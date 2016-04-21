#ifndef _TOFINO_PHV_HEADER_FRAGMENT_CREATOR_H_
#define _TOFINO_PHV_HEADER_FRAGMENT_CREATOR_H_
#include "ir/ir.h"
class HeaderFragmentCreator : public Transform {
 public:
  const IR::Expression *preorder(IR::Member *field_ref) override;
  const IR::Expression *postorder(IR::Slice *slice) override;
};
#endif /* _TOFINO_PHV_HEADER_FRAGMENT_CREATOR_H_ */
