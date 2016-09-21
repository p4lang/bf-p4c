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
                dump_cluster_set("lhs_cluster_set..insert", &lhs_cluster_set_i);
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

void Cluster::postorder(const IR::Primitive* primitive)
{
    if(dst_i)
    {
        sanity_check_clusters("postorder.."+primitive->name+"..", dst_i);
    }
    dst_i = nullptr;
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
                    //
                    // a --> (a r)
                    // op b r => b --> (b r a)
                    // all rhs set members must point to lhs set
                    // b, r, a --> (b r a)
                    // remove r, a from lhs set
                    // remove rhs cluster from lhs_cluster_set as rhs cluster subsumed by lhs'
                    //
                    std::set<const PhvInfo::Field *>* dst_map_i_rhs = dst_map_i[rhs];
                    for(auto field: *(dst_map_i[rhs]))
                    {
                        dst_map_i[field] = dst_map_i[lhs];
                        lhs_cluster_set_i.erase(field);
                    }
                    delete dst_map_i_rhs;
                }
            }
            dump_cluster_set("lhs_cluster_set..erase", &lhs_cluster_set_i);
        }
    }
}

void Cluster::sanity_check_clusters(const std::string& msg, const PhvInfo::Field *lhs)
{
    if(lhs && dst_map_i[lhs])
    {
        // b --> (b, d, e),	count b in (b, d, e) = 1
        if(dst_map_i[lhs]->count(lhs) != 1)
        {
            std::cout << "*****sanity FAIL*****cluster member count > 1.." << msg << *lhs << "-->" << *(dst_map_i[lhs]);
        }
        // forall x elem (b, d, e),	x --> (b, d, e)
        for(auto rhs: *(dst_map_i[lhs]))
        {
            if(dst_map_i[rhs] != dst_map_i[lhs])
            {
                std::cout << "*****sanity FAIL*****cluster member pointers inconsistent.." << msg << *lhs << "-->" << *rhs;
            }
        }
    }
}

void Cluster::sanity_check_clusters_unique(const std::string& msg)
{
    // sanity check dst_map_i[] contains unique clusters only
    // forall clusters x,y	x intersect y = 0
    //
    for(auto entry: dst_map_i)
    {
        const PhvInfo::Field *lhs = entry.first;
        if(lhs && dst_map_i[lhs])
        {
            std::set<const PhvInfo::Field *> s1 = *dst_map_i[lhs];
            for(auto entry_2: dst_map_i)
            {
                const PhvInfo::Field *lhs_2 = entry_2.first;
                if(lhs_2 && dst_map_i[lhs_2] && lhs != lhs_2)
                {
                    std::set<const PhvInfo::Field *> s2 = *dst_map_i[lhs_2];
                    std::vector<const PhvInfo::Field *> s3;
                    s3.clear();
                    set_intersection(s1.begin(),s1.end(),s2.begin(),s2.end(), std::back_inserter(s3));
                    if(s3.size())
                    {
                        std::cout << "*****sanity FAIL*****uniqueness.." << msg << *lhs << s1 << "..intersect.." << *lhs_2 << s2 << '=' << s3 << std::endl;
                        dump_cluster_set("lhs", &s1);
                        dump_cluster_set("lhs_2", &s2);
                    }
                }
            }//for
        }
    }
}

void Cluster::end_apply()
{
    for(auto entry: dst_map_i)
    {
        const PhvInfo::Field *lhs = entry.first;
        sanity_check_clusters("end_apply..", lhs);
    }
    //
    // form unique clusters
    // forall x not elem lhs_cluster_set_i, dst_map_i[x] = 0
    //
    std::list<const PhvInfo::Field *> delete_list;
    for(auto entry: dst_map_i)
    {
        const PhvInfo::Field *lhs = entry.first;
        if(lhs && lhs_cluster_set_i.count(lhs) == 0)
        {
            dst_map_i[lhs] = nullptr;
            delete_list.push_back(lhs);
        }
    }
    for(auto fp : delete_list)
    {
        dst_map_i.erase(fp);
    }
    sanity_check_clusters_unique("end_apply..");
}//end_apply

void Cluster::dump_field(const PhvInfo::Field *field)
{
    if(field)
    {
        LOG3("..........." << *field);
    }
    else LOG3("..........." << '-');
}

void Cluster::dump_cluster_set(const std::string& msg, std::set<const PhvInfo::Field *>* cluster_set)
{
    if(cluster_set)
    {
        LOG3(msg << '[');
        for(auto field: *cluster_set)
        {
            dump_field(field); 
        }
        LOG3(msg << ']');
    }
}

std::ostream &operator<<(std::ostream &out, Cluster &cluster)
{
    // iterate through all elements in std::map
    for(auto entry: cluster.dst_map())
    {
	// ignore singleton clusters
        if(entry.second && entry.second->size() > 1)
        {
            out << *(entry.first) << "-->(";
            for (auto entry_2: *(entry.second))
            {
                out << ' ' << *entry_2;
            }
            out << ')' << std::endl;
        }
    }

    return out;
}
