#ifndef _HEADERS_
#define _HEADERS_

#define QUEUE_REG_STAGE1 1
#define QUEUE_REG_STAGE2 2
#define QUEUE_REG_STAGE3 3
#define QUEUE_REG_STAGE4 4
#define QUEUE_REG_STAGE5 5
#define QUEUE_REG_STAGE6 6
#define QUEUE_REG_STAGE7 7
#define QUEUE_REG_STAGE8 8
#define QUEUE_REG_STAGE9 9

#define EG_QUEUE_REG_STAGE1 10
#define EG_QUEUE_REG_STAGE2 11
#define EG_QUEUE_REG_STAGE3 12

#define FLOW_STATS_INDEX_WIDTH 13
#define FLOW_STATS_SIZE        1<<FLOW_STATS_INDEX_WIDTH
typedef bit<FLOW_STATS_INDEX_WIDTH>   stats_index_t;

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
const ip_protocol_t IP6_ROUTING   = 43;
const ip_protocol_t IP6_FRAGMENT  = 44;
const ip_protocol_t IP6_DESTINATION = 60;
const ip_protocol_t IP6_AUTHENTICATION = 51;
const ip_protocol_t IP6_SECURITY = 50;
const ip_protocol_t IP6_MOBILITY = 135;

typedef bit<16> udp_port_type_t;
const udp_port_type_t PORT_GTP = 2152; //GTP-U only
const udp_port_type_t PORT_GTP_v2 = 2132; //GTP-C or v2only (no data)
const udp_port_type_t PORT_GTP_C = 3386;  //GTP' (no data)
/* Ingress mirroring information */
typedef bit<8>  pkt_type_t;
const pkt_type_t PKT_TYPE_NORMAL = 1;
const pkt_type_t PKT_TYPE_MIRROR = 2;
const pkt_type_t PKT_TYPE_CAPTURE = 3;
const pkt_type_t PKT_TYPE_BROADCAST = 4;
const pkt_type_t PKT_TYPE_SKIP_EGRESS = 6;

typedef bit<3> port_type_t;
const port_type_t FRONTPANEL_PORT = 1;
const port_type_t L23_PORT = 2;
const port_type_t L47_PORT = 3;
const port_type_t CAPTURE_PORT = 4;
const port_type_t L23CPU_PORT = 5;


#if __TARGET_TOFINO__ == 1
typedef bit<3> mirror_type_t;
#else
typedef bit<4> mirror_type_t;
#endif
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
    bit<8>  dsap;
    bit<8>  ssap;
    bit<8>  snap_control;
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
    bit<20>       label0;
    bit<3>        exp0;
    bit<1>        bos0;
    bit<8>        ttl0;

    bit<20>       label1;
    bit<3>        exp1;
    bit<1>        bos1;
    bit<8>        ttl1;

    bit<20>       label2;
    bit<3>        exp2;
    bit<1>        bos2;
    bit<8>        ttl2;

    bit<20>       label3;
    bit<3>        exp3;
    bit<1>        bos3;
    bit<8>        ttl3;
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
    bit<3>  version;
    bit<1>  protocol_type;
    bit<1>  reserved;
    bit<1>  ext_flag;
    bit<1>  seq_num_flag;
    bit<1>  n_pdu_flag;
    bit<8>  message_type;
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
    bit<1>  filter;
    bit<1>  trigger;
    bit<12> seq_no; //include parity
    bit<4>  pad;
    bit<12> seq_no_2;
    bit<2>  pad_2;
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
    bit<3>  l47_ob_egressport;
    bit<1>  l23_match;
    bit<8>  engine_id;
    bit<32> ipv6_src_127_96;
    bit<32> ipv6_src_95_64;
    bit<32> ipv6_src_63_32;
    bit<32> ip_src_31_0;
    bit<32> ipv6_dst_127_96;
    bit<32> ipv6_dst_95_64;
    bit<32> ipv6_dst_63_32;
    bit<32> ip_dst_31_0;
    bit<4>  vid_top;
    bit<8>  vid_bot;
    bit<1>  map_v6;
    bit<1>  map_v4;
    bit<1>  l47_tcp;
    bit<1>  cpu_lldp;
    MirrorId_t  mirror_session;
    mirror_h mirror;
    bit<4>   v4options_count;
    bit<4>   innerv4options_count;
}

struct rich_pair {
    bit<16>     first;
    bit<16>     second;
}

/*
 * Egress metadata,
 */
struct egress_metadata_t {
    example_bridge_h  bridge;
    mirror_h  ing_port_mirror;
    pkt_type_t pkt_type;
    MirrorId_t mirror_session;
    mirror_h mirror;
    bit<1> bank_bit;
}

struct header_t {
    example_bridge_h  bridge;
    capture_h  capture;
    ethernet_h ethernet;
    snap_h  snap;
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
    ip46_h  inner_ip_version;
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
    example_bridge_h  bridge;
    capture_h  capture;
    ethernet_h ethernet;
    snap_h  snap;
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
    ip46_h  inner_ip_version;
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

@stage(QUEUE_REG_STAGE1)
Register<bit<16>, bit<11>>(32) ping_reg;
@stage(QUEUE_REG_STAGE9)
Register<bit<16>, bit<11>>(32) ping_egress_reg;
@stage(QUEUE_REG_STAGE1)
Register<bit<16>, bit<11>>(32) pong_reg;
@stage(QUEUE_REG_STAGE9)
Register<bit<16>, bit<11>>(32) pong_egress_reg;

@stage(QUEUE_REG_STAGE2)
Register<bit<16>, bit<11>>(32) ping_reg2;
@stage(EG_QUEUE_REG_STAGE1)
Register<bit<16>, bit<11>>(32) ping_egress_reg2;
@stage(QUEUE_REG_STAGE2)
Register<bit<16>, bit<11>>(32) pong_reg2;
@stage(EG_QUEUE_REG_STAGE1)
Register<bit<16>, bit<11>>(32) pong_egress_reg2;

@stage(QUEUE_REG_STAGE3)
Register<bit<16>, bit<11>>(32) ping_reg3;
@stage(EG_QUEUE_REG_STAGE3)
Register<bit<16>, bit<11>>(32) ping_egress_reg3;
@stage(QUEUE_REG_STAGE3)
Register<bit<16>, bit<11>>(32) pong_reg3;
@stage(EG_QUEUE_REG_STAGE3)
Register<bit<16>, bit<11>>(32) pong_egress_reg3;
// dummy

@stage(QUEUE_REG_STAGE4)
Register<bit<32>, bit<1>>(1) gt_stage4;
@stage(QUEUE_REG_STAGE5)
Register<bit<32>, bit<1>>(1) gt_stage5;
@stage(QUEUE_REG_STAGE6)
Register<bit<32>, bit<1>>(1) gt_stage6;
@stage(QUEUE_REG_STAGE7)
Register<bit<32>, bit<1>>(1) gt_stage7;
@stage(QUEUE_REG_STAGE8)
Register<bit<32>, bit<1>>(1) gt_stage8;

#endif /* _HEADERS_ */
