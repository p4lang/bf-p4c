#ifndef BACKENDS_TOFINO_COPY_HEADER_ELIMINATOR_
#define BACKENDS_TOFINO_COPY_HEADER_ELIMINATOR_
#include "ir/ir.h"
#include <list>
class CopyHeaderEliminator : public Modifier {
 public:
  bool preorder(IR::Primitive *primitive);
  void postorder(IR::ActionFunction *action_function);
 private:
  // This list stores all copy_header primitives in an action.
  std::list<const IR::Primitive *> copy_headers_;
};
#endif
