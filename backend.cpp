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

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string>
#include "ir/ir.h"
#include "ir/dbprint.h"
#include "lib/log.h"
#include "frontends/p4-14/typecheck.h"
#include "tofinoOptions.h"
#include "tofino/common/copy_header_eliminator.h"
#include "tofino/common/extract_maupipe.h"
#include "tofino/common/elim_unused.h"
#include "tofino/common/field_defuse.h"
#include "tofino/common/header_stack.h"
#include "tofino/common/live_at_entry.h"
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
#include "tofino/parde/add_parde_metadata.h"
#include "tofino/parde/asm_output.h"
#include "tofino/parde/bridge_metadata.h"
#include "tofino/parde/compute_shifts.h"
#include "tofino/parde/digest.h"
#include "tofino/parde/match_keys.h"
#include "tofino/parde/split_big_states.h"
#include "tofino/parde/split_header.h"
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
#include "tofino/phv/phv_analysis_api.h"
#include "tofino/phv/validate_allocation.h"
#include "tofino/common/parser_overlay.h"

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

void backend(const IR::Tofino::Pipe* maupipe, const Tofino_Options& options) {
    PhvInfo phv;
    SymBitMatrix mutually_exclusive_field_ids;
    Cluster cluster(phv);                                        // cluster analysis
    Cluster_PHV_Requirements cluster_phv_req(cluster);           // cluster PHV requirements
    PHV_Field_Operations phv_field_ops(phv);                     // field operation analysis
    PHV_Interference cluster_phv_interference(cluster_phv_req, mutually_exclusive_field_ids);
                                                                 // cluster PHV Interference Graph
    PHV_MAU_Group_Assignments cluster_phv_mau(cluster_phv_req);  // cluster PHV Container placements
    Cluster_Slicing cluster_slicing(cluster_phv_mau);            // cluster slicing
    Cluster_PHV_Overlay cluster_phv_overlay(cluster_phv_mau, cluster_phv_interference);
                                                                 // overlay clusters to MAU groups
                                                                 // need cluster_phv_interference
                                                                 // func mutually_exclusive(f1, f2)
    PHV_Analysis_API phv_analysis_api(phv, cluster_phv_mau, 0);  // extended object interface
                                                                 // phv_analysis to rest of compiler
    PHV_Bind phv_bind(phv, cluster_phv_mau);                     // field binding to PHV Containers
    DependencyGraph deps;
    TablesMutuallyExclusive mutex;
    FieldDefUse defuse(phv);
    HeaderStackInfo stacks;
    TableSummary summary;
    MauAsmOutput mauasm(phv);
    Visitor *phv_alloc;
    ParserOverlay parserOverlay(phv, mutually_exclusive_field_ids);
    LayoutChoices lc;

    if (options.trivial_phvalloc) {
        phv_alloc = new PHV::TrivialAlloc(phv);
    } else {
        phv_alloc = new PassManager({
            //
            // &cluster_phv_mau,   // cluster PHV container placements
                                // second cut PHV MAU Group assignments
                                // honor single write conflicts from Table Placement
            &phv_bind,          // fields bound to PHV containers
                                // later passes assume that phv alloc info
                                // is sorted in field bit order, msb first
                                // done by phv_bind
        });
    }

    PassManager *phv_analysis = new PassManager({
        &cluster,              // cluster analysis
        &parserOverlay,        // produce pairs of mutually exclusive header
                               // fields, eg. (arpSrc, ipSrc)
        &phv_field_ops,        // PHV field operations analysis
        &cluster_phv_req,      // cluster PHV requirements analysis
        options.phv_interference?  &cluster_phv_interference: nullptr,
                               // cluster PHV interference graph analysis
        &cluster_phv_mau,      // cluster PHV container placements
                               // first cut PHV MAU Group assignments
                               // produces cohabit fields for Table Placement
        &cluster_slicing,      // slice clusters into smaller clusters
                               // attempt packing with reduced width requirements
                               // slicing also improves overlay possibilities due to lesser width
                               // although number and mutual exclusion of fields don't change
        &cluster_phv_overlay,  // overlay unallocated clusters to clusters as well as MAU groups
        &phv_analysis_api,     // phv analysis results api interface
    });

    PassManager backend = {
        new DumpPipe("Initial table graph"),
        new RemoveEmptyControls,
        new CheckStatefulAlu,
        &phv,
        &defuse,
        new AddBridgedMetadata(phv, defuse),
        new AddMetadataShims,
        new Digests,
        &phv,  // only needed to avoid warnings about otherwise unused ingress/egress_port?
        new LiveAtEntry(phv),
        new CreateThreadLocalInstances(INGRESS),
        new CreateThreadLocalInstances(EGRESS),
        &stacks,
        new StackPushShims(stacks),
        &phv,
        new VisitFunctor([&phv, &stacks]() { phv.allocatePOV(stacks); }),
        new HeaderPushPop(stacks),
        new CopyHeaderEliminator,   // needs to be after POV alloc and before InstSel
        new InstructionSelection(phv),
        new DumpPipe("Before ElimUnused .....after InstructionSelection"),
        &defuse,
        new ElimUnused(phv, defuse),
        new DumpPipe("After ElimUnused .....before phv_analysis"),
        //
        phv_analysis,               // phv analysis after last &phv pass
        //
        new GatewayOpt(phv),   // must be before TableLayout?  or just TablePlacement?
        new TableLayout(phv, lc),
        new TableFindSeqDependencies,
        new FindDependencyGraph(phv, deps),
        Log::verbose() ? new VisitFunctor([&deps]() { std::cout << deps; }) : nullptr,
        new SpreadGatewayAcrossSeq,
        new CheckTableNameDuplicate,
        new TableFindSeqDependencies,
        new CheckTableNameDuplicate,
        new FindDependencyGraph(phv, deps),
        &mutex,
        new DetermineActionProfileFaults(mutex),
        new DumpPipe("Before table placement"),
        new TablePlacement(&deps, mutex, phv, lc),
        new CheckTableNameDuplicate,
        new TableFindSeqDependencies,  // not needed?
        new CheckTableNameDuplicate,
        new ComputeShifts,
        new DumpPipe("Before ElimUnused .....after ComputeShifts"),
        &defuse,
        new ElimUnused(phv, defuse),
        new DumpPipe("After ElimUnused .....before SetReferenced"),
        new PhvInfo::SetReferenced(phv),
        &mutex,
        &summary,
        Log::verbose() ? new VisitFunctor([&summary]() { std::cout << summary; }) : nullptr,
        //
        phv_alloc,                   // phv assignment / binding
        //
        Log::verbose() ? new VisitFunctor([&phv]() { std::cout << phv; }) : nullptr,
        new PHV::ValidateAllocation(phv),

        new IXBarRealign(phv),
        new SplitExtractEmit,
        new TotalInstructionAdjustment(phv),
        new LoadMatchKeys(phv),   // depends on SplitExtractEmit
        new SplitPhvUse(phv),     // depends on SplitExtractEmit
        new SplitBigStates(phv),  // depends on SplitPhvUse
        new DumpPipe("Final table graph"),
        new CheckTableNameDuplicate,
        new PhvInfo::SetReferenced(phv),
        &mauasm
    };
    backend.setName("Tofino backend");
    if (LOGGING(4))
        backend.addDebugHook(debug_hook);
    maupipe = maupipe->apply(backend);

    if (ErrorReporter::instance.getErrorCount() > 0)
        return;
    std::ostream *out = &std::cout;
    if (options.outputFile)
        out = new std::ofstream(options.outputFile);
    *out << "version: 1.0.0" << std::endl
         << PhvAsmOutput(phv)
         << ParserAsmOutput(maupipe, phv, INGRESS)
         << DeparserAsmOutput(maupipe, phv, INGRESS)
         << ParserAsmOutput(maupipe, phv, EGRESS)
         << DeparserAsmOutput(maupipe, phv, EGRESS)
         << mauasm << std::flush;
}

}  // namespace Tofino
