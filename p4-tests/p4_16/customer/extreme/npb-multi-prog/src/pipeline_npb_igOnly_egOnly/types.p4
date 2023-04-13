#ifndef _P4_TYPES_
#define _P4_TYPES_

// ----------------------------------------------------------------------------
// Common protocols/types
//-----------------------------------------------------------------------------
#define ETHERTYPE_ENET 0x6558  // geneve defined (rfc-8926)
#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_ARP  0x0806
#define ETHERTYPE_VLAN 0x8100
#define ETHERTYPE_IPV6 0x86dd
#define ETHERTYPE_MPLS 0x8847
#define ETHERTYPE_PTP  0x88F7
#define ETHERTYPE_FCOE 0x8906
#define ETHERTYPE_ROCE 0x8915
#define ETHERTYPE_BFN  0x9000
#define ETHERTYPE_BFN2 0x9001
#ifdef ING_HDR_STACK_COUNTERS // Parser tests use newer/fixed scapy
  #define ETHERTYPE_QINQ 0x88A8 // Note: uncomment once ptf/scapy-vxlan are fixed
#else
  #define ETHERTYPE_QINQ 0x8100
#endif
#define ETHERTYPE_MINM 0x88e7 // 802.1ah (PBB)
#define ETHERTYPE_BR   0x893F
//#define ETHERTYPE_VN   0x892F
#define ETHERTYPE_VN   0x8926
#define ETHERTYPE_NSH  0x894F

#define IP_PROTOCOLS_ICMP   1
#define IP_PROTOCOLS_IGMP   2
#define IP_PROTOCOLS_IPV4   4
#define IP_PROTOCOLS_TCP    6
#define IP_PROTOCOLS_UDP    17
#define IP_PROTOCOLS_IPV6   41
#define IP_PROTOCOLS_SRV6   43
#define IP_PROTOCOLS_GRE    47
#define IP_PROTOCOLS_ICMPV6 58
#define IP_PROTOCOLS_ESP    0x32  // 50
#define IP_PROTOCOLS_SCTP   0x84  // 132

#define UDP_PORT_VXLAN_GPE 4788
#define UDP_PORT_VXLAN  4789
#define UDP_PORT_ROCEV2 4791
#define UDP_PORT_GENV   6081
#define UDP_PORT_SFLOW  6343
#define UDP_PORT_MPLS   6635
#define UDP_PORT_GTP_U  2152
#define UDP_PORT_GTP_C  2123

#define GRE_PROTOCOLS_ERSPAN_TYPE_3 0x22EB
#define GRE_PROTOCOLS_NVGRE         0x6558  // transparent enet bridging (L2 GRE)
#define GRE_PROTOCOLS_IP            0x0800
#define GRE_PROTOCOLS_ERSPAN_TYPE_2 0x88BE
#define GRE_PROTOCOLS_IPV6          0x86DD
#define GRE_FLAGS_PROTOCOL_NVGRE    0x20006558

#define NSH_PROTOCOLS_IPV4 0x1
#define NSH_PROTOCOLS_IPV6 0x2
#define NSH_PROTOCOLS_ETH  0x3
#define NSH_PROTOCOLS_NSH  0x4
#define NSH_PROTOCOLS_MPLS 0x5
#define NSH_PROTOCOLS_EXP1 0xFE
#define NSH_PROTOCOLS_EXP2 0xFF

#define VLAN_DEPTH_OUTER 2 // doesn't change everything

// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------

typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;

#ifndef switch_counter_width
#define switch_counter_width 32
#endif

typedef PortId_t switch_port_t; // defined in tna
#if __TARGET_TOFINO__ == 3
const switch_port_t SWITCH_PORT_INVALID = 11w0x1ff;
typedef bit<5> switch_port_padding_t;
#else
const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;
typedef bit<7> switch_port_padding_t;
#endif

typedef QueueId_t switch_qid_t; // defined in tna (t2 = 7 bits)

typedef ReplicationId_t switch_rid_t; // defined in tna
const switch_rid_t SWITCH_RID_DEFAULT = 0xffff;

typedef bit<switch_port_lag_index_width> switch_port_lag_index_t;
//const switch_port_lag_index_t SWITCH_FLOOD = 0x3ff;

typedef bit<switch_bd_width> switch_bd_t;
const switch_bd_t SWITCH_BD_DEFAULT_VRF = 4097; // bd allocated for default vrf

//#ifndef switch_nexthop_width
//#define switch_nexthop_width 16
//#endif
typedef bit<switch_nexthop_width> switch_nexthop_t;

#ifdef RESILIENT_ECMP_HASH_ENABLE
#define switch_hash_width 64
#else
#define switch_hash_width 32
#endif
typedef bit<switch_hash_width> switch_hash_t;

#ifndef egress_dtel_drop_report_width
#define egress_dtel_drop_report_width 17
#endif

#ifndef egress_dtel_flow_report_width
#define egress_dtel_flow_report_width 17
#endif

#ifndef egress_dtel_flow_report_num_blocks
#define egress_dtel_flow_report_num_blocks 1
#endif

typedef bit<16> switch_xid_t;
typedef bit<9> switch_yid_t;

typedef bit<switch_smac_index_width> switch_smac_index_t;

typedef bit<switch_cpu_reason_width> switch_cpu_reason_t;
const switch_cpu_reason_t SWITCH_CPU_REASON_PTP             = 8;
// -------------------------------------
// Extreme Networks - Added
// -------------------------------------
const switch_cpu_reason_t SWITCH_CPU_REASON_IG_PORT_MIRROR = 254;
const switch_cpu_reason_t SWITCH_CPU_REASON_EG_PORT_MIRROR = 255;

struct switch_cpu_port_value_set_t {
    bit<16> ether_type;
    switch_port_t port;
}

