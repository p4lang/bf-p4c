#include "bf-p4c/common/asm_output.h"  // canon_name
#include "bf-p4c/parde/clot/clot_info.h"  // ClotInfo
#include "bf-p4c/device.h"
#include "resources_clot.h"

namespace BFN {

bool ClotResourcesLogging::usingClots() const {
    return Device::numClots() > 0 && BackendOptions().use_clot;
}

bool ClotResourcesLogging::preorder(const IR::BFN::LoweredParserState* state) {
    if (!usingClots()) return false;

    auto parserIR = findContext<IR::BFN::LoweredParser>();
    BUG_CHECK(parserIR, "State does not belong to a parser? %1%", state);

    for (const auto* match : state->transitions) {
        logClotUsages(match, state, parserIR->gress);
        // A parser state can have multiple extracts, but the clot
        // information is duplicated across all of them. Hence, we only
        // check the first extract to gather all clot info for this state.
        break;
    }

    return true;
}

void ClotResourcesLogging::logClotUsages(const IR::BFN::LoweredParserMatch* match,
                            const IR::BFN::LoweredParserState *state, gress_t gress) {
    for (auto* ck : match->checksums) {
        if (auto* csum = ck->to<IR::BFN::LoweredParserChecksum>())
            if (csum->type == IR::BFN::ChecksumMode::CLOT)
                clotTagToChecksumUnit[csum->clot_dest.tag] = csum->unit_id;
    }

    for (auto* stmt : match->extracts) {
        if (auto* extract = stmt->to<IR::BFN::LoweredExtractClot>()) {
            // Don't generate JSON for the extracted CLOT if the CLOT is spilled.
            if (!extract->is_start) continue;

            clotUsages[gress]->append_clots(logExtractClotInfo(extract, state));
        }
    }
}

ClotResourcesLogging::ClotUsage*
ClotResourcesLogging::logExtractClotInfo(const IR::BFN::LoweredExtractClot* extract,
                                      const IR::BFN::LoweredParserState *state) {
    using ClotField = Resources_Schema_Logger::ClotField;

    const auto* source = extract->source->to<IR::BFN::LoweredPacketRVal>();
    const auto bytes = source->range;
    const bool hasChecksum = clotTagToChecksumUnit.count(extract->dest.tag) > 0;
    const std::string issueState = state->name.c_str();
    const auto length = bytes.hi - bytes.lo + 1;
    const auto offset = bytes.lo;
    const auto tag = extract->dest.tag;

    auto usage = new ClotUsage(hasChecksum, issueState, length, offset, tag);

    if (auto c = clotInfo.parser_state_to_clot(state, tag)) {
        std::vector<ClotField*> fieldList;
        int clotOffset = 0;
        for (auto *f : c->all_slices()) {
            const std::string name = cstring(canon_name(f->field()->name)).c_str();
            const auto msb = f->range().hi;
            const auto lsb = f->range().lo;
            auto cf = new ClotField(clotOffset, lsb, msb, name);
            clotOffset += f->field()->size;
            fieldList.push_back(cf);
        }
        usage->append(fieldList);
    }

    return usage;
}

std::vector<ClotResourcesLogging::ClotResourceUsage*> ClotResourcesLogging::getLoggers() {
    BUG_CHECK(collected, "Trying to get clot log without applying inspector to pipe node.");
    return clotUsages;
}

ClotResourcesLogging::ClotResourcesLogging(const ClotInfo& clotInfo) : clotInfo(clotInfo) {
    using ClotEligibleField = Resources_Schema_Logger::ClotEligibleField;

    if (!usingClots()) return;

    // Once Multi Parser support is added in T2NA, clot support will have
    // ClotInfo per parser and the code below should change to use a vector
    // of clots per parser similar to P4iParser. Currently this assumes a
    // single parser scenario
    // Initialize clot structures for ingress & egress
    for (auto gress : (gress_t[2]) {INGRESS, EGRESS}) {
        clotUsages[gress] = new ClotResourceUsage(::toString(gress).c_str(),  Device::numClots());
    }

    // Populate information for CLOT-eligible fields.
    for (auto field : *clotInfo.clot_eligible_fields()) {
        const auto bitWidth = field->size;
        const bool isReadonly = clotInfo.is_readonly(field);
        const bool isModified = clotInfo.is_modified(field);
        const bool isChecksum = clotInfo.is_checksum(field);
        const std::string name = cstring(canon_name(field->name)).c_str();

        int numBitsInClots = 0;
        for (auto &kv : *clotInfo.slice_clots(field)) {
            numBitsInClots += kv.first->size();
        }

        int numBitsInPhvs = 0;
        field->foreach_alloc([&](const PHV::AllocSlice& alloc) {
            numBitsInPhvs += alloc.width();
        });

        auto cef = new ClotEligibleField(bitWidth, isChecksum, isModified, isReadonly,
                                    name, numBitsInClots, numBitsInPhvs);
        clotUsages[field->gress]->append_clot_eligible_fields(cef);
    }
}

}  // namespace BFN
