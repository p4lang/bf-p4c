#include "lib/algorithm.h"
#include "asm_output.h"
#include "lib/bitops.h"
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

void MauAsmOutput::emit_ixbar(std::ostream &out, indent_t indent, const IXBar::Use &use) const {
    map<int, map<int, const IXBar::Use::Byte *>> sort;
    if (use.use.empty()) return;
    for (auto &b : use.use) {
        bool n = sort[b.loc.group].emplace(b.loc.byte, &b).second;
        assert(n); }
    out << indent++ << "input_xbar:" << std::endl;
    for (auto &group : sort) {
        const IXBar::Use::Byte *prev = 0;
        out << indent << "group " << group.first << ": { ";
        for (auto &b : group.second) {
            if (prev && prev->field == b.second->field && prev->byte+1 == b.second->byte) {
                prev = b.second;
                continue; }
            if (prev) out << (prev->byte*8 + 7) << ')' << ", ";
            out << (b.first*8) << ": " << canon_name(trim_asm_name(b.second->field)) << '('
                << (b.second->byte*8) << "..";
            prev = b.second; }
        if (prev) out << (prev->byte*8 + 7) << ')';
        out << " }" << std::endl; }
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
    bool have_bus = true;
    for (auto &r : mem.row) {
        row.push_back(r.row);
        bus.push_back(r.bus);
        if (r.bus < 0) have_bus = false; }
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
    const MauAsmOutput  &self;
    std::ostream        &out;
    indent_t            indent;
    const char          *sep = nullptr;
    bool preorder(const IR::ActionFunction *act) override {
        out << indent << act->name << ":" << std::endl;
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
            std::pair<int, int>     bits;
            if (auto f = self.phv.field(exp, &bits)) {
                out << sep << canon_name(f->name);
                if (bits.second || bits.first != f->size-1)
                    out << '(' << bits.second << ".." << bits.first << ')';
            } else {
                out << sep << "/* " << *exp << " */"; }
            sep = ", ";
        } else {
            out << indent << "# " << *exp << std::endl; }
        return false; }

 public:
    EmitAction(const MauAsmOutput &s, std::ostream &o, indent_t i) : self(s), out(o), indent(i) {
        visitDagOnce = false; }
};

void MauAsmOutput::emit_table(std::ostream &out, const IR::MAU::Table *tbl) const {
    /* FIXME -- some of this should be method(s) in IR::MAU::Table? */
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
        emit_ixbar(out, indent, tbl->resources->match_ixbar);
    }
    if (tbl->gateway_expr) {
        indent_t gw_indent = indent;
        if (tbl->match_table)
            out << gw_indent++ << "gateway:" << std::endl;
        emit_ixbar(out, gw_indent, tbl->resources->gateway_ixbar);
    }

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
            } else
                out << next_default;
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
            act->apply(EmitAction(*this, out, indent));
        --indent; }
}

void emit_fmt_immed(std::ostream &out, const IR::MAU::Table *tbl, int base, const char *sep) {
    std::map<cstring, int>      done;
    for (auto act : Values(tbl->actions)) {
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
            if (done.count(arg.second)) {
                assert(done[arg.second] == byte);
                byte += arg.first;
                continue; }
            done[arg.second] = byte;
            out << sep << arg.second << ": " << base + byte*8;
            byte += arg.first;
            out << ".." << base + byte*8 - 1;
            sep = ", "; } }
}

void emit_fmt_nonimmed(std::ostream &out, const IR::ActionFunction *act, const char *sep) {
    vector<std::pair<int, cstring>> sorted_args;
    for (auto arg : act->args) {
        int size = (arg->type->width_bits() + 7) / 8U;  // in bytes
        sorted_args.emplace_back(size, arg->name); }
    std::stable_sort(sorted_args.begin(), sorted_args.end(),
        [](const std::pair<int, cstring> &a, const std::pair<int, cstring> &b)->bool {
            return a.first > b.first; });
    int byte = 0;
    for (auto &arg : sorted_args) {
        if (byte + arg.first <= 4) {
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
    emit_fmt_immed(out, tbl, action_fmt_size, ", ");
    out << " }" << std::endl;
    self.emit_table_indir(out, indent, tbl);
    return false; }
bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::ActionData *ad) {
    indent_t    indent(1);
    out << indent++ << "action " << ad->name << ':' << std::endl;
    self.emit_memory(out, indent, tbl->resources->memuse.at(ad->name));
    for (auto act : Values(tbl->actions)) {
        if (act->args.empty()) continue;
        out << indent << "format " << act->name << ": {";
        emit_fmt_nonimmed(out, act, " ");
        out << " }" << std::endl; }
    if (!tbl->actions.empty()) {
        out << indent++ << "actions:" << std::endl;
        for (auto act : Values(tbl->actions))
            act->apply(EmitAction(self, out, indent));
        --indent; }
    return false; }
