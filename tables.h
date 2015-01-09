#ifndef _tables_h_
#define _tables_h_

#include "alloc.h"
#include "asm-types.h"
#include "bitvec.h"
#include "map.h"
#include <string>
#include <vector>

class Stage;
class Instruction;
class InputXbar;
class MatchTable;

class Table {
protected:
    Table(int line, std::string &&n, gress_t gr, Stage *s, int lid = -1)
        : name_(n), stage(s), match(0), gress(gr), lineno(line),
          logical_id(lid), input_xbar(0), format(0), actions(0) {
            assert(all.find(name_) == all.end());
            all.emplace(name_, this); }
    virtual ~Table() { all.erase(name_); }
    virtual void setup(VECTOR(pair_t) &data) = 0;
    void setup_layout(value_t *row, value_t *col, value_t *bus);
    void setup_logical_id();
    void setup_action_table(value_t &);
    void setup_actions(value_t &);
    void alloc_rams(bool logical, Alloc2Dbase<Table *> &use, Alloc2Dbase<Table *> *bus_use);
    void alloc_busses(Alloc2Dbase<Table *> &bus_use);
    void alloc_id(const char *idname, int &id, int &next_id, int max_id,
		  bool order, Alloc1Dbase<Table *> &use);
    void check_next();
public:
    const char *name() { return name_.c_str(); }
    int table_id();
    virtual void pass1() = 0;
    virtual void pass2() = 0;
    virtual void write_regs() = 0;

    struct Layout {
        /* Holds the layout of which rams/tcams/busses are used by the table
         * These refer to rows/columns in different spaces:
         * ternary match refers to tcams (16x2)
         * exact match and ternary indirect refer to physical srams (8x12)
         * action (and others?) refer to logical srams (16x6) */
        int                     lineno;
        int                     row, bus;
        std::vector<int>        cols;
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
        Ref &operator=(const Ref &a) & { name = a.name; return *this; }
        Ref &operator=(Ref &&a) & { name = a.name; return *this; }
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
    public:
        struct Field {
            unsigned    bit, size, group;
            int         action_xbar;
            bool operator==(const Field &a) const { return size == a.size; }
        };
        Format(VECTOR(pair_t) &);
    private:
        std::vector<std::map<std::string, Field>>               fmt;
        std::map<int, std::map<std::string, Field>::iterator>   byindex;
    public:
        int                                                     lineno;
        unsigned                                                size, immed_size;
        unsigned                                                log2size; /* ceil(log2(size)) */

        int groups() const { return fmt.size(); }
        Field *field(const std::string &n, int group = 0) {
            assert(group >= 0 && (size_t)group < fmt.size());
            auto it = fmt[group].find(n);
            if (it != fmt[group].end()) return &it->second;
            return 0; }
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
        void pass1(Table *);
        void pass2(Table *);
        void write_regs(Table *);
    };
    class ActionBus {
	std::map<std::string, std::pair<std::vector<unsigned>, Table::Format::Field *>>      by_name;
	std::map<unsigned, std::pair<std::string, Table::Format::Field *>>   by_byte;
    public:
        int             lineno;
	ActionBus(Table *, VECTOR(pair_t) &);
        void write_action_regs(Table *tbl, unsigned homerow, unsigned action_slice);
    };
public:
    std::string                 name_;
    Stage                       *stage;
    MatchTable                  *match;
    gress_t                     gress;
    int                         lineno;
    int                         logical_id;
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
};

#endif /* _tables_h_ */
