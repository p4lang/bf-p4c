#include "cluster_phv_mau.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

//***********************************************************************************
//
// PHV_MAU_Group::Container_Content::Container_Content constructor
// 
//***********************************************************************************

PHV_MAU_Group::Container_Content::Container_Content(int l, int w, PHV_Container *c)
	: lo_i(l), hi_i(l+w-1), container_i(c)
{
    BUG_CHECK(container_i, "*****PHV_MAU_Group::Container_Content constructor called with null container ptr*****");
    container_i->ranges()[lo_i] = hi_i;
}

//***********************************************************************************
//
// PHV_MAU_Group::PHV_MAU_Group
// 
//***********************************************************************************

PHV_MAU_Group::PHV_MAU_Group(PHV_Container::PHV_Word w, int n, int& phv_number, PHV_Container::Ingress_Egress gress,
	const int containers_in_group)
	: width_i(w), number_i(n), gress_i(gress), avail_containers_i(containers_in_group)
{
    // create containers within group
    for (int i=1; i <= containers_in_group; i++)
    {
        PHV_Container *c = new PHV_Container(this, width_i, i, phv_number++, gress);
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
// (a) within MAU group, aligned container slices
//     (i)  honor alignment across members of cluster
//     (ii) increase number (albeit decreased width)
//
// (b) sort aligned slices to match clusters fast with available Containers <w, n>
//     slicing algorithm 
//     (i)   can produce several <container_packs> for given w
//     (ii)  a container can be member of several <container_packs>
//     (iii) guarantees that for given w, given n only one <container_pack> in G
//           as every slice reduces n by 1 from previous slicing operation
//
//     container packs sorted with increasing w, increasing n
//     map[width][number]--> <G:container_packs>  
// 
//***********************************************************************************


void PHV_MAU_Group::create_aligned_container_slices(std::list<PHV_Container *>& container_list)
{
    // larger n in <n:w> possible only when 2 or more containers
    // however, track singleton containers with available space
    // useful for horizontal packing where possible, e.g., POV bits
    //
    // for each slice group, obtain max of all lows in each partial container
    //
    int lo = (int) width_i; 
    for (;container_list.size() > 0;)
    {
        int hi = lo - 1;
        lo = 0;
        for (auto c: container_list)
        {
           lo = std::max(lo, c->ranges().begin()->first); 
        }
        // for each partial container slice lo .. hi 
        //
        int width = hi - lo + 1;
        std::list<PHV_Container *> c_remove;
        std::set<Container_Content *> *cc_set = new std::set<Container_Content *>;
        for (auto c: container_list)
        {
            cc_set->insert(new Container_Content(lo, width, c));			// insert in cc_set
            if(c->ranges().begin()->first == lo)
            {
                c_remove.push_back(c);
            }
        }
        aligned_container_slices_i[width][container_list.size()].insert(*cc_set);	// insert in map[w][n]
        //
        // remove containers completely sliced
        for (auto c: c_remove)
        {
            container_list.remove(c);
        }
    }
}


void PHV_MAU_Group::create_aligned_container_slices()
{
    // Ingress Containers and Egress Containers cannot be shared
    // split packable containers_pack into Ingress_Only list and Egress_Only list
    //
    std::list<PHV_Container *> ingress_container_list;
    std::list<PHV_Container *> egress_container_list;
    //
    for (auto c: containers_pack_i)
    {
        if(c->gress() == PHV_Container::Ingress_Egress::Ingress_Only)
        {
            ingress_container_list.push_back(c);
        }
        else
        {
            egress_container_list.push_back(c);
        }
    }
    //
    create_aligned_container_slices(ingress_container_list);
    create_aligned_container_slices(egress_container_list);
    //
    sanity_check_container_packs("PHV_MAU_Group::create_aligned_container_slices()..");
    //
}//create_aligned_container_slices


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
        int phv_number = phv_number_start_i[x.first];
        //
        for (int i=1; i <= x.second; i++)
        {
            // does this group phv containers fall in ingress_only or egress_only category
            //
            PHV_Container::Ingress_Egress gress = PHV_Container::Ingress_Egress::Ingress_Or_Egress;
            for (auto ie: ingress_egress_i)
            {
                std::pair<int, int> limits = ie.first;
                if(phv_number < limits.first)
                {
                    break;
                }
                if(phv_number >= limits.first && phv_number <= limits.second)
                {
                    gress = ie.second;
                    break;
                }
            }
            //
            PHV_MAU_Group *g = new PHV_MAU_Group(x.first, i, phv_number, gress);
            PHV_MAU_i[g->width()].push_back(g);
        }
    }
    // create TPHV collections
    for (auto &x: num_groups_i)
    {
        int phv_number = t_phv_number_start_i[x.first];
        //
        std::vector<PHV_MAU_Group *> t_phv_groups;
        for (int i=1; i <= x.second; i++)
        {
            // any TPHV collection can be Ingress, Egress but not both
            // which gress for this collection shall be determined during container placement
            // initialize to Ingress_Or_Egress
            //
            PHV_MAU_Group *g = new PHV_MAU_Group(x.first, i, phv_number, PHV_Container::Ingress_Egress::Ingress_Or_Egress,
		((int)PHV_Container::Containers::MAX)/2);
            t_phv_groups.push_back(g);
        }
        // collections
        int collection=0;
        int i=0;
        for (auto g: t_phv_groups)
        {
            for (auto c: g->phv_containers())
            {
                if(i++ % x.second == 0)
                {
                    collection++;
                }
                T_PHV_i[collection][g->width()].push_back(c);
            }
        }
    }
    //
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
        container_pack_cohabit(clusters_to_be_assigned);
        // 
        // update PHV_MAU_Group info pertaining to available containers
        //
        update_PHV_MAU_Group_container_slices(); 
        //
        container_cohabit_summary();
    }
    //
    // POV fields placement in MAU containers
    //
    POV_placement_containers();
    //
    // T_PHV fields placement in containers conforming to T_PHV Collection constraints
    //
    T_PHV_placement_containers();
    //
    sanity_check_group_containers("PHV_MAU_Group_Assignments::PHV_MAU_Group_Assignments()..");
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
// 3a.honor MAU group In/Egress only constraints
// 3b.pick next cl, put in Group with available non-occupied <container, width>
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
PHV_MAU_Group_Assignments::cluster_placement_containers(
	std::map<PHV_Container::PHV_Word, std::map<int, std::vector<Cluster_PHV *>>>& cluster_phv_map,
	std::list<Cluster_PHV *>& clusters_to_be_assigned,
	std::set<PHV_MAU_Group *>& mau_group_containers_avail)
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
    LOG3("..........clusters to be assigned (" << clusters_to_be_assigned.size() << ").........." << std::endl);
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
    LOG3("..........mau groups to be filled (" << mau_groups_to_be_filled.size() << ").........." << std::endl);
    LOG3(mau_groups_to_be_filled);
    //
    // assign clusters_to_be_assigned to mau_groups_to_be_filled
    // 2. each cluster field in separate containers
    //    addresses single-write constraint, surround effects within container, alignment issues (start @ 0)
    //
    LOG3("..........Initial Container Placements .........." << std::endl);
    for (auto g: mau_groups_to_be_filled)
    {
        std::list<Cluster_PHV *> clusters_remove;
        for (auto cl: clusters_to_be_assigned)
        {
            //
            // 3a.honor MAU group In/Egress only constraints
            //
            if(gress_in_compatibility(g->gress(), cl->gress()))
            {   
                // gress mismatch
                // skip cluster for this MAU group
                //
                continue;
            }
            //
            // 3b.pick next cl, put in Group with available non-occupied <container, width>
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
                            g->containers_pack().insert(g->phv_containers()[container_index]);
                            mau_group_containers_avail.insert(g);
                        }
                        LOG3("\t\t" << g->phv_containers()[container_index]);
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
// input:
//	mau_groups_containers_avail
// output:
//	in each PHV_MAU_Group, map[width][number] of aligned_container_slices
//	consider all PHV_MAU_Groups, create composite map[width][number] --> <set of <set of container_packs>>
//	map has sorted order width increasing, number increasing
// 
//***********************************************************************************

void PHV_MAU_Group_Assignments::create_aligned_container_slices(std::set<PHV_MAU_Group *>& mau_group_containers_avail)
{
    for (auto g: mau_group_containers_avail)
    {
        g->create_aligned_container_slices();
    }
    //
    // create composite map[width][number] --> <set of <set of container_packs>>
    // from all mau groups aligned_container_slices
    // map automatically has sorted order width increasing, number increasing
    //
    for (auto rit=PHV_MAU_i.rbegin(); rit!=PHV_MAU_i.rend(); ++rit)
    {
        // groups within this word size
        for(auto g: rit->second)
        {
            for (auto w: g->aligned_container_slices())
            {
                for (auto n: w.second)
                {
                    for (auto cc_set: n.second)
                    {
                        aligned_container_slices_i[w.first][n.first].insert(cc_set);	// insert in composite  map[w][n]
                    }
                }
            }
        }
    }
    LOG3(std::endl << "----------sorted MAU Container Packs avail after Initial Container Placements----------");
    LOG3(aligned_container_slices_i);
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
//        <num, width>             <num containers, bit width>
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
//       remaining clusters sorted with decreasing n, decreasing w
//       sort avail G:<n,w>, G:n increasing, and within G, w increasing
//       already available as map[w][n]--> <G:container_pack>
//       create composite map[w][n]--> <set of <container_pack>> as several G's can produce map[w][n]--> <G:container_pack>
//       fill container packs, automatically aligment honored
//
//       for members in cluster
//           pick top member<cn, cw> from sorted list
//           search map[cw] upto end of map
//               if map[mw][mn] accommodates member<cn, cw>
//                   if mw > cw, mn > cn
//                       split container_pack <mw, mn> --> <mw, mn-cn>, (<mw, cn> --> <mw-cw, cn>, <cw, cn>)  
//                       map.insert new container_packs
//                   allocate member<cn, cw> to container_pack<cw, cn>
//                       C.update_record member<cn, cw>
//                       for each cohabit field, taint bits packing from righmost slice
//                       -- honors alignment among cluster members
//                       -- ref: PHV_MAU_Group::create_aligned_container_slices()
//                       map.remove container_pack<mw, mn>
//           if member not allocated then "cannot pack member"
//
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
// input:
//        (i)  clusters_to_be_assigned
//        (ii) all PHV_MAU_Groups w/ std::map<int, std::map<int, std::set<Container_Content *>>> aligned_container_slices_i 
//             forall G,C sorted aligned_slices
//             --------------------------------
//             map[width][number]
//             [1][1]
//             [1][2]*2        
//             [1][11]         
//             [3][1]          
//             [3][2]          
//             [3][3]          
//             [5][1]         
//             [6][1]          
//             [7][1]         
//             [8][2]          
//             [8][4]         
//             [8][5]         
//             [8][10]         
//             [12][4]        
//             [15][10]
// output:
//	clusters (cohabit) packed into available containers
// 
//***********************************************************************************

void PHV_MAU_Group_Assignments::container_pack_cohabit(std::list<Cluster_PHV *>& clusters_to_be_assigned)
{
    // sort clusters number decreasing, width decreasing
    //
    clusters_to_be_assigned.sort([](Cluster_PHV *l, Cluster_PHV *r) {
        if(l->num_containers() == r->num_containers())
        {
            return l->width() > r->width();
        }
        return l->num_containers() > r->num_containers();
    });
    LOG3("----------sorted clusters to be Packed (" << clusters_to_be_assigned.size() << ")-----" << std::endl);
    LOG3(clusters_to_be_assigned);
    //
    // pack sorted clusters<n,w> to containers[w][n]
    //
    LOG3("..........Packing.........." << std::endl);
    //
    std::list<Cluster_PHV *> clusters_remove;
    for (auto cl: clusters_to_be_assigned)
    {
        int cl_w = cl->max_width();		// ?? assert width < container_width, also consider non uniform widths of fields
        int cl_n = cl->num_containers();
        //
        bool found_match = false;
        for (auto &i : aligned_container_slices_i)
        {
            int m_w = i.first;
            if(m_w >= cl_w)
            {
                for (auto &j : i.second)
                {
                    // split container_pack <mw, mn> --> <mw, mn-cn>, (<mw, cn> --> <mw-cw, cn>, <cw, cn>)
                    //
                    int m_n = j.first;
                    if(m_n >= cl_n)
                    {
                        // honor gress compatible match
                        //
                        std::set<PHV_MAU_Group::Container_Content *> cc_set;
                        PHV_Container::Ingress_Egress c_gress = PHV_Container::Ingress_Egress::Ingress_Or_Egress;
                        cc_set.clear();
                        for (auto cc_set_x: j.second)
                        {
                            c_gress = (*(cc_set_x.begin()))->container()->gress();
                            if(! gress_in_compatibility(c_gress, cl->gress()))
                            {
                                cc_set = cc_set_x;
                                //
                                // remove matching PHV_MAU_Group Container Content from set_of_sets
                                // if set_of_sets empty then remove map[m_w] entry
                                //
                                j.second.erase(cc_set_x);
                                if(j.second.empty())
                                {
                                    i.second.erase(j.first);
                                }
                                //
                                break;
                            }
                        }
                        if(cc_set.empty())
                        {   //
                            // not gress compatible
                            //
                            LOG3("-----<" << cl_n << ',' << cl_w << '>' << (char) cl->gress() << "-----[" << m_w << "](" << m_n << ')' << (char) c_gress << j.second);
                            //
                            continue;
                        }
                        //
                        LOG3(".....<" << cl_n << ',' << cl_w << '>' << (char) cl->gress() <<  "-->[" << m_w << "](" << m_n << ')' << (char) c_gress << cc_set);
                        //
                        // mau availabilty number > cluster requirement number
                        //
                        if(m_n > cl_n)
                        {   // create new container pack <mw, mn-cn>
                            // n = m_n - cl_n containers
                            // insert in map[n]
                            //
                            std::set<PHV_MAU_Group::Container_Content *>* cc_n = new std::set<PHV_MAU_Group::Container_Content *>;
                            auto n = m_n - cl_n;
                            for (auto i=0; i < n; i++)
                            {
                                cc_n->insert(*(cc_set.begin()));
                                cc_set.erase(cc_set.begin());
                            }
                            i.second[n].insert(*cc_n);
                            LOG3("\t==>[" << m_w << "]-->[" << m_w << "](" << n << ')' << std::endl << '\t' << *cc_n);
                        }
                        //
                        // container tracking based on cc_set ... <cl_n, cl_w>;
                        //
                        auto field = 0;
                        for (auto cc : cc_set)
                        {
                            // to honor alignment of fields in clusters
                            // start with rightmost vertical slice that accommodates this width
                            //
                            int start = cc->hi() + 1 - cl_w;
                            cc->container()->taint(start, cl_w, cl->cluster_vec()[field++], cc->lo() /*container ranges*/);
                            //
                            // if container is fully packed, remove from group's available containers
                            //
                            if(cc->container()->status() == PHV_Container::Container_status::FULL)
                            {
                                cc->container()->phv_mau_group()->containers_pack().erase(cc->container());
                            }
                            LOG3("\t\t" << *(cc->container()));
                        }
                        //
                        // mau availabilty width > cluster requirement width
                        //
                        if(m_w > cl_w)
                        {   // create new container pack <mw-cw, cn>
                            // new width w = m_w - cl_w;
                            // insert in map[m_w-cl_w][cl_n]
                            //
                            std::set<PHV_MAU_Group::Container_Content *>* cc_w = new std::set<PHV_MAU_Group::Container_Content *>;
                            *cc_w = cc_set;
                            for (auto cc: *cc_w)
                            {
                                cc->hi(cc->hi() - cl_w);
                            }
                            auto w = m_w - cl_w;
                            aligned_container_slices_i[w][cl_n].insert(*cc_w);
                            LOG3("\t==>(" << cl_n << ")-->[" << w << "](" << cl_n << ')' << std::endl << '\t' << *cc_w);
                        }
                        // remove cl
                        //
                        clusters_remove.push_back(cl);
                        //
                        found_match = true;	// next cluster cl
                        break;
                    }
                }
            }
            if(found_match)
            {
                break;
            }
        }
    }
    //
    sanity_check_container_fields_gress("PHV_MAU_Group_Assignments::container_pack_cohabit()..");
    //
    // remove clusters already assigned
    for (auto cl: clusters_remove)
    {
        clusters_to_be_assigned.remove(cl);
    }
    LOG3(std::endl << "----------after Packing ..... clusters not assigned (" << clusters_to_be_assigned.size() << ")-----" << std::endl);
    LOG3(clusters_to_be_assigned);
    //
    LOG3("----------after Packing ..... sorted MAU Container Packs avail----------");
    LOG3(aligned_container_slices_i);
    //
    consolidate_slices_in_group();
    //
    LOG3("----------after Packing ..... consolidate slices ..... MAU Container Packs avail----------");
    LOG3(aligned_container_slices_i);
    //
}//container_pack_cohabit


void PHV_MAU_Group_Assignments::consolidate_slices_in_group()
{
    // consolidate to get larger number same width only when all aligned and same MAU group
    // [3](2)*2 ((PHV-149<3>{8..10}, PHV-147), (PHV-145<3>{8..10}, PHV-151)) ==> [3](4)*1
    //
    for (auto w: aligned_container_slices_i)
    {
        for (auto n: w.second)
        {
            if(n.second.size() > 1)
            {
                // multiple sets in set of sets
                // attempt to consolidate only within same MAU group
                //
                std::map<PHV_MAU_Group *, std::map<int, std::set<std::set<PHV_MAU_Group::Container_Content *>>>> g_lo;
                for (auto cc_set: n.second)
                {
                    PHV_Container *c = (*(cc_set.begin()))->container();
                    int lo = (*(cc_set.begin()))->lo();
                    g_lo[c->phv_mau_group()][lo].insert(cc_set);
                }
                // all elements of g_lo[g][lo] must be used for aligned_slices[w][n]
                //
                aligned_container_slices_i[w.first].erase(n.first);
                for (auto g: g_lo)
                {
                    for (auto l: g.second)
                    {
                        if(l.second.size() > 1)
                        {   //
                            // make a composite set from all sets in l.second
                            //
                            std::set<PHV_MAU_Group::Container_Content *> *set_u = new std::set<PHV_MAU_Group::Container_Content *>;
                            for (auto cc_set: l.second)
                            {
                                for (auto cc: cc_set)
                                {
                                    set_u->insert(cc);
                                }
                            }
                            aligned_container_slices_i[w.first][set_u->size()].insert(*set_u);
                        }
                        else
                        {   // use existing singleton set
                            // 
                            aligned_container_slices_i[w.first][n.first].insert(*(l.second.begin()));
                        } 
                    }
                }
            }
        }
    }
}//consolidate_slices_in_group

//
// update PHV MAU Group container slice information
// after container cohabit packing pass completed
//

void PHV_MAU_Group_Assignments::update_PHV_MAU_Group_container_slices()
{
    for (auto &gg: PHV_MAU_i)
    {
        // groups within this word size
        for(auto g: gg.second)
        {
            g->aligned_container_slices().clear();
        }
    }
    // update PHV MAU Group map from updated composite map[width][number] --> <set of <set of container_packs>>
    //
    for (auto &w: aligned_container_slices_i)
    {
        for (auto &n: w.second)
        {
            for (auto &cc_set: n.second)
            {
                PHV_Container *c = (*(cc_set.begin()))->container();
                PHV_MAU_Group *g = c->phv_mau_group();
                g->aligned_container_slices()[w.first][n.first].insert(cc_set);		// insert in PHV_MAU_Group map[w][n]
            }
        }
    }
}//update_PHV_MAU_Group_container_slices

//
// container cohabit summary
// input to TP phase to honor single write issue avoidance
//

void PHV_MAU_Group_Assignments::container_cohabit_summary()
{
    for (auto &gg: PHV_MAU_i)
    {
        // groups within this word size
        for (auto g: gg.second)
        {
            for (auto c: g->phv_containers())
            {
                if(c->fields_in_container().size() > 1)
                {
                    cohabit_fields_i.push_back(c);
                }
            }
        }
    }
}//container_cohabit_summary


//***********************************************************************************
//
// POV placement
// 
//***********************************************************************************


void
PHV_MAU_Group_Assignments::POV_placement_containers()
{
    LOG3("..........POV fields to be assigned (" << phv_requirements_i.pov_fields().size() << ").........." << std::endl);
    LOG3(phv_requirements_i.pov_fields());
}


//***********************************************************************************
//
// T_PHV placement
// 
//***********************************************************************************


void
PHV_MAU_Group_Assignments::T_PHV_placement_containers()
{
    LOG3("..........T_PHV fields to be assigned (" << phv_requirements_i.t_phv_fields().size() << ").........." << std::endl);
    LOG3(phv_requirements_i.t_phv_fields());
}


//***********************************************************************************
//
// sanity checks
// 
//***********************************************************************************


void PHV_MAU_Group::Container_Content::sanity_check_container(const std::string& msg)
{
}

void PHV_MAU_Group::sanity_check_container_packs(const std::string& msg)
{
    // for all aligned container_packs in MAU Group
    // check width of each slice
    // check only one slice range per map[w][n]
    //
    for (auto w: aligned_container_slices_i)
    {
        for (auto n: w.second)
        {
            for (auto cc_set: n.second)
            {
                // for all members check width and range lo .. hi
                // also check all containers belong to the same gress
                //
                std::set<int> lo;
                std::set<int> hi;
                lo.clear();
                hi.clear();
                std::set<PHV_Container::Ingress_Egress> gress;
                for (auto cc: cc_set)
                {
                    if(cc->width() != w.first)
                    {
                        WARNING("*****cluster_phv_mau.cpp:sanity_FAIL*****cluster_pack width differs .." << w.first << " vs " << cc << ' ' << msg);
                    }
                    lo.insert(cc->lo());
                    hi.insert(cc->hi());
                    //
                    gress.insert(cc->container()->gress());
                }
                if(lo.size() != 1)
                {
                    WARNING("*****cluster_phv_mau.cpp:sanity_FAIL*****cluster_pack lo differs .." << '[' << w.first << "][" << n.first << ' ' << msg);
                }
                if(hi.size() != 1)
                {
                    WARNING("*****cluster_phv_mau.cpp:sanity_FAIL*****cluster_pack hi differs .." << '[' << w.first << "][" << n.first << ' ' << msg);
                }
                if(gress.size() != 1)
                {
                    WARNING("*****cluster_phv_mau.cpp:sanity_FAIL*****gress differs .." << n.second << msg);
                }
            }
        }
    }
}

void PHV_MAU_Group::sanity_check_container_fields_gress(const std::string& msg)
{
    // sanity check all fields contained in this container are gress compatible with container gress
    //
    for (auto c: phv_containers_i)
    {
        for (auto cc: c->fields_in_container())
        {
            const PhvInfo::Field *field = cc->field();
            PHV_Container::Ingress_Egress f_gress = PHV_Container::gress(field);
            if(f_gress != c->gress())
            {
                WARNING("*****cluster_phv_mau.cpp:sanity_FAIL*****gress differs .." << (char) f_gress  << " vs " << (char) c->gress() << "..." << msg << c);
            }
        }
    }
}

void PHV_MAU_Group::sanity_check_group_containers(const std::string& msg)
{
    for (auto &w: aligned_container_slices_i)
    {
        for (auto &n: w.second)
        {
            for (auto &cc_set: n.second)
            {
                for (auto &cc: cc_set)
                {
                    cc->sanity_check_container(msg+"PHV_MAU_Group::sanity_check_group_containers");
                }
            }
        }
    }
    for (auto &c: containers_pack_i)
    {
        c->sanity_check_container(msg+"PHV_MAU_Group::sanity_check_group_containers containers_pack");
    }
    for (auto &c: phv_containers_i)
    {
        c->sanity_check_container(msg+"PHV_MAU_Group::sanity_check_group_containers phv_containers");
    }
}

void PHV_MAU_Group_Assignments::sanity_check_container_fields_gress(const std::string& msg)
{
    for (auto groups: PHV_MAU_i)
    { 
        for (auto g: groups.second)
        {
            g->sanity_check_container_fields_gress(msg); 
        } 
    } 
}

void PHV_MAU_Group_Assignments::sanity_check_group_containers(const std::string& msg)
{
    // sanity check PHV_MAU_Group_Assignments aligned_container_slices with individual MAU Groups
    //
    for (auto &w: aligned_container_slices_i)
    {
        for (auto &n: w.second)
        {
            for (auto &cc_set: n.second)
            {
                PHV_Container *c = (*(cc_set.begin()))->container();
                PHV_MAU_Group *g = c->phv_mau_group();
                if(g->aligned_container_slices()[w.first][n.first].count(cc_set) != 1)
                {
                    WARNING("*****cluster_phv_mau.cpp:sanity_FAIL*****.." << msg << g << " aligned_container_slices does not contain" << cc_set);
                }
            }
        }
    }
    // sanity check individual MAU Groups aligned_container_slices with composite PHV_MAU_Group_Assignments
    // for each MAU Group sanity check constituent containers
    //
    for (auto groups: PHV_MAU_i)
    { 
        for (auto g: groups.second)
        {
            for (auto &w: g->aligned_container_slices())
            {
                for (auto &n: w.second)
                {
                    for (auto &cc_set: n.second)
                    {
                        if(aligned_container_slices_i[w.first][n.first].count(cc_set) != 1)
                        {
                            WARNING("*****cluster_phv_mau.cpp:sanity_FAIL*****.." << msg << " composite aligned_container_slices does not contain" << cc_set << " from " << g);
                        }
                    }
                }
            }
            g->sanity_check_group_containers(msg); 
        } 
    } 
}

//***********************************************************************************
//
// output stream <<
// 
//***********************************************************************************
//
// PHV_MAU_Group Container_Content output
//
std::ostream &operator<<(std::ostream &out, PHV_MAU_Group::Container_Content *c)
{
    if(c)
    {
        out << c->container() << '<' << c->width() << '>' << '{' << c->lo() << ".." << c->hi() << '}';
    }
    else
    {
        out << "--cc--";
    }

    return out;
}
//
//
std::ostream &operator<<(std::ostream &out, std::set<PHV_MAU_Group::Container_Content *>& slices)
{
    out << '(';
    for (auto c: slices)
    {
        if(c->container()->status() != PHV_Container::Container_status::FULL)
        {
            out << c << ' ';
        }
    }
    out << std::endl << "\t)";

    return out;
}
//
//
std::ostream &operator<<(std::ostream &out, std::map<int, std::map<int, std::set<std::set<PHV_MAU_Group::Container_Content *>>>>& all_container_packs)
{
    // map[w][n] --> <set of <set of container_packs>>
    //
    for (auto w: all_container_packs)
    {
        for (auto n: w.second)
        {
            out << std::endl << "\t" << '[' << w.first << "](" << n.first << ')';
            if(n.second.size() > 1)
            {
                out << '*' << n.second.size();
            }
            out << std::endl << '\t';
            for(auto s: n.second)
            {
                out << s;
            }
        }
    }
    out << std::endl;

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
    out << (char) g.gress();
    if(g.avail_containers())
    {
        out << '(' << g.avail_containers() << ')';
    }
    // summarize packable containers
    if(g.containers_pack().size())
    {
        out << "\t{ ";
        for (auto c: g.containers_pack())
        {
            if(c->status() != PHV_Container::Container_status::FULL)
            {
                out << c << ' ';
            }
        }
        out << std::endl << "\t}";
    }
    // summarize container slice groups
    if(! g.aligned_container_slices().empty())
    {
        for (auto w: g.aligned_container_slices())
        {
            for (auto n: w.second)
            {
                out << std::endl << "\t" << '[' << w.first << "](" << n.first << ')' << std::endl;
                for (auto s: n.second)
                {
                    out << '\t' << s;
                }
            }
        }
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
    out << std::endl;
    out << "++++++++++ #mau_groups=" << phv_mau_vec.size() << " ++++++++++" << std::endl;
    for (auto m: phv_mau_vec)
    {
        out << std::endl;
        out << m;
    }
    out << std::endl;

    return out;
}
//
// phv_mau_group_assignments output
//
std::ostream &operator<<(std::ostream &out, PHV_MAU_Group_Assignments &phv_mau_grps)
{
    out << "++++++++++ PHV MAU Group Assignments ++++++++++" << std::endl; 
    for (auto rit=phv_mau_grps.phv_mau_map().rbegin(); rit!=phv_mau_grps.phv_mau_map().rend(); ++rit)
    {
        out << rit->second;
    }
    // 
    out << std::endl
        << "++++++++++ T_PHV Collections ++++++++++" << std::endl; 
    for (auto coll: phv_mau_grps.t_phv_map())
    {
        out << std::endl
            << "Collection" << coll.first;
        for (auto m: coll.second)
        {
            out << m.second;
        }
        out << std::endl;
    }
    // 
    out << std::endl
        << "++++++++++ Container Cohabit Summary .....(" << phv_mau_grps.cohabit_fields().size() << ")..... ++++++++++"
        << std::endl
        << std::endl;
    for (auto cof: phv_mau_grps.cohabit_fields())
    {
        out << '<' << cof->fields_in_container().size() << ':' << *cof << std::endl;
        out << '>' << std::endl;
    }

    return out;
}
