#ifndef _field_use_h_
#define _field_use_h_

#include "ir/visitor.h"
#include "lib/bitvec.h"
#include <iostream>

class FieldUse : public Inspector, P4WriteContext {
    vector<cstring>		field_names;
    map<cstring, int>		field_index;
    map<cstring, bitvec[2]>	table_use;
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
	return table_use.at(t->name)[0]; }
    bitvec table_writes(const IR::MAU::Table *t) const {
	return table_use.at(t->name)[1]; }
    void cloning_table(cstring name, cstring newname) {
	assert(table_use.count(name) && !table_use.count(newname));
	table_use[newname][0] = table_use[name][0];
	table_use[newname][1] = table_use[name][1]; }
};


#endif /* _field_use_h_ */
