#ifndef BF_P4C_MAU_FLATROCK_TABLE_LAYOUT_H_
#define BF_P4C_MAU_FLATROCK_TABLE_LAYOUT_H_

#include "bf-p4c/mau/action_format.h"
#include "bf-p4c/mau/table_layout.h"
#include "ir/ir-generated.h"

namespace Flatrock {

class LayoutChoices : public ::LayoutChoices {
    void setup_exact_match(const IR::MAU::Table *tbl, const IR::MAU::Table::Layout &layout_proto,
            ActionData::FormatType_t format_type, int action_data_bytes_in_table,
            int immediate_bits, int index) override;
    void setup_layout_option_no_match(const IR::MAU::Table *tbl,
            const IR::MAU::Table::Layout &layout, ActionData::FormatType_t format_type) override;
    void setup_ternary_layout(const IR::MAU::Table *tbl,
            const IR::MAU::Table::Layout &layout_proto, ActionData::FormatType_t format_type,
            int action_data_bytes_in_table, int immediate_bits, int index) override;
    void add_layout_option(const IR::MAU::Table *tbl, const IR::MAU::Table::Layout &layout,
            const IR::MAU::Table::Way &way, ActionData::FormatType_t format_type,
            const int entries, const int single_entry_bits,
            const int overhead_bits, const int index);
 public:
    LayoutChoices(PhvInfo &p, const ReductionOrInfo &ri, SplitAttachedInfo &a)
        : ::LayoutChoices(p, ri, a) {}
};

}  // namespace Flatrock
#endif /* BF_P4C_MAU_FLATROCK_TABLE_LAYOUT_H_ */
