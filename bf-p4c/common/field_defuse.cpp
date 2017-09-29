#include "field_defuse.h"
#include "lib/hex.h"
#include "lib/log.h"
#include "lib/map.h"
#include "lib/range.h"

static std::ostream &operator<<(std::ostream &out, const FieldDefUse::locpair &loc) {
    return out << *loc.second << " [" << loc.second->id << " in " << *loc.first << "]";
}

class FieldDefUse::ClearBeforeEgress : public Inspector, TofinoWriteContext {
    FieldDefUse &self;
    bool preorder(const IR::Expression *e) override {
        auto *f = self.phv.field(e);
        if (f && isWrite()) {
            LOG4("CLEARING FIELD: " << e);
            self.defuse.erase(f->id);
            return false; }
        if (e->is<IR::Member>())
            return false;
        return true; }
    bool preorder(const IR::HeaderRef *hr) override {
        for (int id : self.phv.struct_info(hr).field_ids()) {
            if (isWrite()) {
                self.defuse.erase(id);
                LOG4("CLEARING HEADER REF: " << hr); } }
        return false; }
 public:
    explicit ClearBeforeEgress(FieldDefUse &self) : self(self) {}
};

Visitor::profile_t FieldDefUse::init_apply(const IR::Node *root) {
    auto rv = Inspector::init_apply(root);
    conflict.clear();
    defs.clear();
    uses.clear();
    defuse.clear();
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

void FieldDefUse::read(const PhvInfo::Field *f, const IR::BFN::Unit *unit,
                       const IR::Expression *e) {
    if (!f) return;
    auto &info = field(f);
    LOG3("FieldDefUse(" << (void *)this << "): " << DBPrint::Brief << *unit <<
         " reading " << f->name << " [" << e->id << "]");
    info.use.clear();
    locpair use(unit, e);
    info.use.emplace(use);
    located_uses[f->id].emplace(use);
    check_conflicts(info, unit->stage());
    for (auto def : info.def) {
        LOG4("  " << use << " uses " << def);
        uses[def].emplace(use);
        defs[use].emplace(def); }
}
void FieldDefUse::read(const IR::HeaderRef *hr, const IR::BFN::Unit *unit,
                       const IR::Expression *e) {
    if (!hr) return;
    PhvInfo::StructInfo info = phv.struct_info(hr);
    for (int id : info.field_ids())
        read(phv.field(id), unit, e);
    if (!info.metadata)
        read(phv.field(hr->toString() + ".$valid"), unit, e);
}
void FieldDefUse::write(const PhvInfo::Field *f, const IR::BFN::Unit *unit,
                        const IR::Expression *e, bool partial) {
    if (!f) return;
    auto &info = field(f);
    LOG3("FieldDefUse(" << (void *)this << "): " << DBPrint::Brief << *unit <<
         " writing " << f->name << " [" << e->id << "]" << (partial ? " (partial)" : ""));
    if (unit->is<IR::BFN::ParserState>()) {
        // parser can't rewrite PHV (it ors), so need to treat it as a read for conflicts, but
        // we don't mark it as a use of previous writes, and don't clobber those previous writes.
        if (!partial)
            info.use.clear();
        info.use.emplace(unit, e);
        check_conflicts(info, unit->stage());
        for (auto def : info.def)
            LOG4("  " << e << " [" << e->id << "]" << " in " << *unit << " combines with " <<
                 def.second << " from " << *def.first << " [" << def.first->id << "]");
    } else if (!partial) {
        info.def.clear(); }
    info.def.emplace(unit, e);
    located_defs[f->id].emplace(unit, e);
}
void FieldDefUse::write(const IR::HeaderRef *hr, const IR::BFN::Unit *unit,
                        const IR::Expression *e) {
    if (!hr) return;
    PhvInfo::StructInfo info = phv.struct_info(hr);
    for (int id : info.field_ids())
        write(phv.field(id), unit, e);
    if (!info.metadata)
        write(phv.field(hr->toString() + ".$valid"), unit, e);
}

bool FieldDefUse::preorder(const IR::BFN::Parser *p) {
    if (p->gress == EGRESS) {
        /* after processing the ingress pipe, before proceeding to the egress pipe, we
         * clear everything mentioned in the egress parser.  We want to ensure that nothing
         * that might be set by the egress parser is considered for bridging -- if it might
         * be set but isn't, it should be left unset in the egress pipe (not bridged) */
        p->apply(ClearBeforeEgress(*this)); }
    return true;
}

bool FieldDefUse::preorder(const IR::Expression *e) {
    bitrange bits;
    auto *f = phv.field(e, &bits);
    auto *hr = e->to<IR::HeaderRef>();

    // Prevent visiting HeaderRefs in Members when PHV lookup fails, eg. for
    // $valid fields before allocatePOV.
    if (!f && e->is<IR::Member>()) return false;
    if (!f && !hr) return true;

    if (auto unit = findContext<IR::BFN::Unit>()) {
        if (isWrite()) {
           /* this is a temporary fix to make sure that we dont overwrite the 
            * previous assignment. This needs to be enhanced to deal with range
            * being non-contiguous and overwrite if the range is contiguous
            */
            bool partial = (f && (bits.lo != 0 || bits.hi != f->size-1));
            write(f, unit, e, partial);
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
    switch (c.id/26/26) {
    case 0:
        return out << char('a' + c.id/26) << char('a' + c.id%26);
    case 1:
        return out << char('A' + c.id/26 - 26) << char('a' + c.id%26);
    case 2:
        return out << char('a' + c.id/26 - 52) << char('A' + c.id%26);
    case 3:
        return out << char('A' + c.id/26 - 78) << char('A' + c.id%26);
    default:
        return out << "??"; }
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
            std::clog << (conflict[i][j] ? '1' : '0');
        if (count < 40)
            std::clog << " " << phv.field(i)->name; }
    std::clog << std::endl;
}
