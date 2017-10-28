#include <config.h>

#include "action_bus.h"
#include "instruction.h"
#include "power_ctl.h"
#include "phv.h"
#include "tables.h"
#include "stage.h"

std::map<std::string, const Instruction::Decode *>
    Instruction::Decode::opcode[Instruction::NUM_SETS];

Instruction *Instruction::decode(Table *tbl, const Table::Actions::Action *act,
                                 const VECTOR(value_t) &op) {
    if (auto *d = ::get(Instruction::Decode::opcode[tbl->instruction_set()], op[0].s))
        return d->decode(tbl, act, op);
    if (auto p = strchr(op[0].s, '.')) {
        std::string opname(op[0].s, p - op[0].s);
        if (auto *d = ::get(Instruction::Decode::opcode[tbl->instruction_set()], opname)) {
            if (d->type_suffix)
                return d->decode(tbl, act, op); } }
    error(op[0].lineno, "Unknown instruction %s", op[0].s);
    return 0;
}

namespace {
static const int group_size[] = { 32, 32, 32, 32, 8, 8, 8, 8, 16, 16, 16, 16, 16, 16 };

struct operand {
    struct Base {
        int     lineno;
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
        virtual void pass2(int) const {}
        virtual void gen_prim_cfg(json::map& ) = 0;
    } *op;
    struct Const : Base {
        long            value;
        Const(int line, long v) : Base(line), value(v) {}
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const Const *>(a_)) {
                return value == a->value;
            } else return false; }
        Const *clone() override { return new Const(*this); }
        int bits(int group) override {
            int val = value;
            if (val > 0 && ((val >> (group_size[group] - 1)) & 1))
                val |= ~0UL << group_size[group];
            int minconst = (options.target == JBAY) ? -4 : -8;
            if (val >= minconst && val < 8)
                return value+24;
            error(lineno, "constant value %ld out of range for immediate", value);
            return -1; }
        void dbprint(std::ostream &out) const override { out << value; }
        void gen_prim_cfg(json::map& out) { 
          out["type"] = "immmediate"; 
          out["name"] = std::to_string(value);
        }
    };
    struct Phv : Base {
        ::Phv::Ref      reg;
        Phv(int line, gress_t g, const value_t &n) : Base(line), reg(g, n) {}
        Phv(int line, gress_t g, const std::string &n, int l, int h) :
            Base(line), reg(g, line, n, l, h) {}
        Phv(const ::Phv::Ref &r) : Base(r.lineno), reg(r) {}
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const Phv *>(a_)) {
                return reg == a->reg;
            } else return false; }
        Phv *clone() override { return new Phv(*this); }
        bool check() override {
            if (!reg.check()) return false;
            if (reg->reg.mau_id() < 0) {
                error(reg.lineno, "%s not accessable in mau", reg->reg.name);
                return false; }
            return true;
        }
        int phvGroup() override { return reg->reg.mau_id() / ::Phv::mau_groupsize(); }
        int bits(int group) override {
            if (group != phvGroup()) {
                error(lineno, "registers in an instruction must all be in the same phv group");
                return -1; }
            return reg->reg.mau_id() % ::Phv::mau_groupsize(); }
        unsigned bitoffset(int group) const override { return reg->lo; }
        void mark_use(Table *tbl) override {
            tbl->stage->action_use[tbl->gress][reg->reg.uid] = true; }
        void dbprint(std::ostream &out) const override { out << reg; }
        void phvRead(std::function<void (const ::Phv::Slice &sl)> fn) override { fn(*reg); }
        void gen_prim_cfg(json::map& out) { 
          out["type"] = "phv"; 
          out["name"] = reg->reg.name;
        }
    };
    struct Action : Base {
        std::string             name;
        std::string             p4name;
        Table                   *table;
        Table::Format::Field    *field;
        unsigned                lo, hi;

        Action(int line, const std::string &n, Table *tbl, Table::Format::Field *f,
               unsigned l, unsigned h) : Base(line), name(n), table(tbl), field(f), lo(l), hi(h) {}
        Action(int line, const std::string &n, Table *tbl, Table::Format::Field *f,
               unsigned l, unsigned h, const std::string &m) : 
                Base(line), name(n), p4name(m), table(tbl), field(f), lo(l), hi(h) {}
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const Action *>(a_)) {
                return name == a->name && table == a->table && field == a->field &&
                       lo == a->lo && hi == a->hi;
            } else return false; }
        Action *clone() override { return new Action(*this); }
        int bits(int group) override {
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
        void pass2(int group) const override {
            unsigned bits = group_size[group];
            unsigned bytes = bits/8U;
            if (field && table->find_on_actionbus(field, lo, bytes) < 0) {
                int immed_offset = 0;
                if (table->format && table->format->immed)
                    immed_offset = table->format->immed->bit(0);
                int l = field->bit(lo) - immed_offset, h = field->bit(hi) - immed_offset;
                if (l%bits != 0 && l/bits != h/bits)
                    error(lineno, "%s misaligned for action bus", name.c_str());
                table->need_on_actionbus(field, lo & ~7, bytes);
            } else if (!field && table->find_on_actionbus(name, lo, bytes) < 0) {
                if (Table::all.count(name))
                    table->need_on_actionbus(Table::all.at(name), lo & ~7, bytes);
                else
                    error(lineno, "Can't find any operand named %s", name.c_str()); } }
        void mark_use(Table *tbl) override {
            if (field) field->flags |= Table::Format::Field::USED_IMMED; }
        unsigned bitoffset(int group) const override {
            int size = group_size[group]/8U;
            int byte = field ? table->find_on_actionbus(field, lo, size)
                             : table->find_on_actionbus(name, lo, size);
            return 8*(byte % size) + lo % 8; }
        void dbprint(std::ostream &out) const override {
            out << name << '(' << lo << ".." << hi << ')';
            if (field)
                out << '[' << field->bits[0].lo << ':' << field->size << ", "
                    << field->group << ']'; }
        void gen_prim_cfg(json::map& out) { 
          std::string refn = "immediate";
          if (field) {
            auto fmt = field->fmt;
            if (fmt) {
                auto tbl = fmt->tbl;
                auto tbltype = tbl->table_type();
                if (tbltype == Table::ACTION) {
                    refn = "action_param";
                } 
            }
          } 
          out["type"] = refn;
          out["name"] = p4name; 
        }
    };
    struct RawAction : Base {
        int             index;
        unsigned        offset;

        RawAction(int line, int idx, unsigned off) : Base(line), index(idx), offset(off) {}
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const RawAction *>(a_)) {
                return index == a->index && offset == a->offset;
            } else return false; }
        RawAction *clone() override { return new RawAction(*this); }
        int bits(int group) override { return 0x40 + index; }
        unsigned bitoffset(int group) const override { return offset; }
        void dbprint(std::ostream &out) const override { out << 'A' << index; }
        void gen_prim_cfg(json::map& out) { /* TODO: what is this */ }
    };
    struct HashDist : Base {
        Table                   *table;
        std::vector<int>        units;

        HashDist(int line, Table *t) : Base(line), table(t) {}
        HashDist(int line, Table *t, int unit) : Base(line), table(t) { units.push_back(unit); }
        static HashDist *parse(Table *tbl, const VECTOR(value_t) &v) {
            if (v.size < 2 || v[0] != "hash_dist") return nullptr;
            auto *rv = new HashDist(v[0].lineno, tbl);
            for (int i = 1; i < v.size; ++i) {
                if (CHECKTYPE(v[i], tINT)) {
                    rv->units.push_back(v[i].i);
                } else {
                    delete rv;
                    return nullptr; } }
            return rv; }

        HashDistribution *find_hash_dist(int unit) const {
            if (auto rv = table->find_hash_dist(unit)) return rv;
            for (auto mtab : table->get_match_tables())
                if (auto rv = mtab->find_hash_dist(unit)) return rv;
            return nullptr; }
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const HashDist *>(a_)) {
                return table == a->table && units == a->units;
            } else return false; }
        HashDist *clone() override { return new HashDist(*this); }
        void pass2(int group) const override {
            if (units.size() > 2) {
                error(lineno, "Can't use more than 2 hash_dist units together in an action");
                return; }
            int size = group_size[group]/8U;
            if (units.size() == 2) {
                if (size != 4)
                    error(lineno, "Can't combine hash_dist units in %d bit operation", size*8);
                auto xbar_use = HashDistribution::IMMEDIATE_LOW;
                for (auto u : units) {
                    if (auto hd = find_hash_dist(u))
                        hd->xbar_use |= xbar_use;
                    else
                        error(lineno, "No hash dist %d in table %s", u, table->name());
                    xbar_use = HashDistribution::IMMEDIATE_HIGH; }
            } else if (auto hd = find_hash_dist(units.at(0))) {
                if (!(hd->xbar_use & HashDistribution::IMMEDIATE_HIGH))
                    hd->xbar_use |= HashDistribution::IMMEDIATE_LOW;
            } else error(lineno, "No hash dist %d in table %s", units.at(0), table->name());
            int offset = 0;
            for (auto u : units) {
                if (auto hd = find_hash_dist(u)) {
                    if (!(hd->xbar_use & HashDistribution::IMMEDIATE_LOW))
                        offset = 16;
                    if (table->find_on_actionbus(hd, offset, size) < 0)
                        table->need_on_actionbus(hd, offset, size);
                    offset = 16; } } }
        int bits(int group) override {
            int size = group_size[group]/8U;
            auto hd = find_hash_dist(units.at(0));
            int offset = hd->xbar_use & HashDistribution::IMMEDIATE_LOW ? 0 : 16;
            int byte = table->find_on_actionbus(hd, offset, size);
            if (byte < 0) {
                error(lineno, "hash dist %d is not on the action bus", hd->id);
                return -1; }
            if (size == 2) byte -= 32;
            if (byte >= 0 || byte < 32*size)
                return 0x20 + byte/size;
            error(lineno, "action bus entry %d(hash_dist %d) out of range for %d-bit access",
                  size == 2 ? byte+32 : byte, hd->id, size*8);
            return -1; }
        void dbprint(std::ostream &out) const override {
            out << "hash_dist(";
            const char *sep = "";
            for (auto u : units) {
                out << sep << u;
                sep = ", "; }
            out << ")"; }
        void gen_prim_cfg(json::map& out) { 
          out["type"] = "hash";
          out["name"] = "TODO"; // TODO: What is the name?
          // TODO: What about algorithm?
        }
    };
    struct Named : Base {
        std::string     name;
        std::string     p4name;
        int             lo, hi;
        Table           *tbl;
        std::string     action;

        Named(int line, const std::string &n, int l, int h, Table *t, const std::string &act)
        : Base(line), name(n), lo(l), hi(h), tbl(t), action(act) {}
        Named(int line, const std::string &n, int l, int h, Table *t, const std::string &act, std::string &m)
        : Base(line), name(n), p4name(m), lo(l), hi(h), tbl(t), action(act) {}
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const Named *>(a_)) {
                return name == a->name && lo == a->lo && hi == a->hi && tbl == a->tbl &&
                       action == a->action;
            } else return false; }
        Base *lookup(Base *&ref) override;
        Named *clone() override { return new Named(*this); }
        bool check() override { assert(0); return true; }
        int phvGroup() override { assert(0); return -1; }
        int bits(int group) override { assert(0); return 0; }
        unsigned bitoffset(int group) const override { assert(0); return 0; }
        void mark_use(Table *tbl) override { assert(0); }
        void dbprint(std::ostream &out) const override {
            out << name;
            if (lo >= 0) {
                out << '(' << lo;
                if (hi >= 0 && hi != lo) out << ".. " << hi;
                out << ')'; }
            out << '[' << tbl->name() << ':' << action << ']'; }
        void gen_prim_cfg(json::map& out) { /* what will be this */ }
    };
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
    template <class T> T *to() { return dynamic_cast<T *>(op->lookup(op)); }
    void gen_prim_cfg(json::map& out) { op->gen_prim_cfg(out); }
    
};

