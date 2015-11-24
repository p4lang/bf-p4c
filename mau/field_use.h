#ifndef _field_use_h_
#define _field_use_h_

#include "mau_visitor.h"
#include "lib/bitvec.h"
#include <iostream>

class FieldUse : public MauInspector, P4WriteContext {
    vector<cstring>		field_names;
    map<cstring, int>		field_index;
    struct rw_t { bitvec reads, writes; };
    map<cstring, rw_t>		table_use;
    void access_field(cstring field);
    bool preorder(const IR::MAU::Table *t) override;
    bool preorder(const IR::FieldRef *f) override;
    bool preorder(const IR::Index *f) override;
    friend std::ostream &operator<<(std::ostream &, const FieldUse &);
public:
    FieldUse() { visitDagOnce = false; }
    bitvec tables_modify(const IR::MAU::TableSeq *t) const;
    bitvec tables_access(const IR::MAU::TableSeq *t) const;
    bitvec tables_modify(const IR::MAU::Table *t) const;
    bitvec tables_access(const IR::MAU::Table *t) const;
    bitvec table_reads(const IR::MAU::Table *t) const {
	return table_use.at(t->name).reads; }
    bitvec table_writes(const IR::MAU::Table *t) const {
	return table_use.at(t->name).writes; }
    void cloning_table(cstring name, cstring newname) {
	assert(table_use.count(name) && !table_use.count(newname));
	table_use[newname] = table_use[name]; }
};


#endif /* _field_use_h_ */
