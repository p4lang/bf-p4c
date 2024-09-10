#ifndef BF_P4C_PHV_V2_TYPES_H_
#define BF_P4C_PHV_V2_TYPES_H_

#include <functional>

#include "backends/tofino/phv/utils/utils.h"
#include "backends/tofino/phv/v2/allocator_metrics.h"

namespace PHV {
namespace v2 {

/// a function type that true if phv allocation is possible for the cluster.
using AllocVerifier = std::function<bool(const SuperCluster *, AllocatorMetrics &)>;

/// @returns true if two field slices cannot be packed into one container.
using HasPackConflict = std::function<
    bool(const PHV::FieldSlice &fs1, const PHV::FieldSlice &fs2)>;

/// map field slices to their starting position in a container.
using FieldSliceStart = std::pair<PHV::FieldSlice, int>;
using FieldSliceAllocStartMap = ordered_map<PHV::FieldSlice, int>;
std::ostream& operator<<(std::ostream& out, const FieldSliceAllocStartMap& fs);

/// type of container groups grouped by sizes.
using ContainerGroupsBySize = std::map<PHV::Size, std::vector<ContainerGroup>>;

/// Map container to container status.
using TxContStatus = ordered_map<PHV::Container, Transaction::ContainerStatus>;

}  // namespace v2
}  // namespace PHV

#endif /* BF_P4C_PHV_V2_TYPES_H_ */
