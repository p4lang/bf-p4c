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
    bool preorder(const IR::Stateful *) override;
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
        int                             action = -1, immediate = -1, version = -1;
        vector<std::pair<int, int>>     match;
    };
    int action_bits = 0;
    int immediate_bits = 0;
    vector<match_group> format;
 public:
    vector<Slice>       match_fields;
    Slice               ghost_bits;
    TableFormat(const MauAsmOutput &s, const IR::MAU::Table *tbl);
    void print(std::ostream &) const;
};

class MauAsmOutput::ImmedFormat {
    struct arg {
        cstring         name;
        int             lo, hi;
        arg(cstring n, int l, int sz) : name(n), lo(l), hi(l+sz-1) {}
    };
    vector<arg> immediates;
    int         base = 0;
    const char  *tag = nullptr;
    void init(const IR::ActionFunction *act) {
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
            immediates.emplace_back(arg.second, byte*8, arg.first*8);
            byte += arg.first; } }

 public:
    ImmedFormat(const IR::ActionFunction *act, const char *tag) : tag(tag) { init(act); }
    ImmedFormat(const IR::ActionFunction *act, int base) : base(base) { init(act); }
    explicit operator bool() { return !immediates.empty(); }
    void print(std::ostream &out) const {
        const char *sep = "";
        for (auto &a : immediates) {
            out << sep << a.name << ": ";
            if (tag) out << tag << '(';
            out << (base+a.lo) << ".." << (base+a.hi);
            if (tag) out << ")";
            sep = ", "; } }
};

void MauAsmOutput::emit_ixbar(std::ostream &out, indent_t indent, gress_t gress,
        const IXBar::Use &use, const Memories::Use *mem, const TableFormat *fmt) const {
    map<int, map<int, Slice>> sort;
    if (use.use.empty()) return;
    for (auto &b : use.use) {
        bool n = sort[b.loc.group].emplace(b.loc.byte*8,
            Slice(phv, gress, b.field, b.byte*8, b.byte*8 + 7)).second;
        assert(n); }
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
    int hash_group = -1;
    if (!use.way_use.empty()) {
        out << indent << "ways:" << std::endl;
        auto memway = mem->ways.begin();
        for (auto &way : use.way_use) {
            if (hash_group >= 0 && hash_group != way.group)
                BUG("multiple hash groups use in ways");
            hash_group = way.group;
            out << indent << "- [" << way.group << ", " << way.slice << ", 0x"
                << hex(memway->second) << "]" << std::endl;
            ++memway; } }
    out << indent++ << "input_xbar:" << std::endl;
    for (auto &group : sort)
        out << indent << "group " << group.first << ": " << group.second << std::endl;
    if (use.hash_table_input) {
        for (int ht : bitvec(use.hash_table_input)) {
            out << indent++ << "hash " << ht << ":" << std::endl;
            unsigned half = ht & 1;
            unsigned done = 0, mask_bits = 0;
            vector<Slice> match_data;
            Slice ghost;
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
                if (!ghost) ghost = fmt->ghost_bits & reg;
                reg -= fmt->ghost_bits;
                if (!reg) continue;
                match_data.emplace_back(reg); }
            for (auto &way : use.way_use) {
                mask_bits |= way.mask;
                if (done & (1 << way.slice)) continue;
                done |= 1 << way.slice;
                out << indent << (way.slice*10) << ".." << (way.slice*10 + 9) << ": ";
                if (!match_data.empty()) {
                    out << "random(" << emit_vector(match_data, ", ") << ")";
                    if (ghost) out << " ^ "; }
                if (ghost) out << ghost;
                out << std::endl; }
            for (auto range : bitranges(mask_bits)) {
                out << indent << (range.first+40);
                if (range.second != range.first) out << ".." << (range.second+40);
                out << ": ";
                if (!match_data.empty()) {
                    out << "random(" << emit_vector(match_data, ", ") << ")";
                    if (ghost) out << " ^ "; }
                if (ghost) out << "stripe(" << ghost << ")";
                out << std::endl; }
            --indent; } }
    if (hash_group >= 0) {
        out << indent++ << "hash group " << hash_group << ":" << std::endl;
        out << indent << "table: [" << emit_vector(bitvec(use.hash_table_input), ", ") << "]"
            << std::endl;
        --indent; }
}

