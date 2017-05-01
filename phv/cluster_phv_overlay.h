#ifndef _TOFINO_PHV_CLUSTER_PHV_OVERLAY_H_
#define _TOFINO_PHV_CLUSTER_PHV_OVERLAY_H_

#include "cluster_phv_interference.h"
//
//*************************************************************************************************
//
// cluster_phv_overlay overflow clusters that have not yet been allocated to PHV containers
// they overlay containers with mutually exclusive fields
// considering mutually exclusive headers and/or liveness analysis
//
//*************************************************************************************************
//
//
class Cluster_PHV_Overlay : public Visitor {
 private:
    PHV_MAU_Group_Assignments &phv_mau_i;
    PHV_Interference &phv_interference_i;

 public:
    Cluster_PHV_Overlay(
        PHV_MAU_Group_Assignments &phv_mau_m,
        PHV_Interference &phv_interference_m)
        : phv_mau_i(phv_mau_m), phv_interference_i(phv_interference_m) {}
    //
    PHV_MAU_Group_Assignments& phv_mau() { return phv_mau_i; }
    //
    const IR::Node *apply_visitor(const IR::Node *node, const char *name = 0) override;
    //
    // cluster to cluster overlay
    //
    bool overlay_field_to_field(
        PhvInfo::Field *f_overlay,
        PhvInfo::Field *f_substratum,
        bool exceed_substratum = false);
    bool overlay_cluster_to_cluster(
        Cluster_PHV *cl_1,
        Cluster_PHV *cl_2);
    void overlay_clusters_to_clusters(
        std::list<Cluster_PHV *>& overlay_clusters_to_be_assigned,
        std::list<Cluster_PHV *>& substratum_clusters,
        const char *msg = "");
    //
    // cluster to MAU group overlay
    //
    bool overlay_field_to_container(
        Cluster_PHV *cl,
        PhvInfo::Field *field,
        PHV_Container *c,
        int run_width,
        int &start_bit);
    bool overlay_cluster_to_mau_group(
        Cluster_PHV *cl,
        PHV_MAU_Group *g);
    void overlay_clusters_to_mau_groups(
        std::list<Cluster_PHV *>& clusters_to_be_assigned,
        std::list<PHV_MAU_Group *>& phv_groups_to_be_overlayed,
        const char *msg = "");
};

std::ostream &operator<<(
    std::ostream &,
    ordered_map<PhvInfo::Field *, std::list<std::pair<PHV_Container *, int>>>&);
std::ostream &operator<<(
    std::ostream &,
    Cluster_PHV_Overlay&);

#endif /* _TOFINO_PHV_CLUSTER_PHV_OVERLAY_H_ */
