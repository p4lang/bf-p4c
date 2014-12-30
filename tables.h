#ifndef _tables_h_
#define _tables_h_

#include "alloc.h"
#include "asm-types.h"
#include "map.h"
#include <string>
#include <vector>

class Stage;
class Instruction;

class Table {

protected:
    Table(int line, std::string &&n, gress_t gr, Stage *s, int lid = -1)
        : name_(n), stage(s), gress(gr), lineno(line), logical_id(lid), format(0),
          actions(0) {
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
    void alloc_logical_id();
    void check_next();
public:
    const char *name() { return name_.c_str(); }
    int table_id();
    virtual void pass1() = 0;
    virtual void pass2() = 0;
    virtual void write_regs() = 0;

    struct Layout {
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
        bool operator==(const Table *t) { return name == t->name_; }
        bool operator==(const char *t) { return name == t; }
        bool operator==(const std::string &t) { return name == t; }
        void check() {
            if (lineno > 0 && all.count(name) == 0)
                error(lineno, "No table named %s", name.c_str()); }
    };

    class Format {
    public:
        struct Field {
            unsigned    bit, size, group;
            bool operator==(const Field &a) const { return size == a.size; }
        };
        Format(VECTOR(pair_t) &);
    private:
        std::vector<std::map<std::string, Field>>               fmt;
        std::map<int, std::map<std::string, Field>::iterator>   byindex;
    public:
        int                                                     lineno;
        unsigned                                                size;
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
#if 0
        struct iterator {
            vector<act_t::iterator>::iterator     it;
            iterator(const act_t::iterator &i) : it(i) {}
            iterator(const iterator &) = default;
            iterator(iterator &&) = default;
            iterator &operator=(const iterator &) & = default;
            iterator &operator=(iterator &&) & = default;
            bool operator==(const iterator &a) { return it == a.it; }
            iterator &operator++() { ++it; return *this; }
            iterator &operator*() { return *this; }
            const char *name() { return it->first.c_str(); }
            int &address() { return it->second.first; }
            size_t size() { return it->second.second.size(); }
            Instruction *operator[](size_t i) {
                assert(i < it->second.second.size());
                return it->second.second[i]; }
        };
#endif
    public:
        Actions(VECTOR(pair_t) &);
        int             lineno;
        iterator begin() { return order.begin(); }
        iterator end() { return order.end(); }
    };

public:
    std::string                 name_;
    Stage                       *stage;
    gress_t                     gress;
    int                         lineno;
    int                         logical_id;
    std::vector<Layout>         layout;
    Format                      *format;
    Ref                         action;
    std::vector<std::string>    action_args;
    Actions                     *actions;
    std::vector<Ref>            hit_next;
    Ref                         miss_next;

    static std::map<std::string, Table *>       all;
};

#endif /* _tables_h_ */
