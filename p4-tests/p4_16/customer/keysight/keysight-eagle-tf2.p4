#include <core.p4>
#include <t2na.p4>

# 1 "headers.p4" 1
# 10 "headers.p4"
typedef bit<13> stats_index_t;

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
const udp_port_type_t PORT_GTP_C = 3386; //GTP' (no data)
/* Ingress mirroring information */
typedef bit<8> pkt_type_t;
const pkt_type_t PKT_TYPE_NORMAL = 1;
const pkt_type_t PKT_TYPE_MIRROR = 2;
const pkt_type_t PKT_TYPE_CAPTURE = 3;
const pkt_type_t PKT_TYPE_BROADCAST = 4;
const pkt_type_t PKT_TYPE_SKIP_EGRESS = 6;


typedef bit<4> port_type_t;
const port_type_t FRONTPANEL_PORT = 1;
const port_type_t L23_PORT = 2;
const port_type_t L47_PORT = 3;
const port_type_t CAPTURE_PORT = 4;





typedef bit<4> mirror_type_t;

const mirror_type_t MIRROR_TYPE_I2E = 1;
const mirror_type_t MIRROR_TYPE_E2E = 2;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header snap_h {
    bit<8> dsap;
    bit<8> ssap;
    bit<8> snap_control;
    bit<24> oui;
    bit<16> ether_type;
}

header vlan_tag_h {
    bit<4> pcp_cfi; //pcp = (3:1) cfi = 0
    bit<4> vlan_top;
    bit<8> vlan_bot;
    bit<16> ether_type;
}

header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

// header mpls_n_h {
//     bit<8> label_top;
//     bit<4> label_bot;
//     bit<3> exp;
//     bit<1> bos;
//     bit<8> ttl;
// }

header mpls_n_h {
    bit<16> mpls_all;
    bit<8> ttl;
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

header l47_tstamp_h {
    bit<32> l47_tstamp;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> hdr_length;
    bit<16> checksum;
}

header icmp_h {
    bit<8> type_;
    bit<8> code;
    bit<16> hdr_checksum;
}

// Address Resolution Protocol -- RFC 6747
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
    // ...
}

// Segment Routing Extension (SRH) -- IETFv7
header ipv6_srh_h {
    bit<8> next_hdr;
    bit<8> hdr_ext_len;
    bit<8> routing_type;
    bit<8> seg_left;
    bit<8> last_entry;
    bit<8> flags;
    bit<16> tag;
}

// VXLAN -- RFC 7348
header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

