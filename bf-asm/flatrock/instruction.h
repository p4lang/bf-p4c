#ifndef FLATROCK_INSTRUCTION_H_
#define FLATROCK_INSTRUCTION_H_

#include "asm-types.h"
#include "bf-asm/instruction.h"
#include "bf-asm/action_bus.h"
#include "bf-asm/phv.h"
#include "bf-asm/stage.h"
#include "bf-asm/tables.h"

namespace Flatrock {

struct Operand {
    /** A source operand to a VLIW instruction -- this can be a variety of things, so we
     * have a pointer to an abstract base class and a number of derived concrete classes for
     * the different kinds of operands.  When we parse the operand, the type may be determined,
     * or if it is just a name, we will have to wait to a later pass to resolve what the
     * name refers to.  At that point, the `Named' object created in parsing will be replaced
     * with the actual operand type */
    struct Base {
        int     lineno;
        explicit Base(int line) : lineno(line) {}
        Base(const Base &a) : lineno(a.lineno) {}
        virtual ~Base() {}
        virtual Base *clone() = 0;
        virtual Base *lookup(Base *&ref) { return this; }
        virtual bool check() { return true; }
        virtual int bits(int slot) = 0;
        virtual int bit_offset(int slot) = 0;
        virtual void dbprint(std::ostream &) const = 0;
        virtual bool equiv(const Base *) const = 0;
        virtual bool phvRead(std::function<void(const ::Phv::Slice &sl)>) { return false; }
        virtual bool phv() const { return false; }
        /** pass1 called as part of pass1 processing of stage
         * @param tbl table containing the action with the instruction with this operand
         * @param slot PHV container this operand is associated with */
        virtual void pass1(Table *tbl, int slot) {}
        /** pass2 called as part of pass2 processing of stage
         * @param tbl table containing the action with the instruction with this operand
         * @param slot PHV container this operand is associated with */
        virtual void pass2(Table *tbl, int slot) {}
    } *op;
    struct Const : Base {
        int64_t value;
        Const(int line, int64_t v) : Base(line), value(v) {}
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const Const *>(a_)) {
                return value == a->value;
            } else { return false; } }
        Const *clone() override { return new Const(*this); }
        int bits(int slot) override {
            switch (::Phv::reg(slot)->size) {
            case 8: return (value & 0xff) | 0x100;
            case 16: return (value & 0x1f) | 0x20;
            case 32: return (value & 0xf) | 0x10;
            default: BUG("invalid register size %d", ::Phv::reg(slot)->size); } }
        int bit_offset(int) override { return 0; }
        void pass1(Table *tbl, int slot) override {
            int min, max;
            switch (::Phv::reg(slot)->size) {
            case 8:  min = -128; max = 255; break;
            case 16: min =  -16; max =  15; break;
            case 32: min =   -8; max =   7; break;
            default: BUG("invalid register size %d", ::Phv::reg(slot)->size); }
            if (value > max || value < min)
                error(lineno, "Constant value %" PRId64 " out of range for PHE%d",
                      value, ::Phv::reg(slot)->size); }
        void dbprint(std::ostream &out) const override { out << value; }
    };
    struct Phv : Base {
        ::Phv::Ref      reg;
        ActionBusSource abs;
        Phv(int line, gress_t g, int stage, const value_t &n) : Base(line), reg(g, stage, n) {}
        Phv(int line, gress_t g, int stage, const std::string &n, int l, int h) :
            Base(line), reg(g, stage, line, n, l, h) {}
        explicit Phv(const ::Phv::Ref &r) : Base(r.lineno), reg(r) {}
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const Phv *>(a_)) {
                return reg == a->reg;
            } else { return false; } }
        Phv *clone() override { return new Phv(*this); }
        int bits(int slot) override {
            BUG_CHECK(abs.type == ActionBusSource::XcmpData, "%s not on xcmp abus", reg.name());
            unsigned size = ::Phv::reg(slot)->size/8U;  // size in bytes
            // FIXME -- need to be checking to make sure the whole value is within the slot
            // somehow.  But we only have a single byte recorded in the ActionBusSource?
            if (abs.xcmp_group) {
                unsigned align_mask = 3/size;
                BUG_CHECK((slot & align_mask) == (abs.xcmp_byte & align_mask),
                          "wadb byte %d misaligned for slot %d", abs.xcmp_byte, slot);
                return 16/size + abs.xcmp_byte/4;
            } else {
                return abs.xcmp_byte/size; } }
        int bit_offset(int slot) override {
            BUG_CHECK(abs.type == ActionBusSource::XcmpData, "%s not on xcmp abus", reg.name());
            unsigned bit = reg->lo;
            if (!abs.xcmp_group)
                bit = bit % 8U + (abs.xcmp_byte%4U) * 8;
            return bit % ::Phv::reg(slot)->size; }
        bool check() override {
            if (!reg.check()) return false;
            if (reg->reg.mau_id() < 0) {
                error(reg.lineno, "%s not accessible in mau", reg->reg.name);
                return false; }
            return true; }
        void pass1(Table *tbl, int) override {
            tbl->stage->action_use[tbl->gress][reg->reg.uid] = true; }
        void pass2(Table *tbl, int slot) override {
            ::InputXbar::Group grp(::InputXbar::Group::XCMP, -1);
            int byte = tbl->find_on_ixbar(*reg, grp, &grp);
            if (byte < 0) {
                error(reg.lineno, "%s not available on the xcmp ixbar", reg.name());
                return; }
            unsigned size = ::Phv::reg(slot)->size/8U;  // size in bytes
            if (reg->hi/8U - reg->lo/8U >= size)
                error(reg.lineno, "%s is not entirely in one ADB slot", reg.name());
            if (grp.index > 0 && size < 4) {
                unsigned align_mask = 3/size;
                if ((slot & align_mask) != (byte & align_mask))
                    error(reg.lineno, "%s not aligned in wadb for destination PHE%d",
                          reg.name(), size*8); }
            abs = ActionBusSource(grp, byte);
            if (tbl->find_on_actionbus(abs, reg->lo, reg->hi, ::Phv::reg(slot)->size/8U) < 0)
                tbl->need_on_actionbus(abs, reg->lo, reg->hi, ::Phv::reg(slot)->size/8U); }
        void dbprint(std::ostream &out) const override { out << reg; }
        bool phvRead(std::function<void(const ::Phv::Slice &sl)> fn) override {
            fn(*reg);
            return true; }
        bool phv() const override { return true; }
    };
    struct Action : Base {
        /* source referring to either an action data or immediate field OR an attached table
         * output.  All of these are accessed via the action data bus */
        std::string             name;
        std::string             p4name;
        TableOutputModifier     mod = TableOutputModifier::NONE;
        Table                   *table;
        Table::Format::Field    *field;
        int                     lo, hi;

        Action(int line, const std::string &n, Table *tbl, Table::Format::Field *f,
               unsigned l, unsigned h) : Base(line), name(n), table(tbl), field(f), lo(l), hi(h) {}
        Action(int line, const std::string &n, TableOutputModifier mod, Table *tbl,
               unsigned l, unsigned h)
        : Base(line), name(n), mod(mod), table(tbl), field(nullptr), lo(l), hi(h) {}
        Action(int line, const std::string &n, Table *tbl, Table::Format::Field *f,
               unsigned l, unsigned h, const std::string &m)
        : Base(line), name(n), p4name(m), table(tbl), field(f), lo(l), hi(h) {}
        Action(int line, const std::string &n, TableOutputModifier mod, Table *tbl,
               unsigned l, unsigned h, const std::string &m)
        : Base(line), name(n), p4name(m), mod(mod), table(tbl), field(nullptr), lo(l), hi(h) {}
        bool equiv(const Base *a_) const override {
            auto *a = dynamic_cast<const Action *>(a_);
            if (!a || lo != a->lo || hi != a->hi) return false;
            if (name == a->name && table == a->table && field == a->field && mod == a->mod)
                return true;
            if (field != a->field && (!field || !a->field)) return false;
            int b1 = field ? table->find_on_actionbus(field, lo, hi, 0)
                           : table->find_on_actionbus(name, mod, lo, hi, 0);
            int b2 = a->field ? a->table->find_on_actionbus(a->field, lo, hi, 0)
                              : a->table->find_on_actionbus(a->name, mod, lo, hi, 0);
            return b1 == b2 && b1 >= 0; }
        Action *clone() override { return new Action(*this); }
        int bits(int slot) override {
            int size = ::Phv::reg(slot)->size/8U;
            int byte = field ? table->find_on_actionbus(field, lo, hi, 0)
                             : table->find_on_actionbus(name, mod, lo, hi, 0);
            if (byte < 0) {
                if (lo > 0 || (field && hi + 1 < int(field->size)))
                    error(lineno, "%s(%d..%d) is not on the action bus", name.c_str(), lo, hi);
                else
                    error(lineno, "%s is not on the action bus", name.c_str());
                return -1; }
            return byte/size; }
        int bit_offset(int slot) override {
            int size = ::Phv::reg(slot)->size;
            int byte = field ? table->find_on_actionbus(field, lo, hi, 0)
                             : table->find_on_actionbus(name, mod, lo, hi, 0);
            return (byte * 8U + lo) % size; }
        void pass1(Table *tbl, int slot) override {
            if (field) field->flags |= Table::Format::Field::USED_IMMED;
            auto slot_size = ::Phv::reg(slot)->size;
            if (lo >= 0 && hi >= 0 && lo/slot_size != hi/slot_size) {
                error(lineno, "action bus slice (%d..%d) can't fit in a single slot for %d bit "
                      "access", lo, hi, slot_size);
                // chop it down to be in range (avoid error cascade)
                hi = lo | (slot_size-1); } }
        void dbprint(std::ostream &out) const override {
            out << name << mod << '(' << lo << ".." << hi << ')';
            if (field)
                out << '[' << field->bits[0].lo << ':' << field->size << ", "
                    << field->group << ']'; }
    };
    struct RawAction : Base {
        int             index;
        unsigned        offset;

        RawAction(int line, int idx, unsigned off) : Base(line), index(idx), offset(off) {}
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const RawAction *>(a_)) {
                return index == a->index && offset == a->offset;
            } else { return false; } }
        RawAction *clone() override { return new RawAction(*this); }
        int bits(int) override { return index; }
        int bit_offset(int) override { return 0; }
        void dbprint(std::ostream &out) const override { out << 'A' << index; }
        // is_ealu_output() is true if this is an EALU output
    };
