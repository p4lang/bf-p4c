#include "bf-p4c/phv/analysis/dark_live_range.h"
#include "bf-p4c/common/table_printer.h"

bool DarkLiveRange::overlaps(
        const int max_num_min_stages,
        const ordered_map<unsigned, unsigned>& range1,
        const ordered_map<unsigned, unsigned>& range2) {
    const unsigned PARSER = max_num_min_stages + 2;
    const unsigned DEPARSER = max_num_min_stages + 1;
    if (range1.count(PARSER) && range2.count(PARSER)) {
        LOG4("\t\tBoth fields used in the parser. Cannot do dark overlay.");
        return true;
    }
    if (range1.count(DEPARSER) && range2.count(DEPARSER)) {
        LOG4("\t\tBoth fields used in the deparser. Cannot do dark overlay.");
        return true;
    }
    bitvec f1Uses;
    bitvec f2Uses;
    for (unsigned i = 0; i <= DEPARSER; i++) {
        if (range1.count(i)) {
            LOG4("\t\tField 1 use in stage " << i << " : " <<
                    LiveRangeReport::use_type(range1.at(i)));
            f1Uses.setbit(i);
            if (i != 0 && range1.at(i) == LiveRangeReport::READ) f1Uses.setbit(i - 1);
            if (i != DEPARSER && range1.at(i) == LiveRangeReport::READ) f1Uses.setbit(i + 1);
        }
        if (range2.count(i)) {
            LOG4("\t\tField 2 use in stage " << i << " : " <<
                    LiveRangeReport::use_type(range2.at(i)));
            f2Uses.setbit(i);
            if (i != 0 && range2.at(i) == LiveRangeReport::READ) f2Uses.setbit(i - 1);
            if (i != DEPARSER && range2.at(i) == LiveRangeReport::READ) f2Uses.setbit(i + 1);
        }
    }
    LOG3("\t\tField 1 use: " << f1Uses << ", Field 2 use: " << f2Uses);
    bitvec combo = f1Uses & f2Uses;
    return combo.empty();
}

Visitor::profile_t DarkLiveRange::init_apply(const IR::Node* root) {
    livemap.clear();
    overlay.clear();
    max_num_min_stages = -1;
    BUG_CHECK(dg.finalized, "Dependence graph is not populated.");
    return Inspector::init_apply(root);
}

bool DarkLiveRange::preorder(const IR::MAU::Table* t) {
    int minStage = dg.min_stage(t);
    if (minStage > max_num_min_stages)
        max_num_min_stages = minStage;
    return true;
}

void DarkLiveRange::setFieldLiveMap(const PHV::Field* f) {
    LOG2("    Setting live range for field " << f);
    // minUse = earliest stage for uses of the field.
    // maxUse = latest stage for uses of the field.
    // minDef = earliest stage for defs of the field.
    // maxDef = latest stage for defs of the field.
    // Set the min values initially to the deparser, and the max values to the parser initially.
    const int DEPARSER = max_num_min_stages + 1;
    const int PARSER = max_num_min_stages + 2;

    // For each use of the field, parser implies stage `max_num_min_stages + 2`, deparser implies
    // stage `max_num_min_stages + 1` (12 for Tofino), and a table implies the corresponding
    // dg.min_stage.
    for (const FieldDefUse::locpair use : defuse.getAllUses(f->id)) {
        const IR::BFN::Unit* use_unit = use.first;
        if (use_unit->is<IR::BFN::ParserState>() || use_unit->is<IR::BFN::Parser>()) {
            // Ignore parser use if field is marked as not parsed.
            if (notParsedFields.count(f)) continue;
            // There is no need to set the maxUse here, because maxUse is either -1 (if there is no
            // other use) or a non-negative value (which does not need to be updated).
            LOG4("\t  Used in parser.");
            livemap[f][PARSER] |= LiveRangeReport::READ;
        } else if (use_unit->is<IR::BFN::Deparser>()) {
            // Ignore deparser use if field is marked as not deparsed.
            if (notDeparsedFields.count(f)) continue;
            // There is no need to set the minUse here, because minUse is either DEPARSER (if there
            // is no other use) or a between [-1, max_num_min_stages] (which does not need to be
            // updated).
            LOG4("\t  Used in deparser.");
            livemap[f][DEPARSER] |= LiveRangeReport::READ;
        } else if (use_unit->is<IR::MAU::Table>()) {
            const auto* t = use_unit->to<IR::MAU::Table>();
            int use_stage = dg.min_stage(t);
            LOG4("\t  Used in stage " << use_stage << " in table " << t->name);
            livemap[f][use_stage] |= LiveRangeReport::READ;
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
                LOG4("\t  Field with initialized read defined in parser.");
                livemap[f][PARSER] |= LiveRangeReport::WRITE;
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
                    livemap[f][PARSER] |= LiveRangeReport::WRITE;
                }
            }
        } else if (def_unit->is<IR::BFN::Deparser>()) {
            if (notDeparsedFields.count(f)) continue;
            LOG4("\t  Defined in deparser.");
            livemap[f][DEPARSER] |= LiveRangeReport::WRITE;
        } else if (def_unit->is<IR::MAU::Table>()) {
            const auto* t = def_unit->to<IR::MAU::Table>();
            int def_stage = dg.min_stage(t);
            LOG4("\t  Defined in stage " << def_stage << " in table " << t->name);
            livemap[f][def_stage] |= LiveRangeReport::WRITE;
        } else {
            BUG("Unknown unit encountered %1%", def_unit->toString());
        }
    }
}

void DarkLiveRange::setPaddingFieldLiveMap(const PHV::Field* f) {
    const int DEPARSER = max_num_min_stages + 1;
    const int PARSER = max_num_min_stages + 2;
    // For padding fields (marked by alwaysPackable), the live range is the deparser (for ingress
    // fields) and the parser (for egress fields).
    if (f->gress == INGRESS) {
        livemap[f][DEPARSER] |= LiveRangeReport::READ;
    } else if (f->gress == EGRESS) {
        livemap[f][PARSER] |= LiveRangeReport::WRITE;
    } else if (f->gress == GHOST) {
        livemap[f][DEPARSER] |= LiveRangeReport::WRITE;
    }
}

void DarkLiveRange::end_apply() {
    // If there are no stages required, do not run this pass.
    if (max_num_min_stages <= 0) return;
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
    for (const auto* f : fieldsConsidered) {
        if (f->alwaysPackable)
            setPaddingFieldLiveMap(f);
        else
            setFieldLiveMap(f);
    }
    if (LOGGING(1)) LOG1(printLiveRanges());
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
            if (!overlaps(max_num_min_stages, access1, access2)) {
                overlay(f1->id, f2->id) = true;
                LOG3("    (" << f1->name << ", " << f2->name << ")");
            }
        }
    }
}

cstring DarkLiveRange::printLiveRanges() const {
    std::stringstream ss;
    const int DEPARSER = max_num_min_stages + 1;
    const int PARSER = max_num_min_stages + 2;
    auto numStages = DEPARSER;
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
        if (entry.second.count(PARSER))
            row.push_back(std::string(LiveRangeReport::use_type(entry.second.at(PARSER))));
        else
            row.push_back("");
        for (int i = 0; i <= DEPARSER; i++) {
            if (entry.second.count(i))
                row.push_back(std::string(LiveRangeReport::use_type(entry.second.at(i))));
            else
                row.push_back("");
        }
        tp.addRow(row);
    }
    tp.print();
    return ss.str();
}
