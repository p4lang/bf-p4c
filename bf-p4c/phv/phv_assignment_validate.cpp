#include "bf-p4c/phv/cluster.h"
#include "bf-p4c/phv/phv_analysis_api.h"
#include "bf-p4c/phv/phv_assignment_api.h"
#include "bf-p4c/phv/phv_assignment_validate.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/log.h"
#include "lib/stringref.h"

//
//***********************************************************************************
//
// PHV_Assignment_Validate::apply_visitor
//
//***********************************************************************************
//
//
const IR::Node *
PHV_Assignment_Validate::apply_visitor(const IR::Node *node, const char *name) {
    //
    if (name) {
        LOG1(name);
    }
    node->apply(*uses_i);  // uses_i recomputed
    //
    // create map from field ranges to container bit ranges
    //
    create_field_container_map();
    //
    return node;
}  // apply_visitor

void
PHV_Assignment_Validate::end_apply() {
    //
    LOG3(*this);
    //
    sanity_check_fields("PHV_Assignment_Validate::end_apply()");
}

void
PHV_Assignment_Validate::create_field_container_map() {
    //
    phv_name_alloc_slices_map_i.clear();
    //
    for (auto &f : phv_i) {
        if (!uses_i->is_referenced(&f)) {  // disregard unreferenced fields
            continue;
        }
        assert(f.phv_assignment_api());
        for (auto &slice : f.alloc_i) {
            int field_bit_lo = slice.field_bit;
            int field_bit_hi = field_bit_lo + slice.width - 1;
            f.phv_assignment_api()
                ->field_container_map()[std::make_pair(field_bit_lo, field_bit_hi)] = &slice;
            //
            phv_name_alloc_slices_map_i[slice.container.toString()].push_back(&slice);
            // need a token pointer from name to PHV::Container* for use in tuples below
            // can be address of any container incarnation in alloc slices, so latest overrides
            phv_name_container_map_i[slice.container.toString()] = &(slice.container);
        }
    }  // for
    // sort alloc slices in name_alloc_slices_map
    for (auto &e : phv_name_alloc_slices_map_i) {
        e.second.sort(
            [](const PHV::Field::alloc_slice *l, const PHV::Field::alloc_slice *r) {
                return l->container_bit < r->container_bit;
            });
    }
}

std::tuple<
    const PHV::Field *,
    const std::pair<int, int>,
    PHV::Container *,
    const std::pair<int, int>>
PHV_Assignment_Validate::make_tuple(const PHV::Field::alloc_slice *slice) {
    //
    assert(slice);
    //
    int field_lo = slice->field_bit;
    int field_hi = field_lo + slice->width - 1;
    //
    const PHV::Field *f = slice->field;
    const std::pair<int, int> field_range = std::make_pair(field_lo, field_hi);
    PHV::Container *c = const_cast<PHV::Container *>(&(slice->container));
    int container_lo = slice->container_bit;
    int container_hi = slice->container_bit + slice->width - 1;
    const std::pair<int, int> container_range = std::make_pair(container_lo, container_hi);
    //
    return std::make_tuple(f, field_range, c, container_range);
}

//
//
//***********************************************************************************
//
// sanity checks
//
//***********************************************************************************
//
//
void
PHV_Assignment_Validate::sanity_check_fields(const std::string& msg) {
    //
    const std::string msg_1 = msg + ".....sanity_check_fields()";
    for (auto &f : phv_i) {
        if (!f.phv_assignment_api()) {
            LOG1("*****phv_assignment_validate.cpp:sanity_FAIL*****....."
                << "..... PHV_Assignment_Validate extended object not created for field ..... "
                << f);
        }
    }
    sanity_check_fields_containers(msg);
    sanity_check_container_holes(msg);
    //
}  // sanity_check_fields

