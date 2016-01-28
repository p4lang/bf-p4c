#ifndef _TOFINO_PARDE_COMPUTE_SHIFTS_H_
#define _TOFINO_PARDE_COMPUTE_SHIFTS_H_

#include "parde_visitor.h"

class ComputeShifts : public PardeModifier {
    int shift;
    void postorder(IR::Primitive *prim) {
        if (prim->name == "extract")
            shift += (prim->operands[0]->type->width_bits() + 7) / 8U; }
    bool preorder(IR::Tofino::ParserMatch *) { shift = 0; return true; }
    void postorder(IR::Tofino::ParserMatch *match) {
        if (findContext<IR::Tofino::ParserState>()->name[0] != '$')
            match->shift = shift; }
};

#endif /* _TOFINO_PARDE_COMPUTE_SHIFTS_H_ */
