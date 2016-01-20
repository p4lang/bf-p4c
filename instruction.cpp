#include "action_bus.h"
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
    virtual Instruction *decode(Table *tbl, const std::string &act, const VECTOR(value_t) &op) = 0;
};

std::map<std::string, Idecode *> Idecode::opcode;

static const int group_size[] = { 32, 32, 32, 32, 8, 8, 8, 8, 16, 16, 16, 16, 16, 16 };

class operand {
private:
    class Base {
    protected:
        int     lineno;
    public:
        Base(int line) : lineno(line) {}
        Base(const Base &a) : lineno(a.lineno) {}
	virtual ~Base() {}
	virtual Base *clone() = 0;
        virtual Base *lookup(Base *&ref) { return this; }
        virtual bool check() { return true; }
        virtual int phvGroup() { return -1; }
        virtual int bits(int group) = 0;
        virtual unsigned bitoffset(int group) const { return 0; }
        virtual void mark_use(Table *tbl) {}
        virtual void dbprint(std::ostream &) const = 0;
	virtual bool equiv(const Base *) const = 0;
        virtual void phvRead(std::function<void (const ::Phv::Slice &sl)>) {}
        virtual void pass2(Table *, int) const {}
    } *op;
    class Const : public Base {
	long		value;
    public:
	Const(int line, long v) : Base(line), value(v) {}
	bool equiv(const Base *a_) const {
	    if (auto *a = dynamic_cast<const Const *>(a_)) {
		return value == a->value;
	    } else return false; }
    private:
	virtual Const *clone() { return new Const(*this); }
        int bits(int group) {
            if (value >= -8 || value < 8)
                return value+24;
            error(lineno, "constant value %ld out of range for immediate", value);
            return -1; }
        virtual void dbprint(std::ostream &out) const { out << value; }
    };
    class Phv : public Base {
	::Phv::Ref	reg;
    public:
	Phv(int line, gress_t g, const value_t &n) : Base(line), reg(g, n) {}
	Phv(int line, gress_t g, const std::string &n, int l, int h) :
            Base(line), reg(g, line, n, l, h) {}
        Phv(const ::Phv::Ref &r) : Base(r.lineno), reg(r) {}
	bool equiv(const Base *a_) const {
	    if (auto *a = dynamic_cast<const Phv *>(a_)) {
		return reg == a->reg;
	    } else return false; }
    private:
	virtual Phv *clone() { return new Phv(*this); }
        bool check() { return reg.check(); }
        int phvGroup() { return reg->reg.index / 16; }
        int bits(int group) {
            if (group != phvGroup()) {
                error(lineno, "registers in an instruction must all be in the same phv group");
                return -1; }
            return reg->reg.index % 16; }
        virtual unsigned bitoffset(int group) const { return reg->lo; }
        virtual void mark_use(Table *tbl) {
            tbl->stage->action_use[tbl->gress][reg->reg.index] = true; }
        virtual void dbprint(std::ostream &out) const { out << reg; }
        void phvRead(std::function<void (const ::Phv::Slice &sl)> fn) override { fn(*reg); }
    };
    class Action : public Base {
	std::string		name;
        Table                   *table;
	Table::Format::Field	*field;
        unsigned                lo, hi;
    public:
	Action(int line, const std::string &n, Table *tbl, Table::Format::Field *f,
               unsigned l, unsigned h) : Base(line), name(n), table(tbl), field(f), lo(l), hi(h) {}
	bool equiv(const Base *a_) const {
	    if (auto *a = dynamic_cast<const Action *>(a_)) {
		return name == a->name && table == a->table && field == a->field &&
		       lo == a->lo && hi == a->hi;
	    } else return false; }
    private:
	virtual Action *clone() { return new Action(*this); }
        int bits(int group) { 
            int size = group_size[group]/8U;
            int byte = field ? table->find_on_actionbus(field, lo, size)
                             : table->find_on_actionbus(name, lo, size);
            if (byte < 0) {
		if (lo > 0 || (field && hi+1 < field->size))
		    error(lineno, "%s(%d..%d) is not on the action bus", name.c_str(), lo, hi);
		else
		    error(lineno, "%s is not on the action bus", name.c_str());
                return -1; }
            int byte_value = byte;
            if (size == 2) byte -= 32;
            if (byte < 0 || byte > 32*size)
                error(lineno, "action bus entry %d(%s) out of range for %d-bit access",
                      byte_value, name.c_str(), size*8);
            //else if (byte % size != 0) 
            //    error(lineno, "action bus entry %d(%s) misaligned for %d-bit access",
            //          byte_value, name.c_str(), size*8);
            else
                return 0x20 + byte/size;
            return -1; }
        virtual void pass2(Table *, int group) const {
            int size = group_size[group]/8U;
            if (field && table->find_on_actionbus(field, lo, size) < 0) 
                table->need_on_actionbus(field, lo, size); }
        virtual void mark_use(Table *tbl) {
            if (field) field->flags |= Table::Format::Field::USED_IMMED; }
        virtual unsigned bitoffset(int group) const {
            int size = group_size[group]/8U;
            int byte = field ? table->find_on_actionbus(field, lo, size)
                             : table->find_on_actionbus(name, lo, size);
            return 8*(byte % size) + lo % 8; }
        virtual void dbprint(std::ostream &out) const {
            out << name << '(' << lo << ".." << hi << ')';
            if (field)
                out << '[' << field->bits[0].lo << ':' << field->size << ", "
                    << field->group << ']'; }
    };
    class RawAction : public Base {
        int             index;
        unsigned        offset;
    public:
        RawAction(int line, int idx, unsigned off) : Base(line), index(idx), offset(off) {}
	bool equiv(const Base *a_) const {
	    if (auto *a = dynamic_cast<const RawAction *>(a_)) {
		return index == a->index && offset == a->offset;
	    } else return false; }
    private:
	virtual RawAction *clone() { return new RawAction(*this); }
        int bits(int group) { return 0x40 + index; }
        virtual unsigned bitoffset(int group) const { return offset; }
        void dbprint(std::ostream &out) const { out << 'A' << index; }
    };
    class Named : public Base {
        std::string     name;
        int             lo, hi;
        Table           *tbl;
        std::string     action;
    public:
        Named(int line, const std::string &n, int l, int h, Table *t, const std::string &act) :
            Base(line), name(n), lo(l), hi(h), tbl(t), action(act) {}
	bool equiv(const Base *a_) const {
	    if (auto *a = dynamic_cast<const Named *>(a_)) {
		return name == a->name && lo == a->lo && hi == a->hi && tbl == a->tbl &&
		       action == a->action;
	    } else return false; }
    private:
        Base *lookup(Base *&ref);
	Named *clone() { return new Named(*this); }
        bool check() { assert(0); return true; }
        int phvGroup() { assert(0); return -1; }
        int bits(int group) { assert(0); return 0; }
        unsigned bitoffset(int group) const { assert(0); return 0; }
        void mark_use(Table *tbl) { assert(0); }
        void dbprint(std::ostream &out) const { 
            out << name;
            if (lo >= 0) {
                out << '(' << lo;
                if (hi >= 0 && hi != lo) out << ".. " << hi;
                out << ')'; }
            out << '[' << tbl->name() << ':' << action << ']'; }
    };
public:
    operand() : op(0) {}
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
    operand(Table *tbl, const std::string &act, const value_t &v);
    operand(gress_t gress, const value_t &v) : op(new Phv(v.lineno, gress, v)) {}
    operand(const ::Phv::Ref &r) : op(new Phv(r)) {}
    bool valid() const { return op != 0; }
    bool operator==(operand &a) {
	return op == a.op || (op && a.op && op->lookup(op)->equiv(a.op->lookup(a.op))); }
    unsigned bitoffset(int group) { return op->lookup(op)->bitoffset(group); }
    bool check() { return op && op->lookup(op) ? op->check() : false; }
    int phvGroup() { return op->lookup(op)->phvGroup(); }
    void phvRead(std::function<void (const ::Phv::Slice &sl)> fn) { op->lookup(op)->phvRead(fn); }
    int bits(int group) { return op->lookup(op)->bits(group); }
    void mark_use(Table *tbl) { op->lookup(op)->mark_use(tbl); }
    void dbprint(std::ostream &out) const { op->dbprint(out); }
    Base *operator->() { return op->lookup(op); }
};

