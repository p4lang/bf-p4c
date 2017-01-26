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
    bool preorder(const IR::Register *) override;
    bool preorder(const IR::ActionProfile *) override;
    bool preorder(const IR::ActionSelector *) override;
    bool preorder(const IR::MAU::TernaryIndirect *) override;
    bool preorder(const IR::MAU::ActionData *) override;
    bool preorder(const IR::Attached *att) override {
        BUG("unknown attached table type %s", typeid(*att).name()); }
    EmitAttached(const MauAsmOutput &s, std::ostream &o, const IR::MAU::Table *t)
    : self(s), out(o), tbl(t) {}
};

std::ostream &operator<<(std::ostream &out, const MauAsmOutput &mauasm) {
    for (auto &stage : mauasm.by_stage) {
        out << "stage " << stage.first.second << ' ' << stage.first.first << ':' << std::endl;
        for (auto tbl : stage.second)
            mauasm.emit_table(out, tbl); }
    return out;
}

class MauAsmOutput::TableFormat {
    const MauAsmOutput &self;
    struct match_group {
        int starting_bits[7] = {-1, -1, -1, -1, -1, -1, -1};
        vector<std::pair<int, int>>     match;
    };
    int total_bits[7] = {0, 0, 0, 0, 0, 0, 0};
    enum type_t { ACTION, IMMEDIATE, VERS, COUNTER, METER, INDIRECT_ACTION, SELECTOR };
    vector<match_group> format;
 public:
    vector<Slice>       match_fields;
    vector<Slice>       ghost_bits;
    TableFormat(const MauAsmOutput &s, const IR::MAU::Table *tbl);
    void print(std::ostream &) const;
    void setup_indirect(type_t type, int groups, int groups_per_word, bitvec &used) {
        if (total_bits[type] > 0) {
            for (int i = 0; i < groups; i++) {
                int word = i / groups_per_word;
                format[i].starting_bits[type] = used.ffz(128*word);
                used.setrange(format[i].starting_bits[type], total_bits[type]);
            }
        }
    }
};

class MauAsmOutput::ImmedFormat {
    struct arg {
        cstring         name, immed;
        int             lo, hi;
        arg(cstring n, cstring im, int l, int sz) : name(n), immed(im), lo(l), hi(l+sz-1) {}
    };
    vector<arg> immediates;

 public:
    void add_alias(cstring name, cstring immed) {
        immediates.emplace_back(name, immed, -1, 0); }
    void setup_immed(const IR::ActionFunction *act, const char *immed) {
        vector<std::pair<int, cstring>> sorted_args;
        for (auto arg : act->args) {
            int size = (arg->type->width_bits() + 7) / 8U;  // in bytes
            sorted_args.emplace_back(size, arg->name); }
        std::stable_sort(sorted_args.begin(), sorted_args.end(),
            [](const std::pair<int, cstring> &a, const std::pair<int, cstring> &b)->bool {
                return a.first > b.first; });
        int byte = 0;
        for (auto &arg : sorted_args) {
            if (byte >= 4) break;
            if (byte + arg.first > 4) continue;
            immediates.emplace_back(arg.second, immed, byte*8, arg.first*8);
            byte += arg.first; } }
    explicit operator bool() { return !immediates.empty(); }
    void print(std::ostream &out) const {
        const char *sep = "";
        for (auto &a : immediates) {
            out << sep << a.name << ": " << a.immed;
            if (a.lo >= 0)
                out << '(' << a.lo << ".." << a.hi << ')';
            sep = ", "; } }
};

class MauAsmOutput::ActionDataFormat : public Inspector {
    const MauAsmOutput          &self;
    const IR::MAU::Table        *tbl;
    const IR::ActionFunction    *act;
    bitvec inuse;
    std::multimap<int, std::pair<int, cstring>> placed_args;
    std::map<const IR::ActionArg *, std::pair<int, int>> arg_use;

