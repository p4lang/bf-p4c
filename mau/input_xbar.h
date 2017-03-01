#ifndef _TOFINO_MAU_INPUT_XBAR_H_
#define _TOFINO_MAU_INPUT_XBAR_H_

#include <unordered_set>
#include "lib/alloc.h"
#include "lib/hex.h"
#include "ir/ir.h"
#include "tofino/mau/table_layout.h"

class PhvInfo;
class IXBarRealign;
struct TableResourceAlloc;


struct IXBar {
    static constexpr int EXACT_GROUPS = 8;
    static constexpr int EXACT_BYTES_PER_GROUP = 16;
    static constexpr int HASH_TABLES = 16;
    static constexpr int HASH_GROUPS = 8;
    static constexpr int HASH_INDEX_GROUPS = 4;  /* groups of 10 bits for indexing */
    static constexpr int HASH_SINGLE_BITS = 12;  /* top 12 bits of hash table individually */
    static constexpr int HASH_DIST_GROUPS = 3;
    static constexpr int HASH_DIST_BITS = 16;
    static constexpr int HASH_DIST_UNITS = 2;
    static constexpr int TERNARY_GROUPS = StageUse::MAX_TERNARY_GROUPS;
    static constexpr int BYTE_GROUPS = StageUse::MAX_TERNARY_GROUPS/2;
    static constexpr int TERNARY_BYTES_PER_GROUP = 5;
    struct Loc {
        int group = -1, byte = -1;
        Loc() = default;
        Loc(int g, int b) : group(g), byte(b) {}
        explicit operator bool() const { return group >= 0 && byte >= 0; }
        operator std::pair<int, int>() const { return std::make_pair(group, byte); }
    };

 private:
    /* IXBar tracks the use of all the input xbar bytes in a single stage.  Each byte use is set
     * to record the name of the field it will be getting and the bit offset within the field.
     * cstrings here are field names as used in PhvInfo (so PhvInfo::field can be used to find
     * out details about the field) */
    Alloc2D<std::pair<cstring, int>, EXACT_GROUPS, EXACT_BYTES_PER_GROUP>       exact_use;
    Alloc2D<std::pair<cstring, int>, TERNARY_GROUPS, TERNARY_BYTES_PER_GROUP>   ternary_use;
    Alloc1D<std::pair<cstring, int>, BYTE_GROUPS>                               byte_group_use;
    Alloc2Dbase<std::pair<cstring, int>> &use(bool ternary) {
        if (ternary) return ternary_use;
        return exact_use; }
    /* reverse maps of the above, mapping field names to sets of group+byte */
    std::multimap<cstring, Loc>         exact_fields;
    std::multimap<cstring, Loc>         ternary_fields;
    std::multimap<cstring, Loc> &fields(bool ternary) {
        return ternary ? ternary_fields : exact_fields; }

    /* Track the use of hashtables/groups too -- FIXME -- should it be a separate data structure?
     * strings here are table names */
    Alloc2D<cstring, HASH_TABLES, HASH_INDEX_GROUPS>    hash_index_use;
    unsigned                                    hash_index_inuse[HASH_INDEX_GROUPS] = { 0 };
    Alloc2D<cstring, HASH_TABLES, HASH_SINGLE_BITS>     hash_single_bit_use;
    unsigned                                    hash_single_bit_inuse[HASH_SINGLE_BITS] = { 0 };
    Alloc1D<cstring, HASH_GROUPS>                      hash_group_print_use;
    unsigned                                    hash_group_use[HASH_GROUPS] = { 0 };
    Alloc2D<cstring, HASH_TABLES, HASH_DIST_GROUPS>     hash_dist_use;
    unsigned                                    hash_dist_inuse[HASH_TABLES] = { 0 };
    Alloc2D<cstring, HASH_TABLES, HASH_DIST_GROUPS * HASH_DIST_BITS>   hash_dist_bit_use;
    unsigned long                               hash_dist_bit_inuse[HASH_TABLES] = { 0 };
    int hash_dist_groups[HASH_DIST_UNITS] = {-1, -1};
    friend class IXBarRealign;

