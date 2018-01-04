#ifndef BF_P4C_PHV_CLUSTER_PHV_OPERATIONS_H_
#define BF_P4C_PHV_CLUSTER_PHV_OPERATIONS_H_

#include "bf-p4c/ir/thread_visitor.h"
#include "bf-p4c/phv/phv.h"
#include "bf-p4c/phv/phv_parde_mau_use.h"
#include "ir/ir.h"
#include "lib/map.h"
#include "lib/ordered_map.h"
#include "lib/range.h"

namespace PHV {
class Field;
}  // namespace PHV

class PhvInfo;

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
 private:
    PhvInfo &phv;                     // phv object referenced through constructor
    PHV::Field *dst_i = nullptr;  // destination of current statement
    bool preorder(const IR::MAU::Instruction *p) override;
    void end_apply() override;

 public:
    explicit PHV_Field_Operations(PhvInfo &phv_f) : phv(phv_f) { }
};

#endif /* BF_P4C_PHV_CLUSTER_PHV_OPERATIONS_H_ */
