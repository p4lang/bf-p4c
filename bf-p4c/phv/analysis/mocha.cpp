#include "bf-p4c/phv/analysis/mocha.h"

Visitor::profile_t CollectMochaCandidates::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    fieldsWritten.clear();
    fieldsNotWrittenForMocha.clear();
    mochaCount = 0;
    mochaSize = 0;
    return rv;
}

bool CollectMochaCandidates::preorder(const IR::MAU::Action* act) {
    auto* tbl = findContext<IR::MAU::Table>();
    ActionAnalysis aa(phv, false, false, tbl);
    ActionAnalysis::FieldActionsMap fieldActionsMap;
    aa.set_field_actions_map(&fieldActionsMap);
    act->apply(aa);
    populateMembers(act, fieldActionsMap);
    return true;
}

void CollectMochaCandidates::populateMembers(
        const IR::MAU::Action* act,
        const ActionAnalysis::FieldActionsMap& fieldActionsMap) {
    const IR::MAU::Table* tbl = findContext<IR::MAU::Table>();
    BUG_CHECK(tbl != nullptr,
        "No associated table found for collecting mocha candidates - %1%", act->name);
    LOG5("\tAnalyzing action " << act->name << " in table " << tbl->name);
    for (auto& fieldAction : Values(fieldActionsMap)) {
        const PHV::Field* write = phv.field(fieldAction.write.expr);
        BUG_CHECK(write, "Action %1% does not have a write?", fieldAction.write.expr);
        fieldsWritten[write->id] = true;
        if (fieldAction.name != "set") {
            LOG5("\t  Field written by nonset: " << write);
            fieldsNotWrittenForMocha[write->id] = true;
        }
        for (auto& readSrc : fieldAction.reads) {
            if (readSrc.type == ActionAnalysis::ActionParam::ACTIONDATA ||
                    readSrc.type == ActionAnalysis::ActionParam::CONSTANT) {
                LOG5("\t  Field written by action data/constant: " << write);
                fieldsNotWrittenForMocha[write->id] = true;
            }
            if (readSrc.speciality != ActionAnalysis::ActionParam::NO_SPECIAL) {
                LOG5("\t  Field written by speciality: " << write);
                fieldsNotWrittenForMocha[write->id] = true;
            }
        }
    }
}

void CollectMochaCandidates::end_apply() {
    for (PHV::Field& f : phv) {
        std::stringstream ss;
        ss << "    Examining field: " << f << std::endl;
        if (!uses.is_referenced(&f)) {
            ss << "    ...unreferenced field";
            LOG5(ss.str());
            continue;
        }
        if (fieldsNotWrittenForMocha[f.id]) {
            ss << "    ...write by action data/constant/speciality operation/nonset operation";
            LOG5(ss.str());
            continue;
        }
        // Mocha fields that are part of packets need to start at byte boundaries (for now).
        // E.g. trafficClass in ipv4 starts at bit 4 and so, must start at bit 4 of a container.
        // The fact that it shares a container with another non-mocha field becomes an issue if
        // trafficClass is to be allocated to a mocha container.
        if (isPacketField(&f) && f.offset % 8 != 0) {
            ss << "    ...packet field starts at nonzero bit-in-byte offset.";
            LOG5(ss.str());
            continue;
        }
        // If field size is not in byte multiples, we must perform extra analysis to determine if
        // the exact containers requirement for the mocha candidate field can be satisfied. For now,
        // we ignore those fields for mocha allocation.
        // XXX(Deep): Add analysis to determine if the exact_containers requirement can be satisfied
        // for nonbyte-aligned packet fields.
        if (isPacketField(&f) && f.size % 8 != 0) {
            ss << "    ...packet field size is not in multiple of bytes.";
            LOG5(ss.str());
            continue;
        }
        if (f.pov) {
            ss << "    ...pov field.";
            LOG5(ss.str());
            continue;
        }
        ss << "    ...mocha candidate found.";
        LOG5(ss.str());
        ++mochaCount;
        mochaSize += f.size;
        f.set_mocha_candidate(true);
    }
    LOG2("\tNumber of mocha candidates identified: " << mochaCount);
    LOG2("\tBit width of mocha candidates        : " << mochaSize);
    LOG2("\tMocha candidates:");
    for (const PHV::Field& f : phv)
        if (f.is_mocha_candidate())
            LOG2("\t  " << f);
}
