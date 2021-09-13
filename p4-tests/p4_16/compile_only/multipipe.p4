#include <tna.p4>

#ifndef PIPES
#define PIPES 1
#endif

struct custom_header_t { }

struct custom_metadata_t { }

parser SwitchIngressParser(
        packet_in pkt,
        out custom_header_t hdr,
        out custom_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        transition accept;
    }
}


control SwitchIngress_a(
        inout custom_header_t hdr,
        inout custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    apply { }
}

#if PIPES > 1
control SwitchIngress_b(
        inout custom_header_t hdr,
        inout custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    apply { }
}
#endif  // PIPES > 1

#if PIPES > 2
control SwitchIngress_c(
        inout custom_header_t hdr,
        inout custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    apply { }
}
#endif  // PIPES > 2

#if PIPES > 3
control SwitchIngress_d(
        inout custom_header_t hdr,
        inout custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    apply { }
}
#endif  // PIPES > 3

control SwitchIngressDeparser(
        packet_out pkt,
        inout custom_header_t hdr,
        in custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply { }
}

parser SwitchEgressParser(
        packet_in pkt,
        out custom_header_t hdr,
        out custom_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        transition accept;
    }
}

control SwitchEgressEmpty(
    inout custom_header_t hdr,
    inout custom_metadata_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    apply { }
}

control SwitchEgressDeparser(packet_out pkt,
        inout custom_header_t hdr,
        in custom_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md) {

    apply { }
}

Pipeline(SwitchIngressParser(),
         SwitchIngress_a(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgressEmpty(),
         SwitchEgressDeparser()) pipeline_profile_a;

#if PIPES > 1
Pipeline(SwitchIngressParser(),
         SwitchIngress_b(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgressEmpty(),
         SwitchEgressDeparser()) pipeline_profile_b;
#endif  // PIPES > 1

#if PIPES > 2
Pipeline(SwitchIngressParser(),
         SwitchIngress_c(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgressEmpty(),
         SwitchEgressDeparser()) pipeline_profile_c;
#endif  // PIPES > 2

#if PIPES > 3
Pipeline(SwitchIngressParser(),
         SwitchIngress_d(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgressEmpty(),
         SwitchEgressDeparser()) pipeline_profile_d;
#endif  // PIPES > 3

#if PIPES == 4
Switch(pipeline_profile_a, pipeline_profile_b, pipeline_profile_c,pipeline_profile_d) main;
#elif PIPES == 2
Switch(pipeline_profile_a, pipeline_profile_b) main;
#else
Switch(pipeline_profile_a) main;
#endif
