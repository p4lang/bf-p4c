#ifndef BF_P4C_ARCH_ARCHITECTURE_H_
#define BF_P4C_ARCH_ARCHITECTURE_H_

#include <boost/algorithm/string.hpp>
#include <boost/optional.hpp>
#include <set>
#include "ir/ir.h"
#include "ir/namemap.h"
#include "lib/path.h"
#include "frontends/common/options.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/coreLibrary.h"
#include "frontends/p4/cloner.h"
#include "frontends/p4/uniqueNames.h"
#include "frontends/p4/sideEffects.h"
#include "frontends/p4/methodInstance.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/device.h"
#include "program_structure.h"

namespace BFN {

/// Find and remove extern method calls that the P4 programmer has requested by
/// excluded from translation using the `@dont_translate_extern_method` pragma.
/// Currently this pragma is only supported on actions; it takes as an argument
/// a list of strings that identify extern method calls to remove from the action
/// body.
struct RemoveExternMethodCallsExcludedByAnnotation : public Transform {
    const IR::MethodCallStatement*
    preorder(IR::MethodCallStatement* call) override {
        auto* action = findContext<IR::P4Action>();
        if (!action) return call;

        auto* callExpr = call->methodCall->to<IR::MethodCallExpression>();
        BUG_CHECK(callExpr, "Malformed method call IR: %1%", call);

        auto* dontTranslate = action->getAnnotation("dont_translate_extern_method");
        if (!dontTranslate) return call;
        for (auto* excluded : dontTranslate->expr) {
            auto* excludedMethod = excluded->to<IR::StringLiteral>();
            if (!excludedMethod) {
                ::error("Non-string argument to @dont_translate_extern_method: "
                        "%1%", excluded);
                return call;
            }

            if (excludedMethod->value == callExpr->toString()) {
                ::warning("Excluding method call from translation due to "
                          "@dont_translate_extern_method: %1%", call);
                return nullptr;
            }
        }

        return call;
    }
};

class GenerateTofinoProgram : public Transform {
    ProgramStructure* structure;
 public:
    explicit GenerateTofinoProgram(ProgramStructure* structure)
            : structure(structure) { CHECK_NULL(structure); setName("GenerateTofinoProgram"); }
    //
    const IR::Node* preorder(IR::P4Program* program) override {
        auto *rv = structure->create(program);
        return rv;
    }
};

class TranslationFirst : public PassManager {
 public:
    TranslationFirst() { setName("TranslationFirst"); }
};

class TranslationLast : public PassManager {
 public:
    TranslationLast() { setName("TranslationLast"); }
};

/// Add parser code to extract the standard TNA intrinsic metadata.
struct AddIntrinsicMetadata : public Transform {
    /// @return a parser state with a name that's distinct from the states in
    /// the P4 program and an `@name` annotation with a '$' prefix. Downstream,
    /// we search for certain '$' states and replace them with more generated
    /// parser code.
    static IR::ParserState *
    createGeneratedParserState(cstring name,
                               IR::IndexedVector<IR::StatOrDecl> &&statements,
                               const IR::Expression *selectExpression) {
        // XXX(seth): It'd be good to actually verify that this name is unique.
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

    /// @return an `extract()` call that extracts the given header. The header is
    /// assumed to be one of the standard TNA metadata headers.
    static IR::Statement *
    createExtractCall(const IR::BFN::TranslatedP4Parser *parser, cstring header) {
        auto packetInParam = parser->tnaParams.at("pkt");
        auto *method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("extract"));
        auto headerParam = parser->tnaParams.at(header);
        auto *args = new IR::Vector<IR::Expression>({
                                                            new IR::PathExpression(headerParam)
                                                    });
        auto *callExpr = new IR::MethodCallExpression(method, args);
        return new IR::MethodCallStatement(callExpr);
    }

    /// @return a lookahead expression for the given size of `bit<>` type.
    static IR::Expression *
    createLookaheadExpr(const IR::BFN::TranslatedP4Parser *parser, int bits) {
        auto packetInParam = parser->tnaParams.at("pkt");
        auto *method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("lookahead"));
        auto *typeArgs = new IR::Vector<IR::Type>({
                                                          IR::Type::Bits::get(bits)
                                                  });
        auto *lookaheadExpr =
                new IR::MethodCallExpression(method, typeArgs,
                                             new IR::Vector<IR::Expression>);
        return lookaheadExpr;
    }

