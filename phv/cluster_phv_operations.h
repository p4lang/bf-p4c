#ifndef _TOFINO_PHV_CLUSTER_PHV_OPERATIONS_H_
#define _TOFINO_PHV_CLUSTER_PHV_OPERATIONS_H_

#include "phv.h"
#include "phv_fields.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/range.h"
#include "tofino/ir/thread_visitor.h"

/** @brief Annotate each Field in PhvInfo with the instructions it's involved
 * in.
 *
 * Specifically, include the name of the instruction, whether it is a
 * move-based instruction, and whether it is read, written, both, or
 * invalidated. This information is stored in the Field.operations field.
 *
 * @pre An up-to-date PhvInfo data structure.
 *
 * @post The operations field of all Field objects in @phv_f will be populated.
 */
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
