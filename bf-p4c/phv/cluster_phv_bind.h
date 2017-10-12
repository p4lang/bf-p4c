#ifndef BF_P4C_PHV_CLUSTER_PHV_BIND_H_
#define BF_P4C_PHV_CLUSTER_PHV_BIND_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/range.h"
#include "bf-p4c/ir/thread_visitor.h"
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
    const PhvUse &uses_i;                           // field uses mau, I, E
    const PHV_MAU_Group_Assignments &phv_mau_i;     // PHV MAU Group Assignments

    std::list<const PHV_Container *> containers_i;  // all filled containers
    std::list<PHV::Field *> allocated_fields_i;
                                                    // allocated fields to be finally bound
    std::list<PHV::Field *> fields_overflow_i;
                                                    // overflow fields =  All - PHV_Bind fields

    void sanity_check_field_duplicate_containers(const std::string&);
    void sanity_check_field_slices(ordered_set<PHV::Field *>&, const std::string&);
    void sanity_check_all_fields_allocated(const std::string&);

 public:
    PHV_Bind(PhvInfo &phv_f, const PhvUse &u, const PHV_MAU_Group_Assignments &phv_m)
       : phv_i(phv_f),
         uses_i(u),          // uses recomputed, dead code elimination after Cluster Use computation
         phv_mau_i(phv_m) { }

    std::list<const PHV_Container *> containers()     { return containers_i; }
    std::list<PHV::Field *>& allocated_fields()       { return allocated_fields_i; }
    std::list<PHV::Field *>& fields_overflow()        { return fields_overflow_i; }

    const IR::Node *apply_visitor(const IR::Node *, const char *name = 0) override;
    void end_apply(const IR::Node *) override { phv_i.set_done(); }

    void collect_containers_with_fields();
    void bind_fields_to_containers();

    // function to obtain PHV_Container from PHV::Container & vice-versa
    const PHV::Container *phv_container(const PHV_Container *) const;
    const PHV_Container *phv_container(const PHV::Container *) const;
};

std::ostream &operator<<(std::ostream &, PHV_Bind&);

#endif /* BF_P4C_PHV_CLUSTER_PHV_BIND_H_ */
