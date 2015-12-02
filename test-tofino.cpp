#include <iostream>
#include <stdio.h>
#include <string>
#include "ir/ir.h"
#include "ir/dbprint.h"
#include "lib/log.h"
#include "tofino/common/extract_maupipe.h"
#include "tofino/common/field_defuse.h"
#include "tofino/mau/asm_output.h"
#include "tofino/mau/phv_constraints.h"
#include "tofino/mau/split_gateways.h"
#include "tofino/mau/table_dependency_graph.h"
#include "tofino/mau/table_layout.h"
#include "tofino/mau/table_mutex.h"
#include "tofino/mau/table_placement.h"
#include "tofino/mau/table_seqdeps.h"
#include "tofino/mau/table_summary.h"
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

void test_tofino_backend(const IR::Global *program) {
    if (verbose) {
	std::cout << "-------------------------------------------------" << std::endl
		  << "Initial program" << std::endl
		  << "-------------------------------------------------" << std::endl;
	std::cout << *program << std::endl; }
    PhvInfo phv;
    program->apply(phv);

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
    PassManager backend = {
	new CreateThreadLocalInstances,
	new HeaderFragmentCreator,
	new CopyHeaderEliminator,
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
	std::cout << *maupipe << std::endl /* << deps;
	std::cout << defuse */; }
    TableSummary summary;
    maupipe->apply(CheckTableNameDuplicate());
    maupipe->apply(summary);
    if (verbose)
	std::cout << summary;
    MauAsmOutput mauasm;
    maupipe->apply(mauasm);
    std::cout << PhvAsmOutput(phv) << mauasm;
}
