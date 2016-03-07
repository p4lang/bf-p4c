#include "field_defuse.h"
#include "lib/hex.h"
#include "lib/log.h"
#include "lib/map.h"
#include "lib/range.h"

#if 0
class FieldDefUse::Init : public Inspector {
    FieldDefUse &self;
    void add_field(cstring field);
    bool preorder(const IR::Member *f) override { add_field(self.phv.field(f)); return false; }
    bool preorder(const IR::HeaderStackItemRef *f) override {
        /*add_field(f->toString());*/ return false; }
 public:
    explicit Init(FieldDefUse &s) : self(s) {}
};

void FieldDefUse::Init::add_field(cstring field) {
    assert(field);
    auto *info = self.phv.field(field);
    if (info && !self.defuse.count(field)) {
        self.defuse[field].name = field;
        self.defuse[field].id = info->id;
        self.defuse[field].def.insert(nullptr); }
}
#endif

Visitor::profile_t FieldDefUse::init_apply(const IR::Node *root) {
    auto rv = Inspector::init_apply(root);
    // root->apply(Init(*this));
    return rv;
}

void FieldDefUse::check_conflicts(const info &read, int when) {
    int firstdef = INT_MAX;
    for (auto def : read.def) {
        if (!def) firstdef = -1;
        else if (def->logical_order() < firstdef)
            firstdef = def->logical_order(); }
    for (auto &other : Values(defuse)) {
        if (other.field == read.field) continue;
        for (auto use : other.use) {
            int use_when = use ? use->logical_order() : INT_MAX;
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

void FieldDefUse::access_field(const PhvInfo::Info *f) {
    if (auto table = findContext<IR::MAU::Table>()) {
        auto &info = field(f);
        if (isWrite()) {
            LOG3("FieldDefUse(" << (void *)this << "): table " << table->name <<
                 " writing " << f->name);
            info.def.clear();
            info.def.insert(table);
        } else {
            LOG3("FieldDefUse(" << (void *)this << "): table " << table->name <<
                 " reading " << f->name);
            info.use.clear();
            info.use.insert(table);
            check_conflicts(info, table->logical_order()); }
    } else {
        assert(0); }
}

bool FieldDefUse::preorder(const IR::Member *f) {
    if (auto *field = phv.field(f))
        access_field(field);
    return false;
}

bool FieldDefUse::preorder(const IR::HeaderSliceRef *h) {
  access_field(phv.field(h));
  return false;
}

bool FieldDefUse::preorder(const IR::HeaderStackItemRef *) {
    // access_field(f->toString());
    return false;
}

bool FieldDefUse::preorder(const IR::Tofino::Parser *) {
    return false;
}

static const char *output_metadata[2][4] = { {
    "ig_intr_md_for_tm", "ig_intr_md_for_mb", 0,
}, {
    "eg_intr_md_for_deparser", "eg_intr_md_for_mb", "eg_intr_md_for_oport", 0,
} };

bool FieldDefUse::preorder(const IR::Tofino::Deparser *d) {
    for (auto hdr : output_metadata[d->gress]) {
        if (!hdr) break;
        if (auto hdr_fields = phv.header(hdr)) {
            for (int id : Range(hdr_fields->first, hdr_fields->second)) {
                auto *f = phv.field(id);
                if (defuse.count(f->id)) {
                    auto &info = defuse[f->id];
                    info.use.clear();
                    info.use.insert(nullptr);
                    check_conflicts(info, INT_MAX); } } } }
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
