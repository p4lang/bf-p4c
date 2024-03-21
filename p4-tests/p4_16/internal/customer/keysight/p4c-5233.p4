#include <t2na.p4>

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
const ether_type_t ETHERTYPE_LLDP = 16w0x88cc;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_IGMP = 2;
const ip_protocol_t IP_PROTOCOLS_IPV4 = 4;
const ip_protocol_t IP_PROTOCOLS_IPV6 = 41;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;
const ip_protocol_t IP_PROTOCOLS_OSPF = 89;
const ip_protocol_t IP_PROTOCOLS_GRE = 47;
const ip_protocol_t IP_PROTOCOLS_ICMPv6 = 58;
typedef bit<32> signature_t;
const signature_t L23_SIGNATURE_TOP = 0xC0DEFACE;
const signature_t L23_SIGNATURE_BOT = 0xCAFE0000;
const signature_t L47_SIGNATURE_TOP = 0x0101080a;

//v6 options
const ip_protocol_t IP6_HBH = 0;
const ip_protocol_t IP6_ROUTING = 43;
const ip_protocol_t IP6_FRAGMENT = 44;
const ip_protocol_t IP6_DESTINATION = 60;
const ip_protocol_t IP6_AUTHENTICATION = 51;
const ip_protocol_t IP6_SECURITY = 50;
const ip_protocol_t IP6_MOBILITY = 135;

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

struct range_pair {
    bit<32> start;
    bit<32> end;
}

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

header mpls5_h {
    bit<20> label0;
    bit<3> exp0;
    bit<1> bos0;
    bit<8> ttl0;

    bit<20> label1;
    bit<3> exp1;
    bit<1> bos1;
    bit<8> ttl1;

    bit<20> label2;
    bit<3> exp2;
    bit<1> bos2;
    bit<8> ttl2;

    bit<20> label3;
    bit<3> exp3;
    bit<1> bos3;
    bit<8> ttl3;
}

header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header mpls_n_h {
    bit<16> mpls_all;
    bit<8> ttl;
}

header ipv4_h {
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<16> flags_frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header ip46_h {
   bit<4> version;
   bit<4> hdrlength;
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

header ipv6_extension_header_h{
    bit<8> next_hdr;
    bit<8> header_length;
    bit<48> option_header;
}

header ipv6_options_header_h{
    varbit<16384> options;
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
    bit<16> udp_length;
    bit<16> checksum;
}

header icmp_h {
    bit<8> type_;
    bit<8> code;
    bit<16> hdr_checksum;
    bit<32> id_seq_number;
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
    bit<32> seq_num_options;
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
}

header l23rxtimetsamp_h{
    bit<16> rx_timestamp;
}

header l23signature_option_h {

    bit<16> pgid;
    bit<16> sequence;
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

@preamble
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
    bit<1> trigger;
    bit<1> filter;
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

header ipv4_options_h {
    varbit<320> options;
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
    bit<1> l23_match;
    bit<8> engine_id;
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
    bit<1> l47_tcp;
    bit<1> cpu_lldp;
    MirrorId_t mirror_session;
    mirror_h mirror;
    bit<4> v4options_count;
    bit<4> innerv4options_count;
    bit<1> bank_bit;
}

struct rich_pair {
    bit<16> first;
    bit<16> second;
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
    snap_h snap;
    vlan_tag_h vlan_tag_0;
    vlan_tag_h vlan_tag_1;
    vlan_tag_h vlan_tag_2;
    mpls_h mpls_0;
    mpls_h mpls_1;
    mpls_h mpls_2;
    mpls_h mpls_3;
    mpls_h mpls_4;
    ip46_h ip_version_0;
    ipv4_h ipv4;
    ipv4_options_h ipv4_options;
    ipv6_h ipv6;
    icmp_h icmp;
    gre_h gre;
    grechecksum_h gre_checksum;
    tcp_h tcp;
    udp_h udp;
    gtpv1_h gtp1;
    ip46_h inner_ip_version;
    ipv4_h inner_ipv4;
    ipv4_options_h inner_ipv4_options;
    ipv6_h inner_ipv6;
    tcp_h inner_tcp;
    udp_h inner_udp;
    l47_tstamp_h l47_tstamp;
    l23signature_h first_payload;
    l23rxtimetsamp_h rx_timestamp;
    // Add more headers here.
}

struct eg_header_t {
    example_bridge_h bridge;
    capture_h capture;
    ethernet_h ethernet;
    snap_h snap;
    vlan_tag_h vlan_tag_0;
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
    ipv4_h ipv4;
    ipv4_options_h ipv4_options;
    ipv6_h ipv6;
    icmp_h icmp;
    gre_h gre;
    grechecksum_h gre_checksum;
    tcp_h tcp;
    udp_h udp;
    gtpv1_h gtp1;
    ip46_h inner_ip_version;
    ipv4_h inner_ipv4;
    ipv4_options_h inner_ipv4_options;
    ipv6_h inner_ipv6;
    tcp_h inner_tcp;
    udp_h inner_udp;
    l47_tstamp_h l47_tstamp;
    l23signature_h first_payload;
    l23rxtimetsamp_h rx_timestamp;
    l23signature_option_h l23_option;
    // Add more headers here.
}

@stage(1)
Register<bit<16>, bit<11>>(32) ping_reg;
@stage(9)
Register<bit<16>, bit<11>>(32) ping_egress_reg;
@stage(1)
Register<bit<16>, bit<11>>(32) pong_reg;
@stage(9)
Register<bit<16>, bit<11>>(32) pong_egress_reg;

@stage(2)
Register<bit<16>, bit<11>>(32) ping_reg2;
@stage(10)
Register<bit<16>, bit<11>>(32) ping_egress_reg2;
@stage(2)
Register<bit<16>, bit<11>>(32) pong_reg2;
@stage(10)
Register<bit<16>, bit<11>>(32) pong_egress_reg2;

@stage(3)
Register<bit<16>, bit<11>>(32) ping_reg3;
@stage(12)
Register<bit<16>, bit<11>>(32) ping_egress_reg3;
@stage(3)
Register<bit<16>, bit<11>>(32) pong_reg3;
@stage(12)
Register<bit<16>, bit<11>>(32) pong_egress_reg3;
// dummy

@stage(4)
Register<bit<32>, bit<1>>(1) gt_stage4;
@stage(5)
Register<bit<32>, bit<1>>(1) gt_stage5;
@stage(6)
Register<bit<32>, bit<1>>(1) gt_stage6;
@stage(7)
Register<bit<32>, bit<1>>(1) gt_stage7;
@stage(8)
Register<bit<32>, bit<1>>(1) gt_stage8;
/*!
 * @file packet_parser_ingress.p4
 * @brief  main functions for Eagle switch.
 * @author
 * @date
 */
parser PacketParserIngress(packet_in pkt,
                    out header_t hdr,
                    out ingress_metadata_t meta,
                    out ingress_intrinsic_metadata_t ig_intr_md) {
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
        meta.v4options_count = 0;
        meta.innerv4options_count = 0;
        // initialize bridge header
        hdr.bridge.setValid();
        hdr.bridge.l47_timestamp_insert = 0;
        hdr.bridge.l23_txtstmp_insert = 0;
        hdr.bridge.l23_rxtstmp_insert = 0;
        hdr.bridge.l2_offset = 0;
        transition parseEthernet;
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
            ETHERTYPE_IPV4: parseIp;
            ETHERTYPE_IPV6: parseIpv6;
            ETHERTYPE_ARP: parseAccept;
            ETHERTYPE_LLDP: parseCPU;
            default: parseL23;
        }
    }

    state parseCPU {
        meta.cpu_lldp = 1;
        transition accept;
    }

    state parseSnapHeader {
        pkt.extract(hdr.snap);
        transition select(hdr.snap.ether_type) {
            ETHERTYPE_MPLS_UNICAST: parseMpls;
            ETHERTYPE_MPLS_MULTICAST: parseMpls;
            ETHERTYPE_IPV4: parseIp;
            ETHERTYPE_IPV6: parseIpv6;
            ETHERTYPE_ARP: parseAccept;
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
            ETHERTYPE_IPV4: parseIp;
            ETHERTYPE_IPV6: parseIpv6;
            ETHERTYPE_ARP: parseAccept;
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
            ETHERTYPE_IPV4: parseIp;
            ETHERTYPE_IPV6: parseIpv6;
            ETHERTYPE_ARP: parseAccept;
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
            ETHERTYPE_IPV4: parseIp;
            ETHERTYPE_IPV6: parseIpv6;
            ETHERTYPE_ARP: parseAccept;
            default: parseL23;
        }
    }

    state parseMpls {
        bit<1> bos0 = pkt.lookahead<mpls5_h>().bos0;
        bit<1> bos1 = pkt.lookahead<mpls5_h>().bos1;
        bit<1> bos2 = pkt.lookahead<mpls5_h>().bos2;
        bit<1> bos3 = pkt.lookahead<mpls5_h>().bos3;
        pkt.extract(hdr.mpls_0);
        transition select(bos0, bos1, bos2, bos3) {
            (1, _, _, _) : parseIp;
            (0, 1, _, _) : parseMpls1;
            (0, 0, 1, _) : parseMpls2;
            (0, 0, 0, 1) : parseMpls3;
            default: parseMpls4Check;
        }
    }
    // have to split to 2, it error with one more bit above
    state parseMpls4Check {
        bit<1> bos3 = pkt.lookahead<mpls5_h>().bos3;
        transition select(bos3) {
            (1) : parseMpls4;
            default: parseIp;
        }
    }

    state parseMpls1 {
        pkt.extract(hdr.mpls_1);
        transition parseIp;
    }

    state parseMpls2 {
        pkt.extract(hdr.mpls_1);
        pkt.extract(hdr.mpls_2);
        transition parseIp;
    }

    state parseMpls3 {
        pkt.extract(hdr.mpls_1);
        pkt.extract(hdr.mpls_2);
        pkt.extract(hdr.mpls_3);
        transition parseIp;
    }

    state parseMpls4 {
        pkt.extract(hdr.mpls_1);
        pkt.extract(hdr.mpls_2);
        pkt.extract(hdr.mpls_3);
        pkt.extract(hdr.mpls_4);
        transition parseIp;
    }

     state parseIp {
        bit<4> version = pkt.lookahead<ip46_h>().version;
        transition select(version) {
          (4w0x4): parseMplsIpv4;
          (4w0x6): parseIpv6;
          default: parseL23;
        }
    }

    state parseMplsIpv4 {
        pkt.extract(hdr.ip_version_0);
        pkt.extract(hdr.ipv4);
        pkt.extract(hdr.ipv4_options, (bit<32>)(hdr.ip_version_0.hdrlength - 5)*32 );
        transition select(hdr.ipv4.protocol, hdr.ipv4.total_len) {
            (IP_PROTOCOLS_GRE, _): parseGre;
            (IP_PROTOCOLS_IPV6, _): parseInnerIpv6;
            (IP_PROTOCOLS_TCP, _): parseTcpv4;
            (IP_PROTOCOLS_UDP, _ ): parseUdp;
            (IP_PROTOCOLS_ICMP, _): parseIcmp;
            (_, 16w0x10 &&& 16w0xfff0): parseAccept;
            (_, 16w0x2a &&& 16w0xfffa): parseL23;
            (_, 16w0x28 &&& 16w0xfffc): parseAccept;
            (_, 16w0x20 &&& 16w0xfffc): parseAccept;
            default: parseL23;
        }
    }

    state parseIpv6 {
        pkt.extract(hdr.ip_version_0);
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr, hdr.ipv6.payload_len) {
            (IP_PROTOCOLS_GRE, _): parseGre;
            (IP_PROTOCOLS_IPV4, _): parseInnerIpv4;
            (IP_PROTOCOLS_ICMPv6, _): parseIcmp;
            (IP_PROTOCOLS_UDP, _): parseUdp;
            (IP_PROTOCOLS_TCP, 16w0x10 &&& 16w0xfff8) : parseTcpAccept;
            (IP_PROTOCOLS_TCP, 16w0x18 &&& 16w0xfff8) : parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x20 &&& 16w0x20): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x40 &&& 16w0x40): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x80 &&& 16w0x80): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x100 &&& 16w0x100): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x200 &&& 16w0x200): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x400 &&& 16w0x400): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x800 &&& 16w0x800): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x1000 &&& 16w0x1000): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x2000 &&& 16w0x2000): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x4000 &&& 16w0x4000): parseTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x8000 &&& 16w0x8000): parseTcpv4;
            (_, 16w0x18 &&& 16w0xfff8) : parseL23;
            (_, 16w0x10 &&& 16w0xfff8) : parseAccept;
            default: parseL23;
        }
    }

    state parseTcpv4 {
        pkt.extract(hdr.tcp);
        bit<32> signature = pkt.lookahead<l23signature_h>().signature_top;
        transition select(signature) {
            (L47_SIGNATURE_TOP): parseL47;
            (L23_SIGNATURE_TOP): parseL23;
            default : accept;
        }
    }


    state parseTcpAccept {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parseIcmp {
        pkt.extract(hdr.icmp);
        pkt.extract(hdr.first_payload);
        meta.engine_id = hdr.first_payload.signature_bot[23:16];
        transition accept;
    }

    state parseUdp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port, hdr.udp.udp_length) {
            (PORT_GTP, _): parseGtpv1;
            (_, 0x10 &&& 0xfff8): parseUdpOpt;
            (_, 0x18 &&& 0xfffe): parseUdpOpt;
           // (_, 0x1a &&& 0xfffa): parseL23;
            (_, 0x00 &&& 0xfff0): parseAccept;
            default: parseL23;
        }
    }

    state parseUdpOpt {
        pkt.extract(hdr.l47_tstamp);
        transition accept;
    }

    state parseGtpv1{
        pkt.extract(hdr.gtp1);
        transition select(pkt.lookahead<ip46_h>().version) {
            4w0x4: parseInnerIpv4;
            4w0x6: parseInnerIpv6;
            default: accept;
        }
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
        transition parseInnerIpv6;
    }

    state parseGrechecksumIpv4 {
        pkt.extract(hdr.gre_checksum);
        transition parseInnerIpv4;
    }

    state parseInnerUdpOpt {
        pkt.extract(hdr.inner_udp);
        pkt.extract(hdr.l47_tstamp);
        transition accept;
    }

    state parseInnerIpv6 {
        pkt.extract(hdr.inner_ip_version);
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr, hdr.inner_ipv6.payload_len) {
            // for particular inner decode
            (IP_PROTOCOLS_TCP, 16w0x10 &&& 16w0xfff ) : parseInnerTcpAccept;
            (IP_PROTOCOLS_TCP, 16w0x18 &&& 16w0xfff8) : parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x20 &&& 16w0x20): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x40 &&& 16w0x40): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x80 &&& 16w0x80): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x100 &&& 16w0x100): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x200 &&& 16w0x200): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x400 &&& 16w0x400): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x800 &&& 16w0x800): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x1000 &&& 16w0x1000): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x2000 &&& 16w0x2000): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x4000 &&& 16w0x4000): parseInnerTcpv4;
            (IP_PROTOCOLS_TCP, 16w0x8000 &&& 16w0x8000): parseInnerTcpv4;
            (IP_PROTOCOLS_UDP, _): parseInnerUdp;
            (_, 16w0x18 &&& 16w0xfff8) : parseL23;
            (_, 16w0x10 &&& 16w0xfff8) : parseAccept;
            default: parseL23;
        }
    }

    state parseInnerIpv4 {
        pkt.extract(hdr.inner_ip_version);
        pkt.extract(hdr.inner_ipv4);
        pkt.extract(hdr.inner_ipv4_options, (bit<32>)(hdr.inner_ip_version.hdrlength - 5)*32 );
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.total_len) {
            (IP_PROTOCOLS_TCP, _): parseInnerTcpv4;
            (IP_PROTOCOLS_UDP, _): parseInnerUdp;
            (_, 16w0x10 &&& 16w0xfff0) : parseAccept;
            (_, 16w0x2c &&& 16w0xfffc) : parseL23;
            (_, 16w0x28 &&& 16w0xfffc) : parseAccept;
            (_, 16w0x20 &&& 16w0xfffc) : parseAccept;
            default: parseL23;
        }
    }

    state parseInnerTcpv4 {
        pkt.extract(hdr.inner_tcp);
        bit<32> signature = pkt.lookahead<l23signature_h>().signature_top;
        transition select(signature) {
            (L47_SIGNATURE_TOP): parseL47;
            (L23_SIGNATURE_TOP): parseL23;
            default : accept;
        }
    }

    state parseInnerTcpAccept {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parseInnerUdp {
        pkt.extract(hdr.inner_udp);
        transition select(hdr.inner_udp.udp_length) {
            (0x10 &&& 0xfff8): parseUdpOpt;
            (0x18 &&& 0xfffe): parseUdpOpt;
            (0x08 &&& 0xfff0): parseAccept;
            default: parseL23;
        }
    }

    state parseL23 {
        pkt.extract(hdr.first_payload);
        pkt.extract(hdr.rx_timestamp);
        meta.engine_id = hdr.first_payload.signature_bot[23:16];
        transition accept;
    }

    state parseL47 {
        pkt.extract(hdr.first_payload);
        transition accept;
    }

    state parseAccept {
        transition accept;
    }
}
/*!
 * @file packet_parser_egress.p4
 * @brief  main functions for Eagle switch.
 * @author
 * @date
 */
