#ifndef _parser_h_
#define _parser_h_

#include "sections.h"
#include "phv.h"
#include "gen/memories.prsr_mem_main_rspec.h"
#include "gen/regs.prsr_reg_main_rspec.h"
#include "gen/regs.prsr_reg_merge_rspec.h"
#include <map>
#include <vector>
#include <set>
#include "bitvec.h"

enum {
    /* global constants related to parser */
    PARSER_STATE_WIDTH = 8,
    PARSER_STATE_MASK = 0xff,
    PARSER_TCAM_DEPTH = 256,
};

class Parser : public Section {
    int                         lineno[2];
    memories_all_parser_        mem[2];
    regs_all_parser_            reg[2];
    regs_all_parse_merge        reg_merge;
    Parser();
    ~Parser();
    void start(int lineno, VECTOR(value_t) args);
    void input(VECTOR(value_t) args, value_t data);
    void process();
    void output();
    static Parser singleton_object;
    struct phv_output_map;

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
            State *operator->() const { assert(ptr.size() == 1); return ptr[0]; }
            State *operator*() const { assert(ptr.size() == 1); return ptr[0]; }
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
            short   ctr_zero, ctr_neg;
            short   width;
            MatchKey() : lineno(0), ctr_zero(-1), ctr_neg(-1), width(0) {
                for (auto &a : data) a.bit = -1; }
            void setup(value_t &);
            int setup_match_el(value_t &);
        private:
            int add_byte(int);
        };
        struct Match {
            int     lineno;
            match_t match;
            int     counter, offset, shift;
            bool    counter_reset, offset_reset;
            Ref     next;
            enum flags_t { OFFSET=1, ROTATE=2 };
            struct Save {
                int         lo, hi;
                Phv::Ref    where;
                int         flags;
                Save(gress_t, int l, int h, value_t &data, int flgs=0);
                void write_output_config(phv_output_map *, unsigned &);
            };
            std::vector<Save>               save;
            struct Set {
                Phv::Ref	where;
                int		what;
                int         flags;
                Set(gress_t gress, value_t &data, int v, int flgs=0);
                void write_output_config(phv_output_map *, unsigned &);
            };
            std::vector<Set>   		set;
            Match(int lineno, gress_t, match_t m, VECTOR(pair_t) &data);
            Match(int lineno, gress_t, State *n);
            void unmark_reachable(Parser *, State *state, bitvec &unreach);
            void pass1(Parser *pa, State *state);
            void write_config(Parser *, State *, Match *);
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
        void write_lookup_config(Parser *, State *, int, const std::vector<State *> &);
        void write_config(Parser *);
    };
    friend class State;
    std::map<std::string, State>        states[2];
    std::vector<State *>                all;
    bitvec                              state_use[2];
    State::Ref                          start_state[2][4];
    int                                 tcam_row_use[2];
    Phv::Ref                            parser_error[2];
    std::vector<Phv::Ref>               multi_write;
    bitvec                              phv_use[2], phv_allow_multi_write;




    /* remapping structure for getting at the config bits for phv output
     * programming in a systematic way */
    struct phv_output_map {
        ubits<9>    *dst;
        ubits_base  *src;   /* 6 or 8 bits */
        ubits<1>    *src_type, *offset_add, *offset_rot;
    };
    void setup_phv_output_map(phv_output_map *, gress_t, int);
};

#endif /* _parser_h_ */
