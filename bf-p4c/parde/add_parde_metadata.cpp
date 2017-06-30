#include "add_parde_metadata.h"
#include "lib/exceptions.h"

IR::Member *gen_fieldref(const IR::HeaderOrMetadata *hdr, cstring field) {
    const IR::Type *ftype = nullptr;
    auto f = hdr->type->getField(field);
    if (f != nullptr)
        ftype = f->type;
    else
        BUG("No field %s in %s", field, hdr->name);
    return new IR::Member(ftype, new IR::ConcreteHeaderRef(hdr), field);
}

bool AddMetadataShims::preorder(IR::Tofino::Parser *parser) {
    if (parser->gress == INGRESS) {
        // Add a state that parses the phase 0 data. This is a placeholder that
        // just skips it; if we find a phase 0 table, it'll be replaced later.
        auto phase0Match =
            new IR::Tofino::ParserMatch(match_t(), 8, { }, parser->start);
        auto phase0State =
            new IR::Tofino::ParserState("$phase0", INGRESS, { }, { phase0Match });

        auto* meta = pipe->metadata["standard_metadata"];
        if (!meta || !meta->type->getField("ingress_port") ||
                     !meta->type->getField("resubmit_flag")) {
            // There's not really much we can do in this case; just skip over
            // the intrinsic metadata.
            auto match =
                new IR::Tofino::ParserMatch(match_t(), 16, { }, parser->start);
            parser->start =
                new IR::Tofino::ParserState("$skip_metadata", INGRESS, { }, { match });
            return false;
        }

        // This state handles the extraction of all intrinsic metadata other
        // than the resubmit flag.
        auto igPort = gen_fieldref(meta, "ingress_port");
        auto intrinsicMatch = new IR::Tofino::ParserMatch(match_t(), 8, {
                new IR::Primitive("extract", igPort),
            }, phase0State);
        auto intrinsicState =
            new IR::Tofino::ParserState("$ingress_metadata", INGRESS,
                                        { }, { intrinsicMatch });

        // Parsing starts by checking the resubmit flag. If it's not set, we
        // parse the ingress metadata and transition to phase 0. If it is set,
        // we have a resubmitted packet, which we need to handle differently;
        // for now, we just skip directly to the start state.
        auto resubmitFlag = gen_fieldref(meta, "resubmit_flag");
        auto normalMatch = new IR::Tofino::ParserMatch(match_t(1, 1, 1), 0, {
                new IR::Primitive("extract", resubmitFlag),
            }, intrinsicState);
        auto resubmitMatch = new IR::Tofino::ParserMatch(match_t(1, 0, 1), 16, {
                new IR::Primitive("extract", resubmitFlag),
            }, parser->start);
        parser->start =
            new IR::Tofino::ParserState("$ingress_metadata_shim", INGRESS,
                                        { resubmitFlag },
                                        { normalMatch, resubmitMatch });
    } else if (parser->gress == EGRESS) {
        auto* meta = pipe->metadata["standard_metadata"];
        if (!meta || !meta->type->getField("egress_port")) return false;
        parser->start = new IR::Tofino::ParserState(
            "$egress_metadata_shim", parser->gress, {}, {
            new IR::Tofino::ParserMatch(match_t(), 2, {
                new IR::Primitive("extract", gen_fieldref(meta, "egress_port")) },
                parser->start) });
    }
    return false;
}

bool AddMetadataShims::preorder(IR::Tofino::Deparser *d) {
    if (d->gress == INGRESS) {
        auto *meta = pipe->metadata["standard_metadata"];
        if (!meta || !meta->type->getField("egress_spec")) return false;
        d->egress_port = gen_fieldref(meta, "egress_spec");
    } else if (d->gress == EGRESS) {
        // egress_port is read-only
        auto *meta = pipe->metadata["standard_metadata"];
        if (!meta || !meta->type->getField("egress_port")) return false;
        d->egress_port = gen_fieldref(meta, "egress_port");
    }
    return false;
}
