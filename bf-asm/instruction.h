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
    virtual bool salu_output() const { return false; }
    virtual void phvRead(std::function<void (const Phv::Slice &sl)>) = 0;
#define VIRTUAL_TARGET_METHODS(TARGET) \
    virtual void write_regs(Target::TARGET::mau_regs &, Table *, Table::Actions::Action *) = 0;
    FOR_ALL_REGISTER_SETS(VIRTUAL_TARGET_METHODS)
#undef VIRTUAL_TARGET_METHODS
#define DECLARE_FORWARD_VIRTUAL_INSTRUCTION_WRITE_REGS(TARGET)                          \
    void write_regs(Target::TARGET::mau_regs &regs, Table *tbl,                         \
                    Table::Actions::Action *act) override;
    static Instruction *decode(Table *, const Table::Actions::Action *, const VECTOR(value_t) &);

    enum instruction_set_t { VLIW_ALU=0, STATEFUL_ALU=1, NUM_SETS=2 };
    struct Decode {
        static std::multimap<std::string, Decode *> opcode[NUM_SETS];
        bool            type_suffix;
        unsigned        targets;
        Decode(const char *name, int set = VLIW_ALU, bool ts = false);
        Decode(const char *name, target_t target, int set = VLIW_ALU, bool ts = false);
        const Decode &alias(const char *name, int set = VLIW_ALU, bool ts = false) {
            opcode[set].emplace(name, this);
            return *this; }
        virtual Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                                    const VECTOR(value_t) &op) const = 0;
    };
};

#endif /* _instruction_h_ */
