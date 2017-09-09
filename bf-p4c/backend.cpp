/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "backend.h"
#include <fstream>
#include "tofino/common/copy_header_eliminator.h"
#include "tofino/common/extract_maupipe.h"
#include "tofino/common/elim_unused.h"
#include "tofino/common/field_defuse.h"
#include "tofino/common/header_stack.h"
#include "tofino/common/live_at_entry.h"
#include "tofino/common/live_range_overlay.h"
#include "tofino/common/parser_overlay.h"
#include "tofino/common/metadata_constant_propagation.h"
#include "tofino/mau/asm_output.h"
#include "tofino/mau/empty_controls.h"
#include "tofino/mau/gateway.h"
#include "tofino/mau/instruction_adjustment.h"
#include "tofino/mau/instruction_selection.h"
#include "tofino/mau/ixbar_realign.h"
#include "tofino/mau/push_pop.h"
#include "tofino/mau/split_gateways.h"
#include "tofino/mau/stateful_alu.h"
#include "tofino/mau/table_dependency_graph.h"
#include "tofino/mau/table_layout.h"
#include "tofino/mau/table_mutex.h"
#include "tofino/mau/table_placement.h"
#include "tofino/mau/table_seqdeps.h"
#include "tofino/mau/table_summary.h"
#include "tofino/parde/asm_output.h"
#include "tofino/parde/bridge_metadata.h"
#include "tofino/parde/digest.h"
#include "tofino/parde/resolve_computed.h"
#include "tofino/parde/split_big_states.h"
#include "tofino/parde/stack_push_shims.h"
#include "tofino/phv/asm_output.h"
#include "tofino/phv/trivial_alloc.h"
#include "tofino/phv/split_phv_use.h"
#include "tofino/phv/create_thread_local_instances.h"
#include "tofino/phv/cluster_phv_interference.h"
#include "tofino/phv/cluster_phv_bind.h"
#include "tofino/phv/cluster_phv_operations.h"
#include "tofino/phv/cluster_phv_slicing.h"
#include "tofino/phv/cluster_phv_overlay.h"
#include "tofino/phv/phv_analysis_validate.h"
#include "tofino/phv/phv_assignment_validate.h"
#include "tofino/phv/validate_allocation.h"

namespace Tofino {

class CheckTableNameDuplicate : public MauInspector {
    set<cstring>        names;
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
  CheckUnimplementedFeatures(bool print = false) : _printAndNotExit(print) {}

  bool preorder (const IR::EntriesList *entries) {
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

    bool preorder(const IR::Tofino::Pipe* pipe) override {
       MauAsmOutput mauasm(phv);
       pipe->apply(mauasm);

       if (ErrorReporter::instance.getErrorCount() > 0)
           return false;

       *out << "version: 1.0.0" << std::endl
            << PhvAsmOutput(phv)
            << ParserAsmOutput(pipe, phv, INGRESS)
            << DeparserAsmOutput(pipe, phv, INGRESS)
            << ParserAsmOutput(pipe, phv, EGRESS)
            << DeparserAsmOutput(pipe, phv, EGRESS)
            << mauasm
            << std::flush;

       return false; }
};

class PHV_AnalysisPass : public PassManager {
 private:
    SymBitMatrix mutually_exclusive_field_ids;
    Cluster cluster;                            // cluster analysis
    Cluster_PHV_Requirements cluster_phv_req;   // cluster PHV requirements
    PHV_Interference cluster_phv_interference;  // intra-cluster PHV Interference Graph
    PHV_MAU_Group_Assignments cluster_phv_mau;  // cluster PHV Container placements

 public:
    PHV_MAU_Group_Assignments& group_assignments() { return cluster_phv_mau; }

