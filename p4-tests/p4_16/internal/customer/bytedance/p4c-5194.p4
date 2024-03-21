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

#include <core.p4>
#include <tna.p4>  /* TOFINO1_ONLY */

@command_line("--disable-parse-min-depth-limit", "--disable-parse-max-depth-limit")

//-----------------------------------------------------------------------------
// Features.
//-----------------------------------------------------------------------------
// L2 Unicast

//#define STORM_CONTROL_ENABLE

// L3 Unicast

// ACLs

//To enable port_group in ingress ACLs.
//#define PORT_GROUP_IN_ACL_KEY_ENABLE

// Mirror

//#define ERSPAN_TYPE2_ENABLE

//#define ERSPAN_VLAN_ENABLE

// QoS

// #define QOS_ACL_ENABLE

// DTEL
// #define DTEL_ENABLE
// #define DTEL_QUEUE_REPORT_ENABLE
// #define DTEL_DROP_REPORT_ENABLE
// #define DTEL_FLOW_REPORT_ENABLE
// #define DTEL_ACL_ENABLE

// SFLOW

// TUNNEL
// #define GRE_ENABLE
// #define TUNNEL_ENABLE
// #define IPV6_TUNNEL_ENABLE

// resilient hash enable
// #define RESILIENT_ECMP_HASH_ENABLE
//-----------------------------------------------------------------------------
// Table sizes.
//-----------------------------------------------------------------------------
const bit<32> PORT_TABLE_SIZE = 288 * 2;

// 4K L2 vlans
const bit<32> VLAN_TABLE_SIZE = 4096;
const bit<32> BD_FLOOD_TABLE_SIZE = VLAN_TABLE_SIZE * 4;

// 1K (port, vlan) <--> BD
const bit<32> PORT_VLAN_TABLE_SIZE = 1024;

// 5K BDs
const bit<32> BD_TABLE_SIZE = 5120;

// 16K MACs
const bit<32> MAC_TABLE_SIZE = 16384;

// IP Hosts/Routes
const bit<32> IPV4_HOST_TABLE_SIZE = 1024;
const bit<32> IPV4_LPM_TABLE_SIZE = 10240;
const bit<32> IPV4_LOCAL_HOST_TABLE_SIZE = 1024;
const bit<32> IPV6_HOST_TABLE_SIZE = 1024;
const bit<32> IPV6_LPM_TABLE_SIZE = 10240;
const bit<32> IPV6_LPM64_TABLE_SIZE = 0;

// ECMP/Nexthop
const bit<32> ECMP_GROUP_TABLE_SIZE = 512;
const bit<32> ECMP_SELECT_TABLE_SIZE = 32768;
const bit<32> NEXTHOP_TABLE_SIZE = 65536;

// Ingress ACLs
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 2048;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 1024;
const bit<32> INGRESS_IP_MIRROR_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IP_DTEL_ACL_TABLE_SIZE = 512;

// Egress ACLs
const bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 1024;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512;

// VIP COUNTER TABLE 
const bit<32> VIPV4_COUNTER_TABLE_SIZE = 12288;
const bit<32> VIPV6_COUNTER_TABLE_SIZE = 12288;

// VTEP TABLE
const bit<32> TTGW_VTEP_TABLE_SIZE = 16384;

// Cluster->dscp table
const bit<32> DSCP_TABLE_SIZE = 16384;

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

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

@pa_container_size("ingress", "hdr.ethernet.src_addr", 16, 32)
@pa_container_size("ingress", "hdr.ethernet.dst_addr", 16, 32)
@pa_container_size("ingress", "hdr.ethernet.$valid", 16)
header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
    bit<16> ether_type;
}

header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header ttgw_h {
    bit<16> cluster_index;
    bit<128> local_vtep;
    bit<128> rs_vtep;
    bit<128> rs_addr;
    bit<16> rs_port;
    bit<16> rss;
    // bit<16> l3_checksum;
    bit<16> ether_type;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

// Router Alert IP option -- RFC 2113, RFC 2711
header router_alert_option_h {
    bit<8> type;
    bit<8> length;
    bit<16> value;
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
    // ...
}

header igmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    // ...
}

// Address Resolution Protocol -- RFC 6747
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
    // ...
}

// RDMA over Converged Ethernet (RoCEv2)
header rocev2_bth_h {
    bit<8> opcodee;
    bit<1> se;
    bit<1> migration_req;
    bit<2> pad_count;
    bit<4> transport_version;
    bit<16> partition_key;
    bit<1> f_res1;
    bit<1> b_res1;
    bit<6> reserved;
    bit<24> dst_qp;
    bit<1> ack_req;
    bit<7> reserved2;
    // ...
}

// Fiber Channel over Ethernet (FCoE)
header fcoe_fc_h {
    bit<4> version;
    bit<100> reserved;
    bit<8> sof; // Start of frame

    bit<8> r_ctl; // Routing control
    bit<24> d_id; // Destination identifier
    bit<8> cs_ctl; // Class specific control
    bit<24> s_id; // Source identifier
    bit<8> type;
    bit<24> f_ctl; // Frame control
    bit<8> seq_id;
    bit<8> df_ctl;
    bit<16> seq_cnt; // Sequence count
    bit<16> ox_id; // Originator exchange id
    bit<16> rx_id; // Responder exchange id
    // ...
}

// Segment Routing Extension (SRH) -- IETFv7
header ipv6_srh_h {
    bit<8> next_hdr;
    bit<8> hdr_ext_len;
    bit<8> routing_type;
    bit<8> seg_left;
    bit<8> last_entry;
    bit<8> flags;
    bit<16> tag;
}

// VXLAN -- RFC 7348
header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

