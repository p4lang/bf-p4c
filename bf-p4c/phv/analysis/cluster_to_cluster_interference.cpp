#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/sequential_vertex_coloring.hpp>
#include <iomanip>
#include "bf-p4c/phv/make_clusters.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/analysis/cluster_to_cluster_interference.h"
#include "lib/log.h"
#include "lib/stringref.h"

const IR::Node *
Cluster_Interference::apply_visitor(const IR::Node *node, const char *name) {
    LOG1("..........Cluster_Interference::apply_visitor()..........");
    if (name)
        LOG1(name);

    // include both phv clusters and t_phv clusters for interference computation
    std::vector<PHV::AlignedCluster*> clusters;
    for (auto s_cl : clustering_i.cluster_groups())
        for (auto r_cl : s_cl->clusters())
            for (auto a_cl : r_cl->clusters())
                clusters.push_back(a_cl);

    // reduce_clusters populates clusters_i .. Substratum S1,Overlay O11,O12,S2,O21,O22,O23,S3 ...
    reduce_clusters(clusters, "phv+t_phv");

    LOG3(*this);
    return node;
}

ordered_map<int, std::vector<PHV::AlignedCluster*>>
Cluster_Interference::find_overlay(std::vector<PHV::AlignedCluster *> clusters) {
    // Define the BGL graph.
    typedef boost::adjacency_list<
        boost::setS,            // No duplicate edges
        boost::vecS,
        boost::undirectedS,     // Undirected edges
        boost::property<boost::vertex_index_t, std::size_t>,
        boost::no_property      // No edge labels
        > Graph;
    typedef typename boost::graph_traits<Graph> GraphTraits;
    typedef typename GraphTraits::vertex_descriptor Vertex;
    typedef typename boost::graph_traits<Graph>::vertices_size_type vertices_size_type;
    typedef typename boost::property_map<Graph, boost::vertex_index_t>::const_type
        vertex_index_map;

    Graph g;
    // BGL Property Map: maps vertices to slices.
    boost::iterator_property_map<PHV::AlignedCluster **, vertex_index_map>
        cluster_map(&clusters.front(), boost::get(boost::vertex_index, g));

    // Add vertices.
    std::size_t i = 0;
    for (auto* cl : clusters) {
        Vertex v = boost::add_vertex(i++, g);
        cluster_map[v] = cl; }

    // Add interference edges.
    GraphTraits::vertex_iterator v, vend;
    for (boost::tie(v, vend) = boost::vertices(g); v != vend; ++v) {
        GraphTraits::vertex_iterator v2, vend2;
        for (boost::tie(v2, vend2) = boost::vertices(g); v2 != vend2; ++v2) {
            PHV::AlignedCluster *cl1 = cluster_map[*v];
            PHV::AlignedCluster *cl2 = cluster_map[*v2];
            if (cl1 == cl2)
                continue;
            if (!can_overlay(cl1, cl2))
                // Clusters interfere
                boost::add_edge(*v, *v2, g); } }

    // Build smallest-last vertex ordering for greedy vertex coloring.
    // TODO: Use better heuristic?
    boost::tie(v, vend) = boost::vertices(g);
    std::vector<Vertex> order_vec(v, vend);
    std::sort(order_vec.begin(), order_vec.end(), [&](Vertex v1, Vertex v2) {
        return boost::out_degree(v1, g) > boost::out_degree(v2, g); });

    // Do vertex coloring; output `color`.
    auto order =
        boost::make_iterator_property_map(
            order_vec.begin(),
            boost::identity_property_map(),
            GraphTraits::null_vertex());
    std::vector<vertices_size_type> color_vec(boost::num_vertices(g));
    boost::iterator_property_map<vertices_size_type*, vertex_index_map>
        color(&color_vec.front(), boost::get(boost::vertex_index, g));
    boost::sequential_vertex_coloring(g, order, color);

    // Build a color->cluster map to return.  (Colors are "virtual mau groups.")
    //
    ordered_map<int, std::vector<PHV::AlignedCluster*>> rv;
    for (boost::tie(v, vend) = boost::vertices(g); v != vend; ++v) {
        int vreg = static_cast<int>(color[*v]);
        PHV::AlignedCluster *cl = cluster_map[*v];

        LOG3("CLUSTER " << cl->id() << " ASSIGNED VREG " << vreg);

        rv[vreg].push_back(cl); }
    return rv;
}