operand::operand(Table *tbl, const std::string &act, const value_t &v) : op(0) {
    if (v.type == tINT) {
	op = new Const(v.lineno, v.i);
    } else if (CHECKTYPE2(v, tSTR, tCMD)) {
	const std::string &n = v.type == tSTR ? v.s : v[0].s;
        int lo = -1, hi = -1;
        if (v.type == tCMD) {
            if (!CHECKTYPE2(v[1], tINT, tRANGE)) return;
            if (v[1].type == tINT) lo = hi = v[1].i;
            else {
                lo = v[1].lo;
                hi = v[1].hi; } }
        op = new Named(v.lineno, n, lo, hi, tbl, act); }
}

auto operand::Named::lookup(Base *&ref) -> Base * {
    int slot, len = -1;
    if (tbl->action) tbl = tbl->action;
    if (auto *field = tbl->lookup_field(name, action)) {
#if 0
        if (lo >= 0 && (unsigned)lo >= field->size) {
            error(lineno, "Bit %d out of range for field %s", lo, name.c_str());
            ref = 0;
        } else if (hi >= 0 && (unsigned)hi >= field->size) {
            error(lineno, "Bit %d out of range for field %s", hi, name.c_str());
            ref = 0;
        } else
#endif
            ref = new Action(lineno, name, tbl, field, lo >= 0 ? lo : 0,
                             hi >= 0 ? hi : field->size - 1);
    } else if (tbl->find_on_actionbus(name, 0, 7, &len) >= 0) {
        ref = new Action(lineno, name, tbl, 0, lo >= 0 ? lo : 0,
                         hi >= 0 ? hi : len - 1);
    } else if (!::Phv::get(tbl->gress, name) && sscanf(name.c_str(), "A%d%n", &slot, &len) >= 1 &&
               len == (int)name.size() && slot >= 0 && slot < 32)
        ref = new RawAction(lineno, slot, lo >= 0 ? lo : 0);
    else
        ref = new Phv(lineno, tbl->gress, name, lo, hi);
    if (ref != this) delete this;
    return ref;
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
        Instruction *decode(Table *tbl, const std::string &act, const VECTOR(value_t) &op);
    } *opc;
    Phv::Ref    dest;
    operand     src1, src2;
    AluOP(Decode *d, Table *tbl, const std::string &act, const value_t *ops) :
            Instruction(ops->lineno), opc(d), dest(tbl->gress, ops[0]),
            src1(tbl, act, ops[1]), src2(tbl, act, ops[2]) {}
    Instruction *pass1(Table *tbl);
    void pass2(Table *tbl) { src1->pass2(tbl, slot/16); src2->pass2(tbl, slot/16); }
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const ::Phv::Slice &sl)> fn) {
        src1.phvRead(fn); src2.phvRead(fn); }
    void dbprint(std::ostream &out) const {
        out << "INSTR: " << opc->name << ' ' << dest << ", " << src1 << ", " << src2; }
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
                     opA("alu_a", 0x31e, &opB), opORCB("orcb", 0x35e, &opORCA),
                     opOR("or", 0x39e, true), opSETHI("sethi", 0x39e, true),
                     opBMSET("bitmasked-set", 0x2e); // FIXME -- make 3rd operand explicit?