class memory_vector {
    const vector<int>           &vec;
    Memories::Use::type_t       type;
    friend std::ostream &operator<<(std::ostream &, const memory_vector &);
 public:
    memory_vector(const vector<int> &v, Memories::Use::type_t t) : vec(v), type(t) {}
};

std::ostream &operator<<(std::ostream &out, const memory_vector &v) {
    if (v.vec.size() > 1) out << "[ ";
    const char *sep = "";
    int col_adjust = v.type == Memories::Use::TERNARY ? 0 : 2;
    bool logical = v.type >= Memories::Use::TWOPORT;
    int col_mod = logical ? 6 : 12;
    for (auto c : v.vec) {
        out << sep << (c + col_adjust) % col_mod;
        sep = ", "; }
    if (v.vec.size() > 1) out << " ]";
    return out;
}

void MauAsmOutput::emit_memory(std::ostream &out, indent_t indent, const Memories::Use &mem) const {
    vector<int> row, bus;
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
            out << indent << "- " << memory_vector(r.col, mem.type) << std::endl;
    } else {
        out << indent << "row: " << row[0] << std::endl;
        if (have_bus) out << indent << "bus: " << bus[0] << std::endl;
        out << indent << "column: " << memory_vector(mem.row[0].col, mem.type) << std::endl;
    }
}

