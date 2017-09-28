#ifndef BF_P4C_MAU_FIELD_USE_H_
#define BF_P4C_MAU_FIELD_USE_H_

#include <iostream>
#include "mau_visitor.h"
#include "lib/bitvec.h"
#include "lib/safe_vector.h"
#include "bf-p4c/ir/tofino_write_context.h"

class FieldUse : public MauInspector, TofinoWriteContext {
    safe_vector<cstring>        field_names;
    std::map<cstring, int>      field_index;
    struct rw_t { bitvec reads, writes; };
    std::map<cstring, rw_t>     table_use;
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


#endif /* BF_P4C_MAU_FIELD_USE_H_ */