#if 0
    // FIXME -- read from XCMP hash?
    struct HashDist : Base {
        Table                   *table;
        std::vector<int>        units;
        int                     lo = -1, hi = -1;

        HashDist(int line, Table *t) : Base(line), table(t) {}
        HashDist(int line, Table *t, int unit) : Base(line), table(t) { units.push_back(unit); }
        unsigned bitoffset(int group) const override { return lo >= 0 ? lo : 0; }
        static HashDist *parse(Table *tbl, const VECTOR(value_t) &v) {
            if (v.size < 2 || v[0] != "hash_dist") return nullptr;
            auto *rv = new HashDist(v[0].lineno, tbl);
            for (int i = 1; i < v.size; ++i) {
                if (v[i].type == tRANGE && rv->lo == -1) {
                    rv->lo = v[i].lo;
                    rv->hi = v[i].hi;
                } else if (CHECKTYPE(v[i], tINT)) {
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
            auto *a = dynamic_cast<const HashDist *>(a_);
            if (!a || units != a->units || lo != a->lo || hi != a->hi) return false;
            if (table == a->table) return true;
            int elo = this->lo < 0 ? 0 : lo;
            int ehi = this->hi < 0 ? 15 : hi;
            for (auto unit : units) {
                int b1 = table->find_on_actionbus(find_hash_dist(unit), elo, ehi, 0);
                int b2 = a->table->find_on_actionbus(a->find_hash_dist(unit), elo, ehi, 0);
                if (b1 != b2 || b1 < 0) return false; }
            return true; }
        HashDist *clone() override { return new HashDist(*this); }
        void pass2(int group) override {
            if (units.size() > 2) {
                error(lineno, "Can't use more than 2 hash_dist units together in an action");
                return; }
            int size = group_size[group]/8U;
            if (lo < 0) lo = 0;
            if (hi < 0) hi = 8*size - 1;
            if ((lo ^ hi) & ~(8*size-1))
                error(lineno, "hash dist slice(%d..%d) can't be accessed by %d bit PHV",
                      lo, hi, 8*size);
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
                if (hd->xbar_use & HashDistribution::IMMEDIATE_HIGH) {
                    if (size == 4) {
                        lo += 16;
                        hi += 16; }
                } else {
                    hd->xbar_use |= HashDistribution::IMMEDIATE_LOW; }
            } else {
                error(lineno, "No hash dist %d in table %s", units.at(0), table->name());
            }
            int lo = this->lo;
            for (auto u : units) {
                if (auto hd = find_hash_dist(u)) {
                    if (table->find_on_actionbus(hd, lo, hi, size) < 0)
                        table->need_on_actionbus(hd, lo, hi, size);
                    lo += 16; } } }
        int bits(int group, int dest_size = -1) override {
            int size = group_size[group]/8U;
            auto hd = find_hash_dist(units.at(0));
            int byte = table->find_on_actionbus(hd, lo, hi, size);
            if (byte < 0) {
                error(lineno, "hash dist %d is not on the action bus", hd->id);
                return -1; }
            if (units.size() == 2) {
                auto hd1 = find_hash_dist(units.at(1));
                if (table->find_on_actionbus(ActionBusSource(hd, hd1), lo + 16, hi, size) < 0)
                    error(lineno, "hash dists %d and %d not contiguous on the action bus",
                          hd->id, hd1->id);
            }
            if (size == 2) byte -= 32;
            if (byte >= 0 || byte < 32*size)
                return ACTIONBUS_OPERAND + byte/size;
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
    };
    struct RandomGen : Base {
        Table           *table;
        RandomNumberGen rng;
        int             lo = 0, hi = -1;
        RandomGen(Table *t, const VECTOR(value_t) &v) : Base(v[0].lineno), table(t), rng(0) {
            if (v.size > 1 && CHECKTYPE(v[1], tINT)) rng.unit = v[1].i;
            if (rng.unit < 0 || rng.unit > 1)
                error(v[0].lineno, "invalid random number generator");
            if (v.size > 2 && CHECKTYPE(v[2], tRANGE)) {
                lo = v[2].lo;
                hi = v[2].hi;
                if (lo < 0 || hi > 31 || hi < lo)
                    error(v[2].lineno, "invalid random number generator slice"); } }
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const RandomGen *>(a_)) {
                return rng == a->rng && lo == a->lo && hi == a->hi;
            } else { return false; } }
        RandomGen *clone() override { return new RandomGen(*this); }
        void pass2(int group) override {
            unsigned size = group_size[group];
            if (hi < 0) hi = lo + 8*size - 1;
            if ((lo ^ hi) & ~(8*size-1))
                error(lineno, "invalid slice(%d..%d) of rng %d for use with %d bit PHV",
                      lo, hi, rng.unit, size);
            if (table->find_on_actionbus(rng, lo, hi, size/8U))
                table->need_on_actionbus(rng, lo, hi, size/8U); }
        int bits(int group, int dest_size = -1) override {
            int size = group_size[group]/8U;
            int byte = table->find_on_actionbus(rng, lo, hi, size);
            if (byte < 0) {
                error(lineno, "rng %d is not on the action bus", rng.unit);
                return -1; }
            if (size == 2) byte -= 32;
            if (byte >= 0 || byte < 32*size)
                return ACTIONBUS_OPERAND + byte/size;
            error(lineno, "action bus entry %d(rng %d) out of range for %d-bit access",
                  size == 2 ? byte+32 : byte, rng.unit, size*8);
            return -1; }
        unsigned bitoffset(int group) const override { return lo; }
        void dbprint(std::ostream &out) const override {
            out << "rng " << rng.unit << '(' << lo << ".." << hi << ')'; }
    };
