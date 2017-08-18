#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/sequential_vertex_coloring.hpp>
#include <iomanip>
#include "cluster_phv_interference.h"
#include "lib/log.h"
#include "lib/stringref.h"

const IR::Node *
PHV_Interference::apply_visitor(const IR::Node *node, const char *name) {
    LOG1("..........PHV_Interference::apply_visitor()..........");
    if (name)
        LOG1(name);

    reduce_clusters(phv_requirements_i.cluster_phv_fields(), "phv");
    reduce_clusters(phv_requirements_i.t_phv_fields(), "t_phv");

    LOG3(*this);
    return node;
}

ordered_set<PhvInfo::Field*> PHV_Interference::reduce_singleton_clusters(
    const ordered_map<PHV_Container::Ingress_Egress,
        ordered_map<int, std::vector<Cluster_PHV *>>> singletons,
    const std::string& msg) {
    LOG3("..........Begin: PHV_Interference::reduction_singleton_clusters().........." << msg);

    ordered_set<PhvInfo::Field*> singleton_owners;
    for (auto by_gress : singletons) {
        for (auto by_width : by_gress.second) {
            // Collect fields from singleton clusters with this gress/width.
            std::vector<PhvInfo::Field*> fields;
            for (auto cl : by_width.second)
                fields.insert(fields.end(), cl->cluster_vec().begin(), cl->cluster_vec().end());

            // Reduce.
            ordered_set<PhvInfo::Field*> owners = reduce_cluster(
                fields,
                by_width.first,
                msg + "_" + PHV_Container::Container_Content::Pass::Aggregate);
            singleton_owners.insert(owners.begin(), owners.end()); } }

    LOG3("..........End: PHV_Interference::reduction_singleton_clusters().........." << msg);
    return singleton_owners;
}

/* Build a "field interference graph" for this cluster.  Field slices become
 * vertices, where each field is split by @cluster_width. An edge exists
 * between fields that are NOT mutually exclusive (and hence interfere with
 * each other and cannot be overlaid), as well as between slices of the same
 * field.
 *
 * After vertex coloring, vertices with the same color are fields that can be
 * overlaid.
 */
