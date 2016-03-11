#ifndef _TOFINO_PARDE_COMPUTE_SHIFTS_H_
#define _TOFINO_PARDE_COMPUTE_SHIFTS_H_

#include "parde_visitor.h"

class ComputeShifts : public PardeModifier {
    struct CountExtracts : public Inspector {
        int &count;
        void postorder(const IR::Primitive *prim) override {
            if (prim->name == "extract")
                count += (prim->operands[0]->type->width_bits() + 7) / 8U; }
        explicit CountExtracts(int &c) : count(c) {}
    };
    void postorder(IR::Tofino::ParserMatch *match) override {
        if (findContext<IR::Tofino::ParserState>()->name[0] != '$') {
            match->shift = 0;
            match->stmts.apply(CountExtracts(match->shift)); } }
};

#endif /* _TOFINO_PARDE_COMPUTE_SHIFTS_H_ */
