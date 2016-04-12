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
    Alloc2D<cstring, TCAM_ROWS, TCAM_COLUMNS>           tcam_use;
    Alloc2D<cstring, SRAM_ROWS, MAPRAM_COLUMNS>         mapram_use;
    Alloc2D<cstring, SRAM_ROWS, 2>                      sram_match_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                      tind_bus;
    Alloc2D<cstring, SRAM_ROWS, 2>                      action_data_bus;
    Alloc1D<cstring, SRAM_ROWS>                         stateful_bus;

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

    void clear();
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
