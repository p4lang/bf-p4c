#include "asm_output.h"
#include "gateway.h"
#include "lib/algorithm.h"
#include "lib/bitops.h"
#include "lib/bitrange.h"
#include "lib/hex.h"
#include "lib/indent.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "bf-p4c/parde/phase0.h"
#include "bf-p4c/phv/asm_output.h"
#include "resource.h"

class MauAsmOutput::EmitAttached : public Inspector {
    friend class MauAsmOutput;
    const MauAsmOutput          &self;
    std::ostream                &out;
    const IR::MAU::Table        *tbl;
    bool preorder(const IR::MAU::Counter *) override;
    bool preorder(const IR::MAU::Meter *) override;
    bool preorder(const IR::MAU::Selector *) override;
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
        if (stage.first.first == INGRESS && stage.first.second == 0)
            out << mauasm.pipe->phase0Info;
        for (auto tbl : stage.second)
            mauasm.emit_table(out, tbl);
    }
    return out;
}

class MauAsmOutput::TableMatch {
 public:
    vector<Slice>       match_fields;
    vector<Slice>       ghost_bits;

    TableMatch(const MauAsmOutput &s, const PhvInfo &phv, const IR::MAU::Table *tbl);
};


/** Function that emits the action data aliases needed for consistency across the action data
 *  bus.  The aliases are to be used to set up parameters for the Context JSON, and if necessary
 *  rename multiple action data parameters as one parameter name.  This must be done in order
 *  to have one parameter used in a container in the action
 *
 *  The constants converted to action data parameters are also printed here for the Context
 *  JSON.
 *
 *  The determination of the names is done by the action_format code, in order to simplify
 *  this function significantly.  This just outputs information for either immediate or
 *  action data tables.
 */
void MauAsmOutput::emit_action_data_alias(std::ostream &out, indent_t indent,
        const IR::MAU::Table *tbl, const IR::MAU::Action *af) const {
    bool is_immediate = tbl->layout.action_data_bytes_in_overhead > 0;
    const vector<ActionFormat::ActionDataPlacement> *placement_vec = nullptr;
    auto &use = tbl->resources->action_format;
    if (is_immediate)
        placement_vec = &(use.immediate_format.at(af->name));
    else
        placement_vec = &(use.action_data_format.at(af->name));

    out << indent << "- { ";
    size_t index = 0;
    bool last_entry = false;
    for (auto &placement : *placement_vec) {
        out << placement.get_action_name();

        auto type = static_cast<ActionFormat::cont_type_t>(placement.gen_index());
        out << ": " << use.get_format_name(placement.start, type, is_immediate,
                                           placement.range, (placement.arg_locs.size() == 1));
        if (placement.arg_locs.size() == 1 && placement.arg_locs[0].is_constant) {
            out << ", ";
            out << placement.arg_locs[0].get_asm_name();
            out << ": " << placement.arg_locs[0].constant_value;
        }

        if (index == placement_vec->size() - 1 && placement.arg_locs.size() == 1)
            last_entry = true;
        if (!last_entry)
             out << ", ";
        if (placement.arg_locs.size() > 1) {
            size_t arg_index = 0;
            for (auto &arg_loc : placement.arg_locs) {
                out << arg_loc.get_asm_name();
                out << ": " << placement.get_action_name()
                    << "(" << arg_loc.data_loc.min().index()
                    << ".." << arg_loc.data_loc.max().index() << ")";

                if (arg_loc.is_constant) {
                    out << ", ";
                    out << arg_loc.get_asm_name();
                    out << ": " << arg_loc.constant_value;
                }

                if (index == placement_vec->size() - 1
                    && arg_index == placement.arg_locs.size() - 1)
                    last_entry = true;
                if (!last_entry)
                    out << ", ";
                arg_index++;
            }
        }

        if (placement.bitmasked_set) {
            if (last_entry)
                out << ", ";
            out << placement.get_mask_name();
            out << ": " << use.get_format_name(placement.start, type, is_immediate,
                                               placement.range, false,
                                               placement.bitmasked_set);
            out << ", ";
            out << placement.mask_name;
            out << ": 0x" << hex(placement.range.getrange(0, placement.size));
            if (!last_entry)
                out << ", ";
        }
        index++;
    }
    out << " }" << std::endl;
}



// Simply emits the action data format of the action data table or action profile
void MauAsmOutput::emit_action_data_format(std::ostream &out, indent_t indent,
        const IR::MAU::Table *tbl, const IR::MAU::Action *af) const {
    auto &use = tbl->resources->action_format;
    auto &placement_vec = use.action_data_format.at(af->name);
    if (placement_vec.size() == 0)
        return;
    out << indent << "format " << canon_name(af->name) << ": { ";
    size_t index = 0;
    bool last_entry = false;
    for (auto &placement : placement_vec) {
        bitvec total_range(0, placement.size);
        auto type = static_cast<ActionFormat::cont_type_t>(placement.gen_index());
        out << use.get_format_name(placement.start, type, false, total_range, false);
        out << ": " << (8 * placement.start) << ".."
            << (8 * placement.start + placement.size - 1);
        if (index + 1 == placement_vec.size())
            last_entry = true;

        if (!last_entry)
            out << ", ";

        if (placement.bitmasked_set) {
            if (last_entry)
                out << ", ";
            out << use.get_format_name(placement.start, type, false, total_range, false,
                                       placement.bitmasked_set);
            int mask_start = 8 * placement.start + placement.size;
            out << ": " << mask_start << ".." << (mask_start + placement.size - 1);
            if (!last_entry)
                out << ", ";
        }

        index++;
    }
    out << " }" << std::endl;
}