// Generic Protocol Extension for VXLAN -- IETFv4
header vxlan_gpe_h {
    bit<8> flags;
    bit<16> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

// Generic Routing Encapsulation (GRE) -- RFC 1701
header gre_h {
    bit<1> C;
    bit<1> R;
    bit<1> K;
    bit<1> S;
    bit<1> s;
    bit<3> recurse;
    bit<5> flags;
    bit<3> version;
    bit<16> proto;
}

// Network Virtualisation using GRE (NVGRE) -- RFC 7637
header nvgre_h {
    bit<24> vsid;
    bit<8> flow_id;
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

// Generic Network Virtualization Encapsulation (Geneve)
header geneve_h {
    bit<2> version;
    bit<6> opt_len;
    bit<1> oam;
    bit<1> critical;
    bit<6> reserved;
    bit<16> proto_type;
    bit<24> vni;
    bit<8> reserved2;
}

header geneve_option_h {
    bit<16> opt_class;
    bit<8> opt_type;
    bit<3> reserved;
    bit<5> opt_len;
}

// Bidirectional Forwarding Detection (BFD) -- RFC 5880
header bfd_h {
    bit<3> version;
    bit<5> diag;
    bit<8> flags;
    bit<8> detect_multi;
    bit<8> len;
    bit<32> my_discriminator;
    bit<32> your_discriminator;
    bit<32> desired_min_tx_interval;
    bit<32> req_min_rx_interval;
    bit<32> req_min_echo_rx_interval;
}

// Telemetry report header -- version 0.5
// See https://github.com/p4lang/p4-applications/blob/master/docs/telemetry_report_v0_5.pdf
header dtel_report_v05_h {
    bit<4> version;
    bit<4> next_proto;
    bit<3> d_q_f;
    bit<15> reserved;
    bit<6> hw_id;
    bit<32> seq_number;
    bit<32> timestamp;
    bit<32> switch_id;
}

// DTel report base header
header dtel_report_base_h {

    bit<7> pad0;

    PortId_t ingress_port;

    bit<7> pad1;

    PortId_t egress_port;

    bit<3> pad2;
    bit<5> queue_id;

}

// DTel drop report header
header dtel_drop_report_h {
    bit<8> drop_reason;
    bit<16> reserved;
}

// DTel switch local report header
header dtel_switch_local_report_h {
    bit<5> pad3;
    bit<19> queue_occupancy;
    bit<32> timestamp;
}

// Telemetry report header -- version 1.0
// See https://github.com/p4lang/p4-applications/blob/master/docs/telemetry_report_v1_0.pdf
header dtel_report_v10_h {
    bit<4> version;
    bit<4> length;
    bit<3> next_proto;
    bit<6> metadata_bits;
    bit<6> reserved;
    bit<3> d_q_f;
    bit<6> hw_id;
    bit<32> switch_id;
    bit<32> seq_number;
    bit<32> timestamp;
}

// Telemetry report header -- version 2.0
// See https://github.com/p4lang/p4-applications/blob/master/docs/telemetry_report_v2_0.pdf
header dtel_report_v20_h {
    bit<4> version;
    // Telemetry Report v2.0 hw_id is 6 bits, however due to p4 constraints,
    // shrinking it to 4 bits
    bit<4> hw_id;
    // Telemetry Report v2.0 seq_number is 22 bits, however due to p4
    // constraints, expanding it to 24 bits, always leaving the top 2 bits as 0
    bit<24> seq_number;
    bit<32> switch_id;
    // Due to p4 constraints, need to treat the following as one field:
    // bit<4> rep_type;
    // bit<4> in_type;
    // bit<16> report_length;
    bit<16> report_length;
    bit<8> md_length;
    bit<3> d_q_f;
    bit<5> reserved;
    bit<16> rep_md_bits;
    bit<16> domain_specific_id;
    bit<16> ds_md_bits;
    bit<16> ds_md_status;
}

// Optional metadata present in the telemetry report.
header dtel_metadata_1_h {

    bit<7> pad0;

    PortId_t ingress_port;

    bit<7> pad1;

    PortId_t egress_port;
}

header dtel_metadata_2_h {
    bit<32> hop_latency;
}

header dtel_metadata_3_h {

    bit<3> pad2;
    bit<5> queue_id;

    bit<5> pad3;
    bit<19> queue_occupancy;
}

header dtel_metadata_4_h {
    bit<16> pad;
    bit<48> ingress_timestamp;
}

header dtel_metadata_5_h {
    bit<16> pad;
    bit<48> egress_timestamp;
}

header dtel_report_metadata_15_h {

    bit<3> pad;
    bit<5> queue_id;

    bit<8> drop_reason;
    bit<16> reserved;
}

// Barefoot Specific Headers.
header fabric_h {
    bit<8> reserved;
    bit<3> color;
    bit<5> qos;
    bit<8> reserved2;
}

// CPU header
header cpu_h {
    bit<1> tx_bypass;
    bit<1> capture_ts;
    bit<1> reserved;
    bit<5> egress_queue;
    bit<16> ingress_port;
    bit<16> port_lag_index;
    bit<16> ingress_bd;
    bit<16> reason_code; // Also used as a 16-bit bypass flag.
    bit<16> ether_type;
}

// CPU header
//TODO(msharif): Update format of the CPU header.
// header cpu_h {
//    bit<8> flags; /*
//        bit<1> tx_bypass;
//        bit<1> capture_ts;
//        bit<1> multicast;
//        bit<5> reserved;
//    */
//    bit<8> qid;
//    bit<16> reserved;
//    bit<16> port_or_group;
//    bit<16> port;
//    bit<16> port_lag_index;
//    bit<16> bd;
//    bit<16> reason_code; // Also used as a 16-bit bypass flag.
//    bit<16> ether_type;
//}

header timestamp_h {
    bit<48> timestamp;
}

// ----------------------------------------------------------------------------
// Common protocols/types
//-----------------------------------------------------------------------------
//#define ETHERTYPE_QINQ 0x88A8 // Note: uncomment once ptf/scapy-vxlan are fixed
// ----------------------------------------------------------------------------
// Common table sizes
//-----------------------------------------------------------------------------

const bit<32> LAG_TABLE_SIZE = 1024;
const bit<32> LAG_GROUP_TABLE_SIZE = 256;
const bit<32> LAG_MAX_MEMBERS_PER_GROUP = 64;
const bit<32> LAG_SELECTOR_TABLE_SIZE = 16384; // 256 * 64

const bit<32> ECMP_MAX_MEMBERS_PER_GROUP = 64;

const bit<32> DTEL_GROUP_TABLE_SIZE = 4;
const bit<32> DTEL_MAX_MEMBERS_PER_GROUP = 64;
const bit<32> DTEL_SELECTOR_TABLE_SIZE = 256;

// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------
typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;

typedef PortId_t switch_port_t;

const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;
typedef bit<7> switch_port_padding_t;

typedef QueueId_t switch_qid_t;

typedef ReplicationId_t switch_rid_t;
const switch_rid_t SWITCH_RID_DEFAULT = 0xffff;

typedef bit<3> switch_ingress_cos_t;

typedef bit<3> switch_digest_type_t;
const switch_digest_type_t SWITCH_DIGEST_TYPE_INVALID = 0;
const switch_digest_type_t SWITCH_DIGEST_TYPE_MAC_LEARNING = 1;

typedef bit<16> switch_ifindex_t;
typedef bit<10> switch_port_lag_index_t;
const switch_port_lag_index_t SWITCH_FLOOD = 0x3ff;

typedef bit<16> switch_bd_t;
const switch_bd_t SWITCH_BD_DEFAULT_VRF = 4097; // bd allocated for default vrf

typedef bit<16> switch_vrf_t;

typedef bit<16> switch_nexthop_t;
typedef bit<16> switch_outer_nexthop_t;

typedef bit<10> switch_user_metadata_t;

typedef bit<32> switch_hash_t;
typedef bit<16> switch_xid_t;
typedef bit<9> switch_yid_t;

typedef bit<32> switch_ig_port_lag_label_t;

typedef bit<16> switch_eg_port_lag_label_t;
typedef bit<16> switch_bd_label_t;
typedef bit<16> switch_if_label_t;

typedef bit<10> switch_rmac_group_t;
typedef bit<16> switch_smac_index_t;

typedef bit<16> switch_mtu_t;

typedef bit<12> switch_stats_index_t;

typedef bit<16> switch_cpu_reason_t;
const switch_cpu_reason_t SWITCH_CPU_REASON_PTP = 8;

struct switch_cpu_port_value_set_t {
    bit<16> ether_type;
    switch_port_t port;
}

typedef bit<8> switch_drop_reason_t;
const switch_drop_reason_t SWITCH_DROP_REASON_UNKNOWN = 0;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_ZERO = 10;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_MULTICAST = 11;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_DST_MAC_ZERO = 12;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_ETHERNET_MISS = 13;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SAME_MAC_CHECK = 17;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_ZERO = 14;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_MULTICAST = 15;
const switch_drop_reason_t SWITCH_DROP_REASON_DST_MAC_ZERO = 16;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID = 25;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_TTL_ZERO = 26;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_SRC_MULTICAST = 27;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_SRC_LOOPBACK = 28;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_MISS = 29;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID = 30;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_INVALID_CHECKSUM = 31;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_FRAGMENTATION = 32;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_VERSION_INVALID = 40;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_TTL_ZERO = 41;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_MULTICAST = 42;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_LOOPBACK = 43;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_IHL_INVALID = 44;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_INVALID_CHECKSUM = 45;
const switch_drop_reason_t SWITCH_DROP_REASON_PORT_VLAN_MAPPING_MISS = 55;
const switch_drop_reason_t SWITCH_DROP_REASON_STP_STATE_LEARNING = 56;
const switch_drop_reason_t SWITCH_DROP_REASON_STP_STATE_BLOCKING = 57;
const switch_drop_reason_t SWITCH_DROP_REASON_SAME_IFINDEX = 58;
const switch_drop_reason_t SWITCH_DROP_REASON_MULTICAST_SNOOPING_ENABLED = 59;
const switch_drop_reason_t SWITCH_DROP_REASON_MTU_CHECK_FAIL = 70;
const switch_drop_reason_t SWITCH_DROP_REASON_TRAFFIC_MANAGER = 71;
const switch_drop_reason_t SWITCH_DROP_REASON_STORM_CONTROL = 72;
const switch_drop_reason_t SWITCH_DROP_REASON_WRED = 73;
const switch_drop_reason_t SWITCH_DROP_REASON_INGRESS_PORT_METER = 75;
const switch_drop_reason_t SWITCH_DROP_REASON_INGRESS_ACL_METER = 76;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_PORT_METER = 77;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_ACL_METER = 78;
const switch_drop_reason_t SWITCH_DROP_REASON_ACL_DENY = 80;
const switch_drop_reason_t SWITCH_DROP_REASON_RACL_DENY = 81;
const switch_drop_reason_t SWITCH_DROP_REASON_URPF_CHECK_FAIL = 82;
const switch_drop_reason_t SWITCH_DROP_REASON_IPSG_MISS = 83;
const switch_drop_reason_t SWITCH_DROP_REASON_IFINDEX = 84;
const switch_drop_reason_t SWITCH_DROP_REASON_CPU_COLOR_YELLOW = 85;
const switch_drop_reason_t SWITCH_DROP_REASON_CPU_COLOR_RED = 86;
const switch_drop_reason_t SWITCH_DROP_REASON_STORM_CONTROL_COLOR_YELLOW = 87;
const switch_drop_reason_t SWITCH_DROP_REASON_STORM_CONTROL_COLOR_RED = 88;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_UNICAST = 89;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_MULTICAST = 90;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_BROADCAST = 91;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_ACL_DENY = 92;
const switch_drop_reason_t SWITCH_DROP_REASON_NEXTHOP = 93;
const switch_drop_reason_t SWITCH_DROP_REASON_NON_IP_ROUTER_MAC = 94;
const switch_drop_reason_t SWITCH_DROP_REASON_MLAG_MEMBER = 95;
const switch_drop_reason_t SWITCH_DROP_REASON_L3_IPV4_DISABLE = 99;
const switch_drop_reason_t SWITCH_DROP_REASON_L3_IPV6_DISABLE = 100;
const switch_drop_reason_t SWITCH_DROP_REASON_INGRESS_PFC_WD_DROP = 101;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_PFC_WD_DROP = 102;
const switch_drop_reason_t SWITCH_DROP_REASON_INNER_DST_MAC_BROADCAST = 103;
const switch_drop_reason_t SWITCH_DROP_REASON_TUNNEL_REWRITE_MISS = 104;

typedef bit<1> switch_port_type_t;
const switch_port_type_t SWITCH_PORT_TYPE_NORMAL = 0;
const switch_port_type_t SWITCH_PORT_TYPE_CPU = 1;

typedef bit<2> switch_ip_type_t;
const switch_ip_type_t SWITCH_IP_TYPE_NONE = 0;
const switch_ip_type_t SWITCH_IP_TYPE_IPV4 = 1;
const switch_ip_type_t SWITCH_IP_TYPE_IPV6 = 2;

typedef bit<2> switch_ip_frag_t;
const switch_ip_frag_t SWITCH_IP_FRAG_NON_FRAG = 0b00; // Not fragmented.
const switch_ip_frag_t SWITCH_IP_FRAG_HEAD = 0b10; // First fragment of the fragmented packets.
const switch_ip_frag_t SWITCH_IP_FRAG_NON_HEAD = 0b11; // Fragment with non-zero offset.

// Bypass flags ---------------------------------------------------------------
typedef bit<16> switch_ingress_bypass_t;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L2 = 16w0x0001;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L3 = 16w0x0002;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ACL = 16w0x0004;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SYSTEM_ACL = 16w0x0008;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_QOS = 16w0x0010;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_METER = 16w0x0020;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STORM_CONTROL = 16w0x0040;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STP = 16w0x0080;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SMAC = 16w0x0100;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_NAT = 16w0x0200;

// Add more ingress bypass flags here.

const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ALL = 16w0xffff;

typedef bit<8> switch_egress_bypass_t;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_REWRITE = 8w0x01;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_ACL = 8w0x02;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_SYSTEM_ACL = 8w0x04;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_QOS = 8w0x08;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_WRED = 8w0x10;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_STP = 8w0x20;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_MTU = 8w0x40;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_METER = 8w0x80;

// Add more egress bypass flags here.

const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_ALL = 8w0xff;

typedef bit<8> gw_egress_bypass_t;
const gw_egress_bypass_t GW_EGRESS_BYPASS_TUNNEL = 8w0x80;

const gw_egress_bypass_t GW_EGRESS_BYPASS_ALL = 8w0xff;

// PKT ------------------------------------------------------------------------
typedef bit<16> switch_pkt_length_t;

typedef bit<8> switch_pkt_src_t;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED = 0;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_INGRESS = 1;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_EGRESS = 2;
const switch_pkt_src_t SWITCH_PKT_SRC_DEFLECTED = 3;

typedef bit<2> switch_pkt_color_t;
const switch_pkt_color_t SWITCH_METER_COLOR_GREEN = 0;
const switch_pkt_color_t SWITCH_METER_COLOR_YELLOW = 1;
const switch_pkt_color_t SWITCH_METER_COLOR_RED = 3;

typedef bit<2> switch_pkt_type_t;
const switch_pkt_type_t SWITCH_PKT_TYPE_UNICAST = 0;
const switch_pkt_type_t SWITCH_PKT_TYPE_MULTICAST = 1;
const switch_pkt_type_t SWITCH_PKT_TYPE_BROADCAST = 2;

// LOU ------------------------------------------------------------------------

typedef bit<8> switch_l4_port_label_t;

// STP ------------------------------------------------------------------------
typedef bit<2> switch_stp_state_t;
const switch_stp_state_t SWITCH_STP_STATE_FORWARDING = 0;
const switch_stp_state_t SWITCH_STP_STATE_BLOCKING = 1;
const switch_stp_state_t SWITCH_STP_STATE_LEARNING = 2;

typedef bit<10> switch_stp_group_t;

struct switch_stp_metadata_t {
    switch_stp_group_t group;
    switch_stp_state_t state_;
}

// Sflow ----------------------------------------------------------------------
typedef bit<8> switch_sflow_id_t;
const switch_sflow_id_t SWITCH_SFLOW_INVALID_ID = 8w0xff;

struct switch_sflow_metadata_t {
    switch_sflow_id_t session_id;
    bit<1> sample_packet;
}

// Metering -------------------------------------------------------------------

typedef bit<8> switch_copp_meter_id_t;

typedef bit<10> switch_meter_index_t;

typedef bit<8> switch_mirror_meter_id_t;

// QoS ------------------------------------------------------------------------
typedef bit<2> switch_qos_trust_mode_t;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_UNTRUSTED = 0;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_TRUST_DSCP = 1;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_TRUST_PCP = 2;

typedef bit<5> switch_qos_group_t;

typedef bit<8> switch_tc_t;
typedef bit<3> switch_cos_t;

typedef bit<11> switch_etrap_index_t;

//MYIP type
typedef bit<2> switch_myip_type_t;
const switch_myip_type_t SWITCH_MYIP_NONE = 0;
const switch_myip_type_t SWITCH_MYIP = 1;
const switch_myip_type_t SWITCH_MYIP_SUBNET = 2;

struct switch_qos_metadata_t {
    switch_qos_trust_mode_t trust_mode; // Ingress only.
    switch_qos_group_t group;
    switch_tc_t tc;
    switch_pkt_color_t color;
    switch_pkt_color_t acl_meter_color;
    switch_pkt_color_t port_color;
    switch_pkt_color_t flow_color;
    switch_pkt_color_t storm_control_color;
    switch_meter_index_t port_meter_index;
    switch_meter_index_t acl_meter_index;
    switch_qid_t qid;
    switch_ingress_cos_t icos; // Ingress only.
    bit<19> qdepth; // Egress only.
    switch_etrap_index_t etrap_index;
    switch_pkt_color_t etrap_color;
    switch_tc_t etrap_tc;
    bit<1> etrap_state;
}

// Learning -------------------------------------------------------------------
typedef bit<1> switch_learning_mode_t;
const switch_learning_mode_t SWITCH_LEARNING_MODE_DISABLED = 0;
const switch_learning_mode_t SWITCH_LEARNING_MODE_LEARN = 1;

struct switch_learning_digest_t {
    switch_bd_t bd;
    switch_port_lag_index_t port_lag_index;
    mac_addr_t src_addr;
}

struct switch_learning_metadata_t {
    switch_learning_mode_t bd_mode;
    switch_learning_mode_t port_mode;
    switch_learning_digest_t digest;
}

// Multicast ------------------------------------------------------------------
typedef bit<2> switch_multicast_mode_t;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_NONE = 0;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_SM = 1; // Sparse mode
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_BIDIR = 2; // Bidirectional

typedef MulticastGroupId_t switch_mgid_t;

typedef bit<16> switch_multicast_rpf_group_t;

struct switch_multicast_metadata_t {
    switch_mgid_t id;
    bit<2> mode;
    switch_multicast_rpf_group_t rpf_group;
}

// URPF -----------------------------------------------------------------------
typedef bit<2> switch_urpf_mode_t;
const switch_urpf_mode_t SWITCH_URPF_MODE_NONE = 0;
const switch_urpf_mode_t SWITCH_URPF_MODE_LOOSE = 1;
const switch_urpf_mode_t SWITCH_URPF_MODE_STRICT = 2;

// WRED/ECN -------------------------------------------------------------------

typedef bit<10> switch_wred_index_t;

typedef bit<2> switch_ecn_codepoint_t;
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_NON_ECT = 0b00; // Non ECN-capable transport
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_ECT0 = 0b10; // ECN capable transport
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_ECT1 = 0b01; // ECN capable transport
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_CE = 0b11; // Congestion encountered

// Mirroring ------------------------------------------------------------------
typedef MirrorId_t switch_mirror_session_t; // Defined in tna.p4
const switch_mirror_session_t SWITCH_MIRROR_SESSION_CPU = 250;

// Using same mirror type for both Ingress/Egress to simplify the parser.
typedef bit<8> switch_mirror_type_t;

/* Although strictly speaking deflected packets are not mirrored packets,
 * need a mirror_type codepoint for packet length adjustment.
 * Pick a large value since this is not used by mirror logic.
 */

// Common metadata used for mirroring.
struct switch_mirror_metadata_t {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    switch_mirror_session_t session_id;
    switch_mirror_meter_id_t meter_index;
}

header switch_port_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    bit<48> timestamp;

    bit<6> _pad;

    switch_mirror_session_t session_id;

}

header switch_cpu_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    switch_port_padding_t _pad1;
    switch_port_t port;
    switch_bd_t bd;
    bit<6> _pad2;
    switch_port_lag_index_t port_lag_index;
    switch_cpu_reason_t reason_code;
}

