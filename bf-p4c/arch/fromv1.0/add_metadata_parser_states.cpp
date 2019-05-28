#include "add_metadata_parser_states.h"

#include "bf-p4c/arch/bridge_metadata.h"
#include "bf-p4c/arch/intrinsic_metadata.h"
#include "bf-p4c/arch/fromv1.0/phase0.h"
#include "bf-p4c/arch/fromv1.0/mirror.h"
#include "bf-p4c/arch/fromv1.0/resubmit.h"
#include "bf-p4c/arch/remove_set_metadata.h"
#include "bf-p4c/midend/parser_utils.h"

namespace BFN {

/// If after translation, both the $phase0 and $resubmit states are still empty,
/// i.e. no phase0 or resubmit data to parse, we can safely delete these states
/// and skip to parsing the packet directly. Likewise, we can do the same for
/// $bridged_metadata and $mirrored on egress.
///
struct ElimUnusedMetadataStates : Transform {
    IR::ParserState* tmp = nullptr;

    bool no_phase0 = false, no_resubmit = false;
    bool no_mirrored = false, no_bridged = false;

    void skip_to_packet(IR::ParserState* state) {
        state->components = tmp->components;
        state->selectExpression = tmp->selectExpression;
    }

    bool is_empty(IR::ParserState* state) {
        if (state->components.size() == 1) {
            if (auto call = state->components[0]->to<IR::MethodCallStatement>()) {
                if (auto method = call->methodCall->method->to<IR::Member>()) {
                    if (method->member == "advance") {
                        tmp = state;
                        return true;
                    }
                }
            }
        }

        return false;
    }

    IR::Node* postorder(IR::ParserState* state) override {
        if (state->name == "__phase0")   no_phase0 = is_empty(state);
        if (state->name == "__resubmit") no_resubmit = is_empty(state);
        if (state->name == "__mirrored") no_mirrored = is_empty(state);
        if (state->name == "__bridged_metadata")  no_bridged = is_empty(state);

        if (state->name == "__check_resubmit" && no_phase0 && no_resubmit)
            skip_to_packet(state);

        if (state->name == "__check_mirrored" && no_mirrored && no_bridged)
            skip_to_packet(state);

        return state;
    }

    IR::Node* postorder(IR::BFN::TnaParser* parser) override {
        IR::IndexedVector<IR::ParserState> states;

        for (auto state : parser->states) {
            if (no_phase0 && no_resubmit) {
                if (state->name == "__phase0" || state->name == "__resubmit")
                    continue;
            }

            if (no_mirrored && no_bridged) {
                if (state->name == "__mirrored" || state->name == "__bridged")
                    continue;
            }

            states.push_back(state);
        }

        parser->states = states;

        return parser;
    }
};

AddMetadataParserStates::AddMetadataParserStates(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
    addPasses({
        new AddIntrinsicMetadata(refMap, typeMap),
        new RemoveSetMetadata(refMap, typeMap),
        new TranslatePhase0(refMap, typeMap),
        new AddTnaBridgeMetadata(refMap, typeMap),
        new FixupResubmitMetadata(refMap, typeMap),
        new FixupMirrorMetadata(refMap, typeMap),
        new ElimUnusedMetadataStates
    });
}

}  // namespace BFN