#endif
    struct Named : Base {
        std::string             name;
        std::string             p4name;
        TableOutputModifier     mod = TableOutputModifier::NONE;
        int                     lo, hi;
        Table                   *tbl;
        std::string             action;

        Named(int line, const std::string &n, int l, int h, Table *t, const std::string &act)
        : Base(line), name(n), lo(l), hi(h), tbl(t), action(act) {}
        Named(int line, const std::string &n, TableOutputModifier m, int l, int h,
              Table *t, const std::string &act)
        : Base(line), name(n), mod(m), lo(l), hi(h), tbl(t), action(act) {}
        Named(int line, const std::string &n, int l, int h,
              Table *t, const std::string &act, std::string &m)
        : Base(line), name(n), p4name(m), lo(l), hi(h), tbl(t), action(act) {}
        Named(int line, const std::string &n, TableOutputModifier mod, int l, int h,
              Table *t, const std::string &act, std::string &m)
        : Base(line), name(n), p4name(m), mod(mod), lo(l), hi(h), tbl(t), action(act) {}
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const Named *>(a_)) {
                return name == a->name && lo == a->lo && hi == a->hi && tbl == a->tbl &&
                       action == a->action;
            } else { return false; } }
        Base *lookup(Base *&ref) override;
        Named *clone() override { return new Named(*this); }
        bool check() override { BUG(); return true; }
        int bits(int) override { BUG(); return 0; }
        int bit_offset(int) override { BUG(); return 0; }
        void pass1(Table *, int) override { BUG(); }
        void dbprint(std::ostream &out) const override {
            out << name;
            if (lo >= 0) {
                out << '(' << lo;
                if (hi >= 0 && hi != lo) out << ".. " << hi;
                out << ')'; }
            out << '[' << tbl->name() << ':' << action << ']'; }
    };
    Operand() : op(0) {}
    Operand(const Operand &a) : op(a.op ? a.op->clone() : 0) {}
    Operand(Operand &&a) : op(a.op) { a.op = 0; }
    Operand &operator=(const Operand &a) {
        if (&a != this) {
            delete op;
            op = a.op ? a.op->clone() : 0; }
        return *this; }
    Operand &operator=(Operand &&a) {
        if (&a != this) {
            delete op;
            op = a.op;
            a.op = 0; }
        return *this; }
    ~Operand() { delete op; }
    Operand(Table *tbl, const Table::Actions::Action *act, const value_t &v);
    Operand(gress_t gress, int stage, const value_t &v) : op(new Phv(v.lineno, gress, stage, v)) { }
    explicit Operand(const ::Phv::Ref &r) : op(new Phv(r)) {}
    bool valid() const { return op != 0; }
    bool operator==(Operand &a) {
        return op == a.op || (op && a.op && op->lookup(op)->equiv(a.op->lookup(a.op))); }
    bool check() {
        return op && op->lookup(op) ? op->check() : false; }
    void dbprint(std::ostream &out) const { op->dbprint(out); }
    Base *operator->() { return op->lookup(op); }
    template <class T> T *to() { return dynamic_cast<T *>(op->lookup(op)); }
    static bool isActionData(const value_t &v) {
        std::string name_;
        if (CHECKTYPE2M(v, tSTR, tCMD, "phv or register reference or slice")) {
            if (v.type == tSTR)
                name_ = v.s;
            else
                name_ = v[0].s;

            if (name_[0] == 'A' || name_[0] == 'E')
                return true;
            else
                return false;
        }
        return false;
    }
    bool phv() { return op->lookup(op)->phv(); }
};

