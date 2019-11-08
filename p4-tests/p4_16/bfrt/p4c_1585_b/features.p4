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
 *
 ******************************************************************************/

// List of all supported #define directives.

// ***** ORIGINAL SWITCH DEFINES -- FOR REFERENCE  *****
// ***** (what barefoot initially had them set to) *****

/*
// #define ACL_REDIRECT_ENABLE
// #define BRIDGE_PORT_ENABLE
#define COPP_ENABLE

#if __TARGET_TOFINO__ == 1
#define DTEL_ENABLE
#define DTEL_QUEUE_REPORT_ENABLE
#define DTEL_DROP_REPORT_ENABLE
#define DTEL_FLOW_REPORT_ENABLE
#define DTEL_ACL_ENABLE
#endif

// #define ECN_ACL_ENABLE
// #define EGRESS_ACL_ENABLE
#define EGRESS_PORT_MIRROR_ENABLE
#define ERSPAN_ENABLE
#define ERSPAN_TYPE2_ENABLE
#define INGRESS_POLICER_ENABLE
#define INGRESS_PORT_MIRROR_ENABLE
// #define IPINIP_ENABLE
#define IPV6_ENABLE
// #define IPV6_TUNNEL_ENABLE
#define L4_PORT_LOU_ENABLE
// #define MAC_PACKET_CLASSIFICATION
#define MIRROR_ENABLE
#define MIRROR_ACL_ENABLE
// #define MLAG_ENABLE
#define MULTICAST_ENABLE
#define PACKET_LENGTH_ADJUSTMENT
// #define PBR_ENABLE
#define PTP_ENABLE
// #define QINQ_ENABLE
#define QINQ_RIF_ENABLE
#define QOS_ENABLE
// #define QOS_ACL_ENABLE
#define RACL_ENABLE
#define STORM_CONTROL_ENABLE
// #define STP_ENABLE
// #define TCP_FLAGS_LOU_ENABLE
// #define TUNNEL_ENABLE
#define UNICAST_SELF_FORWARDING_CHECK
// #define VXLAN_ENABLE
// #define WRED_ENABLE
*/

// ==========================================================
// ==========================================================
// ==========================================================
// Tofino 1
// ==========================================================
// ==========================================================
// ==========================================================

#if __TARGET_TOFINO__ == 1

// #define ACL_REDIRECT_ENABLE
// #define BRIDGE_PORT_ENABLE
#undef  COPP_ENABLE

#if __TARGET_TOFINO__ == 1
#undef  DTEL_ENABLE
#undef  DTEL_QUEUE_REPORT_ENABLE
#undef  DTEL_DROP_REPORT_ENABLE
#undef  DTEL_FLOW_REPORT_ENABLE
#undef  DTEL_ACL_ENABLE
#endif

// #define ECN_ACL_ENABLE
// #define EGRESS_ACL_ENABLE
#undef  EGRESS_PORT_MIRROR_ENABLE
#undef  ERSPAN_ENABLE
#undef  ERSPAN_TYPE2_ENABLE
#undef  INGRESS_POLICER_ENABLE
#undef  INGRESS_PORT_MIRROR_ENABLE
// (below)
// (below)
// #define IPV6_TUNNEL_ENABLE
#undef  L4_PORT_LOU_ENABLE
// #define MAC_PACKET_CLASSIFICATION
#undef  MIRROR_ENABLE
#undef  MIRROR_ACL_ENABLE
// #define MLAG_ENABLE
#define MULTICAST_ENABLE
#undef  PACKET_LENGTH_ADJUSTMENT
// #define PBR_ENABLE
#undef  PTP_ENABLE
// #define  QINQ_ENABLE
#undef  QINQ_RIF_ENABLE
#undef  QOS_ENABLE
// #define QOS_ACL_ENABLE
#undef  RACL_ENABLE
#undef  STORM_CONTROL_ENABLE
// #define STP_ENABLE
// #define TCP_FLAGS_LOU_ENABLE
#define TUNNEL_ENABLE
#undef  UNICAST_SELF_FORWARDING_CHECK
// (below)
// #define WRED_ENABLE

#define IPINIP
#undef  IPV6_ENABLE
#define VXLAN_ENABLE

// -----------------------------
// Extreme Networks Additions
// -----------------------------

#undef  ING_STUBBED_OUT
#undef  EGR_STUBBED_OUT

//#define MPLS_ENABLE
//#define GTP_ENABLE
//#define SPBM_ENABLE

// define for selecting simple tables, rather than action_selectors/action_profiles tables
#define SFC_SIMPLE
#define SFF_SIMPLE

// define for action selector, undef for action_profile -- if simple is undefined.
#define SFC_COMPLEX_TYPE_ACTION_SELECTOR
#define SFF_COMPLEX_TYPE_ACTION_SELECTOR

// per header stack counters for debug
#undef  ING_HDR_STACK_COUNTERS

// define so that you don't have to program up any tables to get a packet through (for debug only!)
#define SEND_PKT_OUT_PORT_IT_CAME_IN_ON

// define for simultaneous switch and npb functionality (undefine for npb only)
#undef  ENABLE_SWITCH_MAC_AND_FIB_TABLES

#undef  SF_METER_ENABLE

#undef  SF_DEDUP_ENABLE

// ==========================================================

