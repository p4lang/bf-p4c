#include "bf-p4c/mau/dump_json_graph.h"

using namespace P4;

DumpJsonGraph::DumpJsonGraph(DependencyGraph &dg, Util::JsonObject* dgJson,
                             cstring passContext, bool placed) :
    dg(dg), dgJson(dgJson), passContext(passContext), placed(placed) {
    addPasses({
        new FindFlowGraph(fg)
    });
}

void DumpJsonGraph::end_apply(const IR::Node *) {
    if (BackendOptions().create_graphs) {
        dg.to_json(dgJson, fg, passContext, placed);
    }
}