header gtpv1_h {
    bit<3> version;
    bit<1> protocol_type;
    bit<1> reserved;
    bit<1> ext_flag;
    bit<1> seq_num_flag;
    bit<1> n_pdu_flag;
    bit<8> message_type;
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

header ospf_h {
    bit<8> version;
    bit<8> type;
    bit<16> pkt_length;
    bit<64> dont_care;
    bit<16> checksum;
    bit<16> autype;
    bit<64> authentication;
}

header igmp_v2_h {
    bit<8> type;
    bit<8> max_rsp;
    bit<16> checksum;
    bit<32> group_address;
}

header igmp_v3_extra_h {
    bit<16> dont_care;
    bit<16> num_sources;
}

header l23signature_h {
    bit<32> signature_top;
    bit<32> signature_bot;
    bit<32> rx_timestamp;
}

header l23signature_option_h {
    bit<32> pgid;
    bit<32> sequence;
    bit<32> txtstamp;
}

header skip_l2_1h {
    bit<32> skip_l2;
}
header skip_l2_2h {
    bit<32> skip_l2_one;
    bit<32> skip_l2_two;
}
header skip_l2_3h {
    bit<32> skip_l2_one;
    bit<32> skip_l2_two;
    bit<32> skip_l2_three;
}
header skip_l2_4h {
    bit<32> skip_l2_one;
    bit<32> skip_l2_two;
    bit<32> skip_l2_three;
    bit<32> skip_l2_four;
}
header skip_l2_5h {
    bit<32> skip_l2_one;
    bit<32> skip_l2_two;
    bit<32> skip_l2_three;
    bit<32> skip_l2_four;
    bit<32> skip_l2_five;
}
header skip_l2_6h {
    bit<32> skip_l2_one;
    bit<32> skip_l2_two;
    bit<32> skip_l2_three;
    bit<32> skip_l2_four;
    bit<32> skip_l2_five;
    bit<32> skip_l2_six;
}
header skip_l2_7h {
    bit<32> skip_l2_one;
    bit<32> skip_l2_two;
    bit<32> skip_l2_three;
    bit<32> skip_l2_four;
    bit<32> skip_l2_five;
    bit<32> skip_l2_six;
    bit<32> skip_l2_seven;
}
header skip_l2_8h {
    bit<32> skip_l2_one;
    bit<32> skip_l2_two;
    bit<32> skip_l2_three;
    bit<32> skip_l2_four;
    bit<32> skip_l2_five;
    bit<32> skip_l2_six;
    bit<32> skip_l2_seven;
    bit<32> skip_l2_eight;
}
header skip_l2_9h {
    bit<32> skip_l2_one;
    bit<32> skip_l2_two;
    bit<32> skip_l2_three;
    bit<32> skip_l2_four;
    bit<32> skip_l2_five;
    bit<32> skip_l2_six;
    bit<32> skip_l2_seven;
    bit<32> skip_l2_eight;
    bit<32> skip_l2_nine;
}
/*
 * Ingress metadata, not used but required to use tna.p4
 */

header mirror_h {
   pkt_type_t pkt_type;
  // bit<8> l2_offset;
  // bit<3> flags_l3_protocol;
  // bit<1> flags_l47_tstamp;
  // bit<1> flags_first_payload;
  // bit<3> pad_1;
   bit<1> trigger;
   bit<1> filter;
   bit<6> pad;
   bit<16> capture_seq_no;
   bit<32> mac_timestamp;
}

//@flexible
header example_bridge_h {
    pkt_type_t pkt_type;
    bit<8> l2_offset;
    bit<3> flags_l3_protocol;
    bit<1> flags_l47_tstamp;
    bit<1> flags_first_payload;
    bit<1> l47_timestamp_insert;
    bit<1> l23_txtstmp_insert;
    bit<1> l23_rxtstmp_insert;
    bit<8> ingress_port;
    bit<3> capture_group;
    bit<3> rich_register;
    //bit<1> reserved;
    bit<1> trigger;
    bit<1> filter;
    //bit<7> reserved;
    bit<32> sum_mac_timestamp;
}

header capture_h {
    bit<1> filter;
    bit<1> trigger;
    bit<12> seq_no; //include parity
    bit<4> pad;
    bit<12> seq_no_2;
    bit<2> pad_2;
    bit<32> timestamp;
}

struct port_metadata_t {
    //temporary since we have only 64-bits port metadata for tofino1
    // will be 192 bits in T2
    port_type_t port_type;
    bit<8> capture_group;
}

struct lat_tot_layout {
    bit<32> lo;
    bit<32> hi;
}

struct ingress_metadata_t {
    port_metadata_t port_properties;
    bit<16> src_port;
    bit<16> dst_port;
    bit<3> l47_ob_egressport;
    bit<1> bank_bit;
    bit<4> engine_id;
    bit<32> ipv6_src_127_96;
    bit<32> ipv6_src_95_64;
    bit<32> ipv6_src_63_32;
    bit<32> ip_src_31_0;
    bit<32> ipv6_dst_127_96;
    bit<32> ipv6_dst_95_64;
    bit<32> ipv6_dst_63_32;
    bit<32> ip_dst_31_0;
    bit<4> vid_top;
    bit<8> vid_bot;
    bit<1> map_v6;
    bit<1> map_v4;
    bit<1> pad_2;
    bit<1> stream_bit;
    MirrorId_t mirror_session;
    mirror_h mirror;
    bit<4> ig_stage_count;
    bit<4> eg_stage_count;
}

/*
 * Egress metadata,
 */
struct egress_metadata_t {
    example_bridge_h bridge;
    mirror_h ing_port_mirror;
    pkt_type_t pkt_type;
    MirrorId_t mirror_session;
    mirror_h mirror;
    bit<1> bank_bit;
}

struct header_t {
    example_bridge_h bridge;
    capture_h capture;
    ethernet_h ethernet;
    ip46_h ip_version;
    snap_h snap;
    vlan_tag_h vlan_tag_0;
    vlan_tag_h vlan_tag_1;
    vlan_tag_h vlan_tag_2;
    mpls_h mpls_0;
    ip46_h ip_version_0;
    mpls_n_h mpls_1;
    ip46_h ip_version_1;
    mpls_n_h mpls_2;
    ip46_h ip_version_2;
    mpls_n_h mpls_3;
    ip46_h ip_version_3;
    mpls_n_h mpls_4;
    ip46_h ip_version_4;
    ipv4_h ipv4;
    ipv6_h ipv6;
    gre_h gre;
    grechecksum_h gre_checksum;
    tcp_h tcp;
    udp_h udp;
    gtpv1_h gtp1;
    ip46_h inner_ip_version;
    ipv4_h inner_ipv4;
    ipv6_h inner_ipv6;
    tcp_h inner_tcp;
    udp_h inner_udp;
    l47_tstamp_h l47_tstamp;
    l23signature_h first_payload;
    l23signature_option_h l23_option;
    // Add more headers here.
}

struct eg_header_t {
    example_bridge_h bridge;
    capture_h capture;
    ethernet_h ethernet;
    skip_l2_1h skip_l2_1;
    skip_l2_2h skip_l2_2;
    skip_l2_3h skip_l2_3;
    skip_l2_4h skip_l2_4;
    skip_l2_5h skip_l2_5;
    skip_l2_6h skip_l2_6;
    skip_l2_7h skip_l2_7;
    skip_l2_8h skip_l2_8;
    skip_l2_9h skip_l2_9;
    ip46_h ip_version;
    snap_h snap;
    vlan_tag_h vlan_tag_0;
    vlan_tag_h vlan_tag_1;
    vlan_tag_h vlan_tag_2;
    mpls_h mpls_0;
    ip46_h ip_version_0;
    mpls_n_h mpls_1;
    ip46_h ip_version_1;
    mpls_n_h mpls_2;
    ip46_h ip_version_2;
    mpls_n_h mpls_3;
    ip46_h ip_version_3;
    mpls_n_h mpls_4;
    ip46_h ip_version_4;
    ipv4_h ipv4;
    ipv6_h ipv6;
    gre_h gre;
    grechecksum_h gre_checksum;
    tcp_h tcp;
    udp_h udp;
    gtpv1_h gtp1;
    ip46_h inner_ip_version;
    ipv4_h inner_ipv4;
    ipv6_h inner_ipv6;
    tcp_h inner_tcp;
    udp_h inner_udp;
    l47_tstamp_h l47_tstamp;
    l23signature_h first_payload;
    l23signature_option_h l23_option;
    // Add more headers here.
}

@stage(1)
Register<bit<16>, bit<11>>(2048) ping_reg;
@stage(8)
Register<bit<16>, bit<11>>(2048) ping_egress_reg;
@stage(1)
Register<bit<16>, bit<11>>(2048) pong_reg;
@stage(8)
Register<bit<16>, bit<11>>(2048) pong_egress_reg;
# 15 "eagle.p4" 2
# 1 "packet_parser_ingress.p4" 1
/*!
 * @file packet_parser_ingress.p4
 * @brief  main functions for Eagle switch.
 * @author
 * @date
 */


# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */


# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/tofino2arch.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */
# 15 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 2
# 10 "packet_parser_ingress.p4" 2






parser PacketParserIngress(packet_in pkt,
                    out header_t hdr,
                    out ingress_metadata_t meta,
                    out ingress_intrinsic_metadata_t ig_intr_md) {
    bit<16> payload_length =0;
    state start {
        pkt.extract(ig_intr_md);
        meta.port_properties =
        port_metadata_unpack<port_metadata_t>(pkt);
       // meta.l47_ib_ethertype = 0;
        meta.ipv6_src_127_96 = 0;
        meta.ipv6_src_95_64 = 0;
        meta.ipv6_src_63_32 = 0;
        meta.ip_src_31_0 = 0;
        meta.ipv6_dst_127_96 = 0;
        meta.ipv6_dst_95_64 = 0;
        meta.ipv6_dst_63_32 = 0;
        meta.ip_dst_31_0 = 0;
        meta.src_port = 0;
        meta.dst_port = 0;
        meta.ig_stage_count = 1;
        meta.eg_stage_count = 0;
        // initialize bridge header
        hdr.bridge.setValid();
        hdr.bridge.l47_timestamp_insert = 0;
        hdr.bridge.l23_txtstmp_insert = 0;
        hdr.bridge.l23_rxtstmp_insert = 0;
        hdr.bridge.l2_offset = 0;
        transition select(meta.port_properties.port_type)
        {
            L47_PORT: parseL47Egress;
            default: parseEthernet;
        }
    }

    state parseSkipEgress {
        hdr.bridge.pkt_type = PKT_TYPE_SKIP_EGRESS;
        transition accept;
    }

    state parseL47Egress {
        pkt.extract(hdr.ethernet);
        pkt.extract(hdr.vlan_tag_0);
        meta.l47_ob_egressport = hdr.vlan_tag_0.pcp_cfi[3:1];
        transition select(hdr.vlan_tag_0.vlan_bot, hdr.vlan_tag_0.ether_type) {
            (1 &&& 0x1, 0 &&& 0xf800): parseSnapHeader; /* < 1536 */
            (1 &&& 0x1, ETHERTYPE_VLAN_INNER): parseVlan1;
            (1 &&& 0x1, ETHERTYPE_VLAN): parseVlan1;
            (1 &&& 0x1, ETHERTYPE_SVLAN): parseVlan1;
            (1 &&& 0x1, ETHERTYPE_MPLS_UNICAST): parseMpls;
            (1 &&& 0x1, ETHERTYPE_MPLS_MULTICAST): parseMpls;
            (1 &&& 0x1, ETHERTYPE_IPV4): parseIpv4;
            (1 &&& 0x1, ETHERTYPE_IPV6): parseIpv6;
            (0 &&& 0x1, _): parseSkipEgress;
            default: parseL23;
        }
    }

    state parseEthernet {
        pkt.extract(hdr.ethernet);
        hdr.bridge.pkt_type = PKT_TYPE_NORMAL;
        transition select(hdr.ethernet.ether_type) {
            0 &&& 0xf800: parseSnapHeader; /* < 1536 */
            ETHERTYPE_VLAN: parseVlan;
            ETHERTYPE_SVLAN: parseVlan;
            ETHERTYPE_MPLS_UNICAST: parseMpls;
            ETHERTYPE_MPLS_MULTICAST: parseMpls;
            ETHERTYPE_IPV4: parseIpv4;
            ETHERTYPE_IPV6: parseIpv6;
            default: parseL23;
        }
    }

    state parseSnapHeader {
        pkt.extract(hdr.snap);
        transition select(hdr.snap.ether_type) {
            ETHERTYPE_MPLS_UNICAST: parseMpls;
            ETHERTYPE_MPLS_MULTICAST: parseMpls;
            ETHERTYPE_IPV4: parseIpv4;
            ETHERTYPE_IPV6: parseIpv6;
            default: parseL23;
        }
    }

    state parseVlan {
        pkt.extract(hdr.vlan_tag_0);
        transition select(hdr.vlan_tag_0.ether_type) {
            0 &&& 0xf800: parseSnapHeader; /* < 1536 */
            ETHERTYPE_VLAN_INNER: parseVlan1;
            ETHERTYPE_VLAN: parseVlan1;
            ETHERTYPE_SVLAN: parseVlan1;
            ETHERTYPE_MPLS_UNICAST: parseMpls;
            ETHERTYPE_MPLS_MULTICAST: parseMpls;
            ETHERTYPE_IPV4: parseIpv4;
            ETHERTYPE_IPV6: parseIpv6;
            default: parseL23;
        }
    }

    state parseVlan1 {
        pkt.extract(hdr.vlan_tag_1);
        transition select(hdr.vlan_tag_1.ether_type) {
            0 &&& 0xf800: parseSnapHeader; /* < 1536 */
            ETHERTYPE_VLAN_INNER: parseVlan2;
            ETHERTYPE_VLAN: parseVlan2;
            ETHERTYPE_SVLAN: parseVlan2;
            ETHERTYPE_MPLS_UNICAST: parseMpls;
            ETHERTYPE_MPLS_MULTICAST: parseMpls;
            ETHERTYPE_IPV4: parseIpv4;
            ETHERTYPE_IPV6: parseIpv6;
            default: parseL23;
        }
    }
    //last vlan, accept anything that is not decoded
    state parseVlan2 {
        pkt.extract(hdr.vlan_tag_2);
        transition select(hdr.vlan_tag_2.ether_type) {
            0 &&& 0xf800: parseSnapHeader; /* < 1536 */
            ETHERTYPE_MPLS_UNICAST: parseMpls;
            ETHERTYPE_MPLS_MULTICAST: parseMpls;
            ETHERTYPE_IPV4: parseIpv4;
            ETHERTYPE_IPV6: parseIpv6;
            default: parseL23;
        }
    }

    state parseMpls {
        pkt.extract(hdr.mpls_0);
        pkt.extract(hdr.ip_version_0);
        transition select(hdr.mpls_0.bos, hdr.ip_version_0.version) {
          (1w0x1, 4w0x4): parseMplsIpv4;
          (1w0x1, 4w0x6): parseMplsIpv6;
          (1w0x0, 4w0x0 &&& 4w0x0): parseMpls1;
          default: parseL23;
        }
    }

    state parseMpls1 {
        pkt.extract(hdr.mpls_1);
        pkt.extract(hdr.ip_version_1);
        transition select(hdr.mpls_1.mpls_all, hdr.ip_version_1.version) {
            (16w0x1 &&& 16w0x1, 4w0x4): parseMplsIpv4;
            (16w0x1 &&& 16w0x1, 4w0x6): parseMplsIpv6;
            (16w0x0 &&& 16w0x1, 4w0x0 &&& 4w0x0): parseMpls2;
            default: parseL23;
        }
    }

    state parseMpls2 {
        pkt.extract(hdr.mpls_2);
        pkt.extract(hdr.ip_version_2);
        transition select(hdr.mpls_2.mpls_all, hdr.ip_version_2.version) {
          (16w0x1 &&& 16w0x1, 4w0x4): parseMplsIpv4;
          (16w0x1 &&& 16w0x1, 4w0x6): parseMplsIpv6;
          (16w0x0 &&& 16w0x1, 4w0x0 &&& 4w0x0): parseMpls3;
          default: parseL23;
        }
    }

    state parseMpls3 {
        pkt.extract(hdr.mpls_3);
        pkt.extract(hdr.ip_version_3);
        transition select(hdr.mpls_3.mpls_all, hdr.ip_version_3.version) {
            (16w0x1 &&& 16w0x1, 4w0x4): parseMplsIpv4;
            (16w0x1 &&& 16w0x1, 4w0x6): parseMplsIpv6;
            (16w0x0 &&& 16w0x1, 4w0x0 &&& 4w0x0): parseMpls4;
            default: parseL23;
        }
    }

    state parseMpls4 {
        pkt.extract(hdr.mpls_4);
        pkt.extract(hdr.ip_version_4);
        transition select(hdr.mpls_4.mpls_all, hdr.ip_version_4.version) {
            (16w0x1 &&& 16w0x1, 4w0x4): parseMplsIpv4;
            (16w0x1 &&& 16w0x1, 4w0x6): parseMplsIpv6;
            default: parseL23;
        }
    }


    state parseMplsIpv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol, hdr.ipv4.total_len) {
            (IP_PROTOCOLS_GRE, 16w0x0 &&& 16w0x0): parseGre;
            (IP_PROTOCOLS_IPV6, 16w0x0 &&& 16w0x0): parseInnerIpv6;
            (IP_PROTOCOLS_TCP, 16w0x80 &&& 16w0x80): parseTcp;
            (IP_PROTOCOLS_TCP, 16w0x40 &&& 16w0x40): parseTcp;
            // ok to parse tcp +test payload
            (IP_PROTOCOLS_TCP, 16w0x38 &&& 16w0x38): parseTcpOpt;
            (IP_PROTOCOLS_TCP, 16w0x34 &&& 16w0x34): parseTcpOpt;
            (IP_PROTOCOLS_TCP, 16w0x30 &&& 16w0x30): parseTcpOnly;
            (IP_PROTOCOLS_TCP, 16w0x28 &&& 16w0x28): parseTcpOnly;

            (IP_PROTOCOLS_UDP, 16w0x80 &&& 16w0x80): parseUdp;
            (IP_PROTOCOLS_UDP, 16w0x40 &&& 16w0x40): parseUdp;
            (IP_PROTOCOLS_UDP, 16w0x28 &&& 16w0x28): parseUdp;
            // ok to parse UDP + timestamp but not test payload
            (IP_PROTOCOLS_UDP, 16w0x20 &&& 16w0x20): parseUdpOpt;
            (IP_PROTOCOLS_UDP, 16w0x1C &&& 16w0x1C): parseUdpOnly;
            (8w0x0 &&& 8w0x0, 16w0x80 &&& 16w0x80): parseL23;
            (8w0x0 &&& 8w0x0, 16w0x40 &&& 16w0x40): parseL23;
            (8w0x0 &&& 8w0x0, 16w0x2C &&& 16w0x2C): parseL23;
            default: furtherDecode;
        }
    }

    state parseTcpOpt {
        pkt.extract(hdr.tcp);
        pkt.extract(hdr.first_payload);
        transition accept;
    }

    state parseTcpOnly {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parseUdpOpt {
        pkt.extract(hdr.udp);
        pkt.extract(hdr.l47_tstamp);
        transition accept;
    }

    state parseUdpOnly {
        pkt.extract(hdr.udp);
        transition accept;
    }

    state furtherDecode {
        transition select(hdr.ipv4.protocol, hdr.ipv4.total_len) {
            (8w0x0 &&& 8w0x0,16w0x2000 &&& 16w0x2000): finalAccept;
            (8w0x0 &&& 8w0x0,16w0x1000 &&& 16w0x1000): finalAccept;
            (8w0x0 &&& 8w0x0,16w0x800 &&& 16w0x800): finalAccept;
            (8w0x0 &&& 8w0x0,16w0x400 &&& 16w0x400): finalAccept;
            (8w0x0 &&& 8w0x0,16w0x200 &&& 16w0x200): finalAccept;
            (8w0x0 &&& 8w0x0,16w0x100 &&& 16w0x100): finalAccept;
            default: accept;
        }
    }

    state furtherDecodev6 {
        transition select(hdr.ipv6.next_hdr, hdr.ipv6.payload_len) {
            //v6 payload 0 len = jumbo
            (8w0x0 &&& 8w0x0, 0): finalAcceptv6;
            (8w0x0 &&& 8w0x0, 16w0x2000 &&& 16w0x2000): finalAcceptv6;
            (8w0x0 &&& 8w0x0, 16w0x1000 &&& 16w0x1000): finalAcceptv6;
            (8w0x0 &&& 8w0x0, 16w0x800 &&& 16w0x800): finalAcceptv6;
            (8w0x0 &&& 8w0x0, 16w0x400 &&& 16w0x400): finalAcceptv6;
            (8w0x0 &&& 8w0x0, 16w0x200 &&& 16w0x200): finalAcceptv6;
            (8w0x0 &&& 8w0x0, 16w0x100 &&& 16w0x100): finalAcceptv6;
            (8w0x0 &&& 8w0x0, 16w0x80 &&& 16w0x80): finalAcceptv6;
            default: accept;
        }
    }

    state finalAccept {
        transition select(hdr.ipv4.protocol) {
            (IP_PROTOCOLS_TCP): parseTcp;
            (IP_PROTOCOLS_UDP): parseUdp;
            default : parseL23;
        }
    }

    state finalAcceptv6 {
        transition select(hdr.ipv6.next_hdr) {
            (IP_PROTOCOLS_TCP): parseTcp;
            (IP_PROTOCOLS_UDP): parseUdp;
            default : parseL23;
        }
    }

    state parseMplsIpv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr, hdr.ipv6.payload_len) {
            (IP_PROTOCOLS_GRE, 16w0x0 &&& 16w0x0): parseGre;
            (IP_PROTOCOLS_IPV4, 16w0x0 &&& 16w0x0): parseInnerIpv4;
            (IP_PROTOCOLS_TCP, 16w0x40 &&& 16w0x40) : parseTcp;
            (IP_PROTOCOLS_TCP, 16w0x2C &&& 16w0x2C) : parseTcp;
            (IP_PROTOCOLS_TCP, 16w0x20 &&& 16w0x20) : parseTcpOpt;
            (IP_PROTOCOLS_TCP, 16w0x10 &&& 16w0x10) : parseTcpOnly;
            (IP_PROTOCOLS_UDP, 16w0x40 &&& 16w0x40) : parseUdp;
            (IP_PROTOCOLS_UDP, 16w0x20 &&& 16w0x20) : parseUdp;
            (IP_PROTOCOLS_UDP, 16w0x14 &&& 16w0x14) : parseUdp;
            (IP_PROTOCOLS_UDP, 16w0x10 &&& 16w0x10) : parseUdpOpt;
            (IP_PROTOCOLS_UDP, 16w0xC &&& 16w0xC) : parseUdpOpt;
            (IP_PROTOCOLS_UDP, 16w0x8 &&& 16w0x8) : parseUdpOnly;
            (8w0x0 &&& 8w0x0, 16w0x40 &&& 16w0x40) : parseL23;
            (8w0x0 &&& 8w0x0, 16w0x20 &&& 16w0x20) : parseL23;
            (8w0x0 &&& 8w0x0, 16w0x18 &&& 16w0x18) : parseL23;
            default: furtherDecodev6;
        }
    }

    state parseIpv4 {
        pkt.extract(hdr.ip_version_4);
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol, hdr.ipv4.total_len) {
            (IP_PROTOCOLS_GRE, 16w0x0 &&& 16w0x0): parseGre;
            (IP_PROTOCOLS_IPV6, 16w0x0 &&& 16w0x0): parseInnerIpv6;
            (IP_PROTOCOLS_TCP, 16w0x80 &&& 16w0x80): parseTcp;
            (IP_PROTOCOLS_TCP, 16w0x40 &&& 16w0x40): parseTcp;
            // ok to parse tcp +test payload
            (IP_PROTOCOLS_TCP, 16w0x38 &&& 16w0x38): parseTcpOpt;
            (IP_PROTOCOLS_TCP, 16w0x34 &&& 16w0x34): parseTcpOpt;
            (IP_PROTOCOLS_TCP, 16w0x30 &&& 16w0x30): parseTcpOnly;
            (IP_PROTOCOLS_TCP, 16w0x28 &&& 16w0x28): parseTcpOnly;

            (IP_PROTOCOLS_UDP, 16w0x80 &&& 16w0x80): parseUdp;
            (IP_PROTOCOLS_UDP, 16w0x40 &&& 16w0x40): parseUdp;
            (IP_PROTOCOLS_UDP, 16w0x28 &&& 16w0x28): parseUdp;
            // ok to parse UDP + timestamp but not test payload
            (IP_PROTOCOLS_UDP, 16w0x20 &&& 16w0x20): parseUdpOpt;
            (IP_PROTOCOLS_UDP, 16w0x1C &&& 16w0x1C): parseUdpOnly;
            (8w0x0 &&& 8w0x0, 16w0x80 &&& 16w0x80): parseL23;
            (8w0x0 &&& 8w0x0, 16w0x40 &&& 16w0x40): parseL23;
            (8w0x0 &&& 8w0x0, 16w0x2C &&& 16w0x2C): parseL23;
            default: furtherDecode;
        }
    }

    state parseIpv6 {
        pkt.extract(hdr.ip_version_4);
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr, hdr.ipv6.payload_len) {
            (IP_PROTOCOLS_GRE, 16w0x0 &&& 16w0x0): parseGre;
            (IP_PROTOCOLS_IPV4, 16w0x0 &&& 16w0x0): parseInnerIpv4;
            //payload length = 0, jumbo frames (special)
          (IP_PROTOCOLS_TCP, 16w0x40 &&& 16w0x40) : parseTcp;
            (IP_PROTOCOLS_TCP, 16w0x2C &&& 16w0x2C) : parseTcp;
            (IP_PROTOCOLS_TCP, 16w0x20 &&& 16w0x20) : parseTcpOpt;
            (IP_PROTOCOLS_TCP, 16w0x18 &&& 16w0x10) : parseTcpOnly;
            (IP_PROTOCOLS_UDP, 16w0x40 &&& 16w0x40) : parseUdp;
            (IP_PROTOCOLS_UDP, 16w0x20 &&& 16w0x20) : parseUdp;
            (IP_PROTOCOLS_UDP, 16w0x18 &&& 16w0x18) : parseUdp;
            (IP_PROTOCOLS_UDP, 16w0x14 &&& 16w0x14) : parseUdp;
            (IP_PROTOCOLS_UDP, 16w0x10 &&& 16w0x10) : parseUdpOpt;
            (IP_PROTOCOLS_UDP, 16w0xC &&& 16w0xC) : parseUdpOpt;
            (IP_PROTOCOLS_UDP, 16w0x8 &&& 16w0x8) : parseUdpOnly;
            (8w0x0 &&& 8w0x0, 16w0x40 &&& 16w0x40) : parseL23;
            (8w0x0 &&& 8w0x0, 16w0x20 &&& 16w0x20) : parseL23;
            (8w0x0 &&& 8w0x0, 16w0x18 &&& 16w0x18) : parseL23;
            default: furtherDecodev6;
        }
    }

    state parseTcp {
        pkt.extract(hdr.tcp);
        pkt.extract(hdr.first_payload);
    }

    state parseUdp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            PORT_GTP: parseGtpv1;
            PORT_GTP_v2: parseGtpC;
            PORT_GTP_C: parseGtpC;
            default: parseL23;
        }
    }

    state parseGtpv1{
        pkt.extract(hdr.gtp1);
        transition select(pkt.lookahead<ip46_h>().version) {
            4w0x4: parseInnerIpv4;
            4w0x6: parseInnerIpv6;
            default: accept;
        }
    }

    state parseGtpC{
        pkt.extract(hdr.gtp1);
        transition accept;
    }

    state parseGre {
        pkt.extract(hdr.gre);
        transition select(hdr.gre.checksum_flag, hdr.gre.protocol_type) {
            (1w0x1, ETHERTYPE_IPV4): parseGrechecksumIpv4;
            (1w0x1, ETHERTYPE_IPV6): parseGrechecksumIpv6;
            (1w0x0, ETHERTYPE_IPV4): parseInnerIpv4;
            (1w0x0, ETHERTYPE_IPV6): parseInnerIpv6;
            default: accept;
        }
    }

    state parseGrechecksumIpv6 {
        pkt.extract(hdr.gre_checksum);
        pkt.extract(hdr.inner_ip_version);
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr) {
            IP_PROTOCOLS_TCP: parseInnerTcp;
            IP_PROTOCOLS_UDP: parseInnerUdp;
            default: parseL23;
        }
    }

    state parseInnerTcpOpt {
        pkt.extract(hdr.inner_tcp);
        pkt.extract(hdr.first_payload);
        transition accept;
    }

    state parseInnerTcpOnly {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parseInnerUdpOpt {
        pkt.extract(hdr.inner_udp);
        pkt.extract(hdr.l47_tstamp);
        transition accept;
    }

    state parseInnerUdpOnly {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }

    state finalInnerAccept {
        transition select(hdr.inner_ipv4.protocol) {
            (IP_PROTOCOLS_TCP): parseInnerTcp;
            (IP_PROTOCOLS_UDP): parseInnerUdp;
            default : parseL23;
        }
    }

    state parseInnerv4Length {
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.total_len) {
            // for particular inner decode
            (8w0x0 &&& 8w0x0, 16w0x2000 &&& 16w0x2000): finalInnerAccept;
            (8w0x0 &&& 8w0x0, 16w0x1000 &&& 16w0x1000): finalInnerAccept;
            (8w0x0 &&& 8w0x0, 16w0x800 &&& 16w0x800): finalInnerAccept;
            (8w0x0 &&& 8w0x0, 16w0x400 &&& 16w0x400): finalInnerAccept;
            (8w0x0 &&& 8w0x0, 16w0x200 &&& 16w0x200): finalInnerAccept;
            (8w0x0 &&& 8w0x0, 16w0x100 &&& 16w0x100): finalInnerAccept;
            (8w0x0 &&& 8w0x0, 16w0x80 &&& 16w0x80): finalInnerAccept;
            (8w0x0 &&& 8w0x0, 16w0x40 &&& 16w0x40): finalInnerAccept;
            (IP_PROTOCOLS_TCP, 16w0x38 &&& 16w0x38): parseInnerTcpOpt;
            (IP_PROTOCOLS_TCP, 16w0x34 &&& 16w0x34): parseInnerTcpOpt;
            (IP_PROTOCOLS_TCP, 16w0x30 &&& 16w0x30): parseInnerTcpOnly;
            (IP_PROTOCOLS_TCP, 16w0x28 &&& 16w0x28): parseInnerTcpOnly;
            (IP_PROTOCOLS_UDP, 16w0x28 &&& 16w0x28): parseInnerUdp;
            (IP_PROTOCOLS_UDP, 16w0x20 &&& 16w0x20): parseInnerUdpOpt;
            (IP_PROTOCOLS_UDP, 16w0x1C &&& 16w0x1C): parseInnerUdpOnly;
            default: accept;
        }
    }

    state finalInnerAcceptv6 {
        transition select(hdr.inner_ipv6.next_hdr) {
            (IP_PROTOCOLS_TCP): parseInnerTcp;
            (IP_PROTOCOLS_UDP): parseInnerUdp;
            default : parseL23;
        }
    }

    state parseInnerv6Length {
        transition select(hdr.inner_ipv6.next_hdr, hdr.inner_ipv6.payload_len) {
            // for particular inner decode
            (8w0x0 &&& 8w0x0, 16w0x2000 &&& 16w0x2000): finalInnerAcceptv6;
            (8w0x0 &&& 8w0x0, 16w0x1000 &&& 16w0x1000): finalInnerAcceptv6;
            (8w0x0 &&& 8w0x0, 16w0x800 &&& 16w0x800): finalInnerAcceptv6;
            (8w0x0 &&& 8w0x0, 16w0x400 &&& 16w0x400): finalInnerAcceptv6;
            (8w0x0 &&& 8w0x0, 16w0x200 &&& 16w0x200): finalInnerAcceptv6;
            (8w0x0 &&& 8w0x0, 16w0x100 &&& 16w0x100): finalInnerAcceptv6;
            (8w0x0 &&& 8w0x0, 16w0x80 &&& 16w0x80): finalInnerAcceptv6;
            (8w0x0 &&& 8w0x0, 16w0x40 &&& 16w0x40): finalInnerAcceptv6;
            (8w0x0 &&& 8w0x0, 16w0x20 &&& 16w0x20): finalInnerAcceptv6;
            (IP_PROTOCOLS_TCP, 16w0x20 &&& 16w0x20): parseInnerTcpOpt;
            (IP_PROTOCOLS_TCP, 16w0x18 &&& 16w0x10): parseInnerTcpOnly;
            (IP_PROTOCOLS_UDP, 16w0x14 &&& 16w0x14): parseInnerUdp;
            (IP_PROTOCOLS_UDP, 16w0x10 &&& 16w0x10): parseInnerUdpOpt;
            (IP_PROTOCOLS_UDP, 16w0xC &&& 16w0xC): parseInnerUdpOpt;
            (IP_PROTOCOLS_UDP, 16w0x8 &&& 16w0x8): parseInnerUdpOnly;

            default: accept;
        }
    }

    state parseGrechecksumIpv4 {
        pkt.extract(hdr.gre_checksum);
        pkt.extract(hdr.inner_ip_version);
        pkt.extract(hdr.inner_ipv4);
        transition parseInnerv4Length;
    }

    state parseInnerIpv4 {
        pkt.extract(hdr.inner_ip_version);
        pkt.extract(hdr.inner_ipv4);
        transition parseInnerv4Length;
    }

    state parseInnerIpv6 {
        pkt.extract(hdr.inner_ip_version);
        pkt.extract(hdr.inner_ipv6);
        transition parseInnerv6Length;
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

    state parseL23 {
        pkt.extract(hdr.first_payload);
        transition accept;
    }
}
# 16 "eagle.p4" 2
# 1 "packet_parser_egress.p4" 1
/*!
 * @file packet_parser_egress.p4
 * @brief  main functions for Eagle switch.
 * @author
 * @date
 */


# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */


# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/tofino2arch.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */
# 15 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 2
# 10 "packet_parser_egress.p4" 2






parser PacketParserEgress(packet_in pkt,
                    inout eg_header_t hdr, inout egress_metadata_t eg_md ) {
    state start {
        transition parse_headers;
    }

    state parse_headers {
        pkt.extract(hdr.ethernet);
        transition select(eg_md.bridge.l2_offset) {
            (20): parseIpv4;
            (21): parseHeaders1;
            (22): parseHeaders2;
            (23): parseHeaders3;
            (24): parseHeaders4;
            (25): parseHeaders5;
            (26): parseHeaders6;
            (27): parseHeaders7;
            (28): parseHeaders8;
            (29): parseHeaders9;
            (40): parseIpv6;
            (41): parseHeaders1v6;
            (42): parseHeaders2v6;
            (43): parseHeaders3v6;
            (44): parseHeaders4v6;
            (45): parseHeaders5v6;
            (46): parseHeaders6v6;
            (47): parseHeaders7v6;
            (48): parseHeaders8v6;
            (49): parseHeaders9v6;
            default: accept;
        }
    }

    state parseHeaders1 {
        pkt.extract(hdr.skip_l2_1);
        transition parseIpv4;
    }

    state parseHeaders2 {
        pkt.extract(hdr.skip_l2_2);
        transition parseIpv4;
    }

    state parseHeaders3 {
        pkt.extract(hdr.skip_l2_3);
        transition parseIpv4;
    }

    state parseHeaders4 {
        pkt.extract(hdr.skip_l2_4);
        transition parseIpv4;
    }

    state parseHeaders5 {
        pkt.extract(hdr.skip_l2_5);
        transition parseIpv4;
    }

    state parseHeaders6 {
        pkt.extract(hdr.skip_l2_6);
        transition parseIpv4;
    }

    state parseHeaders7 {
        pkt.extract(hdr.skip_l2_7);
        transition parseIpv4;
    }

    state parseHeaders8 {
        pkt.extract(hdr.skip_l2_8);
        transition parseIpv4;
    }

    state parseHeaders9 {
        pkt.extract(hdr.skip_l2_9);
        transition parseIpv4;
    }

    state parseHeaders1v6 {
        pkt.extract(hdr.skip_l2_1);
        transition parseIpv6;
    }

    state parseHeaders2v6 {
        pkt.extract(hdr.skip_l2_2);
        transition parseIpv6;
    }

    state parseHeaders3v6 {
        pkt.extract(hdr.skip_l2_3);
        transition parseIpv6;
    }

    state parseHeaders4v6 {
        pkt.extract(hdr.skip_l2_4);
        transition parseIpv6;
    }

    state parseHeaders5v6 {
        pkt.extract(hdr.skip_l2_5);
        transition parseIpv6;
    }

    state parseHeaders6v6 {
        pkt.extract(hdr.skip_l2_6);
        transition parseIpv6;
    }

    state parseHeaders7v6 {
        pkt.extract(hdr.skip_l2_7);
        transition parseIpv6;
    }

    state parseHeaders8v6 {
        pkt.extract(hdr.skip_l2_8);
        transition parseIpv6;
    }

    state parseHeaders9v6 {
        pkt.extract(hdr.skip_l2_9);
        transition parseIpv6;
    }


    state parseIpv4 {
        pkt.extract(hdr.ip_version);
        pkt.extract(hdr.ipv4);
        transition select(eg_md.bridge.flags_l3_protocol) {
            1: parseUdp;
            2: parseTcp;
            3: parseGre;
            4: parseGtp;
            6: parseInnerIpv6;
            default: parseL23;
        }
    }

    state parseIpv6 {
        pkt.extract(hdr.ip_version);
        pkt.extract(hdr.ipv6);
        transition select(eg_md.bridge.flags_l3_protocol) {
            1: parseUdp;
            2: parseTcp;
            3: parseGre;
            4: parseGtp;
            5: parseInnerIpv4;
            default: parseL23;
        }
    }

    state parseGreNoChecksum {
      transition select(hdr.gre.protocol_type) {
         (ETHERTYPE_IPV4): parseInnerIpv4;
         (ETHERTYPE_IPV6): parseInnerIpv6;
         default: accept;
      }
    }

    state parseGreChecksum {
      pkt.extract(hdr.gre_checksum);
      transition select(hdr.gre.protocol_type) {
         (ETHERTYPE_IPV4): parseInnerIpv4;
         (ETHERTYPE_IPV6): parseInnerIpv6;
         default: accept;
      }
    }

    state parseGre {
      pkt.extract(hdr.gre);
      transition select(hdr.gre.checksum_flag) {
         (1w0x1): parseGreChecksum;
         default: parseGreNoChecksum;
      }
    }

    state parseL23 {
        transition select(eg_md.bridge.l23_txtstmp_insert) {
            1w1 : parseL23Timestamp;
            default: parseFirstPayload;
        }
    }

    state parseTcp{
        pkt.extract(hdr.tcp);
        transition parseL23;
    }

    state parseUdp {
        pkt.extract(hdr.udp);
        transition select(eg_md.bridge.flags_l47_tstamp, eg_md.bridge.flags_first_payload,
        eg_md.bridge.l23_txtstmp_insert)
        {
            (1w1, 1w0, 1w0): parseL47tstamp;
            (1w0, 1w1, 1w0): parseFirstPayload;
            (1w0, 1w1, 1w1): parseL23Timestamp;
        }
    }

    state parseL23Timestamp {
        pkt.extract(hdr.first_payload);
        pkt.extract(hdr.l23_option);
        transition accept;
    }

    state parseFirstPayload {
        pkt.extract(hdr.first_payload);
        transition accept;
    }

    state parseL47tstamp {
        pkt.extract(hdr.l47_tstamp);
        transition accept;
    }



    state parseGtp {
        pkt.extract(hdr.udp);
        pkt.extract(hdr.gtp1);
        transition select(pkt.lookahead<ip46_h>().version) {
          4w0x4: parseInnerIpv4;
          4w0x6: parseInnerIpv6;
          default: accept;
      }
    }


    state parseInnerIpv4 {
      pkt.extract(hdr.inner_ip_version);
      pkt.extract(hdr.inner_ipv4);
      transition select(hdr.inner_ipv4.protocol,
        eg_md.bridge.flags_l47_tstamp, eg_md.bridge.flags_first_payload,
        eg_md.bridge.l23_txtstmp_insert) {
        (IP_PROTOCOLS_TCP, _, 1w1, 1w0): parseInnerTcp;
        (IP_PROTOCOLS_TCP, _, 1w1, 1w1): parseInnerTcpL23Timestamp;
        (IP_PROTOCOLS_UDP, 1w0, 1w1, 1w1): parseInnerUdpL23Timestamp;
        (IP_PROTOCOLS_UDP, 1w0, 1w1, 1w0): parseInnerUdp;
        (IP_PROTOCOLS_UDP, 1w1, 1w0, _): parseInnerUdpOption;
        (_, _, 1w1, 1w0): parseFirstPayload;
        (_, _, 1w1, 1w1): parseL23Timestamp;
        default: accept;
      }
    }

    state parseInnerIpv6 {
      pkt.extract(hdr.inner_ip_version);
      pkt.extract(hdr.inner_ipv6);
      transition select(hdr.inner_ipv6.next_hdr,
        eg_md.bridge.flags_l47_tstamp, eg_md.bridge.flags_first_payload,
        eg_md.bridge.l23_txtstmp_insert) {
        (IP_PROTOCOLS_TCP, _, 1w1, 1w0): parseInnerTcp;
        (IP_PROTOCOLS_TCP, _, 1w1, 1w1): parseInnerTcpL23Timestamp;
        (IP_PROTOCOLS_UDP, 1w0, 1w1, 1w1): parseInnerUdpL23Timestamp;
        (IP_PROTOCOLS_UDP, 1w0, 1w1, 1w0): parseInnerUdp;
        (IP_PROTOCOLS_UDP, 1w1, 1w0, _): parseInnerUdpOption;
        (_, _, 1w1, 1w0): parseFirstPayload;
        (_, _, 1w1, 1w1): parseL23Timestamp;
        default: accept;
      }
    }

    state parseInnerTcpL23Timestamp {
        pkt.extract(hdr.inner_tcp);
        pkt.extract(hdr.first_payload);
        pkt.extract(hdr.l23_option);
    }

    state parseInnerTcp {
        pkt.extract(hdr.inner_tcp);
        pkt.extract(hdr.first_payload);
    }

    state parseInnerUdpL23Timestamp{
        pkt.extract(hdr.inner_udp);
        pkt.extract(hdr.first_payload);
        pkt.extract(hdr.l23_option);
    }

    state parseInnerUdp{
        pkt.extract(hdr.inner_udp);
        pkt.extract(hdr.first_payload);
    }

    state parseInnerUdpOption {
        pkt.extract(hdr.inner_udp);
        pkt.extract(hdr.l47_tstamp);
    }
}
# 17 "eagle.p4" 2
# 1 "hash_generator.p4" 1
/*!
 * @file hash_generator.p4
 * @brief Generate hash calculation based on destination/src ip and destination/src ports
 */

# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */


# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/tofino2arch.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */
# 15 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 2
# 7 "hash_generator.p4" 2





control calculate_hash(inout header_t hdr,
    inout ingress_metadata_t meta,
    out bit<8> hashRes) {
    /******************************/
  CRCPolynomial<bit<32>>(32w0x1edc6f41, // polynomial
                           true, // reversed
                           false, // use msb?
                           false, // extended?
                           32w0x00000000, // initial shift register value
                           32w0x00000000 // result xor
                           ) poly1;
  Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly1) coreSelHash;

  //Hash<bit<32>>(HashAlgorithm_t.CRC32) coreSelHash; // CRC32 hash algorithm with default polynomial
  bit<32> srcDig; // smaller of the hash fields extracted from IPv4/6 src or dst addresses
  bit<32> srcDigPart3; // condensed upper half of IPv6 src address
  bit<32> srcDigPart2; // condensed lower half of IPv6 src address
  bit<32> srcDigPart0; // condensed upper half of IPv6 src address
  bit<32> srcDigPart1; // condensed lower half of IPv6 src address
  bit<32> dstDig; // bigger of the hash fields extracted from IPv4/6 src or dst addresses
  bit<32> dstDigPart3; // condensed upper half of IPv6 dst address
  bit<32> dstDigPart2; // condensed lower half of IPv6 dst address
  bit<32> dstDigPart0; // condensed upper half of IPv6 dst address
  bit<32> dstDigPart1; // condensed lower half of IPv6 dst address

  bit<16> diffPort; // difference between srcPort and dstPort, use in case srcDig == dstDig
  bit<32> loDig3;
  bit<32> loDig2;
  bit<32> loDig1;
  bit<32> loDig0;
  bit<32> hiDig3;
  bit<32> hiDig2;
  bit<32> hiDig1;
  bit<32> hiDig0;
  bit<16> loPort;
  bit<16> hiPort;
  bit<32> final_hash;
  bit<32> diffDig0; // srcDig - dstDig
  bit<32> diffDig1;
  bit<16> srcPort;
  bit<16> dstPort;
  /******************************
   * Crunches IPv6 src and dst addresses into 2 32-bit halves each using XOR
   * @param none
   * @return none
   */
  action mapIpv6Addr() {
    srcDigPart0 = meta.ip_src_31_0 & 0x7fffffff;
    srcDigPart1 = meta.ipv6_src_63_32;
    srcDigPart2 = meta.ipv6_src_95_64;
    srcDigPart3 = meta.ipv6_src_127_96;
    dstDigPart0 = meta.ip_dst_31_0 & 0x7fffffff;
    dstDigPart1 = meta.ipv6_dst_63_32;
    dstDigPart2 = meta.ipv6_dst_95_64;
    dstDigPart3 = meta.ipv6_dst_127_96;
    srcPort = meta.src_port;
    dstPort = meta.dst_port;
  }

  /**
   * Calculates the differences between the 32-bit hash fields
   * @param none
   * @return none
   */
  action noSwapOrder() {
    loPort = dstPort;
    loDig3 = dstDigPart3;
    loDig2 = dstDigPart2;
    loDig1 = dstDigPart1;
    loDig0 = dstDigPart0;
    hiPort = srcPort;
    hiDig3 = srcDigPart3;
    hiDig2 = srcDigPart2;
    hiDig1 = srcDigPart1;
    hiDig0 = srcDigPart0;
  }

  action swapOrder() {
    loPort = srcPort;
    loDig3 = srcDigPart3;
    loDig2 = srcDigPart2;
    loDig1 = srcDigPart1;
    loDig0 = srcDigPart0;
    hiPort = dstPort;
    hiDig3 = dstDigPart3;
    hiDig2 = dstDigPart2;
    hiDig1 = dstDigPart1;
    hiDig0 = dstDigPart0;
  }

  action calcDiffPort() {
    diffPort = srcPort - dstPort;
  }

  action calcDiffDig() {
    diffDig0 = srcDigPart0 - dstDigPart0;
  }

  table determine_orderTbl {
    key = {
      diffDig0 : ternary;
      diffPort : ternary;
    }
    actions = {
        noSwapOrder;
        swapOrder;
    }
    //default_action = noSwapOrder;
    const entries = {
        (32w0x0, 16w0 &&& 16w0x8000): noSwapOrder;
        (32w0x0, 16w0x8000 &&& 16w0x8000): swapOrder;
        (32w0x80000000 &&& 32w0x80000000, _): swapOrder;
        (32w0 &&& 32w0x80000000, _): noSwapOrder;
    }
    size = 4;
  }
  /******************************/
  apply
  {
    mapIpv6Addr();
    //Calculate the difference of the hash fields
    calcDiffDig();
    calcDiffPort();
    determine_orderTbl.apply();
    final_hash = coreSelHash.get({hiDig3, loDig3, hiDig2, loDig2,
                                  hiDig1, loDig1, hiDig0, loDig0,
                                  hiPort, loPort});
    hashRes = final_hash[7:0];
  }
}
# 18 "eagle.p4" 2
# 1 "outbound_l47.p4" 1
/*!
 * @file outbound_l47.p4
 * @brief Remove MPLS (overhead) labels and sends the packet out
 */

# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */


# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/tofino2arch.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */
# 15 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 2
# 7 "outbound_l47.p4" 2





control outbound_l47(inout header_t hdr) {
  /******************************/
  action popVlan()
  {
    hdr.ethernet.ether_type = hdr.vlan_tag_0.ether_type;
    hdr.vlan_tag_0.setInvalid();
  }

  /******************************/
  apply
  {
    //assume it will always have 1 VLAN tag 
    // this is only applied on pkts 
    // from L47 compute node traffic
    popVlan();
  }
}

control outbound_l47_insert_timestamp(inout eg_header_t hdr,
  inout egress_metadata_t eg_md,
  in bit<32> egress_timestamp) {

  action insert_udp_timestamp() {
    hdr.first_payload.signature_top = egress_timestamp;
  }

  action insert_l47_timestamp() {
    hdr.l47_tstamp.l47_tstamp = egress_timestamp;
  }

  action insert_tcp_timestamp() {
    hdr.first_payload.signature_bot = egress_timestamp;
  }
  /*****************************************/
  apply
  {
    if (hdr.l47_tstamp.isValid())
        insert_l47_timestamp();
    else
    {
      if (hdr.first_payload.isValid())
      {
        //insert_compute_node_timestampTbl.apply();
        if (hdr.inner_tcp.isValid() || hdr.tcp.isValid())
        {
          insert_tcp_timestamp();
        }
        else if (hdr.inner_udp.isValid() || hdr.udp.isValid())
        {
          insert_udp_timestamp();
        }
      }
    }

  }
}
# 19 "eagle.p4" 2
# 1 "inbound_l47.p4" 1
/*!
 * @file inbound_l47.p4
 * @brief lookup table for queue range, queue offset and queue mask
 */

# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */


# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/tofino2arch.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */
# 15 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 2
# 7 "inbound_l47.p4" 2






control inbound_l47_gen_lookup(inout header_t hdr,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
        in ingress_metadata_t meta,
        out bit<8> lookup_queue_offset,
        out bit<1> l47_match,
        out bit<1> timestamp_calc,
        out bit<4> l47_iport,
        out bit<8> mod,
        out stats_index_t stat_index) {

  const bit<32> table_sz = 8192;// 16384 if we do exact match with SRAM
  stats_index_t index = 0;
  // need to implement 8K for v4 range, 2K or v6 range
  bit<9> lookup_5;
  bit<11> lookup_6;
  bit<11> lookup_7;
  bit<16> remap_addr_0 = 0;
  bit<16> remap_addr_1 = 0;
  bit<16> remap_addr_2 = 0;
  bit<16> remap_addr_3 = 0;
  bit<16> remap_addr_4 = 0;
  bit<16> remap_addr_5 = 0;
  bit<16> remap_addr_6;
  bit<16> remap_addr_7;
  bit<1> map_v6 = 0;
  bit<1> map_v4 = 0;

 /**********************************/
  action map_address() {
    remap_addr_6 = meta.ip_dst_31_0[31:16];
    remap_addr_7 = meta.ip_dst_31_0[15:0];
  }

  action map_v6_address() {
    remap_addr_0 = meta.ipv6_dst_127_96[31:16];
    remap_addr_1 = meta.ipv6_dst_127_96[15:0];
    remap_addr_2 = meta.ipv6_dst_95_64[31:16];
    remap_addr_3 = meta.ipv6_dst_95_64[15:0];
    remap_addr_4 = meta.ipv6_dst_63_32[31:16];
    remap_addr_5 = meta.ipv6_dst_63_32[15:0];
  }

  action setDefault_5() { lookup_5 = 0;}
  action setDefault_6() { lookup_6 = 0;}
  action setDefault_7() { lookup_7 = 0;}
  action setlookup_5(bit<9> lookup) { lookup_5 = lookup;}
  action setlookup_6(bit<11> lookup) { lookup_6 = lookup;}
  action setlookup_7(bit<11> lookup) { lookup_7 = lookup;}

  table range_47_32{
    key = {
      remap_addr_5 : range;
      meta.map_v6 : exact;
    }
    actions = {
      setlookup_5;
      setDefault_5;
    }
    default_action = setDefault_5;
    size = 512;
  }

  table range_31_16 {
    key = {
     remap_addr_6 : range;
     meta.map_v4 : exact;
     meta.map_v6 : exact;
    }
    actions = {
      setlookup_6;
      setDefault_6;
    }
    default_action = setDefault_6;
    size = 1024;
  }

  table range_15_0 {
    key = {
      remap_addr_7 : range;
      meta.map_v4 : exact;
      meta.map_v6 : exact;
    }
    actions = {
      setlookup_7;
      setDefault_7;
    }
    default_action = setDefault_7;
    size = 1024;
  }

  action setCnPort(PortId_t egPort,
    bit<1> timestamp_ext,
    bit<8> queue_offset,
    stats_index_t stats_index,
    bit<3> l47_port, bit<8> prog_mod,
    QueueId_t queue )
  {
    ig_intr_tm_md.ucast_egress_port = egPort;
    hdr.bridge.pkt_type = PKT_TYPE_SKIP_EGRESS;
    lookup_queue_offset = queue_offset;
    l47_match = 1;
    timestamp_calc = timestamp_ext;
    stat_index = stats_index;
    index = stats_index;
    l47_iport[3:1] = l47_port;
    l47_iport[0:0] = 0;
    ig_intr_tm_md.ingress_cos = 1;
    ig_intr_tm_md.qid = queue;
    mod = prog_mod;
  }

  action setQueue()
  {
    lookup_queue_offset = 0;
    l47_match = 0;
    timestamp_calc = 0;
    stat_index = 0;
    index = 0;
    l47_iport = 0;
    mod = 1;
  }

  table EgressCnTbl {
    key = {
      meta.vid_top: exact;
      meta.vid_bot: exact;
      remap_addr_0: exact;
      remap_addr_1: exact;
      remap_addr_2: exact;
      remap_addr_3: exact;
      remap_addr_4: exact;
      lookup_5: exact;
      lookup_6: exact;
      lookup_7: exact;
      ig_intr_md.ingress_port : exact;
    }
    actions = {
      setCnPort;
      setQueue;
    }
    default_action = setQueue;
    size = table_sz;
  }

  /******************************/
  apply
  {
    map_address();
    map_v6_address();
    range_31_16.apply();
    range_15_0.apply();
    range_47_32.apply();
    EgressCnTbl.apply();
  }
}

control inbound_l47_insert_vlan(inout header_t hdr,
in bit<4> ingress_port, in bit<8> queue_no, in bit<16> ethertype) {

  action map_ethertype()
  {
    hdr.vlan_tag_0.ether_type = ethertype;
    hdr.vlan_tag_0.vlan_bot = queue_no;
    hdr.vlan_tag_0.vlan_top = 0;
  }
  // push vlan label as the first label then swap the ethertype 
  action insertVlanOverhead() {
    hdr.ethernet.ether_type = 0x8100;
    hdr.vlan_tag_0.setValid();
    hdr.vlan_tag_0.pcp_cfi = ingress_port;
    map_ethertype();
  }

  action insertVlan_1() {
    hdr.vlan_tag_1 = hdr.vlan_tag_0;
  }

  action insertVlan_2() {
    hdr.vlan_tag_2 = hdr.vlan_tag_1;
    hdr.vlan_tag_1 = hdr.vlan_tag_0;
  }

  /******************************/
  apply
  {
    if (hdr.vlan_tag_1.isValid())
    {
      insertVlan_2();
    }
    else if (hdr.vlan_tag_0.isValid())
    {
      insertVlan_1();
    }
    insertVlanOverhead();
    //map_ethertype();
  }
}

control inbound_l47_calc_latency( inout header_t hdr,
                                  in ingress_intrinsic_metadata_t ig_intr_md,
                                  in bit<32> rx_tstamp,
                                  out bit<32> latency) {
  action calc_udp_timestamp() {
    latency = rx_tstamp - hdr.first_payload.signature_top;
  }

  action calc_udp_l47_timestamp() {
    latency = rx_tstamp - hdr.l47_tstamp.l47_tstamp;
  }

  action calc_tcp_timestamp() {
    latency = rx_tstamp - hdr.first_payload.signature_bot;
  }

  /*****************************************/
  apply
  {
    if ( hdr.l47_tstamp.isValid())
        calc_udp_l47_timestamp();
    else if (hdr.inner_tcp.isValid() || hdr.tcp.isValid() )
    {
      calc_tcp_timestamp();
    }
    else if (hdr.inner_udp.isValid() || hdr.udp.isValid())
    {
      calc_udp_timestamp();
    }
  }

}
# 20 "eagle.p4" 2
# 1 "timestamp.p4" 1
/*!
 * @file timestamp.p4
 * @brief insert timestamp for L23
 */

# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */


# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/tofino2arch.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */
# 15 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 2
# 7 "timestamp.p4" 2





control timestamp_insertion(inout eg_header_t hdr,
                            inout egress_metadata_t eg_md,
                            in bit<32> egress_timestamp ) {

    action insert_tx_timestamp() {
        hdr.l23_option.txtstamp = egress_timestamp;
    }



  /***************************************************/
  apply
  {
    if(eg_md.bridge.l23_txtstmp_insert == 1)
    {
        insert_tx_timestamp();
    }
  }
}
# 21 "eagle.p4" 2
# 1 "latency_stat.p4" 1
/*!
 * @file latency_stat.p4
 * @brief latency_statistic calculation
 */

# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */


# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/tofino2arch.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */
# 15 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 2
# 7 "latency_stat.p4" 2





