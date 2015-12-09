#include "header_fragment_creator.h"
#include "ir/ir.h"

const IR::Node*
HeaderFragmentCreator::preorder(IR::FieldRef *field_ref) {
  IR::Node *new_node = field_ref;
  const IR::HeaderType *header_type = IR::GetHeaderType(*field_ref);
  if (nullptr != header_type) {
    new_node = new IR::FragmentRef(*field_ref);
  }
  return new_node;
}
