#ifndef _tables_h_
#define _tables_h_

#include <iostream>
#include <config.h>

#include <set>
#include <string>
#include <vector>
#include <unordered_map>
#include <bitops.h>
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
struct ActionBusSource;
class AttachedTable;
struct AttachedTables;
class GatewayTable;
class IdletimeTable;
class ActionTable;
struct Instruction;
class InputXbar;
class MatchTable;
class SelectionTable;
class StatefulTable;
class MeterTable;
class Synth2Port;
class Stage;
struct HashCol;

struct RandomNumberGen {
    int         unit;
    RandomNumberGen(int u) : unit(u) {}
    bool operator==(const RandomNumberGen &a) const { return unit == a.unit; }
};

enum class TableOutputModifier { NONE, Color, Address };
std::ostream &operator<<(std::ostream &, TableOutputModifier);

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
        int                     row = -1;
        int                     bus = -1;        // search bus for SRamMatch
        // result bus for SRamMatch, if the result bus is not used, a -1 is a possible value
        int                     result_bus = -2;
        int                     word = -1;      // which word for wide tables
        bool                    home_row = false;       // is this a home row
        std::vector<int>        cols, vpns, maprams;
        Layout() = default;
        Layout(int l, int r) : lineno(l), row(r) {}
        friend std::ostream &operator<<(std::ostream &, const Layout &);

        bool word_initialized() const { return word >= 0; }
        bool result_bus_initialized() const { return result_bus >= -1 && result_bus <= 1; }
        bool result_bus_used() const { return result_bus >= 0; }
    };
protected:
    Table(int line, std::string &&n, gress_t gr, Stage *s, int lid = -1);
    virtual ~Table();
    Table(const Table &) = delete;
    Table(Table &&) = delete;
    virtual void setup(VECTOR(pair_t) &data) = 0;
    virtual void common_init_setup(const VECTOR(pair_t) &, bool, P4Table::type);
    virtual bool common_setup(pair_t &, const VECTOR(pair_t) &, P4Table::type);
    void setup_layout(std::vector<Layout> &, const VECTOR(pair_t) &data, const char *subname = "");
    int setup_layout_attrib(std::vector<Layout> &, const value_t &data,
                            const char *what, int Layout::*attr);
    void setup_logical_id();
    void setup_actions(value_t &);
    void setup_maprams(value_t &);
    void setup_vpns(std::vector<Layout> &, VECTOR(value_t) *, bool allow_holes = false);
    virtual void vpn_params(int &width, int &depth, int &period, const char *&period_name) const
    { BUG(); }
    virtual int get_start_vpn() { return 0; }
    void alloc_rams(bool logical, Alloc2Dbase<Table *> &use, Alloc2Dbase<Table *> *bus_use = 0);
    void alloc_busses(Alloc2Dbase<Table *> &bus_use);
    void alloc_id(const char *idname, int &id, int &next_id, int max_id,
                  bool order, Alloc1Dbase<Table *> &use);
    void alloc_maprams();
    virtual void alloc_vpns();
    void need_bus(int lineno, Alloc1Dbase<Table *> &use, int idx, const char *name);
    static bool allow_ram_sharing(const Table *t1, const Table *t2);
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
            BUG_CHECK(a.type == tSTR);
            name = a.s;
            lineno = a.lineno;
            return *this; }
        Ref(const std::string &n) : lineno(-1), name(n) {}
        Ref(const char *n) : lineno(-1), name(n) {}
        Ref(const value_t &a) : lineno(a.lineno) { if (CHECKTYPE(a, tSTR)) name = a.s; }
        Ref &operator=(const std::string &n) { name = n; return *this; }
        operator bool() const { return all.count(name) > 0; }
        operator Table*() const { return ::get(all, name); }
        Table *operator->() const { return ::get(all, name); }
        bool set() const { return lineno >= 0; }
        bool operator==(const Table *t) const { return name == t->name_; }
        bool operator==(const char *t) const { return name == t; }
        bool operator==(const std::string &t) const { return name == t; }
        bool operator==(const Ref &a) const { return name == a.name; }
        bool operator<(const Ref &a) const { return name < a.name; }
        bool check() const {
            if (set() && !*this)
                error(lineno, "No table named %s", name.c_str());
            return *this; }
    };

    class NextTables {
        std::set<Ref>   next;
        int             long_branch = -1;       // long branch tag to use (if any)
        const Table     *next_table_ = nullptr; // table to use as next table (if any)
        bool            resolved = false;
        bool            can_use_lb(int stage, const NextTables &);
     public:
        int             lineno = -1;
        NextTables() = default;
        NextTables(const NextTables &) = default;
        NextTables(NextTables &&) = default;
        NextTables &operator=(const NextTables &a) = default;
        NextTables &operator=(NextTables &&) = default;
        NextTables(value_t &v);

        std::set<Ref>::iterator begin() const { return next.begin(); }
        std::set<Ref>::iterator end() const { return next.end(); }
        bool operator==(const NextTables &a) const { return next == a.next; }
        bool subset_of(const NextTables &a) const {
            for (auto &n : next)
                if (!a.next.count(n)) return false;
            return true; }
        void resolve_long_branch(const Table *tbl, const std::map<int, NextTables> &lbrch);
        bool set() const { return lineno >= 0; }
        int next_table_id() const {
            BUG_CHECK(resolved);
            return next_table_ ? next_table_->table_id() : Target::END_OF_PIPE(); }
        std::string next_table_name() const {
            BUG_CHECK(resolved);
            return next_table_ ? next_table_->p4_name() : "END"; }
        const Table *next_table() const { return next_table_; }
        int long_branch_tag() const { return long_branch; }
        unsigned next_in_stage(int stage) const;
        bool need_next_map_lut() const;
        void force_single_next_table();
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
            Format      *fmt;  // containing format
            bool operator==(const Field &a) const { return size == a.size; }
            /* return the bit in the format that contains bit i of this field */
            unsigned bit(unsigned i) {
                unsigned last = 0;
                for (auto &chunk : bits) {
                    if (i < (unsigned)chunk.size())
                        return chunk.lo + i;
                    i -= chunk.size();
                    last = chunk.hi+1; }
                if (i == 0) return last;
                BUG();
                return 0; // quiet -Wreturn-type warning
            }
            /* bit(i), adjusted for the immediate shift of the match group of the field
             * returns the bit in the post-extract immediate containing bit i */
            unsigned immed_bit(unsigned i) {
                auto rv = bit(i);
                if (fmt->immed) rv -= fmt->immed->by_group[group]->bit(0);
                return rv; }
            unsigned hi(unsigned bit) {
                for (auto &chunk : bits)
                    if (bit >= chunk.lo && bit <= chunk.hi)
                        return chunk.hi;
                BUG();
                return 0; // quiet -Wreturn-type warning
            }
            enum flags_t { NONE=0, USED_IMMED=1, ZERO=3 };
            bool conditional_value = false;
            std::string condition;
            Field(Format *f) : fmt(f) {}
            Field(Format *f, unsigned size, unsigned lo = 0, enum flags_t fl = NONE)
                : size(size), flags(fl), fmt(f) {
                if (size) bits.push_back({ lo, lo + size-1 }); }
            Field(const Field &f, Format *fmt) : size(f.size), flags(f.flags), bits(f.bits), fmt(fmt) {}

            /// mark all bits from the field in @param bitset
            void set_field_bits(bitvec &bitset) {
                for (auto &b : bits) bitset.setrange(b.lo, b.size());
            }
        };
        friend std::ostream &operator<<(std::ostream &, const Field &);
        Format(Table *t) : tbl(t) { fmt.resize(1); }
        Format(Table *, const VECTOR(pair_t) &data, bool may_overlap = false);
        ~Format();
        void pass1(Table *tbl);
        void pass2(Table *tbl);
    private:
        std::vector<ordered_map<std::string, Field>>                  fmt;
        std::map<unsigned, ordered_map<std::string, Field>::iterator> byindex;
        static bool equiv(const ordered_map<std::string, Field> &,
                          const ordered_map<std::string, Field> &);
    public:
        int                     lineno = -1;
        Table                   *tbl;
        unsigned                size = 0, immed_size = 0;
        Field                   *immed = 0;
        unsigned                log2size = 0; /* ceil(log2(size)) */
        int                     overhead_word = -1;

        unsigned groups() const { return fmt.size(); }
        Field *field(const std::string &n, int group = 0) {
            BUG_CHECK(group >= 0 && (size_t)group < fmt.size());
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
        void add_field(Field &f, std::string name="dummy", int grp=0 ) {
            fmt[grp].emplace(name, Field(f, this)); }
        decltype(fmt[0].begin()) begin(int grp=0) { return fmt[grp].begin(); }
        decltype(fmt[0].end()) end(int grp=0) { return fmt[grp].end(); }
        decltype(fmt[0].cbegin()) begin(int grp=0) const { return fmt[grp].begin(); }
        decltype(fmt[0].cend()) end(int grp=0) const { return fmt[grp].end(); }
        bool is_wide_format() const {
            return (log2size >= 7 || groups() > 1) ? true : false; }
        int get_entries_per_table_word() const {
            // A phase0 table can only have 1 entry
            if (tbl->table_type() == PHASE0) return 1;
            if (is_wide_format()) return groups();
            return log2size ? (1U << (ceil_log2(MEM_WORD_WIDTH) - log2size)) : 0; }
        int get_mem_units_per_table_word() const {
            return is_wide_format() ? ((size - 1)/MEM_WORD_WIDTH) + 1 : 1; }
        int get_table_word_width() const {
            return is_wide_format() ?
                MEM_WORD_WIDTH * get_mem_units_per_table_word() : MEM_WORD_WIDTH; }
        int get_padding_format_width() const {
            return is_wide_format() ? get_mem_units_per_table_word() * MEM_WORD_WIDTH
                                        : (1U << log2size); }
    };

    struct Call : Ref { /* a Ref with arguments */
        struct Arg {
            enum { Field, HashDist, Counter, Const, Name }    type;
        private:
            union {
                Format::Field           *fld;
                HashDistribution        *hd;
                intptr_t                val;
                char                    *str;
            };
        public:
            Arg() = delete;
            Arg(const Arg &a) : type(a.type) {
                memcpy(this, &a, sizeof(*this));
                if (type == Name) str = strdup(str); }
            Arg(Arg &&a) : type(a.type) {
                memcpy(this, &a, sizeof(*this));
                a.type = Const; }
            Arg &operator=(const Arg &a) {
                if (type == Name) free(str);
                memcpy(this, &a, sizeof(*this));
                if (type == Name) str = strdup(str);
                return *this; }
            Arg &operator=(Arg &&a) {
                std::swap(type, a.type);
                std::swap(val, a.val);
                return *this; }
            Arg(Format::Field *f) : type(Field) { fld = f; }
            Arg(HashDistribution *hdist) : type(HashDist) { hd = hdist; }
            Arg(int v) : type(Const) { val = v; }
            Arg(const char *n) : type(Name) { str = strdup(n); }
            Arg(decltype(Counter) ctr, int mode) : type(Counter) { val = mode;
                BUG_CHECK(ctr == Counter); }
            ~Arg() { if (type == Name) free(str); }
            bool operator==(const Arg &a) const {
                if (type != a.type) return false;
                switch(type) {
                    case Field: return fld == a.fld;
                    case HashDist: return hd == a.hd;
                    case Counter: case Const: return val == a.val;
                    case Name: return !strcmp(str, a.str);
                    default: BUG(); }
                return false;
            }
            bool operator!=(const Arg &a) const { return !operator==(a); }
            Format::Field *field() const { return type == Field ? fld : nullptr; }
            HashDistribution *hash_dist() const { return type == HashDist ? hd : nullptr; }
            const char *name() const { return type == Name ? str : nullptr; }
            int count_mode() const { return type == Counter ? val : 0; }
            int value() const { return type == Const ? val : 0; }
            operator bool() const { return fld != nullptr; }
            unsigned size() const;
        };
        std::vector<Arg>        args;
        void setup(const value_t &v, Table *tbl);
        Call() {}
        Call(const value_t &v, Table *tbl) { setup(v, tbl); }
        bool operator==(const Call &a) const { return Ref::operator==(a) && args == a.args; }
        bool operator!=(const Call &a) const { return !(*this == a); }
        bool is_direct_call() const {
            if (args.size() == 0)
                return false;
            if (args[0] == "$DIRECT")
                return true;
            return false;
        }
    };

    struct p4_param {
        std::string name;
        std::string alias;
        std::string key_name;
        unsigned start_bit;
        unsigned position;
        unsigned bit_width;
        unsigned bit_width_full;
        std::string default_value;  // value stored as hex string to accommodate large nos
        bool defaulted;
        bool is_valid;
        std::string type;
        p4_param(std::string n = "", unsigned p = 0, unsigned bw = 0, unsigned bwf = 0, std::string t = "",std::string v = "", bool d = false, bool i = false, unsigned s = 0) :
            name(n), start_bit(s), position(p), bit_width(bw), bit_width_full(bwf), default_value(v), defaulted(d), is_valid(i), type(t) {}
    };
    friend std::ostream &operator<<(std::ostream &, const p4_param &);
    typedef std::vector<p4_param>  p4_params;

    class Actions {
    public:
        struct Action {
            struct alias_t {
                std::string     name;
                int             lineno = -1, lo = -1, hi = -1;
                bool            is_constant = false;
                unsigned        value;
                alias_t(value_t &);
                unsigned size() const {
                    if (hi != -1 && lo != -1)
                        return hi - lo + 1;
                    else
                        return 0;
                }
            };
            std::string                         name;
            std::string                         rng_param_name = "";
            int                                 lineno = -1, addr = -1, code = -1;
            std::multimap<std::string, alias_t> alias;
            std::vector<Instruction *>          instr;
            bitvec                              slot_use;
            unsigned                            handle = 0;
            p4_params                           p4_params_list;
            bool                                default_allowed = false;
            bool                                default_only = false;
            bool                                is_constant = false;
            std::string                         default_disallowed_reason = "";
            std::vector<Call>                   attached;
            int                                 next_table_encode = -1;
            NextTables                          next_table_ref;
            NextTables                          next_table_miss_ref;
            std::map<std::string, std::vector<bitvec>> mod_cond_values;
            // The hit map points to next tables for actions as ordered in the
            // assembly, we use 'position_in_assembly' to map the correct next
            // table, as actions can be ordered in the map different from the
            // assembly order.
            int                                 position_in_assembly = -1;
            bool                                minmax_use = false;  // jbay sful min/max
            Action(Table *, Actions *, pair_t &, int);
            enum mod_cond_loc_t { MC_ADT, MC_IMMED };
            void setup_mod_cond_values(value_t &map);
            Action(const char *n, int l) : name(n), lineno(l) {}
            Action(const Action &) = delete;
            Action(Action &&) = delete;
            bool equiv(Action *a);
            bool equivVLIW(Action *a);
            typedef const decltype(alias)::value_type alias_value_t;
            std::map<std::string, std::vector<alias_value_t *>> reverse_alias() const;
            std::string alias_lookup(int lineno, std::string name, int &lo, int &hi) const;
            bool has_rng() { return !rng_param_name.empty(); }
            const p4_param* has_param(std::string param) const {
                for (auto &e : p4_params_list)
                    if (e.name == param) return &e;
                return nullptr; }
            void pass1(Table *tbl);
            void check_next(Table *tbl);
            void check_next_ref(Table *tbl, const Table::Ref &ref) const;
            void add_indirect_resources(json::vector &indirect_resources) const;
            bool is_color_aware() const;
            void gen_simple_tbl_cfg(json::vector &) const;
            void add_p4_params(json::vector &, bool include_default = true) const;
            void check_conditional(Table::Format::Field &field) const;
            bool immediate_conditional(int lo, int sz, std::string &condition) const;
            friend std::ostream &operator<<(std::ostream &, const alias_t &);
            friend std::ostream &operator<<(std::ostream &, const Action &);
        };
    private:
        typedef ordered_map<std::string, Action> map_t;
        map_t                   actions;
        bitvec                  code_use;
        std::map<int, Action *> by_code;
        bitvec                  slot_use;
        Table                   *table;
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
        void add_p4_params(const Action&, json::vector &) const;
        void gen_tbl_cfg(json::vector &) const ;
        void add_immediate_mapping(json::map &);
        void add_action_format(const Table *, json::map &) const;
        bool has_hash_dist() { return ( table->table_type() == HASH_ACTION ); }
        size_t size() { return actions.size(); }
    };

