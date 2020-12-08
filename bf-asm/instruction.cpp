#include "instruction.h"

#include <config.h>

#include "action_bus.h"
#include "power_ctl.h"
#include "phv.h"
#include "depositfield.h"
#include "stage.h"
#include "tables.h"

namespace {
constexpr int RotationBits = 16;
}

std::multimap<std::string, Instruction::Decode *>
    Instruction::Decode::opcode[Instruction::NUM_SETS];

Instruction::Decode::Decode(const char *name, int set, bool ts) : type_suffix(ts) {
    targets = ~0U;
    for (auto d : ValuesForKey(opcode[set], name)) {
        BUG_CHECK(!(d->targets & 1));
        targets &= ~d->targets; }
    BUG_CHECK(targets > 1);
    opcode[set].emplace(name, this);
}
Instruction::Decode::Decode(const char *name, target_t target, int set, bool ts) : type_suffix(ts) {
    targets = 1 << target;
    for (auto d : ValuesForKey(opcode[set], name)) {
        if (d->targets & 1) {
            d->targets &= ~targets;
            BUG_CHECK(d->targets > 1); } }
    opcode[set].emplace(name, this);
}
Instruction::Decode::Decode(const char *name, std::set<target_t> target, int set, bool ts)
: type_suffix(ts), targets(0) {
    for (auto t : target)
        targets |= 1 << t;
    BUG_CHECK(targets > 1);
    for (auto d : ValuesForKey(opcode[set], name)) {
        if (d->targets & 1) {
            d->targets &= ~targets;
            BUG_CHECK(d->targets > 1); } }
    opcode[set].emplace(name, this);
}

Instruction *Instruction::decode(Table *tbl, const Table::Actions::Action *act,
                                 const VECTOR(value_t) &op) {
    for (auto d : ValuesForKey(Instruction::Decode::opcode[tbl->instruction_set()], op[0].s)) {
        if ((d->targets >> Target::register_set()) & 1)
            return d->decode(tbl, act, op); }
    if (auto p = strchr(op[0].s, '.')) {
        std::string opname(op[0].s, p - op[0].s);
        for (auto d : ValuesForKey(Instruction::Decode::opcode[tbl->instruction_set()], opname)) {
            if (((d->targets >> options.target) & 1) && d->type_suffix)
                return d->decode(tbl, act, op); } }
    return 0;
}

