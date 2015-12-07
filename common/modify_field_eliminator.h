#ifndef BACKENDS_TOFINO_MODIFY_FIELD_ELIMINATOR_
#define BACKENDS_TOFINO_MODIFY_FIELD_ELIMINATOR_
#include "ir/ir.h"
class ModifyFieldEliminator : public Transform {
 public:
  const IR::Node *preorder(IR::Primitive *primitive) override {
    if (primitive->name == "modify_field") {
      // All modify_field primitives should have been normalized.
      assert(primitive->operands.size() == 3);
      auto mask = dynamic_cast<const IR::Constant*>(primitive->operands[2]);
      assert(nullptr != mask);
      if (0 == mask->asLong()) primitive = nullptr;
    }
    return primitive;
  }
};
#endif
