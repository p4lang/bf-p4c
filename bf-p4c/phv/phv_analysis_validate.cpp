#include "phv_analysis_api.h"
#include "phv_analysis_validate.h"
#include "lib/log.h"
#include "lib/stringref.h"

//
//***********************************************************************************
//
// PHV_Analysis_Validate::apply_visitor
//
//***********************************************************************************
//
//
const IR::Node *
PHV_Analysis_Validate::apply_visitor(const IR::Node *node, const char *name) {
    if (name)
        LOG1(name);
    return node;
}

void
PHV_Analysis_Validate::end_apply() {
    LOG3(*this);
    sanity_check_fields("PHV_Analysis_Validate::end_apply()");
}

std::tuple<
    PhvInfo::Field *,
    const std::pair<int, int>,
    const PHV_Container *,
    const std::pair<int, int>>
PHV_Analysis_Validate::make_tuple(PHV_Container::Container_Content *cc) {
    //
    assert(cc);
    //
    int field_lo = cc->field_bit_lo();
    int field_hi = field_lo + cc->width() - 1;
    //
    // sanity check
    //
    int field_slice = field_hi - field_lo + 1;
    int width_in_container = cc->hi() - cc->lo() + 1;
    assert(width_in_container == field_slice);
    //
    PhvInfo::Field *f = cc->field();
    auto field_range = std::make_pair(field_lo, field_hi);
    const PHV_Container *c = cc->container();
    auto container_range = std::make_pair(cc->lo(), cc->hi());
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
PHV_Analysis_Validate::sanity_check_fields(const std::string& msg) {
    const std::string msg_1 = msg + ".....sanity_check_fields()";
    for (auto &f : phv_i) {
        if (!f.phv_analysis_api()) {
            // TODO: This will never fail, because f.phv_analysis_api() is checked
            // for NULL when constructing the field_container_map in the API.
            LOG1("*****phv_analysis_validate.cpp:sanity_FAIL*****....."
                << "..... PHV_Analysis_Validate extended object not created for field ..... "
                << f); } }

    sanity_check_fields_containers(msg);
    sanity_check_container_holes(msg);
}

void
PHV_Analysis_Validate::sanity_check_fields_containers(const std::string& msg) {
    //
    const std::string msg_1 = msg + ".....sanity_check_fields_containers()";
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>> tuple_list_f;
    for (auto &f : phv_i) {
        if (!uses_i.is_referenced(&f)) {  // disregard unreferenced fields
            continue;
        }
        PHV_Analysis_API *f_api = f.phv_analysis_api();
        assert(f_api);
        f_api->field_to_containers(&f, tuple_list_f);
        //
        // sanity check exact containers & container no holes
        //
        if (f.exact_containers()) {
            for (auto &tuple : tuple_list_f) {
                const PHV_Container *c = get<2>(tuple);
                PHV_Container *c1 = const_cast<PHV_Container *>(c);
                int phv_num = c->phv_number();
                if (container_holes(phv_num)) {
                    LOG1("*****phv_analysis_validate.cpp:sanity_FAIL*****....."
                        << "..... sanity_check_fields_containers: NOT exact_containers ..... "
                        << std::endl
                        << f
                        << *c1);
                }
            }
        }
        //
        // sanity check reverse map container to fields
        //
        std::list<std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>> tuple_list_c;  // sanity reverse check container_to_fields
        ordered_set<PHV_Container *> phv_containers;   // sanity match field's vec of phv_containers
        for (auto &t : tuple_list_f) {
            std::list<std::tuple<
                PhvInfo::Field *,
                const std::pair<int, int>,
                const PHV_Container *,
                const std::pair<int, int>>> tuple_list_temp;
            const PHV_Container *c = std::get<2>(t);
            std::pair<int, int> container_range = std::get<3>(t);
            container_to_fields(
                c->phv_number(),
                container_range,
                tuple_list_temp);
            //
            // discard overlayed fields in container range
            // otherwise tuple_list_c will have more entries and will not match tuple_list_f
            // they will be checked separately during their turn in this field loop
            //
            tuple_list_temp.remove_if(
                [&f](std::tuple<
                      PhvInfo::Field *,
                      const std::pair<int, int>,
                      const PHV_Container *,
                      const std::pair<int, int>> t) {
                    //
                    return std::get<0>(t) != &f;
                });
            tuple_list_c.splice(tuple_list_c.end(), tuple_list_temp);
            phv_containers.insert(const_cast<PHV_Container *>(c));
        }  // for
        if (tuple_list_f != tuple_list_c) {
            LOG1("*****phv_analysis_validate.cpp:sanity_FAIL*****....."
                << "..... sanity_check_fields_containers: fields_to_containers_to_fields ..... "
                << std::endl
                << tuple_list_f
                << std::endl
                << tuple_list_c);
        }
        // sanity check containers in field's phv_containers match those in tuple_list_f
        //
        ordered_set<PHV_Container *> s_check;
        s_check = f.phv_containers();
        s_check -= phv_containers;
        if (s_check.size()) {
            LOG1("*****phv_analysis_validate.cpp:sanity_FAIL*****....."
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
        std::map<const std::pair<int, int>, const PHV_Container *> field_slices_to_container;
        for (auto &t : tuple_list_c) {
            auto field_range = std::get<1>(t);
            auto container = std::get<2>(t);
            if (field_slices_to_container.count(field_range)) {
                LOG1("*****phv_analysis_validate.cpp:sanity_FAIL*****....."
                    << "..... sanity_check_fields_containers: field slice duplicate container ....."
                    << std::endl
                    << f
                    << '{' << field_range.first << ".." << field_range.second << '}'
                    << " containers are "
                    << std::endl
                    << field_slices_to_container[field_range]
                    << container);
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
                LOG1("*****phv_analysis_validate.cpp:sanity_FAIL*****....."
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
        if (field_size && uses_i.is_referenced(&f)) {  // disregard unreferenced fields)
            LOG1("*****phv_analysis_validate.cpp:sanity_FAIL*****....."
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
PHV_Analysis_Validate::sanity_check_container_holes(const std::string& msg) {
    //
    const std::string msg_1 = msg + ".....sanity_check_container_holes()";
    //
    assert(phv_mau_i);
    for (auto &e : phv_mau_i->phv_containers()) {
        int phv_num = e.first;
        const PHV_Container *c = phv_mau_i->phv_container(phv_num);
        assert(c);
        //
        std::list<std::tuple<
            const PHV_Container *,
            const std::pair<int, int>>> holes_list_1;
        container_holes(phv_num, holes_list_1);
        //
        std::list<std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>> tuple_list;
        container_to_fields(phv_num, tuple_list);
        //
        std::list<std::tuple<
            const PHV_Container *,
            const std::pair<int, int>>> holes_list_2;
        int container_width = c->width();
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
            c->holes(bits, '0', holes_list);
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
            LOG1("*****phv_analysis_validate.cpp:sanity_FAIL*****....."
                << "..... PHV_Analysis_Validate container holes inconsistent ..... "
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
PHV_Analysis_Validate::field_allocated(
    PhvInfo::Field *f,
    bool contiguously) {
    //
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>> tuple_list;
    bool contiguous = f->phv_analysis_api()->field_to_containers(f, tuple_list);
    int allocated_width = 0;
    for (auto &tuple : tuple_list) {
        const std::pair<int, int> field_range = std::get<1>(tuple);
        allocated_width += field_range.second - field_range.first + 1;
    }
    if (allocated_width > f->size) {
        LOG1(
            "*****phv_analysis_validate.cpp:sanity_WARN*****....."
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
// Containers to Fields
//
//***********************************************************************************
//
// sort container ranges in tuples
//
void
PHV_Analysis_Validate::sort_container_ranges(
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    // sort ranges in container
    //
    tuple_list.sort([](
        std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>> l,
        std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
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
PHV_Analysis_Validate::container_holes(int phv_num) {
    // return true if container has holes
    std::list<std::tuple<
        const PHV_Container *,
        const std::pair<int, int>>> tuple_list;
    container_holes(phv_num, tuple_list);
    return tuple_list.size()? true: false;
}

void
PHV_Analysis_Validate::container_holes(
    int phv_num,
    std::list<std::tuple<
        const PHV_Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    tuple_list.clear();
    assert(phv_mau_i);
    const PHV_Container *c = phv_mau_i->phv_container(phv_num);
    assert(c);
    std::list<std::pair<int, int>> holes_list;
    c->holes(holes_list);
    for (auto &pair : holes_list) {
        tuple_list.push_back(std::make_pair(c, pair));
    }
}  // container_holes

//
// container to fields
//
void
PHV_Analysis_Validate::container_to_fields(
    int phv_num,
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>>& tuple_list,
    bool written_fields_only,
    bool overlayed_fields_only,
    bool sliced_fields_only) {
    //
    tuple_list.clear();
    assert(phv_mau_i);
    const PHV_Container *c = phv_mau_i->phv_container(phv_num);
    assert(c);
    for (auto &cc_s : Values(c->fields_in_container())) {
        for (auto &cc : cc_s) {
            if (written_fields_only && !cc->field()->mau_write()) {
                continue;
            }
            if (overlayed_fields_only && !cc->overlayed()) {
                continue;
            }
            if (sliced_fields_only && !cc->sliced()) {
                continue;
            }
            tuple_list.push_back(make_tuple(cc));
        }
    }
    sort_container_ranges(tuple_list);
}  // container_to_fields

//
// container ranges to fields
//
void
PHV_Analysis_Validate::container_to_fields(
    int phv_num,
    std::pair<int, int>& f_range,
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
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
    assert(phv_mau_i);
    const PHV_Container *c = phv_mau_i->phv_container(phv_num);
    assert(c);
    for (auto &cc_s : Values(c->fields_in_container())) {
        for (auto &cc : cc_s) {
            std::pair<int, int> range = {cc->lo(), cc->hi()};
            if (hi < range.first) {
                continue;
            }
            if (lo >= range.first && lo <= range.second) {
                if (written_fields_only && !cc->field()->mau_write()) {
                    continue;
                }
                if (overlayed_fields_only && !cc->overlayed()) {
                    continue;
                }
                if (sliced_fields_only && !cc->sliced()) {
                    continue;
                }
                tuple_list.push_back(make_tuple(cc));
            }
        }
    }
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
PHV_Analysis_Validate::fields_written(
    int phv_num,
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    container_to_fields(phv_num, tuple_list, true /* written fields only */);
}  // fields_written

//
// all fields written in container range
//
void
PHV_Analysis_Validate::fields_written(
    int phv_num,
    std::pair<int, int>& f_range,
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    container_to_fields(phv_num, f_range, tuple_list, true /* written fields only */);
}  // field(range)s_written

//
// all fields written in MAU
//
void
PHV_Analysis_Validate::fields_written(
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    tuple_list.clear();
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>> tuple_temp;
    assert(phv_mau_i);
    for (auto &e : phv_mau_i->phv_containers()) {
        container_to_fields(e.first, tuple_temp, true /* written fields only */);
        tuple_list.splice(tuple_list.end(), tuple_temp);
    }
}  // all fields written in MAU

//
// all fields written in program
//
void
PHV_Analysis_Validate::fields_written(
    std::list<std::pair<
        PhvInfo::Field *,
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
PHV_Analysis_Validate::fields_overlayed(
    int phv_num,
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
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
PHV_Analysis_Validate::fields_overlayed(
    int phv_num,
    std::pair<int, int>& f_range,
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
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
PHV_Analysis_Validate::fields_overlayed(
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    tuple_list.clear();
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>> tuple_temp;
    assert(phv_mau_i);
    for (auto &e : phv_mau_i->phv_containers()) {
        container_to_fields(
            e.first,
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
PHV_Analysis_Validate::fields_overlayed(
    PhvInfo::Field *field,
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>>& tuple_list) {
    assert(field);
    tuple_list.clear();

    // all containers having field
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>> tuple_list_c;
    field->phv_analysis_api()->field_to_containers(field, tuple_list_c);

    // for all container ranges for this field, find all fields
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>> tuple_list_f;

    for (auto &tuple : tuple_list_c) {
        const PHV_Container *c = get<2>(tuple);
        int phv_num = c->phv_number();
        std::pair<int, int> c_range = get<3>(tuple);
        container_to_fields(phv_num, c_range, tuple_list_f);
        tuple_list.splice(tuple_list.end(), tuple_list_f); }
}

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
PHV_Analysis_Validate::fields_sliced(
    int phv_num,
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
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
PHV_Analysis_Validate::fields_sliced(
    int phv_num,
    std::pair<int, int>& f_range,
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
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
PHV_Analysis_Validate::fields_sliced(
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    tuple_list.clear();
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>> tuple_temp;
    assert(phv_mau_i);
    for (auto &e : phv_mau_i->phv_containers()) {
        container_to_fields(
            e.first,
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
PHV_Analysis_Validate::fields_sliced(
    std::list<std::pair<
        PhvInfo::Field *,
        const std::pair<int, int>>>& tuple_list) {
    //
    tuple_list.clear();
    for (auto &f : phv_i) {
        std::list<std::pair<
            PhvInfo::Field *,
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
PHV_Analysis_Validate::fields_sliced(
    PhvInfo::Field *f,
    std::list<std::pair<
        PhvInfo::Field *,
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
        const PHV_Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    if (tuple_list.size()) {
        out << "\t"
            << std::get<0>(tuple_list.front())
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
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>& tuple) {
    //
    // print map from field ranges to container ranges
    //
    PhvInfo::Field *f = std::get<0>(tuple);
    const std::pair<int, int> field_range = std::get<1>(tuple);
    const PHV_Container *c = std::get<2>(tuple);
    const std::pair<int, int> container_range = std::get<3>(tuple);
    out << "\t" << f->id << ":" << f->name
        << "[" << field_range.first << ".." << field_range.second << "]"
        << "\t-> " << c->phv_number_string()
        << "[" << container_range.first << ".." << container_range.second << "]"
        << std::endl;
    //
    return out;
}

std::ostream &operator<<(
    std::ostream &out,
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
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
    std::map<int, std::list<PHV_Container::Container_Content *>>& phv_name_cc_map) {
    //
    for (auto &e : phv_name_cc_map) {
        out << "PHV-" << e.first << std::endl;
        for (auto &cc : e.second) {
            int container_bit_lo = cc->lo();
            int container_bit_hi = cc->hi();
            out << "\t[" << container_bit_lo << ".." << container_bit_hi << "]";
            out << (container_bit_lo > 9 ? "" : "\t");
            int field_bit_lo = cc->field_bit_lo();
            int field_bit_hi = cc->field_bit_hi();
            out << "-> {" << field_bit_lo << ".." << field_bit_hi << "} "
                << cc->field()
                << std::endl;
        }
    }
    //
    return out;
}

std::ostream &operator<<(std::ostream &out, PHV_Analysis_Validate &phv_analysis_validate) {
    out << "Begin+++++++++++++++++++++++++ PHV Analysis Validate ++++++++++++++++++++++++++++++"
        << std::endl;
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>> tuple_list;
    out << ".................... PHV Analysis Validate: Fields to Containers ......................"
        << std::endl;
    for (auto &f : phv_analysis_validate.phv_i) {
        if (!phv_analysis_validate.uses_i.is_referenced(&f)) {  // disregard unreferenced fields
            continue;
        }
        assert(f.phv_analysis_api());
        // out << f.phv_analysis_api()->field_container_map();
        f.phv_analysis_api()->field_to_containers(&f, tuple_list);
        out << tuple_list;
        //
        // sanity print reverse map from container ranges to field ranges
        //
        for (auto &t : tuple_list) {
            const PHV_Container *c = std::get<2>(t);
            std::list<std::tuple<
                PhvInfo::Field *,
                const std::pair<int, int>,
                const PHV_Container *,
                const std::pair<int, int>>> tuple_list_c;
            phv_analysis_validate.container_to_fields(c->phv_number(), tuple_list_c);
            for (auto &t_c : tuple_list_c) {
                const PhvInfo::Field *field = std::get<0>(t_c);
                const std::pair<int, int> field_range = std::get<1>(t_c);
                const PHV_Container *container = std::get<2>(t_c);
                const std::pair<int, int> container_range = std::get<3>(t_c);
                out << "\t\t"
                    << container->phv_number_string()
                    << "[" << container_range.first << ".." << container_range.second << "]"
                    << "\t-> " << field->id << ":" << field->name
                    << "[" << field_range.first << ".." << field_range.second << "]"
                    << std::endl;
            }
        }
    }
    out << ".................... PHV Analysis Validate: Containers to Fields ......................"
        << std::endl;
    out << "End+++++++++++++++++++++++++ PHV Analysis Validate ++++++++++++++++++++++++++++++"
        << std::endl;
    return out;
}