// Tunneling ------------------------------------------------------------------
enum switch_tunnel_mode_t { PIPE, UNIFORM }
typedef bit<3> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NONE = 0;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VXLAN = 1;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPINIP = 2;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NVGRE = 3;

const switch_bd_t SWITCH_VXLAN_DEFAULT_BD = 65535; // bd allocated for default vrf

const bit<8> DEFAULT_VXLAN_TTL = 8w64;
// const mac_addr_t DEFAULT_GATEWAY_SMAC= 48w0x123456123456; // 12:34:56:12:34:56
// const mac_addr_t DEFAULT_GATEWAY_DMAC= 48w0x003456123456; // used for xacl and fallback

enum switch_tunnel_term_mode_t { P2P, P2MP };

typedef bit<16> switch_tunnel_index_t;
typedef bit<24> switch_tunnel_id_t;

struct switch_tunnel_metadata_t {
    switch_tunnel_type_t type;
    switch_tunnel_index_t index;
    switch_tunnel_id_t id;
    switch_ifindex_t ifindex;
    bit<16> hash;
    bit<16> cluster_index;
    bit<1> terminate;
    bit<1> encap;
    switch_ip_type_t ip_type; // vxlan tunnel ip type
    switch_ip_type_t service_ip_type; // FIXME: vip ip type, 只在入向（encap）有用到，是普通报文（vip 入向）的 ip_type，出向（decap）这个值是外层 tunnel 的 ip_type
}

// Data-plane telemetry (DTel) ------------------------------------------------
/* report_type bits for drop and flow reflect dtel_acl results,
 * i.e. whether drop reports and flow reports may be triggered by this packet.
 * report_type bit for queue is not used by bridged / deflected packets,
 * reflects whether queue report is triggered by this packet in cloned packets.
 */
typedef bit<8> switch_dtel_report_type_t;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_NONE = 0b000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_DROP = 0b100;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_QUEUE = 0b010;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_FLOW = 0b001;

const switch_dtel_report_type_t SWITCH_DTEL_SUPPRESS_REPORT = 0b1000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_IFA_CLONE = 0b10000;
const switch_dtel_report_type_t SWITCH_DTEL_IFA_EDGE = 0b100000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE = 0b1000000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_ETRAP_HIT = 0b10000000;

typedef bit<8> switch_ifa_sample_id_t;

typedef bit<6> switch_dtel_hw_id_t;

// Outer header sizes for DTEL Reports
/* Up to the beginning of the DTEL Report v0.5 header
 * 14 (Eth) + 20 (IPv4) + 8 (UDP) + 4 (CRC) = 46 bytes */
const bit<16> DTEL_REPORT_V0_5_OUTER_HEADERS_LENGTH = 46;
/* Outer headers + part of DTEL Report v2 length not included in report_length
 * 14 (Eth) + 20 (IPv4) + 8 (UDP) + 12 (DTEL) + 4 (CRC) = 58 bytes */
const bit<16> DTEL_REPORT_V2_OUTER_HEADERS_LENGTH = 58;

struct switch_dtel_metadata_t {
    switch_dtel_report_type_t report_type;
    bit<1> ifa_gen_clone; // Ingress only, indicates desire to clone this packet
    bit<1> ifa_cloned; // Egress only, indicates this is an ifa cloned packet
    bit<32> latency; // Egress only.
    switch_mirror_session_t session_id;
    switch_mirror_session_t clone_session_id; // Used for IFA interop
    bit<32> hash;
    bit<2> drop_report_flag; // Egress only.
    bit<2> flow_report_flag; // Egress only.
    bit<1> queue_report_flag; // Egress only.
}

typedef bit<4> switch_ingress_nat_hit_type_t;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_NONE = 0;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_TYPE_FLOW_NONE = 1;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_TYPE_FLOW_NAPT = 2;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_TYPE_FLOW_NAT = 3;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_TYPE_DEST_NONE = 4;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_TYPE_DEST_NAPT = 5;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_TYPE_DEST_NAT = 6;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_TYPE_SRC_NONE = 7;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_TYPE_SRC_NAPT = 8;
const switch_ingress_nat_hit_type_t SWITCH_NAT_HIT_TYPE_SRC_NAT = 9;

typedef bit<1> switch_nat_zone_t;
const switch_nat_zone_t SWITCH_NAT_INSIDE_ZONE_ID = 0;
const switch_nat_zone_t SWITCH_NAT_OUTSIDE_ZONE_ID = 1;

struct switch_nat_ingress_metadata_t {
  switch_ingress_nat_hit_type_t hit;
  switch_nat_zone_t ingress_zone;
  bit<16> dnapt_index;
  bit<16> snapt_index;
  bool nat_disable;
  bool dnat_pool_hit;
}

header switch_dtel_switch_local_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    bit<48> timestamp;

    bit<6> _pad;

    switch_mirror_session_t session_id;
    bit<32> hash;
    switch_dtel_report_type_t report_type;
    switch_port_padding_t _pad2;
    switch_port_t ingress_port;
    switch_port_padding_t _pad3;
    switch_port_t egress_port;

    bit<3> _pad4;

    switch_qid_t qid;
    bit<5> _pad5;
    bit<19> qdepth;

    bit<32> egress_timestamp;

}

header switch_dtel_drop_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    bit<48> timestamp;

    bit<6> _pad;

    switch_mirror_session_t session_id;
    bit<32> hash;
    switch_dtel_report_type_t report_type;
    switch_port_padding_t _pad2;
    switch_port_t ingress_port;
    switch_port_padding_t _pad3;
    switch_port_t egress_port;

    bit<3> _pad4;

    switch_qid_t qid;
    switch_drop_reason_t drop_reason;
}

// Used for dtel truncate_only and ifa_clone mirror sessions
header switch_simple_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;

    bit<6> _pad;

    switch_mirror_session_t session_id;
}

@flexible
struct switch_bridged_metadata_dtel_extension_t {
    switch_dtel_report_type_t report_type;
    switch_mirror_session_t session_id;
    bit<32> hash;
    switch_port_t egress_port;
}

//-----------------------------------------------------------------------------
// Other Metadata Definitions
//-----------------------------------------------------------------------------
// Flags
//XXX Force the fields that are XORd to NOT share containers.
@pa_container_size("ingress", "ig_md.checks.same_if", 16)

struct switch_ingress_flags_t {
    bool ipv4_checksum_err;
    bool inner_ipv4_checksum_err;
    bool link_local;
    bool routed;
    bool acl_deny;
    bool racl_deny;
    bool port_vlan_miss;
    bool rmac_hit;
    bool dmac_miss;
    switch_myip_type_t myip;
    bool glean;
    bool storm_control_drop;
    bool acl_meter_drop;
    bool port_meter_drop;
    bool flood_to_multicast_routers;
    bool peer_link;
    bool capture_ts;
    bool mac_pkt_class;
    bool pfc_wd_drop;
    bool bypass_egress;
    // Add more flags here.
    bool services;
}

struct switch_egress_flags_t {
    bool routed;
    bool bypass_egress;
    bool acl_deny;
    bool mlag_member;
    bool peer_link;
    bool capture_ts;
    bool wred_drop;
    bool port_meter_drop;
    bool acl_meter_drop;
    bool pfc_wd_drop;

    // Add more flags here.
}

// Checks
struct switch_ingress_checks_t {
    switch_port_lag_index_t same_if;
    bool mrpf;
    bool urpf;

    // Add more checks here.
}

struct switch_egress_checks_t {
    switch_bd_t same_bd;
    switch_mtu_t mtu;
    bool stp;

    // Add more checks here.
}

// IP
struct switch_ip_metadata_t {
    bool unicast_enable;
    bool multicast_enable;
    bool multicast_snooping;
    // switch_urpf_mode_t urpf_mode;
}

struct switch_lookup_fields_t {
    switch_pkt_type_t pkt_type;

    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<16> mac_type;
    bit<3> pcp;

    // 1 for ARP request, 2 for ARP reply.
    bit<16> arp_opcode;

