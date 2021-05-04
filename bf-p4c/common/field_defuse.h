#ifndef _FIELD_DEFUSE_H_
#define _FIELD_DEFUSE_H_

#include <iostream>
#include "ir/ir.h"
#include "lib/symbitmatrix.h"
#include "lib/ltbitmatrix.h"
#include "lib/ordered_set.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/ir/control_flow_visitor.h"
#include "bf-p4c/ir/tofino_write_context.h"

/** Represent the parser initialization that sets all fields to zero.
 *  This is actually a dummy subclass of IR::Expression to work with
 *  the locpair setup. NEVER insert this class to IR, because it is not
 *  a IR node, because it is not registered in visiter classes.
 */
class ImplicitParserInit : public IR::Expression {
 private:
    IR::Expression* clone() const override {
        auto* new_expr = new ImplicitParserInit(*this);
        return new_expr; }

 public:
    explicit ImplicitParserInit(const PHV::Field* f)
        : field(f) { }
    const PHV::Field* field;
    void dbprint(std::ostream & out) const override {
        out << "ImplicitParserInit"; }
};

class FieldDefUse : public BFN::ControlFlowVisitor, public Inspector, TofinoWriteContext {
 public:
    /** A given expression for a field might appear multiple places in the IR dag (eg, an
     * action used by mulitple tables), so we use a pair<Unit,Expr> to denote a particular
     * use or definition in the code */
    typedef std::pair<const IR::BFN::Unit *, const IR::Expression*>  locpair;
    typedef ordered_set<locpair> LocPairSet;

    enum VisitMode {
      VisitJustReads,
      VisitJustWrites,
      VisitAll
    };

    VisitMode mode = VisitAll;

 private:
    const PhvInfo               &phv;
    SymBitMatrix                &conflict;

    /// Maps uses to defs and vice versa.
    ordered_map<locpair, LocPairSet>  &uses, &defs;
    ordered_map<locpair, bool> ixbar_refs;

    /// All uses and all defs for each field.
    ordered_map<int, LocPairSet>      &located_uses, &located_defs;

    /// Maps each def to the set of defs that it may overwrite.
    ordered_map<locpair, LocPairSet>  &output_deps;

    /// All implicit parser zero initialization for each field.
    LocPairSet                        &parser_zero_inits;

    // All fields that rely on parser zero initialization.
    ordered_set<const PHV::Field*>    &uninitialized_fields;

    // All fields used as alias destinations.
    ordered_set<const PHV::Field*>    alias_destinations;

    /// Intermediate data structure for computing def/use sets.
    struct info {
        const PHV::Field    *field = 0;
        LocPairSet           def, use;
    };
    /// Intermediate data structure for computing def/use sets.
    std::unordered_map<int, info> defuse;
    class ClearBeforeEgress;
    class CollectAliasDestinations;

    profile_t init_apply(const IR::Node *root) override;
    void end_apply(const IR::Node *root) override;
    void check_conflicts(const info &read, int when);
    void read(const PHV::Field *, const IR::BFN::Unit *, const IR::Expression *, bool);
    void read(const IR::HeaderRef *, const IR::BFN::Unit *, const IR::Expression *, bool);
    void write(const PHV::Field *, const IR::BFN::Unit *,
               const IR::Expression *, bool, bool partial = false);
    void write(const IR::HeaderRef *, const IR::BFN::Unit *, const IR::Expression *, bool);
    info &field(const PHV::Field *);
    info &field(int id) { return field(phv.field(id)); }
    void access_field(const PHV::Field *);
    bool preorder(const IR::BFN::Pipe *p) override;
    bool preorder(const IR::BFN::Parser *p) override;
    bool preorder(const IR::BFN::LoweredParser *p) override;
    bool preorder(const IR::MAU::Primitive* prim) override;
    bool preorder(const IR::MAU::Action *p) override;
    bool preorder(const IR::MAU::StatefulAlu* prim) override;
    bool preorder(const IR::Expression *e) override;
    FieldDefUse *clone() const override { return new FieldDefUse(*this); }
    void flow_merge(Visitor &) override;
    FieldDefUse(const FieldDefUse &) = default;
    FieldDefUse(FieldDefUse &&) = default;
    friend std::ostream &operator<<(std::ostream &, const FieldDefUse::info &);
    friend void dump(const FieldDefUse::info &);
    friend std::ostream &operator<<(std::ostream &, const FieldDefUse &);

