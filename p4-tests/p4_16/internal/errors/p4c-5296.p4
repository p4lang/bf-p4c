#include <tna.p4>  /* TOFINO1_ONLY */

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
typedef bit<16> vlan_tag_t;
typedef bit<16> ethtype_t;
typedef bit<16> gport_t;
typedef bit<16> bp_cookie_t;

header pseul2_h {
    mac_addr_t dmac;
    mac_addr_t smac;
    // ethtype_t ether_type;
}

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
}

header ethernetII_h {
    ethtype_t ether_type;
}

header ethernet802_3_h {
    bit<16> length;
}

header vlan_tag_h {
    ethtype_t tpid;
    vlan_tag_t tag;
}

header pppoe_session_h {
    bit<4> version;
    bit<4> type;
    bit<8> code;
    bit<16> session_id;
    bit<16> payload_length;
    bit<16> protocol;
}

header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header pw_h {
    bit<8> ver;
    bit<8> resv;
    bit<16> type;
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

header ipv4_option_var_h {
    varbit<320> opts;
}

header ipv4_option_h {
    bit<8> type;
    bit<8> length;
    bit<16> value;
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

header ipv6_ext_h {
    bit<8> next_hdr;
    bit<8> ext_hdr_len;
    bit<8> opt_type;
    bit<8> opt_len;
    bit<32> opts;
}

header ipv6_frag_h {
    bit<8> next_hdr;
    bit<8> rsv0;
    bit<13> frag_offset;
    bit<2> rsv1;
    bit<1> more;
    bit<32> identification;
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

header tcp_option_var_h {
    varbit<320> opts;
}

header tcp_option_h {
    bit<8> kind;
    bit<8> length;
    bit<16> info;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

header sctp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> verif_tag;
    bit<32> checksum;
    //bit<32> chunks[];
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

// Address Resolution Protocol -- RFC 6747
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
    // ...
}

header arp_ipv4_h {
    bit<48> smac_addr;
    bit<32> sip_addr;
    bit<48> dmac_addr;
    bit<32> dip_addr;
}

header ipsec_ah_h {
    bit<8> nexthdr;
    bit<8> len;
    bit<16> rsv;
    bit<32> spi;
    bit<32> seq;
}

header ipsec_ah_opt_h {
    bit<32> icv;
}

header ipsec_esp_h {
    bit<32> spi;
    bit<32> seq;
    // varbit<x> pld;
}

// VXLAN -- RFC 7348
header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

// Generic Routing Encapsulation (GRE) -- RFC 1701
header gre_h {
    bit<1> C; /**< Checksum Present bit */
    bit<1> R; /**< Route Present bit */
    bit<1> K; /**< Key Present bit */
    bit<1> S; /**< Sequence Number Present bit */
    bit<1> s; /**< Reserved */
    bit<3> recurse; /**< No of layers that gre is Encapsulated*/
    bit<5> flags; /**< Reserved */
    bit<3> version; /**< Version Number */
    bit<16> proto; /**< Protocol Type */
}

header gre_option_h {
    bit<32> data; /**< Represents Checksum or Key or Sequence Number*/
}

header l2tp_h {
    bit<1> T; /**< Type*/
    bit<1> L; /**< Length*/
    bit<2> rsv0;
    bit<1> S; /**< Sequence*/
    bit<1> rsv1;
    bit<1> O; /**< Offset*/
    bit<1> P; /**< Priority*/
    bit<4> rsv2;
    bit<4> ver; /**< Version*/
    // bit<16> length;
    bit<16> tunnel_id;
    bit<16> session_id;
}

header l2tp_option_h {
    bit<32> data; /**< Represents Offset or Sequence Number*/
}

header p2p_t {
    bit<8> proto;
}
# 288 "../../p4c-5296/headers.p4"
header gtpv1_t {
    bit<3> ver;
    bit<1> p; /**< Protocol Type*/
    bit<1> rsv0;
    bit<1> E; /** Extension Header Flag*/
    bit<1> S; /**< Sequence*/
    bit<1> Pn; /**< N-PDU*/
    bit<8> msg_t; /**< Message Type*/
    bit<16> len;
    bit<32> TEID;
}

header gtpv1_option_h {
    bit<16> seq;
    bit<8> n_pdu;
    bit<8> next_exthdr_t;
}

header gtpv1_exthdr_h {
    bit<8> len;
    bit<16> ctx;
    bit<8> next_exthdr_t;
}
# 326 "../../p4c-5296/headers.p4"
// CPU header
header cpu_h {
    bit<5> egress_queue;
    bit<1> tx_bypass;
    bit<1> capture_ts;
    bit<1> reserved;
    bit<16> ingress_port;
    bit<16> port_lag_index;
    bit<16> ingress_bd;
    bit<16> reason_code; // Also used as a 16-bit bypass flag.
    bit<16> ether_type;
}

// Tx To NPU header
header npu_tx_h {
    bit<8> lport;

    bit<8> mix;
    /**mix[2:0] = user_id
     mix[3:3] = Ts Present bit
     mix[7:4] = rsv*/

    bit<48> ts; /**< Timestamp */
}

// Tx To NPS header
header nps_tx_h {
    ethtype_t tpid;
    bit<16> lport;

    bit<8> mix;
    /**mix[2:0] = user_id
     mix[3:3] = multiuser Present bit
     mix[7:4] = rsv*/

    bit<8> apid; /**< action profile id */
    bit<32> hash; /**< hash value */
}

// Rx From NPU header
header npu_rx_h {
    ethtype_t tpid;
    bit<16> apid;
    bit<8> rsv;
    bit<8> flowid;
    bit<32> hash;
}

// lb header use for multiuser
header lb_h {
    ethtype_t tpid;
    gport_t srcport;
}

header xgp_h {
    ethtype_t tpid;
    gport_t gport;
}

header bp_h {
    ethtype_t tpid;
    gport_t srcport;
    gport_t gport;
    bp_cookie_t cookie;
}

header bp_option_h {
    bit<32> hash;
}
header port_down_lb_h {
    @padding bit<3> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<3> app_id; // Application id
    @padding bit<8> _pad2;
    gport_t gport;
    bit<16> packet_id;
}

// ----------------------------------------------------------------------------
// Common protocols/types
//-----------------------------------------------------------------------------

/* The number of required hash bits depends on both the selection algorithm
 * (resilient or fair) and the maximum group size
 *
 * The rules are as follows:
 *
 * if MAX_GROUP_SZIE <= 120:      subgroup_select_bits = 0
 * elif MAX_GROUP_SIZE <= 3840:   subgroup_select_bits = 10
 * elif MAX_GROUP_SIZE <= 119040: subgroup_select_bits = 15
 * else: ERROR
 *
 * The rules for the hash size are:
 *
 * FAIR:      14 + subgroup_select_bits
 * RESILIENT: 51 + subgroup_select_bits
 *
 */
  const SelectorMode_t SELECTION_MODE = SelectorMode_t.RESILIENT;

/*
 * HASH_WIDTH final definition
 */

/*
 * Since we will be calculating hash in 32-bit pieces, we will have this
 * definition, which will be either bit<32>, bit<64> or bit<96> depending
 * on HASH_WIDTH
 */

typedef bit<(32)> switch_hash_t;
typedef bit<(51)> selector_hash_t;

// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------
typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;

typedef PortId_t switch_port_t;
const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;

typedef gport_t switch_gport_t;
const switch_gport_t SWITCH_GPORT_INVALID = 0;
const switch_gport_t SWITCH_GPORT_LOCAL = 0xffff;

// typedef MulticastGroupId_t switch_mgid_t;
typedef bit<8> switch_mgid_t;
const switch_mgid_t switch_invalid_mgid = 0;

typedef bit<16> switch_rid_t;
const switch_rid_t switch_rid_uc = 0;

typedef bit<16> switch_ifindex_t;

typedef bit<9> switch_port_lag_index_t;
const switch_port_lag_index_t SWITCH_PORT_LAG_INVALID = 0;
const switch_port_lag_index_t SWITCH_FLOOD = 0xff;

typedef bit<16> switch_port_fwd_index_t;
const switch_port_fwd_index_t SWITCH_PORT_FWD_INVALID = 0;

typedef bit<16> switch_port_label_t;
typedef bit<16> switch_port_tag_t;

typedef bit<8> switch_port_ingroup_t;
typedef bit<16> switch_if_label_t;

typedef bit<16> switch_smac_index_t;
typedef bit<16> switch_tpid_t;
typedef bit<16> switch_vlan_tag_t;

typedef bit<128> switch_ip_addr_t;
typedef bit<32> switch_ipv4_addr_t;
typedef bit<32> switch_ip_addr_sign_t;

typedef bit<8> switch_ip_proto_t;
typedef bit<8> switch_ip_tos_t;
typedef bit<16> switch_l4_port_t;

typedef bit<16> switch_mtu_t;

typedef bit<12> switch_stats_index_t;

struct switch_cpu_port_value_set_t {
    bit<16> ether_type;
    switch_port_t port;
}

const bit<5> switch_npu_port_num = 24;
struct switch_npu_port_value_set_t {
    switch_port_t port;
}

typedef bit<8> switch_drop_reason_t;
const switch_drop_reason_t SWITCH_DROP_REASON_UNKNOWN = 0;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID = 1;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_TTL_ZERO = 2;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID = 3;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_INVALID_CHECKSUM = 4;
const switch_drop_reason_t SWITCH_DROP_REASON_INNER_IP_VERSION_INVALID = 5;
const switch_drop_reason_t SWITCH_DROP_REASON_INNER_IP_TTL_ZERO = 6;
const switch_drop_reason_t SWITCH_DROP_REASON_INNER_IP_IHL_INVALID = 7;
const switch_drop_reason_t SWITCH_DROP_REASON_INNER_IP_INVALID_CHECKSUM = 8;

typedef bit<2> switch_ip_type_t;
const switch_ip_type_t SWITCH_IP_TYPE_NONE = 0;
const switch_ip_type_t SWITCH_IP_TYPE_IPV4 = 1;
const switch_ip_type_t SWITCH_IP_TYPE_IPV6 = 2;

typedef bit<3> switch_ip_frag_t;
const switch_ip_frag_t SWITCH_IP_FRAG_UNKNOWN = 0b000;
const switch_ip_frag_t SWITCH_IP_FRAG_NON_FRAG = 0b001; // Not fragmented.
const switch_ip_frag_t SWITCH_IP_FRAG_HEAD = 0b111; // First fragment of the fragmented packets
// const switch_ip_frag_t SWITCH_IP_FRAG_LAST = 0b101; // Last fragment of the fragmented packets.
const switch_ip_frag_t SWITCH_IP_FRAG_NON_HEAD = 0b011; // Fragment with non-zero offset.

// Bypass flags ---------------------------------------------------------------
typedef bit<2> switch_ingress_bypass_t;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_NONE = 0;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ACLRULE = 1;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ACLACT = 2;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ALL = 0x3;

// PKT ------------------------------------------------------------------------

typedef bit<8> switch_pkt_src_t;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED = 0;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_INGRESS = 1;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_EGRESS = 2;
const switch_pkt_src_t SWITCH_PKT_SRC_DEFLECTED = 3;

// Metering -------------------------------------------------------------------

typedef bit<8> switch_copp_meter_id_t;

typedef bit<10> switch_meter_index_t;

typedef bit<8> switch_mirror_meter_id_t;

// Mirroring ------------------------------------------------------------------
typedef MirrorId_t switch_mirror_session_t; // Defined in tna.p4
const switch_mirror_session_t SWITCH_MIRROR_SESSION_NONE = 0;
const switch_mirror_session_t SWITCH_MIRROR_SESSION_CPU = 250;

// Using same mirror type for both Ingress/Egress to simplify the parser.
typedef bit<3> switch_mirror_type_t;

// Common metadata used for mirroring.
struct switch_mirror_metadata_t {
    switch_pkt_src_t src;
    @padding bit<5> _pad0;
    switch_mirror_type_t type;
    switch_mirror_session_t session_id;
    //switch_mirror_meter_id_t meter_index;
}

header switch_port_mirror_metadata_h {
    switch_pkt_src_t src;
    @padding bit<5> _pad0;
    switch_mirror_type_t type;
    //bit<48> timestamp;
    @padding bit<6> _pad;
    switch_mirror_session_t session_id;

}
# 318 "../../p4c-5296/types.p4"
// Used for truncate_only mirror sessions
header switch_simple_mirror_metadata_h {
    switch_pkt_src_t src;
    @padding bit<5> _pad0;
    switch_mirror_type_t type;

    @padding bit<6> _pad;

    switch_mirror_session_t session_id;
}

//packet type

enum bit<3> switch_pkt_l2_type_t {
    L2TYPE_UNKNOWN_L2 = 0,
    L2TYPE_ETHERNET_II_VLAN_MPLS = 1,
    L2TYPE_ETHERNET_II_VLAN = 2,
    L2TYPE_ETHERNET_II_MPLS = 3,
    L2TYPE_ETHERNET_II = 4,
    L2TYPE_ETHERNET_802_3 = 5
}

enum bit<3> switch_pkt_l3_type_t {
    L3TYPE_UNKNOWN_L3 = 0,
    L3TYPE_IPV4 = 1,
    L3TYPE_ARP = 2,
    //VLAN    = 3,
    L3TYPE_IPV6 = 4,
    //MPLS    = 5,
    L3TYPE_ISIS = 6
}

enum bit<4> switch_pkt_l4_type_t {
    L4TYPE_UNKNOWN_L4 = 0,
    L4TYPE_ICMP = 1,
    L4TYPE_IPV4 = 2,
    L4TYPE_TCP = 3,
    L4TYPE_UDP = 4,
    L4TYPE_IPV6 = 5,
    L4TYPE_GRE = 6,
    L4TYPE_IPSEC_ESP = 7,
    L4TYPE_IPSEC_AH = 8,
    L4TYPE_ICMPV6 = 9,
    L4TYPE_OSPF = 10,
    L4TYPE_L2TP = 11,
    L4TYPE_SCTP = 12
}

enum bit<3> switch_pkt_l5_type_t {
    L5TYPE_UNKNOWN_L5 = 0,
    L5TYPE_BGP = 1,
    L5TYPE_L2TP = 2,
    L5TYPE_PPTP = 3,
    L5TYPE_GTP_V0 = 4,
    L5TYPE_GTP_C = 5,
    L5TYPE_GTP_U = 6,
    L5TYPE_VXLAN = 7
}

@flexible
struct switch_pkt_type_t {
    switch_pkt_l2_type_t l2type;
    switch_pkt_l3_type_t l3type;
    switch_pkt_l4_type_t l4type;
    switch_pkt_l5_type_t l5type;
}

typedef bit<3> protocol_l2_stats_index_t;
const protocol_l2_stats_index_t L2_UNKNOWN_PKT_STATS_INDEX = 0;
const protocol_l2_stats_index_t ETHERNETII_UNTAGGED_PKT_STATS_INDEX = 1;
const protocol_l2_stats_index_t ETHERNETII_TAGGED_PKT_STATS_INDEX = 2;
const protocol_l2_stats_index_t ETHERNETII_MPLS_PKT_STATS_INDEX = 3;
const protocol_l2_stats_index_t ETHERNETII_TAGGED_MPLS_PKT_STATS_INDEX = 4;
const protocol_l2_stats_index_t ETHERNET_802_3_PKT_STATS_INDEX = 5;

typedef bit<1> protocol_isis_stats_index_t;
const protocol_isis_stats_index_t ISIS_PKT_STATS_INDEX = 1;

typedef bit<2> protocol_l3_stats_index_t;
const protocol_l3_stats_index_t L3_UNKNOWN_PKT_STATS_INDEX = 0;
const protocol_l3_stats_index_t IPV4_PKT_STATS_INDEX = 1;
const protocol_l3_stats_index_t IPV6_PKT_STATS_INDEX = 2;

typedef bit<4> protocol_l4_stats_index_t;
const protocol_l4_stats_index_t L4_UNKNOWN_PKT_STATS_INDEX = 0;
const protocol_l4_stats_index_t ICMP_PKT_STATS_INDEX = 1;
const protocol_l4_stats_index_t TCP_PKT_STATS_INDEX = 2;
const protocol_l4_stats_index_t UDP_PKT_STATS_INDEX = 3;
const protocol_l4_stats_index_t SCTP_PKT_STATS_INDEX = 4;
const protocol_l4_stats_index_t ICMPV6_PKT_STATS_INDEX = 5;
const protocol_l4_stats_index_t IPV4INIPV4_PKT_STATS_INDEX = 6;
const protocol_l4_stats_index_t IPV6OVERIPV4_PKT_STATS_INDEX = 7;
const protocol_l4_stats_index_t IPV4OVERIPV6_PKT_STATS_INDEX = 8;
const protocol_l4_stats_index_t IPV6INIPV6_PKT_STATS_INDEX = 9;
const protocol_l4_stats_index_t GRE_PKT_STATS_INDEX = 10;
const protocol_l4_stats_index_t IPSEC_AH_PKT_STATS_INDEX = 11;
const protocol_l4_stats_index_t IPSEC_ESP_PKT_STATS_INDEX = 12;
const protocol_l4_stats_index_t OSPF_PKT_STATS_INDEX = 13;
const protocol_l4_stats_index_t L2TP_IN_L4_PKT_STATS_INDEX = 14;

typedef bit<3> protocol_l5_stats_index_t;
const protocol_l5_stats_index_t L5_UNKNOWN_PKT_STATS_INDEX = 0;
const protocol_l5_stats_index_t VXLAN_PKT_STATS_INDEX = 1;
const protocol_l5_stats_index_t GTP_C_PKT_STATS_INDEX = 2;
const protocol_l5_stats_index_t GTP_U_PKT_STATS_INDEX = 3;
const protocol_l5_stats_index_t L2TP_IN_L5_PKT_STATS_INDEX = 4;
const protocol_l5_stats_index_t PPTP_PKT_STATS_INDEX = 5;
const protocol_l5_stats_index_t BGP_PKT_STATS_INDEX = 6;
const protocol_l5_stats_index_t GTP_V0_PKT_STATS_INDEX = 7;

typedef bit<16> switch_pkt_length_t;

// LOU ------------------------------------------------------------------------

typedef bit<8> switch_l4_port_label_t;

// Tunneling ------------------------------------------------------------------
enum switch_tunnel_mode_t { PIPE, UNIFORM }
typedef bit<4> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NONE = 0;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPV4INIPV4 = 2;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPV6OVERIPV4 = 3;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPV6INIPV6 = 4;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPV4OVERIPV6 = 5;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GRE = 6;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VXLAN = 7;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTPV0 = 8;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTPV1 = 9;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTPV2 = 10;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_L2TP = 11;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_TEREDO = 12;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPSEC_AH = 13;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_MPLS_L2 = 14;

typedef bit<16> switch_tunnel_index_t;
typedef bit<24> switch_tunnel_id_t;

// @pa_mutually_exclusive("ingress", "ig_md.tunnel.ethtype", "hdr.inner_etherII.ether_type")
@flexible
struct switch_tunnel_metadata_t {
    switch_tunnel_type_t type;
    //switch_tunnel_index_t index;
    // switch_tunnel_id_t id;
    bool full_parsed;
    bool ah_all_parsed;
    // ethtype_t ethtype;
    //switch_ifindex_t ifindex;
    //bit<16> hash;
    //bool terminate;
}

//-----------------------------------------------------------------------------
// Other Metadata Definitions
//-----------------------------------------------------------------------------
// Flags
//XXX Force the fields that are XORd to NOT share containers.
//@pa_container_size("ingress", "ig_md.checks.same_if", 16)
@flexible
struct switch_ingress_flags_t {
    bool unknown_pkt;
    bool ipv4_ihl_err;
    bool inner_ipv4_ihl_err;
    bool ipv4_checksum_err;
    bool inner_ipv4_checksum_err;
    bool tcp_hl_err;
    bool inner_tcp_hl_err;
    //bool acl_deny;
    //bool acl_meter_drop;
    //bool port_meter_drop;
    //bool capture_ts;
    // bool vlantags;
    bool mplslabels;
    //bool tunnels;
    // Add more flags here.
}

typedef bit<8> switch_hash8_key_ip_t;
typedef bit<16> switch_hash16_key_ip_t;
typedef bit<32> switch_hash32_key_ip_t;

@flexible
struct switch_hash_key_t {
    switch_hash8_key_ip_t sip32;
    switch_hash8_key_ip_t dip32;
    switch_hash8_key_ip_t sip16;
    switch_hash8_key_ip_t dip16;
    switch_hash8_key_ip_t sip8;
    switch_hash8_key_ip_t dip8;
}

typedef bit<2> switch_lkp_mode_t;
const switch_lkp_mode_t SWITCH_LKP_MODE_UNKNOWN = 0;
const switch_lkp_mode_t SWITCH_LKP_OUTER_DATA = 1;
const switch_lkp_mode_t SWITCH_LKP_INNER_DATA = 2;

typedef bit<4> switch_udf_pkt_type_t;
const switch_udf_pkt_type_t UDF_INVALID_TYPE = 0;
const switch_udf_pkt_type_t UDF_ETH802_3_UNKNW_L3 = 1;
const switch_udf_pkt_type_t UDF_ETHII_UNKNW_L3 = 2;
const switch_udf_pkt_type_t UDF_MPLS_UNKNW_L3 = 3;
const switch_udf_pkt_type_t UDF_INNER_ETHII_UNKNW_L3 = 4;
const switch_udf_pkt_type_t UDF_UNKNW_L4 = 5;
const switch_udf_pkt_type_t UDF_INNER_UNKNW_L4 = 6;
const switch_udf_pkt_type_t UDF_UNKNW_L5 = 10;
const switch_udf_pkt_type_t UDF_INNER_UNKNW_L5 = 11;
const switch_udf_pkt_type_t UDF_TUNNEL = 11;

typedef bit<(8*8)> switch_udf_grp_fld_t;
const switch_udf_grp_fld_t udf_grp_fld_invalid = 0;

typedef bit<(2*(8*8))> switch_udf_lkp_field_t;
const switch_udf_lkp_field_t udf_lkp_fld_invalid = 0;

typedef bit<(16*8)> switch_hbrd_lkp_field_t;
const switch_hbrd_lkp_field_t hbrd_lkp_fld_invalid = 0;

typedef bit<3> switch_vlan_tag_no_t;
const switch_vlan_tag_no_t vlan_unknowntagged = 0;
const switch_vlan_tag_no_t vlan_untagged = 1;
const switch_vlan_tag_no_t vlan_onetagged = 2;
const switch_vlan_tag_no_t vlan_doubletagged = 3;
const switch_vlan_tag_no_t vlan_moretagged = 4;

@pa_alias("ingress", "ig_md.lkp.mac_src_addr", "hdr.ethernet.src_addr")
@pa_alias("ingress", "ig_md.lkp.mac_dst_addr", "hdr.ethernet.dst_addr")
@pa_alias("ingress", "ig_md.lkp.ethtype", "hdr.etherII.ether_type")
@pa_container_size("ingress", "ig_md.lkp.ip_src_addr", 32, 32, 32, 32)
@pa_container_size("ingress", "ig_md.lkp.ip_dst_addr", 32, 32, 32, 32)
@pa_atomic("ingress", "ig_md.lkp.ipmode")
@pa_container_size("ingress", "ig_md.lkp.ip_proto", 8)
@pa_container_size("ingress", "ig_md.lkp.l4_src_port", 16)
@pa_container_size("ingress", "ig_md.lkp.l4_dst_port", 16)
@flexible
struct switch_lookup_fields_t {
    switch_gport_t gport; /* gport within pkt */
    //switch_pkt_length_t pkt_length;
    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    ethtype_t ethtype;
    //bit<3> pcp;
    // switch_vlan_tag_no_t tagno;
    //switch_tpid_t outertpid;
    //switch_tpid_t secondtpid;
    //switch_tpid_t thirdtpid;
    switch_vlan_tag_t outervlan;
    switch_vlan_tag_t secondvlan;
    switch_vlan_tag_t thirdvlan;
    switch_vlan_tag_t innervlan;

    // 1 for ARP request, 2 for ARP reply.
    //bit<16> arp_opcode;

    //bit<(switch_lkp_mode_width + switch_ip_type_width + switch_ip_frag_width)> mskipbits;
    // bit<(switch_lkp_mode_width + switch_ip_type_width)> mskipbits;
    // bit<(switch_lkp_mode_width + switch_ip_type_width)> ipmode;
    bit<4> ipmode;
    switch_lkp_mode_t lkp_mode;
    switch_ip_type_t ip_type;

    bit<8> ip_proto;
    //bit<8> ip_ttl;
    switch_ip_tos_t ip_tos;
    switch_ip_frag_t ip_frag;
    switch_ip_addr_t ip_src_addr;
    switch_ip_addr_t ip_dst_addr;

    bit<8> tcp_flags;
    switch_l4_port_t l4_src_port;
    switch_l4_port_t l4_dst_port;
}

typedef bit<(32*8)> switch_udf_field_t;
const switch_udf_field_t udf_invalid_fld = 0;

@flexible
struct switch_udf_metadata_t {
    switch_udf_pkt_type_t udf_pkt_type;
    switch_udf_field_t udf_fld;
}
typedef bit<16> switch_class_value_t;
const switch_class_value_t CLASS_VALUE_INVALID = 0;

typedef bit<24> switch_acl_priority_t;
const switch_acl_priority_t ACL_PRIORITY_INVALID = 0xffffff;

typedef bit<16> switch_acl_rule_label_t;
const switch_acl_rule_label_t ACL_RULE_LABEL_INVALID = 0;

@pa_mutually_exclusive("ingress", "ig_md.class.em1ip", "ig_md.class.emsip")
@pa_mutually_exclusive("ingress", "ig_md.class.em1ip", "ig_md.class.emdip")
@pa_mutually_exclusive("ingress", "ig_md.class.x1_class", "ig_md.class.mactype")
@pa_mutually_exclusive("ingress", "ig_md.class.x1_class", "ig_md.class.mskipx")

@pa_mutually_exclusive("ingress", "ig_md.class.x2_class", "ig_md.class.hybrid")

@pa_mutually_exclusive("ingress", "ig_md.class.x2_class", "ig_md.class.x1_class")

@pa_mutually_exclusive("ingress", "ig_md.class.x3_class", "ig_md.class.em1ip")
@pa_mutually_exclusive("ingress", "ig_md.class.x3_class", "ig_md.class.x2_class")
@pa_mutually_exclusive("ingress", "ig_md.class.acl_rule", "ig_md.class.mskip4")

@pa_mutually_exclusive("ingress", "ig_md.class.acl_rule", "ig_md.class.x3_class")
@pa_mutually_exclusive("ingress", "ig_md.class.em1ip_pri", "ig_md.class.emsip_pri")
@pa_mutually_exclusive("ingress", "ig_md.class.em1ip_pri", "ig_md.class.emdip_pri")
@pa_mutually_exclusive("ingress", "ig_md.class.x1_pri", "ig_md.class.mac_pri")
@pa_mutually_exclusive("ingress", "ig_md.class.x1_pri", "ig_md.class.mskipx_pri")

@pa_mutually_exclusive("ingress", "ig_md.class.x2_pri", "ig_md.class.hybrd_pri")

@pa_mutually_exclusive("ingress", "ig_md.class.x2_pri", "ig_md.class.x1_pri")

@pa_mutually_exclusive("ingress", "ig_md.class.x3_pri", "ig_md.class.em1ip_pri")
@pa_mutually_exclusive("ingress", "ig_md.class.x3_pri", "ig_md.class.x2_pri")
@pa_container_size("ingress", "ig_md.class.dstip_class", 16)
@pa_container_size("ingress", "ig_md.class.srcip_class", 16)
@pa_container_size("ingress", "ig_md.class.sdip_class", 16)
@pa_container_size("ingress", "ig_md.class.msksip_class", 16)
@pa_container_size("ingress", "ig_md.class.mskdip_class", 16)
@pa_container_size("ingress", "ig_md.class.emsip", 16)
@pa_container_size("ingress", "ig_md.class.emdip", 16)
@pa_container_size("ingress", "ig_md.class.em1ip", 16)
@pa_container_size("ingress", "ig_md.class.mskip4", 16)
@pa_container_size("ingress", "ig_md.class.mskipx", 16)
@pa_container_size("ingress", "ig_md.class.mactype", 16)
@pa_container_size("ingress", "ig_md.class.hybrid", 16)

@pa_container_size("ingress", "ig_md.class.mskipx_pri", 32)
@pa_container_size("ingress", "ig_md.class.mac_pri", 32)
# 773 "../../p4c-5296/types.p4"
@flexible
struct switch_classifier_fields_t {
    switch_class_value_t dstip_class;
    switch_class_value_t srcip_class;
    switch_class_value_t sdip_class;
    // switch_class_value_t msksdip_class;
    switch_class_value_t msksip_class;
    switch_class_value_t mskdip_class;
    switch_class_value_t emsip;
    switch_class_value_t emdip;
    switch_class_value_t em1ip;
    // switch_class_value_t emip;
    switch_class_value_t mskip4;
    switch_class_value_t mskipx;
    switch_class_value_t mactype;
    switch_class_value_t hybrid;
    switch_class_value_t x1_class;
    switch_class_value_t x2_class;
    switch_class_value_t x3_class;
    switch_class_value_t acl_rule;
    switch_acl_priority_t emsip_pri;
    switch_acl_priority_t emdip_pri;
    switch_acl_priority_t em1ip_pri;
    // switch_acl_priority_t emip_pri;
    switch_acl_priority_t mskip4_pri;
    switch_acl_priority_t mskipx_pri;
    switch_acl_priority_t mac_pri;
    switch_acl_priority_t hybrd_pri;
    switch_acl_priority_t x1_pri;
    switch_acl_priority_t x2_pri;
    switch_acl_priority_t x3_pri;
}

typedef bit<14> acl_action_stats_index_t;
const acl_action_stats_index_t ACL_UNKNOWN_ACTION_STATS_INDEX = 0;

typedef bit<8> switch_acl_action_prof_index_t;
const switch_acl_action_prof_index_t ACL_UNKNOWN_ACTION_PROF_INDEX = 0;

typedef switch_acl_action_prof_index_t switch_nexthop_t;

typedef bit<2> switch_udf_grp_sel_t;
const switch_udf_grp_sel_t sel_grp_invalid = 0;
const switch_udf_grp_sel_t sel_grp_abcd = 1;
const switch_udf_grp_sel_t sel_grp_acbd = 2;
const switch_udf_grp_sel_t sel_grp_adbc = 3;

typedef bit<4> switch_hybrid_acl_fld_sel_t;
const switch_hybrid_acl_fld_sel_t sel_invalid = 0;
const switch_hybrid_acl_fld_sel_t sel_sip6 = 1;
const switch_hybrid_acl_fld_sel_t sel_dip6 = 2;
/*sip4+dip4+lkp_mode+iptype+ip_frag(+ihl)+proto+iplen+l4_sport+l4_dport+tcpflags*/
const switch_hybrid_acl_fld_sel_t sel_ip4 = 3;
/*sip_class+dip_class+lkp_mode+iptype+ip_frag(+ihl)+proto+iplen+l4_sport+l4_dport+tcpflags*/
const switch_hybrid_acl_fld_sel_t sel_ipany = 4;
/*smac+dmac+ethtype+outervlan*/
const switch_hybrid_acl_fld_sel_t sel_eth = 5;
const switch_hybrid_acl_fld_sel_t sel_udf1 = 6;
const switch_hybrid_acl_fld_sel_t sel_udf2 = 7;
//...

typedef bit<2> switch_vlan_edit_mode_t;
const switch_vlan_edit_mode_t vlan_edit_mode_invalid = 0;
const switch_vlan_edit_mode_t vlan_edit_mode_add = 1;
const switch_vlan_edit_mode_t vlan_edit_mode_modify = 2;

typedef bit<3> switch_vlan_tag_type_t;
const switch_vlan_tag_type_t vlan_tag_type_invalid = 0;
const switch_vlan_tag_type_t vlan_tag_type_port = 1;
const switch_vlan_tag_type_t vlan_tag_type_rule = 2;
const switch_vlan_tag_type_t vlan_tag_type_udf = 3;
const switch_vlan_tag_type_t vlan_tag_type_portrule = 4;

@flexible
struct switch_pkt_action_vlan_fields_t {
    switch_vlan_tag_type_t type;
    switch_vlan_edit_mode_t mode;
    switch_vlan_tag_t vlantag;
}

typedef bit<3> switch_mac_edit_type_t;
const switch_mac_edit_type_t mac_edit_type_invalid = 0;
const switch_mac_edit_type_t mac_edit_type_port = 1;
const switch_mac_edit_type_t mac_edit_type_rule = 2;
const switch_mac_edit_type_t mac_edit_type_ts = 3;
const switch_mac_edit_type_t mac_edit_type_udf = 4;
// @pa_mutually_exclusive("egress", "eg_md.nhact.macact.smac", "hdr.ethernet.src_addr")
// @pa_mutually_exclusive("egress", "eg_md.nhact.macact.dmac", "hdr.ethernet.dst_addr")
@flexible
struct switch_pkt_action_mac_fields_t {
    switch_mac_edit_type_t smtype;
    mac_addr_t smac;
    switch_mac_edit_type_t dmtype;
    mac_addr_t dmac;
}

typedef bit<16> switch_acl_action_tunnel_bmp_t;
const switch_acl_action_tunnel_bmp_t tunnel_strip_none = 0x00;
const switch_acl_action_tunnel_bmp_t tunnel_strip_vlan = 0x01;
const switch_acl_action_tunnel_bmp_t tunnel_strip_mpls = 0x02;
const switch_acl_action_tunnel_bmp_t tunnel_strip_ipinip = 0x04;
const switch_acl_action_tunnel_bmp_t tunnel_strip_gre = 0x08;
const switch_acl_action_tunnel_bmp_t tunnel_strip_vxlan = 0x10;
const switch_acl_action_tunnel_bmp_t tunnel_strip_gtp = 0x20;
const switch_acl_action_tunnel_bmp_t tunnel_strip_l2tp = 0x40;
const switch_acl_action_tunnel_bmp_t tunnel_strip_outervlan = 0x80;
const switch_acl_action_tunnel_bmp_t tunnel_strip_doublevlan = 0x100;
// const switch_acl_action_tunnel_bmp_t tunnel_strip_threevlan = 0x200;
const switch_acl_action_tunnel_bmp_t tunnel_strip_teredo = 0x1000;
const switch_acl_action_tunnel_bmp_t tunnel_strip_ipsec_ah = 0x2000;
const switch_acl_action_tunnel_bmp_t tunnel_strip_l2 = 0x8000;

typedef bit<4> switch_hash_field_sel_t;
const switch_hash_field_sel_t hash_sel_unset = 0;
const switch_hash_field_sel_t hash_sel_outer_sip = 1;
const switch_hash_field_sel_t hash_sel_outer_dip = 2;
const switch_hash_field_sel_t hash_sel_outer_sdip = 3;
const switch_hash_field_sel_t hash_sel_outer_sdip_sdport = 4;
const switch_hash_field_sel_t hash_sel_outer_sdip_sdport_proto = 5;
const switch_hash_field_sel_t hash_sel_inner_sip = 8;
const switch_hash_field_sel_t hash_sel_inner_dip = 9;
const switch_hash_field_sel_t hash_sel_inner_sdip = 10;
const switch_hash_field_sel_t hash_sel_inner_sdip_sdport = 11;
const switch_hash_field_sel_t hash_sel_inner_sdip_sdport_proto = 12;

typedef bit<3> switch_hash_algo_sel_t;
const switch_hash_algo_sel_t hash_algo_unset = 0;
const switch_hash_algo_sel_t hash_algo_crc = 1;
const switch_hash_algo_sel_t hash_algo_xor = 2;
const switch_hash_algo_sel_t hash_algo_add = 3;
const switch_hash_algo_sel_t hash_algo_sub = 4;

typedef bit<2> switch_dlb_mode_sel_t;
const switch_dlb_mode_sel_t dlb_mode_unset = 0;
const switch_dlb_mode_sel_t dlb_mode_hash = 1;
const switch_dlb_mode_sel_t dlb_mode_rr = 2;
const switch_dlb_mode_sel_t dlb_mode_random = 3;

typedef bit<4> switch_dlb_sel_t;
const switch_dlb_sel_t dlb_unset = 0;
const switch_dlb_sel_t dlb_rr = 1;
const switch_dlb_sel_t dlb_random = 2;
const switch_dlb_sel_t dlb_hash_sel_outer_sip = 4;
const switch_dlb_sel_t dlb_hash_sel_outer_dip = 5;
const switch_dlb_sel_t dlb_hash_sel_outer_sdip = 6;
const switch_dlb_sel_t dlb_hash_sel_outer_sdip_sdport = 7;
const switch_dlb_sel_t dlb_hash_sel_outer_sdip_sdport_proto = 8;
const switch_dlb_sel_t dlb_hash_sel_inner_sip = 10;
const switch_dlb_sel_t dlb_hash_sel_inner_dip = 11;
const switch_dlb_sel_t dlb_hash_sel_inner_sdip = 12;
const switch_dlb_sel_t dlb_hash_sel_inner_sdip_sdport = 13;
const switch_dlb_sel_t dlb_hash_sel_inner_sdip_sdport_proto = 14;

struct switch_nh_np_cookie_t {
    bit<1> multiuser;
    switch_acl_action_prof_index_t apid;
}

@flexible
struct switch_hash_sel_t {
    switch_hash_field_sel_t field;
    switch_hash_algo_sel_t algo;
}

struct switch_acl_action_dlb_sel_t {
    switch_dlb_mode_sel_t dlbmode;
    switch_hash_sel_t hashsel;
}

@flexible
struct switch_ip_hash_field_t {
    switch_ip_type_t ip_type;
    switch_ip_addr_t sip;
    switch_ip_addr_t dip;

    // switch_ip_addr_sign_t ip_src_sign;
    // switch_ip_addr_sign_t ip_dst_sign;
    bool xhash;

    switch_l4_port_t sport;
    switch_l4_port_t dport;
    bit<8> proto;
}

// @pa_alias("ingress", "ig_md.aclact.apid", "hdr.np_rx.apid")
@flexible
struct switch_acl_action_fields_t {
    switch_acl_action_prof_index_t apid;
    switch_acl_rule_label_t rule_label;
    // bool  deny;
    // bool  copytocpu;
    switch_mirror_metadata_t mirror;

    // switch_acl_action_dlb_sel_t dlbsel;
}

struct switch_nexthop_action_fields_t {
    switch_pkt_action_vlan_fields_t vlanact;
    switch_pkt_length_t trunclen;
    switch_pkt_action_mac_fields_t macact;

    switch_acl_action_tunnel_bmp_t tunnels;

    // switch_nh_np_cookie_t cookie;
}

// packet Sample ----------------------------------------------------------------------

typedef bit<8> switch_sample_id_t;
const switch_sample_id_t SWITCH_SAMPLE_INVALID_ID = 0;

struct switch_sample_metadata_t {
    // switch_sample_id_t sample_id;
    bit<1> sample_packet;
}

struct switch_timer_info_t {
    bit<32> current;
    bit<32> start;
    // bit<32> seconds;
}

struct switch_timer_md_t {
    bit<1> reached;
}

// typedef bit<32> sub_lag_t;
typedef bit<8> sub_lag_t;
struct switch_outgrp_hashadapter_t {
    // bit<32> start;
    sub_lag_t current;
    // bit<32> nums;
}

typedef bit<3> switch_porttype_t;
const switch_porttype_t SWITCH_PORT_TYPE_FP = 0;
const switch_porttype_t SWITCH_PORT_TYPE_NP = 1;
const switch_porttype_t SWITCH_PORT_TYPE_LB = 2;
const switch_porttype_t SWITCH_PORT_TYPE_CPU = 3;
const switch_porttype_t SWITCH_PORT_TYPE_BP = 4;
const switch_porttype_t SWITCH_PORT_TYPE_RP = 5;
const switch_porttype_t SWITCH_PORT_TYPE_RC = 6;

typedef bit<1> switch_matchmode_t;
const switch_matchmode_t SWITCH_MATCHMODE_AUTO = 0;
const switch_matchmode_t SWITCH_MATCHMODE_OUTER = 1;

typedef bit<2> switch_brdgmode_t;
const switch_brdgmode_t SWITCH_BRDGMODE_BGDEF = 0;
const switch_brdgmode_t SWITCH_BRDGMODE_BGFIRST = 1;
const switch_brdgmode_t SWITCH_BRDGMODE_BGONLY = 2;

typedef bit<1> switch_fwdmode_t;
const switch_fwdmode_t SWITCH_FWDMODE_PORT = 0;
const switch_fwdmode_t SWITCH_FWDMODE_LAG = 1;

typedef bit<8> switch_port_mix_t; //fwdmode+brdgmode+porttype+matchmode
typedef bit<3> switch_uid_t;

typedef bit<8> switch_port_control_t;
const switch_port_control_t SWITCH_PC_NONE = 0x00;
const switch_port_control_t SWITCH_PC_MPLS_USE_PW = 0x01;
const switch_port_control_t SWITCH_PC_ADD_PTAG = 0x02;

// @pa_alias("ingress", "ig_md.port_info.ingroup", "hdr.lb.src_ingroup")
// @pa_mutually_exclusive("ingress", "ig_md.port_md.port_label", "hdr.lb.src_port_label")
// @pa_mutually_exclusive("ingress", "ig_md.port_md.port_label", "hdr.np_tx.lport")
// @pa_alias("ingress", "ig_md.port_md.mix", "hdr.np_tx.mix")
// @pa_container_size("ingress", "ig_md.port_info.uid", 8)

// @pa_solitary("ingress", "ig_md.port_md.matchmode")
@flexible
struct switch_port_metadata_t {
    switch_port_fwd_index_t brdg_intf;
    switch_mgid_t brdg_mc;
    // switch_fwdmode_t fwdmode;
    // switch_brdgmode_t brdgmode;
    // switch_porttype_t porttype;
    // switch_matchmode_t matchmode;
    switch_port_mix_t portmix;
    /*
    *portmix[6:6] fwdmode;
    *portmix[5:4] brdgmode;
    *portmix[3:1] porttype;
    *portmix[0:0] matchmode;
    */
# 1077 "../../p4c-5296/types.p4"
    switch_port_label_t port_label;
    switch_sample_id_t sample_id;
    switch_port_control_t flags;
}

@pa_container_size("ingress", "ig_md.port_info.ingroup", 8)
@flexible
struct switch_port_properties_t {
    switch_port_ingroup_t ingroup;
    switch_port_tag_t port_tag;
    // switch_brdgmode_t brdgmode;
    switch_dlb_sel_t dlbsel;
    // sub_lag_t sub_lag;
    switch_uid_t uid;
}

struct prel2_eth_t {
    mac_addr_t dmac;
    mac_addr_t smac;
    // ethtype_t ether_type;
}

struct switch_ingress_global_info_t {
    bit<1> mc_rr;
}

typedef bit<48> switch_timestamp_t;
// @pa_no_overlay("ingress", "ig_intr_md_for_dprsr.drop_ctl")
@pa_alias("ingress", "ig_md.port", "ig_intr_md.ingress_port")
// @pa_alias("ingress", "ig_md.timestamp", "ig_intr_md.ingress_mac_tstamp")
// @pa_mutually_exclusive("ingress", "ig_md.timestamp", "hdr.np_tx.ts")
@pa_alias("ingress", "ig_md.egress_port", "ig_intr_md_for_tm.ucast_egress_port")
// @pa_alias("ingress", "ig_md.mgid", "ig_intr_md_for_tm.mcast_grp_a")
// @pa_alias("ingress", "ig_md.mgid2", "ig_intr_md_for_tm.mcast_grp_b")
@pa_alias("ingress", "ig_md.aclact.mirror.type", "ig_intr_md_for_dprsr.mirror_type")

@pa_mutually_exclusive("ingress", "ig_md.hash", "hdr.np_rx.hash")
// @pa_container_size("ingress", "ig_md.upd_csum", 8)
// @pa_container_size("ingress", "ig_md.bypass", 8)
// @pa_alias("ingress", "ig_md.copytocpu", "ig_intr_md_for_tm.copy_to_cpu")
// @pa_solitary("ingress", "ig_intr_md_for_tm.copy_to_cpu")
// @pa_solitary("ingress", "ig_md.sample.sample_packet")
// @pa_solitary("ingress", "ig_md.pkt_type.l4type")
// @pa_container_size("ingress", "ig_md.pkt_type.l4type", 8)

@pa_alias("ingress", "ig_md.outer_hash.sip", "hdr.ipv6.src_addr")
@pa_alias("ingress", "ig_md.outer_hash.dip", "hdr.ipv6.dst_addr")
@pa_mutually_exclusive("ingress", "ig_md.outer_hash.sport", "hdr.tcp.src_port")
@pa_mutually_exclusive("ingress", "ig_md.outer_hash.dport", "hdr.tcp.dst_port")

@pa_alias("ingress", "ig_md.inner_hash.sip", "hdr.inner_ipv6.src_addr")
@pa_alias("ingress", "ig_md.inner_hash.dip", "hdr.inner_ipv6.dst_addr")
@pa_mutually_exclusive("ingress", "ig_md.inner_hash.sport", "hdr.inner_tcp.src_port")
@pa_mutually_exclusive("ingress", "ig_md.inner_hash.dport", "hdr.inner_tcp.dst_port")

// @pa_container_size("ingress", "ig_md.gport_hash", 32)
@pa_container_size("ingress", "ig_intr_md_for_dprsr.drop_ctl", 8)

// Ingress metadata
@flexible
struct switch_ingress_metadata_t {
    switch_port_t port; /* ingress port */
    switch_port_metadata_t port_md; /* ingress port info */
    switch_port_properties_t port_info; /* ingress port extra info */
    switch_port_t egress_port; /* egress port */
    switch_gport_t srcport;
    switch_gport_t gport; /* ingress gport */
    switch_port_lag_index_t egr_port_lag_index; /* ingress port/lag index */
    switch_mgid_t mgid;
    switch_mgid_t mgid2;
    switch_ingress_global_info_t glb_info;
    switch_pkt_type_t pkt_type;
    //switch_pkt_type_t inner_pkt_type;
    switch_sample_metadata_t sample;
    switch_timer_md_t time;

    switch_ingress_flags_t flags;
    switch_drop_reason_t drop_reason;

    // switch_timestamp_t timestamp;
    switch_hash_t hash;
    switch_hash_t gport_hash;

    switch_lookup_fields_t lkp;
    switch_ip_hash_field_t outer_hash;
    switch_ip_hash_field_t inner_hash;
    switch_tunnel_metadata_t tunnel;
    // switch_udf_metadata_t udf;
    switch_classifier_fields_t class;

    switch_acl_action_fields_t aclact;
    switch_ingress_bypass_t igr_bypass;

    bool bypass;
    bool deny;

    bp_cookie_t cookie;
}

// @pa_alias("ingress", "hdr.bridged_md.src", "ig_md.aclact.mirror.src")
// @pa_alias("ingress", "hdr.bridged_md.type", "ig_md.aclact.mirror.type")
// @pa_alias("ingress", "hdr.bridged_md.inport", "ig_md.port_md.port_label")
@pa_alias("ingress", "hdr.bridged_md.srcport", "ig_md.srcport")
@pa_alias("ingress", "hdr.bridged_md.port_tag", "ig_md.port_info.port_tag")
@pa_alias("ingress", "hdr.bridged_md.rule_label", "ig_md.aclact.rule_label")
@pa_alias("ingress", "hdr.bridged_md.gport", "ig_md.gport")

@pa_alias("ingress", "hdr.bridged_md.egr_port_lag_index", "ig_md.egr_port_lag_index")

@pa_alias("ingress", "hdr.bridged_md.bypass", "ig_md.bypass")
@pa_alias("ingress", "hdr.bridged_md.uid", "ig_md.port_info.uid")
@pa_alias("ingress", "hdr.bridged_md.nhid", "ig_md.aclact.apid")
@pa_alias("ingress", "hdr.bridged_md.hash", "ig_md.hash")
@pa_alias("ingress", "hdr.bridged_md.cookie", "ig_md.cookie")
// @pa_solitary("ingress", "hdr.bridged_md.validity")

header switch_bridged_metadata_h {
    switch_pkt_src_t src;
    // switch_bridge_type_t type;
    // switch_port_label_t inport;
    switch_gport_t srcport;
    switch_gport_t gport;

    @padding bit<7> rsvd;
    switch_port_lag_index_t egr_port_lag_index;

    switch_port_tag_t port_tag;
    switch_acl_rule_label_t rule_label;
    @padding bit<5> pad0;
    switch_uid_t uid;

    switch_nexthop_t nhid;
    // switch_timestamp_t ts;
    switch_hash_t hash;
    @padding bit<7> pad2;
    bool bypass;

    @padding bit<7> pad3;
    bool inner_parsed;
    @padding bit<6> pad4;
    switch_ip_type_t inner_ip_type;

    bp_cookie_t cookie;
    switch_port_control_t flags;
}

@flexible
struct switch_egrport_properties_t {
    bool dis_rewrite;
    bool strip_ptag;

}

struct switch_pkt_info_t {
    switch_ip_type_t outer_ip_type;
    switch_ip_type_t inner_ip_type;
    // switch_port_control_t flags;
}

/********  G L O B A L   E G R E S S   M E T A D A T A  *********/
@egress_intrinsic_metadata_opt
@pa_alias("egress", "eg_md.egr_port", "eg_intr_md.egress_port")
// @pa_alias("egress", "hdr.bridged_md.src", "eg_md.src")
// @pa_alias("egress", "hdr.bridged_md.type", "eg_md.type")
@pa_alias("egress", "hdr.bridged_md.srcport", "eg_md.srcport")
@pa_alias("egress", "hdr.bridged_md.port_tag", "eg_md.inport_tag")
@pa_alias("egress", "hdr.bridged_md.rule_label", "eg_md.rule_label")
@pa_alias("egress", "hdr.bridged_md.uid", "eg_md.uid")
@pa_alias("egress", "hdr.bridged_md.nhid", "eg_md.nhid")
@pa_alias("egress", "hdr.bridged_md.hash", "eg_md.hash")
// @pa_alias("egress", "eg_intr_md_from_prsr.global_tstamp", "eg_md.ts")
@pa_alias("egress", "hdr.bridged_md.gport", "eg_md.gport")

@pa_alias("egress", "hdr.bridged_md.egr_port_lag_index", "eg_md.egr_port_lag_index")

@pa_alias("egress", "hdr.bridged_md.bypass", "eg_md.bypass")
@pa_alias("egress", "hdr.bridged_md.cookie", "eg_md.cookie")
@pa_alias("egress", "hdr.bridged_md.flags", "eg_md.flags")

@flexible
struct switch_egress_metadata_t {
    switch_port_t egr_port;
    switch_gport_t srcport;
    switch_gport_t gport; /* egress gport */
    switch_port_lag_index_t egr_port_lag_index; /* egress port/lag index */
    switch_egrport_properties_t port_info; /* egress port extra info */
    switch_pkt_src_t src;
    // switch_bridge_type_t type;
    // switch_port_label_t inport;
    switch_port_tag_t inport_tag;
    switch_acl_rule_label_t rule_label;

    switch_pkt_info_t pkt_info;

    // @padding bit<5> pad0;
    switch_uid_t uid;
    // @padding bit<6> pad1;
    switch_nexthop_t nhid;
    switch_nexthop_action_fields_t nhact;

    switch_tunnel_metadata_t tunnel;

    // switch_timestamp_t ts;
    switch_hash_t hash;
    bool bypass;

    bp_cookie_t cookie;
    switch_port_control_t flags;

}

// @pa_mutually_exclusive("ingress", "hdr.np_tx", "hdr.np_rx")

// @pa_mutually_exclusive("ingress", "hdr.np_rx", "hdr.lb")

@pa_mutually_exclusive("egress", "hdr.bp.tpid", "hdr.np_ethtype.ether_type")

@pa_mutually_exclusive("egress", "hdr.lb.tpid", "hdr.np_ethtype.ether_type")

@pa_mutually_exclusive("egress", "hdr.xge_port.tpid", "hdr.np_ethtype.ether_type")

@pa_mutually_exclusive("ingress", "hdr.ipv4.version", "hdr.ipv6.version")
@pa_mutually_exclusive("ingress", "hdr.ipv4.diffserv", "hdr.ipv6.traffic_class")
@pa_mutually_exclusive("ingress", "hdr.ipv4.total_len", "hdr.ipv6.payload_len")
@pa_mutually_exclusive("ingress", "hdr.ipv4.protocol", "hdr.ipv6.next_hdr")
@pa_mutually_exclusive("ingress", "hdr.ipv4.ttl", "hdr.ipv6.hop_limit")
@pa_mutually_exclusive("ingress", "hdr.ipv4.src_addr", "hdr.ipv6.src_addr")
@pa_mutually_exclusive("ingress", "hdr.ipv4.dst_addr", "hdr.ipv6.dst_addr")
@pa_mutually_exclusive("egress", "hdr.ipv4.version", "hdr.ipv6.version")
@pa_mutually_exclusive("egress", "hdr.ipv4.diffserv", "hdr.ipv6.traffic_class")
@pa_mutually_exclusive("egress", "hdr.ipv4.total_len", "hdr.ipv6.payload_len")
@pa_mutually_exclusive("egress", "hdr.ipv4.protocol", "hdr.ipv6.next_hdr")
@pa_mutually_exclusive("egress", "hdr.ipv4.ttl", "hdr.ipv6.hop_limit")
@pa_mutually_exclusive("egress", "hdr.ipv4.src_addr", "hdr.ipv6.src_addr")
@pa_mutually_exclusive("egress", "hdr.ipv4.dst_addr", "hdr.ipv6.dst_addr")

@pa_mutually_exclusive("ingress", "hdr.tcp.src_port", "hdr.udp.src_port")
@pa_mutually_exclusive("ingress", "hdr.tcp.dst_port", "hdr.udp.dst_port")
@pa_mutually_exclusive("ingress", "hdr.tcp.src_port", "hdr.sctp.src_port")
@pa_mutually_exclusive("ingress", "hdr.tcp.dst_port", "hdr.sctp.dst_port")
@pa_mutually_exclusive("egress", "hdr.tcp.src_port", "hdr.udp.src_port")
@pa_mutually_exclusive("egress", "hdr.tcp.dst_port", "hdr.udp.dst_port")
@pa_mutually_exclusive("egress", "hdr.tcp.src_port", "hdr.sctp.src_port")
@pa_mutually_exclusive("egress", "hdr.tcp.dst_port", "hdr.sctp.dst_port")
// @pa_mutually_exclusive("ingress", "hdr.tcp", "hdr.gre")
# 1402 "../../p4c-5296/types.p4"
@pa_mutually_exclusive("ingress", "hdr.inner_ipv4.version", "hdr.inner_ipv6.version")
@pa_mutually_exclusive("ingress", "hdr.inner_ipv4.diffserv", "hdr.inner_ipv6.traffic_class")
@pa_mutually_exclusive("ingress", "hdr.inner_ipv4.total_len", "hdr.inner_ipv6.payload_len")
@pa_mutually_exclusive("ingress", "hdr.inner_ipv4.protocol", "hdr.inner_ipv6.next_hdr")
@pa_mutually_exclusive("ingress", "hdr.inner_ipv4.ttl", "hdr.inner_ipv6.hop_limit")
@pa_mutually_exclusive("ingress", "hdr.inner_ipv4.src_addr", "hdr.inner_ipv6.src_addr")
@pa_mutually_exclusive("ingress", "hdr.inner_ipv4.dst_addr", "hdr.inner_ipv6.dst_addr")
# 1419 "../../p4c-5296/types.p4"
@pa_mutually_exclusive("ingress", "hdr.inner_tcp.src_port", "hdr.inner_udp.src_port")
@pa_mutually_exclusive("ingress", "hdr.inner_tcp.dst_port", "hdr.inner_udp.dst_port")
@pa_mutually_exclusive("ingress", "hdr.inner_tcp.src_port", "hdr.inner_sctp.src_port")
@pa_mutually_exclusive("ingress", "hdr.inner_tcp.dst_port", "hdr.inner_sctp.dst_port")
# 1433 "../../p4c-5296/types.p4"
@pa_container_size("ingress", "hdr.ethernet.src_addr", 16, 32)
@pa_container_size("ingress", "hdr.ethernet.dst_addr", 16, 32)

struct switch_header_t {
    switch_bridged_metadata_h bridged_md;
# 1453 "../../p4c-5296/types.p4"
    pktgen_timer_header_t timer;

    ethernet_h ethernet;
    ethernet802_3_h ether802_3;

    lb_h lb;

    bp_h bp;

    xgp_h xge_port;

    npu_rx_h np_rx;

    nps_tx_h nps_tx;

    ethernetII_h np_ethtype;
    ipv4_h np_tx;

    vlan_tag_h vlan_add;
    vlan_tag_h[4] vlan_tag;
    ethernetII_h etherII;

    ipv4_h gre_ip;
    gre_h gre_add;

    pppoe_session_h pppoe;
    mpls_h[5] mpls;
    pw_h pw;
    ipv4_h ipv4;
# 1507 "../../p4c-5296/types.p4"
    ipv4_option_h ipv4_options;

    ipv6_h ipv6;

    ipv6_ext_h ipv6_ext;

    ipv6_frag_h ipv6_frag;

    ipsec_ah_h ipsec_ah;
    ipsec_ah_opt_h[3] ipsec_ah_opt;
    ipsec_esp_h ipsec_esp;
    udp_h udp;
    sctp_h sctp;

    // igmp_h igmp;
    tcp_h tcp;
# 1539 "../../p4c-5296/types.p4"
    tcp_option_h tcp_options;

    vxlan_h vxlan;
    gre_h gre;
    gre_option_h[3] gre_opts;
    l2tp_h l2tp;
    l2tp_option_h l2tp_opts;
    p2p_t p2p;

    gtpv1_t gtpv1;
    gtpv1_option_h gtpv1_opts;
    gtpv1_exthdr_h[2] gtpv1_ext;

    ethernet_h inner_ethernet;
    ethernet802_3_h inner_ether802_3;
    vlan_tag_h[4] inner_vlan_tag;
    ethernetII_h inner_etherII;
    mpls_h[5] inner_mpls;
    ipv4_h inner_ipv4;
# 1576 "../../p4c-5296/types.p4"
    ipv4_option_h inner_ipv4_options;

    ipv6_h inner_ipv6;

    ipv6_ext_h inner_ipv6_ext;

    ipv6_frag_h inner_ipv6_frag;

    udp_h inner_udp;
    tcp_h inner_tcp;

    sctp_h inner_sctp;
    // icmp_h inner_icmp;
}
# 4 "../../p4c-5296/parde.p4" 2

//=============================================================================
// Ingress parser
//=============================================================================
parser SwitchIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
# 30 "../../p4c-5296/parde.p4"
    bit<36> data = 0;
    //value_set<bit<16>>(1) udp_port_vxlan;
    // value_set<bit<1>>(1) matchmode;

    ParserCounter() optlen;

    state start {
        pkt.extract(ig_intr_md);
        ig_md.port = ig_intr_md.ingress_port;
        // ig_md.timestamp = ig_intr_md.ingress_mac_tstamp;
        // Check for resubmit flag if packet is resubmitted.
        // transition select(ig_intr_md.resubmit_flag) {
        //    1 : parse_resubmit;
        //    0 : parse_port_metadata;
        // }
        transition parse_port_metadata;
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition accept;
    }

    state parse_port_metadata {
        // Parse port metadata produced by ibuf
        //switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);
        ig_md.port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);
        //init metadata;
        // ig_md.egr_port_lag_index = SWITCH_PORT_LAG_INVALID;
        ig_md.gport = SWITCH_GPORT_INVALID;
        ig_md.srcport = ig_md.port_md.port_label;
        // ig_md.aclact.apid = ACL_UNKNOWN_ACTION_PROF_INDEX;
# 76 "../../p4c-5296/parde.p4"
        ig_md.igr_bypass = SWITCH_INGRESS_BYPASS_NONE;
        ig_md.deny = false;
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_NONE;
        ig_md.tunnel.full_parsed = false;
# 102 "../../p4c-5296/parde.p4"
        transition parse_packet;

    }

    state parse_packet {
# 121 "../../p4c-5296/parde.p4"
        transition parse_ethernet;

    }
# 215 "../../p4c-5296/parde.p4"
    state parse_npu {
        pkt.extract(hdr.np_rx);
        ig_md.igr_bypass = SWITCH_INGRESS_BYPASS_ACLRULE;
        // ig_md.aclact.apid = (switch_acl_action_prof_index_t)hdr.np_rx.apid;

        transition select(pkt.lookahead<ethtype_t>()) {
            0x8100 &&& 0xefff: parse_vlan;

            default : parse_ethernetII;
        }

        //transition accept;
    }

    state parse_lbp {
        pkt.extract(hdr.lb);
        transition select(pkt.lookahead<ethtype_t>()) {
            0x8100 &&& 0xefff: parse_vlan;

            default : parse_ethernetII;
        }
        //transition accept;
    }

    state parse_bp_raw {
        transition select(pkt.lookahead<ethtype_t>()) {
            0x8100 &&& 0xefff: parse_vlan;

            default : parse_ethernetII;
        }
    }
# 278 "../../p4c-5296/parde.p4"
    state parse_bp {
        pkt.extract(hdr.bp);
        // ig_md.flags.bp_pkt = true;
        ig_md.gport = hdr.bp.gport;
        // ig_md.igr_bypass = (SWITCH_INGRESS_BYPASS_ACLRULE | SWITCH_INGRESS_BYPASS_ACLACT);
        // ig_md.port_md.matchmode = hdr.lb.matchmode;
        transition parse_bp_raw;
    }

    state parse_xge_port {
        pkt.extract(hdr.xge_port);
        // ig_md.port_md.matchmode = hdr.lb.matchmode;
        transition select(pkt.lookahead<ethtype_t>()) {
            0x8100 &&& 0xefff: parse_vlan;

            default : parse_ethernetII;
        }
        //transition accept;
    }
# 321 "../../p4c-5296/parde.p4"
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(pkt.lookahead<ethtype_t>(), ig_md.port_md.portmix[3:1]) {
            (0x9200, SWITCH_PORT_TYPE_BP) : parse_bp;

            (0x9200, SWITCH_PORT_TYPE_NP) : parse_npu;

            (0x8100, SWITCH_PORT_TYPE_RP) : parse_xge_port;

            (0x9200, SWITCH_PORT_TYPE_LB) : parse_lbp;

            (0x8100 &&& 0xefff, _) : parse_vlan;

            default : parse_ethernetII;
        }
    }

    state parse_ethernet802_3 {
        //ig_md.pkt_type.l2type = switch_pkt_l2_type_t.L2TYPE_ETHERNET_802_3;
        pkt.extract(hdr.ether802_3);
        transition accept;
    }

    state parse_ethernetII {
        //ig_md.pkt_type.l2type = switch_pkt_l2_type_t.L2TYPE_ETHERNET_II;
        pkt.extract(hdr.etherII);
        //ethtype = hdr.etherII.ether_type;
        transition parse_ethtype;
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        //ethtype = hdr.vlan_tag.last.ether_type;
        transition select(pkt.lookahead<ethtype_t>()) {
            0x8100 &&& 0xefff : parse_vlan;
            default : parse_ethernetII;
        }
    }

    state parse_ethtype {
        //transition select(ethtype) {
        transition select(hdr.etherII.ether_type) {

            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            0x8847 : parse_mpls;
            0x8848 : parse_mpls;
            0x8864 : parse_pppoe;
            default : accept;
        }
    }

    state parse_pppoe {
        pkt.extract(hdr.pppoe);
        transition select(hdr.pppoe.protocol) {
            0x21 : parse_ipv4;
            0x57 : parse_ipv6;
            default : accept;
        }
    }

    state parse_mpls {
        //ig_md.pkt_type.l3type = switch_pkt_l3_type_t.MPLS;
        pkt.extract(hdr.mpls.next);
        transition select(hdr.mpls.last.bos) {
            0 : parse_mpls;
            default : parse_mpls_data;
        }
    }

    state parse_mpls_data {
        data = pkt.lookahead<bit<36>>();
        transition select(data[35:32], data[3:0]) {
            (4, _) : parse_ipv4;
            (6, _) : parse_ipv6;
            (_, 4) : parse_pw_ipv4;
            (_, 6) : parse_pw_ipv6;

            default : parse_mpls_l2;

        }
    }

    state parse_pw_ipv4 {
        pkt.extract(hdr.pw);
        transition parse_ipv4;
    }

    state parse_pw_ipv6 {
        pkt.extract(hdr.pw);
        transition parse_ipv6;
    }

    state parse_mpls_l2 {
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_MPLS_L2;
        transition select(ig_md.port_md.flags) {
            SWITCH_PC_MPLS_USE_PW &&& SWITCH_PC_MPLS_USE_PW : parse_pw_l2;
            default : parse_inner_ethernet;
        }
    }

    state parse_pw_l2 {
        pkt.extract(hdr.pw);
        transition parse_inner_ethernet;
    }

    state parse_ipv4 {
        //ig_md.pkt_type.l3type = switch_pkt_l3_type_t.L3TYPE_IPV4;
        pkt.extract(hdr.ipv4);
# 474 "../../p4c-5296/parde.p4"
        transition select(hdr.ipv4.ihl, hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (5, 6, 0) : parse_tcp;
            (5, 17, 0) : parse_udp;
            (5, 132, 0) : parse_sctp;

            (5, 4, 0) : parse_ipv4inipv4;
            (5, 41, 0) : parse_ipv6overipv4;
            (5, 47, 0) : parse_gre;
            //IP_PROTOCOLS_IPSEC_ESP : parse_ipsec_esp;

            //IP_PROTOCOLS_OSPF : parse_ospf;
            (5, 115, 0) : parse_l2tp;

            (0 &&& 0xC, _, _) : accept;
            (4, _, _) : accept;

            (6, _, 0) : parse_ipv4_options;

            // Do NOT parse the next header if IP packet is fragmented.
            default : accept;
        }

    }

    state parse_ipv4_err_ihl {
        ig_md.flags.ipv4_ihl_err = true;
        transition accept;//reject;
    }

    state parse_ipv4_options {
# 531 "../../p4c-5296/parde.p4"
        pkt.extract(hdr.ipv4_options);

        transition parse_ipv4_no_options;

    }

/*

#define PARSE_L4_UDF_FIELD                                          ig_md.udf.l4_udf = pkt.lookahead<switch_udf_field_t>();         ig_md.udf.udf_valid_bits = UDF_L4_VALID;
ALID;
    //ig_md.udf.udf_valid_bits[UDF_L4_BIT:UDF_L4_BIT] = 1;

*/
# 546 "../../p4c-5296/parde.p4"
    state parse_ipv4_no_options {
# 565 "../../p4c-5296/parde.p4"
        transition select(hdr.ipv4.protocol) {
            (6) : parse_tcp;
            (17) : parse_udp;
            (132) : parse_sctp;

            (4) : parse_ipv4inipv4;
            (41) : parse_ipv6overipv4;
            (47) : parse_gre;
            //IP_PROTOCOLS_IPSEC_ESP : parse_ipsec_esp;

            //IP_PROTOCOLS_OSPF : parse_ospf;
            (115) : parse_l2tp;

            default : accept;
        }

    }

    state parse_ipv6 {
        //ig_md.pkt_type.l3type = switch_pkt_l3_type_t.L3TYPE_IPV6;
        pkt.extract(hdr.ipv6);
# 613 "../../p4c-5296/parde.p4"
        transition select(hdr.ipv6.next_hdr) {
            6 : parse_tcp;
            17 : parse_udp;
            132 : parse_sctp;

            //IP_PROTOCOLS_ICMPV6 : parse_icmp;
            4 : parse_ipv4overipv6;
            41 : parse_ipv6inipv6;
            47 : parse_gre;
            //IP_PROTOCOLS_IPSEC_ESP : parse_ipsec_esp;

            //IP_PROTOCOLS_OSPF : parse_ospf;
            115 : parse_l2tp;

            0 : parse_ipv6_ext;
            60 : parse_ipv6_ext;
            43 : parse_ipv6_ext;

            44 : parse_ipv6_frag;

            default : accept;
        }

    }

    state parse_ipv6_ext {
        pkt.extract(hdr.ipv6_ext);
        // proto = hdr.ipv6_frag.next_hdr;
        transition select(hdr.ipv6_ext.ext_hdr_len, hdr.ipv6_ext.next_hdr) {

            (0, 44) : parse_ipv6_frag;

            (0, 6) : parse_tcp;
            (0, 17) : parse_udp;
            (0, 132) : parse_sctp;

            //IP_PROTOCOLS_ICMPV6 : parse_icmp;
            (0, 4) : parse_ipv4overipv6;
            (0, 41) : parse_ipv6inipv6;
            (0, 47) : parse_gre;
            //IP_PROTOCOLS_IPSEC_ESP : parse_ipsec_esp;

            //IP_PROTOCOLS_OSPF : parse_ospf;
            (0, 115) : parse_l2tp;

            default : accept;
        }
    }

    state parse_ipv6_frag {
        pkt.extract(hdr.ipv6_frag);
        // proto = hdr.ipv6_frag.next_hdr;
        transition select(hdr.ipv6_frag.next_hdr) {
            6 : parse_tcp;
            17 : parse_udp;
            132 : parse_sctp;

            //IP_PROTOCOLS_ICMPV6 : parse_icmp;
            4 : parse_ipv4overipv6;
            41 : parse_ipv6inipv6;
            47 : parse_gre;
            //IP_PROTOCOLS_IPSEC_ESP : parse_ipsec_esp;

            //IP_PROTOCOLS_OSPF : parse_ospf;
            115 : parse_l2tp;

            default : accept;
        }
    }
# 758 "../../p4c-5296/parde.p4"
    state parse_ipsec_esp {
        pkt.extract(hdr.ipsec_esp);
        transition accept;
    }
# 778 "../../p4c-5296/parde.p4"
/*

#define PARSE_L5_UDF_FIELD                                          ig_md.udf.l5_udf = pkt.lookahead<switch_udf_field_t>();         ig_md.udf.udf_valid_bits = (UDF_L4_VALID + UDF_L5_VALID);
LID);
    //ig_md.udf.udf_valid_bits[UDF_L5_BIT:UDF_L5_BIT] = 1;

*/
# 784 "../../p4c-5296/parde.p4"
    state parse_udp {
        //ig_md.pkt_type.l4type = switch_pkt_l4_type_t.L4TYPE_UDP;
        pkt.extract(hdr.udp);
        //PARSE_L5_UDF_FIELD
# 799 "../../p4c-5296/parde.p4"
        transition select(hdr.udp.dst_port) {
            //udp_port_vxlan : parse_vxlan;
            4789 : parse_vxlan;
            1701 : parse_l2tp;
            2152 : parse_gtp_u;

            default : accept;
        }

    }

    state parse_tcp {
        //ig_md.pkt_type.l4type = switch_pkt_l4_type_t.L4TYPE_TCP;
        pkt.extract(hdr.tcp);
        //PARSE_L5_UDF_FIELD
# 851 "../../p4c-5296/parde.p4"
        transition select(hdr.tcp.data_offset, hdr.tcp.dst_port) {

            (5, 2152) : parse_gtp_u;

            (0 &&& 0xC, _) : accept;
            (4, _) : accept;
            (5, _) : accept;

            (6, _) : parse_tcp_options;
            default : accept;

        }

    }

    state parse_tcp_no_options {

        transition select(hdr.tcp.dst_port) {
            //L4_PORT_PPTP : parse_pptp;

            2152 : parse_gtp_u;

            default : accept;

        }

    }

    state parse_tcp_err_ihl {
        ig_md.flags.tcp_hl_err = true;
        transition accept;//reject;
    }

    state parse_tcp_options {
# 915 "../../p4c-5296/parde.p4"
        pkt.extract(hdr.tcp_options);
        transition parse_tcp_no_options;

    }

    state parse_sctp {
        //ig_md.pkt_type.l4type = switch_pkt_l4_type_t.L4TYPE_SCTP;
        pkt.extract(hdr.sctp);
        //PARSE_L5_UDF_FIELD
        //l4_dst_port = hdr.sctp.dst_port;
        transition accept;
    }
# 941 "../../p4c-5296/parde.p4"
    state parse_gre {
        //ig_md.pkt_type.l4type = switch_pkt_l4_type_t.L4TYPE_GRE;
        pkt.extract(hdr.gre);
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_GRE;
        //PARSE_L5_UDF_FIELD
        transition select(hdr.gre.C, hdr.gre.K, hdr.gre.S, hdr.gre.R, hdr.gre.version) {
            (1, _, _, 0, 0) : parse_gre_csum;
            (_, 1, _, 0, 0) : parse_gre_key;
            (_, _, 1, 0, 0) : parse_gre_seq;
            (_, _, _, 0, 0) : parse_gre_no_opts;
            default : accept;
        }
    }

    state parse_gre_csum {
        pkt.extract(hdr.gre_opts.next);
        transition select(hdr.gre.K, hdr.gre.S) {
            (1, _) : parse_gre_key;
            (_, 1) : parse_gre_seq;
            default : parse_gre_no_opts;
        }
    }

    state parse_gre_key {
        pkt.extract(hdr.gre_opts.next);
        transition select(hdr.gre.S) {
            1 : parse_gre_seq;
            default : parse_gre_no_opts;
        }
    }

    state parse_gre_seq {
        pkt.extract(hdr.gre_opts.next);
        transition parse_gre_no_opts;
    }

    state parse_gre_no_opts {
        transition select(hdr.gre.proto) {
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            0x6558 : parse_inner_ethernet;
            default : accept;
        }
    }

    state parse_l2tp {
        //ig_md.pkt_type.l4type = switch_pkt_l4_type_t.L4TYPE_L2TP;
        pkt.extract(hdr.l2tp);
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_L2TP;
        //ig_md.tunnel.id = (bit<24>)hdr.l2tp.tunnel_id;
        transition select(hdr.l2tp.T, hdr.l2tp.L, hdr.l2tp.O, hdr.l2tp.S) {
            (0, 0, 0, 0) : parse_l2tp_no_opts;
            (0, 0, 0, 1) : parse_l2tp_seq;
            default : accept;
        }
    }

    state parse_l2tp_seq {
        pkt.extract(hdr.l2tp_opts);
        transition parse_l2tp_no_opts;
    }

    state parse_l2tp_no_opts {
        transition parse_p2p;
    }

    state parse_p2p {
        pkt.extract(hdr.p2p);
        transition select(hdr.p2p.proto) {
            0x21&&&0xff : parse_inner_ipv4;
            0x57&&&0xff : parse_inner_ipv6;
            default : accept;
        }
    }
# 1053 "../../p4c-5296/parde.p4"
    state parse_vxlan {
        //ig_md.pkt_type.l5type = switch_pkt_l5_type_t.L5TYPE_VXLAN;
        pkt.extract(hdr.vxlan);
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_VXLAN;
        // ig_md.tunnel.id = hdr.vxlan.vni;
        transition parse_inner_ethernet;
    }
# 1099 "../../p4c-5296/parde.p4"
    state parse_gtp_c {
        //ig_md.pkt_type.l5type = switch_pkt_l5_type_t.L5TYPE_GTP_C;
        transition select(pkt.lookahead<bit<3>>()) {
            1 : parse_gtpv1;

            default : accept;
        }
    }

    state parse_gtp_u {
        //ig_md.pkt_type.l5type = switch_pkt_l5_type_t.L5TYPE_GTP_U;
        transition select(pkt.lookahead<bit<3>>()) {
            1 : parse_gtpv1;

            default : accept;
        }
    }

    state parse_gtpv1 {
        pkt.extract(hdr.gtpv1);
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_GTPV1;
        transition select(hdr.gtpv1.p, hdr.gtpv1.E, hdr.gtpv1.S, hdr.gtpv1.Pn, hdr.gtpv1.msg_t) {
            // (0, _, _, _) : accept;
            (1, 0, 0, 0, 0xff &&& 0xff) : parse_inner_ip;
            (1, _, _, _, 0xff &&& 0xff) : parse_gtpv1_opts;
            default : accept;
        }
    }

    state parse_gtpv1_opts {
        pkt.extract(hdr.gtpv1_opts);
        transition select(hdr.gtpv1.E, hdr.gtpv1_opts.next_exthdr_t) {
            (0, _) : parse_inner_ip;
            (1, 0) : parse_inner_ip;
            (1, _) : parse_gtpv1_ext;
            default : accept;
        }
    }

    state parse_gtpv1_ext {
        pkt.extract(hdr.gtpv1_ext.next);
        transition select(hdr.gtpv1_ext.last.len, hdr.gtpv1_ext.last.next_exthdr_t) {
            (1, 0) : parse_inner_ip;
            (1, _) : parse_gtpv1_ext;
            default : accept;
        }
    }
# 1173 "../../p4c-5296/parde.p4"
    state parse_ipv4inipv4 {
        //ig_md.pkt_type.l4type = switch_pkt_l4_type_t.L3TYPE_IPV4;
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPV4INIPV4;
        transition parse_inner_ipv4;
    }

    state parse_ipv6overipv4 {
        //ig_md.pkt_type.l4type = switch_pkt_l4_type_t.L3TYPE_IPV6;
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPV6OVERIPV4;
        transition parse_inner_ipv6;
    }

    state parse_ipv6inipv6 {
        //ig_md.pkt_type.l4type = switch_pkt_l4_type_t.L3TYPE_IPV6;
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPV6INIPV6;
        transition parse_inner_ipv6;
    }

    state parse_ipv4overipv6 {
        //ig_md.pkt_type.l4type = switch_pkt_l4_type_t.L3TYPE_IPV4;
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPV4OVERIPV6;
        transition parse_inner_ipv4;
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(pkt.lookahead<ethtype_t>()) {
            0x8100 &&& 0xefff: parse_inner_vlan;

            default : parse_inner_ethernetII;
        }
    }

    state parse_inner_ethernet802_3 {
        //ig_md.pkt_type.l2type = switch_pkt_l2_type_t.L2TYPE_ETHERNET_802_3;
        pkt.extract(hdr.inner_ether802_3);
        transition accept;
    }

    state parse_inner_ethernetII {
        //ig_md.pkt_type.l2type = switch_pkt_l2_type_t.L2TYPE_ETHERNET_II;
        pkt.extract(hdr.inner_etherII);
        //ethtype = hdr.etherII.ether_type;
        transition parse_inner_ethtype;
    }

    state parse_inner_vlan {
        pkt.extract(hdr.inner_vlan_tag.next);
        //ethtype = hdr.vlan_tag.last.ether_type;
        transition select(pkt.lookahead<ethtype_t>()) {
            0x8100 : parse_inner_vlan;
            default : parse_inner_ethernetII;
        }
    }

    state parse_inner_ethtype {
        //transition select(ethtype) {
        transition select(hdr.inner_etherII.ether_type) {
            // ETHERTYPE_ARP : parse_inner_arp;
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            0x8847 : parse_inner_mpls;
            0x8848 : parse_inner_mpls;
            default : accept;
        }
    }

    state parse_inner_mpls {
        //ig_md.pkt_type.l3type = switch_pkt_l3_type_t.MPLS;
        pkt.extract(hdr.inner_mpls.next);
        transition select(hdr.inner_mpls.last.bos) {
            0 : parse_inner_mpls;
            default : parse_inner_ip;
        }
    }

    state parse_inner_ip {
        transition select(pkt.lookahead<bit<4>>()) {
            4 : parse_inner_ipv4;
            6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        ig_md.tunnel.full_parsed = true;
# 1294 "../../p4c-5296/parde.p4"
        transition select(hdr.inner_ipv4.ihl, hdr.inner_ipv4.protocol, hdr.inner_ipv4.frag_offset) {
            (5, 6, 0) : parse_inner_tcp;
            (5, 17, 0) : parse_inner_udp;
            (5, 132, 0) : parse_inner_sctp;

            (0 &&& 0xC, _, _) : accept;
            (4, _, _) : accept;

            (6, _, 0) : parse_inner_ipv4_options;

            default : accept;
        }

    }

    state parse_inner_ipv4_err_ihl {
        ig_md.flags.inner_ipv4_ihl_err = true;
        transition accept;//reject;
    }

    state parse_inner_ipv4_options {
# 1336 "../../p4c-5296/parde.p4"
        pkt.extract(hdr.inner_ipv4_options);

        transition parse_inner_ipv4_no_options;

    }

    state parse_inner_ipv4_no_options {
# 1357 "../../p4c-5296/parde.p4"
        transition select(hdr.inner_ipv4.protocol) {
            (6) : parse_inner_tcp;
            (17) : parse_inner_udp;
            (132) : parse_inner_sctp;
            default : accept;
        }

    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        ig_md.tunnel.full_parsed = true;
# 1387 "../../p4c-5296/parde.p4"
        transition select(hdr.inner_ipv6.next_hdr) {

            0 : parse_inner_ipv6_ext;
            60 : parse_inner_ipv6_ext;
            43 : parse_inner_ipv6_ext;

            44 : parse_inner_ipv6_frag;

            6 : parse_inner_tcp;
            17 : parse_inner_udp;
            132 : parse_inner_sctp;
            default : accept;
        }

    }

    state parse_inner_ipv6_ext {
        pkt.extract(hdr.inner_ipv6_ext);
        // proto = hdr.ipv6_frag.next_hdr;
        transition select(hdr.inner_ipv6_ext.ext_hdr_len, hdr.inner_ipv6_ext.next_hdr) {

            (0, 44) : parse_inner_ipv6_frag;

            (0, 6) : parse_inner_tcp;
            (0, 17) : parse_inner_udp;
            (0, 132) : parse_inner_sctp;
            default : accept;
        }
    }

    state parse_inner_ipv6_frag {
        pkt.extract(hdr.inner_ipv6_frag);
        // inner_proto = hdr.inner_ipv6_frag.next_hdr;
        transition select(hdr.inner_ipv6_frag.next_hdr) {
            6 : parse_inner_tcp;
            17 : parse_inner_udp;
            132 : parse_inner_sctp;
            default : accept;
        }
    }
# 1443 "../../p4c-5296/parde.p4"
    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
# 1475 "../../p4c-5296/parde.p4"
        transition select(hdr.inner_tcp.data_offset) {
# 1487 "../../p4c-5296/parde.p4"
            default : accept;

        }

    }

    state parse_inner_tcp_no_options {
        transition accept;
    }

    state parse_inner_tcp_err_ihl {
        ig_md.flags.inner_tcp_hl_err = true;
        transition accept;//reject;
    }
# 1524 "../../p4c-5296/parde.p4"
    state parse_inner_sctp {
        pkt.extract(hdr.inner_sctp);
        //inner_l4_dst_port = hdr.inner_sctp.dst_port;
        transition accept;
    }

}

