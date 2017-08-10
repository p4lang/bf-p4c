#ifndef _TOFINO_PARDE_ASM_OUTPUT_H_
#define _TOFINO_PARDE_ASM_OUTPUT_H_

#include <functional>
#include "ir/ir.h"
#include "tofino/common/asm_output.h"
#include "tofino/phv/phv_fields.h"

class ParserAsmOutput : public Inspector {
    gress_t                                     gress;
    const PhvInfo                               &phv;
    const IR::Tofino::Parser                    *parser;
    vector<const IR::Tofino::ParserState *>     states;
    bool preorder(const IR::Tofino::ParserState *state) override {
        states.push_back(state);
        return true; }
    friend std::ostream &operator<<(std::ostream &, const ParserAsmOutput &);
 public:
    ParserAsmOutput(const IR::Tofino::Pipe *pipe, const PhvInfo &phv, gress_t gr)
    : gress(gr), phv(phv), parser(pipe->thread[gress].parser) {
        if (parser) parser->apply(*this); }
};

class DeparserAsmOutput {
    gress_t                     gress;
    const PhvInfo               &phv;
    const IR::Tofino::Deparser  *deparser;
    friend std::ostream &operator<<(std::ostream &, const DeparserAsmOutput &);
 public:
    DeparserAsmOutput(const IR::Tofino::Pipe *pipe, const PhvInfo &phv, gress_t gr)
    : gress(gr), phv(phv), deparser(pipe->thread[gress].deparser) {}

    void emit_fieldlist(
        std::ostream &out,
        const IR::Vector<IR::Expression> *list,
        const cstring *mirror_select = nullptr,
        const char *sep = "") const;
};

#endif /* _TOFINO_PARDE_ASM_OUTPUT_H_ */
