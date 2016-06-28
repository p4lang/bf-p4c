#include "field_defuse.h"
#include "lib/hex.h"
#include "lib/log.h"
#include "lib/map.h"
#include "lib/range.h"

Visitor::profile_t FieldDefUse::init_apply(const IR::Node *root) {
    auto rv = Inspector::init_apply(root);
    conflict.clear();
    uses.clear();
    return rv;
}

void FieldDefUse::check_conflicts(const info &read, int when) {
    int firstdef = INT_MAX;
    for (auto def : read.def)
        firstdef = std::min(firstdef, def.first->stage());
    for (auto &other : Values(defuse)) {
        if (other.field == read.field) continue;
        for (auto use : other.use) {
            int use_when = use.first->stage();
            if (use_when >= firstdef && use_when <= when)
                conflict(read.field->id, other.field->id) = true; } }
}

FieldDefUse::info &FieldDefUse::field(const PhvInfo::Field *f) {
    auto &info = defuse[f->id];
    assert(!info.field || info.field == f);
    info.field = f;
    return info;
}

void FieldDefUse::read(const PhvInfo::Field *f, const IR::Tofino::Unit *unit,
                       const IR::Expression *e) {
    if (!f) return;
    auto &info = field(f);
    LOG3("FieldDefUse(" << (void *)this << "): " << DBPrint::Brief << *unit <<
         " reading " << f->name);
    info.use.clear();
    info.use.emplace(unit, e);
    check_conflicts(info, unit->stage());
    for (auto def : info.def) {
        LOG4("  " << e << " in " << *unit << " uses " << def.second << " from " << *def.first);
        uses[def.second].emplace(unit, e); }
}
void FieldDefUse::read(const IR::HeaderRef *hr, const IR::Tofino::Unit *unit,
                       const IR::Expression *e) {
    if (!hr) return;
    for (int id : Range(*phv.header(hr)))
        read(phv.field(id), unit, e);
    read(phv.field(hr->toString() + ".$valid"), unit, e);
}
void FieldDefUse::write(const PhvInfo::Field *f, const IR::Tofino::Unit *unit,
                        const IR::Expression *e) {
    if (!f) return;
    auto &info = field(f);
    LOG3("FieldDefUse(" << (void *)this << "): " << DBPrint::Brief << *unit <<
         " writing " << f->name);
    if (unit->is<IR::Tofino::ParserState>()) {
        // parser can't rewrite PHV (it ors), so need to treat it as a read for conflicts, but
        // we don't mark it as a use of previous writes, and don't clobber those previous writes.
        info.use.clear();
        info.use.emplace(unit, e);
        check_conflicts(info, unit->stage());
    } else {
        info.def.clear(); }
    info.def.emplace(unit, e);
    uses[e];
}
void FieldDefUse::write(const IR::HeaderRef *hr, const IR::Tofino::Unit *unit,
                        const IR::Expression *e) {
    if (!hr) return;
    for (int id : Range(*phv.header(hr)))
        write(phv.field(id), unit, e);
    write(phv.field(hr->toString() + ".$valid"), unit, e);
}

bool FieldDefUse::preorder(const IR::Expression *e) {
    auto *f = phv.field(e);
    auto *hr = e->to<IR::HeaderRef>();
    if (!f && !hr) return true;
    if (auto unit = findContext<IR::Tofino::Unit>()) {
        if (unit->is<IR::Tofino::ParserState>() || isWrite()) {
            write(f, unit, e);
            write(hr, unit, e);
        } else {
            read(f, unit, e);
            read(hr, unit, e); }
    } else {
        assert(0); }
    return false;
}

void FieldDefUse::flow_merge(Visitor &a_) {
    FieldDefUse &a = dynamic_cast<FieldDefUse &>(a_);
    LOG3("FieldDefUse(" << (void *)this << "): merging " << (void *)&a);
    for (auto &i : Values(a.defuse)) {
        auto &info = field(i.field);
        info.def.insert(i.def.begin(), i.def.end());
        info.use.insert(i.use.begin(), i.use.end()); }
}

std::ostream &operator<<(std::ostream &out, const FieldDefUse::info &i) {
    out << DBPrint::Brief;
    out << i.field->name << ": def:";
    const char *sep = "";
    for (auto u : i.def) {
        out << sep << *u.first;
        sep = ","; }
    out << " use:";
    sep = "";
    for (auto u : i.use) {
        out << sep << *u.first;
        sep = ","; }
    out << std::endl;
    out << DBPrint::Reset;
    return out;
}
void dump(const FieldDefUse::info &a) { std::cout << a; }

std::ostream &operator<<(std::ostream &out, const FieldDefUse &a) {
    for (auto &i : Values(a.defuse))
        out << i;
    out << DBPrint::Brief;
    unsigned maxw = 0;
    for (unsigned i = 0; i < a.phv.num_fields(); i++) {
        unsigned sz = a.phv.field(i)->name.size();
        if (!a.defuse.count(i))
            sz += 2;
        if (maxw < sz) maxw = sz; }
    for (unsigned i = 0; i < a.phv.num_fields(); i++) {
        if (!a.defuse.count(i))
            out << '[' << std::setw(maxw-2) << std::left << a.phv.field(i)->name << ']';
        else
            out << std::setw(maxw) << std::left << a.phv.field(i)->name;
        out << ' ';
        for (unsigned j = 0; j <= i; j++)
            out << (a.conflict[i][j] ? '1' : '0');
        out << std::endl; }
    out << DBPrint::Reset;
    return out;
}
void dump(const FieldDefUse &a) { std::cout << a; }

struct code { int id; };
std::ostream &operator<<(std::ostream &out, const code &c) {
    return out << char('a' + c.id/26) << char('a' + c.id%26);
}

void FieldDefUse::end_apply(const IR::Node *) {
    if (!LOGGING(2)) return;
    LOG2("FieldDefUse result:");
    int count = phv.num_fields();
    if (count >= 40) {
        for (auto f : phv)
            std::clog << code{f.id} << " " << f.name << std::endl; }
    std::clog << "  ";
    for (int i = 0; i < count; i++)
        std::clog << char('a' + i/26);
    std::clog << "\n  ";
    for (int i = 0; i < count; i++)
        std::clog << char('a' + i%26);
    for (int i = 0; i < count; i++) {
        std::clog << '\n' << code{i};
        for (int j = 0; j < count; j++)
            std::clog << char('0' + conflict[i][j]);
        if (count < 40)
            std::clog << " " << phv.field(i)->name; }
    std::clog << std::endl;
}
