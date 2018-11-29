/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2018 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

#ifndef _P4_TYPES_
#define _P4_TYPES_

// ----------------------------------------------------------------------------
// Common protocols/types
//-----------------------------------------------------------------------------
#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_ARP  0x0806
#define ETHERTYPE_VLAN 0x8100
#define ETHERTYPE_IPV6 0x86dd
#define ETHERTYPE_MPLS 0x8847
#define ETHERTYPE_PTP  0x88F7
#define ETHERTYPE_FCOE 0x8906
#define ETHERTYPE_ROCE 0x8915
#define ETHERTYPE_BFN  0x9000
#define ETHERTYPE_QINQ 0x9100

#define IP_PROTOCOLS_ICMP   1
#define IP_PROTOCOLS_IGMP   2
#define IP_PROTOCOLS_IPV4   4
#define IP_PROTOCOLS_TCP    6
#define IP_PROTOCOLS_UDP    17
#define IP_PROTOCOLS_IPV6   41
#define IP_PROTOCOLS_SRV6   43
#define IP_PROTOCOLS_GRE    47
#define IP_PROTOCOLS_ICMPV6 58

#define UDP_PORT_VXLAN  4789
#define UDP_PORT_ROCEV2 4791
#define UDP_PORT_GENV   6081
#define UDP_PORT_SFLOW  6343
#define UDP_PORT_MPLS   6635

#define GRE_PROTOCOLS_ERSPAN_TYPE_3 0x22EB
#define GRE_PROTOCOLS_NVGRE         0x6558
#define GRE_PROTOCOLS_IP            0x0800
#define GRE_PROTOCOLS_ERSPAN_TYPE_2 0x88BE

#define VLAN_DEPTH 2
#define MPLS_DEPTH 3


#define SFC_DEPTH 2 //[only include current and next Function, next is optinal]
#define SFC_END 0
#define CPU_PORT 64

#define SFC_LOAD_BALANCER_ID 10
#define LOAD_BALANCER_PORT 1

#define SFC_XGW_ID 11
#define XGW_PORT 129

#define SFC_ROUTER_ID 12
#define ROUTER_PORT 257



// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------
typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;

typedef PortId_t switch_port_t;
const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;

typedef QueueId_t switch_qid_t;
typedef MirrorId_t switch_mirror_id_t;
typedef ReplicationId_t switch_rid_t;
typedef bit<3> switch_ingress_cos_t;

typedef bit<3> switch_digest_type_t;
const switch_digest_type_t SWITCH_DIGEST_TYPE_MAC_LEARNING = 0;
const switch_digest_type_t SWITCH_DIGEST_TYPE_INVALID = 7;

typedef bit<16> switch_ifindex_t;
const switch_ifindex_t SWITCH_IFINDEX_FLOOD = 16w0xffff;

typedef bit<9> switch_port_lag_index_t;
typedef bit<16> switch_bd_t;
typedef bit<16> switch_vrf_t;
typedef bit<16> switch_nexthop_t;
typedef bit<16> switch_xid_t;
typedef bit<9> switch_yid_t;

typedef bit<16> switch_port_lag_label_t;
typedef bit<16> switch_bd_label_t;
typedef bit<16> switch_if_label_t;

#ifdef ACL_RANGE_ENABLE
typedef bit<8> switch_l4_port_label_t;
#else
typedef bit<16> switch_l4_port_label_t;
#endif

typedef bit<10> switch_rmac_group_t;
typedef bit<16> switch_smac_index_t;

typedef bit<16> switch_mtu_index_t;

typedef bit<12> switch_stats_index_t;

