#include <assert.h>
#include "ir/ir.h"
#include "ir/dbprint.h"
#include "common/inline_control_flow.h"
#include "common/name_gateways.h"
#include "frontends/p4v1.2/evaluator/evaluator.h"
#include "frontends/p4v1.2/methodInstance.h"
#include "tofino/common/param_binding.h"
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
  const P4V12::BlockMap                         *blockMap;
  gress_t                                       gress;
  IR::Tofino::Pipe                              *pipe;
  map<const IR::Node *, IR::MAU::Table *>       tables;
  map<const IR::Node *, IR::MAU::TableSeq *>    seqs;

 public:
  GetTofinoTables(const IR::Global *gl, gress_t gr, IR::Tofino::Pipe *p)
  : program(gl), blockMap(nullptr), gress(gr), pipe(p) {}
  GetTofinoTables(const P4V12::BlockMap *bm, gress_t gr, IR::Tofino::Pipe *p)
  : program(nullptr), blockMap(bm), gress(gr), pipe(p) {}

 private:
  void add_tt_action(IR::MAU::Table *tt, IR::ID name) {
    if (auto action = program->get<IR::ActionFunction>(name)) {
      if (!tt->actions.count(name))
        tt->actions.add(name, action);
      else
        error("%s: action %s appears multiple times in table %s", name.srcInfo, name, tt->name);
    } else {
      error("%s: no action %s for table %s", name.srcInfo, name, tt->name); } }
  void setup_tt_actions(IR::MAU::Table *tt, const IR::Table *table) {
    for (auto act : table->actions)
      add_tt_action(tt, act);
    if (auto ap = program->get<IR::ActionProfile>(table->action_profile.name)) {
      tt->attached.push_back(ap);
      for (auto act : ap->actions)
        add_tt_action(tt, act);
      if (auto sel = program->get<IR::ActionSelector>(ap->selector.name))
        tt->attached.push_back(sel);
      else if (ap->selector)
        error("%s: no action_selector %s", ap->selector.srcInfo, ap->selector.name);
    } else if (table->action_profile) {
      error("%s: no action_profile %s", table->action_profile.srcInfo,
            table->action_profile.name); } }
  void setup_tt_actions(IR::MAU::Table *tt, const IR::TableContainer *table) {
    for (auto act : *table->properties->getProperty("actions")->value
                          ->to<IR::ActionList>()->actionList)
      if (auto action = blockMap->refMap->getDeclaration(act->name->path)
                                ->to<IR::ActionContainer>()) {
        if (!tt->actions.count(action->name))
          tt->actions.add(action->name, new IR::ActionFunction(action, act->arguments));
        else
          error("%s: action %s appears multiple times in table %s", action->name.srcInfo,
                action->name, tt->name); }
    // action_profile already pulled into TableContainer?
  }

  bool preorder(const IR::Vector<IR::Declaration> *) override { return false; }

  bool preorder(const IR::Vector<IR::Expression> *v) override {
    assert(!seqs.count(v));
    seqs[v] = new IR::MAU::TableSeq();
    return true; }
  void postorder(const IR::Vector<IR::Expression> *v) override {
    for (auto el : *v)
      if (tables.count(el))
        seqs.at(v)->tables.push_back(tables.at(el)); }
  bool preorder(const IR::BlockStatement *b) override {
    assert(!seqs.count(b));
    seqs[b] = new IR::MAU::TableSeq();
    return true; }
  void postorder(const IR::BlockStatement *b) override {
    for (auto el : *b->components)
      if (tables.count(el))
        seqs.at(b)->tables.push_back(tables.at(el)); }

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
    auto tt = tables.at(a);
    for (auto &act : a->actions) {
      auto name = act.first;
      if (!tt->actions.count(name)) {
          if (name == "hit")
            name = "$hit";
          else if (name == "miss")
            name = "$miss";
          else if (name != "default")
            error("%s: no action %s in table %s", a->srcInfo, name, tt->name); }
      tt->next[name] = seqs.at(act.second); } }
  bool preorder(const IR::MethodCallExpression *m) override {
      auto mi = P4V12::MethodInstance::resolve(m, blockMap->refMap, blockMap->typeMap, true);
    if (!mi || !mi->isApply())
      BUG("Method Call %1% not apply", m);
    auto table = mi->object->to<IR::TableContainer>();
    if (!table) BUG("%1% not apllied to table", m);
    if (!tables.count(m)) {
      auto tt = tables[m] = new IR::MAU::Table(table->name, gress, new IR::Table(table));
      setup_tt_actions(tt, table);
    } else {
      error("%s: Multiple applies of table %s not supported", m->srcInfo, table->name); }
    return true; }
  void postorder(const IR::MethodCallStatement *m) override {
    if (!tables.count(m->methodCall))
        BUG("MethodCall %1% is not apply", m);
    tables[m] = tables.at(m->methodCall); }
  void postorder(const IR::SwitchStatement *s) override {
    auto exp = s->expression->to<IR::Member>();
    if (!exp || exp->member != "action_run" || !tables.count(exp->expr)) {
      error("%s: Can only switch on table.apply().action_run", s->expression->srcInfo);
      return; }
    auto tt = tables[s] = tables.at(exp->expr);
    for (auto c : *s->cases)
      tt->next[c->label] = seqs.at(c->statement); }

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
  bool preorder(const IR::IfStatement *c) {
    static int uid = 0;
    char buf[16];
    snprintf(buf, sizeof(buf), "cond-%d", ++uid);
    tables[c] = new IR::MAU::Table(buf, gress, c->condition);
    return true; }
  void postorder(const IR::IfStatement *c) {
    if (c->ifTrue)
      tables.at(c)->next["true"] = seqs.at(c->ifTrue);
    if (c->ifFalse)
      tables.at(c)->next["false"] = seqs.at(c->ifFalse); }

  void postorder(const IR::Control *cf) override {
    assert(!pipe->thread[gress].mau);
    pipe->thread[gress].mau = seqs.at(cf->code); }
  bool preorder(const IR::ControlContainer *cf) override {
    visit(cf->body);
    assert(!pipe->thread[gress].mau);
    pipe->thread[gress].mau = seqs.at(cf->body);
    return false; }

  void postorder(const IR::Statement *st) {
    BUG("Unhandled statement %1%", st); }
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

