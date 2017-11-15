#include "bf-p4c/phv/cluster_phv_mau.h"
#include <boost/format.hpp>
#include <boost/range/adaptor/reversed.hpp>
#include <cstdlib>
#include "bf-p4c/device.h"
#include "bf-p4c/phv/cluster_phv_operations.h"
#include "bf-p4c/phv/action_phv_constraints.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/phv_spec.h"
#include "lib/log.h"
#include "lib/stringref.h"

//***********************************************************************************
//
// PHV_MAU_Group::Container_Slice::Container_Slice constructor
//
//***********************************************************************************

PHV_MAU_Group::Container_Slice::Container_Slice(le_bitrange range, PHV_Container *c)
        : range_i(range), container_i(c) {
    BUG_CHECK(container_i,
        "*****PHV_MAU_Group::Container_Slice constructor called with null container ptr*****");
    container_i->sanity_check_container_ranges("PHV_MAU_Group::Container_Slice constructor");
}

PHV_MAU_Group::Container_Slice::Container_Slice(int lo, int width, PHV_Container *c)
    : Container_Slice(le_bitrange(StartLen(lo, width)), c) { }

//***********************************************************************************
//
// PHV_MAU_Group::create_aligned_container_slices
//
// slice partially filled containers
// to obtain larger number of sub-containers with reduced width
//
// (a) within MAU group, aligned container slices
//     (i)  honor alignment across members of cluster
//     (ii) increase number (albeit decreased width)
//
// (b) sort aligned slices to match clusters fast with available Containers <w, n>
//     slicing algorithm
//     (i)   can produce several <container_packs> for given w
//     (ii)  a container can be member of several <container_packs>
//     (iii) guarantees that for given w, given n only one <container_pack> in G
//           as every slice reduces n by 1 from previous slicing operation
//
//     container packs sorted with increasing w, increasing n
//     map[width][number]--> <G:container_packs>
//
//***********************************************************************************


void PHV_MAU_Group::create_aligned_container_slices_per_range(
    std::list<PHV_Container *>& container_list) {
    //
    // larger n in <n:w> possible only when 2 or more containers
    // create aligned slices only when all container range hi's match
    // else no alignment, consider separate containers with constituent slices
    // singleton containers with available space useful for horizontal packing where possible,
    // e.g., POV bit/header_stack bit array
    //
    // alignment calculations use ranges().begin() for each container
    // to consider other ranges
    // successively erase ranges().begin() & call this routine
    //
    /* Each container maintains a map of its free bit ranges.  For each
     * container in `container_list`, check whether the hi bit of the first
     * free range is the same.  If so, align on that hi bit.
     */
    boost::optional<int> hi = boost::none;
    for (PHV_Container *c : container_list) {
        int range_hi = c->ranges().begin()->second;
        if (!hi)
            hi = range_hi;
        if (*hi != range_hi)
            return; }

    /* Given that each container contains a range of free bits ending at `*hi`,
     * do the following:
     *  - Find the lo bit of the smallest free range.
     *  - Create new slices in each container from lo..hi.
     *  - Remove any containers with no more free bits---guaranteed to be at least one removed.
     *  - Set hi = lo - 1.
     * Repeat until no free bits remain in the first range of any container.
     */
     int window_hi = *hi;
     while (container_list.size() > 0) {
         int window_lo = 0;
         for (PHV_Container* c : container_list)
            window_lo = std::max(window_lo, c->ranges().begin()->first);

         int width = window_hi - window_lo + 1;
         int num_slices = container_list.size();
         auto* cc_set = new std::list<Container_Slice *>;

         // Create a new slice for each container, and remove containers that have no remaining
         // free bits.
         for (auto it = container_list.begin(); it != container_list.end(); /* empty */) {
             PHV_Container* c = *it;
             cc_set->push_back(new Container_Slice(window_lo, width, c));
             if (c->ranges().begin()->first == window_lo) {
                 // next time around c's next range selected
                 c->ranges().erase(c->ranges().begin());
                 it = container_list.erase(it);
             } else {
                 it++; } }

         // Add the new slices to the list of slice groups.
         aligned_container_slices_i[width][num_slices].emplace_back(std::move(*cc_set));

         // Update window.
         window_hi = window_lo - 1; }
}


void PHV_MAU_Group::create_aligned_container_slices() {
    //
    // Ingress Containers and Egress Containers cannot be shared
    // split packable containers into Ingress_Only list and Egress_Only list
    //
    aligned_container_slices_i.clear();

    std::list<PHV_Container *> ingress_container_list;
    std::list<PHV_Container *> egress_container_list;
    std::list<PHV_Container *> vacant_container_list;

    for (PHV_Container *c : phv_containers_i) {
        c->create_ranges();
        if (c->status() == PHV_Container::Container_status::PARTIAL) {
            BUG_CHECK(c->gress(), "Container partially allocated but gress not set");
            switch (*c->gress()) {
              case INGRESS:
                ingress_container_list.push_back(c);
                break;
              case EGRESS:
                egress_container_list.push_back(c);
                break; }
        } else if (c->status() == PHV_Container::Container_status::EMPTY) {
            vacant_container_list.push_back(c); } }

    create_aligned_container_slices(ingress_container_list);
    create_aligned_container_slices(egress_container_list);
    if (vacant_container_list.size())
        create_aligned_container_slices_per_range(vacant_container_list);

    // create aligned slices would have clobbered ranges[] in containers
    for (PHV_Container *c : phv_containers_i)
        c->create_ranges();

    sanity_check_container_packs("PHV_MAU_Group::create_aligned_container_slices()..");
}


void PHV_MAU_Group::create_aligned_container_slices(
    std::list<PHV_Container *>& container_list) {
    while (container_list.size()) {
        ordered_map<int, std::list<PHV_Container *>> container_hi_s;
        container_hi_s.clear();
        for (PHV_Container* c : container_list)
           container_hi_s[c->ranges().begin()->second].push_back(c);

        for (auto &entry : container_hi_s) {
            LOG4("\t~~~this iteration, considering containers~~~");
            LOG4(entry.second);
            create_aligned_container_slices_per_range(entry.second);
            assert(entry.second.size() == 0); }

        LOG4("\t~~~create_aligned_slices: PHV Container Packs Avail~~~");
        LOG4(aligned_container_slices_i);

        // Clear containers with no remaining free bit ranges.
        container_list.remove_if([](PHV_Container *c) { return c->ranges().size() == 0; }); }
}

void
PHV_MAU_Group::container_population_density(
    ordered_map<PHV_Container::Container_status, std::pair<int, int>>& c_bits) {
    //
    c_bits.clear();
    for (PHV_Container *c : phv_containers_i) {
        c_bits[c->status()].first++;
        c_bits[c->status()].second += int(c->width()) - c->avail_bits();  // populated bits
    }
}  // container_population_density

//
//***********************************************************************************
//
// PHV_MAU_Group_Assignments::apply_visitor()
//
//***********************************************************************************


const IR::Node *
PHV_MAU_Group_Assignments::apply_visitor(const IR::Node *node, const char *) {
    LOG1("--- BEGIN PHV ALLOCATION ----------------------------------------------------");
    LOG2("");
    LOG2("Dumping PHV allocation after each intermediate round of allocation.  Each round");
    LOG2("assigns as many clusters as possible under the given constraints.");
    LOG2("");
    LOG2("Format: CONTAINER(gress)[slice of container]<--field_name[slice of field]");
    LOG2("where slices are optional and their lack implies all bits have been assigned.");
    LOG2("");

    if (!phv_requirements_i.cluster_phv_fields().size())
        LOG4("**********PHV_MAU_Group_Assignments apply_visitor w/ 0 Requirements***********");

    //
    // create PHV Group Assignments from PHV Requirements
    //
    clear();                            // clear all PHV, T_PHV container assignments if any
                                        // used when PHV_MAU_Group_Assignments::apply_visitor()
                                        // called multiple times
    create_MAU_groups();
    create_TPHV_collections();

    cluster_PHV_placements();           // PHV placements

    cluster_TPHV_placements();          // consider TPHVoverflow => PHV before POV placements

    cluster_POV_placements();           // POV placements after TPHVoverflow => PHV

    cluster_PHV_nibble_placements();    // nibble cluster PHV placements

    cluster_T_PHV_nibble_placements();  // nibble T_PHV placements

    field_overlays();                   // place non-owner fields in containers "on top of" their
                                        // owners, i.e. overlaid starting at the same lo bit

    compute_substratum_clusters();      // write non-POV clusters that have already been placed to
                                        // substratum_phv_clusters and substratum_t_phv_clusters

    container_cohabit_summary();        // summarize recommendations to TP by storing containers
                                        // in cohabit_fields that contain more than one field which
                                        // is written to in the MAU pipeline

    sanity_check_group_containers("PHV_MAU_Group_Assignments::PHV_MAU_Group_Assignments()..");
    LOG4(*this);
    return node;
}

void
PHV_MAU_Group_Assignments::clear() {
    //
    // PHV_MAU_i[width] = vector of groups
    for (auto &x : PHV_MAU_i) {
        for (auto &y : x.second) {
            y->clear();
        }
    }
    // T_PHV_i[collection][width] = vector of containers
    for (auto &x : T_PHV_i) {
        for (auto &y : x.second) {
            for (auto &z : y.second) {
                z->clear();
            }
        }
    }
    //
    PHV_groups_i.clear();
    T_PHV_groups_i.clear();
    //
    clusters_to_be_assigned_i.clear();
    clusters_to_be_assigned_nibble_i.clear();
    pov_fields_i.clear();
    t_phv_fields_i.clear();
    t_phv_fields_nibble_i.clear();
    //
    aligned_container_slices_i.clear();
    T_PHV_container_slices_i.clear();
    //
    cohabit_fields_i.clear();
}

void PHV_MAU_Group_Assignments::phv_containers(unsigned container_id, PHV_Container *c) {
    BUG_CHECK(c, "NULL container");
    phv_containers_i[container_id] = c;
}

const PHV_Container * PHV_MAU_Group_Assignments::phv_container(unsigned container_id) const {
    return phv_containers_i.at(container_id);
}

unsigned
PHV_MAU_Group_Assignments::num_ingress_collections(std::vector<Cluster_PHV *>& cluster_vec) {
    unsigned ingress_and_egress = 0;
    unsigned ingress = 0;

    for (Cluster_PHV *cl : cluster_vec) {  // possible to have 0 fields alloc to TPHV
        if (cl->exact_containers()) {
            ingress_and_egress++;
            if (cl->gress() == INGRESS)
                ingress++; } }

    int ingress_collections = Constants::num_collections / 2;
    if (ingress_and_egress) {
        int value = (ingress * Constants::num_collections) / ingress_and_egress
                      + ((ingress * Constants::num_collections) % ingress_and_egress ? 1 : 0);
        if (std::abs(ingress_collections - value) > 1)
            ingress_collections = value; }

    LOG4("*****PHV_MAU_Group_Assignments: sanity_INFO*****....."
        << ".....ingress = " << ingress << ", ingress_and_egress = " << ingress_and_egress
        << ", ingress_collections = " << ingress_collections);

    BUG_CHECK(0 <= ingress_collections, "Negative number of ingress collections");
    return unsigned(ingress_collections);
}

void PHV_MAU_Group_Assignments::create_MAU_groups() {
    const PhvSpec& phvSpec = Device::phvSpec();
    // For each kind of PHV group...
    for (const PHV::Type &t : Device::phvSpec().containerTypes()) {
        // Create the number of groups of that kind...
        unsigned group_num = 0;
        for (auto group : Device::phvSpec().mauGroups(t)) {
            // Is this group pinned to ingress/egress or can be assigned to either?
            boost::optional<gress_t> gress;
            bool ingressOnly = !(group & phvSpec.ingressOnly()).empty();
            bool egressOnly = !(group & phvSpec.egressOnly()).empty();
            if (ingressOnly && egressOnly)
                P4C_UNIMPLEMENTED("Cannot mix ingress-only and egress-only "
                                  "containers in MAU groups.");
            else if (ingressOnly)
                gress = INGRESS;
            else if (egressOnly)
                gress = EGRESS;
            else
                gress = boost::none;

            // Create empty group
            PHV_MAU_Group *g = new PHV_MAU_Group(t, group_num++, gress);

            // Add containers to group
            for (auto container_id : group) {
                // TODO: Do containers really need a back pointer to their
                // enclosing group?
                PHV_Container *c = new PHV_Container(g, t.size(), container_id, gress);
                g->add_empty_container(c);

                // TODO: Does this really need a separate map of containers?
                this->phv_containers(container_id, c); }

            PHV_MAU_i[g->width()].push_back(g);
            PHV_groups_i.push_front(g); } }
}

gress_t PHV_MAU_Group_Assignments::TPHV_collection_gress(unsigned collection_num) {
    unsigned ingress_collections = num_ingress_collections(phv_requirements_i.t_phv_fields());
    return (collection_num < ingress_collections) ? INGRESS : EGRESS;
}

void PHV_MAU_Group_Assignments::create_TPHV_collections() {
    // create TPHV collections
    // T_PHV Collection = 4*32b, 4*8b, 6*16b container groups
    // any TPHV collection can be Ingress_Only, Egress_Only but not both
    // set gress for collection based on ingress / egress partition estimate
    const PhvSpec& phvSpec = Device::phvSpec();
    int collection_num = 0;
    for (auto collection : phvSpec.tagalongGroups()) {
        // TODO: We seem to be pre-pinning TPHV collections to threads based.  Why?
        gress_t gress = TPHV_collection_gress(collection_num);

        // Each PHV_MAU_Group holds containers of the same size.  Hence, TPHV
        // collections are split into three groups, by size.
        ordered_map<PHV::Size, PHV_MAU_Group *> groups_by_size;
        for (PHV::Size size : { PHV::Size::b8, PHV::Size::b16, PHV::Size::b32 })
            groups_by_size[size] =
                new PHV_MAU_Group(PHV::Type(PHV::Kind::tagalong, size), collection_num, gress);

        // Add containers to groups by size
        for (auto container_id : collection) {
            // TODO: see TODOs for mau group creation
            PHV::Size size = phvSpec.idToContainer(container_id).type().size();
            PHV_Container *c =
                new PHV_Container(groups_by_size.at(size), size, container_id, gress);
            groups_by_size.at(size)->add_empty_container(c);
            this->phv_containers(container_id, c); }

        for (PHV::Size size : { PHV::Size::b8, PHV::Size::b16, PHV::Size::b32 }) {
            for (PHV_Container* c : groups_by_size.at(size)->phv_containers())
                T_PHV_i[collection_num][size].push_back(c);
            T_PHV_groups_i.push_front(groups_by_size.at(size)); }

        ++collection_num; }

    sanity_check_T_PHV_collections("PHV_MAU_Group_Assignments::PHV_MAU_Group_Assignments().....");
}

