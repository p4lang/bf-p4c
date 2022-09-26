// Copyright 2020-2021 Extreme Networks, Inc.
// All rights reserved.

// This file is auto-generated via /npb-dp/p4_pipelines/cls/pipeline.py
#ifndef _DEPLOYMENT_PARAMS_PIPELINE_NPB_
#define _DEPLOYMENT_PARAMS_PIPELINE_NPB_

// Use this #define within your modules to declare
// the list of deployment parameters being passed in
// from above.
#define MODULE_DEPLOYMENT_PARAMS \
bool OUTER_IPV6_ENABLE = true, \
bool INNER_IPV6_ENABLE = true, \
bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, \
bool OUTER_IPoMPLS_ENABLE = false, \
bool OUTER_MPLSoGRE_ENABLE = false, \
bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, \
bool OUTER_IPINIP_ENABLE = true, \
bool OUTER_VNTAG_ENABLE = true, \
bool TRANSPORT_IPV4_VXLAN_INGRESS_ENABLE = true, \
bool UDF_ENABLE = false, \
bool INNER_IPINIP_ENABLE = true, \
bool OUTER_GRE_ENABLE = true, \
bool TRANSPORT_GRE_INGRESS_ENABLE = true, \
bool OUTER_EoMPLS_ENABLE = false, \
bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, \
bool TRANSPORT_IPV6_REDUCED_ADDR = true, \
bool OUTER_ETAG_ENABLE = true, \
bool EGRESS_ENABLE = true, \
bool OUTER_GENEVE_ENABLE = false, \
bool INGRESS_ENABLE = true, \
bool TRANSPORT_GRE_EGRESS_ENABLE = true, \
bool INNER_GTP_ENABLE = true, \
bool OUTER_EoMPLS_PWCW_ENABLE = false, \
bool TRANSPORT_SPBM_INGRESS_ENABLE = true, \
bool TRANSPORT_EoMPLS_INGRESS_ENABLE = true, \
bool TRANSPORT_IPV4_INGRESS_ENABLE = true, \
bool OUTER_NVGRE_ENABLE = true, \
bool INNER_GRE_ENABLE = true, \
bool FOLDED_ENABLE = false, \
bool TRANSPORT_EGRESS_ENABLE = true, \
bool OUTER_VXLAN_ENABLE = true, \
bool INNER_INNER_IPV6_ENABLE = true, \
bool TRANSPORT_IPV4_GENEVE_INGRESS_ENABLE = false, \
bool TRANSPORT_IPV6_EGRESS_ENABLE = true, \
bool TRANSPORT_IPV6_INGRESS_ENABLE = true, \
bool TRANSPORT_INGRESS_ENABLE = true, \
bool OUTER_GTP_ENABLE = true, \
bool TRANSPORT_IPV4_EGRESS_ENABLE = true, \
bit<32> PORT_TABLE_SIZE = 288, \
bit<32> OUTER_NEXTHOP_TABLE_SIZE = 4096, \
bit<32> NEXTHOP_TABLE_SIZE = 8192, \
bit<32> LAG_SELECTOR_TABLE_SIZE = 2048, \
bit<32> NPB_ING_SFC_TUNNEL_NETWORK_SAP_TABLE_DEPTH = 8192, \
bit<32> PORT_VLAN_TABLE_SIZE = 1024, \
bit<32> IPV6_DST_TUNNEL_TABLE_SIZE = 1024, \
bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, \
bit<32> NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE = 2096, \
bit<32> NPB_EGR_SF_2_EGRESS_SFP_HDR_STRIP_TABLE_DEPTH = 8, \
bit<32> LAG_GROUP_TABLE_SIZE = 32, \
bit<32> LAG_TABLE_SIZE = 1024, \
bit<32> DTEL_MAX_MEMBERS_PER_GROUP = 64, \
bit<32> NPB_EGR_SF_2_EGRESS_SFP_SFF_TABLE_DEPTH = 8192, \
bit<32> DEDUP_ADDR_WIDTH = 16, \
bit<32> NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH = 8192, \
bit<32> NPB_ING_SF_0_SFP_SCHD_SELECTOR_TABLE_SIZE = 16384, \
bit<32> TUNNEL_SMAC_REWRITE_TABLE_SIZE = 32, \
bit<32> TUNNEL_DST_REWRITE_TABLE_SIZE = 1024, \
bit<32> RMAC_TABLE_SIZE = 64, \
bit<32> NPB_ING_SF_0_SFP_SCHD_MAX_MEMBERS_PER_GROUP = 128, \
bit<32> ECMP_GROUP_TABLE_SIZE = 1024, \
bit<32> NPB_ING_SF_0_SFP_FLW_CLS_TABLE_DEPTH = 128, \
bit<32> NPB_ING_SFF_ARP_TABLE_DEPTH = 8192, \
bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_L3_LEN_RNG_TABLE_DEPTH = 128, \
bit<32> NPB_ING_SFC_SF_SEL_TABLE_DEPTH = 8192, \
bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536, \
bit<32> DEDUP_NUM_BLOCKS = 16, \
bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, \
bit<32> INGRESS_IP_DTEL_ACL_TABLE_SIZE = 512, \
bit<32> NPB_EGR_SFF_ARP_TABLE_DEPTH = 8192, \
bit<32> MPLS_DEPTH_TRANSPORT = 4, \
bit<32> NPB_ING_SF_0_SFP_SCHD_GROUP_TABLE_SIZE = 128, \
bit<32> TUNNEL_DMAC_REWRITE_TABLE_SIZE = 256, \
bit<32> BD_TABLE_SIZE = 5120, \
bit<32> IPV4_SRC_TUNNEL_TABLE_SIZE = 256, \
bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L4_DST_RNG_TABLE_DEPTH = 256, \
bit<32> DTEL_GROUP_TABLE_SIZE = 4, \
bit<32> NPB_ING_SFC_TUNNEL_INNER_EXM_TABLE_DEPTH = 8192, \
bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L3_LEN_RNG_TABLE_DEPTH = 128, \
bit<32> NPB_ING_SF_0_BAS_ADV_SFF_TABLE_DEPTH = 1024, \
bit<32> MPLS_DEPTH_OUTER = 4, \
bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, \
bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, \
bit<32> NPB_ING_SF_1_MULTICAST_SFF_TABLE_DEPTH = 1024, \
bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, \
bit<32> NPB_EGR_SF_2_EGRESS_SFP_TRUNC_TABLE_DEPTH = 8, \
bit<32> NPB_ING_SFC_TUNNEL_OUTER_TCAM_TABLE_DEPTH = 1024, \
bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_DST_RNG_TABLE_DEPTH = 256, \
bit<32> OUTER_ECMP_GROUP_TABLE_SIZE = 4096, \
bit<32> TUNNEL_SRC_REWRITE_TABLE_SIZE = 512, \
bit<32> MAC_TABLE_SIZE = 1024, \
bit<32> NPB_ING_SF_0_SFP_SCHD_TABLE_SIZE = 8192, \
bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, \
bit<32> ECMP_SELECT_TABLE_SIZE = 16384, \
bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, \
bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, \
bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_SRC_RNG_TABLE_DEPTH = 256, \
bit<32> OUTER_ECMP_SELECT_TABLE_SIZE = 16384, \
bit<32> LAG_MAX_MEMBERS_PER_GROUP = 64, \
bit<32> VLAN_TABLE_SIZE = 4096, \
bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L4_SRC_RNG_TABLE_DEPTH = 256, \
bit<32> IPV6_SRC_TUNNEL_TABLE_SIZE = 256, \
bit<32> NPB_ING_SFC_SF_SEL_NSH_XLATE_TABLE_DEPTH = 8192, \
bit<32> DTEL_SELECTOR_TABLE_SIZE = 256

