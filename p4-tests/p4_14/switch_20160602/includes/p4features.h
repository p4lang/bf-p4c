#ifdef __TARGET_TOFINO__
#ifndef USER_FEATURE_OVERRIDE
#define DC_BASIC_PROFILE
#else
#include "p4userfeatures.h"
#endif
#else
#define FABRIC_ENABLE
#ifdef BMV2
#define EGRESS_FILTER
#define STORM_CONTROL_DISABLE
#define INT_TRANSIT_ENABLE
#define INT_PLT_ENABLE
#endif
#endif

#ifdef INT_DEBUG
#define P4_INT_DEBUG
#endif

/* TRANSIT and EP are mutually exclusive */
/* favor EP over TRANSIT if both are set */
#ifdef INT_EP_ENABLE
#define P4_INT_EP_ENABLE
#define INT_ENABLE
#define P4_INT_ENABLE
#undef INT_TRANSIT_ENABLE
#endif

#ifdef INT_TRANSIT_ENABLE
#define P4_INT_TRANSIT_ENABLE
#define INT_ENABLE
#define P4_INT_ENABLE
#endif

#ifdef INT_PLT_ENABLE
#define INT_ENABLE
#define P4_INT_ENABLE
#define P4_INT_PLT_ENABLE
#endif

#if defined(SFLOW_ENABLE) && defined(__TARGET_TOFINO__)
#define URPF_DISABLE
#define MPLS_DISABLE
#endif

#ifdef SFLOW_ENABLE
#define P4_SFLOW_ENABLE
#endif

#if defined(FLOWLET_ENABLE) && defined(__TARGET_TOFINO__)
#define STORM_CONTROL_DISABLE
#define IPSG_DISABLE
#define URPF_DISABLE
#define NAT_DISABLE
#endif

#ifdef FLOWLET_ENABLE
#define P4_FLOWLET_ENABLE
#endif

#if defined(INT_ENABLE) && defined(__TARGET_TOFINO__)
#define MPLS_DISABLE
#define MULTICAST_DISABLE
#define TUNNEL_OVER_IPV6_DISABLE
#undef FABRIC_ENABLE
#endif

#if defined(INT_EP_ENABLE) && defined(__TARGET_TOFINO__)
#define STP_DISABLE
#define STORM_CONTROL_DISABLE
#define IPSG_DISABLE
#define EGRESS_FILTER_DISABLE
#define NVGRE_DISABLE
#define URPF_DISABLE
#define NAT_DISABLE
#define IPV6_DISABLE
#endif

// Profiles control, default is DC_BASIC_PROFILE
//#define DC_BASIC_PROFILE
//#define DC_MAXSIZES_PROFILE

// Individual features control
//#define URPF_DISABLE
//#define IPV6_DISABLE
//#define MPLS_DISABLE
//#define NAT_DISABLE
//#define MULTICAST_DISABLE
//#define L2_MULTICAST_DISABLE
//#define L3_MULTICAST_DISABLE
//#define TUNNEL_DISABLE
//#define STORM_CONTROL_DISABLE
//#define IPSG_DISABLE
//#define ACL_DISABLE
//#define QOS_DISABLE
//#define STP_DISABLE
//#define L2_DISABLE
//#define L3_DISABLE
//#define EGRESS_FILTER
//#define STATS_DISABLE
//#define MIRROR_DISABLE

#if defined(DC_MAXSIZES_PROFILE)

#define URPF_DISABLE
#define NAT_DISABLE
#define IPSG_DISABLE
#define QOS_DISABLE
#ifndef HARLYN
#define HARLYN
#endif

#elif defined(L2_PROFILE)

#define HARLYN
#define SCALING
#define L3_DISABLE
#define IPV6_DISABLE
#define ACL_DISABLE
#define MPLS_DISABLE
#define NAT_DISABLE
#define MULTICAST_DISABLE
#define TUNNEL_DISABLE
#define STORM_CONTROL_DISABLE
#define IPSG_DISABLE
#define METER_DISABLE