void PHV_MAU_Group_Assignments::compute_substratum_clusters() {
    //
    // substratum clusters are computed by noting the incoming clusters from phv_requirements
    // and then subtracting clusters that remain to be assigned
    //
    // pov clusters cannot overlay or be overlayed
    //
    substratum_phv_clusters_i.clear();
    substratum_t_phv_clusters_i.clear();
    //
    ordered_set<Cluster_PHV *> all_phv;
    for (auto &cl : phv_requirements_i.cluster_phv_fields()) {
        all_phv.insert(cl);
    }
    ordered_set<Cluster_PHV *> to_be_assigned_phv;
    for (auto &cl : clusters_to_be_assigned_i) {
        to_be_assigned_phv.insert(cl);
    }
    for (auto &cl : clusters_to_be_assigned_nibble_i) {
        to_be_assigned_phv.insert(cl);
    }
    all_phv -= to_be_assigned_phv;
    substratum_phv_clusters_i.assign(all_phv.begin(), all_phv.end());
    //
    ordered_set<Cluster_PHV *> all_t_phv;
    for (auto &cl : phv_requirements_i.t_phv_fields()) {
        all_t_phv.insert(cl);
    }
    ordered_set<Cluster_PHV *> to_be_assigned_t_phv;
    for (auto &cl : t_phv_fields_i) {
        to_be_assigned_t_phv.insert(cl);
    }
    for (auto &cl : t_phv_fields_nibble_i) {
        to_be_assigned_t_phv.insert(cl);
    }
    all_t_phv -= to_be_assigned_t_phv;
    substratum_t_phv_clusters_i.assign(all_t_phv.begin(), all_t_phv.end());
    //
    sanity_check_clusters_allocation();
    //
}  // compute_substratum_clusters


void PHV_MAU_Group_Assignments::dump_new_placements(const std::string& msg, bool clear) const {
    // All containers, sorted by type.
    static std::vector<PHV_Container *> all_containers;
    static ordered_set<PHV_Container::Container_Content *> allocated;

    if (!LOGGING(3))
        return;

    // Get all containers once.
    if (all_containers.size() == 0) {
        std::set<PHV_Container *> all_containers_set;
        for (auto *g : PHV_groups_i) {
            for (auto *c : g->phv_containers()) {
                all_containers_set.insert(c); } }
        for (auto &by_collection : T_PHV_i) {
            for (auto &by_width : by_collection.second) {
                for (auto *c : by_width.second) {
                    all_containers_set.insert(c); } } }
        all_containers.insert(
            all_containers.begin(), all_containers_set.begin(), all_containers_set.end());
        std::sort(all_containers.begin(), all_containers.end()); }

    if (clear)
        allocated.clear();

    if (clear)
        LOG3("--- ALL PHV ALLOCATION (for all rounds so far): " << msg);
    else
        LOG3("--- PHV ALLOCATION (new in this round): " << msg);
    LOG3("");

    std::map<boost::optional<gress_t>,
        std::map<PHV::Type,
            std::map<PHV_Container::Container_status,
                ordered_set<PHV_Container *>>>> alloc_status;

    // Print field allocation.
    const PhvSpec& phvSpec = Device::phvSpec();
    for (auto *c : all_containers) {
        PHV::Type type = phvSpec.idToContainer(c->container_id()).type();
        alloc_status[c->gress()][type][c->status()].insert(c);
        if (c->fields_in_container().size() == 0)
            continue;
        for (auto &field_ccs : c->fields_in_container()) {
            for (auto* cc : field_ccs.second) {
                if (allocated.count(cc))
                    continue;
                allocated.insert(cc);
                std::stringstream gress_ss;
                std::stringstream container_slice_ss;
                std::stringstream field_slice_ss;
                std::stringstream field_info_ss;
                std::stringstream field_name_ss;
                gress_ss << c->gress();
                field_info_ss << cc->field();
                field_name_ss << cc->field()->name;
                // Print container slice info if field only partially fills container.
                if (cc->width() != int(c->width()))
                    container_slice_ss << "[" << cc->lo() << ":" << cc->hi() << "]";
                // Print field slice info if field is partially allocated to container.
                if (cc->width() != cc->field()->size)
                    field_slice_ss << "[" << cc->field_bit_lo() << " : " <<
                                             cc->field_bit_hi() << "]";
                LOG3(boost::format("%1%(%2%)%3% %|25t| <-- %|30t|%4%%5%")
                    % c->toString()
                    % gress_ss.str()
                    % container_slice_ss.str()
                    % (LOGGING(4) ? field_info_ss.str() : field_name_ss.str())
                    % field_slice_ss.str()); } } }

    // Print container status.
    std::stringstream ss;
    bool first_by_gress = true;
    auto gresses = std::list<boost::optional<gress_t>>({INGRESS, EGRESS, boost::none});
    auto statuses = {PHV_Container::EMPTY, PHV_Container::PARTIAL, PHV_Container::FULL};
    for (auto gress : gresses) {
        first_by_gress = true;
        for (auto status : statuses) {
            for (auto type : phvSpec.containerTypes()) {
                if (alloc_status[gress][type][status].size() == 0)
                    continue;
                std::stringstream ss_gress;
                std::string s_status;
                ss_gress << gress;
                switch (status) {
                  case PHV_Container::EMPTY: s_status = "EMPTY"; break;
                  case PHV_Container::PARTIAL: s_status = "PARTIAL"; break;
                  case PHV_Container::FULL: s_status = "FULL"; break; }
                ss << boost::format("%1% %|10t| %3% %|20t| %2% %|30t| %4%\n")
                      % (first_by_gress  ? ss_gress.str() : "")
                      % type.toString()
                      % s_status
                      % alloc_status[gress][type][status].size();
                first_by_gress = false; } } }

    LOG3("");
    LOG3("CONTAINER STATUS (after allocation so far):");
    LOG3(boost::format("%1% %|10t| %2% %|20t| %3% %|30t| %4%\n")
        % "GRESS" % "TYPE" % "STATUS" % "COUNT");
    LOG3(ss.str());
    LOG3("");
}

void PHV_MAU_Group_Assignments::cluster_PHV_placements() {
    //
    // cluster placement in containers conforming to MAU group constraints
    //
    for (auto &cl : phv_requirements_i.cluster_phv_fields()) {
        //
        // nibble clusters separated from others -- lower priority placement after TPHVoverflow, POV
        // it is beneficial to include contrained nibbles also, e.g., learning "bottom bits"
        // as packing smaller widths before larger widths restricts latter accommodation
        //
        if (cl->max_width() <= Constants::nibble)
            clusters_to_be_assigned_nibble_i.push_front(cl);
        else
            clusters_to_be_assigned_i.push_front(cl); }

    // place fields into their natural container sizes
    container_no_pack(clusters_to_be_assigned_i, PHV_groups_i, "PHV_smallest_container_width");

    if (clusters_to_be_assigned_i.size()) {
        //
        // attempt placement without smallest_container_width
        // e.g., empty 32b, 16b containers for 8b clusters
        //
        container_no_pack(clusters_to_be_assigned_i, PHV_groups_i,
            "PHV_any_container_width", false /* use any container width */);

        // Check allocation for action induced constraints
        check_action_constraints();

        if (clusters_to_be_assigned_i.size()) {
            // If there are any remaining unallocated clusters, try assigning them
            // to container groups that are partially occupied.  This includes
            // packing fields from different clusters in the same container, if the
            // appropriate constraints are satisfied.
            container_pack_cohabit(clusters_to_be_assigned_i, aligned_container_slices_i, "PHV");

            if (clusters_to_be_assigned_i.size())
                LOG4("********** PHV placement + packing ***** DID NOT FIT ***** **********"); }
    } else {
        check_action_constraints();
    }
}

void PHV_MAU_Group_Assignments::check_action_constraints() {
    // Check allocation for action induced constraints
    for (auto entry : phv_containers()) {
        if (entry.second->status() != PHV_Container::Container_status::EMPTY) {
            std::vector<ActionPhvConstraints::PackingCandidate> existing_packing;
            if (entry.second->fields_in_container().size() < 2)
                continue;
            std::string packing_string;
            for (auto field : entry.second->fields_in_container()) {
                packing_string.append(field.first->name);
                packing_string.append(" ");
                for (auto cc : field.second)
                    existing_packing.push_back(ActionPhvConstraints::PackingCandidate(field.first,
                                le_bitrange(FromTo(cc->field_bit_lo(), cc->field_bit_hi()))));
                if (existing_packing.size() >= 2) {
                    unsigned error_code = action_constraints.can_cohabit(existing_packing);
                    std::stringstream msg;
                    if (error_code != ActionAnalysis::ContainerAction::NO_PROBLEM)
                        msg << entry.first;
                    if (error_code == ActionAnalysis::ContainerAction::PARTIAL_OVERWRITE) {
                        ::error("Only part of the container %1% with fields %2% is written.",
                                msg.str(), packing_string);
                    } else if (error_code ==
                            ActionAnalysis::ContainerAction::MULTIPLE_CONTAINER_ACTIONS) {
                        ::error("Set and non-set operations cannot be performed in the same"
                                "action for container %1%", msg.str());
                    } else if (error_code == ActionAnalysis::ContainerAction::
                            TOO_MANY_PHV_SOURCES) {
                        ::error("Operation on container %1% with fields %2% uses more than two "
                                "source containers.", msg.str(), packing_string);
                    } else if (error_code == ActionAnalysis::ContainerAction::PHV_AND_ACTION_DATA) {
                        ::error("Action writes fields using the same assignment type but different "
                                "source operands (both action parameter and phv) for container %1%",
                                msg.str()); } } } } }
}

void PHV_MAU_Group_Assignments::cluster_POV_placements() {
    //
    // POV fields in PHV containers
    //
    pov_fields_i.assign(
        phv_requirements_i.pov_fields().begin(),
        phv_requirements_i.pov_fields().end());
    //
    // place POVs: bit occupies whole container => reduces opportunities for TPHV overflow into PHV
    // pack POVs horizontally
    // avoid initial placement
    // initial placement with POV_any_container_width gobbles large containers
    // initial placement with POV_smallest_container_width gobbles byte sized containers
    //
    // container_no_pack(
    //   pov_fields_i,
    //   PHV_groups_i,
    //   "POV_any_container_width",
    //   false/*smallest_container_width*/);
    // container_no_pack(pov_fields_i, PHV_groups_i, "POV_smallest_container_width");
    //
    if (pov_fields_i.size()) {
        //
        // pack remaining clusters to partially filled containers
        //
        container_pack_cohabit(pov_fields_i, aligned_container_slices_i, "POV");
        //
        if (pov_fields_i.size())
            LOG4("********** POV packing ***** DID NOT FIT ***** **********");
    }
}  // PHV_MAU_Group_Assignments::cluster_POV_placements

void
PHV_MAU_Group_Assignments::cluster_TPHV_placements() {
    //
    // T_PHV fields allocation
    // initial placement as in Clusters & PHV placement constraints
    // later pack in containers conforming to T_PHV Collection constraints
    // T_PHV_container_slices populated before container_pack_cohabit()
    //
    // t_phv_fields_i.assign(
    //   phv_requirements_i.t_phv_fields().begin(),
    //   phv_requirements_i.t_phv_fields().end());
    //
    // separate t_phv fields nibble
    //
    for (auto &cl : phv_requirements_i.t_phv_fields()) {
        if (cl->max_width() <= Constants::nibble)
            t_phv_fields_nibble_i.push_front(cl);
        else
            t_phv_fields_i.push_front(cl); }
    container_no_pack(t_phv_fields_i, T_PHV_groups_i, "T_PHV_smallest_container_width");
    //
    if (t_phv_fields_i.size()) {
        // attempt placement without smallest_container_width
        // e.g., empty 32b, 16b containers for 8b clusters
        container_no_pack(t_phv_fields_i, T_PHV_groups_i, "T_PHV_any_container_width", false);
        if (t_phv_fields_i.size()) {
            // pack remaining clusters to partially filled containers
            container_pack_cohabit(t_phv_fields_i, T_PHV_container_slices_i, "T_PHV");
            // try overflow T_PHVs in PHV remaining spaces
            if (t_phv_fields_i.size()) {
                LOG4("..........T_PHV Overflow ==> PHV ..........");
                // attempt empty containers in PHV
                container_no_pack(t_phv_fields_i, PHV_groups_i, "PHV <= T_PHV any_C_width", false);
                if (t_phv_fields_i.size()) {
                    container_pack_cohabit(
                        t_phv_fields_i, aligned_container_slices_i, "PHV <== TPHV_Overflow");
                    if (t_phv_fields_i.size()) {
                        LOG4("*** T_PHV Overflow PHV DID NOT FIT #cls = " << t_phv_fields_i.size());
                        LOG4(t_phv_fields_i); } } } } }
}  // PHV_MAU_Group_Assignments::cluster_TPHV_placements

void
PHV_MAU_Group_Assignments::cluster_PHV_nibble_placements() {
    //
    // placement in byte containers preferred to larger containers
    // as it avoids gateway matching issues, bit_masked set generation etc by other phases
    //
    container_no_pack(
        clusters_to_be_assigned_nibble_i,
        PHV_groups_i,
        "PHV_Nibble_smallest_container_width");
    if (clusters_to_be_assigned_nibble_i.size()) {
        //
        // pack remaining clusters to partially filled containers
        //
        container_pack_cohabit(
            clusters_to_be_assigned_nibble_i,
            aligned_container_slices_i,
            "PHV_Nibble");
        //
        if (clusters_to_be_assigned_nibble_i.size())
            LOG4("********** PHV Nibble placement + packing ***** DID NOT FIT ***** **********");
    }
}  // PHV_MAU_Group_Assignments::cluster_PHV_nibble_placements

