#ifndef BF_P4C_PHV_CLUSTER_PHV_REQ_H_
#define BF_P4C_PHV_CLUSTER_PHV_REQ_H_

#include "bf-p4c/ir/gress.h"
#include "bf-p4c/ir/thread_visitor.h"
#include "bf-p4c/phv/cluster.h"
#include "bf-p4c/phv/cluster_phv_container.h"
#include "bf-p4c/phv/phv.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/ordered_set.h"
#include "lib/range.h"

namespace PHV {
class Field;
}  // namespace PHV

class Cluster_PHV {
 private:
    std::vector<PHV::Field *> cluster_vec_i;           // vec sorted by decreasing field width
    std::vector<Cluster_PHV *> cluster_overlay_vec_i;  // clusters that can overlay this cluster
    Cluster_PHV *overlay_substratum_i = nullptr;       // this cluster overlay on substratum cluster
    int id_num_i;                                      // number part of id_i
    std::string id_i;                                  // cluster id
    gress_t gress_i;                                   // ingress or egress
    bool uniform_width_i = false;                      // field widths differ in cluster
    int max_width_i = 0;                               // max width of field in cluster
    int num_containers_i = 0;                          // # of containers
    PHV::Size width_i;                                 // container width in PHV group
    int num_overlays_i = 0;                            // number of overlay fields
    int num_constraints_i = 0;                         // # of constrained fields, e.g., no cohabit
    bool sliced_i = false;                             // sliced cluster, move-based ops only
    bool exact_containers_i = false;                   // true => field must match container width

 public:
    Cluster_PHV(
        ordered_set<PHV::Field *> *set_of_f,
        std::string id_s = "???");                     // NOLINT(runtime/explicit)
                                                       // cluster set of fields
    Cluster_PHV(PHV::Field *f,
        std::string id_s = "???");                     // NOLINT(runtime/explicit)

    Cluster_PHV(
        Cluster_PHV *cl,                               // cluster slicing interface
        bool lo = true);                               // NOLINT(runtime/explicit)

    void set_gress();                                  // set gress
    int compute_num_overlays();                        // number of overlay fields on this cluster
    void insert_field_clusters(Cluster_PHV *parent = 0, bool slice_lo = true);
                                                       // field's list of clusters
    void compute_requirements();                       // compute cluster requirements
    int compute_width_req();                           // determines width req of field in cluster
                                                       // field = ccgf w/ constrained member no_pack
    int compute_max_width();                           // determines max_width of field in cluster
                                                       // which can be ccgf "no-pack" constrained
    PHV::Size container_width(int field_width);

    ordered_set<PHV::Field *> *field_set(PHV::Field *f) {
        ordered_set<PHV::Field *> *s = new ordered_set<PHV::Field *>;
        s->insert(f);
        return s;
    }

    std::vector<PHV::Field *>& cluster_vec()            { return cluster_vec_i; }
    const std::vector<PHV::Field *>& cluster_vec() const  { return cluster_vec_i; }
    std::vector<Cluster_PHV *>& cluster_overlay_vec()   { return cluster_overlay_vec_i; }
    Cluster_PHV* overlay_substratum() const             { return overlay_substratum_i; }
    void overlay_substratum(Cluster_PHV *cl)            { overlay_substratum_i = cl; }
    int id_num()                                        { return id_num_i; }
    std::string id()                                    { return id_i; }
    void id(std::string id_p)                           { id_i = id_p; }
    gress_t gress()                                     { return gress_i; }
    PHV::Size width()                                   { return width_i; }
    void width(PHV::Size w)                             { width_i = w; }
    bool uniform_width()                                { return uniform_width_i; }
    int max_width()                                     { return max_width_i; }
    void max_width(int i)                               { max_width_i = i; }
    int needed_bits() {
        if (uniform_width_i) {
            return cluster_vec_i.size() * max_width_i;
        } else {
            int f_bits = 0;
            for (auto &f : cluster_vec_i) {
                f_bits += f->phv_use_width();
            }
            return f_bits;
        }
    }
    int num_containers()                                { return num_containers_i; }
    void num_containers(int n)                          { num_containers_i = n; }
    int num_containers(PHV::Field *);
    int num_containers(PHV::Field *, PHV::Size width);
    int num_containers(std::vector<PHV::Field *>&);
    int num_containers(std::vector<PHV::Field *>&, PHV::Size width);
    int num_constraints()                               { return num_constraints_i; }
    int num_overlays()                                  { return num_overlays_i; }

