#ifndef _tables_h_
#define _tables_h_

#include <config.h>

#include <set>
#include <string>
#include <vector>
#include "algorithm.h"
#include "alloc.h"
#include "asm-types.h"
#include "bitvec.h"
#include "constants.h"
#include "hash_dist.h"
#include "json.h"
#include "map.h"
#include "ordered_map.h"
#include "phv.h"
#include "p4_table.h"
#include "slist.h"
#include "target.h"

class ActionBus;
struct AttachedTables;
class GatewayTable;
class IdletimeTable;
struct Instruction;
class InputXbar;
class MatchTable;
class SelectionTable;
class Stateful;
class Synth2Port;
class Stage;
struct Ref;

class Table {
public:
    struct Layout {
        /* Holds the layout of which rams/tcams/busses are used by the table
         * These refer to rows/columns in different spaces:
         * ternary match refers to tcams (12x2)
         * exact match and ternary indirect refer to physical srams (8x12)
         * action (and others?) refer to logical srams (16x6)
         * vpns contains the (base)vpn index of each ram in the row (matching cols)
         * maprams contain the map ram indexes for synthetic 2-port memories (matching cols) */
        int                     lineno = -1;
        int                     row = -1, bus = -1;
        std::vector<int>        cols, vpns, maprams;
        Layout() = default;
        Layout(int l, int r) : lineno(l), row(r) {}
    };
protected:
    Table(int line, std::string &&n, gress_t gr, Stage *s, int lid = -1);
    virtual ~Table();
    Table(const Table &) = delete;
    Table(Table &&) = delete;
    virtual void setup(VECTOR(pair_t) &data) = 0;
    virtual void common_init_setup(const VECTOR(pair_t) &, bool, P4Table::type);
    virtual bool common_setup(pair_t &, const VECTOR(pair_t) &, P4Table::type);
    void setup_layout(std::vector<Layout> &, const value_t *row, const value_t *col,
                      const value_t *bus, const char *subname = "");
    void setup_logical_id();
    void setup_actions(value_t &);
    void setup_maprams(VECTOR(value_t) *);
    void setup_vpns(std::vector<Layout> &, VECTOR(value_t) *, bool allow_holes = false);
    virtual void vpn_params(int &width, int &depth, int &period, const char *&period_name)
    { assert(0); }
    void alloc_rams(bool logical, Alloc2Dbase<Table *> &use, Alloc2Dbase<Table *> *bus_use = 0);
    void alloc_busses(Alloc2Dbase<Table *> &bus_use);
    void alloc_id(const char *idname, int &id, int &next_id, int max_id,
                  bool order, Alloc1Dbase<Table *> &use);
    void alloc_maprams();
    virtual void alloc_vpns();
    void need_bus(int lineno, Alloc1Dbase<Table *> &use, int idx, const char *name);
public:

    class Type {
        static std::map<std::string, Type *>           *all;
        std::map<std::string, Type *>::iterator        self;
    protected:
        Type(std::string &&);
        Type(const char *name) : Type(std::string(name)) {}
        virtual ~Type();
    public:
        static Type *get(const char *name) { return ::get(all, name); }
        static Type *get(const std::string &name) { return ::get(all, name); }
        virtual Table *create(int lineno, const char *name, gress_t gress,
                              Stage *stage, int lid, VECTOR(pair_t) &data) = 0;
    };

    struct Ref {
        int             lineno;
        std::string     name;
        Ref() : lineno(-1) {}
        Ref(const Ref &) = default;
        Ref(Ref &&) = default;
        Ref &operator=(const Ref &a) & {
            name = a.name;
            if (lineno < 0) lineno = a.lineno;
            return *this; }
        Ref &operator=(Ref &&a) & {
            name = a.name;
            if (lineno < 0) lineno = a.lineno;
            return *this; }
        Ref &operator=(const value_t &a) & {
            assert(a.type == tSTR);
            name = a.s;
            lineno = a.lineno;
            return *this; }
        Ref(const std::string &n) : lineno(-1), name(n) {}
        Ref(const value_t &a) : lineno(a.lineno), name(a.s) {
            assert(a.type == tSTR); }
        Ref &operator=(const std::string &n) { name = n; return *this; }
        operator bool() const { return all.count(name) > 0; }
        operator Table*() const { return ::get(all, name); }
        Table *operator->() const { return ::get(all, name); }
        bool set() const { return lineno >= 0; }
        bool operator==(const Table *t) { return name == t->name_; }
        bool operator==(const char *t) { return name == t; }
        bool operator==(const std::string &t) { return name == t; }
        bool check() {
            if (set() && !*this)
                error(lineno, "No table named %s", name.c_str());
            return *this; }
    };

    class Format {
    public:
        struct bitrange_t { unsigned lo, hi;
            bitrange_t(unsigned l, unsigned h) : lo(l), hi(h) {}
            bool operator==(const bitrange_t &a) const { return lo == a.lo && hi == a.hi; }
            bool disjoint(const bitrange_t &a) const { return lo > a.hi || a.lo > hi; }
            bitrange_t overlap(const bitrange_t &a) const {
                // only valid if !disjoint
                return bitrange_t(std::max(lo, a.lo), std::min(hi, a.hi)); }
            int size() const { return hi-lo+1; }

        };
        struct Field {
            unsigned    size = 0, group = 0, flags = 0;
            std::vector<bitrange_t>    bits;
            Field       **by_group = 0;
            bool operator==(const Field &a) const { return size == a.size; }
            unsigned bit(unsigned i) {
                unsigned last = 0;
                for (auto &chunk : bits) {
                    if (i < (unsigned)chunk.size())
                        return chunk.lo + i;
                    i -= chunk.size();
                    last = chunk.hi+1; }
                if (i == 0) return last;
                assert(0); }
            unsigned hi(unsigned bit) {
                for (auto &chunk : bits)
                    if (bit >= chunk.lo && bit <= chunk.hi)
                        return chunk.hi;
                assert(0); }
            enum flags_t { NONE=0, USED_IMMED=1, ZERO=3 };
            Field() {}
            Field(unsigned size, unsigned lo = 0, enum flags_t fl = NONE)
                : size(size), flags(fl) {
                if (size) bits.push_back({ lo, lo + size-1 }); }
        };
        Format() { fmt.resize(1); }
        Format(const VECTOR(pair_t) &data, bool may_overlap = false);
        ~Format();
        void pass1(Table *tbl);
        void pass2(Table *tbl);
    private:
        std::vector<std::map<std::string, Field>>                  fmt;
        std::map<unsigned, std::map<std::string, Field>::iterator> byindex;
    public:
        int                     lineno = -1;
        unsigned                size = 0, immed_size = 0;
        Field                   *immed = 0;
        unsigned                log2size = 0; /* ceil(log2(size)) */

