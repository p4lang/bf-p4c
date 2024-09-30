#include "bf-p4c/common/ir_utils.h"
#include "lib/exceptions.h"

P4::IR::Member *gen_fieldref(const P4::IR::HeaderOrMetadata *hdr, cstring field) {
    const P4::IR::Type *ftype = nullptr;
    auto f = hdr->type->getField(field);
    if (f != nullptr)
        ftype = f->type;
    else
        BUG("Couldn't find intrinsic metadata field %s in %s", field, hdr->name);
    return new P4::IR::Member(ftype, new P4::IR::ConcreteHeaderRef(hdr), field);
}

const P4::IR::HeaderOrMetadata*
getMetadataType(const P4::IR::BFN::Pipe* pipe, cstring typeName) {
    if (pipe->metadata.count(typeName) == 0)
        return nullptr;
    return pipe->metadata[typeName];
}

bool isSigned(const P4::IR::Type *t) {
    if (auto b = t->to<P4::IR::Type::Bits>())
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
