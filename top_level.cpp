#include "tfas.h"
#include "top_level.h"

TopLevel TopLevel::all;

void TopLevel::output() {
    for (int i = 0; i < 4; i++) {
        mem_top.pipes[i] = "memories.pipe";
        reg_top.pipes[i] = "regs.pipe"; }
    reg_top.macs.disable();
    reg_top.serdes.disable();
    mem_top.emit_json(*open_output("memories.top.cfg.json"));
    mem_pipe.emit_json(*open_output("memories.pipe.cfg.json"));
    reg_top.emit_json(*open_output("regs.top.cfg.json"));
    reg_pipe.emit_json(*open_output("regs.pipe.cfg.json"));
}
