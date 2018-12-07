#include <config.h>

#include "algorithm.h"
#include "constants.h"
#include "parser.h"
#include "phv.h"
#include "range.h"
#include "stage.h"
#include "target.h"
#include "top_level.h"

#include "tofino/parser.cpp"    // tofino template specializations
#if HAVE_JBAY
#include "jbay/parser.cpp"      // jbay template specializations
#endif // HAVE_JBAY

Parser Parser::singleton_object;

Parser::Parser() : Section("parser") {
    lineno[0] = lineno[1] = 0;
    hdr_len_adj[INGRESS] = 0;
    hdr_len_adj[EGRESS] = 0;
    meta_opt = 0;
}
Parser::~Parser() {
}

void Parser::start(int lineno, VECTOR(value_t) args) {
    if (args.size == 0) {
        this->lineno[INGRESS] = this->lineno[EGRESS] = lineno;
        return; }
    if (args.size != 1 || (args[0] != "ingress" && args[0] != "egress" &&
                           (args[0] != "ghost" || options.target < JBAY)))
        error(lineno, "parser must specify ingress%s or egress",
              options.target >= JBAY ? ", ghost" : "");
    gress_t gress = args[0] == "egress" ? EGRESS : INGRESS;
    if (!this->lineno[gress]) this->lineno[gress] = lineno;
}
void Parser::input(VECTOR(value_t) args, value_t data) {
    if (args[0] == "ghost") {
        ghost_parser = Phv::Ref(GHOST, 0, data);
        return; }
    if (!CHECKTYPE(data, tMAP)) return;
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        if (args.size > 0) {
            if (args[0] == "ingress" && gress != INGRESS) continue;
            if (args[0] == "egress" && gress != EGRESS) continue;
        } else if (error_count > 0)
            break;
        for (auto &kv : MapIterChecked(data.map, true)) {
            if (kv.key == "start" && (kv.value.type == tVEC || kv.value.type == tSTR)) {
                if (kv.value.type == tVEC)
                    for (int i = 0; i < 4 && i < kv.value.vec.size; i++)
                        start_state[gress][i] = kv.value[i];
                else
                    for (int i = 0; i < 4; i++)
                        start_state[gress][i] = kv.value;
                continue; }
            if (kv.key == "priority" && (kv.value.type == tVEC || kv.value.type == tINT)) {
                if (kv.value.type == tVEC) {
                    for (int i = 0; i < 4 && i < kv.value.vec.size; i++)
                        if (CHECKTYPE(kv.value[i], tINT))
                            priority[gress][i] = kv.value[i].i;
                } else
                    for (int i = 0; i < 4; i++)
                        priority[gress][i] = kv.value.i;
                continue; }
            if (kv.key == "priority_threshold" &&
                (kv.value.type == tVEC || kv.value.type == tINT)) {
                if (kv.value.type == tVEC) {
                    for (int i = 0; i < 4 && i < kv.value.vec.size; i++)
                        if (CHECKTYPE(kv.value[i], tINT))
                            pri_thresh[gress][i] = kv.value[i].i;
                } else
                    for (int i = 0; i < 4; i++)
                        pri_thresh[gress][i] = kv.value.i;
                continue; }
            if (kv.key == "parser_error") {
                if (parser_error[gress].lineno >= 0) {
                    error(kv.key.lineno, "Multiple parser_error declarations");
                    warning(parser_error[gress].lineno, "Previous was here");
                } else
                    parser_error[gress] = Phv::Ref(gress, 0, kv.value);
                continue; }
            if (kv.key == "counter_init") {
                if (!CHECKTYPE2(kv.value, tVEC, tMAP)) continue;
                if (kv.value.type == tVEC) {
                    int i = 0;
                    for (auto &v : kv.value.vec) {
                        if (i >= PARSER_CTRINIT_ROWS) {
                            error(v.lineno, "too many counter init rows");
                            break; }
                        counter_init[gress][i++] = new CounterInit(v); }
                    continue; }
                for (auto &el : kv.value.map) {
                    if (!CHECKTYPE(el.key, tINT)) continue;
                    if (el.key.i < 0 || el.key.i >= PARSER_CTRINIT_ROWS)
                        error(el.key.lineno, "invalid counter init row");
                    else if (auto *old = counter_init[gress][el.key.i]) {
                        error(el.key.lineno, "duplicate counter init row");
                        warning(old->lineno, "previous counter init row");
                    } else
                        counter_init[gress][el.key.i] = new CounterInit(el.value); }
                continue; }
            if (kv.key == "multi_write") {
                if (kv.value.type == tVEC)
                    for (auto &el : kv.value.vec)
                        multi_write.emplace_back(gress, 0, el);
                else
                    multi_write.emplace_back(gress, 0, kv.value);
                continue; }
            if (kv.key == "init_zero") {
                if (kv.value.type == tVEC)
                    for (auto &el : kv.value.vec)
                        init_zero.emplace_back(gress, 0, el);
                else
                    init_zero.emplace_back(gress, 0, kv.value);
                continue; }
            if (kv.key == "hdr_len_adj") {
                if (CHECKTYPE(kv.value, tINT))
                    hdr_len_adj[gress] = kv.value.i;
                continue; }
            if (kv.key == "states") {
                if (CHECKTYPE(kv.value, tMAP))
                    for (auto &st : kv.value.map)
                        define_state(gress, st);
                continue; }
            if (gress == EGRESS && kv.key == "meta_opt") {
                if (CHECKTYPE(kv.value, tINT))
                    meta_opt = kv.value.i;
                continue; }
            define_state(gress, kv); }

        if (!hdr_len_adj[gress]) { 
            error(lineno[gress], "Parser header length adjust value not specified for %sgress", 
                                    gress ? "e" : "in");
        }
        // process the CLOTs immediately rather than in Parser::process() so that it
        // happens before Deparser::process()
        for (auto &vec : Values(clots[gress])) {
            State::Match::Clot *maxlen = 0;
            for (auto *cl : vec) {
                if (cl->tag >= 0)
                    clot_use[gress][cl->tag].push_back(cl);
                if (!maxlen || cl->max_length > maxlen->max_length)
                    maxlen = cl; }
            for (auto *cl : vec)
                cl->max_length = maxlen->max_length; }
        std::map<std::string, unsigned> clot_alloc;
        unsigned free_clot_tag = 0;
        while (free_clot_tag < PARSER_MAX_CLOTS && !clot_use[gress][free_clot_tag].empty())
            ++free_clot_tag;
        for (auto &vec : Values(clots[gress])) {
            for (auto *cl : vec) {
                if (cl->tag >= 0) continue;
                if (clot_alloc.count(cl->name)) {
                    cl->tag = clot_alloc.at(cl->name);
                    clot_use[gress][cl->tag].push_back(cl);
                } else if (free_clot_tag >= PARSER_MAX_CLOTS) {
                    error(cl->lineno, "Too many CLOTs (%d max)", PARSER_MAX_CLOTS);
                } else {
                    clot_alloc[cl->name] = cl->tag = free_clot_tag++;
                    clot_use[gress][cl->tag].push_back(cl);
                    while (free_clot_tag < PARSER_MAX_CLOTS &&
                           !clot_use[gress][free_clot_tag].empty())
                        ++free_clot_tag; } } }
    }
}

void Parser::define_state(gress_t gress, pair_t &kv) {
   if (!CHECKTYPE2M(kv.key, tSTR, tCMD, "state declaration")) return;
   const char *name = kv.key.s;
   match_t stateno = { 0, 0 };
   if (kv.key.type == tCMD) {
       name = kv.key[0].s;
       if (!CHECKTYPE2(kv.key[1], tINT, tMATCH)) return;
       if (kv.key[1].type == tINT) {
           if (kv.key[1].i > PARSER_STATE_MASK)
               error(kv.key.lineno, "Explicit state out of range");
           stateno.word1 = kv.key[1].i;
           stateno.word0 = (~kv.key[1].i) & PARSER_STATE_MASK;
       } else {
           stateno = kv.key[1].m;
           if ((stateno.word0 | stateno.word1) > PARSER_STATE_MASK)
               error(kv.key.lineno, "Explicit state out of range");
           stateno.word0 |= ~(stateno.word0 | stateno.word1) & PARSER_STATE_MASK; } }
   if (!CHECKTYPE(kv.value, tMAP)) return;
   auto n = states[gress].emplace(name, State(kv.key.lineno, name, gress,
                                  stateno, kv.value.map));
   if (n.second)
       all.push_back(&n.first->second);
   else {
       error(kv.key.lineno, "State %s already defined in %sgress", name,
             gress ? "e" : "in");
       warning(n.first->second.lineno, "previously defined here"); }
}

