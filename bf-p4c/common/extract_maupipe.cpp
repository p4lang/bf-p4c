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
#include "tofino/parde/checksum.h"
#include "tofino/parde/extract_parser.h"
#include "tofino/parde/phase0.h"
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

    const IR::Primitive *cvtMethodCall(const IR::MethodCallExpression *mc);
    bool preorder(const IR::IndexedVector<IR::StatOrDecl> *) override { return true; }
    bool preorder(const IR::BlockStatement *) override { return true; }
    bool preorder(const IR::AssignmentStatement *assign) override {
        cstring pname = "modify_field";
        if (assign->left->type->is<IR::Type_Header>())
            pname = "copy_header";
        auto right = assign->right;
        if (auto cast = right->to<IR::Cast>())
            right = cast->expr;
        if (auto mc = right->to<IR::MethodCallExpression>())
            right = cvtMethodCall(mc);
        auto prim = new IR::Primitive(assign->srcInfo, pname, assign->left, right);
        af->action.push_back(prim->apply(setup));
        return false; }
    bool preorder(const IR::MethodCallStatement *mc) override {
        af->action.push_back(cvtMethodCall(mc->methodCall)->apply(setup));
        return false; }
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

const IR::Primitive *ActionBodySetup::cvtMethodCall(const IR::MethodCallExpression *mc) {
    auto mi = P4::MethodInstance::resolve(mc, refMap, typeMap, true);
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
    auto prim = new IR::Primitive(mc->srcInfo, mc->type, name);
    if (mc->method && mc->method->type)
        prim = new IR::MAU::TypedPrimitive(mc->srcInfo, mc->type, mc->method->type, name);
    if (recv) prim->operands.push_back(recv);
    for (auto arg : *mc->arguments)
        prim->operands.push_back(arg);
    return prim;
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
                                    const IR::Annotations *annot,
                                    map<cstring, IR::ActionProfile *> *shared_ap,
                                    map<cstring, IR::ActionSelector *> *shared_as) {
    IR::CounterOrMeter *rv = nullptr;
    // FIXME -- this should be looking at the arch model, but the current arch model stuff
    // is too complex -- need a way of building this automatically from the arch.p4 file.
    // For now, hack just using the type name as a string.
    cstring tname = type->toString();
    if (auto p = tname.find('<'))  // strip off type args (if any)
        tname = tname.before(p);
    if (tname == "action_selector") {
        if (shared_as == nullptr || shared_ap == nullptr)
            BUG("Action Selector %s used in an impossible manner", name);
        if (shared_as->find(name) != shared_as->end()) {
            if (shared_ap->find(name) == shared_ap->end())
                BUG("Shared Action Selector with no corresponding Action Profile");
            if (tt)
                 tt->attached.push_back(shared_ap->at(name));
            return shared_as->at(name);
        }
        auto sel = new IR::ActionSelector(srcInfo, name, annot);
        sel->mode = getAnnotID(annot, "mode");
        sel->type = getAnnotID(annot, "type");
        auto ap = new IR::ActionProfile(srcInfo, name);
        ap->size = args->at(1)->as<IR::Constant>().asInt();
        ap->selector = name;
        // FIXME Need to reconstruct the field list from the table key?
        (*shared_ap)[name] = ap;
        (*shared_as)[name] = sel;
        if (tt)
            tt->attached.push_back(ap);
        return sel;
    } else if (tname == "action_profile") {
        if (shared_as == nullptr || shared_ap == nullptr)
            BUG("Action Profile %s used in an impossible manner", name);
        if (shared_ap->find(name) != shared_ap->end()) {
            return shared_ap->at(name);
        }
        auto ap = new IR::ActionProfile(srcInfo, name);
        ap->size = args->at(0)->as<IR::Constant>().asInt();
        (*shared_ap)[name] = ap;
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
    auto reg_arg = ext->arguments->size() > 0 ? ext->arguments->at(0) : nullptr;
    if (!reg_arg) {
        if (auto regprop = ext->properties["reg"]) {
            if (auto rpv = regprop->value->to<IR::ExpressionValue>())
                reg_arg = rpv->expression;
            else
                BUG("reg property %s is not an ExpressionValue", regprop);
        } else {
            error("%s: no reg property in stateful_alu %s", ext->srcInfo, ext->name);
            return; } }
    auto pe = reg_arg->to<IR::PathExpression>();
    auto d = pe ? refMap->getDeclaration(pe->path, true) : nullptr;
    auto reg = d ? d->to<IR::Declaration_Instance>() : nullptr;
    auto regtype = reg ? reg->type->to<IR::Type_Specialized>() : nullptr;
    if (!regtype || regtype->baseType->toString() != "register") {
        error("%s: reg is not a register", reg_arg->srcInfo);
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
        error("%s: register actions in the same table must use the same underlying regster,"
              "trying to use %s", salu->srcInfo, reg); }
    LOG3("Adding " << ext->name << " to StatefulAlu " << reg->name);
    ext->apply(CreateSaluInstruction(salu));
    if (!salu->action_map.emplace(action, ext->name).second)
        error("%s: multiple calls to execute in action %s", loc, action);
}

namespace {
class FixP4Table : public Transform {
    const P4::ReferenceMap *refMap;
    IR::MAU::Table *tt;
    set<cstring> &unique_names;
    map<cstring, IR::ActionProfile *> *shared_ap;
    map<cstring, IR::ActionSelector *> *shared_as;
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
                                     cc->arguments, prop->annotations, shared_ap, shared_as);
                LOG3("Created " << obj->node_type_name() << ' ' << obj->name << " (pt 1)");
            } else if (auto pe = pval->to<IR::PathExpression>()) {
                auto &d = refMap->getDeclaration(pe->path, true)->as<IR::Declaration_Instance>();
                obj = createAttached(tt, d.srcInfo, d.externalName(), d.type,
                                     d.arguments, d.annotations, shared_ap, shared_as);
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
    FixP4Table(const P4::ReferenceMap *r, IR::MAU::Table *tt, set<cstring> &u,
               map<cstring, IR::ActionProfile *> *ap, map<cstring, IR::ActionSelector *> *as)
    : refMap(r), tt(tt), unique_names(u), shared_ap(ap), shared_as(as) {}
};

struct AttachTables : public Modifier {
    const P4::ReferenceMap                      *refMap;
    map<cstring, vector<const IR::Attached *>>  attached;
    map<cstring, IR::MAU::StatefulAlu *>        salu;
    map<const IR::Declaration_Instance *, const IR::Attached *> converted;


    void postorder(IR::MAU::Table *tbl) override {
        if (attached.count(tbl->name)) {
            for (auto a : attached[tbl->name]) {
                if (contains(tbl->attached, a)) {
                    LOG3(a->name << " already attached to " << tbl->name);
                } else {
                    LOG3("attaching " << a->name << " to " << tbl->name);
                    tbl->attached.push_back(a); } } }
        if (salu.count(tbl->name)) {
            BUG_CHECK(!contains(tbl->attached, salu.at(tbl->name)), "salu already attached?");
            LOG3("attaching " << salu.at(tbl->name)->name << " to " << tbl->name);
            tbl->attached.push_back(salu.at(tbl->name)); } }
    void postorder(IR::GlobalRef *gref) override {
        if (auto di = gref->obj->to<IR::Declaration_Instance>()) {
            auto tt = findContext<IR::MAU::Table>();
            cstring tname;
            BUG_CHECK(tt, "GlobalRef not in a table");
            for (auto att : tt->attached) {
                if (att->name == di->externalName()) {
                    gref->obj = converted[di] = att;
                    break; } }
            if (converted.count(di)) {
                gref->obj = converted.at(di);
                if (!contains(attached[tt->name], converted.at(di)))
                    attached[tt->name].push_back(converted.at(di));
            } else if (auto att = createAttached(nullptr, di->srcInfo, di->externalName(),
                                                 di->type, di->arguments, di->annotations,
                                                 nullptr, nullptr)) {
                LOG3("Created " << att->node_type_name() << ' ' << att->name << " (pt 3)");
                gref->obj = converted[di] = att;
                attached[tt->name].push_back(att);
            } else if ((tname = di->type->toString()) == "stateful_alu_14" ||
                       tname.startsWith("register_action<") ||
                       tname.startsWith("stateful_alu<")) {
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
    map<cstring, IR::ActionProfile *> shared_ap;
    map<cstring, IR::ActionSelector *> shared_as;
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
            auto tt = tables[m] =
                new IR::MAU::Table(cstring::make_unique(unique_names, table->name), gress, table);
            unique_names.insert(tt->name);
            tt->match_table = table =
                table->apply(FixP4Table(refMap, tt, unique_names,
                                        &shared_ap, &shared_as))->to<IR::P4Table>();
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
        return new IR::HeaderStackItemRef(idx->srcInfo, type, idx->left, idx->right);
    }
    const IR::Expression* preorder(IR::Member* member) override {
        auto type = member->type->to<IR::Type_Header>();
        if (!type) return member;
        if (member->member == "next")
            return new IR::HeaderStackItemRef(member->srcInfo, type, member->expr,
                                              new IR::Tofino::UnresolvedStackNext);
        if (member->member == "last")
            return new IR::HeaderStackItemRef(member->srcInfo, type, member->expr,
                                              new IR::Tofino::UnresolvedStackLast);
        return member;
    }
};

const IR::Tofino::Pipe* extract_v1model_arch(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                                             const IR::PackageBlock* top) {
    auto parser_blk = top->getParameterValue("p");
    auto parser = parser_blk->to<IR::ParserBlock>()->container;
    auto verify_checksum_blk = top->findParameterValue("vr");
    auto verify_checksum = verify_checksum_blk
                         ? verify_checksum_blk->to<IR::ControlBlock>()->container
                         : nullptr;
    auto ingress_blk = top->getParameterValue("ig");
    auto ingress = ingress_blk->to<IR::ControlBlock>()->container;
    auto egress_blk = top->getParameterValue("eg");
    auto egress = egress_blk->to<IR::ControlBlock>()->container;
    auto compute_checksum_blk = top->findParameterValue("ck");
    auto compute_checksum = compute_checksum_blk
                          ? compute_checksum_blk->to<IR::ControlBlock>()->container
                          : nullptr;
    auto deparser_blk = top->getParameterValue("dep");
    auto deparser = deparser_blk->to<IR::ControlBlock>()->container;

    LOG1("parser: " << parser);
    LOG1("verify checksum: " << verify_checksum);
    LOG1("ingress: " << ingress);
    LOG1("egress: " << egress);
    LOG1("compute checksum: " << compute_checksum);
    LOG1("deparser: " << deparser);
    // FIXME add consistency/sanity checks to make sure arch is well-formed.

    auto rv = new IR::Tofino::Pipe();

    ParamBinding bindings(refMap, typeMap);

    for (auto param : *parser->type->applyParams->getEnumerator())
        bindings.bind(param);
    if (verify_checksum) {
        for (auto param : *verify_checksum->type->applyParams->getEnumerator())
            bindings.bind(param);
    }
    for (auto param : *ingress->type->applyParams->getEnumerator())
        bindings.bind(param);
    for (auto param : *egress->type->applyParams->getEnumerator())
        bindings.bind(param);
    if (compute_checksum) {
        for (auto param : *compute_checksum->type->applyParams->getEnumerator())
            bindings.bind(param);
    }
    for (auto param : *deparser->type->applyParams->getEnumerator())
        bindings.bind(param);
    auto it = ingress->type->applyParams->parameters.rbegin();
    // hanw: all map to standard_metadata
    rv->metadata.addUnique("standard_metadata",
                           bindings.get(*it)->obj->to<IR::Metadata>());

    PassManager fixups = {
        &bindings,
        new SplitComplexInstanceRef,
        new RemoveInstanceRef,
        new ConvertIndexToHeaderStackItemRef,
        new RewriteForTofino(refMap, typeMap),
    };

    parser = parser->apply(fixups);
    if (verify_checksum)
        verify_checksum = verify_checksum->apply(fixups);
    if (compute_checksum)
        compute_checksum = compute_checksum->apply(fixups);
    deparser = deparser->apply(fixups);

    auto parserInfo = Tofino::extractParser(rv, parser, deparser);
    for (auto gress : { INGRESS, EGRESS }) {
        rv->thread[gress].parser = parserInfo.parsers[gress];
        rv->thread[gress].deparser = parserInfo.deparsers[gress];
    }

    // Check for a phase 0 table. If one exists, it'll be removed from the
    // ingress pipeline and converted to a parser program.
    // XXX(seth): We should be able to move this into the midend now.
    std::tie(ingress, rv) = Tofino::extractPhase0(ingress, rv, refMap, typeMap);

    // Convert the contents of the ComputeChecksum control, if any, into
    // deparser primitives.
    rv = Tofino::extractComputeChecksum(compute_checksum, rv);

    ingress = ingress->apply(fixups);
    egress = egress->apply(fixups);

    // ingress = ingress->apply(InlineControlFlow(blockMap));
    ingress->apply(GetTofinoTables(refMap, typeMap, INGRESS, rv));
    // egress = egress->apply(InlineControlFlow(blockMap));
    egress->apply(GetTofinoTables(refMap, typeMap, EGRESS, rv));

    // AttachTables...
    AttachTables toAttach(refMap);
    for (auto &th : rv->thread)
        th.mau = th.mau->apply(toAttach);

    return rv->apply(fixups);
}

const IR::Tofino::Pipe* extract_native_arch(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                                            const IR::PackageBlock* top) {
    auto ingress_parser_blk = top->getParameterValue("ingress_parser");
    auto ingress_parser = ingress_parser_blk->to<IR::ParserBlock>()->container;
    auto ingress_blk = top->getParameterValue("ingress");
    auto ingress = ingress_blk->to<IR::ControlBlock>()->container;
    auto ingress_deparser_blk = top->getParameterValue("ingress_deparser");
    auto ingress_deparser = ingress_deparser_blk->to<IR::ControlBlock>()->container;
    auto egress_parser_blk = top->getParameterValue("egress_parser");
    auto egress_parser = egress_parser_blk->to<IR::ParserBlock>()->container;
    auto egress_blk = top->getParameterValue("egress");
    auto egress = egress_blk->to<IR::ControlBlock>()->container;
    auto egress_deparser_blk = top->getParameterValue("egress_deparser");
    auto egress_deparser = egress_deparser_blk->to<IR::ControlBlock>()->container;

    LOG1("in_parser:" << ingress_parser);
    LOG1("ingress:" << ingress);
    LOG1("in_deparser:" << ingress_deparser);
    LOG1("eg_parser:" << egress_parser);
    LOG1("egress:" << egress);
    LOG1("eg_deparser:" << egress_deparser);

    auto rv = new IR::Tofino::Pipe();

    ParamBinding bindings(refMap, typeMap);
    for (auto param : *ingress_parser->type->applyParams->getEnumerator())
        bindings.bind(param);
    for (auto param : *ingress->type->applyParams->getEnumerator())
        bindings.bind(param);
    for (auto param : *ingress_deparser->type->applyParams->getEnumerator())
        bindings.bind(param);
    for (auto param : *egress_parser->type->applyParams->getEnumerator())
        bindings.bind(param);
    for (auto param : *egress->type->applyParams->getEnumerator())
        bindings.bind(param);
    for (auto param : *egress_deparser->type->applyParams->getEnumerator())
        bindings.bind(param);

    // ingress_input_metadata at position 1
    auto it = ingress->type->applyParams->parameters.at(1);
    rv->metadata.addUnique("ingress_in_metadata",
                           bindings.get(it)->obj->to<IR::Metadata>());

    // ingress_output_metadata at position 2
    it = ingress->type->applyParams->parameters.at(2);
    rv->metadata.addUnique("ingress_out_metadata",
                           bindings.get(it)->obj->to<IR::Metadata>());

    // egress_input_metadata at position 1
    it = egress->type->applyParams->parameters.at(1);
    rv->metadata.addUnique("egress_in_metadata",
                           bindings.get(it)->obj->to<IR::Metadata>());

    // egress_output_metadata at position 2
    it = egress->type->applyParams->parameters.at(2);
    rv->metadata.addUnique("egress_out_metadata",
                           bindings.get(it)->obj->to<IR::Metadata>());

    PassManager fixups = {
        &bindings,
        new SplitComplexInstanceRef,
        new RemoveInstanceRef,
        new ConvertIndexToHeaderStackItemRef,
        new RewriteForTofino(refMap, typeMap),
    };
    ingress_parser = ingress_parser->apply(fixups);
    ingress = ingress->apply(fixups);
    ingress_deparser = ingress_deparser->apply(fixups);
    egress_parser = egress_parser->apply(fixups);
    egress = egress->apply(fixups);
    egress_deparser = egress_deparser->apply(fixups);

    auto parserInfo = Tofino::extractParser(rv, ingress_parser, ingress_deparser,
                                                egress_parser, egress_deparser);
    for (auto gress : { INGRESS, EGRESS }) {
        rv->thread[gress].parser = parserInfo.parsers[gress];
        rv->thread[gress].deparser = parserInfo.deparsers[gress];
    }

    ingress->apply(GetTofinoTables(refMap, typeMap, INGRESS, rv));
    egress->apply(GetTofinoTables(refMap, typeMap, EGRESS, rv));

    AttachTables toAttach(refMap);
    for (auto &th : rv->thread)
        th.mau = th.mau->apply(toAttach);

    return rv->apply(fixups);
}

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

    if (options.target == "tofino-v1model-barefoot" && !options.native_arch) {
        return extract_v1model_arch(&refMap, &typeMap, top);
    }
    if (options.target == "tofino-native-barefoot" || options.native_arch) {
        return extract_native_arch(&refMap, &typeMap, top);
    }
    error("Unknown architecture %s", options.target);
    return nullptr;
}
