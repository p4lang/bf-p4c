#include "header_removal_analysis.h"

HeaderRemovalAnalysis::HeaderRemovalAnalysis(const PhvInfo& phvInfo,
                                             const std::set<FieldSliceSet>& correlations) :
phvInfo(phvInfo), resultMap() {
    // Build the index of correlations.
    interestedCorrelations = new std::map<const PHV::FieldSlice*,
                                          std::set<FieldSliceSet>,
                                          PHV::FieldSlice::Less>;
    for (auto& correlation : correlations) {
        for (const auto* povBit : correlation) {
            (*interestedCorrelations)[povBit].insert(correlation);
        }
    }
}

Visitor::profile_t HeaderRemovalAnalysis::init_apply(const IR::Node* root) {
    auto result = Inspector::init_apply(root);

    resultMap.clear();
    for (auto& correlations : Values(*interestedCorrelations)) {
        for (auto& correlation : correlations) {
            resultMap[correlation] = {{}};
        }
    }

    return result;
}

bool HeaderRemovalAnalysis::preorder(const IR::MAU::Action *act) {
    act->action.visit_children(*this);
    return false;
}

bool HeaderRemovalAnalysis::preorder(const IR::MAU::Instruction* instruction) {
    // Make sure we have a call to "set".
    if (instruction->name != "set") return true;

    auto dst = instruction->operands.at(0);
    auto src = instruction->operands.at(1);

    // Make sure we are setting a header's validity bit.
    le_bitrange bitrange;
    const PHV::Field* dstField = nullptr;
    if (auto alias_slice = dst->to<IR::BFN::AliasSlice>())
        dstField = phvInfo.field(alias_slice->source, &bitrange);
    else
        dstField = phvInfo.field(dst, &bitrange);
    if (!dstField || !dstField->pov) return true;

    // Handle case where we are assigning a non-zero constant to the validity bit. Conservatively,
    // we assume that assigning a non-constant value to the POV bit can clear the bit.
    bool definitely_invalidated = false;
    if (auto constant = src->to<IR::Constant>()) {
        if (constant->value != 0) return true;
        definitely_invalidated = true;
    }
    povBitsSetInvalidInMau.insert(dstField);

    // Record the action to allow identifying when multiple headers are invalidated together
    const auto* action = findContext<IR::MAU::Action>();
    povBitsUpdateActions[dstField].insert(action);
    if (definitely_invalidated)
        povBitsInvalidateActions[dstField].insert(action);

    // Ignore if the validity bit is uninteresting to the client.
    const auto* povBit = new PHV::FieldSlice(dstField, bitrange);
    if (!interestedCorrelations->count(povBit)) return true;

    // Mark the POV bit as being cleared.
    for (auto& interestedCorrelation : interestedCorrelations->at(povBit)) {
        std::set<FieldSliceSet> rewritten = {};
        for (auto correlation : resultMap.at(interestedCorrelation)) {
            correlation.insert(povBit);
            rewritten.emplace(correlation);
        }

        std::swap(resultMap.at(interestedCorrelation), rewritten);
    }

    return true;
}

void HeaderRemovalAnalysis::end_apply() {
    bitvec fields_encountered;
    for (auto it1 = povBitsUpdateActions.begin(); it1 != povBitsUpdateActions.end(); ++it1) {
        auto* f1 = it1->first;
        auto& update_actions1 = it1->second;
        povBitsAlwaysInvalidateTogether(f1->id, f1->id) = true;
        fields_encountered[f1->id] = true;
        for (auto it2 = std::next(it1); it2 != povBitsUpdateActions.end(); ++it2) {
            auto* f2 = it2->first;
            auto& update_actions2 = it2->second;
            if (update_actions1 != update_actions2) continue;
            if (povBitsInvalidateActions.count(f1) && povBitsInvalidateActions.count(f2)) {
                auto& invalidate_actions1 = povBitsInvalidateActions.at(f1);
                auto& invalidate_actions2 = povBitsInvalidateActions.at(f2);

                if (update_actions1 != invalidate_actions1 ||
                    update_actions1 != invalidate_actions2)
                    continue;

                povBitsAlwaysInvalidateTogether(f1->id, f2->id) = true;
            }
        }
    }

    if (LOGGING(4)) {
        LOG4("pov bits always invalidated together:");
        for (auto it1 = fields_encountered.begin(); it1 != fields_encountered.end(); ++it1) {
            for (auto it2 = std::next(it1); it2 != fields_encountered.end(); ++it2) {
                if (povBitsAlwaysInvalidateTogether(*it1, *it2)) {
                    const PHV::Field* f1 = phvInfo.field(*it1);
                    CHECK_NULL(f1);
                    const PHV::Field* f2 = phvInfo.field(*it2);
                    CHECK_NULL(f2);
                    LOG4("(" << f1->name << ", " << f2->name << ")");
                }
            }
        }
    }
}

HeaderRemovalAnalysis* HeaderRemovalAnalysis::clone() const {
    return new HeaderRemovalAnalysis(*this);
}

HeaderRemovalAnalysis& HeaderRemovalAnalysis::flow_clone() {
    return *clone();
}

void HeaderRemovalAnalysis::flow_merge(Visitor& v) {
    HeaderRemovalAnalysis& other = dynamic_cast<HeaderRemovalAnalysis&>(v);

    povBitsSetInvalidInMau.insert(other.povBitsSetInvalidInMau.begin(),
                                  other.povBitsSetInvalidInMau.end());
    for (const auto* f : Keys(other.povBitsUpdateActions)) {
        povBitsUpdateActions[f].insert(other.povBitsUpdateActions[f].begin(),
                                       other.povBitsUpdateActions[f].end());
    }
    for (const auto *f : Keys(other.povBitsInvalidateActions)) {
        povBitsInvalidateActions[f].insert(other.povBitsInvalidateActions[f].begin(),
                                           other.povBitsInvalidateActions[f].end());
    }
    for (auto &kv : other.resultMap) {
        resultMap.at(kv.first).insert(kv.second.begin(), kv.second.end());
    }
}

#if 0
void HeaderRemovalAnalysis::flow_copy(::ControlFlowVisitor& v) {
    HeaderRemovalAnalysis& other = dynamic_cast<HeaderRemovalAnalysis&>(v);
    resultMap = other.resultMap;
}
#endif