        unsigned groups() const { return fmt.size(); }
        Field *field(const std::string &n, int group = 0) {
            assert(group >= 0 && (size_t)group < fmt.size());
            auto it = fmt[group].find(n);
            if (it != fmt[group].end()) return &it->second;
            return 0; }
        void apply_to_field(const std::string &n, std::function<void(Field *)> fn) {
            for (auto &m : fmt) {
                auto it = m.find(n);
                if (it != m.end()) fn(&it->second); } }
        std::string find_field(Field *field) {
            for (auto &m : fmt)
                for (auto &f : m)
                    if (field == &f.second)
                        return f.first;
            return "<unknown>"; }
        int find_field_lineno(Field *field) {
            for (auto &m : fmt)
                for (auto &f : m)
                    if (field == &f.second)
                        return lineno;
            return -1; }
        void add_field(Field &f, std::string name="dummy", int grp=0 ) { fmt[grp][name] = f; }
        decltype(fmt[0].begin()) begin(int grp=0) { return fmt[grp].begin(); }
        decltype(fmt[0].end()) end(int grp=0) { return fmt[grp].end(); }
        decltype(fmt[0].cbegin()) begin(int grp=0) const { return fmt[grp].begin(); }
        decltype(fmt[0].cend()) end(int grp=0) const { return fmt[grp].end(); }
    };

    struct Call : Ref { /* a Ref with arguments */
        struct Arg {
            enum { Field, HashDist }    type;
        private:
            union {
                Format::Field           *fld;
                HashDistribution        *hd;
            };
        public:
            Arg(Format::Field *f) : type(Field) { fld = f; }
            Arg(HashDistribution *hdist) : type(HashDist) { hd = hdist; }
            bool operator==(const Arg &a) const { return type == a.type && fld == a.fld; }
            bool operator!=(const Arg &a) const { return type != a.type || fld != a.fld; }
            Format::Field *field() { return type == Field ? fld : 0; }
            HashDistribution *hash_dist() { return type == HashDist ? hd : 0; }
            operator bool() { return fld != nullptr; }
            unsigned size() const;
        };
        std::vector<Arg>        args;
        void setup(const value_t &v, Table *tbl);
        Call() {}
        Call(const value_t &v, Table *tbl) { setup(v, tbl); }
    };

    struct p4_param {
        std::string name;
        unsigned position;
        unsigned bit_width;
        unsigned bit_width_full;
        unsigned default_value;
        bool defaulted;
        bool is_valid;
        std::string type;
        p4_param(std::string n = "", unsigned p = 0, unsigned bw = 0, unsigned bwf = 0, std::string t = "",unsigned v = 0, bool d = false, bool i = false) :
            name(n), position(p), bit_width(bw), bit_width_full(bwf), type(t) , default_value(v), defaulted(d), is_valid(i) {}
    };
    typedef std::vector<p4_param>  p4_params;

