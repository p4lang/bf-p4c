#ifndef BF_P4C_ARCH_INTRINSIC_METADATA_H_
#define BF_P4C_ARCH_INTRINSIC_METADATA_H_

#include "ir/ir.h"
#include "bf-p4c/device.h"
#include "frontends/p4/cloner.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "bf-p4c/midend/type_checker.h"
#include "bf-p4c/midend/parser_utils.h"

namespace BFN {

/// Add parser code to extract the standard TNA intrinsic metadata.
class AddMetadataFields : public Transform {
    const IR::ParserState* start_i2e_mirrored = nullptr;
    const IR::ParserState* start_e2e_mirrored = nullptr;
    const IR::ParserState* start_coalesced = nullptr;
    const IR::ParserState* start_egress = nullptr;
    // map the name of 'start_i2e_mirrored' ... to the IR::SelectCase
    // that is used to transit to these state. Used to support extra
    // entry point to P4-14 parser.
    std::map<cstring, const IR::SelectCase*> selectCaseMap;

 public:
    AddMetadataFields() { setName("AddIntrinsicMetadata"); }

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
    static void addIngressMetadata(IR::BFN::TnaParser *parser) {
        auto *p4EntryPointState =
            convertStartStateToNormalState(parser, "ingress_p4_entry_point");

        // Add a state that skips over any padding between the phase 0 data and the
        // beginning of the packet.
        const auto bitSkip = Device::pardeSpec().bitIngressPrePacketPaddingSize();
        auto *skipToPacketState =
            ParserUtils::createGeneratedParserState("skip_to_packet", {
                ParserUtils::createAdvanceCall(parser, bitSkip)
            }, p4EntryPointState->name);
        parser->states.push_back(skipToPacketState);


        // Add a state that parses the phase 0 data. This is a placeholder that
        // just skips it; if we find a phase 0 table, it'll be replaced later.
        const auto bitPhase0Size = Device::pardeSpec().bitPhase0Size();
        auto *phase0State =
            ParserUtils::createGeneratedParserState("phase0", {
                ParserUtils::createAdvanceCall(parser, bitPhase0Size)
            }, skipToPacketState->name);
        parser->states.push_back(phase0State);

        // This state parses resubmit data. Just like phase 0, the version we're
        // generating here is a placeholder that just skips the data; we'll replace
        // it later with an actual implementation.
        const auto bitResubmitSize = Device::pardeSpec().bitResubmitSize();
        auto *resubmitState =
            ParserUtils::createGeneratedParserState("resubmit", {
                ParserUtils::createAdvanceCall(parser, bitResubmitSize)
            }, skipToPacketState->name);
        parser->states.push_back(resubmitState);

        // If this is a resubmitted packet, the initial intrinsic metadata will be
        // followed by the resubmit data; otherwise, it's followed by the phase 0
        // data. This state checks the resubmit flag and branches accordingly.
        auto igIntrMd = parser->tnaParams.at("ig_intr_md");
        IR::Vector<IR::Expression> selectOn = {
                         new IR::Member(new IR::PathExpression(igIntrMd),
                                        "resubmit_flag")
        };
        auto *checkResubmitState =
            ParserUtils::createGeneratedParserState(
                "check_resubmit", {},
                new IR::SelectExpression(new IR::ListExpression(selectOn), {
                    ParserUtils::createSelectCase(1, 0x0, 0x1, phase0State),
                    ParserUtils::createSelectCase(1, 0x1, 0x1, resubmitState)
                }));
        parser->states.push_back(checkResubmitState);

        // This state handles the extraction of ingress intrinsic metadata.
        auto *igMetadataState =
            ParserUtils::createGeneratedParserState("ingress_metadata", {
                ParserUtils::createSetMetadata(parser, "ig_intr_md_from_prsr", "parser_err", 16, 0),
                ParserUtils::createExtractCall(parser, parser->tnaParams.at("ig_intr_md"))
            }, checkResubmitState->name);
        parser->states.push_back(igMetadataState);

        addNewStartState(parser, "ingress_tna_entry_point", igMetadataState->name);
    }

