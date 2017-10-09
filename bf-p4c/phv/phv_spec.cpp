#include "bf-p4c/phv/phv_spec.h"

#include <sstream>
#include "lib/bitvec.h"
#include "lib/cstring.h"
#include "lib/exceptions.h"

void
PhvSpec::addType(PHV::Type t) {
    const size_t typeId = definedTypes.size();
    definedTypes.push_back(t);
    typeIdMap[t] = typeId;
}

const std::vector<PHV::Type>& PhvSpec::containerTypes() const {
    return definedTypes;
}

unsigned PhvSpec::numContainerTypes() const {
    return definedTypes.size();
}

PHV::Type PhvSpec::idToContainerType(unsigned id) const {
    BUG_CHECK(id < definedTypes.size(),
              "Container type id %1% is out of range");
    return definedTypes[id];
}

unsigned PhvSpec::containerTypeToId(PHV::Type type) const {
    return typeIdMap.at(type);
}

PHV::Container PhvSpec::idToContainer(unsigned id) const {
    // Ids are assigned to containers in ascending order by index, with the
    // different container types interleaved. For example, on Tofino the
    // sequence is as follows:
    //   B0, H0, W0, TB0, TH0, TW0, B1, H1, W1, ...
    const auto typeId = id % numContainerTypes();
    const auto index = id / numContainerTypes();
    return PHV::Container(idToContainerType(typeId), index);
}

unsigned PhvSpec::containerToId(PHV::Container container) const {
    // See idToContainer() for the details of id assignment.
    return container.index() * numContainerTypes() +
           containerTypeToId(container.type());
}

cstring PhvSpec::containerSetToString(const bitvec& set) const {
    bool first = true;
    std::stringstream setAsString;
    for (auto member : set) {
        if (!first) setAsString << ", ";
        first = false;
        setAsString << idToContainer(member);
    }
    return cstring(setAsString);
}

TofinoPhvSpec::TofinoPhvSpec() {
    addType(PHV::Type::B);
    addType(PHV::Type::H);
    addType(PHV::Type::W);
    addType(PHV::Type::TB);
    addType(PHV::Type::TH);
    addType(PHV::Type::TW);
}

bitvec
TofinoPhvSpec::deparserGroup(unsigned id) const {
    const auto containerType = idToContainerType(id % numContainerTypes());
    const unsigned index =  id / numContainerTypes();

    // Individually assigned containers aren't part of a group, by definition.
    if (individuallyAssignedContainers()[id])
        return range(containerType, index, 1);

    // Return a singleton for invalid containers; they have no deparser group.
    if (!physicalContainers()[id])
        return range(containerType, index, 1);

    // We also treat overflow containers (i.e., containers which don't exist in
    // hardware) as being individually assigned.
    if (!physicalContainers()[id])
        return range(containerType, index, 1);

    // Outside of the exceptional cases above, containers are assigned to
    // threads in groups. The grouping depends on the type of container.
    if (containerType == PHV::Type::B || containerType == PHV::Type::H)
        return range(containerType, (index / 8) * 8, 8);
    else if (containerType == PHV::Type::W)
        return range(containerType, (index / 4) * 4, 4);
    else if (containerType.kind() == PHV::Kind::tagalong)
        // Should never need the "or"
        return tagalongGroup(id).get_value_or(range(containerType, index, 1));
    else
        BUG("Unexpected PHV container type %1%", containerType);
}

bitvec
TofinoPhvSpec::range(PHV::Type t, unsigned start, unsigned length) const {
    bitvec containers;
    for (unsigned index = start; index < start + length; ++index)
        containers.setbit(index * numContainerTypes() + containerTypeToId(t));
    return containers;
}

const bitvec& TofinoPhvSpec::ingressOnly() const {
    static const bitvec containers = range(PHV::Type::B, 0, 16)
                                   | range(PHV::Type::H, 0, 16)
                                   | range(PHV::Type::W, 0, 16);
    return containers;
}

const bitvec& TofinoPhvSpec::egressOnly() const {
    static const bitvec containers = range(PHV::Type::B, 16, 16)
                                   | range(PHV::Type::H, 16, 16)
                                   | range(PHV::Type::W, 16, 16);
    return containers;
}

const std::vector<bitvec>& TofinoPhvSpec::mauGroups(PHV::Type t) const {
    static std::map<PHV::Type, std::vector<bitvec>> mau_groups;

    // Initialize once
    if (mau_groups.size() == 0) {
        for (int index = 0; index < 4; ++index) {
            mau_groups[PHV::Type::B].push_back(range(PHV::Type::B, index * 16, 16));
            mau_groups[PHV::Type::W].push_back(range(PHV::Type::W, index * 16, 16)); }
        for (int index = 0; index < 6; ++index)
            mau_groups[PHV::Type::H].push_back(range(PHV::Type::H, index * 16, 16)); }

    return mau_groups[t];
}

boost::optional<bitvec> TofinoPhvSpec::mauGroup(unsigned container_id) const {
    const auto containerType = idToContainerType(container_id % numContainerTypes());
    if (containerType.kind() != PHV::Kind::normal)
        return boost::none;

    const unsigned index = container_id / numContainerTypes();
    const unsigned mau_group_index = index / 16;
    auto group = mauGroups(containerType);
    if (mau_group_index < group.size())
        return group[mau_group_index];
    return boost::none;
}

