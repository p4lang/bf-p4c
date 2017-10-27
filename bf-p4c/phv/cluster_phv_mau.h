#ifndef BF_P4C_PHV_CLUSTER_PHV_MAU_H_
#define BF_P4C_PHV_CLUSTER_PHV_MAU_H_

#include <boost/optional.hpp>
#include <boost/optional/optional_io.hpp>
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/ir/thread_visitor.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/cluster_phv_req.h"
#include "bf-p4c/phv/phv.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/range.h"

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
    class Container_Slice {
     //
     // PHV_MAU_Group Container_Slice represents a container slice of contiguously available bits
     // a container's range of available bits can be partitioned into several slices
     // based on alignment with slices from other containers within the same MAU group
     // cluster of fields mapped to aligned container slices, <number, width>, within a MAU group
     //
     private:
        // range of container bits in this slice
        le_bitrange range_i;
        PHV_Container *container_i;
        //
     public:
        /// Create a @width wide slice of container @c starting at bit position
        /// @lo (little Endian, @lo points to the LSB).
        Container_Slice(int lo, int width, PHV_Container *c);
        Container_Slice(le_bitrange range, PHV_Container *c);

        /// @returns the low bit (little Endian, LSB) of this container slice.
        int lo() const                      { return range_i.lo; }

        /// @returns the high bit (little Endian, MSB) of this container slice.
        int hi() const                      { return range_i.hi; }

        /// @returns the width of this container slice.
        int width() const                   { return range_i.size(); }

        /// @returns the (little Endian) bit range of this container slice.
        le_bitrange range() const           { return range_i; }

        /// @returns the container object that this container slice slices.
        PHV_Container *container() const    { return container_i; }

        void sanity_check_container(const std::string&);
    };

    /** Groups container slices first by slice width and then by number of
     * slices available of that width.  All slices in a group slice the same
     * bit range of different containers.  For example:
     *
     * ```
     * Aligned_Container_Slices_t slices = {
     *     { 8, // bit wide slices
     *       { 2, // slices in this group
     *         { new Container_Slice(0, 8, c1),
     *           new Container_Slice(0, 8, c2) } } } }
     * ```
     *
     * Note that we use std::map and std::list rather than ordered_map in order
     * to maintain a custom sorted order.
     */
    typedef
        std::map<int,
            std::map<int,
                std::list<std::list<Container_Slice *>>>> Aligned_Container_Slices_t;

 private:
    PHV::Type type_i;
    unsigned number_i;                                       // 1..4 [32], 1..6 [16], 1..4 [8]

    /** Gress assignment for all containers in this MAU group, if any.
     *
     * XXX(cole): Containers should be assigned to threads by deparser group,
     * not MAU group.
     */
    boost::optional<gress_t> gress_i;

    size_t empty_containers_i;                          // number of containers that remain Empty
    std::vector<PHV_Container *> phv_containers_i;      // containers in this MAU group
    std::vector<Cluster_PHV *> cluster_phv_i;           // clusters in this MAU group
    Aligned_Container_Slices_t aligned_container_slices_i;
                                          // See comment for the Aligned_Container_Slices_t type.
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
    /** Create an empty MAU group of PHV containers.
     *
     * @param t container type.
     * @param group_number unique number of this MAU group.
     * @param gress whether this group is pinned to ingress/egress or can be assigned to either.
     */
    PHV_MAU_Group(PHV::Type t, unsigned group_number, boost::optional<gress_t> gress)
    : type_i(t), number_i(group_number), gress_i(gress), empty_containers_i(0) { }

    void clear() {
        for (auto &c : phv_containers_i) {
            c->clear();
        }
        phv_containers_i.clear();
        cluster_phv_i.clear();
        aligned_container_slices_i.clear();
    }

    PHV::Type type()                                    { return type_i; }
    PHV::Size width()                                   { return type_i.size(); }
    unsigned number()                                   { return number_i; }

    /// Pin gress of this group.
    void gress(gress_t gress_p)   {
        gress_i = gress_p;
        // XXX(cole): guarantee this at the container level, not group level.
        // set gress for all containers in group
        for (auto &c : phv_containers_i)
            c->gress(gress_p);
    }
    boost::optional<gress_t> gress()                    { return gress_i; }

    std::vector<PHV_Container *>& phv_containers()             { return phv_containers_i; }
    const std::vector<PHV_Container *>& phv_containers() const { return phv_containers_i; }

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

    void add_empty_container(PHV_Container *c) {
        phv_containers_i.push_back(c);
        empty_containers_i++; }

    PHV_Container *empty_container() {
        // return next empty container in MAU group
        for (auto &c : phv_containers_i) {
            if (c->status() == PHV_Container::Container_status::EMPTY) {
                return c;
            }
        }
        return nullptr;
    }
    void container_population_density(
        ordered_map<PHV_Container::Container_status, std::pair<int, int>>&);

    std::vector<Cluster_PHV *>& clusters()              { return cluster_phv_i; }
    void create_aligned_container_slices_per_range(std::list<PHV_Container *>&);
    void create_aligned_container_slices(std::list<PHV_Container *>&);
    void create_aligned_container_slices();
    Aligned_Container_Slices_t& aligned_container_slices() { return aligned_container_slices_i; }

    void sanity_check_container_packs(const std::string&);
    void sanity_check_container_fields_gress(const std::string&);
    void sanity_check_group_containers(const std::string&, bool check_deparsed_no_hole = true);

    friend class ActionPhvConstraints;
};  // class PHV_MAU_Group
//
//
class PHV_MAU_Group_Assignments : public Visitor {
 public:
    //
    enum Constants {nibble = 4, num_collections = 8, phv_mau_group_size = 16};

