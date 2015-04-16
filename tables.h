#ifndef _tables_h_
#define _tables_h_

#include "algorithm.h"
#include "alloc.h"
#include "asm-types.h"
#include "bitvec.h"
#include "json.h"
#include "map.h"
#include <set>
#include <string>
#include "phv.h"
#include <vector>

class ActionBus;
class GatewayTable;
class Instruction;
class InputXbar;
class MatchTable;
class SelectionTable;
class Stage;

class Table {
protected:
    Table(int line, std::string &&n, gress_t gr, Stage *s, int lid = -1);
    virtual ~Table();
    Table(const Table &) = delete;
    Table(Table &&) = delete;
    virtual void setup(VECTOR(pair_t) &data) = 0;
    void setup_layout(value_t *row, value_t *col, value_t *bus);
    void setup_logical_id();
    void setup_actions(value_t &);
    void setup_vpns(VECTOR(value_t) *);
    virtual void vpn_params(int &width, int &depth, int &period, const char *&period_name) { assert(0); }
    void alloc_rams(bool logical, Alloc2Dbase<Table *> &use, Alloc2Dbase<Table *> *bus_use = 0);
    void alloc_busses(Alloc2Dbase<Table *> &bus_use);
    void alloc_id(const char *idname, int &id, int &next_id, int max_id,
		  bool order, Alloc1Dbase<Table *> &use);
    void alloc_vpns();
    void check_next();
public:
    const char *name() { return name_.c_str(); }
    int table_id();
    virtual void pass1() = 0;
    virtual void pass2() = 0;
    virtual void write_regs() = 0;
    virtual void gen_tbl_cfg(json::vector &out) = 0;
    virtual std::unique_ptr<json::map> gen_memory_resource_allocation_tbl_cfg();
    enum table_type_t { OTHER=0, TERNARY_INDIRECT, GATEWAY, ACTION, SELECTION };
    virtual table_type_t set_match_table(MatchTable *m) { return OTHER; }
    virtual GatewayTable *get_gateway() { return 0; }
    virtual SelectionTable *get_selector() { return 0; }

    struct Layout {
        /* Holds the layout of which rams/tcams/busses are used by the table
         * These refer to rows/columns in different spaces:
         * ternary match refers to tcams (16x2)
         * exact match and ternary indirect refer to physical srams (8x12)
         * action (and others?) refer to logical srams (16x6)
         * vpns contains the (base)vpn index of each ram in the row (matching cols) */
        int                     lineno;
        int                     row, bus;
        std::vector<int>        cols, vpns;
    };

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
        struct bitrange_t { unsigned lo, hi;
            bitrange_t(unsigned l, unsigned h) : lo(l), hi(h) {}
            bool operator==(const bitrange_t &a) const { return lo == a.lo && hi == a.hi; }
            int size() { return hi-lo+1; }
        };
    public:
        struct Field {
            unsigned    size, group, flags;
            std::vector<bitrange_t>    bits;
            Field       **by_group;
            Field() : size(0), group(0), flags(0),
                /*action_xbar(-1), action_xbar_bit(0),*/ by_group(0) {}
            bool operator==(const Field &a) const { return size == a.size; }
            unsigned hi(unsigned bit) {
                for (auto &chunk : bits)
                    if (bit >= chunk.lo && bit <= chunk.hi)
                        return chunk.hi;
                assert(0); }
            enum flags_t { USED_IMMED=1 };
        };
        Format(VECTOR(pair_t) &data, bool may_overlap = false);
        ~Format();
        void setup_immed(Table *tbl);
    private:
        std::vector<std::map<std::string, Field>>                  fmt;
        std::map<unsigned, std::map<std::string, Field>::iterator> byindex;
    public:
        int                     lineno;
        unsigned                size, immed_size;
        Field                   *immed;
        unsigned                log2size; /* ceil(log2(size)) */

        unsigned groups() const { return fmt.size(); }
        Field *field(const std::string &n, int group = 0) {
            assert(group >= 0 && (size_t)group < fmt.size());
            auto it = fmt[group].find(n);
            if (it != fmt[group].end()) return &it->second;
            return 0; }
        void apply_to_field(const std::string &n,
                            std::function<void(Format::Field *)> fn) {
            for (auto &m : fmt) {
                auto it = m.find(n);
                if (it != m.end()) fn(&it->second); } }
        decltype(fmt[0].begin()) begin(int grp=0) { return fmt[grp].begin(); }
        decltype(fmt[0].end()) end(int grp=0) { return fmt[grp].end(); }
    };

    struct Call : Ref { /* a Ref with arguments */
        std::vector<Format::Field*>     args;
        void setup(const value_t &v, Table *tbl);
    };

    class Actions {
        struct Action {
            std::string                 name;
            int                         lineno, addr, code;
            std::vector<Instruction *>  instr;
            Action(const char *n, int l) : name(n), lineno(l), addr(-1), code(-1) {}
        };
        std::vector<Action>             actions;
        std::map<std::string, int>      by_name;
    public:
        Actions(Table *tbl, VECTOR(pair_t) &);
        std::vector<Action>::iterator begin() { return actions.begin(); }
        std::vector<Action>::iterator end() { return actions.end(); }
        int count() { return actions.size(); }
        bool exists(const std::string &n) { return by_name.count(n) > 0; }
        void pass1(Table *);
        void pass2(Table *);
        void write_regs(Table *);
    };
