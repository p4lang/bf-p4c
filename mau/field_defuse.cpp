#include "field_defuse.h"
#include "lib/log.h"
#include "lib/map.h"
#include "lib/hex.h"

class FieldDefUse::Init : public Inspector {
    FieldDefUse &self;
    void add_field(cstring field);
    bool preorder(const IR::FieldRef *f) override { add_field(f->asString()); return false; }
    bool preorder(const IR::Index *f) override { add_field(f->asString()); return false; }
public:
    Init(FieldDefUse &s) : self(s) {}
};

void FieldDefUse::Init::add_field(cstring field) {
    assert(field);
    auto *info = self.phv.field(field);
    if (info && !self.defuse.count(field)) {
	self.defuse[field].name = field;
	self.defuse[field].id = info->id;
	self.defuse[field].def.insert(nullptr); }
}

Visitor::profile_t FieldDefUse::init_apply(const IR::Node *root) {
    auto rv = Inspector::init_apply(root);
    root->apply(Init(*this));
    return rv;
}

void FieldDefUse::access_field(cstring field) {
    auto *info = phv.field(field);
    if (!info) return; // FIXME
    if (auto table = findContext<IR::MAU::Table>()) {
	auto &info = defuse.at(field);
	assert(info.name == field);
	assert(info.id == phv.field(field)->id);
	if (isWrite()) {
	    LOG3("FieldDefUse(" << (void *)this << "): table " << table->name <<
		 " writing " << field);
	    info.def.clear();
	    info.def.insert(table);
	} else {
	    LOG3("FieldDefUse(" << (void *)this << "): table " << table->name <<
		 " reading " << field);
	    info.use.clear();
	    info.use.insert(table);
	    int firstdef = INT_MAX;
	    for (auto def : info.def) {
		if (!def) firstdef = -1;
		else if (def->logical_order() < firstdef)
		    firstdef = def->logical_order(); }
	    for (auto &other : Values(defuse)) {
		if (other.id == info.id) continue;
		for (auto use : other.use)
		    if (use->logical_order() > firstdef &&
			use->logical_order() <= table->logical_order()) {
			    conflict[info.id][other.id] = true;
			    conflict[other.id][info.id] = true; } } }
    } else
	assert(0);
}

bool FieldDefUse::preorder(const IR::FieldRef *f) {
    access_field(f->asString());
    return false;
}

bool FieldDefUse::preorder(const IR::Index *f) {
    access_field(f->asString());
    return false;
}

void FieldDefUse::flow_merge(Visitor &a_) {
    FieldDefUse &a = dynamic_cast<FieldDefUse &>(a_);
    LOG3("FieldDefUse(" << (void *)this << "): merging " << (void *)&a);
    for (auto &i : Values(a.defuse)) {
	assert(defuse.at(i.name).name == i.name);
	assert(defuse.at(i.name).id == i.id);
	defuse.at(i.name).def.insert(i.def.begin(), i.def.end());
	defuse.at(i.name).use.insert(i.use.begin(), i.use.end()); }
}

std::ostream &operator<<(std::ostream &out, const FieldDefUse &a) {
    for (auto &i : Values(a.defuse)) {
	out << i.name << ": def:";
	const char *sep = "";
	for (auto t : i.def) {
	    out << sep << (t ? t->name : "<init>");
	    if (t && t->logical_id >= 0)
		out << '(' << t->gress << ' ' << hex(t->logical_id) << ')';
	    sep = ","; }
	out << " use:";
	sep = "";
	for (auto t : i.use) {
	    out << sep << t->name;
	    if (t && t->logical_id >= 0)
		out << '(' << t->gress << ' ' << hex(t->logical_id) << ')';
	    sep = ","; }
	out << std::endl; }
    int maxw = 0;
    for (int i = 0; i < a.phv.num_fields(); i++) {
	int sz = a.phv.field(i)->name.size();
	if (!a.defuse.count(a.phv.field(i)->name))
	    sz += 2;
	if (maxw < sz) maxw = sz; }
    for (int i = 0; i < a.phv.num_fields(); i++) {
	if (!a.defuse.count(a.phv.field(i)->name))
	    out << '[' << std::setw(maxw-2) << std::left << a.phv.field(i)->name << ']';
	else
	    out << std::setw(maxw) << std::left << a.phv.field(i)->name;
	out << ' ';
	for (int j = 0; j <= i; j++)
	    out << (a.conflict[i][j] ? '1' : '0');
	out << std::endl; }
    return out;
}
