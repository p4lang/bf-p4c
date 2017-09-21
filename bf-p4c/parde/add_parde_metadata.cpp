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

bool AddMetadataShims::preorder(IR::BFN::Parser *parser) {
    // XXX(hanw): remove after tna translation for p16 is done
    cstring ingress_intrinsic_metadata;
    cstring egress_intrinsic_metadata;
    if (useTna) {
        ingress_intrinsic_metadata = "ingress_intrinsic_metadata";
        egress_intrinsic_metadata = "egress_intrinsic_metadata";
    } else {
        ingress_intrinsic_metadata = "standard_metadata";
        egress_intrinsic_metadata = "standard_metadata";
    }

    if (parser->gress == INGRESS) {
        auto alwaysDeparseBit =
            new IR::TempVar(IR::Type::Bits::get(1), true, "$always_deparse");

        auto* meta = pipe->metadata[ingress_intrinsic_metadata];
        if (!meta || !meta->type->getField("ingress_port") ||
                     !meta->type->getField("resubmit_flag")) {
            // There's not really much we can do in this case; just skip over
            // the intrinsic metadata.
            IR::Vector<IR::BFN::ParserPrimitive> init = {
                new IR::BFN::ExtractConstant(alwaysDeparseBit,
                                                new IR::Constant(IR::Type::Bits::get(1), 1))
            };
            auto match =
                new IR::BFN::ParserMatch(match_t(), 16, {init}, parser->start);
            parser->start =
                new IR::BFN::ParserState("$skip_metadata", INGRESS, { }, { match });
            return false;
        }

        // Add a state that parses the phase 0 data. This is a placeholder that
        // just skips it; if we find a phase 0 table, it'll be replaced later.
        auto phase0Match =
            new IR::BFN::ParserMatch(match_t(), 8, { }, parser->start);
        auto phase0State =
            new IR::BFN::ParserState("$phase0", INGRESS, { }, { phase0Match });

        // This state handles the extraction of all intrinsic metadata other
        // than the resubmit flag.
        auto igPort = gen_fieldref(meta, "ingress_port");
        auto intrinsicMatch = new IR::BFN::ParserMatch(match_t(), 8, {
                new IR::BFN::ExtractBuffer(igPort, 7, 9),
            }, phase0State);
        auto intrinsicState =
            new IR::BFN::ParserState("$ingress_metadata", INGRESS,
                                        { }, { intrinsicMatch });

        // On ingress, parsing starts by initializing constants and checking the
        // resubmit flag. If it's not set, we parse the ingress metadata and
        // transition to phase 0. If it is set, we have a resubmitted packet,
        // which we need to handle differently.
        // XXX(seth): For now, we check the resubmit flag but branch to the same
        // place no matter what. We need to figure out what to do here.
        auto resubmitFlag = gen_fieldref(meta, "resubmit_flag");
        IR::Vector<IR::BFN::ParserPrimitive> init = {
            new IR::BFN::ExtractBuffer(resubmitFlag, 0, 1),
            new IR::BFN::ExtractConstant(alwaysDeparseBit,
                                            new IR::Constant(IR::Type::Bits::get(1), 1))
        };
        auto normalMatch = new IR::BFN::ParserMatch(match_t(8, 0, 0x80), 0,
                                                       init, intrinsicState);
        auto resubmitMatch = new IR::BFN::ParserMatch(match_t(8, 0x80, 0x80), 0,
                                                         init, intrinsicState);
        parser->start =
            new IR::BFN::ParserState("$ingress_metadata_shim", INGRESS,
                                        { new IR::BFN::SelectBuffer(0, 1) },
                                        { normalMatch, resubmitMatch });
    } else if (parser->gress == EGRESS) {
        // Add a state that parses bridged metadata. This is just a placeholder;
        // we'll replace it once we know which metadata need to be bridged.
        auto bridgedMetadataMatch =
            new IR::BFN::ParserMatch(match_t(), 0, { }, parser->start);
        auto bridgedMetadataState =
            new IR::BFN::ParserState("$bridged_metadata", EGRESS, { },
                                        { bridgedMetadataMatch });

        auto* meta = pipe->metadata[egress_intrinsic_metadata];
        if (!meta || !meta->type->getField("egress_port")) {
            // There's not really much we can do in this case; just skip over
            // the intrinsic metadata.
            auto match =
                new IR::BFN::ParserMatch(match_t(), 2, { }, bridgedMetadataState);
            parser->start =
                new IR::BFN::ParserState("$skip_metadata", EGRESS, { }, { match });
            return false;
        }

        // On egress, we start by extracting the egress intrinsic metadata and
        // then begin processing bridged metadata.
        // XXX(seth): We'll eventually need to handle mirroring and coalescing
        // here, too.
        parser->start = new IR::BFN::ParserState(
            "$egress_metadata_shim", parser->gress, {}, {
            new IR::BFN::ParserMatch(match_t(), 2, {
                new IR::BFN::ExtractBuffer(gen_fieldref(meta, "egress_port"), 7, 9)
            }, bridgedMetadataState) });
    }
    return false;
}

bool AddMetadataShims::preorder(IR::BFN::Deparser *d) {
    // XXX(hanw): remove after tna translation for p16 is done
    cstring ingress_intrinsic_metadata;
    cstring egress_intrinsic_metadata;
    cstring ingress_egress_port;
    if (useTna) {
        ingress_intrinsic_metadata = "ingress_intrinsic_metadata_for_tm";
        egress_intrinsic_metadata = "egress_intrinsic_metadata";
        ingress_egress_port = "ucast_egress_port";
    } else {
        ingress_intrinsic_metadata = "standard_metadata";
        egress_intrinsic_metadata = "standard_metadata";
        ingress_egress_port = "egress_spec";
    }

    if (d->gress == INGRESS) {
        auto *meta = pipe->metadata[ingress_intrinsic_metadata];
        if (!meta || !meta->type->getField(ingress_egress_port)) return false;
        d->egress_port = gen_fieldref(meta, ingress_egress_port);
    } else if (d->gress == EGRESS) {
        // egress_port is read-only
        auto *meta = pipe->metadata[egress_intrinsic_metadata];
        if (!meta || !meta->type->getField("egress_port")) return false;
        d->egress_port = gen_fieldref(meta, "egress_port");
    }
    return false;
}
