#include "instruction.h"
#include "phv.h"
#include "tables.h"

struct Idecode {
    static std::map<std::string, Idecode *> opcode;
    Idecode(const char *name) { opcode[name] = this; }
    Idecode &alias(const char *name) {
        opcode[name] = this;
        return *this; }
    virtual Instruction *decode(Table *tbl, const VECTOR(value_t) &op) = 0;
};

std::map<std::string, Idecode *> Idecode::opcode;

class operand {
private:
    struct Base {
	virtual ~Base() {}
	virtual Base *clone() = 0;
    } *op;
    struct Const : public Base {
	long		value;
	Const(long v) : value(v) {}
	virtual Const *clone() { return new Const(*this); }
    };
    struct Phv : public Base {
	::Phv::Ref	reg;
	Phv(gress_t g, const value_t &n) : reg(g, n) {}
	virtual Phv *clone() { return new Phv(*this); }
    };
    struct Action : public Base {
	std::string		name;
	Table::Format::Field	*field;
	Action(const std::string &n, Table::Format::Field *f) : name(n), field(f) {}
	virtual Action *clone() { return new Action(*this); }
    };
public:
    operand() : op(0) {}
    operand(long v) : op(new Const(v)) {}
    operand(gress_t g, const value_t &n) : op(new Phv(g, n)) {}
    operand(const std::string &n, Table::Format::Field *f) : op(new Action(n, f)) {}
    operand(const operand &a) : op(a.op ? a.op->clone() : 0) {}
    operand(operand &&a) : op(a.op) { a.op = 0; }
    ~operand() { delete op; }
    operand(Table *tbl, const value_t &v);
    bool valid() const { return op != 0; }
};

operand::operand(Table *tbl, const value_t &v) : op(0) {
    if (v.type == tINT) {
	op = new Const(v.i);
    } else if (CHECKTYPE2(v, tSTR, tCMD)) {
	const std::string &n = v.type == tSTR ? v.s : v[0].s;
	if (auto *field = tbl->format ? tbl->format->field(n) : 0) {
	    op = new Action(n, field);
	} else
	    op = new Phv(tbl->gress, v); }
}

struct AluOP : public Instruction {
    struct Decode : public Idecode {
        std::string name;
        unsigned opcode;
        Decode(const char *n, unsigned opc) : Idecode(n), name(n), opcode(opc) {}
        Instruction *decode(Table *tbl, const VECTOR(value_t) &op);
    } *opc;
    operand dest, src1, src2;
    AluOP(Decode *d, Table *tbl, const value_t *ops) : opc(d), dest(tbl, ops[0]),
		    src1(tbl, ops[1]), src2(tbl, ops[2]) {}
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

Instruction *AluOP::Decode::decode(Table *tbl, const VECTOR(value_t) &op) {
    if (op.size != 4) {
        error(op[0].lineno, "%s requires 3 operands", op[0].s);
        return 0; }
    AluOP *rv = new AluOP(this, tbl, op.data + 1);
    if (!rv->dest.valid())
        error(op[1].lineno, "invalid dest");
    else if (!rv->src1.valid())
        error(op[2].lineno, "invalid src1");
    else if (!rv->src2.valid())
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
        Instruction *decode(Table *tbl, const VECTOR(value_t) &op);
    };
    operand dest, src1, src2;
    DepositField(Table *tbl, const value_t &d, const value_t &s)
	: dest(tbl, d), src1(tbl, s), src2(tbl, d) {}
    DepositField(Table *tbl, const value_t &d, const value_t &s1, const value_t &s2)
	: dest(tbl, d), src1(tbl, s1), src2(tbl, s2) {}
    void encode(Table *fmt);
};

static DepositField::Decode opDepositField("deposit_field");

Instruction *DepositField::Decode::decode(Table *tbl, const VECTOR(value_t) &op) {
    if (op.size != 4 && op.size != 3) {
        error(op[0].lineno, "%s requires 2 or 3 operands", op[0].s);
        return 0; }
    DepositField *rv;
    if (op.size == 4)
	rv = new DepositField(tbl, op[1], op[2], op[3]);
    else
	rv = new DepositField(tbl, op[1], op[2]);
    if (!rv->dest.valid())
        error(op[1].lineno, "invalid dest");
    else if (!rv->src1.valid())
        error(op[2].lineno, "invalid src1");
    else if (!rv->src2.valid())
        error(op[3].lineno, "invalid src2");
    else
        return rv;
    delete rv;
    return 0;
}

void DepositField::encode(Table *fmt) {
}

Instruction *Instruction::decode(Table *tbl, const VECTOR(value_t) &op) {
    if (auto *d = ::get(Idecode::opcode, op[0].s))
        return d->decode(tbl, op);
    else
        error(op[0].lineno, "Unknown instruction %s", op[0].s);
    return 0;
}
