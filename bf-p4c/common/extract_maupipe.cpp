#include "extract_maupipe.h"
#include <assert.h>
#include "slice.h"
#include "ir/ir.h"
#include "ir/dbprint.h"
#include "common/name_gateways.h"
#include "frontends/p4-14/inline_control_flow.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/methodInstance.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/common/copy_header_eliminator.h"
#include "bf-p4c/common/param_binding.h"
#include "bf-p4c/common/simplify_references.h"
#include "bf-p4c/mau/stateful_alu.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/parde/checksum.h"
#include "bf-p4c/parde/extract_parser.h"
#include "bf-p4c/parde/phase0.h"
#include "bf-p4c/parde/resubmit.h"
#include "lib/algorithm.h"
#include "lib/error.h"
#include "lib/safe_vector.h"

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

class ConvertMethodCall : public Transform {
    P4::ReferenceMap        *refMap;
    P4::TypeMap             *typeMap;

    const IR::Primitive *preorder(IR::MethodCallExpression *mc) {
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

    const IR::Primitive *postorder(IR::Primitive *prim) {
        if (prim->name == "method_call_init") {
            BUG_CHECK(prim->operands.size() == 1, "method call initialization failed");
            auto first_operand = prim->operands[0];
            BUG_CHECK(first_operand->is<IR::Primitive>(), "method call initialization mismatch");
            return first_operand->to<IR::Primitive>();
        } else {
            return prim;
        }
    }

 public:
    ConvertMethodCall(P4::ReferenceMap *rm, P4::TypeMap *tm) : refMap(rm), typeMap(tm) {}
};

/** Initial conversion of P4-16 action information to backend structures.  Converts all method
 *  calls to primitive calls with operands, and also converts all parameters within an action
 *  into IR::ActionArgs
 */
class ActionFunctionSetup : public PassManager {
    P4::ReferenceMap        *refMap;
    P4::TypeMap             *typeMap;
    ActionArgSetup          *action_arg_setup;

 public:
    ActionFunctionSetup(P4::ReferenceMap *rm, P4::TypeMap *tm, ActionArgSetup *aas) :
    refMap(rm), typeMap(tm), action_arg_setup(aas) {
        addPasses({
            new ConvertMethodCall(refMap, typeMap),
            action_arg_setup
        });
        stop_on_error = false;
    }
};

/** The purpose of this pass is to initialize each IR::MAU::Action with information on whether
 *  or not the action can be used as a default action, or if specifically it is meant only for the
 *  default action.  This information must be passed back directly to the context JSON.
 */
class DefaultActionInit : public Modifier {
    const IR::P4Table *table;
    const IR::ActionListElement *elem;

    bool preorder(IR::MAU::Action *act) override {
        auto prop = table->properties->getProperty(IR::TableProperties::defaultActionPropertyName);
        if (prop == nullptr) {
            error("%s: This table has no default action defined, and cannot be understood by "
                  " the backend compiler", table->srcInfo, table->externalName());
            return false;
        }

        auto default_action = table->getDefaultAction();
        if (!default_action)
            return false;
        const IR::Vector<IR::Expression> *args = nullptr;
        if (auto mc = default_action->to<IR::MethodCallExpression>()) {
            default_action = mc->method;
            args = mc->arguments;
        }
        // Indicates that this action is to be used only as a miss
        auto def_only_annot = elem->annotations->getSingle("default_only");

        auto path = default_action->to<IR::PathExpression>();
        if (!path)
            BUG("Default action path %s cannot be found", default_action);
        if (path->path->name == act->name) {
            if (def_only_annot)
                act->miss_action_only = true;
            act->init_default = true;
            if (args)
                act->default_params = *args;
        } else {
            if (def_only_annot)
                error("%s: Action %s is marked as default only, but is not the default action",
                      elem->srcInfo, elem);
            // Default action is marked constant, and cannot be changed by the runtime
            if (prop->isConstant) {
                act->disallowed_reason = "has_const_default";
                return false; }
        }
        act->default_allowed = true;
        return false;
    }

 public:
    DefaultActionInit(const IR::P4Table *t, const IR::ActionListElement *ale)
        : table(t), elem(ale) {}
};

class ActionBodySetup : public Inspector {
    IR::MAU::Action         *af;

