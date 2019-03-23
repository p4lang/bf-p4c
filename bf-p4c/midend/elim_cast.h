#ifndef BF_P4C_MIDEND_ELIM_CAST_H_
#define BF_P4C_MIDEND_ELIM_CAST_H_

#include "ir/ir.h"
#include "frontends/p4/simplify.h"
#include "frontends/p4/typeMap.h"
#include "frontends/p4/strengthReduction.h"
#include "bf-p4c/midend/type_checker.h"
#include "bf-p4c/common/slice.h"

namespace BFN {

/**
 * Open issues, the following expressions are not yet handled.
 *  1. (bit<64>)(h.h.a << h.h.b)
 *  2. cast in register action apply functions
 *  3. ++ operator in method call.
 */

/**
 * This pass will simplify the complex expression with multiple casts
 * into simpler expression with at most one cast, e.g.:
 *
 * int<8> i8 = 8s1;
 * bit<16> h1 = (bit<16>)(bit<8>)i8;
 *
 * will be translated to:
 *
 * int<8> i8 = 8s1;
 * bit<8> b8 = (bit<8>)i8;  // RHS is represented with IR::BFN::ReinterpretCast
 * bit<16> h1 = 8w0++b8;
 *
 */
class EliminateWidthCasts : public Transform {
 public:
    EliminateWidthCasts() { }
    const IR::Node* preorder(IR::Cast* cast) override;

#if 0
    // Caveat(hanw): do not simplify cast in apply functions.
    // stateful_alu implementation must handle '++'
    // before we can eliminate cast.
    const IR::Node* preorder(IR::Function* func) override {
        prune();
        return func; }
#endif

    // Caveat(hanw): we do not simplify the cast in a selection expression,
    // because we do not support '++' operator with a constant lhs.
    // Further, simplifying the selection expression has impact on
    // pvs control plan API generation that needs to be discussed with
    // Steve and Yuan.
    const IR::Node* preorder(IR::SelectExpression *expr) override {
        prune();
        return expr; }
};

/**
 * This pass converts IR::Cast to IR::BFN::ReinterpretCast for the following
 * cases:
 *   - cast from bit<W> to int<W>
 *   - cast from int<W> to bit<W>
 *   - cast from bit<1> to bool
 *   - cast from bool to bit<1>
 *
 * IR::BFN::ReinterpretCast is handled in the backend.
 */
class RewriteCastToReinterpretCast : public Transform {
    P4::TypeMap* typeMap;

 public:
    explicit RewriteCastToReinterpretCast(P4::TypeMap* typeMap) : typeMap(typeMap) {}
    const IR::Node* preorder(IR::Cast* expression) override {
        const IR::Type *srcType = expression->expr->type;
        const IR::Type *dstType = expression->destType;

        if (srcType->is<IR::Type_Boolean>() || dstType->is<IR::Type_Boolean>()) {
            auto retval = new IR::BFN::ReinterpretCast(expression->srcInfo,
                                                       expression->destType, expression->expr);
            typeMap->setType(retval, expression->destType);
            return retval;
        } else if (srcType->is<IR::Type_Bits>() && dstType->is<IR::Type_Bits>()) {
            if (srcType->width_bits() != dstType->width_bits())
                return expression;
            if (srcType->to<IR::Type_Bits>()->isSigned != dstType->to<IR::Type_Bits>()->isSigned) {
                auto retval = new IR::BFN::ReinterpretCast(expression->srcInfo,
                                                           expression->destType, expression->expr);
                typeMap->setType(retval, expression->destType);
                return retval; }
        }
        return expression;
    }
};

/**
 * This pass removes redundant casts in the following cases:
 *
 * int<w> val = (int<w>)(bit<w>)(v); where the type of v is int<w>
 * bit<w> val = (bit<w>)(int<w>)(v); where the type of v is bit<w>
 * int<w> val = (int<w>)(v); where the type of v is int<w>
 * bit<w> val = (bit<w>)(v); where the type of v is bit<w>
 *
 * This usually happens as the result of a copy-propagation.
 */
class SimplifyRedundantCasts : public Transform {
 public:
    SimplifyRedundantCasts() {}

    const IR::Node* preorder(IR::Cast* expression) override {
        const IR::Type *srcType = expression->expr->type;
        const IR::Type *dstType = expression->destType;

        if (!srcType->is<IR::Type_Bits>() || !dstType->is<IR::Type_Bits>())
            return expression;

        if (srcType->width_bits() != dstType->width_bits())
            return expression;

        if (expression->expr->is<IR::Cast>()) {
            const IR::Cast *innerCast = expression->expr->to<IR::Cast>();
            if (srcType->to<IR::Type_Bits>()->isSigned == dstType->to<IR::Type_Bits>()->isSigned)
                return expression;
            if (dstType->width_bits() == innerCast->expr->type->width_bits())
                return innerCast->expr;
        } else {
            if (srcType->to<IR::Type_Bits>()->isSigned != dstType->to<IR::Type_Bits>()->isSigned)
                return expression;
            if (dstType->width_bits() == srcType->width_bits())
                return expression->expr;
        }

        return expression;
    }
};

/**
 * This pass removes nested casts with the same signs, e.g.:
 *
 * bit<10> md;
 * bit<10> b = (bit<10>)(bit<32>)(md);
 *
 * which should be simplified to
 *
 * bit<10> b = md;
 *
 * Caveat: we currently do not support more than two levels of casting.
 */
class SimplifyNestedCasts : public Transform {
 public:
    SimplifyNestedCasts() {}

