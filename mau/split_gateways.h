#ifndef _split_gateways_h_
#define _split_gateways_h_

#include "ir/visitor.h"
#include "field_use.h"

class reason : public Backtrack::trigger {
};

class SplitGateways : public Transform, public Backtrack {
    FieldUse	uses;
    bool do_splitting = false;
    bool backtrack(trigger &trig) { do_splitting = !do_splitting; return do_splitting; }
    Visitor::profile_t init_apply(const IR::Node *) override;
    const IR::Node *postorder(IR::MAU::Table *) override;
};

#endif /* _split_gateways_h_ */
