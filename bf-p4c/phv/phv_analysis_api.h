#ifndef BF_P4C_PHV_PHV_ANALYSIS_API_H_
#define BF_P4C_PHV_PHV_ANALYSIS_API_H_

#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/range.h"
#include "bf-p4c/ir/thread_visitor.h"
#include "cluster_phv_container.h"
#include "cluster_phv_mau.h"
//
//***********************************************************************************
//
// PHV Analysis API
// contains results from PHV Analysis PassManager in backend.cpp
// this object extends from PhvInfo::Field  field->phv_analysis_api
//
//***********************************************************************************
//
//
class PHV_Analysis_API {
 private:
    PhvInfo::Field *field_i;                          /// owner field points to this extended object
                                                      //  this object = field_i->phv_analysis_api_i
    ordered_map<std::pair<int, int>, PHV_Container::Container_Content *> field_container_map_i;
                                                      /// field ranges to container bits
                                                      /// range does not straddle containers

 public:
    PHV_Analysis_API(PhvInfo::Field *f_p) : field_i(f_p) { }  // NOLINT(runtime/explicit)
    PhvInfo::Field *field()                                   { return field_i; }
    ordered_map<std::pair<int, int>, PHV_Container::Container_Content *>&
        field_container_map()                                 { return field_container_map_i; }
    //
    //
    // APIs
    //
    // fields to containers
    //
    bool
    field_to_containers(
        PhvInfo::Field *,
        std::list<std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>>&);
    void
    field_to_containers(
        PhvInfo::Field *,
        std::pair<int, int>&,
        std::list<std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>>&);
    //
};  // class PHV_Analysis_API
//
std::ostream &operator<<(std::ostream &, PHV_Analysis_API &);
//
#endif /* BF_P4C_PHV_PHV_ANALYSIS_API_H_ */