operand::operand(Table *tbl, const Table::Actions::Action *act, const value_t &v) : op(0) {
    if (v.type == tINT) {
        op = new Const(v.lineno, v.i);
    } else if (CHECKTYPE2(v, tSTR, tCMD)) {
        std::string name = v.type == tSTR ? v.s : v[0].s;
        std::string p4name = name;
        int lo = -1, hi = -1;
        if (v.type == tCMD) {
            if (v == "hash_dist" && (op = HashDist::parse(tbl, v.vec)))
                return;
            if (!PCHECKTYPE2(v.vec.size == 2, v[1], tINT, tRANGE)) return;
            if (v[1].type == tINT) lo = hi = v[1].i;
            else {
                lo = v[1].lo;
                hi = v[1].hi; } }
        while (act->alias.count(name)) {
            auto &alias = act->alias.at(name);
            if (lo >= 0) {
                if (alias.lo >= 0) {
                    lo += alias.lo;
                    hi += alias.lo;
                    if (alias.hi >= 0 && hi > alias.hi)
                        error(v.lineno, "invalid bitslice of %s", name.c_str()); }
            } else {
                lo = alias.lo;
                hi = alias.hi; }
            name = alias.name; }
        op = new Named(v.lineno, name, lo, hi, tbl, act->name, p4name); }
}