void Parser::process() {
    if (all.empty()) return;
    for (auto st : all) st->pass1(this);
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        if (states[gress].empty()) continue;
        if (start_state[gress][0].lineno < 0) {
            State *start = ::getref(states[gress], "start");
            if (!start) start = ::getref(states[gress], "START");
            if (!start) {
                error(lineno[gress], "No %sgress parser start state", gress ? "e" : "in");
                continue;
            } else for (int i = 0; i < 4; i++) {
                start_state[gress][i].name = start->name;
                start_state[gress][i].lineno = start->lineno;
                start_state[gress][i].ptr.push_back(start); }
        } else for (int i = 0; i < 4; i++)
            start_state[gress][i].check(gress, this, 0);
        for (int i = 0; i < 4 && !start_state[gress][i]; i++)
            if (!start_state[gress][i]->can_be_start()) {
                std::string name = std::string("<start") + char('0'+i) + '>';
                LOG1("Creating new " << gress << " " << name << " state");
                auto n = states[gress].emplace(name, State(lineno[gress], name.c_str(), gress,
                        match_t{ 0, 0 }, VECTOR(pair_t) { 0, 0, 0 }));
                BUG_CHECK(n.second);
                State *state = &n.first->second;
                state->def = new State::Match(lineno[gress], gress, *start_state[gress][i]);
                for (int j = 3; j >= i; j--)
                    if (start_state[gress][j] == start_state[gress][i]) {
                        start_state[gress][j].name = name;
                        start_state[gress][j].ptr[0] = state; }
                all.insert(all.begin(), state); }
        if (parser_error[gress].lineno >= 0)
            if (parser_error[gress].check())
                phv_use[gress][parser_error[gress]->reg.uid] = 1; }
    if (ghost_parser && ghost_parser.check()) {
        if (ghost_parser.size() != 32)
            error(ghost_parser.lineno, "ghost thread input must be 32 bits"); }
    if (error_count > 0) return;
    int all_index = 0;
    for (auto st : all) st->all_idx = all_index++;
    bitvec unreach(0, all_index);
    for (int i = 0; i < 4; i++) {
        if (!states[INGRESS].empty())
            start_state[INGRESS][i]->unmark_reachable(this, unreach);
        if (!states[EGRESS].empty())
            start_state[EGRESS][i]->unmark_reachable(this, unreach); }
    for (auto u : unreach)
        warning(all[u]->lineno, "%sgress state %s unreachable",
                all[u]->gress ? "E" : "In", all[u]->name.c_str());
    for (auto &reg : multi_write)
        if (reg.check()) {
            int id = reg->reg.parser_id();
            if (id >= 0)
                phv_allow_multi_write[id] = 1;
            else
                error(reg.lineno, "%s is not accessable in the parser", reg->reg.name); }
    for (auto &reg : init_zero)
        if (reg.check()) {
            int id = reg->reg.parser_id();
            if (id >= 0) {
                phv_init_valid[id] = 1;
                phv_use[reg.gress()][id] = 1;
            } else {
                error(reg.lineno, "%s is not accessable in the parser", reg->reg.name); } }
    if (phv_use[INGRESS].intersects(phv_use[EGRESS])) {
        bitvec tmp = phv_use[INGRESS];
        tmp &= phv_use[EGRESS];
        for (int reg : tmp)
            error(lineno[0], "Phv register %s(R%d) used by both ingress and egress",
                  Phv::reg(reg)->name, reg); }
    if (options.match_compiler || 1) {  /* FIXME -- need proper liveness analysis */
        Phv::setuse(INGRESS, phv_use[INGRESS]);
        Phv::setuse(EGRESS, phv_use[EGRESS]); }
}

void Parser::output(json::map & ctxt_json) {
    ctxt_json["parser"]["ingress"] = json::vector();
    ctxt_json["parser"]["egress"] = json::vector();
    if (all.empty()) return;
    for (auto st : all) st->pass2(this);
    if (error_count > 0) return;
    tcam_row_use[INGRESS] = tcam_row_use[EGRESS] = PARSER_TCAM_DEPTH;
    SWITCH_FOREACH_TARGET(options.target,
        auto *regs = new TARGET::parser_regs;
        declare_registers(regs);
        write_config(*regs, ctxt_json["parser"]);
        gen_configuration_cache(*regs, ctxt_json["configuration_cache"]);
    )
}

Parser::Checksum::Checksum(gress_t gress, pair_t data) : lineno(data.key.lineno), gress(gress) {
    if (!CHECKTYPE2(data.key, tSTR, tCMD)) return;
    if (!CHECKTYPE(data.value, tMAP)) return;
    if (data.key.vec.size == 2) {
        if ((unit = data.key[1].i) >= Target::PARSER_CHECKSUM_UNITS())
            error(lineno, "invalid parser checksum unit %d", unit);
     } else { error(data.key.lineno, "Syntax error"); }
    for (auto &kv : MapIterChecked(data.value.map, true)) {
        if (kv.key == "type") {
            if (CHECKTYPE(kv.value, tSTR)) {
                     if (kv.value == "VERIFY")   type = 0;
                else if (kv.value == "RESIDUAL") type = 1;
                else if (kv.value == "CLOT")     type = 2;
                else error(kv.value.lineno, "Unknown parser checksum type");
            }
            if (kv.value == "clot") {
                if (unit < 2 || unit > 4)
                    error(kv.value.lineno, "CLOT can only use checksum engine 2-4"); }
        } else if (kv.key == "start") {
            if (CHECKTYPE(kv.value, tINT)) start = kv.value.i;
        } else if (kv.key == "end") {
            if (CHECKTYPE(kv.value, tINT)) end = kv.value.i;
        } else if (kv.key == "addr") {
            if (CHECKTYPE(kv.value, tINT)) addr = kv.value.i;
        } else if (kv.key == "add") {
            if (CHECKTYPE(kv.value, tINT)) add = kv.value.i;
        } else if (kv.key == "dest") {
            if (kv.value.type == tCMD && kv.value == "clot" && kv.value.vec.size == 2)
                tag = kv.value[1].i;
            else dest = Phv::Ref(gress, 0, kv.value);
        } else if (kv.key == "end_pos") {
            if (CHECKTYPE(kv.value, tINT)) dst_bit_hdr_end_pos = kv.value.i;
        } else if (kv.key == "mask") {
            if (CHECKTYPE(kv.value, tVEC)) {
                for (int i = 0; i < kv.value.vec.size; i++) {
                    auto range = kv.value[i];
                    unsigned lo = 0, hi = 0;
                    if (range.type == tRANGE) {
                        lo = range.lo;
                        hi = range.hi;
                    } else if (range.type == tINT)
                        lo = hi = range.i;
                    else error(kv.value.lineno, "Syntax error, expecting range or int");

                    if (lo > hi)
                        error(kv.value.lineno, "Invalid parser checksum input");
                    if ((hi + 1) > PARSER_INPUT_BUFFER_SIZE)
                        error(kv.value.lineno, "Parser checksum out of input buffer?");

                    for (unsigned byte = lo; byte <= hi; ++byte)
                       mask |= (1 << byte);
                }
            }
        } else if (kv.key == "shift") {
            shift = get_bool(kv.value);
        } else if (kv.key == "swap") {
            if (CHECKTYPE(kv.value, tINT)) swap = kv.value.i;
        } else {
             warning(kv.key.lineno, "ignoring unknown item %s in checksum", value_desc(kv.key)); } }
}

