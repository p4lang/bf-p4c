// P4C-5019: program exhibits this problem without the fix:
//
// Compiler Bug: Could not find field ingress::eg_md.common.lkp
//
// Restricting to TF1 for now as that's the platform targeted by the customer.

#include <core.p4>
#include <tna.p4>   /* TOFINO1_ONLY */

@command_line("--disable-parse-max-depth-limit")



//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------




typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
typedef bit<32> switch_vpc_id_t;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<1> flag_rs;
    bit<1> flag_df;
    bit<1> flag_mf;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header ipv4_option_h {
    bit<8> type;
    bit<8> length;
    bit<16> value;
}

header ipv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header tcp_option_1b_h {
     bit<8> value;
}

header tcp_option_2b_h {
    bit<16> value;
}

header tcp_option_4b_h {
    bit<32> value;
}

header tcp_option_mss_h {
    bit<8> kind;
    bit<8> length;
    bit<16> mss;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

header icmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
}

// Address Resolution Protocol -- RFC 6747
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;






}

// VXLAN -- RFC 7348
header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

//TGRE
header gre_common_h {
    bit<1> C;
    bit<1> R;
    bit<1> K;
    bit<1> S;
    bit<1> s;
    bit<3> recurse;
    bit<5> flags;
    bit<3> version;
    bit<16> protocol;
}

//C flag is invalid
header gre_vpc1_h {
    bit<1> C;
    bit<1> R;
    bit<1> K;
    bit<1> S;
    bit<1> s;
    bit<3> recurse;
    bit<5> flags;
    bit<3> version;
    bit<16> protocol;
    switch_vpc_id_t vpcid;
}

//C flag is valid
header gre_vpc2_h {
    bit<1> C;
    bit<1> R;
    bit<1> K;
    bit<1> S;
    bit<1> s;
    bit<3> recurse;
    bit<5> flags;
    bit<3> version;
    bit<16> protocol;
    ipv4_addr_t vm_addr;
    switch_vpc_id_t vpcid;
}

// ERSPAN common header for type 2/3
header erspan_h {
    bit<16> version_vlan;
    bit<16> session_id; // include cos_en_t(6) and session_id(10)
}

// ERSPAN Type II -- IETFv3
header erspan_type2_h {
    bit<32> index; // include reserved(12) and index(20)
}

// ERSPAN Type III -- IETFv3
header erspan_type3_h {
    bit<32> timestamp;
    bit<32> ft_d_other;
    /*
    bit<16> sgt;    // Security group tag
    bit<1>  p;
    bit<5> ft;      // Frame type
    bit<6> hw_id;
    bit<1> d;       // Direction
    bit<2> gra;     // Timestamp granularity
    bit<1> o;       // Optional sub-header
    */
}

// ERSPAN platform specific subheader -- IETFv3
header erspan_platform_h {
    bit<6> id;
    bit<58> info;
}

// Barefoot Specific Headers.
header fabric_h {
    mac_addr_t dst_addr; //6 
    mac_addr_t src_addr; //6
    bit<16> ether_type; //2
    bit<16> tf_port_id;
    // bit<7> pad1;
}

header timestamp_h {
    bit<48> timestamp;
}

/*
* no use in stage and will be storaged in TPHV.
* used to prevent compile optimization only.
*/
header payload_frag_h {
    bit<16> data;
}





// ----------------------------------------------------------------------------
// Common protocols/types
//-----------------------------------------------------------------------------

//#define ETHERTYPE_QINQ 0x88A8 // Note: uncomment once ptf/scapy-vxlan are fixed

const bit<3> DPSR_RESBUMIT_TYPE = 0;
const mac_addr_t VXLAN_FAKE_SRC_MAC = 0x3cfdfe29cbc2;
const mac_addr_t VXLAN_FAKE_DST_MAC = 0x3cfdfe29cbd2;
// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------
typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;

typedef int<32> switch_int32_t;





typedef PortId_t switch_port_t;




typedef bit<16> switch_vrf_t;
const bit<32> SWITCH_VRF_SPEC_MAX = 4096;


typedef bit<32> switch_nexthop_t;


typedef bit<16> switch_hash_t;


typedef bit<16> switch_mss_t;
// diff between tcpMSS and MTU 



typedef bit<16> switch_mtu_t;
typedef bit<16> switch_tcp_checksum_t;

typedef bit<4> pkt_action_index_s;
const pkt_action_index_s PKT_ACTION_ACCEPT = 0;
const pkt_action_index_s PKT_ACTION_MIRROR = 1;
const pkt_action_index_s PKT_ACTION_DROP = 2;
const pkt_action_index_s PKT_ACTION_TO_CPU = 3;
const pkt_action_index_s PKT_ACTION_DIRECT_TO_PORT = 4;
const pkt_action_index_s PKT_ACTION_RESUBMIT = 5;
const pkt_action_index_s PKT_ACTION_IP_FRAG = 6;
const bit<32> PKT_ACTION_MAX_INDEX = 7;


typedef bit<8> switch_drop_reason_t;
const switch_drop_reason_t SWITCH_DROP_REASON_UNKNOWN = 0;
const switch_drop_reason_t SWITCH_DROP_REASON_DIP_NO_TERMINATE = 1;
const switch_drop_reason_t SWITCH_DROP_REASON_ETHERTYPE_NO_SUPPORT = 2;
const switch_drop_reason_t SWITCH_DROP_REASON_IPHDR_EXCEED_MAXLEN = 3;
const switch_drop_reason_t SWITCH_DROP_REASON_INNER_ETHERTYPE_NO_SUPPORT = 4;
const switch_drop_reason_t SWITCH_DROP_REASON_INNER_IPHDR_EXCEED_MAXLEN = 5;
const switch_drop_reason_t SWITCH_DROP_REASON_GRE_INNER_PROTO_NO_SUPPORT = 6;
const switch_drop_reason_t SWITCH_DROP_REASON_VALIDATION_FAIL = 7;
const switch_drop_reason_t SWITCH_DROP_REASON_TUNNEL_MAPPING_NO_VRF = 8;
const switch_drop_reason_t SWITCH_DROP_REASON_URPF_CHECK_FAIL = 9;
const switch_drop_reason_t SWITCH_DROP_REASON_NO_ROUTE = 10;
const switch_drop_reason_t SWITCH_DROP_REASON_RID_MAP_NH_FAIL =11;
const switch_drop_reason_t SWITCH_DROP_REASON_NO_NEXTHOP = 12;
const switch_drop_reason_t SWITCH_DROP_REASON_VNI_BUNDLE = 13;
const switch_drop_reason_t SWITCH_DROP_REASON_NO_INNER_NEIGHBOR = 14;
const switch_drop_reason_t SWITCH_DROP_REASON_NO_OUTER_NEIGHBOR = 15;
const switch_drop_reason_t SWITCH_DROP_REASON_GRE_SIP_NOT_SET = 16;
const switch_drop_reason_t SWITCH_DROP_REASON_FORWARD_VIP_NOT_SET = 17;
const switch_drop_reason_t SWITCH_DROP_REASON_NO_INNER_SMAC = 18;
const switch_drop_reason_t SWITCH_DROP_REASON_BFD_OVERSPEED = 19;
const switch_drop_reason_t SWITCH_DROP_REASON_BGP_OVERSPEED = 20;
const switch_drop_reason_t SWITCH_DROP_REASON_ARP_OVERSPEED = 21;
const switch_drop_reason_t SWITCH_DROP_REASON_OTHER_CPU_OVERSPEED = 22;
const switch_drop_reason_t SWITCH_DROP_REASON_CNTL_OVERSPEED = 23;
const switch_drop_reason_t SWITCH_DROP_REASON_ACL_DENY = 24;
const bit<32> SWITCH_DROP_REASON_MAX = 25;

struct switch_drop_flag_t {
    bool unknown;
    bool dip_no_terminate;
    bool ethertype_no_support;
    bool iphdr_exceed_maxlen;
    bool inner_ethertype_no_support;
    bool inner_iphdr_exceed_maxlen;
    bool gre_inner_proto_no_support;
    bool validation_fail;
    bool tunnel_mapping_no_vrf;
    bool urpf_check_fail;
    bool no_route;
    bool rid_map_nh_fail;
    bool no_nexthop;
    bool vni_bundel;
    bool no_inner_neighbor;
    bool no_outer_neighbor;
    bool gre_sip_no_set;
    bool forward_vip_no_set;
    bool no_inner_smac;
    bool bfd_overspeed;
    bool bgp_overspeed;
    bool arp_overspeed;
    bool other_cpu_overspeed;
    bool cntl_overspeed;
    bool acl_deny;
}

typedef bit<2> switch_ip_type_t;
const switch_ip_type_t SWITCH_IP_TYPE_NONE = 0;
const switch_ip_type_t SWITCH_IP_TYPE_IPV4 = 1;
const switch_ip_type_t SWITCH_IP_TYPE_IPV6 = 2;
const switch_ip_type_t SWITCH_IP_TYPE_MPLS = 3; // Consider renaming ip_type to l3_type

typedef bit<2> switch_ip_frag_t;
const switch_ip_frag_t SWITCH_IP_FRAG_NON_FRAG = 0b00; // Not fragmented.
const switch_ip_frag_t SWITCH_IP_FRAG_HEAD = 0b10; // First fragment of the fragmented packets.
const switch_ip_frag_t SWITCH_IP_FRAG_NON_HEAD = 0b11; // Fragment with non-zero offset.

typedef bit<16> switch_pkt_length_t;

typedef bit<8> switch_pkt_src_t;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED_PA_TO_PB = 0;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED_PB_RECIRC = 1;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED_PB_TO_PC = 2;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED_PC_RECIRC = 3;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED_PC_TO_PD = 4;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED_PD_RECIRC = 5;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED_PD_TO_PA = 6;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED_PB_TO_PA = 7;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED_URPF = 8;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED_CROSS_VRF = 9;
const switch_pkt_src_t SWITCH_PKT_SRC_INGRESS_CLONE = 10;
const switch_pkt_src_t SWITCH_PKT_SRC_EGRESS_CLONE = 11;
const switch_pkt_src_t SWITCH_PKT_SRC_IP_FRAG_1 = 12;
const switch_pkt_src_t SWITCH_PKT_SRC_IP_FRAG_2 = 13;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED_BYPASS = 14; // for to cpu and direct to port

typedef bit<2> switch_pkt_color_t;
const switch_pkt_color_t SWITCH_METER_COLOR_GREEN = 0;
const switch_pkt_color_t SWITCH_METER_COLOR_YELLOW = 1;
const switch_pkt_color_t SWITCH_METER_COLOR_RED = 3;

// resubmit
typedef bit<8> switch_resubmit_type_t;
const switch_resubmit_type_t SWITCH_RESUBMIT_TYPE_NONE = 0;
const switch_resubmit_type_t SWITCH_RESUBMIT_TYPE_URPF = 1;

typedef bit<8> switch_packet_type_t;




typedef bit<8> switch_meter_id_t;
const switch_meter_id_t SWITCH_METER_ID_CAPTURE = 1;
const switch_meter_id_t SWITCH_METER_ID_COPP_BFD = 2;
const switch_meter_id_t SWITCH_METER_ID_COPP_BGP = 3;
const switch_meter_id_t SWITCH_METER_ID_COPP_ARP = 4;
const switch_meter_id_t SWITCH_METER_ID_COPP_OTHER_CPU = 5;
const switch_meter_id_t SWITCH_METER_ID_COPP_CNTL = 6;

// Mirroring ------------------------------------------------------------------
//typedef MirrorId_t switch_mirror_session_t; // Defined in tna.p4
typedef bit<16> switch_mirror_session_t;
const switch_mirror_session_t SWITCH_MIRROR_SESSION_CPU = 250;

typedef bit<8> switch_mirror_type_t;

// Tunneling ------------------------------------------------------------------
typedef bit<3> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NONE = 0;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VXLAN = 1;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GRE = 2;
typedef bit<24> switch_tunnel_vni_t;

// neighbor ------------------------------------------------------------------

typedef bit<16> switch_neighbor_index_t;

// multicast
typedef MulticastGroupId_t switch_mgid_t;

// ----------------------------------------------------------------------------
// Common const values
//-----------------------------------------------------------------------------
const bit<32> EGRESS_PORT_REDIRECT_TABLE_SIZE = 512;
const bit<32> VRF_SIZE = 4096;


// ----------------------------------------------------------------------------
// Common struct
//-----------------------------------------------------------------------------
struct switch_port_metadata_t {
    switch_port_t egress_port;
}

@flexible
struct switch_tunnel_metadata_t {
    switch_tunnel_type_t type;
    bit<32> key;
    ipv4_addr_t vm_addr;
    ipv4_addr_t dst_addr;
    bit<2> gre_type; //1 -- gre1, 2 --- gre2
    switch_mtu_t mtu;
    bit<1> to_local;
}

struct switch_common_flags_t {
    bool ipv4_checksum_err;
    bool inner_ipv4_checksum_err;
    bool nottl;
    bool routed;
    bool gre_ver_set;
    bool inner_ipv4_checksum_update_en;
    bool tcp_checksum_odd;
    bool tcp_checksum_even;
    bool fragment_labeled;
}

struct switch_common_checks_t {
    bool urpf;
}

struct switch_cross_vrf_metadata_t {
    switch_tunnel_type_t tun_type;//3
    bit<32> tun_key;
}

@flexible
struct switch_lookup_fields_t {
    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<16> mac_type;
    bit<16> arp_opcode;

    switch_ip_type_t ip_type;
    bit<8> ip_proto;
    bit<8> ip_ttl;
    bit<8> ip_tos;
    switch_ip_frag_t ip_frag;
    bit<128> ip_src_addr;
    bit<128> ip_dst_addr;
    bit<20> ipv6_flow_label;

    bit<8> tcp_flags;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;
}

@flexible
struct switch_hash_fields_t {
    switch_ip_type_t ip_type;
    bit<8> ip_proto;
    bit<32> ip_src_addr;
    bit<32> ip_dst_addr;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;
    bit<20> ipv6_flow_label;
    switch_ip_type_t inner_ip_type;
    bit<8> inner_ip_proto;
    bit<128> inner_ip_src_addr;
    bit<128> inner_ip_dst_addr;
    bit<16> inner_l4_src_port;
    bit<16> inner_l4_dst_port;
    bit<20> inner_ipv6_flow_label;
}

struct mac_header {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

// ----------------------------------------------------------------------------
// Mirror Metadata
//-----------------------------------------------------------------------------
header switch_mirror_metadata_t {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    bit<32> timestamp;
    switch_mirror_session_t session_id;
}

// ----------------------------------------------------------------------------
// Resubmit Metadata
//-----------------------------------------------------------------------------
header switch_resubmit_metadata_h {
    switch_resubmit_type_t type;
}

// ----------------------------------------------------------------------------
// Common Metadata
//-----------------------------------------------------------------------------
@flexible
struct switch_common_metadata_t {
    switch_pkt_src_t pkt_src;
    pkt_action_index_s pkt_action;
    switch_pkt_length_t pkt_length;

    switch_port_t port;
    switch_port_t egress_port;

    switch_lookup_fields_t lkp;
    switch_hash_fields_t hash_fields;
    switch_tunnel_metadata_t tunnel;
    switch_mirror_metadata_t mirror;

    switch_vrf_t vrf;
    switch_nexthop_t nexthop;
    switch_mgid_t mgid;
    switch_neighbor_index_t inner_neighbor_index;
    switch_tunnel_vni_t ingress_vni;//24
    switch_hash_t inner_five_tuples_hash;//16
    switch_hash_t vxlan_src_port_hash;//16

