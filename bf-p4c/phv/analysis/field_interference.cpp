#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/sequential_vertex_coloring.hpp>

#include "bf-p4c/phv/analysis/field_interference.h"
#include "lib/log.h"

FieldInterference::FieldVector FieldInterference::getAllReferencedFields(
        std::vector<PHV::AlignedCluster*>& clusters,
        gress_t gress) {
    FieldVector rs;
    for (auto *cl : clusters) {
        for (auto *f : cl->fields()) {
            if (f->gress != gress) continue;
            if (std::find(rs.begin(), rs.end(), f) == rs.end())
                rs.push_back(f);
            field_to_cluster_map[f].insert(cl); } }
    return rs;
}

const IR::Node *
FieldInterference::apply_visitor(const IR::Node *node, const char *name) {
    LOG4("...............Field Interference apply visitor()................");
    if (name)
        LOG4(name);

    std::vector<PHV::AlignedCluster*> all_clusters;
    for (auto* cluster_group : clustering_i.cluster_groups())
        all_clusters.insert(all_clusters.end(), cluster_group->clusters().begin(),
                                                cluster_group->clusters().end());

    FieldVector ingress_fields = getAllReferencedFields(all_clusters, INGRESS);
    FieldVector egress_fields = getAllReferencedFields(all_clusters, EGRESS);

    ingress_overlays = constructFieldInterference(ingress_fields);
    egress_overlays = constructFieldInterference(egress_fields);

    LOG4("Ingress Overlays");
    printFieldColorMap(ingress_overlays);
    LOG4("Egress Overlays");
    printFieldColorMap(egress_overlays);

    return node;
}

FieldInterference::FieldInterference::FieldColorMap
FieldInterference::constructFieldInterference(FieldVector &fields) {
    typedef boost::adjacency_list<
        boost::setS,                    // No duplicate edges
        boost::vecS,
        boost::undirectedS,             // Undirected edges
        boost::property<boost::vertex_index_t, std::size_t>,
        boost::no_property              // No edge labels
            > Graph;
    typedef typename boost::graph_traits<Graph> GraphTraits;
    typedef typename GraphTraits::vertex_descriptor Vertex;
    typedef typename boost::graph_traits<Graph>::vertices_size_type vertices_size_type;
    typedef typename boost::property_map<Graph, boost::vertex_index_t>::const_type vertex_index_map;

    Graph g;
    // BGL Property Map: Maps vertices to fields
    boost::iterator_property_map<PHV::Field **, vertex_index_map> field_map(&fields.front(),
            boost::get(boost::vertex_index, g));

    // Add vertices
    // TODO: Add gress, tagalong/PHVs labels to this log message
    LOG5("Creating field to field interference graph");
    std::size_t i = 0;
    for (auto *f : fields) {
        // Do not create interference graph for unreferenced fields
        Vertex v = boost::add_vertex(i++, g);
        field_map[v] = f;
        LOG5("\tVertex " << (i - 1) << " <- Field " << f->name); }

    // Add interference edges
    GraphTraits::vertex_iterator v, vend;
    for (boost::tie(v, vend) = boost::vertices(g); v != vend; ++v) {
        GraphTraits::vertex_iterator v2, vend2;
        for (boost::tie(v2, vend2) = boost::vertices(g); v2 != vend2; ++v2) {
            PHV::Field *f1 = field_map[*v];
            PHV::Field *f2 = field_map[*v2];
            if (f1 == f2) continue;
            if (!PHV::Allocation::mutually_exclusive(mutex_i, f1, f2)) {
                // Fields interfere
                boost::add_edge(*v, *v2, g);
                LOG5("\tAdding interference edge: " << f1->name << " <-> " << f2->name); } } }

    // Build smallest-last vertex ordering for greedy vertex coloring
    boost::tie(v, vend) = boost::vertices(g);
    std::vector<Vertex> order_vec(v, vend);
    std::sort(order_vec.begin(), order_vec.end(), [&](Vertex v1, Vertex v2) {
        return boost::out_degree(v1, g) > boost::out_degree(v2, g); });

    // Do vertex coloring; output color
    auto order = boost::make_iterator_property_map(order_vec.begin(),
            boost::identity_property_map(), GraphTraits::null_vertex());
    std::vector<vertices_size_type> color_vec(boost::num_vertices(g));
    boost::iterator_property_map<vertices_size_type*, vertex_index_map> color(&color_vec.front(),
            boost::get(boost::vertex_index, g));
    boost::sequential_vertex_coloring(g, order, color);

    // Build a color->cluster map to return. Colors are virtual MAU groups.
    ordered_map<int, std::vector<PHV::Field *>> rv;
    for (boost::tie(v, vend) = boost::vertices(g); v != vend; ++v) {
        int vreg = static_cast<int>(color[*v]);
        PHV::Field* f = field_map[*v];
        LOG5("Field " << f->name << " assigned VREG " << vreg);
        rv[vreg].push_back(f); }

    return rv;
}

void
FieldInterference::printFieldColorMap(FieldInterference::FieldColorMap& m) {
    if (!LOGGING(4)) return;
    size_t numMultiSets = 0;    // Number of colors with more than 1 field , i.e. number of sets of
                                // multiple mutually exclusive fields instead of single fields
    for (auto entry : m) {
        // Do not print groups with only one member
        // (Fields that are not part of a mutually exclusive set of fields)
        if (entry.second.size() < 2)
            continue;
        else
            numMultiSets++;
        std::stringstream ss;
        ss << entry.first << "\t:\t";   // Color number
        for (auto *f : entry.second) {
            ss << f->name;
            if (f->is_ccgf())
                ss << " (ccgf, " << f->ccgf_width() << "b) ";
            else
                ss << " (" << f->size << "b) ";
        }
        LOG4(ss); }
    LOG4("Number of colors with multiple fields: " << numMultiSets);
}
