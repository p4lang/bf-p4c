#include "action_bus.h"
#include "asm-types.h"
#include "bfas.h"
#include "phv.h"
#include "stage.h"
#include "tables.h"
#include "flatrock/instruction.h"

namespace Flatrock {

static void parse_slice(const VECTOR(value_t) &vec, int idx, int &lo, int &hi) {
    if (PCHECKTYPE2(vec.size == idx+1, vec[idx], tINT, tRANGE)) {
        if (vec[idx].type == tINT) {
            lo = hi = vec[idx].i;
        } else {
            lo = vec[idx].lo;
            hi = vec[idx].hi; } }
}

Operand::Operand(Table *tbl, const Table::Actions::Action *act, const value_t &v) : op(0) {
    if (v.type == tINT) {
        op = new Const(v.lineno, v.i);
    } else if (CHECKTYPE2(v, tSTR, tCMD)) {
        std::string name = v.type == tSTR ? v.s : v[0].s;
        std::string p4name = name;
        TableOutputModifier mod = TableOutputModifier::NONE;
        int lo = -1, hi = -1;
        if (v.type == tCMD) {
            if (v.vec.size > 1 && (v[1] == "color" || v[1] == "address")) {
                if (v[1] == "color") mod = TableOutputModifier::Color;
                if (v[1] == "address") mod = TableOutputModifier::Address;
                if (v[1].type == tCMD)
                    parse_slice(v[1].vec, 1, lo, hi);
                else if (v.vec.size > 2)
                    parse_slice(v.vec, 2, lo, hi);
            } else {
                parse_slice(v.vec, 1, lo, hi); } }
        name = act->alias_lookup(v.lineno, name, lo, hi);
        op = new Named(v.lineno, name, mod, lo, hi, tbl, act->name, p4name); }
}

auto Operand::Named::lookup(Base *&ref) -> Base * {
    int slot, len = -1;
    if (tbl->action) tbl = tbl->action;
    int lo = this->lo >= 0 ? this->lo : 0;
    if (auto *field = tbl->lookup_field(name, action)) {
        if ((unsigned)lo >= field->size) {
            error(lineno, "Bit %d out of range for field %s", lo, name.c_str());
            ref = nullptr;
        } else if (hi >= 0 && (unsigned)hi >= field->size) {
            error(lineno, "Bit %d out of range for field %s", hi, name.c_str());
            ref = nullptr;
        } else {
            ref = new Action(lineno, name, tbl, field, lo,
                             hi >= 0 ? hi : field->size - 1, p4name); }
    } else if (tbl->find_on_actionbus(name, mod, lo, hi >= 0 ? hi : 7, 0, &len) >= 0) {
        ref = new Action(lineno, name, mod, tbl, lo, hi >= 0 ? hi : len - 1, p4name);
    } else if (::Phv::get(tbl->gress, tbl->stage->stageno, name)) {
        ref = new Phv(lineno, tbl->gress, tbl->stage->stageno, name, lo, hi);
    } else if (sscanf(name.c_str(), "A%d%n", &slot, &len) >= 1 &&
               len == static_cast<int>(name.size()) && slot >= 0 && slot < 32) {
        ref = new RawAction(lineno, slot, lo);
    } else if (Table::all->count(name)) {
        ref = new Action(lineno, name, mod, tbl, lo, hi, p4name);
    } else {
        ref = new Phv(lineno, tbl->gress, tbl->stage->stageno, name, this->lo, hi); }
    if (ref != this) delete this;
    return ref;
}

static Noop                 opNoop("noop",          FLATROCK);                            // NOLINT
static PhvWrite::Decode     opSet ("set",           FLATROCK, PhvWrite::Decode::SET),     // NOLINT
                            opAndc("andc",          FLATROCK, PhvWrite::Decode::ANDC),    // NOLINT
                            opOr  ("or",            FLATROCK, PhvWrite::Decode::OR);      // NOLINT
static BitmaskSet::Decode   opSetm("bitmasked-set", FLATROCK);                            // NOLINT
static DepositField::Decode opDpf ("deposit-field", FLATROCK);                            // NOLINT
static LoadConst::Decode    opLdc ("load-const",    FLATROCK);                            // NOLINT

BitmaskSet::BitmaskSet(PhvWrite &wr, int m) : PhvWrite(wr), mask(m) { opc = &opSetm; }
DepositField::DepositField(PhvWrite &wr) : PhvWrite(wr) { opc = &opDpf; }
LoadConst::LoadConst(PhvWrite &wr) : PhvWrite(wr) { opc = &opDpf; }

PhvWrite *PhvWrite::Decode::alloc(Table *tbl, const Table::Actions::Action *act,
                                  const VECTOR(value_t) &op) const {
    return new PhvWrite(this, tbl, act, op[op.size-2], op[op.size-1]); }
PhvWrite *DepositField::Decode::alloc(Table *tbl, const Table::Actions::Action *act,
                                      const VECTOR(value_t) &op) const {
    return new DepositField(this, tbl, act, op[op.size-2], op[op.size-1]); }
PhvWrite *LoadConst::Decode::alloc(Table *tbl, const Table::Actions::Action *act,
                                   const VECTOR(value_t) &op) const {
    return new LoadConst(this, tbl, act, op[op.size-2], op[op.size-1]); }

Instruction *PhvWrite::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                      const VECTOR(value_t) &op) const {
    if (op.size != 3 && op.size != 4) {
        error(op[0].lineno, "%s requires 2 or 3 operands", op[0].s);
        return nullptr; }
    if (Operand::isActionData(op[1]))
        return nullptr;
    PhvWrite *rv = alloc(tbl, act, op);
    if (op.size == 3) {
        rv->alu_slot = rv->dest;
    } else {
        warning(op[0].lineno, "VLIW ops in adjacent slots deprecated");
        rv->alu_slot = Phv::Ref(tbl->gress, tbl->stage->stageno + 1, op[1]);
    }
    if (!rv->src.valid()) {
        error(op[2].lineno, "invalid src");
        delete rv;
        return nullptr; }
    return rv;
}

