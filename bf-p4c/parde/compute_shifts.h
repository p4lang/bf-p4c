#ifndef _TOFINO_PARDE_COMPUTE_SHIFTS_H_
#define _TOFINO_PARDE_COMPUTE_SHIFTS_H_

#include "parde_visitor.h"

class ComputeShifts : public PardeModifier {
    void postorder(IR::Tofino::ParserMatch* match) override {
        if (match->shift >= 0) return;  // We already computed the shift.

        unsigned bits = 0;
        forAllMatching<IR::Primitive>(&match->stmts, [&](const IR::Primitive* p) {
            if (p->name == "extract")
                bits += p->operands[0]->type->width_bits();
            return false;
        });

        // On Tofino we can't parse or deparse headers correctly if they aren't
        // byte-aligned. Practically speaking, that means that the extractions
        // in a ParserMatch must be byte-aligned as well; we're careful not to
        // violate this requirement in compiler-generated code, and user
        // generated code always extracts entire headers. If this is violated,
        // the resulting program is unlikely to work correctly, though we'll
        // round up and soldier on in the interest of producing some sort of
        // output.
        if (bits % 8 != 0)
            ::warning("Parser extractions are not byte-aligned in state %1%",
                      findContext<IR::Tofino::ParserState>());

        match->shift = (bits + 7) / 8U;
    }
};

#endif /* _TOFINO_PARDE_COMPUTE_SHIFTS_H_ */
