#include <map>
#include <regex>
#include <string>
#include <vector>
#include <iterator>
#include <memory>

#include "action_data_bus.h"
#include "bf-p4c/mau/flatrock/asm_output.h"
#include "boost/range/adaptor/reversed.hpp"
#include "bf-p4c/common/alias.h"
#include "bf-p4c/common/ir_utils.h"
#include "bf-p4c/common/slice.h"
#include "bf-p4c/lib/error_type.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/mau/asm_output.h"
#include "bf-p4c/mau/asm_format_hash.h"
#include "bf-p4c/mau/gateway.h"
#include "bf-p4c/mau/payload_gateway.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/table_format.h"
#include "bf-p4c/mau/tofino/asm_output.h"
#include "bf-p4c/mau/tofino/input_xbar.h"
#include "bf-p4c/parde/asm_output.h"
#include "bf-p4c/mau/jbay_next_table.h"
#include "bf-p4c/parde/phase0.h"
#include "bf-p4c/phv/asm_output.h"
#include "lib/algorithm.h"
#include "lib/bitops.h"
#include "lib/bitrange.h"
#include "lib/hex.h"
#include "lib/indent.h"
#include "lib/stringref.h"

namespace Tofino {

void emit_ixbar_gather_map(const PhvInfo &phv, std::multimap<int, Slice> &match_data_map,
        std::map<le_bitrange, const IR::Constant*> &constant_map,
        const safe_vector<Slice> &match_data,
        const safe_vector<const IR::Expression *> &field_list_order, const LTBitMatrix &sym_keys,
        int &total_size);

class EmitHashExpression : public Inspector {
    const PhvInfo               &phv;
    std::ostream                &out;
    indent_t                    indent;
    int                         bit;
    const safe_vector<Slice>    &match_data;

    bool preorder(const IR::Concat *c) override {
        visit(c->right, "right");
        bit += c->right->type->width_bits();
        visit(c->left, "left");
        return false; }
    bool preorder(const IR::BFN::SignExtend *c) override {
        le_bitrange     bits;
        if (auto *field = phv.field(c->expr, &bits)) {
            Slice f(field, bits);
            int ext = c->type->width_bits() - bits.size();
            out << indent << bit << ".." << (bit + bits.size() - 1) << ": " << f << std::endl
                << indent << (bit + bits.size());
            if (ext > 1) out << ".." << (bit + c->type->width_bits() - 1);
            out << ": stripe(" << Slice(f, bits.size()-1) << ")" << std::endl;
        } else {
            BUG("%s too complex in EmitHashExpression", c);
        }
        return false; }
    bool preorder(const IR::Constant *) override {
        // FIXME -- if the constant is non-zero, it should be included into the 'seed'
        return false; }
    bool preorder(const IR::Expression *e) override {
        le_bitrange     bits;
        if (auto *field = phv.field(e, &bits)) {
            Slice sl(field, bits);
            for (auto match_sl : match_data) {
                auto overlap = sl & match_sl;
                if (!overlap) continue;
                auto bit = this->bit + overlap.get_lo() - sl.get_lo();
                out << indent << bit;
                if (overlap.width() > 1)
                    out << ".." << (bit + overlap.width() - 1);
                out << ": " << overlap << std::endl; }
        } else if (e->is<IR::Slice>()) {
            // allow for slice on HashGenExpression
            return true;
        } else {
            BUG("%s too complex in EmitHashExpression", e);
        }
        return false; }
    bool preorder(const IR::MAU::HashGenExpression *hge) override {
        auto *fl = hge->expr->to<IR::MAU::FieldListExpression>();
        BUG_CHECK(fl, "HashGenExpression not a field list: %s", hge);
        if (hge->algorithm.type == IR::MAU::HashFunction::IDENTITY) {
            // For identity, just output each field individually
            for (auto *el : boost::adaptors::reverse(fl->components)) {
                visit(el, "component");
                bit += el->type->width_bits(); }
            return false; }
        le_bitrange br = { 0, hge->hash_output_width };
        if (auto *sl = getParent<IR::Slice>()) {
            br.lo = sl->getL();
            br.hi = sl->getH(); }
        out << indent << bit << ".." << (bit + br.size() - 1) << ": ";
        safe_vector<const IR::Expression *> field_list_order;
        int total_bits = 0;
        for (auto e : fl->components)
            field_list_order.push_back(e);
        if (hge->algorithm.ordered()) {
            std::multimap<int, Slice> match_data_map;
            std::map<le_bitrange, const IR::Constant*> constant_map;
            LTBitMatrix sym_keys;  // FIXME -- needed?  always empty for now
            emit_ixbar_gather_map(phv, match_data_map, constant_map, match_data,
                                       field_list_order, sym_keys, total_bits);
            out << FormatHash(nullptr, &match_data_map, &constant_map, nullptr,
                              hge->algorithm, total_bits, &br);
        } else {
            // FIXME -- need to set total_bits to something?
            out << FormatHash(&match_data, nullptr, nullptr, nullptr,
                              hge->algorithm, total_bits, &br); }
        out << std::endl;
        return false; }

