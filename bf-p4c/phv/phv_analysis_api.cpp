#include "phv_analysis_api.h"
#include "lib/log.h"
#include "lib/stringref.h"

//
//***********************************************************************************
//
// PHV_Analysis_API::apply_visitor
//
//***********************************************************************************
//
//
const IR::Node *
PHV_Analysis_API::apply_visitor(const IR::Node *node, const char *name) {
    //
    if (name) {
        LOG1(name);
    }
    for (auto &f : phv_i) {
       //
       // set up extended phv_analysis object for each field
       //
       f.phv_analysis_api(new PHV_Analysis_API(phv_i, phv_mau_i, &f));
    }
    //
    // create map from field ranges to container bit ranges
    //
    create_field_container_map();
    //
    LOG3(*this);
    //
    return node;
}  // apply_visitor

void
PHV_Analysis_API::end_apply() {
    //
    sanity_check_fields("PHV_Analysis_API::end_apply()");
    sanity_check_fields_containers("PHV_Analysis_API::end_apply()");
    sanity_check_container_holes("PHV_Analysis_API::end_apply()");
}

void
PHV_Analysis_API::create_field_container_map() {
    for (auto &f : phv_i) {
        for (auto &c : f.phv_containers()) {
            for (auto &cc : c->fields_in_container()[&f]) {
                int field_bit_lo = cc->field_bit_lo();
                int field_bit_hi = cc->field_bit_lo() + cc->width() - 1;
                assert(f.phv_analysis_api());
                f.phv_analysis_api()
                    ->field_container_map()[std::make_pair(field_bit_lo, field_bit_hi)] = cc;
            }
        }
    }
}

std::tuple<
    PhvInfo::Field *,
    const std::pair<int, int>,
    const PHV_Container *,
    const std::pair<int, int>>
