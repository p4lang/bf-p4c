#include "bf-p4c/mau/asm_output.h"
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
    for (auto &stage : mauasm.by_stage) {
        out << "stage " << stage.first.second << ' ' << stage.first.first << ':' << std::endl;
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
                                           placement.slot_bits, (placement.arg_locs.size() == 1));
        if (placement.arg_locs.size() == 1 && placement.arg_locs[0].is_constant) {
            out << ", ";
            out << placement.arg_locs[0].get_asm_name();
            out << ": " << placement.arg_locs[0].constant_value;
        }

        if (index == placement_vec.size() - 1 && placement.arg_locs.size() == 1)
            last_entry = true;
        if (!last_entry)
             out << ", ";
        if (placement.arg_locs.size() > 1) {
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
    safe_vector<Slice>          match_data;
    const Slice                 *ghost;
    IR::MAU::hash_function      func;
    FormatHash(const safe_vector<Slice>& md, const Slice *g, IR::MAU::hash_function f)
        : match_data(md), ghost(g), func(f) {}
};

std::ostream &operator<<(std::ostream &out, const FormatHash &hash) {
    if (hash.func.type == IR::MAU::hash_function::IDENTITY) {
        out << "stripe(" << emit_vector(hash.match_data) << ")";
    } else if (hash.func.type == IR::MAU::hash_function::RANDOM) {
        if (!hash.match_data.empty()) {
            out << "random(" << emit_vector(hash.match_data, ", ") << ")";
            if (hash.ghost) out << " ^ ";
        }
        if (hash.ghost) {
            out << *hash.ghost;
        }
    } else if (hash.func.type == IR::MAU::hash_function::CRC) {
        out << "stripe(crc";
        if (hash.func.reverse) out << "_rev";
        out << "(0x" << hex(hash.func.poly) << ", ";
        if (hash.func.init)
            out << "0x" << hex(hash.func.init) << ", ";
        out << emit_vector(hash.match_data, ", ") << ")";
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
                Slice sl(phv, fi.field, fi.lo, fi.hi);
                auto n = midbytes[b.loc.group/2].emplace(sl.bytealign(), sl);
                BUG_CHECK(n.second, "duplicate byte use in ixbar");
            } else {
                Slice sl(phv, fi.field, fi.lo, fi.hi);
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
            out << "hash: " << hash_dist.groups.at(slice) << ", ";
            out << "mask: 0x" << hash_dist.masks.at(slice) << ", ";
            out << "shift: " << hash_dist.shifts.at(slice);
            if (hash_dist.expand.count(slice) > 0)
                out << ", expand: " << hash_dist.expand.at(slice);
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
        out << ": " << FormatHash(match_data, ghost, IR::MAU::hash_function::random()) << std::endl;
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
    out << ": " << FormatHash(match_data, ghost, IR::MAU::hash_function::random()) << std::endl;
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
                out << ": " << FormatHash(ident_slice, nullptr, IR::MAU::hash_function::identity())
                    << std::endl;
            }
            start_bit = bv.ffs(end_bit);
        }
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

    for (auto &select : use->select_use) {
        if (select.mode == "resilient")
            out << indent << "0..50: "
                << FormatHash(match_data, nullptr, select.algorithm) << std::endl;
        else if (select.mode == "fair")
            out << indent << "0..13: "
                << FormatHash(match_data, nullptr, select.algorithm) << std::endl;
        else
            BUG("Unrecognized mode of the action selector");
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

        for (int i = 0, sliceIdx = 0; i < IXBar::HASH_DIST_SLICES; i++) {
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
            if (last_bit == -1)
                last_bit = (i + 1) * IXBar::HASH_DIST_BITS - 1;
            out << indent << first_bit << ".." << last_bit;
            out << ": " << FormatHash(match_data, nullptr, hdh.algorithm) << std::endl;
            sliceIdx++;
        }
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
    int hash_group = 0;
    for (auto hash_table_input : use->hash_table_inputs) {
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
            --indent;
        }
        hash_group++;
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
    safe_vector<int> row, bus, home_row;
    bool logical = mem.type >= Memories::Use::COUNTER;
    bool have_bus = !logical;
    bool have_mapcol = mem.is_twoport();
    bool have_col = false;

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
    }

    if (row.size() > 1) {
        out << indent << "row: " << row << std::endl;
        if (have_bus) out << indent << "bus: " << bus << std::endl;
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

cstring format_name(int type, bool pfe_bit = false) {
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

            int hash_lo = -1; int hash_hi = -1; int section = -1;
            if (rs.location.type == ActionFormat::FULL && hd_use->slices.size() == 2) {
                units.insert(units.end(), hd_use->slices.begin(), hd_use->slices.end());
            } else {
                int unit_index = use.find_hash_dist(hd, lo, hi, hash_lo, hash_hi, section);
                units.push_back(hd_use->slices[unit_index]);
            }

            out << "hash_dist(";
            size_t unit_index = 0;
            for (auto unit : units) {
                out << unit;
                if (unit_index != units.size() - 1)
                    out << ",";
                unit_index++;
            }
            if (hash_lo >= 0 && hash_hi >= 0) {
                out << ", " << hash_lo << ".." << hash_hi;
            }
            // 16 bit hash dist in a 32 bit slot have to determine whether the hash distribution
            // unit goes in the lo section or the hi section
            if (section >= 0) {
                cstring lo_hi = section == 0 ? "lo" : "hi";
                out << ", " << lo_hi;
            }
            out << ")";
        } else if (use.is_meter_color(rs.byte_offset, rs.immediate)) {
            for (auto back_at : tbl->attached) {
                auto at = back_at->attached;
                auto *mtr = at->to<IR::MAU::Meter>();
                if (mtr == nullptr) continue;
                out << tbl->get_use_name(mtr) << " color";
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
        safe_vector<std::pair<int, int>> pfe_bits;
        // For table objects that are not match
        for (type = TableFormat::NEXT; type <= TableFormat::INDIRECT_ACTION; type++) {
            if (match_group.mask[type].popcount() == 0) continue;
            bits.clear();
            pfe_bits.clear();
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
            auto *at = prim->operands.at(0)->to<IR::GlobalRef>()->obj
                       ->to<IR::MAU::AttachedMemory>();
            if (prim->operands.size() < 2) continue;
            if (auto aa = prim->operands.at(1)->to<IR::ActionArg>()) {
                alias[aa->name] = self.find_indirect_index(at, true, nullptr, table); } }
        out << indent << canon_name(act->name) << ":" << std::endl;
        action_context_json(act);
        out << indent << "- default_action: { "
            << " allowed: " << std::boolalpha << act->default_allowed;
            if (!act->default_allowed)
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
        for (auto prim : act->stateful) {
            auto *at = prim->operands.at(0)->to<IR::GlobalRef>()
                           ->obj->to<IR::MAU::AttachedMemory>();
            auto *salu = at->to<IR::MAU::StatefulAlu>();
            if (prim->operands.size() < 2 && (!salu || salu->instruction.size() <= 1)) continue;
            out << indent << "- " << self.find_attached_name(table, at) << '(';
            const char *sep = "";
            if (salu) {
                out << salu->action_map.at(act->name);
                sep = ", "; }
            for (size_t i = 1; i < prim->operands.size(); ++i) {
                // FIXME -- some execute primitives for attached tables have additional
                // FIXME -- arguments that we generally want to ignore here.  Should have removed
                // FIXME -- them earlier when we did whatever we needed to do for them, but for
                // FIXME -- now we just ignore ones that make no sense
                if (auto *k = prim->operands.at(i)->to<IR::Constant>())
                    out << sep << k->value;
                else if (auto *a = prim->operands.at(i)->to<IR::ActionArg>())
                    out << sep << a->name;
                else
                    continue;
                sep = ", "; }
            out << ')' << std::endl;
            is_empty = false; }
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
                out << sep << canon_name(field->externalName());
                int count = 0;
                field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &) {
                    count++;
                });
                if (count == 1) {
                    bool single_loc = (field->alloc_i.size() == 1);
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
        int hash_lo = -1; int hash_hi = -1;
        int section = -1;
        if (lo >= 0 && hi >= 0) {
            auto af = table->resources->action_format;
            int unit_index = af.find_hash_dist(hd, lo, hi, hash_lo, hash_hi, section);
            units.push_back(hd_use->slices[unit_index]);
        } else {
            units.insert(units.end(), hd_use->slices.begin(), hd_use->slices.end());
        }

        for (size_t i = 0; i < units.size(); i++) {
            out << units[i];
            if (i != units.size() - 1)
                out << ", ";
        }

        if (hash_lo >= 0 && hash_hi >= 0) {
            out << ", " << hash_lo << ".." << hash_hi;
        }

        out << ")";
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
        out << sep << self.find_attached_name(table, att->attached);
        if (auto mtr = att->attached->to<IR::MAU::Meter>()) {
            if (mtr->color_output())
                out << " color";
        }
        sep = ", ";
        return false; }
    bool preorder(const IR::MAU::HashDist *hd) override {
        handle_hash_dist(hd);
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

            Slice sl(phv, fi.field, lo, hi);

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
                hi -= (cont_loc.max().index() - ghosted_bits.min().index());
            Slice sl(phv, fi.field, lo, hi);
            if (sl.bytealign() != (ghosted_bits.min().index() % 8))
                BUG("Byte alignment for ghosting does not match up properly");
            ghost_bits.push_back(sl);
        }
    }

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
        out << indent << canon_name(phv.field(expr)->externalName()) << ": ";
        out << "{ type: " << ixbar_read->match_type.name << ", ";
        out << "size: " << expr->type->width_bits() << ", ";
        out << "full_size: " << phv.field(expr)->size << " }" << std::endl;
        p4_param_index++;
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
    LOG1("Emitting table " << tbl->name);
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
    out << indent++ << tbl_type << ' ' << tbl->name << ' ' << tbl->logical_id % 16U << ':'
        << std::endl;
    if (!tbl->gateway_only()) {
        emit_table_context_json(out, indent, tbl);
        auto memuse_name = tbl->get_use_name();
        if (!tbl->layout.no_match_miss_path()) {
            emit_memory(out, indent, tbl->resources->memuse.at(memuse_name));
            emit_ixbar(out, indent, &tbl->resources->match_ixbar, &tbl->resources->hash_dists,
                       &tbl->resources->memuse.at(memuse_name), &fmt, tbl->layout.ternary);
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

    if (!tbl->layout.ternary && !tbl->layout.no_match_miss_path())
        emit_action_data_bus(out, indent, tbl, true);

    /* FIXME -- this is a mess and needs to be rewritten to be sane */
    bool have_action = false, have_indirect = false;
    for (auto back_at : tbl->attached) {
        auto at = back_at->attached;
        if (auto *ti = at->to<IR::MAU::TernaryIndirect>()) {
            have_indirect = true;
            cstring name = tbl->get_use_name(ti);
            out << indent << at->kind() << ": " << name << std::endl;
        } else if (auto ad = at->to<IR::MAU::ActionData>()) {
            bool ad_check = tbl->layout.action_data_bytes_in_table > 0;
            ad_check |= tbl->layout.indirect_action_addr_bits > 0;
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

class MauAsmOutput::UnattachedName : public MauInspector {
    const IR::MAU::Table *comp_table;
    cstring comparison_name;
    cstring return_name;
    const IR::MAU::AttachedMemory *unattached;
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
    explicit UnattachedName(const IR::MAU::Table* ct, cstring cn,
                            const IR::MAU::AttachedMemory *at)
        : comp_table(ct), comparison_name(cn), unattached(at) {}
    cstring name() { return return_name; }
};

/** Figure out which overhead field in the table is being used to index an attached
 *  indirect table (counter, meter, stateful, action data) and return its asm name.  Contained
 *  now within the actual IR for Hash Distribution
 */
std::string MauAsmOutput::find_indirect_index(const IR::MAU::AttachedMemory *at_mem,
        bool index_only, const IR::MAU::HashDist *hd, const IR::MAU::Table *tbl) const {
    if (hd != nullptr) {
        auto hash_dist_uses = tbl->resources->hash_dists;
        const IXBar::HashDistUse *hd_use = nullptr;
        for (auto &hash_dist_use : hash_dist_uses) {
            if (hd == hash_dist_use.original_hd) {
                hd_use = &hash_dist_use;
                break;
            }
        }
        BUG_CHECK(hd_use != nullptr, "No associated hash distribution group for an address");
        return "hash_dist " + std::to_string(hd_use->slices[0]);
    }

    if (at_mem->is<IR::MAU::Counter>()) {
        return "counter_addr";
    } else if (at_mem->is<IR::MAU::Meter>() || at_mem->is<IR::MAU::Selector>()) {
        return "meter_addr";
    } else if (auto salu = at_mem->to<IR::MAU::StatefulAlu>()) {
        if (salu->instruction.size() > 1 && !index_only)
            return "meter_type, meter_addr";
        else
            return "meter_addr";
    } else if (at_mem->is<IR::MAU::ActionData>()) {
        return index_only ? "action_addr" : "action, action_addr";
    } else {
        BUG("unsupported attached table type in find_indirect_index: %s", at_mem);
    }
    return "";
}


cstring MauAsmOutput::find_attached_name(const IR::MAU::Table *tbl,
        const IR::MAU::AttachedMemory *at) const {
    auto match_name = tbl->get_use_name();
    auto &memuse = tbl->resources->memuse.at(match_name);
    auto at_name = tbl->get_use_name(at);

    if (memuse.unattached_tables.count(at_name) > 0) {
        UnattachedName unattached(tbl, memuse.unattached_tables.at(at_name), at);
        pipe->apply(unattached);
        at_name = unattached.name();
    }
    return at_name;
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
        if (at_mem->indexed())
            out << '(' << find_indirect_index(at_mem, false, back_at->hash_dist, tbl) << ')';
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
        out << indent << "default_action: ";
        bool found_def_act = false;
        for (auto act : Values(tbl->actions)) {
            if (!act->init_default) continue;
            found_def_act = true;
            out << canon_name(act->name) << std::endl;
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
    auto match_name = tbl->get_use_name();
    auto &memuse = tbl->resources->memuse.at(match_name);
    auto at_name = tbl->get_use_name(at);
    auto unattached_loc = memuse.unattached_tables.find(at_name);
    if (unattached_loc != memuse.unattached_tables.end())
        return true;
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::Counter *counter) {
    indent_t indent(1);
    if (is_unattached(counter))
        return false;
    auto name = tbl->get_use_name(counter);
    out << indent++ << "counter " << name << ":" << std::endl;
    out << indent << "p4: { name: " << canon_name(counter->name)
                      << ", size: " << counter->size
                      << " }" << std::endl;
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
    if (is_unattached(meter))
        return false;

    auto name = tbl->get_use_name(meter);
    out << indent++ << "meter " << name << ":" << std::endl;
    out << indent << "p4: { name: " << canon_name(meter->name) << " }" << std::endl;
    if (meter->input)
        self.emit_ixbar(out, indent, &tbl->resources->meter_ixbar, nullptr, nullptr, nullptr,
                        false);
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
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
    if (meter->indexed() && !tbl->layout.hash_action)
        out << indent << "per_flow_enable: " << "meter_pfe" << std::endl;
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::Selector *as) {
    indent_t indent(1);
    if (is_unattached(as)) {
        return false;
    }
    cstring name = tbl->get_use_name(as);
    out << indent++ << "selection " << name << ":" << std::endl;
    out << indent << "p4: { name: " << canon_name(as->name) << " }" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
    self.emit_ixbar(out, indent, &tbl->resources->selector_ixbar,
                    nullptr, nullptr, nullptr, false);
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

    auto name = tbl->get_use_name(ad);
    out << indent++ << "action " << name << ':' << std::endl;
    out << indent << "p4: { name: " << canon_name(ad->name);
    if (!ad->direct)
        out << ", size: " << ad->size;
    out << " }" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
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

    auto name = tbl->get_use_name(salu);
    out << indent++ << "stateful " << name << ':' << std::endl;
    out << indent << "p4: { name: " << canon_name(salu->name) << " }" << std::endl;
    if (salu->selector)
        self.emit_memory(out, indent, *self.selector_memory.at(salu->selector));
    else
        self.emit_memory(out, indent, tbl->resources->memuse.at(name));
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
        auto sel = salu->selector->to<IR::MAU::Selector>();
        const IR::MAU::Table *seltbl = nullptr;
        auto ti = self.by_stage.find(std::make_pair(gress, stage));
        if (ti != self.by_stage.end()) {
            for (auto itbl : ti->second) {
                for (auto at : itbl.tableInfo->attached) {
                    auto at_mem = at->attached;
                    if (at_mem == sel) {
                        seltbl = itbl.tableInfo;
                        break;
                    }
                    if (seltbl) break;
                }
                if (seltbl) break;
            }
        }
        if (!seltbl) {
            BUG("SALU Selector Table not found?");
        } else {
            out << indent << "selection_table: " << seltbl->get_use_name(salu->selector)
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
    if (!salu->instruction.empty()) {
        out << indent++ << "actions:" << std::endl;
        for (auto act : Values(salu->instruction))
            act->apply(EmitAction(self, out, tbl, indent));
        --indent; }
    if (salu->indexed() && !tbl->layout.hash_action)
        out << indent << "per_flow_enable: meter_pfe" << std::endl;
    return false;
}

bool MauAsmOutput::emit_idletime(std::ostream &out, indent_t indent, const IR::MAU::Table *tbl,
                                 const IR::MAU::IdleTime *id) const {
    auto name = tbl->get_use_name(id);
    out << indent++ << "idletime:" << std::endl;
    emit_memory(out, indent, tbl->resources->memuse.at(name));
    out << indent << "precision: " << id->precision << std::endl;
    out << indent << "sweep_interval: " << id->interval << std::endl;
    out << indent << "notification: " << id->two_way_notification << std::endl;
    out << indent << "per_flow_enable: " << (id->per_flow_idletime ? "true" : "false") << std::endl;
    return false;
}