parser PacketParserEgress(packet_in pkt,
                    inout eg_header_t hdr, inout egress_metadata_t eg_md ) {
    state start {
        pkt.extract(hdr.ethernet);
        transition select(eg_md.bridge.l2_offset) {
            (1): parseHeaders1;
            (2): parseHeaders2;
            (3): parseHeaders3;
            (4): parseHeaders4;
            (5): parseHeaders5;
            (6): parseHeaders6;
            (7): parseHeaders7;
            (8): parseHeaders8;
            (9): parseHeaders9;
        default: parse_headers;
        }
    }

    state parseHeaders1 {
        pkt.extract(hdr.skip_l2_1);
        transition parse_headers;
    }

    state parseHeaders2 {
        pkt.extract(hdr.skip_l2_2);
        transition parse_headers;
    }

    state parseHeaders3 {
        pkt.extract(hdr.skip_l2_3);
        transition parse_headers;
    }

    state parseHeaders4 {
        pkt.extract(hdr.skip_l2_4);
        transition parse_headers;
    }

    state parseHeaders5 {
        pkt.extract(hdr.skip_l2_5);
        transition parse_headers;
    }

    state parseHeaders6 {
        pkt.extract(hdr.skip_l2_6);
        transition parse_headers;
    }

    state parseHeaders7 {
        pkt.extract(hdr.skip_l2_7);
        transition parse_headers;
    }

    state parseHeaders8 {
        pkt.extract(hdr.skip_l2_8);
        transition parse_headers;
    }

    state parseHeaders9 {
        pkt.extract(hdr.skip_l2_9);
        transition parse_headers;
    }

    state parse_headers {
        transition select(pkt.lookahead<ip46_h>().version) {
            (4): parseIpv4;
            (6): parseIpv6;
            default: parsel23payload;
        }
    }

    state parseIpv4Payload {
        transition select(eg_md.bridge.flags_l3_protocol) {
            1 : parseUdp;
            2 : parseTcp;
            3 : parseGre;
            4 : parseGtp;
            6 : parseInnerIpv6;
            7 : parseIcmp;
            default: parseL23;
        }
    }

    state parseIpv4 {
        pkt.extract(hdr.ip_version);
        pkt.extract(hdr.ipv4);
        pkt.extract(hdr.ipv4_options, (bit<32>)(hdr.ip_version.hdrlength - 5)*32 );
        transition parseIpv4Payload;
    }

    state parseIpv6 {
        pkt.extract(hdr.ip_version);
        pkt.extract(hdr.ipv6);
        transition select(eg_md.bridge.flags_l3_protocol) {
            (1): parseUdp;
            (4): parseGtp;
            (7): parseIcmp;
            (2): parseTcp;
            (3): parseGre;
            (5): parseInnerIpv4;
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
        transition select(eg_md.bridge.l47_timestamp_insert, eg_md.bridge.l23_txtstmp_insert)
        {
            (1w1, 1w0): parseL23;
            (1w0, 1w1): parseL23;
            default: accept;
        }
    }

     state parseIcmp {
        pkt.extract(hdr.icmp);
        pkt.extract(hdr.first_payload);
        transition accept;
    }

    state parseUdp {
        pkt.extract(hdr.udp);
        transition select(eg_md.bridge.l47_timestamp_insert, eg_md.bridge.l23_txtstmp_insert)
        {
            (1w1, 1w0): parseL47tstamp;
            (1w0, 1w1): parseL23Timestamp;
            default: accept;
        }
    }

    state parseL23Timestamp {
        pkt.extract(hdr.first_payload);
        pkt.extract(hdr.rx_timestamp);
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
      pkt.extract(hdr.inner_ipv4_options, (bit<32>)(hdr.inner_ip_version.hdrlength - 5)*32 );
      transition select(hdr.inner_ipv4.protocol,
        eg_md.bridge.l47_timestamp_insert,
        eg_md.bridge.l23_txtstmp_insert) {
        (IP_PROTOCOLS_TCP, 1w1, 1w0): parseInnerTcp;
        (IP_PROTOCOLS_TCP, 1w0, 1w1): parseInnerTcpL23Timestamp;
        (IP_PROTOCOLS_UDP, 1w0, 1w1): parseInnerUdpL23Timestamp;
        (IP_PROTOCOLS_UDP, 1w1, 1w0): parseInnerUdp;
        (_, 1w1, 1w0): parseFirstPayload;
        (_, 1w1, 1w1): parseL23Timestamp;
        default: accept;
      }
    }

    state parseInnerIpv6 {
      pkt.extract(hdr.inner_ip_version);
      pkt.extract(hdr.inner_ipv6);
      transition select(hdr.inner_ipv6.next_hdr,
        eg_md.bridge.l47_timestamp_insert,
        eg_md.bridge.l23_txtstmp_insert) {
        (IP_PROTOCOLS_TCP, 1w1, 1w0): parseInnerTcp;
        (IP_PROTOCOLS_TCP, 1w0, 1w1): parseInnerTcpL23Timestamp;
        (IP_PROTOCOLS_UDP, 1w0, 1w1): parseInnerUdpL23Timestamp;
        (IP_PROTOCOLS_UDP, 1w1, 1w0): parseInnerUdp;
        (_, 1w1, 1w0): parseFirstPayload;
        (_, 1w0, 1w1): parseL23Timestamp;
        default: accept;
      }
    }

    state parseInnerTcpL23Timestamp {
        pkt.extract(hdr.inner_tcp);
        transition parsel23payload;
    }

    state parseInnerUdpL23Timestamp{
        pkt.extract(hdr.inner_udp);
        transition parsel23payload;
    }

    state parseInnerTcp {
        pkt.extract(hdr.inner_tcp);
        pkt.extract(hdr.first_payload);
        transition accept;
    }

    state parsel23payload {
        pkt.extract(hdr.first_payload);
        pkt.extract(hdr.rx_timestamp);
        pkt.extract(hdr.l23_option);
        transition accept;
    }

    state parseInnerUdp{
        pkt.extract(hdr.inner_udp);
        pkt.extract(hdr.first_payload);
        transition accept;
    }
}
//#include "hash_generator.p4"
/*!
 * @file outbound_l47.p4
 * @brief Remove MPLS (overhead) labels and sends the packet out
 */







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
    else {
      if (hdr.first_payload.isValid()) {
        //insert_compute_node_timestampTbl.apply();
        if (hdr.inner_tcp.isValid() || hdr.tcp.isValid()) {
          insert_tcp_timestamp();
        }
        else if (hdr.inner_udp.isValid() || hdr.udp.isValid() || hdr.icmp.isValid()) {
          insert_udp_timestamp();
        }
      }
    }

  }
}
/*!
 * @file inbound_l47.p4
 * @brief lookup table for queue range, queue offset and queue mask
 */
