#include "cluster.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

//***********************************************************************************
//
// preorder walk on IR tree to insert field operands in cluster set
// 
//***********************************************************************************

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
                dst_map_i[dst_i] = new std::set<const PhvInfo::Field *>; 	// new std::set
                lhs_unique_i.insert(dst_i);					// lhs_unique set insert field
                dump_cluster_set("lhs_unique..insert", &lhs_unique_i);
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
    std::cout << "*****sanity FAIL**********Operation*****" << operation->toString() << std::endl;

    return true;
}

//***********************************************************************************
//
// postorder walk on IR tree
// 
//***********************************************************************************

void Cluster::postorder(const IR::Primitive* primitive)
{
    if(dst_i)
    {
        sanity_check_clusters("postorder.."+primitive->name+"..", dst_i);
    }
    dst_i = nullptr;
}

//***********************************************************************************
//
// end of IR walk epilogue
// perform sanity checks
// obtain unique clusters
// 
//***********************************************************************************

void Cluster::end_apply()
{
    for(auto entry: dst_map_i)
    {
        const PhvInfo::Field *lhs = entry.first;
        sanity_check_clusters("end_apply..", lhs);
    }
    //
    // form unique clusters
    // forall x not elem lhs_unique_i, dst_map_i[x] = 0
    //
    std::list<const PhvInfo::Field *> delete_list;
    for(auto entry: dst_map_i)
    {
        const PhvInfo::Field *lhs = entry.first;
        if(lhs && lhs_unique_i.count(lhs) == 0)
        {
            dst_map_i[lhs] = nullptr;
            delete_list.push_back(lhs);
        }
    }
    for(auto fp : delete_list)
    {
        dst_map_i.erase(fp);						// erase map key
    }
    sanity_check_clusters_unique("end_apply..");
}//end_apply

//***********************************************************************************
//
// insert field in cluster
//
// map[a]--> cluster(a,x) + insert b
// if b == a
//     [a] --> (a,x)
// if [b]--> ==  [a]-->
//     do nothing
// if [b]-->nullptr
//     (a,x) = (a,x) U b
//     [a],[b] --> (a,x,b) 
// if [b]-->(b,d,x)
//     [a]--> (a,u,v) U (b,d,x)
//     [b(=rhs)] set members --> [a(=lhs)], rhs cluster subsumed by lhs'
//     [b],[d],[x],[a],[u],[v] --> (a,u,v,b,d,x)
//     lhs_unique set - remove(b,d,x)
//     note: [b]-->(b,d,x) & op c d => [c]-->(c,b,d,x), lhs_unique set - insert(c),remove(b,d,x)
//     del (b,d,x) as no map[] key points to (b,d,x) 
// 
//***********************************************************************************

void Cluster::insert_cluster(const PhvInfo::Field *lhs, const PhvInfo::Field *rhs)
{
    if(lhs && dst_map_i[lhs] && rhs)
    {
        if(rhs == lhs)
        {   // b == a
            dst_map_i[lhs]->insert(rhs);
        }
        else
        {
            if(dst_map_i[rhs] != dst_map_i[lhs])
            {   // [b]-->nullptr
                if(! dst_map_i[rhs])
                {
                    dst_map_i[lhs]->insert(rhs);
                    dst_map_i[rhs] = dst_map_i[lhs];
                }
                else
                {   // [b]-->(b,d,x)
                    dst_map_i[lhs]->insert(dst_map_i[rhs]->begin(), dst_map_i[rhs]->end());
                    //
                    std::set<const PhvInfo::Field *>* dst_map_i_rhs = dst_map_i[rhs];
                    for(auto field: *(dst_map_i[rhs]))
                    {
                        dst_map_i[field] = dst_map_i[lhs];
                        lhs_unique_i.erase(field);				// lhs_unique set erase field
                    }
                    delete dst_map_i_rhs;					// delete std::set
                }
            }
            dump_cluster_set("lhs_unique..erase", &lhs_unique_i);
        }
    }
}

//***********************************************************************************
//
// sanity checks
// 
//***********************************************************************************

void Cluster::sanity_check_clusters(const std::string& msg, const PhvInfo::Field *lhs)
{
    if(lhs && dst_map_i[lhs])
    {
        // b --> (b,d,e); count b=1 in (b,d,e)
        if(dst_map_i[lhs]->count(lhs) != 1)
        {
            std::cout << "*****sanity_FAIL*****cluster member count > 1.."
		<< msg << *lhs << "-->" << *(dst_map_i[lhs]) << std::endl;
        }
        // forall x elem (b,d,e), x-->(b,d,e)
        for(auto rhs: *(dst_map_i[lhs]))
        {
            if(dst_map_i[rhs] != dst_map_i[lhs])
            {
                std::cout << "*****sanity_FAIL*****cluster member pointers inconsistent.."
		<< msg << *lhs << "-->" << *rhs << std::endl;
            }
        }
    }
}

void Cluster::sanity_check_clusters_unique(const std::string& msg)
{
    // sanity check dst_map_i[] contains unique clusters only
    // forall clusters x,y
    //		x intersect y = 0
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
                        std::cout << "*****sanity_FAIL*****uniqueness.."
				<< msg << *lhs << s1 << "..intersect.." << *lhs_2 << s2 << '=' << s3 << std::endl;
                        dump_cluster_set("lhs", &s1);
                        dump_cluster_set("lhs_2", &s2);
                    }
                }
            }//for
        }
    }
}

//***********************************************************************************
//
// dumps
// 
//***********************************************************************************

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

//***********************************************************************************
//
// output stream <<
// 
//***********************************************************************************

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
