#include "bf-p4c/phv/pragma/pa_container_size.h"
#include <string>
#include <numeric>
#include "bf-p4c/phv/pragma/phv_pragmas.h"
#include "lib/log.h"

boost::optional<PHV::Size>
PragmaContainerSize::convert_to_phv_size(const IR::Constant* ir) {
    int rst = ir->asInt();
    if (rst != 8 && rst != 16 && rst != 32) {
        ::warning("@pragma pa_container_size's third argument "
                  "must be one of {8, 16, 32}, but  %1% is not, skipped", rst);
        return boost::none; }
    return boost::make_optional(static_cast<PHV::Size>(rst));
}

bool PragmaContainerSize::preorder(const IR::BFN::Pipe* pipe) {
    auto check_pragma_string = [] (const IR::StringLiteral* ir) {
        if (!ir) {
            // We only have stringLiteral in IR, no IntLiteral.
            ::warning("%1%", "@pragma pa_container_size's arguments "
                      "must be string literals, skipped");
            return false; }
        return true; };

    auto global_pragmas = pipe->global_pragmas;
    for (const auto* annotation : global_pragmas) {
        if (annotation->name.name != PHV::pragma::CONTAINER_SIZE)
            continue;

        auto& exprs = annotation->expr;
        // check pragma argument
        if (exprs.size() < 3) {
            ::warning("@pragma pa_container_size must "
                      "have at least 3 arguments, only %1% found, skipped", exprs.size());
            continue; }

        auto gress = exprs[0]->to<IR::StringLiteral>();
        auto field_ir = exprs[1]->to<IR::StringLiteral>();

        if (!check_pragma_string(gress) || !check_pragma_string(field_ir))
            continue;

        // check gress correct
        if (!PHV::Pragmas::gressValid("pa_container_size", gress->value))
            continue;

        // check field name
        auto field_name = gress->value + "::" + field_ir->value;
        auto field = phv_i.field(field_name);
        if (!field) {
            ::warning("@pragma pa_container_size's argument "
                      "%1% does not match any phv fields, skipped", field_name);
            continue; }

        // If there is a pa_container_size pragma on the field, then also apply it to its privatized
        // (TPHV) version.
        boost::optional<cstring> tphvName = field->getTPHVPrivateFieldName();
        const PHV::Field* privatized_field = tphvName ?  phv_i.field(*tphvName) : nullptr;
        if (privatized_field)
            LOG1("Privatized field in pragma: " << privatized_field);

        if (pa_container_sizes_i.count(field)) {
            ::warning("@pragma pa_container_size %1% is overriding previous pragmas: ",
                      annotation); }
        pa_container_sizes_i[field] = {};
        if (privatized_field)
            pa_container_sizes_i[privatized_field] = {};

        bool failed = false;
        for (size_t i = 2; i < exprs.size(); ++i) {
            auto container_size_ir = exprs[i]->to<IR::Constant>();
            if (!container_size_ir) {
                ::warning("%1% is not legal integer, skipped", exprs[i]);
                failed = true;
                break; }

            auto container_size = convert_to_phv_size(container_size_ir);
            if (!container_size) {
                failed = true;
                break;
            } else {
                pa_container_sizes_i[field].push_back(*container_size);
                if (privatized_field)
                    pa_container_sizes_i[privatized_field].push_back(*container_size); } }

        if (failed) {
            pa_container_sizes_i.erase(field);
            if (privatized_field)
                pa_container_sizes_i.erase(privatized_field);
            continue; }
    }
    LOG1(*this);
    return true;
}

void PragmaContainerSize::end_apply() {
    for (const auto& kv : pa_container_sizes_i) {
        auto& field = kv.first;
        auto& sizes = kv.second;
        update_field_slice_req(field, sizes); }
}

