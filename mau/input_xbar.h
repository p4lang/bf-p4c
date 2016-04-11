#ifndef _TOFINO_MAU_INPUT_XBAR_H_
#define _TOFINO_MAU_INPUT_XBAR_H_

#include "lib/alloc.h"
#include "ir/ir.h"

class PhvInfo;

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
     * to record the name of the field it will be getting and the byte offset within the field.
     * cstrings here are field names as used in PhvInfo (so PhvInfo::field can be used to find
     * out details about the field) */
    Alloc2D<std::pair<cstring, int>, EXACT_GROUPS, EXACT_BYTES_PER_GROUP>       exact_use;
    Alloc2D<std::pair<cstring, int>, TERNARY_GROUPS, TERNARY_BYTES_PER_GROUP>   ternary_use;
    Alloc1D<std::pair<cstring, int>, BYTE_GROUPS>                               byte_group_use;
    /* reverse maps of the above, mapping field names to sets of group+byte */
    std::multimap<cstring, Loc>         exact_fields;
    std::multimap<cstring, Loc>         ternary_fields;

    /* Track the use of hashtables/groups too -- FIXME -- should it be a separate data structure? */
    Alloc2D<cstring, HASH_TABLES, HASH_INDEX_GROUPS>    hash_index_use;
    unsigned                                    hash_index_inuse[HASH_INDEX_GROUPS] = { 0 };
    Alloc2D<cstring, HASH_TABLES, HASH_SINGLE_BITS>     hash_single_bit_use;
    unsigned                                    hash_single_bit_inuse[HASH_SINGLE_BITS] = { 0 };
    Alloc1D<cstring, HASH_GROUPS>                       hash_group_use;

 public:
    /* IXbar::Use tracks the input xbar use of a single table */
    struct Use {
        bool            ternary;
        struct Byte {
            cstring     field;
            int         byte;
            Loc         loc;
            Byte(cstring f, int b) : field(f), byte(b) {}
            Byte(cstring f, int b, int g, int gb) : field(f), byte(b), loc(g, gb) {}
            operator std::pair<cstring, int>() const { return std::make_pair(field, byte); }
            bool operator==(const std::pair<cstring, int> &a) const {
                return field == a.first && byte == a.second; }
        };
        vector<Byte>    use;
        unsigned        hash_table_input = 0;
        struct Way {
            int         group, slice;
            unsigned    mask;
            Way() = delete;
            Way(int g, int s, unsigned m) : group(g), slice(s), mask(m) {}
        };
        vector<Way>     way_use;
        void clear() { use.clear(); hash_table_input = 0; way_use.clear(); }
        void compute_hash_tables();
        int groups() const;  // how many different groups in this use
    };

    void clear();
    bool allocTable(bool ternary, const IR::V1Table *tbl, const PhvInfo &phv, Use &alloc);
    bool allocHashWay(const IR::MAU::Table *, const IR::MAU::Table::Way &, Use &);
    bool allocGateway(const IR::Expression *gw, const PhvInfo &phv, Use &alloc);
    bool allocTable(const IR::MAU::Table *tbl, const PhvInfo &phv, Use &tbl_alloc, Use &gw_alloc);
    void update(const Use &alloc);
    friend std::ostream &operator<<(std::ostream &, const IXBar &);
};

inline std::ostream &operator<<(std::ostream &out, const IXBar::Loc &l) {
    return out << '(' << l.group << ',' << l.byte << ')'; }

inline std::ostream &operator<<(std::ostream &out, const IXBar::Use::Byte &b) {
    return out << b.field << ',' << b.byte << ' ' << b.loc; }

#endif /* _TOFINO_MAU_INPUT_XBAR_H_ */
