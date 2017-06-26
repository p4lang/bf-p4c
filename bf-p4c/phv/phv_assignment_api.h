#ifndef _TOFINO_PHV_PHV_ASSIGNMENT_API_H_
#define _TOFINO_PHV_PHV_ASSIGNMENT_API_H_

#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"
//
//***********************************************************************************
//
// PHV Assignment API
// contains results from PHV Assignment/phv_bind PassManager in backend.cpp
// this object extends from PhvInfo::Field  field->phv_assignment_api
//
//***********************************************************************************
//
//
class PHV_Assignment_API : public Visitor {
 private:
    PhvInfo &phv_i;                                   /// referenced through constructor
    PhvInfo::Field *field_i;                          /// owner field points to this extended object
                                                      //  this object =field_i->phv_assignment_api_i
    Cluster::Uses *uses_i;                            /// field used? in mau, parde
    ordered_map<std::pair<int, int>, const PhvInfo::Field::alloc_slice *> field_container_map_i;
                                                      /// field ranges to container bits
                                                      /// range does not straddle containers
    static std::map<cstring, std::list<const PhvInfo::Field::alloc_slice *>>
        phv_name_alloc_slices_map_i;                  /// map PHV::Container name to alloc slices
    static ordered_map<cstring, PHV::Container *> phv_name_container_map_i;
                                                      /// map PHV::Container name -- PHV::Container*

 public:
    PHV_Assignment_API(
        PhvInfo &phv_p,
        PhvInfo::Field *f_p)
      : phv_i(phv_p),
        field_i(f_p),
        uses_i(new Cluster::Uses(phv_p)) { }

    PhvInfo& phv()                                        { return phv_i; }
    PhvInfo::Field *field()                               { return field_i; }
    Cluster::Uses *uses()                                 { return uses_i; }
    ordered_map<std::pair<int, int>, const PhvInfo::Field::alloc_slice *>&
        field_container_map()                             { return field_container_map_i; }
    std::map<cstring, std::list<const PhvInfo::Field::alloc_slice *>>&
        phv_name_alloc_slices_map()                       { return phv_name_alloc_slices_map_i; }
    ordered_map<cstring, PHV::Container *>&
        phv_name_container_map()                          { return phv_name_container_map_i; }
    PHV::Container *
        phv_name_container_map(cstring name)              { return phv_name_container_map_i[name]; }
    //
    const IR::Node *apply_visitor(const IR::Node *, const char *name = 0) override;
    void end_apply() override;
    //
    void create_field_container_map();
    std::tuple<
        const PhvInfo::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>
            make_tuple(const PhvInfo::Field::alloc_slice *slice);
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
            const PhvInfo::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>>>&);
    void
    field_to_containers(
        PhvInfo::Field *,
        std::pair<int, int>&,
        std::list<std::tuple<
            const PhvInfo::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>>>&);
    //
    // containers to fields
    //
    bool
    container_holes(PHV::Container&);
    void
    container_holes(
        PHV::Container&,
        std::list<std::tuple<
            PHV::Container *,
            const std::pair<int, int>>>& tuple_list);
    void
    container_holes(
        PHV::Container&,
        std::list<std::pair<int, int>>& holes_list);
    void
    container_to_fields(
        PHV::Container&,
        std::list<std::tuple<
            const PhvInfo::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>>>&,
        bool written_fields_only = false,
        bool overlayed_fields_only = false,
        bool sliced_fields_only = false);
    void
    container_to_fields(
        PHV::Container&,
        std::pair<int, int>&,
        std::list<std::tuple<
            const PhvInfo::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>>>&,
        bool written_fields_only = false,
        bool overlayed_fields_only = false,
        bool sliced_fields_only = false);
    //
    // fields written
    //
    void
    fields_written(
        PHV::Container&,
        std::list<std::tuple<
            const PhvInfo::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>>>& tuple_list);
    void
    fields_written(
        PHV::Container&,
        std::pair<int, int>& f_range,
        std::list<std::tuple<
            const PhvInfo::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>>>& tuple_list);
    void
    fields_written(
        std::list<std::tuple<
            const PhvInfo::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>>>& tuple_list);  // all fields written in MAU
    void
    fields_written(
        std::list<std::pair<
            const PhvInfo::Field *,
            const std::pair<int, int>>>& tuple_list);  // all fields written in program
    //
    // fields overlayed
    //
    void
    fields_overlayed(
        PHV::Container&,
        std::list<std::tuple<
            const PhvInfo::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>>>& tuple_list);
    void
    fields_overlayed(
        PHV::Container&,
        std::pair<int, int>& f_range,
        std::list<std::tuple<
            const PhvInfo::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>>>& tuple_list);
    void
    fields_overlayed(
        std::list<std::tuple<
            const PhvInfo::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>>>& tuple_list);  // all fields overlayed in MAU
    void
    fields_overlayed(
        PhvInfo::Field *field,
        std::list<std::tuple<
            const PhvInfo::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>>>& tuple_list);  // all fields overlaying a field
    //
    // fields sliced
    //
    void
    fields_sliced(
        PHV::Container&,
        std::list<std::tuple<
            const PhvInfo::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>>>& tuple_list);
    void
    fields_sliced(
        PHV::Container&,
        std::pair<int, int>& f_range,
        std::list<std::tuple<
            const PhvInfo::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>>>& tuple_list);
    void
    fields_sliced(
        std::list<std::tuple<
            const PhvInfo::Field *,
            const std::pair<int, int>,
            PHV::Container *,
            const std::pair<int, int>>>& tuple_list);
    void
    fields_sliced(
        std::list<std::pair<
            const PhvInfo::Field *,
            const std::pair<int, int>>>& tuple_list);
    void
    fields_sliced(
        PhvInfo::Field *f,
        std::list<std::pair<
            const PhvInfo::Field *,
            const std::pair<int, int>>>& tuple_list);
    //
};  // class PHV_Assignment_API
//
std::ostream &operator<<(
    std::ostream &,
    std::list<std::tuple<
        PHV::Container *,
        const std::pair<int, int>>>&);
std::ostream &operator<<(
    std::ostream &,
    std::tuple<
        const PhvInfo::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>&);
std::ostream &operator<<(
    std::ostream &,
    std::list<std::tuple<
        const PhvInfo::Field *,
        const std::pair<int, int>,
        PHV::Container *,
        const std::pair<int, int>>>&);
std::ostream &operator<<(
    std::ostream &,
    ordered_map<std::pair<int, int>, const PhvInfo::Field::alloc_slice *>&);
std::ostream &operator<<(
    std::ostream &out,
    std::map<cstring, std::list<const PhvInfo::Field::alloc_slice *>>&);
std::ostream &operator<<(std::ostream &, PHV_Assignment_API &);
//
#endif /* _TOFINO_PHV_PHV_ASSIGNMENT_API_H_ */