namespace VLIW {
static const int group_size[] = { 32, 32, 32, 32, 8, 8, 8, 8, 16, 16, 16, 16, 16, 16 };

struct operand {
    /** A source operand to a VLIW instruction -- this can be a variety of things, so we
     * have a pointer to an abstract base class and a number of derived concrete classes for
     * the different kinds of operands.  When we parse the operand, the type may be determined,
     * or if it is just a name, we will have to wait to a later pass to resolve what the
     * name refers to.  At that point, the `Named' object created in parsing will be replaced
     * with the actual operand type */
    static const int ACTIONBUS_OPERAND = 0x20;
    struct Base {
        int     lineno;
        explicit Base(int line) : lineno(line) {}
        Base(const Base &a) : lineno(a.lineno) {}
        virtual ~Base() {}
        virtual Base *clone() = 0;
        virtual Base *lookup(Base *&ref) { return this; }
        virtual bool check() { return true; }
        virtual int phvGroup() { return -1; }
        virtual int bits(int group, int dest_size = -1) = 0;
        virtual unsigned bitoffset(int group) const { return 0; }
        virtual void dbprint(std::ostream &) const = 0;
        virtual bool equiv(const Base *) const = 0;
        virtual void phvRead(std::function<void(const ::Phv::Slice &sl)>) {}
        /** pass1 called as part of pass1 processing of stage
         * @tbl - table containing the action with the instruction with this operand
         * @group - mau PHV group of the ALU (dest) for this instruction */
        virtual void pass1(Table *tbl, int group) {}
        /** pass2 called as part of pass2 processing of stage
         * @group - mau PHV group of the ALU (dest) for this instruction */
        virtual void pass2(int group) {}
    } *op;
    struct Const : Base {
        int64_t value;
        Const(int line, int64_t v) : Base(line), value(v) {}
        bool equiv(const Base *a_) const override {
            if (auto *a = dynamic_cast<const Const *>(a_)) {
                return value == a->value;
            } else { return false; } }
        Const *clone() override { return new Const(*this); }
        int32_t bits(int group, int dest_size = -1) override {
            // assert(value <= 0xffffffffLL);
            int32_t val = value;
            if (val > 0 && ((val >> (group_size[group] - 1)) & 1))
                val |= UINT64_MAX << group_size[group];
            int minconst = Target::MINIMUM_INSTR_CONSTANT();

            if (dest_size != -1) {  // DepositField::encode() calling.
                auto rotConst
                    = DepositField::discoverRotation(val, group_size[group], 8, minconst - 1);
                if (rotConst.rotate)
                    return rotConst.value+24 | (rotConst.rotate << RotationBits);
            }

            if (val >= minconst && val < 8)
                return val+24;
            error(lineno, "constant value %" PRId64 " out of range for immediate", value);
            return -1; }
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
        bool check() override {
            if (!reg.check()) return false;
            if (reg->reg.mau_id() < 0) {
                error(reg.lineno, "%s not accessable in mau", reg->reg.name);
                return false; }
            return true;
        }
        int phvGroup() override { return reg->reg.mau_id() / ::Phv::mau_groupsize(); }
        int bits(int group, int dest_size = -1) override {
            if (group != phvGroup()) {
                error(lineno, "registers in an instruction must all be in the same phv group");
                return -1; }
            return reg->reg.mau_id() % ::Phv::mau_groupsize(); }
        unsigned bitoffset(int group) const override { return reg->lo; }
        void pass1(Table *tbl, int) override {
            tbl->stage->action_use[tbl->gress][reg->reg.uid] = true; }
        void dbprint(std::ostream &out) const override { out << reg; }
        void phvRead(std::function<void(const ::Phv::Slice &sl)> fn) override { fn(*reg); }
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
        int bits(int group, int dest_size = -1) override {
            int size = group_size[group]/8U;
            BUG_CHECK(lo >= 0 && hi >= 0);
            unsigned lo = this->lo, hi = this->hi;
            if (dest_size > 0) {
                // override size based on destination size for deposit-field
                hi = lo + dest_size - 1;
                unsigned mask = group_size[group] - 1;  // group size is power of 2 (8, 16, or 32)
                if ((hi | mask) != (lo | mask)) {
                    // crosses slot boundary, so is a wrap-around rotated source -- need all of it
                    lo &= ~mask;
                    hi = lo | mask; } }
            int byte = field ? table->find_on_actionbus(field, lo, hi, size)
                             : table->find_on_actionbus(name, mod, lo, hi, size);
            if (byte < 0) {
                if (this->lo > 0 || (field && this->hi + 1 < int(field->size)))
                    error(lineno, "%s(%d..%d) is not on the action bus", name.c_str(), lo, hi);
                else
                    error(lineno, "%s is not on the action bus", name.c_str());
                return -1; }
            int byte_value = byte;
            if (size == 2) byte -= 32;
            if (byte < 0 || byte > 32*size)
                error(lineno, "action bus entry %d(%s) out of range for %d-bit access",
                      byte_value, name.c_str(), size*8);
            // else if (byte % size != 0)
            //     error(lineno, "action bus entry %d(%s) misaligned for %d-bit access",
            //           byte_value, name.c_str(), size*8);
            else
                return ACTIONBUS_OPERAND + byte/size;
            return -1; }
        void pass1(Table *tbl, int group) override {
            if (field) field->flags |= Table::Format::Field::USED_IMMED;
            if (lo >= 0 && hi >= 0 && lo/group_size[group] != hi/group_size[group]) {
                error(lineno, "action bus slice (%d..%d) can't fit in a single slot for %d bit "
                      "access", lo, hi, group_size[group]);
                // chop it down to be in range (avoid error cascade)
                hi = lo | (group_size[group]-1); } }
        void pass2(int group) override {
            int bits = group_size[group];
            unsigned bytes = bits/8U;
            if (lo < 0) lo = 0;
            if (hi < 0) hi = lo + bits - 1;
            if (hi > lo + bits - 1) {
                warning(lineno, "%s(%d..%d) larger than %d bit access", name.c_str(), lo, hi, bits);
                hi = lo + bits - 1; }
            if ((lo ^ hi) & ~(bits-1))
                error(lineno, "%s(%d..%d) can't be accessed by %d bit PHV",
                      name.c_str(), lo, hi, bits);
            if (field && table->find_on_actionbus(field, lo, hi, bytes) < 0) {
                int immed_offset = 0;
                if (table->format && table->format->immed)
                    immed_offset = table->format->immed->bit(0);
                int l = field->bit(lo) - immed_offset, h = field->bit(hi) - immed_offset;
                if (l%bits != 0 && l/bits != h/bits)
                    error(lineno, "%s misaligned for action bus", name.c_str());
                table->need_on_actionbus(field, lo, hi, bytes);
            } else if (!field && table->find_on_actionbus(name, mod, lo, hi, bytes) < 0) {
                if (Table::all.count(name))
                    table->need_on_actionbus(Table::all.at(name), mod, lo, hi, bytes);
                else
                    error(lineno, "Can't find any operand named %s", name.c_str()); } }
        unsigned bitoffset(int group) const override {
            int size = group_size[group]/8U;
            int byte = field ? table->find_on_actionbus(field, lo, hi, size)
                             : table->find_on_actionbus(name, lo, hi, size);
            return 8*(byte % size) + lo % 8; }
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
        int bits(int group, int dest_size = -1) override { return ACTIONBUS_OPERAND + index; }
        unsigned bitoffset(int group) const override { return offset; }
        void dbprint(std::ostream &out) const override { out << 'A' << index; }
    };
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
        void dbprint(std::ostream &out) const override {
            out << "rng " << rng.unit << '(' << lo << ".." << hi << ')'; }
    };
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
        int phvGroup() override { BUG(); return -1; }
        int bits(int group, int dest_size = -1) override { BUG(); return 0; }
        unsigned bitoffset(int group) const override { BUG(); return 0; }
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
    unsigned bitoffset(int group) { return op->lookup(op)->bitoffset(group); }
    bool check() { return op && op->lookup(op) ? op->check() : false; }
    int phvGroup() { return op->lookup(op)->phvGroup(); }
    void phvRead(std::function<void(const ::Phv::Slice &sl)> fn) { op->lookup(op)->phvRead(fn); }
    int bits(int group, int dest_size = -1) { return op->lookup(op)->bits(group, dest_size); }
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
            if (v == "hash_dist" && (op = HashDist::parse(tbl, v.vec)))
                return;
            if (v == "rng" && (op = new RandomGen(tbl, v.vec)))
                return;
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
        if (name == "hash_dist" && lo == hi) {
            auto hd = new HashDist(v.lineno, tbl, lo);
            if (v.type == tCMD && v[1].type == tRANGE) {
                hd->lo = v[1].lo;
                hd->hi = v[1].hi; }
            op = hd;
            return; }
        op = new Named(v.lineno, name, mod, lo, hi, tbl, act->name, p4name); }
}

