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
        virtual void pass1(Stateful *) { }
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
        virtual int phv_index(Stateful *tbl) = 0;
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
        void pass1(Stateful *tbl) override {
            if (!reg.check()) return;
            int size = tbl->format->begin()->second.size/8U;
            int byte = tbl->find_on_ixbar(*reg, tbl->input_xbar->match_group());
            if (byte < 0)
                error(lineno, "Can't find %s on the input xbar", reg.name());
            else if (byte != 8 && byte != 8 + size)
                error(lineno, "%s must be at 64 or %d on ixbar to be used in stateful table %s",
                      reg.desc().c_str(), 64 + size*8, tbl->name());
            else if (reg->size() > size * 8)
                error(lineno, "%s is too big for stateful table %s",
                      reg.desc().c_str(), tbl->name());
            else
                tbl->phv_byte_mask |= ((1U << (reg->size() + 7)/8U) - 1) << (byte - 8); }
        int phv_index(Stateful *tbl) override {
            return tbl->find_on_ixbar(*reg, tbl->input_xbar->match_group()) > 8; }
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
        int phv_index(Stateful *tbl) override { return pi; }
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
    CMPLO, CMPHI,
    ALU2LO, ALU1LO, ALU2HI, ALU1HI,
    ALUOUT
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
    if (exp == "!") return 0xf ^ decode_predicate(exp[1]);
    if (exp == "&") return decode_predicate(exp[1]) & decode_predicate(exp[2]);;
    if (exp == "|") return decode_predicate(exp[1]) | decode_predicate(exp[2]);;
    if (exp == "^") return decode_predicate(exp[1]) ^ decode_predicate(exp[2]);;
    if (exp.type == tINT && exp.i >=0 && exp.i <= 15) return exp.i;
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
    Instruction *pass1(Table *tbl, Table::Actions::Action *) override;
    void pass2(Table *tbl, Table::Actions::Action *)  override { }
    bool equiv(Instruction *a_) override;
    void dbprint(std::ostream &out) const override {
        out << "INSTR: " << opc->name /*<< ' ' << dest << ", " << src1 << ", " << src2*/; }
    template<class REGS> void write_regs(REGS &regs, Table *tbl, Table::Actions::Action *act);
    FOR_ALL_TARGETS(FORWARD_VIRTUAL_INSTRUCTION_WRITE_REGS)
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
        } else if (op[idx] == "cmplo" || op[idx] == "cmphi" || op[idx] == "!" ||
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
    auto tbl = dynamic_cast<Stateful *>(tbl_);
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

template<class REGS>
void AluOP::write_regs(REGS &regs, Table *tbl_, Table::Actions::Action *act) {
    auto tbl = dynamic_cast<Stateful *>(tbl_);
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu = meter_group.stateful.salu_instr_state_alu[act->code][slot - 2];
    auto &salu_instr_common = meter_group.stateful.salu_instr_common[act->code];
    auto &salu_instr_output_alu = meter_group.stateful.salu_instr_output_alu[act->code];
    salu.salu_op = opc->opcode & 0xf;
    salu.salu_arith = opc->opcode >> 4;
    salu.salu_pred = predication_encode;
    if (tbl->is_dual_mode()) {
        salu_instr_common.salu_datasize = tbl->format->log2size - 1;
        salu_instr_common.salu_op_dual = 1; }
    else {
        salu_instr_common.salu_datasize = tbl->format->log2size; }
    if (srca) {
        if (auto m = srca.to<operand::Memory>()) {
            salu.salu_asrc_memory = 1;
            salu.salu_asrc_memory_index = m->field->bit(0) > 0;
        } else if (auto k = srca.to<operand::Const>()) {
            salu.salu_asrc_memory = 0;
            if (k->value >= -8 && k->value < 8) {
                salu.salu_const_src = k->value;
                salu.salu_regfile_const = 0;
            } else {
                salu.salu_const_src = tbl->get_const(k->value);
                salu.salu_regfile_const = 1; }
        } else assert(0); }
    if (srcb) {
        if (auto f = srcb.to<operand::Phv>()) {
            salu.salu_bsrc_phv = 1;
            salu.salu_bsrc_phv_index = f->phv_index(tbl);
        } else if (auto m = srcb.to<operand::MathFn>()) {
            if(auto b = m->of.to<operand::Phv>()) {
                salu_instr_common.salu_alu2_lo_bsrc_math = 1;
                salu_instr_common.salu_alu2_lo_math_src = b->phv_index(tbl);
            } else assert(0);
        } else if (auto k = srcb.to<operand::Const>()) {
            salu.salu_bsrc_phv = 0;
            if (k->value >= -8 && k->value < 8) {
                salu.salu_const_src = k->value;
                salu.salu_regfile_const = 0;
            } else {
                salu.salu_const_src = tbl->get_const(k->value);
                salu.salu_regfile_const = 1; }
        } else assert(0); }
}

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
    Instruction *pass1(Table *, Table::Actions::Action *) override { slot = ALU1LO; return this; }
    void pass2(Table *, Table::Actions::Action *) override { }
    bool equiv(Instruction *a_) override;
    void dbprint(std::ostream &out) const override{
        out << "INSTR: " << opc->name /*<< ' ' << dest << ", " << src1 << ", " << src2*/; }
    template<class REGS> void write_regs(REGS &regs, Table *tbl, Table::Actions::Action *act);
    FOR_ALL_TARGETS(FORWARD_VIRTUAL_INSTRUCTION_WRITE_REGS)
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

template<class REGS>
void BitOP::write_regs(REGS &regs, Table *tbl, Table::Actions::Action *act) {
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu = meter_group.stateful.salu_instr_state_alu[act->code][slot-2];
    salu.salu_op = opc->opcode & 0xf;
    salu.salu_pred = predication_encode;
    //1b instructions are from mem-lo to alu1-lo
    salu.salu_asrc_memory = 1;
    salu.salu_asrc_memory_index = 0;
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
    Instruction *pass1(Table *tbl, Table::Actions::Action *) override;
    void pass2(Table *tbl, Table::Actions::Action *) override { }
    bool equiv(Instruction *a_) override;
    void dbprint(std::ostream &out) const override{
        out << "INSTR: " << opc->name /*<< ' ' << dest << ", " << src1 << ", " << src2*/; }
    template<class REGS> void write_regs(REGS &regs, Table *tbl, Table::Actions::Action *act);
    FOR_ALL_TARGETS(FORWARD_VIRTUAL_INSTRUCTION_WRITE_REGS)
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
    auto tbl = dynamic_cast<Stateful *>(tbl_);
    slot = dest;
    if (srca) srca->pass1(tbl);
    if (srcb) srcb->pass1(tbl);
    if (srcc) srcc->pass1(tbl);
    return this;
}

template<class REGS>
void CmpOP::write_regs(REGS &regs, Table *tbl_, Table::Actions::Action *act) {
    auto tbl = dynamic_cast<Stateful *>(tbl_);
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu = meter_group.stateful.salu_instr_cmp_alu[act->code][slot];
    if (srca) {
        salu.salu_cmp_asrc_input = srca->field->bit(0) > 0;
        salu.salu_cmp_asrc_sign = srca_neg;
        salu.salu_cmp_asrc_enable = 1; }
    if (srcb) {
        salu.salu_cmp_bsrc_input = srcb->phv_index(tbl);
        salu.salu_cmp_bsrc_sign = srcb_neg;
        salu.salu_cmp_bsrc_enable = 1; }
    if (srcc) {
        if (srcc->value >= -8 && srcc->value < 8) {
            salu.salu_cmp_const_src = srcc->value & 0xf;
            salu.salu_cmp_regfile_const = 0;
        } else {
            salu.salu_cmp_const_src = tbl->get_const(srcc->value);
            salu.salu_cmp_regfile_const = 1; } }
    salu.salu_cmp_opcode = opc->opcode | (type << 2);
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
    enum mux_select { MEM_HI=0, MEM_LO, PHV_HI, PHV_LO, ALU_HI, ALU_LO, PRED };
    mux_select output_mux;
    static const std::map<std::string, int> ops_mux_lookup;
    OutOP(const Decode *op, int lineno) : SaluInstruction(lineno) {}
    std::string name() override { return "output"; };
    Instruction *pass1(Table *tbl, Table::Actions::Action *) override { slot = ALUOUT; return this; }
    void pass2(Table *tbl, Table::Actions::Action *) override { }
    bool equiv(Instruction *a_) override;
    void dbprint(std::ostream &out) const override {
        out << "INSTR: output " /*<< ' ' << dest << ", " << src1 << ", " << src2*/; }
    template<class REGS> void write_regs(REGS &regs, Table *tbl, Table::Actions::Action *act);
    FOR_ALL_TARGETS(FORWARD_VIRTUAL_INSTRUCTION_WRITE_REGS)
};

const std::map<std::string, int> OutOP::ops_mux_lookup = {
    { "mem_hi", MEM_HI }, { "mem_lo", MEM_LO },
    { "memory_hi", MEM_HI }, { "memory_lo", MEM_LO },
    { "phv_hi", PHV_HI }, { "phv_lo", PHV_LO },
    { "alu_hi", ALU_HI }, { "alu_lo", ALU_LO },
    { "alu_hi_out", ALU_HI }, { "alu_lo_out", ALU_LO },
    { "predicate", PRED } };

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
        } else if (op[idx] == "cmplo" || op[idx] == "cmphi" || op[idx] == "!" ||
                   op[idx] == "&" || op[idx] == "|" || op[idx] == "^") {
            rv->predication_encode = decode_predicate(op[idx++]);
            if (rv->predication_encode == STATEFUL_PREDICATION_ENCODE_NOOP)
                warning(op[idx-1].lineno, "Instruction predicate is always false");
            else if (rv->predication_encode == STATEFUL_PREDICATION_ENCODE_UNCOND)
                warning(op[idx-1].lineno, "Instruction predicate is always true"); } }
    //Check mux operand
    if (idx < op.size) {
        if (op[idx].type == tSTR &&  OutOP::ops_mux_lookup.count(op[idx].s))
            rv->output_mux = (mux_select)OutOP::ops_mux_lookup.at(op[idx].s);
        else
            error(op[idx].lineno, "invalid operand '%s' for '%s' instruction",
                  value_desc(op[idx]), op[0].s); }
    return rv;
}

