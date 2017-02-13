#ifndef _TOFINO_MAU_TABLE_LAYOUT_H_
#define _TOFINO_MAU_TABLE_LAYOUT_H_

#include "mau_visitor.h"
class PhvInfo;

class TableLayout : public MauModifier, Backtrack {
    const PhvInfo &phv;
    bool alloc_done = false;
    profile_t init_apply(const IR::Node *root) override;
    bool backtrack(trigger &trig) override;
    bool preorder(IR::MAU::Table *tbl) override;
    void setup_match_layout(IR::MAU::Table::Layout &, const IR::MAU::Table *);
    void setup_gateway_layout(IR::MAU::Table::Layout &, IR::MAU::Table *);
    void setup_layout_options(IR::MAU::Table *tbl, int immediate_bytes_reserved,
                              bool has_action_profile);
    void setup_ternary_layout_options(IR::MAU::Table *tbl, int immediate_bytes_reserved,
                                      bool has_action_profile);
    void setup_layout_option_no_match(IR::MAU::Table *tbl, int immediate_bytes_reserved);
 public:
    explicit TableLayout(const PhvInfo &phv) : phv(phv) {}
};

#endif /* _TOFINO_MAU_TABLE_LAYOUT_H_ */