bool Parser::Checksum::equiv(const Checksum &a) const {
    if (unit != a.unit) return false;
    if (dest && a.dest) {
        if (dest != a.dest) return false;
    } else if (dest || a.dest) return false;
    return add == a.add && mask == a.mask && swap == a.swap && start == a.start &&
           end == a.end && shift == a.shift && type == a.type;
}

void Parser::Checksum::pass1(Parser *parser) {
    if (addr >= 0) {
        if (addr >= PARSER_CHECKSUM_ROWS)
            error(lineno, "invalid %sgress parser checksum address %d", gress ? "e" : "in", addr);
        else if (parser->checksum_use[gress][addr]) {
            if (!equiv(*parser->checksum_use[gress][addr])) {
                error(lineno, "incompatible %sgress parser checksum use at address %d",
                      gress ? "e" : "in", addr);
                warning(parser->checksum_use[gress][addr]->lineno, "previous use"); }
        } else
            parser->checksum_use[gress][addr] = this; }
    if (dest.check() && dest->reg.parser_id() < 0)
        error(dest.lineno, "%s is not accessable in the parser", dest->reg.name);
    if (dest && dest->reg.size == 32)
        error(dest.lineno, "checksum unit cannot write to 32-bit container");
    if (type == 0 && dest) {
        if (dest->lo != dest->hi)
            error(dest.lineno, "checksum verification destination must be single bit");
        else dst_bit_hdr_end_pos = dest->lo;
#if HAVE_JBAY
        if (options.target == JBAY && dest->reg.size == 8 && dest->reg.deparser_id() % 2)
            dst_bit_hdr_end_pos += 8;
#endif // HAVE_JBAY
    } else if (type == 1 && dest && dest.size() != dest->reg.size) {
        error(dest.lineno, "residual checksum must write whole container"); }
}
void Parser::Checksum::pass2(Parser *parser) {
    if (addr < 0) {
        int avail = -1;
        for (int i = 0; i < PARSER_CHECKSUM_ROWS; ++i) {
            if (parser->checksum_use[gress][i]) {
                if (equiv(*parser->checksum_use[gress][i])) {
                    addr = i;
                    break; }
            } else if (avail < 0)
                avail = i; }
        if (addr < 0) {
            if (avail >= 0)
                parser->checksum_use[gress][addr = avail] = this;
            else
                error(lineno, "Ran out of room in %sgress parser checksum", gress ? "e" : "in"); } }
}

template<class ROW>
void Parser::Checksum::write_row_config(ROW &row) {
    row.add = add;
    if (dest) row.dst = dest->reg.parser_id();
    else if (tag >= 0) row.dst = tag;
    row.dst_bit_hdr_end_pos = dst_bit_hdr_end_pos;
    row.hdr_end = end;
    int rsh = 0;
    for (auto &el : row.mask)
         el = (mask >> rsh++) & 1;
    row.shr = shift;
    row.start = start;
    rsh = 0;
    for (auto &el : row.swap)
         el = (swap >> rsh++) & 1;
    row.type = type;
}

Parser::CounterInit::CounterInit(value_t &data) : lineno(data.lineno) {
    if (data.type != tMAP) {
        if (!parse(data))
            error(lineno, "synatx error in parser counter expression");
    } else {
        for (auto &kv : MapIterChecked(data.map)) {
            if (kv.key == "add") {
                if (CHECKTYPE(kv.value, tINT))
                    if ((add = kv.value.i) < 0 || add > 255 )
                        error(kv.value.lineno, "counter add value out of range");
            } else if (kv.key == "max") {
                if (CHECKTYPE(kv.value, tINT))
                    if ((max = kv.value.i) < 0 || max > 255)
                        error(kv.value.lineno, "counter max value out of range");
            } else if (kv.key == "mask") {
                if (CHECKTYPE(kv.value, tINT)) {
                    if (kv.value.i <= 0 || (kv.value.i & (kv.value.i + 1)))
                        error(kv.value.lineno, "counter mask must be one less than a power of 2");
                    else if ((max = bitcount(kv.value.i) - 1) > 7)
                        error(kv.value.lineno, "counter mask value out of range"); }
            } else if (kv.key == "src" || kv.key == "source") {
                if (kv.value.type == tINT && kv.value.i >= 0 && kv.value.i < 4) src = kv.value.i;
                else if (kv.value == "half" && kv.value.type == tCMD && kv.value.vec.size == 2) {
                    if (kv.value[1] == "lo") src = 0;
                    else if (kv.value[1] == "hi") src = 1;
                    else error(kv.value.lineno, "unknown counter source");
                } else if (kv.value == "half_lo") src = 0;
                else if (kv.value == "half_hi") src = 1;
                else if (kv.value == "byte0") src = 2;
                else if (kv.value == "byte1") src = 3;
                else error(kv.value.lineno, "unknown counter source");
            } else if (kv.key == "rot" || kv.key == "rotate") {
                if (CHECKTYPE(kv.value, tINT))
                    if ((rot = kv.value.i) < 0 || rot > 7)
                        error(kv.value.lineno, "counter rotate value out of range");
            } else {
                error(kv.key.lineno, "Unknown field %s in counter", kv.key.s); } } }
}

bool Parser::CounterInit::parse(value_t &exp, int what) {
    enum { START, OFFSET, RSHIFT, LSHIFT, MASK, ADD };
    if (exp.type == tCMD) {
        if (what == START) {
            for (int i = exp[0] == "load"; i < exp.vec.size; i++) {
                if (exp[i] == "max") {
                    if (++i >= exp.vec.size || exp[i].type != tINT)
                        return false;
                    max = exp[2].i;
                } else if (exp[i] == "half_lo") {
                    if (src >= 0 || offset >= 0) return false;
                    src = 1;
                } else if (exp[i] == "half_hi") {
                    if (src >= 0 || offset >= 0) return false;
                    src = 1;
                } else if (exp[i] == "byte0") {
                    if (src >= 0 || offset >= 0) return false;
                    src = 2;
                } else if (exp[i] == "byte1") {
                    if (src >= 0 || offset >= 0) return false;
                    src = 3;
                } else if (exp[i] == "half") {
                    if (src >= 0 || offset >= 0 || ++i >= exp.vec.size) return false;
                    if (exp[i] == "lo") src = 0;
                    if (exp[i] == "hi") src = 1;
                    else return false;
                } else {
                    if (!parse(exp[i], OFFSET))
                        return false; } }
            return true; }
        if (what == OFFSET && exp[0] == ">>") {
            if (exp.vec.size != 3) return false;
            return parse(exp[1], what) && parse(exp[2], RSHIFT); }
        if (what == OFFSET && exp[0] == "<<") {
            if (exp.vec.size != 3) return false;
            return parse(exp[1], what) && parse(exp[2], LSHIFT); }
        if (what == OFFSET && exp[0] == "&") {
            if (exp.vec.size != 3) return false;
            return parse(exp[1], what) && parse(exp[2], MASK); }
        if (what == OFFSET && exp[0] == "+") {
            if (exp.vec.size != 3) return false;
            return parse(exp[1], what) && parse(exp[2], ADD); }
    } else if (exp.type == tINT) {
        switch (what) {
        case OFFSET:
            if (offset >= 0 || src >= 0) return false;
            offset = exp.i;
            return true;
        case RSHIFT:
            if (rot) return false;
            rot = exp.i & 7;
            return true;
        case LSHIFT:
            if (rot) return false;
            rot = -exp.i & 7;
            return true;
        case MASK:
            if (mask != 7) return false;
            mask = bitcount(exp.i) - 1;
            if ((exp.i & (exp.i + 1)) || mask < 0 || mask > 7) {
                error(lineno, "mask must one less than a power of 2");
                return false; }
            return true;
        case ADD:
            if (add) return false;
            add = exp.i;
            return true;
        default: return false; } }
    return false;
}

