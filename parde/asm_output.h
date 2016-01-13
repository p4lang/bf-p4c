#ifndef _TOFINO_PARDE_ASM_OUTPUT_H_
#define _TOFINO_PARDE_ASM_OUTPUT_H_

#include <functional>
#include "../ir/tofino.h"
#include "tofino/common/asm_output.h"

class ParserAsmOutput : public Inspector {
    gress_t                                     gress;
    const IR::Tofino::Parser                    *parser;
    vector<const IR::Tofino::ParserState *>     states;
    bool preorder(const IR::Tofino::ParserState *state) override {
        states.push_back(state);
        return true; }
    friend std::ostream &operator<<(std::ostream &, const ParserAsmOutput &);
 public:
    ParserAsmOutput(const IR::Tofino::Pipe *pipe, gress_t gr)
    : gress(gr), parser(pipe->thread[gress].parser) {
        parser->apply(*this); }
};

class DeparserAsmOutput {
    gress_t                     gress;
    const IR::Tofino::Deparser  *deparser;
    friend std::ostream &operator<<(std::ostream &, const DeparserAsmOutput &);
 public:
    DeparserAsmOutput(const IR::Tofino::Pipe *pipe, gress_t gr)
    : gress(gr), deparser(pipe->thread[gress].deparser) {}
};

#endif /* _TOFINO_PARDE_ASM_OUTPUT_H_ */