//-----------------------------------------------------------------------------
// Ingress Deparser
//-----------------------------------------------------------------------------
control SwitchIngressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    //IngressMirror() mirror;

    apply {
        //mirror.apply(hdr, ig_md, ig_md.aclact.mirror, ig_intr_md_for_dprsr);
# 1567 "../../p4c-5296/parde.p4"
        pkt.emit(hdr);
    }
}

//----------------------------------------------------------------------------
// Egress parser
//----------------------------------------------------------------------------
// expect error@NO SOURCE: "Parser SwitchEgressParser: longest path through parser .* exceeds maximum parse depth"
parser SwitchEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
# 1591 "../../p4c-5296/parde.p4"
    bit<36> data = 0;
    ParserCounter() optlen;

    state start {
        pkt.extract(eg_intr_md);
        eg_md.egr_port = eg_intr_md.egress_port;
        switch_port_mirror_metadata_h mirror_md = pkt.lookahead<switch_port_mirror_metadata_h>();
        eg_md.src = mirror_md.src;
        transition select(mirror_md.src, mirror_md.type) {
            (SWITCH_PKT_SRC_BRIDGED, _) : parse_bridged_pkt;
            (SWITCH_PKT_SRC_CLONED_INGRESS, 1) : parse_port_mirrored_metadata;
            default : accept;
        }
    }

    state parse_port_mirrored_metadata {
        switch_port_mirror_metadata_h port_mirror;
        pkt.extract(port_mirror);
        // pkt.extract(hdr.ethernet);
        //pkt.advance(MIRROR_METADATA_SIZE);
        // pkt.advance(sizeInBits<switch_port_mirror_metadata_h>(pkt.lookahead<switch_port_mirror_metadata_h>()));
        transition accept;
    }

    state parse_bridged_pkt {
        pkt.extract(hdr.bridged_md);
        // eg_md.egr_port_lag_index = SWITCH_PORT_LAG_INVALID;

        eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_NONE;

        eg_md.pkt_info.outer_ip_type = SWITCH_IP_TYPE_NONE;

        // ig_md.pkt_type.l3type = L3TYPE_UNKNOWN_L3;
        // ig_md.pkt_type.l4type = L4TYPE_UNKNOWN_L4;
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(pkt.lookahead<ethtype_t>()) {
            0x8100 &&& 0xefff: parse_vlan;

            default : parse_ethernetII;
        }
    }

    state parse_ethernet802_3 {
        pkt.extract(hdr.ether802_3);
        transition accept;
    }

    state parse_ethernetII {
        pkt.extract(hdr.etherII);
        transition parse_ethtype;
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(pkt.lookahead<ethtype_t>()) {
            0x8100 &&& 0xefff : parse_vlan;
            default : parse_ethernetII;
        }
    }

    state parse_ethtype {
        transition select(hdr.etherII.ether_type) {

            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            0x8847 : parse_mpls;
            0x8848 : parse_mpls;
            default : accept;
        }
    }

    state parse_mpls {
        pkt.extract(hdr.mpls.next);
        transition select(hdr.mpls.last.bos) {
            0 : parse_mpls;
            default : parse_mpls_data;
        }
    }

    state parse_mpls_data {
        data = pkt.lookahead<bit<36>>();
        transition select(data[35:32], data[3:0]) {
            (4, _) : parse_ipv4;
            (6, _) : parse_ipv6;
            (_, 4) : parse_pw_ipv4;
            (_, 6) : parse_pw_ipv6;

            default : parse_mpls_l2;

        }
    }

    state parse_pw_ipv4 {
        pkt.extract(hdr.pw);
        transition parse_ipv4;
    }

    state parse_pw_ipv6 {
        pkt.extract(hdr.pw);
        transition parse_ipv6;
    }

    state parse_mpls_l2 {

        eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_MPLS_L2;

        transition accept;

    }

    state parse_pw_l2 {
        pkt.extract(hdr.pw);

        transition accept;

    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);

        eg_md.pkt_info.outer_ip_type = SWITCH_IP_TYPE_IPV4;

        // eg_md.pkt_type.l3type = switch_pkt_l3_type_t.L3TYPE_IPV4;
