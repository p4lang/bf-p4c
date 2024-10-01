#include <core.p4>
#include <tna.p4>

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x800;
const ether_type_t ETHERTYPE_ARP = 16w0x806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;
header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16>    ether_type;
}

header ipv4_h {
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffserv;
    bit<16>     total_len;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     frag_offset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header custom_h {
    int<16> fuddled;
}

struct header_t {
    ethernet_h ethernet;
    ipv4_h     ipv4;
    custom_h   custom;
}

struct empty_header_t {
}

struct empty_metadata_t {
}

parser TofinoIngressParser(packet_in pkt, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1: parse_resubmit;
            0: parse_port_metadata;
        }
    }
    state parse_resubmit {
        transition reject;
    }
    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition accept;
    }
}

parser TofinoEgressParser(packet_in pkt, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

control BypassEgress(inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    action set_bypass_egress() {
        ig_tm_md.bypass_egress = 1w1;
    }
    table bypass_egress {
        actions = {
            set_bypass_egress();
        }
        const default_action = set_bypass_egress;
    }
    apply {
        bypass_egress.apply();
    }
}

parser EmptyEgressParser(packet_in pkt, out empty_header_t hdr, out empty_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser(packet_out pkt, inout empty_header_t hdr, in empty_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {
    }
}

control EmptyEgress(inout empty_header_t hdr, inout empty_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

struct metadata_t {
}

parser SwitchIngressParser(packet_in pkt, out header_t hdr, out metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    TofinoIngressParser() tofino_parser;
    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4: parse_ipv4;
            default: reject;
        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }
}

control SwitchIngressDeparser(packet_out pkt, inout header_t hdr, in metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        pkt.emit(hdr);
    }
}

control SwitchIngress(inout header_t hdr, inout metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action hit(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
        hdr.custom.setValid();
        hdr.custom.fuddled = -16s7849;
    }
    action miss() {
        ig_intr_dprsr_md.drop_ctl = 0x1;
    }
    table forward {
        key = {
            hdr.ethernet.dst_addr : exact;
        }
        actions = {
            hit;
            miss;
        }
        const default_action = miss;
        size = 1024;
    }
    apply {
        forward.apply();
        ig_intr_tm_md.bypass_egress = 1w1;
    }
}

Pipeline(SwitchIngressParser(), SwitchIngress(), SwitchIngressDeparser(), EmptyEgressParser(), EmptyEgress(), EmptyEgressDeparser()) pipe;

Switch(pipe) main;

