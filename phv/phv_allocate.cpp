#include "phv_allocate.h"

void PhvAllocate::do_alloc(PhvInfo::Info *) {
    /* greedy allocate space for field */
}

bool PhvAllocate::preorder(const IR::Tofino::Pipe *) {
    for (auto &field : phv)
	if (field.alloc.empty())
	    do_alloc(&field);
    return false;
}

