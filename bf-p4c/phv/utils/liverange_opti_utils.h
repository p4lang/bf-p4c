#ifndef EXTENSIONS_BF_P4C_PHV_UTILS_LIVERANGE_OPTI_UTILS_H_
#define EXTENSIONS_BF_P4C_PHV_UTILS_LIVERANGE_OPTI_UTILS_H_

#include "ir/ir.h"
#include "bf-p4c/phv/analysis/dominator_tree.h"

/// @returns true if any of the dominator units in @doms is a parser node.
static bool hasParserUse(ordered_set<const IR::BFN::Unit*> doms) {
    for (const auto* u : doms)
        if (u->is<IR::BFN::Parser>() || u->is<IR::BFN::ParserState>())
            return true;
    return false;
}

/// @returns all pairs (x, y) where x is an unit in @f_units that can reach the unit y in @g_units.
static ordered_set<std::pair<const IR::BFN::Unit*, const IR::BFN::Unit*>>
canFUnitsReachGUnits(
        const ordered_set<const IR::BFN::Unit*>& f_units,
        const ordered_set<const IR::BFN::Unit*>& g_units,
        const ordered_map<gress_t, FlowGraph>& flowGraph) {
    ordered_set<std::pair<const IR::BFN::Unit*, const IR::BFN::Unit*>> rv;
    auto gress = boost::make_optional(false, gress_t());
    for (const auto* u1 : f_units) {
        bool deparser1 = u1->is<IR::BFN::Deparser>();
        bool table1 = u1->is<IR::MAU::Table>();
        if (!gress) gress = u1->thread();
        if (hasParserUse({ u1 })) {
            LOG4("\t\t\tParser defuse " << DBPrint::Brief << u1 << " can reach all g units.");
            for (const auto* u2 : g_units) rv.insert(std::make_pair(u1, u2));
            continue;
        }
        const auto* t1 = table1 ? u1->to<IR::MAU::Table>() : nullptr;
        BUG_CHECK(flowGraph.count(*gress), "Flow graph not found for %1%", *gress);
        const FlowGraph& fg = flowGraph.at(*gress);
        for (const auto* u2 : g_units) {
            // Units of different gresses cannot reach each other.
            if (gress)
                if (u2->thread() != *gress)
                    return rv;
            bool deparser2 = u2->is<IR::BFN::Deparser>();
            // If f was used in a deparser and g was not in the deparser, then f cannot reach g.
            if (deparser1) {
                if (deparser2) {
                    LOG4("\t\t\tBoth units are deparser. Can reach.");
                    rv.insert(std::make_pair(u1, u2));
                } else {
                    LOG4("\t\t\t" << DBPrint::Brief << u1 << " cannot reach " << DBPrint::Brief <<
                         u2);
                }
                continue;
            }
            // Deparser/table use for f_unit cannot reach parser use for g_unit.
            if (table1 && hasParserUse({ u2 })) {
                LOG4("\t\t\t" << DBPrint::Brief << u1 << " cannot reach " << DBPrint::Brief << u2);
                continue;
            }
            // Deparser use for g can be reached by every unit's use in f.
            if (deparser2) {
                rv.insert(std::make_pair(u1, u2));
                LOG4("\t\t\t" << DBPrint::Brief << u1 << " can reach " << DBPrint::Brief << u2);
                continue;
            }

            if (!u2->is<IR::MAU::Table>())
                BUG("Non-parser, non-deparser, non-table defuse unit found.");
            const auto* t2 = u2->to<IR::MAU::Table>();
            if (fg.can_reach(t1, t2)) {
                LOG4("\t\t\t" << t1->name << " can reach " << t2->name);
                rv.insert(std::make_pair(u1, u2));
            } else {
                LOG4("\t\t\t" << t1->name << " cannot reach " << t2->name);
            }
        }
    }
    return rv;
}

/// Trim the set of dominators by removing nodes that are dominated by other dominator nodes
/// already in the set.
static void getTrimmedDominators(
        ordered_set<const IR::BFN::Unit*>& candidates,
        const BuildDominatorTree& domTree) {
    // By definition of dominators, all candidates are tables.
    ordered_set<const IR::BFN::Unit*> emptySet;
    ordered_set<const IR::BFN::Unit*> dominatedNodes;
    for (const auto* u1 : candidates) {
        if (hasParserUse({ u1 })) continue;
        bool table1 = u1->is<IR::MAU::Table>();
        const auto* t1 = table1 ? u1->to<IR::MAU::Table>() : nullptr;
        for (const auto* u2 : candidates) {
            if (u1 == u2) continue;
            if (hasParserUse({ u2 })) continue;
            bool table2 = u2->is<IR::MAU::Table>();
            const auto* t2 = table2 ? u2->to<IR::MAU::Table>() : nullptr;
            // If u1 dominates u2, only consider u1. So, mark u2 for deletion.
            if (domTree.strictlyDominates(t1, t2))
                dominatedNodes.insert(u2);
        }
    }
    for (const auto* u : dominatedNodes)
        candidates.erase(u);
}

#endif  /*  EXTENSIONS_BF_P4C_PHV_UTILS_LIVERANGE_OPTI_UTILS_H_  */
