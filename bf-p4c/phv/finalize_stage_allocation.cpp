#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/phv/finalize_stage_allocation.h"

bool CalcMaxPhysicalStages::preorder(const IR::MAU::Table* tbl) {
    int stage = tbl->logical_id / TableSummary::NUM_LOGICAL_TABLES_PER_STAGE;
    if (stage + 1 > deparser_stage[tbl->gress])
        deparser_stage[tbl->gress] = stage + 1;
    return true;
}

void CalcMaxPhysicalStages::end_apply() {
    for (auto i : deparser_stage)
        if (i > dep_stage_overall)
            dep_stage_overall = i;
    LOG1("  Deparser denoted by physical stage " << dep_stage_overall);
}

void FinalizeStageAllocation::summarizeUseDefs(
        const PhvInfo& phv,
        const DependencyGraph& dg,
        const FieldDefUse::LocPairSet& refs,
        ordered_map<int, ordered_set<const IR::MAU::Table*>>& stageToTables,
        bool& usedInParser,
        bool& usedInDeparser,
        bool usePhysicalStages) {
    for (auto& ref : refs) {
        if (ref.first->is<IR::BFN::Parser>() || ref.first->is<IR::BFN::ParserState>()) {
            if (!ref.second->is<ImplicitParserInit>())
                usedInParser = true;
        } else if (ref.first->is<IR::BFN::Deparser>()) {
            usedInDeparser = true;
            LOG5("\tUsed in deparser");
        } else if (ref.first->is<IR::MAU::Table>()) {
            auto* t = ref.first->to<IR::MAU::Table>();
            if (usePhysicalStages) {
                BUG_CHECK(t->logical_id != -1, "Table %1% is unallocated", t->name);
                auto minStages = phv.minStage(TableSummary::getTableName(t));
                for (auto stage : minStages) stageToTables[stage].insert(t);
            } else {
                stageToTables[dg.min_stage(t)].insert(t);
            }
        } else {
            BUG("Found a unit that is not the parser, deparser, or table");
        }
    }
}