    switch_drop_flag_t drop_reason; //25
    switch_meter_id_t meter_index;
    switch_pkt_color_t color;
    bool sample_flag;
    bool first_fragment_flag;
    switch_tcp_checksum_t origin_tcp_checksum;
}





const bit<9> PORT_PCI_CPU = 320;

struct switch_ingress_flags_t {
    switch_common_flags_t common;
}

struct switch_egress_flags_t {
    switch_common_flags_t common;
}

struct switch_ingress_checks_t {
    switch_common_checks_t common;
}

struct switch_egress_checks_t {
    switch_common_checks_t common;
}

// ----------------------------------------------------------------------------
// PA Ingress TO PB Egress Metadata
//-----------------------------------------------------------------------------
@flexible
struct switch_bridged_pa_to_pb_metadata_t {
    switch_port_t ig_port;
}
header switch_bridged_pa_to_pb_metadata_h {
    switch_pkt_src_t src;
    switch_bridged_pa_to_pb_metadata_t base;
}

// ----------------------------------------------------------------------------
// PB Egress TO PB Ingress Metadata
//-----------------------------------------------------------------------------
@flexible
struct switch_bridged_pb_recirc_metadata_t {
    pkt_action_index_s pkt_action;//4
    switch_vrf_t vrf;//16
    switch_hash_t inner_five_tuples_hash;//16
    switch_hash_t vxlan_src_port_hash;//16
    switch_ip_type_t ip_type;
    bit<128> lkp_ip_addr;
    bool urpf;
    switch_drop_flag_t drop_reason;
    switch_port_t ig_port;
}

//fake_header: for ingress pipeline, before parser, mac hw will check L2 header
//if ether_type < 0x0600, then frame is 802.3, ehter_type represents length in fact,
//if this not equal pkt len will drop because FramesReceivedwithLengthError
//so we set this filed > 0x0600, then frame is Ethernet that is valid.
//profile_b egress recirc profile_b ingress (37byte)
header switch_bridged_pb_recirc_metadata_h {
    mac_header fake_header;//14 * 8
    switch_pkt_src_t src;//8
    switch_bridged_pb_recirc_metadata_t base;
}

// ----------------------------------------------------------------------------
// PB Ingress TO PC Egress Metadata
//-----------------------------------------------------------------------------
@flexible
struct switch_bridged_pb_to_pc_metadata_t {
    pkt_action_index_s pkt_action;//4
    switch_vrf_t vrf;//16
    switch_hash_t inner_five_tuples_hash;//16
    switch_hash_t vxlan_src_port_hash;//16
    switch_ip_type_t ip_type;
    bit<128> lkp_ip_addr;
    switch_nexthop_t nexthop;
    bool urpf;
    bool nottl;
    switch_drop_flag_t drop_reason;
    switch_port_t ig_port;
}

header switch_bridged_pb_to_pc_metadata_h {
    switch_pkt_src_t src;//8
    switch_bridged_pb_to_pc_metadata_t base;
}


// ----------------------------------------------------------------------------
// PC Egress TO PC Ingress Metadata
//-----------------------------------------------------------------------------
@flexible
struct switch_bridged_pc_recirc_metadata_t {
    pkt_action_index_s pkt_action;//4
    switch_vrf_t vrf;//16
    switch_hash_t inner_five_tuples_hash;//16
    switch_hash_t vxlan_src_port_hash;//16
    bool urpf;
    bool nottl;
    switch_nexthop_t nexthop;
    switch_drop_flag_t drop_reason;
    switch_port_t ig_port;
}

header switch_bridged_pc_recirc_metadata_h {
    mac_header fake_header;//14 * 8
    switch_pkt_src_t src;//8
    switch_bridged_pc_recirc_metadata_t base;
}

// ----------------------------------------------------------------------------
// PC Ingress TO PD Egress Metadata
//-----------------------------------------------------------------------------
@flexible
struct switch_bridged_pc_to_pd_metadata_t {
    pkt_action_index_s pkt_action;//4
    switch_vrf_t vrf;//16
    switch_hash_t inner_five_tuples_hash;//16
    switch_hash_t vxlan_src_port_hash;//16
    switch_nexthop_t nexthop;
    switch_mgid_t mgid;
    switch_port_t ig_port;
}

header switch_bridged_pc_to_pd_metadata_h {
    switch_pkt_src_t src;//8
    switch_bridged_pc_to_pd_metadata_t base;
}

// ----------------------------------------------------------------------------
// PD Egress TO PD Ingress Metadata
//-----------------------------------------------------------------------------
@flexible
struct switch_bridged_pd_recirc_metadata_t {
    pkt_action_index_s pkt_action;//4
    switch_vrf_t vrf;//16
    switch_hash_t inner_five_tuples_hash;//16
    switch_hash_t vxlan_src_port_hash;//16
    switch_neighbor_index_t inner_neighbor_index;//16 inner neighbour
    switch_tunnel_type_t tun_type;//3
    bit<2> gre_type; //2: 1 -- gre1, 2 --- gre2
    bit<32> tun_key;
    ipv4_addr_t vm_addr;//32
    ipv4_addr_t tun_dst_addr;//32
    bit<1> tunnel_to_local;
    switch_drop_flag_t drop_reason;
    switch_port_t ig_port;
    switch_mtu_t mtu;//16
}

header switch_bridged_pd_recirc_metadata_h {
    mac_header fake_header;//14 * 8
    switch_pkt_src_t src;//8
    switch_bridged_pd_recirc_metadata_t base;
}

// ----------------------------------------------------------------------------
// PD Ingress TO PA Egress Metadata
//-----------------------------------------------------------------------------
@flexible
struct switch_bridged_pd_to_pa_metadata_t {
    pkt_action_index_s pkt_action;//4
    switch_vrf_t vrf;//16
    switch_hash_t inner_five_tuples_hash;//16
    switch_hash_t vxlan_src_port_hash;//16
    switch_neighbor_index_t inner_neighbor_index;//16 inner neighbour
    switch_tunnel_type_t tun_type;//3
    bit<2> gre_type; //2: 1 -- gre1, 2 --- gre2
    bit<32> tun_key;
    ipv4_addr_t vm_addr;//32
    ipv4_addr_t tun_dst_addr;//32
    switch_drop_flag_t drop_reason;
    switch_port_t ig_port;
    bit<16> inner_l4_src_port;
    bit<16> inner_l4_dst_port;
}

header switch_bridged_pd_to_pa_metadata_h {
    switch_pkt_src_t src;//8
    switch_bridged_pd_to_pa_metadata_t base;
}

// ----------------------------------------------------------------------------
// URPF metadata, PC Ingress To PB Egress
//-----------------------------------------------------------------------------
@flexible
struct switch_bridged_urpf_metadata_t {
    switch_port_t ig_port;
}
header switch_bridged_urpf_metadata_h {
    switch_pkt_src_t src;//8
    switch_bridged_urpf_metadata_t base;
}

// ----------------------------------------------------------------------------
// cross vrf metadata, PD Ingress To PB Egress
//-----------------------------------------------------------------------------
@flexible
struct switch_bridged_cross_vrf_metadata_t {
    switch_tunnel_type_t tun_type;//3
    bit<32> tun_key;
    switch_port_t ig_port;
}

//profile crossvrf metadata
header switch_bridged_cross_vrf_metadata_h {
    switch_pkt_src_t src;//8
    switch_bridged_cross_vrf_metadata_t base;
}

// ----------------------------------------------------------------------------
// for to cpu or direct to port metadata
//-----------------------------------------------------------------------------
@flexible
struct switch_bridged_bypass_metadata_t {
    pkt_action_index_s pkt_action;//8
}

//for to cpu or direct to port
header switch_bridged_bypass_metadata_h {
    switch_pkt_src_t src;//8
    switch_bridged_bypass_metadata_t base;
}

// ----------------------------------------------------------------------------
// Ingress Metadata
//-----------------------------------------------------------------------------
@pa_auto_init_metadata
@pa_alias("ingress", "ig_md.common.egress_port", "ig_intr_md_for_tm.ucast_egress_port")
@pa_alias("ingress", "ig_intr_md_for_dprsr.mirror_type", "ig_md.common.mirror.type")
struct switch_ingress_metadata_t {
    switch_common_metadata_t common;
    switch_ingress_flags_t flags;
    switch_ingress_checks_t checks;
}

// ----------------------------------------------------------------------------
// Egress Metadata
//-----------------------------------------------------------------------------
@pa_auto_init_metadata
@pa_alias("egress", "eg_intr_md_for_dprsr.mirror_type", "eg_md.common.mirror.type")
struct switch_egress_metadata_t {
    switch_common_metadata_t common;
    switch_cross_vrf_metadata_t cross_vrf_data;
    switch_egress_checks_t checks;
    switch_egress_flags_t flags;
}

// ----------------------------------------------------------------------------
// Switch Header
//-----------------------------------------------------------------------------
@pa_no_overlay("egress", "hdr.bridged_pb_recirc.src")
@pa_no_overlay("egress", "hdr.bridged_pb_recirc.base_pkt_action")
@pa_no_overlay("egress", "hdr.bridged_pb_recirc.base_vrf")
@pa_no_overlay("egress", "hdr.bridged_pb_recirc.base_inner_five_tuples_hash")
@pa_no_overlay("egress", "hdr.bridged_pb_recirc.base_vxlan_src_port_hash")
@pa_no_overlay("egress", "hdr.bridged_pb_recirc.base_ip_type")
@pa_no_overlay("egress", "hdr.bridged_pb_recirc.base_lkp_ip_addr")
@pa_no_overlay("egress", "hdr.bridged_pb_recirc.fake_header_ether_type")

@pa_no_overlay("egress", "hdr.bridged_pc_recirc.src")
@pa_no_overlay("egress", "hdr.bridged_pc_recirc.base_pkt_action")
@pa_no_overlay("egress", "hdr.bridged_pc_recirc.base_vrf")
@pa_no_overlay("egress", "hdr.bridged_pc_recirc.base_inner_five_tuples_hash")
@pa_no_overlay("egress", "hdr.bridged_pc_recirc.base_vxlan_src_port_hash")
@pa_no_overlay("egress", "hdr.bridged_pc_recirc.base_nexthop")
@pa_no_overlay("egress", "hdr.bridged_pc_recirc.base_urpf")
@pa_no_overlay("egress", "hdr.bridged_pc_recirc.fake_header_ether_type")

@pa_no_overlay("egress", "hdr.bridged_pd_recirc.src")
@pa_no_overlay("egress", "hdr.bridged_pd_recirc.base_pkt_action")
@pa_no_overlay("egress", "hdr.bridged_pd_recirc.base_vrf")
@pa_no_overlay("egress", "hdr.bridged_pd_recirc.base_inner_five_tuples_hash")
@pa_no_overlay("egress", "hdr.bridged_pd_recirc.base_vxlan_src_port_hash")
@pa_no_overlay("egress", "hdr.bridged_pd_recirc.base_inner_neighbor_index")
@pa_no_overlay("egress", "hdr.bridged_pd_recirc.base_tun_type")
@pa_no_overlay("egress", "hdr.bridged_pd_recirc.base_gre_type")
@pa_no_overlay("egress", "hdr.bridged_pd_recirc.base_tun_key")
@pa_no_overlay("egress", "hdr.bridged_pd_recirc.base_vm_addr")
@pa_no_overlay("egress", "hdr.bridged_pd_recirc.base_tun_dst_addr")

@pa_no_overlay("ingress", "hdr.fabric.dst_addr")
@pa_no_overlay("ingress", "hdr.fabric.src_addr")
@pa_no_overlay("ingress", "hdr.fabric.ether_type")
@pa_no_overlay("ingress", "hdr.fabric.tf_port_id")
struct switch_header_t {
    switch_bridged_pa_to_pb_metadata_h bridged_pa_to_pb;
    switch_bridged_pb_recirc_metadata_h bridged_pb_recirc;
    switch_bridged_pb_to_pc_metadata_h bridged_pb_to_pc;
    switch_bridged_pc_recirc_metadata_h bridged_pc_recirc;
    switch_bridged_pc_to_pd_metadata_h bridged_pc_to_pd;
    switch_bridged_pd_recirc_metadata_h bridged_pd_recirc;
    switch_bridged_pd_to_pa_metadata_h bridged_pd_to_pa;
    switch_bridged_urpf_metadata_h bridged_urpf;
    switch_bridged_cross_vrf_metadata_h bridged_cross_vrf;
    switch_bridged_bypass_metadata_h bridged_bypass;
    // switch_mirror_metadata_h mirror;
    fabric_h fabric;
    ethernet_h ethernet;
    ipv4_h ipv4;
    ipv4_option_h ip_opt_word_1;
    ipv4_option_h ip_opt_word_2;
    ipv4_option_h ip_opt_word_3;
    ipv4_option_h ip_opt_word_4;
    ipv4_option_h ip_opt_word_5;
    ipv4_option_h ip_opt_word_6;
    ipv4_option_h ip_opt_word_7;
    ipv4_option_h ip_opt_word_8;
    ipv4_option_h ip_opt_word_9;
    ipv4_option_h ip_opt_word_10;
    ipv6_h ipv6;
    gre_vpc1_h gre1;
    gre_vpc2_h gre2;
    arp_h arp;
    udp_h udp;
    icmp_h icmp;
    tcp_h tcp;
    tcp_option_4b_h[10] tcp_options_4b_before;
    tcp_option_2b_h tcp_options_2b_before;
    tcp_option_1b_h tcp_options_1b_before;
    tcp_option_mss_h tcp_options_mss;
    vxlan_h vxlan;
    erspan_h erspan;
    erspan_type2_h erspan_type2;
    erspan_type3_h erspan_type3;
    erspan_platform_h erspan_platform;
    ethernet_h inner_ethernet;
    arp_h inner_arp;
    ipv4_h inner_ipv4;
    ipv4_option_h inner_ip_opt_word_1;
    ipv4_option_h inner_ip_opt_word_2;
    ipv4_option_h inner_ip_opt_word_3;
    ipv4_option_h inner_ip_opt_word_4;
    ipv4_option_h inner_ip_opt_word_5;
    ipv4_option_h inner_ip_opt_word_6;
    ipv4_option_h inner_ip_opt_word_7;
    ipv4_option_h inner_ip_opt_word_8;
    ipv4_option_h inner_ip_opt_word_9;
    ipv4_option_h inner_ip_opt_word_10;
    ipv6_h inner_ipv6;
    udp_h inner_udp;
    tcp_h inner_tcp;
    icmp_h inner_icmp;
    payload_frag_h payload_frag;
}

action add_bridged_pa_to_pb_md(inout switch_bridged_pa_to_pb_metadata_h bridge_pa_to_pb,
                      in switch_common_metadata_t switch_md) {

    bridge_pa_to_pb.setValid();
    bridge_pa_to_pb.src = SWITCH_PKT_SRC_BRIDGED_PA_TO_PB;
    bridge_pa_to_pb.base.ig_port = switch_md.port;
}

action add_bridged_pb_recirc_md(inout switch_bridged_pb_recirc_metadata_h bridge_pb_recirc,
                    in switch_common_metadata_t switch_md, switch_common_checks_t switch_checks) {
    bridge_pb_recirc.setValid();
    bridge_pb_recirc.fake_header.ether_type = 0x0800;//must set >= 0x0600
    bridge_pb_recirc.src = SWITCH_PKT_SRC_BRIDGED_PB_RECIRC;

    bridge_pb_recirc.base.pkt_action = switch_md.pkt_action;
    bridge_pb_recirc.base.vrf = switch_md.vrf;
    bridge_pb_recirc.base.ig_port = switch_md.port;
    bridge_pb_recirc.base.inner_five_tuples_hash = switch_md.inner_five_tuples_hash;
    bridge_pb_recirc.base.vxlan_src_port_hash = switch_md.vxlan_src_port_hash;
    bridge_pb_recirc.base.ip_type = switch_md.lkp.ip_type;
    bridge_pb_recirc.base.lkp_ip_addr = switch_md.lkp.ip_dst_addr;
    bridge_pb_recirc.base.urpf = switch_checks.urpf;
    bridge_pb_recirc.base.drop_reason = switch_md.drop_reason;
}

action add_bridged_pb_to_pc_md(inout switch_bridged_pb_to_pc_metadata_h bridge_pb_to_pc,
                    in switch_common_metadata_t switch_md, in switch_common_flags_t switch_flags, switch_common_checks_t switch_checks) {
    bridge_pb_to_pc.setValid();
    bridge_pb_to_pc.src = SWITCH_PKT_SRC_BRIDGED_PB_TO_PC;

    bridge_pb_to_pc.base.pkt_action = switch_md.pkt_action;
    bridge_pb_to_pc.base.vrf = switch_md.vrf;
    bridge_pb_to_pc.base.ig_port = switch_md.port;
    bridge_pb_to_pc.base.inner_five_tuples_hash = switch_md.inner_five_tuples_hash;
    bridge_pb_to_pc.base.vxlan_src_port_hash = switch_md.vxlan_src_port_hash;
    bridge_pb_to_pc.base.ip_type = switch_md.lkp.ip_type;
    bridge_pb_to_pc.base.lkp_ip_addr = switch_md.lkp.ip_dst_addr;
    bridge_pb_to_pc.base.nexthop = switch_md.nexthop;
    bridge_pb_to_pc.base.urpf = switch_checks.urpf;
    bridge_pb_to_pc.base.drop_reason = switch_md.drop_reason;
    bridge_pb_to_pc.base.nottl = switch_flags.nottl;
}

action add_bridged_pc_recirc_md(inout switch_bridged_pc_recirc_metadata_h bridge_pc_recirc,
                    in switch_common_metadata_t switch_md, in switch_common_flags_t switch_flags, switch_common_checks_t switch_checks) {
    bridge_pc_recirc.setValid();
    bridge_pc_recirc.fake_header.ether_type = 0x0800;//must set >= 0x0600
    bridge_pc_recirc.src = SWITCH_PKT_SRC_BRIDGED_PC_RECIRC;

    bridge_pc_recirc.base.pkt_action = switch_md.pkt_action;
    bridge_pc_recirc.base.vrf = switch_md.vrf;
    bridge_pc_recirc.base.ig_port = switch_md.port;
    bridge_pc_recirc.base.inner_five_tuples_hash = switch_md.inner_five_tuples_hash;
    bridge_pc_recirc.base.vxlan_src_port_hash = switch_md.vxlan_src_port_hash;
    bridge_pc_recirc.base.nexthop = switch_md.nexthop;
    bridge_pc_recirc.base.urpf = switch_checks.urpf;
    bridge_pc_recirc.base.drop_reason = switch_md.drop_reason;
    bridge_pc_recirc.base.nottl = switch_flags.nottl;
}

action add_bridged_pc_to_pd_md(inout switch_header_t hdr_pc_to_pd,
                    in switch_common_metadata_t switch_md) {
    hdr_pc_to_pd.fabric.setInvalid();
    hdr_pc_to_pd.bridged_pc_to_pd.setValid();
    hdr_pc_to_pd.bridged_pc_to_pd.src = SWITCH_PKT_SRC_BRIDGED_PC_TO_PD;

    hdr_pc_to_pd.bridged_pc_to_pd.base.ig_port = switch_md.port;
    hdr_pc_to_pd.bridged_pc_to_pd.base.pkt_action = switch_md.pkt_action;
    hdr_pc_to_pd.bridged_pc_to_pd.base.vrf = switch_md.vrf;
    hdr_pc_to_pd.bridged_pc_to_pd.base.inner_five_tuples_hash = switch_md.inner_five_tuples_hash;
    hdr_pc_to_pd.bridged_pc_to_pd.base.vxlan_src_port_hash = switch_md.vxlan_src_port_hash;
    hdr_pc_to_pd.bridged_pc_to_pd.base.nexthop = switch_md.nexthop;
    hdr_pc_to_pd.bridged_pc_to_pd.base.mgid = switch_md.mgid;
}

action add_bridged_pd_recirc_md(inout switch_bridged_pd_recirc_metadata_h bridge_pd_recirc,
                    in switch_common_metadata_t switch_md) {
    bridge_pd_recirc.setValid();
    bridge_pd_recirc.fake_header.ether_type = 0x0800;//must set >= 0x0600
    bridge_pd_recirc.src = SWITCH_PKT_SRC_BRIDGED_PD_RECIRC;

    bridge_pd_recirc.base.ig_port = switch_md.port;
    bridge_pd_recirc.base.pkt_action = switch_md.pkt_action;
    bridge_pd_recirc.base.vrf = switch_md.vrf;
    bridge_pd_recirc.base.inner_five_tuples_hash = switch_md.inner_five_tuples_hash;
    bridge_pd_recirc.base.vxlan_src_port_hash = switch_md.vxlan_src_port_hash;
    bridge_pd_recirc.base.tun_type = switch_md.tunnel.type;
    bridge_pd_recirc.base.gre_type = switch_md.tunnel.gre_type;
    bridge_pd_recirc.base.tun_key = switch_md.tunnel.key;
    bridge_pd_recirc.base.vm_addr = switch_md.tunnel.vm_addr;
    bridge_pd_recirc.base.tun_dst_addr = switch_md.tunnel.dst_addr;
    bridge_pd_recirc.base.inner_neighbor_index = switch_md.inner_neighbor_index;
    bridge_pd_recirc.base.tunnel_to_local = switch_md.tunnel.to_local;
    bridge_pd_recirc.base.drop_reason = switch_md.drop_reason;
    bridge_pd_recirc.base.mtu = switch_md.tunnel.mtu;
}

action add_bridged_pd_to_pa_md(inout switch_bridged_pd_to_pa_metadata_h bridge_pd_to_pa,
                    in switch_common_metadata_t switch_md) {
    bridge_pd_to_pa.setValid();
    bridge_pd_to_pa.src = SWITCH_PKT_SRC_BRIDGED_PD_TO_PA;

    bridge_pd_to_pa.base.ig_port = switch_md.port;
    bridge_pd_to_pa.base.pkt_action = switch_md.pkt_action;
    bridge_pd_to_pa.base.vrf = switch_md.vrf;
    bridge_pd_to_pa.base.inner_five_tuples_hash = switch_md.inner_five_tuples_hash;
    bridge_pd_to_pa.base.vxlan_src_port_hash = switch_md.vxlan_src_port_hash;
    bridge_pd_to_pa.base.tun_type = switch_md.tunnel.type;
    bridge_pd_to_pa.base.gre_type = switch_md.tunnel.gre_type;
    bridge_pd_to_pa.base.tun_key = switch_md.tunnel.key;
    bridge_pd_to_pa.base.vm_addr = switch_md.tunnel.vm_addr;
    bridge_pd_to_pa.base.tun_dst_addr = switch_md.tunnel.dst_addr;
    bridge_pd_to_pa.base.inner_neighbor_index = switch_md.inner_neighbor_index;
    bridge_pd_to_pa.base.drop_reason = switch_md.drop_reason;
    bridge_pd_to_pa.base.inner_l4_src_port = switch_md.lkp.l4_src_port;
    bridge_pd_to_pa.base.inner_l4_dst_port = switch_md.lkp.l4_dst_port;
}

action add_bridged_urpf_md(inout switch_bridged_urpf_metadata_h bridge_urpf,
                            in switch_common_metadata_t switch_md) {
    bridge_urpf.setValid();
    bridge_urpf.src = SWITCH_PKT_SRC_BRIDGED_URPF;
    bridge_urpf.base.ig_port = switch_md.port;
}

action add_bridged_cross_vrf_md(inout switch_bridged_cross_vrf_metadata_h bridged_md_cross,
                    in switch_common_metadata_t switch_md) {
    bridged_md_cross.setValid();
    bridged_md_cross.src = SWITCH_PKT_SRC_BRIDGED_CROSS_VRF;
    bridged_md_cross.base.tun_type = switch_md.tunnel.type;
    bridged_md_cross.base.tun_key = switch_md.tunnel.key;
    bridged_md_cross.base.ig_port = switch_md.port;
}

action add_bridged_bypass_md(inout switch_header_t hdr_bypass,
                    in switch_common_metadata_t switch_md) {
    hdr_bypass.bridged_bypass.setValid();
    hdr_bypass.bridged_bypass.src = SWITCH_PKT_SRC_BRIDGED_BYPASS;
    hdr_bypass.bridged_bypass.base.pkt_action = switch_md.pkt_action;
}





action ig_real_drop(inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
    ig_intr_md_for_dprs.drop_ctl = 0x1;
}

action ig_resubmit(inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    ig_intr_md_for_dprsr.resubmit_type = DPSR_RESBUMIT_TYPE;
}

action ig_multicast(inout ingress_intrinsic_metadata_for_tm_t ig_tm_md, bit<16> mcast_grp, bit<13> l2_mcast_hash) {
    ig_tm_md.mcast_grp_a = mcast_grp;
    ig_tm_md.level2_mcast_hash = l2_mcast_hash;
}

action eg_real_drop(inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    eg_intr_md_for_dprsr.drop_ctl = 0x1;
}

action cpu_rewrite(inout switch_header_t hdr, bit<16> ingress_port) {
    hdr.fabric.setValid();
    hdr.fabric.ether_type = 0x9000;
    hdr.fabric.tf_port_id = ingress_port;
}






//-----------------------------------------------------------------------------
// Tunnel decapsulation
//-----------------------------------------------------------------------------
control TunnelDecap(inout switch_header_t hdr,
                    in switch_common_metadata_t switch_md)() {

    action copy_ipv4_header() {
        hdr.ipv4.setValid();
        hdr.ipv4.version = hdr.inner_ipv4.version;
        hdr.ipv4.ihl = hdr.inner_ipv4.ihl;
        hdr.ipv4.total_len = hdr.inner_ipv4.total_len;
        hdr.ipv4.identification = hdr.inner_ipv4.identification;
        hdr.ipv4.flag_rs = hdr.inner_ipv4.flag_rs;
        hdr.ipv4.flag_df = hdr.inner_ipv4.flag_df;
        hdr.ipv4.flag_mf = hdr.inner_ipv4.flag_mf;
        hdr.ipv4.frag_offset = hdr.inner_ipv4.frag_offset;
        hdr.ipv4.protocol = hdr.inner_ipv4.protocol;
        hdr.ipv4.ttl = hdr.inner_ipv4.ttl;
        // hdr.ipv4.hdr_checksum = hdr.inner_ipv4.hdr_checksum;
        hdr.ipv4.src_addr = hdr.inner_ipv4.src_addr;
        hdr.ipv4.dst_addr = hdr.inner_ipv4.dst_addr;

        hdr.inner_ipv4.setInvalid();
    }

    action invalidate_vxlan_header() {
        hdr.vxlan.setInvalid();
    }
    action invalidate_udp_header() {
        hdr.udp.setInvalid();
    }

    action invalidate_gre1_header() {
        hdr.gre1.setInvalid();
    }

    action invalidate_gre2_header() {
        hdr.gre2.setInvalid();
    }

    action decap_vxlan_inner_ipv4() {
        hdr.ethernet = hdr.inner_ethernet;
        copy_ipv4_header();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_vxlan_header();
     invalidate_udp_header();
    }

    action decap_gre1_inner_ipv4() {
        hdr.ethernet.ether_type = 0x0800;
        copy_ipv4_header();
        hdr.ipv6.setInvalid();
        invalidate_gre1_header();
    }

    action decap_gre2_inner_ipv4() {
        hdr.ethernet.ether_type = 0x0800;
        copy_ipv4_header();
        hdr.ipv6.setInvalid();
        invalidate_gre2_header();
    }

    table decap_tunnel_hdr {
        key = {
            hdr.gre1.isValid() : exact;
            hdr.gre2.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.vxlan.isValid(): exact;
            hdr.inner_ethernet.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
        }

        actions = {
            decap_vxlan_inner_ipv4;
            decap_gre1_inner_ipv4;
            decap_gre2_inner_ipv4;
        }

        const entries = {
            (false, false, true, true, true, true) : decap_vxlan_inner_ipv4;
            (true, false, false, false, false, true) : decap_gre1_inner_ipv4;
            (false, true, false, false, false, true) : decap_gre2_inner_ipv4;
        }
        size = 8;
    }

    apply {
        decap_tunnel_hdr.apply();
    }
}



//-----------------------------------------------------------------------------
// Tunnel Nexthop
//-----------------------------------------------------------------------------
control TunnelNexthop(inout switch_header_t hdr,
                      inout switch_common_metadata_t switch_md)
                      (switch_uint32_t tunnel_nexthop_table_size) {

    action encap_vxlan(switch_tunnel_vni_t vni, ipv4_addr_t dst_addr,
                            switch_neighbor_index_t neighbor_index, switch_mtu_t mtu,
                            bool to_local) {
        switch_md.tunnel.type = SWITCH_TUNNEL_TYPE_VXLAN;
        switch_md.tunnel.key[23:0] = vni;
        switch_md.tunnel.dst_addr = dst_addr;
        switch_md.tunnel.to_local = (bit<1>)to_local;
        switch_md.tunnel.mtu = mtu;
        switch_md.inner_neighbor_index = neighbor_index;
    }

    action encap_gre(switch_vpc_id_t vpcid, ipv4_addr_t dst_addr, switch_mtu_t mtu, bool to_local) {
        switch_md.tunnel.type = SWITCH_TUNNEL_TYPE_GRE;
        switch_md.tunnel.gre_type = 1;
        switch_md.tunnel.key = vpcid;
        switch_md.tunnel.vm_addr = 0;
        switch_md.tunnel.to_local = (bit<1>)to_local;
        switch_md.tunnel.mtu = mtu;
        switch_md.tunnel.dst_addr = dst_addr;
    }

    action encap_gre_with_vm(switch_vpc_id_t vpcid, ipv4_addr_t dst_addr,
                                ipv4_addr_t vm_addr, switch_mtu_t mtu, bool to_local) {
        switch_md.tunnel.type = SWITCH_TUNNEL_TYPE_GRE;
        switch_md.tunnel.gre_type = 2;
        switch_md.tunnel.key = vpcid;
        switch_md.tunnel.vm_addr = vm_addr;
        switch_md.tunnel.to_local = (bit<1>)to_local;
        switch_md.tunnel.mtu = mtu;
        switch_md.tunnel.dst_addr = dst_addr;
    }

    action drop_pkt() {
        switch_md.pkt_action = PKT_ACTION_DROP;
        switch_md.drop_reason.no_nexthop = true;
    }

    @pack(4)
    table tunnel_nexthop {
        key = { switch_md.nexthop : exact; }
        actions = {
            drop_pkt;
            encap_vxlan;
            encap_gre;
            encap_gre_with_vm;
        }

        const default_action = drop_pkt;
        size = tunnel_nexthop_table_size;
    }

    apply {
        tunnel_nexthop.apply();
    }
}

//-----------------------------------------------------------------------------
// inner rewrite
//-----------------------------------------------------------------------------
control InnerRewrite(inout switch_header_t hdr,
                        inout switch_common_metadata_t switch_md,
                        inout switch_common_flags_t switch_flags)(
                        switch_uint32_t vni_bundle_table_size,
                        switch_uint32_t inner_neigh_table_size,
                        switch_uint32_t vrf_size) {

    action dec_8(inout bit<8> ttl) {
        ttl = ttl - 1;
    }

    action set_inner_neighbor(mac_addr_t dmac) {
        hdr.ethernet.dst_addr = dmac;
    }
    action no_inner_neighbor() {
        switch_md.pkt_action = PKT_ACTION_DROP;
        switch_md.drop_reason.no_inner_neighbor = true;
    }

    table inner_neighbor {
        key = { switch_md.inner_neighbor_index : exact; }
        actions = {
            no_inner_neighbor;
            set_inner_neighbor;
        }

        const default_action = no_inner_neighbor;
        size = inner_neigh_table_size;
    }

    action no_inner_smac() {
        switch_md.pkt_action = PKT_ACTION_DROP;
        switch_md.drop_reason.no_inner_smac = true;
    }
    action set_inner_smac(mac_addr_t fake_smac) {
        hdr.ethernet.src_addr = fake_smac;
    }

    table inner_smac {
        key = { switch_md.vrf : exact; }
        actions = {
            no_inner_smac;
            set_inner_smac;
        }

        const default_action = no_inner_smac;
        size = vrf_size;
    }

    action set_vni_bundle() {
        switch_md.pkt_action = PKT_ACTION_DROP;
        switch_md.drop_reason.vni_bundel = true;
    }

    table vni_bundle {
        key = {
            switch_md.vrf : exact;
            switch_md.ingress_vni : exact;
            switch_md.tunnel.key : exact; }
        actions = {
            set_vni_bundle;
            NoAction;
        }

        const default_action = NoAction;
        size = vni_bundle_table_size;
    }

    apply {
        switch(vni_bundle.apply().action_run) {
            NoAction : {
                if (switch_flags.nottl == false) {
                    dec_8(hdr.ipv4.ttl);
                }
                if (switch_md.tunnel.type == SWITCH_TUNNEL_TYPE_VXLAN) {
                    inner_neighbor.apply();
                    inner_smac.apply();
                }
            }
        }
    }
}

//-----------------------------------------------------------------------------
// Tunnel Encap
//-----------------------------------------------------------------------------
control TunnelEncap(inout switch_header_t hdr,
                    inout switch_common_metadata_t switch_md,
                    inout switch_common_flags_t switch_flags)() {
    bit<16> payload_len;


    action add_udp_header(bit<16> src_port, bit<16> dst_port) {
        hdr.udp.setValid();
        hdr.udp.src_port = src_port;
        hdr.udp.dst_port = dst_port;
        hdr.udp.checksum = 0;
    }

    action add_vxlan_header(bit<24> vni) {
        hdr.vxlan.setValid();
        hdr.vxlan.flags = 8w0x08;
        // hdr.vxlan.reserved = 0;
        hdr.vxlan.vni = vni;
    }

    action add_gre1_header(switch_vpc_id_t vpcid, bit<16> proto) {
        hdr.gre1.setValid();
        hdr.gre1.C = 0;
        hdr.gre1.R = 0;
        hdr.gre1.K = 1;
        hdr.gre1.S = 0;
        hdr.gre1.s = 0;
        hdr.gre1.recurse = 0;
        hdr.gre1.flags = 0;
        hdr.gre1.version = 0;
        hdr.gre1.protocol = proto;
        hdr.gre1.vpcid = vpcid;
    }

    action add_gre2_header(switch_vpc_id_t vpcid, bit<16> proto, ipv4_addr_t vm_addr) {
        hdr.gre2.setValid();
        hdr.gre2.C = 1;
        hdr.gre2.R = 0;
        hdr.gre2.K = 1;
        hdr.gre2.S = 0;
        hdr.gre2.s = 0;
        hdr.gre2.recurse = 0;
        hdr.gre2.flags = 0;
        hdr.gre2.version = 0;
        hdr.gre2.protocol = proto;
        hdr.gre2.vm_addr = vm_addr;
        hdr.gre2.vpcid = vpcid;
    }


    action add_ipv4_header(bit<8> proto) {
        hdr.ipv4.setValid();
        hdr.ipv4.version = 4w4;
        hdr.ipv4.ihl = 4w5;
        // hdr.ipv4.total_len = 0;
        hdr.ipv4.identification = 0;
        hdr.ipv4.ttl = 0xff;
        hdr.ipv4.flag_rs = 0;
        hdr.ipv4.flag_df = 0;
        hdr.ipv4.flag_mf = 0;
        hdr.ipv4.frag_offset = 0;
        hdr.ipv4.protocol = proto;
    }

    action copy_ipv4_header() {
        // Copy all of the IPv4 header fields.
        hdr.inner_ipv4.setValid();
        hdr.inner_ipv4.version = hdr.ipv4.version;
        hdr.inner_ipv4.ihl = hdr.ipv4.ihl;
        hdr.inner_ipv4.diffserv = hdr.ipv4.diffserv;
        hdr.inner_ipv4.total_len = hdr.ipv4.total_len;
        hdr.inner_ipv4.identification = hdr.ipv4.identification;
        hdr.inner_ipv4.flag_rs = hdr.ipv4.flag_rs;
        hdr.inner_ipv4.flag_df = hdr.ipv4.flag_df;
        hdr.inner_ipv4.flag_mf = hdr.ipv4.flag_mf;
        hdr.inner_ipv4.frag_offset = hdr.ipv4.frag_offset;
        hdr.inner_ipv4.ttl = hdr.ipv4.ttl;
        hdr.inner_ipv4.protocol = hdr.ipv4.protocol;
        // hdr.inner_ipv4.hdr_checksum = hdr.ipv4.hdr_checksum;
        hdr.inner_ipv4.src_addr = hdr.ipv4.src_addr;
        hdr.inner_ipv4.dst_addr = hdr.ipv4.dst_addr;
        switch_flags.inner_ipv4_checksum_update_en = true;
    }

    action rewrite_vxlan_inner_ipv4(bit<16> vxlan_port) {
        //inner ip
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        //inner eth
        hdr.inner_ethernet.setValid();
        hdr.inner_ethernet = hdr.ethernet;
        //outer vxlan
        add_vxlan_header(switch_md.tunnel.key[23:0]);
        //outer udp
        add_udp_header(switch_md.vxlan_src_port_hash, vxlan_port);
        hdr.udp.length = payload_len + 16w30;//UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        //outer ip
        add_ipv4_header(17);
        hdr.ipv4.total_len = payload_len + 16w50;//IPv4 (20) + UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        //outer eth
        hdr.ethernet.ether_type = 0x0800;
    }

    action rewrite_gre1_inner_ipv4() {
        //inner ip
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        //outer gre1
        add_gre1_header(switch_md.tunnel.key, 0x0800);
        //outer ip
        add_ipv4_header(47);
        hdr.ipv4.total_len = payload_len + 16w28;//IPv4 (20) + GRE1 (8) 
        //outer eth
        hdr.ethernet.ether_type = 0x0800;
    }

    action rewrite_gre1_inner_ipv4_set_version() {
        rewrite_gre1_inner_ipv4();
        hdr.gre1.version = 1;
    }

    action rewrite_gre2_inner_ipv4() {
        //inner ip
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        //outer gre2
        add_gre2_header(switch_md.tunnel.key, 0x0800, switch_md.tunnel.vm_addr);
        //outer ip
        add_ipv4_header(47);
        hdr.ipv4.total_len = payload_len + 16w32;//IPv4 (20) + GRE2 (12) 
        //outer eth
        hdr.ethernet.ether_type = 0x0800;
    }

    action rewrite_gre2_inner_ipv4_set_version() {
        rewrite_gre2_inner_ipv4();
        hdr.gre2.version = 1;
    }

    table tunnel_encap {
        key = {
            switch_md.tunnel.type : exact;
            switch_md.tunnel.gre_type : ternary;
         hdr.ipv4.isValid() : exact;
            switch_flags.gre_ver_set : ternary;
        }

        actions = {
            NoAction;
            rewrite_vxlan_inner_ipv4;
            rewrite_gre1_inner_ipv4;
            rewrite_gre1_inner_ipv4_set_version;
            rewrite_gre2_inner_ipv4;
            rewrite_gre2_inner_ipv4_set_version;
        }

        const entries = {
            (SWITCH_TUNNEL_TYPE_VXLAN, _, true, _) : rewrite_vxlan_inner_ipv4(4789);
            (SWITCH_TUNNEL_TYPE_GRE, 1, true, false) : rewrite_gre1_inner_ipv4();
            (SWITCH_TUNNEL_TYPE_GRE, 1, true, true) : rewrite_gre1_inner_ipv4_set_version();
            (SWITCH_TUNNEL_TYPE_GRE, 2, true, false) : rewrite_gre2_inner_ipv4();
            (SWITCH_TUNNEL_TYPE_GRE, 2, true, true) : rewrite_gre2_inner_ipv4_set_version();
        }
        const default_action = NoAction;
        size = 8;
    }

    apply {
        if (switch_md.pkt_action == PKT_ACTION_ACCEPT) {
            tunnel_encap.apply();
        }
    }
}


//-----------------------------------------------------------------------------
// Tunnel SIP
//-----------------------------------------------------------------------------
control TunnelRewrite(inout switch_header_t hdr,
                    inout switch_common_metadata_t switch_md)() {

    switch_uint8_t id = 1;
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) gre_sip_selector_hash;
    ActionProfile(512) gre_sip_action_profile;
    ActionSelector(gre_sip_action_profile,
                   gre_sip_selector_hash,
                   SelectorMode_t.FAIR,
                   512,
                   1) gre_sip_action_selector;

