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

// ===== pkt header defines =================================

// ----- applies to: transport -----
#undef  IPV6_TRANSPORT_INGRESS_ENABLE // currently only used for sfc tunnel tables
#undef  GRE_TRANSPORT_INGRESS_ENABLE
#undef  ERSPAN_TRANSPORT_INGRESS_ENABLE

#undef  GRE_TRANSPORT_EGRESS_ENABLE_V4
#undef  GRE_TRANSPORT_EGRESS_ENABLE_V6
#undef  ERSPAN_TRANSPORT_EGRESS_ENABLE // v4 only

// ----- applies to: outer -----
#define ETAG_ENABLE
#define VNTAG_ENABLE
#define IPINIP
#define VXLAN_ENABLE
#define NVGRE_ENABLE
#define GRE_ENABLE
#define GTP_ENABLE
#undef  MPLS_ENABLE

// ----- applies to: inner -----
#undef  INNER_GRE_ENABLE
#undef  INNER_GTP_ENABLE

// ----- applies to: outer and inner -----
#define IPV6_ENABLE
#define UDF_ENABLE // if SF_0_ONE_POLICY_TABLE is defined, you may need to shrink the UDF width to fit

// ===== feature defines ====================================

// ----- parser -----
#undef  INGRESS_PARSER_POPULATES_LKP_0
#undef  INGRESS_PARSER_POPULATES_LKP_1
#undef  INGRESS_PARSER_POPULATES_LKP_2
#define EGRESS_PARSER_POPULATES_LKP_WITH_OUTER
#define EGRESS_PARSER_POPULATES_LKP_SCOPED
#undef  PARSER_ERROR_HANDLING_ENABLE

// ----- switch: mirroring -----
#undef  MIRROR_INGRESS_ENABLE      // only valid if MIRROR_ENABLE is defined
#undef  MIRROR_ENABLE              // for egress
#undef  MIRROR_INGRESS_PORT_ENABLE // only valid if MIRROR_INGRESS_ENABLE is defined
#undef  MIRROR_EGRESS_PORT_ENABLE  // only valid if MIRROR_ENABLE is defined

// ----- switch: cpu -----
#undef  CPU_ENABLE
#undef  CPU_ACL_INGRESS_ENABLE
#undef  CPU_ACL_EGRESS_ENABLE   // only valid if MIRROR_ENABLE is defined
#undef  CPU_COPP_INGRESS_ENABLE // only valid if CPU_ENABLE    is defined
#undef  CPU_COPP_EGRESS_ENABLE  // only valid if CPU_ENABLE    is defined
#undef  CPU_FABRIC_HEADER_ENABLE
#undef  CPU_PORT_INGRESS_ENABLE // port copy-to-cpu (an alternative to port mirroring, if that doesn't fit)

// ----- switch: dtel -----
#undef  DTEL_ENABLE
#undef  DTEL_QUEUE_REPORT_ENABLE
#undef  DTEL_DROP_REPORT_ENABLE
#undef  DTEL_FLOW_REPORT_ENABLE
#undef  DTEL_ACL_ENABLE

// ----- switch: other -----
#define MULTICAST_ENABLE
// #define QINQ_ENABLE
// #define QINQ_RIF_ENABLE
#define TUNNEL_ENABLE
#undef  VALIDATION_ENABLE
#define SHARED_ECMP_LAG_HASH_CALCULATION

// ----- npb: sfc -----
#define SFC_NSH_ENABLE
#undef  SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE // only valid if TRANSPORT_ENABLE is defined
#undef  SFC_TRANSPORT_NETSAP_TABLE_ENABLE        // only valid if TRANSPORT_ENABLE is defined
#undef  SFC_OUTER_TUNNEL_TABLE_ENABLE
#undef  SFC_TIMESTAMP_ENABLE                     // undef for sims, define for real chip

// ----- npb: sff -----
#undef  SFF_SCHD_SIMPLE                       // define for selecting simple tables, rather than action_selectors/action_profiles tables.
#define SFF_SCHD_COMPLEX_TYPE_ACTION_SELECTOR // define for action selector, undef for action_profile -- only used if _SIMPLE is undefined.
#undef  SFF_PREDECREMENTED_SI_ENABLE

