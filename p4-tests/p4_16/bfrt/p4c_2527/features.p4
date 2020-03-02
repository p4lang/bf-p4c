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

// List of all supported #define directives.

// ==========================================================
// ==========================================================
// ==========================================================
// Tofino 1
// ==========================================================
// ==========================================================
// ==========================================================

#if __TARGET_TOFINO__ == 1

#undef  ERSPAN_INGRESS_ENABLE
#undef  ERSPAN_EGRESS_ENABLE
#undef  MIRROR_ENABLE
#define MULTICAST_ENABLE
// #define QINQ_ENABLE
// #define QINQ_RIF_ENABLE
#define TUNNEL_ENABLE
#undef  VALIDATION_ENABLE

#define IPINIP
#define IPV6_ENABLE
#define VXLAN_ENABLE
#define GRE_ENABLE

// define to stub out the vast majority of the ingress MAU - for debug
#undef  ING_STUBBED_OUT
// define to stub out the vast majority of the egress MAU - for debug
#undef  EGR_STUBBED_OUT

#define GTP_ENABLE
#undef  MPLS_ENABLE

#undef  SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
#undef  SFC_TRANSPORT_TUNNEL_IPV6_TABLE_ENABLE
#undef  SFC_OUTER_TUNNEL_TABLE_ENABLE
#undef  SFC_TIMESTAMP_ENABLE // undef for sims, define for real chip

// define for selecting simple tables, rather than action_selectors/action_profiles tables.
#define SFF_SCHD_SIMPLE

// define for action selector, undef for action_profile -- only used if _SIMPLE is undefined.
#define SFF_SCHD_COMPLEX_TYPE_ACTION_SELECTOR

// define for simultaneous switch and npb functionality (undefine for npb only)
#undef  BRIDGING_ENABLE
#undef  TRANSPORT_ENABLE

#undef  SF_0_LEN_RNG_TABLE_ENABLE
#undef  SF_0_ACL_SHARED_IP_ENABLE
#undef  SF_0_ACL_INT_CTRL_FLAGS_ENABLE

#undef  SF_2_LEN_RNG_TABLE_ENABLE
#undef  SF_2_ACL_SHARED_IP_ENABLE
#undef  SF_2_ACL_MAC_KEY_ENABLE
#define SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
#undef  SF_2_METER_ENABLE
#undef  SF_2_DEDUP_ENABLE

// define to include per header-stack counters (for debug - currently used by parser tests)
#define ING_HDR_STACK_COUNTERS 

// define to enable user-defined fields (this feature needs work - placeholder for now)
#undef UDF_ENABLE // if SF_0_ONE_POLICY_TABLE is defined, you may need to shrink the UDF width to fit

// define to enable the handling of parser errors in MAU
// (currently, only udf-releated partial header errors are supported)
// (currently, all parser errors get dropped in the parser due to p4c limitation (case #9472)) 
#undef PARSER_ERROR_HANDLING_ENABLE

// define to include the parse_cpu state in the ingress parser.
// when enabled in certain configurations, we exceed tofino's 12 (mau) stages.
#undef PARSER_INGRESS_CPU_STATE

// define to enable parser/deparser support for inner ARP, ICMP, IGMP, GRE, ESP headers.
// these headers are not currently used in MAU, so removing them (undef) may result in PHV savings.
// not sure if some will evenutally be needed for L7 UDF stuff - hence the define...
#undef PARDE_INNER_CONTROL_ENABLE // ARP, ICMP, IGMP, ICMPv6
#undef PARDE_INNER_GRE_ENABLE
#undef PARDE_INNER_ESP_ENABLE

#define BUG_09719_WORKAROUND // saturating subtracts       -- feature is broken
#undef  BUG_10015_WORKAROUND // ingress transport decap    -- compiler crash (sigsegv)
#undef  BUG_INVALID_LONG_BRANCH_WORKAROUND
#define BUG_10439_WORKAROUND // casting from bit<32> to bit<128> in parser

