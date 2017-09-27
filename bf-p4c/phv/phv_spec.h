#ifndef EXTENSIONS_BF_P4C_PHV_PHV_SPEC_H_
#define EXTENSIONS_BF_P4C_PHV_PHV_SPEC_H_

#include <vector>
#include "bf-p4c/phv/phv.h"
#include "lib/ordered_map.h"

class cstring;

class PhvSpec {
 protected:
    std::vector<PHV::Type> definedTypes;
    ordered_map<PHV::Type, unsigned> typeIdMap;

    /// Add a PHV container type to the set of types which are available on this
    /// device. This should only be called inside the constructor of subclasses
    /// of PhvSpec; after a PhvSpec instance is constructed, its list of
    /// container types is considered immutable.
    void addType(PHV::Type t);

 public:
    /// @return the PHV container types available on this device.
    const std::vector<PHV::Type>& containerTypes() const;

    /// @return the number of PHV container types available on this device.
    /// Behaves the same as `containerTypes().size()`.
    unsigned numContainerTypes() const;

    /// @return the PHV container type corresponding to the given numeric id.
    /// Different devices may map the same id to different types. Behaves the
    /// as `containerTypes()[id]`.
    PHV::Type idToContainerType(unsigned id) const;

    /// @return a numeric id that uniquely specifies the given PHV container
    /// type on this device. Different devices may map the same type to
    /// different ids. This behaves the same as using `std::find_if` to find the
    /// index of the given type in `containerTypes()`.
    unsigned containerTypeToId(PHV::Type type) const;

    /// @return the PHV container corresponding to the given numeric id on this
    /// device. Different devices have different PHV containers, so ids are not
    /// consistent between devices.
    PHV::Container idToContainer(unsigned id) const;

    /// @return a numeric id that uniquely specifies the given PHV container on
    /// this device. Different devices have different PHV containers, so ids are
    /// not consistent between devices.
    unsigned containerToId(PHV::Container container) const;

    /// @return a string representation of the provided @set of containers.
    cstring containerSetToString(const bitvec& set) const;

    /// @return the ids of every container in the same deparser group as the
    /// provided container.
    virtual bitvec deparserGroup(unsigned id) const = 0;

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
    virtual bitvec range(PHV::Type t, unsigned start, unsigned length) const = 0;

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
    TofinoPhvSpec();

    bitvec deparserGroup(unsigned id) const override;

    bitvec range(PHV::Type t, unsigned start, unsigned length) const override;

    const bitvec& ingressOnly() const override;

    const bitvec& egressOnly() const override;

    bitvec tagalongGroup(unsigned groupIndex) const override;

    const bitvec& individuallyAssignedContainers() const override;

    const bitvec& physicalContainers() const override;
};

#if HAVE_JBAY
class JBayPhvSpec : public PhvSpec {
 public:
    JBayPhvSpec();

    bitvec deparserGroup(unsigned id) const override;

    bitvec range(PHV::Type t, unsigned start, unsigned length) const override;

    const bitvec& ingressOnly() const override;

    const bitvec& egressOnly() const override;

    bitvec tagalongGroup(unsigned groupIndex) const override;

    const bitvec& individuallyAssignedContainers() const override;

    const bitvec& physicalContainers() const override;
};
#endif /* HAVE_JBAY */

#endif /* EXTENSIONS_BF_P4C_PHV_PHV_SPEC_H_ */
