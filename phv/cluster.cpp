#include "cluster.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

bool Cluster::preorder(const IR::Member* expression)
{
    // class Member : Operation_Unary
    // toString = expr->toString() + "." + member

    LOG3(".....Member....." << expression->toString());

    return true;
}

bool Cluster::preorder(const IR::Operation_Unary* expression)
{
    const PhvInfo::Field *expr = phv.field(expression->expr);

    LOG3(".....Unary Operation....." << expression->toString()
	<< '(' << expression->expr->toString() << ')');
    if(expr)
    {
        LOG3('(');
        LOG3(*expr);
        LOG3(')');
    }

    return true;
}

bool Cluster::preorder(const IR::Operation_Binary* expression)
{
    const PhvInfo::Field *left = phv.field(expression->left);
    const PhvInfo::Field *right = phv.field(expression->right);

    LOG3(".....Binary Operation....." << expression->toString()
	<< '(' << expression->left->toString() << ',' << expression->right->toString() << ')');
    if(left || right)
    {
        LOG3('(');
        if(left) LOG3(*left); else LOG3('-');
        if(right) LOG3(*right); else LOG3('-');
        LOG3(')');
    }

    return true;
}

bool Cluster::preorder(const IR::Operation_Ternary* expression)
{
    const PhvInfo::Field *e0 = phv.field(expression->e0);
    const PhvInfo::Field *e1 = phv.field(expression->e1);
    const PhvInfo::Field *e2 = phv.field(expression->e2);

    LOG3(".....Ternary Operation....." << expression->toString() 
	<< '(' << expression->e0->toString() << ',' << expression->e1->toString() << ',' << expression->e2->toString()
        << ')');
    if(e0 || e1 || e2)
    {
        LOG3('(');
        if(e0) LOG3(*e0); else LOG3('-');
        if(e1) LOG3(*e1); else LOG3('-');
        if(e2) LOG3(*e2); else LOG3('-');
        LOG3(')');
    }

    return true;
}

bool Cluster::preorder(const IR::Primitive* primitive)
{

    LOG3(".....Primitive:Operation....." << primitive->name);
    if (! primitive->operands.empty())
    {
        LOG3('(');
        for (auto &operand : primitive->operands)
        {
            const PhvInfo::Field *field = phv.field(operand);
            if(field) LOG3(*field); else LOG3('-');
        }
        LOG3(')');
    }

    return true;
}

bool Cluster::preorder(const IR::Operation* operation)
{

    // should not reach here
    LOG3("*****Operation*****" << operation->toString());

    return true;
}