ordered_map<int, std::vector<PhvInfo::Field*>> PHV_Interference::find_overlay(
    int cluster_width,
    const std::vector<PhvInfo::Field *> cluster) {
    /* Split fields that are wider than the cluster_width into slices.  Slices
     * become vertices in place of their fields: if fields f1 and f2 interfere,
     * than all the slices of f1 interfere with all the slices of f2.  The
     * slices from the same field interfere with each other, which forces them
     * to be assigned different colors.
     */
    struct Slice {
        // Offset of this slice in the field.
        std::size_t idx;
        PhvInfo::Field *field;
        Slice(std::size_t idx, PhvInfo::Field *field) : idx(idx), field(field) { }
    };

    std::size_t num_slices = 0;
    ordered_map<PhvInfo::Field *, ordered_set<Slice *>> slices;
    for (auto f : cluster) {
        int num_containers =
            f->phv_use_width() / cluster_width + (f->phv_use_width() % cluster_width ? 1 : 0);
        for (std::size_t i : boost::irange(0, num_containers)) {
            num_slices++;
            slices[f].insert(new Slice(i, f)); } }

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
    // Backing vector for slice_map.
    std::vector<Slice*> slices_vec(num_slices);
    // BGL Proprety Map: maps vertices to slices.
    boost::iterator_property_map<Slice **, vertex_index_map>
        slice_map(&slices_vec.front(), boost::get(boost::vertex_index, g));

    // Add vertices.
    std::size_t i = 0;
    for (auto f : cluster) {
        for (auto *s : slices[f]) {
            Vertex v = boost::add_vertex(i++, g);
            slice_map[v] = s; } }

    // Add interference edges.
    GraphTraits::vertex_iterator v, vend;
    for (boost::tie(v, vend) = boost::vertices(g); v != vend; ++v) {
        GraphTraits::vertex_iterator v2, vend2;
        for (boost::tie(v2, vend2) = boost::vertices(g); v2 != vend2; ++v2) {
            Slice *s1 = slice_map[*v];
            Slice *s2 = slice_map[*v2];
            if (s1 == s2)
                continue;
            if (s1->field == s2->field || !mutually_exclusive(s1->field, s2->field)) {
                // Slices interfere if they are from fields that interfere, or
                // if they are from the same field.
                boost::add_edge(*v, *v2, g); } } }

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

    // Build a color->field map to return.  (Colors are "virtual containers.")
    //
    // Oddity: The rest of PHV allocation expects "colors" (i.e. virtual
    // containers) to be numbered negatively starting at -1, so colors need to
    // start at 1, not 0.
    ordered_map<int, std::vector<PhvInfo::Field*>> rv;
    for (boost::tie(v, vend) = boost::vertices(g); v != vend; ++v) {
        int vreg = static_cast<int>(color[*v]) + 1;
        auto f = slice_map[*v]->field;

        // Sanity check: ensure slices from the same field are not in the same virtual container
        if (std::find(rv[vreg].begin(), rv[vreg].end(), f) != rv[vreg].end()) {
            LOG3("digraph G {");
            // print colored vertices
            GraphTraits::vertex_iterator v2, vend2;
            for (boost::tie(v2, vend2) = boost::vertices(g); v2 != vend2; ++v2)
                LOG3("    \"" << slice_map[*v2]->field->name << "_" << slice_map[*v2]->idx <<
                     "\" [color=" << std::hex << "0x" << (color[*v2] * 64) << "];");
            // print edges
            GraphTraits::edge_iterator e, eend;
            for (boost::tie(e, eend) = boost::edges(g); e != eend; ++e) {
                auto source = slice_map[boost::source(*e, g)];
                auto target = slice_map[boost::target(*e, g)];
                LOG3("    \"" << source->field->name << "_" << source->idx <<
                     "\" -> \"" << target->field->name << "_" << target->idx << "\";");
            }
            LOG3("}");
            BUG("Two slices of the same field overlaid"); }
        LOG3("FIELD " << f->name << " ASSIGNED VREG " << vreg);

        rv[vreg].push_back(f); }
    return rv;
}

ordered_set<PhvInfo::Field*> PHV_Interference::do_intracluster_overlay(
    const ordered_map<int, std::vector<PhvInfo::Field*>> reg_map) {
    ordered_set<PhvInfo::Field*> owners;

    // For each set of fields that can be overlaid, find the widest and
    // make it the owner.  Then add the rest to its overlay map.
    for (auto kv : reg_map) {
        if (kv.second.size() == 0)
            continue;

        // Find the owner.
        auto it = std::max_element(kv.second.begin(), kv.second.end(),
            [&](const PhvInfo::Field *f1, const PhvInfo::Field *f2) {
                return f1->phv_use_width() < f2->phv_use_width(); });
        PhvInfo::Field *owner = *it;
        owners.insert(owner);

        // Add other fields to owner's overlay set.
        for (auto f : kv.second) {
            if (f == owner)
                continue;
            owner->field_overlay_map(f, kv.first, false /*virtual register*/);

            /* Non-owner fields are later removed from their clusters (see
             * `reduce_clusters()`).  Rather than clearing their cluster ID, we
             * mangle the cluster ID string with all the fields overlaid
             * together, creating a new, fake cluster ID.
             *
             * For example, suppose we have a cluster with ID "phv_9" and
             * overlaid fields with IDs 1, 2, 3, and 4, with Field 1 being the
             * owner.  The new cluster ID for fields 2--4 would be:
             *
             *  "phv_9 ~1_2_3_4".
             *
             * (The '~' indicates that this change was introduced in the Field
             * Interference pass.)
             *
             * The `sanity_check_overlayed_fields()` method relies on this
             * mangling.
             */
            std::string pad("");
            if (f->cl_id().find(std::to_string(owner->id)) == std::string::npos) {
                pad += std::string(" ")
                       + PHV_Container::Container_Content::Pass::Field_Interference
                       + std::to_string(owner->id); }
            f->cl_id(f->cl_id() + pad + "_" + std::to_string(f->id)); } }

    return owners;
}

