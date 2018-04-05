#include "backend.h"
#include <fstream>
#include <set>
#include "bf-p4c/common/alias.h"
#include "bf-p4c/common/bridged_metadata_replacement.h"
#include "bf-p4c/common/check_header_refs.h"
#include "bf-p4c/common/extract_maupipe.h"
#include "bf-p4c/common/elim_unused.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/common/live_range_overlay.h"
#include "bf-p4c/common/multiple_apply.h"
#include "bf-p4c/common/parser_overlay.h"
#include "bf-p4c/mau/empty_controls.h"
#include "bf-p4c/mau/gateway.h"
#include "bf-p4c/mau/instruction_adjustment.h"
#include "bf-p4c/mau/instruction_selection.h"
#include "bf-p4c/mau/ixbar_realign.h"
#include "bf-p4c/mau/push_pop.h"
#include "bf-p4c/mau/split_alpm.h"
#include "bf-p4c/mau/split_gateways.h"
#include "bf-p4c/mau/stateful_alu.h"
#include "bf-p4c/mau/table_layout.h"
#include "bf-p4c/mau/table_mutex.h"
#include "bf-p4c/mau/table_placement.h"
#include "bf-p4c/mau/table_seqdeps.h"
#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/parde/add_jbay_pov.h"
#include "bf-p4c/parde/bridge_metadata.h"
#include "bf-p4c/parde/lower_parser.h"
#include "bf-p4c/parde/merge_parser_state.h"
#include "bf-p4c/parde/resolve_computed.h"
#include "bf-p4c/parde/stack_push_shims.h"
#include "bf-p4c/phv/check_unallocated.h"
#include "bf-p4c/phv/create_thread_local_instances.h"
#include "bf-p4c/phv/mau_backtracker.h"
#include "bf-p4c/phv/phv_analysis.h"
#include "bf-p4c/phv/privatization.h"
#include "bf-p4c/phv/validate_allocation.h"

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
        if (Log::verbose() || LOGGING(1)) {
            if (heading)
                std::cout << "-------------------------------------------------" << std::endl
                          << heading << std::endl
                          << "-------------------------------------------------" << std::endl;
            if (LOGGING(2))
                dump(pipe);
            else
                std::cout << *pipe << std::endl; }
        return false; }
};

void force_link_dump(const IR::Node *n) { dump(n); }

static void debug_hook(const char *, unsigned, const char *pass, const IR::Node *n) {
    LOG4(pass << ": " << std::endl << *n << std::endl);
}

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
                new SharedIndirectAttachedAnalysis(mutex),
                new DumpPipe("Before TablePlacement"),
                new TablePlacement(&deps, mutex, phv, lc, options.forced_placement),
                new CheckTableNameDuplicate,
                new TableFindSeqDependencies,  // not needed?
                new CheckTableNameDuplicate,
                &defuse,
                (options.no_deadcode_elimination == false) ? new ElimUnused(phv, defuse) : nullptr,
                &mutex
            });

                setName("Table Alloc");
            }
};

Backend::Backend(const BFN_Options& options) :
    clot(uses),
    phv(mutually_exclusive_field_ids),
    uses(phv),
    defuse(phv),
    bridged_fields(phv) {
    addPasses({
        new DumpPipe("Initial table graph"),
        new RemoveEmptyControls,
        new MultipleApply,
        new CheckStatefulAlu,
        new CollectHeaderStackInfo,  // Needed by CollectPhvInfo.
        new CollectPhvInfo(phv),
        &defuse,
#if HAVE_JBAY
        options.target == "jbay" ? new AddJBayMetadataPOV(phv) : nullptr,
#endif  // HAVE_JBAY
        new ResolveComputedParserExpressions,
        new CollectPhvInfo(phv),
        &defuse,
        // only needed to avoid warnings about otherwise unused ingress/egress_port?
        new CollectPhvInfo(phv),
        new CreateThreadLocalInstances,
        new CollectHeaderStackInfo,  // Needs to be rerun after CreateThreadLocalInstances, but
                                     // cannot be run after InstructionSelection.
        new StackPushShims,
        new CollectPhvInfo(phv),  // Needs to be rerun after CreateThreadLocalInstances.
        new HeaderPushPop,
        new CollectPhvInfo(phv),
        new DoInstructionSelection(phv),
        new DumpPipe("After InstructionSelection"),
        new Alias(phv),   // Interpret the pa_alias pragmas
        new CollectPhvInfo(phv),
        &defuse,
        options.privatization ? new Privatization(phv, deps, doNotPrivatize, defuse) : nullptr,
                                  // For read-only fields, generate private TPHV and PHV copies.
        new CollectPhvInfo(phv),
        &defuse,
        new CollectNameAnnotations(phv),
        &bridged_fields,  // Needs to be run after InstructionSelection & CollectNameAnnotations.
        new ReplaceOriginalFieldWithBridged(phv, bridged_fields),  // Run before deadcode elim.
        new CollectPhvInfo(phv),
        &defuse,
        new AlpmSetup,
        new CollectPhvInfo(phv),
        &defuse,
        (options.no_deadcode_elimination == false) ? new ElimUnused(phv, defuse) : nullptr,
        (options.no_deadcode_elimination == false) ? new ElimUnusedHeaderStackInfo : nullptr,
        new CollectPhvInfo(phv),
#if HAVE_JBAY
        options.target == "jbay" ? nullptr : new MergeParserStates,
#endif  // HAVE_JBAY
        &defuse,
            // Following pass must run after CollectNameAnnotations, after any CollectPhvInfo.
        new SetExternalNameForBridgedMetadata(phv, bridged_fields),
        new DumpPipe("Before phv_analysis"),
        new CheckForHeaders(),
#if HAVE_JBAY
        options.target == "jbay" && options.use_clot ? new AllocateClot(clot, phv, uses) : nullptr,
#endif  // HAVE_JBAY
        new PHV_AnalysisPass(options, phv, uses, clot, defuse, deps),  // phv analysis after last
                                                                 // CollectPhvInfo pass

        new PHV::ValidateAllocation(phv, clot, phv.field_mutex, doNotPrivatize),
                                // Validate results of PHV allocation
        options.privatization ? new UndoPrivatization(phv, doNotPrivatize) : nullptr,
                                // Undo results of privatization for the doNotPrivatize fields
        new PHV::ValidateActions(phv, false, true, false),
        new AddAliasAllocation(phv),
        options.privatization ? &defuse : nullptr,
        new TableAllocPass(options, phv, defuse, deps),
        new TableSummary,
        new IXBarVerify(phv),
        new TotalInstructionAdjustment(phv),
        new DumpPipe("Final table graph"),
        new CheckForUnallocatedTemps(phv, uses, clot),

        // Lower the parser IR to a target-specific representation. This *loses
        // information* about field reads and writes in the parser and deparser,
        // so after this point it's not safe to run CollectPhvInfo, FieldDefUse,
        // or any other pass that walks over the IR to find references to
        // fields.
        new LowerParser(phv, clot, defuse),

        new CheckTableNameDuplicate,
        new CheckUnimplementedFeatures(options.allowUnimplemented),
    });
    setName("Tofino backend");

    if (LOGGING(4))
        addDebugHook(debug_hook);
}

}  // namespace BFN
