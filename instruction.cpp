#include "instruction.h"

struct Idecode {
    static std::map<std::string, Idecode *> opcode;
    Idecode(const char *name) { opcode[name] = this; }
    Idecode &alias(const char *name) {
        opcode[name] = this;
        return *this; }
    virtual Instruction *decode(const VECTOR(value_t) &op) = 0;
};

std::map<std::string, Idecode *> Idecode::opcode;

struct operand {
    enum { INVALID, CONST, REG, SLICE } type;
    std::string         name;
    union {
        long            value;
        struct {
            unsigned    lo, hi;
        };
    };
    operand() : type(INVALID) {}
    operand(const operand &) = default;
    operand(operand &&) = default;
    operand &operator=(const operand &) & = default;
    operand &operator=(operand &&) & = default;
    operand &operator=(const value_t &v) {
        if (v.type == tINT) {
            type = CONST;
            value = v.i;
        } else if (v.type == tSTR) {
            type = REG;
            name = v.s;
        } else if (v.type == tCMD && v.vec.size == 2) {
            type = SLICE;
            name = v[0].s;
            if (v[1].type == tINT) {
                lo = hi = v[1].i;
            } else if (v[1].type == tRANGE) {
                lo = v[1].lo;
                hi = v[1].hi;
            } else
                type = INVALID;
        } else
            type = INVALID;
        return *this; }
    operand(const value_t &v) { *this = v; }
};

struct AluOP : public Instruction {
    struct Decode : public Idecode {
        std::string name;
        unsigned opcode;
        Decode(const char *n, unsigned opc) : Idecode(n), name(n), opcode(opc) {}
        Instruction *decode(const VECTOR(value_t) &op);
    } *opc;
    operand dest, src1, src2;
    AluOP(Decode *d, const value_t *ops) : opc(d), dest(ops[0]), src1(ops[1]), src2(ops[2]) {}
    void encode(Table *fmt);
};

static AluOP::Decode opADD("add", 0x23e), opADDC("addc", 0x2be),
                     opSUB("sub", 0x33e), opSUBC("sub", 0x3be),
                     opSADDU("saddu", 0x03e), opSADDS("sadds", 0x07e),
                     opSSUBU("ssubu", 0x0be), opSSUBS("ssubs", 0x0fe),
                     opMINU("minu", 0x13e), opMINS("mins", 0x17e),
                     opMAXU("maxu", 0x1be), opMAXS("maxs", 0x1fe),
                     opSETZ("setz", 0x01e), opNOR("nor", 0x05e),
                     opANDCA("andca", 0x09e), opNOTA("nota", 0x0de),
                     opANDCB("andcb", 0x11e), opNOTB("notb", 0x15e),
                     opXOR("xor", 0x19e), opNAND("nand", 0x19e),
                     opAND("and", 0x21e), opXNOR("xnor", 0x25e),
                     opB("alu_b", 0x29e), opORCA("orca", 0x29e),
                     opA("alu_a", 0x31e), opORCB("orcb", 0x35e),
                     opOR("or", 0x39e), opSETHI("sethi", 0x39e);

Instruction *AluOP::Decode::decode(const VECTOR(value_t) &op) {
    if (op.size != 4) {
        error(op[0].lineno, "%s requires 3 operands", op[0].s);
        return 0; }
    AluOP *rv = new AluOP(this, op.data + 1);
    if (rv->dest.type != operand::REG)
        error(op[1].lineno, "invalid dest");
    else if (rv->src1.type == operand::INVALID)
        error(op[2].lineno, "invalid src1");
    else if (rv->src2.type == operand::INVALID)
        error(op[3].lineno, "invalid src2");
    else
        return rv;
    delete rv;
    return 0;
}

void AluOP::encode(Table *fmt) {
}

struct DepositField : public Instruction {
    struct Decode : public Idecode {
        Decode(const char *n) : Idecode(n) {}
        Instruction *decode(const VECTOR(value_t) &op);
    };
    operand dest, src1, src2;
    DepositField(const value_t &d, const value_t &s) : dest(d), src1(s), src2(d) {}
    void encode(Table *fmt);
};

static DepositField::Decode opDepositField("deposit_field");

Instruction *DepositField::Decode::decode(const VECTOR(value_t) &op) {
    if (op.size != 4 && op.size != 3) {
        error(op[0].lineno, "%s requires 2 or 3 operands", op[0].s);
        return 0; }
    DepositField *rv = new DepositField(op[1], op[2]);
    if (op.size == 4) rv->src2 = op[3];
    if (rv->dest.type == operand::INVALID)
        error(op[1].lineno, "invalid dest");
    else if (rv->src1.type == operand::INVALID)
        error(op[2].lineno, "invalid src1");
    else if (rv->src2.type == operand::INVALID)
        error(op[3].lineno, "invalid src2");
    else
        return rv;
    delete rv;
    return 0;
}

void DepositField::encode(Table *fmt) {
}

Instruction *Instruction::decode(const VECTOR(value_t) &op) {
    if (auto *d = ::get(Idecode::opcode, op[0].s))
        return d->decode(op);
    else
        error(op[0].lineno, "Unknown instruction %s", op[0].s);
    return 0;
}
