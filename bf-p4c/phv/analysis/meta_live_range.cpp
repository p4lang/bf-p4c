#include "phv/analysis/meta_live_range.h"

cstring MetadataLiveRange::printAccess(int access) {
    switch (access) {
        case 1: return "R";
        case 2: return "W";
        case 3: return "RW";
        default: return "U";
    }
}

bool MetadataLiveRange::overlaps(std::pair<int, int>& range1, std::pair<int, int>& range2, int
        depDist) {
    return overlaps(range1.first, range1.second, range2.first, range2.second, depDist);
}

bool MetadataLiveRange::overlaps(int minStage1, int maxStage1, int minStage2, int
        maxStage2, int depDist) {
    bool range1LTrange2 = ((minStage1 + depDist) < minStage2) && ((maxStage1 + depDist) <
            minStage2);
    bool range2LTrange1 = ((minStage2 + depDist) < minStage1) && ((maxStage2 + depDist) <
            minStage1);
    return (range1LTrange2 || range2LTrange1);
}


Visitor::profile_t MetadataLiveRange::init_apply(const IR::Node* root) {
    livemap.clear();
    livemapUsage.clear();
    minStages.clear();
    overlay.clear();
    BUG_CHECK(dg.finalized, "Dependence graph is not populated.");
    return Inspector::init_apply(root);
}

bool MetadataLiveRange::preorder(const IR::MAU::Table* t) {
    int minStage = dg.min_stage(t);
    minStages[minStage].insert(t);
    return true;
}

void MetadataLiveRange::setFieldLiveMap(const PHV::Field* f) {
    LOG2("    Setting live range for field " << f);
    // minUse = earliest stage for uses of the field.
    // maxUse = latest stage for uses of the field.
    // minDef = earliest stage for defs of the field.
    // maxDef = latest stage for defs of the field.
    // Set the min values initially to the deparser, and the max values to the parser initially.
    const int DEPARSER = dg.max_min_stage + 1;
    int minUse = DEPARSER;
    int minDef = DEPARSER;
    int maxUse = -1;
    int maxDef = -1;
    int maxUseAccess = 0;
    int minUseAccess = 0;
    int minDefAccess = 0;
    int maxDefAccess = 0;

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
            minUseAccess = READ;
        } else if (use_unit->is<IR::BFN::Deparser>()) {
            // Ignore deparser use if field is marked as not deparsed.
            if (notDeparsedFields.count(f)) continue;
            // There is no need to set the minUse here, because minUse is either DEPARSER (if there
            // is no other use) or a between [-1, dg.max_min_stage] (which does not need to be
            // updated).
            LOG4("\t  Used in deparser.");
            maxUse = DEPARSER;
            maxUseAccess = READ;
        } else if (use_unit->is<IR::MAU::Table>()) {
            const auto* t = use_unit->to<IR::MAU::Table>();
            int use_stage = dg.min_stage(t);
            LOG4("\t  Used in stage " << use_stage << " in table " << t->name);
            // Update minUse and maxUse based on the min_stage of the table.
            // If the minUse and maxUse are encountered for the first time, overwrite the earlier
            // access information. If another use with the same minUse/maxUse is encountered, then
            // append the access information with the access information for this unit.
            if (use_stage < minUse) {
                minUse = use_stage;
                minUseAccess = READ;
            } else if (use_stage == minUse) {
                minUseAccess |= READ;
            }
            if (use_stage > maxUse) {
                maxUse = use_stage;
                maxUseAccess = READ;
            } else if (use_stage == maxUse) {
                maxUseAccess |= READ;
            }
        } else {
            BUG("Unknown unit encountered %1%", use_unit->toString());
        }
    }

    // Set live range for every def of the field.
    for (const FieldDefUse::locpair def : defuse.getAllDefs(f->id)) {
        const IR::BFN::Unit* def_unit = def.first;
        // If the definition is of type ImplicitParserInit, then it was added to account for
        // uninitialized reads, and can be safely ignored. Account for all other parser
        // initializations, as long as the field is not marked notParsed.
        if (def_unit->is<IR::BFN::ParserState>() || def_unit->is<IR::BFN::Parser>()) {
            // If the def is an implicit read inserted only for metadata fields to account for
            // uninitialized reads, then ignore that initialization.
            if (def.second->is<ImplicitParserInit>()) {
                LOG4("\t\tIgnoring implicit parser init.");
                continue;
            }
            if (!notParsedFields.count(f) && !(f->bridged && f->gress == INGRESS)) {
                LOG4("\t  Field defined in parser.");
                minDef = -1;
                minDefAccess = WRITE;
                continue;
            }
        } else if (def_unit->is<IR::BFN::Deparser>()) {
            if (notDeparsedFields.count(f)) continue;
            maxDef = DEPARSER;
            maxDefAccess = WRITE;
            LOG4("\t  Defined in deparser.");
        } else if (def_unit->is<IR::MAU::Table>()) {
            const auto* t = def_unit->to<IR::MAU::Table>();
            int def_stage = dg.min_stage(t);
            LOG4("\t  Defined in stage " << def_stage << " in table " << t->name);
            if (def_stage < minDef) {
                minDef = def_stage;
                minDefAccess = WRITE;
            } else if (def_stage == minDef) {
                minDefAccess |= WRITE;
            }
            if (def_stage > maxDef) {
                maxDef = def_stage;
                maxDefAccess = WRITE;
            } else if (def_stage == maxDef) {
                maxDefAccess |= WRITE;
            }
        } else {
            BUG("Unknown unit encountered %1%", def_unit->toString());
        }
    }
    LOG2("\t  minUse: " << minUse << " (" << printAccess(minUseAccess) << "), minDef: " << minDef <<
         " (" << printAccess(minDefAccess) << ")");
    LOG2("\t  maxUse: " << maxUse << " (" << printAccess(maxUseAccess) << "), maxDef: " << maxDef <<
         " (" << printAccess(maxDefAccess) << ")");
    livemap[f->id] = std::make_pair(std::min(minUse, minDef), std::max(maxUse, maxDef));

    // Update the access information for the minStage and maxStage uses by synthesizing the separate
    // access information maintained for uses and defs of the field.
    int minStageAccess = (minUse == minDef) ? (minUseAccess | minDefAccess) :
                        ((minUse > minDef) ? minDefAccess : minUseAccess);
    int maxStageAccess = (maxUse == maxDef) ? (maxUseAccess | maxDefAccess) :
                        ((maxUse < maxDef) ? maxDefAccess : maxUseAccess);
    // If the field's live range is only one stage, then make sure the usages are set up
    // correct.
    if (livemap[f->id].first == livemap[f->id].second) {
        int access = minStageAccess | maxStageAccess;
        livemapUsage[f->id] = std::make_pair(access, access);
    } else {
        livemapUsage[f->id] = std::make_pair(minStageAccess, maxStageAccess);
    }
    LOG2("\tLive range for " << f->name << " is [" << livemap[f->id].first << ", " <<
         livemap[f->id].second << "]. Access is [" << printAccess(livemapUsage[f->id].first) << ", "
         << printAccess(livemapUsage[f->id].second) << "].");
}

