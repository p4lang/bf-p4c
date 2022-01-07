#ifndef BF_P4C_PHV_FINALIZE_PHYSICAL_LIVERANGE_H_
#define BF_P4C_PHV_FINALIZE_PHYSICAL_LIVERANGE_H_

#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_fields.h"
#include "ir/ir-generated.h"

namespace PHV {

/// FinalizePhysicalLiverange will update live ranges of allocated slices based on the
/// table placement result stored in IR::MAU::Table. It will also update
/// PhvInfo::table_to_physical_stages so the field->foreach_alloc can still work correctly.
/// The algorithm is simple, by pre-ordering on all IR::Expression, we can get the
/// corresponding overlapped AllocSlice for the expression, and update its live range by
/// the unit of the expression.
class FinalizePhysicalLiverange : public Inspector, TofinoWriteContext {
 private:
    PhvInfo& phv_i;
    const ClotInfo& clot_i;
    const TableSummary& table_summary_i;
    /// AllocSlice to updated live ranges.
    ordered_map<AllocSlice, LiveRange> live_ranges_i;
    /// table pointers of the new IR.
    ordered_set<const IR::MAU::Table*> tables_i;
    /// table name to stages.
    ordered_map<cstring, std::set<int>> table_stages_i;

    /// mark or extends live range of AllocSlices of (@p f, @p bits) to @p unit.
    /// When @p allow_unallocated is false, it will also run a BUG_CHECK to make sure that
    /// we can find a AllocSlice of (@p f, @p bits).
    void mark_access(const PHV::Field* f, le_bitrange bits, const IR::BFN::Unit* unit,
                     bool is_write, bool allow_unallocated = false);

    /// helper functions to update live_ranges_i.
    void update_liverange(const safe_vector<AllocSlice>& slices, const StageAndAccess& op);

 protected:
    /// init_apply clears internal states.
    profile_t init_apply(const IR::Node *root) override {
        live_ranges_i.clear();
        tables_i.clear();
        table_stages_i.clear();
        return Inspector::init_apply(root);
    }

    /// optimization for visitDagOnce = false: we only need to visit parser state once.
    bool preorder(const IR::BFN::ParserState*) override {
        visitOnce();
        return true;
    }

    /// collect table to stages.
    bool preorder(const IR::MAU::Table* t) override;

    /// re-map AllocSlices to physical liverange.
    bool preorder(const IR::Expression* e) override;

    /// updates PhvInfo:
    /// (1) AllocSlice live range.
    /// (2) PhvInfo::table_to_physical_stages.
    void end_apply() override;

 public:
    /// XXX(yumin): we need to set visitDagOnce to be false because there are some IR nodes
    /// that are copied instead of cloned. For example, we notice that the
    /// the *_partition_index:alpm expression is copied but they should be cloned.
    explicit FinalizePhysicalLiverange(PhvInfo& phv,
                                       const ClotInfo& clot,
                                       const TableSummary& table_summary)
        : phv_i(phv), clot_i(clot), table_summary_i(table_summary) {
        visitDagOnce = false;
    }
};

}  // PHV

#endif /* BF_P4C_PHV_FINALIZE_PHYSICAL_LIVERANGE_H_ */
