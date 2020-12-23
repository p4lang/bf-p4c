#ifndef EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_CONTAINER_SIZE_H_
#define EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_CONTAINER_SIZE_H_

#include <boost/optional.hpp>
#include <map>
#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils/utils.h"

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
    PhvInfo& phv_i;

    // By default all of the container size pragma defined externally will be processed as high
    // priority when sorting supercluster. Other internally defined container size pragma can
    // select to be prioritize over all the other supercluster or not through the add_constraint()
    // high_pri argument.
    ordered_set<const PHV::Field*> pa_container_sizes_high_pri_i;
    ordered_map<const PHV::Field*, std::vector<PHV::Size>> pa_container_sizes_i;
    ordered_map<PHV::FieldSlice, PHV::Size> field_slice_req_i;
    // Set of all slices that become no-pack because of pa_container_size pragmas.
    std::map<const PHV::Field*, std::set<PHV::FieldSlice>> no_pack_slices_i;

    profile_t init_apply(const IR::Node* root) override {
        profile_t rv = Inspector::init_apply(root);
        pa_container_sizes_i.clear();
        pa_container_sizes_high_pri_i.clear();
        no_pack_slices_i.clear();
        field_slice_req_i.clear();
        return rv;
    }

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

    // Add no-split constraint if the field has only one container size associated with it adn the
    // size of the container is larger than or equal to the size of the field. The pragma also
    // implies that the entire field must be packed into a single specified size container.
    void check_and_add_no_split(
            PHV::Field* field,
            PHV::Field* privatized_field = nullptr) const;

 public:
    explicit PragmaContainerSize(PhvInfo& phv) : phv_i(phv) { }

    /// BFN::Pragma interface
    static const char *name;
    static const char *description;
    static const char *help;

    const ordered_map<const PHV::Field*, std::vector<PHV::Size>>&
    field_to_sizes() const { return pa_container_sizes_i; }

    // field_to_layout return the container layout of the field.
    // e.g.
    // "f1" => [8,8,8,8], @pa_container_size("f1<32>", 8)
    // "f2" => [8, 16], @pa_container_size("f2<16>", 8, 16).
    ordered_map<const PHV::Field*, std::vector<int>>
    field_to_layout() const;

    bool is_specified(const PHV::Field* field) const {
        return pa_container_sizes_i.count(field); }

    bool is_high_priority(const PHV::Field* field) const {
        return pa_container_sizes_high_pri_i.count(field); }

    // Require @field is specified.
    bool is_single_parameter(const PHV::Field* field) const {
        return pa_container_sizes_i.at(field).size() == 1; }

    const ordered_map<PHV::FieldSlice, PHV::Size>& field_slice_reqs() const {
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
    ordered_set<const PHV::Field*>
    unsatisfiable_fields(const std::list<PHV::SuperCluster*>& sliced);

    /**
     *  Add constraint regardless of whether constraint is already specified on the field.
     *  @high_pri argument defines if this constraint should increase the supercluster priority to
     *  one of the highest.
     */
    void add_constraint(const PHV::Field* field, std::vector<PHV::Size> sizes,
                        bool high_pri = true);

    /** Pretty print existing size requirements specified in vector @sizes.
      */
    cstring printSizeConstraints(const std::vector<PHV::Size>& sizes) const;

    /** Check if the @sizes constraints to be added to @field violates already existing constraints
      * for that field. If it does, return false. Otherwise, add the constraint and return true.
      * Otherwise, add the constraint.
      */
    bool check_and_add_constraint(const PHV::Field* field, std::vector<PHV::Size> sizes);

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

    bool has_no_pack_slice(const PHV::Field* field) const {
        return no_pack_slices_i.count(field);
    }

    const std::set<PHV::FieldSlice> get_no_pack_slices(const PHV::Field* field) const {
        static std::set<PHV::FieldSlice> emptySet;
        if (!has_no_pack_slice(field)) return emptySet;
        return no_pack_slices_i.at(field);
    }
};

std::ostream& operator<<(std::ostream& out, const PragmaContainerSize& pa_cs);

#endif /* EXTENSIONS_BF_P4C_PHV_PRAGMA_PA_CONTAINER_SIZE_H_ */
