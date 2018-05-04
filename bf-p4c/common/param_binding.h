#ifndef _COMMON_PARAM_BINDING_H_
#define _COMMON_PARAM_BINDING_H_

#include <map>
#include "ir/ir.h"

namespace P4 {
class TypeMap;
}  // namespace P4

/*
 *  This pass processes the declarations from architecture definition
 *  before it processes the declarations from user program. The simple way
 *  to guarantee is to apply this pass to IR::P4Program, in which the architecture
 *  declarations always precedes the user program declarations.
 *
 *  For example, in tna.p4, the architecture defines Ingress as:
 *  Ingress ( ...,
 *            ig_intr_md_for_tm_t ig_intr_md_for_tm,
 *            ... );
 *
 *  In a user program, user defines ingress block as:
 *  MyIngress ( ...,
 *            ig_intr_md_for_tm_t ig_tm_md,
 *            ... );
 *
 *  The ParamBinding pass will bind the 'ig_tm_md' param in user program to
 *  the name 'ig_intr_md_for_tm' in tna.p4, because the tna.p4 name is fixed
 *  across all user programs, but the user provided name is not.
 *
 *  The assumption is that if block in the same pipeline has parameters that
 *  are of the same type, the parameters are virtually connected with wires
 *  in the architecture, and it is safe for the backend to assume these parameters
 *  are the same variables. It works for programs with multiple pipes as well,
 *  because each pipe in a multi-pipe architecture is compiled separately.
 *  No false sharing of name could happen in a multi-pipe compilation.
 */

/// ParamBinding creates and tracks instances of package parameters and
/// variable declarations.
class ParamBinding : public Inspector {
    const P4::TypeMap *typeMap;
    std::map<const IR::Type*, const IR::InstanceRef *>          by_type;
    std::map<const IR::Parameter *, const IR::InstanceRef *>    by_param;
    std::map<const IR::Declaration_Variable *, const IR::InstanceRef *>    by_declvar;

 public:
    explicit ParamBinding(const P4::TypeMap *typeMap) : typeMap(typeMap) { }

    /// Add a new header or metadata instance bound to the given parameter.
    void bind(const IR::Parameter *param);

    /// Add a new header or metadata instance bound to the given variable
    /// declaration.
    void bind(const IR::Declaration_Variable *var);

    /// Get the header or metadata instance previously bound to the given
    /// parameter.
    const IR::InstanceRef *get(const IR::Parameter *param) const {
        return by_param.count(param) ? by_param.at(param) : nullptr; }

    /// Get the header or metadata instance previously bound to the given
    /// variable declaration.
    const IR::InstanceRef *get(const IR::Declaration_Variable *var) const {
        return by_declvar.count(var) ? by_declvar.at(var) : nullptr; }

    /// Add a new header or metadata instance bound to the given parameter.
    void postorder(const IR::Parameter *param);

    /// Add a new header or metadata instance bound to the given variable
    /// declaration.
    void postorder(const IR::Declaration_Variable *var);
};

#endif /* _COMMON_PARAM_BINDING_H_ */
