#ifndef BF_P4C_PARDE_ASM_OUTPUT_H_
#define BF_P4C_PARDE_ASM_OUTPUT_H_

#include "bf-p4c/phv/phv_fields.h"
#include "ir/ir.h"

/// Helper that can generate parser assembly and write it to an output stream.
struct ParserAsmOutput {
    ParserAsmOutput(const IR::BFN::Pipe* pipe, gress_t gress);

 private:
    friend std::ostream& operator<<(std::ostream&, const ParserAsmOutput&);

    const IR::BFN::LoweredParser* parser;
};

/// Helper that can generate deparser assembly and write it to an output stream.
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