Instruction *Noop::decode(Table *tbl, const Table::Actions::Action *act,
                                 const VECTOR(value_t) &op) const {
    if (op.size != 2) {
        error(op[0].lineno, "%s requires 1 operand", op[0].s);
        return nullptr; }
    if (Operand::isActionData(op[1]))
        return nullptr;
    value_t A0{tSTR, op[1].lineno};
    A0.s = const_cast<char *>("A0");
    PhvWrite *rv = new PhvWrite(this, tbl, act, op[1], A0);
    rv->alu_slot = rv->dest;
    return rv;
}

Instruction *BitmaskSet::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                        const VECTOR(value_t) &op) const {
    if (op.size != 4 && op.size != 5) {
        error(op[0].lineno, "%s requires 3 or 4 operands", op[0].s);
        return nullptr; }
    if (Operand::isActionData(op[1]))
        return nullptr;
    if (op[op.size-1].type != tINT) {
        error(op[op.size-1].lineno, "%s mask must be a constant", op[0].s);
        return nullptr; }
    auto *rv = new BitmaskSet(this, tbl, act, op[op.size-3], op[op.size-2], op[op.size-1].i);
    if (op.size == 4) {
        rv->alu_slot = rv->dest;
    } else {
        warning(op[0].lineno, "VLIW ops in adjacent slots deprecated");
        rv->alu_slot = Phv::Ref(tbl->gress, tbl->stage->stageno + 1, op[1]);
    }
    if (!rv->src.valid()) {
        error(op[2].lineno, "invalid src");
        delete rv;
        return nullptr; }
    return rv;
}