    action set_sip(ipv4_addr_t sip) {
        hdr.ipv4.src_addr = sip;
    }

    action no_sip() {
        switch_md.pkt_action = PKT_ACTION_DROP;
        switch_md.drop_reason.forward_vip_no_set = true;
    }

    action rewrite_dip() {
        hdr.ipv4.dst_addr = switch_md.tunnel.dst_addr;
    }

    table select_gre_sip {
        key = {
            id : exact;
            switch_md.inner_five_tuples_hash : selector;
        }

        actions = {
            NoAction;
            set_sip;
        }

        default_action = NoAction;
        size = 1;
        implementation = gre_sip_action_selector;
    }

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) vip_selector_hash;
    ActionProfile(2) vip_action_profile;
    ActionSelector(vip_action_profile,
                   vip_selector_hash,
                   SelectorMode_t.FAIR,
                   2,
                   1) vip_action_selector;

    table select_vip {
        key = {
            id : exact;
            switch_md.inner_five_tuples_hash : selector;
        }

        actions = {
            no_sip;
            set_sip;
        }

        default_action = no_sip;
        size = 1;
        implementation = vip_action_selector;
    }

    action l2_rewrite(mac_addr_t smac, mac_addr_t dmac) {
        hdr.ethernet.dst_addr = dmac;
        hdr.ethernet.src_addr = smac;
    }

    action no_neighbor() {
        switch_md.pkt_action = PKT_ACTION_DROP;
        switch_md.drop_reason.no_outer_neighbor = true;
    }

    table neighbor {
        key = { switch_md.port : exact; }
        actions = {
            l2_rewrite;
            no_neighbor;
        }

        const default_action = no_neighbor;
        size = 512;
    }


    apply {
        if (switch_md.pkt_action == PKT_ACTION_ACCEPT) {
            switch(neighbor.apply().action_run) {
                l2_rewrite: {
                    rewrite_dip();
                    if (switch_md.tunnel.type == SWITCH_TUNNEL_TYPE_VXLAN) {
                        select_vip.apply();
                    } else if (switch_md.tunnel.type == SWITCH_TUNNEL_TYPE_GRE) {
                        switch(select_gre_sip.apply().action_run) {
                            NoAction : { select_vip.apply(); }
                        }
                    }
                }
            }
        }
    }
}





control IngressStatistics(inout switch_common_metadata_t switch_md,
                          inout switch_common_checks_t switch_checks)
     (switch_uint32_t ingress_statictics_table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) ingress_statistics_ct;

    action statistics_hit() {
        ingress_statistics_ct.count();
    }

    action statistics_miss() {
        ingress_statistics_ct.count();
    }

    table ingress_statistics_table {
        key = {
            switch_md.vrf : exact;
            switch_md.tunnel.type : exact;
            switch_md.tunnel.key : exact;
        }

        actions = {
            statistics_hit;
            statistics_miss;
        }
        counters = ingress_statistics_ct;
        const default_action = statistics_miss;
        size = ingress_statictics_table_size;
    }

    apply {
        if (!switch_checks.urpf) {
            ingress_statistics_table.apply();
        }
    }
}

control EgressStatistics(inout switch_common_metadata_t switch_md)
     (switch_uint32_t egress_statictics_table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) egress_statistics_ct;

    action statistics_hit() {
        egress_statistics_ct.count();
    }

    action statistics_miss() {
        egress_statistics_ct.count();
    }

    table egress_statistics_table {
        key = {
            switch_md.vrf : exact;
            switch_md.tunnel.type : exact;
            switch_md.tunnel.key : exact;
        }

        actions = {
            statistics_hit;
            statistics_miss;
        }
        counters = egress_statistics_ct;
        const default_action = statistics_miss;
        size = egress_statictics_table_size;
    }


    apply {
        if (switch_md.pkt_action == PKT_ACTION_ACCEPT) {
           egress_statistics_table.apply();
        }
    }
}

control DropStatistics(inout switch_common_metadata_t switch_md)
        (switch_uint32_t drop_stats_table_size) {

    Counter<bit<64>, switch_drop_reason_t>(SWITCH_DROP_REASON_MAX, CounterType_t.PACKETS) drop_counter; // 基于reason的pipe丢包计数
    Counter<bit<64>, switch_vrf_t>(SWITCH_VRF_SPEC_MAX, CounterType_t.PACKETS) vrf_drop_counter; // 基于vrf的pipe丢包计数

    action update_reason_drop_stats(bit<8> index) {
        drop_counter.count(index);
    }

    table reason_drop_stats {
        key = {
            switch_md.pkt_action :exact;
            switch_md.drop_reason.unknown :ternary;
            switch_md.drop_reason.ethertype_no_support :ternary;
            switch_md.drop_reason.dip_no_terminate :ternary;
            switch_md.drop_reason.iphdr_exceed_maxlen :ternary;
            switch_md.drop_reason.inner_ethertype_no_support :ternary;
            switch_md.drop_reason.gre_inner_proto_no_support :ternary;
            switch_md.drop_reason.inner_iphdr_exceed_maxlen :ternary;
            switch_md.drop_reason.validation_fail :ternary;
            switch_md.drop_reason.tunnel_mapping_no_vrf :ternary;
            switch_md.drop_reason.urpf_check_fail :ternary;
            switch_md.drop_reason.no_route :ternary;
            switch_md.drop_reason.rid_map_nh_fail :ternary;
            switch_md.drop_reason.acl_deny :ternary;
            switch_md.drop_reason.bfd_overspeed :ternary;
            switch_md.drop_reason.bgp_overspeed :ternary;
            switch_md.drop_reason.arp_overspeed :ternary;
            switch_md.drop_reason.cntl_overspeed :ternary;
            switch_md.drop_reason.other_cpu_overspeed :ternary;
            switch_md.drop_reason.no_nexthop :ternary;
            switch_md.drop_reason.vni_bundel :ternary;
            switch_md.drop_reason.no_inner_neighbor :ternary;
            switch_md.drop_reason.no_inner_smac :ternary;
            switch_md.drop_reason.no_outer_neighbor :ternary;
            switch_md.drop_reason.gre_sip_no_set :ternary;
            switch_md.drop_reason.forward_vip_no_set :ternary;
        }

        actions = {
            NoAction;
            update_reason_drop_stats;
        }

        const entries = {
            (PKT_ACTION_DROP, true, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_UNKNOWN);
            (PKT_ACTION_DROP, _, true, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_ETHERTYPE_NO_SUPPORT);
            (PKT_ACTION_DROP, _, _, true, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_DIP_NO_TERMINATE);
            (PKT_ACTION_DROP, _, _, _, true, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_IPHDR_EXCEED_MAXLEN);
            (PKT_ACTION_DROP, _, _, _, _, true, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_INNER_ETHERTYPE_NO_SUPPORT);
            (PKT_ACTION_DROP, _, _, _, _, _, true, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_GRE_INNER_PROTO_NO_SUPPORT);
            (PKT_ACTION_DROP, _, _, _, _, _, _, true, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_INNER_IPHDR_EXCEED_MAXLEN);
            (PKT_ACTION_DROP, _, _, _, _, _, _, _, true, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_VALIDATION_FAIL);
            (PKT_ACTION_DROP, _, _, _, _, _, _, _, _, true, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_TUNNEL_MAPPING_NO_VRF);
            (PKT_ACTION_DROP, _, _, _, _, _, _, _, _, _, true, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_URPF_CHECK_FAIL);
            (PKT_ACTION_DROP, _, _, _, _, _, _, _, _, _, _, true, _, _, _, _, _, _, _, _, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_NO_ROUTE);
            (PKT_ACTION_DROP, _, _, _, _, _, _, _, _, _, _, _, true, _, _, _, _, _, _, _, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_RID_MAP_NH_FAIL);
            (PKT_ACTION_DROP, _, _, _, _, _, _, _, _, _, _, _, _, true, _, _, _, _, _, _, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_ACL_DENY);
            (PKT_ACTION_DROP, _, _, _, _, _, _, _, _, _, _, _, _, _, true, _, _, _, _, _, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_BFD_OVERSPEED);
            (PKT_ACTION_DROP, _, _, _, _, _, _, _, _, _, _, _, _, _, _, true, _, _, _, _, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_BGP_OVERSPEED);
            (PKT_ACTION_DROP, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, true, _, _, _, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_ARP_OVERSPEED);
            (PKT_ACTION_DROP, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, true, _, _, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_CNTL_OVERSPEED);
            (PKT_ACTION_DROP, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, true, _, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_OTHER_CPU_OVERSPEED);
            (PKT_ACTION_DROP, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, true, _, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_NO_NEXTHOP);
            (PKT_ACTION_DROP, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, true, _, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_VNI_BUNDLE);
            (PKT_ACTION_DROP, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, true, _, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_NO_INNER_NEIGHBOR);
            (PKT_ACTION_DROP, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, true, _, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_NO_INNER_SMAC);
            (PKT_ACTION_DROP, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, true, _, _) : update_reason_drop_stats(SWITCH_DROP_REASON_NO_OUTER_NEIGHBOR);
            (PKT_ACTION_DROP, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, true, _) : update_reason_drop_stats(SWITCH_DROP_REASON_GRE_SIP_NOT_SET);
            (PKT_ACTION_DROP, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, true) : update_reason_drop_stats(SWITCH_DROP_REASON_FORWARD_VIP_NOT_SET);
        }

        const default_action = NoAction;
        size = drop_stats_table_size;
    }

    action update_drop_stats() {
        vrf_drop_counter.count(switch_md.vrf);
    }

    table vrf_drop_stats {
        key = {
            switch_md.pkt_action : exact;
        }

        actions = {
            NoAction;
            update_drop_stats;
        }

        const entries = {
            (PKT_ACTION_DROP) : update_drop_stats();
            (PKT_ACTION_ACCEPT) : NoAction;
        }

        const default_action = NoAction;
        size = drop_stats_table_size;
    }

    apply {
        reason_drop_stats.apply();
        vrf_drop_stats.apply();
    }
}