    bool preorder(const IR::IndexedVector<IR::StatOrDecl> *) override { return true; }
    bool preorder(const IR::BlockStatement *) override { return true; }
    bool preorder(const IR::AssignmentStatement *assign) override {
        cstring pname = "modify_field";
        if (assign->left->type->is<IR::Type_Header>())
            pname = "copy_header";
        auto prim = new IR::Primitive(assign->srcInfo, pname, assign->left, assign->right);
        af->action.push_back(prim);
        return false; }
    bool preorder(const IR::MethodCallStatement *mc) override {
        auto mc_init = new IR::Primitive(mc->srcInfo, "method_call_init", mc->methodCall);
        af->action.push_back(mc_init);
        return false;
    }
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
    explicit ActionBodySetup(IR::MAU::Action *af) : af(af) {}
};

}  // anonymous namespace

static const IR::MAU::Action *createActionFunction(P4::ReferenceMap *refMap, P4::TypeMap *typeMap,
    const IR::P4Action *ac, const IR::Vector<IR::Expression> *args) {
    auto rv = new IR::MAU::Action;
    rv->srcInfo = ac->srcInfo;
    rv->name = ac->externalName();
    ActionArgSetup aas;
    size_t arg_idx = 0;
    for (auto param : *ac->parameters->getEnumerator()) {
        if ((param->direction == IR::Direction::None) ||
            ((!args || arg_idx >= args->size()) && param->direction == IR::Direction::In)) {
            auto arg = new IR::ActionArg(param->srcInfo, param->type, rv->name, param->name);
            aas.add_arg(arg);
            rv->args.push_back(arg);
        } else {
            if (!args || arg_idx >= args->size())
                error("%s: Not enough args for %s", args ? args->srcInfo : ac->srcInfo, ac);
            else
                aas.add_arg(param->name, args->at(arg_idx++)); } }
    if (arg_idx != (args ? args->size(): 0))
        error("%s: Too many args for %s", args->srcInfo, ac);
    ac->body->apply(ActionBodySetup(rv));
    ActionFunctionSetup afs(refMap, typeMap, &aas);
    return rv->apply(afs)->to<IR::MAU::Action>();
}

static IR::ID getAnnotID(const IR::Annotations *annot, cstring name) {
    if (auto a = annot->getSingle(name))
        if (a->expr.size() == 1)
            if (auto str = a->expr.at(0)->to<IR::StringLiteral>())
                return IR::ID(str->srcInfo, str->value);
    return IR::ID();
}

static IR::MAU::BackendAttached *createIdleTime(cstring name, const IR::Annotations *annot) {
    auto idletime = new IR::MAU::IdleTime(name);

    if (auto s = annot->getSingle("idletime_precision"))
        idletime->precision = s->expr.at(0)->to<IR::Constant>()->asInt();

    if (auto s = annot->getSingle("idletime_interval"))
        idletime->interval = s->expr.at(0)->to<IR::Constant>()->asInt();

    if (auto s = annot->getSingle("idletime_two_way_notification")) {
        int two_way_notification = s->expr.at(0)->to<IR::Constant>()->asInt();

        if (two_way_notification == 2)
            idletime->two_way_notification = "two_way";
        else if (two_way_notification == 1)
            idletime->two_way_notification = "enable";
        else if (two_way_notification == 0)
            idletime->two_way_notification = "disable";
    }

    if (auto s = annot->getSingle("idletime_per_flow_idletime")) {
        int per_flow_enable = s->expr.at(0)->to<IR::Constant>()->asInt();
        idletime->per_flow_idletime = (per_flow_enable == 1) ? true : false;
    }

    if (idletime->precision != 1 && idletime->precision != 2 &&
        idletime->precision != 3 && idletime->precision != 6)
        idletime->precision = 3;

    if (idletime->interval < 0 || idletime->interval > 12)
        idletime->interval = 7;

    idletime->two_way_notification = (idletime->precision > 1) ? "enable" : "disable";

    if (idletime->precision == 1 || idletime->precision == 2)
        idletime->per_flow_idletime = false;
    else
        idletime->per_flow_idletime = true;

    return idletime;
}