struct InstructionShim : Instruction {
    // Just a shim to ensure these instructions are only used on Flatrock
    explicit InstructionShim(int l) : Instruction(l) {}
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        void write_regs, (mau_regs &, Table *, Table::Actions::Action *), override {
            BUG("Flatrock instruction on %s?", Target::name()); })
};

struct VLIWInstruction : InstructionShim {
    explicit VLIWInstruction(int l) : InstructionShim(l) {}
    virtual uint32_t encode() = 0;
    void write_regs(Target::Flatrock::mau_regs &, Table *, Table::Actions::Action *) override;
};

struct PhvWrite : VLIWInstruction {
    struct Decode : Instruction::Decode {
        enum opcodes { NOOP=0, SET=1, ANDC=2, OR=3, SETBM=4, LDC=4, DPF=8 };
        std::string name;
        unsigned opcode;
        Decode(const char *n, target_t targ, unsigned op)
        : Instruction::Decode(n, targ), name(n), opcode(op) {}
        virtual PhvWrite *alloc(Table *tbl, const Table::Actions::Action *act,
                                const VECTOR(value_t) &op) const;
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    } const *opc;
    Phv::Ref    alu_slot;
    Phv::Ref    dest;
    Operand     src;
    static constexpr int MAX_MERGE_DEST = 0;  // no merge dest any more?
    PhvWrite(const Decode *op, Table *tbl, const Table::Actions::Action *act,
             const value_t &d, const value_t &s) : VLIWInstruction(d.lineno),
         opc(op), dest(tbl->gress, tbl->stage->stageno + 1, d), src(tbl, act, s) {}
    std::string name() { return opc->name; }
    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    void pass2(Table *tbl, Table::Actions::Action *) { src->pass2(tbl, slot); }
    bool equiv(Instruction *a_);
    uint32_t encode();
    bool phvRead(std::function<void(const ::Phv::Slice &sl)> fn) { return src->phvRead(fn); }
    void dbprint(std::ostream &out) const {
        out << "INSTR: " << opc->name << " " << dest << ", " << src; }
};

