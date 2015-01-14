#include "parser.h"
#include "phv.h"
#include "range.h"
#include <fstream>

Parser Parser::singleton_object;

Parser::Parser() : Section("parser") {
    lineno[0] = lineno[1] = 0;
    declare_registers(&mem, sizeof(mem),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "parser.mem[";
            if (addr < (const char *)&mem[EGRESS]) {
                out << "INGRESS]";
                mem[INGRESS].emit_fieldname(out, addr, end);
            } else {
                out << "EGRESS]";
                mem[EGRESS].emit_fieldname(out, addr, end); } });
    declare_registers(&reg, sizeof(reg),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "parser.reg[";
            if (addr < (const char *)&reg[EGRESS]) {
                out << "INGRESS]";
                reg[INGRESS].emit_fieldname(out, addr, end);
            } else {
                out << "EGRESS]";
                reg[EGRESS].emit_fieldname(out, addr, end); } });
    declare_registers(&reg, sizeof(reg),
        [this](std::ostream &out, const char *addr, const void *end) {
            out << "parser.merge";
            reg_merge.emit_fieldname(out, addr, end); });
}
Parser::~Parser() {
    undeclare_registers(&mem);
    undeclare_registers(&reg);
    undeclare_registers(&reg_merge);
}

void Parser::start(int lineno, VECTOR(value_t) args) {
    if (args.size != 1 || (args[0] != "ingress" && args[0] != "egress"))
        error(lineno, "parser must specify ingress or egress");
    gress_t gress = args[0] == "egress" ? EGRESS : INGRESS;
    if (!this->lineno[gress]) this->lineno[gress] = lineno;
}
void Parser::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    gress_t gress = args[0] == "egress" ? EGRESS : INGRESS;
    for (auto &kv : data.map) {
        if (!CHECKTYPE2M(kv.key, tSTR, tCMD, "state declaration")) continue;
        const char *name = kv.key.s;
        match_t stateno = { 0, 0 };
        if (kv.key.type == tCMD) {
            name = kv.key[0].s;
            if (CHECKTYPE2(kv.key[1], tINT, tMATCH)) continue;
            if (kv.key[1].type == tINT) {
                stateno.word1 = kv.key[1].i;
                stateno.word0 = (~kv.key[1].i) & 0xff;
            } else
                stateno = kv.key[1].m; }
        if (!CHECKTYPE(kv.value, tMAP)) continue;
        auto n = states[gress].emplace(name, State(kv.key.lineno, name, gress,
                                       stateno, kv.value.map));
        if (n.second)
            all.push_back(&n.first->second);
        else {
            error(kv.key.lineno, "State %s already defined in %sgress", name, gress ? "e" : "in");
            error(n.first->second.lineno, "previously defined here"); } }
}

void Parser::process() {
    for (auto st : all) st->pass1(this);
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        if (states[gress].empty()) continue;
        if (!(start_state[gress] = ::getref(states[gress], "start")) &&
            !(start_state[gress] = ::getref(states[gress], "START"))) {
            error(lineno[gress], "No %sgress parser start state", gress ? "e" : "in");
            continue; }
        if (!start_state[gress]->can_be_start()) {
            auto n = states[gress].emplace("<start>", State(lineno[gress], "<start>", gress,
                    match_t{ 0, 0 }, VECTOR(pair_t) { 0, 0, 0 }));
            assert(n.second);
            n.first->second.def = new State::Match(lineno[gress], gress, start_state[gress]);
            start_state[gress] = &n.first->second;
            all.insert(all.begin(), start_state[gress]); } }
    if (error_count > 0) return;
    int all_index = 0;
    for (auto st : all) st->all_idx = all_index++;
    bitvec unreach(0, all_index);
    start_state[INGRESS]->unmark_reachable(this, unreach);
    start_state[EGRESS]->unmark_reachable(this, unreach);
    for (auto u : unreach)
        error(all[u]->lineno, "%sgress state %s unreachable",
              all[u]->gress ? "E" : "In", all[u]->name.c_str());
}

