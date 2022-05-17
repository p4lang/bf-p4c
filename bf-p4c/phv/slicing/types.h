#ifndef BF_P4C_PHV_SLICING_TYPES_H_
#define BF_P4C_PHV_SLICING_TYPES_H_

#include <functional>

#include "lib/bitvec.h"
#include "lib/ordered_map.h"

#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/phv/utils/utils.h"

namespace PHV {
namespace Slicing {

/// Unfortunately it's non-trivial to use boost::coroutines2 or boost::context in this project
/// because libgc(BDWGC) libgc will try to scan the region
/// between current stack pointer and the base of what it thinks the current stack
/// is, which can falsely be the base of the main stack. So we use callback
/// style iterator here. For more information about the limitation of libgc with coroutines, see
/// https://github.com/ivmai/bdwgc/pull/277
/// https://github.com/ivmai/bdwgc/issues/274
/// https://github.com/ivmai/bdwgc/issues/150
/// IterateCb returns false to stop iteration.
using IterateCb = std::function<bool(std::list<SuperCluster*>)>;

/// PHVContainerSizeLayout maps phv fields to a vector of container sizes.
using PHVContainerSizeLayout = ordered_map<const PHV::Field*, std::vector<int>>;

/// PackConflictChecker return true if the fields @f1 and @f2 have a pack conflict.
using PackConflictChecker = std::function<bool(const FieldSlice &fs1, const FieldSlice &fs2)>;

/// IsReferencedChecker return true if the field is referenced.
using IsReferencedChecker = std::function<bool(const Field* f1)>;

struct IteratorConfig {
    /// minimal_packing_mode sets the slicing preference to create minimal
    /// packing of fieldslices. Slicing result that has less packing of fieldslices will be
    /// iterated before others.
    bool minimal_packing_mode = false;
    /// loose_action_packing_check mode allows iterator to return super clusters that, without
    /// further slicing, action might not be synthesizable because:
    /// (1) unwritten bytes in destination container might be corrupted.
    /// But it will still try to make sure that with some more proper splitting, the cluster
    /// can be allocated.
    bool loose_action_packing_check_mode = false;

    /// smartly backtrack to the frame that made the invalid packing decision, by leveraging the
    /// invalid packing info from packing validator.
    bool smart_backtracking_mode = false;

    IteratorConfig(bool minimal_packing_mode, bool loose_action_packing_check_mode,
                   bool smart_backtracking_mode)
        : minimal_packing_mode(minimal_packing_mode),
          loose_action_packing_check_mode(loose_action_packing_check_mode),
          smart_backtracking_mode(smart_backtracking_mode) {}
};

/// The interface that the iterator must satisfy.
class IteratorInterface {
 public:
    /// iterate will pass valid slicing results to cb. Stop when cb returns false.
    virtual void iterate(const IterateCb& cb) = 0;

    /// invalidate is the feedback mechanism for allocation algorithm to
    /// ask iterator to not produce slicing result contains @p sl.
    virtual void invalidate(const SuperCluster::SliceList* sl) = 0;

    /// set iterator configs.
    virtual void set_config(const IteratorConfig& cfg) = 0;
};

}  // namespace Slicing
}  // namespace PHV

#endif /* BF_P4C_PHV_SLICING_TYPES_H_ */
