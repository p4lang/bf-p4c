#ifndef BACKENDS_TOFINO_CREATE_THREAD_LOCAL_INSTANCES_
#define BACKENDS_TOFINO_CREATE_THREAD_LOCAL_INSTANCES_
#include <ir/visitor.h>
#include <tofino/ir/tofino.h>

namespace IR {
  class NamedRef;
  class Tofino_Parser;
  class Tofino_Deparser;
} // end namespace IR

// This Visitor creates a thread-local instance of every metadata and header
// instance. The name of the new instance is gress-name::instance-name.
// TODO: When header/metadata instances are added to MAU_Pipe, this class must
// create 2 copies (one for each thread) of every header/metadata instance
// object.
class CreateThreadLocalInstances : public Modifier {
 public:
  CreateThreadLocalInstances();
  ~CreateThreadLocalInstances() { }
  // Always returns true. It prepends "thread-name::" to named_ref->name.
  bool preorder(IR::NamedRef *named_ref) override;
  bool preorder(IR::Tofino_Parser *parser) override;
  void postorder(IR::Tofino_Deparser *deparser) override;
 private:
  gress_t gress_;
  bool    gress_valid_;
};

#endif /* TOFINO_BACKEND_CREATE_THREAD_LOCAL_INSTANCES_ */
