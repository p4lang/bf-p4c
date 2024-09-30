#include "table_control_deps.h"
#include "lib/algorithm.h"

ordered_set<const P4::IR::MAU::Table *> TableControlDeps::parents() {
    ordered_set<const P4::IR::MAU::Table *> rv;
    const Visitor::Context *ctxt = nullptr;
    while (auto *t = findContext<P4::IR::MAU::Table>(ctxt))
        rv.insert(t);
    return rv;
}

void TableControlDeps::postorder(const P4::IR::MAU::Table *tbl) {
    BUG_CHECK(!info.count(tbl), "visit called when previously visited?");
    info_t &info = this->info[tbl];
    info.parents = parents();
    ordered_set<const P4::IR::MAU::TableSeq *> next;
    for (auto *seq : Values(tbl->next))
        next.insert(seq);
    info.dependent_paths = next.size();
}

void TableControlDeps::revisit(const P4::IR::MAU::Table *tbl) {
    BUG_CHECK(info.count(tbl), "revisit called when not previously visited?");
    auto parents = this->parents();
    erase_if(info.at(tbl).parents, [&](const P4::IR::MAU::Table *t) { return !parents.count(t); });
}

bool TableControlDeps::operator()(const P4::IR::MAU::Table *a, const P4::IR::MAU::Table *b) const {
    BUG_CHECK(info.count(a), "table not present");
    BUG_CHECK(info.count(b), "table not present");
    return info.at(b).parents.count(a);
}

int TableControlDeps::paths(const P4::IR::MAU::Table *tbl) const {
    BUG_CHECK(info.count(tbl), "table not present");
    return info.at(tbl).dependent_paths;
}
