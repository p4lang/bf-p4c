#ifndef _TOFINO_THREAD_VISITOR_H_
#define _TOFINO_THREAD_VISITOR_H_

#include "ir/visitor.h"

class ThreadVisitor : public virtual Visitor {
  friend class  IR::Tofino_Pipe;
  gress_t       thread;
 public:
  explicit ThreadVisitor(gress_t th) : thread(th) {}
};

#endif /* _TOFINO_THREAD_VISITOR_H_ */
