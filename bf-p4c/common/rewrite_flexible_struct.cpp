#include "common/rewrite_flexible_struct.h"
#include "lib/pad_alignment.h"

namespace BFN {

bool DoRewriteFlexibleStruct::findFlexibleAnnotation(const IR::Type_StructLike* header) {
    for (auto f : header->fields) {
        if (f->type->is<IR::Type_Bits>() || f->type->is<IR::Type_Varbits>())
            continue;
        auto canonicalType = typeMap->getTypeType(f->type, true);
        if (auto st = canonicalType->to<IR::Type_StructLike>()) {
            auto anno = st->getAnnotation("flexible");
            if (anno != nullptr)
                return true;
            if (findFlexibleAnnotation(st))
                return true; } }
    return false;
}

const IR::Node* DoRewriteFlexibleStruct::preorder(IR::Type_Struct* st) {
    if (!st->getAnnotation("flexible"))
        return st;

    IR::IndexedVector<IR::StructField> structFields;
    unsigned padFieldId = 0;
    for (auto& field : st->fields) {
        // Add padding field for every bridged metadata field to ensure that the resulting
        // header is byte aligned.
        const int alignment = getAlignment(field->type->width_bits());
        if (alignment != 0) {
            cstring padFieldName = "__pad_";
            padFieldName += cstring::to_cstring(padFieldId++);
            auto *fieldAnnotations = new IR::Annotations({
                new IR::Annotation(IR::ID("hidden"), {})});
            structFields.push_back(new IR::StructField(padFieldName, fieldAnnotations,
                                                       IR::Type::Bits::get(alignment)));
        }
        structFields.push_back(field);
    }

    auto retval = new IR::BFN::Type_StructFlexible(st->srcInfo, st->name, structFields);
    LOG6("rewrite flexible struct " << retval);
    return retval;
}

}  // namespace BFN
