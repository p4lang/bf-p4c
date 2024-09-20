#ifndef EXTENSIONS_BF_P4C_COMMON_DEBUG_INFO_H_
#define EXTENSIONS_BF_P4C_COMMON_DEBUG_INFO_H_

#include <vector>
#include "lib/cstring.h"

using namespace P4;

namespace BFN {

/// A tracker for debugging information. This is used for informational purposes
/// only; the information can be included in generated assembly or log files,
/// but it has no effect on correctness.
struct DebugInfo {
    /// Merge the contents of another DebugInfo object into this one.
    void mergeWith(const DebugInfo& other) {
        info.insert(info.end(), other.info.begin(), other.info.end());
    }

    std::vector<cstring> info;
};

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_COMMON_DEBUG_INFO_H_ */
