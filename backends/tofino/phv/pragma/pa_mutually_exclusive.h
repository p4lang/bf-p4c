#ifndef EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_MUTUALLY_EXCLUSIVE_H_
#define EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_MUTUALLY_EXCLUSIVE_H_

#include <map>
#include <optional>
#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils/utils.h"

/** pa_mutually_exclusive pragma support.
 *
 * This pass will gather all pa_mutually_exclusive pragmas and generate pa_mutually_exclusive_i:
 * mapping from a field to the set of fields it is mutually exclusive with.
 *
 */
class PragmaMutuallyExclusive : public Inspector {
    const PhvInfo& phv_i;
    ordered_map<const PHV::Field*, ordered_set<const PHV::Field*>> pa_mutually_exclusive_i;
    ordered_map<cstring, ordered_set<cstring>> mutually_exclusive_headers;

    profile_t init_apply(const IR::Node* root) override {
        profile_t rv = Inspector::init_apply(root);
        pa_mutually_exclusive_i.clear();
        mutually_exclusive_headers.clear();
        return rv;
    }

    /** Get global pragma pa_mutually_exclusive.
     */
    bool preorder(const IR::BFN::Pipe* pipe) override;

 public:
    explicit PragmaMutuallyExclusive(const PhvInfo& phv) : phv_i(phv) { }

    /// BFN::Pragma interface
    static const char *name;
    static const char *description;
    static const char *help;

    const ordered_map<const PHV::Field*, ordered_set<const PHV::Field*>>& mutex_fields() const {
        return pa_mutually_exclusive_i;
    }
    const ordered_map<cstring, ordered_set<cstring>>& mutex_headers() const {
        return mutually_exclusive_headers;
    }
};

std::ostream& operator<<(std::ostream& out, const PragmaMutuallyExclusive& pa_me);

#endif /* EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_MUTUALLY_EXCLUSIVE_H_ */
