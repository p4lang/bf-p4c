#include "lib/ordered_set.h"
#include "live_range_overlay.h"
#include "ir/ir.h"
#include "tofino/ir/gress.h"

void LiveRangeOverlay::end_apply() {
    LOG4("---------------------------------------------------");
    LOG4("Live Range Analysis");

    // NB: Fields/units are matched by gress.
    // NB: Only metadata fields are considered.

    // Find all units in which each field is definitely dead.  Field f is dead
    // at unit u if, for every read of f that happens after u at u', there
    // exists a u'' that writes f that happens between u and u'.

    // Fields that are not definitely dead are possibly live.
    map<int, ordered_set<const IR::Tofino::Unit *>> livemap;
    for (const PhvInfo::Field &f : phv) {
        if (!f.metadata)
            continue;
        LOG4("checking liveness of " << f.name);
        ordered_set<const IR::Tofino::Unit *> *all_units;
        all_units = f.gress == INGRESS ? &all_ingress_units : &all_egress_units;
        for (const IR::Tofino::Unit *u : *all_units) {
            bool dead = true;
            for (const FieldDefUse::locpair ur_loc : defuse.getAllUses(f.id)) {
                const IR::Tofino::Unit *ur = ur_loc.first;
                if (!happens_before(ur, u)) {
                    dead = false;
                    for (const FieldDefUse::locpair uw_loc : defuse.getAllDefs(f.id)) {
                        const IR::Tofino::Unit *uw = uw_loc.first;
                        if (happens_before(u, uw) && happens_before(uw, ur)) {
                            dead = true;
                            break; } } }
                if (!dead) break; }
            if (dead) {
                LOG4("    dead at " << DBPrint::Brief << u);
            } else {
                LOG4("    live at " << DBPrint::Brief << u);
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
    const IR::Tofino::Unit *u2) {
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
    ordered_map<int, FieldDefUse::LocPairSet> &out) {
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
