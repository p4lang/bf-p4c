#ifndef BF_P4C_MAU_MEMORIES_H_
#define BF_P4C_MAU_MEMORIES_H_

#include <algorithm>
#include "bf-p4c/mau/input_xbar.h"
#include "bf-p4c/mau/table_format.h"
#include "ir/ir.h"
#include "lib/alloc.h"
#include "lib/safe_vector.h"

struct Memories {
    /* track memory allocations within a single stage */
    static constexpr int SRAM_ROWS = 8;
    static constexpr int SRAM_COLUMNS = 10;
    static constexpr int LOGICAL_TABLES = 16;
    static constexpr int LEFT_SIDE_COLUMNS = 4;
    static constexpr int RIGHT_SIDE_COLUMNS = SRAM_COLUMNS - LEFT_SIDE_COLUMNS;
    static constexpr int LEFT_SIDE_RAMS = LEFT_SIDE_COLUMNS * SRAM_ROWS;
    static constexpr int RIGHT_SIDE_RAMS = RIGHT_SIDE_COLUMNS * SRAM_ROWS;
    static constexpr int MAPRAM_COLUMNS = 6;
    static constexpr int SRAM_DEPTH = 1024;
    static constexpr int TCAM_ROWS = 12;
    static constexpr int TCAM_COLUMNS = 2;
    static constexpr int TCAM_DEPTH = 512;
    static constexpr int TABLES_MAX = 16;
    static constexpr int TERNARY_TABLES_MAX = 8;
    static constexpr int ACTION_TABLES_MAX = 16;
    static constexpr int GATEWAYS_PER_ROW = 2;
    static constexpr int BUS_COUNT = 2;
    static constexpr int STATS_ALUS = 4;
    static constexpr int METER_ALUS = 4;
    static constexpr int MAX_DATA_SWBOX_ROWS = 5;
    static constexpr int COLOR_MAPRAM_PER_ROW = 4;
    static constexpr int IMEM_ADDRESS_BITS = 6;
    static constexpr int IMEM_LOOKUP_BITS = 3;
    static constexpr int NUM_IDLETIME_BUS = 10;
    static constexpr int MAX_PARTITION_RAMS_PER_ROW = 5;

    static constexpr int LOGICAL_ROW_MISSING_OFLOW = 8;

    struct search_bus_info {
        cstring name;
        int width_section = 0;
        int hash_group = 0;
        int logical_table = 0;
        bool init = false;

        search_bus_info() {}
        search_bus_info(cstring n, int ws, int hg, int lt)
            : name(n), width_section(ws), hash_group(hg), logical_table(lt), init(true) {}

        bool operator==(const search_bus_info &sbi) {
            return name == sbi.name && width_section == sbi.width_section
                   && hash_group == sbi.hash_group && logical_table == sbi.logical_table;
        }

        bool operator!=(const search_bus_info &sbi) {
            return !operator==(sbi);
        }

        bool free() { return !init; }
        friend std::ostream &operator<<(std::ostream &, const search_bus_info &);
    };

 private:
    Alloc2D<cstring, SRAM_ROWS, SRAM_COLUMNS>          sram_use;
    unsigned                                           sram_inuse[SRAM_ROWS] = { 0 };
    Alloc2D<cstring, TCAM_ROWS, TCAM_COLUMNS>          tcam_use;
    Alloc2D<cstring, SRAM_ROWS, 2>                     gateway_use;
    Alloc2D<search_bus_info, SRAM_ROWS, 2>             sram_search_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                     sram_print_search_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                     sram_match_bus;
    // int tcam_group_use[TCAM_ROWS][TCAM_COLUMNS] = {{-1}};
    int tcam_midbyte_use[TCAM_ROWS/2][TCAM_COLUMNS] = {{-1}};
    Alloc2D<cstring, SRAM_ROWS, 2>                     tind_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                     payload_use;
    Alloc2D<cstring, SRAM_ROWS, 2>                     action_data_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                     overflow_bus;
    Alloc1D<cstring, SRAM_ROWS>                        twoport_bus;
    Alloc1D<std::pair<cstring, int>, SRAM_ROWS - 1>    vert_overflow_bus;
    Alloc2D<cstring, SRAM_ROWS, MAPRAM_COLUMNS>        mapram_use;
    unsigned                                           mapram_inuse[SRAM_ROWS] = {0};
    Alloc2D<cstring, 2, NUM_IDLETIME_BUS>              idletime_bus;
    bool gw_bytes_reserved[SRAM_ROWS][BUS_COUNT] = {{false}};
    Alloc1D<cstring, STATS_ALUS>                       stats_alus;
    Alloc1D<cstring, METER_ALUS>                       meter_alus;