control inbound_l47_gen_lookup(inout header_t hdr,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
        in ingress_metadata_t meta,
        in bit<16> ethertype,

        out bit<1> l47_match,
        out bit<1> timestamp_calc,
        out stats_index_t stat_index) {

  const bit<32> table_sz = 8192;// 16384 if we do exact match with SRAM
  stats_index_t index = 0;
  // need to implement 8K for v4 range, 2K or v6 range
  bit<9> lookup_5;
  bit<11> lookup_6;
  bit<14> lookup_7;
  bit<16> remap_addr_0 = 0;
  bit<16> remap_addr_1 = 0;
  bit<16> remap_addr_2 = 0;
  bit<16> remap_addr_3 = 0;
  bit<16> remap_addr_4 = 0;
  bit<16> remap_addr_5 = 0;
  bit<16> remap_addr_6;
  bit<16> remap_addr_7;
  bit<16> ternary_match_6 = 0;
  bit<1> mac_match = 0;
  bit<32> range_addr = 0;
  bit<16> range_result = 0;
  bit<16> range_result_2 = 0;
  bit<1> skip_range = 0;
  bit<4> ingress_cos = 0;
  bit<4> ingress_cos2 = 0;
  bit<1> timestamp_calc_local;
  PortId_t local_mac_egPort;
  PortId_t local_ip_egPort;
  stats_index_t stat_index_local;

  Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identity_hash32_l;
  Register<range_pair, bit<16>>(size=1<<13, initial_value={0, 0}) range_reg;
  RegisterAction<range_pair, bit<16>, bit<16>>(range_reg)
  compare_range = {
      void apply(inout range_pair value, out bit<16> rv) {
          rv = this.predicate(value.start > range_addr, value.end < range_addr);
      }
   };

  Register<range_pair, bit<16>>(size=1<<11, initial_value={0, 0}) mac_range_reg;
  RegisterAction<range_pair, bit<16>, bit<16>>(mac_range_reg)
  compare_range2 = {
      void apply(inout range_pair value, out bit<16> rv) {
          rv = this.predicate(value.start > hdr.ethernet.dst_addr[31:0], value.end < hdr.ethernet.dst_addr[31:0]);
      }
   };
 /**********************************/

  action map_v6_address() {
    remap_addr_0 = meta.ipv6_dst_127_96[31:16];
    remap_addr_1 = meta.ipv6_dst_127_96[15:0];
    remap_addr_2 = meta.ipv6_dst_95_64[31:16];
    remap_addr_3 = meta.ipv6_dst_95_64[15:0];
    remap_addr_4 = meta.ipv6_dst_63_32[31:16];
    remap_addr_5 = meta.ipv6_dst_63_32[15:0];
    remap_addr_6 = meta.ip_dst_31_0[31:16];
    remap_addr_7 = meta.ip_dst_31_0[15:0];
  }

  action setMacRangePort( bit<1> timestamp_ext, PortId_t egPort,
    stats_index_t stats_index, bit<4> pfc_cos, bit<16> match_index)
  {
    timestamp_calc_local = timestamp_ext;
    stat_index_local = stats_index;
    ingress_cos = pfc_cos;
    range_result = compare_range2.execute(match_index);
    local_mac_egPort = egPort;
    mac_match = 1;
  }

  action setQueue()
  {
    timestamp_calc_local = 0;
    stat_index_local = 0;
    index = 0;
    local_mac_egPort = 0;
    mac_match = 0;
  }

  table EgressMacRangeCnTbl {
    key = {
      meta.vid_top : exact;
      meta.vid_bot : exact;
      hdr.vlan_tag_0.isValid(): exact;
      hdr.ethernet.dst_addr[47:32] : exact;
      hdr.ethernet.dst_addr[31:16] : ternary;
      hdr.ethernet.dst_addr[15:0] :ternary;
      ig_intr_md.ingress_port : exact;
    }
    actions = {
      setMacRangePort;
      setQueue;
    }
    default_action = setQueue;
    size = 2048;
  }

  action map_ternary( bit<16> match_index ) {
     ternary_match_6 = match_index;
  }

  table EgressTernaryTbl {
    key = {
      remap_addr_6 : ternary;
      remap_addr_7 : ternary;
      hdr.vlan_tag_0.isValid(): exact;
      ig_intr_md.ingress_port : exact;
    }
    actions = {
       map_ternary;
       NoAction;
    }
    default_action = NoAction;
    size = 8192;
  }

  action setRangePort( bit<1> timestamp_ext, PortId_t egPort,
    stats_index_t stats_index, bit<4> pfc_cos )
  {
    timestamp_calc = timestamp_ext;
    stat_index = stats_index;
    ingress_cos2 = pfc_cos;
    range_result_2 = compare_range.execute(ternary_match_6);
    local_ip_egPort = egPort;
  }

  action setQueue2()
  {
    timestamp_calc = timestamp_calc_local;
    stat_index = stat_index_local;
    ingress_cos2 = ingress_cos;
    range_result_2 = range_result;
    local_ip_egPort = local_mac_egPort;
  }

  table EgressRangeCnTbl {
    key = {
      meta.vid_top : exact;
      meta.vid_bot : exact;
      hdr.vlan_tag_0.isValid(): exact;
      remap_addr_0 : exact;
      remap_addr_1 : exact;
      remap_addr_2 : exact;
      remap_addr_3 : exact;
      remap_addr_4 : exact;
      remap_addr_5 : exact;
      ternary_match_6: exact;
      ig_intr_md.ingress_port : exact;
      mac_match : exact;
    }
    actions = {
      setRangePort;
      setQueue2;
    }
    default_action = setQueue2;
    size = 8192;
  }

  action matchRangeEport()
  {
    l47_match = 1;
    ig_intr_tm_md.ucast_egress_port = local_ip_egPort;
  }

  action matchRangeWithVlan()
  {
    matchRangeEport();
    hdr.vlan_tag_0.pcp_cfi = ingress_cos2;
  }

 action matchRangeInsertVlan()
  {
    matchRangeEport();
    hdr.ethernet.ether_type = 0x8100;
    hdr.vlan_tag_0.setValid();
    hdr.vlan_tag_0.vlan_top = 0xf;
    hdr.vlan_tag_0.vlan_bot = 0xff;
    hdr.vlan_tag_0.pcp_cfi = ingress_cos2;
    hdr.vlan_tag_0.ether_type = ethertype;
  }

  table EgressRangecompare {
    key = {
      range_result_2 : exact;
      hdr.vlan_tag_0.isValid(): exact;
    }
    actions = {
      matchRangeInsertVlan;
      matchRangeWithVlan;
      matchRangeEport;
      NoAction;
    }
    default_action = NoAction;
    size = 4;
  }

  /******************************/
  apply
  {
    map_v6_address();
    range_addr = identity_hash32_l.get({remap_addr_6 +++ remap_addr_7});
    EgressMacRangeCnTbl.apply();
    EgressTernaryTbl.apply();
    EgressRangeCnTbl.apply();
    EgressRangecompare.apply();
  }
}

