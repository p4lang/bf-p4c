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
    safe_vector<int> dleft_hash_sizes;
    int entries = 0;
    int srams = 0, maprams = 0, tcams = 0;
    int select_bus_split = -1;
    int action_format_index = -1;
    bool previously_widened = false;
    bool identity = false;
    LayoutOption() {}
    explicit LayoutOption(const IR::MAU::Table::Layout l, int i)
        : layout(l), action_format_index(i) {}
    LayoutOption(const IR::MAU::Table::Layout l, const IR::MAU::Table::Way w, int i)
        : layout(l), way(w), action_format_index(i) {}
    void clear_mems() {
        srams = 0;
        maprams = 0;
        tcams = 0;
        entries = 0;
        select_bus_split = -1;
        way_sizes.clear();
        partition_sizes.clear();
        dleft_hash_sizes.clear();
    }

    int logical_tables() const {
        if (partition_sizes.size() > 0)
            return static_cast<int>(partition_sizes.size());
        else if (dleft_hash_sizes.size() > 0)
            return static_cast<int>(dleft_hash_sizes.size());
        return 1;
    }
};

class LayoutChoices {
 public:
    ordered_map<cstring, safe_vector<LayoutOption>> total_layout_options;
    ordered_map<cstring, safe_vector<ActionFormat::Use>> total_action_formats;
    safe_vector<LayoutOption> get_layout_options(const IR::MAU::Table *t) const {
        safe_vector<LayoutOption> empty;
        if (t == nullptr)
            return empty;
        if (total_layout_options.find(t->name) == total_layout_options.end())
            return empty;
        return total_layout_options.at(t->name);
    }

    safe_vector<ActionFormat::Use> get_action_formats(const IR::MAU::Table *t) const {
        ActionFormat::Use use;
        safe_vector<ActionFormat::Use> empty;
        if (t == nullptr)
            return empty;
        else if (total_action_formats.find(t->name) == total_action_formats.end())
            return empty;
        return total_action_formats.at(t->name);
    }

    void clear() {
        total_layout_options.clear();
        total_action_formats.clear();
    }
};

class TableLayout : public MauModifier, Backtrack {
    // In order to know how many field sections can be packed together into the same byte
    struct MatchByteKey {
        cstring name;
        int lo;
        int ixbar_multiplier;
        int match_multiplier;

        MatchByteKey(cstring n, int l, int im, int mm)
            : name(n), lo(l), ixbar_multiplier(im), match_multiplier(mm) { }

        bool operator<(const MatchByteKey &mbk) const {
            if (name != mbk.name) return name < mbk.name;
            if (lo != mbk.lo) return lo < mbk.lo;
            if (ixbar_multiplier < mbk.ixbar_multiplier)
                return ixbar_multiplier < mbk.ixbar_multiplier;
            if (match_multiplier < mbk.match_multiplier)
                return match_multiplier < mbk.match_multiplier;
            return false;
        }
    };

    static constexpr int MIN_PACK = 1;
    static constexpr int MAX_PACK = 9;
    // FIXME: Technically this is 5, but need to update version bit information
    static constexpr int MAX_ENTRIES_PER_ROW = 5;

    const PhvInfo &phv;
    LayoutChoices &lc;
    bool alloc_done = false;
    int get_hit_actions(const IR::MAU::Table *tbl);
    profile_t init_apply(const IR::Node *root) override;
    bool backtrack(trigger &trig) override;
    bool preorder(IR::MAU::Table *tbl) override;
    bool preorder(IR::MAU::Action *act) override;
    bool preorder(IR::MAU::InputXBarRead *read) override;
    bool preorder(IR::MAU::Selector *sel) override;
    void check_for_alpm(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl,
                         cstring &partition_index);
    void setup_instr_and_next(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl);
    void setup_match_layout(IR::MAU::Table::Layout &, const IR::MAU::Table *);
    void setup_gateway_layout(IR::MAU::Table::Layout &, IR::MAU::Table *);
    void setup_exact_match(IR::MAU::Table *tbl, int action_data_bytes_in_table,
                           int immediate_bits, int index);
    void setup_layout_options(IR::MAU::Table *tbl);
    void setup_action_layout(IR::MAU::Table *tbl);
    void setup_ternary_layout_options(IR::MAU::Table *tbl);
    void setup_layout_option_no_match(IR::MAU::Table *tbl);
    void attach_random_seed(IR::MAU::Table *tbl);
    bool can_be_hash_action(IR::MAU::Table *tbl, std::string &reason);
    void add_hash_action_option(IR::MAU::Table *tbl, bool &hash_action_only);

 public:
    explicit TableLayout(const PhvInfo &p, LayoutChoices &l) : phv(p), lc(l) {}
    static void check_for_ternary(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl);
    static void check_for_atcam(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl,
                                cstring &partition_index, const PhvInfo& phv);
};

/// Run after TablePlacement to fix up anything needed in the layout as a result
class FinalTableLayout : public MauModifier {
    bool preorder(IR::MAU::Counter *cntr) override;

 public:
    explicit FinalTableLayout(const PhvInfo &, LayoutChoices &) {}
};

#endif /* BF_P4C_MAU_TABLE_LAYOUT_H_ */
