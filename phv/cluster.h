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
    std::unordered_map<PhvInfo::Field *, std::unordered_set<const PhvInfo::Field *>> dst_map_i;
    PhvInfo::Field *dst_i = nullptr;

    bool preorder(const IR::Member* expression) override;
    bool preorder(const IR::Operation_Unary* expression) override;
    bool preorder(const IR::Operation_Binary* expression) override;
    bool preorder(const IR::Operation_Ternary* expression) override;
    bool preorder(const IR::Primitive* primitive) override;
    bool preorder(const IR::Operation* operation) override;

 public:
    Cluster(PhvInfo &p) : phv_i(p){}
    std::unordered_map<PhvInfo::Field *, std::unordered_set<const PhvInfo::Field *>>& dst_map() {return dst_map_i;}
};

std::ostream &operator<<(std::ostream &, Cluster &);

#endif /* _TOFINO_PHV_CLUSTER_H_ */
