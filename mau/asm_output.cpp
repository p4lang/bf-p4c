#include "asm_output.h"
#include "gateway.h"
#include "lib/algorithm.h"
#include "lib/bitops.h"
#include "lib/bitrange.h"
#include "lib/hex.h"
#include "lib/indent.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "tofino/phv/asm_output.h"
#include "resource.h"

class MauAsmOutput::EmitAttached : public Inspector {
    friend class MauAsmOutput;
    const MauAsmOutput          &self;
    std::ostream                &out;
    const IR::MAU::Table        *tbl;
    bool preorder(const IR::Counter *) override;
    bool preorder(const IR::Meter *) override;
    bool preorder(const IR::ActionProfile *) override;
    bool preorder(const IR::ActionSelector *) override;
    bool preorder(const IR::MAU::TernaryIndirect *) override;
    bool preorder(const IR::MAU::ActionData *) override;
    bool preorder(const IR::MAU::StatefulAlu *) override;
    bool preorder(const IR::Attached *att) override {
        BUG("unknown attached table type %s", typeid(*att).name()); }
    EmitAttached(const MauAsmOutput &s, std::ostream &o, const IR::MAU::Table *t)
    : self(s), out(o), tbl(t) {}};

std::ostream &operator<<(std::ostream &out, const MauAsmOutput &mauasm) {
    for (auto &stage : mauasm.by_stage) {
        out << "stage " << stage.first.second << ' ' << stage.first.first << ':' << std::endl;
        for (auto tbl : stage.second)
            mauasm.emit_table(out, tbl); }
    return out;
}

class MauAsmOutput::TableMatch {
 public:
    vector<Slice>       match_fields;
    vector<Slice>       ghost_bits;

    TableMatch(const MauAsmOutput &s, const PhvInfo &phv, const IR::MAU::Table *tbl);
};

/* Function that emits the immediate information based on the immediate_format object
   contained within the table resources object.  This function must also coordinate with
   all of the potential holes within the immediate format, as they might contain other
   data that is not action data */
void MauAsmOutput::emit_immediate_format(std::ostream &out, indent_t indent,
        const IR::MAU::Table *tbl, const IR::MAU::Action *af) const {
    auto &placement = tbl->resources->action_format.immediate_format.at(af->name);
    out << indent << "- { ";
    auto &immediate_mask = tbl->resources->action_format.immediate_mask;

    bool need_indices = false;
    if (immediate_mask.max() != immediate_mask.end()
        && immediate_mask.ffz() < static_cast<size_t>(immediate_mask.max().index()))
        need_indices = true;

    size_t immediate_count = 0;
    int immediate_location = 0;
    bool immediate_to_end = true;
    int container_spot = 0;
    bool started = false;
    size_t index = 0;
    for (auto &container : placement) {
        bitvec total_arg(0);
        for (auto &arg_loc : container.arg_locs) {
            total_arg |= arg_loc.data_loc;
        }

        if ((!started && total_arg.ffs() != 0) || !immediate_to_end
            || container_spot != container.start) {
            immediate_count++;
            immediate_location = 0;
        }
        started = true;

        int start = 0;
        bool all_spaces_handled = false;

        // If a container has a hole, the output of the function must be able to handle that
        do {
            int end = total_arg.ffz(start);
            if (end == container.size) {
                all_spaces_handled = true;
            }
            out << container.asm_name << ": ";
            cstring immed_name = "immediate";
            if (need_indices)
                immed_name = immed_name + std::to_string(immediate_count);
            out << immed_name;

            int immediate_back = immediate_location + end - start - 1;
            out << "(" << immediate_location << ".." << immediate_back << ")";

            if (!all_spaces_handled) {
                start = total_arg.ffs(end);
                if (start == -1) {
                    immediate_to_end = false;
                    all_spaces_handled = true;
                } else {
                    immediate_count++;
                    immediate_location = 0;
                }
            } else {
                immediate_location = immediate_back + 1;
                immediate_to_end = end == container.size;
            }

            if (all_spaces_handled && index + 1 != placement.size())
                out << ", ";
            else
                out << " ";
        } while (!all_spaces_handled);
        index++;
        container_spot = container.start + container.size / 8;
    }
    out << " }" << std::endl;
}

// Simply emits the action data format of the action data table or action profile
void MauAsmOutput::emit_action_data_format(std::ostream &out, indent_t indent,
        const IR::MAU::Table *tbl, const IR::MAU::Action *af) const {
    auto &placement = tbl->resources->action_format.action_data_format.at(af->name);
    if (placement.size() == 0)
        return;
    out << indent << "format " << canon_name(af->name) << ": { ";
    size_t index = 0;
    for (auto &container : placement) {
        out << container.asm_name;
        out << ": " << container.start << ".."
            << (container.start + container.size - 1);
        if (index + 1 != placement.size())
            out << ", ";
        index++;
    }
    out << " }" << std::endl;
}


struct FormatHash {
    vector<Slice> match_data;
    vector<Slice> ghost;
    const IXBar::Use::algorithm_t alg;
    FormatHash(vector<Slice> md, vector<Slice> g, IXBar::Use::algorithm_t a)
        : match_data(md), ghost(g), alg(a) {}
};

// FIXME: This is a simple function for crc polynomial.  Probably needs to be expanded for
// actual use of the assembly
static cstring inline crc_poly(int number) {
    if (number == 16)
        return "0x8fdb";
    else  // if (number == "32")
        return "0xe89061db";
}

std::ostream &operator<<(std::ostream &out, const FormatHash &hash) {
    if (hash.alg == IXBar::Use::ExactMatch) {
        if (!hash.match_data.empty()) {
            out << "random(" << emit_vector(hash.match_data, ", ") << ")";
            if (!hash.ghost.empty()) out << " ^ ";
        }
        if (!hash.ghost.empty()) {
            out << "stripe(" << emit_vector(hash.ghost, ", ") << ")";
        }
    } else if (hash.alg == IXBar::Use::Random) {
        out << "random(" << emit_vector(hash.match_data, ", ") << ")";
    } else if (hash.alg == IXBar::Use::CRC16) {
        out << "stripe(crc(" << crc_poly(16) << ", " << emit_vector(hash.match_data, ", ") << "))";
    } else if (hash.alg == IXBar::Use::CRC32) {
        out << "stripe(crc(" << crc_poly(16) << ", " << emit_vector(hash.match_data, ", ") << "))";
    } else if (hash.alg == IXBar::Use::Identity) {
        out << hash.match_data[0];
    } else {
        BUG("Hashing Algorithm is not recognized");
    }
    return out;
}