control l47_latency_flow_stat(in bit<1> first_pkt, in stats_index_t stat_index,
                      in bit<32> latency )(bit<32> num_stats) {

   Register<lat_tot_layout, stats_index_t>(num_stats) data_storage;
   RegisterAction<lat_tot_layout, stats_index_t, bit<32>>(data_storage)
   write_data = {
      void apply(inout lat_tot_layout value) {
         //register_data = register_data + latency;
         lat_tot_layout register_data;
         register_data = value;
         if (latency + register_data.lo <= 32w0xffffffff) {
               value.hi = register_data.hi;
         }
         else {
            value.hi = register_data.hi + 32w1;
         }
         value.lo = latency + register_data.lo;
       }
   };

   RegisterAction<lat_tot_layout, stats_index_t, bit<32>>(data_storage)
   first_data = {
      void apply(inout lat_tot_layout value) {
         lat_tot_layout register_data;
         register_data = value;
         value.lo = latency;
         value.hi = 0;
       }
   };

  /***************************************************/
  apply
   {
      if (first_pkt == 1w0)
        first_data.execute(stat_index);
      else
        write_data.execute(stat_index);
   }
}

control latency_stat( in bit<1> bank, in stats_index_t stat_index,
   in bit<32> latency ) {

   bit<1> first_pkt;
   //reset for minimum latency
   Register<bit<1>, stats_index_t>(size=1<<13, initial_value=0) first_pkt_reg;

   l47_latency_flow_stat(1<<13) l47_latencyA;
   l47_latency_flow_stat(1<<13) l47_latencyB;
   Register<bit<32>, stats_index_t>(size=1<<13, initial_value=0) store_lat_minA;
   Register<bit<32>, stats_index_t>(size=1<<13, initial_value=0) store_lat_maxA;
   Register<bit<32>, stats_index_t>(size=1<<13, initial_value=0) store_pktA;

   Register<bit<32>, stats_index_t>(size=1<<13, initial_value=0) store_lat_minB;
   Register<bit<32>, stats_index_t>(size=1<<13, initial_value=0) store_lat_maxB;
   Register<bit<32>, stats_index_t>(size=1<<13, initial_value=0) store_pktB;

   RegisterAction<bit<1>, stats_index_t, bit<1>>(first_pkt_reg)
   write_first_pkt = {
      void apply(inout bit<1> register_data, out bit<1> result)
      {
         result = register_data;
         register_data = 1;
      }
   };

   RegisterAction<bit<32>, stats_index_t, bit<32>>(store_lat_minA)
   write_lat_minA = {
      void apply(inout bit<32> register_data) {
         register_data = min(latency, register_data);
      }
   };

   RegisterAction<bit<32>, stats_index_t, bit<32>>(store_lat_minA)
   first_lat_minA = {
      void apply(inout bit<32> register_data) {
         register_data = latency;
      }
   };

   RegisterAction<bit<32>, stats_index_t, bit<32>>(store_lat_minB)
   write_lat_minB = {
      void apply(inout bit<32> register_data) {
         register_data = min(latency, register_data);
      }
   };

   RegisterAction<bit<32>, stats_index_t, bit<32>>(store_lat_minB)
   first_lat_minB = {
      void apply(inout bit<32> register_data) {
         register_data = latency;
      }
   };

   RegisterAction<bit<32>, stats_index_t, bit<32>>(store_lat_maxA)
   write_lat_maxA = {
       void apply(inout bit<32> register_data) {
          register_data = max(latency, register_data);
       }
   };

   RegisterAction<bit<32>, stats_index_t, bit<32>>(store_lat_maxA)
   first_lat_maxA = {
      void apply(inout bit<32> register_data) {
         register_data = latency;
      }
   };

   RegisterAction<bit<32>, stats_index_t, bit<32>>(store_lat_maxB)
   write_lat_maxB = {
       void apply(inout bit<32> register_data) {
          register_data = max(latency, register_data);
       }
   };

   RegisterAction<bit<32>, stats_index_t, bit<32>>(store_lat_maxB)
   first_lat_maxB = {
      void apply(inout bit<32> register_data) {
         register_data = latency;
      }
   };

   RegisterAction<bit<32>, stats_index_t, bit<32>>(store_pktA)
   incr_pkt_countA = {
      void apply(inout bit<32> register_data) {
         register_data = register_data + 1;
      }
   };

   RegisterAction<bit<32>, stats_index_t, bit<32>>(store_pktB)
   incr_pkt_countB = {
      void apply(inout bit<32> register_data) {
         register_data = register_data + 1;
      }
   };


  /***************************************************/
  apply
  {
    first_pkt = write_first_pkt.execute(stat_index);
    if (bank == 1w1)
    {
      l47_latencyA.apply(first_pkt, stat_index, latency);
      if (first_pkt == 1w0)
      {
         first_lat_minA.execute(stat_index);
         first_lat_maxA.execute(stat_index);
      }
      else
      {
         write_lat_minA.execute(stat_index);
         write_lat_maxA.execute(stat_index);
      }
      incr_pkt_countA.execute(stat_index);
    }
    else
    {
      l47_latencyB.apply(first_pkt, stat_index, latency);
      if (first_pkt == 1w0)
      {
         first_lat_minB.execute(stat_index);
         first_lat_maxB.execute(stat_index);
      }
      else
      {
         write_lat_minB.execute(stat_index);
         write_lat_maxB.execute(stat_index);
      }
      incr_pkt_countB.execute(stat_index);
    }
  }
}
# 22 "eagle.p4" 2
# 1 "egress_mirror_overhead.p4" 1
/*!
 * @file  egress_mirror_overhead.p4
 * @brief insert overhead in mirrored packet 
 */

# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */


# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/tofino2arch.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */
# 15 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 2
# 7 "egress_mirror_overhead.p4" 2





control mirror_l47_insert_vlan(inout header_t hdr, in bit<4> ingress_port) {

  bit<16> ethertype;

  action get_ethetype()
  {
    ethertype = hdr.ethernet.ether_type;
  }

  action map_ethertype()
  {

    hdr.vlan_tag_0.vlan_bot = 0;
    hdr.vlan_tag_0.vlan_top = 0;
  }
  // push vlan label as the first label then swap the ethertype 
  action insertVlanOverhead() {
    hdr.vlan_tag_0.ether_type = hdr.ethernet.ether_type;
    hdr.ethernet.ether_type = 0x8100;
    hdr.vlan_tag_0.setValid();
    hdr.vlan_tag_0.pcp_cfi = ingress_port;
    hdr.vlan_tag_0.vlan_bot = 255;
    hdr.vlan_tag_0.vlan_top = 0;
  }

  /******************************/
  apply
  {
    //get_ethetype();
    insertVlanOverhead();
    //map_ethertype();
  }
}
# 23 "eagle.p4" 2
# 1 "ingress_metadata_map.p4" 1
/*!
 * @file ingress_metadata_map.p4
 * @brief map ingress metadata ( muxing inner ip, ip to metadata)
 */

# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */


# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/tofino2arch.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */
# 15 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 2
# 7 "ingress_metadata_map.p4" 2





control ingress_metadata_map(in header_t hdr,
  in ingress_intrinsic_metadata_t ig_intr_md,
  inout ingress_metadata_t meta ) {

   bool inner_vlan;
   bool inner_ip;

   action setIpVlanMode(bool cfg_vlan, bool cfg_ip)
   {
     inner_vlan = cfg_vlan;
     inner_ip = cfg_ip;
   }

   action setDefaultConfig()
   {
      inner_vlan = false;
      inner_ip = false;
   }

  table FrontPanelConfigTbl {
    key = {
      ig_intr_md.ingress_port : exact;
    }
    actions = {
      setIpVlanMode;
      setDefaultConfig;
    }
    default_action = setDefaultConfig;
    size = 64;
  }

   action map_v4()
   {
      meta.ip_src_31_0 = hdr.ipv4.src_addr;
      meta.ip_dst_31_0 = hdr.ipv4.dst_addr;
      meta.map_v4 = 1w1;
      meta.map_v6 = 1w0;
   }

   action map_v6()
   {
      meta.ipv6_src_127_96 = hdr.ipv6.src_addr[127:96];
      meta.ipv6_src_95_64 = hdr.ipv6.src_addr[95:64];
      meta.ipv6_src_63_32 = hdr.ipv6.src_addr[63:32];
      meta.ip_src_31_0 = hdr.ipv6.src_addr[31:0];
      meta.ipv6_dst_127_96 = hdr.ipv6.dst_addr[127:96];
      meta.ipv6_dst_95_64 = hdr.ipv6.dst_addr[95:64];
      meta.ipv6_dst_63_32 = hdr.ipv6.dst_addr[63:32];
      meta.ip_dst_31_0 = hdr.ipv6.dst_addr[31:0];
      meta.map_v4 = 1w0;
      meta.map_v6 = 1w1;
   }

   action map_inner_v4()
   {
      meta.ip_src_31_0 = hdr.inner_ipv4.src_addr;
      meta.ip_dst_31_0 = hdr.inner_ipv4.dst_addr;
      meta.map_v4 = 1w1;
      meta.map_v6 = 1w0;
   }

   action map_inner_v6()
   {
      meta.ipv6_src_127_96 = hdr.inner_ipv6.src_addr[127:96];
      meta.ipv6_src_95_64 = hdr.inner_ipv6.src_addr[95:64];
      meta.ipv6_src_63_32 = hdr.inner_ipv6.src_addr[63:32];
      meta.ip_src_31_0 = hdr.inner_ipv6.src_addr[31:0];
      meta.ipv6_dst_127_96 = hdr.inner_ipv6.dst_addr[127:96];
      meta.ipv6_dst_95_64 = hdr.inner_ipv6.dst_addr[95:64];
      meta.ipv6_dst_63_32 = hdr.inner_ipv6.dst_addr[63:32];
      meta.ip_dst_31_0 = hdr.inner_ipv6.dst_addr[31:0];
      meta.map_v4 = 1w0;
      meta.map_v6 = 1w1;
   }

   action map_tcp()
   {
      meta.src_port = hdr.tcp.src_port & 0x7fff;
      meta.dst_port = hdr.tcp.dst_port & 0x7fff;
   }

   action map_udp()
   {
      meta.src_port = hdr.udp.src_port & 0x7fff;
      meta.dst_port = hdr.udp.dst_port & 0x7fff;
   }

   action map_inner_tcp()
   {
      meta.src_port = hdr.inner_tcp.src_port & 0x7fff;
      meta.dst_port = hdr.inner_tcp.dst_port & 0x7fff;
   }

   action map_inner_udp()
    {
      meta.src_port = hdr.inner_udp.src_port & 0x7fff;
      meta.dst_port = hdr.inner_udp.dst_port & 0x7fff;
    }

   table metadata_inner {
      key = {
         hdr.ipv4.isValid() : ternary;
         hdr.ipv6.isValid() : ternary;
         hdr.inner_ipv4.isValid() : ternary;
         hdr.inner_ipv6.isValid() : ternary;
      }
      actions = {
         map_v4;
         map_v6;
         map_inner_v6;
         map_inner_v4;
         NoAction;
      }
      const entries = {
         (_, _, true, _): map_inner_v4();
         (_, _, false, true): map_inner_v6();
         (true, _, false, false): map_v4();
         (false, true,false, false): map_v6();
      }
   }

   table metadata_default {
      key = {
         hdr.ipv4.isValid() : exact;
         hdr.ipv6.isValid() : exact;
      }
      actions = {
         map_v4;
         map_v6;
         NoAction;
      }
      const entries = {
         (true, false): map_v4();
         (false, true): map_v6();
      }
   }

   table metadata_portmap {
      key = {
         hdr.tcp.isValid() : ternary;
         hdr.udp.isValid() : ternary;
         hdr.inner_tcp.isValid() : ternary;
         hdr.inner_udp.isValid() : ternary;
      }
      actions = {
         map_tcp;
         map_udp;
         map_inner_tcp;
         map_inner_udp;
         NoAction;
      }
      const entries = {
         (_, _, true, _): map_inner_tcp();
         (_, _, false, true): map_inner_udp();
         (true, _, false, false): map_tcp();
         (false, true,false, false): map_udp();
      }
   }

   action map_vlan()
   {
      meta.vid_top = hdr.vlan_tag_0.vlan_top;
      meta.vid_bot = hdr.vlan_tag_0.vlan_bot;
   }

   action no_vlan()
   {
      meta.vid_top = 0;
      meta.vid_bot = 0;
   }

   action map_inner_vlan()
   {
      meta.vid_top = hdr.vlan_tag_1.vlan_top;
      meta.vid_bot = hdr.vlan_tag_1.vlan_bot;
   }

   table metadata_vlan {
      key = {
         inner_vlan : exact;
         hdr.vlan_tag_0.isValid() : exact;
         hdr.vlan_tag_1.isValid() : exact;
      }
      actions = {
         map_inner_vlan;
         map_vlan;
         no_vlan;
      }
      const entries = {
         (true, true, true) : map_inner_vlan();
         (true, true, false): map_vlan();
         (true, false, false): no_vlan;
         (false, true, true): map_vlan();
         (false, true, false): map_vlan();
         (false, false, false): no_vlan;
      }
   }
  /***************************************************/
  apply
   {
      FrontPanelConfigTbl.apply();
      if (inner_ip)
         metadata_inner.apply();
      else
         metadata_default.apply();
      if (meta.port_properties.port_type == FRONTPANEL_PORT)
         metadata_vlan.apply();
      //metadata_vlan.apply();
      metadata_portmap.apply();
   }
}
# 24 "eagle.p4" 2
# 1 "checksum_correction.p4" 1
/*!
 * @file checksum_correction.p4
 * @brief checksum correcion
 */

# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */


# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/tofino2arch.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */
# 15 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 2
# 7 "checksum_correction.p4" 2




