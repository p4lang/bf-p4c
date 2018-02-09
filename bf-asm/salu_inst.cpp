#include <config.h>

#include "instruction.h"
#include "phv.h"
#include "tables.h"
#include "stage.h"
#include <cstring>

namespace {

struct operand {
    struct Base {
        int lineno;
        Base(int line) : lineno(line) {}
        Base(const Base &a) : lineno(a.lineno) {}
        virtual ~Base() {}
        virtual Base *clone() const = 0;
        virtual void dbprint(std::ostream &) const = 0;
        virtual bool equiv(const Base *) const = 0;
        virtual const char *kind() const = 0;
        virtual Base *lookup(Base *&) { return this; }
        virtual void pass1(StatefulTable *) { }
    } *op;
    struct Const : public Base {
        long value;
        Const *clone() const override { return new Const(*this); }
        Const(int line, long v) : Base(line), value(v) {}
        void dbprint(std::ostream &out) const override { out << value; }
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const Const *>(a_)) {
                return value == a->value;
            } else return false; }
        const char *kind() const override { return "constant"; }
    };
    struct Phv : public Base {
        virtual Phv *clone() const = 0;
        Phv(int lineno) : Base(lineno) {}
        virtual int phv_index(StatefulTable *tbl) = 0;
    };
    struct PhvReg : public Phv {
        ::Phv::Ref      reg;
        PhvReg *clone() const override { return new PhvReg(*this); }
        PhvReg(gress_t gress, const value_t &v) : Phv(v.lineno), reg(gress, v) {}
        void dbprint(std::ostream &out) const override { out << reg; }
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const PhvReg *>(a_)) {
                return reg == a->reg;
            } else return false; }
        const char *kind() const override { return "phv_reg"; }
        void pass1(StatefulTable *tbl) override {
            if (!reg.check()) return;
            int size = tbl->format->begin()->second.size/8U;
            if (!tbl->input_xbar) {
                error(lineno, "No input xbar for salu instruction operand for phv");
                return;
            }
            int byte = tbl->find_on_ixbar(*reg, tbl->input_xbar->match_group());
            int base = options.target == TOFINO ? 8 : 0;
            if (byte < 0)
                error(lineno, "Can't find %s on the input xbar", reg.name());
            else if (byte != base && byte != base + size)
                error(lineno, "%s must be at %d or %d on ixbar to be used in stateful table %s",
                      reg.desc().c_str(), base*8, (base + size)*8, tbl->name());
            else if (reg->size() > size * 8)
                error(lineno, "%s is too big for stateful table %s",
                      reg.desc().c_str(), tbl->name());
            else
                tbl->phv_byte_mask |= ((1U << (reg->size() + 7)/8U) - 1) << (byte - base); }
        int phv_index(StatefulTable *tbl) override {
            int base = options.target == TOFINO ? 8 : 0;
            return tbl->find_on_ixbar(*reg, tbl->input_xbar->match_group()) > base; }
    };
    // Operand which directly accesses phv(hi/lo) from Input Xbar
    struct PhvRaw : public Phv {
        int pi=-1;
        PhvRaw *clone() const override { return new PhvRaw(*this); }
        PhvRaw(gress_t gress, const value_t &v) : Phv(v.lineno) {
            if (v == "phv_lo") pi = 0;
            else if (v == "phv_hi") pi = 1;
            else assert(0); }
        void dbprint(std::ostream &out) const override { out << pi; }
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const PhvRaw *>(a_)) {
                return pi == a->pi;
            } else return false; }
        const char *kind() const override { return "phv_ixb"; }
        int phv_index(StatefulTable *tbl) override { return pi; }
    };
    struct Memory : public Base {
        Table                     *tbl;
        Table::Format::Field      *field;
        Memory *clone() const override { return new Memory(*this); }
        Memory(int line, Table *t, Table::Format::Field *f)
        : Base(line), tbl(t), field(f) {}
        void dbprint(std::ostream &out) const override { out << tbl->format->find_field(field); }
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const Memory *>(a_)) {
                return field == a->field;
            } else return false; }
        const char *kind() const override { return "memory"; }
    };
    struct MathFn;
    bool neg = false;
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
    operand(Table *tbl, const Table::Actions::Action *act, const value_t &v);
    bool valid() const { return op != 0; }
    explicit operator bool() const { return op != 0; }
    bool operator==(operand &a) {
        return op == a.op || (op && a.op && op->lookup(op)->equiv(a.op->lookup(a.op))); }
    void dbprint(std::ostream &out) const {
        if (neg) out << '-';
        if (op) op->dbprint(out); else out << "(null)"; }
    Base *operator->() { return op->lookup(op); }
    template<class T> T *to() { return dynamic_cast<T *>(op); }
};

