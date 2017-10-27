#ifndef BF_P4C_PHV_CHECK_FITTING_H_
#define BF_P4C_PHV_CHECK_FITTING_H_

#include "lib/error.h"
#include "phv_fields.h"
#include "phv_parde_mau_use.h"

/** Fail with an error if PHV analysis was unable to fit all fields within
 * available PHV containers.
 *
 * @pre PHV_Bind.
 */
class CheckFitting : public Visitor {
 private:
    const PhvInfo &phv;
    const PhvUse &uses;
    const bool ignorePHVOverflow;

 public:
    CheckFitting(const PhvInfo &phv, const PhvUse &uses, bool ignorePHVOverflow = false)
    : phv(phv), uses(uses), ignorePHVOverflow(ignorePHVOverflow) { }
    const IR::Node *apply_visitor(const IR::Node *n, const char *) override;

    /** Produce the set of fields that are not fully allocated to PHV containers.
     *
     * @param unallocated Unallocated fields are added to this set.
     */
    static ordered_set<PHV::Field *>
    collect_unallocated_fields(const PhvInfo &phv, const PhvUse &uses) {
        ordered_set<PHV::Field*> unallocated;

        for (auto& field : phv) {
            if (!uses.is_referenced(&field))
                continue;

            bitvec allocatedBits;
            field.foreach_alloc([&](const PHV::Field::alloc_slice& slice) {
                bitvec sliceBits(slice.field_bit, slice.width);
                allocatedBits |= sliceBits; });

            // XXX(seth): Long term it would be ideal to only allocate the bits we
            // actually need, but this will help us find bugs in the short term.
            bitvec allBitsInField(0, field.size);
            if (allocatedBits != allBitsInField)
                unallocated.insert(&field); }

        return unallocated;
    }
};

#endif /* BF_P4C_PHV_CHECK_FITTING_H_ */
