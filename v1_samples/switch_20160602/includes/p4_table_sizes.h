#ifndef _P4_TABLE_SIZES_H_
#define _P4_TABLE_SIZES_H_

#if defined(MIN_PROFILE)
/******************************************************************************
 *  Min Size profile
 *****************************************************************************/
#define MIN_SRAM_TABLE_SIZE                    1024
#define MIN_TCAM_TABLE_SIZE                    512

#define VALIDATE_PACKET_TABLE_SIZE             MIN_TCAM_TABLE_SIZE
#define PORTMAP_TABLE_SIZE                     288
#define STORM_CONTROL_TABLE_SIZE               MIN_TCAM_TABLE_SIZE
#define STORM_CONTROL_METER_TABLE_SIZE         MIN_SRAM_TABLE_SIZE
#define STORM_CONTROL_STATS_TABLE_SIZE         MIN_SRAM_TABLE_SIZE
#define PORT_VLAN_TABLE_SIZE                   4096
#define OUTER_ROUTER_MAC_TABLE_SIZE            MIN_SRAM_TABLE_SIZE
#define DEST_TUNNEL_TABLE_SIZE                 MIN_SRAM_TABLE_SIZE
#define IPV4_SRC_TUNNEL_TABLE_SIZE             MIN_SRAM_TABLE_SIZE
#define IPV6_SRC_TUNNEL_TABLE_SIZE             MIN_SRAM_TABLE_SIZE
#define TUNNEL_SRC_REWRITE_TABLE_SIZE          MIN_SRAM_TABLE_SIZE
#define TUNNEL_DST_REWRITE_TABLE_SIZE          MIN_SRAM_TABLE_SIZE
#define OUTER_MULTICAST_STAR_G_TABLE_SIZE      MIN_TCAM_TABLE_SIZE
#define OUTER_MULTICAST_S_G_TABLE_SIZE         MIN_SRAM_TABLE_SIZE
#define VNID_MAPPING_TABLE_SIZE                MIN_SRAM_TABLE_SIZE
#define BD_TABLE_SIZE                          MIN_SRAM_TABLE_SIZE
#define BD_FLOOD_TABLE_SIZE                    MIN_SRAM_TABLE_SIZE
#define BD_STATS_TABLE_SIZE                    MIN_SRAM_TABLE_SIZE
#define OUTER_MCAST_RPF_TABLE_SIZE             MIN_SRAM_TABLE_SIZE
#define MPLS_TABLE_SIZE                        MIN_SRAM_TABLE_SIZE
#define VALIDATE_MPLS_TABLE_SIZE               MIN_TCAM_TABLE_SIZE

#define ROUTER_MAC_TABLE_SIZE                  MIN_SRAM_TABLE_SIZE
#define MAC_TABLE_SIZE                         MIN_SRAM_TABLE_SIZE
#define IPSG_TABLE_SIZE                        MIN_SRAM_TABLE_SIZE
#define IPSG_PERMIT_SPECIAL_TABLE_SIZE         MIN_TCAM_TABLE_SIZE
#define INGRESS_MAC_ACL_TABLE_SIZE             MIN_TCAM_TABLE_SIZE
#define INGRESS_IP_ACL_TABLE_SIZE              MIN_TCAM_TABLE_SIZE
#define INGRESS_IPV6_ACL_TABLE_SIZE            MIN_TCAM_TABLE_SIZE
#define INGRESS_QOS_ACL_TABLE_SIZE             MIN_TCAM_TABLE_SIZE
#define INGRESS_IP_RACL_TABLE_SIZE             MIN_TCAM_TABLE_SIZE
#define INGRESS_IPV6_RACL_TABLE_SIZE           MIN_TCAM_TABLE_SIZE
#define IP_NAT_TABLE_SIZE                      MIN_SRAM_TABLE_SIZE
#define IP_NAT_FLOW_TABLE_SIZE                 MIN_TCAM_TABLE_SIZE
#define EGRESS_NAT_TABLE_SIZE                  MIN_SRAM_TABLE_SIZE
#define IPV4_LPM_TABLE_SIZE                    MIN_TCAM_TABLE_SIZE
#define IPV6_LPM_TABLE_SIZE                    MIN_TCAM_TABLE_SIZE
#define IPV4_HOST_TABLE_SIZE                   MIN_SRAM_TABLE_SIZE
#define IPV6_HOST_TABLE_SIZE                   MIN_SRAM_TABLE_SIZE
#define IPV4_MULTICAST_STAR_G_TABLE_SIZE       MIN_SRAM_TABLE_SIZE
#define IPV4_MULTICAST_S_G_TABLE_SIZE          MIN_SRAM_TABLE_SIZE
#define IPV6_MULTICAST_STAR_G_TABLE_SIZE       MIN_SRAM_TABLE_SIZE
#define IPV6_MULTICAST_S_G_TABLE_SIZE          MIN_SRAM_TABLE_SIZE
#define MCAST_RPF_TABLE_SIZE                   MIN_SRAM_TABLE_SIZE
#define FWD_RESULT_TABLE_SIZE                  MIN_TCAM_TABLE_SIZE
#define URPF_GROUP_TABLE_SIZE                  MIN_SRAM_TABLE_SIZE
#define ECMP_GROUP_TABLE_SIZE                  MIN_SRAM_TABLE_SIZE
#define ECMP_SELECT_TABLE_SIZE                 MIN_SRAM_TABLE_SIZE
#define NEXTHOP_TABLE_SIZE                     MIN_SRAM_TABLE_SIZE
#define LAG_GROUP_TABLE_SIZE                   MIN_SRAM_TABLE_SIZE
#define LAG_SELECT_TABLE_SIZE                  MIN_SRAM_TABLE_SIZE
#define SYSTEM_ACL_SIZE                        MIN_TCAM_TABLE_SIZE
#define LEARN_NOTIFY_TABLE_SIZE                MIN_TCAM_TABLE_SIZE