// Use this #define within your modules to declare
// the list of deployment parameters being passed down
// to sub-module instances.
#define INSTANCE_DEPLOYMENT_PARAMS \
OUTER_IPV6_ENABLE, \
INNER_IPV6_ENABLE, \
TRANSPORT_ERSPAN_EGRESS_ENABLE, \
OUTER_IPoMPLS_ENABLE, \
OUTER_MPLSoGRE_ENABLE, \
TRANSPORT_ERSPAN_INGRESS_ENABLE, \
OUTER_IPINIP_ENABLE, \
OUTER_VNTAG_ENABLE, \
TRANSPORT_IPV4_VXLAN_INGRESS_ENABLE, \
UDF_ENABLE, \
INNER_IPINIP_ENABLE, \
OUTER_GRE_ENABLE, \
TRANSPORT_GRE_INGRESS_ENABLE, \
OUTER_EoMPLS_ENABLE, \
TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, \
TRANSPORT_IPV6_REDUCED_ADDR, \
OUTER_ETAG_ENABLE, \
EGRESS_ENABLE, \
OUTER_GENEVE_ENABLE, \
INGRESS_ENABLE, \
TRANSPORT_GRE_EGRESS_ENABLE, \
INNER_GTP_ENABLE, \
OUTER_EoMPLS_PWCW_ENABLE, \
TRANSPORT_SPBM_INGRESS_ENABLE, \
TRANSPORT_EoMPLS_INGRESS_ENABLE, \
TRANSPORT_IPV4_INGRESS_ENABLE, \
OUTER_NVGRE_ENABLE, \
INNER_GRE_ENABLE, \
FOLDED_ENABLE, \
TRANSPORT_EGRESS_ENABLE, \
OUTER_VXLAN_ENABLE, \
INNER_INNER_IPV6_ENABLE, \
TRANSPORT_IPV4_GENEVE_INGRESS_ENABLE, \
TRANSPORT_IPV6_EGRESS_ENABLE, \
TRANSPORT_IPV6_INGRESS_ENABLE, \
TRANSPORT_INGRESS_ENABLE, \
OUTER_GTP_ENABLE, \
TRANSPORT_IPV4_EGRESS_ENABLE, \
PORT_TABLE_SIZE, \
OUTER_NEXTHOP_TABLE_SIZE, \
NEXTHOP_TABLE_SIZE, \
LAG_SELECTOR_TABLE_SIZE, \
NPB_ING_SFC_TUNNEL_NETWORK_SAP_TABLE_DEPTH, \
PORT_VLAN_TABLE_SIZE, \
IPV6_DST_TUNNEL_TABLE_SIZE, \
INGRESS_IPV4_ACL_TABLE_SIZE, \
NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE, \
NPB_EGR_SF_2_EGRESS_SFP_HDR_STRIP_TABLE_DEPTH, \
LAG_GROUP_TABLE_SIZE, \
LAG_TABLE_SIZE, \
DTEL_MAX_MEMBERS_PER_GROUP, \
NPB_EGR_SF_2_EGRESS_SFP_SFF_TABLE_DEPTH, \
DEDUP_ADDR_WIDTH, \
NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH, \
NPB_ING_SF_0_SFP_SCHD_SELECTOR_TABLE_SIZE, \
TUNNEL_SMAC_REWRITE_TABLE_SIZE, \
TUNNEL_DST_REWRITE_TABLE_SIZE, \
RMAC_TABLE_SIZE, \
NPB_ING_SF_0_SFP_SCHD_MAX_MEMBERS_PER_GROUP, \
ECMP_GROUP_TABLE_SIZE, \
NPB_ING_SF_0_SFP_FLW_CLS_TABLE_DEPTH, \
NPB_ING_SFF_ARP_TABLE_DEPTH, \
NPB_EGR_SF_2_EGRESS_SFP_POLICY_L3_LEN_RNG_TABLE_DEPTH, \
NPB_ING_SFC_SF_SEL_TABLE_DEPTH, \
INGRESS_MAC_ACL_TABLE_SIZE, \
DEDUP_NUM_BLOCKS, \
IPV4_DST_TUNNEL_TABLE_SIZE, \
INGRESS_IP_DTEL_ACL_TABLE_SIZE, \
NPB_EGR_SFF_ARP_TABLE_DEPTH, \
MPLS_DEPTH_TRANSPORT, \
NPB_ING_SF_0_SFP_SCHD_GROUP_TABLE_SIZE, \
TUNNEL_DMAC_REWRITE_TABLE_SIZE, \
BD_TABLE_SIZE, \
IPV4_SRC_TUNNEL_TABLE_SIZE, \
NPB_ING_SF_0_BAS_ADV_POLICY_L4_DST_RNG_TABLE_DEPTH, \
DTEL_GROUP_TABLE_SIZE, \
NPB_ING_SFC_TUNNEL_INNER_EXM_TABLE_DEPTH, \
NPB_ING_SF_0_BAS_ADV_POLICY_L3_LEN_RNG_TABLE_DEPTH, \
NPB_ING_SF_0_BAS_ADV_SFF_TABLE_DEPTH, \
MPLS_DEPTH_OUTER, \
EGRESS_MAC_ACL_TABLE_SIZE, \
INGRESS_IPV6_ACL_TABLE_SIZE, \
NPB_ING_SF_1_MULTICAST_SFF_TABLE_DEPTH, \
EGRESS_IPV4_ACL_TABLE_SIZE, \
NPB_EGR_SF_2_EGRESS_SFP_TRUNC_TABLE_DEPTH, \
NPB_ING_SFC_TUNNEL_OUTER_TCAM_TABLE_DEPTH, \
NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_DST_RNG_TABLE_DEPTH, \
OUTER_ECMP_GROUP_TABLE_SIZE, \
TUNNEL_SRC_REWRITE_TABLE_SIZE, \
MAC_TABLE_SIZE, \
NPB_ING_SF_0_SFP_SCHD_TABLE_SIZE, \
EGRESS_IPV6_ACL_TABLE_SIZE, \
ECMP_SELECT_TABLE_SIZE, \
NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, \
INGRESS_L7_ACL_TABLE_SIZE, \
NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_SRC_RNG_TABLE_DEPTH, \
OUTER_ECMP_SELECT_TABLE_SIZE, \
LAG_MAX_MEMBERS_PER_GROUP, \
VLAN_TABLE_SIZE, \
NPB_ING_SF_0_BAS_ADV_POLICY_L4_SRC_RNG_TABLE_DEPTH, \
IPV6_SRC_TUNNEL_TABLE_SIZE, \
NPB_ING_SFC_SF_SEL_NSH_XLATE_TABLE_DEPTH, \
DTEL_SELECTOR_TABLE_SIZE 

