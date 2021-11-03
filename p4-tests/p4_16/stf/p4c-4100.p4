#include <core.p4>
#include <t2na.p4>

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

header vlan_tag_h {
    bit<3>    pcp;
    bit<1>    cfi;
    vlan_id_t vid;
    bit<16>   ether_type;
}

header mpls_h {
    bit<20> label;
    bit<3>  exp;
    bit<1>  bos;
    bit<8>  ttl;
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

header ipv6_h {
    bit<4>      version;
    bit<8>      traffic_class;
    bit<20>     flow_label;
    bit<16>     payload_len;
    bit<8>      next_hdr;
    bit<8>      hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> hdr_length;
    bit<16> checksum;
}

struct header_t {
    ethernet_h    ethernet;
    vlan_tag_h[2] vlan_tag;
    ipv4_h        ipv4;
    ipv6_h        ipv6;
    tcp_h         tcp;
    udp_h         udp;
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
            ETHERTYPE_VLAN: parse_vlan;
            default: accept;
        }
    }
    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            ETHERTYPE_IPV4: parse_ipv4;
            ETHERTYPE_VLAN: parse_vlan;
            default: accept;
        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }
}

control SwitchIngressDeparser(packet_out pkt, inout header_t hdr, in metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
    }
}

control SwitchIngress(inout header_t hdr, inout metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action add_tag() {
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].ether_type = 0;
        hdr.vlan_tag[0].pcp = 0;
        hdr.vlan_tag[0].vid = 0;
        hdr.vlan_tag[1].setValid();
        hdr.vlan_tag[1].cfi = 0;
        hdr.vlan_tag[1].ether_type = 0;
        hdr.vlan_tag[1].pcp = 0;
        hdr.vlan_tag[1].vid = 0;
    }
    table test {
        actions = {
            add_tag;
        }
        const default_action = add_tag;
    }
    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        test.apply();
    }
}

parser SwitchEgressParser(packet_in pkt, out header_t hdr, out empty_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    TofinoEgressParser() tofino_parser;
    state start {
        tofino_parser.apply(pkt, eg_intr_md);
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

control SwitchEgressDeparser(packet_out pkt, inout header_t hdr, in empty_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {
        pkt.emit(hdr);
    }
}

control SwitchEgress(inout header_t hdr, inout empty_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES, true) direct_counter_teop;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) direct_counter;
    action nop() {
    }
    action hit_src() {
        direct_counter.count();
    }
    table count_src {
        key = {
            hdr.ethernet.src_addr: ternary;
        }
        actions = {
            hit_src;
            @defaultonly nop;
        }
        size = 1024;
        const default_action = nop;
        counters = direct_counter;
    }
    action hit_src_teop() {
        hdr.ipv4.setInvalid();
        hdr.ethernet.ether_type = 0xffff;
        direct_counter_teop.count();
    }
    table count_src_teop {
        key = {
            hdr.ethernet.src_addr: ternary;
        }
        actions = {
            hit_src_teop;
            @defaultonly nop;
        }
        size = 1024;
        const default_action = nop;
        counters = direct_counter_teop;
    }
    apply {
        count_src.apply();
        count_src_teop.apply();
    }
}

Pipeline(SwitchIngressParser(), SwitchIngress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) pipe;

Switch(pipe) main;