void PragmaContainerSize::update_field_slice_req(
        const PHV::Field* field,
        const std::vector<PHV::Size>& sizes) {
    int rest_width = field->size;
    int offset = 0;
    if (sizes.size() == 1) {
        PHV::Size sz = sizes.front();
        int sz_int = static_cast<int>(sz);
        while (rest_width > 0) {
            int end = std::min(field->size - 1, offset + sz_int - 1);
            PHV::FieldSlice slice(field, FromTo(offset, end));
            offset = end + 1;
            rest_width -= sz_int;
            field_slice_req_i[slice] = sz;
        }
    } else {
        for (const auto& sz : sizes) {
            int sz_int = static_cast<int>(sz);
            int end = std::min(field->size - 1, offset + sz_int - 1);
            PHV::FieldSlice slice(field, FromTo(offset, end));
            offset = end + 1;
            rest_width -= sz_int;
            field_slice_req_i[slice] = sz;
        }
        if (rest_width > 0) {
            ::warning("%1% has a pa_container_size pragma that "
                      "sum of sizes are less than field size",
                      cstring::to_cstring(field)); }
    }
}

boost::optional<PHV::Size>
PragmaContainerSize::field_slice_req(const PHV::FieldSlice& fs) const {
    if (field_slice_req_i.count(fs)) {
        return field_slice_req_i.at(fs);
    } else {
        return boost::none; }
}