// Deployment Profile: vcpFw
// -----------------------------------------------

const bool OUTER_IPV6_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool INNER_IPV6_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool TRANSPORT_ERSPAN_EGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool OUTER_IPoMPLS_ENABLE_PIPELINE_NPB_VCPFW = false;
const bool OUTER_MPLSoGRE_ENABLE_PIPELINE_NPB_VCPFW = false;
const bool TRANSPORT_ERSPAN_INGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool OUTER_IPINIP_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool OUTER_VNTAG_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool TRANSPORT_IPV4_VXLAN_INGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool UDF_ENABLE_PIPELINE_NPB_VCPFW = false;
const bool INNER_IPINIP_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool OUTER_GRE_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool TRANSPORT_GRE_INGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool OUTER_EoMPLS_ENABLE_PIPELINE_NPB_VCPFW = false;
const bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID_PIPELINE_NPB_VCPFW = false;
const bool TRANSPORT_IPV6_REDUCED_ADDR_PIPELINE_NPB_VCPFW = true;
const bool OUTER_ETAG_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool EGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool OUTER_GENEVE_ENABLE_PIPELINE_NPB_VCPFW = false;
const bool INGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool TRANSPORT_GRE_EGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool INNER_GTP_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool OUTER_EoMPLS_PWCW_ENABLE_PIPELINE_NPB_VCPFW = false;
const bool TRANSPORT_SPBM_INGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool TRANSPORT_EoMPLS_INGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool TRANSPORT_IPV4_INGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool OUTER_NVGRE_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool INNER_GRE_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool FOLDED_ENABLE_PIPELINE_NPB_VCPFW = false;
const bool TRANSPORT_EGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool OUTER_VXLAN_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool INNER_INNER_IPV6_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool TRANSPORT_IPV4_GENEVE_INGRESS_ENABLE_PIPELINE_NPB_VCPFW = false;
const bool TRANSPORT_IPV6_EGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool TRANSPORT_IPV6_INGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool TRANSPORT_INGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool OUTER_GTP_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool TRANSPORT_IPV4_EGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bit<32> PORT_TABLE_SIZE_PIPELINE_NPB_VCPFW = 288;
const bit<32> OUTER_NEXTHOP_TABLE_SIZE_PIPELINE_NPB_VCPFW = 4096;
const bit<32> NEXTHOP_TABLE_SIZE_PIPELINE_NPB_VCPFW = 8192;
const bit<32> LAG_SELECTOR_TABLE_SIZE_PIPELINE_NPB_VCPFW = 2048;
const bit<32> NPB_ING_SFC_TUNNEL_NETWORK_SAP_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 8192;
const bit<32> PORT_VLAN_TABLE_SIZE_PIPELINE_NPB_VCPFW = 1024;
const bit<32> IPV6_DST_TUNNEL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 1024;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 6144;
const bit<32> NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE_PIPELINE_NPB_VCPFW = 2096;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_HDR_STRIP_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 8;
const bit<32> LAG_GROUP_TABLE_SIZE_PIPELINE_NPB_VCPFW = 32;
const bit<32> LAG_TABLE_SIZE_PIPELINE_NPB_VCPFW = 1024;
const bit<32> DTEL_MAX_MEMBERS_PER_GROUP_PIPELINE_NPB_VCPFW = 64;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_SFF_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 8192;
const bit<32> DEDUP_ADDR_WIDTH_PIPELINE_NPB_VCPFW = 16;
const bit<32> NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 8192;
const bit<32> NPB_ING_SF_0_SFP_SCHD_SELECTOR_TABLE_SIZE_PIPELINE_NPB_VCPFW = 16384;
const bit<32> TUNNEL_SMAC_REWRITE_TABLE_SIZE_PIPELINE_NPB_VCPFW = 32;
const bit<32> TUNNEL_DST_REWRITE_TABLE_SIZE_PIPELINE_NPB_VCPFW = 1024;
const bit<32> RMAC_TABLE_SIZE_PIPELINE_NPB_VCPFW = 64;
const bit<32> NPB_ING_SF_0_SFP_SCHD_MAX_MEMBERS_PER_GROUP_PIPELINE_NPB_VCPFW = 128;
const bit<32> ECMP_GROUP_TABLE_SIZE_PIPELINE_NPB_VCPFW = 1024;
const bit<32> NPB_ING_SF_0_SFP_FLW_CLS_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 128;
const bit<32> NPB_ING_SFF_ARP_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 8192;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_L3_LEN_RNG_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 128;
const bit<32> NPB_ING_SFC_SF_SEL_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 8192;
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 1536;
const bit<32> DEDUP_NUM_BLOCKS_PIPELINE_NPB_VCPFW = 16;
const bit<32> IPV4_DST_TUNNEL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 1024;
const bit<32> INGRESS_IP_DTEL_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 512;
const bit<32> NPB_EGR_SFF_ARP_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 8192;
const bit<32> MPLS_DEPTH_TRANSPORT_PIPELINE_NPB_VCPFW = 4;
const bit<32> NPB_ING_SF_0_SFP_SCHD_GROUP_TABLE_SIZE_PIPELINE_NPB_VCPFW = 128;
const bit<32> TUNNEL_DMAC_REWRITE_TABLE_SIZE_PIPELINE_NPB_VCPFW = 256;
const bit<32> BD_TABLE_SIZE_PIPELINE_NPB_VCPFW = 5120;
const bit<32> IPV4_SRC_TUNNEL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 256;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L4_DST_RNG_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 256;
const bit<32> DTEL_GROUP_TABLE_SIZE_PIPELINE_NPB_VCPFW = 4;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_EXM_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 8192;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L3_LEN_RNG_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 128;
const bit<32> NPB_ING_SF_0_BAS_ADV_SFF_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 1024;
const bit<32> MPLS_DEPTH_OUTER_PIPELINE_NPB_VCPFW = 4;
const bit<32> EGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 512;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 2048;
const bit<32> NPB_ING_SF_1_MULTICAST_SFF_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 1024;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 512;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_TRUNC_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 8;
const bit<32> NPB_ING_SFC_TUNNEL_OUTER_TCAM_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 1024;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_DST_RNG_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 256;
const bit<32> OUTER_ECMP_GROUP_TABLE_SIZE_PIPELINE_NPB_VCPFW = 4096;
const bit<32> TUNNEL_SRC_REWRITE_TABLE_SIZE_PIPELINE_NPB_VCPFW = 512;
const bit<32> MAC_TABLE_SIZE_PIPELINE_NPB_VCPFW = 1024;
const bit<32> NPB_ING_SF_0_SFP_SCHD_TABLE_SIZE_PIPELINE_NPB_VCPFW = 8192;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 512;
const bit<32> ECMP_SELECT_TABLE_SIZE_PIPELINE_NPB_VCPFW = 16384;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 2048;
const bit<32> INGRESS_L7_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 1024;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_SRC_RNG_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 256;
const bit<32> OUTER_ECMP_SELECT_TABLE_SIZE_PIPELINE_NPB_VCPFW = 16384;
const bit<32> LAG_MAX_MEMBERS_PER_GROUP_PIPELINE_NPB_VCPFW = 64;
const bit<32> VLAN_TABLE_SIZE_PIPELINE_NPB_VCPFW = 4096;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L4_SRC_RNG_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 256;
const bit<32> IPV6_SRC_TUNNEL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 256;
const bit<32> NPB_ING_SFC_SF_SEL_NSH_XLATE_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 8192;
const bit<32> DTEL_SELECTOR_TABLE_SIZE_PIPELINE_NPB_VCPFW = 256;