 public:
    EmitHashExpression(const PhvInfo &phv, std::ostream &out, indent_t indent, int bit,
                       const safe_vector<Slice> &match_data)
    : phv(phv), out(out), indent(indent), bit(bit), match_data(match_data) {}
};

/**
 * This funciton is to emit the match data function associated with an SRAM match table.
 */
void emit_ixbar_match_func(std::ostream &out, indent_t indent,
        safe_vector<Slice> &match_data, Slice *ghost, le_bitrange hash_bits) {
    if (match_data.empty() && ghost == nullptr)
        return;
    out << indent << hash_bits.lo;
    if (hash_bits.size() != 1)
        out << ".." << hash_bits.hi;
    out << ": " << FormatHash(&match_data, nullptr, nullptr, ghost,
                              IR::MAU::HashFunction::random()) << std::endl;
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
void emit_ixbar_hash_atcam(std::ostream &out, indent_t indent,
        safe_vector<Slice> &ghost, const Tofino::IXBar::Use *use, int hash_group) {
    safe_vector<Slice> empty;
    BUG_CHECK(use->way_use.size() == 1, "One and only one way necessary for ATCAM tables");
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

        le_bitrange hash_bits = { start_bit, end_bit };
        hash_bits = hash_bits.shiftedByBits(use->way_use[0].slice * IXBar::RAM_LINE_SELECT_BITS);
        emit_ixbar_match_func(out, indent, empty, &adapted_ghost, hash_bits);
    }

    unsigned mask_bits = 0;
    for (auto way : use->way_use) {
        if (way.group != hash_group)
            continue;
        mask_bits |= way.mask;
    }

    for (auto ghost_slice : ghost) {
        // int start_bit = 0;  int end_bit = 0;
        if (ghost_slice.get_hi() < TableFormat::RAM_GHOST_BITS)
            continue;

        int bits_seen = TableFormat::RAM_GHOST_BITS;
        for (auto br : bitranges(mask_bits)) {
            le_bitrange ixbar_bits = { bits_seen, bits_seen + (br.second - br.first) };
            le_bitrange ghost_bits = { ghost_slice.get_lo(), ghost_slice.get_hi() };
            bits_seen += ixbar_bits.size();
            auto boost_sl = toClosedRange<RangeUnit::Bit, Endian::Little>
                            (ixbar_bits.intersectWith(ghost_bits));
            if (boost_sl == boost::none)
                continue;
            le_bitrange sl_overlap = *boost_sl;
            le_bitrange hash_bits = { br.first + sl_overlap.lo - ixbar_bits.lo,
                                      br.second - (ixbar_bits.hi - sl_overlap.hi) };
            hash_bits = hash_bits.shiftedByBits(IXBar::RAM_SELECT_BIT_START);
            Slice adapted_ghost = ghost_slice;
            if (ghost_slice.get_lo() < sl_overlap.lo)
                adapted_ghost.shrink_lo(sl_overlap.lo - ghost_slice.get_lo());
            if (ghost_slice.get_hi() > sl_overlap.hi)
                adapted_ghost.shrink_hi(ghost_slice.get_hi() - sl_overlap.hi);
            emit_ixbar_match_func(out, indent, empty, &adapted_ghost, hash_bits);
        }
    }
}

void ixbar_hash_exact_bitrange(Slice ghost_slice, int min_way_size,
        le_bitrange non_rotated_slice, le_bitrange comp_slice, int initial_lo_bit,
        safe_vector<std::pair<le_bitrange, Slice>> &ghost_positions) {
    auto boost_sl = toClosedRange<RangeUnit::Bit, Endian::Little>
                        (non_rotated_slice.intersectWith(comp_slice));
    if (boost_sl == boost::none)
        return;
    le_bitrange overlap = *boost_sl;
    int lo = overlap.lo - initial_lo_bit;
    int hi = overlap.hi - initial_lo_bit;
    le_bitrange hash_position = overlap;
    if (hash_position.lo >= min_way_size)
        hash_position = hash_position.shiftedByBits(-1 * min_way_size);
    ghost_positions.emplace_back(hash_position, ghost_slice(lo, hi));
}

/**
 * Fills in the slice_to_select_bits map, described in emit_ixbar_hash_exact
 */
void ixbar_hash_exact_info(int &min_way_size, int &min_way_slice,
        const Tofino::IXBar::Use *use, int hash_group,
        std::map<int, bitvec> &slice_to_select_bits) {
    for (auto way : use->way_use) {
        if (way.group != hash_group)
            continue;
        bitvec local_select_mask = bitvec(way.mask);
        int curr_way_size = IXBar::RAM_LINE_SELECT_BITS + local_select_mask.popcount();
        min_way_size = std::min(min_way_size, curr_way_size);
        min_way_slice = std::min(way.slice, min_way_slice);

        // Guarantee that way object that have the same slice bits also use a
        // similar pattern of select bits
        auto mask_p = slice_to_select_bits.find(way.slice);
        if (mask_p != slice_to_select_bits.end()) {
            bitvec curr_mask = mask_p->second;
            BUG_CHECK(curr_mask.min().index() == local_select_mask.min().index()
                      || local_select_mask.empty(), "Shared line select bits are not coordinated "
                      "to shared ram select index");
            slice_to_select_bits[way.slice] |= local_select_mask;
        } else {
            slice_to_select_bits[way.slice] = local_select_mask;
        }
    }

    bitvec verify_overlap;
    for (auto kv : slice_to_select_bits) {
        BUG_CHECK((verify_overlap & kv.second).empty(), "The RAM select bits are not unique per "
                  "way");
        verify_overlap |= kv.second;
        BUG_CHECK(kv.second.empty() || kv.second.is_contiguous(), "The RAM select bits must "
                  "currently be contiguous for the context JSON");
    }
}

/**
 * The purpose of this code is to output the hash matrix specifically for exact tables.
 * This code classifies all of the ghost bits for this particular hash table.  The ghost bits
 * are the bits that appear in the hash but not in the table format.  This reduces the
 * number of bits actually needed to match against.
 *
 * The ghost bits themselves are spread through an identity hash, while the bits that appear
 * in the match are randomized.  Thus each ghost bit is assigned a corresponding bit in the
 * way bits or select bits within the match format.
 *
 * The hash matrix is specified on a hash table by hash table basis.  16 x 64b hash tables
 * at most are specified, and if the ghost bits do not appear in that particular hash table,
 * they will not be output.  The ident_bits_prev_alloc is used to track how where to start
 * the identity of the ghost bits within this particular hash table.
 *
 * The hash for an exact match function is the following:
 *
 *     1.  Random for all of the match related bits.
 *     2.  An identity hash for the ghost bits across each way.
 *
 * Each way is built up of both RAM line select bits and RAM select bits.  The RAM line select
 * bits is a 10 bit window ranging from 0-4 way * 10 bit sections of the 52 bit hash bus. The
 * RAM select bits is any section of the upper 12 bits of the hash.
 *
 * In order to increase randomness, the identity hash across different ways is different.
 * Essentially each identity hash is shifted by 1 bit per way, so that the same identity hash
 * does not end up on the same RAM line.
 */
void emit_ixbar_hash_exact(std::ostream &out, indent_t indent,
        safe_vector<Slice> &match_data, safe_vector<Slice> &ghost, const Tofino::IXBar::Use *use,
        int hash_group, int &ident_bits_prev_alloc) {
    if (use->type == IXBar::Use::ATCAM_MATCH) {
        emit_ixbar_hash_atcam(out, indent, ghost, use, hash_group);
        return;
    }

    int min_way_size = IXBar::RAM_LINE_SELECT_BITS + IXBar::HASH_SINGLE_BITS + 1;
    int min_way_slice = IXBar::HASH_INDEX_GROUPS + 1;
    // key is way.slice i.e. RAM line select, value is the RAM select mask.  Due to an optimization
    // multiple IXBar::Use::Way may have the same way.slice, and different way.mask values.
    std::map<int, bitvec> slice_to_select_bits;

    ixbar_hash_exact_info(min_way_size, min_way_slice, use, hash_group, slice_to_select_bits);
    bool select_bits_needed = min_way_size > IXBar::RAM_LINE_SELECT_BITS;
    bitvec ways_done;

    for (auto way : use->way_use) {
        if (ways_done.getbit(way.slice))
            continue;
        if (way.group != hash_group)
            continue;
        ways_done.setbit(way.slice);
        // pair is portion of identity function, slice of PHV field
        safe_vector<std::pair<le_bitrange, Slice>> ghost_line_select_positions;
        safe_vector<std::pair<le_bitrange, Slice>> ghost_ram_select_positions;
        int ident_pos = ident_bits_prev_alloc;
        for (auto ghost_slice : ghost) {
            int ident_pos_shifted = ident_pos + way.slice - min_way_slice;
            // This is the identity bits starting at bit 0 that this ghost slice will impact on
            // a per way basis.
            le_bitrange non_rotated_slice = { ident_pos_shifted,
                                              ident_pos_shifted + ghost_slice.width() - 1 };

            // The bits in the RAM line select that begin at the ident_pos_shifted bit up to 10
            bool pre_rotation_line_sel_needed = ident_pos_shifted < IXBar::RAM_LINE_SELECT_BITS;
            if (pre_rotation_line_sel_needed) {
                le_bitrange ident_bits = { ident_pos_shifted, IXBar::RAM_LINE_SELECT_BITS - 1};
                ixbar_hash_exact_bitrange(ghost_slice, min_way_size, non_rotated_slice,
                                          ident_bits, ident_pos_shifted,
                                          ghost_line_select_positions);
            }

            // The bits in the RAM select, i.e. the upper 12 bits
            if (select_bits_needed) {
                le_bitrange ident_select_bits = { IXBar::RAM_LINE_SELECT_BITS, min_way_size - 1};
                ixbar_hash_exact_bitrange(ghost_slice, min_way_size, non_rotated_slice,
                                          ident_select_bits, ident_pos_shifted,
                                          ghost_ram_select_positions);
            }

            // The bits that start at bit 0 of the RAM line select
            bool post_rotation_needed = ident_pos_shifted + ghost_slice.width() > min_way_size;
            if (post_rotation_needed) {
                le_bitrange post_rotation_bits = { min_way_size,
                                                   min_way_size + ident_pos_shifted - 1 };
                ixbar_hash_exact_bitrange(ghost_slice, min_way_size, non_rotated_slice,
                                          post_rotation_bits, ident_pos_shifted,
                                          ghost_line_select_positions);
            }
            ident_pos += ghost_slice.width();
        }

        bitvec used_line_select_range;
        for (auto ghost_pos : ghost_line_select_positions) {
            used_line_select_range.setrange(ghost_pos.first.lo, ghost_pos.first.size());
        }

        safe_vector<le_bitrange> non_ghosted;
        bitvec no_ghost_line_select_bits
            = bitvec(0, IXBar::RAM_LINE_SELECT_BITS)
              - used_line_select_range.getslice(0, IXBar::RAM_LINE_SELECT_BITS);

        // Print out the portions that have no ghost impact, but have hash impact due to the
        // random hash on the normal match data (RAM line select)
        for (auto br : bitranges(no_ghost_line_select_bits)) {
            le_bitrange hash_bits = { br.first, br.second };
            hash_bits = hash_bits.shiftedByBits(IXBar::RAM_LINE_SELECT_BITS * way.slice);
            emit_ixbar_match_func(out, indent, match_data, nullptr, hash_bits);
        }

        // Print out the portions that have both match data and ghost data (RAM line select)
        for (auto ghost_pos : ghost_line_select_positions) {
            le_bitrange hash_bits = ghost_pos.first;
            hash_bits = hash_bits.shiftedByBits(IXBar::RAM_LINE_SELECT_BITS * way.slice);
            emit_ixbar_match_func(out, indent, match_data, &(ghost_pos.second), hash_bits);
        }

        bitvec ram_select_mask = slice_to_select_bits.at(way.slice);
        bitvec used_ram_select_range;
        for (auto ghost_pos : ghost_ram_select_positions) {
            used_ram_select_range.setrange(ghost_pos.first.lo, ghost_pos.first.size());
        }
        used_ram_select_range >>= IXBar::RAM_LINE_SELECT_BITS;

        bitvec no_ghost_ram_select_bits =
            bitvec(0, ram_select_mask.popcount()) - used_ram_select_range;

        // Print out the portions of that have no ghost data in RAM select
        for (auto br : bitranges(no_ghost_ram_select_bits)) {
            le_bitrange hash_bits = { br.first, br.second };
            // start at bit 40
            int shift = IXBar::RAM_SELECT_BIT_START + ram_select_mask.min().index();
            hash_bits = hash_bits.shiftedByBits(shift);
            emit_ixbar_match_func(out, indent, match_data, nullptr, hash_bits);
        }


        // Print out the portions that have ghost impact.  Assumed at the point that
        // the select bits are contiguous, not a hardware requirement, but a context JSON req.
        for (auto ghost_pos : ghost_ram_select_positions) {
            le_bitrange hash_bits = ghost_pos.first;
            int shift = IXBar::RAM_SELECT_BIT_START + ram_select_mask.min().index();
            shift -= IXBar::RAM_LINE_SELECT_BITS;
            hash_bits = hash_bits.shiftedByBits(shift);
            emit_ixbar_match_func(out, indent, match_data, &(ghost_pos.second), hash_bits);
        }
    }

    for (auto ghost_slice : ghost) {
        ident_bits_prev_alloc += ghost_slice.width();
    }
}

/** Given a bitrange to allocate into the ixbar hash matrix, as well as a list of fields to
 *  be the identity, this coordinates the field slice to a portion of the bit range.  This
 *  really only applies for identity matches.
 */
void emit_ixbar_hash_dist_ident(const PhvInfo &phv, std::ostream &out,
        indent_t indent, safe_vector<Slice> &match_data,
        const Tofino::IXBar::Use::HashDistHash &hdh,
        const safe_vector<const IR::Expression *> & /*field_list_order*/) {
    if (hdh.hash_gen_expr) {
        int hash_gen_expr_width = hdh.hash_gen_expr->type->width_bits();
        BUG_CHECK(hash_gen_expr_width > 0, "zero width hash expression: %s ?", hdh.hash_gen_expr);
        for (auto bit_pos : hdh.galois_start_bit_to_p4_hash) {
            int out_bit = bit_pos.first, in_bit = bit_pos.second.lo;
            while (in_bit <= bit_pos.second.hi && in_bit < hash_gen_expr_width) {
                int width = FormatHash::SliceWidth(phv, hdh.hash_gen_expr, in_bit, match_data);
                le_bitrange slice(in_bit, in_bit + width - 1);
                slice = slice.intersectWith(bit_pos.second);
                out << indent << out_bit;
                if (width > 1 ) out << ".." << (out_bit + slice.size() - 1);
                out << ": ";
                if (!FormatHash::ZeroHash(phv, hdh.hash_gen_expr, slice, match_data)) {
                    FormatHash::Output(phv, out, hdh.hash_gen_expr, slice, match_data);
                } else {
                    out << "0"; }
                out << std::endl;
                in_bit += slice.size();
                out_bit += slice.size(); }
            BUG_CHECK(in_bit == bit_pos.second.hi + 1 || in_bit >= hash_gen_expr_width,
                      "mismatched hash width"); }
        return; }

    BUG("still need this code?");
#if 0
    int bits_seen = 0;
    for (auto it = field_list_order.rbegin(); it != field_list_order.rend(); it++) {
        auto fs = PHV::AbstractField::create(phv, *it);
        for (auto &sl : match_data) {
            if (!(fs->field() && fs->field() == sl.get_field()))
                continue;
            auto boost_sl = toClosedRange<RangeUnit::Bit, Endian::Little>
                                  (fs->range().intersectWith(sl.range()));
            if (boost_sl == boost::none)
                continue;
            // Which slice bits of this field are overlapping
            le_bitrange field_overlap = *boost_sl;
            int ident_range_lo = bits_seen + field_overlap.lo - fs->range().lo;
            int ident_range_hi = ident_range_lo + field_overlap.size() - 1;
            le_bitrange identity_range = { ident_range_lo, ident_range_hi };
            for (auto bit_pos : hdh.galois_start_bit_to_p4_hash) {
                // Portion of the p4_output_hash that overlaps with the identity range
                auto boost_sl2 = toClosedRange<RangeUnit::Bit, Endian::Little>
                                 (identity_range.intersectWith(bit_pos.second));
                if (boost_sl2 == boost::none)
                    continue;
                le_bitrange ident_overlap = *boost_sl2;
                int hash_lo = bit_pos.first + (ident_overlap.lo - bit_pos.second.lo);
                int hash_hi = hash_lo + ident_overlap.size() - 1;
                int field_range_lo = field_overlap.lo + (ident_overlap.lo - identity_range.lo);
                int field_range_hi = field_range_lo + ident_overlap.size() - 1;
                Slice asm_sl(fs->field(), field_range_lo, field_range_hi);
                safe_vector<Slice> ident_slice;
                ident_slice.push_back(asm_sl);
                out << indent << hash_lo << ".." << hash_hi << ": "
                    << FormatHash(&ident_slice, nullptr, nullptr, nullptr,
                                  IR::MAU::HashFunction::identity())
                    << std::endl;
            }
        }
        bits_seen += fs->size();
    }
#endif
}

void emit_ixbar_meter_alu_hash(const PhvInfo &phv, std::ostream &out, indent_t indent,
        const safe_vector<Slice> &match_data, const Tofino::IXBar::Use::MeterAluHash &mah,
        const safe_vector<const IR::Expression *> &field_list_order,
        const LTBitMatrix &sym_keys) {
    if (mah.algorithm.type == IR::MAU::HashFunction::IDENTITY) {
        auto mask = mah.bit_mask;
        for (auto &el : mah.computed_expressions) {
            el.second->apply(EmitHashExpression(phv, out, indent, el.first, match_data));
            mask.clrrange(el.first, el.second->type->width_bits());
        }
        for (int to_clear = mask.ffs(0); to_clear >= 0;) {
            int end = mask.ffz(to_clear);
            out << indent << to_clear;
            if (end - 1 > to_clear) out << ".." << (end - 1);
            out << ": 0" << std::endl;
            to_clear = mask.ffs(end); }
    } else {
        le_bitrange br = { mah.bit_mask.min().index(), mah.bit_mask.max().index() };
        int total_bits = 0;
        std::multimap<int, Slice> match_data_map;
        std::map<le_bitrange, const IR::Constant*> constant_map;
        bool use_map = false;
        if (mah.algorithm.ordered()) {
            emit_ixbar_gather_map(phv, match_data_map, constant_map, match_data,
                    field_list_order, sym_keys, total_bits);
            use_map = true;
        }
        out << indent << br.lo << ".." << br.hi << ": ";
        if (use_map)
            out << FormatHash(nullptr, &match_data_map, nullptr, nullptr,
                    mah.algorithm, total_bits, &br);
        else
            out << FormatHash(&match_data, nullptr, nullptr, nullptr,
                    mah.algorithm, total_bits, &br);
        out << std::endl;
    }
}

void emit_ixbar_proxy_hash(const PhvInfo &phv, std::ostream &out, indent_t indent,
        safe_vector<Slice> &match_data, const Tofino::IXBar::Use::ProxyHashKey &ph,
        const safe_vector<const IR::Expression *> &field_list_order,
        const LTBitMatrix &sym_keys) {
    int start_bit = ph.hash_bits.ffs();
    do {
        int end_bit = ph.hash_bits.ffz(start_bit);
        le_bitrange br = { start_bit, end_bit - 1 };
        int total_bits = 0;
        out << indent << br.lo << ".." << br.hi << ": ";
        if (ph.algorithm.ordered()) {
            std::multimap<int, Slice> match_data_map;
            std::map<le_bitrange, const IR::Constant*> constant_map;
            emit_ixbar_gather_map(phv, match_data_map, constant_map, match_data,
                    field_list_order, sym_keys, total_bits);
            out << FormatHash(nullptr, &match_data_map, nullptr, nullptr,
                    ph.algorithm, total_bits, &br);
        } else {
            out << FormatHash(&match_data, nullptr, nullptr, nullptr,
                    ph.algorithm, total_bits, &br);
        }
        out << std::endl;
        start_bit = ph.hash_bits.ffs(end_bit);
    } while (start_bit >= 0);
}

/**
 * Given an order for an allocation, will determine the input position of the slice in
 * the allocation, and save it in the match_data_map
 *
 * When two keys are considered symmetric, currently they are given the same bit stream position
 * in the crc calculation in order to guarantee that their hash algorithm is identical for
 * those two keys.  This change, however, notes that the output of the function is not truly
 * the CRC function they requested, but a variation on it
 */
void emit_ixbar_gather_map(const PhvInfo &phv,
        std::multimap<int, Slice> &match_data_map,
        std::map<le_bitrange, const IR::Constant*> &constant_map,
        const safe_vector<Slice> &match_data,
        const safe_vector<const IR::Expression *> &field_list_order, const LTBitMatrix &sym_keys,
        int &total_size) {
    std::map<int, int> field_start_bits;
    std::map<int, int> reverse_sym_keys;
    int bits_seen = 0;
    for (int i = field_list_order.size() - 1; i >= 0; i--) {
        auto fs = PHV::AbstractField::create(phv, field_list_order.at(i));
        field_start_bits[i] = bits_seen;
        bitvec sym_key = sym_keys[i];
        if (!sym_key.empty()) {
            BUG_CHECK(sym_key.popcount() == 1 && reverse_sym_keys.count(sym_key.min().index()) == 0,
                "Symmetric hash broken in the backend");
            reverse_sym_keys[sym_key.min().index()] = i;
        }
        bits_seen += fs->size();
    }

    for (auto sl : match_data) {
        int order_bit = 0;
        // Traverse field list in reverse order. For a field list the convention
        // seems to indicate the field offsets are determined based on first
        int index = field_list_order.size();
        for (auto fs_itr = field_list_order.rbegin(); fs_itr != field_list_order.rend(); fs_itr++) {
            index--;
            auto fs = PHV::AbstractField::create(phv, *fs_itr);
            if (fs->is<PHV::Constant>()) {
                auto cons = fs->to<PHV::Constant>();
                le_bitrange br = { order_bit, order_bit + fs->size() - 1 };
                constant_map[br] = cons->value;
                order_bit += fs->size();
                continue;
            }

            if (fs->field() != sl.get_field()) {
                order_bit += fs->size();
                continue;
            }

            auto half_open_intersect = fs->range().intersectWith(sl.range());
            if (half_open_intersect.empty()) {
                order_bit += fs->size();
                continue;
            }

            le_bitrange intersect = { half_open_intersect.lo, half_open_intersect.hi - 1 };
            Slice adapted_sl = sl;


            int lo_adjust = std::max(intersect.lo - sl.range().lo, sl.range().lo - intersect.lo);
            int hi_adjust = std::max(intersect.hi - sl.range().hi, sl.range().hi - intersect.hi);
            adapted_sl.shrink_lo(lo_adjust);
            adapted_sl.shrink_hi(hi_adjust);
            int offset = adapted_sl.get_lo() - fs->range().lo;

            int sym_order_bit = reverse_sym_keys.count(index) > 0 ?
                                field_start_bits.at(reverse_sym_keys.at(index)) : order_bit;
            match_data_map.emplace(sym_order_bit + offset, adapted_sl);
            order_bit += fs->size();
        }
    }

    total_size = 0;
    for (auto fs : field_list_order) {
        total_size += fs->type->width_bits();
    }
}

/* Generate asm for the hash of a table, specifically either a match, gateway, or selector
   table.  Also used for hash distribution hash */
void emit_ixbar_hash(const PhvInfo &phv, std::ostream &out, indent_t indent,
        safe_vector<Slice> &match_data, safe_vector<Slice> &ghost, const IXBar::Use *use_,
        int hash_group, int &ident_bits_prev_alloc) {
    auto *use = dynamic_cast<const Tofino::IXBar::Use *>(use_);
    if (!use) return;
    if (!use->way_use.empty()) {
        emit_ixbar_hash_exact(out, indent, match_data, ghost, use, hash_group,
                              ident_bits_prev_alloc);
    }

    if (use->meter_alu_hash.allocated) {
        emit_ixbar_meter_alu_hash(phv, out, indent, match_data, use->meter_alu_hash,
                                  use->field_list_order, use->symmetric_keys);
    }

    if (use->proxy_hash_key_use.allocated) {
        emit_ixbar_proxy_hash(phv, out, indent, match_data, use->proxy_hash_key_use,
                              use->field_list_order, use->symmetric_keys);
    }


    // Printing out the hash for gateway tables
    for (auto ident : use->bit_use) {
        // Gateway fields in the hash are continuous bitranges, but may not match up
        // with the fields.  So we figure out the overlap between each use and each
        // match field and split them up where they don't match.  Do we really need to
        // do this?
        Slice range_sl(phv, ident.field, ident.lo, ident.lo + ident.width - 1);
        for (auto sl : match_data) {
            auto overlap = range_sl & sl;
            if (!overlap) continue;
            int bit = 40 + ident.bit + overlap.get_lo() - range_sl.get_lo();
            out << indent << bit;
            if (overlap.width() > 1)
                out << ".." << (bit + overlap.width() - 1);
            out << ": " << overlap << std:: endl;
        }
    }


    if (use->hash_dist_hash.allocated) {
        auto &hdh = use->hash_dist_hash;
        if (hdh.algorithm.type == IR::MAU::HashFunction::IDENTITY) {
            emit_ixbar_hash_dist_ident(phv, out, indent, match_data, hdh, use->field_list_order);
            return;
        }
        std::multimap<int, Slice> match_data_map;
        std::map<le_bitrange, const IR::Constant*> constant_map;
        bool use_map = false;
        int total_bits = 0;
        if (hdh.algorithm.ordered()) {
            emit_ixbar_gather_map(phv, match_data_map, constant_map, match_data,
                    use->field_list_order, use->symmetric_keys, total_bits);
            use_map = true;
        }

        for (auto bit_start : hdh.galois_start_bit_to_p4_hash) {
            int start_bit = bit_start.first;
            le_bitrange br = bit_start.second;
            int end_bit = start_bit + br.size() - 1;
            out << indent << start_bit << ".." << end_bit;
            if (use_map)
                out << ": " << FormatHash(nullptr, &match_data_map, &constant_map,
                        nullptr, hdh.algorithm, total_bits, &br);
            else
                out << ": " << FormatHash(&match_data, nullptr, nullptr,
                        nullptr, hdh.algorithm, total_bits, &br);
            out << std::endl;
        }
    }
}

/* Calculate the hash tables used by an individual P4 table in the IXBar */
void emit_ixbar_gather_bytes(const PhvInfo &phv,
        const safe_vector<Tofino::IXBar::Use::Byte> &use,
        std::map<int, std::map<int, Slice>> &sort, std::map<int, std::map<int, Slice>> &midbytes,
        const IR::MAU::Table *tbl, bool ternary, bool atcam = false) {
    PHV::FieldUse f_use(PHV::FieldUse::READ);
    for (auto &b : use) {
        BUG_CHECK(b.loc.allocated(), "Byte not allocated by assembly");
        int byte_loc = IXBar::TERNARY_BYTES_PER_GROUP;
        if (atcam && !b.is_spec(::IXBar::ATCAM_INDEX))
            continue;
        for (auto &fi : b.field_bytes) {
            auto field = phv.field(fi.get_use_name());
            BUG_CHECK(field, "Field not found");
            le_bitrange field_bits = { fi.lo, fi.hi };
            // It is not a guarantee, especially in Tofino2 due to live ranges being different
            // that a FieldInfo is not corresponding to a single alloc_slice object
            field->foreach_alloc(field_bits, tbl, &f_use, [&](const PHV::AllocSlice &sl) {
                if (b.loc.byte == byte_loc && ternary) {
                    Slice asm_sl(phv, fi.get_use_name(), sl.field_slice().lo, sl.field_slice().hi);
                    auto n = midbytes[b.loc.group/2].emplace(asm_sl.bytealign(), asm_sl);
                    BUG_CHECK(n.second, "duplicate byte use in ixbar");
                } else {
                    Slice asm_sl(phv, fi.get_use_name(), sl.field_slice().lo, sl.field_slice().hi);
                    auto n = sort[b.loc.group].emplace(b.loc.byte*8 + asm_sl.bytealign(), asm_sl);
                    BUG_CHECK(n.second, "duplicate byte use in ixbar");
                }
            }, PHV::SliceMatch::REF_PHYS_LR);
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

/* Determine which bytes of a table's input xbar belong to an individual hash table,
   so that we can output the hash of this individual table. */
void emit_ixbar_hash_table(int hash_table, safe_vector<Slice> &match_data,
        safe_vector<Slice> &ghost, const TableMatch *fmt,
        std::map<int, std::map<int, Slice>> &sort) {
    if (sort.empty())
        return;
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
            // P4C-4496: if dynamic_table_key_masks pragma is applied to the
            // table, ghost bits are disabled, as a result, match key must be
            // emitted as match data to generated the correct hash section in
            // bfa and context.json
            if (!fmt->identity_hash || fmt->dynamic_key_masks)
                match_data.insert(match_data.end(), reg_hash.begin(), reg_hash.end());
        } else {
            match_data.emplace_back(reg);
        }
    }
}

void Tofino::IXBar::Use::emit_ixbar_asm(const PhvInfo &phv, std::ostream &out, indent_t indent,
        const TableMatch *fmt, const IR::MAU::Table *tbl) const {
    std::map<int, std::map<int, Slice>> sort;
    std::map<int, std::map<int, Slice>> midbytes;
    emit_ixbar_gather_bytes(phv, use, sort, midbytes, tbl,
                            type == IXBar::Use::TERNARY_MATCH);
    cstring group_type = type == IXBar::Use::TERNARY_MATCH ? "ternary" : "exact";
    for (auto &group : sort)
        out << indent << group_type << " group "
            << group.first << ": " << group.second << std::endl;
    for (auto &midbyte : midbytes)
        out << indent << "byte group "
            << midbyte.first << ": " << midbyte.second << std::endl;
    if (type == IXBar::Use::ATCAM_MATCH) {
        sort.clear();
        midbytes.clear();
        emit_ixbar_gather_bytes(phv, use, sort, midbytes, tbl,
                                type == IXBar::Use::TERNARY_MATCH,
                                type == IXBar::Use::ATCAM_MATCH);
    }
    for (int hash_group = 0; hash_group < IXBar::HASH_GROUPS; hash_group++) {
        unsigned hash_table_input = hash_table_inputs[hash_group];
        bitvec hash_seed = this->hash_seed[hash_group];
        int ident_bits_prev_alloc = 0;
        if (hash_table_input || hash_seed) {
            for (int ht : bitvec(hash_table_input)) {
                out << indent++ << "hash " << ht << ":" << std::endl;
                safe_vector<Slice> match_data;
                safe_vector<Slice> ghost;
                emit_ixbar_hash_table(ht, match_data, ghost, fmt, sort);
                // FIXME: This is obviously an issue for larger selector tables,
                //  whole function needs to be replaced
                emit_ixbar_hash(phv, out, indent, match_data, ghost, this, hash_group,
                                ident_bits_prev_alloc);
                if (is_parity_enabled())
                    out << indent << IXBar::HASH_PARITY_BIT << ": parity" << std::endl;
                --indent;
            }
            out << indent++ << "hash group " << hash_group << ":" << std::endl;
            if (hash_table_input)
                out << indent << "table: [" << emit_vector(bitvec(hash_table_input), ", ") << "]"
                    << std::endl;
            out << indent << "seed: 0x" << hash_seed << std::endl;
            if (is_parity_enabled())
                out << indent << "seed_parity: true" << std::endl;
            --indent;
        }
    }
}

bool Tofino::ActionDataBus::Use::emit_adb_asm(std::ostream &out, const IR::MAU::Table *tbl,
                                              bitvec source) const {
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
        if (!first)
            out << ", ";
        first = false;
        out << rs.location.byte;
        if (byte_sz > 1)
            out << ".." << (rs.location.byte + byte_sz - 1);
        out << " : ";

        // For emitting hash distribution sections on the action_bus directly.  Must find
        // which slices of hash distribution are to go to which bytes, requiring coordination
        // from the input xbar and action format allocation
        if (source_is_immed
            && format.is_byte_offset<ActionData::Hash>(rs.byte_offset)) {
            safe_vector<int> all_hash_dist_units = tbl->resources->hash_dist_immed_units();
            bitvec slot_hash_dist_units;
            int immed_lo = rs.byte_offset * 8;
            int immed_hi = immed_lo + (8 << rs.location.type) - 1;
            le_bitrange immed_range = { immed_lo, immed_hi };
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
            int rng_unit = tbl->resources->rng_unit();
            out << "rng(" << rng_unit << ", ";
            int lo = rs.byte_offset * 8;
            int hi = lo + byte_sz * 8 - 1;
            out << lo << ".." << hi << ")";
        } else if (source_is_immed
                   && format.is_byte_offset<ActionData::MeterColor>(rs.byte_offset)) {
            for (auto back_at : tbl->attached) {
                auto at = back_at->attached;
                auto *mtr = at->to<IR::MAU::Meter>();
                if (mtr == nullptr) continue;
                out << MauAsmOutput::find_attached_name(tbl, mtr) << " color";
                break;
            }
        } else if (source_is_adt || source_is_immed) {
            out << format.get_format_name(rs.location.type, rs.source, rs.byte_offset);
        } else if (source_is_meter) {
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
    return !first;
}

void MauAsmOutput::emit_table_format(std::ostream &out, indent_t indent,
        const TableFormat::Use &use, const TableMatch *tm,
        bool ternary, bool no_match) const {
    ::MauAsmOutput::emit_table_format(out, indent, use, tm, ternary, no_match);

    if (!use.match_group_map.empty()) {
        out << indent << "match_group_map: [ ";
        std::string sep = "";
        for (auto ram_entries : use.match_group_map) {
            out << sep << "[ " << emit_vector(ram_entries) << " ]";
            sep = ", ";
        }
        out << " ]" << std::endl;
        indent--;
    }
}

}  // end Tofino namespace

