#include <assert.h>
#include "ir/ir.h"
#include "ir/dbprint.h"
#include "frontends/p4v1/inline_control_flow.h"
#include "common/name_gateways.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/methodInstance.h"
#include "tofino/common/param_binding.h"
#include "tofino/mau/table_dependency_graph.h"
#include "tofino/parde/extract_parser.h"
#include "lib/algorithm.h"
#include "lib/error.h"
#include "blockmap.h"
#include "rewrite.h"

namespace {
class ActionArgSetup : public Transform {
    /* FIXME -- use ParameterSubstitution for this somehow? */
    std::map<cstring, const IR::Expression *>    args;
    const IR::Node *preorder(IR::PathExpression *pe) override {
        if (args.count(pe->path->name))
            return args.at(pe->path->name);
        return pe; }

 public:
    void add_arg(const IR::ActionArg *a) { args[a->name] = a; }
    void add_arg(cstring name, const IR::Expression *e) { args[name] = e; }
};

class ActionBodySetup : public Inspector {
    IR::ActionFunction      *af;
    ActionArgSetup          &setup;
    bool preorder(const IR::IndexedVector<IR::StatOrDecl> *) override { return true; }
    bool preorder(const IR::BlockStatement *) override { return true; }
    bool preorder(const IR::AssignmentStatement *assign) override {
        cstring pname = "modify_field";
        if (assign->left->type->is<IR::Type_Header>())
            pname = "copy_header";
        auto prim = new IR::Primitive(assign->srcInfo, pname, assign->left, assign->right);
        af->action.push_back(prim->apply(setup));
        return false; }
    bool preorder(const IR::MethodCallStatement *mc) override {
        ERROR("extern method call " << mc << " not yet implemented");
        return false; }
    bool preorder(const IR::Declaration *) override {
        // FIXME -- for now, ignoring local variables?  Need copy prop + dead code elim
        return false; }
    bool preorder(const IR::Node *n) override {
        BUG("un-handled node %1% in action", n);
        return false; }

 public:
    ActionBodySetup(IR::ActionFunction *af, ActionArgSetup &setup) : af(af), setup(setup) {}
};
}  // anonymous namespace

const IR::ActionFunction *createActionFunction(const IR::P4Action *ac,
                                               const IR::Vector<IR::Expression> *args) {
    IR::ActionFunction *rv = new IR::ActionFunction;
    rv->srcInfo = ac->srcInfo;
    rv->name = ac->externalName();
    ActionArgSetup setup;
    size_t arg_idx = 0;
    for (auto param : *ac->parameters->getEnumerator()) {
        if ((param->direction == IR::Direction::None) ||
            ((!args || arg_idx >= args->size()) && param->direction == IR::Direction::In)) {
            auto arg = new IR::ActionArg(param->srcInfo, param->type, param->name);
            setup.add_arg(arg);
            rv->args.push_back(arg);
        } else {
            if (!args || arg_idx >= args->size())
                error("%s: Not enough args for %s", args ? args->srcInfo : ac->srcInfo, ac);
            else
                setup.add_arg(param->name, args->at(arg_idx++)); } }
    if (arg_idx != (args ? args->size(): 0))
        error("%s: Too many args for %s", args->srcInfo, ac);
    ac->body->apply(ActionBodySetup(rv, setup));
    return rv;
}

static void setIntProperty(cstring name, int *val, const IR::PropertyValue *pval) {
    if (auto *ev = pval->to<IR::ExpressionValue>()) {
        if (auto *cv = ev->expression->to<IR::Constant>()) {
            *val = cv->asInt();
            return; } }
    error("%s: %s property must be a constant", pval->srcInfo, name);
}