void
PHV_Assignment_Validate::sanity_check_fields_containers(const std::string& msg) {
    //
    const std::string msg_1 = msg + ".....sanity_check_fields_containers()";
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>> tuple_list_f;
    for (auto &f : phv_i) {
        if (!uses_i->is_referenced(&f)) {  // disregard unreferenced fields
            continue;
        }
        field_to_containers(&f, tuple_list_f);
        //
        // sanity check exact containers & container no holes
        //
        if (f.exact_containers()) {
            for (auto &tuple : tuple_list_f) {
                PHV::Container *c = get<2>(tuple);
                if (container_holes(*c)) {
                    LOG1("*****phv_assignment_validate.cpp:sanity_FAIL*****....."
                        << "..... sanity_check_fields_containers: NOT exact_containers ..... "
                        << std::endl
                        << f
                        << *c);
                }
            }
        }
        //
        // sanity check reverse map container to fields
        //
        std::list<std::tuple<
            const PHV::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>>> tuple_list_c;  // sanity reverse check container_to_fields
        ordered_set<const PHV::Container *> phv_containers;  // field's vec of phv_containers
        for (auto &t : tuple_list_f) {
            std::list<std::tuple<
                const PHV::Field *,
                const std::pair<int, int>,
                PHV::Container *,
                const std::pair<int, int>>> tuple_list_temp;
            PHV::Container *c = std::get<2>(t);
            std::pair<int, int> container_range = std::get<3>(t);
            container_to_fields(
                *c,
                container_range,
                tuple_list_temp);
            //
            // discard overlayed fields in container range
            // otherwise tuple_list_c will have more entries and will not match tuple_list_f
            // they will be checked separately during their turn in this field loop
            //
            tuple_list_temp.remove_if(
                [&f](std::tuple<
                      const PHV::Field *,
                      const std::pair<int, int>,
                      PHV::Container *,
                      const std::pair<int, int>> t) {
                    //
                    return std::get<0>(t) != &f;
                });
            tuple_list_c.splice(tuple_list_c.end(), tuple_list_temp);
            phv_containers.insert(c);
        }  // for
        if (tuple_list_f != tuple_list_c) {
            LOG1("*****phv_assignment_validate.cpp:sanity_FAIL*****....."
                << "..... sanity_check_fields_containers: fields_to_containers_to_fields ..... "
                << std::endl
                << "tuple_list_f = "
                << std::endl
                << tuple_list_f
                << "tuple_list_c = "
                << std::endl
                << tuple_list_c);
        }
        // sanity check containers in field's phv_containers match those in tuple_list_f
        //
        ordered_set<const PHV::Container *> s_check;
        for (auto &slice : f.alloc_i) {
            s_check.insert(&(slice.container));
        }
        s_check -= phv_containers;
        if (s_check.size()) {
            LOG1("*****phv_assignment_validate.cpp:sanity_FAIL*****....."
                << "..... sanity_check_fields_containers: field's vec of phv containers ..... "
                << std::endl
                << f
                << std::endl
                << phv_containers);
        }
        // sanity check field slices
        // not duplicated in containers
        // don't overlap
        // completely allocated
        // sorted map of field slices to containers
        //
        std::map<const std::pair<int, int>, const PHV::Container *> field_slices_to_container;
        for (auto &t : tuple_list_c) {
            auto field_range = std::get<1>(t);
            auto container = std::get<2>(t);
            if (field_slices_to_container.count(field_range)) {
                LOG1("*****phv_assignment_validate.cpp:sanity_FAIL*****....."
                    << "..... sanity_check_fields_containers: field slice duplicate container ....."
                    << std::endl
                    << f
                    << '{' << field_range.first << ".." << field_range.second << '}'
                    << " containers are "
                    << std::endl
                    << *(field_slices_to_container[field_range])
                    << ", "
                    << *(container));
            }
            field_slices_to_container[field_range] = container;
        }
        auto field_size = f.size;
        auto prev_lo = -1;
        auto prev_hi = -1;
        for (auto &e : field_slices_to_container) {
            auto field_range = e.first;
            auto lo = field_range.first;
            auto hi = field_range.second;
            if (lo < prev_hi) {  // overlap with previous slice
                LOG1("*****phv_assignment_validate.cpp:sanity_FAIL*****....."
                    << "..... sanity_check_fields_containers: field_slices_overlap ..... "
                    << std::endl
                    << f
                    << '{' << lo << ".." << hi << '}'
                    << " overlaps "
                    << '{' << prev_lo << ".." << prev_hi << '}');
            }
            field_size -= (hi - lo + 1);
            prev_lo = lo;
            prev_hi = hi;
        }
        if (field_size && uses_i->is_referenced(&f)) {  // disregard unreferenced fields)
            LOG1("*****phv_assignment_validate.cpp:sanity_FAIL*****....."
                << "..... sanity_check_fields_containers: field_incomplete_allocation ..... "
                << std::endl
                << f
                << "<" << f.size << ">"
                << " remainder "
                << field_size);
        }
    }  // for
}  // sanity_check_fields_containers