    struct mem_info {
        int logical_tables = 0;
        int match_tables = 0;
        int match_bus_min = 0;
        int atcam_tables = 0;
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
        int stateful_tables = 0;
        int stateful_RAMs = 0;
        int selector_tables = 0;
        int selector_RAMs = 0;
        int no_match_tables = 0;
        int independent_gw_tables = 0;
        int idletime_RAMs = 0;

        void clear() {
            memset(this, 0, sizeof(mem_info));
        }

        int total_RAMs() const {
            return match_RAMs + action_RAMs + stats_RAMs + meter_RAMs + selector_RAMs + tind_RAMs;
        }

        int left_side_RAMs() const { return tind_RAMs; }
        int right_side_RAMs() const { return meter_RAMs + stats_RAMs + selector_RAMs
                                             + stateful_RAMs; }
        int non_SRAM_RAMs() const { return left_side_RAMs() + right_side_RAMs() + action_RAMs; }
        int columns(int RAMs) const { return (RAMs + SRAM_COLUMNS - 1) / SRAM_COLUMNS; }
        bool constraint_check() const;
    };

    friend class SetupAttachedTables;

 public:
    /* Memories::Use tracks memory use of a single table */
    struct Use {
        enum type_t { EXACT, ATCAM, TERNARY, GATEWAY, TIND, IDLETIME, COUNTER, METER, SELECTOR,
                      STATEFUL, ACTIONDATA } type;
        bool is_twoport() const { return type == COUNTER || type == METER || type == SELECTOR
                                         || type == STATEFUL; }
        /* FIXME -- when tracking EXACT table memuse, do we need to track which way
         * each memory is allocated to?  For now, we do not. */
        struct Row {
            int         row, bus, word, alloc;
            safe_vector<int> col, mapcol, vpn;
            Row() : row(-1), bus(-1), word(-1), alloc(-1) {}
            explicit Row(int r, int b = -1, int w = -1, int a = -1)
                : row(r), bus(b), word(w), alloc(a) {}
            void dbprint(std::ostream &out) const {
                out << "Row " << row << " with bus " << bus;
            }
        };
        struct Way {
            int size;
            unsigned select_mask;
            safe_vector<std::pair<int, int>> rams;
            explicit Way(int s, unsigned sm) : size(s), select_mask(sm) {}
        };
        struct Gateway {
            uint64_t payload_value = 0ULL;
            int      payload_row = -1;
            int      payload_bus = -1;
            int      unit = -1;
            type_t bus_type;
            void clear() {
                payload_value = 0ULL;
                payload_row = -1;
                payload_bus = -1;
                unit = -1;
            }
        };

        safe_vector<Row>                         row;
        safe_vector<Row>                         color_mapram;
        safe_vector<std::pair<int, int>>         home_row;
        safe_vector<Way>                         ways;
        Gateway                                  gateway;

        /** This is a map of AttachedMemory UniqueIds that are shared with other tables, i.e.
         *  Action Profiles.  The AttachedMemory though shared, is only allocated on one table
         *  The key is the id of the table underneath the current table, and the value is the
         *  id of where the allocation of that table is.
         *
         *  In the assembly, the name from associated with the value will point to the correct
         *  assembly allocated name.
         *
         *  The map will only be valid under the associated match portion, i.e the EXACT/TERNARY
         *  portion of the key
         */
        std::map<UniqueId, UniqueId>             unattached_tables;
        safe_vector<UniqueId>                    dleft_learn;
        safe_vector<UniqueId>                    dleft_match;

