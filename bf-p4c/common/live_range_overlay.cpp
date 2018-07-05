#include "live_range_overlay.h"

#include <numeric>
#include "lib/ordered_set.h"
#include "ir/ir.h"
#include "bf-p4c/ir/gress.h"

// happens_before(x, y) means x MUST happen before Y.  Hence,
// !happens_before(y, x) implies that x MAY happen before Y.
bool LiveRangeOverlay::may_happen_before(
    const IR::BFN::Unit *x,
    const IR::BFN::Unit *y) const {
    return !happens_before(y, x);
}

// Field f is definitely dead at unit u if there does not exist a
// read-after-write dependence from uw to ur such that uw may happen before
// u and ur may happen after.
bool LiveRangeOverlay::is_dead_at(const PHV::Field &f, const IR::BFN::Unit *u) const {
    for (const FieldDefUse::locpair use : defuse.getAllUses(f.id)) {
        const IR::BFN::Unit *use_unit = use.first;
        for (auto def : defuse.getDefs(use)) {
            const IR::BFN::Unit *def_unit = def.first;
            // If the field is specified as pa_no_init and if it has uninitialized reads, then
            // ignore the parser unit defs.
            if (noInitFields.count(&f) && defuse.hasUninitializedRead(f.id)) {
                if (def_unit->is<IR::BFN::ParserState>()) {
                    LOG2("Ignoring def of field " << f << " with uninitialized read and def in "
                         " parser state " << DBPrint::Brief << def_unit);
                    continue;
                }
            }
            // If uw may happen before u and u may happen before ur, then f may
            // be live.
            if (may_happen_before(def_unit, u) && may_happen_before(u, use_unit))
                return false; } }
    return true;
}

void LiveRangeOverlay::end_apply() {
    LOG4("---------------------------------------------------");
    LOG4("Live Range Analysis");

    // NB: Fields/units are matched by gress.
    // NB: Only metadata fields are considered.

    // Fields that are not definitely dead are possibly live.
    ordered_map<int, ordered_set<const IR::BFN::Unit *>> livemap;
    for (const PHV::Field &f : phv) {
        // Only consider for live range overlay if the field is non-bridged metadata or a bridged
        // metadata padding field or is a privatizable field (PHV copy of a privatized field).
        if (!f.metadata && !f.alwaysPackable && !f.privatizable())
            continue;
        LOG4("checking liveness of " << f.name);
        livemap[f.id] = { };
        ordered_set<const IR::BFN::Unit *> *all_units;
        all_units = f.gress == INGRESS ? &all_ingress_units : &all_egress_units;
        for (const IR::BFN::Unit *u : *all_units) {
            if (f.alwaysPackable) {
                // Bridged metadata padding field is valid only in ingress deparser and egress
                // parser.
                bool isEgressParser = u->is<IR::BFN::ParserState>() && u->thread() ==  EGRESS;
                bool isIngressDeparser = u->is<IR::BFN::Deparser>() && u->thread() == INGRESS;
                if (isEgressParser || isIngressDeparser) {
                    LOG4("    live at " << DBPrint::Brief << u);
                    livemap[f.id].insert(u);
                } else {
                    LOG4("    dead at " << DBPrint::Brief << u); }
            } else {
                if (is_dead_at(f, u)) {
                    LOG4("    dead at " << DBPrint::Brief << u);
                } else {
                    LOG4("    maybe live at " << DBPrint::Brief << u);
                    livemap[f.id].insert(u); } } } }

    if (LOGGING(1))
        printLiveRanges(livemap);

    // Fields can be overlaid if they may never be live in the same
    // unit.
    // Do not overlay intrinsic metadata or pov bits because they are unconditionally read in the
    // deparser.
    LOG4("mutually exclusive metadata:");
    // Fields marked as no overlay by pa_no_overlay
    for (auto f1 : phv) {
        if ((!f1.metadata && !f1.alwaysPackable && !f1.privatizable()) || f1.pov ||
                f1.deparsed_to_tm())
            continue;
        if (noOverlay.count(&f1))
            continue;
        for (auto f2 : phv) {
            if (f1.id == f2.id) continue;  // field should never be mutex to it self.
            if ((!f2.metadata && !f2.alwaysPackable && !f2.privatizable()) || f2.pov ||
                 f1.gress != f2.gress || f2.deparsed_to_tm())
                continue;
            if (noOverlay.count(&f2))
                continue;
            BUG_CHECK(livemap.count(f1.id), "livemap not generated on %1%", f1);
            BUG_CHECK(livemap.count(f2.id), "livemap not generated on %1%", f2);
            if (!intersects(livemap[f1.id], livemap[f2.id])) {
                LOG4("(" << f1.name << ", " << f2.name << ")");
                overlay(f1.id, f2.id) = true; } } }
}