Parser::PriorityUpdate::PriorityUpdate(const value_t &exp) {
    lineno = exp.lineno;
    if (!parse(exp))
        error(lineno, "syntax error in priority expression");
}

bool Parser::PriorityUpdate::parse(const value_t &exp, int what) {
    enum { START, MASK, SHIFT, LOAD };
    if (exp.type == tCMD) {
        if (exp[0] == ">>") {
            return what < SHIFT && parse(exp[1], LOAD) && parse(exp[2], SHIFT);
        } else if (exp[0] == "&") {
            return what < SHIFT && parse(exp[1], MASK) && parse(exp[2], MASK);
        }
    } else if (exp.type == tINT) {
        switch (what) {
        case START: case MASK:
            if (mask >= 0) return false;
            if ((mask = exp.i) < 0 || mask > 7) {
                error(exp.lineno, "priority mask %d out of range", mask);
                return false; }
            return true;
        case SHIFT:
            if (shift >= 0) return false;
            if ((shift = exp.i) < 0 || shift > 15) {
                error(exp.lineno, "priority shift %d out of range", shift);
                return false; }
            return true;
        default:
            return false; }
    } else if (exp.type == tSTR && exp.s[0] == '@' && isdigit(exp.s[1])) {
        char *end;
        if (what == SHIFT || offset >= 0 || (offset = strtol(exp.s+1, &end, 10)) < 0 || *end)
            return false;
        return true; }
    return false;
}

Parser::State::Ref &Parser::State::Ref::operator=(const value_t &v) {
    lineno = v.lineno;
    ptr.clear();
    if (v.type == tSTR) {
        name = v.s;
        pattern.word0 = pattern.word1 = 0;
    } else if (CHECKTYPE2M(v, tINT, tMATCH, "state reference")) {
        name.clear();
        if (v.type == tINT) {
            pattern.word0 = ~v.i;
            pattern.word1 = v.i;
        } else
            pattern = v.m;
        if ((pattern.word0 | pattern.word1) > PARSER_STATE_MASK) {
            error(lineno, "Parser state out of range");
            pattern.word0 &= PARSER_STATE_MASK;
            pattern.word1 &= PARSER_STATE_MASK;
        } else
            pattern.word1 |= ~(pattern.word0 | pattern.word1) & PARSER_STATE_MASK; }
    return *this;
}

void Parser::State::Ref::check(gress_t gress, Parser *pa, State *state) {
    if (ptr.empty()) {
        if (name.size()) {
            auto it = pa->states[gress].find(name);
            if (it != pa->states[gress].end())
                ptr.push_back(&it->second);
            else if (name != "END" && name != "end")
                error(lineno, "No state named %s in %sgress parser",
                      name.c_str(), gress ? "e" : "in");
        } else if (pattern) {
            match_t tmp = pattern;
            unsigned wc = tmp.word0 & tmp.word1;
            if (wc && !state->stateno) {
                warning(lineno, "Using next state pattern in state without an explicit "
                        "state number");
                wc = 0; }
            tmp.word0 &= ~wc | state->stateno.word0;
            tmp.word1 &= ~wc | state->stateno.word1;
            for (auto *st : pa->all) {
                if (st->gress != state->gress) continue;
                if (st == state) continue;
                if (tmp.matches(st->stateno))
                    ptr.push_back(st); } } }
}

const char* Parser::match_key_loc_name(int loc) {
    if (options.target == TOFINO) {
        if (loc == 0 || loc == 1) return "half";
        if (loc == 2) return "byte0";
        if (loc == 3) return "byte1";
#if HAVE_JBAY
    } else if (options.target == JBAY) {
        if (loc == 0) return "byte0";
        if (loc == 1) return "byte1";
        if (loc == 2) return "byte2";
        if (loc == 3) return "byte3";
#endif // HAVE_JBAY
    }

    error(-1, "Invalid match key loc");
    return nullptr;
}

int Parser::match_key_loc(value_t &key, bool errchk) {
    if (errchk && !CHECKTYPE(key, tSTR)) return -1;
    int loc = Parser::match_key_loc(key.s);
    if (loc < 0)
        error(key.lineno, "Invalid matcher location %s", key.s);
    return loc;
}

int Parser::match_key_loc(const char* key) {
    if (options.target == TOFINO) {
        if (!strcmp(key, "half") || !strcmp(key, "half0")) return 0;
        if (!strcmp(key, "byte0")) return 2;
        if (!strcmp(key, "byte1")) return 3;
#if HAVE_JBAY
    } else if (options.target == JBAY) {
        if (!strcmp(key, "byte0")) return 2;
        if (!strcmp(key, "byte1")) return 3;
        if (!strcmp(key, "byte2")) return 0;
        if (!strcmp(key, "byte3")) return 1;
#endif // HAVE_JBAY
    }

    error(-1, "Invalid match key %s", key);
    return -1;
}

int Parser::match_key_size(const char* key) {
    if (!strncmp(key, "half", 4)) return 16;
    if (!strncmp(key, "byte", 4)) return 8;

    error(-1, "Invalid match key %s", key);
    return -1;
}

int Parser::State::MatchKey::move_down(int loc) {
    int to = loc;
    while (to >= 0 && ((specified >> to) & 1)) to--;
    if (to < 0) return -1;
    if (data[to].bit >= 0 && move_down(to) < 0)
        return -1;
    data[to] = data[loc];
    data[loc].bit = -1;
    return 0;
}

int Parser::State::MatchKey::add_byte(int loc, int byte, bool use_saved) {
    if (byte <= -64 || byte >= 32) {
        error(lineno, "Match key index out of range");
        return -1; }
    if (loc >= 0) {
        if ((specified >> loc) & 1)
            error(lineno, "Multiple matches in %s matcher", Parser::match_key_loc_name(loc));
        specified |= (1 << loc);
        if (data[loc].bit >= 0 && move_down(loc) < 0)
            return -1;
    } else {
        for (int i = 3; i >= 0; i--)
            if (data[i].bit < 0) {
                loc = i;
                break; }
        if (loc < 0) {
            error(lineno, "Too much data for parse matcher");
            return -1; } }
    data[loc].bit = width;
    data[loc].byte = use_saved ? USE_SAVED : byte;
    width += 8;
    return 0;
}

int Parser::State::MatchKey::setup_match_el(int at, value_t &spec) {
    switch (spec.type) {
    case tINT:
        return add_byte(at, spec.i);
    case tRANGE:
        if (spec.lo >= spec.hi) {
            error(spec.lineno, "Invalid match range");
            return -1; }
        if (at >= 0) at += spec.hi - spec.lo;
        for (int i = spec.hi; i >= spec.lo; i--) {
            if (add_byte(at, i) < 0)
                return -1;
            if (at >= 0) at--; }
        return 0;
    case tMAP:
        if (at >= 0) goto error;
        for (int i = spec.map.size-1; i >= 0; i--)
            if (setup_match_el(Parser::match_key_loc(spec.map[i].key), spec.map[i].value) < 0)
                return -1;
        return 0;
    case tSTR:
        if (spec == "ctr_zero") {
            if (ctr_zero >= 0) {
                error(spec.lineno, "'ctr_zero' specified twice");
                return -1; }
            ctr_zero = width++;
            return 0;
        } else if (spec == "ctr_neg") {
            if (ctr_neg >= 0) {
                error(spec.lineno, "'ctr_neg' specified twice");
                return -1; }
            ctr_neg = width++;
            return 0;
        } else if (at < 0 && (at = Parser::match_key_loc(spec, false)) >= 0) {
            if (options.target == TOFINO && at == 0 && add_byte(1, 0, true) < 0) return -1;
            return add_byte(at, 0, true); }
        /* fall through */
    default:
    error:
        error(spec.lineno, "Syntax error in match spec");
        return -1; }
}

