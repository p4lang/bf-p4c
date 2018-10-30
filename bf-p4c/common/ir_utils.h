#ifndef EXTENSIONS_BF_P4C_COMMON_IR_UTILS_H_
#define EXTENSIONS_BF_P4C_COMMON_IR_UTILS_H_

#include "ir/ir.h"

IR::Member *gen_fieldref(const IR::HeaderOrMetadata *hdr, cstring field);

const IR::HeaderOrMetadata*
getMetadataType(const IR::BFN::Pipe* pipe, cstring typeName);

#endif /* EXTENSIONS_BF_P4C_COMMON_IR_UTILS_H_ */