    bool sliced()                                       { return sliced_i; }
    int req_containers_bottom_bits();  // number of fields that must be in bottom bits of container
    bool exact_containers()                             { return exact_containers_i; }
    void set_exact_containers();                        // set exact_containers

    /** Returns the width of @f, taking the following into consideration:
     *
     *    1. If @f is in this cluster and this is a sliced cluster, then
     *    returns the width of the slice of @f under consideration.
     *
     *    2. If @f is a CCGF owner, returns the total size of all CCGF members.
     *    This is different than `f->phv_use_width()`, which may be
     *    artificially inflated beyond the size of the field to force PHV
     *    allocation to place the field alone in a container.
     *
     *    3. Otherwise, returns `f->size`.
     *
     * (1) and (2) are mutually exclusive, as CCGFs cannot be sliced.
     */
    int get_field_placement_size(const PHV::Field *f) const;
};


//***********************************************************************************
//
// class Cluster_PHV_Requirements computes Cluster Requirements (width & number of containers)
// for every computed cluster after Cluster analysis
// class Cluster_PHV computes requirements for each cluster
// conditions:
// must perform Cluster_PHV_Requirements analysis after &cluster pass
// input:
// cluster.dst_map() computed by Cluster
// accumulated map<field*, pointer to cluster_set of field*>
// output:
// accumulated vector<Cluster_PHV*> for each of PHV_Word (32,16,8-bit) widths
//
//***********************************************************************************
//
//

/** @brief Analyze properties and requirements for each cluster, and sort them
 * by size and kind.
 *
 * @pre PhvInfo, Cluster.
 *
 * @post Each cluster has a Cluster_PHV object describing its properties and
 * requirements, but the field_overlay_map is empty.  Cluster_PHVs are sorted
 * and stored in Cluster_PHV_Requirements fields.
 */
class Cluster_PHV_Requirements : public Visitor {
 private:
    Cluster &cluster_i;

    /** Cluster requirements sorted by <number of fields, width> in decreasing
     * order (num, then width).
     */
    std::vector<Cluster_PHV *> Cluster_PHV_i;

    /** sorted pov fields, width decreasing header-stack POVs are not 1-bit
     * fields such fields must be contiguously allocated in PHV
     */
    std::vector<Cluster_PHV *> pov_fields_i;

    /// fields that are not used through mau pipeline, sorted width decreasing
    std::vector<Cluster_PHV *> t_phv_fields_i;

 public:
    // TODO: The name "Cluster" is a bit confusing---it implies a single
    // cluster.
    Cluster_PHV_Requirements(Cluster &c) : cluster_i(c) {}  // NOLINT(runtime/explicit)
    //
    Cluster&
        cluster() { return cluster_i; }
    //
    std::vector<Cluster_PHV *>& cluster_phv_fields()  { return Cluster_PHV_i; }
    //
    std::vector<Cluster_PHV *>& pov_fields()          { return pov_fields_i; }
    std::vector<Cluster_PHV *>& t_phv_fields()        { return t_phv_fields_i; }
    //
    const IR::Node *apply_visitor(const IR::Node *, const char *name = 0) override;
    //
    std::pair<int, int> gress(std::list<Cluster_PHV *>& cluster_list);
};
//
//
std::ostream &operator<<(std::ostream &, Cluster_PHV&);
std::ostream &operator<<(std::ostream &, Cluster_PHV*);
std::ostream &operator<<(std::ostream &, std::list<Cluster_PHV *>&);
std::ostream &operator<<(std::ostream &, std::vector<Cluster_PHV *>*);
std::ostream &operator<<(std::ostream &, std::vector<Cluster_PHV *>&);
std::ostream &operator<<(std::ostream &, ordered_map<int, std::vector<Cluster_PHV *>>&);
std::ostream &operator<<(std::ostream &,
    ordered_map<PHV::Size, ordered_map<int, std::vector<Cluster_PHV *>>>&);
std::ostream &operator<<(std::ostream &, Cluster_PHV_Requirements&);
//
#endif /* BF_P4C_PHV_CLUSTER_PHV_REQ_H_ */