    /// @return an `advance()` call that advances by the given number of bits.
    static IR::Statement *
    createAdvanceCall(const IR::BFN::TranslatedP4Parser *parser, int bits) {
        auto packetInParam = parser->tnaParams.at("pkt");
        auto *method = new IR::Member(new IR::PathExpression(packetInParam),
                                      IR::ID("advance"));
        auto *args = new IR::Vector<IR::Expression>(
                {new IR::Constant(IR::Type::Bits::get(32), bits)});
        auto *callExpr = new IR::MethodCallExpression(method, args);
        return new IR::MethodCallStatement(callExpr);
    }

    /// @return an assignment statement of the form `header.field = constant`.
    static IR::Statement *
    createSetMetadata(const IR::BFN::TranslatedP4Parser *parser, cstring header,
                      cstring field, int bitWidth, int constant) {
        auto headerParam = parser->tnaParams.at(header);
        auto *member = new IR::Member(new IR::PathExpression(headerParam),
                                      IR::ID(field));
        auto *value = new IR::Constant(IR::Type::Bits::get(bitWidth), constant);
        return new IR::AssignmentStatement(member, value);
    }

    /// Rename the start state of the given parser and return it. This will
    /// leave the parser without a start state, so the caller must create a new
    /// one.
    static const IR::ParserState *
    convertStartStateToNormalState(IR::P4Parser *parser, cstring newName) {
        auto *origStartState = parser->getDeclByName(IR::ParserState::start);
        auto origStartStateIt = std::find(parser->states.begin(),
                                          parser->states.end(),
                                          origStartState);
        BUG_CHECK(origStartStateIt != parser->states.end(),
                  "Couldn't find the original start state?");
        parser->states.erase(origStartStateIt);

        auto *newState = origStartState->to<IR::ParserState>()->clone();
        newState->name = IR::ID(cstring("__") + newName);
        newState->annotations = newState->annotations
                ->addAnnotationIfNew(IR::Annotation::nameAnnotation,
                                     new IR::StringLiteral(IR::ParserState::start));
        parser->states.push_back(newState);

        return newState;
    }

    /// Add a new start state to the given parser, with a potentially
    /// non-'start' name applied via an `@name` annotation.
    static void addNewStartState(IR::P4Parser *parser, cstring name,
                                 cstring nextState) {
        auto *startState =
                new IR::ParserState(IR::ParserState::start,
                                    new IR::PathExpression(nextState));
        startState->annotations = startState->annotations
                ->addAnnotationIfNew(IR::Annotation::nameAnnotation,
                                     new IR::StringLiteral(cstring("$") + name));
        parser->states.push_back(startState);
    }

    /// Add the standard TNA ingress metadata to the given parser. The original
    /// start state will remain in the program, but with a new name.
    static void addIngressMetadata(IR::BFN::TranslatedP4Parser *parser) {
        auto *p4EntryPointState =
                convertStartStateToNormalState(parser, "ingress_p4_entry_point");

        // Add a state that skips over any padding between the phase 0 data and the
        // beginning of the packet.
        // XXX(seth): This "padding" is new in JBay, and it may contain actual data
        // rather than just padding. Once we have a chance to investigate what it
        // does, we'll want to revisit this.
        const auto bitSkip = Device::pardeSpec().bitIngressPrePacketPaddingSize();
        auto *skipToPacketState =
                createGeneratedParserState("skip_to_packet", {
                        createAdvanceCall(parser, bitSkip)
                }, p4EntryPointState->name);
        parser->states.push_back(skipToPacketState);


        // Add a state that parses the phase 0 data. This is a placeholder that
        // just skips it; if we find a phase 0 table, it'll be replaced later.
        const auto bitPhase0Size = Device::pardeSpec().bitPhase0Size();
        auto *phase0State =
                createGeneratedParserState("phase0", {
                        createAdvanceCall(parser, bitPhase0Size)
                }, skipToPacketState->name);
        parser->states.push_back(phase0State);

        // This state parses resubmit data. Just like phase 0, the version we're
        // generating here is a placeholder that just skips the data; we'll replace
        // it later with an actual implementation.
        const auto bitResubmitSize = Device::pardeSpec().bitResubmitSize();
        auto *resubmitState =
                createGeneratedParserState("resubmit", {
                        createAdvanceCall(parser, bitResubmitSize)
                }, skipToPacketState->name);
        parser->states.push_back(resubmitState);

        // If this is a resubmitted packet, the initial intrinsic metadata will be
        // followed by the resubmit data; otherwise, it's followed by the phase 0
        // data. This state checks the resubmit flag and branches accordingly.
        auto igIntrMd = parser->tnaParams.at("ig_intr_md");
        IR::Vector<IR::Expression> selectOn = {
                new IR::Cast(IR::Type::Bits::get(8),
                             new IR::Member(new IR::PathExpression(igIntrMd),
                                            "resubmit_flag"))
        };
        auto *checkResubmitState =
                createGeneratedParserState(
                        "check_resubmit", {},
                        new IR::SelectExpression(new IR::ListExpression(selectOn), {
                                createSelectCase(8, 0, 0x80, phase0State),
                                createSelectCase(8, 0x80, 0x80, resubmitState)
                        }));
        parser->states.push_back(checkResubmitState);

        // This state handles the extraction of ingress intrinsic metadata.
        auto *igMetadataState =
            createGeneratedParserState("ingress_metadata", {
                createSetMetadata(parser, "ig_intr_md_from_prsr", "parser_err", 16, 0),
                createExtractCall(parser, "ig_intr_md")
            }, checkResubmitState->name);
        parser->states.push_back(igMetadataState);

        addNewStartState(parser, "ingress_tna_entry_point", igMetadataState->name);
    }