void Parser::output() {
    for (auto st : all) st->pass2(this);
    for (auto st : all) st->write_config(this);
    // TODO: write checksum units
    mem[INGRESS].po_csum_ctrl_0_row.disable();
    mem[INGRESS].po_csum_ctrl_1_row.disable();
    mem[EGRESS].po_csum_ctrl_0_row.disable();
    mem[EGRESS].po_csum_ctrl_1_row.disable();

    std::ofstream mem_in("memories.all.parser.ingress.cfg.json");
    mem[INGRESS].emit_json(mem_in, "ingress");
    std::ofstream mem_eg("memories.all.parser.egress.cfg.json");
    mem[EGRESS].emit_json(mem_eg, "egress");
    std::ofstream reg_in("regs.all.parser.ingress.cfg.json");
    reg[INGRESS].emit_json(reg_in, "ingress");
    std::ofstream reg_eg("regs.all.parser.egress.cfg.json");
    reg[EGRESS].emit_json(reg_eg, "egress");
    std::ofstream reg_mg("regs.all.parse_merge.cfg.json");
    reg_merge.emit_json(reg_mg);
}

void Parser::State::Ref::check(gress_t gress, Parser *pa) {
    if (name.size() && !ptr) {
        auto it = pa->states[gress].find(name);
        if (it != pa->states[gress].end())
            ptr = &it->second;
        else if (name != "END" && name != "end")
            error(lineno, "No state named %s in %sgress parser",
                  name.c_str(), gress ? "e" : "in"); }
}

int Parser::State::MatchKey::add_byte(unsigned byte) {
    if (byte >= 32) {
        error(lineno, "Match key index out of range");
        return -1; }
    for (int i = 0; i < 4; i++) {
        if (data[i].bit < 0) {
            data[i].bit = width;
            data[i].byte = byte;
            width += 8;
            return 0; } }
    error(lineno, "Too much data for parse matcher");
    return -1;
}

int Parser::State::MatchKey::setup_match_el(value_t &spec) {
    switch (spec.type) {
    case tINT:
        return add_byte(spec.i);
    case tRANGE:
        if (spec.lo >= spec.hi) {
            error(spec.lineno, "Invalid match range");
            return -1; }
        for (int i = spec.lo; i <= spec.hi; i++) {
            if (add_byte(spec.i) < 0)
                return -1; }
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
            return 0; }
        /* fall through */
    default:
        error(spec.lineno, "Syntax error in match spec");
        return -1; }
}

void Parser::State::MatchKey::setup(value_t &spec) {
    lineno = spec.lineno;
    if (spec.type == tVEC)
        for (auto &v : spec.vec)
            if (setup_match_el(v) < 0)
                return;
    else
        setup_match_el(spec);
    if (data[3].bit >= 0 && data[3].byte != data[2].byte + 1) {
        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {
                if (data[i].byte+1 == data[j].byte) {
                    auto lo = data[i];
                    auto hi = data[j];
                    data[i] = data[2];
                    data[j] = data[3];
                    data[2] = lo;
                    data[3] = hi;
                    return; } } }
        error(spec.lineno, "Must have a 16-bit pair in match bytes"); }
}

