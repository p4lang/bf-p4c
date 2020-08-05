#ifndef BF_ASM_PARSER_H_
#define BF_ASM_PARSER_H_

#include <map>
#include <vector>
#include <set>

#include "sections.h"
#include "phv.h"
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
    int                                 lineno = -1;
    template<class REGS> void write_config(REGS &, json::map &, bool legacy = true);

    struct Checksum {
        int             lineno = -1, addr = -1, unit = -1;
        gress_t         gress;
        Phv::Ref        dest;
        int             tag = -1;
        unsigned        add = 0, mask = 0, swap = 0, mul_2 = 0;
        unsigned        dst_bit_hdr_end_pos = 0;
        bool            start = false, end = false, shift = false;
        unsigned        type = 0;  // 0 = verify, 1 = residual, 2 = clot
        Checksum(gress_t, pair_t);
        bool equiv(const Checksum &) const;
        void pass1(Parser *);
        void pass2(Parser *);
        template<class REGS> void write_config(REGS &, Parser *);
        template<class REGS>
        void write_output_config(REGS &, Parser *, void *, unsigned &) const;
     private:
        template <typename ROW> void write_tofino_row_config(ROW &row);
        template <typename ROW> void write_row_config(ROW &row);
    };
    struct CounterInit {
        gress_t         gress;
        int             lineno = -1, addr = -1;
        int             add = 0, mask = 255, rot = 0, max = 255, src = -1;
        CounterInit(gress_t, pair_t);
        void pass1(Parser *) { }
        void pass2(Parser *);
        template<class REGS> void write_config(REGS &, gress_t, int);
        bool equiv(const CounterInit&) const;
    };
    struct PriorityUpdate {
        int             lineno = -1, offset = -1, shift = -1, mask = -1;
        PriorityUpdate() {}
        explicit PriorityUpdate(const value_t &data);
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
            explicit Ref(value_t &v) { *this = v; }
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
            short   save = 0;
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
            State*      state = nullptr;
            match_t     match;
            std::string value_set_name;
            int         value_set_size = 0;
            int         value_set_handle = -1;
            int         offset_inc = 0, shift = 0, buf_req = -1;
            bool        offset_rst = false;

            int ctr_imm_amt = 0, ctr_ld_src = 0, ctr_load = 0;
            bool ctr_stack_push = false, ctr_stack_upd_w_top = false, ctr_stack_pop = false;

            CounterInit* ctr_instr = nullptr;

            PriorityUpdate      priority;

            Ref         next;
            MatchKey    load;

            int row = -1;
            bool has_narrow_to_wide_extract = false;

            enum flags_t { OFFSET = 1, ROTATE = 2 };

            struct Save {
                Match*      match;
                int         lo, hi;
                Phv::Ref    where, second;
                int         flags;
                Save(gress_t, Match* m, int l, int h, value_t &data, int flgs = 0);
                template<class REGS>
                int write_output_config(REGS &, void *, unsigned &) const;
                OutputUse output_use() const;
            };
            std::vector<Save*>               save;

            struct Set {
                Match*          match = nullptr;
                Phv::Ref        where;
                unsigned        what;
                int             flags;
                Set(gress_t gress, Match* m, value_t &data, int v, int flgs = 0);
                template<class REGS>
                void write_output_config(REGS &, void *, unsigned &) const;
                OutputUse output_use() const;
                bool merge(gress_t, const Set &a);
                bool operator==(const Set &a) const { return where == a.where && what == a.what
                    && flags == a.flags; }
            };
            std::vector<Set*>            set;

            struct Clot {
                int             lineno, tag;
                std::string     name;
                bool            load_length = false;
                int             start = -1, length = -1, length_shift = -1, length_mask = -1;
                int             max_length = -1;
                int             csum_unit = -1;
                Clot(gress_t gress, const value_t &tag, const value_t &data);
                Clot(const Clot &) = delete;
                Clot(Clot &&) = delete;
                bool parse_length(const value_t &exp, int what = 0);
                template<class PO_ROW> void write_config(PO_ROW &, int) const;
            };
            std::vector<Clot *>         clots;
            std::vector<Checksum>       csum;

            struct FieldMapping {
                Phv::Ref        where;
                std::string     container_id;
                int             lo = -1;
                int             hi = -1;
                FieldMapping(Phv::Ref &ref, const value_t &a);
            };
            std::vector<FieldMapping>   field_mapping;

            struct HdrLenIncStop {
                int             lineno = -1;
                unsigned        final_amt = 0;
                HdrLenIncStop() { }
                explicit HdrLenIncStop(const value_t &data);
                explicit operator bool() const { return lineno >= 0; }
                template<class PO_ROW> void write_config(PO_ROW &) const;
            } hdr_len_inc_stop;

            Match(int lineno, gress_t, State *s, match_t m, VECTOR(pair_t) &data);
            Match(int lineno, gress_t, State *n);
            ~Match() { if (ctr_instr) delete ctr_instr; }
            void unmark_reachable(Parser *, State *state, bitvec &unreach);
            void pass1(Parser *pa, State *state);
            void pass2(Parser *pa, State *state);
            OutputUse output_use() const;
            void merge_outputs(OutputUse);
            template<class REGS> int write_load_config(REGS &, Parser *, State *, int) const;
            template<class REGS> void write_lookup_config(REGS &, State *, int) const;
            template<class EA_REGS> void write_counter_config(EA_REGS &) const;
            template<class REGS> void write_common_row_config(REGS &, Parser *, State *, int,
                                                              Match *, json::map &);
            template<class REGS> void write_row_config(REGS &, Parser *, State *, int,
                                                       Match *, json::map &);
            template<class REGS> void write_config(REGS &, Parser *, State *, Match *, json::map &);
            template<class REGS> void write_config(REGS &, json::vector &);

            template <class REGS> void write_saves(REGS &regs, Match* def, void *output_map,
                    int& max_off, unsigned& used);
            template <class REGS> void write_sets(REGS &regs, Match* def,
                    void *output_map, unsigned& used);

            std::set<Match*> get_all_preds();
            std::set<Match*> get_all_preds_impl(std::set<Match*>& visited);
        };

        std::string             name;
        gress_t                 gress;
        match_t                 stateno;
        MatchKey                key;
        std::vector<Match*>     match;
        Match                   *def;
        std::set<Match*>        pred;
        int                     lineno = -1;
        int                     all_idx = -1;

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
    void input(VECTOR(value_t) args, value_t data);
    void process();
    void output(json::map &);
    void output_legacy(json::map &);
    gress_t                             gress;
    std::string                         name;
    std::map<std::string, State*>       states;
    std::vector<State*>                 all;
    std::map<State::Match*, int>        match_to_row;
    bitvec                              port_use;
    int                                 parser_no;  // used to print cfg.json
    bitvec                              state_use;
    State::Ref                          start_state[4];
    int                                 priority[4] = { 0 };
    int                                 pri_thresh[4] = { 3, 3, 3, 3 };
    int                                 tcam_row_use = 0;
    Phv::Ref                            parser_error;
    // the ghost "parser" extracts a single 32-bit value
    // this information is first extracted in AsmParser and passed to
    // individual Parser, because currently parse_merge register is programmed
    // in Parser class.
    // FIXME -- should move all merge reg handling into AsmParser.
    Phv::Ref                            ghost_parser;
    bitvec                              (&phv_use)[2];
    bitvec                              phv_allow_bitwise_or, phv_allow_clear_on_write;
    bitvec                              phv_init_valid;
    int                                 hdr_len_adj = 0, meta_opt = 0;
    std::vector<Alloc1D<Checksum *, PARSER_CHECKSUM_ROWS>>              checksum_use;
    Alloc1D<CounterInit *, PARSER_CTRINIT_ROWS>                         counter_init;
    static std::map<gress_t, std::map<std::string, std::vector<State::Match::Clot *>>> clots;
    static Alloc1D<std::vector<State::Match::Clot *>, PARSER_MAX_CLOTS> clot_use;
    static unsigned                                                     max_handle;
    int                                                                 parser_handle = -1;

    Parser(bitvec (&phv_use)[2], gress_t gr, int idx)
    : gress(gr), parser_no(idx), phv_use(phv_use) {}

    template<class REGS> void gen_configuration_cache(REGS &, json::vector &cfg_cache);
    static int clot_maxlen(gress_t gress, unsigned tag) {
        auto &vec = clot_use[tag];
        return vec.empty() ? -1 : vec.at(0)->max_length; }
    static int clot_maxlen(gress_t gress, std::string tag) {
        if (clots.count(gress) && clots.at(gress).count(tag))
            return clots.at(gress).at(tag).at(0)->max_length;
        return -1; }
    static int clot_tag(gress_t gress, std::string tag) {
        if (clots.count(gress) && clots.at(gress).count(tag))
            return clots.at(gress).at(tag).at(0)->tag;
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
    // Store parser names to their handles. Used by phase0 match tables to link
    // parser handle
    static std::map<std::string, unsigned>     parser_handles;
    static const unsigned get_parser_handle(std::string phase0Table) {
        for (auto p : Parser::parser_handles) {
            auto parser_name = p.first;
            if (phase0Table.find(parser_name) != std::string::npos)
                return p.second;
        }
        return 0;
    }

    template<class REGS> void *setup_phv_output_map(REGS &, gress_t, int);

 private:
    template<class REGS> void mark_unused_output_map(REGS &, void *, unsigned);
    void define_state(gress_t gress, pair_t &kv);
    void output_default_ports(json::vector& vec, bitvec port_use);
};

#endif /* BF_ASM_PARSER_H_ */
