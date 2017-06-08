#ifdef __TARGET_TOFINO__
//#define DC_BASIC_PROFILE
#define HARLYN
//#define MIN_PROFILE
#define URPF_DISABLE
#define IPSG_DISABLE
#define IPV6_OUTER_MULTICAST_DISABLE
//#define IPV6_MULTICAST_DISABLE
//#define NAT_DISABLE
#endif

// Profiles control
//#define DC_BASIC_PROFILE
//#define MIN_PROFILE

// Individual features control
//#define URPF_DISABLE
//#define IPV6_DISABLE
//#define MPLS_DISABLE
//#define NAT_DISABLE
//#define MULTICAST_DISABLE
//#define TUNNEL_DISABLE
//#define STORM_CONTROL_DISABLE
//#define IPSG_DISABLE
//#define ACL_DISABLE
//#define QOS_DISABLE
//#define MTU_DISABLE
//#define STP_DISABLE

#ifdef DC_BASIC_PROFILE
#define URPF_DISABLE
#define MPLS_DISABLE
#define NAT_DISABLE
#define MULTICAST_DISABLE
#define STORM_CONTROL_DISABLE
#define IPSG_DISABLE
#define ACL_DISABLE
#define QOS_DISABLE
#define MTU_DISABLE
#define HARLYN
#endif

#define OUTER_PIM_BIDIR_OPTIMIZATION
#define PIM_BIDIR_OPTIMIZATION

// Defines for semantic library
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

#ifdef TUNNEL_DISABLE
#define P4_TUNNEL_DISABLE
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

#ifdef MTU_DISABLE
#define P4_MTU_DISABLE
#endif

#ifdef STP_DISABLE
#define P4_STP_DISABLE
#endif
