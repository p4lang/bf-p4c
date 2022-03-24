#ifndef BF_P4C_PHV_SMART_FIELDSLICE_PACKING_H_
#define BF_P4C_PHV_SMART_FIELDSLICE_PACKING_H_

#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/phv/make_clusters.h"
#include "bf-p4c/phv/table_phv_constraints.h"

namespace PHV {

/// A allocation verify that returns true if the super cluster can be allocated to @p alloc.
using AllocVerifier = std::function<bool(const PHV::SuperCluster *)>;

/// @returns a list of new super cluster after smart byte packing. Note that this list of super
/// cluster is verified by trivial allocation, so it can always pass the trivial allocation.
/// @cluster_groups is a list of super cluster on which the user wish to run smart byte packing.
/// @alloc_func is a function pointer pointing to a function that can run the speculative super
/// cluster allocation. Note that no allocation commitment will be performed, so @alloc will remain
/// the same. For current algorithm, only fieldslices that do not have alignment and belong to the
/// same field, and whose sum of ranges equals to the whole field size have the possibility to be
/// packed in one slice list.
std::list<PHV::SuperCluster*> get_packed_cluster_group(
    const std::list<PHV::SuperCluster*> &cluster_groups,
    const TableFieldPackOptimization &table_pack_opt,
    const AllocVerifier& can_be_allocated,
    PhvInfo &phv_i);

}  // namespace PHV

#endif  /* BF_P4C_PHV_SMART_FIELDSLICE_PACKING_H_ */