struct Noop : PhvWrite::Decode {
    Noop(const char *n, target_t targ) : Decode(n, targ, 0) {}
    Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                        const VECTOR(value_t) &op) const override;
};

struct BitmaskSet : PhvWrite {
    struct Decode : PhvWrite::Decode {
        Decode(const char *n, target_t targ) : PhvWrite::Decode(n, targ, SETBM) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    };
    uint32_t    mask;
    BitmaskSet(const Decode *op, Table *tbl, const Table::Actions::Action *act, const value_t &d,
               const value_t &s, int m) : PhvWrite(op, tbl, act, d, s), mask(m) {}
    BitmaskSet(PhvWrite &wr, int m);
    uint32_t encode();
};

struct DepositField : PhvWrite {
    struct Decode : PhvWrite::Decode {
        Decode(const char *n, target_t targ) : PhvWrite::Decode(n, targ, DPF) {}
        PhvWrite *alloc(Table *tbl, const Table::Actions::Action *act,
                        const VECTOR(value_t) &op) const override;
    };
    DepositField(const Decode *op, Table *tbl, const Table::Actions::Action *act,
                 const value_t &d, const value_t &s) : PhvWrite(op, tbl, act, d, s) {}
    explicit DepositField(PhvWrite &wr);
    uint32_t encode();
};