    class Actions {
    public:
        struct Action {
            struct alias_t {
                std::string     name;
                int             lineno = -1, lo = -1, hi = -1;
                bool            is_constant = false;
                unsigned        value;
                alias_t(value_t &); };
            std::string                         name;
            std::string                         rng_param_name = "";
            int                                 lineno = -1, addr = -1, code = -1;
            std::map<std::string, alias_t>      alias;
            std::vector<Instruction *>          instr;
            bitvec                              slot_use;
            unsigned                            handle;
            p4_params                           p4_params_list;
            Action(Table *, Actions *, pair_t &);
            Action(const char *n, int l) : name(n), lineno(l) {}
            bool equiv(Action *a);
            typedef const decltype(alias)::value_type alias_value_t;
            std::map<std::string, std::vector<alias_value_t *>> reverse_alias() const;
            bool has_rng() { return !rng_param_name.empty(); }
        };
    private:
        typedef ordered_map<std::string, Action> map_t;
        map_t           actions;
        bitvec          code_use;
        bitvec          slot_use;
        Table           *table;
    public:
        int                                     max_code = -1;
        Actions(Table *tbl, VECTOR(pair_t) &);
        typedef map_t::value_type                               value_type;
        typedef IterValues<map_t::iterator>::iterator           iterator;
        typedef IterValues<map_t::const_iterator>::iterator     const_iterator;
        iterator begin() { return iterator(actions.begin()); }
        const_iterator begin() const { return const_iterator(actions.begin()); }
        iterator end() { return iterator(actions.end()); }
        const_iterator end() const { return const_iterator(actions.end()); }
        int count() { return actions.size(); }
        Action *action(const std::string &n) {
            auto it = actions.find(n);
            return it == actions.end() ? nullptr : &it->second; }
        bool exists(const std::string &n) { return actions.count(n) > 0; }
        void pass1(Table *);
        void pass2(Table *);
        void stateful_pass2(Table *);
        template<class REGS> void write_regs(REGS &, Table *);
        void add_p4_params(const Action&, json::vector &);
        void gen_tbl_cfg(json::vector &);
        void add_immediate_mapping(json::map &);
        void add_next_table_mapping(Table *, json::map &);
        void add_action_format(Table *, json::map &);
        bool has_hash_dist() { return ( table->table_type() == HASH_ACTION ); }
    };
public:
    const char *name() const { return name_.c_str(); }
    const char *p4_name() const { if(p4_table) return p4_table->p4_name(); return ""; }
    unsigned handle() const { if(p4_table) return p4_table->get_handle(); return -1; }
    int table_id() const;
    virtual void pass1() = 0;
    virtual void pass2() = 0;
#define VIRTUAL_TARGET_METHODS(TARGET) \
    virtual void write_merge_regs(Target::TARGET::mau_regs &, int type, int bus) { assert(0); } \
    virtual void write_merge_regs(Target::TARGET::mau_regs &, MatchTable *match, int type,      \
                                  int bus, const std::vector<Call::Arg> &args) { assert(0); }   \
    virtual void write_regs(Target::TARGET::mau_regs &) = 0;
FOR_ALL_TARGETS(VIRTUAL_TARGET_METHODS)
#undef VIRTUAL_TARGET_METHODS
#define FORWARD_VIRTUAL_TABLE_WRITE_REGS(TARGET)                                           \
    void write_regs(Target::TARGET::mau_regs &regs) override {                             \
                write_regs<Target::TARGET::mau_regs>(regs); }
#define FORWARD_VIRTUAL_TABLE_WRITE_MERGE_REGS(TARGET)                                     \
    void write_merge_regs(Target::TARGET::mau_regs &regs, int type, int bus) override {    \
        write_merge_regs<Target::TARGET::mau_regs>(regs, type, bus); }
#define FORWARD_VIRTUAL_TABLE_WRITE_MERGE_REGS_WITH_ARGS(TARGET)                           \
    void write_merge_regs(Target::TARGET::mau_regs &regs, MatchTable *match, int type,     \
                          int bus, const std::vector<Call::Arg> &args) override {          \
        write_merge_regs<Target::TARGET::mau_regs>(regs, match, type, bus, args); }
#define MAKE_ABSTRACT_TABLE_WRITE_MERGE_REGS_WITH_ARGS(TARGET)                             \
    void write_merge_regs(Target::TARGET::mau_regs &regs, MatchTable *match, int type,     \
                          int bus, const std::vector<Call::Arg> &args) override = 0;

    virtual void gen_tbl_cfg(json::vector &out) = 0;
    virtual void gen_name_lookup(json::map &out) {}
    virtual json::map *base_tbl_cfg(json::vector &out, const char *type, int size);
    virtual json::map *add_stage_tbl_cfg(json::map &tbl, const char *type, int size);
    virtual std::unique_ptr<json::map> gen_memory_resource_allocation_tbl_cfg(
            const char *type, std::vector<Layout> &layout, bool skip_spare_bank = false);
    virtual void common_tbl_cfg(json::map &tbl, const char *match_type);
    enum table_type_t { OTHER=0, TERNARY_INDIRECT, GATEWAY, ACTION, SELECTION, COUNTER,
                        METER, IDLETIME, STATEFUL, HASH_ACTION, EXACT, TERNARY };
    virtual table_type_t table_type() { return OTHER; }
    virtual int instruction_set() { return 0; /* VLIW_ALU */ }
    virtual table_type_t set_match_table(MatchTable *m, bool indirect) { assert(0); }
    virtual MatchTable *get_match_table() { assert(0); }
    virtual std::set<MatchTable *> get_match_tables() { assert(0); }
    virtual const AttachedTables *get_attached() const { return 0; }
    virtual const GatewayTable *get_gateway() const { return 0; }
    virtual SelectionTable *get_selector() const { return 0; }
    virtual void set_stateful (Stateful *s) { assert(0); }
    virtual Stateful *get_stateful() const { return 0; }
    virtual const Call &get_action() const { return action; }
    virtual int direct_shiftcount() { assert(0); }
    virtual int indirect_shiftcount() { assert(0); }
    virtual int home_row() const { assert(0); }
    /* row,col -> mem unitno mapping -- unitnumbers used in context json */
    virtual int memunit(int r, int c) { return r*12 + c; }
    virtual int unitram_type() { assert(0); }
    virtual bool adr_mux_select_stats() { return false; }
    virtual bool run_at_eop() { return false; }
    template<class REGS> void write_mapram_regs(REGS &regs, int row, int col, int vpn, int type);
    template<class T> T *to() { return dynamic_cast<T *>(this); }

    std::string                 name_;
    P4Table                     *p4_table = 0;
    Stage                       *stage = 0;
    gress_t                     gress;
    int                         lineno = -1;
    int                         logical_id = -1;
    InputXbar                   *input_xbar = 0;
    std::vector<Layout>         layout;
    bool                        no_vpns = false; /* for odd actions with null vpns
                                                  * generated by compiler */
    Format                      *format = 0;
    int                         action_enable = -1;
    bool                        enable_action_data_enable = false;
    bool                        enable_action_instruction_enable = false;
    Call                        action;
    Actions                     *actions = 0;
    ActionBus                   *action_bus = 0;
    std::string                 default_action;
    unsigned                    default_action_handle = 0;
    int                         default_action_lineno = -1;
    std::map<std::string,unsigned>   default_action_parameters;
    bool                        default_only_action = false;
    std::vector<Ref>            hit_next;
    Ref                         miss_next;
    std::set<Table *>           pred;
    std::vector<HashDistribution>       hash_dist;
    p4_params                   p4_params_list;

    static std::map<std::string, Table *>       all;

