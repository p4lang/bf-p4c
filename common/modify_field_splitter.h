#ifndef TOFINO_COMMON_MODIFY_FIELD_SPLITTER_H_
#define TOFINO_COMMON_MODIFY_FIELD_SPLITTER_H_

#include "ir/ir.h"
class ModifyFieldSplitter : public Transform {
 public:
  const IR::Node *preorder(IR::Primitive *primitive) override;
};

#endif /* TOFINO_COMMON_MODIFY_FIELD_SPLITTER_H_ */
