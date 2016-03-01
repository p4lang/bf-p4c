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
    if (p->name == "extract") {
        for (auto field : *hdr_type->fields)
            rv->push_back(new IR::Primitive(p->srcInfo, p->name,
                                            new IR::FieldRef(field->type, hdr,
                                                             field->name)));
        rv->push_back(new IR::Primitive(p->srcInfo, "set_metadata",
            new IR::FieldRef(IR::Type::Bits::get(1), hdr, "$valid"),
            new IR::Constant(1)));
    } else {
      // Just change emit(header_ref) to emit(header_slice_ref). The slice will
      // be the whole header.
      auto hsr = new IR::HeaderSliceRef(hdr->srcInfo, hdr,
                                        hdr->type->width_bits() - 1, 0);
      rv->push_back(new IR::Primitive(p->srcInfo, p->name, hsr));
    }
    return rv;
}