//#define switch_drop_reason_width 8
typedef bit<switch_drop_reason_width> switch_drop_reason_t;
const switch_drop_reason_t SWITCH_DROP_REASON_UNKNOWN = 0;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_ZERO = 10;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_MULTICAST = 11;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_DST_MAC_ZERO = 12;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_ETHERNET_MISS = 13;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_ZERO = 14;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_MULTICAST = 15;
const switch_drop_reason_t SWITCH_DROP_REASON_DST_MAC_ZERO = 16;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SAME_MAC_CHECK = 17;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID = 25;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_TTL_ZERO = 26;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_SRC_MULTICAST = 27;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_SRC_LOOPBACK = 28;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_MISS = 29;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID = 30;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_INVALID_CHECKSUM = 31;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_VERSION_INVALID = 40;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_TTL_ZERO = 41;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_MULTICAST = 42;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_LOOPBACK = 43;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_IHL_INVALID = 44;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_INVALID_CHECKSUM = 45;
const switch_drop_reason_t SWITCH_DROP_REASON_PORT_VLAN_MAPPING_MISS = 55;
const switch_drop_reason_t SWITCH_DROP_REASON_SAME_IFINDEX = 58;
const switch_drop_reason_t SWITCH_DROP_REASON_MULTICAST_SNOOPING_ENABLED = 59;
const switch_drop_reason_t SWITCH_DROP_REASON_TRAFFIC_MANAGER = 71;
const switch_drop_reason_t SWITCH_DROP_REASON_ACL_DENY = 80;
const switch_drop_reason_t SWITCH_DROP_REASON_IFINDEX = 84;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_UNICAST = 89;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_MULTICAST = 90;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_BROADCAST = 91;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_ACL_DENY = 92;
const switch_drop_reason_t SWITCH_DROP_REASON_NEXTHOP = 93;
const switch_drop_reason_t SWITCH_DROP_REASON_MLAG_MEMBER = 95;
// -------------------------------------
// Extreme Networks - Added
// -------------------------------------
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_VERSION_INVALID = 110;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_OAM = 111;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_TTL_ZERO = 112;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_LEN_INVALID = 113;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_MDTYPE_INVALID = 114;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_NEXT_PROTO_INVALID = 115;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_SI_ZERO = 116;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_MD_LEN_INVALID = 117;
const switch_drop_reason_t SWITCH_DROP_REASON_SFC_TABLE_MISS = 118;

typedef bit<2> switch_ip_type_t;
const switch_ip_type_t SWITCH_IP_TYPE_NONE = 0;
const switch_ip_type_t SWITCH_IP_TYPE_IPV4 = 1;
const switch_ip_type_t SWITCH_IP_TYPE_IPV6 = 2;

typedef bit<2> switch_ip_frag_t;
const switch_ip_frag_t SWITCH_IP_FRAG_NON_FRAG = 0b00; // Not fragmented.
const switch_ip_frag_t SWITCH_IP_FRAG_HEAD     = 0b10; // First fragment of the fragmented packets.
const switch_ip_frag_t SWITCH_IP_FRAG_NON_HEAD = 0b11; // Fragment with non-zero offset.

// To determine these values, run the test "test_mau_1hop_s_e_sf0_l2_acl_sf2_l2_acl" and subtract the count values.
const int EGRESS_ACL_ADJUST_NORMAL = -32; // DO NOT DELETE -- FIRMWARE CONSUMES THIS
//const int EGRESS_ACL_ADJUST_DROP   =   4; // DO NOT DELETE -- FIRMWARE CONSUMES THIS
const int EGRESS_ACL_ADJUST_DROP   = -32; // DO NOT DELETE -- FIRMWARE CONSUMES THIS

// Bypass flags ---------------------------------------------------------------

typedef bit<8> switch_ingress_bypass_t;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L2            = 8w0x01;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SFC           = 8w0x02;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SF_ACL        = 8w0x04;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SF_MCAST      = 8w0x08;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SFF           = 8w0x10;
//const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_REWRITE       = 8w0x20;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ALL           = 8w0xff;

#define INGRESS_BYPASS(t) (ig_md.bypass & SWITCH_INGRESS_BYPASS_##t != 0)
//#define INGRESS_BYPASS(t) (false)

// PKT ------------------------------------------------------------------------

typedef bit<16> switch_pkt_length_t;

typedef bit<8> switch_pkt_src_t;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED        = 0;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_INGRESS = 1;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_EGRESS  = 2;
const switch_pkt_src_t SWITCH_PKT_SRC_DEFLECTED      = 3;

typedef bit<2> switch_pkt_color_t;
const switch_pkt_color_t SWITCH_METER_COLOR_GREEN    = 0;
const switch_pkt_color_t SWITCH_METER_COLOR_YELLOW   = 1;
const switch_pkt_color_t SWITCH_METER_COLOR_RED      = 3;

typedef bit<2> switch_pkt_type_t;
const switch_pkt_type_t SWITCH_PKT_TYPE_UNICAST      = 0;
const switch_pkt_type_t SWITCH_PKT_TYPE_MULTICAST    = 1;
const switch_pkt_type_t SWITCH_PKT_TYPE_BROADCAST    = 2;

// Metering -------------------------------------------------------------------

//#define switch_copp_meter_id_width 8
typedef bit<switch_copp_meter_id_width> switch_copp_meter_id_t;

//#define switch_meter_index_width 10
typedef bit<switch_meter_index_width> switch_meter_index_t;

//#define switch_mirror_meter_id_width 8
typedef bit<switch_mirror_meter_id_width> switch_mirror_meter_id_t;

// QoS ------------------------------------------------------------------------

struct switch_qos_metadata_t {
//	switch_tc_t tc;
//	switch_pkt_color_t color;
	switch_qid_t qid;
	bit<19> qdepth; // Egress only.
}

// Multicast ------------------------------------------------------------------

typedef bit<2> switch_multicast_mode_t;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_NONE      = 0;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_SM    = 1; // Sparse mode
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_BIDIR = 2; // Bidirectional

typedef MulticastGroupId_t switch_mgid_t;

//typedef bit<16> switch_multicast_rpf_group_t;

struct switch_multicast_metadata_t {
    switch_mgid_t id;
    bit<2> mode;
//  switch_multicast_rpf_group_t rpf_group;
}

// Mirroring ------------------------------------------------------------------

