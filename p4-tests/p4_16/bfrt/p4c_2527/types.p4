/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

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

#define UDP_PORT_VXLAN  4789
#define UDP_PORT_ROCEV2 4791
#define UDP_PORT_GENV   6081
#define UDP_PORT_SFLOW  6343
#define UDP_PORT_MPLS   6635
#define UDP_PORT_GTP_C  2123
#define UDP_PORT_GTP_U  2152
#define UDP_PORT_GTP_PRIME 3386

#define GRE_PROTOCOLS_ERSPAN_TYPE_3 0x22EB
#define GRE_PROTOCOLS_NVGRE         0x6558
#define GRE_PROTOCOLS_IP            0x0800
#define GRE_PROTOCOLS_ERSPAN_TYPE_2 0x88BE

#define VLAN_DEPTH 2
//#define MPLS_DEPTH 3
#define MPLS_DEPTH 4

// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------
typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;

typedef PortId_t switch_port_t;
const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;

typedef ReplicationId_t switch_rid_t;
const switch_rid_t SWITCH_RID_DEFAULT = 0xffff;

typedef bit<3> switch_digest_type_t;
const switch_digest_type_t SWITCH_DIGEST_TYPE_INVALID = 0;
const switch_digest_type_t SWITCH_DIGEST_TYPE_MAC_LEARNING = 1;

typedef bit<16> switch_ifindex_t;
typedef bit<10> switch_port_lag_index_t;
const switch_port_lag_index_t SWITCH_FLOOD = 0x3ff;

typedef bit<16> switch_bd_t;
const switch_bd_t SWITCH_BD_DEFAULT_VRF = 4097; // bd allocated for default vrf

#ifndef switch_nexthop_width
#define switch_nexthop_width 16
#endif
typedef bit<switch_nexthop_width> switch_nexthop_t;
typedef bit<16> switch_outer_nexthop_t;

typedef bit<16> switch_xid_t;
typedef bit<9> switch_yid_t;

typedef bit<16> switch_smac_index_t;

typedef bit<12> switch_stats_index_t;

#define switch_drop_reason_width 8
typedef bit<switch_drop_reason_width> switch_drop_reason_t;
const switch_drop_reason_t SWITCH_DROP_REASON_UNKNOWN = 0;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_ZERO = 10;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_MULTICAST = 11;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_DST_MAC_ZERO = 12;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_ETHERNET_MISS = 13;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_ZERO = 14;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_MULTICAST = 15;
const switch_drop_reason_t SWITCH_DROP_REASON_DST_MAC_ZERO = 16;
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
const switch_ip_frag_t SWITCH_IP_FRAG_HEAD = 0b10; // First fragment of the fragmented packets.
const switch_ip_frag_t SWITCH_IP_FRAG_NON_HEAD = 0b11; // Fragment with non-zero offset.

// PKT ------------------------------------------------------------------------

typedef bit<16> switch_pkt_length_t;

typedef bit<8> switch_pkt_src_t;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED = 0;

typedef bit<2> switch_pkt_type_t;
const switch_pkt_type_t SWITCH_PKT_TYPE_UNICAST = 0;
const switch_pkt_type_t SWITCH_PKT_TYPE_MULTICAST = 1;
const switch_pkt_type_t SWITCH_PKT_TYPE_BROADCAST = 2;

// Multicast ------------------------------------------------------------------

typedef bit<2> switch_multicast_mode_t;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_NONE = 0;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_SM = 1; // Sparse mode
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_BIDIR = 2; // Bidirectional

typedef MulticastGroupId_t switch_mgid_t;

typedef bit<16> switch_multicast_rpf_group_t;

struct switch_multicast_metadata_t {
    switch_mgid_t id;
    bit<2> mode;
    switch_multicast_rpf_group_t rpf_group;
}

// Tunneling ------------------------------------------------------------------

enum switch_tunnel_mode_t { PIPE, UNIFORM }

