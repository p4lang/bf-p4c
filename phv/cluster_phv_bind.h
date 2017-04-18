#ifndef _TOFINO_PHV_CLUSTER_PHV_BIND_H_
#define _TOFINO_PHV_CLUSTER_PHV_BIND_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"
#include "cluster_phv_mau.h"
//
//
//***********************************************************************************
//
// class PHV_Bind binds containers to fields
// conditions:
// must perform PHV_Bind after PHV_MAU_Group_Assignments pass
//
// input:
// PHV_MAU_Group_Assignments
// phv_mau_map() map<PHV_Container::PHV_Word, std::vector<PHV_MAU_Group *>>
// t_phv_map()   map<int, map<PHV_Container::PHV_Word, std::vector<PHV_Container *>>>
// All containers bit mapped to fields
//
// output:
// fields bound to Containers
//
//***********************************************************************************
//
//
class PHV_Bind : public Visitor {
 private:
    //
    PhvInfo &phv_i;                                 // all fields in input
    PHV_MAU_Group_Assignments &phv_mau_i;           // PHV MAU Group Assignments
    Cluster::Uses *uses_i;                          // field uses mau, I, E
    std::list<const PHV_Container *> containers_i;  // all filled containers
    ordered_set<const PhvInfo::Field *> fields_i;   // all fields to be finally bound
    std::list<const PhvInfo::Field *> fields_overflow_i;
                                                    // overflow fields =  All - PHV_Bind fields
    ordered_map<const PHV_Container*, PHV::Container *> phv_to_asm_map_i;
                                                    // PHV_Container = asm_container PHV::Container
    //
 public:
    //
    PHV_Bind(PhvInfo &phv_f, PHV_MAU_Group_Assignments &phv_m)
       : phv_i(phv_f),
         phv_mau_i(phv_m),
         uses_i(new Cluster::Uses(phv_f)) { }       // Cluster uses() not re-used
                                                    // Uses recomputed
                                                    // dead code elimination
                                                    // happens after Phv Analysis
                                                    // i.e., after Cluser Uses computation
    //
    std::list<const PHV_Container *> containers()         { return containers_i; }
    ordered_set<const PhvInfo::Field *>& fields()         { return fields_i; }
    std::list<const PhvInfo::Field *>& fields_overflow()  { return fields_overflow_i; }
    //
    const IR::Node *apply_visitor(const IR::Node *, const char *name = 0) override;
    void create_phv_asm_container_map();
    void collect_containers_with_fields();
    void phv_tphv_allocate(std::list<const PhvInfo::Field *>& fields);
    void bind_fields_to_containers();
    void container_contiguous_alloc(               // backup for ccgf fields processing
        PhvInfo::Field *,
        int,
        PHV::Container *,
        int);
    void trivial_allocate(std::list<const PhvInfo::Field *>&);
    //
    void sanity_check_field_duplicate_containers(const std::string&);
    void sanity_check_all_fields_allocated(const std::string&);
    void end_apply(const IR::Node *) override { phv_i.set_done(); }
    //
};
//
//
std::ostream &operator<<(std::ostream &, PHV_Bind&);
//
#endif /* _TOFINO_PHV_CLUSTER_PHV_BIND_H_ */
