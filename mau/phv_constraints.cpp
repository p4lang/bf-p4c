#include "lib/algorithm.h"
#include "phv_constraints.h"

namespace {
struct FieldsReferenced : public Inspector {
    PhvInfo                     &phv;
    set<PhvInfo::Field *>       fields;
    bool preorder(const IR::Member *f) override { fields.insert(phv.field(f)); return false; }
    FieldsReferenced(PhvInfo &p, const IR::Expression *e) : phv(p) { e->apply(*this); }
};
}  // end anon namespace

bool MauPhvConstraints::preorder(const IR::Primitive *p) {
    FieldsReferenced fields(phv, p);
    for (auto f1 : fields.fields)
        for (auto f2 : fields.fields)
            if (f1 != f2)
                f1->constraints.emplace(PhvInfo::constraint::SAME_GROUP, f2);
    return false;
}

void MauPhvConstraints::constraining_op(const IR::Expression *e) {
    FieldsReferenced fields(phv, e);
    for (auto f : fields.fields)
        f->constraints.emplace(PhvInfo::constraint::FULL_UNIT);
}
