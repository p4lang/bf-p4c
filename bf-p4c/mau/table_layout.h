#ifndef BF_P4C_MAU_TABLE_LAYOUT_H_
#define BF_P4C_MAU_TABLE_LAYOUT_H_

#include "bf-p4c/mau/action_format.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "lib/safe_vector.h"

class LayoutOption {
 public:
    IR::MAU::Table::Layout layout;
    IR::MAU::Table::Way way;
    safe_vector<int> way_sizes;
    safe_vector<int> partition_sizes;
    int entries = 0;
    int srams = 0, maprams = 0, tcams = 0;
    LayoutOption() {}
    explicit LayoutOption(const IR::MAU::Table::Layout l) : layout(l) {}
    LayoutOption(const IR::MAU::Table::Layout l, const IR::MAU::Table::Way w)
                : layout(l), way(w) {}
    void clear_mems() {
        srams = 0;
        maprams = 0;
        tcams = 0;
        entries = 0;
        way_sizes.clear();
        partition_sizes.clear();
    }

    int logical_tables() const {
        return static_cast<size_t>(partition_sizes.size());
    }
};

class LayoutChoices {
 public:
    ordered_map<cstring, safe_vector<LayoutOption>> total_layout_options;
    ordered_map<cstring, ActionFormat::Use> total_action_formats;
    safe_vector<LayoutOption> get_layout_options(const IR::MAU::Table *t) const {
        safe_vector<LayoutOption> empty;
        if (t == nullptr)
            return empty;
        if (total_layout_options.find(t->name) == total_layout_options.end())
            return empty;
        return total_layout_options.at(t->name);
    }

    ActionFormat::Use get_action_format(const IR::MAU::Table *t) const {
        ActionFormat::Use use;
        if (t == nullptr)
            return use;
        else if (total_action_formats.find(t->name) == total_action_formats.end())
            return use;
        return total_action_formats.at(t->name);
    }

    void clear() {
        total_layout_options.clear();
        total_action_formats.clear();
    }
};

class TableLayout : public MauModifier, Backtrack {
    const PhvInfo &phv;
    LayoutChoices &lc;
    bool alloc_done = false;
    int get_hit_actions(const IR::MAU::Table *tbl);
    profile_t init_apply(const IR::Node *root) override;
    bool backtrack(trigger &trig) override;
    bool preorder(IR::MAU::Table *tbl) override;
    bool preorder(IR::MAU::Action *act) override;
    bool preorder(IR::MAU::InputXBarRead *read) override;
    void check_for_atcam(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl,
                         cstring &partition_index);
    void check_for_ternary(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl);
    void setup_match_layout(IR::MAU::Table::Layout &, const IR::MAU::Table *);
    void setup_gateway_layout(IR::MAU::Table::Layout &, IR::MAU::Table *);
    void setup_exact_match(IR::MAU::Table *tbl, int action_data_bytes);
    void setup_layout_options(IR::MAU::Table *tbl, int immediate_bytes_reserved);
    void setup_ternary_layout_options(IR::MAU::Table *tbl, int immediate_bytes_reserved);
    void setup_layout_option_no_match(IR::MAU::Table *tbl, int immediate_bytes_reserved);
 public:
    explicit TableLayout(const PhvInfo &p, LayoutChoices &l) : phv(p), lc(l) {}
};

#endif /* BF_P4C_MAU_TABLE_LAYOUT_H_ */
