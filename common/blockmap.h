#ifndef _TOFINO_COMMON_BLOCKMAP_H_
#define _TOFINO_COMMON_BLOCKMAP_H_

#include "ir/ir.h"
#include "frontends/p4/evaluator/evaluator.h"

class FillFromBlockMap : public Transform {
    P4::ReferenceMap* refMap = nullptr;
    P4::TypeMap* typeMap = nullptr;

    const IR::Expression *preorder(IR::Expression *exp) override {
        if (exp->type == IR::Type::Unknown::get())
            if (auto type = typeMap->getType(getOriginal()))
                exp->type = type;
        return exp; }
    const IR::Type *preorder(IR::Type_Name *type) override {
        if (getContext()->node->is<IR::TypeNameExpression>()) return type;
        if (auto decl = refMap->getDeclaration(type->path)) {
            if (auto tdecl = decl->getNode()->to<IR::Type_Declaration>())
                return transform_child(tdecl)->to<IR::Type>();
            else
                BUG("Type_Name %1% maps to %2% rather than a type decl", type, decl);
        } else {
            BUG("Type_Name %1% doesn't map to a declaration", type, decl); } }

 public:
    FillFromBlockMap(P4::ReferenceMap* refMap, P4::TypeMap* typeMap)
    : refMap(refMap), typeMap(typeMap) {}
};

#endif /* _TOFINO_COMMON_BLOCKMAP_H_ */
