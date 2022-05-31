#ifndef EXTENSIONS_BF_P4C_IR_CONTROL_FLOW_VISITOR_H_
#define EXTENSIONS_BF_P4C_IR_CONTROL_FLOW_VISITOR_H_

#include "ir/ir.h"

namespace BFN {

class ControlFlowVisitor : public ::ControlFlowVisitor {
 protected:
    /** filter_join_points is only relevant for Visitors that set joinFlows = true
     * in their constructor. Most control flow visitors in the back end probably only want
     * ParserState, Table, and TableSeq join points; by default, filter all others.
     * This is relevant mostly because joinFlows does not really work properly, as flows
     * that join (node with mulitple parents) are only processed once all parents are
     * visited, *BUT* subsequent nodes (siblings after the join points) will be visited
     * immediately, *BEFORE* the join node is visited. This is, simply, wrong, but fixing
     * it requires multithreading or coroutines in the visitor infrastructure, which has not
     * yet been implemented. So some visitors need to also filter Tables (and visit them
     * repeatedly with visitDagOne = false or visitAgain) or they'll fail.
     *
     * XXX(cole): If IR::BFN::ParserPrimitive nodes are not specifically
     * excluded from join points, then they (and their children) will be
     * visited out of control flow order.
     *
     * @warning Children overriding this method MUST filter (return true) if @n
     * is an IR::BFN::ParserPrimitive node. This is due to the visit order misfeature
     * noted above.
     */
    bool filter_join_point(const IR::Node *n) override {
        return !n->is<IR::BFN::ParserState>() &&
               // !n->is<IR::MAU::Table>() &&
               !n->is<IR::MAU::TableSeq>();
    }
};

};  // end namespace BFN

#endif /* EXTENSIONS_BF_P4C_IR_CONTROL_FLOW_VISITOR_H_ */
