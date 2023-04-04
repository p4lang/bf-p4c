#include "bf-p4c/phv/v2/kind_size_indexed_map.h"

namespace PHV {
namespace v2 {

int KindSizeIndexedMap::sum(const PHV::Kind& k) const {
    int rv = 0;
    for (const auto& kv : m) {
        if (kv.first.first == k) {
            rv += kv.second;
        }
    }
    return rv;
}

int KindSizeIndexedMap::sum(const PHV::Size& s) const {
    int rv = 0;
    for (const auto& kv : m) {
        if (kv.first.second == s) {
            rv += kv.second;
        }
    }
    return rv;
}

std::optional<int> KindSizeIndexedMap::get(const PHV::Kind& k, const PHV::Size& s) const {
    if (m.count({k, s})) return m.at({k, s});
    return std::nullopt;
}

int KindSizeIndexedMap::get_or(const PHV::Kind& k, const PHV::Size& s, int default_v) const {
    if (auto rv = get(k, s)) return *rv;
    return default_v;
}

}  // namespace v2
}  // namespace PHV
