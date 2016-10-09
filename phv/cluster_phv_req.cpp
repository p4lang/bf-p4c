#include "cluster_phv_req.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

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
                                if(l->uniform_width() == false && r->uniform_width() == false)
                                {   // same size, descending widths <2:_16_10> <2:_16_9> <2:_16_5>
                                    auto differ = std::mismatch(l->cluster_vec().begin(), l->cluster_vec().end(), r->cluster_vec().begin(),
                                                   [](const PhvInfo::Field *f1, const PhvInfo::Field *f2) {
                                                       return f1->size == f2->size;
                                               });
                                    return *differ.first >= *differ.second;
                                }
                                return l->uniform_width() == true && r->uniform_width() == false;
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
    if(max_width_i > (int) PHV_Container::PHV_Word::b16)
    {
        width_i = PHV_Container::PHV_Word::b32;
    }
    else if(max_width_i > (int) PHV_Container::PHV_Word::b8) 
    {
        width_i = PHV_Container::PHV_Word::b16;
    }
    else
    {
        width_i = PHV_Container::PHV_Word::b8;
    }
    // num containers of width
    //
    num_containers_i = num_containers(cluster_vec_i, width_i);
    //
}//Cluster_PHV

int
Cluster_PHV::num_containers(std::vector<const PhvInfo::Field *>& cluster_vec, PHV_Container::PHV_Word width)
{
    // num containers of width
    int num_containers = 0;
    for(auto pfield: cluster_vec)
    {
        // fields can span containers  (e.g., 48b = 2*32b or 3*16b = 6*8b)
        // no sharing of containers with cohabitant fields
        // sharing needs analyses:
        // (i)  container single-write table interference
        // (ii) surround interference 
        num_containers += pfield->size/(int)width + (pfield->size%(int)width? 1 : 0);
    }
    if(num_containers > (int) PHV_Container::Containers::MAX)
    {
        WARNING("*****Cluster_PHV::get_num_containers: num_containers = " << num_containers << " > " << (int) (PHV_Container::Containers::MAX) << " ******");
    }

    return num_containers;
}

//***********************************************************************************
//
// output stream <<
// 
//***********************************************************************************
//
// cluster_phv output
//
std::ostream &operator<<(std::ostream &out, Cluster_PHV &cp)
{
    // cluster summary
    //
    out << "<" << cp.cluster_vec().size() << ':';
    if(cp.uniform_width() == true)
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
    out << '{' << cp.num_containers() << '*' << (int)(cp.width()) << '}';

    return out;
}

std::ostream &operator<<(std::ostream &out, std::list<Cluster_PHV *> &cluster_list)
{
    for (auto c: cluster_list)
    {
        // cluster summary
        out << *c << std::endl;
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, Cluster_PHV *cp)
{
    // cluster details
    //
    if(cp)
    {
        // cluster summary
        out << *cp;
        // fields in cluster
        out << '(' << std::endl
            << cp->cluster_vec()
            << ')' << std::endl;
    }
    else
    {
        out << "-cp-";
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<Cluster_PHV *> *cluster_vec)
{
    out << '[';
    if(cluster_vec)
    {
        out << std::endl;
        for(auto cl: *cluster_vec)
        {
           // cluster summary
           out << *cl << std::endl;
        }
    }
    else 
    {
        out << "-clv-";
    }
    out << ']' << std::endl; 

    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<Cluster_PHV *> &cluster_phv_vec)
{
    out << ".....{" << cluster_phv_vec.front()->num_containers() << ',' << (int) cluster_phv_vec.front()->width() << "}#" << cluster_phv_vec.size() << " ....." << std::endl;
    for (auto cp: cluster_phv_vec)
    {
        // cluster details
        out << cp;
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, std::map<int, std::vector<Cluster_PHV *>>& phv_req_map)
{
    for (auto rit=phv_req_map.rbegin(); rit!=phv_req_map.rend(); ++rit)
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
    for (auto rit=phv_requirements.cluster_phv_map().rbegin(); rit!=phv_requirements.cluster_phv_map().rend(); ++rit)
    {
        int num_clusters = 0;
        for (auto rit_2=rit->second.rbegin(); rit_2!=rit->second.rend(); ++rit_2)
        {
            num_clusters += rit_2->second.size();
        }
        out << "[----------" << (int) rit->first << "---------#" << num_clusters << ']' << std::endl;
        for (auto rit_2=rit->second.rbegin(); rit_2!=rit->second.rend(); ++rit_2)
        {
            out << rit_2->second;
        }
    }
    //
    out << "++++++++++ PHV Container Requirements ++++++++++" << std::endl << std::endl;
    for (auto rit=phv_requirements.cluster_phv_map().rbegin(); rit!=phv_requirements.cluster_phv_map().rend(); ++rit)
    {
        out << "[----------" << (int) rit->first << "----------]" << std::endl;
        out << rit->second;
    }

    return out;
}
