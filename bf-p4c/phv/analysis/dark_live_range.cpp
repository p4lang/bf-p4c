#include "bf-p4c/mau/table_layout.h"
#include "bf-p4c/phv/analysis/dark_live_range.h"
#include "bf-p4c/phv/analysis/live_range_shrinking.h"
#include "bf-p4c/common/table_printer.h"

bool DarkLiveRange::overlaps(
        const int num_max_min_stages,
        const DarkLiveRangeEntry& range1,
        const DarkLiveRangeEntry& range2) {
    const int DEPARSER = num_max_min_stages + 1;
    bitvec f1Uses;
    bitvec f2Uses;
    unsigned index = 0;
    for (int i = 0; i <= DEPARSER; i++) {
        for (unsigned j : { READ, WRITE }) {
            StageAndAccess stageAndAccess = std::make_pair(i, PHV::FieldUse(j));
            if (range1.count(stageAndAccess)) {
                f1Uses.setbit(index);
                LOG5("\t\t  Setting f1 bit " << index << ", stage " << i << ": " <<
                     PHV::FieldUse(j));
            }
            if (range2.count(stageAndAccess)) {
                f2Uses.setbit(index);
                LOG5("\t\t  Setting f2 bit " << index << ", stage " << i << ": " <<
                     PHV::FieldUse(j));
            }
            ++index;
        }
    }
    LOG4("\t\tField 1 use: " << f1Uses << ", Field 2 use: " << f2Uses);
    bitvec combo = f1Uses & f2Uses;
    LOG4("\t\tcombo: " << combo << ", empty? " << (combo.popcount() != 0));
    return (combo.popcount() != 0);
}

Visitor::profile_t DarkLiveRange::init_apply(const IR::Node* root) {
    livemap.clear();
    overlay.clear();
    fieldToUnitUseMap.clear();
    BUG_CHECK(dg.finalized, "Dependence graph is not populated.");
    // For each use of the field, parser implies stage `dg.max_min_stage + 2`, deparser implies
    // stage `dg.max_min_stage + 1` (12 for Tofino), and a table implies the corresponding
    // dg.min_stage.
    DEPARSER = dg.max_min_stage + 1;
    livemap.setDeparserStageValue(DEPARSER);
    LOG1("Deparser is at " << DEPARSER << ", max stage: " << dg.max_min_stage);
    return Inspector::init_apply(root);
}

void DarkLiveRange::setFieldLiveMap(const PHV::Field* f) {
    LOG4("    Setting live range for field " << f);
    // minUse = earliest stage for uses of the field.
    // maxUse = latest stage for uses of the field.
    // minDef = earliest stage for defs of the field.
    // maxDef = latest stage for defs of the field.
    // Set the min values initially to the deparser, and the max values to the parser initially.
    for (const FieldDefUse::locpair use : defuse.getAllUses(f->id)) {
        const IR::BFN::Unit* use_unit = use.first;
        if (use_unit->is<IR::BFN::ParserState>() || use_unit->is<IR::BFN::Parser>()) {
            // Ignore parser use if field is marked as not parsed.
            if (notParsedFields.count(f)) {
                LOG4("\t  Ignoring field " << f << " use in parser");
                continue;
            }
            LOG4("\t  Used in parser.");
            livemap.addAccess(f, 0 /* stage */, READ, use_unit, false);
            livemap.addAccess(f, PARSER, READ, use_unit, false);
        } else if (use_unit->is<IR::BFN::Deparser>()) {
            // Ignore deparser use if field is marked as not deparsed.
            if (notDeparsedFields.count(f)) continue;
            LOG4("\t  Used in deparser.");
            livemap.addAccess(f, DEPARSER, READ, use_unit, false);
        } else if (use_unit->is<IR::MAU::Table>()) {
            const auto* t = use_unit->to<IR::MAU::Table>();
            int use_stage = dg.min_stage(t);
            LOG4("\t  Used in stage " << use_stage << " in table " << t->name);
            livemap.addAccess(f, use_stage, READ, use_unit, false);
        } else {
            BUG("Unknown unit encountered %1%", use_unit->toString());
        }
        fieldToUnitUseMap[f][use_unit] |= PHV::FieldUse(READ);
    }

    // Set live range for every def of the field.
    for (const FieldDefUse::locpair def : defuse.getAllDefs(f->id)) {
        const IR::BFN::Unit* def_unit = def.first;
        // If the field is specified as pa_no_init, and it has an uninitialized read, we ignore the
        // compiler-inserted parser initialization.
        if (noInitFields.count(f) && defuse.hasUninitializedRead(f->id)) {
            if (def_unit->is<IR::BFN::ParserState>()) {
                LOG4("Ignoring def of field " << f << " with uninitialized read and def in "
                     "parser state " << DBPrint::Brief << def_unit);
                continue;
            }
        }
        // If the field is not specified as pa_no_init and has a def in the parser, check if the def
        // is of type ImplicitParserInit, and if it is, we can safely ignore this def.
        if (def_unit->is<IR::BFN::ParserState>() || def_unit->is<IR::BFN::Parser>()) {
            if (def.second->is<ImplicitParserInit>()) {
                LOG4("\t\tIgnoring implicit parser init.");
                continue;
            }
            if (notParsedFields.count(f)) LOG4("\t\tIgnoring because field set to not parsed");
            if (!notParsedFields.count(f) && !(f->bridged && f->gress == INGRESS)) {
                LOG4("\t  Field defined in parser.");
                livemap.addAccess(f, PARSER, WRITE, def_unit, false);
                livemap.addAccess(f, 0 /* first stage */, READ, def_unit, false);
                continue;
            }
        } else if (def_unit->is<IR::BFN::Deparser>()) {
            if (notDeparsedFields.count(f)) continue;
            LOG4("\t  Defined in deparser.");
            livemap.addAccess(f, DEPARSER, WRITE, def_unit, false);
        } else if (def_unit->is<IR::MAU::Table>()) {
            const auto* t = def_unit->to<IR::MAU::Table>();
            int def_stage = dg.min_stage(t);
            LOG4("\t  Defined in stage " << def_stage << " in table " << t->name);
            livemap.addAccess(f, def_stage, WRITE, def_unit, false);
        } else {
            BUG("Unknown unit encountered %1%", def_unit->toString());
        }
        fieldToUnitUseMap[f][def_unit] |= PHV::FieldUse(WRITE);
    }
}

