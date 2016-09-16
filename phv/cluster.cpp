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
        insert_cluster(dst_i, field);
        LOG3('(');
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
            insert_cluster(dst_i, left);
            LOG3(*left);
        }
        else LOG3('-');
        if(right)
        {
            insert_cluster(dst_i, right);
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
            insert_cluster(dst_i, e0);
            LOG3(*e0);
        }
        else LOG3('-');
        if(e1)
        {
            insert_cluster(dst_i, e1);
            LOG3(*e1);
        }
        else LOG3('-');
        if(e2)
        {
            insert_cluster(dst_i, e2);
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
    dst_i = nullptr; 
    if (! primitive->operands.empty())
    {
        dst_i = phv_i.field(primitive->operands[0]);
        // assert dst_i;
        if(! dst_map_i[dst_i])
        {
            dst_map_i[dst_i] = new std::set<const PhvInfo::Field *>; 
        }
        LOG3('(');
        for (auto &operand : primitive->operands)
        {
            const PhvInfo::Field *field = phv_i.field(operand);
            if(field)
            {
                insert_cluster(dst_i, field);
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

void Cluster::insert_cluster(const PhvInfo::Field *lhs, const PhvInfo::Field *rhs)
{
    // a, b
    // if (b == a)
    //     (a) = a
    // if(b --> ==  a-->)
    //     do nothing
    // if(b --> nullptr)
    //     (a) = (a) U b
    //     b --> (a) 
    // if(b == (b d ...))
    //     (a) = (a) U (b)
    //     (b) --> (a)
    //     del (b) -- no opd points to (b) 
    //
    if(lhs && dst_map_i[lhs] && rhs)
    {
        if(rhs == lhs)
        {   // (a) = a
            dst_map_i[lhs]->insert(rhs);
        }
        else
        {
            if(dst_map_i[rhs] != dst_map_i[lhs])
            {
                // b --> nullptr
                if(! dst_map_i[rhs])
                {
                    dst_map_i[lhs]->insert(rhs);
                    dst_map_i[rhs] = dst_map_i[lhs];
                }
                else
                {
                    // b = (b d ...)
                    dst_map_i[lhs]->insert(dst_map_i[rhs]->begin(), dst_map_i[rhs]->end());
                    // all rhs set members must point to lhs set
                    //for(auto iter = dst_map_i[rhs]->begin(); iter != dst_map_i[rhs]->end(); iter++)
                    {
                        //dst_map_i[*iter] = dst_map_i[lhs];
                    }
                    //delete dst_map_i[rhs];
                }
            }
        }
    }
}

std::ostream &operator<<(std::ostream &out, Cluster &cluster)
{
    // iterate through all elements in std::map
    for(auto iter = cluster.dst_map().begin(); iter != cluster.dst_map().end(); iter++)
    {
	// ignore singleton clusters
        if(iter->second && iter->second->size() > 1)
        {
            std::cout << *(iter->first) << "-->(";
            auto it = iter->second->begin();
                std::cout << *(*it);
                it++;
            for (; it != iter->second->end(); it++)
            {
                std::cout << ", ";
                std::cout << *(*it);
            }
            std::cout << ')' << std::endl;
        }
    }

    return out;
}