void
PHV_MAU_Group_Assignments::cluster_T_PHV_nibble_placements() {
    //
    if (t_phv_fields_nibble_i.size()) {
        //
        // pack remaining clusters to partially filled containers
        //
        container_pack_cohabit(
            t_phv_fields_nibble_i,
            T_PHV_container_slices_i,
            "T_PHV_Nibble");
        //
        // try overflow T_PHV_Nibbles in PHV remaining spaces
        //
        if (t_phv_fields_nibble_i.size()) {
            //
            LOG4("..........T_PHV Nibble Overflow ==> PHV ..........");
            //
            container_pack_cohabit(
                t_phv_fields_nibble_i,
                aligned_container_slices_i,
                "PHV <== TPHV_Nibble_Overflow");
            //
            if (t_phv_fields_nibble_i.size())
                LOG4("********** T_PHV Nibble packing + PHV_Overflow ***** DID NOT FIT **********");
        }
    }
}  // PHV_MAU_Group_Assignments::cluster_T_PHV_nibble_placements

void
PHV_MAU_Group_Assignments::field_overlays() {
    //
    // for each container, overlay fields in container
    //
    for (auto &groups : PHV_MAU_i) {
        for (auto &g : groups.second) {
            for (auto &c : g->phv_containers()) {
                c->field_overlays();
            }
        }
    }
    for (auto &coll : T_PHV_i) {
        for (auto &m : coll.second) {
            for (auto &c : m.second) {
                c->field_overlays();
            }
        }
    }
}  // field_overlays

//*************************************************************************************************
//
// PHV_MAU_Group_Assignments::container_no_pack
//
// 1. sorted clusters requirement decreasing, sorted mau groups width decreasing
//
// 2. each CLUSTER FIELD in SEPARATE containers
//    addresses
//        surround effects within container
//        alignment issues (default start @ 0 unless alignment dictated by parser)
//        single-write constraint
//        deparser egress_port constraint (no cohabit)
//
// 3a.honor MAU group In/Egress only constraints
// 3b.pick next cl, put in Group with available non-occupied <container, width>
//    s.t., after assignment, G.remaining_containers != 1 as forall cl, |cl| >= 2
//    field f may need several containers, e.g., f:128 --> C1<32>,C2,C3,C4
//    but each C single or partial field only => C does not contain 2 fields
//
// fields that do not have any grouping constraints form singleton clusters
// they are subjected to the same allocation algorithm using <number = 1, width>
// cluster_phv_interference.cpp graph reduction attempts to group & reduce / overlay singletons
//
// 4. when all G exhausted
//    clusters_to_be_assigned contains clusters not assigned
//
//*************************************************************************************************

void
PHV_MAU_Group_Assignments::container_no_pack(
    std::list<Cluster_PHV *>& clusters_to_be_assigned,
    std::list<PHV_MAU_Group *>& phv_groups_to_be_filled,
    const char *msg,
    bool smallest_container_width)  {
    //
    // 1. sorted clusters requirement <number, width> decreasing
    //
    // 2. assign clusters_to_be_assigned to phv_groups_to_be_filled
    //    each cluster field in separate containers
    //    addresses
    //        single-write constraint,
    //        surround effects within container,
    //        alignment issues (start @ 0)
    //
    // sort clusters, number decreasing, width decreasing
    // preference given to clusters with fields having
    // exact_container requirement,
    // higher number of constraints
    //
    clusters_to_be_assigned.sort([](Cluster_PHV *l, Cluster_PHV *r) {
        if (l->num_overlays() > r->num_overlays())
            return true;
        if (l->exact_containers() && !r->exact_containers())
            return true;
        if (!l->exact_containers() && r->exact_containers())
            return false;
        if (l->num_constraints() == r->num_constraints()) {
            if (l->num_containers() == r->num_containers())
                // when placement, no pack, consider container_width, not field width (max_width())
                return l->width() > r->width();
            return l->num_containers() > r->num_containers(); }
        return l->num_constraints() > r->num_constraints(); });
    //
    // sort PHV_Groups in order 32b, 16b, 8b
    // for given width, I/E tagged MAU groups first
    //
    phv_groups_to_be_filled.sort([](PHV_MAU_Group *l, PHV_MAU_Group *r) {
        if (l->width() == r->width())
            return l->gress() != boost::none;
        return l->width() > r->width(); });

    for (auto &g : phv_groups_to_be_filled) {
        std::list<Cluster_PHV *> clusters_remove;
        for (auto &cl : clusters_to_be_assigned) {
            //
            // 3a.honor MAU group In/Egress only constraints
            //
            if (g->gress() && *g->gress() != cl->gress()) {
                // gress mismatch
                // skip cluster for this MAU group
                //
                continue;
            }
            if (smallest_container_width) {
                //
                // try to exact match cl width to g width  -- parser placement contraints
                // fields less than byte use byte
                //
                if (int(g->width()) > int(PHV::Size::b8)
                 && int(cl->width()) * 2 <= int(g->width())) {
                    //
                    continue;
                }
            }
            //
            // 3b.pick next cl, put in Group with available non-occupied <container, width>
            //    field f may need several containers, e.g., f:128 --> C1[32],C2,C3,C4
            //    each C single or partial field, e.g., f:24 --> C1[16], C2[8/16]
            //
            // parser containers exact width requirement
            // group can change based on cl downsize_mau_group(), use cl_g, save g for next cl
            //
            PHV_MAU_Group *cl_g = g;
            size_t req_containers = cl->num_containers();
            if (cl->exact_containers()) {
                if (int(cl->width()) < int(cl_g->width())) {
                    if (auto g_scale_down = downsize_mau_group(
                                                cl->gress(),
                                                int(cl->width()),
                                                req_containers,
                                                phv_groups_to_be_filled)) {
                        //
                        cl_g = g_scale_down;
                        LOG4("..... exact_containers ... downsizing MAU Group .....");
                        LOG4(*cl_g);
                    } else {
                        LOG4("*****cluster_phv_mau.cpp: sanity_WARN*****"
                            << ".....downsize...exact_containers MATCH NOT AVAILABLE");
                        LOG4(cl);
                    }
                } else {
                    // upsize mau group if current width groups have insufficient empty containers
                    if (req_containers > max_empty_containers(cl->gress(),
                                                              int(cl_g->width()),
                                                              phv_groups_to_be_filled)) {
                        if (auto g_scale_up = upsize_mau_group(
                                                    cl->gress(),
                                                    int(cl->width()),
                                                    req_containers,
                                                    phv_groups_to_be_filled)) {
                            //
                            cl_g = g_scale_up;
                            LOG4("..... exact_containers ... upsizing MAU Group .....");
                            LOG4(*cl_g);
                        } else {
                            LOG4("*****cluster_phv_mau.cpp: sanity_WARN*****"
                                << ".....upsize...exact_containers MATCH NOT AVAILABLE");
                            LOG4(cl);
                        }
                    }
                }
            }
            if (cl_g->width() != cl->width()) {
                // scale cl width down or up
                // <2:_48_32>{3*32} => <2:_48_32>{5*16}
                // <1:24>{3*8} => <1:24>{2*16} => <1:24>{1*32}
                req_containers = cl->num_containers(cl->cluster_vec(), cl_g->width());
            }
            if (req_containers <= cl_g->empty_containers()) {  // attempt assigning cl to cl_g
                LOG4("..... attempting MAU Group .....");
                LOG4(*cl_g);

                // for each field in cluster cl, assign consecutive chunks
                // across consecutive empty containers in g, tainting container
                // bits that are assigned.
                for (size_t i=0; i < cl->cluster_vec().size(); i++) {
                    PHV::Field *field = cl->cluster_vec()[i];
                    //
                    // phv_use_width can be inflated by Operations ceil_phv_use_width()
                    // to compute accurate requirements
                    // use correct amount to set cc->width
                    //
                    auto field_width = 0;
                    // field constrained no_pack and not ccgf owner, use size
                    if (PHV_Container::constraint_no_cohabit(field) && field->ccgf() != field) {
                       // field->ccgf() should be null, no member of ccgf should reach here
                       BUG_CHECK(field->ccgf() == nullptr,
                           "cluster_phv_mau.cpp: no ccgf member should be present in cluster");
                       field_width = field->size;
                    } else {
                       field_width = field->phv_use_width();
                    }
                    for (auto field_bit_lo=0; field_width > 0;) {
                        int taint_bits = std::min(field_width, int(cl_g->width()));
                        PHV_Container *container = cl_g->empty_container();
                        BUG_CHECK(container != nullptr,
                            "No container available for field %1%", field);

                        // consider alignment only at start of field
                        int align_start = 0;
                        if (field_bit_lo == 0) {
                            // Consider byte-relative alignment constraint (if any).
                            align_start = field->phv_alignment().get_value_or(0);

                            // Consider absolute alignment constraint for this set of containers,
                            // by:
                            // ...finding the bitrange representing all the containers this
                            // field will be tiled across.
                            int field_placement_size = cl->get_field_placement_size(field);
                            int req_containers_for_field =
                                field_placement_size / int(container->width()) +
                                (field_placement_size % int(container->width()) ? 1 : 0);
                            int aggregate_container_bits =
                                req_containers_for_field * int(container->width());
                            auto this_container_range =
                                nw_bitrange(StartLen(0, aggregate_container_bits));

                            // ...intersecting with the valid range for this field.
                            nw_bitinterval valid_interval =
                                this_container_range.intersectWith(field->validContainerRange());
                            BUG_CHECK(!valid_interval.empty(), "Bad absolute container range; "
                                      "field %1% has valid container range %2%, which has no "
                                      "overlap with aggregate container range %3%", field->name,
                                      field->validContainerRange(), this_container_range);
                            le_bitrange valid_range =
                                (*toClosedRange(valid_interval)).toOrder<Endian::Little>(
                                    aggregate_container_bits);

                            // ...and shifting the start bit if necessary.
                            if (!valid_range.contains(align_start)) {
                                // Use the lowest valid bit that also respects
                                // any relative (intra-byte) alignment, if present.
                                if (!field->phv_alignment()) {
                                    align_start = valid_range.lo;
                                } else {
                                    int req_byte_align = align_start % int(PHV::Size::b8);
                                    int abs_byte_align = valid_range.lo % int(PHV::Size::b8);
                                    int shift =
                                        abs_byte_align <= req_byte_align ?
                                        req_byte_align - abs_byte_align :
                                        req_byte_align + int(PHV::Size::b8) - abs_byte_align;
                                    align_start =
                                        (valid_range.lo + shift) % int(container->width()); }
                                BUG_CHECK(valid_range.contains(align_start),
                                    "Field %1% to start at container bit %2% (width %4%) "
                                    "but has an absolute alignment requirement of %3%",
                                    field, align_start, valid_range.lo, container->width());
                                BUG_CHECK(align_start % int(PHV::Size::b8) ==
                                          field->phv_alignment().get_value_or(0),
                                          "Inconsistent alignment constraints"); } }

                        if (taint_bits + align_start > int(container->width()))
                            taint_bits = int(container->width()) - align_start;

                        // TODO: If fields write to a ccgf in the same action, we need extra code
                        // here to ensure that the fields written into the ccgf destinations follow
                        // the same packing as the ccgf.
                        // metadata m {a, b, c, d, ...}
                        // header vlan {bit<3> priority; bit<1> chi; bit<12> tag; }
                        // Action {
                        //   priority = m.c;
                        //   tag = m.d;
                        // }
                        // Multiple fields may occupy a single container when they are part of a
                        // ccgf. If ccgf is destination, then container_no_pack needs to place
                        // operands of instructions writing to CCGF fields in the same container
                        // according to action analysis. Hence, m.c and m.d must be in the same
                        // container

                        int processed_bits =
                            container->taint(
                                align_start,
                                taint_bits,
                                field,
                                field_bit_lo);
                        LOG4(*container);

                        // ccgf fields with members that have pack constraints may not be done yet
                        // taint() sets field's hi reflecting balance remaining,
                        // returns processed width
                        //
                        field_bit_lo += processed_bits;
                        field_width -= processed_bits;  // loop termination
                        //
                        // check if this container is partially filled with parser field
                        // if field in MAU, avoid MAU Group violation, avoid relocation to another G
                        // also, if cluster is not uniform width, e.g.,
                        //     (ingress::test.field_a{0..31} deparsed,
                        //      ingress::test.field_e{0..15} deparsed)
                        //     set test.field_a, test.field_e
                        // placing field_a in 32b, field_e in 16b will cause mau group violation
                        // "registers in an instruction must all be in the same phv group"
                        //
                    }  // for field
                    if (!field->allocation_complete()) {
                        // TODO(cole): Should this be a BUG?
                        LOG4("*****cluster_phv_mau.cpp: sanity_FAIL*****"
                            << ".....ccgf member(s) INCOMPLETE ALLOCATION");
                        LOG4(field);
                    }
                }  // for cluster
                // update num_containers
                cl->num_containers(req_containers);
                cl->width(cl_g->width());
                cl_g->clusters().push_back(cl);
                clusters_remove.push_back(cl);

                // fix MAU group's gress Ingress Or Egress
                if (cl_g->gress() == boost::none)
                    cl_g->gress(cl->gress());

                LOG4(*cl_g << " <-- " << cl);
                if (cl_g->empty_containers() == 0)
                    break;
            }  // attempt cl to g
        }  // for clusters

        // remove clusters already assigned
        for (auto &cl : clusters_remove)
            clusters_to_be_assigned.remove(cl);
    }  // for phv groups

    //
    // all mau groups searched
    //
    std::list<PHV_MAU_Group *> phv_groups_remove;
    for (auto &g : phv_groups_to_be_filled) {
        if (g->empty_containers() == 0)
            phv_groups_remove.push_back(g); }

    // remove groups that are full
    for (auto &g : phv_groups_remove)
        phv_groups_to_be_filled.remove(g);

    // Log new fields allocated and the current state of the containers (free,
    // partially allocated, full).
    dump_new_placements(msg);
}

size_t PHV_MAU_Group_Assignments::max_empty_containers(
        boost::optional<gress_t> gress,
        int width,
        std::list<PHV_MAU_Group *> phv_groups_to_be_filled) {
    size_t empty_containers = 0;

    for (auto &g : phv_groups_to_be_filled) {
        if (int(g->width()) == width && g->gress() != gress)
            empty_containers = std::max(empty_containers, g->empty_containers()); }

    return empty_containers;
}

