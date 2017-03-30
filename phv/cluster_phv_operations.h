#ifndef _TOFINO_PHV_CLUSTER_PHV_OPERATIONS_H_
#define _TOFINO_PHV_CLUSTER_PHV_OPERATIONS_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"
//
//***********************************************************************************
//
// class PHV_Field_Operations
// collects all operations field participates
//
//***********************************************************************************
//
class PHV_Field_Operations : public Inspector {
    //
    // define enum INVALID, R, W, RW
    //
 private:
    PhvInfo &phv;                     // phv object referenced through constructor
    PhvInfo::Field *dst_i = nullptr;  // destination of current statement
    bool preorder(const IR::MAU::Instruction *p) override;
    void end_apply() override;
    //
 public:
    explicit PHV_Field_Operations(PhvInfo &phv_f) : phv(phv_f) {}
    //
};
//
//
#endif /* _TOFINO_PHV_CLUSTER_PHV_OPERATIONS_H_ */
