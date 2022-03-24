#ifndef BF_P4C_PHV_V2_TRIVIAL_ALLOCATOR_H_
#define BF_P4C_PHV_V2_TRIVIAL_ALLOCATOR_H_

#include "bf-p4c/phv/allocate_phv.h"
#include "bf-p4c/phv/utils/utils.h"
#include "bf-p4c/phv/v2/utils_v2.h"

namespace PHV {
namespace v2 {

/// TrivialAllocator allocates PHV fields to an infinite long PHV. It is in two cases:
/// (1) trivial allocation before table placement.
/// (2) check whether all constraints can be satisfied.
class TrivialAllocator {
 private:
    /// PhvStatus bookkeeper for containers.
    class PhvStatus {
        std::unordered_map<PHV::Size, int> next_container_idx;

     public:
        PhvStatus();
        PHV::Container next_container(PHV::Size) const;
        void inc_next_container(PHV::Size);
    };

    const AllocUtils& utils_i;
    PhvInfo& phv_i;
    const int pipe_id_i;  /// used for logging purposes

    /// @returns a list of container groups that same-size groups are merged into one group.
    ContainerGroupsBySize make_container_groups_merged_by_size() const;


    // gen_alloc_slices_from_tx extract allocation results from tx and generate allocation of
    // fieldslices to *new* phv containers. New phv containers are requested from @p phv_status
    // and phv_status will be updated.
    std::vector<PHV::AllocSlice> gen_alloc_slices_from_tx(const PHV::Transaction& tx,
                                                          PhvStatus& phv_status) const;

    // gen_alloc_slices_from_tx extract allocation results from tx and generate allocation of
    // fieldslices to *new* phv containers. New phv containers are requested from @p phv_status
    // and phv_status will be updated.
    void bind_alloc_slices(const std::vector<PHV::AllocSlice>& slices);

 public:
    TrivialAllocator(const AllocUtils& utils, PhvInfo& phv, int pipe_id);

    /// PartialAllocResult contains the allocation result and updated phv status if we slice
    /// and allocate a super cluster.
    struct PartialAllocResult {
        const AllocError* err = nullptr;
        std::vector<AllocSlice> alloc_slices;
        PhvStatus phv_status;
        bool ok() const { return err == nullptr; };
        PartialAllocResult(const std::vector<AllocSlice>& alloc_slices, PhvStatus phv_status)
            : alloc_slices(alloc_slices), phv_status(phv_status) {}
        explicit PartialAllocResult(const AllocError* err) : err(err) {}
    };

    /// @returns a PartialAllocResult that contains alloc_slices of an updated phv status when
    /// allocation succeeded. If allocation failed, PartialResult of an error that contains
    /// the best effort diagnose result will be returned.
    const PartialAllocResult* slice_and_allocate_sc(const Allocation& empty_alloc,
                                                    const PHV::SuperCluster* sc,
                                                    PhvStatus phv_status,
                                                    const ContainerGroupsBySize& container_groups,
                                                    const int max_slicings = 128,
                                                    std::ostream* history = nullptr) const;

    /// run trivial PHV allocator to allocate all @p clusters and update phv_i.
    bool allocate(const std::list<PHV::SuperCluster*>& clusters);

    /// @returns true if @p sc can be allocated to @p empty_alloc, assuming there are infinite
    /// containers. Use this verify whether there is any unsatisfiable constraint in @p sc.
    bool can_be_allocated(const Allocation& empty_alloc,
                          const PHV::SuperCluster* sc,
                          const int max_slicings = 128) const;
};

}  // namespace v2
}  // namespace PHV

#endif /* BF_P4C_PHV_V2_TRIVIAL_ALLOCATOR_H_ */
