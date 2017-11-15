#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/sequential_vertex_coloring.hpp>
#include <iomanip>
#include "bf-p4c/phv/cluster_to_cluster_interference.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/log.h"
#include "lib/stringref.h"

const IR::Node *
Cluster_Interference::apply_visitor(const IR::Node *node, const char *name) {
    LOG1("..........Cluster_Interference::apply_visitor()..........");
    if (name)
        LOG1(name);

    reduce_clusters(phv_requirements_i.cluster_phv_fields(), "phv");

    reduce_clusters(phv_requirements_i.t_phv_fields(), "t_phv");

    LOG3(*this);
    return node;
}

ordered_map<int, std::vector<Cluster_PHV*>>
Cluster_Interference::find_overlay(std::vector<Cluster_PHV *> clusters) {
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
    // BGL Proprety Map: maps vertices to slices.
    boost::iterator_property_map<Cluster_PHV **, vertex_index_map>
        cluster_map(&clusters.front(), boost::get(boost::vertex_index, g));

    // Add vertices.
    std::size_t i = 0;
    for (auto *cl : clusters) {
        Vertex v = boost::add_vertex(i++, g);
        cluster_map[v] = cl; }

    // Add interference edges.
    GraphTraits::vertex_iterator v, vend;
    for (boost::tie(v, vend) = boost::vertices(g); v != vend; ++v) {
        GraphTraits::vertex_iterator v2, vend2;
        for (boost::tie(v2, vend2) = boost::vertices(g); v2 != vend2; ++v2) {
            Cluster_PHV *cl1 = cluster_map[*v];
            Cluster_PHV *cl2 = cluster_map[*v2];
            if (cl1 == cl2)
                continue;
            if (!mutually_exclusive(cl1, cl2))
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
    ordered_map<int, std::vector<Cluster_PHV*>> rv;
    for (boost::tie(v, vend) = boost::vertices(g); v != vend; ++v) {
        int vreg = static_cast<int>(color[*v]);
        Cluster_PHV *cl = cluster_map[*v];

        LOG3("CLUSTER " << cl->id() << " ASSIGNED VREG " << vreg);

        rv[vreg].push_back(cl); }
    return rv;
}

std::vector<Cluster_PHV*> Cluster_Interference::do_intercluster_overlay(
    const ordered_map<int, std::vector<Cluster_PHV*>> reg_map) {
    std::vector<Cluster_PHV*> owners;

    // For each set of clusters that can be overlaid, find the cluster
    // with the largest number of member fields and
    // make it the owner.  Then add the rest to its overlay map.
    LOG3("..........Inter Cluster Overlays..........");
    for (auto kv : reg_map) {
        if (kv.second.size() == 0)
            continue;

        // Find the owner.
        auto it = std::max_element(kv.second.begin(), kv.second.end(),
            [&](const Cluster_PHV *cl1, const Cluster_PHV *cl2) {
                return cl1->cluster_vec().size() < cl2->cluster_vec().size(); });
        Cluster_PHV *owner = *it;
        owners.push_back(owner);

        // Add other clusters to owner's overlay set.
        if (kv.second.size() > 1)
            LOG3("...substratum owner " << owner->id());
        // sort in decreasing order of #fields in cluster
        // cl1={f11}, cl2={f21,f22}, cl3={f31,f32};
        // f11---f21, f11 mutex f22, f21 mutex f31, f22 mutex f32, f11 mutex f31, f11 mutex f32
        // cl1 mutex cl2 mutex cl3
        // without sorting, f11 overlay f31, f21 conflicts f11/f31 => cl2--cl3
        // with sorting, f21/f31, f22/f32, f11/f22/f32
        // c1l mutex cl2 mutex cl3
        // this sorting order is used to associate overlay fields to substratum fields
        // via the final call to mutual_exclusive(...... seal_deal = true)
        std::sort(kv.second.begin(), kv.second.end(), [](Cluster_PHV *l, Cluster_PHV *r) {
            return l->cluster_vec().size() > r->cluster_vec().size(); });
        for (auto *cl : kv.second) {
            if (cl == owner)
                continue;
            owner->cluster_overlay_vec().push_back(cl);
            cl->overlay_substratum(owner);
            LOG3("......overlay " << cl->id()); } }

    return owners;
}

void Cluster_Interference::reduce_clusters(
    std::vector<Cluster_PHV*> &clusters,
    const std::string &msg) {
    LOG3("....Begin: Cluster_Interference::reduce_clusters() = " << clusters.size() << "  " << msg);

    // Produce `reg_map`, which maps each virtual container to the clusters
    // overlaid on it.
    ordered_map<int, std::vector<Cluster_PHV*>> reg_map = find_overlay(clusters);

    // Assign the widest cluster as owner of each virtual group and update
    // the owner's cluster_overlay_vec.
    // the original vector of clusters is now reduced
    clusters = do_intercluster_overlay(reg_map);

    // Verify that clusters selected to be overlaid are, in fact, mutually
    // exclusive.
    sanity_check_overlay_maps(clusters, "Cluster_Interference::reduce_cluster()");

    // overlay fields are associated with substratum fields
    // performed after sanity_check_overlay_maps()
    // to avoid matching cl's fields already inserted in owner fields' field_overlay_map
    for (auto owner : clusters)
        for (auto cl : owner->cluster_overlay_vec())
            mutually_exclusive(owner, cl, true /* associate substratum-overlay fields */);
    LOG3("....End: Cluster_Interference::reduce_clusters() = " << clusters.size() << "  " << msg);
}

bool Cluster_Interference::mutually_exclusive(Cluster_PHV *cl1, Cluster_PHV *cl2, bool seal_deal) {
    // check if possible to get a mapping of all fields in cl1 mutual exclusive to fields in cl2
    // if both clusters have exact container requirements, their container widths must match
    if (cl1->exact_containers() && cl2->exact_containers() && cl1->width() != cl2->width())
        return false;
    // consider the largest cluster as substratum and the other as overlay
    Cluster_PHV *cl_s = nullptr;
    Cluster_PHV *cl_o = nullptr;
    if (cl1->num_containers() * int(cl1->width()) >= cl2->num_containers() * int(cl2->width())) {
        cl_s = cl1;
        cl_o = cl2;
    } else {
        cl_s = cl2;
        cl_o = cl1; }
    // copy of substratum_fields as list changes
    std::list<PHV::Field *> substratum_fs(cl_s->cluster_vec().begin(), cl_s->cluster_vec().end());
    std::map<PHV::Field *, int> substratum_containers;
    for (auto *f_s : substratum_fs)
        substratum_containers[f_s] = cl_s->num_containers(f_s);
    std::map<PHV::Field *, std::map<int, PHV::Field *>> f_s_f_o_map;  // map[f_s][c] = f_o
    int o_fields_to_map = cl_o->cluster_vec().size();
    for (auto* f_o : cl_o->cluster_vec()) {
        PHV::Field *remove_field = 0;
        for (auto* f_s : substratum_fs) {
            if (phv_interference_i.mutually_exclusive(f_o, f_s)) {
                int container_index = cl_s->num_containers(f_s) - substratum_containers[f_s] + 1;
                BUG_CHECK(container_index > 0 && container_index <= cl_s->num_containers(f_s),
                    "....cluster_to_cluster_interference: container_index %1% not 1..%2%, f = %3%",
                    cl_s->num_containers(f_s), f_s);
                f_s_f_o_map[f_s][container_index] = f_o;
                o_fields_to_map--;
                substratum_containers[f_s]--;  // this container unavailable for next f_o
                if (substratum_containers[f_s] <= 0)
                    remove_field = f_s;
                break; } }
        if (remove_field)
            // other fields in cl_o can no longer use f_o/f_s' positions
            substratum_fs.remove(remove_field); }
    if (o_fields_to_map) {
        // could not map all fields
        BUG_CHECK(seal_deal == false,
            "Overlaid clusters incorrect inference mutually exclusive %1%, %2%",
            cl1->id(), cl2->id());
        return false;
    } else if (seal_deal) {
        // associate f_o fields to f_s in f_s field_overlay_map
        for (auto e1 : f_s_f_o_map) {
            PHV::Field *f_s = e1.first;
            for (auto e2 : e1.second) {
                int r = e2.first;
                PHV::Field *f_o = e2.second;
                // Add f_o to f_s's overlay set.
                f_s->field_overlay_map(f_o, r, false /*virtual register*/);
                // f_o may have overlay fields from intra-cluster interference
                // transfer those to f_s
                if (f_o->field_overlay_map().count(-r)) {
                    for (auto* f_o_ov : *(f_o->field_overlay_map()[-r]))
                        f_s->field_overlay_map(f_o_ov, r, false /*virtual register*/); }
                f_o->field_overlay_map().erase(-r); } } }
    return true;
}

//***********************************************************************************
//
// sanity checks
//
//***********************************************************************************

void Cluster_Interference::sanity_check_overlay_maps(
    std::vector<Cluster_PHV*> owners,
    const std::string& base) {
    const std::string msg = base+"Cluster_Interference::sanity_check_overlay_maps";

    // overlaid cluster's substratum has overlaid cluster as element in its cluster_overlay_vec
    ordered_map<int, Cluster_PHV*> reg_owner;
    for (auto *owner : owners)
        for (auto &cl_o : owner->cluster_overlay_vec())
            if (cl_o->overlay_substratum() != owner || cl_o->cluster_overlay_vec().size())
                LOG1("*****cluster_to_cluster_interference:sanity_FAIL*****" << msg
                    << ".......... cluster substratum / overlay inconsistent ....."
                    << "\t" << owner << "\t" << cl_o);

    // Overlaid clusters are mutually exclusive.
    for (auto *owner : owners) {
        for (auto cl1 : owner->cluster_overlay_vec()) {
                BUG_CHECK(mutually_exclusive(cl1, owner),
                    "Overlaid clusters not mutually exclusive %1%, %2%", owner->id(), cl1->id());
                for (auto cl2 : owner->cluster_overlay_vec()) {
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

std::ostream &operator<<(std::ostream &out, ordered_map<int, Cluster_PHV*>& reg_map) {
    for (auto &r : reg_map) {
        out << "\treg[" << r.first << "] --> "
            << r.second
            << std::endl;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out, Cluster_Interference &cluster_interference) {
    out << std::endl
        << "Begin ++++++++++++++++++++ Cluster Interference ++++++++++++++++++++"
        << std::endl
        << std::endl;
    out << cluster_interference.phv_requirements();
    out << std::endl
        << "End ++++++++++++++++++++ Cluster Interference ++++++++++++++++++++"
        << std::endl
        << std::endl;
    return out;
}
