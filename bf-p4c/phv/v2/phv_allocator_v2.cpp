#include "bf-p4c/phv/v2/phv_allocator_v2.h"

#include "lib/error.h"
#include "bf-p4c/phv/v2/trivial_allocator.h"

namespace PHV {
namespace v2 {

const IR::Node* PhvAllocation::apply_visitor(const IR::Node* root_, const char *) {
    BUG_CHECK(root_->is<IR::BFN::Pipe>(), "IR root is not a BFN::Pipe: %s", root_);
    const auto* root = root_->to<IR::BFN::Pipe>();
    pipe_id_i = root->id;

    // clear allocation result to create an empty concrete allocation.
    PHV::AllocUtils::clear_slices(phv_i);
    PHV::ConcreteAllocation alloc = ConcreteAllocation(phv_i, utils_i.uses);
    std::list<PHV::SuperCluster*> clusters = utils_i.make_superclusters();
    // remove singleton unreferenced fields
    clusters = PHV::AllocUtils::remove_unref_clusters(utils_i.uses, clusters);
    clusters = PHV::AllocUtils::remove_clot_allocated_clusters(utils_i.clot, clusters);
    clusters = PHV::AllocUtils::remove_singleton_metadata_slicelist(clusters);

    if (utils_i.settings.trivial_alloc) {
        auto trivial_allocator = new TrivialAllocator(utils_i, phv_i, pipe_id_i);
        bool ok = trivial_allocator->allocate(clusters);
        if (!ok) {
            LOG1("Trivial allocation failed.");
        }
        return root;
    }
    P4C_UNIMPLEMENTED("PHV::v2 non-trivial allocation not implemented");
    return root;
}

}  // namespace v2
}  // namespace PHV
