#ifndef _action_bus_h_
#define _action_bus_h_

#include "tables.h"

class ActionBus {
    struct Slot {
        std::string                 name;
        unsigned                    byte, size;  // size in bits
        std::map<Table::Format::Field *, unsigned>
                                    data;
        // offset in the specified field is in this slot -- corresponding bytes for different
        // action data formats will go into the same slot.
    };
    std::map<unsigned, Slot>                        by_byte;
    std::map<Table::Format::Field *, std::map<unsigned, unsigned>>      need_place;
    // bytes from the given fields are needed on the action bus -- the pairs in the map
    // are (offset,use) where offset is offset in bits, and use is a bitset of the needed
    // uses (bit index == log2 of the access size)
    int find_merge(int offset, int bytes);
public:
    int             lineno;
    ActionBus() : lineno(-1) {}
    ActionBus(Table *, VECTOR(pair_t) &);
    void pass1(Table *tbl);
    void pass2(Table *tbl);
    void write_immed_regs(Table *tbl);
    void write_action_regs(Table *tbl, unsigned homerow, unsigned action_slice);
    int find(Table::Format::Field *f, int off, int size);
    void do_alloc(Table *tbl, Table::Format::Field *f, unsigned use, int lobyte,
                  int bytes, unsigned offset);
    void need_alloc(Table *tbl, Table::Format::Field *f, unsigned off, unsigned size);
    int find(const char *name, int off, int size, int *len = 0);
    int find(const std::string &name, int off, int size, int *len = 0) {
        return find(name.c_str(), off, size, len); }
    unsigned size() {
        unsigned rv = 0;
        for (auto &slot : by_byte) rv += slot.second.size;
        return rv; }
};

#endif /* _action_bus_h_ */