typedef bit<4> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NONE = 0;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VXLAN = 1;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPINIP = 2;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NSH = 3;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NVGRE = 4;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTPC = 5;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTPU = 6;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_ERSPAN = 7;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GRE = 8;
//const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VLAN = 9;

#ifndef switch_tunnel_index_width
#define switch_tunnel_index_width 16
#endif
typedef bit<switch_tunnel_index_width> switch_tunnel_index_t;
typedef bit<24> switch_tunnel_id_t;

struct switch_tunnel_metadata_t {
    switch_tunnel_type_t type;
    switch_tunnel_index_t index;
    switch_tunnel_id_t id;
	bit<8> flow_id;
    switch_ifindex_t ifindex;
    bit<16> hash;
    bool terminate;
}

//-----------------------------------------------------------------------------
// Other Metadata Definitions
//-----------------------------------------------------------------------------

// Flags
//XXX Force the fields that are XORd to NOT share containers.
struct switch_ingress_flags_t {
    bool ipv4_checksum_err_0;
    bool ipv4_checksum_err_1;
    bool ipv4_checksum_err_2;
    bool acl_deny;
    bool port_vlan_miss;
    bool rmac_hit;
	bool dmac_miss;
//  bool glean;
    // Add more flags here.
}

struct switch_egress_flags_t {
    bool ipv4_checksum_err_0;
    bool ipv4_checksum_err_1;
    bool ipv4_checksum_err_2;
    bool acl_deny;
    bool rmac_hit;
    // Add more flags here.
}

// Checks
struct switch_ingress_checks_t {
    // Add more checks here.
}

struct switch_egress_checks_t {
    // Add more checks here.
}

struct switch_lookup_fields_t {
	// l2
    mac_addr_t        mac_src_addr;
    mac_addr_t        mac_dst_addr;
    bit<16>           mac_type;
    bit<3>            pcp;
	bit<5>            pad; // to keep everything byte-aligned, so that the parser can extract to this struct.

	// l3
    switch_ip_type_t  ip_type;
    bit<8>            ip_proto;
    bit<8>            ip_tos;
#ifdef BUG_10439_WORKAROUND
    bit<32>           ip_src_addr_3;
    bit<32>           ip_src_addr_2;
    bit<32>           ip_src_addr_1;
    bit<32>           ip_src_addr_0;
    bit<32>           ip_dst_addr_3;
    bit<32>           ip_dst_addr_2;
    bit<32>           ip_dst_addr_1;
    bit<32>           ip_dst_addr_0;
#else
    bit<128>          ip_src_addr;
    bit<128>          ip_dst_addr;
#endif // BUG_10439_WORKAROUND
    bit<16>           ip_len;

	// l4
    bit<8>            tcp_flags;
    bit<16>           l4_src_port;
    bit<16>           l4_dst_port;

	// tunnel
    switch_tunnel_type_t tunnel_type;
    switch_tunnel_id_t   tunnel_id;

    switch_drop_reason_t drop_reason;
}

// --------------------------------------------------------------------------------
// Bridged Metadata
// --------------------------------------------------------------------------------

// Header types used by ingress/egress deparsers.
@flexible
struct switch_bridged_metadata_t {
    // user-defined metadata carried over from ingress to egress.
    switch_port_t ingress_port;
    switch_port_lag_index_t ingress_port_lag_index;
    switch_bd_t ingress_bd;
    switch_nexthop_t nexthop;
//  switch_pkt_type_t pkt_type;
//  bit<48> timestamp;
	bool   rmac_hit;

    // Add more fields here.

    // ---------------
    // nsh meta data
    // ---------------
    bool                            nsh_type1_hdr_is_new;        // set by sfc

    bit<3>                          nsh_type1_sf_bitmask;        //  1 byte

    // ---------------
    // dedup stuff
    // ---------------
#ifdef SF_2_DEDUP_ENABLE
    bit<8>                          ip_proto;
    ipv4_addr_t                     ipv4_src_addr;
    ipv4_addr_t                     ipv4_dst_addr;
#endif
}

