#ifndef BF_P4C_PHV_PACKING_VALIDATOR_H_
#define BF_P4C_PHV_PACKING_VALIDATOR_H_

#include <boost/optional.hpp>

#include "bf-p4c/phv/action_source_tracker.h"
#include "bf-p4c/phv/utils/utils.h"
#include "lib/cstring.h"
#include "lib/ordered_set.h"

namespace PHV {

/// PackingValidator is an interface type of classes that have a can_pack function to verify
/// whether the packing will violate any constraint.
class PackingValidator {
 public:
    struct Result {
        enum class Code { OK, BAD, UNKNOWN };
        Code code = Code::UNKNOWN;
        cstring err = "";
        Result() = default;
        explicit Result(Code code, cstring err = "") : code(code), err(err) {}
    };

    /// can_pack returns Result with code::OK if @p slice_lists can be allocated to containers
    /// without being further split, and allocation will not violate action PHV constraints.
    /// If @p can_be_split_further is not empty, this function will further check that
    /// when @p slice_lists are allocated to containers without further split, can
    /// @p can_be_split_further be split and allocated successfully, by checking
    /// whether slices in the same byte (must be packed in one container) will violate any
    /// action phv constraint.
    /// contract: both @p slice_lists and @p can_be_split_further must contain fine-sliced
    /// PHV::Fieldslices, that any operation will only read or write one PHV::FieldSlice.
    /// All Slicelists in a super cluster satisfy this constraint.
    /// contract: no overlapping slice between @p slice_lists and @p can_be_further_split.
    virtual Result can_pack(
        const ordered_set<const SuperCluster::SliceList*>& slice_lists,
        const ordered_set<const SuperCluster::SliceList*>& can_be_further_split = {}) const = 0;
};

/// ActionPackingValidator checks action PHV constraints for packing of fieldslices, by using
/// ActionConstraintSolver. It will try to compute container sizes and corresponding alignments
/// of all slice lists, and then it will build and call the solver to check if it is possible
/// to synthesize actions.
class ActionPackingValidator : public PackingValidator {
 private:
    const ActionSourceTracker& sources_i;

 public:
    explicit ActionPackingValidator(const ActionSourceTracker& sources) : sources_i(sources) {}

    /// can_pack checks action phv constraints if fieldslices packed in @p slice_lists will be
    /// allocated without further split. Currently, we only support validation of move-based
    /// instructions.
    Result can_pack(const ordered_set<const SuperCluster::SliceList*>& slice_lists,
                    const ordered_set<const SuperCluster::SliceList*>& can_be_further_split = {})
        const override;
};

}  // namespace PHV

#endif /* BF_P4C_PHV_PACKING_VALIDATOR_H_ */