auto operand::Named::lookup(Base *&ref) -> Base * {
    int slot, len = -1;
    if (tbl->action) tbl = tbl->action;
    int lo = this->lo >= 0 ? this->lo : 0;
    if (auto *field = tbl->lookup_field(name, action)) {
        if (!options.match_compiler) {
            /* FIXME -- The glass compiler generates refs past the end of action table fields
             * like these, and just accesses whatever bits happen to be there.  So we
             * supress these error checks for compatibility (ex: tests/action_bus1.p4) */
            if ((unsigned)lo >= field->size) {
                error(lineno, "Bit %d out of range for field %s", lo, name.c_str());
                ref = 0;
            } else if (hi >= 0 && (unsigned)hi >= field->size) {
                error(lineno, "Bit %d out of range for field %s", hi, name.c_str());
                ref = 0; } }
        if (ref) {
            ref = new Action(lineno, name, tbl, field, lo,
                             hi >= 0 ? hi : field->size - 1, p4name);
        }
    } else if (tbl->find_on_actionbus(name, mod, lo, hi >= 0 ? hi : 7, 0, &len) >= 0) {
        ref = new Action(lineno, name, mod, tbl, lo, hi >= 0 ? hi : len - 1, p4name);
    } else if (::Phv::get(tbl->gress, tbl->stage->stageno, name)) {
        ref = new Phv(lineno, tbl->gress, tbl->stage->stageno, name, lo, hi);
    } else if (sscanf(name.c_str(), "A%d%n", &slot, &len) >= 1 &&
               len == static_cast<int>(name.size()) && slot >= 0 && slot < 32) {
        ref = new RawAction(lineno, slot, lo);
    } else if (name == "hash_dist" && (lo == hi || hi < 0)) {
        ref = new HashDist(lineno, tbl, lo);
    } else if (Table::all.count(name)) {
        ref = new Action(lineno, name, mod, tbl, lo, hi, p4name);
    } else {
        ref = new Phv(lineno, tbl->gress, tbl->stage->stageno, name, this->lo, hi); }
    if (ref != this) delete this;
    return ref;
}

struct VLIWInstruction : Instruction {
    explicit VLIWInstruction(int l) : Instruction(l) {}
    virtual int encode() = 0;
#if HAVE_JBAY || HAVE_CLOUDBREAK
    template<class REGS> void write_regs_2(REGS &regs, Table *tbl, Table::Actions::Action *act);
#endif
    FOR_ALL_REGISTER_SETS(DECLARE_FORWARD_VIRTUAL_INSTRUCTION_WRITE_REGS)
};

#include "tofino/instruction.cpp"
#if HAVE_JBAY
#include "jbay/instruction.cpp"
#endif  // HAVE_JBAY
#if HAVE_CLOUDBREAK
#include "cloudbreak/instruction.cpp"
#endif  // HAVE_CLOUDBREAK

struct AluOP : VLIWInstruction {
    const struct Decode : Instruction::Decode {
        std::string name;
        unsigned opcode;
        const Decode *swap_args;
        Decode(const char *n, unsigned opc, bool assoc = false) : Instruction::Decode(n), name(n),
            opcode(opc), swap_args(assoc ? this : 0) {}
        Decode(const char *n, target_t targ, unsigned opc, bool assoc = false)
        : Instruction::Decode(n, targ), name(n), opcode(opc), swap_args(assoc ? this : 0) {}
        Decode(const char *n, std::set<target_t> targ, unsigned opc, bool assoc = false)
        : Instruction::Decode(n, targ), name(n), opcode(opc), swap_args(assoc ? this : 0) {}
        Decode(const char *n, unsigned opc, Decode *sw, const char *alias_name = 0)
        : Instruction::Decode(n), name(n), opcode(opc), swap_args(sw) {
            if (sw && !sw->swap_args) sw->swap_args = this;
            if (alias_name) alias(alias_name); }
        Decode(const char *n, target_t targ, unsigned opc, Decode *sw, const char *alias_name = 0)
        : Instruction::Decode(n, targ), name(n), opcode(opc), swap_args(sw) {
            if (sw && !sw->swap_args) sw->swap_args = this;
            if (alias_name) alias(alias_name); }
        Decode(const char *n, std::set<target_t> targ, unsigned opc, Decode *sw,
               const char *alias_name = 0)
        : Instruction::Decode(n, targ), name(n), opcode(opc), swap_args(sw) {
            if (sw && !sw->swap_args) sw->swap_args = this;
            if (alias_name) alias(alias_name); }
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    } *opc;
    Phv::Ref    dest;
    operand     src1, src2;
    AluOP(const Decode *op, Table *tbl, const Table::Actions::Action *act, const value_t &d,
          const value_t &s1, const value_t &s2)
    : VLIWInstruction(d.lineno), opc(op), dest(tbl->gress, tbl->stage->stageno + 1, d),
      src1(tbl, act, s1), src2(tbl, act, s2) {}
    std::string name() { return opc->name; }
    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    void pass2(Table *tbl, Table::Actions::Action *) {
        src1->pass2(slot/Phv::mau_groupsize());
        src2->pass2(slot/Phv::mau_groupsize()); }
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void(const ::Phv::Slice &sl)> fn) {
        src1.phvRead(fn); src2.phvRead(fn); }
    void dbprint(std::ostream &out) const {
        out << "INSTR: " << opc->name << ' ' << dest << ", " << src1 << ", " << src2; }
};

