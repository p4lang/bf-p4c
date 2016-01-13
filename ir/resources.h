#ifndef _TOFINO_IR_RESOURCES_H_
#define _TOFINO_IR_RESOURCES_H_

// This does not need the ir.h
#include "ir/visitor.h"

/* various resources needed for the back-end IR */

struct TableResourceAlloc;

enum gress_t { INGRESS, EGRESS };

inline std::ostream &operator<<(std::ostream &out, gress_t gress) {
    return out << (gress ? "egress" : "ingress"); }

class ThreadVisitor : public virtual Visitor {
  friend class  IR::Tofino_Pipe;
  gress_t       thread;
 public:
  explicit ThreadVisitor(gress_t th) : thread(th) {}
};

#endif /* _TOFINO_IR_RESOURCES_H_ */