 private:
    Cluster_PHV_Requirements &phv_requirements_i;  // reference to parent PHV Requirements
    ActionPhvConstraints &action_constraints;      // reference to action constraints
    ordered_map<unsigned, PHV_Container *> phv_containers_i;
                                       // map phv_number to Container
    ordered_map<PHV::Size, std::vector<PHV_MAU_Group *>> PHV_MAU_i;
                                       // PHV MAU groups comprise 16 same-width containers
                                       // = 4g*32b + 4g*8b + 6g*16b = 64+64+96 = 224 containers
                                       // PHV_MAU_i[width] = vector of groups
    ordered_map<unsigned, ordered_map<PHV::Size, std::vector<PHV_Container *>>> T_PHV_i;
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
    PHV_MAU_Group::Aligned_Container_Slices_t aligned_container_slices_i;
                                       // for all PHV_MAU_Groups
                                       // sorted map <width increasing, num increasing>
                                       // containing <set of <set of container_packs>>
    //
    PHV_MAU_Group::Aligned_Container_Slices_t T_PHV_container_slices_i;
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

    size_t max_empty_containers(
        boost::optional<gress_t> gress,
        int width,
        std::list<PHV_MAU_Group *> phv_groups_to_be_filled);
    PHV_MAU_Group* upsize_mau_group(
        gress_t gress,
        int width,
        size_t required_containers,
        std::list<PHV_MAU_Group *> phv_groups_to_be_filled);
    PHV_MAU_Group* downsize_mau_group(
        gress_t gress,
        int width,
        size_t required_containers,
        std::list<PHV_MAU_Group *> phv_groups_to_be_filled);
    //
    void create_aligned_container_slices();
    //
    void consolidate_slices_in_group(
        ordered_map<int,
            ordered_map<int, std::list<std::list<PHV_MAU_Group::Container_Slice *>>>>&);

    /** Populate `cohabit_fields` with containers that contain more than one
     * field written to in the MAU pipeline.
     */
    void container_cohabit_summary();

 public:
    //
    PHV_MAU_Group_Assignments(Cluster_PHV_Requirements &phv_r,
                              ActionPhvConstraints &act_r)  // NOLINT(runtime/explicit)
        : phv_requirements_i(phv_r), action_constraints(act_r) {}
    //
    void clear();
    Cluster_PHV_Requirements& phv_requirements() { return phv_requirements_i; }

    // all PHV MAU groups, all TPHV collections
    const ordered_map<unsigned, PHV_Container *>& phv_containers() const {
        return phv_containers_i;
    }

    /// Map a device-provided container ID (see phv_spec.h) to a PHV_Container
    /// (aux. information for PHV allocation).
    void phv_containers(unsigned container_id, PHV_Container *c);

    /// Look up a PHV_Container given a device-provided container ID (see phv_spec.h).
    const PHV_Container *phv_container(unsigned container_id) const;

    const ordered_map<PHV::Size, std::vector<PHV_MAU_Group *>>&
        phv_mau_map() const { return PHV_MAU_i; }
    const ordered_map<unsigned, ordered_map<PHV::Size, std::vector<PHV_Container *>>>&
        t_phv_map() const { return T_PHV_i; }
    //
    // remaining container slices available
    //
    PHV_MAU_Group::Aligned_Container_Slices_t&
        aligned_container_slices() { return aligned_container_slices_i; }
    PHV_MAU_Group::Aligned_Container_Slices_t&
        T_PHV_container_slices()   { return T_PHV_container_slices_i; }
    //
    // remaining clusters to be processed
    //
    std::list<Cluster_PHV *>& phv_clusters()          { return clusters_to_be_assigned_i; }
    std::list<Cluster_PHV *>& phv_clusters_nibble()   { return clusters_to_be_assigned_nibble_i; }
    std::list<Cluster_PHV *>& pov_clusters()          { return pov_fields_i; }
    std::list<Cluster_PHV *>& t_phv_clusters()        { return t_phv_fields_i; }
    std::list<Cluster_PHV *>& t_phv_clusters_nibble() { return t_phv_fields_nibble_i; }

