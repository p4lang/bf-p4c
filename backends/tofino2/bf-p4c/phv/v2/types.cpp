#include "bf-p4c/phv/v2/types.h"

namespace PHV {
namespace v2 {

std::ostream& operator<<(std::ostream& out, const FieldSliceAllocStartMap& fs) {
    std::string sep = "";
    for (const auto& kv : fs) {
        const auto& index = kv.second;
        const auto& fs = kv.first;
        out << sep << index << ":" << fs.field()->name << "[" << fs.range().lo << ":"
            << fs.range().hi << "]";
        sep = ", ";
    }
    return out;
}


}  // namespace v2
}  // namespace PHV
