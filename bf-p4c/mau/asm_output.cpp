#include <regex>
#include <string>
#include "bf-p4c/common/alias.h"
#include "bf-p4c/lib/error_type.h"
#include "bf-p4c/ir/tofino_write_context.h"
#include "bf-p4c/mau/asm_output.h"
#include "bf-p4c/mau/gateway.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/table_format.h"
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

int DefaultNext::id_counter = 0;

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
    bool phase0OutputAsm = false;
    // Output phase0 table only once in assembly at the start of stage 0
    // TODO: For multiple parser support, new assembly syntax under parser
    // needs to be added to specify phase0 for each parser. Correspondingly,
    // context.json schema for phase0 table must be changed to include
    // phase0 info within the parser node
    auto* pipe = mauasm.pipe;

    for (auto p : pipe->thread[INGRESS].parsers) {
        if (auto* parser = p->to<IR::BFN::LoweredParser>()) {
            if (auto p0 = parser->phase0) {
                out << "stage 0 ingress:" << std::endl;
                out << p0;
                phase0OutputAsm = true;
            }
        }
    }

    int maxStages[3] = { -1, -1, -1 };
    for (auto &stage : mauasm.by_stage)
        if (stage.first.second > maxStages[stage.first.first])
            maxStages[stage.first.first] = stage.first.second;

    for (auto &stage : mauasm.by_stage) {
        if (!phase0OutputAsm || stage.first.second != 0 || stage.first.first != INGRESS)
            out << "stage " << stage.first.second << ' ' << stage.first.first << ':' << std::endl;
        if (Device::currentDevice() == Device::JBAY &&
            stage.first.first != GHOST && stage.first.second > 0)
            out << indent << "dependency: match" << std::endl;
        if (Device::currentDevice() == Device::JBAY &&
            stage.first.second == maxStages[stage.first.first])
            mauasm.emit_always_init_action(out, indent, stage.first);
        for (auto &tbl : stage.second) {
            mauasm.emit_table(out, tbl.tableInfo, stage.first.second /* stage */,
                stage.first.first /* gress */);
        }
    }
    if (mauasm.by_stage.empty() && !phase0OutputAsm) {
        // minimal pipe config for empty program
        out << "stage 0 ingress: {}" << std::endl; }
    return out;
}

class MauAsmOutput::TableMatch {
 public:
    safe_vector<Slice>       match_fields;
    safe_vector<Slice>       ghost_bits;

    struct ProxyHashSlice {
        le_bitrange bits;
        explicit ProxyHashSlice(le_bitrange b) : bits(b) {}

     public:
        friend std::ostream &operator<<(std::ostream &, const ProxyHashSlice &);
    };
    safe_vector<ProxyHashSlice> proxy_hash_fields;
    bool proxy_hash = false;
    bool identity_hash = false;

    const IR::MAU::Table     *table = nullptr;
    void init_proxy_hash(const IR::MAU::Table *tbl);

    TableMatch(const MauAsmOutput &s, const PhvInfo &phv, const IR::MAU::Table *tbl);
};

std::ostream &operator<<(std::ostream &out, const MauAsmOutput::TableMatch::ProxyHashSlice &sl) {
    out << "hash_group" << "(" << sl.bits.lo << ".." << sl.bits.hi << ")";
    return out;
}

void MauAsmOutput::emit_single_alias(std::ostream &out, cstring &sep,
        const ActionData::Parameter *param, le_bitrange adt_range, cstring alias,
        safe_vector<ActionData::Argument> &full_args, cstring action_name) const {
    bool found = false;
    bool single_value = true;
    le_bitrange arg_bits = { 0, 0 };
    if (auto arg = param->to<ActionData::Argument>()) {
        for (auto full_arg : full_args) {
            if (arg->name() != full_arg.name())
                continue;
            if (arg->param_field() != full_arg.param_field()) {
                single_value = false;
                arg_bits = arg->param_field();
            }
            found = true;
            break;
        }
        BUG_CHECK(found, "An argument %s was not found in the parameters of action %s",
                  arg->name(), action_name);
    }

    out << sep << param->name();
    if (!single_value)
        out << "." << arg_bits.lo << "-" << arg_bits.hi;
    out << ": ";
    out << alias << "(" << adt_range.lo << ".." << adt_range.hi << ")";
    sep = ", ";

    // Have to go through another layer of aliasing to print out the constant
    if (auto constant = param->to<ActionData::Constant>()) {
        out << sep << constant->name() << ": ";
        out << constant->value().getrange(0, 32);
        sep = ", ";
    }
}

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
 *
 *  Currently, there are two levels of aliasing:
 *      1. An alias to combine multiple P4 parameters into a single aliased P4 parameter,
 *         if these multiple parameters are used in the same action:
 *             -set f1, arg1
 *             -set f2, arg2
 *         where f1 and f2 are in the same container.  arg1 and arg2 will be aliased to
 *         something like $data0
 *      2. A location in the Action Ram/Match Ram alias, i.e. $adf_h0 or immediate(lo..hi)
 *
 *  Due to the current way instruction adjustment works, either the parameter, or the first
 *  alias, i.e. $data0, appear in the actual instructions.  One could make an argument
 *  that this isn't needed, and that may be true, but would require further work in
 *  Instruction Adjustment
 */
void MauAsmOutput::emit_action_data_alias(std::ostream &out, indent_t indent,
        const IR::MAU::Table *tbl, const IR::MAU::Action *af) const {
    auto &format = tbl->resources->action_format;
    auto all_alu_positions = format.alu_positions.at(af->name);
    safe_vector<ActionData::Argument> full_args;
    for (auto arg : af->args) {
        le_bitrange full_arg_bits = { 0, arg->type->width_bits() - 1};
        full_args.emplace_back(arg->name.name, full_arg_bits);
    }

    out << indent << "- { ";
    cstring sep = "";
    for (auto alu_pos : all_alu_positions) {
        cstring alias_name = alu_pos.alu_op->alias();
        le_bitrange slot_bits = { alu_pos.alu_op->slot_bits().min().index(),
                                 alu_pos.alu_op->slot_bits().max().index() };
        le_bitrange postpone_range = { 0, 0 };
        bool second_alias;
        cstring second_level_alias;
        if (!alias_name.isNull()) {
            out << sep << alias_name << ": ";
            out << format.get_format_name(alu_pos, false, &slot_bits, nullptr);
            sep = ", ";
            second_level_alias = alias_name;
            second_alias = true;
        } else {
            second_level_alias = format.get_format_name(alu_pos, false, nullptr, &postpone_range);
            second_alias = false;
        }

        auto ad_pos = alu_pos.alu_op->parameter_positions();

        int wrapped_con_idx = 0;
        for (auto pos : ad_pos) {
            // Stop at the bitmasked-set
            if (pos.first >= static_cast<int>(alu_pos.alu_op->size()))
                break;
            le_bitrange adt_range = { pos.first, pos.first + pos.second->size() - 1 };
            // The alias already has subtracted out the slot_bits range.
            if (second_alias) {
                adt_range = adt_range.shiftedByBits(-1 * slot_bits.lo);
            } else {
                // In order to capture the direct location in immediate, the first immediate
                // bit position has to be added to the range, as immediate is one keyword
                adt_range = adt_range.shiftedByBits(postpone_range.lo);
            }

            const ActionData::Parameter *param = pos.second;
            auto wrapped_con_name = alu_pos.alu_op->wrapped_constant();

            // A constant that is wrapped around the RAM slot will two separate values, and
            // will be some split of one of those two values
            if (!wrapped_con_name.isNull() && pos.second->name() == wrapped_con_name) {
                auto curr_con = param->to<ActionData::Constant>();
                BUG_CHECK(curr_con, "Wrapped constant function is not working correctly");
                auto next_con = new ActionData::Constant(*curr_con);
                next_con->set_alias(curr_con->alias() + "_" + std::to_string(wrapped_con_idx));
                wrapped_con_idx++;
                param = next_con;
            }

            emit_single_alias(out, sep, param, adt_range, second_level_alias,
                              full_args, af->name);
        }

        // Because the mask can now be built up of both parameters and constants, the alias
        // mechanism is similar to the data fields
        if (alu_pos.alu_op->is_constrained(ActionData::BITMASKED_SET)) {
            le_bitrange mask_slot_bits = { alu_pos.alu_op->mask_bits().min().index(),
                                           alu_pos.alu_op->mask_bits().max().index() };
            out << sep << alu_pos.alu_op->mask_alias() << ": ";
            out << format.get_format_name(alu_pos, true, &mask_slot_bits);
            sep = ", ";
            for (auto pos : ad_pos) {
                if (pos.first < static_cast<int>(alu_pos.alu_op->size()))
                    continue;
                le_bitrange adt_range = { pos.first, pos.first + pos.second->size() -1 };
                adt_range = adt_range.shiftedByBits(-1 * alu_pos.alu_op->size());
                adt_range = adt_range.shiftedByBits(-1 * slot_bits.lo);
                emit_single_alias(out, sep, pos.second, adt_range, alu_pos.alu_op->mask_alias(),
                                  full_args, af->name);
            }
        }
    }
    out << " }" << std::endl;
}



// Simply emits the action data format of the action data table or action profile
void MauAsmOutput::emit_action_data_format(std::ostream &out, indent_t indent,
        const IR::MAU::Table *tbl, const IR::MAU::Action *af) const {
    auto &format = tbl->resources->action_format;
    auto &alu_pos_vec = format.alu_positions.at(af->name);
    if (alu_pos_vec.empty())
        return;

    std::set<std::pair<int, int>> single_placements;
    for (auto &alu_pos : alu_pos_vec) {
        auto single_placement = std::make_pair(alu_pos.start_byte, alu_pos.alu_op->size());

        if (alu_pos.loc == ActionData::IMMEDIATE)
            continue;
        single_placements.insert(single_placement);
    }

    if (single_placements.empty())
        return;

    out << indent << "format " << canon_name(af->name) << ": { ";
    cstring sep = "";
    single_placements.clear();
    for (auto &alu_pos : alu_pos_vec) {
        auto single_placement = std::make_pair(alu_pos.start_byte, alu_pos.alu_op->size());

        if (alu_pos.loc == ActionData::IMMEDIATE)
            continue;
        if (single_placements.count(single_placement) == 0) {
            cstring alias_name = format.get_format_name(alu_pos, false);
            out << sep << alias_name;
            int start_bit = alu_pos.start_byte * 8;
            int end_bit = start_bit + alu_pos.alu_op->size() - 1;
            out << ": " << start_bit << ".." << end_bit;
            sep = ", ";
        }

        single_placements.insert(single_placement);

        if (alu_pos.alu_op->is_constrained(ActionData::BITMASKED_SET)) {
            int mask_start = alu_pos.start_byte + alu_pos.alu_op->size() / 8;
            auto bitmasked_placement = std::make_pair(mask_start, alu_pos.alu_op->size());
            if (single_placements.count(bitmasked_placement) == 0) {
                out << sep << format.get_format_name(alu_pos, true);
                int start_bit = mask_start * 8;
                int end_bit = start_bit + alu_pos.alu_op->size() - 1;
                out << ": " << start_bit << ".." << end_bit;
                sep = ", ";
                single_placements.insert(bitmasked_placement);
            }
        }
    }
    out << " }" << std::endl;
}


struct FormatHash {
    using RangeOfConstant = std::map<le_bitrange, const IR::Constant*>;
    const safe_vector<Slice>         *match_data;
    const std::multimap<int, Slice>  *match_data_map;
    const RangeOfConstant            *constant_map;
    const Slice                      *ghost;
    IR::MAU::HashFunction            func;
    int                              total_bits = 0;
    le_bitrange                      *field_range;

    FormatHash(const safe_vector<Slice> *md, const std::multimap<int, Slice> *mdm,
               const std::map<le_bitrange, const IR::Constant*> *cm, const Slice *g,
               IR::MAU::HashFunction f, int tb = 0, le_bitrange *fr = nullptr)
        : match_data(md), match_data_map(mdm), constant_map(cm), ghost(g),
        func(f), total_bits(tb), field_range(fr) {
        BUG_CHECK(match_data == nullptr || match_data_map == nullptr, "FormatHash not "
                  "configured correctly");
    }
};

