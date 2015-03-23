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
    void set_immed_offsets(Table *tbl);
    void set_action_offsets(Table *tbl);
    void write_immed_regs(Table *tbl);
    void write_action_regs(Table *tbl, unsigned homerow, unsigned action_slice);
};

#endif /* _action_bus_h_ */