Instruction *PhvWrite::pass1(Table *tbl, Table::Actions::Action *act) {
    if (!alu_slot.check() || !dest.check() || !src.check()) return this;
    if (dest->reg.mau_id() < 0) {
        error(dest.lineno, "%s not accessable in mau", dest->reg.name);
        return this; }
    if (alu_slot->reg.mau_id() < 0) {
        error(alu_slot.lineno, "%s not accessable in mau", alu_slot->reg.name);
        return this; }
    slot = alu_slot->reg.mau_id();
    if (static_cast<unsigned>(dest->reg.mau_id() - slot) > MAX_MERGE_DEST) {
        error(lineno, "Can't write to %s using PhvWrite for %s",
              dest->reg.name, alu_slot->reg.name); }
    int hi = Phv::reg(slot)->size - 1;
    int maxconst = hi == 7 ? 256 : hi == 15 ? 16 : 8;
    auto *k = src.to<Operand::Const>();
    // FIXME -- invalid 'set' instructions might be implementable by converting them
    // to load-const, deposit-field, or bitmasked-set
    if (opc->opcode == Decode::SET) {
        // set instruction rewrites -- to bitmasked-set, deposit-field, or load-const if needed
        if (dest->lo != 0 || dest->hi != hi) {
            return (new DepositField(*this))->pass1(tbl, act);
        } else if (hi == 7) {
            // 8-bit set becomes bitmasked-set
            return (new BitmaskSet(*this, 0xff))->pass1(tbl, act);
        } else if (k && (k->value >= maxconst || k->value < -maxconst)) {
            return (new LoadConst(*this))->pass1(tbl, act);
        }
    }
    if (opc->opcode < 4 && (dest->lo != 0 || dest->hi != hi))
        error(dest.lineno, "%s can't write to slice of destination", opc->name.c_str());
    tbl->stage->action_set[tbl->gress][dest->reg.uid] = true;
    if (opc->opcode != Decode::LDC) {
        // loadconst has different limits on the size of the constant, checked below
        src->pass1(tbl, slot); }
    return this;
}
Instruction *LoadConst::pass1(Table *tbl, Table::Actions::Action *act) {
    PhvWrite::pass1(tbl, act);
    if (auto *k = src.to<Operand::Const>()) {
        switch (Phv::reg(slot)->size) {
        case 8:
            error(dest.lineno, "load-const not usable on 8-bit containers"
                  " (use setbm with all ones mask instead)");
            break;
        case 16:
            if (k->value < -32768 || k->value > 65535)
                error(src->lineno, "%" PRId64 " out of range for load-const", k->value);
            break;
        case 32:
            if (k->value < 0 || k->value >= 0x80000)
                error(src->lineno, "%" PRId64 " out of range for load-const", k->value);
            break;
        default:
            BUG("invalid PHE size %d", Phv::reg(slot)->size); }
    } else {
        error(src->lineno, "load-const source is not a constant?"); }
    return this;
}

bool PhvWrite::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<PhvWrite *>(a_)) {
        return opc == a->opc && dest == a->dest && src == a->src;
    } else {
        return false;
    }
}

uint32_t PhvWrite::encode() {
    uint32_t rv = src->bits(slot);
    int merge_dest = dest->reg.mau_id() - slot;
    BUG_CHECK(merge_dest == 0, "merge in PHV write not supported");
    switch (Phv::reg(slot)->size) {
    case 8:
        rv |= opc->opcode << 15;
        break;
    case 16:
        rv |= opc->opcode << 15;
        break;
    case 32:
        rv |= opc->opcode << 17;
        break;
    default:
        BUG("invalid register size");
    }
    return rv;
}
uint32_t BitmaskSet::encode() {
    uint32_t rv = PhvWrite::encode();
    BUG_CHECK(Phv::reg(slot)->size == 8, "bitmasked-set not 8 bits");
    rv |= (mask^0xff) << 9;
    return rv;
}
uint32_t DepositField::encode() {
    uint32_t rv = PhvWrite::encode();
    switch (Phv::reg(slot)->size) {
    case 8:
        rv |= ((src->bit_offset(slot) - dest->lo) & 7) << 9;
        rv |= dest->lo << 12;
        rv |= dest->hi << 15;
        break;
    case 16:
        rv |= ((src->bit_offset(slot) - dest->lo) & 15) << 6;
        rv |= dest->lo << 10;
        rv |= dest->hi << 14;
        break;
    case 32:
        rv |= ((src->bit_offset(slot) - dest->lo) & 31) << 5;
        rv |= dest->lo << 10;
        rv |= dest->hi << 15;
        break;
    default:
        BUG("invalid register size");
    }
    return rv;
}
uint32_t LoadConst::encode() {
    uint32_t rv = src.to<Operand::Const>()->value;
    int merge_dest = dest->reg.mau_id() - slot;
    BUG_CHECK(merge_dest == 0, "merge in PHV write not supported");
    switch (Phv::reg(slot)->size) {
    case 16:
        rv &= 0xffff;
        rv |= opc->opcode << 15;
        break;
    case 32:
        rv &= 0x7ffff;
        rv |= opc->opcode << 17;
        break;
    default:
        BUG("invalid register size");
    }
    return rv;
}