// Use this #define to pass the list of deployment
// params into your top-level module instantiations.
#define INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_VCPFW \
OUTER_IPV6_ENABLE_PIPELINE_NPB_VCPFW, \
INNER_IPV6_ENABLE_PIPELINE_NPB_VCPFW, \
TRANSPORT_ERSPAN_EGRESS_ENABLE_PIPELINE_NPB_VCPFW, \
OUTER_IPoMPLS_ENABLE_PIPELINE_NPB_VCPFW, \
OUTER_MPLSoGRE_ENABLE_PIPELINE_NPB_VCPFW, \
TRANSPORT_ERSPAN_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, \
OUTER_IPINIP_ENABLE_PIPELINE_NPB_VCPFW, \
OUTER_VNTAG_ENABLE_PIPELINE_NPB_VCPFW, \
TRANSPORT_IPV4_VXLAN_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, \
UDF_ENABLE_PIPELINE_NPB_VCPFW, \
INNER_IPINIP_ENABLE_PIPELINE_NPB_VCPFW, \
OUTER_GRE_ENABLE_PIPELINE_NPB_VCPFW, \
TRANSPORT_GRE_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, \
OUTER_EoMPLS_ENABLE_PIPELINE_NPB_VCPFW, \
TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID_PIPELINE_NPB_VCPFW, \
TRANSPORT_IPV6_REDUCED_ADDR_PIPELINE_NPB_VCPFW, \
OUTER_ETAG_ENABLE_PIPELINE_NPB_VCPFW, \
EGRESS_ENABLE_PIPELINE_NPB_VCPFW, \
OUTER_GENEVE_ENABLE_PIPELINE_NPB_VCPFW, \
INGRESS_ENABLE_PIPELINE_NPB_VCPFW, \
TRANSPORT_GRE_EGRESS_ENABLE_PIPELINE_NPB_VCPFW, \
INNER_GTP_ENABLE_PIPELINE_NPB_VCPFW, \
OUTER_EoMPLS_PWCW_ENABLE_PIPELINE_NPB_VCPFW, \
TRANSPORT_SPBM_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, \
TRANSPORT_EoMPLS_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, \
TRANSPORT_IPV4_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, \
OUTER_NVGRE_ENABLE_PIPELINE_NPB_VCPFW, \
INNER_GRE_ENABLE_PIPELINE_NPB_VCPFW, \
FOLDED_ENABLE_PIPELINE_NPB_VCPFW, \
TRANSPORT_EGRESS_ENABLE_PIPELINE_NPB_VCPFW, \
OUTER_VXLAN_ENABLE_PIPELINE_NPB_VCPFW, \
INNER_INNER_IPV6_ENABLE_PIPELINE_NPB_VCPFW, \
TRANSPORT_IPV4_GENEVE_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, \
TRANSPORT_IPV6_EGRESS_ENABLE_PIPELINE_NPB_VCPFW, \
TRANSPORT_IPV6_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, \
TRANSPORT_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, \
OUTER_GTP_ENABLE_PIPELINE_NPB_VCPFW, \
TRANSPORT_IPV4_EGRESS_ENABLE_PIPELINE_NPB_VCPFW, \
PORT_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
OUTER_NEXTHOP_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
NEXTHOP_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
LAG_SELECTOR_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
NPB_ING_SFC_TUNNEL_NETWORK_SAP_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
PORT_VLAN_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
IPV6_DST_TUNNEL_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
INGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
NPB_EGR_SF_2_EGRESS_SFP_HDR_STRIP_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
LAG_GROUP_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
LAG_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
DTEL_MAX_MEMBERS_PER_GROUP_PIPELINE_NPB_VCPFW, \
NPB_EGR_SF_2_EGRESS_SFP_SFF_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
DEDUP_ADDR_WIDTH_PIPELINE_NPB_VCPFW, \
NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
NPB_ING_SF_0_SFP_SCHD_SELECTOR_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
TUNNEL_SMAC_REWRITE_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
TUNNEL_DST_REWRITE_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
RMAC_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
NPB_ING_SF_0_SFP_SCHD_MAX_MEMBERS_PER_GROUP_PIPELINE_NPB_VCPFW, \
ECMP_GROUP_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
NPB_ING_SF_0_SFP_FLW_CLS_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
NPB_ING_SFF_ARP_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
NPB_EGR_SF_2_EGRESS_SFP_POLICY_L3_LEN_RNG_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
NPB_ING_SFC_SF_SEL_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
INGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
DEDUP_NUM_BLOCKS_PIPELINE_NPB_VCPFW, \
IPV4_DST_TUNNEL_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
INGRESS_IP_DTEL_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
NPB_EGR_SFF_ARP_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
MPLS_DEPTH_TRANSPORT_PIPELINE_NPB_VCPFW, \
NPB_ING_SF_0_SFP_SCHD_GROUP_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
TUNNEL_DMAC_REWRITE_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
BD_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
IPV4_SRC_TUNNEL_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
NPB_ING_SF_0_BAS_ADV_POLICY_L4_DST_RNG_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
DTEL_GROUP_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
NPB_ING_SFC_TUNNEL_INNER_EXM_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
NPB_ING_SF_0_BAS_ADV_POLICY_L3_LEN_RNG_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
NPB_ING_SF_0_BAS_ADV_SFF_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
MPLS_DEPTH_OUTER_PIPELINE_NPB_VCPFW, \
EGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
INGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
NPB_ING_SF_1_MULTICAST_SFF_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
EGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
NPB_EGR_SF_2_EGRESS_SFP_TRUNC_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
NPB_ING_SFC_TUNNEL_OUTER_TCAM_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_DST_RNG_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
OUTER_ECMP_GROUP_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
TUNNEL_SRC_REWRITE_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
MAC_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
NPB_ING_SF_0_SFP_SCHD_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
EGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
ECMP_SELECT_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
INGRESS_L7_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_SRC_RNG_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
OUTER_ECMP_SELECT_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
LAG_MAX_MEMBERS_PER_GROUP_PIPELINE_NPB_VCPFW, \
VLAN_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
NPB_ING_SF_0_BAS_ADV_POLICY_L4_SRC_RNG_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
IPV6_SRC_TUNNEL_TABLE_SIZE_PIPELINE_NPB_VCPFW, \
NPB_ING_SFC_SF_SEL_NSH_XLATE_TABLE_DEPTH_PIPELINE_NPB_VCPFW, \
DTEL_SELECTOR_TABLE_SIZE_PIPELINE_NPB_VCPFW 