Instruction *AluOP::Decode::decode(Table *tbl, const std::string &act, const VECTOR(value_t) &op) {
    if (op.size != 4) {
        error(op[0].lineno, "%s requires 3 operands", op[0].s);
        return 0; }
    AluOP *rv = new AluOP(this, tbl, act, op.data + 1);
    if (!rv->src1.valid())
        error(op[2].lineno, "invalid src1");
    else if (!rv->src2.valid())
        error(op[3].lineno, "invalid src2");
    else
        return rv;
    delete rv;
    return 0;
}

Instruction *AluOP::pass1(Table *tbl) {
    if (!dest.check() || !src1.check() || !src2.check()) return this;
    if (dest->lo || dest->hi != dest->reg.size-1) {
        error(lineno, "ALU ops cannot operate on slices");
        return this; }
    slot = dest->reg.index;
    tbl->stage->action_set[tbl->gress][slot] = true;
    src1.mark_use(tbl);
    src2.mark_use(tbl);
    if (src2.phvGroup() < 0 && opc->swap_args) {
        std::swap(src1, src2);
        opc = opc->swap_args; }
    if (src2.phvGroup() < 0)
        error(lineno, "src2 must be phv register");
    return this;
}
int AluOP::encode() {
    return (opc->opcode << 10) | (src1.bits(slot/16) << 4) | src2.bits(slot/16);
}
bool AluOP::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<AluOP *>(a_)) {
	return opc == a->opc && dest == a->dest && src1 == a->src1 && src2 == a->src2;
    } else
	return false;
}