void Parser::State::MatchKey::setup(value_t &spec) {
    lineno = spec.lineno;
    if (spec.type == tVEC) {
        /* allocate the keys bits for the least significant match bits first... */
        for (int i = spec.vec.size-1; i >= 0; i--)
            if (setup_match_el(-1, spec[i]) < 0)
                return;
    } else
        setup_match_el(-1, spec);
    if (data[0].bit >= 0 && data[1].bit >= 0 && data[1].byte != data[0].byte + 1 &&
        (data[0].byte & data[1].byte) != USE_SAVED)
    {
        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {
                if (data[i].byte+1 == data[j].byte) {
                    auto hi = data[i];
                    auto lo = data[j];
                    data[i] = data[0];
                    data[j] = data[1];
                    data[0] = hi;
                    data[1] = lo;
                    return; } } }
        error(spec.lineno, "Must have a 16-bit pair in match bytes"); }
    if (data[0].bit < 0 && data[1].bit >= 0) {
        /* if we're using half of the 16-bit match, use the upper (first) half */
        auto t = data[0];
        data[0] = data[1];
        data[1] = t; }
}

Parser::State::Match::Match(int l, gress_t gress, match_t m, VECTOR(pair_t) &data) :
    lineno(l), match(m)
{
    for (auto &kv : data) {
        if (kv.key == "counter") {
            if (counter || counter_reset)
                error(kv.key.lineno, "Multiple counter settings in match");
            if (!CHECKTYPE2M(kv.value, tINT, tCMD, "set, inc or dec value"))
                continue;
            if (kv.value.type == tINT) {
                counter = kv.value.i;
                counter_reset = true;
            } else if (kv.value[0] == "load") {
                counter_load = true;
                if (kv.value.vec.size == 3 && kv.value[1] == "@" && kv.value[2].type == tINT)
                    counter = kv.value[2].i;
                else
                    counter_exp = new CounterInit(kv.value);
            } else if (CHECKTYPEM(kv.value[1], tINT, "set, inc or dec value")) {
                counter = kv.value.i;
                counter_reset = false;
                if (kv.value[0] == "dec" || kv.value[0] == "decrement")
                    counter = -counter;
                else if (kv.value[0] == "set")
                    counter_reset = true;
                else if (kv.value[0] != "inc" && kv.value[0] != "increment")
                    error(kv.value.lineno, "Syntax error, expecting set, inc or dec value"); }
        } else if (kv.key == "offset") {
            if (offset || offset_reset)
                error(kv.key.lineno, "Multiple offset settings in match");
            if (!CHECKTYPE2M(kv.value, tINT, tCMD, "set or inc value"))
                continue;
            if (kv.value.type == tINT) {
                offset = kv.value.i;
                offset_reset = true;
            } else if (CHECKTYPEM(kv.value[1], tINT, "set or inc value")) {
                offset = kv.value.i;
                offset_reset = false;
                if (kv.value[0] == "set")
                    offset_reset = true;
                else if (kv.value[0] != "inc" && kv.value[0] != "increment")
                    error(kv.value.lineno, "Syntax error, expecting set or inc value"); }
        } else if (kv.key == "priority") {
            if (priority)
                error(kv.key.lineno, "Mulitple priority updates in match");
            else
                priority = PriorityUpdate(kv.value);
        } else if (kv.key == "shift") {
            if (shift)
                error(kv.key.lineno, "Multiple shift settings in match");
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if ((shift = kv.value.i) < 0 || shift > PARSER_INPUT_BUFFER_SIZE)
                error(kv.value.lineno, "shift value %d out of range", shift);
        } else if (kv.key == "buf_req") {
            if (buf_req >= 0)
                error(kv.key.lineno, "Multiple buf_req settings in match");
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if ((buf_req = kv.value.i) < 0 || shift > PARSER_INPUT_BUFFER_SIZE)
                error(kv.value.lineno, "buf_req value %d out of range", shift);
        } else if (kv.key == "next") {
            if (next.lineno >= 0) {
                error(kv.key.lineno, "Multiple next settings in match");
                error(next.lineno, "previously set here"); }
            next = kv.value;
        } else if (kv.key == "save") {
            if (future.lineno) {
                error(kv.value.lineno, "Multiple save entries in match");
                error(future.lineno, "previous specified here");
            } else
                future.setup(kv.value);
        } else if (kv.key == "checksum") {
            csum.emplace_back(gress, kv);
        } else if (kv.key == "field_mapping") {
            if (CHECKTYPE(kv.value, tMAP)) {
                for (auto map : kv.value.map) {
                    auto ref = Phv::Ref(gress, 0, map.key);
                    auto fm = FieldMapping(ref, map.value);
                    field_mapping.emplace_back(fm);
                }
            }
        } else if (kv.key.type == tCMD && kv.key == "clot" && kv.key.vec.size == 2) {
            clots.emplace_back(singleton_object, gress, kv.key.vec[1], kv.value);
        } else if (kv.key.type == tINT) {
            save.emplace_back(gress, kv.key.i, kv.key.i, kv.value);
        } else if (kv.key.type == tRANGE) {
            save.emplace_back(gress, kv.key.lo, kv.key.hi, kv.value);
        } else if (kv.value.type == tINT) {
            set.emplace_back(gress, kv.key, kv.value.i);
        } else if (kv.value.type == tCMD && kv.value[0] == "rotate") {
            if (CHECKTYPE(kv.value[1], tINT))
                set.emplace_back(gress, kv.key, kv.value[1].i, ROTATE);
        } else {
            error(kv.key.lineno, "Syntax error");
        }
    }
}

Parser::State::Match::Match(int l, gress_t gress, State *n) : lineno(l)
{
    /* build a default match for a synthetic start state */
    counter = offset = shift = 0;
    counter_reset = offset_reset = true;
    next.name = n->name;
    next.ptr.push_back(n);
}

static value_t &extract_save_phv(value_t &data) {
    if (data.type == tVEC)
        return data[0];
    if (data.type == tCMD && (data[0] == "offset" || data[0] == "rotate"))
        return data[1];
    return data;
}

Parser::State::Match::Save::Save(gress_t gress, int l, int h, value_t &data, int flgs) :
    lo(l), hi(h), where(gress, 0, extract_save_phv(data)), flags(flgs)
{
    if (hi < lo || hi-lo > 3 || hi-lo == 2)
        error(data.lineno, "Invalid parser extraction size");
    if (data.type == tVEC) {
        if (data.vec.size > 2 || data.vec.size < 1)
            error(data.lineno, "Can only extract into single or pair");
        if (data.vec.size == 2)
            second = Phv::Ref(gress, 0, data[1]); }
    if (data.type == tCMD) {
        if (data[0] == "offset")
            flags |= OFFSET;
        else if (data[0] == "rotate")
            flags |= ROTATE; }
}

Parser::State::Match::Set::Set(gress_t gress, value_t &data, int v, int flgs) :
    where(gress, 0, extract_save_phv(data)), what(v), flags(flgs)
{
    if (data.type == tCMD) {
        if (data[0] == "offset")
            flags |= OFFSET;
        else if (data[0] == "rotate")
            flags |= ROTATE; }
}

bool Parser::State::Match::Clot::parse_length(const value_t &exp, int what) {
    enum { START, MASK, SHIFT, LOAD };
    if (exp.type == tCMD) {
        if (exp[0] == ">>") {
            return what < SHIFT && parse_length(exp[1], LOAD) && parse_length(exp[2], SHIFT);
        } else if (exp[0] == "&") {
            return what < SHIFT && parse_length(exp[1], MASK) && parse_length(exp[2], MASK);
        }
    } else if (exp.type == tINT) {
        switch (what) {
        case START: case MASK:
            if (length_mask >= 0) return false;
            if ((length_mask = exp.i) < 0 || length_mask > 0x3f) {
                error(exp.lineno, "length mask %d out of range", length_mask);
                return false; }
            return true;
        case SHIFT:
            if (length_shift >= 0) return false;
            if ((length_shift = exp.i) < 0 || length_shift > 15) {
                error(exp.lineno, "length shift %d out of range", length_shift);
                return false; }
            return true;
        default:
            return false; }
    } else if (exp.type == tSTR && exp.s[0] == '@' && isdigit(exp.s[1])) {
        char *end;
        if (what == SHIFT || length >= 0 || (length = strtol(exp.s+1, &end, 10)) < 0 || *end)
            return false;
        load_length = true;
        return true; }
    return false;
}

