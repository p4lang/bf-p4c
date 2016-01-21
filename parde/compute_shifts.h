#ifndef _TOFINO_PARDE_COMPUTE_SHIFTS_H_
#define _TOFINO_PARDE_COMPUTE_SHIFTS_H_

#include "parde_visitor.h"

class ComputeShifts : public PardeModifier {
    int shift = 0;
    void postorder(IR::Primitive *prim) {
        if (prim->name == "extract")
            shift += prim->operands[0]->type->width_bits() / 8U; }
    void postorder(IR::Tofino::ParserMatch *match) {
        match->shift = shift;
        shift = 0; }
};

#endif /* _TOFINO_PARDE_COMPUTE_SHIFTS_H_ */
