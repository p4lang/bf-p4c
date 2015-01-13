#include "parser.h"
#include "phv.h"
#include <fstream>

Parser Parser::singleton_object;

Parser::Parser() : Section("parser") {
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
        if (auto old = ::getref(states[gress], name)) {
            error(kv.key.lineno, "State %s already defined in %sgress", name, gress ? "e" : "in");
            error(old->lineno, "previously defined here");
        } else 
            states[gress].emplace(name, State(kv.key.lineno, name, gress, stateno, kv.value.map)); }
}

void Parser::process() {
}
void Parser::output() {
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

int add_match_byte(int lineno, Parser::MatchKey *m, unsigned byte) {
    if (byte >= 32) {
        error(lineno, "Match key index out of range");
        return -1; }
    for (int i = 0; i < 4; i++) {
        if (m->data[i].bit < 0) {
            m->data[i].bit = m->width;
            m->data[i].byte = byte;
            m->width += 8;
            return 0; } }
    error(lineno, "Too much data for parse matcher");
    return -1;
}

int setup_match_el(Parser::MatchKey *m, value_t &data) {
    switch (data.type) {
    case tINT:
        return add_match_byte(data.lineno, m, data.i);
    case tRANGE:
        if (data.lo >= data.hi) {
            error(data.lineno, "Invalid match range");
            return -1; }
        for (int i = data.lo; i <= data.hi; i++) {
            if (add_match_byte(data.lineno, m, data.i) < 0)
                return -1; }
        return 0;
    case tSTR:
        if (data == "ctr_zero") {
            if (m->ctr_zero >= 0) {
                error(data.lineno, "'ctr_zero' specified twice");
                return -1; }
            m->ctr_zero = m->width++;
            return 0;
        } else if (data == "ctr_neg") {
            if (m->ctr_neg >= 0) {
                error(data.lineno, "'ctr_neg' specified twice");
                return -1; }
            m->ctr_neg = m->width++;
            return 0; }
        /* fall through */
    default:
        error(data.lineno, "Syntax error in match spec");
        return -1; }
}

void setup_match(Parser::MatchKey *m, value_t &data) {
    m->lineno = data.lineno;
    if (data.type == tVEC)
        for (auto &v : data.vec)
            if (setup_match_el(m, v) < 0)
                return;
    else
        setup_match_el(m, data);
    if (m->data[3].bit >= 0 && m->data[3].byte != m->data[2].byte + 1) {
        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {
                if (m->data[i].byte+1 == m->data[j].byte) {
                    auto lo = m->data[i];
                    auto hi = m->data[j];
                    m->data[i] = m->data[2];
                    m->data[j] = m->data[3];
                    m->data[2] = lo;
                    m->data[3] = hi;
                    return; } } }
        error(data.lineno, "Must have a 16-bit pair in match bytes"); }
}

Parser::Match::Match(int l, gress_t gress, match_t m, VECTOR(pair_t) &data) : lineno(l), match(m) {
    for (auto &kv : data) {
        if (kv.key == "counter") {
        } else if (kv.key == "offset") {
        } else if (kv.key == "shift") {
        } else if (kv.key == "next") {
        } else if (kv.key.type == tINT) {
            save.emplace_back(gress, kv.key.i, kv.key.i, kv.value);
        } else if (kv.key.type == tRANGE) {
            save.emplace_back(gress, kv.key.lo, kv.key.hi, kv.value);
        } else if (kv.value.type == tINT) {
            set.emplace_back(gress, kv.key, kv.value.i);
        } else {
            error(kv.key.lineno, "Syntax error");
        }
    }
}

Parser::Match::Save::Save(gress_t gress, int l, int h, value_t &data) :
    lo(l), hi(h), offset(0), rotate(0), where(gress, data)
{
}

Parser::State::State(int l, const char *n, gress_t gr, match_t sno, VECTOR(pair_t) &data) :
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
                setup_match(&key, kv.value);
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
