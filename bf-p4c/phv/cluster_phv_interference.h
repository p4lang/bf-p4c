#ifndef BF_P4C_PHV_CLUSTER_PHV_INTERFERENCE_H_
#define BF_P4C_PHV_CLUSTER_PHV_INTERFERENCE_H_

#include "cluster_phv_req.h"
#include "phv.h"
#include "phv_fields.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/ir/thread_visitor.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/range.h"
#include "lib/symbitmatrix.h"

/** @brief Reduce cluster requirements by identifying fields within a cluster
 * that can be overlaid.
 *
 * This pass attempts to eagerly overlay mutually-exclusive fields within each
 * cluster. It does so for each cluster by:
 *
 *  1. Creating an interference graph, where vertices are field slices and
 *  edges denote that two slices are NOT mutually exclusive---that is, they
 *  interfere with each other.
 *
 *  2. Computing a vertex coloring of the interference graph.  Each color
 *  represents a "virtual container", and fields assigned the same virtual
 *  container do not interfere and can be overlaid.
 *
 *  3. Choosing the widest field in each virtual container as the "owner",
 *  adding the other, non-owner fields to the owner's `field_overlay_map`, and
 *  removing the non-owner fields from the cluster.
 *
 *  4. Recomputing the cluster requirements, now that some fields have been
 *  removed from the cluster (and overlaid).
 *
 * Singleton clusters (i.e. with only one element) are grouped by width and
 * gress; each such group is considered a "cluster" for this pass.
 *
 * EXAMPLE
 *
 * Suppose we have six fields, A--F, involved in the following three operations:
 *
 * ```
 * A     = B<2w> op C
 * D     = C     op E
 * F<2w> = D     op A
 * ```
 *
 * With the following interference edges:
 *
 * ```
 * D---A---E---C---B    F
 *     ^-------^
 * ```
 *
 * where `F<2w>` means F is two words wide.  Let the container width be ONE
 * word wide---F and B will be sliced into two containers each, meaning that
 * this cluster currently requires EIGHT containers.
 *
 * After interference reduction, these fields can fit in three virtual
 * containers:
 *
 *  - Container 1: {D, E, B.1, F.1}
 *  - Container 2: {C}
 *  - Container 3: {A, B.2, F.2}
 *
 * The widest field in each virtual container will be chosen as the owner; the
 * others will be assigned to the owner's `field_overlay_map` and removed from
 * the cluster.
 *
 * Note that a field may be assigned to non-adjacent virtual containers; the
 * `PHV_MAU_Group_Assignments::container_no_pack()` method, invoked as part of
 * the `PHV_MAU_Group_Assignments` pass, ensures that fields with adjacency
 * constraints are assigned to adjacent containers, even if this pass assigns
 * them non-adjacent virtual containers.
 *
 * @pre Cluster_PHV_Requirements and any field overlay information available.
 *
 * @post Populate the field_overlay_map of each Field, and update the <num,
 * width> requirements of each cluster to reflect overlaid fields.
 */

class PHV_Interference : public Visitor {
 private:
    Cluster_PHV_Requirements &phv_requirements_i;  // reference to parent PHV Requirements
    SymBitMatrix &mutex_i;                         // fields liveness interference

 public:
    PHV_Interference(Cluster_PHV_Requirements &phv_r, SymBitMatrix &mutex_m)
        : phv_requirements_i(phv_r), mutex_i(mutex_m) {}

    Cluster_PHV_Requirements& phv_requirements() { return phv_requirements_i; }
    SymBitMatrix& mutex() { return mutex_i; }

    const IR::Node *apply_visitor(const IR::Node *, const char *name = 0) override;

    /** Helper function for `reduce_clusters`. Packages singleton
     * clusters into one big "cluster", recursively invokes
     * `reduce_cluster` on the big cluster, and then splits the result
     * back into singleton clusters.
     *
     * @returns The set of owners (each corresponding to a singleton).
     */
    ordered_set<PHV::Field*> reduce_singleton_clusters(
        const ordered_map<gress_t, ordered_map<int, std::vector<Cluster_PHV *>>>,
        const std::string&);

    /** Helper function for `reduce_cluster`. Assigns sets of fields in @cluster
     * that can be overlaid to a virtual register.  Fields wider than
     * @cluster_width are sliced, and so the same field may appear in two
     * different virtual registers.
     *
     * @return a map from virtual registers to sets of fields that can be
     * overlaid.
     */
    ordered_map<int, std::vector<PHV::Field *>> find_overlay(
        int cluster_width,
        const std::vector<PHV::Field *> cluster);

    /** Helper function for `reduce_cluster`.  For each set of fields in
     * @reg_map, selects the widest as the "owner", and updates the owner's
     * overlay map to overlay the remaining fields on the owner.
     *
     * @returns The set of owners.
     */
    ordered_set<PHV::Field*> do_intracluster_overlay(
        const ordered_map<int, std::vector<PHV::Field*>> reg_map);

    /** Finds fields that can be overlaid.  For each set of fields that can be
     * overlaid, chooses a fresh virtual container, and makes the largest field the
     * "owner" by assigning the other fields to its field_overlay_map.
     *
     * @param fields    The set of fields to attempt to overlay.
     *
     * @param width     The container width of the cluster `fields` are
     * assigned to.  Fields larger than @width will be sliced, and each slice
     * assigned to a different virtual container..
     * // TODO: Handle slicing more uniformly.
     *
     * @param msg       Message prepended to debug messages.
     *
     * @returns The set of owners.
     */
    ordered_set<PHV::Field*> reduce_cluster(
        const std::vector<PHV::Field*> fields,
        int width,
        const std::string& msg);

    /** Reduces each cluster with `reduce_cluster`, and then updates its cluster
     * requirements.
     *
     * Also treats all singleton clusters of the same width in each gress as one
     * big "cluster", in order to overlay singleton cluster fields with each
     * other.
     *
     * Removes non-owner fields from each cluster in @clusters and non-owner
     * singletons from @clusters.
     */
    void reduce_clusters(std::vector<Cluster_PHV *> &clusters, const std::string&);

    /** True if @f1 and all its associated fields are mutually exclusive with
     * @f2 and all its associated fields.  Associated fields are:
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
    bool mutually_exclusive(PHV::Field *f1, PHV::Field *f2);

    /** Checks that owners own unique virtual registers, and that overlaid
     * fields are mutually exclusive.
     */
    void sanity_check_overlay_maps(ordered_set<PHV::Field *>, const std::string&);
};

std::ostream &operator<<(std::ostream &, ordered_map<int, PHV::Field*>&);
std::ostream &operator<<(std::ostream &out,
    ordered_map<gress_t, ordered_map<int, std::vector<Cluster_PHV *>>>&);
std::ostream &operator<<(std::ostream &, PHV_Interference&);

#endif /* BF_P4C_PHV_CLUSTER_PHV_INTERFERENCE_H_ */
