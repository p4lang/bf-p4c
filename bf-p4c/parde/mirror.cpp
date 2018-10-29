#include "bf-p4c/parde/mirror.h"

#include <algorithm>
#include "bf-p4c/device.h"
#include "bf-p4c/parde/field_packing.h"
#include "frontends/p4/coreLibrary.h"
#include "frontends/p4/fromv1.0/v1model.h"
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/indent.h"
#include "bf-p4c/lib/pad_alignment.h"

namespace BFN {
namespace {

/**
 * Analyze the `mirror.emit()` method within the deparser block,
 * and try to extract the field list.
 *
 * @param statement  The `emit()` method call to analyze.
 * @return a MirroredFieldList vector containing the mirrored fields, or
 * boost::none if the `emit()` call was invalid.
 */
boost::optional<MirroredFieldList*>
analyzeMirrorStatement(const IR::MethodCallStatement* statement) {
    auto methodCall = statement->methodCall->to<IR::MethodCallExpression>();
    if (!methodCall) {
        return boost::none;
    }
    auto member = methodCall->method->to<IR::Member>();
    if (!member || member->member != "emit") {
        return boost::none;
    }
    if (methodCall->arguments->size() != 2) {
        ::warning("Expected 2 arguments for mirror.%1% statement: %1%",
                  member->member);
        return boost::none;
    }
    const IR::ListExpression* fieldList = nullptr;
    {
        fieldList = (*methodCall->arguments)[1]->expression->to<IR::ListExpression>();
        if (!fieldList) {
            ::warning("Expected field list: %1%", methodCall);
            return boost::none;
        }
    }
    auto* finalFieldList = new MirroredFieldList;
    for (auto* field : fieldList->components) {
        LOG2("mirror field list would include field: " << field);
        auto* member = field->to<IR::Member>();
        if (!member || !member->expr->is<IR::HeaderRef>()) {
            ::warning("Expected field: %1%", field);
            return boost::none;
        }
        finalFieldList->push_back(member);
    }
    return finalFieldList;
}

boost::optional<const IR::Constant*>
checkIfStatement(const IR::IfStatement* ifStatement) {
    auto* equalExpr = ifStatement->condition->to<IR::Equ>();
    if (!equalExpr) {
        ::warning("Expected comparison of mirror_type with constant: "
                  "%1%", ifStatement->condition);
        return boost::none;
    }
    auto* constant = equalExpr->right->to<IR::Constant>();
    if (!constant) {
        ::warning("Expected comparison of mirror_type with constant: "
                  "%1%", equalExpr->right);
        return boost::none;
    }

    auto* member = equalExpr->left->to<IR::Member>();
    if (!member || member->member != "mirror_type") {
        ::warning("Expected comparison of mirror_type with constant: "
                  "%1%", ifStatement->condition);
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

struct FindMirroredFieldLists : public Inspector {
    FindMirroredFieldLists(P4::ReferenceMap* refMap, P4::TypeMap* typeMap)
      : refMap(refMap), typeMap(typeMap) { }

    bool preorder(const IR::MethodCallStatement* call) override {
        auto deparser = findContext<IR::BFN::TranslatedP4Deparser>();
        if (!deparser)
            return call;

        auto gress = deparser->thread;

        auto* mi = P4::MethodInstance::resolve(call, refMap, typeMap);
        if (auto* em = mi->to<P4::ExternMethod>()) {
            cstring externName = em->actualExternType->name;
            LOG5("externName: " << externName);
            if (externName != "Mirror") return false;
        }

        auto* ifStatement = findContext<IR::IfStatement>();
        if (!ifStatement) {
            ::warning("Expected mirror to be used within an `if` "
                      "statement");
            return false;
        }
        auto mirrorIdxConstant = checkIfStatement(ifStatement);
        if (!mirrorIdxConstant) return false;

        auto fieldList = analyzeMirrorStatement(call);
        if (!fieldList) return false;

        unsigned mirrorIdx = (*mirrorIdxConstant)->asInt();
        BUG_CHECK((mirrorIdx & ~0x07) == 0, "Mirror index is more than 3 bits?");
        fieldLists[std::make_pair(gress, mirrorIdx)] = *fieldList;

        LOG1("found mirror list");
        return false;
    }

    MirroredFieldLists fieldLists;
    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
};

FieldPacking* packMirroredFieldList(gress_t from_gress, const MirroredFieldList* fieldList) {
    auto* packing = new FieldPacking;

    for (auto* toMirror : *fieldList) {
        const IR::Member* source = toMirror->to<IR::Member>();
        auto* containingType = source->expr->type;
        BUG_CHECK(containingType->is<IR::Type_StructLike>(),
                  "Mirror field is not attached to a structlike type?");
        auto* type = containingType->to<IR::Type_StructLike>();

        auto* field = type->getField(source->member);
        BUG_CHECK(field != nullptr,
                  "Mirror field %1% not found in type %2%", field, type);

        // Skip parsing `mirror_id`, `mirror_type`, and `mirror_source`; they're
        // handled specially.
        if (source->member == "mirror_id" &&
              (type->name == "ingress_intrinsic_metadata_for_mirror_buffer_t" ||
               type->name == "egress_intrinsic_metadata_for_mirror_buffer_t")) {
            packing->padToAlignment(8);
            continue;
        }
        if ((source->member == "mirror_type") &&
              (type->name == "ingress_intrinsic_metadata_for_deparser_t" ||
               type->name == "egress_intrinsic_metadata_for_deparser_t")) {
            packing->padToAlignment(8);
            continue;
        }
        if ((source->member == "mirror_source") &&
            (type->name == "compiler_generated_metadata_t")) {
            packing->padToAlignment(8);
            continue;
        }

        // Align the field so that its LSB lines up with a byte boundary.
        // After phv allocation, this extract and parser state will be adjusted
        // accroding to the actual allocation.
        const int alignment = getAlignment(field->type->width_bits());
        packing->padToAlignment(8, alignment);

        packing->appendField(source, field->type->width_bits(), from_gress);
        packing->padToAlignment(8);
    }

    return packing;
}

// XXX(seth): We have code like this duplicated in several places. We should
// centralize it.
IR::Member *gen_fieldref(const IR::HeaderOrMetadata *hdr, cstring field) {
    const IR::Type *ftype = nullptr;
    auto f = hdr->type->getField(field);
    if (f != nullptr)
        ftype = f->type;
    else
        BUG("Couldn't find intrinsic metadata field %s in %s", field, hdr->name);
    return new IR::Member(ftype, new IR::ConcreteHeaderRef(hdr), field);
}

// XXX(seth): This is widely duplicated too.
const IR::HeaderOrMetadata*
getMetadataType(const IR::BFN::Pipe* pipe, cstring typeName) {
    auto* meta = pipe->metadata[typeName];
    BUG_CHECK(meta != nullptr,
              "Couldn't find required intrinsic metadata type: %1%", typeName);
    return meta;
}

struct AddMirroredFieldListParser : public Transform {
  AddMirroredFieldListParser(const IR::BFN::Pipe* pipe,
                             const MirroredFieldListPacking* fieldLists)
          : pipe(pipe), fieldLists(fieldLists) { }

  const IR::BFN::Parser* preorder(IR::BFN::Parser* parser) override {
      if (parser->gress != EGRESS)
          prune();
      return parser;
  }

  const IR::BFN::ParserState* preorder(IR::BFN::ParserState* state) override {
      auto parser = findOrigCtxt<IR::BFN::Parser>();
      if (!parser) return state;
      if (state->name != createThreadName(parser->gress, "$mirrored")) return state;

      // This is the '$mirrored' placeholder state. Generate code to extract
      // mirrored field lists.
      return addMirroredFieldListParser(state->transitions[0]->next);
  }

  const IR::BFN::ParserState*
  addMirroredFieldListParser(const IR::BFN::ParserState* finalState) {
      IR::Vector<IR::BFN::Transition> transitions;
      for (auto& fieldList : *fieldLists) {
          const gress_t gress = fieldList.first.first;
          const auto digestId = fieldList.first.second;
          const FieldPacking* packing = fieldList.second;

          // Construct a `clone_src` value. The first bit indicates that the
          // packet is mirrored; the second bit indicates whether it originates
          // from ingress or egress. See `constants.p4` for the details of the
          // format.
          unsigned source = 1 << 0;
          if (gress == EGRESS)
              source |= 1 << 1;

          // Create a state that extracts the fields in this field list.
          cstring fieldListStateName = "$mirror_field_list_" +
                                       cstring::to_cstring(gress) + "_" +
                                       cstring::to_cstring(digestId);
          auto* fieldListState =
            packing->createExtractionState(EGRESS, fieldListStateName, finalState);
          fieldListState->statements.push_back(
            new IR::BFN::Extract(cloneDigestId, new IR::BFN::ConstantRVal(digestId)));
          fieldListState->statements.push_back(
            new IR::BFN::Extract(cloneSource, new IR::BFN::ConstantRVal(source)));

          // The combination of `clone_src` and the digest ID uniquely identify
          // this field list; this information is included in the mirror field
          // list, although frustratingly it's included with an alignment that
          // prevents us from simply extracting it, which would certainly
          // simplify this code a lot.
          // XXX(seth): This would also be much simpler to do during
          // translation, where is where this stuff really belongs.
          const unsigned fieldListId = (source << 3) | digestId;
          transitions.push_back(
            new IR::BFN::Transition(match_t(8, fieldListId, 0x1f), 1,
                                    fieldListState));
      }

      // Add a default match for the case where there are no field lists in
      // this mirrored packet.
      transitions.push_back(
          new IR::BFN::Transition(match_t(), 1, finalState));

      auto *select = new IR::BFN::Select(new IR::BFN::MetadataRVal(StartLen(0, 8)));
      return new IR::BFN::ParserState(createThreadName(EGRESS, "$mirrored"), EGRESS, {},
                                      {select}, transitions);
  }

  Visitor::profile_t init_apply(const IR::Node *root) override {
      auto* egParserMeta =
          getMetadataType(pipe, "compiler_generated_meta");
      cloneDigestId = gen_fieldref(egParserMeta, "clone_digest_id");
      cloneSource = gen_fieldref(egParserMeta, "clone_src");
      return Transform::init_apply(root);
  }

 private:
  const IR::BFN::Pipe* pipe;
  const MirroredFieldListPacking* fieldLists;
  const IR::Member* cloneDigestId;
  const IR::Member* cloneSource;
};

}  // namespace

ExtractMirrorFieldPackings::ExtractMirrorFieldPackings(P4::ReferenceMap *refMap,
                                                       P4::TypeMap *typeMap,
                                                       MirroredFieldListPacking* fieldPackings)
    : fieldPackings(fieldPackings) {
    CHECK_NULL(fieldPackings);
    auto findMirror = new FindMirroredFieldLists(refMap, typeMap);
    addPasses({
        findMirror,
        new VisitFunctor([findMirror, fieldPackings]() {
            for (auto& fieldList : findMirror->fieldLists) {
                auto* packing = BFN::packMirroredFieldList(
                        fieldList.first.first,  // gress
                        fieldList.second);
                fieldPackings->emplace(fieldList.first, packing);
            }
        }),
    });
}

PopulateMirrorStateWithFieldPackings::PopulateMirrorStateWithFieldPackings(
        IR::BFN::Pipe* pipe, const MirroredFieldListPacking* fieldPackings) {
    CHECK_NULL(fieldPackings);
    auto addMirrorParserState = new AddMirroredFieldListParser(pipe, fieldPackings);
    addPasses({
        addMirrorParserState,
        LOGGING(4) ? new DumpParser("add_mirror_states") : nullptr,
    });
}

}  // namespace BFN
