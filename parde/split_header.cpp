#include "split_header.h"

IR::Node *SplitExtractEmit::preorder(IR::Primitive *p) {
    if (p->name != "extract" && p->name != "emit")
        return p;
    assert(p->operands.size() == 1);
    auto *hdr = p->operands[0]->to<IR::HeaderRef>();
    if (!hdr) return p;
    auto *rv = new IR::Vector<IR::Expression>;
    auto *hdr_type = hdr->type->to<IR::HeaderType>();
    assert(hdr_type);
    for (auto &field : hdr_type->fields)
        rv->push_back(new IR::Primitive(p->srcInfo, p->name,
            new IR::FieldRef(field.second, hdr, field.first)));
    if (p->name == "extract")
        rv->push_back(new IR::Primitive(p->srcInfo, "set_metadata",
            new IR::FieldRef(IR::Type::Bits::get(1), hdr, "$valid"),
            new IR::Constant(1)));
    return rv;
}
