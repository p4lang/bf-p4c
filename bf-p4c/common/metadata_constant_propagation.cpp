#include "metadata_constant_propagation.h"

IR::Node *MetadataConstantPropagation::preorder(IR::Expression *e) {
    if (!first_reads.count(getOriginal<IR::Expression>()))
        return e;
    if (findContext<IR::MAU::Action>() && !findContext<IR::ListExpression>()) {
        auto t = e->type;
        LOG4("replacing " << e << " : " << t << " with zero");
        if (t->is<IR::Type_Boolean>()) {
            prune();
            return new IR::BoolLiteral(false);
        } else if (t->is<IR::Type_Bits>()) {
            prune();
            return new IR::Constant(t, 0);
        } else {
            LOG4("can't replace read before write of metadata type " << t);
        }
    }
    // TODO: Warn if the user has a table that matches on uninitialized
    // metadata.
    return e;
}

Visitor::profile_t MetadataConstantPropagation::init_apply(const IR::Node *root) {
    auto rv = Transform::init_apply(root);

    LOG4("find reads of uninitialized fields");
    // Find first reads: if a field use does not have a def, then it is
    // reading an unintialized value.
    for (auto &f : phv) {
        for (const FieldDefUse::locpair use : defuse.getUses(f.id)) {
            if (!defuse.getDefs(use).size()) {
                LOG4("uninitialized read of " <<
                     f.name << " at "<< DBPrint::Brief << use.first <<
                     ":" << DBPrint::Brief << use.second);
                first_reads.insert(use.second); } } }

    return rv;
}

