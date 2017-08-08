#include "parser_overlay.h"
#include <sstream>
#include <typeinfo>
#include "lib/log.h"
#include "ir/ir.h"


void ParserOverlay::mark(const PhvInfo::Field* f) {
    if (!f || f->metadata) return;
    int new_field = f->id;
    if (fields_encountered[new_field])
        return;
    fields_encountered[new_field] = true;
    mutually_inclusive[new_field] |= fields_encountered;
}

void ParserOverlay::mark(const IR::HeaderRef* hr) {
    if (!hr) return;
    for (int id : phv.struct_info(hr).field_ids())
        mark(phv.field(id));
}

bool ParserOverlay::preorder(const IR::Expression *e) {
    auto *f = phv.field(e);
    auto *hr = e->to<IR::HeaderRef>();
    if (!f && !hr) return true;
    mark(f);
    mark(hr);
    return false;
}

void ParserOverlay::flow_merge(Visitor& other_) {
    ParserOverlay &other = dynamic_cast<ParserOverlay &>(other_);
    fields_encountered |= other.fields_encountered;
    mutually_inclusive |= other.mutually_inclusive;
}

void ParserOverlay::end_apply() {
    LOG4("mutually exclusive fields:");
    for ( auto it1 = fields_encountered.begin();
          it1 != fields_encountered.end();
          ++it1 ) {
        for (auto it2 = it1; it2 != fields_encountered.end(); ++it2) {
            if (mutually_inclusive(*it1, *it2)) continue;
            mutually_exclusive(*it1, *it2) = true;
            LOG4("(" << phv.field(*it1)->name << ", " << phv.field(*it2)->name << ")");
        }
    }
}