auto operand::Named::lookup(Base *&ref) -> Base * {
    int slot, len = -1;
    if (tbl->action) tbl = tbl->action;
    if (auto *field = tbl->lookup_field(name, action)) {
        if (!options.match_compiler) {
            /* FIXME -- The old compiler generates refs past the end of action table fields
             * like these, and just accesses whatever bits happen to be there.  So we
             * supress these error checks for compatibility (ex: tests/action_bus1.p4) */
            if (lo >= 0 && (unsigned)lo >= field->size) {
                error(lineno, "Bit %d out of range for field %s", lo, name.c_str());
                ref = 0;
            } else if (hi >= 0 && (unsigned)hi >= field->size) {
                error(lineno, "Bit %d out of range for field %s", hi, name.c_str());
                ref = 0; } }
        if (ref) {
            ref = new Action(lineno, name, tbl, field, lo >= 0 ? lo : 0,
                             hi >= 0 ? hi : field->size - 1, p4name);
        }
    } else if (tbl->find_on_actionbus(name, lo >= 0 ? lo : 0, 7, &len) >= 0) {
        ref = new Action(lineno, name, tbl, 0, lo >= 0 ? lo : 0,
                         hi >= 0 ? hi : len - 1, p4name);
    } else if (::Phv::get(tbl->gress, name)) {
        ref = new Phv(lineno, tbl->gress, name, lo, hi);
    } else if (sscanf(name.c_str(), "A%d%n", &slot, &len) >= 1 &&
               len == (int)name.size() && slot >= 0 && slot < 32) {
        ref = new RawAction(lineno, slot, lo >= 0 ? lo : 0);
    } else if (name == "hash_dist" && lo == hi) {
        ref = new HashDist(lineno, tbl, lo);
    } else if (Table::all.count(name)) {
        ref = new Action(lineno, name, tbl, nullptr, lo >= 0 ? lo : 0, hi >= 0 ? hi : 31, p4name);
    } else {
        ref = new Phv(lineno, tbl->gress, name, lo, hi); }
    if (ref != this) delete this;
    return ref;
}

int parity(unsigned v) {
    v ^= v >> 16;
    v ^= v >> 8;
    v ^= v >> 4;
    v ^= v >> 2;
    v ^= v >> 1;
    return v&1;
}