void VLIWInstruction::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
                                 Table::Actions::Action *act) {
    if (act != tbl->stage->imem_addr_use[tbl->gress][act->addr]) {
        LOG3("skipping " << tbl->name() << '.' << act->name << " as its imem is used by " <<
             tbl->stage->imem_addr_use[tbl->gress][act->addr]->name);
        return; }
    LOG2(this);
    auto &imem = regs.ppu_phvwr.imem;
    int iaddr = act->addr / Target::Flatrock::IMEM_COLORS;
    int color = act->addr % Target::Flatrock::IMEM_COLORS;
    uint32_t bits = encode(), delta = bits;
    BUG_CHECK(slot >= 0);
    switch (Phv::reg(slot)->size) {
    case 8:
        delta = imem.imem8[slot].phvwr_imem8[iaddr];
        imem.imem8[slot].phvwr_imem8[iaddr].color = color;
        imem.imem8[slot].phvwr_imem8[iaddr].instr = bits;
        delta ^= imem.imem8[slot].phvwr_imem8[iaddr];
        break;
    case 16:
        slot -= imem.imem8.size();
        delta = imem.imem16[slot].phvwr_imem16[iaddr];
        imem.imem16[slot].phvwr_imem16[iaddr].color = color;
        imem.imem16[slot].phvwr_imem16[iaddr].instr = bits;
        delta ^= imem.imem16[slot].phvwr_imem16[iaddr];
        break;
    case 32:
        slot -= imem.imem8.size() + imem.imem16.size();
        delta = imem.imem32[slot].phvwr_imem32[iaddr];
        imem.imem32[slot].phvwr_imem32[iaddr].color = color;
        imem.imem32[slot].phvwr_imem32[iaddr].instr = bits;
        delta ^= imem.imem32[slot].phvwr_imem32[iaddr];
        break;
    default:
        BUG(); }
    regs.ppu_phvwr.rf.phvwr_parity[iaddr].parity[color] ^= parity_2b(delta);
}