    unsigned layout_size() {
        unsigned rv = 0;
        for (auto &row : layout) rv += row.cols.size();
        return rv; }
    unsigned layout_get_vpn(int r, int c) {
        for (auto &row : layout) {
            if (row.row != r) continue;
            auto col = find(row.cols, c);
            if (col == row.cols.end()) continue;
            return row.vpns.at(col - row.cols.begin()); }
        assert(0);
        return 0; }
    void layout_vpn_bounds(int &min, int &max, bool spare = false) {
        min = 1000000; max = -1;
        for (Layout &row : layout)
            for (auto v : row.vpns) {
                if (v < min) min = v;
                if (v > max) max = v; }
        if (spare && max > min) --max; }
    virtual Format::Field *lookup_field(const std::string &n,
                                        const std::string &act = "")
        { return format ? format->field(n) : 0; }
    virtual std::string find_field(Format::Field *field) {
        return format ? format->find_field(field) : "<unknown>"; }
    virtual int find_field_lineno(Format::Field *field) {
        return format ? format->find_field_lineno(field) : -1; }
    virtual void apply_to_field(const std::string &n, std::function<void(Format::Field *)> fn)
        { if (format) format->apply_to_field(n, fn); }
    int find_on_ixbar(Phv::Slice sl, int group);
    HashDistribution *find_hash_dist(int unit);
    virtual int find_on_actionbus(Format::Field *f, int off, int size);
    virtual void need_on_actionbus(Format::Field *f, int off, int size);
    virtual int find_on_actionbus(const char *n, int off, int size, int *len = 0);
    int find_on_actionbus(const std::string &n, int off, int size, int *len = 0) {
        return find_on_actionbus(n.c_str(), off, size, len); }
    virtual void need_on_actionbus(Table *attached, int off, int size);
    virtual int find_on_actionbus(HashDistribution *hd, int off, int size);
    virtual void need_on_actionbus(HashDistribution *hd, int off, int size);
    virtual Call &action_call() { return action; }
    virtual Actions *get_actions() { return actions; }
    void add_reference_table(json::vector &table_refs, const Table::Call& c, const std::string& href);
    json::map &add_pack_format(json::map &stage_tbl, int memword, int words, int entries = -1);
    json::map &add_pack_format(json::map &stage_tbl, Table::Format *format,
                               Table::Actions::Action *act = nullptr);
    virtual void add_field_to_pack_format(json::vector &field_list, int basebit, std::string name,
                                          const Table::Format::Field &field,
                                          const std::vector<Actions::Action::alias_value_t *> &);
    void add_zero_padding_fields(Table::Format *format, Table::Actions::Action *act = nullptr, unsigned format_width = 64);
    // Result physical buses should be setup for
    // Exact/Hash/MatchwithNoKey/ATCAM/Ternary tables
    void add_result_physical_buses(json::map &stage_tbl);
    void canon_field_list(json::vector &field_list);
    void check_next();
    void check_next(Ref &next);
    bool choose_logical_id(const slist<Table *> *work = nullptr);
    virtual int hit_next_size() const { return hit_next.size(); }
    p4_param *find_p4_param(value_t &v, p4_params &l) {
        for (auto &p : l)
            if (p.name == v.s) return &p;
        return nullptr;
    }
};

class FakeTable : public Table {
public:
    FakeTable(const char *name) : Table(-1, name, INGRESS, 0, -1) {}
    void setup(VECTOR(pair_t) &data) override { assert(0); }
    void pass1() override { assert(0); }
    void pass2() override { assert(0); }
    template<class REGS> void write_regs(REGS &) { assert(0); }
    FOR_ALL_TARGETS(FORWARD_VIRTUAL_TABLE_WRITE_REGS)
    void gen_tbl_cfg(json::vector &out) override { assert(0); }
};

struct AttachedTables {
    Table::Call                 selector;
    std::vector<Table::Call>    stats, meter;
    SelectionTable *get_selector() const;
    void pass1(MatchTable *self);
    template<class REGS> void write_merge_regs(REGS &regs, MatchTable *self, int type, int bus);
    bool run_at_eop();
};

#define DECLARE_ABSTRACT_TABLE_TYPE(TYPE, PARENT, ...)                  \
class TYPE : public PARENT {                                            \
protected:                                                              \
    TYPE(int l, const char *n, gress_t g, Stage *s, int lid)            \
        : PARENT(l, n, g, s, lid) {}                                    \
    __VA_ARGS__                                                         \
};

DECLARE_ABSTRACT_TABLE_TYPE(MatchTable, Table,
    GatewayTable                *gateway = 0;
    IdletimeTable               *idletime = 0;
    AttachedTables              attached;
    enum { NONE=0, TABLE_MISS=1, TABLE_HIT=2, DISABLED=3, GATEWAY_MISS=4, GATEWAY_HIT=5,
           GATEWAY_INHIBIT=6 }  table_counter = NONE;

    using Table::pass1;
    void pass1(int type);
    using Table::write_regs;
    template<class TARGET> void write_common_regs(typename TARGET::mau_regs &, int, Table *);
    template<class REGS> void write_regs(REGS &, int type, Table *result);
    template<class REGS> void setup_next_table_map(REGS &, Table *);
    void common_init_setup(const VECTOR(pair_t) &, bool, P4Table::type) override;
    bool common_setup(pair_t &, const VECTOR(pair_t) &, P4Table::type) override;
public:
    const AttachedTables *get_attached() const override { return &attached; }
    const GatewayTable *get_gateway() const override { return gateway; }
    MatchTable *get_match_table() override { return this; }
    std::set<MatchTable *> get_match_tables() override { return std::set<MatchTable *>{this}; }
    void gen_name_lookup(json::map &out) override;
    bool run_at_eop() override { return attached.run_at_eop(); }
    virtual bool is_ternary() { return false; }
    void gen_idletime_tbl_cfg(json::map &stage_tbl);
)

