#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/dominator_tree.hpp>
#include "bf-p4c/phv/analysis/dominator_tree.h"

using namespace boost;

bool BuildDominatorTree::preorder(const IR::BFN::Pipe *pipe) {
    const int numThreads = (sizeof(pipe->thread) / sizeof(IR::BFN::Pipe::thread_t));
    for (size_t i = 0; i < numThreads /* pipe->thread.size() */; ++i) {
        flowGraph.push_back(new FlowGraph());
        pipe->thread[i].mau->apply(FindFlowGraph(*(flowGraph[i])));
    }

    // Generate dominator tree for each gress.
    for (auto* fg : flowGraph) {
        ordered_map<int, const IR::MAU::Table*> indexMap;
        // If the flow graph is empty (e.g. no egress tables), no need to build the dominator map.
        // However, we still create an ImmediateDominatorMap for the particular gress.
        if (fg->emptyFlowGraph) {
            iDominator.push_back(new ImmediateDominatorMap());
            continue;
        }
        if (!fg->gress)
            BUG("Gress not assigned for flow graph");
        gress_t graphGress = *(fg->gress);
        generateIndexToTableMap(*fg, indexMap);
        iDominator.push_back(new ImmediateDominatorMap);
        generateDominatorTree(*fg, indexMap, *(iDominator.at(graphGress)));
    }
    if (!LOGGING(1)) return false;
    for (size_t i = 0; i < iDominator.size(); ++i) {
        LOG1("\tPrinting dominator tree for " << i);
        printDominatorTree(*(iDominator.at(i)));
    }
    return false;
}

Visitor::profile_t BuildDominatorTree::init_apply(const IR::Node* root) {
    flowGraph.clear();
    for (auto* idom : iDominator)
        idom->clear();
    return Inspector::init_apply(root);
}

void BuildDominatorTree::generateIndexToTableMap(
        const FlowGraph& fg,
        ordered_map<int, const IR::MAU::Table*>& indexMap) const {
    graph_traits<G>::vertex_iterator uItr, uEnd;
    // For each vertex, create a map of the index of the vertex to the table that vertex represents.
    // This is useful for translating the results of the boost dominator algorithm (which operates
    // on the vertex indices) to the associated table pointers.
    for (boost::tie(uItr, uEnd) = vertices(fg.g); uItr != uEnd; ++uItr)
        indexMap[boost::get(boost::vertex_index, fg.g)[*uItr]] =
            boost::get(boost::vertex_table, fg.g)[*uItr];
    if (!LOGGING(4)) return;
    LOG4("      Printing index to table names");
    for (auto kv : indexMap)
        if (kv.second != nullptr)
            LOG4("        " << kv.first << "\t:\t" << kv.second->name);
}

void BuildDominatorTree::generateDominatorTree(
        const FlowGraph& fg,
        const ordered_map<int, const IR::MAU::Table*>& indexToTableMap,
        ImmediateDominatorMap& iDom) {
    // idom is a mapping from index of a vertex to the index of its immediate dominator veretx.
    ordered_map<int, int> idom;

    // Standard boost dominator tree analysis.
    std::vector<Vertex> domTreePredVector;
    IndexMap indexMap(boost::get(vertex_index, fg.g));
    graph_traits<G>::vertex_iterator uItr, uEnd;
    domTreePredVector = std::vector<Vertex>(num_vertices(fg.g), graph_traits<G>::null_vertex());
    PredMap domTreePredMap = make_iterator_property_map(domTreePredVector.begin(), indexMap);
    lengauer_tarjan_dominator_tree(fg.g, vertex(1, fg.g), domTreePredMap);

    // We use the map idom to first interpret the results of the dominator analysis. This allows us
    // to get the dominator information without needing to handle the special case of the SINK node
    // (which does not have any table pointer associated with it) and the SOURCE node (which has a
    // NULL vertex as the immediate dominator).
    for (boost::tie(uItr, uEnd) = vertices(fg.g); uItr != uEnd; ++uItr) {
        if (boost::get(domTreePredMap, *uItr) != graph_traits<G>::null_vertex()) {
            idom[boost::get(indexMap, *uItr)] =
                boost::get(indexMap, boost::get(domTreePredMap, *uItr));
            LOG4("\t\tSetting dominator for " << boost::get(indexMap, *uItr) << " to " <<
                            boost::get(indexMap, boost::get(domTreePredMap, *uItr)));
        } else {
            idom[boost::get(indexMap, *uItr)] = -1;
            LOG4("\t\tSetting dominator for " << boost::get(indexMap, *uItr) << " to -1");
        }
    }

    // This is where we translate the data in idom and translate it into a map between table
    // pointers. If the node is a source node (its immediate dominator is the NULL vertex), we
    // assign the dominator of that node to itself. We also verify that the sink node was not
    // assigned to be an immediate dominator to any node.
    for (auto kv : idom) {
        if (kv.second == -1) {
            iDom[indexToTableMap.at(kv.first)] = indexToTableMap.at(kv.first);
        } else if (kv.second == 0) {
            BUG("Sink node cannot be the immediate dominator");
        } else {
            if (!indexToTableMap.count(kv.second))
                BUG("Unknown table with index %1% not found", kv.second);
            iDom[indexToTableMap.at(kv.first)] = indexToTableMap.at(kv.second);
        }
    }
}

