#include <tna.p4>

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

struct metadata {
    bit<16> ethType;
}

struct headers {
    ethernet_t ethernet;
}

parser ingressParserImpl(packet_in packet, out headers hdr, out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        packet.extract(hdr.ethernet);
        transition accept;
    }
}

parser egressParserImpl(packet_in packet, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    action set_port(PortId_t port) {
        ig_intr_md_for_tm.ucast_egress_port=port;
    }

    Hash<bit<14>> (HashAlgorithm_t.CRC16)  lag_ecmp_hash;
    ActionProfile(8192) lag_ecmp_af;
    ActionSelector(lag_ecmp_af, lag_ecmp_hash, SelectorMode_t.FAIR, 120, 1) lag_ecmp;
    table nexthop {
        key = {
            hdr.ethernet.etherType: exact;
            hdr.ethernet.srcAddr : selector;
            hdr.ethernet.dstAddr : selector;
        }
        actions = { set_port; }
        size = 1024;
        implementation = lag_ecmp;
    }
    apply {
        nexthop.apply();
    }
}

control ingressDeparserImpl(packet_out packet, inout headers hdr, in metadata meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
    }
}

control egress(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

control egressDeparserImpl(packet_out packet, inout headers hdr, in metadata meta, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
    }
}

Pipeline(ingressParserImpl(), ingress(), ingressDeparserImpl(), egressParserImpl(), egress(), egressDeparserImpl()) pipe;

Switch(pipe) main;