struct LoadConst : PhvWrite {
    struct Decode : PhvWrite::Decode {
        Decode(const char *n, target_t targ) : PhvWrite::Decode(n, targ, LDC) {}
        PhvWrite *alloc(Table *tbl, const Table::Actions::Action *act,
                        const VECTOR(value_t) &op) const override;
    };
    LoadConst(const Decode *op, Table *tbl, const Table::Actions::Action *act,
              const value_t &d, const value_t &s) : PhvWrite(op, tbl, act, d, s) {}
    explicit LoadConst(PhvWrite &wr);
    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    uint32_t encode();
};

namespace EALU {

struct EALUInstruction : InstructionShim {
    int instr_width;
    int instr_word;
    explicit EALUInstruction(int l) : InstructionShim(l) {}
    virtual uint32_t encode() = 0;
    bool decode_dest(const value_t &d);
    void write_regs(Target::Flatrock::mau_regs &, Table *, Table::Actions::Action *) override;
};

struct AluOP : EALUInstruction {
    enum special_flags { Commutative=1, IgnoreSrc1=2, IgnoreSrc2=4, IgnoreSrcs=6,
                         CanSliceWithConst=8 };
    struct Decode : Instruction::Decode {
        enum opcodes { ADD, SUB };
        std::string name;
        unsigned opcode;
        const Decode *swap_args;
        int flags = 0;
        Decode(const char *n, target_t targ, unsigned opc, int flgs = 0, const char *alias_name = 0)
        : Instruction::Decode(n, targ), name(n), opcode(opc),
          swap_args(flgs & Commutative ? this : 0), flags(flgs) {
            if (alias_name) alias(alias_name); }
        Decode(const char *n, target_t targ, unsigned opc, Decode *sw, const char *alias_name = 0)
        : Instruction::Decode(n, targ), name(n), opcode(opc), swap_args(sw) {
            if (sw && !sw->swap_args) sw->swap_args = this;
            if (alias_name) alias(alias_name); }
        Decode(const char *n, target_t targ, unsigned opc, int flgs, Decode *sw,
               const char *alias_name = 0)
        : Instruction::Decode(n, targ), name(n), opcode(opc), swap_args(sw), flags(flgs) {
            if (sw && !sw->swap_args) sw->swap_args = this;
            if (alias_name) alias(alias_name); }
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    } const *opc;
    Operand dest;   // for ealu, use Operand::Action
    Operand src1;   // for ealu, use Operand::Phv
    Operand src2;   // for ealu, use Operand::Action
    bool ignoreSrc1 = false, ignoreSrc2 = false;
    AluOP(const Decode *op, Table *tbl, const Table::Actions::Action *act, const value_t &d,
          const value_t &s1, const value_t &s2)
        : EALUInstruction(d.lineno),
          opc(op),
          dest(tbl, act, d),
          src1(tbl, act, s1),
          src2(tbl, act, s2) {
        decode_dest(d);
    }
    std::string name() override { return opc->name; }
    Instruction *pass1(Table *tbl, Table::Actions::Action *) override;
    void pass2(Table *tbl, Table::Actions::Action *) override {
        if (auto s1 = src1.to<Operand::Phv>())
            if (!ignoreSrc1) src1->pass2(tbl, s1->reg->reg.mau_id());
        if (auto s2 = src2.to<Operand::Phv>())
            if (!ignoreSrc2) src2->pass2(tbl, s2->reg->reg.mau_id());
    }
    uint32_t encode() override;
    bool equiv(Instruction *a_) override;
    bool phvRead(std::function<void(const ::Phv::Slice &sl)> fn) override {
        bool rv = false;
        return rv; }
    void dbprint(std::ostream &out) const override {
        out << "INSTR: " << opc->name << ' ' << dest << ", " << src1 << ", " << src2 << '\n';
    }
};

struct LoadConst : EALUInstruction {
    struct Decode : Instruction::Decode {
        std::string name;
        unsigned opcode;
        Decode(const char *n, target_t targ, unsigned opc) :
        Instruction::Decode(n, targ), name(n), opcode(opc) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    } const *opc;
    Operand dest;
    int     src;
    LoadConst(Table *tbl, const Table::Actions::Action *act,
                  const value_t &d, int s1) : EALUInstruction(d.lineno), dest(tbl, act, d),
                  src(s1) {
        decode_dest(d);
    }
    LoadConst(Table *tbl, const Table::Actions::Action *act,
                  const Operand &d, int s1) : EALUInstruction(d.op->lineno), dest(d),
                  src(s1) {
    }
    std::string name() override { return opc->name; }
    Instruction *pass1(Table *tbl, Table::Actions::Action *) override;
    void pass2(Table *tbl, Table::Actions::Action *) override { }
    uint32_t encode() override;
    bool equiv(Instruction *a_) override;
    bool phvRead(std::function<void(const ::Phv::Slice &sl)> fn) override { return false; }
    void dbprint(std::ostream &out) const override {
        out << "INSTR: LoadConst " << dest << ", " << src;
    }
};

struct ShiftOP : EALUInstruction {
    struct Decode : Instruction::Decode {
        std::string name;
        unsigned opcode;
        bool use_src1;
        Decode(const char *n, target_t targ, unsigned opc, bool funnel = false)
        : Instruction::Decode(n, targ), name(n), opcode(opc), use_src1(funnel) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    } const *opc;
    Operand dest;   // for ealu, use Operand::Action
    Operand src1;   // for ealu, use Operand::Phv
    Operand src2;   // for ealu, use Operand::Action
    int shift = 0;
    ShiftOP(const Decode *op, Table *tbl, const Table::Actions::Action *act, const value_t *ops)
    : EALUInstruction(ops->lineno), opc(op), dest(tbl, act, ops[0]),
      src1(tbl, act, ops[1]), src2(tbl, act, ops[2]) {
        decode_dest(ops[0]);
        if (opc->use_src1) {
            if (CHECKTYPE(ops[3], tINT)) shift = ops[3].i;
        } else {
            src2 = src1;
            if (CHECKTYPE(ops[2], tINT)) shift = ops[2].i; } }
    std::string name() override { return opc->name; }
    Instruction *pass1(Table *tbl, Table::Actions::Action *) override;
    void pass2(Table *tbl, Table::Actions::Action *) override {
        src1->pass2(tbl, instr_word);
        src2->pass2(tbl, instr_word); }
    uint32_t encode() override;
    bool equiv(Instruction *a_) override;
    bool phvRead(std::function<void(const ::Phv::Slice &sl)> fn) override {
        return src1->phvRead(fn) | src2->phvRead(fn); }
    void dbprint(std::ostream &out) const override {
        out << "INSTR: " << opc->name << ' ' << dest << ", " << src1 << ", " << shift; }
};

struct Set : EALUInstruction {
    struct Decode : Instruction::Decode {
        std::string name;
        unsigned opcode;
        Decode(const char *n, target_t targ, unsigned opc)
            : Instruction::Decode(n, targ), name(n), opcode(opc) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) & op) const override;
    } const *opc;
    Operand dest;
    Operand src;
    int priority;
    bool chain;
    Set(const Decode *op, Table *tbl, const Table::Actions::Action *act, const value_t &d,
        const value_t &s1)
        : EALUInstruction(d.lineno), opc(op), dest(tbl, act, d), src(tbl, act, s1) {
        decode_dest(d); }
    std::string name() override { return "Set"; }
    Instruction *pass1(Table *tbl, Table::Actions::Action *) override;
    void pass2(Table *tbl, Table::Actions::Action *) override { src->pass2(tbl, instr_word); }
    uint32_t encode() override;
    bool equiv(Instruction *a_) override;
    bool phvRead(std::function<void(const ::Phv::Slice &sl)> fn) override { return false; }
    void dbprint(std::ostream &out) const override {
        out << "INSTR: EaluSet " << dest << ", " << src;
    }
};

