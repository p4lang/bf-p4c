#include "ir/ir.h"
#include "ir/pattern.h"
#include "ir/visitor.h"
#include "simplifyIfStatement.h"
#include "backends/tofino/midend/path_linearizer.h"

namespace P4 {

const IR::Node* ElimCallExprInIfCond::preorder(IR::IfStatement* stmt) {
    prune();
    BUG_CHECK(stack.empty(), "if statement in if condition?");
    visit(stmt->condition, "condition");
    const IR::Node *rv = stmt;
    if (!stack.empty()) {
        auto block = new IR::BlockStatement(stack);
        stack.clear();
        block->push_back(stmt);
        rv = block; }
    visit(stmt->ifTrue, "ifTrue");
    visit(stmt->ifFalse, "ifFalse");
    return rv;
}

const IR::Node* ElimCallExprInIfCond::postorder(IR::MethodCallExpression* methodCall) {
    const Context *ctxt = nullptr;
    auto ifstmt = findContext<IR::IfStatement>(ctxt);
    if (!ifstmt)
        return methodCall;
    if (strcmp(ctxt->child_name, "condition") != 0)
        return methodCall;
    BFN::PathLinearizer linearizer;
    if (auto member = methodCall->method->to<IR::Member>()) {
        if (member->member.name == "isValid" ||
            member->member.name == "apply")
            return methodCall;
        member->expr->apply(linearizer);
    } else if (methodCall->method->to<IR::PathExpression>()) {
        // may need to modify to support function();
        return methodCall;
    } else {
        BUG("Unexpected method call", methodCall);
    }
    auto& path = *linearizer.linearPath;
    auto tempVar = refMap->newName(path.to_cstring());
    auto decl = new IR::Declaration_Variable(tempVar, methodCall->type, methodCall->clone());
    stack.push_back(decl);
    return new IR::PathExpression(tempVar);
}

}   // namespace P4