typedef MirrorId_t switch_mirror_session_t; // Defined in tna.p4
const switch_mirror_session_t SWITCH_MIRROR_SESSION_CPU_INGRESS = 251;
const switch_mirror_session_t SWITCH_MIRROR_SESSION_CPU_EGRESS  = 250;

// Using same mirror type for both Ingress/Egress to simplify the parser.
typedef bit<8> switch_mirror_type_t;
#define SWITCH_MIRROR_TYPE_INVALID 0
#define SWITCH_MIRROR_TYPE_PORT 1
#define SWITCH_MIRROR_TYPE_CPU 2
#define SWITCH_MIRROR_TYPE_DTEL_DROP 3
#define SWITCH_MIRROR_TYPE_DTEL_SWITCH_LOCAL 4
#define SWITCH_MIRROR_TYPE_SIMPLE 5
/* Although strictly speaking deflected packets are not mirrored packets,
 * need a mirror_type codepoint for packet length adjustment.
 * Pick a large value since this is not used by mirror logic.
 */
#define SWITCH_MIRROR_TYPE_DTEL_DEFLECT 255

// Common metadata used for mirroring.
struct switch_mirror_metadata_t {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    switch_mirror_session_t session_id;
    switch_mirror_meter_id_t meter_index;
}
/*
header switch_port_mirror_ingress_metadata_h { // this is a header!
    switch_pkt_src_t src;                   // 8
    switch_mirror_type_t type;              // 8
    switch_port_padding_t _pad1;            // 7  \ 16 total
    switch_port_t port;                     // 9  /
    switch_bd_t bd;                         // 16
#ifdef CPU_HDR_CONTAINS_EG_PORT
    bit<7> _pad2;                           // 7  \ 16 total
    switch_port_t eg_port;                  // 9  /
#else
    bit<6> _pad2;                           // 6  \ 16 total
    switch_port_lag_index_t port_lag_index; // 10 /
#endif
//#if defined(PTP_ENABLE) || defined(INT_V2)
//    bit<48> timestamp;
//#else
//    bit<32> timestamp;                      // 32
//#endif
//#if __TARGET_TOFINO__ == 1
//    bit<6> _pad;
//#endif
//    switch_mirror_session_t session_id;     // 8
    switch_cpu_reason_t reason_code;        // 16
#if __TARGET_TOFINO__ == 1
    bit<3> _pad4;
#else
    bit<1> _pad4;
#endif
    switch_qid_t qos_qid;                   // 7
	bit< 5> _pad5;                          // 5  \ 24 total
	bit<19> qos_qdepth;                     // 19 /
}
*/
/*
header switch_port_mirror_egress_metadata_h { // this is a header!
    switch_pkt_src_t src;                   // 8
    switch_mirror_type_t type;              // 8
    switch_port_padding_t _pad1;            // 7  \ 16 total
    switch_port_t port;                     // 9  /
    switch_bd_t bd;                         // 16
#ifdef CPU_HDR_CONTAINS_EG_PORT
    bit<7> _pad2;                           // 7  \ 16 total
    switch_port_t eg_port;                  // 9  /
#else
    bit<6> _pad2;                           // 6  \ 16 total
    switch_port_lag_index_t port_lag_index; // 10 /
#endif
//#if defined(PTP_ENABLE) || defined(INT_V2)
//    bit<48> timestamp;
//#else
//    bit<32> timestamp;                      // 32
//#endif
//#if __TARGET_TOFINO__ == 1
//    bit<6> _pad;
//#endif
//    switch_mirror_session_t session_id;     // 8
    switch_cpu_reason_t reason_code;        // 16
#if __TARGET_TOFINO__ == 1
    bit<3> _pad4;
#else
    bit<1> _pad4;
#endif
    switch_qid_t qos_qid;                   // 7
	bit< 5> _pad5;                          // 5  \ 24 total
	bit<19> qos_qdepth;                     // 19 /
}
*/
header switch_cpu_mirror_ingress_metadata_h { // this is a header!
    switch_pkt_src_t src;                   // 8
    switch_mirror_type_t type;              // 8
    switch_port_padding_t _pad1;            // 7  \ 16 total
    switch_port_t port;                     // 9  /
    switch_bd_t bd;                         // 16
#ifdef CPU_HDR_CONTAINS_EG_PORT
    bit<7> _pad2;                           // 7  \ 16 total
    switch_port_t eg_port;                  // 9  /
#else
    bit<6> _pad2;                           // 6  \ 16 total
    switch_port_lag_index_t port_lag_index; // 10 /
#endif
#if defined(PTP_ENABLE) || defined(INT_V2)
    bit<48> timestamp;
#else
    bit<32> timestamp;                      // 32
#endif
//#if __TARGET_TOFINO__ == 1
//    bit<6> _pad;
//#endif
//    switch_mirror_session_t session_id;     // 8
    switch_cpu_reason_t reason_code;        // 16
/*
#if __TARGET_TOFINO__ == 1
    bit<3> _pad4;
#else
    bit<1> _pad4;
#endif
    switch_qid_t qos_qid;                   // 7
	bit< 5> _pad5;                          // 5  \ 24 total
	bit<19> qos_qdepth;                     // 19 /
*/
}

header switch_cpu_mirror_egress_metadata_h { // this is a header!
    switch_pkt_src_t src;                   // 8
    switch_mirror_type_t type;              // 8
    switch_port_padding_t _pad1;            // 7  \ 16 total
    switch_port_t port;                     // 9  /
    switch_bd_t bd;                         // 16
#ifdef CPU_HDR_CONTAINS_EG_PORT
    bit<7> _pad2;                           // 7  \ 16 total
    switch_port_t eg_port;                  // 9  /
#else
    bit<6> _pad2;                           // 6  \ 16 total
    switch_port_lag_index_t port_lag_index; // 10 /
#endif
#if defined(PTP_ENABLE) || defined(INT_V2)
    bit<48> timestamp;
#else
    bit<32> timestamp;                      // 32
#endif
//#if __TARGET_TOFINO__ == 1
//    bit<6> _pad;
//#endif
//    switch_mirror_session_t session_id;     // 8
    switch_cpu_reason_t reason_code;        // 16
#if __TARGET_TOFINO__ == 1
    bit<3> _pad4;
#else
    bit<1> _pad4;
#endif
    switch_qid_t qos_qid;                   // 7
	bit< 5> _pad5;                          // 5  \ 24 total
	bit<19> qos_qdepth;                     // 19 /
}

