#include "bf-p4c/parde/p4i/gen_parser_json.h"

#include <boost/optional.hpp>
#include <vector>

#include "bf-p4c/ir/gress.h"
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

    int shift = 0;
    auto &regs = prev_state->select->regs;
    for (auto rItr = regs.rbegin(); rItr != regs.rend(); rItr++) {
        auto reg = *rItr;
        P4iParserMatchOn match_on;
        match_on.hardware_id   = reg.id;
        match_on.bit_width     = reg.size * 8;

        if (auto* const_val = match->value->to<IR::BFN::ParserConstMatchValue>()) {
            std::stringstream v;
            auto w0 = const_val->value.word0 >> shift;
            auto w1 = const_val->value.word1 >> shift;
            auto mask = (1U << match_on.bit_width) - 1;
            match_t m = { w0 & mask, w1 & mask };
            v << m;
            match_on.value = v.str();
            shift += match_on.bit_width;
        } else if (auto* pvs = match->value->to<IR::BFN::ParserPvsMatchValue>()) {
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

int GenerateParserP4iJson::getStateId(cstring state) {
    if (!state_ids.count(state)) {
        int id = state_ids.size();
        state_ids[state] = id;
    }
    return state_ids.at(state);
}

/// Assign a tcam id for this match, higher the number, higher the priority.
int GenerateParserP4iJson::getTcamId(const IR::BFN::LoweredParserMatch* match, gress_t gress) {
    auto* pvs = match->value->to<IR::BFN::ParserPvsMatchValue>();
    if (!tcam_ids[gress].count(match)) {
        tcam_ids[gress][match] = next_tcam_id[gress];
        next_tcam_id[gress] -= pvs ? pvs->size : 1;  // pvs uses multiple TCAM rows
    }

    return tcam_ids[gress].at(match);
}

std::vector<P4iParserStateTransition>
GenerateParserP4iJson::generateStateTransitionsByMatch(
        cstring next_state,
        const IR::BFN::LoweredParserState* prev_state,
        const IR::BFN::LoweredParserMatch* match) {
    // Create a parser state transition out from this match.
    P4iParserStateTransition state_transition;
    state_transition.tcam_row           = getTcamId(match, prev_state->gress);
    state_transition.shifts             = match->shift;
    state_transition.extracts           = generateExtracts(match);
    state_transition.saves              = generateSaves(match);
    state_transition.matches            = generateMatches(prev_state, match);
    state_transition.has_counter        = !match->counters.empty();
    state_transition.next_state_id      = getStateId(next_state);
    state_transition.next_state_name    = next_state;
    if (prev_state) {
        state_transition.previous_state_id = getStateId(prev_state->name);
        state_transition.previous_state_name = prev_state->name;
    }

    std::vector<P4iParserStateTransition> ret_states = {state_transition};
    // Duplicate the node iff we are working with parser set values, this is important
    // due to the right count of the used TCAM values.
    if (auto* pvs = match->value->to<IR::BFN::ParserPvsMatchValue>()) {
        const int dup_count = pvs->size - 1;
        for (int dup_i = 0; dup_i < dup_count; dup_i++) {
            // The copy of the P4iParserStateTransition is created during the push_back
            state_transition.tcam_row--;
            ret_states.push_back(state_transition);
        }
    }

    return ret_states;
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
            // Don't generate JSON for the extracted CLOT if the CLOT is spilled.
            if (!extract->is_start) continue;

            clot_usage[gress].clots.push_back(generateExtractClot(extract, state));
        }
    }
}

bool GenerateParserP4iJson::preorder(const IR::BFN::LoweredParser* parser) {
    LOG1("parser : " << parser->name);
    P4iParser *p = new P4iParser();
    p->parser_name   = parser->name;
    p->parser_id     = parser->portmap.size() > 0 ? parser->portmap[0] : 0;
    p->n_states      = Device::pardeSpec().numTcamRows();
    p->gress         = ::toString(parser->gress);
    parsers[parser->name] = p;
    return true;
}

bool GenerateParserP4iJson::preorder(const IR::BFN::LoweredParserState* state) {
    auto parser_ir = findContext<IR::BFN::LoweredParser>();
    BUG_CHECK(parser_ir, "state does not belong to a parser? %1%", state);
    BUG_CHECK(parsers.count(parser_ir->name) > 0, "Parser %1% not added to map", parser_ir->name);
    P4iParser *p = parsers[parser_ir->name];

    for (const auto* match : state->transitions) {
        LOG1("State Match: " << match);
        cstring next_state;
        if (match->next)
            next_state = match->next->name;
        else if (match->loop)
            next_state = match->loop;
        else
            next_state = "END";
        auto states = generateStateTransitionsByMatch(stripThreadPrefix(next_state), state, match);
        p->states.insert(p->states.end(), states.begin(), states.end());
    }

    if ((Device::numClots() > 0) && BackendOptions().use_clot) {
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
        p->phase0 = phase0;
    }

    return true;
}