#define DECLARE_TABLE_TYPE(TYPE, PARENT, NAME, ...)                     \
class TYPE : public PARENT {                                            \
    static struct Type : public Table::Type {                           \
        Type() : Table::Type(NAME) {}                                   \
        TYPE *create(int lineno, const char *name, gress_t gress,       \
                      Stage *stage, int lid, VECTOR(pair_t) &data);     \
    } table_type_singleton;                                             \
    friend struct Type;                                                 \
    TYPE(int l, const char *n, gress_t g, Stage *s, int lid)            \
        : PARENT(l, n, g, s, lid) {}                                    \
    void setup(VECTOR(pair_t) &data) override;                          \
public:                                                                 \
    void pass1() override;                                              \
    void pass2() override;                                              \
    template<class REGS> void write_regs(REGS &regs);                   \
    FOR_ALL_TARGETS(FORWARD_VIRTUAL_TABLE_WRITE_REGS)                   \
    void gen_tbl_cfg(json::vector &out) override;                       \
private:                                                                \
    __VA_ARGS__                                                         \
};
#define DEFINE_TABLE_TYPE(TYPE)                                         \
TYPE::Type TYPE::table_type_singleton;                                  \
TYPE *TYPE::Type::create(int lineno, const char *name, gress_t gress,   \
                          Stage *stage, int lid, VECTOR(pair_t) &data) {\
    TYPE *rv = new TYPE(lineno, name, gress, stage, lid);               \
    rv->setup(data);                                                    \
    return rv;                                                          \
}

DECLARE_ABSTRACT_TABLE_TYPE(SRamMatchTable, MatchTable,         // exact or atcam match
protected:
    std::vector<Phv::Ref>                 match;
    std::map<unsigned, Phv::Ref>          match_by_bit;
    std::vector<std::vector<Phv::Ref>>    match_in_word;
    std::vector<int>                      word_ixbar_group;
    struct GroupInfo {
        /* info about which word(s) are used per format group with wide matches */
        int                     overhead_word;  /* which word of wide match contains overhead */
        int                     overhead_bit;   /* lowest bit that contains overhead in that word */
        int                     word_group;     /* which match group within the word to use */
        std::map<int, int>      match_group;    /* which match group for each word with match */
        std::vector<unsigned>   tofino_mask;    /* 14-bit tofino byte/nibble mask for each word */
        GroupInfo() : overhead_word(-1), overhead_bit(-1), word_group(-1) {}
    };
    std::vector<GroupInfo>      group_info;
    std::vector<std::vector<int>> word_info;    /* which format group corresponds to each
                                                 * match group in each word */
    int         mgm_lineno = -1;                /* match_group_map lineno */
public:
    Format::Field *lookup_field(const std::string &n, const std::string &act = "") override;
    void setup_word_ixbar_group();
    void verify_format();
    void vpn_params(int &width, int &depth, int &period, const char *&period_name) override {
        width = (format->size-1)/128 + 1;
        period = format->groups();
        depth = period * layout_size() / width;
        period_name = "match group size"; }
    template<class REGS> void write_merge_regs(REGS &regs, int type, int bus) {
        attached.write_merge_regs(regs, this, type, bus); }
    FOR_ALL_TARGETS(FORWARD_VIRTUAL_TABLE_WRITE_MERGE_REGS)
)

DECLARE_TABLE_TYPE(ExactMatchTable, SRamMatchTable, "exact_match",
    struct Way {
        int                              lineno;
        int                              group, subgroup, mask;
        std::vector<std::pair<int, int>> rams;
    };
    std::vector<Way>                      ways;
    struct WayRam { int way, index, word, bank; };
    std::map<std::pair<int, int>, WayRam> way_map;
    std::map<unsigned, unsigned> hash_fn_ids;
    bool isindirect() {
        if (action)
            if (action.args.size() > 1) return true;
        return false; }
    void setup_ways();
    void alloc_vpns() override;
public:
    SelectionTable *get_selector() const override { return attached.get_selector(); }
    using Table::gen_memory_resource_allocation_tbl_cfg;
    std::unique_ptr<json::map> gen_memory_resource_allocation_tbl_cfg(Way &);
    void add_field_to_pack_format(json::vector &field_list, int basebit, std::string name,
                                  const Table::Format::Field &field,
                                  const std::vector<Actions::Action::alias_value_t *> &) override;
    int unitram_type() override { return UnitRam::MATCH; }
    table_type_t table_type() override { return EXACT; }
)

DECLARE_TABLE_TYPE(AlgTcamMatchTable, SRamMatchTable, "atcam_match",
    bitvec      s0q1_nibbles, s1q0_nibbles;
    void alloc_vpns() override;
    void find_tcam_match();
)

