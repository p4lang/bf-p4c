#include "elim_emit_headers.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/methodInstance.h"

DoEliminateEmitHeaders::DoEliminateEmitHeaders(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) :
    refMap(refMap), typeMap(typeMap) { setName("EliminateEmitHeaders"); }

const IR::Node* DoEliminateEmitHeaders::preorder(IR::Argument *arg) {
    const IR::Type* type = nullptr;
    if (auto path = arg->expression->to<IR::PathExpression>()) {
        if (path->type->is<IR::Type_StructLike>())
            type = path->type->to<IR::Type_StructLike>();
        else
            return arg;
    } else if (auto mem = arg->expression->to<IR::Member>()) {
        if (mem->type->is<IR::Type_StructLike>())
            type = mem->type->to<IR::Type_StructLike>();
        else
            return arg; }

    if (!type) return arg;

    auto mc = findContext<IR::MethodCallExpression>();
    if (!mc) return arg;

    auto mi = P4::MethodInstance::resolve(mc, refMap, typeMap, true);
    if (auto em = mi->to<P4::ExternMethod>()) {
        if (em->actualExternType->name != "Digest" &&
            em->actualExternType->name != "Mirror" &&
            em->actualExternType->name != "Resubmit")
            return arg; }

    auto fieldList = IR::Vector<IR::Expression>();
    if (auto header = type->to<IR::Type_Header>()) {
        for (auto f : header->fields) {
            auto mem = new IR::Member(arg->expression, f->name);
            fieldList.push_back(mem); }
    } else if (auto st = type->to<IR::Type_Struct>()) {
        for (auto f : st->fields) {
            auto mem = new IR::Member(arg->expression, f->name);
            fieldList.push_back(mem); } }

    if (fieldList.size())
        return new IR::Argument(arg->srcInfo, new IR::ListExpression(fieldList));

    return arg;
}