struct AluOP3Src : AluOP {
    struct Decode : AluOP::Decode {
        Decode(const char *n, unsigned opc) : AluOP::Decode(n, opc) {}
        Decode(const char *n, target_t t, unsigned opc) : AluOP::Decode(n, t, opc) {}
        Decode(const char *n, std::set<target_t> t, unsigned opc) : AluOP::Decode(n, t, opc) {}
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

Instruction *AluOP::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                   const VECTOR(value_t) &op) const {
    AluOP *rv;
    if (op.size == 4) {
        rv = new AluOP(this, tbl, act, op.data[1], op.data[2], op.data[3]);
    } else if (op.size == 3) {
        rv = new AluOP(this, tbl, act, op.data[1], op.data[1], op.data[2]);
    } else {
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
    src1->pass1(tbl, slot/Phv::mau_groupsize());
    src2->pass1(tbl, slot/Phv::mau_groupsize());
    if (src2.phvGroup() < 0 && opc->swap_args) {
        std::swap(src1, src2);
        opc = opc->swap_args; }
    if (src2.phvGroup() < 0)
        error(lineno, "src2 must be phv register");
    return this;
}
Instruction *AluOP3Src::pass1(Table *tbl, Table::Actions::Action *act) {
    AluOP::pass1(tbl, act);
    src3->pass1(tbl, slot/Phv::mau_groupsize());
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
    int rv = (opc->opcode << 6) | src1.bits(slot/Phv::mau_groupsize());
    rv <<= Target::INSTR_SRC2_BITS();
    return rv | src2.bits(slot/Phv::mau_groupsize());
}
bool AluOP::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<AluOP *>(a_)) {
        return opc == a->opc && dest == a->dest && src1 == a->src1 && src2 == a->src2;
    } else {
        return false;
    }
}

struct LoadConst : VLIWInstruction {
    struct Decode : Instruction::Decode {
        explicit Decode(const char *n) : Instruction::Decode(n) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    };
    Phv::Ref    dest;
    int         src;
    LoadConst(Table *tbl, const Table::Actions::Action *act, const value_t &d, int s)
        : VLIWInstruction(d.lineno), dest(tbl->gress, tbl->stage->stageno + 1, d), src(s) {}
    LoadConst(int line, Phv::Ref &d, int v) : VLIWInstruction(line), dest(d), src(v) {}
    std::string name() { return ""; }
    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    void pass2(Table *, Table::Actions::Action *) {}
    int encode() { return Target::encodeConst(src); }
    bool equiv(Instruction *a_);
    void phvRead(std::function<void(const ::Phv::Slice &sl)> fn) { }
    void dbprint(std::ostream &out) const {
        out << "INSTR: set " << dest << ", " << src; }
};

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
    if (size > 21)
        size = 21;
    // The load const source is an unsigned constant (even though the uArch for Tofino says that
    // the source is signed, this is not true);
    if (src >= (1 << size) || src < 0)
        error(lineno, "Constant value %d out of range", src);
    src &= (1 << size) - 1;
    tbl->stage->action_set[tbl->gress][dest->reg.uid] = true;
    return this;
}

bool LoadConst::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<LoadConst *>(a_)) {
        return dest == a->dest && src == a->src;
    } else {
        return false;
    }
}

struct CondMoveMux : VLIWInstruction {
    const struct Decode : Instruction::Decode {
        std::string name;
        unsigned opcode, cond_size;
        bool    src2opt;
        Decode(const char *name, unsigned opc, unsigned csize, bool s2opt, const char *alias_name)
        : Instruction::Decode(name), name(name), opcode(opc), cond_size(csize), src2opt(s2opt) {
            alias(alias_name); }
        Decode(const char *name, target_t targ, unsigned opc, unsigned csize, bool s2opt,
               const char *alias_name) : Instruction::Decode(name, targ), name(name),
               opcode(opc), cond_size(csize), src2opt(s2opt) {
            alias(alias_name); }
        Decode(const char *name, std::set<target_t> targ, unsigned opc, unsigned csize, bool s2opt,
               const char *alias_name) : Instruction::Decode(name, targ), name(name),
               opcode(opc), cond_size(csize), src2opt(s2opt) {
            alias(alias_name); }
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    } *opc;
    Phv::Ref    dest;
    operand     src1, src2;
    unsigned    cond = 0;
    CondMoveMux(Table *tbl, const Decode *op, const Table::Actions::Action *act,
                const value_t &d, const value_t &s)
    : VLIWInstruction(d.lineno), opc(op), dest(tbl->gress, tbl->stage->stageno + 1, d),
      src1(tbl, act, s), src2(tbl->gress, tbl->stage->stageno, d) {}
    CondMoveMux(Table *tbl, const Decode *op, const Table::Actions::Action *act,
                const value_t &d, const value_t &s1, const value_t &s2)
    : VLIWInstruction(d.lineno), opc(op), dest(tbl->gress, tbl->stage->stageno + 1, d),
      src1(tbl, act, s1), src2(tbl, act, s2) {}
    std::string name() { return opc->name; }
    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    void pass2(Table *tbl, Table::Actions::Action *) {
        src1->pass2(slot/Phv::mau_groupsize());
        src2->pass2(slot/Phv::mau_groupsize()); }
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void(const ::Phv::Slice &sl)> fn) {
        if (cond & 1) fn(*dest);
        src1.phvRead(fn);
        if (!opc->src2opt || (cond & 4))
            src2.phvRead(fn); }
    void dbprint(std::ostream &out) const {
        out << "INSTR: cmov " << dest << ", " << src1 << ", " << src2; }
};

