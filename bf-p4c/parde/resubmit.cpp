#include "bf-p4c/parde/resubmit.h"

#include <algorithm>
#include "bf-p4c/device.h"
#include "bf-p4c/parde/field_packing.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "frontends/p4/coreLibrary.h"
#include "frontends/p4/fromv1.0/v1model.h"
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/indent.h"

namespace BFN {

/**
 * Analyze the Resubmit `emit` method within the deparser block,
 * and try to extract the source field list.
 *
 * @param statement  The `emit` method to analyze
 * @return a ResubmitSource vector containing the source fields used in the resubmit,
 * or boost::none if the resubmit code was invalid.
 */

boost::optional<ResubmitSources*>
analyzeResubmitStatement(const IR::MethodCallStatement* statement) {
    auto methodCall = statement->methodCall->to<IR::MethodCallExpression>();
    if (!methodCall) {
        return boost::none;
    }
    auto member = methodCall->method->to<IR::Member>();
    if (!member || member->member != "emit") {
        return boost::none;
    }
    if (methodCall->arguments->size() != 1) {
        ::warning("Expected 1 arguments for resubmit.%1% statement: %1%", member->member);
        return boost::none;
    }
    const IR::ListExpression* sourceList = nullptr;
    {
        sourceList = (*methodCall->arguments)[0]->expression->to<IR::ListExpression>();
        if (!sourceList) {
            ::warning("Expected list of fields: %1%", methodCall);
            return boost::none;
        }
    }
    auto* sources = new ResubmitSources;
    for (auto* source : sourceList->components) {
        LOG2("resubmit would include field: " << source);
        auto* member = source->to<IR::Member>();
        if (!member || !member->expr->is<IR::HeaderRef>()) {
            ::warning("Expected field: %1%", source);
            return boost::none;
        }
        sources->push_back(member);
    }
    return sources;
}

boost::optional<const IR::Constant*>
checkIfStatement(const IR::IfStatement* ifStatement) {
    auto* equalExpr = ifStatement->condition->to<IR::Equ>();
    if (!equalExpr) {
        ::warning("Expected comparing resubmit_type with constant: %1%", ifStatement->condition);
        return boost::none;
    }
    auto* constant = equalExpr->right->to<IR::Constant>();
    if (!constant) {
        ::warning("Expected comparing resubmit_type with constant: %1%", equalExpr->right);
        return boost::none;
    }

    auto* member = equalExpr->left->to<IR::Member>();
    if (!member || member->member != "resubmit_type") {
        ::warning("Expected comparing resubmit_type with constant: %1%", ifStatement->condition);
        return boost::none;
    }
    if (!ifStatement->ifTrue || ifStatement->ifFalse) {
        ::warning("Expected an `if` with no `else`: %1%", ifStatement);
        return boost::none;
    }
    auto* method = ifStatement->ifTrue->to<IR::MethodCallStatement>();
    if (!method) {
        ::warning("Expected a single method call statement: %1%", method);
        return boost::none;
    }
    return constant;
}

class FindResubmit : public DeparserInspector {
    bool preorder(const IR::MethodCallStatement* node) override {
        auto mi = P4::MethodInstance::resolve(node, refMap, typeMap);
        if (auto* em = mi->to<P4::ExternMethod>()) {
            cstring externName = em->actualExternType->name;
            if (externName != "Resubmit") {
                return false;
            }
        }
        auto ifStatement = findContext<IR::IfStatement>();
        if (!ifStatement) {
            ::warning("Expected Resubmit to be used within an If statement");
        }
        auto resubmit_type = checkIfStatement(ifStatement);
        if (!resubmit_type) {
            return false;
        }

        auto resubmit = analyzeResubmitStatement(node);
        if (resubmit)
            extracts.emplace((*resubmit_type)->asInt(), *resubmit);
        return false;
    }

 public:
    FindResubmit(P4::ReferenceMap* refMap, P4::TypeMap* typeMap)
            : refMap(refMap), typeMap(typeMap) { }

    ResubmitExtracts extracts;

