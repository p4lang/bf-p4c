#ifndef BF_ASM_INPUT_XBAR_H_
#define BF_ASM_INPUT_XBAR_H_

#include <fstream>

#include "constants.h"
#include "phv.h"
#include "ordered_map.h"
#include "hashexpr.h"

class Table;

struct HashCol {
    int                     lineno = -1;
    HashExpr                *fn = 0;
    int                     bit = 0;
    bitvec                  data;
    unsigned                valid = 0;  // Used only in Tofino
    void dbprint(std::ostream & out) const {
        out << "HashCol: " <<
               " lineno: " << lineno <<
               " bit: " << bit <<
               " data: " << data <<
               " valid: " << valid;
        if (fn) out << " fn: " << *fn << std::endl;
    }
};

inline std::ostream &operator<<(std::ostream &out, HashCol &col) {
    col.dbprint(out);
    return out;
}

struct DynamicIXbar {
    int                                         bit = -1;
    std::vector<std::pair<Phv::Ref, match_t>>   match_phv;
    match_t                                     match;

    DynamicIXbar() = default;
    DynamicIXbar(const DynamicIXbar &) = default;
    DynamicIXbar(DynamicIXbar &&) = default;
    DynamicIXbar &operator=(const DynamicIXbar &) = default;
    DynamicIXbar &operator=(DynamicIXbar &&) = default;
    DynamicIXbar(const Table *, const pair_t &);
};

class InputXbar {
 public:
    struct Group {
        short                                   index;
        enum type_t { INVALID, EXACT, TERNARY, BYTE, GATEWAY, XCMP }
                                                type;
        Group(Group::type_t t, int i) : index(i), type(t) {}
        explicit operator bool() const { return type != INVALID; }
        bool operator==(const Group &a) const { return type == a.type && index == a.index; }
        bool operator<(const Group &a) const {
            return (type << 16) + index < (a.type << 16) + a.index; }
    };

 protected:
    struct Input {
        Phv::Ref        what;
        int             lo, hi;
        explicit Input(const Phv::Ref &a) : what(a), lo(-1), hi(-1) {}
        Input(const Phv::Ref &a, int s) : what(a), lo(s), hi(-1) {}
        Input(const Phv::Ref &a, int l, int h) : what(a), lo(l), hi(h) {}
        unsigned size() const { return hi - lo + 1; }
    };
    struct HashGrp {
        int             lineno = -1;
        unsigned        tables = 0;  // Bit set for table index
        uint64_t        seed = 0;
        bool            seed_parity = false;  // Parity to be set on the seed value
    };
    Table       *table;
    ordered_map<Group, std::vector<Input>>              groups;
    std::map<unsigned, std::map<int, HashCol>>          hash_tables;
    // Map of hash table index to parity bit set on the table
    std::map<unsigned, unsigned>                        hash_table_parity;
    std::map<unsigned, HashGrp>                         hash_groups;
    static bool conflict(const std::vector<Input> &a, const std::vector<Input> &b);
    static bool conflict(const std::map<int, HashCol> &, const std::map<int, HashCol> &, int * = 0);
    static bool conflict(const HashGrp &a, const HashGrp &b);
    bool copy_existing_hash(int group, std::pair<const int, HashCol> &col);
    uint64_t hash_columns_used(unsigned hash);
    bool can_merge(HashGrp &a, HashGrp &b);
    void add_use(unsigned &byte_use, std::vector<Input> &a);
    virtual int group_max_index(Group::type_t t) const;
    virtual Group group_name(bool ternary, const value_t &value) const;
    virtual int group_size(Group::type_t t) const;
    const char *group_type(Group::type_t t) const;
    void parse_group(Table *t, Group gr, const value_t &value);
    void parse_hash_group(HashGrp &hash_group, const value_t &value);
    void parse_hash_table(Table *t, unsigned index, const value_t &value);
    virtual bool parse_unit(Table *t, const pair_t &kv) { return false; }
    void setup_hash(std::map<int, HashCol> &, int id, gress_t, int stage, value_t &,
                    int lineno, int lo, int hi);
    struct TcamUseCache {
       std::map<int, std::pair<const Input &, int>>     tcam_use;
       std::set<InputXbar *>                            ixbars_added;
    };
    virtual void check_input(Group group, Input &input, TcamUseCache &tcam_use);
    int tcam_input_use(int out_byte, int phv_byte, int phv_size);
    void tcam_update_use(TcamUseCache &use);
    void gen_hash_column(std::pair<const int, HashCol> &col,
        std::pair<const unsigned int, std::map<int, HashCol>> &hash);