struct operand::MathFn : public Base {
    operand of;
    MathFn *clone() const override { return new MathFn(*this); }
    MathFn(int line, operand of) : Base(line), of(of) {}
    void dbprint(std::ostream &out) const override { out << "math(" << of << ")";; }
    bool equiv(const Base *a_) const override {
        if (auto *a = dynamic_cast<const MathFn *>(a_)) {
            return of.op == a->of.op;
        } else return false; }
    const char *kind() const override { return "math fn"; }
};

operand::operand(Table *tbl, const Table::Actions::Action *act, const value_t &v_) : op(nullptr) {
    const value_t *v = &v_;
    if (v->type == tCMD && *v == "-") {
        neg = true;
        v = &v->vec[1]; }
    if (v->type == tINT) {
        op = new Const(v->lineno, v->i);
    } else if (v->type == tBIGINT) {
        if (v->bigi.size > 1 || v->bigi.data[0] > LONG_MAX)
            error(v->lineno, "Integer too large");
        op = new Const(v->lineno, v->bigi.data[0]);
    } else if (v->type == tSTR) {
        if (auto f = tbl->format->field(v->s))
            op = new Memory(v->lineno, tbl, f);
        else if (*v == "phv_lo" || *v == "phv_hi")
            op = new PhvRaw(tbl->gress, *v);
        else
            op = new PhvReg(tbl->gress, *v);
    } else if ((v->type == tCMD) && (v->vec[0] == "math_table")) {
        //operand *opP = new operand(tbl, act, v->vec[1]);
        op = new MathFn(v->lineno, operand(tbl, act, v->vec[1])); }
    else
        op = new PhvReg(tbl->gress, *v);
}

enum salu_slot_use {
    CMP0, CMP1, CMP2, CMP3,
    ALU2LO, ALU1LO, ALU2HI, ALU1HI,
    ALUOUT0, ALUOUT1, ALUOUT2, ALUOUT3,
    // aliases
    CMPLO=CMP0, CMPHI=CMP1,
    ALUOUT=ALUOUT0,
};

//Abstract interface class for SALU Instructions
//SALU Instructions - AluOP, BitOP, CmpOP, OutOP
struct SaluInstruction : public Instruction {
    SaluInstruction(int lineno): Instruction(lineno) {};
    //Stateful ALU's dont access PHV's directly
    void phvRead(std::function<void (const Phv::Slice &sl)>) final {};
    static int decode_predicate(const value_t &exp);
};

int SaluInstruction::decode_predicate(const value_t &exp) {
    if (exp == "cmplo") return STATEFUL_PREDICATION_ENCODE_CMPLO;
    if (exp == "cmphi") return STATEFUL_PREDICATION_ENCODE_CMPHI;
    if (exp == "cmp0") return STATEFUL_PREDICATION_ENCODE_CMP0;
    if (Target::STATEFUL_CMP_UNITS() > 1 && exp == "cmp1") return STATEFUL_PREDICATION_ENCODE_CMP1;
    if (Target::STATEFUL_CMP_UNITS() > 2 && exp == "cmp2") return STATEFUL_PREDICATION_ENCODE_CMP2;
    if (Target::STATEFUL_CMP_UNITS() > 3 && exp == "cmp3") return STATEFUL_PREDICATION_ENCODE_CMP3;
    if (exp == "!") return Target::STATEFUL_PRED_MASK() ^ decode_predicate(exp[1]);
    if (exp == "&") return decode_predicate(exp[1]) & decode_predicate(exp[2]);;
    if (exp == "|") return decode_predicate(exp[1]) | decode_predicate(exp[2]);;
    if (exp == "^") return decode_predicate(exp[1]) ^ decode_predicate(exp[2]);;
    if (exp.type == tINT && exp.i >=0 && exp.i <= Target::STATEFUL_PRED_MASK()) return exp.i;
    error(exp.lineno, "Unexpected expression %s in predicate", value_desc(&exp));
    return -1;
}

