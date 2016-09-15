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
    const PhvInfo::Field *field = phv_i.field(expression->expr);

    LOG3(".....Unary Operation....." << expression->toString()
	<< '(' << expression->expr->toString() << ')');
    if(field)
    {
        LOG3('(');
        dst_map_i[dst_i].insert(field);
        LOG3(*field);
        LOG3(')');
    }

    return true;
}

bool Cluster::preorder(const IR::Operation_Binary* expression)
{
    const PhvInfo::Field *left = phv_i.field(expression->left);
    const PhvInfo::Field *right = phv_i.field(expression->right);

    LOG3(".....Binary Operation....." << expression->toString()
	<< '(' << expression->left->toString() << ',' << expression->right->toString() << ')');
    if(left || right)
    {
        LOG3('(');
        if(left)
        {
            dst_map_i[dst_i].insert(left);
            LOG3(*left);
        }
        else LOG3('-');
        if(right)
        {
            dst_map_i[dst_i].insert(right);
            LOG3(*right);
        }
        else LOG3('-');
        LOG3(')');
    }

    return true;
}

bool Cluster::preorder(const IR::Operation_Ternary* expression)
{
    const PhvInfo::Field *e0 = phv_i.field(expression->e0);
    const PhvInfo::Field *e1 = phv_i.field(expression->e1);
    const PhvInfo::Field *e2 = phv_i.field(expression->e2);

    LOG3(".....Ternary Operation....." << expression->toString() 
	<< '(' << expression->e0->toString() << ',' << expression->e1->toString() << ',' << expression->e2->toString()
        << ')');
    if(e0 || e1 || e2)
    {
        LOG3('(');
        if(e0)
        {
            dst_map_i[dst_i].insert(e0);
            LOG3(*e0);
        }
        else LOG3('-');
        if(e1)
        {
            dst_map_i[dst_i].insert(e1);
            LOG3(*e1);
        }
        else LOG3('-');
        if(e2)
        {
            dst_map_i[dst_i].insert(e2);
            LOG3(*e2);
        }
        else LOG3('-');
        LOG3(')');
    }

    return true;
}

bool Cluster::preorder(const IR::Primitive* primitive)
{
    LOG3(".....Primitive:Operation....." << primitive->name);
    if (! primitive->operands.empty())
    {
        dst_i = phv_i.field(primitive->operands[0]);
        // assert dst_i;
        LOG3('(');
        for (auto &operand : primitive->operands)
        {
            const PhvInfo::Field *field = phv_i.field(operand);
            if(field)
            {
                dst_map_i[dst_i].insert(field);
                LOG3(*field);
            }
            else LOG3('-');
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

std::ostream &operator<<(std::ostream &out, Cluster &cluster)
{
    // iterate through all elements in std::map
    for(std::map<PhvInfo::Field *, std::set<const PhvInfo::Field *>>::iterator it = cluster.dst_map().begin();
	it != cluster.dst_map().end();
	it++)
    {
        std::cout << it->first << "-->"<< it->second << std::endl;
    }
    //for (std::set<std::string>::iterator it=setOfNumbers.begin(); it!=setOfNumbers.end(); ++it)
    //{
        //std::cout << ' ' << *it;
    //}

    return out;
}
