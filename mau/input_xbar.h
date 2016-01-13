#ifndef _TOFINO_MAU_INPUT_XBAR_H_
#define _TOFINO_MAU_INPUT_XBAR_H_

#include "lib/alloc.h"
#include "../ir/tofino.h"

struct IXBar {
    enum {
        EXACT_GROUPS = 8,
        EXACT_BYTES_PER_GROUP = 16,
        HASH_TABLES = 16,
        HASH_GROUPS = 8,
        TERNARY_GROUPS = 16,
        BYTE_GROUPS = 8,
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
     * to record the name of the field it will be getting and the byte offset within the field */
    Alloc2D<std::pair<cstring, int>, EXACT_GROUPS, EXACT_BYTES_PER_GROUP>       exact_use;
    Alloc2D<std::pair<cstring, int>, TERNARY_GROUPS, TERNARY_BYTES_PER_GROUP>   ternary_use;
    Alloc1D<std::pair<cstring, int>, BYTE_GROUPS>                               byte_group_use;
    /* reverse maps of the above, mapping field names to sets of group+byte */
    std::multimap<cstring, Loc>         exact_fields;
    std::multimap<cstring, Loc>         ternary_fields;

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
        void clear() { use.clear(); }
    };

    void clear();
    bool allocTable(bool ternary, const IR::Table *tbl, Use &alloc);
    bool allocGateway(const IR::Expression *gw, Use &alloc);
    bool allocTable(const IR::MAU::Table *tbl, Use &tbl_alloc, Use &gw_alloc);
    void update(const Use &alloc);
    friend std::ostream &operator<<(std::ostream &, const IXBar &);
};

inline std::ostream &operator<<(std::ostream &out, const IXBar::Loc &l) {
    return out << '(' << l.group << ',' << l.byte << ')'; }

inline std::ostream &operator<<(std::ostream &out, const IXBar::Use::Byte &b) {
    return out << b.field << ',' << b.byte << ' ' << b.loc; }

#endif /* _TOFINO_MAU_INPUT_XBAR_H_ */