struct BitmaskSet : EALUInstruction {
    struct Decode : Instruction::Decode {
        std::string name;
        unsigned opcode;
        Decode(const char *n, target_t targ, unsigned opc)
            : Instruction::Decode(n, targ), name(n), opcode(opc) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) & op) const override;
    } const *opc;
    Operand dest;
    Operand src1;
    uint32_t mask;
    int priority;
    bool chain;
    BitmaskSet(const Decode *op, Table *tbl, const Table::Actions::Action *act, const value_t &d,
               const value_t &s1, int mask, int prio = -1, bool chain = false)
        : EALUInstruction(d.lineno), opc(op), dest(tbl, act, d), src1(tbl, act, s1), mask(mask) {
        decode_dest(d); }
    std::string name() override { return "bitmasked-set"; }
    Instruction *pass1(Table *tbl, Table::Actions::Action *) override;
    void pass2(Table *tbl, Table::Actions::Action *) override {
        src1->pass2(tbl, instr_word); }
    uint32_t encode() override;
    bool equiv(Instruction *a_) override;
    bool phvRead(std::function<void(const ::Phv::Slice &sl)> fn) override { return false; }
    void dbprint(std::ostream &out) const override {
        out << "INSTR: bitmasked-set " << dest << ", " << src1;
    }
};