control EgressPortRedirect(inout switch_ingress_metadata_t ig_md)(
                           switch_uint32_t egress_port_redirect_table_size) {

    action set_egress_port(switch_port_t port) {
        ig_md.common.egress_port = port;
    }

    table egress_port_redirect {
        key = {
            ig_md.common.pkt_action : ternary;
            ig_md.checks.common.urpf : ternary;
            ig_md.common.tunnel.to_local: ternary;
            ig_md.common.port : ternary;
        }

        actions = {
            NoAction;
            set_egress_port;
        }

        const default_action = NoAction;
        size = egress_port_redirect_table_size;
    }

    apply {
        egress_port_redirect.apply();
    }
}





control IpAcl(inout switch_common_metadata_t switch_md)
        (switch_uint32_t acl_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) acl_stats;

    action set_capture() {
        switch_md.mirror.type = 1;
        acl_stats.count();
    }

    action set_sflow() {
        switch_md.mirror.type = 0;
        acl_stats.count();
    }

    action set_meter(switch_meter_id_t meter_index) {
        switch_md.meter_index = meter_index;
        switch_md.color = SWITCH_METER_COLOR_GREEN;
        acl_stats.count();
    }

    action set_counter() {
        acl_stats.count();
    }

    action set_drop() {
        switch_md.pkt_action = PKT_ACTION_DROP;
        switch_md.drop_reason.acl_deny = true;
        acl_stats.count();
    }

    action set_redirect(switch_port_t redirect_port) {
        switch_md.port = redirect_port;
        acl_stats.count();
    }

    table ip_acl {
        key = {
            switch_md.vrf : ternary @name("vrf");
            switch_md.lkp.ip_src_addr : ternary @name("sip");
            switch_md.lkp.ip_dst_addr : ternary @name("dip");
            switch_md.lkp.ip_proto : ternary @name("ip_proto");
            switch_md.lkp.l4_src_port : range @name("l4sport");
            switch_md.lkp.l4_dst_port : range @name("l4dport");
            switch_md.lkp.ip_ttl : range @name("ttl");
        }

        actions = {
            @defaultonly NoAction;
            set_capture;
            set_sflow;
            set_meter;
            set_counter;
            set_drop;
            set_redirect;
        }

        const default_action = NoAction;
        counters = acl_stats;
        size = acl_table_size;
    }

    apply {
        ip_acl.apply();
    }
}

control IngressSystemAcl(inout switch_common_metadata_t switch_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout switch_header_t hdr)
        (switch_uint32_t system_acl_table_size) {

    action set_to_cpu() {
        switch_md.egress_port = PORT_PCI_CPU;
        bit<16> tf_port = (bit<16>)switch_md.port;
        cpu_rewrite(hdr, tf_port);
    }

    action set_drop() {
        ig_real_drop(ig_intr_md_for_dprsr);
    }

    action set_copp(switch_meter_id_t meter_index) {
        switch_md.meter_index = meter_index;
        switch_md.color = SWITCH_METER_COLOR_GREEN;
        set_to_cpu();
    }

    action set_direct_port() {
        switch_md.egress_port = (bit<9>)hdr.fabric.tf_port_id;
        hdr.fabric.setInvalid();
    }

    table system_acl {
        key = {
            switch_md.pkt_action : exact @name("pkt_action");
            switch_md.lkp.ip_src_addr : ternary @name("sip");
            switch_md.lkp.ip_dst_addr : ternary @name("dip");
            switch_md.lkp.ip_proto : ternary @name("ip_proto");
            switch_md.lkp.l4_src_port : ternary @name("l4sport");
            switch_md.lkp.l4_dst_port : ternary @name("l4dport");
            switch_md.lkp.ip_ttl : ternary @name("ttl");
            switch_md.lkp.mac_type : ternary @name("mac_type");
        }

        actions = {
            @defaultonly NoAction;
            set_copp;
            set_to_cpu;
            set_drop;
            set_direct_port;
        }

        const entries = {
            (PKT_ACTION_DIRECT_TO_PORT, _, _, _, _, _, _, _) : set_direct_port();
            (PKT_ACTION_DROP, _, _, _, _, _, _, _) : set_drop();
            (PKT_ACTION_TO_CPU, _, _, 0x11, _, 0xec8, _, _) : set_copp(SWITCH_METER_ID_COPP_BFD); // BFD 
            (PKT_ACTION_TO_CPU, _, _, 0x11, _, 0x12b0, _, _) : set_copp(SWITCH_METER_ID_COPP_BFD); // BFD 
            (PKT_ACTION_TO_CPU, _, _, 0x6, 0xb3, _, _, _) : set_copp(SWITCH_METER_ID_COPP_BGP); // BGP 
            (PKT_ACTION_TO_CPU, _, _, 0x6, _, 0xb3, _, _) : set_copp(SWITCH_METER_ID_COPP_BGP); // BGP 
            (PKT_ACTION_TO_CPU, _, _, _, _, _, _, 0x0806) : set_copp(SWITCH_METER_ID_COPP_ARP); // ARP 
            (PKT_ACTION_TO_CPU, _, _, _, _, _, _, _) : set_copp(SWITCH_METER_ID_COPP_OTHER_CPU);// Other to cpu
            (PKT_ACTION_TO_CPU, _, _, 0x6, 0xc383, _, _, _) : set_copp(SWITCH_METER_ID_COPP_CNTL); // GRPC
            (PKT_ACTION_TO_CPU, _, _, 0x6, _, 0xc383, _, _) : set_copp(SWITCH_METER_ID_COPP_CNTL); // GRPC
            (PKT_ACTION_TO_CPU, _, _, 0x6, 0x50, _, _, _) : set_copp(SWITCH_METER_ID_COPP_CNTL); // HTTP
            (PKT_ACTION_TO_CPU, _, _, 0x6, _, 0x8ca0, _, _) : set_copp(SWITCH_METER_ID_COPP_CNTL); // SSH 
            (PKT_ACTION_TO_CPU, _, _, _, _, _, _, _) : set_copp(SWITCH_METER_ID_COPP_CNTL); // LLDP
            (PKT_ACTION_TO_CPU, _, _, _, 0x35, _, _, _) : set_copp(SWITCH_METER_ID_COPP_CNTL); // DNS
        }

        const default_action = NoAction;
        size = system_acl_table_size;
    }

    apply {
        system_acl.apply();
    }
}

control EgressSystemAcl(inout switch_common_metadata_t switch_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout switch_header_t hdr)
        (switch_uint32_t system_acl_table_size) {

    action set_to_cpu() {}

    action set_direct_port() {}

    action set_drop() {
        eg_real_drop(eg_intr_md_for_dprsr);
    }

    action set_copp(switch_meter_id_t meter_index) {
        switch_md.meter_index = meter_index;
        switch_md.color = SWITCH_METER_COLOR_GREEN;
        set_to_cpu();
    }

    table system_acl {
        key = {
            switch_md.pkt_action : exact @name("pkt_action");
            switch_md.lkp.ip_src_addr : ternary @name("sip");
            switch_md.lkp.ip_dst_addr : ternary @name("dip");
            switch_md.lkp.ip_proto : ternary @name("ip_proto");
            switch_md.lkp.l4_src_port : ternary @name("l4sport");
            switch_md.lkp.l4_dst_port : ternary @name("l4dport");
            switch_md.lkp.ip_ttl : ternary @name("ttl");
            switch_md.lkp.mac_type : ternary @name("mac_type");
        }

        actions = {
            @defaultonly NoAction;
            set_copp;
            set_to_cpu;
            set_drop;
            set_direct_port;
        }

        const entries = {
            (PKT_ACTION_DROP, _, _, _, _, _, _, _) : set_drop();
        }

        const default_action = NoAction;
        size = system_acl_table_size;
    }

    apply {
        system_acl.apply();
    }
}





control IngressMeter(inout switch_common_metadata_t switch_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)
        (switch_uint32_t meter_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) meter_stats;
    Meter<bit<8>>(1 << 8, MeterType_t.BYTES) ig_meter;

    action mirror_and_count() {
        switch_md.mirror.src = SWITCH_PKT_SRC_INGRESS_CLONE;
        switch_md.mirror.session_id = 1;
        meter_stats.count();
    }

    action no_mirror_and_count() {
        switch_md.mirror.type = 0;
        meter_stats.count();
    }

    action bfd_drop_and_count() {
        switch_md.drop_reason.bfd_overspeed = true;
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        meter_stats.count();
    }

    action bgp_drop_and_count() {
        switch_md.drop_reason.bgp_overspeed = true;
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        meter_stats.count();
    }

    action arp_drop_and_count() {
        switch_md.drop_reason.arp_overspeed = true;
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        meter_stats.count();
    }

    action cntl_drop_and_count() {
        switch_md.drop_reason.cntl_overspeed = true;
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        meter_stats.count();
    }

    action other_cpu_drop_and_count() {
        switch_md.drop_reason.other_cpu_overspeed = true;
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        meter_stats.count();
    }

    action meter_drop_and_count() {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        meter_stats.count();
    }

    action meter_count() {
        meter_stats.count();
    }

    table meter_action {
        key = {
            switch_md.meter_index : ternary;
            switch_md.color : exact;
        }

        actions = {
            mirror_and_count;
            no_mirror_and_count;
            bfd_drop_and_count;
            bgp_drop_and_count;
            arp_drop_and_count;
            cntl_drop_and_count;
            other_cpu_drop_and_count;
            meter_drop_and_count;
            meter_count;
        }

        const entries = {
            (SWITCH_METER_ID_CAPTURE, SWITCH_METER_COLOR_RED) : no_mirror_and_count;
            (SWITCH_METER_ID_COPP_BFD, SWITCH_METER_COLOR_RED) : bfd_drop_and_count;
            (SWITCH_METER_ID_COPP_BGP, SWITCH_METER_COLOR_RED) : bgp_drop_and_count;
            (SWITCH_METER_ID_COPP_ARP, SWITCH_METER_COLOR_RED) : arp_drop_and_count;
            (SWITCH_METER_ID_COPP_CNTL, SWITCH_METER_COLOR_RED) : cntl_drop_and_count;
            (SWITCH_METER_ID_COPP_OTHER_CPU, SWITCH_METER_COLOR_RED) : other_cpu_drop_and_count;
            (SWITCH_METER_ID_CAPTURE, SWITCH_METER_COLOR_GREEN) : mirror_and_count;
            (_, SWITCH_METER_COLOR_RED) : meter_drop_and_count;
        }

        const default_action = meter_count;
        counters = meter_stats;
        table_size = meter_table_size;
    }

    action set_color() {
        switch_md.color = (bit<2>) ig_meter.execute(switch_md.meter_index);
    }

    table meter_index {
        actions = {
            set_color;
        }
        const default_action = set_color;
        size = 1;
    }

    apply {
        if (switch_md.meter_index != 8w0) {
            meter_index.apply();
            meter_action.apply();
        }
    }
}

control EgressMeter(inout switch_common_metadata_t switch_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)
        (switch_uint32_t meter_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) meter_stats;
    Meter<bit<8>>(1 << 8, MeterType_t.BYTES) eg_meter;

    action mirror_and_count() {
        switch_md.mirror.src = SWITCH_PKT_SRC_INGRESS_CLONE;
        switch_md.mirror.session_id = 1;
        meter_stats.count();
    }

    action no_mirror_and_count() {
        switch_md.mirror.type = 0;
        meter_stats.count();
    }

    action bfd_drop_and_count() {
        switch_md.drop_reason.bfd_overspeed = true;
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        meter_stats.count();
    }

    action bgp_drop_and_count() {
        switch_md.drop_reason.bgp_overspeed = true;
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        meter_stats.count();
    }

    action arp_drop_and_count() {
        switch_md.drop_reason.arp_overspeed = true;
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        meter_stats.count();
    }

    action cntl_drop_and_count() {
        switch_md.drop_reason.cntl_overspeed = true;
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        meter_stats.count();
    }

    action other_cpu_drop_and_count() {
        switch_md.drop_reason.other_cpu_overspeed = true;
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        meter_stats.count();
    }

    action meter_drop_and_count() {
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        meter_stats.count();
    }

    action meter_count() {
        meter_stats.count();
    }

    table meter_action {
        key = {
            switch_md.meter_index : ternary;
            switch_md.color : exact;
        }

        actions = {
            mirror_and_count;
            no_mirror_and_count;
            bfd_drop_and_count;
            bgp_drop_and_count;
            arp_drop_and_count;
            cntl_drop_and_count;
            other_cpu_drop_and_count;
            meter_drop_and_count;
            meter_count;
        }

        const entries = {
            (SWITCH_METER_ID_CAPTURE, SWITCH_METER_COLOR_RED) : no_mirror_and_count;
            (SWITCH_METER_ID_COPP_BFD, SWITCH_METER_COLOR_RED) : bfd_drop_and_count;
            (SWITCH_METER_ID_COPP_BGP, SWITCH_METER_COLOR_RED) : bgp_drop_and_count;
            (SWITCH_METER_ID_COPP_ARP, SWITCH_METER_COLOR_RED) : arp_drop_and_count;
            (SWITCH_METER_ID_COPP_CNTL, SWITCH_METER_COLOR_RED) : cntl_drop_and_count;
            (SWITCH_METER_ID_COPP_OTHER_CPU, SWITCH_METER_COLOR_RED) : other_cpu_drop_and_count;
            (SWITCH_METER_ID_CAPTURE, SWITCH_METER_COLOR_GREEN) : mirror_and_count;
            (_, SWITCH_METER_COLOR_RED) : meter_drop_and_count;
        }

        const default_action = meter_count;
        counters = meter_stats;
        table_size = meter_table_size;
    }

    action set_color() {
        switch_md.color = (bit<2>) eg_meter.execute(switch_md.meter_index);
    }

    table meter_index {
        actions = {
            set_color;
        }
        const default_action = set_color;
        size = 1;
    }

    apply {
        if (switch_md.meter_index != 8w0) {
            meter_index.apply();
            meter_action.apply();
        }
    }
}





struct switch_sample_info_t {
    bit<16> current;
    bit<16> rate;
}

control Capture(inout switch_common_metadata_t switch_md)
        (switch_uint32_t capture_table_size) {

    Register<switch_sample_info_t, bit<32>>(1) samplers;
    Register<switch_int32_t, bit<32>>(1) count_reg;

    RegisterAction<switch_sample_info_t, bit<16>, bool>(samplers) sample_action = {
        void apply(inout switch_sample_info_t reg, out bool flag) {
            if (reg.current > 0) {
                reg.current = reg.current - 1;
                flag = false;
            } else {
                reg.current = reg.rate;
                flag = true;
            }
        }
    };

    RegisterAction<switch_int32_t, bit<32>, switch_mirror_type_t>(count_reg) count_reg_action = {
        void apply(inout switch_int32_t value, out switch_mirror_type_t mirror_type){
            if (value == (0x7FFFFFFF)) {
                mirror_type = 1;
            } else {
                if (value > 0) {
                    mirror_type = 1;
                    value = value - 1;
                } else {
                    mirror_type = 0;
                }
            }
        }
    };

    action pkt_sample() {
        switch_md.sample_flag = sample_action.execute(0);
    }

    table sample {
        key = {
            switch_md.mirror.type : exact;
        }

        actions = {
            NoAction;
            pkt_sample;
        }

        const entries = {
            (1) : pkt_sample();
            (0) : NoAction();
        }

        const default_action = NoAction;
        size = capture_table_size;
    }

    action pkt_capture() {
        switch_md.mirror.type = count_reg_action.execute(0);
        switch_md.mirror.type = 1;
        switch_md.mirror.src = SWITCH_PKT_SRC_INGRESS_CLONE;
        switch_md.mirror.session_id = 1;
    }

    table capture {
        key = {
            switch_md.mirror.type : exact;
            switch_md.sample_flag : exact;
        }

        actions = {
            NoAction;
            pkt_capture;
        }

        const entries = {
            (1, true) : pkt_capture;
            (1, false) : NoAction;
        }

        const default_action = NoAction;
        size = capture_table_size;
    }

    apply {
        sample.apply();
        capture.apply();
    }
}


//-----------------------------------------------------------------------------
// Table sizes.
//-----------------------------------------------------------------------------
const bit<32> HASH_TABLE_SIZE = 4;

const bit<32> VNI_BUNDLE_TABLE_SIZE = 10 * 1024;
const bit<32> INNER_NEIGHBOUR_TABLE_SIZE = 10 * 1024;
const bit<32> EGRESS_STATICTICS_TABLE_SIZE = 8192;

const bit<32> EGRESS_ACL_TABLE_SIZE = 1024;
const bit<32> EGRESS_SYSTEM_ACL_TABLE_SIZE = 1024;
const bit<32> EGRESS_CAPTURE_TABLE_SIZE = 1024;
const bit<32> EGRESS_METER_TABLE_SIZE = 1024;
const bit<32> EGRESS_DROP_STATISTICS_TABLE_SIZE = 1024;

control SwitchIngress_a(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    EgressPortRedirect(EGRESS_PORT_REDIRECT_TABLE_SIZE) egress_port_redirect;

    apply {
        add_bridged_pa_to_pb_md(hdr.bridged_pa_to_pb, ig_md.common);
        egress_port_redirect.apply(ig_md);
    }
}

control SwitchEgress_a(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    InnerRewrite(VNI_BUNDLE_TABLE_SIZE, INNER_NEIGHBOUR_TABLE_SIZE, VRF_SIZE) inner_rewrite;
    TunnelEncap() tunnel_encap;
    TunnelRewrite() tunnel_rewrite;
    EgressStatistics(EGRESS_STATICTICS_TABLE_SIZE) statistics;
    IpAcl(EGRESS_ACL_TABLE_SIZE) egress_acl;
    EgressSystemAcl(EGRESS_SYSTEM_ACL_TABLE_SIZE) egress_system_acl;
    Capture(EGRESS_CAPTURE_TABLE_SIZE) egress_capture;
    EgressMeter(EGRESS_METER_TABLE_SIZE) egress_meter;
    DropStatistics(EGRESS_DROP_STATISTICS_TABLE_SIZE) egress_drop_statistics;

    apply {
        inner_rewrite.apply(hdr, eg_md.common, eg_md.flags.common);
        tunnel_encap.apply(hdr, eg_md.common, eg_md.flags.common);
        tunnel_rewrite.apply(hdr, eg_md.common);
        statistics.apply(eg_md.common);
        egress_acl.apply(eg_md.common);
        egress_capture.apply(eg_md.common);
        egress_system_acl.apply(eg_md.common, eg_intr_md_for_dprsr, hdr);
        egress_meter.apply(eg_md.common, eg_intr_md_for_dprsr);
        egress_drop_statistics.apply(eg_md.common);
    }
}



/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/* This is the P4-16 core library, which declares some built-in P4 constructs using P4 */


/**
 * Copyright 2013-2021 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */



//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------








