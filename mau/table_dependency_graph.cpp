#include <assert.h>
#include <algorithm>
#include "table_dependency_graph.h"
#include "ir/ir.h"
#include "lib/log.h"

static const char *dep_types[] = { "W", "A", "M" };

std::ostream &operator<<(std::ostream &out, const DependencyGraph &dg) {
    auto save = out.flags();
    for (auto &tt : dg.graph) {
        out << std::setw(16) << std::left << tt.first;
        int w = std::max(static_cast<int>(tt.first.size()) - 16, 0);
        if (tt.second.min_stage >= 0) {
            out << ' ' << tt.second.min_stage << '+' << tt.second.dep_stages;
            w += 4; }
        for (auto &dep : tt.second.data_dep) {
            if (w > 50) { out << std::endl << std::setw(16) << " "; w = 0; }
            out << ' ' << dep.first << '(' << dep_types[dep.second] << ')';
            w += dep.first.size() + 4; }
        for (auto &dep : tt.second.control_dep) {
            if (w > 50) { out << std::endl << std::setw(16) << " "; w = 0; }
            out << ' ' << dep.first << '(' << dep.second << ')';
            w += dep.first.size() + dep.second.size() + 3; }
        out << std::endl; }
    out.flags(save);
    return out;
}

class FindDependencyGraph::AddDependencies : public MauInspector, P4WriteContext {
    FindDependencyGraph         &self;
    Table                       *table;
    Table::depend_t             type;

 public:
    AddDependencies(FindDependencyGraph &self, Table *t, Table::depend_t ty)
    : self(self), table(t), type(ty) {}
    bool preorder(const IR::Expression *e) override {
        if (auto *field = self.phv.field(e)) {
            if (!self.access.count(field->name)) return false;
            LOG3("add_dependency(" << field->name << ")");
            if (isWrite()) {
                for (auto t : self.access[field->name].read)
                    if (table->data_dep[t->name] < Table::WRITE)
                        table->data_dep[t->name] = Table::WRITE;
            } else {
                for (auto t : self.access[field->name].write)
                    if (table->data_dep[t->name] < type)
                        table->data_dep[t->name] = type; }
            return false; }
        return true; }
};

class FindDependencyGraph::UpdateAccess : public MauInspector , P4WriteContext {
    FindDependencyGraph         &self;
    Table                       *table;

 public:
    UpdateAccess(FindDependencyGraph &self, Table *t) : self(self), table(t) {}
    bool preorder(const IR::Expression *e) override {
        if (auto *field = self.phv.field(e)) {
            if (isWrite()) {
                LOG3("update_access write " << field->name);
                auto &a = self.access[field->name];
                a.read.clear();
                a.write.clear();
                a.write.insert(table);
            } else {
                LOG3("update_access read " << field->name);
                self.access[field->name].read.insert(table); }
            return false; }
        return true; }
};

class FindDependencyGraph::UpdateAttached : public Inspector {
    FindDependencyGraph         &self;
    Table                       *table;

 public:
    UpdateAttached(FindDependencyGraph &self, Table *t) : self(self), table(t) {}
    void postorder(const IR::Meter *meter) override {
        if (meter->direct && meter->result) {
            auto *field = self.phv.field(meter->result);
            BUG_CHECK(field, "meter writing to %s", meter->result);
            auto &a = self.access[field->name];
            a.read.clear();
            a.write.clear();
            a.write.insert(table);
        }
    }
};


void FindDependencyGraph::add_control_dependency(Table *tt, const IR::Node *child) {
    const Context *ctxt = getContext();
    while (ctxt && dynamic_cast<const IR::MAU::TableSeq *>(ctxt->node)) {
        child = ctxt->node;
        ctxt = ctxt->parent; }
    if (!ctxt || dynamic_cast<const IR::Tofino::Pipe *>(ctxt->node)) {
        return;
    } else if (auto *t = dynamic_cast<const IR::MAU::Table *>(ctxt->node)) {
        for (auto &kv : t->next)
            if (kv.second == child) {
                tt->control_dep[t->name] = kv.first;
                return; }
        assert(false);
    } else {
        assert(false); }
}

bool FindDependencyGraph::preorder(const IR::MAU::TableSeq *) {
    const Context *ctxt = getContext();
    if (ctxt && ctxt->node->is<IR::Tofino::Pipe>()) {
        gress = gress_t(ctxt->child_index / 3);
        access.clear(); }
    return true;
}
bool FindDependencyGraph::preorder(const IR::MAU::Table *t) {
    if (!graph.count(t->name)) {
        LOG3("FindDep table " << t->name);
        auto &table = graph.emplace(t->name, Table(t->name, gress)).first->second;
        add_control_dependency(&table, t);
        for (auto &gw : t->gateway_rows)
            gw.first->apply(AddDependencies(*this, &table, Table::MATCH));
        if (t->match_table && t->match_table->reads)
            t->match_table->reads->apply(AddDependencies(*this, &table, Table::MATCH));
        for (auto &action : Values(t->actions))
            action->apply(AddDependencies(*this, &table, Table::ACTION));
        for (auto &gw : t->gateway_rows)
            gw.first->apply(UpdateAccess(*this, &table));
        for (auto &action : Values(t->actions))
            action->apply(UpdateAccess(*this, &table));
        t->apply(UpdateAttached(*this, &table));
    } else {
        error("%s: Multiple applies of table %s not supported", t->srcInfo, t->name); }
    return true;
}

template<class T>
inline set<T> &operator |=(set<T> &s, const set<T> &a) {
    s.insert(a.begin(), a.end());
    return s; }

void FindDependencyGraph::flow_merge(Visitor &v) {
    for (auto &a : dynamic_cast<FindDependencyGraph &>(v).access) {
        access[a.first].read |= a.second.read;
        access[a.first].write |= a.second.write; }
}

void FindDependencyGraph::recompute_dep_stages() {
    for (auto &t : graph) t.second.min_stage = t.second.dep_stages = 0;
    bool delta;
    do {
        delta = false;
        for (auto &t : graph) {
            auto &table = t.second;
            for (auto &dep : table.data_dep) {
                int stages = table.dep_stages;
                int min = graph.at(dep.first).min_stage;
                if (dep.second >= Table::ACTION) ++stages, ++min;
                if (stages > graph.at(dep.first).dep_stages) {
                    graph.at(dep.first).dep_stages = stages;
                    delta = true; }
                if (min > table.min_stage) {
                    table.min_stage = min;
                    delta = true; } }
            for (auto &dep : table.control_dep) {
                int stages = table.dep_stages;
                int min = graph.at(dep.first).min_stage;
                if (stages > graph.at(dep.first).dep_stages) {
                    graph.at(dep.first).dep_stages = stages;
                    delta = true; }
                if (min > table.min_stage) {
                    table.min_stage = min;
                    delta = true; } } }
    } while (delta);
}
