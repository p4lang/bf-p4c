#include "bf-p4c/device.h"
#include "phv.h"
#include "phv_spec.h"

namespace PHV {

Type::Type(unsigned typeId) {
    Type t = Device::phvSpec().idTypeMap.at(typeId);
    *this = t; }

Type::Type(Type::TypeEnum te) {
    switch (te) {
        case Type::B:  kind_ = Kind::normal;   size_ = Size::b8;  break;
        case Type::H:  kind_ = Kind::normal;   size_ = Size::b16; break;
        case Type::W:  kind_ = Kind::normal;   size_ = Size::b32; break;
        case Type::TB: kind_ = Kind::tagalong; size_ = Size::b8;  break;
        case Type::TH: kind_ = Kind::tagalong; size_ = Size::b16; break;
        case Type::TW: kind_ = Kind::tagalong; size_ = Size::b32; break;
        default: BUG("Unknown PHV type"); }
}

Type::Type(const char* name) {
    const char* n = name;

    switch (*n) {
        case 'T': kind_ = Kind::tagalong; n++; break;
        default:  kind_ = Kind::normal; }

    switch (*n++) {
        case 'B': size_ = Size::b8;  break;
        case 'H': size_ = Size::b16; break;
        case 'W': size_ = Size::b32; break;
        default: BUG("Invalid PHV type '%s'", name); }

    if (*n)
        BUG("Invalid PHV type '%s'", name);
}

unsigned Type::id() const {
    return Device::phvSpec().typeIdMap.at(*this); }

std::ostream& operator<<(std::ostream& out, const PHV::Kind k) {
    switch (k) {
        case PHV::Kind::normal:   return out << "";
        case PHV::Kind::tagalong: return out << "T";
        default:    BUG("Unknown PHV container kind");
    }
}

std::ostream& operator<<(std::ostream& out, const PHV::Size sz) {
    switch (sz) {
        case PHV::Size::b8:  return out << "B";
        case PHV::Size::b16: return out << "H";
        case PHV::Size::b32: return out << "W";
        default:    BUG("Unknown PHV container size");
    }
}

std::ostream& operator<<(std::ostream& out, const PHV::Type& t) {
    return out << t.kind() << t.size();
}

}  // namespace PHV

ordered_map<PHV::Type, unsigned> PhvSpec::typeIdMap;
ordered_map<unsigned, PHV::Type> PhvSpec::idTypeMap;

void
PhvSpec::addType(PHV::Type t) {
    static unsigned typeId = 0;
    typeIdMap[t] = typeId;
    idTypeMap[typeId] = t;
    typeId++;
}

void
TofinoPhvSpec::defineTypes() const {
    addType(PHV::Type::B);
    addType(PHV::Type::H);
    addType(PHV::Type::W);
    addType(PHV::Type::TB);
    addType(PHV::Type::TH);
    addType(PHV::Type::TW);
}

bitvec
TofinoPhvSpec::group(unsigned id) const {
    const auto containerType = PHV::Type(id % Device::phvSpec().numTypes());
    unsigned index =  id / Device::phvSpec().numTypes();

    // Individually assigned containers aren't part of a group, by definition.
    if (Device::phvSpec().individuallyAssignedContainers()[id])
        return range(containerType, index, 1);

    // We also treat overflow containers (i.e., containers which don't exist in
    // hardware) as being individually assigned.
    if (!Device::phvSpec().physicalContainers()[id])
        return range(containerType, index, 1);

    // Outside of the exceptional cases above, containers are assigned to
    // threads in groups. The grouping depends on the type of container.
    if (containerType == PHV::Type::B || containerType == PHV::Type::H)
        return range(containerType, (index / 8) * 8, 8);
    else if (containerType == PHV::Type::W)
        return range(containerType, (index / 4) * 4, 4);
    else if (containerType == PHV::Type::TB || containerType == PHV::Type::TW)
        return Device::phvSpec().tagalongGroup(index / 4);
    else if (containerType == PHV::Type::TH)
        return Device::phvSpec().tagalongGroup(index / 6);
    else
        BUG("Unexpected PHV container type %1%", containerType);
}

bitvec
TofinoPhvSpec::range(PHV::Type t, unsigned start, unsigned length) const {
    bitvec containers;
    for (unsigned index = start; index < start + length; ++index)
        containers.setbit(index * Device::phvSpec().numTypes() + t.id());
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
