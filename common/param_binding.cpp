#include "param_binding.h"

void ParamBinding::bind(const IR::Parameter *param) {
    auto *type = param->type->to<IR::Type_StructLike>();
    if (!type)
        BUG("Unhandled structlike type %1%", param->type);
    if (!by_type.count(type)) {
        LOG1("adding param binding for " << param->name << ": " << type->name);
        by_type.emplace(type, new IR::InstanceRef(param->name, type)); }
    LOG2("adding param binding for node " << param->id << ": " << type->name);
    by_param[param] = by_type.at(type);
}

const IR::Expression *ParamBinding::postorder(IR::PathExpression *pe) {
    if (auto decl = blockMap->refMap->getDeclaration(pe->path)) {
        if (auto param = decl->getNode()->to<IR::Parameter>()) {
            if (auto ref = get(param)) {
                LOG2("binding " << pe << " to " << ref);
                return ref;
            } else {
                LOG3("no binding for " << param); }
        } else {
            LOG3(decl << " is not a parameter"); }
    } else {
        LOG3("nothing in blockMap for " << pe); }
    return pe;
}

const IR::Expression *ParamBinding::postorder(IR::Member *mem) {
    if (auto iref = mem->expr->to<IR::InstanceRef>()) {
        if ((iref = iref->nested.get<IR::InstanceRef>(mem->member))) {
            LOG2("collapsing " << mem << " to " << iref);
            return iref; } }
    LOG3("not collapsing " << mem);
    return mem;
}
