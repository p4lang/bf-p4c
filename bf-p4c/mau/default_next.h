#ifndef BF_P4C_MAU_DEFAULT_NEXT_H_
#define BF_P4C_MAU_DEFAULT_NEXT_H_

#include "mau_visitor.h"
#include "bf-p4c/ir/control_flow_visitor.h"
#include "lib/ordered_set.h"

class DefaultNext : public MauInspector, BFN::ControlFlowVisitor {
    int id;
    static int id_counter;
    bool long_branch_disabled = false;
    std::map<const IR::MAU::Table *, const IR::MAU::Table *>    *default_next;
    ///> JBay only, for temporary
    std::map<const IR::MAU::Table *, ordered_set<const IR::MAU::Table *>> possible_nexts;
    std::set<const IR::MAU::Table *>    prev_tbls;
    bool preorder(const IR::Expression *) override { return false; }
    bool preorder(const IR::MAU::Table *tbl) override {
        LOG3(id << ": DefaultNext::preorder(" << tbl->name << ") prev=" <<
             DBPrint::Brief << prev_tbls << DBPrint::Reset);
        for (auto prev : prev_tbls) {
            if (default_next->count(prev)) {
                // Disabling for JBay, really only used for the characterize power, and necessary
                // to run until that pass is converted to a ControlFlowVisitor
                if (default_next->at(prev) != tbl && long_branch_disabled)
                    BUG("inconsistent table layout");
            } else {
                default_next->emplace(prev, tbl);
            }
            possible_nexts[prev].insert(tbl);
        }
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
    profile_t init_apply(const IR::Node *root) override {
        LOG3("DefaultNext starting");
        id = id_counter = 0;
        return MauInspector::init_apply(root); }

 public:
    explicit DefaultNext(bool lbd) : long_branch_disabled(lbd),
        default_next(new std::remove_reference<decltype(*default_next)>::type) {
        joinFlows = true; visitDagOnce = false; }
    const IR::MAU::Table *next(const IR::MAU::Table *t) const {
        return ::get(default_next, t); }
    ordered_set<const IR::MAU::Table *> possible_next(const IR::MAU::Table *t) const {
        ordered_set<const IR::MAU::Table *> rv;
        if (possible_nexts.count(t))
            return possible_nexts.at(t);
        return rv;
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