void MetadataLiveRange::setPaddingFieldLiveMap(const PHV::Field* f) {
    const int DEPARSER = dg.max_min_stage + 1;
    // For padding fields (marked by overlayable), the live range is the deparser (for
    // ingress fields) and the parser (for egress fields).
    if (f->gress == INGRESS) {
        livemap[f->id] = std::make_pair(DEPARSER, DEPARSER);
    } else if (f->gress == EGRESS) {
        livemap[f->id] = std::make_pair(-1, -1);
    } else if (f->gress == GHOST) {
        livemap[f->id] = std::make_pair(DEPARSER, DEPARSER);
    }
}

void MetadataLiveRange::end_apply() {
    // If there are no tables, then dg.max_min_stage is -1, and this analysis is not required.
    if (dg.max_min_stage < 0) return;

    // Set of fields whose live ranges must be calculated.
    ordered_set<const PHV::Field*> fieldsConsidered;
    for (const PHV::Field& f : phv) {
        // Ignore metadata fields marked as no_init because initialization would cause their
        // container to become valid.
        if (f.is_invalidate_from_arch()) continue;
        if (noInitFields.count(&f) && !noOverlay.get_no_overlay_fields().count(&f)) {
            fieldsConsidered.insert(&f);
            continue;
        }
        // POV bits are always live, so ignore.
        if (f.pov) continue;
        // Ignore pa_no_overlay fields.
        if (noOverlay.get_no_overlay_fields().count(&f)) continue;
        // Ignore unreferenced fields because they are not allocated anyway.
        if (!uses.is_referenced(&f))
            continue;
        fieldsConsidered.insert(&f);
    }
    for (const auto* f : fieldsConsidered) {
        if (f->overlayable)
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
            // No overlay possible if fields are of different gresses.
            if (f1->gress != f2->gress) {
                overlay(f1->id, f2->id) = false;
                continue;
            }
            // pair-wise no_overlay constraint check.
            if (!noOverlay.can_overlay(f1, f2)) {
                continue;
            }
            // If the live ranges of fields differ by more than DEP_DIST stages, then overlay due to
            // live range shrinking is possible.
            if (overlaps(range1, range2)) {
                overlay(f1->id, f2->id) = true;
                LOG3("    overlay(" << f1->name << ", " << f2->name << ")");
            }
            // For pa_no_init fields, dependence distance is of little less consideration.
            if (!overlay(f1->id, f2->id)) {
                if (noInitFields.count(f1) && noInitFields.count(f2)) {
                    if (overlaps(range1, range2, 0)) {
                        overlay(f1->id, f2->id) = true;
                        LOG1("    overlay noInit(" << f1->name << ", " << f2->name << ")");
                    }
                } else if (noInitFields.count(f1) && !noInitFields.count(f2)) {
                    if (range2.first < range1.first && range2.second < range1.first) {
                        overlay(f1->id, f2->id) = true;
                        LOG1("    overlay noInitF1(" << f1->name << ", " << f2->name << ")");
                    }
                } else if (noInitFields.count(f2) && !noInitFields.count(f1)) {
                    if (range1.first < range2.first && range1.second < range2.first) {
                        overlay(f1->id, f2->id) = true;
                        LOG1("    overlay noInitF2(" << f1->name << ", " << f2->name << ")");
                    }
                }
            }
        }
    }
    if (LOGGING(1))
        printLiveRanges();
}

void MetadataLiveRange::printLiveRanges() const {
    LOG1("LIVERANGE REPORT");
    std::stringstream dashes;
    const int DEPARSER = dg.max_min_stage + 1;
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
