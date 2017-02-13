#ifndef _TOFINO_MAU_MEMORIES_H_
#define _TOFINO_MAU_MEMORIES_H_

#include <algorithm>
#include "lib/alloc.h"
#include "ir/ir.h"
#include "input_xbar.h"

struct Memories {
    /* track memory allocations within a single stage */
    static constexpr int SRAM_ROWS = 8;
    static constexpr int SRAM_COLUMNS = 10;
    static constexpr int LEFT_SIDE_COLUMNS = 4;
    static constexpr int MAPRAM_COLUMNS = 6;
    static constexpr int TCAM_ROWS = 12;
    static constexpr int TCAM_COLUMNS = 2;
    static constexpr int TABLES_MAX = 16;
    static constexpr int TERNARY_TABLES_MAX = 8;
    static constexpr int ACTION_TABLES_MAX = 16;
    static constexpr int BUS_COUNT = 2;
    static constexpr int STATS_ALUS = 4;
    static constexpr int METER_ALUS = 4;

    Alloc2D<cstring, SRAM_ROWS, SRAM_COLUMNS>          sram_use;
    unsigned                                           sram_inuse[SRAM_ROWS] = { 0 };
    Alloc2D<cstring, TCAM_ROWS, TCAM_COLUMNS>          tcam_use;
    Alloc2D<cstring, SRAM_ROWS, 2>                     gateway_use;
    Alloc2D<std::pair<cstring, int>, SRAM_ROWS, 2>     sram_match_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                     sram_print_match_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                     action_data_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                     tind_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                     overflow_bus;
    Alloc1D<cstring, SRAM_ROWS>                        twoport_bus;
    Alloc1D<std::pair<cstring, int>, SRAM_ROWS - 1>    vert_overflow_bus;
    Alloc2D<cstring, SRAM_ROWS, MAPRAM_COLUMNS>        mapram_use;
    unsigned                                           mapram_inuse[SRAM_ROWS] = {0};
    Alloc1D<cstring, SRAM_ROWS>                        stateful_bus;
    int gw_bytes_per_sb[SRAM_ROWS][BUS_COUNT] = {{0}};
    Alloc1D<cstring, STATS_ALUS>                       stats_alus;
    Alloc1D<cstring, METER_ALUS>                       meter_alus;
    struct mem_info {
        int match_tables = 0;
        int match_bus_min = 0;
        int match_RAMs = 0;
        int tind_tables = 0;
        int tind_RAMs = 0;
        int action_tables = 0;
        int action_bus_min = 0;
        int action_RAMs = 0;
        int ternary_tables = 0;
        int ternary_TCAMs = 0;
        int stats_tables = 0;
        int stats_RAMs = 0;
        int meter_tables = 0;
        int meter_RAMs = 0;
        int selector_tables = 0;
        int selector_RAMs = 0;
        int no_match_tables = 0;
        int independent_gw_tables = 0;

        void clear() {
            memset(this, 0, sizeof(mem_info));
        }

        int total_RAMs() {
            return match_RAMs + action_RAMs + stats_RAMs + meter_RAMs + selector_RAMs + tind_RAMs;
        }

        int left_side_RAMs() { return tind_RAMs; }
        int right_side_RAMs() { return meter_RAMs + stats_RAMs + selector_RAMs; }
        int non_SRAM_RAMs() { return left_side_RAMs() + right_side_RAMs() + action_RAMs; }
        int columns(int RAMs) { return (RAMs + SRAM_COLUMNS - 1) / SRAM_COLUMNS; }
        bool constraint_check();
    };



    /* Memories::Use tracks memory use of a single table */
    struct Use {
        enum type_t { EXACT, TERNARY, GATEWAY, TIND, TWOPORT, ACTIONDATA } type;
        /* FIXME -- when tracking EXACT table memuse, do we need to track which way
         * each memory is allocated to?  For now, we do not. */
        struct Row {
            int         row, bus;
            vector<int> col, mapcol;
            explicit Row(int r, int b = -1) : row(r), bus(b) {}
            void dbprint(std::ostream &out) const {
                out << "Row " << row << " with bus " << bus;
            }
        };
        struct Way {
            int size;
            unsigned select_mask;
            vector<std::pair<int, int>> rams;
            explicit Way(int s, unsigned sm) : size(s), select_mask(sm) {}
        };
        vector<Row>                          row;
        vector<Row>                          color_mapram;
        vector<std::pair<int, int>>          home_row;
        vector<Way>                          ways;
        int                                  per_row;
        bool                                 unattached_profile = false;
        cstring                              profile_name;
        bool                                 unattached_selector = false;
        cstring                              selector_name;
        // depth in memory units + mask to use for memory selection per way
        void visit(Memories &mem, std::function<void(cstring &)>) const;
    };


