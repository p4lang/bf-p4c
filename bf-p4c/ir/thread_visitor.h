#ifndef BF_P4C_IR_THREAD_VISITOR_H_
#define BF_P4C_IR_THREAD_VISITOR_H_

#include "ir/ir.h"

class ThreadVisitor : public virtual Visitor {
    friend class  IR::BFN::Pipe;
    gress_t       thread;
 public:
    explicit ThreadVisitor(gress_t th) : thread(th) {}
    friend gress_t VisitingThread(ThreadVisitor *v) { return v->thread; }
};

extern gress_t VisitingThread(const Visitor *v);

#endif /* BF_P4C_IR_THREAD_VISITOR_H_ */