Instruction *CondMoveMux::Decode::decode(Table *tbl, const Table::Actions::Action *act,
                                         const VECTOR(value_t) &op) const {
    if (op.size != 5 && (op.size != 4 || !src2opt)) {
        error(op[0].lineno, "%s requires %s4 operands", op[0].s, src2opt ? "3 or " : "");
        return 0; }
    if (!CHECKTYPE(op[op.size-1], tINT)) {
        if (op[op.size-1].i < 0 || op[op.size-1].i >= (1 << cond_size)) {
            error(op[op.size-1].lineno, "%s condition must be %d-bit constant", op[0].s, cond_size);
            return 0;
        }
    }
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
    src1->pass1(tbl, slot/Phv::mau_groupsize());
    src2->pass1(tbl, slot/Phv::mau_groupsize());
    return this;
}
int CondMoveMux::encode() {
    int rv = (cond << 11) | (opc->opcode << 6) | src1.bits(slot/Phv::mau_groupsize());
    rv <<= Target::INSTR_SRC2_BITS();
    /* funny cond test on src2 is to match the compiler output -- if we're not testing
     * src2 validity, what we specify as src2 is irrelevant */
    return rv | (cond & 0x40 ? src2.bits(slot/Phv::mau_groupsize()) : 0);
}
bool CondMoveMux::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<CondMoveMux *>(a_)) {
        return opc == a->opc && dest == a->dest && src1 == a->src1 && src2 == a->src2 &&
               cond == a->cond;
    } else {
        return false;
    }
}

/**
 * This instruction represents the Byte-Rotate-Merge instruction described in the
 * uArch section 14.1.6.5 Byte-rotate-merge section.
 */
struct ByteRotateMerge : VLIWInstruction {
    struct Decode : Instruction::Decode {
        Decode() : Instruction::Decode("byte_rotate_merge") { alias("byte-rotate-merge"); }
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const;
    };
    Phv::Ref dest;
    operand src1, src2;
    bitvec byte_mask;
    int src1_shift, src2_shift;
    ByteRotateMerge(Table *tbl, const Table::Actions::Action *act, const value_t &d,
        const value_t &s1, const value_t &s2, int s1s, int s2s, int bm)
    : VLIWInstruction(d.lineno), dest(tbl->gress, tbl->stage->stageno + 1, d),
      src1(tbl, act, s1), src2(tbl, act, s2), src1_shift(s1s), src2_shift(s2s), byte_mask(bm) {}

    std::string name() { return "byte_rotate_merge"; }
    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    void pass2(Table *tbl, Table::Actions::Action *) {
        src1->pass2(slot/Phv::mau_groupsize());
        src2->pass2(slot/Phv::mau_groupsize());
    }
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void(const ::Phv::Slice &sl)> fn) {
        src1.phvRead(fn); src2.phvRead(fn);
    }
    void dbprint(std::ostream &out) const {
        out << "INSTR: byte_rotate_merge " << dest << ", " << src1 << ", " << src2 << " "
            << byte_mask;
    }
};

/**
 * Unlike deposit-field, because of the non-contiguity of both sources possibly, the
 * full instruction with both sources, shifts and byte mask are required
 */
Instruction *ByteRotateMerge::Decode::decode(Table *tbl, const Table::Actions::Action *act,
       const VECTOR(value_t) &op) const {
    if (op.size != 7) {
        error(op[0].lineno, "%s requires 6 operands", op[0].s);
        return 0;
    }
    if (!CHECKTYPE(op[4], tINT) || !CHECKTYPE(op[5], tINT) || !CHECKTYPE(op[6], tINT)) {
        error(op[0].lineno, "%s requires operands 3-5 to be ints", op[0].s);
        return 0;
    }

    ByteRotateMerge *rv = new ByteRotateMerge(tbl, act, op[1], op[2], op[3], op[4].i,
                                              op[5].i, op[6].i);
    if (!rv->src1.valid())
        error(op[2].lineno, "invalid src1");
    else if (!rv->src2.valid())
        error(op[3].lineno, "invalid src2");
    else
        return rv;
    delete rv;
    return 0;
}

/**
 * The shifts at most can be container.size / 8 and the byte mask bit count can be at most
 * container.size / 8.
 */
