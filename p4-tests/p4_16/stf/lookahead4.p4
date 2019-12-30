#include <t2na.p4>

header first_h { bit<8> data; }
header second_h { bit<8> data; }
header lookahead_h { bit<8> data; }

@flexible
struct switch_bridged_metadata_t {
    bit<16> ingress_ifindex;
}

header switch_bridged_metadata_h {
    switch_bridged_metadata_t base;
}

struct switch_port_metadata_t {
    bit<10> port_lag_index;
    bit<16> port_lag_label;
    bit<16> ifindex;
}

struct switch_ingress_metadata_t {
    bit<16> ifindex;
}

struct switch_egress_metadata_t {
}

struct switch_header_t {
    switch_bridged_metadata_h bridged_md;
    first_h first;
    second_h second;
}

parser SwitchIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);

        ig_md.ifindex = port_md.ifindex;
        transition lookahead;
    }
    state lookahead {
        lookahead_h lookahead = pkt.lookahead<lookahead_h>();
        transition select(lookahead.data) {
            0x42: set_ifindex;
            default: parse_first;
        }
    }
    state set_ifindex {
        ig_md.ifindex = 1;
        transition parse_first;
    }
    state parse_first {
        pkt.extract(hdr.first);
        transition select(hdr.first.data) {
            0x81 : parse_second;
            default : accept;
        }
    }
    state parse_second {
     pkt.extract(hdr.second);
     transition accept;
    }
}

control SwitchIngress(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    apply {
        ig_intr_md_for_tm.ucast_egress_port = ig_intr_md.ingress_port;
        hdr.bridged_md.setValid();
        hdr.bridged_md.base.ingress_ifindex = ig_md.ifindex;
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
        pkt.extract<switch_bridged_metadata_h>(_);
        transition accept;
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

control SwitchEgressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
    }
}

Pipeline(
        SwitchIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
        SwitchEgressParser(),
        SwitchEgress(),
        SwitchEgressDeparser()) pipe;

Switch(pipe) main;