public:
    const char *name() const { return name_.c_str(); }
    const char *p4_name() const { if(p4_table) return p4_table->p4_name(); return ""; }
    unsigned p4_size() const { if(p4_table) return p4_table->p4_size(); return 0; }
    unsigned handle() const { if(p4_table) return p4_table->get_handle(); return -1; }
    std::string action_profile() const { if(p4_table) return p4_table->action_profile; return ""; }
    std::string how_referenced() const { if(p4_table) return p4_table->how_referenced; return ""; }
    int table_id() const;
    virtual void pass0() {} // only match tables need pass0
    virtual void pass1();
    virtual void pass2() = 0;
    virtual void pass3() = 0;
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        virtual void write_action_regs, (mau_regs &, const Actions::Action *), {})
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        virtual void write_merge_regs, (mau_regs &, int type, int bus), { assert(0); })
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        virtual void write_merge_regs, (mau_regs &, MatchTable *match, int type, int bus,
                                        const std::vector<Call::Arg> &args), { assert(0); })
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        virtual void write_regs, (mau_regs &), = 0)

    virtual void gen_tbl_cfg(json::vector &out) const = 0;
    virtual void gen_name_lookup(json::map &out) {}
    virtual json::map *base_tbl_cfg(json::vector &out, const char *type, int size) const;
    virtual json::map *add_stage_tbl_cfg(json::map &tbl, const char *type, int size) const;
    virtual std::unique_ptr<json::map> gen_memory_resource_allocation_tbl_cfg(
            const char *type, const std::vector<Layout> &layout, bool skip_spare_bank = false) const;
    virtual void common_tbl_cfg(json::map &tbl) const;
    bool add_json_node_to_table(json::map &tbl, const char *name) const;
    enum table_type_t { OTHER=0, TERNARY_INDIRECT, GATEWAY, ACTION, SELECTION, COUNTER,
                        METER, IDLETIME, STATEFUL, HASH_ACTION, EXACT, TERNARY, PHASE0, ATCAM,
                        PROXY_HASH };
    virtual table_type_t table_type() const { return OTHER; }
    virtual int instruction_set() { return 0; /* VLIW_ALU */ }
    virtual table_type_t set_match_table(MatchTable *m, bool indirect) { assert(0); return OTHER; }
    virtual const MatchTable *get_match_table() const { assert(0); return nullptr; }
    virtual MatchTable *get_match_table() { assert(0); return nullptr; }
    virtual std::set<MatchTable *> get_match_tables() { return std::set<MatchTable *>(); }
    virtual const AttachedTables *get_attached() const { return 0; }
    virtual AttachedTables *get_attached() { return 0; }
    virtual const GatewayTable *get_gateway() const { return 0; }
    virtual GatewayTable *get_table_gateway() { return 0; }
    virtual SelectionTable *get_selector() const { return 0; }
    virtual MeterTable* get_meter() const { return 0; }
    virtual void set_stateful (StatefulTable *s) { BUG(); }
    virtual StatefulTable *get_stateful() const { return 0; }
    virtual void set_address_used() { BUG(); }
    virtual void set_color_used() { BUG(); }
    virtual void set_output_used() { BUG(); }
    virtual const Call &get_action() const { return action; }
    virtual bool is_attached(const Table *) const { BUG(); return false; }
    virtual Format::Field *find_address_field(const AttachedTable *) const { BUG(); return 0; }
    virtual Format::Field *get_per_flow_enable_param(MatchTable *) const { BUG(); return 0; }
    virtual Format::Field *get_meter_address_param(MatchTable *) const { BUG(); return 0; }
    virtual Format::Field *get_meter_type_param(MatchTable *) const { BUG(); return 0; }
    virtual int direct_shiftcount() const { BUG(); return -1; }
    virtual int indirect_shiftcount() const { BUG(); return -1; }
    virtual int address_shift() const { BUG(); return -1; }
    virtual int home_row() const { BUG(); return -1; }
    /* row,col -> mem unitno mapping -- unitnumbers used in context json */
    virtual int memunit(const int r, const int c) const { return r*12 + c; }
    virtual int unitram_type() { BUG(); return -1; }
    virtual bool uses_colormaprams() const { return false; }
    virtual int color_shiftcount(Table::Call &call, int group, int tcam_shift) const {
        BUG(); return -1; }
    virtual int color_addr_type() const { BUG(); return -1; }
    virtual bool adr_mux_select_stats() { return false; }
    virtual bool run_at_eop() { return false; }
    virtual Format* get_format() { return format; }
    virtual unsigned determine_shiftcount(Table::Call &call, int group, unsigned word,
           int tcam_shift) const { assert(0); return -1; }
    template<class REGS> void write_mapram_regs(REGS &regs, int row, int col, int vpn, int type);
    template<class T> T *to() { return dynamic_cast<T *>(this); }
    template<class T> const T *to() const { return dynamic_cast<const T *>(this); }
    virtual void determine_word_and_result_bus() { BUG(); }

    std::string                 name_;
    int                         uid;
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
    Call                        instruction;
    Actions                     *actions = 0;
    ActionBus                   *action_bus = 0;
    std::string                 default_action;
    unsigned                    default_action_handle = 0;
    int                         default_action_lineno = -1;
    typedef std::map<std::string, std::string> default_action_params;
    default_action_params       default_action_parameters;
    bool                        default_only_action = false;
    std::vector<NextTables>     hit_next;
    std::vector<NextTables>     extra_next_lut;  // extra entries not in the hit_next from gateway
    // currently the assembler will add extra elements to the 8 entry next table lut if they
    // are needed for a gateway and not present in the lut already.  We add these in a separate
    // vector from hit_next so that context.json only reports the original hit_next from the source
    // and we don't try to get a next table hit index from the action.
    NextTables                  miss_next;
    std::map<int, NextTables>   long_branch;
    int                         long_branch_input = -1;
    std::map<Table *, std::set<Actions::Action *>>
                                pred;   // predecessor tables w the actions in that table that
                                        // call this table
    std::vector<HashDistribution>       hash_dist;
    p4_params                   p4_params_list;
    std::unique_ptr<json::map>  context_json;
    // saved here in to extract into the context json
    unsigned                    next_table_adr_mask = 0U;
    bitvec                      reachable_tables_;

    static std::map<std::string, Table *>       all;

    unsigned layout_size() const {
        unsigned rv = 0;
        for (auto &row : layout) rv += row.cols.size();
        return rv; }
    unsigned layout_get_vpn(const int r, const int c) const {
        for (auto &row : layout) {
            if (row.row != r) continue;
            auto col = find(row.cols.begin(), row.cols.end(), c);
            if (col == row.cols.end()) continue;
            return row.vpns.at(col - row.cols.begin()); }
        BUG();
        return 0; }
    void layout_vpn_bounds(int &min, int &max, bool spare = false) {
        min = 1000000; max = -1;
        for (Layout &row : layout)
            for (auto v : row.vpns) {
                if (v < min) min = v;
                if (v > max) max = v; }
        if (spare && max > min) --max; }
    virtual Format::Field *lookup_field(const std::string &n,
                                        const std::string &act = "") const
        { return format ? format->field(n) : 0; }
    virtual std::string find_field(Format::Field *field) {
        return format ? format->find_field(field) : "<unknown>"; }
    virtual int find_field_lineno(Format::Field *field) {
        return format ? format->find_field_lineno(field) : -1; }
    virtual void apply_to_field(const std::string &n, std::function<void(Format::Field *)> fn)
        { if (format) format->apply_to_field(n, fn); }
    int find_on_ixbar(Phv::Slice sl, int group);
    virtual HashDistribution *find_hash_dist(int unit);
    virtual int find_on_actionbus(const ActionBusSource &src, int lo, int hi, int size, int pos = -1);
    virtual void need_on_actionbus(const ActionBusSource &src, int lo, int hi, int size);
    virtual int find_on_actionbus(const char *n, TableOutputModifier mod, int lo, int hi,
                                   int size, int *len = 0);
    int find_on_actionbus(const char *n, int lo, int hi, int size, int *len = 0) {
        return find_on_actionbus(n, TableOutputModifier::NONE, lo, hi, size, len); }
    int find_on_actionbus(const std::string &n, TableOutputModifier mod, int lo, int hi,
                          int size, int *len = 0) {
        return find_on_actionbus(n.c_str(), mod, lo, hi, size, len); }
    int find_on_actionbus(const std::string &n, int lo, int hi, int size, int *len = 0) {
        return find_on_actionbus(n.c_str(), TableOutputModifier::NONE, lo, hi, size, len); }
    virtual void need_on_actionbus(Table *att, TableOutputModifier mod, int lo, int hi, int size);
    static bool allow_bus_sharing(Table *t1, Table *t2);
    virtual Call &action_call() { return action; }
    virtual Call &instruction_call() { return instruction; }
    virtual Actions *get_actions() const { return actions; }
    virtual const std::vector<NextTables> &get_hit_next() const { return hit_next; }
    virtual const NextTables &get_miss_next() const { return miss_next; }
    virtual bool is_directly_referenced(const Table::Call& c) const;
    virtual void add_reference_table(json::vector &table_refs, const Table::Call& c) const;
    json::map &add_pack_format(json::map &stage_tbl, int memword, int words, int entries = -1) const;
    json::map &add_pack_format(json::map &stage_tbl, Table::Format *format, bool pad_zeros = true,
                               bool print_fields = true, Table::Actions::Action *act = nullptr) const;
    virtual void add_field_to_pack_format(json::vector &field_list, int basebit, std::string name,
                                          const Table::Format::Field &field,
                                          const Table::Actions::Action *act) const;
    virtual bool validate_call(Table::Call &call, MatchTable *self, size_t required_args,
            int hash_dist_type, Table::Call &first_call) { BUG(); return false; }
    bool validate_instruction(Table::Call &call) const;
                                          // const std::vector<Actions::Action::alias_value_t *> &);
    // Generate the context json for a field into field list.
    // Use the bits specified in field, offset by the base bit.
    // If the field is a constant, output a const_tuple map, including the specified value.
    void output_field_to_pack_format(json::vector &field_list, int basebit,
                                     std::string name, std::string source, int start_bit,
                                     const Table::Format::Field &field,
                                     unsigned value = 0) const;
    void add_zero_padding_fields(Table::Format *format,
                                 Table::Actions::Action *act = nullptr,
                                 unsigned format_width = 64) const;
    void get_cjson_source(const std::string &field_name, std::string &source, int &start_bit) const;
    // Result physical buses should be setup for
    // Exact/Hash/MatchwithNoKey/ATCAM/Ternary tables
    virtual void add_result_physical_buses(json::map &stage_tbl) const;
    void canon_field_list(json::vector &field_list) const;
    void for_all_next(std::function<void(const Ref &)> fn);
    void check_next(const Ref &next);
    void check_next(NextTables &next);
    void check_next();
    virtual void set_pred();
    bool choose_logical_id(const slist<Table *> *work = nullptr);
    virtual int hit_next_size() const { return hit_next.size(); }
    const p4_param *find_p4_param(std::string s, std::string t = "", int start_bit = -1, int width = -1) const {
        remove_name_tail_range(s);
        for (auto &p : p4_params_list) {
            if ((p.name == s) || (p.alias == s)) {
                if (!t.empty() && (p.type != t)) continue;
                if ((start_bit > -1) &&
                    (start_bit < p.start_bit)) continue;
                if ((width > -1) &&
                    (p.start_bit + p.bit_width < start_bit + width)) continue;
                return &p;
            }
        }
        return nullptr; }
    const p4_param *find_p4_param_type(std::string &s) const {
        for (auto &p : p4_params_list)
            if (p.type == s) return &p;
        return nullptr; }
    virtual std::string get_default_action() {
        return (!default_action.empty()) ? default_action : action ? action->default_action : ""; }
    virtual default_action_params* get_default_action_parameters() {
        return (!default_action_parameters.empty()) ? &default_action_parameters : action ? &action->default_action_parameters : nullptr; }
    virtual unsigned get_default_action_handle() const {
        return default_action_handle > 0 ? default_action_handle : action ? action->default_action_handle : 0; }
    int get_format_field_size(std::string s) const {
        if (auto field = lookup_field(s)) return field->size;
        return 0; }
    virtual bool needs_handle() const { return false; }
    virtual bool needs_next() const { return false; }
    virtual bitvec compute_reachable_tables();
    bitvec reachable_tables() {
        if (!reachable_tables_) reachable_tables_ = compute_reachable_tables();
        return reachable_tables_; }
};

