#ifndef BF_P4C_IR_GATEWAY_CONTROL_FLOW_H_
#define BF_P4C_IR_GATEWAY_CONTROL_FLOW_H_

#include "ir/ir.h"
#include "ir/visitor.h"
#include "control_flow_visitor.h"

namespace BFN {

/** Mixin class for ControlFlowVisitor to allow better tracking of gateway dependent
 *  information
 * A Visitor subclass may inherit from this (instead of directly from ControlFlowVisitor)
 * in order to get better notification about visiting the gateway-dependent (or match-action
 * dependent) next chains of a table.  When visiting an IR::MAU::Table's children with a
 * visitor that inherits from this mixin, the `pre_visit_table_next` method will be called
 * just before visiting each next chain.  This method can then update the visitor's internal
 * info to propagate knowledge of the gateway tests.  Any info can be computed here, or
 * computed when visiting the gateway expressions (which will be before visiting all the
 * next chains).
 * This should be useful for any type of value inferencing where info about the values
 * of any fields/metadata/headers/POV bits can be inferred from the gateway condition.
 */
class GatewayControlFlow : public virtual ControlFlowVisitor {
 protected:
    /** iff we're currently visiting a gateway expression, `gateway_context` will return
     * the containing table, and either the gateway expression index being visited or
     * the tag of the gateway expression */
    const IR::MAU::Table *gateway_context(int &idx) const;
    const IR::MAU::Table *gateway_context(cstring &tag) const;
    /** if we're currently visiting a gateway expression, will return all the tags on
     * gateway rows before or after the row we are currently visiting */
    std::set<cstring> gateway_earlier_tags() const;
    std::set<cstring> gateway_later_tags() const;

 public:
    virtual void pre_visit_table_next(const IR::MAU::Table *tbl, cstring tags) = 0;
};

}  // end namespace BFN

#endif /* BF_P4C_IR_GATEWAY_CONTROL_FLOW_H_ */