std::set<const PHV::Field*>
PragmaContainerSize::unsatisfiable_fields(
        const std::list<PHV::SuperCluster*>& sliced) {
    std::set<const PHV::Field*> rst;
    std::set<const PHV::Field*> is_in_slicelist;
    // field is not sliced in the way specified.
    LOG3("Calling unsatisfiable_fields on list of superclusters: ");
    for (const auto* sup_cluster : sliced)
        LOG3(sup_cluster);

    for (const auto* sup_cluster : sliced) {
        for (const auto* slice_list : sup_cluster->slice_lists()) {
            bool sliceListCheckRequired = false;
            bool need_exact_container =
                std::any_of(slice_list->begin(), slice_list->end(),
                            [] (const PHV::FieldSlice& fs) {
                                return fs.field()->exact_containers(); });
            // This check only applies to slice list that has exact_container requirement.
            // Pragma enforced requirements on non-exact-container fields are checked later
            // in the satisfies_constraints().
            // The logic is that, we generate a map that mapping a fieldslice to the required sizes.
            // This mapping, i.e. field_slice_req_i is used in the satisfies_constraints().
            // Here, we are trying our best to make this pragma possible by slicing the
            // in the desired way.
            if (!need_exact_container) continue;

            int slice_list_size =
                std::accumulate(slice_list->begin(), slice_list->end(), 0,
                                [] (int a, const PHV::FieldSlice& fs) {
                                    return a + fs.size(); });
            for (const auto& slice : *slice_list) {
                LOG3("  Slice: " << slice);
                // not a specified field
                if (!is_specified(slice.field()))
                    continue;
                // Field slicing for the current slice is not explicitly specified. However, there
                // might be a slice that represents the entire slice list (combination of multiple
                // slices in this slice list belonging to the same field) and has a specified slice
                // list. In that case, if the combined slice list satisfies the pragma requirement,
                // then this slice list does not have any satisfiable fields. Thus, for this case,
                // we need to produce the combined slice from the slice list and check if it
                // satisfied the pragma container_size requirement. Setting sliceListCheckRequired
                // to true indicates to the rest of the method that we need a check for the combined
                // slice.
                //
                // For example, consider @pragma pa_container_size ingress ipv6.srcAddr 32, which
                // specifies that the 128-bit ingress::ipv6.srcAddr field should only be allocated
                // to 32-bit containers. Due to this pragma and the fact that ingress::ipv6.srcAddr
                // is deparsed and has exact_containers requirement, the adjust_requirements()
                // method adds ipv6.srcAddr[127:96], ipv6.srcAddr[95:64], ipv6.srcAddr[63:32], and
                // ipv6.srcAddr[0:31] to the field_slice_req_i map (each of these slices as keys has
                // corresponding value 32).
                //
                // However, because of a table that uses the upper 16 bits of ipv6.srcAddr for
                // match, the actual slices found in the slice list are ipv6.srcAddr[127:112] and
                // ipv6.srcAddr[111:96]. These slices are obviously not found in the
                // field_slice_req_i map and so, the pragma requirements are considered
                // unsatisfiable. Therefore, the slicing iterator is then incremented and the
                // adjust_requirements() and satisfiability checks are performed again.
                //
                // As ipv6.srcAddr[111:96] and ipv6.srcAddr[127:112] are part of the same slice
                // list, they will always be allocated to the same container. Therefore, we must
                // check if the field_slice_req_i contains an entry for the combined slice that can
                // represent the entire slice list (ipv6.srcAddr[127:96]).
                if (!field_slice_req_i.count(slice)) {
                    rst.insert(slice.field());
                    sliceListCheckRequired = true;
                    LOG3("    " << slice << " requires slice list check");
                    continue; }
                // not possible because of the form of slice list.
                if (int(field_slice_req_i.at(slice)) != slice_list_size)
                    rst.insert(slice.field());
            }

            // If sliceListCheckRequired is false, we must try to produce a combined slice
            // representing the slice list and check it for the pragma container_size requirements.
            if (!sliceListCheckRequired) continue;

            // Combined range of a FieldSlice that might span multiple slices of the same field in
            // the same slice list. E.g. range for ipv6.srcAddr[112:127] and ipv6.srcAddr[96:111]
            // will be [96:127].
            le_bitrange range;
            // Need special handling for the first slice in the slice list.
            boost::optional<PHV::FieldSlice> prevSlice = boost::none;
            // In case the combined slice satisfies the pragma requirements, we need to remove the
            // corresponding fields from the unsatisfiable set (rst).
            std::set<const PHV::Field*> toBeRemovedFields;
            // In case the combined slice satisfies the pragma requirements, we need to add a new
            // requirement to the `field_slice_req_i` map corresponding to the combined slice.
            std::set<PHV::FieldSlice> toBeAddedReq;
            // Error condition for checking the combined slice.
            bool errorCombinedSliceCheck = false;
            // When a slice list contains slices that are not part of a specified slicing, then the
            // field is considered unsatisfiable at this point. However, if the slices in the slice
            // list put together (combined slice) can satisfy the container_size constraint, then
            // that slicing should be considered valid.
            for (auto& slice : *slice_list) {
                if (prevSlice != boost::none) {
                    // If the fields in the slice list are different, then ignore because we cannot
                    // produce a combined slice representing the entire field list.
                    if (prevSlice->field() != slice.field()) {
                        errorCombinedSliceCheck = true;
                        break; }
                    // The slice list fields are non-contiguous, so we cannot produce the combined
                    // slice.
                    if (prevSlice->range().hi + 1 != slice.range().lo) {
                        errorCombinedSliceCheck = true;
                        break; }
                    // Combine the ranges of the slices seen so far from this slice list.
                    range |= slice.range();
                } else {
                    // First slice encountered; so range is the range of the first seen slice.
                    range = slice.range(); }
                prevSlice = slice;
                // Provisionally add the slices to the toBeRemovedFields
                toBeRemovedFields.insert(slice.field());
                toBeAddedReq.insert(slice); }
            if (errorCombinedSliceCheck || !prevSlice)
                continue;
            PHV::FieldSlice combinedSlice(prevSlice->field(), range);
            LOG3("  Combined slice produced: " << combinedSlice);
            // If the combined slice does not have a specified requirement, then ignore the
            // remaining checks.
            if (!field_slice_req_i.count(combinedSlice))
                continue;
            // If the slice list size does not match the requirement for the combined slice, then
            // these fields will stay unsatisfiable.
            if (int(field_slice_req_i.at(combinedSlice)) != slice_list_size)
                continue;
            // At this point, the combined slice is valid and satisfies the container_size
            // requirements. So, we need to remove the corresponding slices from the set of
            // unsatisfiable fields (rst).
            for (const auto* f : toBeRemovedFields)
                if (rst.count(f))
                    rst.erase(f);
            // Finally, add a new field slice requirement corresponding to the individual slices
            // making up the combined slice. This is essential because those individual slices will
            // be checked for container size requirements once again when the rotational clusters
            // are checked.
            for (auto& sl : toBeAddedReq)
                field_slice_req_i[sl] = field_slice_req_i.at(combinedSlice);

            // Additionally, for all fields that share a rotational cluster with the toBeAddedReq
            // slices, we must add field_slice_req_i entries for those fields too.
            for (auto& sl : toBeAddedReq) {
                LOG3("    Checking added slice: " << sl);
                const auto& rot_cluster = sup_cluster->cluster(sl);
                LOG3("      Rotational cluster: " << rot_cluster);
                for (auto& sl1 : rot_cluster.slices()) {
                    if (sl1 == sl) continue;
                    LOG3("      Adding " << sl1 << " to field_slice_req_i");
                    field_slice_req_i[sl1] = field_slice_req_i.at(combinedSlice);
                }
            }
        }

        LOG4("Printing field_slice_req_i map");
        for (auto kv : field_slice_req_i)
            LOG4("\t" << kv.first << "\t:\t" << kv.second);

        for (const auto* rot_cluster : sup_cluster->clusters()) {
            for (const auto* ali_cluster : rot_cluster->clusters()) {
                for (const auto& slice : ali_cluster->slices()) {
                    if (!is_specified(slice.field())) continue;
                    // not a specified slicing
                    if (!field_slice_req_i.count(slice))
                        rst.insert(slice.field());
                } } }
    }
    LOG3(rst.size() << " unsatisfiable field(s) found.");
    for (auto& sl : rst)
        LOG3("  Unsatisfiable field: " << sl);
    return rst;
}