Parser::State::Match::Clot::Clot(Parser &prsr, gress_t gress, const value_t &tag,
                                 const value_t &data) : lineno(tag.lineno) {
    if (CHECKTYPE2(tag, tINT, tSTR)) {
        if (tag.type == tINT) {
            this->tag = tag.i;
            name = std::to_string(tag.i);
        } else {
            this->tag = -1;
            name = tag.s; } }
    prsr.clots[gress][name].push_back(this);
    if (!CHECKTYPE3(data, tINT, tRANGE, tMAP)) return;
    if (data.type == tINT) {
       start = data.i;
       length = 1;
    } else if (data.type == tRANGE) {
        start = data.lo;
        length = data.hi - data.lo + 1;
    } else for (auto &kv : data.map) {
        if (kv.key == "start") {
            if (CHECKTYPE(kv.value, tINT))
                start = kv.value.i;
        } else if (kv.key == "length") {
            if (kv.value.type == tINT) {
                length = kv.value.i;
            } else if (!parse_length(kv.value) || !load_length)
                error(kv.value.lineno, "Syntax error");
            if (length_mask < 0) length_mask = 0x3f;
            if (length_shift < 0) length_shift = 0;
        } else if (kv.key == "max_length") {
            if (CHECKTYPE(kv.value, tINT))
                max_length = kv.value.i;
        } else if (kv.key == "checksum") {
            if (CHECKTYPE(kv.value, tINT))
                csum_unit = kv.value.i;
        } else
            error(kv.key.lineno, "Unknown CLOT key %s", value_desc(kv.key)); }
    if (start < 0)
        error(data.lineno, "No start in clot %s", name.c_str());
    if (length < 0)
        error(data.lineno, "No length in clot %s", name.c_str());
    if (max_length < 0) {
        if (load_length)
            max_length = 64;
        else
            max_length = length;
    } else if (!load_length && max_length != length) {
        error(data.lineno, "Inconsistent constant length and max_length in clot"); }
}

Parser::State::Match::FieldMapping::FieldMapping(Phv::Ref &ref, const value_t &a) {
    if (CHECKTYPE(a, tCMD)) {
        where = ref;
        container_id = a.vec[0].s;
        lo = a.vec[1].lo;
        hi = a.vec[1].hi;
    } else {
        error(a.lineno, "Syntax error");
    }
}

Parser::State::State(int l, const char *n, gress_t gr, match_t sno, const VECTOR(pair_t) &data) :
    name(n), gress(gr), stateno(sno), def(0), lineno(l)
{
    VECTOR(pair_t) default_data = EMPTY_VECTOR_INIT;
    bool have_default = data["default"] != 0;
    for (auto &kv : data) {
        if (kv.key.type == tINT && kv.value.type == tMAP) {
            match_t m = { ~(unsigned)kv.key.i, (unsigned)kv.key.i };
            match.emplace_back(kv.key.lineno, gress, m, kv.value.map);
        } else if (kv.key.type == tBIGINT && kv.value.type == tMAP) {
            match_t m = { ~(unsigned)kv.key.bigi.data[0], (unsigned)kv.key.bigi.data[0] };
            match.emplace_back(kv.key.lineno, gress, m, kv.value.map);
        } else if (kv.key == "value_set" && kv.value.type == tMAP) {
            match_t m = { 0, 0 };
            match.emplace_back(kv.key.lineno, gress, m, kv.value.map);
            if (kv.key.type == tCMD) {
                if (CHECKTYPE(kv.key[1], tSTR))
                    match.back().value_set_name = kv.key[1].s;
                if (kv.key.vec.size > 2 && CHECKTYPE(kv.key[2], tINT))
                    match.back().value_set_size = kv.key[2].i;
                else
                    match.back().value_set_size = 1;
            } else
                match.back().value_set_size = 1;
        } else if (kv.key.type == tMATCH) {
            if (!CHECKTYPE(kv.value, tMAP)) continue;
            match.emplace_back(kv.key.lineno, gress, kv.key.m, kv.value.map);
        } else if (kv.key == "match") {
            if (key.lineno) {
                error(kv.value.lineno, "Multiple match entries in state %s", n);
                error(key.lineno, "previous specified here");
            } else
                key.setup(kv.value);
        } else if (kv.key == "default") {
            if (!CHECKTYPE(kv.value, tMAP)) continue;
            if (def) {
                error(kv.key.lineno, "Multiple defaults in state %s", n);
                error(def->lineno, "previous specified here");
            } else {
                match_t m = { 0, 0 };
                def = new Match(kv.key.lineno, gress, m, kv.value.map); }
        } else if (!have_default) {
            VECTOR_add(default_data, kv);
        } else
            error(kv.key.lineno, "Syntax error");
    }
    if (default_data.size) {
        BUG_CHECK(!def);
        match_t m = { 0, 0 };
        def = new Match(default_data[0].key.lineno, gress, m, default_data); }
    VECTOR_fini(default_data);
}

bool Parser::State::can_be_start() {
    if (match.size()) return false;
    if (!def) return true;
    //if (def->counter || def->offset || def->shift) return false;
    //if (def->counter_reset || def->offset_reset) return false;
    //if (def->save.size() || def->set.size()) return false;
    return true;
}

void Parser::State::unmark_reachable(Parser *pa, bitvec &unreach) {
    if (!unreach[all_idx]) return;
    unreach[all_idx] = 0;
    for (auto &m : match) m.unmark_reachable(pa, this, unreach);
    if (def) def->unmark_reachable(pa, this, unreach);
}

void Parser::State::Match::unmark_reachable(Parser *pa, Parser::State *state, bitvec &unreach) {
    for (auto succ : next) succ->unmark_reachable(pa, unreach);
}

/********* pass 1 *********/

void Parser::State::Match::pass1(Parser *pa, State *state) {
    next.check(state->gress, pa, state);
    for (auto &s : save) {
        if (!s.where.check()) continue;
        if (s.where->reg.parser_id() < 0)
            error(s.where.lineno, "%s is not accessable in the parser", s.where->reg.name);
        if (s.lo >= 32 && s.lo < 54)
            error(s.where.lineno, "byte 32-53 of input buffer cannot be used for output");
        pa->phv_use[state->gress][s.where->reg.uid] = 1;
        int size = s.where->reg.size;
        if (s.second) {
            if (!s.second.check()) continue;
            if (s.second->reg.parser_id() < 0)
                error(s.second.lineno, "%s is not accessable in the parser", s.second->reg.name);
            else if (s.second->lo >= 32 && s.second->lo < 54)
                error(s.where.lineno, "byte 32-53 of input buffer cannot be used for output");
            else if (s.second->reg.parser_id() != s.where->reg.parser_id() + 1 ||
                (s.where->reg.parser_id() & 1))
                error(s.second.lineno, "Can only write into even/odd register pair");
            else if (s.second->lo || s.second->hi != size-1)
                error(s.second.lineno, "Can only write data into whole phv registers in parser");
            else
                size *= 2; }
        if (s.where->lo || s.where->hi != s.where->reg.size-1)
            error(s.where.lineno, "Can only write data into whole phv registers in parser");
        else if ((s.hi-s.lo+1)*8 != size)
            error(s.where.lineno, "Data to write doesn't match phv register size");
    }
    //TODO: Merge phv reg slices if present. Phv slices if generated by the
    //compiler are merged together as otherwise assembler will put them in different
    //slots and can cause 'Ran out of phv slices' error. This should eventually go away
    //as ideally the compiler should not generate any phv slices
    if (!options.match_compiler) {
        for (unsigned i1 = 0; i1 < set.size(); ++i1) {
            for (unsigned i2 = i1 + 1; i2 < set.size(); ++i2) {
                auto &a = set[i1];
                auto &b = set[i2];
                if (a == b) continue;
                if (a.where->reg == b.where->reg) {
                    if(a.merge(state->gress, b)) {
                        set.erase(set.begin() + i2);
                        --i2; }
                    else {
                        error(a.where.lineno, "Cannot merge phv slices %s and %s",
                              a.where.name(), b.where.name());
                        break; } } } } }
    for (auto &s : set) {
        if (!s.where.check()) continue;
        if (s.where->reg.parser_id() < 0)
            error(s.where.lineno, "%s is not accessable in the parser", s.where->reg.name);
        pa->phv_use[state->gress][s.where->reg.uid] = 1;
        if (s.where->lo || s.where->hi != s.where->reg.size-1) {
            pa->phv_allow_multi_write[s.where->reg.parser_id()] = 1;
            if (s.what > ~(~1U << (s.where->hi - s.where->lo)))
                error(s.where.lineno, "Can't fit value %d in a %d bit phv slice",
                        s.what, (s.where->hi - s.where->lo + 1)); } }
    if (value_set_size == 0) {
        uint64_t match_mask = (UINT64_C(1) << state->key.width) - 1;
        uint64_t not_covered = match_mask & ~(match.word0 | match.word1);
        if (not_covered != 0) {
            warning(lineno, "Match pattern does not cover all bits of match key, "
                    "assuming the rest are don't care");
            match.word0 |= not_covered;
            match.word1 |= not_covered; }
        if ((match.word1 & ~match.word0 & ~match_mask) != 0)
            error(lineno, "Matching on bits not in the match of state %s", state->name.c_str());
        for (auto &m : state->match) {
            if (&m == this) break;
            if (m.match == match) {
                warning(lineno, "Can't match parser state due to previous match");
                warning(m.lineno, "here");
                break; } } }
    for (auto &c : csum)
        c.pass1(pa);
}