    const IR::Node* preorder(IR::Cast* expression) override {
        if (!expression->expr->is<IR::Cast>())
            return expression;

        const IR::Type *dstType = expression->destType;
        auto secondCast = expression->expr->to<IR::Cast>();

        // stop if not a nested cast
        if (!secondCast)
            return expression;

        // stop if more than two levels of nested casts.
        if (secondCast->expr->is<IR::Cast>()) {
            ::error("Expression %1% is too complex to handle, "
                    "consider simplifying the nested casts.", expression);
            return expression; }

        const IR::Type *srcType = secondCast->destType;
        auto innerExpr = secondCast->expr;

        if (!srcType->is<IR::Type_Bits>() || !dstType->is<IR::Type_Bits>() ||
                !innerExpr->type->is<IR::Type_Bits>())
            return expression;

        // only handle (bit<a>)(bit<b>)(bit<c>)
        if (srcType->to<IR::Type_Bits>()->isSigned ||
            dstType->to<IR::Type_Bits>()->isSigned ||
            innerExpr->type->to<IR::Type_Bits>()->isSigned)
            return expression;

        // given a expression (bit<a>)(bit<b>)(md), where the type of md is
        // bit<c>, we need to handle the following four cases:
        // case 1: a > b > c, the expression should be simplified to (bit<a>)(md);
        // case 2: a > b < c, the expression should be simplified to (bit<a>)(slice(md, b-1, 0))
        //    we reject this expression for now.
        // case 3: a < b > c, the expression should be simplified to (bit<a>)(md);
        // case 4: a < b < c, the expression should be simplified to (bit<a>)(md);
        if (dstType->width_bits() <= srcType->width_bits()) {
            return new IR::Cast(dstType, innerExpr);
        } else if (dstType->width_bits() > srcType->width_bits() &&
                   srcType->width_bits() > innerExpr->type->width_bits()) {
            return new IR::Cast(dstType, innerExpr);
        } else {
            ::error("Expression %1% is too complex to handle, "
                    "consider simplifying the nested casts.", expression); }

        return expression;
    }
};

/**
 * This pass moves the cast on a binary operation to each operand.
 * This transformation does not apply to all binary operations,
 * and it is not sound if the operands are int type. So it is a best effort.
 * It also does not handle (bool)(expr binop expr), where binop is bitwise operation.
 *
 * We only simplifies add/sub, addsat/subsat,
 * bitwise operations (and, or, xor) on unsigned bit types.
 */
class SimplifyOperationBinary : public Transform {
 public:
    SimplifyOperationBinary() {}
    const IR::Node* preorder(IR::Cast *expression) {
        if (!expression->expr->is<IR::Operation_Binary>())
            return expression;

        // cannot cast lhs and rhs to boolean on
        // a bitwise binary operation.
        if (expression->destType->is<IR::Type_Boolean>())
            return expression;

        auto binop = expression->expr->to<IR::Operation_Binary>();
        IR::Expression* left = nullptr;
        IR::Expression* right = nullptr;

        // do not simplify if any operand is not bit type
        if (!binop->left->type->is<IR::Type_Bits>() || !binop->right->type->is<IR::Type_Bits>())
            return expression;

        // do not simplify if any operand is signed bit type
        if (binop->left->type->to<IR::Type_Bits>()->isSigned ||
            binop->right->type->to<IR::Type_Bits>()->isSigned)
            return expression;

        if (expression->type->width_bits() > binop->type->width_bits()) {
            // widening cast
            if (binop->is<IR::Add>() || binop->is<IR::Sub>() || binop->is<IR::Mul>() ||
                binop->is<IR::AddSat>() || binop->is<IR::SubSat>()) {
                // would change carry/overflow/saturate behavior, so can't do it.
                return expression; }
        } else if (expression->type->width_bits() < binop->type->width_bits()) {
            // narrowing cast
            if (binop->is<IR::AddSat>() || binop->is<IR::SubSat>() ||
                binop->is<IR::Div>() || binop->is<IR::Mod>()) {
                // would change saturate or rounding behavior, so can't do it.
                return expression; } }

        if (binop->left->is<IR::Constant>()) {
            auto cst = binop->left->to<IR::Constant>();
            left = new IR::Constant(expression->destType, cst->value, cst->base);
        } else {
            left = new IR::Cast(expression->destType, binop->left); }

        if (binop->right->is<IR::Constant>()) {
            auto cst = binop->right->to<IR::Constant>();
            right = new IR::Constant(expression->destType, cst->value, cst->base);
        } else {
            right = new IR::Cast(expression->destType, binop->right); }

        if (auto op = expression->expr->to<IR::Add>())
            return new IR::Add(op->srcInfo, left, right);
        if (auto op = expression->expr->to<IR::Sub>())
            return new IR::Sub(op->srcInfo, left, right);
        if (auto op = expression->expr->to<IR::AddSat>())
            return new IR::AddSat(op->srcInfo, left, right);
        if (auto op = expression->expr->to<IR::SubSat>())
            return new IR::SubSat(op->srcInfo, left, right);
        if (auto op = expression->expr->to<IR::BAnd>())
            return new IR::BAnd(op->srcInfo, left, right);
        if (auto op = expression->expr->to<IR::BOr>())
            return new IR::BOr(op->srcInfo, left, right);
        if (auto op = expression->expr->to<IR::BXor>())
            return new IR::BXor(op->srcInfo, left, right);
        return expression;
    }
};

struct SliceInfo {
    int hi;
    int lo;
    const IR::Expression* expr;

