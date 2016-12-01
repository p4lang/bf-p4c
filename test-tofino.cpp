#include <base/logging.h>
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
#include "tofino/mau/instruction_selection.h"
#include "tofino/mau/ixbar_realign.h"
#include "tofino/mau/phv_constraints.h"
#include "tofino/mau/push_pop.h"
#include "tofino/mau/split_gateways.h"
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
#include "tofino/parde/match_keys.h"
#include "tofino/parde/split_big_states.h"
#include "tofino/parde/split_header.h"
#include "tofino/parde/stack_push_shims.h"
#include "tofino/phv/asm_output.h"
#include "tofino/phv/trivial_alloc.h"
#include "tofino/phv/split_phv_use.h"
#include "tofino/phv/create_thread_local_instances.h"
#include "tofino/phv/phv_allocator.h"
#include "tofino/phv/cluster_phv_bind.h"

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

void test_tofino_backend(const IR::Tofino::Pipe *maupipe, const Tofino_Options *options) {
    PhvInfo phv;
    Cluster cluster(phv);                                        // cluster analysis
    Cluster_PHV_Requirements cluster_phv_req(cluster);           // cluster PHV requirements
    PHV_MAU_Group_Assignments cluster_phv_mau(cluster_phv_req);  // cluster PHV Container placements
    PHV_Bind phv_bind(phv, cluster_phv_mau);                     // field binding to PHV Containers
    DependencyGraph deps;
    TablesMutuallyExclusive mutex;
    FieldDefUse defuse(phv);
    HeaderStackInfo stacks;
    TableSummary summary;
    MauAsmOutput mauasm(phv);
    PassManager *phv_alloc;

    if (options->phv_ortools) {
        auto *newpa = new PhvAllocator(phv, defuse.conflicts(), std::ref(mutex));
        phv_alloc = new PassManager({
            newpa,
            new VisitFunctor([newpa, options]() {
                if (!newpa->Solve(options->phv_ortools)) {
                    error("or-tools failed to find PHV allocation"); } }),
            Log::verbose() ? new VisitFunctor([&phv]() {
                std::cout << "Printing PHV fields:\n";
                for (auto iter = phv.begin(); iter != phv.end(); ++iter) {
                    LOG2("result:" << iter->name << iter->alloc[0]);
                    LOG2("result:" << iter->name << iter->alloc[1]); }}) : nullptr });
    } else {
        phv_alloc = new PassManager({
            new MauPhvConstraints(phv),
            new PHV::TrivialAlloc(phv, defuse.conflicts()),
            options->phv_new ? new VisitFunctor([&]() {
                // &cluster_phv_mau,  // cluster PHV container placements
                                      // second cut PHV MAU Group assignments
                                      // honor single write conflicts from Table Placement
                &phv_bind,            // fields bound to PHV containers
                }) : nullptr,
            });
    }

    PassManager *phv_analysis = new PassManager({
        &cluster,          // cluster analysis
        &cluster_phv_req,  // cluster PHV requirements analysis
        &cluster_phv_mau,  // cluster PHV container placements
                           // first cut PHV MAU Group assignments
                           // produces cohabit fields for Table Placement
    });

    PassManager backend = {
        new DumpPipe("Initial table graph"),
        new RemoveEmptyControls,
        &phv,
        &defuse,
        new AddBridgedMetadata(phv, defuse),
        new AddMetadataShims,
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

        phv_analysis,               // phv analysis after last &phv pass

        new CanonGatewayExpr,       // must be before TableLayout?  or just TablePlacement?
        new SplitComplexGateways(phv),
        new CheckGatewayExpr(phv),
        new TableLayout(phv),
        new TableFindSeqDependencies,
        new FindDependencyGraph(&deps),
        Log::verbose() ? new VisitFunctor([&deps]() { std::cout << deps; }) : nullptr,
        new TypeCheck,
        new SpreadGatewayAcrossSeq,
        new CheckTableNameDuplicate,
        new TableFindSeqDependencies,
        new CheckTableNameDuplicate,
        new FindDependencyGraph(&deps),
        &mutex,
        new DetermineActionProfileFaults(mutex),
        new DumpPipe("Before table placement"),
        new TablePlacement(deps, mutex, phv),
        new CheckTableNameDuplicate,
        new TableFindSeqDependencies,  // not needed?
        new CheckTableNameDuplicate,
        new ComputeShifts,
        new DumpPipe("Before ElimUnused"),
        &defuse,
        new ElimUnused(phv, defuse),
        new DumpPipe("After ElimUnused"),
        new PhvInfo::SetReferenced(phv),
        &mutex,
        &summary,
        Log::verbose() ? new VisitFunctor([&summary]() { std::cout << summary; }) : nullptr,

        phv_alloc,                   // phv assignment / binding

        Log::verbose() ? new VisitFunctor([&phv]() { std::cout << phv; }) : nullptr,

        new IXBarRealign(phv),
        new SplitExtractEmit,
        new LoadMatchKeys(phv),   // depends on SplitExtractEmit
        new SplitPhvUse(phv),     // depends on SplitExtractEmit
        new SplitBigStates(phv),  // depends on SplitPhvUse
        new DumpPipe("Final table graph"),
        new CheckTableNameDuplicate,
        new PhvInfo::SetReferenced(phv),
        &mauasm
    };
    if (LOGGING(4))
        backend.addDebugHook(debug_hook);
    maupipe = maupipe->apply(backend);
    if (ErrorReporter::instance.getErrorCount() > 0)
        return;
    std::ostream *out = &std::cout;
    if (options->outputFile)
        out = new std::ofstream(options->outputFile);
    *out << "version: 1.0.0" << std::endl
         << PhvAsmOutput(phv)
         << ParserAsmOutput(maupipe, phv, INGRESS)
         << DeparserAsmOutput(maupipe, phv, INGRESS)
         << ParserAsmOutput(maupipe, phv, EGRESS)
         << DeparserAsmOutput(maupipe, phv, EGRESS)
         << mauasm << std::flush;
}
