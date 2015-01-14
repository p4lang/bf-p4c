#include "instruction.h"
#include "phv.h"
#include "tables.h"
#include "stage.h"

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
        int     lineno;
        Base(int line) : lineno(line) {}
        Base(const Base &a) : lineno(a.lineno) {}
	virtual ~Base() {}
	virtual Base *clone() = 0;
        virtual bool check() { return true; }
        virtual int phvGroup() { return -1; }
        virtual ::Phv::Slice *slice() { return 0; }
        virtual int bits(int group) = 0;
        virtual void mark_use(Table *tbl) {}
    } *op;
    struct Const : public Base {
	long		value;
	Const(int line, long v) : Base(line), value(v) {}
	virtual Const *clone() { return new Const(*this); }
        int bits(int group) {
            if (value >= -16 || value < 16)
                return value+48;
            error(lineno, "constant value %ld out of range for immediate", value);
            return -1; }
    };
    struct Phv : public Base {
	::Phv::Ref	reg;
        ::Phv::Slice    sl;
	Phv(int line, gress_t g, const value_t &n) : Base(line), reg(g, n) {}
	virtual Phv *clone() { return new Phv(*this); }
        bool check() { return reg.check(); }
        int phvGroup() { return reg->reg.index / 32; }
        ::Phv::Slice *slice() { sl = *reg; return &sl; }
        int bits(int group) {
            if (group != phvGroup()) {
                error(lineno, "registers in an instruction must all be in the same phv group");
                return -1; }
            return reg->reg.index % 32; }
        virtual void mark_use(Table *tbl) {
            tbl->stage->phv_use[tbl->gress][reg->reg.index] = true; }
    };
    struct Action : public Base {
	std::string		name;
	Table::Format::Field	*field;
	Action(int line, const std::string &n, Table::Format::Field *f) :
            Base(line), name(n), field(f) {}
	virtual Action *clone() { return new Action(*this); }
        int bits(int group) { 
            if (field->action_xbar < 0)
                error(lineno, "%s is not on the action bus", name.c_str());
            else switch (group) {
            case 0: case 1:
                if (field->action_xbar >= 160)
                    error(lineno, "action bus entry %d(%s) out of range for 32-bit access",
                          field->action_xbar, name.c_str());
                else if (field->action_xbar&3)
                    error(lineno, "action bus entry %d(%s) misaligned for 32-bit access",
                          field->action_xbar, name.c_str());
                else
                    return 0x40 + field->action_xbar / 4;
                break;
            case 2: case 3:
                if (field->action_xbar >= 40)
                    error(lineno, "action bus entry %d(%s) out of range for 8-bit access",
                          field->action_xbar, name.c_str());
                else
                    return 0x40 + field->action_xbar;
                break;
            case 4: case 5: case 6:
                if (field->action_xbar < 40 || field->action_xbar >= 120)
                    error(lineno, "action bus entry %d(%s) out of range for 16-bit access",
                          field->action_xbar, name.c_str());
                else if (field->action_xbar&1)
                    error(lineno, "action bus entry %d(%s) misaligned for 16-bit access",
                          field->action_xbar, name.c_str());
                else
                    return 0x40 + (field->action_xbar / 2) - 20;
                break;
            default:
                assert(0);
                break; }
            return -1; }
    };
public:
    operand() : op(0) {}
#if 0
    operand(long v) : op(new Const(v)) {}
    operand(gress_t g, const value_t &n) : op(new Phv(g, n)) {}
    operand(const std::string &n, Table::Format::Field *f) : op(new Action(n, f)) {}
