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
    std::map<const PhvInfo::Field *, std::set<const PhvInfo::Field *>*> dst_map_i;
				// map of field to cluster it belongs
    std::set<const PhvInfo::Field *> lhs_unique_i;
				// maintains unique cluster ptrs
    PhvInfo::Field *dst_i = nullptr;
				// destination of current statement

    bool preorder(const IR::Member*) override;
    bool preorder(const IR::Operation_Unary*) override;
    bool preorder(const IR::Operation_Binary*) override;
    bool preorder(const IR::Operation_Ternary*) override;
    bool preorder(const IR::Primitive*) override;
    bool preorder(const IR::Operation*) override;
    void postorder(const IR::Primitive*) override;
    void end_apply() override;

    void insert_cluster(const PhvInfo::Field *, const PhvInfo::Field *);
    void sanity_check_clusters(const std::string&, const PhvInfo::Field *);
    void sanity_check_clusters_unique(const std::string&);

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
    std::map<const PhvInfo::Field *, std::set<const PhvInfo::Field *>*>& dst_map()
    {
        return dst_map_i;
    }
};

std::ostream &operator<<(std::ostream &, std::set<const PhvInfo::Field *>*);
std::ostream &operator<<(std::ostream &, Cluster &);

#endif /* _TOFINO_PHV_CLUSTER_H_ */
