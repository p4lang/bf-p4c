#include "phv_analysis_api.h"
#include "phv_analysis_validate.h"  // make_tuple()
#include "lib/log.h"
#include "lib/stringref.h"

//
//
//***********************************************************************************
//
// APIs
//
//***********************************************************************************
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
    if (f_api->field_container_map().empty()) {
        LOG1(
            "*****phv_analysis_api.cpp:sanity_WARN*****....."
            << ".....field_to_containers(): field container map reveals unassigned field....."
            << std::endl
            << f);
    }
    for (auto &cc : Values(f_api->field_container_map())) {
        tuple_list.push_back(PHV_Analysis_Validate::make_tuple(cc));
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
    if (f_api->field_container_map().empty()) {
        LOG1(
            "*****phv_analysis_api.cpp:sanity_WARN*****....."
            << ".....field_to_containers(ra): field container map reveals unassigned field....."
            << std::endl
            << f);
    }
    for (auto &e : f_api->field_container_map()) {
        std::pair<int, int> range = e.first;
        if (hi < range.first) {
            break;
        }
        if (lo >= range.first && lo <= range.second) {
            PHV_Container::Container_Content *cc = e.second;
            tuple_list.push_back(PHV_Analysis_Validate::make_tuple(cc));
            lo += cc->width();
        }
    }
}  // field(ranges)_to_containers
//
//
//***********************************************************************************
//
// sanity checks
//
//***********************************************************************************
//
//

//
//
//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//
//

std::ostream &operator<<(std::ostream &out, PHV_Analysis_API &phv_analysis_api) {
    out << "Begin+++++++++++++++++++++++++ PHV Analysis API ++++++++++++++++++++++++++++++"
        << std::endl;
    out << phv_analysis_api.field();
    out << "End+++++++++++++++++++++++++ PHV Analysis API ++++++++++++++++++++++++++++++"
        << std::endl;
    return out;
}
