#include "bf-p4c/phv/analysis/critical_path_clusters.h"

const IR::Node *
CalcCriticalPathClusters::apply_visitor(const IR::Node * node, const char *) {
    LOG4("..........CalcCriticalPathClusters::apply_visitor()..........");
    ordered_set<const PHV::Field *> critical_fields =
        parser_critical_path.calc_all_critical_fields();

    for (auto* super_cluster : clustering.cluster_groups()) {
        bool has_critical_field = std::any_of(critical_fields.begin(), critical_fields.end(),
            [&](const PHV::Field* f) { return super_cluster->contains(f); });
        if (has_critical_field) {
            results.push_back(super_cluster);
            break; } }

    if (LOGGING(4)) {
        LOG4("=========== Results ===========");
        for (auto* super_cluster : results) {
            for (auto* rotational_cluster : super_cluster->clusters()) {
                for (auto* aligned_cluster : rotational_cluster->clusters()) {
                    for (auto& slice : aligned_cluster->slices()) {
                        LOG4("Field:" << slice.field()->name); } } }
            LOG4("==============================="); } }

    return node;
}
