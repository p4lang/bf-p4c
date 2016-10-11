#include "cluster_phv_mau.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

//***********************************************************************************
//
// PHV_MAU_Group::Container_Content::Container_Content constructor
// 
//***********************************************************************************

PHV_MAU_Group::Container_Content::Container_Content(int l, int w, PHV_Container *c) : lo_i(l), hi_i(l+w-1), container_i(c)
{
    BUG_CHECK(container_i, "*****PHV_MAU_Group::Container_Content constructor called with null container ptr*****");
}

//***********************************************************************************
//
// PHV_MAU_Group::PHV_MAU_Group
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
// PHV_MAU_Group::create_aligned_container_slices
// 
// slice partially filled containers
// to obtain larger number of sub-containers with reduced width
// 
//***********************************************************************************

void PHV_MAU_Group::create_aligned_container_slices()
{
    // larger n in <n:w> possible only when 2 or more containers
    //
    if(containers_pack_i.size() > 1)
    {
        // for each slice group, obtain max of all lows in each partial container
        //
        std::list<PHV_Container *> container_list(containers_pack_i.begin(), containers_pack_i.end());
        int lo = (int) width_i; 
        for (;container_list.size() > 0;)
        {
            int hi = lo - 1;
            lo = 0;
            for (auto c: container_list)
            {
               lo = std::max(lo, c->avail_bits_lo()); 
            }
            // for each partial container slice lo .. hi 
            //
            int width = hi - lo + 1;
            std::list<PHV_Container *> c_remove;
            for (auto c: container_list)
            {
                aligned_container_slices_i[width].insert(new Container_Content(lo, width, c));
                if(c->avail_bits_lo() == lo)
                {
                    c_remove.push_back(c);
                }
            }
            // remove containers completely sliced
            for (auto c: c_remove)
            {
                container_list.remove(c);
            }
        }
    }
}

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
    // cluster placement in containers conforming to MAU group constraints
    //
    std::list<Cluster_PHV *> clusters_to_be_assigned;
    std::set<PHV_MAU_Group *> mau_group_containers_avail;
    cluster_placement_containers(phv_requirements_i.cluster_phv_map(), clusters_to_be_assigned, mau_group_containers_avail);
    //
    // pack remaining clusters to partially filled containers
    //
    if(clusters_to_be_assigned.size())
    {
        // slice containers to form groups that can accommodate larger number for given width in <n:w>
        //
        create_aligned_container_slices(mau_group_containers_avail);
        //
        container_pack_cohabit(clusters_to_be_assigned, mau_group_containers_avail);
    }
    //
}//PHV_MAU_Group_Assignments

//***********************************************************************************
//
// PHV_MAU_Group_Assignments::cluster_placement_containers
// 
// 1. sorted clusters requirement decreasing, sorted mau groups width decreasing
// 
// 2. each cluster field in separate containers
//    addresses single-write constraint, surround effects within container, alignment issues (start @ 0)
// 
// 3. pick next cl, put in Group with available non-occupied <container, width>
//    s.t., after assignment, G.remaining_containers != 1 as forall cl, |cl| >= 2
//    field f may need several containers, e.g., f:128 --> C1<32>,C2,C3,C4
//    but each C single or partial field only => C does not contain 2 fields
// 
// 4. when all G exhausted
//    clusters_to_be_assigned contains clusters not assigned
//    mau_group_containers_avail contains mau groups that have partially available containers 
// 
//***********************************************************************************

void
PHV_MAU_Group_Assignments::cluster_placement_containers(std::map<PHV_Container::PHV_Word, std::map<int, std::vector<Cluster_PHV *>>>& cluster_phv_map, std::list<Cluster_PHV *>& clusters_to_be_assigned, std::set<PHV_MAU_Group *>& mau_group_containers_avail)
{
    //
    // 1. sorted clusters requirement decreasing, sorted mau groups width decreasing
    //
    // traverse in reverse cluster_phv_map requirements for [32], [16], [8]
    // populate sorted queue of clusters
    //
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
    std::list<PHV_MAU_Group *> mau_groups_to_be_filled;
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
    LOG3("..........container placements ..........");
    for (auto g: mau_groups_to_be_filled)
    {
        std::list<Cluster_PHV *> clusters_remove;
        for (auto cl: clusters_to_be_assigned)
        {
            // 3. pick next cl, put in Group with available non-occupied <container, width>
            //    s.t., after assignment, G.remaining_containers != 1 as forall cl, |cl| >= 2
            //    field f may need several containers, e.g., f:128 --> C1<32>,C2,C3,C4
            //    but each C single or partial field only => C does not contain 2 fields
            //
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
                        field_width -= (int) g->width();
                        //
                        g->phv_containers()[container_index]->taint(0, taint_bits, cl->cluster_vec()[i]);
                        if(g->phv_containers()[container_index]->status() == PHV_Container::Container_status::PARTIAL)
                        {   // MAU group has container packing potential
                            //
                            g->containers_pack().push_back(g->phv_containers()[container_index]);
                            mau_group_containers_avail.insert(g);
                        }
                        container_index++;
                    }
                }
                g->avail_containers(avail_containers - req_containers);
                if(g->avail_containers() == 0)
                {
                    break;
                }
            }
        }
        if(g->avail_containers())
        {
            mau_group_containers_avail.insert(g);
        }
        // remove clusters already assigned
        for (auto cl: clusters_remove)
        {
            clusters_to_be_assigned.remove(cl);
        }
    }
    //
    // all mau groups exhausted
    //
}//cluster_placement_containers


