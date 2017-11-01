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
    auto* meta = getMetadataType(pipe, "ingress_intrinsic_metadata");

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

    // This state handles the extraction of ingress intrinsic metadata.
    const auto igMetadataPacking = Device::pardeSpec().ingressMetadataLayout(meta);
    auto* intrinsicState =
      igMetadataPacking.createExtractionState(INGRESS, "$ingress_metadata", phase0State);

    // On ingress, parsing starts by initializing constants and checking the
    // resubmit flag. If it's not set, we parse the ingress metadata and
    // transition to phase 0. If it is set, we have a resubmitted packet,
    // which we need to handle differently.
    // XXX(seth): For now, we check the resubmit flag but branch to the same
    // place no matter what. We need to figure out what to do here.
    auto* alwaysDeparseBit =
        new IR::TempVar(IR::Type::Bits::get(1), true, "$always_deparse");
    IR::Vector<IR::BFN::ParserPrimitive> init = {
        new IR::BFN::Extract(alwaysDeparseBit, new IR::BFN::ConstantRVal(1))
    };
    auto* toNormal =
      new IR::BFN::Transition(match_t(8, 0, 0x80), 0, intrinsicState);
    auto* toResubmit =
      new IR::BFN::Transition(match_t(8, 0x80, 0x80), 0, intrinsicState);
    parser->start =
      new IR::BFN::ParserState("$entry_point", INGRESS, init,
        { new IR::BFN::Select(new IR::BFN::BufferRVal(StartLen(0, 1))) },
        { toNormal, toResubmit });
}

void AddMetadataShims::addEgressMetadata(IR::BFN::Parser *parser) {
    auto* meta = getMetadataType(pipe, "egress_intrinsic_metadata");

    // Add a state that parses bridged metadata. This is just a placeholder;
    // we'll replace it once we know which metadata need to be bridged.
    // XXX(seth): We'll eventually need to handle mirroring and coalescing
    // as well.
    auto bridgedMetadataState =
        new IR::BFN::ParserState("$bridged_metadata", EGRESS, { }, { }, {
            new IR::BFN::Transition(match_t(), 0, parser->start)
        });

    // This state handles the extraction of egress intrinsic metadata.
    const auto epbConfig = Device::pardeSpec().defaultEPBConfig();
    const auto egMetadataPacking =
      Device::pardeSpec().egressMetadataLayout(epbConfig, meta);
    parser->start =
      egMetadataPacking.createExtractionState(EGRESS, "$egress_metadata_shim",
                                              bridgedMetadataState);
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
    auto *meta = pipe->metadata["ingress_intrinsic_metadata_for_tm"];
    if (!meta) return;

    addDeparserIntrinsic(d, meta, "ucast_egress_port", "egress_unicast_port");
    addDeparserIntrinsic(d, meta, "mcast_grp_a", "egress_multicast_group_a");
    addDeparserIntrinsic(d, meta, "mcast_grp_b", "egress_multicast_group_b");
    addDeparserIntrinsic(d, meta, "rid", "rid");
    addDeparserIntrinsic(d, meta, "level1_exclusion_id", "xid");
    addDeparserIntrinsic(d, meta, "level2_exclusion_id", "yid");
    addDeparserIntrinsic(d, meta, "deflect_on_drop", "deflect_on_drop");
    addDeparserIntrinsic(d, meta, "packet_color", "meter_color");
    addDeparserIntrinsic(d, meta, "ingress_cos", "icos");
    addDeparserIntrinsic(d, meta, "qid", "qid");
    addDeparserIntrinsic(d, meta, "bypass_egress", "bypss_egr");
    addDeparserIntrinsic(d, meta, "enable_mcast_cutthru", "ct_mcast");
}

void AddMetadataShims::addEgressMetadata(IR::BFN::Deparser *d) {
    // egress_port is read-only
    auto *meta = pipe->metadata["egress_intrinsic_metadata"];
    if (!meta) return;
    addDeparserIntrinsic(d, meta, "egress_port", "egress_unicast_port");
    addDeparserIntrinsic(d, meta, "egress_cos", "ecos");
}