/* Calculate the hash tables used by an individual P4 table in the IXBar */
void MauAsmOutput::emit_ixbar_gather_bytes(const vector<IXBar::Use::Byte> &use,
        map<int, map<int, Slice>> &sort) const {
    for (auto &b : use) {
        Slice sl(phv, b.field, b.lo, b.hi);
        auto n = sort[b.loc.group].emplace(b.loc.byte*8 + sl.bytealign(), sl);
        assert(n.second);
    }
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

/* Generate asm for the way information, such as the size, select mask, and specifically which
   RAMs belong to a specific way */
void MauAsmOutput::emit_ixbar_ways(std::ostream &out, indent_t indent,
        const IXBar::Use &use, const Memories::Use *mem, bool is_sel) const {
    if (!use.way_use.empty() && !is_sel) {
        out << indent << "ways:" << std::endl;
        auto memway = mem->ways.begin();
        for (auto way : use.way_use) {
            out << indent << "- [" << way.group << ", " << way.slice;
            out << ", 0x" << hex(memway->select_mask) << ", ";
            size_t index = 0;
            for (auto ram : memway->rams) {
                out << "[" << ram.first << ", " << (ram.second + 2) << "]";
                if (index < memway->rams.size() - 1)
                    out << ", ";
                index++;
            }
            out  << "]" << std::endl;
            ++memway;
        }
    }
}

/* Generate asm for the hash distribution unit, specifically the unit, group, mask and shift value
   found in each hash dist assembly */
void MauAsmOutput::emit_ixbar_hash_dist(std::ostream &out, indent_t indent,
        const IXBar::Use &use/*, const IR::MAU::Table *tbl*/) const {
    if (use.hash_dist_use.empty())
        return;
    out << indent++ << "hash_dist:" << std::endl;
    for (auto &hash_dist : use.hash_dist_use) {
        int bits_output = 0;  int first_slice = -1;
        for (int i = 0; i < IXBar::HASH_DIST_GROUPS; i++) {
            if (((1 << i) & hash_dist.slice) == 0) continue;
            if (bits_output >= hash_dist.max_size) continue;
            if (first_slice == -1)
                first_slice = i;
            int unit = IXBar::HASH_DIST_GROUPS * hash_dist.unit + i;
            out << indent << unit << ": {";
            out << "hash: " << hash_dist.group;
            unsigned long max_size_mask = (1 << (hash_dist.max_size)) - 1;
            max_size_mask <<= first_slice * IXBar::HASH_DIST_BITS;
            unsigned long potential_mask = (1 << IXBar::HASH_DIST_BITS) - 1;
            potential_mask <<= i * IXBar::HASH_DIST_BITS;
            unsigned long mask = (hash_dist.bit_mask & potential_mask & max_size_mask);
            mask >>= (IXBar::HASH_DIST_BITS * i);
            bits_output += __builtin_popcount(mask);
            out << ", mask: 0x" << hex(mask);
            out << ", shift: " << hash_dist.shift;
            out << "}" << std::endl;
        }
    }
    indent--;
}

/* Determine which bytes of a table's input xbar belong to an individual hash table,
   so that we can output the hash of this individual table. */
void MauAsmOutput::emit_ixbar_hash_table(int hash_table, vector<Slice> &match_data,
        vector<Slice> &ghost, const TableMatch *fmt, map<int, map<int, Slice>> &sort) const {
    unsigned half = hash_table & 1;
    for (auto &match : sort.at(hash_table/2)) {
        Slice reg = match.second;
        if (match.first/64U != half) {
            if ((match.first + reg.width() - 1)/64U != half)
                continue;
            assert(half);
            reg = reg(64 - match.first, 64);
        } else if ((match.first + reg.width() - 1)/64U != half) {
            assert(!half);
            reg = reg(0, 63 - match.first); }
        if (!reg) continue;
        if (fmt != nullptr) {
            vector<Slice> reg_ghost;
            vector<Slice> reg_hash = reg.split(fmt->ghost_bits, reg_ghost);
            ghost.insert(ghost.end(), reg_ghost.begin(), reg_ghost.end());
            match_data.insert(match_data.end(), reg_hash.begin(), reg_hash.end());
        } else {
            match_data.emplace_back(reg);
        }
    }
}

/* Generate asm for the hash of a table, specifically either a match, gateway, or selector
   table.  Not used for hash distribution hash */
void MauAsmOutput::emit_ixbar_hash(std::ostream &out, indent_t indent, vector<Slice> &match_data,
        vector<Slice> &ghost, const IXBar::Use &use, int hash_group,
        const IR::ActionSelector *as) const {
    unsigned done = 0; unsigned mask_bits = 0;
    if (as != nullptr) {
        if (as->mode == "fair")
            out << indent << "0..13: "
                << FormatHash(match_data, ghost, use.select_use.back().alg) << std::endl;
        else
            out << indent << "0..50: "
                << FormatHash(match_data, ghost, use.select_use.back().alg) << std::endl;
    }
    for (auto &way : use.way_use) {
        mask_bits |= way.mask;
        if (done & (1 << way.slice)) continue;
        done |= 1 << way.slice;
        out << indent << (way.slice*10) << ".." << (way.slice*10 + 9) << ": "
            << FormatHash(match_data, ghost, IXBar::Use::ExactMatch) << std::endl;
    }
    for (auto range : bitranges(mask_bits)) {
        out << indent << (range.first+40);
        if (range.second != range.first) out << ".." << (range.second+40);
        out << ": " << FormatHash(match_data, ghost, IXBar::Use::ExactMatch) << std::endl;
    }
    for (auto ident : use.bit_use) {
        out << indent << (40 + ident.bit);
        if (ident.width > 1)
            out << ".." << (39 + ident.bit + ident.width);
        out << ": " << Slice(phv, ident.field, ident.lo, ident.lo + ident.width - 1)
            << std:: endl;
        assert(hash_group == -1 || hash_group == ident.group);
    }
}

/* Generate Assembly for an individual hash distribution P4 requirement, specifically the
   hash tables and hash bits required on the hash input xbar */
void MauAsmOutput::emit_ixbar_hash_dist_hash(std::ostream &out, indent_t indent,
        vector<Slice> &match_data, vector<Slice> &ghost,
        const IXBar::Use::HashDist &hash_dist) const {
    for (int i = 0; i < IXBar::HASH_DIST_GROUPS; i++) {
        if (((1 << i) & hash_dist.slice) == 0) continue;
        int first_bit = i * IXBar::HASH_DIST_BITS;
        int last_bit = -1;
        bool last_bit_found = false;
        for (int j = i * IXBar::HASH_DIST_BITS; j < (i + 1) * IXBar::HASH_DIST_BITS; j++) {
            if (((1ULL << j) & hash_dist.bit_mask) == 0 && !last_bit_found) {
                last_bit_found = true;
                last_bit = j - 1;
            }
            if (((1ULL << j) & hash_dist.bit_mask) != 0 && last_bit_found) {
                BUG("Split in address bits for hash distribution");
            }
        }
        if (last_bit == -1)
            last_bit = (i + 1) * IXBar::HASH_DIST_BITS - 1;
        out << indent << first_bit << ".." << last_bit;
        out << ": " << FormatHash(match_data, ghost, hash_dist.alg) << std::endl;
    }
}

/* Emit the ixbar use for a particular type of table */
void MauAsmOutput::emit_ixbar(std::ostream &out, indent_t indent,
        const IXBar::Use &use, const Memories::Use *mem, const TableMatch *fmt,
        bool /*hash_action*/, bool is_sel /*= false*/,
        const IR::ActionSelector *as /*= nullptr */) const {
    map<int, map<int, Slice>> sort;
    map<int, map<int, Slice>> total_sort;
    emit_ixbar_ways(out, indent, use, mem, is_sel);
    emit_ixbar_hash_dist(out, indent, use);
    emit_ixbar_gather_bytes(use.use, sort);
    if (use.use.empty() && use.hash_dist_use.empty()) {
        return;
    }
    out << indent++ << "input_xbar:" << std::endl;
    for (auto &group : sort)
        out << indent << "group " << group.first << ": " << group.second << std::endl;
    // Hash groups are now broguht out of the IXBar Use, rather than recalculated in asm_output
    int hash_group = 0;
    for (auto hash_table_input : use.hash_table_inputs) {
        if (hash_table_input) {
            for (int ht : bitvec(hash_table_input)) {
                out << indent++ << "hash " << ht << ":" << std::endl;
                vector<Slice> match_data;
                vector<Slice> ghost;
                emit_ixbar_hash_table(ht, match_data, ghost, fmt, sort);
                // FIXME: This is obviously an issue for larger selector tables,
                //  whole function needs to be replaced
                emit_ixbar_hash(out, indent, match_data, ghost, use, hash_group, as);
                --indent;
            }
            out << indent++ << "hash group " << hash_group << ":" << std::endl;
            out << indent << "table: [" << emit_vector(bitvec(hash_table_input), ", ") << "]"
                << std::endl;
            --indent;
        }
        hash_group++;
    }
    for (auto hash_dist : use.hash_dist_use) {
        sort.clear();
        emit_ixbar_gather_bytes(hash_dist.use, sort);
        for (auto &group : sort)
            out << indent << "exact group " << group.first << ": " << group.second << std::endl;
        for (int ht : bitvec(hash_dist.hash_table_input)) {
            out << indent++ << "hash " << ht << ":" << std::endl;
            vector<Slice> match_data;
            vector<Slice> ghost;
            emit_ixbar_hash_table(ht, match_data, ghost, nullptr, sort);
            emit_ixbar_hash_dist_hash(out, indent, match_data, ghost, hash_dist);
            --indent;
        }
        out << indent++ << "hash group " << hash_dist.group << ":" << std::endl;
        out << indent  << "table: [" << emit_vector(bitvec(hash_dist.hash_table_input), ", ")
            << "]" << std::endl;
        --indent;
    }
}

class memory_vector {
    const vector<int>           &vec;
    Memories::Use::type_t       type;
    bool                        is_mapcol;
    friend std::ostream &operator<<(std::ostream &, const memory_vector &);
 public:
    memory_vector(const vector<int> &v, Memories::Use::type_t t, bool ism) : vec(v), type(t),
                                                                             is_mapcol(ism) {}
};

std::ostream &operator<<(std::ostream &out, const memory_vector &v) {
    if (v.vec.size() != 1) out << "[ ";
    const char *sep = "";
    int col_adjust = (v.type == Memories::Use::TERNARY || v.is_mapcol)  ? 0 : 2;
    bool logical = v.type >= Memories::Use::TWOPORT;
    int col_mod = logical ? 6 : 12;
    for (auto c : v.vec) {
        out << sep << (c + col_adjust) % col_mod;
        sep = ", "; }
    if (v.vec.size() != 1) out << " ]";
    return out;
}

void MauAsmOutput::emit_memory(std::ostream &out, indent_t indent, const Memories::Use &mem) const {
    vector<int> row, bus, home_row;
    bool logical = mem.type >= Memories::Use::TWOPORT;
    bool have_bus = !logical;
    for (auto &r : mem.row) {
        if (logical) {
            row.push_back(2*r.row + (r.col[0] >= Memories::LEFT_SIDE_COLUMNS));
        } else {
            row.push_back(r.row);
            bus.push_back(r.bus);
            if (r.bus < 0) have_bus = false; } }
    if (row.size() > 1) {
        out << indent << "row: " << row << std::endl;
        if (have_bus) out << indent << "bus: " << bus << std::endl;
        out << indent << "column:" << std::endl;
        for (auto &r : mem.row)
            out << indent << "- " << memory_vector(r.col, mem.type, false) << std::endl;
        if (mem.type == Memories::Use::TWOPORT) {
            out << indent << "maprams: " << std::endl;
            for (auto &r : mem.row)
                out << indent << "- " << memory_vector(r.mapcol, mem.type, true) << std::endl;
        }
    } else {
        out << indent << "row: " << row[0] << std::endl;
        if (have_bus) out << indent << "bus: " << bus[0] << std::endl;
        out << indent << "column: " << memory_vector(mem.row[0].col, mem.type, false) << std::endl;
        if (mem.type == Memories::Use::TWOPORT) {
            out << indent << "maprams: " << memory_vector(mem.row[0].mapcol, mem.type, true)
                << std::endl;
        }
    }

    for (auto r : mem.home_row) {
        home_row.push_back(r.first);
    }
    if (!home_row.empty()) {
        if (home_row.size() > 1)
            out << indent << "home_row: " << home_row << std::endl;
        else
            out << indent << "home_row: " << home_row[0] << std::endl;
    }
    if (!mem.color_mapram.empty()) {
        out << indent++ << "color_maprams:" << std::endl;
        vector<int> color_mapram_row, color_mapram_bus;
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
        } else {
            out << indent << "row: " << color_mapram_row[0] << std::endl;
            out << indent << "bus: " << color_mapram_bus[0] << std::endl;
            out << indent << "column: " << memory_vector(mem.color_mapram[0].col, mem.type, true)
                << std::endl;
        }
        indent--;
    }
}

