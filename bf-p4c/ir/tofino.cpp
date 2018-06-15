#include "ir/ir.h"

/* static */ size_t IR::BFN::UnresolvedStackRef::nextId = 0;
/* static */ size_t IR::BFN::ContainerRef::nextId = 0;

IR::InstanceRef::InstanceRef(cstring prefix, IR::ID n, const IR::Type *t, bool forceMeta)
: HeaderRef(t), name(n) {
    if (n.srcInfo.isValid()) srcInfo = n.srcInfo;
    if (prefix)
        name.name = prefix + "." + n.name;
    if (auto *hdr = t->to<IR::Type_Header>()) {
        if (forceMeta)
            obj = new IR::Metadata(name, hdr);
        else
            obj = new IR::Header(name, hdr);
    } else if (auto *meta = t->to<IR::Type_Struct>()) {
        obj = new IR::Metadata(name, meta);
        for (auto f : meta->fields)
            if (f->type->is<IR::Type_StructLike>() || f->type->is<IR::Type_Stack>())
                nested.add(name + "." + f->name,
                           new InstanceRef(name, f->name, f->type, forceMeta));
    } else if (auto *stk = t->to<IR::Type_Stack>()) {
        if (forceMeta)
            P4C_UNIMPLEMENTED("metadata arrays not handled in InstanceRef::InstanceRef");
        obj = new IR::HeaderStack(name, stk->elementType->to<IR::Type_Header>(), stk->getSize());
    } else if (t->is<IR::Type::Bits>() || t->is<IR::Type::Boolean>() || t->is<IR::Type_Set>()) {
        obj = nullptr;
    } else {
        P4C_UNIMPLEMENTED("Unhandled InstanceRef type %1%", t); }
}

IR::V1InstanceRef::V1InstanceRef(cstring prefix, IR::ID n, const IR::Type *t, bool forceMeta)
: InstanceRef(t) {
    name = n;
    if (n.srcInfo.isValid()) srcInfo = n.srcInfo;
    if (prefix && forceMeta)
        name.name = prefix + "." + n.name;
    if (auto *hdr = t->to<IR::Type_Header>()) {
        if (forceMeta)
            obj = new IR::Metadata(n, hdr);
        else
            obj = new IR::Header(n, hdr);
    } else if (auto *meta = t->to<IR::Type_Struct>()) {
        obj = new IR::Metadata(n, meta);
        for (auto f : meta->fields)
            if (f->type->is<IR::Type_StructLike>() || f->type->is<IR::Type_Stack>())
                nested.add(f->name, new V1InstanceRef(n, f->name, f->type, forceMeta));
    } else if (auto *stk = t->to<IR::Type_Stack>()) {
        if (forceMeta)
            P4C_UNIMPLEMENTED("metadata arrays not handled in V1InstanceRef::V1InstanceRef");
        obj = new IR::HeaderStack(n, stk->elementType->to<IR::Type_Header>(), stk->getSize());
    } else if (t->is<IR::Type::Bits>() || t->is<IR::Type::Boolean>() || t->is<IR::Type_Set>()) {
        obj = nullptr;
    } else {
        P4C_UNIMPLEMENTED("Unhandled V1InstanceRef type %1%", t); }
}

int IR::TempVar::uid = 0;
