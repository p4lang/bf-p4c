#ifndef _TOFINO_PHV_PHV_ANALYSIS_API_H_
#define _TOFINO_PHV_PHV_ANALYSIS_API_H_

#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"
#include "cluster_phv_container.h"
#include "cluster_phv_mau.h"
//
//***********************************************************************************
//
// PHV Analysis API
// contains results from PHV Analysis PassManager in backend.cpp
// treated as extended object to PhvInfo::Field
//
//***********************************************************************************
//
//
class PHV_Analysis_API : public Visitor {
    //
 private:
    //
    PhvInfo &phv_i;                                           // referenced through constructor
    PHV_MAU_Group_Assignments &phv_mau_i;                     // PHV MAU Group Assignments
    PhvInfo::Field *field_i;                                  // owner field
    ordered_map<std::pair<int, int>, PHV_Container::Container_Content *> field_container_map_i;
                                                              // field ranges -> container bits
                                                              // range does not straddle containers
    //
 public:
    PHV_Analysis_API(PhvInfo &phv_p, PHV_MAU_Group_Assignments &phv_mau_p, PhvInfo::Field *f_p)
        : phv_i(phv_p), phv_mau_i(phv_mau_p), field_i(f_p) {}
    //
    PhvInfo& phv()                                            { return phv_i; }
    PHV_MAU_Group_Assignments & phv_mau()                     { return phv_mau_i; }
    PhvInfo::Field *field()                                   { return field_i; }
    ordered_map<std::pair<int, int>, PHV_Container::Container_Content *>&
        field_container_map()                                 { return field_container_map_i; }
    //
    const IR::Node *apply_visitor(const IR::Node *, const char *name = 0) override;
    void end_apply();
    //
    void create_field_container_map();
    std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>
            make_tuple(PHV_Container::Container_Content *cc);
    //
    void sanity_check_fields(const std::string&);
    //
    // APIs
    //
    void
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
    void
    container_to_fields(
        int phv_num,
        std::list<std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>>&);
    void
    container_to_fields(
        int phv_num,
        std::pair<int, int>&,
        std::list<std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>>&);
    //
};  // class PHV_Analysis_API
//
std::ostream &operator<<(
    std::ostream &,
    std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>&);
std::ostream &operator<<(
    std::ostream &,
    std::list<std::tuple<
        PhvInfo::Field *,
        const std::pair<int, int>,
        const PHV_Container *,
        const std::pair<int, int>>>&);
std::ostream &operator<<(
    std::ostream &,
    ordered_map<std::pair<int, int>, PHV_Container::Container_Content *>&);
std::ostream &operator<<(std::ostream &, PHV_Analysis_API &);
//
#endif /* _TOFINO_PHV_PHV_ANALYSIS_API_H_ */
