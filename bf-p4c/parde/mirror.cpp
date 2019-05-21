#include "bf-p4c/parde/mirror.h"

#include <algorithm>
#include "bf-p4c/common/ir_utils.h"
#include "bf-p4c/device.h"
#include "bf-p4c/parde/field_packing.h"
#include "frontends/p4/cloner.h"
#include "frontends/p4/coreLibrary.h"
#include "frontends/p4/fromv1.0/v1model.h"
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/indent.h"
#include "bf-p4c/lib/pad_alignment.h"
#include "dump_parser.h"

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
    const IR::Expression* expression = methodCall->arguments->at(1)->expression;
    if (expression->is<IR::StructInitializerExpression>()) {
        const IR::StructInitializerExpression* fieldList = nullptr;
        {
            fieldList = expression->to<IR::StructInitializerExpression>();
            if (!fieldList) {
                ::warning("Expected field list: %1%", methodCall);
                return boost::none;
            }
        }
        auto* finalFieldList = new MirroredFieldList;
        for (auto* field : fieldList->components) {
            LOG2("mirror field list would include field: " << field);
            if (!field->expression->is<IR::Concat>() &&
                !field->expression->is<IR::Cast>() &&
                !field->expression->is<IR::Constant>() &&
                !field->expression->is<IR::Member>()) {
                ::warning("Unexpected field: %1% ", field);
                return boost::none; }
            finalFieldList->push_back(field->expression);
        }
        LOG3("found fieldList " << finalFieldList);
        return finalFieldList;
    }
    return boost::none;
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
    LOG3("found constant " << constant);
    return constant;
}

struct FindMirroredFieldLists : public Inspector {
    FindMirroredFieldLists(P4::ReferenceMap* refMap, P4::TypeMap* typeMap)
      : refMap(refMap), typeMap(typeMap) { }

    bool preorder(const IR::MethodCallStatement* call) override {
        auto deparser = findContext<IR::BFN::TnaDeparser>();
        if (!deparser)
            return call;

        auto gress = deparser->thread;

        auto* mi = P4::MethodInstance::resolve(call, refMap, typeMap);
        if (!mi->is<P4::ExternMethod>())
            return false;

        auto* em = mi->to<P4::ExternMethod>();
        cstring externName = em->actualExternType->name;
        LOG5("externName: " << externName);
        if (externName != "Mirror")
            return false;

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

        auto mce = call->methodCall->to<IR::MethodCallExpression>();
        auto type = mce->typeArguments->at(0);
        auto typeName = type->to<IR::Type_Name>();
        cstring header = typeName->path->name.name;

        unsigned mirrorIdx = (*mirrorIdxConstant)->asInt();
        BUG_CHECK((mirrorIdx & ~0x07) == 0, "Mirror index is more than 3 bits?");
        fieldLists[std::make_tuple(gress, mirrorIdx, header)] = *fieldList;

        LOG1("found mirror list");
        return false;
    }

    MirroredFieldLists fieldLists;
    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
};

class AddMirroredFieldListParser : public Transform {
    P4::ClonePathExpressions cloner;

 public:
    explicit AddMirroredFieldListParser(const MirroredFieldLists* fieldLists)
        : fieldLists(fieldLists) { }

    const IR::BFN::TnaParser* preorder(IR::BFN::TnaParser* parser) override {
        if (parser->thread != EGRESS)
            prune();
        return parser;
    }

    IR::Node* createEmptyMirrorState(const IR::BFN::TnaParser* parser, cstring nextState) {
        // Add a state that skips over compiler generated byte
        auto *skipToPacketState =
            createGeneratedParserState("mirrored", {
                createAdvanceCall(parser, 8)
            }, new IR::PathExpression(IR::ID(nextState)));
        return skipToPacketState;
    }

    const IR::Node* preorder(IR::ParserState* state) override {
        auto parser = findOrigCtxt<IR::BFN::TnaParser>();
        if (!parser) return state;
        prune();
        if (state->name == "__mirrored") {
            // This is the '$mirrored' placeholder state. Generate code to extract
            auto selExpr = state->selectExpression;
            if (auto path = selExpr->to<IR::PathExpression>()) {
                auto nextState = path->path->name;
                if (fieldLists->size() == 0)
                    return createEmptyMirrorState(parser, nextState);
                return addMirroredFieldListParser(parser, state, nextState);
            } else if (auto selcases = selExpr->to<IR::SelectExpression>()) {
                auto pathexpr = selcases->selectCases[0]->state;
                auto nextState = pathexpr->to<IR::PathExpression>()->path->name;
                return addMirroredFieldListParser(parser, state, nextState);
            }
         }
        return state;
    }

