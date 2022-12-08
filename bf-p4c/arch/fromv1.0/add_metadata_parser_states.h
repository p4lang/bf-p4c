#ifndef BF_P4C_ARCH_FROMV1_0_ADD_METADATA_PARSER_STATES_H_
#define BF_P4C_ARCH_FROMV1_0_ADD_METADATA_PARSER_STATES_H_

#include "ir/ir.h"
#include "ir/pass_manager.h"

namespace P4 {
class ReferenceMap;
class TypeMap;
}

namespace BFN {

struct ElimUnusedMetadataStates : Transform {
    IR::ParserState* tmp = nullptr;

    bool no_phase0 = false, no_resubmit = false;
    bool no_mirrored = false, no_bridged = false;

    void skip_to_packet(IR::ParserState* state);
    bool is_empty(IR::ParserState* state);
    IR::Node* postorder(IR::ParserState* state) override;
    IR::Node* postorder(IR::P4Parser* parser) override;
};

/// Add parser states to parse ingress and egress intrinsic metadata generated by Tofino.
/// And then add parser states to parse metadata that is prepended to user packet data.
/// These are, on ingress, phase0 and resubmit metadata; And on egress, bridged and mirror metadata.
struct AddMetadataParserStates : PassManager {
    bool use_bridge_metadata = false;
    AddMetadataParserStates(P4::ReferenceMap* refMap, P4::TypeMap* typeMap);
};

}  // namespace BFN

#endif  /* BF_P4C_ARCH_FROMV1_0_ADD_METADATA_PARSER_STATES_H_ */