# 1765 "../../p4c-5296/parde.p4"
        transition select(hdr.ipv4.ihl, hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (5, 6, 0) : parse_tcp;
            (5, 17, 0) : parse_udp;
            (5, 132, 0) : parse_sctp;

            (5, 4, 0) : parse_ipv4inipv4;
            (5, 41, 0) : parse_ipv6overipv4;
            (5, 47, 0) : parse_gre;
            //IP_PROTOCOLS_IPSEC_ESP : parse_ipsec_esp;

            //IP_PROTOCOLS_OSPF : parse_ospf;
            (5, 115, 0) : parse_l2tp;

            (0 &&& 0xC, _, _) : accept;
            (4, _, _) : accept;

            (6, _, 0) : parse_ipv4_options;

            // Do NOT parse the next header if IP packet is fragmented.
            default : accept;
        }

    }

    state parse_ipv4_err_ihl {
        // ig_md.flags.ipv4_ihl_err = true;
        transition accept;//reject;
    }

    state parse_ipv4_options {
# 1819 "../../p4c-5296/parde.p4"
        pkt.extract(hdr.ipv4_options);
        transition parse_ipv4_no_options;

    }

    state parse_ipv4_no_options {
# 1840 "../../p4c-5296/parde.p4"
        transition select(hdr.ipv4.protocol) {
            (6) : parse_tcp;
            (17) : parse_udp;
            (132) : parse_sctp;

            (4) : parse_ipv4inipv4;
            (41) : parse_ipv6overipv4;
            (47) : parse_gre;
            //IP_PROTOCOLS_IPSEC_ESP : parse_ipsec_esp;

            //IP_PROTOCOLS_OSPF : parse_ospf;
            (115) : parse_l2tp;

            default : accept;
        }

    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);

        eg_md.pkt_info.outer_ip_type = SWITCH_IP_TYPE_IPV6;

        // eg_md.pkt_type.l3type = switch_pkt_l3_type_t.L3TYPE_IPV6;
