#ifndef EXTENSIONS_BF_P4C_PHV_PHV_SPEC_H_
#define EXTENSIONS_BF_P4C_PHV_PHV_SPEC_H_

#include <vector>
#include "bf-p4c/phv/phv.h"
#include "lib/ordered_map.h"
#include "lib/bitvec.h"

class cstring;

class PhvSpec {
 protected:
    // All cache fields
    mutable bitvec physical_containers_i;
    mutable std::map<PHV::Type, std::vector<bitvec>> mau_groups_i;
    mutable bitvec ingress_only_containers_i;
    mutable bitvec egress_only_containers_i;
    mutable std::vector<bitvec> tagalong_collections_i;
    mutable bitvec individually_assigned_containers_i;

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

    std::map<PHV::Type, unsigned> deparserGroupSize;

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

    /** The JBay parser treats the PHV as 256 x 16b containers, where each
     * extractor can write to the upper/lower/both 8b segments of each 16b
     * container.  MAU, on the other hand, views PHV as groups of 8b, 16b, and
     * 32b containers.
     *
     * As a result, if an even/odd pair of 8b PHV containers holds extracted
     * fields, then they need to be assigned to the same thread.
     *
     * @return the ids of every container in the same parser group as the
     * provided container.
     */
    virtual bitvec parserGroup(unsigned id) const = 0;

    /// @return the ids of every container in the same deparser group as the
    /// provided container.
    bitvec deparserGroup(unsigned id) const;

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
    bitvec mauGroup(unsigned container_id) const;

    /// @return a pair <#groups, #containers per group> corresponding to the
    /// PHV Type @t
    const std::pair<int, int> mauGroupNumAndSize(const PHV::Type t) const;

    /// @return a bitvec of available tagalong collections.
    const std::vector<bitvec>& tagalongGroups() const;

    /// @return the ids of every container in @container_id's tagalong group, or
    /// boost::none if @container_id is not part of any MAU group.
    bitvec tagalongGroup(unsigned container_id) const;

    /// @return the ids of containers that can be assigned to a thread
    /// individually.
    virtual const bitvec& individuallyAssignedContainers() const = 0;

    /// @return the ids of all containers which actually exist on the Tofino
    /// hardware - i.e., all non-overflow containers.
    const bitvec& physicalContainers() const;

    /// @return the target-specific address of @container_id.
    virtual unsigned physicalAddress(unsigned container_id) const = 0;
};


class TofinoPhvSpec : public PhvSpec {
    /// Physical addresses of PHV containers.
    struct ClosedRange { unsigned min; unsigned max; };
    std::map<PHV::Type, ClosedRange> physicalAddresses = {
        { PHV::Type::W,   { .min = 0,   .max = 63  } },
        { PHV::Type::B,   { .min = 64,  .max = 127 } },
        { PHV::Type::H,   { .min = 128, .max = 255 } },
        { PHV::Type::TW,  { .min = 256, .max = 287 } },
        { PHV::Type::TB,  { .min = 288, .max = 319} },
        { PHV::Type::TH,  { .min = 320, .max = 367 } }, };

 public:
    TofinoPhvSpec();

    /// @see PhvSpec::parserGroup(unsigned id).
    bitvec parserGroup(unsigned id) const override;

    const bitvec& individuallyAssignedContainers() const override;

    /// @see PhvSpec::physicalAddress(unsigned container_id).
    unsigned physicalAddress(unsigned container_id) const override;
};

#if HAVE_JBAY
class JBayPhvSpec : public PhvSpec {
 public:
    JBayPhvSpec();

    /// @see PhvSpec::parserGroup(unsigned id).
    bitvec parserGroup(unsigned id) const override;

    const bitvec& individuallyAssignedContainers() const override;

    /// @see PhvSpec::physicalAddress(unsigned container_id).
    unsigned physicalAddress(unsigned container_id) const override;
};
#endif /* HAVE_JBAY */

#endif /* EXTENSIONS_BF_P4C_PHV_PHV_SPEC_H_ */
