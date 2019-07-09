#include "backend.h"
#include <fstream>
#include <set>
#include "lib/indent.h"

#include "bf-p4c/common/alias.h"
#include "bf-p4c/common/bridged_metadata_replacement.h"
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
#include "bf-p4c/mau/characterize_power.h"
#include "bf-p4c/mau/check_duplicate.h"
#include "bf-p4c/mau/empty_controls.h"
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
#include "bf-p4c/mau/mau_alloc.h"
#include "bf-p4c/parde/add_jbay_pov.h"
#include "bf-p4c/parde/adjust_extract.h"
#include "bf-p4c/parde/collect_parser_usedef.h"
#include "bf-p4c/parde/egress_packet_length.h"
#include "bf-p4c/parde/lower_parser.h"
#include "bf-p4c/parde/merge_parser_state.h"
#include "bf-p4c/parde/reset_invalidated_checksum_headers.h"
#include "bf-p4c/parde/resolve_parser_stack_index.h"
#include "bf-p4c/parde/infer_payload_offset.h"
#include "bf-p4c/parde/stack_push_shims.h"
#include "bf-p4c/phv/check_unallocated.h"
#include "bf-p4c/phv/create_thread_local_instances.h"
#include "bf-p4c/phv/phv_analysis.h"
#include "bf-p4c/phv/privatization.h"
#include "bf-p4c/phv/finalize_stage_allocation.h"
#include "bf-p4c/phv/validate_allocation.h"
#include "bf-p4c/phv/analysis/dark.h"
#include "bf-p4c/phv/utils/live_range_report.h"

