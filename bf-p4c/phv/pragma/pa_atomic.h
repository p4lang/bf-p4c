#ifndef EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_ATOMIC_H_
#define EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_ATOMIC_H_

#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"

/** Adds the atomic pragma to the specified fields with the specified gress.
  * Fields with this pragma cannot be split across containers.
  */
class PragmaAtomic : public Inspector {
    PhvInfo& phv_i;
    const std::set<cstring> disable_pragmas;

    /// List of fields for which the pragma pa_atomic has been specified
    /// Used to print logging messages
    ordered_set<const PHV::Field*> fields;

    profile_t init_apply(const IR::Node* root) override {
        profile_t rv = Inspector::init_apply(root);
        fields.clear();
        return rv;
    }

    bool add_constraint(cstring field_name);

    bool preorder(const IR::BFN::Pipe* pipe) override;

 public:
    explicit PragmaAtomic(PhvInfo& phv) : phv_i(phv) { }

    explicit PragmaAtomic(PhvInfo& phv, const std::set<cstring> disable)
        : phv_i(phv), disable_pragmas(disable) { }

    /// @returns the set of fields fo which the pragma pa_atomic has been specified in the program
    const ordered_set<const PHV::Field*> getFields() const {
        return fields;
    }
};

std::ostream& operator<<(std::ostream& out, const PragmaAtomic& pa_a);

#endif /* EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_ATOMIC_H_ */