struct AluOP : public SaluInstruction {
    const struct Decode : public Instruction::Decode {
        std::string name;
        unsigned opcode;
        enum operands_t { NONE, A, B, AandB } operands = AandB;
        const Decode *swap_args;
        Decode(const char *n, int opc, bool assoc = false, const char *alias_name = 0)
        : Instruction::Decode(n, STATEFUL_ALU), name(n), opcode(opc), swap_args(assoc ? this : 0) {
            if (alias_name) alias(alias_name, STATEFUL_ALU); }
        Decode(const char *n, int opc, Decode *sw, const char *alias_name = 0,
               operands_t use = AandB)
        : Instruction::Decode(n, STATEFUL_ALU), name(n), opcode(opc), operands(use), swap_args(sw) {
            if (sw && !sw->swap_args) sw->swap_args = this;
            if (alias_name) alias(alias_name, STATEFUL_ALU); }
        Decode(const char *n, int opc, const char *alias_name)
        : Instruction::Decode(n, STATEFUL_ALU), name(n), opcode(opc), swap_args(0) {
            if (alias_name) alias(alias_name, STATEFUL_ALU); }
        Decode(const char *n, int opc, bool assoc, operands_t use)
        : Instruction::Decode(n, STATEFUL_ALU), name(n), opcode(opc), operands(use),
          swap_args(assoc ? this : 0) {}
        Decode(const char *n, int opc, const char *alias_name, operands_t use)
        : Instruction::Decode(n, STATEFUL_ALU), name(n), opcode(opc), operands(use), swap_args(0) {
            if (alias_name) alias(alias_name, STATEFUL_ALU); }
        Decode(const char *n, int opc, Decode *sw, operands_t use)
        : Instruction::Decode(n, STATEFUL_ALU), name(n), opcode(opc), operands(use), swap_args(sw) {
            if (sw && !sw->swap_args) sw->swap_args = this; }

        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    } *opc;
    int predication_encode = STATEFUL_PREDICATION_ENCODE_UNCOND;
    enum { LO, HI }     dest;
    operand             srca, srcb;
    AluOP(const Decode *op, int l) : SaluInstruction(l), opc(op) {}
    std::string name() override { return opc->name; };
    void gen_prim_cfg(json::map& out) override {
        out["name"] = opc->name;
        /* TODO:
        dest.gen_prim_cfg((out["dst"] = json::map()));
        json::vector &srcv = out["src"] = json::vector();
        json::map oneoper;
        srca.gen_prim_cfg(oneoper);
        srcv.push_back(std::move(oneoper));
        srcb.gen_prim_cfg(oneoper);
        srcv.push_back(std::move(oneoper));
        */
    }
    Instruction *pass1(Table *tbl, Table::Actions::Action *) override;
    void pass2(Table *tbl, Table::Actions::Action *)  override { }
    bool equiv(Instruction *a_) override;
    void dbprint(std::ostream &out) const override {
        out << "INSTR: " << opc->name /*<< ' ' << dest << ", " << src1 << ", " << src2*/; }
    template<class REGS> void write_regs(REGS &regs, Table *tbl, Table::Actions::Action *act);
    FOR_ALL_TARGETS(DECLARE_FORWARD_VIRTUAL_INSTRUCTION_WRITE_REGS)
};

