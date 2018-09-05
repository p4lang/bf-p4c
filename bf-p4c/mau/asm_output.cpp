#include "bf-p4c/mau/asm_output.h"
#include <regex>
#include <string>
#include "bf-p4c/common/alias.h"
#include "bf-p4c/mau/gateway.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/table_format.h"
#include "bf-p4c/parde/phase0.h"
#include "bf-p4c/phv/asm_output.h"
#include "lib/algorithm.h"
#include "lib/bitops.h"
#include "lib/bitrange.h"
#include "lib/hex.h"
#include "lib/indent.h"
#include "lib/stringref.h"

class MauAsmOutput::EmitAttached : public Inspector {
    friend class MauAsmOutput;
    const MauAsmOutput          &self;
    std::ostream                &out;
    const IR::MAU::Table        *tbl;
    int                         stage;
    gress_t                     gress;
    bool is_unattached(const IR::MAU::AttachedMemory *at);
    bool preorder(const IR::MAU::Counter *) override;
    bool preorder(const IR::MAU::Meter *) override;
    bool preorder(const IR::MAU::Selector *) override;
    bool preorder(const IR::MAU::TernaryIndirect *) override;
    bool preorder(const IR::MAU::ActionData *) override;
    bool preorder(const IR::MAU::StatefulAlu *) override;
    // XXX(zma) bfas does not recognize idletime as a table type,
    // therefore we're emitting idletime inlined, see MauAsmOutput::emit_idletime
    bool preorder(const IR::MAU::IdleTime *) override { return false; }
    bool preorder(const IR::Attached *att) override {
        BUG("unknown attached table type %s", typeid(*att).name()); }
    EmitAttached(const MauAsmOutput &s, std::ostream &o, const IR::MAU::Table *t,
        int stg, gress_t gt)
    : self(s), out(o), tbl(t), stage(stg), gress(gt) {}};

std::ostream &operator<<(std::ostream &out, const MauAsmOutput &mauasm) {
    indent_t indent(1);
    for (auto &stage : mauasm.by_stage) {
        out << "stage " << stage.first.second << ' ' << stage.first.first << ':' << std::endl;
#if HAVE_JBAY
        if (Device::currentDevice() == Device::JBAY && stage.first.second > 0)
            out << indent << "dependency: match" << std::endl;
#endif
        for (auto &tbl : stage.second) {
            BUG_CHECK(!(tbl.phase0Info && tbl.tableInfo),
                      "TableInstance is both a phase 0 table and a regular table?");
            if (tbl.phase0Info)
                out << tbl.phase0Info;
            else
                mauasm.emit_table(out, tbl.tableInfo, stage.first.second /* stage */,
                    stage.first.first /* gress */);
        }
    }
    return out;
}

class MauAsmOutput::TableMatch {
 public:
    safe_vector<Slice>       match_fields;
    safe_vector<Slice>       ghost_bits;
    const IR::MAU::Table     *table = nullptr;

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
    auto &use = tbl->resources->action_format;
    auto orig_placement_vec = use.action_data_format.at(af->name);

    ActionFormat::SingleActionALUPlacement placement_vec;

    for (auto placement : orig_placement_vec) {
        if (placement.specialities != 0)
            continue;
        placement_vec.push_back(placement);
    }

