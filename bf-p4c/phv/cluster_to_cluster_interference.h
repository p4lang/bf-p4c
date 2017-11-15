#ifndef BF_P4C_PHV_CLUSTER_TO_CLUSTER_INTERFERENCE_H_
#define BF_P4C_PHV_CLUSTER_TO_CLUSTER_INTERFERENCE_H_

#include "bf-p4c/ir/gress.h"
#include "bf-p4c/ir/thread_visitor.h"
#include "bf-p4c/phv/cluster_phv_req.h"
#include "bf-p4c/phv/phv.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/range.h"
#include "lib/symbitmatrix.h"

namespace PHV {
class Field;
}  // namespace PHV

/** @brief Reduce cluster requirements by identifying clusters
 * that can be overlaid with other clusters.
 *
 * This pass attempts to eagerly overlay mutually-exclusive clusters
 * It does so for each cluster by:
 *
 *  1. Creating an interference graph, where vertices are clusters and
 *  edges denote that two clusters are NOT mutually exclusive---that is, field(s)
 *  of one cluster interfere with fields of the other.
 *
 *  2. Computing a vertex coloring of the interference graph.  Each color
 *  represents a "virtual MAU group", and fields assigned the same virtual
 *  group do not interfere and can be overlaid.
 *
 *  3. Choosing the widest field cluster (considering alignment and width of fields in cluster)
 *  in each virtual group as the "owner",
 *  adding the other, non-owner clusters to the owner's `cluster_overlay_map`, and
 *  removing the non-owner clusters from the list of clusters to be phv allocated.
 *
 *  4. Recomputing cluster requirements, now that some clusters have been
 *  removed from the list of clusters (and overlaid).
 *
 * Singleton clusters (i.e. with only one element) have already been  grouped by width and
 * gress by a previous pass "cluster_phv_interference"
 *
 *
 * @pre Cluster_PHV_Requirements and any field overlay information available.
 * @pre Cluster_PHV_Interference and any field overlay information available.
 *
 * @post Populate the cluster_overlay_map of each cluster
 */

class Cluster_Interference : public Visitor {
 private:
    Cluster_PHV_Requirements &phv_requirements_i;  // reference to parent PHV Requirements
    PHV_Interference &phv_interference_i;          // reference to PHV Interference
    SymBitMatrix &mutex_i;                         // fields liveness interference

 public:
    Cluster_Interference(
        Cluster_PHV_Requirements &phv_r, PHV_Interference &phv_interf_m, SymBitMatrix &mutex_m)
        : phv_requirements_i(phv_r), phv_interference_i(phv_interf_m), mutex_i(mutex_m) {}

    Cluster_PHV_Requirements& phv_requirements()   { return phv_requirements_i; }
    PHV_Interference& phv_interference()           { return phv_interference_i; }
    SymBitMatrix& mutex()                          { return mutex_i; }

    const IR::Node *apply_visitor(const IR::Node *, const char *name = 0) override;

    /* Build a "cluster interference graph" for a vector of clusters.  clusters become
     * vertices. An edge exists
     * between clusters that are NOT mutually exclusive (and hence interfere with
     * each other and cannot be overlaid)
     *
     * After vertex coloring, vertices with the same color are clusters that can be
     * overlaid.
     */
    ordered_map<int, std::vector<Cluster_PHV*>>
        find_overlay(std::vector<Cluster_PHV *> clusters);

    /* For each set of clusters that can be overlaid, find the cluster
     * with the largest number of member fields and make it the owner
     * Then add the rest to its overlay map.
     */
    std::vector<Cluster_PHV*>
        do_intercluster_overlay(const ordered_map<int, std::vector<Cluster_PHV*>> reg_map);

    /** Finds clusters that can be overlaid.  For each set of clusters that can be
     * overlaid, chooses a fresh virtual mau group, and makes the largest cluster the
     * "owner" by assigning the other clusters to its cluster_overlay_map.
     *
     * @param clusters    The set of clusters to attempt to overlay.
     *
     * @param msg       Message prepended to debug messages.
     *
     * updates the reduced set of clusters.
     */
    void reduce_clusters(std::vector<Cluster_PHV*> &clusters, const std::string &msg);

    /** True if @cl1 and all its associated fields are mutually exclusive with
     * @cl2 and all its associated fields.  Associated fields are:
     *
     *  - the field itself
     *  - all CCGF fields, if it is a CCGF owner
     *  - all fields that overlay it
     *  - all CCGF fields of fields that overlay it, if any of those fields
     *    are CCGF owners
     *
     * Note that preventing two CCGF fields from overlaying unless ALL their
     * sub-fields can overlay is conservative.  Suppose we have the following
     * two CCGFs:
     *
     *   f1: {f1, f2}
     *   f3: {f3, f4}
     *
     * If we know that both CCGFs will be overlaid starting at the same bit,
     * and if f1 is the same width as f3, and f2 as f4, then only f1---f3 and
     * f2---f4 need to be mutually exclusive, but not f1---f4 or f2---f3.
     */
    bool mutually_exclusive(Cluster_PHV *cl1, Cluster_PHV *cl2, bool seal_deal = false);

    /** Checks that owners own unique virtual groups, and that overlaid
     * clusters are mutually exclusive.
     * note that several virtual groups can be mapped to a single mau group
     */
    void sanity_check_overlay_maps(std::vector<Cluster_PHV *>, const std::string&);
};

std::ostream &operator<<(std::ostream &, ordered_map<int, Cluster_PHV*>&);
std::ostream &operator<<(std::ostream &, Cluster_Interference&);

#endif /* BF_P4C_PHV_CLUSTER_TO_CLUSTER_INTERFERENCE_H_ */