typedef bit<16> switch_cpu_reason_t;
typedef bit<8> switch_drop_reason_t;
const switch_drop_reason_t SWITCH_DROP_REASON_UNKNOWN = 0;
const switch_drop_reason_t SWITCH_DROP_OUTER_SRC_MAC_ZERO = 10;
const switch_drop_reason_t SWITHC_DROP_OUTER_SRC_MAC_MULTICAST = 11;
const switch_drop_reason_t SWITCH_DROP_OUTER_DST_MAC_ZERO = 12;
const switch_drop_reason_t SWITCH_DROP_OUTER_ETHERNET_MISS = 13;
const switch_drop_reason_t SWITCH_DROP_SRC_MAC_ZERO = 14;
const switch_drop_reason_t SWITCH_DROP_SRC_MAC_MULTICAST = 15;
const switch_drop_reason_t SWITCH_DROP_DST_MAC_ZERO = 16;
const switch_drop_reason_t SWITCH_DROP_OUTER_IP_VERSION_INVALID = 25;
const switch_drop_reason_t SWITCH_DROP_OUTER_IP_TTL_ZERO = 26;
const switch_drop_reason_t SWITCH_DROP_OUTER_IP_SRC_MULTICAST = 27;
const switch_drop_reason_t SWITCH_DROP_OUTER_IP_SRC_LOOPBACK = 28;
const switch_drop_reason_t SWITCH_DROP_OUTER_IP_MISS = 29;
const switch_drop_reason_t SWITCH_DROP_OUTER_IP_IHL_INVALID = 30;
const switch_drop_reason_t SWITCH_DROP_OUTER_IP_INVALID_CHECKSUM = 31;
const switch_drop_reason_t SWITCH_DROP_IP_VERSION_INVALID = 40;
const switch_drop_reason_t SWITCH_DROP_IP_TTL_ZERO = 41;
const switch_drop_reason_t SWITCH_DROP_IP_SRC_MULTICAST = 42;
const switch_drop_reason_t SWITCH_DROP_IP_SRC_LOOPBACK = 43;
const switch_drop_reason_t SWITCH_DROP_IP_IHL_INVALID = 44;
const switch_drop_reason_t SWITCH_DROP_IP_INVALID_CHECKSUM = 45;
const switch_drop_reason_t SWITCH_DROP_PORT_VLAN_MAPPING_MISS = 55;
const switch_drop_reason_t SWITCH_DROP_STP_STATE_LEARNING = 56;
const switch_drop_reason_t SWITCH_DROP_STP_STATE_BLOCKING = 57;
const switch_drop_reason_t SWITCH_DROP_SAME_IFINDEX = 58;
const switch_drop_reason_t SWITCH_DROP_MULTICAST_SNOOPING_ENABLED = 59;
const switch_drop_reason_t SWITCH_DROP_MTU_CHECK_FAIL = 70;
const switch_drop_reason_t SWITCH_DROP_TRAFFIC_MANAGER = 71;
const switch_drop_reason_t SWITCH_DROP_METER = 72;
const switch_drop_reason_t SWITCH_DROP_ACL_DENY = 80;
const switch_drop_reason_t SWITCH_DROP_RACL_DENY = 81;
const switch_drop_reason_t SWITCH_DROP_URPF_CHECK_FAIL = 82;
const switch_drop_reason_t SWITCH_DROP_IPSG_MISS = 83;
const switch_drop_reason_t SWITCH_DROP_IFINDEX = 84;
const switch_drop_reason_t SWITCH_DROP_CPU_COLOR_YELLOW = 85;
const switch_drop_reason_t SWITCH_DROP_CPU_COLOR_RED = 86;
const switch_drop_reason_t SWITCH_DROP_STORM_CONTROL_COLOR_YELLOW = 87;
const switch_drop_reason_t SWITCH_DROP_STORM_CONTROL_COLOR_RED = 88;
const switch_drop_reason_t SWITCH_DROP_L2_MISS_UNICAST = 89;
const switch_drop_reason_t SWITCH_DROP_L2_MISS_MULTICAST = 90;
const switch_drop_reason_t SWITCH_DROP_L2_MISS_BROADCAST = 91;
const switch_drop_reason_t SWITCH_DROP_L3_IPV6_DISABLE = 100;

typedef bit<1> switch_port_type_t;
const switch_port_type_t SWITCH_PORT_TYPE_NORMAL = 0;
const switch_port_type_t SWITCH_PORT_TYPE_CPU = 1;

typedef bit<2> switch_ip_type_t;
const switch_ip_type_t SWITCH_IP_TYPE_NONE = 0;
const switch_ip_type_t SWITCH_IP_TYPE_IPV4 = 1;
const switch_ip_type_t SWITCH_IP_TYPE_IPV6 = 2;

