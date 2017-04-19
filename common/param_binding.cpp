#include "param_binding.h"

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

const IR::Expression *ParamBinding::postorder(IR::PathExpression *pe) {
    if (auto decl = refMap->getDeclaration(pe->path)) {
        if (auto param = decl->to<IR::Parameter>()) {
            if (auto ref = get(param)) {
                LOG2("binding " << pe << " to " << ref);
                return ref;
            } else {
                LOG3("no binding for " << param); }
        } else if (auto var = decl->to<IR::Declaration_Variable>()) {
            if (!by_declvar[var]) {
                LOG2("creating instance for var " << var->name);
                by_declvar[var] = new IR::InstanceRef(var->name, typeMap->getType(var), true);
            } else {
                LOG3("returning instance for var " << var->name); }
            return by_declvar[var];
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

/**
 * Split extern method calls that refer to a complex objects (non-header structs or stacks)
 * such calls need to be split to refer to each field or element of the stack.
 * These are (currently) just 'extract' and 'emit' methods.  They need to be split to
 * only extract a single header at a time.
 * We do this as a perorder function so after splitting, we'll recursively visit the split
 * children, splitting further as needed.
 */
const IR::Node *SplitComplexInstanceRef::preorder(IR::MethodCallStatement *mc) {
    if (mc->methodCall->arguments->size() == 0) return mc;
    auto dest = mc->methodCall->arguments->at(0)->to<IR::InstanceRef>();
    if (!dest) return mc;
    if (auto hs = dest->obj->to<IR::HeaderStack>()) {
        auto *rv = new IR::Vector<IR::StatOrDecl>;
        for (int idx = 0; idx < hs->size; ++idx) {
            auto *split = mc->methodCall->clone();
            auto *args = split->arguments->clone();
            split->arguments = args;
            for (auto &op : *args)
                if (auto ir = op->to<IR::InstanceRef>())
                    if (ir->obj == hs)
                        op = new IR::HeaderStackItemRef(ir, new IR::Constant(idx));
            rv->push_back(new IR::MethodCallStatement(mc->srcInfo, split)); }
        return rv;
    } else if (!dest->nested.empty()) {
        auto *rv = new IR::Vector<IR::StatOrDecl>;
        for (auto nest : dest->nested) {
            auto *split = mc->methodCall->clone();
            auto *args = split->arguments->clone();
            split->arguments = args;
            for (auto &op : *args)
                if (auto ir = op->to<IR::InstanceRef>())
                    op = ir->nested.at(nest.first);
            rv->push_back(new IR::MethodCallStatement(mc->srcInfo, split)); }
        return rv; }
    return mc;
}
