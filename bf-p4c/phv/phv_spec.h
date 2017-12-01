#ifndef EXTENSIONS_BF_P4C_PHV_PHV_SPEC_H_
#define EXTENSIONS_BF_P4C_PHV_PHV_SPEC_H_

#include <boost/optional.hpp>
#include <vector>
#include "bf-p4c/phv/phv.h"
#include "lib/ordered_map.h"

class cstring;

class PhvSpec {
 protected:
    std::vector<PHV::Type> definedTypes;
    ordered_map<PHV::Type, unsigned> typeIdMap;

    /**
     * @used to describe phv groups for mau in the device. 
     * e.g. entry { PHV::Type::W, std::pair(4,16) } means for normal 32b
     * container, there are 4 groups, each with 16 containers.
     */
    std::map<PHV::Type, std::pair<unsigned, unsigned>> mauGroupSpec;

    std::map<PHV::Type, std::vector<unsigned>> ingressOnlyMauGroupIds;

    std::map<PHV::Type, std::vector<unsigned>> egressOnlyMauGroupIds;

    std::map<PHV::Type, unsigned> tagalongCollectionSpec;

    unsigned numTagalongCollections = 0;

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
    bitvec range(PHV::Type t, unsigned start, unsigned length) const;

    /// @return containers that constraint to either ingress or egress
    bitvec ingressOrEgressOnlyContainers(
        const std::map<PHV::Type, std::vector<unsigned>>& gressOnlyMauGroupIds) const;

    /// @return a bitvec of the containers which are hard-wired to ingress.
    const bitvec& ingressOnly() const;

    /// @return a bitvec of the containers which are hard-wired to egress.
    const bitvec& egressOnly() const;

    /// @return MAU groups of a given type @t.
    const std::vector<bitvec>& mauGroups(PHV::Type t) const;

    /// @return MAU groups of all types
    const std::map<PHV::Type, std::vector<bitvec>>& mauGroups() const;

    /// @return the ids of every container in @container_id's MAU group, or
    /// boost::none if @container_id is not part of any MAU group.
    boost::optional<bitvec> mauGroup(unsigned container_id) const;

    /// @return a pair <#groups, #containers per group> corresponding to the
    /// PHV Type @t
    const std::pair<int, int> mauGroupNumAndSize(const PHV::Type t) const;

    /// @return a bitvec of available tagalong collections.
    const std::vector<bitvec>& tagalongGroups() const;

    /// @return the ids of every container in @container_id's tagalong group, or
    /// boost::none if @container_id is not part of any MAU group.
    boost::optional<bitvec> tagalongGroup(unsigned container_id) const;

    /// @return the ids of containers that can be assigned to a thread
    /// individually.
    virtual const bitvec& individuallyAssignedContainers() const = 0;

    /// @return the ids of all containers which actually exist on the Tofino
    /// hardware - i.e., all non-overflow containers.
    const bitvec& physicalContainers() const;
};


class TofinoPhvSpec : public PhvSpec {
 public:
    TofinoPhvSpec();

    bitvec deparserGroup(unsigned id) const override;

    const bitvec& individuallyAssignedContainers() const override;
};

#if HAVE_JBAY
class JBayPhvSpec : public PhvSpec {
 public:
    JBayPhvSpec();

    bitvec deparserGroup(unsigned id) const override;

    const bitvec& individuallyAssignedContainers() const override;
};
#endif /* HAVE_JBAY */

#endif /* EXTENSIONS_BF_P4C_PHV_PHV_SPEC_H_ */