std::list<PHV::AlignedCluster*> Cluster_Interference::do_intercluster_overlay(
    const ordered_map<int, std::vector<PHV::AlignedCluster*>> reg_map) {
    std::list<PHV::AlignedCluster*> owners;

    // For each set of clusters that can be overlaid, find the cluster
    // with the largest number of member fields and
    // make it the owner.  Then add the rest to its overlay map.
    // when overlaid clusters comprise phv and tphv clusters, substratum is always a phv cluster
    // because a tphv cluster can be overlaid on phv but not vice-versa
    LOG3("..........Inter Cluster Overlays..........");
    for (auto kv : reg_map) {
        if (kv.second.size() == 0)
            continue;

        // Find the owner.
        // if both phv and tphv clusters present owner is largest phv cluster
        // sort in decreasing order of #fields in cluster
        // cl1={f11}, cl2={f21,f22}, cl3={f31,f32};
        // f11---f21, f11 mutex f22, f21 mutex f31, f22 mutex f32, f11 mutex f31, f11 mutex f32
        // cl1 mutex cl2 mutex cl3
        // without sorting, f11 overlay f31, f21 conflicts f11/f31 => cl2--cl3
        // with sorting, f21/f31, f22/f32, f11/f22/f32
        // c1l mutex cl2 mutex cl3
        // this sorting order is necessary to associate overlay fields to substratum fields
        std::sort(kv.second.begin(), kv.second.end(),
            [](PHV::AlignedCluster *l, PHV::AlignedCluster *r) {
            if (l->aggregate_size() == r->aggregate_size())
                // when equal container bits, owner substratum must be phv cluster
                if (l->okIn(PHV::Kind::tagalong) != r->okIn(PHV::Kind::tagalong))
                    return !l->okIn(PHV::Kind::tagalong) && r->okIn(PHV::Kind::tagalong);
            return l->aggregate_size() > r->aggregate_size(); });
        // owner is first cluster
        // can_overlay() forbids t_phv owner of mixed clusters
        PHV::AlignedCluster *owner = *(kv.second.begin());
        owners.push_back(owner);

        // Add other clusters to owner's overlay set.
        if (kv.second.size() > 1)
            LOG3("...substratum owner " << owner->id());
        for (auto* cl : kv.second) {
            if (cl == owner)
                continue;
            this->substratum_overlay_i[owner].push_back(cl);
            LOG3("......overlay " << cl->id()); } }

    return owners;
}

void Cluster_Interference::reduce_clusters(
    std::vector<PHV::AlignedCluster*> clusters, const std::string &msg) {
    LOG3("....Begin: Cluster_Interference::reduce_clusters() = " << clusters.size() << "  " << msg);

    // sort clusters by decreasing container requirements to statically "weight" coloring process
    // e.g., 128b color affinity to 32b before 8b => regs 128b + 8b instead of 128b + 32b
    std::sort(clusters.begin(), clusters.end(), [](PHV::AlignedCluster *l, PHV::AlignedCluster *r) {
        if (l->aggregate_size() == r->aggregate_size())
            return l->max_width() > r->max_width();
        return l->aggregate_size() > r->aggregate_size(); });

    // Produce `reg_map`, which maps each virtual container to the clusters
    // overlaid on it.
    ordered_map<int, std::vector<PHV::AlignedCluster*>> reg_map = find_overlay(clusters);

    // Assign the widest cluster as owner of each virtual group and update
    // the owner's cluster_overlay_vec.
    // the original vector of clusters is now reduced
    std::list<PHV::AlignedCluster*> owners = do_intercluster_overlay(reg_map);
    // sort owners with greater overlay clusters before others
    owners.sort([this](PHV::AlignedCluster *l, PHV::AlignedCluster *r) {
        return this->substratum_overlay_i[l].size() > this->substratum_overlay_i[r].size(); });

    // Verify that clusters selected to be overlaid are, in fact, mutually exclusive.
    sanity_check_overlay_maps(owners, "Cluster_Interference::reduce_cluster()");

    // list of reduced clusters as Substratum1 Overlay11, Overlay12, S2,O21,O22 .....
    for (auto* owner : owners) {
        this->clusters_i.push_back(owner);                  // substratum cluster
        for (auto* cl : this->substratum_overlay_i[owner])  // overlay cluster
            this->clusters_i.push_back(cl); }

    LOG3("....End: Cluster_Interference::reduce_clusters() = " << clusters.size() << "  " << msg);
}

boost::optional<std::map<const PHV::Field *, std::map<int, const PHV::Field *>>>
Cluster_Interference::can_overlay(PHV::AlignedCluster *cl1, PHV::AlignedCluster *cl2) {
    // additional constraints to mutual exclusion that must be satisfied for overlay
    // if both clusters have exact container requirements, their container widths must match
    if (cl1->exact_containers() && cl2->exact_containers() && cl1->max_width() != cl2->max_width())
        return boost::none;
    // forbid t_phv substratum of mixed clusters, phv can't be overlaid in t_phv
    // also, larger t_phv cannot be overlaid on smaller phv
    if (cl1->okIn(PHV::Kind::tagalong) != cl2->okIn(PHV::Kind::tagalong)) {
        PHV::AlignedCluster *phv_cl = !cl1->okIn(PHV::Kind::tagalong) ? cl1 : cl2;
        PHV::AlignedCluster *t_phv_cl = !cl1->okIn(PHV::Kind::tagalong) ? cl2 : cl1;
        if (t_phv_cl->aggregate_size() > phv_cl->aggregate_size())
            return boost::none;
    }
    return mutually_exclusive(cl1, cl2);
}

