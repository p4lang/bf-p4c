#ifndef _TOFINO_PHV_CLUSTER_H_
#define _TOFINO_PHV_CLUSTER_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"

class Cluster : public Inspector {
    PhvInfo	&phv;
    vector<vector<PhvInfo::Field *>>	fields;

    bool preorder(const IR::Member* expression) override;
    bool preorder(const IR::Operation_Unary* expression) override;
    bool preorder(const IR::Operation_Binary* expression) override;
    bool preorder(const IR::Operation_Ternary* expression) override;
    bool preorder(const IR::Operation* operation) override;

 public:
    Cluster(PhvInfo &p) : phv(p){}
};

#endif /* _TOFINO_PHV_CLUSTER_H_ */