// Bypass flags ---------------------------------------------------------------
typedef bit<8> switch_ingress_bypass_t;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L2 = 8w0x01;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L3 = 8w0x02;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ACL = 8w0x04;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SYSTEM_ACL = 8w0x08;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_QOS = 8w0x10;

// Add more bypass flags here.

const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ALL = 8w0xff;

#define BYPASS(t) (ig_md.bypass & SWITCH_INGRESS_BYPASS_##t != 0)


// PKT ------------------------------------------------------------------------
typedef bit<16> switch_pkt_length_t;

//TODO(msharif) : try to reduce the bit width
typedef bit<8> switch_pkt_src_t;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGE = 0;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONE_INGRESS = 1;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONE_EGRESS = 2;

typedef bit<2> switch_pkt_color_t;
const switch_pkt_color_t SWITCH_METER_COLOR_GREEN = 0;
const switch_pkt_color_t SWITCH_METER_COLOR_YELLOW = 1;
const switch_pkt_color_t SWITCH_METER_COLOR_RED = 2;

typedef bit<2> switch_pkt_type_t;
const switch_pkt_type_t SWITCH_PKT_TYPE_UNICAST = 0;
const switch_pkt_type_t SWITCH_PKT_TYPE_MULTICAST = 1;
const switch_pkt_type_t SWITCH_PKT_TYPE_BROADCAST = 2;

// STP ------------------------------------------------------------------------
typedef bit<2> switch_stp_state_t;
const switch_stp_state_t SWITCH_STP_STATE_FORWARDING = 0;
const switch_stp_state_t SWITCH_STP_STATE_BLOCKING = 1;
const switch_stp_state_t SWITCH_STP_STATE_LEARNING = 2;

typedef bit<10> switch_stp_group_t;

struct switch_stp_metadata_t {
    switch_stp_group_t group;
    switch_stp_state_t state_;
}

// QoS ------------------------------------------------------------------------
typedef bit<2> switch_qos_trust_mode_t;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_UNTRUSTED = 0;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_TRUST_DSCP = 1;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_TRUST_PCP = 2;

typedef bit<5> switch_qos_group_t;
typedef bit<8> switch_tc_t;
typedef bit<3> switch_cos_t;

struct switch_qos_metadata_t {
    switch_qos_trust_mode_t trust_mode; // Ingress only.
    switch_qos_group_t group;
    switch_tc_t tc;
    switch_pkt_color_t color;
}

// Learning -------------------------------------------------------------------
//TODO(msharif): Add drop and cpu_trap mode?
typedef bit<1> switch_learning_mode_t;
const switch_learning_mode_t SWITCH_LEARNING_MODE_DISABLED = 0;
const switch_learning_mode_t SWITCH_LEARNING_MODE_LEARN = 1;

struct switch_learning_digest_t {
    @pa_container_size("ingress", "digest.bd", 16)
    switch_bd_t bd;
    @pa_container_size("ingress", "digest.ifindex", 16)
    switch_ifindex_t ifindex;
    @pa_container_size("ingress", "digest.src_addr", 16)
    mac_addr_t src_addr;
}

struct switch_learning_metadata_t {
    switch_learning_mode_t mode;
    switch_learning_digest_t digest;
}

// Multicast ------------------------------------------------------------------
typedef bit<2> switch_multicast_mode_t;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_NONE = 0;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_SM = 1; // Sparse mode
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_BIDIR = 2; // Bidirectional

typedef MulticastGroupId_t switch_mgid_t;
typedef bit<16> switch_multicast_rpf_group_t;
struct switch_multicast_metadata_t {
    bit<2> mode;
    switch_multicast_rpf_group_t rpf_group;
}

// URPF -----------------------------------------------------------------------
typedef bit<2> switch_urpf_mode_t;
const switch_urpf_mode_t SWITCH_URPF_MODE_NONE = 0;
const switch_urpf_mode_t SWITCH_URPF_MODE_LOOSE = 1;
const switch_urpf_mode_t SWITCH_URPF_MODE_STRICT = 2;

// WRED/ECN -------------------------------------------------------------------
#define switch_wred_index_width 8
typedef bit<switch_wred_index_width> switch_wred_index_t;
typedef bit<12> switch_wred_stats_index_t;

