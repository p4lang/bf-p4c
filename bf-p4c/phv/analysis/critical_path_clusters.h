#ifndef BF_P4C_PHV_ANALYSIS_CRITICAL_PATH_CLUSTERS_H_
#define BF_P4C_PHV_ANALYSIS_CRITICAL_PATH_CLUSTERS_H_

#include "ir/ir.h"
#include "lib/cstring.h"
#include "bf-p4c/phv/make_clusters.h"
#include "bf-p4c/phv/analysis/parser_critical_path.h"

/** Provide a function to produces a std::set<const SuperCluster*> that
 * those SuperClusters have at least one cluster that
 * has field(s) extracted on the parser critical path,
 * either ingress or egress. The result
 * can be fetched by getCriticalPathClusters().
 *
 * This pass does not traverse the IR tree, nor does it change states.
 * After spliting clusters, call calc_critical_clusters.
 *
 * @pre Must run after CalcParserCriticalPath
 */
class CalcCriticalPathClusters : public Inspector {
 private:
    ordered_set<const PHV::Field *> critical_fields_i;
    const CalcParserCriticalPath& parser_critical_path;
    const IR::Node *apply_visitor(const IR::Node *, const char *name = 0) override;

 public:
    explicit CalcCriticalPathClusters(const CalcParserCriticalPath& parser_critical_path)
        : parser_critical_path(parser_critical_path) {}

    std::set<PHV::SuperCluster *>
    calc_critical_clusters(const std::list<PHV::SuperCluster *>& clusters) const;

    profile_t init_apply(const IR::Node* root) override;

    void print(std::ostream& out, const std::set<PHV::SuperCluster *>& clusters) const;
};

#endif /* BF_P4C_PHV_ANALYSIS_CRITICAL_PATH_CLUSTERS_H_ */
