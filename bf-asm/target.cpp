#include <config.h>

#include "asm-types.h"
#include "bson.h"
#include "target.h"
#include "ubits.h"
#include "parser.h"

void declare_registers(const Target::Tofino::top_level_regs *regs) {
    declare_registers(&regs->mem_top, sizeof(regs->mem_top),
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "memories.top";
            regs->mem_top.emit_fieldname(out, addr, end); });
    declare_registers(&regs->mem_pipe, sizeof(regs->mem_pipe),
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "memories.pipe";
            regs->mem_pipe.emit_fieldname(out, addr, end); });
    declare_registers(&regs->reg_top, sizeof(regs->reg_top),
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "registers.top";
            regs->reg_top.emit_fieldname(out, addr, end); });
    declare_registers(&regs->reg_pipe, sizeof(regs->reg_pipe),
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "registers.pipe";
            regs->reg_pipe.emit_fieldname(out, addr, end); });
}
void undeclare_registers(const Target::Tofino::top_level_regs *regs) {
    undeclare_registers(&regs->mem_top);
    undeclare_registers(&regs->mem_pipe);
    undeclare_registers(&regs->reg_top);
    undeclare_registers(&regs->reg_pipe);
}

void declare_registers(const Target::Tofino::parser_regs *regs) {
    declare_registers(&regs->memory[INGRESS], sizeof regs->memory[INGRESS],
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "parser.mem[INGRESS]";
            regs->memory[INGRESS].emit_fieldname(out, addr, end); });
    declare_registers(&regs->memory[EGRESS], sizeof regs->memory[EGRESS],
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "parser.mem[EGRESS]";
            regs->memory[EGRESS].emit_fieldname(out, addr, end); });
    declare_registers(&regs->ingress, sizeof regs->ingress,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "parser.ibp_reg";
            regs->ingress.emit_fieldname(out, addr, end); });
    declare_registers(&regs->egress, sizeof regs->egress,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "parser.ebp_reg";
            regs->egress.emit_fieldname(out, addr, end); });
    declare_registers(&regs->merge, sizeof regs->merge,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "parser.merge";
            regs->merge.emit_fieldname(out, addr, end); });
}
void undeclare_registers(const Target::Tofino::parser_regs *regs) {
    undeclare_registers(&regs->memory[INGRESS]);
    undeclare_registers(&regs->memory[EGRESS]);
    undeclare_registers(&regs->ingress);
    undeclare_registers(&regs->egress);
    undeclare_registers(&regs->merge);
}
void declare_registers(const Target::Tofino::mau_regs *regs, int stage) {
    declare_registers(regs, sizeof *regs,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "mau[" << stage << "]";
            regs->emit_fieldname(out, addr, end); });
}
void declare_registers(const Target::Tofino::deparser_regs *regs) {
    declare_registers(&regs->input, sizeof(regs->input),
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "deparser.input_phase";
            regs->input.emit_fieldname(out, addr, end); });
    declare_registers(&regs->header, sizeof(regs->header),
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "deparser.header_phase";
            regs->header.emit_fieldname(out, addr, end); });
}
void undeclare_registers(const Target::Tofino::deparser_regs *regs) {
    undeclare_registers(&regs->input);
    undeclare_registers(&regs->header);
}

void emit_parser_registers(const Target::Tofino::top_level_regs* regs, std::ostream &out, uint64_t a) {
    std::set<int> emitted_parsers;
    for (auto ig : regs->parser_ingress) {
        json::map header;
        header["handle"] = ig.first;
        out << binout::tag('P') << json::binary(header);
        ig.second->emit_binary(out, 0); }
    for (auto eg : regs->parser_egress) {
        json::map header;
        header["handle"] = eg.first;
        out << binout::tag('P') << json::binary(header);
        eg.second->emit_binary(out, 0); }
    for (auto ig : regs->parser_memory[INGRESS]) {
        json::map header;
        header["handle"] = ig.first;
        out << binout::tag('P') << json::binary(header);
        ig.second->emit_binary(out, 0); }
    for (auto eg : regs->parser_memory[EGRESS]) {
        json::map header;
        header["handle"] = eg.first;
        out << binout::tag('P') << json::binary(header);
        eg.second->emit_binary(out, 0); }
}

