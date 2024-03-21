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

#ifndef _P4_TABLE_SIZE_
#define _P4_TABLE_SIZE_

// --------------------------------------------

#define MIN_SRAM_TABLE_SIZE 1024
#define MIN_TCAM_TABLE_SIZE 512

// --------------------------------------------

const bit<32> PORT_TABLE_SIZE                = 256;

// 4K L2 vlans
const bit<32> VLAN_TABLE_SIZE                = 4096;

// 1K (port, vlan) <--> BD
const bit<32> PORT_VLAN_TABLE_SIZE           = 1024;

// 5K BDs
const bit<32> BD_TABLE_SIZE                  = 5120;

// IP Hosts/Routes
const bit<32> RMAC_TABLE_SIZE                = 64;

// 16K MACs
#if __TARGET_TOFINO__ == 2
const bit<32> MAC_TABLE_SIZE                 = 1024;
#else
const bit<32> MAC_TABLE_SIZE                 = MIN_SRAM_TABLE_SIZE;
#endif

// Tunnels - 4K IPv4 + 1K IPv6
const bit<32> IPV4_DST_TUNNEL_TABLE_SIZE     = 64;   // ingress
const bit<32> IPV4_SRC_TUNNEL_TABLE_SIZE     = 256;  // ingress
const bit<32> IPV6_DST_TUNNEL_TABLE_SIZE     = 64;   // ingress
const bit<32> IPV6_SRC_TUNNEL_TABLE_SIZE     = 256;  // ingress

const bit<32> TUNNEL_SRC_REWRITE_TABLE_SIZE  = 512;  // egress
const bit<32> TUNNEL_DST_REWRITE_TABLE_SIZE  = 1024; // egress
const bit<32> TUNNEL_SMAC_REWRITE_TABLE_SIZE = 32;   // egress
const bit<32> TUNNEL_DMAC_REWRITE_TABLE_SIZE = 256;  // egress

// ECMP/Nexthop
#if __TARGET_TOFINO__ == 2
const bit<32> NEXTHOP_TABLE_SIZE             = 8192;
#else
const bit<32> NEXTHOP_TABLE_SIZE             = MIN_SRAM_TABLE_SIZE;
#endif
const bit<32> ECMP_GROUP_TABLE_SIZE          = 1024;  // derek: unused; removed this table
const bit<32> ECMP_SELECT_TABLE_SIZE         = 16384; // derek: unused; removed this table

// ECMP/Nexthop
const bit<32> OUTER_NEXTHOP_TABLE_SIZE       = 4096;  // aka NUM_TUNNELS
const bit<32> OUTER_ECMP_GROUP_TABLE_SIZE    = 4096;  // derek: unused in switch.p4
const bit<32> OUTER_ECMP_SELECT_TABLE_SIZE   = 16384; // derek: unused; changed table type to normal table

// Lag
const bit<32> LAG_GROUP_TABLE_SIZE           = 1024;
const bit<32> LAG_SELECT_TABLE_SIZE          = 256;

// Ingress ACLs
#if __TARGET_TOFINO__ == 2
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE     = 2048;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE    = 4096; // derek: ideally this should be 8192
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE    = 2048;
const bit<32> INGRESS_L7_ACL_TABLE_SIZE      = 1024;
#else
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE     = MIN_TCAM_TABLE_SIZE;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE    = MIN_TCAM_TABLE_SIZE;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE    = MIN_TCAM_TABLE_SIZE;
const bit<32> INGRESS_L7_ACL_TABLE_SIZE      = MIN_TCAM_TABLE_SIZE;
#endif

// Egress ACL
#if __TARGET_TOFINO__ == 2
const bit<32> EGRESS_MAC_ACL_TABLE_SIZE      = 128;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE     = 128;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE     = 128;
#else
const bit<32> EGRESS_MAC_ACL_TABLE_SIZE      = MIN_TCAM_TABLE_SIZE;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE     = MIN_TCAM_TABLE_SIZE;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE     = MIN_TCAM_TABLE_SIZE;
#endif

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Extreme Networks - Added
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

#if __TARGET_TOFINO__ == 1

// ----------------
// *** tofino 1 ***
// ----------------

// net intf

