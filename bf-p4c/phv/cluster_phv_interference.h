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

/** @brief Reduce cluster requirements by identifying fields within a cluster
 * that can be overlaid.
 *
 * @pre Cluster_PHV_Requirements and any field overlay information available.
 *
 * @post Populate the field_overlay_map of each Cluster_PHV, and the
 * field_overlay_map of each Field, and update the <num, width> requirements of
 * each cluster to reflect overlaid fields.
 */
class PHV_Interference : public Visitor {
 private:
    //
    Cluster_PHV_Requirements &phv_requirements_i;  // reference to parent PHV Requirements
    SymBitMatrix &mutex_i;                         // fields liveness interference
    //
    ordered_map<PhvInfo::Field *, ordered_set<PhvInfo::Field *>*> interference_edge_i;
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
    bool mutually_exclusive(PhvInfo::Field *f1, PhvInfo::Field *f2);
    void create_interference_edge(PhvInfo::Field *, PhvInfo::Field *);
    void virtual_container_overlay(
        Cluster_PHV *,
        PhvInfo::Field *,
        ordered_map<int, PhvInfo::Field*>&,
        const int);
    void assign_virtual_container(
        Cluster_PHV *,
        PhvInfo::Field *,
        ordered_map<int, PhvInfo::Field*>&);
    //
    void sanity_check_interference(
        Cluster_PHV *,
        const std::string&);
    void sanity_check_overlay_maps(
        ordered_map<int, PhvInfo::Field*>&,
        Cluster_PHV *,
        const std::string&);
    //
};
//
//
std::ostream &operator<<(std::ostream &, ordered_map<int, PhvInfo::Field*>&);
std::ostream &operator<<(std::ostream &out,
    ordered_map<PHV_Container::Ingress_Egress,
        ordered_map<int,
            std::vector<Cluster_PHV *>>>&);
std::ostream &operator<<(std::ostream &, PHV_Interference&);
//
#endif /* _TOFINO_PHV_CLUSTER_PHV_INTERFERENCE_H_ */
