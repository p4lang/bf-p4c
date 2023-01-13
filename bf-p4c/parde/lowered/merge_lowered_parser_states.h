#ifndef EXTENSIONS_BF_P4C_PARDE_LOWERED_MERGE_LOWERED_PARSER_STATES_H_
#define EXTENSIONS_BF_P4C_PARDE_LOWERED_MERGE_LOWERED_PARSER_STATES_H_

#include "bf-p4c/logging/phv_logging.h"
#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/parde/lowered/compute_lowered_parser_ir.h"
#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/parde/parser_info.h"

namespace Parde::Lowered {

/// After parser lowering, we have converted the parser IR from P4 semantic (action->match)
/// to HW semantic (match->action), there may still be opportunities where we can merge states
/// where we couldn't before lowering (without breaking the P4 semantic).
struct MergeLoweredParserStates : public ParserTransform {
    const CollectLoweredParserInfo& parser_info;
    const ComputeLoweredParserIR& computed;
    ClotInfo& clot;
    PhvLogging::CollectDefUseInfo* defuseInfo;

    explicit MergeLoweredParserStates(const CollectLoweredParserInfo& pi,
                                      const ComputeLoweredParserIR& computed, ClotInfo& c,
                                      PhvLogging::CollectDefUseInfo* defuseInfo)
        : parser_info(pi), computed(computed), clot(c), defuseInfo(defuseInfo) {}

    // Compares all fields in two LoweredParserMatch objects
    // except for the match values.  Essentially returns if both
    // LoweredParserMatch do the same things when matching.
    //
    // Equivalent to IR::BFN::LoweredParserMatch::operator==(IR::BFN::LoweredParserMatch const & a)
    // but considering the loop fields and with the value fields masked off.
    bool compare_match_operations(const IR::BFN::LoweredParserMatch* a,
                                  const IR::BFN::LoweredParserMatch* b);

    const IR::BFN::LoweredParserMatch* get_unconditional_match(
        const IR::BFN::LoweredParserState* state);

    struct RightShiftPacketRVal : public Modifier {
        int byteDelta = 0;
        bool oob = false;

        explicit RightShiftPacketRVal(int byteDelta) : byteDelta(byteDelta) {}

        bool preorder(IR::BFN::LoweredPacketRVal* rval) override;
    };

    // Checksum also needs the masks to be shifted
    struct RightShiftCsumMask : public Modifier {
        int byteDelta = 0;
        bool oob = false;
        bool swapMalform = false;

        explicit RightShiftCsumMask(int byteDelta) : byteDelta(byteDelta) {}

        bool preorder(IR::BFN::LoweredParserChecksum* csum) override;
    };

    bool can_merge(const IR::BFN::LoweredParserMatch* a, const IR::BFN::LoweredParserMatch* b);

    void do_merge(IR::BFN::LoweredParserMatch* match, const IR::BFN::LoweredParserMatch* next);

    // do not merge loopback state for now, need to maitain loopback pointer TODO
    // p4-tests/p4_16/compile_only/p4c-1601-neg.p4
    bool is_loopback_state(cstring state);

    IR::Node* preorder(IR::BFN::LoweredParserMatch* match) override;
};

}  // namespace Parde::Lowered

#endif /* EXTENSIONS_BF_P4C_PARDE_LOWERED_MERGE_LOWERED_PARSER_STATES_H_ */
