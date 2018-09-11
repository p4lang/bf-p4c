#include "phv/analysis/meta_live_range.h"

bool MetadataLiveRange::overlaps(std::pair<int, int>& range1, std::pair<int, int>& range2) {
    return overlaps(range1.first, range1.second, range2.first, range2.second);
}

bool MetadataLiveRange::overlaps(int minStage1, int maxStage1, int minStage2, int
        maxStage2) {
    bool range1LTrange2 = ((minStage1 + DEP_DIST) < minStage2) && ((maxStage1 + DEP_DIST) <
            minStage2);
    bool range2LTrange1 = ((minStage2 + DEP_DIST) < minStage1) && ((maxStage2 + DEP_DIST) <
            minStage1);
    return (range1LTrange2 || range2LTrange1);
}


Visitor::profile_t MetadataLiveRange::init_apply(const IR::Node* root) {
    livemap.clear();
    minStages.clear();
    overlay.clear();
    max_num_min_stages = -1;
    BUG_CHECK(dg.finalized, "Dependence graph is not populated.");
    return Inspector::init_apply(root);
}

bool MetadataLiveRange::preorder(const IR::MAU::Table* t) {
    int minStage = dg.min_stage(t);
    minStages[minStage].insert(t);
    if (minStage > max_num_min_stages)
        max_num_min_stages = minStage;
    return true;
}

void MetadataLiveRange::setFieldLiveMap(const PHV::Field* f) {
    LOG2("    Setting live range for field " << f);
    // minUse = earliest stage for uses of the field.
    // maxUse = latest stage for uses of the field.
    // minDef = earliest stage for defs of the field.
    // maxDef = latest stage for defs of the field.
    // Set the min values initially to the deparser, and the max values to the parser initially.
    const int DEPARSER = max_num_min_stages + 1;
    int minUse = DEPARSER;
    int minDef = DEPARSER;
    int maxUse = -1;
    int maxDef = -1;

    // For each use of the field, parser imply stage -1, deparser imply stage `Devices::numStages`
    // (12 for Tofino), and a table implies the corresponding dg.min_stage.
    for (const FieldDefUse::locpair use : defuse.getAllUses(f->id)) {
        const IR::BFN::Unit* use_unit = use.first;
        if (use_unit->is<IR::BFN::ParserState>() || use_unit->is<IR::BFN::Parser>()) {
            // Ignore parser use if field is marked as not parsed.
            if (notParsedFields.count(f)) continue;
            // There is no need to set the maxUse here, because maxUse is either -1 (if there is no
            // other use) or a non-negative value (which does not need to be updated).
            LOG4("\t  Used in parser.");
            minUse = -1;
        } else if (use_unit->is<IR::BFN::Deparser>()) {
            // Ignore deparser use if field is marked as not deparsed.
            if (notDeparsedFields.count(f)) continue;
            // There is no need to set the minUse here, because minUse is either DEPARSER (if there
            // is no other use) or a between [-1, max_num_min_stages] (which does not need to be
            // updated).
            LOG4("\t  Used in deparser.");
            maxUse = DEPARSER;
        } else if (use_unit->is<IR::MAU::Table>()) {
            const auto* t = use_unit->to<IR::MAU::Table>();
            int use_stage = dg.min_stage(t);
            LOG4("\t  Used in stage " << use_stage << " in table " << t->name);
            // Update minUse and maxUse based on the min_stage of the table.
            if (use_stage < minUse)
                minUse = use_stage;
            if (use_stage > maxUse)
                maxUse = use_stage;
        } else {
            BUG("Unknown unit encountered %1%", use_unit->toString());
        }
    }

    // Set live range for every def of the field.
    for (const FieldDefUse::locpair def : defuse.getAllDefs(f->id)) {
        const IR::BFN::Unit* def_unit = def.first;
        // If the field is specified as pa_no_init, and it has an uninitialized read, we ignore the
        // compiler-inserted parser initialization.
        if (noInitFields.count(f) && defuse.hasUninitializedRead(f->id)) {
            if (def_unit->is<IR::BFN::ParserState>()) {
                LOG2("Ignoring def of field " << f << " with uninitialized read and def in "
                     "parser state " << DBPrint::Brief << def_unit);
                continue;
            }
        }
        // If the field is not specified as pa_no_init and has a def in the parser:
        // 1. If the field does not have an uninitialized read and is not specified as not parsed,
        // and is not an ingress bridged field, then its def in the parser is `real` and so must be
        // taken into account.
        if (def_unit->is<IR::BFN::ParserState>() || def_unit->is<IR::BFN::Parser>()) {
            if (!defuse.hasUninitializedRead(f->id) && !notParsedFields.count(f) && !(f->bridged &&
                        f->gress == INGRESS)) {
                minDef = -1;
                LOG4("\t  Field with initialized read defined in parser.");
                continue;
            }
            // 2. For all other fields, if the def includes the INGRESS_PARSER_ENTRY (for ingress)
            // or the EGRESS_PARSER_ENTRY (for egress) parser state, then this is the implicit
            // initialization inserted by the compiler and so, can be safely ignored for live range
            // analysis.
            if (def_unit->is<IR::BFN::ParserState>()) {
                if (def_unit->to<IR::BFN::ParserState>()->name.startsWith(INGRESS_PARSER_ENTRY) &&
                    def_unit->to<IR::BFN::ParserState>()->name.startsWith(EGRESS_PARSER_ENTRY)) {
                    LOG4("\t  Defined in parser.");
                    minDef = -1;
                }
            }
        } else if (def_unit->is<IR::BFN::Deparser>()) {
            if (notDeparsedFields.count(f)) continue;
            maxDef = DEPARSER;
            LOG4("\t  Defined in deparser.");
        } else if (def_unit->is<IR::MAU::Table>()) {
            const auto* t = def_unit->to<IR::MAU::Table>();
            int def_stage = dg.min_stage(t);
            LOG4("\t  Defined in stage " << def_stage << " in table " << t->name);
            if (def_stage < minDef)
                minDef = def_stage;
            if (def_stage > maxDef)
                maxDef = def_stage;
        } else {
            BUG("Unknown unit encountered %1%", def_unit->toString());
        }
    }
    LOG2("\t  minUse: " << minUse << ", minDef: " << minDef);
    LOG2("\t  maxUse: " << maxUse << ", maxDef: " << maxDef);
    livemap[f->id] = std::make_pair(std::min(minUse, minDef), std::max(maxUse, maxDef));
    LOG2("\tLive range for " << f->name << " is [" << livemap[f->id].first << ", " <<
         livemap[f->id].second << "].");
}