void BuildDominatorTree::printDominatorTree(const ImmediateDominatorMap& idom) const {
    for (auto kv : idom) {
        cstring idominator;
        cstring source;
        if (kv.second == kv.first)
            idominator = "SOURCE";
        else
            idominator = kv.second->name;
        if (kv.first == 0)
            source = "SINK";
        else
            source = kv.first->name;
        LOG1("\t\t" << boost::format("%=25s") % source << "\t:\t" <<
             boost::format("%=25s") % idominator);
    }
}

boost::optional<const IR::MAU::Table*>
BuildDominatorTree::getImmediateDominator(const IR::MAU::Table* t, gress_t gress) const {
    cstring tableName = (t == NULL) ? "deparser" : t->name;
    BUG_CHECK(gress < iDominator.size(), "Invalid gress %1% for table %2%", gress, tableName);
    const ImmediateDominatorMap* iDom = iDominator.at(gress);
    if (!iDom->count(t)) return boost::none;
    return iDom->at(t);
}

boost::optional<const IR::MAU::Table*>
BuildDominatorTree::getNonGatewayImmediateDominator(const IR::MAU::Table* t, gress_t gress) const {
    cstring tableName = (t == NULL) ? "deparser" : t->name;
    BUG_CHECK(gress < iDominator.size(), "Invalid gress %1% for table %2%", gress, tableName);
    auto dom = getImmediateDominator(t, gress);
    if (!dom) return boost::none;
    // If the table is not a gateway, then return the immediate dominator itself.
    if (!((*dom)->gateway_only())) return (*dom);
    // If the table is the same as its dominator then we are at the source node and if the source
    // node is a gateway, then return boost::noone.
    if ((*dom)->gateway_only() && t == *dom) return boost::none;
    // If the table is the same as its dominator then we are at the source node, so return the
    // source node.
    if (t == *dom) return t;
    return getNonGatewayImmediateDominator(*dom, gress);
}

