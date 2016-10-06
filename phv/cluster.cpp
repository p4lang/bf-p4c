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
// Cluster_PHV_Requirements::Cluster_PHV_Requirements constructor
// 
//***********************************************************************************

Cluster_PHV_Requirements::Cluster_PHV_Requirements(Cluster &c) : cluster_i(c)
{
    // create PHV Requirements from clusters
    if(! cluster_i.dst_map().size())
    {
        WARNING("*****Cluster_PHV_Requirements called w/ 0 clusters******");
    }
    //
    for (auto p: Values(cluster_i.dst_map()))
    {
        Cluster_PHV *m = new Cluster_PHV(p);
        Cluster_PHV_i[m->width()][m->num_containers()].push_back(m);
    }
    //
    // cluster PHV requirement = [qty, width]
    // sort based on width requirement, greatest width first
    // for each width sort based on quantity requirement
    //
    for (auto &x: Values(Cluster_PHV_i))
    {
        for (auto &p: Values(x))
        {
            std::sort(p.begin(), p.end(), [](Cluster_PHV *l, Cluster_PHV *r) {
                if(l->width() == r->width())
                {
                    if(l->num_containers() == r->num_containers())
                    {
                        if(l->max_width() == r->max_width())
                        {
                            if(l->cluster_vec().size() == r->cluster_vec().size())
                            {   // sort by uniform_width first
                                if(! l->uniform_width() && ! r->uniform_width())
                                {   // same size, descending widths <2:_16_10> <2:_16_9> <2:_16_5>
                                    auto differ = std::mismatch(l->cluster_vec().begin(), l->cluster_vec().end(), r->cluster_vec().begin(),
                                                   [](const PhvInfo::Field *f1, const PhvInfo::Field *f2) {
                                                       return f1->size == f2->size;
                                               });
                                    return *differ.first >= *differ.second;
                                }
                                return l->uniform_width() && ! r->uniform_width();
                            }
                            return l->cluster_vec().size() > r->cluster_vec().size();
                        }
                        return l->max_width() > r->max_width();
                    }
                    return l->num_containers() > r->num_containers();
                }
                return l->width() > r->width();
            });
        }
    }
}//Cluster_PHV_Requirements

//***********************************************************************************
//
// Cluster_PHV::Cluster_PHV constructor
// 
//***********************************************************************************

Cluster_PHV::Cluster_PHV(std::set<const PhvInfo::Field *> *p) : cluster_vec_i(p->begin(), p->end())
{
    if(!p)
    {
        WARNING("*****Cluster_PHV called w/ nullptr cluster_set******");
    }
    if((std::adjacent_find (cluster_vec_i.begin(), cluster_vec_i.end(),
		[](const PhvInfo::Field *l, const PhvInfo::Field *r) { return l->size != r->size; }))
       == cluster_vec_i.end())
    {
        uniform_width_i = true;
        max_width_i = cluster_vec_i.front()->size;
    }
    else
    {
        uniform_width_i = false;
        // get max field_width
        max_width_i = 0;
        for(auto pfield: cluster_vec_i)
        {
            max_width_i = std::max(pfield->size, max_width_i);
        }
        // cluster vector = sorted cluster set, decreasing field width
        std::sort(cluster_vec_i.begin(), cluster_vec_i.end(),
		[](const PhvInfo::Field *l, const PhvInfo::Field *r) { return l->size > r->size; });
    }
    // container width
    if(max_width_i > 16)
    {
        width_i = PHV_Container::PHV_Word::b32;
    }
    else if(max_width_i > 8) 
    {
        width_i = PHV_Container::PHV_Word::b16;
    }
    else
    {
        width_i = PHV_Container::PHV_Word::b8;
    }
    // num containers of width
    num_containers_i = 0;
    for(auto pfield: cluster_vec_i)
    {
        // fields can span containers  (e.g., 48b = 2*32b)
        // no sharing of containers with cohabitant fields
        // sharing needs analyses:
        // (i)  container single-write table interference
        // (ii) surround interference 
        num_containers_i += pfield->size/(int)width_i + (pfield->size%(int)width_i? 1 : 0);
    }
}//Cluster_PHV

//***********************************************************************************
//
// PHV_MAU_Group_Assignments::PHV_MAU_Group_Assignments
// 
//***********************************************************************************

PHV_MAU_Group_Assignments::PHV_MAU_Group_Assignments(Cluster_PHV_Requirements &phv_r) : phv_requirements_i(phv_r)
{
    // create PHV Group Assignments from PHV Requirements
    if(! phv_requirements_i.cluster_phv_map().size())
    {
        WARNING("*****PHV_MAU_Group_Assignments called w/ 0 Requirements******");
    }
    // create MAU Groups
    for (auto &x: num_groups_i)
    {
        for (int i=1; i <= x.second; i++)
        {
            PHV_MAU_Group *g = new PHV_MAU_Group(x.first, i);
            PHV_MAU_i[g->width()].push_back(g);
        }
    }
    // allocate containers to clusters
    allocate_containers(phv_requirements_i.cluster_phv_map());
    //
}//PHV_MAU_Group_Assignments

bool
PHV_MAU_Group_Assignments::allocate_containers(std::map<PHV_Container::PHV_Word, std::map<int, std::vector<Cluster_PHV *>>>& cluster_phv_map)
{
    // fill PHV_MAU_Groups in reverse order 32, 16, 8
    // map cluster_phv_map in reverse order 32 --> 16 --> 8 to corresponding PHV_MAU_Groups
    //
    std::map<PHV_Container::PHV_Word, std::vector<PHV_MAU_Group *>>::reverse_iterator rit;
    for (rit=PHV_MAU_i.rbegin(); rit!=PHV_MAU_i.rend(); ++rit)
    {
        std::map<PHV_Container::PHV_Word, std::map<int, std::vector<Cluster_PHV *>>>::reverse_iterator rit_2;
        for (rit_2=cluster_phv_map.rbegin(); rit_2!=cluster_phv_map.rend(); ++rit_2)
        {
        }
    }

    return false;
}

