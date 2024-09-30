#ifndef BF_P4C_MAU_VALIDATE_ACTIONS_H_
#define BF_P4C_MAU_VALIDATE_ACTIONS_H_

#include "bf-p4c/mau/mau_visitor.h"
#include "ir/visitor.h"
#include "bf-p4c/phv/phv_fields.h"

class PhvInfo;
class ReductionOrInfo;

class ValidateActions final : public MauInspector {
 private:
    const PhvInfo &phv;
    const ReductionOrInfo &red_info;
    bool stop_compiler;
    bool phv_alloc;
    bool ad_alloc;
    bool warning_found = false;

    // true if action analysis finds a PHV allocation that violates MAU constraints.
    bool error_found = false;

    profile_t init_apply(const P4::IR::Node* root) override;
    bool preorder(const P4::IR::MAU::Action *act) override;
    void end_apply() override;

 public:
    explicit ValidateActions(const PhvInfo &p, const ReductionOrInfo &ri, bool sc, bool pa, bool ad)
        : phv(p), red_info(ri), stop_compiler(sc), phv_alloc(pa), ad_alloc(ad) {}
};

#endif /* BF_P4C_MAU_VALIDATE_ACTIONS_H_ */
