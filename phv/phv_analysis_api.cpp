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
    PhvInfo::Field *f = cc->field();
    const PHV_Container *c = cc->container();
    int field_lo = cc->field_bit_lo();
    int field_hi = field_lo + cc->width() - 1;
    auto field_range = std::make_pair(field_lo, field_hi);
    auto container_range = std::make_pair(cc->lo(), cc->hi());
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
    const std::string msg_1 = msg + "...::sanity_check_fields";
    for (auto &f : phv_i) {
        if (!f.phv_analysis_api()) {
            LOG1("*****phv_analysis_api.cpp:sanity_FAIL*****....."
                << "..... PHV_Analysis_API extended object not created for field ..... "
                << f);
        }
    }
}

//
//
//***********************************************************************************
//
// APIs
//
//***********************************************************************************
//
//

// field to containers
void
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
    for (auto &e : f_api->field_container_map()) {
        PHV_Container::Container_Content *cc = e.second;
        tuple_list.push_back(make_tuple(cc));
    }
}

// field ranges to containers
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
}

// container to fields
void
PHV_Analysis_API::container_to_fields(
    int phv_num,
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    tuple_list.clear();
    PHV_Container *c = phv_mau_i.phv_container(phv_num);
    assert(c);
    for (auto &e : c->fields_in_container()) {
        for (auto &cc : e.second) {
            tuple_list.push_back(make_tuple(cc));
        }
    }
}

// container ranges to fields
void
PHV_Analysis_API::container_to_fields(
    int phv_num,
    std::pair<int, int>& f_range,
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>>& tuple_list) {
    //
    int lo = f_range.first;
    int hi = f_range.second;
    assert(lo >= 0);
    assert(hi >= 0);
    //
    tuple_list.clear();
    PHV_Container *c = phv_mau_i.phv_container(phv_num);
    assert(c);
    for (auto &e : c->fields_in_container()) {
        for (auto &cc : e.second) {
            std::pair<int, int> range = {cc->lo(), cc->hi()};
            if (hi < range.first) {
                break;
            }
            if (lo >= range.first && lo <= range.second) {
                tuple_list.push_back(make_tuple(cc));
            }
        }
    }
}

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
        const_cast<PHV_Container *>(c)->phv_number(),
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