    switch_ip_type_t ip_type;
    bit<8> ip_proto;
    bit<8> ip_ttl;
    bit<8> ip_tos;
    bit<2> ip_frag;
    bit<128> ip_src_addr;
    bit<128> ip_dst_addr;

    bit<8> tcp_flags;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;
}

// Header types used by ingress/egress deparsers.
@flexible
struct switch_bridged_metadata_t {
    // user-defined metadata carried over from ingress to egress.
    switch_port_t ingress_port;
    switch_port_lag_index_t ingress_port_lag_index;
    switch_bd_t ingress_bd;
    switch_nexthop_t nexthop;
    switch_pkt_type_t pkt_type;
    bool routed;
    bool bypass_egress;
    //TODO(msharif) : Fix the bridged metadata fields for PTP.

    switch_cpu_reason_t cpu_reason;
    bit<48> timestamp;
    switch_tc_t tc;
    switch_qid_t qid;
    switch_pkt_color_t color;

    // Add more fields here.
}

@flexible
struct switch_bridged_metadata_acl_extension_t {

    bit<16> l4_src_port;
    bit<16> l4_dst_port;
    bit<8> tcp_flags;
    switch_l4_port_label_t l4_src_port_label;
    switch_l4_port_label_t l4_dst_port_label;

}

@flexible
struct switch_bridged_metadata_tunnel_extension_t {
    switch_vrf_t vrf;
    // bit<16> checksum_l3_tmp;
    bit<16> cluster_index;
    bit<1> terminate;
    bit<1> encap;
    switch_ip_type_t service_ip_type;
}
@pa_no_overlay("ingress", "hdr.cpu.ingress_port") // to fix ingress_port and ttgw.hdr.rs_index overlay bug

typedef bit<8> switch_bridge_type_t;

header switch_bridged_metadata_h {
    switch_pkt_src_t src;
    switch_bridge_type_t type;
    switch_bridged_metadata_t base;

    switch_bridged_metadata_acl_extension_t acl;

// #ifdef TUNNEL_ENABLE
    switch_bridged_metadata_tunnel_extension_t tunnel;
// #endif

}

struct switch_port_metadata_t {
    switch_port_lag_index_t port_lag_index;
    switch_ig_port_lag_label_t port_lag_label;
}

@pa_auto_init_metadata

@pa_container_size("ingress", "ig_md.mirror.src", 8)
@pa_container_size("ingress", "ig_md.mirror.type", 8)
@pa_container_size("ingress", "smac_src_move", 16)
@pa_alias("ingress", "ig_md.egress_port", "ig_intr_md_for_tm.ucast_egress_port")

@pa_alias("ingress", "ig_md.multicast.id", "ig_intr_md_for_tm.mcast_grp_b")

@pa_alias("ingress", "ig_md.qos.qid", "ig_intr_md_for_tm.qid")
@pa_alias("ingress", "ig_md.qos.icos", "ig_intr_md_for_tm.ingress_cos")
@pa_alias("ingress", "ig_intr_md_for_dprsr.mirror_type", "ig_md.mirror.type")
// Ingress metadata
struct switch_ingress_metadata_t {
    switch_port_t port; /* ingress port */
    switch_port_t egress_port; /* egress port */
    switch_port_lag_index_t port_lag_index; /* ingress port/lag index */
    switch_port_lag_index_t egress_port_lag_index; /* egress port/lag index */
    switch_bd_t bd;
    switch_vrf_t vrf;
    switch_nexthop_t nexthop;
    switch_outer_nexthop_t outer_nexthop;
    switch_nexthop_t acl_nexthop;
    bool acl_port_redirect;
    switch_nexthop_t unused_nexthop;

    bit<48> timestamp;
    switch_hash_t hash;

    switch_ingress_flags_t flags;
    switch_ingress_checks_t checks;
    switch_ingress_bypass_t bypass;

    switch_ip_metadata_t ipv4;
    switch_ip_metadata_t ipv6;
    switch_ig_port_lag_label_t port_lag_label;
    switch_bd_label_t bd_label;
    switch_if_label_t if_label;
    switch_l4_port_label_t l4_src_port_label;
    switch_l4_port_label_t l4_dst_port_label;

    switch_drop_reason_t drop_reason;
    switch_cpu_reason_t cpu_reason;

    switch_rmac_group_t rmac_group;
    switch_lookup_fields_t lkp;
    switch_multicast_metadata_t multicast;
    switch_stp_metadata_t stp;
    switch_qos_metadata_t qos;
    switch_sflow_metadata_t sflow;
    switch_tunnel_metadata_t tunnel;
    switch_learning_metadata_t learning;
    switch_mirror_metadata_t mirror;
    switch_dtel_metadata_t dtel;
    mac_addr_t same_mac;

    switch_user_metadata_t user_metadata;

    // bit<16> checksum_l3_tmp;
}

// Egress metadata
@pa_container_size("egress", "eg_md.mirror.src", 8)
@pa_container_size("egress", "eg_md.mirror.type", 8)

struct switch_egress_metadata_t {
    switch_pkt_src_t pkt_src;
    switch_pkt_length_t pkt_length;
    switch_pkt_type_t pkt_type;

    /* ingress port_lag_index for cpu going packets, egress port_lag_index for
     * normal ports */
    switch_port_lag_index_t port_lag_index;

    switch_port_type_t port_type; /* egress port type */
    switch_port_t port; /* Mutable copy of egress port */
    switch_port_t ingress_port; /* ingress port */
    switch_bd_t bd;
    switch_vrf_t vrf;
    switch_nexthop_t nexthop;
    switch_outer_nexthop_t outer_nexthop;

    bit<32> timestamp;

    bit<48> ingress_timestamp;

    switch_egress_flags_t flags;
    switch_egress_checks_t checks;
    switch_egress_bypass_t bypass;

    // for egress ACL
    switch_eg_port_lag_label_t port_lag_label;
    switch_bd_label_t bd_label;
    switch_if_label_t if_label;
    switch_l4_port_label_t l4_src_port_label;
    switch_l4_port_label_t l4_dst_port_label;

    switch_lookup_fields_t lkp;
    switch_qos_metadata_t qos;
    switch_tunnel_metadata_t tunnel;
    switch_mirror_metadata_t mirror;
    switch_dtel_metadata_t dtel;
    switch_sflow_metadata_t sflow;

    switch_cpu_reason_t cpu_reason;
    switch_drop_reason_t drop_reason;

    bit<16> checksum_l4_tmp;
    bool checksum_upd_tcp_ipv4;
    bool checksum_upd_tcp_ipv6;
    bool checksum_upd_udp_ipv4;
    bool checksum_upd_udp_ipv6;
    bool checksum_inner_ipv4_udp;

}

// Header format for mirrored metadata fields
struct switch_mirror_metadata_h {
    switch_port_mirror_metadata_h port;
    switch_cpu_mirror_metadata_h cpu;
    switch_dtel_drop_mirror_metadata_h dtel_drop;
    switch_dtel_switch_local_mirror_metadata_h dtel_switch_local;
    switch_simple_mirror_metadata_h simple_mirror;
}

struct switch_header_t {
    switch_bridged_metadata_h bridged_md;
    // switch_mirror_metadata_h mirror;
    ethernet_h ethernet;
    fabric_h fabric;
    cpu_h cpu;
    timestamp_h timestamp;
    vlan_tag_h[2] vlan_tag;
    mpls_h[3] mpls;
    ttgw_h ttgw;
    ipv4_h ipv4;
    ipv4_option_h ipv4_option;
    ipv6_h ipv6;
    arp_h arp;
    udp_h udp;
    icmp_h icmp;
    igmp_h igmp;
    tcp_h tcp;
    dtel_report_v05_h dtel;
    dtel_report_base_h dtel_report;
    dtel_switch_local_report_h dtel_switch_local_report;
    dtel_drop_report_h dtel_drop_report;

    rocev2_bth_h rocev2_bth;
    vxlan_h vxlan;
    gre_h gre;
    nvgre_h nvgre;
    geneve_h geneve;
    erspan_h erspan;
    erspan_type2_h erspan_type2;
    erspan_type3_h erspan_type3;
    erspan_platform_h erspan_platform;
    ethernet_h inner_ethernet;
    ipv4_h inner_ipv4;
    ipv6_h inner_ipv6;
    udp_h inner_udp;
    tcp_h inner_tcp;
    icmp_h inner_icmp;
}

// Flow hash calculation.
control Ipv4Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv4_hash;
    apply {
        hash [31:0] = ipv4_hash.get({lkp.ip_src_addr [31:0],
                                     lkp.ip_dst_addr [31:0],
                                     lkp.ip_proto,
                                     lkp.l4_dst_port,
                                     lkp.l4_src_port});
    }
}
control Ipv6Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_hash;
    apply {
        hash[31:0] = ipv6_hash.get({lkp.ip_src_addr,
                                    lkp.ip_dst_addr,
                                    lkp.ip_proto,
                                    lkp.l4_dst_port,
                                    lkp.l4_src_port});
    }
}
control NonIpHash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;
    apply {
        hash[31:0] = non_ip_hash.get({lkp.mac_type, lkp.mac_src_addr, lkp.mac_dst_addr});
    }
}

action rewrite_bridged_md(
        inout switch_bridged_metadata_h gw_bridged_md, in switch_ingress_metadata_t ig_md) {
    gw_bridged_md.base.ingress_port_lag_index = ig_md.port_lag_index;
    gw_bridged_md.base.nexthop = ig_md.nexthop;
    gw_bridged_md.base.pkt_type = ig_md.lkp.pkt_type;
    gw_bridged_md.base.routed = ig_md.flags.routed;
}


control ChecksumType(inout switch_egress_metadata_t eg_md, in switch_header_t hdr) {
    apply {
        if (hdr.inner_ipv4.isValid()) {
            eg_md.checksum_inner_ipv4_udp = true;
        }
        if (hdr.inner_tcp.isValid()) {
            eg_md.lkp.l4_dst_port = hdr.inner_tcp.dst_port;
            if (hdr.inner_ipv4.isValid()) {
                eg_md.checksum_upd_tcp_ipv4 = true;
                eg_md.lkp.ip_dst_addr[31:0] = hdr.inner_ipv4.dst_addr;
            } else if (hdr.inner_ipv6.isValid()) {
                eg_md.checksum_upd_tcp_ipv6 = true;
                eg_md.lkp.ip_dst_addr = hdr.inner_ipv6.dst_addr;
            }
        }
        else if (hdr.inner_udp.isValid() && hdr.inner_udp.checksum != 0){
            eg_md.lkp.l4_dst_port = hdr.inner_udp.dst_port;
            if (hdr.inner_ipv4.isValid()) {
                eg_md.checksum_upd_udp_ipv4 = true;
                eg_md.lkp.ip_dst_addr[31:0] = hdr.inner_ipv4.dst_addr;
            } else if (hdr.inner_ipv6.isValid()) {
                eg_md.checksum_upd_udp_ipv6 = true;
                eg_md.lkp.ip_dst_addr = hdr.inner_ipv6.dst_addr;
            }
        }
    }
}


