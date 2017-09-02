#ifndef _instruction_h_
#define _instruction_h_

#include <config.h>

#include <functional>
#include "tables.h"

struct Instruction {
    int         lineno;
    int         slot;
    Instruction(int l) : lineno(l), slot(-1) {}
    virtual ~Instruction() {}
    virtual Instruction *pass1(Table *, Table::Actions::Action *) = 0;
    virtual std::string name() = 0;
    virtual void pass2(Table *, Table::Actions::Action *) = 0;
    virtual void dbprint(std::ostream &) const = 0;
    virtual bool equiv(Instruction *a) = 0;
    virtual void phvRead(std::function<void (const Phv::Slice &sl)>) = 0;
    virtual void write_regs(Target::Tofino::mau_regs &, Table *, Table::Actions::Action *) = 0;
#if HAVE_JBAY
    virtual void write_regs(Target::JBay::mau_regs &, Table *, Table::Actions::Action *) = 0;
#endif // HAVE_JBAY
    static Instruction *decode(Table *, const Table::Actions::Action *, const VECTOR(value_t) &);

    enum instruction_set_t { VLIW_ALU=0, STATEFUL_ALU=1, NUM_SETS=2 };
    struct Decode {
        static std::map<std::string, const Decode *> opcode[NUM_SETS];
        bool    type_suffix;
        Decode(const char *name, int set = VLIW_ALU, bool ts = false) : type_suffix(ts) {
            opcode[set][name] = this; }
        const Decode &alias(const char *name, int set = VLIW_ALU, bool ts = false) const {
            opcode[set][name] = this;
            return *this; }
        virtual Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                                    const VECTOR(value_t) &op) const = 0;
    };
};

#endif /* _instruction_h_ */