 public:
    unordered_set<const IR::ActionSelector *>                selectors;
    /* IXbar::Use tracks the input xbar use of a single table */
    struct Use {
        /* everything is public so anyone can read it, but only IXBar should write to this */
        enum flags_t { NeedRange = 1, NeedXor = 2,
                       Align16lo = 4, Align16hi = 8, Align32lo = 16, Align32hi = 32 };
        bool            ternary;
        bool            gw_search_bus;  int gw_search_bus_bytes;
        bool            gw_hash_group;

        enum algorithm_t { ExactMatch, Random, CRC16, CRC32, Identity };
        enum hash_dist_type_t { CounterPtr = 1, MeterPtr = 2, RegisterPtr = 4, Immediate = 8,
                                MeterPre = 16, SelectMod = 32 };
        /* tracking individual bytes (or parts of bytes) placed on the ixbar */
        struct Byte {
            cstring     field;
            int         lo, hi;
            Loc         loc;
            int         flags = 0;  // flags describing alignment and gateway use/requirements
            Byte(cstring f, int l, int h) : field(f), lo(l), hi(h) {}
            Byte(cstring f, int l, int h, int g, int gb) : field(f), lo(l), hi(h), loc(g, gb) {}
            operator std::pair<cstring, int>() const { return std::make_pair(field, lo); }
            bool operator==(const std::pair<cstring, int> &a) const {
                return field == a.first && lo == a.second; } };
        vector<Byte>    use;

        /* which of the 16 hash tables we are using (bitvec) */
        unsigned        hash_table_inputs[HASH_GROUPS] = { 0 };
        /* values fed through the hash tables onto the upper 12 bits of the hash bus via
         * an identity matrix */
        struct Bits {
            cstring     field;
            int         group;
            int         lo, bit, width;
            Bits(cstring f, int g, int l, int b, int w)
            : field(f), group(g), lo(l), bit(b), width(w) {}
            int hi() const { return lo + width - 1; } };
        vector<Bits>    bit_use;

        /* hash tables used for way address computation */
        struct Way {
            int         group, slice;  // group refers to which 8 of the hash groups used,
                                       // slice refers to the 10b way used
            unsigned    mask;
            Way() = delete;
            Way(int g, int s, unsigned m) : group(g), slice(s), mask(m) {} };
        vector<Way>     way_use;

        struct Select {
            int          group;
            unsigned     bit_mask;
            algorithm_t  alg;
            explicit Select(int g) : group(g), bit_mask(0) {}
        };
        vector<Select> select_use;

        struct HashDist {
            vector<Byte>      use;
            unsigned          hash_table_input;
            int               unit = -1;
            int               group = -1;
            unsigned          slice = 0;
            unsigned long     bit_mask = 0;
            int               shift = 0;
            int               max_size = 0;
            algorithm_t       alg;
            hash_dist_type_t  type;
            HashDist() : use(), group(-1) {}
        };
        vector<HashDist> hash_dist_use;

        void clear() { use.clear(); memset(hash_table_inputs, 0, sizeof(hash_table_inputs));
                       bit_use.clear(); way_use.clear(); select_use.clear();
                       hash_dist_use.clear(); }
        unsigned compute_hash_tables();
        unsigned compute_hash_dist_tables(int i = -1);
        int groups() const;  // how many different groups in this use
        bool exact_comp(const IXBar::Use *exact_use, int width) const;
        void add(const Use &alloc);
        int hash_groups() const;
    };

    /* A problem occurred with the way the IXbar was allocated that requires backtracking
     * and trying something else */
    struct failure : public Backtrack::trigger {
        int     stage = -1, group = -1;
        failure(int stg, int grp) : trigger(OTHER), stage(stg), group(grp) {}
    };


/* An individual SRAM group or half of a TCAM group */
    struct grp_use {
        enum type_t { MATCH, HASH_DIST, FREE };
        int group;
        bitvec found;
        bitvec free;
        bool first_hash_open = true;
        bool second_hash_open = true;
        type_t first_hash_dist = FREE;
        type_t second_hash_dist = FREE;

