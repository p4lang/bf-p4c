#ifndef _parser_h_
#define _parser_h_

#include "sections.h"
#include "phv.h"
#include <map>
#include <vector>
#include <set>
#include "alloc.h"
#include "bitvec.h"
#include "ubits.h"

enum {
    /* global constants related to parser */
    PARSER_STATE_WIDTH = 8,
    PARSER_STATE_MASK = 0xff,
    PARSER_TCAM_DEPTH = 256,
    PARSER_CHECKSUM_ROWS = 32,
    PARSER_CTRINIT_ROWS = 16,
    PARSER_INPUT_BUFFER_SIZE = 32,
    PARSER_MAX_CLOTS = 64,
    PARSER_MAX_CLOT_LENGTH = 64,
};

class Parser {
    int                                 lineno;
    template<class REGS> void write_config(REGS &, json::map &, bool legacy = true);
    static Parser singleton_object;

    struct Checksum {
        int             lineno, addr = -1, unit = -1;
        gress_t         gress;
        Phv::Ref        dest;
        int             tag = -1;
        unsigned        add = 0, mask = 0, swap = 0;
        unsigned        dst_bit_hdr_end_pos = 0;
        bool            start = false, end = false, shift = false;
        unsigned        type = 0; // 0 = verify, 1 = residual, 2 = clot
        Checksum(gress_t, pair_t);
        bool equiv(const Checksum &) const;
        void pass1(Parser *);
        void pass2(Parser *);
        template<class REGS> void write_config(REGS &, Parser *);
        template<class REGS>
        void write_output_config(REGS &, Parser *, void *, unsigned &) const;
    private:
        template <typename ROW> void write_row_config(ROW &row_regs);
    };
    struct CounterInit {
        int             lineno = -1, offset = -1;
        int             add = 0, mask = 7, rot = 0, max = 255, src = -1;
        CounterInit(value_t &data);
        bool parse(value_t &exp, int what = 0);
        template<class REGS> void write_config(REGS &, gress_t, int);
        bool equiv(const CounterInit &a) const {
            /* ignoring lineno and offset fields */
            return add == a.add && mask == a.mask && rot == a.rot && max == a.max && src == a.src; }
    };
    struct PriorityUpdate {
        int             lineno = -1, offset = -1, shift = -1, mask = -1;
        PriorityUpdate() {}
        PriorityUpdate(const value_t &data);
        bool parse(const value_t &exp, int what = 0);
        explicit operator bool() const { return lineno >= 0; }
        template<class REGS> void write_config(REGS &);
    };
 public:
    struct State {
        struct Ref {
            int                         lineno;
            std::string                 name;
            match_t                     pattern;
            std::vector<State *>        ptr;
            Ref() : lineno(-1) { pattern.word0 = pattern.word1 = 0; }
            Ref &operator=(const value_t &);
            Ref(value_t &v) { *this = v; }
            operator bool() const { return ptr.size() > 0; }
            State *operator->() const { BUG_CHECK(ptr.size() == 1); return ptr[0]; }
            State *operator*() const { BUG_CHECK(ptr.size() == 1); return ptr[0]; }
            bool operator==(const Ref &a) const { return name == a.name && pattern == a.pattern; }
            void check(gress_t, Parser *, State *);
            std::vector<State*>::const_iterator begin() const { return ptr.begin(); }
            std::vector<State*>::const_iterator end() const { return ptr.end(); }
        };
        struct MatchKey {
            int     lineno;
            struct {
                short   bit, byte;
            }       data[4];
            enum { USE_SAVED = 0x7fff }; /* magic number can be stored in 'byte' field */
            short   specified;
            short   ctr_zero, ctr_neg;
            short   width;
            MatchKey() : lineno(0), specified(0), ctr_zero(-1), ctr_neg(-1), width(0) {
                for (auto &a : data) a.bit = -1; }
            void setup(value_t &);
            int setup_match_el(int, value_t &);
            void preserve_saved(unsigned mask);
            template<class REGS> void write_config(REGS &, json::vector &);
        private:
            int add_byte(int, int, bool use_saved = false);
            int move_down(int);
        };
        struct OutputUse {
            unsigned    b8 = 0, b16 = 0, b32 = 0;
            OutputUse &operator+=(const OutputUse &a) {
                b8 += a.b8; b16 += a.b16; b32 += a.b32;
                return *this; }
        };
        struct Match {
            int         lineno;
            match_t     match;
            std::string value_set_name;
            int         value_set_size = 0;
            int         value_set_handle = -1;
            int         counter = 0, offset = 0, shift = 0, buf_req = -1;
            bool        counter_load = false, counter_reset = false, offset_reset = false;
            CounterInit *counter_exp;
            PriorityUpdate      priority;

