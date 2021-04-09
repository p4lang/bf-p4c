/* -*- P4_16 -*- */
#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
const ether_type_t ETHERTYPE_VLAN_INNER = 16w0x9100;
const ether_type_t ETHERTYPE_SVLAN = 16w0x88a8;
const ether_type_t ETHERTYPE_MPLS_UNICAST = 16w0x8847;
const ether_type_t ETHERTYPE_MPLS_MULTICAST = 16w0x8848;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_IGMP = 2;
const ip_protocol_t IP_PROTOCOLS_IPV4 = 4;
const ip_protocol_t IP_PROTOCOLS_IPV6 = 41;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;
const ip_protocol_t IP_PROTOCOLS_OSPF = 89;
const ip_protocol_t IP_PROTOCOLS_GRE = 47;
typedef bit<16> udp_port_type_t;
const udp_port_type_t PORT_GTP = 2152; //GTP-U only
const udp_port_type_t PORT_GTP_v2 = 2132; //GTP-C or v2only (no data)
const udp_port_type_t PORT_GTP_C = 3386;  //GTP' (no data)
/* Ingress mirroring information */
typedef bit<8>  pkt_type_t;
const pkt_type_t PKT_TYPE_NORMAL = 1;
const pkt_type_t PKT_TYPE_MIRROR = 2;
const pkt_type_t PKT_TYPE_CAPTURE = 3;
const pkt_type_t PKT_TYPE_CAPTURE_FINAL = 5;
const pkt_type_t PKT_TYPE_SKIP_EGRESS = 6;