control PktValidation(
        in switch_header_t hdr,
        inout switch_common_metadata_t switch_md,
        inout switch_common_flags_t switch_flags) {

    action valid_outer_ethernet() {
        switch_md.lkp.mac_src_addr = hdr.ethernet.src_addr;
        switch_md.lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        switch_md.lkp.mac_type = hdr.ethernet.ether_type;
    }

    action valid_outer_ipv4_hash() {
        switch_md.hash_fields.ip_type = SWITCH_IP_TYPE_IPV4;
        switch_md.hash_fields.ip_proto = hdr.ipv4.protocol;
        switch_md.hash_fields.ip_src_addr = hdr.ipv4.src_addr;
        switch_md.hash_fields.ip_dst_addr = hdr.ipv4.dst_addr;
    }

    action valid_outer_ipv4_lkp() {
        //lookup filed
        switch_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        switch_md.lkp.ip_tos = hdr.ipv4.diffserv;
        switch_md.lkp.ip_proto = hdr.ipv4.protocol;
        switch_md.lkp.ip_ttl = hdr.ipv4.ttl;
        switch_md.lkp.ip_src_addr[63:0] = 64w0;
        switch_md.lkp.ip_src_addr[95:64] = hdr.ipv4.src_addr;
        switch_md.lkp.ip_src_addr[127:96] = 32w0;
        switch_md.lkp.ip_dst_addr[63:0] = 64w0;
        switch_md.lkp.ip_dst_addr[95:64] = hdr.ipv4.dst_addr;
        switch_md.lkp.ip_dst_addr[127:96] = 32w0;
    }

    action valid_outer_ipv4() {
        valid_outer_ipv4_hash();
        valid_outer_ipv4_lkp();
    }

    action valid_outer_udp_hash() {
        //hash filed
        switch_md.hash_fields.l4_src_port = hdr.udp.src_port;
        switch_md.hash_fields.l4_dst_port = hdr.udp.dst_port;
    }

    action valid_outer_udp_lkp() {
        //lookup field
        switch_md.lkp.l4_src_port = hdr.udp.src_port;
        switch_md.lkp.l4_dst_port = hdr.udp.dst_port;
        switch_md.lkp.tcp_flags = 0;
    }

    action valid_outer_udp() {
        valid_outer_udp_hash();
        valid_outer_udp_lkp();
    }

    action valid_vxlan() {
        switch_md.tunnel.type = SWITCH_TUNNEL_TYPE_VXLAN;
        switch_md.tunnel.key[23:0] = hdr.vxlan.vni;
    }

    action valid_gre1() {
        switch_md.tunnel.type = SWITCH_TUNNEL_TYPE_GRE;
        switch_md.tunnel.key = hdr.gre1.vpcid;
    }

    action valid_gre2() {
        switch_md.tunnel.type = SWITCH_TUNNEL_TYPE_GRE;
        switch_md.tunnel.key = hdr.gre2.vpcid;
    }

    action valid_outer_tcp() {
        //lookup field
        switch_md.lkp.l4_src_port = hdr.tcp.src_port;
        switch_md.lkp.l4_dst_port = hdr.tcp.dst_port;
        switch_md.lkp.tcp_flags = hdr.tcp.flags;
        //hash filed
        switch_md.hash_fields.l4_src_port = hdr.tcp.src_port;
        switch_md.hash_fields.l4_dst_port = hdr.tcp.dst_port;
    }

    action valid_outer_icmp() {
        //lookup field
        switch_md.lkp.l4_src_port[7:0] = hdr.icmp.type;
        switch_md.lkp.l4_src_port[15:8] = hdr.icmp.code;
        switch_md.lkp.l4_dst_port = 0;
        switch_md.lkp.tcp_flags = 0;
        //hash filed
        switch_md.hash_fields.l4_src_port[7:0] = hdr.icmp.type;
        switch_md.hash_fields.l4_src_port[15:8] = hdr.icmp.code;
    }

    action valid_inner_ethernet() {
        switch_md.lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        switch_md.lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
        switch_md.lkp.mac_type = hdr.inner_ethernet.ether_type;
    }

    action valid_inner_ipv4() {
        //lookup field
        switch_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        switch_md.lkp.ip_tos = hdr.inner_ipv4.diffserv;
        switch_md.lkp.ip_ttl = hdr.inner_ipv4.ttl;
        switch_md.lkp.ip_proto = hdr.inner_ipv4.protocol;
        switch_md.lkp.ip_src_addr[63:0] = 64w0;
        switch_md.lkp.ip_src_addr[95:64] = hdr.inner_ipv4.src_addr;
        switch_md.lkp.ip_src_addr[127:96] = 32w0;
        switch_md.lkp.ip_dst_addr[63:0] = 64w0;
        switch_md.lkp.ip_dst_addr[95:64] = hdr.inner_ipv4.dst_addr;
        switch_md.lkp.ip_dst_addr[127:96] = 32w0;
        //hash filed
        switch_md.hash_fields.inner_ip_type = SWITCH_IP_TYPE_IPV4;
        switch_md.hash_fields.inner_ip_proto = hdr.inner_ipv4.protocol;
        switch_md.hash_fields.inner_ip_src_addr[95:64] = hdr.inner_ipv4.src_addr;
        switch_md.hash_fields.inner_ip_dst_addr[95:64] = hdr.inner_ipv4.dst_addr;
    }

    action valid_inner_tcp() {
        //lookup field
        switch_md.lkp.l4_src_port = hdr.inner_tcp.src_port;
        switch_md.lkp.l4_dst_port = hdr.inner_tcp.dst_port;
        switch_md.lkp.tcp_flags = hdr.inner_tcp.flags;
        //hash filed
        switch_md.hash_fields.inner_l4_src_port = hdr.inner_tcp.src_port;
        switch_md.hash_fields.inner_l4_dst_port = hdr.inner_tcp.dst_port;
    }

    action valid_inner_udp() {
        //lookup field
        switch_md.lkp.l4_src_port = hdr.inner_udp.src_port;
        switch_md.lkp.l4_dst_port = hdr.inner_udp.dst_port;
        switch_md.lkp.tcp_flags = 0;
        //hash filed
        switch_md.hash_fields.inner_l4_src_port = hdr.inner_udp.src_port;
        switch_md.hash_fields.inner_l4_dst_port = hdr.inner_udp.dst_port;
    }

    action valid_inner_icmp() {
        //lookup field
        switch_md.lkp.l4_src_port[7:0] = hdr.inner_icmp.type;
        switch_md.lkp.l4_src_port[15:8] = hdr.inner_icmp.code;
        switch_md.lkp.l4_dst_port = 0;
        switch_md.lkp.tcp_flags = 0;
        //hash filed
        switch_md.hash_fields.inner_l4_src_port[7:0] = hdr.inner_icmp.type;
        switch_md.hash_fields.inner_l4_src_port[15:8] = hdr.inner_icmp.code;
    }

    action valid_ipv4_udp() {
        valid_outer_ethernet();
        valid_outer_ipv4();
        valid_outer_udp();
    }

    action valid_ipv4_tcp() {
        valid_outer_ethernet();
        valid_outer_ipv4();
        valid_outer_tcp();
    }

    action valid_ipv4_icmp() {
        valid_outer_ethernet();
        valid_outer_ipv4();
        valid_outer_icmp();
    }

    action valid_ipv4_unknown() {
        valid_outer_ethernet();
        valid_outer_ipv4();
    }

    action valid_gre1_inner_ipv4_udp() {
        valid_outer_ipv4_hash();
        valid_gre1();
        valid_inner_ipv4();
        valid_inner_udp();
    }
    action valid_gre1_inner_ipv4_tcp() {
        valid_outer_ipv4_hash();
        valid_gre1();
        valid_inner_ipv4();
        valid_inner_tcp();
    }
    action valid_gre1_inner_ipv4_icmp() {
        valid_outer_ipv4_hash();
        valid_gre1();
        valid_inner_ipv4();
        valid_inner_icmp();
    }
    action valid_gre1_inner_ipv4_unknown() {
        valid_outer_ipv4_hash();
        valid_gre1();
        valid_inner_ipv4();
    }

    action valid_gre2_inner_ipv4_udp() {
        valid_outer_ipv4_hash();
        valid_gre2();
        valid_inner_ipv4();
        valid_inner_udp();
    }
    action valid_gre2_inner_ipv4_tcp() {
        valid_outer_ipv4_hash();
        valid_gre2();
        valid_inner_ipv4();
        valid_inner_tcp();
    }
    action valid_gre2_inner_ipv4_icmp() {
        valid_outer_ipv4_hash();
        valid_gre2();
        valid_inner_ipv4();
        valid_inner_icmp();
    }
    action valid_gre2_inner_ipv4_unknown() {
        valid_outer_ipv4_hash();
        valid_gre2();
        valid_inner_ipv4();
    }

    action valid_vxlan_inner_ipv4_udp() {
        valid_outer_ipv4_hash();
        valid_outer_udp_hash();
        valid_vxlan();
        valid_inner_ethernet();
        valid_inner_ipv4();
        valid_inner_udp();
    }

    action valid_vxlan_inner_ipv4_tcp() {
        valid_outer_ipv4_hash();
        valid_outer_udp_hash();
        valid_vxlan();
        valid_inner_ethernet();
        valid_inner_ipv4();
        valid_inner_tcp();
    }

    action valid_vxlan_inner_ipv4_icmp() {
        valid_outer_ipv4_hash();
        valid_outer_udp_hash();
        valid_vxlan();
        valid_inner_ethernet();
        valid_inner_ipv4();
        valid_inner_icmp();
    }

    action valid_vxlan_inner_ipv4_unknown() {
        valid_outer_ipv4_hash();
        valid_outer_udp_hash();
        valid_vxlan();
        valid_inner_ethernet();
        valid_inner_ipv4();
    }

    action drop_pkt() {
        switch_md.pkt_action = PKT_ACTION_DROP;
        switch_md.drop_reason.validation_fail = true;
    }

    table validate_pkt {
        key = {
            hdr.ethernet.isValid() : exact;
            hdr.ipv4.isValid() : exact;
            switch_flags.ipv4_checksum_err : ternary;
            hdr.tcp.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.icmp.isValid() : exact;
            hdr.gre1.isValid() : exact;
            hdr.gre2.isValid() : exact;

            hdr.vxlan.isValid() : exact;

            hdr.inner_ethernet.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            switch_flags.inner_ipv4_checksum_err : ternary;
            hdr.inner_tcp.isValid() : exact;
            hdr.inner_udp.isValid() : exact;
            hdr.inner_icmp.isValid() : exact;
        }

        actions = {
            drop_pkt;
            valid_ipv4_udp;
            valid_ipv4_tcp;
            valid_ipv4_icmp;
            valid_ipv4_unknown;

            valid_gre1_inner_ipv4_udp;
            valid_gre1_inner_ipv4_tcp;
            valid_gre1_inner_ipv4_icmp;
            valid_gre1_inner_ipv4_unknown;

            valid_gre2_inner_ipv4_udp;
            valid_gre2_inner_ipv4_tcp;
            valid_gre2_inner_ipv4_icmp;
            valid_gre2_inner_ipv4_unknown;

            valid_vxlan_inner_ipv4_udp;
            valid_vxlan_inner_ipv4_tcp;
            valid_vxlan_inner_ipv4_icmp;
            valid_vxlan_inner_ipv4_unknown;
        }
        const default_action = drop_pkt;
        const entries = {
            (true, true, false, false, false, false, true, false, false, false, true, false, false, true, false) : valid_gre1_inner_ipv4_udp();
            (true, true, false, false, false, false, true, false, false, false, true, false, true, false, false) : valid_gre1_inner_ipv4_tcp();
            (true, true, false, false, false, false, true, false, false, false, true, false, false, false, true) : valid_gre1_inner_ipv4_icmp();
            (true, true, false, false, false, false, true, false, false, false, true, false, false, false, false) : valid_gre1_inner_ipv4_unknown();

            (true, true, false, false, false, false, false, true, false, false, true, false, false, true, false) : valid_gre2_inner_ipv4_udp();
            (true, true, false, false, false, false, false, true, false, false, true, false, true, false, false) : valid_gre2_inner_ipv4_tcp();
            (true, true, false, false, false, false, false, true, false, false, true, false, false, false, true) : valid_gre2_inner_ipv4_icmp();
            (true, true, false, false, false, false, false, true, false, false, true, false, false, false, false) : valid_gre2_inner_ipv4_unknown();

            (true, true, false, false, true, false, false, false, true, true, true, false, false, true, false) : valid_vxlan_inner_ipv4_udp();
            (true, true, false, false, true, false, false, false, true, true, true, false, true, false, false) : valid_vxlan_inner_ipv4_tcp();
            (true, true, false, false, true, false, false, false, true, true, true, false, false, false, true) : valid_vxlan_inner_ipv4_icmp();
            (true, true, false, false, true, false, false, false, true, true, true, false, false, false, false) : valid_vxlan_inner_ipv4_unknown();
        }
        size = 64;
    }

    apply {
        //only support vxlan and gre pkt for action=PKT_ACTION_ACCEPT, others will drop
        if (switch_md.pkt_action == PKT_ACTION_ACCEPT) {
            validate_pkt.apply();
        }
    }
}





control TupleHash(in switch_header_t hdr, inout switch_common_metadata_t switch_md) (switch_uint32_t hash_table_size){
    Hash<bit<16>>(HashAlgorithm_t.CRC16) inner_five_tuples_hash;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) inner_outer_ten_tuples_hash;
    bit<16> inner_five_tuples_hash_value;
    bit<16> inner_outer_ten_tuples_hash_value;
    bit<16> inner_l4_src_port = switch_md.hash_fields.inner_l4_src_port;
    bit<16> inner_l4_dst_port = switch_md.hash_fields.inner_l4_dst_port;

    action clear_l4_info_for_first_frament() {
        inner_l4_src_port = 0;
        inner_l4_dst_port = 0;
    }

    action normal_hash() {
        switch_md.vxlan_src_port_hash = inner_five_tuples_hash_value;
    }

    action bfd_hash() {
        switch_md.vxlan_src_port_hash = inner_outer_ten_tuples_hash_value;
    }

    table vxlan_src_port_hash_mod {
        key = {
            switch_md.hash_fields.inner_ip_proto : exact;
            switch_md.hash_fields.inner_l4_dst_port : exact;
        }

        actions = {
            bfd_hash;
            normal_hash;
        }

        const default_action = normal_hash;
        size = hash_table_size;
    }

    apply {
        // for first framented pkt
        if (hdr.inner_ipv4.isValid() && hdr.inner_ipv4.flag_mf == 1) {
            clear_l4_info_for_first_frament();
        }

        inner_five_tuples_hash_value = inner_five_tuples_hash.get({
                                        switch_md.hash_fields.inner_ip_src_addr,
                                        switch_md.hash_fields.inner_ip_dst_addr,
                                        switch_md.hash_fields.inner_ip_proto,
                                        inner_l4_dst_port,
                                        inner_l4_src_port});

        inner_outer_ten_tuples_hash_value
            = inner_outer_ten_tuples_hash.get({switch_md.hash_fields.ip_src_addr,
                                                switch_md.hash_fields.ip_dst_addr,
                                                switch_md.hash_fields.ip_proto,
                                                switch_md.hash_fields.l4_dst_port,
                                                switch_md.hash_fields.l4_src_port,
                                                switch_md.hash_fields.inner_ip_src_addr,
                                                switch_md.hash_fields.inner_ip_dst_addr,
                                                switch_md.hash_fields.inner_ip_proto,
                                                inner_l4_dst_port,
                                                inner_l4_src_port});

        switch_md.inner_five_tuples_hash = inner_five_tuples_hash_value;

        vxlan_src_port_hash_mod.apply();
    }
}





control VrfMapping(inout switch_header_t hdr,
                    inout switch_common_metadata_t switch_md,
                    inout switch_common_flags_t switch_flags,
                    inout switch_common_checks_t switch_checks)(
                    switch_uint32_t tunnel_to_vrf_table_size,
                    switch_uint32_t vrf_attribute_table_size) {

    action map_tunnel_to_vrf(switch_vrf_t vrf, bool urpf) {
        switch_md.vrf = vrf;
        switch_checks.urpf = urpf;
    }

    action map_tunnel_to_vrf_miss() {
        switch_md.pkt_action = PKT_ACTION_DROP;
        switch_md.drop_reason.tunnel_mapping_no_vrf = true;
    }

    table tunnel_to_vrf_table {
        key = {
            switch_md.tunnel.type : exact;
            switch_md.tunnel.key : exact;
        }

        actions = {
            map_tunnel_to_vrf_miss;
            map_tunnel_to_vrf;
        }
        const default_action = map_tunnel_to_vrf_miss;
        size = tunnel_to_vrf_table_size;
    }

    action set_gre_version() {
        switch_flags.gre_ver_set = true;
    }

    table vrf_attribute {
        key = {
            switch_md.vrf : exact;
        }

        actions = {
            NoAction;
            set_gre_version;
        }
        size = vrf_attribute_table_size;
    }

    apply {
        tunnel_to_vrf_table.apply();
        vrf_attribute.apply();
    }
}







//
// *************************** FIB v4 **************************************
//
control Fibv4(inout switch_common_metadata_t switch_md,
              inout switch_common_flags_t switch_flags)(
              switch_uint32_t ipv4_lpm_table_size,
              switch_uint32_t host_table_size) {

    action fib_hit(switch_nexthop_t nexthop_index, bool nottl) {
        switch_md.nexthop = nexthop_index;
        switch_flags.routed = true;
        switch_md.drop_reason.no_route = false;
        switch_flags.nottl = nottl;
    }

    action fib_miss() {
        switch_md.drop_reason.no_route = true;
        switch_flags.routed = false;
    }

    Alpm(number_partitions = 1024, subtrees_per_partition = 2) algo_lpm;
    @name(".ipv4_lpm_dst")
    table lpm32 {
        key = {
            switch_md.vrf : exact;
            switch_md.lkp.ip_dst_addr[95:64] : lpm @name("ipv4_dst_addr");
        }

        actions = {
            fib_miss;
            fib_hit;
        }

        const default_action = fib_miss();
        size = ipv4_lpm_table_size;
        implementation = algo_lpm;
        requires_versioning = false;
    }

    table ipv4_host {
        key = {
            switch_md.vrf : exact;
            switch_md.lkp.ip_dst_addr[95:64] : exact @name("ipv4_dst_addr");
        }

        actions = {
            fib_miss;
            fib_hit;
        }

        const default_action = fib_miss();
        size = host_table_size;
    }

    apply {
        switch(ipv4_host.apply().action_run) {
            fib_miss : {
                lpm32.apply();
            }
        }
    }
}

//
// *************************** FIB v6 **************************************
//
control Fibv6(inout switch_common_metadata_t switch_md,
              inout switch_common_flags_t switch_flags)(
              switch_uint32_t lpm_table_size,
              switch_uint32_t host_table_size) {

    action fib_hit(switch_nexthop_t nexthop_index, bool nottl) {
        switch_md.nexthop = nexthop_index;
        switch_flags.routed = true;
        switch_md.drop_reason.no_route = false;
        switch_flags.nottl = nottl;
    }

    action fib_miss() {
        switch_md.drop_reason.no_route = true;
        switch_flags.routed = false;
    }

    Alpm(number_partitions = 1024, subtrees_per_partition = 2) algo_lpm;
    @name(".ipv6_lpm_dst")
    table lpm128 {
        key = {
            switch_md.vrf : exact;
            switch_md.lkp.ip_dst_addr : lpm @name("ipv6_dst_addr");
        }

        actions = {
            fib_miss;
            fib_hit;
        }

        const default_action = fib_miss();
        size = lpm_table_size;
        implementation = algo_lpm;
        requires_versioning = false;
    }

    table ipv6_host {
        key = {
            switch_md.vrf : exact;
            switch_md.lkp.ip_dst_addr : exact @name("ipv6_dst_addr");
        }

        actions = {
            fib_miss;
            fib_hit;
        }

        const default_action = fib_miss();
        size = host_table_size;
    }

    apply {
        switch(ipv6_host.apply().action_run) {
            fib_miss : {
                lpm128.apply();
            }
        }
    }
}

control Fibv6Lpm(inout switch_common_metadata_t switch_md,
              inout switch_common_flags_t switch_flags)(
              switch_uint32_t lpm_table_size) {

    action fib_hit(switch_nexthop_t nexthop_index) {
        switch_md.nexthop = nexthop_index;
        switch_flags.routed = true;
    }

    action fib_miss() {
        switch_md.drop_reason.no_route = true;
        switch_flags.routed = false;
    }

    Alpm(number_partitions = 1024, subtrees_per_partition = 2) algo_lpm;
    @name(".ipv6_lpm_dst")
    table lpm128 {
        key = {
            switch_md.vrf : exact;
            switch_md.lkp.ip_dst_addr : lpm @name("ipv6_dst_addr");
        }

        actions = {
            fib_miss;
            fib_hit;
        }

        const default_action = fib_miss();
        size = lpm_table_size;
        implementation = algo_lpm;
        requires_versioning = false;
    }

    apply {
        lpm128.apply();
    }
}


// *************************** Ecmp**************************************
control Ecmp(inout switch_common_metadata_t switch_md)(
              switch_uint32_t ecmp_group_table_size,
              switch_uint32_t ecmp_selection_table_size,
              switch_uint32_t ecmp_max_members_per_group=64) {

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionProfile(ecmp_selection_table_size) ecmp_action_profile;
    ActionSelector(ecmp_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   ecmp_max_members_per_group,
                   ecmp_group_table_size) ecmp_selector;

    action set_ecmp_properties(switch_nexthop_t nexthop_index) {
        switch_md.nexthop = nexthop_index;
    }

    table ecmp {
        key = {
            switch_md.nexthop : exact;
            switch_md.inner_five_tuples_hash : selector;
        }

        actions = {
            @defaultonly NoAction;
            set_ecmp_properties;
        }

        const default_action = NoAction;
        size = ecmp_group_table_size;
        implementation = ecmp_selector;
    }

    apply {
        ecmp.apply();
    }
}

// *************************** Nexthop2Mgid**************************************
control Nexthop2Mgid(inout switch_common_metadata_t switch_md)(
                switch_uint32_t multicast_group_table_size) {

    action set_nexthop_mgid(switch_mgid_t mgid) {
        switch_md.mgid = mgid;
    }

    table nexthop2mgid {
        key = {
            switch_md.nexthop : exact;
        }

        actions = {
            @defaultonly NoAction;
            set_nexthop_mgid;
        }

        const default_action = NoAction;
        size = multicast_group_table_size;
    }

    apply {
        nexthop2mgid.apply();
    }
}

// *************************** Rid2Nexthop**************************************
control Rid2Nexthop(inout switch_common_metadata_t switch_md,
                       in egress_intrinsic_metadata_t eg_intr_md)(
                        switch_uint32_t mc_rid_map_nh_table_size) {
    action set_nexthop_index(switch_nexthop_t nexthop_index) {
        switch_md.nexthop = nexthop_index;
        switch_md.drop_reason.rid_map_nh_fail = false;
    }

    action rid2nexthop_miss() {
        switch_md.pkt_action = PKT_ACTION_DROP;
        switch_md.drop_reason.rid_map_nh_fail = true;
    }

    table rid2nexthop {
        key = {
            eg_intr_md.egress_rid : exact;
        }

        actions = {
            @defaultonly rid2nexthop_miss;
            set_nexthop_index;
        }

        const default_action = rid2nexthop_miss;
        size = mc_rid_map_nh_table_size;
    }

    apply {
        if (switch_md.mgid != 0) {
            rid2nexthop.apply();
        }
    }
}

control TTLCheck(in switch_header_t hdr,
                inout switch_common_metadata_t switch_md,
                in switch_common_flags_t switch_flags) {
    apply {
        if (switch_flags.nottl == false && hdr.inner_ipv4.ttl <= 1) {
            switch_md.pkt_action = PKT_ACTION_TO_CPU;
        }
    }
}







control UrpfPrepare(inout switch_common_metadata_t switch_md,
                    inout switch_common_checks_t switch_checks){
    action confirm_urpf_check() {
        switch_md.lkp.ip_dst_addr = switch_md.lkp.ip_src_addr;
    }

    action cancel_urpf_flag() {
        switch_checks.urpf = false;
    }

    apply {
        if (switch_md.pkt_src == SWITCH_PKT_SRC_BRIDGED_URPF) {
            cancel_urpf_flag();
        }

        if (switch_checks.urpf) {
            confirm_urpf_check();
        }
    }
}

control UrpfDecision(inout switch_header_t hdr,
                inout switch_common_metadata_t switch_md,
                inout switch_common_flags_t switch_flags,
                inout switch_common_checks_t switch_checks) {
    action urpf_check_fail() {
        switch_md.drop_reason.urpf_check_fail = true;
        switch_checks.urpf = false;
    }

    action urpf_check_success() {
        add_bridged_urpf_md(hdr.bridged_urpf, switch_md);
    }

    table urpf_decision {
        key = {
            switch_checks.urpf : exact;
            switch_flags.routed : exact;
        }

        actions = {
            NoAction;
            urpf_check_fail;
            urpf_check_success;
        }
        const default_action = NoAction;
        const entries = {
            (true, false) : urpf_check_fail();
            (true, true) : urpf_check_success();
        }
        size = 4;
    }


    apply {
        urpf_decision.apply();
    }
}



