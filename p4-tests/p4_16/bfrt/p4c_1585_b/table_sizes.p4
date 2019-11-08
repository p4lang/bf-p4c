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

#ifndef _P4_TABLE_SIZE_
#define _P4_TABLE_SIZE_

const bit<32> PORT_TABLE_SIZE = 288 * 2;

// 4K L2 vlans
const bit<32> VLAN_TABLE_SIZE = 4096;
const bit<32> BD_FLOOD_TABLE_SIZE = VLAN_TABLE_SIZE * 4;

// 1K (port, vlan) <--> BD
const bit<32> PORT_VLAN_TABLE_SIZE = 1024;

// 4K (port, vlan[0], vlan[1]) <--> BD
const bit<32> DOUBLE_TAG_TABLE_SIZE = 4096;

// 5K BDs
const bit<32> BD_TABLE_SIZE = 5120;

// 16K MACs
#if __TARGET_TOFINO__ == 2
const bit<32> MAC_TABLE_SIZE = 65536;
#else
const bit<32> MAC_TABLE_SIZE = 16384;
#endif

#if __TARGET_TOFINO__ == 2
// IP Hosts/Routes
const bit<32> IPV4_LPM_TABLE_SIZE = 131072;
const bit<32> IPV6_LPM_TABLE_SIZE = 32768;
const bit<32> IPV4_HOST_TABLE_SIZE = 65536;
const bit<32> IPV6_HOST_TABLE_SIZE = 65536;
// Multicast
const bit<32> IPV4_MULTICAST_STAR_G_TABLE_SIZE = 2048;
const bit<32> IPV4_MULTICAST_S_G_TABLE_SIZE = 8192;
const bit<32> IPV6_MULTICAST_STAR_G_TABLE_SIZE = 1024;
const bit<32> IPV6_MULTICAST_S_G_TABLE_SIZE = 1024;
const bit<32> RID_TABLE_SIZE = 32768;
#else
// IP Hosts/Routes
const bit<32> IPV4_LPM_TABLE_SIZE = 16384;
const bit<32> IPV6_LPM_TABLE_SIZE = 8192;
const bit<32> IPV4_HOST_TABLE_SIZE = 32768;
const bit<32> IPV6_HOST_TABLE_SIZE = 16384;
// Multicast
const bit<32> IPV4_MULTICAST_STAR_G_TABLE_SIZE = 2048;
const bit<32> IPV4_MULTICAST_S_G_TABLE_SIZE = 4096;
const bit<32> IPV6_MULTICAST_STAR_G_TABLE_SIZE = 512;
const bit<32> IPV6_MULTICAST_S_G_TABLE_SIZE = 512;
const bit<32> RID_TABLE_SIZE = 4096;
#endif

// Tunnels - 4K IPv4 + 1K IPv6
const bit<32> DEST_TUNNEL_TABLE_SIZE = 512;
const bit<32> IPV4_SRC_TUNNEL_TABLE_SIZE = 4096;
const bit<32> IPV6_SRC_TUNNEL_TABLE_SIZE = 1024;
const bit<32> VNI_MAPPING_TABLE_SIZE = 4096;
const bit<32> TUNNEL_SRC_REWRITE_TABLE_SIZE = 512;
const bit<32> TUNNEL_DST_REWRITE_TABLE_SIZE = 4096;
const bit<32> TUNNEL_SMAC_REWRITE_TABLE_SIZE = 512;
const bit<32> TUNNEL_DMAC_REWRITE_TABLE_SIZE = 4096;
const bit<32> TUNNEL_REWRITE_TABLE_SIZE = 512;

// ECMP/Nexthop
const bit<32> ECMP_GROUP_TABLE_SIZE = 1024;
const bit<32> OUTER_ECMP_GROUP_TABLE_SIZE = 4096;
const bit<32> ECMP_SELECT_TABLE_SIZE = 16384;
#if __TARGET_TOFINO__ == 2
const bit<32> NEXTHOP_TABLE_SIZE = 65536;
#else
const bit<32> NEXTHOP_TABLE_SIZE = 32768;
#endif
const bit<32> OUTER_NEXTHOP_TABLE_SIZE = 4096;

// Ingress ACLs
#if __TARGET_TOFINO__ == 2
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 4096;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 1024;
const bit<32> INGRESS_MIRROR_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_MAC_QOS_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_QOS_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV6_QOS_ACL_TABLE_SIZE = 512;

