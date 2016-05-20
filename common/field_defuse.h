#ifndef _FIELD_DEFUSE_H_
#define _FIELD_DEFUSE_H_

#include <iostream>
#include "ir/ir.h"
#include "lib/symbitmatrix.h"
#include "lib/ltbitmatrix.h"
#include "tofino/phv/phv_fields.h"

class FieldDefUse : public ControlFlowVisitor, Inspector, P4WriteContext {
    const PhvInfo       &phv;
    SymBitMatrix        &conflict;
    struct info {
        const PhvInfo::Info             *field = 0;
        set<const IR::MAU::Table *>     def, use;
    };
    std::unordered_map<int, info> defuse;
    // class Init;

    profile_t init_apply(const IR::Node *root) override;
    void end_apply(const IR::Node *root) override;
    void check_conflicts(const info &read, int when);
    void read(const PhvInfo::Info *, const IR::MAU::Table *);
    void read(const IR::HeaderRef *, const IR::MAU::Table *);
    void write(const PhvInfo::Info *, const IR::MAU::Table *);
    void write(const IR::HeaderRef *, const IR::MAU::Table *);
    info &field(const PhvInfo::Info *);
    info &field(int id) { return field(phv.field(id)); }
    void access_field(const PhvInfo::Info *);
    // bool preorder(const IR::Tofino::Parser *p) override;
    // bool preorder(const IR::Tofino::Deparser *p) override;
    bool preorder(const IR::Expression *e) override;
    FieldDefUse *clone() const override { return new FieldDefUse(*this); }
    void flow_merge(Visitor &) override;
    FieldDefUse(const FieldDefUse &) = default;
    FieldDefUse(FieldDefUse &&) = default;
    friend std::ostream &operator<<(std::ostream &, const FieldDefUse &);

 public:
    explicit FieldDefUse(const PhvInfo &p)
    : phv(p), conflict(*new SymBitMatrix) { visitDagOnce = false; }
    const SymBitMatrix &conflicts() { return conflict; }
};

#endif /* _FIELD_DEFUSE_H_ */