const IR::V1Table *createV1Table(const IR::P4Table *tc, const P4::ReferenceMap *refMap) {
    IR::V1Table *rv = new IR::V1Table;
    rv->srcInfo = tc->srcInfo;
    rv->name = tc->externalName();
    for (auto prop : *tc->properties->properties) {
        if (prop->name == "key") {
            auto reads = new IR::Vector<IR::Expression>();
            for (auto el : *prop->value->to<IR::Key>()->keyElements) {
                reads->push_back(el->expression);
                rv->reads_types.push_back(el->matchType->path->name); }
            rv->reads = reads;
        } else if (prop->name == "actions") {
            for (auto el : *prop->value->to<IR::ActionList>()->actionList)
                rv->actions.push_back(refMap->getDeclaration(el->name->path, true)->externalName());
        } else if (prop->name == "default_action") {
            auto v = prop->value->to<IR::ExpressionValue>();
            if (!v) {
            } else if (auto pe = v->expression->to<IR::PathExpression>()) {
                rv->default_action = refMap->getDeclaration(pe->path, true)->externalName();
                rv->default_action.srcInfo = pe->srcInfo;
                continue;
            } else if (auto mc = v->expression->to<IR::MethodCallExpression>()) {
                if (auto pe = mc->method->to<IR::PathExpression>()) {
                    rv->default_action = refMap->getDeclaration(pe->path, true)->externalName();
                    rv->default_action.srcInfo = mc->srcInfo;
                    rv->default_action_args = mc->arguments;
                    continue; } }
            BUG("default action %1% is not an action or call", prop->value);
        } else if (prop->name == "size") {
            setIntProperty(prop->name, &rv->size, prop->value);
        } else if (prop->name == "min_size") {
            setIntProperty(prop->name, &rv->min_size, prop->value);
        } else if (prop->name == "max_size") {
            setIntProperty(prop->name, &rv->max_size, prop->value); } }
    return rv;
}

namespace {
class FindAttached : public Inspector {
  map<cstring, vector<const IR::Attached *>>    &attached;
  void postorder(const IR::Stateful *st) override {
    if (!contains(attached[st->table], st))
      attached[st->table].push_back(st); }
 public:
  explicit FindAttached(map<cstring, vector<const IR::Attached *>> &a) : attached(a) {}
};

struct AttachTables : public Modifier {
  const IR::V1Program                          *program;
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

  explicit AttachTables(const IR::V1Program *prg) : program(prg) {
    program->apply(FindAttached(attached)); }
};

static const IR::MethodCallExpression *isApplyHit(const IR::Expression *e, bool *lnot = 0) {
  if (auto *n = e->to<IR::LNot>()) {
    e = n->expr;
    if (lnot) *lnot = true;
  } else if (lnot) {
    *lnot = false; }
  if (auto *mem = e->to<IR::Member>()) {
    if (mem->member != "hit") return nullptr;
    if (auto *mc = mem->expr->to<IR::MethodCallExpression>()) {
      mem = mc->method->to<IR::Member>();
      if (mem && mem->member == "apply")
        return mc; } }
  return nullptr;
}

class GetTofinoTables : public Inspector {
  const IR::V1Program                          *program;
  const P4::ReferenceMap                       *refMap;
  const P4::TypeMap                            *typeMap;
  gress_t                                       gress;
  IR::Tofino::Pipe                              *pipe;
  map<const IR::Node *, IR::MAU::Table *>       tables;
  map<const IR::Node *, IR::MAU::TableSeq *>    seqs;
  IR::MAU::TableSeq *getseq(const IR::Node *n) {
    if (!seqs.count(n) && tables.count(n))
        seqs[n] = new IR::MAU::TableSeq(tables.at(n));
    return seqs.at(n); }

 public:
    GetTofinoTables(const IR::V1Program *prog, gress_t gr, IR::Tofino::Pipe *p)
            : program(prog), refMap(nullptr), typeMap(nullptr), gress(gr), pipe(p) {}
    GetTofinoTables(const P4::ReferenceMap* refMap, const P4::TypeMap* typeMap,
                    gress_t gr, IR::Tofino::Pipe *p)
            : program(nullptr), refMap(refMap), typeMap(typeMap), gress(gr), pipe(p) {}

