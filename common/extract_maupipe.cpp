#include <assert.h>
#include "ir/ir.h"
#include "ir/dbprint.h"
#include "frontends/p4-14/inline_control_flow.h"
#include "common/name_gateways.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/methodInstance.h"
#include "tofino/common/param_binding.h"
#include "tofino/mau/table_dependency_graph.h"
#include "tofino/parde/extract_parser.h"
#include "tofino/tofinoOptions.h"
#include "lib/algorithm.h"
#include "lib/error.h"
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
    P4::ReferenceMap        *refMap;
    P4::TypeMap             *typeMap;
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
    bool preorder(const IR::MethodCallStatement *mc) override;
    bool preorder(const IR::Declaration *) override {
        // FIXME -- for now, ignoring local variables?  Need copy prop + dead code elim
        return false; }
    bool preorder(const IR::Annotations *) override {
        // FIXME -- for now, ignoring annotations.
        return false; }
    bool preorder(const IR::Node *n) override {
        BUG("un-handled node %1% in action", n);
        return false; }

 public:
    ActionBodySetup(P4::ReferenceMap *refMap, P4::TypeMap *typeMap, IR::ActionFunction *af,
                    ActionArgSetup &setup)
    : refMap(refMap), typeMap(typeMap), af(af), setup(setup) {}
};

bool ActionBodySetup::preorder(const IR::MethodCallStatement *mc) {
    auto mi = P4::MethodInstance::resolve(mc->methodCall, refMap, typeMap, true);
    cstring name;
    const IR::Expression *recv = nullptr;
    if (auto bi = mi->to<P4::BuiltInMethod>()) {
        name = bi->name;
        recv = bi->appliedTo;
    } else if (auto em = mi->to<P4::ExternMethod>()) {
        name = em->actualExternType->name + "." + em->method->name;
        auto n = em->object->getNode();
        recv = new IR::GlobalRef(typeMap->getType(n), n);
    } else if (auto ef = mi->to<P4::ExternFunction>()) {
        name = ef->method->name;
    } else {
        BUG("method call %s not yet implemented", mc); }
    static const std::map<cstring, cstring> name_remap = {
        { "counter.count", "count" },
        { "isValid", "valid" },
        { "meter.execute_meter", "execute_meter" },
        { "pop_front", "pop" },
        { "push_front", "push" },
    };
    if (name_remap.count(name)) name = name_remap.at(name);
    auto prim = new IR::Primitive(mc->srcInfo, name);
    if (recv) prim->operands.push_back(recv);
    for (auto arg : *mc->methodCall->arguments)
        prim->operands.push_back(arg);
    af->action.push_back(prim->apply(setup));
    return false;
}

}  // anonymous namespace

static IR::ActionFunction *createActionFunction(P4::ReferenceMap *refMap, P4::TypeMap *typeMap,
                                                const IR::P4Action *ac,
                                                const IR::Vector<IR::Expression> *args) {
    IR::ActionFunction *rv = new IR::ActionFunction;
    rv->srcInfo = ac->srcInfo;
    rv->name = ac->externalName();
    ActionArgSetup setup;
    size_t arg_idx = 0;
    for (auto param : *ac->parameters->getEnumerator()) {
        if ((param->direction == IR::Direction::None) ||
            ((!args || arg_idx >= args->size()) && param->direction == IR::Direction::In)) {
            auto arg = new IR::ActionArg(param->srcInfo, param->type, rv->name, param->name);
            setup.add_arg(arg);
            rv->args.push_back(arg);
        } else {
            if (!args || arg_idx >= args->size())
                error("%s: Not enough args for %s", args ? args->srcInfo : ac->srcInfo, ac);
            else
                setup.add_arg(param->name, args->at(arg_idx++)); } }
    if (arg_idx != (args ? args->size(): 0))
        error("%s: Too many args for %s", args->srcInfo, ac);
    ac->body->apply(ActionBodySetup(refMap, typeMap, rv, setup));
    return rv;
}

static IR::ID getAnnotID(const IR::Annotations *annot, cstring name) {
    if (auto a = annot->getSingle(name))
        if (a->expr.size() == 1)
            if (auto str = a->expr.at(0)->to<IR::StringLiteral>())
                return IR::ID(str->srcInfo, str->value);
    return IR::ID();
}

