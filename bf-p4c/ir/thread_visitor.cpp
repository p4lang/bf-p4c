#include "thread_visitor.h"

gress_t VisitingThread(const Visitor *v) {
    const Visitor::Context *ctxt = nullptr;
    if (v->findContext<IR::BFN::Pipe>(ctxt))
        return gress_t(ctxt->child_index / 3);
    BUG("Not visiting a BFN::Pipe");
}

