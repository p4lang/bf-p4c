#include "bf-p4c/phv/analysis/dark.h"
#include <queue>

Visitor::profile_t CollectNonDarkUses::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    nonDarkMauUses.clear();
    return rv;
}

bool CollectNonDarkUses::contextNeedsIXBar() {
    for (auto c = getContext(); c; c = c->parent) {
        if (c->node->is<IR::MAU::IXBarExpression>() ||
            c->node->is<IR::MAU::StatefulCall>() ||
            c->node->is<IR::MAU::StatefulAlu>() ||
            c->node->is<IR::MAU::Table>() ||
            c->node->is<IR::MAU::Meter>() ||
            c->node->is<IR::MAU::HashDist>())
            return true;
        if (c->node->is<IR::MAU::Action>())
            return false;
    }
    BUG("invalid context in CollectNonDarkUses");
}

bool CollectNonDarkUses::preorder(const IR::MAU::Table* table) {
    // Ensure that we visit all expressions in the table, even if they have been previously visited
    // in a different context.
    auto result = Inspector::preorder(table);
    revisit_visited();
    return result;
}

bool CollectNonDarkUses::preorder(const IR::Expression *e) {
    if (auto *field = phv.field(e)) {
        if (contextNeedsIXBar()) {
            nonDarkMauUses[field->id] = true; }
        return false; }
    return true;
}

bool CollectNonDarkUses::hasNonDarkUse(const PHV::Field* f) const {
    return nonDarkMauUses[f->id];
}

Visitor::profile_t MarkDarkCandidates::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    nonDarkMauUses.clear();
    darkCount = 0;
    darkSize = 0;
    return rv;
}

void MarkDarkCandidates::end_apply() {
    for (PHV::Field& f : phv) {
        std::stringstream ss;

        ss << "    Candidate field for dark: " << f << std::endl;

        // If the metadata field is used in the parser/deparser, then ignore it.
        // Note that the is_used_parde() function does returns false for a bunch of fields (such as
        // deparser parameters), which it considers to be used in the MAU instead. Until we resolve
        // this discrepancy by understanding how the rest of the compiler uses the results of
        // is_used_parde(), we need to add the second clause is_deparsed() below.
        if (uses.is_used_parde(&f) || uses.is_deparsed(&f)) {
            ss << "    ...field used in parde.";
            LOG5(ss.str());
            continue; }

        if (nonDarkUses.hasNonDarkUse(&f)) {
            ss << "    ...used for non-dark MAU operations.";
            LOG5(ss.str());
            continue; }

        if (f.bridged || f.padding) {
            ss << "    ...encountered bridged/padding/phase0 field.";
            LOG5(ss.str());
            continue; }

        if (f.is_checksummed()) {
            ss << "    ...checksum field encountered.";
            LOG5(ss.str());
            continue; }

        if (f.is_digest()) {
            ss << "    ...digest field encountered.";
            LOG5(ss.str());
            continue; }

        // Ignore dark analysis is field is not a mocha candidate.
        // Dark fields can go into mocha and so are definitely mocha candidates.
        // XXX(Deep): In the long run, we should move to using dark containers as a kind of spill
        // space, where fields can be temporarily written into dark from normal/mocha containers in
        // stages where they are not used. The following requirement is overly restrictive, once we
        // enable such spill-oriented allocation.
        if (!f.is_mocha_candidate()) {
            ss << "    ... non-mocha candidate.";
            LOG5(ss.str());
            continue;
        }

        f.set_dark_candidate(true);
        ++darkCount;
        darkSize += f.size;
        LOG1("    Dark candidate: " << f); }
    LOG1("    Number of dark candidate fields: " << darkCount);
    LOG1("    Total size of dark candidates  : " << darkSize << "b.");
}
