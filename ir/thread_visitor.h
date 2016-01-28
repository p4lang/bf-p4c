#ifndef _TOFINO_IR_THREAD_VISITOR_H_
#define _TOFINO_IR_THREAD_VISITOR_H_

#include "ir/ir.h"

class ThreadVisitor : public virtual Visitor {
  friend class  IR::Tofino::Pipe;
  gress_t       thread;
 public:
  explicit ThreadVisitor(gress_t th) : thread(th) {}
};

#endif /* _TOFINO_IR_THREAD_VISITOR_H_ */
