#include "bfas.h"
#include "top_level.h"
#include "bson.h"
#include "binary_output.h"
#include "version.h"

TopLevel *TopLevel::all = nullptr;

TopLevel::TopLevel() {
    BUG_CHECK(!all);
    all = this;
}

TopLevel::~TopLevel() {
    all = nullptr;
}

#if HAVE_FLATROCK
// this specialization should go away once we have memory CSRs
template<>
TopLevelRegs<Target::Flatrock>::TopLevelRegs() {
    declare_registers(&this->mem_top, sizeof(this->mem_top),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "memories.top";
            /* this->mem_top.emit_fieldname(out, addr, end); */ });
    declare_registers(&this->mem_pipe, sizeof(this->mem_pipe),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "memories.pipe";
            /* this->mem_pipe.emit_fieldname(out, addr, end); */ });
    declare_registers(&this->reg_top, sizeof(this->reg_top),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "registers.top";
            this->reg_top.emit_fieldname(out, addr, end); });
    declare_registers(&this->reg_pipe, sizeof(this->reg_pipe),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "registers.pipe";
            this->reg_pipe.emit_fieldname(out, addr, end); });
}
#endif  /* HAVE_FLATROCK */
template<class TARGET>
TopLevelRegs<TARGET>::TopLevelRegs() {
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
TopLevelRegs<TARGET>::~TopLevelRegs() {
    undeclare_registers(&this->mem_top);
    undeclare_registers(&this->mem_pipe);
    undeclare_registers(&this->reg_top);
    undeclare_registers(&this->reg_pipe);
}

#if HAVE_FLATROCK
// FIXME -- factor better (once we have flatrock mems, the only difference needed
// is the name 'fpp' instead of 'pipes' (and the number of pipes)
template<>
void TopLevelRegs<Target::Flatrock>::output(json::map &ctxt_json) {
    for (int i = 0; i < Target::NUM_PIPES(); i++) {
        if (options.binary >= PIPE0 && options.binary != PIPE0 + i) {
            this->mem_top.fpp[i].disable();
            this->reg_top.fpp[i].disable();
        } else {
            this->mem_top.fpp[i].set("memories.pipe", &this->mem_pipe);
            this->reg_top.fpp[i].set("regs.pipe", &this->reg_pipe); } }
    if (options.condense_json) {
        this->mem_top.disable_if_reset_value();
        this->mem_pipe.disable_if_reset_value();
        this->reg_top.disable_if_reset_value();
        this->reg_pipe.disable_if_reset_value(); }
    if (error_count == 0) {
        if (options.gen_json) {
            this->mem_top.emit_json(*open_output("memories.top.cfg.json"));
            this->mem_pipe.emit_json(*open_output("memories.pipe.cfg.json"));
            this->reg_top.emit_json(*open_output("regs.top.cfg.json"));
            this->reg_pipe.emit_json(*open_output("regs.pipe.cfg.json")); }
        if (options.binary != NO_BINARY) {
            auto binfile = open_output("%s.bin", Target::Flatrock::name);
            json::map header;
            header["asm_version"] = BFASM::Version::getVersion();
            if (ctxt_json["compiler_version"])
                header["compiler_version"] = ctxt_json["compiler_version"]->clone();
            header["reg_version"] = Target::Flatrock::top_level_regs::_regs_top::_reg_version;
            if (ctxt_json["run_id"])
                header["run_id"] = ctxt_json["run_id"]->clone();
            if (ctxt_json["program_name"])
                header["program_name"] = ctxt_json["program_name"]->clone();
            header["target"] = Target::name();
            header["stages"] = Target::NUM_MAU_STAGES();
            *binfile << binout::tag('H') << json::binary(header);
            if (options.binary != ONE_PIPE) {
                this->mem_top.emit_binary(*binfile, 0);
                this->reg_top.emit_binary(*binfile, 0);
            } else {
                this->mem_pipe.emit_binary(*binfile, 0);
                this->reg_pipe.emit_binary(*binfile, 0); }

            if (options.multi_parsers) {
                emit_parser_registers(this, *binfile);
            }
        }
    }
}
#endif  /* HAVE_FLATROCK */
template<class TARGET>
void TopLevelRegs<TARGET>::output(json::map &ctxt_json) {
    for (int i = 0; i < Target::NUM_PIPES(); i++) {
        if (options.binary >= PIPE0 && options.binary != PIPE0 + i) {
            this->mem_top.pipes[i].disable();
            this->reg_top.pipes[i].disable();
        } else {
            this->mem_top.pipes[i].set("memories.pipe", &this->mem_pipe);
            this->reg_top.pipes[i].set("regs.pipe", &this->reg_pipe); } }
    if (options.condense_json) {
        this->mem_top.disable_if_reset_value();
        this->mem_pipe.disable_if_reset_value();
        this->reg_top.disable_if_reset_value();
        this->reg_pipe.disable_if_reset_value(); }
    if (error_count == 0) {
        if (options.gen_json) {
            this->mem_top.emit_json(*open_output("memories.top.cfg.json"));
            this->mem_pipe.emit_json(*open_output("memories.pipe.cfg.json"));
            this->reg_top.emit_json(*open_output("regs.top.cfg.json"));
            this->reg_pipe.emit_json(*open_output("regs.pipe.cfg.json")); }
        if (options.binary != NO_BINARY) {
            auto binfile = open_output("%s.bin", TARGET::name);
            json::map header;
            header["asm_version"] = BFASM::Version::getVersion();
            if (ctxt_json["compiler_version"])
                header["compiler_version"] = ctxt_json["compiler_version"]->clone();
            header["reg_version"] = TARGET::top_level_regs::_regs_top::_reg_version;
            if (ctxt_json["run_id"])
                header["run_id"] = ctxt_json["run_id"]->clone();
            if (ctxt_json["program_name"])
                header["program_name"] = ctxt_json["program_name"]->clone();
            header["target"] = Target::name();
            header["stages"] = Target::NUM_MAU_STAGES();
            *binfile << binout::tag('H') << json::binary(header);
            if (options.binary != ONE_PIPE) {
                this->mem_top.emit_binary(*binfile, 0);
                this->reg_top.emit_binary(*binfile, 0);
            } else {
                this->mem_pipe.emit_binary(*binfile, 0);
                this->reg_pipe.emit_binary(*binfile, 0); }

            if (options.multi_parsers) {
                emit_parser_registers(this, *binfile);
            }
        }
    }
}

#if HAVE_FLATROCK
template<> void TopLevelRegs<Target::Flatrock>::set_mau_stage(int stage,
            const char *file, Target::Flatrock::mau_regs *regs) {
    // FIXME -- these are just the ingress regs; need another for the egress regs
    this->reg_pipe.ppu_pack.ippu[stage].set(file, regs);
}
#endif  /* HAVE_FLATROCK */
template<class TARGET>
void TopLevelRegs<TARGET>::set_mau_stage(int stage, const char *file,
                                         typename TARGET::mau_regs *regs) {
    this->reg_pipe.mau[stage].set(file, regs);
}

#define TOP_LEVEL_REGS(REGSET)        template class TopLevelRegs<Target::REGSET>;
FOR_ALL_REGISTER_SETS(TOP_LEVEL_REGS)