struct VLIWInstruction : Instruction {
    VLIWInstruction(int l) : Instruction(l) {}
    virtual int encode() = 0;
    void gen_prim_cfg(json::map& out) { };
    template<class REGS>
    void write_regs(REGS &regs, Table *tbl, Table::Actions::Action *act);
    FOR_ALL_TARGETS(DECLARE_FORWARD_VIRTUAL_INSTRUCTION_WRITE_REGS)
};

#include "tofino/instruction.cpp"
#if HAVE_JBAY
#include "jbay/instruction.cpp"
#endif // HAVE_JBAY

struct AluOP : VLIWInstruction {
    const struct Decode : Instruction::Decode {
        std::string name;
        unsigned opcode;
        const Decode *swap_args;
        Decode(const char *n, unsigned opc, bool assoc = false) : Instruction::Decode(n), name(n),
            opcode(opc), swap_args(assoc ? this : 0) {}
        Decode(const char *n, unsigned opc, Decode *sw, const char *alias_name = 0)
        : Instruction::Decode(n), name(n), opcode(opc), swap_args(sw) {
            if (sw && !sw->swap_args) sw->swap_args = this;
            if (alias_name) alias(alias_name); }
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    } *opc;
    Phv::Ref    dest;
    operand     src1, src2;
    AluOP(const Decode *op, Table *tbl, const Table::Actions::Action *act, const value_t &d,
          const value_t &s1, const value_t &s2)
    : VLIWInstruction(d.lineno), opc(op), dest(tbl->gress, d),
      src1(tbl, act, s1), src2(tbl, act, s2) {}
    std::string name() { return opc->name; };
    void gen_prim_cfg(json::map& out) { 
      out["name"] = "DirectAluPrimitive";
      out["operation"] = opc->name;
      dest.gen_prim_cfg((out["dest"] = json::map()));
      json::vector &srcv = out["src"] = json::vector();
      json::map oneoper;
      src1.gen_prim_cfg(oneoper);
      srcv.push_back(std::move(oneoper));
      src2.gen_prim_cfg(oneoper);
      srcv.push_back(std::move(oneoper));
    }
    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    void pass2(Table *tbl, Table::Actions::Action *) {
        src1->pass2(slot/Phv::mau_groupsize());
        src2->pass2(slot/Phv::mau_groupsize()); }
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const ::Phv::Slice &sl)> fn) {
        src1.phvRead(fn); src2.phvRead(fn); }
    void dbprint(std::ostream &out) const {
        out << "INSTR: " << opc->name << ' ' << dest << ", " << src1 << ", " << src2; }
};

struct AluOP3Src : AluOP {
    struct Decode : AluOP::Decode {
        Decode(const char *n, unsigned opc) : AluOP::Decode(n, opc) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    };
    operand     src3;
    AluOP3Src(const Decode *op, Table *tbl, const Table::Actions::Action *act, const value_t &d,
              const value_t &s1, const value_t &s2, const value_t &s3)
    : AluOP(op, tbl, act, d, s1, s2), src3(tbl, act, s3) {}
    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    void pass2(Table *tbl, Table::Actions::Action *);
};

static AluOP::Decode opADD("add", 0x23e, true), opADDC("addc", 0x2be, true),
                     opSUB("sub", 0x33e), opSUBC("subc", 0x3be),
                     opSADDU("saddu", 0x03e), opSADDS("sadds", 0x07e),
                     opSSUBU("ssubu", 0x0be), opSSUBS("ssubs", 0x0fe),
                     opMINU("minu", 0x13e, true), opMINS("mins", 0x17e, true),
                     opMAXU("maxu", 0x1be, true), opMAXS("maxs", 0x1fe, true),
                     opSETZ("setz", 0x01e, true), opNOR("nor", 0x05e, true),
                     opANDCA("andca", 0x09e), opNOTA("nota", 0x0de),
                     opANDCB("andcb", 0x11e, &opANDCA), opNOTB("notb", 0x15e, &opNOTA, "not"),
                     opXOR("xor", 0x19e, true), opNAND("nand", 0x19e, true),
                     opAND("and", 0x21e, true), opXNOR("xnor", 0x25e, true),
                     opB("alu_b", 0x29e), opORCA("orca", 0x29e),
                     opA("alu_a", 0x31e, &opB), opORCB("orcb", 0x35e, &opORCA),
                     opOR("or", 0x39e, true), opSETHI("sethi", 0x39e, true);
static AluOP3Src::Decode opBMSET("bitmasked-set", 0x2e);

