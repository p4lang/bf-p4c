#ifndef _TOFINO_PHV_CLUSTER_PHV_OVERLAY_H_
#define _TOFINO_PHV_CLUSTER_PHV_OVERLAY_H_

#include "phv.h"
#include "phv_fields.h"
#include "cluster.h"
//
//***********************************************************************************
// Overlay overflown fields to containers with mutual exclusiveness headers
//***********************************************************************************
//
class Cluster_PHV_Overlay : public Visitor {
 private:
    PHV_MAU_Group_Assignments &phv_mau_i;
    SymBitMatrix &mutex_i;
 public:
    Cluster_PHV_Overlay(
        PHV_MAU_Group_Assignments &phv_m,
        SymBitMatrix &mutex_m) : phv_mau_i(phv_m), mutex_i(mutex_m) {}
    //
    const IR::Node *apply_visitor(const IR::Node *node, const char *name = 0) override;
    bool overlay_cluster_to_group(Cluster_PHV *cl, PHV_MAU_Group *g);
    void overlay_clusters_to_groups(std::list<Cluster_PHV *>& clusters_to_be_assigned,
                                    std::list<PHV_MAU_Group *>& phv_groups_to_be_overlayed,
                                    const char *msg = "");
    bool check_field_with_container(const PhvInfo::Field *field, PHV_Container *ctnr);
};

#endif /* _TOFINO_PHV_CLUSTER_PHV_OVERLAY_H_ */
