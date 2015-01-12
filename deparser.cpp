#include "deparser.h"
#include "phv.h"
#include <fstream>

Deparser Deparser::singleton_object;

Deparser::Deparser() : Section("deparser") {
    declare_registers(&mem, sizeof(mem),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "deparser.mem[";
            if (addr < (const char *)&mem[EGRESS]) {
                out << "INGRESS]";
                mem[INGRESS].emit_fieldname(out, addr, end);
            } else {
                out << "EGRESS]";
                mem[EGRESS].emit_fieldname(out, addr, end); } });
    declare_registers(&reg, sizeof(reg),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "deparser.reg[";
            if (addr < (const char *)&reg[EGRESS]) {
                out << "INGRESS]";
                reg[INGRESS].emit_fieldname(out, addr, end);
            } else {
                out << "EGRESS]";
                reg[EGRESS].emit_fieldname(out, addr, end); } });
}
Deparser::~Deparser() {
    undeclare_registers(&mem);
    undeclare_registers(&reg);
}

void Deparser::start(int lineno, VECTOR(value_t) args) {
}
void Deparser::input(VECTOR(value_t) args, value_t data) {
}
void Deparser::process() {
}
void Deparser::output() {
    std::ofstream mem_in("memories.all.deparser.ingress.cfg.json");
    mem[INGRESS].emit_json(mem_in, "ingress");
    std::ofstream mem_eg("memories.all.deparser.egress.cfg.json");
    mem[EGRESS].emit_json(mem_eg, "egress");
    std::ofstream reg_in("regs.all.deparser.ingress.cfg.json");
    reg[INGRESS].emit_json(reg_in, "ingress");
    std::ofstream reg_eg("regs.all.deparser.egress.cfg.json");
    reg[EGRESS].emit_json(reg_eg, "egress");
}
