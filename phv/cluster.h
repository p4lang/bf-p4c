#ifndef _TOFINO_PHV_CLUSTER_H_
#define _TOFINO_PHV_CLUSTER_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"

class MAU_Req;

//***********************************************************************************
//
// class Cluster computes the cluster set belonging to a field
// input:
// fields computed by PhvInfo phv
// these field pointers are not part of IR, they are calculated by &phv
// must perform cluster analysis after last &phv pass 
// output:
// accumulated map< field*, pointer to cluster_set of field* >
// 
//***********************************************************************************

class Cluster : public Inspector
{
public:
    enum class MAU_width {b32=32, b16=16, b8=8};
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
    // MAU_Req_i filled after MAU_Req analysis, post pass to Cluster analysis
    //
    std::map<MAU_width, std::vector<MAU_Req *>> MAU_Req_i;
				// sorted MAU requirements
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
    void insert_cluster(const PhvInfo::Field *, const PhvInfo::Field *);
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
    std::map<MAU_width, std::vector<MAU_Req *>>& mau_req_map()
    {
        return MAU_Req_i;
    }
};
//
//***********************************************************************************
//
// class MAU_Requirements computes MAU Requirements (width & number of containers)
// for every accumulated cluster after Cluster analysis
// class MAU_Req computes requirements for each cluster
// input:
// cluster.dst_map() computed by Cluster
// must perform MAU_Req analysis after &cluster pass 
// output:
// accumulated vector< MAU_Req* > for each of 32,16,8-bit widths
// in parent cluster
// 
//***********************************************************************************
//
class MAU_Req
{
    std::vector<const PhvInfo::Field *> cluster_vec_i;
    						// cluster vec sorted by decreasing field width
    int id_i;					// cluster id
    int width_i;				// max width of field in cluster
    int num_containers_i;			// number of containers
    Cluster::MAU_width container_width_i;	// container width in MAU group
    bool uniform_width_i;			// widths of fields in clusters different ?
    bool sliceable_i;				// can split cluster, move-based ops only ?
    //
    public:
    MAU_Req(std::set<const PhvInfo::Field *> *p) : cluster_vec_i(p->begin(), p->end())
    {
        if(!p)
        {
            WARNING("*****MAU_Req called w/ nullptr cluster_set******");
        }
        // cluster vector = sorted cluster set, decreasing field width
        std::sort(cluster_vec_i.begin(), cluster_vec_i.end(), [](const PhvInfo::Field *l, const PhvInfo::Field *r) {
            return l->size > r->size;
        });
        // max width of field
        width_i = 0;
        for(auto pfield: cluster_vec_i)
        {
           if(pfield->size > width_i)
           {
               width_i = pfield->size;
           }
        }
        // container width
        if(width_i > 16)
        {
            container_width_i = Cluster::MAU_width::b32;
        }
        else if(width_i > 8) 
        {
            container_width_i = Cluster::MAU_width::b16;
        }
        else
        {
            container_width_i = Cluster::MAU_width::b8;
        }
        // num containers of container_width
        num_containers_i = 0;
        for(auto pfield: cluster_vec_i)
        {
            num_containers_i += pfield->size/(int)container_width_i + (pfield->size%(int)container_width_i? 1 : 0);
        }
    }
    //
    int width()						{ return width_i; }
    int num_containers()				{ return num_containers_i; }
    Cluster::MAU_width container_width()		{ return container_width_i; }
    bool uniform_width()				{ return uniform_width_i; }
    bool sliceable()					{ return sliceable_i; }
    std::vector<const PhvInfo::Field *>& cluster_vec()	{ return cluster_vec_i; }
};
//
class MAU_Requirements
{
    Cluster &cluster_i;		// reference to parent
    //
    public:
    MAU_Requirements(Cluster &c) : cluster_i(c)
    {
        // create MAU Requirements from clusters
        if(! cluster_i.dst_map().size())
        {
            WARNING("*****MAU_Req called w/ 0 clusters******");
        }
        //
        for (auto p: Values(cluster_i.dst_map()))
        {
            MAU_Req *m = new MAU_Req(p);
            cluster_i.mau_req_map()[m->container_width()].push_back(m);
        }
        //
        // cluster MAU requirement = [qty, width]
        // sort based on width requirement, greatest width first
        // for each width sort based on quantity requirement
        //
        for (auto &p: Values(cluster_i.mau_req_map()))
        {
            std::sort(p.begin(), p.end(), [](MAU_Req *l, MAU_Req *r) {
                if(l->width() == r->width())
                {
                    return l->cluster_vec().size() > r->cluster_vec().size();
                }
                return l->width() > r->width();
            });
        } 
    }
};
//
std::ostream &operator<<(std::ostream &, MAU_Req*);
std::ostream &operator<<(std::ostream &, std::vector<MAU_Req *>&);
std::ostream &operator<<(std::ostream &, std::map<Cluster::MAU_width, std::vector<MAU_Req *>>&);
std::ostream &operator<<(std::ostream &, std::set<const PhvInfo::Field *>*);
std::ostream &operator<<(std::ostream &, std::vector<const PhvInfo::Field *>&);
std::ostream &operator<<(std::ostream &, Cluster &);
//
#endif /* _TOFINO_PHV_CLUSTER_H_ */