void
PHV_Assignment_Validate::sanity_check_container_holes(const std::string& msg) {
    //
    const std::string msg_1 = msg + ".....sanity_check_container_holes()";
    //
    for (auto &e : phv_name_alloc_slices_map_i) {
        PHV::Container *c = phv_name_container_map(e.first);
        //
        std::list<std::tuple<
            PHV::Container *,
            const std::pair<int, int>>> holes_list_1;
        container_holes(*c, holes_list_1);
        //
        std::list<std::tuple<
            const PHV::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>>> tuple_list;
        container_to_fields(*c, tuple_list);
        //
        std::list<std::tuple<
            PHV::Container *,
            const std::pair<int, int>>> holes_list_2;
        int container_width = c->size();
        if (tuple_list.size()) {
            std::vector<char> bits(container_width, '0');
            for (auto &tuple : tuple_list) {
                std::pair<int, int> container_range = get<3>(tuple);
                int lo = container_range.first;
                int hi = container_range.second;
                for (auto i = lo; i <= hi; i++) {
                    bits[i] = '1';
                }  // for
            }  // for
            std::list<std::pair<int, int>> holes_list;
            PHV_Container::holes(bits, '0', holes_list);
            //
            for (auto &pair : holes_list) {
                holes_list_2.push_back(std::make_pair(c, pair));
            }
        } else {
            // no fields in container => empty
            holes_list_2.push_back(std::make_pair(c, std::make_pair(0, container_width - 1)));
        }
        //
        if (holes_list_1 != holes_list_2) {
            LOG1("*****phv_assignment_validate.cpp:sanity_FAIL*****....."
                << "..... PHV_Assignment_Validate container holes inconsistent ..... "
                << std::endl
                << holes_list_1
                << " -- "
                << holes_list_2);
        }
    }  // for
}  // sanity_check_container_holes
//
//
//***********************************************************************************
//
// APIs
//
//***********************************************************************************
//
//
//***********************************************************************************
//
// Field allocated ?
// Allocated contiguously ?
//
//***********************************************************************************
//
//
bool
PHV_Assignment_Validate::field_allocated(
    PHV::Field *f,
    bool contiguously) {
    //
    assert(f);
    PHV_Assignment_API *f_api = f->phv_assignment_api();
    assert(f_api);
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>> tuple_list;
    bool contiguous = f_api->field_to_containers(f, tuple_list);
    int allocated_width = 0;
    for (auto &tuple : tuple_list) {
        const std::pair<int, int> field_range = std::get<1>(tuple);
        allocated_width += field_range.second - field_range.first + 1;
    }
    if (allocated_width > f->size) {
        LOG1(
            "*****phv_assignment_validate.cpp:sanity_WARN*****....."
            << ".....field_allocated(): container allocation width exceeds field size....."
            << std::endl
            << tuple_list);
    }
    bool allocated = allocated_width >= f->size? true: false;
    return allocated && (contiguously? contiguous: true);
}  // field allocated
//
//
//***********************************************************************************
//
// Fields to Containers
//
//***********************************************************************************
//
//
// field to containers
//
bool
PHV_Assignment_Validate::field_to_containers(
    PHV::Field *f,
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    assert(f);
    PHV_Assignment_API *f_api = f->phv_assignment_api();
    assert(f_api);
    tuple_list.clear();
    bool contiguous = true;
    int next_start = -1;
    std::list<const PHV::Container *> phv_containers;
    if (f_api->field_container_map().empty()) {
        LOG1(
            "*****phv_assignment_validate.cpp:sanity_WARN*****....."
            << ".....field_to_containers(): field container map reveals unassigned container....."
            << std::endl
            << f);
    }
    for (auto &slice : Values(f_api->field_container_map())) {
        tuple_list.push_back(make_tuple(slice));
        const PHV::Container *c = &(slice->container);
        if ((next_start != -1 && next_start != slice->container_bit)
            || (phv_containers.size() && phv_containers.back()->index() != c->index() - 1)) {
            //
            contiguous = false;
        }
        next_start = (slice->container_bit + slice->width) % c->size();
        phv_containers.push_back(c);
    }
    return contiguous;
}  // field_to_containers

