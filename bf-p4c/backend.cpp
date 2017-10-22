#include "backend.h"
#include <fstream>
#include <set>
#include "bf-p4c/common/check_header_refs.h"
#include "bf-p4c/common/copy_header_eliminator.h"
#include "bf-p4c/common/extract_maupipe.h"
#include "bf-p4c/common/elim_unused.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/common/live_at_entry.h"
#include "bf-p4c/common/live_range_overlay.h"
#include "bf-p4c/common/parser_overlay.h"
#include "bf-p4c/mau/asm_output.h"
#include "bf-p4c/mau/empty_controls.h"
#include "bf-p4c/mau/gateway.h"
#include "bf-p4c/mau/instruction_adjustment.h"
#include "bf-p4c/mau/instruction_selection.h"
#include "bf-p4c/mau/ixbar_realign.h"
#include "bf-p4c/mau/push_pop.h"
#include "bf-p4c/mau/split_gateways.h"
#include "bf-p4c/mau/stateful_alu.h"
#include "bf-p4c/mau/table_layout.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/mau/table_placement.h"
#include "bf-p4c/mau/table_seqdeps.h"
#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/parde/add_jbay_pov.h"
#include "bf-p4c/parde/asm_output.h"
#include "bf-p4c/parde/bridge_metadata.h"
#include "bf-p4c/parde/digest.h"
#include "bf-p4c/parde/lower_parser.h"
#include "bf-p4c/parde/resolve_computed.h"
#include "bf-p4c/parde/stack_push_shims.h"
#include "bf-p4c/phv/asm_output.h"
#include "bf-p4c/phv/check_unallocated.h"
#include "bf-p4c/phv/create_thread_local_instances.h"
#include "bf-p4c/phv/phv_analysis.h"

namespace BFN {

class CheckTableNameDuplicate : public MauInspector {
    std::set<cstring>        names;
    profile_t init_apply(const IR::Node *root) override {
        names.clear();
        return MauInspector::init_apply(root); }
    bool preorder(const IR::MAU::Table *t) override {
        if (names.count(t->name))
            BUG("Multiple tables named '%s'", t->name);
        names.insert(t->name);
        return true; }
};

/**
 * A class to collect all currently unimplemented features
 * and control whether we print an error (for debugging) or exit
 */
class CheckUnimplementedFeatures : public Inspector {
  bool _printAndNotExit;
 public:
  explicit CheckUnimplementedFeatures(bool print = false) : _printAndNotExit(print) {}

  bool preorder(const IR::EntriesList *entries) {
    auto source = entries->getSourceInfo().toPosition();
    if (_printAndNotExit)
      ::warning("Table entries (%s) are not yet implemented in this backend",
                source.toString());
    else
      throw Util::CompilerUnimplemented(source.sourceLine, source.fileName,
                "Table entries are not yet implemented in this backend");
    return false;
  }
};

struct DumpPipe : public Inspector {
    const char *heading;
    DumpPipe() : heading(nullptr) {}
    explicit DumpPipe(const char *h) : heading(h) {}
    bool preorder(const IR::Node *pipe) override {
        if (Log::verbose()) {
            if (heading)
                std::cout << "-------------------------------------------------" << std::endl
                          << heading << std::endl
                          << "-------------------------------------------------" << std::endl;
            if (Log::verbosity() > 1)
                dump(pipe);
            else
                std::cout << *pipe << std::endl; }
        return false; }
};

void force_link_dump(const IR::Node *n) { dump(n); }

static void debug_hook(const char *, unsigned, const char *pass, const IR::Node *n) {
    LOG4(pass << ": " << std::endl << *n << std::endl);
}

class AsmOutput : public Inspector {
 private:
    std::ostream* out = nullptr;
    const PhvInfo &phv;

 public:
    AsmOutput(const PhvInfo &phv, cstring outputFile) : phv(phv) {
        out = &std::cout;
        if (outputFile)
            out = new std::ofstream(outputFile); }

