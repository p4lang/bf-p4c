#include "constraints.h"

namespace Constraints {

std::ostream &operator<<(std::ostream &out, const SolitaryConstraint& cons) {
    out << "(";
    if (cons.isALU())
        out << "alu ";
    if (cons.isChecksum())
        out << "checksum ";
    if (cons.isArch())
        out << "arch ";
    if (cons.isDigest())
        out << "digest ";
    if (cons.isPragmaSolitary())
        out << "pragma_solitary ";
    if (cons.isPragmaContainerSize())
        out << "pragma_container_size ";
    if (cons.isClearOnWrite())
        out << "clear_on_write ";
    out << ")";
    return out;
}

}  // namespace Constraints
