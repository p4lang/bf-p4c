#include "bfas.h"
#include "top_level.h"

TopLevel *TopLevel::all = nullptr;

TopLevel::TopLevel() {
    assert(!all);
    all = this;
}

TopLevel::~TopLevel() {
    all = nullptr;
}

template<class TARGET>
TopLevelTarget<TARGET>::TopLevelTarget() {
    declare_registers(&this->mem_top, sizeof(this->mem_top),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "memories.top";
            this->mem_top.emit_fieldname(out, addr, end); });
    declare_registers(&this->mem_pipe, sizeof(this->mem_pipe),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "memories.pipe";
            this->mem_pipe.emit_fieldname(out, addr, end); });
    declare_registers(&this->reg_top, sizeof(this->reg_top),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "registers.top";
            this->reg_top.emit_fieldname(out, addr, end); });
    declare_registers(&this->reg_pipe, sizeof(this->reg_pipe),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "registers.pipe";
            this->reg_pipe.emit_fieldname(out, addr, end); });
}

template<class TARGET>
TopLevelTarget<TARGET>::~TopLevelTarget() {
    undeclare_registers(&this->mem_top);
    undeclare_registers(&this->mem_pipe);
    undeclare_registers(&this->reg_top);
    undeclare_registers(&this->reg_pipe);
}

template<class TARGET>
void TopLevelTarget<TARGET>::output(json::map &) {
    for (int i = 0; i < 4; i++) {
        this->mem_top.pipes[i].set("memories.pipe", &this->mem_pipe);
        this->reg_top.pipes[i].set("regs.pipe", &this->reg_pipe); }
    //this->reg_top.macs.disable();
    //this->reg_top.serdes.disable();
    if (options.condense_json) {
        this->mem_top.disable_if_zero();
        this->mem_pipe.disable_if_zero();
        this->reg_top.disable_if_zero();
        this->reg_pipe.disable_if_zero(); }
    if (error_count == 0) {
        if (options.gen_json) {
            this->mem_top.emit_json(*open_output("memories.top.cfg.json"));
            this->mem_pipe.emit_json(*open_output("memories.pipe.cfg.json"));
            this->reg_top.emit_json(*open_output("regs.top.cfg.json"));
            this->reg_pipe.emit_json(*open_output("regs.pipe.cfg.json")); }
        if (options.binary != NO_BINARY) {
            auto binfile = open_output("%s.bin", TARGET::name);
            if (options.binary == FOUR_PIPE) {
                this->mem_top.emit_binary(*binfile, 0);
                this->reg_top.emit_binary(*binfile, 0);
            } else if (options.binary == ONE_PIPE) {
                this->mem_pipe.emit_binary(*binfile, 0);
                this->reg_pipe.emit_binary(*binfile, 0); } } }
}

template class TopLevelTarget<Target::Tofino>;
#if HAVE_JBAY
template class TopLevelTarget<Target::JBay>;
#endif
