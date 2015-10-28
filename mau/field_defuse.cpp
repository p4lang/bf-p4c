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
    if (!self.field_index->count(field)) {
	int idx = self.field_names->size();
	self.field_index->emplace(field, idx);
	self.field_names->push_back(field);
	self.defuse[field].name = field;
	self.defuse[field].id = idx;
	self.defuse[field].def.insert(nullptr); }
}

Visitor::profile_t FieldDefUse::init_apply(const IR::Node *root) {
    auto rv = Inspector::init_apply(root);
    root->apply(Init(*this));
    return rv;
}

void FieldDefUse::access_field(cstring field) {
    if (auto table = findContext<IR::MAU::Table>()) {
	auto &info = defuse.at(field);
	assert(info.name == field);
	assert(info.id == field_index->at(field));
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
	}
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
    return out;
}