static AluOP::Decode opADD("add", 0x1c, true), opSUB("sub", 0x1e),
                     opSADDU("saddu", 0x10, true), opSADDS("sadds", 0x11, true),
                     opSSUBU("ssubu", 0x12), opSSUBS("ssubs", 0x13),
                     opMINU("minu", 0x14, true), opMINS("mins", 0x15, true),
                     opMAXU("maxu", 0x16, true), opMAXS("maxs", 0x17, true),
                     opSUBR("subr", 0x1f, &opSUB),
                     opSSUBRU("ssubru", 0x1a, &opSSUBU), opSSUBRS("ssubrs", 0x1b, &opSSUBS),

                     opSETZ("setz", 0x00, true, AluOP::Decode::NONE), opNOR("nor", 0x01, true),
                     opANDCA("andca", 0x02), opNOTA("nota", 0x03, "not", AluOP::Decode::A),
                     opANDCB("andcb", 0x04, &opANDCA),
                     opNOTB("notb", 0x05, &opNOTA, AluOP::Decode::B),
                     opXOR("xor", 0x06, true), opNAND("nand", 0x07, true),
                     opAND("and", 0x08, true), opXNOR("xnor", 0x09, true),
                     opB("alu_b", 0x0a, "b", AluOP::Decode::B), opORCA("orca", 0x0b),
                     opA("alu_a", 0x0c, &opB, "a", AluOP::Decode::A), opORCB("orcb", 0x0d, &opORCA),
                     opOR("or", 0x0e, true), opSETHI("sethi", 0x0f, true, AluOP::Decode::NONE);

Instruction *AluOP::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                   const VECTOR(value_t) &op) const {
    AluOP *rv = new AluOP(this, op[0].lineno);
    auto operands = this->operands;
    int idx = 1;
    // Check optional predicate operand
    if (idx < op.size) {
        if (op[idx].type == tINT) {
            // Predicate is an integer. no warning for odd values
            rv->predication_encode = op[idx++].i;
        } else if (op[idx].startsWith("cmp") || op[idx] == "!" ||
                   op[idx] == "&" || op[idx] == "|" || op[idx] == "^") {
            // Predicate is an expression
            rv->predication_encode = decode_predicate(op[idx++]);
            if (rv->predication_encode == STATEFUL_PREDICATION_ENCODE_NOOP)
                warning(op[idx-1].lineno, "Instruction predicate is always false");
            else if (rv->predication_encode == STATEFUL_PREDICATION_ENCODE_UNCOND)
                warning(op[idx-1].lineno, "Instruction predicate is always true"); } }
    if (idx < op.size && op[idx] == "lo") {
        rv->dest = LO;
        idx++;
    } else if (idx < op.size && op[idx] == "hi") {
        rv->dest = HI;
        idx++;
    } else
        error(rv->lineno, "invalid destination for %s instruction", op[0].s);
    if (operands == NONE) {
        if (idx < op.size)
            error(rv->lineno, "too many operands for %s instruction", op[0].s);
        return rv; }
    if (idx < op.size)
        rv->srca = operand(tbl, act, op[idx++]);
    if (idx < op.size)
        rv->srcb = operand(tbl, act, op[idx++]);
    if ((rv->srca.to<operand::Phv>() || rv->srca.to<operand::MathFn>()) && swap_args) {
        operands = (rv->opc = swap_args)->operands;
        std::swap(rv->srca, rv->srcb);
    } else if ((rv->srcb.to<operand::Memory>() && rv->srca.to<operand::Const>()) && swap_args) {
        operands = (rv->opc = swap_args)->operands;
        std::swap(rv->srca, rv->srcb);
    } else if (operands == B) {
        std::swap(rv->srca, rv->srcb); }
    if (idx < op.size || (operands == A && rv->srcb) || (operands == B && rv->srca))
        error(rv->lineno, "too many operands for %s instruction", op[0].s);
    else if ((!rv->srca && operands != B) || (!rv->srcb && operands != A))
        error(rv->lineno, "not enough operands for %s instruction", op[0].s);
    if (rv->srca.to<operand::MathFn>())
        error(rv->lineno, "Can't reference math table in %soperand of %s instruction",
              operands != A ? "first " : "", op[0].s);
    if (rv->srca.to<operand::Phv>())
        error(rv->lineno, "Can't reference phv in %soperand of %s instruction",
              operands != A ? "first " : "", op[0].s);
    if (rv->srcb.to<operand::Memory>())
        error(rv->lineno, "Can't reference memory in %soperand of %s instruction",
              operands != A ? "first " : "", op[0].s);
    if (rv->srcb.to<operand::MathFn>()) {
        rv->slot = ALU2LO;
        if (rv->dest != LO)
            error(rv->lineno, "Can't reference math table in alu-hi"); }
    if (rv->srca.neg) {
        if (auto k = rv->srca.to<operand::Const>())
            k->value = -k->value;
        else
            error(rv->lineno, "Can't negate operand of %s instruction", op[0].s); }
    if (rv->srcb.neg) {
        if (auto k = rv->srcb.to<operand::Const>())
            k->value = -k->value;
        else
            error(rv->lineno, "Can't negate operand of %s instruction", op[0].s); }
    return rv;
}

