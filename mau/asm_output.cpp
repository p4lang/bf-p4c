#include "asm_output.h"
#include "lib/indent.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "tofino/phv/asm_output.h"

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
        throw Util::CompilerBug("unknown attached table type %s", typeid(*att).name()); }
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
        out << indent << "group " << group.first << ": {";
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
            out << indent << "- " << r.col << std::endl;
    } else {
        out << indent << "row: " << row[0] << std::endl;
        if (have_bus) out << indent << "bus: " << bus[0] << std::endl;
        out << indent << "column:" << mem.row[0].col << std::endl;
    }
}

void MauAsmOutput::emit_action(std::ostream &out, indent_t indent,
                               const IR::ActionFunction *act) const {
    out << indent << act->name << ":" << std::endl;
    for (auto instr : act->action) {
        if (instr->name == "modify_field") {
            out << indent << "- set " << instr->operands[0] << ", " << instr->operands[1]
                << std::endl;
        } else if (instr->name == "add") {
            out << indent << "- add " << instr->operands[0] << ", " << instr->operands[1] << ", "
                << instr->operands[2] << std::endl;
        } else if (instr->name == "add_to_field") {
            out << indent << "- add " << instr->operands[0] << ", " << instr->operands[0] << ", "
                << instr->operands[1] << std::endl;
        } else {
            warning("Unhandled instruction primitive %s", instr->name); } }
    if (act->action.empty()) {
        /* a noop */
        out << indent << "- 0" << std::endl; }
}

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

    /* FIXME -- this is a mees and needs to be rewritten to be sane */
    bool have_action = false, have_indirect = false;
    for (auto at : tbl->attached) {
        if (dynamic_cast<const IR::MAU::TernaryIndirect *>(at)) {
            have_indirect = true;
            out << indent << at->kind() << ": " << at->name << std::endl;
        } else if (dynamic_cast<const IR::MAU::ActionData *>(at)) {
            have_action = true; } }

    vector<const IR::MAU::Table *>      next_hit;
    const IR::MAU::Table                *next_miss = 0;
    for (auto &next : tbl->next) {
        if (next.first == "true" || next.first == "false") {
            continue;  // for the gateway
        } else if (next.first == "$miss") {
            next_miss = next.second->front();
        } else {
            next_hit.push_back(next.second->front()); } }
    if (next_hit.empty()) {
        if (next_miss) {
            out << indent << "hit: " << default_next.next_in_thread(tbl) << std::endl;
            out << indent << "miss: " << next_miss->name << std::endl;
        } else {
            out << indent << "next: " << default_next.next_in_thread(tbl) << std::endl; }
    } else {
        if (next_hit.size() == 1) {
            out << indent << "hit: " << next_hit.front()->name << std::endl;
        } else {
            out << indent << "hit: ";
            const char *sep = next_hit.size() > 1 ? "[ " : "";
            for (auto t : next_hit) {
                out << sep << (t ? t->name : default_next.next_in_thread(tbl));
                sep = ", "; }
            out << " ]" << std::endl; }
        if (next_miss)
            out << indent << "miss: " << next_miss->name << std::endl;
        else
            out << indent << "miss: " << default_next.next_in_thread(tbl) << std::endl; }

    if (!have_indirect)
        emit_table_indir(out, indent, tbl);
    for (auto at : tbl->attached)
        at->apply(EmitAttached(*this, out, tbl));
}

void MauAsmOutput::emit_table_indir(std::ostream &out, indent_t indent,
                                    const IR::MAU::Table *tbl) const {
    for (auto at : tbl->attached) {
        out << indent << at->kind() << ": " << at->name;
        if (at->indexed())
            out << '(' << at->kind() << ')';
        out << std::endl; }
    if (!tbl->actions.empty()) {
        out << indent++ << "actions:" << std::endl;
        for (auto act : tbl->actions)
            emit_action(out, indent, act);
        --indent; }
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
    self.emit_table_indir(out, indent, tbl);
    return false; }
bool MauAsmOutput::EmitAttached::preorder(const IR::MAU::ActionData *) {
    return false; }