ordered_set<PhvInfo::Field*> PHV_Interference::reduce_cluster(
    const std::vector<PhvInfo::Field*> fields,
    int width,
    const std::string &msg) {
    LOG3(".........." << msg << ".....attempting to reduce.....");

    // Produce `reg_map`, which maps each virtual container to the fields
    // overlaid in it.
    ordered_map<int, std::vector<PhvInfo::Field*>> reg_map = find_overlay(width, fields);

    // Assign the widest field as owner of each virtual container and update
    // the owner field_overlay_map.
    ordered_set<PhvInfo::Field*> owners = do_intracluster_overlay(reg_map);

    // Verify that fields selected to be overlaid are, in fact, mutually
    // exclusive.
    sanity_check_overlay_maps(owners, "PHV_Interference::apply_visitor()");
    return owners;
}

void PHV_Interference::reduce_clusters(
    std::vector<Cluster_PHV *>& clusters,
    const std::string& msg) {
    LOG3("..........Begin: PHV_Interference::interference_reduction().........." << msg);

    ordered_map<PHV_Container::Ingress_Egress,
        ordered_map<int,
            std::vector<Cluster_PHV *>>> singletons;

    // Reduce each non-singleton cluster and gather singleton clusters.
    for (auto &cl : clusters) {
        // Gather singleton clusters by width and gress.
        if (cl->cluster_vec().size() == 1) {
            /* Do not attempt to overlay parser containers, as they must match
             * container width. CCGFs are considered as a unit, and so require
             * no special treatment.
             */
            if (!cl->exact_containers())
                singletons[cl->gress()][cl->max_width()].push_back(cl);
            continue; }

        // Reduce non-singleton clusters.
        ordered_set<PhvInfo::Field*> owners = reduce_cluster(cl->cluster_vec(), cl->width(), msg);

        // Recompute reduced cluster requirements.
        cl->cluster_vec().clear();
        cl->cluster_vec().insert(cl->cluster_vec().begin(), owners.begin(), owners.end());
        cl->compute_requirements(); }

    // Remove all singletons.
    for (auto by_gress : singletons)
        for (auto by_width : by_gress.second)
            for (auto *cl : by_width.second) {
                auto it = std::find(clusters.begin(), clusters.end(), cl);
                if (it != clusters.end())
                    clusters.erase(it); }

    // Try overlaying singleton clusters with the same width and gress.
    ordered_set<PhvInfo::Field*> singleton_owners = reduce_singleton_clusters(singletons, msg);

    // Add new clusters for singleton owners.
    for (auto f : singleton_owners) {
        std::string cl_id =
            PHV_Container::Container_Content::Pass::Field_Interference +
            std::string(1, PHV_Container::Container_Content::Pass::Aggregate);
        clusters.push_back(new Cluster_PHV(f, cl_id)); }

    LOG3("..........End: PHV_Interference::interference_reduction().........." << msg);
}

