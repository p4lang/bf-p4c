#include "copy_header_eliminator.h"

bool
CopyHeaderEliminator::preorder(IR::Primitive *primitive) {
  if (primitive->name == "copy_header") {
    copy_headers_.push_back(primitive);
  }
  return false;
}

void
CopyHeaderEliminator::postorder(IR::ActionFunction *action_function) {
  // Insert modify_field primitives.
  for (const IR::Primitive *cp_hdr : copy_headers_) {
    auto dst_hdr_ref = dynamic_cast<const IR::HeaderRef*>(cp_hdr->operands[0]);
    auto src_hdr_ref = dynamic_cast<const IR::HeaderRef*>(cp_hdr->operands[1]);
    // Assuming that type-checker has ensured that both src and dst have same
    // header type.
    assert (dst_hdr_ref->type == src_hdr_ref->type);
    // TODO: Use modify_field to copy POVRef too.
    for (int i = 0; i < dst_hdr_ref->type->width_bits(); i+=8) {
      action_function->action.push_back(
        new IR::Primitive(cp_hdr->srcInfo, "modify_field",
                          new IR::FragmentRef(dst_hdr_ref->srcInfo,
                                              dst_hdr_ref, i, 8),
                          new IR::FragmentRef(src_hdr_ref->srcInfo,
                                              src_hdr_ref, i, 8)));
    }
  }
  // Remove the copy header primitives.
  auto cp_hdr_iter = copy_headers_.begin();
  auto primitive_iter = action_function->action.begin();
  while (cp_hdr_iter != copy_headers_.end() &&
         primitive_iter != action_function->action.end()) {
    if (*(*primitive_iter) == *(*cp_hdr_iter)) {
      primitive_iter = action_function->action.erase(primitive_iter);
      cp_hdr_iter = copy_headers_.erase(cp_hdr_iter);
    }
    else ++primitive_iter;
  }
  // Sanity check: Make sure that we replaced all the copy_header primitives
  // that we visited.
  assert (copy_headers_.empty());
}