PHV_MAU_Group*
PHV_MAU_Group_Assignments::upsize_mau_group(
    gress_t gress,
    int width,
    size_t required_containers,
    std::list<PHV_MAU_Group *> phv_groups_to_be_filled) {
    //
    // find available MAU group w/ container width > width
    // e.g., for width = 8, try 16b, then 32b
    //
    phv_groups_to_be_filled.sort([](PHV_MAU_Group *l, PHV_MAU_Group *r) {
        if (l->width() == r->width())
            return l->empty_containers() < r->empty_containers();
        return l->width() < r->width(); });

    for (auto &g : phv_groups_to_be_filled) {
        bool gress_is_ok = !g->gress() || (g->gress() && *g->gress() == gress);
        bool enough_empty_bits =
            g->empty_containers() * int(g->width()) >= required_containers * width;
        if (gress_is_ok && enough_empty_bits)
            return g; }

    LOG4("***** upsize_mau_group() FAILED for <gress,width,required_containers>  *****"
        << "<" << required_containers << "*" << width << gress << ">");

    return nullptr;
}

PHV_MAU_Group*
PHV_MAU_Group_Assignments::downsize_mau_group(
    gress_t gress,
    int width,
    size_t required_containers,
    std::list<PHV_MAU_Group *> phv_groups_to_be_filled) {
    //
    // find available MAU group w/ container width <= width & required containers
    // e.g., for width = 24, try 16b, then 8b
    //
    phv_groups_to_be_filled.sort([](PHV_MAU_Group *l, PHV_MAU_Group *r) {
        if (l->width() == r->width())
            return l->empty_containers() > r->empty_containers();
        return l->width() > r->width(); });

    for (auto &g : phv_groups_to_be_filled) {
        bool gress_is_ok = !g->gress() || (g->gress() && *g->gress() == gress);
        // XXX(cole): Isn't there a method somewhere that already calculates this?
        bool enough_empty_bits =
            g->empty_containers() * int(g->width()) >= required_containers * width;
        if (gress_is_ok && int(g->width()) <= width && enough_empty_bits)
            return g; }

    LOG4("***** downsize_mau_group() FAILED for <gress,width,required_containers>  *****"
        << "<" << required_containers << "*" << width << gress << ">");

    return nullptr;
}


//***********************************************************************************
//
// PHV_MAU_Group_Assignments::create_aligned_container_slices
//
// for all MAU groups with partially filled containers
// slice to obtain larger number of sub-containers with reduced width
//
// input:
//      all mau groups
// output:
//      in each PHV_MAU_Group, map[width][number] of aligned_container_slices
//      consider all PHV_MAU_Groups,
//      create composite map[width][number] --> <set of <set of container_packs>>
//      map has sorted order width increasing, number increasing
//
//***********************************************************************************

void PHV_MAU_Group_Assignments::create_aligned_container_slices() {
    //
    // create composite map[width][number] --> <set of <set of container_packs>>
    // from all mau groups aligned_container_slices
    // map automatically has sorted order width increasing, number increasing
    //
    aligned_container_slices_i.clear();
    for (auto rit = PHV_MAU_i.rbegin(); rit != PHV_MAU_i.rend(); ++rit) {
        // groups within this word size
        for (auto g : rit->second) {
            g->create_aligned_container_slices();
            //
            for (auto w : g->aligned_container_slices()) {
                for (auto n : w.second) {
                    for (auto cc_set : n.second) {
                        aligned_container_slices_i[w.first][n.first].push_back(cc_set);
                           // insert in composite  map[w][n]
                    }
                }
            }
        }
    }
    LOG4("..........PHV Container Packs Avail ..........");
    LOG4(aligned_container_slices_i);
    //
    // pack remaining fields to partially filled containers
    // conforming to T_PHV Collection constraints
    // T_PHV_container_slices determined before container_pack_cohabit()
    //
    T_PHV_container_slices_i.clear();
    for (auto &coll : T_PHV_i) {
        for (auto &m : coll.second) {
            auto *set_cc = new std::list<PHV_MAU_Group::Container_Slice *>;
            for (auto &c : m.second) {
                if (c->status() == PHV_Container::Container_status::EMPTY) {
                    set_cc->push_back(
                        new PHV_MAU_Group::Container_Slice(
                            0,
                            int(c->width()),
                            c));
                } else if (c->status() == PHV_Container::Container_status::PARTIAL) {
                    //
                    // extract contiguous bit ranges
                    // c->avail_bits()=16 but disjoint (0..2)(19..31)<16>
                    //
                    for (auto &r : c->ranges()) {
                        int start = r.first;
                        int partial_width = r.second - r.first + 1;
                        auto* set_cc_partial = new std::list<PHV_MAU_Group::Container_Slice *>;
                        set_cc_partial->push_back(
                            new PHV_MAU_Group::Container_Slice(start, partial_width, c));
                        T_PHV_container_slices_i[partial_width][1].push_back(*set_cc_partial);
                    }
                }
            }
            if (set_cc->size()) {
                T_PHV_container_slices_i
                   [int(m.first)][set_cc->size()].push_back(*set_cc);
            }
        }
    }
    LOG4("..........T_PHV Container Packs avail ..........");
    LOG4(T_PHV_container_slices_i);
}  // PHV_MAU_Group_Assignments::create_aligned_container_slices()

//***********************************************************************************
//
// predicates for packing constraints
//
// PHV_MAU_Group_Assignments::match_cluster_to_cc_set()
// PHV_MAU_Group_Assignments::packing_predicates()
//
//***********************************************************************************
//
// ensure each field's alignment start is satisfied before container packing
//
bool
PHV_MAU_Group_Assignments::satisfies_phv_alignment(
    Cluster_PHV *cl,
    int lo,
    int hi) {
    //
    for (auto &f : cl->cluster_vec()) {
        if (f->phv_use_lo() == 0) {
            // need to consider alignment only @ start bit of field
            // if field sliced, consider slice that has start bit 0
            if (auto align_start = f->phv_alignment()) {
                // TODO:
                // also should try as bit-in-byte, a+8, a+16 etc.
                if (*align_start < lo || *align_start > hi)
                    return false;
                // to compute end, use container width, e.g., cl->width()=8, f->phv_use_width()=23
                const int end = *align_start + int(cl->width()) - 1;
                if (end < lo || end > hi)
                    return false;
            }
        }
    }
    return true;
}
//
// ensure each predicate is satisfied when matching cluster fields to cc_set
//
bool
PHV_MAU_Group_Assignments::match_cluster_to_cc_set(
    Cluster_PHV *cl,
    std::list<PHV_MAU_Group::Container_Slice *>& cc_set) {
    //
    // when x fields can be allocated to y ccs, x < y
    // the top y-x is striped for reuse as a new set of aligned ccs, the bottom x allocated
    // iterate through ccs in reverse, otherwise comparison is against the wrong set of containers
    // compare fields in reverse: [f1,f2] vs [c1,c2,c3,c4]
    // f2 vs c4, f1 vs c3, s.t., [f1,f2] => [c3,c4]
    //
    auto cc_it = cc_set.rbegin();
    auto f_it = cl->cluster_vec().rbegin();
    for (; cc_it != cc_set.rend() && f_it != cl->cluster_vec().rend(); ++cc_it, ++f_it) {
        //
        // bridge metadata considerations:
        // cannot pack bridge metadata mirror & bridge metadata Not mirror
        // packed bridge metadata must belong to same field list (one of eight field lists)
        //
        PHV::Field *f = *f_it;
        PHV_Container *c = (*cc_it)->container();
        BUG_CHECK(c, "*****PHV_MAU_Group_Assignments::packing_predicates, container null *****");
        if (f->bridged && f->mirror_field_list.member_field) {
            // for all fields in container, ensure mirror fields & same field list
            for (auto &entry : c->fields_in_container()) {
                PHV::Field *cf = entry.first;
                if (cf->mirror_field_list != f->mirror_field_list)
                    return false;  // mirror_field_lists disagree, cannot pack
            }  // for
        }
        //
        // bridge-metadata has alignment constraint between ingress and egress
        // mirror field list members (whether bridged or not) have same alignment constraint
        // ingress_bridge_metadata starts at same 'bit in byte' as egress_bridge_metadata
        // such constraints are auto matched by parde alignment generation after thread split
        //
        // TODO
        // learning digests: L1, L2 belong to same digest
        // mirror, resubmit digests do not have this constraint
        //
        // deparser container constraints related to packing
        //
        if (c->deparsed()) {  // set by taint_bits()..fields_in_container() after fd allocated to c
            // disallow deparsed header w/ deparsed non-header
            for (auto &entry : c->fields_in_container()) {
                PHV::Field *cf = entry.first;
                // if deparsed header in c, disallow anything but another deparsed header
                if (!cf->metadata && cf->deparsed() && (f->metadata || f->pov || !f->deparsed()))
                    return false;
                // if deparsed bridge metadata in c, disallow deparsed header
                if (cf->metadata && cf->deparsed() && !(f->metadata || f->pov) && f->deparsed())
                    return false;
            }  // for
        }
        // before placing deparsed f in c, ensure
        // deparser container constraints related to packing
        //
        if (f->deparsed()) {
            for (auto &entry : c->fields_in_container()) {
                PHV::Field *cf = entry.first;
                // do not put deparsed header with non-deparsed field in container
                if (!f->bridged && !cf->deparsed())
                    return false;
                // if container has deparsed header, disallow metadata
                if (!cf->metadata && cf->deparsed() && f->metadata)
                    return false;
            }  // for
        }
        //
        // Pass a vector to ActionPhvConstraints::can_cohabit to detect if any
        // action constraints prevent packing within the same container
        // 0th to (n-2)th elements of the n-element vector are the fields already
        // present in the container.
        // The last (n-1)th element is the field for which we are attempting to pack
        // Along with the field itself, also pass it the relevant container content so that Action
        // Analysis knows which slice of the field the container contains
        std::vector<ActionPhvConstraints::PackingCandidate> packing_candidates;
        for (auto field : c->fields_in_container()) {
            for (auto cc : field.second)
                packing_candidates.push_back(ActionPhvConstraints::PackingCandidate(field.first,
                            le_bitrange(FromTo(cc->field_bit_lo(), cc->field_bit_hi())))); }
        if (f->ccgf() == nullptr) {
            // If a field is not part of a CCGF, then its (phv_use_lo, phv_use_hi) range represents
            // the slice of the field that is a candidate for packing
            packing_candidates.push_back(ActionPhvConstraints::PackingCandidate(f,
                        le_bitrange(FromTo(f->phv_use_lo(), f->phv_use_hi()))));
        } else {
            /** If a field is a CCGF, then we need to examine which fields fall within the
              * [phv_use_lo, phv_use_hi] range of the CCGF representative. E.g. suppose we have a
              * CCGF formed of the following header fields:
              *
              *     bit<4> a;
              *     bit<2> b;
              *     bit<3> c;
              *     bit<7> d;
              *
              * Suppose we are considering the slice [0,7] (i.e. phv_use_lo = 0, phv_use_hi =
              * 7). The can_cohabit method must examine the co-habit of fields a, b, and c in
              * addition to the existing packing for that container.
              *
              * On the other hand, if we only consider the candidate slice [4,7], then it needs to
              * examine cohabiting only for fields b and c.
              *
              * This piece of the code walks through each CCGF member and checks if part of that
              * member field falls within the [phv_use_lo, phv_use_hi] closed range.
              *
              */
            auto use_range = le_bitrange(FromTo(f->phv_use_lo(), f->phv_use_hi()));
            int offset = 0;
            for (auto *field : boost::adaptors::reverse(f->ccgf_fields())) {
                auto field_range = le_bitrange(StartLen(0, field->size)).shiftedByBits(offset);
                if (use_range.overlaps(field_range)) {
                    // intersectsWith() returns a HalfOpenRange because the result of
                    // intersectWith() may be empty
                    // In this case though, because intersectWith is only performed when overlaps is
                    // true, the result of intersectWith should never be empty and so, it can be
                    // safely converted to a ClosedRange.
                    boost::optional<le_bitrange> phv_limits =
                        toClosedRange(use_range.intersectWith(field_range));
                    if (!phv_limits)
                        BUG("Intersect operation must not return empty bitrange if the result of "
                                "overlaps() is true");
                    // As the check in can_cohabit is based on slices of fields [field_bit_lo,
                    // field_bit_hi], we need to push the field slice limits onto packing_candidates
                    // (and not the ccgf's phv use limits)
                    auto field_limits = phv_limits.get().shiftedByBits(-offset);
                    packing_candidates.push_back(ActionPhvConstraints::PackingCandidate(field,
                                field_limits)); }
                offset += field->size; } }
        if (action_constraints.can_cohabit(packing_candidates) !=
                ActionAnalysis::ContainerAction::NO_PROBLEM) {
            return false; } }  // for
    return true;
}  // match_cluster_to_cc_set

