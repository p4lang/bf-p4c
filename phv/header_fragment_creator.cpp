#include "header_fragment_creator.h"
#include "ir/ir.h"

const IR::Node*
HeaderFragmentCreator::preorder(IR::Member *field_ref) {
  if (field_ref->member.name[0] != '$' &&
      field_ref->expr->type->is<IR::Type_StructLike>()) {
    return new IR::HeaderSliceRef(field_ref); }
  return field_ref;
}