        void clear_allocation() {
            row.clear();
            color_mapram.clear();
            home_row.clear();
            gateway.clear();
        }

        void clear() {
            clear_allocation();
            unattached_tables.clear();
            dleft_learn.clear();
            dleft_match.clear();
        }

        // depth in memory units + mask to use for memory selection per way
        void visit(Memories &mem, std::function<void(cstring &)>) const;
    };

 private:
    struct table_alloc {
        const IR::MAU::Table *table;
        const IXBar::Use *match_ixbar;
        const TableFormat::Use *table_format;
        std::map<UniqueId, Memories::Use>* memuse;
        const LayoutOption *layout_option;
        int provided_entries;
        int calculated_entries;
        int attached_gw_bytes = 0;
        int stage_table = -1;
        // Linked gw/match table that uses the same result bus
        table_alloc *table_link = nullptr;
        explicit table_alloc(const IR::MAU::Table *t, const IXBar::Use *mi,
                             const TableFormat::Use *tf,
                             std::map<UniqueId, Memories::Use> *mu,
                             const LayoutOption *lo, const int e, const int st)
                : table(t), match_ixbar(mi), table_format(tf), memuse(mu),
                  layout_option(lo), provided_entries(e),
                  calculated_entries(0), attached_gw_bytes(0), stage_table(st),
                  table_link(nullptr) {}
        void link_table(table_alloc *ta) {table_link = ta;}

        UniqueId build_unique_id(const IR::MAU::AttachedMemory *at = nullptr,
             bool is_gw = false, int logical_table = -1,
             UniqueAttachedId::pre_placed_type_t ppt = UniqueAttachedId::NO_PP) const;
    };
    friend std::ostream & operator<<(std::ostream &out, const Memories::table_alloc &ta);

    /** Information on a particular table that is to be allocated in the RAM array */
    struct SRAM_group {
        table_alloc *ta;  // Link to the table alloc to be generated
        int depth = 0;    // Individual number of RAMs required for a group
        int width = 0;    // How wide an individual group is, only needed for exact match
        int placed = 0;   // How many have been allocated so far
        int number = 0;   // Used to keep track of wide action tables and way numbers in exact match
        int hash_group = -1;  // Which hash group the exact match way is using
        int logical_table = -1;  // For ATCAM tables, which logical table this partition is based
        int vpn_increment = 1;
        int vpn_offset = 0;
        bool direct = false;  // Whether the attached table is directly or indirectly addressed
        const IR::MAU::AttachedMemory *attached = nullptr;
        UniqueAttachedId::pre_placed_type_t ppt = UniqueAttachedId::NO_PP;
        int recent_home_row = -1;  // For swbox users, most recent row to oflow to
        enum type_t { EXACT, ACTION, STATS, METER, REGISTER, SELECTOR, TIND, IDLETIME, ATCAM,
                      GROUP_TYPES } type;

        // Color Mapram Requirements, necessary for METER groups
        struct color_mapram_group {
            int needed = 0;
            int placed = 0;
            bool all_placed() const {
                BUG_CHECK(placed <= needed, "Placed more RAMs than actually needed");
                return needed == placed;
            }
            int left_to_place() const {
                BUG_CHECK(placed <= needed, "Placed more RAMs than actually needed");
                return needed - placed;
            }
        };


        // Linkage between selectors and the corresponding action table in order to prevent
        // a collision on the selector overflow
        struct selector_info {
            SRAM_group *sel_group = nullptr;
            ordered_set<SRAM_group *> action_groups;
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
        bool requires_ab = false;  // LPF and WRED meters require synth and action bus

        SRAM_group(table_alloc *t, int d, int w, int n, type_t ty)
            : ta(t), depth(d), width(w), number(n), type(ty) {}
        SRAM_group(table_alloc *t, int d, int n, type_t ty)
            : ta(t), depth(d), number(n), type(ty) {}
        SRAM_group(table_alloc *t, int d, int w, int n, int h, type_t ty)
            : ta(t), depth(d), width(w), number(n), hash_group(h), type(ty) {}
        void dbprint(std::ostream &out) const;
        search_bus_info build_search_bus(int width_sect) {
            return search_bus_info(ta->table->name, width_sect, hash_group, logical_table);
        }