namespace EALU {

// The following instruction table for the Flatrock PPU is identical to the
// instruction table for tofino123.  Note: these instruction must be
// instantiated after the PhvWrite instructions, as instruction is decoded as
// PhvWrite instructions first. If that failed, it is then decoded as Ealu
// instructions.
//                                   OPNAME            OPCODE
static AluOP::Decode     opADD      ("add",   FLATROCK, 0x23e,  AluOP::Commutative),               // NOLINT
                         opADDC     ("addc",  FLATROCK, 0x2be,  AluOP::Commutative),               // NOLINT
                         opSUB      ("sub",   FLATROCK, 0x33e),                                    // NOLINT
                         opSUBC     ("subc",  FLATROCK, 0x3be),                                    // NOLINT
                         opSADDU    ("saddu", FLATROCK, 0x03e,  AluOP::Commutative),               // NOLINT
                         opSADDS    ("sadds", FLATROCK, 0x07e,  AluOP::Commutative),               // NOLINT
                         opSSUBU    ("ssubu", FLATROCK, 0x0be),                                    // NOLINT
                         opSSUBS    ("ssubs", FLATROCK, 0x0fe),                                    // NOLINT
                         opMINU     ("minu",  FLATROCK, 0x13e,  AluOP::Commutative),               // NOLINT
                         opMINS     ("mins",  FLATROCK, 0x17e,  AluOP::Commutative),               // NOLINT
                         opMAXU     ("maxu",  FLATROCK, 0x1be,  AluOP::Commutative),               // NOLINT
                         opMAXS     ("maxs",  FLATROCK, 0x1fe,  AluOP::Commutative),               // NOLINT
                         opSETZ     ("setz",  FLATROCK, 0x01e,  AluOP::Commutative+AluOP::IgnoreSrcs), // NOLINT
                         opNOR      ("nor",   FLATROCK, 0x05e,  AluOP::Commutative),               // NOLINT
                         opANDCA    ("andca", FLATROCK, 0x09e,  AluOP::CanSliceWithConst),         // NOLINT
                         opANDCB    ("andcb", FLATROCK, 0x11e,  &opANDCA),                         // NOLINT
                         opNOTB     ("notb",  FLATROCK, 0x15e,  AluOP::IgnoreSrc1,  "not"),        // NOLINT
                         opNOTA     ("nota",  FLATROCK, 0x0de,  AluOP::IgnoreSrc2,  &opNOTB),      // NOLINT
                         opXOR      ("xor",   FLATROCK, 0x19e,  AluOP::Commutative+AluOP::CanSliceWithConst), // NOLINT
                         opNAND     ("nand",  FLATROCK, 0x1de,  AluOP::Commutative),               // NOLINT
                         opAND      ("and",   FLATROCK, 0x21e,  AluOP::Commutative),               // NOLINT
                         opXNOR     ("xnor",  FLATROCK, 0x25e,  AluOP::Commutative),               // NOLINT
                         opB        ("alu_b", FLATROCK, 0x29e,  AluOP::IgnoreSrc1),                // NOLINT
                         opORCA     ("orca",  FLATROCK, 0x2de),                                    // NOLINT
                         opA        ("alu_a", FLATROCK, 0x31e,  AluOP::IgnoreSrc2,  &opB),         // NOLINT
                         opORCB     ("orcb",  FLATROCK, 0x35e,  &opORCA),                          // NOLINT
                         opOR       ("or",    FLATROCK, 0x39e,  AluOP::Commutative+AluOP::CanSliceWithConst), // NOLINT
                         opSETHI    ("sethi", FLATROCK, 0x3de,  AluOP::Commutative+AluOP::IgnoreSrcs),        // NOLINT
                         opGTEQU    ("gtequ", FLATROCK, 0x02e),                                    // NOLINT
                         opGTEQS    ("gteqs", FLATROCK, 0x06e),                                    // NOLINT
                         opLTU      ("ltu",   FLATROCK, 0x0ae),                                    // NOLINT
                         opLTS      ("lts",   FLATROCK, 0x0ee),                                    // NOLINT
                         opLEQU     ("lequ",  FLATROCK, 0x12e, &opGTEQU),                          // NOLINT
                         opLEQS     ("leqs",  FLATROCK, 0x16e, &opGTEQS),                          // NOLINT
                         opGTU      ("gtu",   FLATROCK, 0x1ae, &opLTU),                            // NOLINT
                         opGTS      ("gts",   FLATROCK, 0x1ee, &opLTS),                            // NOLINT
                         opEQ       ("eq",    FLATROCK, 0x22e, AluOP::Commutative),                // NOLINT
                         opNEQ      ("neq",   FLATROCK, 0x2ae, AluOP::Commutative),                // NOLINT
                         opEQ64     ("eq64",  FLATROCK, 0x26e, AluOP::Commutative),                // NOLINT
                         opNEQ64    ("neq64", FLATROCK, 0x2ee, AluOP::Commutative);                // NOLINT
static ShiftOP::Decode   opSHL      ("shl",   FLATROCK, 0x0c,       false),                        // NOLINT
                         opSHRS     ("shrs",  FLATROCK, 0x1c,       false),                        // NOLINT
                         opSHRU     ("shru",  FLATROCK, 0x14,       false),                        // NOLINT
                         opFUNSHIFT ("funnel-shift", FLATROCK, 0x4,   true);                       // NOLINT

static LoadConst::Decode    ealuOpLdc     ("load-const",        FLATROCK, 0x8);                    // NOLINT
static Set::Decode          ealuOpSet     ("set",               FLATROCK, 0x6);                    // NOLINT
static BitmaskSet::Decode   ealuOpSetm    ("bitmasked-set",     FLATROCK, 1);                      // NOLINT
static ByteRotateMerge::Decode  ealuOpBrm ("byte-rotate-merge", FLATROCK, 0xa);                    // NOLINT
static DepositField::Decode ealuOpDeposit ("deposit-field",     FLATROCK, 0x1);                    // NOLINT


// Decode destination field for EALU instructions to instr_word and instr_width
bool EALUInstruction::decode_dest(const value_t &v) {
    if (!CHECKTYPE(v, tSTR)) return false;
    // match on "Ax", "EALU8[x]", "EALU16[x]", "EALU32[x]" to identify EALU outputs
    int slot, len = -1;
    if (sscanf(v.s, "A%d%n", &slot, &len) >= 1 && v.s[len] == '\0') {
        if (slot >= 0 && slot < 4) {
            instr_width = 8;
            instr_word = slot;
            return true;
        } else if (slot == 4 || slot == 6) {
            instr_width = 16;
            instr_word = slot;
            return true;
        } else if (slot == 16 || slot == 20) {
            instr_width = 32;
            instr_word = slot;
            return true;
        } else {
            return false;
        }
    } else if (sscanf(v.s, "EALU8[%d]%n", &slot, &len) >= 1 && len == strlen(v.s) && slot >= 0 &&
               slot < Target::EXTEND_ALU_8_SLOTS()) {
        instr_width = 8;
        instr_word = slot;
        return true;
    } else if (sscanf(v.s, "EALU16[%d]%n", &slot, &len) >= 1 && len == strlen(v.s) && slot >= 0 &&
               slot < Target::EXTEND_ALU_16_SLOTS()) {
        instr_width = 16;
        instr_word = slot;
        return true;
    } else if (sscanf(v.s, "EALU32[%d]%n", &slot, &len) >= 1 && len == strlen(v.s) && slot >= 0 &&
               slot < Target::EXTEND_ALU_32_SLOTS()) {
        instr_width = 32;
        instr_word = slot;
        return true; }
    return false;
}

Instruction* AluOP::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                   const VECTOR(value_t) &op) const {
    AluOP *rv;
    if (op.size == 4) {
        rv = new AluOP(this, tbl, act, op.data[1], op.data[2], op.data[3]);
    } else if (op.size == 3) {
        if (!(flags & IgnoreSrc1) && (flags & IgnoreSrc2)) {
            rv = new AluOP(this, tbl, act, op.data[1], op.data[2], op.data[2]);
            rv->ignoreSrc2 = true;
        } else {
            rv = new AluOP(this, tbl, act, op.data[1], op.data[1], op.data[2]);
            rv->ignoreSrc1 = (flags & IgnoreSrc1) != 0; }
    } else if (op.size == 2 && (flags & IgnoreSrc1) && (flags & IgnoreSrc2)) {
        rv = new AluOP(this, tbl, act, op.data[1], op.data[1], op.data[1]);
        rv->ignoreSrc1 = rv->ignoreSrc2 = true;
    } else {
        error(op[0].lineno, "%s requires 2 or 3 operands", op[0].s);
        return nullptr; }
    if (!rv->src1.valid())
        error(op[2].lineno, "invalid src1");
    else if (!rv->src2.valid())
        error(op[3].lineno, "invalid src2");
    else
        return rv;
    delete rv;
    return nullptr;
}