    struct table_alloc {
        const IR::MAU::Table *table;
        const IXBar::Use *match_ixbar;
        map<cstring, Memories::Use>* memuse;
        const IR::MAU::Table::LayoutOption *layout_option;
        int provided_entries;
        int calculated_entries;
        int attached_gw_bytes = 0;
        table_alloc *table_link = nullptr;
        explicit table_alloc(const IR::MAU::Table *t, const IXBar::Use *mi,
                             map<cstring, Memories::Use> *mu,
                             const IR::MAU::Table::LayoutOption *lo, const int e)
                : table(t), match_ixbar(mi), memuse(mu), layout_option(lo), provided_entries(e),
                  calculated_entries(0), attached_gw_bytes(0), table_link(nullptr) {}
        void link_table(table_alloc *ta) {table_link = ta;}
    };

    struct SRAM_group {
        table_alloc *ta;
        int depth;
        int width;
        int placed;
        int number;
        int hash_group;
        const IR::Attached *attached;
        int recent_home_row;
        enum type_t { EXACT, ACTION, STATS, METER, SELECTOR, TIND } type;
        struct color_mapram_group {
            int needed;
            int placed;
            bool required;
            bool all_placed() { return needed == placed; }
            int left_to_place() { return needed - placed; }
            color_mapram_group() : needed(0), placed(0), required(false) {}
        };
        struct selector_info {
            SRAM_group *sel_group;
            unordered_set<SRAM_group *> action_groups;
            selector_info() : sel_group(nullptr) {}
            bool sel_linked() { return sel_group != nullptr; }
            bool act_linked() { return !action_groups.empty(); }
            bool sel_all_placed() { return sel_group->all_placed(); }
            bool action_all_placed() {
                if (action_groups.empty())
                    BUG("No action corresponding with this selector");
                for (auto *action_group : action_groups) {
                    if (!action_group->all_placed())
                        return false;
                }
                return true;
            }
            bool sel_any_placed() {
                return sel_group->any_placed();
            }
            bool action_any_placed() {
                if (action_groups.empty())
                    BUG("No action corresponding with this selector");
                for (auto *action_group : action_groups) {
                    if (action_group->any_placed())
                        return true;
                }
                return false;
            }
            bool is_act_corr_group(SRAM_group *corr) {
                return action_groups.find(corr) != action_groups.end();
            }
            bool is_sel_corr_group(SRAM_group *corr) {
                return corr == sel_group;
            }
            bool one_action_left() {
                int total_unplaced_groups = 0;
                for (auto *action_group : action_groups)
                    if (action_group->left_to_place() > 0)
                        total_unplaced_groups++;
                return total_unplaced_groups == 1;
            }
            int action_left_to_place() {
                int left_to_place = 0;
                for (auto *action_group : action_groups)
                    left_to_place += action_group->left_to_place();
                return left_to_place;
            }
            SRAM_group *action_group_left() {
                if (!one_action_left())
                    BUG("Trying to call action_group_left with more than one action left");
                for (auto *action_group : action_groups)
                    if (action_group->left_to_place() > 0)
                        return action_group;
                return nullptr;
            }
        };
        selector_info sel;
        color_mapram_group cm;
        bool requires_ab;
        explicit SRAM_group(table_alloc *t, int d, int w, int n, type_t ty)
            : ta(t), depth(d), width(w), placed(0), number(n), hash_group(0), attached(nullptr),
              type(ty), sel(), cm(), requires_ab(false) {}
        explicit SRAM_group(table_alloc *t, int d, int n, type_t ty)
            : ta(t), depth(d), width(0), placed(0), number(n), hash_group(0), attached(nullptr),
              type(ty), sel(), cm(), requires_ab(false) {}
        explicit SRAM_group(table_alloc *t, int d, int w, int n, int h, type_t ty)
            : ta(t), depth(d), width(w), placed(0), number(n), hash_group(h), attached(nullptr),
              type(ty), sel(), cm(), requires_ab(false) {}
        void dbprint(std::ostream &out) const {
            out << ta->table->name << " way #" << number << " depth: " << depth
                << " width: " << width << " placed: " << placed;
        }
        int unique_bus(int i) { return hash_group * width + i; }
        int left_to_place() { return depth - placed; }
        bool all_placed() { return (depth == placed); }
        bool any_placed() { return (placed != 0); }
        bool needs_ab() { return requires_ab && !all_placed(); }
        bool sel_act_placed(SRAM_group *corr) {
            if (type == ACTION && sel.sel_linked() && sel.is_sel_corr_group(corr)
                && corr->sel.action_all_placed())
                return true;
            else
                return false;
        }
        int RAMs_required() const {
            if (type == SELECTOR) {
                int action_depth = 0;
                for (auto *action_group : sel.action_groups)
                    action_depth += action_group->depth;
                return depth + action_depth;
            } else {
                return depth;
            }
        }
        int total_left_to_place() {
            if (type == SELECTOR) {
                int action_depth = 0;
                for (auto *action_group : sel.action_groups)
                    action_depth += action_group->left_to_place();
                return left_to_place() + action_depth;
            } else {
                return left_to_place();
            }
        }
        cstring get_name() {
            if (type == TIND)
                return ta->table->get_use_name(nullptr, false, IR::MAU::Table::TIND_NAME);
            else if (type == ACTION && attached == nullptr)
                return ta->table->get_use_name(nullptr, false, IR::MAU::Table::AD_NAME);
            else
                return ta->table->get_use_name(attached);
        }
    };

