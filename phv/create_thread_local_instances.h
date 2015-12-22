#ifndef _TOFINO_CREATE_THREAD_LOCAL_INSTANCES_H_
#define _TOFINO_CREATE_THREAD_LOCAL_INSTANCES_H_
#include "ir/ir.h"

// This Visitor creates a thread-local instance of every metadata and header
// instance. The name of the new instance is gress-name::instance-name.
// TODO: When header/metadata instances are added to MAU_Pipe, this class must
// create 2 copies (one for each thread) of every header/metadata instance
// object.
class CreateThreadLocalInstances : public Modifier, ThreadVisitor {
 public:
  explicit CreateThreadLocalInstances(gress_t th) : ThreadVisitor(th), gress_(th) {}
  // Always returns true. It prepends "thread-name::" to named_ref->name.
  bool preorder(IR::NamedHeaderRef *hdr_ref) override;
 private:
  gress_t gress_;
};

#endif /* _TOFINO_CREATE_THREAD_LOCAL_INSTANCES_H_ */
