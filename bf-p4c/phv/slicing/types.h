#ifndef BF_P4C_PHV_SLICING_TYPES_H_
#define BF_P4C_PHV_SLICING_TYPES_H_

#include <functional>

#include "lib/bitvec.h"
#include "lib/ordered_map.h"

#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/phv/utils/utils.h"

namespace PHV {
namespace Slicing {

// Unfortunately it's non-trivial to use boost::coroutines2 or boost::context in this project
// because libgc(BDWGC) libgc will try to scan the region
// between current stack pointer and the base of what it thinks the current stack
// is, which can falsely be the base of the main stack. So we use callback
// style iterator here. For more information about the limitation of libgc with coroutines, see
// https://github.com/ivmai/bdwgc/pull/277
// https://github.com/ivmai/bdwgc/issues/274
// https://github.com/ivmai/bdwgc/issues/150
// IterateCb returns false to stop iteration.
using IterateCb = std::function<bool(std::list<SuperCluster*>)>;

// PHVContainerSizeLayout maps phv fields to a vector of container sizes.
using PHVContainerSizeLayout = ordered_map<const PHV::Field*, std::vector<int>>;

// PackConflictChecker return true if the fields @f1 and @f2 have a pack conflict.
using PackConflictChecker = std::function<bool(const Field* f1, const Field* f2)>;

// The interface that the iterator must satisfy.
class IteratorInterface {
 public:
    // iterate will pass valid slicing results to cb. Stop when cb returns false.
    virtual void iterate(const IterateCb& cb) = 0;

    // invalidate is the feedback mechanism for allocation algorithm to
    // ask iterator to not produce slicing result contains @p sl.
    virtual void invalidate(const SuperCluster::SliceList* sl) = 0;
};

}  // namespace Slicing
}  // namespace PHV

#endif /* BF_P4C_PHV_SLICING_TYPES_H_ */