DECLARE_TABLE_TYPE(TernaryMatchTable, MatchTable, "ternary_match",
    void vpn_params(int &width, int &depth, int &period, const char *&period_name) override;
    struct Match {
        int word_group=-1, byte_group=-1, byte_config=0, dirtcam=0;
        Match() {}
        Match(const value_t &);
    };
    std::vector<Match>  match;
    int match_word(int word_group) {
        for (unsigned i = 0; i < match.size(); i++)
            if (match[i].word_group == word_group)
                return i;
        return -1; }
    unsigned            chain_rows; /* bitvector */
    enum { ALWAYS_ENABLE_ROW = (1<<2) | (1<<5) | (1<<9) };
    friend class TernaryIndirectTable;
public:
    int tcam_id;
    Table::Ref indirect;
    int indirect_bus;   /* indirect bus to use if there's no indirect table */
    void alloc_vpns() override;
    Format::Field *lookup_field(const std::string &name, const std::string &action) override {
        assert(!format);
        return indirect ? indirect->lookup_field(name, action) : 0; }
    int find_on_actionbus(Format::Field *f, int off, int size) override {
        return indirect ? indirect->find_on_actionbus(f, off, size)
                        : Table::find_on_actionbus(f, off, size); }
    void need_on_actionbus(Format::Field *f, int off, int size) override {
        indirect ? indirect->need_on_actionbus(f, off, size)
                 : Table::need_on_actionbus(f, off, size); }
    int find_on_actionbus(const char *n, int off, int size, int *len = 0) override {
        return indirect ? indirect->find_on_actionbus(n, off, size, len)
                        : Table::find_on_actionbus(n, off, size, len); }
    const Call &get_action() const override { return indirect ? indirect->get_action() : action; }
    Actions *get_actions() override { return actions ? actions : indirect ? indirect->actions : 0; }
    const AttachedTables *get_attached() const override {
        return indirect ? indirect->get_attached() : &attached; }
    SelectionTable *get_selector() const override {
        return indirect ? indirect->get_selector() : 0; }
    std::unique_ptr<json::map> gen_memory_resource_allocation_tbl_cfg(
            const char *type, std::vector<Layout> &layout, bool skip_spare_bank=false) override;
    Call &action_call() override { return indirect ? indirect->action : action; }
    int memunit(int r, int c) override { return r + c*12; }
    bool is_ternary() override { return true; }
    int hit_next_size() const override {
        if (indirect && indirect->hit_next.size() > 0)
            return indirect->hit_next.size();
        return hit_next.size(); }
    table_type_t table_type() override { return TERNARY; }
    void gen_entry_cfg(json::vector &out, std::string name, \
        unsigned lsb_offset, unsigned lsb_idx, unsigned msb_idx, \
        std::string source, unsigned start_bit, unsigned field_width);
)

DECLARE_TABLE_TYPE(Phase0MatchTable, Table, "phase0_match",
    int         size = 72;
    int         width = 1;
)
DECLARE_TABLE_TYPE(HashActionTable, MatchTable, "hash_action",
public:
    //int                                 row = -1, bus = -1;
    table_type_t table_type() override { return HASH_ACTION; }
    template<class REGS> void write_merge_regs(REGS &regs, int type, int bus);
    FOR_ALL_TARGETS(FORWARD_VIRTUAL_TABLE_WRITE_MERGE_REGS)
)

DECLARE_TABLE_TYPE(TernaryIndirectTable, Table, "ternary_indirect",
    TernaryMatchTable           *match_table;
    AttachedTables              attached;
    table_type_t table_type() override { return TERNARY_INDIRECT; }
    table_type_t set_match_table(MatchTable *m, bool indirect) override;
    void vpn_params(int &width, int &depth, int &period, const char *&period_name) override {
        width = (format->size-1)/128 + 1;
        depth = layout_size() / width;
        period = 1;
        period_name = 0; }
    Actions *get_actions() override { return actions ? actions : match_table->actions; }
    const AttachedTables *get_attached() const override { return &attached; }
    const GatewayTable *get_gateway() const override { return match_table->get_gateway(); }
    MatchTable *get_match_table() override { return match_table; }
    std::set<MatchTable *> get_match_tables() override {
        std::set<MatchTable *> rv;
        if (match_table) rv.insert(match_table);
        return rv; }
    SelectionTable *get_selector() const override { return attached.get_selector(); }
    template<class REGS> void write_merge_regs(REGS &regs, int type, int bus) {
        attached.write_merge_regs(regs, match_table, type, bus); }
    FOR_ALL_TARGETS(FORWARD_VIRTUAL_TABLE_WRITE_MERGE_REGS)
    void add_field_to_pack_format(json::vector &field_list, int basebit, std::string name,
                                  const Table::Format::Field &field,
                                  const std::vector<Actions::Action::alias_value_t *> &) override;
    int unitram_type() override { return UnitRam::TERNARY_INDIRECTION; }
public:
    unsigned address_shift() const { return std::min(5U, format->log2size - 2); }
)

DECLARE_ABSTRACT_TABLE_TYPE(AttachedTable, Table,
    /* table that can be attached to multiple match tables to do something */
    std::set<MatchTable *>      match_tables;
    bool                        direct = false, indirect = false;
    bool                        per_flow_enable = false;
    std::string                 per_flow_enable_param = "";
    unsigned                    per_flow_enable_bit = 0;
    unsigned                    address_bits;
    table_type_t set_match_table(MatchTable *m, bool indirect) {
        if ((indirect && direct) || (!indirect && this->indirect))
            error(lineno, "Table %s is accessed with direct and indirect indices", name());
        this->indirect = indirect;
        direct = !indirect;
        match_tables.insert(m);
        if ((unsigned)m->logical_id < (unsigned)logical_id) logical_id = m->logical_id;
        return table_type(); }
    const GatewayTable *get_gateway() const {
        return match_tables.size() == 1 ? (*match_tables.begin())->get_gateway() : 0; }
    MatchTable *get_match_table() {
        return match_tables.size() == 1 ? *match_tables.begin() : 0; }
    std::set<MatchTable *> get_match_tables() { return match_tables; }
    SelectionTable *get_selector() const {
        return match_tables.size() == 1 ? (*match_tables.begin())->get_selector() : 0; }
    Call &action_call() {
        return match_tables.size() == 1 ? (*match_tables.begin())->action_call() : action; }
    int memunit(int r, int c) { return r*6 + c; }
    void pass1();
    unsigned get_meter_alu_index() {
        if(layout.size() > 0) return layout[0].row/4U;
        error(lineno, "Cannot determine Meter ALU Index for table %s", name());
        return 0; }
protected:
    // Accessed by Meter/Selection/Stateful Tables
    void add_meter_alu_index(json::map &stage_tbl);
public:
    std::string get_per_flow_enable_param() { return per_flow_enable_param; }
    bool get_per_flow_enable() { return per_flow_enable; }
)