bool Parser::State::Match::Set::merge(gress_t gress, const Set &a) {
    auto orig = where;
    if (where->reg != a.where->reg) return false;
    if (!(where->hi < a.where->lo || a.where->hi < where->lo)) {
        warning(where.lineno, "Phv slices %s and %s overlapping"
                , where.name(), a.where.name()); }
    what = ((what << where->lo) | (a.what << a.where->lo))
        >> (std::min(where->lo, a.where->lo));
    where = Phv::Ref(where->reg, gress, std::min(where->lo, a.where->lo),
                     std::max(where->hi, a.where->hi));
    LOG1("Merging phv slices " << orig << " + " << a.where << " = " << where);
    return true;
}

void Parser::State::pass1(Parser *pa) {
    for (auto &m : match) m.pass1(pa, this);
    if (def) def->pass1(pa, this);
    for (auto code : MatchIter(stateno)) {
        if (pa->state_use[gress][code]) {
            error(lineno, "%sgress state %s uses state code %d, already in use",
                  gress ? "E" : "In", name.c_str(), code);
            for (auto *state : pa->all) {
                if (state != this && state->gress == gress && state->stateno.matches(code))
                    error(state->lineno, "also used by state %s", state->name.c_str()); } }
        pa->state_use[gress][code] = 1; }
    for (auto &m : match)
        for (auto succ : m.next)
            succ->pred.insert(this);
    if (def)
        for (auto succ : def->next)
            succ->pred.insert(this);
}

/********* pass 2 *********/

void Parser::State::MatchKey::preserve_saved(unsigned saved) {
    for (int i = 3; i >= 0; i--) {
        if (!((saved >> i) & 1)) continue;
        if (data[i].bit < 0 || data[i].byte == USE_SAVED)
            continue;
        if ((specified >> i) & 1)
            error(lineno, "match in %s matcher conflicts with previous state save "
                  "action", Parser::match_key_loc_name(i));
        else if (move_down(i) < 0) {
            error(lineno, "Ran out of matching space due to preserved values from "
                  "previous states");
            break; } }
}

Parser::State::OutputUse Parser::State::Match::Save::output_use() const {
    OutputUse rv;
    if (lo == hi) rv.b8++;
    else if (lo+1 == hi) rv.b16++;
    else if (lo+3 == hi) rv.b32++;
    else BUG();
    return rv;
}
Parser::State::OutputUse Parser::State::Match::Set::output_use() const {
    OutputUse rv;
    if (where->reg.size == 8) rv.b8++;
    else if (where->reg.size == 16) rv.b16++;
    else if (where->reg.size == 32) rv.b32++;
    else BUG();
    return rv;
}
Parser::State::OutputUse Parser::State::Match::output_use() const {
    OutputUse rv;
    for (auto &s : save) rv += s.output_use();
    for (auto &s : set) rv += s.output_use();
    return rv;
}
void Parser::State::Match::merge_outputs(OutputUse use) {
    if (options.target != TOFINO) return;
    // FIXME -- this is tofino specific
    use += output_use();
    if (use.b32 >= 4 && use.b16 >= 4) return;
    std::sort(save.begin(), save.end(), [](const Save &a, const Save &b)->bool {
        return a.lo < b.lo; });
    /* combine adjacent aligned 16-bit extracts into 32 bit */
    for (unsigned i = 0; i+1 < save.size() && use.b32 < 4; ++i) {
        if (save[i].hi == save[i].lo + 1 && save[i+1].lo == save[i].hi + 1 &&
            save[i+1].hi == save[i+1].lo + 1 && !save[i].flags && !save[i+1].flags &&
            (save[i].where->reg.parser_id() & 1) == 0 &&
            save[i].where->reg.parser_id() + 1 == save[i+1].where->reg.parser_id()) {
            LOG3("merge 2x16->32 (" << save[i].where << ", " << save[i+1].where << ")");
            save[i].hi += 2;
            save.erase(save.begin()+i+1);
            use.b32++;
            use.b16 -= 2; } }
    /* combine adjacent aligned 8-bit extracts into 16 bit */
    for (unsigned i = 0; i+1 < save.size() && use.b16 < 4; ++i) {
        if (save[i].hi == save[i].lo && save[i+1].lo == save[i].hi + 1 &&
            save[i+1].hi == save[i+1].lo && !save[i].flags && !save[i+1].flags &&
            (save[i].where->reg.parser_id() & 1) == 0 &&
            save[i].where->reg.parser_id() + 1 == save[i+1].where->reg.parser_id()) {
            LOG3("merge 2x8->16 (" << save[i].where << ", " << save[i+1].where << ")");
            save[i].hi += 1;
            save.erase(save.begin()+i+1);
            use.b16++;
            use.b8 -= 2; } }
    /* combine 4 adjacent aligned 8-bit extracts into 32 bit */
    for (unsigned i = 0; i+1 < save.size() && use.b32 < 4; ++i) {
        if (save[i].hi == save[i].lo + 1 && save[i+1].lo == save[i].hi + 1 &&
            save[i+1].hi == save[i+1].lo + 1 && !save[i].flags && !save[i+1].flags &&
            (save[i].where->reg.parser_id() & 1) == 0 &&
            save[i].where->reg.parser_id() + 1 == save[i+1].where->reg.parser_id()) {
            LOG3("merge 4x8->32 (" << save[i].where << ", " << save[i+1].where << ")");
            save[i].hi += 2;
            save.erase(save.begin()+i+1);
            use.b32++;
            use.b16 -= 2; } }
}

void Parser::State::Match::pass2(Parser *pa, State *state) {
    for (auto &c : csum)
        c.pass2(pa);
    if (counter < 0 && counter_exp) {
        if (counter_exp->src < 0)
            error(counter_exp->lineno, "can't allocate match unit for counter load"
                  " (unimplemented)");
        else {
            int i = 0, free = -1;
            for (auto init : pa->counter_init[state->gress]) {
                if (init && init->equiv(*counter_exp)) {
                    counter = i;
                    break; }
                if (free < 0 && !init) free = i;
                ++i; }
            if (counter < 0) {
                if (free >= 0)
                    pa->counter_init[state->gress][counter = free] = counter_exp;
                else
                    error(counter_exp->lineno, "no space left in counter init ram"); } } }
    if (clots.size() > 0) {
        if (options.target == TOFINO)
            error(clots[0].lineno, "clots not supported on tofino");
        else if (clots.size() > 2)
            error(clots[2].lineno, "no more that 2 clots per state"); }
}

