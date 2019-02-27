#ifndef BF_P4C_MAU_RESOURCE_ESTIMATE_H_
#define BF_P4C_MAU_RESOURCE_ESTIMATE_H_

#include "bf-p4c/mau/table_layout.h"
#include "lib/safe_vector.h"

struct StageUseEstimate {
    static constexpr int MIN_WAYS = 1;
    static constexpr int MAX_WAYS = 8;
    static constexpr int MAX_METER_ALUS = 4;
    static constexpr int MAX_STATS_ALUS = 4;
    // FIXME: This is a quick workaround that will need to change as the tables need to expand
    static constexpr int MAX_DLEFT_HASH_SIZE = 23;
    static constexpr int COMPILER_DEFAULT_SELECTOR_POOLS = 4;
    static constexpr int SINGLE_RAMLINE_POOL_SIZE = 120;
    static constexpr int MAX_MOD = 31;
    static constexpr int MAX_MOD_SHIFT = 5;
    static constexpr int MAX_POOL_RAMLINES = MAX_MOD << MAX_MOD_SHIFT;
    static constexpr int MOD_INPUT_BITS = 10;

    typedef std::map<const IR::MAU::AttachedMemory *, int> attached_entries_t;
    int logical_ids = 0;
    int srams = 0;
    int tcams = 0;
    int maprams = 0;
    int exact_ixbar_bytes = 0;
    int ternary_ixbar_groups = 0;
    int meter_alus = 0;
    int stats_alus = 0;

    safe_vector<LayoutOption> layout_options;
    safe_vector<ActionFormat::Use> action_formats;
    MeterFormat::Use meter_format;
    size_t preferred_index;
    StageUseEstimate() {}
    StageUseEstimate &operator+=(const StageUseEstimate &a) {
        logical_ids += a.logical_ids;
        srams += a.srams;
        tcams += a.tcams;
        maprams += a.maprams;
        exact_ixbar_bytes += a.exact_ixbar_bytes;
        ternary_ixbar_groups += a.ternary_ixbar_groups;
        return *this; }
    StageUseEstimate(const IR::MAU::Table *, int &, attached_entries_t &, const LayoutChoices *lc,
                     bool prev_placed, bool table_placement = false);

    StageUseEstimate operator+(const StageUseEstimate &a) const {
        StageUseEstimate rv = *this; rv += a; return rv; }
    static StageUseEstimate max() {
        StageUseEstimate rv;
        rv.logical_ids = StageUse::MAX_LOGICAL_IDS;
        rv.srams = StageUse::MAX_SRAMS;
        rv.tcams = StageUse::MAX_TCAMS;
        rv.maprams = StageUse::MAX_MAPRAMS;
        rv.exact_ixbar_bytes = StageUse::MAX_IXBAR_BYTES;
        rv.ternary_ixbar_groups = StageUse::MAX_TERNARY_GROUPS;
        rv.stats_alus = MAX_METER_ALUS;
        rv.meter_alus = MAX_STATS_ALUS;
        return rv; }
    bool operator<=(const StageUseEstimate &a) {
        return logical_ids <= a.logical_ids && srams <= a.srams && tcams <= a.tcams &&
               maprams <= a.maprams; }
    void clear() {
        logical_ids = 0; srams = 0; tcams = 0; maprams = 0;
        exact_ixbar_bytes = 0; ternary_ixbar_groups = 0;
    }
    void options_to_ways(const IR::MAU::Table *tbl, int entries);
    void options_to_rams(const IR::MAU::Table *tbl, const attached_entries_t &att_entries,
                         bool table_placement);
    void select_best_option(const IR::MAU::Table *tbl);
    void options_to_ternary_entries(const IR::MAU::Table *tbl, int entries);
    void select_best_option_ternary();
    void options_to_atcam_entries(const IR::MAU::Table *tbl, int entries);
    void options_to_dleft_entries(const IR::MAU::Table *tbl, const attached_entries_t &att_entries);
    void calculate_attached_rams(const IR::MAU::Table *tbl, const attached_entries_t &att_entries,
                                 LayoutOption *lo, bool table_placement);
    void fill_estimate_from_option(int &entries);
    const LayoutOption *preferred() const {
    if (layout_options.empty())
        return nullptr;
    else
        return &layout_options[preferred_index]; }

    const ActionFormat::Use *preferred_action_format() const {
        auto option = preferred();
        if (option == nullptr)
            return nullptr;
        return &action_formats[option->action_format_index];
    }

