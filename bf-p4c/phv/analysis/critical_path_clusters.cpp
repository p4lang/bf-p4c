#include "bf-p4c/phv/analysis/critical_path_clusters.h"

bool has_critical_field(PHV::AlignedCluster *cluster,
                        const ordered_set<const PHV::Field *>& critical_fields) {
    for (const auto& field : cluster->fields()) {
        if (critical_fields.count(field)) {
            return true; } }
    return false;
}

const IR::Node *
CalcCriticalPathClusters::apply_visitor(const IR::Node * node, const char *) {
    LOG4("..........CalcCriticalPathClusters::apply_visitor()..........");
    ordered_set<const PHV::Field *> critical_fields =
        parser_critical_path.calc_all_critical_fields();

    for (const auto& super_cluster : clustering.cluster_groups()) {
        for (const auto& aligned_cluster : super_cluster->clusters()) {
            if (has_critical_field(aligned_cluster, critical_fields)) {
                results.push_back(super_cluster);
                break;
            }
        }
    }

    if (LOGGING(4)) {
        LOG4("=========== Results ===========");
        for (const auto& super_cluster : results) {
            for (const auto& cluster : super_cluster->clusters()) {
                for (const auto& f : cluster->fields()) {
                    LOG4("Field:" << f->name); } }
            LOG4("===============================");
        }
    }

    return node;
}
