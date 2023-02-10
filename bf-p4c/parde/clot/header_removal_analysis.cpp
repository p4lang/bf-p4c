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
    auto dstField = phvInfo.field(dst, &bitrange);
    if (!dstField || !dstField->pov) return true;

    // Handle case where we are assigning a non-zero constant to the validity bit. Conservatively,
    // we assume that assigning a non-constant value to the POV bit can clear the bit.
    if (auto constant = src->to<IR::Constant>()) {
        if (constant->value != 0) return true;
    }
    povBitsSetInvalidInMau.insert(dstField);

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

HeaderRemovalAnalysis* HeaderRemovalAnalysis::clone() const {
    return new HeaderRemovalAnalysis(*this);
}

HeaderRemovalAnalysis& HeaderRemovalAnalysis::flow_clone() {
    return *clone();
}

void HeaderRemovalAnalysis::flow_merge(Visitor& v) {
    HeaderRemovalAnalysis& other = dynamic_cast<HeaderRemovalAnalysis&>(v);

    for (auto& kv : other.resultMap) {
        resultMap.at(kv.first).insert(kv.second.begin(), kv.second.end());
    }
}

#if 0
void HeaderRemovalAnalysis::flow_copy(::ControlFlowVisitor& v) {
    HeaderRemovalAnalysis& other = dynamic_cast<HeaderRemovalAnalysis&>(v);
    resultMap = other.resultMap;
}
#endif
