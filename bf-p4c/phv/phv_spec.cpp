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

bitvec
PhvSpec::range(PHV::Type t, unsigned start, unsigned length) const {
    bitvec containers;
    for (unsigned index = start; index < start + length; ++index)
        containers.setbit(index * numContainerTypes() + containerTypeToId(t));
    return containers;
}

const bitvec& PhvSpec::physicalContainers() const {
    static bitvec containers;
    if (containers == bitvec()) {
        for (auto tg : mauGroups())
            for (auto g : tg.second)
                containers |= g;

        for (auto g : tagalongGroups())
            containers |= g;
    }
    return containers;
}

boost::optional<bitvec> PhvSpec::mauGroup(unsigned container_id) const {
    const auto containerType = idToContainerType(container_id % numContainerTypes());
    auto it = mauGroupSpec.find(containerType);
    if (it == mauGroupSpec.end())
        return boost::none;

    const unsigned index = container_id / numContainerTypes();
    unsigned groupSize = it->second.second;
    const unsigned mau_group_index = index / groupSize;
    auto group = mauGroups(containerType);
    if (mau_group_index < group.size())
        return group[mau_group_index];
    return boost::none;
}

const std::map<PHV::Type, std::vector<bitvec>>& PhvSpec::mauGroups() const {
    static std::map<PHV::Type, std::vector<bitvec>> mau_groups;

    // Initialize once
    if (mau_groups.size() == 0) {
        for (auto gs : mauGroupSpec) {
            PHV::Type groupType = gs.first;
            unsigned numGroups = gs.second.first;
            unsigned groupSize = gs.second.second;
            for (unsigned index = 0; index < numGroups; index++)
                mau_groups[groupType].push_back(range(groupType, index * groupSize, groupSize)); } }

    return mau_groups;
}

const std::vector<bitvec>& PhvSpec::mauGroups(PHV::Type t) const {
    auto it = mauGroups().find(t);
    if (it != mauGroups().end())
        return mauGroups().at(t);

    static std::vector<bitvec> dummy;
    return dummy;  // FIXME
}

TofinoPhvSpec::TofinoPhvSpec() {
    addType(PHV::Type::B);
    addType(PHV::Type::H);
    addType(PHV::Type::W);
    addType(PHV::Type::TB);
    addType(PHV::Type::TH);
    addType(PHV::Type::TW);

    mauGroupSpec = {
        { PHV::Type::B, std::make_pair(4, 16) },
        { PHV::Type::H, std::make_pair(6, 16) },
        { PHV::Type::W, std::make_pair(4, 16) }
    };
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

#if HAVE_JBAY
// XXX(zma) JBayPhvSpec is TofinoPhvSpec minus tagalongs for now,
// will need to add dark and mochas (TODO).
JBayPhvSpec::JBayPhvSpec() {
    addType(PHV::Type::B);
    addType(PHV::Type::H);
    addType(PHV::Type::W);

    mauGroupSpec = {
        { PHV::Type::B, std::make_pair(4, 12) },
        { PHV::Type::H, std::make_pair(6, 12) },
        { PHV::Type::W, std::make_pair(4, 12) }
    };
}

bitvec
JBayPhvSpec::deparserGroup(unsigned id) const {
    // JBay does not have deparser group constraints.
    bitvec rv;
    rv.setbit(id);
    return rv;
}

const bitvec& JBayPhvSpec::ingressOnly() const {
    static const bitvec containers;
    return containers;
}

const bitvec& JBayPhvSpec::egressOnly() const {
    static const bitvec containers;
    return containers;
}

const std::vector<bitvec>& JBayPhvSpec::tagalongGroups() const {
    static std::vector<bitvec> tagalong_groups;
    return tagalong_groups;
}

boost::optional<bitvec> JBayPhvSpec::tagalongGroup(unsigned) const {
    return boost::none;
}

const bitvec& JBayPhvSpec::individuallyAssignedContainers() const {
    static const bitvec containers;
    return containers;
}

#endif /* HAVE_JBAY */
