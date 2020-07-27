#ifndef EXTENSIONS_BF_P4C_PARDE_CLOT_POV_BIT_SET_H_
#define EXTENSIONS_BF_P4C_PARDE_CLOT_POV_BIT_SET_H_

#include "bf-p4c/phv/phv_fields.h"

/// Implements equality correctly.
class PovBitSet : public std::set<const PHV::FieldSlice*, PHV::FieldSlice::Less> {
 public:
    bool operator==(const PovBitSet& other) {
        if (size() != other.size()) return false;

        auto it1 = begin();
        auto it2 = other.begin();
        while (it1 != end()) {
            if (!PHV::FieldSlice::equal(*it1, *it2)) return false;
            ++it1;
            ++it2;
        }

        return true;
    }

    bool operator !=(const PovBitSet& other) {
        return !operator==(other);
    }
};

#endif /* EXTENSIONS_BF_P4C_PARDE_CLOT_POV_BIT_SET_H_ */