std::ostream &operator<<(std::ostream &out, const FormatHash &hash) {
    if (hash.field_range != nullptr) {
        FormatHash hash2(hash.match_data, hash.match_data_map, hash.constant_map,
                         hash.ghost, hash.func, hash.total_bits);
        out << "slice(" << hash2 << ", " << hash.field_range->lo << "..";
        out << hash.field_range->hi << ")";
        return out;
    }

    if (hash.func.type == IR::MAU::HashFunction::IDENTITY) {
        BUG_CHECK(hash.match_data, "For an identity, must be a standard vector");
        out << "stripe(" << emit_vector(*hash.match_data) << ")";
    } else if (hash.func.type == IR::MAU::HashFunction::RANDOM) {
        BUG_CHECK(hash.match_data, "For a random, must be a standard vector");
        if (!hash.match_data->empty()) {
            out << "random(" << emit_vector(*hash.match_data, ", ") << ")";
            if (hash.ghost) out << " ^ ";
        }
        if (hash.ghost) {
            out << *hash.ghost;
        }
    } else if (hash.func.type == IR::MAU::HashFunction::CRC) {
        BUG_CHECK(hash.match_data_map, "For a crc, must be a map");
        out << "stripe(crc";
        if (hash.func.reverse) out << "_rev";
        out << "(0x" << hex(hash.func.poly) << ", ";
        out << "0x" << hex(hash.func.init) << ", ";
        out << "0x" << hex(hash.func.final_xor) << ", ";
        out << hash.total_bits << ", ";
        out << *hash.match_data_map;
        // could not use the operator<< on std::map because the le_bitrange
        // does not print to valid json range.
        if (hash.constant_map) {
            out << ", {";
            const char *sep = " ";
            for (const auto &kv : *hash.constant_map) {
                out << sep << kv.first.lo << ".." << kv.first.hi << ": " << kv.second;
                sep = ", ";
            }
            out << " }"; }
        out << ")";
        // FIXME -- final_xor needs to go into the seed for the hash group
        out << ")";
    } else if (hash.func.type == IR::MAU::HashFunction::XOR) {
        // fixme -- should be able to implement this in a hash function
        BUG("xor hashing algorithm not supported");
    } else if (hash.func.type == IR::MAU::HashFunction::CSUM) {
        BUG("csum hashing algorithm not supported");
    } else {
        BUG("unknown hashing algorithm %d", hash.func.type);
    }
    return out;
}

