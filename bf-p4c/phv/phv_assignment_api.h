#ifndef BF_P4C_PHV_PHV_ASSIGNMENT_API_H_
#define BF_P4C_PHV_PHV_ASSIGNMENT_API_H_

#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/range.h"
#include "bf-p4c/ir/thread_visitor.h"
#include "cluster.h"
#include "cluster_phv_container.h"
#include "phv_fields.h"
//
//***********************************************************************************
//
// PHV Assignment API
// contains results from PHV Assignment/phv_bind PassManager in backend.cpp
// this object extends from PHV::Field  field->phv_assignment_api
//
//***********************************************************************************
//
//
class PHV_Assignment_API {
 private:
    PHV::Field *field_i;                          /// owner field points to this extended object
                                                  //  this object =field_i->phv_assignment_api_i
    ordered_map<std::pair<int, int>, const PHV::Field::alloc_slice *> field_container_map_i;
                                                      /// field ranges to container bits
                                                      /// range does not straddle containers

 public:
    PHV_Assignment_API(PHV::Field *f_p) : field_i(f_p) { }  // NOLINT(runtime/explicit)

    PHV::Field *field()                               { return field_i; }
    ordered_map<std::pair<int, int>, const PHV::Field::alloc_slice *>&
        field_container_map()                             { return field_container_map_i; }
    //
    // APIs
    //
    // fields to containers
    //
    bool
    field_to_containers(
        PHV::Field *,
        std::list<std::tuple<
            const PHV::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>>>&);
    //
};  // class PHV_Assignment_API
//
std::ostream &operator<<(std::ostream &, PHV_Assignment_API &);
//
#endif /* BF_P4C_PHV_PHV_ASSIGNMENT_API_H_ */
