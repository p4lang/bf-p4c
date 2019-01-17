#include "common/rewrite_flexible_struct.h"

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

    auto retval = new IR::BFN::Type_StructFlexible(st->srcInfo, st->name, st->fields);
    LOG1("retval " << retval);
    return retval;
}

}  // namespace BFN