control calculate_checksum(in egress_metadata_t eg_md, inout eg_header_t hdr,
                          in bit<32> collapsed_tstamp, in bit<32> global_tstamp) {

    //zero pad all the checksum to 32-bit
    bit<32> egress_timestamp;
    bit<32> cksm;
    bit<32> carry;
    bit<32> carry_2;
    bit<16> org_cksm;
    bit<16> final;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identityHash32_tx;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identityHash32_cksm;

    action sum_timestamp()
    {
       egress_timestamp = collapsed_tstamp + identityHash32_tx.get(global_tstamp[31:16]);
    }

    action map_tcp_chksum()
    {
      org_cksm = hdr.tcp.checksum ;
    }

    action map_udp_chksum()
    {
      org_cksm = hdr.udp.checksum ;
    }

    action map_inner_udp_chksum() {
      org_cksm = hdr.inner_udp.checksum;
    }

    action map_inner_tcp_chksum() {
      org_cksm = hdr.inner_tcp.checksum;
    }

    table checksum_map_tbl{
      key = {
        hdr.tcp.isValid() : ternary;
        hdr.udp.isValid() : ternary;
        hdr.inner_tcp.isValid() : ternary;
        hdr.inner_udp.isValid() : ternary;
      }
      actions = {
        map_tcp_chksum;
        map_udp_chksum;
        map_inner_tcp_chksum;
        map_inner_udp_chksum;
        NoAction;
      }
      const entries = {
         ( _, _, true, _): map_inner_tcp_chksum;
         ( _, _, false, true): map_inner_udp_chksum;
         ( true, _, false, false): map_tcp_chksum;
         ( false, true,false, false): map_udp_chksum;
      }
   }
   //negate original checksum to get the sum of all fields
   action invert_org()
   {
      org_cksm = org_cksm ^ 0xffff;
   }

   action step_rx_4(){
      cksm = eg_md.bridge.sum_mac_timestamp;
    }

    action step_tx_4(){
      cksm = egress_timestamp;
    }

   table initialize_cs_tbl{
       key = {
        eg_md.bridge.l23_rxtstmp_insert: exact;
        eg_md.bridge.l23_txtstmp_insert: exact;
        eg_md.bridge.l47_timestamp_insert: exact;
       }
       actions = {
        step_rx_4();
        step_tx_4();
        NoAction;
       }
       const entries = {
        (1, 0, 0): step_rx_4;
        (0, 1, 0): step_tx_4;
        (0, 0, 1): step_tx_4;
       }
    }

    action add_cksm_to_org()
    {
      cksm = cksm + identityHash32_cksm.get(org_cksm);
    }

    action shift_out_carry() {
      carry = cksm >> 16;
      cksm = cksm & 0xFFFF;
    }

    action add_carry() {
      cksm = cksm + carry;
    }

    action shift_out_carry_2() {
      carry_2 = cksm >> 16;
      cksm = cksm & 0xFFFF;
    }

    action add_carry_2() {
      cksm = cksm + carry_2;
    }

    action finalize_checksum()
    {
      final = (bit<16>)(cksm) ^ 0xffff;
    }

    action insert_tcp_chksum()
    {
      hdr.tcp.checksum = final;
    }

    action insert_udp_chksum()
    {
      hdr.udp.checksum = final;
    }

    action insert_inner_udp_chksum() {
      hdr.inner_udp.checksum = final;
    }

    action insert_inner_tcp_chksum() {
      hdr.inner_tcp.checksum = final;
    }

   table checksum_insert_tbl{
      key = {
        hdr.tcp.isValid() : ternary;
        hdr.udp.isValid() : ternary;
        hdr.inner_tcp.isValid() : ternary;
        hdr.inner_udp.isValid() : ternary;
      }
      actions = {
        insert_tcp_chksum;
        insert_udp_chksum;
        insert_inner_tcp_chksum;
        insert_inner_udp_chksum;
        NoAction;
      }
      const entries = {
         ( _, _, true, _): insert_inner_tcp_chksum;
         ( _, _, false, true): insert_inner_udp_chksum;
         ( true, _, false, false): insert_tcp_chksum;
         ( false, true,false, false): insert_udp_chksum;
      }
   }

    apply
    {
      checksum_map_tbl.apply();
      invert_org();
      sum_timestamp();
      initialize_cs_tbl.apply();
      add_cksm_to_org();
      shift_out_carry();
      add_carry();
      shift_out_carry_2();
      add_carry_2();
      finalize_checksum();
      if (eg_md.bridge.l23_txtstmp_insert == 1 || eg_md.bridge.l47_timestamp_insert == 1)
        checksum_insert_tbl.apply();
    }
}
# 25 "eagle.p4" 2
# 1 "l2offset_map.p4" 1
/*!
 * @file ingress_metadata_map.p4
 * @brief map ingress metadata ( muxing inner ip, ip to metadata)
 */

# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */


# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/tofino2arch.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */
# 15 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 2
# 7 "l2offset_map.p4" 2





control l2_offset_map(inout header_t hdr, in bit<8> mpls_offset) {

   bit<8> l2_offset;
       action map_1()
   {
      l2_offset = mpls_offset + 21;
   }

   action map_2()
   {
      l2_offset = mpls_offset + 22;
   }

   action map_3()
   {
      l2_offset = mpls_offset + 23;
   }

   action map_4()
   {
      l2_offset = mpls_offset + 24;
   }

   action map_0()
   {
      l2_offset = mpls_offset + 20;
   }

    action map_1_v6()
   {
      l2_offset = mpls_offset + 41;
   }

   action map_2_v6()
   {
      l2_offset = mpls_offset + 42;
   }

   action map_3_v6()
   {
      l2_offset = mpls_offset + 43;
   }

   action map_4_v6()
   {
      l2_offset = mpls_offset + 44;
   }

   action map_0_v6()
   {
      l2_offset = mpls_offset + 40;
   }

    action map_0_noip() {
        l2_offset = mpls_offset;
    }

    action map_l2_offset()
    {
        hdr.bridge.l2_offset = l2_offset;
    }

   table map_l2offset_tbl{
      key = {
        hdr.vlan_tag_0.isValid(): ternary;
        hdr.vlan_tag_1.isValid(): ternary;
        hdr.vlan_tag_2.isValid(): ternary;
        hdr.snap.isValid(): exact;
        hdr.ipv4.isValid(): exact;
        hdr.ipv6.isValid(): exact;
      }
      actions = {
        map_1;
        map_2;
        map_3;
        map_4;
        map_0;
        map_1_v6;
        map_2_v6;
        map_3_v6;
        map_4_v6;
        map_0_v6;
        map_0_noip;
      }
      const entries = {
        (true, false, false, false, true, false): map_1();
        (false, true, false, false, true, false): map_1();
        (true, true, false, false, true, false): map_2();
        (_, true, true, false, true, false): map_2();
        (true, false, false, true, true, false): map_3();
        (false, true, false, true, true, false): map_3();
        (_, true, true, true, true, false): map_4();
        (true, true, false, true, true, false): map_4();
        (false, false, false, false, true, false): map_0();
        (false, false, false, true, true, false): map_2();

        (true, false, false, false, false, true): map_1_v6();
        (false, true, false, false, false, true): map_1_v6();
        (true, true, false, false, false, true): map_2_v6();
        (_, true, true, false, false, true): map_2_v6();
        (true, false, false, true, false, true): map_3_v6();
        (false, true, false, true, false, true): map_3_v6();
        (true, true, false, true, false, true): map_4_v6();
        (_, true, true, true, false, true): map_4_v6();
        (false, false, false, false, false, true): map_0_v6();
        (false, false, false, true, false, true): map_2_v6();
        (false, false, false, false, false, false): map_0_noip;
      }
   }


    action map_udp () { hdr.bridge.flags_l3_protocol = 1;}
    action map_tcp() { hdr.bridge.flags_l3_protocol = 2;}
    action map_gre() { hdr.bridge.flags_l3_protocol = 3;}
    action map_gtp() { hdr.bridge.flags_l3_protocol = 4;}
    action map_inner_v4() { hdr.bridge.flags_l3_protocol = 5;}
    action map_inner_v6() { hdr.bridge.flags_l3_protocol = 6;}
    action no_l4() { hdr.bridge.flags_l3_protocol = 0;}

    table map_l3_offset_tbl {
      key = {
         hdr.udp.isValid(): exact;
         hdr.tcp.isValid(): exact;
         hdr.gre.isValid(): exact;
         hdr.gtp1.isValid(): exact;
         hdr.ipv4.isValid(): ternary;
         hdr.ipv6.isValid(): ternary;
         hdr.inner_ipv4.isValid(): ternary;
         hdr.inner_ipv6.isValid(): ternary;
      }
      actions = {
         map_udp;
         map_tcp;
         map_gre;
         map_gtp;
         map_inner_v4;
         map_inner_v6;
         no_l4;
      }
      const entries = {
         (true, false, false, false, _, _, _, _): map_udp;
         (false, true, false, false, _, _, _, _): map_tcp;
         (false, false, true, false, _, _, _, _): map_gre;
         (true, false, false, true, _, _, _, _): map_gtp;
         (true, false, false, false, false, true, true, false): map_inner_v4;
         (false, false, false, false, true, false, false, true): map_inner_v6;
      }
      default_action = no_l4;
      size = 8;
   }


   action map_l47tstamp()
   {
      hdr.bridge.flags_l47_tstamp = 1;
      hdr.bridge.flags_first_payload = 0;
   }

   action map_l23tstamp()
   {
      hdr.bridge.flags_l47_tstamp = 0;
      hdr.bridge.flags_first_payload = 1;
   }

   action map_no_tstamp()
   {
      hdr.bridge.flags_l47_tstamp = 0;
      hdr.bridge.flags_first_payload = 0;
   }

   table map_tstamp_flags_tbl{
      key = {
         hdr.l47_tstamp.isValid(): exact;
         hdr.first_payload.isValid(): exact;
      }
      actions = {
         map_l47tstamp;
         map_l23tstamp;
         map_no_tstamp;
      }
      const entries = {
         (true, false): map_l47tstamp;
         (false, true): map_l23tstamp;
         (false, false): map_no_tstamp;
      }
   }


  /***************************************************/
  apply
   {
      map_l2offset_tbl.apply();
      map_l2_offset();
      map_l3_offset_tbl.apply();
      map_tstamp_flags_tbl.apply();
   }
}
# 26 "eagle.p4" 2
# 1 "capture_filter.p4" 1
/*!
 * @file inbound_l47.p4
 * @brief lookup table for queue range, queue offset and queue mask
 */

# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */


# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/tofino2arch.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */
# 15 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 2
# 7 "capture_filter.p4" 2






control capture_filter( inout header_t hdr,
                        in ingress_intrinsic_metadata_t ig_intr_md,
                        inout ingress_metadata_t meta,
                        in bit<1> l23_match, in bit<1> l47_match
        ) {

  bit<8> sa_match_no = 0;
  bit<8> da_match_no = 0;

  bit<20> mpls_label;
  bit<1> mpls_valid;
  bit<1> vlan_valid;
  bit<16> vlan_label;
  bit<8> mpls_match_no;
  bit<8> vlan_match_no;
  bit<1> v6_match;
  bit<96> v6_sa_top;
  bit<96> v6_da_top;
  bit<1> v4_match;
  bit<32> source_ip;
  bit<32> destination_ip;
  bit<8> ip_sa_match_no;
  bit<8> ip_da_match_no;
  bit<16> src_port;
  bit<16> dst_port;
  bit<1> port_match;
  bit<8> sport_match_no;
  bit<8> dport_match_no;
  //reserve 0 for non-match


/********************************/
    action ethernet_da_match(bit<8> entry)
    {
        da_match_no = entry;
    }

    table ethernet_da_tbl {
    key = {
        hdr.ethernet.dst_addr : ternary;
    }
    actions = {
        ethernet_da_match;
        NoAction;
    }
    default_action = NoAction;
    size = 32;
    }

/********************************/
    action ethernet_sa_match(bit<8> entry)
    {
        sa_match_no = entry;
    }

    table ethernet_sa_tbl {
    key = {
        hdr.ethernet.src_addr : ternary;
    }
    actions = {
        ethernet_sa_match;
        NoAction;
    }
    default_action = NoAction;
    size = 32;
    }

/********************************/
    action mpls_match(bit<8> entry)
    {
        mpls_match_no = entry;
    }

    action vlan_match(bit<8> entry)
    {
        vlan_match_no = entry;
    }

    table vlan_mpls_tbl {
    key = {
        hdr.mpls_0.label : ternary;
        hdr.vlan_tag_0.vlan_top : exact;
        hdr.vlan_tag_0.vlan_bot : range;
        hdr.vlan_tag_1.vlan_top : exact;
        hdr.vlan_tag_1.vlan_bot : range;
        hdr.mpls_0.isValid() : exact;
        hdr.vlan_tag_0.isValid() : exact;
        hdr.vlan_tag_1.isValid() : exact;
    }
    actions = {
        vlan_match;
        mpls_match;
        NoAction;
    }
    default_action = NoAction;
    size = 32;
    }

/********************************/
    action ip_sa_match(bit<8> entry)
    {
        ip_sa_match_no = entry;
    }

    action ip_da_match(bit<8> entry)
    {
        ip_da_match_no = entry;
    }

    table ip_sa_tbl {
        key = {
            meta.map_v4 : exact;
            meta.map_v6 : exact;
            meta.ip_src_31_0 : ternary;
            meta.ipv6_src_63_32 : exact;
            meta.ipv6_src_95_64 : exact;
            meta.ipv6_src_127_96: exact;
        }
        actions = {
            ip_sa_match;
            NoAction;
        }
        default_action = NoAction;
        size = 32;
    }

    table ip_da_tbl {
        key = {
            meta.map_v4 : exact;
            meta.map_v6 : exact;
            meta.ip_dst_31_0 : ternary;
            meta.ipv6_dst_63_32 : exact;
            meta.ipv6_dst_95_64 : exact;
            meta.ipv6_dst_127_96: exact;
        }
        actions = {
            ip_sa_match;
            NoAction;
        }
        default_action = NoAction;
        size = 32;
    }

    /********/
    action dport_match(bit<8> entry)
    {
        dport_match_no = entry;
    }

    action sport_match(bit<8> entry)
    {
        sport_match_no = entry;
    }

    table src_port_tbl {
        key = {
            meta.src_port : range;
            port_match : exact;
        }
        actions = {
            sport_match;
            NoAction;
        }
        default_action = NoAction;
        size = 32;
    }

    table dst_port_tbl {
        key = {
            meta.dst_port : range;
            port_match : exact;
        }
        actions = {
            dport_match;
            NoAction;
        }
        default_action = NoAction;
        size = 32;
    }

    action trigger_match()
    {
        meta.mirror.filter = 1w0;
        meta.mirror.trigger = 1w1;
        hdr.bridge.filter = 1w0;
        hdr.bridge.trigger = 1w1;
    }

    action trigger_and_filter_match()
    {
        meta.mirror.filter = 1w1;
        meta.mirror.trigger = 1w1;
        hdr.bridge.filter = 1w1;
        hdr.bridge.trigger = 1w1;
    }

    action filter_match()
    {
        meta.mirror.filter = 1w1;
        meta.mirror.trigger = 1w0;
        hdr.bridge.filter = 1w1;
        hdr.bridge.trigger = 1w0;
    }


    table caputre_matchers_tbl {
        key = {
            sport_match_no : ternary;
            dport_match_no : ternary;
            ip_sa_match_no : ternary;
            ip_da_match_no : ternary;
            sa_match_no : ternary;
            da_match_no : ternary;
            mpls_match_no : ternary;
            vlan_match_no : ternary;
            l23_match : ternary;
            l47_match : ternary;
        }
        actions = {
            trigger_match;
            trigger_and_filter_match;
            filter_match;
            NoAction;
        }
        default_action = NoAction;
        size = 512;
    }

/******************************/
apply
{
    ethernet_sa_tbl.apply();
    ethernet_da_tbl.apply();
    vlan_mpls_tbl.apply();
    ip_da_tbl.apply();
    ip_sa_tbl.apply();
    dst_port_tbl.apply();
    src_port_tbl.apply();
    caputre_matchers_tbl.apply();
}

}
# 27 "eagle.p4" 2
# 1 "length_filter.p4" 1
/*!
 * @file inbound_l47.p4
 * @brief lookup table for queue range, queue offset and queue mask
 */

# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */


# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/tofino2arch.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */
# 15 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 2
# 7 "length_filter.p4" 2






