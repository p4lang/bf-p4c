#include "copy_header_eliminator.h"

const IR::Node *
CopyHeaderEliminator::preorder(IR::Primitive *primitive) {
    if (primitive->name == "copy_header" || primitive->name == "modify_field") {
        auto dst_hdr_ref = primitive->operands[0]->to<const IR::HeaderRef>();
        auto src_hdr_ref = primitive->operands[1]->to<const IR::HeaderRef>();
        if (primitive->name == "modify_field" && !dst_hdr_ref) return primitive;
        // replace with a sequence of modify_field primitives for each field
        BUG_CHECK(dst_hdr_ref, "Invalid destination header in %s", primitive->toString());
        BUG_CHECK(src_hdr_ref, "Invalid source header in %s", primitive->toString());
        // Assuming that type-checker has ensured that both src and dst have same
        // header type.
        BUG_CHECK(dst_hdr_ref->type == src_hdr_ref->type,
                  "Type mismatch in copy_header: %s and %s",
                  dst_hdr_ref->type->toString(), src_hdr_ref->type->toString());
        auto *hdr_type = dst_hdr_ref->type->to<IR::Type_StructLike>();
        auto rv = new IR::Vector<IR::Primitive>;
        for (auto field : hdr_type->fields) {
            auto dst = new IR::Member(dst_hdr_ref->srcInfo, field->type, dst_hdr_ref, field->name);
            auto src = new IR::Member(src_hdr_ref->srcInfo, field->type, src_hdr_ref, field->name);
            rv->push_back(new IR::Primitive(primitive->srcInfo, "modify_field", dst, src)); }
        if (!dst_hdr_ref->baseRef()->is<IR::Metadata>()) {
            auto validtype = IR::Type::Bits::get(1);
            auto dst = new IR::Member(dst_hdr_ref->srcInfo, validtype, dst_hdr_ref, "$valid");
            IR::Expression *src;
            if (!src_hdr_ref->baseRef()->is<IR::Metadata>())
                src = new IR::Member(src_hdr_ref->srcInfo, validtype, src_hdr_ref, "$valid");
            else
                src = new IR::Constant(validtype, 1);
            rv->push_back(new IR::Primitive(primitive->srcInfo, "modify_field", dst, src)); }
        return rv; }
    if (primitive->name == "add_header" || primitive->name == "setValid" ||
        primitive->name == "remove_header" || primitive->name == "setInvalid") {
        auto hdr_ref = primitive->operands[0]->to<const IR::HeaderRef>();
        BUG_CHECK(hdr_ref, "Invalid destination header in %s", primitive->toString());
        BUG_CHECK(!hdr_ref->baseRef()->is<IR::Metadata>(), "Can't %s metadata", primitive);
        auto validtype = IR::Type::Bits::get(1);
        auto dst = new IR::Member(hdr_ref->srcInfo, validtype, hdr_ref, "$valid");
        auto src = new IR::Constant(validtype,
            primitive->name == "add_header" || primitive->name == "setValid");
        return new IR::Primitive(primitive->srcInfo, "modify_field", dst, src); }
    return primitive;
}