struct LoadConst : public Instruction {
    struct Decode : public Idecode {
        Decode(const char *n) : Idecode(n) {}
        Instruction *decode(Table *tbl, const std::string &act, const VECTOR(value_t) &op);
    };
    Phv::Ref    dest;
    int         src;
    LoadConst(Table *tbl, const std::string &act, const value_t &d, int&s)
	: Instruction(d.lineno), dest(tbl->gress, d), src(s) {}
    Instruction *pass1(Table *tbl);
    void pass2(Table *) {}
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const ::Phv::Slice &sl)> fn) { }
    void dbprint(std::ostream &out) const {
        out << "INSTR: set " << dest << ", " << src; }

};

static LoadConst::Decode opLoadConst("load-const");

Instruction *LoadConst::Decode::decode(Table *tbl, const std::string &act, const VECTOR(value_t) &op) {
    if (op.size != 3) {
        error(op[0].lineno, "%s requires 2 operands", op[0].s);
        return 0; }
    if (!CHECKTYPE(op[2], tINT)) return 0;
    return new LoadConst(tbl, act, op[1], op[2].i);
}

Instruction *LoadConst::pass1(Table *tbl) {
    if (!dest.check()) return this;
    if (dest->lo || dest->hi != dest->reg.size-1) {
        error(lineno, "load-const cannot operate on slices");
        return this; }
    slot = dest->reg.index;
    int size = Phv::reg(slot).size;
    if (size > 23) size = 23;
    if (src >= (1 << size) || src < -(1 << (size-1)))
        error(lineno, "Constant value %d out of range", src);
    src &= (1 << size) - 1;
    tbl->stage->action_set[tbl->gress][slot] = true;
    return this;
}
int LoadConst::encode() {
    return (src >> 10 << 15) | (0x8 << 10) | (src & 0x3ff);
}
bool LoadConst::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<LoadConst *>(a_)) {
	return dest == a->dest && src == a->src;
    } else
	return false;
}

struct CondMoveMux : public Instruction {
    struct Decode : public Idecode {
        unsigned opcode, cond_size;
        bool    src2opt;
        Decode(const char *name, unsigned opc, bool s2opt, unsigned csize, const char *alias_name)
            : Idecode(name), opcode(opc), cond_size(csize), src2opt(s2opt) { alias(alias_name); }
        Instruction *decode(Table *tbl, const std::string &act, const VECTOR(value_t) &op);
    } *opc;
    Phv::Ref    dest;
    operand     src1, src2;
    unsigned    cond;
    CondMoveMux(Table *tbl, Decode *op, const std::string &act, const value_t &d, const value_t &s)
	: Instruction(d.lineno), opc(op), dest(tbl->gress, d), src1(tbl, act, s),
          src2(tbl->gress, d) {}
    CondMoveMux(Table *tbl, Decode *op, const std::string &act, const value_t &d,
                const value_t &s1, const value_t &s2)
	: Instruction(d.lineno), opc(op), dest(tbl->gress, d), src1(tbl, act, s1),
          src2(tbl, act, s2) {}
    Instruction *pass1(Table *tbl);
    void pass2(Table *tbl) { src1->pass2(tbl, slot/16); src2->pass2(tbl, slot/16); }
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const ::Phv::Slice &sl)> fn) {
        if (cond & 1) fn(*dest);
        src1.phvRead(fn);
        if (!opc->src2opt || (cond & 4))
            src2.phvRead(fn); }
    void dbprint(std::ostream &out) const {
        out << "INSTR: cmov " << dest << ", " << src1 << ", " << src2; }
};

static CondMoveMux::Decode opCondMove("cmov", 0x16, true, 5, "conditional-move"),
                           opCondMux("cmux", 0x6, false, 2, "conditional-mux");

