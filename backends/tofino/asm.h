#ifndef _EXTENSIONS_BF_P4C_ASM_H_
#define _EXTENSIONS_BF_P4C_ASM_H_

#include <string>

#include "backends/tofino/bf-p4c-options.h"
#include "backends/tofino/common/bridged_packing.h"
#include "backends/tofino/common/utils.h"
#include "backends/tofino/mau/asm_output.h"
#if HAVE_FLATROCK
#include "backends/tofino/mau/flatrock/asm_output.h"
#endif  /* HAVE_FLATROCK */
#include "backends/tofino/mau/jbay_next_table.h"
#include "backends/tofino/mau/tofino/asm_output.h"
#include "backends/tofino/parde/asm_output.h"
#include "backends/tofino/parde/clot/clot_info.h"
#include "backends/tofino/parde/parser_header_sequences.h"
#include "backends/tofino/phv/asm_output.h"
#include "backends/tofino/phv/phv_fields.h"
#include "backends/tofino/phv/utils/live_range_report.h"

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
    int pipe_id;
    const PhvInfo &phv;
    const ClotInfo &clot;
    const FieldDefUse &defuse;
    const LogRepackedHeaders *flex;
    const NextTable *nxt_tbl;
    const MauPower::FinalizeMauPredDepsPower *power_and_mpr;
    const TableSummary &tbl_summary;
    const LiveRangeReport *live_range_report;
    const ParserHeaderSequences &prsr_header_seqs;
    const BFN_Options &options;
    /// Tell this pass whether it is called after a succesful compilation
    bool _successfulCompile = true;
    std::string ghostPhvContainer() const;

 public:
    AsmOutput(int pipe_id, const PhvInfo &phv, const ClotInfo &clot, const FieldDefUse &defuse,
              const LogRepackedHeaders *flex, const NextTable *nxts,
              const MauPower::FinalizeMauPredDepsPower *pmpr, const TableSummary &tbl_summary,
              const LiveRangeReport *live_range_report,
              const ParserHeaderSequences &prsr_header_seqs, const BFN_Options &opts, bool success);

    bool preorder(const IR::BFN::Pipe *pipe) override;
};

} /* namespace BFN */

#endif /* _EXTENSIONS_BF_P4C_ASM_H_ */