control length_filter( inout eg_header_t hdr,
                        in egress_metadata_t eg_md,
                        in egress_intrinsic_metadata_t eg_intr_md
        ) {

  bit<3> length_match_no = 0;

  //reserve 0 for non-match

 /**********************************/
    action length_match(bit<3> entry)
    {
        length_match_no = entry;
    }

    table length_tbl{
    key = {
        eg_intr_md.pkt_length : range;
    }
    actions = {
        length_match;
        NoAction;
    }
    default_action = NoAction;
    size = 8;
    }

    action trigger_match()
    {
        hdr.capture.filter = 1w0;
        hdr.capture.trigger = 1w1;
    }

    action trigger_and_filter_match()
    {
        hdr.capture.filter = 1w1;
        hdr.capture.trigger = 1w1;
    }

    action filter_match()
    {
        hdr.capture.filter = 1w1;
        hdr.capture.trigger = 1w0;
    }

    action no_match()
    {
        hdr.capture.filter = 1w0;
        hdr.capture.trigger = 1w0;
    }


    table capture_matchers_tbl {
        key = {
            length_match_no : ternary;
            eg_md.ing_port_mirror.filter : exact;
            eg_md.ing_port_mirror.trigger : exact;
        }
        actions = {
            trigger_match;
            trigger_and_filter_match;
            filter_match;
            no_match;
        }
        default_action = no_match;
        size = 32;
    }

/******************************/
apply
{
    length_tbl.apply();
    capture_matchers_tbl.apply();
}

}
# 28 "eagle.p4" 2
# 1 "ingress_cmp.p4" 1

# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */


# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/tofino2arch.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */
# 15 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 2
# 3 "ingress_cmp.p4" 2




control ingress_cmp(in ghost_intrinsic_metadata_t g_intr_md,
                    inout ingress_metadata_t meta,
                    out bit<16> rich_register) {

MinMaxAction<bit<16>, bit<8>, bit<16>>(ping_reg) ping_get = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x3E, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(pong_reg) pong_get = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x3E, subindex[2:0]);
        }
    };


    @stage(1)
    action ping_get_depth() {
        ping_get.execute(meta.port_properties.capture_group, rich_register);
    }
    @stage(1)
    action pong_get_depth() {
        pong_get.execute(meta.port_properties.capture_group, rich_register);
    }
    @stage(1)
    table ping_read_tbl {
        actions = {
            ping_get_depth;
        }
        default_action = ping_get_depth;
    }

    @stage(1)
    table pong_read_tbl {
        actions = {
            pong_get_depth;
        }
        default_action = pong_get_depth;
    }


    apply {
        if (g_intr_md.ping_pong == 0) {
            ping_read_tbl.apply();
        }
        else {
            pong_read_tbl.apply();
        }
    }
}
# 29 "eagle.p4" 2
# 1 "egress_cmp.p4" 1

# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */


# 1 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/tofino2arch.p4" 1
/**
 * Copyright 2013-2020 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */
# 15 "/home/parallels/bf-sde-9.3.0/install/share/p4c/p4include/t2na.p4" 2
# 3 "egress_cmp.p4" 2




control egress_cmp(in ghost_intrinsic_metadata_t g_intr_md,
                    inout ingress_metadata_t meta,
                    in bit<8> idx, out bit<16> rich_register) {

    MinMaxAction<bit<16>, bit<8>, bit<16>>(ping_egress_reg) ping_egress_get = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x3E, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(pong_egress_reg) pong_egress_get = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x3E, subindex[2:0]);
        }
    };


/******************************************************************************/
    action eg_ping_get_depth() {
        ping_egress_get.execute(idx,rich_register);
    }
    action eg_pong_get_depth() {
        pong_egress_get.execute(idx,rich_register);
    }
    @stage(8)
    table eg_ping_read_tbl {
        actions = {
            eg_ping_get_depth;
        }
        default_action = eg_ping_get_depth;
    }

    @stage(8)
    table eg_pong_read_tbl {
        actions = {
            eg_pong_get_depth;
        }
        default_action = eg_pong_get_depth;
    }


    apply {
        if (g_intr_md.ping_pong == 0) {
            eg_ping_read_tbl.apply();
        }
        else {
            eg_pong_read_tbl.apply();
        }
    }


}
# 30 "eagle.p4" 2
/**
 * Ingress parser
 * @param in pkt input packet
 * @param out hdr header(s) extracted from the packet
 * @param out ig_md ingress metadata
 * @param out ig_intr_md ingress intrinsic metadata
 * @return none
 */
parser SxIngParser(packet_in pkt,
       out header_t hdr,
       out ingress_metadata_t meta,
       out ingress_intrinsic_metadata_t ig_intr_md) {
    PacketParserIngress() pkt_parser;

    state start {
      pkt_parser.apply(pkt, hdr, meta, ig_intr_md);
      transition accept;
    }
}

/**
 * Ingress pipeline: Sets the destination port for incoming packets.
 * @param inout hdr extracted header(s)
 * @param inout ig_md ingress metadata
 * @param in ig_intr_md ingress intrinsic metadata
 * @param in ig_intr_prsr_md ingress intrinsic metadata for parser
 * @param in ig_intr_dprsr_md ingress intrinsic metadata for deparser
 * @param out ig_intr_md_for_tm ingress intrinsic metadata for traffic manager
 * @return none
 */

control SxIngPipeline(inout header_t hdr,
         inout ingress_metadata_t meta,
         in ingress_intrinsic_metadata_t ig_intr_md,
         in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
         inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
         inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
         in ghost_intrinsic_metadata_t g_intr_md)
{
  /*
   * Ingress per port stat counters
   */
    Counter<bit<64>, bit<6>> (64, CounterType_t.PACKETS_AND_BYTES) banked_port_statsB;
    Counter<bit<64>, bit<6>> (64, CounterType_t.PACKETS_AND_BYTES) banked_port_statsA;
    const bit<32> table_sz = 512;
    bit<8> sel_hash;
    bit<8> queue_offset;
    bit<1> l47_match;
    bit<1> timestamp_calc;
    bit<16> ethertype;
    bit<8> final_queue ;
    bit<32> pkt_latency;
    stats_index_t stat_index;
    stats_index_t banked_index;
    bit<7> port_index;
    bit<8> mpls_offset;
    bit<32> ingress_mac_timestamp;
    bit<4> l47_ingress_port;
    bit<1> l23_match;
    bit<1> insert_l23_txtimestamp = 0;
    bit<8> prog_mod;
    bit<32> collapsed_rx_mac;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identityHash32_rx;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identityHash32_rx_2;
    bit<16> rich_register = 0;
    bit<16> egress_rich_register = 0;
    bit<8> egress_capture_group = 0;
    bit<16> seq_no = 0;
    bit<1> match = 0;
    bit<1> match_bank_stat = 0;

    Register<bit<16>, bit<3>>(size=8, initial_value=0) sequence_no;
    RegisterAction<bit<16>, bit<3>, bit<16>>(sequence_no)
    update_seq_no = {
        void apply(inout bit<16> register_data, out bit<16> result)
        {
            result = register_data;
            if (register_data == 16w0x7ff)
                register_data = 0;
            else
                register_data = register_data + 1;
        }
    };

   /**
   * Sets egress port.
   * @param egPort egress port
   * @return none
   */
    action truncate_rx_tstamp() {
       ingress_mac_timestamp = (bit<32>)(ig_intr_md.ingress_mac_tstamp);
       ethertype = hdr.ethernet.ether_type;
    }

    action assign_rx_tstamp(){
      hdr.bridge.sum_mac_timestamp = collapsed_rx_mac + identityHash32_rx_2.get({ingress_mac_timestamp[15:0]});
    }

    action insertL23RxTimestamp() {
      hdr.first_payload.rx_timestamp = (bit<32>)(ig_intr_md.ingress_mac_tstamp);
      hdr.bridge.l23_rxtstmp_insert = 1;
    }

    action setL23InboundInsertEgPort(PortId_t egPort, QueueId_t queue) {
        ig_intr_tm_md.ucast_egress_port = egPort;
        ig_intr_tm_md.qid = queue;
        insertL23RxTimestamp();
    }

    action setL23OutboundEgPort(PortId_t egPort, QueueId_t queue){
        ig_intr_tm_md.ucast_egress_port = egPort;
        ig_intr_tm_md.qid = queue;
        hdr.bridge.l23_txtstmp_insert = 0;
    }

    action setL23OutboundInsertEgPort(PortId_t egPort, QueueId_t queue){
        ig_intr_tm_md.ucast_egress_port = egPort;
        ig_intr_tm_md.qid = queue;
        hdr.bridge.l23_txtstmp_insert = 1;
    }

    table L23OutboundTbl {
        key = {
            ig_intr_md.ingress_port : exact;
            meta.engine_id: exact;
            insert_l23_txtimestamp: exact;
        }
        actions = {
          setL23InboundInsertEgPort;
          setL23OutboundInsertEgPort;
          setL23OutboundEgPort;
          NoAction;
        }
        default_action = NoAction;
        size = 8;
    }

    action match_signature()
    {
        l23_match = 1w1;
        meta.engine_id = hdr.first_payload.rx_timestamp[3:0];
        hdr.bridge.pkt_type = PKT_TYPE_NORMAL;
        insert_l23_txtimestamp = hdr.first_payload.rx_timestamp[4:4];
    }

    action l23_match_signature()
    {
        match_signature();
    }

    action no_match()
    {
        l23_match = 1w0;
    }

    table checkSignatureTbl {
        key = {
          hdr.first_payload.signature_top: exact;
          hdr.first_payload.signature_bot: exact;
        }
        actions = {
          match_signature;
          no_match;
        }
        default_action = no_match;
        size = 2;
    }

    action lookup_queue( bit<8> output_queue) {
    //modulo, use a programmable lookup table instead
    //to save and & operation, this has to be maximum 127
    //Truncating to 7 bits require remapping of PHV.
    //Math should guarantee the top most bit is 0 for now.
        final_queue = queue_offset + output_queue;
    }

    action lookup_queue_0() {
    //mod of 1
        final_queue = queue_offset;
    }
    action map_final_queue()
    {
        final_queue = 0xff;
    }

    table queueModTbl {
        key = {
          sel_hash: ternary;
          l47_match: exact;
          prog_mod: exact;
        }
        actions = {
          lookup_queue;
          lookup_queue_0;
          map_final_queue;
        }
        default_action = map_final_queue;
        size = 3588;
    }

    // each front panel should map to a single multicast group that has
    // at least 2 ports, a default CN port and CPU port
    action set_mcast_grp(MulticastGroupId_t mcg) {
        ig_intr_tm_md.mcast_grp_a = mcg;
        ig_intr_dprsr_md.mirror_type = 0;
        hdr.bridge.pkt_type = PKT_TYPE_BROADCAST;
        hdr.bridge.ingress_port = ig_intr_md.ingress_port[7:0];
    }

    //only match on l47_match and l23_match = 0
    // the only configurable item from user is the port number
    table multicastTbl {
        key = {
            ig_intr_md.ingress_port : exact;
            l47_match: exact;
        }
        actions = {
            set_mcast_grp;
            NoAction;
        }
        default_action = NoAction;
        size = 8;
    }

    action insert_seq_no()
    {
        meta.mirror.capture_seq_no = seq_no;
        //meta.mirror.l2_offset = hdr.bridge.l2_offset;
    }

    action set_capture_mirror_session(MirrorId_t mirror_session) {
        ig_intr_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
        ig_intr_tm_md.mcast_grp_a = 0;
        meta.mirror_session = mirror_session;
        meta.mirror.pkt_type = PKT_TYPE_CAPTURE;
        meta.mirror.mac_timestamp = ingress_mac_timestamp;
        seq_no = update_seq_no.execute(meta.port_properties.capture_group[5:3]);
        //meta.mirror.flags_first_payload = hdr.bridge.flags_first_payload;
        //meta.mirror.flags_l3_protocol = hdr.bridge.flags_l3_protocol;
        //meta.mirror.flags_l47_tstamp = hdr.bridge.flags_l47_tstamp;
        match = 1;
    }

    table ingressCaptureTbl {
        key = {
            ig_intr_md.ingress_port : exact;
            meta.port_properties.capture_group : exact;
            rich_register : exact;
        }
        actions = {
            set_capture_mirror_session;
            NoAction;
        }
        default_action = NoAction;
        size = 32;
    }

    action assignEPort(PortId_t egress_port, QueueId_t queue) {
        ig_intr_tm_md.ucast_egress_port = egress_port;
        // the ingress_cos is always mapped to the 3-bit l47_ob_egressport
        // qid will be 0 for CPU  (qid 1 for fpgas)
        ig_intr_tm_md.ingress_cos = meta.l47_ob_egressport;
        ig_intr_tm_md.qid = queue;
    }

    table assignOutboundEportTbl {
        key = {
            ig_intr_md.ingress_port : exact;
            meta.l47_ob_egressport: exact;
        }
        actions = {
            assignEPort;
            NoAction;
        }
        default_action = NoAction;
        size = 64;
    }

    action collapse_rx_tstamp(){
      collapsed_rx_mac = identityHash32_rx.get({ingress_mac_timestamp[31:16]});
    }

    action mpls_1()
   {
      mpls_offset = 1;
   }

   action mpls_2()
   {
      mpls_offset = 2;
   }

   action mpls_3()
   {
      mpls_offset = 3;
   }

   action mpls_4()
   {
      mpls_offset = 4;
   }

   action mpls_5()
   {
      mpls_offset = 5;
   }

   action mpls_0()
   {
      mpls_offset = 0;
   }

   table mapMplsTbl {
        key = {
         hdr.mpls_0.isValid(): ternary;
         hdr.mpls_1.isValid(): ternary;
         hdr.mpls_2.isValid(): ternary;
         hdr.mpls_3.isValid(): ternary;
         hdr.mpls_4.isValid(): ternary;
        }
        actions = {
         mpls_1;
         mpls_2;
         mpls_3;
         mpls_4;
         mpls_5;
         mpls_0;
        }
        const entries = {
         ( true, false, false, false, false ): mpls_1;
         ( _, true, false, false, false ): mpls_2;
         ( _, _, true, false, false ): mpls_3;
         ( _, _, _, true, false ): mpls_4;
         ( _, _, _, _, true ): mpls_5;
         ( false, false, false, false, false ): mpls_0;
        }
   }

   action mark_normal()
    {
      hdr.bridge.pkt_type = PKT_TYPE_NORMAL;
      hdr.bridge.l47_timestamp_insert = 1w1;
    }

    action mark_bypass()
    {
       hdr.bridge.pkt_type = PKT_TYPE_SKIP_EGRESS;
       hdr.bridge.l47_timestamp_insert = 1w0;
       //ig_intr_tm_md.bypass_egress = 1;
    }

    table mapBypassEgressTbl {
        key = {
            hdr.l47_tstamp.isValid(): exact;
            hdr.first_payload.isValid(): exact;
        }
        actions = {
            mark_bypass;
            mark_normal;
        }
        const entries = {
           (true, false): mark_normal;
           (false, true): mark_normal;
           (false, false): mark_bypass;
           (true, true): mark_bypass;
        }
   }

    action map_bank(bit<1> bank)
    {
        meta.bank_bit = bank;
    }

    table mapBankBitTbl {
        actions = {
            map_bank;
        }
        //default_action = map_bank;
    }

    action map_stream(bit<1> bank)
    {
        meta.stream_bit = bank;
    }

    table mapStreamBitTbl {
        actions = {
            map_stream;
        }
        //default_action = map_bank;
    }

    action count_latency_stats(stats_index_t index)
    {
        banked_index = index;
    }

    table countl47Table {
        key = {
            stat_index: exact;
            ig_intr_md.ingress_port : exact;
        }
        actions = {
            count_latency_stats;
            NoAction;
        }
        default_action = NoAction;
        size = 1<<13;
    }

    action map_port_indexA(bit<6> index)
    {
        banked_port_statsA.count(index);
    }

    table bankedPortTableA {
        key = {
            ig_intr_md.ingress_port : exact;
        }
        actions = {
            map_port_indexA;
            NoAction;
        }
        default_action = NoAction;
        size = 64;
    }

    action map_port_indexB(bit<6> index)
    {
        banked_port_statsB.count(index);
    }

    table bankedPortTableB {
        key = {
            ig_intr_md.ingress_port : exact;
        }
        actions = {
            map_port_indexB;
            NoAction;
        }
        default_action = NoAction;
        size = 64;
    }

    action do_set_egress_group(bit<3> group) {
        hdr.bridge.capture_group = group;
        egress_capture_group[5:3] = group;
    }

    table set_egress_group {
        key = {
            ig_intr_tm_md.ucast_egress_port : exact;
        }
        actions = { do_set_egress_group; }
        size = 512;
    }

    action set_rich_bridge()
    {
        hdr.bridge.rich_register = egress_rich_register[2:0];
    }

/***************************************************
  /*
   * main execution body for ingress pipeline
   */
  apply
    {
        ingress_cmp.apply(g_intr_md, meta, rich_register);
        truncate_rx_tstamp();
        mapMplsTbl.apply();
        mapBankBitTbl.apply();
        mapStreamBitTbl.apply();
        if ( meta.bank_bit == 1)
            bankedPortTableA.apply();
        else
            bankedPortTableB.apply();

        ingress_metadata_map.apply(hdr, ig_intr_md, meta);
        //if input port is a l47 port
        if (meta.port_properties.port_type == 3)
        {
            l23_match = 1w0;
            assignOutboundEportTbl.apply();
            outbound_l47.apply(hdr);
            if ( hdr.bridge.pkt_type == PKT_TYPE_SKIP_EGRESS)
                hdr.bridge.l47_timestamp_insert = 1w0;
            else
            {
                mapBypassEgressTbl.apply();
            }
        }
        else
        {
            // match if signature exist in payload
            if (meta.port_properties.port_type == 2)
                match_signature();
            else
            {
                checkSignatureTbl.apply();
            }
            //ingress_metadata_map.apply(hdr, ig_intr_md, meta);
            //calculate hash based on packet headers
            calculate_hash.apply(hdr, meta, sel_hash);
            //lookup egress port and queue parameters for l47
            inbound_l47_gen_lookup.apply(hdr, ig_intr_md, ig_intr_tm_md, meta,
                queue_offset, l47_match, timestamp_calc, l47_ingress_port, prog_mod, stat_index);
            //lookup will do the mod operation
            queueModTbl.apply();
            //If L23 type packets
            if (l23_match == 1)
            {
                L23OutboundTbl.apply();
                collapse_rx_tstamp();
                assign_rx_tstamp();
            }
            else //vlan is inserted regardless of l47 match
            {
                inbound_l47_insert_vlan.apply(hdr, l47_ingress_port, final_queue, ethertype);
                multicastTbl.apply();
            }
        }
        //set egress group for capture
        set_egress_group.apply();
        egress_cmp.apply(g_intr_md, meta, egress_capture_group, egress_rich_register);
        l2_offset_map.apply(hdr, mpls_offset);
        ingressCaptureTbl.apply();
        if (match == 1w1)
            insert_seq_no();
        capture_filter.apply(hdr, ig_intr_md, meta, l23_match, l47_match);
        set_rich_bridge();
        //if it fails to match l47, multicast the packet to cpu and its default cn port
        if (timestamp_calc == 1)
        {
            countl47Table.apply();
            //calculate latency assuming it is l47 payload
            inbound_l47_calc_latency.apply(hdr, ig_intr_md, ingress_mac_timestamp, pkt_latency);
            latency_stat.apply(meta.bank_bit, banked_index, pkt_latency);
        }
    }
}
/**
 * Ingress deparser
 * @param out pkt packet to be emitted to the egress pipeline
 * @param in ig_md ingress metadata
 * @param in ig_intr_dprsr_md ingress intrinsic metadata for deparser
 * @return none
 */