        int left_to_place() const {
            BUG_CHECK(placed <= depth, "Placed more than needed");
            return depth - placed;
        }
        bool all_placed() const {
            BUG_CHECK(placed <= depth, "Placed more than needed");
            return (depth == placed);
        }
        bool any_placed() { return (placed != 0); }
        bool needs_ab() { return requires_ab && !all_placed(); }
        bool is_synth_type() { return type == STATS || type == METER || type == REGISTER
                                      || type == SELECTOR; }
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
        // cstring get_name() const;
        UniqueId build_unique_id() const;
        bool same_wide_action(const SRAM_group &a);
        int calculate_next_vpn() const {
            return placed * vpn_increment + vpn_offset;
        }
    };

    struct match_selection {
        safe_vector<int> rows;
        safe_vector<int> cols;
        std::map<int, int> widths;
        std::map<int, int> buses;
        unsigned column_mask = 0;
    };
    /** Information about particular use on a row during allocate_all_swbox_users */
    struct swbox_fill {
        SRAM_group *group = nullptr;
        unsigned mask = 0;
        unsigned mapram_mask = 0;
        operator bool() const { return group != nullptr; }
        swbox_fill() {}
        void clear() { group = nullptr; mask = 0; mapram_mask = 0; }
        void clear_masks() {mask = 0; mapram_mask = 0; }
        void dbprint(std::ostream &out) const {
            out << *group << " RAM mask: 0x" << hex(mask) << " map RAM mask: 0x"
                << hex(mapram_mask);
        }
    };

    // Used for array indices in allocate_all_action
    enum RAM_side_t { LEFT = 0, RIGHT, RAM_SIDES };
    enum switchbox_t { ACTION = 0, SYNTH, OFLOW, SWBOX_TYPES };

    safe_vector<table_alloc *>       tables;
    safe_vector<table_alloc *>       exact_tables;
    safe_vector<SRAM_group *>        exact_match_ways;
    safe_vector<table_alloc *>       atcam_tables;
    safe_vector<SRAM_group *>        atcam_partitions;
    safe_vector<table_alloc *>       ternary_tables;
    safe_vector<table_alloc *>       tind_tables;
    safe_vector<SRAM_group *>        tind_groups;
    safe_vector<table_alloc *>       action_tables;
    safe_vector<table_alloc *>       indirect_action_tables;
    safe_vector<table_alloc *>       selector_tables;
    safe_vector<table_alloc *>       stats_tables;
    safe_vector<table_alloc *>       meter_tables;
    safe_vector<table_alloc *>       stateful_tables;
    ordered_set<SRAM_group *>        action_bus_users;
    ordered_set<SRAM_group *>        synth_bus_users;
    ordered_set<SRAM_group *>        must_be_placed_in_half;
    safe_vector<table_alloc *>       gw_tables;
    safe_vector<table_alloc *>       no_match_hit_tables;
    safe_vector<table_alloc *>       no_match_miss_tables;
    safe_vector<table_alloc *>       payload_gws;
    safe_vector<table_alloc *>       normal_gws;
    safe_vector<table_alloc *>       no_match_gws;
    safe_vector<table_alloc *>       idletime_tables;
    safe_vector<SRAM_group *>        idletime_groups;

    int allocation_count = 0;

    ordered_map<const IR::MAU::AttachedMemory *, table_alloc *> shared_attached;

