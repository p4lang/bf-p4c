#include "lib/algorithm.h"
#include "phv_constraints.h"

namespace {
struct FieldsReferenced : public Inspector {
    set<cstring>        fields;
    bool preorder(const IR::FieldRef *f) { fields.insert(f->toString()); return false; }
    bool preorder(const IR::HeaderStackItemRef *f) { fields.insert(f->toString()); return false; }
    explicit FieldsReferenced(const IR::Expression *e) { e->apply(*this); }
};
};

bool MauPhvConstraints::preorder(const IR::Primitive *p) {
    FieldsReferenced fields(p);
    remove_if(fields.fields, [this](cstring f) -> bool { return !phv.field(f); });
    for (auto f1 : fields.fields)
        for (auto f2 : fields.fields)
            if (f1 != f2)
                phv.field(f1)->constraints.emplace(PhvInfo::constraint::SAME_GROUP, f2);
    return false;
}

void MauPhvConstraints::constraining_op(const IR::Expression *e) {
    FieldsReferenced fields(e);
    for (auto f : fields.fields)
        if (auto *info = phv.field(f))
            info->constraints.emplace(PhvInfo::constraint::FULL_UNIT);
}
