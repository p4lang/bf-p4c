#include "match_keys.h"

#include <boost/optional.hpp>

#include <algorithm>

#include "lib/cstring.h"
#include "tofino/ir/bitrange.h"

bool LoadMatchKeys::preorder(IR::Tofino::ParserState *st) {
    for (auto &sel : st->select) {
        auto field = phv.field(sel);
        if (!field) continue;

        boost::optional<nw_bitrange> selectorBitRange;
        forAllMatching<IR::Tofino::Extract>(st, [&](const IR::Tofino::Extract* e) {
            if (phv.field(e->dest) != field) return false;
            if (!e->is<IR::Tofino::ExtractBuffer>()) {
                ::warning("Match selector %s in state %s cannot be mapped to a "
                          "definite input buffer range from primitive: %3%",
                          sel, st, e);
                return false;
            }

            auto extractRange = e->to<IR::Tofino::ExtractBuffer>()->extractedBits();
            if (selectorBitRange && *selectorBitRange != extractRange) {
                ::warning("Match selector %s in state %s was already mapped to "
                          "input buffer range %3%, but it would be mapped to "
                          "offset %4% by primitive: %5%", sel, st,
                          cstring::to_cstring(*selectorBitRange),
                          cstring::to_cstring(extractRange), e);
                return false;
            }

            selectorBitRange = extractRange;
            return false;
        });

        if (!selectorBitRange) {
            ::warning("Match selector %s is not extracted in state %s; can't "
                      "map it to an input buffer range", sel, st);
            continue;
        }

        sel = new IR::Constant(selectorBitRange->loByte());
        if (selectorBitRange->loByte() != selectorBitRange->hiByte())
            sel = new IR::Range(sel, new IR::Constant(selectorBitRange->hiByte()));
    }

    return true;
}
