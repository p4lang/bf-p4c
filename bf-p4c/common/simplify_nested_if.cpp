#include <numeric>
#include <functional>
#include <cmath>
#include "lib/bitvec.h"
#include "simplify_nested_if.h"

namespace P4 {

const IR::Node* DoSimplifyNestedIf::preorder(IR::P4Control* control) {
    if (policy != nullptr && !policy->convert(control))
        prune();  // skip this one
    return control;
}

const IR::Node* DoSimplifyNestedIf::preorder(IR::IfStatement *stmt) {
    prune();

    if (stmt->ifTrue) {
        stack_.push_back(stmt->condition);
        visit(stmt->ifTrue);
        predicates[stmt->ifTrue] = stack_;
        stack_.pop_back(); }

    if (stmt->ifFalse) {
        stack_.push_back(new IR::LNot(stmt->condition));
        visit(stmt->ifFalse);
        stack_.pop_back(); }

    if (stack_.size() == 0) {
        IR::IndexedVector<IR::StatOrDecl> vec;
        auto fold = [](const IR::Expression* a, const IR::Expression* b) {
            return new IR::LAnd(a, b); };
        for (auto p : predicates) {
            auto newcond = std::accumulate(std::next(p.second.rbegin()), p.second.rend(),
                                        p.second.back(), fold);
            vec.push_back(new IR::IfStatement(newcond, p.first, nullptr));
        }
        predicates.clear();
        return new IR::BlockStatement(stmt->srcInfo, vec); }
    return stmt;
}

void DoSimplifyComplexCondition::do_equ(bitvec& val, const IR::Equ* eq) {
    if (auto cst = eq->left->to<IR::Constant>()) {
        if (!policy->check(eq->right))
            return;
        unique_dest = eq->right;
        auto idx = cst->asInt();
        val.setbit(idx);
    } else if (auto cst = eq->right->to<IR::Constant>()) {
        if (!policy->check(eq->left))
            return;
        unique_dest = eq->left;
        auto idx = cst->asInt();
        val.setbit(idx);
    }
}

void DoSimplifyComplexCondition::do_neq(bitvec& val, const IR::Neq* neq) {
    if (auto cst = neq->left->to<IR::Constant>()) {
        auto idx = cst->asInt();
        int width = cst->type->width_bits();
        bitvec negated;
        for (auto v = 0; v < (1 << width); v++) {
            if (idx == v)
                continue;
            negated.setbit(v); }
        val &= negated;
    } else if (auto cst = neq->right->to<IR::Constant>()) {
        auto idx = cst->asInt();
        int width = cst->type->width_bits();
        bitvec negated;
        for (auto v = 0; v < (1 << width); v++) {
            if (idx == v)
                continue;
            negated.setbit(v); }
        val &= negated; }
}

const IR::Node* DoSimplifyComplexCondition::preorder(IR::P4Control* control) {
    if (skip != nullptr && !skip->convert(control))
        prune();  // skip this one
    return control;
}

const IR::Node* DoSimplifyComplexCondition::preorder(IR::LAnd* expr) {
    prune();
    auto ctxt = findOrigCtxt<IR::IfStatement>();
    if (!ctxt)
        return expr;

    if (auto e = expr->left->to<IR::LAnd>()) {
        stack_.push(e);
        visit(expr->left);
        stack_.pop(); }

    if (auto e = expr->right->to<IR::LAnd>()) {
        stack_.push(e);
        visit(expr->right);
        stack_.pop(); }

    if (auto e = expr->left->to<IR::Equ>())
        do_equ(constants, e);
    if (auto e = expr->right->to<IR::Equ>())
        do_equ(constants, e);
    if (auto e = expr->left->to<IR::Neq>())
        do_neq(constants, e);
    if (auto e = expr->right->to<IR::Neq>())
        do_neq(constants, e);

    if (stack_.size() == 0) {
        if (!unique_dest)
            return expr;
        auto idx = constants.ffs(0);
        auto dest_width = unique_dest->type->width_bits();
        auto ret = new IR::Equ(unique_dest->type, unique_dest,
                               new IR::Constant(
                                       IR::Type_Bits::get(dest_width), idx, 10));
        constants.clear();
        unique_dest = nullptr;
        policy->reset();
        return ret; }
    return expr;
}

}  // namespace P4