//
// ensure each predicate is satisfied before container packing
//
bool
PHV_MAU_Group_Assignments::packing_predicates(
    Cluster_PHV *cl,
    std::list<PHV_MAU_Group::Container_Slice *>& cc_set) {
    //
    BUG_CHECK(cl, "Empty cluster");
    BUG_CHECK(cl->cluster_vec().size() <= cc_set.size(), "Bad cluster--slice set match");
    BUG_CHECK(*(cc_set.begin()), "Empty slice set");

    boost::optional<gress_t> c_gress = (*(cc_set.begin()))->container()->gress();
    if (c_gress && *c_gress != cl->gress())
        return false;

    // attempt to avoid non bridged metadata in deparsed container
    canonicalize_cc_set(cl, cc_set);
    //
    // constrained nibbles, e.g., learning digest, place in container's "bottom bits"
    int req = cl->req_containers_bottom_bits();
    if (req && !num_containers_bottom_bits(cl, cc_set, req))
        return false;

    // TODO
    //
    // field start restrictions .. must start @X 'bit-in-byte' in container, e.g., X,X+8,X+16 etc.
    //
    le_bitrange container_slice_range = (*cc_set.rbegin())->range();
    if (!satisfies_phv_alignment(cl, container_slice_range.lo, container_slice_range.hi))
        return false;

    // Check whether this slice set supports the absolute alignment constraints
    // for all fields in the cluster.
    PHV::Size container_size = (*cc_set.rbegin())->container()->width();
    for (PHV::Field* fieldInfo : cl->cluster_vec()) {
        nw_bitrange valid_container_range = fieldInfo->validContainerRange();

        // XXX(cole): for now, if a field has an absolute alignment constraint but
        // cannot fit in a single slice, don't pack this cluster in this slice
        // group.
        if (valid_container_range != ZeroToMax()
            && fieldInfo->phv_use_width() > container_slice_range.size()) {
            return false; }

        // Intersect the valid container range with this container size, in
        // case the valid container range is larger than this container.
        nw_bitinterval valid_interval =
            valid_container_range.intersectWith(nw_bitrange(StartLen(0, int(container_size))));
        if (valid_interval.empty())
            return false;

        // The `validContainerRange` constraint is a bit range in network
        // order, so convert it to little Endian with respect to this container
        // size.
        le_bitrange valid_range =
            (*toClosedRange(valid_interval)).toOrder<Endian::Little>(int(container_size));
        le_bitinterval valid_slice_interval =
            valid_range.intersectWith(container_slice_range);

        // Return false if the slice isn't in the valid range.
        if (valid_slice_interval.size() < fieldInfo->phv_use_width())
            return false;

        // If this field needs to be allocated in the "bottom bits" (little
        // Endian, LSB), check that these bits are in the valid range.
        auto phv_use_width = le_bitinterval(StartLen(0, fieldInfo->phv_use_width()));
        if (fieldInfo->deparsed_bottom_bits() && !valid_slice_interval.contains(phv_use_width))
            return false; }

    // try sliding window of cc_set
    for (int slice_adjust = cc_set.size() - cl->cluster_vec().size() + 1;
        slice_adjust;
        slice_adjust--) {
        //
        if (match_cluster_to_cc_set(cl, cc_set))
            break;
        if (slice_adjust == 1)
            return false;
        //
        // rotate down cc_set by 1
        // allocation stripe uses bottom
        //
        cc_set.push_front(*(cc_set.rbegin()));
        cc_set.pop_back(); }

    //
    // TODO
    //
    // field solitary: e.g., 7*1b can't be packed to 8b, use separate containers, albeit 2TCAMS, 88b
    //
    // checksum 16b..16b..8b in 16b or 8b container ?
    //
    // mutually_cohabit(f1, f2),
    //
    // instruction adjustment related constraints from TP / Instruction Selection
    //

    return true;
}  // packing_predicates

//***********************************************************************************
//
// PHV_MAU_Group_Assignments::container_pack_cohabit
//
// 4. when all G exhausted, attempt to pack C with available widths
//    (i)  co-habit         (need Table "single-write", surround side-effects (move-based ops))
//    (ii) no overlay       (need liveness, ifce graph)
//    e.g.,
//    clusters remain              G.avail
//    --------------               -------
//        <num, width>             <num containers, bit width>
//         7 1                     G1: 1:3
//         6 8                     G2: 1:7
//         5 8                     G3: 1:1, 1:1
//         5 4                     G4: 1:1, 1:7
//         5 1                     G5: 1:8, 1:13
//         4 3                     G6: 1:3, 1:6, 1:7
//         4 1                     G7: 4:8
//         3 8                     G8: 4:12
//         3 8                     G9: 5:8, 5:16
//         3 8 8 5                 G10: 1:1, 10:16
//         3 5
//         3 5
//         3 2
//         3 1
//         3 1
//         3 1
//         2 9
//         2 8
//         2 1
//
//   (i) Pack co-habit
//       remaining clusters sorted with decreasing n, decreasing w
//       sort avail G:<n,w>, G:n increasing, and within G, w increasing
//       already available as map[w][n]--> <G:container_pack>
//       create composite map[w][n]--> <set of <container_pack>>
//           as several G's can produce map[w][n]--> <G:container_pack>
//       fill container packs, automatically aligment honored
//
//       for members in cluster
//           pick top member<cn, cw> from sorted list
//           search map[cw] upto end of map
//               if map[mw][mn] accommodates member<cn, cw>
//                   if mw > cw, mn > cn
//                       split container_pack <mw, mn>
//                           --> <mw, mn-cn>, (<mw, cn> --> <mw-cw, cn>, <cw, cn>)
//                       map.insert new container_packs
//                   allocate member<cn, cw> to container_pack<cw, cn>
//                       C.update_record member<cn, cw>
//                       for each cohabit field, taint bits packing from righmost slice
//                       -- honors alignment among cluster members
//                       -- ref: PHV_MAU_Group::create_aligned_container_slices()
//                       map.remove container_pack<mw, mn>
//           if member not allocated then "cannot pack member"
//
//       G.singleton C use later if necessary for
//       (i) horizontal pack
//       (ii) status bits e.g., POVs for headers that honor single-write constraint
//
// 5. vertical distribution => no horizontal distribution
//        x.y => sigma Ca.y where x = number of containers = sigma Ca
//        addresses
//        (i)   sibling operands cannot reside in same container
//        (ii)  single-write constraint for cluster members
//        (iii) single-write constraint across clusters cohabiting container may exist
//              these fields are output as a recommedation to Table-Placement
//        within new cl selected for co-habit, packing should ensure no G.rem = 1.X
//        as no future cl can use this remnant unless horizontal packing enabled
//
// input:
//        (i)  clusters_to_be_assigned
//        (ii) all PHV_MAU_Groups w/ map<int, map<int, set<Container_Slice *>>>
//                 aligned_container_slices_i
//             forall G,C sorted aligned_slices
//             --------------------------------
//             map[width][number]
//             [1][1]
//             [1][2]*2
//             [1][11]
//             [3][1]
//             [3][2]
//             [3][3]
//             [5][1]
//             [6][1]
//             [7][1]
//             [8][2]
//             [8][4]
//             [8][5]
//             [8][10]
//             [12][4]
//             [15][10]
// output:
//      clusters (cohabit) packed into available containers
//
//***********************************************************************************

void PHV_MAU_Group_Assignments::container_pack_cohabit(
    std::list<Cluster_PHV *>& clusters_to_be_assigned,
    PHV_MAU_Group::Aligned_Container_Slices_t& aligned_slices,
    const char *msg) {
    // slice containers to form groups that can accommodate larger number for given width in <n:w>
    create_aligned_container_slices();

    // sort clusters number decreasing, width decreasing, using ids to break ties
    clusters_to_be_assigned.sort([](Cluster_PHV *l, Cluster_PHV *r) {
        // Sort by number of overlays first
        if (l->num_overlays() > r->num_overlays())
            return true;
        // ...then by number of containers
        if (l->num_containers() != r->num_containers())
            return l->num_containers() > r->num_containers();

        // ...then by width
        if (l->max_width() != r->max_width())
            return l->max_width() > r->max_width();

        // ...and finally by unique ID number.
        return l->id_num() < r->id_num(); });

    LOG4("..........Begin Pack Cohabit ("
         << clusters_to_be_assigned.size()
         << ").....Sorted Clusters to be packed....."
         << msg
         << std::endl);
    LOG4(clusters_to_be_assigned);

    // pack sorted clusters<n,w> to containers[w][n]
    LOG4("..........Packing.........." << std::endl);

    std::list<Cluster_PHV *> clusters_remove;
    for (auto* cl : clusters_to_be_assigned) {
        int required_width = std::min(cl->max_width(), int(cl->width()));
            // exceed container_width => no match, e.g., cluster <1:160>{5*32}(pkt.pad_1{0..159})
        int required_containers = cl->num_containers();

        // Find a group of slices (copied to cc_set) that can hold this cluster.
        std::list<PHV_MAU_Group::Container_Slice *> cc_set;

        // Set when cc_set is found:
        int slice_width;
        int available_slices;
        boost::optional<gress_t> slice_gress;

        for (auto& slices_by_width : aligned_slices) {
            slice_width = slices_by_width.first;
            if (slice_width < required_width)
                continue;
            for (auto &slices_by_count : slices_by_width.second) {
                if (cl->exact_containers()) {
                    BUG_CHECK(slices_by_count.second.size() > 0,
                              "Aligned slices group with zero slices");

                    // cluster width must exact match container
                    // check first container in cc_list
                    if (slice_width != required_width)
                        continue;

                    std::list<PHV_MAU_Group::Container_Slice *>& cc_l =
                        *(slices_by_count.second.begin());
                    PHV_MAU_Group::Container_Slice *cc = *(cc_l.begin());
                    if (slice_width != int(cc->container()->width()))
                        continue; }
                //
                // split container_pack <slice_width, slice_count>
                // --> <slice_width, slice_count-cn>,
                //     (<slice_width, required_containers> -->
                //      <slice_width-required_width, required_containers>,
                //      <required_width, required_containers>)
                //
                available_slices = slices_by_count.first;
                if (available_slices < required_containers)
                    continue;

                // check gress compatibility
                slice_gress = boost::none;

                // find a slice set suitable for holding cluster cl
                for (auto &cc_set_x : slices_by_count.second) {
                    slice_gress = (*(cc_set_x.begin()))->container()->gress();
                    if (packing_predicates(cl, cc_set_x)) {
                        cc_set = cc_set_x;

                        // remove matching MAU_Group Container Content from set_of_sets
                        // if set_of_sets empty then remove map[slice_width] entry
                        slices_by_count.second.remove(cc_set_x);
                        if (slices_by_count.second.empty())
                            slices_by_width.second.erase(slices_by_count.first);

                        break; } }

                if (cc_set.empty())
                    // not compatible, constraints not satisfied, continue looking
                    LOG4("-----" << cl->id() << '<' << required_containers << ',' << required_width
                         << '>' << cl->gress()
                         << "-----[" << slice_width << "](" << available_slices << ')'
                         << slice_gress /*<< slices_by_count.second*/);
                else
                    break; }

            // If the inner loop was successful, break.
            if (!cc_set.empty())
                break; }

        // If no slice set can hold this cluster, continue to the next
        // cluster; a later pass will hopefully handle this one.
        if (cc_set.empty())
            continue;

        // Mark cluster for removal.
        clusters_remove.push_back(cl);

        LOG4("....." << cl->id() << "<" << required_containers << ',' << required_width << '>'
             << cl->gress() <<  "-->[" << slice_width << "](" << available_slices << ')'
             << slice_gress);
        LOG4("\t" << cc_set);
        BUG_CHECK(available_slices >= 0 && size_t(available_slices) == cc_set.size(),
            "Slice group of size %1% but expected size %2%", cc_set.size(), available_slices);

        // Put any extra, unused slices into their own group in the slice map.
        if (available_slices > required_containers) {
            //
            // create new container pack <mw, mn-cn>
            // n = available_slices - required_containers containers
            // insert in map[n]
            //
            auto* cc_n = new std::list<PHV_MAU_Group::Container_Slice *>;
            auto n = available_slices - required_containers;
            for (auto idx = 0; idx < n; idx++) {
                cc_n->push_back(*(cc_set.begin()));
                cc_set.erase(cc_set.begin());
            }
            aligned_slices[slice_width][n].push_back(*cc_n);
            LOG4("\t==>[" << slice_width << "]-->[" << slice_width << "](" << n << ')');
            LOG4("\t" << *cc_n); }

        // Assign slices to containers.
        size_t field_num = 0;
        PHV::Field *f = cl->cluster_vec()[field_num];
        auto field_bit_lo = f->phv_use_lo(cl);               // considers slice lo
        for (auto* cc : cc_set) {
            //
            // to honor alignment of fields in clusters
            // start with rightmost vertical slice that accommodates this width
            //
            int start = cc->hi() + 1 - required_width;
            if (f->deparsed_bottom_bits()) {
                // f has constraints "bottom bits", e.g., learning digest
                // packing_predicates() must have ensured bottom bits available
                //
                // TODO(cole): If any field in a cluster has
                // `deparsed_bottom_bits()` set, do all fields need to be
                // aligned at 0?
                assert(cc->lo() == 0);
                start = cc->lo(); }

            if (f->phv_use_width(cl) > required_width
                && required_width != int(cc->container()->width())) {       // 128b = 32*4
                //
                // TODO(cole): Should this be BUG?
                LOG4("cluster_phv_mau.cpp*****sanity_FAIL*****");
                LOG4(".....field width exceeds slice .....");
                LOG4(f);
                LOG4(" slice width required_width = " << required_width); }

            if (f->metadata && !f->bridged && cc->container()->deparsed()) {
                const PHV::Field *deparsed_header = nullptr;
                const PHV::Field *non_deparsed_field = nullptr;
                cc->container()->sanity_check_deparsed_container_violation(
                        deparsed_header, non_deparsed_field);
                BUG_CHECK(!deparsed_header, "Metadata %1% placed with deparsed header field %2%",
                    f, deparsed_header); }

            // last alloc of field slice may be remainder of division by required_width,
            // e.g., 375bits mod 32b containers, last field slice = 23 bits
            //
            int remaining_field_width = f->phv_use_hi(cl) - field_bit_lo + 1;
            int width_in_container = std::min(required_width, remaining_field_width);
            int align_start = start;

            // consider alignment only at start of field
            if (field_bit_lo == 0) {
                // account for relative alignment
                align_start = f->phv_alignment().get_value_or(start);

                // account for absolute container alignment
                nw_bitrange nw_container_slice =
                    cc->range().toOrder<Endian::Network>(int(cc->container()->width()));
                nw_bitinterval nw_valid_container_slice =
                    nw_container_slice.intersectWith(f->validContainerRange());
                BUG_CHECK(nw_valid_container_slice.size() >= required_width,
                    "Container slice %1% does not have enough valid bits for field %2%: "
                    "%3% cannot hold %4% bits",
                    cc, f, nw_valid_container_slice, required_width);
                le_bitrange le_valid_container_slice = *toClosedRange(
                    nw_valid_container_slice.toOrder<Endian::Little>(
                        int(cc->container()->width())));

                if (!le_valid_container_slice.contains(align_start)) {
                    // Use the lowest valid bit that also respects
                    // any relative (intra-byte) alignment, if present.
                    if (!f->phv_alignment()) {
                        align_start = le_valid_container_slice.lo;
                    } else {
                        int req_byte_align = align_start % int(PHV::Size::b8);
                        int abs_byte_align = le_valid_container_slice.lo % int(PHV::Size::b8);
                        int shift = abs_byte_align <= req_byte_align ?
                                    req_byte_align - abs_byte_align :
                                    req_byte_align + int(PHV::Size::b8) - abs_byte_align;
                        align_start = le_valid_container_slice.lo + shift; }

                    BUG_CHECK(le_valid_container_slice.contains(align_start),
                        "Field %1% to start at container bit %2% but has an absolute alignment "
                        "requirement of %3%", f, align_start, le_valid_container_slice.lo);
                    BUG_CHECK(align_start % int(PHV::Size::b8) ==
                              f->phv_alignment().get_value_or(0),
                              "Inconsistent alignment constraints"); } }

            if (f->size < cc->width()) {
                auto le_field_range = le_bitrange(StartLen(align_start, f->size));
                auto nw_field_range = le_field_range.toOrder<Endian::Network>(
                    int(cc->container()->width()));
                BUG_CHECK(f->validContainerRange().contains(nw_field_range),
                    "Violated container alignment constraint for field %1%: %2% not in %3%",
                    f, nw_field_range, f->validContainerRange()); }

            if (width_in_container + align_start > int(cc->container()->width()))
                width_in_container = int(cc->container()->width()) - align_start;

            cc->container()->taint(align_start,               // start
                                   width_in_container,        // width
                                   f,                         // field
                                   field_bit_lo);             // field_bit_lo
            cc->container()->sanity_check_container_ranges(
                "PHV_MAU_Group_Assignments::container_pack_cohabit..");
            LOG4("\t" << f << " assigned to " << *(cc->container()));
            //
            // advance to next field or continue same field
            //
            if (field_num < cl->cluster_vec().size() - 1) {
                field_num++;
                f = cl->cluster_vec()[field_num];
                field_bit_lo = f->phv_use_lo(cl);             // considers slice lo
            } else {
                //
                // single field overlapping several containers
                // e.g., singleton field cl <1:160>{5*32}
                // same field, advance field_bit_lo
                //
                field_bit_lo += required_width; } }

        // If the cluster did not use all the available bits in each slice,
        // create a new group of slices out of the remaining, free bits.
        if (slice_width > required_width) {
            //
            // set aligned slices with cc_set representing updated availability
            // if no disjoint available segments due to parde_alignment
            //     create new container pack <mw-cw, cn>
            //     new width w = slice_width - required_width;
            //     insert in map[slice_width-required_width][required_containers]
            // else
            //     create container packs representing availability
            //     to left and right of occupation
            //
            // usually top-bit occupation but check bottom bit, e.g., $learning
            // parde alignment can create disjoint partitions
            // vacancies before & after occupation width
            auto cc_b = *(cc_set.begin());
            bool lo_occupied = cc_b->container()->bits()[cc_b->lo()] != '0';
            bool hi_occupied = cc_b->container()->bits()[cc_b->hi()] != '0';
            //
            bool disjoint_segments = !lo_occupied && !hi_occupied;
            std::list<PHV_MAU_Group::Container_Slice *>* cc_d = nullptr;
            int lo_d = 0;
            int hi_d = 0;
            if (disjoint_segments) {
                cc_d = new std::list<PHV_MAU_Group::Container_Slice *>;
                for (auto bit = cc_b->lo(); bit <= cc_b->hi(); bit++) {
                    if (cc_b->container()->bits()[bit] != '0') {
                        lo_d = bit - 1;
                        hi_d = lo_d + required_width + 1;
                        BUG_CHECK(cc_b->container()->bits()[hi_d] == '0',
                            "*****PHV_MAU_Group_Assignments:: "
                            "disjoint availability inconsistent *****");
                        break; } }

                for (auto &cc : cc_set) {
                    // disjoint available segments
                    // cc_d represents availability to right of occupation
                    cc_d->push_back(
                        new PHV_MAU_Group::Container_Slice(
                            hi_d, cc->hi() - hi_d + 1, cc->container())); } }

            auto *cc_w = new std::list<PHV_MAU_Group::Container_Slice *>;
            for (auto &cc : cc_set) {
                if (lo_occupied) {
                    cc_w->push_back(
                        new PHV_MAU_Group::Container_Slice(
                            cc->lo() + required_width,
                            cc->hi() - cc->lo() - required_width + 1,
                            cc->container()));
                } else {
                    if (hi_occupied) {
                        cc_w->push_back(
                            new PHV_MAU_Group::Container_Slice(
                                cc->lo(),
                                cc->hi() - required_width - cc->lo() + 1,
                                cc->container()));
                    } else {
                        // disjoint available segments
                        // cc_w represents availability to left of occupation
                        cc_w->push_back(
                            new PHV_MAU_Group::Container_Slice(
                                cc->lo(), lo_d - cc->lo() + 1, cc->container())); } } }

            int w_d_h = 0;
            int w = 0;
            if (disjoint_segments) {
                w_d_h = (*(cc_d->begin()))->width();
                w = (*(cc_w->begin()))->width();
                aligned_slices[w_d_h][required_containers].push_back(*cc_d);
                aligned_slices[w][required_containers].push_back(*cc_w);
            } else {
                w = slice_width - required_width;
                aligned_slices[w][required_containers].push_back(*cc_w); }

            LOG4("\t==>(" << required_containers << ")-->[" << w << "]" <<
                 "(" << required_containers << ')' << std::endl << '\t' << *cc_w);

            if (disjoint_segments) {
                LOG4("\t|==>|(" << required_containers << ")-->[" << w_d_h << "]" <<
                    "(" << required_containers << ')' << std::endl << '\t' << *cc_d); } } }

    sanity_check_container_fields_gress("PHV_MAU_Group_Assignments::container_pack_cohabit()..");

    // remove clusters already assigned
    for (auto &cl : clusters_remove)
        clusters_to_be_assigned.remove(cl);

    // clean up aligned_slices
    for (auto &i : aligned_slices) {
        bool clear_i = true;
        for (auto &x : i.second) {
            if (!x.second.empty()) {
                clear_i = false;
                break; } }
        if (clear_i == true)
            aligned_slices[i.first].clear(); }

    bool clear_i = true;
    for (auto &i : aligned_slices) {
        if (!i.second.empty()) {
            clear_i = false;
            break; } }

    if (clear_i == true)
        aligned_slices.clear();

    // update groups with empty containers
    std::list<PHV_MAU_Group *> phv_groups = PHV_groups_i;
    if (&aligned_slices != &aligned_container_slices_i)
        phv_groups = T_PHV_groups_i;

    ordered_set<PHV_MAU_Group *> phv_groups_remove;
    for (auto &g : phv_groups) {
        g->empty_containers() = 0;
        for (auto &c : g->phv_containers()) {
            if (c->status() == PHV_Container::Container_status::EMPTY)
                g->inc_empty_containers(); }
        if (g->empty_containers() == 0)
            phv_groups_remove.insert(g); }

    for (auto &g : phv_groups_remove)
        phv_groups.remove(g);

    // update correct state for aligned slices in all groups
    create_aligned_container_slices();

    // sanity check after correct state for aligned slices so that container ranges are correct
    sanity_check_container_avail("container_pack_cohabit ()..");

    // Log new fields allocated and the current state of the containers (free,
    // partially allocated, full).
    dump_new_placements(msg);
}


