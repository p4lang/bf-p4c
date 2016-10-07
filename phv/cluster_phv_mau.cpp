#include "cluster_phv_mau.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

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
    // traverse in reverse cluster_phv_map requirements for [32], [16], [8]
    // populate sorted queue of clusters
    //
    std::vector<Cluster_PHV *> clusters_to_be_assigned;
    for (auto rit=cluster_phv_map.rbegin(); rit!=cluster_phv_map.rend(); ++rit)
    {
        for (auto rit_2=rit->second.rbegin(); rit_2!=rit->second.rend(); ++rit_2)
        {
            for(auto cl: rit_2->second)
            {
                clusters_to_be_assigned.push_back(cl);
            }
        }
    }
    LOG3("..........clusters to be assigned..........");
    LOG3(&clusters_to_be_assigned);
    //
    // fill PHV_MAU_Groups in reverse order 32b, 16b, 8b
    // map cluster_phv_map in reverse order 32 --> 16 --> 8 to corresponding PHV_MAU_Groups
    //
    for (auto rit=PHV_MAU_i.rbegin(); rit!=PHV_MAU_i.rend(); ++rit)
    {
        // search groups within this word size
        for(auto g: rit->second)
        {
            if(g->avail_containers())
            {
                // attempt to assign first cluster that fits without remainder 1 container
            }
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
// output stream <<
// 
//***********************************************************************************
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
