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
    std::ostream*      out = nullptr;
    const PhvInfo     &phv;
    const ClotInfo    &clot;
    const FieldDefUse &defuse;
    const BFN_Options &options;
    const cstring pipeName;
    /// Tell this pass whether it is called after a succesful compilation
    bool               _successfulCompile = true;

 public:
    AsmOutput(const PhvInfo &phv,
              const ClotInfo &clot,
              const FieldDefUse& defuse,
              const BFN_Options &opts,
              const cstring pipeName,
              bool success)
          : phv(phv), clot(clot), defuse(defuse), options(opts),
            pipeName(pipeName), _successfulCompile(success) {
        out = &std::cout;
        auto openmode = std::ios_base::out;
        if (options.outputDir) {
            std::string outputDir(opts.outputDir.c_str());
            if (opts.langVersion == BFN_Options::FrontendVersion::P4_16) {
                outputDir = outputDir + "/" + pipeName;
            }
            int rc = mkdir(outputDir.c_str(), 0755);
            if (rc != 0 && errno != EEXIST) {
                std::cerr << "Failed to create directory: " << outputDir << std::endl;
                return;
            }
            std::string dir(outputDir);
            cstring outputFile = dir + "/" + opts.programName + ".bfa";
            out = new std::ofstream(outputFile, openmode);
        }
    }
    bool preorder(const IR::BFN::Pipe* pipe) override {
        LOG1("ASM generation for successful compile? " << (_successfulCompile ? "true" : "false"));

        if (_successfulCompile) {
            MauAsmOutput mauasm(phv);
            pipe->apply(mauasm);

            *out << "version:" << std::endl
                 << "  version: " << BFASM::Version::getVersion() << std::endl
                 << "  run_id: \"" << RunId::getId() << "\"" << std::endl;
            if (::errorCount() == 0) {
                *out << PhvAsmOutput(phv, defuse, pipe->ghost_thread != nullptr)
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