bool AluOP::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<AluOP *>(a_))
        return opc == a->opc && predication_encode == a->predication_encode && dest == a->dest &&
               srca == a->srca && srcb == a->srcb;
    return false;
}

Instruction *AluOP::pass1(Table *tbl_, Table::Actions::Action *act) {
    auto tbl = dynamic_cast<StatefulTable *>(tbl_);
    if (slot < 0 && act->slot_use[slot = (dest ? ALU1HI : ALU1LO)])
        slot = dest ? ALU2HI : ALU2LO;
    auto k1 = srca.to<operand::Const>();
    auto k2 = srcb.to<operand::Const>();
    if (k1 && k2 && k1->value != k2->value)
        error(lineno, "can only have one distinct constant in an SALU instruction");
    if (!k1) k1 = k2;
    if (k1 && (k1->value < -8 || k1->value >= 8))
        tbl->get_const(k1->value);
    if (srca) srca->pass1(tbl);
    if (srcb) srcb->pass1(tbl);
    return this; }

struct BitOP : public SaluInstruction {
    const struct Decode : public Instruction::Decode {
        std::string name;
        unsigned opcode;
        Decode(const char *n, unsigned opc)
        : Instruction::Decode(n, STATEFUL_ALU), name(n), opcode(opc) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    } *opc;
    int predication_encode = STATEFUL_PREDICATION_ENCODE_UNCOND;
    BitOP(const Decode *op, int lineno) : SaluInstruction(lineno), opc(op) {}
    std::string name() override { return opc->name; };
    void gen_prim_cfg(json::map& out) override {
        out["name"] = opc->name;
    }
    Instruction *pass1(Table *, Table::Actions::Action *) override { slot = ALU1LO; return this; }
    void pass2(Table *, Table::Actions::Action *) override { }
    bool equiv(Instruction *a_) override;
    void dbprint(std::ostream &out) const override{
        out << "INSTR: " << opc->name /*<< ' ' << dest << ", " << src1 << ", " << src2*/; }
    template<class REGS> void write_regs(REGS &regs, Table *tbl, Table::Actions::Action *act);
    FOR_ALL_TARGETS(DECLARE_FORWARD_VIRTUAL_INSTRUCTION_WRITE_REGS)
};

static BitOP::Decode opSET_BIT("set_bit", 0x0), opSET_BITC("set_bitc", 0x1),
                     opCLR_BIT("clr_bit", 0x2), opCLR_BITC("clr_bitc", 0x3),
                     opREAD_BIT("read_bit", 0x4), opREAD_BITC("read_bitc", 0x5),
                     opSET_BIT_AT("set_bit_at", 0x6), opSET_BITC_AT("set_bitc_at", 0x7),
                     opCLR_BIT_AT("clr_bit_at", 0x8), opCLR_BITC_AT("clr_bitc_at", 0x9);

Instruction *BitOP::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                   const VECTOR(value_t) &op) const {
    BitOP *rv = new BitOP(this, op[0].lineno);
    if (op.size > 1)
        error(rv->lineno, "too many operands for %s instruction", op[0].s);
    return rv;
}

