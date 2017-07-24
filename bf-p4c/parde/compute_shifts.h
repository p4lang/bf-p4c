#ifndef _TOFINO_PARDE_COMPUTE_SHIFTS_H_
#define _TOFINO_PARDE_COMPUTE_SHIFTS_H_

#include "parde_visitor.h"

class ComputeShifts : public PardeModifier {
    void postorder(IR::Tofino::ParserMatch* match) override {
        if (match->shift >= 0) return;  // We already computed the shift.

        auto stateName = findContext<IR::Tofino::ParserState>()->name;

        nw_bitinterval bits;
        forAllMatching<IR::Tofino::ExtractBuffer>(&match->stmts,
                      [&](const IR::Tofino::ExtractBuffer* extract) {
            if (extract->isShiftedOut()) {
                ::warning("Ignoring offset of shifted-out extraction in "
                          "state %1%: %2%", stateName, extract);
                return false;
            }
            bits = bits.unionWith(extract->bitInterval());
            return false;
        });

        // XXX(seth): If the high bit of the interval isn't byte-aligned, it
        // *may* indicate an issue in the original source program (e.g., a
        // non-byte-aligned header). On the other hand, it may just indicate
        // that we dead code eliminated some of the fields that were extracted
        // here. Because we can't tell the difference at this layer, we can't
        // report an error. We really need to detect non-byte-aligned headers
        // earlier. For now, we just warn.
        if (!bits.isHiAligned())
            ::warning("Parser extractions are not byte-aligned in "
                      "state %1% match %2%", stateName, match);

        match->shift = bits.nextByte();

        LOG1("Computed shift " << match->shift << " for state " << stateName
              << " match " << match);
    }
};

#endif /* _TOFINO_PARDE_COMPUTE_SHIFTS_H_ */