//=============================================================================
// GW IngressParser
//=============================================================================
parser GwIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        pkt.extract(hdr.bridged_md);
        // cause internal compile error, moves to pipeline
        // ig_md.port_lag_index = hdr.bridged_md.base.ingress_port_lag_index;
        // ig_md.vrf = hdr.bridged_md.tunnel.vrf;
        transition select(hdr.ethernet.ether_type, ig_intr_md.ingress_port) {
            (0x0800, _) : parse_ipv4;
            (0x86dd, _) : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            5 : parse_ipv4_no_options;
            6 : parse_ipv4_options;
            default : accept;
        }
    }

    state parse_ipv4_options {
        // Only a single 32-bit option (e.g. router alert) is supported.
        pkt.extract(hdr.ipv4_option);
        ipv4_checksum.add(hdr.ipv4_option);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (6, 0) : parse_tcp;
            (17, 0) : parse_udp;
            // Do NOT parse the next header if IP packet is fragmented.
            default : accept;
        }
    }

    state parse_ipv6 {

        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            6 : parse_tcp;
            17 : parse_udp;
            default : accept;
        }

    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            4789 : parse_vxlan;
         default : accept;
     }
    }

    state parse_vxlan {
// #ifdef TUNNEL_ENABLE
        pkt.extract(hdr.vxlan);
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_VXLAN;
        ig_md.tunnel.id = hdr.vxlan.vni;
        transition parse_inner_ethernet;
// #else
//         transition accept;
// #endif
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
        inner_ipv4_checksum.add(hdr.inner_ipv4);
        ig_md.flags.inner_ipv4_checksum_err = inner_ipv4_checksum.verify();
        transition accept;
    }

    state parse_inner_ipv6 {

        pkt.extract(hdr.inner_ipv6);

        transition accept;
    }
}

//=============================================================================
// GW IngressDeparser
//=============================================================================
control GwIngressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.arp); // Ingress only.
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp); // Ingress only.
        pkt.emit(hdr.icmp); // Ingress only.
        pkt.emit(hdr.igmp); // Ingress only.
        pkt.emit(hdr.rocev2_bth); // Ingress only.
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
    }
}

//=============================================================================
// TTGW EgressParser
//=============================================================================
parser TtgwEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    Checksum() tcp_checksum;
    Checksum() udp_checksum;

    @critical
    state start {
        pkt.extract(eg_intr_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.port = eg_intr_md.egress_port;
        eg_md.qos.qdepth = eg_intr_md.deq_qdepth;
        eg_md.checksum_upd_tcp_ipv4 = false;
        eg_md.checksum_upd_tcp_ipv6 = false;
        eg_md.checksum_upd_udp_ipv4 = false;
        eg_md.checksum_upd_udp_ipv6 = false;
        eg_md.checksum_inner_ipv4_udp = false;
        transition parse_bridged_pkt;
    }

    state parse_bridged_pkt {
        pkt.extract(hdr.bridged_md);
        eg_md.flags.routed = hdr.bridged_md.base.routed;
// #ifdef TUNNEL_ENABLE
        eg_md.tunnel.cluster_index = hdr.bridged_md.tunnel.cluster_index;
        // eg_md.tunnel.hash = hdr.bridged_md.tunnel.hash;
        eg_md.tunnel.encap = hdr.bridged_md.tunnel.encap;
        eg_md.tunnel.terminate = hdr.bridged_md.tunnel.terminate;
        eg_md.tunnel.service_ip_type = hdr.bridged_md.tunnel.service_ip_type;
// #endif
        transition select(hdr.bridged_md.tunnel.encap) {
            1 : parse_ttgw;
            0 : parse_ethernet;
            default : accept;
        }
    }

    state parse_ttgw {
        pkt.extract(hdr.ttgw);
        tcp_checksum.subtract({hdr.ttgw.rs_port});
        udp_checksum.subtract({hdr.ttgw.rs_port});
        eg_md.tunnel.hash = hdr.ttgw.rss;
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type, eg_intr_md.egress_port) {
            (0x0800, _) : parse_ipv4;
            (0x86dd, _) : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        tcp_checksum.subtract({hdr.ipv4.dst_addr});
        udp_checksum.subtract({hdr.ipv4.dst_addr});
        transition select(hdr.ipv4.ihl) {
            5 : parse_ipv4_no_options;
            6 : parse_ipv4_options;
            default : accept;
        }
    }

    state parse_ipv4_options {
        // Only a single 32-bit option (e.g. router alert) is supported.
        pkt.extract(hdr.ipv4_option);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (6, 0) : parse_tcp;
            (17, 0) : parse_udp;
            default : accept;
        }
    }

    state parse_ipv6 {

        pkt.extract(hdr.ipv6);
        tcp_checksum.subtract({hdr.ipv6.dst_addr});
        udp_checksum.subtract({hdr.ipv6.dst_addr});
        transition select(hdr.ipv6.next_hdr) {
            6 : parse_tcp;
            17 : parse_udp;
            default : accept;
        }

    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        tcp_checksum.subtract_all_and_deposit(eg_md.checksum_l4_tmp);
        tcp_checksum.subtract({hdr.tcp.checksum});
        tcp_checksum.subtract({hdr.tcp.dst_port});
        transition accept;
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        udp_checksum.subtract_all_and_deposit(eg_md.checksum_l4_tmp);
        udp_checksum.subtract({hdr.udp.checksum});
        udp_checksum.subtract({hdr.udp.dst_port});
        transition select(hdr.udp.dst_port) {
            4789 : parse_vxlan;
            default : accept;
        }
    }

    state parse_vxlan {
// #ifdef TUNNEL_ENABLE
        pkt.extract(hdr.vxlan);
        eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_VXLAN;
        eg_md.tunnel.id = hdr.vxlan.vni;
        transition parse_inner_ethernet;
// #else
//         transition accept;
// #endif
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
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.ihl, hdr.inner_ipv4.frag_offset) {
            (6, 5, 0) : parse_inner_tcp;
            (17, 5, 0) : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_ipv6 {

        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr) {
            6 : parse_inner_tcp;
            17 : parse_inner_udp;
            default : accept;
        }

    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }
}

//=============================================================================
// TTGW EgressDeparser
//=============================================================================
control TtgwEgressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    Checksum() inner_l4_checksum;

    apply {
        hdr.ipv4.hdr_checksum = ipv4_checksum.update({
            hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.total_len,
            hdr.ipv4.identification,
            hdr.ipv4.flags,
            hdr.ipv4.frag_offset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.src_addr,
            hdr.ipv4.dst_addr});
            // hdr.opaque_option.type,
            // hdr.opaque_option.length,
            // hdr.opaque_option.value});

// #ifdef TUNNEL_ENABLE
        if (eg_md.checksum_inner_ipv4_udp){
            hdr.inner_ipv4.hdr_checksum = inner_ipv4_checksum.update({
                hdr.inner_ipv4.version,
                hdr.inner_ipv4.ihl,
                hdr.inner_ipv4.diffserv,
                hdr.inner_ipv4.total_len,
                hdr.inner_ipv4.identification,
                hdr.inner_ipv4.flags,
                hdr.inner_ipv4.frag_offset,
                hdr.inner_ipv4.ttl,
                hdr.inner_ipv4.protocol,
                hdr.inner_ipv4.src_addr,
                hdr.inner_ipv4.dst_addr});
        }
// #endif

        // TO DO : udp branch may meet some error out of double vxlan
        if (eg_md.checksum_upd_tcp_ipv4){
            hdr.inner_tcp.checksum = inner_l4_checksum.update({
                    hdr.ttgw.rs_port,
                    eg_md.lkp.ip_dst_addr,
                    eg_md.lkp.l4_dst_port,
                    eg_md.checksum_l4_tmp
            });
        }
        if (eg_md.checksum_upd_tcp_ipv6){
            hdr.inner_tcp.checksum = inner_l4_checksum.update({
                    hdr.ttgw.rs_port,
                    eg_md.lkp.ip_dst_addr,
                    eg_md.lkp.l4_dst_port,
                    eg_md.checksum_l4_tmp
            });
        }
        if (eg_md.checksum_upd_udp_ipv4){
            hdr.inner_udp.checksum = inner_l4_checksum.update(data = {
                    hdr.ttgw.rs_port,
                    eg_md.lkp.ip_dst_addr,
                    eg_md.lkp.l4_dst_port,
                    eg_md.checksum_l4_tmp
            }, zeros_as_ones = true);
            // UDP specific checksum handling
        }
        if (eg_md.checksum_upd_udp_ipv6){
            hdr.inner_udp.checksum = inner_l4_checksum.update(data = {
                    hdr.ttgw.rs_port,
                    eg_md.lkp.ip_dst_addr,
                    eg_md.lkp.l4_dst_port,
                    eg_md.checksum_l4_tmp
            }, zeros_as_ones = true);
            // UDP specific checksum handling
        }

        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.fabric); // Egress only.
        pkt.emit(hdr.cpu); // Egress only.
        pkt.emit(hdr.timestamp); // Egress only.
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
        // pkt.emit(hdr.dtel); // Egress only.
        // pkt.emit(hdr.dtel_switch_local_report); // Egress only.
        // pkt.emit(hdr.dtel_drop_report); // Egress only.
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.gre); // Egress only.
        pkt.emit(hdr.erspan_type2); // Egress only.
        pkt.emit(hdr.erspan_type3); // Egress only.
        pkt.emit(hdr.erspan_platform); // Egress only.
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
    }
}

// ============================================================================
// Inner packet validaion
// Validate ethernet, Ipv4 or Ipv6 common lookup fields.
// NOTE:
// For IPinIP packets, the actions are valid_ipv*. This would set the L2
// lookup fields to 0. The RMAC table is setup to ignore the dmac to process
// these packets
// ============================================================================

control GwPktValidation(
        in switch_header_t hdr,
        inout switch_ingress_flags_t flags,
        inout switch_lookup_fields_t lkp) {
//-----------------------------------------------------------------------------
// Validate outer packet header
// - Drop the packet if src addr is zero or multicast or dst addr is zero.
//-----------------------------------------------------------------------------
    action valid_ipv6_pkt() {
        // Set common lookup fields
        lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        lkp.ip_tos = hdr.ipv6.traffic_class;
        lkp.ip_proto = hdr.ipv6.next_hdr;
        lkp.ip_ttl = hdr.ipv6.hop_limit;
        lkp.ip_src_addr = hdr.ipv6.src_addr;
        lkp.ip_dst_addr = hdr.ipv6.dst_addr;
    }

    action valid_ipv4_pkt() {
        // Set common lookup fields
        lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        lkp.ip_tos = hdr.ipv4.diffserv;
        lkp.ip_proto = hdr.ipv4.protocol;
        lkp.ip_ttl = hdr.ipv4.ttl;
        lkp.ip_src_addr = (bit<128>) hdr.ipv4.src_addr;
        lkp.ip_dst_addr = (bit<128>) hdr.ipv4.dst_addr;
    }

    action valid_ipv4_pkt_untagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_UNICAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.ethernet.ether_type;
        valid_ipv4_pkt();
    }

    action valid_ipv6_pkt_untagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_UNICAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.ethernet.ether_type;
        valid_ipv6_pkt();
    }

    table validate_ethernet {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }

        actions = {
            valid_ipv4_pkt_untagged;
            valid_ipv6_pkt_untagged;
        }
        const entries = {
            (true, false) : valid_ipv4_pkt_untagged();
            (false, true) : valid_ipv6_pkt_untagged();
        }

    }

//-----------------------------------------------------------------------------
// Set L4 and other lookup fields
//-----------------------------------------------------------------------------
    action set_tcp_ports() {
        lkp.l4_src_port = hdr.tcp.src_port;
        lkp.l4_dst_port = hdr.tcp.dst_port;
        lkp.tcp_flags = hdr.tcp.flags;
    }

    action set_udp_ports() {
        lkp.l4_src_port = hdr.udp.src_port;
        lkp.l4_dst_port = hdr.udp.dst_port;
        lkp.tcp_flags = 0;
    }

    table validate_other {
        key = {
            hdr.tcp.isValid() : exact;
            hdr.udp.isValid() : exact;
        }

        actions = {
            NoAction;
            set_tcp_ports;
            set_udp_ports;
        }

        const default_action = NoAction;
        const entries = {
            (true, false) : set_tcp_ports();
            (false, true) : set_udp_ports();
        }
    }

    apply {
        validate_ethernet.apply();
        // validate_other.apply();
    }
}