struct FormatHash {
    vector<Slice> match_data;
    vector<Slice> ghost;
    cstring alg;
    FormatHash(vector<Slice> md, vector<Slice> g, cstring a)
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

static bool checkEqual(cstring a, cstring b) {
    return (strcasecmp(a.c_str(), b.c_str()) == 0);
}

std::ostream &operator<<(std::ostream &out, const FormatHash &hash) {
    if (checkEqual(hash.alg, "exact_match")) {
        if (!hash.match_data.empty()) {
            out << "random(" << emit_vector(hash.match_data, ", ") << ")";
            if (!hash.ghost.empty()) out << " ^ ";
        }
        if (!hash.ghost.empty()) {
            out << "stripe(" << emit_vector(hash.ghost, ", ") << ")";
        }
    } else if (checkEqual(hash.alg, "random")) {
        out << "random(" << emit_vector(hash.match_data, ", ") << ")";
    } else if (checkEqual(hash.alg, "crc16")) {
        out << "stripe(crc(" << crc_poly(16) << ", " << emit_vector(hash.match_data, ", ") << "))";
    } else if (checkEqual(hash.alg, "crc32")) {
        out << "stripe(crc(" << crc_poly(32) << ", " << emit_vector(hash.match_data, ", ") << "))";
    } else if (checkEqual(hash.alg, "identity")) {
        out << hash.match_data[0];
    } else if (checkEqual(hash.alg, "selector_identity")) {
        out << "stripe(" << hash.match_data[0] << ")";
    } else {
        BUG("Hashing Algorithm is not recognized");
    }
    return out;
}

/* Calculate the hash tables used by an individual P4 table in the IXBar */
void MauAsmOutput::emit_ixbar_gather_bytes(const vector<IXBar::Use::Byte> &use,
        map<int, map<int, Slice>> &sort, bool ternary) const {
    for (auto &b : use) {
        int byte_loc = IXBar::TERNARY_BYTES_PER_GROUP;
        int split_byte = 4;
        if (b.loc.byte == byte_loc && ternary) {
            auto *field = phv.field(b.field);
            field->foreach_byte([&](const PhvInfo::Field::alloc_slice &sl) {
                if (sl.field_bit != b.lo) return;
                if ((sl.container_bit % 8)  >= split_byte) {
                    int lo = std::max(b.hi - split_byte + 1, b.lo);
                    Slice sl(phv, b.field, lo, b.hi);
                    auto n = sort[b.loc.group + 1].emplace(byte_loc*8 + sl.bytealign() - 4, sl);
                    assert(n.second);
                } else {
                    Slice sl(phv, b.field, b.lo, b.hi);
                    auto n = sort[b.loc.group].emplace(b.loc.byte*8 + sl.bytealign(), sl);
                    assert(n.second);
                }
                /* Should be the code if the assembly parsing was reasonable
                if ((sl.container_bit % 8) < split_byte) {
                    int hi = std::min(b.hi, b.lo + split_byte - 1);
                    Slice sl(phv, b.field, b.lo, hi);
                    auto n = sort[b.loc.group].emplace(byte_loc*8 + sl.bytealign(), sl);
                    assert(n.second);
                }
                if ((sl.container_hi()% 8) >= split_byte) {
                    int lo = std::max(b.hi - split_byte + 1, b.lo);
                    Slice sl(phv, b.field, lo, b.hi);
                    auto n = sort[b.loc.group + 1].emplace(byte_loc*8 + sl.bytealign() - 4, sl);
                    assert(n.second);
                }
                */
            });

        } else {
            Slice sl(phv, b.field, b.lo, b.hi);
            auto n = sort[b.loc.group].emplace(b.loc.byte*8 + sl.bytealign(), sl);
            assert(n.second);
        }
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
void MauAsmOutput::emit_ways(std::ostream &out, indent_t indent, const IXBar::Use *use,
        const Memories::Use *mem) const {
    if (use == nullptr || use->way_use.empty())
        return;

    out << indent << "ways:" << std::endl;
    auto memway = mem->ways.begin();
    for (auto way : use->way_use) {
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

/* Generate asm for the hash distribution unit, specifically the unit, group, mask and shift value
   found in each hash dist assembly */
void MauAsmOutput::emit_hash_dist(std::ostream &out, indent_t indent,
        const vector<IXBar::HashDistUse> *hash_dist_use) const {
    if (hash_dist_use == nullptr || hash_dist_use->empty())
        return;
    out << indent++ << "hash_dist:" << std::endl;
    for (auto &hash_dist : *hash_dist_use) {
        for (auto slice : hash_dist.slices) {
            out << indent <<  slice << ": { ";
            out << "hash: " << hash_dist.groups.at(slice) << ", ";
            out << "mask: 0x" << hash_dist.masks.at(slice) << ", ";
            out << "shift: " << hash_dist.shifts.at(slice);
            if (hash_dist.expand.at(slice) > 0)
                out << ", expand: " << hash_dist.expand.at(slice);
            out << " }" << std::endl;
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
        vector<Slice> &ghost, const IXBar::Use *use, int hash_group) const {
    unsigned done = 0; unsigned mask_bits = 0;

    for (auto &select : use->select_use) {
        if (select.mode == "resilient")
            out << indent << "0..50: "
                << FormatHash(match_data, ghost, select.algorithm) << std::endl;
        else if (select.mode == "fair")
            out << indent << "0..13: "
                << FormatHash(match_data, ghost, select.algorithm) << std::endl;
        else
            BUG("Unrecognized mode of the action selector");
    }
    for (auto &way : use->way_use) {
        mask_bits |= way.mask;
        if (done & (1 << way.slice)) continue;
        done |= 1 << way.slice;
        out << indent << (way.slice*10) << ".." << (way.slice*10 + 9) << ": "
            << FormatHash(match_data, ghost, "exact_match") << std::endl;
    }
    for (auto range : bitranges(mask_bits)) {
        out << indent << (range.first+40);
        if (range.second != range.first) out << ".." << (range.second+40);
        out << ": " << FormatHash(match_data, ghost, "exact_match") << std::endl;
    }
    for (auto ident : use->bit_use) {
        out << indent << (40 + ident.bit);
        if (ident.width > 1)
            out << ".." << (39 + ident.bit + ident.width);
        out << ": " << Slice(phv, ident.field, ident.lo, ident.lo + ident.width - 1)
            << std:: endl;
        assert(hash_group == -1 || hash_group == ident.group);
    }

    if (use->hash_dist_hash.allocated) {
        auto &hdh = use->hash_dist_hash;
        for (int i = 0; i < IXBar::HASH_DIST_SLICES; i++) {
            if (((1 << i) & hdh.slice) == 0) continue;
            int first_bit = -1;
            int last_bit = -1;
            bool first_bit_found = false;
            bool last_bit_found = false;
            for (int j = i * IXBar::HASH_DIST_BITS; j < (i + 1) * IXBar::HASH_DIST_BITS; j++) {
                if (!first_bit_found) {
                    if (((1ULL << j) & hdh.bit_mask)) {
                        first_bit_found = true;
                        first_bit = j;
                    }
                    continue;
                }
                if (((1ULL << j) & hdh.bit_mask) == 0 && !last_bit_found) {
                    last_bit_found = true;
                    last_bit = j - 1;
                }
                if (((1ULL << j) & hdh.bit_mask) != 0 && last_bit_found) {
                    BUG("Split in address bits for hash distribution");
                }
            }
            // FIXME: this cannot work for larger than 16 bit addresses?
            if (hdh.algorithm == "identity") {
                for (auto slice : match_data) {
                    out << indent << (first_bit + slice.get_lo());
                    if (slice.width() > 1)
                        out << ".." << (first_bit + slice.get_hi());
                    out << ": " << slice << std::endl;
                }
            } else {
                if (last_bit == -1)
                last_bit = (i + 1) * IXBar::HASH_DIST_BITS - 1;
                out << indent << first_bit << ".." << last_bit;
                out << ": " << FormatHash(match_data, ghost, hdh.algorithm) << std::endl;
            }
        }
    }
}

void MauAsmOutput::emit_single_ixbar(std::ostream &out, indent_t indent, const IXBar::Use *use,
        const TableMatch *fmt) const {
    map<int, map<int, Slice>> sort;
    emit_ixbar_gather_bytes(use->use, sort, use->ternary);
    cstring group_type = use->ternary ? "ternary" : "exact";
    for (auto &group : sort)
        out << indent << group_type << " group " << group.first << ": "
                      << group.second << std::endl;
    int hash_group = 0;
    for (auto hash_table_input : use->hash_table_inputs) {
        if (hash_table_input) {
            for (int ht : bitvec(hash_table_input)) {
                out << indent++ << "hash " << ht << ":" << std::endl;
                vector<Slice> match_data;
                vector<Slice> ghost;
                emit_ixbar_hash_table(ht, match_data, ghost, fmt, sort);
                // FIXME: This is obviously an issue for larger selector tables,
                //  whole function needs to be replaced
                emit_ixbar_hash(out, indent, match_data, ghost, use, hash_group);
                --indent;
            }
            out << indent++ << "hash group " << hash_group << ":" << std::endl;
            out << indent << "table: [" << emit_vector(bitvec(hash_table_input), ", ") << "]"
                << std::endl;
            --indent;
        }
        hash_group++;
    }
}

/* Emit the ixbar use for a particular type of table */
void MauAsmOutput::emit_ixbar(std::ostream &out, indent_t indent, const IXBar::Use *use,
        const vector<IXBar::HashDistUse> *hash_dist_use, const Memories::Use *mem,
        const TableMatch *fmt) const {
    emit_ways(out, indent, use, mem);
    emit_hash_dist(out, indent, hash_dist_use);
    if ((use == nullptr || use->use.empty())
        && (hash_dist_use == nullptr || hash_dist_use->empty())) {
        return;
    }
    out << indent++ << "input_xbar:" << std::endl;
    if (use) {
        emit_single_ixbar(out, indent, use, fmt);
    }

    if (hash_dist_use) {
        for (auto &hash_dist : *hash_dist_use) {
            emit_single_ixbar(out, indent, &(hash_dist.use), nullptr);
        }
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

cstring format_name(int type, bool pfe_bit = false) {
    if (type == TableFormat::MATCH)
        return "match";
    if (type == TableFormat::ACTION)
        return "action";
    if (type == TableFormat::IMMEDIATE)
        return "immediate";
    if (type == TableFormat::VERS)
        return "version";
    if (type == TableFormat::COUNTER) {
        if (pfe_bit)
            return "counter_pfe";
        else
            return "counter_addr";
    }
    if (type == TableFormat::METER) {
        if (pfe_bit)
            return "meter_pfe";
        else
            return "meter_addr";
    }
    if (type == TableFormat::INDIRECT_ACTION)
        return "action_addr";
    return "";
}

void MauAsmOutput::emit_action_data_bus(std::ostream &out, indent_t indent,
        const IR::MAU::Table *tbl) const {
    auto &action_data_xbar = tbl->resources->action_data_xbar;
    auto &use = tbl->resources->action_format;
    out << indent << "action_bus: { ";

    if (tbl->layout.action_data_bytes > 0) {
        size_t total_index = 0;
        for (auto &rs : action_data_xbar.reserved_spaces) {
            bitvec total_range(0, ActionFormat::CONTAINER_SIZES[rs.location.type]);
            int byte_sz = ActionFormat::CONTAINER_SIZES[rs.location.type] / 8;
            out << rs.location.byte;
            if (byte_sz > 1)
                out << ".." << (rs.location.byte + byte_sz - 1);
            out << " : " << use.get_format_name(rs.byte_offset, rs.location.type, rs.immediate,
                                                total_range, false);
            if (total_index != action_data_xbar.reserved_spaces.size() - 1)
                out << ", ";
            else
                out << " ";
            total_index++;
        }
    }
    out << "}" << std::endl;
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
        vector<std::pair<int, int>> pfe_bits;
        // For table objects that are not match
        for (type = TableFormat::ACTION; type <= TableFormat::INDIRECT_ACTION; type++) {
            if (match_group.mask[type].popcount() == 0) continue;
            bits.clear();
            int start = match_group.mask[type].ffs();
            while (start >= 0) {
                int end = match_group.mask[type].ffz(start);
                if (end == -1)
                    end = match_group.mask[type].max().index();
                if (type == TableFormat::COUNTER || type == TableFormat::METER) {
                    bits.emplace_back(start, end - 2);
                    pfe_bits.emplace_back(end - 1, end - 1);
                } else {
                    bits.emplace_back(start, end - 1);
                }
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
                if (type == TableFormat::COUNTER || type == TableFormat::METER) {
                    fmt.emit(out, format_name(type, true), group, pfe_bits);
                }
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
            const bitvec &byte_layout = match_byte.second;
            // Byte start and byte end are the bitvec positions for this specific byte
            if (!byte_layout.is_contiguous())
                BUG("Currently non contiguous byte allocation in table format?");

            int byte_start = byte_layout.min().index();
            int byte_end = byte_layout.max().index();
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

void MauAsmOutput::emit_ternary_match(std::ostream &out, indent_t indent,
        const TableFormat::Use &use) const {
    if (use.tcam_use.size() == 0)
        return;
    out << indent << "match:" << std::endl;
    for (auto tcam_use : use.tcam_use) {
        out << indent << "- { ";
        out << "group: " << tcam_use.group << ", ";
        if (tcam_use.byte_group != -1)
            out << "byte_group: " << tcam_use.byte_group << ", ";
        if (tcam_use.byte_config != -1)
            out << "byte_config: " << tcam_use.byte_config << ", ";
        out << "dirtcam: 0x" << tcam_use.dirtcam;
        out << " }" << std::endl;
    }
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
    cstring                     act_name;
    bool                        is_empty;

    void action_context_json(const IR::MAU::Action *act) {
        if (act->args.size() > 0) {
            size_t list_index = 0;
            out << indent << "- p4_param_order: {";
            for (auto arg : act->args) {
                out << arg->name << ": ";
                out << arg->type->width_bits();
                if (list_index != act->args.size() - 1)
                    out << ", ";
                list_index++; }
            out << " }" << std::endl; }
    }
    bool preorder(const IR::MAU::Action *act) override {
        act_name = act->name;
        for (auto prim : act->stateful) {
            auto at = prim->operands.at(0)->to<IR::GlobalRef>()->obj->to<IR::Attached>();
            if (prim->operands.size() < 2) continue;
            if (auto aa = prim->operands.at(1)->to<IR::ActionArg>()) {
                alias[aa->name] = self.find_indirect_index(at); } }
        out << indent << canon_name(act->name) << ":" << std::endl;
        action_context_json(act);
        is_empty = true;
        if (table->layout.action_data_bytes > 0) {
            self.emit_action_data_alias(out, indent, table, act);
            is_empty = false;
        }
        if (!alias.empty()) {
            out << indent << "- " << alias << std::endl;
            is_empty = false;
            alias.clear(); }
        act->action.visit_children(*this);
        if (is_empty)
            out << indent << "- 0" << std::endl;
        return false; }
    bool preorder(const IR::MAU::SaluAction *act) override {
        out << indent << canon_name(act->name) << ":" << std::endl;
        is_empty = true;
        return true; }
    void postorder(const IR::ActionFunction *) override {
        if (is_empty) out << indent << "- 0" << std::endl; }
    bool preorder(const IR::Annotations *) override { return false; }

    bool preorder(const IR::MAU::Instruction *inst) override {
        out << indent << "- " << inst->name;
        sep = " ";
        is_empty = false;
        return true; }
    /** With instructions now over potential slices, must keep this information passed
     *  down through the entirety of the action pass
     */
    bool preorder(const IR::MAU::MultiOperand *mo) override {
         out << sep << mo->name;
         sep = ", ";
         return false;
    }
    void handle_phv_expr(const IR::Expression *expr) {
        if (sep) {
            bitrange bits;
            if (auto field = self.phv.field(expr, &bits)) {
                out << sep << canon_name(field->name);
                int count = 0;
                field->foreach_alloc(bits, [&](const PhvInfo::Field::alloc_slice &) {
                    count++;
                });
                if (count == 1) {
                    bool single_loc = (field->alloc_i.size() == 1);
                    field->foreach_alloc([&](const PhvInfo::Field::alloc_slice &alloc) {
                        if (!(alloc.field_bit <= bits.lo && alloc.field_hi() >= bits.hi))
                            return;
                        if (!single_loc)
                            out << "." << alloc.field_bit << "-" << alloc.field_hi();
                        if (bits.lo > alloc.field_bit || bits.hi < alloc.field_hi())
                            out << "(" << bits.lo << ".." << bits.hi << ")";
                    });
                }
            } else {
                ERROR(expr << " does not have a PHV allocation though it is used in an action");
                out << sep;
            }
            sep = ", ";
        } else {
            out << indent << "# " << *expr << std::endl;
        }
    }
    bool preorder(const IR::Slice *sl) override {
        assert(sep);
        if (self.phv.field(sl)) {
            handle_phv_expr(sl);
            return false;
        }
        visit(sl->e0);
        if (sl->e0->is<IR::ActionArg>()) {
            out << "." << sl->getL() << "-" << sl->getH();
        } else {
            out << "(" << sl->getL() << ".." << sl->getH() << ")";
        }
        return false;
    }
    bool preorder(const IR::Constant *c) override {
        assert(sep);
        out << sep << c->asLong();
        sep = ", ";
        return false;
    }
    bool preorder(const IR::BoolLiteral *c) override {
        assert(sep);
        out << sep << c->value;
        sep = ", ";
        return false;
    }
    bool preorder(const IR::MAU::ActionDataConstant *adc) override {
        assert(sep);
        out << sep << adc->name;
        sep = ", ";
        return false;
    }
    bool preorder(const IR::ActionArg *a) override {
        assert(sep);
        out << sep << a->toString();
        sep = ", ";
        return false; }
    bool preorder(const IR::MAU::SaluReg *r) override {
        assert(sep);
        out << sep << r->name;
        sep = ", ";
        return false; }
    bool preorder(const IR::MAU::SaluMathFunction *mf) override {
        assert(sep);
        out << sep << "math_table";
        sep = "(";
        visit(mf->expr, "expr");
        out << ")";
        sep = ", ";
        return false; }
    bool preorder(const IR::MAU::AttachedOutput *att) override {
        assert(sep);
        out << sep << table->get_use_name(att->attached);
        sep = ", ";
        return false; }
    bool preorder(const IR::MAU::HashDist *hd) override {
        assert(sep);
        out << sep << "hash_dist(";
        sep = "";
        for (size_t i = 0; i < hd->units.size(); i++) {
            out << hd->units[i];
            if (i != hd->units.size() - 1)
                out << ",";
        }
        out << ")";
        sep = ", ";
        return false; }
    bool preorder(const IR::LNot *) override {
        out << sep << "!";
        sep = "";
        return true; }
    bool preorder(const IR::Neg *) override {
        out << sep << "-";
        sep = "";
        return true; }
    bool preorder_binop(const IR::Operation::Binary *bin, const char *op) {
        visit(bin->left);
        sep = op;
        visit(bin->right);
        sep = ", ";
        return false; }
    bool preorder(const IR::LAnd *e) override { return preorder_binop(e, " & "); }
    bool preorder(const IR::LOr *e) override { return preorder_binop(e, " | "); }
    void postorder(const IR::MAU::Instruction *) override {
        sep = nullptr;
        out << std::endl;
    }
    bool preorder(const IR::Cast *c) override { visit(c->expr); return false; }
    bool preorder(const IR::Expression *exp) override {
        handle_phv_expr(exp);
        return false;
    }
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
        const bitvec &byte_layout = match_info.second;
        if (!byte_layout.is_contiguous()) {
            BUG("Currently table format byte is not contiguous?");
        }
        // If the vector is partially ghosted, then the ffs will be the first location of the
        // ghost.  If it is an unaligned bit, then the ffs will be 0, as we couldn't break
        // that bit up particularly easily
        int lo = byte.lo;
        int hi = byte.hi;
        if (byte_layout.popcount() != hi - lo + 1) {
            lo += ((byte_layout.min().index() % 8) - byte.bit_use.min().index());
        }

        Slice sl(phv, byte.field, lo, hi);

        if (sl.bytealign() != (byte_layout.min().index() % 8))
            BUG("Byte alignment does not match up properly");


        match_fields.push_back(sl);
    }

    // Determine which bytes are part of the ghosting bits.  Again like the match info,
    // whichever bits are ghosted must be handled in a particular way if the byte is partially
    // matched and partially ghosted
    for (auto ghost_info : tbl->resources->table_format.ghost_bits) {
        const IXBar::Use::Byte &byte = ghost_info.first;
        const bitvec &byte_layout = ghost_info.second;
        if (!byte_layout.is_contiguous()) {
            BUG("Currently ghosted format byte is not contiguous?");
        }
        int lo = byte.lo;
        int hi = byte.hi;
        if (byte_layout.popcount() != hi - lo + 1) {
            hi -= (byte.bit_use.max().index() - (byte_layout.max().index() % 8));
        }
        Slice sl(phv, byte.field, lo, hi);
        if (sl.bytealign() != (byte_layout.min().index() % 8))
            BUG("Byte alignment does not match up properly");
        ghost_bits.push_back(sl);
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

/** Gateways in Tofino are 4 44 bit TCAM rows used to compare conditionals.  A comparison will
 *  be done on a row by row basis.  If that row hits, then the gateway matches on that particular
 *  row.  Lastly all gateways have a miss row, which will automatically match if the none of the
 *  programmed gateway rows match
 *
 *  Gateways rows have the following strucure:
 *  - A match to compare the search bus/hash bus
 *  - An inhibit bit
 *  - A next table lookup
 *  - A payload shared between all 5 rows.
 *
 *  If the row is inhibited, this means when the row matches, the payload is placed onto the
 *  match result bus, overriding whatever was previously on the result bus.  This could have
 *  been the result of a match table.  The next table is then used in the predication vector.
 *  However, if the row is not inhibited, the gateway does nothing to the match bus, and the
 *  next table comes from either the hit or miss path.  Inhibit is turned on by providing
 *  a next table for a gateway row.
 *
 *  Let me provide two examples.  The first is a gateway table using the same logical table
 *  as an exact match table:
 *
 *  if (f == 2) {
 *      apply(exact_match);
 *      apply(x);
 *  }
 *  apply(y);
 *
 *  Let's take a look at the gateway:
 *
 *  ____match____|__inhibit__|__next_table__|__payload___
 *      f == 2       false        N/A           N/A       (0x2 : run_table)
 *      miss         true         y             0x0       (miss : y)
 *
 *  In this case, if f == 1, then we want the exact_match table to use it's results to determine
 *  what to do.  By not inhibiting, the exact_match table will determine what happens, including
 *  the next table.
 *
 *  However, the case is actual reversed when we need a table with no match data linked with
 *  a gateway:
 *
 *  if (f == 2) {
 *      apply(no_match_hit_path);
 *      apply(x);
 *  }
 *  apply(y);
 *
 *  ____match____|__inhibit__|__next_table__|__payload___
 *      f == 2       true         x             0x1       (0x2 : x)
 *      miss         false        N/A           0x0       (miss : run_table)
 *
 *  A table with no match will always go down the miss path, as the result bus will be labeled
 *  a miss coming out of the RAM array.  The only way to go down the hit path is to inhibit the
 *  gateway.  Thus if the f == 1, the result bus goes through the hit bus with the payload 0x1.
 *  This bit is then used a per flow enable bit, for things like finding the action instruction
 *  address or an address from hash distribution.  It will then use next table in the gateway.
 *  When f != 1, the gateway will not override, and the table will automatically miss.  Then,
 *  the miss next table is used to determine where to go next
 */
void MauAsmOutput::emit_gateway(std::ostream &out, indent_t gw_indent,
        const IR::MAU::Table *tbl, bool no_match, cstring next_hit, cstring &gw_miss) const {
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
                if (no_match) {
                    out << "run_table";
                    gw_miss = next_for(tbl, line.second, default_next);
                } else {
                    out << next_for(tbl, line.second, default_next);
                }
            } else {
                if (no_match)
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

/** This allocates a gateway that always hits, in order for the table to always go through the
 *  the hit pathway.
 */
void MauAsmOutput::emit_no_match_gateway(std::ostream &out, indent_t gw_indent,
        const IR::MAU::Table *tbl) const {
    out << gw_indent << "0x0: " << next_for(tbl, "", default_next) << std::endl;
    out << gw_indent << "miss: " << next_for(tbl, "", default_next) << std::endl;
}

void MauAsmOutput::emit_table_context_json(std::ostream &out, indent_t indent,
        const IR::MAU::Table *tbl) const {
    out << indent << "p4: { name: " << canon_name(tbl->match_table->name);
    if (auto k = tbl->match_table->getConstantProperty("size"))
        out << ", size: " << k->asInt();
    for (auto at : tbl->attached)
        if (auto ap = at->to<IR::MAU::ActionData>())
            if (!ap->direct)
                out << ", action_profile: " << canon_name(ap->name);
    out << " }" << std::endl;

    if (tbl->match_key.empty())
        return;

    out << indent++ <<  "p4_param_order: " << std::endl;
    int p4_param_index = 0;
    for (auto ixbar_read : tbl->match_key) {
        if (ixbar_read->match_type.name == "selector") continue;
        if (p4_param_index != ixbar_read->p4_param_order) continue;
        auto *expr = ixbar_read->expr;
        if (ixbar_read->from_mask)
            expr = expr->to<IR::Slice>()->e0;
        out << indent << canon_name(phv.field(expr)->name) << ": ";
        out << "{ type: " << ixbar_read->match_type.name << ", ";
        out << "size: " << expr->type->width_bits() << " }" << std::endl;
        p4_param_index++;
    }
}

void MauAsmOutput::emit_table(std::ostream &out, const IR::MAU::Table *tbl) const {
    /* FIXME -- some of this should be method(s) in IR::MAU::Table? */
    TableMatch fmt(*this, phv, tbl);
    const char *tbl_type = "gateway";
    indent_t    indent(1);
    bool no_match_hit = tbl->layout.no_match_hit_path() && !tbl->gateway_only();
    if (!tbl->gateway_only())
        tbl_type = tbl->layout.ternary ? "ternary_match" : "exact_match";
    if (no_match_hit)
        tbl_type = "hash_action";
    out << indent++ << tbl_type << ' '<< tbl->name << ' ' << tbl->logical_id % 16U << ':'
        << std::endl;
    if (!tbl->gateway_only()) {
        emit_table_context_json(out, indent, tbl);
        auto memuse_name = tbl->get_use_name();
        emit_memory(out, indent, tbl->resources->memuse.at(memuse_name));
        emit_ixbar(out, indent, &tbl->resources->match_ixbar, &tbl->resources->hash_dists,
                   &tbl->resources->memuse.at(memuse_name), &fmt);
        if (!tbl->layout.ternary && !tbl->layout.no_match_data()) {
            emit_table_format(out, indent, tbl->resources->table_format, &fmt, false);
        }

        if (tbl->layout.ternary)
            emit_ternary_match(out, indent, tbl->resources->table_format);
    }

    cstring next_hit = "";  cstring next_miss = "";
    cstring gw_miss;
    bool need_next_hit_map = false;
    if (!tbl->gateway_only()) {
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


    if (tbl->uses_gateway() || (tbl->layout.no_match_hit_path())) {
        indent_t gw_indent = indent;
        if (!tbl->gateway_only())
            out << gw_indent++ << "gateway:" << std::endl;
        emit_ixbar(out, gw_indent, &tbl->resources->gateway_ixbar, nullptr, nullptr, &fmt);
        for (auto &use : Values(tbl->resources->memuse)) {
            if (use.type == Memories::Use::GATEWAY) {
                out << gw_indent << "row: " << use.row[0].row << std::endl;
                out << gw_indent << "bus: " << use.row[0].bus << std::endl;
                out << gw_indent << "unit: " << use.gateway.unit << std::endl;
                // FIXME: This is the case for a gateway attached to a ternary or exact match
                if (use.gateway.payload_value == 1) {
                    out << gw_indent << "payload: " << use.gateway.payload_value << std::endl;
                    // FIXME: Assembler doesn't yet support payload bus/row for every table
                }
                break;
            }
        }
        if (!tbl->layout.no_match_data() || tbl->uses_gateway())
            emit_gateway(out, gw_indent, tbl, no_match_hit, next_hit, gw_miss);
        else
            emit_no_match_gateway(out, gw_indent, tbl);
        if (tbl->gateway_only())
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
        if (no_match_hit && gw_miss) {
            out << indent << "next: " << gw_miss << std::endl;
        } else if (next_miss != next_hit) {
            out << indent << "hit: " << next_hit << std::endl;
            out << indent << "miss: " << next_miss << std::endl;
        } else {
            out << indent << "next: " << next_hit << std::endl;
        }
    }

    if (tbl->layout.action_data_bytes_in_overhead > 0)
        emit_action_data_bus(out, indent, tbl);

    /* FIXME -- this is a mess and needs to be rewritten to be sane */
    bool have_action = false, have_indirect = false;
    for (auto at : tbl->attached) {
        if (auto *ti = at->to<IR::MAU::TernaryIndirect>()) {
            have_indirect = true;
            cstring name = tbl->get_use_name(ti);
            out << indent << at->kind() << ": " << name << std::endl;
        } else if (auto ad = at->to<IR::MAU::ActionData>()) {
            bool ad_check = tbl->layout.action_data_bytes_in_overhead
                            < tbl->layout.action_data_bytes;
            ad_check |= tbl->layout.indirect_action_addr_bits > 0;
            BUG_CHECK(ad_check, "Action Data Table %s misconfigured", ad->name);
            have_action = true; } }
    assert(have_indirect == (tbl->layout.ternary));
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

/** Figure out which overhead field in the table is being used to index an attached
 *  indirect table (counter, meter, stateful, action data) and return its asm name.  Contained
 *  now within the actual IR for Hash Distribution
 */ 
std::string MauAsmOutput::find_indirect_index(const IR::Attached *at) const {
    cstring index_name;
    if (auto hdat = at->to<IR::MAU::HashDistAttached>()) {
        if (auto hash_dist = hdat->hash_dist) {
            return "hash_dist " + std::to_string(hash_dist->units[0]);
        }
    }

    if (at->is<IR::MAU::Counter>()) {
        return "counter_addr";
    } else if (at->is<IR::MAU::Meter>() || at->is<IR::MAU::StatefulAlu>()
               || at->is<IR::MAU::Selector>()) {
        return "meter_addr";
    } else if (at->is<IR::MAU::ActionData>()) {
        return "action, action_addr";
    } else {
        BUG("unsupported attached table type in find_indirect_index: %s", at);
    }
    return "";
}

void MauAsmOutput::emit_table_indir(std::ostream &out, indent_t indent,
                                    const IR::MAU::Table *tbl) const {
    bool have_action = false;
    auto match_name = tbl->get_use_name();
    for (auto at : tbl->attached) {
        if (at->is<IR::MAU::TernaryIndirect>()) continue;
        if (auto *ad = at->to<IR::MAU::ActionData>()) {
            have_action = true;
            out << indent << "action: ";
            auto &memuse = tbl->resources->memuse.at(match_name);
            if (memuse.unattached_profile) {
                UnattachedName unattached(tbl, memuse.profile_name, ad);
                pipe->apply(unattached);
                out << unattached.name();
            } else {
                out << tbl->get_use_name(ad);
            }
        } else if (auto *as = at->to<IR::MAU::Selector>()) {
             auto &memuse = tbl->resources->memuse.at(match_name);
             out << indent << "selector: ";
             if (memuse.unattached_selector) {
                 UnattachedName unattached(tbl, memuse.selector_name, as);
                 pipe->apply(unattached);
                 out << unattached.name();
             } else {
                 out << tbl->get_use_name(as);
             }
        } else {
            out << indent << at->kind() << ": " << tbl->get_use_name(at);
        }

        if (at->indexed())
            out << '(' << find_indirect_index(at) << ')';
        out << std::endl;
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
        out << std::endl;
        if (args && args->size() > 0) {
            auto params = defact->type->to<IR::Type_Action>()->parameters;
            BUG_CHECK(params->size() == args->size(), "Wrong number of params to default action");
            out << indent++ << "default_action_parameters:" << std::endl;
            int index = 0;
            for (auto arg : *args)
                out << indent << params->getParameter(index++)->name << ": " << arg << std::endl;
            --indent; } }
}

static void counter_format(std::ostream &out, const IR::MAU::DataAggregation type, int per_row) {
    if (type == IR::MAU::DataAggregation::PACKETS) {
        for (int i = 0; i < per_row; i++) {
            int first_bit = (per_row - i - 1) * 128/per_row;
            int last_bit = first_bit + 128/per_row - 1;
            out << "packets(" << i << "): " << first_bit << ".." << last_bit;
            if (i != per_row - 1)
                out << ", ";
        }
    } else if (type == IR::MAU::DataAggregation::BYTES) {
        for (int i = 0; i < per_row; i++) {
            int first_bit = (per_row - i - 1) * 128/per_row;
            int last_bit = first_bit + 128/per_row - 1;
            out << "bytes(" << i << "): " << first_bit << ".." << last_bit;
            if (i != per_row - 1)
                out << ", ";
        }
    } else if (type == IR::MAU::DataAggregation::BOTH) {
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

bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::Counter *counter) {
    indent_t indent(1);
    auto name = tbl->get_use_name(counter);
    out << indent++ << "counter " << name << ":" << std::endl;
    out << indent << "p4: { name: " << canon_name(counter->name) << " }" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
    cstring count_type;
    switch (counter->type) {
        case IR::MAU::DataAggregation::PACKETS:
            count_type = "packets"; break;
        case IR::MAU::DataAggregation::BYTES:
            count_type = "bytes"; break;
        case IR::MAU::DataAggregation::BOTH:
            count_type = "packets_and_bytes"; break;
        default:
            count_type = "";
    }
    out << indent << "count: " << count_type << std::endl;
    out << indent << "format: {";
    counter_format(out, counter->type, tbl->resources->memuse.at(name).per_row);
    out << "}" << std::endl;
    if (counter->indexed() && !tbl->layout.hash_action)
        out << indent << "per_flow_enable: " << "counter_pfe" << std::endl;
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::Meter *meter) {
    indent_t indent(1);
    auto name = tbl->get_use_name(meter);
    out << indent++ << "meter " << name << ":" << std::endl;
    out << indent << "p4: { name: " << canon_name(meter->name) << " }" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
    cstring imp_type;
    if (!meter->implementation.name)
        imp_type = "standard";
    else
        imp_type = meter->implementation.name;
    out << indent << "type: " << imp_type << std::endl;
    cstring count_type;
    switch (meter->type) {
        case IR::MAU::DataAggregation::PACKETS:
            count_type = "packets"; break;
        case IR::MAU::DataAggregation::BYTES:
            count_type = "bytes"; break;
        case IR::MAU::DataAggregation::BOTH:
            count_type = "packets_and_bytes"; break;
        default:
            count_type = "";
    }
    out << indent << "count: " << count_type << std::endl;
    if (meter->indexed() && !tbl->layout.hash_action)
        out << indent << "per_flow_enable: " << "meter_pfe" << std::endl;
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::Selector *as) {
    indent_t indent(1);
    auto match_name = tbl->get_use_name();
    if (tbl->resources->memuse.at(match_name).unattached_profile) {
        return false;
    }
    cstring name = tbl->get_use_name(as);
    out << indent++ << "selection " << name << ":" << std::endl;
    out << indent << "p4: { name: " << canon_name(as->name) << " }" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
    self.emit_ixbar(out, indent, &tbl->resources->selector_ixbar, nullptr, nullptr, nullptr);
    out << indent << "mode: " << (as->mode ? as->mode.name : "fair") << " 0" << std::endl;
    out << indent << "per_flow_enable: " << "meter_pfe" << std::endl;
    // FIXME: Currently outputting default values for now, these must be brought through
    // either the tofino native definitions or pragmas
    out << indent << "non_linear: true" << std::endl;
    out << indent << "pool_sizes: [" << as->group_size << "]" << std::endl;
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
    if (!ad->direct) {
        auto match_name = tbl->get_use_name();
        if (tbl->resources->memuse.at(match_name).unattached_profile)
            return false;
    }
    auto name = tbl->get_use_name(ad);
    out << indent++ << "action " << name << ':' << std::endl;
    out << indent << "p4: { name: " << canon_name(ad->name);
    if (!ad->direct)
        out << ", size: " << ad->size;
    out << " }" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
    for (auto act : Values(tbl->actions)) {
        if (act->args.empty()) continue;
        self.emit_action_data_format(out, indent, tbl, act);
    }
    self.emit_action_data_bus(out, indent, tbl);
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
    out << indent << "p4: { name: " << canon_name(salu->name) << " }" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
    self.emit_ixbar(out, indent, &tbl->resources->salu_ixbar, nullptr, nullptr, nullptr);
    out << indent << "format: { lo: ";
    if (salu->dual)
        out << salu->width/2 << ", hi:" << salu->width/2;
    else
        out << salu->width;
    out << " }" << std::endl;
    if (salu->math.valid) {
        out << indent++ << "math_table:" << std::endl;
        out << indent << "invert: " << salu->math.exp_invert << std::endl;
        out << indent << "shift: " << salu->math.exp_shift << std::endl;
        out << indent << "scale: " << salu->math.scale << std::endl;
        out << indent << "data: [";
        const char *sep = " ";
        for (auto v : salu->math.table) {
            out << sep << v;
            sep = ", "; }
        out << (sep+1) << ']' << std::endl;
        --indent; }
    if (!salu->instruction.empty()) {
        out << indent++ << "actions:" << std::endl;
        for (auto act : Values(salu->instruction))
            act->apply(EmitAction(self, out, tbl, indent));
        --indent; }
    if (salu->indexed() && !tbl->layout.hash_action)
        out << indent << "per_flow_enable: meter_pfe" << std::endl;
    return false;
}