#if HAVE_JBAY
void declare_registers(const Target::JBay::top_level_regs *regs) {
    declare_registers(&regs->mem_top, sizeof(regs->mem_top),
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "memories.top";
            regs->mem_top.emit_fieldname(out, addr, end); });
    declare_registers(&regs->mem_pipe, sizeof(regs->mem_pipe),
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "memories.pipe";
            regs->mem_pipe.emit_fieldname(out, addr, end); });
    declare_registers(&regs->reg_top, sizeof(regs->reg_top),
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "registers.top";
            regs->reg_top.emit_fieldname(out, addr, end); });
    declare_registers(&regs->reg_pipe, sizeof(regs->reg_pipe),
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "registers.pipe";
            regs->reg_pipe.emit_fieldname(out, addr, end); });
}
void undeclare_registers(const Target::JBay::top_level_regs *regs) {
    undeclare_registers(&regs->mem_top);
    undeclare_registers(&regs->mem_pipe);
    undeclare_registers(&regs->reg_top);
    undeclare_registers(&regs->reg_pipe);
}
void declare_registers(const Target::JBay::parser_regs *regs) {
    declare_registers(&regs->memory[INGRESS], sizeof regs->memory[INGRESS],
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "parser.mem[INGRESS]";
            regs->memory[INGRESS].emit_fieldname(out, addr, end); });
    declare_registers(&regs->memory[EGRESS], sizeof regs->memory[EGRESS],
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "parser.mem[EGRESS]";
            regs->memory[EGRESS].emit_fieldname(out, addr, end); });
    declare_registers(&regs->ingress, sizeof regs->ingress,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "parser.ipb_reg";
            regs->ingress.emit_fieldname(out, addr, end); });
    declare_registers(&regs->egress, sizeof regs->egress,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "parser.epb_reg";
            regs->egress.emit_fieldname(out, addr, end); });
    declare_registers(&regs->main[INGRESS], sizeof regs->main[INGRESS],
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "parser.ingress.main";
            regs->main[INGRESS].emit_fieldname(out, addr, end); });
    declare_registers(&regs->main[EGRESS], sizeof regs->main[EGRESS],
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "parser.egress.main";
            regs->main[EGRESS].emit_fieldname(out, addr, end); });
    declare_registers(&regs->merge, sizeof regs->merge,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "parser.merge";
            regs->merge.emit_fieldname(out, addr, end); });
}
void undeclare_registers(const Target::JBay::parser_regs *regs) {
    undeclare_registers(&regs->memory[INGRESS]);
    undeclare_registers(&regs->memory[EGRESS]);
    undeclare_registers(&regs->ingress);
    undeclare_registers(&regs->egress);
    undeclare_registers(&regs->main[INGRESS]);
    undeclare_registers(&regs->main[EGRESS]);
    undeclare_registers(&regs->merge);
}
void declare_registers(const Target::JBay::mau_regs *regs, int stage) {
    declare_registers(regs, sizeof *regs,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "mau[" << stage << "]";
            regs->emit_fieldname(out, addr, end); });
}
void declare_registers(const Target::JBay::deparser_regs *regs) {
    declare_registers(regs, sizeof *regs,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "deparser.regs";
            regs->emit_fieldname(out, addr, end); });
}

void emit_parser_registers(const Target::JBay::top_level_regs *regs, std::ostream &out, uint64_t a) {
    std::set<int> emitted_parsers;
    for (auto ig : regs->parser_ingress) {
        json::map header;
        header["handle"] = ig.first;
        out << binout::tag('P') << json::binary(header);
        ig.second->emit_binary(out, 0); }
    for (auto eg : regs->parser_egress) {
        json::map header;
        header["handle"] = eg.first;
        out << binout::tag('P') << json::binary(header);
        eg.second->emit_binary(out, 0); }
    for (auto ig : regs->parser_main[INGRESS]) {
        json::map header;
        header["handle"] = ig.first;
        out << binout::tag('P') << json::binary(header);
        ig.second->emit_binary(out, 0); }
    for (auto eg : regs->parser_main[EGRESS]) {
        json::map header;
        header["handle"] = eg.first;
        out << binout::tag('P') << json::binary(header);
        eg.second->emit_binary(out, 0); }
    for (auto ig : regs->parser_memory[INGRESS]) {
        json::map header;
        header["handle"] = ig.first;
        out << binout::tag('P') << json::binary(header);
        ig.second->emit_binary(out, 0); }
    for (auto eg : regs->parser_memory[EGRESS]) {
        json::map header;
        header["handle"] = eg.first;
        out << binout::tag('P') << json::binary(header);
        eg.second->emit_binary(out, 0); }
}

#endif // HAVE_JBAY

int Target::encodeConst(int src) {
    SWITCH_FOREACH_TARGET(options.target, return TARGET::encodeConst(src); );
    BUG(); return 0;
}

// should these be inline in the header file?
#define DEFINE_PER_TARGET_CONSTANT(TYPE, NAME)                          \
TYPE Target::NAME() {                                                   \
    SWITCH_FOREACH_TARGET(options.target, return TARGET::NAME; )        \
    BUG_CHECK(!"invalid target");                                       \
    return (TYPE){};                                                    \
}
PER_TARGET_CONSTANTS(DEFINE_PER_TARGET_CONSTANT)