control GwIngressSystemAcl(
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(
        switch_uint32_t acl_table_size=512,
        switch_uint32_t drop_stats_table_size=1024) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS) stats;

    action drop_count() {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        stats.count();
    }

    action count() {
        stats.count();
    }

    table drop_stats {
        key = {
            ig_md.drop_reason : exact @name("drop_reason");
        }

        actions = {
            @defaultonly NoAction;
            drop_count;
            count;
        }

        const default_action = NoAction;
        counters = stats;
        size = drop_stats_table_size;
    }

    apply {
        drop_stats.apply();
    }
}

control TtgwEgressSystemAcl(
        inout switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)(
        switch_uint32_t acl_table_size=512,
        switch_uint32_t drop_stats_table_size=1024) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) stats;

    action drop_count() {
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        stats.count();
    }

    action count() {
        stats.count();
    }

    table drop_stats {
        key = {
            eg_md.drop_reason : exact @name("drop_reason");
        }

        actions = {
            @defaultonly NoAction;
            drop_count;
            count;
        }

        const default_action = NoAction;
        counters = stats;
        size = drop_stats_table_size;
    }

    apply {
        drop_stats.apply();
    }
}


//-----------------------------------------------------------------------------
// Tunnel decapsulation
//
// @param hdr : Parsed headers.
// @param mode :  Specify the model for tunnel decapsulation. In the UNIFORM model, ttl and dscp
// fields are preserved by copying from the outer header on decapsulation. In the PIPE mode, ttl,
// and dscp fields of the inner header are independent of that in the outer header and remain the
// same on decapsulation.
//
//-----------------------------------------------------------------------------
control TunnelDecap(inout switch_header_t hdr,
                    in switch_egress_metadata_t eg_md)(
                    switch_tunnel_mode_t mode) {
    action decap_inner_udp() {
        hdr.udp = hdr.inner_udp;
        hdr.inner_udp.setInvalid();
    }

    action decap_inner_tcp() {
        hdr.tcp = hdr.inner_tcp;
        hdr.inner_tcp.setInvalid();
        hdr.udp.setInvalid();
    }

    action decap_inner_unknown() {
        hdr.udp.setInvalid();
    }

    table decap_inner_l4 {
        key = {
            hdr.inner_udp.isValid() : exact;
            hdr.inner_tcp.isValid() : exact;
        }
        actions = {
            decap_inner_udp;
            decap_inner_tcp;
            decap_inner_unknown;
        }

        const default_action = decap_inner_unknown;
        const entries = {
            (true, false) : decap_inner_udp();
            (false, true) : decap_inner_tcp();
        }
        size = 16;
    }

    action copy_ipv4_header() {
        hdr.ipv4.setValid();
        hdr.ipv4.version = hdr.inner_ipv4.version;
        hdr.ipv4.ihl = hdr.inner_ipv4.ihl;
        hdr.ipv4.total_len = hdr.inner_ipv4.total_len;
        hdr.ipv4.identification = hdr.inner_ipv4.identification;
        hdr.ipv4.flags = hdr.inner_ipv4.flags;
        hdr.ipv4.frag_offset = hdr.inner_ipv4.frag_offset;
        hdr.ipv4.protocol = hdr.inner_ipv4.protocol;
        // hdr.ipv4.hdr_checksum = hdr.inner_ipv4.hdr_checksum;
        hdr.ipv4.src_addr = hdr.inner_ipv4.src_addr;
        hdr.ipv4.dst_addr = hdr.inner_ipv4.dst_addr;

        if (mode == switch_tunnel_mode_t.UNIFORM) {
            // NoAction.
            hdr.ipv4.ttl = DEFAULT_VXLAN_TTL;
        } else if (mode == switch_tunnel_mode_t.PIPE) {
            hdr.ipv4.ttl = hdr.inner_ipv4.ttl;
            hdr.ipv4.diffserv = hdr.inner_ipv4.diffserv;
        }
        hdr.inner_ipv4.setInvalid();
    }

    action copy_ipv6_header() {
        hdr.ipv6.setValid();
        hdr.ipv6.version = hdr.inner_ipv6.version;
        hdr.ipv6.flow_label = hdr.inner_ipv6.flow_label;
        hdr.ipv6.payload_len = hdr.inner_ipv6.payload_len;
        hdr.ipv6.next_hdr = hdr.inner_ipv6.next_hdr;
        hdr.ipv6.src_addr = hdr.inner_ipv6.src_addr;
        hdr.ipv6.dst_addr = hdr.inner_ipv6.dst_addr;

        if (mode == switch_tunnel_mode_t.UNIFORM) {
            // NoAction.
            hdr.ipv6.hop_limit = DEFAULT_VXLAN_TTL;
        } else if (mode == switch_tunnel_mode_t.PIPE) {
            hdr.ipv6.hop_limit = hdr.inner_ipv6.hop_limit;
            hdr.ipv6.traffic_class = hdr.inner_ipv6.traffic_class;
        }
        hdr.inner_ipv6.setInvalid();
    }

    action invalidate_tunneling_headers() {
        // Removing tunneling headers by default.
        hdr.vxlan.setInvalid();
    }

    action decap_inner_ethernet_ipv4() {
        hdr.ethernet = hdr.inner_ethernet;
        copy_ipv4_header();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_tunneling_headers();
    }

    action decap_inner_ethernet_ipv6() {

        hdr.ethernet = hdr.inner_ethernet;
        copy_ipv6_header();
        hdr.ipv4.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_tunneling_headers();

    }

    action decap_inner_ethernet_non_ip() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_tunneling_headers();
    }

    action decap_inner_ipv4() {
        hdr.ethernet.ether_type = 0x0800;
        copy_ipv4_header();
        hdr.ipv6.setInvalid();
        invalidate_tunneling_headers();
    }

    action decap_inner_ipv6() {

        hdr.ethernet.ether_type = 0x86dd;
        copy_ipv6_header();
        hdr.ipv4.setInvalid();
        invalidate_tunneling_headers();

    }

    table decap_inner_ip {
        key = {
            hdr.inner_ethernet.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }

        actions = {
            decap_inner_ethernet_ipv4;
            decap_inner_ethernet_ipv6;
            decap_inner_ethernet_non_ip;
            decap_inner_ipv4;
            decap_inner_ipv6;
        }

        const entries = {
            (true, true, false) : decap_inner_ethernet_ipv4();
            (true, false, true) : decap_inner_ethernet_ipv6();
            (true, false, false) : decap_inner_ethernet_non_ip();
            (false, true, false) : decap_inner_ipv4();
            (false, false, true) : decap_inner_ipv6();
        }
        size = 16;
    }

    apply {
// #ifdef TUNNEL_ENABLE
        if (!(eg_md.bypass & GW_EGRESS_BYPASS_TUNNEL != 0)) {
            // Copy L3 headers into inner headers.
            decap_inner_ip.apply();
            // Copy L4 headers into inner headers.
            decap_inner_l4.apply();
        }
// #endif /* TUNNEL_ENABLE */
    }
}

//-----------------------------------------------------------------------------
// Tunnel rewrite
// Outer ETH / IP / UDP / VXLAN rewrite
//-----------------------------------------------------------------------------
control TunnelRewrite(inout switch_header_t hdr,
                      inout switch_egress_metadata_t eg_md,
                      inout switch_lookup_fields_t lkp) {

    // Tunnel destination IP rewrite
    action rewrite_ipv4_dst() {
        hdr.ipv4.dst_addr = hdr.ttgw.rs_vtep[31:0];
    }

    action rewrite_ipv6_dst() {
        hdr.ipv6.dst_addr = hdr.ttgw.rs_vtep;
    }

    // Inner destination IP rewrite
    action rewrite_inner_ipv4_dst() {
        hdr.inner_ipv4.dst_addr = hdr.ttgw.rs_addr[31:0];
    }

    action rewrite_inner_ipv6_dst() {
        hdr.inner_ipv6.dst_addr = hdr.ttgw.rs_addr;
    }

    // Tunnel source IP rewrite
    action rewrite_ipv4_src() {
        hdr.ipv4.src_addr = hdr.ttgw.local_vtep[31:0];
    }

    action rewrite_ipv6_src() {
        hdr.ipv6.src_addr = hdr.ttgw.local_vtep;
    }

    action rewrite_src_miss() {
        eg_md.drop_reason = SWITCH_DROP_REASON_TUNNEL_REWRITE_MISS;
    }

    table src_addr_rewrite {
        key = {
            eg_md.tunnel.ip_type : exact @name("ip_type");
        }
        actions = {
            rewrite_ipv4_src;
            rewrite_ipv6_src;
            rewrite_src_miss;
        }

        default_action = rewrite_src_miss;
        size = 4;

        const entries = {
            SWITCH_IP_TYPE_IPV4 : rewrite_ipv4_src();
            SWITCH_IP_TYPE_IPV6 : rewrite_ipv6_src();
        }
    }

    action rewrite_inner_default_mac(mac_addr_t rs_mac, mac_addr_t smac) {
        hdr.inner_ethernet.dst_addr = rs_mac;
        hdr.inner_ethernet.src_addr = smac;
    }

    action rewrite_inner_mac_miss() {
        eg_md.drop_reason = SWITCH_DROP_REASON_TUNNEL_REWRITE_MISS;
    }

    table rewrite_inner_mac {
        actions = {
            rewrite_inner_mac_miss;
            rewrite_inner_default_mac;
        }

        default_action = rewrite_inner_mac_miss;
    }

    action rewrite_default_vni(bit<24> tunnel_id) {
        hdr.vxlan.vni = tunnel_id;
    }

    action rewrite_tunnel_id_miss() {
        eg_md.drop_reason = SWITCH_DROP_REASON_TUNNEL_REWRITE_MISS;
    }

    table rewrite_tunnel_id {
        actions = {
            rewrite_tunnel_id_miss;
            rewrite_default_vni;
        }

        default_action = rewrite_tunnel_id_miss;
    }

    action rewrite_inner_tcp_port() {
        hdr.inner_tcp.dst_port = hdr.ttgw.rs_port;
    }

    action rewrite_inner_udp_port() {
        hdr.inner_udp.dst_port = hdr.ttgw.rs_port;
    }

    table rewrite_inner_dst_port {
        key = {
            hdr.inner_udp.isValid() : exact;
            hdr.inner_tcp.isValid() : exact;
        }

        actions = {
            rewrite_inner_udp_port;
            rewrite_inner_tcp_port;
        }

        const entries = {
            (true, false) : rewrite_inner_udp_port();
            (false, true) : rewrite_inner_tcp_port();
        }
    }

    apply {
        if (!(eg_md.bypass & GW_EGRESS_BYPASS_TUNNEL != 0)) {
            switch(src_addr_rewrite.apply().action_run) {
                rewrite_ipv4_src : {
                    rewrite_ipv4_dst();
                }

                rewrite_ipv6_src : {
                    rewrite_ipv6_dst();
                }
            }

            rewrite_inner_mac.apply();
            rewrite_inner_dst_port.apply();
            rewrite_tunnel_id.apply();

            if (eg_md.tunnel.service_ip_type == SWITCH_IP_TYPE_IPV4) {
                rewrite_inner_ipv4_dst();
            } else if (eg_md.tunnel.service_ip_type == SWITCH_IP_TYPE_IPV6) {
                rewrite_inner_ipv6_dst();
            }
        }
    }
}

