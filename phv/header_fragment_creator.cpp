#include "header_fragment_creator.h"
#include "ir/ir.h"

const IR::Expression *HeaderFragmentCreator::preorder(IR::Member *field_ref) {
    if (field_ref->member.name[0] != '$' &&
        !field_ref->type->is<IR::Type::Varbits>() &&
        field_ref->expr->type->is<IR::Type_StructLike>()) {
        return new IR::HeaderSliceRef(field_ref); }
    return field_ref;
}

/* FIXME -- should we have a general "slice fold" pass used both here and in SplitPhvUse? */
const IR::Expression *HeaderFragmentCreator::postorder(IR::Slice *sl) {
    if (auto *hsr = sl->e0->to<IR::HeaderSliceRef>()) {
        int lo = sl->getL() + hsr->getL();
        int hi = sl->getH() + hsr->getL();
        if (lo > hsr->getH())
            return new IR::Constant(0);
        if (hi > hsr->getH())
            hi = hsr->getH();
        return new IR::HeaderSliceRef(hsr->srcInfo, hsr->header_ref(), hi, lo); }
    return sl;
}
