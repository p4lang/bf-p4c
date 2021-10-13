#ifndef EXTENSIONS_BF_P4C_PHV_UTILS_LIVERANGE_OPTI_UTILS_H_
#define EXTENSIONS_BF_P4C_PHV_UTILS_LIVERANGE_OPTI_UTILS_H_

#include "ir/ir.h"
#include "bf-p4c/phv/analysis/dominator_tree.h"

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

#endif  /*  EXTENSIONS_BF_P4C_PHV_UTILS_LIVERANGE_OPTI_UTILS_H_  */
