#include "instruction.h"

#include "action_bus.h"
#include "phv.h"
#include "stage.h"
#include "tables.h"

namespace Flatrock {

struct operand {
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
        virtual void dbprint(std::ostream &) const = 0;
        virtual bool equiv(const Base *) const = 0;
        virtual bool phvRead(std::function<void(const ::Phv::Slice &sl)>) { return false; }
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
        int bits(int) override { return value & 0xff; }
        void pass1(Table *tbl, int slot) override {
            if (::Phv::reg(slot)->size != 8)
                error(lineno, "Constant literals only useable on 8-bit PHEs");
            if (value > 255 || value < -128)
                error(lineno, "Constant value %" PRId64 " out of range", value); }
        void dbprint(std::ostream &out) const override { out << value; }
    };
    struct Phv : Base {
        ::Phv::Ref      reg;
        Phv(int line, gress_t g, int stage, const value_t &n) : Base(line), reg(g, stage, n) {}
        Phv(int line, gress_t g, int stage, const std::string &n, int l, int h) :
            Base(line), reg(g, stage, line, n, l, h) {}
        explicit Phv(const ::Phv::Ref &r) : Base(r.lineno), reg(r) {}
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const Phv *>(a_)) {
                return reg == a->reg;
            } else { return false; } }
        Phv *clone() override { return new Phv(*this); }
        int bits(int) override {
            error(lineno, "Flatrock action data bus regs not implemented yet");
            return 0; }
        bool check() override {
            if (!reg.check()) return false;
            if (reg->reg.mau_id() < 0) {
                error(reg.lineno, "%s not accessable in mau", reg->reg.name);
                return false; }
            return true; }
        void pass1(Table *tbl, int) override {
            tbl->stage->action_use[tbl->gress][reg->reg.uid] = true; }
        void pass2(Table *tbl, int slot) override {
            InputXbar::Group grp(InputXbar::Group::XCMP, -1);
            int byte = tbl->find_on_ixbar(*reg, grp, &grp);
            if (byte < 0) {
                error(reg.lineno, "%s not available on the xcmp ixbar", reg.name());
                return; }
            ActionBusSource abs(grp, byte);
            if (tbl->find_on_actionbus(abs, reg->lo, reg->hi, ::Phv::reg(slot)->size) < 0)
                tbl->need_on_actionbus(abs, reg->lo, reg->hi, ::Phv::reg(slot)->size); }
        void dbprint(std::ostream &out) const override { out << reg; }
        bool phvRead(std::function<void(const ::Phv::Slice &sl)> fn) override {
            fn(*reg);
            return true; }
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
            int size = ::Phv::reg(slot)->size;
            error(lineno, "Flatrock ADB decode not implemented yet"); }
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
        void dbprint(std::ostream &out) const override { out << 'A' << index; }
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
        void pass1(Table *, int) override { BUG(); }
        void dbprint(std::ostream &out) const override {
            out << name;
            if (lo >= 0) {
                out << '(' << lo;
                if (hi >= 0 && hi != lo) out << ".. " << hi;
                out << ')'; }
            out << '[' << tbl->name() << ':' << action << ']'; }
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
    operand(gress_t gress, int stage, const value_t &v) : op(new Phv(v.lineno, gress, stage, v)) {}
    explicit operand(const ::Phv::Ref &r) : op(new Phv(r)) {}
    bool valid() const { return op != 0; }
    bool operator==(operand &a) {
        return op == a.op || (op && a.op && op->lookup(op)->equiv(a.op->lookup(a.op))); }
    bool check() { return op && op->lookup(op) ? op->check() : false; }
    void dbprint(std::ostream &out) const { op->dbprint(out); }
    Base *operator->() { return op->lookup(op); }
    template <class T> T *to() { return dynamic_cast<T *>(op->lookup(op)); }
};

static void parse_slice(const VECTOR(value_t) &vec, int idx, int &lo, int &hi) {
    if (PCHECKTYPE2(vec.size == idx+1, vec[idx], tINT, tRANGE)) {
        if (vec[idx].type == tINT) {
            lo = hi = vec[idx].i;
        } else {
            lo = vec[idx].lo;
            hi = vec[idx].hi; } }
}