Instruction *CondMoveMux::Decode::decode(Table *tbl, const std::string &act, const VECTOR(value_t) &op) {
    if (op.size != 5 && (op.size != 4 || !src2opt)) {
        error(op[0].lineno, "%s requires %s4 operands", op[0].s, src2opt ? "3 or " : "");
        return 0; }
    if (!CHECKTYPE(op[op.size-1], tINT))
    if (op[op.size-1].i < 0 || op[op.size-1].i >= (1 << cond_size)) {
        error(op[op.size-1].lineno, "%s condition must be %d-bit constant", op[0].s, cond_size);
        return 0; }
    CondMoveMux *rv;
    if (op.size == 5)
	rv = new CondMoveMux(tbl, this, act, op[1], op[2], op[3]);
    else
	rv = new CondMoveMux(tbl, this, act, op[1], op[2]);
    rv->cond = op[op.size-1].i;
    if (!rv->src1.valid())
        error(op[2].lineno, "invalid src1");
    else if (!rv->src2.valid())
        error(op[3].lineno, "invalid src2");
    else
        return rv;
    delete rv;
    return 0;
}

Instruction *CondMoveMux::pass1(Table *tbl) {
    if (!dest.check() || !src1.check() || !src2.check()) return this;
    slot = dest->reg.index;
    tbl->stage->action_set[tbl->gress][slot] = true;
    src1.mark_use(tbl);
    src2.mark_use(tbl);
    return this;
}
int CondMoveMux::encode() {
    /* funny cond test on src2 is to match the compiler output -- if we're not testing
     * src2 validity, what we specify as src2 is irrelevant */
    return (cond << 15) | (opc->opcode << 10) | (src1.bits(slot/16) << 4) | 
        (cond & 0x40 ? src2.bits(slot/16) : 0);
}
bool CondMoveMux::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<CondMoveMux *>(a_)) {
	return opc == a->opc && dest == a->dest && src1 == a->src1 && src2 == a->src2 &&
	       cond == a->cond;
    } else
	return false;
}

struct Set;

struct DepositField : public Instruction {
    struct Decode : public Idecode {
        Decode() : Idecode("deposit_field") { alias("deposit-field"); }
        Instruction *decode(Table *tbl, const std::string &act, const VECTOR(value_t) &op);
    };
    Phv::Ref    dest;
    operand     src1, src2;
    DepositField(Table *tbl, const std::string &act, const value_t &d, const value_t &s)
	: Instruction(d.lineno), dest(tbl->gress, d), src1(tbl, act, s), src2(tbl->gress, d) {}
    DepositField(Table *tbl, const std::string &act, const value_t &d, const value_t &s1, const value_t &s2)
	: Instruction(d.lineno), dest(tbl->gress, d), src1(tbl, act, s1), src2(tbl, act, s2) {}
    DepositField(const Set &);
    Instruction *pass1(Table *tbl);
    void pass2(Table *tbl) { src1->pass2(tbl, slot/16); src2->pass2(tbl, slot/16); }
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const ::Phv::Slice &sl)> fn) {
        src1.phvRead(fn); src2.phvRead(fn); }
    void dbprint(std::ostream &out) const {
        out << "INSTR: deposit_field " << dest << ", " << src1 << ", " << src2; }
};

static DepositField::Decode opDepositField;

Instruction *DepositField::Decode::decode(Table *tbl, const std::string &act, const VECTOR(value_t) &op) {
    if (op.size != 4 && op.size != 3) {
        error(op[0].lineno, "%s requires 2 or 3 operands", op[0].s);
        return 0; }
    DepositField *rv;
    if (op.size == 4)
	rv = new DepositField(tbl, act, op[1], op[2], op[3]);
    else
	rv = new DepositField(tbl, act, op[1], op[2]);
    if (!rv->src1.valid())
        error(op[2].lineno, "invalid src1");
    else if (!rv->src2.valid())
        error(op[3].lineno, "invalid src2");
    else
        return rv;
    delete rv;
    return 0;
}

