#include "bf-p4c/parde/add_parde_metadata.h"
#include "bf-p4c/device.h"
#include "lib/exceptions.h"

namespace {

IR::Member *gen_fieldref(const IR::HeaderOrMetadata *hdr, cstring field) {
    const IR::Type *ftype = nullptr;
    auto f = hdr->type->getField(field);
    if (f != nullptr)
        ftype = f->type;
    else
        BUG("Couldn't find intrinsic metadata field %s in %s", field, hdr->name);
    return new IR::Member(ftype, new IR::ConcreteHeaderRef(hdr), field);
}

const IR::HeaderOrMetadata*
getMetadataType(const IR::BFN::Pipe* pipe, cstring typeName) {
    auto* meta = pipe->metadata[typeName];
    BUG_CHECK(meta != nullptr,
              "Couldn't find required intrinsic metadata type: %1%", typeName);
    return meta;
}

}  // namespace

bool AddMetadataShims::preorder(IR::BFN::Parser *parser) {
    switch (parser->gress) {
        case INGRESS: addIngressMetadata(parser); break;
        case EGRESS:  addEgressMetadata(parser);  break;
    }

    return false;
}

void AddMetadataShims::addIngressMetadata(IR::BFN::Parser *parser) {
    auto* igMeta = getMetadataType(pipe, "ingress_intrinsic_metadata");
    auto* igParserMeta =
      getMetadataType(pipe, "ingress_intrinsic_metadata_from_parser");

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

    // This state parses resubmit data. Just like phase 0, the version we're
    // generating here is a placeholder that just skips the data; we'll replace
    // it later with an actual implementation.
    const auto byteResubmitSize = Device::pardeSpec().byteResubmitSize();
    auto* resubmitState =
        new IR::BFN::ParserState("$resubmit", INGRESS, { }, { }, {
            new IR::BFN::Transition(match_t(), byteResubmitSize, skipToPacketState)
        });

    // If this is a resubmitted packet, the initial intrinsic metadata will be
    // followed by the resubmit data; otherwise, it's followed by the phase 0
    // data. This state checks the resubmit flag and branches accordingly.
    auto* resubmitFlagField = gen_fieldref(igMeta, "resubmit_flag");
    auto* checkResubmitState =
      new IR::BFN::ParserState("$check_resubmit", INGRESS, { },
        { new IR::BFN::Select(new IR::BFN::ComputedRVal(resubmitFlagField)) },
        { new IR::BFN::Transition(match_t(8, 0, 0x80), 0, phase0State),
          new IR::BFN::Transition(match_t(8, 0x80, 0x80), 0, resubmitState) });

    // This state handles the extraction of ingress intrinsic metadata.
    const auto igMetadataPacking = Device::pardeSpec().ingressMetadataLayout(igMeta);
    auto* igMetadataState =
      igMetadataPacking.createExtractionState(INGRESS, "$ingress_metadata",
                                              checkResubmitState);

    // This state initializes some special metadata and serves as an entry
    // point.
    auto* alwaysDeparseBit =
        new IR::TempVar(IR::Type::Bits::get(1), true, "$always_deparse");
    auto* globalTimestamp = gen_fieldref(igParserMeta, "ingress_global_tstamp");
    auto* globalVersion = gen_fieldref(igParserMeta, "ingress_global_ver");
    auto* parserErrorCode = gen_fieldref(igParserMeta, "ingress_parser_err");

    parser->start =
      new IR::BFN::ParserState("$entry_point", INGRESS,
        { new IR::BFN::Extract(alwaysDeparseBit, new IR::BFN::ConstantRVal(1)),
          new IR::BFN::Extract(globalTimestamp, new IR::BFN::BufferRVal(StartLen(432, 48))),
          new IR::BFN::Extract(globalVersion, new IR::BFN::BufferRVal(StartLen(480, 32))),
          new IR::BFN::Extract(parserErrorCode, new IR::BFN::ConstantRVal(0)),
        }, { },
        { new IR::BFN::Transition(match_t(), 0, igMetadataState) });
}

