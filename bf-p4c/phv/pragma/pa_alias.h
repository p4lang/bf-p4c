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
 public:
    struct AliasDestination {
        /// The alias destination field.
        cstring field;

        /// The range of the field being aliased, or boost::none when the
        /// entire field is aliased.
        boost::optional<le_bitrange> range;
    };

    /// Map type from alias sources to destinations.
    using AliasMap = ordered_map<cstring, AliasDestination>;

 private:
    const PhvInfo& phv_i;
    AliasMap aliasMap;

    /// All PHV::Field objects that have expressions associated with them.
    /// This is used to replace IR::Expression objects for aliased fields later.
    bitvec fieldsWithExpressions;

    profile_t init_apply(const IR::Node* root) override;

    /// Get all fields with IR::Expression objects associated with them.
    bool preorder(const IR::Expression* expr) override;

    /// Get global pragma pa_alias.
    void postorder(const IR::BFN::Pipe* pipe) override;

 public:
    explicit PragmaAlias(PhvInfo& phv) : phv_i(phv) { }
    const AliasMap& getAliasMap() const { return aliasMap; }
};

std::ostream& operator<<(std::ostream& out, const PragmaAlias& pa_a);
std::ostream &operator<<(std::ostream &, const PragmaAlias::AliasDestination& dest);

#endif /* EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_ALIAS_H_ */