    unsigned side_mask(RAM_side_t side);
    unsigned partition_mask(RAM_side_t side);
    int mems_needed(int entries, int depth, int per_mem_row, bool is_twoport);
    void clear_table_vectors();
    void clear_uses();
    void clear_allocation();
    void set_logical_memuse_type(table_alloc *ta, Use::type_t type);
    bool analyze_tables(mem_info &mi);
    void calculate_column_balance(const mem_info &mi, unsigned &row, bool &column_balance_init);
    bool single_allocation_balance(mem_info &mi, unsigned row);
    bool cut_from_left_side(const mem_info &mi, int left_given_columns, int right_given_columns);
    bool allocate_all_atcam(mem_info &mi);
    bool allocate_all_exact(unsigned column_mask);
    safe_vector<int> way_size_calculator(int ways, int RAMs_needed);
    safe_vector<std::pair<int, int>> available_SRAMs_per_row(unsigned mask, SRAM_group *group,
                                                             int width_sect);
    safe_vector<int> available_match_SRAMs_per_row(unsigned selected_columns_mask,
        unsigned total_mask, std::set<int> selected_rows, SRAM_group *group, int width_sect);
    void break_exact_tables_into_ways();
    bool search_bus_available(int search_row, search_bus_info &sbi);
    int select_search_bus(SRAM_group *group, int width_sect, int row);
    bool find_best_row_and_fill_out(unsigned column_mask);
    bool fill_out_row(SRAM_group *placed_way, int row, unsigned column_mask);
    SRAM_group *find_best_candidate(SRAM_group *placed_way, int row, int &loc);
    void compress_ways(bool atcam);
    void compress_row(Use &alloc);

    void break_atcams_into_partitions();
    bool determine_match_rows_and_cols(SRAM_group *group, int row, unsigned column_mask,
        match_selection &match_select, bool atcam);
    void fill_out_match_alloc(SRAM_group *group, match_selection &match_select, bool atcam);
    bool find_best_partition_for_atcam(unsigned column_mask);
    bool fill_out_partition(int row, unsigned partition_mask);
    unsigned best_partition_side(mem_info &mi);
    SRAM_group *best_partition_candidate(int row, unsigned column_mask, int &loc);

    bool allocate_all_ternary();
    int ternary_TCAMs_necessary(table_alloc *ta, int &midbyte);
    bool find_ternary_stretch(int TCAMs_necessary, int &row, int &col, int midbyte,
        bool &split_midbyte);

    bool allocate_all_tind();
    void find_tind_groups();
    int find_best_tind_row(SRAM_group *tg, int &bus);
    void compress_tind_groups();

    bool allocate_all_swbox_users();
    void find_swbox_bus_users();
    void swbox_bus_selectors_indirects();
    void swbox_bus_meters_counters();
    void swbox_bus_stateful_alus();
    void swbox_logical_row(int row, RAM_side_t side, swbox_fill candidates[SWBOX_TYPES],
                           swbox_fill &curr_oflow, swbox_fill &sel_oflow);
    void find_swbox_candidates(int row, RAM_side_t side, swbox_fill candidates[SWBOX_TYPES],
                                bool stats_available, bool meter_available,
                                swbox_fill &curr_oflow, swbox_fill &sel_oflow);
    void adjust_RAMs_available(swbox_fill &curr_oflow, int RAMs_avail[OFLOW], int row,
                               RAM_side_t side);

    int half_RAMs_available(int row, bool right_only);
    int half_map_RAMs_available(int row);
    int synth_half_RAMs_to_place();
    int synth_half_map_RAMs_to_place();
    int action_half_RAMs_to_place();
    bool action_table_best_candidate(SRAM_group *next_synth, swbox_fill &sel_oflow);
    bool action_table_in_half(SRAM_group *action_table, SRAM_group *next_synth,
                              swbox_fill &sel_oflow);
    bool synth_in_half(SRAM_group *synth_table, int row);

