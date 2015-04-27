#ifndef _action_bus_h_
#define _action_bus_h_

#include "tables.h"

class ActionBus {
    struct Slot {
        std::string                 name;
        unsigned                    byte, size;
        Table::Format::Field        *data;
        unsigned                    offset;
    };
    std::map<unsigned, Slot>                        by_byte;
public:
    int             lineno;
    ActionBus() : lineno(-1) {}
    ActionBus(Table *, VECTOR(pair_t) &);
    void pass1(Table *tbl);
    void pass2(Table *tbl);
    void write_immed_regs(Table *tbl);
    void write_action_regs(Table *tbl, unsigned homerow, unsigned action_slice);
    int find(Table::Format::Field *f, int off);
    int find(const char *name, int off, int *size = 0);
    int find(const std::string &name, int off, int *size = 0) {
        return find(name.c_str(), off, size); }
    unsigned size() {
        unsigned rv = 0;
        for (auto &slot : by_byte) rv += slot.second.size;
        return rv; }
};

#endif /* _action_bus_h_ */
