#include "elim_emit_headers.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/methodInstance.h"

EliminateEmitHeaders::EliminateEmitHeaders(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) :
    refMap(refMap), typeMap(typeMap) { setName("EliminateEmitHeaders"); }

const IR::Node* EliminateEmitHeaders::preorder(IR::Argument *arg) {
    if (!arg->expression->to<IR::PathExpression>())
        return arg;

    auto path = arg->expression->to<IR::PathExpression>();

    if (!path->type->is<IR::Type_StructLike>())
        return arg;

    auto mc = findContext<IR::MethodCallExpression>();
    if (!mc) return arg;

    auto mi = P4::MethodInstance::resolve(mc, refMap, typeMap, true);
    if (auto em = mi->to<P4::ExternMethod>()) {
        if (em->actualExternType->name != "Digest" &&
            em->actualExternType->name != "Mirror" &&
            em->actualExternType->name != "Resubmit")
            return arg; }

    auto fieldList = IR::Vector<IR::Expression>();
    if (auto header = path->type->to<IR::Type_Header>()) {
        for (auto f : header->fields) {
            auto mem = new IR::Member(path, f->name);
            fieldList.push_back(mem); }
    } else if (auto st = path->type->to<IR::Type_Struct>()) {
        for (auto f : st->fields) {
            auto mem = new IR::Member(path, f->name);
            fieldList.push_back(mem); } }

    if (fieldList.size())
        return new IR::Argument(arg->srcInfo, new IR::ListExpression(fieldList));

    return arg;
}
