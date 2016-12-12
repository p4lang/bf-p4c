#include "split_header.h"

IR::Node *SplitExtractEmit::preorder(IR::Primitive *p) {
    if (p->name != "extract" && p->name != "emit")
        return p;
    assert(p->operands.size() == 1);
    auto *hdr = p->operands[0]->to<IR::HeaderRef>();
    if (!hdr) return p;
    auto *rv = new IR::Vector<IR::Expression>;
    auto *hdr_type = hdr->type->to<IR::Type_StructLike>();
    assert(hdr_type);
    for (auto field : *hdr_type->fields) {
        IR::Expression *fref = new IR::Member(field->type, hdr, field->name);
        rv->push_back(new IR::Primitive(p->srcInfo, p->name, fref)); }
    if (p->name == "extract" && !hdr->baseRef()->is<IR::Metadata>()) {
        rv->push_back(new IR::Primitive(p->srcInfo, "set_metadata",
            new IR::Member(IR::Type::Bits::get(1), hdr, "$valid"),
            new IR::Constant(1))); }
    return rv;
}
