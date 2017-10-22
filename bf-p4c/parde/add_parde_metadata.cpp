#include "bf-p4c/parde/add_parde_metadata.h"
#include "bf-p4c/device.h"
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
    switch (parser->gress) {
        case INGRESS: addIngressMetadata(parser); break;
        case EGRESS:  addEgressMetadata(parser);  break;
    }

    return false;
}

void AddMetadataShims::addIngressMetadata(IR::BFN::Parser *parser) {
    // XXX(hanw): remove after tna translation for p16 is done
    cstring ingress_intrinsic_metadata = useTna ? "ingress_intrinsic_metadata_for_tm" :
                                                  "standard_metadata";

    auto alwaysDeparseBit =
        new IR::TempVar(IR::Type::Bits::get(1), true, "$always_deparse");

    auto* meta = pipe->metadata[ingress_intrinsic_metadata];

    for (auto meta : pipe->metadata) {
        LOG1("metadata " << meta.first << " " << meta.second);
    }
    if (!meta || !meta->type->getField("ingress_port") ||
                 !meta->type->getField("resubmit_flag")) {
        // There's not really much we can do in this case; just skip over
        // the intrinsic metadata.
        IR::Vector<IR::BFN::ParserPrimitive> init = {
            new IR::BFN::ExtractConstant(alwaysDeparseBit,
                                         new IR::Constant(IR::Type::Bits::get(1), 1))
        };
        const auto byteSkip = Device::pardeSpec().byteTotalIngressMetadataSize();
        parser->start =
            new IR::BFN::ParserState("$skip_metadata", INGRESS, init, { }, {
                new IR::BFN::Transition(match_t(), byteSkip, parser->start)
            });
        return;
    }

    // Add a state that skips over any padding between the phase 0 data and the
    // beginning of the packet.
    // XXX(seth): This "padding" is new in JBay, and it may contain actual data
    // rather than just padding. Once we have a chance to investigate what it
    // does, we'll want to revisit this.
    const auto byteSkip = Device::pardeSpec().byteIngressPrePacketPaddingSize();
    auto* skipToPacketState =
      new IR::BFN::ParserState("$skip_to_packet", INGRESS, { }, { }, {
          new IR::BFN::Transition(match_t(), byteSkip, parser->start)
      });

    // Add a state that parses the phase 0 data. This is a placeholder that
    // just skips it; if we find a phase 0 table, it'll be replaced later.
    const auto bytePhase0Size = Device::pardeSpec().bytePhase0Size();
    auto* phase0State =
        new IR::BFN::ParserState("$phase0", INGRESS, { }, { }, {
            new IR::BFN::Transition(match_t(), bytePhase0Size, skipToPacketState)
        });

    // This state handles the extraction of all intrinsic metadata other
    // than the resubmit flag.
    const auto byteIgMetadataSize =
      Device::pardeSpec().byteIngressMetadataPrefixSize();
    auto* igPort = gen_fieldref(meta, "ingress_port");
    IR::Vector<IR::BFN::ParserPrimitive> extractIgMetadata = {
        new IR::BFN::ExtractBuffer(igPort, StartLen(7, 9)),
    };
    auto intrinsicState =
        new IR::BFN::ParserState("$ingress_metadata", INGRESS,
                                 extractIgMetadata, { }, {
            new IR::BFN::Transition(match_t(), byteIgMetadataSize, phase0State)
        });

    // On ingress, parsing starts by initializing constants and checking the
    // resubmit flag. If it's not set, we parse the ingress metadata and
    // transition to phase 0. If it is set, we have a resubmitted packet,
    // which we need to handle differently.
    // XXX(seth): For now, we check the resubmit flag but branch to the same
    // place no matter what. We need to figure out what to do here.
    auto resubmitFlag = gen_fieldref(meta, "resubmit_flag");
    IR::Vector<IR::BFN::ParserPrimitive> init = {
        new IR::BFN::ExtractBuffer(resubmitFlag, StartLen(0, 1)),
        new IR::BFN::ExtractConstant(alwaysDeparseBit,
                                     new IR::Constant(IR::Type::Bits::get(1), 1))
    };
    auto* toNormal =
      new IR::BFN::Transition(match_t(8, 0, 0x80), 0, intrinsicState);
    auto* toResubmit =
      new IR::BFN::Transition(match_t(8, 0x80, 0x80), 0, intrinsicState);
    parser->start =
      new IR::BFN::ParserState("$ingress_metadata_shim", INGRESS, init,
                               { new IR::BFN::SelectBuffer(StartLen(0, 1)) },
                               { toNormal, toResubmit });
}

