#ifndef TOFINO_PHV_TRIVIAL_ALLOC_H_
#define TOFINO_PHV_TRIVIAL_ALLOC_H_

#include "ir/ir.h"
#include "phv_fields.h"
#include "lib/symbitmatrix.h"

namespace PHV {

class TrivialAlloc : public Inspector {
 public:
    TrivialAlloc(PhvInfo &p, const SymBitMatrix &c) : phv(p), conflict(c) {}
    struct Regs;

 private:
    PhvInfo                     &phv;
    const SymBitMatrix          &conflict;
    class Uses;
    void do_alloc(PhvInfo::Field *, Regs *, Regs *, int = 0);
    bool preorder(const IR::Tofino::Pipe *p) override;
    void end_apply(const IR::Node *) override { phv.alloc_done_ = true; }
};

}  // namespace PHV


#endif /* TOFINO_PHV_TRIVIAL_ALLOC_H_ */