struct ByteRotateMerge : EALUInstruction {
    struct Decode : Instruction::Decode {
        std::string name;
        unsigned opcode;
        Decode(const char *n, target_t targ, unsigned opc)
            : Instruction::Decode(n, targ), name(n), opcode(opc) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) & op) const override;
    } const *opc;
    Operand dest;
    Operand src1;
    int mask;
    int rot1, rot2;
    ByteRotateMerge(const Decode *op, Table *tbl, const Table::Actions::Action *act,
                    const value_t &d, const value_t &s1, int mask, int rot1, int rot2)
        : EALUInstruction(d.lineno),
          opc(op),
          dest(tbl, act, d),
          src1(tbl, act, s1),
          mask(mask),
          rot1(rot1),
          rot2(rot2) {
        decode_dest(d); }
    std::string name() override { return "ByteRotateMerge"; }
    Instruction *pass1(Table *tbl, Table::Actions::Action *) override;
    void pass2(Table *tbl, Table::Actions::Action *) override { }
    uint32_t encode() override;
    bool equiv(Instruction *a_) override;
    bool phvRead(std::function<void(const ::Phv::Slice &sl)> fn) override { return false; }
    void dbprint(std::ostream &out) const override {
        out << "INSTR: ByteRotateMerge " << dest << ", " << src1;
    }
};

struct DepositField : EALUInstruction {
    struct Decode : Instruction::Decode {
        std::string name;
        unsigned opcode;
        Decode(const char *n, target_t targ, unsigned opc)
            : Instruction::Decode(n, targ), name(n), opcode(opc) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) & op) const override;
    } const *opc;
    Operand dest;
    Operand src1;
    Operand src2;
    int hibit, lobit;
    int rot;
    int priority;
    bool chain;
    DepositField(const Decode *op, Table *tbl, const Table::Actions::Action *act, const value_t &d,
                 const value_t &s1, const value_t &s2, int hibit = -1, int lobit = -1, int rot = -1,
                 int priority = -1, bool chain = false)
        : EALUInstruction(d.lineno),
          opc(op),
          dest(tbl, act, d),
          src1(tbl, act, s1),
          src2(tbl, act, s2),
          hibit(hibit),
          lobit(lobit),
          rot(rot),
          priority(priority),
          chain(chain) {
        decode_dest(d);
    }
    std::string name() override { return "deposit-field"; }
    Instruction *pass1(Table *tbl, Table::Actions::Action *) override;
    void pass2(Table *tbl, Table::Actions::Action *) override { }
    uint32_t encode() override;
    bool equiv(Instruction *a_) override;
    bool phvRead(std::function<void(const ::Phv::Slice &sl)> fn) override { return false; }
    void dbprint(std::ostream &out) const override {
        out << "INSTR: deposit-field " << dest << ", " << src1 << ", " << src2;
    }
};

}  // namespace EALU
}  // namespace Flatrock
#endif  /* FLATROCK_INSTRUCTION_H_ */
