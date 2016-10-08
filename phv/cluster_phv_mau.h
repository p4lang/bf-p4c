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
    enum class Containers {MAX=16};
    //
 private:
    PHV_Container::PHV_Word width_i;			// container width in PHV group
    int number_i;					// 1..4 [32], 1..6 [16], 1..4 [8]
    int avail_containers_i = (int)Containers::MAX;	// number of available containers
    std::vector<PHV_Container *> phv_containers_i;	// containers in this MAU group
    std::vector<Cluster_PHV *> cluster_phv_i;		// clusters in this MAU group
 public:
    PHV_MAU_Group(PHV_Container::PHV_Word w, int n);
    //
    PHV_Container::PHV_Word width()			{ return width_i; }
    int number()					{ return number_i; }
    int avail_containers()				{ return avail_containers_i; }
    void avail_containers(int n)			{ avail_containers_i = n; }
    std::vector<PHV_Container *>& phv_containers()	{ return phv_containers_i; }
    std::vector<Cluster_PHV *>& clusters()		{ return cluster_phv_i; }
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
    std::map<PHV_Container::PHV_Word, std::vector<PHV_MAU_Group *>> PHV_MAU_i;
							// sorted PHV requirements <num, width>,
							// num decreasing then width decreasing
    bool allocate_containers(std::map<PHV_Container::PHV_Word, std::map<int, std::vector<Cluster_PHV *>>>& cluster_phv_map);
 public:
    PHV_MAU_Group_Assignments(Cluster_PHV_Requirements &phv_r);
    //
    std::map<PHV_Container::PHV_Word, std::vector<PHV_MAU_Group *>>& phv_mau_map()
    {
        return PHV_MAU_i;
    }
};
std::ostream &operator<<(std::ostream &, PHV_MAU_Group&);
std::ostream &operator<<(std::ostream &, PHV_MAU_Group*);
std::ostream &operator<<(std::ostream &, std::list<PHV_MAU_Group *>&);
std::ostream &operator<<(std::ostream &, std::vector<PHV_MAU_Group *>&);
std::ostream &operator<<(std::ostream &, std::vector<PHV_MAU_Group *>*);
std::ostream &operator<<(std::ostream &, PHV_MAU_Group_Assignments&);
//
#endif /* _TOFINO_PHV_CLUSTER_PHV_MAU_H_ */