bool LiveRangeOverlay::happens_before(
    const IR::BFN::Unit *u1,
    const IR::BFN::Unit *u2) const {
    // This relation is not reflexive.
    if (u1 == u2)
        return false;

    // Ingress always happens before egress.
    if (u1->thread() == INGRESS && u2->thread() == EGRESS)
        return true;
    else if (u1->thread() == EGRESS && u2->thread() == INGRESS)
        return false;

    if (u1->is<IR::BFN::Parser>() || u1->is<IR::BFN::ParserState>()) {
        // Parser states are considered to happen at the same time for the
        // purpose of live range analysis.
        if (u2->is<IR::BFN::Parser>() || u2->is<IR::BFN::ParserState>())
            return false;

        // If u2 is not a parse state, it must be a table or deparser, which
        // happens after the u1 parse state.
        if (u2->is<IR::MAU::Table>() ||
            u2->is<IR::BFN::Deparser>())
            return true;

        BUG("Unexpected kind of BFN::Unit."); }

    if (auto t1 = u1->to<IR::MAU::Table>()) {
        if (u2->is<IR::BFN::Parser>() || u2->is<IR::BFN::ParserState>())
            return false;
        if (auto t2 = u2->to<IR::MAU::Table>()) {
            if (t1->logical_id == -1 && t2->logical_id == -1) {
                return dg.happens_before(t1, t2);
            } else if (t1 ->logical_id == -1 || t2->logical_id == -1) {
                BUG("Partial table allocation");
            } else {
                int t1_stage = static_cast<int>(t1->logical_id / 16);
                int t2_stage = static_cast<int>(t2->logical_id / 16);
                return t1_stage < t2_stage; } }
        if (u2->is<IR::BFN::Deparser>())
            return true;
        BUG("Unexpected kind of BFN::Unit."); }

    if (u1->is<IR::BFN::Deparser>()) {
        if (u2->is<IR::BFN::Parser>() || u2->is<IR::BFN::ParserState>() ||
            u2->is<IR::MAU::Table>())
            return false;
        if (u2->is<IR::BFN::Deparser>())
            return true; }

    BUG("Unexpected kind of BFN::Unit.");
}

void LiveRangeOverlay::printLiveRanges(ordered_map<int, ordered_set<const IR::BFN::Unit*>>& lm) {
    ordered_map<unsigned, unsigned> minStage;
    ordered_map<unsigned, unsigned> maxStage;
    std::stringstream dashes;

    auto numStages = Device::numStages();
    const unsigned dashWidth = 95 + (numStages + 2) * 3;
    for (unsigned i = 0; i < dashWidth; i++)
        dashes << "-";
    LOG1(dashes.str());
    std::stringstream colTitle;
    colTitle << (boost::format("%=70s") % "Field Name") << "|  gress  | P |";
    for (int i = 0; i < numStages; i++)
        colTitle << boost::format("%=3s") % i << "|";
    colTitle << " D |";
    LOG1(colTitle.str());
    LOG1(dashes.str());
    for (auto entry : lm) {
        const auto* f = phv.field(entry.first);
        bool usedInParser = false;
        bool usedInDeparser = false;
        ordered_set<unsigned> stages;
        for (auto u : entry.second) {
            if (dynamic_cast<const IR::BFN::ParserState *>(u))
                usedInParser = true;
            if (dynamic_cast<const IR::BFN::Deparser *>(u))
                usedInDeparser = true;
            if (const auto *t = dynamic_cast<const IR::MAU::Table *>(u))
                stages.insert(dg.min_stage(t));
        }
        minStage[entry.first] = std::accumulate(stages.begin(), stages.end(), numStages + 1, [](int
                    a, int b) { return std::min(a, b); });
        maxStage[entry.first] = std::accumulate(stages.begin(), stages.end(), -1, [](int a, int b)
                { return std::max(a, b); });
        std::stringstream ss;
        ss << boost::format("%=70s") % f->name << "|" << boost::format("%=9s") % f->gress << "|";
        if (usedInParser)
            ss << " x |";
        else
            ss << "   |";
        for (int i = 0; i < numStages; i++) {
            if (stages.count(i))
                ss << " x |";
            else
                ss << "   |"; }
        if (usedInDeparser)
            ss << " x |";
        else
            ss << "   |";
        LOG1(ss.str());
    }
    LOG1(dashes.str());
}
