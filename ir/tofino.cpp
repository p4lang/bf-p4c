#include "ir/ir.h"

IR::InstanceRef::InstanceRef(IR::ID name, const IR::Type *t) {
    if (name.srcInfo.isValid()) srcInfo = name.srcInfo;
    this->type = t;
    if (auto *hdr = t->to<IR::Type_Header>()) {
        obj = new IR::Header(name, hdr);
    } else if (auto *meta = t->to<IR::Type_Struct>()) {
        obj = new IR::Metadata(name, meta);
        for (auto field : *meta->fields)
            if (field->type->is<IR::Type_StructLike>() || field->type->is<IR::Type_Stack>())
                nested.add(field->name, new InstanceRef(field->name, field->type));
    } else if (auto *stk = t->to<IR::Type_Stack>()) {
        obj = new IR::HeaderStack(name, stk->baseType->to<IR::Type_Header>(), stk->getSize());
    } else {
        BUG("Unhandled InstanceRef type %1%", t); }
}
