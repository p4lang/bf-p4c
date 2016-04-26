#ifndef _TOFINO_COMMON_BLOCKMAP_H_
#define _TOFINO_COMMON_BLOCKMAP_H_

#include "ir/ir.h"
#include "frontends/p4/evaluator/evaluator.h"

class FillFromBlockMap : public Transform {
    P4::EvaluatorPass *eval = 0;
    P4::BlockMap *blockMap = 0;
    profile_t init_apply(const IR::Node *root) override {
        if (eval) blockMap = eval->getBlockMap();
        return Transform::init_apply(root); }
    const IR::Expression *preorder(IR::Expression *exp) override {
        if (exp->type == IR::Type::Unknown::get())
            if (auto type = blockMap->typeMap->getType(getOriginal()))
                exp->type = type;
        return exp; }
    const IR::Type *preorder(IR::Type_Name *type) override {
        if (getContext()->node->is<IR::TypeNameExpression>()) return type;
        if (auto decl = blockMap->refMap->getDeclaration(type->path)) {
            if (auto tdecl = decl->getNode()->to<IR::Type_Declaration>())
                return transform_child(tdecl)->to<IR::Type>();
            else
                BUG("Type_Name %1% maps to %2% rather than a type decl", type, decl);
        } else {
            BUG("Type_Name %1% doesn't map to a declaration", type, decl); } }

 public:
    explicit FillFromBlockMap(P4::BlockMap *bm) : blockMap(bm) {}
    explicit FillFromBlockMap(P4::EvaluatorPass *e) : eval(e) {}
};

#endif /* _TOFINO_COMMON_BLOCKMAP_H_ */
