#include "bf-p4c/phv/transforms/auto_alias.h"

Visitor::profile_t DetermineCandidateHeaders::init_apply(const IR::Node* root) {
    allHeaders.clear();
    headers.clear();
    headersValidatedInParser.clear();
    headersValidatedInMAU.clear();
    for (const auto& f : phv)
        allHeaders.insert(f.header());;
    return Inspector::init_apply(root);
}

bool DetermineCandidateHeaders::preorder(const IR::BFN::Extract* extract) {
    BUG_CHECK(extract->dest, "Extract %1% does not have a destination",
            cstring::to_cstring(extract));
    BUG_CHECK(extract->dest->field, "Extract %1% does not have a destination field",
            cstring::to_cstring(extract));
    const PHV::Field* field = phv.field(extract->dest->field);
    BUG_CHECK(field, "Could not find destination field for extract %1%",
            cstring::to_cstring(extract));
    if (!field->pov) return true;
    headersValidatedInParser.insert(field->header());
    LOG3("\t  Header validated in parser: " << field->header());
    return true;
}

bool DetermineCandidateHeaders::preorder(const IR::MAU::Instruction* inst) {
    const IR::MAU::Action* action = findContext<IR::MAU::Action>();
    if (inst->operands.empty()) return true;
    const PHV::Field* destField = phv.field(inst->operands[0]);
    if (!destField) return true;
    if (!destField->pov) return true;
    if (inst->name != "set") return true;
    if (inst->operands.size() != 2) return true;
    auto* constant = inst->operands[1]->to<IR::Constant>();
    if (constant) {
        uint64_t constVal = constant->asUint64();
        if (constVal == 0) return true;
    }
    BUG_CHECK(action != nullptr,
        "No associated action found for determining candidate header - %1%", inst->name);
    headersValidatedInMAU[destField->header()].insert(action);
    LOG3("\t  Header validated in action " << action->name << ": " << destField->header());
    return true;
}

void DetermineCandidateHeaders::end_apply() {
    for (const auto header : allHeaders) {
        if (headersValidatedInParser.count(header)) continue;
        if (headersValidatedInMAU.count(header))
            headers[header].insert(headersValidatedInMAU.at(header).begin(),
                    headersValidatedInMAU.at(header).end());
    }
    LOG3("\tNumber of candidate headers: " << headers.size());
    for (auto& kv : headers) {
        std::stringstream ss;
        ss << "\t  " << kv.first << " : ";
        for (const auto* action : kv.second)
            ss << action->name << " ";
        LOG3(ss.str());
    }
}

Visitor::profile_t DetermineCandidateFields::init_apply(const IR::Node* root) {
    initialCandidateSet.clear();
    candidateSources.clear();
    LOG3("\tInitial candidate fields:");
    for (const auto& f : phv) {
        if (f.pov) continue;
        if (!headers.isCandidateHeader(f.header())) continue;
        initialCandidateSet.insert(&f);
        LOG3("\t  " << f.name);
    }
    return Inspector::init_apply(root);
}

inline void DetermineCandidateFields::dropFromCandidateSet(const PHV::Field* field) {
    initialCandidateSet.erase(field);
}

bool DetermineCandidateFields::multipleSourcesFound(
        const PHV::Field* dest,
        const PHV::Field* src) const {
    if (!candidateSources.count(dest)) return false;
    bool newSourceFound = false;
    for (auto& kv : candidateSources)
        if (kv.first != src)
            newSourceFound = true;
    return newSourceFound;
}

bool DetermineCandidateFields::preorder(const IR::MAU::Instruction* inst) {
    const IR::MAU::Action* action = findContext<IR::MAU::Action>();
    if (inst->operands.empty()) return true;
    const PHV::Field* destField = phv.field(inst->operands[0]);
    if (!destField) return true;
    if (!initialCandidateSet.count(destField)) return true;
    if (inst->name != "set" || inst->operands.size() != 2) {
        dropFromCandidateSet(destField);
        return true;
    }
    if (inst->operands[1]->is<IR::Constant>()) {
        dropFromCandidateSet(destField);
        return true;
    }
    const PHV::Field* srcField = phv.field(inst->operands[1]);
    if (!srcField) {
        dropFromCandidateSet(destField);
        LOG3("\tDrop " << destField->name << " because source is not a field.");
        return true;
    }
    if (multipleSourcesFound(destField, srcField)) {
        dropFromCandidateSet(destField);
        LOG3("\tDrop " << destField->name << " because a second source " << srcField->name <<
             " found");
        return true;
    }
    auto& validationActions = headers.getActionsForCandidateHeader(destField->header());
    LOG3("\t  Found " << validationActions.size() << " actions");
    BUG_CHECK(action != nullptr,
        "No associated action found for determining candidate fields - %1%", inst->name);
    if (!validationActions.count(action)) {
        dropFromCandidateSet(destField);
        LOG3("\tDrop " << destField->name << " because the header is not validated in action " <<
             action->name);
        return true;
    }
    LOG3("\tAdding write to field " << destField->name << " from " << srcField->name);
    candidateSources[destField][srcField].insert(action);
    return true;
}

void DetermineCandidateFields::end_apply() {
    LOG3("\tFinal candidate set:");
    for (const auto* f : initialCandidateSet) {
        if (!candidateSources.count(f)) continue;
        std::stringstream ss;
        ss << "\t  " << f->name << ", ";
        if (candidateSources.at(f).size() > 1) continue;
        const PHV::Field* srcField = nullptr;
        for (auto& kv : candidateSources.at(f)) {
            srcField = kv.first;
            ss << kv.first->name << ", ";
            for (const auto* action : kv.second)
                ss << action->name << " ";
        }
        if (srcField != nullptr) {
            if (!pragma.addAlias(f, srcField, true, PragmaAlias::COMPILER))
                LOG1("\tCould not add alias for fields " << f->name << " and " << srcField->name);
            else
                LOG1(ss.str());
        }
    }
}
