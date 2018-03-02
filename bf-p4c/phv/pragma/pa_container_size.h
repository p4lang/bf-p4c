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
 * 2. field_slice_req_i: if enforcing a pragma, the fieldslices it must be splitted to,
 *    and the size of container that that fieldslice must be allocated to.
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
    bool preorder(const IR::BFN::Pipe* pipe) override;

    /** Populate field_slice_req_i based on pa_container_sizes_i.
     */
    void end_apply() override;

    boost::optional<PHV::Size>
    convert_to_phv_size(const IR::Constant* ir);

    void update_field_slice_req(const PHV::Field* field,
                                const std::vector<PHV::Size>& sizes);

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

    /** For a result of slicing a supercluster, a list of supercluster, return
     * a set of fields that is sliced in the way that pragma can not be satisfied.
     *
     *  Require: Forall field showed in @p sliced, all FieldSlices of that field
     *  exists in @p sliced.
     */
    std::set<const PHV::Field*>
    unsatisfiable_fields(const std::list<PHV::SuperCluster*>& sliced) const;

    /** Ignore unsatisfiable fields related pragma.
     */
    void ignore_fields(const std::set<const PHV::Field*>& fields);

    /** Add ad-lib constraint.
     *
     *  In phv allocation, use this at the begging.
     */
    void add_constraint(const PHV::Field* field, std::vector<PHV::Size> sizes);

    /** Adjust field_slice_req_i based on slice list.
     *
     * Since slice list ensures that all fieldslice will be allocated together, so that
     * even if fields are not sliced in the way specified by pragma, however,
     * they will be allocated while satisfying pragmas, for example,
     * slice lists:
        [ abc<16> meta no_split [0:11]
          abc<16> meta no_split [12:12]
          abc<16> meta no_split [13:15] ]
     * rotational clusters:
     *  [[abc<16> meta no_split [0:11]]]
     *  [[abc<16> meta no_split [12:12]]]
     *  [[abc<16> meta no_split [13:15]]]
     * and @pa_container_size("ingress", "abc", 16) is actually Okay.
     */
    void adjust_requirements(const std::list<PHV::SuperCluster*>& sliced);
};

std::ostream& operator<<(std::ostream& out, const PragmaContainerSize& pa_cs);

#endif /* EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_CONTAINER_SIZE_H_ */
