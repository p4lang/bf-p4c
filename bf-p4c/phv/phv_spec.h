#ifndef EXTENSIONS_TOFINO_PHV_PHV_SPEC_H_
#define EXTENSIONS_TOFINO_PHV_PHV_SPEC_H_

#include "lib/bitvec.h"

namespace PHV {
    /// An enumeration of the possible PHV container types.
    enum class Kind : unsigned {
        B = 0,   /// 8-bit
        H = 1,   /// 16-bit
        W = 2,   /// 32-bit
        TB = 3,  /// 8-bit tagalong
        TH = 4,  /// 16-bit tagalong
        TW = 5   /// 32-bit tagalong
    };
    static constexpr unsigned NumKinds = 6;

    std::ostream &operator<<(std::ostream &out, const Kind k);
}  // namespace PHV

class PhvSpec {
 public:
    /**
     * Generates a bitvec containing a range of containers. This kind of bitvec
     * can be used to implement efficient set operations on large numbers of
     * containers.
     *
     * To generate the range [B10, B16), use `range(Kind::B, 10, 6)`.
     *
     * @param kind The type of container.
     * @param start The index of first container in the range.
     * @param length The number of containers in the range. May be zero.
     */
    bitvec range(PHV::Kind kind, unsigned start, unsigned length) const;

    /// @return a bitvec of the containers which are hard-wired to ingress.
    const bitvec& ingressOnly() const;

    /// @return a bitvec of the containers which are hard-wired to egress.
    const bitvec& egressOnly() const;

    /// @return the ids of every container in the given tagalong group.
    bitvec tagalongGroup(unsigned groupIndex) const;

    /// @return the ids of containers that can be assigned to a thread
    /// individually.
    const bitvec& individuallyAssignedContainers() const;

    /// @return the ids of all containers which actually exist on the Tofino
    /// hardware - i.e., all non-overflow containers.
    const bitvec& physicalContainers() const;
};


class TofinoPhvSpec : public PhvSpec {
};

#endif /* EXTENSIONS_TOFINO_PHV_PHV_SPEC_H_ */