    struct action_fill {
        SRAM_group *group;
        unsigned mask;
        unsigned mapram_mask;
        size_t index;
        action_fill() : group(nullptr), mask(0), mapram_mask(0), index(0) {}
        void clear() { group = nullptr; mask = 0; mapram_mask = 0; index = 0; }
        void clear_masks() {mask = 0; mapram_mask = 0; }
    };

    struct profile_info {
        const IR::ActionProfile *ap;
        const IR::ActionSelector *as;
        table_alloc *linked_ta;
        explicit profile_info(const IR::ActionProfile *a, table_alloc *t) : ap(a), linked_ta(t) {}
        explicit profile_info(const IR::ActionSelector *a, table_alloc *t) : as(a), linked_ta(t) {}
    };



    static constexpr int ACTION_IND = 0;
    static constexpr int SUPPL_IND = 1;
    static constexpr int OFLOW_IND = 2;

    vector<table_alloc *>       tables;
    vector<table_alloc *>       exact_tables;
    vector<SRAM_group *>        exact_match_ways;
    vector<table_alloc *>       ternary_tables;
    vector<table_alloc *>       tind_tables;
    vector<SRAM_group *>        tind_groups;
    vector<table_alloc *>       action_tables;
    vector<table_alloc *>       indirect_action_tables;
    vector<profile_info *>      action_profiles;
    vector<table_alloc *>       selector_tables;
    vector<table_alloc *>       stats_tables;
    vector<table_alloc *>       meter_tables;
    vector<SRAM_group *>        action_bus_users;
    vector<SRAM_group *>        suppl_bus_users;
    vector<table_alloc *>       gw_tables;
    vector<table_alloc *>       no_match_tables;
    vector<table_alloc *>       hash_action_tables;
    vector<table_alloc *>       action_payload_gws;
    vector<table_alloc *>       normal_gws;
    vector<table_alloc *>       hash_action_gws;

    void clear();
    void clear_table_vectors();
    void clear_uses();
    void add_table(const IR::MAU::Table *t, const IR::MAU::Table *gw,
                   TableResourceAlloc *resources, const IR::MAU::Table::LayoutOption *lo,
                   int entries);
    bool analyze_tables(mem_info &mi);
    void calculate_column_balance(mem_info &mi, unsigned &row);
    bool cut_from_left_side(mem_info &mi, int left_given_columns, int right_given_columns);
    bool allocate_all();
    bool allocate_all_exact(unsigned column_mask);
    vector<int> way_size_calculator(int ways, int RAMs_needed);
    vector<std::pair<int, int>> available_SRAMs_per_row(unsigned mask, table_alloc *ta,
                                                        int depth);
    vector<int> available_match_SRAMs_per_row(unsigned row_mask, unsigned total_mask, int row,
                                                 table_alloc *ta, int width_sect);
    void break_exact_tables_into_ways();
    int match_bus_available(table_alloc *ta, int width, int row);
    bool find_best_row_and_fill_out(unsigned column_mask);
    bool fill_out_row(SRAM_group *placed_wa, int row, unsigned column_mask);
    bool pack_way_into_RAMs(SRAM_group *wa, int row, int &cols, unsigned column_mask);
    SRAM_group *find_best_candidate(SRAM_group *placed_wa, int row, int &loc);
    void compress_ways();