class MauAsmOutput::EmitAction : public Inspector {
    const MauAsmOutput          &self;
    std::ostream                &out;
    const IR::MAU::Table        *table;
    indent_t                    indent;
    const char                  *sep = nullptr;
    bool preorder(const IR::ActionFunction *act) override {
        out << indent << act->name << ":" << std::endl;
        if (table->layout.action_data_bytes_in_overhead) {
            ImmedFormat ifmt(act, "immediate");
            if (ifmt) out << indent << "- { " << ifmt << " }" << std::endl; }
        if (act->action.empty()) {
            /* a noop */
            out << indent << "- 0" << std::endl; }
        visit_children(act, [this, act]() { act->action.visit_children(*this); });
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
        out << sep << *a;
        sep = ", ";
        return false; }
    void postorder(const IR::MAU::Instruction *) override {
        sep = nullptr;
        out << std::endl; }
    bool preorder(const IR::Expression *exp) override {
        if (sep) {
            PhvInfo::Info::bitrange bits;
            if (auto f = self.phv.field(exp, &bits)) {
                out << sep << canon_name(f->name);
                if (bits.lo || bits.size() != f->size)
                    out << '(' << bits.lo << ".." << bits.hi << ')';
            } else {
                out << sep << "/* " << *exp << " */"; }
            sep = ", ";
        } else {
            out << indent << "# " << *exp << std::endl; }
        return false; }

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
            if (auto mask = r->to<IR::Mask>()) {
                field = mask->left;
            } else if (auto prim = r->to<IR::Primitive>()) {
                if (prim->name != "valid")
                    BUG("unexpected reads expression %s", r);
                // FIXME -- for now just assuming we can fit the valid bit reads in as needed
                continue; }
            const PhvInfo::Info *finfo;
            PhvInfo::Info::bitrange bits;
            if (!field || !(finfo = self.phv.field(field, &bits)))
                BUG("unexpected reads expression %s", r);
            match_fields.emplace_back(finfo, tbl->gress, bits.lo, bits.hi); } }

    if (!tbl->layout.ternary && !match_fields.empty())
        ghost_bits = match_fields[0](0, 9);

    if (!tbl->ways.empty()) {
        bitvec used;
        action_bits = ceil_log2(tbl->actions.size());
        immediate_bits = tbl->layout.action_data_bytes_in_overhead * 8;
        int width = tbl->ways[0].width;
        int groups = tbl->ways[0].match_groups;
        int groups_per_word = (groups + width - 1)/width;
        format.resize(groups);
        for (int i = 0; i < groups; i++) {
            int word = i / groups_per_word;
            int j = i % groups_per_word;
            if (action_bits > 0) {
                format[i].action = 128*word + j*action_bits;
                used.setrange(format[i].action, action_bits); }
            format[i].version = 128*word + 124 - j*4;
            used.setrange(format[i].version, 4); }
        if (immediate_bits > 0) {
            for (int i = 0; i < groups; i++) {
                int word = i / groups_per_word;
                format[i].immediate = used.ffz(128*word);
                used.setrange(format[i].immediate, immediate_bits); } }
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
        fmt.emit(out, "action", i, group.action, action_bits);
        fmt.emit(out, "immediate", i, group.immediate, immediate_bits);
        fmt.emit(out, "version", i, group.version, 4);
        fmt.emit(out, "match", i, group.match);
        ++i; }
    out << (fmt.sep + 1) << "}";
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
        emit_ixbar(out, indent, tbl->gress, tbl->resources->match_ixbar,
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
        emit_ixbar(out, gw_indent, tbl->gress, tbl->resources->gateway_ixbar, 0, &fmt);
        for (auto &use : Values(tbl->resources->memuse))
            if (use.type == Memories::Use::GATEWAY) {
                out << gw_indent << "row: " << use.row[0].row << std::endl;
                out << gw_indent << "bus: " << use.row[0].bus << std::endl;
                break; }
        CollectGatewayFields collect(phv);
        tbl->apply(collect);
        if (collect.compute_offsets()) {
            bool have_xor;
            out << gw_indent << "match: {";
            const char *sep = " ";
            for (auto &f : collect.info) {
                if (f.second.xor_with) {
                    have_xor = true;
                    continue; }
                out << sep << f.second.offset << ": " << Slice(f.first, tbl->gress);
                sep = ", "; }
            out << (sep+1) << "}" << std::endl;
            if (have_xor) {
                out << gw_indent << "xor: {";
                sep = " ";
                for (auto &f : collect.info) {
                    if (f.second.xor_with) {
                        out << sep << f.second.offset << ": " << Slice(f.first, tbl->gress);
                        sep = ", "; } }
                out << (sep+1) << "}" << std::endl; }
            for (auto &line : tbl->gateway_rows) {
                out << gw_indent;
                if (line.first) {
                    BuildGatewayMatch match(phv, collect);
                    line.first->apply(match);
                    out << match << ": ";
                } else {
                    out << "miss: "; }
                if (line.second) {
                    if (tbl->next.count(line.second) && !tbl->next[line.second]->empty())
                        out << tbl->next[line.second]->front()->name;
                    else
                        out << default_next.next_in_thread(tbl);
                } else {
                    out << "run_table"; }
                out << std::endl; }
            if (tbl->gateway_rows.back().first)
                out << gw_indent << "miss: run_table" << std::endl;
        } else {
            WARNING("Failed to fit gateway expression for " << tbl->name); } }

    /* FIXME -- this is a mess and needs to be rewritten to be sane */
    bool have_action = false, have_indirect = false;
    for (auto at : tbl->attached) {
        if (at->is<IR::MAU::TernaryIndirect>()) {
            have_indirect = true;
            out << indent << at->kind() << ": " << at->name << std::endl;
        } else if (at->is<IR::ActionProfile>()) {
            have_action = true;
        } else if (at->is<IR::MAU::ActionData>()) {
            assert(tbl->layout.action_data_bytes > tbl->layout.action_data_bytes_in_overhead);
            have_action = true; } }
    assert(have_indirect == (tbl->layout.ternary && (tbl->layout.overhead_bits > 1)));
    assert(have_action || (tbl->layout.action_data_bytes <=
                           tbl->layout.action_data_bytes_in_overhead));

    cstring     next_hit, next_miss, next_default;
    bool        need_next_hit_map = false;
    next_hit = next_miss = next_default = default_next.next_in_thread(tbl);
    for (auto &next : tbl->next) {
        if (next.first == "true" || next.first == "false") {
            continue;  // for the gateway
        } else if (next.first == "$miss") {
            if (!next.second->empty())
                next_miss = next.second->front()->name;
        } else if (next.first == "$hit") {
            if (!next.second->empty())
                next_hit = next.second->front()->name;
        } else if (next.first == "default") {
            if (!next.second->empty())
                next_default = next.second->front()->name;
        } else {
            need_next_hit_map = true; } }
    if (need_next_hit_map) {
        out << indent << "hit: [ ";
        const char *sep = "";
        for (auto act : Values(tbl->actions)) {
            out << sep;
            if (tbl->next.count(act->name)) {
                auto seq = tbl->next.at(act->name);
                if (seq->empty())
                    default_next.next_in_thread(tbl);
                else
                    out << seq->front()->name;
            } else {
                out << next_default;
            }
            sep = ", "; }
        out << " ]" << std::endl;
        out << indent << "miss: " << next_miss << std::endl;
    } else {
        if (next_miss != next_hit) {
            out << indent << "hit: " << next_hit << std::endl;
            out << indent << "miss: " << next_miss << std::endl;
        } else {
            out << indent << "next: " << default_next.next_in_thread(tbl) << std::endl; } }

    if (!have_indirect)
        emit_table_indir(out, indent, tbl);
    for (auto at : tbl->attached)
        at->apply(EmitAttached(*this, out, tbl));
}

