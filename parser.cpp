#include "parser.h"
#include "phv.h"
#include "range.h"

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
    declare_registers(&reg_merge, sizeof(reg_merge),
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
    if (args.size == 0) {
        this->lineno[INGRESS] = this->lineno[EGRESS] = lineno;
        return; }
    if (args.size != 1 || (args[0] != "ingress" && args[0] != "egress"))
        error(lineno, "parser must specify ingress or egress");
    gress_t gress = args[0] == "egress" ? EGRESS : INGRESS;
    if (!this->lineno[gress]) this->lineno[gress] = lineno;
}
void Parser::input(VECTOR(value_t) args, value_t data) {
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
            if (kv.key == "parser_error") {
                if (parser_error[gress].lineno >= 0) {
                    error(kv.key.lineno, "Multiple parser_error declarations");
                    warning(parser_error[gress].lineno, "Previous was here");
                } else
                    parser_error[gress] = Phv::Ref(gress, kv.value);
                continue; }
            if (kv.key == "multi_write") {
                if (kv.value.type == tVEC)
                    for (auto &el : kv.value.vec)
                        multi_write.emplace_back(gress, el);
                else
                    multi_write.emplace_back(gress, kv.value);
                continue; }
            if (!CHECKTYPE2M(kv.key, tSTR, tCMD, "state declaration")) continue;
            const char *name = kv.key.s;
            match_t stateno = { 0, 0 };
            if (kv.key.type == tCMD) {
                name = kv.key[0].s;
                if (!CHECKTYPE2(kv.key[1], tINT, tMATCH)) continue;
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
            if (!CHECKTYPE(kv.value, tMAP)) continue;
            auto n = states[gress].emplace(name, State(kv.key.lineno, name, gress,
                                           stateno, kv.value.map));
            if (n.second)
                all.push_back(&n.first->second);
            else {
                error(kv.key.lineno, "State %s already defined in %sgress", name,
                      gress ? "e" : "in");
                warning(n.first->second.lineno, "previously defined here"); } } }
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
                assert(n.second);
                State *state = &n.first->second;
                state->def = new State::Match(lineno[gress], gress, *start_state[gress][i]);
                for (int j = 3; j >= i; j--)
                    if (start_state[gress][j] == start_state[gress][i]) {
                        start_state[gress][j].name = name;
                        start_state[gress][j].ptr[0] = state; }
                all.insert(all.begin(), state); }
        if (parser_error[gress].lineno >= 0)
            if (parser_error[gress].check())
                phv_use[gress][parser_error[gress]->reg.index] = 1; }
    if (error_count > 0) return;
    int all_index = 0;
    for (auto st : all) st->all_idx = all_index++;
    bitvec unreach(0, all_index);
    for (int i = 0; i < 4; i++) {
        start_state[INGRESS][i]->unmark_reachable(this, unreach);
        start_state[EGRESS][i]->unmark_reachable(this, unreach); }
    for (auto u : unreach)
        error(all[u]->lineno, "%sgress state %s unreachable",
              all[u]->gress ? "E" : "In", all[u]->name.c_str());
    if (phv_use[INGRESS].intersects(phv_use[EGRESS])) {
        bitvec tmp = phv_use[INGRESS];
        tmp &= phv_use[EGRESS];
        for (int reg : tmp)
            error(lineno[0], "Phv register R%d used by both ingress and egress", reg); }
    for (auto &reg : multi_write)
        if (reg.check())
            phv_allow_multi_write[reg->reg.index] = 1;
    if (options.match_compiler) {
        Phv::setuse(INGRESS, phv_use[INGRESS]);
        Phv::setuse(EGRESS, phv_use[EGRESS]); }
}