Instruction *ByteRotateMerge::pass1(Table *tbl, Table::Actions::Action *) {
    if (!dest.check() || !src1.check() || !src2.check()) return this;
    if (dest->reg.mau_id() < 0) {
        error(dest.lineno, "%s not accessable in mau", dest->reg.name);
        return this; }
    if (dest->reg.type != Phv::Register::NORMAL) {
        error(dest.lineno, "byte-rotate-merge dest can't be dark or mocha phv");
        return this; }
    if (dest->reg.size == 8) {
        error(dest.lineno, "byte-rotate-merge invalid on 8 bit containers");
        return this; }
    if (byte_mask.max().index() > dest->reg.size / 8) {
        error(dest.lineno, "byte-rotate-merge mask beyond container size bounds");
        return this; }
    if (src1_shift > dest->reg.size / 8) {
        error(dest.lineno, "byte-rotate-merge src1_shift beyond container size bounds");
        return this; }
    if (src2_shift > dest->reg.size / 8) {
        error(dest.lineno, "byte-rotate-merge src2_shift beyond container size bounds");
        return this; }
    slot = dest->reg.mau_id();
    tbl->stage->action_set[tbl->gress][dest->reg.uid] = true;
    src1->pass1(tbl, slot/Phv::mau_groupsize());
    src2->pass1(tbl, slot/Phv::mau_groupsize());
    src2->pass1(tbl, slot/Phv::mau_groupsize());
    if (src2.phvGroup() < 0) {
        std::swap(src1, src2);
        std::swap(src1_shift, src2_shift);
        byte_mask = bitvec(0, dest->reg.size / 8) - byte_mask;
    }
    if (src2.phvGroup() < 0)
        error(lineno, "src2 must be phv register");
    return this;
}

int ByteRotateMerge::encode() {
    int bits = (0xa << 6) | src1.bits(slot/Phv::mau_groupsize());
    bits |= (byte_mask.getrange(0, 4)) << 10;
    bits |= (src1_shift << 17);
    bits |= (src2_shift << 15);
    bits <<= Target::INSTR_SRC2_BITS();
    return bits | src2.bits(slot/Phv::mau_groupsize());
}

bool ByteRotateMerge::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<ByteRotateMerge *>(a_)) {
        return dest == a->dest && src1 == a->src1 && src2 == a->src2 && byte_mask == a->byte_mask
               && src1_shift == a->src1_shift && src2_shift == a->src2_shift;
    } else {
        return false;
    }
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
    : VLIWInstruction(d.lineno), dest(tbl->gress, tbl->stage->stageno + 1, d),
      src1(tbl, act, s), src2(tbl->gress, tbl->stage->stageno, d) {}
    DepositField(Table *tbl, const Table::Actions::Action *act, const value_t &d,
                 const value_t &s1, const value_t &s2)
    : VLIWInstruction(d.lineno), dest(tbl->gress, tbl->stage->stageno + 1, d),
      src1(tbl, act, s1), src2(tbl, act, s2) {}
    DepositField(Table *tbl, const Set &);
    std::string name() { return "deposit_field"; }
    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    void pass2(Table *tbl, Table::Actions::Action *) {
        src1->pass2(slot/Phv::mau_groupsize());
        src2->pass2(slot/Phv::mau_groupsize()); }
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void(const ::Phv::Slice &sl)> fn) {
        src1.phvRead(fn); src2.phvRead(fn); }
    void dbprint(std::ostream &out) const {
        out << "INSTR: deposit_field " << dest << ", " << src1 << ", " << src2; }
};

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
    src1->pass1(tbl, slot/Phv::mau_groupsize());
    src2->pass1(tbl, slot/Phv::mau_groupsize());
    return this;
}
int DepositField::encode() {
    // If src1 is an operand::Const (and we pass a valid dest_size),
    // we will recieve the combined rotation + bits from DepositField::discoverRotation().
    // Otherwise the top 'RotationBits' will be zero.
    int rotConst = src1.bits(slot/Phv::mau_groupsize(), dest.size());
    unsigned rot = rotConst >> RotationBits;
    rot += dest->reg.size - dest->lo + src1.bitoffset(slot/Phv::mau_groupsize());
    rot %= dest->reg.size;
    int bits = rotConst & ((1U << RotationBits) - 1);
    bits |= (1 << 6);
    bits |= dest->hi << 7;
    bits |= rot << 12;
    switch (Phv::reg(slot)->size) {
    case 8:
        bits |= (dest->lo & 3) << 10;
        bits |= (dest->lo & ~3) << 13;
        break;
    case 16:
        bits |= (dest->lo & 1) << 11;
        bits |= (dest->lo & ~1) << 15;
        break;
    case 32:
        bits |= dest->lo << 17;
        break;
    default:
        BUG(); }
    bits <<= Target::INSTR_SRC2_BITS();
    return bits | src2.bits(slot/Phv::mau_groupsize());
}
bool DepositField::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<DepositField *>(a_)) {
        return dest == a->dest && src1 == a->src1 && src2 == a->src2;
    } else {
        return false;
    }
}

struct Set : VLIWInstruction {
    struct Decode : Instruction::Decode {
        std::string name;
        explicit Decode(const char *n) : Instruction::Decode(n), name(n) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    };
    Phv::Ref    dest;
    operand     src;
    static AluOP::Decode *opA;
    Set(Table *tbl, const Table::Actions::Action *act, const value_t &d, const value_t &s)
    : VLIWInstruction(d.lineno), dest(tbl->gress, tbl->stage->stageno + 1, d), src(tbl, act, s) {}
    std::string name() { return "set"; }
    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    void pass2(Table *tbl, Table::Actions::Action *) { src->pass2(slot/Phv::mau_groupsize()); }
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void(const ::Phv::Slice &sl)> fn) { src.phvRead(fn); }
    void dbprint(std::ostream &out) const {
        out << "INSTR: set " << dest << ", " << src; }
};