#define MAC_REWRITE_TABLE_SIZE                 MIN_TCAM_TABLE_SIZE
#define EGRESS_VNID_MAPPING_TABLE_SIZE         MIN_SRAM_TABLE_SIZE
#define EGRESS_BD_MAPPING_TABLE_SIZE           MIN_SRAM_TABLE_SIZE
#define EGRESS_BD_STATS_TABLE_SIZE             MIN_SRAM_TABLE_SIZE
#define REPLICA_TYPE_TABLE_SIZE                MIN_TCAM_TABLE_SIZE
#define RID_TABLE_SIZE                         MIN_SRAM_TABLE_SIZE
#define TUNNEL_DECAP_TABLE_SIZE                MIN_SRAM_TABLE_SIZE
#define L3_MTU_TABLE_SIZE                      MIN_SRAM_TABLE_SIZE
#define EGRESS_VLAN_XLATE_TABLE_SIZE           MIN_SRAM_TABLE_SIZE
#define SPANNING_TREE_TABLE_SIZE               MIN_SRAM_TABLE_SIZE
#define FABRIC_REWRITE_TABLE_SIZE              MIN_TCAM_TABLE_SIZE
#define EGRESS_ACL_TABLE_SIZE                  MIN_TCAM_TABLE_SIZE
#define VLAN_DECAP_TABLE_SIZE                  MIN_SRAM_TABLE_SIZE
#define TUNNEL_HEADER_TABLE_SIZE               MIN_SRAM_TABLE_SIZE
#define TUNNEL_REWRITE_TABLE_SIZE              MIN_SRAM_TABLE_SIZE
#define TUNNEL_SMAC_REWRITE_TABLE_SIZE         MIN_SRAM_TABLE_SIZE
#define TUNNEL_DMAC_REWRITE_TABLE_SIZE         MIN_SRAM_TABLE_SIZE
#define MIRROR_SESSIONS_TABLE_SIZE             MIN_SRAM_TABLE_SIZE
#define MIRROR_COALESCING_SESSIONS_TABLE_SIZE  MIN_SRAM_TABLE_SIZE
#define DROP_STATS_TABLE_SIZE                  MIN_SRAM_TABLE_SIZE
#define ACL_STATS_TABLE_SIZE                   MIN_SRAM_TABLE_SIZE
#define METER_INDEX_TABLE_SIZE                 MIN_SRAM_TABLE_SIZE
#define METER_ACTION_TABLE_SIZE                MIN_SRAM_TABLE_SIZE

#define INT_TERMINATE_TABLE_SIZE               256
#define INT_SOURCE_TABLE_SIZE                  256
#define INT_UNDERLAY_ENCAP_TABLE_SIZE          8
#define PLT_HASH_WIDTH                         16
#define PLT_BLOOM_FILTER_SIZE                  65536
#define PLT_NUM_FILTERS                        7

