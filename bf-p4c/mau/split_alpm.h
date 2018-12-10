#ifndef BF_P4C_MAU_SPLIT_ALPM_H_
#define BF_P4C_MAU_SPLIT_ALPM_H_

#include "ir/ir.h"
#include "lib/cstring.h"

/// This pass converts an alpm table into a pre_classifier table + an Atcam table.
class SplitAlpm : public Transform {
    static const std::set<unsigned> valid_partition_values;
    const IR::Node* postorder(IR::MAU::Table *tbl) override;
    const IR::MAU::Table* create_pre_classifier_tcam(
            IR::MAU::Table* tbl, IR::TempVar* tv, unsigned partition_index_bits,
            unsigned pre_classifer_number_entries);
    const IR::MAU::Table* create_atcam(IR::MAU::Table* table, IR::TempVar* tv,
            unsigned partition_count, unsigned partition_index_bits,
            unsigned subtrees_per_partition);
 public:
    static const cstring ALGORITHMIC_LPM_PARTITIONS;
    static const cstring ALGORITHMIC_LPM_SUBTREES_PER_PARTITION;

    SplitAlpm() {}
};

class AlpmSetup : public PassManager {
 public:
    AlpmSetup();
};
#endif  /* BF_P4C_MAU_SPLIT_ALPM_H_ */
