#ifndef EXTENSIONS_BF_P4C_IR_CONTROL_FLOW_VISITOR_H_
#define EXTENSIONS_BF_P4C_IR_CONTROL_FLOW_VISITOR_H_

#include "ir/ir.h"

namespace BFN {

class ControlFlowVisitor : public ::ControlFlowVisitor {
 protected:
    /** Most control flow visitors in the back end probably only want
     * ParserState and TableSeq join points; by default, filter all others.
     *
     * XXX(cole): If IR::BFN::ParserPrimitive nodes are not specifically
     * excluded from join points, then they (and their children) will be
     * visited out of control flow order.
     *
     * @warning Children overriding this method MUST filter (return true) if @n
     * is an IR::BFN::ParserPrimitive node.
     */
    bool filter_join_point(const IR::Node *n) override {
        return !n->is<IR::BFN::ParserState>() && !n->is<IR::MAU::TableSeq>();
    }
};

};  // end namespace BFN

#endif /* EXTENSIONS_BF_P4C_IR_CONTROL_FLOW_VISITOR_H_ */
