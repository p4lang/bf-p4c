#include "bf-p4c/phv/analysis/dark.h"

Visitor::profile_t CollectDarkCandidates::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    nonDarkMauUses.clear();
    darkCount = 0;
    darkSize = 0;
    return rv;
}

bool CollectDarkCandidates::preorder(const IR::MAU::Action* act) {
    for (auto* prim : act->stateful) {
        for (auto* operand : prim->operands) {
            const PHV::Field* f = phv.field(operand);
            if (!f) continue;
            LOG5("    Input crossbar read, stateful primitive: " << f);
            nonDarkMauUses[f->id] = true; } }
    return true;
}

bool CollectDarkCandidates::preorder(const IR::MAU::Table* tbl) {
    for (auto kv : tbl->gateway_rows) {
        if (kv.first == nullptr) continue;
        auto* op = kv.first->to<IR::Operation_Binary>();
        if (!op)
            continue;
        const PHV::Field* left = phv.field(op->left);
        if (left) {
            LOG5("    Input crossbar read, field in gateway condition: " << left);
            nonDarkMauUses[left->id] = true; }
        const PHV::Field* right = phv.field(op->right);
        if (right) {
            LOG5("    Input crossbar read, field in gateway condition: " << right);
            nonDarkMauUses[right->id] = true; } }
    return true;
}

bool CollectDarkCandidates::preorder(const IR::MAU::InputXBarRead* read) {
    const PHV::Field* f = phv.field(read->expr);
    if (!f) return true;
    nonDarkMauUses[f->id] = true;
    LOG5("    Input crossbar read: " << f);
    return true;
}

bool CollectDarkCandidates::preorder(const IR::MAU::Meter* mtr) {
    const PHV::Field* f = phv.field(mtr->result);
    if (f) {
        LOG5("    Meter result: " << f);
        nonDarkMauUses[f->id] = true; }
    f = phv.field(mtr->pre_color);
    if (f) {
        LOG5("    Meter pre color: " << f);
        nonDarkMauUses[f->id] = true; }
    f = phv.field(mtr->input);
    if (f) {
        LOG5("    Meter input: " << f);
        nonDarkMauUses[f->id] = true; }
    return true;
}

void CollectDarkCandidates::end_apply() {
    for (PHV::Field& f : phv) {
        std::stringstream ss;
        // Ignore dark analysis is field is not a mocha candidate.
        // Dark fields can go into mocha and so are definitely mocha candidates.
        // XXX(Deep): In the long run, we should move to using dark containers as a kind of spill
        // space, where fields can be temporarily written into dark from normal/mocha containers in
        // stages where they are not used. The following requirement is overly restrictive, once we
        // enable such spill-oriented allocation.
        if (!f.is_mocha_candidate()) continue;

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

        if (nonDarkMauUses[f.id]) {
            ss << "    ...used for non-dark MAU operations.";
            LOG5(ss.str());
            continue; }

        f.set_dark_candidate(true);
        ++darkCount;
        darkSize += f.size;
        LOG1("    Dark candidate: " << f); }
    LOG1("    Number of dark candidate fields: " << darkCount);
    LOG1("    Total size of dark candidates  : " << darkSize << "b.");
}
