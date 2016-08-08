#include "ir/ir.h"

IR::InstanceRef::InstanceRef(cstring prefix, IR::ID name, const IR::Type *t, bool forceMeta) {
    if (name.srcInfo.isValid()) srcInfo = name.srcInfo;
    cstring iname = name.name;
    if (prefix && forceMeta)
        iname = prefix + "." + iname;
    this->type = t;
    if (auto *hdr = t->to<IR::Type_Header>()) {
        if (forceMeta)
            obj = new IR::Metadata(iname, hdr);
        else
            obj = new IR::Header(iname, hdr);
    } else if (auto *meta = t->to<IR::Type_Struct>()) {
        obj = new IR::Metadata(iname, meta);
        for (auto f : *meta->fields)
            if (f->type->is<IR::Type_StructLike>() || f->type->is<IR::Type_Stack>())
                nested.add(f->name, new InstanceRef(iname, f->name, f->type, forceMeta));
    } else if (auto *stk = t->to<IR::Type_Stack>()) {
        if (forceMeta)
            BUG("metadata arrays not handled in InstanceRef::InstanceRef");
        obj = new IR::HeaderStack(iname, stk->baseType->to<IR::Type_Header>(), stk->getSize());
    } else {
        BUG("Unhandled InstanceRef type %1%", t); }
}
