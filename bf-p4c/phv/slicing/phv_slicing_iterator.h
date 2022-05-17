#ifndef BF_P4C_PHV_SLICING_PHV_SLICING_ITERATOR_H_
#define BF_P4C_PHV_SLICING_PHV_SLICING_ITERATOR_H_

#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/packing_validator_interface.h"
#include "bf-p4c/phv/slicing/types.h"
#include "bf-p4c/phv/utils/utils.h"

namespace PHV {
namespace Slicing {

/// ItrContext holds the current context for the generated slicing iterator.
/// Note that, the SlicingIterator here is making slicing decision on *SliceList*
/// intead of SuperClusters. SuperClusters are just products of doing union-find on
/// sliced SliceLists with rotational clusters. see README.md for more details.
/// The input @p sc is better to be:
/// (1) split by pa_solitary already.
/// (2) split by deparsed_bottom_bits already.
class ItrContext : public IteratorInterface {
 private:
    IteratorInterface* pImpl;

 public:
    ItrContext(const PhvInfo& phv, const SuperCluster* sc, const PHVContainerSizeLayout& pa,
               const PackingValidator& packing_validator,
               const PackConflictChecker pack_conflict,
               const IsReferencedChecker is_referenced);

    /// iterate will pass valid slicing results to cb. Stop when cb returns false.
    void iterate(const IterateCb& cb) override { pImpl->iterate(cb); }

    /// invalidate is the feedback mechanism for allocation algorithm to
    /// ask iterator to not produce slicing result contains @p sl. This function can be called
    /// multiple times, and the implementation decides which one will be respected.
    /// For example, a DFS slicing iterator may choose to respect the list of top-most stack frame,
    /// i.e., the most recent decision made by DFS.
    void invalidate(const SuperCluster::SliceList* sl) override { pImpl->invalidate(sl); }

    /// set iterator configs.
    void set_config(const IteratorConfig& cfg) override {
        pImpl->set_config(cfg);
    };
};

}  // namespace Slicing
}  // namespace PHV

#endif /* BF_P4C_PHV_SLICING_PHV_SLICING_ITERATOR_H_ */
