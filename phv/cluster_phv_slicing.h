#ifndef _TOFINO_PHV_CLUSTER_PHV_SLICING_H_
#define _TOFINO_PHV_CLUSTER_PHV_SLICING_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"
#include "cluster.h"
#include "cluster_phv_mau.h"
//
//***********************************************************************************
//
// cluster Slicing
// attempt to slice clusters to enable packing into phv slots
//
//***********************************************************************************
//
//
class Cluster_Slicing : public Visitor {
 private:
    PHV_MAU_Group_Assignments &phv_mau_i;           // PHV MAU Group Assignments
 public:
    Cluster_Slicing(PHV_MAU_Group_Assignments &phv_m)  // NOLINT(runtime/explicit)
        : phv_mau_i(phv_m) {}
    //
    const IR::Node *apply_visitor(const IR::Node *, const char *name = 0) override;
    void end_apply() override;
};
#endif /* _TOFINO_PHV_CLUSTER_PHV_SLICING_H_ */
