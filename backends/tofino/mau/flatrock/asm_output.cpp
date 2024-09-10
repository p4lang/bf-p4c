#include <boost/iostreams/detail/select.hpp>
#include "action_data_bus.h"
#include "backends/tofino/mau/asm_output.h"
#include "backends/tofino/mau/asm_hash_output.h"
#include "backends/tofino/mau/flatrock/asm_output.h"
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
                                const ::TableMatch *fmt, const IR::MAU::Table *tbl) const {
    typedef std::map<int, std::map<int, Slice>> SortMap;
    SortMap sort_all, sort_word, sort_byte;
    cstring group_type;
    cstring (*index)(int i) = [](int)->cstring { return ""; };
    switch (type) {
    case EXACT_MATCH:
        group_type = "exact";
        index = [](int i)->cstring { return i ? "word" : "byte"; };
        break;
    case ATCAM_MATCH:
        BUG("ATCAM not supported");
    case TERNARY_MATCH:
        group_type = "ternary";
        index = [](int i)->cstring { return std::to_string(i); };
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
        index = [](int i)->cstring { return i ? "word" : "byte"; };
        break;
    }
    gather_bytes(phv, sort_all, tbl);
    for (auto &group : sort_all) {
        if (type == GATEWAY && group.first == 1) {
            // don't output the config of the fixed part of the gateway ixbar
            continue; }
        out << indent << group_type << " " << index(group.first)
            << ": " << group.second << std::endl;
        // TODO: Current sorting for word / byte is simple. With xcmp there is 1 byte group and 3
        // word groups and this algorithm will need to be updated.
        if (group.first == 1)
            sort_word.insert(group);
        else
            sort_byte.insert(group);
    }

    if (xme_units) {
        out << indent << "exact unit: [ " << emit_vector(bitvec(xme_units)) << " ]" << std::endl;
        int ident_bits_prev_alloc = 0;

        auto emit_ixbar_hash_table_and_exact = [&](int &xmu, SortMap &s) {
            safe_vector<Slice> match_data;
            safe_vector<Slice> ghost;
            emit_ixbar_hash_table(-1, match_data, ghost, fmt, s);
            emit_ixbar_hash_exact(out, indent+1, match_data, ghost, this, xmu,
                                  ident_bits_prev_alloc);
        };

        for (int mask = xme_units, xmu = 0; mask; ++xmu, mask >>= 2) {
            if ((mask & 3) == 0) continue;
            // Word hash
            if (sort_word.size() > 0) {
                out << indent << "word hash:" << std::endl;
                emit_ixbar_hash_table_and_exact(xmu, sort_word);
            }

            // Byte hash
            if (sort_byte.size() > 0) {
                out << indent << "byte hash:" << std::endl;
                emit_ixbar_hash_table_and_exact(xmu, sort_byte);
            }
        }
    }

    if (tbl->layout.is_lamb && output_unit >= 0)
        out << indent << "output unit: " << output_unit << std::endl;
}

