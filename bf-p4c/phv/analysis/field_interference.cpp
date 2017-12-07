#include <boost/graph/adjacency_list.hpp>
#include "bf-p4c/lib/vertex_weighted_coloring.h"

#include "bf-p4c/phv/analysis/field_interference.h"
#include "lib/log.h"

FieldInterference::FieldVector FieldInterference::getAllReferencedFields(
        std::vector<PHV::AlignedCluster*>& clusters,
        gress_t gress) {
    FieldVector rs;
    for (auto* cl : clusters) {
        for (auto& slice : cl->slices()) {
            if (slice.gress() != gress) continue;
            if (std::find(rs.begin(), rs.end(), slice.field()) == rs.end())
                rs.push_back(slice.field());
            field_to_cluster_map[slice.field()].insert(cl); } }
    return rs;
}

const IR::Node *
FieldInterference::apply_visitor(const IR::Node *node, const char *name) {
    LOG4("...............Field Interference apply visitor()................");
    if (name)
        LOG4(name);

    std::vector<PHV::AlignedCluster*> all_clusters;
    for (auto* super_cluster : clustering_i.cluster_groups())
        for (auto* rotational_cluster : super_cluster->clusters())
            all_clusters.insert(all_clusters.end(), rotational_cluster->clusters().begin(),
                                                    rotational_cluster->clusters().end());

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

    LOG5("Creating field to field interference graph");
    VertexWeightedGraphBuilder<Graph> graph_builder;
    std::map<int, PHV::Field *> vertex_id_to_field;
    // add vertices with its weight
    for (const auto& f : fields) {
        int v_id = graph_builder.add_vertex(f->size);
        vertex_id_to_field[v_id] = f;
        LOG5("\tVertex " << v_id << " <- Field " << f->name);
    }

    // Add interference edges
    for (const auto& vi : vertex_id_to_field) {
        for (const auto& vj : vertex_id_to_field) {
            if (vi.first == vj.first) continue;
            if (!PHV::Allocation::mutually_exclusive(mutex_i, vi.second, vj.second)) {
                graph_builder.add_edge(vi.first, vj.first);
                LOG5("\tAdding interference edge: "
                     << vi.second->name
                     << " <-> " << vj.second->name); } } }

    auto graph = graph_builder.build();
    WeightedGraphColoringSolver<decltype(graph.graph),
                                decltype(graph.weights),
                                decltype(graph.colors)> solver(graph);
    solver.run();

    // Build a color->cluster map to return. Colors are virtual MAU groups.
    ordered_map<int, std::vector<PHV::Field *>> rv;
    for (const auto& v : vertex_id_to_field) {
        int v_color = graph.colors[v.first];
        LOG5("Field " << v.second->name << " assigned VREG " << v_color);
        rv[v_color].push_back(v.second); }

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
