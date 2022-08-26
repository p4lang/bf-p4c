#ifndef BF_P4C_MAU_FLATROCK_ASM_OUTPUT_H_
#define BF_P4C_MAU_FLATROCK_ASM_OUTPUT_H_

#include "bf-p4c/mau/asm_output.h"

namespace Flatrock {

class PpuAsmOutput : public MauAsmOutput {
 private:
    void emit_table_format(std::ostream &out, indent_t, const TableFormat::Use &use,
            const TableMatch *tm, bool ternary, bool no_match) const override;
    bool gateway_uses_inhibit_index(const IR::MAU::Table *) const override;
 public:
    PpuAsmOutput(const PhvInfo &phv, const IR::BFN::Pipe *pipe,
                 const NextTable *nxts, const MauPower::FinalizeMauPredDepsPower* pmpr,
                 const BFN_Options &options)
        : MauAsmOutput(phv, pipe, nxts, pmpr, options) {}
};

}  // end namespace Flatrock

#endif /* BF_P4C_MAU_FLATROCK_ASM_OUTPUT_H_ */