class FakeTable : public Table {
public:
    FakeTable(const char *name) : Table(-1, name, INGRESS, 0, -1) {}
    void setup(VECTOR(pair_t) &data) override { assert(0); }
    void pass1() override { assert(0); }
    void pass2() override { assert(0); }
    void pass3() override { assert(0); }
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        virtual void write_regs, (mau_regs &), override { assert(0); })
    void gen_tbl_cfg(json::vector &out) const override { assert(0); }
};

class AlwaysRunTable : public Table {
    /* a 'table' to hold the always run action in a stage */
public:
    AlwaysRunTable(gress_t gress, Stage *stage, pair_t &init);
    void setup(VECTOR(pair_t) &data) override { assert(0); }
    void pass1() override { actions->pass1(this); }
    void pass2() override { actions->pass2(this); }
    void pass3() override { }
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        void write_regs,(mau_regs &regs), override; )
    void gen_tbl_cfg(json::vector &out) const override { }
};

struct AttachedTables {
    Table::Call                 selector;
    Table::Call                 selector_length;
    std::vector<Table::Call>    stats, meters, statefuls;
    Table::Call                 meter_color;
    SelectionTable *get_selector() const;
    MeterTable* get_meter(std::string name = "") const;
    StatefulTable *get_stateful(std::string name = "") const;
    Table::Format::Field *find_address_field(const AttachedTable *tbl) const;
    const Table::Call *get_call(const Table *) const;
    bool is_attached(const Table *tbl) const { return get_call(tbl) != nullptr; }
    void pass0(MatchTable *self);
    void pass1(MatchTable *self);
    template<class REGS> void write_merge_regs(REGS &regs, MatchTable *self, int type, int bus);
    template<class REGS> void write_tcam_merge_regs(REGS &regs, MatchTable *self, int bus,
                                                    int tcam_shift);
    bool run_at_eop();
    bitvec compute_reachable_tables() const;
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
    bool                        always_run = false;
    friend struct AttachedTables;
    enum { NONE=0, TABLE_MISS=1, TABLE_HIT=2, DISABLED=3, GATEWAY_MISS=4, GATEWAY_HIT=5,
           GATEWAY_INHIBIT=6 }  table_counter = NONE;