//-----------------------------------------------------------------------------
// Tunnel encapsulation
//
// @param hdr : Parsed headers.
// @param eg_md : Egress metadata fields.
// @param mode :  Specify the model for tunnel encapsulation. In the UNIFORM model, ttl and dscp
// fields are preserved by copying into the outer header on encapsulation. This results in 'normal'
// behaviour for ECN field (See RFC 6040 secion 4.1). In the PIPE model, outer header ttl and dscp
// fields are independent of that in the inner header and are set to user-defined values on
// encapsulation.
// @param vni_mapping_table_size : Number of VNIs.
//
//-----------------------------------------------------------------------------
control TunnelEncap(inout switch_header_t hdr,
                    inout switch_egress_metadata_t eg_md)(
                    switch_tunnel_mode_t mode=switch_tunnel_mode_t.PIPE) {
    bit<16> payload_len = 16w0;

    action copy_ipv4_header() {
        // Copy all of the IPv4 header fields.
        hdr.inner_ipv4.setValid();
        hdr.inner_ipv4.version = hdr.ipv4.version;
        hdr.inner_ipv4.ihl = hdr.ipv4.ihl;
        hdr.inner_ipv4.diffserv = hdr.ipv4.diffserv;
        hdr.inner_ipv4.total_len = hdr.ipv4.total_len;
        hdr.inner_ipv4.identification = hdr.ipv4.identification;
        hdr.inner_ipv4.flags = hdr.ipv4.flags;
        hdr.inner_ipv4.frag_offset = hdr.ipv4.frag_offset;
        hdr.inner_ipv4.ttl = hdr.ipv4.ttl - 1;
        hdr.inner_ipv4.protocol = hdr.ipv4.protocol;
        // hdr.inner_ipv4.hdr_checksum = hdr.ipv4.hdr_checksum;
        hdr.inner_ipv4.src_addr = hdr.ipv4.src_addr;
        hdr.inner_ipv4.dst_addr = hdr.ipv4.dst_addr;
        hdr.ipv4.setInvalid();
    }

    action copy_ipv6_header() {
        hdr.inner_ipv6.setValid();
        hdr.inner_ipv6.version = hdr.ipv6.version;
        hdr.inner_ipv6.traffic_class = hdr.ipv6.traffic_class;
        hdr.inner_ipv6.flow_label = hdr.ipv6.flow_label;
        hdr.inner_ipv6.payload_len = hdr.ipv6.payload_len;
        hdr.inner_ipv6.next_hdr = hdr.ipv6.next_hdr;
        hdr.inner_ipv6.hop_limit = hdr.ipv6.hop_limit - 1;
        hdr.inner_ipv6.src_addr = hdr.ipv6.src_addr;
        hdr.inner_ipv6.dst_addr = hdr.ipv6.dst_addr;
        hdr.ipv6.setInvalid();
    }

    action rewrite_inner_ipv4_udp() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        hdr.inner_udp = hdr.udp;
        hdr.udp.setInvalid();
    }

    action rewrite_inner_ipv4_tcp() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        hdr.inner_tcp = hdr.tcp;
        hdr.tcp.setInvalid();
    }

    action rewrite_inner_ipv4_unknown() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
    }

    action rewrite_inner_ipv6_udp() {

        payload_len = hdr.ipv6.payload_len + 16w40;
        copy_ipv6_header();
        hdr.inner_udp = hdr.udp;
        hdr.udp.setInvalid();

    }

    action rewrite_inner_ipv6_tcp() {

        payload_len = hdr.ipv6.payload_len + 16w40;
        copy_ipv6_header();
        hdr.inner_tcp = hdr.tcp;
        hdr.tcp.setInvalid();

    }

    action rewrite_inner_ipv6_unknown() {

        payload_len = hdr.ipv6.payload_len + 16w40;
        copy_ipv6_header();

    }

    table encap_outer {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.tcp.isValid() : exact;
        }

        actions = {
            rewrite_inner_ipv4_udp;
            rewrite_inner_ipv4_unknown;
            rewrite_inner_ipv6_udp;
            rewrite_inner_ipv6_unknown;
            rewrite_inner_ipv4_tcp;
            rewrite_inner_ipv6_tcp;
        }

        const entries = {
            (true, false, false, false) : rewrite_inner_ipv4_unknown();
            (false, true, false, false) : rewrite_inner_ipv6_unknown();
            (true, false, true, false) : rewrite_inner_ipv4_udp();
            (false, true, true, false) : rewrite_inner_ipv6_udp();
            (true, false, false, true) : rewrite_inner_ipv4_tcp();
            (false, true, false, true) : rewrite_inner_ipv6_tcp();
        }
    }

//-----------------------------------------------------------------------------
// Helper actions to add various headers.
//-----------------------------------------------------------------------------
    action add_udp_header(bit<16> src_port, bit<16> dst_port) {
        hdr.udp.setValid();
        hdr.udp.src_port = src_port | 0xC000;
        hdr.udp.dst_port = dst_port;
        hdr.udp.checksum = 0;
        // hdr.udp.length = 0;
    }

    action add_vxlan_header() {

        hdr.vxlan.setValid();
        hdr.vxlan.flags = 8w0x08;
        // hdr.vxlan.reserved = 0;
        // hdr.vxlan.vni = vni;
        // hdr.vxlan.reserved2 = 0;

    }

    action add_ipv4_header(bit<8> proto) {
        hdr.ipv4.setValid();
        hdr.ipv4.version = 4w4;
        hdr.ipv4.ihl = 4w5;
        // hdr.ipv4.total_len = 0;
        hdr.ipv4.identification = 0;
        hdr.ipv4.flags = 0;
        hdr.ipv4.frag_offset = 0;
        hdr.ipv4.protocol = proto;
        // hdr.ipv4.src_addr = 0;
        // hdr.ipv4.dst_addr = 0;

        if (mode == switch_tunnel_mode_t.UNIFORM) {
            // NoAction.
            hdr.ipv4.ttl = DEFAULT_VXLAN_TTL + 1;
        } else if (mode == switch_tunnel_mode_t.PIPE) {
            hdr.ipv4.ttl = DEFAULT_VXLAN_TTL + 1;
            hdr.ipv4.diffserv = 0;
        }
    }

    action add_ipv6_header(bit<8> proto) {

        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w6;
        hdr.ipv6.flow_label = 0;
        // hdr.ipv6.payload_len = 0;
        hdr.ipv6.next_hdr = proto;
        // hdr.ipv6.src_addr = 0;
        // hdr.ipv6.dst_addr = 0;

        if (mode == switch_tunnel_mode_t.UNIFORM) {
            // NoAction.
            hdr.ipv6.hop_limit = DEFAULT_VXLAN_TTL + 1;
        } else if (mode == switch_tunnel_mode_t.PIPE) {
            hdr.ipv6.hop_limit = DEFAULT_VXLAN_TTL + 1;
            hdr.ipv6.traffic_class = 0;
        }

    }

    action rewrite_ipv4_vxlan(bit<16> vxlan_port) {
        hdr.inner_ethernet = hdr.ethernet;
        add_ipv4_header(17);
        // Total length = packet length + 50
        //   IPv4 (20) + UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.ipv4.total_len = payload_len + 16w50;

        add_udp_header(eg_md.tunnel.hash, vxlan_port);
        // UDP length = packet length + 30
        //   UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.udp.length = payload_len + 16w30;

        add_vxlan_header();
        hdr.ethernet.ether_type = 0x0800;
    }

    action rewrite_ipv6_vxlan(bit<16> vxlan_port) {

        hdr.inner_ethernet = hdr.ethernet;
        add_ipv6_header(17);
        // Payload length = packet length + 50
        //   UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.ipv6.payload_len = payload_len + 16w30;

        add_udp_header(eg_md.tunnel.hash, vxlan_port);
        // UDP length = packet length + 30
        //   UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.udp.length = payload_len + 16w30;

        add_vxlan_header();
        hdr.ethernet.ether_type = 0x86dd;

    }

    apply {
// #ifdef TUNNEL_ENABLE
        if (!(eg_md.bypass & GW_EGRESS_BYPASS_TUNNEL != 0)) {
            // Copy L3/L4 header into inner headers.
            encap_outer.apply();

            // Add outer L3/L4/Tunnel headers.
            if (eg_md.tunnel.ip_type == SWITCH_IP_TYPE_IPV4) {
                rewrite_ipv4_vxlan(4789);
            }
            else if (eg_md.tunnel.ip_type == SWITCH_IP_TYPE_IPV6) {
                rewrite_ipv6_vxlan(4789);
            }
        }
// #endif
    }
}