    bool allocate_all_ternary();
    int ternary_TCAMs_necessary(table_alloc *ta, int &mid_bytes_needed);
    bool find_ternary_stretch(int TCAMs_necessary, int mid_bytes_needed, int &row, int &col);

    bool allocate_all_tind();
    void find_tind_groups();
    int find_best_tind_row(SRAM_group *tg, int &bus);
    void compress_tind_groups();

    bool allocate_all_action();
    void find_action_bus_users();
    void action_bus_selectors_indirects();
    void action_bus_meters_counters();
    void find_action_candidates(int row, int mask, action_fill &action, action_fill &suppl,
                                action_fill &oflow, bool stats_available, bool meter_available,
                                action_fill &curr_oflow, action_fill &sel_unplaced);
    void adjust_RAMs_available(action_fill &curr_oflow, int &suppl_RAMs_available,
                               int action_RAMs_available, int row, bool left_side);
    void best_candidates(action_fill &best_fit_action, action_fill &best_fit_suppl,
                         action_fill &next_action, action_fill &next_suppl,
                         action_fill &curr_oflow, int action_RAMs_available,
                         int suppl_RAMs_available, bool stats_available,
                         bool meter_available, unsigned mask, action_fill &sel_unplaced);
    void fill_out_masks(unsigned suppl_masks[3], unsigned action_masks[3], int RAMs[3],
                        int RAMs_filled[3], bool is_suppl[3], int row, unsigned mask,
                        int suppl_RAMs_available, int action_RAMs_available);
    void action_row_trip(action_fill &action, action_fill &suppl, action_fill &oflow,
                         action_fill &best_fit_action, action_fill &best_fit_suppl,
                         action_fill &curr_oflow, action_fill &next_action,
                         action_fill &next_suppl, int action_RAMs_available,
                         int suppl_RAMs_available, bool left_side, int order[3]);
    void action_oflow_only(action_fill &action, action_fill &oflow,
                           action_fill &best_fit_action, action_fill &next_action,
                           action_fill &curr_oflow, int RAMs_available, int order[3]);
    void set_up_RAM_counts(action_fill &action, action_fill &suppl, action_fill &oflow,
                           int order[3], int RAMs[3], bool is_suppl[3],
                           int suppl_RAMs_available);
    void color_mapram_candidates(action_fill &suppl, action_fill &oflow, unsigned mask);
    void fill_out_color_mapram(action_fill &action, int row, unsigned mask, bool is_oflow);
    bool fill_out_action_row(action_fill &action, int row, int side, unsigned mask,
                             bool is_oflow, bool is_twoport);
    void action_side(action_fill &action, action_fill &suppl, action_fill &oflow,
                     bool removed[3], int row, int side, unsigned mask);
    void calculate_curr_oflow(action_fill &action, action_fill &suppl, action_fill &oflow,
                              bool removed[3], action_fill &curr_oflow,
                              action_fill &twoport_oflow, bool right_side);
    void calculate_sel_unplaced(action_fill &action, action_fill &suppl, action_fill &oflow,
                                action_fill &sel_unplaced);
    bool can_place_selector(action_fill &curr_oflow, SRAM_group *curr_check,
                            int suppl_RAMs_available, int action_RAMs_available,
                            action_fill &sel_unplaced);
    void selector_candidate_setup(action_fill &action, action_fill &suppl, action_fill &oflow,
                                  action_fill &curr_oflow, action_fill &sel_unplaced,
                                  action_fill &next_suppl, int order[3],
                                  int action_RAMs_available, int suppl_RAMs_available);
    void action_bus_users_log();
    bool allocate_all_gw();
    table_alloc *find_corresponding_exact_match(cstring name);
    bool gw_search_bus_fit(table_alloc *ta, table_alloc *exact_ta, int width_sect,
                           int row, int col);
    bool allocate_all_no_match();
    void allocate_one_no_match(table_alloc *ta, int row, int col);
    void update(cstring table_name, const Use &alloc);
    void update(const map<cstring, Use> &alloc);
    void remove(cstring table_name, const Use &alloc);
    void remove(const map<cstring, Use> &alloc);
    friend std::ostream &operator<<(std::ostream &, const Memories &);
};

#endif /* _TOFINO_MAU_MEMORIES_H_ */
