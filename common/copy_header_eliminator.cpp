#include "copy_header_eliminator.h"
#include "base/logging.h"

const IR::Node *
CopyHeaderEliminator::preorder(IR::Primitive *primitive) {
  if (primitive->name == "copy_header") {
    // replace with a sequence of modify_field primitives
    auto dst_hdr_ref = primitive->operands[0]->to<const IR::HeaderRef>();
    auto src_hdr_ref = primitive->operands[1]->to<const IR::HeaderRef>();
    CHECK_NE(nullptr, dst_hdr_ref) << "Invalid destination header in " <<
      primitive->toString();
    CHECK_NE(nullptr, src_hdr_ref) << "Invalid source header in " <<
      primitive->toString();
    // Assuming that type-checker has ensured that both src and dst have same
    // header type.
    CHECK_EQ(dst_hdr_ref->type, src_hdr_ref->type) <<
      "Type mismatch in copy_header: " << dst_hdr_ref->type->toString() <<
      " and " << src_hdr_ref->type->toString();
    // TODO: Use modify_field to copy POVRef too.
    auto rv = new IR::Vector<IR::Primitive>;
    auto dst_slice = new IR::HeaderSliceRef(dst_hdr_ref->srcInfo, dst_hdr_ref,
                                            dst_hdr_ref->type->width_bits() - 1,
                                            0);
    auto src_slice = new IR::HeaderSliceRef(src_hdr_ref->srcInfo, src_hdr_ref,
                                            src_hdr_ref->type->width_bits() - 1,
                                            0);
    rv->push_back(new IR::Primitive(primitive->srcInfo, "modify_field",
                                    dst_slice, src_slice));
    return rv;
  }
  return primitive;
}