// Deployment Profile: chtr
// -----------------------------------------------

const bool OUTER_IPV6_ENABLE_PIPELINE_NPB_CHTR = true;
const bool INNER_IPV6_ENABLE_PIPELINE_NPB_CHTR = true;
const bool TRANSPORT_ERSPAN_EGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool OUTER_IPoMPLS_ENABLE_PIPELINE_NPB_CHTR = false;
const bool OUTER_MPLSoGRE_ENABLE_PIPELINE_NPB_CHTR = false;
const bool TRANSPORT_ERSPAN_INGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool OUTER_IPINIP_ENABLE_PIPELINE_NPB_CHTR = true;
const bool OUTER_VNTAG_ENABLE_PIPELINE_NPB_CHTR = true;
const bool TRANSPORT_IPV4_VXLAN_INGRESS_ENABLE_PIPELINE_NPB_CHTR = false;
const bool UDF_ENABLE_PIPELINE_NPB_CHTR = false;
const bool INNER_IPINIP_ENABLE_PIPELINE_NPB_CHTR = true;
const bool OUTER_GRE_ENABLE_PIPELINE_NPB_CHTR = true;
const bool TRANSPORT_GRE_INGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool OUTER_EoMPLS_ENABLE_PIPELINE_NPB_CHTR = false;
const bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID_PIPELINE_NPB_CHTR = false;
const bool TRANSPORT_IPV6_REDUCED_ADDR_PIPELINE_NPB_CHTR = true;
const bool OUTER_ETAG_ENABLE_PIPELINE_NPB_CHTR = true;
const bool EGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool OUTER_GENEVE_ENABLE_PIPELINE_NPB_CHTR = true;
const bool INGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool TRANSPORT_GRE_EGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool INNER_GTP_ENABLE_PIPELINE_NPB_CHTR = true;
const bool OUTER_EoMPLS_PWCW_ENABLE_PIPELINE_NPB_CHTR = false;
const bool TRANSPORT_SPBM_INGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool TRANSPORT_EoMPLS_INGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool TRANSPORT_IPV4_INGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool OUTER_NVGRE_ENABLE_PIPELINE_NPB_CHTR = true;
const bool INNER_GRE_ENABLE_PIPELINE_NPB_CHTR = true;
const bool FOLDED_ENABLE_PIPELINE_NPB_CHTR = false;
const bool TRANSPORT_EGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool OUTER_VXLAN_ENABLE_PIPELINE_NPB_CHTR = false;
const bool INNER_INNER_IPV6_ENABLE_PIPELINE_NPB_CHTR = true;
const bool TRANSPORT_IPV4_GENEVE_INGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool TRANSPORT_IPV6_EGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool TRANSPORT_IPV6_INGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool TRANSPORT_INGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool OUTER_GTP_ENABLE_PIPELINE_NPB_CHTR = true;
const bool TRANSPORT_IPV4_EGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bit<32> PORT_TABLE_SIZE_PIPELINE_NPB_CHTR = 288;
const bit<32> OUTER_NEXTHOP_TABLE_SIZE_PIPELINE_NPB_CHTR = 4096;
const bit<32> NEXTHOP_TABLE_SIZE_PIPELINE_NPB_CHTR = 8192;
const bit<32> LAG_SELECTOR_TABLE_SIZE_PIPELINE_NPB_CHTR = 2048;
const bit<32> NPB_ING_SFC_TUNNEL_NETWORK_SAP_TABLE_DEPTH_PIPELINE_NPB_CHTR = 8192;
const bit<32> PORT_VLAN_TABLE_SIZE_PIPELINE_NPB_CHTR = 1024;
const bit<32> IPV6_DST_TUNNEL_TABLE_SIZE_PIPELINE_NPB_CHTR = 1024;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR = 6144;
const bit<32> NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE_PIPELINE_NPB_CHTR = 2096;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_HDR_STRIP_TABLE_DEPTH_PIPELINE_NPB_CHTR = 8;
const bit<32> LAG_GROUP_TABLE_SIZE_PIPELINE_NPB_CHTR = 32;
const bit<32> LAG_TABLE_SIZE_PIPELINE_NPB_CHTR = 1024;
const bit<32> DTEL_MAX_MEMBERS_PER_GROUP_PIPELINE_NPB_CHTR = 64;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_SFF_TABLE_DEPTH_PIPELINE_NPB_CHTR = 8192;
const bit<32> DEDUP_ADDR_WIDTH_PIPELINE_NPB_CHTR = 16;
const bit<32> NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH_PIPELINE_NPB_CHTR = 8192;
const bit<32> NPB_ING_SF_0_SFP_SCHD_SELECTOR_TABLE_SIZE_PIPELINE_NPB_CHTR = 16384;
const bit<32> TUNNEL_SMAC_REWRITE_TABLE_SIZE_PIPELINE_NPB_CHTR = 32;
const bit<32> TUNNEL_DST_REWRITE_TABLE_SIZE_PIPELINE_NPB_CHTR = 1024;
const bit<32> RMAC_TABLE_SIZE_PIPELINE_NPB_CHTR = 64;
const bit<32> NPB_ING_SF_0_SFP_SCHD_MAX_MEMBERS_PER_GROUP_PIPELINE_NPB_CHTR = 128;
const bit<32> ECMP_GROUP_TABLE_SIZE_PIPELINE_NPB_CHTR = 1024;
const bit<32> NPB_ING_SF_0_SFP_FLW_CLS_TABLE_DEPTH_PIPELINE_NPB_CHTR = 128;
const bit<32> NPB_ING_SFF_ARP_TABLE_DEPTH_PIPELINE_NPB_CHTR = 8192;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_L3_LEN_RNG_TABLE_DEPTH_PIPELINE_NPB_CHTR = 128;
const bit<32> NPB_ING_SFC_SF_SEL_TABLE_DEPTH_PIPELINE_NPB_CHTR = 8192;
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR = 1536;
const bit<32> DEDUP_NUM_BLOCKS_PIPELINE_NPB_CHTR = 16;
const bit<32> IPV4_DST_TUNNEL_TABLE_SIZE_PIPELINE_NPB_CHTR = 1024;
const bit<32> INGRESS_IP_DTEL_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR = 512;
const bit<32> NPB_EGR_SFF_ARP_TABLE_DEPTH_PIPELINE_NPB_CHTR = 8192;
const bit<32> MPLS_DEPTH_TRANSPORT_PIPELINE_NPB_CHTR = 4;
const bit<32> NPB_ING_SF_0_SFP_SCHD_GROUP_TABLE_SIZE_PIPELINE_NPB_CHTR = 128;
const bit<32> TUNNEL_DMAC_REWRITE_TABLE_SIZE_PIPELINE_NPB_CHTR = 256;
const bit<32> BD_TABLE_SIZE_PIPELINE_NPB_CHTR = 5120;
const bit<32> IPV4_SRC_TUNNEL_TABLE_SIZE_PIPELINE_NPB_CHTR = 256;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L4_DST_RNG_TABLE_DEPTH_PIPELINE_NPB_CHTR = 256;
const bit<32> DTEL_GROUP_TABLE_SIZE_PIPELINE_NPB_CHTR = 4;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_EXM_TABLE_DEPTH_PIPELINE_NPB_CHTR = 8192;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L3_LEN_RNG_TABLE_DEPTH_PIPELINE_NPB_CHTR = 128;
const bit<32> NPB_ING_SF_0_BAS_ADV_SFF_TABLE_DEPTH_PIPELINE_NPB_CHTR = 1024;
const bit<32> MPLS_DEPTH_OUTER_PIPELINE_NPB_CHTR = 4;
const bit<32> EGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR = 512;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR = 2048;
const bit<32> NPB_ING_SF_1_MULTICAST_SFF_TABLE_DEPTH_PIPELINE_NPB_CHTR = 1024;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR = 512;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_TRUNC_TABLE_DEPTH_PIPELINE_NPB_CHTR = 8;
const bit<32> NPB_ING_SFC_TUNNEL_OUTER_TCAM_TABLE_DEPTH_PIPELINE_NPB_CHTR = 1024;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_DST_RNG_TABLE_DEPTH_PIPELINE_NPB_CHTR = 256;
const bit<32> OUTER_ECMP_GROUP_TABLE_SIZE_PIPELINE_NPB_CHTR = 4096;
const bit<32> TUNNEL_SRC_REWRITE_TABLE_SIZE_PIPELINE_NPB_CHTR = 512;
const bit<32> MAC_TABLE_SIZE_PIPELINE_NPB_CHTR = 1024;
const bit<32> NPB_ING_SF_0_SFP_SCHD_TABLE_SIZE_PIPELINE_NPB_CHTR = 8192;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR = 512;
const bit<32> ECMP_SELECT_TABLE_SIZE_PIPELINE_NPB_CHTR = 16384;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH_PIPELINE_NPB_CHTR = 2048;
const bit<32> INGRESS_L7_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR = 1024;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_SRC_RNG_TABLE_DEPTH_PIPELINE_NPB_CHTR = 256;
const bit<32> OUTER_ECMP_SELECT_TABLE_SIZE_PIPELINE_NPB_CHTR = 16384;
const bit<32> LAG_MAX_MEMBERS_PER_GROUP_PIPELINE_NPB_CHTR = 64;
const bit<32> VLAN_TABLE_SIZE_PIPELINE_NPB_CHTR = 4096;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L4_SRC_RNG_TABLE_DEPTH_PIPELINE_NPB_CHTR = 256;
const bit<32> IPV6_SRC_TUNNEL_TABLE_SIZE_PIPELINE_NPB_CHTR = 256;
const bit<32> NPB_ING_SFC_SF_SEL_NSH_XLATE_TABLE_DEPTH_PIPELINE_NPB_CHTR = 8192;
const bit<32> DTEL_SELECTOR_TABLE_SIZE_PIPELINE_NPB_CHTR = 256;

