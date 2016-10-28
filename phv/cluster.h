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
    std::vector<const PhvInfo::Field *> pov_fields_i;
				// pov fields
    std::vector<const PhvInfo::Field *> fields_no_use_mau_i;
				// fields that are not used through mau pipeline
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
    void sanity_check_fields_use(const std::string&,
        std::set<const PhvInfo::Field *>,	// all fields
        std::set<const PhvInfo::Field *>,	// cluster fields
        std::set<const PhvInfo::Field *>,	// all - cluster
        std::set<const PhvInfo::Field *>,	// pov fields
        std::set<const PhvInfo::Field *>);	// no mau fields
    //
 public:
    Cluster(PhvInfo &p);
    //
    std::map<const PhvInfo::Field *, std::set<const PhvInfo::Field *>*>& dst_map()
    {
        return dst_map_i;
    }
    //
    std::vector<const PhvInfo::Field *>& pov_fields()		{ return pov_fields_i; }
    //
    std::vector<const PhvInfo::Field *>& fields_no_use_mau()	{ return fields_no_use_mau_i; }
    void compute_fields_no_use_mau();
};
//
//
std::ostream &operator<<(std::ostream &, std::set<const PhvInfo::Field *>*);
std::ostream &operator<<(std::ostream &, std::vector<const PhvInfo::Field *>&);
std::ostream &operator<<(std::ostream &, Cluster &);
//
#endif /* _TOFINO_PHV_CLUSTER_H_ */