bool PHV_Interference::mutually_exclusive(PhvInfo::Field *f1, PhvInfo::Field *f2) {
    // NB: We use std::set here because ordered_set doesn't implement
    // `insert(Iterator first, Iterator last)`, and the order we check the
    // Cartesian product of two sets doesn't matter anyway.
    std::set<PhvInfo::Field *> f1_fields, f2_fields;

    // Get fields already overlaying f1 and f2.
    std::list<PhvInfo::Field *> f1_overlays, f2_overlays;
    f1->field_overlays(f1_overlays);
    f2->field_overlays(f2_overlays);

    // For all fields f in {f1} U f1_overlays, add f and all CCGF fields f owns
    // to f1_fields.  Do the same for {f2} U f2_overlays.
    f1_overlays.push_back(f1);
    f2_overlays.push_back(f2);
    for (auto f : f1_overlays) {
        f1_fields.insert(f);
        f1_fields.insert(f->ccgf_fields().begin(), f->ccgf_fields().end()); }
    for (auto f : f2_overlays) {
        f2_fields.insert(f);
        f2_fields.insert(f->ccgf_fields().begin(), f->ccgf_fields().end()); }

    // Check that all fields associated with `f1` are mutually exclusive with
    // all fields associated with `f2`.
    for (auto f1_x : f1_fields)
        for (auto f2_x : f2_fields)
            if (!mutex_i(f1_x->id, f2_x->id))
                return false;
    return true;
}

//***********************************************************************************
//
// sanity checks
//
//***********************************************************************************

void PHV_Interference::sanity_check_overlay_maps(
    ordered_set<PhvInfo::Field*> owners,
    const std::string& base) {
    const std::string msg = base+"PHV_Interference::sanity_check_overlay_maps";
    //
    // ownership in field_overlay_map has unique registers
    //
    ordered_map<int, PhvInfo::Field*> reg_owner;
    for (auto *owner : owners) {
        for (auto &reg_map : owner->field_overlay_map()) {
            int reg = reg_map.first;
            if (reg_owner.find(reg) != reg_owner.end()) {
                LOG1("*****cluster_phv_interference:sanity_FAIL*****" << msg);
                LOG1(".....[" << reg << "]..... has multiple owners .....");
                LOG1("\t" << reg_owner.at(reg));
                LOG1("\t" << owner);
            } else {
                reg_owner[reg] = owner;
            } } }
    //
    // Overlaid fields are mutually exclusive.
    //
    for (auto *owner : owners) {
        for (auto overlays_kv : owner->field_overlay_map()) {
            ordered_set<PhvInfo::Field *> &overlays = *overlays_kv.second;
            for (auto f1 : overlays) {
                BUG_CHECK(mutex_i(f1->id, owner->id),
                    "Overlaid fields not mutually exclusive");
                for (auto f2 : overlays) {
                    if (f1 == f2)
                        continue;
                    BUG_CHECK(mutex_i(f1->id, f2->id),
                        "Overlaid fields not mutually exclusive"); } } } }
}

//***********************************************************************************
//
// output stream <<
//
//***********************************************************************************
//
//

std::ostream &operator<<(std::ostream &out, ordered_map<int, PhvInfo::Field*>& reg_map) {
    for (auto &r : reg_map) {
        out << "\treg[" << r.first << "] --> "
            << r.second
            << std::endl;
    }
    return out;
}

std::ostream &operator<<(std::ostream &out,
    ordered_map<PHV_Container::Ingress_Egress,
        ordered_map<int,
            std::vector<Cluster_PHV *>>> &aggregates) {
    out << "Begin ....................Singleton cluster aggregates...................."
        << std::endl;
    for (auto &entry : aggregates) {
        out << '/' << entry.first << '/' << std::endl;
        for (auto &entry_2 : entry.second) {
            out << '\t' << '|' << entry_2.first << '|' << std::endl;
            for (auto &cl : entry_2.second) {
                out << "\t\t" << cl << std::endl;
            }
        }
    }
    out << "End ....................Singleton cluster aggregates...................."
        << std::endl;
    return out;
}

std::ostream &operator<<(std::ostream &out, PHV_Interference &phv_interference) {
    out << std::endl
        << "Begin ++++++++++++++++++++ PHV Interference ++++++++++++++++++++"
        << std::endl
        << std::endl;
    out << phv_interference.phv_requirements();
    out << std::endl
        << "End ++++++++++++++++++++ PHV Interference ++++++++++++++++++++"
        << std::endl
        << std::endl;
    return out;
}
