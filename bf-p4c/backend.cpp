#include "backend.h"
#include <fstream>
#include <set>
#include "lib/indent.h"

#include "bf-p4c/common/alias.h"
#include "bf-p4c/common/check_for_unimplemented_features.h"
#include "bf-p4c/common/check_header_refs.h"
#include "bf-p4c/common/extract_maupipe.h"
#include "bf-p4c/common/elim_unused.h"
#include "bf-p4c/common/flexible_packing.h"
#include "bf-p4c/common/header_stack.h"
#include "bf-p4c/common/multiple_apply.h"
#include "bf-p4c/common/size_of.h"
#include "bf-p4c/common/utils.h"
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
#include "bf-p4c/mau/push_pop.h"
#include "bf-p4c/mau/selector_update.h"
#include "bf-p4c/mau/split_alpm.h"
#include "bf-p4c/mau/stateful_alu.h"
#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/mau/validate_actions.h"
#include "bf-p4c/mau/mau_alloc.h"
#include "bf-p4c/parde/add_jbay_pov.h"
#include "bf-p4c/parde/adjust_extract.h"
#include "bf-p4c/parde/collect_parser_usedef.h"
#include "bf-p4c/parde/check_parser_multi_write.h"
#include "bf-p4c/parde/clot/allocate_clot.h"
#include "bf-p4c/parde/egress_packet_length.h"
#include "bf-p4c/parde/lower_parser.h"
#include "bf-p4c/parde/merge_parser_state.h"
#include "bf-p4c/parde/resolve_negative_extract.h"
#include "bf-p4c/parde/reset_invalidated_checksum_headers.h"
#include "bf-p4c/parde/infer_payload_offset.h"
#include "bf-p4c/parde/stack_push_shims.h"
#include "bf-p4c/phv/auto_init_metadata.h"
#include "bf-p4c/phv/check_unallocated.h"
#include "bf-p4c/phv/create_thread_local_instances.h"
#include "bf-p4c/phv/phv_analysis.h"
#include "bf-p4c/phv/privatization.h"
#include "bf-p4c/phv/finalize_stage_allocation.h"
#include "bf-p4c/phv/validate_allocation.h"
#include "bf-p4c/phv/analysis/dark.h"

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
        LOG5(pass << " [" << parent << " (" << idx << ")]:");
        ::dump(std::clog, n);
        LOG5(std::endl);
    } else {
        LOG4(pass << " [" << parent << " (" << idx << ")]:" << indent << endl <<
             *n << unindent << endl); }
}

