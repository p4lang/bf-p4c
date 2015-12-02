#ifndef _default_next_h_
#define _default_next_h_

#include "mau_visitor.h"

class DefaultNext : public MauInspector, ControlFlowVisitor {
    std::map<const IR::MAU::Table *, const IR::MAU::Table *>    *default_next;
    std::set<const IR::MAU::Table *>    prev_tbls;
    bool preorder(const IR::MAU::Table *tbl) override {
        for (auto prev : prev_tbls) {
            assert(!default_next->count(prev));
            default_next->emplace(prev, tbl); }
        prev_tbls.clear();
        return true; }
    void postorder(const IR::MAU::Table *tbl) override {
        prev_tbls.clear();
        prev_tbls.insert(tbl); }
    virtual DefaultNext *clone() const override { return new DefaultNext(*this); }
    virtual void flow_merge(Visitor &a_) override {
        auto &a = dynamic_cast<DefaultNext &>(a_);
        prev_tbls.insert(a.prev_tbls.begin(), a.prev_tbls.end()); }
    DefaultNext(const DefaultNext &) = default;
public:
    DefaultNext() : default_next(new std::remove_reference<decltype(*default_next)>::type) {}
    const IR::MAU::Table *next(const IR::MAU::Table *t) {
        return ::get(default_next, t); }
    cstring next_in_thread(const IR::MAU::Table *t) {
        if (auto *n = next(t))
            if (n->gress == t->gress)
                return n->name;
        return "END"; }
};

#endif /* _default_next_h_ */
