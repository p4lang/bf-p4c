#include <base/logging.h>
#include "lib/log.h"
#include "parser_overlay.h"
#include "ir/ir.h"

#include <sstream>
#include <typeinfo>

void ParserOverlay::mark(const PhvInfo::Field* f) {
    if (!f || f->metadata) return;
    int new_field = f->id;
    if (fields_encountered.find(new_field) != fields_encountered.end())
        return;
    fields_encountered.insert(new_field);
    for (auto &known_field : fields_encountered) {
        mutually_inclusive(new_field, known_field) = true; }
}

void ParserOverlay::mark(const IR::HeaderRef* hr) {
    if (!hr) return;
    auto hdr_ids = *phv.header(hr);
    for (int id : Range(hdr_ids))
        mark(phv.field(id));
}

bool ParserOverlay::preorder(const IR::Expression *e) {
    auto *f = phv.field(e);
    auto *hr = e->to<IR::HeaderRef>();
    if (!f && !hr) return true;
    if (findContext<IR::Tofino::ParserState>()) {
        mark(f);
        mark(hr);
    }
    return true;
}

void ParserOverlay::flow_merge(Visitor& other_) {
    ParserOverlay &other = dynamic_cast<ParserOverlay &>(other_);
    for (auto other_field : other.fields_encountered) {
        // Union fields_encountered.
        fields_encountered.insert(other_field);

        // Union mutually_inclusive.
        for (auto other_field2 : other.fields_encountered)
            mutually_inclusive(other_field, other_field2) =
                other.mutually_inclusive(other_field, other_field2) ? true : false; }
}

void ParserOverlay::end_apply() {
    LOG4("mutually exclusive fields:");
    for ( auto it1 = fields_encountered.begin();
          it1 != fields_encountered.end();
          ++it1 )
    {
        for (auto it2 = it1; it2 != fields_encountered.end(); ++it2) {
            if (mutually_inclusive(*it1, *it2)) continue;
            mutually_exclusive(*it1, *it2) = true;
            LOG4("(" << phv.field(*it1)->name << ", " << phv.field(*it2)->name << ")");
        }
    }
}
