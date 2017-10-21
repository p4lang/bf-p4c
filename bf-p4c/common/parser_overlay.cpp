#include "parser_overlay.h"
#include <sstream>
#include <typeinfo>
#include "bf-p4c/phv/phv_fields.h"
#include "ir/ir.h"
#include "lib/log.h"

void BuildParserOverlay::mark(const PHV::Field* f) {
    // XXX(cole): f->pov is supposed to imply f->metadata.
    if (!f || f->metadata || f->pov)
        return;
    int new_field = f->id;
    if (fields_encountered[new_field])
        return;
    fields_encountered[new_field] = true;
    mutually_inclusive[new_field] |= fields_encountered;
}

bool BuildParserOverlay::preorder(const IR::BFN::Extract *e) {
    auto *f = phv.field(e->dest->field);
    mark(f);
    return false;
}

void BuildParserOverlay::flow_merge(Visitor& other_) {
    BuildParserOverlay &other = dynamic_cast<BuildParserOverlay &>(other_);
    fields_encountered |= other.fields_encountered;
    mutually_inclusive |= other.mutually_inclusive;
}

void BuildParserOverlay::end_apply() {
    LOG4("mutually exclusive fields:");
    for (auto it1 = fields_encountered.begin();
         it1 != fields_encountered.end();
         ++it1 ) {
        for (auto it2 = it1; it2 != fields_encountered.end(); ++it2) {
            // Consider fields that are part of headers that can be added in the
            // MAU pipeline to always be mutually inclusive.
            // XXX(cole): this could use a more sophisticated analysis to be
            // more precise.
            bool skipAddedField = addedHeaderFields[*it1] || addedHeaderFields[*it2];
            if (mutually_inclusive(*it1, *it2) || skipAddedField)
                continue;
            mutually_exclusive(*it1, *it2) = true;
            LOG4("(" << phv.field(*it1)->name << ", " << phv.field(*it2)->name << ")"); } }
}

bool FindAddedHeaderFields::preorder(const IR::Primitive* prim) {
    // If this is a well-formed field modification...
    if (prim->name == "set" && prim->operands.size() > 1) {
        // that writes a non-zero value to `hdrRef.$valid`...
        auto* m = prim->operands[0]->to<IR::Member>();
        auto* c = prim->operands[1]->to<IR::Constant>();
        if (m && m->member == "$valid" && c && c->asInt() != 0) {
            if (auto* hr = m->expr->to<IR::HeaderRef>()) {
                // then add all fields of the header (not including $valid) to
                // the set of fields that are part of added headers
                PhvInfo::StructInfo info = phv.struct_info(hr);
                for (int id : info.field_ids()) {
                    rv[id] = true; } } } }
    return false;
}