// ----------------------------------------

@flexible
struct switch_bridged_metadata_tunnel_extension_t {
    switch_tunnel_index_t index;
    switch_outer_nexthop_t outer_nexthop;
    bit<16> hash;

//  bool terminate;
    bool terminate_0;
    bool terminate_1;
    bool terminate_2;
	bool nsh_terminate;
}

typedef bit<8> switch_bridge_type_t;

// ----------------------------------------

header switch_bridged_metadata_h {
    switch_pkt_src_t src;
    switch_bridge_type_t type;
    switch_bridged_metadata_t base;
#ifdef TUNNEL_ENABLE
    switch_bridged_metadata_tunnel_extension_t tunnel;
#endif
}

// --------------------------------------------------------------------------------
// Ingress port metadata
// --------------------------------------------------------------------------------

struct switch_port_metadata_t {
    switch_port_lag_index_t port_lag_index;
//  switch_ifindex_t ifindex;
}

// --------------------------------------------------------------------------------
// Ingress metadata
// --------------------------------------------------------------------------------

@pa_container_size("ingress", "ig_md.lkp.l4_src_port", 8)
@pa_alias("ingress", "ig_md.egress_port", "ig_intr_md_for_tm.ucast_egress_port")
@pa_alias("ingress", "ig_md.multicast.id", "ig_intr_md_for_tm.mcast_grp_b")

struct switch_ingress_metadata_t {
    switch_port_t port;                            /* ingress port */
    switch_port_t egress_port;                     /* egress port */
    switch_port_lag_index_t port_lag_index;        /* ingress port/lag index */
    switch_port_lag_index_t egress_port_lag_index; /* egress port/lag index */    /* derek: passed to egress */
    switch_bd_t bd;
    switch_nexthop_t nexthop;                                                     /* derek: egress table pointer #1 */
    switch_outer_nexthop_t outer_nexthop;                                         /* derek: egress table pointer #2 */
//  switch_nexthop_t acl_nexthop;
//  bool acl_redirect;

    bit<48> timestamp;
    bit<32> hash;
    bit<32> hash_nsh;

    switch_ingress_flags_t flags;
//  switch_ingress_checks_t checks;

    switch_drop_reason_t drop_reason_general;
    switch_drop_reason_t drop_reason_0;
    switch_drop_reason_t drop_reason_1;
    switch_drop_reason_t drop_reason_2;

    switch_lookup_fields_t lkp;
#ifdef UDF_ENABLE
    bit<UDF_WIDTH>         lkp_l7_udf; // ingress only
#endif

    switch_multicast_metadata_t multicast;
    switch_tunnel_metadata_t tunnel_0;                                            /* derek: egress table pointer #3 (tunnel_0.index) */
    switch_tunnel_metadata_t tunnel_1;
    switch_lookup_fields_t   lkp_2;
    switch_tunnel_metadata_t tunnel_2;
	bool nsh_terminate;

#ifdef UDF_ENABLE
    bit<1>                  parse_udf_reached;
#endif
    nsh_type1_internal_lkp_t nsh_type1;
}

// --------------------------------------------------------------------------------
// Egress metadata
// --------------------------------------------------------------------------------

struct switch_egress_metadata_t {
    switch_pkt_src_t pkt_src;
    switch_pkt_length_t pkt_length;
//  switch_kt_type_t pkt_type;

    switch_port_lag_index_t port_lag_index;     /* egress port/lag index */
    switch_port_t port;                         /* Mutable copy of egress port */
    switch_port_t ingress_port;                 /* ingress port */
    switch_ifindex_t ingress_ifindex;           /* ingress interface index */
    switch_bd_t bd;
    switch_nexthop_t nexthop;
    switch_outer_nexthop_t outer_nexthop;

//  bit<32> timestamp;
//  bit<48> ingress_timestamp;

