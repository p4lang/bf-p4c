#include "bf-p4c/parde/add_parde_metadata.h"
#include "bf-p4c/arch/bridge_metadata.h"
#include "bf-p4c/device.h"
#include "bf-p4c/common/ir_utils.h"
#include "lib/exceptions.h"

bool AddParserMetadata::preorder(IR::BFN::Parser *parser) {
    switch (parser->gress) {
        case INGRESS: addIngressMetadata(parser); break;
        case EGRESS:  addEgressMetadata(parser);  break;
        default: break;  // Nothing for Ghost
    }

    return true;
}

void AddParserMetadata::addIngressMetadata(IR::BFN::Parser *parser) {
    // This state initializes some special metadata and serves as an entry
    // point.
    auto *igParserMeta =
            getMetadataType(pipe, "ingress_intrinsic_metadata_from_parser");
    auto *alwaysDeparseBit =
            new IR::TempVar(IR::Type::Bits::get(1), true, "ingress$always_deparse");
    auto *bridgedMetadataIndicator =
            new IR::TempVar(IR::Type::Bits::get(8), false, BFN::BRIDGED_MD_INDICATOR);
    auto *globalTimestamp = gen_fieldref(igParserMeta, "global_tstamp");
    auto *globalVersion = gen_fieldref(igParserMeta, "global_ver");

    auto prim = new IR::Vector<IR::BFN::ParserPrimitive>();
    if (isV1) {
        prim->push_back(new IR::BFN::Extract(alwaysDeparseBit,
                new IR::BFN::ConstantRVal(1)));
        prim->push_back(new IR::BFN::Extract(bridgedMetadataIndicator,
                new IR::BFN::ConstantRVal(0)));
    }
    if (Device::currentDevice() == Device::TOFINO) {
        prim->push_back(new IR::BFN::Extract(globalTimestamp,
                new IR::BFN::MetadataRVal(StartLen(432, 48))));
        prim->push_back(new IR::BFN::Extract(globalVersion,
                new IR::BFN::MetadataRVal(StartLen(480, 32))));
    } else {
        prim->push_back(new IR::BFN::Extract(globalTimestamp,
                new IR::BFN::MetadataRVal(StartLen(400, 48))));
        prim->push_back(new IR::BFN::Extract(globalVersion,
                new IR::BFN::MetadataRVal(StartLen(448, 32))));
    }

    parser->start =
      new IR::BFN::ParserState(createThreadName(parser->gress, "$entry_point"), parser->gress,
        *prim, { },
        { new IR::BFN::Transition(match_t(), 0, parser->start) });
}

void AddParserMetadata::addEgressMetadata(IR::BFN::Parser *parser) {
    auto* egParserMeta =
      getMetadataType(pipe, "egress_intrinsic_metadata_from_parser");

    auto* alwaysDeparseBit =
        new IR::TempVar(IR::Type::Bits::get(1), true, "egress$always_deparse");
    auto* globalTimestamp = gen_fieldref(egParserMeta, "global_tstamp");
    auto* globalVersion = gen_fieldref(egParserMeta, "global_ver");

    auto prim = new IR::Vector<IR::BFN::ParserPrimitive>();
    if (isV1)
        prim->push_back(new IR::BFN::Extract(alwaysDeparseBit, new IR::BFN::ConstantRVal(1)));

    if (Device::currentDevice() == Device::TOFINO) {
        prim->push_back(new IR::BFN::Extract(globalTimestamp,
                new IR::BFN::MetadataRVal(StartLen(432, 48))));
        prim->push_back(new IR::BFN::Extract(globalVersion,
                new IR::BFN::MetadataRVal(StartLen(480, 32))));
    } else {
        prim->push_back(new IR::BFN::Extract(globalTimestamp,
                new IR::BFN::MetadataRVal(StartLen(400, 48))));
        prim->push_back(new IR::BFN::Extract(globalVersion,
                new IR::BFN::MetadataRVal(StartLen(448, 32))));
    }

    parser->start =
      new IR::BFN::ParserState(createThreadName(parser->gress, "$entry_point"), parser->gress,
        *prim, { },
        { new IR::BFN::Transition(match_t(), 0, parser->start) });
}

bool AddDeparserMetadata::preorder(IR::BFN::Deparser *d) {
    switch (d->gress) {
        case INGRESS: addIngressMetadata(d); break;
        case EGRESS:  addEgressMetadata(d);  break;
        default: break;  // Nothing for Ghost
    }

    return false;
}

namespace {

void addDeparserParamRename(IR::BFN::Deparser* deparser,
                      const IR::HeaderOrMetadata* meta,
                      cstring field, cstring paramName) {
    auto* param =
      new IR::BFN::DeparserParameter(paramName, gen_fieldref(meta, field));

    deparser->params.push_back(param);
}

// Use this method if field name is same as param (assembly) name
// FIXME(zma) move renaming to assembler; having multiple names for
// same thing is never a good idea ...
void addDeparserParam(IR::BFN::Deparser* deparser,
                      const IR::HeaderOrMetadata* meta,
                      cstring field) {
    addDeparserParamRename(deparser, meta, field, field);
}

}  // namespace