PHV_Analysis_API::make_tuple(PHV_Container::Container_Content *cc) {
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
PHV_Analysis_API::sanity_check_fields(const std::string& msg) {
    //
    const std::string msg_1 = msg + ".....sanity_check_fields()";
    for (auto &f : phv_i) {
        if (!f.phv_analysis_api()) {
            LOG1("*****phv_analysis_api.cpp:sanity_FAIL*****....."
                << "..... PHV_Analysis_API extended object not created for field ..... "
                << f);
        }
    }
}  // sanity_check_fields

void
PHV_Analysis_API::sanity_check_fields_containers(const std::string& msg) {
    //
    const std::string msg_1 = msg + ".....sanity_check_fields_containers()";
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>> tuple_list_f;
    for (auto &f : phv_i) {
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
                    LOG1("*****phv_analysis_api.cpp:sanity_FAIL*****....."
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
            f_api->container_to_fields(
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
            LOG1("*****phv_analysis_api.cpp:sanity_FAIL*****....."
                << "..... sanity_check_fields_containers: fields_to_containers_to_fields ..... "
                << std::endl
                << tuple_list_f
                << std::endl
                << tuple_list_c);
        }
        //
        // sanity check containers in field's phv_containers match those in tuple_list_f
        //
        ordered_set<PHV_Container *> s_check;
        s_check = f.phv_containers();
        s_check -= phv_containers;
        if (s_check.size()) {
            LOG1("*****phv_analysis_api.cpp:sanity_FAIL*****....."
                << "..... sanity_check_fields_containers: field's vec of phv containers ..... "
                << std::endl
                << f
                << std::endl
                << phv_containers);
        }
    }  // for
}  // sanity_check_fields_containers

void
PHV_Analysis_API::sanity_check_container_holes(const std::string& msg) {
    //
    const std::string msg_1 = msg + ".....sanity_check_container_holes()";
    //
    for (auto &e : phv_mau_i.phv_containers()) {
        int phv_num = e.first;
        PHV_Container *c = phv_mau_i.phv_container(phv_num);
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
            LOG1("*****phv_analysis_api.cpp:sanity_FAIL*****....."
                << "..... PHV_Analysis_API container holes inconsistent ..... "
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
PHV_Analysis_API::field_allocated(
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
            "*****phv_analysis_api.cpp:sanity_WARN*****....."
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
PHV_Analysis_API::field_to_containers(
    PhvInfo::Field *f,
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    assert(f);
    PHV_Analysis_API *f_api = f->phv_analysis_api();
    assert(f_api);
    tuple_list.clear();
    bool contiguous = true;
    int next_start = -1;
    std::list<int> phv_nums;
    for (auto &cc : Values(f_api->field_container_map())) {
        tuple_list.push_back(make_tuple(cc));
        const PHV_Container *c = cc->container();
        int phv_num = c->phv_number();
        if ((next_start != -1 && next_start != cc->lo())
            || (phv_nums.size() && phv_nums.back() != phv_num - 1)) {
            //
            contiguous = false;
        }
        next_start = (cc->hi() + 1) % c->width();
        phv_nums.push_back(phv_num);
    }
    return contiguous;
}  // field_to_containers

//
// field ranges to containers
//
void
PHV_Analysis_API::field_to_containers(
    PhvInfo::Field *f,
    std::pair<int, int>& f_range,
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    assert(f);
    PHV_Analysis_API *f_api = f->phv_analysis_api();
    assert(f_api);
    int lo = f_range.first;
    int hi = f_range.second;
    assert(lo >= 0);
    assert(hi >= 0);
    tuple_list.clear();
    for (auto &e : f_api->field_container_map()) {
        std::pair<int, int> range = e.first;
        if (hi < range.first) {
            break;
        }
        if (lo >= range.first && lo <= range.second) {
            PHV_Container::Container_Content *cc = e.second;
            tuple_list.push_back(make_tuple(cc));
            lo += cc->width();
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
static void
sort_container_ranges(
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
PHV_Analysis_API::container_holes(int phv_num) {
    // return true if container has holes
    std::list<std::tuple<
        const PHV_Container *,
        const std::pair<int, int>>> tuple_list;
    container_holes(phv_num, tuple_list);
    return tuple_list.size()? true: false;
}

void
PHV_Analysis_API::container_holes(
    int phv_num,
    std::list<std::tuple<
        const PHV_Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    tuple_list.clear();
    PHV_Container *c = phv_mau_i.phv_container(phv_num);
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
PHV_Analysis_API::container_to_fields(
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
    PHV_Container *c = phv_mau_i.phv_container(phv_num);
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
PHV_Analysis_API::container_to_fields(
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
    PHV_Container *c = phv_mau_i.phv_container(phv_num);
    assert(c);
    for (auto &cc_s : Values(c->fields_in_container())) {
        for (auto &cc : cc_s) {
            std::pair<int, int> range = {cc->lo(), cc->hi()};
            if (hi < range.first) {
                break;
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
PHV_Analysis_API::fields_written(
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
PHV_Analysis_API::fields_written(
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
PHV_Analysis_API::fields_written(
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
    for (auto &e : phv_mau_i.phv_containers()) {
        container_to_fields(e.first, tuple_temp, true /* written fields only */);
        tuple_list.splice(tuple_list.end(), tuple_temp);
    }
}  // all fields written in MAU

//
// all fields written in program
//
void
PHV_Analysis_API::fields_written(
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
PHV_Analysis_API::fields_overlayed(
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
PHV_Analysis_API::fields_overlayed(
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
PHV_Analysis_API::fields_overlayed(
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
    for (auto &e : phv_mau_i.phv_containers()) {
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
PHV_Analysis_API::fields_overlayed(
    PhvInfo::Field *field,
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    assert(field);
    tuple_list.clear();
    //
    // all containers having field
    //
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>> tuple_list_c;
    field_to_containers(
        field,
        tuple_list_c);
    //
    // for all container ranges for this field, find all fields
    //
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
PHV_Analysis_API::fields_sliced(
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
PHV_Analysis_API::fields_sliced(
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
PHV_Analysis_API::fields_sliced(
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
    for (auto &e : phv_mau_i.phv_containers()) {
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
PHV_Analysis_API::fields_sliced(
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
PHV_Analysis_API::fields_sliced(
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
    // sanity check reverse map
    //
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>> tuple_list;
    f->phv_analysis_api()->container_to_fields(
        c->phv_number(),
        tuple_list);
    for (auto &t : tuple_list) {
        PhvInfo::Field *f = std::get<0>(t);
        const std::pair<int, int> field_range = std::get<1>(t);
        const PHV_Container *c = std::get<2>(t);
        const std::pair<int, int> container_range = std::get<3>(t);
        out << "\t\t" << c->phv_number_string()
            << "[" << container_range.first << ".." << container_range.second << "]"
            << "\t-> " << f->id << ":" << f->name
            << "[" << field_range.first << ".." << field_range.second << "]"
            << std::endl;
    }
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
    ordered_map<std::pair<int, int>, PHV_Container::Container_Content *>& field_container_map) {
    //
    for (auto &e : field_container_map) {
        std::pair<int, int> range = e.first;
        PHV_Container::Container_Content *cc = e.second;
        PhvInfo::Field *field = cc->field();
        const PHV_Container *c = cc->container();
        int container_bit_lo = cc->lo();
        int container_bit_hi = cc->hi();
        out << "\t" << field->id << ":" << field->name
            << "[" << range.first << ".." << range.second << "]\t-> "
            << c->phv_number_string() << "[" << container_bit_lo << ".." << container_bit_hi << "]"
            << std::endl;
    }
    //
    return out;
}

std::ostream &operator<<(std::ostream &out, PHV_Analysis_API &phv_analysis_api) {
    out << "Begin+++++++++++++++++++++++++ PHV Analysis API ++++++++++++++++++++++++++++++"
        << std::endl;
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>> tuple_list;
    for (auto &f : phv_analysis_api.phv()) {
        assert(f.phv_analysis_api());
        // out << f.phv_analysis_api()->field_container_map();
        f.phv_analysis_api()->field_to_containers(&f, tuple_list);
        out << tuple_list;
    }
    out << "End+++++++++++++++++++++++++ PHV Analysis API ++++++++++++++++++++++++++++++"
        << std::endl;
    return out;
}
