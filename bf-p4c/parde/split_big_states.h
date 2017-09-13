#ifndef TOFINO_PARDE_SPLIT_BIG_STATES_H_
#define TOFINO_PARDE_SPLIT_BIG_STATES_H_

#include "parde_visitor.h"
#include "tofino/phv/phv_fields.h"

class UniqueStateNamer : public PardeInspector {
    std::set<cstring>   names;
    profile_t init_apply(const IR::Node *root) override {
        names.clear();
        return PardeInspector::init_apply(root); }
    bool preorder(const IR::Expression *) override { return false; }
    bool preorder(const IR::BFN::ParserState *state) override {
        names.insert(state->name);
        return true; }
 public:
    cstring newname(cstring root) {
        cstring rv = root;
        int ctr = 0;
        while (names.count(rv)) {
            char tmp[16];
            snprintf(tmp, sizeof(tmp), ".%d", ctr++);
            rv = root + tmp; }
        names.insert(rv);
        return rv; }
};

class SplitBigStates : public PardeModifier {
    const PhvInfo       &phv;
    UniqueStateNamer    names;
    bool preorder(IR::BFN::Parser *p) override {
        p->apply(names);
        return true; }
    bool preorder(IR::BFN::ParserMatch *state) override;
 public:
    explicit SplitBigStates(const PhvInfo &phv) : phv(phv) {}
};

#endif /* TOFINO_PARDE_SPLIT_BIG_STATES_H_ */