struct fmt_state {
    const char *sep = " ";
    int next = 0;
    void emit(std::ostream &out, const char *name, int group, int bit, int width) {
        if (bit < 0) return;
        out << sep << name;
        if (group != -1)
            out << '(' << group << ")";
        out << ": ";
        if (next == bit)
            out << width;
        else
            out << bit << ".." << bit+width-1;
        next = bit+width;
        sep = ", "; }
    void emit(std::ostream &out, const char *name, int group,
              const vector<std::pair<int, int>> &bits) {
        if (bits.size() == 1) {
            emit(out, name, group, bits[0].first, bits[0].second - bits[0].first + 1);
        } else if (bits.size() > 1) {
            out << sep << name;
            if (group != -1)
                out << '(' << group << ")";
            out << ": [";
            sep = "";
            for (auto &p : bits) {
                out << sep << p.first << ".." << p.second;
                sep = ", "; }
            out << " ]"; } }
};

cstring format_name(int type) {
    if (type == TableFormat::MATCH)
        return "match";
    if (type == TableFormat::ACTION)
        return "action";
    if (type == TableFormat::IMMEDIATE)
        return "immediate";
    if (type == TableFormat::VERS)
        return "version";
    if (type == TableFormat::COUNTER)
        return "counter_ptr";
    if (type == TableFormat::METER)
        return "meter_ptr";
    if (type == TableFormat::INDIRECT_ACTION)
        return "action_ptr";
    if (type == TableFormat::SELECTOR)
        return "select_ptr";
    return "";
}