Instruction *AluOP::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                   const VECTOR(value_t) &op) const {
    AluOP *rv;
    if (op.size == 4)
        rv = new AluOP(this, tbl, act, op.data[1], op.data[2], op.data[3]);
    else if (op.size == 3)
        rv = new AluOP(this, tbl, act, op.data[1], op.data[1], op.data[2]);
    else {
        error(op[0].lineno, "%s requires 2 or 3 operands", op[0].s);
        return 0; }
    if (!rv->src1.valid())
        error(op[2].lineno, "invalid src1");
    else if (!rv->src2.valid())
        error(op[3].lineno, "invalid src2");
    else
        return rv;
    delete rv;
    return 0;
}
Instruction *AluOP3Src::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                       const VECTOR(value_t) &op) const {
    if (op.size != 5) {
        if (op.size < 3 || op.size > 5) {
            error(op[0].lineno, "%s requires 2, 3 or 4 operands", op[0].s);
            return 0;
        } else { }
            return AluOP::Decode::decode(tbl, act, op); }
    auto rv = new AluOP3Src(this, tbl, act, op.data[1], op.data[2], op.data[3], op.data[4]);
    if (!rv->src1.valid())
        error(op[2].lineno, "invalid src1");
    else if (!rv->src2.valid())
        error(op[3].lineno, "invalid src2");
    else if (!rv->src3.valid())
        error(op[3].lineno, "invalid src3");
    else
        return rv;
    delete rv;
    return 0;
}

Instruction *AluOP::pass1(Table *tbl, Table::Actions::Action *) {
    if (!dest.check() || !src1.check() || !src2.check()) return this;
    if (dest->reg.mau_id() < 0) {
        error(dest.lineno, "%s not accessable in mau", dest->reg.name);
        return this; }
    if (dest->reg.type != Phv::Register::NORMAL) {
        error(dest.lineno, "%s dest can't be dark or mocha phv", opc->name.c_str());
        return this; }
    if (dest->lo || dest->hi != dest->reg.size-1) {
        error(lineno, "ALU ops cannot operate on slices");
        return this; }
    slot = dest->reg.mau_id();
    tbl->stage->action_set[tbl->gress][dest->reg.uid] = true;
    src1.mark_use(tbl);
    src2.mark_use(tbl);
    if (src2.phvGroup() < 0 && opc->swap_args) {
        std::swap(src1, src2);
        opc = opc->swap_args; }
    if (src2.phvGroup() < 0)
        error(lineno, "src2 must be phv register");
    return this;
}
Instruction *AluOP3Src::pass1(Table *tbl, Table::Actions::Action *act) {
    AluOP::pass1(tbl, act);
    src3.mark_use(tbl);
    if (!src3.to<operand::Action>())
        error(lineno, "src3 must be on the action bus");
    return this;
}
void AluOP3Src::pass2(Table *tbl, Table::Actions::Action *act) {
    AluOP::pass2(tbl, act);
    src3->pass2(slot/Phv::mau_groupsize());
    if (auto s1 = src1.to<operand::Action>()) {
        auto s3 = src3.to<operand::Action>();
        if (s1->bits(slot/Phv::mau_groupsize()) + 1 != s3->bits(slot/Phv::mau_groupsize()))
            error(lineno, "src1 and src3 must be adjacent on the action bus");
    } else {
        error(lineno, "src1 must be on the action bus"); }
}

int AluOP::encode() {
    int rv = (opc->opcode << 10) | (src1.bits(slot/Phv::mau_groupsize()) << 4);
    if (options.target == JBAY) rv <<= 1;
    return rv | src2.bits(slot/Phv::mau_groupsize());
}
bool AluOP::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<AluOP *>(a_)) {
        return opc == a->opc && dest == a->dest && src1 == a->src1 && src2 == a->src2;
    } else
        return false;
}

struct LoadConst : VLIWInstruction {
    struct Decode : Instruction::Decode {
        Decode(const char *n) : Instruction::Decode(n) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    };
    Phv::Ref    dest;
    int         src;
    LoadConst(Table *tbl, const Table::Actions::Action *act, const value_t &d, int&s)
        : VLIWInstruction(d.lineno), dest(tbl->gress, d), src(s) {}
    LoadConst(int line, Phv::Ref &d, int v) : VLIWInstruction(line), dest(d), src(v) {}
    std::string name() { return ""; };
    void gen_prim_cfg(json::map& out) { 
      out["name"] = "ModifyFieldPrimitive"; 
      dest.gen_prim_cfg((out["dest"] = json::map()));
      json::vector &srcv = out["src"] = json::vector();
      json::map onemap;
      onemap["immediate"] = std::to_string(src);
      srcv.push_back(std::move(onemap));
    }
    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    void pass2(Table *, Table::Actions::Action *) {}
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const ::Phv::Slice &sl)> fn) { }
    void dbprint(std::ostream &out) const {
        out << "INSTR: set " << dest << ", " << src; }

};

static LoadConst::Decode opLoadConst("load-const");

Instruction *LoadConst::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                       const VECTOR(value_t) &op) const {
    if (op.size != 3) {
        error(op[0].lineno, "%s requires 2 operands", op[0].s);
        return 0; }
    if (!CHECKTYPE(op[2], tINT)) return 0;
    return new LoadConst(tbl, act, op[1], op[2].i);
}

