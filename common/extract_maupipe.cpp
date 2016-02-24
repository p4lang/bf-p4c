#include <assert.h>
#include "ir/ir.h"
#include "ir/dbprint.h"
#include "common/inline_control_flow.h"
#include "common/name_gateways.h"
#include "frontends/p4v1.2/evaluator/evaluator.h"
#include "tofino/mau/table_dependency_graph.h"
#include "tofino/parde/extract_parser.h"
#include "lib/algorithm.h"
#include "lib/error.h"

class FindAttached : public Inspector {
  map<cstring, vector<const IR::Attached *>>    &attached;
  void postorder(const IR::Stateful *st) override {
    if (!contains(attached[st->table], st))
      attached[st->table].push_back(st); }
 public:
  explicit FindAttached(map<cstring, vector<const IR::Attached *>> &a) : attached(a) {}
};

struct AttachTables : public Modifier {
  const IR::Global                              *program;
  map<cstring, vector<const IR::Attached *>>    attached;

  void postorder(IR::MAU::Table *tbl) override {
    if (attached.count(tbl->name))
      for (auto a : attached[tbl->name])
        if (!contains(tbl->attached, a))
          tbl->attached.push_back(a); }
  void postorder(IR::Primitive *prim) override {
    if (prim->name == "count" || prim->name == "execute_meter")
      if (auto at = program->get<IR::Attached>(prim->operands[0]->toString())) {
        if (auto tt = findContext<IR::MAU::Table>())
          if (!contains(attached[tt->name], at))
            attached[tt->name].push_back(at); }
    /* various error check should be here */ }

  explicit AttachTables(const IR::Global *prg) : program(prg) {
    program->apply(FindAttached(attached)); }
};

class GetTofinoTables : public Inspector {
  const IR::Global                              *program;
  gress_t                                       gress;
  IR::Tofino::Pipe                              *pipe;
  map<const IR::Node *, IR::MAU::Table *>       tables;
  map<const IR::Node *, IR::MAU::TableSeq *>    seqs;

 public:
  GetTofinoTables(const IR::Global *gl, gress_t gr, IR::Tofino::Pipe *p)
  : program(gl), gress(gr), pipe(p) {}

 private:
  void setup_tt_actions(IR::MAU::Table *tt, const IR::Table *table) {
    for (auto act : table->actions)
      if (auto action = program->get<IR::ActionFunction>(act.name))
        if (std::find(tt->actions.begin(), tt->actions.end(), action) == tt->actions.end())
          tt->actions.push_back(action);
    if (auto ap = program->get<IR::ActionProfile>(table->action_profile.name)) {
      tt->attached.push_back(ap);
      for (auto act : ap->actions)
        if (auto action = program->get<IR::ActionFunction>(act.name))
          if (std::find(tt->actions.begin(), tt->actions.end(), action) == tt->actions.end())
            tt->actions.push_back(action);
      if (auto sel = program->get<IR::ActionSelector>(ap->selector.name))
        tt->attached.push_back(sel);
      else if (ap->selector)
        error("%s: no action_selector %s", ap->selector.srcInfo, ap->selector.name);
    } else if (table->action_profile) {
      error("%s: no action_profile %s", table->action_profile.srcInfo,
            table->action_profile.name); } }

  bool preorder(const IR::Vector<IR::Expression> *v) override {
    assert(!seqs.count(v));
    seqs[v] = new IR::MAU::TableSeq();
    return true; }
  void postorder(const IR::Vector<IR::Expression> *v) override {
    for (auto el : *v)
      if (tables.count(el))
        seqs.at(v)->tables.push_back(tables.at(el)); }

  bool preorder(const IR::Apply *a) override {
    auto table = program->get<IR::Table>(a->name);
    if (!tables.count(a)) {
      if (!table) {
        error("%s: No table named %s", a->srcInfo, a->name);
        return true; }
      auto tt = tables[a] = new IR::MAU::Table(a->name, gress, table);
      setup_tt_actions(tt, table);
    } else {
      error("%s: Multiple applies of table %s not supported", a->srcInfo, a->name); }
    return true; }
  void postorder(const IR::Apply *a) override {
    for (auto &act : a->actions)
      tables.at(a)->next[act.first] = seqs.at(act.second); }