class ConvertIndexToHeaderStackItemRef : public Transform {
    const IR::Expression *preorder(IR::ArrayIndex *idx) override {
        auto type = idx->type->to<IR::Type_Header>();
        if (!type) BUG("%1% is not a header stack ref");
        return new IR::HeaderStackItemRef(idx->srcInfo, type, idx->left, idx->right); }
};

const IR::Tofino::Pipe *extract_maupipe(const IR::P4V12Program *program) {
    P4V12::EvaluatorPass evaluator(true);
    program = program->apply(evaluator);
    auto blockMap = evaluator.getBlockMap();
    auto top = blockMap->getToplevelBlock();
    if (!top) {
        error("No main switch");
        return nullptr; }

    auto parser_blk = blockMap->getBlockBoundToParameter(top, "p");
    auto parser = parser_blk->to<P4V12::ParserBlock>()->container;
    auto ingress_blk = blockMap->getBlockBoundToParameter(top, "ig");
    auto ingress = ingress_blk->to<P4V12::ControlBlock>()->container;
    auto egress_blk = blockMap->getBlockBoundToParameter(top, "eg");
    auto egress = egress_blk->to<P4V12::ControlBlock>()->container;
    auto deparser_blk = blockMap->getBlockBoundToParameter(top, "dep");
    auto deparser = deparser_blk->to<P4V12::ControlBlock>()->container;
    LOG1("parser:" << parser);
    LOG1("ingress:" << ingress);
    LOG1("egress:" << egress);
    LOG1("deparser:" << deparser);
    // FIXME add consistency/sanity checks to make sure arch is well-formed.

    auto rv = new IR::Tofino::Pipe();

    ParamBinding bindings(blockMap);

    for (auto param : *parser->type->applyParams->parameters)
        if (param->type->is<IR::Type_StructLike>())
            bindings.bind(param);
    for (auto param : *ingress->type->applyParams->parameters)
        if (param->type->is<IR::Type_StructLike>())
            bindings.bind(param);
    for (auto param : *egress->type->applyParams->parameters)
        if (param->type->is<IR::Type_StructLike>())
            bindings.bind(param);
    for (auto param : *deparser->type->applyParams->parameters)
        if (param->type->is<IR::Type_StructLike>())
            bindings.bind(param);

    rv->standard_metadata =
        bindings.get(ingress->type->applyParams->parameters->back())->obj->to<IR::Metadata>();
    PassManager fixups = {
        &bindings,
        new RemoveInstanceRef,
        new ConvertIndexToHeaderStackItemRef
    };
    parser = parser->apply(fixups);
    ingress = ingress->apply(fixups);
    egress = egress->apply(fixups);
    deparser = deparser->apply(fixups);

    GetTofinoParser make_parser(parser);
    parser->apply(make_parser);
    if (auto in = rv->thread[INGRESS].parser = make_parser.parser(INGRESS))
        rv->thread[INGRESS].deparser = new IR::Tofino::Deparser(INGRESS, in);
    if (auto eg = rv->thread[EGRESS].parser = make_parser.parser(EGRESS))
        rv->thread[EGRESS].deparser = new IR::Tofino::Deparser(EGRESS, eg);

    ingress = ingress->apply(InlineControlFlow(blockMap));
    ingress->apply(GetTofinoTables(blockMap, INGRESS, rv));
    egress = egress->apply(InlineControlFlow(blockMap));
    egress->apply(GetTofinoTables(blockMap, EGRESS, rv));

    // AttachTables...

    return rv->apply(fixups);
}
