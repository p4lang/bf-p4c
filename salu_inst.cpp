#include "instruction.h"
#include "phv.h"
#include "tables.h"
#include "stage.h"

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
        ::Phv::Ref      reg;
        Phv *clone() const override { return new Phv(*this); }
        Phv(gress_t gress, const value_t &v) : Base(v.lineno), reg(gress, v) {}
        void dbprint(std::ostream &out) const override { out << reg; }
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const Phv *>(a_)) {
                return reg == a->reg;
            } else return false; }
        const char *kind() const override { return "phv"; }
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
    struct MathFn : public Base {
        Base    *of;
        MathFn *clone() const override { return new MathFn(*this); }
        MathFn(int line, Base *of) : Base(line), of(of) {}
        void dbprint(std::ostream &out) const override { out << "math(" << *of << ")";; }
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const MathFn *>(a_)) {
                return of->equiv(a->of);
            } else return false; }
        const char *kind() const override { return "math fn"; }
    };
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

operand::operand(Table *tbl, const Table::Actions::Action *act, const value_t &v_) : op(nullptr) {
    const value_t *v = &v_;
    if (v->type == tCMD && (*v == "-" || *v == "!")) {
        neg = true;
        v = &v->vec[1]; }
    if (CHECKTYPE2(*v, tINT, tSTR)) {
        if (v->type == tINT)
            op = new Const(v->lineno, v->i);
        else if (auto f = tbl->format->field(v->s))
            op = new Memory(v->lineno, tbl, f);
        else
            op = new Phv(tbl->gress, *v); }
}

enum salu_slot_use {
    CMPLO, CMPHI,
    ALU2LO, ALU1LO, ALU2HI, ALU1HI,
};

struct AluOP : public Instruction {
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
    AluOP(const Decode *op, int l) : Instruction(l), opc(op) {}
    Instruction *pass1(Table *tbl, Table::Actions::Action *) override;
    void pass2(Table *tbl, Table::Actions::Action *)  override { }
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const Phv::Slice &sl)>) { }
    void dbprint(std::ostream &out) const {
        out << "INSTR: " << opc->name /*<< ' ' << dest << ", " << src1 << ", " << src2*/; }
    template<class REGS> void write_regs(REGS &regs, Table *tbl, Table::Actions::Action *act);
    void write_regs(Target::Tofino::mau_regs &regs, Table *tbl,
                    Table::Actions::Action *act) override {
        write_regs<Target::Tofino::mau_regs>(regs, tbl, act); }
    void write_regs(Target::JBay::mau_regs &regs, Table *tbl,
                    Table::Actions::Action *act) override {
        write_regs<Target::JBay::mau_regs>(regs, tbl, act); }
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
    int idx = 1;
    if (idx < op.size && op[idx].type == tINT) {
        rv->predication_encode = op[idx++].i;
    } else if (idx < op.size && op[idx] == "!") {
        assert(op[idx].type == tCMD && op[idx].vec.size == 2);
        if (op[idx][1] == "cmplo")
            rv->predication_encode = STATEFUL_PREDICATION_ENCODE_NOTCMPLO;
        else if (op[idx][1] == "cmphi")
            rv->predication_encode = STATEFUL_PREDICATION_ENCODE_NOTCMPHI;
        else
            error(op[idx].lineno, "Unknown predicate !%s", value_desc(op[idx][1]));
        idx++;
    } else if (idx < op.size && op[idx] == "cmplo") {
        rv->predication_encode = STATEFUL_PREDICATION_ENCODE_CMPLO;
        idx++;
    } else if (idx < op.size && op[idx] == "cmphi") {
        rv->predication_encode = STATEFUL_PREDICATION_ENCODE_CMPHI;
        idx++; }
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
        rv->opc = swap_args;
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

Instruction *AluOP::pass1(Table *tbl, Table::Actions::Action *act) {
    if (slot < 0 && act->slot_use[slot = (dest ? ALU1HI : ALU1LO)])
        slot = dest ? ALU2HI : ALU2LO;
    auto k1 = srca.to<operand::Const>();
    auto k2 = srcb.to<operand::Const>();
    if (k1 && k2 && k1->value != k2->value)
        error(lineno, "can only have one distinct constant in an SALU instruction");
    if (!k1) k1 = k2;
    if (k1 && (k1->value < -8 || k1->value >= 8))
        dynamic_cast<Stateful *>(tbl)->get_const(k1->value);
    if (auto p = srcb.to<operand::Phv>())
        p->reg.check();
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
        if (/*auto f =*/ srcb.to<operand::Phv>()) {
            salu.salu_bsrc_phv = 1;
            salu.salu_bsrc_phv_index = 0;  // FIXME
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

struct BitOP : public Instruction {
    const struct Decode : public Instruction::Decode {
        std::string name;
        unsigned opcode;
        Decode(const char *n, unsigned opc)
        : Instruction::Decode(n, STATEFUL_ALU), name(n), opcode(opc) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    } *opc;
    int predication_encode = STATEFUL_PREDICATION_ENCODE_UNCOND;
    BitOP(const Decode *op, int lineno) : Instruction(lineno), opc(op) {}
    Instruction *pass1(Table *tbl, Table::Actions::Action *) override { slot = ALU1LO; return this; }
    void pass2(Table *tbl, Table::Actions::Action *) override { }
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const Phv::Slice &sl)>) { }
    void dbprint(std::ostream &out) const {
        out << "INSTR: " << opc->name /*<< ' ' << dest << ", " << src1 << ", " << src2*/; }
    template<class REGS> void write_regs(REGS &regs, Table *tbl, Table::Actions::Action *act);
    void write_regs(Target::Tofino::mau_regs &regs, Table *tbl,
                    Table::Actions::Action *act) override {
        write_regs<Target::Tofino::mau_regs>(regs, tbl, act); }
    void write_regs(Target::JBay::mau_regs &regs, Table *tbl,
                    Table::Actions::Action *act) override {
        write_regs<Target::JBay::mau_regs>(regs, tbl, act); }
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

struct CmpOP : public Instruction {
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
    CmpOP(const Decode *op, int lineno) : Instruction(lineno), opc(op) {}
    Instruction *pass1(Table *tbl, Table::Actions::Action *) override;
    void pass2(Table *tbl, Table::Actions::Action *) override { }
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const Phv::Slice &sl)>) { }
    void dbprint(std::ostream &out) const {
        out << "INSTR: " << opc->name /*<< ' ' << dest << ", " << src1 << ", " << src2*/; }
    template<class REGS> void write_regs(REGS &regs, Table *tbl, Table::Actions::Action *act);
    void write_regs(Target::Tofino::mau_regs &regs, Table *tbl,
                    Table::Actions::Action *act) override {
        write_regs<Target::Tofino::mau_regs>(regs, tbl, act); }
    void write_regs(Target::JBay::mau_regs &regs, Table *tbl,
                    Table::Actions::Action *act) override {
        write_regs<Target::JBay::mau_regs>(regs, tbl, act); }
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
        } else {
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
    slot = dest;
    if (srcb) srcb->reg.check();
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
        salu.salu_cmp_bsrc_input = 0;  // FIXME
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

}  // end anonymous namespace