#undef  BRIDGING_L2_FWD_EN_SIGNAL_ENABLE

#else // __TARGET_TOFINO__

// ==========================================================
// ==========================================================
// ==========================================================
// Tofino 2
// ==========================================================
// ==========================================================
// ==========================================================

#undef  ERSPAN_INGRESS_ENABLE
#undef  ERSPAN_EGRESS_ENABLE
#undef  MIRROR_ENABLE
#define MULTICAST_ENABLE
// #define QINQ_ENABLE
// #define QINQ_RIF_ENABLE
#define TUNNEL_ENABLE
#undef  VALIDATION_ENABLE

#define IPINIP
#define IPV6_ENABLE
#define VXLAN_ENABLE
#define GRE_ENABLE

// define to stub out the vast majority of the ingress MAU - for debug
#undef  ING_STUBBED_OUT
// define to stub out the vast majority of the egress MAU - for debug
#undef  EGR_STUBBED_OUT

#define GTP_ENABLE
#undef  MPLS_ENABLE

#undef  SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
#undef  SFC_TRANSPORT_TUNNEL_IPV6_TABLE_ENABLE
#define SFC_OUTER_TUNNEL_TABLE_ENABLE
#undef  SFC_TIMESTAMP_ENABLE // undef for sims, define for real chip

// define for selecting simple tables, rather than action_selectors/action_profiles tables.
#define SFF_SCHD_SIMPLE

// define for action selector, undef for action_profile -- only used if _SIMPLE is undefined.
#define SFF_SCHD_COMPLEX_TYPE_ACTION_SELECTOR

// define for simultaneous switch and npb functionality (undefine for npb only)
#define BRIDGING_ENABLE
#define TRANSPORT_ENABLE

#undef  SF_0_LEN_RNG_TABLE_ENABLE
#undef  SF_0_ACL_SHARED_IP_ENABLE
#undef  SF_0_ACL_INT_CTRL_FLAGS_ENABLE

#undef  SF_2_LEN_RNG_TABLE_ENABLE
#undef  SF_2_ACL_SHARED_IP_ENABLE
#undef  SF_2_ACL_MAC_KEY_ENABLE
#define SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
#undef  SF_2_METER_ENABLE
#undef  SF_2_DEDUP_ENABLE

// define to include per header-stack counters (for debug - currently used by parser tests)
#define ING_HDR_STACK_COUNTERS 

// define to enable user-defined fields (this feature needs work - placeholder for now)
#undef UDF_ENABLE // if SF_0_ONE_POLICY_TABLE is defined, you may need to shrink the UDF width to fit

// define to enable the handling of parser errors in MAU
// (currently, only udf-releated partial header errors are supported)
// (currently, all parser errors get dropped in the parser due to p4c limitation (case #9472)) 
#undef PARSER_ERROR_HANDLING_ENABLE

// define to include the parse_cpu state in the ingress parser.
// when enabled in certain configurations, we exceed tofino's 12 (mau) stages.
#undef PARSER_INGRESS_CPU_STATE

// define to enable parser/deparser support for inner ARP, ICMP, IGMP, GRE, ESP headers.
// these headers are not currently used in MAU, so removing them (undef) may result in PHV savings.
// not sure if some will evenutally be needed for L7 UDF stuff - hence the define...
#undef PARDE_INNER_CONTROL_ENABLE // ARP, ICMP, IGMP, ICMPv6
#undef PARDE_INNER_GRE_ENABLE
#undef PARDE_INNER_ESP_ENABLE

#define BUG_09719_WORKAROUND // saturating subtracts       -- feature is broken
#undef  BUG_10015_WORKAROUND // ingress transport decap    -- compiler crash (sigsegv)
#undef  BUG_INVALID_LONG_BRANCH_WORKAROUND
#define BUG_10439_WORKAROUND // casting from bit<32> to bit<128> in parser

#define BRIDGING_L2_FWD_EN_SIGNAL_ENABLE

#endif // __TARGET_TOFINO__
