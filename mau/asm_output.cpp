#include "asm_output.h"
#include "lib/indent.h"
#include "lib/log.h"
#include "lib/stringref.h"

std::ostream &operator<<(std::ostream &out, const MauAsmOutput &mauasm) {
    for (auto &stage : mauasm.by_stage) {
        out << "stage " << stage.first.second << ' ' << stage.first.first << ':' << std::endl;
        for (auto tbl : stage.second)
            mauasm.emit_table(out, tbl); }
    return out;
}

static StringRef trim_name(StringRef name) {
    if (auto *p = name.find('['))
        name = name.before(p);
    if (auto *p = name.findlast(':'))
        name = name.after(p+1);
    return name;
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
            out << (b.first*8) << ": " << trim_name(b.second->field) << '('
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

void MauAsmOutput::emit_table(std::ostream &out, const IR::MAU::Table *tbl) const {
    /* FIXME -- some of this should be method(s) in IR::MAU::Table? */
    const char *tbl_type = "gateway";
    indent_t    indent(1);
    if (tbl->match_table)
        tbl_type = tbl->layout.ternary ? "ternary_match" : "exact_match";
    out << indent++ << tbl_type << ' '<< tbl->name << ' ' << tbl->logical_id % 16U << ':'
        << std::endl;
    if (tbl->match_table) {
        emit_memory(out, indent, tbl->resources->memuse.at(tbl->name));
        emit_ixbar(out, indent, tbl->resources->match_ixbar);
    }
}
