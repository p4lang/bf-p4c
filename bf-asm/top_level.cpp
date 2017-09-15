#include "tfas.h"
#include "top_level.h"

TopLevel TopLevel::all;

TopLevel::TopLevel() {
    declare_registers(&mem_top, sizeof(mem_top),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "memories.top";
            mem_top.emit_fieldname(out, addr, end); });
    declare_registers(&mem_pipe, sizeof(mem_pipe),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "memories.pipe";
            mem_pipe.emit_fieldname(out, addr, end); });
    declare_registers(&reg_top, sizeof(reg_top),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "registers.top";
            reg_top.emit_fieldname(out, addr, end); });
    declare_registers(&reg_pipe, sizeof(reg_pipe),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "registers.pipe";
            reg_pipe.emit_fieldname(out, addr, end); });
}

TopLevel::~TopLevel() {
    undeclare_registers(&mem_top);
    undeclare_registers(&mem_pipe);
    undeclare_registers(&reg_top);
    undeclare_registers(&reg_pipe);
}

void TopLevel::output(json::map &) {
    for (int i = 0; i < 4; i++) {
        mem_top.pipes[i] = "memories.pipe";
        reg_top.pipes[i] = "regs.pipe"; }
    //reg_top.macs.disable();
    //reg_top.serdes.disable();
    if (!options.match_compiler) {
        mem_top.disable_if_zero();
        mem_pipe.disable_if_zero();
        reg_top.disable_if_zero();
        reg_pipe.disable_if_zero(); }
    mem_top.emit_json(*open_output("memories.top.cfg.json"));
    mem_pipe.emit_json(*open_output("memories.pipe.cfg.json"));
    reg_top.emit_json(*open_output("regs.top.cfg.json"));
    reg_pipe.emit_json(*open_output("regs.pipe.cfg.json"));
    if (!name_lookup.empty())
        *open_output("p4_name_lookup.json") <<  &name_lookup << std::endl;
}
