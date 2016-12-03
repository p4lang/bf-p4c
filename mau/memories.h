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
    static constexpr int EXACT_TABLES_MAX = 16;
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
        int match_tables;
        int match_bus_min;
        int match_RAMs;
        int tind_tables;
        int tind_RAMs;
        int action_tables;
        int action_bus_min;
        int action_RAMs;
        int ternary_tables;
        int ternary_TCAMs;
        int stats_tables;
        int stats_RAMs;
        int meter_tables;
        int meter_RAMs;

        void clear() {
            match_tables = 0; match_bus_min = 0; match_RAMs = 0; tind_tables = 0;
            tind_RAMs = 0; action_tables = 0; action_bus_min = 0; action_RAMs = 0;
            ternary_tables = 0; ternary_TCAMs = 0; stats_tables = 0; stats_RAMs = 0;
            meter_tables = 0; meter_RAMs = 0;
        }
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
        vector<Row>     row;
        vector<Row>                          color_mapram;
        vector<std::pair<int, int>>          home_row;
        vector<std::pair<int, unsigned>>     ways;
        int                                  per_row;
        bool                                 unattached_profile = false;
        cstring                              profile_name;
        // depth in memory units + mask to use for memory selection per way
        void visit(Memories &mem, std::function<void(cstring &)>) const;
    };

    struct table_alloc {
        const IR::MAU::Table *table;
        const IXBar::Use *match_ixbar;
        map<cstring, Memories::Use>* memuse;
        int provided_entries;
        int calculated_entries;
        int attached_gw_bytes;
        table_alloc *table_link;
        explicit table_alloc(const IR::MAU::Table *t, const IXBar::Use *mi,
                             map<cstring, Memories::Use> *mu, int e)
                : table(t), match_ixbar(mi), memuse(mu), provided_entries(e),
                  calculated_entries(0), attached_gw_bytes(0), table_link(nullptr) {}
        void link_table(table_alloc *ta) {table_link = ta;}
    };

    struct SRAM_group {
        table_alloc *ta;
        int depth;
        int width;
        int placed;
        int number;
        int recent_home_row;
        cstring name;
        enum type_t { EXACT, ACTION, STATS, METER, SELECTOR, TIND } type;
        struct color_mapram_group {
            int needed;
            int placed;
            bool required;
            bool waiting_for_selector;
            bool all_placed() { return needed == placed; }
            int left_to_place() { return needed - placed; }
            color_mapram_group() : needed(0), placed(0), required(false) {}
        };
        color_mapram_group cm;
        bool requires_ab;
        explicit SRAM_group(table_alloc *t, int d, int w, int n, type_t ty)
            : ta(t), depth(d), width(w), placed(0), number(n), type(ty), cm(),
              requires_ab(false) {}
        explicit SRAM_group(table_alloc *t, int d, int n, type_t ty)
            : ta(t), depth(d), width(0), placed(0), number(n), type(ty), cm(),
              requires_ab(false) {}
        void dbprint(std::ostream &out) const {
            out << ta->table->name << " way #" << number << " depth: " << depth
                << " width: " << width << " placed: " << placed;
        }
        int left_to_place() { return depth - placed; }
        bool all_placed() { return (depth == placed); }
        bool needs_ab() { return requires_ab && !all_placed();}
        cstring name_addition() {
            switch (type) {
                case EXACT:    return "";
                case ACTION:   return "$action";
                case STATS:    return "$stats";
                case METER:    return "$meter";
                case SELECTOR: return "$selector";
                case TIND:     return "$tind";
                default:       return "";
            }
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
    vector<IR::ActionProfile *> action_profiles;
    vector<table_alloc *>       selector_tables;
    vector<table_alloc *>       stats_tables;
    vector<table_alloc *>       meter_tables;
    vector<SRAM_group *>        action_bus_users;
    vector<SRAM_group *>        suppl_bus_users;
    vector<table_alloc *>       gw_tables;


    void clear();
    void clear_table_vectors();
    void add_table(const IR::MAU::Table *t, const IR::MAU::Table *gw,
                   TableResourceAlloc *resources, int entries);
    bool analyze_tables(mem_info &mi);
    void calculate_column_balance(mem_info &mi, unsigned &row);
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
    int stats_per_row(int min_width, int max_width, IR::CounterType type);
    void find_action_candidates(int row, int mask, action_fill &action, action_fill &suppl,
                                action_fill &oflow, bool stats_available, bool meter_available,
                                action_fill &curr_oflow);
    void adjust_RAMs_available(action_fill &curr_oflow, int &suppl_RAMs_available,
                               int action_RAMs_available, int row, bool left_side);
    void best_candidates(action_fill &best_fit_action, action_fill &best_fit_suppl,
                         action_fill &next_action, action_fill &next_suppl,
                         action_fill &curr_oflow, int action_RAMs_available,
                         int suppl_RAMs_available, bool stats_available,
                         bool meter_available, unsigned mask);
    void fill_out_masks(unsigned suppl_masks[3], unsigned action_masks[3], int RAMs[3],
                        int RAMs_filled[3], bool is_suppl[3], int row, unsigned mask,
                        int suppl_RAMs_available, int action_RAMs_available);
    void action_row_trip(action_fill &action, action_fill &suppl, action_fill &oflow,
                         action_fill &best_fit_action, action_fill &best_fit_suppl,
                         action_fill &curr_oflow, action_fill &next_action,
                         action_fill &next_suppl, int action_RAMs_available,
                         int suppl_RAMs_available, bool left_side, int order[3], int RAMs[3],
                         bool is_suppl[3]);
    void action_oflow_only(action_fill &action, action_fill &oflow,
                           action_fill &best_fit_action, action_fill &next_action,
                           action_fill &curr_oflow, int RAMs_available, int order[3]);
    void color_mapram_candidates(action_fill &suppl, action_fill &oflow, unsigned mask);
    void fill_out_color_mapram(action_fill &action, int row, unsigned mask, bool is_oflow);
    bool fill_out_action_row(action_fill &action, int row, int side, unsigned mask,
                             bool is_oflow, bool is_twoport);
    void action_side(action_fill &action, action_fill &suppl, action_fill &oflow,
                     bool removed[3], int row, int side, unsigned mask);
    void calculate_curr_oflow(action_fill &action, action_fill &suppl, action_fill &oflow,
                              bool removed[3], action_fill &curr_oflow,
                              action_fill &twoport_oflow, bool right_side);
    bool allocate_all_gw();
    table_alloc *find_corresponding_exact_match(cstring name);
    bool gw_search_bus_fit(table_alloc *ta, table_alloc *exact_ta, int width_sect,
                           int row, int col);

    bool alloc2Port(cstring table_name, int entries, int entries_per_word, Use &alloc);
    bool allocActionRams(cstring table_name, int width, int depth, Use &alloc);
    bool allocBus(cstring table_name, Alloc2Dbase<cstring> &bus_use, Use &alloc);
    bool allocRams(cstring table_name, int width, int depth,
                   Alloc2Dbase<cstring> &use, Alloc2Dbase<cstring> *bus, Use &alloc);
    bool allocTable(cstring name, const IR::MAU::Table *table, int &entries,
                    map<cstring, Use> &alloc, const IXBar::Use &);
    void update(cstring table_name, const Use &alloc);
    void update(const map<cstring, Use> &alloc);
    void remove(cstring table_name, const Use &alloc);
    void remove(const map<cstring, Use> &alloc);
    friend std::ostream &operator<<(std::ostream &, const Memories &);
};

#endif /* _TOFINO_MAU_MEMORIES_H_ */