void Parser::output() {
    if (all.empty()) return;
    for (auto st : all) st->pass2(this);
    if (error_count > 0) return;
    tcam_row_use[INGRESS] = tcam_row_use[EGRESS] = PARSER_TCAM_DEPTH;
    for (auto st : all) st->write_config(this);
    if (error_count > 0) return;
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        // TODO: write ctr_init_ram
        // TODO: write checksum units
        mem[gress].po_csum_ctrl_0_row.disable();
        mem[gress].po_csum_ctrl_1_row.disable();
        // TODO: fixed config copied from compiler -- needs to be controllable
        for (int i = 0; i < 4; i++)
            if (start_state[gress][i]) {
                reg[gress].start_state.state[i] = start_state[gress][i]->stateno.word1;
                reg[gress].enable.enable[i] = 1; }
        reg[gress].mode = 4;
        reg[gress].max_iter.max = 128;
        if (parser_error[gress].lineno >= 0)
            reg[gress].err_phv_cfg.dst = parser_error[gress]->reg.index;
        reg[gress].err_phv_cfg.aram_mem_err_en = 1;
        reg[gress].err_phv_cfg.csum_mem_err_en = 1;
        reg[gress].err_phv_cfg.ctr_mem_err_en = 1;
        reg[gress].err_phv_cfg.ctr_range_err_en = 1;
        reg[gress].err_phv_cfg.dst_cont_err_en = 1;
        reg[gress].err_phv_cfg.fcs_err_en = 1;
        reg[gress].err_phv_cfg.multi_wr_err_en = 1;
        reg[gress].err_phv_cfg.no_tcam_match_err_en = 1;
        reg[gress].err_phv_cfg.partial_hdr_err_en = 1;
        reg[gress].err_phv_cfg.phv_owner_err_en = 1;
        reg[gress].err_phv_cfg.src_ext_err_en = 1;
        reg[gress].err_phv_cfg.timeout_err_en = 1;
        // disable unused registers
        reg[gress].aram_mem_err_cnt.disable();
        reg[gress].csum_err_cnt.disable();
        reg[gress].csum_mem_err_cnt.disable();
        reg[gress].ctr_mem_err_cnt.disable();
        reg[gress].ctr_range_err_cnt.disable();
        reg[gress].dst_cont_err_cnt.disable();
        reg[gress].fcs_err_cnt.disable();
        reg[gress].hdr_byte_cnt.disable();
        reg[gress].idle_cnt.disable();
        reg[gress].int_en.disable();
        reg[gress].int_status.disable();
        reg[gress].max_cycle.disable();
        reg[gress].multi_wr_err_cnt.disable();
        reg[gress].no_tcam_match_err_cnt.disable();
        reg[gress].partial_hdr_err_cnt.disable();
        reg[gress].phv_owner_err_cnt.disable();
        reg[gress].pri_start.disable();
        reg[gress].src_ext_err_cnt.disable();
        reg[gress].timeout_err_cnt.disable(); }
    if (options.match_compiler) {
        phv_use[INGRESS] |= Phv::use(INGRESS);
        phv_use[EGRESS] |= Phv::use(EGRESS); }
    for (int i : phv_use[EGRESS]) {
        if (i >= 256)
            reg_merge.phv_owner.t_owner[i-256] = 1;
        else
            reg_merge.phv_owner.owner[i] = 1; }
    for (int i = 0; i < 224; i++)
        if (!phv_allow_multi_write[i])
            reg_merge.no_multi_wr.nmw[i] = 1;
    for (int i = 0; i < 112; i++)
        if (!phv_allow_multi_write[256+i])
            reg_merge.no_multi_wr.t_nmw[i] = 1;
    mem[INGRESS].emit_json(*open_output("memories.all.parser.ingress.cfg.json"), "ingress");
    mem[EGRESS].emit_json(*open_output("memories.all.parser.egress.cfg.json"), "egress");
    reg[INGRESS].emit_json(*open_output("regs.all.parser.ingress.cfg.json"), "ingress");
    reg[EGRESS].emit_json(*open_output("regs.all.parser.egress.cfg.json"), "egress");
    reg_merge.emit_json(*open_output("regs.all.parse_merge.cfg.json"));
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