// Tunneling ------------------------------------------------------------------

enum switch_tunnel_mode_t { PIPE, UNIFORM }

typedef bit<4> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NONE   = 0;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VXLAN  = 1;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPINIP = 2;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NSH    = 3;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NVGRE  = 4;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTPC   = 5;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTPU   = 6;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_ERSPAN = 7;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GRE    = 8;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VLAN   = 9;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_MPLS   = 10;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_UNSUPPORTED = 11;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GENEVE = 12;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_SPBM = 13;

//#ifndef switch_tunnel_index_width
//#define switch_tunnel_index_width 16
//#endif
typedef bit<switch_tunnel_index_width> switch_tunnel_index_t;
//#ifndef switch_tunnel_ip_index_width
//#define switch_tunnel_ip_index_width 16
//#endif
typedef bit<switch_tunnel_ip_index_width> switch_tunnel_ip_index_t;
#ifndef switch_tunnel_nexthop_width
#define switch_tunnel_nexthop_width 16
#endif
typedef bit<switch_tunnel_nexthop_width> switch_tunnel_nexthop_t;
typedef bit<switch_tunnel_id_width> switch_tunnel_vni_t;

struct switch_tunnel_metadata_t { // for transport
	// note: in addition to tunnel stuff, this structure serves as a catch-all for all non-scoped signals (tunnel related or not)
	// --------------------------------
    switch_tunnel_type_t type;
	switch_tunnel_index_t index; // Egress only.
    switch_tunnel_ip_index_t dip_index;
    switch_tunnel_vni_t vni;
//  switch_ifindex_t ifindex;
//  bit<16> hash;
	bool terminate;
	bit<8> nvgre_flow_id;

	bool unsupported_tunnel;
}

struct switch_tunnel_metadata_reduced_t { // for outer, inner, and inner-inner
	// note: in addition to tunnel stuff, this structure serves as a catch-all for all non-scoped signals (tunnel related or not)
	// --------------------------------
//	switch_tunnel_type_t type;
//	switch_tunnel_index_t index;
//  switch_tunnel_ip_index_t dip_index;
//  switch_tunnel_vni_t vni;
//  switch_ifindex_t ifindex;
//  bit<16> hash;
	bool terminate;
	bit<8> nvgre_flow_id;

	bool unsupported_tunnel;
}

// Data-plane telemetry (DTel) ------------------------------------------------
/* report_type bits for drop and flow reflect dtel_acl results,
 * i.e. whether drop reports and flow reports may be triggered by this packet.
 * report_type bit for queue is not used by bridged / deflected packets,
 * reflects whether queue report is triggered by this packet in cloned packets.
 */
typedef bit<8> switch_dtel_report_type_t;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_NONE         =      0b000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_FLOW         =      0b001;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_QUEUE        =      0b010;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_DROP         =      0b100;

const switch_dtel_report_type_t SWITCH_DTEL_SUPPRESS_REPORT          =     0b1000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_IFA_CLONE    =    0b10000;
const switch_dtel_report_type_t SWITCH_DTEL_IFA_EDGE                 =   0b100000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE =  0b1000000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_ETRAP_HIT    = 0b10000000;

typedef bit<8> switch_ifa_sample_id_t;

#ifdef INT_V2
#define switch_dtel_hw_id_width 4
#else
#define switch_dtel_hw_id_width 6
#endif
typedef bit<switch_dtel_hw_id_width> switch_dtel_hw_id_t;

// Outer header sizes for DTEL Reports
/* Up to the beginning of the DTEL Report v0.5 header
 * 14 (Eth) + 20 (IPv4) + 8 (UDP) + 4 (CRC) = 46 bytes */
const bit<16> DTEL_REPORT_V0_5_OUTER_HEADERS_LENGTH = 46;
/* Outer headers + part of DTEL Report v2 length not included in report_length
 * 14 (Eth) + 20 (IPv4) + 8 (UDP) + 12 (DTEL) + 4 (CRC) = 58 bytes */
const bit<16> DTEL_REPORT_V2_OUTER_HEADERS_LENGTH = 58;

struct switch_dtel_metadata_t {
    switch_dtel_report_type_t report_type;
    bit<1> ifa_gen_clone; // Ingress only, indicates desire to clone this packet
    bit<1> ifa_cloned; // Egress only, indicates this is an ifa cloned packet
    bit<32> latency; // Egress only.
    switch_mirror_session_t session_id;
    switch_mirror_session_t clone_session_id; // Used for IFA interop
    bit<32> hash;
    bit<2> drop_report_flag; // Egress only.
    bit<2> flow_report_flag; // Egress only.
    bit<1> queue_report_flag; // Egress only.
}

header switch_dtel_switch_local_mirror_metadata_h { // 28 bytes?
    switch_pkt_src_t src; // 1
    switch_mirror_type_t type; // 1
#if defined(PTP_ENABLE) || defined(INT_V2)
    bit<48> timestamp; // 6
#else
    bit<32> timestamp;
#endif
#if __TARGET_TOFINO__ == 1
    bit<6> _pad;
#endif
    switch_mirror_session_t session_id; // 1
    bit<32> hash; // 4
    switch_dtel_report_type_t report_type; // 1
    switch_port_padding_t _pad2; // \ 2
    switch_port_t ingress_port;  // /
    switch_port_padding_t _pad3; // \ 2
    switch_port_t egress_port;   // /
#if __TARGET_TOFINO__ == 1
    bit<3> _pad4;
#else
    bit<1> _pad4;
#endif
    switch_qid_t qid; // 1
    bit<5> _pad5;   // \ 3
    bit<19> qdepth; // /
#ifdef INT_V2
    bit<48> egress_timestamp; // 6
#else
    bit<32> egress_timestamp;
#endif
}

