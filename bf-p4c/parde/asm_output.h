#ifndef BF_P4C_PARDE_ASM_OUTPUT_H_
#define BF_P4C_PARDE_ASM_OUTPUT_H_

#include "ir/ir.h"
#include "bf-p4c-options.h"
#include "bf-p4c/parde/parser_header_sequences.h"

class PhvInfo;
class ClotInfo;

/// Helper that can generate parser assembly and write it to an output stream.
struct ParserAsmOutput {
    ParserAsmOutput(const IR::BFN::Pipe* pipe, const PhvInfo &phv, gress_t gress);

 private:
    friend std::ostream& operator<<(std::ostream&, const ParserAsmOutput&);

    std::vector<const IR::BFN::LoweredParser*> parsers;
    const PhvInfo               &phv;
};

/// Helper that can generate phase0 assembly and write it to an output stream.
struct Phase0AsmOutput {
    const IR::BFN::Pipe *pipe;
    const IR::BFN::Phase0 *phase0;
    Phase0AsmOutput(const IR::BFN::Pipe* pipe, const IR::BFN::Phase0* phase0)
        : pipe(pipe), phase0(phase0) {}

 private:
    friend std::ostream& operator<<(std::ostream&, const Phase0AsmOutput&);
};

/// Helper that can generate deparser assembly and write it to an output stream.
struct DeparserAsmOutput {
    DeparserAsmOutput(const IR::BFN::Pipe* pipe, const PhvInfo &phv, const ClotInfo &clot,
                      gress_t);

    const PhvInfo               &phv;
    const ClotInfo              &clot;

 private:
    friend std::ostream &operator<<(std::ostream&, const DeparserAsmOutput&);

    const IR::BFN::LoweredDeparser* deparser;
};

/// Helper that can generate header assembly and write it to an output stream.
struct HeaderAsmOutput {
    explicit HeaderAsmOutput(const ParserHeaderSequences &seqs);

 private:
    friend std::ostream& operator<<(std::ostream&, const HeaderAsmOutput&);

    const ParserHeaderSequences &seqs;
};

#endif /* BF_P4C_PARDE_ASM_OUTPUT_H_ */