    struct GroupSet {
        Group           group;
        const std::vector<InputXbar *> &use;
        GroupSet(const std::vector<InputXbar *> &u, Group g) : group(g), use(u) {}
        GroupSet(ordered_map<Group, std::vector<InputXbar *>> &u, Group g) : group(g), use(u[g]) {}
        void dbprint(std::ostream &) const;
        const Input *find(Phv::Slice sl) const;
        std::vector<const Input *> find_all(Phv::Slice sl) const;
    };

    InputXbar() = delete;
    InputXbar(const InputXbar &) = delete;
    void input(Table *table, bool ternary, const VECTOR(pair_t) &data);
    InputXbar(Table *table, int lineno) : table(table), lineno(lineno) {}

 public:
    const int   lineno;
    int random_seed = -1;
    static std::unique_ptr<InputXbar> create(Table *table, const value_t *key = nullptr);
    static std::unique_ptr<InputXbar> create(Table *table, bool tern, const value_t &key,
                                             const VECTOR(pair_t) &data);
    void pass1();
    virtual void pass2();
    template<class REGS> void write_regs(REGS &regs);
    template<class REGS> void write_xmu_regs(REGS &regs);
#if HAVE_FLATROCK
    virtual void write_regs_v(Target::Flatrock::mau_regs &regs) { BUG(); }
    virtual void write_xmu_regs_v(Target::Flatrock::mau_regs &regs) { BUG(); }
#endif
    template<class REGS> void write_galois_matrix(REGS &regs,
            int id, const std::map<int, HashCol> &mat);
    bool have_exact() const {
        for (auto &grp : groups) if (grp.first.type == Group::EXACT) return true;
        return false; }
    bool have_ternary() const {
        for (auto &grp : groups) if (grp.first.type != Group::EXACT) return true;
        return false; }
    int hash_group() const {
        /* used by gateways to get the associated hash group */
        if (hash_groups.size() != 1) return -1;
        return hash_groups.begin()->first; }
    bitvec hash_group_bituse(int grp = -1) const;
    std::vector<const HashCol *> hash_column(int col, int grp = -1) const;
    int match_group() {
        /* used by gateways and stateful to get the associated match group */
        if (groups.size() != 1 || groups.begin()->first.type != Group::EXACT) return -1;
        return groups.begin()->first.index; }
    bitvec bytemask();
    /* functions for tcam ixbar that take into account funny byte/word group stuff */
    unsigned tcam_width();
    int tcam_byte_group(int n);
    int tcam_word_group(int n);
    std::map<unsigned, std::map<int, HashCol>>& get_hash_tables() { return hash_tables; }
    const std::map<int, HashCol>& get_hash_table(unsigned id = 0);
    Phv::Ref get_hashtable_bit(unsigned id, unsigned bit) const {
        return get_group_bit(Group(Group::EXACT, id/2), bit + 64*(id & 0x1)); }
    Phv::Ref get_group_bit(Group grp, unsigned bit) const {
        if (groups.count(grp))
            for (auto &in : groups.at(grp))
                if (bit >= unsigned(in.lo) && bit <= unsigned(in.hi))
                    return Phv::Ref(in.what, bit-in.lo, bit-in.lo);
        return Phv::Ref(); }
    std::string get_field_name(int bit) {
        for (auto &g : groups) {
            for (auto &p : g.second) {
                if (bit <= p.hi && bit >= p.lo)
                    return p.what.name(); } }
        return ""; }
    bool is_p4_param_bit_in_hash(std::string p4_param_name, int bit) {
        for (auto &g : groups) {
            for (auto &p : g.second) {
                std::string phv_field_name = p.what.name();
                auto phv_field_lobit = remove_name_tail_range(phv_field_name);
                phv_field_lobit += p.what.fieldlobit();
                auto phv_field_hibit = phv_field_lobit + p.size() - 1;
                if (p4_param_name == phv_field_name
                    && bit <= phv_field_hibit && bit >= phv_field_lobit)
                    return true;
            }
        }
        return false;
    }
    unsigned get_seed_bit(unsigned group, unsigned bit) const {
        if (hash_groups.count(group))
            return ((hash_groups.at(group).seed >> bit) & 0x1);
        return 0; }
    HashGrp* get_hash_group(unsigned group = -1) { return ::getref(hash_groups, group); }
    HashGrp* get_hash_group_from_hash_table(int hash_table) {
        if (hash_table < 0 || hash_table >= HASH_TABLES) return nullptr;
        for (auto &hg : hash_groups) {
            if (hg.second.tables & (1U << hash_table))
                return &hg.second;
        }
        return nullptr;
    }
    bool log_hashes(std::ofstream& out) const;
    virtual unsigned exact_physical_ids() const { return -1; }

