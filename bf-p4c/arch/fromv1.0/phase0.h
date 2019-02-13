#ifndef BF_P4C_ARCH_FROMV1_0_PHASE0_H_
#define BF_P4C_ARCH_FROMV1_0_PHASE0_H_

#include "ir/ir.h"

namespace P4 {
class ReferenceMap;
class TypeMap;
}  // namespace P4

namespace BFN {

/**
 * Searches for a phase 0 table and transforms the program to implement it.
 *
 * If a phase 0 table is found, the following transformations are performed:
 *  - The `apply()` call that invokes the phase 0 table is removed. The table
 *  itself remains in case it's invoked in multiple places; if it isn't, dead
 *  code elimination will remove it.
 *  - An `@phase0` annotation describing the control plane API for the phase 0
 *  table and the layout of its fields is generated and attached to the ingress
 *  control.
 *  - A parser state which extracts the phase 0 data and implements the phase
 *  0 table's action is generated and substituted into the `__phase0` parser
 *  state.
 *
 * XXX(seth): There is a known issue with this pass: the parser it generates
 * will be invalid if the P4 program uses a different name for the TNA M
 * parameter in the ingress parser than it uses in the ingress control. This
 * will get fixed with a followup PR.
 *
 * @pre All controls are inlined, the program has been transformed to use the
 * TNA architecture, and a `__phase0` parser state has been created.
 * @post The transformations above are applied if a phase 0 table is found.
 */
struct TranslatePhase0 : public PassManager {
    TranslatePhase0(P4::ReferenceMap* refMap, P4::TypeMap* typeMap);
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_FROMV1_0_PHASE0_H_ */