static IR::Attached *createV1Attached(IR::MAU::Table *tt, Util::SourceInfo srcInfo, cstring name,
                                      const IR::Type *type, const IR::Vector<IR::Expression> *args,
                                      const IR::Annotations *annot) {
    IR::CounterOrMeter *rv = nullptr;
    // FIXME -- this should be looking at the arch model, but the current arch model stuff
    // is too complex -- need a way of building this automatically from the arch.p4 file.
    // For now, hack just using the type name as a string.
    cstring tname = type->toString();
    if (auto p = tname.find('<'))  // strip off type args (if any)
        tname = tname.before(p);
    if (tname == "action_selector") {
        auto sel = new IR::ActionSelector(srcInfo, name);
        auto flc = new IR::FieldListCalculation();
        flc->algorithm = args->at(0)->as<IR::Member>().member;
        flc->output_width = args->at(2)->as<IR::Constant>().asInt();
        sel->key_fields = flc;
        sel->mode = getAnnotID(annot, "mode");
        sel->type = getAnnotID(annot, "type");
        auto ap = new IR::ActionProfile(srcInfo, name);
        ap->size = args->at(1)->as<IR::Constant>().asInt();
        ap->selector = name;
        // FIXME Need to reconstruct the field list from the table key?
        tt->attached.push_back(ap);
        return sel;
    } else if (tname == "action_profile") {
        auto ap = new IR::ActionProfile(srcInfo, name);
        ap->size = args->at(0)->as<IR::Constant>().asInt();
        return ap;
    } else if (tname == "counter" || tname == "direct_counter") {
        auto ctr = new IR::Counter(srcInfo, name);
        for (auto anno : annot->annotations) {
            if (anno->name == "max_width")
                ctr->max_width = anno->expr.at(0)->as<IR::Constant>().asInt();
            else if (anno->name == "min_width")
                ctr->min_width = anno->expr.at(0)->as<IR::Constant>().asInt();
            else
                WARNING("unknown annotation " << anno->name << " on " << tname); }
        rv = ctr;
    } else if (tname == "meter" || tname == "direct_meter") {
        auto mtr = new IR::Meter(srcInfo, name);
        for (auto anno : annot->annotations) {
            if (anno->name == "result")
                mtr->result = anno->expr.at(0);
            else if (anno->name == "pre_color")
                mtr->pre_color = anno->expr.at(0);
            else if (anno->name == "implementation")
                mtr->implementation = anno->expr.at(0)->as<IR::StringLiteral>();
            else
                WARNING("unknown annotation " << anno->name << " on " << tname); }
        rv = mtr; }
    if (rv) {
        switch (args->size()) {
        case 1:
            rv->settype(args->at(0)->as<IR::Member>().member.name);
            rv->direct = true;
            break;
        case 2:
            rv->instance_count = args->at(0)->as<IR::Constant>().asInt();
            rv->settype(args->at(1)->as<IR::Member>().member.name);
            break;
        default:
            BUG("wrong number of arguments to %s ctor %s", tname, args);
            break; }
        return rv; }
    return nullptr;
}


namespace {
class FixP4Table : public Transform {
    const P4::ReferenceMap *refMap;
    IR::MAU::Table *tt;
    set<cstring> &unique_names;
    bool default_action_fix = false;

