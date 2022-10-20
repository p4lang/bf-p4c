#include <boost/iostreams/detail/select.hpp>
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
    for (auto &group : sort) {
        if (type == GATEWAY && group.first == 1) {
            // don't output the config of the fixed part of the gateway ixbar
            continue; }
        out << indent << group_type << index(group.first) << ": " << group.second << std::endl; }
    if (xme_units) {
        out << indent << "exact unit: [ " << emit_vector(bitvec(xme_units)) << " ]" << std::endl;
        int ident_bits_prev_alloc = 0;
        for (int mask = xme_units, xmu = 0; mask; ++xmu, mask >>= 2) {
            if ((mask & 3) == 0) continue;
            out << indent << "hash " << xmu << ":" << std::endl;
            safe_vector<Slice> match_data;
            safe_vector<Slice> ghost;
            emit_ixbar_hash_table(0, match_data, ghost, fmt, sort);
            emit_ixbar_hash_exact(out, indent+1, match_data, ghost, this, xmu,
                                  ident_bits_prev_alloc); } }
    if (output_unit >= 0)
        out << indent << "output unit: " << output_unit << std::endl;
}

bool IXBar::Use::emit_gateway_asm(const MauAsmOutput &, std::ostream &out, indent_t indent,
                                  const IR::MAU::Table *) const {
    if (num_gw_rows <= 0) return false;
    out << indent << "row: " << first_gw_row << std::endl;
#if 0
    // FIXME -- we need this code if we want to use the gateway payload to specify the
    // action/indirect pointers/immediate data/next table instead of the inhibit index
    // We probably want that when there's only one thing the gateway does, as that allows
    // us to merge with a match table and share overhead format.
    // FIXME -- the decision on which to use (payload or inhibit_index) should probably be
    // stored in the layout somewhere.
    if (tbl->layout.gateway && (tbl->layout.gateway_match || tbl->layout.hash_action) &&
        tbl->resources->table_format.has_overhead()) {
        auto payload = FindPayloadCandidates::determine_payload(tbl, tbl->resources, &tbl->layout);
        out << indent << "payload: 0x" << hex(payload.getrange(0,64)) << std::endl;
        mauasm.emit_table_format(out, indent, tbl->resources->table_format, nullptr, false, true); }
#endif
    return true;
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

bool PpuAsmOutput::gateway_uses_inhibit_index(const IR::MAU::Table *tbl) const {
    // FIXME -- the decision on which to use (payload or inhibit_index) should probably be
    // stored in the layout somewhere.  For now we use inhibit_index when there are 2+
    // choices as the payload can only provide one.
    std::set<cstring> gw_tags;
    for (auto &gw : tbl->gateway_rows) {
        if (gw.second)
            gw_tags.insert(gw.second); }
    return gw_tags.size() > 1;
}

// FIXME -- Remove stuff no longer required for Flatrock
void PpuAsmOutput::emit_memory(std::ostream &out, indent_t indent, const Memories::Use &mem,
         const IR::MAU::Table::Layout *layout, const TableFormat::Use *format) const {
    safe_vector<int> row, bus, result_bus, word;
    std::map<int, safe_vector<int>> home_rows;
    safe_vector<int> stash_rows;
    safe_vector<int> stash_cols;
    safe_vector<int> stash_units;
    safe_vector<int> alu_rows;
    safe_vector<char> logical_bus;
    bool logical = mem.type >= Memories::Use::COUNTER;
    bool have_bus = false;
    bool have_mapcol = mem.is_twoport();
    bool have_col = false;
    bool have_word = mem.type == Memories::Use::ACTIONDATA;
    bool have_vpn = have_word;

    bool separate_bus = mem.separate_search_and_result_bus();
    // Also explicitly print out search bus and hash bus if the layout has no overhead
    if (layout != nullptr && format != nullptr) {
        if (!layout->no_match_rams()) {
            if (!format->has_overhead())
                separate_bus = true;
        }
    }

    for (auto &r : mem.row) {
        if (logical) {
            int logical_row = 2*r.row + (r.col[0] >= Memories::LEFT_SIDE_COLUMNS);
            row.push_back(logical_row);
            have_col = true;
            if (r.bus >= 0) {
                switch (r.bus) {
                    case 0 /*ACTION*/:
                        logical_bus.push_back('A');
                        break;
                    case 1 /*SYNTH*/:
                        logical_bus.push_back('S');
                        alu_rows.push_back(logical_row);
                        break;
                    case 2 /*OFLOW*/:
                        logical_bus.push_back('O');
                        break;
                    default:
                        logical_bus.push_back('X');
                        break;
                }
                have_bus = true;
                // Only provide VPN for the Counter/Meter and ActionData case until validated on
                // the other type of logical memory type.
                if (mem.type == Memories::Use::COUNTER || mem.type == Memories::Use::METER)
                    have_vpn = true;
            }
        } else {
            row.push_back(r.row);
            bus.push_back(r.bus);
            if (r.bus >= 0) have_bus = true;
            if (separate_bus)
                result_bus.push_back(r.result_bus);
            if (r.col.size() > 0) have_col = true;
        }
        if (have_word)
            word.push_back(r.word);
        if ((r.stash_unit >= 0) && (r.stash_col >= 0)) {
            stash_rows.push_back(r.row);
            stash_cols.push_back(r.stash_col);
            stash_units.push_back(r.stash_unit);
            LOG4("Adding stash on row: " << r.row << ", col: "
                    << r.stash_col << ", unit: " << r.stash_unit);
        }
    }
    if (row.size() > 1) {
        out << indent << "row: " << row << std::endl;
        if (have_bus) {
            if (separate_bus) {
                out << indent << "search_bus: " << bus << std::endl;
                out << indent << "result_bus: " << result_bus << std::endl;
            } else {
                if (logical)
                    out << indent << "logical_bus: " << logical_bus << std::endl;
                else
                    out << indent << "bus: " << bus << std::endl;
            }
        } else if (separate_bus) {
            out << indent << "result_bus: " << result_bus << std::endl;
        }
        if (have_word)
            out << indent << "word: " << word << std::endl;
        if (have_col) {
            out << indent << "column:" << std::endl;
            for (auto &r : mem.row)
                out << indent << "- " << memory_vector(r.col, mem.type, false) << std::endl;
        }
        if (have_mapcol) {
            out << indent << "maprams: " << std::endl;
            for (auto &r : mem.row)
                out << indent << "- " << memory_vector(r.mapcol, mem.type, true) << std::endl;
        }
        if (have_vpn) {
            out << indent << "vpns: " << std::endl;
            for (auto &r : mem.row) {
                out << indent << "- " << r.vpn << std::endl;
            }
        }
    } else if (row.size() == 1) {
        out << indent << "row: " << row[0] << std::endl;
        if (have_bus) {
            if (separate_bus) {
                out << indent << "search_bus: " << bus[0] << std::endl;
                out << indent << "result_bus: " << result_bus[0] << std::endl;
            } else {
                if (logical)
                    out << indent << "logical_bus: " << logical_bus[0] << std::endl;
                else
                    out << indent << "bus: " << bus[0] << std::endl;
            }
        } else if (separate_bus) {
            out << indent << "result_bus: " << result_bus[0] << std::endl;
        }
        if (have_col) {
            out << indent << "column: " << memory_vector(mem.row[0].col, mem.type, false)
            << std::endl;
        }
        if (have_mapcol) {
            out << indent << "maprams: " << memory_vector(mem.row[0].mapcol, mem.type, true)
                << std::endl;
        }
        if (have_vpn)
           out << indent << "vpns: " << mem.row[0].vpn << std::endl;
    }
    for (auto r : mem.home_row) {
        home_rows[r.second].push_back(r.first);
    }

    if (!mem.loc_to_gb.empty()) {
        out << indent << "tcam_id: " << mem.table_id << std::endl;
        std::map<int, std::set<int>> row_to_stages;
        for (auto loc : mem.loc_to_gb) {
            const Memories::Use::ScmLoc &scm_loc = loc.first;
            row_to_stages[scm_loc.row].insert(scm_loc.stage);
        }
        out << indent << "row: [ ";
        bool first_val = true;
        for (const auto &[key, value] : row_to_stages) {
            if (first_val)
                out << key;
            else
                out << ", " << key;

            first_val = false;
        }
        out << " ]" << std::endl;

        auto print_set = [&](const std::set<int> &s) {
            out << " [ ";
            bool first = true;
            for (int stage : s) {
                if (first)
                    out << stage;
                else
                    out << ", " << stage;

                first = false;
            }
            out << " ]";
        };

        out << indent << "stage: [ ";
        first_val = true;
        for (const auto &[key, value] : row_to_stages) {
            if (first_val) {
                print_set(value);
            } else {
                out << ", ";
                print_set(value);
            }

            first_val = false;
        }
        out << " ]" << std::endl;
    }

    // Home rows are now printed out as a vector of vectors, of each home row per word
    if (mem.type == Memories::Use::ACTIONDATA && !home_rows.empty()) {
        out << indent << "home_row:" << std::endl;
        int word_check = 0;
        for (auto home_row_kv : home_rows) {
            BUG_CHECK(word_check++ == home_row_kv.first, "Home row is not found with a row");
            auto home_row = home_row_kv.second;
            if (home_row.size() > 1)
                out << indent << "- " << home_row << std::endl;
            else
                out << indent << "- " << home_row[0] << std::endl;
        }
    } else if (!alu_rows.empty()) {
        if (alu_rows.size() > 1)
            out << indent << "home_row: " << alu_rows << std::endl;
        else
            out << indent << "home_row: " << alu_rows[0] << std::endl;
    }
    if (!mem.color_mapram.empty()) {
        out << indent++ << "color_maprams:" << std::endl;
        safe_vector<int> color_mapram_row, color_mapram_bus;
        for (auto &r : mem.color_mapram) {
            color_mapram_row.push_back(r.row);
            color_mapram_bus.push_back(r.bus);
        }
        if (color_mapram_row.size() > 1) {
            out << indent << "row: " << color_mapram_row << std::endl;
            out << indent << "bus: " << color_mapram_bus << std::endl;
            out << indent << "column:" << std::endl;
            for (auto &r : mem.color_mapram)
                out << indent << "- " << memory_vector(r.col, mem.type, true) << std::endl;
            out << indent << "vpns:" << std::endl;
            for (auto &r : mem.color_mapram)
                out << indent << "- " << r.vpn << std::endl;
        } else {
            out << indent << "row: " << color_mapram_row[0] << std::endl;
            out << indent << "bus: " << color_mapram_bus[0] << std::endl;
            out << indent << "column: " << memory_vector(mem.color_mapram[0].col, mem.type, true)
                << std::endl;
            out << indent << "vpns:" << mem.color_mapram[0].vpn << std::endl;
        }
        out << indent << "address: ";
        if (mem.cma == IR::MAU::ColorMapramAddress::IDLETIME)
            out << "idletime";
        else if (mem.cma == IR::MAU::ColorMapramAddress::STATS)
            out << "stats";
        else
            BUG("Color mapram has not been allocated an address");
        out << std::endl;
        indent--;
    }

    if (mem.type == Memories::Use::TERNARY && mem.tind_result_bus >= 0)
        out << indent << "indirect_bus: " << mem.tind_result_bus << std::endl;


    if ((mem.type == Memories::Use::EXACT) &&
            (stash_rows.size() > 0) && (stash_units.size() > 0)) {
        out << indent++ << "stash: " << std::endl;
        out << indent << "row: " << stash_rows << std::endl;
        out << indent << "col: " << stash_cols << std::endl;
        out << indent << "unit: " << stash_units << std::endl;
        indent--;
    }
}

}  // end namespace Flatrock
