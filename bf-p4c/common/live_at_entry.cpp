#include "live_at_entry.h"
#include "bf-p4c/phv/phv_fields.h"
#include "ir/dump.h"

Visitor::profile_t LiveAtEntry::init_apply(const IR::Node *root) {
    auto rv = Inspector::init_apply(root);
    LOG3("LiveAtEntry(" << (void *)this << ")");
    if (LOGGING(5)) dump_notype(root);
    written.clear();
    return rv;
}

bool LiveAtEntry::preorder(const IR::Expression *e) {
    if (getParent<IR::BFN::ParserState>()) {
        /* Only expression child of ParserState is the select expression, which never actually
         * accesses the fields it refers to -- they're converted into references into the
         * input buffer at a later point.  For here, ignore them */
         return false; }
    if (auto *f = phv.field(e)) {
        if (isWrite()) {
            LOG4((void *)this << ": [" << e->id << "] write to " << f->name << "(" << f->id << ")");
            written[f->id] = 1;
        } else if (!written[f->id]) {
            LOG3((void *)this << ": [" << e->id << "] read unwritten " << f->name <<
                 "(" << f->id << ")");
            result[f->id] = 1; }
    }
    return true;
}

LiveAtEntry *LiveAtEntry::clone() const {
    auto *rv = new LiveAtEntry(*this);
    LOG4("flow_clone " << (void *)rv << " <- " << (void *)this << " [" << getOriginal()->id << "]");
    return rv;
}

void LiveAtEntry::flow_merge(Visitor &a_) {
    auto &a = dynamic_cast<LiveAtEntry&>(a_);
    LOG4("flow_merge " << (void *)&a << (a.flow_is_dead ? "(dead)" : "") << " -> " <<
         (void *)this << (flow_is_dead ? "(dead)" : "") << " [" << getOriginal()->id << "]");
    if (!a.flow_is_dead) {
        if (flow_is_dead)
            written = a.written;
        else
            written &= a.written;
        flow_is_dead = false; }
}

void LiveAtEntry::end_apply(const IR::Node *) {
    if (!LOGGING(2)) return;
    LOG2("Live at entry to program");
    for (auto &f : phv)
        if (result[f.id])
            LOG2("   " << f);
}