# 1890 "../../p4c-5296/parde.p4"
        transition select(hdr.ipv6.next_hdr) {
            6 : parse_tcp;
            17 : parse_udp;
            132 : parse_sctp;

            //IP_PROTOCOLS_ICMPV6 : parse_icmp;
            4 : parse_ipv4overipv6;
            41 : parse_ipv6inipv6;
            47 : parse_gre;
            //IP_PROTOCOLS_IPSEC_ESP : parse_ipsec_esp;

            //IP_PROTOCOLS_OSPF : parse_ospf;
            115 : parse_l2tp;

            0 : parse_ipv6_ext;
            60 : parse_ipv6_ext;
            43 : parse_ipv6_ext;

            44 : parse_ipv6_frag;

            default : accept;
        }

    }

    state parse_ipv6_ext {
        pkt.extract(hdr.ipv6_ext);
        // proto = hdr.ipv6_frag.next_hdr;
        transition select(hdr.ipv6_ext.ext_hdr_len, hdr.ipv6_ext.next_hdr) {

            (0, 44) : parse_ipv6_frag;

            (0, 6) : parse_tcp;
            (0, 17) : parse_udp;
            (0, 132) : parse_sctp;

            //IP_PROTOCOLS_ICMPV6 : parse_icmp;
            (0, 4) : parse_ipv4overipv6;
            (0, 41) : parse_ipv6inipv6;
            (0, 47) : parse_gre;
            //IP_PROTOCOLS_IPSEC_ESP : parse_ipsec_esp;

            //IP_PROTOCOLS_OSPF : parse_ospf;
            (0, 115) : parse_l2tp;

            default : accept;
        }
    }

    state parse_ipv6_frag {
        pkt.extract(hdr.ipv6_frag);
        // proto = hdr.ipv6_frag.next_hdr;
        transition select(hdr.ipv6_frag.next_hdr) {
            6 : parse_tcp;
            17 : parse_udp;
            132 : parse_sctp;

            //IP_PROTOCOLS_ICMPV6 : parse_icmp;
            4 : parse_ipv4overipv6;
            41 : parse_ipv6inipv6;
            47 : parse_gre;
            //IP_PROTOCOLS_IPSEC_ESP : parse_ipsec_esp;

            //IP_PROTOCOLS_OSPF : parse_ospf;
            115 : parse_l2tp;

            default : accept;
        }
    }
