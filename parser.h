#ifndef _parser_h_
#define _parser_h_

#include "sections.h"
#include "phv.h"
#include "gen/memories.prsr_mem_main_rspec.h"
#include "gen/regs.prsr_reg_main_rspec.h"
#include "gen/regs.prsr_reg_merge_rspec.h"
#include <map>
#include <vector>

class Parser : public Section {
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

public:
    struct MatchKey {
        int     lineno;
        struct {
        short   bit, byte;
        }       data[4];
        short   ctr_zero, ctr_neg;
        short   width;
        MatchKey() : lineno(0), ctr_zero(-1), ctr_neg(-1), width(0) {
            for (auto &a : data) a.bit = a.byte = -2; }
    };
    struct Match {
        int     lineno;
        match_t match;
        int     counter, offset, shift;
        bool    counter_reset, offset_rest;
        match_t next;
        struct Save {
            int         lo, hi;
            bool        offset;
            int         rotate;
            Phv::Ref    where;
            Save(gress_t, int l, int h, value_t &data);
        };
        std::vector<Save>                       save;
        std::vector<std::pair<Phv::Ref, int>>   set;
        Match(int lineno, gress_t, match_t m, VECTOR(pair_t) &data);
    };
    class State {
        std::string             name;
        gress_t                 gress;
        match_t                 stateno;
        MatchKey                key;
        std::vector<Match>      match;
        Match                   *def;
    public:
        int             lineno;
        State(State &&) = default;
        State(int lineno, const char *name, gress_t, match_t stateno, VECTOR(pair_t) &data);
    };
    std::map<std::string, State>        states[2];


};




#endif /* _parser_h_ */
