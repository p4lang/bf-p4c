#include "count_strided_header_refs.h"

#include "ir/ir.h"

bool CountStridedHeaderRefs::preorder(const IR::HeaderStackItemRef* hs) {
    auto stack = hs->base()->toString();
    auto index = hs->index()->to<IR::Constant>()->asUnsigned();
    header_stack_to_indices[stack].insert(index);
    return false;
}

