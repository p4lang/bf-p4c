#include "param_binding.h"

void ParamBinding::bind(const IR::Parameter *param) {
    if (!by_type.count(param->type)) {
        LOG1("adding param binding for " << param->name << ": " << param->type->toString());
        by_type.emplace(param->type, new IR::InstanceRef(param->name, param->type)); }
    LOG2("adding param binding for node " << param->id << ": " << param->type->toString());
    by_param[param] = by_type.at(param->type);
}

const IR::Expression *ParamBinding::postorder(IR::PathExpression *pe) {
    if (auto decl = refMap->getDeclaration(pe->path)) {
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
            return iref; }
        LOG3("not collapsing " << mem << " (no nested iref)");
    } else {
        LOG3("not collapsing " << mem << " (not an iref)"); }
    return mem;
}
