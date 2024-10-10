#ifndef BF_P4C_PHV_V2_PHV_ALLOCATION_V2_H_
#define BF_P4C_PHV_V2_PHV_ALLOCATION_V2_H_

#include "lib/cstring.h"

#include "bf-p4c/phv/v2/phv_kit.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/utils/utils.h"

namespace PHV {
namespace v2 {

class PhvAllocation : public Visitor {
    const PhvKit& kit_i;
    const MauBacktracker& mau_bt_i;
    PhvInfo& phv_i;
    int pipe_id_i = -1;

    const IR::Node *apply_visitor(const IR::Node* root, const char *name = 0) override;

 public:
    PhvAllocation(const PhvKit& kit, const MauBacktracker& mau, PhvInfo& phv)
        : kit_i(kit), mau_bt_i(mau), phv_i(phv) {}
};

}  // namespace v2
}  // namespace PHV

#endif /* BF_P4C_PHV_V2_PHV_ALLOCATION_V2_H_ */