void PHV_MAU_Group_Assignments::consolidate_slices_in_group(
    ordered_map<int,
    ordered_map<int,
    std::list<std::list<PHV_MAU_Group::Container_Slice *>>>>& aligned_slices) {
    //
    // consolidate to get larger number same width only when all aligned and same MAU group
    // [3](2)*2 ((PHV-149<3>{8..10}, PHV-147), (PHV-145<3>{8..10}, PHV-151)) ==> [3](4)*1
    //
    for (auto w : aligned_slices) {
        for (auto n : w.second) {
            if (n.second.size() > 1) {
                //
                // multiple sets in set of sets
                // attempt to consolidate only within same MAU group
                //
                ordered_map<PHV_MAU_Group *,
                ordered_map<int, std::list<std::list<PHV_MAU_Group::Container_Slice *>>>> g_lo;
                for (auto &cc_set : n.second) {
                    PHV_Container *c = (*(cc_set.begin()))->container();
                    int lo = (*(cc_set.begin()))->lo();
                    g_lo[c->phv_mau_group()][lo].push_back(cc_set);
                }
                // all elements of g_lo[g][lo] must be used for aligned_slices[w][n]
                //
                aligned_slices[w.first].erase(n.first);
                for (auto &g : g_lo) {
                    for (auto &l : g.second) {
                        if (l.second.size() > 1) {
                            //
                            // make a composite set from all sets in l.second
                            //
                            auto* set_u = new std::list<PHV_MAU_Group::Container_Slice *>;
                            for (auto &cc_set : l.second) {
                                for (auto &cc : cc_set) {
                                    set_u->push_back(cc);
                                }
                            }
                            aligned_slices[w.first][set_u->size()].push_back(*set_u);
                        } else {
                            //
                            // use existing singleton set
                            //
                            aligned_slices[w.first][n.first].push_back(*(l.second.begin()));
                        }
                    }
                }
            }
        }
    }
}  // consolidate_slices_in_group

bool
PHV_MAU_Group_Assignments::canonicalize_cc_set(
    Cluster_PHV *cl,
    std::list<PHV_MAU_Group::Container_Slice *>& cc_set) {
    //
    // return true if non bridge metadata field will be mapped to deparsed container
    //
    assert(cl);
    assert(cc_set.size() >= cl->cluster_vec().size());
    //
    size_t metadata_fields = 0;
    for (auto &f : cl->cluster_vec()) {
        if (f->metadata && !f->bridged) {
            metadata_fields++;
        }
    }
    if (!metadata_fields) {  // no metadata fields
        return false;
    }
    size_t deparsed_containers = 0;
    for (auto &cc : cc_set) {
        if (cc->container()->deparsed()) {
            deparsed_containers++;
        }
    }
    if (!deparsed_containers) {  // no deparsed containers
        return false;
    }
    // attempt reorder cc_set to match metadata fields to non-deparsed containers
    // packing: if cc_set > cl size, cc_set horizontally sliced @equality, bottom slice contains cl
    // sort cc_set, non-deparsed containers congregating to the end
    //
    if (cc_set.size() - deparsed_containers > metadata_fields) {
        cc_set.sort([](PHV_MAU_Group::Container_Slice *l, PHV_MAU_Group::Container_Slice *r) {
            if (l->container()->deparsed() && r->container()->deparsed()) {
                // sort by container_id to prevent non-determinism
                return l->container()->container_id() < r->container()->container_id();
            }
            if (l->container()->deparsed() && !r->container()->deparsed()) {
                return true;
            }
            if (!l->container()->deparsed() && r->container()->deparsed()) {
                return false;
            }
            // sort by container_id to prevent non-determinism
            return l->container()->container_id() < r->container()->container_id();
        });
        LOG4("..........Reordered non-deparsed containers to end ("
             << cc_set.size()
             << ").........."
             << cc_set
             << std::endl);
        //
        // sort cluster fields s.t. metadata fields are towards end to map non-deparsed containers
        // e.g., {f1, f2, fmeta1, fmeta2} => {Cdeparsed1, Cdeparsed2, .. CNon_deparsed1, CNon2 ..}
        //
        std::sort(cl->cluster_vec().begin(), cl->cluster_vec().end(),
            [](PHV::Field *l, PHV::Field *r) {
            bool l_meta = l->metadata && !l->bridged;
            bool r_meta = r->metadata && !r->bridged;
            if (!l_meta && !r_meta) {
                // sort by field id to prevent non-determinism
                return l->id < r->id;
            }
            if (!l_meta && r_meta) {
                return true;
            }
            if (l_meta && !r_meta) {
                return false;
            }
            // sort by field id to prevent non-determinism
            return l->id < r->id;
        });
        //
        return false;
    }
    //
    return true;
}  // canonicalize_cc_set

bool
PHV_MAU_Group_Assignments::num_containers_bottom_bits(
    Cluster_PHV *cl,
    std::list<PHV_MAU_Group::Container_Slice *>& cc_set,
    int num_c) {
    //
    // return true if there are num_c containers with bottom bits available
    //
    assert(cl);
    assert(num_c);
    //
    int containers_bottom_avail = 0;
    for (auto &cc : cc_set) {
        if (!cc->lo()) {
            containers_bottom_avail++;
        }
    }
    if (!containers_bottom_avail) {  // no such containers
        return false;
    }
    // attempt reorder cc_set
    // packing: if cc_set > cl size, cc_set horizontally sliced @equality, bottom slice contains cl
    // sort cc_set, containers w/ bottom bits available congregating to the end
    //
    if (containers_bottom_avail >= num_c) {
        cc_set.sort([](PHV_MAU_Group::Container_Slice *l, PHV_MAU_Group::Container_Slice *r) {
            if (l->lo() && r->lo()) {
                // sort by container_id to prevent non-determinism
                return l->container()->container_id() < r->container()->container_id();
            }
            if (l->lo() && !r->lo()) {
                return true;
            }
            if (!l->lo() && r->lo()) {
                return false;
            }
            // sort by container_id to prevent non-determinism
            return l->container()->container_id() < r->container()->container_id();
        });
        LOG4("..........Reordered bottom-bit containers to end ("
             << cc_set.size()
             << ").........."
             << cc_set
             << std::endl);
        //
        // sort cluster fields s.t. constrained fields (i.e., need bottom bits) are towards end
        // to map "bottom-bit available" containers
        // e.g., {f1, f2, fneed_b1, fneed_b2} => {CNo_bottom1, CNo_bottom2,..Cbottom_1, Cbottom_2..}
        //
        std::sort(cl->cluster_vec().begin(), cl->cluster_vec().end(),
            [](PHV::Field *l, PHV::Field *r) {
            if (!l->deparsed_bottom_bits() && !r->deparsed_bottom_bits()) {
                // sort by field id to prevent non-determinism
                return l->id < r->id;
            }
            if (!l->deparsed_bottom_bits() && r->deparsed_bottom_bits()) {
                return true;
            }
            if (l->deparsed_bottom_bits() && !r->deparsed_bottom_bits()) {
                return false;
            }
            // sort by field id to prevent non-determinism
            return l->id < r->id;
        });
        //
        return true;
    }
    //
    return false;
}  // num_containers_bottom_bits

std::pair<int, int>
PHV_MAU_Group_Assignments::gress(PHV_MAU_Group::Aligned_Container_Slices_t& aligned_slices) {
    //
    std::pair<int, int> gress_pair = {0, 0};  // count of ingress, egress
    for (auto &w : aligned_slices) {
        for (auto &n : w.second) {
            for (auto &l : n.second) {
                for (auto &cc : l) {
                    if (!cc->container()->gress())
                        continue;
                    switch (*(cc->container()->gress())) {
                      case INGRESS:
                        gress_pair.first++;
                        break;
                      case EGRESS:
                        gress_pair.second++;
                        break; } } } } }
    return gress_pair;
}