void MauAsmOutput::emit_table_indir(std::ostream &out, indent_t indent,
                                    const IR::MAU::Table *tbl) const {
    bool have_action = false;
    for (auto at : tbl->attached) {
        if (at->is<IR::MAU::TernaryIndirect>()) continue;
        if (at->is<IR::ActionProfile>() || at->is<IR::MAU::ActionData>())
            have_action = true;
        out << indent << at->kind() << ": " << at->name;
        if (at->indexed())
            out << '(' << at->kind() << ')';
        out << std::endl; }
    if (!have_action && !tbl->actions.empty()) {
        out << indent++ << "actions:" << std::endl;
        for (auto act : Values(tbl->actions))
            act->apply(EmitAction(*this, out, tbl, indent));
        --indent; }
}

void emit_fmt_nonimmed(std::ostream &out, const IR::MAU::Table *tbl, const IR::ActionFunction *act,
                       const char *sep) {
    vector<std::pair<int, cstring>> sorted_args;
    for (auto arg : act->args) {
        int size = (arg->type->width_bits() + 7) / 8U;  // in bytes
        sorted_args.emplace_back(size, arg->name); }
    std::stable_sort(sorted_args.begin(), sorted_args.end(),
        [](const std::pair<int, cstring> &a, const std::pair<int, cstring> &b)->bool {
            return a.first > b.first; });
    int byte = 0;
    for (auto &arg : sorted_args) {
        if (byte + arg.first <= tbl->layout.action_data_bytes_in_overhead) {
            byte += arg.first;
            continue; }
        out << sep << arg.second << ": " << arg.first*8;
        sep = ", "; }
}

bool MauAsmOutput::EmitAttached::preorder(const IR::Stateful *) {
    return false; }
bool MauAsmOutput::EmitAttached::preorder(const IR::ActionProfile *) {
    return false; }
bool MauAsmOutput::EmitAttached::preorder(const IR::ActionSelector *) {
    return false; }
bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::TernaryIndirect *ti) {
    indent_t    indent(1);
    out << indent++ << "ternary_indirect " << ti->name << ':' << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(ti->name));
    int action_fmt_size = ceil_log2(tbl->actions.size());
    out << indent << "format: { action: " << action_fmt_size;
    if (tbl->layout.action_data_bytes_in_overhead > 0)
        out << ", immediate: " << tbl->layout.action_data_bytes_in_overhead*8;
    out << " }" << std::endl;
    self.emit_table_indir(out, indent, tbl);
    return false; }
bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::ActionData *ad) {
    indent_t    indent(1);
    out << indent++ << "action " << ad->name << ':' << std::endl;
    if (tbl->match_table)
        out << indent << "p4: { name: " << tbl->match_table->name << "$action }" << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(ad->name));
    for (auto act : Values(tbl->actions)) {
        if (act->args.empty()) continue;
        out << indent << "format " << act->name << ": {";
        emit_fmt_nonimmed(out, tbl, act, " ");
        out << " }" << std::endl; }
    if (!tbl->actions.empty()) {
        out << indent++ << "actions:" << std::endl;
        for (auto act : Values(tbl->actions))
            act->apply(EmitAction(self, out, tbl, indent));
        --indent; }
    return false; }
