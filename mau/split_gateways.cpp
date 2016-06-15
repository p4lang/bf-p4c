#include "ir/ir.h"
#include "split_gateways.h"
#include "lib/log.h"

Visitor::profile_t SpreadGatewayAcrossSeq::init_apply(const IR::Node *root) {
    auto rv = MauTransform::init_apply(root);
    root->apply(uses);
    LOG2(uses);
    return rv;
}

const IR::Node *SpreadGatewayAcrossSeq::postorder(IR::MAU::Table *t) {
    char suffix[8];
    int counter = 0;
#if 1
    if (!do_splitting) {
        prune();
        return t; }
#endif
    if (!t->uses_gateway()) return t;
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
                snprintf(suffix, sizeof(suffix), ".%d", ++counter);
                newtable = t->clone_rename(suffix);
                newtable->next.clear();
                rv->push_back(newtable); }
            newtable->next[it->first] =
                new IR::MAU::TableSeq(newtable->next[it->first], table);
            if (uses.tables_modify(table) & uses.table_reads(t))
                splitting = false; } }
    if (rv->size() <= 1)
        return t;
    for (int i = 1; i <= counter; i++) {
        snprintf(suffix, sizeof(suffix), ".%d", i);
        uses.cloning_table(t->name, t->name + suffix); }
    return rv;
}

const IR::MAU::Table *SplitComplexGateways::preorder(IR::MAU::Table *tbl) {
    if (tbl->gateway_rows.size() <= 1) return tbl;
    if (tbl->match_table)
        BUG("Must run SplitComplexGateways before attaching gateways to match tables");
    CollectGatewayFields collect(phv);
    tbl->apply(collect);
    if (collect.compute_offsets())
        return tbl;
    for (unsigned i = tbl->gateway_rows.size() - 1; i > 0; --i) {
        CollectGatewayFields collect(phv, i);
        tbl->apply(collect);
        if (collect.compute_offsets()) {
#if 0
        FIXME -- this is actually wrong as it effectively duplicates the table in the
        dependency tree, which is ok in some cases, but won't work in others.  Need to
        figure out how the change the representation to make use of this pattern correctly
        in the general case, without having to introduce new metadata.
            LOG1("Splitting " << i << " rows into " << tbl->name);
            auto rest = tbl->clone_rename("-split");
            rest->gateway_rows.erase(rest->gateway_rows.begin(), rest->gateway_rows.begin() + i);
            tbl->gateway_rows.erase(tbl->gateway_rows.begin() + i, tbl->gateway_rows.end());
            tbl->gateway_rows.emplace_back(nullptr, "$gwcont");
            tbl->next.addUnique("$gwcont", new IR::MAU::TableSeq(rest));
#endif
            return tbl; } }
    return tbl;
}
