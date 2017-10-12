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
// this object extends from PHV::Field  field->phv_analysis_api
//
//***********************************************************************************
//
//
class PHV_Analysis_API {
 private:
    PHV::Field *field_i;                          /// owner field points to this extended object
                                                  //  this object = field_i->phv_analysis_api_i
    ordered_map<std::pair<int, int>, PHV_Container::Container_Content *> field_container_map_i;
                                                      /// field ranges to container bits
                                                      /// range does not straddle containers

 public:
    PHV_Analysis_API(PHV::Field *f_p) : field_i(f_p) { }  // NOLINT(runtime/explicit)
    PHV::Field *field()                                   { return field_i; }
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
        PHV::Field *,
        std::list<std::tuple<
            PHV::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>>&);
    void
    field_to_containers(
        PHV::Field *,
        std::pair<int, int>&,
        std::list<std::tuple<
            PHV::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>>&);
    //
};  // class PHV_Analysis_API

std::ostream &operator<<(std::ostream &, PHV_Analysis_API &);

class Build_PHV_Analysis_APIs : public Visitor {
 private:
    PhvInfo &phv_i;                                   /// referenced through constructor
    const Phv_Parde_Mau_Use &uses_i;                  /// field used? in mau, parde

    void create_field_container_map();

    const IR::Node *apply_visitor(const IR::Node *node, const char *name) {
        if (name)
            LOG1(name);
        create_field_container_map();
        return node;
    }

 public:
    Build_PHV_Analysis_APIs(
        PhvInfo &phv_p,
        const Phv_Parde_Mau_Use &uses_i)
      : phv_i(phv_p),
        uses_i(uses_i) { }
};

#endif /* BF_P4C_PHV_PHV_ANALYSIS_API_H_ */
