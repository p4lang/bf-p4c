#include "bf-p4c/parde/p4i/gen_parser_json.h"

#include <boost/optional.hpp>
#include <vector>

#include "bf-p4c/common/asm_output.h"

std::vector<P4iParserExtract>
GenerateParserP4iJson::generateExtracts(const IR::BFN::LoweredParserMatch* match) {
    std::vector<P4iParserExtract> rst;
    std::map<size_t, int> extractor_ids;
    for (const auto* prim : match->extracts) {
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
            if (auto* buffer = extract_ir->source->to<IR::BFN::LoweredInputBufferRVal>()) {
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
GenerateParserP4iJson::generateMatches(const IR::BFN::LoweredParserState* prev_state,
                                       const IR::BFN::LoweredParserState* curr_state,
                                       const IR::BFN::LoweredParserMatch* match) {
    std::vector<P4iParserMatchOn> rst;

    for (const auto& reg : curr_state->select->regs) {
        P4iParserMatchOn match_on;
        match_on.hardware_id   = reg.id;
        match_on.bit_width     = reg.size * 8;

        // XXX(zma) This assumes the match word is saved into the match registers in the
        // previous state. This however is not true in general -- match word can be saved
        // and forward to any future state.
        if (prev_state) {
            for (auto prev_match : prev_state->transitions) {
                for (auto prev_save : prev_match->saves) {
                    if (prev_save->dest == reg) {
                        match_on.buffer_offset = prev_save->source->extractedBytes().loByte();
                    }
                }
            }
        }

        if (auto* const_val = match->value->to<IR::BFN::LoweredConstMatchValue>()) {
            // TODO(yumin): value can be truncated to represent values in each
            // match register, for more precise result.
            match_t v = const_val->value;
            match_on.mask = (~(v.word0 ^ v.word1));
            match_on.value = (v.word0 ^ v.word1);
        } else if (auto* pvs = match->value->to<IR::BFN::LoweredPvsMatchValue>()) {
            match_on.value_set = pvs->name;
        } else {
            BUG("Unknown parser match value type: %1%", match->value);
        }
        rst.push_back(match_on);
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
        int id = MAX_TCAM_ID - (tcam_ids.size() - 1);
        id = (id < 0) ? 0 : ((id > MAX_TCAM_ID) ? MAX_TCAM_ID : id);
        tcam_ids[match] = id; }
    return tcam_ids.at(match);
}

P4iParserState
GenerateParserP4iJson::generateStateByMatch(
        const IR::BFN::LoweredParserState* curr_state,
        const IR::BFN::LoweredParserState* prev_state,
        const IR::BFN::LoweredParserMatch* match) {
    // Create a parser state out from this match.
    P4iParserState state;
    state.state_id      = getStateId(curr_state);
    state.tcam_row      = getTcamId(match);
    state.shifts        = match->shift;
    state.extracts      = generateExtracts(match);
    state.matches       = generateMatches(prev_state, curr_state, match);
    state.has_counter   = false;  // TODO(yumin): update this when counter is supported.
    state.state_name    = curr_state->name;
    if (prev_state) {
        state.previous_state_id = getStateId(prev_state);
        state.previous_state_name = prev_state->name;
    }

    return state;
}

P4iParserClot
GenerateParserP4iJson::generateExtractClot(const IR::BFN::LoweredExtractClot* extract,
                                           const cstring state) {
    auto* source = extract->source->to<IR::BFN::LoweredPacketRVal>();
    P4iParserClot clot;
    auto bytes = source->extractedBytes();
    clot.issue_state = state;
    clot.offset = bytes.lo;
    clot.tag = extract->dest.tag;
    clot.length = bytes.hi - bytes.lo + 1;
    if (clot_tag_to_checksum_unit.count(extract->dest.tag))
        clot.has_checksum = true;
    if (auto c = clotInfo.parser_state_to_clot(clot.issue_state, clot.tag)) {
        // TODO: Clot can contain multiple field lists due to overlay. Add once
        // support is availabe in Clot structure.
        std::vector<cstring> fl;
        for (auto *f : c->all_fields())
            fl.push_back(cstring::to_cstring(canon_name(f->name)));
        clot.field_lists.push_back(fl);
    }
    return clot;
}

void GenerateParserP4iJson::generateClotInfo(const IR::BFN::LoweredParserMatch* match,
                                                const cstring state, const gress_t gress) {
    for (auto* ck : match->checksums) {
        if (auto* csum = ck->to<IR::BFN::LoweredParserChecksum>())
            if (csum->type == IR::BFN::ChecksumMode::CLOT)
                clot_tag_to_checksum_unit[csum->clot_dest.tag] = csum->unit_id;
    }

    int numClots = 0;
    for (auto* stmt : match->extracts) {
        if (auto* extract = stmt->to<IR::BFN::LoweredExtractClot>()) {
            clot_usage.clots.push_back(generateExtractClot(extract, state));
            numClots++;  // seems redundant as equal to clots size?
        }
    }
    clot_usage.gress = gress;
    clot_usage.num_clots = numClots;
}

bool GenerateParserP4iJson::preorder(const IR::BFN::LoweredParserState* state) {
    auto parser_ir = findContext<IR::BFN::LoweredParser>();
    BUG_CHECK(parser_ir, "state does not belong to a parser? %1%", state);

    auto prev_state = findContext<IR::BFN::LoweredParserState>();
    for (const auto* match : state->transitions) {
        parsers[parser_ir->gress].states.push_back(
                generateStateByMatch(state, prev_state, match));
        if ((Device::currentDevice() == Device::JBAY) && BackendOptions().use_clot)
            generateClotInfo(match, state->name, parser_ir->gress);
    }

    if (parser_ir->gress == INGRESS) {
        P4iPhase0 phase0;
        auto ig_p0 = (parser_ir) ? parser_ir->phase0 : nullptr;
        if (ig_p0) {
            phase0.table_name = ig_p0->tableName;
            phase0.action_name = ig_p0->actionName;
        }
        parsers[parser_ir->gress].phase0 = phase0;
    }

    return true;
}
