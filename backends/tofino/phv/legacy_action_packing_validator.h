#ifndef BF_P4C_PHV_LEGACY_ACTION_PACKING_VALIDATOR_H_
#define BF_P4C_PHV_LEGACY_ACTION_PACKING_VALIDATOR_H_

#include <optional>

#include "backends/tofino/phv/action_packing_validator_interface.h"
#include "lib/ordered_set.h"

namespace PHV {
namespace legacy {

/// ActionPackingValidator checks action PHV constraints for packing of fieldslices, by using
/// ActionConstraintSolver. It will try to compute container sizes and corresponding alignments
/// of all slice lists, and then it will build and call the solver to check if it is possible
/// to synthesize actions.
class ActionPackingValidator : public ActionPackingValidatorInterface {
 private:
    const ActionSourceTracker& sources_i;
    const PhvUse& uses_i;

 public:
    explicit ActionPackingValidator(const ActionSourceTracker& sources, const PhvUse& uses)
        : sources_i(sources), uses_i(uses) {}

    /// can_pack checks action phv constraints if fieldslices packed in @p slice_lists will be
    /// allocated without further split. Currently, we only support validation of move-based
    /// instructions.
    Result can_pack(const ordered_set<const SuperCluster::SliceList*>& slice_lists,
                    const ordered_set<const SuperCluster::SliceList*>& can_be_further_split = {},
                    const bool loose_mode = false)
        const override;
};

}  // namespace legacy
}  // namespace PHV

#endif /* BF_P4C_PHV_LEGACY_ACTION_PACKING_VALIDATOR_H_ */
