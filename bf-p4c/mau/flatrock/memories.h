#ifndef BF_P4C_MAU_FLATROCK_MEMORIES_H_
#define BF_P4C_MAU_FLATROCK_MEMORIES_H_

#include <algorithm>
#include "bf-p4c/mau/attached_entries.h"
#include "bf-p4c/mau/flatrock/input_xbar.h"
#include "bf-p4c/mau/flatrock/table_format.h"
#include "bf-p4c/mau/instruction_memory.h"
#include "bf-p4c/mau/action_format.h"
#include "bf-p4c/mau/memories.h"
#include "ir/ir.h"
#include "lib/safe_vector.h"

namespace Flatrock {

/*
 * -------------------------
 * STM (Shared Table Memory)
 * -------------------------
 * An array of RAM used by PPU stages to store stateless and stateful tables.
 * The STM is used for most SRAM-based table data that directly scales with the number of table
 * entries. This includes hashtable entries, BPH descriptors, sparse trie bucket descriptors and
 * buckets, action entries, stateful entries, etc.
 *
 * FPP = 1 iSTM (Ingress) + 1 eSTM (Egress)
 *
 * N_ISTM_ROWS
 * N_ESTM_ROWS
 * N_IPPU_STAGES
 * N_EPPU_STAGES
 * N_ISTM_ROWS / N_ESTM_ROWS != N_IPPU_STAGES / N_EPPU_STAGES
 *
 * 1 STM stage per PPU stage
 * Each STM connected to previous and next STM stage
 * Pipleline flops added between groups
 *
 * 2 STM Stages in a STM group
 * All RAMs in a group are in the same pipeline stage
 * STM_STAGES_PER_GROUP = 2
 *
 * STM_COLS_PER_STAGE
 * Each column contains 1 RAM pair (STM UNIT) per row
 * RAM = 1024 entries x 137 bit (128 + 9 ECC)
 * 1 port for r/w
 * ECC handled by users of RAM
 *
 * Interfaces
 * 6 x Read requests      : 1 bit valid, 20 bit address
 * 6 x Read response      : 1 bit valid,                 137 bit data
 * 1 x Write request      : 1 bit valid, 20 bit address, 137 bit data
 * 1 x Spare read request : 1 bit valid, 11 bit address
 * 1 x Spare read response: 1 bit valid,                 137 bit data
 * 1 x Spare write request: 1 bit valid, 11 bit address, 137 bit data
 *
 * 20 bit Address = Full Array in max config
 * - 10 MSBs : RAM access (VPN) - 1024 RAMs?
 * - 10 LSBs : Address for selected RAM
 * - Address broadcase to all RAMs on a request
 * - No match scenario : valid = 0, data = 0x0
 * - Less bits required in egress as it has a smaller config
 *
 * Q.The PPU restricts tables with read/write access to only use RAMs with the same delay, which
 * means that only 18 bits are needed on the write ports to handle the maximum size table, but these
 * are also kept at the same size. - Why 18 bits?
 *
 * Spare R/W
 * - Only access top RAM pair within each column
 * - 11 bit address : 1 MSB (Choose from RAM pair) + 10 LSBs for RAM access
 *
 * Q. What purpose does spare ram r/w serve?
 * Q. What if the table has multiple columns assigned within a stage? Which one os the first RAM
 * pair?
 * A. The 10 LSBs will address a RAM pair, so this is not table specific but RAM specific request
 *
 * STM UNIT:
 * - A pair of RAMs
 * - Each RAM has 1024 entries x 137 bit data (128 + 9 ECC)
 * - Logic to propogate vertical and Horizontal buses
 *
 * Requests / Responses:
 * - Configured variable delay ensures read responses from RAMs in different stages arrive at the
 *   final STM output port at the same cycle
 * - For spare rd/wr VPN RAM 0 = 0 and VPN RAM1 = 1
 *
 * Delays:
 * - STM_RAM_CFG_DEL (0 <= x <= 16)
 *   16 = 1 cycle off bus + 1 cycle on bus + 14 (2 x 7 (Ingress stages) / 2(stages per group) - 1)
 *
 * Q. How is the distance (in cycles) from PPU stage to its RAMs calculated?
 * A. Same cycles to reach an STM group i.e. 2 stages
 *
 * Q. What is an STM management used for?
 * A. How CPU accesses the RAMs, driver adds entries. Stashes not used, atomic way of doing it
 * otherwise.
 *
 * Q. Can an STM unit be added to a table dynamically by reconfiguring delays / addresses ?
 *
 * Q. Separate files for STM / SCM ?
 *
 * - Use vertical bus to allocate as many RAMs required and then use horizontal bus to add more RAMs
 *   from other columns
 * - DPU's used for dual port stats / meter / counter memorys allocated as RAMs
 * - Spare bank has less latency and has an extra rd/wr port to it (2 rd / 2 wr in same cycle)
 * - DPU's need to be allocated the spare bank row (top row) - place them first as they are most
 *   constrained
 * - No delays on vertical buses within a stage
 * - 2 Horizontal buses on each row
 *
 * - P4 logical tables mapped to difference physical table
 *   Sequence of 16 tables per stage used for predication
 * - Dynamic config - multiple p4 tables map to same physical table
 */

struct Memories : public ::Memories {
    ////////////////////////////////////////////////////////
    // SCM PARAMETERS
    ////////////////////////////////////////////////////////
    static constexpr int TCAM_ROWS = 20;      // This is to abstract the 10 x 2 -> 20 x 1
    static constexpr int TCAM_COLUMNS = 1;    // This is to abstract the 10 x 2 -> 20 x 1
    static constexpr int TCAM_DEPTH = 512;
    static constexpr int LOCAL_TIND_DEPTH = 64;
    static constexpr int TOTAL_LOCAL_TIND = 16;
    static constexpr int TABLES_MAX = 16;
    static constexpr int TERNARY_TABLES_MAX = 8;
    static constexpr int TERNARY_TABLES_WITH_STM_TIND_MAX = 4;
    static constexpr int EGRESS_STAGE0_INGRESS_STAGE = 13;

