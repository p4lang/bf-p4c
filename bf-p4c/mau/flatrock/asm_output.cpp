#include "bf-p4c/mau/asm_output.h"
#include "bf-p4c/mau/flatrock/input_xbar.h"

namespace Flatrock {

void IXBar::Use::gather_bytes(const PhvInfo &phv, std::map<int, std::map<int, Slice>> &sort,
                              const IR::MAU::Table *tbl) const {
    PHV::FieldUse f_use(PHV::FieldUse::READ);
    for (auto &b : use) {
        BUG_CHECK(b.loc.allocated(), "Byte not allocated by assembly");
        // exact grp 1 is by 32-bits words; the rest are 8 bit bytes
        int size = type == EXACT_MATCH && b.loc.group == 1 ? 32 : 8;
        for (auto &fi : b.field_bytes) {
            auto field = phv.field(fi.get_use_name());
            le_bitrange field_bits = { fi.lo, fi.hi };
            field->foreach_alloc(field_bits, tbl, &f_use, [&](const PHV::AllocSlice &sl) {
                Slice asm_sl(phv, fi.get_use_name(), sl.field_slice().lo, sl.field_slice().hi);
                auto n = sort[b.loc.group].emplace(b.loc.byte*size + asm_sl.align(size), asm_sl);
                BUG_CHECK(n.second, "duplicate byte use in ixbar");
            });
        }
    }

    // join together adjacent slices
    for (auto &group : sort) {
        auto it = group.second.begin();
        while (it != group.second.end()) {
            auto next = it;
            if (++next != group.second.end()) {
                Slice j = it->second.join(next->second);
                if (j && it->first + it->second.width() == next->first) {
                    it->second = j;
                    group.second.erase(next);
                    continue;
                }
            }
            it = next;
        }
    }
}

void IXBar::Use::emit_ixbar_asm(const PhvInfo &phv, std::ostream &out, indent_t indent,
                                const TableMatch *, const IR::MAU::Table *tbl) const {
    std::map<int, std::map<int, Slice>> sort;
    gather_bytes(phv, sort, tbl);
    cstring group_type;
    switch (type) {
    case EXACT_MATCH:   group_type = "exact";           break;
    case ATCAM_MATCH:   BUG("ATCAM not supported");
    case TERNARY_MATCH: group_type = "ternary";         break;
    case TRIE_MATCH:    group_type = "trie";            break;
    case GATEWAY:       group_type = "gateway";         break;
    case PROXY_HASH:    BUG("PROXY_HASH not supported");
    default:            group_type = "action";          break;
    }
    for (auto &group : sort)
        out << indent << group_type << " group " << group.first
            << ": " << group.second << std::endl;
}

}  // end namespace Flatrock
