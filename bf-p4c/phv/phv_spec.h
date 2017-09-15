#ifndef EXTENSIONS_BF_P4C_PHV_PHV_SPEC_H_
#define EXTENSIONS_BF_P4C_PHV_PHV_SPEC_H_

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
    virtual bitvec range(PHV::Kind kind, unsigned start, unsigned length) const = 0;

    /// @return a bitvec of the containers which are hard-wired to ingress.
    virtual const bitvec& ingressOnly() const = 0;

    /// @return a bitvec of the containers which are hard-wired to egress.
    virtual const bitvec& egressOnly() const = 0;

    /// @return the ids of every container in the given tagalong group.
    virtual bitvec tagalongGroup(unsigned groupIndex) const = 0;

    /// @return the ids of containers that can be assigned to a thread
    /// individually.
    virtual const bitvec& individuallyAssignedContainers() const = 0;

    /// @return the ids of all containers which actually exist on the Tofino
    /// hardware - i.e., all non-overflow containers.
    virtual const bitvec& physicalContainers() const = 0;
};


class TofinoPhvSpec : public PhvSpec {
 public:
    bitvec range(PHV::Kind kind, unsigned start, unsigned length) const override;

    const bitvec& ingressOnly() const override;

    const bitvec& egressOnly() const override;

    bitvec tagalongGroup(unsigned groupIndex) const override;

    const bitvec& individuallyAssignedContainers() const override;

    const bitvec& physicalContainers() const override;
};

#endif /* EXTENSIONS_BF_P4C_PHV_PHV_SPEC_H_ */