        bool first_hash_dist_avail() {
            return first_hash_dist == HASH_DIST || first_hash_dist == FREE;
        }

        bool second_hash_dist_avail() {
            return second_hash_dist == HASH_DIST || second_hash_dist == FREE;
        }

        bool first_hash_dist_only() {
            return first_hash_dist == HASH_DIST;
        }

        bool second_hash_dist_only() {
            return second_hash_dist == HASH_DIST;
        }
        void dbprint(std::ostream &out) const {
            out << group << " found: " << found << " free: " << free;
        }
    };

    /* A struct use for TCAM split between 2 groups.  Mid bytes are for the individual
       byte groups within the two ternary groups.  Only one grp_use is necessary for the
       calculation of the SRAM xbar */
    struct big_grp_use {
        int big_group;
        grp_use first;
        grp_use second;
        bool mid_byte_found;
        bool mid_byte_free;
        void dbprint(std::ostream &out) const {
            out << big_group << " : found=" << first.found << " " << mid_byte_found << " "
                << second.found  << " : free= " << first.free  << " " << mid_byte_free
                << " " << second.free; }
        int total_found() const { return first.found.popcount() + second.found.popcount()
                                         + mid_byte_found; }
        int total_free() const { return first.free.popcount() + second.free.popcount()
                                        + mid_byte_free; }
        int total_used() const { return total_found() + total_free(); }
        int better_group() const {
            int first_open = first.free.popcount() + first.found.popcount();
            int second_open = second.free.popcount() + second.found.popcount();
            if (first_open >= second_open)
                 return first_open;
            return second_open;
        }
    };


    void clear();
    bool allocMatch(bool ternary, const IR::P4Table *tbl, const PhvInfo &phv, Use &alloc,
                    vector<IXBar::Use::Byte *> &alloced, bool second_try, int hash_groups);
    int getHashGroup(unsigned hash_table_input);
    void getHashDistGroups(unsigned hash_table_input, int hash_group_opt[2]);
    bool allocAllHashWays(bool ternary, const IR::MAU::Table *tbl, Use &alloc,
                          const IR::MAU::Table::LayoutOption *layout_option,
                          size_t start, size_t last);
    bool allocHashWay(const IR::MAU::Table *tbl,
                      const IR::MAU::Table::LayoutOption *layout_option,
                      size_t index, size_t start, Use &alloc);
    bool allocGateway(const IR::MAU::Table *, const PhvInfo &phv, Use &alloc, bool second_try);
    bool allocSelector(const IR::ActionSelector *, const IR::P4Table *, const PhvInfo &phv,
                       Use &alloc, bool second_try, cstring name);
    bool allocHashDist(const HashDistReq &hash_dist_req, const PhvInfo &phv, Use &alloc,
                       bool second_try, const IR::MAU::Table *tbl, cstring name);
    bool allocTable(const IR::MAU::Table *tbl, const PhvInfo &phv, Use &tbl_alloc, Use &gw_alloc,
                    Use &sel_alloc, const IR::MAU::Table::LayoutOption *lo,
                    const vector<HashDistReq> &hash_dist_reqs);
    void update_hash_dist(cstring name, const Use &alloc);
    void update(cstring name, const Use &alloc);
    void update(cstring name, const TableResourceAlloc *alloc);
    void update(const IR::MAU::Table *tbl) {
        if (tbl->resources) update(tbl->name, tbl->resources); }
    friend std::ostream &operator<<(std::ostream &, const IXBar &);
    const Loc *findExactByte(cstring name, int byte) const {
        for (auto &p : Values(exact_fields.equal_range(name)))
            if (exact_use.at(p.group, p.byte).second/8 == byte)
                return &p;
        /* FIXME -- what if it's in more than one place? */
        return nullptr; }

