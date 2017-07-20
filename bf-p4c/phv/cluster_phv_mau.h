#ifndef _TOFINO_PHV_CLUSTER_PHV_MAU_H_
#define _TOFINO_PHV_CLUSTER_PHV_MAU_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"
#include "cluster_phv_req.h"

/** @brief PHV_MAU_Group_Assignments computes MAU Group Assignments to clusters.
 *
 * input:
 * - cluster_phv_requirements.cluster_phv_map()
 * - sorted requirements computed by Cluster_PHV_Requirements
 * - accumulated vector<Cluster_PHV*> for each of PHV_Word (32,16,8-bit) widths
 *
 * output:
 * - cluster fields mapped to MAU Groups with Container Assignments
 * - substratum_phv_clusters and substratum_t_phv_clusters, which are (non-POV)
 *   clusters that could not be assigned
 * - cohabit_fields
 * - clusters_to_be_assigned, clusters_to_be_assigned_nibble, t_phv_fields, and
 *   t_phv_fields_nibble with remaining clusters that were not able to be
 *   assigned (if any)
 *
 * @pre Cluster_PHV_Requirements.
 */
class PHV_MAU_Group_Assignments;

/** @brief A PHV container group.  ALU operands and the container being written
 * must be in the same group.
 */
class PHV_MAU_Group {
 public:
    /** @brief Marks a contiguous bit segment @l to @h (inclusive) of a
     * PHV_Container.
     */
    class Container_Content {
     //
     // PHV_MAU_Group Container_Content represents a container slice of contiguously available bits
     // a container's range of available bits can be partitioned into several slices
     // based on alignment with slices from other containers within the same MAU group
     // cluster of fields mapped to aligned container slices, <number, width>, within a MAU group
     //
     private:
        int lo_i;  // low of bit range in container for packing
        int hi_i;  // high of bit range in container for packing
        PHV_Container *container_i;
        //
     public:
        //
        Container_Content(int l, int h, PHV_Container *c);
        //
        int lo() const                  { return lo_i; }
        void lo(int l)                  { lo_i = l; }
        int hi() const                  { return hi_i; }
        void hi(int h)                  { hi_i = h; }
        int width() const               { return hi_i - lo_i + 1; }
        PHV_Container *container()      { return container_i; }
        //
        void sanity_check_container(const std::string&);
    };
    //
 private:
    //
    PHV_Container::PHV_Word width_i;                    // container width in PHV group
    int number_i;                                       // 1..4 [32], 1..6 [16], 1..4 [8]
    PHV_Container::Ingress_Egress gress_i;              // Ingress_Only,
                                                        // Egress_Only,
                                                        // Ingress_Or_Egress
    size_t empty_containers_i;                          // number of containers that remain Empty
    std::vector<PHV_Container *> phv_containers_i;      // containers in this MAU group
    std::vector<Cluster_PHV *> cluster_phv_i;           // clusters in this MAU group
    ordered_map<int,
        ordered_map<int,
            std::list<std::list<Container_Content *>>>> aligned_container_slices_i;
                                              // [8..15] [3..15] => 2[8..15] [3..7]
                                              // map[8][2] --> (Cx[8..15], Cy[8..15]
                                              // map[5][1]--> (Cy[3..7]
                                              // [2..7] [1..7] [5..7] => 3[5..7] 2[2..4] [1..1]
                                              // map[3][3] --> (Cx[5..7], Cy, Cz)
                                              // map[3][2] --> (Cx[2..4], Cy)
                                              // map[1][1] --> (Cy [1..1])
                                              // ingress, egress slices having same width, num
                                              // [w](n) --> ((Ingress set) (Egress set))
 public:
    /** Create @containers_in_group PHV_Container containers of size @w and
     * gress @gress, numbered consecutively starting from @phv_number.  Update
     * @owner->phv_containers to map container number to each new container.
     *
     * Then, create a PHV_MAU_Group with these containers and assigned number
     * @n.
     *
     * Afterwards, @phv_number = @phv_number + @containers_in_group.
     */
    PHV_MAU_Group(
        PHV_MAU_Group_Assignments *owner,
        PHV_Container::PHV_Word w,
        int n,
        int& phv_number,
        std::string asm_encoded,
        PHV_Container::Ingress_Egress gress,
        const int containers_in_group = PHV_Container::Containers::MAX);

