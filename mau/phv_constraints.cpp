#include "lib/algorithm.h"

#include "phv_constraints.h"

namespace {
struct FieldsReferenced : public Inspector {
    PhvInfo                     &phv;
    set<PhvInfo::Field *>       fields;
    bool preorder(const IR::Expression *e) override {
        if (auto *f = phv.field(e)) {
            fields.insert(f);
            return false; }
        return true; }
    FieldsReferenced(PhvInfo &p, const IR::Expression *e) : phv(p) { e->apply(*this); }
};
}  // end anon namespace