Instruction *LoadConst::pass1(Table *tbl, Table::Actions::Action *) {
    if (!dest.check()) return this;
    if (dest->reg.mau_id() < 0) {
        error(dest.lineno, "%s not accessable in mau", dest->reg.name);
        return this; }
    if (dest->reg.type != Phv::Register::NORMAL) {
        error(dest.lineno, "load-const dest can't be dark or mocha phv");
        return this; }
    if (dest->lo || dest->hi != dest->reg.size-1) {
        error(lineno, "load-const cannot operate on slices");
        return this; }
    slot = dest->reg.mau_id();
    int size = Phv::reg(slot)->size;
    if (size > 23) size = 23;
    if (src >= (1 << size) || src < -(1 << (size-1)))
        error(lineno, "Constant value %d out of range", src);
    src &= (1 << size) - 1;
    tbl->stage->action_set[tbl->gress][dest->reg.uid] = true;
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

struct CondMoveMux : VLIWInstruction {
    const struct Decode : Instruction::Decode {
        std::string name;
        unsigned opcode, cond_size;
        bool    src2opt;
        Decode(const char *name, unsigned opc, bool s2opt, unsigned csize, const char *alias_name)
        : name(name), Instruction::Decode(name), opcode(opc), cond_size(csize), src2opt(s2opt) {
            alias(alias_name); }
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    } *opc;
    Phv::Ref    dest;
    operand     src1, src2;
    unsigned    cond;
    CondMoveMux(Table *tbl, const Decode *op, const Table::Actions::Action *act,
                const value_t &d, const value_t &s)
    : VLIWInstruction(d.lineno), opc(op), dest(tbl->gress, d), src1(tbl, act, s),
      src2(tbl->gress, d) {}
    CondMoveMux(Table *tbl, const Decode *op, const Table::Actions::Action *act,
                const value_t &d, const value_t &s1, const value_t &s2)
    : VLIWInstruction(d.lineno), opc(op), dest(tbl->gress, d), src1(tbl, act, s1),
      src2(tbl, act, s2) {}
    std::string name() { return opc->name; }
    void gen_prim_cfg(json::map& out) { 
      out["name"] = opc->name;
      dest.gen_prim_cfg((out["dest"] = json::map()));
      json::vector &srcv = out["src"] = json::vector();
      json::map oneoper;
      src1.gen_prim_cfg(oneoper);
      srcv.push_back(std::move(oneoper));
      src2.gen_prim_cfg(oneoper);
      srcv.push_back(std::move(oneoper));
    }
    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    void pass2(Table *tbl, Table::Actions::Action *) {
        src1->pass2(slot/Phv::mau_groupsize());
        src2->pass2(slot/Phv::mau_groupsize()); }
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

Instruction *CondMoveMux::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                         const VECTOR(value_t) &op) const {
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

Instruction *CondMoveMux::pass1(Table *tbl, Table::Actions::Action *) {
    if (!dest.check() || !src1.check() || !src2.check()) return this;
    if (dest->reg.mau_id() < 0) {
        error(dest.lineno, "%s not accessable in mau", dest->reg.name);
        return this; }
    if (dest->reg.type != Phv::Register::NORMAL) {
        error(dest.lineno, "%s dest can't be dark or mocha phv", opc->name.c_str());
        return this; }
    slot = dest->reg.mau_id();
    tbl->stage->action_set[tbl->gress][dest->reg.uid] = true;
    src1.mark_use(tbl);
    src2.mark_use(tbl);
    return this;
}
int CondMoveMux::encode() {
    int rv = (cond << 15) | (opc->opcode << 10) | (src1.bits(slot/Phv::mau_groupsize()) << 4);
    if (options.target == JBAY) rv <<= 1;
    /* funny cond test on src2 is to match the compiler output -- if we're not testing
     * src2 validity, what we specify as src2 is irrelevant */
    return rv | (cond & 0x40 ? src2.bits(slot/Phv::mau_groupsize()) : 0);
}
bool CondMoveMux::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<CondMoveMux *>(a_)) {
        return opc == a->opc && dest == a->dest && src1 == a->src1 && src2 == a->src2 &&
               cond == a->cond;
    } else
        return false;
}

struct Set;

struct DepositField : VLIWInstruction {
    struct Decode : Instruction::Decode {
        Decode() : Instruction::Decode("deposit_field") { alias("deposit-field"); }
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    };
    Phv::Ref    dest;
    operand     src1, src2;
    DepositField(Table *tbl, const Table::Actions::Action *act, const value_t &d,
                 const value_t &s)
    : VLIWInstruction(d.lineno), dest(tbl->gress, d), src1(tbl, act, s), src2(tbl->gress, d) {}
    DepositField(Table *tbl, const Table::Actions::Action *act, const value_t &d,
                 const value_t &s1, const value_t &s2)
    : VLIWInstruction(d.lineno), dest(tbl->gress, d), src1(tbl, act, s1), src2(tbl, act, s2) {}
    DepositField(const Set &);
    std::string name() { return "deposit_field"; }
    void gen_prim_cfg(json::map& out) { 
      out["name"] = "ModifyFieldPrimitive"; 
      dest.gen_prim_cfg((out["dest"] = json::map()));
      json::vector &srcv = out["src"] = json::vector();
      json::map oneoper;
      src1.gen_prim_cfg(oneoper);
      srcv.push_back(std::move(oneoper));
      src2.gen_prim_cfg(oneoper);
      srcv.push_back(std::move(oneoper));
    }

    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    void pass2(Table *tbl, Table::Actions::Action *) {
        src1->pass2(slot/Phv::mau_groupsize());
        src2->pass2(slot/Phv::mau_groupsize()); }
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const ::Phv::Slice &sl)> fn) {
        src1.phvRead(fn); src2.phvRead(fn); }
    void dbprint(std::ostream &out) const {
        out << "INSTR: deposit_field " << dest << ", " << src1 << ", " << src2; }
};

