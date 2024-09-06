#ifndef BF_P4C_MAU_TOFINO_ASM_OUTPUT_H_
#define BF_P4C_MAU_TOFINO_ASM_OUTPUT_H_

#include "bf-p4c/mau/asm_output.h"

namespace Tofino {

class MauAsmOutput : public ::MauAsmOutput {
 private:
    void emit_table_format(std::ostream &out, indent_t, const TableFormat::Use &use,
            const TableMatch *tm, bool ternary, bool no_match) const;
    void emit_memory(std::ostream &out, indent_t, const Memories::Use &,
            const IR::MAU::Table::Layout *l = nullptr,
            const TableFormat::Use *f = nullptr) const;
 public:
    MauAsmOutput(const PhvInfo &phv, const IR::BFN::Pipe *pipe,
                 const NextTable *nxts, const MauPower::FinalizeMauPredDepsPower* pmpr,
                 const BFN_Options &options)
        : ::MauAsmOutput(phv, pipe, nxts, pmpr, options) {}
};

}  // end namespace Tofino

#endif /* BF_P4C_MAU_TOFINO_ASM_OUTPUT_H_ */
