#ifndef EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_ALIAS_H_
#define EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_ALIAS_H_

#include <boost/optional.hpp>
#include <map>
#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils.h"

/** pa_alias pragma support.
 *
 * This pass will gather all pa_alias pragmas and generate pa_alias_i:
 * mapping from a field to another field that it aliases with.
 *
 */
class PragmaAlias : public Inspector {
    PhvInfo& phv_i;

    ordered_map<const PHV::Field*, const PHV::Field*> pa_alias_i;

    /// All PHV::Field objects that have expressions associated with them.
    /// This is used to replace IR::Expression objects for aliased fields later.
    bitvec fieldsWithExpressions;

    profile_t init_apply(const IR::Node* root) override;

    /// Get all fields with IR::Expression objects associated with them.
    bool preorder(const IR::Expression* expr) override;

    /// Get global pragma pa_alias.
    void postorder(const IR::BFN::Pipe* pipe) override;

    void end_apply() override;

 public:
    explicit PragmaAlias(PhvInfo& phv) : phv_i(phv) { }

    const ordered_map<const PHV::Field*, const PHV::Field*>& alias_fields() const {
        return pa_alias_i;
    }
};

std::ostream& operator<<(std::ostream& out, const PragmaAlias& pa_a);

#endif /* EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_ALIAS_H_ */
