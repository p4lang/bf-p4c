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
        const std::list<PHV::SuperCluster*>& sliced) const {
    std::set<const PHV::Field*> rst;
    std::set<const PHV::Field*> is_in_slicelist;
    // field is not sliced in the way specified.
    for (const auto* sup_cluster : sliced) {
        for (const auto* slice_list : sup_cluster->slice_lists()) {
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
                // not a specified field
                if (!is_specified(slice.field())) continue;
                // not a specified slicing
                if (!field_slice_req_i.count(slice)) {
                    rst.insert(slice.field());
                    continue; }
                // not possible because of the form of slice list.
                if (int(field_slice_req_i.at(slice)) != slice_list_size) {
                    rst.insert(slice.field()); }
            }
        }

        for (const auto* rot_cluster : sup_cluster->clusters()) {
            for (const auto* ali_cluster : rot_cluster->clusters()) {
                for (const auto& slice : ali_cluster->slices()) {
                    if (!is_specified(slice.field())) continue;
                    // not a specified slicing
                    if (!field_slice_req_i.count(slice)) {
                        rst.insert(slice.field()); }
                } } }
    }
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
