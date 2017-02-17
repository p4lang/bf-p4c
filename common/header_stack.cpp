#include "header_stack.h"

Visitor::profile_t HeaderStackInfo::init_apply(const IR::Node *root) {
    info.clear();
    return Inspector::init_apply(root);
}

void HeaderStackInfo::postorder(const IR::HeaderStack *hs) {
    auto &i = info[hs->name];
    i.name = hs->name;
    i.size = hs->size;
    i.maxpush = i.maxpop = 0;
    if (i.name.startsWith("ingress::"))
        i.gress = INGRESS;
    else if (i.name.startsWith("egress::"))
        i.gress = EGRESS;
    else
        BUG("Can't determine thread");
}

void HeaderStackInfo::postorder(const IR::Primitive *prim) {
    if (prim->name == "push" || prim->name == "pop") {
        BUG_CHECK(prim->operands.size() == 2, "wrong number of operands to %s", prim);
        cstring hsname = prim->operands[0]->toString();
        if (!info.count(hsname)) {
            /* Should have been caught by typechecking? */
            error("%s: No header stack %s", prim->srcInfo, prim->operands[0]);
            return; }
        int &max = (prim->name == "push") ? at(hsname).maxpush : at(hsname).maxpop;
        if (auto count = prim->operands[1]->to<IR::Constant>()) {
            auto countval = count->asInt();
            if (countval <= 0)
                error("%s: %s amount must be > 0", count->srcInfo, prim->name);
            else if (countval > max)
                max = countval;
        } else {
            error("%s: %s amount must be constant", prim->operands[1]->srcInfo, prim->name); } }
}
