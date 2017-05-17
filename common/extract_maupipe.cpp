#include <assert.h>
#include "ir/ir.h"
#include "ir/dbprint.h"
#include "frontends/p4-14/inline_control_flow.h"
#include "common/name_gateways.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/methodInstance.h"
#include "tofino/common/param_binding.h"
#include "tofino/mau/stateful_alu.h"
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
    IR::MAU::Action         *af;
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
    ActionBodySetup(P4::ReferenceMap *refMap, P4::TypeMap *typeMap, IR::MAU::Action *af,
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
    auto prim = new IR::Primitive(mc->srcInfo, mc->methodCall->type, name);
    if (recv) prim->operands.push_back(recv);
    for (auto arg : *mc->methodCall->arguments)
        prim->operands.push_back(arg);
    af->action.push_back(prim->apply(setup));
    return false;
}

}  // anonymous namespace

static IR::MAU::Action *createActionFunction(P4::ReferenceMap *refMap, P4::TypeMap *typeMap,
                                             const IR::P4Action *ac,
                                             const IR::Vector<IR::Expression> *args) {
    auto rv = new IR::MAU::Action;
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

static IR::Attached *createAttached(IR::MAU::Table *tt, Util::SourceInfo srcInfo, cstring name,
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
        auto sel = new IR::ActionSelector(srcInfo, name, annot);
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
        if (tt)
            tt->attached.push_back(ap);
        return sel;
    } else if (tname == "action_profile") {
        auto ap = new IR::ActionProfile(srcInfo, name);
        ap->size = args->at(0)->as<IR::Constant>().asInt();
        return ap;
    } else if (tname == "counter" || tname == "direct_counter") {
        auto ctr = new IR::Counter(srcInfo, name, annot);
        for (auto anno : annot->annotations) {
            if (anno->name == "max_width")
                ctr->max_width = anno->expr.at(0)->as<IR::Constant>().asInt();
            else if (anno->name == "min_width")
                ctr->min_width = anno->expr.at(0)->as<IR::Constant>().asInt();
            else
                WARNING("unknown annotation " << anno->name << " on " << tname); }
        rv = ctr;
    } else if (tname == "meter" || tname == "direct_meter") {
        auto mtr = new IR::Meter(srcInfo, name, annot);
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
    LOG2("Failed to create attached table for " << type->toString());
    return nullptr;
}

static void updateAttachedSalu(const Util::SourceInfo &loc, const P4::ReferenceMap *refMap,
                               IR::MAU::StatefulAlu *&salu, const IR::Declaration_Instance *ext,
                               cstring action) {
    BUG_CHECK(ext->type->toString() == "stateful_alu", "%s is not a stateful alu", ext);
    auto regprop = ext->properties["reg"];
    if (!regprop) {
        error("%s: no reg property in stateful_alu %s", ext->srcInfo, ext->name);
        return; }
    auto rpv = regprop->value->to<IR::ExpressionValue>();
    auto pe = rpv ? rpv->expression->to<IR::PathExpression>() : nullptr;
    auto d = pe ? refMap->getDeclaration(pe->path, true) : nullptr;
    auto reg = d ? d->to<IR::Declaration_Instance>() : nullptr;
    auto regtype = reg ? reg->type->to<IR::Type_Specialized>() : nullptr;
    if (!regtype || regtype->baseType->toString() != "register") {
        error("%s: reg is not a register", regprop->srcInfo);
        return; }
    if (!salu) {
        LOG3("Creating new StatefulAlu for " << regtype->toString() << " " << reg->name);
        salu = new IR::MAU::StatefulAlu(reg->srcInfo, reg->externalName(), reg->annotations, reg);
        if (auto size = reg->arguments->at(0)->to<IR::Constant>()->asInt()) {
            salu->direct = false;
            salu->instance_count = size;
        } else {
            salu->direct = true; }
        salu->width = regtype->arguments->at(0)->width_bits();
    } else if (salu->reg != reg) {
        error("%s: stateful_alu blocks in the same table must use the same underlying regster,"
              "trying to use %s", salu->srcInfo, reg); }
    LOG3("Adding " << ext->name << " to StatefulAlu " << reg->name);
    ext->apply(CreateSaluInstruction(salu));
    if (!salu->action_map.emplace(action, ext->name).second)
        error("%s: multiple calls to execute_stateful_alu in action %s", loc, action);
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
            // counters: direct counters
            // meters: direct meters
            // implementation: action profile and action selector
            auto pval = ev->expression;
            IR::Attached *obj = nullptr;
            if (auto cc = pval->to<IR::ConstructorCallExpression>()) {
                cstring tname = cc->type->toString();
                if (auto p = tname.find('<'))  // strip off type args (if any)
                    tname = tname.before(p);
                unique_names.insert(tname);   // don't use the type name directly
                tname = cstring::make_unique(unique_names, tname);
                unique_names.insert(tname);
                obj = createAttached(tt, cc->srcInfo, prop->externalName(tname), cc->type,
                                     cc->arguments, prop->annotations);
                LOG3("Created " << obj->node_type_name() << ' ' << obj->name << " (pt 1)");
            } else if (auto pe = pval->to<IR::PathExpression>()) {
                auto &d = refMap->getDeclaration(pe->path, true)->as<IR::Declaration_Instance>();
                obj = createAttached(tt, d.srcInfo, d.externalName(), d.type,
                                     d.arguments, d.annotations);
                LOG3("Created " << obj->node_type_name() << ' ' << obj->name << " (pt 2)"); }
            BUG_CHECK(obj, "not valid for %s: %s", prop->name, pval);
            LOG3("attaching " << obj->name << " to " << tt->name);
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

struct AttachTables : public Modifier {
    const P4::ReferenceMap                      *refMap;
    map<cstring, vector<const IR::Attached *>>  attached;
    map<cstring, IR::MAU::StatefulAlu *>        salu;
    map<const IR::Declaration_Instance *, const IR::Attached *> converted;

    void postorder(IR::MAU::Table *tbl) override {
        if (attached.count(tbl->name))
            for (auto a : attached[tbl->name]) {
                if (contains(tbl->attached, a)) {
                    LOG3(a->name << " already attached to " << tbl->name);
                } else {
                    LOG3("attaching " << a->name << " to " << tbl->name);
                    tbl->attached.push_back(a); } }
        if (salu.count(tbl->name)) {
            BUG_CHECK(!contains(tbl->attached, salu.at(tbl->name)), "salu already attached?");
            LOG3("attaching " << salu.at(tbl->name)->name << " to " << tbl->name);
            tbl->attached.push_back(salu.at(tbl->name)); } }
    void postorder(IR::GlobalRef *gref) override {
        if (auto di = gref->obj->to<IR::Declaration_Instance>()) {
            auto tt = findContext<IR::MAU::Table>();
            BUG_CHECK(tt, "GlobalRef not in a table");
            for (auto att : tt->attached) {
                if (att->name == di->name) {
                    gref->obj = converted[di] = att;
                    break; } }
            if (converted.count(di)) {
                gref->obj = converted.at(di);
                if (!contains(attached[tt->name], converted.at(di)))
                    attached[tt->name].push_back(converted.at(di));
            } else if (auto att = createAttached(nullptr, di->srcInfo, di->externalName(),
                                                 di->type, di->arguments, di->annotations)) {
                LOG3("Created " << att->node_type_name() << ' ' << att->name << " (pt 3)");
                gref->obj = converted[di] = att;
                attached[tt->name].push_back(att);
            } else if (di->type->toString() == "stateful_alu") {
                auto act = findContext<IR::MAU::Action>();
                updateAttachedSalu(gref->srcInfo, refMap, salu[tt->name], di, act->name);
                gref->obj = converted[di] = salu[tt->name]; } } }
    explicit AttachTables(const P4::ReferenceMap *refMap) : refMap(refMap) {}
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
    GetTofinoTables(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                    gress_t gr, IR::Tofino::Pipe *p)
    : refMap(refMap), typeMap(typeMap), gress(gr), pipe(p) {}

 private:
    void setup_tt_actions(IR::MAU::Table *tt, const IR::P4Table *table) {
        for (auto act : table->properties->getProperty("actions")->value
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
        for (auto el : b->components)
            if (tables.count(el))
                seqs.at(b)->tables.push_back(tables.at(el)); }
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

    auto it = ingress->type->applyParams->parameters.rbegin();
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
    auto in_parser = rv->thread[INGRESS].parser = parserInfo.parser(INGRESS);
    if (deparser)
        rv->thread[INGRESS].deparser = new IR::Tofino::Deparser(INGRESS, deparser);
    else if (in_parser)
        rv->thread[INGRESS].deparser = new IR::Tofino::Deparser(INGRESS, in_parser);
    auto eg_parser = rv->thread[EGRESS].parser = parserInfo.parser(EGRESS);
    if (deparser)
        rv->thread[EGRESS].deparser = new IR::Tofino::Deparser(EGRESS, deparser);
    else if (eg_parser)
        rv->thread[EGRESS].deparser = new IR::Tofino::Deparser(EGRESS, eg_parser);

    // ingress = ingress->apply(InlineControlFlow(blockMap));
    ingress->apply(GetTofinoTables(&refMap, &typeMap, INGRESS, rv));
    // egress = egress->apply(InlineControlFlow(blockMap));
    egress->apply(GetTofinoTables(&refMap, &typeMap, EGRESS, rv));

    // AttachTables...
    AttachTables toAttach(&refMap);
    for (auto &th : rv->thread)
        th.mau = th.mau->apply(toAttach);

    return rv->apply(fixups);
}
