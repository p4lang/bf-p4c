#ifndef _TOFINO_COMMON_BLOCKMAP_H_
#define _TOFINO_COMMON_BLOCKMAP_H_

#include "ir/ir.h"
#include "frontends/p4v1.2/evaluator/evaluator.h"

class FillFromBlockMap : public Transform {
    P4V12::EvaluatorPass *eval;
    const IR::Expression *preorder(IR::Expression *exp) {
        if (exp->type == IR::Type::Unknown::get()) {
            if (auto type = eval->getBlockMap()->typeMap->getType(getOriginal()))
                exp->type = type;
            else
                BUG("Expression %1% has no type in typeMap", exp); }
        return exp; }
    const IR::Type *preorder(IR::Type_Name *type) {
        if (auto decl = eval->getBlockMap()->refMap->getDeclaration(type->path)) {
            if (auto tdecl = decl->getNode()->to<IR::Type_Declaration>())
                return transform_child(tdecl)->to<IR::Type>();
            else
                BUG("Type_Name %1% maps to %2% rather than a type decl", type, decl);
        } else {
            BUG("Type_Name %1% doesn't map to a declaration", type, decl); } }
#if 0
    const IR::Node *preorder(IR::PathExpression *exp) {
        if (auto decl = eval->getBlockMap()->refMap->getDeclaration(exp->path)) {
            if (decl->getNode()->is<IR::Parameter>())
                return exp;
            else if (auto n = decl->getNode()->to<IR::Expression>())
                return n;
            else
                BUG("PathExpression %1% maps to non-expression %2%", exp, decl);
        } else {
            BUG("no declaration for path expression %1%", exp); } }
#endif

 public:
    explicit FillFromBlockMap(P4V12::EvaluatorPass *e) : eval(e) {}
};

#endif /* _TOFINO_COMMON_BLOCKMAP_H_ */
