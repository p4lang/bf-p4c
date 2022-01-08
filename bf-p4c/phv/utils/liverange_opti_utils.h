#ifndef EXTENSIONS_BF_P4C_PHV_UTILS_LIVERANGE_OPTI_UTILS_H_
#define EXTENSIONS_BF_P4C_PHV_UTILS_LIVERANGE_OPTI_UTILS_H_

#include "ir/ir.h"
#include "bf-p4c/phv/analysis/dominator_tree.h"

namespace PHV {
class Transaction;
}

/// @returns true if any of the dominator units in @doms is a parser node.
bool hasParserUse(ordered_set<const IR::BFN::Unit*> doms);

/// @returns all pairs (x, y) where x is an unit in @f_units that can reach the unit y in @g_units.
ordered_set<std::pair<const IR::BFN::Unit*, const IR::BFN::Unit*>> canFUnitsReachGUnits(
    const ordered_set<const IR::BFN::Unit*>& f_units,
    const ordered_set<const IR::BFN::Unit*>& g_units,
    const ordered_map<gress_t, FlowGraph>& flowGraph);

/// Trim the set of dominators by removing nodes that are dominated by other dominator nodes
/// already in the set.
void getTrimmedDominators(ordered_set<const IR::BFN::Unit*>& candidates,
                          const BuildDominatorTree& domTree);

/// Overlaying two fields @g and @f using ARA initialization may modify
/// the flowgraph of the program. This function updates the flowgraph
/// for initializing field @f whose min-stage based liverange is later
/// than the liverange of @g. The @return flowgraph is the original
/// flowgraph complemented with flows from all units referencing field
/// g to all units referencing field f.
/// NOTE: The updated flowgraph is meant to check for control flow
/// loops and not used as the IR flowgraph.
ordered_map<gress_t, FlowGraph>
  update_flowgraph(const ordered_set<const IR::BFN::Unit*>& g_units,
                   const ordered_set<const IR::BFN::Unit*>& f_units,
                   const ordered_map<gress_t, FlowGraph>& flgraphs,
                   const PHV::Transaction& transact,
                   bool& canUseARA);

#endif  /*  EXTENSIONS_BF_P4C_PHV_UTILS_LIVERANGE_OPTI_UTILS_H_  */