void UpdateFieldAllocation::updateAllocation(PHV::Field* f) {
    static PHV::FieldUse read(PHV::FieldUse::READ);
    static PHV::FieldUse write(PHV::FieldUse::WRITE);
    ordered_map<PHV::Container, std::vector<PHV::Field::alloc_slice>> containerToSlicesMap;
    ordered_map<int, ordered_set<const IR::MAU::Table*>> readTables;
    ordered_map<int, ordered_set<const IR::MAU::Table*>> writeTables;
    bool usedInParser = false, usedInDeparser = false;

    LOG3("\tUpdating allocation for " << f);

    FinalizeStageAllocation::summarizeUseDefs(phv, dg, defuse.getAllDefs(f->id), writeTables,
            usedInParser, usedInDeparser);
    FinalizeStageAllocation::summarizeUseDefs(phv, dg, defuse.getAllUses(f->id), readTables,
            usedInParser, usedInDeparser);
    if (f->aliasSource != nullptr) {
        FinalizeStageAllocation::summarizeUseDefs(phv, dg,
                defuse.getAllDefs(f->aliasSource->id),
                writeTables, usedInParser, usedInDeparser);
        FinalizeStageAllocation::summarizeUseDefs(phv, dg,
                defuse.getAllUses(f->aliasSource->id), readTables, usedInParser,
                usedInDeparser);
    } else if (phv.getAliasMap().count(f)) {
        const PHV::Field* aliasDest = phv.getAliasMap().at(f);
        FinalizeStageAllocation::summarizeUseDefs(phv, dg, defuse.getAllDefs(aliasDest->id),
                writeTables, usedInParser, usedInDeparser);
        FinalizeStageAllocation::summarizeUseDefs(phv, dg, defuse.getAllUses(aliasDest->id),
                readTables, usedInParser, usedInDeparser);
    }

    std::stringstream ss;
    ss << "\t" << f->name << std::endl;
    ss << "\t Written by tables:" << std::endl;
    for (auto& kv : writeTables) {
        ss << "\t  " << kv.first << " : ";
        for (const auto* t : kv.second) ss << t->name << " ";
        ss << std::endl;
    }
    ss << "\t Read by tables:" << std::endl;
    for (auto& kv : readTables) {
        ss << "\t  " << kv.first << " : ";
        for (const auto* t : kv.second) ss << t->name << " ";
        ss << std::endl;
    }
    ordered_map<le_bitrange, PHV::StageAndAccess> minStageAccount;
    for (auto& alloc : f->get_alloc()) {
        le_bitrange range = alloc.field_bits();
        if (!minStageAccount.count(range)) {
            minStageAccount[range] = alloc.min_stage;
            continue;
        }
        auto candidate = minStageAccount.at(range);
        if (candidate.first > alloc.min_stage.first ||
            (candidate.first == alloc.min_stage.first && candidate.second > alloc.min_stage.second))
            minStageAccount[range] = alloc.min_stage;
    }
    for (auto& alloc : f->get_alloc()) {
        if (parserMin == alloc.min_stage && deparserMax == alloc.max_stage) {
            // Change max stage to deparser in the physical stage list.
            int physDeparser = depStages.getDeparserStage();
            BUG_CHECK(physDeparser >= 0, "No tables detected while finalizing allocation of %1%",
                    alloc);
            alloc.max_stage = std::make_pair(physDeparser, write);
            LOG5(ss.str() << "\tIgnoring field slice: " << alloc);
            continue;
        } else {
            LOG1("\t\tNot ignoring for parserMin " << parserMin.first << parserMin.second <<
                 " and deparserMax " << deparserMax.first << deparserMax.second);
            LOG1("\t\talloc min: " << alloc.min_stage.first << alloc.min_stage.second);
            LOG1("\t\talloc max: " << alloc.max_stage.first << alloc.max_stage.second);
        }
        bool includeParser = false;
        if (usedInParser) {
            if (alloc.min_stage == minStageAccount.at(alloc.field_bits())) {
                includeParser = true;
                LOG3("\t\tInclude parser use in this slice.");
            }
        }
        bool alwaysRunLastStageSlice = false;
        if (usedInDeparser) {
            if (!alloc.init_i.empty && alloc.init_i.alwaysInitInLastMAUStage) {
                alwaysRunLastStageSlice = true;
                LOG4("\t\tDetected slice for always run in last stage");
            }
        }
        LOG3(ss.str() << "\t  Slice: " << alloc);
        containerToSlicesMap[alloc.container].push_back(alloc);
        int minStageRead = (alloc.min_stage.second == read) ?
                            alloc.min_stage.first : (alloc.min_stage.first + 1);
        int maxStageRead = alloc.max_stage.first;
        int minStageWritten = alloc.min_stage.first;
        int maxStageWritten = (alloc.max_stage.second == write) ? alloc.max_stage.first
                : (alloc.max_stage.first == 0 ? 0 : alloc.max_stage.first - 1);
        LOG3("\t\tRead: [" << minStageRead << ", " << maxStageRead << "], Write: [" <<
             minStageWritten << ", " << maxStageWritten << "]");

        const int NOTSET = -2;
        int minPhysicalRead, maxPhysicalRead, minPhysicalWrite, maxPhysicalWrite;
        minPhysicalRead = maxPhysicalRead = minPhysicalWrite = maxPhysicalWrite = NOTSET;

        for (auto stage = minStageRead; stage <= maxStageRead; stage++) {
            LOG5("\t\t\tRead Stage: " << stage);
            if (readTables.count(stage)) {
                for (const auto* t : readTables.at(stage)) {
                    int stage = t->logical_id / TableSummary::NUM_LOGICAL_TABLES_PER_STAGE;
                    LOG3("\t\t  Read table: " << t->name << ", stage: " << stage);
                    if (minPhysicalRead == NOTSET && maxPhysicalRead == NOTSET) {
                        // Initial value not set.
                        minPhysicalRead = stage;
                        maxPhysicalRead = stage;
                        continue;
                    }
                    if (stage < minPhysicalRead) minPhysicalRead = stage;
                    if (stage > maxPhysicalRead) maxPhysicalRead = stage;
                }
            }
        }
        for (auto stage = minStageWritten; stage <= maxStageWritten; stage++) {
            LOG5("\t\t\tWrite Stage: " << stage);
            if (writeTables.count(stage)) {
                for (const auto* t : writeTables.at(stage)) {
                    int stage = t->logical_id / TableSummary::NUM_LOGICAL_TABLES_PER_STAGE;
                    LOG3("\t\t  Written table: " << t->name << ", stage: " << stage);
                    if (minPhysicalWrite == NOTSET && maxPhysicalWrite == NOTSET) {
                        // Initial value not set, so this stage is both maximum and minimum.
                        minPhysicalWrite = stage;
                        maxPhysicalWrite = stage;
                        continue;
                    }
                    if (stage < minPhysicalWrite) minPhysicalWrite = stage;
                    if (stage > maxPhysicalWrite) maxPhysicalWrite = stage;
                }
            }
        }
        LOG3("\t\tPhys Read: [" << minPhysicalRead << ", " << maxPhysicalRead << "], " <<
             " Phys Write: [" << minPhysicalWrite << ", " << maxPhysicalWrite << "]");
        int new_min_stage, new_max_stage;
        PHV::FieldUse new_min_use, new_max_use;
        bool readAbsent = ((minPhysicalRead == NOTSET) && (maxPhysicalRead == NOTSET));
        bool writeAbsent = ((minPhysicalWrite == NOTSET) && (maxPhysicalWrite == NOTSET));
        // Make sure that there is some physical stage during which this slice is alive.
        // No need to check parser, because there will be at least one use from the parser extract.
        BUG_CHECK(!readAbsent || !writeAbsent || alwaysRunLastStageSlice,
                "No read or write detected for allocated slice %1%", alloc);

        if (readAbsent) {
            // If this slice only has write.
            new_min_stage = minPhysicalWrite;
            new_min_use = write;
            new_max_stage = maxPhysicalWrite;
            new_max_use = write;
        } else if (writeAbsent) {
            // If this slice only has read.
            new_min_stage = minPhysicalRead;
            new_min_use = read;
            new_max_stage = maxPhysicalRead;
            new_max_use = read;
        } else {
            // If this slice both has read and write.
            if (minPhysicalRead <= minPhysicalWrite) {
                new_min_stage = minPhysicalRead;
                new_min_use = read;
            } else {
                new_min_stage = minPhysicalWrite;
                new_min_use = write;
            }
            if (maxPhysicalWrite >= maxPhysicalRead) {
                new_max_stage = maxPhysicalWrite;
                new_max_use = write;
            } else {
                new_max_stage = maxPhysicalRead;
                new_max_use = read;
            }
        }
        if (includeParser) {
            new_min_stage = 0;
            new_min_use = PHV::FieldUse(PHV::FieldUse::READ);
        }
        if (alwaysRunLastStageSlice) {
            new_min_use = write;
            new_max_use = read;
            int dep_stage = depStages.getDeparserStage(f->gress);
            BUG_CHECK(dep_stage >= 0, "No tables detected in the program while finalizing "
                    "PHV allocation");
            new_min_stage = dep_stage - 1;
            new_max_stage = dep_stage;
        }
        alloc.min_stage = std::make_pair(new_min_stage, new_min_use);
        alloc.max_stage = std::make_pair(new_max_stage, new_max_use);
        LOG3("\t  New min stage: " << alloc.min_stage.first << alloc.min_stage.second <<
             ", New max stage: " << alloc.max_stage.first << alloc.max_stage.second);
    }
}