static DepositField::Decode opDepositField;

Instruction *DepositField::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                          const VECTOR(value_t) &op) const {
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

Instruction *DepositField::pass1(Table *tbl, Table::Actions::Action *) {
    if (!dest.check() || !src1.check() || !src2.check()) return this;
    if (dest->reg.mau_id() < 0) {
        error(dest.lineno, "%s not accessable in mau", dest->reg.name);
        return this; }
    if (dest->reg.type != Phv::Register::NORMAL) {
        error(dest.lineno, "deposit-field dest can't be dark or mocha phv");
        return this; }
    slot = dest->reg.mau_id();
    tbl->stage->action_set[tbl->gress][dest->reg.uid] = true;
    src1.mark_use(tbl);
    src2.mark_use(tbl);
    return this;
}
int DepositField::encode() {
    unsigned rot = (dest->reg.size - dest->lo + src1.bitoffset(slot/Phv::mau_groupsize()))
                    % dest->reg.size;
    int bits = (1 << 10) | (src1.bits(slot/Phv::mau_groupsize()) << 4);
    bits |= dest->hi << 11;
    bits |= rot << 16;
    switch (Phv::reg(slot)->size) {
    case 8:
        bits |= (dest->lo & 3) << 14;
        bits |= (dest->lo & ~3) << 17;
        break;
    case 16:
        bits |= (dest->lo & 1) << 15;
        bits |= (dest->lo & ~1) << 19;
        break;
    case 32:
        bits |= dest->lo << 21;
        break;
    default:
        assert(0); }
    if (options.target == JBAY) bits <<= 1;
    return bits | src2.bits(slot/Phv::mau_groupsize());
}
bool DepositField::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<DepositField *>(a_)) {
        return dest == a->dest && src1 == a->src1 && src2 == a->src2;
    } else
        return false;
}

struct Set : VLIWInstruction {
    struct Decode : Instruction::Decode {
        std::string name;
        Decode(const char *n) : name(n), Instruction::Decode(n) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    };
    Phv::Ref    dest;
    operand     src;
    Set(Table *tbl, const Table::Actions::Action *act, const value_t &d, const value_t &s)
        : VLIWInstruction(d.lineno), dest(tbl->gress, d), src(tbl, act, s) {}
    std::string name() { return "set"; };
    void gen_prim_cfg(json::map& out) { 
      out["name"] = "ModifyFieldPrimitive"; 
      dest.gen_prim_cfg((out["dest"] = json::map()));
      json::vector &srcv = out["src"] = json::vector();
      json::map oneoper;
      src.gen_prim_cfg(oneoper);
      srcv.push_back(std::move(oneoper));
    }
    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    void pass2(Table *tbl, Table::Actions::Action *) { src->pass2(slot/Phv::mau_groupsize()); }
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const ::Phv::Slice &sl)> fn) { src.phvRead(fn); }
    void dbprint(std::ostream &out) const {
        out << "INSTR: set " << dest << ", " << src; }

};

DepositField::DepositField(const Set &s)
: VLIWInstruction(s), dest(s.dest), src1(s.src), src2(s.dest->reg) {}

static Set::Decode opSet("set");

Instruction *Set::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                 const VECTOR(value_t) &op) const {
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

Instruction *Set::pass1(Table *tbl, Table::Actions::Action *act) {
    if (!dest.check() || !src.check()) return this;
    if (dest->reg.mau_id() < 0) {
        error(dest.lineno, "%s not accessable in mau", dest->reg.name);
        return this; }
    if (dest->lo || dest->hi != dest->reg.size-1)
        return (new DepositField(*this))->pass1(tbl, act);
    if (auto *k = src.to<operand::Const>()) {
        if (dest->reg.type == Phv::Register::DARK) {
            error(dest.lineno, "can't set dark phv to a constant");
            return this; }
        int minconst = (options.target == JBAY) ? -4 : -8;
        if (k->value < minconst || k->value >= 8)
            return (new LoadConst(lineno, dest, k->value))->pass1(tbl, act); }
    slot = dest->reg.mau_id();
    tbl->stage->action_set[tbl->gress][dest->reg.uid] = true;
    src.mark_use(tbl);
    return this;
}
int Set::encode() {
    int rv = src.bits(slot/Phv::mau_groupsize());
    switch (dest->reg.type) {
    case Phv::Register::NORMAL:
        rv = (opA.opcode << 10) | (rv << 4);
        if (options.target == JBAY) rv <<= 1;
        rv |= (slot & 0xf);
        break;
    case Phv::Register::MOCHA:
        rv |= 0x40;
        break;
    case Phv::Register::DARK:
        rv |= 0x20;
        break;
    default:
        assert(0); }
    return rv;
}
bool Set::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<Set *>(a_)) {
        return dest == a->dest && src == a->src;
    } else
        return false;
}