//***********************************************************************************
//
// PHV_MAU_Group::PHV_MAU_Group constructor
// 
//***********************************************************************************

PHV_MAU_Group::PHV_MAU_Group(PHV_Container::PHV_Word w, int n) : width_i(w), number_i(n)
{
    // create containers within group
    for (int i=1; i <= (int)Containers::MAX; i++)
    {
        PHV_Container *c = new PHV_Container(width_i, i);
        phv_containers_i.push_back(c);
    }
}//PHV_MAU_Group

//***********************************************************************************
//
// PHV_Container::PHV_Container constructor
// 
//***********************************************************************************

PHV_Container::PHV_Container(PHV_Word w, int n) : width_i(w), number_i(n)
{
}//PHV_Container

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
//
// cluster_phv output
//
std::ostream &operator<<(std::ostream &out, Cluster_PHV &cp)
{
    // cluster summary
    //
    out << "<" << cp.cluster_vec().size() << ':';
    if(cp.uniform_width())
    {
        out << cp.max_width();
    }
    else
    {
        for(auto f: cp.cluster_vec())
        {
            out << '_' << f->size;
        }
    }
    out << '>';

    return out;
}

std::ostream &operator<<(std::ostream &out, Cluster_PHV *cp)
{
    if(cp)
    {
        // cluster summary
        out << *cp;
        // fields in cluster
        out << "{" << cp->num_containers() << '*' << (int)(cp->width()) << "}(" << std::endl
            << cp->cluster_vec()
            << ')' << std::endl;
    }
    else
    {
        out << "-cp-";
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<Cluster_PHV *> &cluster_phv_vec)
{
    out << "++++++++++ #clusters=" << cluster_phv_vec.size() << " ++++++++++" << std::endl;
    for (auto cp: cluster_phv_vec)
    {
        out << cp;
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, std::map<int, std::vector<Cluster_PHV *>>& phv_req_map)
{
    std::map<int, std::vector<Cluster_PHV *>>::reverse_iterator rit;
    for (rit=phv_req_map.rbegin(); rit!=phv_req_map.rend(); ++rit)
    {
        // print key <number> of phv_req_map 
        out << '[' << rit->first << "]*" << rit->second.size() << "   \t= ";
        // summarize clusters
        for (auto &cp: rit->second)
        {
            // cluster summary
            out << *cp << ' ';
        }
        out << std::endl;
    }

    return out; 
}

std::ostream &operator<<(std::ostream &out, Cluster_PHV_Requirements &phv_requirements)
{
    out << "++++++++++ Cluster PHV Requirements ++++++++++" << std::endl << std::endl;
    std::map<PHV_Container::PHV_Word, std::map<int, std::vector<Cluster_PHV *>>>::reverse_iterator rit;
    for (rit=phv_requirements.cluster_phv_map().rbegin(); rit!=phv_requirements.cluster_phv_map().rend(); ++rit)
    {
        out << "[----" << (int) rit->first << "----]" << std::endl;
        std::map<int, std::vector<Cluster_PHV *>>::reverse_iterator rit_2;
        for (rit_2=rit->second.rbegin(); rit_2!=rit->second.rend(); ++rit_2)
        {
            out << rit_2->second;
        }
    }
    //
    out << "++++++++++ PHV Container Requirements ++++++++++" << std::endl << std::endl;
    for (rit=phv_requirements.cluster_phv_map().rbegin(); rit!=phv_requirements.cluster_phv_map().rend(); ++rit)
    {
        out << "[----" << (int) rit->first << "----]" << std::endl;
        out << rit->second;
    }

    return out;
}
//
// phv_mau_group output
//
std::ostream &operator<<(std::ostream &out, std::vector<PHV_Container::content>& c)
{
    for (auto s: c)
    {
        out << s.field() << '{' << s.lo() << ".." << s.hi() << '[' << s.width() << ']';
    }

    return out;
}
std::ostream &operator<<(std::ostream &out, PHV_Container *c)
{
    if(c)
    {
        out << "\tC" << c->number() << '[' << (int)(c->width()) << ']'
            << '(' << (char)(c->status()) << c->fields() << ')';
        out << '\t';
        for (int i=0; i < (int) c->width(); i++) out << '0';
    }
    else
    {
        out << "-c-";
    }
    out << std::endl;

    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<PHV_Container *> &phv_containers)
{
    for (auto m: phv_containers)
    {
        out << m;
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, PHV_MAU_Group *g)
{
    if(g)
    {
        out << 'G' << g->number() << '[' << (int)(g->width()) << ']'
            << '(' << g->avail_containers() << ')' << std::endl
            << g->phv_containers();
    }
    else
    {
        out << "-g-";
    }
    out << std::endl;

    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<PHV_MAU_Group *> &phv_mau_vec)
{
    out << "++++++++++ #mau_groups=" << phv_mau_vec.size() << " ++++++++++" << std::endl;
    for (auto m: phv_mau_vec)
    {
        out << m;
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, PHV_MAU_Group_Assignments &phv_mau_grps)
{
    out << "++++++++++ PHV MAU Group Assignments ++++++++++" << std::endl;
    for (auto &p: Values(phv_mau_grps.phv_mau_map()))
    {
        out << p;
    } 

    return out;
}