 private:
    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
};

FieldPacking* packResubmitFields(const ResubmitSources* extracts) {
    auto* packing = new FieldPacking;

    for (auto extractItem : *extracts) {
        const IR::Member* source = extractItem->to<IR::Member>();
        auto containingType = source->expr->type;
        BUG_CHECK(containingType->is<IR::Type_StructLike>(),
                  "Resubmit field is not attached to a structlike type?");
        auto type = containingType->to<IR::Type_StructLike>();

        auto field = type->getField(source->member);
        BUG_CHECK(field != nullptr,
                  "Resubmit field %1% not found in type %2%", field, type);

        // skip parsing intr_md_for_deparser.resubmit_type
        if (source->member == "resubmit_type" &&
            type->name == "ingress_intrinsic_metadata_for_deparser_t") {
            packing->padToAlignment(8);
            continue;
        }

        // Align the field so that its LSB lines up with a byte boundary.
        // After phv allocation, this extract and parser state will be adjusted
        // accroding to the actual allocation.
        const int fieldSize = field->type->width_bits();
        const int nextByteBoundary = 8 * ((fieldSize + 7) / 8);
        const int alignment = nextByteBoundary - fieldSize;
        packing->padToAlignment(8, alignment);

        packing->appendField(source, field->type->width_bits(), INGRESS);
        packing->padToAlignment(8);
    }

    auto maxResubmitSize = Device::pardeSpec().bitResubmitSize() -
                           Device::pardeSpec().bitResubmitTagSize();
    if (packing->totalWidth == 0) {
        packing->appendPadding(maxResubmitSize);
    } else {
        packing->padToAlignment(maxResubmitSize);
    }
    return packing;
}

/// resubmit parser is only generated for p4-14 based programs
class AddResubmitParser : public ParserModifier {
 public:
  explicit AddResubmitParser(const ResubmitPacking* packings)
      : packings(packings) { }

  bool preorder(IR::BFN::Parser* parser) {
      if (parser->gress != INGRESS) return false;

      auto start = transformAllMatching<IR::BFN::ParserState>(parser->start,
                   [this](const IR::BFN::ParserState* state) {
          if (state->name != createThreadName(INGRESS, "$resubmit")) return state;

          // This is the '$resubmit' placeholder state. We'll replace it with our
          // generated parser program. After resubmit, we'll transition to the
          // same state that the placeholder state transitioned to.
          return this->addResubmitState(state->transitions[0]->next);
      });

      parser->start = start->to<IR::BFN::ParserState>();
      return false;
  }

  const IR::BFN::ParserState*
  addResubmitState(const IR::BFN::ParserState* finalState) {
      IR::Vector<IR::BFN::Transition> transitions;
      for (auto packing : *packings) {
          cstring nextStateName = "$resubmit_$" + std::to_string(packing.first);

          auto* nextState =
                  packing.second->createExtractionState(INGRESS, nextStateName, finalState);
          transitions.push_back(
                  new IR::BFN::Transition(
                      // mask is 0x07 because there can be at most 8 different resubmit sessions.
                      match_t(Device::pardeSpec().bitResubmitTagSize(), packing.first, 0x07),
                      Device::pardeSpec().byteResubmitTagSize(),
                      nextState));
      }

      IR::Vector<IR::BFN::ParserPrimitive> extracts;
      if (packings->size()) {
          auto select = new IR::BFN::Select(
              new IR::BFN::MetadataRVal(StartLen(0, Device::pardeSpec().bitResubmitTagSize())));
          return new IR::BFN::ParserState("$resubmit", INGRESS, extracts, { select }, transitions);
      } else {
          transitions.push_back(
              new IR::BFN::Transition(match_t(),
                                      Device::pardeSpec().byteResubmitSize(), finalState));
          return new IR::BFN::ParserState("$resubmit", INGRESS, extracts, { }, transitions);
      }
  }

 private:
  const ResubmitPacking* packings;
};

ExtractResubmitFieldPackings::ExtractResubmitFieldPackings(P4::ReferenceMap *refMap,
                                                           P4::TypeMap *typeMap,
                                                           ResubmitPacking* fieldPackings)
    : fieldPackings(fieldPackings) {
    CHECK_NULL(fieldPackings);
    auto findResubmit = new FindResubmit(refMap, typeMap);
    addPasses({
        findResubmit,
        new VisitFunctor([findResubmit, fieldPackings]() {
            for (auto extract : findResubmit->extracts) {
                auto packing = packResubmitFields(extract.second);
                fieldPackings->emplace(extract.first, packing);
            }
        }),
    });
}

PopulateResubmitStateWithFieldPackings::PopulateResubmitStateWithFieldPackings(
    const ResubmitPacking *fieldPackings) : fieldPackings(fieldPackings) {
    auto addResubmitParser = new AddResubmitParser(fieldPackings);
    addPasses({
         addResubmitParser,
    });
}

}  // namespace BFN
