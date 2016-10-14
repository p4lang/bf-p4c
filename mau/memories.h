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

    Alloc2D<cstring, SRAM_ROWS, SRAM_COLUMNS>          sram_use;
    unsigned                                           sram_inuse[SRAM_ROWS] = { 0 };
    Alloc2D<cstring, TCAM_ROWS, TCAM_COLUMNS>          tcam_use;
    Alloc2D<std::pair<cstring, int> *, SRAM_ROWS, 2>   sram_match_bus;
    Alloc2D<std::pair<cstring, int> *, SRAM_ROWS, 2>   sram_search_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                     sram_print_match_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                     action_data_bus;
    Alloc2D<cstring,  SRAM_ROWS, 2>                    tind_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                     overflow_bus;
    Alloc1D<cstring, SRAM_ROWS - 1>                    vert_overflow_bus;
    Alloc2D<cstring, SRAM_ROWS, MAPRAM_COLUMNS>        mapram_use;
    Alloc1D<cstring, SRAM_ROWS>                        stateful_bus;

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

        void clear() {
            match_tables = 0; match_bus_min = 0; match_RAMs = 0; tind_tables = 0;
            tind_RAMs = 0; action_tables = 0; action_bus_min = 0; action_RAMs = 0;
            ternary_tables = 0; ternary_TCAMs = 0;
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
        vector<std::pair<int, unsigned>>     ways;
        // depth in memory units + mask to use for memory selection per way
        void visit(Memories &mem, std::function<void(cstring &)>) const;
    };

    struct table_alloc {
        const IR::MAU::Table *table;
        const IXBar::Use *match_ixbar;
        map<cstring, Memories::Use>* memuse;
        int provided_entries;
        int calculated_entries;
        cstring name;
        explicit table_alloc(const IR::MAU::Table *t, const IXBar::Use *mi,
                             map<cstring, Memories::Use> *mu, int e)
                : table(t), match_ixbar(mi), memuse(mu), provided_entries(e),
                  calculated_entries(0) {}
    };

    struct SRAM_group {
        table_alloc *ta;
        int depth;
        int width;
        int placed;
        int number;
        explicit SRAM_group(table_alloc *t, int d, int w, int n)
            : ta(t), depth(d), width(w), placed(0), number(n) {}
        explicit SRAM_group(table_alloc *t, int d, int n)
                     : ta(t), depth(d), width(0),  placed(0), number(n) {}
        void dbprint(std::ostream &out) const {
            out << ta->table->name << " way #" << number << " depth: " << depth
                << " width: " << width << " placed: " << placed;
        }
        int left_to_place() { return depth - placed; }
        bool all_placed() { return (depth == placed); }
    };

    vector<table_alloc *>      tables;
    vector<table_alloc *>      exact_tables;
    vector<SRAM_group *>       exact_match_ways;
    vector<table_alloc *>      ternary_tables;
    vector<table_alloc *>      tind_tables;
    vector<SRAM_group *>       tind_groups;
    vector<table_alloc *>      action_tables;
    vector<SRAM_group *>       action_bus_users;
    vector<table_alloc *>      gw_tables;

    void clear();
    void add_table(const IR::MAU::Table *t, const IXBar::Use *mi,
                   map<cstring, Memories::Use> *mu, int entries);
    bool analyze_tables(mem_info &mi);
    void calculate_column_balance();
    bool allocate_all();
    bool allocate_all_exact();
    bool allocate_exact(table_alloc *ta, mem_info &mi, int average_depth);
    vector<int> way_size_calculator(int ways, int RAMs_needed);
    vector<std::pair<int, int>> available_SRAMs_per_row(unsigned mask, table_alloc *ta,
                                                        int depth);
    vector<int> available_match_SRAMs_per_row(unsigned row_mask, unsigned total_mask, int row,
                                                 table_alloc *ta, int width_sect);
    void break_exact_tables_into_ways();
    int match_bus_available(table_alloc *ta, int width, int row);
    bool find_best_row_and_fill_out();
    bool fill_out_row(SRAM_group *placed_wa, int row);
    bool pack_way_into_RAMs(SRAM_group *wa, int row, int &cols);
    SRAM_group *find_best_candidate(SRAM_group *placed_wa, int row, int &loc);
    void compress_ways();

    bool allocate_all_ternary();
    int ternary_TCAMs_necessary(table_alloc *ta, int &mid_bytes_needed);
    bool find_ternary_stretch(int TCAMs_necessary, int mid_bytes_needed, int &row, int &col);

    bool allocate_all_tind();
    void find_tind_groups();

    bool allocate_all_action();
    void find_action_bus_users();
    void find_action_candidates(int row, int mask, SRAM_group **a_group, unsigned &a_mask,
                                int &a_index, SRAM_group** oflow_group,
                                unsigned &oflow_mask, int &oflow_index);
    bool best_a_oflow_pair(SRAM_group **best_a_group, SRAM_group **best_oflow_group,
                           int &a_index, int &oflow_index, int RAMs_available,
                           SRAM_group *best_fit_group, int best_fit_index,
                           SRAM_group *curr_oflow_group);
    bool fill_out_action_row(SRAM_group *a_group, unsigned a_mask, int a_index,
                             int row, int side, unsigned mask, bool is_oflow);

    bool allocate_all_gw();

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
