#ifndef _TOFINO_PHV_CLUSTER_PHV_REQ_H_
#define _TOFINO_PHV_CLUSTER_PHV_REQ_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"
#include "cluster.h"
#include "cluster_phv_container.h"
//
//
//***********************************************************************************
//
// class Cluster_PHV_Requirements computes Cluster Requirements (width & number of containers)
// for every computed cluster after Cluster analysis
// class Cluster_PHV computes requirements for each cluster
// conditions:
// must perform Cluster_PHV_Requirements analysis after &cluster pass 
// input:
// cluster.dst_map() computed by Cluster
// accumulated map<field*, pointer to cluster_set of field*>
// output:
// accumulated vector<Cluster_PHV*> for each of PHV_Word (32,16,8-bit) widths
// 
//***********************************************************************************
//
//
class Cluster_PHV
{
 private:
    std::vector<const PhvInfo::Field *> cluster_vec_i;
    							// cluster vec sorted by decreasing field width
    int id_i;						// cluster id
    PHV_Container::Ingress_Egress gress_i;		// ingress or egress
    PHV_Container::PHV_Word width_i;			// container width in PHV group
    bool uniform_width_i=false;				// field widths differ in cluster
    int max_width_i;					// max width of field in cluster
    int num_containers_i;				// number of containers
    bool sliceable_i;					// can split cluster, move-based ops only ?
    //
 public:
    Cluster_PHV(std::set<const PhvInfo::Field *> *p);
    //
    std::vector<const PhvInfo::Field *>& cluster_vec()	{ return cluster_vec_i; }
    PHV_Container::Ingress_Egress gress()		{ return gress_i; }
    PHV_Container::PHV_Word width()			{ return width_i; }
    void width(PHV_Container::PHV_Word w)		{ width_i = w; }
    bool uniform_width()				{ return uniform_width_i; }
    int max_width()					{ return max_width_i; }
    int num_containers()				{ return num_containers_i; }
    void num_containers(int n)				{ num_containers_i = n; }
    int num_containers(std::vector<const PhvInfo::Field *>&, PHV_Container::PHV_Word);
    bool sliceable()					{ return sliceable_i; }
};
//
//
class Cluster_PHV_Requirements
{
 private:
    Cluster &cluster_i;					// reference to parent cluster
    //
    std::map<PHV_Container::PHV_Word, std::map<int, std::vector<Cluster_PHV *>>> Cluster_PHV_i;
							// sorted PHV requirements <num, width>,
							// num decreasing then width decreasing
    std::vector<const PhvInfo::Field *> pov_fields_i;
							// sorted pov fields, width decreasing
							// some are not 1-bit fields
    std::vector<const PhvInfo::Field *> t_phv_fields_i;
							// fields that are not used through mau pipeline
							// sorted width decreasing
 public:
    Cluster_PHV_Requirements(Cluster &c);
    //
    std::map<PHV_Container::PHV_Word, std::map<int, std::vector<Cluster_PHV *>>>& cluster_phv_map()
    {
        return Cluster_PHV_i;
    }
    //
    std::vector<const PhvInfo::Field *>& pov_fields()	{ return pov_fields_i; }
    std::vector<const PhvInfo::Field *>& t_phv_fields()	{ return t_phv_fields_i; }
    //
};
//
//
std::ostream &operator<<(std::ostream &, Cluster_PHV&);
std::ostream &operator<<(std::ostream &, Cluster_PHV*);
std::ostream &operator<<(std::ostream &, std::list<Cluster_PHV *>&);
std::ostream &operator<<(std::ostream &, std::vector<Cluster_PHV *>*);
std::ostream &operator<<(std::ostream &, std::vector<Cluster_PHV *>&);
std::ostream &operator<<(std::ostream &, std::map<int, std::vector<Cluster_PHV *>>&);
std::ostream &operator<<(std::ostream &, Cluster_PHV_Requirements&);
//
#endif /* _TOFINO_PHV_CLUSTER_PHV_REQ_H_ */
