#ifndef EXTENSIONS_BF_P4C_MAU_DYNAMIC_DEP_METRICS_H_
#define EXTENSIONS_BF_P4C_MAU_DYNAMIC_DEP_METRICS_H_

#include <functional>
#include "bf-p4c/mau/table_dependency_graph.h"


class DynamicDependencyMetrics {
    const CalculateNextTableProp &ntp;
    const ControlPathwaysToTable &con_paths;
    const DependencyGraph &dg;
    // FIXME -- not thread safe!
    std::function<bool(const IR::MAU::Table *)> placed_tables;

 public:
    DynamicDependencyMetrics(const CalculateNextTableProp &n, const ControlPathwaysToTable &cp,
        const DependencyGraph &d) : ntp(n), con_paths(cp), dg(d) {}

    std::pair<int, int> get_downward_prop_score(const IR::MAU::Table *a,
        const IR::MAU::Table *b) const;

    void score_on_seq(const IR::MAU::TableSeq *seq, const IR::MAU::Table *tbl,
        int &max_dep_impact, char type) const;
    void update_placed_tables(std::function<bool(const IR::MAU::Table*)> pt) { placed_tables = pt; }

    int total_deps_of_dom_frontier(const IR::MAU::Table *a) const;
    int placeable_cds_count(const IR::MAU::Table *tbl,
        ordered_set<const IR::MAU::Table *> &already_placed_in_stage) const;
    bool can_place_cds_in_stage(const IR::MAU::Table *tbl,
        ordered_set<const IR::MAU::Table *> &already_placed_in_table) const;
    double average_cds_chain_length(const IR::MAU::Table *tbl) const;
};

#endif /* EXTENSIONS_BF_P4C_MAU_DYNAMIC_DEP_METRICS_H_ */
