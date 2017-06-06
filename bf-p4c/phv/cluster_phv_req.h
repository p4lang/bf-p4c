#ifndef _TOFINO_PHV_CLUSTER_PHV_REQ_H_
#define _TOFINO_PHV_CLUSTER_PHV_REQ_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/ordered_set.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"
#include "cluster.h"
#include "cluster_phv_container.h"

static int cluster_id_g = 0;                // global counter for assigning cluster ids
//
class Cluster_PHV {
 private:
    std::vector<PhvInfo::Field *> cluster_vec_i;
                                            // cluster vec sorted by decreasing field width
    int id_num_i = cluster_id_g;            // number part of id_i
    std::string id_i;                       // cluster id
    PHV_Container::Ingress_Egress gress_i;  // ingress or egress
    PHV_Container::PHV_Word width_i;        // container width in PHV group
    bool uniform_width_i = false;           // field widths differ in cluster
    int max_width_i = 0;                    // max width of field in cluster
    int num_containers_i = 0;               // number of containers
    int num_fields_no_cohabit_i = 0;        // number of constrained fields, no cohabit

    /// See documentation for field_overlay_map.
    ordered_map<PhvInfo::Field *,
        ordered_map<int, std::vector<PhvInfo::Field *> *>> field_overlay_map_i;

    bool sliced_i = false;                  // sliced cluster, move-based ops only
    bool exact_containers_i = false;        // true => single field must exact match container width

 public:
    Cluster_PHV(
        ordered_set<PhvInfo::Field *> *set_of_f,
        std::string id_s = "???");                     // NOLINT(runtime/explicit)
                                                       // cluster set of fields
    Cluster_PHV(PhvInfo::Field *f,
        std::string id_s = "???")                      // NOLINT(runtime/explicit)
        : Cluster_PHV(field_set(f), id_s) {}           // cluster singleton field
                                                       // e.g., POV fields
    Cluster_PHV(
        Cluster_PHV *cl,                               // cluster slicing interface
        bool lo = true);                               // NOLINT(runtime/explicit)
    //
    void set_gress();                                  // set gress
    void insert_field_clusters(Cluster_PHV *parent = 0, bool slice_lo = true);
                                                       // field's list of clusters
    void compute_requirements();                       // compute cluster requirements
    int compute_width_req();                           // determines width req of field in cluster
                                                       // field = ccgf w/ constrained member no_pack
    int compute_max_width();                           // determines max_width of field in cluster
                                                       // which can be ccgf "no-pack" constrained
    PHV_Container::PHV_Word container_width(int field_width);
    //
    ordered_set<PhvInfo::Field *> *field_set(PhvInfo::Field *f) {
        ordered_set<PhvInfo::Field *> *s = new ordered_set<PhvInfo::Field *>;
        s->insert(f);
        return s;
    }
    //
    std::vector<PhvInfo::Field *>& cluster_vec()        { return cluster_vec_i; }
    int id_num()                                        { return id_num_i; }
    std::string id()                                    { return id_i; }
    void id(std::string id_p)                           { id_i = id_p; }
    PHV_Container::Ingress_Egress gress()               { return gress_i; }
    PHV_Container::PHV_Word width()                     { return width_i; }
    void width(PHV_Container::PHV_Word w)               { width_i = w; }
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
    int num_containers(std::vector<PhvInfo::Field *>&, PHV_Container::PHV_Word);
    int num_fields_no_cohabit()                         { return num_fields_no_cohabit_i; }

    /** A field overlay map maps each "owner" field to the virtual containers
     * it owns and the other non-owner fields in them.  Fields that are too
     * wide will own more than one virtual container.
     */
    ordered_map<PhvInfo::Field *,
        ordered_map<int, std::vector<PhvInfo::Field *> *>>&
            field_overlay_map()                         { return field_overlay_map_i; }
    //
    bool sliced()                                       { return sliced_i; }
    bool exact_containers()                             { return exact_containers_i; }
    void set_exact_containers();                        // set exact_containers
};  // Cluster_PHV


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
    ordered_map<PHV_Container::PHV_Word, ordered_map<int, std::vector<Cluster_PHV *>>>&);
std::ostream &operator<<(std::ostream &, Cluster_PHV_Requirements&);
//
#endif /* _TOFINO_PHV_CLUSTER_PHV_REQ_H_ */
