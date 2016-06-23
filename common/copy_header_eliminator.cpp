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
    auto *hdr_type = dst_hdr_ref->type->to<IR::Type_StructLike>();
    auto rv = new IR::Vector<IR::Primitive>;
    for (auto field : *hdr_type->fields) {
      auto dst = new IR::Member(dst_hdr_ref->srcInfo, field->type, dst_hdr_ref, field->name);
      auto src = new IR::Member(src_hdr_ref->srcInfo, field->type, src_hdr_ref, field->name);
      rv->push_back(new IR::Primitive(primitive->srcInfo, "modify_field", dst, src)); }
    auto dst = new IR::Member(dst_hdr_ref->srcInfo, IR::Type::Bits::get(1), dst_hdr_ref, "$valid");
    auto src = new IR::Member(src_hdr_ref->srcInfo, IR::Type::Bits::get(1), src_hdr_ref, "$valid");
    rv->push_back(new IR::Primitive(primitive->srcInfo, "modify_field", dst, src));
    return rv;
  }
  return primitive;
}
