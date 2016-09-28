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
    auto field = phv_i.field(expression->expr);
    LOG3(field);

    insert_cluster(dst_i, field);

    return true;
}

bool Cluster::preorder(const IR::Operation_Binary* expression)
{
    LOG3(".....Binary Operation....." << expression->toString()
	<< '(' << expression->left->toString() << ',' << expression->right->toString() << ')');
    auto left = phv_i.field(expression->left);
    auto right = phv_i.field(expression->right);
    LOG3(left);
    LOG3(right);

    insert_cluster(dst_i, left);
    insert_cluster(dst_i, right);

    return true;
}

bool Cluster::preorder(const IR::Operation_Ternary* expression)
{
    LOG3(".....Ternary Operation....." << expression->toString() 
	<< '(' << expression->e0->toString() << ',' << expression->e1->toString() << ',' << expression->e2->toString()
        << ')');
    auto e0 = phv_i.field(expression->e0);
    auto e1 = phv_i.field(expression->e1);
    auto e2 = phv_i.field(expression->e2);
    LOG3(e0);
    LOG3(e1);
    LOG3(e2);

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
        auto field = phv_i.field(operand);
        LOG3(field);
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
                LOG3("lhs_unique..insert[" << std::endl << &lhs_unique_i << "lhs_unique..insert]");
            }
            for (auto &operand : primitive->operands)
            {
                auto field = phv_i.field(operand);
                insert_cluster(dst_i, field);
            }
        }
    }

    return true;
}

bool Cluster::preorder(const IR::Operation* operation)
{
    // should not reach here
    WARNING("*****cluster.cpp: sanity_FAIL Operation*****" << operation->toString());

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
        auto lhs = entry.first;
        sanity_check_clusters("end_apply..", lhs);
    }
    //
    // form unique clusters
    // forall x not elem lhs_unique_i, dst_map_i[x] = 0
    // remove singleton clusters
    // forall x, dst_map_i[x] == (x), dst_map_i[x] = 0
    //
    std::list<const PhvInfo::Field *> delete_list;
    for(auto entry: dst_map_i)
    {
        auto lhs = entry.first;
        if(lhs && (lhs_unique_i.count(lhs) == 0 || entry.second->size() <= 1))
        {
            dst_map_i[lhs] = nullptr;
            delete_list.push_back(lhs);
        }
    }
    for(auto fp: delete_list)
    {
        dst_map_i.erase(fp);						// erase map key
    }
    sanity_check_clusters_unique("end_apply..");
    //
    MAU_Requirements(*this);
    //
    // output logs
    //
    // all fields
    LOG3(phv_i);
    // all clusters
    LOG3(*this);
}//end_apply

