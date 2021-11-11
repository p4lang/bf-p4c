#include "bf-p4c/phv/slicing/phv_slicing_iterator.h"

#include "bf-p4c/phv/slicing/phv_slicing_dfs_iterator.h"

namespace PHV {
namespace Slicing {

ItrContext::ItrContext(const PhvInfo& phv,
                       const SuperCluster* sc,
                       const PHVContainerSizeLayout& pa,
                       const PackingValidator& packing_validator,
                       const PackConflictChecker pack_conflict,
                       const IsReferencedChecker is_referenced)
    : pImpl(new DfsItrContext(phv, sc, pa, packing_validator, pack_conflict, is_referenced)) {}

}  // namespace Slicing
}  // namespace PHV
