#ifndef _TOFINO_MAU_FIELD_USE_H_
#define _TOFINO_MAU_FIELD_USE_H_

#include <iostream>
#include "mau_visitor.h"
#include "lib/bitvec.h"
#include "tofino/ir/tofino_write_context.h"

class FieldUse : public MauInspector, TofinoWriteContext {
    vector<cstring>             field_names;
    map<cstring, int>           field_index;
    struct rw_t { bitvec reads, writes; };
    map<cstring, rw_t>          table_use;
    void access_field(cstring field);
    bool preorder(const IR::MAU::Table *t) override;
    bool preorder(const IR::Member *f) override;
    bool preorder(const IR::HeaderStackItemRef *f) override;
    bool preorder(const IR::TempVar *t) override;
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


#endif /* _TOFINO_MAU_FIELD_USE_H_ */
