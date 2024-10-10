#ifndef EXTENSIONS_BF_P4C_PARDE_COUNT_STRIDED_HEADER_REFS_H_
#define EXTENSIONS_BF_P4C_PARDE_COUNT_STRIDED_HEADER_REFS_H_

#include "ir/visitor.h"

using namespace P4;

struct CountStridedHeaderRefs : public Inspector {
    std::map<cstring, std::set<unsigned>> header_stack_to_indices;

    bool preorder(const IR::HeaderStackItemRef* hs);
};

#endif  /* EXTENSIONS_BF_P4C_PARDE_COUNT_STRIDED_HEADER_REFS_H_ */

