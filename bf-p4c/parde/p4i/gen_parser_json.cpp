#include "bf-p4c/parde/p4i/gen_parser_json.h"

#include <boost/optional.hpp>
#include <vector>

std::vector<P4iParserExtract>
GenerateParserP4iJson::generateExtracts(const IR::BFN::LoweredParserMatch* match) {
    std::vector<P4iParserExtract> rst;
    std::map<size_t, int> extractor_ids;
    for (const auto* prim : match->statements) {
        // TODO(yumin): currently clot is not part of visualization.
        if (auto* extract_ir = prim->to<IR::BFN::LoweredExtractPhv>()) {
            P4iParserExtract extract;
            if (extract_ir->dest == nullptr) {
                // TODO(yumin): somehow, jbay leave an extract to nullptr container here..
                continue;
            }
            size_t container_sz = extract_ir->dest->container.size();
            extract.extractor_id = extractor_ids[container_sz]++;
            extract.bit_width = container_sz;
            extract.dest_container =
                Device::phvSpec().containerToId(extract_ir->dest->container);
            if (auto* buffer = extract_ir->source->to<IR::BFN::LoweredBufferlikeRVal>()) {
                extract.buffer_offset = buffer->extractedBytes().loByte();
            } else if (auto* const_val = extract_ir->source->to<IR::BFN::LoweredConstantRVal>()) {
                extract.constant_value = const_val->constant;
            } else {
                BUG("Unknown extract primitive: %1%", prim);
            }
            rst.push_back(std::move(extract));
        }
    }
    return rst;
}

std::vector<P4iParserMatchOn>
GenerateParserP4iJson::generateMatchOn(const IR::BFN::LoweredParserState* state,
                                       const IR::BFN::LoweredParserMatch* match) {
    std::vector<P4iParserMatchOn> rst;
    auto* select = state->select;
    for (const auto& reg : select->regs) {
        P4iParserMatchOn match_on;
        match_on.hardware_id   = reg.id;
        match_on.bit_width     = reg.size * 8;
        if (match->bufferRequired)
            match_on.buffer_offset = int(match->bufferRequired.value());
        if (auto* const_val = match->value->to<IR::BFN::LoweredConstMatchValue>()) {
            // TODO(yumin): value can be truncated to represent values in each
            // match register, for more precise result.
            match_t v = const_val->value;
            match_on.mask = (~(v.word0 ^ v.word1));
            match_on.value = (v.word0 ^ v.word1);
        } else if (auto* pvs = match->value->to<IR::BFN::LoweredPvsMatchValue>()) {
            match_on.value_set = pvs->name;
        } else {
            BUG("unknown pvs: %1%", match->value);
        }
    }
    return rst;
}

int GenerateParserP4iJson::getStateId(const IR::BFN::LoweredParserState* state) {
    // XXX(yumin): the `end` state is a leaf state.
    if (!state_ids.count(state)) {
        int id = state_ids.size();
        state_ids[state] = id;
    }
    return state_ids.at(state);
}

/// Assign a tcam id for this match, higher the number, higher the priority.
int GenerateParserP4iJson::getTcamId(const IR::BFN::LoweredParserMatch* match) {
    static const int MAX_TCAM_ID = 255;
    if (!tcam_ids.count(match)) {
        int id = MAX_TCAM_ID - tcam_ids.size();
        tcam_ids[match] = id; }
    return tcam_ids.at(match);
}

P4iParserState
GenerateParserP4iJson::generateStateByMatch(
        const IR::BFN::LoweredParserState* state_ir,
        const IR::BFN::LoweredParserMatch* match) {
    // Create a parser state out from this match.
    P4iParserState state;
    state.state_id      = getStateId(state_ir);
    state.tcam_row      = getTcamId(match);
    state.shifts        = match->shift;
    state.extracts      = generateExtracts(match);
    state.matchesOn     = generateMatchOn(state_ir, match);
    state.has_counter   = false;  // TODO(yumin): update this when counter is supported.
    state.state_name    = state_ir->name;
    state.next_state_id = getStateId(match->next);
    return state;
}

bool GenerateParserP4iJson::preorder(const IR::BFN::LoweredParserState* state) {
    auto* parser_ir = findContext<IR::BFN::LoweredParser>();
    BUG_CHECK(parser_ir, "state does not belong to a parser? %1%", state);
    for (const auto* match : state->match) {
        parsers[parser_ir->gress].states.push_back(
                generateStateByMatch(state, match));
    }
    return true;
}
