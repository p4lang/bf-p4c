#ifndef EXTENSIONS_BF_P4C_PARDE_CLOT_PRAGMA_DO_NOT_USE_CLOT_H_
#define EXTENSIONS_BF_P4C_PARDE_CLOT_PRAGMA_DO_NOT_USE_CLOT_H_

#include <map>
#include <optional>
#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils/utils.h"

/**
 * @brief do_not_use_clot pragma support.
 *
 * This pass will gather all do_not_use_clot pragmas and generate do_not_use_clot:
 * a set of fields that should not be allocated to CLOTs.
 */
class PragmaDoNotUseClot : public Inspector {
    const PhvInfo& phv_info;
    ordered_set<const PHV::Field*> do_not_use_clot;

    profile_t init_apply(const P4::IR::Node* root) override {
        profile_t rv = Inspector::init_apply(root);
        do_not_use_clot.clear();
        return rv;
    }

    /**
     * @brief Get global pragma do_not_use_clot.
     */
    bool preorder(const P4::IR::BFN::Pipe* pipe) override;

 public:
    explicit PragmaDoNotUseClot(const PhvInfo& phv_info) : phv_info(phv_info) { }

    // BFN::Pragma interface
    static const char *name;
    static const char *description;
    static const char *help;

    const ordered_set<const PHV::Field*>& do_not_use_clot_fields() const {
        return do_not_use_clot;
    }
};

std::ostream& operator<<(std::ostream& out, const PragmaDoNotUseClot& do_not_use_clot);

#endif /* EXTENSIONS_BF_P4C_PARDE_CLOT_PRAGMA_DO_NOT_USE_CLOT_H_ */
