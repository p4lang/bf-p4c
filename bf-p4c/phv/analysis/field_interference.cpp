#include "bf-p4c/phv/analysis/field_interference.h"
#include <boost/graph/adjacency_list.hpp>
#include <algorithm>
#include <numeric>
#include "bf-p4c/lib/vertex_weighted_coloring.h"

FieldInterference::SliceListVector
FieldInterference::getSliceLists(const std::list<PHV::SuperCluster *>& clusters,
                                  gress_t gress,
                                  bool is_tagalong) const {
    SliceListVector rst;
    for (auto* super_cluster : clusters) {
        // Add all slicelist
        std::set<PHV::FieldSlice> already_in_lists;
        for (const auto& slice_list : super_cluster->slice_lists()) {
            bool is_tagalong_list =
                std::all_of(slice_list->begin(), slice_list->end(),
                            [this] (const PHV::FieldSlice& s) {
                                return s.field()->is_tphv_candidate(uses_i); });
            if (slice_list->front().gress() != gress) continue;
            if (is_tagalong != is_tagalong_list) continue;
            already_in_lists.insert(slice_list->begin(), slice_list->end());
            rst.emplace_back(slice_list->begin(), slice_list->end()); }

        // For the rest slices, create singleton slicelist for them.
        for (auto* rotational_cluster : super_cluster->clusters()) {
            for (auto* aligned_cluster : rotational_cluster->clusters()) {
                for (auto slice : aligned_cluster->slices()) {
                    if (slice.gress() != gress) continue;
                    if (slice.field()->is_tphv_candidate(uses_i) != is_tagalong) continue;
                    if (!already_in_lists.count(slice)) {
                        rst.push_back({ slice }); }
                } } } }
    return rst;
}

FieldInterference::SliceColorMap
FieldInterference::calcSliceInterference(const std::list<PHV::SuperCluster *>& clusters) const {
    // Do the calculation separately to reduce the problem scale for a better result.
    // Also, overlaying PHV fields on TPHV fields is not a good idea.
    SliceListVector ingress_tphv_fields = getSliceLists(clusters, INGRESS, true);
    SliceListVector ingress_phv_fields  = getSliceLists(clusters, INGRESS, false);
    SliceListVector egress_tphv_fields  = getSliceLists(clusters, EGRESS, true);
    SliceListVector egress_phv_fields   = getSliceLists(clusters, EGRESS, false);

    LOG4("Ingress tphv coloring");
    SliceColorMap ingress_tphv_overlays = constructFieldInterference(ingress_tphv_fields);
    printFieldColorMap(ingress_tphv_overlays);

    LOG4("Ingress phv coloring");
    SliceColorMap ingress_phv_overlays = constructFieldInterference(ingress_phv_fields);
    printFieldColorMap(ingress_phv_overlays);

    LOG4("Egress tphv coloring");
    SliceColorMap egress_tphv_overlays = constructFieldInterference(egress_tphv_fields);
    printFieldColorMap(egress_tphv_overlays);

    LOG4("Egress phv coloring");
    SliceColorMap egress_phv_overlays = constructFieldInterference(egress_phv_fields);
    printFieldColorMap(egress_phv_overlays);

    // Merge them together by update the later color of slices to eliminate color conflicts.
    // update: later_slice.color += max_size * n_fields;
    std::vector<size_t> sizes{
        ingress_tphv_fields.size(), ingress_phv_fields.size(),
        egress_tphv_fields.size(), egress_phv_fields.size() };
    size_t max_size = *(std::max_element(sizes.begin(), sizes.end()));
    size_t shift = max_size;
    std::vector<SliceColorMap*> to_be_merged = { &ingress_phv_overlays,
                                                 &egress_tphv_overlays,
                                                 &egress_phv_overlays };
    for (auto* overlay_result : to_be_merged) {
        for (const auto& v : (*overlay_result)) {
            ingress_tphv_overlays.emplace(v.first, v.second + max_size); }
        shift += max_size; }

    return ingress_tphv_overlays;
}

bool
FieldInterference::is_mutually_exclusive(const SliceList& a,
                                          const SliceList& b) const {
    for (const auto& a_slice : a) {
        for (const auto& b_slice : b) {
            if (!PHV::Allocation::mutually_exclusive(
                    mutex_i,
                    a_slice.field(),
                    b_slice.field())) {
                return false; }
        } }
    return true;
}