    const MeterFormat::Use *preferred_meter_format() const {
        return &meter_format;
    }

    void determine_initial_layout_option(const IR::MAU::Table *tbl, int &entries,
                                         attached_entries_t &, bool table_placement);
    bool adjust_choices(const IR::MAU::Table *tbl, int &entries, attached_entries_t &);

    bool calculate_for_leftover_srams(const IR::MAU::Table *tbl, int srams_left,
                                      int &entries, attached_entries_t &);
    void calculate_for_leftover_tcams(const IR::MAU::Table *tbl, int srams_left, int tcams_left,
                                      int &entries, attached_entries_t &);
    void calculate_for_leftover_atcams(const IR::MAU::Table *tbl, int srams_left,
                                       int &entries, attached_entries_t &);
    void known_srams_needed(const IR::MAU::Table *tbl, const attached_entries_t &,
                            LayoutOption *lo);
    void unknown_srams_needed(const IR::MAU::Table *tbl, LayoutOption *lo, int srams_left);
    void unknown_tcams_needed(const IR::MAU::Table *tbl, LayoutOption *lo, int tcams_left,
                              int srams_left);
    void unknown_atcams_needed(const IR::MAU::Table *tbl, LayoutOption *lo, int srams_left);
    void calculate_way_sizes(const IR::MAU::Table *tbl, LayoutOption *lo, int &calculated_depth);
    void calculate_partition_sizes(LayoutOption *lo, int ram_depth);
    bool ways_provided(const IR::MAU::Table *tbl, LayoutOption *lo, int &calculated_depth);
    void srams_left_best_option(int srams_left);
    void tcams_left_best_option();
    struct RAM_counter {
        int per_word;
        int width;
        bool need_srams;
        bool need_maprams;
        RAM_counter() : per_word(0), width(0), need_srams(false), need_maprams(false) {}
        RAM_counter(int p, int w, bool ns, bool nm) : per_word(p), width(w), need_srams(ns),
                                                      need_maprams(nm) {}
    };
    void calculate_per_row_vector(safe_vector<RAM_counter> &per_word_and_width,
                                  const IR::MAU::Table *tbl, LayoutOption *lo);

    int stages_required() const;
};


int CounterPerWord(const IR::MAU::Counter *ctr);
int CounterWidth(const IR::MAU::Counter *ctr);
int RegisterPerWord(const IR::MAU::StatefulAlu *reg);
int ActionDataPerWord(const IR::MAU::Table::Layout *layout, int *width);
int ActionDataHuffmanVPNBits(const IR::MAU::Table::Layout *layout);
int ActionDataVPNStartPosition(const IR::MAU::Table::Layout *layout);
int ActionDataVPNIncrement(const IR::MAU::Table::Layout *layout);
int TernaryIndirectPerWord(const IR::MAU::Table::Layout *layout, const IR::MAU::Table *tbl);
int IdleTimePerWord(const IR::MAU::IdleTime *idletime);
int SelectorModBits(const IR::MAU::Selector *sel);
int SelectorShiftBits(const IR::MAU::Selector *sel);
int SelectorHashModBits(const IR::MAU::Selector *sel);
int SelectorLengthShiftBits(const IR::MAU::Selector *sel);
int SelectorLengthBits(const IR::MAU::Selector *sel);

class RangeEntries : public MauInspector {
    static constexpr int MULTIRANGE_DISTRIBUTION_LIMIT = 8;
    static constexpr int RANGE_ENTRY_PERCENTAGE = 25;

 private:
    const PhvInfo &phv;
    int table_entries;
    int total_TCAM_lines = 0;
    int max_entry_TCAM_lines = 1;

    bool preorder(const IR::MAU::TableSeq *) override { return false; }
    bool preorder(const IR::MAU::Action *) override { return false; }
    bool preorder(const IR::MAU::BackendAttached *) override { return false; }
    bool preorder(const IR::MAU::TableKey *) override;
    void postorder(const IR::MAU::Table *) override;

 public:
    int TCAM_lines() { return total_TCAM_lines; }
    RangeEntries(const PhvInfo &p, int te) : phv(p), table_entries(te) {}
};

std::ostream &operator<<(std::ostream &, const StageUseEstimate &);

#endif /* BF_P4C_MAU_RESOURCE_ESTIMATE_H_ */