void MetadataLiveRange::setPaddingFieldLiveMap(const PHV::Field* f) {
    const int DEPARSER = max_num_min_stages + 1;
    // For padding fields (marked by alwaysPackable), the live range is the deparser (for ingress
    // fields) and the parser (for egress fields).
    if (f->gress == INGRESS) {
        livemap[f->id] = std::make_pair(DEPARSER, DEPARSER);
    } else if (f->gress == EGRESS) {
        livemap[f->id] = std::make_pair(-1, -1);
    } else if (f->gress == GHOST) {
        livemap[f->id] = std::make_pair(DEPARSER, DEPARSER);
    }
}

void MetadataLiveRange::end_apply() {
    // Set of fields whose live ranges must be calculated.
    ordered_set<const PHV::Field*> fieldsConsidered;
    for (const PHV::Field& f : phv) {
        // POV bits are always live, so ignore.
        if (f.pov) continue;
        bool isNotParsed = notParsedFields.count(&f);
        bool isNotDeparsed = notDeparsedFields.count(&f);
        // Ignore header fields or fields that do not have associated live range affecting pragmas.
        if (!f.bridged && !f.metadata && !f.alwaysPackable && !f.privatizable() && !isNotParsed &&
                !isNotDeparsed)
            continue;
        // Ignore unreferenced fields because they are not allocated anyway.
        if (!uses.is_referenced(&f))
            continue;
        fieldsConsidered.insert(&f);
    }
    for (const auto* f : fieldsConsidered) {
        if (f->alwaysPackable)
            setPaddingFieldLiveMap(f);
        else
            setFieldLiveMap(f);
    }
    LOG1("Metadata live range overlay potential, subject to initialization");
    for (const auto* f1 : fieldsConsidered) {
        for (const auto* f2 : fieldsConsidered) {
            if (f1 == f2) continue;
            std::pair<int, int> range1 = livemap[f1->id];
            std::pair<int, int> range2 = livemap[f2->id];
            if (overlaps(range1, range2)) {
                overlay(f1->id, f2->id) = true;
                LOG4("    (" << f1->name << ", " << f2->name);
            }
        }
    }
    if (LOGGING(1))
        printLiveRanges();
}

void MetadataLiveRange::printLiveRanges() const {
    std::stringstream dashes;
    const int DEPARSER = max_num_min_stages + 1;
    auto numStages = DEPARSER;
    const unsigned dashWidth = 125 + (numStages + 2) * 3;
    for (unsigned i = 0; i < dashWidth; i++)
        dashes << "-";
    LOG1(dashes.str());
    std::stringstream colTitle;
    colTitle << (boost::format("%=100s") % "Field Name") << "|  gress  | P |";
    for (int i = 0; i < numStages; i++)
        colTitle << boost::format("%=3s") % i << "|";
    colTitle << " D |";
    LOG1(colTitle.str());
    LOG1(dashes.str());
    for (auto entry : livemap) {
        const auto* f = phv.field(entry.first);
        int minUse = entry.second.first;
        int maxUse = entry.second.second;
        std::stringstream ss;
        ss << boost::format("%=100s") % f->name << "|" << boost::format("%=9s") % f->gress << "|";
        for (int i = -1; i <= numStages; i++) {
            if (minUse <= i && i <= maxUse)
                ss << " x |";
            else
                ss << "   |"; }
        LOG1(ss.str());
    }
    LOG1(dashes.str());
}
