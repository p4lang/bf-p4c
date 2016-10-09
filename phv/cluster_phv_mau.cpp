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
    //
    // 1. sorted clusters requirement decreasing, sorted mau groups width decreasing
    //
    // traverse in reverse cluster_phv_map requirements for [32], [16], [8]
    // populate sorted queue of clusters
    //
    std::list<Cluster_PHV *> clusters_to_be_assigned;
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
    LOG3(clusters_to_be_assigned);
    //
    // fill PHV_MAU_Groups in reverse order 32b, 16b, 8b
    // map cluster_phv_map in reverse order 32 --> 16 --> 8 to corresponding PHV_MAU_Groups
    // populate sorted queue of mau containers
    //
    std::list<PHV_MAU_Group *> mau_groups_to_be_filled;;
    for (auto rit=PHV_MAU_i.rbegin(); rit!=PHV_MAU_i.rend(); ++rit)
    {
        // groups within this word size
        for(auto g: rit->second)
        {
            mau_groups_to_be_filled.push_back(g);
        }
    }
    LOG3("..........mau groups to be filled..........");
    LOG3(mau_groups_to_be_filled);
    //
    // assign clusters_to_be_assigned to mau_groups_to_be_filled
    // 2. each cluster field in separate containers
    //    addresses single-write constraint, surround effects within container, alignment issues (start @ 0)
    //
    for (auto g: mau_groups_to_be_filled)
    {
        std::list<Cluster_PHV *> clusters_remove;
        for (auto cl: clusters_to_be_assigned)
        {
            // 3. pick next cl, put in Group with available non-occupied <container, width>
            //    s.t., after assignment, G.remaining_containers != 1 as forall cl, |cl| >= 2
            auto avail_containers = g->avail_containers();
            auto req_containers = cl->num_containers();
            if(g->width() < cl->width())
            {
                // scale cl width down
                // <2:_48_32>{3*32} => <2:_48_32>{5*16}
                req_containers = cl->num_containers(cl->cluster_vec(), g->width());
            }
            if(req_containers <= avail_containers && avail_containers - req_containers != 1)
            {
                // assign cl to g
                //
                // if scaled width, update num_containers
                cl->num_containers(req_containers);
                cl->width(g->width());
                //
                LOG3("....." << *g << " <-- " << *cl);
                g->clusters().push_back(cl);
                clusters_remove.push_back(cl);
                //
                // for each container assigned to cluster, taint bits that are filled
                //
                int container_index = (int) PHV_Container::Containers::MAX - g->avail_containers();
                for (auto i=0, j=0; i < (int) cl->cluster_vec().size(); i++)
                {
                    auto field_width = cl->cluster_vec()[i]->size;
                    for (; j < req_containers && field_width > 0; j++)
                    {
                        int taint_bits = (int) g->width();
                        if(field_width < (int) g->width())
                        {
                            taint_bits = field_width;
                        }
                        g->phv_containers()[container_index++]->taint(0, taint_bits);
                        field_width -= (int) g->width();
                    }
                }
                g->avail_containers(avail_containers - req_containers);
                if(g->avail_containers() == 0)
                {
                    break;
                }
            }
        }
        // remove clusters already assigned
        for (auto cl: clusters_remove)
        {
            clusters_to_be_assigned.remove(cl);
        }
    }
    //
    // all mau groups exhausted
    // clusters not yet assigned
    LOG3("----------clusters not assigned (" << clusters_to_be_assigned.size() << ")-----");
    LOG3(clusters_to_be_assigned);

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
    for (int i=1; i <= (int)PHV_Container::Containers::MAX; i++)
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
std::ostream &operator<<(std::ostream &out, PHV_MAU_Group &g)
{
    // mau group summary
    //
    out << 'G' << g.number() << '[' << (int)(g.width()) << ']'
        << '(' << g.avail_containers() << ')';

    return out;
}

std::ostream &operator<<(std::ostream &out, PHV_MAU_Group *g)
{
    // mau group details
    //
    if(g)
    {
        out << *g << std::endl		// summary
            << g->phv_containers();	// details
    }
    else
    {
        out << "-g-";
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, std::list<PHV_MAU_Group *> &phv_mau_list)
{
    for (auto m: phv_mau_list)
    {
        // summary
        out << *m << std::endl;
    }

    return out;
}

std::ostream &operator<<(std::ostream &out, std::vector<PHV_MAU_Group *> *phv_mau_vec)
{
    out << '[';
    if(phv_mau_vec)
    {
        out << std::endl;
        for(auto g: *phv_mau_vec)
        {
           // mau group summary
           out << *g << std::endl;
        }
    }
    else
    {
        out << "-mgv-";
    }
    out << ']' << std::endl;
   
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
    for (auto rit=phv_mau_grps.phv_mau_map().rbegin(); rit!=phv_mau_grps.phv_mau_map().rend(); ++rit)
    {
        out << rit->second;
    } 

    return out;
}