    /// Add the standard TNA egress metadata to the given parser. The original
    /// start state will remain in the program, but with a new name.
    static void addEgressMetadata(IR::BFN::TnaParser *parser,
                                  const IR::ParserState *start_i2e_mirrored,
                                  const IR::ParserState *start_e2e_mirrored,
                                  const IR::ParserState *start_coalesced,
                                  const IR::ParserState *start_egress,
                                  std::map<cstring, const IR::SelectCase*> selMap) {
        auto *p4EntryPointState =
            convertStartStateToNormalState(parser, "egress_p4_entry_point");

        // Add a state that parses bridged metadata. This is just a placeholder;
        // we'll replace it once we know which metadata need to be bridged.
        auto *bridgedMetadataState = ParserUtils::createGeneratedParserState(
            "bridged_metadata", {}, ((start_egress) ? "start_egress" : p4EntryPointState->name));
        parser->states.push_back(bridgedMetadataState);

        // Similarly, this state is a placeholder which will eventually hold the
        // parser for mirrored data.
        IR::Vector<IR::Expression> selectOn;
        IR::Vector<IR::SelectCase> branchTo;
        if (start_i2e_mirrored || start_e2e_mirrored || start_coalesced)
            selectOn.push_back(new IR::Member(
                new IR::PathExpression(new IR::Path("compiler_generated_meta")), "instance_type"));
        if (start_i2e_mirrored) {
            BUG_CHECK(selMap.count("start_i2e_mirrored") != 0,
                      "Couldn't find the start_i2e_mirrored state?");
            branchTo.push_back(selMap.at("start_i2e_mirrored"));
        }
        if (start_e2e_mirrored) {
            BUG_CHECK(selMap.count("start_e2e_mirrored") != 0,
                      "Couldn't find the start_e2e_mirrored state?");
            branchTo.push_back(selMap.at("start_e2e_mirrored"));
        }
        if (start_coalesced) {
            BUG_CHECK(selMap.count("start_coalesced") != 0,
                      "Couldn't find the start_coalesced state?");
            branchTo.push_back(selMap.at("start_coalesced"));
        }

        IR::ParserState* mirroredState = nullptr;
        if (branchTo.size()) {
            mirroredState = ParserUtils::createGeneratedParserState(
                "mirrored", {},
                new IR::SelectExpression(new IR::ListExpression(selectOn), branchTo));
        } else {
            mirroredState = ParserUtils::createGeneratedParserState("mirrored", {},
                                                              p4EntryPointState->name);
        }
        parser->states.push_back(mirroredState);

        // If this is a mirrored packet, the hardware will have prepended the
        // contents of the mirror buffer to the actual packet data. To detect this
        // data, we add a byte to the beginning of the mirror buffer that contains a
        // flag indicating that it's a mirrored packet. We can use this flag to
        // distinguish a mirrored packet from a normal packet because we always
        // begin the bridged metadata we attach to normal packet with an extra byte
        // which has the mirror indicator flag set to zero.
        selectOn = {ParserUtils::createLookaheadExpr(parser, 8)};
        auto *checkMirroredState =
            ParserUtils::createGeneratedParserState("check_mirrored", {},
                         new IR::SelectExpression(new IR::ListExpression(selectOn), {
                             ParserUtils::createSelectCase(8, 0, 1 << 3, bridgedMetadataState),
                             ParserUtils::createSelectCase(8, 1 << 3, 1 << 3, mirroredState)
                         }));
        parser->states.push_back(checkMirroredState);

        // This state handles the extraction of egress intrinsic metadata.
        auto *egMetadataState =
            ParserUtils::createGeneratedParserState("egress_metadata", {
                ParserUtils::createSetMetadata(parser, "eg_intr_md_from_prsr", "parser_err", 16, 0),
                // createSetMetadata(parser, "eg_intr_md_from_prsr", "coalesce_sample_count", 8, 0),
                ParserUtils::createExtractCall(parser, parser->tnaParams.at("eg_intr_md"))
            }, checkMirroredState->name);
        parser->states.push_back(egMetadataState);

        addNewStartState(parser, "egress_tna_entry_point", egMetadataState->name);
    }

    IR::ParserState* preorder(IR::ParserState* state) override {
        auto anno = state->getAnnotation("packet_entry");
        if (!anno) return state;
        anno = state->getAnnotation("name");
        auto name = anno->expr.at(0)->to<IR::StringLiteral>();
        if (name->value == ".start_i2e_mirrored") {
            start_i2e_mirrored = state;
        } else if (name->value == ".start_e2e_mirrored") {
            start_e2e_mirrored = state;
        } else if (name->value == ".start_coalesced") {
            start_coalesced = state;
        } else if (name->value == ".start_egress") {
            start_egress = state;
        }
        return state;
    }

    // Delete the compiler-generated start state from frontend.
    IR::ParserState* postorder(IR::ParserState* state) override {
        auto anno = state->getAnnotation("name");
        if (!anno) return state;
        auto name = anno->expr.at(0)->to<IR::StringLiteral>();
        if (name->value == ".start") {
            LOG1("found start state ");
            // Frontend renames 'start' to 'start_0' if the '@packet_entry' pragma is used.
            // The renamed 'start' state has a "@name('.start')" annotation.
            // The translation is introduced at frontends/p4/fromv1.0/converters.cpp#L1121
            // As we will create Tofino-specific start state in this pass, we will need to ensure
            // that the frontend-generated start state is removed and the original start
            // state is restored before the logic in this pass modifies the start state.
            // Basically, the invariant here is to ensure the start state is unmodified,
            // with or w/o the @packet_entry pragma.
            state->name = "start";
            return state;
        } else if (name->value == ".$start") {
            auto selExpr = state->selectExpression->to<IR::SelectExpression>();
            BUG_CHECK(selExpr != nullptr, "Couldn't find the select expression?");
            for (auto c : selExpr->selectCases) {
                if (c->state->path->name == "start_i2e_mirrored") {
                    selectCaseMap.emplace("start_i2e_mirrored", c);
                } else if (c->state->path->name == "start_e2e_mirrored") {
                    selectCaseMap.emplace("start_e2e_mirrored", c);
                } else if (c->state->path->name == "start_coalesced") {
                    selectCaseMap.emplace("start_coalesced", c);
                } else if (c->state->path->name == "start_egress") {
                    selectCaseMap.emplace("start_egress", c);
                }
            }
            return nullptr;
        }
        return state;
    }

    IR::BFN::TnaParser* postorder(IR::BFN::TnaParser *parser) override {
        if (parser->thread == INGRESS)
            addIngressMetadata(parser);
        else
            addEgressMetadata(parser,
                              start_i2e_mirrored,
                              start_e2e_mirrored,
                              start_coalesced,
                              start_egress,
                              selectCaseMap);
        return parser;
    }
};

class AddIntrinsicMetadata : public PassManager {
 public:
     AddIntrinsicMetadata(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
         addPasses({
             new AddMetadataFields,
             new P4::ClonePathExpressions,
             new P4::ClearTypeMap(typeMap),
             new BFN::TypeChecking(refMap, typeMap, true),
             });
     }
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_INTRINSIC_METADATA_H_ */