    const IR::P4Table *preorder(IR::P4Table *tc) override {
        tc->name = tc->externalName();
        visit(tc->properties);  // just visiting properties
        prune();
        return tc; }
    const IR::ExpressionValue *preorder(IR::ExpressionValue *ev) override {
        auto prop = findContext<IR::Property>();
        if (prop->name == "default_action") {
            default_action_fix = true;
            return ev;
        } else if (prop->name == "counters" || prop->name == "meters" ||
                   prop->name == "implementation") {
            auto pval = ev->expression;
            IR::Attached *obj = nullptr;
            if (auto cc = pval->to<IR::ConstructorCallExpression>()) {
                cstring tname = cc->type->toString();
                if (auto p = tname.find('<'))  // strip off type args (if any)
                    tname = tname.before(p);
                unique_names.insert(tname);   // don't use the type name directly
                tname = cstring::make_unique(unique_names, tname);
                unique_names.insert(tname);
                LOG1("Create at first point");
                obj = createV1Attached(tt, cc->srcInfo, prop->externalName(tname), cc->type,
                                       cc->arguments, prop->annotations);
            } else if (auto pe = pval->to<IR::PathExpression>()) {
                auto &d = refMap->getDeclaration(pe->path, true)->as<IR::Declaration_Instance>();
                LOG1("Create at second point");
                obj = createV1Attached(tt, d.srcInfo, d.externalName(), d.type,
                                       d.arguments, d.annotations); }
            BUG_CHECK(obj, "not valid for %s: %s", prop->name, pval);
            tt->attached.push_back(obj); }
        prune();
        return ev; }
    const IR::ExpressionValue *postorder(IR::ExpressionValue *ev) override {
        default_action_fix = false;
        return ev; }
    const IR::PathExpression *preorder(IR::PathExpression *pe) override {
        if (default_action_fix) {
            // need to change the default action name back to the extern name, rather than
            // whatever the frontend code rewrote it as.
            auto actName = refMap->getDeclaration(pe->path, true)->externalName();
            pe->path = new IR::Path(pe->path->srcInfo, actName); }
        prune();
        return pe; }
    const IR::Expression *preorder(IR::MethodCallExpression *mc) override {
        visit(mc->method);
        if (default_action_fix && mc->arguments->empty())
            return mc->method;
        prune();
        return mc; }
    const IR::Expression *preorder(IR::BAnd *exp) override {
        if (!getParent<IR::KeyElement>())
            return exp;
        if (exp->left->is<IR::Constant>())
            return new IR::Mask(exp->srcInfo, exp->type, exp->right, exp->left);
        if (exp->right->is<IR::Constant>())
            return new IR::Mask(exp->srcInfo, exp->type, exp->left, exp->right);
        error("%s: mask must have a constant operand to be used as a table key", exp->srcInfo);
        return exp; }

 public:
    FixP4Table(const P4::ReferenceMap *r, IR::MAU::Table *tt, set<cstring> &u)
    : refMap(r), tt(tt), unique_names(u) {}
};

class FindAttached : public Inspector {
    map<cstring, vector<const IR::Attached *>>    &attached;
    void postorder(const IR::Stateful *st) override {
        if (!contains(attached[st->table], st))
          attached[st->table].push_back(st); }
 public:
    explicit FindAttached(map<cstring, vector<const IR::Attached *>> &a) : attached(a) {}
};

struct AttachTables : public Modifier {
    const IR::V1Program                         *program = nullptr;
    map<cstring, vector<const IR::Attached *>>  attached;
    map<const IR::Declaration_Instance *, const IR::Attached *> converted;

    void postorder(IR::MAU::Table *tbl) override {
        if (attached.count(tbl->name))
            for (auto a : attached[tbl->name])
                if (!contains(tbl->attached, a))
                    tbl->attached.push_back(a); }
    void postorder(IR::GlobalRef *gref) override {
        if (program) return;
        if (auto di = gref->obj->to<IR::Declaration_Instance>()) {
            if (converted.count(di)) {
                gref->obj = converted.at(di);
            } else {
                LOG1("Create at this point");
                auto att = createV1Attached(nullptr, di->srcInfo, di->externalName(), di->type,
                                            di->arguments, di->annotations);
                if (att)
                    gref->obj = converted[di] = att; } } }
    void postorder(IR::Primitive *prim) override {
        if (prim->name != "count" && prim->name != "execute_meter")
            return;
        auto tt = findContext<IR::MAU::Table>();
        BUG_CHECK(tt, "%s primitive not in a table", prim);
        const IR::Attached *att = nullptr;
        if (auto gr = prim->operands.at(0)->to<IR::GlobalRef>())
            att = gr->obj->to<IR::Attached>();
        if (!att && program)
            att = program->get<IR::Attached>(prim->operands.at(0)->toString());
        if (att && !contains(attached[tt->name], att))
            attached[tt->name].push_back(att);
        /* various error check should be here */ }

    AttachTables() {}
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
    const IR::V1Program                         *program;
    P4::ReferenceMap                            *refMap;
    P4::TypeMap                                 *typeMap;
    gress_t                                     gress;
    IR::Tofino::Pipe                            *pipe;
    set<cstring>                                unique_names;
    map<const IR::Node *, IR::MAU::Table *>     tables;
    map<const IR::Node *, IR::MAU::TableSeq *>  seqs;
    IR::MAU::TableSeq *getseq(const IR::Node *n) {
        if (!seqs.count(n) && tables.count(n))
            seqs[n] = new IR::MAU::TableSeq(tables.at(n));
        return seqs.at(n); }