//
// container cohabit summary
// recommendations to TP phase
// avoid single write issue
// consider only containers that have more than 1 field each with mau_write
//

void PHV_MAU_Group_Assignments::container_cohabit_summary() {
    for (auto &gg : PHV_MAU_i) {
        // groups within this word size
        for (auto &g : gg.second) {
            for (auto &c : g->phv_containers()) {
                if (c->fields_in_container().size() > 1) {
                    int fields_written = 0;
                    for (auto &cc_s : Values(c->fields_in_container())) {
                       for (auto &cc : cc_s) {
                           if (cc->field()->mau_write()) {
                               fields_written++;
                           }
                       }
                    }
                    if (fields_written > 1) {
                        cohabit_fields_i.push_back(c);
                    }
                }
            }
        }
    }
}  // container_cohabit_summary


//***********************************************************************************
//
// Statistics
//
//***********************************************************************************

void
PHV_MAU_Group_Assignments::container_population_density(
    std::map<PHV::Size,
        std::map<PHV_Container::Container_status,
            std::pair<int, int>>>& c_bits_agg,
    bool phv) {
    //
    c_bits_agg.clear();
    //
    if (phv) {  // PHV
        for (auto &groups : PHV_MAU_i) {
            for (auto &g : groups.second) {
                ordered_map<PHV_Container::Container_status, std::pair<int, int>> c_bits;
                g->container_population_density(c_bits);
                for (auto &e : c_bits) {
                    c_bits_agg[g->width()][e.first].first += e.second.first;
                    c_bits_agg[g->width()][e.first].second += e.second.second;
                }
            }
        }
    } else {  // T_PHV
        for (auto &coll : T_PHV_i) {
            for (auto &m : coll.second) {
                for (auto &c : m.second) {
                    c_bits_agg[c->width()][c->status()].first++;
                    c_bits_agg[c->width()][c->status()].second += int(c->width()) - c->avail_bits();
                                                                                   // populated bits
                }
            }
        }
    }
    for (auto &e : c_bits_agg) {
        //
        // need to track 0 entries in map
        //
        ordered_set<PHV_Container::Container_status> status_not_covered;
        status_not_covered.insert(PHV_Container::Container_status::EMPTY);
        status_not_covered.insert(PHV_Container::Container_status::PARTIAL);
        status_not_covered.insert(PHV_Container::Container_status::FULL);
        //
        for (auto &e_s : e.second) {
            status_not_covered.erase(e_s.first);
        }
        for (auto &s : status_not_covered) {
            c_bits_agg[e.first][s] = {0, 0};
        }
    }  // for
}  // container_population_density

void
PHV_MAU_Group_Assignments::statistics(
    std::ostream &out,
    std::map<PHV::Size,
        std::map<PHV_Container::Container_status,
            std::pair<int, int>>>& c_bits_agg,
    const char *str) {
    int total_occupied_bits = 0;
    int total_occupied_containers = 0;
    for (auto &e : c_bits_agg) {
        int occupied_bits = 0;
        int occupied_containers = 0;
        out << str <<"<b" << e.first << "> ";
        for (auto &e_s : e.second) {
            out << "\t" << static_cast<char>(e_s.first)
                << " = #" << e_s.second.first << "," << e_s.second.second << "b";
            occupied_bits += e_s.second.second;
            if (e_s.first != PHV_Container::Container_status::EMPTY) {
                occupied_containers += e_s.second.first;
            }
        }
        out << "\t(#" << occupied_containers << "," << occupied_bits << "b)";
        out << std::endl;
        total_occupied_bits += occupied_bits;
        total_occupied_containers += occupied_containers;
    }
    int total_containers = 224;
    int total_bits = 4096;
    if (strcmp(str, "phv")) {
        total_containers /= 2;
        total_bits /= 2;
    }
    out << "\t\t" << str << "<#" << total_occupied_containers
        << "(" << total_occupied_containers * 100 / total_containers << "%)"
        << ", b" << total_occupied_bits << ">"
        << "(" << total_occupied_bits * 100 / total_bits << "%)"
        << std::endl;
}

void
PHV_MAU_Group_Assignments::statistics(std::ostream &out) {
    //
    // statistics
    //
    // to preserve order Full, Partial, Empty during output
    // do not want ordered_map / order of insertion
    //
    out << "....................PHV Containers Occupation Statistics................." << std::endl;
    out << "        F=Full, P=Partial, V=Vacant        " << std::endl;
    out << "        #Containers, Occupied bits        " << std::endl;
    out << "-------------------------------------------------------------------------" << std::endl;
    std::map<PHV::Size,
        std::map<PHV_Container::Container_status,
            std::pair<int, int>>> c_bits_agg;
    container_population_density(c_bits_agg /*, phv = true */);
    statistics(out, c_bits_agg, "phv");
    container_population_density(c_bits_agg, false /* t_phv */);
    statistics(out, c_bits_agg, "t_phv");
    out << "-------------------------------------------------------------------------" << std::endl;
}

//***********************************************************************************
//
// status
//
//***********************************************************************************


bool PHV_MAU_Group_Assignments::status(
        std::list<Cluster_PHV *>& clusters_to_be_assigned,
        const char *msg) {
    if (clusters_to_be_assigned.size() > 0) {
        if (LOGGING(4)) {
            ordered_map<gress_t, ordered_map<PHV::Size, int>> needed_containers;
            for (PHV::Size size : { PHV::Size::b8, PHV::Size::b16, PHV::Size::b32 }) {
                needed_containers[INGRESS][size] = 0;
                needed_containers[EGRESS][size] = 0; }

            int needed_bits = 0;
            for (auto &cl : clusters_to_be_assigned) {
                needed_containers[cl->gress()][cl->width()] += cl->num_containers();
                // needed_bits += cl->num_containers() * cl->width();
                needed_bits += cl->needed_bits(); }

            std::stringstream ss;
            for (auto &n_c : needed_containers) {
                for (auto &n : n_c.second) {
                    if (n.second) {
                        ss << " " << n.second
                           << "<" << n.first << "b>"
                           << static_cast<char>(n_c.first); } } }
            if (needed_bits)
                ss << " (bits=" << needed_bits << ");";
            std::string s = ss.str();
            LOG4(std::endl << "---------- Status: Clusters NOT Assigned ("
                << clusters_to_be_assigned.size()
                << ")"
                << s
                << "----------"
                << msg
                << std::endl
                << clusters_to_be_assigned); }
        return false;
    } else {
        LOG4(' ');
        LOG4("++++++++++++++++++++ Status: ALL clusters Assigned ++++++++++++++++++++" << msg);
        LOG4(' ');
        return true;
    }
}

bool PHV_MAU_Group_Assignments::status(
    PHV_MAU_Group::Aligned_Container_Slices_t& aligned_slices,
    const char *msg) {
    //
    if (aligned_slices.empty()) {
        LOG4("----------Status: NO Container Packs Available----------"
            << msg
            << std::endl);
        return false;
    } else {
        int bits_available = 0;
        for (auto &w : aligned_slices) {
            for (auto &n : w.second) {
                bits_available += w.first * n.first * n.second.size();
            }
        }
        LOG4("..........Status: Container Packs Available"
            << " ("
            << bits_available
            << " bits).........."
            << msg
            << std::endl
            << aligned_slices);
        return true;
    }
}

bool PHV_MAU_Group_Assignments::status(
    std::list<PHV_MAU_Group *>& phv_mau_groups,
    const char * /*msg*/) {
    //
    if (phv_mau_groups.empty()) {
        LOG4("----------Status: NO MAU Groups w/ empty Containers Available----------"
            << std::endl);
        return false;
    } else {
        LOG4("..........Status: MAU Groups w/ empty Containers Available.........."
            << phv_mau_groups);
        return true;
    }
}

//***********************************************************************************
//
// sanity checks PHV_MAU_Group
//
//***********************************************************************************

void PHV_MAU_Group::Container_Slice::sanity_check_container(const std::string& msg) {
    //
    const std::string msg_1 = msg+"PHV_MAU_Group::Container_Slice..";
    //
    container_i->sanity_check_container_avail(this->lo(), this->hi(), msg_1);
}

void PHV_MAU_Group::sanity_check_container_packs(const std::string& msg) {
    //
    // for all aligned container_packs in MAU Group
    // check width of each slice
    // check only one slice range per map[w][n]
    //
    for (auto w : aligned_container_slices_i) {
        for (auto n : w.second) {
            for (auto cc_set : n.second) {
                // for all members check width and range lo .. hi
                // also check all containers belong to the same gress
                //
                ordered_set<int> lo;
                ordered_set<int> hi;
                // lo.clear();
                // hi.clear();
                ordered_set<boost::optional<gress_t>> gress;
                for (auto cc : cc_set) {
                    if (cc->width() != w.first) {
                        LOG1(
                           "*****cluster_phv_mau.cpp:sanity_FAIL*****cluster_pack width differs .."
                               << w.first
                               << " vs "
                               << cc
                               << ' '
                               << msg);
                    }
                    lo.insert(cc->lo());
                    hi.insert(cc->hi());
                    //
                    gress.insert(cc->container()->gress());
                }
                if (lo.size() != 1) {
                    LOG1("*****cluster_phv_mau.cpp:sanity_FAIL*****cluster_pack"
                           << ".....lo differs ....."
                            << '['
                            << w.first
                            << "]["
                            << n.first
                            << ' '
                            << msg);
                }
                if (hi.size() != 1) {
                    LOG1("*****cluster_phv_mau.cpp:sanity_FAIL*****cluster_pack"
                           << ".....hi differs ....."
                           << '['
                           << w.first
                           << "]["
                           << n.first
                           << ' '
                           << msg);
                }
                if (gress.size() != 1) {
                    LOG1("*****cluster_phv_mau.cpp:sanity_FAIL*****cluster_pack"
                           << ".....gress differs ....."
                           << n.second
                           << std::endl
                           << "\t"
                           << msg);
                }
            }
        }
    }
}

void PHV_MAU_Group::sanity_check_container_fields_gress(const std::string& msg) {
    //
    // all fields contained in this container are gress compatible with container gress
    // all containers in group have the same gress
    //
    boost::optional<gress_t> g_gress = phv_containers_i.front()->gress();
    for (auto &c : phv_containers_i) {
        for (auto &cc_s : Values(c->fields_in_container())) {
            for (auto &cc : cc_s) {
                PHV::Field *field = cc->field();
                gress_t f_gress = field->gress;
                if (!c->gress() || (c->gress() && f_gress != *c->gress())) {
                    LOG1("*****cluster_phv_mau.cpp:sanity_FAIL***** "
                           << "field ~ container gress differ ..... "
                           << f_gress << " vs " << c->gress() << "..." << msg << c);
                }
            }
        }
        if (g_gress != c->gress()) {
            LOG1("*****cluster_phv_mau.cpp:sanity_FAIL***** "
                   << "MAU group ~ container gress differ ..... "
                   << g_gress
                   << " vs "
                   << c->gress()
                   << "..."
                   << msg
                   << c); } }
}

void PHV_MAU_Group::sanity_check_group_containers(
    const std::string& msg, bool check_deparsed) {
    //
    for (auto &w : aligned_container_slices_i) {
        for (auto &n : w.second) {
            for (auto &cc_set : n.second) {
                for (auto &cc : cc_set) {
                    cc->sanity_check_container(msg
                        + "PHV_MAU_Group::sanity_check_group_containers..");
                }
            }
        }
    }
    for (auto &c : phv_containers_i) {
        c->sanity_check_container(msg
           + "PHV_MAU_Group::sanity_check_group_containers phv_containers..",
           check_deparsed);
    }
}

//***********************************************************************************
//
// sanity checks PHV_MAU_Group_Assignments
//
//***********************************************************************************

void PHV_MAU_Group_Assignments::sanity_check_container_avail(const std::string& msg) {
    //
    const std::string msg_1 = msg+"PHV_MAU_Group_Assignments::sanity_check_container_avail..";
    //
    // check aligned_container_slices map agrees with container filling
    //
    for (auto &w : aligned_container_slices_i) {
        for (auto &n : w.second) {
            for (auto &cc_set : n.second) {
                for (auto &cc : cc_set) {
                    PHV_Container *c = cc->container();
                    c->sanity_check_container_avail(cc->lo(), cc->hi(), msg_1);
                    BUG_CHECK(cc->hi() >= cc->lo(),
                        "*****PHV_MAU_Group_Assignments::sanity_check_container_avail *****"
                        "PHV-%d, ranges[%d] = %d, should be %d",
                        c->container_id(), cc->lo(), c->ranges()[cc->lo()], cc->hi());
                    PHV_MAU_Group *g = c->phv_mau_group();
                    // container bits not yet fully assigned, premature to check_deparsed
                    g->sanity_check_group_containers(msg_1, false/*check_deparsed*/);
                    LOG4("~~~~~G"
                         << g->number()
                         <<":["
                         << w.first
                         << "]["
                         << n.first
                         << "]="
                         << cc_set);
                }
            }
        }
    }
}

void PHV_MAU_Group_Assignments::sanity_check_container_fields_gress(const std::string& msg) {
    for (auto groups : PHV_MAU_i) {
        for (auto g : groups.second) {
            g->sanity_check_container_fields_gress(msg);
        }
    }
}

