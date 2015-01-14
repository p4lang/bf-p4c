#ifndef _parser_h_
#define _parser_h_

#include "sections.h"
#include "phv.h"
#include "gen/memories.prsr_mem_main_rspec.h"
#include "gen/regs.prsr_reg_main_rspec.h"
#include "gen/regs.prsr_reg_merge_rspec.h"
#include <map>
#include <vector>
#include "bitvec.h"

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

    struct State {
        struct Ref {
            int         lineno;
            std::string name;
            State       *ptr;
            Ref() : lineno(-1), ptr(0) {}
            operator bool() { return ptr != 0; }
            State *operator->() { return ptr; }
            void check(gress_t, Parser *);
        };
        struct MatchKey {
            int     lineno;
            struct {
            short   bit, byte;
            }       data[4];
            short   ctr_zero, ctr_neg;
            short   width;
            MatchKey() : lineno(0), ctr_zero(-1), ctr_neg(-1), width(0) {
                for (auto &a : data) a.bit = a.byte = -2; }
            void setup(value_t &);
            int setup_match_el(value_t &);
        private:
            int add_byte(unsigned);
        };
        struct Match {
            int     lineno;
            match_t match;
            int     counter, offset, shift;
            bool    counter_reset, offset_reset;
            Ref     next;
            match_t next_mod;
            enum flags_t { OFFSET=1, ROTATE=2 };
            struct Save {
                int         lo, hi;
                Phv::Ref    where;
                int         flags;
                Save(gress_t, int l, int h, value_t &data, int flgs=0);
            };
            std::vector<Save>               save;
            struct Set {
                Phv::Ref	where;
                int		what;
                int         flags;
                Set(gress_t gress, value_t &data, int v, int flgs=0);
            };
            std::vector<Set>   		set;
            Match(int lineno, gress_t, match_t m, VECTOR(pair_t) &data);
            Match(int lineno, gress_t, State *n);
            void unmark_reachable(Parser *, Parser::State *state, bitvec &unreach);
        };

        std::string             name;
        gress_t                 gress;
        match_t                 stateno;
        MatchKey                key;
        std::vector<Match>      match;
        Match                   *def;
        int                     lineno;
        int                     all_idx;

        State(State &&) = default;
        State(int lineno, const char *name, gress_t, match_t stateno, const VECTOR(pair_t) &data);
        bool can_be_start();
        void unmark_reachable(Parser *, bitvec &);
        void pass1(Parser *);
        void pass2(Parser *);
        void write_config(Parser *);
    };
    friend class State;
    std::map<std::string, State>        states[2];
    std::vector<State *>                all;
    bitvec                              state_use[2];
    State                               *start_state[2];

};

#endif /* _parser_h_ */