Visitor::profile_t UpdateFieldAllocation::init_apply(const IR::Node* root) {
    fieldToSlicesMap.clear();
    containerToReadStages.clear();
    containerToWriteStages.clear();
    LOG1("Deparser logical stage: " << phv.getDeparserStage());
    parserMin = std::make_pair(-1, PHV::FieldUse(PHV::FieldUse::READ));
    deparserMax = std::make_pair(PhvInfo::getDeparserStage(), PHV::FieldUse(PHV::FieldUse::WRITE));
    for (auto& f : phv) updateAllocation(&f);
    for (auto& f : phv) {
        LOG1("\tField: " << f.name);
        for (const auto& slice : f.get_alloc())
            LOG1("\t  Slice: " << slice);
    }
    phv.clearMinStageInfo();
    return Inspector::init_apply(root);
}

bool UpdateFieldAllocation::preorder(const IR::MAU::Table* tbl) {
    int stage = tbl->logical_id / TableSummary::NUM_LOGICAL_TABLES_PER_STAGE;
    PhvInfo::addMinStageEntry(TableSummary::getTableName(tbl), stage);
    return true;
}

void UpdateFieldAllocation::end_apply() {
    PhvInfo::setDeparserStage(depStages.getDeparserStage());
}

FinalizeStageAllocation::FinalizeStageAllocation(
        PhvInfo& p,
        const FieldDefUse& u,
        const DependencyGraph& d,
        const TableSummary& t) {
    addPasses({
        &depStages,
        new UpdateFieldAllocation(p, u, d, t, depStages)
    });
}
