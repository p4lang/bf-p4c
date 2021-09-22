#ifndef BF_P4C_MAU_MEMORIES_H_
#define BF_P4C_MAU_MEMORIES_H_

#include <algorithm>
#include "bf-p4c/mau/attached_entries.h"
#include "bf-p4c/mau/input_xbar.h"
#include "bf-p4c/mau/action_format.h"
#include "ir/ir.h"
#include "lib/alloc.h"
#include "lib/safe_vector.h"

struct Memories {
    /* track memory allocations within a single stage */
    // FIXME -- these constants likely all need to change for Flatrock, so they need
    // to become virtual params of some kind.
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
    static constexpr int BUS_COUNT = 2;         // search/result busses per row
    static constexpr int PAYLOAD_COUNT = 2;     // payload per row
    static constexpr int STATS_ALUS = 4;
    static constexpr int METER_ALUS = 4;
    static constexpr int MAX_DATA_SWBOX_ROWS = 5;
    static constexpr int COLOR_MAPRAM_PER_ROW = 4;
    static constexpr int IMEM_ADDRESS_BITS = 6;
    static constexpr int IMEM_LOOKUP_BITS = 3;
    static constexpr int NUM_IDLETIME_BUS = 10;
    static constexpr int MAX_PARTITION_RAMS_PER_ROW = 5;
    static constexpr int MATCH_CENTRAL_ROW = 4;
    static constexpr int MAX_STATS_ROW_PER_ALU = 3;
    static constexpr int MAX_STATS_RAM_PER_ALU = MAPRAM_COLUMNS * MAX_STATS_ROW_PER_ALU;

    static constexpr int LOGICAL_ROW_MISSING_OFLOW = 8;

    /* Memories::Use tracks memory use of a single table */
    struct Use {
        enum type_t { EXACT, ATCAM, TERNARY, GATEWAY, TIND, IDLETIME, COUNTER, METER, SELECTOR,
                      STATEFUL, ACTIONDATA } type;
        bool is_twoport() const { return type == COUNTER || type == METER || type == SELECTOR
                                         || type == STATEFUL; }
        std::string used_by;
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
            int      payload_match_address = -1;
            int      payload_row = -1;
            int      payload_unit = -1;
            int      unit = -1;
            type_t bus_type;
            void clear() {
                payload_value = 0ULL;
                payload_match_address = -1;
                payload_row = -1;
                payload_unit = -1;
                unit = -1;
            }
        };

        safe_vector<Row>                         row;
        safe_vector<Row>                         color_mapram;
        safe_vector<std::pair<int, int>>         home_row;
        safe_vector<Way>                         ways;
        Gateway                                  gateway;
        int                                      tind_result_bus = -1;
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
        std::map<UniqueId, ordered_set<UniqueId>> unattached_tables;
        safe_vector<UniqueId>                    dleft_learn;
        safe_vector<UniqueId>                    dleft_match;

        int get_way(int row, int col) {
            for (size_t i = 0; i < ways.size(); i++) {
                auto w = ways[i];
                for (auto ram : w.rams) {
                    if ((ram.first == row) && (ram.second == col))
                        return i;
                }
            }
            return -1;
        }

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

        int rams_required() const;
        bool separate_search_and_result_bus() const;
        // depth in memory units + mask to use for memory selection per way
    };

 public:
    virtual ~Memories() {}
    virtual bool allocate_all() = 0;
    virtual bool allocate_all_dummies() = 0;
    virtual void update(cstring table_name, const Use &alloc) = 0;
    virtual void update(const std::map<UniqueId, Use> &alloc) = 0;
    virtual void remove(cstring table_name, const Use &alloc) = 0;
    virtual void remove(const std::map<UniqueId, Use> &alloc) = 0;
    virtual void clear() = 0;
    virtual void add_table(const IR::MAU::Table *t, const IR::MAU::Table *gw,
                   TableResourceAlloc *resources, const LayoutOption *lo,
                   const ActionData::Format::Use *af, ActionData::FormatType_t ft,
                   int entries, int stage_table, attached_entries_t attached_entries) = 0;
    virtual void shrink_allowed_lts() = 0;
    virtual void printOn(std::ostream &) const = 0;
    cstring last_failure() const { return failure_reason ? failure_reason : ""; }

 protected:
    enum update_type_t { UPDATE_RAM, UPDATE_MAPRAM, UPDATE_GATEWAY,
                         UPDATE_PAYLOAD, UPDATE_RESULT_BUS };
    virtual void visitUse(const Use &, std::function<void(cstring &, update_type_t)> fn) = 0;
    cstring failure_reason;

 public:
    static Memories *create();
    friend std::ostream &operator<<(std::ostream &out, const Memories &m) {
        m.printOn(out);
        return out; }
};

template<int R, int C>
std::ostream &operator<<(std::ostream&, const Alloc2D<cstring, R, C>& alloc2d);

#endif /* BF_P4C_MAU_MEMORIES_H_ */