header switch_dtel_drop_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
#if defined(PTP_ENABLE) || defined(INT_V2)
    bit<48> timestamp;
#else
    bit<32> timestamp;
#endif
#if __TARGET_TOFINO__ == 1
    bit<6> _pad;
#endif
    switch_mirror_session_t session_id;
    bit<32> hash;
    switch_dtel_report_type_t report_type;
    switch_port_padding_t _pad2;
    switch_port_t ingress_port;
    switch_port_padding_t _pad3;
    switch_port_t egress_port;
#if __TARGET_TOFINO__ == 1
    bit<3> _pad4;
#else
    bit<1> _pad4;
#endif
    switch_qid_t qid;
    switch_drop_reason_t drop_reason;
}

// Used for dtel truncate_only and ifa_clone mirror sessions
header switch_simple_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
#if __TARGET_TOFINO__ == 1
    bit<6> _pad;
#endif
    switch_mirror_session_t session_id;
}

@flexible
struct switch_bridged_metadata_dtel_extension_t {
//  switch_dtel_report_type_t report_type;
//  switch_mirror_session_t session_id;
//  bit<32> hash;
//  switch_port_t egress_port;
}

//-----------------------------------------------------------------------------
// NSH Metadata
//-----------------------------------------------------------------------------

struct nsh_metadata_t {
	bit<2>                          pad;
	bit<6>                          ttl;                    // ingress / egress hdr
	bit<SPI_WIDTH>                  spi;                    // ingress / egress hdr
	bit<8>                          si;                     // ingress / egress hdr
	bit<8>                          ver;                    // ingress          hdr
	bit<VPN_ID_WIDTH>               vpn;                    // ingress / egress hdr
	bit<8>                          scope;                  // ingress / egress hdr
	bit<SSAP_ID_WIDTH>              sap;                    // ingress / egress hdr

//  bool                            start_of_path;          // ingress / egress
    bool                            end_of_path;            // ingress / egress
    bool                            truncate_enable;        // ingress / egress
    bit<14>                         truncate_len;           // ingress / egress
//	bool                            sf1_active;             // ingress / egress

    bit<8>                          si_predec;              // ingress only
    bool                            sfc_enable;             // ingress only (for sfp sel)
    bit<SF_SRVC_FUNC_CHAIN_WIDTH>   sfc;                    // ingress only (for sfp sel)
	bit<SF_HASH_WIDTH>              hash_1;                 // ingress only (for sfp sel)
    bool                            l2_fwd_en;              // ingress only
	bit<32>                         hash_2;                 // ingress only (for dedup)
	bit<9>                          lag_hash_mask_en;       // ingress only
	bool                            lag_hash_non_symmetric_en; // ingress only

    bit<DSAP_ID_WIDTH>              dsap;                   // egress only (for egress sf)
    bool                            strip_tag_e;            // egress only
    bool                            strip_tag_vn;           // egress only
    bool                            strip_tag_vlan;         // egress only
    bit<SF_L2_EDIT_BD_PTR_WIDTH>    add_tag_vlan_bd;        // egress only
    bool                            terminate_outer;        // egress only
    bool                            terminate_inner;        // egress only
    bool                            dedup_en;               // egress only
}

// ** Note: tenant id definition, from draft-wang-sfc-nsh-ns-allocation-00:
//
// Tenant ID: The tenant identifier is used to represent the tenant or security
// policy domain that the Service Function Chain is being applied to. The Tenant
// ID is a unique value assigned by a control plane. The distribution of Tenant
// ID's is outside the scope of this document. As an example application of
// this field, the first node on the Service Function Chain may insert a VRF
// number, VLAN number, VXLAN VNI or a policy domain ID.

//-----------------------------------------------------------------------------
// Other Metadata Definitions
//-----------------------------------------------------------------------------

// Flags
struct switch_ingress_flags_t {
//  bool ipv4_checksum_err_0;
//  bool ipv4_checksum_err_1;
//  bool ipv4_checksum_err_2;
//  bool acl_deny;
//  bool port_vlan_miss;
//  bool rmac_hit;
//	bool dmac_miss;
//  bool glean;
	bool bypass_egress;
    // Add more flags here.
    bool transport_valid;
	bool outer_enet_in_transport;
}

struct switch_egress_flags_t {
	bool routed;
	bool bypass_egress;
//  bool acl_deny;
//  bool rmac_hit;
    // Add more flags here.
    bool transport_valid;
}

// Checks
struct switch_checks_t {
    // Add more checks here.
}

//struct switch_egress_checks_t {
//    // Add more checks here.
//}

struct switch_lookup_fields_t {
	// l2
	bool              l2_valid;
    mac_addr_t        mac_src_addr;
    mac_addr_t        mac_dst_addr;
    bit<16>           mac_type;
    bit<3>            pcp;
	bit<1>            pad; // to keep everything byte-aligned, so that the parser can extract to this struct.
	vlan_id_t         vid;

	// l3
    switch_ip_type_t  ip_type;
    bit<8>            ip_proto;
    bit<8>            ip_tos;
	bit<3>            ip_flags;
    bit<128>          ip_src_addr;
    bit<128>          ip_dst_addr;
	bit<32>           ip_src_addr_v4;
	bit<32>           ip_dst_addr_v4;
    @pa_alias("ingress" , "ig_md.lkp_0.ip_src_addr[31:0]", "ig_md.lkp_0.ip_src_addr_v4" )
    @pa_alias("ingress" , "ig_md.lkp_0.ip_dst_addr[31:0]", "ig_md.lkp_0.ip_dst_addr_v4" )
    @pa_alias("ingress" , "ig_md.lkp_1.ip_src_addr[31:0]", "ig_md.lkp_1.ip_src_addr_v4" )
    @pa_alias("ingress" , "ig_md.lkp_1.ip_dst_addr[31:0]", "ig_md.lkp_1.ip_dst_addr_v4" )
    @pa_alias("ingress" , "ig_md.lkp_2.ip_src_addr[31:0]", "ig_md.lkp_2.ip_src_addr_v4" )
    @pa_alias("ingress" , "ig_md.lkp_2.ip_dst_addr[31:0]", "ig_md.lkp_2.ip_dst_addr_v4" )
    @pa_alias("egress" ,  "eg_md.lkp_1.ip_src_addr[31:0]", "eg_md.lkp_1.ip_src_addr_v4" )
    @pa_alias("egress" ,  "eg_md.lkp_1.ip_dst_addr[31:0]", "eg_md.lkp_1.ip_dst_addr_v4" )
    bit<16>           ip_len;

