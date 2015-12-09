#ifndef BACKENDS_TOFINO_HEADER_FRAGMENT_CREATOR_
#define BACKENDS_TOFINO_HEADER_FRAGMENT_CREATOR_
#include "ir/visitor.h"
class HeaderFragmentCreator : public Transform {
 public:
  const IR::Node* preorder(IR::FieldRef *field_ref) override;
};
#endif /* BACKENDS_TOFINO_HEADER_FRAGMENT_CREATOR_ */