    /// @return an assignment statement of the form `dest = header.field`.
    static IR::Statement *
    createSetMetadata(const IR::Expression* dest, cstring header, cstring field) {
        auto *member = new IR::Member(new IR::PathExpression(IR::ID(header)),
                                      IR::ID(field));
        return new IR::AssignmentStatement(dest, member);
    }

    static IR::Statement *
    createExtractCall(const IR::BFN::TnaParser *parser, cstring header, cstring tmp) {
        auto packetInParam = parser->tnaParams.at("pkt");
        auto *method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("extract"));
        auto *args = new IR::Vector<IR::Argument>(
            { new IR::Argument(new IR::PathExpression(IR::ID(tmp))) });
        auto *callExpr = new IR::MethodCallExpression(method, args);
        return new IR::MethodCallStatement(callExpr);
    }


    const IR::ParserState* createMirrorState(const IR::BFN::TnaParser* parser,
            gress_t gress, unsigned cloneSrc, unsigned digestId, cstring header,
            const MirroredFieldList* fl, cstring nextState) {
        auto statements = new IR::IndexedVector<IR::StatOrDecl>();
        /**
         * T tmp;
         * pkt.extract(tmp);
         */
        auto tmp = cstring::to_cstring(gress) + "_mirror_tmp_" + std::to_string(digestId);
        auto decl = new IR::Declaration_Variable(IR::ID(tmp), new IR::Type_Name(header));
        statements->push_back(decl);
        statements->push_back(createExtractCall(parser, header, tmp));

        /**
         * copy extract tmp header to metadata;
         */
        unsigned field_idx = 0;
        unsigned skip_idx = 1;
        // skip compiler generated field
        for (auto s : *fl) {
            if (field_idx < skip_idx) {
                field_idx++;
                continue; }
            auto field = "__field_" + std::to_string(field_idx++);
            statements->push_back(createSetMetadata(s->apply(cloner), tmp, field));
        }

        statements->push_back(
            createSetMetadata(parser, "compiler_generated_meta", "clone_digest_id", 4, digestId));
        statements->push_back(
            createSetMetadata(parser, "compiler_generated_meta", "clone_src", 4, cloneSrc));

        // Create a state that extracts the fields in this field list.
        cstring name = "mirror_field_list_" + cstring::to_cstring(gress) + "_" +
            cstring::to_cstring(digestId);

        auto select = new IR::PathExpression(IR::ID(nextState));
        auto newStateName = IR::ID(cstring("__") + name);
        auto *newState = new IR::ParserState(newStateName, *statements, select);
        newState->annotations = newState->annotations
            ->addAnnotationIfNew(IR::Annotation::nameAnnotation,
                                 new IR::StringLiteral(cstring("$") + name));
        return newState;
    }

    static IR::ParserState *
    createGeneratedParserState(cstring name,
                               IR::IndexedVector<IR::StatOrDecl> &&statements,
                               const IR::Expression *selectExpression) {
        auto newStateName = IR::ID(cstring("__") + name);
        auto *newState = new IR::ParserState(newStateName, statements,
                                             selectExpression);
        newState->annotations = newState->annotations
            ->addAnnotationIfNew(IR::Annotation::nameAnnotation,
                                 new IR::StringLiteral(cstring("$") + name));
        return newState;
    }

    /// @return a lookahead expression for the given size of `bit<>` type.
    static IR::Expression *
    createLookaheadExpr(const IR::BFN::TnaParser *parser, int bits) {
        auto packetInParam = parser->tnaParams.at("pkt");
        auto *method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("lookahead"));
        auto *typeArgs = new IR::Vector<IR::Type>({
                                                      IR::Type::Bits::get(bits)
                                                  });
        auto *lookaheadExpr =
            new IR::MethodCallExpression(method, typeArgs,
                                         new IR::Vector<IR::Argument>);
        return lookaheadExpr;
    }

    /// @return a SelectCase that checks for a constant value with some mask
    /// applied.
    static IR::SelectCase *
    createSelectCase(unsigned bitWidth, unsigned value, unsigned mask,
                     const IR::ParserState *nextState) {
        auto *type = IR::Type::Bits::get(bitWidth);
        auto *valueExpr = new IR::Constant(type, value);
        auto *maskExpr = new IR::Constant(type, mask);
        auto *nextStateExpr = new IR::PathExpression(nextState->name);
        return new IR::SelectCase(new IR::Mask(valueExpr, maskExpr), nextStateExpr);
    }

    static IR::Statement *
    createAdvanceCall(const IR::BFN::TnaParser *parser, int bits) {
        auto packetInParam = parser->tnaParams.at("pkt");
        auto *method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("advance"));
        auto *args = new IR::Vector<IR::Argument>(
            { new IR::Argument(new IR::Constant(IR::Type::Bits::get(32), bits)) });
        auto *callExpr = new IR::MethodCallExpression(method, args);
        return new IR::MethodCallStatement(callExpr);
    }

    /// @return an assignment statement of the form `header.field = constant`.
    static IR::Statement *
    createSetMetadata(const IR::BFN::TnaParser *parser, cstring header,
                      cstring field, int bitWidth, int constant) {
        auto headerParam = parser->tnaParams.at(header);
        auto *member = new IR::Member(new IR::PathExpression(headerParam),
                                      IR::ID(field));
        auto *value = new IR::Constant(IR::Type::Bits::get(bitWidth), constant);
        return new IR::AssignmentStatement(member, value);
    }

    IR::Node* addMirroredFieldListParser(const IR::BFN::TnaParser* parser,
            const IR::ParserState* state, cstring nextState) {
        LOG3(" update state " << state << " with these fieldlist: ");
        auto states = new IR::IndexedVector<IR::ParserState>();
        auto selectCases = new IR::Vector<IR::SelectCase>();
        for (auto& fieldList : *fieldLists) {
            const gress_t gress = std::get<0>(fieldList.first);
            const auto digestId = std::get<1>(fieldList.first);
            const auto header = std::get<2>(fieldList.first);
            auto* fl = fieldList.second;
            LOG3(" - " << gress << " " << digestId << " " << fl);

            // Construct a `clone_src` value. The first bit indicates that the
            // packet is mirrored; the second bit indicates whether it originates
            // from ingress or egress. See `constants.p4` for the details of the
            // format.
            unsigned source = 1 << 0;
            if (gress == EGRESS)
                source |= 1 << 1;

            auto *newState = createMirrorState(parser, gress,
                    source, digestId, header, fl, nextState);
            states->push_back(newState);

            const unsigned fieldListId = (source << 3) | digestId;
            auto selectCase = createSelectCase(8, fieldListId, 0x1f, newState);
            selectCases->push_back(selectCase);
        }

        IR::Vector<IR::Expression> selectOn = {
            createLookaheadExpr(parser, 8)
        };

        auto* mirrorState =
            createGeneratedParserState(
                "mirrored", { },
                new IR::SelectExpression(new IR::ListExpression(selectOn), *selectCases));
        states->push_back(mirrorState);
        return states;
    }
#if 0
  const IR::BFN::ParserState*
  addMirroredFieldListParser(const IR::BFN::ParserState* finalState) {
      IR::Vector<IR::BFN::Transition> transitions;
      for (auto& fieldList : *fieldLists) {
          const gress_t gress = fieldList.first.first;
          const auto digestId = fieldList.first.second;
          const MirroredFieldList* fieldList = fieldList.second;

          LOG3("   extract field list " << digestId << " " << fieldList.second);

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

          LOG3("   create state to extract field list ");
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
#endif

 private:
  const MirroredFieldLists* fieldLists;
};

}  // namespace

FixupMirrorMetadata::FixupMirrorMetadata(
        P4::ReferenceMap *refMap,
        P4::TypeMap *typeMap) : refMap(refMap), typeMap(typeMap) {
    auto findMirror = new FindMirroredFieldLists(refMap, typeMap);
    addPasses({
        findMirror,
        new AddMirroredFieldListParser(&findMirror->fieldLists)
    });
}

}  // namespace BFN
