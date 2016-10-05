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
// class Cluster computes cluster sets of fields
// conditions:
// must perform cluster analysis after last &phv pass 
// input:
// fields computed by PhvInfo phv
// these field pointers are not part of IR, they are calculated by &phv
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
//
//***********************************************************************************
//
// class PHV_Container represents the state of a PHV container word
// after PHV Assignment, Fields are mapped to PHV_Containers
//
//***********************************************************************************
//
//
class PHV_Container
{
 public:
    enum class PHV_Word {b32=32, b16=16, b8=8};
    enum class Container_status {EMPTY='E', PARTIAL='P', FULL='F'};
    struct content
    {
        int lo_i, hi_i;					// range of bits within container used by field
        const PhvInfo::Field *field_i;
        int lo() const			{ return lo_i; }
        int hi() const			{ return hi_i; }
        int width() const		{ return hi_i - lo_i + 1; }
        const PhvInfo::Field *field()	{ return field_i; }
    };
    //
 private:
    PHV_Word width_i;					// width of container
    int number_i;					// 1..16 within group
    Container_status status_i = Container_status::EMPTY;
    std::vector<content> fields_i;			// fields in this container
 public:
    PHV_Container(PHV_Word w, int n);
    //
    PHV_Word width()					{ return width_i; }
    int number()					{ return number_i; }
    Container_status status()				{ return status_i; }
    void status(Container_status s)			{ status_i = s; }
    std::vector<content>& fields()			{ return fields_i; }
};
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
    int max_width_i;					// max width of field in cluster
    int num_containers_i;				// number of containers
    PHV_Container::PHV_Word width_i;			// container width in PHV group
    bool uniform_width_i;				// widths of fields in clusters different ?
    bool sliceable_i;					// can split cluster, move-based ops only ?
    //
 public:
    Cluster_PHV(std::set<const PhvInfo::Field *> *p);
    //
    int max_width()					{ return max_width_i; }
    int num_containers()				{ return num_containers_i; }
    PHV_Container::PHV_Word width()			{ return width_i; }
    bool uniform_width()				{ return uniform_width_i; }
    bool sliceable()					{ return sliceable_i; }
    std::vector<const PhvInfo::Field *>& cluster_vec()	{ return cluster_vec_i; }
};
//
//
class Cluster_PHV_Requirements
{
 private:
    Cluster &cluster_i;					// reference to parent cluster
    //
    std::map<PHV_Container::PHV_Word, std::vector<Cluster_PHV *>> Cluster_PHV_i;
							// sorted PHV requirements <num, width>,
							// num decreasing then width decreasing
 public:
    Cluster_PHV_Requirements(Cluster &c);
    //
    std::map<PHV_Container::PHV_Word, std::vector<Cluster_PHV *>>& cluster_phv_map()
    {
        return Cluster_PHV_i;
    }
};
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
    std::vector<PHV_Container *>& phv_containers()	{ return phv_containers_i; }
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
 public:
    PHV_MAU_Group_Assignments(Cluster_PHV_Requirements &phv_r);
    //
    std::map<PHV_Container::PHV_Word, std::vector<PHV_MAU_Group *>>& phv_mau_map()
    {
        return PHV_MAU_i;
    }
};
//
//
std::ostream &operator<<(std::ostream &, std::vector<PHV_Container::content>&);
std::ostream &operator<<(std::ostream &, PHV_Container*);
std::ostream &operator<<(std::ostream &, std::vector<PHV_Container *> &);
std::ostream &operator<<(std::ostream &, PHV_MAU_Group*);
std::ostream &operator<<(std::ostream &, std::vector<PHV_MAU_Group *> &);
std::ostream &operator<<(std::ostream &, PHV_MAU_Group_Assignments &);
//
std::ostream &operator<<(std::ostream &, Cluster_PHV*);
std::ostream &operator<<(std::ostream &, std::vector<Cluster_PHV *>&);
std::ostream &operator<<(std::ostream &, Cluster_PHV_Requirements &);
//
std::ostream &operator<<(std::ostream &, std::set<const PhvInfo::Field *>*);
std::ostream &operator<<(std::ostream &, std::vector<const PhvInfo::Field *>&);
std::ostream &operator<<(std::ostream &, Cluster &);
//
#endif /* _TOFINO_PHV_CLUSTER_H_ */
