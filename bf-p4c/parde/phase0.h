#ifndef BF_P4C_PARDE_PHASE0_H_
#define BF_P4C_PARDE_PHASE0_H_

#include <utility>
#include <vector>

#include "lib/cstring.h"
#include "lib/hex.h"

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
    const cstring tableName;      /// The phase 0 table name.
    const cstring actionName;     /// The phase 0 action name.
    const cstring keyName;        /// The phase 0 key name.
    const FieldPacking* packing;  /// How the phase 0 fields should be packed.
    const int pipe_id;
};

/**
 * Searches for an @phase0 annotation and adds the metadata to the pipe so that
 * we can generate the phase 0 assembly the driver needs.
 *
 * @param ingress  The control/parser to search for the phase 0 table. As the name
 *                 implies, this only makes sense for the ingress control.
 * @param pipe     The pipe to which any phase 0 metadata we find should be
 *                 attached.
 * @param refMap   An reference map with up-to-date information for the ingress
 *                 control.
 */
void extractPhase0(const IR::Node* ingress, IR::BFN::Pipe* pipe,
                   P4::ReferenceMap* refMap);

}  // namespace BFN

std::ostream& operator<<(std::ostream& out, const BFN::Phase0Info* info);

#endif /* BF_P4C_PARDE_PHASE0_H_ */