bool BitOP::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<BitOP *>(a_))
        return opc == a->opc;
    return false;
}

struct CmpOP : public SaluInstruction {
    const struct Decode : public Instruction::Decode {
        std::string     name;
        unsigned        opcode;
        Decode(const char *n, unsigned opc, bool type)
        : Instruction::Decode(n, STATEFUL_ALU, type), name(n), opcode(opc) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                                    const VECTOR(value_t) &op) const override;
    } *opc;
    int                 type = 0;
    enum { LO, HI }     dest;
    operand::Memory     *srca = 0;
    operand::Phv        *srcb = 0;
    operand::Const      *srcc = 0;
    bool                srca_neg = false, srcb_neg = false;
    CmpOP(const Decode *op, int lineno) : SaluInstruction(lineno), opc(op) {}
    std::string name() override { return opc->name; };
    void gen_prim_cfg(json::map& out) override {
        out["name"] = opc->name;
        /* TODO: What are srca, srcb and srcc here?
        srca->gen_prim_cfg((out["dst"] = json::map()));
        json::vector &srcv = out["src"] = json::vector();
        json::map oneoper;
        srcb->gen_prim_cfg(oneoper);
        srcv.push_back(std::move(oneoper));
        srcc->gen_prim_cfg(oneoper);
        srcv.push_back(std::move(oneoper));
        */
    }
    Instruction *pass1(Table *tbl, Table::Actions::Action *) override;
    void pass2(Table *tbl, Table::Actions::Action *) override { }
    bool equiv(Instruction *a_) override;
    void dbprint(std::ostream &out) const override{
        out << "INSTR: " << opc->name /*<< ' ' << dest << ", " << src1 << ", " << src2*/; }
    template<class REGS> void write_regs(REGS &regs, Table *tbl, Table::Actions::Action *act);
    FOR_ALL_TARGETS(DECLARE_FORWARD_VIRTUAL_INSTRUCTION_WRITE_REGS)
};

static CmpOP::Decode opEQU("equ", 0, false), opNEQ("neq", 1, false),
    opGRT("grt", 0, true), opLEQ("leq", 1, true), opGEQ("geq", 2, true), opLSS("lss", 3, true);

Instruction *CmpOP::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                   const VECTOR(value_t) &op) const {
    auto rv = new CmpOP(this, op[0].lineno);
    if (auto *p = strchr(op[0].s, '.')) {
        if (type_suffix && !strcmp(p, ".s")) rv->type = 1;
        else if (type_suffix && !strcmp(p, ".u")) rv->type = 2;
        else if (type_suffix && !strcmp(p, ".uus")) rv->type = 3;
        else error(rv->lineno, "Invalid type %s for %s instruction", p+1, name.c_str());
    } else if (type_suffix)
        error(rv->lineno, "Missing type for %s instruction", name.c_str());
    int idx = 1;
    if (idx < op.size && op[idx] == "lo") {
        rv->dest = LO;
        idx++;
    } else if (idx < op.size && op[idx] == "hi") {
        rv->dest = HI;
        idx++;
    } else
        error(rv->lineno, "invalid destination for %s instruction", op[0].s);
    while (idx < op.size) {
        operand src(tbl, act, op[idx++]);
        if (!rv->srca && (rv->srca = src.to<operand::Memory>())) {
            src.op = nullptr;
            rv->srca_neg = src.neg;
        } else if (!rv->srcb && (rv->srcb = src.to<operand::Phv>())) {
            src.op = nullptr;
            rv->srcb_neg = src.neg;
        } else if (!rv->srcc && (rv->srcc = src.to<operand::Const>())) {
            src.op = nullptr;
            if (src.neg)
                rv->srcc->value = -rv->srcc->value;
        } else if (src) {
            error(src->lineno, "Can't have more than one %s operand to an SALU compare",
                  src->kind()); } }
    return rv;
}