            //int         load_offset = -1, load_unit = -1, load_add = 0, load_shift = 0,
            //            load_mask = 0xff, load_max = 0xff;
            Ref         next;
            MatchKey    future;
            enum flags_t { OFFSET=1, ROTATE=2 };
            struct Save {
                int         lo, hi;
                Phv::Ref    where, second;
                int         flags;
                Save(gress_t, int l, int h, value_t &data, int flgs=0);
                template<class REGS>
                int write_output_config(REGS &, void *, unsigned &) const;
                OutputUse output_use() const;
            };
            std::vector<Save>               save;
            struct Set {
                Phv::Ref        where;
                unsigned        what;
                int             flags;
                Set(gress_t gress, value_t &data, int v, int flgs=0);
                template<class REGS>
                void write_output_config(REGS &, void *, unsigned &) const;
                OutputUse output_use() const;
                bool merge(gress_t, const Set &a);
                bool operator==(const Set &a) const { return where == a.where && what == a.what
                    && flags == a.flags; }
            };
            std::vector<Set>            set;
            struct Clot {
                int             lineno, tag;
                std::string     name;
                bool            load_length = false;
                int             start = -1, length = -1, length_shift = -1, length_mask = -1;
                int             max_length = -1;
                int             csum_unit = -1;
                Clot(gress_t gress, const value_t &tag, const value_t &data);
                bool parse_length(const value_t &exp, int what=0);
                template<class PO_ROW> void write_config(PO_ROW &, int) const;
            };
            std::vector<Clot>           clots;
            std::vector<Checksum>       csum;
            struct FieldMapping {
                Phv::Ref        where;
                std::string     container_id;
                int             lo;
                int             hi;
                FieldMapping(Phv::Ref &ref, const value_t &a);
            };
            std::vector<FieldMapping>   field_mapping;
            Match(int lineno, gress_t, match_t m, VECTOR(pair_t) &data);
            Match(int lineno, gress_t, State *n);
            void unmark_reachable(Parser *, State *state, bitvec &unreach);
            void pass1(Parser *pa, State *state);
            void pass2(Parser *pa, State *state);
            OutputUse output_use() const;
            void merge_outputs(OutputUse);
            template<class REGS> int write_future_config(REGS &, Parser *, State *, int) const;
            template<class REGS> void write_lookup_config(REGS &, State *, int) const;
            template<class EA_REGS> void write_counter_config(EA_REGS &) const;
            template<class REGS> void write_row_config(REGS &, Parser *, State *, int,
                                                       Match *, json::map &);
            template<class REGS> void write_config(REGS &, Parser *, State *, Match *, json::map &);
            template<class REGS> void write_config(REGS &, json::vector &);
        };

        std::string             name;
        gress_t                 gress;
        match_t                 stateno;
        MatchKey                key;
        std::vector<Match>      match;
        Match                   *def;
        std::set<State *>       pred;
        int                     lineno;
        int                     all_idx;

