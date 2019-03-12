#ifndef _EXTENSIONS_BF_P4C_ASM_H_
#define _EXTENSIONS_BF_P4C_ASM_H_

#include <limits.h>
#include <signal.h>
#include <stdio.h>
#include <sys/stat.h>
#include <fstream>
#include <iostream>
#include <string>

#include "bf-asm/version.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/mau/asm_output.h"
#include "bf-p4c/parde/asm_output.h"
#include "bf-p4c/parde/clot_info.h"
#include "bf-p4c/phv/asm_output.h"
#include "bf-p4c/phv/phv_fields.h"
#include "common/run_id.h"
#include "bf-p4c-options.h"

class FieldDefUse;

namespace BFN {

class AsmOutput : public Inspector {
 private:
    const PhvInfo     &phv;
    const ClotInfo    &clot;
    const FieldDefUse &defuse;
    const BFN_Options &options;
    /// Tell this pass whether it is called after a succesful compilation
    bool               _successfulCompile = true;
    PHV::Container ghostPhvContainer() const {
        // FIXME -- need a better way of finding the ghost metadata allocation
        if (auto *field = phv.field("ghost::gh_intr_md.ping_pong"))
            return field->for_bit(0).container;
        BUG("No allocation for ghost metadata?"); }

 public:
    AsmOutput(const PhvInfo &phv,
              const ClotInfo &clot,
              const FieldDefUse& defuse,
              const BFN_Options &opts,
              bool success)
        : phv(phv), clot(clot), defuse(defuse), options(opts), _successfulCompile(success) {}

    bool preorder(const IR::BFN::Pipe* pipe) override {
        LOG1("ASM generation for successful compile? " << (_successfulCompile ? "true" : "false"));

        if (_successfulCompile) {
            auto outputDir = BFNContext::get().getOutputDirectory("", pipe->id);
            if (!outputDir) return false;
            cstring outputFile = outputDir + "/" + options.programName + ".bfa";
            std::ofstream out(outputFile, std::ios_base::out);

            MauAsmOutput mauasm(phv, pipe);
            pipe->apply(mauasm);

            out << "version:" << std::endl
                << "  version: " << BFASM::Version::getVersion() << std::endl
                << "  run_id: \"" << RunId::getId() << "\"" << std::endl;
            if (::errorCount() == 0) {
                out << PhvAsmOutput(phv, defuse, pipe->ghost_thread != nullptr)
                    << ParserAsmOutput(pipe, INGRESS)
                    << DeparserAsmOutput(pipe, phv, clot, INGRESS);
                if (pipe->ghost_thread != nullptr)
                    out << "parser ghost: " << ghostPhvContainer() << std::endl;
                out << ParserAsmOutput(pipe, EGRESS)
                    << DeparserAsmOutput(pipe, phv, clot, EGRESS)
                    << mauasm;
            }
            out << std::flush;
        }
        return false;
    }
};

}  /* namespace BFN */

#endif  /* _EXTENSIONS_BF_P4C_ASM_H_ */