bool IXBar::Use::emit_gateway_asm(const MauAsmOutput &mauasm, std::ostream &out, indent_t indent,
                                  const IR::MAU::Table *tbl) const {
    if (num_gw_rows <= 0) return false;
    out << indent << "row: " << first_gw_row << std::endl;
    // FIXME -- we need this code if we want to use the gateway payload to specify the
    // action/indirect pointers/immediate data/next table instead of the inhibit index
    // We probably want that when there's only one thing the gateway does, as that allows
    // us to merge with a match table and share overhead format.  Alternately, we can use
    // the inhibit index to select one of up to 4 different possiblities for a map table,
    // but we can't use both in one table -- only one or the other statically per table.
    // FIXME -- the decision on which to use (payload or inhibit_index) should probably be
    // stored in the layout somewhere.
    if (((tbl->layout.gateway && tbl->layout.gateway_match) || tbl->layout.hash_action) &&
        tbl->resources->table_format.has_overhead()) {
        auto payload = FindPayloadCandidates::determine_payload(tbl, tbl->resources, &tbl->layout);
        out << indent << "payload: 0x" << hex(payload.getrange(0,64)) << std::endl;
        mauasm.emit_table_format(out, indent, tbl->resources->table_format, nullptr, false, true); }
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
                // FIXME -- this is DEFINITELY all wrong for flatrock
                BUG("need to implement adb/xcmp hash access for flatrock");
#if 0
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
#endif
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

/* Generate asm for the way information, such as the size, select mask, and specifically which
   RAMs belong to a specific way */
void PpuAsmOutput::emit_ways(std::ostream &out, indent_t indent, const ::IXBar::Use *use,
        const Memories::Use *mem) const {
    if (use == nullptr || use->way_use.empty()) return;
    out << indent++ << "ways:" << std::endl;

    auto ixbar_way = use->way_use.begin();

    if (auto *u = dynamic_cast<const Flatrock::IXBar::Use *>(use)) {
        unsigned xme_units = u->xme_units;
        int i = 0;
        for (; ixbar_way != use->way_use.end(); ++ixbar_way) {
            // XME
            int xme = ffs(xme_units) - 1;
            out << indent << "- { " << use->way_source_kind() << ": " << xme << ", "
                << "index: " << ixbar_way->index.lo << ".." << ixbar_way->index.hi;

            // Select
            if (ixbar_way->select_mask)
                out << ", select: " << ixbar_way->select.lo << ".." << ixbar_way->select.hi
                    << " & 0x" << hex(ixbar_way->select_mask);

            // RAMS
            if (u->has_lamb()) {
                out << ", rams: [[" << xme << "]] }" << std::endl;
            } else {
                auto mem_way = mem->ways[i];
                size_t index = 0;
                out << ", rams: [";
                for (auto stage_ram : mem_way.stage_rams) {
                    auto stage = stage_ram.first;
                    for (auto ram : stage_ram.second) {
                        out << "[" << stage << ", " << ram.first << ", " << ram.second << "]";
                        if (index < mem_way.rams.size() - 1)
                            out << ", ";
                        index++;
                    }
                }
                out  << "] }" << std::endl;
            }

            xme_units &= ~(1U << xme);
            i++;
        }
    }
}

void PpuAsmOutput::emit_table_format(std::ostream &out, indent_t indent,
        const TableFormat::Use &use, const ::TableMatch *tm, bool ternary,
        bool gateway) const {
    fmt_state fmt;
    out << indent << "format: {";
    int group = (ternary || gateway) ? -1 : 0;

    for (auto match_group : use.match_groups) {
        LOG5("For match group: " << match_group);
        int type;
        safe_vector<std::pair<int, int>> bits;
        // For table objects that are not match
        for (type = TableFormat::NEXT; type < TableFormat::ENTRY_TYPES; type++) {
            if (match_group.mask[type].popcount() == 0) continue;
            if (type == TableFormat::VERS && gateway) continue;  // no v/v in gw payload
            bits.clear();
            int start = match_group.mask[type].ffs();
            while (start >= 0) {
                int end = match_group.mask[type].ffz(start);
                if (end == -1)
                    end = match_group.mask[type].max().index();
                bits.emplace_back(start, end - 1);
                start = match_group.mask[type].ffs(end);
            }
            // Specifically, the immediate information may have to be broken up into mutliple
            // places
            if (type == TableFormat::IMMEDIATE) {
                for (size_t i = 0; i < bits.size(); i++) {
                    cstring name = format_name(type);
                    if (bits.size() > 1)
                        name = name + std::to_string(i);
                    fmt.emit(out, name, group, bits[i].first, bits[i].second - bits[i].first + 1);
                }
            } else {
                fmt.emit(out, format_name(type), group, bits);
            }
        }

        if (ternary || gateway) {
            if (group >= 0) {
                ++group;
                continue;
            } else {
                break; } }
        type = TableFormat::MATCH;

        bits.clear();

        // Generate a bitvec to output the relevant match bit slice(s) in the "match" output of
        // "format" in the assembly.
        //
        // E.g.
        // format: { action(0): 48..48, immediate(0): 41..47, valid(0): 40..40,
        //                                                    match(0): [ 0..31, 34..39  ]  }
        // Here match slices are aligned on bits 0..31 and bits 34..39
        //
        // The match match bits on word xbar come first followed by byte xbar. The same ordering
        // is followed for "match" output.
        //
        // match: [ hdrs.data.f1(0..7), hdrs.data.f1(8..15), hdrs.data.f1(16..23),
        //                                      hdrs.data.f1(24..31), hdrs.data.h1(10..15)  ]
        // Note, the hole at 32..33 is due to 2 bits being ghosted
        // from the field hdrs.data.h1(8..15)
        int start = -1; int end = -1;
        auto find_start_and_end_bits = [&](int word) {
            for (const auto &match_byte : match_group.match) {
                const auto &byte = match_byte.first;
                if (byte.loc.group != word) continue;
                const bitvec &byte_layout = match_byte.second;
                // Byte start and byte end are the bitvec positions for this specific byte
                BUG_CHECK(!byte_layout.empty(), "Match byte allocated has no match bits");
                int start_bit = byte_layout.ffs();
                do {
                    int end_bit = byte_layout.ffz(start_bit);
                    if (start == -1) {
                        start = start_bit;
                        end = end_bit - 1;
                    } else if (end == start_bit - 1) {
                        end = end_bit - 1;
                    } else {
                        bits.emplace_back(start, end);
                        LOG6("Adding match bits slice at (" << start << ", " << end << ")");
                        start = start_bit;
                        end = end_bit - 1;
                    }
                    start_bit = byte_layout.ffs(end_bit);
                } while (start_bit != -1);
            }
        };

        find_start_and_end_bits(1);
        find_start_and_end_bits(0);
        bits.emplace_back(start, end);
        LOG6("Adding match bits slice at (" << start << ", " << end << ")");

        fmt.emit(out, format_name(type), group, bits);
        group++;
    }

    out << (fmt.sep + 1) << "}" << std::endl;
    if (ternary || gateway)
        return;

    if (tm->proxy_hash) {
        out << indent << "match: [ ";
        std::string sep = "";
        for (auto slice : tm->proxy_hash_fields) {
            out << sep << slice;
            sep = ", ";
        }
        out << " ]" << std::endl;
        out << indent << "proxy_hash_group: " << use.proxy_hash_group << std::endl;
    }

    // Outputs the match portion
    bool first = true;
    for (auto field : tm->match_fields) {
        if (!field) continue;
        if (first) {
            out << indent << "match: [ ";
            first = false;
        } else {
            out << ", "; }
        out << field; }
    if (!first) out << " ]" << std::endl;
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
    safe_vector<int> alu_rows;
    safe_vector<char> logical_bus;
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
        row.push_back(r.row);
        bus.push_back(r.bus);
        if (r.bus >= 0) have_bus = true;
        if (separate_bus)
            result_bus.push_back(r.result_bus);
        if (r.col.size() > 0) have_col = true;
        if (have_word) word.push_back(r.word);
    }
    if (row.size() > 1) {
        out << indent << "row: " << row << std::endl;
        if (have_bus) {
            if (separate_bus) {
                out << indent << "search_bus: " << bus << std::endl;
                out << indent << "result_bus: " << result_bus << std::endl;
            } else {
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
}

void TableMatch::populate_match_fields() {
    Log::TempIndent indent;
    LOG5("Populating match fields" << indent);
    // Determine which fields are part of a table match.  If a field partially ghosted,
    // then this information is contained within the bitvec and the int of the match_info
    auto *ixbar_use = table->resources->match_ixbar.get();
    if (!ixbar_use) return;

    // Sort by match fields by the order oc the byte layout
    std::map<bitvec, IXBar::Use::Byte> match_info_sorted;
    auto match_info = table->resources->table_format.match_groups[0].match;
    for (auto &m : match_info) match_info_sorted.insert({m.second, m.first});

    // Populate slice for each byte into match_fields which will be output to assembly
    for (auto &m : match_info_sorted) {
        const IXBar::Use::Byte &byte = m.second;
        const bitvec &byte_layout = m.first;
        LOG6("For match info : " << byte << ": " << byte_layout);

        for (auto &fi : byte.field_bytes) {
            LOG7("\tFor field byte : " << fi);
            bitvec total_cont_loc = fi.cont_loc();
            int first_cont_bit = total_cont_loc.min().index();
            bitvec layout_shifted
                = byte_layout.getslice(byte_layout.min().index() / 8 * 8, 8);

            auto fieldName = fi.get_use_name();
            auto field = phv.field(fieldName);
            le_bitrange field_bits = { fi.lo, fi.hi };
            int bits_seen = 0;
            PHV::FieldUse use(PHV::FieldUse::READ);
            // It is not a guarantee, especially in Tofino2 due to live ranges being different that
            // a FieldInfo is not corresponding to a single alloc_slice object. Its not clear yet
            // that this will also apply for Flatrock.
            field->foreach_alloc(field_bits, table, &use, [&](const PHV::AllocSlice &sl) {
                int lo = sl.field_slice().lo;
                int hi = sl.field_slice().hi;
                bitvec cont_loc = total_cont_loc & bitvec(bits_seen + first_cont_bit, sl.width());
                bitvec matched_bits = layout_shifted & cont_loc;
                bits_seen += sl.width();
                LOG8("\t\tField Slice: " << sl << ", total_cont_loc: " << total_cont_loc
                        << ", bits_seen: " << bits_seen
                        << ", first_cont_bit: " << first_cont_bit
                        << ", layout_shifted: " << layout_shifted
                        << ", cont_loc: " << cont_loc
                        << ", matched_bits: " << matched_bits);
                // If a byte is partially ghosted, then currently the bits from the lsb are
                // ghosted so the algorithm always shrinks from the bottom
                if (matched_bits.empty()) {
                    return;
                } else if (matched_bits != cont_loc) {
                    lo += (matched_bits.min().index() - cont_loc.min().index());
                }
                Slice asm_sl(phv, fieldName, lo, hi);
                if (asm_sl.bytealign() != (matched_bits.min().index() % 8))
                    BUG("Byte alignment for matching does not match up properly");
                match_fields.push_back(asm_sl);
                LOG7("\t\tAdding single byte match field: " << asm_sl);
            });
        }
    }

    LOG7("\tMatch fields : " << match_fields);
}

TableMatch::TableMatch(const PhvInfo &phv, const IR::MAU::Table *tbl) : ::TableMatch(phv) {
    table = tbl;

    Log::TempIndent indent;
    LOG5("Create TableMatch for table " << table->name << indent);

    if (tbl->resources->table_format.match_groups.size() == 0)
        return;

    populate_match_fields();
    populate_ghost_bits();
}

}  // end namespace Flatrock