    bool preorder(const IR::ActionArg *a) override {
        if (auto *inst = findContext<IR::MAU::Instruction>()) {
            PhvInfo::Field::bitrange bits;
            if (auto f = self.phv.field(inst->operands[0], &bits)) {
                auto &alloc = f->for_bit(bits.lo);
                int sz = alloc.container.size() / 8U;
                if (arg_use[a].first < sz)
                    arg_use[a].first = sz;
                if (auto sl = getParent<IR::Slice>()) {
                    /* FIXME -- deal with mulitple slices with conflicting uses */
                    if (int align = -(sl->getL() / 8U) % sz)
                        arg_use[a].second = align; } } }
        return false; }
    int find_slot(int sz, int align, int align_off) {
        int bit = 0;
        while (1) {
            bit = inuse.ffz(bit);
            while ((bit & (align-1)) != align_off) ++bit;
            int space = inuse.ffs(bit);
            if (space < 0 || space - bit >= sz)
                return bit;
            bit = space; } }

 public:
    ActionDataFormat(const MauAsmOutput &s, const IR::MAU::Table *t, const IR::ActionFunction *a)
    : self(s), tbl(t), act(a) {
        visitDagOnce = false;
        LOG3("laying out action data for " << tbl->name << ":" << act->name);
        a->apply(*this);
        for (auto arg : act->args) {
            int size = (arg->type->width_bits() + 7) / 8U;  // in bytes
            int align = size > 2 ? 4 : size > 1 ? 2 : 1;
            int align_off = size & (align-1);
            if (arg_use.count(arg)) {
                align = arg_use[arg].first;
                align_off = arg_use[arg].second; }
            int at = find_slot(size, align, align_off);
            LOG4(arg->name << " " << size << " bytes at offset " << at <<
                 " (align=" << align << " align_off=" << align_off << ")");
            if (size > 0)
                inuse.setrange(at, size);
            placed_args.emplace(at, std::make_pair(size, arg->name)); } }
    void print(std::ostream &out) const {
        const char *sep = " ";
        int byte = 0;
        out << "format " << act->name << ": {";
        for (auto &arg : placed_args) {
            int end =  arg.first + arg.second.first;
            if (end > tbl->layout.action_data_bytes_in_overhead) {
                if (byte < tbl->layout.action_data_bytes_in_overhead)
                    byte = tbl->layout.action_data_bytes_in_overhead;
                out << sep << arg.second.second << ": ";
                if (byte == arg.first || arg.second.first == 0)
                    out << arg.second.first*8;
                else
                    out << arg.first*8 << ".." << end*8-1; }
            byte = end;
            sep = ", "; }
        out << (sep+1) << " }"; }
};

struct FormatHash {
    vector<Slice> match_data;
    vector<Slice> ghost;
    const IR::ActionSelector *as;
    FormatHash(vector<Slice> md, vector<Slice> g, const IR::ActionSelector *a = nullptr)
        : match_data(md), ghost(g), as(a) {}
};

// FIXME: This is a simple function for crc polynomial.  Probably needs to be expanded for
// actual use of the assembly
static cstring inline crc_poly(cstring number) {
    if (number == "16")
        return "0x8fdb";
    else  // if (number == "32")
        return "0xe89061db";
}

std::ostream &operator<<(std::ostream &out, const FormatHash &hash) {
    if (hash.as != nullptr) {
        cstring alg_name = hash.as->key_fields->algorithm.name;
        if (strncmp(alg_name, "crc", 3) == 0) {
            out << "stripe(crc(" << crc_poly(alg_name.substr(3)) << ", "
                << emit_vector(hash.match_data, ", ") << "))";
        } else if (alg_name == "random") {
            out << "random(" << emit_vector(hash.match_data, ", ") << ")";
        // FIXME: Not sure if this is correct for identity for asm output
        } else if (alg_name == "identity" || alg_name == "identity_lsb") {
            out << hash.match_data[0];
        } else {
            BUG("Algorithm %s for %s is not recognized", alg_name, hash.as->name);
        }
        return out;
    }
    if (!hash.match_data.empty()) {
        out << "random(" << emit_vector(hash.match_data, ", ") << ")";
        if (!hash.ghost.empty()) out << " ^ "; }
    if (!hash.ghost.empty())
        out << "stripe(" << emit_vector(hash.ghost, ", ") << ")";
    return out;
}

