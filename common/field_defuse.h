#ifndef _FIELD_DEFUSE_H_
#define _FIELD_DEFUSE_H_

#include <iostream>
#include "ir/ir.h"
#include "lib/symbitmatrix.h"
#include "lib/ltbitmatrix.h"
#include "tofino/phv/phv_fields.h"

class FieldDefUse : public ControlFlowVisitor, public Inspector, P4WriteContext {
 public:
    typedef std::pair<const IR::Tofino::Unit *, const IR::Expression*>  locpair;

 private:
    const PhvInfo                               &phv;
    SymBitMatrix                                &conflict;
    map<const IR::Expression *, set<locpair>>   &uses;
    struct info {
        const PhvInfo::Info     *field = 0;
        set<locpair>            def, use;
    };
    std::unordered_map<int, info> defuse;
    // class Init;

    profile_t init_apply(const IR::Node *root) override;
    void end_apply(const IR::Node *root) override;
    void check_conflicts(const info &read, int when);
    void read(const PhvInfo::Info *, const IR::Tofino::Unit *, const IR::Expression *);
    void read(const IR::HeaderRef *, const IR::Tofino::Unit *, const IR::Expression *);
    void write(const PhvInfo::Info *, const IR::Tofino::Unit *, const IR::Expression *);
    void write(const IR::HeaderRef *, const IR::Tofino::Unit *, const IR::Expression *);
    info &field(const PhvInfo::Info *);
    info &field(int id) { return field(phv.field(id)); }
    void access_field(const PhvInfo::Info *);
    // bool preorder(const IR::Tofino::Parser *p) override;
    // bool preorder(const IR::Tofino::Deparser *p) override;
    bool preorder(const IR::Expression *e) override;
    FieldDefUse *clone() const override { return new FieldDefUse(*this); }
    void flow_merge(Visitor &) override;
    bool filter_join_point(const IR::Node *n) override {
        return !n->is<IR::Tofino::ParserState>(); }
    FieldDefUse(const FieldDefUse &) = default;
    FieldDefUse(FieldDefUse &&) = default;
    friend std::ostream &operator<<(std::ostream &, const FieldDefUse::info &);
    friend void dump(const FieldDefUse::info &);
    friend std::ostream &operator<<(std::ostream &, const FieldDefUse &);

 public:
    explicit FieldDefUse(const PhvInfo &p)
    : phv(p), conflict(*new SymBitMatrix), uses(*new std::remove_reference<decltype(uses)>::type)
    { joinFlows = true; visitDagOnce = false; }
    const SymBitMatrix &conflicts() { return conflict; }
    const set<locpair> &getUses(const IR::Expression *e) const { return uses.at(e); }
};

#endif /* _FIELD_DEFUSE_H_ */