Instruction *DepositField::pass1(Table *tbl) {
    if (!dest.check() || !src1.check() || !src2.check()) return this;
    slot = dest->reg.index;
    tbl->stage->action_set[tbl->gress][slot] = true;
    src1.mark_use(tbl);
    src2.mark_use(tbl);
    return this;
}
int DepositField::encode() {
    unsigned rot = (dest->reg.size - dest->lo + src1.bitoffset(slot/16)) % dest->reg.size;
    int bits = (1 << 10) | (src1.bits(slot/16) << 4) | src2.bits(slot/16);
    bits |= dest->hi << 11;
    bits |= rot << 16;
    switch (Phv::reg(slot).size) {
    case 8:
        bits |= (dest->lo & 3) << 14;
        bits |= (dest->lo & ~3) << 17;
        break;
    case 16:
        bits |= (dest->lo & 1) << 16;
        bits |= (dest->lo & ~1) << 19;
        break;
    case 32:
        bits |= dest->lo << 21;
        break;
    default:
        assert(0); }
    return bits;
}
bool DepositField::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<DepositField *>(a_)) {
	return dest == a->dest && src1 == a->src1 && src2 == a->src2;
    } else
	return false;
}

struct Set : public Instruction {
    struct Decode : public Idecode {
        Decode(const char *n) : Idecode(n) {}
        Instruction *decode(Table *tbl, const std::string &act, const VECTOR(value_t) &op);
    };
    Phv::Ref    dest;
    operand     src;
    Set(Table *tbl, const std::string &act, const value_t &d, const value_t &s)
	: Instruction(d.lineno), dest(tbl->gress, d), src(tbl, act, s) {}
    Instruction *pass1(Table *tbl);
    void pass2(Table *tbl) { src->pass2(tbl, slot/16); }
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const ::Phv::Slice &sl)> fn) { src.phvRead(fn); }
    void dbprint(std::ostream &out) const {
        out << "INSTR: set " << dest << ", " << src; }

};

DepositField::DepositField(const Set &s)
: Instruction(s), dest(s.dest), src1(s.src), src2(s.dest->reg) {}

static Set::Decode opSet("set");

Instruction *Set::Decode::decode(Table *tbl, const std::string &act, const VECTOR(value_t) &op) {
    if (op.size != 3) {
        error(op[0].lineno, "%s requires 2 operands", op[0].s);
        return 0; }
    Set *rv = new Set(tbl, act, op[1], op[2]);
    if (!rv->src.valid())
        error(op[2].lineno, "invalid src");
    else
        return rv;
    delete rv;
    return 0;
}

Instruction *Set::pass1(Table *tbl) {
    if (!dest.check() || !src.check()) return this;
    if (dest->lo || dest->hi != dest->reg.size-1)
        return (new DepositField(*this))->pass1(tbl);
    slot = dest->reg.index;
    tbl->stage->action_set[tbl->gress][slot] = true;
    src.mark_use(tbl);
    return this;
}
int Set::encode() {
    return (opA.opcode << 10) | (src.bits(slot/16) << 4) | (slot & 0xf);
}
bool Set::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<Set *>(a_)) {
	return dest == a->dest && src == a->src;
    } else
	return false;
}

struct NulOP : public Instruction {
    struct Decode : public Idecode {
        std::string name;
        unsigned opcode;
        Decode(const char *n, unsigned opc) : Idecode(n), name(n), opcode(opc) {}
        Instruction *decode(Table *tbl, const std::string &act, const VECTOR(value_t) &op);
    } *opc;
    Phv::Ref    dest;
    NulOP(Table *tbl, const std::string &act, Decode *o, const value_t &d) :
        Instruction(d.lineno), opc(o), dest(tbl->gress, d) {}
    Instruction *pass1(Table *tbl);
    void pass2(Table *) {}
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const ::Phv::Slice &sl)> fn) { }
    void dbprint(std::ostream &out) const {
        out << "INSTR: " << opc->name << " " << dest; }
};

static NulOP::Decode opInvalidate("invalidate", 0x7000), opNoop("noop", 0);

Instruction *NulOP::Decode::decode(Table *tbl, const std::string &act, const VECTOR(value_t) &op) {
    if (op.size != 2) {
        error(op[0].lineno, "%s requires 1 operand", op[0].s);
        return 0; }
    return new NulOP(tbl, act, this, op[1]);
}

