#ifndef _TOFINO_PHV_CLUSTER_H_
#define _TOFINO_PHV_CLUSTER_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"
//
//
//***********************************************************************************
//
// class Cluster computes cluster sets belonging fields
// input:
// fields computed by PhvInfo phv
// these field pointers are not part of IR, they are calculated by &phv
// must perform cluster analysis after last &phv pass 
// output:
// accumulated map<field*, pointer to cluster_set of field*>
// 
//***********************************************************************************
//
//
class Cluster : public Inspector
{
 private:
    PhvInfo	&phv_i;		// phv object referenced through constructor
    //
    std::map<const PhvInfo::Field *, std::set<const PhvInfo::Field *>*> dst_map_i;
				// map of field to cluster it belongs
    std::set<const PhvInfo::Field *> lhs_unique_i;
				// maintains unique cluster ptrs
    PhvInfo::Field *dst_i = nullptr;
				// destination of current statement
    //
    bool preorder(const IR::Member*) override;
    bool preorder(const IR::Operation_Unary*) override;
    bool preorder(const IR::Operation_Binary*) override;
    bool preorder(const IR::Operation_Ternary*) override;
    bool preorder(const IR::Primitive*) override;
    bool preorder(const IR::Operation*) override;
    void postorder(const IR::Primitive*) override;
    void end_apply() override;
    //
    void set_field_range(PhvInfo::Field *field, const PhvInfo::Field::bitrange& bits);
    void insert_cluster(const PhvInfo::Field *, const PhvInfo::Field *);
    //
    void sanity_check_field_range(const std::string&);
    void sanity_check_clusters(const std::string&, const PhvInfo::Field *);
    void sanity_check_clusters_unique(const std::string&);
    //
 public:
    Cluster(PhvInfo &p) : phv_i(p)
    {
        for (auto field: phv_i)
        {
            dst_map_i[&field] = nullptr;
        }
    }
    std::map<const PhvInfo::Field *, std::set<const PhvInfo::Field *>*>& dst_map()
    {
        return dst_map_i;
    }
};
//
//***********************************************************************************
//
// class PHV_Cluster_Requirements computes Cluster Requirements (width & number of containers)
// for every computed cluster after Cluster analysis
// class PHV_Cluster computes requirements for each cluster
// input:
// cluster.dst_map() computed by Cluster
// must perform PHV_Cluster_Requirements analysis after &cluster pass 
// output:
// accumulated vector<PHV_Cluster*> for each of PHV_width (32,16,8-bit) widths
// PHV_Cluster_i filled after PHV_Cluster_Requirements analysis, post pass to Cluster analysis
// 
//***********************************************************************************
//
//
class PHV_Cluster;
//
//
class PHV_Cluster_Requirements
{
 public:
    enum class PHV_width {b32=32, b16=16, b8=8};
    //
 private:
    Cluster &cluster_i;					// reference to parent cluster
    //
    std::map<PHV_width, std::vector<PHV_Cluster *>> PHV_Cluster_i;
							// sorted PHV requirements <num, width>,
							// num decreasing then width decreasing
 public:
    PHV_Cluster_Requirements(Cluster &c);
    //
    std::map<PHV_width, std::vector<PHV_Cluster *>>& phv_cluster_map()
    {
        return PHV_Cluster_i;
    }
};
//
//
class PHV_Cluster
{
 private:
    std::vector<const PhvInfo::Field *> cluster_vec_i;
    							// cluster vec sorted by decreasing field width
    int id_i;						// cluster id
    int max_width_i;					// max width of field in cluster
    int num_containers_i;				// number of containers
    PHV_Cluster_Requirements::PHV_width container_width_i;	// container width in PHV group
    bool uniform_width_i;				// widths of fields in clusters different ?
    bool sliceable_i;					// can split cluster, move-based ops only ?
    //
 public:
    PHV_Cluster(std::set<const PhvInfo::Field *> *p);
    //
    int max_width()					{ return max_width_i; }
    int num_containers()				{ return num_containers_i; }
    PHV_Cluster_Requirements::PHV_width container_width()	{ return container_width_i; }
    bool uniform_width()				{ return uniform_width_i; }
    bool sliceable()					{ return sliceable_i; }
    std::vector<const PhvInfo::Field *>& cluster_vec()	{ return cluster_vec_i; }
};
//
//
class PHV_MAU_Group;
//
//
class PHV_MAU_Group_Assignments
{
 private:
    PHV_Cluster_Requirements &phv_requirements_i;	// reference to parent PHV Requirements
    //
    const std::map<PHV_Cluster_Requirements::PHV_width, int> num_groups_i {
        {PHV_Cluster_Requirements::PHV_width::b32, 4},
        {PHV_Cluster_Requirements::PHV_width::b16, 6},
        {PHV_Cluster_Requirements::PHV_width::b8, 4},
    };
    std::map<PHV_Cluster_Requirements::PHV_width, std::vector<PHV_MAU_Group *>> PHV_MAU_i;
							// sorted PHV requirements <num, width>,
							// num decreasing then width decreasing
 public:
    PHV_MAU_Group_Assignments(PHV_Cluster_Requirements &phv_r);
    //
    std::map<PHV_Cluster_Requirements::PHV_width, std::vector<PHV_MAU_Group *>>& phv_mau_map()
    {
        return PHV_MAU_i;
    }
};
//
//
class PHV_MAU_Group
{
 private:
    PHV_Cluster_Requirements::PHV_width container_width_i;	// container width in PHV group
    int group_number_i;					// 1..4 [32], 1..6 [16], 1..4 [8]
    int avail_containers_i = 16;			// number of available containers
    std::vector<PHV_Cluster *> phv_clusters_i;		// clusters in this MAU group
 public:
    PHV_MAU_Group(PHV_Cluster_Requirements::PHV_width w, int n);
    //
    PHV_Cluster_Requirements::PHV_width container_width()	{ return container_width_i; }
    int group_number()					{ return group_number_i; }
    int avail_containers()				{ return avail_containers_i; }
};
//
//
std::ostream &operator<<(std::ostream &, PHV_Cluster*);
std::ostream &operator<<(std::ostream &, std::vector<PHV_Cluster *>&);
std::ostream &operator<<(std::ostream &, PHV_Cluster_Requirements &);
std::ostream &operator<<(std::ostream &, PHV_MAU_Group *);
std::ostream &operator<<(std::ostream &, std::vector<PHV_MAU_Group *> &);
std::ostream &operator<<(std::ostream &, PHV_MAU_Group_Assignments &);
std::ostream &operator<<(std::ostream &, std::set<const PhvInfo::Field *>*);
std::ostream &operator<<(std::ostream &, std::vector<const PhvInfo::Field *>&);
std::ostream &operator<<(std::ostream &, Cluster &);
//
#endif /* _TOFINO_PHV_CLUSTER_H_ */