//-----------------------------------------------------------------------------
// Table sizes.
//-----------------------------------------------------------------------------
const bit<32> TUNNEL_TO_VRF_TABLE_SIZE = 8192;
const bit<32> INGRESS_STATICTICS_TABLE_SIZE = 8192;
const bit<32> IPV4_LPM_TABLE_SIZE = 50 * 1024;
const bit<32> IPV4_HOST_TABLE_SIZE = 1000 * 1024;

control SwitchIngress_b(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    Fibv4(IPV4_LPM_TABLE_SIZE, IPV4_HOST_TABLE_SIZE) ipv4_fib;
    EgressPortRedirect(EGRESS_PORT_REDIRECT_TABLE_SIZE) egress_port_redirect;

    apply {
        ipv4_fib.apply(ig_md.common, ig_md.flags.common);
        add_bridged_pb_to_pc_md(hdr.bridged_pb_to_pc, ig_md.common, ig_md.flags.common, ig_md.checks.common);
        egress_port_redirect.apply(ig_md);
    }
}

control SwitchEgress_b(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    PktValidation() validation;
    TupleHash(HASH_TABLE_SIZE) hash;
    VrfMapping(TUNNEL_TO_VRF_TABLE_SIZE, VRF_SIZE) vrf_mapping;
    UrpfPrepare() urpf_pre;
    IngressStatistics(INGRESS_STATICTICS_TABLE_SIZE) statistics;


    apply {
        validation.apply(hdr, eg_md.common, eg_md.flags.common);
        if (eg_md.common.pkt_src == SWITCH_PKT_SRC_BRIDGED_CROSS_VRF) {
            eg_md.common.tunnel.type = eg_md.cross_vrf_data.tun_type;
            eg_md.common.tunnel.key = eg_md.cross_vrf_data.tun_key;
        }
        hash.apply(hdr, eg_md.common);
        vrf_mapping.apply(hdr, eg_md.common, eg_md.flags.common, eg_md.checks.common);
        urpf_pre.apply(eg_md.common, eg_md.checks.common);
        statistics.apply(eg_md.common, eg_md.checks.common);
        add_bridged_pb_recirc_md(hdr.bridged_pb_recirc, eg_md.common, eg_md.checks.common);
    }
}



/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/* This is the P4-16 core library, which declares some built-in P4 constructs using P4 */


/**
 * Copyright 2013-2021 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */



//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
// Table sizes.
//-----------------------------------------------------------------------------
const bit<32> IPV6_LPM_TABLE_SIZE = 50 * 1024;
const bit<32> IPV6_HOST_TABLE_SIZE = 200 * 1024;

const bit<32> ECMP_GROUP_TABLE_SIZE = 4 * 1024;
const bit<32> ECMP_MAX_MEMBERS_PER_GROUP = 64;
const bit<32> ECMP_SELECT_TABLE_SIZE = 4 * 1024 * 64;
const bit<32> NEXTHOP_TO_MGID_TABLE_SIZE = 4 * 1024 * 64;

const bit<32> INGRESS_ACL_TABLE_SIZE = 1024;
const bit<32> INGRESS_SYSTEM_ACL_TABLE_SIZE = 1024;
const bit<32> INGRESS_CAPTURE_TABLE_SIZE = 1024;
const bit<32> INGRESS_METER_TABLE_SIZE = 1024;
const bit<32> INGRESS_DROP_STATISTICS_TABLE_SIZE = 1024;

control SwitchIngress_c(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    Ecmp(ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE, ECMP_MAX_MEMBERS_PER_GROUP) ecmp;
    Nexthop2Mgid(NEXTHOP_TO_MGID_TABLE_SIZE) nexthop2mgid;
    EgressPortRedirect(EGRESS_PORT_REDIRECT_TABLE_SIZE) egress_port_redirect;
    UrpfDecision() urpf_decision;
    IpAcl(INGRESS_ACL_TABLE_SIZE) ingress_acl;
    IngressSystemAcl(INGRESS_SYSTEM_ACL_TABLE_SIZE) ingress_system_acl;
    Capture(INGRESS_CAPTURE_TABLE_SIZE) ingress_capture;
    IngressMeter(INGRESS_METER_TABLE_SIZE) ingress_meter;
    DropStatistics(INGRESS_DROP_STATISTICS_TABLE_SIZE) ingress_drop_statistics;
    TTLCheck() ttl_check;

    apply {
        urpf_decision.apply(hdr, ig_md.common, ig_md.flags.common, ig_md.checks.common);
        ttl_check.apply(hdr, ig_md.common, ig_md.flags.common);
        if (!ig_md.checks.common.urpf) {
            ecmp.apply(ig_md.common);
            nexthop2mgid.apply(ig_md.common);
        }
        ingress_acl.apply(ig_md.common);
        ingress_capture.apply(ig_md.common);
        ingress_system_acl.apply(ig_md.common, ig_intr_md_for_dprsr, hdr);
        ingress_meter.apply(ig_md.common, ig_intr_md_for_dprsr);
        ingress_drop_statistics.apply(ig_md.common);

        if (ig_md.common.pkt_action == PKT_ACTION_TO_CPU
                    || ig_md.common.pkt_action == PKT_ACTION_DIRECT_TO_PORT) {
            add_bridged_bypass_md(hdr, ig_md.common);
        } else {
            add_bridged_pc_to_pd_md(hdr, ig_md.common);
        }
        egress_port_redirect.apply(ig_md);
    }
}

control SwitchEgress_c(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    Fibv6(IPV6_LPM_TABLE_SIZE, IPV6_HOST_TABLE_SIZE) ipv6_fib;

    apply {
        ipv6_fib.apply(eg_md.common, eg_md.flags.common);
        add_bridged_pc_recirc_md(hdr.bridged_pc_recirc, eg_md.common, eg_md.flags.common, eg_md.checks.common);
    }
}



/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/* This is the P4-16 core library, which declares some built-in P4 constructs using P4 */


/**
 * Copyright 2013-2021 Intel Corporation.
 *
 * This software and the related documents are Intel copyrighted materials, and your use of them
 * is governed by the express license under which they were provided to you ("License"). Unless
 * the License provides otherwise, you may not use, modify, copy, publish, distribute, disclose
 * or transmit this software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or implied
 * warranties, other than those that are expressly stated in the License.
 */



//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------












control IPv4Fragment(inout switch_header_t hdr,
                    inout switch_common_metadata_t switch_md,
                    inout switch_common_flags_t switch_flags,
                    in ingress_intrinsic_metadata_t ig_intr_md,
                    in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
                    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    bit<16> max_val1;
    bit<16> max_val2;
    bit<16> frag_range_upper_bound;

    Counter<bit<64>, switch_vrf_t>(SWITCH_VRF_SPEC_MAX + 1, CounterType_t.PACKETS) vrf_ip_frag_counter;

    action fragment_helper() {
        frag_range_upper_bound = switch_md.tunnel.mtu + 16w400;
    }

    action fragment_mark(){
        ig_intr_md_for_dprsr.mirror_type = 2;

        switch_flags.fragment_labeled = true;

        switch_md.mirror.src = SWITCH_PKT_SRC_IP_FRAG_1;
        switch_md.mirror.type = 2;
        switch_md.mirror.timestamp = ig_intr_from_prsr.global_tstamp[31:0];
        //session_id and eg_port are mapped
        switch_md.mirror.session_id = (switch_mirror_session_t)ig_intr_md.ingress_port + 100;
    }

    apply {
        fragment_helper();

        max_val1 = max(hdr.ipv4.total_len, switch_md.tunnel.mtu);
        max_val2 = max(hdr.ipv4.total_len, frag_range_upper_bound);
        if (hdr.ipv4.total_len != switch_md.tunnel.mtu &&
            max_val1 == hdr.ipv4.total_len &&
            max_val2 == frag_range_upper_bound) {
            fragment_mark();
            vrf_ip_frag_counter.count(switch_md.vrf);
        } else {
            switch_flags.fragment_labeled = false;
        }
    }
}

control TcpMssMod(inout switch_header_t hdr,
                inout switch_common_metadata_t switch_md,
                inout switch_common_flags_t switch_flags) {
    bit<16> expect_mss;
    bit<16> max_value;
    action tcp_mss_mod_helper() {
        expect_mss = switch_md.tunnel.mtu - 16w40;
    }

    apply {
        tcp_mss_mod_helper();

        if (hdr.tcp_options_mss.isValid()) {
            max_value = max(hdr.tcp_options_mss.mss, expect_mss);
            if (max_value == hdr.tcp_options_mss.mss) {
                hdr.tcp_options_mss.mss = expect_mss;
            }
        }

        if (hdr.tcp_options_1b_before.isValid()) {
            switch_flags.tcp_checksum_odd = true;
            switch_flags.tcp_checksum_even = false;
        } else {
            switch_flags.tcp_checksum_odd = false;
            switch_flags.tcp_checksum_even = true;
        }
    }
}



//-----------------------------------------------------------------------------
// Table sizes.
//-----------------------------------------------------------------------------
const bit<32> MC_RID_MAP_NH_SIZE = 10 * 1024;
const bit<32> TUNNEL_NEXTHOP_TABLE_SIZE = 630 * 1024;

control SwitchIngress_d(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    EgressPortRedirect(EGRESS_PORT_REDIRECT_TABLE_SIZE) egress_port_redirect;
    IPv4Fragment() ipv4_fragment;
    TcpMssMod() tcp_mss_mod;

    apply {
        // @in_hash{ig_md.common.drop_reason = hdr.bridged_pd_recirc.base.drop_reason;}
        if (ig_md.common.tunnel.to_local == 1) {
            add_bridged_cross_vrf_md(hdr.bridged_cross_vrf, ig_md.common);
        } else {
            tcp_mss_mod.apply(hdr, ig_md.common, ig_md.flags.common);
            ipv4_fragment.apply(hdr, ig_md.common, ig_md.flags.common, ig_intr_md, ig_intr_from_prsr, ig_intr_md_for_dprsr);
            add_bridged_pd_to_pa_md(hdr.bridged_pd_to_pa, ig_md.common);
        }
        egress_port_redirect.apply(ig_md);
    }
}

control SwitchEgress_d(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    TunnelDecap() tunnel_decap;
    Rid2Nexthop(MC_RID_MAP_NH_SIZE) mc_rid_to_nh;
    TunnelNexthop(TUNNEL_NEXTHOP_TABLE_SIZE) tunnel_nexthop;

    apply {
        mc_rid_to_nh.apply(eg_md.common, eg_intr_md);
        tunnel_nexthop.apply(hdr, eg_md.common);
        if (eg_md.common.tunnel.to_local == 0) {
            tunnel_decap.apply(hdr, eg_md.common);
        }
        add_bridged_pd_recirc_md(hdr.bridged_pd_recirc, eg_md.common);
    }
}






//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------




//=============================================================================
// Ingress parser a
//=============================================================================
parser SwitchIngressParser_a(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
     ig_md.common.pkt_action = PKT_ACTION_ACCEPT;
        ig_md.common.port = ig_intr_md.ingress_port;

        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            default : parse_port_metadata;
        }
    }

    state parse_resubmit {
        transition accept;
    }

    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition accept;
    }
}

//=============================================================================
// Ingress deparser a
//=============================================================================
control SwitchIngressDeparser_a(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr.bridged_pa_to_pb);
    }
}


//----------------------------------------------------------------------------
// Egress parser a
//----------------------------------------------------------------------------
parser SwitchEgressParser_a(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    @critical
    state start {
        pkt.extract(eg_intr_md);
        eg_md.common.pkt_length = eg_intr_md.pkt_length;

        switch_pkt_src_t pkt_src_type = pkt.lookahead<switch_pkt_src_t>();
        transition select(pkt_src_type) {
            SWITCH_PKT_SRC_BRIDGED_BYPASS : parse_bridged_bypass_pkt;
            SWITCH_PKT_SRC_BRIDGED_PD_TO_PA : parse_bridged_pd_to_pa_pkt;
            SWITCH_PKT_SRC_IP_FRAG_1 : parse_frag1_metadata;
            SWITCH_PKT_SRC_IP_FRAG_2 : parse_bridged_pd_to_pa_pkt;
            default: accept;
        }
    }

    state parse_bridged_bypass_pkt {
        pkt.extract(hdr.bridged_bypass);
        eg_md.common.pkt_src = hdr.bridged_bypass.src;
        eg_md.common.pkt_action = hdr.bridged_bypass.base.pkt_action;
        transition accept;
    }

    state parse_frag1_metadata {
        switch_mirror_metadata_t mirror_meta;
        pkt.extract(mirror_meta);
        transition parse_bridged_pd_to_pa_pkt;
    }

    state parse_bridged_pd_to_pa_pkt {
        pkt.extract(hdr.bridged_pd_to_pa);
        eg_md.common.pkt_src = hdr.bridged_pd_to_pa.src;
        eg_md.common.port = hdr.bridged_pd_to_pa.base.ig_port;
        eg_md.common.pkt_action = hdr.bridged_pd_to_pa.base.pkt_action;
        eg_md.common.vrf = hdr.bridged_pd_to_pa.base.vrf;
        eg_md.common.inner_five_tuples_hash = hdr.bridged_pd_to_pa.base.inner_five_tuples_hash;
        eg_md.common.vxlan_src_port_hash = hdr.bridged_pd_to_pa.base.vxlan_src_port_hash;
        eg_md.common.tunnel.type = hdr.bridged_pd_to_pa.base.tun_type;
        eg_md.common.tunnel.key = hdr.bridged_pd_to_pa.base.tun_key;
        eg_md.common.tunnel.vm_addr = hdr.bridged_pd_to_pa.base.vm_addr;
        eg_md.common.tunnel.dst_addr = hdr.bridged_pd_to_pa.base.tun_dst_addr;
        eg_md.common.tunnel.gre_type = hdr.bridged_pd_to_pa.base.gre_type;
        eg_md.common.inner_neighbor_index = hdr.bridged_pd_to_pa.base.inner_neighbor_index;
        eg_md.common.drop_reason = hdr.bridged_pd_to_pa.base.drop_reason;
        eg_md.common.lkp.l4_src_port = hdr.bridged_pd_to_pa.base.inner_l4_src_port;
        eg_md.common.lkp.l4_dst_port = hdr.bridged_pd_to_pa.base.inner_l4_dst_port;
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x0800 : parse_src;
            default : accept;
        }
    }

    state parse_src {
        transition select(hdr.bridged_pd_to_pa.src) {
            SWITCH_PKT_SRC_IP_FRAG_2 : parse_fragment;
            default : parse_ipv4;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        eg_md.common.lkp.ip_proto = hdr.ipv4.protocol;
        eg_md.common.lkp.ip_src_addr[63:0] = 64w0;
        eg_md.common.lkp.ip_src_addr[95:64] = hdr.ipv4.src_addr;
        eg_md.common.lkp.ip_src_addr[127:96] = 32w0;
        eg_md.common.lkp.ip_dst_addr[63:0] = 64w0;
        eg_md.common.lkp.ip_dst_addr[95:64] = hdr.ipv4.dst_addr;
        eg_md.common.lkp.ip_dst_addr[127:96] = 32w0;

        transition accept;
    }

    state parse_fragment {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            5 : parse_do_fragment_2;
            default : accept;
        }
    }

    state parse_do_fragment_2 {
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);//320byte
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(128);//400byte

        pkt.extract(hdr.payload_frag);
        transition accept;
    }
}

//----------------------------------------------------------------------------
// Egress deparser a
//----------------------------------------------------------------------------
control SwitchEgressDeparser_a(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    apply {
        hdr.ipv4.hdr_checksum = ipv4_checksum.update({
            hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.total_len,
            hdr.ipv4.identification,
            hdr.ipv4.flag_rs,
            hdr.ipv4.flag_df,
            hdr.ipv4.flag_mf,
            hdr.ipv4.frag_offset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.src_addr,
            hdr.ipv4.dst_addr});

        if (eg_md.flags.common.inner_ipv4_checksum_update_en) {
            hdr.inner_ipv4.hdr_checksum = inner_ipv4_checksum.update({
                hdr.inner_ipv4.version,
                hdr.inner_ipv4.ihl,
                hdr.inner_ipv4.diffserv,
                hdr.inner_ipv4.total_len,
                hdr.inner_ipv4.identification,
                hdr.inner_ipv4.flag_rs,
                hdr.inner_ipv4.flag_df,
                hdr.inner_ipv4.flag_mf,
                hdr.inner_ipv4.frag_offset,
                hdr.inner_ipv4.ttl,
                hdr.inner_ipv4.protocol,
                hdr.inner_ipv4.src_addr,
                hdr.inner_ipv4.dst_addr});
        }
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.gre1);
        pkt.emit(hdr.gre2);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.payload_frag);
    }
}






//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------




//=============================================================================
// Ingress parser b
//=============================================================================
parser SwitchIngressParser_b(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);

        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            default : parse_port_metadata;
        }
    }

    state parse_resubmit {
        transition accept;
    }

    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_bridged_pb_recirc;
    }

    state parse_bridged_pb_recirc {
        pkt.extract(hdr.bridged_pb_recirc);
        ig_md.common.port = hdr.bridged_pb_recirc.base.ig_port;
        ig_md.common.pkt_src = hdr.bridged_pb_recirc.src;
        ig_md.common.pkt_action = hdr.bridged_pb_recirc.base.pkt_action;
        ig_md.common.vrf = hdr.bridged_pb_recirc.base.vrf;
        ig_md.common.inner_five_tuples_hash = hdr.bridged_pb_recirc.base.inner_five_tuples_hash;
        ig_md.common.vxlan_src_port_hash = hdr.bridged_pb_recirc.base.vxlan_src_port_hash;
        ig_md.common.lkp.ip_type = hdr.bridged_pb_recirc.base.ip_type;
        ig_md.common.lkp.ip_dst_addr = hdr.bridged_pb_recirc.base.lkp_ip_addr;
        ig_md.checks.common.urpf = hdr.bridged_pb_recirc.base.urpf;
        ig_md.common.drop_reason = hdr.bridged_pb_recirc.base.drop_reason;

        transition accept;
    }
}

//=============================================================================
// Ingress deparser b
//=============================================================================
control SwitchIngressDeparser_b(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr.bridged_pb_to_pc);
    }
}