void AddDeparserMetadata::addIngressMetadata(IR::BFN::Deparser *d) {
    auto* tmMeta = getMetadataType(pipe, "ingress_intrinsic_metadata_for_tm");
    addDeparserParamRename(d, tmMeta, "ucast_egress_port", "egress_unicast_port");
    addDeparserParamRename(d, tmMeta, "bypass_egress", "bypss_egr");
    addDeparserParam(d, tmMeta, "deflect_on_drop");
    addDeparserParamRename(d, tmMeta, "ingress_cos", "icos");
    addDeparserParam(d, tmMeta, "qid");
    addDeparserParamRename(d, tmMeta, "icos_for_copy_to_cpu", "copy_to_cpu_cos");
    addDeparserParam(d, tmMeta, "copy_to_cpu");
    addDeparserParamRename(d, tmMeta, "packet_color", "meter_color");
    addDeparserParamRename(d, tmMeta, "disable_ucast_cutthru", "ct_disable");
    addDeparserParamRename(d, tmMeta, "enable_mcast_cutthru", "ct_mcast");
    addDeparserParam(d, tmMeta, "mcast_grp_a");
    addDeparserParam(d, tmMeta, "mcast_grp_b");
    addDeparserParam(d, tmMeta, "level1_mcast_hash");
    addDeparserParam(d, tmMeta, "level2_mcast_hash");
    addDeparserParamRename(d, tmMeta, "level1_exclusion_id", "xid");
    addDeparserParamRename(d, tmMeta, "level2_exclusion_id", "yid");
    addDeparserParam(d, tmMeta, "rid");

    auto* dpMeta = getMetadataType(pipe, "ingress_intrinsic_metadata_for_deparser");
    addDeparserParam(d, dpMeta, "drop_ctl");
#if HAVE_JBAY || HAVE_CLOUDBREAK
    if (Device::currentDevice() == Device::JBAY
#if HAVE_CLOUDBREAK
        || Device::currentDevice() == Device::CLOUDBREAK
#endif
    ) {
        addDeparserParamRename(d, dpMeta, "mirror_hash", "mirr_hash");
        addDeparserParamRename(d, dpMeta, "mirror_io_select", "mirr_io_sel");
        addDeparserParamRename(d, dpMeta, "mirror_egress_port", "mirr_epipe_port");
        addDeparserParamRename(d, dpMeta, "mirror_qid", "mirr_qid");
        addDeparserParamRename(d, dpMeta, "mirror_deflect_on_drop", "mirr_dond_ctrl");
        addDeparserParamRename(d, dpMeta, "mirror_ingress_cos", "mirr_icos");
        addDeparserParamRename(d, dpMeta, "mirror_multicast_ctrl", "mirr_mc_ctrl");
        // XXX(TF2LAB-105): disabled due to JBAY-A0 TM BUG
        // addDeparserParamRename(d, dpMeta, "mirror_copy_to_cpu_ctrl", "mirr_c2c_ctrl");
        addDeparserParamRename(d, dpMeta, "adv_flow_ctl", "afc");
        addDeparserParam(d, dpMeta, "mtu_trunc_len");
        addDeparserParam(d, dpMeta, "mtu_trunc_err_f");
        addDeparserParamRename(d, dpMeta, "pktgen", "pgen");
        addDeparserParamRename(d, dpMeta, "pktgen_length", "pgen_len");
        addDeparserParamRename(d, dpMeta, "pktgen_address", "pgen_addr");
        addDeparserParam(d, dpMeta, "learn_sel");
    }
#endif
}

void AddDeparserMetadata::addEgressMetadata(IR::BFN::Deparser *d) {
    auto* outputMeta =
      getMetadataType(pipe, "egress_intrinsic_metadata_for_output_port");
    addDeparserParamRename(d, outputMeta, "capture_tstamp_on_tx", "capture_tx_ts");
    addDeparserParamRename(d, outputMeta, "update_delay_on_tx", "tx_pkt_has_offsets");
    addDeparserParamRename(d, outputMeta, "force_tx_error", "force_tx_err");

    auto* dpMeta = getMetadataType(pipe, "egress_intrinsic_metadata_for_deparser");
    addDeparserParam(d, dpMeta, "drop_ctl");
#if HAVE_JBAY || HAVE_CLOUDBREAK
    if (Device::currentDevice() == Device::JBAY
#if HAVE_CLOUDBREAK
        || Device::currentDevice() == Device::CLOUDBREAK
#endif
    ) {
        addDeparserParamRename(d, dpMeta, "mirror_hash", "mirr_hash");
        addDeparserParamRename(d, dpMeta, "mirror_io_select", "mirr_io_sel");
        addDeparserParamRename(d, dpMeta, "mirror_egress_port", "mirr_epipe_port");
        addDeparserParamRename(d, dpMeta, "mirror_qid", "mirr_qid");
        addDeparserParamRename(d, dpMeta, "mirror_deflect_on_drop", "mirr_dond_ctrl");
        addDeparserParamRename(d, dpMeta, "mirror_ingress_cos", "mirr_icos");
        addDeparserParamRename(d, dpMeta, "mirror_multicast_ctrl", "mirr_mc_ctrl");
        // XXX(TF2LAB-105): disabled due to JBAY-A0 TM BUG
        // addDeparserParamRename(d, dpMeta, "mirror_copy_to_cpu_ctrl", "mirr_c2c_ctrl");
        addDeparserParamRename(d, dpMeta, "adv_flow_ctl", "afc");
        addDeparserParam(d, dpMeta, "mtu_trunc_len");
        addDeparserParam(d, dpMeta, "mtu_trunc_err_f");
    }
#endif
    /* egress_port is how the egress deparser knows where to push
     * the reassembled header and is absolutely necessary
     */
    auto* egMeta = getMetadataType(pipe, "egress_intrinsic_metadata");
    addDeparserParamRename(d, egMeta, "egress_port", "egress_unicast_port");
}