int Parser::State::MatchKey::add_byte(int byte) {
    if (byte < 0 || byte >= 32) {
        error(lineno, "Match key index out of range");
        return -1; }
    for (int i = 3; i >= 0; i--) {
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
        for (int i = spec.hi; i >= spec.lo; i--) {
            if (add_byte(i) < 0)
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
    if (spec.type == tVEC) {
        /* allocate the keys bits for the least significant match bits first... */
        for (int i = spec.vec.size-1; i >= 0; i--)
            if (setup_match_el(spec[i]) < 0)
                return;
    } else
        setup_match_el(spec);
    if (data[0].bit >= 0 && data[1].byte != data[0].byte + 1) {
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
    counter = offset = shift = 0;
    counter_reset = offset_reset = false;
    for (auto &kv : MapIterChecked(data, true)) {
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
            next = kv.value;
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
    VECTOR(pair_t) default_data = EMPTY_VECTOR_INIT;
    bool have_default = data["default"] != 0;
    for (auto &kv : data) {
        if (kv.key.type == tINT && kv.value.type == tMAP) {
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
        } else if (!have_default) {
            VECTOR_add(default_data, kv);
        } else
            error(kv.key.lineno, "Syntax error");
    }
    if (default_data.size) {
        assert(!def);
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

void Parser::State::Match::pass1(Parser *pa, State *state) {
    next.check(state->gress, pa, state);
    for (auto &s : save) {
        if (!s.where.check()) continue;
        pa->phv_use[state->gress][s.where->reg.index] = 1;
        if (s.where->lo || s.where->hi != s.where->reg.size-1)
            error(s.where.lineno, "Can only write data into whole phv registers in parser");
        else if ((s.hi-s.lo+1)*8 != s.where->reg.size)
            error(s.where.lineno, "Data to write doesn't match phv register size");
    }
    for (auto &s : set) {
        if (!s.where.check()) continue;
        pa->phv_use[state->gress][s.where->reg.index] = 1;
        if (s.where->lo || s.where->hi != s.where->reg.size-1) {
            pa->phv_allow_multi_write[s.where->reg.index] = 1;
            if (s.what != ~(~1 << (s.where->hi - s.where->lo)))
                warning(s.where.lineno, "Not writing all bits of phv slice"); }
    }
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
    for (auto &m : match)
        for (auto succ : m.next)
            succ->pred.insert(this);
    if (def)
        for (auto succ : def->next)
            succ->pred.insert(this);
}

/* FIXME -- hack to swap allocation of 8-bit lookups slots to match compiler
 * should be a config param somehow?  Or just not do it at all */
int lookup_swap8bit = 1;

void Parser::State::write_lookup_config(Parser *pa, State *state, int row,
                                        const std::vector<State *> &prev)
{
    LOG2("-- checking match from state " << name << " (" << stateno << ')');
    auto &ea_row = pa->mem[gress].ml_ea_row[row];
    for (int i = 0; i < 4; i++) {
        if (i == 1) continue;
        if (key.data[i].bit < 0) continue;
        bool set = true;
        for (State *p : prev) {
            if (p->key.data[i].bit >= 0) {
                set = false;
                if (p->key.data[i].byte != key.data[i].byte)
                    error(p->lineno, "Incompatible match fields between states "
                          "%s and %s, triggered from state %s", name.c_str(),
                          p->name.c_str(), state->name.c_str()); } }
        if (set) {
            if (i) {
                ea_row.lookup_offset_8[(i-2)^lookup_swap8bit] = key.data[i].byte;
                ea_row.ld_lookup_8[(i-2)^lookup_swap8bit] = 1;
            } else {
                ea_row.lookup_offset_16 = key.data[i].byte;
                ea_row.ld_lookup_16 = 1; } } }
}

enum {
    /* enum for indexes in the phv_output_map */
    phv_32b_0, phv_32b_1, phv_32b_2, phv_32b_3,
    phv_16b_0, phv_16b_1, phv_16b_2, phv_16b_3,
    phv_8b_0, phv_8b_1, phv_8b_2, phv_8b_3,
    phv_output_map_size,
};

void Parser::State::Match::write_config(Parser *pa, State *state, Match *def) {
    int row;
    if ((row = --pa->tcam_row_use[state->gress]) < 0) {
        if (row == -1)
            error(state->lineno, "Ran out of tcam space in %sgress parser",
                  state->gress ? "e" : "in");
        return; }

    auto &word0 = pa->mem[state->gress].ml_tcam_row_word0[row];
    auto &word1 = pa->mem[state->gress].ml_tcam_row_word1[row];
    match_t lookup = { 0, 0 };
    for (int i = 0; i < 4; i++) {
        lookup.word0 <<= 8;
        lookup.word1 <<= 8;
        if (state->key.data[i].bit >= 0) {
            lookup.word0 |= ((match.word0 >> state->key.data[i].bit) & 0xff);
            lookup.word1 |= ((match.word1 >> state->key.data[i].bit) & 0xff); } }
    unsigned dont_care = ~(lookup.word0 | lookup.word1);
    lookup.word0 |= dont_care;
    lookup.word1 |= dont_care;
    word0.lookup_16 = (lookup.word0 >> 16) & 0xffff;
    word1.lookup_16 = (lookup.word1 >> 16) & 0xffff;
    word0.lookup_8[0^lookup_swap8bit] = (lookup.word0 >> 8) & 0xff;
    word1.lookup_8[0^lookup_swap8bit] = (lookup.word1 >> 8) & 0xff;
    word0.lookup_8[1^lookup_swap8bit] = lookup.word0 & 0xff;
    word1.lookup_8[1^lookup_swap8bit] = lookup.word1 & 0xff;
    word0.curr_state = state->stateno.word0;
    word1.curr_state = state->stateno.word1;
    if (state->key.ctr_zero >= 0) {
        word0.ctr_zero = (match.word0 >> state->key.ctr_zero) & 1;
        word1.ctr_zero = (match.word1 >> state->key.ctr_zero) & 1;
    } else
        word0.ctr_zero = word1.ctr_zero = 1;
    if (state->key.ctr_neg >= 0) {
        word0.ctr_neg = (match.word0 >> state->key.ctr_neg) & 1;
        word1.ctr_neg = (match.word1 >> state->key.ctr_neg) & 1;
    } else
        word0.ctr_neg = word1.ctr_neg = 1;
    word0.ver_0 = word1.ver_0 = 1;
    word0.ver_1 = word1.ver_1 = 1;

    auto &ea_row = pa->mem[state->gress].ml_ea_row[row];
    if (counter | counter_reset) {
        ea_row.ctr_amt_idx = counter;
        ea_row.ctr_load = counter_reset;
    } else if (def) {
        ea_row.ctr_amt_idx = def->counter;
        ea_row.ctr_load = def->counter_reset; }
    if (shift) ea_row.shift_amt = shift;
    else if (def) ea_row.shift_amt = def->shift;
    if (auto &next = (!this->next && def) ? def->next : this->next) {
        std::vector<State *> prev;
        for (auto n : next) {
            n->write_lookup_config(pa, state, row, prev);
            prev.push_back(n); }
        match_t &n = next.pattern ? next.pattern : next->stateno;
        ea_row.nxt_state = n.word1;
        ea_row.nxt_state_mask = ~(n.word0 & n.word1) & PARSER_STATE_MASK;
    } else
        ea_row.done = 1;
    ea_row.buf_req = 0; /* FIXME -- set to? */

    auto &action_row = pa->mem[state->gress].po_action_row[row];
    /* FIXME -- checksum setup? */
    if (offset || offset_reset) {
        action_row.dst_offset_inc = offset;
        action_row.dst_offset_rst = offset_reset;
    } else if (def) {
        action_row.dst_offset_inc = def->offset;
        action_row.dst_offset_rst = def->offset_reset; }
    phv_output_map output_map[phv_output_map_size];
    pa->setup_phv_output_map(output_map, state->gress, row);
    unsigned used = 0;
    for (auto &s : set) s.write_output_config(output_map, used);
    if (def) for (auto &s : def->set) s.write_output_config(output_map, used);
    for (auto &s : save) s.write_output_config(output_map, used);
    if (def) for (auto &s : def->save) s.write_output_config(output_map, used);
    for (int i = 0; i < phv_output_map_size; i++)
        if (!(used & (1U << i)))
            *output_map[i].dst = 0x1ff;
}

static struct phv_use_slots { int idx; unsigned usemask, shift, size; }
phv_32b_slots[] = {
    { phv_32b_0, 1U << phv_32b_0, 0, 32 },
    { phv_32b_1, 1U << phv_32b_1, 0, 32 },
    { phv_32b_2, 1U << phv_32b_2, 0, 32 },
    { phv_32b_3, 1U << phv_32b_3, 0, 32 },
    { phv_16b_0, 3U << phv_16b_0, 16, 16 },
    { phv_16b_2, 3U << phv_16b_2, 16, 16 },
    { phv_8b_0, 0xfU << phv_8b_0, 24, 8 },
    { 0, 0 }
},
phv_16b_slots[] = {
    { phv_16b_0, 1U << phv_16b_0, 0, 16 },
    { phv_16b_1, 1U << phv_16b_1, 0, 16 },
    { phv_16b_2, 1U << phv_16b_2, 0, 16 },
    { phv_16b_3, 1U << phv_16b_3, 0, 16 },
    { phv_8b_0, 3U << phv_8b_0, 8, 8 },
    { phv_8b_2, 3U << phv_8b_2, 8, 8 },
    { 0, 0 }
},
phv_8b_slots[] = {
    { phv_8b_0, 1U << phv_8b_0, 0, 8 },
    { phv_8b_1, 1U << phv_8b_1, 0, 8 },
    { phv_8b_2, 1U << phv_8b_2, 0, 8 },
    { phv_8b_3, 1U << phv_8b_3, 0, 8 },
    { 0, 0 }
};

void Parser::State::Match::Save::write_output_config(phv_output_map *map, unsigned &used)
{
    phv_use_slots *usable_slots;
    if (hi-lo == 3) {
        usable_slots = phv_32b_slots;
    } else if (hi-lo == 1) {
        usable_slots = phv_16b_slots;
    } else {
        assert(hi == lo);
        usable_slots = phv_8b_slots; }
    for (int i = 0; usable_slots[i].usemask; i++) {
        auto &slot = usable_slots[i];
        if (used & slot.usemask) continue;
        if ((flags & ROTATE) && !map[slot.idx].offset_rot)
            continue;
        int byte = lo;
        for (int i = slot.idx; slot.usemask & (1U << i); i++, byte++) {
            *map[i].dst = where->reg.index;
            *map[i].src = byte;
            if (flags & OFFSET) *map[i].offset_add = 1;
            if (flags & ROTATE) *map[i].offset_rot = 1; }
        used |= slot.usemask;
        return; }
    error(where.lineno, "Ran out of phv output slots");
}

static int encode_constant_for_slot(int slot, unsigned val) {
    switch(slot) {
    case phv_32b_0: case phv_32b_1: case phv_32b_2: case phv_32b_3:
        for (int i = 0; i < 32; i++) {
            if ((0x7 & val) == val)
                return (i << 3) | val;
            val = ((val >> 1) | (val << 31)) & 0xffffffffU; }
        return -1;
    case phv_16b_0: case phv_16b_1: case phv_16b_2: case phv_16b_3:
        if ((val >> 16) && encode_constant_for_slot(slot, val >> 16) < 0)
            return -1;
        val &= 0xffff;
        for (int i = 0; i < 32; i++) {
            if ((0xf & val) == val)
                return (i << 4) | val;
            val = ((val >> 1) | (val << 15)) & 0xffffU; }
        return -1;
    case phv_8b_0: case phv_8b_1: case phv_8b_2: case phv_8b_3:
        return val & 0xf;
    default:
        assert(0);
        return -1; }
}

void Parser::State::Match::Set::write_output_config(phv_output_map *map, unsigned &used)
{
    phv_use_slots *usable_slots;
    if (where->reg.size == 32)
        usable_slots = phv_32b_slots;
    else if (where->reg.size == 16)
        usable_slots = phv_16b_slots;
    else if (where->reg.size == 8)
        usable_slots = phv_8b_slots;
    else
        assert(0);
    for (int i = 0; usable_slots[i].usemask; i++) {
        auto &slot = usable_slots[i];
        if (used & slot.usemask) continue;
        if (!map[slot.idx].src_type) continue;
        if ((flags & ROTATE) && (!map[slot.idx].offset_rot || slot.shift))
            continue;
        if (encode_constant_for_slot(slot.idx, what << where->lo) < 0)
            continue;
        unsigned shift = slot.shift;
        for (int i = slot.idx; slot.usemask & (1U << i); i++) {
            *map[i].dst = where->reg.index;
            *map[i].src_type = 1;
            *map[i].src = encode_constant_for_slot(i, (what << where->lo) >> shift);
            if (flags & OFFSET) *map[i].offset_add = 1;
            if (flags & ROTATE) *map[i].offset_rot = 1;
            shift -= slot.size; }
        used |= slot.usemask;
        return; }
    error(where.lineno, "Ran out of phv output slots");
}

void Parser::State::write_config(Parser *pa) {
    LOG2(gress << " state " << name << " (" << stateno << ')');
    for (auto i = match.begin(); i != match.end(); i++)
        i->write_config(pa, this, def);
    if (def) def->write_config(pa, this, 0);
}

#define OUTPUT_MAP_INIT(MAP, ROW, SIZE, INDEX) \
    MAP[phv_##SIZE##b_##INDEX].dst = &ROW.phv_##SIZE##b_dst_##INDEX;                    \
    MAP[phv_##SIZE##b_##INDEX].src = &ROW.phv_##SIZE##b_src_##INDEX;                    \
    MAP[phv_##SIZE##b_##INDEX].src_type = &ROW.phv_##SIZE##b_src_type_##INDEX;          \
    MAP[phv_##SIZE##b_##INDEX].offset_add = &ROW.phv_##SIZE##b_offset_add_dst_##INDEX;  \
    MAP[phv_##SIZE##b_##INDEX].offset_rot = &ROW.phv_##SIZE##b_offset_rot_imm_##INDEX;
#define OUTPUT_MAP_INIT_PART(MAP, ROW, SIZE, INDEX) \
    MAP[phv_##SIZE##b_##INDEX].dst = &ROW.phv_##SIZE##b_dst_##INDEX;                    \
    MAP[phv_##SIZE##b_##INDEX].src = &ROW.phv_##SIZE##b_src_##INDEX;                    \
    MAP[phv_##SIZE##b_##INDEX].src_type = 0;                                            \
    MAP[phv_##SIZE##b_##INDEX].offset_add = &ROW.phv_##SIZE##b_offset_add_dst_##INDEX;  \
    MAP[phv_##SIZE##b_##INDEX].offset_rot = 0;

void Parser::setup_phv_output_map(phv_output_map *map, gress_t gress, int row) {
    auto &action_row = mem[gress].po_action_row[row];
    OUTPUT_MAP_INIT(map, action_row, 32, 0)
    OUTPUT_MAP_INIT(map, action_row, 32, 1)
    OUTPUT_MAP_INIT_PART(map, action_row, 32, 2)
    OUTPUT_MAP_INIT_PART(map, action_row, 32, 3)
    OUTPUT_MAP_INIT(map, action_row, 16, 0)
    OUTPUT_MAP_INIT(map, action_row, 16, 1)
    OUTPUT_MAP_INIT_PART(map, action_row, 16, 2)
    OUTPUT_MAP_INIT_PART(map, action_row, 16, 3)
    OUTPUT_MAP_INIT(map, action_row, 8, 0)
    OUTPUT_MAP_INIT(map, action_row, 8, 1)
    OUTPUT_MAP_INIT(map, action_row, 8, 2)
    OUTPUT_MAP_INIT(map, action_row, 8, 3)
}