    ////////////////////////////////////////////////////////
    // STM PARAMETERS
    // Wiki - https://wiki.ith.intel.com/display/ITS51T/STM
    ////////////////////////////////////////////////////////
    static constexpr int N_ISTM_ROWS            = 6;
    static constexpr int N_ESTM_ROWS            = 4;
    static constexpr int STM_HBUS_PER_ROW       = 2;
    static constexpr int STM_STAGES_PER_GROUP   = 2;
    static constexpr int STM_COLS_PER_STAGE     = 5;
    static constexpr int STM_COLS_RD_PORTS      = 6;
    static constexpr int STM_COLS_WR_PORTS      = 1;
    static constexpr int STM_COL_SPARE_RD_PORTS = 1;
    static constexpr int STM_COL_SPARE_WR_PORTS = 1;
    static constexpr int STM_RAM_CFG_DEL        = 16;
    static constexpr int STM_RAM_DEPTH          = 1024;
    static constexpr int STM_RAM_WIDTH          = 137;
    static constexpr int STM_MIN_RD_LATENCY     = 4;
    static constexpr int STM_MAX_RD_LATENCY     = STM_MIN_RD_LATENCY + STM_RAM_CFG_DEL;

    // Search/Result busses per row
    static constexpr int BUS_COUNT              = 2;

    using Use = ::Memories::Use;

 private:
    struct search_bus_info {
        cstring name;
        // word number in exact match format
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
    };
    friend std::ostream &operator<<(std::ostream &, const search_bus_info &);

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
    };
    friend std::ostream &operator<<(std::ostream &, const result_bus_info &);

    // 16 bit mask (0..7 ingress and 8..15 egress)
    unsigned                                                scm_tbl_id = 0;

    struct scm_alloc_stage {
        // Abstract the TCAM layout as a single column with 20 rows
        BFN::Alloc1D<const IR::MAU::Table *, TCAM_ROWS>        tcam_use;
        BFN::Alloc1D<int, TCAM_ROWS>                           tcam_grp;
        BFN::Alloc1D<const IR::MAU::Table *, TCAM_ROWS>        left_hbus1;
        BFN::Alloc1D<const IR::MAU::Table *, TCAM_ROWS>        left_hbus2;
        BFN::Alloc1D<const IR::MAU::Table *, TCAM_ROWS>        right_hbus1;
        BFN::Alloc1D<const IR::MAU::Table *, TCAM_ROWS>        right_hbus2;
        BFN::Alloc1D<const IR::MAU::Table *, TOTAL_LOCAL_TIND> local_tind_use;
        unsigned tcam_in_use;         // 20 bit mask
        unsigned left_hbus1_in_use;   // 20 bit mask
        unsigned left_hbus2_in_use;   // 20 bit mask
        unsigned right_hbus1_in_use;  // 20 bit mask
        unsigned right_hbus2_in_use;  // 20 bit mask