#endif
    operand(const operand &a) : op(a.op ? a.op->clone() : 0) {}
    operand(operand &&a) : op(a.op) { a.op = 0; }
    operand &operator=(const operand &a) {
        if (&a != this) {
            delete op;
            op = a.op ? a.op->clone() : 0; }
        return *this; }
    operand &operator=(operand &&a) {
        if (&a != this) {
            delete op;
            op = a.op;
            a.op = 0; }
        return *this; }
    ~operand() { delete op; }
    operand(Table *tbl, const value_t &v);
    bool valid() const { return op != 0; }
    bool check() const { return op->check(); }
    int phvGroup() const { return op->phvGroup(); }
    ::Phv::Slice *slice() { return op->slice(); }
    int bits(int group) const { return op->bits(group); }
    void mark_use(Table *tbl) const { op->mark_use(tbl); }
};

operand::operand(Table *tbl, const value_t &v) : op(0) {
    if (v.type == tINT) {
	op = new Const(v.lineno, v.i);
    } else if (CHECKTYPE2(v, tSTR, tCMD)) {
	const std::string &n = v.type == tSTR ? v.s : v[0].s;
	if (auto *field = tbl->format ? tbl->format->field(n) : 0) {
	    op = new Action(v.lineno, n, field);
	} else
	    op = new Phv(v.lineno, tbl->gress, v); }
}

struct AluOP : public Instruction {
    struct Decode : public Idecode {
        std::string name;
        unsigned opcode;
        Decode *swap_args;
        Decode(const char *n, unsigned opc, bool assoc = false) : Idecode(n), name(n),
            opcode(opc), swap_args(assoc ? this : 0) {}
        Decode(const char *n, unsigned opc, Decode *sw) : Idecode(n), name(n), opcode(opc),
            swap_args(sw) { if (!sw->swap_args) sw->swap_args = this; }
        Instruction *decode(Table *tbl, const VECTOR(value_t) &op);
    } *opc;
    Phv::Ref    dest;
    operand     src1, src2;
    AluOP(Decode *d, Table *tbl, const value_t *ops) : Instruction(ops->lineno), opc(d),
            dest(tbl->gress, ops[0]), src1(tbl, ops[1]), src2(tbl, ops[2]) {}
    void encode(Table *tbl);
};

static AluOP::Decode opADD("add", 0x23e, true), opADDC("addc", 0x2be, true),
                     opSUB("sub", 0x33e), opSUBC("sub", 0x3be),
                     opSADDU("saddu", 0x03e), opSADDS("sadds", 0x07e),
                     opSSUBU("ssubu", 0x0be), opSSUBS("ssubs", 0x0fe),
                     opMINU("minu", 0x13e, true), opMINS("mins", 0x17e, true),
                     opMAXU("maxu", 0x1be, true), opMAXS("maxs", 0x1fe, true),
                     opSETZ("setz", 0x01e, true), opNOR("nor", 0x05e, true),
                     opANDCA("andca", 0x09e), opNOTA("nota", 0x0de),
                     opANDCB("andcb", 0x11e, &opANDCA), opNOTB("notb", 0x15e, &opNOTA),
                     opXOR("xor", 0x19e, true), opNAND("nand", 0x19e, true),
                     opAND("and", 0x21e, true), opXNOR("xnor", 0x25e, true),
                     opB("alu_b", 0x29e), opORCA("orca", 0x29e),
                     opA("alu_a", 0x31e, &opA), opORCB("orcb", 0x35e, &opORCA),
                     opOR("or", 0x39e, true), opSETHI("sethi", 0x39e, true);

Instruction *AluOP::Decode::decode(Table *tbl, const VECTOR(value_t) &op) {
    if (op.size != 4) {
        error(op[0].lineno, "%s requires 3 operands", op[0].s);
        return 0; }
    AluOP *rv = new AluOP(this, tbl, op.data + 1);
    if (!rv->src1.valid())
        error(op[2].lineno, "invalid src1");
    else if (!rv->src2.valid())
        error(op[3].lineno, "invalid src2");
    else
        return rv;
    delete rv;
    return 0;
}