	// l4
    bit<8>            tcp_flags;
    bit<16>           l4_src_port;
    bit<16>           l4_dst_port;

	// tunnel
    switch_tunnel_type_t tunnel_type;
    switch_tunnel_vni_t  tunnel_id;

    switch_tunnel_type_t tunnel_outer_type; // egress only
    switch_tunnel_type_t tunnel_inner_type; // egress only

	// misc
	bool                 next_lyr_valid;
}

// --------------------------------------------------------------------------------
// Bridged Metadata
// --------------------------------------------------------------------------------

// Header types used by ingress/egress deparsers.
@flexible
struct switch_bridged_metadata_t {
    // user-defined metadata carried over from ingress to egress.
    switch_port_t ingress_port;
#ifdef CPU_HDR_CONTAINS_EG_PORT
//  switch_port_t egress_port; // derek added
#else
    switch_port_lag_index_t ingress_port_lag_index;
#endif
//  switch_bd_t ingress_bd;
    switch_nexthop_t nexthop;
//  switch_pkt_type_t pkt_type;
	bool bypass_egress;
	switch_cpu_reason_t cpu_reason;
#if defined(PTP_ENABLE) || defined(INT_V2)
    bit<48> timestamp;
#else
    bit<32> timestamp;
#endif
	switch_qid_t qid;

    // Add more fields here.

    switch_hash_t hash;
	bool transport_valid;
    bool                            nsh_md_end_of_path;
    bool                            nsh_md_l2_fwd_en;
	bool                            nsh_md_dedup_en;
}

// ----------------------------------------

@flexible
struct switch_bridged_metadata_acl_extension_t {
#if defined(EGRESS_IP_ACL_ENABLE) || defined(EGRESS_MIRROR_ACL_ENABLE)
    bit<16> l4_src_port;
    bit<16> l4_dst_port;
    bit<8> tcp_flags;
    switch_l4_port_label_t l4_src_port_label;
    switch_l4_port_label_t l4_dst_port_label;
  #ifdef ACL_USER_META_ENABLE
    switch_user_metadata_t user_metadata;
  #endif
  #else
    bit<8> tcp_flags;
#endif
}

// ----------------------------------------

@flexible
struct switch_bridged_metadata_tunnel_extension_t {
    switch_tunnel_ip_index_t dip_index;
    switch_tunnel_nexthop_t tunnel_nexthop;
#ifdef VXLAN_ENABLE
//  bit<16> hash;
#endif
//  bool terminate;
}

// ----------------------------------------
/*
@flexible
struct switch_bridged_metadata_nsh_extension_t {
    // ---------------
    // nsh meta data
    // ---------------
    bool                            nsh_md_end_of_path;
    bool                            nsh_md_l2_fwd_en;

	bool                            nsh_md_dedup_en;
}
*/
// ----------------------------------------

#ifdef DTEL_ENABLE
/*
@pa_atomic("ingress", "hdr.bridged_md.base_qid")
@pa_container_size("ingress", "hdr.bridged_md.base_qid", 8)
@pa_container_size("ingress", "hdr.bridged_md.dtel_report_type", 8)
@pa_no_overlay("ingress", "hdr.bridged_md.base_qid")
@pa_no_overlay("ingress", "hdr.bridged_md.__pad_0")
@pa_no_overlay("ingress", "hdr.bridged_md.__pad_1")
@pa_no_overlay("ingress", "hdr.bridged_md.__pad_2")
@pa_no_overlay("ingress", "hdr.bridged_md.__pad_3")
@pa_no_overlay("ingress", "hdr.bridged_md.__pad_4")
@pa_no_overlay("ingress", "hdr.bridged_md.__pad_5")
@pa_no_overlay("egress", "hdr.transport.dtel_report.ingress_port")
@pa_no_overlay("egress", "hdr.transport.dtel_report.egress_port")
@pa_no_overlay("egress", "hdr.transport.dtel_report.queue_id")
@pa_no_overlay("egress", "hdr.transport.dtel_drop_report.drop_reason")
@pa_no_overlay("egress", "hdr.transport.dtel_drop_report.reserved")
#ifdef INT_V2
@pa_no_overlay("egress", "hdr.transport.dtel_metadata_1.ingress_port")
@pa_no_overlay("egress", "hdr.transport.dtel_metadata_1.egress_port")
@pa_no_overlay("egress", "hdr.transport.dtel_metadata_3.queue_id")
@pa_no_overlay("egress", "hdr.transport.dtel_metadata_4.ingress_timestamp")
@pa_no_overlay("egress", "hdr.transport.dtel_metadata_5.egress_timestamp")
@pa_no_overlay("egress", "hdr.transport.dtel_metadata_3.queue_occupancy")
#endif
@pa_no_overlay("egress", "hdr.transport.dtel_switch_local_report.queue_occupancy")
*/

@pa_no_overlay("ingress", "hdr.bridged_md.__pad_4")

#endif

// ----------------------------------------

typedef bit<8> switch_bridge_type_t;

header switch_bridged_metadata_h {
    switch_pkt_src_t src;
    switch_bridge_type_t type;
    switch_bridged_metadata_t base;
//	switch_bridged_metadata_nsh_extension_t nsh;
#if defined(EGRESS_IP_ACL_ENABLE) || defined(EGRESS_MIRROR_ACL_ENABLE) \
    || defined(DTEL_FLOW_REPORT_ENABLE)
    switch_bridged_metadata_acl_extension_t acl;
#endif
#ifdef TUNNEL_ENABLE
    switch_bridged_metadata_tunnel_extension_t tunnel;
#endif
    switch_bridged_metadata_dtel_extension_t dtel;
}