control DscpXlate(inout switch_header_t hdr,
                  in switch_egress_metadata_t eg_md)(
                  switch_uint32_t dscp_table_size = 1024) {

    action dscp_in_rewritev4(bit<6> dscp) {
        hdr.ipv4.diffserv[7:2] = dscp;
    }

    action dscp_in_rewritev6(bit<6> dscp) {
        hdr.ipv6.traffic_class[7:2] = dscp;
    }

    table dscp_in_xlate {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            eg_md.tunnel.cluster_index : exact @name("cluster_index");
        }
        actions = {
            NoAction;
            dscp_in_rewritev4;
            dscp_in_rewritev6;
        }

        default_action = NoAction;
        size = dscp_table_size;
    }

    action dscp_out_rewritev4(bit<6> dscp) {
        hdr.ipv4.diffserv[7:2] = dscp;
    }

    action dscp_out_rewritev6(bit<6> dscp) {
        hdr.ipv6.traffic_class[7:2] = dscp;
    }

    table dscp_out_xlate {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            eg_md.tunnel.cluster_index : exact @name("cluster_index");
        }
        actions = {
            NoAction;
            dscp_out_rewritev4;
            dscp_out_rewritev6;
        }

        default_action = NoAction;
        size = dscp_table_size;
    }

    apply {
        if (eg_md.tunnel.encap == 1) {
            dscp_in_xlate.apply();
        }
        else if (eg_md.tunnel.terminate == 1) {
            dscp_out_xlate.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// GWFIB lookup
//
// @param dst_addr : Destination IPv6/Ipv4 address.
// @param vrf
// @param flags
// @param nexthop : Nexthop index.
// @param host_table_size : Size of the host table.
// @param lpm_table_size : Size of the IPv4 route table.
//-----------------------------------------------------------------------------
control GwFib(in ipv4_addr_t dst_addr,
            in switch_vrf_t vrf,
            out switch_ingress_flags_t flags,
            out switch_nexthop_t nexthop)(
            switch_uint32_t host_table_size,
            switch_uint32_t lpm_table_size,
            bool local_host_enable=false,
            switch_uint32_t local_host_table_size=1024) {
    action fib_hit(switch_nexthop_t nexthop_index) {
        nexthop = nexthop_index;
        flags.routed = true;
    }

    action fib_miss() {
        flags.routed = false;
    }

    action fib_myip_subnet() {
        flags.myip = SWITCH_MYIP_SUBNET;
    }

    action fib_myip() {
        flags.myip = SWITCH_MYIP;
    }

    table fib {
        key = {
            vrf : exact;
            dst_addr : exact;
        }

        actions = {
            fib_miss;
            fib_hit;
            fib_myip;
        }

        const default_action = fib_miss;
        size = host_table_size;
    }

    table fib_local_host {
        key = {
            vrf : exact;
            dst_addr : exact;
        }

        actions = {
            fib_miss;
            fib_hit;
            fib_myip;
        }

        const default_action = fib_miss;
        size = local_host_table_size;
    }

    @alpm(1)
    @alpm_partitions(1024)
    @alpm_subtrees_per_partition(2)
    table fib_lpm {
        key = {
            vrf : exact;
            dst_addr : lpm;
        }

        actions = {
            fib_miss;
            fib_hit;
            fib_myip;
            fib_myip_subnet;
        }

        const default_action = fib_miss;
        size = lpm_table_size;
    }

    apply {
        if (local_host_enable) {
            if (!fib_local_host.apply().hit) {
                if (!fib.apply().hit) {
                    fib_lpm.apply();
                }
            }
        } else {
            if (!fib.apply().hit) {
                fib_lpm.apply();
            }
        }
    }
}

control GwFibv6(in ipv6_addr_t dst_addr,
              in switch_vrf_t vrf,
              out switch_ingress_flags_t flags,
              out switch_nexthop_t nexthop)(
              switch_uint32_t host_table_size,
              switch_uint32_t lpm_table_size,
              switch_uint32_t lpm64_table_size=1024) {
    action fib_hit(switch_nexthop_t nexthop_index) {
        nexthop = nexthop_index;
        flags.routed = true;
    }

    action fib_miss() {
        flags.routed = false;
    }

    action fib_myip_subnet() {
        flags.myip = SWITCH_MYIP_SUBNET;
    }

    action fib_myip() {
        flags.myip = SWITCH_MYIP;
    }

    table fib {
        key = {
            vrf : exact;
            dst_addr : exact;
        }

        actions = {
            fib_miss;
            fib_hit;
            fib_myip;
        }

        const default_action = fib_miss;
        size = host_table_size;
    }

    @alpm(1)
    @alpm_partitions(1024)
    @alpm_subtrees_per_partition(2)

    table fib_lpm {
        key = {
            vrf : exact;
            dst_addr : lpm;
        }

        actions = {
            fib_miss;
            fib_hit;
            fib_myip;
            fib_myip_subnet;
        }

        const default_action = fib_miss;
        size = lpm_table_size;
    }
    apply {

        if (!fib.apply().hit) {

            if (!fib_lpm.apply().hit)

            {

            }
        }

    }
}

// ----------------------------------------------------------------------------
// GW Nexthop/ECMP resolution
//
// @param ig_md : Ingress metadata fields
// @param nexthop_table_size : Number of nexthops.
// @param ecmp_group_table_size : Number of ECMP groups.
// @param ecmp_selction_table_size : Maximum number of ECMP members.
//
// ----------------------------------------------------------------------------
control GwNexthop(inout switch_ingress_metadata_t ig_md)(
                switch_uint32_t nexthop_table_size,
                switch_uint32_t ecmp_group_table_size,
                switch_uint32_t ecmp_selection_table_size) {

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionProfile(ecmp_selection_table_size) ecmp_action_profile;

    ActionSelector(ecmp_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   ECMP_MAX_MEMBERS_PER_GROUP,
                   ecmp_group_table_size) ecmp_selector;

    action set_nexthop_properties(switch_port_lag_index_t port_lag_index,
                                  switch_bd_t bd,
                                  switch_nat_zone_t zone) {

        ig_md.egress_port_lag_index = port_lag_index;

        ig_md.checks.same_if = ig_md.port_lag_index ^ port_lag_index;
    }

    action set_nexthop_properties_post_routed_flood(switch_bd_t bd, switch_mgid_t mgid) {
        ig_md.egress_port_lag_index = 0;
        ig_md.multicast.id = mgid;
    }

    action set_nexthop_properties_glean() {
        ig_md.flags.glean = true;
    }

    action set_nexthop_properties_drop() {
        ig_md.drop_reason = SWITCH_DROP_REASON_NEXTHOP;
    }

    action set_ecmp_properties(switch_port_lag_index_t port_lag_index,
                               switch_bd_t bd,
                               switch_nexthop_t nexthop_index, switch_nat_zone_t zone) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties(port_lag_index, bd, zone);
    }

    action set_ecmp_properties_drop() {
        set_nexthop_properties_drop();
    }
    action set_ecmp_properties_post_routed_flood(
            switch_bd_t bd,
            switch_mgid_t mgid,
            switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties_post_routed_flood(bd, mgid);
    }

    action set_ecmp_properties_glean(switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties_glean();
    }

    action set_nexthop_properties_tunnel(switch_bd_t bd, switch_tunnel_index_t tunnel_index) {
        // TODO(msharif) : Disable cut-through for non-ip packets.
        ig_md.tunnel.index = tunnel_index;
        ig_md.egress_port_lag_index = 0;
    }

    action set_ecmp_properties_tunnel(switch_bd_t bd, switch_tunnel_index_t tunnel_index, switch_nexthop_t
    nexthop_index) {
        set_nexthop_properties_tunnel(bd, tunnel_index);
        ig_md.nexthop = nexthop_index;
    }

    table ecmp {
        key = {
            ig_md.nexthop : exact;
            ig_md.hash : selector;
        }

        actions = {
            NoAction;
            set_ecmp_properties;
            set_ecmp_properties_drop;
            set_ecmp_properties_glean;
            set_ecmp_properties_post_routed_flood;
        }

        const default_action = NoAction;
        size = ecmp_group_table_size;
        implementation = ecmp_selector;
    }

    table nexthop {
        key = {
            ig_md.nexthop : exact;
        }

        actions = {
            NoAction;
            set_nexthop_properties;
            set_nexthop_properties_drop;
            set_nexthop_properties_glean;
            set_nexthop_properties_post_routed_flood;
        }

        const default_action = NoAction;
        size = nexthop_table_size;
    }

    apply {

        switch(nexthop.apply().action_run) {
            NoAction : { ecmp.apply(); }
            default : {}
        }

    }
}

// ----------------------------------------------------------------------------
// GW Link Aggregation (LAG) resolution
//
// @param ig_md : Ingress metadata fields.
// @param hash : Hash value used for port selection.
// @param egress_port : Egress port.
//
// @flag MLAG_ENABLE : Enable multi-chassis LAG.
// ----------------------------------------------------------------------------

control GwLAG(inout switch_ingress_metadata_t ig_md,
            in bit<16> hash,
            out switch_port_t egress_port) {

    bit<16> lag_hash;

    Hash<switch_uint16_t>(HashAlgorithm_t.CRC16) selector_hash;

    ActionProfile(LAG_SELECTOR_TABLE_SIZE) lag_action_profile;
    ActionSelector(lag_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   LAG_MAX_MEMBERS_PER_GROUP,
                   LAG_GROUP_TABLE_SIZE) lag_selector;

    action set_lag_port(switch_port_t port) {
        egress_port = port;
    }

    action set_peer_link_port(switch_port_t port, switch_port_lag_index_t port_lag_index) {
        egress_port = port;
        ig_md.egress_port_lag_index = port_lag_index;
        ig_md.checks.same_if = ig_md.port_lag_index ^ port_lag_index;
    }

    action lag_miss() { }

    table lag {
        key = {

            ig_md.egress_port_lag_index : exact @name("port_lag_index");

            lag_hash : selector;

        }

        actions = {
            lag_miss;
            set_lag_port;

        }

        const default_action = lag_miss;
        size = LAG_TABLE_SIZE;
        implementation = lag_selector;
    }

    apply {
        lag_hash = selector_hash.get({ig_md.lkp.mac_src_addr,
                                      ig_md.lkp.mac_dst_addr,
                                      ig_md.lkp.mac_type,
                                      ig_md.lkp.ip_src_addr,
                                      ig_md.lkp.ip_dst_addr,
                                      ig_md.lkp.ip_proto,
                                      ig_md.lkp.l4_dst_port,
                                      ig_md.lkp.l4_src_port});
        lag.apply();
    }
}

control GwIngress(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    GwPktValidation() pkt_validation;
    Ipv4Hash() ipv4_hash;
    Ipv6Hash() ipv6_hash;
    NonIpHash() non_ip_hash;
    GwFib(IPV4_HOST_TABLE_SIZE,
    IPV4_LPM_TABLE_SIZE,
    true,
    IPV4_LOCAL_HOST_TABLE_SIZE) ipv4_fib;
    GwFibv6(IPV6_HOST_TABLE_SIZE, IPV6_LPM_TABLE_SIZE, IPV6_LPM64_TABLE_SIZE) ipv6_fib;
    GwNexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
    GwLAG() lag;
    GwIngressSystemAcl() system_acl;

    apply {
        pkt_validation.apply(hdr, ig_md.flags, ig_md.lkp);

        ig_md.port_lag_index = hdr.bridged_md.base.ingress_port_lag_index;
        ig_md.vrf = hdr.bridged_md.tunnel.vrf;

        if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
          ipv6_fib.apply(ig_md.lkp.ip_dst_addr, ig_md.vrf, ig_md.flags, ig_md.nexthop);
        } else if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
          ipv4_fib.apply(ig_md.lkp.ip_dst_addr[31:0], ig_md.vrf, ig_md.flags, ig_md.nexthop);
        }
        if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_NONE) {
            non_ip_hash.apply(ig_md.lkp, ig_md.hash[31:0]);
        } else if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
            ipv4_hash.apply(ig_md.lkp, ig_md.hash[31:0]);
        } else {
            ipv6_hash.apply(ig_md.lkp, ig_md.hash[31:0]);
        }

        nexthop.apply(ig_md);
        lag.apply(ig_md, ig_md.hash[31:16], ig_intr_md_for_tm.ucast_egress_port);
        system_acl.apply(ig_md, ig_intr_md_for_dprsr);

        rewrite_bridged_md(hdr.bridged_md, ig_md);
    }
}

control TtgwEgress(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    TunnelDecap(mode=switch_tunnel_mode_t.PIPE) tunnel_decap;
    TunnelEncap(mode=switch_tunnel_mode_t.UNIFORM) tunnel_encap;
    TunnelRewrite() tunnel_rewrite;
    ChecksumType() checksum_type;
    DscpXlate(DSCP_TABLE_SIZE) dscp_xlate;
    TtgwEgressSystemAcl() system_acl;

    action set_tunnel_v4() {
        eg_md.tunnel.ip_type = SWITCH_IP_TYPE_IPV4;
    }

    action set_tunnel_v6() {
        eg_md.tunnel.ip_type = SWITCH_IP_TYPE_IPV6;
    }

    table tunnel_type {
        key = {
            hdr.ttgw.rs_vtep : ternary;
        }

        actions = {
            set_tunnel_v4;
            set_tunnel_v6;
        }

        const entries = {
            (0x00000000000000000000000000000000 &&& 0xffffffffffffffffffffffff00000000) : set_tunnel_v4();
            _ : set_tunnel_v6();
        }
    }

    apply {
        if (eg_md.tunnel.terminate == 1) {
            tunnel_decap.apply(hdr, eg_md);
        } else if (eg_md.tunnel.encap == 1) {
            tunnel_type.apply();
            tunnel_encap.apply(hdr, eg_md);
            tunnel_rewrite.apply(hdr, eg_md, eg_md.lkp);
            checksum_type.apply(eg_md, hdr);
        }
        dscp_xlate.apply(hdr, eg_md);
        system_acl.apply(eg_md, eg_intr_md_for_dprsr);
    }
}

Pipeline(GwIngressParser(),
        GwIngress(),
        GwIngressDeparser(),
        TtgwEgressParser(),
        TtgwEgress(),
        TtgwEgressDeparser()) gwpipe;

Switch(gwpipe) main;