struct NulOP : VLIWInstruction {
    const struct Decode : Instruction::Decode {
        std::string name;
        unsigned opcode;
        Decode(const char *n, unsigned opc) : Instruction::Decode(n), name(n), opcode(opc) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    } *opc;
    Phv::Ref    dest;
    NulOP(Table *tbl, const Table::Actions::Action *act, const Decode *o, const value_t &d) :
        VLIWInstruction(d.lineno), opc(o), dest(tbl->gress, d) {}
    std::string name() { return opc->name; };
    void gen_prim_cfg(json::map& out) { 
      out["name"] = "DirectAluPrimitive";
      out["operator"] = opc->name;
      dest.gen_prim_cfg((out["dest"] = json::map()));
    }
    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    void pass2(Table *, Table::Actions::Action *) {}
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const ::Phv::Slice &sl)> fn) { }
    void dbprint(std::ostream &out) const {
        out << "INSTR: " << opc->name << " " << dest; }
};

static NulOP::Decode opInvalidate("invalidate", 0x3800), opNoop("noop", 0);

Instruction *NulOP::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                   const VECTOR(value_t) &op) const {
    if (op.size != 2) {
        error(op[0].lineno, "%s requires 1 operand", op[0].s);
        return 0; }
    return new NulOP(tbl, act, this, op[1]);
}

Instruction *NulOP::pass1(Table *tbl, Table::Actions::Action *) {
    if (!dest.check()) return this;
    if (dest->reg.mau_id() < 0) {
        error(dest.lineno, "%s not accessable in mau", dest->reg.name);
        return this; }
    slot = dest->reg.mau_id();
    if (opc->opcode || !options.match_compiler) {
        tbl->stage->action_set[tbl->gress][dest->reg.uid] = true; }
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

struct ShiftOP : VLIWInstruction {
    const struct Decode : Instruction::Decode {
        std::string name;
        unsigned opcode;
        bool use_src1;
        const Decode *swap_args;
        Decode(const char *n, unsigned opc, bool funnel = false)
        : Instruction::Decode(n), name(n), opcode(opc), use_src1(funnel) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    } *opc;
    Phv::Ref    dest;
    operand     src1, src2;
    int         shift;
    ShiftOP(const Decode *d, Table *tbl, const Table::Actions::Action *act, const value_t *ops) :
            VLIWInstruction(ops->lineno), opc(d), dest(tbl->gress, ops[0]),
            src1(tbl, act, ops[1]), src2(tbl, act, ops[2]) {
                if (opc->use_src1) {
                    if (CHECKTYPE(ops[3], tINT)) shift = ops[3].i;
                } else {
                    src2 = src1;
                    if (CHECKTYPE(ops[2], tINT)) shift = ops[2].i; } }
    std::string name() { return opc->name; };
    void gen_prim_cfg(json::map& out) { 
      out["name"] = "DirectAluPrimitive";
      out["operator"] = opc->name;
      dest.gen_prim_cfg((out["dest"] = json::map()));
      json::vector &srcv = out["src"] = json::vector();
      json::map oneoper;
      src1.gen_prim_cfg(oneoper);
      srcv.push_back(std::move(oneoper));
      src2.gen_prim_cfg(oneoper);
      srcv.push_back(std::move(oneoper));
    }
    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    void pass2(Table *tbl, Table::Actions::Action *) {
        src1->pass2(slot/Phv::mau_groupsize());
        src2->pass2(slot/Phv::mau_groupsize()); }
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void (const ::Phv::Slice &sl)> fn) {
        src1.phvRead(fn); src2.phvRead(fn); }
    void dbprint(std::ostream &out) const {
        out << "INSTR: " << opc->name << ' ' << dest << ", " << src1 << ", " << shift; }
};

static ShiftOP::Decode opSHL("shl", 0x0c, false), opSHRS("shrs", 0x1c, false),
                       opSHRU("shru", 0x14, false), opFUNSHIFT("funnel-shift", 0x04, true);

Instruction *ShiftOP::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                     const VECTOR(value_t) &op) const {
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

Instruction *ShiftOP::pass1(Table *tbl, Table::Actions::Action *) {
    if (!dest.check() || !src1.check() || !src2.check()) return this;
    if (dest->reg.mau_id() < 0) {
        error(dest.lineno, "%s not accessable in mau", dest->reg.name);
        return this; }
    if (dest->reg.type != Phv::Register::NORMAL) {
        error(dest.lineno, "%s dest can't be dark or mocha phv", opc->name.c_str());
        return this; }
    if (dest->lo || dest->hi != dest->reg.size-1) {
        error(lineno, "shift ops cannot operate on slices");
        return this; }
    slot = dest->reg.mau_id();
    tbl->stage->action_set[tbl->gress][dest->reg.uid] = true;
    src1.mark_use(tbl);
    src2.mark_use(tbl);
    if (src2.phvGroup() < 0)
        error(lineno, "src%s must be phv register", opc->use_src1 ? "2" : "");
    return this;
}
int ShiftOP::encode() {
    int rv = (shift << 16) | (opc->opcode << 10);
    if (opc->use_src1 || options.match_compiler) rv |= src1.bits(slot/Phv::mau_groupsize()) << 4;
    if (options.target == JBAY) rv <<= 1;
    return rv | src2.bits(slot/Phv::mau_groupsize());
}
bool ShiftOP::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<ShiftOP *>(a_)) {
        return opc == a->opc && dest == a->dest && src1 == a->src1 && src2 == a->src2 &&
               shift == a->shift;
    } else
        return false;
}

}  // end anonymous namespace