    void clear() {
        for (auto &c : phv_containers_i) {
            c->clear();
        }
        phv_containers_i.clear();
        cluster_phv_i.clear();
        aligned_container_slices_i.clear();
    }

    PHV_Container::PHV_Word width()                     { return width_i; }
    int number()                                        { return number_i; }
    void gress(PHV_Container::Ingress_Egress gress_p)   {
        gress_i = gress_p;
        // set gress for all containers in group
        for (auto &c : phv_containers_i) {
            c->gress(gress_i);
        }
    }
    PHV_Container::Ingress_Egress gress()               { return gress_i; }
    std::vector<PHV_Container *>& phv_containers()      { return phv_containers_i; }
    size_t& empty_containers()                          { return empty_containers_i; }
    void inc_empty_containers() {
        if (empty_containers_i < phv_containers_i.size()) {
            empty_containers_i++;
        }
    }
    void dec_empty_containers() {
        if (empty_containers_i > 0) {
            empty_containers_i--;
        }
    }
    PHV_Container *empty_container() {
        // return next empty container in MAU group
        for (auto &c : phv_containers_i) {
            if (c->status() == PHV_Container::Container_status::EMPTY) {
                return c;
            }
        }
        return 0;
    }
    void container_population_density(
        ordered_map<PHV_Container::Container_status, std::pair<int, int>>&);

    std::vector<Cluster_PHV *>& clusters()              { return cluster_phv_i; }
    void create_aligned_container_slices_per_range(std::list<PHV_Container *>&);
    void create_aligned_container_slices(std::list<PHV_Container *>&);
    void create_aligned_container_slices();
    ordered_map<int,
        ordered_map<int,
            std::list<std::list<Container_Content *>>>>&
                aligned_container_slices()              { return aligned_container_slices_i; }

