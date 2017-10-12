#include "phv_assignment_api.h"
#include "phv_assignment_validate.h"  // make_tuple()
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
PHV_Assignment_API::field_to_containers(
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
            "*****phv_assignment_api.cpp:sanity_WARN*****....."
            << ".....field_to_containers(): field container map reveals unassigned container....."
            << std::endl
            << f);
    }
    for (auto &slice : Values(f_api->field_container_map())) {
        tuple_list.push_back(PHV_Assignment_Validate::make_tuple(slice));
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

std::ostream &operator<<(std::ostream &out, PHV_Assignment_API &phv_assignment_api) {
    out << "Begin+++++++++++++++++++++++++ PHV Assignment API ++++++++++++++++++++++++++++++"
        << std::endl;
    out << phv_assignment_api.field();
    out << "End+++++++++++++++++++++++++ PHV Assignment API ++++++++++++++++++++++++++++++"
        << std::endl;
    return out;
}