#define SFLOW_INGRESS_TABLE_SIZE               512
#define SFLOW_EGRESS_TABLE_SIZE                512
#define MAX_SFLOW_SESSIONS                     16

#define FLOWLET_MAP_SIZE                       8192
#define FLOWLET_MAP_WIDTH                      13

#else
/******************************************************************************
 *  Default MAX Profile
 *****************************************************************************/
#define VALIDATE_PACKET_TABLE_SIZE             64
#define PORTMAP_TABLE_SIZE                     288
#define STORM_CONTROL_TABLE_SIZE               512
#define STORM_CONTROL_METER_TABLE_SIZE         512
#define STORM_CONTROL_STATS_TABLE_SIZE         8
#define PORT_VLAN_TABLE_SIZE                   32768
#define OUTER_ROUTER_MAC_TABLE_SIZE            256
#define DEST_TUNNEL_TABLE_SIZE                 512
#define IPV4_SRC_TUNNEL_TABLE_SIZE             16384
#define IPV6_SRC_TUNNEL_TABLE_SIZE             4096
#define TUNNEL_SRC_REWRITE_TABLE_SIZE          512
#define TUNNEL_DST_REWRITE_TABLE_SIZE          16354
#define OUTER_MULTICAST_STAR_G_TABLE_SIZE      512
#define OUTER_MULTICAST_S_G_TABLE_SIZE         1024
#define VNID_MAPPING_TABLE_SIZE                16384
#define BD_TABLE_SIZE                          16384
#define BD_FLOOD_TABLE_SIZE                    49152
#define BD_STATS_TABLE_SIZE                    16384
#define OUTER_MCAST_RPF_TABLE_SIZE             512
#define MPLS_TABLE_SIZE                        4096
#define VALIDATE_MPLS_TABLE_SIZE               512

#define ROUTER_MAC_TABLE_SIZE                  512
#define MAC_TABLE_SIZE                         65536
#define IPSG_TABLE_SIZE                        8192
#define IPSG_PERMIT_SPECIAL_TABLE_SIZE         512
#define INGRESS_MAC_ACL_TABLE_SIZE             512
#define INGRESS_IP_ACL_TABLE_SIZE              1024
#define INGRESS_IPV6_ACL_TABLE_SIZE            512
#define INGRESS_QOS_ACL_TABLE_SIZE             512
#define INGRESS_IP_RACL_TABLE_SIZE             1024
#define INGRESS_IPV6_RACL_TABLE_SIZE           512
#define IP_NAT_TABLE_SIZE                      4096
#define IP_NAT_FLOW_TABLE_SIZE                 512
#define EGRESS_NAT_TABLE_SIZE                  16384

#define IPV4_LPM_TABLE_SIZE                    8192
#define IPV6_LPM_TABLE_SIZE                    2048
#define IPV4_HOST_TABLE_SIZE                   65536
#define IPV6_HOST_TABLE_SIZE                   16384

#define IPV4_MULTICAST_STAR_G_TABLE_SIZE       2048
#define IPV4_MULTICAST_S_G_TABLE_SIZE          4096
#define IPV6_MULTICAST_STAR_G_TABLE_SIZE       512
#define IPV6_MULTICAST_S_G_TABLE_SIZE          512
#define MCAST_RPF_TABLE_SIZE                   32768

#define FWD_RESULT_TABLE_SIZE                  512
#define URPF_GROUP_TABLE_SIZE                  32768
#define ECMP_GROUP_TABLE_SIZE                  1024
#define ECMP_SELECT_TABLE_SIZE                 16384
#define NEXTHOP_TABLE_SIZE                     49152
#define LAG_GROUP_TABLE_SIZE                   1024
#define LAG_SELECT_TABLE_SIZE                  1024
#define SYSTEM_ACL_SIZE                        512
#define LEARN_NOTIFY_TABLE_SIZE                512

