#include "ir/ir.h"

/* static */ size_t IR::BFN::UnresolvedStackRef::nextId = 0;
/* static */ size_t IR::BFN::ContainerRef::nextId = 0;

IR::InstanceRef::InstanceRef(cstring prefix, IR::ID n, const IR::Type *t,
                             const IR::Annotations *ann)
: HeaderRef(t), name(n) {
    if (n.srcInfo.isValid()) srcInfo = n.srcInfo;
    if (prefix)
        name.name = prefix + "." + n.name;
    IR::HeaderOrMetadata *obj = nullptr;
    if (auto *hdr = t->to<IR::Type_Header>()) {
        obj = new IR::Header(name, hdr);
    } else if (auto *meta = t->to<IR::Type_Struct>()) {
        obj = new IR::Metadata(name, meta);
        for (auto f : meta->fields)
            if (f->type->is<IR::Type_StructLike>() || f->type->is<IR::Type_Stack>())
                nested.add(name + "." + f->name,
                           new InstanceRef(name, f->name, f->type));
    } else if (auto *stk = t->to<IR::Type_Stack>()) {
        obj = new IR::HeaderStack(name, stk->elementType->to<IR::Type_Header>(), stk->getSize());
    } else if (t->is<IR::Type::Bits>() || t->is<IR::Type::Boolean>() || t->is<IR::Type_Set>()) {
        obj = nullptr;
    } else if (auto *meta = t->to<IR::BFN::Type_StructFlexible>()) {
        obj = new IR::Metadata(name, meta);
        for (auto f : meta->fields)
            if (f->type->is<IR::Type_StructLike>() || f->type->is<IR::Type_Stack>())
                nested.add(name + "." + f->name,
                           new InstanceRef(name, f->name, f->type));
    } else {
        P4C_UNIMPLEMENTED("Unsupported type %s %s", t, n); }
    if (obj && ann)
        obj->annotations = ann;
    this->obj = obj;
}

/* a V1InstanceRef is the same as an InstanceRef except we ignore the prefix -- see tofino.def
 * we also don't handle StructFlexible as that never occurs in V1 */
IR::V1InstanceRef::V1InstanceRef(cstring /* prefix */, IR::ID n, const IR::Type *t,
                                 const IR::Annotations *ann)
: InstanceRef(t) {
    name = n;
    if (n.srcInfo.isValid()) srcInfo = n.srcInfo;
    IR::HeaderOrMetadata *obj = nullptr;
    if (auto *hdr = t->to<IR::Type_Header>()) {
        obj = new IR::Header(n, hdr);
    } else if (auto *meta = t->to<IR::Type_Struct>()) {
        obj = new IR::Metadata(n, meta);
        for (auto f : meta->fields)
            if (f->type->is<IR::Type_StructLike>() || f->type->is<IR::Type_Stack>())
                nested.add(f->name, new V1InstanceRef(n, f->name, f->type));
    } else if (auto *stk = t->to<IR::Type_Stack>()) {
        obj = new IR::HeaderStack(n, stk->elementType->to<IR::Type_Header>(), stk->getSize());
    } else if (t->is<IR::Type::Bits>() || t->is<IR::Type::Boolean>() || t->is<IR::Type_Set>()) {
        obj = nullptr;
    } else {
        P4C_UNIMPLEMENTED("Unsupported P4_14 type %s %s", t, n); }
    if (obj && ann)
        obj->annotations = ann;
    this->obj = obj;
}

int IR::TempVar::uid = 0;

