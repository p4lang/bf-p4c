#include "action_data_bus.h"
#include "bf-p4c/mau/asm_output.h"
#include "bf-p4c/mau/asm_hash_output.h"
#include "bf-p4c/mau/flatrock/asm_output.h"
#include "input_xbar.h"

namespace Flatrock {

int IXBar::Use::slot_size(int group) const {
    switch (type) {
    case TERNARY_MATCH:
    case GATEWAY:
        return 8;
    default:
        // exact and xcmp grp 1 is by 32-bits words; the rest are 8 bit bytes
        return group ? 32 : 8;
    }
}

void IXBar::Use::gather_bytes(const PhvInfo &phv, std::map<int, std::map<int, Slice>> &sort,
                              const IR::MAU::Table *tbl) const {
    PHV::FieldUse f_use(PHV::FieldUse::READ);
    for (auto &b : use) {
        BUG_CHECK(b.loc.allocated(), "Byte not allocated by assembly");
        unsigned size = slot_size(b.loc.group);
        unsigned bit = b.loc.byte * size;
        // PHEs smaller than the slot size are gathered into aligned groups to match the slot size
        if (b.container.size() < size) {
            unsigned gsize = size/b.container.size();  // number of PHEs grouped to fill the slot
            bit += (b.container.index() % gsize) * b.container.size(); }
        for (auto &fi : b.field_bytes) {
            auto field = phv.field(fi.get_use_name());
            CHECK_NULL(field);
            le_bitrange field_bits = { fi.lo, fi.hi };
            field->foreach_alloc(field_bits, tbl, &f_use, [&](const PHV::AllocSlice &sl) {
                Slice asm_sl(phv, fi.get_use_name(), sl.field_slice().lo, sl.field_slice().hi);
                auto n = sort[b.loc.group].emplace(bit + asm_sl.align(size), asm_sl);
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
                                const TableMatch *fmt, const IR::MAU::Table *tbl) const {
    std::map<int, std::map<int, Slice>> sort;
    cstring group_type;
    cstring (*index)(int i) = [](int)->cstring { return ""; };
    switch (type) {
    case EXACT_MATCH:
        group_type = "exact";
        index = [](int i)->cstring { return i ? " word" : " byte"; };
        break;
    case ATCAM_MATCH:
        BUG("ATCAM not supported");
    case TERNARY_MATCH:
        group_type = "ternary";
        index = [](int i)->cstring { return " " + std::to_string(i); };
        break;
    case TRIE_MATCH:
        // is just XCMP?  so this case should go away and use default: below
        BUG("TRIE_MATCH not supported");
        break;
    case GATEWAY:
        group_type = "gateway";
        break;
    case PROXY_HASH:
        BUG("PROXY_HASH not supported");
    default:
        group_type = "xcmp";
        index = [](int i)->cstring { return i ? " word" : " byte"; };
        break;
    }
    gather_bytes(phv, sort, tbl);
    for (auto &group : sort)
        out << indent << group_type << index(group.first) << ": " << group.second << std::endl;
    if (xme_units) {
        out << indent << "exact unit: [ " << emit_vector(bitvec(xme_units)) << " ]" << std::endl;
        int ident_bits_prev_alloc = 0;
        for (int mask = xme_units, xmu = 0; mask; ++xmu, mask >>= 2) {
            if ((mask & 3) == 0) continue;
            out << indent << "hash " << xmu << ":" << std::endl;
            safe_vector<Slice> match_data;
            safe_vector<Slice> ghost;
            emit_ixbar_hash_table(xmu, match_data, ghost, fmt, sort);
            emit_ixbar_hash_exact(out, indent+1, match_data, ghost, this, xmu,
                                  ident_bits_prev_alloc); } }
    if (output_unit >= 0)
        out << indent << "output unit: " << output_unit << std::endl;
}

bool ActionDataBus::Use::emit_adb_asm(std::ostream &out, const IR::MAU::Table *tbl,
                                      bitvec source) const {
    LOG1("Emitting action data bus asm for table " << tbl->name);
    auto &format = tbl->resources->action_format;
    auto &meter_use = tbl->resources->meter_format;

    bool first = true;
    for (auto &rs : action_data_locs) {
        if (!source.getbit(rs.source)) continue;
        auto source_is_immed = (rs.source == ActionData::IMMEDIATE);
        auto source_is_adt = (rs.source == ActionData::ACTION_DATA_TABLE);
        auto source_is_meter = (rs.source == ActionData::METER_ALU);
        BUG_CHECK(source_is_immed || source_is_adt || source_is_meter,
                  "bad action data source %1%", rs.source);
        if (source_is_meter &&
            !meter_use.contains_adb_slot(rs.location.type, rs.byte_offset)) continue;
        bitvec total_range(0, ActionData::slot_type_to_bits(rs.location.type));
        int byte_sz = ActionData::slot_type_to_bits(rs.location.type) / 8;

        int hi = 0;
        for (int lo = 0; (lo = rs.bytes_used.ffs(lo)) >= 0; lo = hi + 1) {
            hi = rs.bytes_used.ffz(lo) - 1;
            if (!first)
                out << ", ";
            first = false;
            out << rs.location.byte + lo;
            if (hi != lo)
                out << ".." << (rs.location.byte + hi);
            out << " : ";
            le_bitrange slot_bits(lo*8, hi*8+7);

            // FIXME -- most of the below should be folded into Format::Use::get_format_name,
            // but for now this is mostly a copy of the tofino code.

            // For emitting hash distribution sections on the action_bus directly.  Must find
            // which slices of hash distribution are to go to which bytes, requiring coordination
            // from the input xbar and action format allocation
            if (source_is_immed
                && format.is_byte_offset<ActionData::Hash>(rs.byte_offset)) {
                // FIXME -- this is probably all wrong for flatrock
                safe_vector<int> all_hash_dist_units = tbl->resources->hash_dist_immed_units();
                bitvec slot_hash_dist_units;
                le_bitrange immed_range = slot_bits.shiftedByBytes(rs.byte_offset);
                for (int i = 0; i < 2; i++) {
                    le_bitrange immed_impact = { i * IXBar::HASH_DIST_BITS,
                                                 (i + 1) * IXBar::HASH_DIST_BITS - 1 };
                    if (!immed_impact.overlaps(immed_range))
                        continue;
                    slot_hash_dist_units.setbit(i);
                }

                out << "hash_dist(";
                // Find the particular hash dist units (if 32 bit, still potentially only one if)
                // only certain bits are allocated
                std::string sep = "";
                for (auto bit : slot_hash_dist_units) {
                    if (all_hash_dist_units.at(bit) < 0) continue;
                    out << sep << all_hash_dist_units.at(bit);
                    sep = ", ";
                }

                // Byte slots need a particular byte range of hash dist
                if (rs.location.type == ActionData::BYTE) {
                    int slot_range_shift = (immed_range.lo / IXBar::HASH_DIST_BITS);
                    slot_range_shift *= IXBar::HASH_DIST_BITS;
                    le_bitrange slot_range = immed_range.shiftedByBits(-1 * slot_range_shift);
                    out << ", " << slot_range.lo << ".." << slot_range.hi;
                }
                // 16 bit hash dist in a 32 bit slot have to determine whether the hash distribution
                // unit goes in the lo section or the hi section
                if (slot_hash_dist_units.popcount() == 1) {
                    cstring lo_hi = slot_hash_dist_units.getbit(0) ? "lo" : "hi";
                    out << ", " << lo_hi;
                }
                out << ")";
            } else if (source_is_immed
                       && format.is_byte_offset<ActionData::RandomNumber>(rs.byte_offset)) {
                // FIXME -- this is probably all wrong for flatrock
                int rng_unit = tbl->resources->rng_unit();
                out << "rng(" << rng_unit << ", ";
                int lo = rs.byte_offset * 8;
                int hi = lo + byte_sz * 8 - 1;
                out << lo << ".." << hi << ")";
            } else if (source_is_immed
                       && format.is_byte_offset<ActionData::MeterColor>(rs.byte_offset)) {
                // FIXME -- this is probably all wrong for flatrock
                for (auto back_at : tbl->attached) {
                    auto at = back_at->attached;
                    auto *mtr = at->to<IR::MAU::Meter>();
                    if (mtr == nullptr) continue;
                    out << MauAsmOutput::find_attached_name(tbl, mtr) << " color";
                    break;
                }
            } else if (source_is_adt || source_is_immed) {
                // FIXME -- is this wrong for flatrock?
                out << format.get_format_name(rs.location.type, rs.source, rs.byte_offset);
            } else if (source_is_meter) {
                // FIXME -- this is probably all wrong for flatrock
                auto *at = tbl->get_attached<IR::MAU::MeterBus2Port>();
                BUG_CHECK(at != nullptr, "Trying to emit meter alu without meter alu user");
                cstring ret_name = MauAsmOutput::find_attached_name(tbl, at);
                out << ret_name;
                out << "(" << (rs.byte_offset * 8) << ".." << ((rs.byte_offset + byte_sz) * 8 - 1)
                    << ")";
            } else {
                BUG("unhandled case in emit_adb_asm");
            }
        }
    }
    return !first;
}

void PpuAsmOutput::emit_table_format(std::ostream &out, indent_t indent,
        const TableFormat::Use &use, const TableMatch *tm, bool ternary,
        bool no_match) const {
    MauAsmOutput::emit_table_format(out, indent, use, tm, ternary, no_match);
}

}  // end namespace Flatrock