DECLARE_TABLE_TYPE(ActionTable, AttachedTable, "action",
    int                                 action_id;
    std::vector<int>                    home_rows;
    int                                 home_lineno = -1;
    std::map<std::string, Format *>     action_formats;
    static const std::map<unsigned, std::vector<std::string>> action_data_address_huffman_encoding;
    void vpn_params(int &width, int &depth, int &period, const char *&period_name) override;
    std::string find_field(Format::Field *field) override;
    int find_field_lineno(Format::Field *field) override;
    Format::Field *lookup_field(const std::string &name, const std::string &action) override;
    void apply_to_field(const std::string &n, std::function<void(Format::Field *)> fn) override;
    int find_on_actionbus(Format::Field *f, int off, int size) override;
    int find_on_actionbus(const char *n, int off, int size, int *len) override;
    table_type_t table_type() override { return ACTION; }
    int unitram_type() override { return UnitRam::ACTION; }
    void pad_format_fields();
    unsigned get_do_care_count(std::string bstring);
    unsigned get_lower_huffman_encoding_bits (unsigned width);
public:
    std::map<std::string, Format *>& get_action_formats() { return action_formats; }
    unsigned get_size() {
        unsigned size = 0;
        if (format) size = format->size;
        for (auto f: get_action_formats()) {
            unsigned fsize = f.second->size;
            if (fsize > size) size = fsize; }
        return size; }
    unsigned get_log2size() {
        unsigned size = get_size();
        return ceil_log2(size); }
)

DECLARE_TABLE_TYPE(GatewayTable, Table, "gateway",
    MatchTable                  *match_table = 0;
    uint64_t                    payload;
    int                         have_payload = 0;
    int                         match_address = -1;
    int                         gw_unit = -1;
    enum range_match_t { NONE, DC_2BIT, DC_4BIT }
                                range_match = NONE;
public:
    struct MatchKey {
        int                     offset;
        Phv::Ref                val;
        MatchKey(gress_t gr, value_t &v) : offset(-1), val(gr, v) {}
        MatchKey(int off, gress_t gr, value_t &v) : offset(off), val(gr, v) {}
        bool operator<(const MatchKey &a) const { return offset < a.offset; }
    };
private:
    std::vector<MatchKey>       match, xor_match;
    struct Match {
        int                     lineno = 0;
        uint16_t                range[6] = { 0, 0, 0, 0, 0, 0 };
        match_t                 val = { 0, 0 };
        bool                    run_table = false;
        Ref                     next;
        Match() {}
        Match(value_t *v, value_t &data, range_match_t range_match);
    }                           miss;
    std::vector<Match>          table;
    template<class REGS> void payload_write_regs(REGS &, int row, int type, int bus);
public:
    table_type_t table_type() override { return GATEWAY; }
    MatchTable *get_match_table() override { return match_table; }
    std::set<MatchTable *> get_match_tables() override {
        std::set<MatchTable *> rv;
        if (match_table) rv.insert(match_table);
        return rv; }
    table_type_t set_match_table(MatchTable *m, bool indirect) override {
        match_table = m;
        if ((unsigned)m->logical_id < (unsigned)logical_id) logical_id = m->logical_id;
        return GATEWAY; }
    static GatewayTable *create(int lineno, const std::string &name, gress_t gress,
                                Stage *stage, int lid, VECTOR(pair_t) &data)
        { return table_type_singleton.create(lineno, name.c_str(), gress, stage, lid, data); }
    const GatewayTable *get_gateway() const override { return this; }
    SelectionTable *get_selector() const override {
        return match_table ? match_table->get_selector() : 0; }
    bool empty_match() const { return match.empty() && xor_match.empty(); }
    unsigned input_use() const;
)

DECLARE_TABLE_TYPE(SelectionTable, AttachedTable, "selection",
    bool                non_linear_hash = false, /* == enable_sps_scrambling */
                        resilient_hash = false; /* false is fair hash */
    int                 mode_lineno = -1, param = -1;
    std::vector<int>    pool_sizes;
    int                 min_words = -1, max_words = -1;
    int                 selection_hash = -1;
public:
    Stateful*           bound_stateful = nullptr;
    table_type_t table_type() override { return SELECTION; }
    void vpn_params(int &width, int &depth, int &period, const char *&period_name) override {
        width = period = 1; depth = layout_size(); period_name = 0; }

    template<class REGS> void write_merge_regs(REGS &regs, MatchTable *match, int type, int bus,
                          const std::vector<Call::Arg> &args);
    template<class REGS> void setup_logical_alu_map(REGS &regs, int logical_id, int alu);
    template<class REGS> void setup_physical_alu_map(REGS &regs, int type, int bus, int alu);
    FOR_ALL_TARGETS(FORWARD_VIRTUAL_TABLE_WRITE_MERGE_REGS_WITH_ARGS)
    unsigned address_shift() const { return 7 + ceil_log2(min_words); }
    unsigned meter_group() const { return layout.at(0).row/4U; }
    int home_row() const override { return layout.at(0).row | 3; }
    int unitram_type() override { return UnitRam::SELECTOR; }
    Stateful *get_stateful() const override { return bound_stateful; }
    void set_stateful(Stateful *s) override { bound_stateful = s; }
)

class IdletimeTable : public Table {
    MatchTable          *match_table = 0;
    int                 sweep_interval = 7, precision = 3;
    bool                disable_notification = false;
    bool                two_way_notification = false;
    bool                per_flow_enable = false;

