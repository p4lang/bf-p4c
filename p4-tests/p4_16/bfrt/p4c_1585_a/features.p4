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

// ***** ORIGINAL SWITCH DEFINES -- FOR REFERENCE  *****
// ***** (what barefoot initially had them set to) *****

/*
#define L4_PORT_LOU_ENABLE
// #define TCP_FLAGS_LOU_ENABLE
// #define BRIDGE_PORT_ENABLE
#define ERSPAN_ENABLE
// #define ERSPAN_TYPE2_ENABLE
#define IPV6_ENABLE
#define MIRROR_ENABLE
#define MIRROR_ACL_ENABLE
#define INGRESS_PORT_MIRROR_ENABLE
#define EGRESS_PORT_MIRROR_ENABLE
#define PTP_ENABLE
#define QOS_ENABLE
// #define QOS_ACL_ENABLE
#define INGRESS_POLICER_ENABLE
// #define STP_ENABLE
// #define MULTIPLE_STP
// #define WRED_ENABLE
#define COPP_ENABLE
#define MULTICAST_ENABLE
#define RACL_ENABLE
// #define PBR_ENABLE
#define STORM_CONTROL_ENABLE
// #define QINQ_ENABLE
#if __TARGET_TOFINO__ == 1
#define TUNNEL_ENABLE
// #define IPV6_TUNNEL_ENABLE
#define VXLAN_ENABLE
#endif
// #define MLAG_ENABLE
// #define MAC_PACKET_CLASSIFICATION
// #define PACKET_LENGTH_ADJUSTMENT
#define IPINIP
*/

// -----------------------------

#undef  L4_PORT_LOU_ENABLE
// #define TCP_FLAGS_LOU_ENABLE
// #define BRIDGE_PORT_ENABLE
#define ERSPAN_ENABLE
// #define ERSPAN_TYPE2_ENABLE
#undef  MIRROR_ENABLE
#undef  MIRROR_ACL_ENABLE
#undef  INGRESS_PORT_MIRROR_ENABLE
#undef  EGRESS_PORT_MIRROR_ENABLE
#undef  PTP_ENABLE
#undef  QOS_ENABLE
// #define QOS_ACL_ENABLE
#undef  INGRESS_POLICER_ENABLE
// #define STP_ENABLE
// #define MULTIPLE_STP
// #define WRED_ENABLE
#undef  COPP_ENABLE
#define MULTICAST_ENABLE
#undef  RACL_ENABLE
// #define PBR_ENABLE
#undef  STORM_CONTROL_ENABLE
// #define QINQ_ENABLE
//#if __TARGET_TOFINO__ == 1
#define TUNNEL_ENABLE
// #define IPV6_TUNNEL_ENABLE
//#endif
// #define MLAG_ENABLE
// #define MAC_PACKET_CLASSIFICATION
// #define PACKET_LENGTH_ADJUSTMENT

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

// define for selecting simple tables, rather than action_selectors/action_profiles tables
#define SIMPLE_SFC
#define SIMPLE_SFF

// define for action selector, undef for action_profile -- if simple is undefined.
#define COMPLEX_SFC_TYPE_ACTION_SELECTOR
#define COMPLEX_SFF_TYPE_ACTION_SELECTOR

// per header stack counters for debug
#undef  ING_HDR_STACK_COUNTERS

// define so that you don't have to program up any tables to get a packet through (for debug only!)
#define SEND_PKT_OUT_PORT_IT_CAME_IN_ON

// define for simultaneous switch and npb functionality (undefine for npb only)
#undef  ENABLE_SWITCH_MAC_AND_FIB_TABLES
