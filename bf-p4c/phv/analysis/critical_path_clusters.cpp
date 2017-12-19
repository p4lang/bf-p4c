#include "bf-p4c/phv/analysis/critical_path_clusters.h"

const IR::Node *
CalcCriticalPathClusters::apply_visitor(const IR::Node * node, const char *) {
    critical_fields_i = parser_critical_path.calc_all_critical_fields();
    return node;
}

std::set<PHV::SuperCluster *>
CalcCriticalPathClusters::calc_critical_clusters(
    const std::list<PHV::SuperCluster *>& clusters) const {
    std::set<PHV::SuperCluster *> results;
    for (auto* super_cluster : clusters) {
        bool has_critical_field = std::any_of(critical_fields_i.begin(), critical_fields_i.end(),
                [&](const PHV::Field* f) { return super_cluster->contains(f); });
        if (has_critical_field) {
            results.insert(super_cluster); } }
    return results;
}

void
CalcCriticalPathClusters::print(std::ostream& out,
                                const std::set<PHV::SuperCluster *>& clusters) const {
    out << "=========== Critical Clusters ===========" << std::endl;
    for (auto* super_cluster : clusters) {
        for (auto* rotational_cluster : super_cluster->clusters()) {
            for (auto* aligned_cluster : rotational_cluster->clusters()) {
                for (auto& slice : aligned_cluster->slices()) {
                    out << "Field:" << slice.field()->name << std::endl; } } }
        out << "=========================================" << std::endl; }
}