static int num_containers(const PHV::Field *field) {
    return field->size / int(PHV::Size::b8) + (field->size % int(PHV::Size::b8) ? 1 : 0);
}

boost::optional<std::map<const PHV::Field *, std::map<int, const PHV::Field *>>>
Cluster_Interference::mutually_exclusive(PHV::AlignedCluster *cl1, PHV::AlignedCluster *cl2) {
    // check if possible to get a mapping of all fields in cl1 mutual exclusive to fields in cl2
    // consider the largest cluster as substratum and the other as overlay
    PHV::AlignedCluster *cl_substratum = nullptr;
    PHV::AlignedCluster *cl_overlay = nullptr;
    if (cl1->aggregate_size() >= cl2->aggregate_size()) {
        cl_substratum = cl1;
        cl_overlay = cl2;
    } else {
        cl_substratum = cl2;
        cl_overlay = cl1; }
    // copy of substratum_fields as list changed during overlay matching
    std::list<const PHV::Field *> substratum_fs;
    for (auto& slice : cl_substratum->slices())
        substratum_fs.push_back(slice.field());

    std::map<const PHV::Field *, int> substratum_containers;
    for (auto* f_s : substratum_fs)
        substratum_containers[f_s] = num_containers(f_s);

    // TODO:
    // assign a single overlaid field across multiple substratum fields
    // ensure that all fields of the overlaid cluster start at the same alignment

    // overlaying several fields on a single substratum is considered
    // each overlay field maps to a separate substratum container
    // map[f_s][c] = f_o
    std::map<const PHV::Field *, std::map<int, const PHV::Field *>> f_s_f_o_map;
    int o_fields_to_map = cl_overlay->slices().size();
    for (auto& slice : cl_overlay->slices()) {
        const PHV::Field* f_o = slice.field();
        const PHV::Field* remove_field = nullptr;
        for (auto* f_s : substratum_fs) {
            // f_o mutually exclusive with f_s
            // f_o container occupation <= f_s
            // TODO:
            // if f_o exceeds f_s containers, mutual exclusion w/ next substratum must be considered
            if (mutex_i(f_o->id, f_s->id)
                && f_o->size <= substratum_containers[f_s] * cl_substratum->max_width()) {
                int container_index = num_containers(f_s) - substratum_containers[f_s] + 1;
                BUG_CHECK(container_index > 0
                    && container_index <= num_containers(f_s),
                    "....cluster_to_cluster_interference: container_index %1% not 1..%2%, f = %3%",
                    num_containers(f_s), f_s);
                f_s_f_o_map[f_s][container_index] = f_o;
                o_fields_to_map--;
                substratum_containers[f_s]--;  // this container unavailable for next f_o
                if (substratum_containers[f_s] <= 0)
                    remove_field = f_s;
                break; } }
        if (remove_field)
            // other fields in cl_overlay can no longer use f_o/f_s positions
            substratum_fs.remove(remove_field); }
    if (o_fields_to_map)
        return boost::none;         // could not map all fields
    return std::move(f_s_f_o_map);  // can map all fields
}

//***********************************************************************************
//
// sanity checks
//
//***********************************************************************************

void Cluster_Interference::sanity_check_overlay_maps(
    std::list<PHV::AlignedCluster*>& owners,
    const std::string& base) {
    const std::string msg = base+"Cluster_Interference::sanity_check_overlay_maps";

    // Overlaid clusters are mutually exclusive.
    for (auto* owner : owners) {
        for (auto* cl1 : this->substratum_overlay_i[owner]) {
                BUG_CHECK(mutually_exclusive(cl1, owner),
                    "Overlay not mutually exclusive w/ owner %1%, %2%", owner->id(), cl1->id());
                for (auto* cl2 : this->substratum_overlay_i[owner]) {
                    if (cl1 == cl2)
                        continue;
                    BUG_CHECK(mutually_exclusive(cl1, cl2),
                        "Overlaid clusters not mutually exclusive %1%, %2%",
                        cl1->id(), cl2->id());}}}
}

//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//
//

std::ostream &operator<<(std::ostream &out, Cluster_Interference &cluster_interference) {
    out << std::endl << "Begin ++++++++++++++++++++ Cluster Interference ++++++++++++++++++++"
        << std::endl << std::endl;
    for (auto* cl : cluster_interference.clusters())
        out << cl;
    out << std::endl << "End ++++++++++++++++++++ Cluster Interference ++++++++++++++++++++"
        << std::endl << std::endl;
    return out;
}