void MauAsmOutput::emit_ixbar(std::ostream &out, indent_t indent,
        const IXBar::Use &use, const Memories::Use *mem, const TableFormat *fmt,
        bool is_sel /*= false*/, const IR::ActionSelector *as /*= nullptr */) const {
    map<int, map<int, Slice>> sort;
    for (auto &b : use.use) {
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
                    continue; } }
            it = next; } }
    if (!use.way_use.empty() && !is_sel) {
        out << indent << "ways:" << std::endl;
        auto memway = mem->ways.begin();
        for (auto &way : use.way_use) {
            out << indent << "- [" << way.group << ", " << way.slice << ", 0x"
                << hex(memway->select_mask) << ", ";
            size_t index = 0;
            for (auto ram : memway->rams) {
                out << "[" << ram.first << ", " << (ram.second + 2) << "]";
                if (index < memway->rams.size() - 1)
                    out << ", ";
                index++;
            }
            out  << "]" << std::endl;
            ++memway; } }
    if (use.use.empty()) return;
    out << indent++ << "input_xbar:" << std::endl;
    for (auto &group : sort)
        out << indent << "group " << group.first << ": " << group.second << std::endl;
    // Hash groups are now broguht out of the IXBar Use, rather than recalculated in asm_output
    int hash_group = 0;
    for (auto hash_table_input : use.hash_table_inputs) {
        if (hash_table_input) {
            for (int ht : bitvec(hash_table_input)) {
                out << indent++ << "hash " << ht << ":" << std::endl;
                unsigned half = ht & 1;
                unsigned done = 0, mask_bits = 0;
                vector<Slice> match_data;
                vector<Slice> ghost;
                for (auto &match : sort.at(ht/2)) {
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
                    if (as == nullptr) {
                        auto reg_hash = reg - fmt->ghost_bits;
                        if (auto reg_ghost = reg - reg_hash)
                            ghost.push_back(reg_ghost);
                        if (reg_hash)
                            match_data.emplace_back(reg_hash);
                    } else {
                        match_data.emplace_back(reg);
                    }
                }
                // FIXME: This is obviously an issue for larger selector tables,
                //  whole function needs to be replaced
                if (as != nullptr) {
                    if (as->mode == "fair")
                        out << indent << "0..13: "
                            << FormatHash(match_data, ghost, as) << std::endl;
                    else
                        out << indent << "0..50: "
                            << FormatHash(match_data, ghost, as) << std::endl;
                }
                for (auto &way : use.way_use) {
                    mask_bits |= way.mask;
                    if (done & (1 << way.slice)) continue;
                    done |= 1 << way.slice;
                    out << indent << (way.slice*10) << ".." << (way.slice*10 + 9) << ": "
                        << FormatHash(match_data, ghost) << std::endl; }
                for (auto range : bitranges(mask_bits)) {
                    out << indent << (range.first+40);
                    if (range.second != range.first) out << ".." << (range.second+40);
                    out << ": " << FormatHash(match_data, ghost) << std::endl; }
                for (auto ident : use.bit_use) {
                    out << indent << (40 + ident.bit);
                    if (ident.width > 1)
                        out << ".." << (39 + ident.bit + ident.width);
                    out << ": " << Slice(phv, ident.field, ident.lo, ident.lo + ident.width - 1)
                        << std:: endl;
                    assert(hash_group == -1 || hash_group == ident.group);
                }
                --indent;
            }
            if (hash_group >= 0) {
                out << indent++ << "hash group " << hash_group << ":" << std::endl;
                out << indent << "table: [" << emit_vector(bitvec(hash_table_input), ", ") << "]"
                    << std::endl;
                --indent;
            }
        }
        hash_group++;
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
    if (v.vec.size() > 1) out << "[ ";
    const char *sep = "";
    int col_adjust = (v.type == Memories::Use::TERNARY || v.is_mapcol)  ? 0 : 2;
    bool logical = v.type >= Memories::Use::TWOPORT;
    int col_mod = logical ? 6 : 12;
    for (auto c : v.vec) {
        out << sep << (c + col_adjust) % col_mod;
        sep = ", "; }
    if (v.vec.size() > 1) out << " ]";
    return out;
}

