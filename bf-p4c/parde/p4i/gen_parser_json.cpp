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
            size_t container_sz = extract_ir->dest->container.size();
            const auto &phvSpec = Device::phvSpec();
            auto cid = phvSpec.containerToId(extract_ir->dest->container);
            extract.extractor_id = extractor_ids[container_sz]++;
            extract.bit_width = container_sz;
            extract.dest_container = phvSpec.physicalAddress(cid,  PhvSpec::MAU);
            if (auto* buffer = extract_ir->source->to<IR::BFN::LoweredInputBufferRVal>()) {
                extract.buffer_offset = buffer->range.loByte();
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
                                       const IR::BFN::LoweredParserMatch* match) {
    std::vector<P4iParserMatchOn> rst;
    if (!prev_state) return rst;

    for (const auto& reg : prev_state->select->regs) {
        P4iParserMatchOn match_on;
        match_on.hardware_id   = reg.id;
        match_on.bit_width     = reg.size * 8;

        if (auto* const_val = match->value->to<IR::BFN::LoweredConstMatchValue>()) {
            std::stringstream v;
            v << const_val->value;
            match_on.value = v.str();
        } else if (auto* pvs = match->value->to<IR::BFN::LoweredPvsMatchValue>()) {
            match_on.value_set = pvs->name;
        } else {
            BUG("Unknown parser match value type: %1%", match->value);
        }
        rst.push_back(match_on);
    }
    return rst;
}

std::vector<P4iParserSavesTo>
GenerateParserP4iJson::generateSaves(const IR::BFN::LoweredParserMatch* match) {
    std::vector<P4iParserSavesTo> rst;

    for (const auto& save : match->saves) {
        P4iParserSavesTo saves_to;
        saves_to.hardware_id   = save->dest.id;
        if (auto* buffer = save->source->to<IR::BFN::LoweredInputBufferRVal>()) {
            saves_to.buffer_offset = buffer->range.loByte();
        } else {
            BUG("Unknown match save source : %1%", save);
        }
        rst.push_back(saves_to);
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
int GenerateParserP4iJson::getTcamId(const IR::BFN::LoweredParserMatch* match, gress_t gress) {
    if (!tcam_ids[gress].count(match)) {
        int id = Device::pardeSpec().numTcamRows() - tcam_ids[gress].size() - 1;
        tcam_ids[gress][match] = id;
    }
    return tcam_ids[gress].at(match);
}

P4iParserStateTransition
GenerateParserP4iJson::generateStateTransitionByMatch(
        const IR::BFN::LoweredParserState* next_state,
        const IR::BFN::LoweredParserState* prev_state,
        const IR::BFN::LoweredParserMatch* match) {
    // Create a parser state transition out from this match.
    P4iParserStateTransition state_transition;
    state_transition.tcam_row           = getTcamId(match, prev_state->gress);
    state_transition.shifts             = match->shift;
    state_transition.extracts           = generateExtracts(match);
    state_transition.saves              = generateSaves(match);
    state_transition.matches            = generateMatches(prev_state, match);
    // TODO(yumin): update this when counter is supported.
    state_transition.has_counter        = false;
    state_transition.next_state_id      = getStateId(next_state);
    state_transition.next_state_name    = next_state ? next_state->name : "END";
    if (prev_state) {
        state_transition.previous_state_id = getStateId(prev_state);
        state_transition.previous_state_name = prev_state->name;
    }

    return state_transition;
}

P4iParserClot
GenerateParserP4iJson::generateExtractClot(const IR::BFN::LoweredExtractClot* extract,
                                           const IR::BFN::LoweredParserState *state) {
    auto* source = extract->source->to<IR::BFN::LoweredPacketRVal>();
    P4iParserClot clot;
    auto bytes = source->range;
    clot.issue_state = state->name;
    clot.offset = bytes.lo;
    clot.tag = extract->dest.tag;
    clot.length = bytes.hi - bytes.lo + 1;
    if (clot_tag_to_checksum_unit.count(extract->dest.tag))
        clot.has_checksum = true;
    if (auto c = clotInfo.parser_state_to_clot(state, clot.tag)) {
        std::vector<P4iParserClotField> fl;
        int clot_offset = 0;
        for (auto *f : c->all_slices()) {
            P4iParserClotField cf;
            cf.name = canon_name(f->field()->name);
            cf.field_msb = f->range().hi;
            cf.field_lsb = f->range().lo;
            cf.clot_offset = clot_offset;
            clot_offset += f->field()->size;
            fl.push_back(cf);
        }
        clot.field_lists.push_back(fl);
    }
    return clot;
}

void GenerateParserP4iJson::generateClotInfo(const IR::BFN::LoweredParserMatch* match,
                            const IR::BFN::LoweredParserState *state, const gress_t gress) {
    for (auto* ck : match->checksums) {
        if (auto* csum = ck->to<IR::BFN::LoweredParserChecksum>())
            if (csum->type == IR::BFN::ChecksumMode::CLOT)
                clot_tag_to_checksum_unit[csum->clot_dest.tag] = csum->unit_id;
    }

    for (auto* stmt : match->extracts) {
        if (auto* extract = stmt->to<IR::BFN::LoweredExtractClot>()) {
            clot_usage[gress].clots.push_back(generateExtractClot(extract, state));
        }
    }
}

bool GenerateParserP4iJson::preorder(const IR::BFN::LoweredParserState* state) {
    auto parser_ir = findContext<IR::BFN::LoweredParser>();
    BUG_CHECK(parser_ir, "state does not belong to a parser? %1%", state);

    // auto prev_state = findContext<IR::BFN::LoweredParserState>();
    for (const auto* match : state->transitions) {
        LOG1("State Match: " << match);
        parsers[parser_ir->gress].states.push_back(
                generateStateTransitionByMatch(match->next, state, match));
    }

    if ((Device::currentDevice() == Device::JBAY) && BackendOptions().use_clot) {
        for (const auto* match : state->transitions) {
            generateClotInfo(match, state, parser_ir->gress);
            // A parser state can have multiple extracts, but the clot
            // information is duplicated across all of them. Hence, we only
            // check the first extract to gather all clot info for this state.
            break;
        }
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
