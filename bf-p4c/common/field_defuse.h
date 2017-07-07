#ifndef _FIELD_DEFUSE_H_
#define _FIELD_DEFUSE_H_

#include <iostream>
#include "ir/ir.h"
#include "lib/symbitmatrix.h"
#include "lib/ltbitmatrix.h"
#include "lib/ordered_set.h"
#include "tofino/phv/phv_fields.h"
#include "tofino/ir/tofino_write_context.h"


class FieldDefUse : public ControlFlowVisitor, public Inspector, TofinoWriteContext {
 public:
    /* A given expression for a field might appear multiple places in the IR dag (eg, an
     * action used by mulitple tables), so we use a pair<Unit,Expr> to denote a particular
     * use or definition in the code */
    typedef std::pair<const IR::Tofino::Unit *, const IR::Expression*>  locpair;
    typedef ordered_set<locpair> LocPairSet;

 private:
    const PhvInfo               &phv;
    SymBitMatrix                &conflict;
    ordered_map<locpair, LocPairSet>  &uses, &defs;
    struct info {
        const PhvInfo::Field    *field = 0;
        LocPairSet            def, use;
    };
    std::unordered_map<int, info> defuse;
    class ClearBeforeEgress;
    // class Init;

    profile_t init_apply(const IR::Node *root) override;
    void end_apply(const IR::Node *root) override;
    void check_conflicts(const info &read, int when);
    void read(const PhvInfo::Field *, const IR::Tofino::Unit *, const IR::Expression *);
    void read(const IR::HeaderRef *, const IR::Tofino::Unit *, const IR::Expression *);
    void write(const PhvInfo::Field *, const IR::Tofino::Unit *, const IR::Expression *);
    void write(const IR::HeaderRef *, const IR::Tofino::Unit *, const IR::Expression *);
    info &field(const PhvInfo::Field *);
    info &field(int id) { return field(phv.field(id)); }
    void access_field(const PhvInfo::Field *);
    bool preorder(const IR::Tofino::Parser *p) override;
    bool preorder(const IR::Expression *e) override;
    FieldDefUse *clone() const override { return new FieldDefUse(*this); }
    void flow_merge(Visitor &) override;
    bool filter_join_point(const IR::Node *n) override {
        return !n->is<IR::Tofino::ParserState>() && !n->is<IR::MAU::TableSeq>(); }
    FieldDefUse(const FieldDefUse &) = default;
    FieldDefUse(FieldDefUse &&) = default;
    friend std::ostream &operator<<(std::ostream &, const FieldDefUse::info &);
    friend void dump(const FieldDefUse::info &);
    friend std::ostream &operator<<(std::ostream &, const FieldDefUse &);

 public:
    explicit FieldDefUse(const PhvInfo &p)
    : phv(p), conflict(*new SymBitMatrix), uses(*new std::remove_reference<decltype(uses)>::type),
      defs(*new std::remove_reference<decltype(defs)>::type)
    { joinFlows = true; visitDagOnce = false; }
    const SymBitMatrix &conflicts() { return conflict; }

    const LocPairSet &getDefs(locpair use) const {
        static const LocPairSet emptyset;
        return defs.count(use) ? defs.at(use) : emptyset; }
    const LocPairSet &getDefs(const IR::Tofino::Unit *u, const IR::Expression *e) const {
        return getDefs(locpair(u, e)); }
    const LocPairSet &getDefs(const Visitor *v, const IR::Expression *e) const {
        return getDefs(locpair(v->findOrigCtxt<IR::Tofino::Unit>(), e)); }
    /** Get all defs of the PhvInfo::Field with ID @fid. */
    const LocPairSet &getDefs(int fid) const {
        static const LocPairSet emptyset;
        return defuse.count(fid) ? defuse.at(fid).def : emptyset; }

    const LocPairSet &getUses(locpair def) const {
        static const LocPairSet emptyset;
        return uses.count(def) ? uses.at(def) : emptyset; }
    const LocPairSet &getUses(const IR::Tofino::Unit *u, const IR::Expression *e) const {
        return getUses(locpair(u, e)); }
    const LocPairSet &getUses(const Visitor *v, const IR::Expression *e) const {
        return getUses(locpair(v->findOrigCtxt<IR::Tofino::Unit>(), e)); }
    /** Get all uses of the PhvInfo::Field with ID @fid. */
    const LocPairSet &getUses(int fid) const {
        static const LocPairSet emptyset;
        return defuse.count(fid) ? defuse.at(fid).use : emptyset; }
};

#endif /* _FIELD_DEFUSE_H_ */