//----------------------------------------------------------------------------
// Egress parser b
//----------------------------------------------------------------------------
parser SwitchEgressParser_b(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    value_set<ipv4_addr_t>(32) vips;
    value_set<ipv4_addr_t>(16) localips;
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    @critical
    state start {
        pkt.extract(eg_intr_md);
        eg_md.common.pkt_length = eg_intr_md.pkt_length;

        switch_pkt_src_t pkt_src_type = pkt.lookahead<switch_pkt_src_t>();
        transition select(pkt_src_type) {
            SWITCH_PKT_SRC_BRIDGED_PA_TO_PB : parse_bridged_pa_to_pb_pkt;
            SWITCH_PKT_SRC_BRIDGED_URPF : parse_bridged_urpf_pkt;
            SWITCH_PKT_SRC_BRIDGED_CROSS_VRF : parse_bridged_cross_vrf_pkt;
            default: accept;
        }
    }

    state parse_bridged_pa_to_pb_pkt {
        pkt.extract(hdr.bridged_pa_to_pb);
        eg_md.common.pkt_src = hdr.bridged_pa_to_pb.src;
        eg_md.common.port = hdr.bridged_pa_to_pb.base.ig_port;

        transition fabric_header_select;
    }

    state parse_bridged_urpf_pkt {
        pkt.extract(hdr.bridged_urpf);
        eg_md.common.pkt_src = hdr.bridged_urpf.src;
        eg_md.common.port = hdr.bridged_urpf.base.ig_port;

        transition fabric_header_select;
    }

    state parse_bridged_cross_vrf_pkt {
        pkt.extract(hdr.bridged_cross_vrf);
        eg_md.common.pkt_src = hdr.bridged_cross_vrf.src;
        eg_md.cross_vrf_data.tun_type = hdr.bridged_cross_vrf.base.tun_type;
        eg_md.cross_vrf_data.tun_key = hdr.bridged_cross_vrf.base.tun_key;
        eg_md.common.port = hdr.bridged_cross_vrf.base.ig_port;

        transition fabric_header_select;
    }

    state fabric_header_select {
        ethernet_h eth = pkt.lookahead<ethernet_h>();
        transition select(eth.ether_type) {
            0x9000 : parse_fabric;
            default : parse_packet;
        }
    }

    state parse_fabric {
        pkt.extract(hdr.fabric);
        eg_md.common.pkt_action = PKT_ACTION_DIRECT_TO_PORT;
        transition accept;
    }

    state parse_packet {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x0800 : parse_ip_type;
            0x0806 : parse_arp_type;
            0x88CC : parse_lldp_type;
            0x8809 : parse_to_cpu;
            default : drop_ethertype_no_support_pkt;
        }
    }

    state drop_ethertype_no_support_pkt {
        eg_md.common.pkt_action = PKT_ACTION_DROP;
        eg_md.common.drop_reason.ethertype_no_support = true;
        transition accept;
    }

    state parse_arp_type {
        eg_md.common.lkp.mac_type = 0x0806;
        eg_md.common.pkt_action = PKT_ACTION_TO_CPU;
        transition accept;
    }

    state parse_lldp_type {
        eg_md.common.lkp.mac_type = 0x88CC;
        eg_md.common.pkt_action = PKT_ACTION_TO_CPU;
        transition accept;
    }

    state parse_to_cpu {
        eg_md.common.pkt_action = PKT_ACTION_TO_CPU;
        transition accept;
    }

    state parse_ip_type {
        ipv4_h ip = pkt.lookahead<ipv4_h>();
        transition select (ip.dst_addr) {
            vips : parse_ipv4;
            localips : parse_local_ips;
            default : drop_dip_no_terminate_pkt;
        }
    }

    state parse_local_ips {
        eg_md.common.pkt_action = PKT_ACTION_TO_CPU;
        transition accept;
    }

    state drop_dip_no_terminate_pkt {
        eg_md.common.pkt_action = PKT_ACTION_DROP;
        eg_md.common.drop_reason.dip_no_terminate = true;
        transition accept;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        eg_md.common.lkp.ip_proto = hdr.ipv4.protocol;
        ipv4_checksum.add(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
             5 : parse_ipv4_no_options;
             6 : parse_ipv4_options_1;
             7 : parse_ipv4_options_2;
             8 : parse_ipv4_options_3;
             9 : parse_ipv4_options_4;
            10 : parse_ipv4_options_5;
            11 : parse_ipv4_options_6;
            12 : parse_ipv4_options_7;
            13 : parse_ipv4_options_8;
            14 : parse_ipv4_options_9;
            15 : parse_ipv4_options_10;
            default: drop_iphdr_exceed_maxlen_pkt;
        }
    }

    state drop_iphdr_exceed_maxlen_pkt {
        eg_md.common.pkt_action = PKT_ACTION_DROP;
        eg_md.common.drop_reason.iphdr_exceed_maxlen = true;
        transition accept;
    }

    state parse_ipv4_options_1 {
        pkt.extract(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_2 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_3 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_4 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_5 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_5);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_6 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_5);
        ipv4_checksum.add(hdr.ip_opt_word_6);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_7 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_5);
        ipv4_checksum.add(hdr.ip_opt_word_6);
        ipv4_checksum.add(hdr.ip_opt_word_7);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_8 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_5);
        ipv4_checksum.add(hdr.ip_opt_word_6);
        ipv4_checksum.add(hdr.ip_opt_word_7);
        ipv4_checksum.add(hdr.ip_opt_word_8);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_9 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_5);
        ipv4_checksum.add(hdr.ip_opt_word_6);
        ipv4_checksum.add(hdr.ip_opt_word_7);
        ipv4_checksum.add(hdr.ip_opt_word_8);
        ipv4_checksum.add(hdr.ip_opt_word_9);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_10 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        pkt.extract(hdr.ip_opt_word_10);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_5);
        ipv4_checksum.add(hdr.ip_opt_word_6);
        ipv4_checksum.add(hdr.ip_opt_word_7);
        ipv4_checksum.add(hdr.ip_opt_word_8);
        ipv4_checksum.add(hdr.ip_opt_word_9);
        ipv4_checksum.add(hdr.ip_opt_word_10);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        eg_md.flags.common.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol) {
            (6) : parse_tcp;
            (17) : parse_udp;
            (47) : parse_gre_common;
            default : parse_to_cpu;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        eg_md.common.lkp.l4_src_port = hdr.tcp.src_port;
        eg_md.common.lkp.l4_dst_port = hdr.tcp.dst_port;
        eg_md.common.pkt_action = PKT_ACTION_TO_CPU;
        transition accept;
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            4789 : parse_vxlan;
            default : parse_to_cpu;
        }
    }

    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            0x0800 : parse_inner_ipv4;
            0x0806 : parse_arp_type;
            default : drop_inner_ethertype_no_support_pkt;
        }
    }

    state drop_inner_ethertype_no_support_pkt {
        eg_md.common.pkt_action = PKT_ACTION_DROP;
        eg_md.common.drop_reason.inner_ethertype_no_support = true;
        transition accept;
    }

    state parse_gre_common {
        gre_common_h gre = pkt.lookahead<gre_common_h>();
        transition select (gre.C) {
            1 : parse_gre2;
            0 : parse_gre1;
        }
    }

    state parse_gre1 {
        pkt.extract(hdr.gre1);
        transition select(hdr.gre1.protocol) {
            0x0800 : parse_inner_ipv4;
            default : drop_gre_inner_proto_no_support_pkt;
        }
    }

    state parse_gre2 {
        pkt.extract(hdr.gre2);
        transition select(hdr.gre2.protocol) {
            0x0800 : parse_inner_ipv4;
            default : drop_gre_inner_proto_no_support_pkt;
        }
    }

    state drop_gre_inner_proto_no_support_pkt {
        eg_md.common.pkt_action = PKT_ACTION_DROP;
        eg_md.common.drop_reason.gre_inner_proto_no_support = true;
        transition accept;
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        inner_ipv4_checksum.add(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.ihl) {
             5 : parse_inner_ipv4_no_options;
             6 : parse_inner_ipv4_options_1;
             7 : parse_inner_ipv4_options_2;
             8 : parse_inner_ipv4_options_3;
             9 : parse_inner_ipv4_options_4;
            10 : parse_inner_ipv4_options_5;
            11 : parse_inner_ipv4_options_6;
            12 : parse_inner_ipv4_options_7;
            13 : parse_inner_ipv4_options_8;
            14 : parse_inner_ipv4_options_9;
            15 : parse_inner_ipv4_options_10;
            default: drop_inner_iphdr_exceed_maxlen_pkt;
        }
    }

    state drop_inner_iphdr_exceed_maxlen_pkt {
        eg_md.common.pkt_action = PKT_ACTION_DROP;
        eg_md.common.drop_reason.inner_iphdr_exceed_maxlen = true;
        transition accept;
    }

    state parse_inner_ipv4_options_1 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_1);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_2 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_1);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_2);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_3 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_1);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_2);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_3);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_4 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_1);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_2);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_3);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_4);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_5 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        pkt.extract(hdr.inner_ip_opt_word_5);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_1);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_2);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_3);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_4);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_5);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_6 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        pkt.extract(hdr.inner_ip_opt_word_5);
        pkt.extract(hdr.inner_ip_opt_word_6);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_1);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_2);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_3);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_4);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_5);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_6);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_7 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        pkt.extract(hdr.inner_ip_opt_word_5);
        pkt.extract(hdr.inner_ip_opt_word_6);
        pkt.extract(hdr.inner_ip_opt_word_7);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_1);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_2);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_3);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_4);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_5);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_6);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_7);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_8 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        pkt.extract(hdr.inner_ip_opt_word_5);
        pkt.extract(hdr.inner_ip_opt_word_6);
        pkt.extract(hdr.inner_ip_opt_word_7);
        pkt.extract(hdr.inner_ip_opt_word_8);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_1);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_2);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_3);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_4);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_5);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_6);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_7);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_8);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_9 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        pkt.extract(hdr.inner_ip_opt_word_5);
        pkt.extract(hdr.inner_ip_opt_word_6);
        pkt.extract(hdr.inner_ip_opt_word_7);
        pkt.extract(hdr.inner_ip_opt_word_8);
        pkt.extract(hdr.inner_ip_opt_word_9);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_1);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_2);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_3);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_4);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_5);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_6);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_7);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_8);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_9);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_10 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        pkt.extract(hdr.inner_ip_opt_word_5);
        pkt.extract(hdr.inner_ip_opt_word_6);
        pkt.extract(hdr.inner_ip_opt_word_7);
        pkt.extract(hdr.inner_ip_opt_word_8);
        pkt.extract(hdr.inner_ip_opt_word_9);
        pkt.extract(hdr.inner_ip_opt_word_10);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_1);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_2);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_3);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_4);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_5);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_6);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_7);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_8);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_9);
        inner_ipv4_checksum.add(hdr.inner_ip_opt_word_10);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_no_options {
        eg_md.flags.common.inner_ipv4_checksum_err = inner_ipv4_checksum.verify();
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.frag_offset) {
            (1, 0) : parse_inner_icmp;
            (6, 0) : parse_inner_tcp;
            (17, 0) : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parse_inner_icmp {
        pkt.extract(hdr.inner_icmp);
        transition accept;
    }
}

//----------------------------------------------------------------------------
// Egress deparser b
//----------------------------------------------------------------------------
control SwitchEgressDeparser_b(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr.bridged_pb_recirc);
        pkt.emit(hdr.fabric);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ip_opt_word_1);
        pkt.emit(hdr.ip_opt_word_2);
        pkt.emit(hdr.ip_opt_word_3);
        pkt.emit(hdr.ip_opt_word_4);
        pkt.emit(hdr.ip_opt_word_5);
        pkt.emit(hdr.ip_opt_word_6);
        pkt.emit(hdr.ip_opt_word_7);
        pkt.emit(hdr.ip_opt_word_8);
        pkt.emit(hdr.ip_opt_word_9);
        pkt.emit(hdr.ip_opt_word_10);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.gre1);
        pkt.emit(hdr.gre2);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp); // Ingress only.
        pkt.emit(hdr.icmp); // Ingress only.
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_arp);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ip_opt_word_1);
        pkt.emit(hdr.inner_ip_opt_word_2);
        pkt.emit(hdr.inner_ip_opt_word_3);
        pkt.emit(hdr.inner_ip_opt_word_4);
        pkt.emit(hdr.inner_ip_opt_word_5);
        pkt.emit(hdr.inner_ip_opt_word_6);
        pkt.emit(hdr.inner_ip_opt_word_7);
        pkt.emit(hdr.inner_ip_opt_word_8);
        pkt.emit(hdr.inner_ip_opt_word_9);
        pkt.emit(hdr.inner_ip_opt_word_10);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
    }
}






//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------




//=============================================================================
// Ingress parser c
//=============================================================================
parser SwitchIngressParser_c(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    value_set<ipv4_addr_t>(32) vips;
    value_set<ipv4_addr_t>(16) localips;

    state start {
        pkt.extract(ig_intr_md);

        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            default : parse_port_metadata;
        }
    }

    state parse_resubmit {
        transition parse_packet;
    }

    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_bridged_pc_recirc_pkt;
    }

    state parse_bridged_pc_recirc_pkt {
        pkt.extract(hdr.bridged_pc_recirc);

        ig_md.common.port = hdr.bridged_pc_recirc.base.ig_port;
        ig_md.common.pkt_src = hdr.bridged_pc_recirc.src;
        ig_md.common.pkt_action = hdr.bridged_pc_recirc.base.pkt_action;
        ig_md.common.vrf = hdr.bridged_pc_recirc.base.vrf;
        ig_md.common.inner_five_tuples_hash = hdr.bridged_pc_recirc.base.inner_five_tuples_hash;
        ig_md.common.vxlan_src_port_hash = hdr.bridged_pc_recirc.base.vxlan_src_port_hash;
        ig_md.checks.common.urpf = hdr.bridged_pc_recirc.base.urpf;
        ig_md.common.nexthop = hdr.bridged_pc_recirc.base.nexthop;
        ig_md.common.drop_reason = hdr.bridged_pc_recirc.base.drop_reason;
        ig_md.flags.common.nottl = hdr.bridged_pc_recirc.base.nottl;

        transition fabric_header_select;
    }

    state fabric_header_select {
        ethernet_h eth = pkt.lookahead<ethernet_h>();
        transition select(eth.ether_type) {
            0x9000 : parse_fabric;
            default : parse_packet;
        }
    }

    state parse_fabric {
        pkt.extract(hdr.fabric);
        transition accept;
    }

    state parse_packet {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x0800 : parse_ip_type;
            0x0806 : parse_arp_type;
            0x88CC : parse_lldp_type;
            0x8809 : parse_to_cpu;
            default : accept;
        }
    }

    state parse_arp_type {
        ig_md.common.lkp.mac_type = 0x0806;
        transition accept;
    }

    state parse_lldp_type {
        ig_md.common.lkp.mac_type = 0x88CC;
        transition accept;
    }

    state parse_to_cpu {
        transition accept;
    }

    state parse_ip_type {
        ipv4_h ip = pkt.lookahead<ipv4_h>();
        transition select (ip.dst_addr) {
            vips : parse_ipv4;
            localips : parse_local_ips;
            default : accept;
        }
    }

    state parse_local_ips {
        transition parse_local_ipv4;
    }

    state parse_local_ipv4 {
        pkt.extract(hdr.ipv4);
        ig_md.common.lkp.ip_proto = hdr.ipv4.protocol;
        transition select(hdr.ipv4.ihl) {
             5 : parse_local_ipv4_no_options;
             6 : parse_local_ipv4_options_1;
             7 : parse_local_ipv4_options_2;
             8 : parse_local_ipv4_options_3;
             9 : parse_local_ipv4_options_4;
            10 : parse_local_ipv4_options_5;
            11 : parse_local_ipv4_options_6;
            12 : parse_local_ipv4_options_7;
            13 : parse_local_ipv4_options_8;
            14 : parse_local_ipv4_options_9;
            15 : parse_local_ipv4_options_10;
            default: accept;
        }
    }

    state parse_local_ipv4_options_1 {
        pkt.extract(hdr.ip_opt_word_1);
        transition parse_local_ipv4_no_options;
    }

    state parse_local_ipv4_options_2 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        transition parse_local_ipv4_no_options;
    }

    state parse_local_ipv4_options_3 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        transition parse_local_ipv4_no_options;
    }

    state parse_local_ipv4_options_4 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        transition parse_local_ipv4_no_options;
    }

    state parse_local_ipv4_options_5 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        transition parse_local_ipv4_no_options;
    }

    state parse_local_ipv4_options_6 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        transition parse_local_ipv4_no_options;
    }

    state parse_local_ipv4_options_7 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        transition parse_local_ipv4_no_options;
    }

    state parse_local_ipv4_options_8 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        transition parse_local_ipv4_no_options;
    }

    state parse_local_ipv4_options_9 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        transition parse_local_ipv4_no_options;
    }

    state parse_local_ipv4_options_10 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        pkt.extract(hdr.ip_opt_word_10);
        transition parse_local_ipv4_no_options;
    }

    state parse_local_ipv4_no_options {
        transition select(hdr.ipv4.protocol) {
            (17) : parse_local_udp;
            (6) : parse_loacl_tcp;
            default : accept;
        }
    }

    state parse_local_udp {
        pkt.extract(hdr.udp);
        ig_md.common.lkp.l4_src_port = hdr.udp.src_port;
        ig_md.common.lkp.l4_dst_port = hdr.udp.dst_port;
        transition accept;
    }

    state parse_loacl_tcp {
        pkt.extract(hdr.tcp);
        ig_md.common.lkp.l4_src_port = hdr.tcp.src_port;
        ig_md.common.lkp.l4_dst_port = hdr.tcp.dst_port;
        transition accept;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ig_md.common.lkp.ip_proto = hdr.ipv4.protocol;
        transition select(hdr.ipv4.ihl) {
             5 : parse_ipv4_no_options;
             6 : parse_ipv4_options_1;
             7 : parse_ipv4_options_2;
             8 : parse_ipv4_options_3;
             9 : parse_ipv4_options_4;
            10 : parse_ipv4_options_5;
            11 : parse_ipv4_options_6;
            12 : parse_ipv4_options_7;
            13 : parse_ipv4_options_8;
            14 : parse_ipv4_options_9;
            15 : parse_ipv4_options_10;
            default: accept;
        }
    }

    state parse_ipv4_options_1 {
        pkt.extract(hdr.ip_opt_word_1);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_2 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_3 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_4 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_5 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_6 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_7 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_8 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_9 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_10 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        pkt.extract(hdr.ip_opt_word_10);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        transition select(hdr.ipv4.protocol) {
            (6) : parse_tcp;
            (17) : parse_udp;
            (47) : parse_gre_common;
            default : parse_to_cpu;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        ig_md.common.lkp.l4_src_port = hdr.tcp.src_port;
        ig_md.common.lkp.l4_dst_port = hdr.tcp.dst_port;
        transition accept;
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            4789 : parse_vxlan;
            default : parse_to_cpu;
        }
    }

    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            0x0800 : parse_inner_ipv4;
            0x0806 : parse_arp_type;
            default : accept;
        }
    }

    state parse_gre_common {
        gre_common_h gre = pkt.lookahead<gre_common_h>();
        transition select (gre.C) {
            1 : parse_gre2;
            0 : parse_gre1;
        }
    }

    state parse_gre1 {
        pkt.extract(hdr.gre1);
        transition select(hdr.gre1.protocol) {
            0x0800 : parse_inner_ipv4;
            default : accept;
        }
    }

    state parse_gre2 {
        pkt.extract(hdr.gre2);
        transition select(hdr.gre2.protocol) {
            0x0800 : parse_inner_ipv4;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.ihl) {
             5 : parse_inner_ipv4_no_options;
             6 : parse_inner_ipv4_options_1;
             7 : parse_inner_ipv4_options_2;
             8 : parse_inner_ipv4_options_3;
             9 : parse_inner_ipv4_options_4;
            10 : parse_inner_ipv4_options_5;
            11 : parse_inner_ipv4_options_6;
            12 : parse_inner_ipv4_options_7;
            13 : parse_inner_ipv4_options_8;
            14 : parse_inner_ipv4_options_9;
            15 : parse_inner_ipv4_options_10;
            default: accept;
        }
    }

    state parse_inner_ipv4_options_1 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_2 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_3 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_4 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_5 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        pkt.extract(hdr.inner_ip_opt_word_5);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_6 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        pkt.extract(hdr.inner_ip_opt_word_5);
        pkt.extract(hdr.inner_ip_opt_word_6);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_7 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        pkt.extract(hdr.inner_ip_opt_word_5);
        pkt.extract(hdr.inner_ip_opt_word_6);
        pkt.extract(hdr.inner_ip_opt_word_7);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_8 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        pkt.extract(hdr.inner_ip_opt_word_5);
        pkt.extract(hdr.inner_ip_opt_word_6);
        pkt.extract(hdr.inner_ip_opt_word_7);
        pkt.extract(hdr.inner_ip_opt_word_8);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_9 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        pkt.extract(hdr.inner_ip_opt_word_5);
        pkt.extract(hdr.inner_ip_opt_word_6);
        pkt.extract(hdr.inner_ip_opt_word_7);
        pkt.extract(hdr.inner_ip_opt_word_8);
        pkt.extract(hdr.inner_ip_opt_word_9);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_10 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        pkt.extract(hdr.inner_ip_opt_word_5);
        pkt.extract(hdr.inner_ip_opt_word_6);
        pkt.extract(hdr.inner_ip_opt_word_7);
        pkt.extract(hdr.inner_ip_opt_word_8);
        pkt.extract(hdr.inner_ip_opt_word_9);
        pkt.extract(hdr.inner_ip_opt_word_10);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_no_options {
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.flag_mf, hdr.inner_ipv4.frag_offset) {
            (1, 0, 0) : parse_inner_icmp;
            (6, 0, 0) : parse_inner_tcp;
            (17, 0, 0) : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parse_inner_icmp {
        pkt.extract(hdr.inner_icmp);
        transition accept;
    }

}

//=============================================================================
// Ingress deparser c 
//=============================================================================
control SwitchIngressDeparser_c(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr.bridged_pc_to_pd);
        pkt.emit(hdr.bridged_bypass);
        pkt.emit(hdr.fabric);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ip_opt_word_1);
        pkt.emit(hdr.ip_opt_word_2);
        pkt.emit(hdr.ip_opt_word_3);
        pkt.emit(hdr.ip_opt_word_4);
        pkt.emit(hdr.ip_opt_word_5);
        pkt.emit(hdr.ip_opt_word_6);
        pkt.emit(hdr.ip_opt_word_7);
        pkt.emit(hdr.ip_opt_word_8);
        pkt.emit(hdr.ip_opt_word_9);
        pkt.emit(hdr.ip_opt_word_10);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.gre1);
        pkt.emit(hdr.gre2);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp); // Ingress only.
        pkt.emit(hdr.icmp); // Ingress only.
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_arp);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ip_opt_word_1);
        pkt.emit(hdr.inner_ip_opt_word_2);
        pkt.emit(hdr.inner_ip_opt_word_3);
        pkt.emit(hdr.inner_ip_opt_word_4);
        pkt.emit(hdr.inner_ip_opt_word_5);
        pkt.emit(hdr.inner_ip_opt_word_6);
        pkt.emit(hdr.inner_ip_opt_word_7);
        pkt.emit(hdr.inner_ip_opt_word_8);
        pkt.emit(hdr.inner_ip_opt_word_9);
        pkt.emit(hdr.inner_ip_opt_word_10);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
    }
}


//----------------------------------------------------------------------------
// Egress parser c
//----------------------------------------------------------------------------
parser SwitchEgressParser_c(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    @critical
    state start {
        pkt.extract(eg_intr_md);
        eg_md.common.pkt_length = eg_intr_md.pkt_length;

        switch_pkt_src_t pkt_src_type = pkt.lookahead<switch_pkt_src_t>();
        transition select(pkt_src_type) {
            SWITCH_PKT_SRC_BRIDGED_PB_TO_PC : parse_bridged_pb_to_pc_pkt;
            default: accept;
        }
    }

    state parse_bridged_pb_to_pc_pkt {
        pkt.extract(hdr.bridged_pb_to_pc);
        eg_md.common.pkt_src = hdr.bridged_pb_to_pc.src;
        eg_md.common.pkt_action = hdr.bridged_pb_to_pc.base.pkt_action;
        eg_md.common.port = hdr.bridged_pb_to_pc.base.ig_port;
        eg_md.common.vrf = hdr.bridged_pb_to_pc.base.vrf;
        eg_md.common.inner_five_tuples_hash = hdr.bridged_pb_to_pc.base.inner_five_tuples_hash;
        eg_md.common.vxlan_src_port_hash = hdr.bridged_pb_to_pc.base.vxlan_src_port_hash;
        eg_md.common.lkp.ip_type = hdr.bridged_pb_to_pc.base.ip_type;
        eg_md.common.lkp.ip_dst_addr = hdr.bridged_pb_to_pc.base.lkp_ip_addr;
        eg_md.common.nexthop = hdr.bridged_pb_to_pc.base.nexthop;
        eg_md.checks.common.urpf = hdr.bridged_pb_to_pc.base.urpf;
        eg_md.common.drop_reason = hdr.bridged_pb_to_pc.base.drop_reason;
        eg_md.flags.common.nottl = hdr.bridged_pb_to_pc.base.nottl;

        transition accept;
    }
}

//----------------------------------------------------------------------------
// Egress deparser c
//----------------------------------------------------------------------------
control SwitchEgressDeparser_c(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr.bridged_pc_recirc);
    }
}






//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------