control inbound_l47_insert_vlan(inout header_t hdr, in bit<16> ethertype) {

  action map_ethertype()
  {
    hdr.vlan_tag_0.ether_type = ethertype;
    hdr.vlan_tag_0.vlan_top = 0xf;
    hdr.vlan_tag_0.vlan_bot = 0xff;
  }
  // push vlan label as the first label then swap the ethertype 
  action insertVlanOverhead() {
    hdr.ethernet.ether_type = 0x8100;
    hdr.vlan_tag_0.setValid();
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
    else if (hdr.inner_udp.isValid() || hdr.udp.isValid() || hdr.icmp.isValid())
    {
        calc_udp_timestamp();
    }
  }
}
/*!
 * @file timestamp.p4
 * @brief insert timestamp for L23
 */







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
/*!
 * @file latency_stat.p4
 * @brief latency_statistic calculation
 */







control l47_latency_flow_stat(in bit<1> first_pkt, in stats_index_t stat_index,
                      in bit<32> latency )(bit<32> num_stats) {
   @KS_stats_service_counter(Latency, eagle_counters)
   @KS_stats_service_columns(sum)
   @KS_stats_service_units(ns)
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

   /*RegisterAction<lat_tot_layout, stats_index_t, bit<32>>(data_storage)
   first_data = {
      void apply(inout lat_tot_layout value) {
         lat_tot_layout register_data;
         register_data = value;
         value.lo = latency;
         value.hi = 0;
       }
   };*/

  /***************************************************/
  apply
   {
      //if (first_pkt == 1w0)
      //  first_data.execute(stat_index);
      //else
      write_data.execute(stat_index);
   }
}

control latency_stat( in bit<1> bank, in stats_index_t stat_index,
   in bit<32> latency ) {

   bit<1> first_pkt;
   //reset for minimum latency
   Register<bit<1>, stats_index_t>(size=1<<13, initial_value=0) first_pkt_reg;
   l47_latency_flow_stat(1<<13) l47_latencyA;
   @KS_stats_service_counter(Min Latency, eagle_counters)
   @KS_stats_service_columns(max)
   @KS_stats_service_units(ns)
   Register<bit<32>, stats_index_t>(size=1<<13, initial_value=0) store_lat_minA;

   @KS_stats_service_counter(Max Latency, eagle_counters)
   @KS_stats_service_columns(min)
   @KS_stats_service_units(ns)
   Register<bit<32>, stats_index_t>(size=1<<13, initial_value=0) store_lat_maxA;

   @KS_stats_service_counter(Pkt Count, eagle_counters)
   @KS_stats_service_columns(packets)
   @KS_stats_service_units(packets)
   Register<bit<32>, stats_index_t>(size=1<<13, initial_value=0) store_pktA;


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

   RegisterAction<bit<32>, stats_index_t, bit<32>>(store_pktA)
   incr_pkt_countA = {
      void apply(inout bit<32> register_data) {
         register_data = register_data + 1;
      }
   };

  /***************************************************/
  apply
  {
      first_pkt = write_first_pkt.execute(stat_index);
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
}
/*!
 * @file  egress_mirror_overhead.p4
 * @brief insert overhead in broadcast packet 
 */







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
/*!
 * @file ingress_metadata_map.p4
 * @brief map ingress metadata ( muxing inner ip, ip to metadata)
 */







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
      metadata_vlan.apply();
      //metadata_vlan.apply();
      metadata_portmap.apply();
   }
}
/*!
 * @file checksum_correction.p4
 * @brief checksum correcion
 */






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
      if (eg_md.bridge.l23_txtstmp_insert == 1 || eg_md.bridge.l47_timestamp_insert == 1 || eg_md.bridge.l23_rxtstmp_insert ==1)
        checksum_insert_tbl.apply();
    }
}
/*!
 * @file ingress_metadata_map.p4
 * @brief map ingress metadata ( muxing inner ip, ip to metadata)
 */







control l2_offset_map(inout header_t hdr, in bit<8> mpls_offset,
in ingress_metadata_t meta) {

   bit<8> l2_offset;
   action map_1()
   {
      l2_offset = mpls_offset + 1;
   }

   action map_2()
   {
      l2_offset = mpls_offset + 2;
   }

   action map_3()
   {
      l2_offset = mpls_offset + 3;
   }

   action map_4()
   {
      l2_offset = mpls_offset + 4;
   }

   action map_0()
   {
      l2_offset = mpls_offset ;
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
      }
      actions = {
        map_1;
        map_2;
        map_3;
        map_4;
        map_0;
        map_0_noip;
      }
      const entries = {
        (true, false, false, false): map_1();
        (false, true, false, false): map_1();
        (true, true, false, false): map_2();
        (_, true, true, false): map_2();
        (true, false, false, true): map_3();
        (false, true, false, true): map_3();
        (_, true, true, true): map_4();
        (true, true, false, true): map_4();
        (false, false, false, false): map_0();
        (false, false, false, true): map_2();
        (false, false, false, false): map_0_noip;
      }
   }

    action map_udp () { hdr.bridge.flags_l3_protocol = 1;}
    action map_tcp() { hdr.bridge.flags_l3_protocol = 2;}
    action map_gre() { hdr.bridge.flags_l3_protocol = 3;}
    action map_gtp() { hdr.bridge.flags_l3_protocol = 4;}
    action map_inner_v4() { hdr.bridge.flags_l3_protocol = 5;}
    action map_inner_v6() { hdr.bridge.flags_l3_protocol = 6;}
    action map_icmp () { hdr.bridge.flags_l3_protocol = 7;}
    action no_l4() { hdr.bridge.flags_l3_protocol = 0;}

    table map_l3_offset_tbl {
      key = {
         hdr.udp.isValid(): exact;
         hdr.tcp.isValid(): exact;
         hdr.gre.isValid(): exact;
         hdr.gtp1.isValid(): exact;
         hdr.icmp.isValid(): exact;
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
         map_icmp;
         no_l4;
      }
      const entries = {
         (true, false, false, false, false, _, _, _, _): map_udp;
         (false, true, false, false, false, _, _, _, _): map_tcp;
         (false, false, true, false, false, _, _, _, _): map_gre;
         (true, false, false, true, false, _, _, _, _): map_gtp;
         (false, false, false, false, true, _, _, _, _): map_icmp;
         (true, false, false, false, false, false, true, true, false): map_inner_v4;
         (false, false, false, false, false, true, false, false, true): map_inner_v6;
      }
      default_action = no_l4;
      size = 8;
   }


  /***************************************************/
  apply
   {
      map_l3_offset_tbl.apply();
      map_l2offset_tbl.apply();
      map_l2_offset();
   }
}
/*!
 * @file inbound_l47.p4
 * @brief lookup table for queue range, queue offset and queue mask
 */
