#include <tna.p4>

#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_IPV6 0x86dd

#define IP_PROTOCOLS_ICMP   1
#define IP_PROTOCOLS_IGMP   2
#define IP_PROTOCOLS_TCP    6
#define IP_PROTOCOLS_UDP    17

#define IP_PROTOCOLS_ICMPV6 58

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
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
    bit<16> length;
    bit<16> checksum;
}

header icmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    // ...
}

header igmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    // ...
}

struct metadata {
}

struct headers {
    ethernet_h ethernet;
    ipv4_h ipv4;
    ipv6_h ipv6;
    tcp_h tcp;
    udp_h udp;
    igmp_h igmp;
    icmp_h icmp;
}

header ingress_skip_t {
#if __TARGET_TOFINO__ >= 2
    bit<192> pad;
#else
    bit<64> pad;
#endif
}

parser ParserI(packet_in pkt,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    ingress_skip_t skip;
    bit<8>  protocol;

    state start {
        pkt.extract(ig_intr_md);
        pkt.extract(skip);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        protocol = hdr.ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(hdr.ipv4.ihl, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
            (5, 3w2 &&& 3w5, 0): parse_ipv4_no_options_frags;
            default : accept;
        }
    }

    state parse_ipv4_no_options_frags {
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_ICMP: parse_icmp;
            IP_PROTOCOLS_IGMP: parse_igmp;
            default: parse_l3_protocol;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        protocol = hdr.ipv6.next_hdr;
        transition select(hdr.ipv6.next_hdr) {
            IP_PROTOCOLS_ICMPV6: parse_icmp;
            default: parse_l3_protocol;
        }
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }

    state parse_igmp {
        pkt.extract(hdr.igmp);
        transition accept;
    }

    // shared fanout/branch state to save tcam resource
    state parse_l3_protocol {
        transition select(protocol) {
           IP_PROTOCOLS_UDP: parse_udp;
           IP_PROTOCOLS_TCP: parse_tcp;
           default : accept;
       }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition accept;
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }
}

control IngressP(
        inout headers hdr,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply { }
}

control DeparserI(
        packet_out b,
        inout headers hdr,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        b.emit(hdr.ethernet);
        b.emit(hdr.ipv4);
        b.emit(hdr.ipv6);
        b.emit(hdr.tcp);
        b.emit(hdr.udp);
        b.emit(hdr.icmp);
        b.emit(hdr.igmp);
    }
}

parser ParserE(packet_in b,
               out headers hdr,
               out metadata meta,
               out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;  // XXX can't have empty parser in P4-16
    } 
}

control EgressP(
        inout headers hdr,
        inout metadata meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply { }
}

control DeparserE(packet_out b,
                  inout headers hdr,
                  in metadata meta,
                  in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply { }
}

Pipeline(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;
Switch(pipe0) main;
