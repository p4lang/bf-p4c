#include "ir/ir.h"
#include <assert.h>
#include <algorithm>
#include "table_dependency_graph.h"
#include "lib/log.h"

static const char *dep_types[] = { "W", "A", "M" };

std::ostream &operator<<(std::ostream &out, const DependencyGraph &dg) {
    auto save = out.flags();
    for (auto &tt : dg.graph) {
	out << std::setw(16) << std::left << tt.first;
        int w = std::max((int)tt.first.size() - 16, 0);
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

class AddDependencies : public MauInspector, P4WriteContext {
    typedef DependencyGraph::Table	Table;
    typedef DependencyGraph::access_t	access_t;
    map<cstring, access_t>	&access;
    Table			*table;
    Table::depend_t		type;
public:
    AddDependencies(map<cstring, access_t> &a, Table *t, Table::depend_t ty)
    : access(a), table(t), type(ty) {}
    void add_dependency(cstring field) {
	if (!access.count(field)) return;
	LOG3("add_dependency(" << field << ")");
	if (isWrite()) {
	    for (auto t : access[field].read)
		if (table->data_dep[t->name] < Table::WRITE)
		    table->data_dep[t->name] = Table::WRITE;
	} else
	    for (auto t : access[field].write)
		if (table->data_dep[t->name] < type)
		    table->data_dep[t->name] = type;
    }
    bool preorder(const IR::FieldRef *f) { add_dependency(f->toString()); return false; }
    bool preorder(const IR::HeaderStackItemRef *f) { add_dependency(f->toString()); return false; }
};

class UpdateAccess : public MauInspector {
    typedef DependencyGraph::Table	Table;
    typedef DependencyGraph::access_t	access_t;
    map<cstring, access_t>	&access;
    Table			*table;
public:
    UpdateAccess(map<cstring, access_t> &a, Table *t) : access(a), table(t) {}
    bool preorder(const IR::FieldRef *f) {
	LOG3("update_access read " << f->toString());
	access[f->toString()].read.insert(table);
	return false; }
    bool preorder(const IR::HeaderStackItemRef *f) {
	LOG3("update_access read " << f->toString());
	access[f->toString()].read.insert(table);
	return false; }
    void postorder(const IR::Primitive *prim) {
	if (prim->name == "modify_field" || prim->name == "add_to_field") {
	    cstring name;
	    if (auto f = dynamic_cast<const IR::FieldRef *>(prim->operands[0]))
		name = f->toString();
	    else if (auto i = dynamic_cast<const IR::HeaderStackItemRef *>(prim->operands[0]))
		name = i->toString();
	    else {
		error("%s: Destination of %s is not a field", prim->srcInfo, prim->name);
		return; }
	    LOG3("update_access write " << name);
	    auto &a = access[name];
	    a.read.clear();
	    a.write.clear();
	    a.write.insert(table); }
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
    } else
	assert(false);
}

bool FindDependencyGraph::preorder(const IR::MAU::TableSeq *) {
    const Context *ctxt = getContext();
    if (ctxt && dynamic_cast<const IR::Tofino::Pipe *>(ctxt->node)) {
	gress = gress_t(ctxt->child_index);
	access.clear(); }
    return true;
}
bool FindDependencyGraph::preorder(const IR::MAU::Table *t) {
    if (!graph.count(t->name)) {
	LOG3("FindDep table " << t->name);
	auto &table = graph.emplace(t->name, Table(t->name, gress)).first->second;
	add_control_dependency(&table, t);
	if (t->gateway_expr)
	    t->gateway_expr->apply(AddDependencies(access, &table, Table::MATCH));
	if (t->match_table && t->match_table->reads)
	    t->match_table->reads->apply(AddDependencies(access, &table, Table::MATCH));
	for (auto &action : t->actions)
	    action->apply(AddDependencies(access, &table, Table::ACTION));
	if (t->gateway_expr)
	    t->gateway_expr->apply(UpdateAccess(access, &table));
	for (auto &action : t->actions)
	    action->apply(UpdateAccess(access, &table));
    } else
	error("%s: Multiple applies of table %s not supported", t->srcInfo, t->name);
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
