#ifndef _TOFINO_PHV_HEADER_FRAGMENT_CREATOR_H_
#define _TOFINO_PHV_HEADER_FRAGMENT_CREATOR_H_
#include "ir/visitor.h"
class HeaderFragmentCreator : public Transform {
 public:
  const IR::Node* preorder(IR::FieldRef *field_ref) override;
};
#endif /* _TOFINO_PHV_HEADER_FRAGMENT_CREATOR_H_ */