 public:
    PHV_AnalysisPass(const Tofino_Options &options, PhvInfo &phv, PhvUse &uses,
                     FieldDefUse &defuse, DependencyGraph &deps) :
        cluster(phv, uses),
        cluster_phv_req(cluster),
        cluster_phv_interference(cluster_phv_req, mutually_exclusive_field_ids),
        cluster_phv_mau(cluster_phv_req) {
            addPasses({
                &uses,                 // use of field in mau, parde
                &cluster,              // cluster analysis
                new ParserOverlay(phv, mutually_exclusive_field_ids),
                                       // produce pairs of mutually exclusive header
                                       // fields, eg. (arpSrc, ipSrc)
                new FindDependencyGraph(phv, deps),
                                       // refresh dependency graph for live range
                                       // analysis
                &defuse,               // refresh defuse
                new LiveRangeOverlay(phv, deps, defuse, mutually_exclusive_field_ids),
                                       // produce pairs of fields that are never live
                                       // in the same stage
                new PHV_Field_Operations(phv),  // PHV field operations analysis
                &cluster_phv_req,      // cluster PHV requirements analysis
                options.phv_interference?
                    &cluster_phv_interference: nullptr,
                                       // cluster PHV interference graph analysis
                &cluster_phv_mau,      // cluster PHV container placements
                                       // first cut PHV MAU Group assignments
                                       // produces cohabit fields for Table Placement
                options.phv_slicing?
                    new Cluster_Slicing(cluster_phv_mau): nullptr,
                                       // slice clusters into smaller clusters
                                       // attempt packing with reduced width requirements
                                       // slicing improves overlay possibilities due to less width
                                       // although number & mutual exclusion of fields don't change
                options.phv_slicing?
                    new Cluster_Slicing(cluster_phv_mau): nullptr,
                                       // repeat once more: unallocated clusters sliced further
                                       // further improves chances of packing and/or overlay
                options.phv_overlay?
                    new Cluster_PHV_Overlay(cluster_phv_mau, cluster_phv_interference): nullptr,
                                       // overlay clusters to MAU groups
                                       // need cluster_phv_interference
                                       // func mutually_exclusive(f1, f2)
                                       // overlay unallocated clusters to clusters & MAU groups
                new PHV_Analysis_Validate(phv, cluster_phv_mau)  // phv analysis results validation
            });

            setName("PHV Analysis");
    }
};

class PHV_AllocPass : public PassManager {
 private:
    PhvInfo                   &phv;

 public:
    PHV_AllocPass(const Tofino_Options &options, PhvInfo &phv, PhvUse &uses,
                  PHV_MAU_Group_Assignments &cluster_phv_mau) : phv(phv) {
            if (options.trivial_phvalloc) {
                addPasses({
                    new PHV::TrivialAlloc(phv)});
            } else {
                addPasses({
                    //
                    // &cluster_phv_mau,       // cluster PHV container placements
                                               // second cut PHV MAU Group assignments
                                               // honor single write conflicts from Table Placement
                    &uses,                     // use of field in mau, parde
                    new PHV_Bind(phv, uses, cluster_phv_mau),
                                               // fields bound to PHV containers
                                               // later passes assume that phv alloc info
                                               // is sorted in field bit order, msb first
                                               // sorting done by phv_bind
                    new PHV_Assignment_Validate(phv)});  // phv assignment results validation
            }
            passes.push_back(new PHV::ValidateAllocation(phv, options.ignorePHVOverflow));
            setName("PHV Alloc");
        }

    void end_apply() override {
        if (Log::verbose())
            std::cout << phv; }
};

class TableAllocPass : public PassManager {
 private:
    TablesMutuallyExclusive mutex;
    LayoutChoices           lc;

 public:
    TableAllocPass(PhvInfo& phv, FieldDefUse &defuse, DependencyGraph &deps) {
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
                new SharedActionProfileAnalysis(mutex),
                new DumpPipe("Before TablePlacement"),
                new TablePlacement(&deps, mutex, phv, lc),
                new CheckTableNameDuplicate,
                new TableFindSeqDependencies,  // not needed?
                new CheckTableNameDuplicate,
                &defuse,
                new ElimUnused(phv, defuse),
                &mutex,
                new TableSummary} );

                setName("Table Alloc");
            }
};

void backend(const IR::Tofino::Pipe* maupipe, const Tofino_Options& options) {
    PhvInfo phv;
    PhvUse uses(phv);
    DependencyGraph deps;
    FieldDefUse defuse(phv);
    PHV_AnalysisPass phv_analysis(options, phv, uses, defuse, deps);
    PHV_AllocPass phv_alloc(options, phv, uses, phv_analysis.group_assignments());

    PassManager backend = {
        new DumpPipe("Initial table graph"),
        new RemoveEmptyControls,
        new CheckStatefulAlu,
        new CollectHeaderStackInfo,  // Needed by CollectPhvInfo.
        new CollectPhvInfo(phv),
        &defuse,
        new AddBridgedMetadata(phv, defuse),
        new ResolveComputedParserExpressions,
        new CollectPhvInfo(phv),
        &defuse,
        new MetadataConstantPropagation(phv, defuse),
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
        new ElimUnused(phv, defuse),  // ElimUnused may have eliminated all references to a field
        new DumpPipe("Before phv_analysis"),
        &phv_analysis,                 // phv analysis after last CollectPhvInfo pass
        new TableAllocPass(phv, defuse, deps),
        new DumpPipe("Before phv_alloc/bind"),
        &phv_alloc,                 // phv assignment / binding
        new IXBarRealign(phv),
        new TotalInstructionAdjustment(phv),
        new SplitPhvUse(phv),
        new SplitBigStates(phv),  // depends on SplitPhvUse
        new DumpPipe("Final table graph"),
        new CheckTableNameDuplicate,
        new CheckUnimplementedFeatures(options.allowUnimplemented),
        new AsmOutput(phv, options.outputFile)
    };
    backend.setName("Tofino backend");
    if (LOGGING(4))
        backend.addDebugHook(debug_hook);
    maupipe = maupipe->apply(backend);
}

}  // namespace Tofino