    using Table::pass1;
    using Table::write_regs;
    template<class TARGET> void write_common_regs(typename TARGET::mau_regs &, int, Table *);
    template<class REGS> void write_regs(REGS &, int type, Table *result);
    template<class REGS> void write_next_table_regs(REGS &, Table *);
    void common_init_setup(const VECTOR(pair_t) &, bool, P4Table::type) override;
    bool common_setup(pair_t &, const VECTOR(pair_t) &, P4Table::type) override;
    int get_address_mau_actiondata_adr_default(unsigned log2size, bool per_flow_enable);
public:
    void pass0() override;
    void pass1() override;
    void pass3() override;
    bool is_alpm() const {
        if (p4_table) return p4_table->is_alpm(); return false; }
    bool is_attached(const Table *tbl) const override;
    const Table::Call *get_call(const Table *tbl) const { return get_attached()->get_call(tbl); }
    const AttachedTables *get_attached() const override { return &attached; }
    AttachedTables *get_attached() override { return &attached; }
    const GatewayTable *get_gateway() const override { return gateway; }
    const MatchTable *get_match_table() const override { return this; }
    MatchTable *get_match_table() override { return this; }
    std::set<MatchTable *> get_match_tables() override {
        std::set<MatchTable *> rv;
        rv.insert(this);
        return rv; }
    Format::Field *find_address_field(const AttachedTable *tbl) const override {
        return attached.find_address_field(tbl); }
    void gen_name_lookup(json::map &out) override;
    Format::Field *lookup_field(const std::string &n, const std::string &act = "") const override;
    bool run_at_eop() override { return attached.run_at_eop(); }
    virtual bool is_ternary() { return false; }
    void gen_idletime_tbl_cfg(json::map &stage_tbl) const;
    int direct_shiftcount() const override { return 64; }
    void gen_hash_bits(const std::map<int, HashCol> &hash_table,
        unsigned hash_table_id, json::vector &hash_bits, unsigned hash_group_no,
        bitvec hash_bits_used) const;
    virtual void add_hash_functions(json::map &stage_tbl) const;
    void add_all_reference_tables(json::map &tbl, Table *math_table=nullptr) const;
    METER_ACCESS_TYPE default_meter_access_type(bool for_stateful);
    bool needs_handle() const override { return true; }
    bool needs_next() const override { return true; }
    void merge_context_json(json::map &tbl, json::map&stage_tbl) const;
    bitvec compute_reachable_tables() override;
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
    void pass3() override;                                              \
    template<class REGS> void write_regs(REGS &regs);                   \
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,                              \
        void write_regs,(mau_regs &regs), override {                    \
            write_regs<decltype(regs)>(regs); })                        \
    void gen_tbl_cfg(json::vector &out) const override;                 \
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

DECLARE_ABSTRACT_TABLE_TYPE(SRamMatchTable, MatchTable,         // exact, atcam, or proxy_hash
protected:
    struct Way {
        int                              lineno;
        int                              group, subgroup, mask;
        std::vector<std::pair<int, int>> rams;
        bitvec select_bits() const {
            bitvec rv(mask);
            rv <<= EXACT_HASH_FIRST_SELECT_BIT;
            rv.setrange(subgroup * EXACT_HASH_ADR_BITS, EXACT_HASH_ADR_BITS);
            return rv;
        }
    };
    std::vector<Way>                      ways;
    struct WayRam { int way, index, word, bank; };
    std::map<std::pair<int, int>, WayRam> way_map;
    std::vector<MatchSource *>              match;
    std::map<unsigned, MatchSource *>       match_by_bit;
    std::vector<std::vector<MatchSource *>> match_in_word;
    std::vector<int>                      word_ixbar_group;
    struct GroupInfo {
        /* info about which word(s) are used per format group with wide matches */
        int                     overhead_word;  /* which word of wide match contains overhead */
        int                     overhead_bit;   /* lowest bit that contains overhead in that word */
        // The word that is going to contain the result bus.  Same as the overhead word, if
        // the entry actually has overhead
        int                     result_bus_word;
        std::map<int, int>      match_group;    /* which match group for each word with match */
        std::vector<unsigned>   tofino_mask;    /* 14-bit tofino byte/nibble mask for each word */
        GroupInfo() : overhead_word(-1), overhead_bit(-1), result_bus_word(-1) {}
        // important function in order to determine shiftcount for exact match entries
        int result_bus_word_group() const { return match_group.at(result_bus_word); }
    };
    std::vector<GroupInfo>      group_info;
    std::vector<std::vector<int>> word_info;    /* which format group corresponds to each
                                                 * match group in each word */
    int         mgm_lineno = -1;                /* match_group_map lineno */
    bitvec version_nibble_mask;
    // Which hash groups are assigned to the hash_function_number in the hash_function json node
    // This is to coordinate with the hash_function_id in the ways
    std::map<unsigned, unsigned> hash_fn_ids;
    template<class REGS>
    void write_attached_merge_regs(REGS &regs, int bus, int word, int word_group);
    void common_sram_setup(pair_t &, const VECTOR(pair_t) &);
    void common_sram_checks();
    void alloc_vpns() override;
    virtual void setup_ways();
    void setup_hash_function_ids();
    void pass1() override;
    template<class REGS> void write_regs(REGS &regs);
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        void write_regs,(mau_regs &regs), override {
            write_regs<decltype(regs)>(regs); })
    virtual std::string get_match_mode(const Phv::Ref &pref, int offset) const;
    json::map* add_common_sram_tbl_cfgs(json::map &tbl,
        std::string match_type, std::string stage_table_type) const;
    void add_action_cfgs(json::map &tbl, json::map &stage_tbl) const;
    virtual unsigned entry_ram_depth() const { return 1024; }
    unsigned get_number_entries() const;
    unsigned get_format_width() const;
    virtual int determine_pre_byteswizzle_loc(MatchSource *ms, int lo, int hi, int word);
    void add_field_to_pack_format(json::vector &field_list, int basebit, std::string name,
                                  const Table::Format::Field &field,
                                  const Table::Actions::Action *act) const override;
    std::unique_ptr<json::map> gen_memory_resource_allocation_tbl_cfg(const Way &) const;
    Actions *get_actions() const override { return actions ? actions : (action ? action->actions : nullptr); }
    void add_hash_functions(json::map &stage_tbl) const override;
    virtual void gen_ghost_bits(int hash_function_number, json::vector &ghost_bits_to_hash_bits,
        json::vector &ghost_bits_info) const { }