// --------------------------------------------------------------------------------
// Bridged Metadata
// --------------------------------------------------------------------------------

@flexible
struct switch_bridged_metadata_folded_t {
	// user-defined metadata carried over from egress to ingress.
    switch_port_t ingress_port;
#ifdef CPU_HDR_CONTAINS_EG_PORT
//  switch_port_t egress_port; // derek added
#else
    switch_port_lag_index_t ingress_port_lag_index;
#endif
//  switch_bd_t ingress_bd;
    switch_nexthop_t nexthop;
//  switch_pkt_type_t pkt_type;
    bool bypass_egress;
    switch_cpu_reason_t cpu_reason;
#if defined(PTP_ENABLE) || defined(INT_V2)
    bit<48> timestamp;
#else
    bit<32> timestamp;
#endif
    switch_qid_t qid;

	// Add more fields here.

    switch_hash_t hash;
	bool transport_valid;
    bool                            nsh_md_end_of_path;
    bool                            nsh_md_l2_fwd_en;
	bool                            nsh_md_dedup_en;
}

// ----------------------------------------

header switch_bridged_metadata_folded_h {
    switch_pkt_src_t src;
    switch_bridge_type_t type;
    switch_bridged_metadata_folded_t base;
//	switch_bridged_metadata_nsh_extension_t nsh;
#if defined(EGRESS_IP_ACL_ENABLE) || defined(EGRESS_MIRROR_ACL_ENABLE) \
    || defined(DTEL_FLOW_REPORT_ENABLE)
    switch_bridged_metadata_acl_extension_t acl;
#endif
#ifdef TUNNEL_ENABLE
    switch_bridged_metadata_tunnel_extension_t tunnel;
#endif
    switch_bridged_metadata_dtel_extension_t dtel;
}

// --------------------------------------------------------------------------------
// Ingress Port Metadata
// --------------------------------------------------------------------------------

struct switch_port_metadata_t {
#ifdef CPU_HDR_CONTAINS_EG_PORT
#else
    switch_port_lag_index_t         port_lag_index;
//  switch_ifindex_t                ifindex;
	bit<1>                          l2_fwd_en;
#endif

#if __TARGET_TOFINO__ == 2
/*
    switch_yid_t exclusion_id;

	// for packets w/o nsh header:
    bit<SSAP_ID_WIDTH>              sap;
    bit<VPN_ID_WIDTH>               vpn;
    bit<SPI_WIDTH>                  spi;
    bit<8>                          si;
    bit<8>                          si_predec;
*/
#endif
}

@pa_auto_init_metadata

// --------------------------------------------------------------------------------
// Ingress Metadata
// --------------------------------------------------------------------------------

//@pa_container_size("ingress", "ig_md.mirror.src", 8)
//@pa_container_size("ingress", "ig_md.mirror.type", 8)
//@pa_container_size("ingress", "smac_src_move", 16)
@pa_alias("ingress", "ig_md.egress_port", "ig_intr_md_for_tm.ucast_egress_port")
#if !defined(DTEL_DROP_REPORT_ENABLE) && !defined(DTEL_QUEUE_REPORT_ENABLE)
@pa_alias("ingress", "ig_md.multicast.id", "ig_intr_md_for_tm.mcast_grp_b")
#endif
//@pa_alias("ingress", "ig_md.qos.qid", "ig_intr_md_for_tm.qid")
//@pa_alias("ingress", "ig_md.qos.icos", "ig_intr_md_for_tm.ingress_cos")
#ifdef MIRROR_INGRESS_ENABLE
@pa_alias("ingress", "ig_intr_md_for_dprsr.mirror_type", "ig_md.mirror.type")
#endif

struct switch_ingress_metadata_t {
    switch_port_t ingress_port;                       /* ingress port */
    switch_port_t egress_port;                        /* egress  port */
    switch_port_lag_index_t ingress_port_lag_index;   /* ingress port/lag index */
    switch_port_lag_index_t egress_port_lag_index;    /* egress  port/lag index */    /* derek: passed to egress */
    switch_bd_t bd;
    switch_nexthop_t nexthop;                                                         /* derek: egress table pointer #1 */
    switch_tunnel_nexthop_t tunnel_nexthop;                                           /* derek: egress table pointer #2 */
//  switch_nexthop_t acl_nexthop;
//  bool acl_redirect;
	switch_nexthop_t unused_nexthop;
    switch_hash_t hash;

    switch_ingress_flags_t flags;
//  switch_checks_t checks;
	switch_ingress_bypass_t bypass;

    switch_drop_reason_t drop_reason; // used by dtel code
	switch_cpu_reason_t cpu_reason;

//#ifdef INGRESS_PARSER_POPULATES_LKP_0
    switch_lookup_fields_t              lkp_0;
//#endif
    switch_lookup_fields_t              lkp_1;    // initially non-scoped, later scoped, version of fields
//#ifdef INGRESS_PARSER_POPULATES_LKP_2
    switch_lookup_fields_t              lkp_2;    // non-scoped version of fields
//#endif
    switch_multicast_metadata_t multicast;
	switch_qos_metadata_t qos;
	switch_mirror_metadata_t mirror;
    switch_tunnel_metadata_t         tunnel_0;  // non-scoped version of fields /* derek: egress table pointer #3 (tunnel_0.dip_index) */
    switch_tunnel_metadata_reduced_t tunnel_1;  // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_2;  // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_3;  // non-scoped version of fields
	switch_dtel_metadata_t dtel;

#if defined(PTP_ENABLE) || defined(INT_V2)
    bit<48> ingress_timestamp;
#else
    bit<32> ingress_timestamp;
#endif

    nsh_metadata_t nsh_md;
}

// --------------------------------------------------------------------------------
// Egress Metadata
// --------------------------------------------------------------------------------

//@pa_container_size("egress", "eg_md.mirror.src", 8)
//@pa_container_size("egress", "eg_md.mirror.type", 8)
#ifdef DTEL_ENABLE
// @pa_container_size("egress", "hdr.dtel_drop_report.drop_reason", 8)
@pa_mutually_exclusive("egress", "hdr.dtel.timestamp", "hdr.erspan_type3.timestamp")
#endif

