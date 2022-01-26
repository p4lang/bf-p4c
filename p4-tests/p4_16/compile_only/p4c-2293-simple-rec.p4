// Recursive parsing example

#include <core.p4>
#include <tna.p4>

header hdr_h {
    bit<16> data;
}

struct switch_ingress_metadata_t {
}

struct switch_egress_metadata_t {
}

struct switch_header_t {
    hdr_h hdr0;
    hdr_h hdr1;
    hdr_h hdr2;
}


parser SwitchIngressParser(
    packet_in pkt,
    out switch_header_t hdr,
    out switch_ingress_metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md) {
    
    state start {
        pkt.extract(ig_intr_md);
        transition parse_port_metadata;
    }
    
    state parse_port_metadata {
        pkt.advance(64);
        transition parse_hdr0;
    }

    state parse_hdr0 {
        pkt.extract(hdr.hdr0);
        transition parse_hdr1;
    }

    state parse_hdr1 {
        pkt.extract(hdr.hdr1);
        transition select(hdr.hdr1.data) {
            0       : parse_hdr1; // Recurse, not allowed
            default : parse_hdr2;
        }
    }

    state parse_hdr2 {
        pkt.extract(hdr.hdr2);
        transition accept;
    }

}


control SwitchIngressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr);
    }
}

parser SwitchEgressParser(
    packet_in pkt,
    out switch_header_t hdr,
    out switch_egress_metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        transition accept;
    }
}

control SwitchEgressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr);
    }
}

control SwitchIngress(
    inout switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    Hash<bit<13>>(HashAlgorithm_t.RANDOM) hash;
    
    apply {
    }
}

control SwitchEgress(
    inout switch_header_t hdr,
    inout switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    apply {
    }
}


Pipeline(SwitchIngressParser(),
    SwitchIngress(),
    SwitchIngressDeparser(),
    SwitchEgressParser(),
    SwitchEgress(),
    SwitchEgressDeparser()) pipe;

Switch(pipe) main;
