#include "extract_maupipe.h"
#include <assert.h>
#include "slice.h"
#include "ir/ir.h"
#include "ir/dbprint.h"
#include "common/name_gateways.h"
#include "frontends/p4-14/inline_control_flow.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/methodInstance.h"
#include "frontends/p4/externInstance.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/common/copy_header_eliminator.h"
#include "bf-p4c/common/pragma/collect_global_pragma.h"
#include "bf-p4c/midend/simplify_references.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/stateful_alu.h"
#include "bf-p4c/mau/table_dependency_graph.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "bf-p4c/parde/deparser_checksum_update.h"
#include "bf-p4c/parde/extract_parser.h"
#include "bf-p4c/parde/gen_deparser.h"
#include "lib/algorithm.h"
#include "lib/error.h"
#include "lib/safe_vector.h"

namespace BFN {

static int getConstant(const IR::Argument* arg) {
    return arg->expression->to<IR::Constant>()->asInt();
}

static int getConstant(const IR::Annotation* annotation) {
    if (annotation->expr.size() != 1) {
        ::error("%1% should contain a constant", annotation);
        return 0;
    }
    auto constant = annotation->expr[0]->to<IR::Constant>();
    if (constant == nullptr) {
        ::error("%1% should contain a constant", annotation);
        return 0;
    }
    return constant->asInt();
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

    void append_extern_constructor_param(const IR::Declaration_Instance *decl,
            cstring externType, IR::Vector<IR::Expression>& constructor_params) {
        // only for Hash extern for now.
        if (externType != "Hash")
            return;
        if (decl->arguments == nullptr)
            return;
        for (auto arg : *decl->arguments) {
            if (!arg->expression->is<IR::PathExpression>())
                continue;
            auto path = arg->expression->to<IR::PathExpression>();
            auto param = refMap->getDeclaration(path->path, false);
            if (auto d = param->to<IR::Declaration_Instance>())
                constructor_params.push_back(new IR::GlobalRef(typeMap->getType(d), d));
        } }

    const IR::Expression *preorder(IR::MethodCallExpression *mc) {
        auto mi = P4::MethodInstance::resolve(mc, refMap, typeMap, true);
        cstring name;
        const IR::Expression *recv = nullptr, *extra_arg = nullptr;
        IR::Vector<IR::Expression> constructor_params;
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
                                         typeMap->getType(n), n);
                // if current extern takes another extern instance as constructor parameter,
                // e.g., Hash takes CRC_Polynomial as an argument.
                if (n->is<IR::Declaration_Instance>())
                    append_extern_constructor_param(n->to<IR::Declaration_Instance>(),
                            em->actualExternType->name,
                            constructor_params);
            }
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
        if (constructor_params.size() != 0)
            prim->operands.append(constructor_params);
        for (auto arg : *mc->arguments)
            prim->operands.push_back(arg->expression);
        if (extra_arg) prim->operands.push_back(extra_arg);
        // if method call returns a value
        return prim;
    }

    const IR::Primitive *postorder(IR::Primitive *prim) {
        if (prim->name == "method_call_init") {
            BUG_CHECK(prim->operands.size() == 1, "method call initialization failed");
            if (auto *p = prim->operands.at(0)->to<IR::Primitive>())
                return p;
            else if (prim->operands.at(0)->is<IR::Member>())
                // comes from a bare "isValid" call -- is a noop
                return nullptr;
            else
                BUG("method call initialization mismatch: %s", prim);
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
    ActionArgSetup          *action_arg_setup;

 public:
    explicit ActionFunctionSetup(ActionArgSetup *aas) :
        action_arg_setup(aas) {
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
            if (prop->isConstant)
                act->is_constant_action = true;
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
        if (!af->exitAction) {
            cstring pname = "modify_field";
            if (assign->left->type->is<IR::Type_Header>())
                pname = "copy_header";
            auto prim = new IR::Primitive(assign->srcInfo, pname, assign->left, assign->right);
            af->action.push_back(prim); }
        return false; }
    bool preorder(const IR::MethodCallStatement *mc) override {
        if (!af->exitAction) {
            auto mc_init = new IR::Primitive(mc->srcInfo, "method_call_init", mc->methodCall);
            af->action.push_back(mc_init); }
        return false;
    }
    bool preorder(const IR::ExitStatement *) override {
        af->exitAction = true;
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

static const IR::MAU::Action *createActionFunction(const IR::P4Action *ac,
                                                   const IR::Vector<IR::Argument> *args) {
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
    ActionFunctionSetup afs(&aas);
    return rv->apply(afs)->to<IR::MAU::Action>();
}

static IR::MAU::AttachedMemory *createIdleTime(cstring name, const IR::Annotations *annot) {
    auto idletime = new IR::MAU::IdleTime(name);

    if (auto s = annot->getSingle("idletime_precision")) {
        idletime->precision = getConstant(s);
        /* Default is 3 */
        if (idletime->precision != 1 && idletime->precision != 2 &&
            idletime->precision != 3 && idletime->precision != 6)
                idletime->precision = 3;
    }

    if (auto s = annot->getSingle("idletime_interval")) {
        idletime->interval = getConstant(s);
        if (idletime->interval < 0 || idletime->interval > 12)
            idletime->interval = 7;
    }

    if (auto s = annot->getSingle("idletime_two_way_notification")) {
        int two_way_notification = getConstant(s);
        if (two_way_notification == 1)
            idletime->two_way_notification = "two_way";
        else if (two_way_notification == 0)
            idletime->two_way_notification = "disable";
    }

    if (auto s = annot->getSingle("idletime_per_flow_idletime")) {
        int per_flow_enable = getConstant(s);
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

/**
  * Checks if there is an annotation of the provided name attached to the match
  * table.  If so, return its integer value.  Since there is no existing
  * use case for a negative annotation value, return negative error code if it does not exist.
  * This function should only be called when there can be a single annotation
  * of the provided name.
  *
  * return codes:
  *    -1 - table doesn't have annotation
  *    -2 - the annotation isn't a constant
  *    -3 - the annotation is not positive
  */
static int getSingleAnnotationValue(const cstring name, const IR::MAU::Table *table) {
    if  (table->match_table) {
        auto annot = table->match_table->getAnnotations();
        if (auto s = annot->getSingle(name)) {
            ERROR_CHECK(s->expr.size() >= 1, "%s: The %s pragma on table %s "
                        "does not have a value", name, table->srcInfo, table->name);
            auto pragma_val =  s->expr.at(0)->to<IR::Constant>();
            if (pragma_val == nullptr) {
                ::error("%s: The %s pragma value on table %s is not a constant",
                        name, table->srcInfo, table->name);
                return -2;
            }
            int value = pragma_val->asInt();
            if (value < 0) {
                ::error("%s: The %s pragma value on table %s cannot be less than zero.",
                        name, table->srcInfo, table->name);
                return -3;
            }
            return value;
        }
    }
    return -1;
}

static void getCRCPolynomialFromExtern(const P4::ExternInstance& instance,
        IR::MAU::HashFunction& hashFunc) {
    if (instance.type->name != "CRCPolynomial") {
        ::error("Expected CRCPolynomial extern instance %1%", instance.type->name);
        return; }
    auto coeffValue = instance.substitution.lookupByName("coeff")->expression;
    BUG_CHECK(coeffValue->to<IR::Constant>(), "Non-constant coeff");
    auto reverseValue = instance.substitution.lookupByName("reversed")->expression;
    BUG_CHECK(reverseValue->to<IR::BoolLiteral>(), "Non-boolean reversed");
    auto msbValue = instance.substitution.lookupByName("msb")->expression;
    BUG_CHECK(msbValue->to<IR::BoolLiteral>(), "Non-boolean msb");
    auto initValue = instance.substitution.lookupByName("init")->expression;
    BUG_CHECK(initValue->to<IR::Constant>(), "Non-constant init");
    auto extendValue = instance.substitution.lookupByName("extended")->expression;
    BUG_CHECK(extendValue->to<IR::BoolLiteral>(), "Non-boolean extend");
    auto xorValue = instance.substitution.lookupByName("xor")->expression;
    BUG_CHECK(xorValue->to<IR::Constant>(), "Non-constant xor");

    hashFunc.msb = msbValue->to<IR::BoolLiteral>()->value;
    hashFunc.extend = extendValue->to<IR::BoolLiteral>()->value;
    hashFunc.reverse = reverseValue->to<IR::BoolLiteral>()->value;
    hashFunc.poly = coeffValue->to<IR::Constant>()->asUint64();
    hashFunc.size = coeffValue->to<IR::Constant>()->type->width_bits() - 1;
    hashFunc.init = initValue->to<IR::Constant>()->asUint64();
    hashFunc.final_xor = xorValue->to<IR::Constant>()->asUint64();
    hashFunc.type = IR::MAU::HashFunction::CRC;
}

/**
 * TODO(hanw): Pass ExternInstance* as a parameter, instead of srcInfo, name, type,
 * substitution, annot.
 * Gated by use in AttachTables::DefineGlobalRefs::postorder(IR::GlobalRef *gref)
 */
static IR::MAU::AttachedMemory *createAttached(Util::SourceInfo srcInfo,
        cstring name, const IR::Type *type, const P4::ParameterSubstitution* substitution,
        const IR::Vector<IR::Type>* typeArgs,
        const IR::Annotations *annot, P4::ReferenceMap *refMap,
        P4::TypeMap* typeMap,
        StatefulSelectors &stateful_selectors,
        const IR::MAU::AttachedMemory **created_ap = nullptr,
        const IR::MAU::Table *match_table = nullptr) {
    auto baseType = getBaseType(type);
    auto tname = getTypeName(baseType);

    if (tname == "ActionSelector") {
        auto sel = new IR::MAU::Selector(srcInfo, name, annot);

        // setup action selector group and group size.
        int num_groups = StageUseEstimate::COMPILER_DEFAULT_SELECTOR_POOLS;
        int max_group_size = StageUseEstimate::SINGLE_RAMLINE_POOL_SIZE;
        bool sps_scramble = true;

        // Check match table for selector pragmas that specify selector properties.
        // P4-14 legacy reasons put these pragmas on the match table rather than
        // the action selector object.
        if (match_table) {
            // Check for max group size pragma.
            int pragma_max_group_size = getSingleAnnotationValue("selector_max_group_size",
                                                                 match_table);
            if (pragma_max_group_size != -1) {
                max_group_size = pragma_max_group_size;
                // max ram words is 992, max members per word is 120
                if (max_group_size < 1 || max_group_size > (992*120)) {
                    ::error("%s: The selector_max_group_size pragma value on table %s is "
                            "not between %d and %d.", match_table->srcInfo,
                            match_table->name, 1, 992*120); } }
            // Check for number of max groups pragma.
            int pragma_num_max_groups = getSingleAnnotationValue("selector_num_max_groups",
                                                                 match_table);
            if (pragma_num_max_groups != -1) {
                num_groups = pragma_num_max_groups;
                if (num_groups < 1) {
                    ::error("%s: The selector_num_max_groups pragma value on table %s is "
                            "not greater than or equal to 1.", match_table->srcInfo,
                             match_table->name); } }
            // Check for selector_enable_scramble pragma.
            int pragma_sps_en = getSingleAnnotationValue("selector_enable_scramble",
                                                         match_table);
            if (pragma_sps_en != -1) {
                if (pragma_sps_en == 0) {
                    sps_scramble = false;
                } else if (pragma_sps_en == 1) {
                    sps_scramble = true;
                } else {
                  ::error("%s: The selector_enable_scramble pragma value on table %s is "
                          "only allowed to be 0 or 1.", match_table->srcInfo,
                           match_table->name);
                }
            }
        }

        sel->sps_scramble = sps_scramble;

        // processing ActionSelector constructor parameters.
        for (auto p : *substitution->getParametersInOrder()) {
            auto arg = substitution->lookup(p);
            if (arg == nullptr)
                continue;
            if (p->name == "mode") {
                if (arg->expression->to<IR::Member>()->member.name == "FAIR")
                    sel->mode = IR::ID("fair");
                else
                    sel->mode = IR::ID("resilient");
            } else if (p->name == "hash") {
                auto inst = P4::ExternInstance::resolve(arg->expression, refMap, typeMap);
                if (inst != boost::none) {
                    if (inst->arguments->size() == 1) {
                        if (!sel->algorithm.setup(inst->arguments->at(0)->expression))
                            BUG("invalid algorithm %s", inst->arguments->at(0)->expression);
                    } else if (inst->arguments->size() == 2) {
                        auto crc_poly = P4::ExternInstance::resolve(
                                inst->arguments->at(1)->expression, refMap, typeMap);
                        if (crc_poly == boost::none)
                            continue;
                        getCRCPolynomialFromExtern(*crc_poly, sel->algorithm);
                    }
                }
            } else if (p->name == "reg") {
                auto regpath = arg->expression->to<IR::PathExpression>()->path;
                auto reg = refMap->getDeclaration(regpath)->to<IR::Declaration_Instance>();
                if (stateful_selectors.count(reg))
                    error("%1% bound to both %2% and %3%", reg, stateful_selectors.at(reg), sel);
                stateful_selectors.emplace(reg, sel);
            } else if (p->name == "max_group_size") {
                max_group_size = getConstant(arg);
                // max ram words is 992, max members per word is 120
                if (max_group_size < 1 || max_group_size > (992*120)) {
                    ::error("%s: The max_group_size value on ActionSelector %s is "
                            "not between %d and %d.", srcInfo, name, 1, 992*120); }
            } else if (p->name == "num_groups") {
                num_groups = getConstant(arg);
                if (num_groups < 1) {
                    ::error("%s: The selector_num_max_groups pragma value on table %s is "
                            "not greater than or equal to 1.", srcInfo, name); }
            } else if (p->name == "action_profile") {
                if (auto path = arg->expression->to<IR::PathExpression>()) {
                    auto af = P4::ExternInstance::resolve(path, refMap, typeMap);
                    if (af == boost::none) {
                        ::error("Expected %1% for ActionSelector %2% to resolve to an "
                                "ActionProfile extern instance", arg, name); }
                    auto ap = new IR::MAU::ActionData(srcInfo, IR::ID(*af->name));
                    ap->direct = false;
                    ap->size = getConstant(af->arguments->at(0));
                    // FIXME Need to reconstruct the field list from the table key?
                    *created_ap = ap;
                }
            } else if (p->name == "size") {
                // XXX(hanw): used to support the deprecated ActionSelector API.
                // ActionSelector(bit<32> size, Hash<_> hash, SelectorMode_t mode);
                // Remove once the deprecated API is removed from
                auto ap = new IR::MAU::ActionData(srcInfo, IR::ID(name));
                ap->direct = false;
                ap->size = getConstant(arg);
                // FIXME Need to reconstruct the field list from the table key?
                *created_ap = ap; }
        }

        sel->num_pools = num_groups;
        sel->max_pool_size = max_group_size;
        sel->size = (sel->max_pool_size + 119) / 120 * sel->num_pools;
        return sel;
    } else if (tname == "ActionProfile") {
        auto ap = new IR::MAU::ActionData(srcInfo, IR::ID(name), annot);
        for (auto p : *substitution->getParametersInOrder()) {
            auto arg = substitution->lookup(p);
            if (arg == nullptr)
                continue;
            if (p->name == "size")
                ap->size = getConstant(arg); }
        return ap;
    } else if (tname == "Counter" || tname == "DirectCounter") {
        auto ctr = new IR::MAU::Counter(srcInfo, name, annot);
        if (tname == "DirectCounter")
            ctr->direct = true;

        for (auto p : *substitution->getParametersInOrder()) {
            auto arg = substitution->lookup(p);
            if (p->name == "type") {
                ctr->settype(arg->expression->as<IR::Member>().member.name);
            } else if (p->name == "size") {
                ctr->size = getConstant(arg);
            } }

        if (typeArgs != nullptr && typeArgs->size() != 0) {
            ctr->min_width = typeArgs->at(0)->width_bits();
        } else {
            ctr->min_width = -1;
        }
        /* min_width comes via Type_Specialized */
        for (auto anno : annot->annotations) {
            if (anno->name == "max_width")
                ctr->max_width = getConstant(anno);
            else if (anno->name == "threshold")
                ctr->threshold = getConstant(anno);
            else if (anno->name == "interval")
                ctr->interval = getConstant(anno);
        }
        return ctr;
    } else if (tname == "Meter") {
        auto mtr = new IR::MAU::Meter(srcInfo, name, annot);
        // Ideally, we would access the arguments by name, however, the P4 frontend IR only
        // populate the 'name' field of IR::Argument when it is used as a named argument.
        // We had to access the name by 'index' and be careful about not to access indices
        // that do not exist.
        for (auto p : *substitution->getParametersInOrder()) {
            auto arg = substitution->lookup(p);
            if (arg == nullptr)
                continue;
            auto expr = arg->expression;
            if (p->name == "size") {
                if (!expr->is<IR::Constant>())
                    ::error(ErrorType::ERR_INVALID, "Invalid Meter size %1%");
                mtr->size = expr->to<IR::Constant>()->asInt();
            } else if (p->name == "type") {
                if (!expr->is<IR::Member>())
                    ::error(ErrorType::ERR_INVALID, "Invalid Meter type %1%, must be"
                                                    "PACKETS or BYTES", expr);
                mtr->settype(arg->expression->as<IR::Member>().member.name);
            } else if (p->name == "red") {
                if (!expr) continue;
                if (!expr->is<IR::Constant>())
                    ::error(ErrorType::ERR_INVALID, "Invalid 'red_value'. "
                                                    "Supported values must be constant.");
                auto red_value = arg->expression->to<IR::Constant>()->asInt();
                if (red_value < 0 || red_value > 255)
                    ::error(ErrorType::ERR_OVERLIMIT, "Invalid 'red_value'."
                                                      "Supported values are in the range [0:255].");
                mtr->red_value = red_value;
            } else if (p->name == "yellow") {
                if (!expr) continue;
                if (!expr->is<IR::Constant>())
                    ::error(ErrorType::ERR_INVALID, "Invalid 'yellow_value'. "
                                                    "Supported values must be constant.");
                auto yellow_value = arg->expression->to<IR::Constant>()->asInt();
                if (yellow_value < 0 || yellow_value > 255)
                    ::error(ErrorType::ERR_OVERLIMIT, "Invalid 'yellow_value'."
                                                      "Supported values are in the range [0:255].");
                mtr->yellow_value = yellow_value;
            } else if (p->name == "green") {
                if (!expr) continue;
                if (!expr->is<IR::Constant>())
                    ::error(ErrorType::ERR_INVALID, "Invalid 'green_value'. "
                                                    "Supported values must be constant.");
                auto green_value = arg->expression->to<IR::Constant>()->asInt();
                if (green_value < 0 || green_value > 255)
                    ::error(ErrorType::ERR_OVERLIMIT, "Invalid 'green_value'."
                                                      "Supported values are in the range [0:255].");
                mtr->green_value = green_value;
            }
        }
        // annotations are supported for p4-14.
        for (auto anno : annot->annotations) {
            if (anno->name == "result")
                mtr->result = anno->expr.at(0);
            else if (anno->name == "implementation")
                mtr->implementation = getString(anno);
            else if (anno->name == "green")
                mtr->green_value = getConstant(anno);
            else if (anno->name == "yellow")
                mtr->yellow_value = getConstant(anno);
            else if (anno->name == "red")
                mtr->red_value = getConstant(anno);
            else if (anno->name == "meter_profile")
                mtr->profile = getConstant(anno);
            else if (anno->name == "meter_sweep_interval")
                mtr->sweep_interval = getConstant(anno);
            else
                WARNING("unknown annotation " << anno->name << " on " << tname); }
        return mtr;
    } else if (tname == "DirectMeter") {
        auto mtr = new IR::MAU::Meter(srcInfo, name, annot);
        mtr->direct = true;
        for (auto p : *substitution->getParametersInOrder()) {
            auto arg = substitution->lookup(p);
            if (arg == nullptr)
                continue;
            auto expr = arg->expression;
            if (p->name == "type") {
                mtr->settype(arg->expression->as<IR::Member>().member.name);
            } else if (p->name == "red") {
                if (!expr) continue;
                if (!expr->is<IR::Constant>())
                    ::error(ErrorType::ERR_INVALID, "Invalid 'red_value'. "
                                                    "Supported values must be constant.");
                auto red_value = arg->expression->to<IR::Constant>()->asInt();
                if (red_value < 0 || red_value > 255)
                    ::error(ErrorType::ERR_OVERLIMIT, "Invalid 'red_value'."
                                                      "Supported values are in the range [0:255].");
                mtr->red_value = red_value;
            } else if (p->name == "yellow") {
                if (!expr) continue;
                if (!expr->is<IR::Constant>())
                    ::error(ErrorType::ERR_INVALID, "Invalid 'yellow_value'. "
                                                    "Supported values must be constant.");
                auto yellow_value = arg->expression->to<IR::Constant>()->asInt();
                if (yellow_value < 0 || yellow_value > 255)
                    ::error(ErrorType::ERR_OVERLIMIT, "Invalid 'yellow_value'."
                                                      "Supported values are in the range [0:255].");
                mtr->yellow_value = yellow_value;
            } else if (p->name == "green") {
                if (!expr) continue;
                if (!expr->is<IR::Constant>())
                    ::error(ErrorType::ERR_INVALID, "Invalid 'green_value'. "
                                                    "Supported values must be constant.");
                auto green_value = arg->expression->to<IR::Constant>()->asInt();
                if (green_value < 0 || green_value > 255)
                    ::error(ErrorType::ERR_OVERLIMIT, "Invalid 'green_value'."
                                                      "Supported values are in the range [0:255].");
                mtr->green_value = green_value;
            } }
        return mtr;
    } else if (tname == "Lpf") {
        auto mtr = new IR::MAU::Meter(srcInfo, name, annot);
        mtr->implementation = IR::ID("lpf");
        for (auto p : *substitution->getParametersInOrder()) {
            auto arg = substitution->lookup(p);
            if (arg == nullptr)
                continue;
            if (p->name == "size") {
                mtr->size = getConstant(arg); } }
        return mtr;
    } else if (tname == "DirectLpf") {
        auto mtr = new IR::MAU::Meter(srcInfo, name, annot);
        mtr->implementation = IR::ID("lpf");
        mtr->direct = true;
        return mtr;
    } else if (tname == "Wred") {
        auto mtr = new IR::MAU::Meter(srcInfo, name, annot);
        mtr->implementation = IR::ID("wred");
        for (auto p : *substitution->getParametersInOrder()) {
            auto arg = substitution->lookup(p);
            if (arg == nullptr)
                continue;
            if (p->name == "size") {
                mtr->size = getConstant(arg);
            } else if (p->name == "drop_value") {
                mtr->red_drop_value = getConstant(arg);
            } else if (p->name == "no_drop_value") {
                mtr->red_nodrop_value = getConstant(arg); } }
        return mtr;
    } else if (tname == "DirectWred") {
        auto mtr = new IR::MAU::Meter(srcInfo, name, annot);
        mtr->implementation = IR::ID("wred");
        mtr->direct = true;
        for (auto p : *substitution->getParametersInOrder()) {
            auto arg = substitution->lookup(p);
            if (arg == nullptr)
                continue;
            if (p->name == "drop_value") {
                mtr->red_drop_value = getConstant(arg);
            } else if (p->name == "no_drop_value") {
                mtr->red_nodrop_value = getConstant(arg); } }
        return mtr;
    }

    LOG2("Failed to create attached table for " << tname);
    return nullptr;
}

/**
 * Helper functions to extract extern instance from table properties.
 * Originally implemented in as part of the control-plane repo.
 */
boost::optional<P4::ExternInstance>
getExternInstanceFromProperty(const IR::P4Table* table,
                              const cstring& propertyName,
                              P4::ReferenceMap* refMap,
                              P4::TypeMap* typeMap) {
    auto property = table->properties->getProperty(propertyName);
    if (property == nullptr) return boost::none;
    if (!property->value->is<IR::ExpressionValue>()) {
        ::error("Expected %1% property value for table %2% to be an expression: %3%",
                propertyName, table->controlPlaneName(), property);
        return boost::none;
    }

    auto expr = property->value->to<IR::ExpressionValue>()->expression;
    auto name = property->controlPlaneName();
    auto externInstance = P4::ExternInstance::resolve(expr, refMap, typeMap, name);
    if (!externInstance) {
        ::error("Expected %1% property value for table %2% to resolve to an "
                "extern instance: %3%", propertyName, table->controlPlaneName(),
                property);
        return boost::none; }

    return externInstance;
}

boost::optional<const IR::ExpressionValue*>
getExpressionFromProperty(const IR::P4Table* table,
                          const cstring& propertyName) {
    auto property = table->properties->getProperty(propertyName);
    if (property == nullptr) return boost::none;
    if (!property->value->is<IR::ExpressionValue>()) {
        ::error("Expected %1% property value for table %2% to be an expression: %3%",
                propertyName, table->controlPlaneName(), property);
        return boost::none;
    }

    auto expr = property->value->to<IR::ExpressionValue>();
    return expr;
}

class FixP4Table : public Inspector {
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
    IR::MAU::Table *tt;
    std::set<cstring> &unique_names;
    DeclarationConversions &converted;
    StatefulSelectors &stateful_selectors;
    DeclarationConversions &assoc_profiles;

    // XXX(hanw): this function only needs one parameter. RefMap and typeMap
    // are passed in as a temporary workaround to avoid larger refactor.
    void createAttachedTableFromTableProperty(P4::ExternInstance& instance,
            P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
        const IR::MAU::AttachedMemory *obj = nullptr;
        const IR::MAU::AttachedMemory *side_obj = nullptr;
        auto tname = cstring::make_unique(unique_names, *instance.name);
        unique_names.insert(tname);
        auto sub = instance.substitution;
        obj = createAttached(instance.expression->srcInfo, tname,
                instance.type, &instance.substitution,
                instance.typeArguments,
                instance.annotations->getAnnotations(),
                refMap, typeMap, stateful_selectors, &side_obj, tt);

        // XXX(hanw): workaround to populate DeclarationConversions and StatefulSelectors.
        // The key to these maps should be ExternInstance, instead of Declaration_Instance,
        // but that require a larger refactor, which can be done later.
        {  // begin workaround
            if (auto path = instance.expression->to<IR::PathExpression>()) {
                auto decl = refMap->getDeclaration(path->path, true);
                if (!decl->is<IR::Declaration_Instance>()) return;

                auto inst = decl->to<IR::Declaration_Instance>();
                auto type = typeMap->getType(inst);
                if (!type) {
                    BUG("Couldn't determine the type of expression: %1%", path);
                }
                if (converted.count(inst) == 0) {
                    converted[inst] = obj;
                    if (side_obj)
                        assoc_profiles[inst] = side_obj;
                } else {
                    obj = converted.at(inst);
                    if (assoc_profiles.count(inst))
                        side_obj = assoc_profiles.at(inst);
                }
            }
        }  // end workaround
        LOG3("attaching " << obj->name << " to " << tt->name);
        tt->attached.push_back(new IR::MAU::BackendAttached(obj->srcInfo, obj));
        if (side_obj)
            tt->attached.push_back(new IR::MAU::BackendAttached(side_obj->srcInfo, side_obj));
    }

    bool preorder(const IR::P4Table *tc) override {
        auto impl = getExternInstanceFromProperty(tc, "implementation", refMap, typeMap);
        if (impl != boost::none) {
            if (impl->type->name == "ActionProfile") {
                createAttachedTableFromTableProperty(*impl, refMap, typeMap);
            } else if (impl->type->name == "ActionSelector") {
                createAttachedTableFromTableProperty(*impl, refMap, typeMap);
            }
        }

        auto counters = getExternInstanceFromProperty(tc, "counters", refMap, typeMap);
        if (counters != boost::none) {
            if (counters->type->name == "DirectCounter") {
                createAttachedTableFromTableProperty(*counters, refMap, typeMap);
            }
        }

        auto meters = getExternInstanceFromProperty(tc, "meters", refMap, typeMap);
        if (meters != boost::none) {
            if (meters->type->name == "DirectMeter") {
                createAttachedTableFromTableProperty(*meters, refMap, typeMap);
            }
        }

        auto timeout = getExpressionFromProperty(tc, "idle_timeout");
        if (timeout != boost::none) {
            auto bool_lit = (*timeout)->expression->to<IR::BoolLiteral>();
            if (bool_lit == nullptr || bool_lit->value == false)
                return false;
            auto annot = tc->getAnnotations();
            auto it = createIdleTime(tc->name, annot);
            tt->attached.push_back(new IR::MAU::BackendAttached(it->srcInfo, it));
        }

        auto atcam = getExternInstanceFromProperty(tc, "atcam", refMap, typeMap);
        if (atcam != boost::none) {
            if (atcam->type->name == "Atcam") {
                tt->layout.partition_count =
                    atcam->arguments->at(0)->expression->to<IR::Constant>()->asInt();
            }
        }

        auto alpm = getExternInstanceFromProperty(tc, "alpm", refMap, typeMap);
        if (alpm != boost::none) {
            if (alpm->type->name == "Alpm") {
                tt->layout.partition_count =
                    alpm->arguments->at(0)->expression->to<IR::Constant>()->asInt();
                tt->layout.subtrees_per_partition =
                    alpm->arguments->at(1)->expression->to<IR::Constant>()->asInt();
            }
        }

        auto hash = getExternInstanceFromProperty(tc, "proxy_hash", refMap, typeMap);
        if (hash != boost::none) {
            if (hash->type->name == "Hash") {
                tt->layout.proxy_hash = true;

                tt->layout.proxy_hash_width =
                    hash->typeArguments->at(0)->width_bits();
                ERROR_CHECK(tt->layout.proxy_hash_width != 0, "ProxyHash width cannot be 0");

                if (hash->arguments->size() == 1) {
                    if (!tt->layout.proxy_hash_algorithm.setup(hash->arguments->at(0)->expression))
                        BUG("invalid algorithm %s", hash->arguments->at(0)->expression);
                } else if (hash->arguments->size() == 2) {
                    auto crc_poly = P4::ExternInstance::resolve(
                            hash->arguments->at(1)->expression, refMap, typeMap);
                    if (crc_poly == boost::none)
                        return false;
                    getCRCPolynomialFromExtern(*crc_poly, tt->layout.proxy_hash_algorithm);
                }
            }
        }
        return false;
    }

 public:
    FixP4Table(P4::ReferenceMap *r, P4::TypeMap* tm, IR::MAU::Table *tt, std::set<cstring> &u,
               DeclarationConversions &con, StatefulSelectors &ss, DeclarationConversions &ap)
    : refMap(r), typeMap(tm), tt(tt), unique_names(u), converted(con),
      stateful_selectors(ss), assoc_profiles(ap) {}
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
        // Reg initialization values for lo/hi are passed as annotations. In
        // p4_14 conversion they cannot be set directly on the register For
        // p4_16 programs these are passed in as optional stateful params
        for (auto annot : ext->annotations->annotations) {
            if (annot->name == "initial_register_lo_value") {
                salu->init_reg_lo = getConstant(annot);
                warning(ErrorType::WARN_DEPRECATED, "%s is deprecated, use the initial_value "
                        "argument of the Register constructor instead", annot);
                LOG4("Reg initial lo value: " << salu->init_reg_lo); }
            if (annot->name == "initial_register_hi_value") {
                salu->init_reg_hi = getConstant(annot);
                warning(ErrorType::WARN_DEPRECATED, "%s is deprecated, use the initial_value "
                        "argument of the Register constructor instead", annot);
                LOG4("Reg initial hi value: " << salu->init_reg_hi); } }
        if (seltype) {
            salu->direct = false;
            auto sel = self.converted.at(reg)->to<IR::MAU::Selector>();
            ERROR_CHECK(sel, "%s: Could not find the associated selector within the stateful "
                        "ALU %s, even though a selector is specified", gref->srcInfo,
                         salu->name);
            if (self.stateful_selectors.count(reg))
                error("%1% bound to both %2% and %3%", reg, self.stateful_selectors.at(reg), sel);
            salu->selector = sel;
            // FIXME -- how are selector table sizes set?  It seems to be lost in P4_16
            salu->size = 120*1024;  // one ram?
        } else if (regtype->toString().startsWith("Register<")) {
            salu->direct = false;
            salu->size = getConstant(reg->arguments->at(0));
        } else {
            salu->direct = true; }
        if (self.stateful_selectors.count(reg))
            salu->selector = self.stateful_selectors.at(reg);
        if (regtype) {
            salu->width = regtype->arguments->at(0)->width_bits();
            if (auto str = regtype->arguments->at(0)->to<IR::Type_Struct>())
                salu->dual = str->fields.size() > 1;
            if (reg->arguments->size() > !salu->direct) {
                auto *init = reg->arguments->at(!salu->direct)->expression;
                // any malformed initial value should have been diagnoesd already, so no need
                // for error messages here
                if (auto *k = init->to<IR::Constant>()) {
                    salu->init_reg_lo = k->asInt();
                } else if (auto *l = init->to<IR::ListExpression>()) {
                    if (l->size() >= 1) {
                        if (auto *k = l->components.at(0)->to<IR::Constant>())
                            salu->init_reg_lo = k->asInt(); }
                    if (l->size() >= 2) {
                        if (auto *k = l->components.at(1)->to<IR::Constant>())
                            salu->init_reg_hi = k->asInt(); } } }
        } else {
            salu->width = 1; }
        if (auto cts = reg->annotations->getSingle("chain_total_size"))
            salu->chain_total_size = getConstant(cts);
        salu_inits[reg] = salu; }

    // copy annotations from register action
    IR::Annotations *new_annot = nullptr;
    for (auto annot : ext->annotations->annotations) {
        if (annot->name == "name") continue;
        if (auto old = salu->annotations->getSingle(annot->name)) {
            if (old->expr.equiv(annot->expr)) continue;
            warning("Conflicting annotations %s and %s related to stateful alu %s",
                    annot, old, salu); }
        if (!new_annot) new_annot = salu->annotations->clone();
        new_annot->add(annot); }
    if (new_annot) salu->annotations = new_annot;

    if (auto red_or = ext->annotations->getSingle("reduction_or_group")) {
        auto pragma_val = red_or->expr.at(0)->to<IR::StringLiteral>();
        ERROR_CHECK(pragma_val, "%s: Please provide a valid reduction_or_group for, which should "
                    "be a string %s", salu->srcInfo, salu->name);
        if (pragma_val) {
            if (salu->reduction_or_group.isNull()) {
                salu->reduction_or_group = pragma_val->value;
            } else {
                ERROR_CHECK(salu->reduction_or_group == pragma_val->value, "%s: Stateful ALU %s"
                    "cannot have multiple reduction or group", salu->srcInfo, salu->name);
            }
        }
    }
    if (ext->type->toString().startsWith("LearnAction"))
        salu->learn_action = true;

    // If the register action hasn't been seen before, this creates an SALU Instruction
    if (register_actions.count(ext) == 0) {
        LOG3("Adding " << ext->name << " to StatefulAlu " << reg->name);
        register_actions.insert(ext);
        if (!inst_ctor[salu]) {
            // Create exactly one CreateSaluInstruction per SALU and reuse it for all the
            // instructions in that SALU, so we can accumulate info in it.
            inst_ctor[salu] = new CreateSaluInstruction(salu); }
        ext->apply(*inst_ctor[salu]); }

    auto prim = findContext<IR::Primitive>();
    LOG6("  - " << (prim ? prim->name : "<no primitive>"));
    if (prim && prim->name.endsWith(".address")) {
        salu->chain_vpn = true;
        return; }
    auto tbl = findContext<IR::MAU::Table>();
    LOG6("  - table " << (tbl ? tbl->name : "<no table>"));
    auto act = findContext<IR::MAU::Action>();
    LOG6("  - action " << (act ? act->name : "<no action>"));
    auto ta_pair = tbl->name + "-" + act->name.originalName;
    if (!salu->action_map.emplace(ta_pair, ext->name).second)
        error("%s: multiple calls to execute in action %s", gref->srcInfo, act->name);
}

bool AttachTables::isSaluActionType(const IR::Type *type) {
    static std::set<cstring> saluActionTypes = {
        "DirectRegisterAction", "DirectRegisterAction2", "DirectRegisterAction3",
        "DirectRegisterAction4",
        "LearnAction", "LearnAction2", "LearnAction3", "LearnAction4",
        "MinMaxAction", "MinMaxAction2", "MinMaxAction3", "MinMaxAction4",
        "RegisterAction", "RegisterAction2", "RegisterAction3", "RegisterAction4",
        "SelectorAction" };
    cstring tname = type->toString();
    tname = tname.before(tname.find('<'));
    return saluActionTypes.count(tname) > 0;
}

void AttachTables::InitializeStatefulAlus::postorder(const IR::GlobalRef *gref) {
    visitAgain();
    if (auto di = gref->obj->to<IR::Declaration_Instance>()) {
        if (isSaluActionType(di->type)) {
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
        auto inst = P4::Instantiation::resolve(di, refMap, typeMap);
        const IR::MAU::AttachedMemory *obj = nullptr;
        if (self.converted.count(di)) {
            obj = self.converted.at(di);
            gref->obj = obj;
        } else if (auto att = createAttached(di->srcInfo, di->externalName(),
                                             di->type, &inst->substitution,
                                             inst->typeArguments, di->annotations,
                                             refMap, typeMap, self.stateful_selectors,
                                             nullptr, nullptr)) {
            LOG3("Created " << att->node_type_name() << ' ' << att->name << " (pt 3)");
            gref->obj = self.converted[di] = att;
            obj = att;
        } else if (isSaluActionType(di->type)) {
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
    StatefulSelectors                           &stateful_selectors;
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
                    gress_t gr, const IR::MAU::TableSeq *&rv, DeclarationConversions &con,
                    StatefulSelectors &ss)
    : refMap(refMap), typeMap(typeMap), gress(gr), rv(rv), converted(con), stateful_selectors(ss) {}

 private:
    void setup_match_mask(IR::MAU::Table *tt, const IR::Mask *mask, IR::ID match_id,
                          int p4_param_order, boost::optional<cstring> ann,
                          boost::optional<cstring> partition_index) {
        auto slices = convertMaskToSlices(mask);
        for (auto slice : slices) {
            auto ixbar_read = new IR::MAU::TableKey(slice, match_id);
            ixbar_read->from_mask = true;
            if (ixbar_read->for_match())
                ixbar_read->p4_param_order = p4_param_order;
            if (ann) {
                ixbar_read->annotations = ixbar_read->annotations->addAnnotationIfNew(
                   IR::Annotation::nameAnnotation,
                   new IR::StringLiteral(*ann)); }
            if (partition_index && ann && (*partition_index == *ann))
                ixbar_read->partition_index = true;
            tt->match_key.push_back(ixbar_read);
        }
    }

    void setup_tt_match(IR::MAU::Table *tt, const IR::P4Table *table) {
        auto *key = table->getKey();
        if (key == nullptr)
            return;
        int p4_param_order = 0;

        boost::optional<cstring> partition_index = boost::make_optional(false, cstring());
        // Fold 'atcam_partition_index' annotation into InputXbarRead IR node.
        auto annot = table->getAnnotations();
        auto s = annot->getSingle("atcam_partition_index");
        if (s)
            partition_index = s->expr.at(0)->to<IR::StringLiteral>()->value;

        for (auto key_elem : key->keyElements) {
            // Get name annotation, if present.
            boost::optional<cstring> ann = boost::make_optional(false, cstring());
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
                setup_match_mask(tt, mask, match_id, p4_param_order, ann, partition_index);
            } else if (auto *mask = key_expr->to<IR::Mask>()) {
                setup_match_mask(tt, mask, match_id, p4_param_order, ann, partition_index);
            } else if (match_id.name == "atcam_partition_index") {
                auto ixbar_read = new IR::MAU::TableKey(key_expr, match_id);
                ixbar_read->partition_index = true;
                ixbar_read->p4_param_order = p4_param_order;
                tt->match_key.push_back(ixbar_read);
            } else {
                auto ixbar_read = new IR::MAU::TableKey(key_expr, match_id);
                if (ixbar_read->for_match())
                    ixbar_read->p4_param_order = p4_param_order;
                if (ann) {
                    ixbar_read->annotations = ixbar_read->annotations->addAnnotationIfNew(
                       IR::Annotation::nameAnnotation,
                       new IR::StringLiteral(*ann));
                }
                if (partition_index && ann && (*partition_index == *ann))
                    ixbar_read->partition_index = true;
                tt->match_key.push_back(ixbar_read);
            }
            if (match_id.name != "selector" && match_id.name != "dleft_hash")
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
            auto newaction = createActionFunction(decl, mce->arguments);
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
        for (auto el : b->components) {
            if (tables.count(el))
                seqs.at(b)->tables.push_back(tables.at(el));
            if (seqs.count(el))
                for (auto tbl : seqs.at(el)->tables)
                    seqs.at(b)->tables.push_back(tbl); } }
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
                table->apply(FixP4Table(refMap, typeMap, tt, unique_names, converted,
                        stateful_selectors, assoc_profiles))->to<IR::P4Table>();
            setup_tt_match(tt, table);
            setup_actions(tt, table);
            LOG3("tt " << tt);
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
            if (c->label->is<IR::DefaultExpression>()) {
                label = "$default";
            } else {
                label = refMap->getDeclaration(c->label->to<IR::PathExpression>()->path)
                              ->getName().originalName;
                if (tt->actions.at(label)->exitAction) {
                    warning("Action %s in table %s exits unconditionally", c->label,
                            tt->externalName());
                    label = cstring(); } }
            if (c->statement) {
                auto n = getseq(c->statement);
                if (label)
                    tt->next.emplace(label, n);
                for (auto ft : fallthrough)
                    tt->next.emplace(ft, n);
                fallthrough.clear();
            } else if (label) {
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
    bool preorder(const IR::BFN::TnaControl *cf) override {
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

    void postorder(const IR::BFN::TnaControl *mau) override {
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

struct ExtractChecksum : public Inspector {
    explicit ExtractChecksum(IR::BFN::Pipe* rv) :
        rv(rv) { setName("ExtractChecksumNative"); }

    void postorder(const IR::BFN::TnaDeparser* deparser) override {
        extractChecksumFromDeparser(deparser, rv);
    }

    IR::BFN::Pipe* rv;
};

// used by backend for tna architecture
ProcessBackendPipe::ProcessBackendPipe(P4::ReferenceMap *refMap, P4::TypeMap *typeMap,
                                       IR::BFN::Pipe *rv, DeclarationConversions &converted,
                                       StatefulSelectors ss,
                                       ParamBinding *bindings) {
    setName("ProcessBackendPipe");
    CHECK_NULL(bindings);
    auto simplifyReferences = new SimplifyReferences(bindings, refMap, typeMap);
    auto useV1model = (BackendOptions().arch == "v1model");
    addPasses({
        new AttachTables(refMap, typeMap, converted, ss),  // add attached tables
        new ProcessParde(rv, useV1model),           // add parde metadata
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
    if (auto di = decl->to<IR::Declaration_Instance>()) {
        if (auto expr = di->arguments->at(index)->expression) {
            if (auto path = expr->to<IR::PathExpression>()) {
                auto name = path->path->name;
                return name;
            }
        }
    }
    // If no declaration found (anonymous instantiation) we get the pipe name
    // from arch definition
    auto main = toplevel->getMain();
    auto cparams = main->getConstructorParameters();
    auto idxParam = cparams->getParameter(index);
    BUG_CHECK(idxParam, "No constructor parameter found for index %d in main", index);
    return idxParam->name;
}

void BackendConverter::convertTnaProgram(const IR::P4Program* program, BFN_Options& options) {
    auto main = toplevel->getMain();
    DeclarationConversions converted;
    StatefulSelectors stateful_selectors;
    main->apply(*arch);

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
            if (!arch->threads.count(std::make_pair(npipe, gress))) {
                ::error("Unable to find thread %1%", npipe);
                return; }
            auto thread = arch->threads.at(std::make_pair(npipe, gress));
            thread = thread->apply(*simplifyReferences);
            if (auto mau = thread->mau->to<IR::BFN::TnaControl>()) {
                mau->apply(ExtractMetadata(rv, bindings));
                mau->apply(GetBackendTables(refMap, typeMap, gress, rv->thread[gress].mau,
                                            converted, stateful_selectors));
            }
            for (auto p : thread->parsers) {
                if (auto parser = p->to<IR::BFN::TnaParser>()) {
                    parser->apply(ExtractParser(refMap, typeMap, rv, arch));
                }
            }
            if (auto dprsr = thread->deparser->to<IR::BFN::TnaDeparser>()) {
                dprsr->apply(ExtractDeparser(refMap, typeMap, rv));
                dprsr->apply(ExtractChecksum(rv));
            }
        }
        if (arch->threads.count(std::make_pair(npipe, GHOST))) {
            auto thread = arch->threads.at(std::make_pair(npipe, GHOST));
            thread = thread->apply(*simplifyReferences);
            if (auto mau = thread->mau->to<IR::BFN::TnaControl>()) {
                mau->apply(ExtractMetadata(rv, bindings));
                mau->apply(GetBackendTables(refMap, typeMap, GHOST, rv->ghost_thread,
                                            converted, stateful_selectors));
            }
        }

        rv->global_pragmas = collect_pragma.global_pragmas();

        ProcessBackendPipe processBackendPipe(refMap, typeMap, rv, converted,
                                              stateful_selectors, bindings);
        processBackendPipe.addDebugHook(options.getDebugHook());

        pipe.push_back(rv->apply(processBackendPipe));
        npipe++;

        // clear DeclarationConversions map after the conversion of each pipeline.
        converted.clear();
    }
}

}  // namespace BFN
