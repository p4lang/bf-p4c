#ifndef EXTENSIONS_BF_P4C_PHV_ANALYSIS_DOMINATOR_TREE_H_
#define EXTENSIONS_BF_P4C_PHV_ANALYSIS_DOMINATOR_TREE_H_

#include "ir/ir.h"
#include "bf-p4c/mau/table_flow_graph.h"

/** This class builds an immediate dominator tree using separate table flow graphs for ingress and
  * egress. This class uses the Lengauer-Tarjan dominator tree algorithm offered by boost.
  * This class maintains a map of table pointers, so must be rerun every time new table objects are
  * created (e.g. through gateway merge) and the associated flow graphs must be re-computed
  * accordingly.
  */
class BuildDominatorTree : public Inspector {
 public:
    /// map[x] = y, means that table y is the immediate dominator for table x.
    using ImmediateDominatorMap = ordered_map<const IR::MAU::Table*, const IR::MAU::Table*>;
    using G = FlowGraph::Graph;
    using Vertex = boost::graph_traits<G>::vertex_descriptor;
    using IndexMap = boost::property_map<G, boost::vertex_index_t>::type;
    using PredMap = boost::iterator_property_map<std::vector<Vertex>::iterator, IndexMap>;

 private:
    /// Maps each gress to its table flow graph.
    ordered_map<gress_t, FlowGraph>&              flowGraph;
    /// Maps each gress to its Immediate dominator map.
    ordered_map<gress_t, ImmediateDominatorMap*>  iDominator;

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::BFN::Pipe* pipe) override;

    /** Generates a map of indexes to a table pointer. Used as a helper function for building the
      * dominator tree.
      */
    void generateIndexToTableMap(
            const FlowGraph& fg,
            ordered_map<int, const IR::MAU::Table*>& indexMap) const;

    /** Generates a dominator tree based on a table flow graph @p fg.
     * Internally uses @p indexToTableMap generated by a call to generateIndexToTableMap() method
     * to identify various tables. The results are accessed via the @p iDom map.
     */
    void generateDominatorTree(
            const FlowGraph& fg,
            const ordered_map<int, const IR::MAU::Table*>& indexToTableMap,
            ImmediateDominatorMap& iDom);

    /** Prints the immediate dominator for each table in @p idom.
      */
    void printDominatorTree(const ImmediateDominatorMap& idom) const;

 public:
    /** @returns the flow graph associated with each gress in the program
      */
    const ordered_map<gress_t, FlowGraph>& getFlowGraph() const {
        return flowGraph;
    }

    /* setup dominator tree using flowGraph
     */
    void setupDomTree();

    /** @returns the immediate dominator table for @p t with @p gress.
     * @returns boost::none if there is no immediate dominator. If @p t is nullptr,
     * then it indicates the deparser, in which case the @p gress needs to be specified.
     */
    boost::optional<const IR::MAU::Table*>
        getImmediateDominator(const IR::MAU::Table* t, gress_t gress) const;

    /** @returns the non gateway immediate dominator for @p t belonging to @p gress. @returns
      * boost::none if there is no non-gateway immediate dominator. If @p t is nullptr, then it
      * indicates the deparser, in which case the @p gress needs to be specified.
      */
    boost::optional<const IR::MAU::Table*>
        getNonGatewayImmediateDominator(const IR::MAU::Table* t, gress_t gress) const;

    /** @returns true if the unit @p u1 strictly dominates unit @p u2.
      */
    bool strictlyDominates(const IR::BFN::Unit* u1, const IR::BFN::Unit* u2) const;

    /** @returns true if the table @p t1 strictly dominates table @p t2.
      */
    bool strictlyDominates(const IR::MAU::Table* t1, const IR::MAU::Table* t2) const;

    /** @returns the lowest common ancestor (group dominator) for the group of tables in @p tables.
      */
    const IR::MAU::Table*
        getNonGatewayGroupDominator(ordered_set<const IR::MAU::Table*>& tables) const;

    /** @returns a vector of tables that strictly dominate the give table @p t.
      */
    const std::vector<const IR::MAU::Table*>
        getAllDominators(const IR::MAU::Table* t, gress_t gress) const;

    explicit BuildDominatorTree(ordered_map<gress_t, FlowGraph>& fg) : flowGraph(fg) { }

    /// GTest methods.

    /** Used exclusively for gtests. Returns the immediate dominator of the table with name @p t
     * and gress @p g. Returns empty string if no dominator present.
     */
    cstring hasImmediateDominator(gress_t g, cstring t) const;

    /** Used exclusively for gtests. Returns true if the table with name @p t1 strictly dominates the
      * table with name @p t2 for @p gress.
      */
    bool strictlyDominates(cstring t1, cstring t2, gress_t gress) const;

    /** Used exclusively for gtests. Return true if the table with name @p t2 and @p gress is a
      * dominator of table with name @p t1.
      */
    bool isDominator(cstring t1, gress_t gress, cstring t2) const;
};
#endif  /* EXTENSIONS_BF_P4C_PHV_ANALYSIS_DOMINATOR_TREE_H_ */