 private:
    bool find_alloc(vector<IXBar::Use::Byte> &alloc_use, bool ternary, bool second_try,
                    vector<IXBar::Use::Byte *> &alloced, int hash_groups_needed,
                    bool hash_dist = false);
    bool find_original_alloc(IXBar::Use &alloc, bool ternary, bool second_try);
    bool find_ternary_alloc(IXBar::Use &alloc, bool ternary, bool second_try);
    void calculate_available_groups(vector<big_grp_use> &order, int hash_groups_needed);
    grp_use::type_t is_group_for_hash_dist(int hash_table);
    bool violates_hash_constraints(vector <big_grp_use> &order, bool hash_dist, int group,
                                   int byte);
    void calculate_found(vector<IXBar::Use::Byte *> unalloced, vector<big_grp_use> &order,
                         bool ternary, bool hash_dist);
    void calculate_ternary_free(vector<big_grp_use> &order, int big_groups,
                                int bytes_per_big_group);
    void calculate_exact_free(vector<big_grp_use> &order, int big_groups,
                              int bytes_per_big_group, bool hash_dist);
    int found_bytes(grp_use *grp, vector<IXBar::Use::Byte *> &unalloced, bool ternary);
    int free_bytes(grp_use *grp, vector<IXBar::Use::Byte *> &unalloced,
                   vector<IXBar::Use::Byte *> &alloced, bool ternary, bool hash_dist);
    int found_bytes_big_group(big_grp_use *grp, vector<IXBar::Use::Byte *> &unalloced);
    int free_bytes_big_group(big_grp_use *grp, vector<IXBar::Use::Byte *> &unalloced,
                                 vector<IXBar::Use::Byte *> &alloced);
    void allocate_free_byte(grp_use *grp, vector<IXBar::Use::Byte *> &unalloced,
                            vector<IXBar::Use::Byte *> &alloced, IXBar::Use::Byte &need,
                            int group, int byte, int &index, int &free_bytes, int &bytes_placed);
    void fill_out_use(vector<IXBar::Use::Byte *> &alloced, bool ternary);
    bool big_grp_alloc(bool ternary, bool second_try, vector<IXBar::Use::Byte *> &unalloced,
                       vector<IXBar::Use::Byte *> &alloced, vector<big_grp_use> &order,
                       int big_groups_needed, int &total_bytes_needed, int bytes_per_big_group,
                       bool hash_dist);
    bool small_grp_alloc(bool ternary, bool second_try, vector<IXBar::Use::Byte *> &unalloced,
                         vector<IXBar::Use::Byte *> &alloced, vector<grp_use *> &small_order,
                         vector<big_grp_use> &order, int &total_bytes_needed, bool hash_dist);
    void layout_option_calculation(const IR::MAU::Table::LayoutOption *layout_option,
                                   size_t &start, size_t &last);
    void field_management(const IR::Expression *field, IXBar::Use &alloc,
        set<cstring> &fields_needed, bool hash_dist, cstring name, const PhvInfo &phv);
    void initialize_hash_dist(const HashDistReq &hash_dist_req, IXBar::Use &alloc,
        const PhvInfo &phv, set<cstring> &fields_needed, const IR::MAU::Table *tbl, cstring name);
    bool allocHashDistAddress(const HashDistReq &hash_dist_req,
        const unsigned used_hash_dist_groups, const unsigned long used_hash_dist_bits,
        const unsigned &hash_table_input, unsigned &slice, unsigned long &bit_mask, cstring name,
        const PhvInfo &phv);
    bool allocHashDistImmediate(const HashDistReq &hash_dist_req,
        const unsigned used_hash_dist_groups,
        const unsigned &hash_table_input, unsigned &slice, unsigned long &bit_mask, cstring name,
        const PhvInfo &phv);
};

inline std::ostream &operator<<(std::ostream &out, const IXBar::Loc &l) {
    return out << '(' << l.group << ',' << l.byte << ')'; }

inline std::ostream &operator<<(std::ostream &out, const IXBar::Use::Byte &b) {
    out << b.field << '[' << b.lo << ".." << b.hi << ']';
    if (b.loc) out << b.loc;
    if (b.flags) out << " flags=" << hex(b.flags);
    return out; }

#endif /* _TOFINO_MAU_INPUT_XBAR_H_ */