    switch_egress_flags_t flags;
//  switch_egress_checks_t checks;

    switch_lookup_fields_t lkp;
    switch_tunnel_type_t   lkp_tunnel_outer_type;
    switch_tunnel_type_t   lkp_tunnel_inner_type;

    switch_tunnel_metadata_t tunnel_0;
    switch_tunnel_metadata_t tunnel_1;
    switch_tunnel_metadata_t tunnel_2;
	bool nsh_terminate;

    switch_drop_reason_t drop_reason_general;
    switch_drop_reason_t drop_reason_0;
    switch_drop_reason_t drop_reason_1;
    switch_drop_reason_t drop_reason_2;

    nsh_type1_internal_lkp_t nsh_type1;

    bit<6>                                              action_bitmask;
//  bit<NPB_EGR_SF_EGRESS_SFP_ACT_SEL_TABLE_DEPTH_POW2> action_3_meter_id;
    bit<10>                                             action_3_meter_id;
    bit<8>                                              action_3_meter_overhead;
}

// --------------------------------------------------------------------------
// Headers
// --------------------------------------------------------------------------

struct switch_header_transport_t {

    ethernet_h ethernet;
    vlan_tag_h[1] vlan_tag;
    nsh_type1_h nsh_type1;

#if defined(ERSPAN_INGRESS_ENABLE) || defined(ERSPAN_EGRESS_ENABLE)
    ipv4_h ipv4;
    gre_h gre;
	gre_extension_sequence_h gre_sequence;
    erspan_type2_h erspan_type2;
    erspan_type3_h erspan_type3;
#endif /* defined(ERSPAN_INGRESS_ENABLE) || defined(ERSPAN_EGRESS_ENABLE) */

}

// -----------------------------------------------------------------------------

struct switch_header_outer_t {

    ethernet_h ethernet;
    e_tag_h e_tag;
    vn_tag_h vn_tag;
    vlan_tag_h[VLAN_DEPTH] vlan_tag;
#ifdef MPLS_ENABLE
    mpls_h[MPLS_DEPTH] mpls;
#endif
    ipv4_h ipv4;
#ifdef IPV6_ENABLE
    ipv6_h ipv6;
#endif  /* IPV6_ENABLE */
    arp_h arp;
    udp_h udp;
    icmp_h icmp;
    igmp_h igmp;
    tcp_h tcp;
    vxlan_h vxlan;
    gre_h gre;
    nvgre_h nvgre;

#ifdef MPLS_ENABLE
    mpls_pw_cw_h mpls_pw_cw;
#endif  /* MPLS_ENABLE */

    sctp_h sctp;
    esp_h esp;

#ifdef GTP_ENABLE
    gtp_v1_base_h gtp_v1_base;
    gtp_v2_base_h gtp_v2_base;
#endif  /* GTP_ENABLE */

}

// -----------------------------------------------------------------------------

struct switch_header_inner_t {

    ethernet_h ethernet;
    ipv4_h ipv4;
#ifdef IPV6_ENABLE
    ipv6_h ipv6;
#endif  /* IPV6_ENABLE */
    udp_h udp;
    tcp_h tcp;
#ifdef PARDE_INNER_CONTROL_ENABLE
    icmp_h icmp;
#endif

    vlan_tag_h[1] vlan_tag;
    sctp_h sctp;

#ifdef PARDE_INNER_GRE_ENABLE
    gre_h gre;
#endif

#ifdef PARDE_INNER_ESP_ENABLE
    esp_h esp;
#endif

#ifdef PARDE_INNER_CONTROL_ENABLE
    arp_h arp;
    igmp_h igmp;
#endif

}

// -----------------------------------------------------------------------------

struct switch_header_t {

    // ===========================
    // misc 
    // ===========================

    switch_bridged_metadata_h bridged_md;

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
    // layer7
    // ===========================

    udf_h l7_udf;

}

#endif /* _P4_TYPES_ */
