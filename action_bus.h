#ifndef _action_bus_h_
#define _action_bus_h_

#include "tables.h"

class ActionBus {
    static struct MeterBus_t {} MeterBus;
    struct Source {
        enum { None, Field, HashDist, MeterBus }        type;
        union {
            Table::Format::Field                        *field;
            HashDistribution                            *hd;
        };
        Source() : type(None) { field = nullptr; }
        Source(Table::Format::Field *f) : type(Field) { field = f; }
        Source(HashDistribution *h) : type(HashDist) { hd = h; }
        Source(MeterBus_t) : type(MeterBus) { field = nullptr; }
        bool operator==(const Source &a) const { return type == a.type && field == a.field; }
        bool operator<(const Source &a) const {
            return type == a.type ? field < a.field : type < a.type; }
        std::string toString(Table *tbl) const;
    };
    struct Slot {
        std::string                 name;
        unsigned                    byte, size;  // size in bits
        std::map<Source, unsigned>  data;
        // offset in the specified source is in this slot -- corresponding bytes for different
        // action data formats will go into the same slot.
        Slot(std::string n, unsigned b, unsigned s) : name(n), byte(b), size(s) {}
        Slot(std::string n, unsigned b, unsigned s, Source src, unsigned off)
        : name(n), byte(b), size(s) { data.emplace(src, off); }
    };
    std::map<unsigned, Slot>                        by_byte;
    std::map<Source, std::map<unsigned, unsigned>>  need_place;
    // bytes from the given sources are needed on the action bus -- the pairs in the map
    // are (offset,use) where offset is offset in bits, and use is a bitset of the needed
    // uses (bit index == log2 of the access size in bytes)
    int find_merge(int offset, int bytes, int use);
public:
    int             lineno;
    ActionBus() : lineno(-1) {}
    ActionBus(Table *, VECTOR(pair_t) &);
    void pass1(Table *tbl);
    void pass2(Table *tbl);
    template<class REGS> void write_immed_regs(REGS &regs, Table *tbl);
    template<class REGS>
    void write_action_regs(REGS &regs, Table *tbl, unsigned homerow, unsigned action_slice);
    int find(Table::Format::Field *f, int off, int size);
    void do_alloc(Table *tbl, Source src, unsigned use, int lobyte, int bytes, unsigned offset);
    void alloc_field(Table *, Source src, unsigned offset, unsigned sizes_needed);
    void need_alloc(Table *tbl, Table::Format::Field *f, unsigned off, unsigned size);
    void need_alloc(Table *tbl, HashDistribution *hd, unsigned off, unsigned size);
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