Instruction* AluOP::pass1(Table *tbl, Table::Actions::Action *act) {
    if (dest->phv())
        error(lineno, "dest must be action data");
    if (!dest->check()) return this;
    if (!ignoreSrc1 && !src1->check()) return this;
    if (!ignoreSrc2 && !src2->check()) return this;

    if (!ignoreSrc1) src1->pass1(tbl, instr_word);
    if (!ignoreSrc2) src2->pass1(tbl, instr_word);

    if (!ignoreSrc2 && !src2->phv() && opc->swap_args) {
        std::swap(src1, src2);
        std::swap(ignoreSrc1, ignoreSrc2);
        opc = opc->swap_args; }

    if (!ignoreSrc2 && !src2->phv())
        error(lineno, "src2 must be phv register");
    return this;
}

uint32_t AluOP::encode() {
    uint32_t rv = (opc->opcode << 11);
    if (!ignoreSrc1)
        rv |= (src1->bits(instr_word) << 5);
    // set srci
    return rv;
}

bool AluOP::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<AluOP *>(a_)) {
        return opc == a->opc && ignoreSrc1 == a->ignoreSrc1 && ignoreSrc2 == a->ignoreSrc2 &&
               src1 == a->src1 && src2 == a->src2 && dest == a->dest;
    } else {
        return false;
    }
}

Instruction *LoadConst::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                           const VECTOR(value_t) &op) const {
    if (op.size != 3) {
        error(op[0].lineno, "%s requires 2 operands", op[0].s);
        return nullptr; }
    if (!CHECKTYPE(op[2], tINT)) return nullptr;
    auto *rv = new LoadConst(tbl, act, op.data[1], op.data[2].i);
    if (!rv->dest.valid()) {
        error(op[1].lineno, "invalid dest");
        delete rv;
        return nullptr; }
    return rv;
}

Instruction *LoadConst::pass1(Table *tbl, Table::Actions::Action *act) {
    if (dest->phv())
        error(lineno, "dest must be action data");
    if (!dest->check()) return this;
    int size = instr_width;
    int minval = -1 << (size - 1);
    if (size > 21) {
        size = 21;
        minval = 0; }
    // For an 8 or 16 bit PHV, the constant to load is 8 (or 16) bits, so
    // there's no need for sign extension to deal with a negative value.  For
    // 32 bit PHVs, the constant is 21 bits and zero-extended to 32 bits, so
    // must be positive.
    if (src >= (1 << size) || src < minval)
        error(lineno, "Constant value %d out of range", src);
    src &= (1 << size) - 1;
    return this;
}

uint32_t LoadConst::encode() {
    return Target::encodeConst(src);
}

bool LoadConst::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<LoadConst *>(a_)) {
        return dest == a->dest && src == a->src;
    } else {
        return false;
    }
}

Instruction *ShiftOP::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                     const value_t_VECTOR &op) const {
    if (op.size != (use_src1 ? 5 : 4)) {
        error(op[0].lineno, "%s requires %d operands", op[0].s, use_src1 ? 4 : 3);
        return nullptr; }
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
    return nullptr;
}