static IR::MAU::BackendAttached *createAttached(IR::MAU::Table *tt, Util::SourceInfo srcInfo,
        cstring name, const IR::Type *type, const IR::Vector<IR::Expression> *args,
        const IR::Annotations *annot, std::map<cstring, IR::MAU::ActionData *> *shared_ap,
        std::map<cstring, IR::MAU::Selector*> *shared_as) {
    // FIXME -- this should be looking at the arch model, but the current arch model stuff
    // is too complex -- need a way of building this automatically from the arch.p4 file.
    // For now, hack just using the type name as a string.
    IR::MAU::Synth2Port *rv = nullptr;
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
        auto sel = new IR::MAU::Selector(srcInfo, name, annot);
        if (annot->getSingle("mode")) {
            auto sel_mode = getAnnotID(annot, "mode");
            if (sel_mode.name == "fair" || sel_mode.name == "resilient")
                sel->mode = sel_mode;
            else if (sel_mode.name == "non_resilient")
                sel->mode = IR::ID("fair");
            else
                ::error("%s: Mode %s provided for the selector %s is unsupported",
                        sel->srcInfo, sel_mode.name, sel->name);
        } else {
            ::warning("%s: No mode specified for the selection %s.  Assuming fair", sel->srcInfo,
                       sel->name);
            sel->mode = IR::ID("fair");
        }
        sel->type = getAnnotID(annot, "type");
        sel->num_groups = 4;
        sel->group_size = 120;
        if (!sel->mode.name)
            sel->mode = IR::ID("fair");
        BUG_CHECK(args->size() == 3, "%s Selector does not have the correct number of arguments",
                  sel->srcInfo);
        sel->algorithm = args->at(0)->to<IR::Member>()->member;
        auto ap = new IR::MAU::ActionData(srcInfo, IR::ID(name));
        ap->direct = false;
        ap->size = args->at(1)->as<IR::Constant>().asInt();
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
        auto ap = new IR::MAU::ActionData(srcInfo, IR::ID(name));
        ap->size = args->at(0)->as<IR::Constant>().asInt();
        (*shared_ap)[name] = ap;
        return ap;
    } else if (tname == "counter" || tname == "direct_counter") {
        auto ctr = new IR::MAU::Counter(srcInfo, name, annot);
        for (auto anno : annot->annotations) {
            if (anno->name == "max_width")
                ctr->max_width = anno->expr.at(0)->as<IR::Constant>().asInt();
            else if (anno->name == "min_width")
                ctr->min_width = anno->expr.at(0)->as<IR::Constant>().asInt();
            else
                WARNING("unknown annotation " << anno->name << " on " << tname); }
        rv = ctr;
    } else if (tname == "meter" || tname == "direct_meter") {
        auto mtr = new IR::MAU::Meter(srcInfo, name, annot);
        for (auto anno : annot->annotations) {
            if (anno->name == "result")
                mtr->result = anno->expr.at(0);
            else if (anno->name == "pre_color")
                mtr->pre_color = anno->expr.at(0);
            else if (anno->name == "implementation")
                mtr->implementation = anno->expr.at(0)->as<IR::StringLiteral>();
            else
                WARNING("unknown annotation " << anno->name << " on " << tname); }
        rv = mtr;
    } else {
        LOG2("Failed to create attached table for " << type->toString());
        return nullptr; }

    switch (args->size()) {
        case 1:
            rv->settype(args->at(0)->as<IR::Member>().member.name);
            rv->direct = true;
            break;
        case 2:
            // XXX(hanw) handles both (member, constant) and
            // (constant, member) in meter constructor
            // because we are in the transition from v1model.p4 to tofino.p4
            if (args->at(0)->is<IR::Member>()) {
                rv->settype(args->at(0)->as<IR::Member>().member.name);
                rv->size = args->at(1)->as<IR::Constant>().asInt();
            } else if (args->at(0)->is<IR::Constant>()) {
                rv->size = args->at(0)->as<IR::Constant>().asInt();
                rv->settype(args->at(1)->as<IR::Member>().member.name);
            } else {
                BUG("unknown argument in meter %s", name);
            }
            break;
        default:
            BUG("wrong number of arguments to %s ctor %s", tname, args);
            break; }
    return rv;
}