        State(State &&) = default;
        State(int lineno, const char *name, gress_t, match_t stateno, const VECTOR(pair_t) &data);
        bool can_be_start();
        void unmark_reachable(Parser *, bitvec &);
        void pass1(Parser *);
        void pass2(Parser *);
        template<class REGS>
        int write_lookup_config(REGS &, Parser *, State *, int, const std::vector<State *> &);
        template<class REGS> void write_config(REGS &, Parser *, json::vector &);
    };
 public:
    Parser();
    ~Parser();
    void input(VECTOR(value_t) args, value_t data);
    void process();
    void output(json::map &);
    // XXX(hanw): remove after 8.7 release
    void output_legacy(json::map &);
    gress_t                             gress;
    std::map<std::string, State>        states[2];
    std::vector<State *>                all;
    bitvec                              port_use;
    int                                 parser_no;  // used to print cfg.json
    bitvec                              state_use[2];
    State::Ref                          start_state[2][4];
    int                                 priority[2][4] = {{0}};
    int                                 pri_thresh[2][4] = { {3,3,3,3}, {3,3,3,3} };
    int                                 tcam_row_use[2] = { 0 };
    Phv::Ref                            parser_error[2];
    // the ghost "parser" extracts a single 32-bit value
    // this information is first extracted in AsmParser and passed to
    // individual Parser, because currently parse_merge register is programmed
    // in Parser class.
    // One possible clean up is to reorganize the gvb
    Phv::Ref                            ghost_parser;
    std::vector<Phv::Ref>               multi_write, init_zero;
    bitvec                              phv_use[2], phv_allow_multi_write, phv_init_valid;
    int                                 hdr_len_adj[2], meta_opt;
    Alloc1D<Checksum *, PARSER_CHECKSUM_ROWS>                           checksum_use[2];
    Alloc1D<CounterInit *, PARSER_CTRINIT_ROWS>                         counter_init[2];
    static std::map<std::string, std::vector<State::Match::Clot *>>     clots[2];
    static Alloc1D<std::vector<State::Match::Clot *>, PARSER_MAX_CLOTS> clot_use[2];
    static unsigned                                                     max_handle;
    int                                                                 parser_handle = -1;

    static Parser& get_parser() { return singleton_object; }
    template<class REGS> void gen_configuration_cache(REGS &, json::vector &cfg_cache);
    static int clot_maxlen(gress_t gress, unsigned tag) {
        auto &vec = clot_use[gress][tag];
        return vec.empty() ? -1 : vec[0]->max_length; }
    static int clot_maxlen(gress_t gress, std::string tag) {
        if (clots[gress].count(tag))
            return clots[gress].at(tag)[0]->max_length;
        return -1; }
    static int clot_tag(gress_t gress, std::string tag) {
        if (clots[gress].count(tag))
            return clots[gress].at(tag)[0]->tag;
        return -1; }

    static const char* match_key_loc_name(int loc);
    static int match_key_loc(const char* key);
    static int match_key_loc(value_t& key, bool errchk = true);
    static int match_key_size(const char* key);

    // Parser Handle Setup
    // ____________________________________________________
    // | Table Type | Pipe Id | Parser Handle | PVS Handle |
    // 31          24        20              12            0
    // PVS Handle = 12 bits
    // Parser Handle = 8 bits
    // Pipe ID = 4 bits
    // Table Type = 8 bits (Parser type is 15)
    static unsigned next_handle() {
        // unique_table_offset is to support multiple pipe.
        // assume parser type is 15, table type used 0 - 6
        return max_handle++ << 12 | unique_table_offset << 20 | 15 << 24;
    }

private:
    template<class REGS> void *setup_phv_output_map(REGS &, gress_t, int);
    template<class REGS> void mark_unused_output_map(REGS &, void *, unsigned);
    void define_state(gress_t gress, pair_t &kv);
    void output_default_ports(json::vector& vec, bitvec port_use);
};

#endif /* _parser_h_ */
