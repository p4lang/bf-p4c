#ifndef _FIELD_DEFUSE_H_
#define _FIELD_DEFUSE_H_

#include <iostream>
#include "ir/ir.h"
#include "lib/bitvec.h"
#include "lib/ltbitmatrix.h"
#include "tofino/phv/phv_fields.h"

class FieldDefUse : public ControlFlowVisitor, Inspector, P4WriteContext {
    const PhvInfo               &phv;
    vector<bitvec>              &conflict;
    struct info {
        const PhvInfo::Info             *field = 0;
        set<const IR::MAU::Table *>     def, use;
    };
    map<int, info>          defuse;
    // class Init;

    profile_t init_apply(const IR::Node *root) override;
    void check_conflicts(const info &read, int when);
    info &field(const PhvInfo::Info *);
    void access_field(const PhvInfo::Info *);
    bool preorder(const IR::Tofino::Parser *p) override;
    bool preorder(const IR::Tofino::Deparser *p) override;
    bool preorder(const IR::FieldRef *f) override;
    bool preorder(const IR::HeaderSliceRef *h) override;
    bool preorder(const IR::HeaderStackItemRef *f) override;
    FieldDefUse *clone() const override { return new FieldDefUse(*this); }
    void flow_merge(Visitor &) override;
    FieldDefUse(const FieldDefUse &) = default;
    FieldDefUse(FieldDefUse &&) = default;
    friend std::ostream &operator<<(std::ostream &, const FieldDefUse &);

 public:
    explicit FieldDefUse(const PhvInfo &p)
    : phv(p), conflict(*new vector<bitvec>(phv.num_fields())) { visitDagOnce = false; }
    const vector<bitvec> &conflicts() { return conflict; }
};


#endif /* _FIELD_DEFUSE_H_ */
