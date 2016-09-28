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
    enum class MAU_width {b32, b16, b8};
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
    std::set<const PhvInfo::Field *>* cluster_set_i;
    				// ptr to cluster set
    int id_i;			// cluster id
    int num_fields_i;		// number of fields in cluster
    int width_i;		// max width of field in cluster
    int num_containers_i;	// number of containers
    int container_width_i;	// container width in MAU group
    bool sliceable_i;		// can split cluster, move-based ops only ?
    bool uniform_width_i;	// widths of fields in clusters different ?
    //
    public:
    MAU_Req(std::set<const PhvInfo::Field *> *p) : cluster_set_i(p)
    {
        BUG_CHECK(p, "**********MAU_Req called w/ nullptr cluster_set***********");
        num_fields_i = cluster_set_i->size();
        width_i = 0;
        for(auto pfield: *cluster_set_i)
        {
           if(pfield->size > width_i)
           {
               width_i = pfield->size;
           }
        }
    }
    //
    int width()		{ return width_i; }
    int num_fields()	{ return num_fields_i; }
    std::set<const PhvInfo::Field *>* cluster_set() { return cluster_set_i; }
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
        //
        BUG_CHECK(cluster_i.dst_map().size(), "**********MAU_Req called w/ 0 clusters***********");
        //
        for (auto p: Values(cluster_i.dst_map()))
        {
            MAU_Req *m = new MAU_Req(p);
            if(m->width() > 16)
            {
                cluster_i.mau_req_map()[Cluster::MAU_width::b32].push_back(m);
            }
            else if(m->width() > 8) 
            {
                cluster_i.mau_req_map()[Cluster::MAU_width::b16].push_back(m);
            }
            else
            {
                cluster_i.mau_req_map()[Cluster::MAU_width::b8].push_back(m);
            }
        }
        //
        // sort based on width requirement, greatest width first
        // for each width sort based on quantity requirement
        //
        for (auto &p: Values(cluster_i.mau_req_map()))
        {
            std::sort(p.begin(), p.end(), [](MAU_Req *l, MAU_Req *r) {
                if(l->width() == r->width())
                {
                    return l->num_fields() > r->num_fields();
                }
                return l->width() > r->width();
            });
        } 
    }
};
//
std::ostream &operator<<(std::ostream &, std::set<const PhvInfo::Field *>*);
std::ostream &operator<<(std::ostream &, Cluster &);
//
#endif /* _TOFINO_PHV_CLUSTER_H_ */