static void updateAttachedSalu(const P4::ReferenceMap *refMap, IR::MAU::StatefulAlu *&salu,
                               const IR::Declaration_Instance *ext) {
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
            salu->size = size;
        } else {
            salu->direct = true; }
        salu->width = regtype->arguments->at(0)->width_bits();
    } else if (salu->reg != reg) {
        // FIXME -- allow multiple stateful alus in one table?  Must use the same index.
        error("%s: register actions in the same table must use the same underlying regster,"
              "trying to use %s", salu->srcInfo, reg); }
    LOG3("Adding " << ext->name << " to StatefulAlu " << reg->name);
    ext->apply(CreateSaluInstruction(salu));
}

namespace {
class FixP4Table : public Transform {
    const P4::ReferenceMap *refMap;
    IR::MAU::Table *tt;
    std::set<cstring> &unique_names;
    std::map<cstring, IR::MAU::ActionData *> *shared_ap;
    std::map<cstring, IR::MAU::Selector *> *shared_as;
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
            IR::MAU::BackendAttached *obj = nullptr;
            if (auto cc = pval->to<IR::ConstructorCallExpression>()) {
                cstring tname;
                if (auto type = cc->type->to<IR::Type_SpecializedCanonical>()) {
                    tname = type->getP4Type()->toString();
                } else {
                    tname = cc->type->toString();
                }
                if (auto p = tname.find('<'))  // strip off type args (if any)
                    tname = tname.before(p);
                unique_names.insert(tname);   // don't use the type name directly
                tname = cstring::make_unique(unique_names, tname);
                unique_names.insert(tname);

                if (auto type = cc->type->to<IR::Type_SpecializedCanonical>()) {
                    obj = createAttached(tt, cc->srcInfo, prop->externalName(tname),
                            type->baseType, cc->arguments, prop->annotations,
                            shared_ap, shared_as);
                } else {
                    obj = createAttached(tt, cc->srcInfo, prop->externalName(tname),
                            cc->type, cc->arguments, prop->annotations,
                            shared_ap, shared_as);
                }
                LOG3("Created " << obj->node_type_name() << ' ' << obj->name << " (pt 1)");
            } else if (auto pe = pval->to<IR::PathExpression>()) {
                auto &d = refMap->getDeclaration(pe->path, true)->as<IR::Declaration_Instance>();
                obj = createAttached(tt, d.srcInfo, d.externalName(), d.type,
                                     d.arguments, d.annotations, shared_ap, shared_as);
                LOG3("Created " << obj->node_type_name() << ' ' << obj->name << " (pt 2)"); }
            BUG_CHECK(obj, "not valid for %s: %s", prop->name, pval);
            LOG3("attaching " << obj->name << " to " << tt->name);
            tt->attached.push_back(obj);
        } else if (prop->name == "support_timeout") {
            auto bool_lit = ev->expression->to<IR::BoolLiteral>();
            if (bool_lit == nullptr || bool_lit->value == false)
                return ev;
            auto table = findContext<IR::P4Table>();
            auto annot = table->getAnnotations();
            auto it = createIdleTime(table->name, annot);
            tt->attached.push_back(it);
        }
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
    FixP4Table(const P4::ReferenceMap *r, IR::MAU::Table *tt, std::set<cstring> &u,
               std::map<cstring, IR::MAU::ActionData *> *ap,
               std::map<cstring, IR::MAU::Selector *> *as)
    : refMap(r), tt(tt), unique_names(u), shared_ap(ap), shared_as(as) {}
};

struct AttachTables : public Modifier {
    const P4::ReferenceMap                                  *refMap;
    std::map<cstring, safe_vector<const IR::MAU::BackendAttached *>>  attached;
    std::map<cstring, IR::MAU::StatefulAlu *>                    all_salu;
    std::map<const IR::Declaration_Instance *, const IR::MAU::BackendAttached *> converted;