    void best_candidates(swbox_fill best_fits[OFLOW], swbox_fill nexts[OFLOW],
                         swbox_fill &curr_oflow, swbox_fill &sel_oflow,
                         bool stats_available, bool meter_available, RAM_side_t side, int row,
                         int RAMs_avail[OFLOW]);
    void fill_out_masks(swbox_fill candidates[SWBOX_TYPES], switchbox_t order[SWBOX_TYPES],
                        int RAMs[SWBOX_TYPES], int row, RAM_side_t side);
    void init_candidate(swbox_fill candidates[SWBOX_TYPES], switchbox_t order[SWBOX_TYPES],
                        bool bus_used[SWBOX_TYPES], switchbox_t type, int &order_index,
                        swbox_fill choice, bool test_action_bus);
    void determine_candidates_order(swbox_fill candidates[SWBOX_TYPES], swbox_fill best_fits[OFLOW],
                              swbox_fill &curr_oflow, swbox_fill nexts[OFLOW],
                              int RAMs_avail[OFLOW], RAM_side_t side,
                              switchbox_t order[SWBOX_TYPES]);
    void set_up_RAM_counts(swbox_fill candidates[SWBOX_TYPES], switchbox_t order[SWBOX_TYPES],
                           int RAMs_avail[OFLOW], int RAMs[SWBOX_TYPES]);
    void color_mapram_candidates(swbox_fill candidates[SWBOX_TYPES], RAM_side_t side);
    void set_color_maprams(swbox_fill &candidate, unsigned &avail_maprams);
    void fill_color_mapram_use(swbox_fill &candidate, int row, RAM_side_t side);
    void fill_RAM_use(swbox_fill &candidate, int row, RAM_side_t side, switchbox_t type);
    void remove_placed_group(swbox_fill &candidate, RAM_side_t side);
    void fill_swbox_side(swbox_fill candidates[SWBOX_TYPES], int row, RAM_side_t side);
    void calculate_curr_oflow(swbox_fill candidates[SWBOX_TYPES], swbox_fill &curr_oflow,
                              swbox_fill &synth_oflow, RAM_side_t side);
    void calculate_sel_oflow(swbox_fill candidates[SWBOX_TYPES], swbox_fill &sel_oflow);
    /**
    bool can_place_selector(action_fill &curr_oflow, SRAM_group *curr_check,
                            int suppl_RAMs_available, int action_RAMs_available,
                            action_fill &sel_unplaced);
    void selector_candidate_setup(action_fill candidates[SWBOX_TYPES], action_fill &curr_oflow,
                                  action_fill &sel_unplaced, action_fill nexts[OFLOW],
                                  int order[SWBOX_TYPES], int RAMs_avail[OFLOW]);
    */
    void action_bus_users_log();
    bool find_unit_gw(Memories::Use &alloc, cstring name, bool requires_search_bus);
    bool find_search_bus_gw(table_alloc *ta, Memories::Use &alloc, cstring name);
    bool find_match_bus_gw(Memories::Use &alloc, uint64_t payload, cstring name,
                           table_alloc *ta_no_match, int logical_table = -1);
    uint64_t determine_payload(table_alloc *ta);
    bool allocate_all_gw();
    bool allocate_all_payload_gw();
    bool allocate_all_normal_gw();
    bool allocate_all_no_match_gw();
    table_alloc *find_corresponding_exact_match(cstring name);
    bool gw_search_bus_fit(table_alloc *ta, table_alloc *exact_ta, int row, int col);
    bool allocate_all_no_match_miss();

    bool find_mem_and_bus_for_idletime(std::vector<std::pair<int, std::vector<int>>>& mem_locs,
                                    int& bus, int total_mem_required, bool top_half);
    bool allocate_idletime_in_top_or_bottom_half(SRAM_group* idletime_group,
                                                 bool top_or_bottom);
    bool allocate_idletime(SRAM_group* idletime_group);
    bool allocate_all_idletime();

 public:
    bool allocate_all();
    void update(cstring table_name, const Use &alloc);
    void update(const std::map<UniqueId, Use> &alloc);
    void remove(cstring table_name, const Use &alloc);
    void remove(const std::map<UniqueId, Use> &alloc);
    void clear();
    void add_table(const IR::MAU::Table *t, const IR::MAU::Table *gw,
                   TableResourceAlloc *resources, const LayoutOption *lo, int entries,
                   int stage_table);
    friend std::ostream &operator<<(std::ostream &, const Memories &);
};

template<int R, int C>
std::ostream &operator<<(std::ostream&, const Alloc2D<cstring, R, C>& alloc2d);

#endif /* BF_P4C_MAU_MEMORIES_H_ */