Instruction *ShiftOP::pass1(Table *tbl, Table::Actions::Action *) {
    if (dest->phv())
        error(lineno, "dest must be action data");
    if (!dest.check()) return this;
    if (!src1.check() || !src2.check()) return this;
    src1->pass1(tbl, slot/Phv::mau_groupsize());
    src2->pass1(tbl, slot/Phv::mau_groupsize());
    if (!src2.phv())
        error(lineno, "src%s must be phv register", opc->use_src1 ? "2" : "");
    return this;
}

uint32_t ShiftOP::encode() {
    int rv = (shift << 17) | (opc->opcode << 11);
    if (opc->use_src1) rv |= src1->bits(instr_word);
    rv <<= 5;
    return rv | src2->bits(instr_word);
}

bool ShiftOP::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<ShiftOP *>(a_)) {
        return opc == a->opc && dest == a->dest && src1 == a->src1 && src2 == a->src2 &&
               shift == a->shift;
    } else {
        return false;
    }
}

Instruction *Set::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                 const VECTOR(value_t) &op) const {
    if (op.size != 3) {
        error(op[0].lineno, "%s requires 2 operands", op[0].s);
        return nullptr; }
    Set *rv = new Set(this, tbl, act, op[1], op[2]);
    if (!rv->src.valid()) {
        error(op[2].lineno, "invalid src");
        delete rv;
        return nullptr; }
    return rv;
}

Instruction *Set::pass1(Table *tbl, Table::Actions::Action *act) {
    if (dest->phv())
        error(lineno, "dest must be action data");
    if (!dest.check() || !src.check()) return this;
    if (auto *k = src.to<Operand::Const>()) {
        int minsignconst = Target::MINIMUM_INSTR_CONSTANT();
        // Translate large value with negative value, e.g. 0xFFFE -> -2 on 16-bit PHV
        int64_t maxvalue = 1LL << instr_width;
        int64_t delta = k->value - maxvalue;
        if (delta >= minsignconst)
            k->value = delta;
        if (k->value < minsignconst || k->value >= 8)
            return (new LoadConst(tbl, act, dest, k->value))->pass1(tbl, act); }
    src->pass1(tbl, instr_word);
    return this;
}

uint32_t Set::encode() {
    uint32_t rv = opc->opcode << 11;
    rv |= src->bits(instr_word) << 5;
    if (chain)
        rv |= 1 << 24;
    if (priority >= 0)
        rv |= priority & 0x7;
    return rv;
}

bool Set::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<Set *>(a_)) {
        return dest == a->dest && src == a->src;
    } else {
        return false;
    }
}

Instruction *BitmaskSet::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                            const VECTOR(value_t) &op) const {
    if (op.size != 4 && op.size != 5) {
        error(op[0].lineno, "%s requires 3 or 4 operands", op[0].s);
        return nullptr; }
    if (!CHECKTYPE(op[op.size - 1], tINT)) {
        error(op[op.size-1].lineno, "%s mask must be a constant", op[0].s);
        return nullptr; }
    auto *rv = new BitmaskSet(this, tbl, act, op.data[op.size - 3], op.data[op.size - 2],
                              op.data[op.size - 1].i);
    if (!rv->dest.valid())
        error(op[1].lineno, "invalid dest");
    else
        return rv;
    delete rv;
    return nullptr;
}

Instruction *BitmaskSet::pass1(Table *tbl, Table::Actions::Action *act) {
    if (dest->phv())
        error(lineno, "dest must be action data");
    if (!dest->check()) return this;
    // only applicable to 8b action data
    if (instr_width != 8) {
        error(lineno, "bitmasked-set only applicable to 8b action data");
        return this; }
    return this;
}

uint32_t BitmaskSet::encode() {
    uint32_t rv = 1 << 21;
    rv |= mask << 11;
    rv |= (src1->bits(instr_word) << 5);
    if (chain)
        rv |= 1 << 22;
    if (priority >= 0)
        rv |= priority & 0x7;
    return rv;
}

bool BitmaskSet::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<BitmaskSet *>(a_)) {
        return dest == a->dest && src1 == a->src1 && mask == a->mask &&
               chain == a->chain && priority == a->priority;
    } else {
        return false;
    }
}

Instruction *ByteRotateMerge::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                             const VECTOR(value_t) &op) const {
    if (op.size != 6) {
        error(op[0].lineno, "%s requires 6 operands", op[0].s);
        return nullptr; }
    auto *rv = new ByteRotateMerge(this, tbl, act, op.data[1], op.data[2], op.data[3].i,
                                   op.data[4].i, op.data[5].i);
    if (!rv->dest.valid())
        error(op[1].lineno, "invalid dest");
    else
        return rv;
    delete rv;
    return nullptr;
}

