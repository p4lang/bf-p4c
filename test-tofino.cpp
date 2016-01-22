#include <stdio.h>
#include <iostream>
#include <string>
#include "ir/ir.h"
#include "ir/dbprint.h"
#include "lib/log.h"
#include "lib/options.h"
#include "tofino/common/extract_maupipe.h"
#include "tofino/common/field_defuse.h"
#include "tofino/mau/asm_output.h"
#include "tofino/mau/instruction_selection.h"
#include "tofino/mau/phv_constraints.h"
#include "tofino/mau/split_gateways.h"
#include "tofino/mau/table_dependency_graph.h"
#include "tofino/mau/table_layout.h"
#include "tofino/mau/table_mutex.h"
#include "tofino/mau/table_placement.h"
#include "tofino/mau/table_seqdeps.h"
#include "tofino/mau/table_summary.h"
#include "tofino/parde/asm_output.h"
#include "tofino/parde/compute_shifts.h"
#include "tofino/parde/split_header.h"
#include "tofino/phv/asm_output.h"
#include "tofino/phv/phv_allocate.h"
#include "tofino/phv/create_thread_local_instances.h"
#include "tofino/phv/header_fragment_creator.h"
#include "tofino/common/copy_header_eliminator.h"
#include "tofino/common/modify_field_splitter.h"
#include "tofino/common/modify_field_eliminator.h"
#include "tofino/common/or_tools_allocator.h"

class CheckTableNameDuplicate : public MauInspector {
    set<cstring>        names;
    profile_t init_apply(const IR::Node *root) override {
        names.clear();
        return MauInspector::init_apply(root); }
    bool preorder(const IR::MAU::Table *t) override {
        assert(names.count(t->name) == 0);
        names.insert(t->name);
        return true; }
};

class DumpPipe : public Inspector {
    bool preorder(const IR::Tofino::Pipe *pipe) override {
        if (verbose)
            std::cout << *pipe << std::endl;
        return false; }
};

void test_tofino_backend(const IR::Global *program, const CompilerOptions *options) {
    if (verbose) {
        std::cout << "-------------------------------------------------" << std::endl
                  << "Initial program" << std::endl
                  << "-------------------------------------------------" << std::endl;
        std::cout << *program << std::endl; }
    PhvInfo phv;
    program->apply(phv);
    phv.allocatePOV();

    auto maupipe = extract_maupipe(program);
    maupipe = maupipe->apply(TableLayout());
    maupipe = maupipe->apply(TableFindSeqDependencies());
    if (verbose) {
        std::cout << "-------------------------------------------------" << std::endl
                  << "Initial table graph" << std::endl
                  << "-------------------------------------------------" << std::endl;
        std::cout << *maupipe << std::endl; }
    DependencyGraph deps;
    maupipe->apply(FindDependencyGraph(&deps));
    if (verbose)
        std::cout << deps;
    TablesMutuallyExclusive mutex;
    FieldDefUse defuse(phv);
    ORToolsAllocator or_tools_allocator;
    PassManager backend = {
        new CreateThreadLocalInstances(INGRESS),
        new CreateThreadLocalInstances(EGRESS),
        new SplitExtractEmit,
        options->phv_alloc ? new HeaderFragmentCreator : 0,
        options->phv_alloc ? new CopyHeaderEliminator : 0,
        options->phv_alloc ? new ModifyFieldSplitter : 0,
        options->phv_alloc ? new ModifyFieldEliminator : 0,
        new SplitGateways,
        new CheckTableNameDuplicate,
        new TableFindSeqDependencies,
        new CheckTableNameDuplicate,
        new FindDependencyGraph(&deps),
        &mutex,
        new TablePlacement(deps, mutex),
        new CheckTableNameDuplicate,
        new TableFindSeqDependencies,  // not needed?
        new CheckTableNameDuplicate,
        new InstructionSelection,
        new ComputeShifts,
        new DumpPipe,
        &defuse,
        new MauPhvConstraints(phv),
        new PhvAllocate(phv, defuse.conflicts()),
#if 0
        options->phv_alloc ? or_tools_allocator.parde_inspector() : 0,
        options->phv_alloc ? or_tools_allocator.mau_inspector() : 0,
#endif
    };
    maupipe = maupipe->apply(backend);
    or_tools_allocator.Solve();
    if (verbose) {
        std::cout << DBPrint::setflag(DBPrint::TableNoActions);
        std::cout << "-------------------------------------------------" << std::endl
                  << "Final table graph" << std::endl
                  << "-------------------------------------------------" << std::endl;
        std::cout << *maupipe << std::endl /* << deps << defuse */; }
    TableSummary summary;
    maupipe->apply(CheckTableNameDuplicate());
    maupipe->apply(summary);
    if (verbose)
        std::cout << summary;
    MauAsmOutput mauasm(phv);
    maupipe->apply(mauasm);
    std::cout << PhvAsmOutput(phv)
              << ParserAsmOutput(maupipe, INGRESS)
              << DeparserAsmOutput(maupipe, INGRESS)
              << ParserAsmOutput(maupipe, EGRESS)
              << DeparserAsmOutput(maupipe, EGRESS)
              << mauasm;
}