const std::vector<bitvec>& TofinoPhvSpec::tagalongGroups() const {
    static std::vector<bitvec> tagalong_groups;

    // Initialize once
    if (tagalong_groups.size() == 0) {
        for (auto collection_num = 0; collection_num < 8; ++collection_num) {
            tagalong_groups.push_back(range(PHV::Type::TB, collection_num * 4, 4) |
                                      range(PHV::Type::TW, collection_num * 4, 4) |
                                      range(PHV::Type::TH, collection_num * 6, 6)); } }

    return tagalong_groups;
}

boost::optional<bitvec> TofinoPhvSpec::tagalongGroup(unsigned container_id) const {
    const auto containerType = idToContainerType(container_id % numContainerTypes());
    if (containerType.kind() != PHV::Kind::tagalong)
        return boost::none;

    const unsigned index = container_id / numContainerTypes();
    unsigned collection_num;
    switch (containerType.size()) {
      case PHV::Size::b8:
      case PHV::Size::b32:
        collection_num = index / 4;
        break;
      case PHV::Size::b16:
        collection_num = index / 6;
        break;
      case PHV::Size::null:
        BUG("Invalid container size");  // XXX(cole): Remove 0-sized (invalid) containers.
    }
    if (tagalongGroups().size() <= collection_num)
        return boost::none;

    return tagalongGroups()[collection_num];
}

const bitvec& TofinoPhvSpec::individuallyAssignedContainers() const {
    static const bitvec containers = range(PHV::Type::B, 56, 8)
                                   | range(PHV::Type::H, 88, 8)
                                   | range(PHV::Type::W, 60, 4);
    return containers;
}

const bitvec& TofinoPhvSpec::physicalContainers() const {
    static const bitvec containers = range(PHV::Type::B,  0, 64)
                                   | range(PHV::Type::H,  0, 96)
                                   | range(PHV::Type::W,  0, 64)
                                   | range(PHV::Type::TB, 0, 32)
                                   | range(PHV::Type::TH, 0, 48)
                                   | range(PHV::Type::TW, 0, 32);
    return containers;
}

#if HAVE_JBAY
// XXX(zma) JBayPhvSpec is TofinoPhvSpec minus tagalongs for now,
// will need to add dark and mochas (TODO).
JBayPhvSpec::JBayPhvSpec() {
    addType(PHV::Type::B);
    addType(PHV::Type::H);
    addType(PHV::Type::W);
}

bitvec
JBayPhvSpec::deparserGroup(unsigned id) const {
    // JBay does not have deparser group constraints.
    bitvec rv;
    rv.setbit(id);
    return rv;
}

bitvec
JBayPhvSpec::range(PHV::Type t, unsigned start, unsigned length) const {
    bitvec containers;
    for (unsigned index = start; index < start + length; ++index)
        containers.setbit(index * numContainerTypes() + containerTypeToId(t));
    return containers;
}

const bitvec& JBayPhvSpec::ingressOnly() const {
    static const bitvec containers = range(PHV::Type::B, 0, 16)
                                   | range(PHV::Type::H, 0, 16)
                                   | range(PHV::Type::W, 0, 16);
    return containers;
}

const bitvec& JBayPhvSpec::egressOnly() const {
    static const bitvec containers = range(PHV::Type::B, 16, 16)
                                   | range(PHV::Type::H, 16, 16)
                                   | range(PHV::Type::W, 16, 16);
    return containers;
}

const std::vector<bitvec>& JBayPhvSpec::mauGroups(PHV::Type t) const {
    static std::map<PHV::Type, std::vector<bitvec>> mau_groups;

    // Initialize once
    if (mau_groups.size() == 0) {
        for (int index = 0; index < 4; ++index) {
            mau_groups[PHV::Type::B].push_back(range(PHV::Type::B, index * 16, 16));
            mau_groups[PHV::Type::W].push_back(range(PHV::Type::W, index * 16, 16)); }
        for (int index = 0; index < 6; ++index)
            mau_groups[PHV::Type::H].push_back(range(PHV::Type::H, index * 16, 16)); }

    return mau_groups[t];
}

boost::optional<bitvec> JBayPhvSpec::mauGroup(unsigned container_id) const {
    const auto containerType = idToContainerType(container_id % numContainerTypes());
    if (containerType.kind() != PHV::Kind::normal)
        return boost::none;

    const unsigned index = container_id / numContainerTypes();
    const unsigned mau_group_index = index / 16;
    auto group = mauGroups(containerType);
    if (mau_group_index < group.size())
        return group[mau_group_index];
    return boost::none;
}

const std::vector<bitvec>& JBayPhvSpec::tagalongGroups() const {
    static std::vector<bitvec> tagalong_groups;
    return tagalong_groups;
}

boost::optional<bitvec> JBayPhvSpec::tagalongGroup(unsigned) const {
    return boost::none;
}

const bitvec& JBayPhvSpec::individuallyAssignedContainers() const {
    static const bitvec containers = range(PHV::Type::B, 56, 8)
                                   | range(PHV::Type::H, 88, 8)
                                   | range(PHV::Type::W, 60, 4);
    return containers;
}

const bitvec& JBayPhvSpec::physicalContainers() const {
    static const bitvec containers = range(PHV::Type::B,  0, 64)
                                   | range(PHV::Type::H,  0, 96)
                                   | range(PHV::Type::W,  0, 64);
    return containers;
}
#endif /* HAVE_JBAY */
