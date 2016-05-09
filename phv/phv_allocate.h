#ifndef _TOFINO_PHV_PHV_ALLOCATE_H_
#define _TOFINO_PHV_PHV_ALLOCATE_H_

#include "ir/ir.h"
#include "phv_fields.h"
#include "lib/bitvec.h"

class PhvAllocate : public Inspector {
    PhvInfo                     &phv;
    const vector<bitvec>        &conflict;
    struct Regs;
    class Uses;
    void do_alloc(PhvInfo::Info *, Regs *);
    bool preorder(const IR::Tofino::Pipe *p) override;

 public:
    PhvAllocate(PhvInfo &p, const vector<bitvec> &c) : phv(p), conflict(c) {}
};


#endif /* _TOFINO_PHV_PHV_ALLOCATE_H_ */