//
// field ranges to containers
//
void
PHV_Assignment_Validate::field_to_containers(
    PHV::Field *f,
    std::pair<int, int>& f_range,
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    assert(f);
    PHV_Assignment_API *f_api = f->phv_assignment_api();
    assert(f_api);
    int lo = f_range.first;
    int hi = f_range.second;
    assert(lo >= 0);
    assert(hi >= 0);
    tuple_list.clear();
    if (f_api->field_container_map().empty()) {
        LOG1(
            "*****phv_assignment_validate.cpp:sanity_WARN*****....."
            << ".....field_to_containers(ra): field container map reveals unassigned container....."
            << std::endl
            << f);
    }
    for (auto &e : f_api->field_container_map()) {
        std::pair<int, int> range = e.first;
        if (hi < range.first) {
            break;
        }
        if (lo >= range.first && lo <= range.second) {
            const PHV::Field::alloc_slice *slice = e.second;
            tuple_list.push_back(make_tuple(slice));
            lo += slice->width;
        }
    }
}  // field(ranges)_to_containers

//
//
//***********************************************************************************
//
// Containers to Fields
//
//***********************************************************************************
//
// sort container ranges in tuples
//
void
PHV_Assignment_Validate::sort_container_ranges(
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    // sort ranges in container
    //
    tuple_list.sort([](
        std::tuple<
            const PHV::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>> l,
        std::tuple<
            const PHV::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>> r) {
        //
        const std::pair<int, int> range_l = get<3>(l);
        const std::pair<int, int> range_r = get<3>(r);
        if (range_l.first == range_r.first) {
            return range_l.second < range_r.second;
        }
        return range_l.first < range_r.first;
    });
}

//
// holes in container
//

bool
PHV_Assignment_Validate::container_holes(PHV::Container& phv_num) {
    // return true if container has holes
    std::list<std::tuple<
        PHV::Container *,
        const std::pair<int, int>>> tuple_list;
    container_holes(phv_num, tuple_list);
    return tuple_list.size()? true: false;
}  // container_holes(phv_num)

void
PHV_Assignment_Validate::container_holes(
    PHV::Container& phv_num,
    std::list<std::tuple<
        PHV::Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    tuple_list.clear();
    std::list<std::pair<int, int>> holes_list;
    container_holes(phv_num, holes_list);
    for (auto &pair : holes_list) {
        tuple_list.push_back(std::make_pair(&phv_num, pair));
    }
}  // container_holes(phv_num, tuple_list)

void
PHV_Assignment_Validate::container_holes(
    PHV::Container& phv_num,
    std::list<std::pair<int, int>>& holes_list) {
    //
    // identify holes in container
    //
    holes_list.clear();
    int width = phv_num.size();
    std::vector<char> bits(width, '0');
    for (auto &slice : phv_name_alloc_slices_map_i[phv_num.toString()]) {
        int lo = slice->container_bit;
        int hi = lo + slice->width - 1;
        for (auto i = lo; i <= hi; i++) {
            bits[i] = '1';
        }  // for
    }  // for
    PHV_Container::holes(bits, '0', holes_list);
}  // container_holes(phv_num, holes_list)

//
// container to fields
//
void
PHV_Assignment_Validate::container_to_fields(
    PHV::Container& phv_num,
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>>& tuple_list,
    bool written_fields_only,
    bool overlayed_fields_only,
    bool sliced_fields_only) {
    //
    tuple_list.clear();
    for (auto &cc : phv_name_alloc_slices_map_i[phv_num.toString()]) {
        if (written_fields_only && !cc->field->mau_write()) {
            continue;
        }
        if (overlayed_fields_only && !cc->field->overlay_substratum()) {
            continue;
        }
        if (sliced_fields_only && !cc->field->sliced()) {
            continue;
        }
        tuple_list.push_back(make_tuple(cc));
    }
    sort_container_ranges(tuple_list);
}  // container_to_fields

