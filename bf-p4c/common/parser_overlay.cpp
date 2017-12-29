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

void BuildParserOverlay::postorder(const IR::BFN::Pipe* pipe) {
    auto check_pragma_string = [] (const IR::StringLiteral* ir) {
        if (!ir) {
            ::warning("%1%", "@pragma pa_mutually_exclusive's arguments must be strings, skipped");
            return false; }
        return true; };

    auto global_pragmas = pipe->global_pragmas;
    for (const auto* annotation : global_pragmas) {
        if (annotation->name.name != "pa_mutually_exclusive")
            continue;

        auto& exprs = annotation->expr;
        // check pragma argument
        if (exprs.size() != 3) {
            ::warning("@pragma pa_mutually_exclusive must "
                      "have 3 arguments, only %1% found, skipped", exprs.size());
            continue; }

        auto gress = exprs[0]->to<IR::StringLiteral>();
        auto field1_ir = exprs[1]->to<IR::StringLiteral>();
        auto field2_ir = exprs[2]->to<IR::StringLiteral>();

        // check gress correct
        if (!check_pragma_string(gress) || !check_pragma_string(field1_ir)
            || !check_pragma_string(field2_ir))
            continue;

        if (gress->value != "ingress" && gress->value != "egress") {
            ::warning("@pragma pa_mutually_exclusive's first argument "
                      "must be either ingress/egress, instead of %1%, skipped", gress);
            continue; }

        auto field1_name = gress->value + "::" + field1_ir->value;
        auto field2_name = gress->value + "::" + field2_ir->value;
        auto field1 = phv.field(field1_name);
        auto field2 = phv.field(field2_name);

        if (!field1) {
            ::warning("@pragma pa_mutually_exclusive's argument "
                      "%1% does not match any phv fields, skipped", field1_name);
            continue; }
        if (!field2) {
            ::warning("@pragma pa_mutually_exclusive's argument "
                      "%1% does not match any phv fields, skipped", field2_name);
            continue; }

        mutually_exclusive(field1->id, field2->id) = true;
        LOG1("set " << field1 << " and " << field2
             << " to be mutually_exclusive because of @pragma pa_mutually_exclusive");
    }
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
