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

void emit_parser_registers(const Target::Tofino::top_level_regs* regs, std::ostream &out) {
    std::set<int> emitted_parsers;
    // The driver can reprogram parser blocks at runtime. We output parser
    // blocks in the binary with the same base address. The driver uses the
    // parser handle at the start of each block to associate the parser block
    // with its respective parser node in context.json.
    // In a p4 program, the user can associate multiple parsers to a
    // multi-parser configuration but only map a few ports. The unmapped
    // parser(s) will be output in context.json node and binary but not have an
    // associated port map in context.json. The driver will not initialize any
    // parsers with these unmapped parser(s) but use them to reconfigure at
    // runtime if required.
    uint64_t pipe_mem_base_addr = 0x200000000000;
    uint64_t prsr_mem_base_addr = (pipe_mem_base_addr + 0x1C800000000) >> 4;
    uint64_t pipe_regs_base_addr = 0x2000000;
    uint64_t prsr_regs_base_addr = pipe_regs_base_addr + 0x700000;
    for (auto ig : regs->parser_ingress) {
        out << binout::tag('P') << binout::byte4(ig.first);
        ig.second->emit_binary(out, prsr_regs_base_addr);
    }
    for (auto ig : regs->parser_memory[INGRESS]) {
        out << binout::tag('P') << binout::byte4(ig.first);
        ig.second->emit_binary(out, prsr_mem_base_addr);
    }
    prsr_regs_base_addr = pipe_regs_base_addr + 0x740000;
    for (auto eg : regs->parser_egress) {
        out << binout::tag('P') << binout::byte4(eg.first);
        eg.second->emit_binary(out, prsr_regs_base_addr);
    }
    prsr_mem_base_addr = (pipe_mem_base_addr + 0x1C800400000) >> 4;
    for (auto eg : regs->parser_memory[EGRESS]) {
        out << binout::tag('P') << binout::byte4(eg.first);
        eg.second->emit_binary(out, prsr_mem_base_addr);
    }
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

void emit_parser_registers(const Target::JBay::top_level_regs *regs, std::ostream &out) {
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
#endif  /* HAVE_JBAY */

#if HAVE_CLOUDBREAK
void declare_registers(const Target::Cloudbreak::top_level_regs *regs) {
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
void undeclare_registers(const Target::Cloudbreak::top_level_regs *regs) {
    undeclare_registers(&regs->mem_top);
    undeclare_registers(&regs->mem_pipe);
    undeclare_registers(&regs->reg_top);
    undeclare_registers(&regs->reg_pipe);
}
void declare_registers(const Target::Cloudbreak::parser_regs *regs) {
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
void undeclare_registers(const Target::Cloudbreak::parser_regs *regs) {
    undeclare_registers(&regs->memory[INGRESS]);
    undeclare_registers(&regs->memory[EGRESS]);
    undeclare_registers(&regs->ingress);
    undeclare_registers(&regs->egress);
    undeclare_registers(&regs->main[INGRESS]);
    undeclare_registers(&regs->main[EGRESS]);
    undeclare_registers(&regs->merge);
}
void declare_registers(const Target::Cloudbreak::mau_regs *regs, int stage) {
    declare_registers(regs, sizeof *regs,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "mau[" << stage << "]";
            regs->emit_fieldname(out, addr, end); });
}
void declare_registers(const Target::Cloudbreak::deparser_regs *regs) {
    declare_registers(regs, sizeof *regs,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "deparser.regs";
            regs->emit_fieldname(out, addr, end); });
}

void emit_parser_registers(const Target::Cloudbreak::top_level_regs *regs, std::ostream &out) {
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
#endif  /* HAVE_CLOUDBREAK */

#if HAVE_FLATROCK
void declare_registers(const Target::Flatrock::top_level_regs *regs) {
    declare_registers(&regs->reg_top, sizeof(regs->reg_top),
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "registers.top";
            regs->reg_top.emit_fieldname(out, addr, end); });
    declare_registers(&regs->reg_pipe, sizeof(regs->reg_pipe),
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "registers.pipe";
            regs->reg_pipe.emit_fieldname(out, addr, end); });
}
void undeclare_registers(const Target::Flatrock::top_level_regs *regs) {
    undeclare_registers(&regs->reg_top);
    undeclare_registers(&regs->reg_pipe);
}
void declare_registers(const Target::Flatrock::parser_regs *regs) {
    declare_registers(&regs->prsr, sizeof regs->prsr,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "parser.regs";
            regs->prsr.emit_fieldname(out, addr, end); });
    declare_registers(&regs->prsr_mem, sizeof regs->prsr_mem,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "parser.mem";
            regs->prsr_mem.emit_fieldname(out, addr, end); });
    declare_registers(&regs->pprsr, sizeof regs->pprsr,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "pseudo_parser.regs";
            regs->pprsr.emit_fieldname(out, addr, end); });
    declare_registers(&regs->pprsr_mem, sizeof regs->pprsr_mem,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "pseudo_parser.mem";
            regs->pprsr_mem.emit_fieldname(out, addr, end); });
}
void undeclare_registers(const Target::Flatrock::parser_regs *regs) {
    undeclare_registers(&regs->pprsr_mem);
    undeclare_registers(&regs->pprsr);
    undeclare_registers(&regs->prsr_mem);
    undeclare_registers(&regs->prsr);
}
void declare_registers(const Target::Flatrock::mau_regs *regs, int stage) {
    declare_registers(regs, sizeof *regs,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "mau[" << stage << "]";
            regs->emit_fieldname(out, addr, end); });
}
void declare_registers(const Target::Flatrock::deparser_regs *regs) {
    declare_registers(&regs->mdp, sizeof regs->mdp,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "mdp.regs";
            regs->mdp.emit_fieldname(out, addr, end); });
    declare_registers(&regs->mdp_mem, sizeof regs->mdp_mem,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "mdp.mem";
            regs->mdp_mem.emit_fieldname(out, addr, end); });
    declare_registers(&regs->dprsr, sizeof regs->dprsr,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "deparser.regs";
            regs->dprsr.emit_fieldname(out, addr, end); });
    declare_registers(&regs->dprsr_mem, sizeof regs->dprsr_mem,
        [=](std::ostream &out, const char *addr, const void *end) {
            out << "deparser.mem";
            regs->dprsr_mem.emit_fieldname(out, addr, end); });
}

void emit_parser_registers(const Target::Flatrock::top_level_regs *regs, std::ostream &out) {
}
#endif  /* HAVE_FLATROCK */

int Target::numMauStagesOverride = 0;

int Target::encodeConst(int src) {
    SWITCH_FOREACH_TARGET(options.target, return TARGET::encodeConst(src); );
    BUG(); return 0;
}

void Target::OVERRIDE_NUM_MAU_STAGES(int num) {
    int allowed = NUM_MAU_STAGES_PRIVATE();
    BUG_CHECK(num > 0 && num <= allowed,
        "Invalid override for NUM_MAU_STAGES. Allowed range is <1, %d>, got %d.", allowed, num);

    numMauStagesOverride = num;
    return;
}

// should these be inline in the header file?
#define DEFINE_PER_TARGET_CONSTANT(TYPE, NAME)                          \
TYPE Target::NAME() {                                                   \
    SWITCH_FOREACH_TARGET(options.target, return TARGET::NAME; )        \
    return (TYPE){};                   /* NOLINT(readability/braces) */ \
}
PER_TARGET_CONSTANTS(DEFINE_PER_TARGET_CONSTANT)