//
// container ranges to fields
//
void
PHV_Assignment_Validate::container_to_fields(
    PHV::Container& phv_num,
    std::pair<int, int>& f_range,
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>>& tuple_list,
    bool written_fields_only,
    bool overlayed_fields_only,
    bool sliced_fields_only) {
    //
    int lo = f_range.first;
    int hi = f_range.second;
    assert(lo >= 0);
    assert(hi >= 0);
    //
    tuple_list.clear();
    for (auto &cc : phv_name_alloc_slices_map_i[phv_num.toString()]) {
        std::pair<int, int> range = {cc->container_bit, cc->container_bit + cc->width - 1};
        if (hi < range.first) {
            continue;
        }
        if (lo >= range.first && lo <= range.second) {
            if (written_fields_only && !cc->field->mau_write()) {
                continue;
            }
            if (overlayed_fields_only && !cc->field->overlay_substratum()) {
                continue;
            }
            if (sliced_fields_only && !cc->field->sliced()) {
                continue;
            }
            tuple_list.push_back(make_tuple(cc));
        }
    }  // for
    sort_container_ranges(tuple_list);
}  // container(ranges)_to_fields

//
//
//***********************************************************************************
//
// Fields Written
//
//***********************************************************************************
//
// all fields written in container
//
void
PHV_Assignment_Validate::fields_written(
    PHV::Container& phv_num,
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    container_to_fields(phv_num, tuple_list, true /* written fields only */);
}  // fields_written

//
// all fields written in container range
//
void
PHV_Assignment_Validate::fields_written(
    PHV::Container& phv_num,
    std::pair<int, int>& f_range,
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    container_to_fields(phv_num, f_range, tuple_list, true /* written fields only */);
}  // field(range)s_written

//
// all fields written in MAU
//
void
PHV_Assignment_Validate::fields_written(
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    tuple_list.clear();
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>> tuple_temp;
    for (auto &e : phv_name_alloc_slices_map_i) {
        PHV::Container *c = phv_name_container_map(e.first);
        assert(c);
        container_to_fields(*c, tuple_temp, true /* written fields only */);
        tuple_list.splice(tuple_list.end(), tuple_temp);
    }
}  // all fields written in MAU

//
// all fields written in program
//
void
PHV_Assignment_Validate::fields_written(
    std::list<std::pair<
        const PHV::Field *,
        const std::pair<int, int>>>& tuple_list) {
    //
    for (auto &f : phv_i) {
        if (f.mau_write()) {
            if (f.sliced()) {
                for (auto &slice : Values(f.field_slices())) {
                    tuple_list.push_back(std::make_pair(&f, slice));
                }
            } else {
                tuple_list.push_back(
                    std::make_pair(&f, std::make_pair(f.phv_use_lo(), f.phv_use_hi())));
            }
        }
    }
}  // all fields written in program

//
//
//***********************************************************************************
//
// Fields Overlayed
//
//***********************************************************************************
//
// all fields overlayed in container
//
void
PHV_Assignment_Validate::fields_overlayed(
    PHV::Container& phv_num,
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    container_to_fields(
        phv_num,
        tuple_list,
        false /* written fields only */,
        true /* overlayed fields only */);
}  // fields_overlayed

//
// all fields overlayed in container range
//
void
PHV_Assignment_Validate::fields_overlayed(
    PHV::Container& phv_num,
    std::pair<int, int>& f_range,
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    container_to_fields(
        phv_num,
        f_range,
        tuple_list,
        false /* written fields only */,
        true /* overlayed fields only */);
}  // field(range)s_overlayed

//
// all fields overlayed in MAU
//
void
PHV_Assignment_Validate::fields_overlayed(
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    tuple_list.clear();
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>> tuple_temp;
    for (auto &e : phv_name_alloc_slices_map_i) {
        PHV::Container *c = phv_name_container_map(e.first);
        assert(c);
        container_to_fields(
            *c,
            tuple_temp,
            false /* written fields only */,
            true /* overlayed fields only */);
        tuple_list.splice(tuple_list.end(), tuple_temp);
    }
}  // all fields overlayed in MAU

