#include <tna.p4>

enum bit<16> ethertype_t {
    VLAN = 0x8100,
    IPV4 = 0x0800,
    IPV6 = 0x86dd
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

struct metadata {
    bit<16> nexthop;
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
    action fib_hit(ethertype_t ether_type, bit<16> nexthop_index) {
        meta.nexthop = nexthop_index;
        hdr.ethernet.etherType = (bit<16>) ether_type;
    }

    action fib_miss() {}

    table fib {
        key = {
            hdr.ethernet.etherType : exact;
        }

        actions = {
            fib_miss;
            fib_hit;
        }

        const default_action = fib_miss;
        size = 1024;
    }

    apply {
        fib.apply();
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