Instruction *NulOP::pass1(Table *tbl) {
    if (!dest.check()) return this;
    slot = dest->reg.index;
    if (opc->opcode || !options.match_compiler) {
        tbl->stage->action_set[tbl->gress][slot] = true; }
    return this;
}
int NulOP::encode() {
    return opc->opcode;
}
bool NulOP::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<NulOP *>(a_)) {
	return opc == a->opc && dest == a->dest;
    } else
	return false;
}

Instruction *Instruction::decode(Table *tbl, const std::string &act, const VECTOR(value_t) &op) {
    if (auto *d = ::get(Idecode::opcode, op[0].s))
        return d->decode(tbl, act, op);
    else
        error(op[0].lineno, "Unknown instruction %s", op[0].s);
    return 0;
}

struct ShiftOP : public Instruction {
    struct Decode : public Idecode {
        std::string name;
        unsigned opcode;
        bool use_src1;
        Decode *swap_args;
        Decode(const char *n, unsigned opc, bool funnel = false) : Idecode(n), name(n),
            opcode(opc), use_src1(funnel) {}
        Instruction *decode(Table *tbl, const std::string &act, const VECTOR(value_t) &op);
    } *opc;
    Phv::Ref    dest;
    operand     src1, src2;
    int         shift;
    ShiftOP(Decode *d, Table *tbl, const std::string &act, const value_t *ops) :
            Instruction(ops->lineno), opc(d), dest(tbl->gress, ops[0]),
            src1(tbl, act, ops[1]), src2(tbl, act, ops[2]) {
                if (opc->use_src1) {
                    if (CHECKTYPE(ops[3], tINT)) shift = ops[3].i;
                } else {
                    src2 = src1;
                    if (CHECKTYPE(ops[2], tINT)) shift = ops[2].i; } }
    Instruction *pass1(Table *tbl);
    void pass2(Table *tbl) { src1->pass2(tbl, slot/16); src2->pass2(tbl, slot/16); }
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const ::Phv::Slice &sl)> fn) {
        src1.phvRead(fn); src2.phvRead(fn); }
    void dbprint(std::ostream &out) const {
        out << "INSTR: " << opc->name << ' ' << dest << ", " << src1 << ", " << shift; }
};

static ShiftOP::Decode opSHL("shl", 0x0c, false), opSHRS("shrs", 0x1c, false),
                       opSHRU("shru", 0x14, false), opFUNSHIFT("funnel-shift", 0x04, true);

Instruction *ShiftOP::Decode::decode(Table *tbl, const std::string &act, const VECTOR(value_t) &op) {
    if (op.size != (use_src1 ? 5 : 4)) {
        error(op[0].lineno, "%s requires %d operands", op[0].s, use_src1 ? 4 : 3);
        return 0; }
    ShiftOP *rv = new ShiftOP(this, tbl, act, op.data + 1);
    if (!rv->src1.valid())
        error(op[2].lineno, "invalid src1");
    else if (!rv->src2.valid())
        error(op[3].lineno, "invalid src2");
    else if (rv->shift < 0 || rv->shift > 0x1f)
        error(op[3].lineno, "invalid shift");
    else
        return rv;
    delete rv;
    return 0;
}

Instruction *ShiftOP::pass1(Table *tbl) {
    if (!dest.check() || !src1.check() || !src2.check()) return this;
    if (dest->lo || dest->hi != dest->reg.size-1) {
        error(lineno, "shift ops cannot operate on slices");
        return this; }
    slot = dest->reg.index;
    tbl->stage->action_set[tbl->gress][slot] = true;
    src1.mark_use(tbl);
    src2.mark_use(tbl);
    if (src2.phvGroup() < 0)
        error(lineno, "src%s must be phv register", opc->use_src1 ? "2" : "");
    return this;
}
int ShiftOP::encode() {
    int rv = (shift << 16) | (opc->opcode << 10) | src2.bits(slot/16);
    if (opc->use_src1 || options.match_compiler) rv |= src1.bits(slot/16) << 4;
    return rv;
}
bool ShiftOP::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<ShiftOP *>(a_)) {
	return opc == a->opc && dest == a->dest && src1 == a->src1 && src2 == a->src2 &&
	       shift == a->shift;
    } else
	return false;
}
