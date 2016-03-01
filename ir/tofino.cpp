#include "ir/ir.h"

IR::InstanceRef::InstanceRef(IR::ID name, const IR::Type_StructLike *t) : name(name) {
    if (auto *hdr = t->to<IR::Type_Header>()) {
        obj = new IR::Header(name, hdr);
    } else if (auto *meta = t->to<IR::Type_Struct>()) {
        obj = new IR::Metadata(name, meta);
        for (auto field : *meta->fields)
            if (auto type = field->type->to<IR::Type_StructLike>())
                nested.add(field->name, new InstanceRef(field->name, type));
    } else {
        BUG("Unhandled structlike type %1%", t); }
}

