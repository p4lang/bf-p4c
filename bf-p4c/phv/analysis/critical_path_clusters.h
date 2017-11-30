#ifndef BF_P4C_PHV_ANALYSIS_CRITICAL_PATH_CLUSTERS_H_
#define BF_P4C_PHV_ANALYSIS_CRITICAL_PATH_CLUSTERS_H_

#include "ir/ir.h"
#include "lib/cstring.h"
#include "bf-p4c/phv/make_clusters.h"
#include "bf-p4c/common/parser_critical_path.h"

/** Produces a std::vector<const SuperCluster*> that
 * those SuperClusters have at least one cluster that
 * has field(s) extracted on the parser critical path,
 * either ingress or egress. The result
 * can be fetched by getCriticalPathClusters().
 *
 * This pass does not traverse the IR tree, nor does it change states.
 *
 * @pre Must run after CalcParserCriticalPath and Clustering.
 */
class CalcCriticalPathClusters : public Inspector {
 private:
    std::vector<PHV::SuperCluster *> results;
    const Clustering& clustering;
    const CalcParserCriticalPath& parser_critical_path;
    const IR::Node *apply_visitor(const IR::Node *, const char *name = 0) override;

 public:
    CalcCriticalPathClusters(const Clustering& clustering,
                             const CalcParserCriticalPath& parser_critical_path)
        : clustering(clustering), parser_critical_path(parser_critical_path) {}
    const std::vector<PHV::SuperCluster *>& getCriticalPathClusters() { return results; }
};

#endif /* BF_P4C_PHV_ANALYSIS_CRITICAL_PATH_CLUSTERS_H_ */