void DarkLiveRange::end_apply() {
    // If there are no stages required, do not run this pass.
    if (dg.max_min_stage < 0) return;
    // Set of fields whose live ranges must be calculated.
    ordered_set<const PHV::Field*> fieldsConsidered;
    for (const PHV::Field& f : phv) {
        if (clot.allocated(&f)) continue;
        if (f.is_deparser_zero_candidate()) continue;
        // Ignore unreferenced fields because they are not allocated anyway.
        if (!uses.is_referenced(&f)) continue;
        // Ignore POV fields.
        if (f.pov) continue;
        fieldsConsidered.insert(&f);
    }
    for (const auto* f : fieldsConsidered) setFieldLiveMap(f);
    if (LOGGING(1)) LOG1(livemap.printDarkLiveRanges());
    for (const auto* f1 : fieldsConsidered) {
        for (const auto* f2 : fieldsConsidered) {
            if (f1 == f2) continue;
            // No overlay possible if fields are of different gresses.
            if (f1->gress != f2->gress) {
                overlay(f1->id, f2->id) = false;
                continue;
            }
            if (!livemap.count(f1) || !livemap.count(f2)) {
                // Overlay possible because one of these fields is not live at all.
                overlay(f1->id, f2->id) = true;
                continue;
            }
            auto& access1 = livemap.at(f1);
            auto& access2 = livemap.at(f2);
            LOG3("    (" << f1->name << ", " << f2->name << ")");
            if (!overlaps(dg.max_min_stage, access1, access2)) {
                LOG4("      Overlay possible between " << f1 << " and " << f2);
                overlay(f1->id, f2->id) = true;
            }
        }
    }
}

cstring DarkLiveRange::DarkLiveRangeMap::printDarkLiveRanges() const {
    std::stringstream ss;
    auto numStages = DEPARSER;
    const int PARSER = -1;
    ss << std::endl << "Uses for fields to determine dark overlay potential:" << std::endl;
    std::vector<std::string> headers;
    headers.push_back("Field");
    headers.push_back("Bit Size");
    headers.push_back("P");
    for (int i = 0; i < numStages; i++)
        headers.push_back(std::to_string(i));
    headers.push_back("D");
    TablePrinter tp(ss, headers, TablePrinter::Align::LEFT);
    for (auto entry : livemap) {
        std::vector<std::string> row;
        row.push_back(std::string(entry.first->name));
        row.push_back(std::to_string(entry.first->size));
        PHV::FieldUse use_type;
        if (entry.second.count(std::make_pair(PARSER, PHV::FieldUse(WRITE))))
            use_type |= PHV::FieldUse(WRITE);
        if (entry.second.count(std::make_pair(PARSER, PHV::FieldUse(READ))))
            use_type |= PHV::FieldUse(READ);
        row.push_back(std::string(use_type.toString()));
        for (int i = 0; i <= DEPARSER; i++) {
            PHV::FieldUse use_type;
            if (entry.second.count(std::make_pair(i, PHV::FieldUse(READ))))
                use_type |= PHV::FieldUse(READ);
            if (entry.second.count(std::make_pair(i, PHV::FieldUse(WRITE))))
                use_type |= PHV::FieldUse(WRITE);
            row.push_back(std::string(use_type.toString()));
        }
        tp.addRow(row);
    }
    tp.print();
    return ss.str();
}
