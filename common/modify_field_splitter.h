#ifndef BACKENDS_TOFINO_MODIFY_FIELD_SPLITTER_
#define BACKENDS_TOFINO_MODIFY_FIELD_SPLITTER_
#include "ir/ir.h"
class ModifyFieldSplitter : public Transform {
 public:
  const IR::Node *preorder(IR::Primitive *primitive) override;
};
#endif
