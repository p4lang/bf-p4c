#ifndef _TOFINO_MAU_INPUT_XBAR_H_
#define _TOFINO_MAU_INPUT_XBAR_H_

#include "lib/alloc.h"
#include "lib/hex.h"
#include "ir/ir.h"

class PhvInfo;
class IXBarRealign;
struct TableResourceAlloc;
// FIXME: Maybe a different format
struct grp_use;
struct big_grp_use;


struct IXBar {
    enum {
        EXACT_GROUPS = 8,
        EXACT_BYTES_PER_GROUP = 16,
        HASH_TABLES = 16,
        HASH_GROUPS = 8,
        HASH_INDEX_GROUPS = 4,  /* groups of 10 bits for indexing */
        HASH_SINGLE_BITS = 12,  /* top 12 bits of each hash table tacked individually */
        TERNARY_GROUPS = StageUse::MAX_TERNARY_GROUPS,
        BYTE_GROUPS = StageUse::MAX_TERNARY_GROUPS/2,
        TERNARY_BYTES_PER_GROUP = 5,
    };
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
    Alloc1D<cstring, HASH_GROUPS>                       hash_group_use;
    friend class IXBarRealign;

 public:
    /* IXbar::Use tracks the input xbar use of a single table */
    struct Use {
        /* everything is public so anyone can read it, but only IXBar should write to this */
        enum flags_t { NeedRange = 1, NeedXor = 2,
                       Align16lo = 4, Align16hi = 8, Align32lo = 16, Align32hi = 32 };
        bool            ternary;
        /* tracking individual bytes (or parts of bytes) placed on the ixbar */
        struct Byte {
            cstring     field;
            int         lo, hi;
            Loc         loc;
            int         flags;  // flags describing alignment and gateway use/requirements
            Byte(cstring f, int l, int h) : field(f), lo(l), hi(h) {}
            Byte(cstring f, int l, int h, int g, int gb) : field(f), lo(l), hi(h), loc(g, gb) {}
            operator std::pair<cstring, int>() const { return std::make_pair(field, lo); }
            bool operator==(const std::pair<cstring, int> &a) const {
                return field == a.first && lo == a.second; } };
        vector<Byte>    use;

        /* which of the 16 hash tables we are using (bitvec) */
        unsigned        hash_table_input = 0;

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
            int         group, slice;
            unsigned    mask;
            Way() = delete;
            Way(int g, int s, unsigned m) : group(g), slice(s), mask(m) {} };
        vector<Way>     way_use;

        void clear() { use.clear(); hash_table_input = 0; bit_use.clear(); way_use.clear(); }
        void compute_hash_tables();
        int groups() const;  // how many different groups in this use
    };

    /* A problem occurred with the way the IXbar was allocated that requires backtracking
     * and trying something else */
    struct failure : public Backtrack::trigger {
        int     stage = -1, group = -1;
        failure(int stg, int grp) : trigger(OTHER), stage(stg), group(grp) {}
    };

    void clear();
    bool allocMatch(bool ternary, const IR::V1Table *tbl, const PhvInfo &phv, Use &alloc,
                    vector<IXBar::Use::Byte *> &alloced, bool second_try, int hash_groups);
    int getHashGroup(cstring name);
    bool allocAllHashWays(bool ternary, const IR::MAU::Table *tbl, Use &alloc);
    bool allocHashWay(const IR::MAU::Table *, const IR::MAU::Table::Way &, Use &);
    bool allocGateway(const IR::MAU::Table *, const PhvInfo &phv, Use &alloc, bool second_try);
    bool allocTable(const IR::MAU::Table *tbl, const PhvInfo &phv, Use &tbl_alloc, Use &gw_alloc);
    void update(cstring name, const Use &alloc);
    void update(cstring name, const TableResourceAlloc *alloc);
    void update(const IR::MAU::Table *tbl) {
        if (tbl->resources) update(tbl->name, tbl->resources); }
    friend std::ostream &operator<<(std::ostream &, const IXBar &);
    const Loc *findExactByte(cstring name, int byte) const {
        for (auto &p : Values(exact_fields.equal_range(name)))
            if (exact_use.at(p.group, p.byte).second == byte)
                return &p;
        /* FIXME -- what if it's in more than one place? */
        return nullptr; }

 private:
    bool find_alloc(IXBar::Use &alloc, bool ternary, bool second_try,
                    vector<IXBar::Use::Byte *> &alloced, int hash_groups_needed);
    bool find_original_alloc(IXBar::Use &alloc, bool ternary, bool second_try);
    bool find_ternary_alloc(IXBar::Use &alloc, bool ternary, bool second_try);
    void calculate_available_groups(vector<big_grp_use> &order, int hash_groups_needed);
    void calculate_found(vector<IXBar::Use::Byte *> unalloced, vector<big_grp_use> &order,
                         bool ternary);
    void calculate_ternary_free(vector<big_grp_use> &order, int big_groups,
                                int bytes_per_big_group);
    void calculate_exact_free(vector<big_grp_use> &order, int big_groups,
                              int bytes_per_big_group);
    int found_bytes(grp_use *grp, vector<IXBar::Use::Byte *> &unalloced, bool ternary);
    int free_bytes(grp_use *grp, vector<IXBar::Use::Byte *> &unalloced,
                   vector<IXBar::Use::Byte *> &alloced, bool ternary);
    int found_bytes_big_group(big_grp_use *grp, vector<IXBar::Use::Byte *> &unalloced);
    int free_bytes_big_group(big_grp_use *grp, vector<IXBar::Use::Byte *> &unalloced,
                                 vector<IXBar::Use::Byte *> &alloced);
    void allocate_free_byte(grp_use *grp, vector<IXBar::Use::Byte *> &unalloced,
                            vector<IXBar::Use::Byte *> &alloced, IXBar::Use::Byte &need,
                            int group, int byte, int &index, int &free_bytes, int &bytes_placed);
    void fill_out_use(vector<IXBar::Use::Byte *> &alloced, bool ternary);
    bool big_grp_alloc(bool ternary, bool second_try, vector<IXBar::Use::Byte *> &unalloced,
                       vector<IXBar::Use::Byte *> &alloced, vector<big_grp_use> &order,
                       int big_groups_needed, int &total_bytes_needed, int bytes_per_big_group);
    bool small_grp_alloc(bool ternary, bool second_try, vector<IXBar::Use::Byte *> &unalloced,
                         vector<IXBar::Use::Byte *> &alloced, vector<grp_use *> &small_order,
                         vector<big_grp_use> &order, int &total_bytes_needed);
};

inline std::ostream &operator<<(std::ostream &out, const IXBar::Loc &l) {
    return out << '(' << l.group << ',' << l.byte << ')'; }

inline std::ostream &operator<<(std::ostream &out, const IXBar::Use::Byte &b) {
    out << b.field << '[' << b.lo << ".." << b.hi << ']';
    if (b.loc) out << b.loc;
    if (b.flags) out << " flags=" << hex(b.flags);
    return out; }

#endif /* _TOFINO_MAU_INPUT_XBAR_H_ */