//
// all fields overlaying a field
//
void
PHV_Assignment_Validate::fields_overlayed(
    PHV::Field *field,
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    assert(field);
    tuple_list.clear();
    //
    // all containers having field
    //
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>> tuple_list_c;
    field_to_containers(
        field,
        tuple_list_c);
    //
    // for all container ranges for this field, find all fields
    //
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>> tuple_list_f;
    for (auto &tuple : tuple_list_c) {
        PHV::Container *c = get<2>(tuple);
        std::pair<int, int> c_range = get<3>(tuple);
        container_to_fields(*c, c_range, tuple_list_f);
        tuple_list.splice(tuple_list.end(), tuple_list_f);
    }
}  // fields_overlayed on field

//
//
//***********************************************************************************
//
// Fields Sliced
//
//***********************************************************************************
//
// all sliced fields container resident
//
void
PHV_Assignment_Validate::fields_sliced(
    PHV::Container& phv_num,
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    container_to_fields(
        phv_num,
        tuple_list,
        false /* written fields only */,
        false /* overlayed fields only */,
        true /* sliced fields only */);
}  // fields_sliced

//
// all sliced fields in container range
//
void
PHV_Assignment_Validate::fields_sliced(
    PHV::Container& phv_num,
    std::pair<int, int>& f_range,
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    container_to_fields(
        phv_num,
        f_range,
        tuple_list,
        false /* written fields only */,
        false /* overlayed fields only */,
        true /* sliced fields only */);
}  // field(range)s_sliced

//
// all sliced fields resident in MAU containers
//
void
PHV_Assignment_Validate::fields_sliced(
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    tuple_list.clear();
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>> tuple_temp;
    for (auto &e : phv_name_alloc_slices_map_i) {
        PHV::Container *c = phv_name_container_map(e.first);
        assert(c);
        container_to_fields(
            *c,
            tuple_temp,
            false /* written fields only */,
            false /* overlayed fields only */,
            true /* sliced fields only */);
        tuple_list.splice(tuple_list.end(), tuple_temp);
    }
}  // all sliced fields resident in MAU containers

//
// all sliced fields in program
//
void
PHV_Assignment_Validate::fields_sliced(
    std::list<std::pair<
        const PHV::Field *,
        const std::pair<int, int>>>& tuple_list) {
    //
    tuple_list.clear();
    for (auto &f : phv_i) {
        std::list<std::pair<
            const PHV::Field *,
            const std::pair<int, int>>> tuple_list_f;
        fields_sliced(&f, tuple_list_f);
        if (tuple_list_f.size()) {
            tuple_list.splice(tuple_list.end(), tuple_list_f);
        }
    }
}  // all sliced fields in program

//
// field slices for a field
//
void
PHV_Assignment_Validate::fields_sliced(
    PHV::Field *f,
    std::list<std::pair<
        const PHV::Field *,
        const std::pair<int, int>>>& tuple_list) {
    //
    assert(f);
    tuple_list.clear();
    if (f->sliced()) {
        for (auto &slice : Values(f->field_slices())) {
            tuple_list.push_back(std::make_pair(f, slice));
        }
    }
}  // all slices of field

//
//
//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//
//

std::ostream &operator<<(
    std::ostream &out,
    std::list<std::tuple<
        PHV::Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    if (tuple_list.size()) {
        out << "\t"
            << *(std::get<0>(tuple_list.front()))
            << ":";
        for (auto &tuple : tuple_list) {
            const std::pair<int, int> range = get<1>(tuple);
            out << "(" << range.first << ".." << range.second << ")";
        }
    }
    //
    return out;
}

