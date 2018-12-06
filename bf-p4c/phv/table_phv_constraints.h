#ifndef BF_P4C_PHV_TABLE_PHV_CONSTRAINTS_H_
#define BF_P4C_PHV_TABLE_PHV_CONSTRAINTS_H_

#include "ir/ir.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/pragma/pa_container_size.h"

/** This class enforces the following constraints related to match key sizes for ternary match
  * tables:
  * - For ternary match tables, the total size of fields used in the match key must be less than or
  *   equal to 66 bytes. For tables that approach this limit (specifically whose match key size is
  *   greater than or equal to 64 bytes), PHV allocation enforces bit in byte alignment to 0 for the
  *   match key fields.
  * xxx(Deep): Add match key constraints for exact match tables.
  * xxx(Deep): Calculate threshold dynamically.
  */

class TernaryMatchKeyConstraints : public MauModifier {
 private:
     static constexpr unsigned BITS_IN_BYTE = 8;
     static constexpr unsigned TERNARY_MATCH_KEY_BITS_THRESHOLD = 64;
     static constexpr unsigned MAX_EXACT_MATCH_KEY_BYTES = 128;
     static constexpr size_t MAX_TERNARY_MATCH_KEY_BITS = (44 * 12) - 4;

     PhvInfo      &phv;

     profile_t init_apply(const IR::Node* root) override;
     bool preorder(IR::MAU::Table* tbl) override;
     void end_apply() override;

     bool isATCAM(IR::MAU::Table* tbl) const;
     bool isTernary(IR::MAU::Table* tbl) const;

     void calculateTernaryMatchKeyConstraints(const IR::MAU::Table* tbl) const;

 public:
     explicit TernaryMatchKeyConstraints(PhvInfo &p) : phv(p) {}
};

/** The results of hash functions are copied into PHVs from the action data bus as immediate values.
  * We can use a maximum of 4 bytes of immediate data per logical table. Right now, the compiler
  * cannot share any of these action data slots. Therefore, we need to add constraints to ensure
  * that there is a maximum of 32-bits of hash bits generated per logical table.
  */
class HashFieldsContainerSize : public Inspector {
 private:
    static constexpr int ONE_BYTE = 8;
    static constexpr int TWO_BYTES = 16;
    static constexpr int THREE_BYTES = 24;

    PhvInfo                 &phv;
    PragmaContainerSize     &containerSize;

    /// Map of table to set of field slices used as outputs of hashing.
    ordered_map<const IR::MAU::Table*, std::vector<PHV::FieldSlice>> hashDests;
    /// Map of table to number of hash bits used by that table.
    ordered_map<const IR::MAU::Table*, int> hashBitsUsage;

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::MAU::Instruction* inst) override;
    void end_apply() override;

 public:
    explicit HashFieldsContainerSize(PhvInfo& p, PragmaContainerSize& pa)
        : phv(p), containerSize(pa) {}
};

/** This class is meant to gather PHV constraints enforced by MAU and the way fields are used in
  * the MAU. Some of these constraints are temporary fixes that are workarounds for current
  * limitations of our allocation algorithms.
  */
class TablePhvConstraints : public PassManager {
 public:
    explicit TablePhvConstraints(PhvInfo& p, PragmaContainerSize& pa) {
        addPasses({
            new TernaryMatchKeyConstraints(p),
            new HashFieldsContainerSize(p, pa)
        });
    }
};

#endif  /* BF_P4C_PHV_TABLE_PHV_CONSTRAINTS_H_ */
