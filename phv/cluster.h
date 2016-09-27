#ifndef _TOFINO_PHV_CLUSTER_H_
#define _TOFINO_PHV_CLUSTER_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"

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

class Cluster : public Inspector {
    PhvInfo	&phv_i;		// phv object referenced through constructor
    //
    class MAU_Req
    {
        Cluster &cluster_i;	// reference to parent
        std::set<const PhvInfo::Field *>* cluster_set_i;
        			// ptr to cluster set
        int id_i;		// cluster id
        int num_fields_i;	// number of fields in cluster
        int width_i;		// max width of field in cluster
        int num_containers_i;	// number of containers
        int container_width_i;	// container width in MAU group
        bool sliceable_i;	// can split cluster, move-based ops only ?
        bool uniform_width_i;	// widths of fields in clusters different ?
        //
        public:
        MAU_Req(Cluster &c, std::set<const PhvInfo::Field *> *p) : cluster_i(c), cluster_set_i(p)
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
            if(width_i > 16)
            {
                cluster_i.MAU_Req_32().push_back(this);
            }
            else if(width_i > 8) 
            {
                cluster_i.MAU_Req_16().push_back(this);
            }
            else
            {
                cluster_i.MAU_Req_8().push_back(this);
            }
        }
        ~MAU_Req(){}
        //
        int width()		{ return width_i; }
        int num_fields()	{ return num_fields_i; }
        std::set<const PhvInfo::Field *>* cluster_set() { return cluster_set_i; }
    };
    vector<MAU_Req*> MAU_Req_32_i;	// sorted MAU requirements for 32b containers
    vector<MAU_Req*> MAU_Req_16_i;	// sorted MAU requirements for 16b containers
    vector<MAU_Req*> MAU_Req_8_i;	// sorted MAU requirements for 8b containers
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
    ~Cluster()
    {
       //garbage collector will clean this up
       //for(auto entry: dst_map_i)
       //{
           //if(entry.second)
           //{
               //delete entry.second;
               //entry.second = nullptr;
           //}
       //}
    }
    vector<MAU_Req*>& MAU_Req_32()	{ return MAU_Req_32_i; }
    vector<MAU_Req*>& MAU_Req_16()	{ return MAU_Req_16_i; }
    vector<MAU_Req*>& MAU_Req_8()	{ return MAU_Req_8_i; }
    std::map<const PhvInfo::Field *, std::set<const PhvInfo::Field *>*>& dst_map()
    {
        return dst_map_i;
    }
};
//
std::ostream &operator<<(std::ostream &, std::set<const PhvInfo::Field *>*);
std::ostream &operator<<(std::ostream &, Cluster &);
//
#endif /* _TOFINO_PHV_CLUSTER_H_ */
