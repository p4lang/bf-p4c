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
    else if (containerType == PHV::Type::TB || containerType == PHV::Type::TW)
        return tagalongGroup(index / 4);
    else if (containerType == PHV::Type::TH)
        return tagalongGroup(index / 6);
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

bitvec TofinoPhvSpec::tagalongGroup(unsigned groupIndex) const {
    return range(PHV::Type::TB, groupIndex * 4, 4)
         | range(PHV::Type::TW, groupIndex * 4, 4)
         | range(PHV::Type::TH, groupIndex * 6, 6);
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
// XXXX(zma) JBayPhvSpec is copied from Tofino for now, it will all be changed.
JBayPhvSpec::JBayPhvSpec() {
    addType(PHV::Type::B);
    addType(PHV::Type::H);
    addType(PHV::Type::W);
    addType(PHV::Type::TB);
    addType(PHV::Type::TH);
    addType(PHV::Type::TW);
}

bitvec
JBayPhvSpec::deparserGroup(unsigned id) const {
    const auto containerType = idToContainerType(id % numContainerTypes());
    const unsigned index =  id / numContainerTypes();

    // Individually assigned containers aren't part of a group, by definition.
    if (individuallyAssignedContainers()[id])
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
    else if (containerType == PHV::Type::TB || containerType == PHV::Type::TW)
        return tagalongGroup(index / 4);
    else if (containerType == PHV::Type::TH)
        return tagalongGroup(index / 6);
    else
        BUG("Unexpected PHV container type %1%", containerType);
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

bitvec JBayPhvSpec::tagalongGroup(unsigned groupIndex) const {
    return range(PHV::Type::TB, groupIndex * 4, 4)
         | range(PHV::Type::TW, groupIndex * 4, 4)
         | range(PHV::Type::TH, groupIndex * 6, 6);
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
                                   | range(PHV::Type::W,  0, 64)
                                   | range(PHV::Type::TB, 0, 32)
                                   | range(PHV::Type::TH, 0, 48)
                                   | range(PHV::Type::TW, 0, 32);
    return containers;
}
#endif /* HAVE_JBAY */