Parser::State::Match::Match(int l, gress_t gress, match_t m, VECTOR(pair_t) &data) :
    lineno(l), match(m)
{
    counter = offset = shift = 0;
    counter_reset = offset_reset = false;
    next_mod.word0 = next_mod.word1 = 0;
    for (auto &kv : data) {
        if (kv.key == "counter") {
            if (counter || counter_reset)
                error(kv.key.lineno, "Multiple counter settings in match");
            if (!CHECKTYPE2M(kv.value, tINT, tCMD, "set, inc or dec value"))
                continue;
            if (kv.value.type == tINT) {
                counter = kv.value.i;
                counter_reset = true;
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
        } else if (kv.key == "shift") {
            if (shift)
                error(kv.key.lineno, "Multiple shift settings in match");
            if (!CHECKTYPE(kv.value, tINT)) continue;
            shift = kv.value.i;
        } else if (kv.key == "next") {
            if (next.lineno >= 0) {
                error(kv.key.lineno, "Multiple next settings in match");
                error(next.lineno, "previously set here"); }
            next.lineno = kv.value.lineno;
            if (kv.value.type == tINT) {
                next_mod.word0 = ~kv.value.i;
                next_mod.word1 = kv.value.i;
            } else if (CHECKTYPE2(kv.value, tSTR, tMATCH)) {
                if (kv.value.type == tSTR)
                    next.name = kv.value.s;
                else
                    next_mod = kv.value.m; }
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
    counter = offset = shift = 0;
    counter_reset = offset_reset = false;
    next_mod.word0 = next_mod.word1 = 0;
    next.name = n->name;
    next.ptr = n;
}

static value_t &extract_save_phv(value_t &data) {
    if (data.type == tCMD && (data[0] == "offset" || data[0] == "rotate"))
        return data[1];
    return data;
}

Parser::State::Match::Save::Save(gress_t gress, int l, int h, value_t &data, int flgs) :
    lo(l), hi(h), where(gress, extract_save_phv(data)), flags(flgs)
{
    if (data.type == tCMD) {
        if (data[0] == "offset")
            flags |= OFFSET;
        else if (data[0] == "rotate")
            flags |= ROTATE; }
}

Parser::State::Match::Set::Set(gress_t gress, value_t &data, int v, int flgs) :
    where(gress, extract_save_phv(data)), what(v), flags(flgs)
{
    if (data.type == tCMD) {
        if (data[0] == "offset")
            flags |= OFFSET;
        else if (data[0] == "rotate")
            flags |= ROTATE; }
}

Parser::State::State(int l, const char *n, gress_t gr, match_t sno, const VECTOR(pair_t) &data) :
    name(n), gress(gr), stateno(sno), def(0), lineno(l)
{
    for (auto &kv : data) {
        if (kv.key.type == tINT) {
            if (!CHECKTYPE(kv.value, tMAP)) continue;
            match_t m = { ~(unsigned)kv.key.i, (unsigned)kv.key.i };
            match.emplace_back(kv.key.lineno, gress, m, kv.value.map);
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
        } else
            error(kv.key.lineno, "Syntax error");
    }
}

bool Parser::State::can_be_start() {
    if (match.size()) return false;
    if (!def) return true;
    if (def->counter || def->offset || def->shift) return false;
    if (def->counter_reset || def->offset_reset) return false;
    if (def->save.size() || def->set.size()) return false;
    return true;
}

void Parser::State::unmark_reachable(Parser *pa, bitvec &unreach) {
    if (!unreach[all_idx]) return;
    unreach[all_idx] = 0;
    for (auto &m : match) m.unmark_reachable(pa, this, unreach);
    if (def) def->unmark_reachable(pa, this, unreach);
}

void Parser::State::Match::unmark_reachable(Parser *pa, Parser::State *state, bitvec &unreach) {
    if (next) next->unmark_reachable(pa, unreach);
    if (next_mod) {
        match_t tmp = next_mod;
        unsigned wc = tmp.word0 & tmp.word1;
        if (wc && !state->stateno) {
            warning(next.lineno, "Using next state pattern in state without an explicit "
                    "state number");
            wc = 0; }
        tmp.word0 &= ~wc | state->stateno.word0;
        tmp.word1 &= ~wc | state->stateno.word1;
        for (auto *st : pa->all) {
            if (st->gress != state->gress) continue;
            if (st == state) continue;
            if (tmp.matches(st->stateno))
                st->unmark_reachable(pa, unreach); } }
}

void Parser::State::pass1(Parser *pa) {
    for (auto &m : match) m.next.check(gress, pa);
    if (def) def->next.check(gress, pa);
    for (auto code : MatchIter(stateno)) {
        if (pa->state_use[gress][code]) {
            error(lineno, "%sgress state %s uses state code %d, already in use",
                  gress ? "E" : "In", name.c_str(), code);
            for (auto *state : pa->all) {
                if (state != this && state->gress == gress && state->stateno.matches(code))
                    error(state->lineno, "also used by state %s", state->name.c_str()); } }
        pa->state_use[gress][code] = 1; }
}

void Parser::State::pass2(Parser *pa) {
}

void Parser::State::write_config(Parser *pa) {
}
