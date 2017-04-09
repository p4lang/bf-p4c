#include "match_keys.h"

namespace {

class FindExtractOffset : public Inspector {
    const PhvInfo               &phv;
    const PhvInfo::Field        *field;
    int                         bit_offset, &out_offset;
    bool preorder(const IR::Primitive *prim) override {
        if (prim->name != "extract") return true;
        int size = prim->operands[0]->type->width_bits();
        if (phv.field(prim->operands[0]) == field)
            out_offset = bit_offset / 8U;
        bit_offset += size;
        return true; }

 public:
    FindExtractOffset(const PhvInfo &phv, const PhvInfo::Field *field, int *offset)
    : phv(phv), field(field), bit_offset(0), out_offset(*offset) {} };

}  // end of anon namespace


bool LoadMatchKeys::preorder(IR::Tofino::ParserState *st) {
    for (auto &sel : st->select)
        if (auto field = phv.field(sel)) {
            int offset = -1;
            for (auto match : st->match) {
                match->stmts.apply(FindExtractOffset(phv, field, &offset));
                if (offset >= 0)
                    break; }
            if (offset >= 0) {
                int size = (sel->type->width_bits() + 7) / 8U;
                sel = new IR::Constant(offset);
                if (size > 1)
                    sel = new IR::Range(sel, new IR::Constant(offset+size-1));
            } else {
                warning("%s not extracted in state %s", sel, st); } }
    return true;
}