typedef bit<2> switch_ecn_codepoint_t;
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_NON_ECT = 0b00; // Non ECN-capable transport
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_ECT0 = 0b10; // ECN capable transport
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_ECT1 = 0b01; // ECN capable transport
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_CE = 0b11; // Congestion encountered

// Metering -------------------------------------------------------------------
#define switch_copp_meter_id_width 8
typedef bit<switch_copp_meter_id_width> switch_copp_meter_id_t;

typedef bit<16> switch_meter_index_t;


// Tunneling ------------------------------------------------------------------
typedef bit<5> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NONE = 0;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VXLAN = 1;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GRE = 2;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_MPLS = 4;

typedef bit<1> switch_tunnel_term_type_t;
const switch_tunnel_term_type_t SWITCH_TUNNEL_TERM_TYPE_P2P = 0x0; // Point-to-Point
const switch_tunnel_term_type_t SWITCH_TUNNEL_TERM_TYPE_P2MP = 0x1; // Point-to-Multipoint

typedef bit<16> switch_tunnel_index_t;
//-----------------------------------------------------------------------------
// Other Metadata Definitions
//-----------------------------------------------------------------------------
// Flags
struct switch_ingress_flags_t {
    bool ipv4_checksum_err;
    bool inner_ipv4_checksum_err;
    bool link_local;
    bool routed;
    bool acl_deny;
    bool racl_deny;
    bool port_vlan_miss;
    bool rmac_hit;
    bool myip;
    bool glean;
    bool flood_to_multicast_routers;

    // Add more flags here.
}

struct switch_egress_flags_t {
    bool routed;

    // Add more flags here.
}


// Checks
struct switch_ingress_checks_t {
    switch_bd_t same_bd;
    switch_ifindex_t same_if;
    bool mrpf;
    bool urpf;
    // Add more checks here.
}

struct switch_egress_checks_t {
    switch_bd_t same_bd;
    switch_mtu_index_t mtu;
    bool stp;

    // Add more checks here.
}

// IP
struct switch_ip_metadata_t {
    bool unicast_enable;
    bool multicast_enable;
    bool multicast_snooping;
    // switch_urpf_mode_t urpf_mode;
}

// Tunnel
struct switch_tunnel_metadata_t {
    switch_tunnel_type_t type;
    //TODO(msharif) : should use 2 different types for tunnel_index and
    switch_tunnel_index_t index; // egress only.
    switch_tunnel_index_t dst_index;
    bit<24> id;
    bool terminate;
}

/*
header_union switch_pktgen_h {
    pktgen_timer_header_t timer;
    pktgen_port_down_header_t port_down;
    pktgen_recirc_header_t recirc;
}*/

struct switch_lookup_fields_t {
    switch_pkt_type_t pkt_type;

    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<16> mac_type;
    bit<3> pcp;

    //XXX this should only be 2 bits.
    bit<16> arp_opcode;

    switch_ip_type_t ip_type;
    bit<8> ip_proto;
    bit<8> ip_ttl;
    bit<8> ip_dscp;
    ipv4_addr_t ipv4_src_addr;
    ipv4_addr_t ipv4_dst_addr;
    ipv6_addr_t ipv6_src_addr;
    ipv6_addr_t ipv6_dst_addr;

    bit<8> tcp_flags;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;
}

// Header types used by ingress/egress deparsers.
header switch_bridged_metadata_t {
    // user-defined metadata carried over from ingress to egress.
    switch_pkt_src_t src;
    bit<7> _pad0;
    switch_port_t ingress_port;
    switch_ifindex_t ingress_ifindex;
    switch_ifindex_t egress_ifindex;
    switch_bd_t ingress_bd;
    switch_nexthop_t nexthop;
    bit<7> _pad1;
    bit<1> routed;
    bit<7> _pad2;
    bit<1> tunnel_terminate;
    bit<6> _pad3;
    switch_pkt_type_t pkt_type;
    switch_tc_t tc;
    switch_cpu_reason_t cpu_reason;

    // add more fields here.
}

header switch_bridged_metadata_tunnel_extension_t {
    switch_nexthop_t outer_nexthop;
    switch_tunnel_index_t tunnel_index;
    bit<16> entropy_hash;
}