// ----- npb: sf #0 -----
#undef  SF_0_L2_VLAN_ID_ENABLE
#define SF_0_L3_LEN_RNG_TABLE_ENABLE
#undef  SF_0_L3_LEN_RNG_TABLE_ENABLE_IN_ACL // only valid if above line is undefined
#define SF_0_L4_SRC_RNG_TABLE_ENABLE
#undef  SF_0_L4_SRC_RNG_TABLE_ENABLE_IN_ACL // only valid if above line is undefined
#define SF_0_L4_DST_RNG_TABLE_ENABLE
#undef  SF_0_L4_DST_RNG_TABLE_ENABLE_IN_ACL // only valid if above line is undefined
#undef  SF_0_ACL_SHARED_IP_ENABLE // will use a common table for ipv4 and ipv6
#undef  SF_0_ACL_INT_CTRL_FLAGS_ENABLE
#undef  SF_0_ALLOW_SCOPE_CHANGES
#undef  SF_0_DEDUP_ENABLE

// ----- npb: sf #2 -----
#undef  SF_2_L2_VLAN_ID_ENABLE
#define SF_2_L3_LEN_RNG_TABLE_ENABLE
#undef  SF_2_L3_LEN_RNG_TABLE_ENABLE_IN_ACL // only valid if above line is undefined
#define SF_2_L4_SRC_RNG_TABLE_ENABLE
#undef  SF_2_L4_SRC_RNG_TABLE_ENABLE_IN_ACL // only valid if above line is undefined
#define SF_2_L4_DST_RNG_TABLE_ENABLE
#undef  SF_2_L4_DST_RNG_TABLE_ENABLE_IN_ACL // only valid if above line is undefined
#undef  SF_2_ACL_SHARED_IP_ENABLE // will use a common table for ipv4 and ipv6
#undef  SF_2_ACL_INT_CTRL_FLAGS_ENABLE
#define SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
#undef  SF_2_EDIT_BD_TO_VID_TABLE_ENABLE
#undef  SF_2_METER_ENABLE
#undef  SF_2_DEDUP_ENABLE

// ----- tofino 1 fitting -----
#undef  BRIDGING_ENABLE // define for simultaneous switch and npb functionality (undefine for npb only)
#define TRANSPORT_ENABLE
#undef  INGRESS_TERMINATE_OUTER_ENABLE
#undef  INGRESS_TERMINATE_INNER_ENABLE // only valid if INGRESS_TERMINATE_OUTER_ENABLE defined

// ----- debug and miscellaneous -----
#undef  ING_STUBBED_OUT        // define to stub out the vast majority of the ingress MAU - for debug
#undef  EGR_STUBBED_OUT        // define to stub out the vast majority of the egress MAU - for debug
#define ING_HDR_STACK_COUNTERS // define to include per header-stack counters (for debug - currently used by parser tests)

// ----- bug fixes -----
#define BUG_09719_WORKAROUND // saturating subtracts -- feature is broken
#undef  BUG_10933_WORKAROUND // compiler bug when trying to set outer.ethernet.ether_type in parser (fixed in v9.2.0)
#undef  BUG_11507_WORKAROUND // rewrite bypass
#undef  BUG_11583_WORKAROUND // cpu header etype -- we need this fixed, there is no real workaround!

// ----- other wanted / needed features that don't fit -----
#undef  CPU_TX_BYPASS_ENABLE                  // this feature currently doesn't fit
#undef  CPU_IG_BYPASS_ENABLE                  // this feature currently doesn't fit
#undef  MULTICAST_INGRESS_RID_ENABLE          // this feature currently doesn't fit
#undef  LAG_HASH_MASKING_ENABLE               // this feature currently doesn't fit
#undef  LAG_HASH_IN_NSH_HDR_ENABLE            // this feature currently doesn't fit
#define FIELD_WIDTHS_REDUCED                  // to help w/ fitting
#undef  FIX_L3_TUN_ALL_AT_ONCE	              // method #1 to try to get inner-inner l3 tunnel decaps to fit
#undef  FIX_L3_TUN_LYR_BY_LYR	              // method #2 to try to get inner-inner l3 tunnel decaps to fit