public:
    Format::Field *lookup_field(const std::string &n, const std::string &act = "") const override;
    virtual void setup_word_ixbar_group();
    virtual void verify_format();
    virtual bool verify_match_key();
    void verify_match(unsigned fmt_width);
    void vpn_params(int &width, int &depth, int &period, const char *&period_name) const override {
        width = (format->size-1)/128 + 1;
        period = format->groups();
        depth = period * layout_size() / width;
        period_name = "match group size"; }
    template<class REGS> void write_merge_regs(REGS &regs, int type, int bus) {
        attached.write_merge_regs(regs, this, type, bus); }
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        void write_merge_regs, (mau_regs &regs, int type, int bus), override {
            write_merge_regs<decltype(regs)>(regs, type, bus); })
    bool is_match_bit(const std::string name, const int bit) const {
        for (auto *m : match) {
            std::string m_name = m->name();
            int m_lo = remove_name_tail_range(m_name) + m->fieldlobit();
            int m_hi = m_lo + m->size() -1;
            if (m_name == name) {
                if (m_lo <= bit
                        && m_hi >= bit)
                    return true;
            }
        }
        return false;
    }
    void determine_word_and_result_bus() override;
    SelectionTable *get_selector() const override { return attached.get_selector(); }
    StatefulTable *get_stateful() const override { return attached.get_stateful(); }
    MeterTable* get_meter() const override { return attached.get_meter(); }
)

DECLARE_TABLE_TYPE(ExactMatchTable, SRamMatchTable, "exact_match",
    bool dynamic_key_masks = false;
    void setup_ways() override;

    // The position of the ghost bits in a single hash function
    // The key is name of the field and the field bit, the value is one-hot for all
    // bits that this ghost bit has an impact on
    using GhostBitPositions = std::map<std::pair<std::string, int>, bitvec>;
    std::map<int, GhostBitPositions> ghost_bit_positions;
    Format* stash_format = nullptr;
    std::vector<int> stash_rows;
    std::vector<int> stash_cols;
    std::vector<int> stash_units;
    std::vector<int> stash_overhead_rows;

public:
    int unitram_type() override { return UnitRam::MATCH; }
    table_type_t table_type() const override { return EXACT; }
    bool has_group(int grp) {
        for (auto &way: ways)
            if (way.group == grp) return true;
        return false; }
    void determine_ghost_bits();
    void gen_ghost_bits(int hash_function_number, json::vector &ghost_bits_to_hash_bits,
                        json::vector &ghost_bits_info) const override;
    void generate_stash_overhead_rows();
)

DECLARE_TABLE_TYPE(AlgTcamMatchTable, SRamMatchTable, "atcam_match",
    // key is column priority, value is way index
    std::map<int, int>                    col_priority_way;
    int                                   number_partitions = 0;
    int                                   max_subtrees_per_partition = 0;
    int                                   bins_per_partition = 0;
    std::string                           partition_field_name = "";
    std::vector<int>                      ixbar_subgroup, ixbar_mask;
    struct match_element {
        Phv::Ref        *field;
        unsigned        offset, width;
    };
    bitvec                                s0q1_nibbles, s1q0_nibbles;
    std::vector<Phv::Ref*>                s0q1_prefs, s1q0_prefs;
    std::map<int, match_element>          s0q1, s1q0;
    table_type_t table_type() const override { return ATCAM; }
    void verify_format() override;
    void verify_entry_priority();
    void setup_column_priority();
    void find_tcam_match();
    void gen_unit_cfg(json::vector &units, int size) const;
    std::unique_ptr<json::vector> gen_memory_resource_allocation_tbl_cfg() const;
    void setup_nibble_mask(Table::Format::Field *match, int group,
                              std::map<int, match_element> &elems, bitvec &mask);
    std::string get_match_mode(const Phv::Ref &pref, int offset) const override;
    void base_alpm_atcam_tbl_cfg(json::map &atcam_tbl, const char *type, int size) const {
        if (p4_table) p4_table->base_alpm_tbl_cfg(atcam_tbl, size, this, P4Table::Atcam); }
    // For ATCAM tables, no hash functions are generated for the table, as the current
    // interpretation of the table is that the partition index is an identity hash function.
    // Potentially this could change at some point
    void add_hash_functions(json::map &stage_tbl) const override {}
    bool has_directly_attached_synth2port() const;
    std::string get_lpm_field_name() const {
        std::string lpm = "lpm";
        if(auto *p = find_p4_param_type(lpm))
            return p->key_name.empty() ? p->name : p->key_name;
        else error(lineno,
            "'lpm' type field not found in alpm atcam '%s-%s' p4 param order",
                name(), p4_name());
        return ""; }
    unsigned get_partition_action_handle() const {
        if (p4_table) return p4_table->get_partition_action_handle();
        return 0; }
    std::string get_partition_field_name() const {
        if (!p4_table) return "";
        auto name = p4_table->get_partition_field_name();
        if (auto* p = find_p4_param(name))
            if (!p->key_name.empty())
                return p->key_name;
        return name;
    }
    unsigned entry_ram_depth() const override { return std::min(number_partitions, 1024); }
)

DECLARE_TABLE_TYPE(ProxyHashMatchTable, SRamMatchTable, "proxy_hash",
    bool dynamic_key_masks = false;
    void setup_ways() override;
    int proxy_hash_group = -1;
    std::string proxy_hash_alg = "<invalid>";
    bool verify_match_key() override;
    table_type_t table_type() const override { return PROXY_HASH; }
    void setup_word_ixbar_group() override;
    int determine_pre_byteswizzle_loc(MatchSource *ms, int lo, int hi, int word) override;
    void add_proxy_hash_function(json::map &stage_tbl) const;
)

DECLARE_TABLE_TYPE(TernaryMatchTable, MatchTable, "ternary_match",
    void vpn_params(int &width, int &depth, int &period, const char *&period_name) const override;
    struct Match {
        int lineno=-1, word_group=-1, byte_group=-1, byte_config=0, dirtcam=0;
        Match() {}
        Match(const value_t &);
    };
    enum range_match_t { TCAM_NORMAL=0, DIRTCAM_2B=1, DIRTCAM_4B_LO=2, DIRTCAM_4B_HI=3, NONE=4 };
    enum byte_config_t { MIDBYTE_NIBBLE_LO=0, MIDBYTE_NIBBLE_HI=1 };
    std::vector<Match>  match;
    int match_word(int word_group) const {
        for (unsigned i = 0; i < match.size(); i++)
            if (match[i].word_group == word_group)
                return i;
        return -1; }
    unsigned            chain_rows[TCAM_UNITS_PER_ROW]; /* bitvector per column */
    enum { ALWAYS_ENABLE_ROW = (1<<2) | (1<<5) | (1<<9) };
    friend class TernaryIndirectTable;
public:
    void pass0() override;
    int tcam_id;
    Table::Ref indirect;
    int indirect_bus;   /* indirect bus to use if there's no indirect table */
    void alloc_vpns() override;
    range_match_t get_dirtcam_mode(int group, int byte) const {
        BUG_CHECK(group >= 0);
        BUG_CHECK(byte >= 0);
        range_match_t dirtcam_mode = NONE;
        for (auto &m : match) {
            if (m.word_group == group) {
                dirtcam_mode = (range_match_t) ((m.dirtcam >> 2*byte) & 0x3); } }
        return dirtcam_mode; }
    Format::Field *lookup_field(const std::string &name, const std::string &action) const override;
    HashDistribution *find_hash_dist(int unit) override {
        return indirect ? indirect->find_hash_dist(unit) : Table::find_hash_dist(unit); }
    int find_on_actionbus(const ActionBusSource &src, int lo, int hi, int size, int pos = -1) override {
        return indirect ? indirect->find_on_actionbus(src, lo, hi, size, pos)
                        : Table::find_on_actionbus(src, lo, hi, size, pos); }
    void need_on_actionbus(const ActionBusSource &src, int lo, int hi, int size) override {
        indirect ? indirect->need_on_actionbus(src, lo, hi, size)
                 : Table::need_on_actionbus(src, lo, hi, size); }
    int find_on_actionbus(const char *n, TableOutputModifier mod, int lo, int hi,
                          int size, int *len = 0) override {
        return indirect ? indirect->find_on_actionbus(n, mod, lo, hi, size, len)
                        : Table::find_on_actionbus(n, mod, lo, hi, size, len); }
    void need_on_actionbus(Table *att, TableOutputModifier mod, int lo, int hi, int size) override {
                indirect ? indirect->need_on_actionbus(att, mod, lo, hi, size)
                                     : Table::need_on_actionbus(att, mod, lo, hi, size); }
    const Call &get_action() const override { return indirect ? indirect->get_action() : action; }
    Actions *get_actions() const override { return actions ? actions :
        (action ? action->actions : indirect ? indirect->actions ? indirect->actions :
         indirect->action ? indirect->action->actions : 0 : 0); }
    const AttachedTables *get_attached() const override {
        return indirect ? indirect->get_attached() : &attached; }
    AttachedTables *get_attached() override {
        return indirect ? indirect->get_attached() : &attached; }
    SelectionTable *get_selector() const override {
        return indirect ? indirect->get_selector() : 0; }
    StatefulTable *get_stateful() const override {
        return indirect ? indirect->get_stateful() : 0; }
    MeterTable* get_meter() const override {
        return indirect ? indirect->get_meter() : 0; }
    bool is_attached(const Table *tbl) const override {
        return indirect ? indirect->is_attached(tbl) : MatchTable::is_attached(tbl); }
    Format::Field *find_address_field(const AttachedTable *tbl) const override {
        return indirect ? indirect->find_address_field(tbl) : attached.find_address_field(tbl); }
    std::unique_ptr<json::map> gen_memory_resource_allocation_tbl_cfg(
            const char *type, const std::vector<Layout> &layout, bool skip_spare_bank=false) const override;
    Call &action_call() override { return indirect ? indirect->action : action; }
    Call &instruction_call() override { return indirect ? indirect->instruction: instruction; }
    int memunit(const int r, const int c) const override { return r + c*12; }
    bool is_ternary() override { return true; }
    int hit_next_size() const override {
        if (indirect && indirect->hit_next.size() > 0)
            return indirect->hit_next.size();
        return hit_next.size(); }
    table_type_t table_type() const override { return TERNARY; }
    void gen_entry_cfg(json::vector &out, std::string name, \
        unsigned lsb_offset, unsigned lsb_idx, unsigned msb_idx, \
        std::string source, unsigned start_bit, unsigned field_width,
        unsigned index, bitvec &tcam_bits, unsigned byte_offset) const;
    void set_partition_action_handle(unsigned handle) {
        if (p4_table) p4_table->set_partition_action_handle(handle); }
    void set_partition_field_name(std::string name) {
        if (p4_table) p4_table->set_partition_field_name(name); }
    void base_alpm_pre_classifier_tbl_cfg(json::map &pre_classifier_tbl, const char *type, int size) const {
        if (p4_table)
            p4_table->base_alpm_tbl_cfg(pre_classifier_tbl, size, this, P4Table::PreClassifier); }
    void gen_match_fields_pvp(json::vector &match_field_list, unsigned word,
        bool uses_versioning, unsigned version_word_group, bitvec &tcam_bits) const;
    unsigned get_default_action_handle() const override {
        unsigned def_act_handle = Table::get_default_action_handle();
        return def_act_handle > 0 ? def_act_handle : indirect ? indirect->get_default_action_handle() ?
            indirect->get_default_action_handle() : action ? action->default_action_handle : 0 : 0; }
    std::string get_default_action() override {
        std::string def_act = Table::get_default_action();
        return !def_act.empty() ? def_act : indirect ? indirect->default_action : ""; }
    Format* get_format() override { return indirect ? indirect->format : format; }
    template<class REGS> void write_merge_regs(REGS &regs, int type, int bus) {
        attached.write_merge_regs(regs, this, type, bus); }
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        void write_merge_regs, (mau_regs &regs, int type, int bus), override {
            write_merge_regs<decltype(regs)>(regs, type, bus); })
    void add_result_physical_buses(json::map &stage_tbl) const override;
    default_action_params* get_default_action_parameters() override {
        if (!default_action_parameters.empty()) return &default_action_parameters;
        auto def_action_params = indirect ? indirect->get_default_action_parameters() : nullptr;
        return def_action_params; }
    bitvec compute_reachable_tables() override;
)

