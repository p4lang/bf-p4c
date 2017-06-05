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

/** Cluster Slicing
 *
 * slice clusters into smaller clusters
 * (i) attempt packing with reduced width requirements
 *     albeit due to gress mismatch sliced clusters may not be packed
 *
 * (ii) slicing improves overlay possibilities due to lesser width
 *      although number and mutual exclusion of fields don't change
 *
 * 1. iterate over all fields in cluster,
 *    if all operations on field are "move" based
 *        cluster can be sliced
 *    else
 *        cluster cannot sliced
 *
 * 2. slice cluster by half, or +/- 1-bit around center
 */
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

    /// Slice a list of clusters.
    void cluster_slice(
        std::list<Cluster_PHV *>&);

    /// Slice a single cluster into halves.
    std::pair<Cluster_PHV *, Cluster_PHV *> cluster_slice(
        Cluster_PHV *);
    //
    void sanity_check_cluster_slices(const std::string&);
};

std::ostream &operator<<(std::ostream &, Cluster_Slicing &);

#endif /* _TOFINO_PHV_CLUSTER_PHV_SLICING_H_ */