    /// Add the standard TNA egress metadata to the given parser. The original
    /// start state will remain in the program, but with a new name.
    static void addEgressMetadata(IR::BFN::TranslatedP4Parser *parser) {
        auto *p4EntryPointState =
                convertStartStateToNormalState(parser, "egress_p4_entry_point");

        // Add a state that parses bridged metadata. This is just a placeholder;
        // we'll replace it once we know which metadata need to be bridged.
        auto *bridgedMetadataState =
                createGeneratedParserState("bridged_metadata", {}, p4EntryPointState->name);
        parser->states.push_back(bridgedMetadataState);

        // Similarly, this state is a placeholder which will eventually hold the
        // parser for mirrored data.
        auto *mirroredState =
                createGeneratedParserState("mirrored", {}, p4EntryPointState->name);
        parser->states.push_back(mirroredState);

        // If this is a mirrored packet, the hardware will have prepended the
        // contents of the mirror buffer to the actual packet data. To detect this
        // data, we add a byte to the beginning of the mirror buffer that contains a
        // flag indicating that it's a mirrored packet. We can use this flag to
        // distinguish a mirrored packet from a normal packet because we always
        // begin the bridged metadata we attach to normal packet with an extra byte
        // which has the mirror indicator flag set to zero.
        IR::Vector<IR::Expression> selectOn = {createLookaheadExpr(parser, 8)};
        auto *checkMirroredState =
            createGeneratedParserState("check_mirrored", {},
                new IR::SelectExpression(new IR::ListExpression(selectOn), {
                createSelectCase(8, 0, 1 << 3, bridgedMetadataState),
                createSelectCase(8, 1 << 3, 1 << 3, mirroredState)
            }));
        parser->states.push_back(checkMirroredState);

        // This state handles the extraction of egress intrinsic metadata.
        // XXX(seth): We can't easily do it without making
        // `packet_in.lookahead()` a little more flexible, but a correct
        // implementation should take the EPB configuration into account. It
        // should look more like this:
#if 0
        const auto epbConfig = Device::pardeSpec().defaultEPBConfig();
        const auto egMetadataPacking =
          Device::pardeSpec().egressMetadataLayout(epbConfig, egMeta);
        auto* egMetadataState =
          egMetadataPacking.createP4ExtractionState("$egress_metadata",
                                                    checkMirroredState);
#endif

        auto *egMetadataState =
            createGeneratedParserState("egress_metadata", {
                createSetMetadata(parser, "eg_intr_md_from_prsr", "parser_err", 16, 0),
                // createSetMetadata(parser, "eg_intr_md_from_prsr", "coalesce_sample_count", 8, 0),
                createExtractCall(parser, "eg_intr_md")
            }, checkMirroredState->name);
        parser->states.push_back(egMetadataState);

        addNewStartState(parser, "egress_tna_entry_point", egMetadataState->name);
    }

    IR::BFN::TranslatedP4Parser *preorder(IR::BFN::TranslatedP4Parser *parser) override {
        prune();

        if (parser->thread == INGRESS)
            addIngressMetadata(parser);
        else
            addEgressMetadata(parser);

        return parser;
    }
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_ARCHITECTURE_H_ */