bool
BuildDominatorTree::strictlyDominates(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const {
    if (t1 == t2) return false;
    // nullptr is passed if the unit is the deparser, and deparser is always strictly dominated by
    // tables.
    if (t1 == nullptr) return false;
    if (t2 == nullptr) return true;
    if (t1->gress != t2->gress) return false;
    const ImmediateDominatorMap* iDom = iDominator.at(t1->gress);
    // For the source node, immediate dominator is the same as the node. Therefore, loop until we
    // reach the source node.
    while (t2 != iDom->at(t2)) {
        t2 = iDom->at(t2);
        if (t2 == t1) return true;
    }
    return false;
}

const std::vector<const IR::MAU::Table*>
BuildDominatorTree::getAllDominators(const IR::MAU::Table* t, gress_t gress) const {
    std::vector<const IR::MAU::Table*> rv;
    const ImmediateDominatorMap* iDom = iDominator.at(gress);
    while (t != iDom->at(t)) {
        t = iDom->at(t);
        rv.push_back(t);
    }
    return rv;
}

const IR::MAU::Table*
BuildDominatorTree::getNonGatewayGroupDominator(ordered_set<const IR::MAU::Table*>& tables) const {
    // Validate that all tables are of the same gress.
    boost::optional<gress_t> gress = boost::none;
    for (const auto* t : tables) {
        if (!gress) {
            gress = t->gress;
            continue;
        }
        if (*gress != t->gress)
            BUG("Call to getNonGatewayGroupDominator with tables of different gresses.");
    }

    // Find all the nodes from the given table to the source.
    ordered_map<const IR::MAU::Table*, std::vector<const IR::MAU::Table*>> pathsToSource;
    boost::optional<unsigned> minDepth = boost::none;
    for (const auto* t : tables) {
        pathsToSource[t] = getAllDominators(t, gress.get());
        LOG3("\t\t\tTable " << t->name << " is at depth " << pathsToSource[t].size() << " in the "
             "dominator tree.");
        if (minDepth == boost::none || pathsToSource[t].size() < *minDepth) {
            minDepth = pathsToSource[t].size();
            LOG4("\t\t\t  Setting minDepth to " << *minDepth);
        }
    }
    if (minDepth)
        LOG3("\t\t  Min depth: " << minDepth.get());

    // Trim all the nodes that are greater in depth than the minimum depth. Note that the position
    // of table pointers in the vector are reversed; i.e. the 0th position in the vector is
    // occupied by the immediate dominator, or the node deepest in the path from the source to the
    // dominator node in question.
    for (const auto* t : tables) {
        LOG4("\t\t\tReducing the size paths for table " << t->name);
        unsigned tableDepth = pathsToSource[t].size();
        while (tableDepth > minDepth.get()) {
            std::stringstream ss;
            ss << "\t\t\t\tErasing " << pathsToSource[t].at(0)->name << "; new table depth: ";
            pathsToSource[t].erase(pathsToSource[t].begin());
            tableDepth = pathsToSource[t].size();
            ss << tableDepth;
            LOG4(ss.str());
        }
        if (minDepth)
            LOG4("\t\t\t  minDepth: " << minDepth.get() << ", new  depth: " <<
                    pathsToSource[t].size());
        BUG_CHECK(minDepth && pathsToSource[t].size() == minDepth.get(), "Paths for table %1% (%2%)"
                  " not reduced" " to the min depth %3%", t->name, pathsToSource[t].size(),
                  minDepth.get());
    }

    // Starting from the minDepth level, keep going up one level at a time and see if we encounter
    // the same table. If we do encounter the same table, then that table is the group dominator.
    // Return the non gateway dominator for that group dominator.
    for (unsigned i = 0; minDepth && i < minDepth.get(); ++i) {
        boost::optional<const IR::MAU::Table*> dom;
        bool foundCommonAncestor = true;
        LOG4("\t\t\t  i = " << i);
        for (const auto* t : tables) {
            if (!dom) {
                dom = pathsToSource[t].at(i);
                LOG4("\t\t\t\tNew table encountered: " << (*dom)->name);
                continue;
            }
            if (dom && dom.get() != pathsToSource[t].at(i)) {
                LOG4("\t\t\t\t  Found a different table: " << pathsToSource[t].at(i)->name);
                foundCommonAncestor = false;
                break;
            }
        }
        if (foundCommonAncestor) {
            LOG3("\t\t\t  Found common ancestor: " << (*dom)->name);
            if ((*dom)->gateway_only()) {
                auto rv = getNonGatewayImmediateDominator(*dom, (*dom)->gress);
                if (!rv) return nullptr;
                return *rv;
            }
            return *dom;
        }
    }
    return nullptr;
}

cstring BuildDominatorTree::hasImmediateDominator(gress_t g, cstring t) const {
    BUG_CHECK(g < iDominator.size(), "Invalid gress %1% for unit %2%", g, t);
    const ImmediateDominatorMap* iDom = iDominator.at(g);
    for (auto kv : *iDom) {
        // If it is a sink node, then check corresponding to the nullptr entry in the dominator map.
        if (kv.first == nullptr && t == "SINK") return kv.second->name;
        if (kv.first == nullptr) continue;
        if (kv.first->name != t) continue;
        return kv.second->name;
    }
    return cstring();
}

bool BuildDominatorTree::strictlyDominates(cstring t1, cstring t2, gress_t gress) const {
    const ImmediateDominatorMap* iDom = iDominator.at(gress);
    const IR::MAU::Table* tbl1;
    const IR::MAU::Table* tbl2;
    for (auto kv : *iDom) {
        if (kv.first == nullptr) continue;
        if (kv.first->name == t1) tbl1 = kv.first;
        if (kv.first->name == t2) tbl2 = kv.first;
    }
    return strictlyDominates(tbl1, tbl2);
}

bool BuildDominatorTree::isDominator(cstring t1, gress_t gress, cstring t2) const {
    const ImmediateDominatorMap* iDom = iDominator.at(gress);
    const IR::MAU::Table* tbl1;
    const IR::MAU::Table* tbl2;
    for (auto kv : *iDom) {
        if (kv.first == nullptr) continue;
        if (kv.first->name == t1) tbl1 = kv.first;
        if (kv.first->name == t2) tbl2 = kv.first;
    }
    if (!tbl1) return false;
    if (!tbl2) return false;
    const auto dominators = getAllDominators(tbl1, gress);
    return (std::find(dominators.begin(), dominators.end(), tbl2) != dominators.end());
}
