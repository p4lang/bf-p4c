#include "copy_header.h"
#include "frontends/p4/methodInstance.h"

namespace BFN {

const IR::Node* DoCopyHeaders::postorder(IR::AssignmentStatement* statement) {
    if (statement->right->to<IR::ListExpression>() ||
            statement->right->to<IR::StructInitializerExpression>())
        return statement;
    auto ltype = typeMap->getType(statement->left, true);
    if (auto strct = ltype->to<IR::Type_Header>()) {
        auto retval = new IR::IndexedVector<IR::StatOrDecl>();
        // add copy valid bit
        auto validtype = IR::Type::Bits::get(1);
        auto dst = new IR::Member(statement->srcInfo, validtype,
                                  statement->left, "$valid");
        auto src = new IR::Member(statement->srcInfo, validtype,
                                  statement->right, "$valid");
        retval->push_back(new IR::AssignmentStatement(statement->srcInfo, dst, src));
        BUG_CHECK(statement->right->is<IR::PathExpression>() ||
                  statement->right->is<IR::Member>() ||
                  statement->right->is<IR::ArrayIndex>(),
                  "%1%: Unexpected operation when eliminating struct copying",
                  statement->right);

        for (auto f : strct->fields) {
            auto right = new IR::Member(statement->right, f->name);
            auto left = new IR::Member(statement->left, f->name);
            retval->push_back(new IR::AssignmentStatement(statement->srcInfo, left, right));
        }
        return new IR::BlockStatement(statement->srcInfo, *retval);
    } else if (auto stk = ltype->to<IR::Type_Stack>()) {
        auto size = stk->size->to<IR::Constant>();
        BUG_CHECK(size && size->value > 0, "stack %s size is not positive constant", ltype);
        auto retval = new IR::IndexedVector<IR::StatOrDecl>();
        BUG_CHECK(statement->right->is<IR::PathExpression>() ||
                  statement->right->is<IR::Member>() ||
                  statement->right->is<IR::ArrayIndex>(),
                  "%1%: Unexpected operation when eliminating stack copying",
                  statement->right);
        for (int i = 0; i < size->asInt(); ++i) {
            auto right = new IR::ArrayIndex(statement->right, new IR::Constant(i));
            auto left = new IR::ArrayIndex(statement->left, new IR::Constant(i));
            retval->push_back(new IR::AssignmentStatement(statement->srcInfo, left, right));
        }
        return new IR::BlockStatement(statement->srcInfo, *retval);
    }

    return statement;
}

/**
 * convert setValid() and setInvalid() method call to assignment statement on $valid bit
 *
 * This conversion is only needed for P4-16 programs to implement the P4-16 semantics
 * of setValid().
 *
 * For P4-14 programs, the setValid() method call is unmodified, because the LocalCopyProp
 * pass needs the method call to implement the semantics for add_header and remove_header.
 * i.e., when validating an uninitialized header in P4-14, all fields in the header must
 * be initialized to zero.
 */
const IR::Node* DoCopyHeaders::postorder(IR::MethodCallStatement *mc) {
    auto mce = mc->methodCall;
    if (auto mem = mce->method->to<IR::Member>()) {
        if (mem->expr->type->is<IR::Type_Header>()) {
            if (mem->member == IR::Type_Header::isValid) {
                // skip
            } else if (mem->member == IR::Type_Header::setValid) {
                auto validtype = IR::Type::Bits::get(1);
                auto src = new IR::Constant(validtype, 1);
                auto dst = new IR::Member(mc->srcInfo, validtype, mem->expr, "$valid");
                return new IR::AssignmentStatement(mc->srcInfo, dst, src);
            } else if (mem->member == IR::Type_Header::setInvalid) {
                auto validtype = IR::Type::Bits::get(1);
                auto src = new IR::Constant(validtype, 0);
                auto dst = new IR::Member(mc->srcInfo, validtype, mem->expr, "$valid");
                return new IR::AssignmentStatement(mc->srcInfo, dst, src);
            }
        }
    }
    return mc;
}

}  // namespace BFN
