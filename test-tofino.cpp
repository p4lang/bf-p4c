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
#include "tofino/common/extract_maupipe.h"
#include "tofino/common/elim_unused.h"
#include "tofino/common/field_defuse.h"
#include "tofino/mau/asm_output.h"
#include "tofino/mau/gateway.h"
#include "tofino/mau/instruction_selection.h"
#include "tofino/mau/ixbar_realign.h"
#include "tofino/mau/phv_constraints.h"
#include "tofino/mau/split_gateways.h"
#include "tofino/mau/table_dependency_graph.h"
#include "tofino/mau/table_layout.h"
#include "tofino/mau/table_mutex.h"
#include "tofino/mau/table_placement.h"
#include "tofino/mau/table_seqdeps.h"
#include "tofino/mau/table_summary.h"
#include "tofino/parde/add_parde_metadata.h"
#include "tofino/parde/asm_output.h"
#include "tofino/parde/compute_shifts.h"
#include "tofino/parde/match_keys.h"
#include "tofino/parde/split_big_states.h"
#include "tofino/parde/split_header.h"
#include "tofino/phv/asm_output.h"
#include "tofino/phv/greedy_alloc.h"
#include "tofino/phv/split_phv_use.h"
#include "tofino/phv/create_thread_local_instances.h"
#include "tofino/phv/header_fragment_creator.h"
#include "tofino/phv/phv_allocator.h"
#include "tofino/common/copy_header_eliminator.h"

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
        if (verbose) {
            if (heading)
                std::cout << "-------------------------------------------------" << std::endl
                          << heading << std::endl
                          << "-------------------------------------------------" << std::endl;
            if (verbose > 1)
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
    DependencyGraph deps;
    TablesMutuallyExclusive mutex;
    FieldDefUse defuse(phv);
    TableSummary summary;
    MauAsmOutput mauasm(phv);
    PassManager *phv_alloc;

    if (options->phv_newalloc) {
        auto *newpa = new PhvAllocator(phv, defuse.conflicts(), std::ref(mutex));
        phv_alloc = new PassManager({
            newpa,
            new VisitFunctor([newpa, options]() {
                if (!newpa->Solve(options->phv_newalloc)) {
                    error("or-tools failed to find PHV allocation"); } }),
            verbose ? new VisitFunctor([&phv]() {
                std::cout << "Printing PHV fields:\n";
                for (auto iter = phv.begin(); iter != phv.end(); ++iter) {
                    LOG2("result:" << iter->name << iter->alloc[0]);
                    LOG2("result:" << iter->name << iter->alloc[1]); }}) : nullptr });
    } else {
        phv_alloc = new PassManager({
            new MauPhvConstraints(phv),
            new PHV::GreedyAlloc(phv, defuse.conflicts()) });
    }

    PassManager backend = {
        new DumpPipe("Initial table graph"),
        new AddMetadataShims,
        new CreateThreadLocalInstances(INGRESS),
        new CreateThreadLocalInstances(EGRESS),
        &phv,
        new VisitFunctor([&phv]() { phv.allocatePOV(); }),
        new CanonGatewayExpr,   // must be before TableLayout?  or just TablePlacement?
        new SplitComplexGateways(phv),
        new CheckGatewayExpr(phv),
        new TableLayout,
        new TableFindSeqDependencies,
        new FindDependencyGraph(&deps),
        verbose ? new VisitFunctor([&deps]() { std::cout << deps; }) : nullptr,
        new CopyHeaderEliminator,
        new HeaderFragmentCreator,
        new TypeCheck,
        new SpreadGatewayAcrossSeq,
        new CheckTableNameDuplicate,
        new TableFindSeqDependencies,
        new CheckTableNameDuplicate,
        new FindDependencyGraph(&deps),
        &mutex,
        new DumpPipe("Before table placement"),
        new TablePlacement(deps, mutex, phv),
        new CheckTableNameDuplicate,
        new TableFindSeqDependencies,  // not needed?
        new CheckTableNameDuplicate,
        new InstructionSelection,
        new ComputeShifts,
        new DumpPipe("Before PA alloc"),
        &defuse,
        new ElimUnused(phv, defuse),
        new DumpPipe("After ElimUnused"),
        new PhvInfo::SetReferenced(phv),
        &mutex,
        &summary,
        verbose ? new VisitFunctor([&summary]() { std::cout << summary; }) : nullptr,

        phv_alloc,

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