//=============================================================================
// Ingress parser d
//=============================================================================
parser SwitchIngressParser_d(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum() tcp_checksum;
    ParserCounter() pctr;

    state start {
        pkt.extract(ig_intr_md);

        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            default : parse_port_metadata;
        }
    }

    state parse_resubmit {
        transition accept;
    }

    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_bridged_pd_recirc;
    }

    state parse_bridged_pd_recirc {
        pkt.extract(hdr.bridged_pd_recirc);
        ig_md.common.pkt_src = hdr.bridged_pd_recirc.src;
        ig_md.common.port = hdr.bridged_pd_recirc.base.ig_port;
        ig_md.common.pkt_action = hdr.bridged_pd_recirc.base.pkt_action;
        ig_md.common.vrf = hdr.bridged_pd_recirc.base.vrf;
        ig_md.common.inner_five_tuples_hash = hdr.bridged_pd_recirc.base.inner_five_tuples_hash;
        ig_md.common.vxlan_src_port_hash = hdr.bridged_pd_recirc.base.vxlan_src_port_hash;
        ig_md.common.tunnel.type = hdr.bridged_pd_recirc.base.tun_type;
        ig_md.common.tunnel.key = hdr.bridged_pd_recirc.base.tun_key;
        ig_md.common.tunnel.vm_addr = hdr.bridged_pd_recirc.base.vm_addr;
        ig_md.common.tunnel.dst_addr = hdr.bridged_pd_recirc.base.tun_dst_addr;
        ig_md.common.tunnel.gre_type = hdr.bridged_pd_recirc.base.gre_type;
        ig_md.common.inner_neighbor_index = hdr.bridged_pd_recirc.base.inner_neighbor_index;
        ig_md.common.tunnel.to_local = hdr.bridged_pd_recirc.base.tunnel_to_local;
        ig_md.common.tunnel.mtu = hdr.bridged_pd_recirc.base.mtu;
        // ig_md.common.drop_reason = hdr.bridged_pd_recirc.base.drop_reason;

        transition select(hdr.bridged_pd_recirc.base.tunnel_to_local) {
            0 : parse_ethernet;
            default : accept;
        }
        // transition accept;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x0800 : parse_ipv4;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            5 : parse_ipv4_no_options;
            6 : parse_ipv4_options_1;
            7 : parse_ipv4_options_2;
            8 : parse_ipv4_options_3;
            9 : parse_ipv4_options_4;
            10 : parse_ipv4_options_5;
            11 : parse_ipv4_options_6;
            12 : parse_ipv4_options_7;
            13 : parse_ipv4_options_8;
            14 : parse_ipv4_options_9;
            15 : parse_ipv4_options_10;
            default: accept;
        }
    }

    state parse_ipv4_options_1 {
        pkt.extract(hdr.ip_opt_word_1);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_2 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_3 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_4 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_5 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_6 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_7 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_8 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_9 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_10 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        pkt.extract(hdr.ip_opt_word_10);
        transition parse_ipv4_no_options;
    }

    @dont_unroll
    state parse_ipv4_no_options {
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (6, 0) : parse_tcp;
            (17, 0) : parse_udp;
            (1, 0) : parse_icmp;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        ig_md.common.lkp.l4_src_port = hdr.udp.src_port;
        ig_md.common.lkp.l4_dst_port = hdr.udp.dst_port;
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        ig_md.common.lkp.l4_src_port[7:0] = hdr.icmp.type;
        ig_md.common.lkp.l4_src_port[15:8] = hdr.icmp.code;
        ig_md.common.lkp.l4_dst_port = 0;
        transition accept;
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);

        ig_md.common.lkp.l4_src_port = hdr.tcp.src_port;
        ig_md.common.lkp.l4_dst_port = hdr.tcp.dst_port;

        // subtract other possibly changed fields
        tcp_checksum.subtract({hdr.tcp.checksum});
        ig_md.common.origin_tcp_checksum = tcp_checksum.get();

        transition select(hdr.tcp.data_offset) {
            5 : accept;
            default : parse_tcp_option;
        }
    }

    state parse_tcp_option {
        transition select(hdr.tcp.flags[1:1]) {
            1 : parse_tcp_syn_option; // syn
            default : accept;
        }
    }

    state parse_tcp_syn_option {
        // Load the counter with a header field.
        // @param max : Maximum permitted value for counter (pre rotate/mask/add).
        // @param rotate : Right rotate (circular) the source field by this number of bits.
        // @param mask : Mask the rotated source field by 2 ^ (mask + 1) - 1.
        // @param add : Constant to add to the rotated and masked lookup field.
        pctr.set(hdr.tcp.data_offset, 15 << 4, 2, 0x5, -20); // (max, rot, mask, add)
        transition next_option_0b_align;
    }

    // Processing for data starting at byte 0 in 32b word
    @dont_unroll
    state next_option_0b_align {
        transition select(pctr.is_zero(), pctr.is_negative()) {
            (false, false) : next_option_0b_align_part2; // no TCP Option bytes left
            default : accept;
        }
    }

    @dont_unroll
    state next_option_0b_align_part2 {
        // precondition: tcp_hdr_bytes_left >= 4
        transition select(pkt.lookahead<bit<32>>()) {
            0x02000000 &&& 0xff000000 : parse_tcp_option_mss;
            0x00000000 &&& 0xfefefefe : parse_tcp_option_4b_before;
            0x00000000 &&& 0xfefefe00 : next_option_3b_align;
            0x00000000 &&& 0xfefe0000 : next_option_2b_align;
            0x00000000 &&& 0xfe000000 : next_option_1b_align;
            0x00020000 &&& 0x00ff0000 : next_option_2b_align;
            0x00030000 &&& 0x00ff0000 : next_option_3b_align;
            0x00040000 &&& 0x00ff0000 : parse_tcp_option_4b_before;
            0x00060000 &&& 0x00ff0000 : parse_tcp_option_4b_before_2b;
            0x00080000 &&& 0x00ff0000 : parse_tcp_option_8b_before;
            0x000a0000 &&& 0x00ff0000 : parse_tcp_option_8b_before_2b;
            0x000c0000 &&& 0x00ff0000 : parse_tcp_option_12b_before;
            0x000e0000 &&& 0x00ff0000 : parse_tcp_option_12b_before_2b;
            0x00100000 &&& 0x00ff0000 : parse_tcp_option_12b_before_4b;
            0x00120000 &&& 0x00ff0000 : parse_tcp_option_12b_before_6b;
            default : accept;
        }
    }

    // Processing for data starting at byte 1 in 32b word
    @dont_unroll
    state next_option_1b_align {
        transition select(pctr.is_zero(), pctr.is_negative()) {
            (false, false) : next_option_1b_align_part2; // no TCP Option bytes left
            default : accept;
        }
    }

    @dont_unroll
    state next_option_1b_align_part2 {
        // precondition: tcp_hdr_bytes_left >= 3
        transition select(pkt.lookahead<bit<32>>()[23:0]) {
            0x020000 &&& 0xff0000 : parse_tcp_option_1b_before_mss;
            0x000000 &&& 0xfefefe : parse_tcp_option_4b_before;
            0x000000 &&& 0xfefe00 : next_option_3b_align;
            0x000000 &&& 0xfe0000 : next_option_2b_align;
            0x000200 &&& 0x00ff00 : next_option_3b_align;
            0x000300 &&& 0x00ff00 : parse_tcp_option_4b_before;
            0x000400 &&& 0x00ff00 : parse_tcp_option_4b_before_1b;
            0x000600 &&& 0x00ff00 : parse_tcp_option_4b_before_3b;
            0x000800 &&& 0x00ff00 : parse_tcp_option_8b_before_1b;
            0x000a00 &&& 0x00ff00 : parse_tcp_option_8b_before_3b;
            0x000c00 &&& 0x00ff00 : parse_tcp_option_12b_before_1b;
            0x000e00 &&& 0x00ff00 : parse_tcp_option_12b_before_3b;
            0x001000 &&& 0x00ff00 : parse_tcp_option_12b_before_5b;
            0x001200 &&& 0x00ff00 : parse_tcp_option_12b_before_7b;
            default : accept;
        }
    }

    // Processing for data starting at byte 2 in 32b word
    @dont_unroll
    state next_option_2b_align {
        transition select(pctr.is_zero(), pctr.is_negative()) {
            (false, false) : next_option_2b_align_part2; // no TCP Option bytes left
            default : accept;
        }
    }

    state next_option_2b_align_part2 {
        // precondition: tcp_hdr_bytes_left >= 2
        transition select(pkt.lookahead<bit<32>>()[15:0]) {
            0x0200 &&& 0xff00 : parse_tcp_option_2b_before_mss;
            0x0000 &&& 0xfefe : parse_tcp_option_4b_before;
            0x0000 &&& 0xfe00 : next_option_3b_align;
            0x0002 &&& 0x00ff : parse_tcp_option_4b_before;
            0x0003 &&& 0x00ff : parse_tcp_option_4b_before_1b;
            0x0004 &&& 0x00ff : parse_tcp_option_4b_before_2b;
            0x0006 &&& 0x00ff : parse_tcp_option_8b_before;
            0x0008 &&& 0x00ff : parse_tcp_option_8b_before_2b;
            0x000a &&& 0x00ff : parse_tcp_option_12b_before;
            0x000c &&& 0x00ff : parse_tcp_option_12b_before_2b;
            0x000e &&& 0x00ff : parse_tcp_option_12b_before_4b;
            0x0010 &&& 0x00ff : parse_tcp_option_12b_before_6b;
            0x0012 &&& 0x00ff : parse_tcp_option_12b_before_8b;
            default : accept;
        }
    }

    // Processing for data starting at byte 3 in 32b word
    @dont_unroll
    state next_option_3b_align {
        transition select(pctr.is_zero(), pctr.is_negative()) {
            (false, false) : next_option_3b_align_part2; // no TCP Option bytes left
            default : accept;
        }
    }

    @dont_unroll
    state next_option_3b_align_part2 {
        // precondition: tcp_hdr_bytes_left >= 2
        transition select(pkt.lookahead<bit<40>>()[15:0]) {
            0x0200 &&& 0xff00 : parse_tcp_option_3b_before_mss;
            0x0000 &&& 0xfe00 : parse_tcp_option_4b_before;
            0x0002 &&& 0x00ff : parse_tcp_option_4b_before_1b;
            0x0003 &&& 0x00ff : parse_tcp_option_4b_before_2b;
            0x0004 &&& 0x00ff : parse_tcp_option_4b_before_3b;
            0x0006 &&& 0x00ff : parse_tcp_option_8b_before_1b;
            0x0008 &&& 0x00ff : parse_tcp_option_8b_before_3b;
            0x000a &&& 0x00ff : parse_tcp_option_12b_before_1b;
            0x000c &&& 0x00ff : parse_tcp_option_12b_before_3b;
            0x000e &&& 0x00ff : parse_tcp_option_12b_before_5b;
            0x0010 &&& 0x00ff : parse_tcp_option_12b_before_7b;
            0x0012 &&& 0x00ff : parse_tcp_option_12b_before_9b;
            default : accept;
        }
    }

    @dont_unroll
    state parse_tcp_option_mss {
        pkt.extract(hdr.tcp_options_mss);
        transition accept;
    }

    @dont_unroll
    state parse_tcp_option_1b_before_mss {
        pkt.extract(hdr.tcp_options_1b_before);
        pctr.decrement(1);
        transition parse_tcp_option_mss;
    }

    @dont_unroll
    state parse_tcp_option_2b_before_mss {
        pkt.extract(hdr.tcp_options_2b_before);
        pctr.decrement(2);
        transition parse_tcp_option_mss;
    }

    @dont_unroll
    state parse_tcp_option_3b_before_mss {
        pkt.extract(hdr.tcp_options_2b_before);
        pkt.extract(hdr.tcp_options_1b_before);
        pctr.decrement(3);
        transition parse_tcp_option_mss;
    }

    @dont_unroll
    state parse_tcp_option_4b_before {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(4);
        transition next_option_0b_align;
    }

    @dont_unroll
    state parse_tcp_option_4b_before_1b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(4);
        transition next_option_1b_align;
    }

    @dont_unroll
    state parse_tcp_option_4b_before_2b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(4);
        transition next_option_2b_align;
    }

    @dont_unroll
    state parse_tcp_option_4b_before_3b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(4);
        transition next_option_3b_align;
    }

    @dont_unroll
    state parse_tcp_option_8b_before {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(8);
        transition next_option_0b_align;
    }

    @dont_unroll
    state parse_tcp_option_8b_before_1b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(8);
        transition next_option_1b_align;
    }

    @dont_unroll
    state parse_tcp_option_8b_before_2b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(8);
        transition next_option_2b_align;
    }

    @dont_unroll
    state parse_tcp_option_8b_before_3b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(8);
        transition next_option_3b_align;
    }

    @dont_unroll
    state parse_tcp_option_12b_before {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(12);
        transition next_option_0b_align;
    }

    @dont_unroll
    state parse_tcp_option_12b_before_1b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(12);
        transition next_option_1b_align;
    }

    @dont_unroll
    state parse_tcp_option_12b_before_2b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(12);
        transition next_option_2b_align;
    }

    @dont_unroll
    state parse_tcp_option_12b_before_3b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(12);
        transition next_option_3b_align;
    }

    @dont_unroll
    state parse_tcp_option_12b_before_4b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(12);
        transition parse_tcp_option_4b_before;
    }

    @dont_unroll
    state parse_tcp_option_12b_before_5b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(12);
        transition parse_tcp_option_4b_before_1b;
    }

    @dont_unroll
    state parse_tcp_option_12b_before_6b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(12);
        transition parse_tcp_option_4b_before_2b;
    }

    @dont_unroll
    state parse_tcp_option_12b_before_7b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(12);
        transition parse_tcp_option_4b_before_3b;
    }

    @dont_unroll
    state parse_tcp_option_12b_before_8b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(12);
        transition parse_tcp_option_8b_before;
    }

    @dont_unroll
    state parse_tcp_option_12b_before_9b {
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pkt.extract(hdr.tcp_options_4b_before.next);
        pctr.decrement(12);
        transition parse_tcp_option_8b_before_1b;
    }
}

control IngressMirror_d(
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    Mirror() mirror;

    apply {
        if (ig_intr_md_for_dprsr.mirror_type == 2) {
            mirror.emit<switch_mirror_metadata_t>(
                (MirrorId_t)ig_md.common.mirror.session_id,
                ig_md.common.mirror);
        }
    }
}

//=============================================================================
// Ingress deparser d
//=============================================================================
control SwitchIngressDeparser_d(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    Checksum() tcp_checksum;
    IngressMirror_d() mirror;

    apply {
        if (hdr.tcp_options_mss.isValid()) {
            if (ig_md.flags.common.tcp_checksum_odd) {
                hdr.tcp.checksum = tcp_checksum.update({
                    // update other possibly changed fields
                    hdr.tcp_options_4b_before[0],
                    hdr.tcp_options_4b_before[1],
                    hdr.tcp_options_4b_before[2],
                    hdr.tcp_options_4b_before[3],
                    hdr.tcp_options_4b_before[4],
                    hdr.tcp_options_4b_before[5],
                    hdr.tcp_options_4b_before[6],
                    hdr.tcp_options_4b_before[7],
                    hdr.tcp_options_4b_before[8],
                    hdr.tcp_options_4b_before[9],
                    hdr.tcp_options_2b_before,
                    hdr.tcp_options_1b_before,
                    hdr.tcp_options_mss,
                    8w0,
                    ig_md.common.origin_tcp_checksum
                });
            }
            if (ig_md.flags.common.tcp_checksum_even) {
                hdr.tcp.checksum = tcp_checksum.update({
                    // update other possibly changed fields
                    hdr.tcp_options_4b_before[0],
                    hdr.tcp_options_4b_before[1],
                    hdr.tcp_options_4b_before[2],
                    hdr.tcp_options_4b_before[3],
                    hdr.tcp_options_4b_before[4],
                    hdr.tcp_options_4b_before[5],
                    hdr.tcp_options_4b_before[6],
                    hdr.tcp_options_4b_before[7],
                    hdr.tcp_options_4b_before[8],
                    hdr.tcp_options_4b_before[9],
                    hdr.tcp_options_2b_before,
                    hdr.tcp_options_mss,
                    ig_md.common.origin_tcp_checksum
                });
            }
        }
        mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);
        pkt.emit(hdr.bridged_pd_to_pa);
        pkt.emit(hdr.bridged_cross_vrf);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.payload_frag);
        pkt.emit(hdr.ip_opt_word_1);
        pkt.emit(hdr.ip_opt_word_2);
        pkt.emit(hdr.ip_opt_word_3);
        pkt.emit(hdr.ip_opt_word_4);
        pkt.emit(hdr.ip_opt_word_5);
        pkt.emit(hdr.ip_opt_word_6);
        pkt.emit(hdr.ip_opt_word_7);
        pkt.emit(hdr.ip_opt_word_8);
        pkt.emit(hdr.ip_opt_word_9);
        pkt.emit(hdr.ip_opt_word_10);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.icmp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.tcp_options_4b_before[0]);
        pkt.emit(hdr.tcp_options_4b_before[1]);
        pkt.emit(hdr.tcp_options_4b_before[2]);
        pkt.emit(hdr.tcp_options_4b_before[3]);
        pkt.emit(hdr.tcp_options_4b_before[4]);
        pkt.emit(hdr.tcp_options_4b_before[5]);
        pkt.emit(hdr.tcp_options_4b_before[6]);
        pkt.emit(hdr.tcp_options_4b_before[7]);
        pkt.emit(hdr.tcp_options_4b_before[8]);
        pkt.emit(hdr.tcp_options_4b_before[9]);
        pkt.emit(hdr.tcp_options_2b_before);
        pkt.emit(hdr.tcp_options_1b_before);
        pkt.emit(hdr.tcp_options_mss);
    }
}


//----------------------------------------------------------------------------
// Egress parser d
//----------------------------------------------------------------------------
parser SwitchEgressParser_d(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    @critical
    state start {
        pkt.extract(eg_intr_md);
        eg_md.common.pkt_length = eg_intr_md.pkt_length;

        switch_pkt_src_t pkt_src_type = pkt.lookahead<switch_pkt_src_t>();
        transition select(pkt_src_type) {
            SWITCH_PKT_SRC_BRIDGED_PC_TO_PD : parse_bridged_pc_to_pd_pkt;
            default: accept;
        }
    }

    state parse_bridged_pc_to_pd_pkt {
        pkt.extract(hdr.bridged_pc_to_pd);
        eg_md.common.port = hdr.bridged_pc_to_pd.base.ig_port;
        eg_md.common.pkt_src = hdr.bridged_pc_to_pd.src;
        eg_md.common.pkt_action = hdr.bridged_pc_to_pd.base.pkt_action;
        eg_md.common.vrf = hdr.bridged_pc_to_pd.base.vrf;
        eg_md.common.inner_five_tuples_hash = hdr.bridged_pc_to_pd.base.inner_five_tuples_hash;
        eg_md.common.vxlan_src_port_hash = hdr.bridged_pc_to_pd.base.vxlan_src_port_hash;
        eg_md.common.nexthop = hdr.bridged_pc_to_pd.base.nexthop;
        eg_md.common.mgid = hdr.bridged_pc_to_pd.base.mgid;

        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type, eg_intr_md.egress_port) {
            (0x0800, _) : parse_ipv4;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
             5 : parse_ipv4_no_options;
             6 : parse_ipv4_options_1;
             7 : parse_ipv4_options_2;
             8 : parse_ipv4_options_3;
             9 : parse_ipv4_options_4;
            10 : parse_ipv4_options_5;
            11 : parse_ipv4_options_6;
            12 : parse_ipv4_options_7;
            13 : parse_ipv4_options_8;
            14 : parse_ipv4_options_9;
            15 : parse_ipv4_options_10;
            default: accept;
        }
    }
    state parse_ipv4_options_1 {
        pkt.extract(hdr.ip_opt_word_1);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_2 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_3 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_4 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_5 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_6 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_7 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_8 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_9 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_10 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        pkt.extract(hdr.ip_opt_word_10);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        transition select(hdr.ipv4.protocol) {
            (17) : parse_udp;
            (47) : parse_gre_common;
            default : accept;
        }
    }

    state parse_gre_common {
        gre_common_h gre = pkt.lookahead<gre_common_h>();
        transition select (gre.C) {
            1 : parse_gre2;
            0 : parse_gre1;
        }
    }

    state parse_gre1 {
        pkt.extract(hdr.gre1);
        transition select(hdr.gre1.protocol) {
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_gre2 {
        pkt.extract(hdr.gre2);
        transition select(hdr.gre2.protocol) {
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            4789 : parse_vxlan;
            default : accept;
        }
    }

    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition accept;
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition accept;
    }

}

//----------------------------------------------------------------------------
// Egress deparser d
//----------------------------------------------------------------------------
control SwitchEgressDeparser_d(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr.bridged_pd_recirc);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.gre1);
        pkt.emit(hdr.gre2);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
    }
}



Pipeline(SwitchIngressParser_a(),
         SwitchIngress_a(),
         SwitchIngressDeparser_a(),
         SwitchEgressParser_a(),
         SwitchEgress_a(),
         SwitchEgressDeparser_a()) pipeline_profile_a;

Pipeline(SwitchIngressParser_b(),
         SwitchIngress_b(),
         SwitchIngressDeparser_b(),
         SwitchEgressParser_b(),
         SwitchEgress_b(),
         SwitchEgressDeparser_b()) pipeline_profile_b;

Pipeline(SwitchIngressParser_c(),
         SwitchIngress_c(),
         SwitchIngressDeparser_c(),
         SwitchEgressParser_c(),
         SwitchEgress_c(),
         SwitchEgressDeparser_c()) pipeline_profile_c;

Pipeline(SwitchIngressParser_d(),
         SwitchIngress_d(),
         SwitchIngressDeparser_d(),
         SwitchEgressParser_d(),
         SwitchEgress_d(),
         SwitchEgressDeparser_d()) pipeline_profile_d;

// Switch(pipeline_profile_b, pipeline_profile_c, pipeline_profile_a, pipeline_profile_d) main;
Switch(pipeline_profile_d) main;
