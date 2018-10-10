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
#include "bf-p4c/common/collect_global_pragma.h"
#include "bf-p4c/common/copy_header_eliminator.h"
#include "bf-p4c/common/param_binding.h"
#include "bf-p4c/common/simplify_references.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/stateful_alu.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/parde/checksum.h"
#include "bf-p4c/parde/extract_parser.h"
#include "bf-p4c/parde/mirror.h"
#include "bf-p4c/parde/phase0.h"
#include "bf-p4c/parde/resubmit.h"
#include "bf-p4c/parde/gen_deparser.h"
#include "lib/algorithm.h"
#include "lib/error.h"
#include "lib/safe_vector.h"

namespace BFN {

class ActionArgSetup : public MauTransform {
    /* FIXME -- use ParameterSubstitution for this somehow? */
    std::map<cstring, const IR::Expression *>    args;
    const IR::Node *preorder(IR::PathExpression *pe) override {
        if (args.count(pe->path->name))
            return args.at(pe->path->name);
        return pe; }

 public:
    void add_arg(const IR::MAU::ActionArg *a) { args[a->name] = a; }
    void add_arg(cstring name, const IR::Expression *e) { args[name] = e; }
};

/// This pass assumes that if a method call expression is used in assignment
/// statement, the assignement statement must be simple, i.e., it must be
/// in the form of:
///    var = method.execute();
/// if the rhs of the assignment statement is complex, such as
///    var = method.execute() + 1;
/// the assignment must be transformed to two simpler assignment statements
/// by an earlier pass.
///    tmp = method.execute();
///    var = tmp + 1;
/// CTD -- the above is not true -- this code would work fine for more complex expressions,
/// however, earlier passes will transform the complex expressions as noted above, so we could
/// assume that if we wanted to.
class ConvertMethodCalls : public MauTransform {
    P4::ReferenceMap        *refMap;
    P4::TypeMap             *typeMap;

    const IR::Expression *preorder(IR::MethodCallExpression *mc) {
        auto mi = P4::MethodInstance::resolve(mc, refMap, typeMap, true);
        cstring name;
        const IR::Expression *recv = nullptr, *extra_arg = nullptr;
        if (auto bi = mi->to<P4::BuiltInMethod>()) {
            name = bi->name;
            recv = bi->appliedTo;
            /* FIXME(CTD) -- duplicates SimplifyHeaderValidMethods a bit, as this may (will?)
             * run before that, and it can't deal with MAU::TypedPrimitives */
            if (name == "isValid") {
                return new IR::Member(mc->srcInfo, IR::Type::Bits::get(1), recv, "$valid");
            } else if (name == "setValid" || name == "setInvalid") {
                recv = new IR::Member(IR::Type::Bits::get(1), recv, "$valid");
                extra_arg = new IR::Constant(IR::Type::Bits::get(1), name == "setValid");
                name = "modify_field"; }
        } else if (auto em = mi->to<P4::ExternMethod>()) {
            name = em->actualExternType->name + "." + em->method->name;
            auto mem = mc->method->to<IR::Member>();
            if (mem && mem->expr->is<IR::This>()) {
                recv = mem->expr;
            } else {
                auto n = em->object->getNode();
                recv = new IR::GlobalRef(mem ? mem->expr->srcInfo : mc->method->srcInfo,
                                         typeMap->getType(n), n); }
        } else if (auto ef = mi->to<P4::ExternFunction>()) {
            name = ef->method->name;
        } else {
            BUG("method call %s not yet implemented", mc); }
        IR::Primitive *prim;
        if (mc->method && mc->method->type)
            prim = new IR::MAU::TypedPrimitive(mc->srcInfo, mc->type, mc->method->type, name);
        else
            prim = new IR::Primitive(mc->srcInfo, mc->type, name);
        if (recv) prim->operands.push_back(recv);
        for (auto arg : *mc->arguments)
            prim->operands.push_back(arg->expression);
        if (extra_arg) prim->operands.push_back(extra_arg);
        // if method call returns a value
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
    ConvertMethodCalls(P4::ReferenceMap *rm, P4::TypeMap *tm) : refMap(rm), typeMap(tm) {}
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
            action_arg_setup
        });
        stop_on_error = false;
    }
};

/** The purpose of this pass is to initialize each IR::MAU::Action with information on whether
 *  or not the action can be used as a default action, or if specifically it is meant only for the
 *  default action.  This information must be passed back directly to the context JSON.
 */
class DefaultActionInit : public MauModifier {
    const IR::P4Table *table;
    const IR::ActionListElement *elem;
    P4::ReferenceMap *refMap;

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
        const IR::Vector<IR::Argument> *args = nullptr;
        if (auto mc = default_action->to<IR::MethodCallExpression>()) {
            default_action = mc->method;
            args = mc->arguments;
        }
        // Indicates that this action is to be used only as a miss
        auto def_only_annot = elem->annotations->getSingle("defaultonly");

        auto path = default_action->to<IR::PathExpression>();
        if (!path)
            BUG("Default action path %s cannot be found", default_action);
        auto actName = refMap->getDeclaration(path->path, true)->externalName();

