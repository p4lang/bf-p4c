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
    static constexpr int STASH_UNITS = 2;
    static constexpr int LOGICAL_TABLES = 16;
    static constexpr int LEFT_SIDE_COLUMNS = 4;
    static constexpr int RIGHT_SIDE_COLUMNS = SRAM_COLUMNS - LEFT_SIDE_COLUMNS;
    static constexpr int LEFT_SIDE_RAMS = LEFT_SIDE_COLUMNS * SRAM_ROWS;
    static constexpr int RIGHT_SIDE_RAMS = RIGHT_SIDE_COLUMNS * SRAM_ROWS;
    static constexpr int MAPRAM_COLUMNS = 6;
    static constexpr int MAPRAM_MASK = (1U << MAPRAM_COLUMNS) - 1;
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
    static constexpr int MATCH_CENTRAL_ROW = 4;

    static constexpr int LOGICAL_ROW_MISSING_OFLOW = 8;

    /**
     * For an SRAM based tables, specifically there are 3 buses, and a 4th output potentially
    *  in use:
     *     1. A search bus for data from the input xbar to be directly compared with a RAM line
     *     2. An address bus to find the associated RAM line/RAM to perform the comparison on
     *     3. A result bus for capturing any overhead and address location of the entry that
     *        matches.
     *     4. A signal to capture the hit signals of all possible entries within the RAM, in
     *        order to capture which VPN is put onto the result bus
     *
     * In the current setup, the search_bus_info captures both the search bus and address bus.
     * The search data bus is captured in section 6.2.3 Exact Match Row Vertical/Horizontal
     * (VH) XBars, and the address bus is discussed in section 6.2.8.4.1 Exact Match RAM
     * Addressing.  Essentially these are locked together because generally a table that has
     * a particular search data also requires a hash address, and these must be the same.
     *
     * The result bus unfortunately isn't really a single section, but is the input to match
     * merge.  The hit signal is captured in section 6.4.3.1 Exact Match Physical Row Result
     * Generation.
     *
     * Previously the allocation for SRAM based tables would lock up both the search portion
     * and the result portion for an individual table.  However, this led to some cases that
     * could be handled significantly better.  Say for instance, an ATCAM table is split into
     * two logical tables on the same row.  While each logical table would require a
     * separate result bus, the logical tables could split their search data/address data, as
     * they have the same input xbar inputs.  Search buses/Address buses are also used by
     * gateways at a later point, and thus by saving search buses, more gateways can be
     * allocated in the same stage.
     */
    struct search_bus_info {
        cstring name;
        int width_section = 0;   // Each search bus for a table has a particular width
        int hash_group = 0;   // Each hash function requires a different hash function
        bool init = false;

        search_bus_info() {}
        search_bus_info(cstring n, int ws, int hg)
            : name(n), width_section(ws), hash_group(hg), init(true) {}

        bool operator==(const search_bus_info &sbi) {
            return name == sbi.name && width_section == sbi.width_section
                   && hash_group == sbi.hash_group;
        }

        bool operator!=(const search_bus_info &sbi) {
            return !operator==(sbi);
        }

        bool free() { return !init; }
        friend std::ostream &operator<<(std::ostream &, const search_bus_info &);
    };

    struct result_bus_info {
        cstring name;
        int width_section = 0;  // Each width section may require a different width section
        int logical_table = 0;  // For ATCAM tables, each logical table requires a separate
                                // result bus
        bool init = false;

        result_bus_info() {}
        result_bus_info(cstring n, int ws, int lt)
            : name(n), width_section(ws), logical_table(lt), init(true) {}

        bool operator==(const result_bus_info &mbi) {
            return name == mbi.name && width_section == mbi.width_section
                   && logical_table == mbi.logical_table;
        }

        bool operator!=(const result_bus_info &mbi) {
            return !operator==(mbi);
        }
        bool free() { return !init; }
        friend std::ostream &operator<<(std::ostream &, const result_bus_info &);
    };

 private:
    Alloc2D<cstring, SRAM_ROWS, SRAM_COLUMNS>          sram_use;
    unsigned                                           sram_inuse[SRAM_ROWS] = { 0 };
    Alloc2D<cstring, SRAM_ROWS, STASH_UNITS>           stash_use;
    Alloc2D<cstring, TCAM_ROWS, TCAM_COLUMNS>          tcam_use;
    Alloc2D<cstring, SRAM_ROWS, 2>                     gateway_use;
    Alloc2D<search_bus_info, SRAM_ROWS, 2>             sram_search_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                     sram_print_search_bus;
    Alloc2D<result_bus_info, SRAM_ROWS, 2>             sram_result_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                     sram_print_result_bus;
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
        int result_bus_min = 0;
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
        bool constraint_check(int lt_allowed) const;
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
            int              row, bus, result_bus, word, alloc;
            int              stash_unit, stash_col;
            safe_vector<int> col, mapcol, vpn;
            Row() : row(-1), bus(-1), result_bus(-1), word(-1), alloc(-1),
                    stash_unit(-1), stash_col(-1) {}
            explicit Row(int r, int b = -1, int w = -1, int a = -1)
                : row(r), bus(b), result_bus(-1), word(w), alloc(a),
                  stash_unit(-1), stash_col(-1) {}
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
        IR::MAU::ColorMapramAddress cma = IR::MAU::ColorMapramAddress::NOT_SET;

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
            cma = IR::MAU::ColorMapramAddress::NOT_SET;
        }

        void clear() {
            clear_allocation();
            unattached_tables.clear();
            dleft_learn.clear();
            dleft_match.clear();
        }

        bool separate_search_and_result_bus() const;
        // depth in memory units + mask to use for memory selection per way
        enum update_type_t { UPDATE_RAM, UPDATE_MAPRAM, UPDATE_GATEWAY, UPDATE_RESULT_BUS };
        void visit(Memories &mem, std::function<void(cstring &, update_type_t)>) const;
    };

 private:
    // The resource information required for an individual IR::MAU::Table object in a single
    // stage.  Could coordinate to multiple logical tables, (i.e. dleft or atcam tables)
    struct table_alloc {
        const IR::MAU::Table *table;
        const IXBar::Use *match_ixbar;
        const TableFormat::Use *table_format;
        std::map<UniqueId, Memories::Use>* memuse;
        const LayoutOption *layout_option;
        int provided_entries;
        // Entries per match table allocation_unit (logical table) of the table.  This is
        // used to determine the attached table requirements if direct
        safe_vector<int> calc_entries_per_uid;
        int total_entries() const {
            return std::accumulate(calc_entries_per_uid.begin(), calc_entries_per_uid.end(), 0);
        }
        int attached_gw_bytes = 0;
        int stage_table = -1;
        // Linked gw/match table that uses the same result bus
        table_alloc *table_link = nullptr;
        explicit table_alloc(const IR::MAU::Table *t, const IXBar::Use *mi,
                             const TableFormat::Use *tf,
                             std::map<UniqueId, Memories::Use> *mu,
                             const LayoutOption *lo, const int e, const int st)
                : table(t), match_ixbar(mi), table_format(tf), memuse(mu),
                  layout_option(lo), provided_entries(e), attached_gw_bytes(0), stage_table(st),
                  table_link(nullptr) {}
        void link_table(table_alloc *ta) {table_link = ta;}

        UniqueId build_unique_id(const IR::MAU::AttachedMemory *at = nullptr,
            bool is_gw = false, int logical_table = -1,
            UniqueAttachedId::pre_placed_type_t ppt = UniqueAttachedId::NO_PP) const;

        safe_vector<UniqueId> allocation_units(const IR::MAU::AttachedMemory *at = nullptr,
            bool is_gw = false,
            UniqueAttachedId::pre_placed_type_t ppt = UniqueAttachedId::NO_PP) const;


        safe_vector<UniqueId> unattached_units(const IR::MAU::AttachedMemory *at = nullptr,
            UniqueAttachedId::pre_placed_type_t ppt = UniqueAttachedId::NO_PP) const;

        safe_vector<UniqueId> accounted_units(const IR::MAU::AttachedMemory *at = nullptr,
            UniqueAttachedId::pre_placed_type_t ppt = UniqueAttachedId::NO_PP) const;
    };
    int logical_tables_allowed = LOGICAL_TABLES;

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
            // Necessary for stats addressed color maprams
            int home_row = -1;
            IR::MAU::ColorMapramAddress cma = IR::MAU::ColorMapramAddress::NOT_SET;
            bool all_placed() const {
                BUG_CHECK(placed <= needed, "Placed more color map RAMs than actually needed");
                return needed == placed;
            }
            int left_to_place() const {
                BUG_CHECK(placed <= needed, "Placed more color map RAMs than actually needed");
                return needed - placed;
            }

            bool require_stats() const { return cma == IR::MAU::ColorMapramAddress::STATS; }
        };


        // Linkage between selectors and the corresponding action table in order to prevent
        // a collision on the selector overflow
        struct selector_info {
            SRAM_group *sel_group = nullptr;
            ordered_set<SRAM_group *> action_groups;
            bool sel_linked() { return sel_group != nullptr; }
            bool act_linked() { return !action_groups.empty(); }
            bool sel_all_placed() const { return sel_group->all_placed(); }
            bool action_all_placed() const {
                if (action_groups.empty())
                    BUG("No action corresponding with this selector");
                for (auto *action_group : action_groups) {
                    if (!action_group->all_placed())
                        return false;
                }
                return true;
            }
            bool sel_any_placed() const {
                return sel_group->any_placed();
            }
            bool action_any_placed() const {
                if (action_groups.empty())
                    BUG("No action corresponding with this selector");
                for (auto *action_group : action_groups) {
                    if (action_group->any_placed())
                        return true;
                }
                return false;
            }

            bool all_placed() const { return sel_all_placed() && action_all_placed(); }

            bool is_act_corr_group(SRAM_group *corr) {
                return action_groups.find(corr) != action_groups.end();
            }
            bool is_sel_corr_group(SRAM_group *corr) {
                return corr == sel_group;
            }
            bool one_action_left() const {
                int total_unplaced_groups = 0;
                for (auto *action_group : action_groups)
                    if (action_group->left_to_place() > 0)
                        total_unplaced_groups++;
                return total_unplaced_groups == 1;
            }
            int action_left_to_place() const {
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
        search_bus_info build_search_bus(int width_sect) const {
            return search_bus_info(ta->table->name, width_sect, hash_group);
        }

        result_bus_info build_result_bus(int width_sect) const;

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
        bool is_synth_type() const { return type == STATS || type == METER || type == REGISTER
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
        int total_left_to_place() const {
            if (type == SELECTOR) {
                int action_depth = 0;
                for (auto *action_group : sel.action_groups)
                    action_depth += action_group->left_to_place();
                return left_to_place() + action_depth;
            } else {
                return left_to_place();
            }
        }

        int maprams_left_to_place() const {
            if (is_synth_type())
                return left_to_place() + cm.left_to_place();
            return 0;
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
        std::map<int, int> search_buses;
        std::map<int, int> result_buses;
        unsigned column_mask = 0;
    };

    enum switchbox_t { ACTION = 0, SYNTH, OFLOW, SWBOX_TYPES };

    struct LogicalRowUser {
        SRAM_group *group = nullptr;
        switchbox_t bus = SWBOX_TYPES;
        bitvec RAM_mask;
        bitvec map_RAM_mask;

        operator bool() const { return group != nullptr; }
        void clear_masks() { RAM_mask.clear(); map_RAM_mask.clear(); }
        void clear() { group = nullptr; bus = SWBOX_TYPES; clear_masks(); }
        bool set() const { return !(RAM_mask.empty() && map_RAM_mask.empty()); }

        bitvec color_map_RAM_mask() const {
            BUG_CHECK(group->type == SRAM_group::METER, "Cannot get color map RAMs of "
                      " a non-METER");
            return map_RAM_mask - (RAM_mask >> LEFT_SIDE_COLUMNS);
        }

        void dbprint(std::ostream &out) const {
            out << *group << " bus " << bus << " RAM mask: 0x" << RAM_mask
                << " map RAM mask: 0x" << map_RAM_mask;
        }
        LogicalRowUser(SRAM_group *g, switchbox_t b) : group(g), bus(b) {}
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
    ordered_set<const SRAM_group *>  must_place_in_half;
    safe_vector<table_alloc *>       gw_tables;
    safe_vector<table_alloc *>       no_match_hit_tables;
    safe_vector<table_alloc *>       no_match_miss_tables;
    safe_vector<table_alloc *>       payload_gws;
    safe_vector<table_alloc *>       normal_gws;
    safe_vector<table_alloc *>       no_match_gws;
    safe_vector<table_alloc *>       idletime_tables;
    safe_vector<SRAM_group *>        idletime_groups;


    // Switchbox Related Helper functions
    int phys_to_log_row(int physical_row, RAM_side_t side) const;
    int log_to_phys_row(int logical_row, RAM_side_t *side = nullptr) const;
    void determine_synth_RAMs(int &RAMs_available, int row, const SRAM_group *curr_oflow) const;
    void determine_action_RAMs(int &RAMs_available, int row, RAM_side_t side,
        const safe_vector<LogicalRowUser> &lrus) const;
    bool alu_pathway_available(SRAM_group *synth_table, int row,
        const SRAM_group *curr_oflow) const;
    int lowest_row_to_overflow(const SRAM_group *candidate, int row) const;
    int open_rams_between_rows(int highest_logical_row, int lowest_logical_row, bitvec sides) const;
    int open_maprams_between_rows(int highest_phys_row, int lowest_phys_row) const;
    bool overflow_possible(const SRAM_group *candidate, int row, RAM_side_t side) const;
    bool can_be_placed_in_half(const SRAM_group *candidate, int row, RAM_side_t side,
        const SRAM_group *synth, int RAMs_avail_on_row) const;
    bool break_other_overflow(const SRAM_group *candidate, const SRAM_group *curr_oflow, int row,
        RAM_side_t side) const;
    bool satisfy_sel_swbox_constraints(const SRAM_group *candidate,
        const SRAM_group *sel_oflow, SRAM_group *synth) const;
    void determine_fit_on_logical_row(SRAM_group **fit_on_logical_row, SRAM_group *candidate,
        int RAMs_avail) const;
    void determine_max_req(SRAM_group **max_req, SRAM_group *candidate) const;
    void candidates_for_synth_row(SRAM_group **fit_on_logical_row, SRAM_group **largest_req,
        int row, const SRAM_group *curr_oflow, const SRAM_group *sel_oflow, int RAMs_avail) const;
    void candidates_for_action_row(SRAM_group **fit_on_logical_row, SRAM_group **largest_req,
        int row, RAM_side_t side, const SRAM_group *curr_oflow, const SRAM_group *sel_oflow,
        int RAMs_avail, SRAM_group *synth) const;
    void determine_synth_logical_row_users(SRAM_group *fit_on_logical_row,
        SRAM_group *max_req, SRAM_group *curr_oflow, safe_vector<LogicalRowUser> &lrus,
        int RAMs_avail) const;
    void determine_action_logical_row_users(SRAM_group *fit_on_logical_row,
        SRAM_group *max_req, SRAM_group *curr_oflow, safe_vector<LogicalRowUser> &lrus,
        int RAMs_avail) const;
    void determine_RAM_masks(safe_vector<LogicalRowUser> &lrus, int row, RAM_side_t side,
        int RAMs_available, bool is_synth_type) const;
    void one_color_map_RAM_mask(LogicalRowUser &lru, bitvec &map_RAM_in_use,
        bool &stats_bus_used, int row) const;
    void determine_color_map_RAM_masks(safe_vector<LogicalRowUser> &lrus, int row) const;
    void determine_logical_row_masks(safe_vector<LogicalRowUser> &lrus, int row,
         RAM_side_t side, int RAMs_avaialble, bool is_synth_type) const;
    void find_swbox_candidates(safe_vector<LogicalRowUser> &lrus, int row, RAM_side_t side,
        SRAM_group *curr_oflow, SRAM_group *sel_oflow);
    void fill_RAM_use(LogicalRowUser &lru, int row, RAM_side_t side);
    void fill_color_map_RAM_use(LogicalRowUser &lru, int row);
    void remove_placed_group(SRAM_group *candidate, RAM_side_t side);
    void update_must_place_in_half(const SRAM_group *candidate, switchbox_t bus);
    void fill_swbox_side(safe_vector<LogicalRowUser> &lrus, int row, RAM_side_t side);
    void swbox_logical_row(safe_vector<LogicalRowUser> &lrus, int row, RAM_side_t side,
        SRAM_group *curr_oflow, SRAM_group *sel_oflow);
    void calculate_curr_oflow(safe_vector<LogicalRowUser> &lrus, SRAM_group **curr_oflow,
        SRAM_group **synth_oflow, RAM_side_t side) const;
    void calculate_sel_oflow(safe_vector<LogicalRowUser> &lrus, SRAM_group **sel_oflow) const;
    // Switchbox related helper functions end

    int allocation_count = 0;
    ordered_map<const IR::MAU::AttachedMemory *, table_alloc *> shared_attached;
    unsigned side_mask(RAM_side_t side) const;
    unsigned partition_mask(RAM_side_t side);
    int mems_needed(int entries, int depth, int per_mem_row, bool is_twoport);
    void clear_table_vectors();
    void clear_uses();
    void clear_allocation();
    void set_logical_memuse_type(table_alloc *ta, Use::type_t type);
    bool analyze_tables(mem_info &mi);
    void calculate_entries();
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
    bool result_bus_available(int match_row, result_bus_info &mbi);
    int select_search_bus(SRAM_group *group, int width_sect, int row);
    int select_result_bus(SRAM_group *group, int width_sect, int row);
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

    void log_allocation(safe_vector<table_alloc *> *tas, UniqueAttachedId::type_t type);
    void log_allocation(safe_vector<table_alloc *> *tas, UniqueAttachedId::pre_placed_type_t ppt);
    void action_bus_users_log();
    bool find_unit_gw(Memories::Use &alloc, cstring name, bool requires_search_bus);
    bool find_search_bus_gw(table_alloc *ta, Memories::Use &alloc, cstring name);
    bool find_result_bus_gw(Memories::Use &alloc, uint64_t payload, cstring name,
                            table_alloc *ta_no_match, int logical_table = -1);
    uint64_t determine_payload(table_alloc *ta);
    bool allocate_all_gw();
    bool allocate_all_payload_gw(bool alloc_search_bus);
    bool allocate_all_normal_gw(bool alloc_search_bus);
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
    void shrink_allowed_lts() { logical_tables_allowed--; }
    friend std::ostream &operator<<(std::ostream &, const Memories &);
};

template<int R, int C>
std::ostream &operator<<(std::ostream&, const Alloc2D<cstring, R, C>& alloc2d);

#endif /* BF_P4C_MAU_MEMORIES_H_ */