    const std::list<Cluster_PHV *>& phv_clusters() const {
        return clusters_to_be_assigned_i; }
    const std::list<Cluster_PHV *>& phv_clusters_nibble() const {
        return clusters_to_be_assigned_nibble_i; }
    const std::list<Cluster_PHV *>& pov_clusters() const {
        return pov_fields_i; }
    const std::list<Cluster_PHV *>& t_phv_clusters() const {
        return t_phv_fields_i; }
    const std::list<Cluster_PHV *>& t_phv_clusters_nibble() const {
        return t_phv_fields_nibble_i; }
    //
    std::list<Cluster_PHV *>& substratum_phv_clusters()   { return substratum_phv_clusters_i; }
    std::list<Cluster_PHV *>& substratum_t_phv_clusters() { return substratum_t_phv_clusters_i; }
    //
    // cohabit_fields requests to TP to avoid single-write issue
    //
    std::vector<PHV_Container *>& cohabit_fields()        { return cohabit_fields_i; }

    /** estimate ingress / egress ratio */
    unsigned num_ingress_collections(std::vector<Cluster_PHV *>&);

    /** Build PHV containers and groups. */
    void create_MAU_groups();

    /** Build TPHV containers and collections. */
    void create_TPHV_collections();

    /** PHV allocation estimates and pins TPHV collections to threads based on
     * estimated requirements.
     *
     * @returns the thread assignment for TPHV collection @collection_num.
     */
    gress_t TPHV_collection_gress(unsigned collection_num);

    void cluster_PHV_placements();
    void check_action_constraints();
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
    satisfies_phv_alignment(
        Cluster_PHV *cl,
        int lo,
        int hi);
    bool
    match_cluster_to_cc_set(
        Cluster_PHV *cl,
        std::list<PHV_MAU_Group::Container_Slice *>& cc_set);
    bool
    packing_predicates(
        Cluster_PHV *cl,
        std::list<PHV_MAU_Group::Container_Slice *>& cc_set);
    //
    // public member
    // container_pack_cohabit also used by
    // Cluster_Slicing : public Visitor .. void Cluster_Slicing::end_apply()
    //
    void container_pack_cohabit(
        std::list<Cluster_PHV *>& clusters_to_be_assigned,
        PHV_MAU_Group::Aligned_Container_Slices_t&,
        const char *msg = "");
    //
    bool canonicalize_cc_set(
        Cluster_PHV *cl,
        std::list<PHV_MAU_Group::Container_Slice *>& cc_set);
    bool num_containers_bottom_bits(
        Cluster_PHV *cl,
        std::list<PHV_MAU_Group::Container_Slice *>& cc_set,
        int num_c);
    std::pair<int, int>
        gress(PHV_MAU_Group::Aligned_Container_Slices_t&);
    //
    void container_population_density(
        std::map<PHV::Size,
            std::map<PHV_Container::Container_status,
                std::pair<int, int>>>&,
        bool phv = true);

    bool status(std::list<Cluster_PHV *>&, const char *msg = "");
    bool status(
        std::list<PHV_MAU_Group *>&,
        const char *msg = "");
    bool status(
        PHV_MAU_Group::Aligned_Container_Slices_t&,
        const char *msg = "");
    //
    void sanity_check(
        std::pair<int, int>& phv_container_numbers,
        ordered_map<PHV::Size, int>& phv_number_start,
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
        std::map<PHV::Size,
            std::map<PHV_Container::Container_status,
                std::pair<int, int>>>& c_bits_agg,
        const char *str);
    void statistics(std::ostream &);

    /** Log new PHV_Container::Container_Content slices allocated since
     * the last time this method was called.
     *
     * @param msg title log message.
     * @param clear report all allocated slices so far.
     */
    void dump_new_placements(const std::string& msg, bool clear = false) const;
};  // class PHV_MAU_Group_Assignments
//
//
std::ostream &operator<<(
    std::ostream &,
    PHV_MAU_Group::Container_Slice*);
std::ostream &operator<<(
    std::ostream &,
    std::list<PHV_MAU_Group::Container_Slice *>&);
std::ostream &operator<<(
    std::ostream &,
    ordered_set<PHV_MAU_Group::Container_Slice *>&);
std::ostream &operator<<(
    std::ostream &,
    std::list<PHV_MAU_Group::Container_Slice *>&);
std::ostream &operator<<(
    std::ostream &,
    std::list<std::list<PHV_MAU_Group::Container_Slice *>>&);
std::ostream &operator<<(
    std::ostream &,
    PHV_MAU_Group::Aligned_Container_Slices_t&);
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
    ordered_map<PHV::Size, std::vector<PHV_Container *>>&);
std::ostream &operator<<(
    std::ostream &out,
    ordered_map<unsigned, ordered_map<PHV::Size, std::vector<PHV_Container *>>>&);
std::ostream &operator<<(
    std::ostream &out,
    ordered_map<PHV::Size, std::vector<PHV_MAU_Group *>>&);
std::ostream &operator<<(std::ostream &, PHV_MAU_Group_Assignments&);
//
#endif /* BF_P4C_PHV_CLUSTER_PHV_MAU_H_ */
