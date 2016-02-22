#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string>
#include "ir/ir.h"
#include "ir/dbprint.h"
#include "lib/log.h"
#include "tofinoOptions.h"
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
#include "tofino/parde/add_parde_metadata.h"
#include "tofino/parde/asm_output.h"
#include "tofino/parde/compute_shifts.h"
#include "tofino/parde/split_header.h"
#include "tofino/phv/asm_output.h"
#include "tofino/phv/phv_allocate.h"
#include "tofino/phv/create_thread_local_instances.h"
#include "tofino/phv/header_fragment_creator.h"
#include "tofino/common/copy_header_eliminator.h"

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

extern void dump(const IR::Node *);
void force_link_dump(const IR::Node *n) { dump(n); }

void test_tofino_backend(const IR::Tofino::Pipe *maupipe, const Tofino_Options *options) {
    PhvInfo phv;
    maupipe = maupipe->apply(AddMetadataShims());
    maupipe = maupipe->apply(phv);
    phv.allocatePOV();
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
    PassManager backend = {
        new CreateThreadLocalInstances(INGRESS),
        new CreateThreadLocalInstances(EGRESS),
        new SplitExtractEmit,
        options->phv_alloc ? new CopyHeaderEliminator : 0,
        options->phv_alloc ? new HeaderFragmentCreator : 0,
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
    if (ErrorReporter::instance.getErrorCount() > 0)
        return;
    MauAsmOutput mauasm(phv);
    maupipe->apply(mauasm);
    std::ostream *out = &std::cout;
    if (options->outputFile)
        out = new std::ofstream(options->outputFile);
    *out << PhvAsmOutput(phv)
         << ParserAsmOutput(maupipe, phv, INGRESS)
         << DeparserAsmOutput(maupipe, phv, INGRESS)
         << ParserAsmOutput(maupipe, phv, EGRESS)
         << DeparserAsmOutput(maupipe, phv, EGRESS)
         << mauasm << std::flush;
}
