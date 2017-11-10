#ifndef BF_P4C_PARDE_PHASE0_H_
#define BF_P4C_PARDE_PHASE0_H_

#include <utility>
#include <vector>

#include "lib/cstring.h"

namespace IR {
namespace BFN {
class Pipe;
}  // namespace BFN
class P4Control;
class P4Table;
}  // namespace IR

namespace P4 {
class ReferenceMap;
class TypeMap;
}  // namespace P4

namespace BFN {

struct FieldPacking;

/// Phase 0 metadata; used to generate phase 0 assembly.
struct Phase0Info {
    const IR::P4Table* table;      /// The phase 0 table.
    const FieldPacking* packing;   /// How the phase 0 fields should be packed.
    const std::string actionName;  /// The phase 0 action name
};

/**
 * Searches for a phase 0 table. If one is found, it's removed from the program,
 * and parser code implementing its behavior is patched into the parser program.
 * The metadata needed to generate the assembly output for phase 0 is also
 * attached to the pipe.
 *
 * @param ingress  The control to search for the phase 0 table. As the name
 *                 implies, this only makes sense for the ingress control.
 * @param pipe     The pipe to which any generated phase 0 parser should be
 *                 attached.
 * @return a new ingress control without the phase 0 table, and a new pipe which
 *         includes the phase 0 parser. If there is no phase 0 table, the
 *         original ingress control and pipe are returned unaltered.
 */
std::pair<const IR::P4Control*, IR::BFN::Pipe*>
extractPhase0(const IR::P4Control* ingress, IR::BFN::Pipe* pipe,
              P4::ReferenceMap* refMap, P4::TypeMap* typeMap);

}  // namespace BFN

std::ostream& operator<<(std::ostream& out, const BFN::Phase0Info* info);

#endif /* BF_P4C_PARDE_PHASE0_H_ */