  bool preorder(const IR::NamedCond *c) override {
    if (!tables.count(c))
      tables[c] = new IR::MAU::Table(c->name, gress, c->pred);
    else
      BUG("duplicated unique name?");
    return true; }
  void postorder(const IR::NamedCond *c) override {
    if (c->ifTrue)
      tables.at(c)->next["true"] = seqs.at(c->ifTrue);
    if (c->ifFalse)
      tables.at(c)->next["false"] = seqs.at(c->ifFalse); }

  bool preorder(const IR::If *) override {
    BUG("unnamed condition in control flow"); }
  void postorder(const IR::Control *cf) override {
    assert(!pipe->thread[gress].mau);
    pipe->thread[gress].mau = seqs.at(cf->code); }
};

const IR::Tofino::Pipe *extract_maupipe(const IR::Global *program) {
  auto rv = new IR::Tofino::Pipe();
  rv->standard_metadata = program->get<IR::Metadata>("standard_metadata");
  GetTofinoParser parser(program);
  program->apply(parser);
  auto ingress = program->get<IR::Control>(parser.ingress_entry());
  if (!ingress) ingress = new IR::Control(IR::ID("ingress"));
  ingress = ingress->apply(InlineControlFlow(program));
  ingress = ingress->apply(NameGateways());
  auto egress = program->get<IR::Control>("egress");
  if (!egress) egress = new IR::Control(IR::ID("egress"));
  egress = egress->apply(InlineControlFlow(program));
  egress = egress->apply(NameGateways());
  ingress->apply(GetTofinoTables(program, INGRESS, rv));
  egress->apply(GetTofinoTables(program, EGRESS, rv));
  if (auto in = rv->thread[INGRESS].parser = parser.parser(INGRESS))
    rv->thread[INGRESS].deparser = new IR::Tofino::Deparser(INGRESS, in);
  if (auto eg = rv->thread[EGRESS].parser = parser.parser(EGRESS))
    rv->thread[EGRESS].deparser = new IR::Tofino::Deparser(EGRESS, eg);
  AttachTables toAttach(program);
  for (auto &th : rv->thread)
    th.mau = th.mau->apply(toAttach);
  return rv;
}

const IR::Tofino::Pipe *extract_maupipe(const IR::P4V12Program *program) {
    P4V12::EvaluatorPass evaluator(false);
    program = program->apply(evaluator);
    auto blockMap = evaluator.getBlockMap();
    auto top = blockMap->getToplevelBlock();
    if (!top) {
        error("No main switch");
        return nullptr; }

    auto parser_blk = blockMap->getBlock(top, top->getParameterValue("prsr"));
    auto parser = parser_blk->to<P4V12::ParserBlock>()->container;
    auto ingress_blk = blockMap->getBlock(top, top->getParameterValue("ingress"));
    auto ingress = ingress_blk->to<P4V12::ControlBlock>()->container;
    auto egress_blk = blockMap->getBlock(top, top->getParameterValue("egress"));
    auto egress = egress_blk->to<P4V12::ControlBlock>()->container;
    auto deparser_blk = blockMap->getBlock(top, top->getParameterValue("deparser"));
    auto deparser = deparser_blk->to<P4V12::ControlBlock>()->container;
    LOG1("parser:" << parser);
    LOG1("ingress:" << ingress);
    LOG1("egress:" << egress);
    LOG1("deparser:" << deparser);
    // FIXME add consistency/sanity checks to make sure arch is well-formed.

    auto rv = new IR::Tofino::Pipe();
#if 0
    auto hdr_t = blockMap->typeMap->getType(ingress->type->applyParams->parameters->at(0)->type);
    auto meta_t = blockMap->typeMap->getType(ingress->type->applyParams->parameters->at(1)->type);
    rv->standard_metadata = new IR::Metadata("standard_metadata", "standard_metadata", meta_t);
#endif
    GetTofinoParser make_parser(parser);
    parser->apply(make_parser);
    if (auto in = rv->thread[INGRESS].parser = make_parser.parser(INGRESS))
        rv->thread[INGRESS].deparser = new IR::Tofino::Deparser(INGRESS, in);
    if (auto eg = rv->thread[EGRESS].parser = make_parser.parser(EGRESS))
        rv->thread[EGRESS].deparser = new IR::Tofino::Deparser(EGRESS, eg);

    return rv;
}
