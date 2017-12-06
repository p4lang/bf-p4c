#include "bf-p4c/phv/phv_spec.h"

#include <sstream>
#include "bf-p4c/bf-p4c-options.h"
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
    if (physical_containers_i) return physical_containers_i.value();
    bitvec containers;
    for (auto tg : mauGroups())
        for (auto g : tg.second)
            containers |= g;
    for (auto g : tagalongGroups())
        containers |= g;
    physical_containers_i = std::move(containers);
    return physical_containers_i.value();
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
    if (mau_groups_i) return mau_groups_i.value();
    std::map<PHV::Type, std::vector<bitvec>> mau_groups;
    for (auto gs : mauGroupSpec) {
        PHV::Type groupType = gs.first;
        unsigned numGroups = gs.second.first;
        unsigned groupSize = gs.second.second;
        for (unsigned index = 0; index < numGroups; index++)
            mau_groups[groupType].push_back(range(groupType, index * groupSize, groupSize)); }
    mau_groups_i = std::move(mau_groups);
    return mau_groups_i.value();
}

bitvec PhvSpec::ingressOrEgressOnlyContainers(
    const std::map<PHV::Type, std::vector<unsigned>>& gressOnlyMauGroupIds) const {
    bitvec containers;
    for (auto gg : gressOnlyMauGroupIds) {
        PHV::Type type = gg.first;
        auto group_ids = gg.second;
        unsigned group_size = mauGroupSpec.at(type).second;
        for (auto group_id : group_ids) {
            containers |= range(type, group_id * group_size, group_size);
        }
    }
    return containers;
}

const bitvec& PhvSpec::ingressOnly() const {
    if (ingress_only_containers_i) return ingress_only_containers_i.value();
    ingress_only_containers_i = ingressOrEgressOnlyContainers(ingressOnlyMauGroupIds);
    return ingress_only_containers_i.value();
}

const bitvec& PhvSpec::egressOnly() const {
    if (egress_only_containers_i) return egress_only_containers_i.value();
    egress_only_containers_i = ingressOrEgressOnlyContainers(egressOnlyMauGroupIds);
    return egress_only_containers_i.value();
}

const std::vector<bitvec>& PhvSpec::tagalongGroups() const {
    if (tagalong_collections_i) return tagalong_collections_i.value();
    std::vector<bitvec> tagalong_collections;

    for (unsigned coll_num = 0; coll_num < numTagalongCollections; ++coll_num) {
        bitvec collection;
        for (auto cs : tagalongCollectionSpec) {
            PHV::Type coll_type = cs.first;
            unsigned coll_size = cs.second;
            collection |= range(coll_type,
                                coll_num * coll_size,
                                coll_size); }
        tagalong_collections.push_back(collection); }

    tagalong_collections_i = std::move(tagalong_collections);
    return tagalong_collections_i.value();
}

boost::optional<bitvec> PhvSpec::tagalongGroup(unsigned container_id) const {
    const auto containerType = idToContainerType(container_id % numContainerTypes());
    if (containerType.kind() != PHV::Kind::tagalong)
        return boost::none;

    const unsigned index = container_id / numContainerTypes();
    unsigned collection_num = index / tagalongCollectionSpec.at(containerType);

    if (tagalongGroups().size() <= collection_num)
        return boost::none;

    return tagalongGroups()[collection_num];
}

const std::vector<bitvec>& PhvSpec::mauGroups(PHV::Type t) const {
    auto it = mauGroups().find(t);
    if (it != mauGroups().end())
        return mauGroups().at(t);

    static std::vector<bitvec> dummy;
    return dummy;  // FIXME
}

const std::pair<int, int> PhvSpec::mauGroupNumAndSize(const PHV::Type t) const {
    std::pair<int, int> emptyPair;
    if (!mauGroupSpec.count(t)) return emptyPair;
    return mauGroupSpec.at(t);
}

TofinoPhvSpec::TofinoPhvSpec() {
    addType(PHV::Type::B);
    addType(PHV::Type::H);
    addType(PHV::Type::W);
    addType(PHV::Type::TB);
    addType(PHV::Type::TH);
    addType(PHV::Type::TW);

    auto& options = BFNContext::get().options();
    if (options.virtual_phvs == false) {
        mauGroupSpec = {
            { PHV::Type::B, std::make_pair(4, 16) },
            { PHV::Type::H, std::make_pair(6, 16) },
            { PHV::Type::W, std::make_pair(4, 16) }
        };

        ingressOnlyMauGroupIds = {
            { PHV::Type::B, { 0 } },
            { PHV::Type::H, { 0 } },
            { PHV::Type::W, { 0 } }
        };

        egressOnlyMauGroupIds = {
            { PHV::Type::B, { 1 } },
            { PHV::Type::H, { 1 } },
            { PHV::Type::W, { 1 } }
        };

        tagalongCollectionSpec = {
            { PHV::Type::TB, 4 },
            { PHV::Type::TW, 4 },
            { PHV::Type::TH, 6 }
        };

        numTagalongCollections = 8;
    } else {  // virtual tofino with 2x phv resources :)
        mauGroupSpec = {
            { PHV::Type::B, std::make_pair(8, 16) },
            { PHV::Type::H, std::make_pair(12, 16) },
            { PHV::Type::W, std::make_pair(8, 16) }
        };

        ingressOnlyMauGroupIds = {
            { PHV::Type::B, { 0, 4 } },
            { PHV::Type::H, { 0, 4 } },
            { PHV::Type::W, { 0, 4 } }
        };

        egressOnlyMauGroupIds = {
            { PHV::Type::B, { 1, 5 } },
            { PHV::Type::H, { 1, 5 } },
            { PHV::Type::W, { 1, 5 } }
        };

        tagalongCollectionSpec = {
            { PHV::Type::TB, 8 },
            { PHV::Type::TW, 8 },
            { PHV::Type::TH, 12 }
        };

        numTagalongCollections = 16;
    }
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

const bitvec& TofinoPhvSpec::individuallyAssignedContainers() const {
    if (individually_assigned_containers_i) return individually_assigned_containers_i.value();
    bitvec containers = range(PHV::Type::B, 56, 8)
                      | range(PHV::Type::H, 88, 8)
                      | range(PHV::Type::W, 60, 4);
    individually_assigned_containers_i = std::move(containers);
    return individually_assigned_containers_i.value();
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

    ingressOnlyMauGroupIds = { };

    egressOnlyMauGroupIds  = { };

    tagalongCollectionSpec = { };

    numTagalongCollections = 0;
}

bitvec JBayPhvSpec::deparserGroup(unsigned id) const {
    // JBay does not have deparser group constraints.
    bitvec rv;
    rv.setbit(id);
    return rv;
}

const bitvec& JBayPhvSpec::individuallyAssignedContainers() const {
    if (individually_assigned_containers_i) return individually_assigned_containers_i.value();
    individually_assigned_containers_i.emplace();
    return individually_assigned_containers_i.value();
}

#endif /* HAVE_JBAY */