    bool preorder(IR::MAU::Table *tbl) override {
        LOG3("AttachTables visiting table " << tbl->name);
        return true; }
    bool preorder(IR::MAU::Action *act) override {
        LOG3("AttachTables visiting action " << act->name);
        return true; }
    void postorder(IR::MAU::Table *tbl) override {
        for (auto a : attached[tbl->name]) {
            if (contains(tbl->attached, a)) {
                LOG3(a->name << " already attached to " << tbl->name);
            } else {
                LOG3("attaching " << a->name << " to " << tbl->name);
                tbl->attached.push_back(a); } }
        if (auto salu = all_salu[tbl->name]) {
            if (contains(tbl->attached, salu)) {
                LOG3(salu->name << " already attached to " << tbl->name);
            } else {
                LOG3("attaching " << salu->name << " to " << tbl->name);
                tbl->attached.push_back(salu); } } }
    // expressions might be in two actions (due to inlining), which need to
    // be visited independently
    void postorder(IR::Expression *) override { visitAgain(); }
    void postorder(IR::GlobalRef *gref) override {
        visitAgain();
        if (auto di = gref->obj->to<IR::Declaration_Instance>()) {
            auto tt = findContext<IR::MAU::Table>();
            BUG_CHECK(tt, "GlobalRef not in a table");
            auto &salu = all_salu[tt->name];
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
            } else if (di->type->toString().startsWith("register_action<")) {
                updateAttachedSalu(refMap, salu, di);
                gref->obj = converted[di] = salu; }
            if (salu == gref->obj) {
                auto act = findContext<IR::MAU::Action>();
                if (!salu->action_map.emplace(act->name, di->name).second) {
                    error("%s: multiple calls to execute in action %s",
                          gref->srcInfo, act->name); } } } }
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
    IR::BFN::Pipe                            *pipe;
    std::set<cstring>                                unique_names;
    std::map<const IR::Node *, IR::MAU::Table *>     tables;
    std::map<const IR::Node *, IR::MAU::TableSeq *>  seqs;
    std::map<cstring, IR::MAU::ActionData *> shared_ap;
    std::map<cstring, IR::MAU::Selector *> shared_as;
    IR::MAU::TableSeq *getseq(const IR::Node *n) {
        if (!seqs.count(n) && tables.count(n))
            seqs[n] = new IR::MAU::TableSeq(tables.at(n));
        return seqs.at(n); }

 public:
    GetTofinoTables(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                    gress_t gr, IR::BFN::Pipe *p)
    : refMap(refMap), typeMap(typeMap), gress(gr), pipe(p) {}

 private:
    void setup_tt_match(IR::MAU::Table *tt, const IR::P4Table *table) {
        auto *key = table->getKey();
        if (key == nullptr)
            return;
        int p4_param_order = 0;
        for (auto key_elem : key->keyElements) {
            auto key_expr = key_elem->expression;
            IR::ID match_id(key_elem->matchType->srcInfo, key_elem->matchType->path->name);
            if (auto *mask = key_expr->to<IR::Mask>()) {
                auto slices = convertMaskToSlices(mask);
                for (auto slice : slices) {
                    auto ixbar_read = new IR::MAU::InputXBarRead(slice, match_id);
                    ixbar_read->from_mask = true;
                    if (match_id.name != "selector")
                        ixbar_read->p4_param_order = p4_param_order;
                    tt->match_key.push_back(ixbar_read);
                }
            } else {
                auto ixbar_read = new IR::MAU::InputXBarRead(key_expr, match_id);
                if (match_id.name != "selector")
                    ixbar_read->p4_param_order = p4_param_order;
                tt->match_key.push_back(ixbar_read);
            }
            if (match_id.name != "selector")
                p4_param_order++;
        }
    }

    void setup_tt_actions(IR::MAU::Table *tt, const IR::P4Table *table) {
        for (auto act : table->properties->getProperty("actions")->value
                              ->to<IR::ActionList>()->actionList) {
            if (auto action = refMap->getDeclaration(act->getPath())->to<IR::P4Action>()) {
                auto mce = act->expression->to<IR::MethodCallExpression>();
                auto newaction = createActionFunction(refMap, typeMap, action, mce->arguments);
                DefaultActionInit dai(table, act);
                auto newaction_defact = newaction->apply(dai)->to<IR::MAU::Action>();
                if (!tt->actions.count(newaction_defact->name))
                    tt->actions.addUnique(newaction_defact->name, newaction_defact);
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
            setup_tt_match(tt, table);
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
        safe_vector<cstring> fallthrough;
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

// model tofino native pipeline using frontend IR
class TnaPipe {
 public:
    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
    const IR::P4Parser *parser;
    const IR::P4Control *mau;
    const IR::P4Control *deparser;

    TnaPipe(const IR::PackageBlock* main, gress_t gress,
            P4::ReferenceMap* refMap, P4::TypeMap* typeMap)
      : refMap(refMap), typeMap(typeMap) {
        // XXX(hanw): parameter names must be consistent with tofino.p4
        if (gress == INGRESS) {
            if (auto blk = main->getParameterValue("ingress_parser")) {
                if (auto pb = blk->to<IR::ParserBlock>()) {
                    parser = pb->container; }}
            if (auto blk = main->getParameterValue("ingress")) {
                if (auto cb = blk->to<IR::ControlBlock>()) {
                    mau = cb->container; }}
            if (auto blk = main->getParameterValue("ingress_deparser")) {
                if (auto cb = blk->to<IR::ControlBlock>()) {
                    deparser = cb->container; }}
        } else if (gress == EGRESS) {
            if (auto blk = main->getParameterValue("egress_parser")) {
                if (auto pb = blk->to<IR::ParserBlock>()) {
                    parser = pb->container; }}
            if (auto blk = main->getParameterValue("egress")) {
                if (auto cb = blk->to<IR::ControlBlock>()) {
                    mau = cb->container; }}
            if (auto blk = main->getParameterValue("egress_deparser")) {
                if (auto cb = blk->to<IR::ControlBlock>()) {
                    deparser = cb->container; }}
        } else {
            ::error("Unknown pipeline %1%", gress);
        }
    }

    void bindParams(ParamBinding* bindings) {
        for (auto param : *parser->getApplyParameters()->getEnumerator())
            bindings->bind(param);
        for (auto param : *mau->getApplyParameters()->getEnumerator())
            bindings->bind(param);
        for (auto param : *deparser->getApplyParameters()->getEnumerator())
            bindings->bind(param);
    }

    /// XXX(hanw): key to rv->metadata is used in add_parde_metadata.cpp
    void extractMetadata(IR::BFN::Pipe* rv, ParamBinding* bindings, gress_t gress) {
        if (gress == INGRESS) {
            // XXX(hanw) index must be consistent with tofino.p4
            int size = mau->getApplyParameters()->parameters.size();
            if (size > 2) {
                auto md = mau->getApplyParameters()->parameters.at(2);
                rv->metadata.addUnique("ingress_intrinsic_metadata",
                                       bindings->get(md)->obj->to<IR::Header>());
            }
            if (size > 3) {
                // intrinsic_metadata_from_parser
                auto md = mau->getApplyParameters()->parameters.at(3);
                rv->metadata.addUnique("ingress_intrinsic_metadata_from_parser",
                                       bindings->get(md)->obj->to<IR::Metadata>());
            }
            if (size > 4) {
                 // intrinsic_metadata_for_tm
                auto md = mau->getApplyParameters()->parameters.at(4);
                rv->metadata.addUnique("ingress_intrinsic_metadata_for_tm",
                                       bindings->get(md)->obj->to<IR::Metadata>());
            }
            if (size > 5) {
                auto md = mau->getApplyParameters()->parameters.at(5);
                rv->metadata.addUnique("ingress_intrinsic_metadata_for_mirror_buffer",
                                       bindings->get(md)->obj->to<IR::Metadata>());
            }
            if (size > 6) {
                auto md = mau->getApplyParameters()->parameters.at(6);
                rv->metadata.addUnique("ingress_intrinsic_metadata_for_deparser",
                                       bindings->get(md)->obj->to<IR::Metadata>());
            }
        } else if (gress == EGRESS) {
            int size = mau->getApplyParameters()->parameters.size();
            if (size > 2) {
                auto md = mau->getApplyParameters()->parameters.at(2);
                rv->metadata.addUnique("egress_intrinsic_metadata",
                                       bindings->get(md)->obj->to<IR::Header>());
            }
            if (size > 3) {
                auto md = mau->getApplyParameters()->parameters.at(3);
                rv->metadata.addUnique("egress_intrinsic_metadata_from_parser",
                                       bindings->get(md)->obj->to<IR::Metadata>());
            }
            if (size > 4) {
                auto md = mau->getApplyParameters()->parameters.at(4);
                rv->metadata.addUnique("egress_intrinsic_metadata_for_mirror_buffer",
                                       bindings->get(md)->obj->to<IR::Metadata>());
            }
            if (size > 5) {
                auto md = mau->getApplyParameters()->parameters.at(5);
                rv->metadata.addUnique("egress_intrinsic_metadata_for_output_port",
                                       bindings->get(md)->obj->to<IR::Metadata>());
            }
            if (size > 6) {
                auto md = mau->getApplyParameters()->parameters.at(6);
                rv->metadata.addUnique("egress_intrinsic_metadata_for_deparser",
                                       bindings->get(md)->obj->to<IR::Metadata>());
            }
        }
    }

    void apply(PassManager& fixup) {
        parser = parser->apply(fixup);
        mau = mau->apply(fixup);
        deparser = deparser->apply(fixup);
    }

    void extractTable(IR::BFN::Pipe* rv, gress_t gress) {
        mau->apply(GetTofinoTables(refMap, typeMap, gress, rv));
    }

    void extractAttached(IR::BFN::Pipe* rv, gress_t gress) {
        AttachTables toAttach(refMap);
        rv->thread[gress].mau = rv->thread[gress].mau->apply(toAttach);
    }

    void extractPhase0(IR::BFN::Pipe* rv, gress_t gress) {
        if (gress == EGRESS) return;
        // Check for a phase 0 table. If one exists, it'll be removed from the
        // ingress pipeline and converted to a parser program.
        // XXX(seth): We should be able to move this into the midend now.
        std::tie(mau, rv) = BFN::extractPhase0(mau, rv, refMap, typeMap);
    }

    void extractResubmit(IR::BFN::Pipe* rv, gress_t gress) {
        if (gress == EGRESS) return;
        std::tie(deparser, rv) = BFN::extractResubmit(deparser, rv, refMap, typeMap);
    }
};

const IR::BFN::Pipe* extract_native_arch(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                                            const IR::PackageBlock* main) {
    TnaPipe* pipes[2];
    pipes[INGRESS] = new TnaPipe(main, INGRESS, refMap, typeMap);
    pipes[EGRESS] = new TnaPipe(main, EGRESS, refMap, typeMap);

    ParamBinding bindings(typeMap);
    SimplifyReferences simplifyReferences(&bindings, refMap, typeMap);

    auto rv = new IR::BFN::Pipe();
    for (auto gress : {INGRESS, EGRESS}) {
        pipes[gress]->bindParams(&bindings /* out */);
        pipes[gress]->extractMetadata(rv /* out */, &bindings /* in */, gress);
        pipes[gress]->extractPhase0(rv, gress);
        pipes[gress]->apply(simplifyReferences);
        pipes[gress]->extractTable(rv /* out */, gress /* in */);
        pipes[gress]->extractAttached(rv /* out */, gress);
    }

    auto parserInfo = BFN::extractParser(rv, pipes[INGRESS]->parser, pipes[INGRESS]->deparser,
                                         pipes[EGRESS]->parser, pipes[EGRESS]->deparser);
    for (auto gress : { INGRESS, EGRESS }) {
        rv->thread[gress].parser = parserInfo.parsers[gress];
        rv->thread[gress].deparser = parserInfo.deparsers[gress];
    }

    for (auto gress : { INGRESS, EGRESS}) {
        /// native tofino path should skip this pass
        pipes[gress]->extractResubmit(rv, gress);
    }

    for (auto gress : { INGRESS, EGRESS }) {
        rv = BFN::extractChecksumFromDeparser(pipes[gress]->deparser, rv);
    }

    PassManager finalSimplifications = {
        &simplifyReferences,
        new CopyHeaderEliminator
    };

    return rv->apply(finalSimplifications);
}

const IR::BFN::Pipe *extract_maupipe(const IR::P4Program *program) {
    P4::ReferenceMap  refMap;
    P4::TypeMap       typeMap;
    refMap.setIsV1(true);
    P4::EvaluatorPass evaluator(&refMap, &typeMap);
    program->apply(evaluator);
    auto toplevel = evaluator.getToplevelBlock();
    auto top = toplevel->getMain();
    if (!top) {
        error("No main switch");
        return nullptr; }
    return extract_native_arch(&refMap, &typeMap, top);
}