void AddMetadataShims::addEgressMetadata(IR::BFN::Parser *parser) {
    auto* egMeta = getMetadataType(pipe, "egress_intrinsic_metadata");
    auto* egParserMeta =
      getMetadataType(pipe, "egress_intrinsic_metadata_from_parser");

    // Add a state that parses bridged metadata. This is just a placeholder;
    // we'll replace it once we know which metadata need to be bridged.
    // XXX(seth): We'll eventually need to handle mirroring and coalescing
    // as well.
    auto* bridgedMetadataState =
        new IR::BFN::ParserState("$bridged_metadata", EGRESS, { }, { }, {
            new IR::BFN::Transition(match_t(), 0, parser->start)
        });

    // This state handles the extraction of egress intrinsic metadata.
    const auto epbConfig = Device::pardeSpec().defaultEPBConfig();
    const auto egMetadataPacking =
      Device::pardeSpec().egressMetadataLayout(epbConfig, egMeta);
    auto* egMetadataState =
      egMetadataPacking.createExtractionState(EGRESS, "$egress_metadata",
                                              bridgedMetadataState);

    // This state initializes some special metadata and serves as an entry
    // point.
    auto* alwaysDeparseBit =
        new IR::TempVar(IR::Type::Bits::get(1), true, "$always_deparse");
    auto* globalTimestamp = gen_fieldref(egParserMeta, "egress_global_tstamp");
    auto* globalVersion = gen_fieldref(egParserMeta, "egress_global_ver");
    auto* parserErrorCode = gen_fieldref(egParserMeta, "egress_parser_err");
    auto* cloneDigestId = gen_fieldref(egParserMeta, "clone_digest_id");
    auto* cloneSource = gen_fieldref(egParserMeta, "clone_src");
    auto* sampleCount = gen_fieldref(egParserMeta, "coalesce_sample_count");
    parser->start =
      new IR::BFN::ParserState("$entry_point", EGRESS,
        { new IR::BFN::Extract(alwaysDeparseBit, new IR::BFN::ConstantRVal(1)),
          new IR::BFN::Extract(globalTimestamp, new IR::BFN::BufferRVal(StartLen(432, 48))),
          new IR::BFN::Extract(globalVersion, new IR::BFN::BufferRVal(StartLen(480, 32))),
          new IR::BFN::Extract(parserErrorCode, new IR::BFN::ConstantRVal(0)),
          new IR::BFN::Extract(cloneDigestId, new IR::BFN::ConstantRVal(0)),
          new IR::BFN::Extract(cloneSource, new IR::BFN::ConstantRVal(0)),
          new IR::BFN::Extract(sampleCount, new IR::BFN::ConstantRVal(0)),
        }, { },
        { new IR::BFN::Transition(match_t(), 0, egMetadataState) });
}

bool AddMetadataShims::preorder(IR::BFN::Deparser *d) {
    switch (d->gress) {
        case INGRESS: addIngressMetadata(d); break;
        case EGRESS:  addEgressMetadata(d);  break;
    }

    return false;
}

namespace {

void addDeparserParam(IR::BFN::Deparser* deparser,
                      const IR::HeaderOrMetadata* meta,
                      cstring field, cstring paramName) {
    if (meta->type->getField(field))
        deparser->metadata[paramName] = new IR::BFN::DeparserIntrinsic(gen_fieldref(meta, field));
}

}  // namespace

void AddMetadataShims::addIngressMetadata(IR::BFN::Deparser *d) {
    auto* tmMeta = getMetadataType(pipe, "ingress_intrinsic_metadata_for_tm");
    addDeparserParam(d, tmMeta, "ucast_egress_port", "egress_unicast_port");
    addDeparserParam(d, tmMeta, "drop_ctl", "drop_ctl");
    addDeparserParam(d, tmMeta, "bypass_egress", "bypss_egr");
    addDeparserParam(d, tmMeta, "deflect_on_drop", "deflect_on_drop");
    addDeparserParam(d, tmMeta, "ingress_cos", "icos");
    addDeparserParam(d, tmMeta, "qid", "qid");
    addDeparserParam(d, tmMeta, "icos_for_copy_to_cpu", "copy_to_cpu_cos");
    addDeparserParam(d, tmMeta, "copy_to_cpu", "copy_to_cpu");
    addDeparserParam(d, tmMeta, "packet_color", "meter_color");
    addDeparserParam(d, tmMeta, "disable_ucast_cutthru", "ct_disable");
    addDeparserParam(d, tmMeta, "enable_mcast_cutthru", "ct_mcast");
    addDeparserParam(d, tmMeta, "mcast_grp_a", "egress_multicast_group_a");
    addDeparserParam(d, tmMeta, "mcast_grp_b", "egress_multicast_group_b");
    addDeparserParam(d, tmMeta, "level1_mcast_hash", "hash_lag_ecmp_mcast_1");
    addDeparserParam(d, tmMeta, "level2_mcast_hash", "hash_lag_ecmp_mcast_2");
    addDeparserParam(d, tmMeta, "level1_exclusion_id", "xid");
    addDeparserParam(d, tmMeta, "level2_exclusion_id", "yid");
    addDeparserParam(d, tmMeta, "rid", "rid");
}

void AddMetadataShims::addEgressMetadata(IR::BFN::Deparser *d) {
    auto* mirrorMeta =
      getMetadataType(pipe, "egress_intrinsic_metadata_for_mirror_buffer");
    addDeparserParam(d, mirrorMeta, "coalesce_length", "coal");

    auto* outputMeta =
      getMetadataType(pipe, "egress_intrinsic_metadata_for_output_port");
    addDeparserParam(d, outputMeta, "capture_tstamp_on_tx", "capture_tx_ts");
    addDeparserParam(d, outputMeta, "update_delay_on_tx", "tx_pkt_has_offsets");
    addDeparserParam(d, outputMeta, "force_tx_error", "force_tx_err");
    addDeparserParam(d, outputMeta, "drop_ctl", "drop_ctl");

    // `egress_unicast_port` and `ecos` are a bit special in that they are made
    // available in the parser as part of `egress_intrinsic_metadata`, but we
    // also need to provide them to the deparser hardware. (The user also can't
    // overwrite these; we prevent that in the architecture by making the
    // intrinsic metadata struct an `in` parameter, so that changes made in the
    // egress control do not propagate to the deparser.)
    auto* egMeta = getMetadataType(pipe, "egress_intrinsic_metadata");
    addDeparserParam(d, egMeta, "egress_port", "egress_unicast_port");
    addDeparserParam(d, egMeta, "egress_cos", "ecos");
}
