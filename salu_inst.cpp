#include "instruction.h"
#include "phv.h"
#include "tables.h"
#include "stage.h"

namespace {

struct AluOP : public Instruction {
    const struct Decode : public Instruction::Decode {
        std::string name;
        unsigned opcode;
        const Decode *swap_args;
        Decode(const char *n, unsigned opc, bool assoc = false)
        : Instruction::Decode(n, STATEFUL_ALU), name(n), opcode(opc), swap_args(assoc ? this : 0) {}
        Decode(const char *n, unsigned opc, Decode *sw, const char *alias_name = 0)
        : Instruction::Decode(n, STATEFUL_ALU), name(n), opcode(opc), swap_args(sw) {
            if (sw && !sw->swap_args) sw->swap_args = this;
            if (alias_name) alias(alias_name); }
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    } *opc;
    AluOP(const Decode *op, Table *tbl, const Table::Actions::Action *act, const value_t &d)
    : Instruction(d.lineno), opc(op) {}
    Instruction *pass1(Table *tbl) { return this; }
    void pass2(Table *tbl) { }
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const Phv::Slice &sl)>) { }
    void dbprint(std::ostream &out) const {
        out << "INSTR: " << opc->name /*<< ' ' << dest << ", " << src1 << ", " << src2*/; }
};

static AluOP::Decode opADD("add", 0xc, true), opSUB("sub", 0xe),
                     opSADDU("saddu", 0x0, true), opSADDS("sadds", 0x1, true),
                     opSSUBU("ssubu", 0x2), opSSUBS("ssubs", 0x3),
                     opMINU("minu", 0x4, true), opMINS("mins", 0x5, true),
                     opMAXU("maxu", 0x6, true), opMAXS("maxs", 0x7, true),
                     opSUBR("subr", 0xf, &opSUB),
                     opSSUBRU("ssubru", 0xa, &opSSUBU), opSSUBRS("ssubrs", 0xb, &opSSUBS),

                     opSETZ("setz", 0x10, true), opNOR("nor", 0x11, true),
                     opANDCA("andca", 0x12), opNOTA("nota", 0x13),
                     opANDCB("andcb", 0x14, &opANDCA), opNOTB("notb", 0x15, &opNOTA, "not"),
                     opXOR("xor", 0x16, true), opNAND("nand", 0x17, true),
                     opAND("and", 0x18, true), opXNOR("xnor", 0x19, true),
                     opB("alu_b", 0x1a), opORCA("orca", 0x1b),
                     opA("alu_a", 0x1c, &opB), opORCB("orcb", 0x1d, &opORCA),
                     opOR("or", 0x1e, true), opSETHI("sethi", 0x1f, true);

Instruction *AluOP::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                   const VECTOR(value_t) &op) const {
    AluOP *rv = new AluOP(this, tbl, act, op.data[1]);
    return rv;
}

int AluOP::encode() { return 0; }
bool AluOP::equiv(Instruction *a_) { return false; }

struct BitOP : public Instruction {
    const struct Decode : public Instruction::Decode {
        std::string name;
        unsigned opcode;
        Decode(const char *n, unsigned opc)
        : Instruction::Decode(n, STATEFUL_ALU), name(n), opcode(opc) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    } *opc;
    BitOP(const Decode *op, Table *tbl, const Table::Actions::Action *act, const value_t &d)
    : Instruction(d.lineno), opc(op) {}
    Instruction *pass1(Table *tbl) { return this; }
    void pass2(Table *tbl) { }
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const Phv::Slice &sl)>) { }
    void dbprint(std::ostream &out) const {
        out << "INSTR: " << opc->name /*<< ' ' << dest << ", " << src1 << ", " << src2*/; }
};

static BitOP::Decode opSET_BIT("set_bit", 0x0), opSET_BITC("set_bitc", 0x1),
                     opCLR_BIT("clr_bit", 0x2), opCLR_BITC("clr_bitc", 0x3),
                     opREAD_BIT("read_bit", 0x4), opREAD_BITC("read_bitc", 0x5),
                     opSET_BIT_AT("set_bit_at", 0x6), opSET_BITC_AT("set_bitc_at", 0x7),
                     opCLR_BIT_AT("clr_bit_at", 0x8), opCLR_BITC_AT("clr_bitc_at", 0x9);

Instruction *BitOP::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                   const VECTOR(value_t) &op) const {
    BitOP *rv = new BitOP(this, tbl, act, op.data[1]);
    return rv;
}

int BitOP::encode() { return 0; }
bool BitOP::equiv(Instruction *a_) { return false; }

struct CmpOP : public Instruction {
    const struct Decode : public Instruction::Decode {
        std::string     name;
        unsigned        opcode;
        Decode(const char *n, unsigned opc, bool type)
        : Instruction::Decode(n, STATEFUL_ALU, type), name(n), opcode(opc) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                                    const VECTOR(value_t) &op) const override;
    } *opc;
    CmpOP(const Decode *op, Table *tbl, const Table::Actions::Action *act, const value_t &d)
    : Instruction(d.lineno), opc(op) {}
    Instruction *pass1(Table *tbl) { return this; }
    void pass2(Table *tbl) { }
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const Phv::Slice &sl)>) { }
    void dbprint(std::ostream &out) const {
        out << "INSTR: " << opc->name /*<< ' ' << dest << ", " << src1 << ", " << src2*/; }
};

static CmpOP::Decode opEQU("equ", 0, false), opNEQ("neq", 1, false),
    opGRT("grt", 0, true), opLEQ("leq", 1, true), opGEQ("geq", 2, true), opLSS("lss", 3, true);

Instruction *CmpOP::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                   const VECTOR(value_t) &op) const {
    auto rv = new CmpOP(this, tbl, act, op.data[1]);
    return rv;
}

int CmpOP::encode() { return 0;}
bool CmpOP::equiv(Instruction *a_) { return false;}

}  // end anonymous namespace
