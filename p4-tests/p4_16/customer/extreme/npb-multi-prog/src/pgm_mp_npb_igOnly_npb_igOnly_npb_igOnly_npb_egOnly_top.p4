#ifndef _PGM_SP_NPB_IGONLY_NPB_IGONLY_NPB_IGONLY_NPB_EGONLY_TOP_
#define _PGM_SP_NPB_IGONLY_NPB_IGONLY_NPB_IGONLY_NPB_EGONLY_TOP_

#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#define BRIDGED_METADATA_WIDTH          36 // number of bytes in the bridged metadata -- must be set manually -- can change between compiler runs

#define BRIDGED_METADATA_WIDTH_EG        0 // number of bytes in the bridged metadata -- must be set manually -- can change between compiler runs

#include "p4src_includes.p4"



control IngressControlIGOnly(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    IngressControl(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_IGONLY_EGONLY_IGONLY) ic;
    apply {
        ic.apply(hdr, ig_md, ig_intr_md, ig_prsr_md, ig_dprsr_md, ig_tm_md);
    }
}

parser IngressParserIGOnly(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    IngressParser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_IGONLY_EGONLY_IGONLY) ip;
    state start {
        ip.apply(pkt, hdr, ig_md, ig_intr_md);
        transition accept;
    }
}

control IngressDeparserIGOnly(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    IngressDeparser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_IGONLY_EGONLY_IGONLY) id;
    apply {
        id.apply(pkt, hdr, ig_md, ig_dprsr_md);
    }
}

control EgressControlIGOnly(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {

    EgressControl(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_IGONLY_EGONLY_IGONLY) ec;
    apply {
        ec.apply(hdr, eg_md, eg_intr_md, eg_prsr_md, ig_intr_dprs_md, eg_intr_oport_md);
    }
}

parser EgressParserIGOnly(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    EgressParser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_IGONLY_EGONLY_IGONLY) ep;
    state start {
        ep.apply(pkt, hdr, eg_md, eg_intr_md);
        transition accept;
    }
}

control EgressDeparserIGOnly(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_dprs_md) {

    EgressDeparser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_IGONLY_EGONLY_IGONLY) ed;
    apply {
        ed.apply(pkt, hdr, eg_md, eg_dprs_md);
    }
}

Pipeline(
    IngressParser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_IGONLY_EGONLY_EGONLY),
    IngressControl(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_IGONLY_EGONLY_EGONLY),
    IngressDeparser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_IGONLY_EGONLY_EGONLY),
    EgressParser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_IGONLY_EGONLY_EGONLY),
    EgressControl(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_IGONLY_EGONLY_EGONLY),
    EgressDeparser(INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_IGONLY_EGONLY_EGONLY)) pipeline_npb_egOnly;

Pipeline(
    IngressParserIGOnly(),
    IngressControlIGOnly(),
    IngressDeparserIGOnly(),
    EgressParserIGOnly(),
    EgressControlIGOnly(),
    EgressDeparserIGOnly()) pipeline_npb_igOnly_C;

Pipeline(
    IngressParserIGOnly(),
    IngressControlIGOnly(),
    IngressDeparserIGOnly(),
    EgressParserIGOnly(),
    EgressControlIGOnly(),
    EgressDeparserIGOnly()) pipeline_npb_igOnly_B;

Pipeline(
    IngressParserIGOnly(),
    IngressControlIGOnly(),
    IngressDeparserIGOnly(),
    EgressParserIGOnly(),
    EgressControlIGOnly(),
    EgressDeparserIGOnly()) pipeline_npb_igOnly_A;

Switch(
    pipeline_npb_egOnly,
    pipeline_npb_igOnly_C,
    pipeline_npb_igOnly_B,
    pipeline_npb_igOnly_A
) main;

#endif // _PGM_SP_NPB_IGONLY_NPB_IGONLY_NPB_IGONLY_NPB_EGONLY_TOP_
