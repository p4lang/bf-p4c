#ifndef EXTENSIONS_BF_P4C_PHV_ALLOCATE_VIRTUAL_CONTAINERS_H_
#define EXTENSIONS_BF_P4C_PHV_ALLOCATE_VIRTUAL_CONTAINERS_H_

#include "ir/ir.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "bf-p4c/parde/clot_info.h"

namespace PHV {
class Container;
class Field;
}  // namespace PHV

/** Create and "virtual" PHV containers and use them to allocate fields that
 * did not fit in physical PHV containers.
 *
 * @pre PHV_Bind.
 */
class AllocateVirtualContainers : public Visitor {
 private:
    PhvInfo &phv_i;                                 // all fields in input
    const PhvUse &uses_i;                           // field uses mau, I, E
    const ClotInfo &clot_i;

    const IR::Node * apply_visitor(const IR::Node *, const char *);

    /** For each field not fully allocated:
     *   - remove it from any containers it was previously (partially) allocated to
     *   - create enough fresh virtual containers to fit it, and allocate it to them
     */
    void trivial_allocate(ordered_set<PHV::Field *>&);

    /// Helper function for `trivial_allocate`.
    void container_contiguous_alloc(PHV::Field *, int, PHV::Container *, int);

 public:
    AllocateVirtualContainers(PhvInfo &phv, const PhvUse &uses, const ClotInfo &clot)
      : phv_i(phv), uses_i(uses), clot_i(clot) { }
};


#endif /* EXTENSIONS_BF_P4C_PHV_ALLOCATE_VIRTUAL_CONTAINERS_H_ */
