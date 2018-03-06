#ifndef BF_P4C_PHV_TABLE_PHV_CONSTRAINTS_H_
#define BF_P4C_PHV_TABLE_PHV_CONSTRAINTS_H_

#include "ir/ir.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/phv/phv_fields.h"

/** This class is meant to gather PHV constraints enforced by tables and the way fields are used in
  * those tables. Here is a running list of constraints gathered by this pass:
  * - For ternary match tables, the total size of fields used in the match key must be less than or
  *   equal to 66 bytes. For tables that approach this limit (specifically whose match key size is
  *   greater than or equal to 64 bytes), PHV allocation enforces bit in byte alignment to 0 for the
  *   match key fields.
  * xxx(Deep): Add match key constraints for exact match tables.
  * xxx(Deep): Calculate threshold dynamically.
  */

class TablePhvConstraints : public MauModifier {
 private:
     static constexpr unsigned BITS_IN_BYTE = 8;
     static constexpr unsigned TERNARY_MATCH_KEY_BITS_THRESHOLD = 64;
     static constexpr unsigned MAX_EXACT_MATCH_KEY_BYTES = 128;

     PhvInfo      &phv;

     profile_t init_apply(const IR::Node* root) override;
     bool preorder(IR::MAU::Table* tbl) override;
     void end_apply() override;

     bool isATCAM(IR::MAU::Table* tbl) const;
     bool isTernary(IR::MAU::Table* tbl) const;

     void calculateTernaryMatchKeyConstraints(const IR::MAU::Table* tbl) const;

 public:
     explicit TablePhvConstraints(PhvInfo &p) : phv(p) {}
};

#endif  /* BF_P4C_PHV_TABLE_PHV_CONSTRAINTS_H_ */