 private:
  void add_tt_action(IR::MAU::Table *tt, IR::ID name) {
    if (auto action = program->get<IR::ActionFunction>(name)) {
      if (!tt->actions.count(name))
        tt->actions.add(name, action);
      else
        error("%s: action %s appears multiple times in table %s", name.srcInfo, name, tt->name);
    } else {
      error("%s: no action %s for table %s", name.srcInfo, name, tt->name); } }
  void setup_tt_actions(IR::MAU::Table *tt, const IR::V1Table *table) {
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
  void setup_tt_actions(IR::MAU::Table *tt, const IR::P4Table *table) {
    for (auto act : *table->properties->getProperty("actions")->value
                          ->to<IR::ActionList>()->actionList)
      if (auto action = refMap->getDeclaration(act->name->path)
                                ->to<IR::P4Action>()) {
        auto newaction = createActionFunction(action, act->arguments);
        if (!tt->actions.count(newaction->name))
          tt->actions.addUnique(newaction->name, newaction);
        else
          error("%s: action %s appears multiple times in table %s", action->name.srcInfo,
                action->name, tt->name); }
    // action_profile already pulled into TableContainer?
  }

  bool preorder(const IR::IndexedVector<IR::Declaration> *) override { return false; }
  bool preorder(const IR::P4Table *) override { return false; }

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
    auto table = program->get<IR::V1Table>(a->name);
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
      tt->next[name] = getseq(act.second); } }
  bool preorder(const IR::MethodCallExpression *m) override {
    auto mi = P4::MethodInstance::resolve(m, refMap, typeMap, true);
    if (!mi || !mi->isApply())
      BUG("Method Call %1% not apply", m);
    auto table = mi->object->to<IR::P4Table>();
    if (!table) BUG("%1% not apllied to table", m);
    if (!tables.count(m)) {
      auto tt = tables[m] = new IR::MAU::Table(table->name, gress,
                                               createV1Table(table, refMap));
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
    for (auto c : *s->cases) {
        cstring label;
        if (c->label->is<IR::DefaultExpression>())
            label = "default";
        else
            label = refMap->getDeclaration(c->label->to<IR::PathExpression>()->path)
                            ->externalName();
        tt->next[label] = getseq(c->statement); } }

  bool preorder(const IR::NamedCond *c) override {
    if (!tables.count(c))
      tables[c] = new IR::MAU::Table(c->name, gress, c->pred);
    else
      BUG("duplicated unique name?");
    return true; }
  void postorder(const IR::NamedCond *c) override {
    if (c->ifTrue)
      tables.at(c)->next["true"] = getseq(c->ifTrue);
    if (c->ifFalse)
      tables.at(c)->next["false"] = getseq(c->ifFalse); }
  bool preorder(const IR::If *) override {
    BUG("unnamed condition in control flow"); }
  bool preorder(const IR::IfStatement *c) {
    if (!isApplyHit(c->condition)) {
      static int uid = 0;
      char buf[16];
      snprintf(buf, sizeof(buf), "cond-%d", ++uid);
      tables[c] = new IR::MAU::Table(buf, gress, c->condition); }
    return true; }
  void postorder(const IR::IfStatement *c) {
    bool lnot;
    cstring T = "true", F = "false";
    if (auto *mc = isApplyHit(c->condition, &lnot)) {
      tables[c] = tables.at(mc);
      T = lnot ? "$miss" : "$hit";
      F = lnot ? "$hit" : "$miss"; }
    if (c->ifTrue && !c->ifTrue->is<IR::EmptyStatement>())
      tables.at(c)->next[T] = getseq(c->ifTrue);
    if (c->ifFalse && !c->ifFalse->is<IR::EmptyStatement>())
      tables.at(c)->next[F] = getseq(c->ifFalse); }
  void postorder(const IR::V1Control *cf) override {
    assert(!pipe->thread[gress].mau);
    pipe->thread[gress].mau = getseq(cf->code); }
  bool preorder(const IR::P4Control *cf) override {
    visit(cf->body);
    assert(!pipe->thread[gress].mau);
    pipe->thread[gress].mau = getseq(cf->body);
    return false; }

  bool preorder(const IR::EmptyStatement *) override { return false; }
  void postorder(const IR::Statement *st) override {
    BUG("Unhandled statement %1%", st); }
};
}  // anonymous namespace

