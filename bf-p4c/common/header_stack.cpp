#include "header_stack.h"

CollectHeaderStackInfo::CollectHeaderStackInfo()
  : stacks(new BFN::HeaderStackInfo) { }

void CollectHeaderStackInfo::postorder(IR::HeaderStack* hs) {
    auto &i = stacks->info[hs->name];
    i.name = hs->name;
    i.size = hs->size;
    i.maxpush = i.maxpop = 0;

    // By default, header stacks are visible in both threads, but if we've
    // already run CreateThreadLocalInstances then this header stack will only
    // be visible in a single thread.
    if (i.name.startsWith("ingress::"))
        i.inThread[EGRESS] = false;
    else if (i.name.startsWith("egress::"))
        i.inThread[INGRESS] = false;
}

void CollectHeaderStackInfo::postorder(IR::Primitive* prim) {
    if (prim->name == "push_front" || prim->name == "pop_front") {
        BUG_CHECK(prim->operands.size() == 2, "wrong number of operands to %s", prim);
        cstring hsname = prim->operands[0]->toString();
        if (!stacks->info.count(hsname)) {
            /* Should have been caught by typechecking? */
            error("%s: No header stack %s", prim->srcInfo, prim->operands[0]);
            return; }
        int &max = (prim->name == "push_front") ? stacks->at(hsname).maxpush
                                                : stacks->at(hsname).maxpop;
        if (auto count = prim->operands[1]->to<IR::Constant>()) {
            auto countval = count->asInt();
            if (countval <= 0)
                error("%s: %s amount must be > 0", count->srcInfo, prim->name);
            else if (countval > max)
                max = countval;
        } else {
            error("%s: %s amount must be constant", prim->operands[1]->srcInfo, prim->name); } }
}

void CollectHeaderStackInfo::postorder(IR::BFN::Pipe* pipe) {
    // Store the information we've collected in
    // `IR::BFN::Pipe::headerStackInfo` so other passes can access it.
    pipe->headerStackInfo = stacks;
}
