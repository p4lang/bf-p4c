#include "asm-types.h"
#include "target.h"
#include "ubits.h"

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
    declare_registers(&regs->main, sizeof regs->main,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "parser.main";
            regs->merge.emit_fieldname(out, addr, end); });
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
    undeclare_registers(&regs->main);
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

