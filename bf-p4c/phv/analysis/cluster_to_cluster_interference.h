#ifndef BF_P4C_PHV_ANALYSIS_CLUSTER_TO_CLUSTER_INTERFERENCE_H_
#define BF_P4C_PHV_ANALYSIS_CLUSTER_TO_CLUSTER_INTERFERENCE_H_

#include "bf-p4c/ir/gress.h"
#include "bf-p4c/ir/thread_visitor.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/range.h"
#include "lib/symbitmatrix.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/utils/utils.h"

namespace PHV {
class Field;
}  // namespace PHV

class Clustering;

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
 *
 * @post Populate the clusters_i field of Cluster_Interference
 */

class Cluster_Interference : public Visitor {
 private:
    Clustering &clustering_i;
    SymBitMatrix &mutex_i;                         // fields liveness interference
    std::map<PHV::AlignedCluster*, std::list<PHV::AlignedCluster*>> substratum_overlay_i;
                                                   // maps substratum owners to list of overlays
    std::list<PHV::AlignedCluster*> clusters_i;    // list substratum, overlays .. S1 O11 O12 S2 O21

 public:
    Cluster_Interference(
        Clustering &cl,
        SymBitMatrix &mutex_m)
        : clustering_i(cl), mutex_i(mutex_m) {}

    SymBitMatrix& mutex()                          { return mutex_i; }

    const IR::Node *apply_visitor(const IR::Node *, const char *name = 0) override;

    /* Build a "cluster interference graph" for a vector of clusters.  clusters become vertices.
     * An edge exists between clusters that are NOT mutually exclusive (and hence interfere with
     * each other and cannot be overlaid)
     *
     * After vertex coloring, vertices with the same color are clusters that can be
     * overlaid.
     */
    ordered_map<int, std::vector<PHV::AlignedCluster*>>
        find_overlay(std::vector<PHV::AlignedCluster *> clusters);

    /* For each set of clusters that can be overlaid, find the cluster
     * with the largest number of member fields and make it the owner
     * Then add the rest to its overlay map.
     */
    std::list<PHV::AlignedCluster*>
        do_intercluster_overlay(const ordered_map<int, std::vector<PHV::AlignedCluster*>> reg_map);

    /** Finds clusters that can be overlaid.  For each set of clusters that can be
     * overlaid, chooses a fresh virtual mau group, and makes the largest cluster the
     * "owner" by assigning the other clusters to its cluster_overlay_map.
     *
     * @param clusters  The set of clusters to attempt to overlay.
     *
     * @param msg       Message prepended to debug messages.
     *
     * removes overlaid clusters from @clusters
     */
    void reduce_clusters(std::vector<PHV::AlignedCluster*> clusters, const std::string &msg);

    /** True if @cl1 and all its associated fields are mutually exclusive with
     * @cl2 and all its fields.
     * Compute whether/how c1 and c2 can overlay
     */
    boost::optional<std::map<const PHV::Field *, std::map<int, const PHV::Field *>>>
        mutually_exclusive(PHV::AlignedCluster *cl1, PHV::AlignedCluster *cl2);

    /** True if @cl1 and @cl2 are mutually_exclusive
     * and all constraints necessary for them to be overlaid are satisfiable
     * Compute whether c1 and c2 can overlay
     */
    boost::optional<std::map<const PHV::Field *, std::map<int, const PHV::Field *>>>
        can_overlay(PHV::AlignedCluster *cl1, PHV::AlignedCluster *cl2);

    /** Checks that owners own unique virtual groups, and that overlaid
     * clusters are mutually exclusive.
     */
    void sanity_check_overlay_maps(std::list<PHV::AlignedCluster *>&, const std::string&);

    /** list of Substratum Overlay clusters .. S1 O11 O12 S2 O21 O22 O23 S3 ...
     * list sorted S1 greater container bits than S2
     */
    std::list<PHV::AlignedCluster*>& clusters()      { return clusters_i; }
};

std::ostream &operator<<(std::ostream &, Cluster_Interference&);

#endif /* BF_P4C_PHV_ANALYSIS_CLUSTER_TO_CLUSTER_INTERFERENCE_H_ */