void Parser::State::pass2(Parser *pa) {
    if (!stateno) {
        unsigned s;
        for (s = 0; pa->state_use[gress][s]; s++);
        if (s > PARSER_STATE_MASK)
            error(lineno, "Can't allocate state number for %sgress state %s",
                  gress ? "e" : "in", name.c_str());
        else {
            stateno.word0 = s ^ PARSER_STATE_MASK;
            stateno.word1 = s;
            pa->state_use[gress][s] = 1; } }
    unsigned def_saved = 0;
    if (def && def->future.lineno >= 0) {
        for (int i = 0; i < 4; i++)
            if (def->future.data[i].bit >= 0)
                def_saved |= 1 << i;
        if (def_saved && def->next)
            def->next->key.preserve_saved(def_saved); }
    OutputUse defuse;
    if (def) defuse = def->output_use();
    for (auto &m : match) {
        m.pass2(pa, this);
        unsigned saved = def_saved;
        if (m.future.lineno) {
            for (int i = 0; i < 4; i++)
                if (m.future.data[i].bit >= 0)
                    saved |= 1 << i;
                else if (def && def->future.lineno && def->future.data[i].bit >= 0)
                    m.future.data[i] = def->future.data[i]; }
        if (saved) {
            if (m.next)
                m.next->key.preserve_saved(saved);
            else if (def && def->next)
                def->next->key.preserve_saved(saved); }
        if (!options.match_compiler)
            m.merge_outputs(defuse); }
}

/********* output *********/

template <class REGS>
void Parser::PriorityUpdate::write_config(REGS &action_row) {
    if (offset >= 0) {
        action_row.pri_upd_type = 1;
        action_row.pri_upd_src = offset;
        action_row.pri_upd_en_shr = shift;
        action_row.pri_upd_val_mask = mask;
    } else {
        action_row.pri_upd_type = 0;
        action_row.pri_upd_en_shr = 1;
        action_row.pri_upd_val_mask = mask;
    }
}

template <class REGS>
void Parser::State::Match::write_config(REGS &regs, Parser *pa, State *state,
                                        Match *def, json::map &ctxt_json) {
    int row, count = 0;
    do {
        if ((row = --pa->tcam_row_use[state->gress]) < 0) {
            if (row == -1)
                error(state->lineno, "Ran out of tcam space in %sgress parser",
                      state->gress ? "e" : "in");
            return; }
        ctxt_json["tcam_rows"].to<json::vector>().push_back(row);
        write_row_config(regs, pa, state, row, def,ctxt_json);
    } while (++count < value_set_size);
}

template<class REGS>
void Parser::State::Match::write_config(REGS &regs, json::vector &vec) {
    for (auto f : field_mapping) {
        json::map container_cjson;
        container_cjson["container_width"] = Parser::match_key_size(f.container_id.c_str());

        int container_hardware_id = Parser::match_key_loc(f.container_id.c_str());
        container_cjson["container_hardware_id"] = container_hardware_id;

        container_cjson["mask"] = (1 << (f.hi - f.lo + 1)) - 1;
        json::vector field_mapping_cjson;
        int select_statement_bit = f.where.lobit();
        for (auto i = f.lo; i <= f.hi; i++) {
            json::map field_map;
            field_map["register_bit"] = i;
            field_map["field_name"] = f.where.name();
            field_map["start_bit"] = i;
            field_map["select_statement_bit"] = select_statement_bit++;
            field_mapping_cjson.push_back(field_map.clone());
        }
        container_cjson["field_mapping"] = field_mapping_cjson.clone();
        vec.push_back(container_cjson.clone());
    }
}

template <class REGS>
void Parser::State::Match::write_row_config(REGS &regs, Parser *pa, State *state, int row,
                                            Match *def, json::map &ctxt_json) {
    int max_off = -1;
    write_lookup_config(regs, state, row);

    auto &ea_row = regs.memory[state->gress].ml_ea_row[row];
    if (counter | counter_reset | counter_load)
        write_counter_config(ea_row);
    else if (def)
        def->write_counter_config(ea_row);
    if (shift)
        max_off = std::max(max_off, int(ea_row.shift_amt = shift) - 1);
    else if (def)
        max_off = std::max(max_off, int(ea_row.shift_amt = def->shift) - 1);
    max_off = std::max(max_off, write_future_config(regs, pa, state, row));
    if (auto &next = (!this->next && def) ? def->next : this->next) {
        std::vector<State *> prev;
        for (auto n : next) {
            max_off = std::max(max_off, n->write_lookup_config(regs, pa, state, row, prev));
            prev.push_back(n); }
        const match_t &n = next.pattern ? next.pattern : next->stateno;
        ea_row.nxt_state = n.word1;
        ea_row.nxt_state_mask = ~(n.word0 & n.word1) & PARSER_STATE_MASK;
    } else
        ea_row.done = 1;

    auto &action_row = regs.memory[state->gress].po_action_row[row];
    for (auto &c : csum) {
        action_row.csum_en[c.unit] = 1;
        action_row.csum_addr[c.unit] = c.addr; }
    if (offset || offset_reset) {
        action_row.dst_offset_inc = offset;
        action_row.dst_offset_rst = offset_reset;
    } else if (def) {
        action_row.dst_offset_inc = def->offset;
        action_row.dst_offset_rst = def->offset_reset; }
    if (priority)
        priority.write_config(action_row);
    void *output_map = pa->setup_phv_output_map(regs, state->gress, row);
    unsigned used = 0;
    for (auto &c : csum) c.write_output_config(regs, pa, output_map, used);
    for (auto &s : set) s.write_output_config(regs, output_map, used);
    if (def) for (auto &s : def->set) s.write_output_config(regs, output_map, used);
    for (auto &s : save)
        max_off = std::max(max_off, s.write_output_config(regs, output_map, used));
    if (def) for (auto &s : def->save)
        max_off = std::max(max_off, s.write_output_config(regs, output_map, used));
    int clot_unit = 0;
    for (auto &c : clots) c.write_config(action_row, clot_unit++);
    if (def) for (auto &c : def->clots) c.write_config(action_row, clot_unit++);
    pa->mark_unused_output_map(regs, output_map, used);

    if (buf_req < 0) {
        buf_req = max_off + 1;
        BUG_CHECK(buf_req <= 32); }
    ea_row.buf_req = buf_req;
}

template <class REGS>
void Parser::State::MatchKey::write_config(REGS &, json::vector &) {
    // FIXME -- TBD -- probably needs to be different for tofino/jbay, so there will be
    // FIXME -- template specializations for this in those files
}

template <class REGS>
void Parser::State::write_config(REGS &regs, Parser *pa, json::vector &ctxt_json) {
    LOG2(gress << " state " << name << " (" << stateno << ')');
    for (auto i = match.begin(); i != match.end(); i++) {
        bool uses_pvs = false;
        json::map state_cjson;
        state_cjson["parser_name"] = name;
        i->write_config(regs, state_cjson["match_registers"]);
        if (i->value_set_size > 0) uses_pvs = true;
        i->write_config(regs, pa, this, def, state_cjson);
        state_cjson["uses_pvs"] = uses_pvs;
        if (def) def->write_config(regs, pa, this, 0, state_cjson);
        if (uses_pvs) {
            state_cjson["pvs_name"] = i->value_set_name;
            if (!pa->pvs_handle_use.count(i->value_set_name)) {
                state_cjson["pvs_handle"] = --pa->pvs_handle;
                pa->pvs_handle_use.emplace(i->value_set_name, pa->pvs_handle);
            } else {
                state_cjson["pvs_handle"] = pa->pvs_handle_use.at(i->value_set_name);
            }
        }
        for (auto idx : MatchIter(stateno)) {
            state_cjson["parser_state_id"] = idx;
            ctxt_json.push_back(state_cjson.clone());
        }
    }
}
