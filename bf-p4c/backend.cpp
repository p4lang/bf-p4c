/**
 * \defgroup backend Backend
 * \brief Overview of backend passes
 *
 * The back-end performs a series of passes that can
 * possibly introduce some backtracking - returning to
 * a given point in the sequence of passes to re-run
 * it again, possibly with new information. This ussually
 * happens when %PHV or %table allocation fails.
 *
 * The back-end starts with IR that was already transformed from front-end/mid-end IR
 * into back-end IR (via BackendConverter). Also the back-end works
 * on individual pipes in the program, not the entire program at once.
 * This means that the input of the back-end is a back-end IR
 * of a pipe and the output is a assembly file for this pipe.
 *
 * There are currently two top-level flows. Changing between them
 * can be done by setting options.alt_phv_alloc. These two flows are:
 * - Main flow:
 *   1. Run full %PHV allocation
 *   2. Run MAU allocation
 * - Alternative flow:
 *   1. Run trivial %PHV allocation
 *   2. Run MAU allocation
 *   3. Run full %PHV allocation
 * - Note: Both flows include different optimization/transformation
 *         passes in between and also possible backtracking.
 *
 * There are two special types of passes:
 * - Dumping passes - these passes dump some information from the compiler
 *                    usually some part of IR.
 *   - DumpPipe
 *   - DumpParser
 *   - DumpTableFlowGraph
 *   - DumpJsonGraph
 * - Logging passes - these passes create log/report files.
 *   - LogFlexiblePacking
 *   - CollectPhvLoggingInfo
 *   - GeneratePrimitiveInfo
 *   - LiveRangeReport
 *   - BFN::CollectIXBarInfo
 */

#include "backend.h"
#include <fstream>
#include <set>
#include "ir/pass_manager.h"
#include "lib/indent.h"

#include "bf-p4c/arch/collect_hardware_constrained_fields.h"
#include "bf-p4c/common/alias.h"
#include "bf-p4c/common/check_field_corruption.h"
#include "bf-p4c/common/check_for_unimplemented_features.h"
#include "bf-p4c/common/check_header_refs.h"
#include "bf-p4c/common/check_uninitialized_read.h"
#include "bf-p4c/common/elim_unused.h"
#include "bf-p4c/common/extract_maupipe.h"
#include "bf-p4c/common/flexible_packing.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/common/ir_utils.h"
#include "bf-p4c/common/multiple_apply.h"
#include "bf-p4c/common/size_of.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/device.h"
#include "bf-p4c/logging/filelog.h"
#include "bf-p4c/logging/phv_logging.h"
#include "bf-p4c/mau/adjust_byte_count.h"
#include "bf-p4c/mau/check_duplicate.h"
#include "bf-p4c/mau/dump_json_graph.h"
#include "bf-p4c/mau/empty_controls.h"
#include "bf-p4c/mau/finalize_mau_pred_deps_power.h"
#include "bf-p4c/mau/gen_prim_json.h"
#include "bf-p4c/mau/instruction_adjustment.h"
#include "bf-p4c/mau/instruction_selection.h"
#include "bf-p4c/mau/ixbar_info.h"
#include "bf-p4c/mau/ixbar_realign.h"
#include "bf-p4c/mau/jbay_next_table.h"
#include "bf-p4c/mau/mau_alloc.h"
#include "bf-p4c/mau/push_pop.h"
#include "bf-p4c/mau/selector_update.h"
#include "bf-p4c/mau/stateful_alu.h"
#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/mau/validate_actions.h"
#include "bf-p4c/parde/add_metadata_pov.h"
#include "bf-p4c/parde/adjust_extract.h"
#include "bf-p4c/parde/check_parser_multi_write.h"
#include "bf-p4c/parde/clot/allocate_clot.h"
#include "bf-p4c/parde/collect_parser_usedef.h"
#include "bf-p4c/parde/infer_payload_offset.h"
#include "bf-p4c/parde/lower_parser.h"
#include "bf-p4c/parde/merge_parser_state.h"
#include "bf-p4c/parde/reset_invalidated_checksum_headers.h"
#include "bf-p4c/parde/resolve_negative_extract.h"
#include "bf-p4c/parde/rewrite_parser_locals.h"
#include "bf-p4c/parde/stack_push_shims.h"
#include "bf-p4c/phv/analysis/dark.h"
#include "bf-p4c/phv/add_alias_allocation.h"
#include "bf-p4c/phv/allocate_temps_and_finalize_liverange.h"
#include "bf-p4c/phv/auto_init_metadata.h"
#include "bf-p4c/phv/check_unallocated.h"
#include "bf-p4c/phv/create_thread_local_instances.h"
#include "bf-p4c/phv/dump_table_flow_graph.h"
#include "bf-p4c/phv/finalize_stage_allocation.h"
#include "bf-p4c/phv/phv_analysis.h"
#include "bf-p4c/phv/v2/metadata_initialization.h"