template<class REGS>
void OutOP::write_regs(REGS &regs, Table *tbl, Table::Actions::Action *act) {
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &action_ctl = regs.rams.map_alu.meter_alu_group_action_ctl[logical_home_row/4U];
    auto &switch_ctl = regs.rams.array.switchbox.row[logical_home_row/2U].ctl;
    auto &action_hv_xbar = regs.rams.array.row[logical_home_row/2U].action_hv_xbar;
    auto &salu = meter_group.stateful.salu_instr_output_alu[act->code];
    salu.salu_output_cmpfn = STATEFUL_PREDICATION_ENCODE_UNCOND;
    if (predication_encode) {
        salu.salu_output_cmpfn = predication_encode;
        // Not clear if this is the best place for the rest of these -- should perhaps
        // be in stateful?  Only needed if the salu wants to output to the VLIW action data bus
        // Output onto rhs action data bus w 4 cycle delay iff selectors anywhere in this stage
        action_ctl.right_alu_action_enable = 1;
        action_ctl.right_alu_action_delay =
            tbl->stage->group_table_use[tbl->gress] & Stage::USE_SELECTOR ? 4 : 0;
        switch_ctl.r_action_o_mux_select.r_action_o_sel_action_rd_r_i = 1;
        // disable action data address huffman decoding, on the assumtion we're not trying
        // to combine this with an action data table on the same home row.  Otherwise, the
        // huffman decoding will think this is an 8-bit value and replicate it.
        action_hv_xbar.action_hv_xbar_disable_ram_adr.action_hv_xbar_disable_ram_adr_right = 1; }
    salu.salu_output_asrc = output_mux;
}

}  // end anonymous namespace