    out << indent << "- { ";
    size_t index = 0;
    bool last_entry = false;
    for (auto &placement : placement_vec) {
        if (placement.specialities != 0)
            continue;
        out << placement.get_action_name();

        auto type = static_cast<ActionFormat::cont_type_t>(placement.gen_index());
        out << ": " << use.get_format_name(placement.start, type, placement.immediate,
                                           placement.slot_bits, !placement.requires_alias());
        if (!placement.requires_alias() && placement.arg_locs[0].is_constant) {
            out << ", ";
            out << placement.arg_locs[0].get_asm_name();
            out << ": " << placement.arg_locs[0].constant_value;
        }

        if (index == placement_vec.size() - 1 && !placement.requires_alias())
            last_entry = true;
        if (!last_entry)
             out << ", ";
        if (placement.requires_alias()) {
            size_t arg_index = 0;
            for (auto &arg_loc : placement.arg_locs) {
                out << arg_loc.get_asm_name();
                out << ": " << placement.get_action_name()
                    << "(" << arg_loc.slot_loc.min().index()
                    << ".." << arg_loc.slot_loc.max().index() << ")";

                if (arg_loc.is_constant) {
                    out << ", ";
                    out << arg_loc.get_asm_name();
                    out << ": " << arg_loc.constant_value;
                }

                if (index == placement_vec.size() - 1
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
            out << ": " << use.get_format_name(placement.start, type, placement.immediate,
                                               placement.slot_bits, false,
                                               placement.bitmasked_set);
            out << ", ";
            out << placement.mask_name;
            out << ": 0x" << hex(placement.slot_bits.getrange(0, placement.alu_size));
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

    std::set<std::pair<int, int>> single_placements;

    size_t max_format = 0;
    for (auto &placement : placement_vec) {
        if (placement.immediate) continue;
        auto single_placement = std::make_pair(placement.start, placement.alu_size);
        if (single_placements.count(single_placement) > 0)
            continue;
        max_format++;
        single_placements.insert(single_placement);
    }
    if (max_format == 0)
        return;

    out << indent << "format " << canon_name(af->name) << ": { ";
    size_t index = 0;
    bool last_entry = false;


    single_placements.clear();

    for (auto &placement : placement_vec) {
        if (placement.immediate) continue;
        bitvec total_range(0, placement.alu_size);
        auto single_placement = std::make_pair(placement.start, placement.alu_size);
        if (single_placements.count(single_placement) > 0)
            continue;
        auto type = static_cast<ActionFormat::cont_type_t>(placement.gen_index());

        out << use.get_format_name(placement.start, type, false, total_range, false);
        out << ": " << (8 * placement.start) << ".."
            << (8 * placement.start + placement.alu_size - 1);
        if (index + 1 == max_format)
            last_entry = true;

        if (!last_entry)
            out << ", ";

        if (placement.bitmasked_set) {
            if (last_entry)
                out << ", ";
            out << use.get_format_name(placement.start, type, false, total_range, false,
                                       placement.bitmasked_set);
            int mask_start = 8 * placement.start + placement.alu_size;
            out << ": " << mask_start << ".." << (mask_start + placement.alu_size - 1);
            if (!last_entry)
                out << ", ";
        }
        single_placements.insert(single_placement);
        index++;
    }
    out << " }" << std::endl;
}


struct FormatHash {
    const safe_vector<Slice>    *match_data;
    const std::map<int, Slice>  *match_data_map;
    const Slice                 *ghost;
    IR::MAU::hash_function      func;
    int                         total_bits = 0;
    le_bitrange                 *field_range;

    FormatHash(const safe_vector<Slice> *md, const std::map<int, Slice> *mdm, const Slice *g,
               IR::MAU::hash_function f, int tb = 0, le_bitrange *fr = nullptr)
        : match_data(md), match_data_map(mdm), ghost(g), func(f), total_bits(tb), field_range(fr) {
        BUG_CHECK(match_data == nullptr || match_data_map == nullptr, "FormatHash not "
                  "configured correctly");
    }
};

std::ostream &operator<<(std::ostream &out, const FormatHash &hash) {
    if (hash.field_range != nullptr) {
        FormatHash hash2(hash.match_data, hash.match_data_map, hash.ghost, hash.func,
                         hash.total_bits);
        out << "slice(" << hash2 << ", " << hash.field_range->lo << "..";
        out << hash.field_range->hi << ")";
        return out;
    }

    if (hash.func.type == IR::MAU::hash_function::IDENTITY) {
        BUG_CHECK(hash.match_data, "For an identity, must be a standard vector");
        out << "stripe(" << emit_vector(*hash.match_data) << ")";
    } else if (hash.func.type == IR::MAU::hash_function::RANDOM) {
        BUG_CHECK(hash.match_data, "For a random, must be a standard vector");
        if (!hash.match_data->empty()) {
            out << "random(" << emit_vector(*hash.match_data, ", ") << ")";
            if (hash.ghost) out << " ^ ";
        }
        if (hash.ghost) {
            out << *hash.ghost;
        }
    } else if (hash.func.type == IR::MAU::hash_function::CRC) {
        BUG_CHECK(hash.match_data_map, "For a crc, must be a map");
        out << "stripe(crc";
        if (hash.func.reverse) out << "_rev";
        out << "(0x" << hex(hash.func.poly) << ", ";
        if (hash.func.init) {
            out << "0x" << hex(hash.func.init) << ", ";
            out << hash.total_bits << ", ";
        }
        out << *hash.match_data_map << ")";
        // FIXME -- final_xor needs to go into the seed for the hash group
        out << ")";
    } else if (hash.func.type == IR::MAU::hash_function::XOR) {
        // fixme -- should be able to implement this in a hash function
        BUG("xor hashing algorithm not supported");
    } else if (hash.func.type == IR::MAU::hash_function::CSUM) {
        BUG("csum hashing algorithm not supported");
    } else {
        BUG("unknown hashing algorithm %d", hash.func.type);
    }
    return out;
}

/* Calculate the hash tables used by an individual P4 table in the IXBar */
void MauAsmOutput::emit_ixbar_gather_bytes(const safe_vector<IXBar::Use::Byte> &use,
        std::map<int, std::map<int, Slice>> &sort,
        std::map<int, std::map<int, Slice>> &midbytes, bool ternary, bool atcam) const {
    for (auto &b : use) {
        int byte_loc = IXBar::TERNARY_BYTES_PER_GROUP;
        if (atcam && !b.is_spec(IXBar::ATCAM_INDEX))
            continue;
        for (auto &fi : b.field_bytes) {
            if (b.loc.byte == byte_loc && ternary) {
                Slice sl(phv, fi.get_use_name(), fi.lo, fi.hi);
                auto n = midbytes[b.loc.group/2].emplace(sl.bytealign(), sl);
                BUG_CHECK(n.second, "duplicate byte use in ixbar");
            } else {
                Slice sl(phv, fi.get_use_name(), fi.lo, fi.hi);
                auto n = sort[b.loc.group].emplace(b.loc.byte*8 + sl.bytealign(), sl);
                BUG_CHECK(n.second, "duplicate byte use in ixbar");
            }
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
    out << indent++ << "ways:" << std::endl;

    auto ixbar_way = use->way_use.begin();
    for (auto mem_way : mem->ways) {
        BUG_CHECK(ixbar_way != use->way_use.end(), "No more ixbar ways to output in asm_output");
        out << indent << "- [" << ixbar_way->group << ", " << ixbar_way->slice;
        out << ", 0x" << hex(mem_way.select_mask) << ", ";
        size_t index = 0;
        for (auto ram : mem_way.rams) {
            out << "[" << ram.first << ", " << (ram.second + 2) << "]";
            if (index < mem_way.rams.size() - 1)
                out << ", ";
            index++;
        }
        out  << "]" << std::endl;
        // ATCAM tables have only one input xbar way
        if (!use->atcam) ++ixbar_way;
    }
}

/* Generate asm for the hash distribution unit, specifically the unit, group, mask and shift value
   found in each hash dist assembly */
void MauAsmOutput::emit_hash_dist(std::ostream &out, indent_t indent,
        const safe_vector<IXBar::HashDistUse> *hash_dist_use) const {
    if (hash_dist_use == nullptr || hash_dist_use->empty())
        return;
    out << indent++ << "hash_dist:" << std::endl;
    for (auto &hash_dist : *hash_dist_use) {
        for (auto slice : hash_dist.slices) {
            out << indent <<  slice << ": { ";
            out << "hash: " << hash_dist.groups.at(slice);
            if (hash_dist.masks.count(slice) > 0)
                out << ", mask: 0x" << hash_dist.masks.at(slice);
            if (hash_dist.shifts.count(slice) > 0)
                out << ", shift: " << hash_dist.shifts.at(slice);
            if (hash_dist.expand.count(slice) > 0)
                out << ", expand: " << hash_dist.expand.at(slice);
            if (hash_dist.outputs.count(slice)) {
                auto &set = hash_dist.outputs.at(slice);
                if (set.size() > 0) {
                    out << ", output: ";
                    if (set.size() > 1) {
                        const char *sep = "[ ";
                        for (auto el : set) {
                            out << sep << el;
                            sep = ", "; }
                        out << " ]";
                    } else {
                        out << *set.begin(); } } }
            out << " }" << std::endl;
        }
    }
    indent--;
}

/* Determine which bytes of a table's input xbar belong to an individual hash table,
   so that we can output the hash of this individual table. */
void MauAsmOutput::emit_ixbar_hash_table(int hash_table, safe_vector<Slice> &match_data,
        safe_vector<Slice> &ghost, const TableMatch *fmt,
        std::map<int, std::map<int, Slice>> &sort) const {
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
            safe_vector<Slice> reg_ghost;
            safe_vector<Slice> reg_hash = reg.split(fmt->ghost_bits, reg_ghost);
            ghost.insert(ghost.end(), reg_ghost.begin(), reg_ghost.end());
            match_data.insert(match_data.end(), reg_hash.begin(), reg_hash.end());
        } else {
            match_data.emplace_back(reg);
        }
    }
}

/** Emits information on a lower 10 bit portion of a RAM select for exact match
 */
void MauAsmOutput::emit_ixbar_hash_way(std::ostream &out, indent_t indent,
        safe_vector<Slice> &match_data, Slice *ghost, const IXBar::Use *use, int hash_group,
        int start_bit, int end_bit) const {
    unsigned done = 0;
    if (match_data.empty() && ghost == nullptr)
        return;
    for (auto &way : use->way_use) {
        if (way.group != hash_group)
            continue;
        if (done & (1 << way.slice)) continue;
        done |= 1 << way.slice;
        int way_start = way.slice * TableFormat::RAM_GHOST_BITS + start_bit;
        int way_end = way.slice * TableFormat::RAM_GHOST_BITS + end_bit;
        out << indent << way_start;
        if (way_end != way_start)
            out << ".." << way_end;
        out << ": " << FormatHash(&match_data, nullptr, ghost, IR::MAU::hash_function::random())
            << std::endl;
    }
}

/** Emits infomration on the upper 12 bits select porition of a RAM select for exact match
 */
void MauAsmOutput::emit_ixbar_hash_way_select(std::ostream &out, indent_t indent,
        safe_vector<Slice> &match_data, Slice *ghost, int start_bit, int end_bit) const {
    int way_start = TableFormat::RAM_GHOST_BITS * IXBar::HASH_INDEX_GROUPS + start_bit;
    int way_end = TableFormat::RAM_GHOST_BITS * IXBar::HASH_INDEX_GROUPS + end_bit;
    out << indent << way_start;
    if (way_end != way_start)
        out << ".." << way_end;
    out << ": " << FormatHash(&match_data, nullptr, ghost, IR::MAU::hash_function::random())
        << std::endl;
}

/** This function is necessary due to the limits of the driver's handling of ATCAM tables.
 *  The driver requires that the partition index hash be in the same order as the bits
 *  of the partition index.
 *
 *  This will eventually force limitations in the implementation of ATCAM tables, i.e.
 *  multiple fields or potentially a slice being used as the partition index.  The true
 *  way this should be handled is the same way as an exact match table, by generating the
 *  hash from the hash matrix provided to driver.  When this support is provided, this
 *  function becomes unnecessary, and can just go through the same pathway that exact
 *  match goes through.
 */
void MauAsmOutput::emit_ixbar_hash_atcam(std::ostream &out, indent_t indent,
        safe_vector<Slice> &ghost, const IXBar::Use *use, int hash_group) const {
    safe_vector<Slice> empty;
    for (auto ghost_slice : ghost) {
        int start_bit = 0;  int end_bit = 0;
        if (ghost_slice.get_lo() >= TableFormat::RAM_GHOST_BITS)
            continue;
        start_bit = ghost_slice.get_lo();
        Slice adapted_ghost = ghost_slice;
        if (ghost_slice.get_hi() < TableFormat::RAM_GHOST_BITS) {
            end_bit = ghost_slice.get_hi();
        } else {
            int diff = ghost_slice.get_hi() - TableFormat::RAM_GHOST_BITS + 1;
            end_bit = TableFormat::RAM_GHOST_BITS - 1;
            adapted_ghost.shrink_hi(diff);
        }
        emit_ixbar_hash_way(out, indent, empty, &adapted_ghost, use, hash_group, start_bit,
                            end_bit);
    }

    unsigned mask_bits = 0;
    for (auto way : use->way_use) {
        if (way.group != hash_group)
            continue;
        mask_bits |= way.mask;
    }

    auto bv = bitvec(mask_bits);
    BUG_CHECK(bv.is_contiguous() || bv.empty(), "Unsupported non-contiguous select mask for "
                                                "ATCAM table");

    for (auto ghost_slice : ghost) {
        int start_bit = 0;  int end_bit = 0;
        if (ghost_slice.get_hi() < TableFormat::RAM_GHOST_BITS)
            continue;

        int max_point = TableFormat::RAM_GHOST_BITS + bv.popcount() - ghost_slice.get_hi();
        end_bit = bv.max().index() - max_point + 1;
        start_bit = bv.min().index();
        Slice adapted_ghost = ghost_slice;
        if (ghost_slice.get_lo() >= TableFormat::RAM_GHOST_BITS) {
            start_bit += ghost_slice.get_lo() - TableFormat::RAM_GHOST_BITS;
        } else {
            int diff = TableFormat::RAM_GHOST_BITS - ghost_slice.get_lo();
            adapted_ghost.shrink_lo(diff);
        }
        emit_ixbar_hash_way_select(out, indent, empty, &adapted_ghost, start_bit, end_bit);
    }
}

/** The purpose of this code is to output the hash matrix specifically for exact tables.
 *  This code classifies all of the ghost bits for this particular hash table.  The ghost bits
 *  are the bits that appear in the hash but not in the table format.  This reduces the
 *  number of bits actually needed to match against.
 *
 *  The ghost bits themselves are spread through an identity hash, while the bits that appear
 *  in the match are randomized.  Thus each ghost bit is assigned a corresponding bit in the
 *  way bits or select bits within the match format.
 *
 *  The hash matrix is specified on a hash table by hash table basis.  16 x 64b hash tables
 *  at most are specified, and if the ghost bits do not appear in that particular hash table,
 *  they will not be output.  The ident_bits_prev_alloc is used to track how where to start
 *  the identity of the ghost bits within this particular hash table.
 */
void MauAsmOutput::emit_ixbar_hash_exact(std::ostream &out, indent_t indent,
        safe_vector<Slice> &match_data, safe_vector<Slice> &ghost, const IXBar::Use *use,
        int hash_group, int &ident_bits_prev_alloc) const {
    // FIXME: See comments above this function, but should be unnecessary
    if (use->atcam) {
        emit_ixbar_hash_atcam(out, indent, ghost, use, hash_group);
        return;
    }

    // Do not specify identity ghost bits at places where ghost bits are already specified
    if (ident_bits_prev_alloc > 0) {
        int prev_alloc = std::min(ident_bits_prev_alloc - 1, TableFormat::RAM_GHOST_BITS - 1);
        emit_ixbar_hash_way(out, indent, match_data, nullptr, use, hash_group, 0,
                            prev_alloc);
    }

    safe_vector<Slice> way_ghost;
    safe_vector<Slice> select_ghost;

    // Classify which ghost bits are going in the lower 10 bits, and the upper select bits
    int ident_bits_alloc = 0;
    for (auto ghost_slice : ghost) {
        int start_bit = ident_bits_prev_alloc + ident_bits_alloc;
        if (start_bit >= TableFormat::RAM_GHOST_BITS) {
            select_ghost.push_back(ghost_slice);
        } else if (start_bit + ghost_slice.width() <= TableFormat::RAM_GHOST_BITS) {
            way_ghost.push_back(ghost_slice);
        } else {
            int diff = TableFormat::RAM_GHOST_BITS - start_bit - 1;
            auto way_slice = ghost_slice(0, diff);
            way_ghost.push_back(way_slice);
            select_ghost.push_back(ghost_slice - way_slice);
        }
        ident_bits_alloc += ghost_slice.width();
    }

    // Handle the ghost bits that are in the lower 10 bits of the hash way
    int bits_allocated = 0;
    for (auto ghost_slice : way_ghost) {
        int start_bit = ident_bits_prev_alloc + bits_allocated;
        int end_bit = start_bit + ghost_slice.width() - 1;
        emit_ixbar_hash_way(out, indent, match_data, &ghost_slice, use, hash_group, start_bit,
                            end_bit);
        bits_allocated += ghost_slice.width();
    }

    // Select bits for each way.  Due to an optimization, select bits can be shared between
    // ways if more than 4 ways are actually required.  This makes sure that the ghost bits
    // for those align appropriately
    bitvec total_ghost_mask;
    // If there aren't enough ghost bits to even reach the select bits
    if (ident_bits_alloc + ident_bits_prev_alloc < TableFormat::RAM_GHOST_BITS) {
        int start_bit = ident_bits_alloc + ident_bits_prev_alloc;
        int end_bit = TableFormat::RAM_GHOST_BITS - 1;
        emit_ixbar_hash_way(out, indent, match_data, nullptr, use, hash_group, start_bit, end_bit);
    } else if (ident_bits_alloc + ident_bits_prev_alloc > TableFormat::RAM_GHOST_BITS) {
        bits_allocated = 0;
        bitvec ghost_slice_mask;
        for (auto ghost_slice : select_ghost) {
            ghost_slice_mask.clear();
            int select_bits = ghost_slice.width();
            int offset = std::max(ident_bits_prev_alloc, int(TableFormat::RAM_GHOST_BITS));
            offset += bits_allocated - TableFormat::RAM_GHOST_BITS;
            bitvec bit_mask(offset, select_bits);
            for (auto way : use->way_use) {
                if (way.group != hash_group)
                    continue;
                bitvec way_mask;
                way_mask.setraw(way.mask);
                bitvec select_ghost_mask = (bit_mask << way_mask.ffs()) & way_mask;

                // Check to make sure that shared ghosted select bits between ways still are
                // correctly aligned
                if ((select_ghost_mask & total_ghost_mask).popcount() != 0) {
                    BUG_CHECK((select_ghost_mask & total_ghost_mask).popcount() == select_bits,
                          "Select mask for a way sharing the select bits is not correctly set up");
                    BUG_CHECK((select_ghost_mask & total_ghost_mask)
                              == (select_ghost_mask & ghost_slice_mask), "Select mask for bits "
                             "collide with a different ghost slice select portion");
                    continue;
                }
                total_ghost_mask |= select_ghost_mask;
                ghost_slice_mask |= select_ghost_mask;
                int start_bit = select_ghost_mask.min().index();
                int end_bit = select_ghost_mask.max().index();
                emit_ixbar_hash_way_select(out, indent, match_data, &ghost_slice, start_bit,
                                           end_bit);
            }
            bits_allocated += select_bits;
        }
    }
    ident_bits_prev_alloc += ident_bits_alloc;

    // For all holes in the upper 12 bits that don't have a corresponding select bit
    if (match_data.size() == 0)
        return;
    unsigned mask_bits = 0;
    for (auto way : use->way_use) {
        if (way.group != hash_group)
            continue;
        mask_bits |= way.mask;
    }
    bitvec select_range = (bitvec(mask_bits) - total_ghost_mask);
    for (auto range : bitranges(select_range.getrange(0, IXBar::HASH_SINGLE_BITS))) {
        emit_ixbar_hash_way_select(out, indent, match_data, nullptr, range.first, range.second);
    }
}

/** Given a bitrange to allocate into the ixbar hash matrix, as well as a list of fields to
 *  be the identity, this coordinates the field slice to a portion of the bit range.  This
 *  really only applies for identity matches.
 */
void MauAsmOutput::emit_ixbar_hash_dist_ident(std::ostream &out, indent_t indent,
        safe_vector<Slice> &match_data, const IXBar::Use::HashDistHash &hdh,
        const IR::Expression *hd_expr) const {
    for (auto &sl : match_data) {
        int slice_bits_seen = 0;
        if (auto le = hd_expr->to<IR::ListExpression>()) {
            for (auto expr : le->components) {
                auto field = phv.field(expr);
                if (field == sl.get_field()) {
                    break;
                }
                slice_bits_seen += field->size;
            }
        }

        int sl_lo = sl.get_lo() + slice_bits_seen;
        int sl_hi = sl.get_hi() + slice_bits_seen;
        auto bv = bitvec(hdh.bit_mask);
        int start_bit = bv.ffs();
        while (start_bit >= 0) {
            int end_bit = bv.ffz(start_bit);
            for (auto position : hdh.bit_starts) {
                if (!(position.first >= start_bit && position.first < end_bit))
                    continue;
                auto br = position.second;
                int hash_lo = position.first;
                int hash_hi = position.first + br.size() - 1;

                // Is slice outside of the bitrange
                if (br.hi < sl_lo || br.lo > sl_hi)
                    continue;

                // Shrink slice and bitrange until they are the same size
                auto adapted_sl = sl;
                if (sl_lo < br.lo)
                    adapted_sl.shrink_lo(br.lo - sl_lo);
                else
                    hash_lo += (sl_lo - br.lo);
                if (sl_hi > br.hi)
                    adapted_sl.shrink_hi(sl_hi - br.hi);
                else
                    hash_hi -= br.hi - sl_hi;

                safe_vector<Slice> ident_slice;
                ident_slice.push_back(adapted_sl);

                out << indent << hash_lo << ".." << hash_hi;
                out << ": " << FormatHash(&ident_slice, nullptr, nullptr,
                                          IR::MAU::hash_function::identity())
                    << std::endl;
            }
            start_bit = bv.ffs(end_bit);
        }
    }
}

void MauAsmOutput::emit_ixbar_meter_alu_hash(std::ostream &out, indent_t indent,
        safe_vector<Slice> &match_data, const IXBar::Use::MeterAluHash &mah,
        const safe_vector<PHV::FieldSlice> &field_list_order) const {
    if (mah.algorithm.type == IR::MAU::hash_function::IDENTITY) {
        for (auto &slice : match_data) {
            if (mah.identity_positions.count(slice.get_field()) == 0)
                continue;
            auto &pos_vec = mah.identity_positions.at(slice.get_field());
            for (auto &pos : pos_vec) {
                auto boost_sl = toClosedRange<RangeUnit::Bit, Endian::Little>
                                    (pos.field_range.intersectWith(slice.range()));
                if (boost_sl == boost::none)
                    continue;
                le_bitrange slice_bits = *boost_sl;
                safe_vector<Slice> single_match_vec;
                int start_bit = pos.hash_start + (slice_bits.lo - pos.field_range.lo);
                int end_bit = start_bit + slice_bits.size() - 1;
                single_match_vec.emplace_back(slice.get_field(), slice_bits);
                out << indent << start_bit << ".." << end_bit << ": "
                    << FormatHash(&single_match_vec, nullptr, nullptr, mah.algorithm)
                    << std::endl;
            }
        }
    } else {
        le_bitrange br = { mah.bit_mask.min().index(), mah.bit_mask.max().index() };
        int total_bits = 0;
        std::map<int, Slice> match_data_map;
        bool use_map = false;
        if (mah.algorithm.ordered) {
            emit_ixbar_gather_map(match_data_map, match_data, field_list_order, total_bits);
            use_map = true;
        }
        out << indent << br.lo << ".." << br.hi << ": ";
        if (use_map)
            out << FormatHash(nullptr, &match_data_map, nullptr, mah.algorithm, total_bits, &br);
        else
            out << FormatHash(&match_data, nullptr, nullptr, mah.algorithm, total_bits, &br);
        out << std::endl;
    }
}

/** Given an order for an allocation, will determine the input position of the slice in
 *  the allocation, and save it in the match_data_map
 *
 *  FIXME: Currently does not work on repeated data
 */
void MauAsmOutput::emit_ixbar_gather_map(std::map<int, Slice> &match_data_map,
        safe_vector<Slice> &match_data,
        const safe_vector<PHV::FieldSlice> &field_list_order, int &total_size) const {
    for (auto sl : match_data) {
        int order_bit = 0;
        // Traverse field list in reverse order. For a field list the convention
        // seems to indicate the field offsets are determined based on first
        // field  MSB and last at LSB.
        for (auto fs_itr = field_list_order.rbegin(); fs_itr != field_list_order.rend(); fs_itr++) {
            auto fs = *fs_itr;
            if (fs.field() != sl.get_field()) {
                order_bit += fs.size();
                continue;
            }

            auto half_open_intersect = fs.range().intersectWith(sl.range());
            if (half_open_intersect.empty()) {
                order_bit += fs.size();
                continue;
            }

            le_bitrange intersect = { half_open_intersect.lo, half_open_intersect.hi - 1 };
            Slice adapted_sl = sl;


            int lo_adjust = std::max(intersect.lo - sl.range().lo, sl.range().lo - intersect.lo);
            int hi_adjust = std::max(intersect.hi - sl.range().hi, sl.range().hi - intersect.hi);
            adapted_sl.shrink_lo(lo_adjust);
            adapted_sl.shrink_hi(hi_adjust);
            int offset = adapted_sl.get_lo() - fs.range().lo;
            match_data_map[order_bit + offset] = adapted_sl;
            order_bit += fs.size();
        }
    }

    total_size = 0;
    for (auto fs : field_list_order) {
        total_size += fs.size();
    }
}

/* Generate asm for the hash of a table, specifically either a match, gateway, or selector
   table.  Not used for hash distribution hash */
void MauAsmOutput::emit_ixbar_hash(std::ostream &out, indent_t indent,
                                   safe_vector<Slice> &match_data,
                                   safe_vector<Slice> &ghost,
                                   const IXBar::Use *use, int hash_group,
                                   int &ident_bits_prev_alloc,
                                   const IR::Expression *hd_expr) const {
    if (!use->way_use.empty()) {
        emit_ixbar_hash_exact(out, indent, match_data, ghost, use, hash_group,
                              ident_bits_prev_alloc);
    }

    if (use->meter_alu_hash.allocated) {
        emit_ixbar_meter_alu_hash(out, indent, match_data, use->meter_alu_hash,
                                  use->field_list_order);
    }


    // Printing out the hash for gateway tables
    for (auto ident : use->bit_use) {
        // Gateway fields in the hash are continuous bitranges currently, must
        // match up with the fields
        Slice range_sl(phv, ident.field, ident.lo, ident.lo + ident.width - 1);
        for (auto sl : match_data) {
            if (sl.get_field()->name != ident.field)
                continue;
            if (range_sl.get_hi() < sl.get_lo() || range_sl.get_lo() > sl.get_hi())
                continue;

            int extra_start = std::max(0, sl.get_lo() - range_sl.get_lo());
            auto adapted_sl = sl;
            if (auto diff = (range_sl.get_lo() - sl.get_lo()) > 0)
                adapted_sl.shrink_lo(diff);
            if (auto diff = (sl.get_hi() - range_sl.get_hi()) > 0)
                adapted_sl.shrink_hi(diff);


            out << indent << (40 + ident.bit + extra_start);
            if (ident.width > 1)
                out << ".." << (40 + ident.bit + extra_start + adapted_sl.width() - 1);
            out << ": " << adapted_sl << std:: endl;
            assert(hash_group == -1 || hash_group == ident.group);
        }
    }

    if (use->hash_dist_hash.allocated) {
        auto &hdh = use->hash_dist_hash;
        if (hdh.algorithm.type == IR::MAU::hash_function::IDENTITY) {
            emit_ixbar_hash_dist_ident(out, indent, match_data, hdh, hd_expr);
            return;
        }

        std::map<int, Slice> match_data_map;
        bool use_map = false;
        int total_bits = 0;
        if (hdh.algorithm.ordered) {
            emit_ixbar_gather_map(match_data_map, match_data, use->field_list_order, total_bits);
            use_map = true;
        }

        for (auto bit_start : hdh.bit_starts) {
            int start_bit = bit_start.first;
            le_bitrange br = bit_start.second;
            int end_bit = start_bit + br.size() - 1;
            out << indent << start_bit << ".." << end_bit;
            if (use_map)
                out << ": " << FormatHash(nullptr, &match_data_map, nullptr, hdh.algorithm,
                                          total_bits, &br);
            else
                out << ": " << FormatHash(&match_data, nullptr, nullptr, hdh.algorithm,
                                          total_bits, &br);
            out << std::endl;
        }

        /*
        for (int i = 0, sliceIdx = 0; i < IXBar::HASH_DIST_SLICES; i++) {
            if (((1 << i) & hdh.slice) == 0) continue;
            int first_bit = -1;
            int last_bit = -1;
            bool first_bit_found = false;
            bool last_bit_found = false;
            for (int j = i * IXBar::HASH_DIST_BITS; j < (i + 1) * IXBar::HASH_DIST_BITS; j++) {
                if (!first_bit_found) {
                    if (((UINT64_C(1) << j) & hdh.bit_mask)) {
                        first_bit_found = true;
                        first_bit = j;
                    }
                    continue;
                }
                if (((UINT64_C(1) << j) & hdh.bit_mask) == 0 && !last_bit_found) {
                    last_bit_found = true;
                    last_bit = j - 1;
                }
                if (((UINT64_C(1) << j) & hdh.bit_mask) != 0 && last_bit_found) {
                    BUG("Split in address bits for hash distribution");
                }
            }
            if (last_bit == -1)
                last_bit = (i + 1) * IXBar::HASH_DIST_BITS - 1;
            out << indent << first_bit << ".." << last_bit;
            out << ": " << FormatHash(&match_data, nullptr, nullptr, hdh.algorithm) << std::endl;
            sliceIdx++;
        }
        */
    }
}

void MauAsmOutput::emit_single_ixbar(std::ostream &out, indent_t indent, const IXBar::Use *use,
        const TableMatch *fmt, const IR::Expression *hd_expr) const {
    std::map<int, std::map<int, Slice>> sort;
    std::map<int, std::map<int, Slice>> midbytes;
    emit_ixbar_gather_bytes(use->use, sort, midbytes, use->ternary);
    cstring group_type = use->ternary ? "ternary" : "exact";
    for (auto &group : sort)
        out << indent << group_type << " group " << group.first << ": "
                      << group.second << std::endl;
    for (auto &midbyte : midbytes)
        out << indent << "byte group " << midbyte.first << ": " << midbyte.second << std::endl;
    if (use->atcam) {
        sort.clear();
        midbytes.clear();
        emit_ixbar_gather_bytes(use->use, sort, midbytes, use->ternary, use->atcam);
    }
    for (int hash_group = 0; hash_group < IXBar::HASH_GROUPS; hash_group++) {
        unsigned hash_table_input = use->hash_table_inputs[hash_group];
        int ident_bits_prev_alloc = 0;
        if (hash_table_input) {
            for (int ht : bitvec(hash_table_input)) {
                out << indent++ << "hash " << ht << ":" << std::endl;
                safe_vector<Slice> match_data;
                safe_vector<Slice> ghost;
                emit_ixbar_hash_table(ht, match_data, ghost, fmt, sort);
                // FIXME: This is obviously an issue for larger selector tables,
                //  whole function needs to be replaced
                emit_ixbar_hash(out, indent, match_data, ghost, use, hash_group,
                                ident_bits_prev_alloc, hd_expr);
                --indent;
            }
            out << indent++ << "hash group " << hash_group << ":" << std::endl;
            out << indent << "table: [" << emit_vector(bitvec(hash_table_input), ", ") << "]"
                << std::endl;
            out << indent << "seed: 0x" << use->hash_seed[hash_group] << std::endl;
            --indent;
        }
    }
}

/* Emit the ixbar use for a particular type of table */
void MauAsmOutput::emit_ixbar(std::ostream &out, indent_t indent, const IXBar::Use *use,
                              const safe_vector<IXBar::HashDistUse> *hash_dist_use,
                              const Memories::Use *mem,
                              const TableMatch *fmt, bool ternary) const {
    if (!ternary) {
        emit_ways(out, indent, use, mem);
        emit_hash_dist(out, indent, hash_dist_use); }
    if ((use == nullptr || use->use.empty())
        && (hash_dist_use == nullptr || hash_dist_use->empty())) {
        return;
    }
    if (ternary && use && !use->ternary) return;
    out << indent++ << "input_xbar:" << std::endl;
    if (use) {
        emit_single_ixbar(out, indent, use, fmt);
    }

    if (hash_dist_use) {
        for (auto &hash_dist : *hash_dist_use) {
            emit_single_ixbar(out, indent, &(hash_dist.use), nullptr,
                              hash_dist.original_hd->field_list);
        }
    }

    if (fmt && fmt->table && fmt->table->random_seed != -1) {
        out << indent++ << "random_seed:" << fmt->table->random_seed << std::endl;
    }
}

class memory_vector {
    const safe_vector<int>     &vec;
    Memories::Use::type_t       type;
    bool                        is_mapcol;
    friend std::ostream &operator<<(std::ostream &, const memory_vector &);
 public:
    memory_vector(const safe_vector<int> &v, Memories::Use::type_t t, bool ism)
      : vec(v), type(t), is_mapcol(ism) {}
};

std::ostream &operator<<(std::ostream &out, const memory_vector &v) {
    if (v.vec.size() != 1) out << "[ ";
    const char *sep = "";

    int col_adjust = (v.type == Memories::Use::TERNARY  ||
                      v.type == Memories::Use::IDLETIME || v.is_mapcol)  ? 0 : 2;
    bool logical = v.type >= Memories::Use::COUNTER;
    int col_mod = logical ? 6 : 12;
    for (auto c : v.vec) {
        out << sep << (c + col_adjust) % col_mod;
        sep = ", "; }
    if (v.vec.size() != 1) out << " ]";
    return out;
}

void MauAsmOutput::emit_memory(std::ostream &out, indent_t indent, const Memories::Use &mem) const {
    safe_vector<int> row, bus, home_row, word;
    bool logical = mem.type >= Memories::Use::COUNTER;
    bool have_bus = !logical;
    bool have_mapcol = mem.is_twoport();
    bool have_col = false;
    bool have_word = mem.type == Memories::Use::ACTIONDATA;
    bool have_vpn = have_word;

    for (auto &r : mem.row) {
        if (logical) {
            row.push_back(2*r.row + (r.col[0] >= Memories::LEFT_SIDE_COLUMNS));
            have_col = true;
        } else {
            row.push_back(r.row);
            bus.push_back(r.bus);
            if (r.bus < 0) have_bus = false;
            if (r.col.size() > 0) have_col = true;
        }

        if (have_word)
            word.push_back(r.word);
    }

    if (row.size() > 1) {
        out << indent << "row: " << row << std::endl;
        if (have_bus) out << indent << "bus: " << bus << std::endl;
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

    } else {
        out << indent << "row: " << row[0] << std::endl;
        if (have_bus) out << indent << "bus: " << bus[0] << std::endl;
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
        safe_vector<int> color_mapram_row, color_mapram_bus;
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
              const safe_vector<std::pair<int, int>> &bits) {
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
    if (type == TableFormat::NEXT)
        return "next";
    if (type == TableFormat::ACTION)
        return "action";
    if (type == TableFormat::IMMEDIATE)
        return "immediate";
    if (type == TableFormat::VERS)
        return "version";
    if (type == TableFormat::COUNTER)
        return "counter_addr";
    if (type == TableFormat::COUNTER_PFE)
        return "counter_pfe";
    if (type == TableFormat::METER)
        return "meter_addr";
    if (type == TableFormat::METER_PFE)
        return "meter_pfe";
    if (type == TableFormat::METER_TYPE)
        return "meter_type";
    if (type == TableFormat::INDIRECT_ACTION)
        return "action_addr";
    return "";
}

void MauAsmOutput::emit_action_data_bus(std::ostream &out, indent_t indent,
        const IR::MAU::Table *tbl, bool immediate) const {
    auto &action_data_xbar = tbl->resources->action_data_xbar;
    auto &use = tbl->resources->action_format;
    size_t max_total = 0;
    for (auto &rs : action_data_xbar.action_data_locs) {
        if (rs.immediate == immediate)
            max_total++;
    }
    if (max_total == 0)
        return;


    out << indent << "action_bus: { ";
    size_t total_index = 0;
    for (auto &rs : action_data_xbar.action_data_locs) {
        if (immediate != rs.immediate) continue;
        bitvec total_range(0, ActionFormat::CONTAINER_SIZES[rs.location.type]);
        int byte_sz = ActionFormat::CONTAINER_SIZES[rs.location.type] / 8;
        out << rs.location.byte;
        if (byte_sz > 1)
            out << ".." << (rs.location.byte + byte_sz - 1);
        out << " : ";

        const IR::MAU::HashDist *hd = nullptr;
        const IR::MAU::RandomNumber *rn = nullptr;
        int lo = -1; int hi = -1;
        // For emitting hash distribution sections on the action_bus directly.  Must find
        // which slices of hash distribution are to go to which bytes, requiring coordination
        // from the input xbar and action format allocation
        if (immediate && use.is_hash_dist(rs.byte_offset, &hd, lo, hi)) {
            const IXBar::HashDistUse *hd_use = nullptr;
            auto &hash_dist_uses = tbl->resources->hash_dists;
            for (auto &hash_dist_use : hash_dist_uses) {
                if (hd == hash_dist_use.original_hd) {
                    hd_use = &hash_dist_use;
                    break;
                }
            }
            BUG_CHECK(hd_use != nullptr, "Could not find hash distribution unit in link up "
                                         "of tables");
            safe_vector<int> units;
            BUG_CHECK(hd_use->slices.size() <= 2, "Currently do not support more than 2 units "
                      "of hash distribution per table");
            le_bitrange field_range = { lo, hi };
            le_bitrange hd_range = { 0, 0 };
            int section = -1;
            safe_vector<int> unit_indexes = use.find_hash_dist(hd, field_range, false, hd_range,
                                                               section);
            for (auto unit_index : unit_indexes)
                units.push_back(hd_use->slices[unit_index]);

            out << "hash_dist(";
            size_t unit_index = 0;
            for (auto unit : units) {
                out << unit;
                if (unit_index != units.size() - 1)
                    out << ", ";
                unit_index++;
            }
            if (hd_range.size() != IXBar::HASH_DIST_BITS) {
                out << ", " << hd_range.lo << ".." << hd_range.hi;
            }
            // 16 bit hash dist in a 32 bit slot have to determine whether the hash distribution
            // unit goes in the lo section or the hi section
            if (section >= 0) {
                cstring lo_hi = section == 0 ? "lo" : "hi";
                out << ", " << lo_hi;
            }
            out << ")";
        } else if (immediate && use.is_rand_num(rs.byte_offset, &rn)) {
            auto rng_use = action_data_xbar.rng_locs.at(rn);
            out << "rng(" << rng_use.unit << ", ";
            int lo = (rs.location.byte * 8) % 8;
            int hi = lo + byte_sz * 8 - 1;
            out << lo << ".." << hi << ")";
        } else if (use.is_meter_color(rs.byte_offset, rs.immediate)) {
            for (auto back_at : tbl->attached) {
                auto at = back_at->attached;
                auto *mtr = at->to<IR::MAU::Meter>();
                if (mtr == nullptr) continue;
                out << tbl->unique_id(mtr) << " color";
                break;
            }
        } else {
            out << use.get_format_name(rs.byte_offset, rs.location.type, rs.immediate,
                                                total_range, false);
        }
        if (total_index != max_total - 1)
            out << ", ";
        else
            out << " ";
        total_index++;
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
        safe_vector<std::pair<int, int>> bits;
        // For table objects that are not match
        for (type = TableFormat::NEXT; type <= TableFormat::INDIRECT_ACTION; type++) {
            if (match_group.mask[type].popcount() == 0) continue;
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
                    start = start_bit;
                    end = end_bit - 1;
                }
                start_bit = byte_layout.ffs(end_bit);
            } while (start_bit != -1);
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
        if (tcam_use.group != -1)
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
        for (auto call : act->stateful_calls) {
            auto prim = call->prim;
            auto *at = prim->operands.at(0)->to<IR::GlobalRef>()->obj
                       ->to<IR::MAU::AttachedMemory>();
            if (call->index == nullptr) continue;
            if (auto aa = call->index->to<IR::MAU::ActionArg>()) {
                alias[aa->name] = self.indirect_address(at);
            }
        }
        auto &instr_mem = table->resources->instr_mem;
        out << indent << canon_name(act->externalName());
        auto &vliw_instr = instr_mem.all_instrs.at(act->name.name);
        out << "(" << vliw_instr.mem_code << ", " << vliw_instr.gen_addr() << "):" << std::endl;
        action_context_json(act);
        out << indent << "- default_" << (act->miss_action_only ? "only_" : "") << "action: {"
            << " allowed: " << std::boolalpha << (act->default_allowed || act->hit_path_imp_only);
        if (!act->default_allowed || act->hit_path_imp_only)
            out << ", reason: " << act->disallowed_reason;
        out << " }" << std::endl;
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
        // Dumping the information on stateful calls.  For anything that has a meter type,
        // the meter type is dumped first, followed by the address location.  This is
        // required to generate override_full_.*_addr information
        for (auto call : act->stateful_calls) {
            auto prim = call->prim;
            auto *at = prim->operands.at(0)->to<IR::GlobalRef>()
                           ->obj->to<IR::MAU::AttachedMemory>();
            out << indent << "- " << self.find_attached_name(table, at) << '(';
            sep = "";
            // Currently dumps meter type as number, because the color aware stuff does not
            // have a name
            if (act->meter_types.count(at->unique_id()) > 0) {
                IR::MAU::MeterType type = act->meter_types.at(at->unique_id());
                out << static_cast<int>(type);
                sep = ", "; }
            BUG_CHECK((call->index == nullptr) == at->direct, "%s Indexing scheme doesn't match up "
                      "for %s", at->srcInfo, at->name);
            if (call->index != nullptr) {
                if (auto *k = call->index->to<IR::Constant>()) {
                    out << sep << k->value;
                    sep = ", ";
                } else if (auto *a = call->index->to<IR::MAU::ActionArg>()) {
                    out << sep << a->name;
                    sep = ", ";
                } else if (call->index->is<IR::MAU::HashDist>()) {
                    out << sep << "$hash_dist";
                    sep = ", ";
                } else if (call->index->is<IR::MAU::StatefulCounter>()) {
                    out << sep << "$stful_counter";
                    sep = ", ";
                } else {
                    BUG("%s: Index for %s is not supported", at->srcInfo, at->name);
                }
            } else {
                out << sep << "$DIRECT";
                sep = ", ";
            }
            out << ')' << std::endl;
            is_empty = false;
        }
        return false; }
    bool preorder(const IR::MAU::SaluAction *act) override {
        out << indent << canon_name(act->name) << ":" << std::endl;
        is_empty = true;
        return true; }
    void postorder(const IR::MAU::Action *) override {
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
            le_bitrange bits;
            if (auto field = self.phv.field(expr, &bits)) {
                out << sep << canon_name(field->externalName());
                int count = 0;
                field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &) {
                    count++;
                });
                if (count == 1) {
                    bool single_loc = (field->get_alloc().size() == 1);
                    field->foreach_alloc([&](const PHV::Field::alloc_slice &alloc) {
                        if (!(alloc.field_bit <= bits.lo && alloc.field_hi() >= bits.hi))
                            return;
                        if (!single_loc)
                            out << "." << alloc.field_bit << "-" << alloc.field_hi();
                        if (bits.lo > alloc.field_bit || bits.hi < alloc.field_hi())
                            out << "(" << bits.lo - alloc.field_bit << ".." <<
                                          bits.hi - alloc.field_bit  << ")";
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

    /** In order to handle slices on hash distribution, i.e. a 8 bit portion of a 16
     *  bit hash distribution unit, the assumption is that the hash distribution is aligned
     *  at 16 bit intervals, and that the slicing is coordinated to that.  Until the hash
     *  distribution is moved into the action format, then this assumption will have
     *  to work.
     */
    void handle_hash_dist(const IR::Expression *expr) {
        int lo = -1; int hi = -1;
        const IR::MAU::HashDist *hd = nullptr;
        if (auto sl = expr->to<IR::Slice>()) {
            hd = sl->e0->to<IR::MAU::HashDist>();
            lo = sl->getL();
            hi = sl->getH();
        } else {
            hd = expr->to<IR::MAU::HashDist>();
            lo = 0;
            hi = hd->type->width_bits();
        }
        assert(sep);
        BUG_CHECK(hd != nullptr, "Printing an invalid the hash distribution in assembly");
        out << sep << "hash_dist(";
        sep = "";
        const IXBar::HashDistUse *hd_use = nullptr;
        auto &hash_dist_uses = table->resources->hash_dists;
        for (auto &hash_dist_use : hash_dist_uses) {
            if (hd == hash_dist_use.original_hd) {
                hd_use = &hash_dist_use;
                break;
            }
        }

        BUG_CHECK(hd_use != nullptr, "Could not find hash distribution unit in link up of tables");
        safe_vector<int> units;

        int section = -1;
        le_bitrange field_range = { lo, hi };
        le_bitrange hd_range = { 0, 0 };
        auto af = table->resources->action_format;
        safe_vector<int> unit_indexes = af.find_hash_dist(hd, field_range, true, hd_range,
                                                          section);
        for (auto unit_index : unit_indexes) {
            units.push_back(hd_use->slices[unit_index]);
        }


        for (size_t i = 0; i < units.size(); i++) {
            out << units[i];
            if (i != units.size() - 1)
                out << ", ";
        }
        out << ", " << hd_range.lo << ".." << hd_range.hi;
        out << ")";
        sep = ", ";
    }


    void handle_random_number(const IR::Expression *expr) {
        int lo = -1;  int hi = -1;
        const IR::MAU::RandomNumber *rn = nullptr;
        if (auto sl = expr->to<IR::Slice>()) {
            rn = sl->e0->to<IR::MAU::RandomNumber>();
            lo = sl->getL();
            hi = sl->getH();
        } else {
            rn = expr->to<IR::MAU::RandomNumber>();
            lo = 0;
            hi = rn->type->width_bits() - 1;
        }
        assert(sep);
        BUG_CHECK(rn != nullptr, "Printing an invalid random number in the assembly");
        out << sep << "rng(";
        auto unit = table->resources->action_data_xbar.rng_locs.at(rn).unit;
        out << unit << ", ";
        auto af = table->resources->action_format;
        int rng_lo = -1;  int rng_hi = -1;
        af.find_rand_num(rn, lo, hi, rng_lo, rng_hi);
        out << rng_lo << ".." << rng_hi << ")";
        sep = ", ";
    }

    bool preorder(const IR::Slice *sl) override {
        assert(sep);
        if (self.phv.field(sl)) {
            handle_phv_expr(sl);
            return false;
        } else if (sl->e0->is<IR::MAU::HashDist>()) {
            handle_hash_dist(sl);
            return false;
        } else if (sl->e0->is<IR::MAU::RandomNumber>()) {
            handle_random_number(sl);
        }
        visit(sl->e0);
        if (sl->e0->is<IR::MAU::ActionArg>()) {
            out << "." << sl->getL() << "-" << sl->getH();
        } else {
            out << "(" << sl->getL() << ".." << sl->getH() << ")";
        }
        return false;
    }

    bool preorder(const IR::MAU::WrappedSlice *sl) override {
        assert(sep);
        auto mo = sl->e0->to<IR::MAU::MultiOperand>();
        visit(mo);
        out << "(" << sl->getL() << ")";
        return false;
    }

    bool preorder(const IR::Constant *c) override {
        assert(sep);
        out << sep << c->value;
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
    bool preorder(const IR::MAU::ActionArg *a) override {
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
        out << sep << self.find_attached_name(table, att->attached);
        if (auto mtr = att->attached->to<IR::MAU::Meter>()) {
            if (mtr->color_output())
                out << " color";
        }
        sep = ", ";
        return false; }
    bool preorder(const IR::Member *m) override {
        if (m->expr->is<IR::MAU::AttachedOutput>()) {
            visit(m->expr, "expr");
            out << " " << m->member;
            return false;
        } else {
            return preorder(static_cast<const IR::Expression *>(m)); } }
    bool preorder(const IR::MAU::HashDist *hd) override {
        handle_hash_dist(hd);
        return false; }
    bool preorder(const IR::MAU::RandomNumber *rn) override {
        handle_random_number(rn);
        return false;
    }
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
    bool preorder(const IR::BAnd *e) override { return preorder_binop(e, " & "); }
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

        safe_vector<Slice> single_byte_match_fields;
        for (auto fi : byte.field_bytes) {
            bitvec cont_loc = fi.cont_loc();
            bitvec layout_shifted
                = byte_layout.getslice(byte_layout.min().index() / 8 * 8, 8);

            int lo = fi.lo;
            int hi = fi.hi;

            bitvec matched_bits = layout_shifted & cont_loc;
            // If a byte is partially ghosted, then currently the bits from the lsb are
            // ghosted so the algorithm always shrinks from the bottom
            if (matched_bits.empty()) {
                continue;
            } else if (matched_bits != cont_loc) {
                lo += (matched_bits.min().index() - cont_loc.min().index());
            }
            Slice sl(phv, fi.get_use_name(), lo, hi);

            if (sl.bytealign() != (matched_bits.min().index() % 8))
                BUG("Byte alignment for matching does not match up properly");
            single_byte_match_fields.push_back(sl);
        }

        std::sort(single_byte_match_fields.begin(), single_byte_match_fields.end(),
            [](const Slice &a, const Slice &b) {
            return a.bytealign() < b.bytealign();
        });

        match_fields.insert(match_fields.end(), single_byte_match_fields.begin(),
                            single_byte_match_fields.end());
    }

    // Determine which bytes are part of the ghosting bits.  Again like the match info,
    // whichever bits are ghosted must be handled in a particular way if the byte is partially
    // matched and partially ghosted
    for (auto ghost_info : tbl->resources->table_format.ghost_bits) {
        const IXBar::Use::Byte &byte = ghost_info.first;
        const bitvec &byte_layout = ghost_info.second;

        for (auto fi : byte.field_bytes) {
            bitvec cont_loc = fi.cont_loc();
            bitvec layout_shifted
                = byte_layout.getslice(byte_layout.min().index() / 8 * 8, 8);

            int lo = fi.lo;
            int hi = fi.hi;

            bitvec ghosted_bits = layout_shifted & cont_loc;
            if (ghosted_bits.empty())
                continue;
            else if (ghosted_bits != cont_loc)
                hi -= (cont_loc.max().index() - ghosted_bits.max().index());
            Slice sl(phv, fi.get_use_name(), lo, hi);
            if (sl.bytealign() != (ghosted_bits.min().index() % 8))
                BUG("Byte alignment for ghosting does not match up properly");
            ghost_bits.push_back(sl);
        }
    }
    /* Store the table pointer handy in case we need to write the seed */
    table = tbl;

    // Link match data together for an easier to read asm
    /*
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
    */
}

static cstring next_for(const IR::MAU::Table *tbl, cstring what, const DefaultNext &def) {
    if (what == "$miss") {
        cstring tns = "$try_next_stage";
        if (tbl->next.count(tns)) {
            if (!tbl->next.at(tns)->empty())
                return tbl->next.at(tns)->front()->unique_id().build_name();
        }
    }
    if (tbl->next.count(what)) {
        if (tbl->next.at(what) && !tbl->next.at(what)->empty())
            return tbl->next.at(what)->front()->unique_id().build_name();
    } else if (tbl->next.count("$default")) {
        if (!tbl->next.at("$default")->empty())
            return tbl->next.at("$default")->front()->unique_id().build_name();
    }
    return def.next_in_thread(tbl);
}

/** Gateways in Tofino are 4 44 bit TCAM rows used to compare conditionals.  A comparison will
 *  be done on a row by row basis.  If that row hits, then the gateway matches on that particular
 *  row.  Lastly all gateways have a miss row, which will automatically match if the none of the
 *  programmed gateway rows match
 *
 *  Gateways rows have the following structure:
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
            if (!f.second.xor_offsets.empty())
                have_xor = true;
            for (auto &offset : f.second.offsets) {
                f.first->foreach_alloc(offset.second, [&](const PHV::Field::alloc_slice &sl) {
                    out << sep << (offset.first + (sl.field_bit - offset.second.lo));
                    out << ": " << Slice(f.first, sl.field_bits());
                    sep = ", ";
                });
            }
        }
        out << (sep+1) << "}" << std::endl;
        if (have_xor) {
            out << gw_indent << "xor: {";
            sep = " ";
            for (auto &f : collect.info) {
                for (auto &offset : f.second.xor_offsets) {
                    f.first->foreach_alloc(offset.second, [&](const PHV::Field::alloc_slice &sl) {
                        out << sep << (offset.first + (sl.field_bit - offset.second.lo));
                        out << ": " << Slice(f.first, sl.field_bits());
                        sep = ", ";
                    });
                }
            }
            out << (sep+1) << "}" << std::endl;
        }
        if (collect.need_range)
            out << gw_indent << "range: 4" << std::endl;
        BuildGatewayMatch match(phv, collect);
        std::map<cstring, cstring> cond_tables;
        for (auto &line : tbl->gateway_rows) {
            out << gw_indent;
            if (line.first) {
                line.first->apply(match);
                out << match << ": ";
            } else {
                out << "miss: ";
            }
            cstring nxt_tbl;
            if (line.second) {
                if (no_match) {
                    out << "run_table";
                    gw_miss = nxt_tbl = next_for(tbl, line.second, default_next);
                } else {
                    nxt_tbl = next_for(tbl, line.second, default_next);
                    out << next_for(tbl, line.second, default_next);
                }
            } else {
                if (no_match) {
                    out << next_hit;
                    nxt_tbl = next_hit;
                } else {
                    out << "run_table";
                    nxt_tbl = tbl->unique_id().build_name();
                }
            }
            out << std::endl;
            bool split_gateway = (line.second == "$gwcont");
            auto cond = (line.second.isNullOrEmpty() || split_gateway) ?
                "$torf" : line.second;
            cond_tables[cond] = nxt_tbl;
        }
        if (tbl->gateway_rows.back().first) {
            out << gw_indent << "miss: run_table" << std::endl;
        }
        out << gw_indent++ << "condition: " << std::endl;
        out << gw_indent << "expression: \"(" << tbl->gateway_cond << ")\"" << std::endl;
        out << gw_indent << "true: "
            << (cond_tables.count("$true") ? cond_tables["$true"] : cond_tables["$torf"])
            << std::endl;
        out << gw_indent << "false: "
            << (cond_tables.count("$false") ? cond_tables["$false"] : cond_tables["$torf"])
            << std::endl;
    } else {
        WARNING("Failed to fit gateway expression for " << tbl->name);
    }
}

/** This allocates a gateway that always hits, in order for the table to always go through the
 *  the hit pathway.
 */
void MauAsmOutput::emit_no_match_gateway(std::ostream &out, indent_t gw_indent,
        const IR::MAU::Table *tbl) const {
    auto nxt_tbl = next_for(tbl, "", default_next);
    out << gw_indent << "0x0: " << nxt_tbl << std::endl;
    out << gw_indent << "miss: " << nxt_tbl << std::endl;
    out << gw_indent++ << "condition: " << std::endl;
    out << gw_indent << "expression: \"true(always hit)\"" << std::endl;
    out << gw_indent << "true: " << nxt_tbl << std::endl;
    out << gw_indent << "false: " << nxt_tbl << std::endl;
}

void MauAsmOutput::emit_table_context_json(std::ostream &out, indent_t indent,
        const IR::MAU::Table *tbl) const {
    out << indent << "p4: { name: " << canon_name(tbl->match_table->externalName());
    if (auto k = tbl->match_table->getConstantProperty("size"))
        out << ", size: " << k->asInt();
    if (tbl->layout.pre_classifier || tbl->layout.alpm)
        out << ", match_type: alpm";
    for (auto back_at : tbl->attached) {
        auto at = back_at->attached;
        if (auto ap = at->to<IR::MAU::ActionData>())
            if (!ap->direct)
                out << ", action_profile: " << canon_name(ap->name);
    }
    // Output 'disable_atomic_modify' pragma if present. This will to be plugged
    // into the context json for the driver. COMPILER-944
    if (auto m = tbl->match_table) {
        for (auto annot : m->annotations->annotations)
            if (annot->name == "disable_atomic_modify"
                    && annot->expr.size() > 0
                    && annot->expr[0]->to<IR::Constant>()->asInt() == 1)
                out << ", disable_atomic_modify : true";
    }
    out << " }" << std::endl;

    if (tbl->match_key.empty())
        return;

    out << indent++ <<  "p4_param_order: " << std::endl;
    int p4_param_index = 0;
    for (auto ixbar_read : tbl->match_key) {
        if (!ixbar_read->for_match())
            continue;
        if (p4_param_index != ixbar_read->p4_param_order) continue;
        auto *expr = ixbar_read->expr;
        if (ixbar_read->from_mask && expr->to<IR::Slice>())
                expr = expr->to<IR::Slice>()->e0;
        // Replace any alias nodes with their original sources, in order to
        // ensure the original names are emitted.
                auto full_size = phv.field(expr)->size;

        // Check for @name annotation.
        cstring name = phv.field(expr)->externalName();

        cstring annName = "";
        std::map<int, int> slices;
        if (auto ann = ixbar_read->getAnnotation(IR::Annotation::nameAnnotation)) {
            annName = IR::Annotation::getName(ann);

            // P4_14-->P4_16 translation names valid matches with a
            // "$valid$" suffix (note the trailing "$").  However, Brig
            // and pdgen use "$valid".
            if (annName.endsWith("$valid$"))
                annName = annName.substr(0, annName.size() - 1);

            // XXX(cole): This is a hack to remove slices from key annName annotations,
            // eg. "foo.bar[3:0]" becomes "foo.bar".
            std::string s(annName.c_str());
            std::smatch sm;
            std::regex sliceRegex(R"(\[([0-9]+):([0-9]+)\])");
            std::regex_search(s, sm, sliceRegex);
            if (sm.size() == 3) {
                auto newAnnName = s.substr(0, sm.position(0));
                // XXX(cole): It would be nice to report srcInfo here.
                ::warning("Table key name not supported.  "
                          "Replacing \"%1%\" with \"%2%\".", annName, newAnnName);
                annName = newAnnName;
                auto start = std::stol(sm[2]);
                auto end = std::stol(sm[1]);
                slices[start] = end - start + 1;
            }

            // XXX(cole): This is a hack to remove mask syntax from key names.
            // This is specifically a problem because
            //
            //   1. P4_14-->P4_16 translation replaces `field mask val :
            //      exact` with `field & val : exact` match keys in some
            //      cases.
            //   2. The front end automatically adds @name annotations to
            //      match keys (if not supplied by the user) converting the
            //      key to a string literal, eg. @name("field & val").
            //   3. However, PD generation/etc. expects @name("field"),
            //      not @name("field & val"), for P4_14 programs.
            //
            // Hence, we remove the trailing " & val".  However, this mean
            // P4_16 programmers can't use that syntax either.
            s = annName.c_str();
            sliceRegex = std::regex(R"( & (.*$))");
            std::regex_search(s, sm, sliceRegex);
            if (sm.size() == 2) {
                auto newAnnName = s.substr(0, sm.position(0));
                auto mask = std::stol(sm[1]);
                if (mask == 0)
                    ::error("Field mask cannot be zero - "
                            "Field: \"%1%\" - Table: \"%2%\"",
                            s, tbl->name);
                // XXX(cole): It would be nice to report srcInfo here.
                ::warning("Table key name syntax not supported.  "
                          "Replacing \"%1%\" with \"%2%\".", annName, newAnnName);
                annName = newAnnName;
                // Get slice(s) out of the mask value. Each slice is a separate
                // entry in p4_param_order
                bitvec m(mask);
                auto start = 0;
                while (start >= 0) {
                    start = m.ffs(start);
                    if (start >= 0) {
                        auto end = m.ffz(start) - 1;
                        slices[start] = end - start + 1;
                        start = end + 1;
                    }
                }
            }
            LOG3(ann << ": setting external annName of key " << ixbar_read
                 << " to " << annName);
        }

        // If fields dont have slices we add the entire field starting at bit 0
        if (slices.empty())
            slices[0] = full_size;

        for (auto sl : slices) {
            out << indent << canon_name(name) << ": ";
            out << "{ type: " << ixbar_read->match_type.name << ", ";
            out << "size: " << sl.second << ", ";
            out << "full_size: " << full_size;
            if (!annName.isNullOrEmpty() && annName.find('.'))
                out << ", key_name: \"" << canon_name(annName) << "\"";
            // Output start bit only for slices
            if (sl.second != full_size) out << ", start_bit: " << sl.first;
            out << " }" << std::endl;
        }

        p4_param_index++;
    }
    if (tbl->dynamic_key_masks)
        out << --indent << "dynamic_key_masks: true" << std::endl;
}

void MauAsmOutput::emit_static_entries(std::ostream &out, indent_t indent,
        const IR::MAU::Table *tbl) const {
    if (tbl->entries_list == nullptr)
        return;

    for (auto k : tbl->match_key) {
        if (k->match_type.name != "exact")
            P4C_UNIMPLEMENTED("Static entries are only supported for exact-match tables");
    }

    out << indent++ << "static_entries:" << std::endl;
    for (auto entry : tbl->entries_list->entries) {
        auto method_call = entry->action->to<IR::MethodCallExpression>();
        BUG_CHECK(method_call, "Action is not specified for a static entry");

        auto path = method_call->method->to<IR::PathExpression>()->path;
        size_t key_index = 0, param_index = 0;
        out << indent++ << "- priority: 0" << std::endl;
        out << indent << "match_key_fields_values: [";
        for (auto key : entry->getKeys()->components) {
            if (auto b = key->to<IR::BoolLiteral>()) {
                out << (b->value ? 1 : 0);
            } else if (key->to<IR::Constant>()) {
                out << key;
            } else {
                P4C_UNIMPLEMENTED("Static entries are only supported for match keys with "
                        "bit-string type");
            }

            if (key_index++ < entry->getKeys()->components.size() - 1)
                out << ", ";
        }
        out << "]" << std::endl;

        for (auto action : Values(tbl->actions)) {
            if (action->name.name == path->name) {
                out << indent << "action: " << canon_name(action->externalName()) << std::endl;
                break;
            }
        }

        out << indent << "is_default_entry: false" <<  std::endl;
        if (method_call->arguments->size() > 0) {
            out << indent << "action_parameters_values: [";
            for (auto param : *method_call->arguments) {
                out << param;
                if (param_index++ < method_call->arguments->size() - 1)
                    out << ", ";
            }
            out << "]" << std::endl;
        }
        indent--;
    }
}

void MauAsmOutput::emit_atcam_match(std::ostream &out, indent_t indent,
        const IR::MAU::Table *tbl) const {
    out << indent << "number_partitions: "
        << tbl->layout.partition_count << std::endl;
    if (tbl->layout.alpm)
        out << indent << "subtrees_per_partition: "
            << tbl->layout.subtrees_per_partition << std::endl;
    for (auto ixr : tbl->match_key) {
        if (ixr->partition_index) {
            out << indent << "partition_field_name: " <<
                canon_name(phv.field(ixr->expr)->externalName()) << std::endl;
            break;
        }
    }
}

void MauAsmOutput::emit_table(std::ostream &out, const IR::MAU::Table *tbl, int stage,
       gress_t gress) const {
    /* FIXME -- some of this should be method(s) in IR::MAU::Table? */
    auto unique_id = tbl->unique_id();
    LOG1("Emitting table " << unique_id);
    TableMatch fmt(*this, phv, tbl);
    const char *tbl_type = "gateway";
    indent_t    indent(1);
    bool no_match_hit = tbl->layout.no_match_hit_path() && !tbl->gateway_only();
    if (!tbl->gateway_only())
        tbl_type = tbl->layout.ternary || tbl->layout.no_match_miss_path()
                   ? "ternary_match" : "exact_match";
    if (no_match_hit)
        tbl_type = "hash_action";
    if (tbl->layout.atcam)
        tbl_type = "atcam_match";
    out << indent++ << tbl_type << ' ' << unique_id << ' ' << tbl->logical_id % 16U
        << ':' << std::endl;
    if (!tbl->gateway_only()) {
        emit_table_context_json(out, indent, tbl);
        if (!tbl->layout.no_match_miss_path()) {
            emit_memory(out, indent, tbl->resources->memuse.at(unique_id));
            emit_ixbar(out, indent, &tbl->resources->match_ixbar, &tbl->resources->hash_dists,
                       &tbl->resources->memuse.at(unique_id), &fmt, tbl->layout.ternary);
        }
        if (!tbl->layout.ternary && !tbl->layout.no_match_data()) {
            emit_table_format(out, indent, tbl->resources->table_format, &fmt, false);
        }

        if (tbl->layout.ternary)
            emit_ternary_match(out, indent, tbl->resources->table_format);

        if (tbl->layout.atcam)
            emit_atcam_match(out, indent, tbl);
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
        auto gateway_name = tbl->gateway_name.isNullOrEmpty() ? tbl->name : tbl->gateway_name;
        out << gw_indent << "name: " <<  gateway_name << std::endl;
        emit_ixbar(out, gw_indent, &tbl->resources->gateway_ixbar, nullptr, nullptr, &fmt, false);
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
        if (tbl->uses_gateway()) {
            out << "END";
            sep = ", ";
        }
        for (auto act : Values(tbl->actions)) {
            if (act->miss_action_only) continue;
            out << sep << next_for(tbl, act->name.originalName, default_next);
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

    emit_static_entries(out, indent, tbl);

    if (!tbl->layout.ternary && !tbl->layout.no_match_miss_path())
        emit_action_data_bus(out, indent, tbl, true);

    /* FIXME -- this is a mess and needs to be rewritten to be sane */
    bool have_action = false, have_indirect = false;
    for (auto back_at : tbl->attached) {
        auto at = back_at->attached;
        if (auto *ti = at->to<IR::MAU::TernaryIndirect>()) {
            have_indirect = true;
            auto unique_id = tbl->unique_id(ti);
            out << indent << at->kind() << ": " << unique_id << std::endl;
        } else if (auto ad = at->to<IR::MAU::ActionData>()) {
            bool ad_check = tbl->layout.action_data_bytes_in_table > 0;
            ad_check |= tbl->layout.action_addr_bits > 0;
            BUG_CHECK(ad_check, "Action Data Table %s misconfigured", ad->name);
            have_action = true; } }
    assert(have_indirect == (tbl->layout.ternary || tbl->layout.no_match_miss_path()));
    BUG_CHECK(have_action || tbl->layout.action_data_bytes_in_table == 0,
              "have action data with no action data table?");

    if (!have_indirect)
        emit_table_indir(out, indent, tbl);

    const IR::MAU::IdleTime* idletime = nullptr;
    for (auto back_at : tbl->attached) {
        auto at = back_at->attached;
        if (auto *id = at->to<IR::MAU::IdleTime>()) {
            idletime = id;
            break;
        }
    }
    if (idletime)
        emit_idletime(out, indent, tbl, idletime);

    for (auto back_at : tbl->attached)
        back_at->apply(EmitAttached(*this, out, tbl, stage, gress));
}

/**
 * Indirect address type.  Will eventually have to pull in action data
 */
std::string MauAsmOutput::indirect_address(const IR::MAU::AttachedMemory *am) const {
    if (am->is<IR::MAU::Counter>())
        return "counter_addr";
    if (am->is<IR::MAU::Selector>() || am->is<IR::MAU::Meter>() || am->is<IR::MAU::StatefulAlu>())
        return "meter_addr";
    BUG("Should not reach this point in indirect address");
    return "";
}

std::string MauAsmOutput::indirect_pfe(const IR::MAU::AttachedMemory *am) const {
    if (am->is<IR::MAU::Counter>())
        return "counter_pfe";
    if (am->is<IR::MAU::Selector>() || am->is<IR::MAU::Meter>() || am->is<IR::MAU::StatefulAlu>())
        return "meter_pfe";
    BUG("Should not reach this point in indirect pfe");
    return "";
}

std::string MauAsmOutput::stateful_counter_addr(IR::MAU::StatefulUse use) const {
    switch (use) {
        case IR::MAU::StatefulUse::LOG: return "counter";
        case IR::MAU::StatefulUse::FIFO_PUSH: return "fifo push";
        case IR::MAU::StatefulUse::FIFO_POP: return "fifo pop";
        case IR::MAU::StatefulUse::STACK_PUSH: return "stack push";
        case IR::MAU::StatefulUse::STACK_POP: return "stack pop";
        default: return "";
    }
}


/** Figure out which overhead field in the table is being used to index an attached
 *  indirect table (counter, meter, stateful, action data) and return its asm name.  Contained
 *  now within the actual IR for Hash Distribution.
 *
 *  Addressed are built up of up to 3 arguments:
 *      - address position - the location of the address bits
 *      - pfe position - the location of the per flow enable bit
 *      - type position - the location of the meter type
 *
 *  With this come some keywords:
 *      1. $DIRECT - The table is directly addressed
 *      2. $DEFAULT - the parameter is defaulted on through the default register
 */
std::string MauAsmOutput::build_call(const IR::MAU::AttachedMemory *at_mem,
       const IR::MAU::BackendAttached *ba, const IR::MAU::Table *tbl) const {
    if (at_mem->is<IR::MAU::ActionData>()) {
        if (!at_mem->direct)
            return "(action, action_addr)";
        else
            return "";
    } else if (at_mem->is<IR::MAU::IdleTime>()) {
        return "";
    }

    std::string rv = "(";

    if (ba->addr_location == IR::MAU::AddrLocation::DIRECT) {
        rv += "$DIRECT";
    } else if (ba->addr_location == IR::MAU::AddrLocation::OVERHEAD) {
        rv += indirect_address(at_mem);
    } else if (ba->addr_location == IR::MAU::AddrLocation::HASH) {
        BUG_CHECK(ba->hash_dist, "Hash Dist not allocated correctly");
        auto hash_dist_uses = tbl->resources->hash_dists;
        const IXBar::HashDistUse *hd_use = nullptr;
        for (auto &hash_dist_use : hash_dist_uses) {
            if (ba->hash_dist == hash_dist_use.original_hd) {
                hd_use = &hash_dist_use;
                break;
            }
        }
        BUG_CHECK(hd_use != nullptr, "No associated hash distribution group for an address");
        rv += "hash_dist " + std::to_string(hd_use->slices[0]);
    } else if (ba->addr_location == IR::MAU::AddrLocation::STFUL_COUNTER) {
        rv += stateful_counter_addr(ba->use);
    }

    rv += ", ";
    if (ba->pfe_location == IR::MAU::PfeLocation::OVERHEAD) {
        rv += indirect_pfe(at_mem);
    } else if (ba->pfe_location == IR::MAU::PfeLocation::DEFAULT) {
        rv += "$DEFAULT";
    }

    if (!at_mem->unique_id().has_meter_type())
        return rv + ")";

    rv += ", ";
    if (ba->type_location == IR::MAU::TypeLocation::OVERHEAD) {
        rv += "meter_type";
    } else if (ba->type_location == IR::MAU::TypeLocation::DEFAULT) {
        rv += "$DEFAULT";
    }
    return rv + ")";
}

cstring MauAsmOutput::find_attached_name(const IR::MAU::Table *tbl,
        const IR::MAU::AttachedMemory *at) const {
    auto unique_id = tbl->unique_id();
    auto at_unique_id = tbl->unique_id(at);
    auto &memuse = tbl->resources->memuse.at(unique_id);

    auto unattached_pos = memuse.unattached_tables.find(at_unique_id);
    if (unattached_pos == memuse.unattached_tables.end())
         return at_unique_id.build_name();
    else
         return unattached_pos->second.build_name();
}

void MauAsmOutput::emit_table_indir(std::ostream &out, indent_t indent,
                                    const IR::MAU::Table *tbl) const {
    bool have_action = false;
    for (auto back_at : tbl->attached) {
        auto at_mem = back_at->attached;
        if (at_mem->is<IR::MAU::TernaryIndirect>()) continue;
        if (at_mem->is<IR::MAU::IdleTime>()) continue;  // XXX(zma) idletime is inlined
        if (at_mem->is<IR::MAU::ActionData>()) {
            have_action = true;
        }
        out << indent << at_mem->kind() << ": ";
        out << find_attached_name(tbl, at_mem);
        out << build_call(at_mem, back_at, tbl);
        out << std::endl;
    }

    if (!have_action && !tbl->actions.empty()) {
        out << indent++ << "actions:" << std::endl;
        for (auto act : Values(tbl->actions)) {
            act->apply(EmitAction(*this, out, tbl, indent));
        }
        --indent;
    }

    if (!tbl->gateway_only()) {
        bool found_def_act = false;
        for (auto act : Values(tbl->actions)) {
            if (!act->init_default) continue;
            found_def_act = true;
            out << indent << "default_" << (act->miss_action_only ? "only_" : "") << "action: "
                << canon_name(act->externalName()) << std::endl;
            if (act->default_params.size() == 0)
                break;
            BUG_CHECK(act->default_params.size() == act->args.size(), "Wrong number of params "
                      "to default action %s", act->name);
            out << indent++ << "default_action_parameters:" << std::endl;
            int index = 0;
            for (auto param : act->default_params) {
                out << indent << act->args[index++]->name << ": " << param << std::endl;
            }
            indent--;
            break;
        }
        if (!found_def_act)
            BUG("No default action found in table %s", tbl->name);
    }
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

/** This ensures that the attached table is output one time, as the memory allocation is stored
 *  with one table alone.
 */
bool MauAsmOutput::EmitAttached::is_unattached(const IR::MAU::AttachedMemory *at) {
    auto unique_id = tbl->unique_id();
    auto &memuse = tbl->resources->memuse.at(unique_id);
    auto at_unique_id = tbl->unique_id(at);
    auto unattached_loc = memuse.unattached_tables.find(at_unique_id);
    if (unattached_loc != memuse.unattached_tables.end())
        return true;
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::Counter *counter) {
    indent_t indent(1);
    if (is_unattached(counter))
        return false;
    auto unique_id = tbl->unique_id(counter);
    out << indent++ << "counter " << unique_id << ":" << std::endl;
    out << indent << "p4: { name: " << canon_name(counter->name)
                      << ", size: " << counter->size
                      << " }" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(unique_id));
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
    int per_row = CounterPerWord(counter);
    counter_format(out, counter->type, per_row);
    out << "}" << std::endl;
    // FIXME: Eventually should not be necessary due to DRV-1856
    auto *ba = findContext<IR::MAU::BackendAttached>();
    if (ba->pfe_location == IR::MAU::PfeLocation::OVERHEAD)
        out << indent << "per_flow_enable: " << "counter_pfe" << std::endl;
    if (counter->threshold != -1) {
        out << indent << "lrt: { threshold: " << counter->threshold <<
             ", interval: " << counter->interval << " }" << std::endl;
    }
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::Meter *meter) {
    indent_t indent(1);
    if (is_unattached(meter))
        return false;

    auto unique_id = tbl->unique_id(meter);
    out << indent++ << "meter " << unique_id << ":" << std::endl;
    out << indent << "p4: { name: " << canon_name(meter->name);
    if (!meter->direct)
        out << ", size: " << meter->size;
    out << " }" << std::endl;
    if (meter->input)
        self.emit_ixbar(out, indent, &tbl->resources->meter_ixbar, nullptr, nullptr, nullptr,
                        false);
    self.emit_memory(out, indent, tbl->resources->memuse.at(unique_id));
    cstring imp_type;
    if (!meter->implementation.name)
        imp_type = "standard";
    else
        imp_type = meter->implementation.name;
    out << indent << "type: " << imp_type << std::endl;
    if (imp_type == "wred") {
        out << indent << "red_output: { ";
        out << " drop: " << meter->red_drop_value;
        out << " , nodrop: " << meter->red_nodrop_value;
        out << " } " << std::endl;
    }

    if (meter->pre_color) {
        const IXBar::HashDistUse *hd_use = nullptr;
        for (auto &hash_dist_use : tbl->resources->hash_dists) {
            if (meter->pre_color == hash_dist_use.original_hd) {
                hd_use = &hash_dist_use;
                break;
            }
        }
        BUG_CHECK(hd_use != nullptr, "Could not find hash distribution unit in link up "
                                     "for meter precolor");
        out << indent << "pre_color: hash_dist(";
        int lo = hd_use->use.hash_dist_hash.bit_mask.min().index() % IXBar::HASH_DIST_BITS;
        int hi = lo + IXBar::METER_PRECOLOR_SIZE - 1;
        out << hd_use->slices[0] << ", " << lo << ".." << hi << ")" << std::endl;
        // FIXME: Eventually should not be necessary due to DRV-1856
        out << indent << "color_aware: true" << std::endl;
    }


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
    if (count_type != "")
        out << indent << "count: " << count_type << std::endl;
    auto *ba = findContext<IR::MAU::BackendAttached>();
    // FIXME: Eventually should not be necessary due to DRV-1856
    if (ba->pfe_location == IR::MAU::PfeLocation::OVERHEAD)
        out << indent << "per_flow_enable: " << "meter_pfe" << std::endl;
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::Selector *as) {
    indent_t indent(1);
    if (is_unattached(as)) {
        return false;
    }
    auto unique_id = tbl->unique_id(as);

    out << indent++ << "selection " << unique_id << ":" << std::endl;
    out << indent << "p4: { name: " << canon_name(as->name);
    if (!as->direct && as->size != 0)
        out << ", size: " << as->size;
    out << " }" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(unique_id));
    self.emit_ixbar(out, indent, &tbl->resources->selector_ixbar,
                    nullptr, nullptr, nullptr, false);
    out << indent << "mode: " << (as->mode ? as->mode.name : "fair") << " 0" << std::endl;
    // out << indent << "per_flow_enable: " << "meter_pfe" << std::endl;
    // FIXME: Currently outputting default values for now, these must be brought through
    // either the tofino native definitions or pragmas
    out << indent << "non_linear: true" << std::endl;
    out << indent << "pool_sizes: [" << as->group_size << "]" << std::endl;
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::TernaryIndirect *ti) {
    indent_t    indent(1);
    auto unique_id = tbl->unique_id(ti);
    out << indent++ << "ternary_indirect " << unique_id << ':' << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(unique_id));
    self.emit_ixbar(out, indent, &tbl->resources->match_ixbar, &tbl->resources->hash_dists,
                    nullptr, nullptr, false);
    self.emit_table_format(out, indent, tbl->resources->table_format, nullptr, true);
    self.emit_action_data_bus(out, indent, tbl, true);
    self.emit_table_indir(out, indent, tbl);
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::ActionData *ad) {
    indent_t    indent(1);
    if (is_unattached(ad))
        return false;

    auto unique_id = tbl->unique_id(ad);
    out << indent++ << "action " << unique_id << ':' << std::endl;
    out << indent << "p4: { name: " << canon_name(ad->name);
    if (!ad->direct)
        out << ", size: " << ad->size;
    out << " }" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(unique_id));
    for (auto act : Values(tbl->actions)) {
        // if (act->args.empty()) continue;
        self.emit_action_data_format(out, indent, tbl, act);
    }
    self.emit_action_data_bus(out, indent, tbl, false);
    if (!tbl->actions.empty()) {
        out << indent++ << "actions:" << std::endl;
        for (auto act : Values(tbl->actions))
            act->apply(EmitAction(self, out, tbl, indent));
        --indent; }
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::StatefulAlu *salu) {
    indent_t    indent(1);
    if (is_unattached(salu))
        return false;

    auto unique_id = tbl->unique_id(salu);
    out << indent++ << "stateful " << unique_id << ':' << std::endl;
    out << indent << "p4: { name: " << canon_name(salu->name);
    if (!salu->direct)
        out << ", size: " << salu->size;
    out << " }" << std::endl;
    if (salu->selector)
        self.emit_memory(out, indent, *self.selector_memory.at(salu->selector));
    else
        self.emit_memory(out, indent, tbl->resources->memuse.at(unique_id));
    self.emit_ixbar(out, indent, &tbl->resources->salu_ixbar, nullptr, nullptr, nullptr, false);
    out << indent << "format: { lo: ";
    if (salu->dual)
        out << salu->width/2 << ", hi:" << salu->width/2;
    else
        out << salu->width;
    out << " }" << std::endl;

    // Write out the table the selector points to
    /* iterate on the "attached" vector on all the tables in the current gress and stage until
     * we find the salu->selector we are looking for */
    if (salu->selector) {
        const IR::MAU::Table *seltbl = nullptr;
        auto ti = self.by_stage.find(std::make_pair(gress, stage));
        if (ti != self.by_stage.end()) {
            for (auto itbl : ti->second) {
                for (auto at : itbl.tableInfo->attached) {
                    auto at_mem = at->attached;
                    if (at_mem == salu->selector) {
                        seltbl = itbl.tableInfo;
                        break;
                    }
                    if (seltbl) break;
                }
                if (seltbl) break;
            }
        }
        if (!seltbl) {
            BUG("SALU Selector Table %s not found in stage %d with table %s", salu->selector->name,
                stage, tbl->name);
        } else {
            out << indent << "selection_table: " << seltbl->unique_id(salu->selector)
              << std::endl;
        }
    }

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
    if (salu->overflow) out << indent << "overflow: " << salu->overflow << std::endl;
    if (salu->underflow) out << indent << "underflow: " << salu->underflow << std::endl;
    if (!salu->instruction.empty()) {
        out << indent++ << "actions:" << std::endl;
        for (auto act : Values(salu->instruction))
            act->apply(EmitAction(self, out, tbl, indent));
        --indent; }

    auto &memuse = tbl->resources->memuse.at(unique_id);
    if (!memuse.dleft_learn.empty() || !memuse.dleft_match.empty()) {
        out << indent++ << "sbus:" << std::endl;
        if (!memuse.dleft_learn.empty())
            out << indent << "learn: [" << emit_vector(memuse.dleft_learn) << "]" << std::endl;
        if (!memuse.dleft_match.empty())
            out << indent << "match: [" << emit_vector(memuse.dleft_match) << "]" << std::endl;
        --indent; }

    if (salu->chain_vpn) {
        out << indent << "offset_vpn: true" << std::endl;
        auto *back_at = getParent<IR::MAU::BackendAttached>();
        // if the address comes from hash_dist, we'll have allocated it with
        // IXBar::Use::METER_ADR_AND_IMMEDIATE, so need to use meter_adr_shift
        // see IXBar::XBarHashDist::initialize_hash_dist_unit
        if (back_at->hash_dist)
            out << indent << "address_shift: " << ceil_log2(salu->width) << std::endl;
    }
    if (salu->chain_total_size > salu->size)
        out << indent << "log_vpn: 0.." << ((salu->chain_total_size * salu->width >> 17) - 1)
            << std::endl;
    return false;
}

bool MauAsmOutput::emit_idletime(std::ostream &out, indent_t indent, const IR::MAU::Table *tbl,
                                 const IR::MAU::IdleTime *id) const {
    auto unique_id = tbl->unique_id(id);
    out << indent++ << "idletime:" << std::endl;
    emit_memory(out, indent, tbl->resources->memuse.at(unique_id));
    out << indent << "precision: " << id->precision << std::endl;
    out << indent << "sweep_interval: " << id->interval << std::endl;
    out << indent << "notification: " << id->two_way_notification << std::endl;
    out << indent << "per_flow_enable: " << (id->per_flow_idletime ? "true" : "false") << std::endl;
    return false;
}
