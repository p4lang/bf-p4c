#include "bf-p4c/phv/v2/phv_allocation_v2.h"

#include "bf-p4c/phv/v2/greedy_allocator.h"
#include "lib/error.h"
#include "bf-p4c/phv/v2/trivial_allocator.h"
#include "bf-p4c/phv/smart_fieldslice_packing.h"

namespace PHV {
namespace v2 {

const IR::Node* PhvAllocation::apply_visitor(const IR::Node* root_, const char *) {
    BUG_CHECK(root_->is<IR::BFN::Pipe>(), "IR root is not a BFN::Pipe: %s", root_);
    const auto* root = root_->to<IR::BFN::Pipe>();
    pipe_id_i = root->id;

    // clear allocation result to create an empty concrete allocation.
    PhvKit::clear_slices(phv_i);
    PHV::ConcreteAllocation alloc = ConcreteAllocation(phv_i, kit_i.uses);
    std::list<PHV::SuperCluster*> clusters = kit_i.make_superclusters();
    // remove singleton unreferenced fields
    clusters = PhvKit::remove_unref_clusters(kit_i.uses, clusters);
    clusters = PhvKit::remove_clot_allocated_clusters(kit_i.clot, clusters);
    clusters = PhvKit::remove_singleton_metadata_slicelist(clusters);

    // apply table-layout-friendly packing on super clusters.
    auto trivial_allocator = new PHV::v2::TrivialAllocator(kit_i, phv_i, pipe_id_i);
    const auto alloc_verifier = [&](const PHV::SuperCluster* sc) {
        return trivial_allocator->can_be_allocated(alloc.makeTransaction(), sc);
    };
    clusters = get_packed_cluster_group(clusters, kit_i.tablePackOpt, alloc_verifier, phv_i);

    if (kit_i.settings.trivial_alloc) {
        if (!trivial_allocator->allocate(clusters)) {
            LOG1("Trivial allocation failed.");
        }
    } else {
        GreedyAllocator greedy_allocator(kit_i, phv_i, pipe_id_i);
        if (!greedy_allocator.allocate(clusters)) {
            LOG1("Greedy allocation failed.");
        }
    }
    return root;
}

}  // namespace v2
}  // namespace PHV