control capture_filter( inout header_t hdr,
                        in ingress_intrinsic_metadata_t ig_intr_md,
                        in ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
                        inout ingress_metadata_t meta,
                        in bit<1> capture_match,
                        in bit<1> l23_match, in bit<1> l47_match
        ) {

  bit<8> sa_match_no = 0;
  bit<8> da_match_no = 0;
  bit<4> partition_id;
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
    @atcam_partition_index("partition_id")
    @atcam_number_partitions(16)
    table ip_sa_tbl {
        key = {
            partition_id : exact;
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
    @atcam_partition_index("partition_id")
    @atcam_number_partitions(16)
    table ip_da_tbl {
        key = {
            partition_id : exact;
            meta.map_v4 : exact;
            meta.map_v6 : exact;
            meta.ip_dst_31_0 : ternary;
            meta.ipv6_dst_63_32 : exact;
            meta.ipv6_dst_95_64 : exact;
            meta.ipv6_dst_127_96: exact;
        }
        actions = {
            ip_da_match;
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


    table capture_matchers_ingress_tbl {
        key = {
            sport_match_no : exact;
            dport_match_no : exact;
            ip_sa_match_no : exact;
            ip_da_match_no : exact;
            sa_match_no : exact;
            da_match_no : exact;
            mpls_match_no : exact;
            vlan_match_no : exact;
            l23_match : exact;
            l47_match : exact;
            ig_intr_md.ingress_port : exact;
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

    table capture_matchers_egress_tbl {
        key = {
            sport_match_no : exact;
            dport_match_no : exact;
            ip_sa_match_no : exact;
            ip_da_match_no : exact;
            sa_match_no : exact;
            da_match_no : exact;
            mpls_match_no : exact;
            vlan_match_no : exact;
            l23_match : exact;
            l47_match : exact;
            ig_intr_tm_md.ucast_egress_port : exact;
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
    if (capture_match == 1w1)
        capture_matchers_ingress_tbl.apply();
    else
        capture_matchers_egress_tbl.apply();
}

}
/*!
 * @file inbound_l47.p4
 * @brief lookup table for queue range, queue offset and queue mask
 */
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






control ingress_cmp(in ghost_intrinsic_metadata_t g_intr_md,
                    inout ingress_metadata_t meta,
                    out bit<16> rich_register) {

 bit<16> temp_rich_register_1;
    bit<16> temp_rich_register_2;
    bit<8> compare = 0;

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

    MinMaxAction<bit<16>, bit<8>, bit<16>>(ping_reg2) ping_get2 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x3C, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(pong_reg2) pong_get2 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x3C, subindex[2:0]);
        }
    };

    MinMaxAction<bit<16>, bit<8>, bit<16>>(ping_reg2) ping_get3 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x3A, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(pong_reg2) pong_get3 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x3A, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(ping_reg2) ping_get4 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x36, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(pong_reg2) pong_get4 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x36, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(ping_reg3) ping_get5 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x2E, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(pong_reg3) pong_get5 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x2E, subindex[2:0]);
        }
    };

    MinMaxAction<bit<16>, bit<8>, bit<16>>(ping_reg3) ping_get6 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x1E, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(pong_reg3) pong_get6 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x1E, subindex[2:0]);
        }
    };

    @stage(1)
    action ping_get_depth() {
        ping_get.execute(meta.port_properties.capture_group, temp_rich_register_1);
    }
    @stage(1)
    action pong_get_depth() {
        pong_get.execute(meta.port_properties.capture_group, temp_rich_register_1);
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
//-------------------------------------------------------
    action ping_get_depth2() {
        ping_get2.execute(meta.port_properties.capture_group, temp_rich_register_2);
    }
    action ping_get_depth3() {
        ping_get3.execute(meta.port_properties.capture_group, temp_rich_register_2);
    }
    action ping_get_depth4() {
        ping_get4.execute(meta.port_properties.capture_group, temp_rich_register_2);
    }
    action ping_get_depth5() {
        ping_get5.execute(meta.port_properties.capture_group, temp_rich_register_2);
    }
    action ping_get_depth6() {
        ping_get6.execute(meta.port_properties.capture_group, temp_rich_register_2);
    }

    action pong_get_depth2() {
        pong_get2.execute(meta.port_properties.capture_group, temp_rich_register_2);
    }
    action pong_get_depth3() {
        pong_get3.execute(meta.port_properties.capture_group, temp_rich_register_2);
    }
    action pong_get_depth4() {
        pong_get4.execute(meta.port_properties.capture_group, temp_rich_register_2);
    }
    action pong_get_depth5() {
        pong_get5.execute(meta.port_properties.capture_group, temp_rich_register_2);
    }

    action pong_get_depth6() {
        pong_get6.execute(meta.port_properties.capture_group, temp_rich_register_2);
    }

    @stage(2)
    table ping_read2_tbl {
        key = {
            temp_rich_register_1 : exact;
        }
        actions = {
            ping_get_depth2;
            ping_get_depth3;
            ping_get_depth4;
            NoAction;
        }
        default_action = NoAction;
    }

    @stage(3)
    table ping_read2_p2_tbl {
        key = {
            temp_rich_register_1 : exact;
        }
        actions = {
            ping_get_depth5;
            ping_get_depth6;
            NoAction;
        }
        default_action = NoAction;
    }

    @stage(2)
    table pong_read2_tbl {
        key = {
            temp_rich_register_1 : exact;
        }
        actions = {
            pong_get_depth2;
            pong_get_depth3;
            pong_get_depth4;
            NoAction;
        }
        default_action = NoAction;
    }
    @stage(3)
    table pong_read2_p2_tbl {
        key = {
            temp_rich_register_1 : exact;
        }
        actions = {
            pong_get_depth5;
            pong_get_depth6;
            NoAction;
        }
        default_action = NoAction;
    }

    Register<bit<16>, bit<8>>(size=8, initial_value=5) last_rich;
    RegisterAction<bit<16>, bit<8>, bit<16>>(last_rich)
    update_last = {
        void apply(inout bit<16> register_data, out bit<16> result)
        {
            result = register_data;
            if (register_data == temp_rich_register_1)
                register_data = temp_rich_register_2;
            else
                register_data = temp_rich_register_1;
        }
    };

    /*Register<bit<8>, bit<1>>(size=1, initial_value=0) cmp_rich;
    RegisterAction<bit<8>, bit<1>, bit<8>>(cmp_rich)
    compare_rich = {
        void apply(inout bit<8> register_data, out bit<8> result)
        {
            result = register_data;
            if (register_data == 1)
                register_data = 0;
            else
                register_data = 1;
        }
    };

    Register<rich_pair, bit<16>>(size=8) rich_pair_reg;
    RegisterAction<rich_pair, bit<8>, bit<16>>(rich_pair_reg) read_first_and_update_second = {
        void apply(inout rich_pair value, out bit<16> read_value){
            read_value = value.first;
            if (value.first == temp_rich_register_1)
                value.second = temp_rich_register_2;
            else
                value.second = temp_rich_register_1;
        }
    };
    RegisterAction<rich_pair, bit<8>, bit<16>>(rich_pair_reg) read_second_and_update_first = {
        void apply(inout rich_pair value, out bit<16> read_value) {
            read_value = value.second;
            if (value.second == temp_rich_register_1)
                value.first = temp_rich_register_2;
            else
                value.first = temp_rich_register_1;
        }
    };

    action cmp_act_1() {
        rich_register = read_first_and_update_second.execute(meta.port_properties.capture_group);
    }
    action cmp_act_2() {
        rich_register = read_second_and_update_first.execute(meta.port_properties.capture_group);
    }

    @stage(QUEUE_REG_STAGE4)
    table compare_step_3_tbl {
    	key = {
            compare : exact;
    	}
        actions = {
            cmp_act_1;
            cmp_act_2;
        }
        const entries = {
            (  0  ) : cmp_act_1();
            (  1  ) : cmp_act_2();
    	}
    }*/

/************************************************************************************/
    apply {
        //compare = compare_rich.execute(0);
        if (g_intr_md.ping_pong == 0) {
            ping_read_tbl.apply();
            ping_read2_tbl.apply();
            ping_read2_p2_tbl.apply();
        }
        else {
            pong_read_tbl.apply();
            pong_read2_tbl.apply();
            pong_read2_p2_tbl.apply();
        }
        //compare_step_3_tbl.apply();
        rich_register = update_last.execute(meta.port_properties.capture_group);
    }
}






control egress_cmp(in ghost_intrinsic_metadata_t g_intr_md,
                    inout ingress_metadata_t meta,
                    in bit<8> idx, out bit<16> rich_register) {

    bit<16> temp_rich_register_1;
    bit<16> temp_rich_register_2;
    bit<8> compare = 0;

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

    action ping_get_depth() {
        ping_egress_get.execute(idx, temp_rich_register_1);
    }
    action pong_get_depth() {
        pong_egress_get.execute(idx, temp_rich_register_1);
    }
    @stage(10)
    table ping_read_tbl {
        actions = {
            ping_get_depth;
        }
        default_action = ping_get_depth;
    }

    @stage(10)
    table pong_read_tbl {
        actions = {
            pong_get_depth;
        }
        default_action = pong_get_depth;
    }

/*********************************************************/
    MinMaxAction<bit<16>, bit<8>, bit<16>>(ping_egress_reg2) ping_egress_get2 = {
    void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x3C, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(pong_egress_reg2) pong_egress_get2 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x3C, subindex[2:0]);
        }
    };

    MinMaxAction<bit<16>, bit<8>, bit<16>>(ping_egress_reg2) ping_egress_get3 = {
    void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x3A, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(pong_egress_reg2) pong_egress_get3 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x3A, subindex[2:0]);
        }
    };

    MinMaxAction<bit<16>, bit<8>, bit<16>>(ping_egress_reg2) ping_egress_get4 = {
    void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x36, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(pong_egress_reg2) pong_egress_get4 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x36, subindex[2:0]);
        }
    };

    MinMaxAction<bit<16>, bit<8>, bit<16>>(ping_egress_reg3) ping_egress_get5 = {
    void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x1E, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(pong_egress_reg3) pong_egress_get5 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x1E, subindex[2:0]);
        }
    };

    MinMaxAction<bit<16>, bit<8>, bit<16>>(ping_egress_reg3) ping_egress_get6 = {
    void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x2E, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<8>, bit<16>>(pong_egress_reg3) pong_egress_get6 = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.min16(value, 0x2E, subindex[2:0]);
        }
    };

    //-------------------------------------------------------
    action ping_get_depth2() {
        ping_egress_get2.execute(idx, temp_rich_register_2);
    }
    action ping_get_depth3() {
        ping_egress_get3.execute(idx, temp_rich_register_2);
    }
    action ping_get_depth4() {
        ping_egress_get4.execute(idx, temp_rich_register_2);
    }
    action ping_get_depth5() {
        ping_egress_get5.execute(idx, temp_rich_register_2);
    }
    action ping_get_depth6() {
        ping_egress_get6.execute(idx, temp_rich_register_2);
    }

    action pong_get_depth2() {
        pong_egress_get2.execute(idx, temp_rich_register_2);
    }
    action pong_get_depth3() {
        pong_egress_get3.execute(idx, temp_rich_register_2);
    }
    action pong_get_depth4() {
        pong_egress_get4.execute(idx, temp_rich_register_2);
    }
    action pong_get_depth5() {
        pong_egress_get5.execute(idx, temp_rich_register_2);
    }
    action pong_get_depth6() {
        pong_egress_get6.execute(idx, temp_rich_register_2);
    }

    @stage(11)
    table ping_read2_tbl {
        key = {
            temp_rich_register_1 : exact;
        }
        actions = {
            ping_get_depth2;
            ping_get_depth3;
            ping_get_depth4;
            NoAction;
        }
        default_action = NoAction;
    }

    @stage(11)
    table pong_read2_tbl {
        key = {
            temp_rich_register_1 : exact;
        }
        actions = {
            pong_get_depth2;
            pong_get_depth3;
            pong_get_depth4;
            NoAction;
        }
        default_action = NoAction;
    }

    table ping_read2_p2_tbl {
        key = {
            temp_rich_register_1 : exact;
        }
        actions = {
            ping_get_depth5;
            ping_get_depth6;
            NoAction;
        }
        default_action = NoAction;
    }

    table pong_read2_p2_tbl {
        key = {
            temp_rich_register_1 : exact;
        }
        actions = {
            pong_get_depth5;
            pong_get_depth6;
            NoAction;
        }
        default_action = NoAction;
    }

    Register<bit<16>, bit<8>>(size=8, initial_value=5) last_rich;
    RegisterAction<bit<16>, bit<8>, bit<16>>(last_rich)
    update_last = {
        void apply(inout bit<16> register_data, out bit<16> result)
        {
            result = register_data;
            if (register_data == temp_rich_register_1)
                register_data = temp_rich_register_2;
            else
                register_data = temp_rich_register_1;
        }
    };


    /*Register<bit<8>, bit<1>>(size=1, initial_value=0) cmp_rich;
    RegisterAction<bit<8>, bit<1>, bit<8>>(cmp_rich)
    compare_rich = {
        void apply(inout bit<8> register_data, out bit<8> result)
        {
            result = register_data;
            if (register_data == 1)
                register_data = 0;
            else
                register_data = 1;
        }
    };

    Register<rich_pair, bit<16>>(size=8) rich_pair_reg;
    RegisterAction<rich_pair, bit<8>, bit<16>>(rich_pair_reg) read_first_and_update_second = {
        void apply(inout rich_pair value, out bit<16> read_value){
            read_value = value.first;
            if (value.first == temp_rich_register_1)
                value.second = temp_rich_register_2;
            else
                value.second = temp_rich_register_1;
        }
    };
    RegisterAction<rich_pair, bit<8>, bit<16>>(rich_pair_reg) read_second_and_update_first = {
        void apply(inout rich_pair value, out bit<16> read_value) {
            read_value = value.second;
            if (value.second == temp_rich_register_1)
                value.first = temp_rich_register_2;
            else
                value.first = temp_rich_register_1;
        }
    };

    action cmp_act_1() {
        rich_register = read_first_and_update_second.execute(idx);
    }
    action cmp_act_2() {
        rich_register = read_second_and_update_first.execute(idx);
    }

    @stage(QUEUE_REG_STAGE4)
    table compare_step_3_tbl {
    	key = {
            compare : exact;
    	}
        actions = {
            cmp_act_1;
            cmp_act_2;
        }
        const entries = {
            (  0  ) : cmp_act_1();
            (  1  ) : cmp_act_2();
    	}
    }*/