public:
    std::string                 name_, p4_table;
    int                         handle;
    Stage                       *stage;
    gress_t                     gress;
    int                         lineno;
    int                         logical_id;
    InputXbar			*input_xbar;
    std::vector<Layout>         layout;
    Format                      *format;
    Call                        action;
    Actions                     *actions;
    ActionBus			*action_bus;
    std::vector<Ref>            hit_next;
    Ref                         miss_next;

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
    virtual Format::Field *lookup_field(const std::string &n,
                                        const std::string &act = "")
        { return format ? format->field(n) : 0; }
    virtual void apply_to_field(const std::string &n, std::function<void(Format::Field *)> fn)
        { if (format) format->apply_to_field(n, fn); }
    int find_on_ixbar(Phv::Slice sl, int group);
    virtual int find_on_actionbus(Format::Field *f, int off);
};

class MatchTable : public Table {
protected:
    GatewayTable                *gateway;
    MatchTable(int l, std::string &&n, gress_t g, Stage *s, int lid)
        : Table(l, std::move(n), g, s, lid), gateway(0) {}
    void write_regs(int type, Table *result);
public:
   GatewayTable *get_gateway() { return gateway; }
};

#define DECLARE_TABLE_TYPE(TYPE, PARENT, NAME, ...)                     \
class TYPE : public PARENT {                                            \
    static struct Type : public Table::Type {                           \
        Type() : Table::Type(NAME) {}                                   \
        TYPE *create(int lineno, const char *name, gress_t gress,       \
                      Stage *stage, int lid, VECTOR(pair_t) &data);     \
    } table_type;                                                       \
    friend struct Type;                                                 \
    TYPE(int l, const char *n, gress_t g, Stage *s, int lid)            \
        : PARENT(l, n, g, s, lid) {}                                    \
    void setup(VECTOR(pair_t) &data);                                   \
public:                                                                 \
    void pass1();                                                       \
    void pass2();                                                       \
    void write_regs();                                                  \
    void gen_tbl_cfg(json::vector &out);                                \
private:                                                                \
    __VA_ARGS__                                                         \
};
#define DEFINE_TABLE_TYPE(TYPE)                                         \
TYPE::Type TYPE::table_type;                                            \
TYPE *TYPE::Type::create(int lineno, const char *name, gress_t gress,   \
                          Stage *stage, int lid, VECTOR(pair_t) &data) {\
    TYPE *rv = new TYPE(lineno, name, gress, stage, lid);               \
    rv->setup(data);                                                    \
    return rv;                                                          \
}

DECLARE_TABLE_TYPE(ExactMatchTable, MatchTable, "exact_match",
    Table::Call                 selector;
    void vpn_params(int &width, int &depth, int &period, const char *&period_name) {
        width = (format->size-1)/128 + 1;
        period = format->groups();
        depth = period * layout_size() / width;
        period_name = "match group size"; }
    struct Way {
        int                              lineno;
        int                              group, subgroup, mask;
        std::vector<std::pair<int, int>> rams;
    };
    std::vector<Way>                      ways;
    struct WayRam { int way, index, word, bank; };
    std::map<std::pair<int, int>, WayRam> way_map;
    void setup_ways();
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
    int         mgm_lineno;     /* match_group_map lineno */
public:
    SelectionTable *get_selector();
    std::unique_ptr<json::map> gen_memory_resource_allocation_tbl_cfg(Way &);
)

DECLARE_TABLE_TYPE(TernaryMatchTable, MatchTable, "ternary_match",
    void vpn_params(int &width, int &depth, int &period, const char *&period_name);
    struct Match {
        int word_group, byte_group, byte_config;
        Match() {}
        Match(const value_t &);
    };
    std::vector<Match>  match;
    unsigned            chain_rows; /* bitvector */
    enum { ALWAYS_ENABLE_ROW = (1<<2) | (1<<5) | (1<<9) };
public:
    int tcam_id;
    Table::Ref indirect;
    int indirect_bus;   /* indirect bus to use if there's no indirect table */
    Format::Field *lookup_field(const std::string &name, const std::string &action) {
        assert(!format);
        return indirect ? indirect->lookup_field(name, action) : 0; }
    int find_on_actionbus(Format::Field *f, int off) {
        return indirect ? indirect->find_on_actionbus(f, off) : -1; }
    SelectionTable *get_selector() { return indirect ? indirect->get_selector() : 0; }
    std::unique_ptr<json::map> gen_memory_resource_allocation_tbl_cfg();
)

