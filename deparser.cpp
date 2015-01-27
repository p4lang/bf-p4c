#include "deparser.h"
#include "phv.h"
#include <fstream>

Deparser Deparser::singleton_object;

Deparser::Deparser() : Section("deparser") {
    declare_registers(&inp_regs, sizeof(inp_regs),
        [](std::ostream &out, const char *addr, const void *end) {
            out << "deparser.input_phase"; });
    declare_registers(&hdr_regs, sizeof(inp_regs),
        [](std::ostream &out, const char *addr, const void *end) {
            out << "deparser.header_phase"; });
}
Deparser::~Deparser() {
    undeclare_registers(&inp_regs);
    undeclare_registers(&hdr_regs);
}

void Deparser::start(int lineno, VECTOR(value_t) args) {
}
void Deparser::input(VECTOR(value_t) args, value_t data) {
}
void Deparser::process() {
}
void Deparser::output() {
    std::ofstream reg_inp("regs.all.deparser.input_phase.cfg.json");
    inp_regs.emit_json(reg_inp);
    std::ofstream reg_hdr("regs.all.deparser.header_phase.cfg.json");
    hdr_regs.emit_json(reg_hdr);
}