std::ostream &operator<<(
    std::ostream &out,
    std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>& tuple) {
    //
    // print map from field ranges to container ranges
    //
    const PHV::Field *f = std::get<0>(tuple);
    const std::pair<int, int> field_range = std::get<1>(tuple);
    PHV::Container *c = std::get<2>(tuple);
    const std::pair<int, int> container_range = std::get<3>(tuple);
    out << "\t" << f->id << ":" << f->name
        << "[" << field_range.first << ".." << field_range.second << "]"
        << "\t-> " << *c
        << "[" << container_range.first << ".." << container_range.second << "]"
        << std::endl;
    //
    return out;
}

std::ostream &operator<<(
    std::ostream &out,
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    for (auto &t : tuple_list) {
        out << t;
    }
    //
    return out;
}

std::ostream &operator<<(
    std::ostream &out,
    ordered_map<std::pair<int, int>, const PHV::Field::alloc_slice *>& field_container_map) {
    //
    for (auto &e : field_container_map) {
        std::pair<int, int> range = e.first;
        const PHV::Field::alloc_slice *slice = e.second;
        const PHV::Field *field = slice->field;
        const PHV::Container c = slice->container;
        int container_bit_lo = slice->container_bit;
        int container_bit_hi = container_bit_lo + slice->width - 1;
        out << "\t" << field->id << ":" << field->name
            << "[" << range.first << ".." << range.second << "]\t-> "
            << c
            << "[" << container_bit_lo << ".." << container_bit_hi << "]"
            << std::endl;
    }
    //
    return out;
}

std::ostream &operator<<(
    std::ostream &out,
    std::map<cstring, std::list<const PHV::Field::alloc_slice *>>& name_alloc_slices_map) {
    //
    for (auto &e : name_alloc_slices_map) {
        out << e.first << std::endl;
        for (auto &slice : e.second) {
            int container_bit_lo = slice->container_bit;
            int container_bit_hi = container_bit_lo + slice->width - 1;
            out << "\t[" << container_bit_lo << ".." << container_bit_hi << "]\t-> ";
            int field_bit_lo = slice->field_bit;
            int field_bit_hi = field_bit_lo + slice->width - 1;
            out << "{" << field_bit_lo << ".." << field_bit_hi << "} "
                << slice->field
                << std::endl;
        }
    }
    //
    return out;
}

std::ostream &operator<<(std::ostream &out, PHV_Assignment_Validate &phv_assignment_validate) {
    out << "Begin+++++++++++++++++++++++++ PHV Assignment Validate ++++++++++++++++++++++++++++++"
        << std::endl;
    std::list<std::tuple<
        const PHV::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>> tuple_list;
    out << ".................... PHV Assignment Validate: Fields to Containers ...................."
        << std::endl;
    for (auto &f : phv_assignment_validate.phv()) {
        if (!phv_assignment_validate.uses()->is_referenced(&f)) {  // disregard unreferenced fields
            continue;
        }
        assert(f.phv_assignment_api());
        // out << f.phv_assignment_api()->field_container_map();
        f.phv_assignment_api()->field_to_containers(&f, tuple_list);
        out << tuple_list;
        //
        // sanity print reverse map from container ranges to field ranges
        //
        for (auto &t : tuple_list) {
            PHV::Container *c = std::get<2>(t);
            std::list<std::tuple<
                const PHV::Field *,
                const std::pair<int, int>,
                PHV::Container *,
                const std::pair<int, int>>> tuple_list_c;
            phv_assignment_validate.container_to_fields(*c, tuple_list_c);
            for (auto &t_c : tuple_list_c) {
                const PHV::Field *field = std::get<0>(t_c);
                const std::pair<int, int> field_range = std::get<1>(t_c);
                PHV::Container *container = std::get<2>(t_c);
                const std::pair<int, int> container_range = std::get<3>(t_c);
                out << "\t\t"
                    << *container
                    << "[" << container_range.first << ".." << container_range.second << "]"
                    << "\t-> " << field->id << ":" << field->name
                    << "[" << field_range.first << ".." << field_range.second << "]"
                    << std::endl;
            }
        }
    }
    out << ".................... PHV Assignment Validate: Containers to Fields ...................."
        << std::endl;
    out << phv_assignment_validate.phv_name_alloc_slices_map()
        << std::endl;
    out << "End+++++++++++++++++++++++++ PHV Assignment Validate ++++++++++++++++++++++++++++++"
        << std::endl;
    return out;
}
