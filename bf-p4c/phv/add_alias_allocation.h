#ifndef BF_P4C_PHV_ADD_ALIAS_ALLOCATION_H_
#define BF_P4C_PHV_ADD_ALIAS_ALLOCATION_H_

#include "bf-p4c/phv/phv_fields.h"

namespace PHV {

/**
  * @brief Create allocation objects (PHV::AllocSlice) for alias source
  * fields in preparation for assembly output
  * @pre PhvAnalysis_Pass has been run so that allocation objects are available.
  */
class AddAliasAllocation : public Inspector {
    PhvInfo& phv;
    ordered_set<const PHV::Field*> seen;

    /// Set @source allocation to that of the @range of @dest.  The size of
    /// @range must match the size of @source.
    void addAllocation(PHV::Field* source, PHV::Field* dest, le_bitrange range);

    profile_t init_apply(const IR::Node* root) override {
        seen.clear();
        return Inspector::init_apply(root);
    }
    bool preorder(const IR::BFN::AliasMember*) override;
    bool preorder(const IR::BFN::AliasSlice*) override;
    void end_apply() override;

 public:
    explicit AddAliasAllocation(PhvInfo& p) : phv(p) { }
};

}  // namespace PHV

#endif /* BF_P4C_PHV_ADD_ALIAS_ALLOCATION_H_ */