#define MAC_REWRITE_TABLE_SIZE                 512
#define EGRESS_VNID_MAPPING_TABLE_SIZE         16384
#define EGRESS_BD_MAPPING_TABLE_SIZE           16384
#define EGRESS_BD_STATS_TABLE_SIZE             16384
#define REPLICA_TYPE_TABLE_SIZE                16
#define RID_TABLE_SIZE                         32768
#define TUNNEL_DECAP_TABLE_SIZE                512
#define L3_MTU_TABLE_SIZE                      512
#define EGRESS_VLAN_XLATE_TABLE_SIZE           32768
#define SPANNING_TREE_TABLE_SIZE               4096
#define FABRIC_REWRITE_TABLE_SIZE              512
#define EGRESS_ACL_TABLE_SIZE                  1024
#define VLAN_DECAP_TABLE_SIZE                  256
#define TUNNEL_HEADER_TABLE_SIZE               256
#define TUNNEL_REWRITE_TABLE_SIZE              16384
#define TUNNEL_SMAC_REWRITE_TABLE_SIZE         512
#define TUNNEL_DMAC_REWRITE_TABLE_SIZE         16384

#define MIRROR_SESSIONS_TABLE_SIZE             1024
#define MIRROR_COALESCING_SESSIONS_TABLE_SIZE  8

#define DROP_STATS_TABLE_SIZE                  256
#define ACL_STATS_TABLE_SIZE                   8192
#define METER_INDEX_TABLE_SIZE                 2048
#define METER_ACTION_TABLE_SIZE                8192

#define INT_TERMINATE_TABLE_SIZE               1024
#define INT_SOURCE_TABLE_SIZE                  2048
#define INT_UNDERLAY_ENCAP_TABLE_SIZE          8
#define PLT_HASH_WIDTH                         16
#define PLT_BLOOM_FILTER_SIZE                  65536
#define PLT_NUM_FILTERS                        7

#define SFLOW_INGRESS_TABLE_SIZE               512
#define SFLOW_EGRESS_TABLE_SIZE                512
#define MAX_SFLOW_SESSIONS                     16

#define FLOWLET_MAP_SIZE                       8192
#define FLOWLET_MAP_WIDTH                      13

#endif

#if defined(L2_PROFILE)
#undef MAC_TABLE_SIZE
#undef NEXTHOP_TABLE_SIZE

#define MAC_TABLE_SIZE                         512000
#define NEXTHOP_TABLE_SIZE                     16384
#endif

#if defined(L3_IPV4_PROFILE)
#undef IPV4_HOST_TABLE_SIZE
#undef IPV4_LPM_TABLE_SIZE
#undef NEXTHOP_TABLE_SIZE
#undef TUNNEL_REWRITE_TABLE_SIZE

#define IPV4_HOST_TABLE_SIZE                   1269760
#define IPV4_LPM_TABLE_SIZE                    4096
#define NEXTHOP_TABLE_SIZE                     6144
#define TUNNEL_REWRITE_TABLE_SIZE              1024
#endif

#if defined(L3_IPV4_FULL_PROFILE)
#undef TUNNEL_REWRITE_TABLE_SIZE
#undef BD_STATS_TABLE_SIZE
#undef EGRESS_BD_STATS_TABLE_SIZE
#undef NEXTHOP_TABLE_SIZE
#undef ECMP_GROUP_TABLE_SIZE
#undef ECMP_SELECT_TABLE_SIZE
#undef PORT_VLAN_TABLE_SIZE
#undef EGRESS_VLAN_XLATE_TABLE_SIZE
#undef ROUTER_MAC_TABLE_SIZE
#undef MIRROR_SESSIONS_TABLE_SIZE
#undef L3_MTU_TABLE_SIZE
#undef SYSTEM_ACL_SIZE
#undef IPV4_HOST_TABLE_SIZE
#undef IPV4_LPM_TABLE_SIZE

#define TUNNEL_REWRITE_TABLE_SIZE              12288
#define BD_STATS_TABLE_SIZE                    32768
#define EGRESS_BD_STATS_TABLE_SIZE             32768
#define NEXTHOP_TABLE_SIZE                     67584
#define ECMP_GROUP_TABLE_SIZE                  16384
#define ECMP_SELECT_TABLE_SIZE                 32768
#define PORT_VLAN_TABLE_SIZE                   76875
#define EGRESS_VLAN_XLATE_TABLE_SIZE           76875
#define ROUTER_MAC_TABLE_SIZE                  2048
#define MIRROR_SESSIONS_TABLE_SIZE             8192
#define L3_MTU_TABLE_SIZE                      10240
#define SYSTEM_ACL_SIZE                        1024
#define IPV4_HOST_TABLE_SIZE                   1167360
#define IPV4_LPM_TABLE_SIZE                    5120
#endif

#if defined(L3_IPV4_ALPM_PROFILE)
#undef IPV4_HOST_TABLE_SIZE
#undef IPV4_LPM_TABLE_SIZE