void AddMetadataShims::addEgressMetadata(IR::BFN::Parser *parser) {
    // XXX(hanw): remove after tna translation for p16 is done
    cstring egress_intrinsic_metadata = useTna ? "egress_intrinsic_metadata"
                                               : "standard_metadata";
    const auto byteEgMetadataSize =
      Device::pardeSpec().byteEgressMetadataSize();

    // Add a state that parses bridged metadata. This is just a placeholder;
    // we'll replace it once we know which metadata need to be bridged.
    auto bridgedMetadataState =
        new IR::BFN::ParserState("$bridged_metadata", EGRESS, { }, { }, {
            new IR::BFN::Transition(match_t(), 0, parser->start)
        });

    auto* meta = pipe->metadata[egress_intrinsic_metadata];
    if (!meta || !meta->type->getField("egress_port")) {
        // There's not really much we can do in this case; just skip over
        // the intrinsic metadata.
        parser->start =
            new IR::BFN::ParserState("$skip_metadata", EGRESS, { }, { }, {
                new IR::BFN::Transition(match_t(), byteEgMetadataSize,
                                        bridgedMetadataState)
            });
        return;
    }

    // On egress, we start by extracting the egress intrinsic metadata and
    // then begin processing bridged metadata.
    // XXX(seth): We'll eventually need to handle mirroring and coalescing
    // here, too.
    IR::Vector<IR::BFN::ParserPrimitive> extractEgMetadata = {
        new IR::BFN::ExtractBuffer(gen_fieldref(meta, "egress_port"),
                                   StartLen(7, 9))
    };
    parser->start =
      new IR::BFN::ParserState("$egress_metadata_shim", parser->gress,
                               extractEgMetadata, { }, {
          new IR::BFN::Transition(match_t(), byteEgMetadataSize,
                                  bridgedMetadataState)
      });
}

bool AddMetadataShims::preorder(IR::BFN::Deparser *d) {
    switch (d->gress) {
        case INGRESS: addIngressMetadata(d); break;
        case EGRESS:  addEgressMetadata(d);  break;
    }

    return false;
}

void AddMetadataShims::addDeparserIntrinsic(IR::BFN::Deparser *d, const IR::HeaderOrMetadata *meta,
                                            cstring field, cstring intrinsic) {
    if (meta->type->getField(field))
        d->metadata[intrinsic] = new IR::BFN::DeparserIntrinsic(gen_fieldref(meta, field));
}

void AddMetadataShims::addIngressMetadata(IR::BFN::Deparser *d) {
    // XXX(hanw): remove after tna translation for p16 is done
    cstring ingress_intrinsic_metadata = useTna ? "ingress_intrinsic_metadata_for_tm" :
                                                  "standard_metadata";

    auto *meta = pipe->metadata[ingress_intrinsic_metadata];
    if (!meta) return;

    cstring ingress_egress_port = useTna ? "ucast_egress_port" : "egress_spec";
    addDeparserIntrinsic(d, meta, ingress_egress_port, "egress_unicast_port");

    // XXX(hanw): remove after tna translation for p16 is done
    if (useTna) {
        addDeparserIntrinsic(d, meta, "mcast_grp_a", "egress_multicast_group_a");
        addDeparserIntrinsic(d, meta, "mcast_grp_b", "egress_multicast_group_b");
    } else {
        addDeparserIntrinsic(d, meta, "mcast_grp", "egress_multicast_group"); }
    addDeparserIntrinsic(d, meta, "deflect_on_drop", "deflect_on_drop");
    addDeparserIntrinsic(d, meta, "packet_color", "meter_color");
    addDeparserIntrinsic(d, meta, "ingress_cos", "icos");
    addDeparserIntrinsic(d, meta, "qid", "qid");
    addDeparserIntrinsic(d, meta, "bypass_egress", "bypss_egr");
    addDeparserIntrinsic(d, meta, "enable_mcast_cutthru", "ct_mcast");
}

void AddMetadataShims::addEgressMetadata(IR::BFN::Deparser *d) {
    // XXX(hanw): remove after tna translation for p16 is done
    cstring egress_intrinsic_metadata = useTna ? "egress_intrinsic_metadata" :
                                                 "standard_metadata";

    // egress_port is read-only
    auto *meta = pipe->metadata[egress_intrinsic_metadata];
    if (!meta) return;
    addDeparserIntrinsic(d, meta, "egress_port", "egress_unicast_port");
    addDeparserIntrinsic(d, meta, "egress_cos", "ecos");
}