    SliceInfo(int hi, int lo, const IR::Expression* expr) :
            hi(hi), lo(lo), expr(expr) {}
};

/** replace concat ++ operations with mulitple operations on slices in the contexts
 * where it works
 *  - immediately on the RHS of an assignment
 *  - directly in an == or != comparison
 */
class RewriteConcatToSlices : public Transform {
 public:
    RewriteConcatToSlices() {}

    // do not simplify '++' in apply functions.
    const IR::Node* preorder(IR::Function* func) override {
        prune();
        return func; }

    const IR::Node* preorder(IR::AssignmentStatement* stmt) override {
        if (auto c = stmt->right->to<IR::Concat>()) {
            auto *rv = new IR::BlockStatement;
            int rsize = c->right->type->width_bits();
            int lsize = c->left->type->width_bits();
            rv->components.push_back(new IR::AssignmentStatement(stmt->srcInfo,
                MakeSlice(stmt->left, rsize, rsize + lsize - 1), c->left));
            rv->components.push_back(new IR::AssignmentStatement(stmt->srcInfo,
                MakeSlice(stmt->left, 0, rsize - 1), c->right));
            return rv;
        }
        return stmt;
    }
    const IR::Node* preorder(IR::Equ *eq) override {
        if (auto c = eq->left->to<IR::Concat>()) {
            int rsize = c->right->type->width_bits();
            int lsize = c->left->type->width_bits();
            return new IR::LAnd(
                new IR::Equ(eq->srcInfo, c->left, MakeSlice(eq->right, rsize, rsize + lsize - 1)),
                new IR::Equ(eq->srcInfo, c->right, MakeSlice(eq->right, 0, rsize - 1))); }
        if (auto c = eq->right->to<IR::Concat>()) {
            int rsize = c->right->type->width_bits();
            int lsize = c->left->type->width_bits();
            return new IR::LAnd(
                new IR::Equ(eq->srcInfo, MakeSlice(eq->left, rsize, rsize + lsize - 1), c->left),
                new IR::Equ(eq->srcInfo, MakeSlice(eq->left, 0, rsize - 1), c->right)); }
        return eq;
    }
    const IR::Node* preorder(IR::Neq *ne) override {
        if (auto c = ne->left->to<IR::Concat>()) {
            int rsize = c->right->type->width_bits();
            int lsize = c->left->type->width_bits();
            return new IR::LOr(
                new IR::Neq(ne->srcInfo, c->left, MakeSlice(ne->right, rsize, rsize + lsize - 1)),
                new IR::Neq(ne->srcInfo, c->right, MakeSlice(ne->right, 0, rsize - 1))); }
        if (auto c = ne->right->to<IR::Concat>()) {
            int rsize = c->right->type->width_bits();
            int lsize = c->left->type->width_bits();
            return new IR::LOr(
                new IR::Neq(ne->srcInfo, MakeSlice(ne->left, rsize, rsize + lsize - 1), c->left),
                new IR::Neq(ne->srcInfo, MakeSlice(ne->left, 0, rsize - 1), c->right)); }
        return ne;
    }
};

class StrengthReduction : public PassManager {
 public:
    StrengthReduction(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
        passes.push_back(new BFN::TypeChecking(refMap, typeMap, true));
        passes.push_back(new P4::DoStrengthReduction());
    }
};

class ElimCasts : public PassManager {
 public:
    ElimCasts(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
        addPasses({
           new SimplifyOperationBinary(),
           new PassRepeated({
               new SimplifyNestedCasts(),
               new SimplifyRedundantCasts()}),
           new RewriteCastToReinterpretCast(typeMap),
           new EliminateWidthCasts(),
           // FIXME -- StrengthReduction has problems with complex nested things like
           // (0 ++ field << 1)[15:0] (from brig-405), which causes problems for Rewrite
           // so we repeat until a fixed point is reached.
           new PassRepeated({new StrengthReduction(refMap, typeMap)}),
           new RewriteConcatToSlices(),
           new P4::SimplifyControlFlow(refMap, typeMap),
           new P4::ClearTypeMap(typeMap),
           new BFN::TypeChecking(refMap, typeMap, true),
        });
    }
};

}  // namespace BFN

#endif  /* BF_P4C_MIDEND_ELIM_CAST_H_ */
