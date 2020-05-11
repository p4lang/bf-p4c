#include "bf-p4c/common/ir_utils.h"
#include "lib/exceptions.h"

IR::Member *gen_fieldref(const IR::HeaderOrMetadata *hdr, cstring field) {
    const IR::Type *ftype = nullptr;
    auto f = hdr->type->getField(field);
    if (f != nullptr)
        ftype = f->type;
    else
        BUG("Couldn't find intrinsic metadata field %s in %s", field, hdr->name);
    return new IR::Member(ftype, new IR::ConcreteHeaderRef(hdr), field);
}

const IR::HeaderOrMetadata*
getMetadataType(const IR::BFN::Pipe* pipe, cstring typeName) {
    auto* meta = pipe->metadata[typeName];
    BUG_CHECK(meta != nullptr,
              "Couldn't find required intrinsic metadata type: %1%", typeName);
    return meta;
}

bool isSigned(const IR::Type *t) {
    if (auto b = t->to<IR::Type::Bits>())
        return b->isSigned;
    return false;
}

uint64_t bitMask(unsigned size) {
    BUG_CHECK(size <= 64, "bitMask(%d), maximum size is 64", size);
    if (size == 64)
        return ~UINT64_C(0);
    return (UINT64_C(1) << size) - 1;
}

big_int bigBitMask(int size) {
    BUG_CHECK(size >= 0, "bigBitMask negative size");
    return (big_int(1) << size) - 1;
}