    IdletimeTable(int lineno, const char *name, gress_t gress, Stage *stage, int lid)
        : Table(lineno, name, gress, stage, lid) {}
    void setup(VECTOR(pair_t) &data) override;
public:
    table_type_t table_type() override { return IDLETIME; }
    table_type_t set_match_table(MatchTable *m, bool indirect) override {
        match_table = m;
        if ((unsigned)m->logical_id < (unsigned)logical_id) logical_id = m->logical_id;
        return IDLETIME; }
    void vpn_params(int &width, int &depth, int &period, const char *&period_name) override {
        width = period = 1; depth = layout_size(); period_name = 0; }
    int memunit(int r, int c) override { return r*6 + c; }
    int precision_shift();
    void pass1() override;
    void pass2() override;
    template<class REGS> void write_merge_regs(REGS &regs, int type, int bus);
    template<class REGS> void write_regs(REGS &regs);
    FOR_ALL_TARGETS(FORWARD_VIRTUAL_TABLE_WRITE_REGS)
    FOR_ALL_TARGETS(FORWARD_VIRTUAL_TABLE_WRITE_MERGE_REGS)
    void gen_tbl_cfg(json::vector &out) override { /* nothing at top level */ }
    void gen_stage_tbl_cfg(json::map &out);
    static IdletimeTable *create(int lineno, const std::string &name, gress_t gress,
                                 Stage *stage, int lid, VECTOR(pair_t) &data) {
        IdletimeTable *rv = new IdletimeTable(lineno, name.c_str(), gress, stage, lid);
        rv->setup(data);
        return rv; }
};

DECLARE_ABSTRACT_TABLE_TYPE(Synth2Port, AttachedTable,
    void vpn_params(int &width, int &depth, int &period, const char *&period_name) override {
        width = period = 1; depth = layout_size(); period_name = 0; }
    bool                global_binding = false;
    json::map *base_tbl_cfg(json::vector &out, const char *type, int size) override;
    json::map *add_stage_tbl_cfg(json::map &tbl, const char *type, int size) override;
public:
    template<class REGS> void write_regs(REGS &regs);
    FOR_ALL_TARGETS(FORWARD_VIRTUAL_TABLE_WRITE_REGS)
    FOR_ALL_TARGETS(MAKE_ABSTRACT_TABLE_WRITE_MERGE_REGS_WITH_ARGS)
    void common_init_setup(const VECTOR(pair_t) &, bool, P4Table::type) override;
    bool common_setup(pair_t &, const VECTOR(pair_t) &, P4Table::type) override;
    void pass1() override;
    void pass2() override;
)

DECLARE_TABLE_TYPE(CounterTable, Synth2Port, "counter",
    enum { NONE=0, PACKETS=1, BYTES=2, BOTH=3 } type = NONE;
    table_type_t table_type() override { return COUNTER; }
    template<class REGS> void write_merge_regs(REGS &regs, MatchTable *match, int type, int bus,
                                               const std::vector<Call::Arg> &args);
    FOR_ALL_TARGETS(FORWARD_VIRTUAL_TABLE_WRITE_MERGE_REGS_WITH_ARGS)
public:
    int direct_shiftcount() override;
    int indirect_shiftcount() override;
    bool run_at_eop() override { return (type&BYTES) != 0; }
    bool adr_mux_select_stats() override { return true; }
    int unitram_type() override { return UnitRam::STATISTICS; }
)

DECLARE_TABLE_TYPE(MeterTable, Synth2Port, "meter",
    enum { NONE=0, STANDARD=1, LPF=2, RED=3 }   type = NONE;
    enum { NONE_=0, PACKETS=1, BYTES=2 }        count = NONE_;
    std::vector<Layout>                         color_maprams;
    table_type_t table_type() override { return METER; }
    template<class REGS> void write_merge_regs(REGS &regs, MatchTable *match, int type, int bus,
                                               const std::vector<Call::Arg> &args);
    template<class REGS> void meter_color_logical_to_phys(REGS &regs, int logical_id, int alu);
    FOR_ALL_TARGETS(FORWARD_VIRTUAL_TABLE_WRITE_MERGE_REGS_WITH_ARGS)
    int                 sweep_interval = 2;
public:
    int direct_shiftcount() override;
    bool                color_aware = false;
    bool                color_aware_per_flow_enable = false;
    bool run_at_eop() override { return type == STANDARD; }
    int unitram_type() override { return UnitRam::METER; }
    int home_row() const override { return layout.at(0).row | 3; }
    void add_cfg_reg(json::vector &cfg_cache, std::string full_name, std::string name, unsigned val, unsigned width);
)

DECLARE_TABLE_TYPE(Stateful, Synth2Port, "stateful",
    table_type_t table_type() override { return STATEFUL; }
    template<class REGS> void write_merge_regs(REGS &regs, MatchTable *match, int type, int bus,
                                               const std::vector<Call::Arg> &args);
    FOR_ALL_TARGETS(FORWARD_VIRTUAL_TABLE_WRITE_MERGE_REGS_WITH_ARGS)
    Ref                 bound_selector;
    std::vector<long>   const_vals;
    struct MathTable {
        int                     lineno = -1;
        std::vector<int>        data;
        bool                    invert = false;
        int                     shift = 0, scale = 0;
        explicit operator bool() { return lineno >= 0; }
        void check();
    }                   math_table;
    bool dual_mode = false;
public:
    unsigned phv_byte_mask = 0;
    int instruction_set() override { return 1; /* STATEFUL_ALU */ }
    int direct_shiftcount() override;
    int unitram_type() override { return UnitRam::STATEFUL; }
    int get_const(long v);
    bool is_dual_mode() { return dual_mode; }
    int home_row() const override { return layout.at(0).row | 3; }
    int indirect_shiftcount() override;
    unsigned get_instruction_count() {
        unsigned instr_count = 0;
        if (actions) {
            for (auto &a : *actions) { //will have only 1 action
                for (auto &i : a.instr) ++instr_count; } }
        return instr_count; }
)

#endif /* _tables_h_ */
