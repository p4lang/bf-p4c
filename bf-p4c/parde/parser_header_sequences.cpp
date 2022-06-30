#include "parser_header_sequences.h"

Visitor::profile_t ParserHeaderSequences::init_apply(const IR::Node *node) {
    header_id_cnt = 0;
    headers.clear();
    header_ids.clear();
    sequences.clear();
    return Inspector::init_apply(node);
}

void ParserHeaderSequences::flow_merge(Visitor& other_) {
    auto& other = dynamic_cast<ParserHeaderSequences&>(other_);
    for (const auto& kv : other.headers) {
        headers[kv.first].insert(kv.second.begin(), kv.second.end());
    }
    for (const auto& kv : other.sequences) {
        sequences[kv.first].insert(kv.second.begin(), kv.second.end());
    }
    header_ids.insert(other.header_ids.begin(), other.header_ids.end());
}

/** @brief Create an empty set of sequences for each parser */
bool ParserHeaderSequences::preorder(const IR::BFN::Parser* parser) {
    sequences.emplace(parser->gress, ordered_set<ordered_set<cstring>>({{}}));
    return true;
}

void ParserHeaderSequences::record_header(gress_t gress, cstring header) {
    if (!headers[gress].count(header)) LOG1("Found header: " << header);
    // Assign a unique header ID
    if (!headers[gress].count(header)) header_ids[{gress, header}] = header_id_cnt++;
    headers[gress].emplace(header);
    for (auto& seq : sequences[gress]) seq.emplace(header);
}

/**
 * @brief Record header extractions.
 *
 * Record:
 *  - Headers of the non-metadata and non-POV fields extracted in parser.
 *  - Headers identified from `$stkvalid` extractions. The `$stkvalid` field is often wider than the
 *    stack depth to allow for left/right shifts corresponding to push/pop operations.
 */
bool ParserHeaderSequences::preorder(const IR::BFN::Extract* extract) {
    auto* lval = extract->dest->to<IR::BFN::FieldLVal>();
    if (!lval) return true;

    auto* field = phv.field(lval->field);
    if (!field || !field->header()) return false;

    // Stack valid ($stkvalid) processing
    const auto* member = lval->field->to<IR::Member>();
    if (member && member->member == "$stkvalid") {
        const auto* ir = member->expr->to<IR::InstanceRef>();
        const auto* tb = member->type->to<IR::Type_Bits>();
        if (ir && tb) {
            if (const auto* hs = ir->obj->to<IR::HeaderStack>()) {
                auto header = hs->name;
                int depth = hs->size;
                int stkvalid_width = tb->size;
                int shift = (stkvalid_width - depth) / 2;
                LOG5("Found stack " << header << " with depth: " << depth);

                // Walk through the $stkvalid bits being set and convert to stack indices.
                // $stkvalid includes pad bits at top/bottom to accommodate the largest shifts;
                // these should be ingored when converting to stack indices.
                if (auto* rval_const = extract->source->to<IR::BFN::ConstantRVal>()) {
                    for (auto bit : bitvec(rval_const->constant->asInt())) {
                        if (bit < depth + shift && bit >= shift) {
                            int idx = depth - (bit - shift) - 1;
                            cstring stack_instance = header + "[" + std::to_string(idx) + "]";
                            record_header(field->gress, stack_instance);
                        }
                    }
                }
            }
        }
        return false;
    }

    // Regular field processing
    if (field->pov || field->metadata) return false;
    record_header(field->gress, field->header());
    return false;
}

void ParserHeaderSequences::end_apply() {
    for (auto& seq : sequences[INGRESS]) seq.emplace(payloadHeaderName);
    headers[INGRESS].insert(payloadHeaderName);
    header_ids[{INGRESS, payloadHeaderName}] = payloadHeaderID;
    if (LOGGING(1)) {
        LOG1("Headers:");
        for (auto gress : {INGRESS, EGRESS}) {
            std::stringstream ss;
            ss << "    " << gress << ": ";
            cstring sep = "";
            for (auto& hdr : headers[gress]) {
                ss << sep << hdr;
                sep = " ";
            }
            LOG1(ss.str());
        }

        LOG1("Header sequences:");
        for (auto gress : {INGRESS, EGRESS}) {
            LOG1("  GRESS: " << gress);
            for (const auto& seq : sequences[gress]) {
                std::stringstream ss;
                ss << "    - [";
                cstring sep = "";
                for (const auto hdr : seq) {
                    ss << sep << hdr;
                    sep = ", ";
                }
                ss << "]";
                LOG1(ss.str());
            }
        }
    }
}
