/**
 * \defgroup SimplifyIfStatement P4::SimplifyIfStatement
 * \ingroup midend
 * \brief Set of passes that simplify if statements.
 */
#ifndef EXTENSIONS_BF_P4C_MIDEND_SIMPLIFYIFSTATEMENT_H_
#define EXTENSIONS_BF_P4C_MIDEND_SIMPLIFYIFSTATEMENT_H_

#include "ir/ir.h"
#include "frontends/p4/typeMap.h"
#include "frontends/p4/simplify.h"
#include "frontends/common/resolveReferences/resolveReferences.h"

namespace P4 {

/**
 * \ingroup SimplifyIfStatement
 * \brief Pass that eliminates call expressions in if statement’s condition.
 *
 * Eliminating CallExpr in IfStatement condition
 *
 *     if (extern.methodcall() == 1w0) {
 *        ...
 *     }
 *
 * transform it to
 *
 *     bit<1> tmp = extern.methodcall();
 *     if (tmp == 1w0) {
 *         ...
 *     }
 *
 */

class ElimCallExprInIfCond : public Transform {
    ReferenceMap* refMap;

 public:
    ElimCallExprInIfCond(ReferenceMap* refMap, TypeMap*) : refMap(refMap) {}
    const IR::Node* preorder(IR::IfStatement* statement) override;
    const IR::Node* postorder(IR::MethodCallExpression* methodCall) override;

    IR::IndexedVector<IR::StatOrDecl> stack;
};

/**
 * \ingroup SimplifyIfStatement
 * \brief Top level PassManager that governs simplification of if statements.
 * 
 */
class SimplifyIfStatement : public PassManager {
 public:
    SimplifyIfStatement(ReferenceMap* refMap, TypeMap* typeMap) {
        passes.push_back(new ElimCallExprInIfCond(refMap, typeMap));
        passes.push_back(new SimplifyControlFlow(typeMap));
    }
};

}  // namespace P4

#endif  /* EXTENSIONS_BF_P4C_MIDEND_SIMPLIFYIFSTATEMENT_H_ */