void PHV_MAU_Group_Assignments::sanity_check_group_containers(
    const std::string& msg) {
    //
    // sanity check PHV_MAU_Group_Assignments aligned_container_slices with individual MAU Groups
    //
    for (auto &w : aligned_container_slices_i) {
        for (auto &n : w.second) {
            for (auto &cc_set : n.second) {
                PHV_Container *c = (*(cc_set.begin()))->container();
                PHV_MAU_Group *g = c->phv_mau_group();
                ordered_set<std::list<PHV_MAU_Group::Container_Slice *>> l_set;
                for (auto &l : g->aligned_container_slices()[w.first][n.first]) {
                    l_set.insert(l);
                }
                if (l_set.count(cc_set) != 1) {
                    LOG1("*****cluster_phv_mau.cpp:sanity_FAIL*****....."
                        << msg
                        << g
                        << " aligned_container_slices does not contain "
                        << cc_set);
                }
            }
        }
    }
    // sanity check individual MAU Groups aligned_container_slices
    // with composite PHV_MAU_Group_Assignments
    // for each MAU Group sanity check constituent containers
    //
    for (auto groups : PHV_MAU_i) {
        for (auto g : groups.second) {
            for (auto &w : g->aligned_container_slices()) {
                for (auto &n : w.second) {
                    for (auto &cc_set : n.second) {
                        ordered_set<std::list<PHV_MAU_Group::Container_Slice *>> l_set;
                        for (auto &l : aligned_container_slices_i[w.first][n.first]) {
                            l_set.insert(l);
                        }
                        if (l_set.count(cc_set) != 1) {
                            LOG1("*****cluster_phv_mau.cpp:sanity_FAIL*****....."
                                << msg
                                << " composite aligned_container_slices does not contain "
                                << cc_set
                                << " from "
                                << g);
                        }
                    }
                }
            }
            g->sanity_check_group_containers(msg);  // default true: check_deparsed
        }
    }
    // sanity check a field is not duplicately allocated
    // check spans all groups, containers
    // field can straddle containers but should not be allocated again, unless field-slice
    //
    ordered_map<PHV::Field *,
        ordered_set<PHV_Container::Container_Content *>> field_container_map;
    for (auto &groups : PHV_MAU_i) {
        for (auto &g : groups.second) {
            for (auto &c : g->phv_containers()) {
                for (auto &cc_s : Values(c->fields_in_container())) {
                    for (auto &cc : cc_s) {
                        PHV::Field *field = cc->field();
                        field_container_map[field].insert(cc);
                    }
                }
            }
        }
    }
    for (auto &entry : field_container_map) {
        auto field = entry.first;
        auto cc_s = entry.second;
        //
        // assert width allocated in container(s) matches field width
        // width will exceed when field duplicately allocated
        //
        int width_in_c = 0;
        for (auto &cc : cc_s) {
            width_in_c += cc->width();
        }
        int field_width = field->phv_use_width();
        if (field_width != width_in_c) {
            bool error = false;
            if (cc_s.size() > 1) {
                LOG1("*****cluster_phv_mau.cpp:sanity_FAIL*****");
                LOG1(msg);
                LOG1(".....field duplicated in containers.....");
                error = true;
            } else {
                if (!PHV_Container::constraint_no_cohabit(field)) {
                    if (field->ccgf_fields().size()) {
                        field_width = field->size;
                        if (field_width != width_in_c) {
                            //
                            LOG1("-----cluster_phv_mau.cpp:sanity_FAIL-----");
                            LOG1(msg);
                            LOG1(".....allocated space in container != ccgf field size.....");
                            error = true;
                        }
                    } else {
                        //
                        LOG1("-----cluster_phv_mau.cpp:sanity_WARN-----");
                        LOG1(msg);
                        LOG1(".....allocated space in container does not match field width.....");
                        LOG1(".....non-uniform? cluster.....");
                        error = true;
                    }
                }
            }
            if (error) {
                // LOG1(field);
                LOG1("width_in_c = " << width_in_c << ", phv_use_width = " << field_width << cc_s);
            }
        }
    }  // for
}  // sanity_check_group_containers

void PHV_MAU_Group_Assignments::sanity_check_T_PHV_collections(const std::string& msg) {
    //
    // sanity check T_PHV collections containers have same gress
    //
    for (auto &coll : T_PHV_i) {
        ordered_set<boost::optional<gress_t>> gress_set;
        for (auto &v : coll.second) {
            for (auto &c : v.second) {
                gress_set.insert(c->gress());
            }
        }
        if (gress_set.size() != 1) {
            LOG1("*****cluster_phv_mau.cpp:sanity_FAIL*****"
                    << msg
                    << ".....T_PHV Collection.....containers have differing gress....."
                    << coll.second);
        }
    }
}  // sanity_check_T_PHV_collections

void PHV_MAU_Group_Assignments::sanity_check_clusters_allocation(
    std::list<Cluster_PHV *>& clusters_p,
    bool allocated,
    const std::string& msg) {
    //
    for (auto &cl : clusters_p) {
        for (auto &f : cl->cluster_vec()) {
            if (allocated && f->phv_containers().empty()) {
                LOG1("*****cluster_phv_mau.cpp:sanity_FAIL*****"
                    << msg
                    << " ..... PHV NOT allocated .....");
                LOG1(cl);
                break;
            }
            if (!allocated && !f->phv_containers().empty()) {
                LOG1("*****cluster_phv_mau.cpp:sanity_FAIL*****"
                    << msg
                    << " ..... PHV IS allocated .....");
                LOG1(cl);
                break;
            }
        }
    }
}  // sanity_check_clusters_allocation(clusters, allocated, msg)

void PHV_MAU_Group_Assignments::sanity_check_clusters_allocation() {
    //
    // sanity check substratum clusters have fields that are PHV allocated
    //
    sanity_check_clusters_allocation(
        substratum_phv_clusters_i,
        true /* already allocated */,
        "Substratum PHV clusters");
    sanity_check_clusters_allocation(
        substratum_t_phv_clusters_i,
        true /* already allocated */,
        "Substratum T_PHV clusters");
    //
    // sanity check overlayable clusters have fields that are NOT PHV allocated
    //
    sanity_check_clusters_allocation(
        clusters_to_be_assigned_i,
        false /* NOT already allocated */,
        "Overlayable PHV clusters");
    sanity_check_clusters_allocation(
        clusters_to_be_assigned_nibble_i,
        false /* NOT already allocated */,
        "Overlayable PHV Nibble clusters");
    sanity_check_clusters_allocation(
        pov_fields_i,
        false /* NOT already allocated */,
        "Overlayable POV clusters");
    sanity_check_clusters_allocation(
        t_phv_fields_i,
        false /* NOT already allocated */,
        "Overlayable T_PHV clusters");
    sanity_check_clusters_allocation(
        t_phv_fields_nibble_i,
        false /* NOT already allocated */,
        "Overlayable T_PHV Nibble clusters");
}  // sanity_check_clusters_allocation()

//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//
// PHV_MAU_Group Container_Slice output
//
std::ostream &operator<<(std::ostream &out, PHV_MAU_Group::Container_Slice *c) {
    if (c)
        out << c->container() << c->container()->gress()
            << '<' << c->width() << '>' << '{' << c->lo() << ".." << c->hi() << '}';
    else
        out << "--cc--";
    return out;
}
//
// ordered_set
std::ostream &operator<<(
    std::ostream &out,
    ordered_set<PHV_MAU_Group::Container_Slice *>& slices) {
    out << '(';
    for (auto c : slices)
        if (c->container()->status() != PHV_Container::Container_status::FULL)
            out << c << ' ';
    out << std::endl << "\t)";
    return out;
}
//
// list
std::ostream &operator<<(
    std::ostream &out,
    std::list<PHV_MAU_Group::Container_Slice *>& slices_list) {
    out << '(';
    for (auto &cc : slices_list)
        if (cc->container()->status() != PHV_Container::Container_status::FULL)
            out << cc << ' ';
    out << ")";
    return out;
}
//
// list of list
std::ostream &operator<<(
    std::ostream &out,
    std::list<std::list<PHV_MAU_Group::Container_Slice *>>& slices_list_list) {
    out << '{';
    for (auto &slices_list : slices_list_list)
        out << slices_list << ',';
    out << std::endl << "\t}";
    return out;
}
//
//
std::ostream &operator<<(
    std::ostream &out,
    PHV_MAU_Group::Aligned_Container_Slices_t& all_container_packs) {
    // map[w][n] --> <set of <set of container_packs>>
    for (auto &w : all_container_packs)
        for (auto &n : w.second) {
            out << std::endl << "\t" << "[w" << w.first << "](n" << n.first << ')';
            if (n.second.size() > 1)
                out << '*' << n.second.size();
            out << std::endl << '\t';
            for (auto s : n.second)
                out << s; }
    out << std::endl;
    return out;
}
//
// phv_mau_group output
//
std::ostream &operator<<(std::ostream &out, PHV_MAU_Group &g) {
    //
    // mau group summary
    //
    out << 'G' << g.number() << "[w" << g.width() << ']';
    out << g.gress();
    if (g.empty_containers()) {
        out << "(V" << g.empty_containers() << ')';
    }
    // summarize packable containers
    ordered_set<PHV_Container *> containers_pack;
    for (auto c : g.phv_containers()) {
        if (c->status() != PHV_Container::Container_status::FULL) {
            containers_pack.insert(c);
        }
    }
    if (containers_pack.size()) {
        out << "\t{ ";
        for (auto c : containers_pack) {
            out << c << ' ';
        }
        out << "}";
    }
    // summarize container slice groups
    if (!g.aligned_container_slices().empty()) {
        for (auto w : g.aligned_container_slices()) {
            for (auto n : w.second) {
                out << std::endl << "\t" << "[w" << w.first << "](n" << n.first << ')' << std::endl;
                for (auto s : n.second) {
                    out << '\t' << s;
                }
            }
        }
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, PHV_MAU_Group *g) {
    //
    // mau group details
    //
    if (g) {
        out << *g << std::endl       // summary
            << g->phv_containers();  // details
    } else {
        out << "-g-";
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, std::list<PHV_MAU_Group *> &phv_mau_list) {
    out << std::endl;
    for (auto m : phv_mau_list) {
        // summary
        out << *m << std::endl;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<PHV_MAU_Group *> *phv_mau_vec) {
    out << '[';
    if (phv_mau_vec) {
        out << std::endl;
        for (auto g : *phv_mau_vec) {
           // mau group summary
           out << *g << std::endl;
        }
    } else {
        out << "-mgv-";
    }
    out << ']' << std::endl;
    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<PHV_MAU_Group *> &phv_mau_vec) {
    out << std::endl;
    out << "++++++++++ #mau_groups=" << phv_mau_vec.size() << " ++++++++++" << std::endl;
    for (auto m : phv_mau_vec) {
        out << std::endl;
        out << m;
    }
    out << std::endl;
    return out;
}

//
// phv_mau_group_assignments output
//

std::ostream &operator<<(
    std::ostream &out,
    ordered_map<PHV::Size, std::vector<PHV_Container *>>& coll) {
    //
    for (auto m : coll) {
        out << m.second;
    }
    out << std::endl;
    return out;
}

std::ostream &operator<<(
    std::ostream &out,
    ordered_map<PHV::Size, std::vector<PHV_MAU_Group *>>& phv_mau_map) {
    //
    for (auto &m : phv_mau_map) {
        out << m.second;
    }
    out << std::endl;
    return out;
}

std::ostream &operator<<(
    std::ostream &out,
    ordered_map<unsigned, ordered_map<PHV::Size, std::vector<PHV_Container *>>>&
        t_phv_mau_map) {
    //
    for (auto &m : t_phv_mau_map) {
        out << m.second;
    }
    out << std::endl;
    return out;
}

std::ostream &operator<<(std::ostream &out, PHV_MAU_Group_Assignments &phv_mau_grps) {
    //
    std::list<PHV::Field *> fields_not_fit;
    fields_not_fit.clear();
    for (auto &cl : phv_mau_grps.phv_clusters()) {
        for (auto &f : cl->cluster_vec()) {
            fields_not_fit.push_front(f);
        }
    }
    for (auto &cl : phv_mau_grps.phv_clusters_nibble()) {
        for (auto &f : cl->cluster_vec()) {
            fields_not_fit.push_front(f);
        }
    }
    for (auto &cl : phv_mau_grps.pov_clusters()) {
        for (auto &f : cl->cluster_vec()) {
            fields_not_fit.push_front(f);
        }
    }
    for (auto &cl : phv_mau_grps.t_phv_clusters()) {
        for (auto &f : cl->cluster_vec()) {
            fields_not_fit.push_front(f);
        }
    }
    for (auto &cl : phv_mau_grps.t_phv_clusters_nibble()) {
        for (auto &f : cl->cluster_vec()) {
            fields_not_fit.push_front(f);
        }
    }
    out << "Begin+++++++++++++++++++++++++ PHV MAU Group Assignments ++++++++++++++++++++++++++++++"
        << std::endl;
    if (fields_not_fit.size()) {
        fields_not_fit.sort([](const PHV::Field *l, const PHV::Field *r) {
            return l->id < r->id;
        });
        std::string detailed_string =
              " ****************************** Clusters NOT Fit ("
              "\n...PHV cluster\t= " + std::to_string(phv_mau_grps.phv_clusters().size())
            + "\n...PHV nibble\t= " + std::to_string(phv_mau_grps.phv_clusters_nibble().size())
            + "\n...POV cluster\t= " + std::to_string(phv_mau_grps.pov_clusters().size())
            + "\n...T_PHV cl_s\t= " + std::to_string(phv_mau_grps.t_phv_clusters().size())
            + "\n...T_PHV nibble\t= " + std::to_string(phv_mau_grps.t_phv_clusters_nibble().size())
            + "\n...Fields\t= " + std::to_string(fields_not_fit.size())
            + "\n) ******************************";
        out << "Begin"
            << detailed_string
            << std::endl
            << std::endl;
        out << fields_not_fit;
        out << "End"
            << detailed_string
            << std::endl
            << std::endl;
    } else {
        out << "++++++++++++++++++++++++++++++ ALL Fields FIT ++++++++++++++++++++++++++++++"
            << std::endl;
    }
    out << std::endl
        << "++++++++++++++++++++++++++++++ PHV Groups ++++++++++++++++++++++++++++++"
        << std::endl;
    //
    for (auto rit = phv_mau_grps.phv_mau_map().rbegin();
         rit != phv_mau_grps.phv_mau_map().rend();
         ++rit) {
        out << rit->second;
    }
    //
    out << std::endl
        << "++++++++++++++++++++++++++++++ T_PHV Collections ++++++++++++++++++++++++++++++"
        << std::endl;
    for (auto coll : phv_mau_grps.t_phv_map()) {
        out << std::endl << "Collection" << coll.first;
        out << coll.second;
    }
    //
    out << std::endl
        << "++++++++++ Container Cohabit Summary .....("
        << phv_mau_grps.cohabit_fields().size()
        << ")..... ++++++++++"
        << std::endl
        << std::endl;
    for (auto cof : phv_mau_grps.cohabit_fields()) {
        out << '<' << cof->fields_in_container().size() << ':' << *cof << std::endl;
        out << '>' << std::endl;
    }
    //
    phv_mau_grps.statistics(out);
    //
    out << "End+++++++++++++++++++++++++ PHV MAU Group Assignments ++++++++++++++++++++++++++++++"
        << std::endl;
    return out;
}
