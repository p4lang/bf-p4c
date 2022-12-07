#ifndef BF_P4C_PHV_V2_TABLE_REPLAY_FRIENDLY_CONSTRAINTS_H_
#define BF_P4C_PHV_V2_TABLE_REPLAY_FRIENDLY_CONSTRAINTS_H_

#include <algorithm>
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/common/field_defuse.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/phv/pragma/pa_no_init.h"

struct AllocInfo {
    int length;
    size_t container_size;
};

namespace PHV {
namespace v2 {

// This pass adds a few pa_container_size constraints based on the feedback from table summary after
// table replay failure. These pa_container_size constraints are trying to replay the trivial
// allocation result for the problematic table provided by table summary. And this can potentially
// fix the problematic's fitting issue and advance the table replay.
class TableReplayFriendlyPhvConstraints : public Transform {
    MauBacktracker &mau_backtracker;
    PhvInfo &phv;
    const ordered_map<cstring, ordered_map<int, AllocInfo>> &trivial_allocation_info;
    ordered_map<cstring, std::vector<PHV::Size>> add_pa_container_size;

 public:
    const ordered_map<cstring, std::vector<PHV::Size>> &get_container_size_constr() {
        return add_pa_container_size;
    }
    void clear_container_size_constr() {
        add_pa_container_size.clear();
    }
    TableReplayFriendlyPhvConstraints(
        MauBacktracker &mau_backtracker, PhvInfo &phv,
        const ordered_map<cstring, ordered_map<int, AllocInfo>> &trivial_allocation_info):
            mau_backtracker(mau_backtracker), phv(phv),
            trivial_allocation_info(trivial_allocation_info) {}

    Visitor::profile_t init_apply(const IR::Node* root) {
        add_pa_container_size.clear();
        return Transform::init_apply(root);
    }

    const IR::Node *preorder(IR::BFN::Pipe * pipe) {
        if (mau_backtracker.get_table_summary()->getActualState() !=
           TableSummary::ALT_FINALIZE_TABLE_SAME_ORDER_TABLE_FIXED) {
            prune();
            add_pa_container_size.clear();
        }
        return pipe;
    }
    const IR::Node *preorder(IR::Expression *expr) override;

    const IR::Node *postorder(IR::BFN::Pipe *pipe) {
        LOG5("print all pa container size");
        LOG5("pipe is " + pipe->canon_name());
        for (auto it : add_pa_container_size) {
            LOG5(it.first);
            for (auto size : it.second) {
                LOG5(size);
            }
        }
        return pipe;
    }
};

// This table collects PHV allocation results after phv analysis. It provides information for
// TableReplayFriendlyPhvConstraints, so that it can replay trivial phv allocation result for some
// table
class CollectPHVAllocationResult : public Inspector {
    // This data structure maps the name of a field to a map that maps alignment to AllocInfo.
    // For example, if a field's name is f and it has two AllocSlice, one is allocating [7:0] to a
    // 8-bit container, another is allocation [8:15] to another 8-bit container. Then one entry of
    // allocation info is f -> { { 0 -> { length = 8, container_size = 8 },
    // { 8 -> { length = 8, container_size = 8 } } }}
    ordered_map<cstring, ordered_map<int, AllocInfo>> allocation_info;
    PhvInfo &phv;
 public:
    explicit CollectPHVAllocationResult(PhvInfo &phv) : phv(phv) {}
    void end_apply(const IR::Node *) override;
    const ordered_map<cstring, ordered_map<int, AllocInfo>> &get_allocation_info()
        { return allocation_info; }
};

}  // namespace v2
}  // namespace PHV

#endif /* BF_P4C_PHV_V2_TABLE_REPLAY_FRIENDLY_CONSTRAINTS_H_ */