FieldInterference::SliceColorMap
FieldInterference::constructFieldInterference(SliceListVector &slice_lists) const {
    typedef boost::adjacency_list<
        boost::setS,                    // No duplicate edges
        boost::vecS,
        boost::undirectedS,             // Undirected edges
        boost::property<boost::vertex_index_t, std::size_t>,
        boost::no_property              // No edge labels
            > Graph;

    LOG6("Creating field to field interference graph");
    VertexWeightedGraphBuilder<Graph> graph_builder;
    std::map<int, const SliceList*> vertex_id_to_slicelist;
    int n_slice_size_sum = 0;
    // add vertices with its weight
    for (const auto& slice_list : slice_lists) {
        int list_size =
            std::accumulate(slice_list.begin(), slice_list.end(), 0,
                            [] (int a, const PHV::FieldSlice& slice) {
                                return a + slice.size();
                            });
        int v_id = graph_builder.add_vertex(list_size);
        vertex_id_to_slicelist.emplace(v_id, &slice_list);
        LOG6("\tVertex " << v_id << " <- Slice " << slice_list);
        n_slice_size_sum += list_size;
    }

    // Add interference edges
    for (const auto& vi : vertex_id_to_slicelist) {
        for (const auto& vj : vertex_id_to_slicelist) {
            if (vi.first == vj.first) continue;
            // If vi and vj is from the same field, they are inclusive.
            if (!is_mutually_exclusive(*vi.second, *vj.second)) {
                graph_builder.add_edge(vi.first, vj.first);
                LOG6("\tAdding interference edge: "
                     << *vi.second
                     << " <-> " << *vj.second); } } }

    auto graph = graph_builder.build();
    WeightedGraphColoringSolver<decltype(graph.graph),
                                decltype(graph.weights),
                                decltype(graph.colors)> solver(graph);
    solver.run();

    FieldInterference::SliceColorMap rv;
    for (const auto& v : vertex_id_to_slicelist) {
        int v_color = graph.color_vec[v.first];
        LOG6("SliceList " << *v.second << " assigned VREG " << v_color);
        for (const auto& slice : *v.second) {
            rv[slice] = v_color; }
    }

    LOG5("Total Bits: " << n_slice_size_sum);
    LOG5("If Alloc-Like-Coloring, Total Bits: " << solver.total_cost());
    LOG5("Potential Overlay Bits: " << n_slice_size_sum - solver.total_cost());
    LOG5("Color Used: " << solver.max_color());

    return rv;
}

void
FieldInterference::printFieldColorMap(FieldInterference::SliceColorMap& m) const {
    if (!LOGGING(4)) return;
    size_t n_metadata_overlays = 0;
    size_t numMultiSets = 0;    // Number of colors with more than 1 field , i.e. number of sets of
                                // multiple mutually exclusive fields instead of single fields
    std::map<int, std::vector<PHV::FieldSlice>> color_to_slices;
    for (const auto& v : m) {
        if (!color_to_slices.count(v.second)) {
            color_to_slices[v.second] = std::vector<PHV::FieldSlice>(); }
        color_to_slices[v.second].push_back(v.first);
    }
    for (auto entry : color_to_slices) {
        // Do not print groups with only one member
        // (Fields that are not part of a mutually exclusive set of fields)
        if (entry.second.size() < 2)
            continue;
        else
            numMultiSets++;
        std::stringstream ss;
        ss << entry.first << "\t:\t";   // Color number
        bool skip_first_indent = true;
        for (auto slice : entry.second) {
            if (slice.field()->metadata) {
                n_metadata_overlays += slice.size(); }
            // output this slice
            if (skip_first_indent) {
                skip_first_indent = false;
            } else {
                ss << " \t \t"; }
            ss << slice;
            ss << " (" << slice.size() << "b) " << std::endl;
        }
        LOG4(ss.str()); }
    LOG4("Number of colors with multiple fields: " << numMultiSets);
    LOG4("Number of metadata ovleray bits: " << n_metadata_overlays);
    LOG4("========================================");
}

std::ostream& operator<<(std::ostream &out, const FieldInterference::SliceList& list) {
    out << "[";
    for (auto& slice : list) {
        if (slice == list.front()) {
            out << " " << slice;
        } else {
            out << "          " << slice; }
        if (slice != list.back()) out << "\n";
    }
    if (list.size() > 1)
        out << "        ]";
    else
        out << " ]";
    return out;
}