void AluOP::encode(Table *tbl) {
    if (!dest.check() || !src1.check() || !src2.check()) return;
    if (dest->lo || dest->hi != dest->reg.size-1) {
        error(lineno, "ALU ops cannot operate on slices");
        return; }
    slot = dest->reg.index;
    tbl->stage->phv_use[tbl->gress][slot] = true;
    src1.mark_use(tbl);
    src2.mark_use(tbl);
    int grp = src2.phvGroup();
    if (grp < 0 && opc->swap_args) {
        std::swap(src1, src2);
        opc = opc->swap_args;
        grp = src2.phvGroup(); }
    if (grp < 0) {
        error(lineno, "src2 must be phv register");
        return; }
    bits = (opc->opcode << 12) | (src1.bits(slot/32) << 5) | src2.bits(slot/32);
}

struct DepositField : public Instruction {
    struct Decode : public Idecode {
        Decode(const char *n) : Idecode(n) {}
        Instruction *decode(Table *tbl, const VECTOR(value_t) &op);
    };
    Phv::Ref    dest;
    operand     src1, src2;
    DepositField(Table *tbl, const value_t &d, const value_t &s)
	: Instruction(d.lineno), dest(tbl->gress, d), src1(tbl, s), src2(tbl, d) {}
    DepositField(Table *tbl, const value_t &d, const value_t &s1, const value_t &s2)
	: Instruction(d.lineno), dest(tbl->gress, d), src1(tbl, s1), src2(tbl, s2) {}
    void encode(Table *tbl);
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
    if (!rv->src1.valid())
        error(op[2].lineno, "invalid src1");
    else if (!rv->src2.valid())
        error(op[3].lineno, "invalid src2");
    else
        return rv;
    delete rv;
    return 0;
}

void DepositField::encode(Table *tbl) {
    if (!dest.check() || !src1.check() || !src2.check()) return;
    slot = dest->reg.index;
    tbl->stage->phv_use[tbl->gress][slot] = true;
    src1.mark_use(tbl);
    src2.mark_use(tbl);
    Phv::Slice *s1 = src1.slice();
    int rot = dest->reg.size - dest->lo;
    if (s1)
        rot = (rot + s1->lo) % dest->reg.size;
    bits = (1 << 12) | (src1.bits(slot/32) << 5) | src2.bits(slot/32);
    bits |= dest->hi << 13;
    bits |= rot << 18;
    switch (slot/32) {
    case 0: case 1:
        bits |= dest->lo << 23;
        break;
    case 2: case 3:
        bits |= (dest->lo & 3) << 16;
        bits |= (dest->lo & ~3) << 19;
        break;
    case 4: case 5: case 6:
        bits |= (dest->lo & 1) << 17;
        bits |= (dest->lo & ~1) << 21;
        break;
    default:
        assert(0); }
}

struct Invalidate : public Instruction {
    struct Decode : public Idecode {
        Decode(const char *n) : Idecode(n) {}
        Instruction *decode(Table *tbl, const VECTOR(value_t) &op);
    };
    Phv::Ref    dest;
    Invalidate(Table *tbl, const value_t &d) : Instruction(d.lineno), dest(tbl->gress, d) {}
    void encode(Table *tbl);
};

static Invalidate::Decode opInvalidate("invalidate");

Instruction *Invalidate::Decode::decode(Table *tbl, const VECTOR(value_t) &op) {
    if (op.size != 2) {
        error(op[0].lineno, "%s requires 1 operand", op[0].s);
        return 0; }
    return new Invalidate(tbl, op[1]);
}

void Invalidate::encode(Table *tbl) {
    if (!dest.check()) return;
    slot = dest->reg.index;
    tbl->stage->phv_use[tbl->gress][slot] = true;
    bits = 0xe000;
}

Instruction *Instruction::decode(Table *tbl, const VECTOR(value_t) &op) {
    if (auto *d = ::get(Idecode::opcode, op[0].s))
        return d->decode(tbl, op);
    else
        error(op[0].lineno, "Unknown instruction %s", op[0].s);
    return 0;
}