 public:
    explicit FieldDefUse(const PhvInfo &p)
    : phv(p), conflict(*new SymBitMatrix),
      uses(*new std::remove_reference<decltype(uses)>::type),
      defs(*new std::remove_reference<decltype(defs)>::type),
      located_uses(*new std::remove_reference<decltype(located_uses)>::type),
      located_defs(*new std::remove_reference<decltype(located_defs)>::type),
      output_deps(*new std::remove_reference<decltype(output_deps)>::type),
      parser_zero_inits(*new std::remove_reference<decltype(parser_zero_inits)>::type),
      uninitialized_fields(*new std::remove_reference<decltype(uninitialized_fields)>::type)
      { joinFlows = true; visitDagOnce = false; }

    // TODO: unused?
    // const SymBitMatrix &conflicts() { return conflict; }

    const LocPairSet &getDefs(locpair use) const {
        static const LocPairSet emptyset;
        return defs.count(use) ? defs.at(use) : emptyset; }
    const LocPairSet &getDefs(const IR::BFN::Unit *u, const IR::Expression *e) const {
        return getDefs(locpair(u, e)); }
    const LocPairSet &getDefs(const Visitor *v, const IR::Expression *e) const {
        return getDefs(locpair(v->findOrigCtxt<IR::BFN::Unit>(), e)); }
    /** Get all defs of the PHV::Field with ID @fid. */
    const LocPairSet &getAllDefs(int fid) const {
        static const LocPairSet emptyset;
        return located_defs.count(fid) ? located_defs.at(fid) : emptyset; }

    const LocPairSet &getUses(locpair def) const {
        static const LocPairSet emptyset;
        return uses.count(def) ? uses.at(def) : emptyset; }
    const LocPairSet &getUses(const IR::BFN::Unit *u, const IR::Expression *e) const {
        return getUses(locpair(u, e)); }
    const LocPairSet &getUses(const Visitor *v, const IR::Expression *e) const {
        return getUses(locpair(v->findOrigCtxt<IR::BFN::Unit>(), e)); }
    /** Get all uses of the PHV::Field with ID @fid. */
    const LocPairSet &getAllUses(int fid) const {
        static const LocPairSet emptyset;
        return located_uses.count(fid) ? located_uses.at(fid) : emptyset; }

    /// @return all defs that the given def may overwrite.
    const LocPairSet &getOutputDeps(locpair def) const {
        static const LocPairSet emptyset;
        return output_deps.count(def) ? output_deps.at(def) : emptyset;
    }
    const LocPairSet &getOutputDeps(const IR::BFN::Unit *u, const IR::Expression *e) const {
        return getOutputDeps(locpair(u, e));
    }
    const LocPairSet &getOutputDeps(const Visitor *v, const IR::Expression *e) const {
        return getOutputDeps(locpair(v->findOrigCtxt<IR::BFN::Unit>(), e));
    }

    const ordered_set<const PHV::Field*> &getUninitializedFields() const {
        return uninitialized_fields; }

    bool hasNonDarkContext(locpair info) const {
        if (ixbar_refs.count(info)) {
            LOG4("\t ixbar_refs:" << ixbar_refs.size());
        }

        if (!ixbar_refs.count(info)) {
            LOG5("\t\t ixbar_refs for expression " << info.second << " not found for unit " <<
                 info.first << ", but assuming it is non-dark");
            return true;
        }

        return ixbar_refs.at(info);
    }

    bool hasUninitializedRead(int fid) const {
        for (const auto& def : getAllDefs(fid)) {
            auto* expr = def.second;
            if (dynamic_cast<const ImplicitParserInit*>(expr) != nullptr)
                if (getUses(def).size() > 0)
                    return true; }
        return false;
    }

    /// @returns true if the field @f is used in the parser.
    bool isUsedInParser(const PHV::Field* f) const;
    bool hasUseAt(const PHV::Field* f, const IR::BFN::Unit* u) const;
    bool hasDefAt(const PHV::Field* f, const IR::BFN::Unit* u) const;
};

#endif /* _FIELD_DEFUSE_H_ */
