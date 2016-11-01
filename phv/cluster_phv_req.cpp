#include "cluster_phv_req.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

//***********************************************************************************
//
// Cluster_PHV_Requirements::Cluster_PHV_Requirements constructor
// 
// input:
//	clusters: cluster.dst_map()
// output:
//	creates sorted PHV container requirements for clusters
//	std::map<PHV_Container::PHV_Word, std::map<int, std::vector<Cluster_PHV *>>> Cluster_PHV_i;
//	sorted PHV requirements <number_of_containers, width_of_containers>
//	number decreasing then width decreasing
// 
//***********************************************************************************

Cluster_PHV_Requirements::Cluster_PHV_Requirements(Cluster &c)
	: cluster_i(c), pov_fields_i(c.pov_fields_not_in_cluster()), t_phv_fields_i(c.fields_no_use_mau())
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
    //
    // POV Requirements from clusters
    // allocate all bits to PHVs only if they are used
    // some POV fields, e.g., header stacks, have width > 1
    // allocation of POV field bits must be contiguous
    // sort based on use: fld->phv_use_hi - fld->phv_use_lo
    // sort based on width requirement, greatest width first
    //
    std::sort(pov_fields_i.begin(), pov_fields_i.end(),
	[](const PhvInfo::Field *l, const PhvInfo::Field *r)
        {
            int l_range = l->phv_use_hi - l->phv_use_lo;
            int r_range = r->phv_use_hi - r->phv_use_lo;
            if(l_range == r_range)
            {
                return l->size > r->size;
            }
            return l_range > r_range;
        });
    //
    // T_PHV Requirements from clusters
    // sort based on width requirement, greatest width first
    //
    std::sort(t_phv_fields_i.begin(), t_phv_fields_i.end(),
	[](const PhvInfo::Field *l, const PhvInfo::Field *r)
        {
            return l->size > r->size;
        });
    //
}//Cluster_PHV_Requirements

//***********************************************************************************
//
// Cluster_PHV::Cluster_PHV constructor
//
// input
//	cluster set of fields
// output
//	sorted cluster vector of fields, width decreasing
//	std::vector<const PhvInfo::Field *> cluster_vec_i
// 
//***********************************************************************************

Cluster_PHV::Cluster_PHV(std::set<const PhvInfo::Field *> *p) : cluster_vec_i(p->begin(), p->end())
{
    if(!p)
    {
        WARNING("*****Cluster_PHV called w/ nullptr cluster_set******");
    }
    //
    // set gress for this cluster
    //
    gress_i = PHV_Container::gress(*(p->begin()));
    //
    // sorted vector, decreasing field width
    //
    auto width_req = 0;
    if((std::adjacent_find (cluster_vec_i.begin(), cluster_vec_i.end(),
		[](const PhvInfo::Field *l, const PhvInfo::Field *r) { return l->size != r->size; }))
       == cluster_vec_i.end())
    {
        uniform_width_i = true;
        width_req = max_width_i = cluster_vec_i.front()->size;
    }
    else
    {
        uniform_width_i = false;
        //
        // cluster vector = sorted cluster set, decreasing field width
        std::sort(cluster_vec_i.begin(), cluster_vec_i.end(),
		[](const PhvInfo::Field *l, const PhvInfo::Field *r) { return l->size > r->size; });
        //
        width_req = max_width_i = cluster_vec_i.front()->size;
        //
        // <8:_32_16_16_16_16_16_16_16>	=> {9*b16} vs {8*b32}
        // <8:_16_16_16_16_16_16_16_9>	=> {8*b16}
        //
        auto scale_down = 0;
        for (auto pfield: cluster_vec_i)
        {
            if(pfield->size * 2 <= max_width_i)
            {
                scale_down++;
            }
        }
        if(scale_down * 2 > (int) cluster_vec_i.size())
        {
            width_req = width_req / 2;
        }
    }
    // container width
    if(width_req > (int) PHV_Container::PHV_Word::b16)
    {
        width_i = PHV_Container::PHV_Word::b32;
    }
    else if(width_req > (int) PHV_Container::PHV_Word::b8) 
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
//
//
// Cluster_PHV::num_containers()
// input
//	cluster vector of fields*, container width
// output
//	num_containers based on field width
//
//
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
    out << (char) cp.gress();

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
