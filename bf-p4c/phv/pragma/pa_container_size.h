#ifndef EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_CONTAINER_SIZE_H_
#define EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_CONTAINER_SIZE_H_

#include <boost/optional.hpp>
#include <map>
#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils.h"

/** pa_container_size pragma support.
 *
 * This pass will gathering all pa_container_size prama and generate:
 * 1. pa_container_sizes_i: map specified fields to specified sizes;
 * 2. field_slice_req_i: if enforcing a pragma, the fieldslices it must be splitted to.
 *
 * Use satisfies_pragmas() on a set of sliced super_cluster to check whether this slice
 * satisfies pragmas, when slicing.
 *
 * Use field_slice_req() when allocating a fieldslice to a container.
 */
class PragmaContainerSize : public Inspector {
    const PhvInfo& phv_i;
    std::map<const PHV::Field*, std::vector<PHV::Size>> pa_container_sizes_i;
    std::map<PHV::FieldSlice, PHV::Size> field_slice_req_i;

    /** Get global pragma pa_container_size.
     */
    void postorder(const IR::BFN::Pipe* pipe) override;

    /** Populate field_slice_req_i based on pa_container_sizes_i.
     */
    void end_apply();

    boost::optional<PHV::Size>
    convert_to_phv_size(const IR::Constant* ir);

 public:
    explicit PragmaContainerSize(const PhvInfo& phv) : phv_i(phv) { }

    const std::map<const PHV::Field*, std::vector<PHV::Size>>&
    field_to_sizes() const { return pa_container_sizes_i; }

    bool is_specified(const PHV::Field* field) const {
        return pa_container_sizes_i.count(field); }

    // Require @field is specified.
    bool is_single_parameter(const PHV::Field* field) const {
        return pa_container_sizes_i.at(field).size() == 1; }

    const std::map<PHV::FieldSlice, PHV::Size>& field_slice_reqs() const {
        return field_slice_req_i; }

    /** Returns the requirement for this FieldSlice.
     */
    boost::optional<PHV::Size> field_slice_req(const PHV::FieldSlice& fs) const;

    /** Require: Forall field showed in @p sliced, all FieldSlices of that field
       exists in @p sliced.
     */
    bool satisfies_pragmas(std::list<PHV::SuperCluster*> sliced) const;
};

std::ostream& operator<<(std::ostream& out, const PragmaContainerSize& pa_cs);

#endif /* EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_CONTAINER_SIZE_H_ */
