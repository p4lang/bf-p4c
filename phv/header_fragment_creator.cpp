#include "header_fragment_creator.h"
#include "ir/ir.h"

const IR::Node*
HeaderFragmentCreator::preorder(IR::FieldRef *field_ref) {
    if (field_ref->base->type->is<IR::HeaderType>())
        return new IR::FragmentRef(*field_ref);
    return field_ref;
}
