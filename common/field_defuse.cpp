#include "field_defuse.h"
#include "lib/hex.h"
#include "lib/log.h"
#include "lib/map.h"
#include "lib/range.h"

Visitor::profile_t FieldDefUse::init_apply(const IR::Node *root) {
    auto rv = Inspector::init_apply(root);
    conflict.clear();
    conflict.resize(phv.num_fields());
    return rv;
}

void FieldDefUse::check_conflicts(const info &read, int when) {
    int firstdef = INT_MAX;
    for (auto def : read.def) {
        if (!def) firstdef = -1;
        else if (def->stage() < firstdef)
            firstdef = def->stage(); }
    for (auto &other : Values(defuse)) {
        if (other.field == read.field) continue;
        for (auto use : other.use) {
            int use_when = use ? use->stage() : INT_MAX;
            if (use_when > firstdef && use_when <= when) {
                    conflict[read.field->id][other.field->id] = true;
                    conflict[other.field->id][read.field->id] = true; } } }
}

FieldDefUse::info &FieldDefUse::field(const PhvInfo::Info *f) {
    auto &info = defuse[f->id];
    assert(!info.field || info.field == f);
    info.field = f;
    return info;
}

void FieldDefUse::read(const PhvInfo::Info *f, const IR::MAU::Table *table) {
    if (!f) return;
    auto &info = field(f);
    LOG3("FieldDefUse(" << (void *)this << "): " << (table ? "table " : "deparser ") <<
         (table ? table->name : "") << " reading " << f->name);
    info.use.clear();
    info.use.insert(table);
    check_conflicts(info, table ? table->stage() : INT_MAX);
}
void FieldDefUse::read(const IR::HeaderRef *hr, const IR::MAU::Table *table) {
    if (!hr) return;
    for (int id : Range(*phv.header(hr)))
        read(phv.field(id), table);
    read(phv.field(hr->toString() + ".$valid"), table);
}
void FieldDefUse::write(const PhvInfo::Info *f, const IR::MAU::Table *table) {
    if (!f) return;
    auto &info = field(f);
    LOG3("FieldDefUse(" << (void *)this << "): " << (table ? "table " : "parser ") <<
         (table ? table->name : "") << " writing " << f->name);
    info.def.clear();
    info.def.insert(table);
    if (!table) {
        // parser can't rewrite PHV (it ors), so need to treat it as a read too
        info.use.clear();
        info.use.insert(table);
        check_conflicts(info, -1); }
}
void FieldDefUse::write(const IR::HeaderRef *hr, const IR::MAU::Table *table) {
    if (!hr) return;
    for (int id : Range(*phv.header(hr)))
        write(phv.field(id), table);
    write(phv.field(hr->toString() + ".$valid"), table);
}

bool FieldDefUse::preorder(const IR::Expression *e) {
    auto *f = phv.field(e);
    auto *hr = e->to<IR::HeaderRef>();
    if (!f && !hr) return true;
    if (auto table = findContext<IR::MAU::Table>()) {
        if (isWrite()) {
            write(f, table);
            write(hr, table);
        } else {
            read(f, table);
            read(hr, table); }
    } else if (findContext<IR::Tofino::ParserState>()) {
        write(f, nullptr);
        write(hr, nullptr);
    } else if (findContext<IR::Tofino::Deparser>()) {
        read(f, nullptr);
        read(hr, nullptr);
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

std::ostream &operator<<(std::ostream &out, const FieldDefUse &a) {
    for (auto &i : Values(a.defuse)) {
        out << i.field->name << ": def:";
        const char *sep = "";
        for (auto t : i.def) {
            out << sep << (t ? t->name : "<init>");
            if (t && t->logical_id >= 0)
                out << '(' << t->gress << ' ' << hex(t->logical_id) << ')';
            sep = ","; }
        out << " use:";
        sep = "";
        for (auto t : i.use) {
            out << sep << (t ? t->name : "<fini>");
            if (t && t->logical_id >= 0)
                out << '(' << t->gress << ' ' << hex(t->logical_id) << ')';
            sep = ","; }
        out << std::endl; }
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
    return out;
}

struct code { int id; };
std::ostream &operator<<(std::ostream &out, const code &c) {
    return out << char('a' + c.id/26) << char('a' + c.id%26);
}

void FieldDefUse::end_apply(const IR::Node *) {
    if (!LOGGING(2)) return;
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
