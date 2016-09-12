#ifndef _action_bus_h_
#define _action_bus_h_

#include "tables.h"

class ActionBus {
    struct Slot {
        std::string                 name;
        unsigned                    byte, size;  // size in bits
        Table::Format::Field        *data;
        unsigned                    offset;      // offset in bits
    };
    std::map<unsigned, Slot>                        by_byte;
    std::map<Table::Format::Field *, std::map<unsigned, unsigned>>      need_place;
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
    void do_alloc(Table *tbl, Table::Format::Field *f, unsigned use, int bytes, unsigned offset);
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