control SxIngDeparser(packet_out pkt,
          inout header_t hdr,
          in ingress_metadata_t meta,
          in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    Mirror() mirror;

    apply{
        if (ig_dprsr_md.mirror_type == MIRROR_TYPE_I2E)
        {
            mirror.emit<mirror_h>(meta.mirror_session, meta.mirror);
        }
        pkt.emit(hdr);
    }
}


/************************************************************************************/
//EGRESS PIPELINE
/************************************************************************************/
parser SxEgrParser(packet_in pkt,
       out eg_header_t hdr,
       out egress_metadata_t eg_md,
       out egress_intrinsic_metadata_t eg_intr_md) {

    PacketParserEgress() pkt_parser;

    state start {
        pkt.extract(eg_intr_md); // need to extract egress intrinsic metadata
        mirror_h mirror_md = pkt.lookahead<mirror_h>();
        transition select(mirror_md.pkt_type) {
            PKT_TYPE_NORMAL : parse_bridge;
            PKT_TYPE_SKIP_EGRESS : parse_skip_egress;
            PKT_TYPE_CAPTURE : parse_capture;
            PKT_TYPE_BROADCAST : parse_broadcast;
            default : accept;
        }
    }

    // this is the packet that is mirror either from ingress or egress
    state parse_capture {
        pkt.extract(eg_md.ing_port_mirror);
        eg_md.pkt_type = PKT_TYPE_CAPTURE;
        hdr.capture.setValid();
        /*eg_md.bridge.l2_offset = eg_md.ing_port_mirror.l2_offset;
        eg_md.bridge.flags_l47_tstamp = eg_md.ing_port_mirror.flags_l47_tstamp;
        eg_md.bridge.flags_first_payload = eg_md.ing_port_mirror.flags_first_payload;
        eg_md.bridge.flags_l3_protocol = eg_md.ing_port_mirror.flags_l3_protocol;
        eg_md.bridge.setValid();
        pkt_parser.apply(pkt, hdr, eg_md);*/
        transition accept;
    }


    state parse_skip_egress {
        pkt.extract(eg_md.bridge);
        pkt.extract(hdr.ethernet);
        transition accept;
    }

    state parse_broadcast {
        pkt.extract(eg_md.bridge);
        pkt.extract(hdr.ethernet);
        pkt.extract(hdr.vlan_tag_0);
        transition accept;
    }

    state parse_bridge {
        pkt.extract(eg_md.bridge);
        pkt_parser.apply(pkt, hdr, eg_md);
        transition accept;
    }
}

/**
 * Egress pipeline
 * @param inout hdr extracted header(s)
 * @param inout eg_md egress metadata
 * @param in eg_intr_md egress intrinsic metadata
 * @param in eg_intr_prsr_md egress intrinsic metadata for parser
 * @param in eg_intr_dprsr_md egress intrinsic metadata for deparser
 * @param out eg_intr_md_for_oport egress intrinsic metadata for output port
 * @return none
 */
control SxEgrPipeline(inout eg_header_t hdr,
          inout egress_metadata_t eg_md,
          in egress_intrinsic_metadata_t eg_intr_md,
          in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
          inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
          inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    bit<32> global_tstamp;
    bit<32> collapsed_tstamp;
    Counter<bit<64>, bit<6>> (64, CounterType_t.PACKETS_AND_BYTES) banked_port_statsA;
    Counter<bit<64>, bit<6>> (64, CounterType_t.PACKETS_AND_BYTES) banked_port_statsB;
    bit<7> port_index;
    bit<16> eg_seq_no = 0;
    bit<1> match = 0;
    bit<1> match_bank_stat = 0;

    action map_bank(bit<1> bank)
    {
        eg_md.bank_bit = bank;
    }

    table mapBankBitTbl {
        actions = {
            map_bank;
        }
        //default_action = map_bank;
    }

    action map_port_indexA(bit<6> stat_index)
    {
        banked_port_statsA.count(stat_index);
    }

    table bankedPortTableA {
        key = {
            eg_intr_md.egress_port : exact;

        }
        actions = {
            map_port_indexA;
            NoAction;
        }
        default_action = NoAction;
        size = 64;
    }

    action map_port_indexB(bit<6> stat_index)
    {
        banked_port_statsB.count(stat_index);
    }

    table bankedPortTableB {
        key = {
            eg_intr_md.egress_port : exact;
        }
        actions = {
            map_port_indexB;
            NoAction;
        }
        default_action = NoAction;
        size = 64;
    }

    action map_collapsed()
    {
        collapsed_tstamp = (bit<32>)(eg_intr_md_from_prsr.global_tstamp[15:0]);
    }

    action map_timestamp()
    {
        global_tstamp = (bit<32>)(eg_intr_md_from_prsr.global_tstamp);
    }

    Register<bit<16>, bit<3>>(size=8, initial_value=0) sequence_no;
    RegisterAction<bit<16>, bit<3>, bit<16>>(sequence_no)
    update_seq_no = {
        void apply(inout bit<16> register_data, out bit<16> result)
        {
            result = register_data;
            if (register_data == 16w0x7ff)
                register_data = 0;
            else
                register_data = register_data + 1;
        }
    };

    action set_capture_mirror_session(MirrorId_t mirror_session) {
        eg_intr_md_for_dprs.mirror_type = MIRROR_TYPE_E2E;
        eg_md.mirror_session = mirror_session;
        eg_md.mirror.mac_timestamp = global_tstamp;
        eg_md.mirror.pkt_type = PKT_TYPE_CAPTURE;
        eg_seq_no = update_seq_no.execute(eg_md.bridge.capture_group);
        match = 1;

// E2E mirroring for Tofino2 & future ASICs, or you'll see extra bytes prior to ethernet
        eg_intr_md_for_dprs.mirror_io_select = 1;

  }

    table captureTbl {
        key = {
            eg_intr_md.egress_port : exact;
            eg_md.bridge.capture_group : exact;
            eg_md.bridge.rich_register : exact;
        }
        actions = {
            set_capture_mirror_session;
            NoAction;
        }
        default_action = NoAction;
        size = 32;
    }

    action set_cos_value(bit<4> pfc_cos)
    {
     hdr.vlan_tag_0.pcp_cfi = pfc_cos;
    }

    table egressMulticastCosTbl {
        key = {
            eg_intr_md.egress_port : exact;
            eg_md.bridge.ingress_port: exact;
            eg_md.bridge.pkt_type : exact;
        }
        actions = {
            set_cos_value;
            NoAction;
        }
        default_action = NoAction;
        size = 64;
    }

    action insert_capture_parity( bit<16> calculated)
    {
        hdr.capture.seq_no = calculated[11:0];
        hdr.capture.seq_no_2 = calculated[11:0];
        //hdr.capture.parity_2 = parity;
        hdr.capture.timestamp = eg_md.ing_port_mirror.mac_timestamp;
    }

    table insertOverheadTbl {
    key = {
        eg_md.ing_port_mirror.capture_seq_no : exact;
    }
    actions = {
        insert_capture_parity;
    }
      size = 2048;
    }

    action insert_seq_no()
    {
       eg_md.mirror.capture_seq_no = eg_seq_no;
    }

    /*******************************************/
    apply {
        egressMulticastCosTbl.apply();
        map_timestamp();
        map_collapsed();
        calculate_checksum.apply(eg_md, hdr, collapsed_tstamp, global_tstamp);
        //only inserting global timestamp
        //for l23, mac timestamp is inserted at ingress pipeline
        if(eg_md.bridge.l47_timestamp_insert == 1)
            outbound_l47_insert_timestamp.apply(hdr, eg_md, global_tstamp);
        else
            timestamp_insertion.apply(hdr, eg_md, global_tstamp);
        // this has to be at the end, such that egress-capture only act on
        // actual packet ( after mirrored packet appear and not the packet that
        // is being mirrored)
        if ( hdr.capture.isValid())
        {
            insertOverheadTbl.apply();
            length_filter.apply(hdr, eg_md, eg_intr_md);
        }
        else
        {
          captureTbl.apply();
          insert_seq_no();;
        }
        mapBankBitTbl.apply();
        if ( eg_md.bank_bit == 1)
            bankedPortTableA.apply();
        else
            bankedPortTableB.apply();
    }
}

/*
 * Egress deparser
 * @param out pkt packet to be emitted to the egress pipeline
 * @param inout hdr header(s) extracted
 * @param in eg_md egress metadata
 * @param in eg_intr_dprsr_md egress intrinsic metadata for deparser
 * @return none
 */
control SxEgrDeparser(packet_out pkt,
          inout eg_header_t hdr,
          in egress_metadata_t eg_md,
          in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {

    Mirror() mirror;
    apply{
        if (eg_intr_md_for_dprs.mirror_type == MIRROR_TYPE_E2E) {
            mirror.emit<mirror_h>(eg_md.mirror_session, eg_md.mirror);
        }
        pkt.emit(hdr);
    }
}

/************************************************************************************/
//GHOST thread
/************************************************************************************/

control SxQueueMonitor(in ghost_intrinsic_metadata_t g_intr_md )
{
    RegisterAction<bit<16>, bit<11>, bit<16>>(ping_reg) ping_update = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[15:0]; } };

    RegisterAction<bit<16>, bit<11>, bit<16>>(pong_reg) pong_update = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[15:0]; } };

    RegisterAction<bit<16>, bit<11>, bit<16>>(ping_egress_reg) ping_egress_update = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[15:0]; } };

    RegisterAction<bit<16>, bit<11>, bit<16>>(pong_egress_reg) pong_egress_update = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[15:0]; } };

    action ping_do_update(bit<11> idx) {
        ping_update.execute(idx);
    }

    @stage(1)
    table ping_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            ping_do_update;
        }
        size = 2048;
    }

    action pong_do_update(bit<11> idx) {
        pong_update.execute(idx);
    }

    @stage(1)
    table pong_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            pong_do_update;
        }
        size = 2048;
    }

    action eg_ping_do_update(bit<11> idx) {
        ping_egress_update.execute(idx);
    }

    @stage(8)
    table eg_ping_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            eg_ping_do_update;
        }
        size = 2048;
    }
    action eg_pong_do_update(bit<11> idx) {
        pong_egress_update.execute(idx);
    }

    @stage(8)
    table eg_pong_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            eg_pong_do_update;
        }
        size = 2048;
    }
    apply {
        if (g_intr_md.ping_pong == 1) {
            ping_update_tbl.apply();
            eg_ping_update_tbl.apply();
        } else {
            pong_update_tbl.apply();
            eg_pong_update_tbl.apply();
        }
    }
}
/*
 * Pipeline construction
 */

Pipeline(SxIngParser(), SxIngPipeline(), SxIngDeparser(), SxEgrParser(),
  SxEgrPipeline(), SxEgrDeparser(), SxQueueMonitor()) pipe;
Switch(pipe) main;