    bool preorder(const IR::BFN::Pipe* pipe) override {
       MauAsmOutput mauasm(phv);
       pipe->apply(mauasm);

       if (ErrorReporter::instance.getErrorCount() > 0)
           return false;

       *out << "version: 1.0.0" << std::endl
            << PhvAsmOutput(phv)
            << ParserAsmOutput(pipe, INGRESS)
            << DeparserAsmOutput(pipe, phv, INGRESS)
            << ParserAsmOutput(pipe, EGRESS)
            << DeparserAsmOutput(pipe, phv, EGRESS)
            << mauasm
            << std::flush;

       return false; }
};

class TableAllocPass : public PassManager {
 private:
    TablesMutuallyExclusive mutex;
    LayoutChoices           lc;

 public:
    TableAllocPass(const BFN_Options& options, PhvInfo& phv, FieldDefUse &defuse,
        DependencyGraph &deps) {
            addPasses({
                new GatewayOpt(phv),   // must be before TableLayout?  or just TablePlacement?
                new TableLayout(phv, lc),
                new TableFindSeqDependencies,
                new FindDependencyGraph(phv, deps),
                new SpreadGatewayAcrossSeq,
                new CheckTableNameDuplicate,
                new TableFindSeqDependencies,
                new CheckTableNameDuplicate,
                new FindDependencyGraph(phv, deps),
                &mutex,
                new SharedIndirectActionAnalysis(mutex),
                new DumpPipe("Before TablePlacement"),
                new TablePlacement(&deps, mutex, phv, lc),
                new CheckTableNameDuplicate,
                new TableFindSeqDependencies,  // not needed?
                new CheckTableNameDuplicate,
                &defuse,
                (options.no_deadcode_elimination == false) ? new ElimUnused(phv, defuse) : nullptr,
                &mutex,
                new TableSummary} );

                setName("Table Alloc");
            }
};

Backend::Backend(const BFN_Options& options) :
    uses(phv),
    defuse(phv) {
    addPasses({
        new DumpPipe("Initial table graph"),
        new RemoveEmptyControls,
        new CheckStatefulAlu,
        new CollectHeaderStackInfo,  // Needed by CollectPhvInfo.
        new CollectPhvInfo(phv),
        &defuse,
        new AddBridgedMetadata(phv, defuse),
        options.device == "jbay" ? new AddJBayMetadataPOV(phv) : nullptr,
        new ResolveComputedParserExpressions,
        new CollectPhvInfo(phv),
        &defuse,
        new CollectPhvInfo(phv),
        &defuse,
        new Digests,
        // only needed to avoid warnings about otherwise unused ingress/egress_port?
        new CollectPhvInfo(phv),
        new LiveAtEntry(phv),
        new CreateThreadLocalInstances,
        new CollectHeaderStackInfo,  // Needs to be rerun after CreateThreadLocalInstances.
        new StackPushShims,
        new CollectPhvInfo(phv),  // Needs to be rerun after CreateThreadLocalInstances.
        new HeaderPushPop,
        new CopyHeaderEliminator,   // needs to be after HeaderPushPop and before InstSel
        new CollectPhvInfo(phv),
        new DoInstructionSelection(phv),
        new DumpPipe("After InstructionSelection"),
        new CollectPhvInfo(phv),
        &defuse,
        (options.no_deadcode_elimination == false) ? new ElimUnused(phv, defuse) : nullptr,
        new DumpPipe("Before phv_analysis"),
        new CheckForHeaders(),
        new PHV_AnalysisPass(options, phv, uses, defuse, deps),  // phv analysis after last
                                                                 // CollectPhvInfo pass
        new TableAllocPass(options, phv, defuse, deps),
        new IXBarRealign(phv),
        new TotalInstructionAdjustment(phv),
        new DumpPipe("Final table graph"),
        new CheckForUnallocatedTemps(phv, uses),

        // Lower the parser IR to a target-specific representation. This *loses
        // information* about field reads and writes in the parser and depaser,
        // so after this point it's not safe to run CollectPhvInfo, FieldDefUse,
        // or any other pass that walks over the IR to find references to
        // fields.
        new LowerParser(phv),

        new CheckTableNameDuplicate,
        new CheckUnimplementedFeatures(options.allowUnimplemented),
        new AsmOutput(phv, options.outputFile)
    });
    setName("Tofino backend");

    if (LOGGING(4))
        addDebugHook(debug_hook);
}

}  // namespace BFN