/************************************************************************************/
    apply {
        //compare = compare_rich.execute(0);
        if (g_intr_md.ping_pong == 0) {
            ping_read_tbl.apply();
            ping_read2_tbl.apply();
            ping_read2_p2_tbl.apply();
        }
        else {
            pong_read_tbl.apply();
            pong_read2_tbl.apply();
            pong_read2_p2_tbl.apply();
        }
        //compare_step_3_tbl.apply();
        rich_register = update_last.execute(idx);
    }
}

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
    // Create port counters ( banked )
    @KS_stats_service_counter(Ingress Port Counter Table, mac,
                              SxIngPipeline.mapBankBitTbl,
                              SxIngPipeline.banked_port_statsB)
    @KS_stats_service_columns(Ingress Packets,Ingress Bytes)
    @KS_stats_service_units(packets,bytes)
    Counter<bit<64>, bit<8>> (256, CounterType_t.PACKETS_AND_BYTES) banked_port_statsA;
    Counter<bit<64>, bit<8>> (256, CounterType_t.PACKETS_AND_BYTES) banked_port_statsB;
    bit<8> queue_offset;
    bit<1> l47_match = 0;
    bit<1> timestamp_calc = 0;
    bit<16> ethertype;
    bit<8> final_queue ;
    bit<32> pkt_latency;
    stats_index_t stat_index;
    bit<8> mpls_offset;
    bit<32> ingress_mac_timestamp;
    bit<1> l23_match;
    bit<1> insert_txtimestamp = 0;
    bit<32> collapsed_rx_mac;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identityHash32_rx;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identityHash32_rx_2;
    bit<16> rich_register = 0;
    bit<16> egress_rich_register = 0;
    bit<8> egress_capture_group = 0;
    bit<16> seq_no = 0;
    bit<1> capture_match = 0;
    bit<8> pkt_count_index = 0;
    bit<1> pkt_count_match = 0;
    // there should only be one value, so it can be type min or max 
    @KS_stats_service_counter(IngressTimestampA, mac,
                                SxIngPipeline.mapBankBitTbl,
                                SxIngPipeline.timestamp_latchB)
    @KS_stats_service_columns(Ingresstimestamp)
    @KS_stats_service_units(ns)
    Register<lat_tot_layout, bit<8>>(size=256) timestamp_latch;
    RegisterAction<lat_tot_layout, bit<8>, bit<32> >(timestamp_latch)
    latch_timestamp = {
        void apply(inout lat_tot_layout value)
        {
            value.lo = (bit<32>)(ig_intr_prsr_md.global_tstamp[31:0]);
            value.hi = (bit<32>)(ig_intr_prsr_md.global_tstamp[47:32]);
        }
    };
    Register<lat_tot_layout, bit<8>>(size=256) timestamp_latchB;
    RegisterAction<lat_tot_layout, bit<8>, bit<32> >(timestamp_latchB)
    latch_timestampB = {
        void apply(inout lat_tot_layout value)
        {
            value.lo = (bit<32>)(ig_intr_prsr_md.global_tstamp[31:0]);
            value.hi = (bit<32>)(ig_intr_prsr_md.global_tstamp[47:32]);
        }
    };

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

    action map_bank(bit<1> bank)
    {
        meta.bank_bit = bank;
    }

    table mapBankBitTbl {
        actions = {
            map_bank;
        }
        size = 1;
        //default_action = map_bank;
    }

    action map_port_index(bit<8> index)
    {
        pkt_count_index = index;
        pkt_count_match = 1;
    }

    table mapPortIndexTbl {
        key = {
            ig_intr_md.ingress_port : exact;
        }
        actions = {
            map_port_index;
            NoAction;
        }
        size = 256;
        default_action = NoAction;
    }
   /**
   * Sets egress port.
   * @param egPort egress port
   * @return none
   */
    action truncate_rx_tstamp() {
       ingress_mac_timestamp = (bit<32>)(ig_intr_md.ingress_mac_tstamp);
       ethertype = hdr.ethernet.ether_type;
       hdr.bridge.ingress_port = ig_intr_md.ingress_port[7:0];
    }

    action assign_rx_tstamp(){
      hdr.bridge.sum_mac_timestamp = collapsed_rx_mac + identityHash32_rx_2.get({ingress_mac_timestamp[15:0]});
    }

    action insertL23RxTimestamp() {
      hdr.first_payload.signature_bot[15:0] = ingress_mac_timestamp[31:16];
      @in_hash{hdr.rx_timestamp.rx_timestamp = ingress_mac_timestamp[15:0];}
      hdr.bridge.l23_rxtstmp_insert = 1;
      hdr.bridge.l23_txtstmp_insert = 0;
    }

    action setOutboundEgPort(PortId_t egPort, QueueId_t queue) {
        ig_intr_tm_md.ucast_egress_port = egPort;
        ig_intr_tm_md.qid = queue;
    }

    action setFixedPort(PortId_t egPort, QueueId_t queue) {
        ig_intr_tm_md.ucast_egress_port = egPort;
        ig_intr_tm_md.qid = queue;
        ig_intr_tm_md.bypass_egress = 1;
        hdr.bridge.setInvalid();
    }

    action setL23InboundInsertEgPort(PortId_t egPort, QueueId_t queue) {
        setOutboundEgPort(egPort, queue);
        insertL23RxTimestamp();
        meta.l23_match = 1;
    }

    action setL23OutboundEgPort(PortId_t egPort, QueueId_t queue){
        setOutboundEgPort(egPort, queue);
        hdr.bridge.l23_txtstmp_insert = 0;
    }

    action setL23OutboundInsertEgPort(PortId_t egPort, QueueId_t queue){
        setOutboundEgPort(egPort, queue);
        hdr.bridge.l23_txtstmp_insert = 1;
        meta.l23_match = 1;
    }

    action setL47OutboundEgPort(PortId_t egPort, QueueId_t queue, bit<4> pcp_cfi) {
        setOutboundEgPort(egPort, queue);
        ig_intr_tm_md.ingress_cos = hdr.vlan_tag_0.pcp_cfi[3:1];
        hdr.vlan_tag_0.pcp_cfi = pcp_cfi;
    }

    action setL47OutboundEgPortInsertTimestamp(PortId_t egPort, QueueId_t queue, bit<4> pcp_cfi) {
        setOutboundEgPort(egPort, queue);
        ig_intr_tm_md.ingress_cos = hdr.vlan_tag_0.pcp_cfi[3:1];
        hdr.bridge.l47_timestamp_insert = 1;
        hdr.vlan_tag_0.pcp_cfi = pcp_cfi;
    }
    // this is a workaround for E810
    action setL47InnerVlanOutboundEgPort(PortId_t egPort, QueueId_t queue, bit<4> pcp_cfi) {
        setOutboundEgPort(egPort, queue);
        ig_intr_tm_md.ingress_cos = hdr.vlan_tag_0.pcp_cfi[3:1];
        hdr.vlan_tag_0.pcp_cfi = pcp_cfi;
        hdr.vlan_tag_1.pcp_cfi = 0;
    }

    action setL47InnerVlanOutboundEgPortInsertTimestamp(PortId_t egPort, QueueId_t queue, bit<4> pcp_cfi) {
        setOutboundEgPort(egPort, queue);
        hdr.bridge.l47_timestamp_insert = 1;
        ig_intr_tm_md.ingress_cos = hdr.vlan_tag_0.pcp_cfi[3:1];
        hdr.vlan_tag_0.pcp_cfi = pcp_cfi;
        hdr.vlan_tag_1.pcp_cfi = 0;
    }

    //direct mapping of hdr.bridge.l23_tx_timestamp_insert = hdr.first_payload.rx_timestamp[4:4]
    //cause error. Workaround is to make it programmable ( fixed to 1 or 0 )
    //user need to use 2 entries for each ingress_port/engine_id option ( key could be 1 or 0 and 
    //use pick the appropriate action)
    table presetOutboundTbl {
        key = {
            hdr.vlan_tag_0.pcp_cfi: ternary;
            hdr.vlan_tag_0.isValid(): ternary;
            hdr.vlan_tag_1.isValid(): ternary;
            meta.port_properties.port_type : ternary;
            meta.engine_id: ternary;
            hdr.first_payload.signature_top: ternary;
            hdr.first_payload.signature_bot: ternary;
            ig_intr_md.ingress_port: ternary;
        }
        actions = {
          setL23InboundInsertEgPort;
          setL23OutboundInsertEgPort;
          setL23OutboundEgPort;
          setL47OutboundEgPort;
          setL47OutboundEgPortInsertTimestamp;
          setL47InnerVlanOutboundEgPort;
          setL47InnerVlanOutboundEgPortInsertTimestamp;
          setOutboundEgPort;
          setFixedPort;
          NoAction;
        }
        default_action = NoAction;
        size = 1024;
    }

    action removeVlan() {
        hdr.ethernet.ether_type = hdr.vlan_tag_0.ether_type;
        hdr.vlan_tag_0.setInvalid();
    }

    table removeVlanTbl {
        key = {
            hdr.vlan_tag_0.vlan_top: exact;
            hdr.vlan_tag_0.vlan_bot: exact;
            meta.port_properties.port_type : exact;
        }
        actions = {
            removeVlan;
            NoAction;
        }
        default_action = NoAction;
        size = 4;
    }

    // special lldp packet from our own cpu (should not have any vlan)
    action insertLLDPVlan(bit<4> vlan_top, bit<8> vlan_bot)
    {
        hdr.ethernet.ether_type = 0x8100;
        hdr.vlan_tag_0.setValid();
        hdr.vlan_tag_0.vlan_top = vlan_top;
        hdr.vlan_tag_0.vlan_bot = vlan_bot;
        hdr.vlan_tag_0.ether_type = ethertype;
        ig_intr_tm_md.ucast_egress_port = 2;
        hdr.bridge.pkt_type = PKT_TYPE_SKIP_EGRESS;
    }

    table mapLLDPVlanTbl {
        key = {
            ig_intr_md.ingress_port : exact;
        }
        actions = {
            insertLLDPVlan;
            NoAction;
        }
        default_action = NoAction;
        size = 512;
    }

    // each front panel should map to a single multicast group that has
    // at least 2 ports, a default CN port and CPU port
    action set_mcast_grp(MulticastGroupId_t mcg) {
        ig_intr_tm_md.mcast_grp_a = mcg;
        ig_intr_dprsr_md.mirror_type = 0;
        hdr.bridge.pkt_type = PKT_TYPE_BROADCAST;
    }

    //only match on l47_match and l23_match = 0
    // the only configurable item from user is the port number
    table multicastTbl {
        key = {
            ig_intr_md.ingress_port : exact;
            l47_match: exact;
            ethertype: ternary;
        }
        actions = {
            set_mcast_grp;
            NoAction;
        }
        default_action = NoAction;
        size = 64;
    }

    action insert_seq_no()
    {
        meta.mirror.capture_seq_no = seq_no;
        //meta.mirror.l2_offset = hdr.bridge.l2_offset;
    }

    action set_capture_mirror_session(MirrorId_t mirror_session) {
        ig_intr_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
        meta.mirror_session = mirror_session;
        meta.mirror.pkt_type = PKT_TYPE_CAPTURE;
        meta.mirror.mac_timestamp = ingress_mac_timestamp;
        seq_no = update_seq_no.execute(meta.port_properties.capture_group[5:3]);
        capture_match = 1;
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
        size = 8;
   }
    action map_port_indexA()
    {
        banked_port_statsA.count(pkt_count_index);
        latch_timestamp.execute(pkt_count_index);
    }

    table bankedPortTableA {
        key = {
            pkt_count_match : exact;
            meta.bank_bit : exact;
        }
        actions = {
            map_port_indexA;
            NoAction;
        }
        const entries =
  {
   (1, 1): map_port_indexA;
            (0, 1): NoAction;
            (1, 0): NoAction;
            (0, 0): NoAction;
  }
        size = 4;
    }


    action map_port_indexB()
    {
        banked_port_statsB.count(pkt_count_index);
        latch_timestampB.execute(pkt_count_index);
    }
    table bankedPortTableB {
        key = {
            pkt_count_match : exact;
            meta.bank_bit : exact;
        }
        actions = {
            map_port_indexB;
            NoAction;
        }
        const entries =
  {
   (1, 0): map_port_indexB;
            (0, 0): NoAction;
            (1, 1): NoAction;
            (0, 1): NoAction;
  }
        size = 4;
    }

    action do_set_egress_group(bit<3> group) {
        hdr.bridge.capture_group = group;
        egress_capture_group[5:3] = group;
    }

    table set_egress_group {
        key = {
            ig_intr_tm_md.ucast_egress_port : exact;
        }
        actions = {
            do_set_egress_group;
            NoAction;
         }
        default_action = NoAction;
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
        mapBankBitTbl.apply();
        mapPortIndexTbl .apply();
        bankedPortTableA.apply();
        bankedPortTableB.apply();
        ingress_cmp.apply(g_intr_md, meta, rich_register);
        truncate_rx_tstamp();
        mapMplsTbl.apply();
        ingress_metadata_map.apply(hdr, ig_intr_md, meta);
        //lookup will do the mod operation
        //If L23 type packets
        collapse_rx_tstamp();
        assign_rx_tstamp();
        if (meta.cpu_lldp == 1)
            mapLLDPVlanTbl.apply();
        else {
            if (presetOutboundTbl.apply().hit == false)
            {
                //vlan is inserted regardless of l47 match
                inbound_l47_gen_lookup.apply(hdr, ig_intr_md, ig_intr_tm_md, meta, ethertype,
                         l47_match, timestamp_calc, stat_index);
                multicastTbl.apply();
            } else {
                removeVlanTbl.apply();
            }
        }
        //set egress group for capture
        set_egress_group.apply();
        egress_cmp.apply(g_intr_md, meta, egress_capture_group, egress_rich_register);
        l2_offset_map.apply(hdr, mpls_offset, meta);
        ingressCaptureTbl.apply();
        if (capture_match == 1w1)
            insert_seq_no();
        capture_filter.apply(hdr, ig_intr_md, ig_intr_tm_md, meta, l23_match, l47_match, capture_match);
        set_rich_bridge();
            //calculate latency assuming it is l47 payload
        inbound_l47_calc_latency.apply(hdr, ig_intr_md, ingress_mac_timestamp, pkt_latency);
        if (timestamp_calc == 1 && l47_match == 1)
            latency_stat.apply(0, stat_index, pkt_latency);
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
            PKT_TYPE_CAPTURE : parseCapture;
            PKT_TYPE_SKIP_EGRESS : parseSkip;
            PKT_TYPE_BROADCAST : parseBroadcast;
            default : parseBridge;
        }
    }

    // this is the packet that is mirror either from ingress or egress
    state parseCapture {
        pkt.extract(eg_md.ing_port_mirror);
        eg_md.pkt_type = PKT_TYPE_CAPTURE;
        hdr.capture.setValid();
        transition accept;
    }

    state parseSkip {
        pkt.extract(eg_md.bridge);
        transition accept;
    }

    state parseBroadcast {
        pkt.extract(eg_md.bridge);
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_VLAN: parseVlan;
            ETHERTYPE_SVLAN: parseVlan;
            default : parseInsertVlan;
        }
    }

    state parseVlan {
       pkt.extract(hdr.vlan_tag_0);
       transition accept;
    }

    state parseInsertVlan {
        hdr.vlan_tag_0.setValid();
        hdr.vlan_tag_0.ether_type = hdr.ethernet.ether_type;
        hdr.vlan_tag_0.vlan_top = 0xf;
        hdr.vlan_tag_0.vlan_bot = 0xff;
        hdr.ethernet.ether_type = 0x8100;
        transition accept;
    }

    state parseBridge {
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
    @KS_stats_service_counter(Egress Port Counter Table, mac,
                                 SxEgrPipeline.mapBankBitTbl,
                                 SxEgrPipeline.banked_port_statsB)
    @KS_stats_service_columns(Egress Packets,Egress Bytes)
    @KS_stats_service_units(packets,bytes)
    Counter<bit<64>, bit<8>> (256, CounterType_t.PACKETS_AND_BYTES) banked_port_statsA;
    Counter<bit<64>, bit<8>> (256, CounterType_t.PACKETS_AND_BYTES) banked_port_statsB;
    bit<8> pkt_count_index = 0;
    bit<1> pkt_count_match = 0;
    bit<16> eg_seq_no = 0;
    bit<1> match = 0;
    bit<8> rich_register;
    bit<1> local_error = 0;
    @KS_stats_service_counter(EgresstimestampA, mac,
                                SxEgrPipeline.mapBankBitTbl,
                                SxEgrPipeline.timestamp_latchB)
    @KS_stats_service_columns(Egresstimestamp)
    @KS_stats_service_units(ns)
    Register<lat_tot_layout, bit<8>>(size=256) timestamp_latch;
    RegisterAction<lat_tot_layout, bit<8>, bit<32>>(timestamp_latch)
    latch_timestamp = {
        void apply(inout lat_tot_layout value)
        {
            value.lo = (bit<32>)(eg_intr_md_from_prsr.global_tstamp[31:0]);
            value.hi = (bit<32>)(eg_intr_md_from_prsr.global_tstamp[47:32]);
        }
    };

    Register<lat_tot_layout, bit<8>>(size=256) timestamp_latchB;
    RegisterAction<lat_tot_layout, bit<8>, bit<32>>(timestamp_latchB)
    latch_timestampB = {
         void apply(inout lat_tot_layout value)
        {
            value.lo = (bit<32>)(eg_intr_md_from_prsr.global_tstamp[31:0]);
            value.hi = (bit<32>)(eg_intr_md_from_prsr.global_tstamp[47:32]);
        }
    };

    Register<bit<8>, bit<3>>(size=8, initial_value=0) last_rich;
    RegisterAction<bit<8>, bit<3>, bit<8>>(last_rich)
    update_last = {
        void apply(inout bit<8> register_data, out bit<8> result)
        {
            if (register_data == (bit<8>)eg_md.bridge.rich_register)
                register_data = register_data - 1;
            else
                register_data = (bit<8>)eg_md.bridge.rich_register;
            result = register_data;
        }
    };

    RegisterAction<bit<8>, bit<3>, bit<8>>(last_rich)
    update_special = {
        void apply(inout bit<8> register_data, out bit<8> result)
        {
            if (register_data == (bit<8>)eg_md.bridge.rich_register)
                register_data = register_data + 1;
            else
                register_data = (bit<8>)eg_md.bridge.rich_register;
            result = register_data;
        }
    };

    action map_bank(bit<1> bank)
    {
        eg_md.bank_bit = bank;
    }

    table mapBankBitTbl {
        actions = {
            map_bank;
        }
        size = 1;
        //default_action = map_bank;
    }
    action map_port_index(bit<8> index)
    {
        pkt_count_index = index;
        pkt_count_match = 1;
    }

    table mapPortIndexTbl {
        key = {
            eg_intr_md.egress_port : exact;
        }
        actions = {
            map_port_index;
            NoAction;
        }
        size = 256;
        default_action = NoAction;
    }

    action map_port_indexA()
    {
        banked_port_statsA.count(pkt_count_index);
        latch_timestamp.execute(pkt_count_index);
    }

    table bankedPortTableA {
        key = {
            pkt_count_match : exact;
            eg_md.bank_bit :exact;
        }
        actions = {
            map_port_indexA;
            NoAction;
        }
        const entries =
  {
   (1, 1): map_port_indexA;
            (0, 0): NoAction;
            (1, 0): NoAction;
            (0, 1): NoAction;
  }
        size = 4;
    }

    action map_port_indexB()
    {
        banked_port_statsB.count(pkt_count_index);
        latch_timestampB.execute(pkt_count_index);
    }
    table bankedPortTableB {
        key = {
            pkt_count_match : exact;
            eg_md.bank_bit :exact;
        }
        actions = {
            map_port_indexB;
            NoAction;
        }
         const entries =
  {
   (1, 0): map_port_indexB;
            (0, 0): NoAction;
            (1, 1): NoAction;
            (0, 1): NoAction;
  }
        size = 4;
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
        //propagate the trigger and filters from ingress pipeline to egress 
        eg_md.mirror.filter = eg_md.bridge.filter;
        eg_md.mirror.trigger = eg_md.bridge.trigger;
        eg_seq_no = update_seq_no.execute(eg_md.bridge.capture_group);
        match = 1;

// E2E mirroring for Tofino2 & future ASICs, or you'll see extra bytes prior to ethernet
        eg_intr_md_for_dprs.mirror_io_select = 1;

  }

    table captureTbl {
        key = {
            eg_intr_md.egress_port : exact;
            eg_md.bridge.capture_group : exact;
            rich_register : exact;
        }
        actions = {
            set_capture_mirror_session;
            NoAction;
        }
        default_action = NoAction;
        size = 32;
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
    Register<bit<16>, bit<9>>(size=512, initial_value=4096) last_sequence_no;
    RegisterAction<bit<16>, bit<9>, bit<1>>(last_sequence_no)
    last_seq_no = {
        void apply(inout bit<16> register_data, out bit<1> result)
        {
            if (register_data == eg_md.ing_port_mirror.capture_seq_no)
                result = 1w1;
            else
                result = 1w0;
            register_data = eg_md.ing_port_mirror.capture_seq_no + 1;
        }
    };
    Register<bit<8>, bit<9>>(size=512, initial_value=0) err_sequence_no;
    RegisterAction<bit<8>, bit<9>, bit<8>>(err_sequence_no)
    err_seq_no = {
        void apply(inout bit<8> register_data, out bit<8> result)
        {
            if ( local_error == 1w1 )
              register_data = register_data + 1;
        }
    };

    action set_cos_value(bit<4> pfc_cos)
    {
     hdr.vlan_tag_0.pcp_cfi = pfc_cos;
    }

    table egressMulticastCosTbl {
        key = {
            eg_intr_md.egress_port : exact;
            eg_md.bridge.ingress_port : exact;
            eg_md.bridge.pkt_type : exact;
        }
        actions = {
            set_cos_value;
            NoAction;
        }
        default_action = NoAction;
        size = 128;
    }

    /*******************************************/
    apply {
        mapBankBitTbl.apply();
        mapPortIndexTbl.apply();
        if (!egressMulticastCosTbl.apply().hit) {
            map_timestamp();
            map_collapsed();
            calculate_checksum.apply(eg_md, hdr, collapsed_tstamp, global_tstamp);
            //only inserting global timestamp
            //for l23, mac timestamp is inserted at ingress pipeline
            if(eg_md.bridge.l47_timestamp_insert == 1)
                outbound_l47_insert_timestamp.apply(hdr, eg_md, global_tstamp);
            else
                timestamp_insertion.apply(hdr, eg_md, global_tstamp);
        }

        if (eg_md.bridge.isValid())
        {
          if (eg_md.bridge.rich_register == 1)
            rich_register = update_special.execute(eg_md.bridge.capture_group);
          else
            rich_register = update_last.execute(eg_md.bridge.capture_group);
        }
        // this has to be at the end, such that egress-capture only act on
        // actual packet ( after mirrored packet appear and not the packet that
        // is being mirrored)
        if (hdr.capture.isValid())
        {
            insertOverheadTbl.apply();
            length_filter.apply(hdr, eg_md, eg_intr_md);
            local_error = last_seq_no.execute(eg_intr_md.egress_port);
        }
        else
        {
            captureTbl.apply();
            insert_seq_no();;
        }
        bankedPortTableA.apply();
        bankedPortTableB.apply();
        err_seq_no.execute(eg_intr_md.egress_port);
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
        size = 32;
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
        size = 32;
    }

    action eg_ping_do_update(bit<11> idx) {
        ping_egress_update.execute(idx);
    }

    @stage(10)
    table eg_ping_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            eg_ping_do_update;
        }
        size = 32;
    }
    action eg_pong_do_update(bit<11> idx) {
        pong_egress_update.execute(idx);
    }

    @stage(10)
    table eg_pong_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            eg_pong_do_update;
        }
        size = 32;
    }