#define IPV4_HOST_TABLE_SIZE                   182272
#define IPV4_FIB_PARTITION_TABLE_SIZE          4096
#define IPV4_LPM_TABLE_SIZE                    462848
#endif

#if defined(L3_IPV6_PROFILE)
#undef IPV6_HOST_TABLE_SIZE
#undef IPV6_LPM_TABLE_SIZE

#define IPV6_HOST_TABLE_SIZE                   303104
#define IPV6_LPM_TABLE_SIZE                    2048
#endif

#if defined(L3_IPV6_ALPM_PROFILE)
#undef IPV6_HOST_TABLE_SIZE
#undef IPV6_LPM_TABLE_SIZE

#define IPV6_HOST_TABLE_SIZE                   59392
#define IPV6_FIB_PARTITION_TABLE_SIZE          2048
#define IPV6_LPM_TABLE_SIZE                    266240
#endif

#if defined(L3_IPV4_TUNNEL_PROFILE)
#undef IPV4_HOST_TABLE_SIZE
#undef IPV4_LPM_TABLE_SIZE
#undef IPV4_SRC_TUNNEL_TABLE_SIZE
#undef TUNNEL_REWRITE_TABLE_SIZE
#undef TUNNEL_DST_REWRITE_TABLE_SIZE

#define IPV4_HOST_TABLE_SIZE                   129024
#define IPV4_LPM_TABLE_SIZE                    4096
#define IPV4_SRC_TUNNEL_TABLE_SIZE             253952
#define TUNNEL_REWRITE_TABLE_SIZE              253952
#define TUNNEL_DST_REWRITE_TABLE_SIZE          253952
#endif

#if defined(L3_IPV6_TUNNEL_PROFILE)
#undef IPV6_HOST_TABLE_SIZE
#undef IPV6_LPM_TABLE_SIZE
#undef IPV6_SRC_TUNNEL_TABLE_SIZE
#undef TUNNEL_REWRITE_TABLE_SIZE
#undef TUNNEL_DST_REWRITE_TABLE_SIZE

#define IPV6_HOST_TABLE_SIZE                   26624
#define IPV6_LPM_TABLE_SIZE                    8192
#define IPV6_SRC_TUNNEL_TABLE_SIZE             114688
#define TUNNEL_REWRITE_TABLE_SIZE              114688
#define TUNNEL_DST_REWRITE_TABLE_SIZE          114688
#endif

#if defined(IPV4_ACL_PROFILE)
#undef IPV4_HOST_TABLE_SIZE
#undef IPV4_LPM_TABLE_SIZE
#undef INGRESS_IP_ACL_TABLE_SIZE

#define IPV4_HOST_TABLE_SIZE                   165888
#define IPV4_LPM_TABLE_SIZE                    4096
#define INGRESS_IP_ACL_TABLE_SIZE              20480
#endif

#if defined(IPV4_ACL_ATCAM_PROFILE)
#undef IPV4_HOST_TABLE_SIZE
#undef IPV4_LPM_TABLE_SIZE
#undef INGRESS_IP_ACL_TABLE_SIZE

#define IPV4_HOST_TABLE_SIZE                   165888
#define IPV4_LPM_TABLE_SIZE                    4096
#define IPV4_ACL_PARTITION_TABLE_SIZE          2048
#define INGRESS_IP_ACL_TABLE_SIZE              122880
#endif

#if defined(IPV6_ACL_PROFILE)
#undef IPV6_HOST_TABLE_SIZE
#undef IPV6_LPM_TABLE_SIZE
#undef INGRESS_IPV6_ACL_TABLE_SIZE

#define IPV6_HOST_TABLE_SIZE                   32768
#define IPV6_LPM_TABLE_SIZE                    2048
#define INGRESS_IPV6_ACL_TABLE_SIZE            7168
#endif

#if defined(IPV6_ACL_ATCAM_PROFILE)
#undef IPV6_HOST_TABLE_SIZE
#undef IPV6_LPM_TABLE_SIZE
#undef INGRESS_IPV6_ACL_TABLE_SIZE

#define IPV6_HOST_TABLE_SIZE                   32768
#define IPV6_LPM_TABLE_SIZE                    2048
#define IPV6_ACL_PARTITION_TABLE_SIZE          1024
#define INGRESS_IPV6_ACL_TABLE_SIZE            61440
#endif

#endif /* _P4_TABLE_SIZES_H_ */