# 2039 "../../p4c-5296/parde.p4"
    state parse_ipsec_esp {
        pkt.extract(hdr.ipsec_esp);
        transition accept;
    }
# 2059 "../../p4c-5296/parde.p4"
    state parse_udp {
        pkt.extract(hdr.udp);
        // eg_md.pkt_type.l4type = switch_pkt_l4_type_t.L4TYPE_UDP;
# 2073 "../../p4c-5296/parde.p4"
        transition select(hdr.udp.dst_port) {
            //udp_port_vxlan : parse_vxlan;
            4789 : parse_vxlan;
            1701 : parse_l2tp;
            2152 : parse_gtp_u;

            default : accept;
        }

    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        // eg_md.pkt_type.l4type = switch_pkt_l4_type_t.L4TYPE_TCP;
# 2124 "../../p4c-5296/parde.p4"
        transition select(hdr.tcp.data_offset, hdr.tcp.dst_port) {

            (5, 2152) : parse_gtp_u;

            (0 &&& 0xC, _) : accept;
            (4, _) : accept;
            (5, _) : accept;

            (6, _) : parse_tcp_options;
            default : accept;

        }

    }

    state parse_tcp_no_options {

        transition select(hdr.tcp.dst_port) {
            //L4_PORT_PPTP : parse_pptp;

            2152 : parse_gtp_u;

            default : accept;

        }

    }

    state parse_tcp_err_ihl {
        // ig_md.flags.tcp_hl_err = true;
        transition accept;//reject;
    }

    state parse_tcp_options {
# 2187 "../../p4c-5296/parde.p4"
        pkt.extract(hdr.tcp_options);
        transition parse_tcp_no_options;

    }

    state parse_sctp {
        pkt.extract(hdr.sctp);
        //l4_dst_port = hdr.sctp.dst_port;
        transition accept;
    }
