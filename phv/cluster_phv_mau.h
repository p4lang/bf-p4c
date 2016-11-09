#ifndef _TOFINO_PHV_CLUSTER_PHV_MAU_H_
#define _TOFINO_PHV_CLUSTER_PHV_MAU_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"
#include "cluster_phv_req.h"
//
//
//***********************************************************************************
//
// class PHV_MAU_Group_Assignments computes MAU Group Assignments to clusters
// conditions:
// must perform PHV_MAU_Group_Assigments after Cluster_PHV_Requirements pass 
// input:
// cluster_phv_requirements.cluster_phv_map()
// sorted requirements computed by Cluster_PHV_Requirements
// accumulated vector<Cluster_PHV*> for each of PHV_Word (32,16,8-bit) widths
// output:
// cluster fields mapped to MAU Groups with Container Assignments
// 
//***********************************************************************************
//
//
class PHV_MAU_Group
{
 public:
    //
    class Container_Content
    {
      private:
        int lo_i;						// low of bit range in container for packing
        int hi_i;						// high of bit range in container for packing
        PHV_Container *container_i;
        //
      public:
        //
        Container_Content(int l, int h, PHV_Container *c);
        //
        int lo() const			{ return lo_i; }
        void lo(int l)			{ lo_i = l; }
        int hi() const			{ return hi_i; }
        void hi(int h)			{ hi_i = h; }
        int width() const		{ return hi_i - lo_i + 1; }
        PHV_Container *container()	{ return container_i; }
        //
        void sanity_check_container(const std::string&);
    };
    //
 private:
    //
    PHV_Container::PHV_Word width_i;			// container width in PHV group
    int number_i;					// 1..4 [32], 1..6 [16], 1..4 [8]
    PHV_Container::Ingress_Egress gress_i;		// Ingress_Only, Egress_Only, Ingress_Or_Egress
    int avail_containers_i;
							// number of available containers
    std::vector<PHV_Container *> phv_containers_i;	// containers in this MAU group
    std::vector<Cluster_PHV *> cluster_phv_i;		// clusters in this MAU group
    std::map<int, std::map<int, std::set<std::set<Container_Content *>>>> aligned_container_slices_i;
							// [8..15] [3..15] => 2[8..15] [3..7]
							// map[8][2] --> (Cx[8..15], Cy[8..15]
							// map[5][1]--> (Cy[3..7]
							// [2..7] [1..7] [5..7] => 3[5..7] 2[2..4] [1..1]
							// map[3][3] --> (Cx[5..7], Cy, Cz)
							// map[3][2] --> (Cx[2..4], Cy)
							// map[1][1] --> (Cy [1..1])
							// ingress slices, egress slices can have same width, num
							// [w](n) --> ((Ingress set) (Egress set))
 public:
    //
    PHV_MAU_Group(PHV_Container::PHV_Word w, int n, int& phv_number, PHV_Container::Ingress_Egress gress,
		const int containers_in_group=(int)PHV_Container::Containers::MAX);
    //
    PHV_Container::PHV_Word width()			{ return width_i; }
    int number()					{ return number_i; }
    PHV_Container::Ingress_Egress gress()		{ return gress_i; }
    int avail_containers()				{ return avail_containers_i; }
    void avail_containers(int n)			{ avail_containers_i = n; }
    std::vector<PHV_Container *>& phv_containers()	{ return phv_containers_i; }
    std::vector<Cluster_PHV *>& clusters()		{ return cluster_phv_i; }
    void create_aligned_container_slices(std::list<PHV_Container *>&);
    void create_aligned_container_slices();
    std::map<int, std::map<int, std::set<std::set<Container_Content *>>>>& aligned_container_slices()
							{ return aligned_container_slices_i; }
    //
    void sanity_check_container_packs(const std::string&);
    void sanity_check_container_fields_gress(const std::string&);
    void sanity_check_group_containers(const std::string&);
};
//
//
class PHV_MAU_Group_Assignments
{
 private:
    Cluster_PHV_Requirements &phv_requirements_i;	// reference to parent PHV Requirements
    //
    const std::map<PHV_Container::PHV_Word, int> num_groups_i
    {
        {PHV_Container::PHV_Word::b32, 4},
        {PHV_Container::PHV_Word::b16, 6},
        {PHV_Container::PHV_Word::b8, 4},
    };
    // PHV
    std::map<PHV_Container::PHV_Word, int> phv_number_start_i
    {
        {PHV_Container::PHV_Word::b32, 0},
        {PHV_Container::PHV_Word::b16, 128},
        {PHV_Container::PHV_Word::b8, 64},
    };
    // T_PHV
    std::map<PHV_Container::PHV_Word, int> t_phv_number_start_i
    {
        {PHV_Container::PHV_Word::b32, 256},
        {PHV_Container::PHV_Word::b16, 320},
        {PHV_Container::PHV_Word::b8, 288},
    };
    //
    std::map<std::pair<int, int>, PHV_Container::Ingress_Egress> ingress_egress_i
    {
        {std::make_pair(0, 15), PHV_Container::Ingress_Egress::Ingress_Only},
        {std::make_pair(16, 31), PHV_Container::Ingress_Egress::Egress_Only},
        {std::make_pair(64, 79), PHV_Container::Ingress_Egress::Ingress_Only},
        {std::make_pair(80, 95), PHV_Container::Ingress_Egress::Egress_Only},
        {std::make_pair(128, 143), PHV_Container::Ingress_Egress::Ingress_Only},
        {std::make_pair(144, 159), PHV_Container::Ingress_Egress::Egress_Only},
    };
    //
    std::map<PHV_Container::PHV_Word, std::vector<PHV_MAU_Group *>> PHV_MAU_i;
								// all PHV MAU groups
								// PHV_MAU_i[width] = vector of groups
    std::map<int, std::map<PHV_Container::PHV_Word, std::vector<PHV_Container *>>> T_PHV_i;
								// all TPHV collections
								// T_PHV_i[collection][width] = vector of containers
    //
    std::map<int, std::map<int, std::set<std::set<PHV_MAU_Group::Container_Content *>>>> aligned_container_slices_i;
							// for all PHV_MAU_Groups
							// sorted map <width increasing, num increasing>
							// containing <set of <set of container_packs>>
    //
    std::map<int, std::map<int, std::set<std::set<PHV_MAU_Group::Container_Content *>>>> T_PHV_container_slices_i;
							// for all T_PHV
							// sorted map <width increasing, num increasing>
							// containing <set of <set of container_packs>>
    //
    std::vector<PHV_Container *> cohabit_fields_i; 	// ranked set of container cohabits
							// requests to TP to avoid single-write issue
    //
    bool gress_in_compatibility(PHV_Container::Ingress_Egress gc_gress, PHV_Container::Ingress_Egress cl_gress)
    {
        return
            (gc_gress == PHV_Container::Ingress_Egress::Ingress_Only
          || gc_gress == PHV_Container::Ingress_Egress::Egress_Only)
          && gc_gress != cl_gress;
    }
    void cluster_placement_containers(
	std::map<PHV_Container::PHV_Word, std::map<int, std::vector<Cluster_PHV *>>>& cluster_phv_map,
	std::list<Cluster_PHV *>& clusters_to_be_assigned);
    void create_aligned_container_slices();
    void container_pack_cohabit(
	std::list<Cluster_PHV *>& clusters_to_be_assigned,
    	std::map<int, std::map<int, std::set<std::set<PHV_MAU_Group::Container_Content *>>>>&
	);
    //
    void consolidate_slices_in_group(
    	std::map<int, std::map<int, std::set<std::set<PHV_MAU_Group::Container_Content *>>>>&
	);
    void update_PHV_MAU_Group_container_slices(
    	std::map<int, std::map<int, std::set<std::set<PHV_MAU_Group::Container_Content *>>>>&
	);
    void container_cohabit_summary();
    //
 public:
    //
    PHV_MAU_Group_Assignments(Cluster_PHV_Requirements &phv_r);
    //
    std::map<PHV_Container::PHV_Word, std::vector<PHV_MAU_Group *>>& phv_mau_map()
    {
        return PHV_MAU_i;
    }
    std::map<int, std::map<int, std::set<std::set<PHV_MAU_Group::Container_Content *>>>>& aligned_container_slices()
							{ return aligned_container_slices_i; }
    std::vector<PHV_Container *>& cohabit_fields()	{ return cohabit_fields_i; }
    //
    std::map<int, std::map<PHV_Container::PHV_Word, std::vector<PHV_Container *>>>& t_phv_map()
    {
        return T_PHV_i;
    }
    std::map<int, std::map<int, std::set<std::set<PHV_MAU_Group::Container_Content *>>>>& T_PHV_container_slices()
							{ return T_PHV_container_slices_i; }
    //
    void sanity_check_container_avail(const std::string&);
    void sanity_check_container_fields_gress(const std::string&);
    void sanity_check_group_containers(const std::string&);
    void sanity_check_T_PHV_collections(const std::string&);
};
//
//
std::ostream &operator<<(std::ostream &, PHV_MAU_Group::Container_Content*);
std::ostream &operator<<(std::ostream &, std::set<PHV_MAU_Group::Container_Content *>&);
std::ostream &operator<<(std::ostream &, std::map<int, std::map<int, std::set<std::set<PHV_MAU_Group::Container_Content *>>>>&);
std::ostream &operator<<(std::ostream &, PHV_MAU_Group&);
std::ostream &operator<<(std::ostream &, PHV_MAU_Group*);
std::ostream &operator<<(std::ostream &, std::list<PHV_MAU_Group *>&);
std::ostream &operator<<(std::ostream &, std::vector<PHV_MAU_Group *>&);
std::ostream &operator<<(std::ostream &, std::vector<PHV_MAU_Group *>*);
std::ostream &operator<<(std::ostream &, std::map<PHV_Container::PHV_Word, std::vector<PHV_Container *>>&);
std::ostream &operator<<(std::ostream &, PHV_MAU_Group_Assignments&);
//
#endif /* _TOFINO_PHV_CLUSTER_PHV_MAU_H_ */
