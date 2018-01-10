#ifndef BF_P4C_PARDE_ASM_OUTPUT_H_
#define BF_P4C_PARDE_ASM_OUTPUT_H_

#include "ir/ir.h"

class PhvInfo;
class ClotInfo;

/// Helper that can generate parser assembly and write it to an output stream.
struct ParserAsmOutput {
    ParserAsmOutput(const IR::BFN::Pipe* pipe, gress_t gress);

 private:
    friend std::ostream& operator<<(std::ostream&, const ParserAsmOutput&);

    const IR::BFN::LoweredParser* parser;
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

#endif /* BF_P4C_PARDE_ASM_OUTPUT_H_ */