# 2210 "../../p4c-5296/parde.p4"
    state parse_gre {
        pkt.extract(hdr.gre);
        // eg_md.pkt_type.l4type = switch_pkt_l4_type_t.L4TYPE_GRE;

        eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_GRE;

        transition select(hdr.gre.C, hdr.gre.K, hdr.gre.S, hdr.gre.R, hdr.gre.version) {
            (1, _, _, 0, 0) : parse_gre_csum;
            (_, 1, _, 0, 0) : parse_gre_key;
            (_, _, 1, 0, 0) : parse_gre_seq;
            (_, _, _, 0, 0) : parse_gre_no_opts;
            default : accept;
        }
    }

    state parse_gre_csum {
        pkt.extract(hdr.gre_opts.next);
        transition select(hdr.gre.K, hdr.gre.S) {
            (1, _) : parse_gre_key;
            (_, 1) : parse_gre_seq;
            default : parse_gre_no_opts;
        }
    }

    state parse_gre_key {
        pkt.extract(hdr.gre_opts.next);
        transition select(hdr.gre.S) {
            1 : parse_gre_seq;
            default : parse_gre_no_opts;
        }
    }

    state parse_gre_seq {
        pkt.extract(hdr.gre_opts.next);
        transition parse_gre_no_opts;
    }

    state parse_gre_no_opts {
# 2256 "../../p4c-5296/parde.p4"
        transition accept;

    }

    state parse_l2tp {
        pkt.extract(hdr.l2tp);
        // eg_md.pkt_type.l4type = switch_pkt_l4_type_t.L4TYPE_L2TP;

        eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_L2TP;

        transition select(hdr.l2tp.T, hdr.l2tp.L, hdr.l2tp.O, hdr.l2tp.S) {
            (0, 0, 0, 0) : parse_l2tp_no_opts;
            (0, 0, 0, 1) : parse_l2tp_seq;
            default : accept;
        }
    }

    state parse_l2tp_seq {
        pkt.extract(hdr.l2tp_opts);
        transition parse_l2tp_no_opts;
    }

    state parse_l2tp_no_opts {
        transition parse_p2p;
    }

    state parse_p2p {
        pkt.extract(hdr.p2p);

        transition accept;

    }