std::ostream& operator<<(std::ostream& out, const PragmaContainerSize& pa_cs) {
    std::stringstream logs;
    for (const auto& kv : pa_cs.field_to_sizes()) {
        auto& field = kv.first;
        auto& container_sizes = kv.second;
        logs << "Add @pa_container_size that: " << field
             << " must be allocated to " << " [ ";
        for (const auto& sz : container_sizes) {
            logs << sz << " "; }
        logs << " ] " << " container(s)" << std::endl; }

    for (const auto& kv : pa_cs.field_slice_reqs()) {
        auto& fs = kv.first;
        auto& sz = kv.second;
        logs << fs << " must goto " << sz << std::endl; }

    out << logs.str();
    return out;
}

void PragmaContainerSize::add_constraint(
        const PHV::Field* field, std::vector<PHV::Size> sizes) {
    if (pa_container_sizes_i.count(field)) {
        ::warning("@pragma pa_container_size: field %1% is overriding by ad-lib adding: ",
                  cstring::to_cstring(field)); }
    pa_container_sizes_i[field] = sizes;
    update_field_slice_req(field, sizes);
}

void PragmaContainerSize::adjust_requirements(const std::list<PHV::SuperCluster*>& sliced) {
    for (const auto* sup_cluster : sliced) {
        for (const auto* slice_list : sup_cluster->slice_lists()) {
            const PHV::Field* field = slice_list->front().field();
            // if slice_list have different fields, ignored.
            if (std::any_of(slice_list->begin(), slice_list->end(),
                            [&] (const PHV::FieldSlice& fs) {
                                return fs.field() != field; })) {
                continue; }

            if (!is_specified(field)) continue;
            // Field in different slice list is too complicated.
            if (!is_single_parameter(field)) continue;

            int req_size = int(pa_container_sizes_i.at(field).front());
            int slice_list_size =
                std::accumulate(slice_list->begin(), slice_list->end(), 0,
                                [] (int a, const PHV::FieldSlice& fs) {
                                    return a + fs.size(); });

            if (slice_list_size != field->size) continue;
            if (slice_list_size > req_size) continue;

            // This slice list works, so we can add redundent fieldslice requirements.
            for (const auto& fs : *slice_list)
                field_slice_req_i[fs] = static_cast<PHV::Size>(req_size);
        } }
}