#elif defined(L3_IPV4_PROFILE) || defined(L3_IPV4_FULL_PROFILE)

#define HARLYN
#define SCALING
#define L2_DISABLE
#define IPV6_DISABLE
#define URPF_DISABLE
#define ACL_DISABLE
#define MPLS_DISABLE
#define NAT_DISABLE
#define MULTICAST_DISABLE
#define TUNNEL_DISABLE
#define STORM_CONTROL_DISABLE
#define IPSG_DISABLE
#define METER_DISABLE

#elif defined(L3_IPV4_ALPM_PROFILE)

#define HARLYN
#define SCALING
#define ALPM
#define L2_DISABLE
#define IPV6_DISABLE
#define URPF_DISABLE
#define ACL_DISABLE
#define MPLS_DISABLE
#define NAT_DISABLE
#define MULTICAST_DISABLE
#define TUNNEL_DISABLE
#define STORM_CONTROL_DISABLE
#define IPSG_DISABLE
#define METER_DISABLE

#elif defined(L3_IPV6_PROFILE)

#define HARLYN
#define SCALING
#define L2_DISABLE
#define IPV4_DISABLE
#define URPF_DISABLE
#define ACL_DISABLE
#define MPLS_DISABLE
#define NAT_DISABLE
#define MULTICAST_DISABLE
#define TUNNEL_DISABLE
#define STORM_CONTROL_DISABLE
#define IPSG_DISABLE
#define METER_DISABLE

#elif defined(L3_IPV6_ALPM_PROFILE)

#define HARLYN
#define SCALING
#define ALPM
#define L2_DISABLE
#define IPV4_DISABLE
#define URPF_DISABLE
#define ACL_DISABLE
#define MPLS_DISABLE
#define NAT_DISABLE
#define MULTICAST_DISABLE
#define TUNNEL_DISABLE
#define STORM_CONTROL_DISABLE
#define IPSG_DISABLE
#define METER_DISABLE

#elif defined(L3_IPV4_TUNNEL_PROFILE)

#define HARLYN
#define SCALING
#define L2_DISABLE
#define IPV6_DISABLE
#define URPF_DISABLE
#define ACL_DISABLE
#define MPLS_DISABLE
#define NAT_DISABLE
#define MULTICAST_DISABLE
#define STORM_CONTROL_DISABLE
#define IPSG_DISABLE
#define METER_DISABLE

#elif defined(L3_IPV6_TUNNEL_PROFILE)

#define HARLYN
#define SCALING
#define L2_DISABLE
#define IPV4_DISABLE
#define URPF_DISABLE
#define ACL_DISABLE
#define MPLS_DISABLE
#define NAT_DISABLE
#define MULTICAST_DISABLE
#define STORM_CONTROL_DISABLE
#define IPSG_DISABLE
#define METER_DISABLE

#elif defined(IPV4_ACL_PROFILE)

#define HARLYN
#define SCALING
#define L2_DISABLE
#define IPV6_DISABLE
#define URPF_DISABLE
#define MPLS_DISABLE
#define NAT_DISABLE
#define MULTICAST_DISABLE
#define TUNNEL_DISABLE
#define STORM_CONTROL_DISABLE
#define IPSG_DISABLE
#define QOS_DISABLE
#define METER_DISABLE

#elif defined(IPV4_ACL_ATCAM_PROFILE)

#define HARLYN
#define SCALING
#define ATCAM
#define L2_DISABLE
#define IPV6_DISABLE
#define URPF_DISABLE
#define MPLS_DISABLE
#define NAT_DISABLE
#define MULTICAST_DISABLE
#define TUNNEL_DISABLE
#define STORM_CONTROL_DISABLE
#define IPSG_DISABLE
#define QOS_DISABLE
#define METER_DISABLE

#elif defined(IPV6_ACL_PROFILE)

