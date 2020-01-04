#include <core.p4>
#if __TARGET_TOFINO__ >= 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

parser TofinoIngressParser(
        packet_in pkt,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }
    state parse_resubmit {
        transition reject;
    }
    state parse_port_metadata {
        pkt.advance(64);
        transition accept;
    }
}
parser TofinoEgressParser(
        packet_in pkt,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}
parser EmptyEgressParser<H, M>(
        packet_in pkt,
        out H hdr,
        out M eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}
control EmptyEgressDeparser<H, M>(
        packet_out pkt,
        inout H hdr,
        in M eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}
control EmptyEgress<H, M>(
        inout H hdr,
        inout M eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;
header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}
header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
    bit<16> ether_type;
}
header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}
header ipv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}
header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}
header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> hdr_lenght;
    bit<16> checksum;
}
struct header_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    ipv6_h ipv6;
    tcp_h tcp;
    udp_h udp;
    ethernet_h inner_ethernet;
    ipv4_h inner_ipv4;
    ipv6_h inner_ipv6;
    tcp_h inner_tcp;
    udp_h inner_udp;
}
parser CommonPacketParser(
    packet_in pkt,
    out ethernet_h ethernet,
    out ipv4_h ipv4,
    out ipv6_h ipv6,
    out udp_h udp,
    out tcp_h tcp) {
    state start {
        pkt.extract(ethernet);
        transition select(ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : reject;
        }
    }
    state parse_ipv4 {
        pkt.extract(ipv4);
        transition select(ipv4.protocol) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            default : accept;
        }
    }
    state parse_ipv6 {
        pkt.extract(ipv6);
        transition select(ipv6.next_hdr) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            default : accept;
        }
    }
    state parse_udp {
        pkt.extract(udp);
        transition accept;
    }
    state parse_tcp {
        pkt.extract(tcp);
        transition accept;
    }
}
struct metadata_t { }
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    TofinoIngressParser() tofino_parser;
    CommonPacketParser() common_packet_parser;
    state start {
        transition parse_common_outer;
    }
    state parse_common_outer {
        common_packet_parser.apply(
            pkt,
            hdr.ethernet,
            hdr.ipv4,
            hdr.ipv6,
            hdr.udp,
            hdr.tcp
        );
        transition end;
    }
    state end {
         transition accept;
     }
}
control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    Checksum() ipv4_checksum;
    apply {
        hdr.ipv4.hdr_checksum = ipv4_checksum.update({
            hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.total_len,
            hdr.ipv4.identification,
            hdr.ipv4.flags,
            hdr.ipv4.frag_offset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.src_addr,
            hdr.ipv4.dst_addr});
         pkt.emit(hdr.ethernet);
    }
}
parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    CommonPacketParser() common_packet_parser;
    state start {
        transition parse_common_outer;
    }
    state parse_common_outer {
        common_packet_parser.apply(
            pkt,
            hdr.ethernet,
            hdr.ipv4,
            hdr.ipv6,
            hdr.udp,
            hdr.tcp
        );
        transition end;
    }
    state end {
         transition accept;
    }
}
control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    bit<16> vrf = (bit<16>)ig_intr_md.ingress_port;
    bit<2> color;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) cntr;
    DirectMeter(MeterType_t.BYTES) meter;
    action hit(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }
    action miss() {
        ig_dprsr_md.drop_ctl = 0x1;
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
    action route(mac_addr_t srcMac, mac_addr_t dstMac, PortId_t dst_port) {
        ig_tm_md.ucast_egress_port = dst_port;
        hdr.ethernet.dst_addr = dstMac;
        hdr.ethernet.src_addr = srcMac;
        cntr.count();
        color = (bit<2>) meter.execute();
        ig_dprsr_md.drop_ctl = 0;
    }
    action nat(ipv4_addr_t srcAddr, ipv4_addr_t dstAddr, PortId_t dst_port) {
        ig_tm_md.ucast_egress_port = dst_port;
        hdr.ipv4.dst_addr = dstAddr;
        hdr.ipv4.src_addr = srcAddr;
        cntr.count();
        color = (bit<2>) meter.execute();
        ig_dprsr_md.drop_ctl = 0;
    }
    table ipRoute {
        key = {
            vrf : exact;
            hdr.ipv4.dst_addr : exact;
        }
        actions = {
            route;
            nat;
        }
        size = 1024;
        counters = cntr;
        meters = meter;
    }
    apply {
        forward.apply();
        vrf = 16w0;
        ipRoute.apply();
        ig_tm_md.bypass_egress = 1w1;
    }
}
Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         EmptyEgress<header_t, metadata_t>(),
         EmptyEgressDeparser<header_t, metadata_t>()) pipe;
Switch(pipe) main;
