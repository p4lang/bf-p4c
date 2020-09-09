#include "bf-p4c/phv/slicing/phv_slicing_iterator.h"

#include "bf-p4c/phv/slicing/phv_slicing_dfs_iterator.h"

namespace PHV {
namespace Slicing {

ItrContext::ItrContext(const SuperCluster* sc, const PHVContainerSizeLayout& pa,
                       const PackConflictChecker& pack_conflict)
    : pImpl(new DfsItrContext(sc, pa, pack_conflict)) {}

}  // namespace Slicing
}  // namespace PHV
