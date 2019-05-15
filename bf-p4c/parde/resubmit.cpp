#include "bf-p4c/parde/resubmit.h"

#include <algorithm>
#include "bf-p4c/device.h"
#include "bf-p4c/parde/field_packing.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "frontends/p4/cloner.h"
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

boost::optional<std::pair<cstring, ResubmitSources*>>
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
    const IR::Expression* expression = methodCall->arguments->at(0)->expression;
    if (expression->is<IR::StructInitializerExpression>()) {
        LOG2("resubmit emits struct initializer expression " << expression);
        const IR::StructInitializerExpression* fieldList = nullptr;
        {
            fieldList = expression->to<IR::StructInitializerExpression>();
            if (!fieldList) {
                ::warning("Expected field list: %1%", methodCall);
                return boost::none;
            }
        }
        auto type = methodCall->typeArguments->at(0);
        auto typeName = type->to<IR::Type_Name>();
        auto* sources = new ResubmitSources;
        for (auto* field : fieldList->components) {
            LOG2("resubmit would include field: " << field);
            if (!field->expression->is<IR::Concat>() &&
                !field->expression->is<IR::Cast>() &&
                !field->expression->is<IR::Constant>() &&
                !field->expression->is<IR::Member>()) {
                ::warning("Unexpected field: %1%", field);
                return boost::none; }
            sources->push_back(field->expression);
        }
        return std::make_pair(typeName->path->name.name, sources);
    }
    return boost::none;
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

/// resubmit parser is only generated for p4-14 based programs
class AddResubmitParser : public Transform {
    P4::ClonePathExpressions cloner;

 public:
    explicit AddResubmitParser(const ResubmitExtracts* extracts)
        : extracts(extracts) { }

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

    IR::Node* preorder(IR::ParserState* state) override {
        auto parser = findOrigCtxt<IR::BFN::TnaParser>();
        BUG_CHECK(parser != nullptr, "ParserState %1% is not in TnaParser ", state->name);
        prune();
        if (state->name == "__resubmit") {
            if (extracts->size() == 0)
                return createEmptyResubmitState(parser);
            return updateResubmitMetadataState(parser, state);
        }
        return state;
    }

    IR::Node* createEmptyResubmitState(const IR::BFN::TnaParser* parser) {
        // Add a state that skips over any padding between the phase 0 data and the
        // beginning of the packet.
        const auto bitSkip = Device::pardeSpec().bitResubmitSize();
        auto *skipToPacketState =
            createGeneratedParserState("resubmit", {
                createAdvanceCall(parser, bitSkip)
            }, new IR::PathExpression(IR::ID("__skip_to_packet")));
        return skipToPacketState;
    }

    IR::Node* updateResubmitMetadataState(const IR::BFN::TnaParser* parser,
            IR::ParserState* state) {
        LOG3(" update state " << state << " with these extracts: ");
        auto states = new IR::IndexedVector<IR::ParserState>();
        auto selectCases = new IR::Vector<IR::SelectCase>();
        for (auto e : *extracts) {
            LOG3(" - " << e.first << " " << e.second.first << " " << e.second.second);
            auto newState = createResubmitState(parser, e.first,
                        e.second.first, e.second.second);
            states->push_back(newState);
            auto selectCase = createSelectCase(8, e.first, 0x07, newState);
            selectCases->push_back(selectCase);
        }

        IR::Vector<IR::Expression> selectOn = {
            createLookaheadExpr(parser, 8)
        };

        auto* resubmitState =
            createGeneratedParserState(
                "resubmit", { },
                new IR::SelectExpression(new IR::ListExpression(selectOn), *selectCases));
        states->push_back(resubmitState);
        return states;
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

    static IR::SelectCase *
    createDefaultSelectCase(cstring nextState) {
        auto *nextStateExpr = new IR::PathExpression(nextState);
        return new IR::SelectCase(new IR::DefaultExpression(), nextStateExpr);
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

    /// @return an assignment statement of the form `dest = header.field`.
    static IR::Statement *
    createSetMetadata(const IR::Expression* dest, cstring header, cstring field) {
        auto *member = new IR::Member(new IR::PathExpression(IR::ID(header)),
                                      IR::ID(field));
        return new IR::AssignmentStatement(dest, member);
    }

    const IR::ParserState* createResubmitState(const IR::BFN::TnaParser* parser,
            unsigned idx, cstring header, const ResubmitSources* sources) {
        auto statements = new IR::IndexedVector<IR::StatOrDecl>();

        /**
         * T tmp;
         * pkt.extract(tmp);
         */
        auto tmp = "__resubmit_tmp_" + std::to_string(idx);
        auto decl = new IR::Declaration_Variable(IR::ID(tmp), new IR::Type_Name(header));
        statements->push_back(decl);
        statements->push_back(createExtractCall(parser, header, tmp));

        /**
         * copy extract tmp header to metadata;
         */
        unsigned field_idx = 0;
        unsigned skip_idx = 1;
        // skip compiler generated field
        for (auto s : *sources) {
            if (field_idx < skip_idx) {
                field_idx++;
                continue; }
            auto field = "__field_" + std::to_string(field_idx++);
            statements->push_back(createSetMetadata(s->apply(cloner), tmp, field));
        }

        cstring name = "resubmit_" + std::to_string(idx);
        auto select = new IR::PathExpression(IR::ID("__skip_to_packet"));
        auto newStateName = IR::ID(cstring("__") + name);
        auto *newState = new IR::ParserState(newStateName, *statements, select);
        newState->annotations = newState->annotations
            ->addAnnotationIfNew(IR::Annotation::nameAnnotation,
                                 new IR::StringLiteral(cstring("$") + name));
        return newState;
    }

 private:
  const ResubmitExtracts* extracts;
};

FixupResubmitMetadata::FixupResubmitMetadata(
        P4::ReferenceMap *refMap,
        P4::TypeMap *typeMap) : refMap(refMap), typeMap(typeMap) {
    auto findResubmit = new FindResubmit(refMap, typeMap);
    addPasses({
        findResubmit,
        new AddResubmitParser(&findResubmit->extracts)
    });
}

}  // namespace BFN