class MauAsmOutput::EmitHashExpression : public Inspector {
    const MauAsmOutput          &self;
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
        if (auto *field = self.phv.field(c->expr, &bits)) {
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
    bool preorder(const IR::Constant *) override { return false; }
    bool preorder(const IR::Expression *e) override {
        le_bitrange     bits;
        if (auto *field = self.phv.field(e, &bits)) {
            Slice sl(field, bits);
            for (auto match_sl : match_data) {
                auto overlap = sl & match_sl;
                if (!overlap) continue;
                auto bit = this->bit + overlap.get_lo() - sl.get_lo();
                out << indent << bit;
                if (overlap.width() > 1)
                    out << ".." << (bit + overlap.width() - 1);
                out << ": " << overlap << std::endl; }
        } else {
            BUG("%s too complex in EmitHashExpression", e);
        }
        return false; }

 public:
    EmitHashExpression(const MauAsmOutput &self, std::ostream &out, indent_t indent, int bit,
                       const safe_vector<Slice> &match_data)
    : self(self), out(out), indent(indent), bit(bit), match_data(match_data) {}
};

/* Calculate the hash tables used by an individual P4 table in the IXBar */
void MauAsmOutput::emit_ixbar_gather_bytes(const safe_vector<IXBar::Use::Byte> &use,
        std::map<int, std::map<int, Slice>> &sort, std::map<int, std::map<int, Slice>> &midbytes,
        const IR::MAU::Table *tbl, bool ternary, bool atcam) const {
    PHV::FieldUse f_use(PHV::FieldUse::READ);
    for (auto &b : use) {
        BUG_CHECK(b.loc.allocated(), "Byte not allocated by assembly");
        int byte_loc = IXBar::TERNARY_BYTES_PER_GROUP;
        if (atcam && !b.is_spec(IXBar::ATCAM_INDEX))
            continue;
        for (auto &fi : b.field_bytes) {
            auto field = phv.field(fi.get_use_name());
            le_bitrange field_bits = { fi.lo, fi.hi };
            // It is not a guarantee, especially in Tofino2 due to live ranges being different
            // that a FieldInfo is not corresponding to a single alloc_slice object
            field->foreach_alloc(field_bits, tbl, &f_use, [&](const PHV::Field::alloc_slice &sl) {
                if (b.loc.byte == byte_loc && ternary) {
                    Slice asm_sl(phv, fi.get_use_name(), sl.field_bit, sl.field_hi());
                    auto n = midbytes[b.loc.group/2].emplace(asm_sl.bytealign(), asm_sl);
                    BUG_CHECK(n.second, "duplicate byte use in ixbar");
                } else {
                    Slice asm_sl(phv, fi.get_use_name(), sl.field_bit, sl.field_hi());
                    auto n = sort[b.loc.group].emplace(b.loc.byte*8 + asm_sl.bytealign(), asm_sl);
                    BUG_CHECK(n.second, "duplicate byte use in ixbar");
                }
            });
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

void MauAsmOutput::emit_hash_dist(std::ostream &out, indent_t indent,
        const safe_vector<IXBar::HashDistUse> *hash_dist_use, bool hashmod) const {
    if (hash_dist_use == nullptr || hash_dist_use->empty())
        return;

    bool first = true;
    for (auto &hash_dist : *hash_dist_use) {
        for (auto &ir_alloc : hash_dist.ir_allocations) {
            BUG_CHECK(ir_alloc.use.type == IXBar::Use::HASH_DIST, "Hash Dist allocation on "
                      "a non-hash dist xbar region");
        }
    // if (hash_dist.use.type != IXBar::Use::HASH_DIST) continue;
        if ((hash_dist.destinations().getbit(IXBar::HD_HASHMOD)) != hashmod) continue;
        if (first) {
            out << indent++ << "hash_dist:" << std::endl;
            first = false;
        }
        out << indent << hash_dist.unit << ": { ";
        out << "hash: " << hash_dist.hash_group();
        if (!hash_dist.mask.empty())
            out << ", mask: 0x" << hash_dist.mask;
        if (hash_dist.shift >= 0)
            out << ", shift: " << hash_dist.shift;
        if (hash_dist.expand >= 0)
            out << ", expand: " << hash_dist.expand;
        auto &set = hash_dist.outputs;
        if (set.size() > 0) {
            out << ", output: ";
            if (set.size() > 1) {
                const char *sep = "[ ";
                for (auto el : set) {
                    out << sep << el;
                    sep = ", "; }
                out << " ]";
            } else {
                out << *set.begin();
            }
        }
        out << " }" << std::endl;
    }
}

/* Determine which bytes of a table's input xbar belong to an individual hash table,
   so that we can output the hash of this individual table. */
void MauAsmOutput::emit_ixbar_hash_table(int hash_table, safe_vector<Slice> &match_data,
        safe_vector<Slice> &ghost, const TableMatch *fmt,
        std::map<int, std::map<int, Slice>> &sort) const {
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
            if (!fmt->identity_hash)
                match_data.insert(match_data.end(), reg_hash.begin(), reg_hash.end());
        } else {
            match_data.emplace_back(reg);
        }
    }
}

/**
 * This funciton is to emit the match data function associated with an SRAM match table.
 */
void MauAsmOutput::emit_ixbar_match_func(std::ostream &out, indent_t indent,
        safe_vector<Slice> &match_data, Slice *ghost, le_bitrange hash_bits) const {
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
void MauAsmOutput::emit_ixbar_hash_atcam(std::ostream &out, indent_t indent,
        safe_vector<Slice> &ghost, const IXBar::Use *use, int hash_group) const {
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

void MauAsmOutput::ixbar_hash_exact_bitrange(Slice ghost_slice, int min_way_size,
        le_bitrange non_rotated_slice, le_bitrange comp_slice, int initial_lo_bit,
        safe_vector<std::pair<le_bitrange, Slice>> &ghost_positions) const {
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
void MauAsmOutput::ixbar_hash_exact_info(int &min_way_size, int &min_way_slice,
        const IXBar::Use *use, int hash_group, std::map<int, bitvec> &slice_to_select_bits) const {
    for (auto way : use->way_use) {
        if (way.group != hash_group)
            continue;
        bitvec local_select_mask = bitvec(way.mask);
        int curr_way_size = IXBar::RAM_LINE_SELECT_BITS + local_select_mask.popcount();
        min_way_size = std::min(min_way_size, curr_way_size);
        min_way_slice = std::min(way.slice, min_way_slice);


        // Guarantee that way object that have the same slice bits also use a similar pattern
        // of select bits
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
void MauAsmOutput::emit_ixbar_hash_exact(std::ostream &out, indent_t indent,
        safe_vector<Slice> &match_data, safe_vector<Slice> &ghost, const IXBar::Use *use,
        int hash_group, int &ident_bits_prev_alloc) const {
    if (use->atcam) {
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
void MauAsmOutput::emit_ixbar_hash_dist_ident(std::ostream &out, indent_t indent,
        safe_vector<Slice> &match_data, const IXBar::Use::HashDistHash &hdh,
        const safe_vector<const IR::Expression *> &field_list_order) const {
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
}

void MauAsmOutput::emit_ixbar_meter_alu_hash(std::ostream &out, indent_t indent,
        safe_vector<Slice> &match_data, const IXBar::Use::MeterAluHash &mah,
        const safe_vector<const IR::Expression *> &field_list_order,
        const LTBitMatrix &sym_keys) const {
    if (mah.algorithm.type == IR::MAU::HashFunction::IDENTITY) {
        auto mask = mah.bit_mask;
        for (auto &el : mah.computed_expressions) {
            el.second->apply(EmitHashExpression(*this, out, indent, el.first, match_data));
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
            emit_ixbar_gather_map(match_data_map, constant_map, match_data,
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

void MauAsmOutput::emit_ixbar_proxy_hash(std::ostream &out, indent_t indent,
        safe_vector<Slice> &match_data, const IXBar::Use::ProxyHashKey &ph,
        const safe_vector<const IR::Expression *> &field_list_order,
        const LTBitMatrix &sym_keys) const {
    int start_bit = ph.hash_bits.ffs();
    do {
        int end_bit = ph.hash_bits.ffz(start_bit);
        le_bitrange br = { start_bit, end_bit - 1 };
        int total_bits = 0;
        out << indent << br.lo << ".." << br.hi << ": ";
        if (ph.algorithm.ordered()) {
            std::multimap<int, Slice> match_data_map;
            std::map<le_bitrange, const IR::Constant*> constant_map;
            emit_ixbar_gather_map(match_data_map, constant_map, match_data,
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
void MauAsmOutput::emit_ixbar_gather_map(std::multimap<int, Slice> &match_data_map,
        std::map<le_bitrange, const IR::Constant*> &constant_map, safe_vector<Slice> &match_data,
        const safe_vector<const IR::Expression *> &field_list_order, const LTBitMatrix &sym_keys,
        int &total_size) const {
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
void MauAsmOutput::emit_ixbar_hash(std::ostream &out, indent_t indent,
                                   safe_vector<Slice> &match_data,
                                   safe_vector<Slice> &ghost,
                                   const IXBar::Use *use, int hash_group,
                                   int &ident_bits_prev_alloc) const {
    if (!use->way_use.empty()) {
        emit_ixbar_hash_exact(out, indent, match_data, ghost, use, hash_group,
                              ident_bits_prev_alloc);
    }

    if (use->meter_alu_hash.allocated) {
        emit_ixbar_meter_alu_hash(out, indent, match_data, use->meter_alu_hash,
                                  use->field_list_order, use->symmetric_keys);
    }

    if (use->proxy_hash_key_use.allocated) {
        emit_ixbar_proxy_hash(out, indent, match_data, use->proxy_hash_key_use,
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
            emit_ixbar_hash_dist_ident(out, indent, match_data, hdh, use->field_list_order);
            return;
        }
        std::multimap<int, Slice> match_data_map;
        std::map<le_bitrange, const IR::Constant*> constant_map;
        bool use_map = false;
        int total_bits = 0;
        if (hdh.algorithm.ordered()) {
            emit_ixbar_gather_map(match_data_map, constant_map, match_data,
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

void MauAsmOutput::emit_single_ixbar(std::ostream &out, indent_t indent, const IXBar::Use *use,
        const TableMatch *fmt, const IR::MAU::Table *tbl) const {
    std::map<int, std::map<int, Slice>> sort;
    std::map<int, std::map<int, Slice>> midbytes;
    emit_ixbar_gather_bytes(use->use, sort, midbytes, tbl, use->ternary);
    cstring group_type = use->ternary ? "ternary" : "exact";
    for (auto &group : sort)
        out << indent << group_type << " group "
            << group.first << ": " << group.second << std::endl;
    for (auto &midbyte : midbytes)
        out << indent << "byte group "
            << midbyte.first << ": " << midbyte.second << std::endl;
    if (use->atcam) {
        sort.clear();
        midbytes.clear();
        emit_ixbar_gather_bytes(use->use, sort, midbytes, tbl, use->ternary, use->atcam);
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
                                ident_bits_prev_alloc);
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


void MauAsmOutput::emit_ixbar(std::ostream &out, indent_t indent, const IXBar::Use *use,
        const IXBar::Use *proxy_hash_use, const safe_vector<IXBar::HashDistUse> *hash_dist_use,
        const Memories::Use *mem, const TableMatch *fmt, const IR::MAU::Table *tbl,
        bool ternary) const {
    if (!ternary) {
        emit_ways(out, indent, use, mem);
    }
    emit_hash_dist(out, indent, hash_dist_use, false);
    if ((use == nullptr || use->use.empty())
        && (proxy_hash_use == nullptr || proxy_hash_use->use.empty())
        && (hash_dist_use == nullptr || hash_dist_use->empty())) {
        return;
    }
    if (ternary && use && !use->ternary) return;
    out << indent++ << "input_xbar:" << std::endl;
    if (use) {
        emit_single_ixbar(out, indent, use, fmt, tbl);
    }

    if (proxy_hash_use) {
        emit_single_ixbar(out, indent, proxy_hash_use, nullptr, tbl);
    }

    if (hash_dist_use) {
        for (auto &hash_dist : *hash_dist_use) {
            for (auto &ir_alloc : hash_dist.ir_allocations) {
                emit_single_ixbar(out, indent, &(ir_alloc.use), nullptr, tbl);
            }
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

void MauAsmOutput::emit_memory(std::ostream &out, indent_t indent, const Memories::Use &mem,
         const IR::MAU::Table::Layout *layout, const TableFormat::Use *format) const {
    safe_vector<int> row, bus, result_bus, word;
    std::map<int, safe_vector<int>> home_rows;
    safe_vector<int> stash_rows;
    safe_vector<int> stash_cols;
    safe_vector<int> stash_units;
    bool logical = mem.type >= Memories::Use::COUNTER;
    bool have_bus = !logical;
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
            row.push_back(2*r.row + (r.col[0] >= Memories::LEFT_SIDE_COLUMNS));
            have_col = true;
        } else {
            row.push_back(r.row);
            bus.push_back(r.bus);
            if (r.bus < 0) have_bus = false;
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
                out << indent << "bus: " << bus << std::endl;
            }
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
    } else {
        out << indent << "row: " << row[0] << std::endl;
        if (have_bus) {
            if (separate_bus) {
                out << indent << "search_bus: " << bus[0] << std::endl;
                out << indent << "result_bus: " << result_bus[0] << std::endl;
            } else {
                out << indent << "bus: " << bus[0] << std::endl;
            }
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
        } else {
            out << indent << "row: " << color_mapram_row[0] << std::endl;
            out << indent << "bus: " << color_mapram_bus[0] << std::endl;
            out << indent << "column: " << memory_vector(mem.color_mapram[0].col, mem.type, true)
                << std::endl;
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
    if (type == TableFormat::SEL_LEN_MOD)
        return "sel_len_mod";
    if (type == TableFormat::SEL_LEN_SHIFT)
        return "sel_len_shift";
    return "";
}

/**
 * This function is used to generate action_data_bus info for TernaryIndirect,
 * ActionData and MAU::Table The 'source' field is used to control which action
 * data bus slot to emit for each type of caller. 'source' is the OR-ed result
 * of (1 << ActionFormat::ad_source_t)
 *
 * For anything that is not an ActionArg or a Constant, the old action format is currently
 * deferred until the new format is used to determine their allocation
 */
void MauAsmOutput::emit_action_data_bus(std::ostream &out, indent_t indent,
        const IR::MAU::Table *tbl, bitvec source) const {
    auto &action_data_xbar = tbl->resources->action_data_xbar;
    auto &format = tbl->resources->action_format;
    auto &meter_xbar = tbl->resources->meter_xbar;
    auto &meter_use = tbl->resources->meter_format;
    size_t max_total = 0;

    for (auto &rs : action_data_xbar.action_data_locs) {
        if (source.getbit(ActionData::IMMEDIATE) && (rs.source == ActionData::IMMEDIATE))
            max_total++;
        else if (source.getbit(ActionData::ACTION_DATA_TABLE) &&
            (rs.source == ActionData::ACTION_DATA_TABLE))
            max_total++; }

    if (source.getbit(ActionData::METER_ALU)) {
        for (auto &rs : meter_xbar.action_data_locs) {
            if (meter_use.contains_adb_slot(rs.location.type, rs.byte_offset) &&
                tbl->get_attached<IR::MAU::MeterBus2Port>())
                max_total++;
        }
    }

    if (max_total == 0)
        return;

    out << indent << "action_bus: { ";
    size_t total_index = 0;
    for (auto &rs : action_data_xbar.action_data_locs) {
        auto emit_immed = source.getbit(ActionData::IMMEDIATE)
                          && (rs.source == ActionData::IMMEDIATE);
        auto emit_adt = source.getbit(ActionData::ACTION_DATA_TABLE)
                        && (rs.source == ActionData::ACTION_DATA_TABLE);
        if (!emit_immed && !emit_adt) continue;
        auto source_is_immed = (rs.source == ActionData::IMMEDIATE);
        bitvec total_range(0, ActionData::slot_type_to_bits(rs.location.type));
        int byte_sz = ActionData::slot_type_to_bits(rs.location.type) / 8;
        out << rs.location.byte;
        if (byte_sz > 1)
            out << ".." << (rs.location.byte + byte_sz - 1);
        out << " : ";

        // For emitting hash distribution sections on the action_bus directly.  Must find
        // which slices of hash distribution are to go to which bytes, requiring coordination
        // from the input xbar and action format allocation
        if (emit_immed && source_is_immed
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
        } else if (emit_immed && source_is_immed
                   && format.is_byte_offset<ActionData::RandomNumber>(rs.byte_offset)) {
            int rng_unit = tbl->resources->rng_unit();
            out << "rng(" << rng_unit << ", ";
            int lo = rs.byte_offset * 8;
            int hi = lo + byte_sz * 8 - 1;
            out << lo << ".." << hi << ")";
        } else if (emit_immed && source_is_immed
                   && format.is_byte_offset<ActionData::MeterColor>(rs.byte_offset)) {
            for (auto back_at : tbl->attached) {
                auto at = back_at->attached;
                auto *mtr = at->to<IR::MAU::Meter>();
                if (mtr == nullptr) continue;
                out << find_attached_name(tbl, mtr) << " color";
                break;
            }
        } else {
            out << format.get_format_name(rs.location.type, rs.source, rs.byte_offset);
        }
        if (total_index != max_total - 1)
            out << ", ";
        else
            out << " ";
        total_index++;
    }

    bool emit_meter_action_data = source.getbit(ActionData::METER_ALU);

    for (auto &rs : meter_xbar.action_data_locs) {
        if (!emit_meter_action_data) continue;
        if (!meter_use.contains_adb_slot(rs.location.type, rs.byte_offset)) continue;
        auto *at = tbl->get_attached<IR::MAU::MeterBus2Port>();
        BUG_CHECK(at != nullptr, "Trying to emit meter alu without meter alu user");
        cstring ret_name = find_attached_name(tbl, at);
        int byte_sz = ActionData::slot_type_to_bits(rs.location.type) / 8;
        out << rs.location.byte;
        if (byte_sz > 1)
            out << ".." << (rs.location.byte + byte_sz - 1);
        out << " : ";
        out << ret_name;
        out << "(" << (rs.byte_offset * 8) << ".." << ((rs.byte_offset + byte_sz) * 8 - 1) << ")";
        if (total_index != max_total - 1)
            out << ", ";
        else
            out << " ";
        total_index++;
    }

    out << "}" << std::endl;
    BUG_CHECK(total_index == max_total, "max total mismatch");
}

/* Emits the format portion of tind tables and for exact match tables. */
void MauAsmOutput::emit_table_format(std::ostream &out, indent_t indent,
          const TableFormat::Use &use, const TableMatch *tm, bool ternary, bool gateway) const {
    fmt_state fmt;
    out << indent << "format: {";
    int group = (ternary || gateway) ? -1 : 0;
#ifdef HAVE_JBAY
    if (Device::currentDevice() == Device::JBAY && gateway) group = 0;
#endif

    for (auto match_group : use.match_groups) {
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

/* wrapper for a set of tables used with next/hit/miss, mostly so we can overload operator>>
 * to output it with correct asm syntax.  Also has a cstring converter for those cases where
 * it needs to be a single table */
class MauAsmOutput::NextTableSet {
    ordered_set<UniqueId> tables;

 public:
    NextTableSet() = default;
    NextTableSet(const NextTableSet &) = default;
    NextTableSet(NextTableSet &&) = default;
    NextTableSet &operator=(const NextTableSet &) = default;
    NextTableSet &operator=(NextTableSet &&) = default;
    NextTableSet(const IR::MAU::Table *t) {                     // NOLINT(runtime/explicit)
        if (t) tables.insert(t->unique_id()); }
    NextTableSet(UniqueId ui) {                                 // NOLINT(runtime/explicit)
        tables.insert(ui); }

    operator cstring() const {
        BUG_CHECK(tables.size() == 1, "not a single next table");
        return tables.front().build_name(); }
    bool operator==(const NextTableSet &a) const { return tables == a.tables; }
    bool operator<(const NextTableSet &a) const { return tables < a.tables; }
    bool insert(const IR::MAU::Table *t) {
        return t ? tables.insert(t->unique_id()).second : false; }
    bool insert(UniqueId ui) { return tables.insert(ui).second; }
    friend inline std::ostream &operator<<(std::ostream &out, const NextTableSet &nxt) {
        const char *sep = " ";
        if (nxt.tables.size() != 1) {
            BUG_CHECK(nxt.tables.empty() || Device::numLongBranchTags() > 0, "long branch snafu");
            out << '['; }
        for (auto ui : nxt.tables) {
            out << sep << ui;
            sep = ", "; }
        if (nxt.tables.size() != 1) out << (sep+1) << ']';
        return out; }
};

MauAsmOutput::NextTableSet MauAsmOutput::next_for(const IR::MAU::Table *tbl, cstring what) const {
    if (what == "$miss" && tbl->next.count("$try_next_stage"))
        what = "$try_next_stage";

    if (tbl->actions.count(what) && tbl->actions.at(what)->exitAction) {
        BUG_CHECK(!Device::numLongBranchTags() || options.disable_long_branch,
                  "long branch incompatible with exit action");
        NextTableSet rv;
        rv.insert(UniqueId("END"));
        return rv;
    }
    if (!tbl->next.count(what))
        what = "$default";
    if (tbl->next.count(what)) {
        // Jbay specific
        if (tbl->next.at(what) && nxt_tbl) {
            // We want to build this set according to the NextTableProp
            NextTableSet rv;

            // Add tables according to next table propagation (if it has an entry in the map)
            if (nxt_tbl->props.count(tbl->unique_id())) {
                auto prop = nxt_tbl->props.at(tbl->unique_id());
                for (auto id : prop[what])
                    rv.insert(id);
                // Add the run_if_ran set
                for (auto always : prop["$run_if_ran"])
                    rv.insert(always);
                return rv;
            }
        }
        if (tbl->next.at(what) && !tbl->next.at(what)->empty())  // Tofino specific
            return tbl->next.at(what)->front();
    }
    if (Device::numLongBranchTags() > 0 && !options.disable_long_branch) {
        // Always add run_if_ran set
        NextTableSet rv;
        if (nxt_tbl->props.count(tbl->unique_id())) {
            auto prop = nxt_tbl->props.at(tbl->unique_id());
            for (auto always : prop["$run_if_ran"])
                rv.insert(always);
        }
        return rv;
    }
    return default_next.next_in_thread_uniq_id(tbl);
}

/* Adjusted to consider actions coming from hash distribution.  Now hash computation
   instructions have specific tags so that we can output the correct hash distribution
   unit corresponding to it. */
class MauAsmOutput::EmitAction : public Inspector, public TofinoWriteContext {
    const MauAsmOutput          &self;
    std::ostream                &out;
    const IR::MAU::Table        *table;
    indent_t                    indent;
    const char                  *sep = nullptr;
    std::map<cstring, cstring>  alias;
    bool                        is_empty;

    /**
     * Outputs the next table configuration for this action:
     * Two possible nodes to be output:
     *     - next_table: The next table to be run with the table hits.  Either a name of a
     *           table or an offset into the hit table.
     *     - next_table_miss: The next table to be run when the table misses.
     *
     * If the table behavior is identical on hit or miss, then the next_table_miss is not
     * output.  If the table is miss_action_only, then no next_table node is output.
     */
    void next_table(const IR::MAU::Action *act, int mem_code) {
        if (table->hit_miss_p4()) {
            out << indent << "- next_table_miss: ";
            if (act->exitAction)
                out << "END" << std::endl;
            else
                out << self.next_for(table, "$miss") << std::endl;
            if (act->miss_action_only)
                return;
        }

        if (table->action_chain()) {
            if (act->miss_action_only) {
                out << indent << "- next_table_miss: "
                    << self.next_for(table, act->name.originalName) << std::endl;
                return;
            }
        }

        out << indent << "- next_table: ";
        if (table->action_chain()) {
            int ntb = table->resources->table_format.next_table_bits();
            if (ntb == 0) {
                out << mem_code;
            } else if (ntb <= ceil_log2(TableFormat::NEXT_MAP_TABLE_ENTRIES)) {
                safe_vector<NextTableSet> next_table_map;
                self.next_table_non_action_map(table, next_table_map);
                for (auto entry : next_table_map) {
                }
                NextTableSet act_set = self.next_for(table, act->name.originalName);
                auto it = std::find(next_table_map.begin(), next_table_map.end(), act_set);
                BUG_CHECK(it != next_table_map.end(), "Next table cannot be associated");
                out << (it - next_table_map.begin());
            } else {
                out << self.next_for(table, act->name.originalName);
            }
        } else {
            out << "0";
        }
        out << std::endl;
    }

    /**
     * In order to fill out the context JSON nodes in the pack format:
     *    - is_mod_field_conditionally_value
     *    - mod_field_conditionally_mask_field_name
     *
     * which are required for the src1 & mask, described in action_format.h in the
     * Parameter class, this function is required.  This dumps out a map:
     *
     *    - key - The names of conditional parameters in an action
     *    - value - The regions of action format that are conditionally controlled by this key
     *
     * I think this is fairly ugly, but was the only concise way to correctly handle all
     * corner cases, rather than having the assembler have to work through potential bitmasked-set
     * instructions in order to potentially find which regions are controlled.
     */
    void mod_cond_value(const IR::MAU::Action *act) {
        auto mod_cond_map = table->resources->action_format.mod_cond_values.at(act->name);
        if (mod_cond_map.empty())
            return;
        out << indent << "- mod_cond_value: {";
        cstring sep = "";
        for (auto entry : mod_cond_map) {
            out << sep << entry.first << ": [ ";
            cstring sep2 = "";
            for (int i = 0; i < ActionData::AD_LOCATIONS; i++) {
                cstring location = i == ActionData::ACTION_DATA_TABLE ? "action_data_table"
                                                                      : "immediate";
                for (auto br : bitranges(entry.second.at(i))) {
                    out << sep2 << location << "(" << br.first << ".." << br.second << ")";
                    sep2 = ", ";
                }
                sep = ", ";
            }
            out << " ]";
        }
        out << " }" << std::endl;
    }

    void action_context_json(const IR::MAU::Action *act) {
        if (act->args.size() > 0) {
            // Use the more verbose, multiline format if we have user annotations.
            bool verbose = false;
            for (auto arg : act->args)
                verbose |= has_user_annotation(arg);

            out << indent++ << "- p4_param_order:";
            if (verbose) out << std::endl;
            else
              out << " { ";

            bool first = true;
            for (auto arg : act->args) {
                if (verbose) {
                    out << indent++ << arg->name << ":" << std::endl;
                    out << indent << "width: " << arg->type->width_bits() << std::endl;
                    emit_user_annotation_context_json(out, indent, arg);
                    indent--;
                } else {
                    if (!first) out << ", ";
                    out << arg->name << ": " << arg->type->width_bits();
                }

                first = false;
            }

            if (!verbose) out << " }" << std::endl;
            indent--;
        }
    }
    bool preorder(const IR::MAU::Action *act) override {
        for (auto call : act->stateful_calls) {
            auto *at = call->attached_callee;
            if (call->index == nullptr) continue;
            if (auto aa = call->index->to<IR::MAU::ActionArg>()) {
                alias[aa->name] = self.indirect_address(at);
            }
        }
        auto &instr_mem = table->resources->instr_mem;
        out << indent << canon_name(act->externalName());
        auto *vliw_instr = getref(instr_mem.all_instrs, act->name.name);
        BUG_CHECK(vliw_instr, "failed to allocate instruction memory for %s", act);
        out << "(" << vliw_instr->mem_code << ", " << vliw_instr->gen_addr() << "):" << std::endl;
        action_context_json(act);
        out << indent << "- default_" << (act->miss_action_only ? "only_" : "") << "action: {"
            << " allowed: " << std::boolalpha << (act->default_allowed || act->hit_path_imp_only);
        if (!act->default_allowed || act->hit_path_imp_only)
            out << ", reason: " << act->disallowed_reason;
        if (act->is_constant_action)
            out << ", is_constant: " << act->is_constant_action;
        out << " }" << std::endl;
        out << indent << "- handle: 0x" << hex(act->handle) << std::endl;
        next_table(act, vliw_instr->mem_code);
        mod_cond_value(act);
        is_empty = true;
        emit_user_annotation_context_json(out, indent, act, true);
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
            auto *at = call->attached_callee;
            out << indent << "- " << self.find_attached_name(table, at) << '(';
            sep = "";
            auto *salu = at->to<IR::MAU::StatefulAlu>();
            if (auto *salu_act = salu ? salu->calledAction(table, act) : nullptr) {
                out << canon_name(salu_act->name);
                sep = ", ";
            } else if (act->meter_types.count(at->unique_id()) > 0) {
                // Currently dumps meter type as number, because the color aware stuff does not
                // have a name in asm, nor does STFUL_CLEAR
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
                    BUG("%s: Index %s for %s is not supported", at->srcInfo, call->index, at->name);
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
        out << indent << canon_name(act->name);
        if (act->inst_code >= 0) out << " " << act->inst_code;
        out << ":" << std::endl;
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
        unsigned use_type = isWrite() ? PHV::FieldUse::WRITE : PHV::FieldUse::READ;
        PHV::FieldUse use(use_type);
        if (sep) {
            le_bitrange bits;
            if (auto field = self.phv.field(expr, &bits)) {
                out << sep << canon_name(field->externalName());
                int count = 0;
                field->foreach_alloc(bits, table, &use, [&](const PHV::Field::alloc_slice &) {
                    count++;
                });
                if (count == 1) {
                    field->foreach_alloc(table, &use, [&](const PHV::Field::alloc_slice &alloc) {
                        if (!(alloc.field_bit <= bits.lo && alloc.field_hi() >= bits.hi))
                            return;
                        bool single_loc = (alloc.width == field->size);
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

    /**
     * HashDist IR object have already been converted in InstructionAdjustment
     */
    void handle_hash_dist(const IR::Expression *expr) {
        int lo = -1; int hi = -1;
        const IR::MAU::HashDist *hd = nullptr;
        bool is_wrapped = false;
        if (auto sl = expr->to<IR::Slice>()) {
            hd = sl->e0->to<IR::MAU::HashDist>();
            lo = sl->getL();
            hi = sl->getH();
        } else if (auto wr_sl = expr->to<IR::MAU::WrappedSlice>()) {
            hd = wr_sl->e0->to<IR::MAU::HashDist>();
            lo = wr_sl->getL();
            is_wrapped = true;
        } else {
            hd = expr->to<IR::MAU::HashDist>();
            lo = 0;
            hi = hd->type->width_bits() - 1;
        }

        BUG_CHECK(hd && !hd->units.empty(), "Hash Dist object %1% not correctly converted in "
                  "InstructionAdjustment", hd);
        out << sep << "hash_dist(";
        std::string sep2 = "";
        for (auto unit : hd->units) {
            out << sep2 << unit;
            sep2 = ", ";
        }
        out << sep2 << lo;
        if (!is_wrapped)
            out << ".." << hi;
        // This extra lo has to be printed out because the hash_dist has to understand this as
        // a range from deposit-field, even though the only thing that matters in this source
        // is the first lo, the range of the deposit-field is determined on the destination
        // See p4c-2153
        else
            out << ".." << lo;
        out << ")";
    }


    void handle_random_number(const IR::Expression *expr) {
        int lo = -1;  int hi = -1;
        const IR::MAU::RandomNumber *rn = nullptr;
        bool is_wrapped = false;
        if (auto sl = expr->to<IR::Slice>()) {
            rn = sl->e0->to<IR::MAU::RandomNumber>();
            lo = sl->getL();
            hi = sl->getH();
        } else if (auto wr_sl = expr->to<IR::MAU::WrappedSlice>()) {
            rn = wr_sl->e0->to<IR::MAU::RandomNumber>();
            lo = wr_sl->getL();
            is_wrapped = true;
        } else {
            rn = expr->to<IR::MAU::RandomNumber>();
            lo = 0;
            hi = rn->type->width_bits() - 1;
        }
        assert(sep);
        BUG_CHECK(rn != nullptr && rn->allocated(), "Printing an invalid random number in the "
                  "assembly");
        out << sep << "rng(";
        out << rn->rng_unit << ", ";
        out << lo;
        if (!is_wrapped)
            out << ".." << hi;
        // This extra lo has to be printed out because the hash_dist has to understand this as
        // a range from deposit-field, even though the only thing that matters in this source
        // is the first lo, the range of the deposit-field is determined on the destination
        // See p4c-2153
        else
            out << ".." << lo;
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
        } else if (sl->e0->is<IR::MAU::RandomNumber>()) {
            handle_random_number(sl);
            return false;
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
        if (auto mo = sl->e0->to<IR::MAU::MultiOperand>()) {
            visit(mo);
        } else if (sl->e0->is<IR::MAU::HashDist>()) {
            handle_hash_dist(sl);
            return false;
        } else {
            BUG("Only HashDist, RandomNumber, and MultiOperands can be wrapped");
        }
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
    bool preorder(const IR::MAU::ConditionalArg *) override {
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
    bool preorder(const IR::MAU::SaluFunction *fn) override {
        assert(sep);
        out << sep << fn->name;
        sep = "(";
        visit(fn->expr, "expr");
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
    bool preorder(const IR::MAU::StatefulCounter *sc) override {
        assert(sep);
        out << sep << self.find_attached_name(table, sc->attached);
        out << " address";
        sep = ", ";
        return false; }
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
    bool preorder(const IR::MAU::IXBarExpression *e) override {
        if (findContext<IR::MAU::Action>()) {
            out << sep << "ixbar /* " << e->expr << " */";
        } else if (findContext<IR::MAU::SaluAction>()) {
            out << sep << (e->bit ? "phv_hi" : "phv_lo");
        } else {
            BUG("IXBarExpression %s not in an action?", e);
        }
        sep = ", ";
        return false; }
    bool preorder(const IR::Expression *exp) override {
        handle_phv_expr(exp);
        return false;
    }
    bool preorder(const IR::Node *n) override { BUG("Unexpected node %s in EmitAction", n); }

 public:
    EmitAction(const MauAsmOutput &s, std::ostream &o, const IR::MAU::Table *tbl, indent_t i)
    : self(s), out(o), table(tbl), indent(i) { visitDagOnce = false; }
};

void MauAsmOutput::TableMatch::init_proxy_hash(const IR::MAU::Table *tbl) {
    proxy_hash = true;
    for (auto match_info : tbl->resources->table_format.match_groups[0].match) {
        const IXBar::Use::Byte &byte = match_info.first;
        const bitvec &byte_layout = match_info.second;

        int start_bit = byte_layout.ffs();
        int initial_bit = start_bit;
        do {
            int end_bit = byte_layout.ffz(start_bit);
            int lo = byte.lo + (start_bit - initial_bit);
            int hi = byte.lo + (end_bit - initial_bit) - 1;
            le_bitrange bits = { lo, hi };
            proxy_hash_fields.emplace_back(bits);
            start_bit = byte_layout.ffs(end_bit);
        } while (start_bit >= 0);
    }
}

/* Information on which tables are matched and ghosted.  This is used by the emit table format,
   and the hashing information.  Comes directly from the table_format object in the resources
   of a table*/
MauAsmOutput::TableMatch::TableMatch(const MauAsmOutput &, const PhvInfo &phv,
        const IR::MAU::Table *tbl) /*: self(s)*/ {
    if (tbl->resources->table_format.match_groups.size() == 0)
        return;
    if (tbl->layout.proxy_hash) {
        init_proxy_hash(tbl);
        return;
    }

    identity_hash = tbl->resources->table_format.identity_hash;

    // Determine which fields are part of a table match.  If a field partially ghosted,
    // then this information is contained within the bitvec and the int of the match_info
    for (auto match_info : tbl->resources->table_format.match_groups[0].match) {
        const IXBar::Use::Byte &byte = match_info.first;
        const bitvec &byte_layout = match_info.second;

        safe_vector<Slice> single_byte_match_fields;
        for (auto &fi : byte.field_bytes) {
            bitvec total_cont_loc = fi.cont_loc();
            int first_cont_bit = total_cont_loc.min().index();
            bitvec layout_shifted
                = byte_layout.getslice(byte_layout.min().index() / 8 * 8, 8);

            auto field = phv.field(fi.get_use_name());
            le_bitrange field_bits = { fi.lo, fi.hi };
            int bits_seen = 0;
            PHV::FieldUse use(PHV::FieldUse::READ);
            // It is not a guarantee, especially in Tofino2 due to live ranges being different
            // that a FieldInfo is not corresponding to a single alloc_slice object
            field->foreach_alloc(field_bits, tbl, &use, [&](const PHV::Field::alloc_slice &sl) {
                int lo = sl.field_bit;
                int hi = sl.field_hi();
                bitvec cont_loc = total_cont_loc & bitvec(bits_seen + first_cont_bit, sl.width);
                bitvec matched_bits = layout_shifted & cont_loc;
                bits_seen += sl.width;
                // If a byte is partially ghosted, then currently the bits from the lsb are
                // ghosted so the algorithm always shrinks from the bottom
                if (matched_bits.empty()) {
                    return;
                } else if (matched_bits != cont_loc) {
                    lo += (matched_bits.min().index() - cont_loc.min().index());
                }
                Slice asm_sl(phv, fi.get_use_name(), lo, hi);
                if (asm_sl.bytealign() != (matched_bits.min().index() % 8))
                    BUG("Byte alignment for matching does not match up properly");
                single_byte_match_fields.push_back(asm_sl);
            });
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

        for (auto &fi : byte.field_bytes) {
            bitvec cont_loc = fi.cont_loc();
            bitvec layout_shifted
                = byte_layout.getslice(byte_layout.min().index() / 8 * 8, 8);
            bitvec total_cont_loc = fi.cont_loc();
            int first_cont_bit = total_cont_loc.min().index();
            auto field = phv.field(fi.get_use_name());
            le_bitrange field_bits = { fi.lo, fi.hi };
            int bits_seen = 0;
            // It is not a guarantee, especially in Tofino2 due to live ranges being different
            // that a FieldInfo is not corresponding to a single alloc_slice object
            PHV::FieldUse use(PHV::FieldUse::READ);
            field->foreach_alloc(field_bits, tbl, &use, [&](const PHV::Field::alloc_slice &sl) {
                int lo = sl.field_bit;
                int hi = sl.field_hi();
                bitvec cont_loc = total_cont_loc & bitvec(bits_seen + first_cont_bit, sl.width);
                bitvec ghosted_bits = layout_shifted & cont_loc;
                bits_seen += sl.width;
                if (ghosted_bits.empty())
                    return;
                else if (ghosted_bits != cont_loc)
                    hi -= (cont_loc.max().index() - ghosted_bits.max().index());
                Slice asm_sl(phv, fi.get_use_name(), lo, hi);
                if (asm_sl.bytealign() != (ghosted_bits.min().index() % 8))
                    BUG("Byte alignment for ghosting does not match up properly");
                ghost_bits.push_back(asm_sl);
            });
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
 *  a gateway (A HashAction table):
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
bool MauAsmOutput::emit_gateway(std::ostream &out, indent_t gw_indent,
        const IR::MAU::Table *tbl, bool no_match, NextTableSet next_hit,
        NextTableSet &gw_miss) const {
    CollectGatewayFields collect(phv, &tbl->resources->gateway_ixbar);
    tbl->apply(collect);
    bool gw_can_miss = false;
    if (collect.compute_offsets()) {
        bool have_xor = false;
        out << gw_indent << "match: {";
        const char *sep = " ";
        PHV::FieldUse use(PHV::FieldUse::READ);
        for (auto &f : collect.info) {
            auto *field = f.first.field();
            if (!f.second.xor_offsets.empty())
                have_xor = true;
            for (auto &offset : f.second.offsets) {
                field->foreach_alloc(offset.second, tbl, &use,
                        [&](const PHV::Field::alloc_slice &sl) {
                    out << sep << (offset.first + (sl.field_bit - offset.second.lo));
                    out << ": " << Slice(field, sl.field_bits());
                    sep = ", ";
                });
            }
        }
        out << (sep+1) << "}" << std::endl;
        if (have_xor) {
            out << gw_indent << "xor: {";
            sep = " ";
            for (auto &f : collect.info) {
                auto *field = f.first.field();
                for (auto &offset : f.second.xor_offsets) {
                    field->foreach_alloc(offset.second, tbl, &use,
                                         [&](const PHV::Field::alloc_slice &sl) {
                        out << sep << (offset.first + (sl.field_bit - offset.second.lo));
                        out << ": " << Slice(field, sl.field_bits());
                        sep = ", ";
                    });
                }
            }
            out << (sep+1) << "}" << std::endl;
        }
        if (collect.need_range)
            out << gw_indent << "range: 4" << std::endl;
        BuildGatewayMatch match(phv, collect);
        std::map<cstring, NextTableSet> cond_tables;
        for (auto &line : tbl->gateway_rows) {
            out << gw_indent;
            if (line.first) {
                line.first->apply(match);
                out << match << ": ";
            } else {
                out << "miss: ";
            }
            NextTableSet nxt_tbl;
            if (line.second) {
                if (no_match) {
                    out << "run_table";
                    gw_miss = nxt_tbl = next_for(tbl, line.second);
                    gw_can_miss = true;
                } else {
                    nxt_tbl = next_for(tbl, line.second);
                    out << next_for(tbl, line.second);
                }
            } else {
                if (no_match) {
                    out << next_hit;
                    nxt_tbl = next_hit;
                } else {
                    out << "run_table";
                    nxt_tbl = tbl;
                    gw_can_miss = true;
                }
            }
            out << std::endl;
            bool split_gateway = (line.second == "$gwcont");
            auto cond = (line.second.isNullOrEmpty() || split_gateway) ?
                "$torf" : line.second;
            cond_tables[cond] = nxt_tbl;
        }
        if (tbl->gateway_rows.back().first) {
            // FIXME -- should check to see if this miss is possible (if there exists a
            // possible input that would miss every match line) and only output this then.
            out << gw_indent << "miss: run_table" << std::endl;
            gw_can_miss = true;
        }
        if (tbl->gateway_cond) {
            out << gw_indent++ << "condition: " << std::endl;
            out << gw_indent << "expression: \"(" << tbl->gateway_cond << ")\"" << std::endl;
            if (cond_tables.count("$true"))
                out << gw_indent << "true: " << cond_tables["$true"] << std::endl;
            else if (cond_tables.count("$torf"))
                out << gw_indent << "true: " << cond_tables["$torf"] << std::endl;
            if (cond_tables.count("$false"))
                out << gw_indent << "false: " << cond_tables["$false"] << std::endl;
            else if (cond_tables.count("$torf"))
                out << gw_indent << "false: " << cond_tables["$torf"] << std::endl; }
    } else {
        WARNING("Failed to fit gateway expression for " << tbl->name);
    }
    return gw_can_miss;
}

/** This allocates a gateway that always hits, with a single (possible noop) action, in order
 * for the table to always go through the the hit pathway.
 * FIXME -- why do we use this for a noop action?  A noop does not require the hit path, so
 * could use the miss path and save the gateway (power if nothing else).  */
void MauAsmOutput::emit_no_match_gateway(std::ostream &out, indent_t gw_indent,
        const IR::MAU::Table *tbl) const {
    BUG_CHECK(tbl->actions.size() <= 1, "not an always hit hash_action table");
    cstring act_name = tbl->actions.empty() ? "" : tbl->actions.begin()->first;
    auto nxt_tbl = next_for(tbl, act_name);
    out << gw_indent << "0x0: " << nxt_tbl << std::endl;
    out << gw_indent << "miss: " << nxt_tbl << std::endl;
    out << gw_indent++ << "condition: " << std::endl;
    out << gw_indent << "expression: \"true(always hit)\"" << std::endl;
    out << gw_indent << "true: " << nxt_tbl << std::endl;
    out << gw_indent << "false: " << nxt_tbl << std::endl;
}

void MauAsmOutput::emit_table_context_json(std::ostream &out, indent_t indent,
        const IR::MAU::Table *tbl) const {
    if (tbl->suppress_context_json) return;
    auto p4Name = cstring::to_cstring(canon_name(tbl->match_table->externalName()));
    out << indent << "p4: { name: " << p4Name;
    if (auto k = tbl->match_table->getConstantProperty("size"))
        out << ", size: " << k->asInt();
    if (tbl->layout.pre_classifier || tbl->layout.alpm)
        out << ", match_type: alpm";
    if (tbl->is_compiler_generated)
        out << ", hidden: true";
    for (auto back_at : tbl->attached) {
        auto at = back_at->attached;
        if (auto ap = at->to<IR::MAU::ActionData>())
            if (!ap->direct)
                out << ", action_profile: " << canon_name(ap->name);
    }
    // Output 'disable_atomic_modify' pragma if present. This will to be plugged
    // into the context json for the driver. COMPILER-944
    if (auto m = tbl->match_table) {
        if (auto a = m->getAnnotations()->getSingle("disable_atomic_modify")) {
            if (a->expr.size() > 0 && a->expr[0]->to<IR::Constant>()) {
                auto val = a->expr[0]->to<IR::Constant>()->asInt();
                if (val == 1) out << ", disable_atomic_modify : true";
                else if (val == 0) out << ", disable_atomic_modify : false";
                else
                    ::warning(BFN::ErrorType::WARN_PRAGMA_USE,
                              "Annotation ignored because parameter %1% is invalid. "
                              "Only the values 0 and 1 are valid.",
                            a->expr[0]);
            } else {
                ::warning(BFN::ErrorType::WARN_PRAGMA_USE,
                          "%1%: disable_atomic_modify annotation ignored. Invalid parameters.", a);
            }
        }
    }
    out << " }" << std::endl;

    if (tbl->match_key.empty())
        return;

    out << indent++ <<  "p4_param_order: " << std::endl;
    int p4_param_index = 0;
    for (auto ixbar_read : tbl->match_key) {
        if (!ixbar_read->for_match())
            continue;
        // do not dump param that is generated by compiler, e.g., alpm partition index
        if (ixbar_read->p4_param_order < 0)
            continue;
        auto *expr = ixbar_read->expr;
        std::map<int, int> slices;
        if (auto slice = expr->to<IR::Slice>()) {
            expr = slice->e0;
            auto hi = slice->e1->to<IR::Constant>();
            auto lo = slice->e2->to<IR::Constant>();

            BUG_CHECK(lo != nullptr && hi != nullptr,
                    "Invalid match key slice %1%[%2%:%3%]", expr, slice->e1, slice->e2);

            auto v_lo = lo->asInt();
            auto v_hi = hi->asInt();

            BUG_CHECK(v_lo <= v_hi, "Invalid match key slice range %1% %2%", v_lo, v_hi);

            slices.emplace(v_lo, v_hi - v_lo + 1);
        }

        auto phv_field = phv.field(expr);
        // Replace any alias nodes with their original sources, in order to
        // ensure the original names are emitted.
        auto full_size = phv_field->size;

        // Check for @name annotation.
        cstring name = phv_field->externalName();

        cstring annName = "";
        if (auto ann = ixbar_read->getAnnotation(IR::Annotation::nameAnnotation)) {
            annName = IR::Annotation::getName(ann);
            // P4_14-->P4_16 translation names valid matches with a
            // "$valid$" suffix (note the trailing "$").  However, Brig
            // and pdgen use "$valid".
            if (annName.endsWith("$valid$"))
                annName = annName.substr(0, annName.size() - 1);

            // XXX(cole): This is a hack to remove slices from key annName annotations,
            // eg. "foo.bar[3:0]" becomes "foo.bar".
            // XXX(hanw): The hack is here because frontend uses @name annotation to keep
            // the original name of the table key and annotation does not keep the
            // IR structure of a slice. The original name of the table key must be
            // kept in case an optimization renames the table key name (not sure if
            // there is optimization that does this).
            std::string s(annName.c_str());
            std::smatch sm;
            std::regex sliceRegex(R"(\[([0-9]+):([0-9]+)\])");
            std::regex_search(s, sm, sliceRegex);
            if (sm.size() == 3) {
                auto newAnnName = s.substr(0, sm.position(0));
                // XXX(cole): It would be nice to report srcInfo here.
                ::warning(BFN::ErrorType::WARN_SUBSTITUTION,
                          "%1%: Table key name not supported.  "
                          "Replacing \"%2%\" with \"%3%\".", tbl, annName, newAnnName);
                annName = newAnnName;
            }

            LOG3(ann << ": setting external annName of key " << ixbar_read
                 << " to " << annName);
        }

        // If fields dont have slices we add the entire field starting at bit 0
        if (slices.empty())
            slices[0] = full_size;

        // Whether the BFA output for this match component will be split across multiple lines.
        // This results in code that is more complex, but maintains compactness and readability of
        // the BFA for the common case when we don't have user annotations.
        bool multiline = has_user_annotation(ixbar_read);
        auto item_sep = [&](std::ostream &out) -> std::ostream & {
            if (multiline) out << std::endl << indent;
            else
                out << ", ";
            return out;
        };

        for (auto sl : slices) {
            out << indent++ << canon_name(name) << ":";
            if (multiline) out << std::endl << indent;
            else
              out << " { ";

            // 'atcam_partition_index' match type is synonym to 'exact' match
            // from the context.json's perspective.  It carries one more bit of
            // information about which field is used as the
            // atcam_partition_index and this information is conveyed to
            // low-level driver via the 'partition_field_name' attribute under
            // the algorithm tcam node. As a result, we print
            // 'atcam_partition_index' as 'exact' here.
            auto match_type = ixbar_read->match_type.name;
            if (match_type == "atcam_partition_index") match_type = "exact";
            out << "type: " << match_type << item_sep;

            out << "size: " << sl.second << item_sep;

            // Slices are used in keys (only) in p4-16, while masks are used
            // (only) in p4-14. For BF-RT, we consider a slice with an
            // annotation  as a separate field and set the size and full_size to
            // be the same value. The key name carries the annotated name.
            bool setKeyName = false;
            if (!annName.isNullOrEmpty()) {
                setKeyName = (cstring::to_cstring(canon_name(name))
                        != cstring::to_cstring(canon_name(annName)));
            }
            auto start_bit = sl.first;
            out << "full_size: " << full_size;
            if (setKeyName)
                out << item_sep << "key_name: \"" << canon_name(annName) << "\"";
            if (start_bit > 0)
                out << item_sep << "start_bit: " << start_bit;
            if (multiline) out << std::endl;
            emit_user_annotation_context_json(out, indent, ixbar_read);
            if (!multiline) out << " }" << std::endl;
            indent--;
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
        if (k->match_type.name == "lpm")
            P4C_UNIMPLEMENTED("Static entries are not supported for lpm-match"
                ". Needs p4 language support to specify prefix length"
                " with the static entry.");
    }

    out << indent++ << "context_json:" << std::endl;
    out << indent << "static_entries:" << std::endl;
    int priority = 0;  // The order of entries in p4 program determine priority
    for (auto entry : tbl->entries_list->entries) {
        auto method_call = entry->action->to<IR::MethodCallExpression>();
        BUG_CHECK(method_call, "Action is not specified for a static entry");

        auto method = method_call->method->to<IR::PathExpression>();
        auto path = method->path;
        size_t key_index = 0, param_index = 0;
        out << indent++ << "- priority: " << priority++ << std::endl;
        out << indent << "match_key_fields_values:" << std::endl;
        for (auto key : entry->getKeys()->components) {
            ERROR_CHECK(key_index < tbl->match_key.size(), ErrorType::ERR_INVALID,
                        "key. Static entry has more keys than those specified "
                        "in match field for table %2%.", key, tbl->externalName());
            auto match_key = tbl->match_key[key_index];
            if (match_key->match_type == "selector" || match_key->match_type == "dleft_hash") {
                key_index++;
                continue; }
            auto match_key_size = phv.field(match_key->expr)->size;
            // Set a mask with all 1's for size of match key
            bitvec match_key_mask(0, match_key_size);
            auto match_key_name = phv.field(match_key->expr)->externalName();
            // Use annotation names if present
            if (auto ann = match_key->getAnnotation(IR::Annotation::nameAnnotation)) {
                auto annName = IR::Annotation::getName(ann);
                // Remove slicing info if present
                std::string s(annName.c_str());
                std::smatch sm;
                std::regex sliceRegex(R"(\[([0-9]+):([0-9]+)\])");
                std::regex_search(s, sm, sliceRegex);
                if (sm.size() == 3) {
                    annName = s.substr(0, sm.position(0));
                }
                match_key_name = annName;
            }
            // Remove trailing `$` from $valid$'s. These are removed from match_key_fields
            // to be consistent with PD Gen which expects only $valid suffix.
            if (match_key_name.endsWith("$valid$"))
                match_key_name = match_key_name.substr(0, match_key_name.size() - 1);
            out << indent++ << "- field_name: " << canon_name(match_key_name) << std::endl;
            if (auto b = key->to<IR::BoolLiteral>()) {
                out << indent << "value: \"0x" << (b->value ? 1 : 0) << "\"" <<  std::endl;
                if (match_key->match_type == "ternary")
                    out << indent << "mask: \"0x1\"" << std::endl;
            } else if (key->to<IR::Constant>()) {
                out << indent << "value: \"0x" << std::hex << key << std::dec << "\"" << std::endl;
                if (match_key->match_type == "ternary") {
                    out << indent << "mask: \"0x"
                        << std::hex << match_key_mask << std::dec << "\"" << std::endl;
                }
            } else if (auto ts = key->to<IR::Mask>()) {
                // This error should be caught in front end as an invalid key
                // expression
                ERROR_CHECK(match_key->match_type == "ternary", ErrorType::ERR_INVALID,
                            "mask value specified in static entry for field %2% a "
                            "non ternary match type in table %3%.",
                            key, canon_name(match_key_name), tbl->externalName());
                // Ternary match with value and mask specified
                // e.g. In p4 - "15 &&& 0xff" where 15 is value and 0xff is mask
                if (auto val = ts->left->to<IR::Constant>()) {
                    out << indent << "value: \"0x" << std::hex
                        << val << std::dec << "\"" << std::endl;
                }
                if (auto mask = ts->right->to<IR::Constant>()) {
                    out << indent << "mask: \"0x" << std::hex
                        << mask->value << std::dec << "\"" << std::endl;
                }
            } else if (key->to<IR::DefaultExpression>()) {
                if (match_key->match_type == "range") {
                    out << indent << "range_start: \"0x0\"" << std::endl;
                    auto range_bit_width = match_key->expr->type->width_bits();
                    auto range_end = ((IR::Constant(1) << range_bit_width) - 1).clone();
                    out << indent << "range_end: \"0x"
                        << std::hex << range_end << std::dec << "\"" << std::endl;

                } else {
                    out << indent << "value: \"0x0\"" << std::endl;
                    if (match_key->match_type == "ternary") {
                        out << indent << "mask: \"0x0\"" << std::endl;
                    }
                }
            } else if (auto r = key->to<IR::Range>()) {
                // This error should be caught in front end as an invalid key
                // expression
                ERROR_CHECK(match_key->match_type == "range", ErrorType::ERR_INVALID,
                            "range value specified in static entry for field %2% a "
                            "non range match type in table %3%.",
                            tbl, canon_name(match_key_name), tbl->externalName());
                // Extract start and end values from range node
                if (auto range_start = r->left->to<IR::Constant>())
                    out << indent << "range_start: \"0x"
                        << std::hex << range_start->value << std::dec << "\"" << std::endl;
                if (auto range_end = r->right->to<IR::Constant>())
                    out << indent << "range_end: \"0x"
                        << std::hex << range_end->value << std::dec << "\"" << std::endl;
            } else {
                P4C_UNIMPLEMENTED("Static entries are only supported for "
                    "match keys with bit-string type");
            }
            key_index++;
            indent--;
        }

        for (auto action : Values(tbl->actions)) {
            if (action->name.name == path->name) {
                out << indent << "action_handle: 0x" << hex(action->handle) << std::endl;
                break;
            }
        }

        out << indent << "is_default_entry: false" <<  std::endl;
        auto num_mc_args = method_call->arguments->size();
        out << indent << "action_parameters_values:";
        if (num_mc_args > 0) {
            auto mc_type = method->type->to<IR::Type_Action>();
            auto param_list = mc_type->parameters->parameters;
            if (param_list.size() != num_mc_args)
            BUG_CHECK((param_list.size() == num_mc_args),
                "Total arguments on method call differ from those on method"
                " parameters in table %s", tbl->name);
            out << std::endl;
            for (auto param : *method_call->arguments) {
                auto p = param_list.at(param_index++);
                auto param_name = p->name;
                out << indent++ << "- parameter_name: " << param_name << std::endl;
                out << indent << "value: \"0x" << std::hex;
                if (param->expression->type->to<IR::Type_Boolean>()) {
                    auto boolExpr = param->expression->to<IR::BoolLiteral>();
                    out << (boolExpr->value ? 1 : 0);
                } else {
                    out << param;
                }
                out << std::dec << "\"" << std::endl;
                indent--;
            }
        } else {
            out << " []" << std::endl;
        }
        indent--;
    }
}

void MauAsmOutput::next_table_non_action_map(const IR::MAU::Table *tbl,
         safe_vector<NextTableSet> &next_table_map) const {
     std::set<NextTableSet> possible_next_tables;
     for (auto act : Values(tbl->actions)) {
         if (act->miss_action_only) continue;
         possible_next_tables.insert(next_for(tbl, act->name.originalName));
     }
     for (auto &nt : possible_next_tables) {
         next_table_map.push_back(nt);
     }
}

void MauAsmOutput::emit_atcam_match(std::ostream &out, indent_t indent,
        const IR::MAU::Table *tbl) const {
    out << indent << "number_partitions: "
        << tbl->layout.partition_count << std::endl;
    if (tbl->layout.alpm) {
        out << indent << "subtrees_per_partition: "
            << tbl->layout.subtrees_per_partition << std::endl;
        auto tbl_entries = tbl->match_table->getConstantProperty("size") ?
                            tbl->match_table->getConstantProperty("size")->asInt() : 0;
        /* table size is optional in p4-14. first check if it comes from p4, otherwise
         * figure it out based on allocation */
        if (tbl_entries == 0) {
            auto unique_id = tbl->unique_id();
            auto &mem = tbl->resources->memuse.at(unique_id);
            auto rams = 0;
            for (auto &row : mem.row) {
                rams += row.col.size();
            }
            tbl_entries = rams * tbl->resources->table_format.match_groups.size() * 1024;
        }
        out << indent << "bins_per_partition: " <<
          tbl_entries/tbl->layout.partition_count + 1 << std::endl;
    }
    for (auto ixr : tbl->match_key) {
        if (ixr->partition_index) {
            out << indent << "partition_field_name: " <<
                canon_name(phv.field(ixr->expr)->externalName()) << std::endl;
            break;
        }
    }
}

// PRAGMA bind_indirect_res_to_match support
// An action profile can have actions with parameters from either action data or
// an indirect resource (stateful/meter/counter). For these indirect resources,
// the driver needs to know when to generate API's against the match table using
// the action profile.  This is specified with the 'bind_indirect_res_to_match'
// pragma.
//
// E.g.
// @pragma bind_indirect_res_to_match r
// @pragma bind_indirect_res_to_match mtr
// @pragma bind_indirect_res_to_match ctr
// action_profile selector_profile {
//     actions {
//         tcp_sport_modify;
//         tcp_dport_modify;
//         ipsa_modify;
//         ipda_modify;
//         ipds_modify;
//         ipttl_modify;
//     }
//     size : ACTION_COUNT;
// }
//
// The context json node 'ap_bind_indirect_res_to_match' within the
// 'match_table' must be populated with all indirect resources associated with
// the action profile
//
// The pragma(s) attached to the action profile get(s) passed in through the
// table attached memory. We first check the presence of this pragma and
// validate each resource associated with the pragma as attached to the table
// actions. A valid resource is directly output in the bfa as a context json
// node syntax which the assembler plugs in to the match table context json
// Associated JIRA - P4C-1528
void MauAsmOutput::emit_indirect_res_context_json(std::ostream &out,
        indent_t indent, const IR::MAU::Table *tbl) const {
    ordered_set<cstring> bind_res;
    for (auto back_at : tbl->attached) {
        auto at = back_at->attached;
        for (auto annot : at->annotations->annotations) {
            if (annot->name != "bind_indirect_res_to_match") continue;
            BUG_CHECK((at->is<IR::MAU::ActionData>() && at->direct == false)
                      || at->is<IR::MAU::Selector>(),
                      "bind_indirect_res_to_match only allowed on action profiles");
            auto res_name = annot->expr[0]->to<IR::StringLiteral>()->value;
            // Ignore multiple pragmas for same resource name
            if (bind_res.count(res_name)) continue;
            for (auto act : Values(tbl->actions)) {
                // Add resource name only once
                if (bind_res.count(res_name)) break;
                for (auto call : act->stateful_calls) {
                    auto call_name = cstring::to_cstring(canon_name(call->attached_callee->name));
                    if (res_name == call_name) {
                        bind_res.insert(res_name);
                        break;
                    }
                }
            }
        }
    }
    if (bind_res.size() > 0) {
        out << indent++ << "context_json:" << std::endl;
        out << indent   << "ap_bind_indirect_res_to_match: [ ";
        for (auto biter = bind_res.begin(); biter != bind_res.end(); biter++) {
            out << *biter;
            if (biter != --bind_res.end()) out << ", ";
        }
        out << " ]" << std::endl;
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
    if (tbl->layout.proxy_hash)
        tbl_type = "proxy_hash";
    if (no_match_hit)
        tbl_type = "hash_action";
    if (tbl->layout.atcam)
        tbl_type = "atcam_match";
    out << indent++ << tbl_type << ' ' << unique_id << ' ' << tbl->logical_id % 16U
        << ':' << std::endl;
    if (tbl->always_run)
        out << indent << "always_run: true" << std::endl;
    if (!tbl->gateway_only()) {
        emit_table_context_json(out, indent, tbl);
        if (!tbl->layout.no_match_miss_path()) {
            emit_memory(out, indent, tbl->resources->memuse.at(unique_id));
            const IXBar::Use *proxy_ixbar = tbl->layout.proxy_hash ?
                                            &tbl->resources->proxy_hash_ixbar : nullptr;
            emit_ixbar(out, indent, &tbl->resources->match_ixbar, proxy_ixbar,
                         &tbl->resources->hash_dists, &tbl->resources->memuse.at(unique_id),
                         &fmt, tbl, tbl->layout.ternary);
        }
        if (!tbl->layout.ternary && !tbl->layout.no_match_rams()) {
            emit_table_format(out, indent, tbl->resources->table_format, &fmt, false, false);
        }

        if (tbl->layout.ternary)
            emit_ternary_match(out, indent, tbl->resources->table_format);

        if (tbl->layout.atcam)
            emit_atcam_match(out, indent, tbl);
    }
    emit_indirect_res_context_json(out, indent, tbl);
    emit_user_annotation_context_json(out, indent, tbl->match_table);

    NextTableSet next_hit;
    NextTableSet gw_miss;
    bool gw_can_miss = false;
    if (!tbl->action_chain()) {
        if (tbl->has_exit_action()) {
            BUG_CHECK(!tbl->has_non_exit_action(), "Need action chaining to handle both exit "
                      "and non-exit actions in table %1%", tbl);
            next_hit = NextTableSet();
        } else {
            next_hit = next_for(tbl, "$hit");
        }
    }

    if (Device::numLongBranchTags() > 0 && !options.disable_long_branch
        && nxt_tbl->lbs.count(tbl->unique_id())) {
        out << indent++ << "long_branch:" << std::endl;
        // Check for long branches out of this table
        for (auto tag : nxt_tbl->lbs.at(tbl->unique_id())) {
            out << indent << tag.first << ": [";
            const char *sep = " ";
            for (auto id : tag.second) {
                out << sep << id.build_name();
                sep = ", ";
            }
            out << (sep+1) << "]" << std::endl;
        }
        --indent;
    }

    if (tbl->uses_gateway() || tbl->layout.no_match_hit_path() || tbl->gateway_only()) {
        indent_t gw_indent = indent;
        if (!tbl->gateway_only())
            out << gw_indent++ << "gateway:" << std::endl;
        out << gw_indent << "name: " <<  tbl->build_gateway_name() << std::endl;
        emit_ixbar(out, gw_indent, &tbl->resources->gateway_ixbar, nullptr, nullptr, nullptr,
                   nullptr, tbl, false);
        bool ok = false;
        for (auto &use : Values(tbl->resources->memuse)) {
            if (use.type == Memories::Use::GATEWAY) {
                out << gw_indent << "row: " << use.row[0].row << std::endl;
                out << gw_indent << "bus: " << use.row[0].bus << std::endl;
                out << gw_indent << "unit: " << use.gateway.unit << std::endl;
                // FIXME: This is the case for a gateway attached to a ternary or exact match
                if (use.gateway.payload_value != 0ULL) {
                    out << gw_indent << "payload: 0x" << hex(use.gateway.payload_value)
                        << std::endl;
                    emit_table_format(out, gw_indent, tbl->resources->table_format, nullptr,
                                      false, true);
                    // FIXME: Assembler doesn't yet support payload bus/row for every table
                }
                ok = true;
                break;
            }
        }
        BUG_CHECK(ok, "No memory allocation for gateway");
        if (!tbl->layout.no_match_rams() || tbl->uses_gateway())
            gw_can_miss = emit_gateway(out, gw_indent, tbl, no_match_hit, next_hit, gw_miss);
        else
            emit_no_match_gateway(out, gw_indent, tbl);
        if (tbl->gateway_only())
            return;
    }

    safe_vector<NextTableSet> next_table_map;
    if (tbl->action_chain()) {
        // Should this be P4C_UNIMPLEMENTED?  One could write a program like this, but
        // supporting it would require having the driver writer the gateway payload for
        // the default action it wants to install, if there is more than one.  See
        // testdata/p4_16_samples/def-use.cpp.
        BUG_CHECK(!no_match_hit || !gw_can_miss,
                  "A hash action table cannot have an action chain.");
        int ntb = tbl->resources->table_format.next_table_bits();
        if (ntb == 0) {
            int ntm_size = tbl->hit_actions() + (tbl->uses_gateway() ? 1 : 0);
            next_table_map.resize(ntm_size);
            for (auto act : Values(tbl->actions)) {
                if (act->miss_action_only) continue;
                auto &instr_mem = tbl->resources->instr_mem;
                auto &vliw_instr = instr_mem.all_instrs.at(act->name.name);
                BUG_CHECK(vliw_instr.mem_code >= 0 && vliw_instr.mem_code < ntm_size,
                          "Instruction has an invalid mem_code");
                next_table_map[vliw_instr.mem_code] = next_for(tbl, act->name.originalName);
            }
        } else if (ntb <= ceil_log2(TableFormat::NEXT_MAP_TABLE_ENTRIES)) {
            next_table_non_action_map(tbl, next_table_map);
        }
    } else {
        if (gw_can_miss && no_match_hit)
            next_table_map.push_back(gw_miss);
        else
            next_table_map.push_back(next_hit);
    }

    if (no_match_hit) {
        out << indent << "next: " << gw_miss << std::endl;
    } else {
        // The hit vector represents the 8 map values that will appear in the 8 entry
        // next_table_map_data.  If that map is not used, then the map will be empty
        out << indent << "hit: [ ";
        const char *nt_sep = "";
        for (auto nt : next_table_map) {
            out << nt_sep << nt;
            nt_sep = ", ";
        }
        out << " ]" << std::endl;
        out << indent << "miss: " << next_for(tbl, "$miss") << std::endl;
    }

    emit_static_entries(out, indent, tbl);
    bitvec source;
    source.setbit(ActionData::IMMEDIATE);
    source.setbit(ActionData::METER_ALU);
    if (!tbl->layout.ternary && !tbl->layout.no_match_miss_path())
        emit_action_data_bus(out, indent, tbl, source);

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
            ad_check |= tbl->layout.action_addr.address_bits > 0;
            BUG_CHECK(ad_check, "Action Data Table %s misconfigured", ad->name);
            have_action = true; } }
    BUG_CHECK(have_action || tbl->layout.action_data_bytes_in_table == 0,
              "have action data with no action data table?");

    if (!have_indirect)
        emit_table_indir(out, indent, tbl, nullptr);

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
 * Indirect address type.
 */
std::string MauAsmOutput::indirect_address(const IR::MAU::AttachedMemory *am) const {
    if (am->is<IR::MAU::ActionData>())
        return "action_addr";
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
        case IR::MAU::StatefulUse::FAST_CLEAR: return "clear";
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
    if (at_mem->is<IR::MAU::IdleTime>()) {
        return "";
    }

    std::string rv = "(";

    if (ba->addr_location == IR::MAU::AddrLocation::DIRECT) {
        rv += "$DIRECT";
    } else if (ba->addr_location == IR::MAU::AddrLocation::OVERHEAD ||
               ba->addr_location == IR::MAU::AddrLocation::GATEWAY_PAYLOAD) {
        rv += indirect_address(at_mem);
    } else if (ba->addr_location == IR::MAU::AddrLocation::HASH) {
        BUG_CHECK(ba->hash_dist, "Hash Dist not allocated correctly");
        auto hash_dist_uses = tbl->resources->hash_dists;
        const IXBar::HashDistUse *hd_use = nullptr;

        IXBar::HashDistDest_t dest = IXBar::dest_location(ba);
        for (auto &hash_dist_use : hash_dist_uses) {
            for (auto &ir_alloc : hash_dist_use.ir_allocations) {
                if (ir_alloc.dest == dest) {
                    BUG_CHECK(hd_use == nullptr, "Hash Dist Address allocated multiple times");
                    hd_use = &hash_dist_use;
                }
            }
        }
        BUG_CHECK(hd_use != nullptr, "No associated hash distribution group for an address");
        rv += "hash_dist " + std::to_string(hd_use->unit);
    } else if (ba->addr_location == IR::MAU::AddrLocation::STFUL_COUNTER) {
        rv += stateful_counter_addr(ba->use);
    }

    rv += ", ";
    if (ba->pfe_location == IR::MAU::PfeLocation::OVERHEAD ||
        ba->pfe_location == IR::MAU::PfeLocation::GATEWAY_PAYLOAD) {
        rv += indirect_pfe(at_mem);
    } else if (ba->pfe_location == IR::MAU::PfeLocation::DEFAULT) {
        rv += "$DEFAULT";
    }

    if (!at_mem->unique_id().has_meter_type())
        return rv + ")";

    rv += ", ";
    if (ba->type_location == IR::MAU::TypeLocation::OVERHEAD ||
        ba->type_location == IR::MAU::TypeLocation::GATEWAY_PAYLOAD) {
        rv += "meter_type";
    } else if (ba->type_location == IR::MAU::TypeLocation::DEFAULT) {
        rv += "$DEFAULT";
    }
    return rv + ")";
}

/**
 * Due to the color mapram possibly having a different address, due to the address
 * coming from hash being different, as the shift and mask happens in the hash distribution
 * unit, a separate call is built for color maprams.  The enable bit should always be
 * the same as the meter address enable bit.
 */
std::string MauAsmOutput::build_meter_color_call(const IR::MAU::Meter *mtr,
        const IR::MAU::BackendAttached *ba, const IR::MAU::Table *tbl) const {
    std::string rv = "(";
    if (ba->addr_location == IR::MAU::AddrLocation::DIRECT) {
        rv += "$DIRECT";
    } else if (ba->addr_location == IR::MAU::AddrLocation::OVERHEAD ||
               ba->addr_location == IR::MAU::AddrLocation::GATEWAY_PAYLOAD) {
        rv += indirect_address(mtr);
    } else if (ba->addr_location == IR::MAU::AddrLocation::HASH) {
        BUG_CHECK(ba->hash_dist, "Hash Dist not allocated correctly");
        auto &hash_dist_uses = tbl->resources->hash_dists;
        const IXBar::HashDistUse *hd_use = nullptr;
        IXBar::HashDistDest_t dest = IXBar::dest_location(ba, true);
        for (auto &hash_dist_use : hash_dist_uses) {
            for (auto &ir_alloc : hash_dist_use.ir_allocations) {
                if (ir_alloc.dest == dest) {
                    BUG_CHECK(hd_use == nullptr, "Hash Dist Address allocated multiple times");
                    hd_use = &hash_dist_use;
                }
            }
        }
        BUG_CHECK(hd_use != nullptr, "No associated hash distribution group for a color mapram "
                  "address");
        rv += "hash_dist " + std::to_string(hd_use->unit);
    } else {
        BUG("Invalid Address for color mapram");
    }

    rv += ", ";
    if (ba->pfe_location == IR::MAU::PfeLocation::OVERHEAD ||
        ba->pfe_location == IR::MAU::PfeLocation::GATEWAY_PAYLOAD) {
        rv += indirect_pfe(mtr);
    } else if (ba->pfe_location == IR::MAU::PfeLocation::DEFAULT) {
        rv += "$DEFAULT";
    }
    return rv + ")";
}

/**
 * The call for the assembler to determine the selector length
 */
std::string MauAsmOutput::build_sel_len_call(const IR::MAU::Selector *sel) const {
    std::string rv = "(";
    if (SelectorModBits(sel) > 0)
        rv += "sel_len_mod";
    else
        rv += "$DEFAULT";

    rv += ", ";
    if (SelectorLengthShiftBits(sel) > 0)
        rv += "sel_len_shift";
    else
        rv += "$DEFAULT";
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
        const IR::MAU::Table *tbl, const IR::MAU::TernaryIndirect *ti) const {
    for (auto back_at : tbl->attached) {
        auto at_mem = back_at->attached;
        if (at_mem->is<IR::MAU::TernaryIndirect>()) continue;
        if (at_mem->is<IR::MAU::IdleTime>()) continue;  // XXX(zma) idletime is inlined
        if (at_mem->is<IR::MAU::StatefulAlu>() && back_at->use == IR::MAU::StatefulUse::NO_USE)
            continue;  // synthetic salu for driver to write to selector; not used directly
        out << indent << at_mem->kind() << ": ";
        out << find_attached_name(tbl, at_mem);
        out << build_call(at_mem, back_at, tbl);
        out << std::endl;
        if (auto mtr = at_mem->to<IR::MAU::Meter>()) {
            if (mtr->color_output()) {
                out << indent << "meter_color : ";
                out << find_attached_name(tbl, at_mem);
                out << build_meter_color_call(mtr, back_at, tbl);
                out << std::endl;
            }
        }

        auto as = at_mem->to<IR::MAU::Selector>();
        if (as != nullptr) {
            out << indent <<  "selector_length: " << find_attached_name(tbl, at_mem);
            out << build_sel_len_call(as) << std::endl;
        }
    }


    if (!tbl->actions.empty()) {
        out << indent << "instruction: " << tbl->unique_id(ti).build_name() << "(";
        if (tbl->resources->table_format.instr_in_overhead())
            out << "action";
        else
            out << "$DEFAULT";
        out << ", " << "$DEFAULT)" << std::endl;

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
                auto pval = param->expression;
                if (pval->is<IR::Constant>())
                    out << indent << act->args[index++]->name << ": \"0x"
                        << std::hex << pval << std::dec << "\"" << std::endl;
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
    out << indent << "p4: { name: " << canon_name(counter->name);
    if (!counter->direct)
        out << ", size: " << counter->size;
    if (counter->direct && tbl->layout.hash_action)
        out << ", how_referenced: direct";
    out << " }" << std::endl;
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
        // 3 indicies to populate, all with same value for "simple LR(t)"
        out << indent << "lrt:" << std::endl;
        for (int e = 0; e < 3; e++) {
            out << indent << "- { threshold: " << counter->threshold <<
                 ", interval: " << counter->interval << " }" << std::endl; }
    }
    emit_user_annotation_context_json(out, indent, counter);
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
    if (meter->direct && tbl->layout.hash_action)
        out << ", how_referenced: direct";
    out << " }" << std::endl;
    if (meter->input)
        self.emit_ixbar(out, indent, &tbl->resources->meter_ixbar, nullptr, nullptr, nullptr,
                        nullptr, tbl, false);
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
    if (meter->green_value >= 0) {
        out << indent << "green: " << meter->green_value << std::endl;
    }
    if (meter->yellow_value >= 0) {
        out << indent << "yellow: " << meter->yellow_value << std::endl;
    }
    if (meter->red_value >= 0) {
        out << indent << "red: " << meter->red_value << std::endl;
    }
    if (meter->profile >= 0) {
        out << indent << "profile: " << meter->profile << std::endl;
    }
    if (meter->sweep_interval >= 0) {
        out << indent << "sweep_interval: " << meter->sweep_interval << std::endl;
    }
    if (meter->pre_color) {
        const IXBar::HashDistUse *hd_use = nullptr;
        const IXBar::HashDistIRUse *hd_ir_use = nullptr;
        IXBar::HashDistDest_t dest = IXBar::dest_location(meter);
        auto &hash_dist_uses = tbl->resources->hash_dists;
        for (auto &hash_dist_use : hash_dist_uses) {
            for (auto &ir_alloc : hash_dist_use.ir_allocations) {
                if (ir_alloc.dest == dest) {
                    BUG_CHECK(hd_use == nullptr && hd_ir_use == nullptr, "Hash Dist Address "
                              "allocated multiple times");
                    hd_use = &hash_dist_use;
                    hd_ir_use = &ir_alloc;
                }
            }
        }
        BUG_CHECK(hd_use != nullptr, "Could not find hash distribution unit in link up "
                                     "for meter precolor");
        out << indent << "pre_color: hash_dist(";
        auto &hdh = hd_ir_use->use.hash_dist_hash;
        int lo = hdh.galois_matrix_bits.min().index() % IXBar::HASH_DIST_BITS;
        int hi = lo + IXBar::METER_PRECOLOR_SIZE - 1;
        out << hd_use->unit << ", " << lo << ".." << hi << ")" << std::endl;
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
    self.emit_ixbar(out, indent, &tbl->resources->selector_ixbar, nullptr,
                    nullptr, nullptr, nullptr, tbl, false);
    out << indent << "mode: " << (as->mode ? as->mode.name : "fair") << " 0" << std::endl;
    // out << indent << "per_flow_enable: " << "meter_pfe" << std::endl;
    // FIXME: Currently outputting default values for now, these must be brought through
    // either the tofino native definitions or pragmas
    out << indent << "non_linear: " << (as->sps_scramble ? "true" : "false") << std::endl;
    out << indent << "pool_sizes: [" << as->max_pool_size << "]" << std::endl;
    if (as->hash_mod) {
        safe_vector<IXBar::HashDistUse> sel_hash_dist;
        bool found = false;
        for (auto hash_dist_use : tbl->resources->hash_dists) {
            for (auto ir_alloc : hash_dist_use.ir_allocations) {
                if (ir_alloc.dest == IXBar::dest_location(as)) {
                    sel_hash_dist.push_back(hash_dist_use);
                    found = true;
                }
            }
        }
        BUG_CHECK(found, "Could not find hash distribution unit in linkup for hash mod");
        self.emit_hash_dist(out, indent, &sel_hash_dist, true);
    }
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::TernaryIndirect *ti) {
    indent_t    indent(1);
    auto unique_id = tbl->unique_id(ti);
    out << indent++ << "ternary_indirect " << unique_id << ':' << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(unique_id));
    self.emit_ixbar(out, indent, &tbl->resources->match_ixbar, nullptr,
                      &tbl->resources->hash_dists, nullptr, nullptr, tbl, false);
    self.emit_table_format(out, indent, tbl->resources->table_format, nullptr, true, false);
    bitvec source;
    source.setbit(ActionData::IMMEDIATE);
    source.setbit(ActionData::METER_ALU);
    self.emit_action_data_bus(out, indent, tbl, source);
    self.emit_table_indir(out, indent, tbl, ti);
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
    if (ad->direct && tbl->layout.hash_action)
        out << ", how_referenced: direct";
    out << " }" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(unique_id));
    for (auto act : Values(tbl->actions)) {
        // if (act->args.empty()) continue;
        self.emit_action_data_format(out, indent, tbl, act);
    }
    bitvec source;
    source.setbit(ActionData::ACTION_DATA_TABLE);
    self.emit_action_data_bus(out, indent, tbl, source);
    /*
    if (!tbl->actions.empty()) {
        out << indent++ << "actions:" << std::endl;
        for (auto act : Values(tbl->actions))
            act->apply(EmitAction(self, out, tbl, indent));
        --indent; }
    */
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
    if (salu->direct && tbl->layout.hash_action)
        out << ", how_referenced: direct";
    if (salu->synthetic_for_selector)
        out << ", hidden: true";
    out << " }" << std::endl;

    if (salu->selector) {
        auto sel_mem_index = std::make_pair(tbl->stage(), salu->selector);
        BUG_CHECK(self.selector_memory.count(sel_mem_index),
            "Stateful selector %s not found in selector memory map for stage %d on table %s",
            salu->selector->name, tbl->stage(), tbl->unique_id());
        auto &sel_info = self.selector_memory.at(sel_mem_index);
        out << indent << "selection_table: " << sel_info.first << std::endl;
        self.emit_memory(out, indent, *sel_info.second);
    } else {
        self.emit_memory(out, indent, tbl->resources->memuse.at(unique_id)); }
    self.emit_ixbar(out, indent, &tbl->resources->salu_ixbar, nullptr, nullptr, nullptr, nullptr,
                    tbl, false);
    out << indent << "format: { lo: ";
    if (salu->dual)
        out << salu->width/2 << ", hi:" << salu->width/2;
    else
        out << salu->width;
    out << " }" << std::endl;

    if (salu->init_reg_lo || salu->init_reg_hi) {
        out << indent << "initial_value : ";
        out << "{ lo: " << salu->init_reg_lo;
        out << " , hi: " << salu->init_reg_hi << " }" << std::endl;
    }
    if (salu->clear_value)
        out << indent << "clear_value : 0x" << salu->clear_value << std::endl;
    if (salu->busy_value)
        out << indent << "busy_value : 0x" << hex(salu->busy_value) << std::endl;

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
        for (auto act : Values(salu->instruction)) {
            // Ideally, this check should never fail as an empty action is validated in
            // 'CheckStatefulAlu' earlier in backend.
            BUG_CHECK((act->action.size() > 0),
                " Stateful %1% must have instructions assigned for action '%1%'."
                " Please verify the action is valid.",
                salu, act);
            act->apply(EmitAction(self, out, tbl, indent));
        }
        --indent; }

    if (salu->pred_shift >= 0)
        out << indent << "pred_shift: " << salu->pred_shift << std::endl;
    if (salu->pred_comb_shift >= 0)
        out << indent << "pred_comb_shift: " << salu->pred_comb_shift << std::endl;

    auto &memuse = tbl->resources->memuse.at(unique_id);
    if (!memuse.dleft_learn.empty() || !memuse.dleft_match.empty()) {
        out << indent << "stage_alu_id: " << memuse.dleft_learn.size() << std::endl;
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
        // to shift up the correct number of subword bits
        // see IXBar::XBarHashDist::initialize_hash_dist_unit
        if (back_at->hash_dist)
            out << indent << "address_shift: " << ceil_log2(salu->width) << std::endl; }
    if (salu->learn_action) {
        // FIXME -- fixed 8-bit shift for LearnAction -- will we ever want anything else?
        out << indent << "phv_hash_shift: 8" << std::endl; }
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

void MauAsmOutput::emit_always_init_action(std::ostream &out, indent_t indent,
                                           const std::pair<gress_t, int>& stageGress) const {
    std::vector<PHV::Field::alloc_slice> slicesToAlwaysInit;
    std::map<PHV::Container, std::vector<PHV::Field::alloc_slice>> containerToAllocSlices;
    // Collect all the instructions needed for always_run.
    for (const auto& f : phv) {
        if (f.gress != stageGress.first) continue;
        f.foreach_alloc([&](const PHV::Field::alloc_slice& alloc) {
            if (alloc.init_i.empty) return;
            if (!alloc.init_i.alwaysInitInLastMAUStage) return;
            slicesToAlwaysInit.push_back(alloc);
            containerToAllocSlices[alloc.container].push_back(alloc);
        });
    }
    if (slicesToAlwaysInit.size() == 0) return;
    std::map<PHV::Container, PHV::Container> combinedInsts;
    std::map<PHV::Container, bitvec> containerToCoverage;
    std::vector<PHV::Field::alloc_slice> ignoreSet;
    for (auto& kv : containerToAllocSlices) {
        if (kv.second.size() == 1) continue;
        for (auto& alloc : kv.second) {
            LOG3("Alloc for container " << alloc.container << " : " << alloc);
            const auto* src_alloc = alloc.init_i.source;
            containerToCoverage[alloc.container] |= bitvec(alloc.container_bit, alloc.width);
            if (combinedInsts.count(alloc.container)) {
                if (combinedInsts.at(alloc.container) != src_alloc->container)
                    LOG3("Cannot allocate always_run init block for field " << alloc <<", The two "
                         "source containers are " << combinedInsts.at(alloc.container) << " and " <<
                         src_alloc->container);
            } else {
                combinedInsts[alloc.container] = src_alloc->container;
            }
            ignoreSet.push_back(alloc);
        }
    }
    // Make sure the entire container is moved in the always run instruction.
    for (auto& kv : containerToCoverage)
        LOG3(kv.first << " : " << kv.second);

    out << indent++ << "always_run_action:" << std::endl;
    for (auto& alloc : slicesToAlwaysInit) {
        if (std::find(ignoreSet.begin(), ignoreSet.end(), alloc) != ignoreSet.end())
            continue;
        const PHV::Field* field = alloc.field;
        out << indent << "- set " << canon_name(field->externalName());
        if (alloc.width != field->size)
            out << "." << alloc.field_bit << "-" << alloc.field_hi();
        out << ", ";
        const auto* src_alloc = alloc.init_i.source;
        const PHV::Field* src_field = src_alloc->field;
        out << canon_name(src_field->externalName());
        if (src_alloc->width != src_field->size)
            out << "." << src_alloc->field_bit << "-" << src_alloc->field_hi();
        out << std::endl;
    }
    for (auto& kv : combinedInsts) {
        out << indent << "- set " << kv.first << ", " << kv.second << std::endl;
    }
}
