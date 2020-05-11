#ifndef EXTENSIONS_BF_P4C_COMMON_IR_UTILS_H_
#define EXTENSIONS_BF_P4C_COMMON_IR_UTILS_H_

#include "ir/ir.h"

IR::Member *gen_fieldref(const IR::HeaderOrMetadata *hdr, cstring field);

const IR::HeaderOrMetadata*
getMetadataType(const IR::BFN::Pipe* pipe, cstring typeName);

bool isSigned(const IR::Type *);

// probably belongs in ir/ir.h or ir/node.h...
template <class T> inline T *clone_update(const T* &ptr) {
    T *rv = ptr->clone();
    ptr = rv;
    return rv; }

uint64_t bitMask(unsigned size);
big_int bigBitMask(int size);

#endif /* EXTENSIONS_BF_P4C_COMMON_IR_UTILS_H_ */