# 2338 "../../p4c-5296/parde.p4"
    state parse_vxlan {
        pkt.extract(hdr.vxlan);

        eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_VXLAN;

        transition accept;

    }
# 2398 "../../p4c-5296/parde.p4"
    state parse_gtp_c {
        transition select(pkt.lookahead<bit<3>>()) {
            1 : parse_gtpv1;

            default : accept;
        }
    }

    state parse_gtp_u {
        transition select(pkt.lookahead<bit<3>>()) {
            1 : parse_gtpv1;

            default : accept;
        }
    }

    state parse_gtpv1 {
        pkt.extract(hdr.gtpv1);

        eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_GTPV1;

        transition select(hdr.gtpv1.p, hdr.gtpv1.E, hdr.gtpv1.S, hdr.gtpv1.Pn, hdr.gtpv1.msg_t) {
            // (0, _, _, _) : accept;

            (1, 0, 0, 0, 0xff &&& 0xff) : accept;

            (1, _, _, _, 0xff &&& 0xff) : parse_gtpv1_opts;
            default : accept;
        }
    }

    state parse_gtpv1_opts {
        pkt.extract(hdr.gtpv1_opts);
        transition select(hdr.gtpv1.E, hdr.gtpv1_opts.next_exthdr_t) {

            (1, 0) : accept;

            (1, _) : parse_gtpv1_ext;
            default : accept;
        }
    }

    state parse_gtpv1_ext {
        pkt.extract(hdr.gtpv1_ext.next);
        transition select(hdr.gtpv1_ext.last.len, hdr.gtpv1_ext.last.next_exthdr_t) {

            (1, 0) : accept;

            (1, _) : parse_gtpv1_ext;
            default : accept;
        }
    }
