#ifndef _action_bus_h_
#define _action_bus_h_

#include <array>
#include "tables.h"

class ActionBus {
    static struct MeterBus_t {} MeterBus;
    struct Source {
        enum { None, Field, HashDist, TableOutput, TableRefOutput }     type;
        union {
            Table::Format::Field                        *field;
            HashDistribution                            *hd;
            Table                                       *table;
            Table::Ref                                  *table_ref;
        };
        Source() : type(None) { field = nullptr; }
        Source(Table::Format::Field *f) : type(Field) { field = f; }
        Source(HashDistribution *h) : type(HashDist) { hd = h; }
        Source(Table *t) : type(TableOutput) { table = t; }
        Source(Table::Ref *t) : type(TableRefOutput) { table_ref = t; }
        Source(MeterBus_t) : type(TableRefOutput) { table_ref = nullptr; }
        bool operator==(const Source &a) const {
            return type == a.type && field == a.field; }
        bool operator<(const Source &a) const {
            return type == a.type ? field < a.field : type < a.type; }
        std::string toString(Table *tbl) const;
    };
    // Check two Source refs to ensure that they are compatible (can be at the same
    // location on the aciton bus -- basically the same data)
    static bool compatible(const Source &a, unsigned a_off, const Source &b, unsigned b_off);
    struct Slot {
        std::string                 name;
        unsigned                    byte, size;  // size in bits
        std::map<Source, unsigned>  data;
        // offset in the specified source is in this slot -- corresponding bytes for different
        // action data formats will go into the same slot.
        Slot(std::string n, unsigned b, unsigned s) : name(n), byte(b), size(s) {}
        Slot(std::string n, unsigned b, unsigned s, Source src, unsigned off)
        : name(n), byte(b), size(s) { data.emplace(src, off); }
        unsigned lo(Table *tbl) const;  // low bit on the action data bus
        bool is_table_output() const {
            for (auto &d : data)
                if (d.first.type == Source::TableOutput || d.first.type == Source::TableRefOutput)
                    return true;
            return false; }
    };
    friend std::ostream &operator<<(std::ostream &, const Source &);
    friend std::ostream &operator<<(std::ostream &, const Slot &);
    friend std::ostream &operator<<(std::ostream &, const ActionBus &);
    std::map<unsigned, Slot>                        by_byte;
    std::map<Source, std::map<unsigned, unsigned>>  need_place;
    // bytes from the given sources are needed on the action bus -- the pairs in the map
    // are (offset,use) where offset is offset in bits, and use is a bitset of the needed
    // uses (bit index == log2 of the access size in bytes)

    std::vector<std::array<unsigned, ACTION_HV_XBAR_SLICES>>    action_hv_slice_use;
    // which bytes of input to the ixbar are used in each action_hv_xbar slice, for each
    // 128-bit slice of the action bus.
    bitvec      byte_use;  // bytes on the action data (input) bus or immediate bus in use
                           // for wide action tables, this may be >16 bytes...

    int find_free(Table *tbl, int min, int max, int step, int lobyte, int bytes);
    int find_merge(Table *tbl, int offset, int bytes, int use);
public:
    int             lineno;
    ActionBus() : lineno(-1) {}
    ActionBus(Table *, VECTOR(pair_t) &);
    void pass1(Table *tbl);
    void pass2(Table *tbl);
    template<class REGS> void write_immed_regs(REGS &regs, Table *tbl);
    template<class REGS>
    void write_action_regs(REGS &regs, Table *tbl, unsigned homerow, unsigned action_slice);
    void do_alloc(Table *tbl, Source src, unsigned use, int lobyte, int bytes, unsigned offset);
    void alloc_field(Table *, Source src, unsigned offset, unsigned sizes_needed);
    void need_alloc(Table *tbl, Table::Format::Field *f, unsigned off, unsigned size);
    void need_alloc(Table *tbl, HashDistribution *hd, unsigned off, unsigned size);
    void need_alloc(Table *tbl, Table *attached, unsigned off, unsigned size);
    int find(Table::Format::Field *f, int off, int size);
    int find(const char *name, int off, int size, int *len = 0);
    int find(const std::string &name, int off, int size, int *len = 0) {
        return find(name.c_str(), off, size, len); }
    int find(HashDistribution *hd, int off, int size);
    unsigned size() {
        unsigned rv = 0;
        for (auto &slot : by_byte) rv += slot.second.size;
        return rv; }
};

#endif /* _action_bus_h_ */