Backend::Backend(const BFN_Options& options, int pipe_id) :
    clot(uses),
    uses(phv),
    defuse(phv),
    decaf(phv, uses, defuse, deps),
    table_summary(pipe_id, deps) {
    flexibleLogging = new LogFlexiblePacking(phv);
    phvLoggingInfo = new CollectPhvLoggingInfo(phv, uses);
    auto *PHV_Analysis = new PHV_AnalysisPass(options, phv, uses, clot,
                                              defuse, deps, decaf, table_alloc,
                                              phvLoggingInfo /*, &jsonGraph */);
    // Collect next table info if we're using LBs
    if (Device::numLongBranchTags() > 0 && !options.disable_long_branch)
        nextTblProp = new JbayNextTable;
    else
        nextTblProp = new DefaultNext(true);

    // Create even if Tofino, since this checks power is within limits.
    power_and_mpr = new MauPower::FinalizeMauPredDepsPower(phv, deps, nextTblProp, options);

    auto* allocateClot = Device::numClots() > 0 && options.use_clot ?
        new AllocateClot(clot, phv, uses) : nullptr;

    liveRangeReport = new LiveRangeReport(phv, table_summary, defuse);
    addPasses({
        flexibleLogging,
        new DumpPipe("Initial table graph"),
        LOGGING(4) ? new DumpParser("begin_backend") : nullptr,
        new AdjustByteCountSetup,
        new CreateThreadLocalInstances,
        new CheckForUnimplementedFeatures(),
        new RemoveEmptyControls,
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
        Device::currentDevice() != Device::TOFINO ? new AddJBayMetadataPOV(phv) : nullptr,
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
        (((options.langVersion == BFN_Options::FrontendVersion::P4_14 && options.arch == "tna") ||
          options.arch == "v1model") && options.adjust_egress_packet_length) ?
            new AdjustEgressPacketLength(phv, defuse) : nullptr,
        new CollectPhvInfo(phv),
        new InstructionSelection(options, phv),
        new DumpPipe("After InstructionSelection"),
        new FindDependencyGraph(phv, deps, &options, "program_graph",
                                "After Instruction Selection"),
        options.decaf ? &decaf : nullptr,
        options.privatization ? new Privatization(phv, deps, doNotPrivatize, defuse) : nullptr,
                                  // For read-only fields, generate private TPHV and PHV copies.

        new CollectPhvInfo(phv),
        // Aliasing replaces all uses of the alias source field with the alias destination field.
        // Therefore, run it first in the backend to ensure that all other passes use a union of the
        // constraints of the alias source and alias destination fields.
        new Alias(phv),
        new CollectPhvInfo(phv),
        new DumpPipe("After Alias"),
        // This is the backtracking point from table placement to PHV allocation. Based on a
        // container conflict-free PHV allocation, we generate a number of no-pack conflicts between
        // fields (these are fields written in different nonmutually exclusive actions in the same
        // stage). As some of these no-pack conflicts may be related to bridged metadata fields, we
        // need to pull out the backtracking point from close to PHV allocation to before bridged
        // metadata packing.
        &table_alloc,
        new ResolveSizeOfOperator(),
        new DumpPipe("After ResolveSizeOfOperator"),
        // Run after bridged metadata packing as bridged packing updates the parser state.
        new CollectPhvInfo(phv),
        new ParserCopyProp(phv),
        new ResolveNegativeExtract,
        new CollectPhvInfo(phv),
        (Device::currentDevice() == Device::JBAY && options.infer_payload_offset) ?
            new InferPayloadOffset(phv, defuse) : nullptr,
        new CollectPhvInfo(phv),
        &defuse,
        new AlpmSetup,
        new CollectHeaderStackInfo,
        new CollectPhvInfo(phv),
        new ValidToStkvalid(phv),   // Alias header stack $valid fields with $stkvalid slices.
                                    // Must happen before ElimUnused.
        new CollectPhvInfo(phv),
        &defuse,
        (options.no_deadcode_elimination == false) ? new ElimUnused(phv, defuse) : nullptr,
        (options.no_deadcode_elimination == false) ? new ElimUnusedHeaderStackInfo : nullptr,
        (options.disable_parser_state_merging == false) ? new MergeParserStates : nullptr,
        options.auto_init_metadata ? nullptr : new DisableAutoInitMetadata(defuse),
        new RemoveMetadataInits(phv, defuse),
        new CollectPhvInfo(phv),
        new CheckParserMultiWrite(phv),
        new CollectPhvInfo(phv),
        new CheckForHeaders(),
        allocateClot,
        &defuse,
        (options.no_deadcode_elimination == false) ? new ElimUnused(phv, defuse) : nullptr,

        // Do PHV allocation.  Cannot run CollectPhvInfo afterwards, as that
        // will clear the allocation.
        new DumpPipe("Before phv_analysis"),
        PHV_Analysis,
        // Validate results of PHV allocation.
        new PHV::ValidateAllocation(phv, clot, doNotPrivatize),

        allocateClot == nullptr ? nullptr : new ClotAdjuster(clot, phv),

        options.privatization ? new UndoPrivatization(phv, doNotPrivatize) : nullptr,
                                // Undo results of privatization for the doNotPrivatize fields
        new ValidateActions(phv, false, true, false),
        new AddAliasAllocation(phv),
        new ReinstateAliasSources(phv),    // revert AliasMembers/Slices to their original sources
        options.privatization ? &defuse : nullptr,
        // This pass must be called before instruction adjustment since the primitive info
        // is per P4 actions. This should also happen before table placement which may cause
        // tables to be split across stages.
        new GeneratePrimitiveInfo(phv, primNode),
        new TableAllocPass(options, phv, deps, table_summary, &jsonGraph),
        new DumpPipe("After TableAlloc"),
        &table_summary,
        // Rerun defuse analysis here so that table placements are used to correctly calculate live
        // ranges output in the assembly.
        &defuse,
        liveRangeReport,
        new IXBarVerify(phv),
        new CollectIXBarInfo(phv),
        new CheckForUnallocatedTemps(phv, uses, clot, PHV_Analysis),
        new InstructionAdjustment(phv),
        nextTblProp,  // Must be run after all modifications to the table graph have finished!
        new DumpPipe("Final table graph"),
        new AdjustExtract(phv),
        // Rewrite parser and deparser IR to reflect the PHV allocation such that field operations
        // are converted into container operations.
        new LowerParser(phv, clot, defuse),
        new CheckTableNameDuplicate,
        new CheckUnimplementedFeatures(options.allowUnimplemented),
        // must be called right before characterize power
        new FindDependencyGraph(phv, deps, &options, "placement_graph",
                "After Table Placement"),
        new DumpJsonGraph(deps, &jsonGraph, "After Table Placement", true),

        // Call this at the end of the backend. This changes the logical stages used for PHV
        // allocation to physical stages based on actual table placement.
        Device::currentDevice() != Device::TOFINO
            ? new FinalizeStageAllocation(phv, defuse, deps, table_summary) : nullptr,

        // Must be called as last pass.  If the power budget is exceeded,
        // we cannot produce a binary file.
        power_and_mpr,
    });
    setName("Barefoot backend");

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