DECLARE_TABLE_TYPE(Phase0MatchTable, MatchTable, "phase0_match",
    int         size = MAX_PORTS;
    int         width = 1;
    int         constant_value = 0;
    table_type_t table_type() const override { return PHASE0; }
    // Phase0 Tables are not actual tables. They cannot have action data
    // or attached tables and do not need a logical id assignment, hence
    // we skip pass0
    void pass0() override {}
    void set_pred() override { return; }
    bool needs_next() const override { return false; }
)
DECLARE_TABLE_TYPE(HashActionTable, MatchTable, "hash_action",
public:
    //int                                 row = -1, bus = -1;
    table_type_t table_type() const override { return HASH_ACTION; }
    template<class REGS> void write_merge_regs(REGS &regs, int type, int bus);
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        void write_merge_regs, (mau_regs &regs, int type, int bus), override {
            write_merge_regs<decltype(regs)>(regs, type, bus); })
    Format::Field *lookup_field(const std::string &n,
                                        const std::string &act = "") const override;
    void add_hash_functions(json::map &stage_tbl) const override;
    void determine_word_and_result_bus() override;
)

DECLARE_TABLE_TYPE(TernaryIndirectTable, Table, "ternary_indirect",
    TernaryMatchTable           *match_table;
    AttachedTables              attached;
    table_type_t table_type() const override { return TERNARY_INDIRECT; }
    table_type_t set_match_table(MatchTable *m, bool indirect) override;
    void vpn_params(int &width, int &depth, int &period, const char *&period_name) const override {
        width = (format->size-1)/128 + 1;
        depth = layout_size() / width;
        period = 1;
        period_name = 0; }
    Actions *get_actions() const override { return actions ? actions : (match_table ? match_table->actions : nullptr); }
    const AttachedTables *get_attached() const override { return &attached; }
    AttachedTables *get_attached() override { return &attached; }
    const GatewayTable *get_gateway() const override { return match_table->get_gateway(); }
    const MatchTable *get_match_table() const override { return match_table; }
    MatchTable *get_match_table() override { return match_table; }
    std::set<MatchTable *> get_match_tables() override {
        std::set<MatchTable *> rv;
        if (match_table) rv.insert(match_table);
        return rv; }
    SelectionTable *get_selector() const override { return attached.get_selector(); }
    StatefulTable *get_stateful() const override { return attached.get_stateful(); }
    MeterTable* get_meter() const override { return attached.get_meter(); }
    bool is_attached(const Table *tbl) const override { return attached.is_attached(tbl); }
    Format::Field *find_address_field(const AttachedTable *tbl) const override {
        return attached.find_address_field(tbl); }
    template<class REGS> void write_merge_regs(REGS &regs, int type, int bus) {
        attached.write_merge_regs(regs, match_table, type, bus); }
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        void write_merge_regs, (mau_regs &regs, int type, int bus), override {
            write_merge_regs<decltype(regs)>(regs, type, bus); })
    int unitram_type() override { return UnitRam::TERNARY_INDIRECTION; }
public:
    Format::Field *lookup_field(const std::string &n,
                                        const std::string &act = "") const override;
    const std::vector<NextTables> &get_hit_next() const override {
        if (hit_next.empty() && match_table)
            return match_table->get_hit_next();
        return Table::get_hit_next(); }
    const NextTables &get_miss_next() const override {
        if (!miss_next.set() && match_table)
            return match_table->get_miss_next();
        return Table::get_miss_next(); }
    int address_shift() const override { return std::min(5U, format->log2size - 2); }
    unsigned get_default_action_handle() const override {
        unsigned def_act_handle = Table::get_default_action_handle();
        return def_act_handle ? def_act_handle : action ? action->default_action_handle : 0; }
    bool needs_handle() const override { return true; }
    bool needs_next() const override { return true; }
    void determine_word_and_result_bus() override;
    bitvec compute_reachable_tables() override;
)

DECLARE_ABSTRACT_TABLE_TYPE(AttachedTable, Table,
    /* table that can be attached to multiple match tables to do something */
    std::set<MatchTable *>      match_tables;
    bool                        direct = false, indirect = false;
    bool                        per_flow_enable = false;
    std::string                 per_flow_enable_param = "";
    virtual unsigned            per_flow_enable_bit(MatchTable *m = nullptr) const;
    table_type_t set_match_table(MatchTable *m, bool indirect) override {
        if ((indirect && direct) || (!indirect && this->indirect))
            error(lineno, "Table %s is accessed with direct and indirect indices", name());
        this->indirect = indirect;
        direct = !indirect;
        match_tables.insert(m);
        if ((unsigned)m->logical_id < (unsigned)logical_id) logical_id = m->logical_id;
        return table_type(); }
    const GatewayTable *get_gateway() const override {
        return match_tables.size() == 1 ? (*match_tables.begin())->get_gateway() : 0; }
    SelectionTable *get_selector() const override;
    StatefulTable *get_stateful() const override;
    MeterTable* get_meter() const override;
    Call &action_call() override {
        return match_tables.size() == 1 ? (*match_tables.begin())->action_call() : action; }
    int memunit(const int r, const int c) const override { return r*6 + c; }
    void pass1() override;
    unsigned get_alu_index() const {
        if(layout.size() > 0) return layout[0].row/4U;
        error(lineno, "Cannot determine ALU Index for table %s", name());
        return 0; }
    unsigned determine_meter_shiftcount(Table::Call &call, int group, int word,
        int tcam_shift) const;
    void determine_meter_merge_regs(MatchTable *match, int type,
        int bus, const std::vector<Call::Arg> &arg, METER_ACCESS_TYPE default_type,
        unsigned &adr_mask, unsigned &per_entry_mux_ctl, unsigned &adr_default,
        unsigned &meter_type_position);
protected:
    // Accessed by Meter/Selection/Stateful Tables as "meter_alu_index"
    // Accessed by Statistics (Counter) Tables as "stats_alu_index"
    void add_alu_index(json::map &stage_tbl, std::string alu_index) const;
public:
    const MatchTable *get_match_table() const override {
        return match_tables.size() == 1 ? *match_tables.begin() : 0; }
    MatchTable *get_match_table() override {
        return match_tables.size() == 1 ? *match_tables.begin() : 0; }
    std::set<MatchTable *> get_match_tables() override { return match_tables; }
    bool has_per_flow_enable() const { return per_flow_enable; }
    std::string get_per_flow_enable_param() { return per_flow_enable_param; }
    Format::Field *get_per_flow_enable_param(MatchTable *m) const override {
        return per_flow_enable ? m->lookup_field(per_flow_enable_param) : nullptr; }
    Format::Field *get_meter_address_param(MatchTable *m) const override {
        std::string pfe_name = per_flow_enable_param.substr(0, per_flow_enable_param.find("_pfe"));
        return per_flow_enable ? m->lookup_field(pfe_name + "_addr") : nullptr; }
    Format::Field *get_meter_type_param(MatchTable *m) const override {
        std::string pfe_name = per_flow_enable_param.substr(0, per_flow_enable_param.find("_pfe"));
        return per_flow_enable ? m->lookup_field(pfe_name + "_type") : nullptr; }
    bool get_per_flow_enable() { return per_flow_enable; }
    bool is_direct() const { return direct; }
    virtual int default_pfe_adjust() const { return 0; }
    std::string get_default_action() override {
        if (!default_action.empty()) return default_action;
        for (auto m : match_tables) {
            std::string def_action = m->get_default_action();
            if (!def_action.empty()) return def_action; }
        return ""; }
    default_action_params* get_default_action_parameters() override {
        if (!default_action_parameters.empty()) return &default_action_parameters;
        for (auto m : match_tables) {
            if (auto def_action_params = m->get_default_action_parameters())
                if (!def_action_params->empty()) return def_action_params; }
        return nullptr; }
    bool validate_call(Table::Call &call, MatchTable *self, size_t required_args,
                       int hash_dist_type, Table::Call &first_call) override;
    // used by Selection and Stateful tables.
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        int meter_alu_fifo_enable_from_mask, (mau_regs &, unsigned bytemask))
)

