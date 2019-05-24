#ifndef EXTENSIONS_BF_P4C_MIDEND_PARSER_UTILS_H_
#define EXTENSIONS_BF_P4C_MIDEND_PARSER_UTILS_H_

#include "ir/ir.h"
#include "lib/cstring.h"

struct ParserUtils {
    /// @return a parser state with a name that's distinct from the states in
    /// the P4 program and an `@name` annotation with a '$' prefix. Downstream,
    /// we search for certain '$' states and replace them with more generated
    /// parser code.
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

    static IR::ParserState *
    createGeneratedParserState(cstring name,
                               IR::IndexedVector<IR::StatOrDecl> &&statements,
                               cstring nextState) {
        return createGeneratedParserState(name, std::move(statements),
                                          new IR::PathExpression(nextState));
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

    /// @return an `extract()` call that extracts the given header.
    static IR::Statement *
    createExtractCall(const IR::BFN::TnaParser *parser, cstring hdr) {
        auto packetInParam = parser->tnaParams.at("pkt");
        auto *method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("extract"));
        auto *args = new IR::Vector<IR::Argument>(
            { new IR::Argument(new IR::PathExpression(IR::ID(hdr))) });
        auto *callExpr = new IR::MethodCallExpression(method, args);
        return new IR::MethodCallStatement(callExpr);
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

    /// @return an `advance()` call that advances by the given number of bits.
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

    /// @return an assignment statement of the form `dest = header.field`.
    static IR::Statement *
    createSetMetadata(const IR::Expression* dest, cstring header, cstring field) {
        auto *member = new IR::Member(new IR::PathExpression(IR::ID(header)),
                                      IR::ID(field));
        return new IR::AssignmentStatement(dest, member);
    }
};

#endif /* EXTENSIONS_BF_P4C_MIDEND_PARSER_UTILS_H_ */