        if (actName == act->name) {
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
    DefaultActionInit(const IR::P4Table *t, const IR::ActionListElement *ale,
                      P4::ReferenceMap *rm)
        : table(t), elem(ale), refMap(rm) {}
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

static const IR::MAU::Action *createActionFunction(P4::ReferenceMap *refMap, P4::TypeMap *typeMap,
    const IR::P4Action *ac, const IR::Vector<IR::Argument> *args) {
    auto rv = new IR::MAU::Action(ac->srcInfo, ac->name, ac->annotations);
    rv->name.name = ac->externalName();
    ActionArgSetup aas;
    size_t arg_idx = 0;
    for (auto param : *ac->parameters->getEnumerator()) {
        if ((param->direction == IR::Direction::None) ||
            ((!args || arg_idx >= args->size()) && param->direction == IR::Direction::In)) {
            auto arg = new IR::MAU::ActionArg(param->srcInfo, param->type, rv->name, param->name);
            aas.add_arg(arg);
            rv->args.push_back(arg);
        } else {
            if (!args || arg_idx >= args->size())
                error("%s: Not enough args for %s", args ? args->srcInfo : ac->srcInfo, ac);
            else
                aas.add_arg(param->name, args->at(arg_idx++)->expression); } }
    if (arg_idx != (args ? args->size(): 0))
        error("%s: Too many args for %s", args->srcInfo, ac);
    ac->body->apply(ActionBodySetup(rv));
    ActionFunctionSetup afs(refMap, typeMap, &aas);
    return rv->apply(afs)->to<IR::MAU::Action>();
}

static IR::MAU::AttachedMemory *createIdleTime(cstring name, const IR::Annotations *annot) {
    auto idletime = new IR::MAU::IdleTime(name);

    if (auto s = annot->getSingle("idletime_precision")) {
        idletime->precision = s->expr.at(0)->to<IR::Constant>()->asInt();
        /* Default is 3 */
        if (idletime->precision != 1 && idletime->precision != 2 &&
            idletime->precision != 3 && idletime->precision != 6)
                idletime->precision = 3;
    }

    if (auto s = annot->getSingle("idletime_interval")) {
        idletime->interval = s->expr.at(0)->to<IR::Constant>()->asInt();
        if (idletime->interval < 0 || idletime->interval > 12)
            idletime->interval = 7;
    }

    if (auto s = annot->getSingle("idletime_two_way_notification")) {
        int two_way_notification = s->expr.at(0)->to<IR::Constant>()->asInt();
        if (two_way_notification == 1)
            idletime->two_way_notification = "two_way";
        else if (two_way_notification == 0)
            idletime->two_way_notification = "disable";
    }

    if (auto s = annot->getSingle("idletime_per_flow_idletime")) {
        int per_flow_enable = s->expr.at(0)->to<IR::Constant>()->asInt();
        idletime->per_flow_idletime = (per_flow_enable == 1) ? true : false;
    }

    /* this is weird - precision value overrides an explicit two_way_notification
     * and per_flow_idletime pragma  */
    if (idletime->precision > 1)
        idletime->two_way_notification = "two_way";

    if (idletime->precision == 1 || idletime->precision == 2)
        idletime->per_flow_idletime = false;
    else
        idletime->per_flow_idletime = true;

    return idletime;
}

void setupParam(IR::MAU::Synth2Port* rv, const IR::Vector<IR::Argument>* args) {
    if (args->size() == 1) {
        rv->settype(args->at(0)->expression->as<IR::Member>().member.name);
        rv->direct = true;
    } else if (args->size() == 2) {
        rv->size = args->at(0)->expression->as<IR::Constant>().asInt();
        rv->settype(args->at(1)->expression->as<IR::Member>().member.name);
    } else {
        BUG("cannot have more than %d arguments", args->size());
    }
}

const IR::Type* getBaseType(const IR::Type* type) {
    const IR::Type* val = type;
    if (auto* t = type->to<IR::Type_Specialized>()) {
        val = t->baseType;
    } else if (auto* t = type->to<IR::Type_SpecializedCanonical>()) {
        val = t->baseType;
    }
    return val;
}

cstring getTypeName(const IR::Type* type) {
    cstring tname;
    if (auto t = type->to<IR::Type_Name>()) {
        tname = t->path->to<IR::Path>()->name;
    } else if (auto t = type->to<IR::Type_Extern>()) {
        tname = t->name;
    } else {
        BUG("Type %s is not supported as attached table", type->toString());
    }
    return tname;
}

static IR::MAU::AttachedMemory *createAttached(Util::SourceInfo srcInfo,
        cstring name, const IR::Type *type, const IR::Vector<IR::Argument> *args,
        const IR::Annotations *annot, const P4::ReferenceMap *refMap,
        const IR::MAU::AttachedMemory **created_ap = nullptr) {
    auto baseType = getBaseType(type);
    auto tname = getTypeName(baseType);

    if (tname == "ActionSelector") {
        auto sel = new IR::MAU::Selector(srcInfo, name, annot);
        if (args->at(2)->expression->to<IR::Member>()->member.name == "FAIR") {
            sel->mode = IR::ID("fair");
        } else {
            sel->mode = IR::ID("resilient");
        }

        sel->num_groups = 4;
        sel->group_size = 120;
        sel->size = (sel->group_size + 119) / 120 * sel->num_groups;
        BUG_CHECK(args->size() == 3, "%s Selector does not have the correct number of arguments",
                  sel->srcInfo);
        auto path = args->at(1)->expression->to<IR::PathExpression>()->path;
        auto decl = refMap->getDeclaration(path)->to<IR::Declaration_Instance>();

        if (!sel->algorithm.setup(decl->arguments->at(0)->expression))
            BUG("invalid algorithm %s", decl->arguments->at(0)->expression);

        auto ap = new IR::MAU::ActionData(srcInfo, IR::ID(name));
        ap->direct = false;
        ap->size = args->at(0)->expression->as<IR::Constant>().asInt();
        // FIXME Need to reconstruct the field list from the table key?
        *created_ap = ap;
        return sel;
    } else if (tname == "ActionProfile") {
        auto ap = new IR::MAU::ActionData(srcInfo, IR::ID(name));
        ap->size = args->at(0)->expression->as<IR::Constant>().asInt();
        return ap;
    } else if (tname == "Counter" || tname == "DirectCounter") {
        auto ctr = new IR::MAU::Counter(srcInfo, name, annot);
        setupParam(ctr, args);
        return ctr;
    } else if (tname == "Meter") {
        auto mtr = new IR::MAU::Meter(srcInfo, name, annot);
        setupParam(mtr, args);
        for (auto anno : annot->annotations) {
            if (anno->name == "result")
                mtr->result = anno->expr.at(0);
            else if (anno->name == "implementation")
                mtr->implementation = anno->expr.at(0)->as<IR::StringLiteral>();
            else if (anno->name == "green")
                mtr->green_value = anno->expr.at(0)->as<IR::Constant>().asInt();
            else if (anno->name == "yellow")
                mtr->yellow_value = anno->expr.at(0)->as<IR::Constant>().asInt();
            else if (anno->name == "red")
                mtr->red_value = anno->expr.at(0)->as<IR::Constant>().asInt();
            else if (anno->name == "meter_profile")
                mtr->profile = anno->expr.at(0)->as<IR::Constant>().asInt();
            else if (anno->name == "meter_sweep_interval")
                mtr->sweep_interval = anno->expr.at(0)->as<IR::Constant>().asInt();
            else
                WARNING("unknown annotation " << anno->name << " on " << tname); }
        return mtr;
    } else if (tname == "DirectMeter") {
        auto mtr = new IR::MAU::Meter(srcInfo, name, annot);
        setupParam(mtr, args);
        return mtr;
    } else if (tname == "Lpf") {
        auto mtr = new IR::MAU::Meter(srcInfo, name, annot);
        mtr->implementation = IR::ID("lpf");
        mtr->size = args->at(0)->expression->as<IR::Constant>().asInt();
        return mtr;
    } else if (tname == "DirectLpf") {
        auto mtr = new IR::MAU::Meter(srcInfo, name, annot);
        mtr->implementation = IR::ID("lpf");
        mtr->direct = true;
        return mtr;
    } else if (tname == "Wred") {
        auto mtr = new IR::MAU::Meter(srcInfo, name, annot);
        mtr->implementation = IR::ID("wred");
        mtr->size = args->at(0)->expression->as<IR::Constant>().asInt();
        mtr->red_drop_value = args->at(1)->expression->as<IR::Constant>().asInt();
        mtr->red_nodrop_value = args->at(2)->expression->as<IR::Constant>().asInt();
        return mtr;
    } else if (tname == "DirectWred") {
        auto mtr = new IR::MAU::Meter(srcInfo, name, annot);
        mtr->implementation = IR::ID("wred");
        mtr->direct = true;
        mtr->red_drop_value = args->at(0)->expression->as<IR::Constant>().asInt();
        mtr->red_nodrop_value = args->at(1)->expression->as<IR::Constant>().asInt();
        return mtr;
    }

    LOG2("Failed to create attached table for " << tname);
    return nullptr;
}



class FixP4Table : public Inspector {
    const P4::ReferenceMap *refMap;
    IR::MAU::Table *tt;
    std::set<cstring> &unique_names;
    DeclarationConversions &converted;
    DeclarationConversions &assoc_profiles;

    bool preorder(const IR::P4Table *tc) override {
        visit(tc->properties);  // just visiting properties
        return false;
    }
    bool preorder(const IR::ExpressionValue *ev) override {
        auto prop = findContext<IR::Property>();
        if (prop->name == "counters" || prop->name == "meters" ||
                   prop->name == "implementation") {
            auto pval = ev->expression;
            const IR::MAU::AttachedMemory *obj = nullptr;
            const IR::MAU::AttachedMemory *side_obj = nullptr;
            if (auto cc = pval->to<IR::ConstructorCallExpression>()) {
                auto baseType = getBaseType(cc->type);
                auto tname = getTypeName(baseType);
                unique_names.insert(tname);   // don't use the type name directly
                tname = cstring::make_unique(unique_names, tname);
                unique_names.insert(tname);
                obj = createAttached(cc->srcInfo, prop->externalName(tname),
                                     baseType, cc->arguments, prop->annotations,
                                     refMap, &side_obj);
            } else if (auto pe = pval->to<IR::PathExpression>()) {
                auto &d = refMap->getDeclaration(pe->path, true)->as<IR::Declaration_Instance>();
                // The algorithm saves action selectors in the large map, rather than the action
                // profile, because no ActionProfile will appear as a declaration within an
                // action.  Action selector will show up in a register selector_action
                if (converted.count(&d) == 0) {
                    LOG3("Create attached " << d.externalName());
                    obj = createAttached(d.srcInfo, d.externalName(), d.type,
                                         d.arguments, d.annotations, refMap, &side_obj);
                    converted[&d] = obj;
                    if (side_obj)
                        assoc_profiles[&d] = side_obj;
                } else {
                    // Action Selectors and Action Profiles are implemented in the same property
                    LOG3("Found relative attached " << d.externalName() << " "
                         << assoc_profiles.size());
                    obj = converted.at(&d);
                    if (assoc_profiles.count(&d))
                        side_obj = assoc_profiles.at(&d);
                }
                LOG3("Created " << obj->node_type_name() << ' ' << obj->name << " (pt 2)"); }
            BUG_CHECK(obj, "not valid for %s: %s", prop->name, pval);
            LOG3("attaching " << obj->name << " to " << tt->name);
            tt->attached.push_back(new IR::MAU::BackendAttached(obj->srcInfo, obj));
            if (side_obj)
                tt->attached.push_back(new IR::MAU::BackendAttached(side_obj->srcInfo, side_obj));
        } else if (prop->name == "idle_timeout") {
            auto bool_lit = ev->expression->to<IR::BoolLiteral>();
            if (bool_lit == nullptr || bool_lit->value == false)
                return false;
            auto table = findContext<IR::P4Table>();
            auto annot = table->getAnnotations();
            auto it = createIdleTime(table->name, annot);
            tt->attached.push_back(new IR::MAU::BackendAttached(it->srcInfo, it));
        }
        return false;
    }

 public:
    FixP4Table(const P4::ReferenceMap *r, IR::MAU::Table *tt, std::set<cstring> &u,
               DeclarationConversions &con, DeclarationConversions &ap)
    : refMap(r), tt(tt), unique_names(u), converted(con), assoc_profiles(ap) {}
};

Visitor::profile_t AttachTables::init_apply(const IR::Node *root) {
    LOG5("AttachTables working on:" << std::endl << root);
    return PassManager::init_apply(root);
}

/** Determine stateful ALU Declaration_Instance underneath the register action, as well
 *  as typing information
 */
bool AttachTables::findSaluDeclarations(const IR::Declaration_Instance *ext,
        const IR::Declaration_Instance **reg_ptr, const IR::Type_Specialized **regtype_ptr,
        const IR::Type_Extern **seltype_ptr) {
    auto reg_arg = ext->arguments->size() > 0 ? ext->arguments->at(0)->expression : nullptr;
    if (!reg_arg) {
        if (auto regprop = ext->properties["reg"]) {
            if (auto rpv = regprop->value->to<IR::ExpressionValue>())
                reg_arg = rpv->expression;
            else
                BUG("reg property %s is not an ExpressionValue", regprop);
        } else {
            error("%s: no reg property in stateful_alu %s", ext->srcInfo, ext->name);
            return false; } }
    auto pe = reg_arg->to<IR::PathExpression>();
    auto d = pe ? refMap->getDeclaration(pe->path, true) : nullptr;
    auto reg = d ? d->to<IR::Declaration_Instance>() : nullptr;
    auto regtype = reg ? reg->type->to<IR::Type_Specialized>() : nullptr;
    auto seltype = reg ? reg->type->to<IR::Type_Extern>() : nullptr;
    if ((!regtype || regtype->baseType->toString() != "DirectRegister") &&
        (!regtype || regtype->baseType->toString() != "Register") &&
        (!seltype || seltype->name != "ActionSelector")) {
        error("%s: is not a Register or ActionSelector", reg_arg->srcInfo);
        return false;
    }
    *reg_ptr = reg;
    if (regtype_ptr)
        *regtype_ptr = regtype;
    if (seltype_ptr)
        *seltype_ptr = seltype;
    return true;
}

static cstring getString(const IR::Annotation* annotation) {
    if (annotation->expr.size() != 1) {
        ::error("%1% should contain a string", annotation);
        return "";
    }
    auto str = annotation->expr[0]->to<IR::StringLiteral>();
    if (str == nullptr) {
        ::error("%1% should contain a string", annotation);
        return "";
    }
    return str->value;
}

/** Converts the Declaration_Instance of the register action into a StatefulAlu object.  Checks
 *  to see if a stateful ALU has already been created, and will also create the SALU Instructions
 *  if the register action is new
 */
void AttachTables::InitializeStatefulAlus
        ::updateAttachedSalu(const IR::Declaration_Instance *ext,
                             const IR::GlobalRef *gref) {
    const IR::Declaration_Instance *reg = nullptr;
    const IR::Type_Specialized *regtype = nullptr;
    const IR::Type_Extern *seltype = nullptr;
    LOG6("updateAttachedSalu(" << ext->name << "[" << ext->id << "], " <<
         gref->srcInfo.toPositionString() << "[" << gref->id << "])");
    bool found = self.findSaluDeclarations(ext, &reg, &regtype, &seltype);
    if (!found) return;

    IR::MAU::StatefulAlu *salu = nullptr;
    if (salu_inits.count(reg)) {
        salu = salu_inits.at(reg);
    } else {
        // Stateful ALU has not been seen yet
        LOG3("Creating new StatefulAlu for " <<
             (regtype ? regtype->toString() : seltype->toString()) << " " << reg->name);
        auto regName = reg->externalName();
        // @reg annotation is used in p4-14 to generate PD API for action selector.
        auto anno = ext->annotations->getSingle("reg");
        if (anno)
            regName = getString(anno);
        salu = new IR::MAU::StatefulAlu(reg->srcInfo, regName, reg->annotations, reg);
        auto annots = ext->annotations ? ext->annotations : 0;
        // Reg initialization values for lo/hi are passed as annotations. In
        // p4_14 conversion they cannot be set directly on the register For
        // p4_16 programs these are passed in as optional stateful params
        for (auto annot : annots->annotations) {
            if (annot->name == "initial_register_lo_value") {
                salu->init_reg_lo = annot->expr.at(0)->to<IR::Constant>()->asInt();
                LOG4("Reg initial lo value: " << salu->init_reg_lo); }
            if (annot->name == "initial_register_hi_value") {
                salu->init_reg_hi = annot->expr.at(0)->to<IR::Constant>()->asInt();
                LOG4("Reg initial hi value: " << salu->init_reg_hi); } }
        if (seltype) {
            salu->direct = false;
            auto sel = self.converted.at(reg)->to<IR::MAU::Selector>();
            ERROR_CHECK(sel, "%s: Could not find the associated selector within the stateful "
                        "ALU %s, even though a selector is specified", gref->srcInfo,
                         salu->name);
            salu->selector = sel;
            // FIXME -- how are selector table sizes set?  It seems to be lost in P4_16
            salu->size = 120*1024;  // one ram?
        } else if (regtype->toString().startsWith("Register<")) {
            salu->direct = false;
            salu->size = reg->arguments->at(0)->expression->to<IR::Constant>()->asInt();
        } else {
            salu->direct = true; }
        salu->width = regtype ? regtype->arguments->at(0)->width_bits() : 1;
        if (auto cts = reg->annotations->getSingle("chain_total_size")) {
            const IR::Constant *k;
            if (cts->expr.size() != 1 || !(k = cts->expr[0]->to<IR::Constant>()))
                error("%s: chain_total_size must be a constant", cts->srcInfo);
            else
                salu->chain_total_size = k->asInt(); }
        salu_inits[reg] = salu; }

    // If the register action hasn't been seen before, this creates an SALU Instruction
    if (register_actions.count(ext) == 0) {
        LOG3("Adding " << ext->name << " to StatefulAlu " << reg->name);
        register_actions.insert(ext);
        ext->apply(CreateSaluInstruction(salu));
    }

    auto prim = findContext<IR::Primitive>();
    LOG6("  - " << (prim ? prim->name : "<no primitive>"));
    if (prim && prim->name == "RegisterAction.address") {
        salu->chain_vpn = true;
        return; }
    auto act = findContext<IR::MAU::Action>();
    LOG6("  - action " << (act ? act->name : "<no action>"));
    if (!salu->action_map.emplace(act->name.originalName, ext->name).second)
        error("%s: multiple calls to execute in action %s", gref->srcInfo, act->name);
}

void AttachTables::InitializeStatefulAlus::postorder(const IR::GlobalRef *gref) {
    visitAgain();
    if (auto di = gref->obj->to<IR::Declaration_Instance>()) {
        if (di->type->toString().startsWith("RegisterAction<") ||
            di->type->toString().startsWith("DirectRegisterAction<") ||
            di->type->toString().startsWith("LearnAction<") ||
            di->type->toString() == "selector_action") {
            updateAttachedSalu(di, gref);
        }
    }
}

/** Convert these Stateful ALUs to constant pointers.  This was necessary to maintain const
 *  pointers for a later pass.
 */
void AttachTables::InitializeStatefulAlus::end_apply() {
    self.all_salus.insert(salu_inits.begin(), salu_inits.end());
}

const IR::MAU::StatefulAlu *AttachTables::DefineGlobalRefs
        ::findAttachedSalu(const IR::Declaration_Instance *ext) {
    const IR::Declaration_Instance *reg = nullptr;
    bool found = self.findSaluDeclarations(ext, &reg);
    if (!found) return nullptr;

    auto salu = self.all_salus.at(reg)->to<IR::MAU::StatefulAlu>();
    BUG_CHECK(salu, "Stateful Alu cannot be found, and should have been initialized within "
              "the previous pass");
    return salu;
}

bool AttachTables::DefineGlobalRefs::preorder(IR::MAU::Table *tbl) {
    LOG3("AttachTables visiting table " << tbl->name);
    return true;
}

bool AttachTables::DefineGlobalRefs::preorder(IR::MAU::Action *act) {
    LOG3("AttachTables visiting action " << act->name);
    return true;
}

void AttachTables::DefineGlobalRefs::postorder(IR::MAU::Table *tbl) {
    for (auto a : attached[tbl->name]) {
        bool already_attached = false;
        for (auto al_a : tbl->attached) {
            if (a->attached == al_a->attached) {
                already_attached = true;
                break;
            }
        }
        if (already_attached) {
            LOG3(a->attached->name << " already attached to " << tbl->name);
        } else {
            LOG3("attaching " << a->attached->name << " to " << tbl->name);
            tbl->attached.push_back(a);
        }
    }
}

void AttachTables::DefineGlobalRefs::postorder(IR::GlobalRef *gref) {
    // expressions might be in two actions (due to inlining), which need to
    // be visited independently
    visitAgain();
    if (auto di = gref->obj->to<IR::Declaration_Instance>()) {
        auto tt = findContext<IR::MAU::Table>();
        BUG_CHECK(tt, "GlobalRef not in a table");
        const IR::MAU::AttachedMemory *obj = nullptr;
        if (self.converted.count(di)) {
            obj = self.converted.at(di);
            gref->obj = obj;
        } else if (auto att = createAttached(di->srcInfo, di->externalName(),
                                             di->type, di->arguments, di->annotations,
                                             refMap, nullptr)) {
            LOG3("Created " << att->node_type_name() << ' ' << att->name << " (pt 3)");
            gref->obj = self.converted[di] = att;
            obj = att;
        } else if (di->type->toString().startsWith("RegisterAction<") ||
                   di->type->toString().startsWith("DirectRegisterAction<") ||
                   di->type->toString().startsWith("LearnAction<") ||
                   di->type->toString() == "selector_action") {
            auto salu = findAttachedSalu(di);
            // Could be because an earlier pass errored out, and we do not stop_on_error
            // In a non-error case, this should always be non-null, and is checked in a BUG
            if (salu == nullptr)
                return;
            gref->obj = salu;
            obj = salu;
        }

        if (obj) {
            bool already_attached = false;
            for (auto at : attached[tt->name]) {
                if (at->attached == obj) {
                    already_attached = true;
                    break;
                }
            }
            if (!already_attached) {
                attached[tt->name].push_back(new IR::MAU::BackendAttached(obj->srcInfo, obj));
            }
        }
    }
}

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

class RewriteActionNames : public Modifier {
    const IR::P4Action *p4_action;
    IR::MAU::Table *mau_table;

 public:
    RewriteActionNames(const IR::P4Action *ac, IR::MAU::Table *tt)
        : p4_action(ac), mau_table(tt) {}

 private:
    bool preorder(IR::Path *path) {
        if (findOrigCtxt<IR::MethodCallExpression>()) {
            for (auto action : Values(mau_table->actions)) {
                if (action->name.name == p4_action->externalName()
                        && p4_action->name.name == path->name.name) {
                    path->name.name = p4_action->externalName();
                    path->name.originalName = action->name.originalName;
                    break;
                }
            }
        }
        return false;
    }
};

class GetBackendTables : public MauInspector {
    P4::ReferenceMap                            *refMap;
    P4::TypeMap                                 *typeMap;
    gress_t                                     gress;
    const IR::MAU::TableSeq                     *&rv;
    DeclarationConversions                      &converted;
    DeclarationConversions                      assoc_profiles;
    std::set<cstring>                                unique_names;
    std::map<const IR::Node *, IR::MAU::Table *>     tables;
    std::map<const IR::Node *, IR::MAU::TableSeq *>  seqs;
    IR::MAU::TableSeq *getseq(const IR::Node *n) {
        if (!seqs.count(n) && tables.count(n))
            seqs[n] = new IR::MAU::TableSeq(tables.at(n));
        return seqs.at(n); }

 public:
    GetBackendTables(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                    gress_t gr, const IR::MAU::TableSeq *&rv, DeclarationConversions &con)
    : refMap(refMap), typeMap(typeMap), gress(gr), rv(rv), converted(con) {}

 private:
    void setup_match_mask(IR::MAU::Table *tt, const IR::Mask *mask, IR::ID match_id,
                          int p4_param_order, boost::optional<cstring> ann) {
        auto slices = convertMaskToSlices(mask);
        for (auto slice : slices) {
            auto ixbar_read = new IR::MAU::InputXBarRead(slice, match_id);
            ixbar_read->from_mask = true;
            if (match_id.name != "selector")
                ixbar_read->p4_param_order = p4_param_order;
            if (ann) {
                ixbar_read->annotations = ixbar_read->annotations->addAnnotationIfNew(
                   IR::Annotation::nameAnnotation,
                   new IR::StringLiteral(*ann)); }
            tt->match_key.push_back(ixbar_read);
        }
    }

    void setup_tt_match(IR::MAU::Table *tt, const IR::P4Table *table) {
        auto *key = table->getKey();
        if (key == nullptr)
            return;
        int p4_param_order = 0;
        for (auto key_elem : key->keyElements) {
            // Get name annotation, if present.
            boost::optional<cstring> ann = boost::none;
            if (auto nameAnn = key_elem->getAnnotation(IR::Annotation::nameAnnotation))
                ann = IR::Annotation::getName(nameAnn);

            auto key_expr = key_elem->expression;
            IR::ID match_id(key_elem->matchType->srcInfo, key_elem->matchType->path->name);
            if (auto *b_and = key_expr->to<IR::BAnd>()) {
                IR::Mask *mask = nullptr;
                if (b_and->left->is<IR::Constant>())
                    mask = new IR::Mask(b_and->srcInfo, b_and->type, b_and->right, b_and->left);
                else if (b_and->right->is<IR::Constant>())
                    mask = new IR::Mask(b_and->srcInfo, b_and->type, b_and->left, b_and->right);
                else
                    ::error("%s: mask %s must have a constant operand to be used as a table key",
                             b_and->srcInfo, b_and);
                if (mask == nullptr)
                    continue;
                setup_match_mask(tt, mask, match_id, p4_param_order, ann);
            } else if (auto *mask = key_expr->to<IR::Mask>()) {
                setup_match_mask(tt, mask, match_id, p4_param_order, ann);
            } else {
                auto ixbar_read = new IR::MAU::InputXBarRead(key_expr, match_id);
                if (match_id.name != "selector")
                    ixbar_read->p4_param_order = p4_param_order;
                if (ann) {
                    ixbar_read->annotations = ixbar_read->annotations->addAnnotationIfNew(
                       IR::Annotation::nameAnnotation,
                       new IR::StringLiteral(*ann)); }
                tt->match_key.push_back(ixbar_read);
            }
            if (match_id.name != "selector")
                p4_param_order++;
        }
    }

    // This function creates a copy of the static entry list within the match
    // table into the backend MAU::Table. This is required to modify names
    // present on actions which are updated in the backend.
    void update_entries_list(IR::MAU::Table *tt, const IR::P4Action *ac) {
        if (tt->entries_list == nullptr) return;
        auto el = tt->entries_list->apply(RewriteActionNames(ac, tt));
        tt->entries_list = el->to<IR::EntriesList>();
    }

    // Convert from IR::P4Action to IR::MAU::Action
    void setup_actions(IR::MAU::Table *tt, const IR::P4Table *table) {
        auto actionList = table->getActionList();
        tt->entries_list = tt->match_table->getEntries();
        for (auto act : actionList->actionList) {
            auto decl = refMap->getDeclaration(act->getPath())->to<IR::P4Action>();
            BUG_CHECK(decl != nullptr,
                      "Table %s actions property cannot contain non-action entry", table->name);
            // act->expression can be either PathExpression or MethodCallExpression, but
            // the createBuiltin pass in frontend has already converted IR::PathExpression
            // to IR::MethodCallExpression.
            auto mce = act->expression->to<IR::MethodCallExpression>();
            auto newaction = createActionFunction(refMap, typeMap, decl, mce->arguments);
            DefaultActionInit dai(table, act, refMap);
            auto newaction_defact = newaction->apply(dai)->to<IR::MAU::Action>();
            if (!tt->actions.count(newaction_defact->name.originalName))
                tt->actions.emplace(newaction_defact->name.originalName, newaction_defact);
            else
                error("%s: action %s appears multiple times in table %s", decl->name.srcInfo,
                          decl->name, tt->name);
            update_entries_list(tt, decl);
        }
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
                table->apply(FixP4Table(refMap, tt, unique_names, converted,
                                        assoc_profiles))->to<IR::P4Table>();
            setup_tt_match(tt, table);
            setup_actions(tt, table);
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
                              ->getName().originalName;
            if (c->statement) {
                auto n = getseq(c->statement);
                tt->next.emplace(label, n);
                for (auto ft : fallthrough)
                    tt->next.emplace(ft, n);
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
            tables.at(c)->next.emplace(T, getseq(c->ifTrue));
        if (c->ifFalse && !c->ifFalse->is<IR::EmptyStatement>())
            tables.at(c)->next.emplace(F, getseq(c->ifFalse));
    }

    // need to understand architecture to process the correct control block
    bool preorder(const IR::BFN::TranslatedP4Control *cf) override {
        visit(cf->body);
        rv = getseq(cf->body);
        return false;
    }

    bool preorder(const IR::EmptyStatement *) override { return false; }
    void postorder(const IR::Statement *st) override {
        BUG("Unhandled statement %1%", st); }

    void end_apply() override {
        // FIXME -- if both ingress and egress contain method calls to the same
        // extern object, and that object contains any method calls, this will end
        // up duplicating that object.  Currently there are no extern objects that can
        // both contain code and be shared between threads, so that can't happen
        rv = rv->apply(ConvertMethodCalls(refMap, typeMap));
    }
};

class ExtractMetadata : public Inspector {
 public:
    ExtractMetadata(IR::BFN::Pipe *rv, ParamBinding *bindings) : rv(rv), bindings(bindings) {
        setName("ExtractMetadata");
    }

    void postorder(const IR::BFN::TranslatedP4Control *mau) override {
        gress_t gress = mau->thread;

        if (gress == INGRESS) {
            // XXX(hanw) index must be consistent with tofino.p4
            int size = mau->getApplyParameters()->parameters.size();
            auto md = mau->getApplyParameters()->parameters.at(2);
            rv->metadata.addUnique("ingress_intrinsic_metadata",
                                   bindings->get(md)->obj->to<IR::Header>());

            // intrinsic_metadata_from_parser
            md = mau->getApplyParameters()->parameters.at(3);
            rv->metadata.addUnique("ingress_intrinsic_metadata_from_parser",
                                   bindings->get(md)->obj->to<IR::Metadata>());

            // intrinsic_metadata_from_deparser
            md = mau->getApplyParameters()->parameters.at(4);
            rv->metadata.addUnique("ingress_intrinsic_metadata_for_deparser",
                                   bindings->get(md)->obj->to<IR::Metadata>());

            // intrinsic_metadata_for_tm
            md = mau->getApplyParameters()->parameters.at(5);
            rv->metadata.addUnique("ingress_intrinsic_metadata_for_tm",
                                   bindings->get(md)->obj->to<IR::Metadata>());

            // compiler_generated_metadata
            if (size > 6) {
                md = mau->getApplyParameters()->parameters.at(6);
                rv->metadata.addUnique("compiler_generated_meta",
                                       bindings->get(md)->obj->to<IR::Metadata>());
            }
        } else if (gress == EGRESS) {
            auto md = mau->getApplyParameters()->parameters.at(2);
            rv->metadata.addUnique("egress_intrinsic_metadata",
                                   bindings->get(md)->obj->to<IR::Header>());

            md = mau->getApplyParameters()->parameters.at(3);
            rv->metadata.addUnique("egress_intrinsic_metadata_from_parser",
                                   bindings->get(md)->obj->to<IR::Metadata>());

            md = mau->getApplyParameters()->parameters.at(4);
            rv->metadata.addUnique("egress_intrinsic_metadata_for_deparser",
                                   bindings->get(md)->obj->to<IR::Metadata>());

            md = mau->getApplyParameters()->parameters.at(5);
            rv->metadata.addUnique("egress_intrinsic_metadata_for_output_port",
                                   bindings->get(md)->obj->to<IR::Metadata>());
        }
    }

 private:
    IR::BFN::Pipe *rv;
    ParamBinding *bindings;
};

class ExtractPhase0 : public Inspector {
 public:
    ExtractPhase0(IR::BFN::Pipe *rv, P4::ReferenceMap *refMap)
        : rv(rv), refMap(refMap) {}

    void postorder(const IR::BFN::TranslatedP4Control *mau) override {
        gress_t thread = mau->thread;
        if (thread == EGRESS) return;
        BFN::extractPhase0(mau, rv, refMap);
    }

 private:
    IR::BFN::Pipe *rv;
    P4::ReferenceMap *refMap;
};

struct ExtractChecksum : public Inspector {
    explicit ExtractChecksum(IR::BFN::Pipe* rv) :
        rv(rv) { setName("ExtractChecksumNative"); }

    void postorder(const IR::BFN::TranslatedP4Deparser* deparser) override {
        extractChecksumFromDeparser(deparser, rv);
    }

    IR::BFN::Pipe* rv;
};

// used by backend for stratum architecture
ProcessBackendPipe::ProcessBackendPipe(P4::ReferenceMap *refMap, P4::TypeMap *typeMap,
                                       IR::BFN::Pipe *rv, DeclarationConversions &converted,
                                       const BFN::ResubmitPacking* resubmitPackings,
                                       const BFN::MirroredFieldListPacking* mirrorPackings,
                                       ParamBinding *bindings) {
    setName("ProcessBackendPipe");
    CHECK_NULL(bindings);
    CHECK_NULL(resubmitPackings);
    CHECK_NULL(mirrorPackings);
    auto simplifyReferences = new SimplifyReferences(bindings, refMap, typeMap);
    addPasses({
        new AttachTables(refMap, converted),  // add attached tables
        new ProcessParde(rv, false /* useTna */),         // add parde metadata
        new PopulateResubmitStateWithFieldPackings(resubmitPackings),
        new PopulateMirrorStateWithFieldPackings(rv, mirrorPackings),
        /// followings two passes are necessary, because ProcessBackendPipe transforms the
        /// IR::BFN::Pipe objects. If all the above passes can be moved to an earlier midend
        /// pass, then the passes below can possibily be removed.
        simplifyReferences,
        new CopyHeaderEliminator(),
    });
}

// used by backend for tna architecture
ProcessBackendPipe::ProcessBackendPipe(P4::ReferenceMap *refMap, P4::TypeMap *typeMap,
                                       IR::BFN::Pipe *rv, DeclarationConversions &converted,
                                       ParamBinding *bindings) {
    setName("ProcessBackendPipe");
    CHECK_NULL(bindings);
    auto simplifyReferences = new SimplifyReferences(bindings, refMap, typeMap);
    addPasses({
        new AttachTables(refMap, converted),  // add attached tables
        new ProcessParde(rv, true /* useTna */),           // add parde metadata
        /// followings two passes are necessary, because ProcessBackendPipe transforms the
        /// IR::BFN::Pipe objects. If all the above passes can be moved to an earlier midend
        /// pass, then the passes below can possibily be removed.
        simplifyReferences,
        new CopyHeaderEliminator(),
    });
}

cstring BackendConverter::getPipelineName(const IR::P4Program* program, int index) {
    auto mainDecls = program->getDeclsByName("main")->toVector();
    if (mainDecls->size() == 0) {
        ::error("No main declaration in the program");
        return nullptr;
    } else if (mainDecls->size() > 1) {
        ::error("Multiple main declarations in the program");
        return nullptr; }
    auto decl = mainDecls->at(0);
    auto expr = decl->to<IR::Declaration_Instance>()->arguments->at(index)->expression;
    if (!expr->is<IR::PathExpression>()) {
        ::error("Anonymous instantiation of Pipeline block in 'main' is not supported");
        return nullptr; }
    auto path = expr->to<IR::PathExpression>();
    auto name = path->path->name;
    return name;
}

void BackendConverter::convertTnaProgram(const IR::P4Program* program, BFN_Options& options) {
    auto main = toplevel->getMain();
    DeclarationConversions converted;

    auto arch = new ParseTna(&threads);
    toplevel->getMain()->apply(*arch);

    auto bindings = new ParamBinding(typeMap,
            options.langVersion == CompilerOptions::FrontendVersion::P4_14);
    /// SimplifyReferences passes are fixup passes that modifies the visited IR tree.
    /// Unfortunately, the modifications by simplifyReferences will transform IR tree towards
    /// the backend IR, which means we can no longer run typeCheck pass after applying
    /// simplifyReferences to the frontend IR.
    auto simplifyReferences = new SimplifyReferences(bindings, refMap, typeMap);
    // ParamBinding pass must be applied to IR::P4Program* node,
    // see comments in param_binding.h for the reason.
    program->apply(*bindings);

    // collect and set global_pragmas
    CollectGlobalPragma collect_pragma;
    program->apply(collect_pragma);

    auto npipe = 0;
    for (auto pkg : main->constantValue) {
        if (!pkg.second) continue;
        if (!pkg.second->is<IR::PackageBlock>()) continue;
        auto name = getPipelineName(program, npipe);
        auto rv = new IR::BFN::Pipe(name, npipe);
        std::list<gress_t> gresses = {INGRESS, EGRESS};
        for (auto gress : gresses) {
            if (!threads.count(std::make_pair(npipe, gress))) {
                ::error("Unabled to find thread %1%", npipe);
                return; }
            auto thread = threads.at(std::make_pair(npipe, gress));
            thread = thread->apply(*simplifyReferences);
            if (auto mau = thread->mau->to<IR::BFN::TranslatedP4Control>()) {
                mau->apply(ExtractMetadata(rv, bindings));
                mau->apply(GetBackendTables(refMap, typeMap, gress, rv->thread[gress].mau,
                                            converted));
            }
            if (auto parser = thread->parser->to<IR::BFN::TranslatedP4Parser>()) {
                parser->apply(ExtractParser(refMap, typeMap, rv));
            }
            if (auto dprsr = thread->deparser->to<IR::BFN::TranslatedP4Deparser>()) {
                dprsr->apply(ExtractDeparser(rv));
                dprsr->apply(ExtractChecksum(rv));
            }
        }
        if (threads.count(std::make_pair(npipe, GHOST))) {
            auto thread = threads.at(std::make_pair(npipe, GHOST));
            thread = thread->apply(*simplifyReferences);
            if (auto mau = thread->mau->to<IR::BFN::TranslatedP4Control>()) {
                mau->apply(ExtractMetadata(rv, bindings));
                mau->apply(GetBackendTables(refMap, typeMap, GHOST, rv->ghost_thread, converted));
            }
        }

        rv->global_pragmas = collect_pragma.global_pragmas();

        ProcessBackendPipe processBackendPipe(refMap, typeMap, rv, converted, bindings);
        processBackendPipe.addDebugHook(options.getDebugHook());

        pipe.push_back(rv->apply(processBackendPipe));
        npipe++;

        // clear DeclarationConversions map after the conversion of each pipeline.
        converted.clear();
    }
}

void BackendConverter::convertV1Program(const IR::P4Program *program, BFN_Options &options) {
    DeclarationConversions converted;
    ResubmitPacking resubmitPackings;
    MirroredFieldListPacking mirrorPackings;

    auto arch = new ParseTna(&threads);
    toplevel->getMain()->apply(*arch);

    auto name = getPipelineName(program, 0);
    auto rv = new IR::BFN::Pipe(name);
    auto bindings = new ParamBinding(typeMap,
        options.langVersion == CompilerOptions::FrontendVersion::P4_14);
    auto simplifyReferences = new SimplifyReferences(bindings, refMap, typeMap);
    // ParamBinding pass must be applied to IR::P4Program* node,
    // see comments in param_binding.h for the reason.
    program->apply(*bindings);
    std::list<gress_t> gresses = {INGRESS, EGRESS};
    for (auto gress : gresses) {
        if (!threads.count(std::make_pair(0 /* pipe 0 */, gress)))
            return;
        auto thread = threads.at(std::make_pair(0 /* pipe 0 */, gress));
        thread = thread->apply(*simplifyReferences);
        if (!thread)
            return;
        if (auto mau = thread->mau->to<IR::BFN::TranslatedP4Control>()) {
            mau->apply(ExtractMetadata(rv, bindings));
            mau->apply(ExtractPhase0(rv, refMap));
            mau->apply(GetBackendTables(refMap, typeMap, gress, rv->thread[gress].mau, converted));
        }
        if (auto parser = thread->parser->to<IR::BFN::TranslatedP4Parser>()) {
            parser->apply(ExtractParser(refMap, typeMap, rv));
        }
        if (auto dprsr = thread->deparser->to<IR::BFN::TranslatedP4Deparser>()) {
            dprsr->apply(ExtractDeparser(rv));
            dprsr->apply(ExtractChecksum(rv));
            dprsr->apply(ExtractResubmitFieldPackings(refMap, typeMap, &resubmitPackings));
            dprsr->apply(ExtractMirrorFieldPackings(refMap, typeMap, &mirrorPackings));
        }
    }

    // collect and set global_pragmas
    CollectGlobalPragma collect_pragma;
    program->apply(collect_pragma);
    rv->global_pragmas = collect_pragma.global_pragmas();

    LOG2("initial extracted program \n" << *rv);
    ProcessBackendPipe processBackendPipe(refMap, typeMap, rv, converted,
                                          &resubmitPackings, &mirrorPackings, bindings);
    processBackendPipe.addDebugHook(options.getDebugHook());
    pipe.push_back(rv->apply(processBackendPipe));
}

void BackendConverter::convert(const IR::P4Program *program, BFN_Options& options) {
    if (options.arch == "v1model") {
        if (Device::currentDevice() == Device::TOFINO) {
            convertV1Program(program, options);
        }
#ifdef HAVE_JBAY
        if (Device::currentDevice() == Device::JBAY) {
            convertV1Program(program, options);
        }
#endif
    } else if (options.arch == "psa" &&
             options.langVersion == CompilerOptions::FrontendVersion::P4_16) {
        if (Device::currentDevice() == Device::TOFINO) {
            convertTnaProgram(program, options);
        }
#ifdef HAVE_JBAY
        if (Device::currentDevice() == Device::JBAY) {
            convertTnaProgram(program, options);
        }
#endif
    } else if ((options.arch == "tna" || options.arch == "t2na") &&
             options.langVersion == CompilerOptions::FrontendVersion::P4_16) {
        if (Device::currentDevice() == Device::TOFINO) {
            convertTnaProgram(program, options);
        }
#ifdef HAVE_JBAY
        if (Device::currentDevice() == Device::JBAY) {
            convertTnaProgram(program, options);
        }
#endif
    } else {
        error("Architecture %s not supported with language version %s", options.arch,
              options.langVersion ==CompilerOptions::FrontendVersion::P4_14 ? "P4_14" :
              options.langVersion ==CompilerOptions::FrontendVersion::P4_16 ? "P4_16" :
              "unknown");
    }
}

}  // namespace BFN