//TODO(msharif) : Need to define multple headers to support mirroring with
// different metadata. Also need a separate header for session info
// (session_id, id).
header switch_mirror_metadata_t {
    switch_pkt_src_t src;
    bit<8> id;
    bit<32> timestamp;
    bit<6> _pad;
    switch_mirror_id_t session_id;
}

header switch_port_metadata_t {
    bit<7> pad_;
    switch_port_lag_index_t port_lag_index;
    switch_port_lag_label_t port_lag_label;
    switch_port_type_t port_type;

    // add more fields here.
    bit<31> _pad1;
}


// Ingress metadata
struct switch_ingress_metadata_t {
    switch_ifindex_t ifindex;                      /* ingress interface index */
    switch_port_type_t port_type;                  /* ingress port type */
    switch_port_t port;                            /* ingress port */
    switch_port_lag_index_t port_lag_index;        /* ingress port/lag index */
    switch_ifindex_t egress_ifindex;               /* egress interface index */
    switch_port_lag_index_t egress_port_lag_index; /* egress port/lag index */
    switch_bd_t bd;
    switch_vrf_t vrf;
    switch_nexthop_t nexthop;
    switch_nexthop_t outer_nexthop;
    bit<48> timestamp;

    switch_ingress_flags_t flags;
    switch_ingress_checks_t checks;
    switch_ingress_bypass_t bypass;

    switch_ip_metadata_t ipv4_md; //XXX change the name
    switch_ip_metadata_t ipv6_md; //XXX change the name
    switch_port_lag_label_t port_lag_label;
    switch_bd_label_t bd_label;
    switch_if_label_t if_label;
    switch_l4_port_label_t src_port_label;
    switch_l4_port_label_t dst_port_label;

    switch_drop_reason_t drop_reason;
    switch_cpu_reason_t cpu_reason;

    switch_rmac_group_t rmac_group;
    switch_multicast_metadata_t multicast;
    switch_stp_metadata_t stp;
    switch_qos_metadata_t qos;
    switch_tunnel_metadata_t tunnel;
    switch_learning_metadata_t learning;
    switch_mirror_metadata_t mirror;
}

// struct lb_ingress_metadata_t{
//     bit<32> srcIp;
//     bit<32> dstIp;
//     bit<8> protocol;
//     bit<16> srcPort;
//     bit<16> dstPort;
//     bit<32> sessionId;
// }

struct sfc_ingress_metadata_t{
    bit<8> controlCode;
    bit<8> nf0;
    bit<8> nf1;
    bit<8> nf2;
    bit<8> nf3;
    bit<8> nf4;
}

struct lb_egress_metadata_t{
    bit<32> srcIp;
    bit<32> dstIp;
    bit<8> protocol;
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> sessionId;
    bool ipv4_checksum_err;
    bool inner_ipv4_checksum_err;
    bit<24> vni;

}

struct xgw_egress_metadata_t{
    bit<32> srcIp;
    bit<32> dstIp;
    bit<8> protocol;
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> sessionId;
    bool hitSession;
    bool ipv4_checksum_err;
    bool inner_ipv4_checksum_err;
}

struct router_egress_metadata_t{
    /* empty */
    bit<32> srcIp;
    bit<32> dstIp;
}

struct lb_header_t{
    ethernet_h ethernet;
    ipv4_h ipv4;
    tcp_h tcp;
    udp_h udp;
    vxlan_h vxlan;
    ethernet_h inner_ethernet;
    ipv4_h inner_ipv4;
    udp_h inner_udp;
    tcp_h inner_tcp;
}

struct sfc_header_t{
    sfc_ethernet_h sfc_ethernet;
}


// struct sfc_header_t {
//     switch_bridged_metadata_t bridged_md;
//     ethernet_h ethernet;
//     ipv4_h ipv4;
//     udp_h udp;
//     tcp_h tcp;
//     vxlan_h vxlan;

//     ethernet_h inner_ethernet;
//     ipv4_h inner_ipv4;
//     ipv6_h inner_ipv6;
//     udp_h inner_udp;
//     tcp_h inner_tcp;
// }

#endif /* _P4_TYPES_ */
