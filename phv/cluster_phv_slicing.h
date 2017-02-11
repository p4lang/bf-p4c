#ifndef _TOFINO_PHV_CLUSTER_PHV_SLICE_H_
#define _TOFINO_PHV_CLUSTER_PHV_SLICE_H_

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
// classes for two passes in cluster slicing
//***********************************************************************************
//
class PHV_Field_Operations : public Inspector {
 public:
    // define enum INVALID, R, W, RW
    explicit PHV_Field_Operations (const PhvInfo &phv_f) : phv(phv_f) {}
 private:
    const PhvInfo &phv;         // phv object referenced through constructor
    PhvInfo::Field *dst_i = nullptr;
                                // destination of current statement
    bool preorder(const IR::MAU::Instruction *p) override;
};
//
//
class Cluster_Slicing : public Visitor {
 private:
    PHV_MAU_Group_Assignments &phv_mau_i;           // PHV MAU Group Assignments
 public:
    Cluster_Slicing(PHV_MAU_Group_Assignments &phv_m) : phv_mau_i(phv_m) {}
    const IR::Node *apply_visitor(const IR::Node *, const char *name = 0) override;
    void end_apply() override;
};
#endif /* _TOFINO_PHV_CLUSTER_PHV_SLICE_H_ */
