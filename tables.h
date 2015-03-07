#ifndef _tables_h_
#define _tables_h_

#include "alloc.h"
#include "asm-types.h"
#include "bitvec.h"
#include "json.h"
#include "map.h"
#include <string>
#include "phv.h"
#include <vector>

class Stage;
class Instruction;
class InputXbar;
class MatchTable;
class GatewayTable;

class Table {
protected:
    Table(int line, std::string &&n, gress_t gr, Stage *s, int lid = -1)
        : name_(n), stage(s), match_table(0), gress(gr), lineno(line),
          logical_id(lid), gateway(0), input_xbar(0), format(0), actions(0),
          action_bus(0) {
            assert(all.find(name_) == all.end());
            all.emplace(name_, this); }
    virtual ~Table() { all.erase(name_); }
    virtual void setup(VECTOR(pair_t) &data) = 0;
    void setup_layout(value_t *row, value_t *col, value_t *bus);
    void setup_logical_id();
    void setup_action_table(value_t &);
    void setup_actions(value_t &);
    void setup_vpns(VECTOR(value_t) *);
    void alloc_rams(bool logical, Alloc2Dbase<Table *> &use, Alloc2Dbase<Table *> *bus_use);
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
        void check() {
            if (set() && !*this)
                error(lineno, "No table named %s", name.c_str()); }
    };

    class Format {
        struct bitrange_t { unsigned lo, hi;
            bitrange_t(unsigned l, unsigned h) : lo(l), hi(h) {}
            bool operator==(const bitrange_t &a) const { return lo == a.lo && hi == a.hi; }
        };
    public:
        struct Field {
            unsigned    size, group, flags;
            std::vector<bitrange_t>    bits;
            int         action_xbar;
            int         action_xbar_bit;
            Field       **by_group;
            Field() : size(0), group(0), flags(0),
                action_xbar(-1), action_xbar_bit(0), by_group(0) {}
            bool operator==(const Field &a) const { return size == a.size; }
            unsigned hi(unsigned bit) {
                for (auto &chunk : bits)
                    if (bit >= chunk.lo && bit <= chunk.hi)
                        return chunk.hi;
                assert(0); }
            enum flags_t { USED_IMMED=1 };
        };
        Format(VECTOR(pair_t) &);
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
    class Actions {
        typedef std::map<std::string, std::pair<int, std::vector<Instruction *>>> act_t;
        act_t                           actions;
        std::vector<act_t::iterator>    order;
        typedef std::vector<act_t::iterator>::iterator  iterator;
    public:
        Actions(Table *tbl, VECTOR(pair_t) &);
        int             lineno;
        iterator begin() { return order.begin(); }
        iterator end() { return order.end(); }
        bool exists(const std::string &n) { return actions.count(n) > 0; }
        void pass1(Table *);
        void pass2(Table *);
        void write_regs(Table *);
    };
    class ActionBus {
	std::map<std::string, std::pair<std::vector<unsigned>, Table::Format::Field *>>      by_name;
	std::map<unsigned, std::pair<std::string, Table::Format::Field *>>   by_byte;
    public:
        int             lineno;
        ActionBus() : lineno(-1) {}
	ActionBus(Table *, VECTOR(pair_t) &);
        void pass1(Table *tbl);
        void pass2(Table *tbl);
        void set_immed_offsets(Table *tbl);
        void set_action_offsets(Table *tbl);
        void write_immed_regs(Table *tbl);
        void write_action_regs(Table *tbl, unsigned homerow, unsigned action_slice);
    };
public:
    std::string                 name_;
    Stage                       *stage;
    MatchTable                  *match_table;
    gress_t                     gress;
    int                         lineno;
    int                         logical_id;
    GatewayTable                *gateway;
    InputXbar			*input_xbar;
    std::vector<Layout>         layout;
    Format                      *format;
    Ref                         action;
    std::vector<Format::Field*> action_args;
    Actions                     *actions;
    ActionBus			*action_bus;
    std::vector<Ref>            hit_next;
    Ref                         miss_next;

    static std::map<std::string, Table *>       all;

    unsigned layout_size() {
        unsigned rv = 0;
        for (auto &row : layout) rv += row.cols.size();
        return rv; }
    virtual Format::Field *lookup_field(const std::string &n,
                                        const std::string &act = "")
        { return format ? format->field(n) : 0; }
    virtual void apply_to_field(const std::string &n, std::function<void(Format::Field *)> fn)
        { if (format) format->apply_to_field(n, fn); }
};

class MatchTable : public Table {
protected:
    MatchTable(int l, std::string &&n, gress_t g, Stage *s, int lid)
        : Table(l, std::move(n), g, s, lid) {}
    void link_action(Table::Ref &ref);
    void write_regs(int type, Table *result);
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
    struct GroupInfo {
        /* info about which word(s) are used per group with wide matches */
        int                     overhead_word;  /* which word of wide match contains overhead */
        int                     word_group;     /* which match group within the word to use */
        std::map<int, int>      match_group;    /* which match group for each word with match */
        GroupInfo() : overhead_word(-1), word_group(-1) {}
    };
    std::vector<GroupInfo>      group_info;
    std::vector<std::vector<int>> word_info;    /* which format group corresponds to each
                                                 * match group in each word */
)
DECLARE_TABLE_TYPE(TernaryMatchTable, MatchTable, "ternary_match",
public:
    int tcam_id;
    Table::Ref indirect;
    Format::Field *lookup_field(const std::string &name, const std::string &action) {
        assert(!format);
        return indirect ? indirect->lookup_field(name, action) : 0; }
)
DECLARE_TABLE_TYPE(TernaryIndirectTable, Table, "ternary_indirect",)
DECLARE_TABLE_TYPE(ActionTable, Table, "action",
    std::map<std::string, Format *>     action_formats;
    Format::Field *lookup_field(const std::string &name, const std::string &action);
    void apply_to_field(const std::string &n, std::function<void(Format::Field *)> fn);
)
DECLARE_TABLE_TYPE(GatewayTable, Table, "gateway",
    uint64_t                    payload;
    int                         gw_unit;
    std::vector<Phv::Ref>       match, xor_match;
    struct Match {
        match_t                 val;
        bool                    run_table;
        Ref                     next;
        Match() : val{0,0}, run_table(false) {}
        Match(match_t &v, value_t &data);
    }                           miss;
    std::vector<Match>          table;
public:
    static GatewayTable *create(int lineno, const std::string &name, gress_t gress,
                                Stage *stage, int lid, VECTOR(pair_t) &data)
        { return table_type.create(lineno, name.c_str(), gress, stage, lid, data); }
)

#endif /* _tables_h_ */
