#ifndef BF_P4C_PHV_V2_PHV_ALLOCATOR_V2_H_
#define BF_P4C_PHV_V2_PHV_ALLOCATOR_V2_H_

#include "bf-p4c/phv/allocate_phv.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/utils/utils.h"
#include "lib/cstring.h"

namespace PHV {
namespace v2 {

class PhvAllocation : public Visitor {
    const AllocUtils& utils_i;
    const MauBacktracker& mau_bt_i;
    PhvInfo& phv_i;
    int pipe_id_i;

    const IR::Node *apply_visitor(const IR::Node* root, const char *name = 0) override;

 public:
    PhvAllocation(const PHV::AllocUtils& utils, const MauBacktracker& mau, PhvInfo& phv)
        : utils_i(utils), mau_bt_i(mau), phv_i(phv) {}
};

}  // namespace v2
}  // namespace PHV

#endif /* BF_P4C_PHV_V2_PHV_ALLOCATOR_V2_H_ */