const bit<32> INGRESS_L4_PORT_LOU_TABLE_SIZE = switch_l4_port_label_width / 2;

const bit<32> IPV4_RACL_TABLE_SIZE = 512;
const bit<32> IPV6_RACL_TABLE_SIZE = 512;
const bit<32> RACL_STATS_TABLE_SIZE = 1024;

#else
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_MIRROR_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_MAC_QOS_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_QOS_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV6_QOS_ACL_TABLE_SIZE = 512;

const bit<32> INGRESS_L4_PORT_LOU_TABLE_SIZE = switch_l4_port_label_width / 2;

const bit<32> IPV4_RACL_TABLE_SIZE = 1024;
const bit<32> IPV6_RACL_TABLE_SIZE = 512;
const bit<32> RACL_STATS_TABLE_SIZE = 2048;
#endif

// Egress ACL
const bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512;

// WRED
const bit<32> WRED_SIZE = 1 << switch_wred_index_width;

// COPP
const bit<32> COPP_METER_SIZE = 1 << switch_copp_meter_id_width;
const bit<32> COPP_DROP_TABLE_SIZE = 1 << (switch_copp_meter_id_width + 1);

// QoS
const bit<32> DSCP_TO_TC_TABLE_SIZE = 1024;
const bit<32> PCP_TO_TC_TABLE_SIZE = 1024;
const bit<32> QUEUE_TABLE_SIZE = 1024;
const bit<32> EGRESS_QOS_MAP_TABLE_SIZE = 1024;

// Policer
const bit<32> INGRESS_POLICER_TABLE_SIZE = 1 << switch_policer_meter_index_width;

// Storm Control
const bit<32> STORM_CONTROL_TABLE_SIZE = 512;

// System ACL
const bit<32> INGRESS_SYSTEM_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_SYSTEM_ACL_TABLE_SIZE = 512;
const bit<32> DROP_STATS_TABLE_SIZE = 1 << switch_drop_reason_width;

const bit<32> L3_MTU_TABLE_SIZE = 1024;

// -----------------------------
// Extreme Networks Additions
// -----------------------------

#define MIN_SRAM_TABLE_SIZE 1024
#define MIN_TCAM_TABLE_SIZE 512

// net intf

// sfc -- classifies non-nsh packets
const bit<32> NPB_ING_SFC_FLOW_TYPE_TABLE_DEPTH                    = MIN_SRAM_TABLE_SIZE;
const bit<32> NPB_ING_SFC_NSH_TABLE_DEPTH                          = MIN_SRAM_TABLE_SIZE;
const bit<32> NPB_ING_SFC_SCHD_TABLE_PART1_DEPTH                   = MIN_SRAM_TABLE_SIZE;
const bit<32> NPB_ING_SFC_SCHD_TABLE_PART2_DEPTH                   = MIN_SRAM_TABLE_SIZE;

// sff -- forwards the packets to the sf's, then forwards to the packet along the chain.
const bit<32> NPB_ING_SFF_TABLE_DEPTH                              = MIN_SRAM_TABLE_SIZE;

// sf #1 -- basic / advanced
const bit<32> NPB_ING_SF_BAS_ADV_POLICY_V4_EXACT_MATCH_TABLE_DEPTH = MIN_SRAM_TABLE_SIZE;
const bit<32> NPB_ING_SF_BAS_ADV_POLICY_V4_LPM_TABLE_DEPTH         = MIN_TCAM_TABLE_SIZE;
const bit<32> NPB_ING_SF_BAS_ADV_POLICY_V6_EXACT_MATCH_TABLE_DEPTH = MIN_SRAM_TABLE_SIZE;
const bit<32> NPB_ING_SF_BAS_ADV_POLICY_V6_LPM_TABLE_DEPTH         = MIN_TCAM_TABLE_SIZE;
const bit<32> NPB_ING_SF_BAS_ADV_SCHD_TABLE_PART1_DEPTH            = MIN_SRAM_TABLE_SIZE;
const bit<32> NPB_ING_SF_BAS_ADV_SCHD_TABLE_PART2_DEPTH            = MIN_SRAM_TABLE_SIZE;

// sf #2 -- replication

// sf #3 -- tool proxy
const bit<32> NPB_EGR_SF_EGRESS_SFP_TABLE_DEPTH                    = MIN_SRAM_TABLE_SIZE;
#define       NPB_EGR_SF_EGRESS_SFP_TABLE_DEPTH_POW2                 10

#endif /* _P4_TABLE_SIZE_ */
