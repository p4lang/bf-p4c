#include "misc.h"
#include "phv.h"
#include <iostream>

Phv Phv::phv;
const Phv::Register Phv::Slice::invalid = { 0, 0 };

static bitvec tagalong_group(int n) {
    bitvec rv;
    rv.setrange(256+n*4, 4);
    rv.setrange(288+n*4, 4);
    rv.setrange(320+n*6, 6);
    return rv; }
const bitvec Phv::tagalong_groups[8] = { tagalong_group(0), tagalong_group(1), tagalong_group(2),
    tagalong_group(3), tagalong_group(4), tagalong_group(5), tagalong_group(6), tagalong_group(7) };

Phv::Phv() : Section("phv") {
    static const struct { char code[4]; unsigned size, count; } sizes[] =
        { { "W", 32, 64 }, { "B", 8, 64 }, { "H", 16, 96 }, { "", 0, 32 },
          { "TW", 32, 32 }, { "TB", 8, 32 }, { "TH", 16, 48 } };
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
        if (sl->valid) {
            phv_use[gress][sl->reg.index] = true;
            user_defined[sl->reg.index].first = gress;
            user_defined[sl->reg.index].second.push_back(name); }
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

void Phv::output_names(json::map &out) {
    for (auto &slot : phv.user_defined)
        out[std::to_string(slot.first)] = std::string(1, "IE"[slot.second.first])
                + " [" + join(slot.second.second, ", ") + "]";
}

Phv::Ref::Ref(gress_t g, const value_t &n) : gress(g), lo(-1), hi(-1), lineno(n.lineno) {
    if (CHECKTYPE2M(n, tSTR, tCMD, "phv or register reference or slice")) {
        if (n.type == tSTR) {
            name_ = n.s;
        } else {
            name_ = n[0].s;
            if (PCHECKTYPE2M(n.vec.size == 2, n[1], tINT, tRANGE, "register slice")) {
                if (n[1].type == tINT)
                    lo = hi = n[1].i;
                else {
                    lo = n[1].lo;
                    hi = n[1].hi;
                    if (lo > hi) {
                        lo = n[1].hi;
                        hi = n[1].lo; } } } } }
}

Phv::Ref::Ref(const Phv::Register &r) : gress(EGRESS), lo(-1), hi(-1), lineno(-1) {
    char buf[8];
    sprintf(buf, "R%d", r.index);
    name_ = buf;
}

bool Phv::Ref::merge(const Phv::Ref &r) {
    if (r.name_ != name_ || r.gress != gress) return false;
    if (lo < 0) return true;
    if (r.lo < 0) {
        lo = hi = -1;
        return true; }
    if (r.hi+1 < lo || hi+1 < r.lo) return false;
    if (r.lo < lo) lo = r.lo;
    if (r.hi > hi) {
        lineno = r.lineno;
        hi = r.hi; }
    return true;
}

void merge_phv_vec(std::vector<Phv::Ref> &vec, const Phv::Ref &r) {
    int merged = -1;
    for (int i = 0; (unsigned)i < vec.size(); i++) {
        if (merged >= 0) {
            if (vec[merged].merge(vec[i])) {
                vec.erase(vec.begin()+i);
                --i; }
        } else if (vec[i].merge(r))
            merged = i; }
    if (merged < 0)
        vec.push_back(r);
}

void merge_phv_vec(std::vector<Phv::Ref> &v1, const std::vector<Phv::Ref> &v2) {
    for (auto &r : v2)
        merge_phv_vec(v1, r);
}

std::vector<Phv::Ref> split_phv_bytes(const Phv::Ref &r) {
    std::vector<Phv::Ref> rv;
    const auto &sl = *r;
    for (unsigned byte = sl.lo/8U; byte <= sl.hi/8U; byte++) {
        int lo = byte*8 - sl.lo;
        int hi = lo + 7;
        if (lo < 0) lo = 0;
        if (hi >= (int)sl.size()) hi = sl.size() - 1;
        rv.emplace_back(r, lo, hi); }
    return rv;
}

std::vector<Phv::Ref> split_phv_bytes(const std::vector<Phv::Ref> &v) {
    std::vector<Phv::Ref> rv;
    for (auto &r : v)
        append(rv, split_phv_bytes(r));
    return rv;
}

void Phv::Ref::dbprint(std::ostream &out) const {
    out << name_;
    if (lo >= 0) {
        out << '(' << lo;
        if (hi != lo) out << ".." << hi;
        out << ')'; }
    Slice sl(**this);
    if (sl.valid) {
        out << '[';
        sl.dbprint(out);
        out << ']'; }
}

void Phv::Slice::dbprint(std::ostream &out) const {
    if (valid) {
        out << "R" << reg.index;
        if (lo != 0 || hi != reg.size-1) {
            out << '(' << lo;
            if (hi != lo) out << ".." << hi;
            out << ')'; }
    } else
        out << "<invalid>";
}

std::string Phv::db_regset(const bitvec &s) {
    std::string rv;
    for (int reg : s) {
        char tmp[16];
        if (!rv.empty()) rv += ", ";
        sprintf(tmp, "R%d", reg);
        rv += tmp; }
    return rv;
}
