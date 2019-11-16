#ifndef EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_NO_OVERLAY_H_
#define EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_NO_OVERLAY_H_

#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"

/** Adds the no_overlay pragma to the specified fields with the specified gress.
  * Fields with this pragma cannot be overlaid with any other field.
  */
class PragmaNoOverlay : public Inspector {
    PhvInfo& phv_i;

    /// List of fields for which the pragma pa_no_overlay has been specified. Used to print
    /// logging messages.
    ordered_set<const PHV::Field*> fields;

    profile_t init_apply(const IR::Node* root) override {
        profile_t rv = Inspector::init_apply(root);
        fields.clear();
        return rv;
    }

    bool add_constraint(cstring field_name);

    bool preorder(const IR::BFN::Pipe* pipe) override;
    bool preorder(const IR::MAU::Instruction* inst) override;

 public:
    explicit PragmaNoOverlay(PhvInfo& phv) : phv_i(phv) { }

    /// BFN::Pragma interface
    static const char *name;
    static const char *description;
    static const char *help;

    /// @returns the set of fields fo which the pragma pa_no_overlay has been specified in the
    /// program.
    const ordered_set<const PHV::Field*>& getFields() const {
        return fields;
    }

    /// @returns true if field @f has been marked as pa_no_overlay.
    bool count(const PHV::Field* f) const {
        return fields.count(f);
    }
};

std::ostream& operator<<(std::ostream& out, const PragmaNoOverlay& pa_no);

#endif /* EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_NO_OVERLAY_H_ */
