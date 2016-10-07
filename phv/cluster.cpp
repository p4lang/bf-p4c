#include "cluster.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

//***********************************************************************************
//
// Cluster::Cluster constructor
// 
//***********************************************************************************

Cluster::Cluster(PhvInfo &p) : phv_i(p)
{
    for (auto field: phv_i)
    {
        dst_map_i[&field] = nullptr;
    }
}

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
    PhvInfo::Field::bitrange bits;
    bits.lo = bits.hi = 0;
    auto field = phv_i.field(expression->expr, &bits);

    LOG3(field);

    set_field_range(field, bits);
    insert_cluster(dst_i, field);

    return true;
}

bool Cluster::preorder(const IR::Operation_Binary* expression)
{
    LOG3(".....Binary Operation....." << expression->toString()
	<< '(' << expression->left->toString() << ',' << expression->right->toString() << ')');
    PhvInfo::Field::bitrange left_bits;
    left_bits.lo = left_bits.hi = 0;
    auto left = phv_i.field(expression->left, &left_bits);

    PhvInfo::Field::bitrange right_bits;
    right_bits.lo = right_bits.hi = 0;
    auto right = phv_i.field(expression->right, &right_bits);

    LOG3(left);
    LOG3(right);

    set_field_range(left, left_bits);
    set_field_range(right, right_bits);

    insert_cluster(dst_i, left);
    insert_cluster(dst_i, right);

    return true;
}

bool Cluster::preorder(const IR::Operation_Ternary* expression)
{
    LOG3(".....Ternary Operation....." << expression->toString() 
	<< '(' << expression->e0->toString() << ',' << expression->e1->toString() << ',' << expression->e2->toString()
        << ')');
    PhvInfo::Field::bitrange e0_bits;
    e0_bits.lo = e0_bits.hi = 0;
    auto e0 = phv_i.field(expression->e0, &e0_bits);

    PhvInfo::Field::bitrange e1_bits;
    e1_bits.lo = e1_bits.hi = 0;
    auto e1 = phv_i.field(expression->e1, &e1_bits);

    PhvInfo::Field::bitrange e2_bits;
    e2_bits.lo = e2_bits.hi = 0;
    auto e2 = phv_i.field(expression->e2, &e2_bits);

    LOG3(e0);
    LOG3(e1);
    LOG3(e2);

    set_field_range(e0, e0_bits);
    set_field_range(e1, e1_bits);
    set_field_range(e2, e2_bits);

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
        PhvInfo::Field::bitrange bits;
        bits.lo = bits.hi = 0;
        auto field = phv_i.field(operand, &bits);
        set_field_range(field, bits);

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
    sanity_check_field_range("end_apply..");
    //
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
    // output logs
    //
    LOG3(phv_i);							// all Fields
    LOG3(*this);							// all Clusters
}//end_apply

//***********************************************************************************
//
// set field range
// updates range of field slice used in computations / travel through MAU pipeline / phv
// 
//***********************************************************************************

void Cluster::set_field_range(PhvInfo::Field *field, const PhvInfo::Field::bitrange& bits)
{
    if(field)
    {
        field->phv_use_lo = std::min(field->phv_use_lo, bits.lo);
        field->phv_use_hi = std::max(field->phv_use_hi, bits.hi);
    }
}

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

void Cluster::sanity_check_field_range(const std::string& msg)
{
    // for all fields in phv_i, check size >= range
    for (auto field: phv_i)
    {
        int range = field.phv_use_hi - field.phv_use_lo + 1;
        if(range > field.size)
        {
            WARNING("*****cluster.cpp:sanity_FAIL*****field range > size .." << msg << &field);
        }
    }
}

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
//
// cluster output
//
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

    return out;
}