operand::operand(Table *tbl, const Table::Actions::Action *act, const value_t &v) : op(0) {
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

auto operand::Named::lookup(Base *&ref) -> Base * {
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

struct VLIWInstruction : Instruction {
    // Mostly just a shim to ensure these instructions are only used on Flatrock
    explicit VLIWInstruction(int l) : Instruction(l) {}
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        void write_regs, (mau_regs &, Table *, Table::Actions::Action *), override {
            BUG("Flatrock instruction on %s?", Target::name()); })
};

struct PhvWrite : VLIWInstruction {
    struct Decode : Instruction::Decode {
        std::string name;
        unsigned opcode;
        Decode(const char *n, target_t targ, unsigned op)
        : Instruction::Decode(n, targ), name(n), opcode(op) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    } const *opc;
    Phv::Ref    alu_slot;
    Phv::Ref    dest;
    operand     src;
    PhvWrite(const Decode *op, Table *tbl, const Table::Actions::Action *act,
             const value_t &d, const value_t &s) : VLIWInstruction(d.lineno),
         opc(op), dest(tbl->gress, tbl->stage->stageno + 1, d), src(tbl, act, s) {}
    std::string name() { return "set"; }
    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    void pass2(Table *tbl, Table::Actions::Action *) { src->pass2(tbl, slot); }
    bool equiv(Instruction *a_);
    bool phvRead(std::function<void(const ::Phv::Slice &sl)> fn) { return src->phvRead(fn); }
    void dbprint(std::ostream &out) const {
        out << "INSTR: set " << dest << ", " << src; }
    void write_regs(Target::Flatrock::mau_regs &, Table *, Table::Actions::Action *) override;
};

static PhvWrite::Decode opNoop  ("noop",  FLATROCK, 0),                                 // NOLINT
                        opSet   ("set",   FLATROCK, 1),                                 // NOLINT
                        opAndc  ("andc",  FLATROCK, 2),                                 // NOLINT
                        opOr    ("or",    FLATROCK, 3),                                 // NOLINT
                        opSetz  ("setz",  FLATROCK, 4),                                 // NOLINT
                        opSetbm ("setbm", FLATROCK, 5);                                 // NOLINT

Instruction *PhvWrite::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                 const VECTOR(value_t) &op) const {
    if (op.size != 3 && op.size != 4) {
        error(op[0].lineno, "%s requires 2 or 3 operands", op[0].s);
        return 0; }
    PhvWrite *rv = new PhvWrite(this, tbl, act, op[op.size-2], op[op.size-1]);
    if (op.size == 3)
        rv->alu_slot = rv->dest;
    else
        rv->alu_slot = Phv::Ref(tbl->gress, tbl->stage->stageno + 1, op[1]);
    if (!rv->src.valid()) {
        error(op[2].lineno, "invalid src");
        delete rv;
        return 0; }
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
    if (static_cast<unsigned>(dest->reg.mau_id() - slot) > 1) {
        error(lineno, "Can't write to %s using PhvWrite for %s",
              dest->reg.name, alu_slot->reg.name); }
    tbl->stage->action_set[tbl->gress][dest->reg.uid] = true;
    src->pass1(tbl, slot);
    return this;
}

bool PhvWrite::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<PhvWrite *>(a_)) {
        return opc == a->opc && dest == a->dest && src == a->src;
    } else {
        return false;
    }
}

void PhvWrite::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
                          Table::Actions::Action *act) {
    if (act != tbl->stage->imem_addr_use[tbl->gress][act->addr]) {
        LOG3("skipping " << tbl->name() << '.' << act->name << " as its imem is used by " <<
             tbl->stage->imem_addr_use[tbl->gress][act->addr]->name);
        return; }
    LOG2(this);
    auto &imem = regs.ppu_phvwr_rspec.imem;
    int iaddr = act->addr / Target::Flatrock::IMEM_COLORS;
    int color = act->addr % Target::Flatrock::IMEM_COLORS;
    int merge_dest = dest->reg.mau_id() - slot;
    uint32_t dest_mask = ((1U << dest->hi) << 1) - (1U << dest->lo);
    uint32_t bits = 0;
    BUG_CHECK(slot >= 0);
    switch (Phv::reg(slot)->size) {
    case 8:
        imem.imem8[slot].phvwr_imem8[iaddr].color = color;
        imem.imem8[slot].phvwr_imem8[iaddr].imm_addr = src->bits(slot);
        imem.imem8[slot].phvwr_imem8[iaddr].mask = dest_mask;
        imem.imem8[slot].phvwr_imem8[iaddr].merge_dest = merge_dest;
        imem.imem8[slot].phvwr_imem8[iaddr].opcode = opc->opcode;
        imem.imem8[slot].phvwr_imem8[iaddr].sel_imm = src.to<operand::Const>() ? 1 : 0;
        bits = imem.imem8[slot].phvwr_imem8[iaddr];
        break;
    case 16:
        imem.imem16[slot-160].phvwr_imem16[iaddr].color = color;
        imem.imem16[slot-160].phvwr_imem16[iaddr].addr = src->bits(slot);
        imem.imem16[slot-160].phvwr_imem16[iaddr].merge_dest = merge_dest;
        imem.imem16[slot-160].phvwr_imem16[iaddr].opcode = opc->opcode;
        bits = imem.imem16[slot-160].phvwr_imem16[iaddr];
        break;
    case 32:
        imem.imem32[slot-200].phvwr_imem32[iaddr].color = color;
        imem.imem32[slot-200].phvwr_imem32[iaddr].addr = src->bits(slot);
        imem.imem32[slot-200].phvwr_imem32[iaddr].merge_dest = merge_dest;
        imem.imem32[slot-200].phvwr_imem32[iaddr].opcode = opc->opcode;
        bits = imem.imem32[slot-200].phvwr_imem32[iaddr];
        break;
    default:
        BUG(); }
    regs.ppu_phvwr_rspec.parity.phvwr_parity[iaddr].parity[color] ^= parity_2b(bits);
}

}  // end namespace Flatrock