    class all_iter {
        decltype(groups)::const_iterator        outer, outer_end;
        bool                                    inner_valid;
        std::vector<Input>::const_iterator      inner;
        void mk_inner_valid() {
            if (!inner_valid) {
                if (outer == outer_end) return;
                inner = outer->second.begin(); }
            while (inner == outer->second.end()) {
                if (++outer == outer_end) return;
                inner = outer->second.begin(); }
            inner_valid = true; }
        struct iter_deref : public std::pair<Group, const Input &> {
            explicit iter_deref(const std::pair<Group, const Input &> &a)
            : std::pair<Group, const Input &>(a) {}
            iter_deref *operator->() { return this; } };

     public:
        all_iter(decltype(groups)::const_iterator o, decltype(groups)::const_iterator oend)
        : outer(o), outer_end(oend), inner_valid(false) { mk_inner_valid(); }
        bool operator==(const all_iter &a) {
            if (outer != a.outer) return false;
            if (inner_valid != a.inner_valid) return false;
            return inner_valid ? inner == a.inner : true; }
        all_iter &operator++() {
            if (inner_valid && ++inner == outer->second.end()) {
                ++outer;
                inner_valid = false;
                mk_inner_valid(); }
            return *this; }
        std::pair<Group, const Input &> operator*() {
            return std::pair<Group, const Input &>(outer->first, *inner); }
        iter_deref operator->() { return iter_deref(**this); }
    };
    all_iter begin() const { return all_iter(groups.begin(), groups.end()); }
    all_iter end() const { return all_iter(groups.end(), groups.end()); }

    const Input *find(Phv::Slice sl, Group grp, Group *found = nullptr) const;
    const Input *find_exact(Phv::Slice sl, int group) const {
        return find(sl, Group(Group::EXACT, group)); }
    virtual int find_offset(const MatchSource *, Group grp) const;
    int find_gateway_offset(const MatchSource *ms) const {
        return find_offset(ms, Group(Group::GATEWAY, 0)); }
    int find_match_offset(const MatchSource *ms) const {
        return find_offset(ms, Group(Group::EXACT, -1)); }

    std::vector<const Input *> find_all(Phv::Slice sl, Group grp) const;
    virtual std::vector<const Input *> find_hash_inputs(Phv::Slice sl, int hash_table) const;
    virtual int global_bit_position_adjust(int hash_table) const {
        return (hash_table / 2) * 128; }
    virtual bitvec global_column0_extract(int hash_table,
        const hash_column_t matrix[PARITY_GROUPS_DYN][HASH_MATRIX_WIDTH_DYN]) const {
            return bitvec(matrix[hash_table][0].column_value); }
};

inline std::ostream &operator<<(std::ostream &out, InputXbar::Group gr) {
    switch (gr.type) {
    case InputXbar::Group::EXACT: out << "exact"; break;
    case InputXbar::Group::TERNARY: out << "ternary"; break;
    case InputXbar::Group::BYTE: out << "byte"; break;
    default: out << "<type=" << static_cast<int>(gr.type) << ">"; }
    return out << " ixbar group " << gr.index; }

#endif /* BF_ASM_INPUT_XBAR_H_ */
