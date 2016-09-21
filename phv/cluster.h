#ifndef _TOFINO_PHV_CLUSTER_H_
#define _TOFINO_PHV_CLUSTER_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"

class Cluster : public Inspector {
    PhvInfo	&phv_i;
    std::set<const PhvInfo::Field *> lhs_cluster_set_i;	// unique cluster ptrs
    std::map<const PhvInfo::Field *, std::set<const PhvInfo::Field *>*> dst_map_i;
    PhvInfo::Field *dst_i = nullptr;

    bool preorder(const IR::Member*) override;
    bool preorder(const IR::Operation_Unary*) override;
    bool preorder(const IR::Operation_Binary*) override;
    bool preorder(const IR::Operation_Ternary*) override;
    bool preorder(const IR::Primitive*) override;
    void postorder(const IR::Primitive*) override;
    bool preorder(const IR::Operation*) override;
    void end_apply() override;

 public:
    Cluster(PhvInfo &p) : phv_i(p)
    {
        for (auto iter = phv_i.begin(); iter != phv_i.end(); ++iter)
        {
            dst_map_i[&(*iter)] = nullptr;
        }
    }
    ~Cluster()
    {
       for(auto entry: dst_map_i)
       {
           if(entry.second)
           {
               delete entry.second;
               entry.second = nullptr;
           }
       }
    }
    std::set<const PhvInfo::Field *>& lhs_cluster_set()
    {
        return lhs_cluster_set_i;
    }
    std::map<const PhvInfo::Field *, std::set<const PhvInfo::Field *>*>& dst_map()
    {
        return dst_map_i;
    }
    void insert_cluster(const PhvInfo::Field *, const PhvInfo::Field *);
    void sanity_check_clusters(const std::string&, const PhvInfo::Field *);
    void sanity_check_clusters_unique(const std::string&);
    void dump_cluster_set(const std::string&, std::set<const PhvInfo::Field *>*);
    void dump_field(const PhvInfo::Field *);
};

std::ostream &operator<<(std::ostream &, Cluster &);

#endif /* _TOFINO_PHV_CLUSTER_H_ */
