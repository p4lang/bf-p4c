#ifndef EXTENSIONS_BF_P4C_PARDE_PARDE_UTILS_H_
#define EXTENSIONS_BF_P4C_PARDE_PARDE_UTILS_H_

#include "bf-p4c/device.h"

struct SortExtracts {
    explicit SortExtracts(IR::BFN::ParserState* state) {
        std::stable_sort(state->statements.begin(), state->statements.end(),
            [&] (const IR::BFN::ParserPrimitive* a,
                 const IR::BFN::ParserPrimitive* b) {
                auto ea = a->to<IR::BFN::Extract>();
                auto eb = b->to<IR::BFN::Extract>();

                if (ea && eb) {
                    auto va = ea->source->to<IR::BFN::PacketRVal>();
                    auto vb = eb->source->to<IR::BFN::PacketRVal>();

                    return (va && vb) ? (va->range < vb->range) : !!va;
                }

                return !!ea;
            });

        if (LOGGING(5)) {
            std::clog << "sorted primitives in " << state->name << std::endl;
            for (auto p : state->statements)
                std::clog << p << std::endl;
        }
    }
};

struct GetMaxBufferPos : Inspector {
    int rv = -1;

    bool preorder(const IR::BFN::InputBufferRVal* rval) override {
        rv = std::max(rval->range.hi, rv);
        return false;
    }
};

struct GetMinBufferPos : Inspector {
    int rv = Device::pardeSpec().byteInputBufferSize() * 8;

    bool preorder(const IR::BFN::InputBufferRVal* rval) override {
        if (rval->range.hi < 0) return false;
        if (rval->range.lo < 0) BUG("rval straddles input buffer?");
        rv = std::min(rval->range.lo, rv);
        return false;
    }
};

struct Shift : Transform {
    int shift_amt = 0;  // in bits
    explicit Shift(int shft) : shift_amt(shft) {
        BUG_CHECK(shift_amt % 8 == 0, "shift amount not byte-aligned?");
    }
};

struct ShiftPacketRVal : Shift {
    bool negative_ok = false;
    explicit ShiftPacketRVal(int shft, bool neg_ok = false) :
        Shift(shft), negative_ok(neg_ok) { }

    IR::Node* preorder(IR::BFN::PacketRVal* rval) override {
        rval->range = rval->range.shiftedByBits(-shift_amt);
        if (!negative_ok)
            BUG_CHECK(rval->range.lo >= 0, "packet rval shifted to be negative?");
        return rval;
    }
};

#endif /* EXTENSIONS_BF_P4C_PARDE_PARDE_UTILS_H_ */
