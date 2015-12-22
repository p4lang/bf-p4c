#include "copy_header_eliminator.h"

const IR::Node *
CopyHeaderEliminator::preorder(IR::Primitive *primitive) {
  if (primitive->name == "copy_header") {
    // replace with a sequence of modify_field primitives
    auto dst_hdr_ref = dynamic_cast<const IR::HeaderRef*>(primitive->operands[0]);
    auto src_hdr_ref = dynamic_cast<const IR::HeaderRef*>(primitive->operands[1]);
    // Assuming that type-checker has ensured that both src and dst have same
    // header type.
    assert(dst_hdr_ref->type == src_hdr_ref->type);
    // TODO: Use modify_field to copy POVRef too.
    auto rv = new IR::Vector<IR::Primitive>;
    for (int i = 0; i < dst_hdr_ref->type->width_bits(); i+=8) {
      rv->push_back(
        new IR::Primitive(primitive->srcInfo, "modify_field",
                          new IR::FragmentRef(dst_hdr_ref->srcInfo,
                                              dst_hdr_ref, i, 8),
                          new IR::FragmentRef(src_hdr_ref->srcInfo,
                                              src_hdr_ref, i, 8)));
    }
    return rv;
  }
  return primitive;
}