        scm_alloc_stage() : tcam_in_use(0), left_hbus1_in_use(0), left_hbus2_in_use(0),
                            right_hbus1_in_use(0), right_hbus2_in_use(0) {}
    };
    struct scm_alloc {
        std::map<const IR::MAU::Table *, int> tbl_to_local_stage;
        std::map<int, scm_alloc_stage> stage_to_alloc;  // Ingress Stage is the key

        void clear() {
            tbl_to_local_stage.clear();
            stage_to_alloc.clear();
        }
    };
    scm_alloc scm_curr_alloc;
    friend std::ostream &operator<<(std::ostream &, const scm_alloc &);

    BFN::Alloc2D<cstring, SRAM_ROWS, 2>                         tind_bus;
    BFN::Alloc2D<cstring, N_ISTM_ROWS, STM_COLS_PER_STAGE>      sram_use;
    BFN::Alloc2D<cstring, SRAM_ROWS, PAYLOAD_COUNT>          payload_use;
    BFN::Alloc2D<cstring, SRAM_ROWS, GATEWAYS_PER_ROW>       gateway_use;

    unsigned  sram_inuse[N_ISTM_ROWS] = { 0 };

    // FIXME (Refactoring): Remove sram_print_result_bus / sram_print_search_bus
    // and move the info inside and move into main result_bus_info /
    // search_bus_info class
    BFN::Alloc2D<search_bus_info, N_ISTM_ROWS, BUS_COUNT>     sram_search_bus;
    BFN::Alloc2D<cstring, N_ISTM_ROWS, BUS_COUNT>             sram_print_search_bus;
    BFN::Alloc2D<result_bus_info, N_ISTM_ROWS, BUS_COUNT>     sram_result_bus;
    BFN::Alloc2D<cstring, N_ISTM_ROWS, BUS_COUNT>             sram_print_result_bus;
    BFN::Alloc2D<cstring, N_ISTM_ROWS, 2>                     action_data_bus;

    struct mem_info {
        int logical_tables          = 0;
        int match_tables            = 0;
        int result_bus_min          = 0;
        int match_RAMs              = 0;
        int tind_tables             = 0;
        int tind_RAMs               = 0;
        int action_tables           = 0;
        int action_bus_min          = 0;
        int action_RAMs             = 0;
        int ternary_tables          = 0;
        int ternary_TCAMs           = 0;
        int no_match_tables         = 0;
        int independent_gw_tables   = 0;

        void clear() {
            memset(this, 0, sizeof(mem_info));
        }

        int total_RAMs() const {
            return match_RAMs + action_RAMs + tind_RAMs;
        }

        int columns(int RAMs) const { return (RAMs + STM_COLS_PER_STAGE - 1) / STM_COLS_PER_STAGE; }
        bool constraint_check(int lt_allowed, cstring &failure_reason) const;
    };

    friend class SetupAttachedTables;

    // The resource information required for an individual IR::MAU::Table object in a single stage.
    // Could coordinate to multiple logical tables
    struct table_alloc {
        const IR::MAU::Table *table;
        const ::IXBar::Use *match_ixbar;
        const TableFormat::Use *table_format;
        const InstructionMemory::Use *instr_mem;
        const ActionData::Format::Use *action_format;
        std::map<UniqueId, Memories::Use>* memuse;
        const LayoutOption *layout_option;
        ActionData::FormatType_t format_type;
        int provided_entries;
        attached_entries_t attached_entries;
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
        // FIXME -- hack to avoid problems in payload calculation when the only reason we
        // have a payload is to set the match address for P4C-2938
        bool payload_match_addr_only = false;
        table_alloc(const IR::MAU::Table *t, const ::IXBar::Use *mi, const TableFormat::Use *tf,
                    const InstructionMemory::Use *im, const ActionData::Format::Use *af,
                    std::map<UniqueId, Memories::Use> *mu, const LayoutOption *lo,
                    ActionData::FormatType_t ft,
                    const int e, const int st, attached_entries_t attached_entries)
            : table(t), match_ixbar(mi), table_format(tf), instr_mem(im), action_format(af),
              memuse(mu), layout_option(lo), format_type(ft), provided_entries(e),
              attached_entries(attached_entries), attached_gw_bytes(0), stage_table(st),
              table_link(nullptr) {}
        void link_table(table_alloc *ta) {table_link = ta;}
        int analysis_priority() const;

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
        int scm_table_id = -1;
        int vpn_increment = 1;
        int vpn_offset = 0;
        int vpn_spare = 0;
        bool direct = false;  // Whether the attached table is directly or indirectly addressed
        const IR::MAU::AttachedMemory *attached = nullptr;
        UniqueAttachedId::pre_placed_type_t ppt = UniqueAttachedId::NO_PP;
        int recent_home_row = -1;  // For swbox users, most recent row to oflow to
        enum type_t { EXACT, ACTION, STATS, METER, REGISTER, SELECTOR, TIND, IDLETIME, ATCAM,
                      GROUP_TYPES } type;

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

