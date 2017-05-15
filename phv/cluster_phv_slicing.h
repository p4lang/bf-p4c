#ifndef _TOFINO_PHV_CLUSTER_PHV_SLICING_H_
#define _TOFINO_PHV_CLUSTER_PHV_SLICING_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"
#include "cluster.h"
#include "cluster_phv_mau.h"
//
//***********************************************************************************
//
// cluster Slicing
// attempt to slice clusters to enable packing into smaller width phv empty slots
//
//***********************************************************************************
//
//
class Cluster_Slicing : public Visitor {
 private:
    PHV_MAU_Group_Assignments &phv_mau_i;              // PHV MAU Group Assignments

 public:
    Cluster_Slicing(PHV_MAU_Group_Assignments &phv_m)  // NOLINT(runtime/explicit)
        : phv_mau_i(phv_m) {}
    //
    PHV_MAU_Group_Assignments& phv_mau() { return phv_mau_i; }
    //
    const IR::Node *apply_visitor(const IR::Node *, const char *name = 0) override;
    //
    bool gress_compatibility(
        std::pair<int, int>,
        std::pair<int, int>);
    void cluster_slice(
        std::list<Cluster_PHV *>&);                    // slice a list of clusters
    std::pair<Cluster_PHV *, Cluster_PHV *> cluster_slice(
        Cluster_PHV *);                                // slice single cluster into halves
    //
    void sanity_check_cluster_slices(const std::string&);
};

std::ostream &operator<<(std::ostream &, Cluster_Slicing &);

#endif /* _TOFINO_PHV_CLUSTER_PHV_SLICING_H_ */
