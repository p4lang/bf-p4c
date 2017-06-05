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
// TODO: What is an extended object?
//
//***********************************************************************************
//
//
class PHV_Analysis_API : public Visitor {
 private:
    PhvInfo &phv_i;                                           /// referenced through constructor
    PHV_MAU_Group_Assignments &phv_mau_i;                     /// PHV MAU Group Assignments
    PhvInfo::Field *field_i;                                  /// owner field
                                                              // TODO: owner field?
    ordered_map<std::pair<int, int>, PHV_Container::Container_Content *> field_container_map_i;
                                                              /// field ranges -> container bits
                                                              /// range does not straddle containers

 public:
    PHV_Analysis_API(
        PhvInfo &phv_p,
        PHV_MAU_Group_Assignments &phv_mau_p,
        PhvInfo::Field *f_p)
      : phv_i(phv_p), phv_mau_i(phv_mau_p), field_i(f_p) { }

    PhvInfo& phv()                                            { return phv_i; }
    PHV_MAU_Group_Assignments & phv_mau()                     { return phv_mau_i; }
    PhvInfo::Field *field()                                   { return field_i; }
    ordered_map<std::pair<int, int>, PHV_Container::Container_Content *>&
        field_container_map()                                 { return field_container_map_i; }
    //
    const IR::Node *apply_visitor(const IR::Node *, const char *name = 0) override;
    void end_apply() override;
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
    void sanity_check_fields_containers(const std::string&);
    void sanity_check_container_holes(const std::string&);
    //
    // APIs
    //
    // field allocated, contiguously
    bool field_allocated(PhvInfo::Field *f, bool contiguously = false);

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
    // containers to fields
    //
    bool
    container_holes(int phv_num);
    void
    container_holes(
        int phv_num,
        std::list<std::tuple<
            const PHV_Container *,
            const std::pair<int, int>>>& tuple_list);
    void
    container_to_fields(
        int phv_num,
        std::list<std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>>&,
        bool written_fields_only = false,
        bool overlayed_fields_only = false,
        bool sliced_fields_only = false);
    void
    container_to_fields(
        int phv_num,
        std::pair<int, int>&,
        std::list<std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>>&,
        bool written_fields_only = false,
        bool overlayed_fields_only = false,
        bool sliced_fields_only = false);
    //
    // fields written
    //
    void
    fields_written(
        int phv_num,
        std::list<std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>>& tuple_list);
    void
    fields_written(
        int phv_num,
        std::pair<int, int>& f_range,
        std::list<std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>>& tuple_list);
    void
    fields_written(
        std::list<std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>>& tuple_list);  // all fields written in MAU
    void
    fields_written(
        std::list<std::pair<
            PhvInfo::Field *,
            const std::pair<int, int>>>& tuple_list);  // all fields written in program
    //
    // fields overlayed
    //
    void
    fields_overlayed(
        int phv_num,
        std::list<std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>>& tuple_list);
    void
    fields_overlayed(
        int phv_num,
        std::pair<int, int>& f_range,
        std::list<std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>>& tuple_list);
    void
    fields_overlayed(
        std::list<std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>>& tuple_list);  // all fields overlayed in MAU
    void
    fields_overlayed(
        PhvInfo::Field *field,
        std::list<std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>>& tuple_list);  // all fields overlaying a field
    //
    // fields sliced
    //
    void
    fields_sliced(
        int phv_num,
        std::list<std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>>& tuple_list);
    void
    fields_sliced(
        int phv_num,
        std::pair<int, int>& f_range,
        std::list<std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>>& tuple_list);
    void
    fields_sliced(
        std::list<std::tuple<
            PhvInfo::Field *,
            const std::pair<int, int>,
            const PHV_Container *,
            const std::pair<int, int>>>& tuple_list);
    void
    fields_sliced(
        std::list<std::pair<
            PhvInfo::Field *,
            const std::pair<int, int>>>& tuple_list);
    void
    fields_sliced(
        PhvInfo::Field *f,
        std::list<std::pair<
            PhvInfo::Field *,
            const std::pair<int, int>>>& tuple_list);
    //
};  // class PHV_Analysis_API
//
std::ostream &operator<<(
    std::ostream &,
    std::list<std::tuple<
        const PHV_Container *,
        const std::pair<int, int>>>&);
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