#define HARLYN
#define SCALING
#define L2_DISABLE
#define IPV4_DISABLE
#define URPF_DISABLE
#define MPLS_DISABLE
#define NAT_DISABLE
#define MULTICAST_DISABLE
#define TUNNEL_DISABLE
#define STORM_CONTROL_DISABLE
#define IPSG_DISABLE
#define QOS_DISABLE
#define METER_DISABLE

#elif defined(IPV6_ACL_ATCAM_PROFILE)

#define HARLYN
#define SCALING
#define ATCAM
#define L2_DISABLE
#define IPV4_DISABLE
#define URPF_DISABLE
#define MPLS_DISABLE
#define NAT_DISABLE
#define MULTICAST_DISABLE
#define TUNNEL_DISABLE
#define STORM_CONTROL_DISABLE
#define IPSG_DISABLE
#define QOS_DISABLE
#define METER_DISABLE

#elif defined(DC_BASIC_PROFILE)

#define MIN_PROFILE
#define IPSG_DISABLE
#define QOS_DISABLE
#ifndef HARLYN
#define HARLYN
#endif

#endif

#define OUTER_PIM_BIDIR_OPTIMIZATION
#define PIM_BIDIR_OPTIMIZATION

#if defined(FABRIC_ENABLE) && defined(HARLYN)
#define MIN_PROFILE
#define IPV6_DISABLE
#define MPLS_DISABLE
#define NAT_DISABLE
#endif

#if defined(DC_MAXSIZES_FABRIC_PROFILE)
#define FABRIC_ENABLE
#define URPF_DISABLE
#define NAT_DISABLE
#define IPSG_DISABLE
#define QOS_DISABLE
#define IPV6_DISABLE
#define MPLS_DISABLE
#ifndef HARLYN
#define HARLYN
#endif
#endif

#ifdef MULTICAST_DISABLE
#define L2_MULTICAST_DISABLE
#define L3_MULTICAST_DISABLE
#endif

// Defines for switchapi library
#ifdef URPF_DISABLE
#define P4_URPF_DISABLE
#endif

#ifdef IPV6_DISABLE
#define P4_IPV6_DISABLE
#endif

#ifdef MPLS_DISABLE
#define P4_MPLS_DISABLE
#endif

#ifdef NAT_DISABLE
#define P4_NAT_DISABLE
#endif

#ifdef MULTICAST_DISABLE
#define P4_MULTICAST_DISABLE
#endif

#ifdef L2_MULTICAST_DISABLE
#define P4_L2_MULTICAST_DISABLE
#endif

#ifdef L3_MULTICAST_DISABLE
#define P4_L3_MULTICAST_DISABLE
#endif

#ifdef TUNNEL_DISABLE
#define P4_TUNNEL_DISABLE
#endif

#ifdef NVGRE_DISABLE
#define P4_NVGRE_DISABLE
#endif

#ifdef STORM_CONTROL_DISABLE
#define P4_STORM_CONTROL_DISABLE
#endif

#ifdef IPSG_DISABLE
#define P4_IPSG_DISABLE
#endif

#ifdef ACL_DISABLE
#define P4_ACL_DISABLE
#endif

#ifdef QOS_DISABLE
#define P4_QOS_DISABLE
#endif

#ifdef STP_DISABLE
#define P4_STP_DISABLE
#endif

#ifdef L2_DISABLE
#define P4_L2_DISABLE
#endif

#ifdef L3_DISABLE
#define P4_L3_DISABLE
#endif

#ifdef IPV4_DISABLE
#define P4_IPV4_DISABLE
#endif

#ifdef STATS_DISABLE
#define P4_STATS_DISABLE
#endif

#ifdef EGRESS_FILTER
#define P4_EGRESS_FILTER
#endif

#ifdef METER_DISABLE
#define P4_METER_DISABLE
#endif

#ifdef MIRROR_DISABLE
#define P4_MIRROR_DISABLE
#endif