        // cstring get_name() const;
        UniqueId build_unique_id() const;
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


    // Used for array indices in allocate_all_action
    enum RAM_side_t { LEFT = 0, RIGHT, RAM_SIDES };

    safe_vector<table_alloc *>       tables;
    safe_vector<table_alloc *>       exact_tables;
    safe_vector<SRAM_group *>        exact_match_ways;
    safe_vector<table_alloc *>       no_match_hit_tables;
    safe_vector<table_alloc *>       ternary_tables;
    safe_vector<table_alloc *>       tind_tables;
    safe_vector<SRAM_group *>        tind_groups;
    safe_vector<table_alloc *>       action_tables;
    safe_vector<SRAM_group *>        action_groups;
    safe_vector<table_alloc *>       tind_result_bus_tables;

    int allocation_count = 0;
    ordered_map<const IR::MAU::AttachedMemory *, table_alloc *> shared_attached;
    int mems_needed(int entries, int depth, int per_mem_row);
    void clear_table_vectors();
    void clear_uses();
    void clear_allocation();
    void set_logical_memuse_type(table_alloc *ta, Use::type_t type);
    bool analyze_tables(mem_info &mi);
    void calculate_entries();
    bool single_allocation_balance(unsigned row);
    bool allocate_all_exact(unsigned column_mask);
    bool allocate_all_actiondata(unsigned column_mask);
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
    void compress_row(Use &alloc);

    bool determine_match_rows_and_cols(SRAM_group *group, int row, unsigned column_mask,
        match_selection &match_select);

    bool allocate_all_ternary();
    int ternary_TCAMs_necessary(table_alloc *ta);
    bool find_ternary_stretch(int TCAMs_necessary,
                              BFN::Alloc1D<const IR::MAU::Table *, TCAM_ROWS> &tcam_use, int &row);

    bool allocate_all_tind();
    void find_tind_groups();

    table_alloc *find_corresponding_exact_match(cstring name);

    bool find_mem_and_bus_for_idletime(std::vector<std::pair<int, std::vector<int>>>& mem_locs,
                                    int& bus, int total_mem_required, bool top_half);
    void compress_ways();
    void fill_out_match_alloc(SRAM_group *group, match_selection &match_select);
    friend std::ostream &operator<<(std::ostream &, const safe_vector<Memories::table_alloc *> &);

 public:
    bool allocate_all();
    void update(cstring name, const Use &alloc);
    void update(const std::map<UniqueId, Use> &alloc);
    void remove(cstring name, const Use &alloc);
    void remove(const std::map<UniqueId, Use> &alloc);
    void clear();
    void add_table(const IR::MAU::Table *t, const IR::MAU::Table *gw,
                   TableResourceAlloc *resources, const LayoutOption *lo,
                   const ActionData::Format::Use *af, ActionData::FormatType_t ft,
                   int entries, int stage_table, attached_entries_t attached_entries);
    void shrink_allowed_lts() { logical_tables_allowed--; }
    void fill_placed_scm_table(const IR::MAU::Table *, const TableResourceAlloc *);
    void printOn(std::ostream &) const;
    void init_shared(int stage) { local_stage = stage; scm_curr_alloc.clear(); }
    void visitUse(const Use &, std::function<void(cstring &, update_type_t)> fn);
};

}  // namespace Flatrock

#endif /* BF_P4C_MAU_FLATROCK_MEMORIES_H_ */