DECLARE_TABLE_TYPE(ActionTable, AttachedTable, "action",
    int                                 action_id;
    std::map<int, bitvec>               home_rows_per_word;
    int                                 home_lineno = -1;
    std::map<std::string, Format *>     action_formats;
    std::map<std::string, Actions::Action *>     pack_actions;
    static const std::map<unsigned, std::vector<std::string>> action_data_address_huffman_encoding;
    void vpn_params(int &width, int &depth, int &period, const char *&period_name) const override;
    int get_start_vpn() override;
    std::string find_field(Format::Field *field) override;
    int find_field_lineno(Format::Field *field) override;
    Format::Field *lookup_field(const std::string &name, const std::string &action) const override;
    void apply_to_field(const std::string &n, std::function<void(Format::Field *)> fn) override;
    int find_on_actionbus(const char *n, TableOutputModifier mod, int lo, int hi,
                          int size, int *len) override;
    int find_on_actionbus(const ActionBusSource &src, int lo, int hi, int size, int pos = -1) override;
    void need_on_actionbus(const ActionBusSource &src, int lo, int hi, int size) override;
    void need_on_actionbus(Table *att, TableOutputModifier mod, int lo, int hi, int size) override;
    table_type_t table_type() const override { return ACTION; }
    int unitram_type() override { return UnitRam::ACTION; }
    void pad_format_fields();
    unsigned get_do_care_count(std::string bstring);
    unsigned get_lower_huffman_encoding_bits (unsigned width);
public:
    const std::map<std::string, Format *>& get_action_formats() const { return action_formats; }
    unsigned get_size() const {
        unsigned size = 0;
        if (format) size = format->size;
        for (auto f: get_action_formats()) {
            unsigned fsize = f.second->size;
            if (fsize > size) size = fsize; }
        return size; }
    unsigned get_log2size() const {
        unsigned size = get_size();
        return ceil_log2(size); }
    unsigned determine_shiftcount(Table::Call &call, int group, unsigned word,
        int tcam_shift) const override;
    unsigned determine_default(Table::Call &call) const;
    unsigned determine_mask(Table::Call &call) const;
    unsigned determine_vpn_shiftcount(Table::Call &call) const;
    bool needs_handle() const override { return true; }
    bool needs_next() const override { return true; }
)

// Dummy value used to start gateway handles. For future use by driver,
// Incremented from inside the gateway table
static uint gateway_handle = 0x70000000;
DECLARE_TABLE_TYPE(GatewayTable, Table, "gateway",
    MatchTable                  *match_table = 0;
    uint64_t                    payload;
    int                         have_payload = -1;
    int                         match_address = -1;
    int                         gw_unit = -1;
    enum range_match_t { NONE, DC_2BIT, DC_4BIT }
                                range_match = NONE;
    std::string                 gateway_name;
    std::string                 gateway_cond;
    bool                        always_run = false;  // only for standalone
public:
    struct MatchKey {
        int                     offset;
        Phv::Ref                val;
        MatchKey(gress_t gr, int stg, value_t &v) : offset(-1), val(gr, stg, v) {}
        MatchKey(int off, gress_t gr, int stg, value_t &v) : offset(off), val(gr, stg, v) {}
        bool operator<(const MatchKey &a) const { return offset < a.offset; }
    };
private:
    std::vector<MatchKey>       match, xor_match;
    struct Match {
        int                     lineno = 0;
        uint16_t                range[6] = { 0, 0, 0, 0, 0, 0 };
        match_t                 val = { 0, 0 };
        bool                    run_table = false;
        NextTables              next;
        int                     next_map_lut = -1;
        Match() {}
        Match(value_t *v, value_t &data, range_match_t range_match);
    }                           miss, cond_true, cond_false;
    std::vector<Match>          table;
    bool                        need_next_map_lut = false;
    template<class REGS> void payload_write_regs(REGS &, int row, int type, int bus);
    template<class REGS> void standalone_write_regs(REGS &regs);
    template<class REGS> void write_next_table_regs(REGS &);
public:
    table_type_t table_type() const override { return GATEWAY; }
    const MatchTable *get_match_table() const override { return match_table; }
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
    StatefulTable *get_stateful() const override {
        return match_table ? match_table->get_stateful() : 0; }
    MeterTable *get_meter() const override {
        return match_table ? match_table->get_meter() : 0; }
    bool empty_match() const { return match.empty() && xor_match.empty(); }
    unsigned input_use() const;
    bool needs_handle() const override { return true; }
    bool needs_next() const override { return true; }
)

DECLARE_TABLE_TYPE(SelectionTable, AttachedTable, "selection",
    bool                non_linear_hash = false, /* == enable_sps_scrambling */
                        resilient_hash = false; /* false is fair hash */
    int                 mode_lineno = -1, param = -1;
    std::vector<int>    pool_sizes;
    int                 min_words = -1, max_words = -1;
    int                 selection_hash = -1;
public:
    StatefulTable*           bound_stateful = nullptr;
    table_type_t table_type() const override { return SELECTION; }
    void vpn_params(int &width, int &depth, int &period, const char *&period_name) const override {
        width = period = 1; depth = layout_size(); period_name = 0; }

    template<class REGS> void write_merge_regs(REGS &regs, MatchTable *match, int type, int bus,
                          const std::vector<Call::Arg> &args);
    template<class REGS> void setup_logical_alu_map(REGS &regs, int logical_id, int alu);
    template<class REGS> void setup_physical_alu_map(REGS &regs, int type, int bus, int alu);
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        void write_merge_regs, (mau_regs &regs, MatchTable *match, int type,
                                int bus, const std::vector<Call::Arg> &args), override {
            write_merge_regs<decltype(regs)>(regs, match, type, bus, args); })
    int address_shift() const override { return 7; }
    unsigned meter_group() const { return layout.at(0).row/4U; }
    int home_row() const override { return layout.at(0).row | 3; }
    int unitram_type() override { return UnitRam::SELECTOR; }
    StatefulTable *get_stateful() const override { return bound_stateful; }
    unsigned determine_shiftcount(Table::Call &call, int group, unsigned word,
        int tcam_shift) const override;
    void set_stateful(StatefulTable *s) override { bound_stateful = s; }
    unsigned per_flow_enable_bit(MatchTable *m = nullptr) const override;
    int indirect_shiftcount() const override;
    unsigned determine_length_shiftcount(const Table::Call &call, int group, int word) const;
    unsigned determine_length_mask(const Table::Call &call) const;
    unsigned determine_length_default(const Table::Call &call) const;
    bool validate_length_call(const Table::Call &call);
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
    table_type_t table_type() const override { return IDLETIME; }
    table_type_t set_match_table(MatchTable *m, bool indirect) override {
        match_table = m;
        if ((unsigned)m->logical_id < (unsigned)logical_id) logical_id = m->logical_id;
        return IDLETIME; }
    void vpn_params(int &width, int &depth, int &period, const char *&period_name) const override {
        width = period = 1; depth = layout_size(); period_name = 0; }
    int memunit(const int r, const int c) const override { return r*6 + c; }
    int precision_shift() const;
    int direct_shiftcount() const override;
    void pass1() override;
    void pass2() override;
    void pass3() override;
    template<class REGS> void write_merge_regs(REGS &regs, int type, int bus);
    template<class REGS> void write_regs(REGS &regs);
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        void write_regs,(mau_regs &regs), override {
            write_regs<decltype(regs)>(regs); })
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        void write_merge_regs, (mau_regs &regs, int type, int bus), override;)
    void gen_tbl_cfg(json::vector &out) const override { /* nothing at top level */ }
    void gen_stage_tbl_cfg(json::map &out) const;
    static IdletimeTable *create(int lineno, const std::string &name, gress_t gress,
                                 Stage *stage, int lid, VECTOR(pair_t) &data) {
        IdletimeTable *rv = new IdletimeTable(lineno, name.c_str(), gress, stage, lid);
        rv->setup(data);
        return rv; }
    bool needs_handle() const override { return true; }
    bool needs_next() const override { return true; }
};