// Use this #define to pass the list of deployment
// params into your top-level module instantiations.
#define INSTANCE_DEPLOYMENT_PARAMS_PIPELINE_NPB_CHTR \
OUTER_IPV6_ENABLE_PIPELINE_NPB_CHTR, \
INNER_IPV6_ENABLE_PIPELINE_NPB_CHTR, \
TRANSPORT_ERSPAN_EGRESS_ENABLE_PIPELINE_NPB_CHTR, \
OUTER_IPoMPLS_ENABLE_PIPELINE_NPB_CHTR, \
OUTER_MPLSoGRE_ENABLE_PIPELINE_NPB_CHTR, \
TRANSPORT_ERSPAN_INGRESS_ENABLE_PIPELINE_NPB_CHTR, \
OUTER_IPINIP_ENABLE_PIPELINE_NPB_CHTR, \
OUTER_VNTAG_ENABLE_PIPELINE_NPB_CHTR, \
TRANSPORT_IPV4_VXLAN_INGRESS_ENABLE_PIPELINE_NPB_CHTR, \
UDF_ENABLE_PIPELINE_NPB_CHTR, \
INNER_IPINIP_ENABLE_PIPELINE_NPB_CHTR, \
OUTER_GRE_ENABLE_PIPELINE_NPB_CHTR, \
TRANSPORT_GRE_INGRESS_ENABLE_PIPELINE_NPB_CHTR, \
OUTER_EoMPLS_ENABLE_PIPELINE_NPB_CHTR, \
TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID_PIPELINE_NPB_CHTR, \
TRANSPORT_IPV6_REDUCED_ADDR_PIPELINE_NPB_CHTR, \
OUTER_ETAG_ENABLE_PIPELINE_NPB_CHTR, \
EGRESS_ENABLE_PIPELINE_NPB_CHTR, \
OUTER_GENEVE_ENABLE_PIPELINE_NPB_CHTR, \
INGRESS_ENABLE_PIPELINE_NPB_CHTR, \
TRANSPORT_GRE_EGRESS_ENABLE_PIPELINE_NPB_CHTR, \
INNER_GTP_ENABLE_PIPELINE_NPB_CHTR, \
OUTER_EoMPLS_PWCW_ENABLE_PIPELINE_NPB_CHTR, \
TRANSPORT_SPBM_INGRESS_ENABLE_PIPELINE_NPB_CHTR, \
TRANSPORT_EoMPLS_INGRESS_ENABLE_PIPELINE_NPB_CHTR, \
TRANSPORT_IPV4_INGRESS_ENABLE_PIPELINE_NPB_CHTR, \
OUTER_NVGRE_ENABLE_PIPELINE_NPB_CHTR, \
INNER_GRE_ENABLE_PIPELINE_NPB_CHTR, \
FOLDED_ENABLE_PIPELINE_NPB_CHTR, \
TRANSPORT_EGRESS_ENABLE_PIPELINE_NPB_CHTR, \
OUTER_VXLAN_ENABLE_PIPELINE_NPB_CHTR, \
INNER_INNER_IPV6_ENABLE_PIPELINE_NPB_CHTR, \
TRANSPORT_IPV4_GENEVE_INGRESS_ENABLE_PIPELINE_NPB_CHTR, \
TRANSPORT_IPV6_EGRESS_ENABLE_PIPELINE_NPB_CHTR, \
TRANSPORT_IPV6_INGRESS_ENABLE_PIPELINE_NPB_CHTR, \
TRANSPORT_INGRESS_ENABLE_PIPELINE_NPB_CHTR, \
OUTER_GTP_ENABLE_PIPELINE_NPB_CHTR, \
TRANSPORT_IPV4_EGRESS_ENABLE_PIPELINE_NPB_CHTR, \
PORT_TABLE_SIZE_PIPELINE_NPB_CHTR, \
OUTER_NEXTHOP_TABLE_SIZE_PIPELINE_NPB_CHTR, \
NEXTHOP_TABLE_SIZE_PIPELINE_NPB_CHTR, \
LAG_SELECTOR_TABLE_SIZE_PIPELINE_NPB_CHTR, \
NPB_ING_SFC_TUNNEL_NETWORK_SAP_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
PORT_VLAN_TABLE_SIZE_PIPELINE_NPB_CHTR, \
IPV6_DST_TUNNEL_TABLE_SIZE_PIPELINE_NPB_CHTR, \
INGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR, \
NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE_PIPELINE_NPB_CHTR, \
NPB_EGR_SF_2_EGRESS_SFP_HDR_STRIP_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
LAG_GROUP_TABLE_SIZE_PIPELINE_NPB_CHTR, \
LAG_TABLE_SIZE_PIPELINE_NPB_CHTR, \
DTEL_MAX_MEMBERS_PER_GROUP_PIPELINE_NPB_CHTR, \
NPB_EGR_SF_2_EGRESS_SFP_SFF_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
DEDUP_ADDR_WIDTH_PIPELINE_NPB_CHTR, \
NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
NPB_ING_SF_0_SFP_SCHD_SELECTOR_TABLE_SIZE_PIPELINE_NPB_CHTR, \
TUNNEL_SMAC_REWRITE_TABLE_SIZE_PIPELINE_NPB_CHTR, \
TUNNEL_DST_REWRITE_TABLE_SIZE_PIPELINE_NPB_CHTR, \
RMAC_TABLE_SIZE_PIPELINE_NPB_CHTR, \
NPB_ING_SF_0_SFP_SCHD_MAX_MEMBERS_PER_GROUP_PIPELINE_NPB_CHTR, \
ECMP_GROUP_TABLE_SIZE_PIPELINE_NPB_CHTR, \
NPB_ING_SF_0_SFP_FLW_CLS_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
NPB_ING_SFF_ARP_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
NPB_EGR_SF_2_EGRESS_SFP_POLICY_L3_LEN_RNG_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
NPB_ING_SFC_SF_SEL_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
INGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR, \
DEDUP_NUM_BLOCKS_PIPELINE_NPB_CHTR, \
IPV4_DST_TUNNEL_TABLE_SIZE_PIPELINE_NPB_CHTR, \
INGRESS_IP_DTEL_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR, \
NPB_EGR_SFF_ARP_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
MPLS_DEPTH_TRANSPORT_PIPELINE_NPB_CHTR, \
NPB_ING_SF_0_SFP_SCHD_GROUP_TABLE_SIZE_PIPELINE_NPB_CHTR, \
TUNNEL_DMAC_REWRITE_TABLE_SIZE_PIPELINE_NPB_CHTR, \
BD_TABLE_SIZE_PIPELINE_NPB_CHTR, \
IPV4_SRC_TUNNEL_TABLE_SIZE_PIPELINE_NPB_CHTR, \
NPB_ING_SF_0_BAS_ADV_POLICY_L4_DST_RNG_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
DTEL_GROUP_TABLE_SIZE_PIPELINE_NPB_CHTR, \
NPB_ING_SFC_TUNNEL_INNER_EXM_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
NPB_ING_SF_0_BAS_ADV_POLICY_L3_LEN_RNG_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
NPB_ING_SF_0_BAS_ADV_SFF_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
MPLS_DEPTH_OUTER_PIPELINE_NPB_CHTR, \
EGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR, \
INGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR, \
NPB_ING_SF_1_MULTICAST_SFF_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
EGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR, \
NPB_EGR_SF_2_EGRESS_SFP_TRUNC_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
NPB_ING_SFC_TUNNEL_OUTER_TCAM_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_DST_RNG_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
OUTER_ECMP_GROUP_TABLE_SIZE_PIPELINE_NPB_CHTR, \
TUNNEL_SRC_REWRITE_TABLE_SIZE_PIPELINE_NPB_CHTR, \
MAC_TABLE_SIZE_PIPELINE_NPB_CHTR, \
NPB_ING_SF_0_SFP_SCHD_TABLE_SIZE_PIPELINE_NPB_CHTR, \
EGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR, \
ECMP_SELECT_TABLE_SIZE_PIPELINE_NPB_CHTR, \
NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
INGRESS_L7_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR, \
NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_SRC_RNG_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
OUTER_ECMP_SELECT_TABLE_SIZE_PIPELINE_NPB_CHTR, \
LAG_MAX_MEMBERS_PER_GROUP_PIPELINE_NPB_CHTR, \
VLAN_TABLE_SIZE_PIPELINE_NPB_CHTR, \
NPB_ING_SF_0_BAS_ADV_POLICY_L4_SRC_RNG_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
IPV6_SRC_TUNNEL_TABLE_SIZE_PIPELINE_NPB_CHTR, \
NPB_ING_SFC_SF_SEL_NSH_XLATE_TABLE_DEPTH_PIPELINE_NPB_CHTR, \
DTEL_SELECTOR_TABLE_SIZE_PIPELINE_NPB_CHTR 

#endif // _DEPLOYMENT_PARAMS_PIPELINE_NPB_