// Set the default base directory for logging files
// This will be overwritten by FileLog::setOutputDir in main, however, the
// static member needs to be initialized here because it needs to be define in the backend library
// so that gtest resolves all symbols.
cstring Logging::FileLog::outputDir = "./";

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
    phv(mutually_exclusive_field_ids),
    uses(phv),
    defuse(phv),
    decaf(phv, uses, defuse, deps),
    bridged_fields(phv),
    table_alloc(phv.field_mutex(), options.disable_init_metadata),
    table_summary(pipe_id, deps) {
    phvLoggingInfo = new CollectPhvLoggingInfo(phv, uses);
    // Collect next table info if we're using LBs
    nextTblProp = Device::numLongBranchTags() > 0 && !options.disable_long_branch
        ? new NextTableProp : nullptr;
    addPasses({
        new DumpPipe("Initial table graph"),
        LOGGING(4) ? new DumpParser("begin_backend") : nullptr,
        new CreateThreadLocalInstances,
        new CheckForUnimplementedFeatures(),
        new RemoveEmptyControls,
        new MultipleApply,
        new AddSelectorSalu,
        new FixupStatefulAlu,
        new CollectHeaderStackInfo,  // Needed by CollectPhvInfo.
        new CollectPhvInfo(phv),
        &defuse,
        Device::currentDevice() == Device::JBAY ? new AddJBayMetadataPOV(phv) : nullptr,
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
        (options.arch == "v1model" && options.adjust_egress_packet_length) ?
            new AdjustEgressPacketLength(phv, defuse) : nullptr,
        new CollectPhvInfo(phv),
        new InstructionSelection(options, phv),
        new DumpPipe("After InstructionSelection"),
        new FindDependencyGraph(phv, deps, "program_graph", "After Instruction Selection"),
        options.decaf ? &decaf : nullptr,
        options.privatization ? new Privatization(phv, deps, doNotPrivatize, defuse) : nullptr,
                                  // For read-only fields, generate private TPHV and PHV copies.

        // This is the backtracking point from table placement to PHV allocation. Based on a
        // container conflict-free PHV allocation, we generate a number of no-pack conflicts between
        // fields (these are fields written in different nonmutually exclusive actions in the same
        // stage). As some of these no-pack conflicts may be related to bridged metadata fields, we
        // need to pull out the backtracking point from close to PHV allocation to before bridged
        // metadata packing.
        &table_alloc,
        new CollectPhvInfo(phv),
        // Aliasing replaces all uses of the alias source field with the alias destination field.
        // Therefore, run it first in the backend to ensure that all other passes use a union of the
        // constraints of the alias source and alias destination fields.
        new Alias(phv, options),
        new CollectPhvInfo(phv),
        // Repacking of flexible headers (including bridged metadata) in the backend.
        // Needs to be run after InstructionSelection but before deadcode elimination.
        new FlexiblePacking(phv, uses, deps, bridged_fields, extracted_together, table_alloc),
        new ResolveSizeOfOperator(),
        new DumpPipe("After ResolveSizeOfOperator"),
        // Run after bridged metadata packing as bridged packing updates the parser state.
        new CollectPhvInfo(phv),
        new ParserCopyProp(phv),
        new CollectPhvInfo(phv),
        (Device::currentDevice() == Device::JBAY && options.infer_payload_offset) ?
            new InferPayloadOffset(phv, defuse) : nullptr,
        new CollectPhvInfo(phv),
        &defuse,
        new AlpmSetup,
        new CollectPhvInfo(phv),
        new ValidToStkvalid(phv),   // Alias header stack $valid fields with $stkvalid slices.
                                    // Must happen before ElimUnused.
        new CollectPhvInfo(phv),
        &defuse,
        (options.no_deadcode_elimination == false) ? new ElimUnused(phv, defuse) : nullptr,
        (options.no_deadcode_elimination == false) ? new ElimUnusedHeaderStackInfo : nullptr,
        (options.disable_parser_state_merging == false) ? new MergeParserStates : nullptr,
        new CollectPhvInfo(phv),
        new CollectBridgedExtractedTogetherFields(phv, extracted_together),
        // DO NOT RUN CollectPhvInfo afterwards, as this will destroy the
        // external names for bridged metadata PHV::Field objects.
        new SetExternalNameForBridgedMetadata(phv, bridged_fields),
        new GatherExternalNames(phv),

        new CheckForHeaders(),
        Device::currentDevice() == Device::JBAY && options.use_clot ?
            new AllocateClot(clot, phv, uses) : nullptr,
        &defuse,
        (options.no_deadcode_elimination == false) ? new ElimUnused(phv, defuse) : nullptr,

        // Do PHV allocation.  Cannot run CollectPhvInfo afterwards, as that
        // will clear the allocation.
        new DumpPipe("Before phv_analysis"),
        new PHV_AnalysisPass(options, phv, uses, clot, defuse, deps, decaf, table_alloc),
        // Validate results of PHV allocation.
        new PHV::ValidateAllocation(phv, clot, doNotPrivatize),

        new ClotAdjuster(clot, phv),

        options.privatization ? new UndoPrivatization(phv, doNotPrivatize) : nullptr,
                                // Undo results of privatization for the doNotPrivatize fields
        new PHV::ValidateActions(phv, false, true, false),
        new AddAliasAllocation(phv),
        new ReinstateAliasSources(phv),    // revert AliasMembers/Slices to their original sources
        options.privatization ? &defuse : nullptr,
        new TableAllocPass(options, phv, deps),
        &table_summary,
        // Rerun defuse analysis here so that table placements are used to correctly calculate live
        // ranges output in the assembly.
        &defuse,
        new LiveRangeReport(phv, table_summary, defuse),
        new IXBarVerify(phv),
        new CollectIXBarInfo(phv),
        phvLoggingInfo,
        new InstructionAdjustment(phv, primNode),
        nextTblProp,  // Must be run after all modifications to the table graph have finished!
        new DumpPipe("Final table graph"),
        new CheckForUnallocatedTemps(phv, uses, clot),

        new AdjustExtract(phv),
        // Lower the parser IR to a target-specific representation. This *loses
        // information* about field reads and writes in the parser and deparser,
        // so after this point it's not safe to run CollectPhvInfo, FieldDefUse,
        // or any other pass that walks over the IR to find references to
        // fields.
        new LowerParser(phv, clot, defuse),

        new CheckTableNameDuplicate,
        new CheckUnimplementedFeatures(options.allowUnimplemented),
        // must be called right before characterize power
        new FindDependencyGraph(phv, deps, "", "After Table Placement"),

        new CharacterizePower(deps,
#if BAREFOOT_INTERNAL
                              options.no_power_check,
#endif
                              options.display_power_budget,
                              options.disable_power_check),
        // Call this at the end of the backend. This changes the logical stages used for PHV
        // allocation to physical stages based on actual table placement.
        Device::currentDevice() == Device::JBAY
            ? new FinalizeStageAllocation(phv, defuse, deps, table_summary) : nullptr
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
