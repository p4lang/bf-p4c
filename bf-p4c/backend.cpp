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
#include "bf-p4c/mau/dump_json_graph.h"
#include "bf-p4c/mau/empty_controls.h"
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
#include "bf-p4c/mau/mau_alloc.h"
#include "bf-p4c/parde/add_jbay_pov.h"
#include "bf-p4c/parde/adjust_extract.h"
#include "bf-p4c/parde/collect_parser_usedef.h"
#include "bf-p4c/parde/check_parser_multi_write.h"
#include "bf-p4c/parde/egress_packet_length.h"
#include "bf-p4c/parde/lower_parser.h"
#include "bf-p4c/parde/merge_parser_state.h"
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
#include "bf-p4c/phv/utils/live_range_report.h"

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

Backend::Backend(const BFN_Options& options, int pipe_id, ExtractedTogether& extracted_together) :
    clot(uses),
    phv(mutually_exclusive_field_ids),
    uses(phv),
    defuse(phv),
    decaf(phv, uses, defuse, deps),
    bridged_fields(phv),
    table_alloc(phv.field_mutex()),
    table_summary(pipe_id, deps) {
    // extracted_together info comes from midend, not the flexible packing in backend
    auto _unused = new ordered_map<cstring, ordered_set<cstring>>;
    flexiblePacking = new FlexiblePacking(phv, uses, deps, bridged_fields,
                                          *_unused, table_alloc, true);
    flexibleLogging = new LogFlexiblePacking(phv);
    phvLoggingInfo = new CollectPhvLoggingInfo(phv, uses);
    auto *PHV_Analysis = new PHV_AnalysisPass(options, phv, uses, clot,
                                              defuse, deps, decaf, table_alloc /*, &jsonGraph */);
    // Collect next table info if we're using LBs
    nextTblProp = Device::numLongBranchTags() > 0 && !options.disable_long_branch
        ? new NextTable : nullptr;

    auto* allocateClot = Device::numClots() > 0 && options.use_clot ?
        new AllocateClot(clot, phv, uses) : nullptr;

    addPasses({
        new DumpPipe("Initial table graph"),
        LOGGING(4) ? new DumpParser("begin_backend") : nullptr,
        new CreateThreadLocalInstances,
        new CheckForUnimplementedFeatures(),
        new RemoveEmptyControls,
        new MultipleApply,
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
        new FindDependencyGraph(phv, deps, "program_graph", "After Instruction Selection"),
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
        // Repacking of flexible headers (including bridged metadata) in the backend.
        // Needs to be run after InstructionSelection but before deadcode elimination.
        flexiblePacking,
        flexibleLogging,
        new DumpPipe("After packing"),
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
        new CollectBridgedExtractedTogetherFields(phv, extracted_together),
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

        allocateClot == nullptr ? nullptr : new ClotAdjuster(allocateClot, clot, phv),

        options.privatization ? new UndoPrivatization(phv, doNotPrivatize) : nullptr,
                                // Undo results of privatization for the doNotPrivatize fields
        new PHV::ValidateActions(phv, false, true, false),
        new AddAliasAllocation(phv),
        new ReinstateAliasSources(phv),    // revert AliasMembers/Slices to their original sources
        options.privatization ? &defuse : nullptr,
        // Primitives info is generated for model logging and is associated with
        // a 'primitives' node (in context.json) for each action within a table.
        //
        // The 'GeneratePrimitiveInfo' pass does the job of generating a
        // <testname>.prim.json file with all action primitives and is later
        // merged into the context.json by the assembler. This is separated out
        // from being generated directly into the assembly file purely to keep
        // the assembly concise and readable.
        //
        // The primitives node requires instruction details like destination
        // field, source operand info and operation type which requires the
        // compiler to have done instruction selection and phv allocation.
        //
        // This pass should however always be called before any instruction
        // adjustment (splitting) occurs as the logging only needs to output the
        // overall instruction execution as specified in the p4 program. This
        // should also happen before table placement which can cause table
        // splitting across stages.
        //
        // TBD: [JIRA CI-11] Compiler while optimizing may split tables across
        // stages. This could result in multiple scenarios - e.g.
        // - all split stages have same set of actions
        // - one split stage has a different set of actions as compared to the others
        // - one split stage is a no match table and others have a gateway
        // - one split stage has an indirect resource and others dont
        // - one split stage has a partial action completed in the other stages
        //
        // With current schema the action primitives (used for logging) are
        // populated per table and are stage agnostic. They assume the actions
        // are same in each stage.
        //
        // Model logging in such cases will be inconsistent/missing since model
        // logs actions per stage. This will require an update to the schema to
        // represent the actions node within a stage_table.  In addition to
        // actions, the indirect_resource node may also need to be moved
        // similarly.
        //
        // Overall this is a significant change as the updated schema
        // must be supported by the driver/model. The schema should also convey
        // the original p4 action and how it is split across the stages to give
        // a clear idea during logging.
        new GeneratePrimitiveInfo(phv, primNode),
        new TableAllocPass(options, phv, deps, table_summary, &jsonGraph),
        new DumpPipe("After TableAlloc"),
        &table_summary,
        // Rerun defuse analysis here so that table placements are used to correctly calculate live
        // ranges output in the assembly.
        &defuse,
        new LiveRangeReport(phv, table_summary, defuse),
        new IXBarVerify(phv),
        new CollectIXBarInfo(phv),
        new CheckForUnallocatedTemps(phv, uses, clot, PHV_Analysis),
        phvLoggingInfo,
        new InstructionAdjustment(phv),
        nextTblProp,  // Must be run after all modifications to the table graph have finished!
        new DumpPipe("Final table graph"),

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
        new FindDependencyGraph(phv, deps, "placement_graph",
                "After Table Placement", /* run_flow_graph */ true),
        new DumpJsonGraph(deps, &jsonGraph, "After Table Placement", true),
        new CharacterizePower(deps,
#if BAREFOOT_INTERNAL
                              options.no_power_check,
#endif
                              options.display_power_budget,
                              options.disable_power_check,
                              options.debugInfo,
                              Device::numLongBranchTags() == 0 || options.disable_long_branch),
        // Call this at the end of the backend. This changes the logical stages used for PHV
        // allocation to physical stages based on actual table placement.
        Device::currentDevice() != Device::TOFINO
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
