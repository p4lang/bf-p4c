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
#include "bf-p4c/common/flexible_packing.h"
#include "bf-p4c/device.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/mau/asm_output.h"
#include "bf-p4c/mau/tofino/asm_output.h"
#include "bf-p4c/mau/flatrock/asm_output.h"
#include "bf-p4c/mau/jbay_next_table.h"
#include "bf-p4c/parde/clot/clot_info.h"
#include "bf-p4c/parde/asm_output.h"
#include "bf-p4c/parde/parser_header_sequences.h"
#include "bf-p4c/phv/asm_output.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/utils/live_range_report.h"
#include "common/run_id.h"
#include "bf-p4c-options.h"

class FieldDefUse;

namespace BFN {

/**
 * \defgroup AsmOutput Assembly output
 *
 * \brief Generate assembly output
 *
 * Generate the assembly output for the program. Invokes separate subpasses for outputting %PHV,
 * parser, deparser, and %MAU sections.
 */

/**
 * \ingroup AsmOutput
 *
 * \brief Generate assembly output
 *
 * Generate the assembly output for the program. Invokes separate subpasses for outputting %PHV,
 * parser, deparser, and %MAU sections.
 */
class AsmOutput : public Inspector {
 private:
    const PhvInfo     &phv;
    const ClotInfo    &clot;
    const FieldDefUse &defuse;
    const LogRepackedHeaders *flex;
    const NextTable *nxt_tbl;
    const MauPower::FinalizeMauPredDepsPower* power_and_mpr;
    const TableSummary &tbl_summary;
    const LiveRangeReport *live_range_report;
    const ParserHeaderSequences &prsr_header_seqs;
    const BFN_Options &options;
    /// Tell this pass whether it is called after a succesful compilation
    bool               _successfulCompile = true;
    std::string ghostPhvContainer() const {
        const std::map<cstring, PHV::Field> &fields = phv.get_all_fields();
        std::set<PHV::Container> ghost_containers;
        std::string output;
        for (auto& kv : fields) {
            const PHV::Field &field = kv.second;
            if (field.name.startsWith("ghost::gh_intr_md") && !field.pov)
                ghost_containers.insert(field.for_bit(0).container());
        }
        if (ghost_containers.size()) {
            if (ghost_containers.size() > 1)
                output += "[ ";
            bool first = true;
            for (auto &cnt : ghost_containers) {
                if (!first)
                    output += ", ";
                output += cnt.toString();
                first = false;
            }
            if (ghost_containers.size() > 1)
                output += " ]";
        } else {
            BUG("No allocation for ghost metadata?");
        }
        return output; }

 public:
    AsmOutput(const PhvInfo &phv,
              const ClotInfo &clot,
              const FieldDefUse& defuse,
              const LogRepackedHeaders *flex,
              const NextTable* nxts,
              const MauPower::FinalizeMauPredDepsPower* pmpr,
              const TableSummary& tbl_summary,
              const LiveRangeReport* live_range_report,
              const ParserHeaderSequences &prsr_header_seqs,
              const BFN_Options &opts,
              bool success)
        : phv(phv), clot(clot), defuse(defuse), flex(flex), nxt_tbl(nxts),
          power_and_mpr(pmpr),
          tbl_summary(tbl_summary), live_range_report(live_range_report),
          prsr_header_seqs(prsr_header_seqs),
          options(opts), _successfulCompile(success) {}

    bool preorder(const IR::BFN::Pipe* pipe) override {
        LOG1("ASM generation for successful compile? " << (_successfulCompile ? "true" : "false"));

        if (_successfulCompile) {
            auto outputDir = BFNContext::get().getOutputDirectory("", pipe->id);
            if (!outputDir) return false;
            cstring outputFile = outputDir + "/" + options.programName + ".bfa";
            std::ofstream out(outputFile, std::ios_base::out);

            MauAsmOutput *mauasm = nullptr;
#if HAVE_FLATROCK
            if (Device::currentDevice() == Device::FLATROCK)
                mauasm = new Flatrock::PpuAsmOutput(phv, pipe, nxt_tbl, power_and_mpr, options);
#endif
            if (!mauasm)
                mauasm = new Tofino::MauAsmOutput(phv, pipe, nxt_tbl, power_and_mpr, options);

            pipe->apply(*mauasm);

            out << "version:" << std::endl
                << "  version: " << BFASM::Version::getVersion() << std::endl
                << "  run_id: \"" << RunId::getId() << "\"" << std::endl
                << "  target: " << Device::name() << std::endl;
            if (::errorCount() == 0) {
                out << PhvAsmOutput(phv, defuse, tbl_summary, live_range_report,
                        pipe->ghost_thread.ghost_parser != nullptr);
#if HAVE_FLATROCK
                if (Device::currentDevice() == Device::FLATROCK)
                    out << HeaderAsmOutput(prsr_header_seqs);
#endif
                out << ParserAsmOutput(pipe, phv, clot, INGRESS);
                // Flatrock metadata packer is output as "ingress deparser" section
                out << DeparserAsmOutput(pipe, phv, clot, INGRESS);
                if (pipe->ghost_thread.ghost_parser != nullptr) {
                    out << "parser ghost: " << std::endl;
                    out << "  ghost_md: " << ghostPhvContainer() << std::endl;
                    if (ghost_only_on_other_pipes(pipe->id)) {
                        // Fix for P4C-3925. In future this may be tied to a
                        // command line option which dictates the pipe mask
                        // value
                        out << "  pipe_mask: 0" << std::endl;
                    }
                }
                out << ParserAsmOutput(pipe, phv, clot, EGRESS);
                out << DeparserAsmOutput(pipe, phv, clot, EGRESS)
                    << *mauasm << std::endl
                    << flex->asm_output() << std::endl;
            }
            out << std::flush;
        }
        return false;
    }
};

}  /* namespace BFN */

#endif  /* _EXTENSIONS_BF_P4C_ASM_H_ */
