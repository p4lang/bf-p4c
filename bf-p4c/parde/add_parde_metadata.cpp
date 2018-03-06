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

bool AddParserMetadataShims::preorder(IR::BFN::Parser *parser) {
    switch (parser->gress) {
        case INGRESS: addIngressMetadata(parser); break;
        case EGRESS:  addEgressMetadata(parser);  break;
    }

    return false;
}

void AddParserMetadataShims::addIngressMetadata(IR::BFN::Parser *parser) {
    // This state initializes some special metadata and serves as an entry
    // point.
    auto* igParserMeta =
      getMetadataType(pipe, "ingress_intrinsic_metadata_from_parser");
    auto* alwaysDeparseBit =
        new IR::TempVar(IR::Type::Bits::get(1), true, "$always_deparse");
    auto* bridgedMetadataIndicator =
      new IR::TempVar(IR::Type::Bits::get(8), false, "^bridged_metadata_indicator");
    auto* globalTimestamp = gen_fieldref(igParserMeta, "global_tstamp");
    auto* globalVersion = gen_fieldref(igParserMeta, "global_ver");

    parser->start =
      new IR::BFN::ParserState("$entry_point", INGRESS,
        { new IR::BFN::Extract(alwaysDeparseBit, new IR::BFN::ConstantRVal(1)),
          new IR::BFN::Extract(bridgedMetadataIndicator, new IR::BFN::ConstantRVal(0)),
          new IR::BFN::Extract(globalTimestamp, new IR::BFN::BufferRVal(StartLen(432, 48))),
          new IR::BFN::Extract(globalVersion, new IR::BFN::BufferRVal(StartLen(480, 32))),
        }, { },
        { new IR::BFN::Transition(match_t(), 0, parser->start) });
}

void AddParserMetadataShims::addEgressMetadata(IR::BFN::Parser *parser) {
    auto* egParserMeta =
      getMetadataType(pipe, "egress_intrinsic_metadata_from_parser");

    auto* alwaysDeparseBit =
        new IR::TempVar(IR::Type::Bits::get(1), true, "$always_deparse");
    auto* globalTimestamp = gen_fieldref(egParserMeta, "global_tstamp");
    auto* globalVersion = gen_fieldref(egParserMeta, "global_ver");
    parser->start =
      new IR::BFN::ParserState("$entry_point", EGRESS,
        { new IR::BFN::Extract(alwaysDeparseBit, new IR::BFN::ConstantRVal(1)),
          new IR::BFN::Extract(globalTimestamp, new IR::BFN::BufferRVal(StartLen(432, 48))),
          new IR::BFN::Extract(globalVersion, new IR::BFN::BufferRVal(StartLen(480, 32))),
        }, { },
        { new IR::BFN::Transition(match_t(), 0, parser->start) });
}

bool AddDeparserMetadataShims::preorder(IR::BFN::Deparser *d) {
    switch (d->gress) {
        case INGRESS: addIngressMetadata(d); break;
        case EGRESS:  addEgressMetadata(d);  break;
    }

    return false;
}

namespace {

void addDeparserParam(IR::BFN::Deparser* deparser,
                      const IR::HeaderOrMetadata* meta,
                      cstring field, cstring paramName,
                      bool canPack = true) {
    auto* param =
      new IR::BFN::DeparserParameter(paramName, gen_fieldref(meta, field));

    // Packing restrictions arise from Tofino's hidden container validity bits,
    // which control the behavior of certain deparser parameters. If the fields
    // assigned to those parameters are packed with other fields in the same
    // container, then writes to those other fields will affect the container
    // validity bit, which can cause the program to misbehave. Other devices use
    // explicit POV bits for the same purpose, so they don't have this problem,
    // and we can ignore the restriction.
    if (Device::currentDevice() == "Tofino")
        param->canPack = canPack;

    deparser->params.push_back(param);
}

}  // namespace

void AddDeparserMetadataShims::addIngressMetadata(IR::BFN::Deparser *d) {
    auto* tmMeta = getMetadataType(pipe, "ingress_intrinsic_metadata_for_tm");
    addDeparserParam(d, tmMeta, "ucast_egress_port", "egress_unicast_port",
                     /* canPack = */ false);
    addDeparserParam(d, tmMeta, "bypass_egress", "bypss_egr");
    addDeparserParam(d, tmMeta, "deflect_on_drop", "deflect_on_drop");
    addDeparserParam(d, tmMeta, "ingress_cos", "icos");
    addDeparserParam(d, tmMeta, "qid", "qid");
    addDeparserParam(d, tmMeta, "icos_for_copy_to_cpu", "copy_to_cpu_cos");
    addDeparserParam(d, tmMeta, "copy_to_cpu", "copy_to_cpu");

    if (Device::currentDevice() == "Tofino")
        addDeparserParam(d, tmMeta, "packet_color", "meter_color");
#if HAVE_JBAY
    else if (Device::currentDevice() == "JBay")
        addDeparserParam(d, tmMeta, "packet_color", "pkt_color");
#endif

    addDeparserParam(d, tmMeta, "disable_ucast_cutthru", "ct_disable");
    addDeparserParam(d, tmMeta, "enable_mcast_cutthru", "ct_mcast");
    addDeparserParam(d, tmMeta, "mcast_grp_a", "mcast_grp_a", /* canPack = */ false);
    addDeparserParam(d, tmMeta, "mcast_grp_b", "mcast_grp_b", /* canPack = */ false);
    addDeparserParam(d, tmMeta, "level1_mcast_hash", "level1_mcast_hash");
    addDeparserParam(d, tmMeta, "level2_mcast_hash", "level2_mcast_hash");
    addDeparserParam(d, tmMeta, "level1_exclusion_id", "xid");
    addDeparserParam(d, tmMeta, "level2_exclusion_id", "yid");
    addDeparserParam(d, tmMeta, "rid", "rid");

    auto* dpMeta = getMetadataType(pipe, "ingress_intrinsic_metadata_for_deparser");
    addDeparserParam(d, dpMeta, "drop_ctl", "drop_ctl", /* canPack = */ false);
}

void AddDeparserMetadataShims::addEgressMetadata(IR::BFN::Deparser *d) {
    auto* outputMeta =
      getMetadataType(pipe, "egress_intrinsic_metadata_for_output_port");
    addDeparserParam(d, outputMeta, "capture_tstamp_on_tx", "capture_tx_ts");
    addDeparserParam(d, outputMeta, "update_delay_on_tx", "tx_pkt_has_offsets");
    addDeparserParam(d, outputMeta, "force_tx_error", "force_tx_err");

    auto* dpMeta = getMetadataType(pipe, "egress_intrinsic_metadata_for_deparser");
    addDeparserParam(d, dpMeta, "drop_ctl", "drop_ctl", /* canPack = */ false);

    /* egress_port is how the egress deparser knows where to push
     * the reassembled header and is absolutely necessary
     */
    auto* egMeta = getMetadataType(pipe, "egress_intrinsic_metadata");
    addDeparserParam(d, egMeta, "egress_port", "egress_unicast_port");
}