    void sanity_check_container_packs(const std::string&);
    void sanity_check_container_fields_gress(const std::string&);
    void sanity_check_group_containers(const std::string&, bool check_deparsed_no_hole = true);
};  // class PHV_MAU_Group
//
//
class PHV_MAU_Group_Assignments : public Visitor {
 private:
    Cluster_PHV_Requirements &phv_requirements_i;  // reference to parent PHV Requirements
    //
    enum Constants {nibble = 4, num_collections = 8};
    //
    ordered_map<PHV_Container::PHV_Word, int> num_groups_i {
        {PHV_Container::PHV_Word::b32, 4},
        {PHV_Container::PHV_Word::b16, 6},
        {PHV_Container::PHV_Word::b8,  4},
    };
    // PHV
    ordered_map<PHV_Container::PHV_Word, int> phv_number_start_i {
        {PHV_Container::PHV_Word::b32, 0},
        {PHV_Container::PHV_Word::b16, 128},
        {PHV_Container::PHV_Word::b8,  64},
    };
    // T_PHV
    ordered_map<PHV_Container::PHV_Word, int> t_phv_number_start_i {
        {PHV_Container::PHV_Word::b32, 256},
        {PHV_Container::PHV_Word::b16, 320},
        {PHV_Container::PHV_Word::b8,  288},
    };
    // ASM register name prefix
    ordered_map<PHV_Container::PHV_Word, std::string> asm_prefix_i {
        {PHV_Container::PHV_Word::b32, "W"},
        {PHV_Container::PHV_Word::b16, "H"},
        {PHV_Container::PHV_Word::b8,  "B"},
    };
    // Container ranges hard-wired to a specific gress.
    const ordered_map<std::pair<int, int>, PHV_Container::Ingress_Egress> ingress_egress_i {
        {std::make_pair(0, 15), PHV_Container::Ingress_Egress::Ingress_Only},
        {std::make_pair(16, 31), PHV_Container::Ingress_Egress::Egress_Only},
        {std::make_pair(64, 79), PHV_Container::Ingress_Egress::Ingress_Only},
        {std::make_pair(80, 95), PHV_Container::Ingress_Egress::Egress_Only},
        {std::make_pair(128, 143), PHV_Container::Ingress_Egress::Ingress_Only},
        {std::make_pair(144, 159), PHV_Container::Ingress_Egress::Egress_Only},
    };
    //
    std::pair<int, int> phv_container_numbers_i   = {0, 223};
    std::pair<int, int> t_phv_container_numbers_i = {256, 367};
    //
    ordered_map<int, PHV_Container *> phv_containers_i;
                                       // map phv_number to Container
    ordered_map<PHV_Container::PHV_Word, std::vector<PHV_MAU_Group *>> PHV_MAU_i;
                                       // PHV MAU groups comprise 16 same-width containers
                                       // = 4g*32b + 4g*8b + 6g*16b = 64+64+96 = 224 containers
                                       // PHV_MAU_i[width] = vector of groups
    ordered_map<int, ordered_map<PHV_Container::PHV_Word, std::vector<PHV_Container *>>> T_PHV_i;
                                       // TPHV Collections comprise 4*8b + 4*32b + 6+16b containers
                                       //  = 14 containers * 8 collections = 112 containers
                                       // T_PHV_i[collection][width] = vector of containers
    std::list<PHV_MAU_Group *> PHV_groups_i;
                                       // list of groups w/ Empty containers
                                       // used for initial PHV placement
    std::list<PHV_MAU_Group *> T_PHV_groups_i;
                                       // list of groups w/ Empty containers
                                       // used for initial T_PHV placement
    //
    std::list<Cluster_PHV *> clusters_to_be_assigned_i;         // phv non-nibble clusters
    std::list<Cluster_PHV *> clusters_to_be_assigned_nibble_i;  // phv nibble clusters
    std::list<Cluster_PHV *> pov_fields_i;                      // pov clusters
    std::list<Cluster_PHV *> t_phv_fields_i;                    // t_phv non-nibble clusters
    std::list<Cluster_PHV *> t_phv_fields_nibble_i;             // t_phv nibble clusters
    //
    std::list<Cluster_PHV *> substratum_phv_clusters_i;         // allocated substratum phv clusters
    std::list<Cluster_PHV *> substratum_t_phv_clusters_i;       // alloc'd substratum t_phv clusters
    //
    ordered_map<int,
        ordered_map<int,
            std::list<std::list<PHV_MAU_Group::Container_Content *>>>> aligned_container_slices_i;
                                       // for all PHV_MAU_Groups
                                       // sorted map <width increasing, num increasing>
                                       // containing <set of <set of container_packs>>
    //
    ordered_map<int,
        ordered_map<int,
            std::list<std::list<PHV_MAU_Group::Container_Content *>>>> T_PHV_container_slices_i;
                                       // for all T_PHV
                                       // sorted map <width increasing, num increasing>
                                       // containing <set of <set of container_packs>>
    //
    std::vector<PHV_Container *> cohabit_fields_i;
                                       // ranked set of container cohabits
                                       // requests to TP to avoid single-write issue
    //
    void container_no_pack(
        std::list<Cluster_PHV *>& clusters_to_be_assigned,
        std::list<PHV_MAU_Group *>& phv_groups_to_be_filled,
        const char *msg = "",
        bool smallest_container_width = true);
    //
    bool fix_parser_container(
        PHV_Container *c,
        std::list<PHV_MAU_Group *>& phv_groups_to_be_filled);
    PHV_Container* parser_container_no_holes(
        PHV_Container::Ingress_Egress,
        PHV_Container::Container_Content *,
        std::list<PHV_MAU_Group *>&);    // ensure parser fields in containers with no holes
    PHV_MAU_Group* downsize_mau_group(
        PHV_Container::Ingress_Egress gress,
        int width,
        size_t required_containers,
        std::list<PHV_MAU_Group *> phv_groups_to_be_filled);
    //
    void create_aligned_container_slices();
    //
    void consolidate_slices_in_group(
        ordered_map<int,
            ordered_map<int, std::list<std::list<PHV_MAU_Group::Container_Content *>>>>&);

    /** Populate `cohabit_fields` with containers that contain more than one
     * field written to in the MAU pipeline.
     */
    void container_cohabit_summary();