/*

// TOFINO 1,  WITH DEDUP 

// #define ACL_REDIRECT_ENABLE
// #define BRIDGE_PORT_ENABLE
#undef  COPP_ENABLE

#if __TARGET_TOFINO__ == 1
#undef  DTEL_ENABLE
#undef  DTEL_QUEUE_REPORT_ENABLE
#undef  DTEL_DROP_REPORT_ENABLE
#undef  DTEL_FLOW_REPORT_ENABLE
#undef  DTEL_ACL_ENABLE
#endif

// #define ECN_ACL_ENABLE
// #define EGRESS_ACL_ENABLE
#undef  EGRESS_PORT_MIRROR_ENABLE
#define ERSPAN_ENABLE
#undef  ERSPAN_TYPE2_ENABLE
#undef  INGRESS_POLICER_ENABLE
#undef  INGRESS_PORT_MIRROR_ENABLE
// (below)
// (below)
// #define IPV6_TUNNEL_ENABLE
#undef  L4_PORT_LOU_ENABLE
// #define MAC_PACKET_CLASSIFICATION
#undef  MIRROR_ENABLE
#undef  MIRROR_ACL_ENABLE
// #define MLAG_ENABLE
#define MULTICAST_ENABLE
#undef  PACKET_LENGTH_ADJUSTMENT
// #define PBR_ENABLE
#undef  PTP_ENABLE
// #define  QINQ_ENABLE
#undef  QINQ_RIF_ENABLE
#undef  QOS_ENABLE
// #define QOS_ACL_ENABLE
#undef  RACL_ENABLE
#undef  STORM_CONTROL_ENABLE
// #define STP_ENABLE
// #define TCP_FLAGS_LOU_ENABLE
#undef  TUNNEL_ENABLE
#undef  UNICAST_SELF_FORWARDING_CHECK
// (below)
// #define WRED_ENABLE

#undef  IPINIP
#undef  IPV6_ENABLE
#undef  VXLAN_ENABLE

// -----------------------------
// Extreme Networks Additions
// -----------------------------

#undef  ING_STUBBED_OUT
#undef  EGR_STUBBED_OUT

//#define MPLS_ENABLE
//#define GTP_ENABLE
//#define SPBM_ENABLE

// define for selecting simple tables, rather than action_selectors/action_profiles tables
#define SFC_SIMPLE
#define SFF_SIMPLE

// define for action selector, undef for action_profile -- if simple is undefined.
#define SFC_COMPLEX_TYPE_ACTION_SELECTOR
#define SFF_COMPLEX_TYPE_ACTION_SELECTOR

// per header stack counters for debug
#undef  ING_HDR_STACK_COUNTERS

// define so that you don't have to program up any tables to get a packet through (for debug only!)
#define SEND_PKT_OUT_PORT_IT_CAME_IN_ON

// define for simultaneous switch and npb functionality (undefine for npb only)
#undef  ENABLE_SWITCH_MAC_AND_FIB_TABLES

#undef  SF_METER_ENABLE

#define SF_DEDUP_ENABLE

*/

#else // __TARGET_TOFINO__

// ==========================================================
// ==========================================================
// ==========================================================
// Tofino 2
// ==========================================================
// ==========================================================
// ==========================================================

// #define ACL_REDIRECT_ENABLE
// #define BRIDGE_PORT_ENABLE
#undef  COPP_ENABLE

#if __TARGET_TOFINO__ == 1
#undef  DTEL_ENABLE
#undef  DTEL_QUEUE_REPORT_ENABLE
#undef  DTEL_DROP_REPORT_ENABLE
#undef  DTEL_FLOW_REPORT_ENABLE
#undef  DTEL_ACL_ENABLE
#endif

// #define ECN_ACL_ENABLE
// #define EGRESS_ACL_ENABLE
#undef  EGRESS_PORT_MIRROR_ENABLE
#undef  ERSPAN_ENABLE
#undef  ERSPAN_TYPE2_ENABLE
#undef  INGRESS_POLICER_ENABLE
#undef  INGRESS_PORT_MIRROR_ENABLE
// (below)
// (below)
// #define IPV6_TUNNEL_ENABLE
#undef  L4_PORT_LOU_ENABLE
// #define MAC_PACKET_CLASSIFICATION
#undef  MIRROR_ENABLE
#undef  MIRROR_ACL_ENABLE
// #define MLAG_ENABLE
#define MULTICAST_ENABLE
#undef  PACKET_LENGTH_ADJUSTMENT
// #define PBR_ENABLE
#undef  PTP_ENABLE
// #define  QINQ_ENABLE
#undef  QINQ_RIF_ENABLE
#undef  QOS_ENABLE
// #define QOS_ACL_ENABLE
#undef  RACL_ENABLE
#undef  STORM_CONTROL_ENABLE
// #define STP_ENABLE
// #define TCP_FLAGS_LOU_ENABLE
#define TUNNEL_ENABLE
#undef  UNICAST_SELF_FORWARDING_CHECK
// (below)
// #define WRED_ENABLE

#define IPINIP
#undef  IPV6_ENABLE
#define VXLAN_ENABLE

// -----------------------------
// Extreme Networks Additions
// -----------------------------

#undef  ING_STUBBED_OUT
#undef  EGR_STUBBED_OUT

//#define MPLS_ENABLE
//#define GTP_ENABLE
//#define SPBM_ENABLE

// define for selecting simple tables, rather than action_selectors/action_profiles tables
#define SFC_SIMPLE
#define SFF_SIMPLE

// define for action selector, undef for action_profile -- if simple is undefined.
#define SFC_COMPLEX_TYPE_ACTION_SELECTOR
#define SFF_COMPLEX_TYPE_ACTION_SELECTOR

// per header stack counters for debug
#undef  ING_HDR_STACK_COUNTERS

// define so that you don't have to program up any tables to get a packet through (for debug only!)
#define SEND_PKT_OUT_PORT_IT_CAME_IN_ON

// define for simultaneous switch and npb functionality (undefine for npb only)
#undef  ENABLE_SWITCH_MAC_AND_FIB_TABLES

#undef  SF_METER_ENABLE

#undef  SF_DEDUP_ENABLE

#endif // __TARGET_TOFINO__