Instruction *ByteRotateMerge::pass1(Table *tbl, Table::Actions::Action *act) {
    if (dest->phv())
        error(lineno, "dest must be action data");
    if (!dest->check()) return this;
    return this;
}

uint32_t ByteRotateMerge::encode() {
    // only applicable to 16 and 32
    if (instr_width != 16 && instr_width != 32) {
        error(lineno, "byte-rotate-merge only applicable to 16b and 32b action data");
        return 0; }
    uint32_t rv = opc->opcode << 11;
    rv |= src1->bits(instr_word) << 5;
    switch (instr_width) {
    case 16:
        rv |= mask & 0x3 << 15;
        rv |= rot1 & 0x1 << 22;
        rv |= rot2 & 0x1 << 20;
        break;
    case 32:
        rv |= mask & 0xf << 15;
        rv |= rot1 & 0x3 << 22;
        rv |= rot2 & 0x3 << 20;
        break;
    }
    return rv;
}

bool ByteRotateMerge::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<ByteRotateMerge *>(a_)) {
        return dest == a->dest && src1 == a->src1;
    } else {
        return false;
    }
}

Instruction *DepositField::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                          const VECTOR(value_t) &op) const {
    if (op.size != 4) {
        error(op[0].lineno, "%s requires 3 operands", op[0].s);
        return nullptr; }
    auto *rv = new DepositField(this, tbl, act, op.data[1], op.data[2], op.data[3]);
    if (!rv->dest.valid())
        error(op[1].lineno, "invalid dest");
    else
        return rv;
    delete rv;
    return nullptr;
}

Instruction *DepositField::pass1(Table *tbl, Table::Actions::Action *act) {
    if (dest->phv())
        error(lineno, "dest must be action data");
    if (!dest->check()) return this;
    return this;
}

uint32_t DepositField::encode() {
    uint32_t rv = 1 << 11;
    rv |= (src1->bits(instr_word) << 5);
    if (priority >= 0)
        rv |= priority & 0x7;
    if (chain)
        rv |= 1 << 22;
    switch (instr_width) {
    case 8:
        rv |= (hibit & 0x7) << 12;
        rv |= (lobit & 3) << 15;
        rv |= (lobit & ~3) << 20;
        rv |= (rot & 0x7) << 17;
        break;
    case 16:
        rv |= (hibit & 0xf) << 12;
        rv |= (lobit & 0x1) << 16;
        rv |= (lobit & ~1) << 21;
        rv |= (rot & 0xf) << 17;
        break;
    case 32:
        rv |= (hibit & 0x1f) << 12;
        rv |= (lobit & 0x1f) << 22;
        rv |= (rot & 0x1f) << 17;
        break;
    }
    return rv;
}

bool DepositField::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<DepositField *>(a_)) {
        return dest == a->dest && src1 == a->src1;
    } else {
        return false;
    }
}

void EALUInstruction::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
                                 Table::Actions::Action *act) {
    auto &imem = regs.ppu_phvwr.imem;
    int iaddr = act->addr / Target::Flatrock::IMEM_COLORS;
    int color = act->addr % Target::Flatrock::IMEM_COLORS;
    uint32_t bits = encode();
    BUG_CHECK(instr_word >= 0);

    LOG2(*this);
    // Use ealu class to convert slot to ealu size
    switch (instr_width) {
    case 8:
        // 8b ealu is 4 slots: A0, A1, A2, A3
        imem.eaimem8[instr_word].ealu_imem8[iaddr].color = color;
        imem.eaimem8[instr_word].ealu_imem8[iaddr].instr = bits;
        break;
    case 16:
        // 16b ealu is 2 slots: A4 and A6;
        instr_word -= 4;
        instr_word /= 2;
        imem.eaimem16[instr_word].ealu_imem16[iaddr].color = color;
        imem.eaimem16[instr_word].ealu_imem16[iaddr].instr = bits;
        break;
    case 32:
        // 32b ealu is 2 slots: A16 and A20
        instr_word -= 16;
        instr_word /= 4;
        imem.eaimem32[instr_word].ealu_imem32[iaddr].color = color;
        imem.eaimem32[instr_word].ealu_imem32[iaddr].instr = bits;
        break;
    default:
        BUG();
    }

    // ealu_parity
    // ealu_eaimem_mask
    // ealu_cfg
}

}  // namespace EALU

}  // end namespace Flatrock
