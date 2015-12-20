#ifndef _phv_allocate_h_
#define _phv_allocate_h_

#include "ir/ir.h"
#include "phv_fields.h"
#include "lib/bitvec.h"

class PhvAllocate : public Inspector {
    PhvInfo                     &phv;
    const vector<bitvec>        &conflict;
    void do_alloc(PhvInfo::Info *);
    bool preorder(const IR::Tofino::Pipe *p) override;
public:
    PhvAllocate(PhvInfo &p, const vector<bitvec> &c) : phv(p), conflict(c) {}
};


#endif /* _phv_allocate_h_ */
