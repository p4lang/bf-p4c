#ifndef _TOFINO_PHV_CLUSTER_PHV_INTERFERENCE_H_
#define _TOFINO_PHV_CLUSTER_PHV_INTERFERENCE_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/range.h"
#include "lib/symbitmatrix.h"
#include "tofino/ir/thread_visitor.h"
#include "cluster_phv_req.h"
//
//
//***********************************************************************************
//
// class PHV_Interference constructs an interference graph after liveness analysis
// to reduce cluster phv requirements
//
// conditions:
// must perform PHV_Interference after Cluster_PHV_Requirements pass
//
// input:
// Cluster_PHV_Requirements
// ordered_map<PHV_Container::PHV_Word,
//   ordered_map<int, std::vector<Cluster_PHV *>>> cluster_phv_map()
// SymBitMatrix mutex_i  = fields' liveness interference
//
// output:
// for each cluster in cluster_phv_map(), reduced requirements <num, width>
//
//***********************************************************************************
//
//
class PHV_Interference : public Visitor {
 private:
    //
    Cluster_PHV_Requirements &phv_requirements_i;  // reference to parent PHV Requirements
    SymBitMatrix &mutex_i;                         // fields liveness interference
    //
    ordered_map<const PhvInfo::Field *, ordered_set<const PhvInfo::Field *>*> interference_edge_i;
                                                   // interference graph edges
    //
 public:
    //
    PHV_Interference(Cluster_PHV_Requirements &phv_r, SymBitMatrix &mutex_m)
        : phv_requirements_i(phv_r), mutex_i(mutex_m) {}
    //
    Cluster_PHV_Requirements&
        phv_requirements() { return phv_requirements_i; }
    SymBitMatrix&
        mutex()            { return mutex_i; }
    //
    const IR::Node *apply_visitor(const IR::Node *, const char *name = 0) override;
    void aggregate_singleton_clusters(
        std::vector<Cluster_PHV *>&,  // original cluster vec
        std::vector<Cluster_PHV *>&,  // aggregate clusters from map of singletons
        ordered_map<PHV_Container::Ingress_Egress,
            ordered_map<int,
                std::vector<Cluster_PHV *>>>&);
    void interference_reduction_singleton_clusters(
        std::vector<Cluster_PHV *>&,
        ordered_map<PHV_Container::Ingress_Egress,
            ordered_map<int,
                std::vector<Cluster_PHV *>>>,
        const std::string&);
    void interference_reduction(
        std::vector<Cluster_PHV *>&,
        const std::string&);
    void create_interference_edge(const PhvInfo::Field *, const PhvInfo::Field *);
    void virtual_container_overlay(
        Cluster_PHV *,
        const PhvInfo::Field *,
        ordered_map<int, const PhvInfo::Field*>&,
        const int);
    void assign_virtual_container(
        Cluster_PHV *,
        const PhvInfo::Field *,
        ordered_map<int, const PhvInfo::Field*>&);
    //
    void sanity_check_interference(
        Cluster_PHV *,
        const std::string&);
    void sanity_check_overlay_maps(
        ordered_map<int, const PhvInfo::Field*>&,
        Cluster_PHV *,
        const std::string&);
    //
};
//
//
std::ostream &operator<<(std::ostream &, ordered_map<int, const PhvInfo::Field*>&);
std::ostream &operator<<(std::ostream &out,
    ordered_map<PHV_Container::Ingress_Egress,
        ordered_map<int,
            std::vector<Cluster_PHV *>>>&);
std::ostream &operator<<(std::ostream &, PHV_Interference&);
//
#endif /* _TOFINO_PHV_CLUSTER_PHV_INTERFERENCE_H_ */