namespace BFN {

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

void force_link_dump(const IR::Node *n) { dump(n); }

static void debug_hook(const char *parent, unsigned idx, const char *pass, const IR::Node *n) {
    using namespace IndentCtl;

    if (LOGGING(5)) {
        const int pipeId = n->to<IR::BFN::Pipe>()->id;
        Logging::FileLog fileLog(pipeId, "backend_passes.log");
        LOG5("PASS: " << pass << " [" << parent << " (" << idx << ")]:");
        ::dump(std::clog, n);
    } else {
        LOG4(pass << " [" << parent << " (" << idx << ")]:" << indent << endl <<
             *n << unindent << endl); }
}

Backend::Backend(const BFN_Options& o, int pipe_id) :
    options(o),
    clot(uses),
    uses(phv),
    defuse(phv),
    decaf(phv, uses, defuse, deps),
    table_summary(pipe_id, deps, phv),
    table_alloc(options, phv, deps, table_summary, &jsonGraph, mau_backtracker),
    mau_backtracker(&table_summary), parserHeaderSeqs(phv), longBranchDisabled() {
    BUG_CHECK(pipe_id >= 0, "Invalid pipe id in backend : %d", pipe_id);
    flexibleLogging = new LogFlexiblePacking(phv);
    phvLoggingInfo = new CollectPhvLoggingInfo(phv, uses);
    auto *PHV_Analysis = new PHV_AnalysisPass(options, phv, uses, clot,
                                              defuse, deps, decaf, mau_backtracker,
                                              phvLoggingInfo /*, &jsonGraph */);
    // Collect next table info if we're using LBs
    if (Device::numLongBranchTags() > 0 && !options.disable_long_branch) {
        nextTblProp.setVisitor(new JbayNextTable);
    } else {
        longBranchDisabled = true;
        nextTblProp.setVisitor(new DefaultNext(longBranchDisabled));
    }

    // Create even if Tofino, since this checks power is within limits.
    power_and_mpr = new MauPower::FinalizeMauPredDepsPower(phv, deps, &nextTblProp, options);

    auto* allocateClot = Device::numClots() > 0 && options.use_clot ?
        new AllocateClot(clot, phv, uses) : nullptr;

    liveRangeReport = new LiveRangeReport(phv, table_summary, defuse);
    auto *pragmaAlias = new PragmaAlias(phv);
    addPasses({
        new DumpPipe("Initial table graph"),
        flexibleLogging,
        LOGGING(4) ? new DumpParser("begin_backend") : nullptr,
        new AdjustByteCountSetup,
#if HAVE_FLATROCK
        // FIXME -- Flatrock *could* have separate allocations for ingress and egress, but
        // the same containers can be used across both too.  Since there's no ingress deparser
        // or egress parser, DefUse needs a single name for fields across both ingress and egress
        Device::currentDevice() == Device::FLATROCK ? nullptr :
#endif
        new CreateThreadLocalInstances,
        new CollectHardwareConstrainedFields,
        new CheckForUnimplementedFeatures(),
        new RemoveEmptyControls,
        new CatchBacktrack<LongBranchAllocFailed>([this] {
            if (!options.table_placement_long_branch_backtrack) {
                options.table_placement_long_branch_backtrack = true;
            } else {
                options.disable_long_branch = true;
                longBranchDisabled = true;
                nextTblProp.setVisitor(new DefaultNext(longBranchDisabled)); }
            mau_backtracker.clear();
            table_summary.resetPlacement();
        }),
        new MultipleApply(options),
        new AddSelectorSalu,
        new FixupStatefulAlu,
        // CanonGatewayExpr checks gateway rows in table and tries to optimize
        // on gateway expressions. Since it can ellminate/modify condition
        // tables, this pass must run before PHV Analysis to ensure we do not
        // generate invalid metadata dependencies. Placing it early in backend,
        // as it will also error out on invalid gateway expressions and we fail
        // early in those cases.
        new CanonGatewayExpr,  // Must be before PHV_Analysis
        new CollectHeaderStackInfo,  // Needed by CollectPhvInfo.
        new CollectPhvInfo(phv),
        &defuse,
        Device::hasMetadataPOV() ? new AddMetadataPOV(phv) : nullptr,
        Device::currentDevice() == Device::TOFINO ?
            new ResetInvalidatedChecksumHeaders(phv) : nullptr,
        new CollectPhvInfo(phv),
        &defuse,
        new CollectHeaderStackInfo,  // Needs to be rerun after CreateThreadLocalInstances, but
                                     // cannot be run after InstructionSelection.
        new RemovePushInitialization,
        new StackPushShims,
        new CollectPhvInfo(phv),    // Needs to be rerun after CreateThreadLocalInstances.
        new HeaderPushPop,
        new CollectPhvInfo(phv),
        new InstructionSelection(options, phv),
        new DumpPipe("After InstructionSelection"),
        new FindDependencyGraph(phv, deps, &options, "program_graph",
                                "After Instruction Selection"),
        options.decaf ? &decaf : nullptr,
        new CollectPhvInfo(phv),
        // Aliasing replaces all uses of the alias source field with the alias destination field.
        // Therefore, run it first in the backend to ensure that all other passes use a union of the
        // constraints of the alias source and alias destination fields.
        pragmaAlias,
        new AutoAlias(phv, *pragmaAlias),
        new Alias(phv, *pragmaAlias),
        new CollectPhvInfo(phv),
        new DumpPipe("After Alias"),
        // This is the backtracking point from table placement to PHV allocation. Based on a
        // container conflict-free PHV allocation, we generate a number of no-pack conflicts between
        // fields (these are fields written in different nonmutually exclusive actions in the same
        // stage). As some of these no-pack conflicts may be related to bridged metadata fields, we
        // need to pull out the backtracking point from close to PHV allocation to before bridged
        // metadata packing.
        &mau_backtracker,
        new ResolveSizeOfOperator(),
        new DumpPipe("After ResolveSizeOfOperator"),
        // Run after bridged metadata packing as bridged packing updates the parser state.
        new CollectPhvInfo(phv),
        new ParserCopyProp(phv),
        new RewriteParserMatchDefs(phv),
        new ResolveNegativeExtract,
        new CollectPhvInfo(phv),
        (Device::currentDevice() != Device::TOFINO && options.infer_payload_offset) ?
            new InferPayloadOffset(phv, defuse) : nullptr,
        new CollectPhvInfo(phv),
        &defuse,
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv),
        new ValidToStkvalid(phv),   // Alias header stack $valid fields with $stkvalid slices.
                                    // Must happen before ElimUnused.
        new CollectPhvInfo(phv),
        &defuse,
        (options.no_deadcode_elimination == false) ? new ElimUnused(phv, defuse) : nullptr,
        (options.no_deadcode_elimination == false) ? new ElimUnusedHeaderStackInfo : nullptr,
        (options.disable_parser_state_merging == false) ? new MergeParserStates : nullptr,
        options.auto_init_metadata ? nullptr : new DisableAutoInitMetadata(defuse, phv),
        new RemoveMetadataInits(phv, defuse),
        new CollectPhvInfo(phv),
        &defuse,
        options.alt_phv_alloc_meta_init ?
            new PHV::v2::MetadataInitialization(mau_backtracker, phv, defuse) : nullptr,
        new CheckParserMultiWrite(phv),
        new CollectPhvInfo(phv),
        new CheckForHeaders(),
        allocateClot,
        // Can't (re)run CollectPhvInfo after this point as it will corrupt clot allocation
        &defuse,
        (options.no_deadcode_elimination == false) ? new ElimUnused(phv, defuse) : nullptr,

#ifdef HAVE_FLATROCK
        // ParserHeaderSequences must be run before the IR is lowered
        Device::currentDevice() == Device::FLATROCK ? &parserHeaderSeqs : nullptr,
#endif  /* HAVE_FLATROCK */

        // Two different allocation flow:
        // (1) Normal allocation:
        //                                if failed
        //     PHV alloc => table alloc ============> PHV alloc => ....
        // (2) Table placement first allocation:
        //                                        with table info
        //     Trivial PHV alloc => table alloc ==================> PHV alloc ===> redo table.
        new DumpPipe("Before phv_analysis"),
        new DumpTableFlowGraph(phv),
        options.alt_phv_alloc ? new PassManager({
            // run trivial alloc for the first time
            new PassIf(
                [this]() {
                    auto actualState = table_summary.getActualState();
                    return actualState == TableSummary::ALT_INITIAL;
                },
                {
                    [=]() {
                        PHV_Analysis->set_trivial_alloc(true);
                        PHV_Analysis->set_no_code_change(true);
                        PHV_Analysis->set_physical_liverange_overlay(false);
                    },
                }),
            // run actual PHV allocation
            new PassIf(
                [this]() {
                    auto actualState = table_summary.getActualState();
                    return actualState == TableSummary::ALT_FINALIZE_TABLE_SAME_ORDER;
                },
                {
                    [=]() {
                        PHV_Analysis->set_trivial_alloc(false);
                        PHV_Analysis->set_no_code_change(true);
                        PHV_Analysis->set_physical_liverange_overlay(true);
                    },
                }),
            // ^^ two PassIf are mutex.
        }) : new PassManager({
            // Do PHV allocation.  Cannot run CollectPhvInfo afterwards, as that
            // will clear the allocation.
            [=](){
                PHV_Analysis->set_trivial_alloc(false);
                PHV_Analysis->set_no_code_change(false);
                PHV_Analysis->set_physical_liverange_overlay(false);
            },
        }),
        PHV_Analysis,

        // Not Putting CheckUninitializedRead at the end of backend is because there is a pass named
        // ReinstateAliasSources will break the program's semantic correctness. Namely, some uses
        // will lose track of their defs, because variable names have been changed by some passes,
        // e.g., ReinstateAliasSources. So CheckUninitializedRead should be put at a place that is
        // most correct semantically. In addition, this pass has to be placed after PHV_Analysis,
        // since pragmas information in PHV_Analysis is needed.
        new CheckUninitializedRead(defuse, phv, PHV_Analysis->get_pragmas()),

        allocateClot == nullptr ? nullptr : new ClotAdjuster(clot, phv),
        new ValidateActions(phv, false, true, false),
        new PHV::AddAliasAllocation(phv),
        new ReinstateAliasSources(phv),    // revert AliasMembers/Slices to their original sources
        // This pass must be called before instruction adjustment since the primitive info
        // is per P4 actions. This should also happen before table placement which may cause
        // tables to be split across stages.
        new GeneratePrimitiveInfo(phv, primNode),
        &table_alloc,
        new DumpPipe("After TableAlloc"),
        &table_summary,
        // Rerun defuse analysis here so that table placements are used to correctly calculate live
        // ranges output in the assembly.
        &defuse,
        options.alt_phv_alloc
            ? new PHV::AllocateTempsAndFinalizeLiverange(phv, clot, defuse) : nullptr,
        liveRangeReport,
        new IXBarVerify(phv),
        new CollectIXBarInfo(phv),
        // DO NOT run CheckForUnallocatedTemps in table-first pass because temp vars has been
        // allocated in above AllocateTempsAndFinalizeLiverange.
        !options.alt_phv_alloc
            ? new CheckForUnallocatedTemps(phv, uses, clot, PHV_Analysis) : nullptr,
        new InstructionAdjustment(phv),
        &nextTblProp,  // Must be run after all modifications to the table graph have finished!
        new DumpPipe("Final table graph"),
        new CheckFieldCorruption(defuse, phv, PHV_Analysis->get_pragmas()),
        new AdjustExtract(phv),
        // Rewrite parser and deparser IR to reflect the PHV allocation such that field operations
        // are converted into container operations.
        new LowerParser(phv, clot, defuse, parserHeaderSeqs),
        new CheckTableNameDuplicate,
        new CheckUnimplementedFeatures(options.allowUnimplemented),
        // must be called right before characterize power
        new FindDependencyGraph(phv, deps, &options, "placement_graph",
                "After Table Placement"),
        new DumpJsonGraph(deps, &jsonGraph, "After Table Placement", true),

        // Call this at the end of the backend. This changes the logical stages used for PHV
        // allocation to physical stages based on actual table placement.
        // DO NOT NEED to do it in alternative phv allocation because AllocSlices are already
        // physical stage based.
        Device::currentDevice() != Device::TOFINO && !options.alt_phv_alloc
            ? new FinalizeStageAllocation(phv, defuse, deps) : nullptr,

        // Must be called as last pass.  If the power budget is exceeded,
        // we cannot produce a binary file.
        power_and_mpr,
    });
    setName("Barefoot backend");

    if (options.excludeBackendPasses)
        removePasses(options.passesToExcludeBackend);

#if 0
    // check for passes that incorrectly duplicate shared attached tables
    // FIXME -- table placement currently breaks this because it does not rename attached
    // tables when it splits them across stages.
    auto *check = new CheckDuplicateAttached;
    addDebugHook([check](const char *, unsigned, const char *pass, const IR::Node *root) {
        check->pass = pass;
        root->apply(*check); }, true);
#endif

    if (LOGGING(4))
        addDebugHook(debug_hook, true);
}

}  // namespace BFN
