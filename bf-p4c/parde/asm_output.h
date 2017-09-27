#ifndef BF_P4C_PARDE_ASM_OUTPUT_H_
#define BF_P4C_PARDE_ASM_OUTPUT_H_

#include <functional>
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/phv/phv_fields.h"
#include "ir/ir.h"
#include "lib/safe_vector.h"

class ParserAsmOutput : public Inspector {
    gress_t                                     gress;
    const PhvInfo                               &phv;
    const IR::BFN::Parser                    *parser;
    safe_vector<const IR::BFN::ParserState *> states;
    bool preorder(const IR::BFN::ParserState *state) override {
        states.push_back(state);
        return true; }
    friend std::ostream &operator<<(std::ostream &, const ParserAsmOutput &);
 public:
    ParserAsmOutput(const IR::BFN::Pipe *pipe, const PhvInfo &phv, gress_t gr)
    : gress(gr), phv(phv), parser(pipe->thread[gress].parser) {
        if (parser) parser->apply(*this); }
};

class DeparserAsmOutput {
    gress_t                     gress;
    const PhvInfo               &phv;
    const IR::BFN::Deparser  *deparser;
    friend std::ostream &operator<<(std::ostream &, const DeparserAsmOutput &);
 public:
    DeparserAsmOutput(const IR::BFN::Pipe *pipe, const PhvInfo &phv, gress_t gr)
    : gress(gr), phv(phv), deparser(pipe->thread[gress].deparser) {}

    void emit_fieldlist(std::ostream &out, const IR::Vector<IR::Expression> *list,
                        const char *sep = "") const;
};

#endif /* BF_P4C_PARDE_ASM_OUTPUT_H_ */