 public:
    //
    PHV_MAU_Group_Assignments(Cluster_PHV_Requirements &phv_r)  // NOLINT(runtime/explicit)
        : phv_requirements_i(phv_r) {}
    //
    void clear();
    //
    Cluster_PHV_Requirements&
        phv_requirements() { return phv_requirements_i; }
    //
    // all PHV MAU groups, all TPHV collections
    //
    std::pair<int, int> phv_container_numbers()           { return phv_container_numbers_i; }
    std::pair<int, int> t_phv_container_numbers()         { return t_phv_container_numbers_i; }
    ordered_map<int, PHV_Container *>& phv_containers()   { return phv_containers_i; }
    void phv_containers(int n, PHV_Container *c);
    PHV_Container *phv_container(int phv_num);
    ordered_map<PHV_Container::PHV_Word, std::vector<PHV_MAU_Group *>>&
        phv_mau_map() { return PHV_MAU_i; }
    ordered_map<int, ordered_map<PHV_Container::PHV_Word, std::vector<PHV_Container *>>>&
        t_phv_map()   { return T_PHV_i; }
    //
    // remaining container slices available
    //
    ordered_map<int, ordered_map<int, std::list<std::list<PHV_MAU_Group::Container_Content *>>>>&
        aligned_container_slices() { return aligned_container_slices_i; }
    ordered_map<int, ordered_map<int, std::list<std::list<PHV_MAU_Group::Container_Content *>>>>&
        T_PHV_container_slices()   { return T_PHV_container_slices_i; }
    //
    // remaining clusters to be processed
    //
    std::list<Cluster_PHV *>& phv_clusters()              { return clusters_to_be_assigned_i; }
    std::list<Cluster_PHV *>& phv_clusters_nibble()       { return
                                                              clusters_to_be_assigned_nibble_i; }
    std::list<Cluster_PHV *>& pov_clusters()              { return pov_fields_i; }
    std::list<Cluster_PHV *>& t_phv_clusters()            { return t_phv_fields_i; }
    std::list<Cluster_PHV *>& t_phv_clusters_nibble()     { return t_phv_fields_nibble_i; }
    //
    std::list<Cluster_PHV *>& substratum_phv_clusters()   { return substratum_phv_clusters_i; }
    std::list<Cluster_PHV *>& substratum_t_phv_clusters() { return substratum_t_phv_clusters_i; }
    //
    // cohabit_fields requests to TP to avoid single-write issue
    //
    std::vector<PHV_Container *>& cohabit_fields()        { return cohabit_fields_i; }

    /** estimate ingress / egress ratio */
    int num_ingress_collections(std::vector<Cluster_PHV *>&);

    /** Build PHV containers and groups. */
    void create_MAU_groups();

    /** Build TPHV containers and collections. */
    void create_TPHV_collections();

    void cluster_PHV_placements();
    void cluster_TPHV_placements();
    void cluster_POV_placements();
    void cluster_PHV_nibble_placements();
    void cluster_T_PHV_nibble_placements();

    /** Updates `substratum_phv_clusters_i` and `substratum_t_phv_clusters_i`
     * with Cluster_PHV_Requirements.cluster_phv_fields (resp.
     * Cluster_PHV_Requirements.t_phv_fields()) that have already been assigned
     * to PHV container groups (resp. TPHV collections).
     */
    void compute_substratum_clusters();

    /** Assign non-owner fields to the containers where their owners were
     * assigned. */
    void field_overlays();

