#include "lib/ordered_set.h"
#include "live_range_overlay.h"
#include "ir/ir.h"
#include "tofino/ir/gress.h"

// happens_before(x, y) means x MUST happen before Y.  Hence,
// !happens_before(y, x) implies that x MAY happen before Y.
bool LiveRangeOverlay::may_happen_before(
    const IR::Tofino::Unit *x,
    const IR::Tofino::Unit *y) const {
    return !happens_before(y, x);
}

// Field f is definitely dead at unit u if there does not exist a
// read-after-write dependence from uw to ur such that uw may happen before
// u and ur may happen after.
bool LiveRangeOverlay::is_dead_at(const PhvInfo::Field &f, const IR::Tofino::Unit *u) const {
    for (const FieldDefUse::locpair ur_loc : defuse.getAllUses(f.id)) {
        const IR::Tofino::Unit *ur = ur_loc.first;
        if (defuse.getDefs(ur_loc).size() == 0) {
            // Uninitialized read---live range begins "before" the parser, when
            // the hardware implicitly initializes all metadata to zero.
            // Hence, this field may be live if u may happen before ur.

            // TODO: egress_spec is special and considered uninitialized until
            // writen.  This should be changed to use Tofino native names.
            if (strstr(f.name, "egress_spec"))
                continue;

            if (may_happen_before(u, ur))
                return false; }
        for (auto uw_loc : defuse.getDefs(ur_loc)) {
            const IR::Tofino::Unit *uw = uw_loc.first;
            // If uw may happen before u and u may happen before ur, then f may
            // be live.
            if (may_happen_before(uw, u) && may_happen_before(u, ur))
                return false; } }
    return true;
}

void LiveRangeOverlay::end_apply() {
    LOG4("---------------------------------------------------");
    LOG4("Live Range Analysis");

    // NB: Fields/units are matched by gress.
    // NB: Only metadata fields are considered.

    // Fields that are not definitely dead are possibly live.
    map<int, ordered_set<const IR::Tofino::Unit *>> livemap;
    for (const PhvInfo::Field &f : phv) {
        if (!f.metadata)
            continue;
        LOG4("checking liveness of " << f.name);
        ordered_set<const IR::Tofino::Unit *> *all_units;
        all_units = f.gress == INGRESS ? &all_ingress_units : &all_egress_units;
        for (const IR::Tofino::Unit *u : *all_units) {
            if (is_dead_at(f, u)) {
                LOG4("    dead at " << DBPrint::Brief << u);
            } else {
                LOG4("    maybe live at " << DBPrint::Brief << u);
                livemap[f.id].insert(u); } } }

    // Fields can be overlaid if they may never be live in the same
    // unit.
    LOG4("mutually exclusive metadata:");
    for (auto f1 : phv) {
        if (!f1.metadata)
            continue;
        for (auto f2 : phv) {
            if (!f2.metadata || f1.gress != f2.gress)
                continue;
            if (!intersects(livemap[f1.id], livemap[f2.id])) {
                LOG4("(" << f1.name << ", " << f2.name << ")");
                overlay(f1.id, f2.id) = true; } } }
}

bool LiveRangeOverlay::happens_before(
    const IR::Tofino::Unit *u1,
    const IR::Tofino::Unit *u2) const {
    // This relation is not reflexive.
    if (u1 == u2)
        return false;

    // Ingress always happens before egress.
    if (u1->thread() == INGRESS && u2->thread() == EGRESS)
        return true;
    else if (u1->thread() == EGRESS && u2->thread() == INGRESS)
        return false;

    if (dynamic_cast<const IR::Tofino::ParserState *>(u1)) {
        // Parser states are considered to happen at the same time for the
        // purpose of live range analysis.
        if (dynamic_cast<const IR::Tofino::ParserState *>(u2))
            return false;

        // If u2 is not a parse state, it must be a table or deparser, which
        // happens after the u1 parse state.
        if (dynamic_cast<const IR::MAU::Table *>(u2) ||
            dynamic_cast<const IR::Tofino::Deparser *>(u2))
            return true;

        BUG("Unexpected kind of Tofino::Unit."); }

    if (auto t1 = dynamic_cast<const IR::MAU::Table *>(u1)) {
        if (dynamic_cast<const IR::Tofino::ParserState *>(u2))
            return false;
        if (auto t2 = dynamic_cast<const IR::MAU::Table *>(u2)) {
            if (t1->logical_id == -1 && t2->logical_id == -1) {
                return dg.happens_before(t1, t2);
            } else if (t1 ->logical_id == -1 || t2->logical_id == -1) {
                BUG("Partial table allocation");
            } else {
                int t1_stage = static_cast<int>(t1->logical_id / 16);
                int t2_stage = static_cast<int>(t2->logical_id / 16);
                return t1_stage < t2_stage; } }
        if (dynamic_cast<const IR::Tofino::Deparser *>(u2))
            return true;
        BUG("Unexpected kind of Tofino::Unit."); }

    if (dynamic_cast<const IR::Tofino::Deparser *>(u1)) {
        if (dynamic_cast<const IR::Tofino::ParserState *>(u2) ||
            dynamic_cast<const IR::MAU::Table *>(u2))
            return false;
        if (dynamic_cast<const IR::Tofino::Deparser *>(u2))
            return true; }

    BUG("Unexpected kind of Tofino::Unit.");
}

void LiveRangeOverlay::get_uninitialized_reads(
    ordered_map<int, FieldDefUse::LocPairSet> &out) const {
    // If a field use does not have a def, then it is reading an unintialized
    // value.
    for (const PhvInfo::Field &f : phv) {
        for (const FieldDefUse::locpair use : defuse.getAllUses(f.id)) {
            if (!defuse.getDefs(use).size()) {
                LOG4("uninitialized read of " << f.name <<
                     " at "<< DBPrint::Brief <<
                     use.first << ":" << DBPrint::Brief << use.second);
                out[f.id].insert(use); } } }
}