struct switch_egress_metadata_t {
    switch_port_t ingress_port;                       /* ingress port */
    switch_port_t egress_port;                        /* egress port (mutable copy) */
    switch_port_lag_index_t egress_port_lag_index;    /* egress port/lag index */
    switch_bd_t bd;
    switch_nexthop_t nexthop;
    switch_tunnel_nexthop_t tunnel_nexthop;
    switch_hash_t hash;

    switch_egress_flags_t flags;
//  switch_checks_t checks;

    switch_drop_reason_t drop_reason; // used by dtel code
	switch_cpu_reason_t cpu_reason;

    switch_lookup_fields_t              lkp_1;    //     scoped version of fields
	switch_qos_metadata_t qos;
    switch_tunnel_metadata_t         tunnel_0;  // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_1;  // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_2;  // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_3;  // non-scoped version of fields
	switch_mirror_metadata_t mirror;
	switch_dtel_metadata_t dtel;

    switch_pkt_src_t pkt_src;
//  switch_pkt_length_t pkt_length;
//  switch_pkt_type_t pkt_type;
    switch_pkt_length_t payload_len;
#ifdef INT_V2
    bit<48> egress_timestamp;
    bit<48> ingress_timestamp;
#else
    bit<32> egress_timestamp;
    bit<32> ingress_timestamp;
#endif

    nsh_metadata_t nsh_md;
}

// --------------------------------------------------------------------------
// Headers
// --------------------------------------------------------------------------

struct switch_mirror_metadata_h {
/*
    switch_port_mirror_ingress_metadata_h port_ingress;
    switch_port_mirror_egress_metadata_h port_egress;
*/
    switch_cpu_mirror_ingress_metadata_h cpu_ingress;
    switch_cpu_mirror_egress_metadata_h cpu_egress;
    switch_dtel_drop_mirror_metadata_h dtel_drop;
    switch_dtel_switch_local_mirror_metadata_h dtel_switch_local;
    switch_simple_mirror_metadata_h simple_mirror;
}

// -----------------------------------------------------------------------------

struct switch_header_transport_t {

    ethernet_h ethernet;
    vlan_tag_h[1] vlan_tag;
    nsh_type1_h nsh_type1;
    nsh_type1_internal_h nsh_type1_internal;
    //mpls_h[MPLS_DEPTH_TRANSPORT] mpls;
    mpls_h mpls_0;
    mpls_h mpls_1;
    mpls_h mpls_2;
    mpls_h mpls_3;
    mpls_h mpls_4;
    mpls_h mpls_5;

    ipv4_h ipv4;
    ipv6_h ipv6;

    udp_h udp;

    geneve_h geneve;
    vxlan_h vxlan;    

    gre_h gre;
	gre_extension_sequence_h gre_sequence;
    erspan_type2_h erspan_type2;
    //erspan_type3_h erspan_type3;

#ifdef INT_V2
    dtel_report_v20_h dtel;
    dtel_metadata_1_h dtel_metadata_1;
    dtel_metadata_2_h dtel_metadata_2;
    dtel_metadata_3_h dtel_metadata_3;
    dtel_metadata_4_h dtel_metadata_4;
    dtel_metadata_5_h dtel_metadata_5;
    dtel_report_metadata_15_h dtel_drop_report;
#else
    dtel_report_v05_h dtel;
    dtel_report_base_h dtel_report;
    dtel_switch_local_report_h dtel_switch_local_report;
    dtel_drop_report_h dtel_drop_report;
#endif
}

// -----------------------------------------------------------------------------

struct switch_header_outer_t {

    ethernet_h ethernet;
    e_tag_h e_tag;
    vn_tag_h vn_tag;
    vlan_tag_h[VLAN_DEPTH_OUTER] vlan_tag;
    //mpls_h[MPLS_DEPTH_OUTER] mpls;
    mpls_h mpls_0;
    mpls_h mpls_1;
    mpls_h mpls_2;
    mpls_h mpls_3;
    // mpls_h mpls_4;
    // mpls_h mpls_5;
    mpls_pw_cw_h mpls_pw_cw;

    ipv4_h ipv4;
    ipv6_h ipv6;

    udp_h udp;
    tcp_h tcp;
    sctp_h sctp;

    geneve_h geneve;
    vxlan_h vxlan;

    gre_h gre;
    gre_optional_h gre_optional;
    nvgre_h nvgre;

    gtp_v1_base_h gtp_v1_base;
    gtp_v1_optional_h gtp_v1_optional;
	gtp_v2_base_h gtp_v2_base;
}

// -----------------------------------------------------------------------------

struct switch_header_inner_t {

    ethernet_h ethernet;
    vlan_tag_h[1] vlan_tag;

    ipv4_h ipv4;
    ipv6_h ipv6;

    udp_h udp;
    tcp_h tcp;
    sctp_h sctp;

    gre_h gre;
    gre_optional_h gre_optional;

    gtp_v1_base_h gtp_v1_base;
    gtp_v1_optional_h gtp_v1_optional;
	gtp_v2_base_h gtp_v2_base;
}

// -----------------------------------------------------------------------------

struct switch_header_inner_inner_t {
	dummy_ethernet_h ethernet;
	dummy_ipv4_h ipv4;
	dummy_ipv6_h ipv6;
}

// -----------------------------------------------------------------------------

struct switch_header_t {

    // ===========================
    // misc
    // ===========================

    switch_bridged_metadata_h bridged_md;
	// switch_mirror_metadata_h mirror;
	switch_bridged_metadata_folded_h bridged_md_folded;
    fabric_h fabric;
    cpu_h cpu;

    // ===========================
    // transport
    // ===========================

	switch_header_transport_t transport;

    // ===========================
    // outer
    // ===========================

	switch_header_outer_t outer;

    // ===========================
    // inner
    // ===========================

    switch_header_inner_t inner;

    // ===========================
    // inner
    // ===========================

    switch_header_inner_inner_t inner_inner;

    // ===========================
    // layer7
    // ===========================

    udf_h udf;

}

#endif /* _P4_TYPES_ */