typedef bit<4> port_type_t;
const port_type_t L23_PORT = 2;
const port_type_t L47_PORT = 3;
const port_type_t CAPTURE_PORT = 4;
const port_type_t RESUBMIT_PORT = 5;
const port_type_t FRONTPANEL_PORT = 1;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header ipv4_h {
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

header ip46_h {
   bit<4> version;
   bit<4> reserved;
}

header ipv6_h {
    bit<24> flow_traffic_class;
    //bit<20> flow_label;
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

header tcp_option_h {
    bit<8> no_op;
    bit<8> no_op1;
    bit<16> timestamp_op;
}

header l47_tstamp_h {
    bit<32> l47_tstamp;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> hdr_length;
    bit<16> checksum;
}

header gtpv1_h {
    bit<3>  version;
    bit<1>  protocol_type;
    bit<1>  reserved;
    bit<1>  ext_flag;
    bit<1>  seq_num_flag;
    bit<1>  n_pdu_flag;
    bit<8>  message_type;
    bit<16> message_length;
    bit<32> teid;
}

header gre_h {
    bit<1> checksum_flag;
    bit<12> reserved;
    bit<3> ver;
    bit<16> protocol_type;
}

header grechecksum_h {
    bit<16> checksum;
    bit<16> reserved;
}

header l23signature_h {
    bit<32> signature_top;
    bit<32> signature_bot;
    bit<32> rx_timestamp;
    bit<32> pgid;
    bit<32> sequence;
    bit<32> txtstamp;
}

header skip_l2_h {
    bit<32> skip_l2;
}

header example_bridge_h {
    pkt_type_t pkt_type;

    bit<1> flags_ipv4;
    bit<1> flags_ipv6;
    bit<1> flags_reserved;
    bit<1> flags_gre;
    bit<1> flags_gre_checksum;
    bit<1> flags_tcp;
    bit<1> flags_tcp_option;
    bit<1> flags_udp;

    bit<1> flags_gtp;
    bit<1> flags_inner_v4;
    bit<1> flags_inner_v6;
    bit<1> flags_inner_tcp;
    bit<1> flags_inner_tcp_option;
    bit<1> flags_inner_udp;
    bit<1> flags_l47_tstamp;
    bit<1> flags_first_payload;

    bit<8> l2_offset;

    bit<4> pad;
    bit<1> l47_timestamp_insert;
    bit<1> l23_txtstmp_insert;
    bit<1> l23_rxtstmp_insert;
    bit<1> pad0;

    bit<32> sum_mac_timestamp;
}

header capture_h {
    bit<32> seq_no;
    bit<32> timestamp;
}

struct ingress_metadata_t {
}

 
struct ingress_headers_t {
    example_bridge_h  bridge;
    ethernet_h ethernet;
}

struct egress_headers_t {
    capture_h  capture;
    ethernet_h ethernet;
    skip_l2_h skip_l2;
    ip46_h ip_version;
    ipv4_h ipv4;
    ipv6_h ipv6;
    gre_h gre;
    grechecksum_h gre_checksum;
    tcp_h tcp;
    tcp_option_h tcp_option;
    udp_h udp;
    gtpv1_h gtp1;
    ip46_h  inner_ip_version;
    ipv4_h inner_ipv4;
    ipv6_h inner_ipv6;
    tcp_h inner_tcp;
    tcp_option_h inner_tcp_option;
    udp_h inner_udp;
    l47_tstamp_h l47_tstamp;
    l23signature_h first_payload;
}

struct egress_metadata_t {
    example_bridge_h  bridge;
    pkt_type_t pkt_type;
}

parser IngressParser(packet_in        pkt,
    out ingress_headers_t          hdr,
    out ingress_metadata_t         meta,
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition accept;
    }
}

control Ingress(
    inout ingress_headers_t                       hdr,
    inout ingress_metadata_t                      meta,
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    apply {
        ig_tm_md.ucast_egress_port = 5;

        hdr.bridge.setValid();

        hdr.bridge.pkt_type = 1;

        hdr.bridge.flags_ipv4 = 1;
        hdr.bridge.flags_ipv6 = 0;
        hdr.bridge.flags_gre = 0;
        hdr.bridge.flags_gre_checksum = 0;
        hdr.bridge.flags_tcp = 1;
        hdr.bridge.flags_tcp_option = 0;
        hdr.bridge.flags_udp = 0;

        hdr.bridge.flags_gtp = 0;
        hdr.bridge.flags_inner_v4 = 0;
        hdr.bridge.flags_inner_v6 = 0;
        hdr.bridge.flags_inner_tcp = 0;
        hdr.bridge.flags_inner_tcp_option = 0;
        hdr.bridge.flags_inner_udp = 0;
        hdr.bridge.flags_l47_tstamp = 1;
        hdr.bridge.flags_first_payload = 0;

        hdr.bridge.l2_offset = 2;
    }
}

control IngressDeparser(packet_out pkt,
    inout ingress_headers_t                       hdr,
    in    ingress_metadata_t                      meta,
    in    ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}

parser EgressParser(packet_in        pkt,
    out egress_headers_t          hdr,
    out egress_metadata_t         meta,
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    state start {
        pkt.extract(eg_intr_md);
        transition select(pkt.lookahead<bit<8>>()) {
            8w1       : parse_bridge;
            default   : accept;
        }
    }

    state parse_bridge {
        pkt.extract(meta.bridge);
        pkt.extract(hdr.ethernet);
        transition select(meta.bridge.l2_offset) {
            8w2: parseHeaders;
            8w0: parseFlags;
            default: accept;
        }
    }

    state parseHeaders {
        pkt.extract(hdr.skip_l2);
        transition parseFlags;
    }
    
    state parseFlags {
        transition select(meta.bridge.flags_ipv4, meta.bridge.flags_ipv6,
             meta.bridge.flags_l47_tstamp, meta.bridge.flags_first_payload) {
            (1w1, 1w0, 1w1, 1w0): parseV4;
            (1w1, 1w0, 1w0, 1w1): parseV4;
            (1w0, 1w1, 1w1, 1w0): parseV6;
            (1w0, 1w1, 1w0, 1w1): parseV6;
            (1w0, 1w0, 1w0, 1w1): parseL23;
            default: accept;
        }
    }

    state parseV4 {
        pkt.extract(hdr.ip_version);
        pkt.extract(hdr.ipv4);
        transition select(meta.bridge.flags_gre, meta.bridge.flags_gre_checksum,
             meta.bridge.flags_tcp, meta.bridge.flags_tcp_option,
             meta.bridge.flags_udp, meta.bridge.flags_inner_v6 ) {
            (1w1, 1w1, 1w0, 1w0, 1w0, 1w0 &&& 1w0): parseGreChecksum;
            (1w1, 1w0, 1w0, 1w0, 1w0, 1w0 &&& 1w0): parseGre;
            (1w0, 1w0, 1w1, 1w1, 1w0, 1w0) : parseTcpOption;
            (1w0, 1w0, 1w1, 1w0, 1w0, 1w0) : parseTcp;
            (1w0, 1w0, 1w0, 1w0, 1w1, 1w0) : parseUdp;
            (1w0, 1w0, 1w0, 1w0, 1w0, 1w1) : parseInnerV6;
            (1w0, 1w0, 1w0, 1w0, 1w0, 1w0) : parseL23;
        }
    }

    state parseV6 {
        pkt.extract(hdr.ip_version);
        pkt.extract(hdr.ipv6);
        transition select(meta.bridge.flags_gre, meta.bridge.flags_gre_checksum,
             meta.bridge.flags_tcp, meta.bridge.flags_tcp_option,
             meta.bridge.flags_udp, meta.bridge.flags_inner_v4) {
            (1w1, 1w1, 1w0, 1w0, 1w0, 1w0 &&& 1w0) : parseGreChecksum;
            (1w1, 1w0, 1w0, 1w0, 1w0, 1w0 &&& 1w0) : parseGre;
            (1w0, 1w0, 1w1, 1w1, 1w0, 1w0) : parseTcpOption;
            (1w0, 1w0, 1w1, 1w0, 1w0, 1w0) : parseTcp;
            (1w0, 1w0, 1w0, 1w0, 1w1, 1w0) : parseUdp;
            (1w0, 1w0, 1w0, 1w0, 1w0, 1w1) : parseInnerV4;
            (1w0, 1w0, 1w0, 1w0, 1w0, 1w0) : parseL23;
        }
    }

    state parseGreChecksum {
      pkt.extract(hdr.gre);
      pkt.extract(hdr.gre_checksum);
      transition select(meta.bridge.flags_inner_v4, meta.bridge.flags_inner_v6) {
        (1w1, 1w0) : parseInnerV4;
        (1w0, 1w1) : parseInnerV6;
      }
    }

    state parseGre {
      pkt.extract(hdr.gre);
      transition select(meta.bridge.flags_inner_v4, meta.bridge.flags_inner_v6) {
        (1w1, 1w0) : parseInnerV4;
        (1w0, 1w1) : parseInnerV6;
      }
    }
    
    state parseTcp{
        pkt.extract(hdr.tcp);
        pkt.extract(hdr.first_payload);
        transition accept;
    }

    state parseTcpOption {
        pkt.extract(hdr.tcp_option);
        pkt.extract(hdr.l47_tstamp);
        transition accept;
    }

    state parseL23 {
        pkt.extract(hdr.first_payload);
        transition accept;
    }

    state parseL47tstamp {
        pkt.extract(hdr.l47_tstamp);
        transition accept;
    }

    state parseUdp {
        pkt.extract(hdr.udp);
        transition select(meta.bridge.flags_l47_tstamp, meta.bridge.flags_first_payload) {
            (1w1, 1w0): parseL47tstamp;
            (1w0, 1w1): parseL23;
        }
    }

    state parseGtp {
        pkt.extract(hdr.gtp1);
        transition select(meta.bridge.flags_inner_v4, meta.bridge.flags_inner_v6) {
            (1w1, 1w0): parseInnerV4;
            (1w0, 1w1): parseInnerV6;
        }
    }

    state parseInnerV4 {
        pkt.extract(hdr.inner_ipv4);
        transition select(meta.bridge.flags_inner_tcp, meta.bridge.flags_inner_tcp_option, 
             meta.bridge.flags_inner_udp, meta.bridge.flags_l47_tstamp, meta.bridge.flags_first_payload) {
            (1w1, 1w1, 1w0, 1w1, 1w0): parseInnerTcpOption;
            (1w1, 1w0, 1w0, 1w0, 1w1): parseInnerTcp;
            (1w0, 1w0, 1w1, 1w1, 1w0): parseInnerUdpOption;
            (1w0, 1w0, 1w1, 1w0, 1w1): parseInnerUdp;
        }
    }

    state parseInnerV6 {
        pkt.extract(hdr.inner_ipv6);
        transition select(meta.bridge.flags_inner_tcp, meta.bridge.flags_inner_tcp_option, 
             meta.bridge.flags_inner_udp, meta.bridge.flags_l47_tstamp, meta.bridge.flags_first_payload) {
            (1w1, 1w1, 1w0, 1w1, 1w0): parseInnerTcpOption;
            (1w1, 1w0, 1w0, 1w0, 1w1): parseInnerTcp;
            (1w0, 1w0, 1w1, 1w1, 1w0): parseInnerUdpOption;
            (1w0, 1w0, 1w1, 1w0, 1w1): parseInnerUdp;
        }
    }

    state parseInnerTcpOption {
        pkt.extract(hdr.inner_tcp);
        pkt.extract(hdr.inner_tcp_option);
        pkt.extract(hdr.l47_tstamp);
        transition accept;
    }

    state parseInnerTcp {
        pkt.extract(hdr.inner_tcp);
        pkt.extract(hdr.first_payload);
        transition accept;
    }

    state parseInnerUdp {
        pkt.extract(hdr.inner_udp);
        pkt.extract(hdr.first_payload);
        transition accept;
    }

    state parseInnerUdpOption {
        pkt.extract(hdr.inner_tcp);
        pkt.extract(hdr.l47_tstamp);
        transition accept;
    }
}

control Egress(
    inout egress_headers_t                          hdr,
    inout egress_metadata_t                         meta,
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md)
{
    apply {
        if (hdr.skip_l2.isValid()) {
           hdr.ethernet.ether_type = 16w0x1234;
        } else {
           hdr.ethernet.ether_type = 16w0x0000;
        }
    }
}

control EgressDeparser(packet_out pkt,
    inout egress_headers_t                       hdr,
    in    egress_metadata_t                      meta,
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}

Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;