//***********************************************************************************
//
// insert field in cluster
//
// map[a]--> cluster(a,x) + insert b
// if b == a
//     [a]-->(a,x)
// if [b]--> ==  [a]-->
//     do nothing
// if [b]-->nullptr
//     (a,x) = (a,x) U b
//     [a],[b]-->(a,x,b) 
// if [b]-->(b,d,x)
//     [a]-->(a,u,v)U(b,d,x)
//     [b(=rhs)] set members --> [a(=lhs)], rhs cluster subsumed by lhs'
//     [b],[d],[x],[a],[u],[v]-->(a,u,v,b,d,x)
//     lhs_unique set: -remove(b,d,x)
//     note: [b]-->(b,d,x) & op c d => [c]-->(c,b,d,x), lhs_unique set: +insert(c)-remove(b,d,x)
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
                    // [a]-->(a,u,v)U(b,d,x)
                    dst_map_i[lhs]->insert(dst_map_i[rhs]->begin(), dst_map_i[rhs]->end());
                    // [b],[d],[x],[a],[u],[v]-->(a,u,v,b,d,x)
                    // lhs_unique set: -remove(b,d,x)
                    std::set<const PhvInfo::Field *>* dst_map_i_rhs = dst_map_i[rhs];
                    for(auto field: *(dst_map_i[rhs]))
                    {
                        dst_map_i[field] = dst_map_i[lhs];
                        lhs_unique_i.erase(field);				// lhs_unique set erase field
                    }
                    delete dst_map_i_rhs;					// delete std::set
                }
            }
            LOG3("lhs_unique..erase[" << std::endl << &lhs_unique_i << "lhs_unique..erase]");
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
            WARNING("*****cluster.cpp:sanity_FAIL*****cluster member count > 1.." << msg << lhs << "-->" << *(dst_map_i[lhs]));
        }
        // forall x elem (b,d,e), x-->(b,d,e)
        for(auto rhs: *(dst_map_i[lhs]))
        {
            if(dst_map_i[rhs] != dst_map_i[lhs])
            {
                WARNING("*****cluster.cpp:sanity_FAIL*****cluster member pointers inconsistent.." << msg << lhs << "-->" << rhs);
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
        if(entry.first && entry.second)
        {
            std::set<const PhvInfo::Field *> s1 = *(entry.second);
            for(auto entry_2: dst_map_i)
            {
                if(entry_2.first && entry_2.second && entry_2.first != entry.first)
                {
                    std::set<const PhvInfo::Field *> s2 = *(entry_2.second);
                    std::vector<const PhvInfo::Field *> s3;
                    s3.clear();
                    set_intersection(s1.begin(),s1.end(),s2.begin(),s2.end(), std::back_inserter(s3));
                    if(s3.size())
                    {
                        WARNING("*****cluster.cpp:sanity_FAIL*****uniqueness.." << msg
				<< entry.first << s1 << "..^.." << entry_2.first << s2 << '=' << s3);
                        LOG3("lhs[" << std::endl << &s1 << "lhs]");
                        LOG3("lhs_2[" << std::endl << &s2 << "lhs_2]");
                    }
                }
            }//for
        }
    }
}

//***********************************************************************************
//
// output stream <<
// 
//***********************************************************************************

std::ostream &operator<<(std::ostream &out, MAU_Req *m)
{
    if(m)
    {
        out << "[<" << m->cluster_vec().size() << ',' << m->width()
            << ">{" << m->num_containers() << '*' << (int)(m->container_width()) << "}](" << std::endl
            << m->cluster_vec()
            << "[<" << m->cluster_vec().size() << ',' << m->width()
            << ">{" << m->num_containers() << '*' << (int)(m->container_width()) << "}])" << std::endl;
    }
    else
    {
        out << "-m-";
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<MAU_Req *> &mau_req_vec)
{
    out << "++++++++++ #clusters=" << mau_req_vec.size() << " ++++++++++" << std::endl;
    for (auto m: mau_req_vec)
    {
        out << m;
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, std::map<Cluster::MAU_width, std::vector<MAU_Req *>> &mau_req_map)
{
    out << "++++++++++ MAU Requirements ++++++++++" << std::endl;
    for (auto &p: Values(mau_req_map))
    {
        out << p;
    } 

    return out;
}

std::ostream &operator<<(std::ostream &out, std::set<const PhvInfo::Field *> *cluster_set)
{
    if(cluster_set)
    {
        for(auto field: *cluster_set)
        {
            out << field << std::endl;
        }
    }
    else
    {
        out << "[X]" << std::endl;
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<const PhvInfo::Field *>& cluster_vec)
{
    for(auto field: cluster_vec)
    {
        out << field << std::endl;
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, Cluster &cluster)
{
    out << "++++++++++ Clusters ++++++++++" << std::endl;
    // iterate through all elements in dst_map
    for(auto entry: cluster.dst_map())
    {
        if(entry.second)
        {
            out << entry.first << "-->(";
            for (auto entry_2: *(entry.second))
            {
                out << ' ' << entry_2;
            }
            out << ')' << std::endl;
        }
    }
    // mau_req_map
    out << cluster.mau_req_map();

    return out;
}