DepositField::DepositField(Table *tbl, const Set &s)
: VLIWInstruction(s), dest(s.dest), src1(s.src), src2(::Phv::Ref(s.dest->reg, tbl->gress)) {}

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
        return (new DepositField(tbl, *this))->pass1(tbl, act);
    if (auto *k = src.to<operand::Const>()) {
        if (dest->reg.type == Phv::Register::DARK) {
            error(dest.lineno, "can't set dark phv to a constant");
            return this; }
        int minconst = Target::MINIMUM_INSTR_CONSTANT();
        if (k->value < minconst || k->value >= 8)
            return (new LoadConst(lineno, dest, k->value))->pass1(tbl, act); }
    slot = dest->reg.mau_id();
    tbl->stage->action_set[tbl->gress][dest->reg.uid] = true;
    src->pass1(tbl, slot/Phv::mau_groupsize());
    return this;
}

int Set::encode() {
    int rv = src.bits(slot/Phv::mau_groupsize());
    switch (dest->reg.type) {
    case Phv::Register::NORMAL:
        rv |= (opA->opcode << 6);
        rv <<= Target::INSTR_SRC2_BITS();
        rv |= (slot & 0xf);
        break;
    case Phv::Register::MOCHA:
        rv |= 0x40;
        break;
    case Phv::Register::DARK:
        rv |= 0x20;
        break;
    default:
        BUG(); }
    return rv;
}

bool Set::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<Set *>(a_)) {
        return dest == a->dest && src == a->src;
    } else {
        return false;
    }
}

struct NulOP : VLIWInstruction {
    const struct Decode : Instruction::Decode {
        std::string name;
        unsigned opcode;
        Decode(const char *n, unsigned opc) : Instruction::Decode(n), name(n), opcode(opc) {}
        Decode(const char *n, target_t targ, unsigned opc)
            : Instruction::Decode(n, targ), name(n), opcode(opc) {}
        Decode(const char *n, std::set<target_t> targ, unsigned opc)
            : Instruction::Decode(n, targ), name(n), opcode(opc) {}
        Instruction *decode(Table *tbl, const Table::Actions::Action *act,
                            const VECTOR(value_t) &op) const override;
    } *opc;
    Phv::Ref    dest;
    NulOP(Table *tbl, const Table::Actions::Action *act, const Decode *o, const value_t &d)
    : VLIWInstruction(d.lineno), opc(o), dest(tbl->gress, tbl->stage->stageno + 1, d) {}
    std::string name() { return opc->name; }
    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    void pass2(Table *, Table::Actions::Action *) {}
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void(const ::Phv::Slice &sl)> fn) { }
    void dbprint(std::ostream &out) const {
        out << "INSTR: " << opc->name << " " << dest; }
};

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
    } else {
        return false;
    }
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
    int         shift = 0;
    ShiftOP(const Decode *d, Table *tbl, const Table::Actions::Action *act, const value_t *ops)
    : VLIWInstruction(ops->lineno), opc(d), dest(tbl->gress, tbl->stage->stageno + 1, ops[0]),
      src1(tbl, act, ops[1]), src2(tbl, act, ops[2]) {
        if (opc->use_src1) {
            if (CHECKTYPE(ops[3], tINT)) shift = ops[3].i;
        } else {
            src2 = src1;
            if (CHECKTYPE(ops[2], tINT)) shift = ops[2].i; } }
    std::string name() { return opc->name; }
    Instruction *pass1(Table *tbl, Table::Actions::Action *);
    void pass2(Table *tbl, Table::Actions::Action *) {
        src1->pass2(slot/Phv::mau_groupsize());
        src2->pass2(slot/Phv::mau_groupsize()); }
    int encode();
    bool equiv(Instruction *a_);
    void phvRead(std::function<void(const ::Phv::Slice &sl)> fn) {
        src1.phvRead(fn); src2.phvRead(fn); }
    void dbprint(std::ostream &out) const {
        out << "INSTR: " << opc->name << ' ' << dest << ", " << src1 << ", " << shift; }
};

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
    if (dest->lo) {
        error(lineno, "shift ops cannot operate on slices");
        return this; }
    slot = dest->reg.mau_id();
    tbl->stage->action_set[tbl->gress][dest->reg.uid] = true;
    src1->pass1(tbl, slot/Phv::mau_groupsize());
    src2->pass1(tbl, slot/Phv::mau_groupsize());
    if (src2.phvGroup() < 0)
        error(lineno, "src%s must be phv register", opc->use_src1 ? "2" : "");
    return this;
}
int ShiftOP::encode() {
    int rv = (shift << 12) | (opc->opcode << 6);
    if (opc->use_src1 || options.match_compiler) rv |= src1.bits(slot/Phv::mau_groupsize());
    rv <<= Target::INSTR_SRC2_BITS();
    return rv | src2.bits(slot/Phv::mau_groupsize());
}
bool ShiftOP::equiv(Instruction *a_) {
    if (auto *a = dynamic_cast<ShiftOP *>(a_)) {
        return opc == a->opc && dest == a->dest && src1 == a->src1 && src2 == a->src2 &&
               shift == a->shift;
    } else {
        return false;
    }
}

