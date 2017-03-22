#include "target.h"
#include "ubits.h"

void declare_registers(const Target::Tofino::parser_memory *mem, const char *gress) {
    declare_registers(mem, sizeof *mem,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "parser.mem[" << gress << "]";
            mem->emit_fieldname(out, addr, end); });
}
void declare_registers(const Target::Tofino::parser_regs *regs) {
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

void declare_registers(const Target::JBay::parser_memory *mem, const char *gress) {
    declare_registers(mem, sizeof *mem,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "parser.mem[" << gress << "]";
            mem->emit_fieldname(out, addr, end); });
}
void declare_registers(const Target::JBay::parser_regs *regs) {
    declare_registers(regs, sizeof *regs,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "parser.regs";
            regs->emit_fieldname(out, addr, end); });
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

