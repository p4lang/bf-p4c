#include <base/logging.h>
#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string>
#include "ir/ir.h"
#include "ir/dbprint.h"
#include "lib/log.h"
#include "frontends/p4v1/typecheck.h"
#include "tofinoOptions.h"
#include "tofino/common/extract_maupipe.h"
#include "tofino/common/field_defuse.h"
#include "tofino/mau/asm_output.h"
#include "tofino/mau/gateway.h"
#include "tofino/mau/instruction_selection.h"
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
#include "tofino/parde/split_header.h"
#include "tofino/phv/asm_output.h"
#include "tofino/phv/phv_allocate.h"
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
            BUG("Mulitple tables named '%s'", t->name);
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

void test_tofino_backend(const IR::Tofino::Pipe *maupipe, const Tofino_Options *options) {
    PhvInfo phv;
    DependencyGraph deps;
    TablesMutuallyExclusive mutex;
    FieldDefUse defuse(phv);
    TableSummary summary;
    MauAsmOutput mauasm(phv);
    PassManager backend = {
        new AddMetadataShims,
        &phv,
        new VisitFunctor([&phv]() { phv.allocatePOV(); }),
        new CanonGatewayExpr,
        new TableLayout,
        new TableFindSeqDependencies,
        new DumpPipe("Initial table graph"),
        new FindDependencyGraph(&deps),
        new VisitFunctor([&deps]() { if (verbose) std::cout << deps; }),
        new CreateThreadLocalInstances(INGRESS),
        new CreateThreadLocalInstances(EGRESS),
        options->phv_alloc ? new CopyHeaderEliminator : 0,
        options->phv_alloc ? new HeaderFragmentCreator : 0,
        new TypeCheck,
        new SplitGateways,
        new CheckTableNameDuplicate,
        new TableFindSeqDependencies,
        new CheckTableNameDuplicate,
        new FindDependencyGraph(&deps),
        &mutex,
        new TablePlacement(deps, mutex, phv),
        new CheckTableNameDuplicate,
        new TableFindSeqDependencies,  // not needed?
        new CheckTableNameDuplicate,
        new InstructionSelection,
        new ComputeShifts,
        new DumpPipe,
        &defuse,
        new MauPhvConstraints(phv),
        new PhvAllocate(phv, defuse.conflicts()),
    };
    maupipe = maupipe->apply(backend);
    PhvInfo gort_phv_allocation;
    maupipe->apply(gort_phv_allocation);
    gort_phv_allocation.allocatePOV();
    PhvAllocator phv_allocator(maupipe);
    CHECK(true == phv_allocator.Solve(maupipe, &gort_phv_allocation));
    LOG2("Printing PHV fields:");
    for (auto iter = gort_phv_allocation.begin();
         iter != gort_phv_allocation.end(); ++iter) {
      if (iter->alloc[0].size() == 0) {
        LOG2("result:" << (iter)->name << (iter)->alloc[1]);
      }
      else {
        CHECK(iter->alloc[1].size() == 0) << ": Wrong allocation for " <<
          iter->name;
        LOG2("result:" << (iter)->name << (iter)->alloc[0]);
      }
    }
    PhvInfo *phv_ptr = &gort_phv_allocation;
    PassManager post_phv_allocation_backend = {
      new SplitExtractEmit,
      new LoadMatchKeys(*phv_ptr),   // depends on SplitExtractEmit
      new SplitPhvUse(*phv_ptr),     // depends on SplitExtractEmit
      new DumpPipe("Final table graph"),
      new CheckTableNameDuplicate,
      &summary,
      new VisitFunctor([&summary]() { if (verbose) std::cout << summary; }),
      &mauasm
    };
    maupipe = maupipe->apply(post_phv_allocation_backend);
    if (ErrorReporter::instance.getErrorCount() > 0)
        return;
    std::ostream *out = &std::cout;
    if (options->outputFile)
        out = new std::ofstream(options->outputFile);
    *out << PhvAsmOutput(*phv_ptr)
         << ParserAsmOutput(maupipe, *phv_ptr, INGRESS)
         << DeparserAsmOutput(maupipe, *phv_ptr, INGRESS)
         << ParserAsmOutput(maupipe, *phv_ptr, EGRESS)
         << DeparserAsmOutput(maupipe, *phv_ptr, EGRESS)
         << mauasm << std::flush;
}
