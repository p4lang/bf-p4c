#include "ir/ir.h"
#include "split_gateways.h"
#include "lib/log.h"

Visitor::profile_t SplitGateways::init_apply(const IR::Node *root) {
    auto rv = MauTransform::init_apply(root);
    root->apply(uses);
    LOG2(uses);
    return rv;
}

const IR::Node *SplitGateways::postorder(IR::MAU::Table *t) {
    char suffix[8];
    int counter = 0;
#if 1
    if (!do_splitting) {
        prune();
        return t; }
#endif
    if (!t->gateway_expr) return t;
    if (t->match_table) return t;
    assert(t->actions.empty());
    assert(t->attached.empty());
    auto rv = new IR::Vector<IR::MAU::Table>();
    for (auto it = t->next.rbegin(); it != t->next.rend(); it++) {
        auto seq = dynamic_cast<const IR::MAU::TableSeq *>(it->second);
        if (!seq) return t;
        bool splitting = true;
        IR::MAU::Table *newtable = nullptr;
        for (auto &table : seq->tables) {
            if (splitting) {
                sprintf(suffix, ".%d", ++counter);
                newtable = new IR::MAU::Table(t->name + suffix, t->gress, t->gateway_expr);
                newtable->gateway_cond = t->gateway_cond;
                rv->push_back(newtable); }
            newtable->next[it->first] =
                new IR::MAU::TableSeq(newtable->next[it->first], table);
            if (uses.tables_modify(table) & uses.table_reads(t))
                splitting = false; } }
    if (rv->size() <= 1)
        return t;
    for (int i = 1; i <= counter; i++) {
        sprintf(suffix, ".%d", i);
        uses.cloning_table(t->name, t->name + suffix); }
    return rv;
}
