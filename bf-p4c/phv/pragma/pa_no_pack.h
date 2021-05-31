#ifndef EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_NO_PACK_H_
#define EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_NO_PACK_H_

#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils/utils.h"
#include "ir/ir.h"

class PragmaNoPack : public Inspector {
    const PhvInfo& phv_i;
    std::vector<std::pair<const PHV::Field*, const PHV::Field*>> no_packs_i;

    profile_t init_apply(const IR::Node* root) override {
        profile_t rv = Inspector::init_apply(root);
        no_packs_i.clear();
        return rv;
    }

    bool preorder(const IR::BFN::Pipe* pipe) override;

 public:
    explicit PragmaNoPack(const PhvInfo& phv) : phv_i(phv) {}

    const std::vector<std::pair<const PHV::Field*, const PHV::Field*>>& no_packs() const {
        return no_packs_i;
    }

    /// BFN::Pragma interface
    static const char* name;
    static const char* description;
    static const char* help;
};

#endif /* EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_NO_PACK_H_ */