// lifted from MAU uArch 15.1.6
// If the operation is associative operand swap is enabled
//                                      OPNAME           OPCODE      OPERAND SWAP
//                                                                   (default = false)
static AluOP::Decode     opADD         ("add",           0x23e,      true), // NOLINT
                         opADDC        ("addc",          0x2be,      true), // NOLINT
                         opSUB         ("sub",           0x33e),            // NOLINT
                         opSUBC        ("subc",          0x3be),            // NOLINT
                         opSADDU       ("saddu",         0x03e,      true), // NOLINT
                         opSADDS       ("sadds",         0x07e,      true), // NOLINT
                         opSSUBU       ("ssubu",         0x0be),            // NOLINT
                         opSSUBS       ("ssubs",         0x0fe),            // NOLINT
                         opMINU        ("minu",          0x13e,      true), // NOLINT
                         opMINS        ("mins",          0x17e,      true), // NOLINT
                         opMAXU        ("maxu",          0x1be,      true), // NOLINT
                         opMAXS        ("maxs",          0x1fe,      true), // NOLINT
                         opSETZ        ("setz",          0x01e,      true), // NOLINT
                         opNOR         ("nor",           0x05e,      true), // NOLINT
                         opANDCA       ("andca",         0x09e),            // NOLINT
                         opNOTA        ("nota",          0x0de),            // NOLINT
                         opANDCB       ("andcb",         0x11e,      &opANDCA), // NOLINT
                         opNOTB        ("notb",          0x15e,      &opNOTA, "not"), // NOLINT
                         opXOR         ("xor",           0x19e,      true), // NOLINT
                         opNAND        ("nand",          0x1de,      true), // NOLINT
                         opAND         ("and",           0x21e,      true), // NOLINT
                         opXNOR        ("xnor",          0x25e,      true), // NOLINT
                         opB           ("alu_b",         0x29e),            // NOLINT
                         opORCA        ("orca",          0x2de),            // NOLINT
                         opA           ("alu_a",         0x31e,      &opB), // NOLINT
                         opORCB        ("orcb",          0x35e,      &opORCA), // NOLINT
                         opOR          ("or",            0x39e,      true), // NOLINT
                         opSETHI       ("sethi",         0x3de,      true); // NOLINT
static LoadConst::Decode opLoadConst   ("load-const");                      // NOLINT
static Set::Decode       opSet         ("set");                             // NOLINT
static NulOP::Decode     opNoop        ("noop",          0x0);              // NOLINT
static ShiftOP::Decode   opSHL         ("shl",           0x0c,       false), // NOLINT
                         opSHRS        ("shrs",          0x1c,       false), // NOLINT
                         opSHRU        ("shru",          0x14,       false), // NOLINT
                         opFUNSHIFT    ("funnel-shift",  0x04,       true); // NOLINT
static DepositField::Decode opDepositField;
static ByteRotateMerge::Decode opByteRotateMerge;

AluOP::Decode* Set::opA = &VLIW::opA;

static AluOP3Src::Decode    tf_opBMSET       ("bitmasked-set", TOFINO, 0x2e);  // NOLINT
static CondMoveMux::Decode  tf_opCondMove    ("cmov",  TOFINO, 0x16, true,  5, "conditional-move");  // NOLINT
static CondMoveMux::Decode  tf_opCondMux     ("cmux",  TOFINO, 0x6,  false, 2, "conditional-mux");   // NOLINT
static NulOP::Decode        tf_opInvalidate  ("invalidate", TOFINO, 0x3800);   // NOLINT

#if HAVE_JBAY || HAVE_CLOUDBREAK
static std::set<target_t>   jb_cb_targets = std::set<target_t>({JBAY, CLOUDBREAK});

static AluOP3Src::Decode    jb_cb_opBMSET    ("bitmasked-set", jb_cb_targets, 0x0e);   // NOLINT
static CondMoveMux::Decode  jb_cb_opCondMove ("cmov",    jb_cb_targets, 0x6, true,  5, "conditional-move");  // NOLINT
static AluOP::Decode        jb_cb_opGTEQU    ("gtequ",   jb_cb_targets, 0x02e),        // NOLINT
                            jb_cb_opGTEQS    ("gteqs",   jb_cb_targets, 0x06e),        // NOLINT
                            jb_cb_opLTU      ("ltu",     jb_cb_targets, 0x0ae),        // NOLINT
                            jb_cb_opLTS      ("lts",     jb_cb_targets, 0x0ee),        // NOLINT
                            jb_cb_opLEQU     ("lequ",    jb_cb_targets, 0x12e, &jb_cb_opGTEQU),  // NOLINT
                            jb_cb_opLEQS     ("leqs",    jb_cb_targets, 0x16e, &jb_cb_opGTEQS),  // NOLINT
                            jb_cb_opGTU      ("gtu",     jb_cb_targets, 0x1ae, &jb_cb_opLTU),  // NOLINT
                            jb_cb_opGTS      ("gts",     jb_cb_targets, 0x1ee, &jb_cb_opLTS),  // NOLINT
                            jb_cb_opEQ       ("eq",      jb_cb_targets, 0x22e, true),  // NOLINT
                            jb_cb_opNEQ      ("neq",     jb_cb_targets, 0x2ae, true),  // NOLINT
                            jb_cb_opEQ64     ("eq64",    jb_cb_targets, 0x26e, true),  // NOLINT
                            jb_cb_opNEQ64    ("neq64",   jb_cb_targets, 0x2ee, true);  // NOLINT
#endif  // HAVE_JBAY || HAVE_CLOUDBREAK

}  // end namespace VLIW

void dump(const Instruction &inst) { std::cout << inst << std::endl; }