 public:
    GetTofinoTables(const IR::V1Program *prog, gress_t gr, IR::Tofino::Pipe *p)
    : program(prog), refMap(nullptr), typeMap(nullptr), gress(gr), pipe(p) {}
    GetTofinoTables(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                    gress_t gr, IR::Tofino::Pipe *p)
    : program(nullptr), refMap(refMap), typeMap(typeMap), gress(gr), pipe(p) {}

 private:
    void add_tt_action(IR::MAU::Table *tt, IR::ID name) {
        if (auto action = program->get<IR::ActionFunction>(name)) {
            if (!tt->actions.count(name)) {
                tt->actions.add(name, action);
            } else {
                error("%s: action %s appears multiple times in table %s",
                      name.srcInfo, name, tt->name); }
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
                              ->to<IR::ActionList>()->actionList) {
            if (auto action = refMap->getDeclaration(act->getPath())->to<IR::P4Action>()) {
                auto mce = act->expression->to<IR::MethodCallExpression>();
                auto newaction = createActionFunction(refMap, typeMap, action, mce->arguments);
                if (!tt->actions.count(newaction->name))
                    tt->actions.addUnique(newaction->name, newaction);
                else
                    error("%s: action %s appears multiple times in table %s", action->name.srcInfo,
                          action->name, tt->name); } }
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
            BUG("converting V1 tables not supported");
            auto tt = tables[a] = new IR::MAU::Table(a->name, gress /*, table*/);
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
                else if (name == "default")
                    name = "$default";
                else
                    error("%s: no action %s in table %s", a->srcInfo, name, tt->name); }
            tt->next[name] = getseq(act.second); } }
    bool preorder(const IR::MethodCallExpression *m) override {
        auto mi = P4::MethodInstance::resolve(m, refMap, typeMap, true);
        if (!mi || !mi->isApply())
            BUG("Method Call %1% not apply", m);
        auto table = mi->object->to<IR::P4Table>();
        if (!table) BUG("%1% not apllied to table", m);
        if (!tables.count(m)) {
            auto tt = tables[m] = new IR::MAU::Table(table->name, gress, table);
            tt->match_table = table =
                table->apply(FixP4Table(refMap, tt, unique_names))->to<IR::P4Table>();
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
        vector<cstring> fallthrough;
        for (auto c : s->cases) {
            cstring label;
            if (c->label->is<IR::DefaultExpression>())
                label = "$default";
            else
                label = refMap->getDeclaration(c->label->to<IR::PathExpression>()->path)
                              ->externalName();
            if (c->statement) {
                auto n = getseq(c->statement);
                tt->next[label] = n;
                for (auto ft : fallthrough)
                    tt->next[ft] = n;
                fallthrough.clear();
            } else {
                fallthrough.push_back(label); } } }
    bool preorder(const IR::NamedCond *c) override {
        if (!tables.count(c))
            tables[c] = new IR::MAU::Table(c->name, gress, c->pred);
        else
            BUG("duplicated unique name?");
        return true; }
    void postorder(const IR::NamedCond *c) override {
        if (c->ifTrue)
            tables.at(c)->next["$true"] = getseq(c->ifTrue);
        if (c->ifFalse)
            tables.at(c)->next["$false"] = getseq(c->ifFalse); }
    bool preorder(const IR::If *) override {
        BUG("unnamed condition in control flow"); }
    bool preorder(const IR::IfStatement *c) override {
        if (!isApplyHit(c->condition)) {
            static int uid = 0;
            char buf[16];
            snprintf(buf, sizeof(buf), "cond-%d", ++uid);
            tables[c] = new IR::MAU::Table(buf, gress, c->condition); }
        return true; }
    void postorder(const IR::IfStatement *c) override {
        bool lnot;
        cstring T = "$true", F = "$false";
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

const IR::Tofino::Pipe *extract_maupipe(const IR::V1Program *program, Tofino_Options &) {
    auto rv = new IR::Tofino::Pipe();
    rv->standard_metadata = program->get<IR::Metadata>("standard_metadata");
    auto parserInfo = Tofino::extractParser(program);
    auto ingress = program->get<IR::V1Control>(parserInfo.ingressEntryPoint);
    if (!ingress) ingress = new IR::V1Control(IR::ID("ingress"));
    ingress = ingress->apply(InlineControlFlow(program));
    ingress = ingress->apply(NameGateways());
    auto egress = program->get<IR::V1Control>("egress");
    if (!egress) egress = new IR::V1Control(IR::ID("egress"));
    egress = egress->apply(InlineControlFlow(program));
    egress = egress->apply(NameGateways());
    ingress->apply(GetTofinoTables(program, INGRESS, rv));
    egress->apply(GetTofinoTables(program, EGRESS, rv));
    if (auto in = rv->thread[INGRESS].parser = parserInfo.parser(INGRESS))
        rv->thread[INGRESS].deparser = new IR::Tofino::Deparser(INGRESS, in);
    if (auto eg = rv->thread[EGRESS].parser = parserInfo.parser(EGRESS))
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

const IR::Tofino::Pipe *extract_maupipe(const IR::P4Program *program, Tofino_Options &options) {
    P4::ReferenceMap  refMap;
    P4::TypeMap       typeMap;
    refMap.setIsV1(options.isv1());
    P4::EvaluatorPass evaluator(&refMap, &typeMap);
    program = program->apply(evaluator);
    auto toplevel = evaluator.getToplevelBlock();
    auto top = toplevel->getMain();
    if (!top) {
        error("No main switch");
        return nullptr; }

    auto parser_blk = top->getParameterValue("p");
    auto parser = parser_blk->to<IR::ParserBlock>()->container;
    auto ingress_blk = top->getParameterValue("ig");
    auto ingress = ingress_blk->to<IR::ControlBlock>()->container;
    auto egress_blk = top->getParameterValue("eg");
    auto egress = egress_blk->to<IR::ControlBlock>()->container;
    auto deparser_blk = top->getParameterValue("dep");
    auto deparser = deparser_blk->to<IR::ControlBlock>()->container;
    LOG1("parser:" << parser);
    LOG1("ingress:" << ingress);
    LOG1("egress:" << egress);
    LOG1("deparser:" << deparser);
    // FIXME add consistency/sanity checks to make sure arch is well-formed.

    auto rv = new IR::Tofino::Pipe();

    ParamBinding bindings(&refMap, &typeMap);

    for (auto param : *parser->type->applyParams->getEnumerator())
        bindings.bind(param);
    for (auto param : *ingress->type->applyParams->getEnumerator())
        bindings.bind(param);
    for (auto param : *egress->type->applyParams->getEnumerator())
        bindings.bind(param);
    for (auto param : *deparser->type->applyParams->getEnumerator())
        bindings.bind(param);

    auto it = ingress->type->applyParams->parameters->rbegin();
    rv->standard_metadata =
        bindings.get(*it)->obj->to<IR::Metadata>();
    PassManager fixups = {
        &bindings,
        new SplitComplexInstanceRef,
        new RemoveInstanceRef,
        new ConvertIndexToHeaderStackItemRef,
        new RewriteForTofino,
    };
    parser = parser->apply(fixups);
    ingress = ingress->apply(fixups);
    egress = egress->apply(fixups);
    deparser = deparser->apply(fixups);

    auto parserInfo = Tofino::extractParser(&parser->as<IR::P4Parser>());
    if (auto in = rv->thread[INGRESS].parser = parserInfo.parser(INGRESS))
        rv->thread[INGRESS].deparser = new IR::Tofino::Deparser(INGRESS, in);
    if (auto eg = rv->thread[EGRESS].parser = parserInfo.parser(EGRESS))
        rv->thread[EGRESS].deparser = new IR::Tofino::Deparser(EGRESS, eg);
    // FIXME -- use the deparser rather than always inferring it from the parser

    // ingress = ingress->apply(InlineControlFlow(blockMap));
    ingress->apply(GetTofinoTables(&refMap, &typeMap, INGRESS, rv));
    // egress = egress->apply(InlineControlFlow(blockMap));
    egress->apply(GetTofinoTables(&refMap, &typeMap, EGRESS, rv));

    // AttachTables...
    AttachTables toAttach;
    for (auto &th : rv->thread)
        th.mau = th.mau->apply(toAttach);

    return rv->apply(fixups);
}
