#ifndef BF_P4C_PHV_V2_KIND_SIZE_INDEXED_MAP_H_
#define BF_P4C_PHV_V2_KIND_SIZE_INDEXED_MAP_H_

#include <map>
#include <optional>

#include "backends/tofino/phv/phv_fields.h"

namespace PHV {
namespace v2 {

struct KindSizeIndexedMap {
    std::map<std::pair<PHV::Kind, PHV::Size>, int> m;
    int& operator[](const std::pair<PHV::Kind, PHV::Size>& ks) { return m[ks]; }
    int sum(const PHV::Kind& k) const;
    int sum(const PHV::Size& k) const;
    std::optional<int> get(const PHV::Kind& k, const PHV::Size& s) const;
    int get_or(const PHV::Kind& k, const PHV::Size& s, int default_val) const;
};
std::ostream& operator<<(std::ostream&, const KindSizeIndexedMap&);

}  // namespace v2
}  // namespace PHV

#endif /* BF_P4C_PHV_V2_KIND_SIZE_INDEXED_MAP_H_ */
