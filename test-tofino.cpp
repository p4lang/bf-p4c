#include <iostream>
#include <stdio.h>
#include <string>
#include "ir/ir.h"
#include "ir/dbprint.h"
#include "lib/log.h"
#include "common/extract_maupipe.h"
#include "common/field_defuse.h"
#include "mau/split_gateways.h"
#include "mau/table_dependency_graph.h"
#include "mau/table_layout.h"
#include "mau/table_mutex.h"
#include "mau/table_placement.h"
#include "mau/table_seqdeps.h"

void test_tofino_backend(const IR::Global *program) {
    PhvInfo phv;
    program->apply(phv);

    auto maupipe = extract_maupipe(program);
    maupipe = maupipe->apply(TableLayout());
    maupipe = maupipe->apply(TableFindSeqDependencies());
    if (verbose)
	std::cout << *maupipe << std::endl;
    DependencyGraph deps;
    maupipe->apply(FindDependencyGraph(&deps));
    if (verbose)
	std::cout << deps;
    TablesMutuallyExclusive mutex;
    PassManager table_place = {
	new SplitGateways,
	new TableFindSeqDependencies,
	new FindDependencyGraph(&deps),
	&mutex,
	new TablePlacement(deps, mutex),
	new TableFindSeqDependencies,  // not needed?
    };
    maupipe = maupipe->apply(table_place);
    FieldDefUse defuse(phv);
    maupipe->apply(defuse);
    if (verbose) {
	std::cout << *maupipe << std::endl << deps;
	std::cout << defuse; }
}
