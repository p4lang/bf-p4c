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
    static constexpr int SALU_HASH_SOURCE_LIMIT = 51;

 public:
    /** "Bitwise" operations are ALU instructions that operate independently on
     * each bit of the source(s) and destination.  For example, a logical AND
     * operation is bitwise, because dst[i] = src1[i] & src2[i] for each bit i.
     *
     * Operands of bitwise instructions can be split across PHV containers,
     * because bitwise instructions themselves can be split across ALUs.
     * Operands of non-bitwise instructions, on the other hand, cannot be
     * split, with the exception of certain arithmetic operations that can be
     * split across adjacent (even/odd) PHV containers.
     *
     * XXX(cole): We don't currently support splitting operands of arithmetic
     * instructions.
     *
     * The following instructions are bitwise.
     */
    static const ordered_set<cstring> BITWISE_OPS;

    // The following instructions are shift instructions, for which even the sources should have a
    // no-pack property.
    static const ordered_set<cstring> SHIFT_OPS;

 private:
    PhvInfo &phv;

    void processSaluInst(const IR::MAU::Instruction*);
    void processInst(const IR::MAU::Instruction*);
    bool preorder(const IR::MAU::Instruction*) override;

 public:
    explicit PHV_Field_Operations(PhvInfo &phv_f) : phv(phv_f) { }
};

#endif /* BF_P4C_PHV_CLUSTER_PHV_OPERATIONS_H_ */
