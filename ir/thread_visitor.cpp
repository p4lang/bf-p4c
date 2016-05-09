#include "thread_visitor.h"

gress_t VisitingThread(Visitor *v) {
    const Visitor::Context *ctxt = nullptr;
    if (v->findContext<IR::Tofino::Pipe>(ctxt))
        return gress_t(ctxt->child_index / 3);
    BUG("Not visiting a Tofino::Pipe");
}
