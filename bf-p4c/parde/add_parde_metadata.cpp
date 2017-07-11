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

        // Add a state that parses the phase 0 data. This is a placeholder that
        // just skips it; if we find a phase 0 table, it'll be replaced later.
        auto phase0Match =
            new IR::Tofino::ParserMatch(match_t(), 8, { }, parser->start);
        auto phase0State =
            new IR::Tofino::ParserState("$phase0", INGRESS, { }, { phase0Match });

        // This state handles the extraction of all intrinsic metadata other
        // than the resubmit flag.
        auto igPort = gen_fieldref(meta, "ingress_port");
        auto intrinsicMatch = new IR::Tofino::ParserMatch(match_t(), 8, {
                new IR::Primitive("extract", igPort),
            }, phase0State);
        auto intrinsicState =
            new IR::Tofino::ParserState("$ingress_metadata", INGRESS,
                                        { }, { intrinsicMatch });

        // On ingress, parsing starts by initializing constants and checking the
        // resubmit flag. If it's not set, we parse the ingress metadata and
        // transition to phase 0. If it is set, we have a resubmitted packet,
        // which we need to handle differently.
        // XXX(seth): For now, we just skip directly to the start state when we
        // encounter a resubmitted packet, but we probably need to do more.
        auto resubmitFlag = gen_fieldref(meta, "resubmit_flag");
        IR::Vector<IR::Expression> init = {
            new IR::Primitive("set_metadata",
                new IR::TempVar(IR::Type::Bits::get(1), true, "$always_deparse"),
                new IR::Constant(IR::Type::Bits::get(1), 1)),
            new IR::Primitive("extract", resubmitFlag)
        };
        auto normalMatch = new IR::Tofino::ParserMatch(match_t(8, 0, 0x80), 0,
                                                       init, intrinsicState);
        auto resubmitMatch = new IR::Tofino::ParserMatch(match_t(8, 0x80, 0x80), 16,
                                                         init, parser->start);
        parser->start =
            new IR::Tofino::ParserState("$ingress_metadata_shim", INGRESS,
                                        { resubmitFlag },
                                        { normalMatch, resubmitMatch });
    } else if (parser->gress == EGRESS) {
        // Add a state that parses bridged metadata. This is just a placeholder;
        // we'll replace it once we know which metadata need to be bridged.
        auto bridgedMetadataMatch =
            new IR::Tofino::ParserMatch(match_t(), 0, { }, parser->start);
        auto bridgedMetadataState =
            new IR::Tofino::ParserState("$bridged_metadata", EGRESS, { },
                                        { bridgedMetadataMatch });

        auto* meta = pipe->metadata["standard_metadata"];
        if (!meta || !meta->type->getField("egress_port")) {
            // There's not really much we can do in this case; just skip over
            // the intrinsic metadata.
            auto match =
                new IR::Tofino::ParserMatch(match_t(), 2, { }, bridgedMetadataState);
            parser->start =
                new IR::Tofino::ParserState("$skip_metadata", EGRESS, { }, { match });
            return false;
        }

        // On egress, we start by extracting the egress intrinsic metadata and
        // then begin processing bridged metadata.
        // XXX(seth): We'll eventually need to handle mirroring and coalescing
        // here, too.
        parser->start = new IR::Tofino::ParserState(
            "$egress_metadata_shim", parser->gress, {}, {
            new IR::Tofino::ParserMatch(match_t(), 2, {
                new IR::Primitive("extract", gen_fieldref(meta, "egress_port"))
            }, bridgedMetadataState) });
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
