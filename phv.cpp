#include "phv.h"
#include <iostream>

Phv Phv::phv;
const Phv::Register Phv::Slice::invalid = { 0, 0 };

Phv::Phv() : Section("phv") {
    static const struct { char code[4]; unsigned size, count; } sizes[] =
        { { "W", 32, 64 }, { "B", 8, 64 }, { "H", 16, 96 }, { "", 0, 32 },
          { "TW", 32, 32 }, { "TB", 8, 32 }, { "TH", 16, 64 } };
    int idx = 0;
    for (unsigned i = 0; i < sizeof sizes/sizeof *sizes; i++) {
        for (unsigned j = 0; j < sizes[i].count; j++, idx++) {
            char buf[8];
            regs[idx].index = idx;
            regs[idx].size = sizes[i].size;
            if (sizes[i].size) {
                sprintf(buf, "R%d", idx);
                names[INGRESS].emplace(buf, Slice(regs[idx], 0, sizes[i].size - 1));
                names[EGRESS].emplace(buf, Slice(regs[idx], 0, sizes[i].size - 1));
                sprintf(buf, "%s%d", sizes[i].code, j);
                names[INGRESS].emplace(buf, Slice(regs[idx], 0, sizes[i].size - 1));
                names[EGRESS].emplace(buf, Slice(regs[idx], 0, sizes[i].size - 1)); } } }
    assert(idx == NUM_PHV_REGS);
}

void Phv::start(int lineno, VECTOR(value_t) args) {
    if (args.size > 1 ||
        (args.size == 1 && args[0] != "ingress" && args[0] != "egress"))
        error(lineno, "phv can only be ingress or egress");
}

int Phv::addreg(gress_t gress, const char *name, const value_t &what) {
    if (!CHECKTYPE2M(what, tSTR, tCMD, "register or slice"))
        return -1;
    auto reg = what.type == tSTR ? what.s : what[0].s;
    if (const Slice *sl = get(gress, reg)) {
        if (what.type == tSTR) {
            names[gress].emplace(name, *sl);
            return 0; }
        if (what.vec.size != 2) {
            error(what.lineno, "Syntax error, expecting bit or slice");
            return -1; }
        if (!CHECKTYPE2M(what[1], tINT, tRANGE, "bit or slice")) return -1;
        if (what[1].type == tINT)
            sl = &names[gress].emplace(name, Slice(*sl, what[1].i, what[1].i)).first->second;
        else
            sl = &names[gress].emplace(name, Slice(*sl, what[1].lo, what[1].hi)).first->second;
        if (!sl->valid) {
            error(what.lineno, "Invalid register slice");
            return -1; }
        return 0;
    } else {
        error(what.lineno, "No register named %s", reg);
        return -1; }
}

void Phv::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    gress_t gress = (args.size == 1 && args[0] == "egress") ? EGRESS : INGRESS;
    for (auto &kv : data.map) {
        if (!CHECKTYPE(kv.key, tSTR)) continue;
        if (get(gress, kv.key.s) || (!args.size && get(EGRESS, kv.key.s))) {
            error(kv.key.lineno, "Duplicate phv name '%s'", kv.key.s);
            continue; }
        if (!addreg(gress, kv.key.s, kv.value) && args.size == 0)
            addreg(EGRESS, kv.key.s, kv.value);
    }
}

Phv::Ref::Ref(gress_t g, const value_t &n) : gress(g), lo(-1), hi(-1), lineno(n.lineno) {
    if (CHECKTYPE2M(n, tSTR, tCMD, "expecting phv or register reference or slice")) {
	if (n.type == tSTR) {
	    name_ = n.s;
	} else {
	    name_ = n[0].s;
	    if (PCHECKTYPE2M(n.vec.size != 2, n[1], tINT, tRANGE, "invalid slice")) {
		if (n[1].type == tINT)
		    lo = hi = n[1].i;
		else {
		    lo = n[1].lo;
		    hi = n[1].hi;
		    if (lo > hi) {
			lo = n[1].hi;
			hi = n[1].lo; } } } } }
}

void Phv::Ref::dbprint(std::ostream &out) const {
    out << name_;
    if (lo >= 0) { 
        out << '(' << lo;
        if (hi != lo) out << ".." << hi;
        out << ')'; }
    Slice sl(**this);
    if (sl.valid) {
        out << "[R" << sl.reg.index;
        if (sl.lo != 0 || sl.hi != sl.reg.size-1) {
            out << '(' << sl.lo;
            if (sl.hi != sl.lo) out << ".." << sl.hi;
            out << ')'; }
        out << ']'; }
}
