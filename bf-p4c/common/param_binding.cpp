#include "param_binding.h"

#include "frontends/p4/typeMap.h"

void ParamBinding::bind(const IR::Parameter *param) {
    auto *type = typeMap->getType(param);
    if (!type->is<IR::Type_StructLike>()) return;
    if (!by_type.count(type)) {
        LOG1("adding param binding for " << param->name << ": " << type->toString());
        by_type.emplace(type, new IR::InstanceRef(param->name, type)); }
    LOG2("adding param binding for node " << param->id << ": " <<
         type->toString() << ' ' << param->name);
    by_param[param] = by_type.at(type);
}

void ParamBinding::bind(const IR::Declaration_Variable *var) {
    if (by_declvar[var]) return;
    LOG2("creating instance for var " << var->name);
    by_declvar[var] = new IR::InstanceRef(var->name, typeMap->getType(var), true);
}


void ParamBinding::postorder(const IR::Parameter *param) {
    auto *type = typeMap->getType(param);
    if (!type->is<IR::Type_StructLike>()) return;
    if (!by_type.count(type)) {
        LOG1("adding param binding for " << param->name << ": " << type->toString());
        by_type.emplace(type, new IR::InstanceRef(param->name, type)); }
    LOG2("adding param binding for node " << param->id << ": " <<
        type->toString() << ' ' << param->name);
    by_param[param] = by_type.at(type);
}

void ParamBinding::postorder(const IR::Declaration_Variable *var) {
    if (by_declvar[var]) return;
    LOG2("creating instance for var " << var->name);
    by_declvar[var] = new IR::InstanceRef(var->name, typeMap->getType(var), true);
}
