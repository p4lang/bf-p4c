#ifndef BF_P4C_MAU_DEFAULT_NEXT_H_
#define BF_P4C_MAU_DEFAULT_NEXT_H_

#include "mau_visitor.h"
#include "bf-p4c/ir/control_flow_visitor.h"

class DefaultNext : public MauInspector, BFN::ControlFlowVisitor {
    int id;
    static int id_counter;
    std::map<const IR::MAU::Table *, const IR::MAU::Table *>    *default_next;
    std::set<const IR::MAU::Table *>    prev_tbls;
    bool preorder(const IR::Expression *) override { return false; }
    bool preorder(const IR::MAU::Table *tbl) override {
        LOG3(id << ": DefaultNext::preorder(" << tbl->name << ") prev=" <<
             DBPrint::Brief << prev_tbls << DBPrint::Reset);
        for (auto prev : prev_tbls) {
            if (default_next->count(prev)) {
                if (default_next->at(prev) != tbl)
                    BUG("inconsistent table layout");
            } else {
                default_next->emplace(prev, tbl); } }
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
    DefaultNext() : default_next(new std::remove_reference<decltype(*default_next)>::type) {
        joinFlows = true; visitDagOnce = false; }
    const IR::MAU::Table *next(const IR::MAU::Table *t) const {
        return ::get(default_next, t); }
    const IR::MAU::Table *next_in_thread(const IR::MAU::Table *t) const {
        if (auto *n = next(t))
            if (n->gress == t->gress)
                return n;
        return nullptr; }
    UniqueId next_in_thread_uniq_id(const IR::MAU::Table *t) const {
      if (auto *n = next(t))
          if (n->gress == t->gress)
              return n->unique_id();
      return UniqueId("END"); }
};

#endif /* BF_P4C_MAU_DEFAULT_NEXT_H_ */
