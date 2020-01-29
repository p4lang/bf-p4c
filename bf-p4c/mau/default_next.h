#ifndef BF_P4C_MAU_DEFAULT_NEXT_H_
#define BF_P4C_MAU_DEFAULT_NEXT_H_

#include "mau_visitor.h"
#include "bf-p4c/ir/control_flow_visitor.h"
#include "bf-p4c/ir/table_tree.h"
#include "lib/ordered_map.h"
#include "lib/ordered_set.h"
#include "bf-p4c/phv/utils/utils.h"  // for operator<<(ordered_set)


class DefaultNext : public MauInspector, BFN::ControlFlowVisitor {
    int id;
    static int id_counter;
    bool long_branch_disabled = false;
    std::set<cstring> *errors;
    ordered_map<const IR::MAU::Table *, ordered_set<const IR::MAU::Table *>> &possible_nexts;
    ordered_set<const IR::MAU::Table *>    prev_tbls;
    bool preorder(const IR::Expression *) override { return false; }
    bool preorder(const IR::MAU::Table *tbl) override {
        LOG3(id << ": DefaultNext::preorder(" << tbl->name << ") prev=" <<
             DBPrint::Brief << prev_tbls << DBPrint::Reset);
        for (auto prev : prev_tbls) {
            if (possible_nexts.count(prev)) {
                // Disabling for JBay, really only used for the characterize power, and necessary
                // to run until that pass is converted to a ControlFlowVisitor
                if (!possible_nexts.at(prev).count(tbl) && long_branch_disabled) {
                    ::error(ErrorType::ERR_UNSUPPORTED_ON_TARGET, "%1% is applied multiple times, "
                            "and the next table information cannot correctly propagate through "
                            "this multiple application", prev);
                    if (errors) errors->insert(prev->externalName()); } }
            possible_nexts[prev].insert(tbl); }
        prev_tbls.clear();
        return true; }
    void postorder(const IR::MAU::Table *tbl) override {
        LOG3(id << ": DefaultNext::postorder(" << tbl->name << ")");
        prev_tbls.insert(tbl); }
    DefaultNext *clone() const override {
        auto *rv = new DefaultNext(*this);
        rv->id = ++id_counter;
        LOG3(id << ": DefaultNext::clone -> " << rv->id);
        return rv; }
    void flow_merge(Visitor &a_) override {
        auto &a = dynamic_cast<DefaultNext &>(a_);
        LOG3(id << ": DefaultNext::flow_merge <- " << a.id);
        prev_tbls.insert(a.prev_tbls.begin(), a.prev_tbls.end()); }
    DefaultNext(const DefaultNext &a) = default;
    bool filter_join_point(const IR::Node *n) override { return !n->is<IR::MAU::TableSeq>(); }
    profile_t init_apply(const IR::Node *root) override {
        LOG3("DefaultNext starting");
        id = id_counter = 0;
        return MauInspector::init_apply(root); }
    bool preorder(const IR::BFN::Pipe *pipe) override {
        LOG5(TableTree("ingress", pipe->thread[INGRESS].mau) <<
             TableTree("egress", pipe->thread[EGRESS].mau) <<
             TableTree("ghost", pipe->ghost_thread) );
        possible_nexts.clear();
        prev_tbls.clear();
        return true; }
    void postorder(const IR::BFN::Pipe *) override {
        if (long_branch_disabled) {
            for (auto prev : prev_tbls) {
                if (possible_nexts.count(prev)) {
                    ::error(ErrorType::ERR_UNSUPPORTED_ON_TARGET, "%1% is applied multiple times, "
                            "and the next table information cannot correctly propagate through "
                            "this multiple application", prev);
                    if (errors) errors->insert(prev->externalName()); } } } }

 public:
    explicit DefaultNext(bool lbd, std::set<cstring> *errs = nullptr)
    : long_branch_disabled(lbd), errors(errs),
      possible_nexts(* new std::remove_reference<decltype(possible_nexts)>::type) {
        joinFlows = true; visitDagOnce = false; }
    const IR::MAU::Table *next(const IR::MAU::Table *t) const {
        if (possible_nexts.count(t)) {
            BUG_CHECK(!possible_nexts.at(t).empty(), "unexpected empty set");
            return possible_nexts.at(t).front(); }
        return nullptr; }
    ordered_set<const IR::MAU::Table *> possible_next(const IR::MAU::Table *t) const {
        if (possible_nexts.count(t))
            return possible_nexts.at(t);
        return {};
    }
    ordered_set<const IR::MAU::Table *> possible_next(cstring name) const {
        for (auto &pn : possible_nexts) {
            if (pn.first->name == name) return pn.second;
            if (pn.first->match_table && pn.first->externalName() == name)
                return pn.second; }
        return {};
    }

    const IR::MAU::Table *next_in_thread(const IR::MAU::Table *t) const {
        if (auto *n = next(t))
            if (n->gress == t->gress)
                return n;
        return nullptr; }
    UniqueId next_in_thread_uniq_id(const IR::MAU::Table *t) const {
        if (auto *n = next(t))
            if (n->gress == t->gress)
                return n->unique_id();
        return UniqueId("END");
    }

    std::set<UniqueId> possible_next_uniq_id(const IR::MAU::Table *t) const {
        std::set<UniqueId> rv;
        for (auto n : possible_next(t))
           if (n->gress == t->gress)
               rv.insert(n->unique_id());
        if (rv.empty())
            rv.insert(UniqueId("END"));
        return rv;
    }
};

#endif /* BF_P4C_MAU_DEFAULT_NEXT_H_ */