DECLARE_TABLE_TYPE(TernaryIndirectTable, Table, "ternary_indirect",
    TernaryMatchTable           *match_table;
    Table::Call                 selector;
    table_type_t set_match_table(MatchTable *m);
    void vpn_params(int &width, int &depth, int &period, const char *&period_name) {
        width = (format->size-1)/128 + 1;
        depth = layout_size() / width;
        period = 1;
        period_name = 0; }
    GatewayTable *get_gateway() { return match_table->get_gateway(); }
    SelectionTable *get_selector();
)

DECLARE_TABLE_TYPE(ActionTable, Table, "action",
    std::set<MatchTable *>      match_tables;
    int action_id;
    void vpn_params(int &width, int &depth, int &period, const char *&period_name) {
        width = 1; depth = layout_size();
        period = 1 << std::max((int)format->log2size - 7, 0);
        period_name = "action data width"; }
    std::map<std::string, Format *>     action_formats;
    Format::Field *lookup_field(const std::string &name, const std::string &action);
    void apply_to_field(const std::string &n, std::function<void(Format::Field *)> fn);
    int find_on_actionbus(Format::Field *f, int off);
    table_type_t set_match_table(MatchTable *m) {
        match_tables.insert(m);
        if ((unsigned)m->logical_id < (unsigned)logical_id) logical_id = m->logical_id;
        return ACTION; }
    GatewayTable *get_gateway() {
        return match_tables.size() == 1 ? (*match_tables.begin())->get_gateway() : 0; }
    SelectionTable *get_selector() {
        return match_tables.size() == 1 ? (*match_tables.begin())->get_selector() : 0; }
)

DECLARE_TABLE_TYPE(GatewayTable, Table, "gateway",
    MatchTable                  *match_table;
    uint64_t                    payload;
    int                         gw_unit;
public:
    struct MatchKey {
        unsigned                offset;
        Phv::Ref                val;
        MatchKey(gress_t gr, value_t &v) : offset(0), val(gr, v) {}
        MatchKey(int off, gress_t gr, value_t &v) : offset(off), val(gr, v) {}
    };
private:
    std::vector<MatchKey>       match, xor_match;
    struct Match {
        match_t                 val;
        bool                    run_table;
        Ref                     next;
        Match() : val{0,0}, run_table(false) {}
        Match(match_t &v, value_t &data);
    }                           miss;
    std::vector<Match>          table;
public:
    table_type_t set_match_table(MatchTable *m) {
        match_table = m;
        if ((unsigned)m->logical_id < (unsigned)logical_id) logical_id = m->logical_id;
        return GATEWAY; }
    static GatewayTable *create(int lineno, const std::string &name, gress_t gress,
                                Stage *stage, int lid, VECTOR(pair_t) &data)
        { return table_type.create(lineno, name.c_str(), gress, stage, lid, data); }
   GatewayTable *get_gateway() { return this; }
   SelectionTable *get_selector() { return match_table ? match_table->get_selector() : 0; }
)

DECLARE_TABLE_TYPE(SelectionTable, Table, "selection",
    std::set<MatchTable *>      match_tables;
    bool                non_linear_hash, resilient_hash;
                        /* resilient_hash == false is fair hash */
    int                 mode_lineno, param;
    std::vector<int>    pool_sizes;
    int                 min_words, max_words;
public:
    bool                per_flow_enable;
    table_type_t set_match_table(MatchTable *m) {
        match_tables.insert(m);
        if ((unsigned)m->logical_id < (unsigned)logical_id) logical_id = m->logical_id;
        return SELECTION; }
    void vpn_params(int &width, int &depth, int &period, const char *&period_name) {
        width = period = 1; depth = layout_size(); period_name = 0; }
    GatewayTable *get_gateway() {
        return match_tables.size() == 1 ? (*match_tables.begin())->get_gateway() : 0; }
    SelectionTable *get_selector() {
        return match_tables.size() == 1 ? (*match_tables.begin())->get_selector() : 0; }
    void write_merge_regs(int type, int bus, Table *action, bool indirect);
    unsigned address_shift() { return 8 + ceil_log2(min_words); }
)

#endif /* _tables_h_ */
