#ifndef BF_P4C_MAU_DUMP_JSON_GRAPH_H_
#define BF_P4C_MAU_DUMP_JSON_GRAPH_H_

#include "bf-p4c/logging/pass_manager.h"
#include "bf-p4c/mau/table_dependency_graph.h"

class DumpJsonGraph : public PassManager {
    FlowGraph fg;
    DependencyGraph &dg;
    Util::JsonObject* dgJson;
    cstring passContext;
    bool placed;

    void end_apply(const IR::Node *root) override;
 public:
    DumpJsonGraph(DependencyGraph &dg, Util::JsonObject* dgJson, cstring passContext, bool placed);
};

#endif  /* BF_P4C_MAU_DUMP_JSON_GRAPH_H_ */
