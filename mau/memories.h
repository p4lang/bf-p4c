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

 
    Alloc2D<cstring, SRAM_ROWS, SRAM_COLUMNS>           sram_use;
    unsigned                                     sram_inuse[SRAM_ROWS] = { 0 };
    Alloc2D<cstring, TCAM_ROWS, TCAM_COLUMNS>           tcam_use;
    Alloc2D<cstring, SRAM_ROWS, MAPRAM_COLUMNS>         mapram_use;
    Alloc2D<cstring, SRAM_ROWS, 2>                      sram_search_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                      sram_match_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                      tind_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                      action_data_bus;
    Alloc1D<cstring, SRAM_ROWS>                         stateful_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                      overflow_bus;
    Alloc1D<cstring, SRAM_ROWS - 1>                     vert_overflow_bus;

    struct mem_info {
        int match_tables;
        int match_bus_min;
        int match_RAMs;
        int tind_tables;
        int tind_RAMs;
        int action_tables;
        int action_bus_min;
        int action_RAMs;

        void clear() {
            match_tables = 0; match_bus_min = 0; match_RAMs = 0; tind_tables = 0;
            tind_RAMs = 0; action_tables = 0; action_bus_min = 0; action_RAMs = 0;
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
        };
        vector<Row>     row;
        vector<std::pair<int, unsigned>>     ways;
        // depth in memory units + mask to use for memory selection per way
        void visit(Memories &mem, std::function<void(cstring &)>) const;
    };

    struct table_alloc {
        const IR::MAU::Table *table;
        const IXBar::Use match_ixbar;
        map<cstring, Memories::Use> alloc;
        int entries;
        explicit table_alloc(const IR::MAU::Table *t, const IXBar::Use mi, int e) 
                : table(t), match_ixbar(mi), entries(e) {}
    };

    struct way_group {
        table_alloc *ta;
        int depth;
        int width;
        int placed;
        explicit way_group (table_alloc *t, int d, int w) : ta(t), depth(d), width(w), placed(0) {}
    };

    Alloc2D<std::pair<table_alloc *, int> *, SRAM_ROWS, 2>   sram_match_bus2;
    Alloc2D<std::pair<table_alloc *, int> *, SRAM_ROWS, 2>   sram_search_bus2;
    Alloc2D<table_alloc *, SRAM_ROWS, SRAM_COLUMNS>          sram_use2;

    vector<table_alloc *>      tables;
    vector<table_alloc *>      exact_tables;
    vector<way_group *>        exact_match_ways;

    void clear();
    void add_table(const IR::MAU::Table *t, const IXBar::Use mi,  int entries);
    bool analyze_tables(mem_info &mi);
    bool allocate_all();
    bool allocate_all_exact(mem_info &mi);
    bool allocate_exact(table_alloc *ta, mem_info &mi, int average_depth);    
    vector<int> way_size_calculator(int ways, int RAMs_needed);
    vector<std::pair<int, int>> available_SRAMs_per_row(unsigned mask, table_alloc *ta,
                                                        int depth);  
    vector<int> available_match_SRAMs_per_row(unsigned row_mask, unsigned total_mask, int row,
                                                 table_alloc *ta, int width_sect);
    void break_exact_tables_into_ways();
    bool find_best_row_and_fill_out();
    bool fill_out_row(way_group *placed_wa, int row);
    way_group * find_best_candidate(way_group *placed_wa, int row);


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