    const IR::Node *apply_visitor(const IR::Node *, const char *name = 0) override;
    //
    bool
    packing_predicates(
        Cluster_PHV *cl,
        std::list<PHV_MAU_Group::Container_Content *>& cc_set,
        bool allow_deparsed_metadata = false);  // default disallow metadata in deparsed container
    //
    // public member
    // container_pack_cohabit also used by
    // Cluster_Slicing : public Visitor .. void Cluster_Slicing::end_apply()
    //
    void container_pack_cohabit(
        std::list<Cluster_PHV *>& clusters_to_be_assigned,
        ordered_map<int,
        ordered_map<int, std::list<std::list<PHV_MAU_Group::Container_Content *>>>>&,
        const char *msg = "",
        bool allow_deparsed_metadata = false);  // default disallow metadata in deparsed container
    //
    bool gress_compatibility(
        PHV_Container::Ingress_Egress gc_gress,
        PHV_Container::Ingress_Egress cl_gress);
    bool metadata_in_deparsed_container(
        Cluster_PHV *cl,
        std::list<PHV_MAU_Group::Container_Content *>& cc_set);
    bool num_containers_bottom_bits(
        Cluster_PHV *cl,
        std::list<PHV_MAU_Group::Container_Content *>& cc_set,
        int num_c);
    std::pair<int, int>
        gress(
            ordered_map<int,
                ordered_map<int,
                    std::list<std::list<PHV_MAU_Group::Container_Content *>>>>&);
    //
    void container_population_density(
        std::map<PHV_Container::PHV_Word,
            std::map<PHV_Container::Container_status,
                std::pair<int, int>>>&,
        bool phv = true);
    //
    bool status(
        std::list<Cluster_PHV *>&,
        const char *msg = "");
    bool status(
        std::list<PHV_MAU_Group *>&,
        const char *msg = "");
    bool status(
        ordered_map<int,
        ordered_map<int,
        std::list<std::list<PHV_MAU_Group::Container_Content *>>>>&,
        const char *msg = "");
    //
    void sanity_check(
        std::pair<int, int>& phv_container_numbers,
        ordered_map<PHV_Container::PHV_Word, int>& phv_number_start,
        const std::string& msg,
        bool t_phv = false);
    void sanity_check_container_avail(const std::string&);
    void sanity_check_container_fields_gress(const std::string&);
    void sanity_check_group_containers(const std::string&);
    void sanity_check_T_PHV_collections(const std::string&);
    void sanity_check_clusters_allocation(
        std::list<Cluster_PHV *>&,
        bool,
        const std::string&);
    void sanity_check_clusters_allocation();
    //
    void statistics(
        std::ostream &out,
        std::map<PHV_Container::PHV_Word,
            std::map<PHV_Container::Container_status,
                std::pair<int, int>>>& c_bits_agg,
        const char *str);
    void statistics(std::ostream &);
    //
};  // class PHV_MAU_Group_Assignments
//
//
std::ostream &operator<<(
    std::ostream &,
    PHV_MAU_Group::Container_Content*);
std::ostream &operator<<(
    std::ostream &,
    std::list<PHV_MAU_Group::Container_Content *>&);
std::ostream &operator<<(
    std::ostream &,
    ordered_set<PHV_MAU_Group::Container_Content *>&);
std::ostream &operator<<(
    std::ostream &,
    std::list<PHV_MAU_Group::Container_Content *>&);
std::ostream &operator<<(
    std::ostream &,
    std::list<std::list<PHV_MAU_Group::Container_Content *>>&);
std::ostream &operator<<(
    std::ostream &,
    ordered_map<int, ordered_map<int, std::list<std::list<PHV_MAU_Group::Container_Content *>>>>&);
std::ostream &operator<<(
    std::ostream &,
    PHV_MAU_Group&);
std::ostream &operator<<(
    std::ostream &,
    PHV_MAU_Group*);
std::ostream &operator<<(
    std::ostream &,
    std::list<PHV_MAU_Group *>&);
std::ostream &operator<<(
    std::ostream &,
    std::vector<PHV_MAU_Group *>&);
std::ostream &operator<<(
    std::ostream &,
    std::vector<PHV_MAU_Group *>*);
std::ostream &operator<<(
    std::ostream &,
    ordered_map<PHV_Container::PHV_Word, std::vector<PHV_Container *>>&);
std::ostream &operator<<(
    std::ostream &out,
    ordered_map<int, ordered_map<PHV_Container::PHV_Word, std::vector<PHV_Container *>>>&);
std::ostream &operator<<(
    std::ostream &out,
    ordered_map<PHV_Container::PHV_Word, std::vector<PHV_MAU_Group *>>&);
std::ostream &operator<<(std::ostream &, PHV_MAU_Group_Assignments&);
//
#endif /* _TOFINO_PHV_CLUSTER_PHV_MAU_H_ */
