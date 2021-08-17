#include "table_control_deps.h"
#include "lib/algorithm.h"

ordered_set<const IR::MAU::Table *> TableControlDeps::parents() {
    ordered_set<const IR::MAU::Table *> rv;
    const Visitor::Context *ctxt = nullptr;
    while (auto *t = findContext<IR::MAU::Table>(ctxt))
        rv.insert(t);
    return rv;
}

void TableControlDeps::postorder(const IR::MAU::Table *tbl) {
    BUG_CHECK(!info.count(tbl), "visit called when previously visited?");
    info_t &info = this->info[tbl];
    info.parents = parents();
    ordered_set<const IR::MAU::TableSeq *> next;
    for (auto *seq : Values(tbl->next))
        next.insert(seq);
    info.dependent_paths = next.size();
}

void TableControlDeps::revisit(const IR::MAU::Table *tbl) {
    BUG_CHECK(info.count(tbl), "revisit called when not previously visited?");
    auto parents = this->parents();
    erase_if(info.at(tbl).parents, [&](const IR::MAU::Table *t) { return !parents.count(t); });
}

bool TableControlDeps::operator()(const IR::MAU::Table *a, const IR::MAU::Table *b) const {
    BUG_CHECK(info.count(a), "table not present");
    BUG_CHECK(info.count(b), "table not present");
    return info.at(b).parents.count(a);
}

int TableControlDeps::paths(const IR::MAU::Table *tbl) const {
    BUG_CHECK(info.count(tbl), "table not present");
    return info.at(tbl).dependent_paths;
}