//***********************************************************************************
//
// PHV_MAU_Group_Assignments::create_aligned_container_slices
//
// for all MAU groups with partially filled containers
// slice to obtain larger number of sub-containers with reduced width
// 
//***********************************************************************************

void PHV_MAU_Group_Assignments::create_aligned_container_slices(std::set<PHV_MAU_Group *>& mau_group_containers_avail)
{
    for (auto g: mau_group_containers_avail)
    {
        g->create_aligned_container_slices();
    }
}

//***********************************************************************************
//
// PHV_MAU_Group_Assignments::container_pack_cohabit
//
// 4. when all G exhausted, attempt to pack C with available widths
//    (i)  co-habit         (need Table "single-write", surround side-effects (move-based ops))
//    (ii) no overlay       (need liveness, ifce graph)
//    e.g., 
//    clusters remain              G.avail
//    --------------               -------
//        <num, width>                <num containers, bit width>
//         7 1                     G1: 1:3
//         6 8                     G2: 1:7
//         5 8                     G3: 1:1, 1:1
//         5 4                     G4: 1:1, 1:7
//         5 1                     G5: 1:8, 1:13
//         4 3                     G6: 1:3, 1:6, 1:7
//         4 1                     G7: 4:8
//         3 8                     G8: 4:12
//         3 8                     G9: 5:8, 5:16
//         3 8 8 5                 G10: 1:1, 10:16
//         3 5
//         3 5
//         3 2
//         3 1
//         3 1
//         3 1
//         2 9
//         2 8
//         2 1
// 
//   (i) Pack co-habit 
//       sort remaining cl n decreasing, width decreasing
//       sort avail G:<n,w>, G:n increasing, and within G, w increasing
//       fill from Container MSB, aligment honored
//       G.singleton C use later if necessary for
//       (i) horizontal pack
//       (ii) status bits e.g., POVs for headers that honor single-write constraint
//
// 5. vertical distribution => no horizontal distribution
//        x.y => sigma Ca.y where x = number of containers = sigma Ca
//        addresses
//        (i)   sibling operands cannot reside in same container
//        (ii)  single-write constraint for cluster members
//        (iii) single-write constraint across clusters cohabiting container may exist
//              these fields are output as a recommedation to Table-Placement
//        within new cl selected for co-habit, packing should ensure no G.rem = 1.X
//        as no future cl can use this remnant unless horizontal packing enabled  
// 
//***********************************************************************************

void PHV_MAU_Group_Assignments::container_pack_cohabit(std::list<Cluster_PHV *>& clusters_to_be_assigned, std::set<PHV_MAU_Group *>& mau_group_containers_avail)
{
    BUG_CHECK(mau_group_containers_avail.size(), "*****container_pack_cohabit: MAU Groups no space left*****");
    //
    // sort clusters number decreasing, width decreasing
    //
    clusters_to_be_assigned.sort([](Cluster_PHV *l, Cluster_PHV *r) {
        if(l->num_containers() == r->num_containers())
        {
            return l->width() > r->width();
        }
        return l->num_containers() > r->num_containers();
    });
    LOG3("----------sorted clusters to be assigned (" << clusters_to_be_assigned.size() << ")-----");
    LOG3(clusters_to_be_assigned);
    //
    // sort mau groups with available containers, num containers increasing, width increasing
    //
    std::vector<PHV_MAU_Group *> mau_group_avail_vec(mau_group_containers_avail.begin(), mau_group_containers_avail.end());
    sort(mau_group_avail_vec.begin(), mau_group_avail_vec.end(), [](PHV_MAU_Group *l, PHV_MAU_Group *r) {
        if(l->containers_pack().size() == r->containers_pack().size())
        {   // sort by total width within G
            //
        }
        return l->containers_pack().size() < r->containers_pack().size();
    });
    //
    LOG3("----------sorted MAU Groups avail (" << mau_group_avail_vec.size() << ")-----");
    LOG3(&mau_group_avail_vec);
    //
}//container_pack_cohabit

//***********************************************************************************
//
// output stream <<
// 
//***********************************************************************************
//
// Container_Content output
//
std::ostream &operator<<(std::ostream &out, std::set<PHV_MAU_Group::Container_Content *>& slices)
{
    for (auto c: slices)
    {
        out << c->container() << '<' << c->width() << '>' << '{' << c->lo() << ".." << c->hi() << '}';
    }

    return out;
}
//
// phv_mau_group output
//
std::ostream &operator<<(std::ostream &out, PHV_MAU_Group &g)
{
    // mau group summary
    //
    out << 'G' << g.number() << '[' << (int)(g.width()) << ']';
    if(g.avail_containers())
    {
        out << '(' << g.avail_containers() << ')';
    }
    // summarize packable containers
    if(g.containers_pack().size())
    {
        out << "{ ";
        for (auto c: g.containers_pack())
        {
            out << c << ' ';
        }
        out << '}';
    }
    // summarize container slice groups
    if(! g.aligned_container_slices().empty())
    {
        out << '|';
        for (auto s: g.aligned_container_slices())
        {
            out << '[' << s.first << "](" << s.second << "); ";
        }
        out << '|';
    }

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
