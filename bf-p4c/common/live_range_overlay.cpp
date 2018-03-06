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
    for (const FieldDefUse::locpair ur_loc : defuse.getAllUses(f.id)) {
        const IR::BFN::Unit *ur = ur_loc.first;
        if (defuse.getDefs(ur_loc).size() == 0) {
            // Uninitialized read---live range begins "before" the parser, when
            // the hardware implicitly initializes all metadata to zero.
            // Hence, this field may be live if u may happen before ur.

            // XXX(hanw): remove this..
            // TODO: egress_spec is special and considered uninitialized until
            // writen.  This should be changed to use Tofino native names.
            if (strstr(f.name, "egress_spec"))
                continue;

            if (may_happen_before(u, ur))
                return false; }
        for (auto uw_loc : defuse.getDefs(ur_loc)) {
            const IR::BFN::Unit *uw = uw_loc.first;
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
    ordered_map<int, ordered_set<const IR::BFN::Unit *>> livemap;
    for (const PHV::Field &f : phv) {
        // Only consider for live range overlay if the field is non-bridged metadata or a bridged
        // metadata padding field
        if (!f.metadata && !f.alwaysPackable)
            continue;
        LOG4("checking liveness of " << f.name);
        ordered_set<const IR::BFN::Unit *> *all_units;
        all_units = f.gress == INGRESS ? &all_ingress_units : &all_egress_units;
        for (const IR::BFN::Unit *u : *all_units) {
            if (f.alwaysPackable) {
                bool isEgressParser = u->is<IR::BFN::ParserState>() && u->thread() ==  EGRESS;
                bool isIngressParser = u->is<IR::BFN::ParserState>() && u->thread() == INGRESS;
                if (isEgressParser || isIngressParser) {
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
    for (auto f1 : phv) {
        if ((!f1.metadata && !f1.alwaysPackable) || f1.pov || f1.deparsed_to_tm())
            continue;
        for (auto f2 : phv) {
            if ((!f2.metadata && !f2.alwaysPackable) || f2.pov || f1.gress != f2.gress ||
                    f2.deparsed_to_tm())
                continue;
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

    if (dynamic_cast<const IR::BFN::ParserState *>(u1)) {
        // Parser states are considered to happen at the same time for the
        // purpose of live range analysis.
        if (dynamic_cast<const IR::BFN::ParserState *>(u2))
            return false;

        // If u2 is not a parse state, it must be a table or deparser, which
        // happens after the u1 parse state.
        if (dynamic_cast<const IR::MAU::Table *>(u2) ||
            dynamic_cast<const IR::BFN::Deparser *>(u2))
            return true;

        BUG("Unexpected kind of BFN::Unit."); }

    if (auto t1 = dynamic_cast<const IR::MAU::Table *>(u1)) {
        if (dynamic_cast<const IR::BFN::ParserState *>(u2))
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
        if (dynamic_cast<const IR::BFN::Deparser *>(u2))
            return true;
        BUG("Unexpected kind of BFN::Unit."); }

    if (dynamic_cast<const IR::BFN::Deparser *>(u1)) {
        if (dynamic_cast<const IR::BFN::ParserState *>(u2) ||
            dynamic_cast<const IR::MAU::Table *>(u2))
            return false;
        if (dynamic_cast<const IR::BFN::Deparser *>(u2))
            return true; }

    BUG("Unexpected kind of BFN::Unit.");
}

void LiveRangeOverlay::get_uninitialized_reads(
    ordered_map<int, FieldDefUse::LocPairSet> &out) const {
    // If a field use does not have a def, then it is reading an unintialized
    // value.
    for (const PHV::Field &f : phv) {
        for (const FieldDefUse::locpair use : defuse.getAllUses(f.id)) {
            if (!defuse.getDefs(use).size()) {
                LOG4("uninitialized read of " << f.name <<
                     " at "<< DBPrint::Brief <<
                     use.first << ":" << DBPrint::Brief << use.second);
                out[f.id].insert(use); } } }
}

void LiveRangeOverlay::printLiveRanges(ordered_map<int, ordered_set<const IR::BFN::Unit*>>& lm) {
    ordered_map<unsigned, unsigned> minStage;
    ordered_map<unsigned, unsigned> maxStage;
    std::stringstream dashes;
    auto numStages = 12;
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
        minStage[entry.first] = std::accumulate(stages.begin(), stages.end(), 13, [](int a, int b)
                { return std::min(a, b); });
        maxStage[entry.first] = std::accumulate(stages.begin(), stages.end(), 0, [](int a, int b)
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
    LOG1(dashes);
}