// sfc -- classifies non-nsh packets
const bit<32> NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH             = MIN_SRAM_TABLE_SIZE;
const bit<32> NPB_ING_SFC_TUNNEL_OUTER_TCAM_TABLE_DEPTH            = MIN_TCAM_TABLE_SIZE;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_EXM_TABLE_DEPTH             = MIN_SRAM_TABLE_SIZE;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH            = MIN_TCAM_TABLE_SIZE;
const bit<32> NPB_ING_SFC_NET_SAP_TABLE_DEPTH                      = MIN_SRAM_TABLE_SIZE;
const bit<32> NPB_ING_SFC_SF_SEL_TABLE_DEPTH                       = MIN_SRAM_TABLE_SIZE; // derek, what size to make this?

// sf #0 -- basic / advanced
const bit<32> NPB_ING_SF_0_BAS_ADV_ACT_SEL_TABLE_DEPTH             = MIN_SRAM_TABLE_SIZE;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_LEN_RNG_TABLE_DEPTH      = MIN_TCAM_TABLE_SIZE;

// sff -- forwards the packets to the sf's, then forwards to the packet along the chain.
const bit<32> NPB_ING_SFF_FLW_CLS_TABLE_DEPTH                      = MIN_SRAM_TABLE_SIZE;
const bit<32> NPB_ING_SFF_SCHD_TABLE_PART1_DEPTH                   = MIN_TCAM_TABLE_SIZE; // action selector group
const bit<32> NPB_ING_SFF_SCHD_TABLE_PART2_DEPTH                   = MIN_SRAM_TABLE_SIZE; // action selector select
const bit<32> NPB_ING_SFF_ARP_TABLE_DEPTH                          = MIN_SRAM_TABLE_SIZE;

// sf #1 -- replication
const bit<32> NPB_ING_SF_1_MULTICAST_ACT_SEL_TABLE_DEPTH           = MIN_SRAM_TABLE_SIZE;
const bit<32> NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE                = MIN_SRAM_TABLE_SIZE;

// sf #2 -- tool proxy
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_ACT_SEL_TABLE_DEPTH          = MIN_SRAM_TABLE_SIZE;
#define       NPB_EGR_SF_2_EGRESS_SFP_ACT_SEL_TABLE_DEPTH_POW2       10                   // unused in latest spec
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_LEN_RNG_TABLE_DEPTH   = MIN_SRAM_TABLE_SIZE;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_HDR_STRIP_TABLE_DEPTH        = MIN_TCAM_TABLE_SIZE; // unused in latest spec
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_TRUNC_TABLE_DEPTH            = MIN_TCAM_TABLE_SIZE; // unused in latest spec

#else

// ----------------
// *** tofino 2 ***
// ----------------

// net intf

// sfc -- classifies non-nsh packets
const bit<32> NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH             = 8192;
const bit<32> NPB_ING_SFC_TUNNEL_OUTER_TCAM_TABLE_DEPTH            = 256;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_EXM_TABLE_DEPTH             = 8192;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH            = 256;
const bit<32> NPB_ING_SFC_NET_SAP_TABLE_DEPTH                      = 8192;
const bit<32> NPB_ING_SFC_SF_SEL_TABLE_DEPTH                       = 8192; // derek, what size to make this?

// sf #0 -- basic / advanced
const bit<32> NPB_ING_SF_0_BAS_ADV_ACT_SEL_TABLE_DEPTH             = 1024;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_LEN_RNG_TABLE_DEPTH      = 128;

// sff -- forwards the packets to the sf's, then forwards to the packet along the chain.
const bit<32> NPB_ING_SFF_FLW_CLS_TABLE_DEPTH                      = 128;
const bit<32> NPB_ING_SFF_SCHD_TABLE_PART1_DEPTH                   = 64;   // action selector group
const bit<32> NPB_ING_SFF_SCHD_TABLE_PART2_DEPTH                   = 1024; // action selector select
const bit<32> NPB_ING_SFF_ARP_TABLE_DEPTH                          = 8192;

// sf #1 -- replication
const bit<32> NPB_ING_SF_1_MULTICAST_ACT_SEL_TABLE_DEPTH           = 1024;
const bit<32> NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE                = 2096;

// sf #2 -- tool proxy
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_ACT_SEL_TABLE_DEPTH          = 8192;
#define       NPB_EGR_SF_2_EGRESS_SFP_ACT_SEL_TABLE_DEPTH_POW2       10 // unused in latest spec
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_LEN_RNG_TABLE_DEPTH   = 128;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_HDR_STRIP_TABLE_DEPTH        = 8; // unused in latest spec
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_TRUNC_TABLE_DEPTH            = 8; // unused in latest spec

#endif

#endif /* _P4_TABLE_SIZE_ */