DECLARE_ABSTRACT_TABLE_TYPE(Synth2Port, AttachedTable,
    void vpn_params(int &width, int &depth, int &period, const char *&period_name) const override {
        width = period = 1; depth = layout_size(); period_name = 0; }
    bool                global_binding = false;
    bool                output_used = false;
    json::map *add_stage_tbl_cfg(json::map &tbl, const char *type, int size) const override;
public:
    template<class REGS> void write_regs(REGS &regs);
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        void write_regs,(mau_regs &regs), override {
            write_regs<decltype(regs)>(regs); })
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        void write_merge_regs, (mau_regs &regs, MatchTable *match, int type, int bus,
                                const std::vector<Call::Arg> &args), override = 0)
    void common_init_setup(const VECTOR(pair_t) &, bool, P4Table::type) override;
    bool common_setup(pair_t &, const VECTOR(pair_t) &, P4Table::type) override;
    void pass1() override;
    void pass2() override;
    void pass3() override;
)

DECLARE_TABLE_TYPE(CounterTable, Synth2Port, "counter",
    enum { NONE=0, PACKETS=1, BYTES=2, BOTH=3 } type = NONE;
    table_type_t table_type() const override { return COUNTER; }
    template<class REGS> void write_merge_regs(REGS &regs, MatchTable *match, int type, int bus,
                                               const std::vector<Call::Arg> &args);
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        void write_merge_regs, (mau_regs &regs, MatchTable *match, int type,
                                int bus, const std::vector<Call::Arg> &args), override {
            write_merge_regs<decltype(regs)>(regs, match, type, bus, args); })
    struct lrt_params {   // largest recent with threshold paramters
        int     lineno;
        int64_t threshold;
        int     interval;
        lrt_params(int l, int64_t t, int i) : lineno(l), threshold(t), interval(i) {}
        lrt_params(const value_t &);
    };
    std::vector<lrt_params>     lrt;
public:
    int home_row() const override { return layout.at(0).row; }
    int direct_shiftcount() const override;
    int indirect_shiftcount() const override;
    unsigned determine_shiftcount(Table::Call &call, int group, unsigned word,
        int tcam_shift) const override;
    int address_shift() const override;
    bool run_at_eop() override { return (type&BYTES) != 0; }
    bool adr_mux_select_stats() override { return true; }
    int unitram_type() override { return UnitRam::STATISTICS; }
)

DECLARE_TABLE_TYPE(MeterTable, Synth2Port, "meter",
    int red_nodrop_value = -1;
    int red_drop_value = -1;
    int green_value = 0;
    int yellow_value = 1;
    int red_value = 3;
    int profile = 0;
    enum { NONE=0, STANDARD=1, LPF=2, RED=3 }   type = NONE;
    enum { NONE_=0, PACKETS=1, BYTES=2 }        count = NONE_;
    std::vector<Layout>                         color_maprams;
    table_type_t table_type() const override { return METER; }
    template<class REGS> void write_merge_regs(REGS &regs, MatchTable *match, int type, int bus,
                                               const std::vector<Call::Arg> &args);
    template<class REGS> void meter_color_logical_to_phys(REGS &regs, int logical_id, int alu);
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        void write_merge_regs, (mau_regs &regs, MatchTable *match, int type,
                                int bus, const std::vector<Call::Arg> &args), override {
            write_merge_regs<decltype(regs)>(regs, match, type, bus, args); })
    int                 sweep_interval = 2;
public:
    enum { IDLE_MAP_ADDR=0, STATS_MAP_ADDR=1 }  color_mapram_addr = IDLE_MAP_ADDR;
    int direct_shiftcount() const override;
    int indirect_shiftcount() const override;
    int address_shift() const override;
    bool                color_aware = false;
    bool                color_aware_per_flow_enable = false;
    bool                color_used = false;
    int                 pre_color_hash_dist_unit = -1;
    int                 pre_color_bit_lo = -1;
    bool run_at_eop() override { return type == STANDARD; }
    int unitram_type() override { return UnitRam::METER; }
    int home_row() const override { return layout.at(0).row | 3; }
    unsigned meter_group() const { return layout.at(0).row/4U; }
    bool uses_colormaprams() const override { return !color_maprams.empty(); }
    unsigned determine_shiftcount(Table::Call &call, int group, unsigned word,
            int tcam_shift) const override;
    void add_cfg_reg(json::vector &cfg_cache, std::string full_name, std::string name, unsigned val, unsigned width);
    int default_pfe_adjust() const override { return color_aware ? -METER_TYPE_BITS : 0; }
    void set_color_used() override { color_used = true; }
    void set_output_used() override { output_used = true; }
    int color_shiftcount(Table::Call &call, int group, int tcam_shift) const override;
    int color_addr_type() const override { return color_mapram_addr; }
)

namespace StatefulAlu {
struct TMatchOP;
struct TMatchInfo {
    const Table::Actions::Action        *act;
    const TMatchOP                      *op;
};
}

DECLARE_TABLE_TYPE(StatefulTable, Synth2Port, "stateful",
    table_type_t table_type() const override { return STATEFUL; }
#if HAVE_JBAY
    bool setup_jbay(const pair_t &kv);
#endif
    template<class REGS> void write_action_regs(REGS &regs, const Actions::Action *);
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        void write_action_regs,(mau_regs &regs, const Actions::Action *act), override {
            write_action_regs<decltype(regs)>(regs, act); })
    template<class REGS> void write_merge_regs(REGS &regs, MatchTable *match, int type, int bus,
                                               const std::vector<Call::Arg> &args);
    template<class REGS> void write_logging_regs(REGS &regs);
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        void write_merge_regs, (mau_regs &regs, MatchTable *match, int type,
                                int bus, const std::vector<Call::Arg> &args), override {
            write_merge_regs<decltype(regs)>(regs, match, type, bus, args); })
    std::vector<int64_t>   const_vals;
    std::vector<int>       const_vals_lineno;
    struct MathTable {
        int                     lineno = -1;
        std::vector<int>        data;
        bool                    invert = false;
        int                     shift = 0, scale = 0;
        explicit operator bool() { return lineno >= 0; }
        void check();
    }                   math_table;
    bool dual_mode = false;
    bool offset_vpn = false;
    bool address_used = false;
    int meter_adr_shift = 0;
    int stateful_counter_mode = 0;
    int watermark_level = 0;
    int watermark_pop_not_push = 0;
    unsigned initial_value_lo = 0;
    unsigned initial_value_hi = 0;
    int logvpn_lineno = -1;
    int logvpn_min = -1, logvpn_max = -1;
    int pred_shift = 0, pred_comb_shift = 0;
    int stage_alu_id = -1;
    Ref underflow_action, overflow_action;
public:
    Ref                 bound_selector;
    unsigned            phv_byte_mask = 0;
    std::vector<Ref>    sbus_learn, sbus_match;
    enum { SBUS_OR=0, SBUS_AND=1 } sbus_comb = SBUS_OR;
    int                 pred_comb_sel = -1;
    int                 phv_hash_shift = 0;
    bitvec              phv_hash_mask = bitvec(0, 128);
    Instruction         *output_lmatch = nullptr;  // output instruction using lmatch
    int instruction_set() override { return 1; /* STATEFUL_ALU */ }
    int direct_shiftcount() const override;
    int indirect_shiftcount() const override;
    int address_shift() const override;
    int unitram_type() override { return UnitRam::STATEFUL; }
    int get_const(int lineno, int64_t v);
    bool is_dual_mode() const { return dual_mode; }
    int alu_size() const { return 1 << std::min(5U, format->log2size - is_dual_mode()); }
    int home_row() const override { return layout.at(0).row | 3; }
    unsigned meter_group() const { return layout.at(0).row/4U; }
    unsigned determine_shiftcount(Table::Call &call, int group, unsigned word,
            int tcam_shift) const override;
    unsigned per_flow_enable_bit(MatchTable *m = nullptr) const override;
    void set_address_used() override { address_used = true; }
    void set_output_used() override { output_used = true; }
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        static int parse_counter_mode, (target_type, const value_t &))
    static int parse_counter_mode(const value_t &v) {
        SWITCH_FOREACH_TARGET(options.target, return parse_counter_mode(TARGET(), v););
        return 0;  // should not reach here, but avoid warning
    }
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD, void set_counter_mode, (target_type, int))
    void set_counter_mode(int mode) {
        SWITCH_FOREACH_TARGET(options.target, set_counter_mode(TARGET(), mode);); }
    FOR_ALL_REGISTER_SETS(TARGET_OVERLOAD,
        void gen_tbl_cfg, (target_type, json::map &, json::map &), const)
#if HAVE_JBAY
    Alloc1D<StatefulAlu::TMatchInfo, Target::JBay::STATEFUL_TMATCH_UNITS>       tmatch_use;
#endif
)

#endif /* _tables_h_ */
