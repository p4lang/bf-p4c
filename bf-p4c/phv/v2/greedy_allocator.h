#ifndef BF_P4C_PHV_V2_GREEDY_ALLOCATOR_H_
#define BF_P4C_PHV_V2_GREEDY_ALLOCATOR_H_

#include "bf-p4c/phv/v2/phv_kit.h"
#include "bf-p4c/phv/utils/utils.h"
#include "bf-p4c/phv/v2/kind_size_indexed_map.h"
#include "bf-p4c/phv/v2/utils_v2.h"

namespace PHV {
namespace v2 {

class GreedyAllocator {
    const PhvKit& kit_i;
    PhvInfo& phv_i;
    /// current pipe, used for logging.
    const int pipe_id_i;
    /// the total number of slicing that we will try for a super cluster.
    const int max_slicing_tries_i = 64;

 private:
    /// @returns a map from PHV::Size to container groups.
    ContainerGroupsBySize make_container_groups_by_size() const;

    struct PreSliceResult {
        std::list<SuperCluster*> clusters;
        ordered_map<const SuperCluster*, KindSizeIndexedMap> baseline_cont_req;
    };

    /// @returns pre-sliced super clusters, that was sliced with minimum splits.
    /// If there are any clusters that cannot pass the allocation test, they will be
    /// saved into invalid_clusters.
    PreSliceResult pre_slice_all(
            const Allocation& empty_alloc,
            const std::list<SuperCluster*>& clusters,
            ordered_set<const SuperCluster*>& invalid_clusters) const;

    /// RefinedSuperClusterSet classifies clusters to
    /// (1) normal pre-sliced and sorted cluster
    /// (2) deparser_zero optimization-targeting clusters.
    /// (3) strided cluster.
    struct RefinedSuperClusterSet {
        std::list<PHV::SuperCluster*> normal;
        std::list<PHV::SuperCluster*> deparser_zero;
        std::list<PHV::SuperCluster*> strided;
    };

    /// sort normal (not deparser-zero, nor strided) clusters based on our heuristics.
    void sort_normal_clusters(std::list<PHV::SuperCluster*>& clusters) const;

    /// @returns a set of super clusters that has been classified by the way they will be
    /// allocated.
    RefinedSuperClusterSet prepare_refined_set(const std::list<SuperCluster*>& clusters) const;

    /// Try slicing and allocate @p sc.
    AllocResult slice_and_allocate_sc(
            const ScoreContext& ctx,
            const Allocation& alloc,
            const PHV::SuperCluster* sc,
            const ContainerGroupsBySize& container_groups,
            const int max_slicings = 128,
            std::ostream* history = nullptr) const;

 public:
    GreedyAllocator(const PhvKit& kit, PhvInfo& phv, int pipe_id)
        : kit_i(kit), phv_i(phv), pipe_id_i(pipe_id){};

    /// @returns false if allocation failed.
    /// allocate all @p clusters to phv_i. This function will directly print out errors
    /// when allocation failed.
    bool allocate(std::list<SuperCluster*> clusters);
};

}  // namespace v2
}  // namespace PHV

#endif /* BF_P4C_PHV_V2_GREEDY_ALLOCATOR_H_ */
