#ifndef EXTENSIONS_BF_P4C_PARDE_PARDE_UTILS_H_
#define EXTENSIONS_BF_P4C_PARDE_PARDE_UTILS_H_

#include "bf-p4c/device.h"


static const IR::BFN::PacketRVal* get_packet_range(const IR::BFN::ParserPrimitive* p) {
    if (auto e = p->to<IR::BFN::Extract>()) {
        if (auto range = e->source->to<IR::BFN::PacketRVal>()) {
            return range;
        } else {
            return nullptr;
        }
    } else if (auto c = p->to<IR::BFN::ChecksumResidualDeposit>()) {
        return c->header_end_byte;
    } else if (auto c = p->to<IR::BFN::ChecksumSubtract>()) {
        return c->source;
    } else if (auto c = p->to<IR::BFN::ChecksumAdd>()) {
        return c->source;
    }
    return nullptr;
}

struct SortExtracts {
    explicit SortExtracts(IR::BFN::ParserState* state) {
        std::stable_sort(state->statements.begin(), state->statements.end(),
            [&] (const IR::BFN::ParserPrimitive* a,
                 const IR::BFN::ParserPrimitive* b) {
                auto va = get_packet_range(a);
                auto vb = get_packet_range(b);
                return (va && vb) ? (va->range < vb->range) : !!va;
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
    std::set<const IR::BFN::ParserChecksumPrimitive*> toggle_swap;
    explicit ShiftPacketRVal(int shft, bool neg_ok = false) :
        Shift(shft), negative_ok(neg_ok) { }

    IR::Node* preorder(IR::BFN::PacketRVal* rval) override {
        auto csum = findContext<IR::BFN::ParserChecksumPrimitive>();
        auto new_range = rval->range.shiftedByBits(-shift_amt);
        // Check if the first byte retains its even - odd alignment. If not, the
        // toggle the swap
        if (csum && (csum->is<IR::BFN::ChecksumSubtract>() ||
                     csum->is<IR::BFN::ChecksumAdd>())) {
            if (rval->range.loByte() % 2 != new_range.loByte() % 2) {
                toggle_swap.insert(csum);
            }
        }
        if (!negative_ok)
            BUG_CHECK(new_range.lo >= 0, "packet rval shifted to be negative?");
        rval->range = new_range;
        return rval;
    }

    IR::Node* postorder(IR::BFN::ParserChecksumPrimitive* csum) {
        for (auto c : toggle_swap) {
            if (c->equiv(*csum)) {
                if (auto sub = csum->to<IR::BFN::ChecksumSubtract>()) {
                    return new IR::BFN::ChecksumSubtract(csum->declName,
                            sub->source, !sub->swap, sub->isPayloadChecksum);
                } else if (auto add = csum->to<IR::BFN::ChecksumAdd>()) {
                    return new IR::BFN::ChecksumAdd(csum->declName,
                    add->source, !add->swap, add->isHeaderChecksum);
                }
            }
        }
        return csum;
    }
};

inline unsigned get_state_shift(const IR::BFN::ParserState* state) {
    unsigned state_shift = 0;

    for (unsigned i = 0; i < state->transitions.size(); i++) {
        auto t = state->transitions[i];

        if (i == 0)
            state_shift = t->shift;
        else
            BUG_CHECK(state_shift == t->shift, "Inconsistent shifts in %1%", state->name);
    }

    return state_shift;
}

#endif /* EXTENSIONS_BF_P4C_PARDE_PARDE_UTILS_H_ */