void MauAsmOutput::emit_memory(std::ostream &out, indent_t indent, const Memories::Use &mem) const {
    vector<int> row, bus, home_row;
    bool logical = mem.type >= Memories::Use::TWOPORT;
    bool have_bus = !logical;
    for (auto &r : mem.row) {
        LOG1("row bus col " << r.row << " " << r.bus << " " << r.col[0]);
    }
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

class MauAsmOutput::EmitAction : public Inspector {
    const MauAsmOutput          &self;
    std::ostream                &out;
    const IR::MAU::Table        *table;
    indent_t                    indent;
    const char                  *sep = nullptr;
    void output_action(const IR::ActionFunction *act, ImmedFormat &ifmt) {
        out << indent << act->name << ":" << std::endl;
        if (ifmt) out << indent << "- { " << ifmt << " }" << std::endl;
        if (act->action.empty()) {
            /* a noop */
            out << indent << "- 0" << std::endl;
        } else {
            act->action.visit_children(*this); } }
    bool preorder(const IR::ActionFunction *act) override {
        ImmedFormat ifmt;
        if (table->layout.action_data_bytes_in_overhead)
            ifmt.setup_immed(act, "immediate");
        output_action(act, ifmt);
        return false; }
    bool preorder(const IR::MAU::ActionFunctionEx *act) override {
        ImmedFormat ifmt;
        if (table->layout.action_data_bytes_in_overhead)
            ifmt.setup_immed(act, "immediate");
        for (auto prim : act->stateful) {
            if (prim->name == "count") {
                if (auto aa = prim->operands[1]->to<IR::ActionArg>())
                    ifmt.add_alias(aa->name, "counter_ptr");
                else
                    ERROR("counter index arg '" << prim->operands[1] << "' is not an action arg");
            } else {
                ERROR("skipping " << prim); } }
        output_action(act, ifmt);
        return false; }
    bool preorder(const IR::MAU::Instruction *inst) override {
        out << indent << "- " << inst->name;
        sep = " ";
        return true; }
    bool preorder(const IR::Constant *c) override {
        assert(sep);
        out << sep << c->asLong();
        sep = ", ";
        return false; }
    bool preorder(const IR::ActionArg *a) override {
        assert(sep);
        out << sep << a->toString();
        sep = ", ";
        return false; }
    void postorder(const IR::MAU::Instruction *) override {
        sep = nullptr;
        out << std::endl; }
    bool preorder(const IR::Cast *c) override { visit(c->expr); return false; }
    bool preorder(const IR::Expression *exp) override {
        if (sep) {
            PhvInfo::Field::bitrange bits;
            if (auto f = self.phv.field(exp, &bits)) {
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

MauAsmOutput::TableFormat::TableFormat(const MauAsmOutput &s, const IR::MAU::Table *tbl) : self(s) {
    /* FIXME -- this should probably be an aux data structure built earlier, rather than
     * done in AsmOutput */

    if (tbl->match_table && tbl->match_table->reads) {
        /* somewhat duplicates what is done in IXBar::alloc_table */
        for (auto r : *tbl->match_table->reads) {
            auto *field = r;
            if (auto mask = r->to<IR::Mask>())
                field = mask->left;
            if (auto prim = field->to<IR::Primitive>()) {
                if (prim->name != "valid")
                    BUG("unexpected reads expression %s", r);
                // FIXME -- for now just assuming we can fit the valid bit reads in as needed
                continue; }
            const PhvInfo::Field *finfo;
            PhvInfo::Field::bitrange bits;
            if (!field || !(finfo = self.phv.field(field, &bits)))
                BUG("unexpected reads expression %s", r);
            match_fields.emplace_back(finfo, bits.lo, bits.hi); } }

    if (!tbl->layout.ternary) {
        int ghost_bits_needed = 10;  // FIXME -- should depend on way depth
        for (auto &field : match_fields) {
            if (ghost_bits_needed >= field.width()) {
                ghost_bits.push_back(field);
                ghost_bits_needed -= field.width();
            } else if (ghost_bits_needed > 0) {
                ghost_bits.push_back(field(0, ghost_bits_needed-1));
                ghost_bits_needed = 0; } } }
    if (!tbl->ways.empty()) {
        bitvec used;
        total_bits[ACTION] = ceil_log2(tbl->actions.size());
        total_bits[IMMEDIATE] = tbl->layout.action_data_bytes_in_overhead * 8;
        total_bits[METER] = tbl->layout.meter_overhead_bits;
        total_bits[COUNTER] = tbl->layout.counter_overhead_bits;
        total_bits[INDIRECT_ACTION] = tbl->layout.indirect_action_overhead_bits;
        total_bits[SELECTOR] = tbl->layout.selector_overhead_bits;
        int width = tbl->ways[0].width;
        int groups = tbl->ways[0].match_groups;
        int groups_per_word = (groups + width - 1)/width;
        format.resize(groups);
        for (int i = 0; i < groups; i++) {
            int word = i / groups_per_word;
            int j = i % groups_per_word;
            if (total_bits[ACTION] > 0) {
                format[i].starting_bits[ACTION] = 128*word + j*total_bits[ACTION];
                used.setrange(format[i].starting_bits[ACTION], total_bits[ACTION]); }
            format[i].starting_bits[VERS] = 128*word + 124 - j*4;
            total_bits[VERS] = 4;
            used.setrange(format[i].starting_bits[VERS], 4); }
        setup_indirect(IMMEDIATE, groups, groups_per_word, used);
        setup_indirect(COUNTER, groups, groups_per_word, used);
        setup_indirect(METER, groups, groups_per_word, used);
        setup_indirect(INDIRECT_ACTION, groups, groups_per_word, used);
        setup_indirect(SELECTOR, groups, groups_per_word, used);
        if (!match_fields.empty()) {
            for (int i = 0; i < groups; i++) {
                int word = i / groups_per_word;
                int bit = used.ffz(128*word);
                for (auto field : match_fields) {
                    field -= ghost_bits;
                    if (!field) continue;
                    bit += (field.bytealign() - bit) & 7;
                    while (used.getslice(bit, field.width())) {
                        bit = used.ffz(used.ffs(bit));
                        bit += (field.bytealign() - bit) & 7; }
                    if (bit + field.width() > width*128)
                        BUG("match group packing overflow for table %s (groups=%d, width=%d)",
                            tbl->name, groups, width);
                    if (format[i].match.empty() || format[i].match.back().second != bit - 1)
                        format[i].match.emplace_back(bit, bit + field.width() - 1);
                    else
                        format[i].match.back().second = bit + field.width() - 1;
                    used.setrange(bit, field.width()); } } } }
}

void MauAsmOutput::TableFormat::print(std::ostream &out) const {
    struct fmt_state {
        const char *sep = " ";
        int next = 0;
        void emit(std::ostream &out, const char *name, int group, int bit, int width) {
            if (bit < 0) return;
            out << sep << name << '(' << group << "): ";
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
                out << sep << name << '(' << group << "): [ ";
                sep = "";
                for (auto &p : bits) {
                    out << sep << p.first << ".." << p.second;
                    sep = ", "; }
                out << " ]"; } }
    } fmt;
    out << "format: {";
    int i = 0;
    for (auto &group : format) {
        fmt.emit(out, "action", i, group.starting_bits[ACTION], total_bits[ACTION]);
        fmt.emit(out, "immediate", i, group.starting_bits[IMMEDIATE], total_bits[IMMEDIATE]);
        fmt.emit(out, "version", i, group.starting_bits[VERS], total_bits[VERS]);
        fmt.emit(out, "counter_ptr", i, group.starting_bits[COUNTER], total_bits[COUNTER]);
        fmt.emit(out, "meter_ptr", i, group.starting_bits[METER], total_bits[METER]);
        fmt.emit(out, "action_ptr", i, group.starting_bits[INDIRECT_ACTION],
                 total_bits[INDIRECT_ACTION]);
        fmt.emit(out, "select_ptr", i, group.starting_bits[SELECTOR], total_bits[SELECTOR]);
        fmt.emit(out, "match", i, group.match);
        ++i; }
    out << (fmt.sep + 1) << "}";
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

void MauAsmOutput::emit_table(std::ostream &out, const IR::MAU::Table *tbl) const {
    /* FIXME -- some of this should be method(s) in IR::MAU::Table? */
    TableFormat fmt(*this, tbl);
    const char *tbl_type = "gateway";
    indent_t    indent(1);
    if (tbl->match_table)
        tbl_type = tbl->layout.ternary ? "ternary_match" : "exact_match";
    out << indent++ << tbl_type << ' '<< tbl->name << ' ' << tbl->logical_id % 16U << ':'
        << std::endl;
    if (tbl->match_table) {
        out << indent << "p4: { name: " << tbl->match_table->name;
        if (tbl->match_table->size > 0)
            out << ", size: " << tbl->match_table->size;
        out << " }" << std::endl;
        emit_memory(out, indent, tbl->resources->memuse.at(tbl->name));
        emit_ixbar(out, indent, tbl->resources->match_ixbar,
                   &tbl->resources->memuse.at(tbl->name), &fmt);
        if (!tbl->layout.ternary) {
            out << indent << fmt << std::endl;
            bool first = true;
            for (auto field : fmt.match_fields) {
                field -= fmt.ghost_bits;
                if (!field) continue;
                if (first) {
                    out << indent << "match: [ ";
                    first = false;
                } else {
                    out << ", "; }
                out << field; }
            if (!first) out << " ]" << std::endl; } }
    if (tbl->uses_gateway()) {
        indent_t gw_indent = indent;
        if (tbl->match_table)
            out << gw_indent++ << "gateway:" << std::endl;
        emit_ixbar(out, gw_indent, tbl->resources->gateway_ixbar, 0, &fmt);
        for (auto &use : Values(tbl->resources->memuse))
            if (use.type == Memories::Use::GATEWAY) {
                out << gw_indent << "row: " << use.row[0].row << std::endl;
                out << gw_indent << "bus: " << use.row[0].bus << std::endl;
                break; }
        CollectGatewayFields collect(phv, &tbl->resources->gateway_ixbar);
        tbl->apply(collect);
        if (collect.compute_offsets()) {
            bool have_xor;
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
                            sep = ", "; } } }
                out << (sep+1) << "}" << std::endl; }
            if (collect.need_range)
                out << gw_indent << "range: 4" << std::endl;
            BuildGatewayMatch match(phv, collect);
            for (auto &line : tbl->gateway_rows) {
                out << gw_indent;
                if (line.first) {
                    line.first->apply(match);
                    out << match << ": ";
                } else {
                    out << "miss: "; }
                if (line.second)
                    out << next_for(tbl, line.second, default_next);
                else
                    out << "run_table";
                out << std::endl; }
            if (tbl->gateway_rows.back().first)
                out << gw_indent << "miss: run_table" << std::endl;
        } else {
            WARNING("Failed to fit gateway expression for " << tbl->name); }
        if (!tbl->match_table)
            return; }

    /* FIXME -- this is a mess and needs to be rewritten to be sane */
    bool have_action = false, have_indirect = false;
    for (auto at : tbl->attached) {
        if (auto *ti = at->to<IR::MAU::TernaryIndirect>()) {
            have_indirect = true;
            cstring name = tbl->resources->use_names.get_name(tbl, ti);
            out << indent << at->kind() << ": " << name << std::endl;
        } else if (at->is<IR::ActionProfile>()) {
            have_action = true;
        } else if (at->is<IR::MAU::ActionData>()) {
            assert(tbl->layout.action_data_bytes > tbl->layout.action_data_bytes_in_overhead);
            have_action = true; } }
    assert(have_indirect == (tbl->layout.ternary && (tbl->layout.overhead_bits > 0)));
    assert(have_action || (tbl->layout.action_data_bytes <=
                           tbl->layout.action_data_bytes_in_overhead));

    bool need_next_hit_map = false;
    for (auto &next : tbl->next) {
        if (next.first[0] != '$') {
            need_next_hit_map = true;
            break; } }
    if (need_next_hit_map) {
        out << indent << "hit: [ ";
        const char *sep = "";
        for (auto act : Values(tbl->actions)) {
            out << sep << next_for(tbl, act->name, default_next);
            sep = ", "; }
        out << " ]" << std::endl;
        out << indent << "miss: " << next_for(tbl, "$miss", default_next)  << std::endl;
    } else {
        auto next_hit = next_for(tbl, "$hit", default_next);
        auto next_miss = next_for(tbl, "$miss", default_next);
        if (next_miss != next_hit) {
            out << indent << "hit: " << next_hit << std::endl;
            out << indent << "miss: " << next_miss << std::endl;
        } else {
            out << indent << "next: " << next_hit << std::endl; } }

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
             return_name = tbl->resources->use_names.get_name(tbl, unattached);
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

void MauAsmOutput::emit_table_indir(std::ostream &out, indent_t indent,
                                    const IR::MAU::Table *tbl) const {
    bool have_action = false;
    vector<const IR::Attached *> stats_tables;
    vector<const IR::Attached *> meter_tables;
    auto match_name = tbl->resources->use_names.get_name(tbl);
    for (auto at : tbl->attached) {
        if (at->is<IR::MAU::TernaryIndirect>()) continue;
        if (at->is<IR::ActionProfile>() || at->is<IR::MAU::ActionData>())
            have_action = true;
        if (at->is<IR::Counter>()) {
            stats_tables.push_back(at);
            continue;
        }
        if (at->is<IR::Meter>()) {
            meter_tables.push_back(at);
            continue;
        }
        if (auto *ap = at->to<IR::ActionProfile>()) {
            auto &memuse = tbl->resources->memuse.at(match_name);
            out << indent << "action: ";
            if (memuse.unattached_profile) {
                UnattachedName unattached(tbl, match_name, ap);
                pipe->apply(unattached);
                out << unattached.name();
            } else {
                out << tbl->resources->use_names.get_name(tbl, ap);
            }
            if (at->indexed())
                out << "(action, action_ptr)";
            out << std::endl;
            continue;
        }

        if (auto *as = at->to<IR::ActionSelector>()) {
             auto &memuse = tbl->resources->memuse.at(match_name);
             out << indent << "selector: ";
             if (memuse.unattached_profile) {
                 UnattachedName unattached(tbl, match_name, as);
                 pipe->apply(unattached);
                 out << unattached.name();
             } else {
                 out << tbl->resources->use_names.get_name(tbl, as);
             }
             out << "(select_ptr)";
             out << std::endl;
             continue;
        }
        out << indent << at->kind() << ": " << at->name;
        if (at->indexed())
            out << '(' << at->kind() << ')';
        out << std::endl; 
    }


    if (!stats_tables.empty()) {
        out << indent << "stats:" << std::endl;
        for (auto at : stats_tables) {
            auto name = tbl->resources->use_names.get_name(tbl, at);
            out << indent << "- " << name;
            if (at->indexed())
                out << '(' << "counter_ptr" << ')';
            out << std::endl;
        }
    }
    if (!meter_tables.empty()) {
        out << indent << "meter:" << std::endl;
        for (auto at : meter_tables) {
            auto name = tbl->resources->use_names.get_name(tbl, at);
            out << indent << "- " << name;
            if (at->indexed())
                out << '(' << "meter_ptr" << ')';
            out << std::endl;
        }
    }


    if (!have_action && !tbl->actions.empty()) {
        out << indent++ << "actions:" << std::endl;
        for (auto act : Values(tbl->actions))
            act->apply(EmitAction(*this, out, tbl, indent));
        --indent; }
    if (tbl->match_table && tbl->match_table->default_action) {
        out << indent << "default_action: " << tbl->match_table->default_action;
        if (tbl->match_table->default_action_args) {
            const char *sep = "(";
            for (auto a : *tbl->match_table->default_action_args) {
                out << sep << *a;
                sep = ", "; }
            if (*sep != '(') out << ")"; }
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
    auto name = tbl->resources->use_names.get_name(tbl, counter);
    LOG1("Name of counter " << name);
    out << indent++ << "counter " << name << ":" << std::endl;
    if (auto p = counter->name.name.find('.'))
        out << indent << "p4: { name: " << counter->name.name.before(p) << " }" << std::endl;
    else
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
    auto name = tbl->resources->use_names.get_name(tbl, meter);
    out << indent++ << "meter " << name << ":" << std::endl;
    if (auto p = meter->name.name.find('.'))
        out << indent << "p4: { name: " << meter->name.name.before(p) << " }" << std::endl;
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

bool MauAsmOutput::EmitAttached::preorder(const IR::Register *) {
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::ActionProfile *ap) {
    auto match_name = tbl->resources->use_names.get_name(tbl);
    if (tbl->resources->memuse.at(match_name).unattached_profile) {
        return false;
    }
    
    indent_t    indent(1);
    auto name = tbl->resources->use_names.get_name(tbl, ap);
    out << indent++ << "action " << name << ':' << std::endl;
    if (auto p = ap->name.name.find('.'))
        out << indent << "p4: { name: " << ap->name.name.before(p) << " }" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
    for (auto act : Values(tbl->actions)) {
        if (act->args.empty()) continue;
        out << indent << ActionDataFormat(self, tbl, act) << std::endl; }
    if (!tbl->actions.empty()) {
        out << indent++ << "actions:" << std::endl;
        for (auto act : Values(tbl->actions))
            act->apply(EmitAction(self, out, tbl, indent));
        --indent; }
    return false;
}

bool MauAsmOutput::EmitAttached::preorder(const IR::ActionSelector *as) {
    indent_t indent(1);
    auto match_name = tbl->resources->use_names.get_name(tbl);
    if (tbl->resources->memuse.at(match_name).unattached_profile) {
        return false;
    }
    cstring name = tbl->resources->use_names.get_name(tbl, as);
    if (auto p = as->name.name.find('.'))
        out << indent << "p4: { name: " << as->name.name.before(p) << " }" << std::endl;
    out << indent++ << "selection " << name << ":" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
    self.emit_ixbar(out, indent, tbl->resources->selector_ixbar,
                    &tbl->resources->memuse.at(name), nullptr, true, as);
    out << indent << "mode: " << as->mode.name << " 0" << std::endl;
    return false; }
bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::TernaryIndirect *ti) {
    indent_t    indent(1);
    auto name = tbl->resources->use_names.get_name(tbl, ti);
    out << indent++ << "ternary_indirect " << name << ':' << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
    int action_fmt_size = ceil_log2(tbl->actions.size());
    out << indent << "format: { ";
    const char *sep = "";
    if (action_fmt_size > 0) {
        out << sep << "action: " << action_fmt_size;
        sep = ", "; }
    if (tbl->layout.action_data_bytes_in_overhead > 0) {
        out << sep << "immediate: " << tbl->layout.action_data_bytes_in_overhead*8;
        sep = ", "; }
    out << " }" << std::endl;
    self.emit_table_indir(out, indent, tbl);
    return false; 
}

bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::ActionData *ad) {
    indent_t    indent(1);
    out << indent++ << "action " << ad->name << ':' << std::endl;
    auto name = tbl->resources->use_names.get_name(tbl, ad);
    if (tbl->match_table)
        out << indent << "p4: { name: " << tbl->match_table->name << "$action }" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(name));
    for (auto act : Values(tbl->actions)) {
        if (act->args.empty()) continue;
        out << indent << ActionDataFormat(self, tbl, act) << std::endl; }
    if (!tbl->actions.empty()) {
        out << indent++ << "actions:" << std::endl;
        for (auto act : Values(tbl->actions))
            act->apply(EmitAction(self, out, tbl, indent));
        --indent; }
    return false;
}
