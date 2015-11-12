#include "ir/ir.h"
#include "ir/dbprint.h"
#include "frontends/common/inline_control_flow.h"
#include "frontends/common/name_gateways.h"
#include "mau/table_dependency_graph.h"
#include <assert.h>
#include "lib/algorithm.h"

class FindAttached : public Inspector {
    map<cstring, vector<const IR::Attached *>>	&attached;
    void postorder(const IR::Stateful *st) override {
	if (!contains(attached[st->table], st))
	    attached[st->table].push_back(st);
    }
public:
    FindAttached(map<cstring, vector<const IR::Attached *>> &a) : attached(a) {}
};

struct AttachTables : public Modifier {
    const IR::Global				*program;
    map<cstring, vector<const IR::Attached *>>	attached;
    void postorder(IR::MAU::Table *tbl) override {
	if (attached.count(tbl->name))
	    for (auto a : attached[tbl->name])
		if (!contains(tbl->attached, a))
		    tbl->attached.push_back(a);
    }
    void postorder(IR::Primitive *prim) override {
	if (prim->name == "count" || prim->name == "execute_meter")
	    if (auto at = program->get<IR::Attached>(prim->operands[0]->toString())) {
		if (auto tt = findContext<IR::MAU::Table>())
		    if (!contains(attached[tt->name], at))
			attached[tt->name].push_back(at); }
	/* various error check should be here */ }
    AttachTables(const IR::Global *prg) : program(prg) {
	program->apply(FindAttached(attached)); }
};

class GetTofinoTables : public Inspector {
    const IR::Global		*program;
    gress_t					gress;
    IR::Tofino::Pipe		*pipe;
    map<const IR::Node *, IR::MAU::Table *>	tables;
    map<const IR::Node *, IR::MAU::TableSeq *>	seqs;
public:
    GetTofinoTables(const IR::Global *gl, gress_t gr, IR::Tofino::Pipe *p)
    : program(gl), gress(gr), pipe(p) {}
private:
    void setup_tt_actions(IR::MAU::Table *tt, const IR::Table *table) {
	for (auto act : table->actions)
	    if (auto action = program->get<IR::ActionFunction>(act.name))
		if (std::find(tt->actions.begin(), tt->actions.end(), action) == tt->actions.end())
		    tt->actions.push_back(action);
	if (auto ap = program->get<IR::ActionProfile>(table->action_profile))
	    for (auto act : ap->actions)
		if (auto action = program->get<IR::ActionFunction>(act.name))
		    if (std::find(tt->actions.begin(), tt->actions.end(), action) == tt->actions.end())
			tt->actions.push_back(action);
    }
    bool preorder(const IR::Vector<IR::Expression> *v) override {
	assert(!seqs.count(v));
	seqs[v] = new IR::MAU::TableSeq();
	return true;
    }
    void postorder(const IR::Vector<IR::Expression> *v) override {
	for (auto el : *v) {
	    seqs.at(v)->tables.push_back(tables.at(el)); }
    }
    bool preorder(const IR::Apply *a) override {
	auto table = program->get<IR::Table>(a->name);
	if (!tables.count(a)) {
	    if (!table) {
		error(a->lineno(), "No table named %s", a->name.c_str());
		return true; }
	    auto tt = tables[a] = new IR::MAU::Table(a->name, gress, table);
	    setup_tt_actions(tt, table);
	} else
	    error(a->lineno(), "Multiple applies of table %s not supported", a->name.c_str());
	return true;
    }
    void postorder(const IR::Apply *a) override {
	for (auto &act : a->actions)
	    tables.at(a)->next[act.first] = seqs.at(act.second);
    }
    bool preorder(const IR::NamedCond *c) override {
	if (!tables.count(c)) {
	    tables[c] = new IR::MAU::Table(c->name, gress, c->pred);
	} else
	    throw std::logic_error("duplicated unique name?");
	return true;
    }
    void postorder(const IR::NamedCond *c) override {
	if (c->ifTrue)
	    tables.at(c)->next["true"] = seqs.at(c->ifTrue);
	if (c->ifFalse)
	    tables.at(c)->next["false"] = seqs.at(c->ifFalse);
    }
    bool preorder(const IR::If *c) override {
	throw std::logic_error("unnamed condition in control flow");
    }
    void postorder(const IR::Control *cf) override {
	assert(!pipe->thread[gress].mau);
	pipe->thread[gress].mau = seqs.at(cf->code);
    }
};

const IR::Tofino::Pipe *extract_maupipe(const IR::Global *program) {
    auto rv = new IR::Tofino::Pipe();
    //program = program->apply(NameGateways());
    auto parser = program->get<IR::Parser>("start");
    auto ingress = program->get<IR::Control>("ingress");
    if (!ingress) ingress = new IR::Control("ingress");
    ingress = ingress->apply(InlineControlFlow(program));
    ingress = ingress->apply(NameGateways());
    auto egress = program->get<IR::Control>("egress");
    if (!egress) egress = new IR::Control("egress");
    egress = egress->apply(InlineControlFlow(program));
    egress = egress->apply(NameGateways());
    ingress->apply(GetTofinoTables(program, INGRESS, rv));
    egress->apply(GetTofinoTables(program, EGRESS, rv));
    rv->thread[INGRESS].parser = new IR::Tofino::Parser(INGRESS, parser);
    rv->thread[EGRESS].parser = new IR::Tofino::Parser(EGRESS, parser);
    rv->thread[INGRESS].deparser = new IR::Tofino::Deparser(INGRESS, parser);
    rv->thread[EGRESS].deparser = new IR::Tofino::Deparser(EGRESS, parser);
    AttachTables toAttach(program);
    for (auto &th : rv->thread)
	th.mau = th.mau->apply(toAttach);
    return rv;
}