bool CmpOP::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<CmpOP *>(a_))
        return opc == a->opc && dest == a->dest && srca == a->srca &&
               srcb == a->srcb && srcc == a->srcc;
    return false;
}

Instruction *CmpOP::pass1(Table *tbl_, Table::Actions::Action *act) {
    auto tbl = dynamic_cast<StatefulTable *>(tbl_);
    slot = dest;
    if (srca) srca->pass1(tbl);
    if (srcb) srcb->pass1(tbl);
    if (srcc) srcc->pass1(tbl);
    return this;
}

//Output ALU instruction
struct OutOP : public SaluInstruction {
    struct Decode : public Instruction::Decode {
        static const int min_ops = 2;
        static const int max_ops = 3;
        Decode(const char *n) : Instruction::Decode(n, STATEFUL_ALU) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
        void check_num_ops(int lineno, const VECTOR(value_t) &op) const;
    };
    int predication_encode = STATEFUL_PREDICATION_ENCODE_UNCOND;
    int output_mux;
    FOR_ALL_TARGETS(TARGET_OVERLOAD, void decode_output_mux, value_t &op)
    OutOP(const Decode *op, int lineno) : SaluInstruction(lineno) {}
    std::string name() override { return "output"; };
    void gen_prim_cfg(json::map& out) override { out["name"] = "output"; };
    Instruction *pass1(Table *tbl, Table::Actions::Action *) override { slot = ALUOUT; return this; }
    void pass2(Table *tbl, Table::Actions::Action *) override { }
    bool equiv(Instruction *a_) override;
    void dbprint(std::ostream &out) const override {
        out << "INSTR: output " /*<< ' ' << dest << ", " << src1 << ", " << src2*/; }
    template<class REGS> void write_regs(REGS &regs, Table *tbl, Table::Actions::Action *act);
    FOR_ALL_TARGETS(DECLARE_FORWARD_VIRTUAL_INSTRUCTION_WRITE_REGS)
};

static OutOP::Decode opOUTPUT("output");

bool OutOP::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<OutOP *>(a_))
        return predication_encode == a->predication_encode
                && slot == a->slot && output_mux == a->output_mux;
    return false;
}
void OutOP::Decode::check_num_ops(int lineno, const VECTOR(value_t) &op) const {
    //FIXME: Mechanism to print more detail on expected instruction format
    //and allowed operands values
    if (op.size > max_ops)
        error(lineno, "too many operands for %s instruction", op[0].s);
    if (op.size < min_ops)
        error(lineno, "too few operands for %s instruction", op[0].s);
}

Instruction *OutOP::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                   const VECTOR(value_t) &op) const {
    OutOP *rv = new OutOP(this, op[0].lineno);
    check_num_ops(rv->lineno, op);
    int idx = 1;
    // Check optional predicate operand
    if (idx < op.size) {
        // Predicate is an integer
        if(op[idx].type == tINT) {
            rv->predication_encode = op[idx++].i;
        // Predicate is an expression
        } else if (op[idx].startsWith("cmp") || op[idx] == "!" ||
                   op[idx] == "&" || op[idx] == "|" || op[idx] == "^") {
            rv->predication_encode = decode_predicate(op[idx++]);
            if (rv->predication_encode == STATEFUL_PREDICATION_ENCODE_NOOP)
                warning(op[idx-1].lineno, "Instruction predicate is always false");
            else if (rv->predication_encode == STATEFUL_PREDICATION_ENCODE_UNCOND)
                warning(op[idx-1].lineno, "Instruction predicate is always true"); } }
    //Check mux operand
    if (idx < op.size) {
        SWITCH_FOREACH_TARGET(options.target, rv->decode_output_mux(TARGET(), op[idx]); );
        if (rv->output_mux < 0)
            error(op[idx].lineno, "invalid operand '%s' for '%s' instruction",
                  value_desc(op[idx]), op[0].s); }
    return rv;
}

#include "tofino/salu_inst.cpp"
#if HAVE_JBAY
#include "jbay/salu_inst.cpp"
#endif // HAVE_JBAY

}  // end anonymous namespace
