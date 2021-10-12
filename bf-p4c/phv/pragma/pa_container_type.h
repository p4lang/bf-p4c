#ifndef EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_CONTAINER_TYPE_H_
#define EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_CONTAINER_TYPE_H_

#include <boost/optional/optional.hpp>
#include "bf-p4c/phv/phv.h"
#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"

/** Specifies the type of container to which a field should be allocated.
  * Syntax is: \@pragma pa_container_type <gress> <fieldname> <container_type>
  * container_type can be any PHV::Kind, except tagalong containers.
  * XXX(Deep): Support specifying tagalong containers as a container kind.
 */
class PragmaContainerType : public Inspector {
    PhvInfo& phv_i;

    /// Map of fields for which the pragma pa_container_type has been specified to the kind of
    /// suggested container.
    /// Used to print logging messages
    ordered_map<const PHV::Field*, PHV::Kind> fields;

    profile_t init_apply(const IR::Node* root) override {
        profile_t rv = Inspector::init_apply(root);
        fields.clear();
        return rv;
    }

    /// Adds the constraint that @p field_name should be allocated to container type @p kind.
    bool add_constraint(const IR::BFN::Pipe* pipe, const IR::Expression* expr,
                        cstring field_name, PHV::Kind kind);

    bool preorder(const IR::BFN::Pipe* pipe) override;

 public:
    explicit PragmaContainerType(PhvInfo& phv) : phv_i(phv) { }

    /// @returns the map of fields and suggested container type for which the pragma
    /// pa_container_type has been specified in the program.
    const ordered_map<const PHV::Field*, PHV::Kind>& getFields() const {
        return fields;
    }

    boost::optional<PHV::Kind> required_kind(const PHV::Field* f) const;

    /// BFN::Pragma interface
    static const char *name;
    static const char *description;
    static const char *help;
};

std::ostream& operator<<(std::ostream& out, const PragmaContainerType& pa_ct);

#endif /* EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_CONTAINER_TYPE_H_ */