//---------------------------------------------------------        
  // to supply 2 groups to ping pong, we need 2 sets of identical registers
  // such that we can access both per packet access
    RegisterAction<bit<16>, bit<11>, bit<16>>(ping_reg2) ping_update2 = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[15:0]; } };

    RegisterAction<bit<16>, bit<11>, bit<16>>(pong_reg2) pong_update2 = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[15:0]; } };

    RegisterAction<bit<16>, bit<11>, bit<16>>(ping_egress_reg2) ping_egress_update2 = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[15:0]; } };

    RegisterAction<bit<16>, bit<11>, bit<16>>(pong_egress_reg2) pong_egress_update2 = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[15:0]; } };

    action ping_do_update2(bit<11> idx) {
        ping_update2.execute(idx);
    }

    @stage(2)
    table ping_update2_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            ping_do_update2;
        }
        size = 32;
    }

    action pong_do_update2(bit<11> idx) {
        pong_update2.execute(idx);
    }

    @stage(2)
    table pong_update2_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            pong_do_update2;
        }
        size = 32;
    }

    action eg_ping_do_update2(bit<11> idx) {
        ping_egress_update2.execute(idx);
    }

    @stage(11)
    table eg_ping_update2_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            eg_ping_do_update2;
        }
        size = 32;
    }
    action eg_pong_do_update2(bit<11> idx) {
        pong_egress_update2.execute(idx);
    }

    @stage(11)
    table eg_pong_update2_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            eg_pong_do_update2;
        }
        size = 32;
    }
  //---------------------------------------------------------        
  // to supply 2 groups to ping pong, we need 2 sets of identical registers
  // such that we can access both per packet access
  RegisterAction<bit<16>, bit<11>, bit<16>>(ping_reg3) ping_update3 = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[15:0]; } };

    RegisterAction<bit<16>, bit<11>, bit<16>>(pong_reg3) pong_update3 = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[15:0]; } };

    RegisterAction<bit<16>, bit<11>, bit<16>>(ping_egress_reg3) ping_egress_update3 = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[15:0]; } };

    RegisterAction<bit<16>, bit<11>, bit<16>>(pong_egress_reg3) pong_egress_update3 = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[15:0]; } };

    action ping_do_update3(bit<11> idx) {
        ping_update3.execute(idx);
    }

    @stage(3)
    table ping_update3_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            ping_do_update3;
        }
        size = 32;
    }

    action pong_do_update3(bit<11> idx) {
        pong_update3.execute(idx);
    }

    @stage(3)
    table pong_update3_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            pong_do_update3;
        }
        size = 32;
    }

    action eg_ping_do_update3(bit<11> idx) {
        ping_egress_update3.execute(idx);
    }

    @stage(12)
    table eg_ping_update3_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            eg_ping_do_update3;
        }
        size = 32;
    }
    action eg_pong_do_update3(bit<11> idx) {
        pong_egress_update3.execute(idx);
    }

    @stage(12)
    table eg_pong_update3_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            eg_pong_do_update3;
        }
        size = 32;
    }
    /***********************************************/
    //DUMMY
    /*RegisterAction<bit<32>, bit<1>, bit<32>>(gt_stage3) gt_update_s3 = {
        void apply(inout bit<32> value) { value = value + 1; } };

    action gt_update_act_s3() {
        gt_update_s3.execute(0);
    }

    @stage(QUEUE_REG_STAGE4)
    table gt_update_s3_tbl {
        actions = {
            gt_update_act_s3;
        }
        size = 2;
    }*/

    RegisterAction<bit<32>, bit<1>, bit<32>>(gt_stage4) gt_update_s4 = {
        void apply(inout bit<32> value) { value = value + 1; } };

    action gt_update_act_s4() {
        gt_update_s4.execute(0);
    }

    @stage(4)
    table gt_update_s4_tbl {
        actions = {
            gt_update_act_s4;
        }
        size = 2;
    }

    RegisterAction<bit<32>, bit<1>, bit<32>>(gt_stage5) gt_update_s5 = {
        void apply(inout bit<32> value) { value = value + 1; } };

    action gt_update_act_s5() {
        gt_update_s5.execute(0);
    }

    @stage(5)
    table gt_update_s5_tbl {
        actions = {
            gt_update_act_s5;
        }
        size = 2;
    }

    RegisterAction<bit<32>, bit<1>, bit<32>>(gt_stage6) gt_update_s6 = {
        void apply(inout bit<32> value) { value = value + 1; } };

    action gt_update_act_s6() {
        gt_update_s6.execute(0);
    }

    @stage(6)
    table gt_update_s6_tbl {
        actions = {
            gt_update_act_s6;
        }
        size = 2;
    }

    RegisterAction<bit<32>, bit<1>, bit<32>>(gt_stage7) gt_update_s7 = {
        void apply(inout bit<32> value) { value = value + 1; } };

    action gt_update_act_s7() {
        gt_update_s7.execute(0);
    }
    @stage(7)
    table gt_update_s7_tbl {
        actions = {
            gt_update_act_s7;
        }
        size = 2;
    }

    RegisterAction<bit<32>, bit<1>, bit<32>>(gt_stage8) gt_update_s8 = {
        void apply(inout bit<32> value) { value = value + 1; } };

    action gt_update_act_s8() {
        gt_update_s8.execute(0);
    }
    @stage(8)
    table gt_update_s8_tbl {
        actions = {
            gt_update_act_s8;
        }
        size = 2;
    }

    RegisterAction<bit<32>, bit<1>, bit<32>>(gt_stage8) gt_update_s9 = {
        void apply(inout bit<32> value) { value = value + 1; } };

    action gt_update_act_s9() {
        gt_update_s9.execute(0);
    }
    @stage(8)
    table gt_update_s9_tbl {
        actions = {
            gt_update_act_s9;
        }
        size = 2;
    }
    /***********************************************************/
    apply {
        if (g_intr_md.ping_pong == 1) {
            ping_update_tbl.apply();
            ping_update2_tbl.apply();
            ping_update3_tbl.apply();
            //gt_update_s2_tbl.apply();
            //gt_update_s3_tbl.apply();
            gt_update_s4_tbl.apply();
            gt_update_s5_tbl.apply();
            gt_update_s6_tbl.apply();
            gt_update_s7_tbl.apply();
            gt_update_s8_tbl.apply();
            gt_update_s9_tbl.apply();
            eg_ping_update_tbl.apply();
            eg_ping_update2_tbl.apply();
            eg_ping_update3_tbl.apply();
        } else {
            pong_update_tbl.apply();
            pong_update2_tbl.apply();
            pong_update3_tbl.apply();
            //gt_update_s2_tbl.apply();
            //gt_update_s3_tbl.apply();
            gt_update_s4_tbl.apply();
            gt_update_s5_tbl.apply();
            gt_update_s6_tbl.apply();
            gt_update_s7_tbl.apply();
            gt_update_s8_tbl.apply();
            gt_update_s9_tbl.apply();
            eg_pong_update_tbl.apply();
            eg_pong_update2_tbl.apply();
            eg_pong_update3_tbl.apply();
        }
    }
}
/*
 * Pipeline construction
 */

Pipeline(SxIngParser(), SxIngPipeline(), SxIngDeparser(), SxEgrParser(),
  SxEgrPipeline(), SxEgrDeparser(), SxQueueMonitor()) pipe;
Switch(pipe) main;