const IR::Tofino::Pipe *extract_maupipe(const IR::V1Program *program) {
  auto rv = new IR::Tofino::Pipe();
  rv->standard_metadata = program->get<IR::Metadata>("standard_metadata");
  GetTofinoParser parser(program);
  program->apply(parser);
  auto ingress = program->get<IR::V1Control>(parser.ingress_entry());
  if (!ingress) ingress = new IR::V1Control(IR::ID("ingress"));
  ingress = ingress->apply(InlineControlFlow(program));
  ingress = ingress->apply(NameGateways());
  auto egress = program->get<IR::V1Control>("egress");
  if (!egress) egress = new IR::V1Control(IR::ID("egress"));
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
        if (!type) BUG("%1% is not a header stack ref", idx->type);
        return new IR::HeaderStackItemRef(idx->srcInfo, type, idx->left, idx->right); }
};

const IR::Tofino::Pipe *extract_maupipe(const IR::P4Program *program) {
    P4::ReferenceMap  refMap;
    P4::TypeMap       typeMap;
    P4::EvaluatorPass evaluator(&refMap, &typeMap, true);
    program = program->apply(evaluator);
    auto blockMap = evaluator.getBlockMap();
    auto top = blockMap->getMain();
    if (!top) {
        error("No main switch");
        return nullptr; }

    auto parser_blk = blockMap->getBlockBoundToParameter(top, "p");
    auto parser = parser_blk->to<IR::ParserBlock>()->container;
    auto ingress_blk = blockMap->getBlockBoundToParameter(top, "ig");
    auto ingress = ingress_blk->to<IR::ControlBlock>()->container;
    auto egress_blk = blockMap->getBlockBoundToParameter(top, "eg");
    auto egress = egress_blk->to<IR::ControlBlock>()->container;
    auto deparser_blk = blockMap->getBlockBoundToParameter(top, "dep");
    auto deparser = deparser_blk->to<IR::ControlBlock>()->container;
    LOG1("parser:" << parser);
    LOG1("ingress:" << ingress);
    LOG1("egress:" << egress);
    LOG1("deparser:" << deparser);
    // FIXME add consistency/sanity checks to make sure arch is well-formed.

    auto rv = new IR::Tofino::Pipe();

    ParamBinding bindings(&refMap);

    for (auto param : *parser->type->applyParams->getEnumerator())
        if (param->type->is<IR::Type_StructLike>())
            bindings.bind(param);
    for (auto param : *ingress->type->applyParams->getEnumerator())
        if (param->type->is<IR::Type_StructLike>())
            bindings.bind(param);
    for (auto param : *egress->type->applyParams->getEnumerator())
        if (param->type->is<IR::Type_StructLike>())
            bindings.bind(param);
    for (auto param : *deparser->type->applyParams->getEnumerator())
        if (param->type->is<IR::Type_StructLike>())
            bindings.bind(param);

    auto it = ingress->type->applyParams->parameters->rbegin();
    rv->standard_metadata =
        bindings.get(*it)->obj->to<IR::Metadata>();
    PassManager fixups = {
        &bindings,
        new RemoveInstanceRef,
        new ConvertIndexToHeaderStackItemRef,
        new RewriteForTofino,
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

    //ingress = ingress->apply(InlineControlFlow(blockMap));
    ingress->apply(GetTofinoTables(&refMap, &typeMap, INGRESS, rv));
    //egress = egress->apply(InlineControlFlow(blockMap));
    egress->apply(GetTofinoTables(&refMap, &typeMap, EGRESS, rv));

    // AttachTables...

    return rv->apply(fixups);
}
