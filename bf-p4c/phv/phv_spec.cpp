#include "phv.h"
#include "phv_spec.h"

bitvec
TofinoPhvSpec::range(PHV::Kind kind, unsigned start, unsigned length) const {
    bitvec containers;
    for (unsigned index = start; index < start + length; ++index)
        containers.setbit(index * 6 + unsigned(kind));
    return containers;
}

const bitvec& TofinoPhvSpec::ingressOnly() const {
    static const bitvec containers = range(PHV::Kind::B, 0, 16)
                                   | range(PHV::Kind::H, 0, 16)
                                   | range(PHV::Kind::W, 0, 16);
    return containers;
}

const bitvec& TofinoPhvSpec::egressOnly() const {
    static const bitvec containers = range(PHV::Kind::B, 16, 16)
                                   | range(PHV::Kind::H, 16, 16)
                                   | range(PHV::Kind::W, 16, 16);
    return containers;
}

bitvec TofinoPhvSpec::tagalongGroup(unsigned groupIndex) const {
    return range(PHV::Kind::TB, groupIndex * 4, 4)
         | range(PHV::Kind::TW, groupIndex * 4, 4)
         | range(PHV::Kind::TH, groupIndex * 6, 6);
}

const bitvec& TofinoPhvSpec::individuallyAssignedContainers() const {
    static const bitvec containers = range(PHV::Kind::B, 56, 8)
                                   | range(PHV::Kind::H, 88, 8)
                                   | range(PHV::Kind::W, 60, 4);
    return containers;
}

const bitvec& TofinoPhvSpec::physicalContainers() const {
    static const bitvec containers = range(PHV::Kind::B, 0, 64)
                                   | range(PHV::Kind::H, 0, 96)
                                   | range(PHV::Kind::W, 0, 64)
                                   | range(PHV::Kind::TB, 0, 32)
                                   | range(PHV::Kind::TH, 0, 48)
                                   | range(PHV::Kind::TW, 0, 32);
    return containers;
}

namespace PHV {

std::ostream& operator<<(std::ostream& out, const PHV::Kind k) {
    PHV::Container c(k, 0);
    return out << (c.tagalong() ? "T" : "") << "BHW?"[c.log2sz()];
}

}  // namespace PHV