# 2491 "../../p4c-5296/parde.p4"
    state parse_ipv4inipv4 {

        eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPV4INIPV4;

        transition accept;

    }

    state parse_ipv6overipv4 {

        eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPV6OVERIPV4;

        transition accept;

    }

    state parse_ipv6inipv6 {

        eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPV6INIPV6;

        transition accept;

    }

    state parse_ipv4overipv6 {

        eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPV4OVERIPV6;

        transition accept;

    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(pkt.lookahead<ethtype_t>()) {
            0x8100 &&& 0xefff: parse_inner_vlan;

            default : parse_inner_ethernetII;
        }
    }

    state parse_inner_ethernet802_3 {
        pkt.extract(hdr.inner_ether802_3);
        transition accept;
    }

    state parse_inner_ethernetII {
        pkt.extract(hdr.inner_etherII);
        transition parse_inner_ethtype;
    }

    state parse_inner_vlan {
        pkt.extract(hdr.inner_vlan_tag.next);
        transition select(pkt.lookahead<ethtype_t>()) {
            0x8100 : parse_inner_vlan;
            default : parse_inner_ethernetII;
        }
    }

    state parse_inner_ethtype {
        transition select(hdr.inner_etherII.ether_type) {
            // ETHERTYPE_ARP : parse_inner_arp;
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            0x8847 : parse_inner_mpls;
            0x8848 : parse_inner_mpls;
            default : accept;
        }
    }

    state parse_inner_mpls {
        pkt.extract(hdr.inner_mpls.next);
        transition select(hdr.inner_mpls.last.bos) {
            0 : parse_inner_mpls;
            default : parse_inner_ip;
        }
    }

    state parse_inner_ip {
        transition select(pkt.lookahead<bit<4>>()) {
            4 : parse_inner_ipv4;
            6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);

        eg_md.tunnel.full_parsed = true;
# 2624 "../../p4c-5296/parde.p4"
        transition select(hdr.inner_ipv4.ihl, hdr.inner_ipv4.protocol, hdr.inner_ipv4.frag_offset) {
            (5, 6, 0) : parse_inner_tcp;
            (5, 17, 0) : parse_inner_udp;
            (5, 132, 0) : parse_inner_sctp;

            (0 &&& 0xC, _, _) : accept;
            (4, _, _) : accept;

            (6, _, 0) : parse_inner_ipv4_options;

            default : accept;
        }

    }

    state parse_inner_ipv4_err_ihl {
        // ig_md.flags.inner_ipv4_ihl_err = true;
        transition accept;//reject;
    }

    state parse_inner_ipv4_options {
# 2663 "../../p4c-5296/parde.p4"
        pkt.extract(hdr.inner_ipv4_options);
        transition parse_inner_ipv4_no_options;

    }

    state parse_inner_ipv4_no_options {
# 2678 "../../p4c-5296/parde.p4"
        transition select(hdr.inner_ipv4.protocol) {
            (6) : parse_inner_tcp;
            (17) : parse_inner_udp;
            (132) : parse_inner_sctp;
            default : accept;
        }

    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);

        eg_md.tunnel.full_parsed = true;
# 2709 "../../p4c-5296/parde.p4"
        transition select(hdr.inner_ipv6.next_hdr) {

            0 : parse_inner_ipv6_ext;
            60 : parse_inner_ipv6_ext;
            43 : parse_inner_ipv6_ext;

            44 : parse_inner_ipv6_frag;

            6 : parse_inner_tcp;
            17 : parse_inner_udp;
            132 : parse_inner_sctp;
            default : accept;
        }

    }

    state parse_inner_ipv6_ext {
        pkt.extract(hdr.inner_ipv6_ext);
        // proto = hdr.ipv6_frag.next_hdr;
        transition select(hdr.inner_ipv6_ext.ext_hdr_len, hdr.inner_ipv6_ext.next_hdr) {

            (0, 44) : parse_inner_ipv6_frag;

            (0, 6) : parse_inner_tcp;
            (0, 17) : parse_inner_udp;
            (0, 132) : parse_inner_sctp;
            default : accept;
        }
    }

    state parse_inner_ipv6_frag {
        pkt.extract(hdr.inner_ipv6_frag);
        // inner_proto = hdr.inner_ipv6_frag.next_hdr;
        transition select(hdr.inner_ipv6_frag.next_hdr) {
            6 : parse_inner_tcp;
            17 : parse_inner_udp;
            132 : parse_inner_sctp;
            default : accept;
        }
    }
# 2765 "../../p4c-5296/parde.p4"
    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
# 2797 "../../p4c-5296/parde.p4"
        transition select(hdr.inner_tcp.data_offset) {
# 2809 "../../p4c-5296/parde.p4"
            default : accept;

        }

    }

    state parse_inner_tcp_no_options {
        transition accept;
    }

    state parse_inner_tcp_err_ihl {
        // ig_md.flags.inner_tcp_hl_err = true;
        transition accept;//reject;
    }
# 2846 "../../p4c-5296/parde.p4"
    state parse_inner_sctp {
        pkt.extract(hdr.inner_sctp);
        transition accept;
    }
}

//-----------------------------------------------------------------------------
// Egress Deparser
//-----------------------------------------------------------------------------
control SwitchEgressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Checksum() ipv4_checksum;
    // Checksum() icmp_checksum;

    apply {

        if (/*eg_md.upd_csum*/hdr.gre_ip.isValid()) {
            hdr.gre_ip.hdr_checksum = ipv4_checksum.update({
                hdr.gre_ip.version,
                hdr.gre_ip.ihl,
                hdr.gre_ip.diffserv,
                hdr.gre_ip.total_len,
                hdr.gre_ip.identification,
                hdr.gre_ip.flags,
                hdr.gre_ip.frag_offset,
                hdr.gre_ip.ttl,
                hdr.gre_ip.protocol,
                hdr.gre_ip.src_addr,
                hdr.gre_ip.dst_addr});
        } else {

            if (/*eg_md.upd_csum_opt*/hdr.ipv4_options.isValid()) {
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
                    hdr.ipv4.dst_addr,
                    hdr.ipv4_options.type,
                    hdr.ipv4_options.length,
                    hdr.ipv4_options.value});
            } else

            if (/*eg_md.upd_csum*/hdr.ipv4.isValid()) {
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
            }

        }

        pkt.emit(hdr);
    }
}
# 6 "../../p4c-5296/p4c-5296.p4" 2

control SwitchIngress(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t local_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    apply {}
}

control SwitchEgress(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t local_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {}
}

Pipeline <switch_header_t, switch_ingress_metadata_t, switch_header_t, switch_egress_metadata_t> (
    SwitchIngressParser(),
    SwitchIngress(),
    SwitchIngressDeparser(),
    SwitchEgressParser(),
    SwitchEgress(),
    SwitchEgressDeparser()) pipe;

Switch(pipe) main;
