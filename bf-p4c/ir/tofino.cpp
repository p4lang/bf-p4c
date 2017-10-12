#include "ir/ir.h"

/* static */ size_t IR::BFN::UnresolvedStackRef::nextId = 0;
/* static */ size_t IR::BFN::ContainerRef::nextId = 0;

IR::InstanceRef::InstanceRef(cstring prefix, IR::ID name, const IR::Type *t, bool forceMeta)
: HeaderRef(t), name(name) {
    if (name.srcInfo.isValid()) srcInfo = name.srcInfo;
    if (prefix && forceMeta)
        name.name = prefix + "." + name.name;
    if (auto *hdr = t->to<IR::Type_Header>()) {
        if (forceMeta)
            obj = new IR::Metadata(name, hdr);
        else
            obj = new IR::Header(name, hdr);
    } else if (auto *meta = t->to<IR::Type_Struct>()) {
        obj = new IR::Metadata(name, meta);
        for (auto f : meta->fields)
            if (f->type->is<IR::Type_StructLike>() || f->type->is<IR::Type_Stack>())
                nested.add(f->name, new InstanceRef(name, f->name, f->type, forceMeta));
    } else if (auto *stk = t->to<IR::Type_Stack>()) {
        if (forceMeta)
            BUG("metadata arrays not handled in InstanceRef::InstanceRef");
        obj = new IR::HeaderStack(name, stk->elementType->to<IR::Type_Header>(), stk->getSize());
    } else if (t->is<IR::Type::Bits>() || t->is<IR::Type::Boolean>()) {
        obj = nullptr;
    } else {
        BUG("Unhandled InstanceRef type %1%", t); }
}

int IR::TempVar::uid = 0;
