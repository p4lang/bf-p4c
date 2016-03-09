#include "match_keys.h"

namespace {

class FindExtractOffset : public Inspector {
    const PhvInfo       &phv;
    const PhvInfo::Info *info;
    int                 offset, &out_offset;
    bool preorder(const IR::Primitive *prim) override {
        if (prim->name != "extract") return true;
        int size = (prim->operands[0]->type->width_bits() + 7) / 8U;
        if (phv.field(prim->operands[0]) == info)
            out_offset = offset;
        offset += size;
        return true; }

 public:
    FindExtractOffset(const PhvInfo &phv, const PhvInfo::Info *info, int *offset)
    : phv(phv), info(info), offset(0), out_offset(*offset) {} };

}  // end of anon namespace


bool LoadMatchKeys::preorder(IR::Tofino::ParserState *st) {
    for (auto &sel : st->select)
        if (auto info = phv.field(sel)) {
            int offset = -1;
            for (auto match : st->match) {
                match->stmts.apply(FindExtractOffset(phv, info, &offset));
                if (offset >= 0)
                    break; }
            if (offset >= 0) {
                int size = (sel->type->width_bits() + 7) / 8U;
                sel = new IR::Constant(offset);
                if (size > 1)
                    sel = new IR::Range(Util::SourceInfo(), sel, new IR::Constant(offset+size-1));
            } else {
                warning("%s not extracted in state %s", sel, st); } }
    return true;
}
