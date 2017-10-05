#ifndef LIVE_AT_ENTRY_H_
#define LIVE_AT_ENTRY_H_

#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/ir/control_flow_visitor.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "lib/bitvec.h"

class LiveAtEntry : public BFN::ControlFlowVisitor, public Inspector, TofinoWriteContext {
    const PhvInfo       &phv;
    bitvec              &result, written;
    bool                flow_is_dead = false;

    profile_t init_apply(const IR::Node *root) override;
    void end_apply(const IR::Node *root) override;
    bool preorder(const IR::Expression *e) override;
    LiveAtEntry *clone() const override;
    void flow_dead() override { flow_is_dead = true; }
    void flow_merge(Visitor &a) override;
 public:
    explicit LiveAtEntry(const PhvInfo &phv) : phv(phv), result(*new bitvec) {
        joinFlows = true; visitDagOnce = false; }
    LiveAtEntry(const LiveAtEntry &) = default;
    LiveAtEntry(LiveAtEntry &&) = default;
};

#endif /* LIVE_AT_ENTRY_H_ */
