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
    LOG3(".....Unary Operation....." << expression->toString()
	<< '(' << expression->expr->toString() << ')');
    const PhvInfo::Field *field = phv_i.field(expression->expr);
    dump_field(field);

    insert_cluster(dst_i, field);

    return true;
}

bool Cluster::preorder(const IR::Operation_Binary* expression)
{
    LOG3(".....Binary Operation....." << expression->toString()
	<< '(' << expression->left->toString() << ',' << expression->right->toString() << ')');
    const PhvInfo::Field *left = phv_i.field(expression->left);
    const PhvInfo::Field *right = phv_i.field(expression->right);
    dump_field(left);
    dump_field(right);

    insert_cluster(dst_i, left);
    insert_cluster(dst_i, right);

    return true;
}

bool Cluster::preorder(const IR::Operation_Ternary* expression)
{

    LOG3(".....Ternary Operation....." << expression->toString() 
	<< '(' << expression->e0->toString() << ',' << expression->e1->toString() << ',' << expression->e2->toString()
        << ')');
    const PhvInfo::Field *e0 = phv_i.field(expression->e0);
    const PhvInfo::Field *e1 = phv_i.field(expression->e1);
    const PhvInfo::Field *e2 = phv_i.field(expression->e2);
    dump_field(e0);
    dump_field(e1);
    dump_field(e2);

    insert_cluster(dst_i, e0);
    insert_cluster(dst_i, e1);
    insert_cluster(dst_i, e2);

    return true;
}

bool Cluster::preorder(const IR::Primitive* primitive)
{
    LOG3(".....Primitive:Operation....." << primitive->name);
    for (auto &operand : primitive->operands)
    {
        const PhvInfo::Field *field = phv_i.field(operand);
        dump_field(field);
    }
    dst_i = nullptr; 
    if (! primitive->operands.empty())
    {
        dst_i = phv_i.field(primitive->operands[0]);
        if(dst_i)
        {
            if(! dst_map_i[dst_i])
            {
                dst_map_i[dst_i] = new std::set<const PhvInfo::Field *>; 
                lhs_cluster_set_i.insert(dst_i);
                dump_lhs_cluster_set("insert");
            }
            for (auto &operand : primitive->operands)
            {
                const PhvInfo::Field *field = phv_i.field(operand);
                insert_cluster(dst_i, field);
            }
        }
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
                    std::set<const PhvInfo::Field *>* dst_map_i_rhs = dst_map_i[rhs];
                    for(auto iter = dst_map_i_rhs->begin(); iter != dst_map_i_rhs->end(); iter++)
                    {
                        dst_map_i[*iter] = dst_map_i[lhs];
                    }
                    delete dst_map_i_rhs;
                }
            }
            // remove rhs from lhs_cluster_set as rhs cluster subsumed by lhs'
            lhs_cluster_set_i.erase(rhs);
            dump_lhs_cluster_set("erase");
        }
    }
}

void Cluster::end_apply()
{
    // sanity check clusters
    // (i) b elem (b, d, e)
    // (ii) forall x elem (b, d, e), x --> (b, d, e)
    //
    for(auto iter = dst_map_i.begin(); iter != dst_map_i.end(); iter++)
    {
        const PhvInfo::Field *lhs = iter->first;
        if(lhs && iter->second)
        {
            // b elem (b, d, e)
            if(iter->second->count(lhs) != 1)
            {
                std::cout << "*****cluster.cpp:end_apply():sanity_check_1 failed*****" << *lhs;
            }
            // forall x elem (b, d, e), x --> (b, d, e)
            for(auto it = iter->second->begin(); it != iter->second->end(); it++)
            {
                const PhvInfo::Field *rhs = *it;
                if(dst_map_i[rhs] != dst_map_i[lhs])
                {
                    std::cout << "*****cluster.cpp:end_apply():sanity_check_2 failed*****" << *lhs << "-->" << *rhs;
                }
            }
        }
    }
    //
    // form unique clusters
    // forall x not elem lhs_cluster_set_i, dst_map_i[x] = 0
    //
    for(auto iter = dst_map_i.begin(); iter != dst_map_i.end(); iter++)
    {
        const PhvInfo::Field *lhs = iter->first;
        if(lhs && lhs_cluster_set_i.count(lhs) == 0)
        {
            dst_map_i[lhs] = nullptr;
        }
    }
    //
    // sanity check dst_map_i[] contains unique clusters only
    // forall clusters x, y  x intersection y = 0
    //
    for(auto iter = dst_map_i.begin(); iter != dst_map_i.end(); iter++)
    {
        const PhvInfo::Field *lhs = iter->first;
        if(lhs && dst_map_i[lhs])
        {
            for(auto it = dst_map_i.begin(); it != dst_map_i.end(); it++)
            {
                const PhvInfo::Field *lhs_2 = it->first;
                if(lhs_2 && dst_map_i[lhs_2] && lhs != lhs_2)
                {
                    std::set<const PhvInfo::Field *> s1 = *dst_map_i[lhs];
                    std::set<const PhvInfo::Field *> s2 = *dst_map_i[lhs_2];
                    std::vector<const PhvInfo::Field *> s3;
                    set_intersection(s1.begin(),s1.end(),s2.begin(),s2.end(), std::back_inserter(s3));
                    if(s3.size())
                    {
                        //std::cout << "*****cluster.cpp:end_apply():sanity_check_3 failed*****" << s1 << "intersect" << s2 << '=' << s3 << std::endl;
                    }
                }
            }//for
        }
    }
}//end_apply

void Cluster::dump_field(const PhvInfo::Field *field)
{
    if(field)
    {
        LOG3("..........." << *field);
    }
    else LOG3("..........." << '-');
}

void Cluster::dump_lhs_cluster_set(const std::string& msg)
{
    LOG3(".....lhs_cluster_set....." << msg << '[');
    for(auto iter = lhs_cluster_set_i.begin(); iter != lhs_cluster_set_i.end(); iter++)
    {
        dump_field(*iter); 
    }
    LOG3(".....lhs_cluster_set.....]");
}

std::ostream &operator<<(std::ostream &out, Cluster &cluster)
{
    // iterate through all elements in std::map
    for(auto iter = cluster.dst_map().begin(); iter != cluster.dst_map().end(); iter++)
    {
	// ignore singleton clusters
        if(iter->second && iter->second->size() > 1)
        {
            out << *(iter->first) << "-->(";
            auto it = iter->second->begin();
                out << *(*it);
                it++;
            for (; it != iter->second->end(); it++)
            {
                out << ", ";
                out << *(*it);
            }
            out << ')' << std::endl;
        }
    }

    return out;
}
