#ifndef _EXTENSIONS_BF_P4C_ASM_H_
#define _EXTENSIONS_BF_P4C_ASM_H_

#include <fstream>
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/mau/asm_output.h"
#include "bf-p4c/parde/asm_output.h"
#include "bf-p4c/parde/clot_info.h"
#include "bf-p4c/phv/asm_output.h"
#include "bf-p4c/phv/phv_fields.h"
#include "common/run_id.h"

namespace BFN {

class AsmOutput : public Inspector {
 private:
    std::ostream*      out = nullptr;
    const PhvInfo     &phv;
    const ClotInfo    &clot;
    const BFN_Options &options;
    /// Tell this pass whether it is called after a succesful compilation
    bool               _successfulCompile = true;

 public:
    AsmOutput(const PhvInfo &phv, const ClotInfo &clot, const BFN_Options &opts, bool success) :
        phv(phv), clot(clot), options(opts), _successfulCompile(success) {
        out = &std::cout;
        if (options.outputFile)
            out = new std::ofstream(options.outputFile);
    }

    bool preorder(const IR::BFN::Pipe* pipe) override {
        LOG1("ASM generation for successful compile? " << (_successfulCompile ? "true" : "false"));

        if (_successfulCompile) {
            MauAsmOutput mauasm(phv);
            pipe->apply(mauasm);

            *out << "version:" << std::endl
                 << "  version: 1.0.0" << std::endl
                 << "  run_id: " << RunId::getId() << std::endl;
            if (::errorCount() == 0) {
                *out << PhvAsmOutput(phv)
                     << ParserAsmOutput(pipe, INGRESS)
                     << DeparserAsmOutput(pipe, phv, clot, INGRESS)
                     << ParserAsmOutput(pipe, EGRESS)
                     << DeparserAsmOutput(pipe, phv, clot, EGRESS)
                     << mauasm;
            }
            *out << std::flush; }
        return false;
    }
};

}  /* namespace BFN */

#endif  /* _EXTENSIONS_BF_P4C_ASM_H_ */