/* Emits the format portion of tind tables and for exact match tables. */
void MauAsmOutput::emit_table_format(std::ostream &out, indent_t indent,
          const TableFormat::Use &use, const TableMatch *tm, bool ternary) const {
    fmt_state fmt;
    out << indent << "format: {";
    int group = ternary ? -1 : 0;

    for (auto match_group : use.match_groups) {
        int type;
        vector<std::pair<int, int>> bits;
        // For table objects that are not match
        for (type = TableFormat::ACTION; type <= TableFormat::SELECTOR; type++) {
            if (match_group.mask[type].popcount() == 0) continue;
            bits.clear();
            int start = match_group.mask[type].ffs();
            while (start >= 0) {
                int end = match_group.mask[type].ffz(start);
                if (end == -1)
                    end = match_group.mask[type].max();
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

        if (ternary) {
            out << "}" << std::endl;
            return;
        }
        type = TableFormat::MATCH;

        bits.clear();
        int start = -1; int end = -1;

        // For every single match byte information.  Have to understand the byte alignment in
        // PHV to understand exactly which bits to use
        for (auto match_byte : match_group.match) {
            int byte_start = -1; int byte_end = -1;
            const IXBar::Use::Byte &byte = match_byte.first;
            const std::pair<int, bitvec> &byte_layout = match_byte.second;
            Slice sl(phv, byte.field, byte.lo, byte.hi);
            // Byte start and byte end are the bitvec positions for this specific byte
            byte_start = byte_layout.second.ffs() + sl.bytealign();
            byte_end = byte_start + byte_layout.first - 1;
            if (start == -1) {
                start = byte_start;
                end = byte_end;
            } else if (end == byte_start - 1) {
                end = byte_end;
            } else {
               bits.emplace_back(start, end);
               start = byte_start;
               end = byte_end;
            }
        }
        bits.emplace_back(start, end);
        fmt.emit(out, format_name(type), group, bits);
        group++;
    }

    if (ternary) {
        out << "}" << std::endl;
        return;
    }
    out << (fmt.sep + 1) << "}" << std::endl;

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


/* Adjusted to consider actions coming from hash distribution.  Now hash computation
   instructions have specific tags so that we can output the correct hash distribution
   unit corresponding to it. */
class MauAsmOutput::EmitAction : public Inspector {
    const MauAsmOutput          &self;
    std::ostream                &out;
    const IR::MAU::Table        *table;
    indent_t                    indent;
    const char                  *sep = nullptr;
    std::map<cstring, cstring>  alias;
    bool                        is_empty;

    void output_action(const IR::MAU::Action *act) {
        out << indent << canon_name(act->name) << ":" << std::endl;
        is_empty = true;
        if (table->layout.action_data_bytes_in_overhead > 0) {
             self.emit_immediate_format(out, indent, table, act);
            is_empty = false; }
        if (!alias.empty()) {
            out << indent << "- " << alias << std::endl;
            alias.clear(); }
        act->action.visit_children(*this);
        if (is_empty)
            out << indent << "- 0" << std::endl;
    }
    bool preorder(const IR::MAU::Action *act) override {
        for (auto prim : act->stateful) {
            if (prim->name == "counter.count") {
                if (auto aa = prim->operands[1]->to<IR::ActionArg>()) {
                    alias[aa->name] = "counter_ptr";
                } else {
                    ERROR("counter index arg '" << prim->operands[1] << "' is not an action arg");
                }
            } else {
                ERROR("skipping " << prim);
            }
        }
        output_action(act);
        return false; }

    bool preorder(const IR::MAU::Instruction *inst) override {
        out << indent << "- " << inst->name;
        sep = " ";
        is_empty = false;
        return true; }
    bool preorder(const IR::Constant *c) override {
        assert(sep);
        out << sep << c->asLong();
        sep = ", ";
        return false; }
    bool preorder(const IR::BoolLiteral *c) override {
        assert(sep);
        out << sep << c->value;
        sep = ", ";
        return false; }
    bool preorder(const IR::ActionArg *a) override {
        assert(sep);
        out << sep << a->toString();
        sep = ", ";
        return false; }
    bool preorder(const IR::MAU::HashDist *) override {
        assert(sep);
        out << sep << "hash_dist(";
        sep = "";
        const IXBar::Use use = table->resources->match_ixbar;
        for (auto hash_dist : use.hash_dist_use) {
            if (hash_dist.type == IXBar::Use::Immediate) {
                for (int i = 0; i < IXBar::HASH_DIST_GROUPS; i++) {
                     if (((1 << i) & hash_dist.slice) == 0) continue;
                     out << sep << i;
                     sep = ", "; } } }
        out << ")";
        sep = ", ";
        return false; }
    void postorder(const IR::MAU::Instruction *) override {
        sep = nullptr;
        out << std::endl; }
    bool preorder(const IR::Cast *c) override { visit(c->expr); return false; }
    bool preorder(const IR::Expression *exp) override {
        if (sep) {
            PhvInfo::Field::bitrange bits;
            auto f = self.phv.field(exp, &bits);
            if (f && !f->alloc.empty()) {
                auto &alloc = f->for_bit(bits.lo);
                out << sep << canon_name(f->name);
                if (alloc.field_bit > 0 || alloc.width != f->size) {
                    out << '.' << alloc.field_bit << '-' << alloc.field_hi();
                    bits.lo -= alloc.field_bit;
                    bits.hi -= alloc.field_bit; }
                if (bits.lo || bits.size() != alloc.width)
                    out << '(' << bits.lo << ".." << bits.hi << ')';
            } else {
                out << sep << "/* " << *exp << " */"; }
            sep = ", ";
        } else {
            out << indent << "# " << *exp << std::endl; }
        return false; }
    bool preorder(const IR::Slice *sl) override {
        if (sep && sl->e0->is<IR::ActionArg>()) {
            out << sep << sl->e0->toString() << '(' << *sl->e2 << ".." << *sl->e1 << ')';
            sep = ", ";
            return false; }
        return preorder(static_cast<const IR::Expression *>(sl)); }
    bool preorder(const IR::Node *n) override { BUG("Unexpected node %s in EmitAction", n); }

 public:
    EmitAction(const MauAsmOutput &s, std::ostream &o, const IR::MAU::Table *tbl, indent_t i)
    : self(s), out(o), table(tbl), indent(i) { visitDagOnce = false; }
};

/* Information on which tables are matched and ghosted.  This is used by the emit table format,
   and the hashing information.  Comes directly from the table_format object in the resources
   of a table*/
MauAsmOutput::TableMatch::TableMatch(const MauAsmOutput &, const PhvInfo &phv,
        const IR::MAU::Table *tbl) /*: self(s)*/ {
    if (tbl->resources->table_format.match_groups.size() == 0)
        return;

    // Determine which fields are part of a table match.  If a field partially ghosted,
    // then this information is contained within the bitvec and the int of the match_info
    for (auto match_info : tbl->resources->table_format.match_groups[0].match) {
        const IXBar::Use::Byte &byte = match_info.first;
        const std::pair<int, bitvec> &byte_layout = match_info.second;
        int lowest_part = byte.lo;
        // If the vector is partially ghosted, then the ffs will be the first location of the
        // ghost.  If it is an unaligned bit, then the ffs will be 0, as we couldn't break
        // that bit up particularly easily
        if (byte.hi - byte.lo + 1 > byte_layout.second.popcount()) {
            lowest_part += byte_layout.second.ffs() % 8;
        }
        Slice sl(phv, byte.field, lowest_part, lowest_part + byte_layout.first - 1);
        match_fields.push_back(sl);
    }

    // Determine which bytes are part of the ghosting bits.  Again like the match info,
    // whichever bits are ghosted must be handled in a particular way if the byte is partially
    // matched and partially ghosted
    for (auto ghost_info : tbl->resources->table_format.ghost_bits) {
        const IXBar::Use::Byte &byte = ghost_info.first;
        const std::pair<int, bitvec> &byte_layout = ghost_info.second;
        if (byte_layout.second.popcount() != 8) {
            // Ghosted bits from an 8-bit field may have multiple ghosting portions
            int start = byte_layout.second.ffs();
            do {
                int end = byte_layout.second.ffz(start);
                if (end == -1)
                    end = byte_layout.second.max() + 1;
                int start_byte = (start % 8) + byte.lo;
                int end_byte = ((end - 1) % 8) + byte.lo;
                Slice sl(phv, byte.field, start_byte, end_byte);
                ghost_bits.push_back(sl);
                start = byte_layout.second.ffs(end);
            } while (start != -1);
        } else {
            int start = byte.hi - byte_layout.first + 1;
            Slice sl(phv, byte.field, start, byte.hi);
            ghost_bits.push_back(sl);
        }
    }

    // Link match data together for an easier to read asm
    auto it = match_fields.begin();
    while (it != match_fields.end()) {
        auto next = it;
        if (++next != match_fields.end()) {
            Slice j = it->join(*next);
            if (j) {
                *it = j;
                match_fields.erase(next);
                continue;
            }
        }
        it = next;
    }
}

static cstring next_for(const IR::MAU::Table *tbl, cstring what, const DefaultNext &def) {
    if (tbl->next.count(what)) {
        if (!tbl->next[what]->empty())
            return tbl->next[what]->front()->name;
    } else if (tbl->next.count("$default")) {
        if (!tbl->next["$default"]->empty())
            return tbl->next["$default"]->front()->name; }
    return def.next_in_thread(tbl);
}


void MauAsmOutput::emit_gateway(std::ostream &out, indent_t gw_indent,
        const IR::MAU::Table *tbl, bool hash_action, cstring next_hit, cstring &gw_miss) const {
    CollectGatewayFields collect(phv, &tbl->resources->gateway_ixbar);
    tbl->apply(collect);
    if (collect.compute_offsets()) {
        bool have_xor = false;
        out << gw_indent << "match: {";
        const char *sep = " ";
        for (auto &f : collect.info) {
            if (f.second.xor_with) {
                have_xor = true;
                continue; }
            for (auto &offset : f.second.offsets) {
                out << sep << offset.first << ": " << Slice(f.first, offset.second);
                sep = ", "; } }
        for (auto &valid : collect.valid_offsets) {
            out << sep << valid.second << ": " << canon_name(valid.first) << ".$valid";
            sep = ", "; }
        out << (sep+1) << "}" << std::endl;
        if (have_xor) {
            out << gw_indent << "xor: {";
            sep = " ";
            for (auto &f : collect.info) {
                if (f.second.xor_with) {
                    for (auto &offset : f.second.offsets) {
                        out << sep << offset.first << ": " << Slice(f.first, offset.second);
                        sep = ", ";
                    }
                }
            }
            out << (sep+1) << "}" << std::endl;
        }
        if (collect.need_range)
            out << gw_indent << "range: 4" << std::endl;
        BuildGatewayMatch match(phv, collect);
        for (auto &line : tbl->gateway_rows) {
            out << gw_indent;
            if (line.first) {
                line.first->apply(match);
                out << match << ": ";
            } else {
                out << "miss: ";
            }
            if (line.second) {
                if (hash_action) {
                    out << "run_table";
                    gw_miss = next_for(tbl, line.second, default_next);
                } else {
                    out << next_for(tbl, line.second, default_next);
                }
            } else {
                if (hash_action)
                    out << next_hit;
                else
                    out << "run_table";
            }
            out << std::endl;
        }
        if (tbl->gateway_rows.back().first) {
            out << gw_indent << "miss: run_table" << std::endl;
        }
    } else {
        WARNING("Failed to fit gateway expression for " << tbl->name);
    }
}

void MauAsmOutput::emit_hash_action_gateway(std::ostream &out, indent_t gw_indent,
        const IR::MAU::Table *tbl) const {
    out << gw_indent << "0x0: " << next_for(tbl, "", default_next) << std::endl;
    out << gw_indent << "miss: " << next_for(tbl, "", default_next) << std::endl;
}

void MauAsmOutput::emit_table(std::ostream &out, const IR::MAU::Table *tbl) const {
    /* FIXME -- some of this should be method(s) in IR::MAU::Table? */
    TableMatch fmt(*this, phv, tbl);
    const char *tbl_type = "gateway";
    indent_t    indent(1);
    if (tbl->match_table)
        tbl_type = tbl->layout.ternary ? "ternary_match" : "exact_match";
    if (tbl->layout.hash_action)
        tbl_type = "hash_action";
    out << indent++ << tbl_type << ' '<< tbl->name << ' ' << tbl->logical_id % 16U << ':'
        << std::endl;
    if (tbl->match_table) {
        out << indent << "p4: { name: " << tbl->match_table->name;
        if (auto k = tbl->match_table->getConstantProperty("size"))
            out << ", size: " << k->asInt();
        for (auto at : tbl->attached)
            if (auto ap = at->to<IR::ActionProfile>())
                out << ", action_profile: " << ap->name;
        out << " }" << std::endl;
        auto memuse_name = tbl->get_use_name();
        emit_memory(out, indent, tbl->resources->memuse.at(memuse_name));
        emit_ixbar(out, indent, tbl->resources->match_ixbar,
                   &tbl->resources->memuse.at(memuse_name), &fmt, tbl->layout.hash_action);
        if (!tbl->layout.ternary && !tbl->layout.no_match_data()) {
            emit_table_format(out, indent, tbl->resources->table_format, &fmt, false);
        }
    }

    cstring next_hit = "";  cstring next_miss = "";
    cstring gw_miss;
    bool need_next_hit_map = false;
    if (tbl->match_table) {
        for (auto &next : tbl->next) {
            if (next.first[0] != '$') {
                need_next_hit_map = true;
                break;
            }
        }
        if (!need_next_hit_map) {
            next_hit = next_for(tbl, "$hit", default_next);
            next_miss = next_for(tbl, "$miss", default_next);
        }
    }



    if (tbl->uses_gateway() || tbl->layout.hash_action) {
        indent_t gw_indent = indent;
        if (tbl->match_table)
            out << gw_indent++ << "gateway:" << std::endl;
        emit_ixbar(out, gw_indent, tbl->resources->gateway_ixbar, 0, &fmt,
                   tbl->layout.hash_action);
        for (auto &use : Values(tbl->resources->memuse))
            if (use.type == Memories::Use::GATEWAY) {
                out << gw_indent << "row: " << use.row[0].row << std::endl;
                out << gw_indent << "bus: " << use.row[0].bus << std::endl;
                if (use.payload != 0)
                    out << gw_indent << "payload: " << use.payload << std::endl;
                break;
            }
        if (!tbl->layout.hash_action || tbl->uses_gateway())
            emit_gateway(out, gw_indent, tbl, tbl->layout.hash_action, next_hit, gw_miss);
        else
            emit_hash_action_gateway(out, gw_indent, tbl);
        if (!tbl->match_table)
            return;
    }

    if (need_next_hit_map) {
        out << indent << "hit: [ ";
        const char *sep = "";
        for (auto act : Values(tbl->actions)) {
            out << sep << next_for(tbl, act->name, default_next);
            sep = ", ";
        }
        out << " ]" << std::endl;
        out << indent << "miss: " << next_for(tbl, "$miss", default_next)  << std::endl;
    } else {
        if (tbl->layout.hash_action && gw_miss) {
            out << indent << "next: " << gw_miss << std::endl;
        } else if (next_miss != next_hit) {
            out << indent << "hit: " << next_hit << std::endl;
            out << indent << "miss: " << next_miss << std::endl;
        } else {
            out << indent << "next: " << next_hit << std::endl;
        }
    }
    /* FIXME -- this is a mess and needs to be rewritten to be sane */
    bool have_action = false, have_indirect = false;
    for (auto at : tbl->attached) {
        if (auto *ti = at->to<IR::MAU::TernaryIndirect>()) {
            have_indirect = true;
            cstring name = tbl->get_use_name(ti);
            out << indent << at->kind() << ": " << name << std::endl;
        } else if (at->is<IR::ActionProfile>()) {
            have_action = true;
        } else if (at->is<IR::MAU::ActionData>()) {
            assert(tbl->layout.action_data_bytes > tbl->layout.action_data_bytes_in_overhead);
            have_action = true; } }
    assert(have_indirect == (tbl->layout.ternary && (tbl->layout.overhead_bits > 0)));
    assert(have_action || (tbl->layout.action_data_bytes <=
                           tbl->layout.action_data_bytes_in_overhead));


    if (!have_indirect)
        emit_table_indir(out, indent, tbl);
    for (auto at : tbl->attached)
        at->apply(EmitAttached(*this, out, tbl));
}

class MauAsmOutput::UnattachedName : public MauInspector {
    const IR::MAU::Table *comp_table;
    cstring comparison_name;
    cstring return_name;
    const IR::Attached *unattached;
    bool setting = false;


    bool preorder(const IR::MAU::Table *tbl) {
        auto p = tbl->name.findlast('.');
        if (tbl->name == comparison_name ||
            (p != nullptr && tbl->name.before(p) == comparison_name)) {
             if (tbl->logical_id/16U != comp_table->logical_id/16U)
                 return true;
             return_name = tbl->get_use_name(unattached);
             if (setting)
                 BUG("Multiple tables claim to be attached table");
             setting = true;
        }
        return true;
    }

    void end_apply() {
        if (setting == false)
            BUG("Unable to find unattached table");
    }

 public:
    explicit UnattachedName(const IR::MAU::Table* ct, cstring cn, const IR::Attached *at) :
        comp_table(ct), comparison_name(cn), unattached(at) {}
    cstring name() { return return_name; }
};

void MauAsmOutput::find_indirect_index(std::ostream &out, const IR::MAU::Table *tbl,
         const IR::Attached *at) const {
    cstring func_name = "";
    IXBar::Use::hash_dist_type_t type;
    if (at->is<IR::Counter>()) {
        func_name = "counter.count";
        type = IXBar::Use::CounterPtr;
    }  else if (at->is<IR::Meter>()) {
        func_name = "meter.execute_meter";
        type = IXBar::Use::MeterPtr;
    }

    const IR::Expression *field = nullptr;
    for (auto action : Values(tbl->actions)) {
        for (auto instr : action->stateful) {
            if (instr->name != func_name) continue;
            if (phv.field(instr->operands[1]) == nullptr) {
                out << "(counter_ptr)";
                return;
            } else {
                field = instr->operands[1];
            }
        }
    }

    if (field == nullptr) {
        BUG("Indirect counter does not have an indirect index");
    }

    for (auto hash_dist : tbl->resources->match_ixbar.hash_dist_use) {
        if (hash_dist.type == type) {
            for (int i = 0; i < IXBar::HASH_DIST_GROUPS; i++) {
                if (((1 << i) & hash_dist.slice) == 0) continue;
                out << "(hash_dist ";
                out << (IXBar::HASH_DIST_GROUPS * hash_dist.unit + i) << ")";
                return;
            }
        }
    }
}

void MauAsmOutput::emit_table_indir(std::ostream &out, indent_t indent,
                                    const IR::MAU::Table *tbl) const {
    bool have_action = false;
    vector<const IR::Counter *> stats_tables;
    vector<const IR::Meter *> meter_tables;
    auto match_name = tbl->get_use_name();
    for (auto at : tbl->attached) {
        if (at->is<IR::MAU::TernaryIndirect>()) continue;
        if (at->is<IR::ActionProfile>() || at->is<IR::MAU::ActionData>())
            have_action = true;
        if (auto *c = at->to<IR::Counter>()) {
            stats_tables.push_back(c);
            continue;
        }
        if (auto *m = at->to<IR::Meter>()) {
            meter_tables.push_back(m);
            continue;
        }
        if (auto *ap = at->to<IR::ActionProfile>()) {
            auto &memuse = tbl->resources->memuse.at(match_name);
            out << indent << "action: ";
            if (memuse.unattached_profile) {
                UnattachedName unattached(tbl, memuse.profile_name, ap);
                pipe->apply(unattached);
                out << unattached.name();
            } else {
                out << tbl->get_use_name(ap);
            }
            if (at->indexed())
                out << "(action, action_ptr)";
            out << std::endl;
            continue;
        }

        if (auto *as = at->to<IR::ActionSelector>()) {
             auto &memuse = tbl->resources->memuse.at(match_name);
             out << indent << "selector: ";
             if (memuse.unattached_selector) {
                 UnattachedName unattached(tbl, memuse.selector_name, as);
                 pipe->apply(unattached);
                 out << unattached.name();
             } else {
                 out << tbl->get_use_name(as);
             }
             out << "(select_ptr)";
             out << std::endl;
             continue;
        }
        auto name = tbl->get_use_name(at);
        out << indent << at->kind() << ": " << name;
        if (at->indexed())
            out << '(' << at->kind() << ')';
        out << std::endl;
    }


    if (!stats_tables.empty()) {
        out << indent << "stats:" << std::endl;
        for (auto at : stats_tables) {
            auto name = tbl->get_use_name(at);
            out << indent << "- " << name;
            if (at->indexed()) {
                find_indirect_index(out, tbl, at);
            }
            out << std::endl;
        }
    }
    if (!meter_tables.empty()) {
        out << indent << "meter:" << std::endl;
        for (auto at : meter_tables) {
            auto name = tbl->get_use_name(at);
            out << indent << "- " << name;
            if (at->indexed())
                out << '(' << "meter_ptr" << ')';
            out << std::endl;
        }
    }


    if (!have_action && !tbl->actions.empty()) {
        out << indent++ << "actions:" << std::endl;
        for (auto act : Values(tbl->actions)) {
            act->apply(EmitAction(*this, out, tbl, indent));
        }
        --indent;
    }
    if (auto defact = tbl->match_table ? tbl->match_table->getDefaultAction() : nullptr) {
        out << indent << "default_action: ";
        const IR::Vector<IR::Expression> *args = nullptr;
        if (auto mc = defact->to<IR::MethodCallExpression>()) {
            args = mc->arguments;
            defact = mc->method; }
        if (auto path = defact->to<IR::PathExpression>())
            out << canon_name(path->path->name);
        else
            BUG("default action %s not handled", defact);
        if (args) {
            out << "(" << DBPrint::Prec_Low;
            const char *sep = "";
            for (auto arg : *args) {
                out << sep << arg;
                sep = ", "; }
            out << ")" << DBPrint::Reset; }
        out << std::endl; }
}

static void counter_format(std::ostream &out, const IR::CounterType type, int per_row) {
    if (type == IR::CounterType::PACKETS) {
        for (int i = 0; i < per_row; i++) {
            int first_bit = (per_row - i - 1) * 128/per_row;
            int last_bit = first_bit + 128/per_row - 1;
            out << "packets(" << i << "): " << first_bit << ".." << last_bit;
            if (i != per_row - 1)
                out << ", ";
        }
    } else if (type == IR::CounterType::BYTES) {
        for (int i = 0; i < per_row; i++) {
            int first_bit = (per_row - i - 1) * 128/per_row;
            int last_bit = first_bit + 128/per_row - 1;
            out << "bytes(" << i << "): " << first_bit << ".." << last_bit;
            if (i != per_row - 1)
                out << ", ";
        }
    } else if (type == IR::CounterType::BOTH) {
        int packet_size, byte_size;
        switch (per_row) {
            case 1:
                packet_size = 64; byte_size = 64; break;
            case 2:
                packet_size = 28; byte_size = 36; break;
            case 3:
                packet_size = 17; byte_size = 25; break;
            default:
                packet_size = 0; byte_size = 0; break;
        }
        for (int i = 0; i < per_row; i++) {
            int first_bit = (per_row - i - 1) * 128/per_row;
            out << "packets(" << i << "): " <<  first_bit << ".." << first_bit + packet_size - 1;
            out << ", ";
            out << "bytes(" << i << "): " << first_bit + packet_size << ".."
                << first_bit + packet_size + byte_size - 1;
            if (i != per_row - 1)
                out << ", ";
        }
    }
}

bool MauAsmOutput::EmitAttached::preorder(const IR::Counter *counter) {
    indent_t indent(1);
    auto name = tbl->get_use_name(counter);
    out << indent++ << "counter " << name << ":" << std::endl;
    out << indent << "p4: { name: " << counter->name << " }" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
    cstring count_type;
    switch (counter->type) {
        case IR::CounterType::PACKETS:
            count_type = "packets"; break;
        case IR::CounterType::BYTES:
            count_type = "bytes"; break;
        case IR::CounterType::BOTH:
            count_type = "packets_and_bytes"; break;
        default:
            count_type = "";
    }
    out << indent << "count: " << count_type << std::endl;
    out << indent << "format: {";
    counter_format(out, counter->type, tbl->resources->memuse.at(name).per_row);
    out << "}" << std::endl;
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::Meter *meter) {
    indent_t indent(1);
    auto name = tbl->get_use_name(meter);
    out << indent++ << "meter " << name << ":" << std::endl;
    out << indent << "p4: { name: " << meter->name << " }" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
    cstring imp_type;
    if (!meter->implementation.name)
        imp_type = "standard";
    else
        imp_type = meter->implementation.name;
    out << indent << "type: " << imp_type << std::endl;
    cstring count_type;
    switch (meter->type) {
        case IR::CounterType::PACKETS:
            count_type = "packets"; break;
        case IR::CounterType::BYTES:
            count_type = "bytes"; break;
        case IR::CounterType::BOTH:
            count_type = "packets_and_bytes"; break;
        default:
            count_type = "";
    }
    out << indent << "count: " << count_type << std::endl;
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::ActionProfile *ap) {
    auto match_name = tbl->get_use_name();
    if (tbl->resources->memuse.at(match_name).unattached_profile) {
        return false;
    }
    indent_t    indent(1);
    auto name = tbl->get_use_name(ap);
    out << indent++ << "action " << name << ':' << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
    for (auto act : Values(tbl->actions)) {
        if (act->args.empty()) continue;
        self.emit_action_data_format(out, indent, tbl, act);
    }
    if (!tbl->actions.empty()) {
        out << indent++ << "actions:" << std::endl;
        for (auto act : Values(tbl->actions))
            act->apply(EmitAction(self, out, tbl, indent));
        --indent; }
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::ActionSelector *as) {
    indent_t indent(1);
    auto match_name = tbl->get_use_name();
    if (tbl->resources->memuse.at(match_name).unattached_profile) {
        return false;
    }
    cstring name = tbl->get_use_name(as);
    out << indent++ << "selection " << name << ":" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
    self.emit_ixbar(out, indent, tbl->resources->selector_ixbar,
                    &tbl->resources->memuse.at(name), nullptr, false, true, as);
    out << indent << "mode: " << as->mode.name << " 0" << std::endl;
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::TernaryIndirect *ti) {
    indent_t    indent(1);
    auto name = tbl->get_use_name(ti);
    out << indent++ << "ternary_indirect " << name << ':' << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
    self.emit_table_format(out, indent, tbl->resources->table_format, nullptr, true);
    self.emit_table_indir(out, indent, tbl);
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::ActionData *ad) {
    indent_t    indent(1);
    auto name = tbl->get_use_name(ad);
    out << indent++ << "action " << name << ':' << std::endl;
    if (tbl->match_table)
        out << indent << "p4: { name: " << ad->name << " }" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
    for (auto act : Values(tbl->actions)) {
        if (act->args.empty()) continue;
        self.emit_action_data_format(out, indent, tbl, act);
    }
    if (!tbl->actions.empty()) {
        out << indent++ << "actions:" << std::endl;
        for (auto act : Values(tbl->actions))
            act->apply(EmitAction(self, out, tbl, indent));
        --indent; }
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::StatefulAlu *salu) {
    indent_t    indent(1);
    auto name = tbl->get_use_name(salu);
    out << indent++ << "stateful " << name << ':' << std::endl;
    out << indent << "p4: { name: " << salu->name << " }" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
    out << indent << "format: { lo: ";
    if (salu->dual)
        out << salu->width/2 << ", hi:" << salu->width/2;
    else
        out << salu->width;
    out << " }" << std::endl;
    return false;
}
