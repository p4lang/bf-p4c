#ifndef BF_P4C_PHV_SLICING_PHV_SLICING_ITERATOR_H_
#define BF_P4C_PHV_SLICING_PHV_SLICING_ITERATOR_H_

#include "bf-p4c/phv/slicing/types.h"
#include "bf-p4c/phv/utils/utils.h"

namespace PHV {
namespace Slicing {

// ItrContext holds the current context for the generated slicing iterator.
// Note that, the SlicingIterator here is making slicing decision on *SliceList*
// intead of SuperClusters. SuperClusters are just products of doing union-find on
// sliced SliceLists with rotational clusters. see README.md for more details.
// The input @p sc is better to be:
// (1) split by pa_solitary already.
// (2) split by deparsed_bottom_bits already.
class ItrContext {
 private:
    IteratorInterface* pImpl;

 public:
    ItrContext(const SuperCluster* sc, const PHVContainerSizeLayout& pa,
               const PackConflictChecker& pack_conflict);

    // iterate will pass valid slicing results to cb. Stop when cb returns false.
    void iterate(const IterateCb& cb) { pImpl->iterate(cb); }

    // invalidate is the feedback mechanism for allocation algorithm to
    // ask iterator to not produce slicing result contains @p sl.
    void invalidate(const SuperCluster::SliceList* sl) { pImpl->invalidate(sl); }
};

}  // namespace Slicing
}  // namespace PHV

#endif /* BF_P4C_PHV_SLICING_PHV_SLICING_ITERATOR_H_ */
