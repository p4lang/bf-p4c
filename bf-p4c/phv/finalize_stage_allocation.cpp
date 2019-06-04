#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/phv/finalize_stage_allocation.h"

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

void FinalizeStageAllocation::updateAllocation(PHV::Field* f) {
    static std::pair<int, PHV::FieldUse> parserMin = std::make_pair(-1,
            PHV::FieldUse(PHV::FieldUse::READ));
    static std::pair<int, PHV::FieldUse> deparserMax =
        std::make_pair(Device::numStages(), PHV::FieldUse(PHV::FieldUse::WRITE));
    static PHV::FieldUse read(PHV::FieldUse::READ);
    static PHV::FieldUse write(PHV::FieldUse::WRITE);
    ordered_map<PHV::Container, std::vector<PHV::Field::alloc_slice>> containerToSlicesMap;
    ordered_map<int, ordered_set<const IR::MAU::Table*>> readTables;
    ordered_map<int, ordered_set<const IR::MAU::Table*>> writeTables;
    bool usedInParser = false, usedInDeparser = false;

    summarizeUseDefs(phv, dg, defuse.getAllDefs(f->id), writeTables, usedInParser, usedInDeparser);
    summarizeUseDefs(phv, dg, defuse.getAllUses(f->id), readTables, usedInParser, usedInDeparser);
    if (f->aliasSource != nullptr) {
        summarizeUseDefs(phv, dg, defuse.getAllDefs(f->aliasSource->id), writeTables, usedInParser,
                usedInDeparser);
        summarizeUseDefs(phv, dg, defuse.getAllUses(f->aliasSource->id), readTables, usedInParser,
                usedInDeparser);
    } else if (phv.getAliasMap().count(f)) {
        const PHV::Field* aliasDest = phv.getAliasMap().at(f);
        summarizeUseDefs(phv, dg, defuse.getAllDefs(aliasDest->id), writeTables, usedInParser,
                usedInDeparser);
        summarizeUseDefs(phv, dg, defuse.getAllUses(aliasDest->id), readTables, usedInParser,
                usedInDeparser);
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
            LOG5(ss.str() << "\tIgnoring field slice: " << alloc);
            continue;
        }
        bool includeParser = false;
        if (usedInParser) {
            if (alloc.min_stage == minStageAccount.at(alloc.field_bits())) {
                includeParser = true;
                LOG3("\t\tInclude parser use in this slice.");
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

        int minPhysicalRead = tables.maxStages(f->gress);
        int maxPhysicalRead = (minStageRead == PhvInfo::getDeparserStage())
            ? tables.maxStages(f->gress) : minStageRead;
        int minPhysicalWrite = tables.maxStages(f->gress);
        int maxPhysicalWrite = (minStageWritten == PhvInfo::getDeparserStage())
            ? tables.maxStages(f->gress) : minStageWritten;
        for (auto stage = minStageRead; stage <= maxStageRead; stage++) {
            LOG5("\t\t\tRead Stage: " << stage);
            if (readTables.count(stage)) {
                for (const auto* t : readTables.at(stage)) {
                    int stage = t->logical_id / TableSummary::NUM_LOGICAL_TABLES_PER_STAGE;
                    if (stage < minPhysicalRead) minPhysicalRead = stage;
                    if (stage > maxPhysicalRead) maxPhysicalRead = stage;
                    LOG3("\t\t  Read table: " << t->name << ", stage: " << stage);
                }
            }
        }
        for (auto stage = minStageWritten; stage <= maxStageWritten; stage++) {
            LOG5("\t\t\tWrite Stage: " << stage);
            if (writeTables.count(stage)) {
                for (const auto* t : writeTables.at(stage)) {
                    int stage = t->logical_id / TableSummary::NUM_LOGICAL_TABLES_PER_STAGE;
                    if (stage < minPhysicalWrite) minPhysicalWrite = stage;
                    if (stage > maxPhysicalWrite) maxPhysicalWrite = stage;
                    LOG3("\t\t  Written table: " << t->name << ", stage: " << stage);
                }
            }
        }
        LOG3("\t\tPhys Read: [" << minPhysicalRead << ", " << maxPhysicalRead << "], " <<
             " Phys Write: [" << minPhysicalWrite << ", " << maxPhysicalWrite << "]");
        int new_min_stage, new_max_stage;
        PHV::FieldUse new_min_use, new_max_use;
        if (minPhysicalRead <= minPhysicalWrite) {
            new_min_stage = minPhysicalRead;
            new_min_use = PHV::FieldUse(PHV::FieldUse::READ);
        } else {
            new_min_stage = minPhysicalWrite;
            new_min_use = PHV::FieldUse(PHV::FieldUse::WRITE);
        }
        if (maxPhysicalWrite >= maxPhysicalRead) {
            new_max_stage = maxPhysicalWrite;
            new_max_use = PHV::FieldUse(PHV::FieldUse::WRITE);
        } else {
            new_max_stage = maxPhysicalRead;
            new_max_use = PHV::FieldUse(PHV::FieldUse::READ);
        }
        if (includeParser) {
            new_min_stage = 0;
            new_min_use = PHV::FieldUse(PHV::FieldUse::READ);
        }
        alloc.min_stage = std::make_pair(new_min_stage, new_min_use);
        alloc.max_stage = std::make_pair(new_max_stage, new_max_use);
        LOG3("\t  New min stage: " << alloc.min_stage.first << alloc.min_stage.second <<
             ", New max stage: " << alloc.max_stage.first << alloc.max_stage.second);
    }
}


Visitor::profile_t FinalizeStageAllocation::init_apply(const IR::Node* root) {
    fieldToSlicesMap.clear();
    containerToReadStages.clear();
    containerToWriteStages.clear();
    LOG1("Deparser stage: " << phv.getDeparserStage());
    for (auto& f : phv) updateAllocation(&f);
    for (auto& f : phv) {
        LOG1("\tField: " << f.name);
        for (const auto& slice : f.get_alloc())
            LOG1("\t  Slice: " << slice);
    }
    phv.clearMinStageInfo();
    return Inspector::init_apply(root);
}

bool FinalizeStageAllocation::preorder(const IR::MAU::Table* tbl) {
    int stage = tbl->logical_id / TableSummary::NUM_LOGICAL_TABLES_PER_STAGE;
    PhvInfo::addMinStageEntry(TableSummary::getTableName(tbl), stage);
    return true;
}
