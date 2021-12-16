#include <t2na.p4> /* TOFINO2_ONLY */
//-----------------------------------------------------------------------------
// Features.
//-----------------------------------------------------------------------------
// L2 Unicast

//#define STORM_CONTROL_ENABLE

// L3 Unicast


// #define IPV6_LPM128_TCAM
//#define IPV4_ALPM_OPT_EN
//#define IPV6_ALPM_OPT_EN

// ACLs
// #define L4_PORT_LOU_ENABLE
// #define ETYPE_IN_IP_ACL_KEY_ENABLE

// //#define ACL_REDIRECT_PORT_ENABLE
// #define ACL_REDIRECT_NEXTHOP_ENABLE
// #define EGRESS_COPP_DISABLE
// #define L4_PORT_EGRESS_LOU_ENABLE
// #define EGRESS_ACL_PORT_RANGE_ENABLE
//To enable port_group in ingress ACLs.
//#define PORT_GROUP_IN_ACL_KEY_ENABLE


// Mirror



//#define INGRESS_MIRROR_ACL_ENABLE





// QoS

//#define INGRESS_ACL_METER_ENABLE
//#define ECN_ACL_ENABLE



// DTEL






// SFLOW
// #define INGRESS_SFLOW_ENABLE

// Tunnel
// #define TUNNEL_ENABLE
// #define IPINIP_ENABLE
// //#define IPV6_TUNNEL_ENABLE
// #define VXLAN_ENABLE
// #define L2_VXLAN_ENABLE
// #define TUNNEL_TTL_MODE_ENABLE
// //#define TUNNEL_QOS_MODE_ENABLE
// #define TUNNEL_ECN_RFC_6040_DISABLE




// #define SFC_P4C_4154_WORKAROUND
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
const bit<32> MAC_TABLE_SIZE = 64*1024;

// IP Hosts/Routes


const bit<32> IPV4_HOST_TABLE_SIZE = 64*1024;
const bit<32> IPV4_LOCAL_HOST_TABLE_SIZE = 16*1024;
const bit<32> IPV4_LPM_TABLE_SIZE = 512*1024;

const bit<32> IPV6_HOST_TABLE_SIZE = 1*1024;
const bit<32> IPV6_LPM_TABLE_SIZE = 512;
//NOTE: IPV6_LPM64_TABLE_SIZE has to be big enough (16*1024) to pass the switch_l3.L3InterfaceTest tests
const bit<32> IPV6_LPM64_TABLE_SIZE = 4*1024;

// ECMP/Nexthop
const bit<32> ECMP_GROUP_TABLE_SIZE = 1024;
const bit<32> ECMP_SELECT_TABLE_SIZE = 65536;

const bit<32> NEXTHOP_TABLE_SIZE = 1 << 16;

const bit<32> TUNNEL_NEXTHOP_TABLE_SIZE = 32768;

// Tunnels

const bit<32> TUNNEL_OBJECT_SIZE = 1 << 8;

const bit<32> TUNNEL_ENCAP_IPV4_SIZE = 4096;
const bit<32> TUNNEL_ENCAP_IPV6_SIZE = 0;
const bit<32> TUNNEL_ENCAP_IP_SIZE = TUNNEL_ENCAP_IPV4_SIZE + TUNNEL_ENCAP_IPV6_SIZE;
const bit<32> RID_TABLE_SIZE = 16384;

// Ingress ACLs
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 2048;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 1024;
const bit<32> INGRESS_IP_MIRROR_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IP_DTEL_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_DTEL_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV6_DTEL_ACL_TABLE_SIZE = 512;

// Egress ACLs
//const bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512;

// Storm Control
const bit<32> STORM_CONTROL_TABLE_SIZE = 256;

// SFC / GHOST

const bit<32> SFC_QUEUE_IDX_SIZE = 256;
const bit<32> SFC_BUFFER_IDX_SIZE = 4;
const bit<32> SFC_PORT_CNT = 256;
const bit<32> SFC_TC_CNT = 8;
const bit<32> SFC_PAUSE_DURATION_SIZE = 1024;

const bit<32> SFC_QUEUE_REG_STAGE_QD = 13;


const bit<32> sfc_suppression_filter_cnt = 1 << 16;

const bit<32> SIGNALING_DETECT_TABLE_SIZE = 8;


# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/headers.p4" 1
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

header ipv6_segment_h {
    bit<128> sid;
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
/*
    bit<1> C;
    bit<1> R;
    bit<1> K;
    bit<1> S;
    bit<1> s;
    bit<3> recurse;
    bit<5> flags;
    bit<3> version;
*/
    bit<16> flags_version;
    bit<16> proto;
}

// Network Virtualisation using GRE (NVGRE) -- RFC 7637
header nvgre_h {
    bit<32> vsid_flowid; // vsid(24) + flowid(8)
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

// GTP V2
header gtpu_h {
    bit<3> version;
    bit<1> p;
    bit<1> t;
    bit<3> spare0;
    bit<8> mesg_type;
    bit<16> mesg_len;
    bit<32> teid;
    bit<24> seq_num;
    bit<8> spare1;
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




    bit<1> pad2;
    bit<7> queue_id;

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




    bit<1> pad2;
    bit<7> queue_id;

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




    bit<1> pad;
    bit<7> queue_id;

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

// SFC header
// TODO: add header here
header sfc_pause_h {
    bit<8> version;
    bit<8> dscp;
    bit<16> duration_us;
    // TODO: padding to 64-byte packet
    // Ethernet + IP + UDP + required fields = 14 + 20 + 8 + 4 = 46
}

header padding_112b_h {
    bit<112> pad_0;
}

header padding_96b_h {
    bit<96> pad;
}

header pfc_h {
    bit<16> opcode;
    bit<8> reserved_zero;
    bit<8> class_enable_vec;
    bit<16> tstamp0;
    bit<16> tstamp1;
    bit<16> tstamp2;
    bit<16> tstamp3;
    bit<16> tstamp4;
    bit<16> tstamp5;
    bit<16> tstamp6;
    bit<16> tstamp7;
}

header timestamp_h {
    bit<48> timestamp;
}
# 177 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4" 1
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




// ----------------------------------------------------------------------------
// Common protocols/types
//-----------------------------------------------------------------------------
# 38 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
//#define ETHERTYPE_QINQ 0x88A8 // Note: uncomment once ptf/scapy-vxlan are fixed
# 86 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
// ----------------------------------------------------------------------------
// Common table sizes
//-----------------------------------------------------------------------------

const bit<32> MIN_TABLE_SIZE = 512;

const bit<32> LAG_TABLE_SIZE = 1024;
const bit<32> LAG_GROUP_TABLE_SIZE = 256;
const bit<32> LAG_MAX_MEMBERS_PER_GROUP = 64;
const bit<32> LAG_SELECTOR_TABLE_SIZE = 16384; // 256 * 64

const bit<32> VRF_TABLE_SIZE = 1024;

const bit<32> DTEL_GROUP_TABLE_SIZE = 4;
const bit<32> DTEL_MAX_MEMBERS_PER_GROUP = 64;
const bit<32> DTEL_SELECTOR_TABLE_SIZE = 256;

const bit<32> IPV4_DST_VTEP_TABLE_SIZE = 512;
const bit<32> IPV6_DST_VTEP_TABLE_SIZE = 512;



const bit<32> VNI_MAPPING_TABLE_SIZE = 1024; // 1K VRF maps


// ----------------------------------------------------------------------------
// LPM
//-----------------------------------------------------------------------------
# 170 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
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
typedef bit<8> switch_isolation_group_t;

typedef bit<16> switch_bd_t;
const switch_bd_t SWITCH_DEFAULT_BD = 16w1;
const switch_bd_t SWITCH_BD_DEFAULT_VRF = 4097; // bd allocated for default vrf




typedef bit<8> switch_vrf_t;
const switch_vrf_t SWITCH_DEFAULT_VRF = 1;




typedef bit<16> switch_nexthop_t;




typedef bit<10> switch_user_metadata_t;






typedef bit<32> switch_hash_t;

typedef bit<128> srv6_sid_t;
# 244 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
typedef bit<16> switch_xid_t;
typedef bit<9> switch_yid_t;




typedef bit<32> switch_ig_port_lag_label_t;

typedef bit<16> switch_eg_port_lag_label_t;
typedef bit<16> switch_bd_label_t;

typedef bit<16> switch_mtu_t;

typedef bit<12> switch_stats_index_t;

typedef bit<16> switch_cpu_reason_t;
const switch_cpu_reason_t SWITCH_CPU_REASON_PTP = 8;

typedef bit<8> switch_fib_label_t;

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
const switch_drop_reason_t SWITCH_DROP_REASON_DST_MAC_MCAST_DST_IP_UCAST = 18;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID = 25;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_TTL_ZERO = 26;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_SRC_MULTICAST = 27;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_SRC_LOOPBACK = 28;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_MISS = 29;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID = 30;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_INVALID_CHECKSUM = 31;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_DST_LOOPBACK = 32;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_SRC_UNSPECIFIED = 33;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_SRC_CLASS_E = 34;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_VERSION_INVALID = 40;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_TTL_ZERO = 41;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_MULTICAST = 42;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_LOOPBACK = 43;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_IHL_INVALID = 44;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_INVALID_CHECKSUM = 45;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_CLASS_E = 46;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_DST_LINK_LOCAL = 47;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_LINK_LOCAL = 48;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_DST_UNSPECIFIED = 49;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_UNSPECIFIED = 50;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_LPM4_MISS = 51;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_LPM6_MISS = 52;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_BLACKHOLE_ROUTE = 53;
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
const switch_drop_reason_t SWITCH_DROP_REASON_MPLS_LABEL_DROP = 103;
const switch_drop_reason_t SWITCH_DROP_REASON_SRV6_MY_SID_DROP = 104;
const switch_drop_reason_t SWITCH_DROP_REASON_PORT_ISOLATION_DROP = 105;
const switch_drop_reason_t SWITCH_DROP_REASON_DMAC_RESERVED = 106;

typedef bit<1> switch_port_type_t;
const switch_port_type_t SWITCH_PORT_TYPE_NORMAL = 0;
const switch_port_type_t SWITCH_PORT_TYPE_CPU = 1;

typedef bit<2> switch_ip_type_t;
const switch_ip_type_t SWITCH_IP_TYPE_NONE = 0;
const switch_ip_type_t SWITCH_IP_TYPE_IPV4 = 1;
const switch_ip_type_t SWITCH_IP_TYPE_IPV6 = 2;
const switch_ip_type_t SWITCH_IP_TYPE_MPLS = 3; // Consider renaming ip_type to l3_type

typedef bit<2> switch_ip_frag_t;
const switch_ip_frag_t SWITCH_IP_FRAG_NON_FRAG = 0b00; // Not fragmented.
const switch_ip_frag_t SWITCH_IP_FRAG_HEAD = 0b10; // First fragment of the fragmented packets.
const switch_ip_frag_t SWITCH_IP_FRAG_NON_HEAD = 0b11; // Fragment with non-zero offset.

// Bypass flags ---------------------------------------------------------------
typedef bit<16> switch_ingress_bypass_t;
# 373 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L2 = 16w0x0001 << 0;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L3 = 16w0x0001 << 1;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ACL = 16w0x0001 << 2;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SYSTEM_ACL = 16w0x0001 << 3;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_QOS = 16w0x0001 << 4;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_METER = 16w0x0001 << 5;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STORM_CONTROL = 16w0x0001 << 6;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STP = 16w0x0001 << 7;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SMAC = 16w0x0001 << 8;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_NAT = 16w0x0001 << 9;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ROUTING_CHECK = 16w0x0001 << 10;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_PV = 16w0x0001 << 11;
// Add more ingress bypass flags here.

const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ALL = 16w0xffff;


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

// Nexthop --------------------------------------------------------------------
typedef bit<2> switch_nexthop_type_t;
const switch_nexthop_type_t SWITCH_NEXTHOP_TYPE_IP = 0;
const switch_nexthop_type_t SWITCH_NEXTHOP_TYPE_MPLS = 1;
const switch_nexthop_type_t SWITCH_NEXTHOP_TYPE_TUNNEL_ENCAP = 2;

// Sflow ----------------------------------------------------------------------
typedef bit<8> switch_sflow_id_t;
const switch_sflow_id_t SWITCH_SFLOW_INVALID_ID = 8w0xff;

struct switch_sflow_metadata_t {
    switch_sflow_id_t session_id;
    bit<1> sample_packet;
}

typedef bit<8> switch_hostif_trap_t;

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
const switch_ecn_codepoint_t NON_ECT = 0b00; // Non ECN-capable transport
const switch_ecn_codepoint_t ECT0 = 0b10; // ECN capable transport
const switch_ecn_codepoint_t ECT1 = 0b01; // ECN capable transport
const switch_ecn_codepoint_t CE = 0b11; // Congestion encountered

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



    bit<32> timestamp;




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
typedef bit<1> switch_tunnel_mode_t;
const switch_tunnel_mode_t SWITCH_TUNNEL_MODE_PIPE = 0;
const switch_tunnel_mode_t SWITCH_TUNNEL_MODE_UNIFORM = 1;

typedef bit<4> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_INGRESS_TUNNEL_TYPE_NONE = 0;
const switch_tunnel_type_t SWITCH_INGRESS_TUNNEL_TYPE_VXLAN = 1;
const switch_tunnel_type_t SWITCH_INGRESS_TUNNEL_TYPE_IPINIP = 2;
const switch_tunnel_type_t SWITCH_INGRESS_TUNNEL_TYPE_NVGRE = 3;
const switch_tunnel_type_t SWITCH_INGRESS_TUNNEL_TYPE_MPLS = 4;
const switch_tunnel_type_t SWITCH_INGRESS_TUNNEL_TYPE_SRV6 = 5;
const switch_tunnel_type_t SWITCH_INGRESS_TUNNEL_TYPE_NVGRE_ST = 6;

const switch_tunnel_type_t SWITCH_EGRESS_TUNNEL_TYPE_NONE = 0;
const switch_tunnel_type_t SWITCH_EGRESS_TUNNEL_TYPE_IPV4_VXLAN = 1;
const switch_tunnel_type_t SWITCH_EGRESS_TUNNEL_TYPE_IPV6_VXLAN = 2;
const switch_tunnel_type_t SWITCH_EGRESS_TUNNEL_TYPE_IPV4_IPINIP = 3;
const switch_tunnel_type_t SWITCH_EGRESS_TUNNEL_TYPE_IPV6_IPINIP = 4;
const switch_tunnel_type_t SWITCH_EGRESS_TUNNEL_TYPE_IPV4_NVGRE = 5;
const switch_tunnel_type_t SWITCH_EGRESS_TUNNEL_TYPE_IPV6_NVGRE = 6;
const switch_tunnel_type_t SWITCH_EGRESS_TUNNEL_TYPE_MPLS = 7;
const switch_tunnel_type_t SWITCH_EGRESS_TUNNEL_TYPE_SRV6_ENCAP = 8;
const switch_tunnel_type_t SWITCH_EGRESS_TUNNEL_TYPE_SRV6_INSERT = 9;

enum switch_tunnel_term_mode_t { P2P, P2MP };
# 642 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
typedef bit<8> switch_tunnel_index_t;



typedef bit<13> switch_tunnel_ip_index_t;



typedef bit<16> switch_tunnel_nexthop_t;
typedef bit<24> switch_tunnel_vni_t;

struct switch_tunnel_metadata_t {
    switch_tunnel_type_t type;
    switch_tunnel_index_t index; // Egress only.
    switch_tunnel_ip_index_t dip_index;
    switch_tunnel_vni_t vni;
    switch_ifindex_t ifindex;
    switch_tunnel_mode_t qos_mode;
    switch_tunnel_mode_t ttl_mode;
    bit<8> encap_ttl;
    bit<8> encap_dscp;
    bit<16> hash;
    bool terminate;
    bit<8> nvgre_flow_id;
    bit<2> mpls_pop_count;
    bit<3> mpls_push_count;
    bit<8> mpls_encap_ttl;
    bit<3> mpls_encap_exp;
    bit<1> mpls_swap;
    bit<128> srh_next_sid;
    bit<8> srh_seg_left;
    bit<8> srh_next_hdr;
    bit<3> srv6_seg_len;
    bit<6> srh_hdr_len;
    bool remove_srh;
    bool pop_active_segment;
    bool srh_decap_forward;
}

struct switch_nvgre_value_set_t {
    bit<32> vsid_flowid;
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
# 712 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
typedef bit<6> switch_dtel_hw_id_t;
typedef bit<32> switch_dtel_switch_id_t;

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



    bit<32> timestamp;




    switch_mirror_session_t session_id;
    bit<32> hash;
    switch_dtel_report_type_t report_type;
    switch_port_padding_t _pad2;
    switch_port_t ingress_port;
    switch_port_padding_t _pad3;
    switch_port_t egress_port;



    bit<1> _pad4;

    switch_qid_t qid;
    bit<5> _pad5;
    bit<19> qdepth;



    bit<32> egress_timestamp;

}

header switch_dtel_drop_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    bit<32> timestamp;




    switch_mirror_session_t session_id;
    bit<32> hash;
    switch_dtel_report_type_t report_type;
    switch_port_padding_t _pad2;
    switch_port_t ingress_port;
    switch_port_padding_t _pad3;
    switch_port_t egress_port;



    bit<1> _pad4;

    switch_qid_t qid;
    switch_drop_reason_t drop_reason;
}

// Used for dtel truncate_only and ifa_clone mirror sessions
header switch_simple_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    switch_mirror_session_t session_id;
}

@flexible
struct switch_bridged_metadata_dtel_extension_t {
    switch_dtel_report_type_t report_type;
    switch_mirror_session_t session_id;
    bit<32> hash;
    switch_port_t egress_port;
}

// Source Flow Control related types (SFC) ------------------------------------------------

enum bit<2> LinkToType {
    Unknown = 0,
    Switch = 1,
    Server = 2
}

const bit<32> msb_set_32b = 32w0x80000000;


typedef bit<1> ping_pong_t;
typedef bit<32> const_t;






// Allow combinations of ingress pipe 9bit egress port + 7bit egress queue
typedef bit<16> sfc_ingress_queue_idx_t;
// This applies to: sfc_queue_idx_t, sfc_buffer_pool_idx_t
typedef bit<8> sfc_queue_idx_t;
//typedef bit<SFC_QUEUE_IDX_PAD_16BIT_BITS> sfc_queue_idx_pad_16bit_t;
typedef bit<2> sfc_buffer_pool_idx_t;
typedef bit<6> sfc_buffer_pool_idx_pad_8bit_t;

typedef bit<16> sfc_suppression_filter_idx_t;

typedef bit<16> buffer_memory_egress_t;
typedef bit<16> buffer_memory_ghost_t;
typedef bit<5> buffer_memory_pad_24bit_t;
typedef bit<11> tm_hw_queue_id_t;
typedef bit<2> pipe_id_t;
typedef bit<16> sfc_pause_duration_us_t;
typedef bit<3> sfc_queue_threshold_idx_t;

enum bit<3> SfcPacketType {
    Unset = 0,
    None = 1, // No SFC packet
    Data = 2, // Normal SFC data packet, SFC is enabled
    Trigger = 3, // SFC pause packet after mirroring, SFC is enabled
    Signal = 4, // SFC pause packet after SFC pause packet construction, SFC is enabled
    TcSignalEnabled = 5 // No SFC packet, but a packet on a SignalingEnabledTC
}
typedef bit<5> SfcPacketType_pad_8bit_t;

struct sfc_qd_threshold_register_t {
    bit<32> qdepth_drain_cells;
    bit<32> target_qdepth;
}

struct sfc_pause_epoch_register_t {
    bit<32> current_epoch_start;
    bit<32> bank_idx_changed;
}

struct sfc_ghost_threshold_debug_register_t {
    bit<32> first_value_over_threshold;
    bit<32> over_threshold_counter;
}

// Metadata for SFC used in ghost thread
struct sfc_ghost_metadata_t {
    sfc_ingress_queue_idx_t ingress_port_queue_idx;
    buffer_memory_ghost_t qdepth_threshold_remainder;
}

// Metadata for SFC used in ingress thread
struct switch_sfc_local_metadata_t {
    SfcPacketType type;
    // [1:1]: switch bank
    // [0:0]: bank idx
    bit<2> switch_bank_idx;
    MirrorId_t signaling_mirror_session_id;
    bool qlength_over_threshold;
    bit<16> suppression_hash_0;
    bit<16> suppression_hash_1;
    sfc_queue_idx_t queue_register_idx;

    buffer_memory_egress_t q_drain_length;
    bit<8> pause_dscp;
    // Calculate in egress
    sfc_pause_duration_us_t pause_duration_us;
    LinkToType link_to_type;
    bit<16> multiplier_second_part;
    bit<8> sfc_pause_packet_dscp;
}

@flexible
struct switch_bridged_metadata_sfc_extension_t {
    SfcPacketType type;
    sfc_queue_idx_t queue_register_idx;
}

// Metadata for SFC used in egress thread
// @flexible
// struct switch_sfc_egress_metadata_t {
//     // Pick up from bridged or bridge md
//     SfcPacketType               type;
//     sfc_queue_idx_t             queue_register_idx;
//     // Set in egress
//     buffer_memory_egress_t      q_drain_length;
//     bit<8>                      pause_dscp;
//     // Calculate in egress
//     sfc_pause_duration_us_t     pause_duration_us;
//     LinkToType                  link_to_type;
//     bit<16>                     multiplier_second_part;
//     bit<8>                      sfc_pause_packet_dscp;
//     // bit<16>                     ingress_port;
//     // bit<16>                     port_lag_index;
// }

header switch_sfc_pause_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    bit<32> timestamp;

    sfc_queue_idx_t queue_register_idx;
    switch_nexthop_t nexthop;
    bit<16> ingress_port;
    bit<16> port_lag_index;
}


//-----------------------------------------------------------------------------
// Other Metadata Definitions
//-----------------------------------------------------------------------------
// Flags
//XXX Force the fields that are XORd to NOT share containers.
@pa_container_size("ingress", "local_md.checks.same_if", 16)



@pa_mutually_exclusive("ingress", "lkp.arp_opcode", "lkp.ip_src_addr")
@pa_mutually_exclusive("ingress", "lkp.arp_opcode", "lkp.ip_dst_addr")
@pa_mutually_exclusive("ingress", "lkp.arp_opcode", "lkp.ipv6_flow_label")
@pa_mutually_exclusive("ingress", "lkp.arp_opcode", "lkp.ip_proto")
@pa_mutually_exclusive("ingress", "lkp.arp_opcode", "lkp.ip_ttl")
@pa_mutually_exclusive("ingress", "lkp.arp_opcode", "lkp.ip_tos")
# 1007 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
struct switch_flags_t {
    bool ipv4_checksum_err;
    bool inner_ipv4_checksum_err;
    bool inner2_ipv4_checksum_err;
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
    bool mpls_trap;
    bool srv6_trap;
    bool mlag_member;
    bool wred_drop;
    bool isolation_packet_drop;
    bool fib_lpm_miss;
    bool fib_drop;
    // Add more flags here.
}

//struct switch_egress_flags_t {
//    bool routed;
//    bool bypass_egress;
//    bool acl_deny;
//    bool mlag_member;
//    bool peer_link;
//    bool capture_ts;
//    bool port_meter_drop;
//    bool acl_meter_drop;
//    bool pfc_wd_drop;
//    bool isolation_packet_drop;
//
//    // Add more flags here.
//}
//

// Checks
struct switch_checks_t {
    switch_port_lag_index_t same_if;
    bool mrpf;
    bool urpf;
    switch_nat_zone_t same_zone_check;
    switch_bd_t same_bd;
    switch_mtu_t mtu;
    bool stp;
    // Add more checks here.
}

//struct switch_egress_checks_t {
//    switch_bd_t same_bd;
//    switch_mtu_t mtu;
//    bool stp;
//
//    // Add more checks here.
//}

// IP
struct switch_ip_metadata_t {
    bool unicast_enable;
    bool multicast_enable;
    bool multicast_snooping;
    // switch_urpf_mode_t urpf_mode;
}

struct switch_lookup_fields_t {
    switch_pkt_type_t pkt_type;

  //    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<16> mac_type;
    bit<3> pcp;

    // 1 for ARP request, 2 for ARP reply.
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
    bit<16> hash_l4_src_port;
    bit<16> hash_l4_dst_port;

    bool mpls_pkt;
    bit<1> mpls_router_alert_label;
    bit<20> mpls_lookup_label;

    switch_hostif_trap_t hostif_trap_id;
}

struct switch_hash_fields_t {
    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<16> mac_type;
    switch_ip_type_t ip_type;
    bit<8> ip_proto;
    bit<128> ip_src_addr;
    bit<128> ip_dst_addr;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;
    bit<20> ipv6_flow_label;
    bit<32> outer_ip_src_addr;
    bit<32> outer_ip_dst_addr;
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



    bit<32> timestamp;

    switch_tc_t tc;
    switch_qid_t qid;
    switch_pkt_color_t color;
    switch_vrf_t vrf;

    // Add more fields here.
}

@flexible
struct switch_bridged_metadata_acl_extension_t {

    bit<16> l4_src_port;
    bit<16> l4_dst_port;
    bit<8> tcp_flags;
# 1179 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
}

@flexible
struct switch_bridged_metadata_tunnel_extension_t {
//    switch_tunnel_index_t index;
    switch_tunnel_nexthop_t tunnel_nexthop;
# 1197 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
    bool terminate;
}


@pa_atomic("ingress", "hdr.bridged_md.base_qid")
@pa_container_size("ingress", "hdr.bridged_md.base_qid", 8)
@pa_container_size("ingress", "hdr.bridged_md.dtel_report_type", 8)
@pa_no_overlay("ingress", "hdr.bridged_md.base_qid")
/*
 CODE_HACK - The following hdr.bridged_md.__pad_* fields are meant to refer to
 the padding for hdr.bridged_md.base_qid, hdr.bridged_md.base_ingress_port, and
 hdr.bridged_md.dtel_egress_port. For deflected packets, these fields are
 copied directly into hdr.dtel_report by the parser. For bridged packets, the
 first two fields are copied by the parser into local_md fields, then if the
 packet is mirrored in order to generate a DTEL report, these local_md fields
 are copied by the deparser into mirror headers, which are then copied by the
 parser into hdr.dtel_report. If the pads are overlaid, resulting in non-zero
 values, then it would corrupt hdr.dtel_report.
*/
@pa_no_overlay("ingress", "hdr.bridged_md.__pad_0")
@pa_no_overlay("ingress", "hdr.bridged_md.__pad_1")
@pa_no_overlay("ingress", "hdr.bridged_md.__pad_2")
@pa_no_overlay("ingress", "hdr.bridged_md.__pad_3")
@pa_no_overlay("ingress", "hdr.bridged_md.__pad_4")
@pa_no_overlay("ingress", "hdr.bridged_md.__pad_5")
/*
 CODE_HACK - The following pragmas are required because the report fields
 are being overlaid with fields that are being later being modified in the
 MAU. The drop report and queue report are added in the egress parser.
 This doesn't really solve the problem completely. The below
 pragma's only help the drop report from not getting overlayed. The queue
 report is still vulnerable to be overlaid with other fields.
*/
@pa_no_overlay("egress", "hdr.dtel_report.ingress_port")
@pa_no_overlay("egress", "hdr.dtel_report.egress_port")
@pa_no_overlay("egress", "hdr.dtel_report.queue_id")
@pa_no_overlay("egress", "hdr.dtel_drop_report.drop_reason")
@pa_no_overlay("egress", "hdr.dtel_drop_report.reserved")
# 1244 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
@pa_no_overlay("egress", "hdr.dtel_switch_local_report.queue_occupancy")
# 1266 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.erspan_type2.index")
# 1286 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
@pa_mutually_exclusive("egress", "hdr.gre.proto", "hdr.udp.src_port")
@pa_mutually_exclusive("egress", "hdr.gre.proto", "hdr.udp.dst_port")
@pa_mutually_exclusive("egress", "hdr.gre.proto", "hdr.udp.length")
@pa_mutually_exclusive("egress", "hdr.gre.proto", "hdr.udp.checksum")
@pa_mutually_exclusive("egress", "hdr.gre.flags_version", "hdr.udp.src_port")
@pa_mutually_exclusive("egress", "hdr.gre.flags_version", "hdr.udp.dst_port")
@pa_mutually_exclusive("egress", "hdr.gre.flags_version", "hdr.udp.length")
@pa_mutually_exclusive("egress", "hdr.gre.flags_version", "hdr.udp.checksum")

@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.dtel.version")
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.dtel.next_proto")
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.dtel.hw_id")
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.dtel.d_q_f")
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.dtel.seq_number")
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.dtel.switch_id")
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.dtel.timestamp")
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.dtel_drop_report.drop_reason")
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.dtel_switch_local_report.pad3")
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.dtel_switch_local_report.queue_occupancy")
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.dtel_report.pad0")
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.dtel_report.pad1")
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.dtel_report.pad2")
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.dtel_report.queue_id")
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.dtel_report.ingress_port")
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.dtel_report.egress_port")

@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.dtel.version")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.dtel.next_proto")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.dtel.hw_id")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.dtel.d_q_f")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.dtel.seq_number")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.dtel.switch_id")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.dtel.timestamp")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.dtel_drop_report.drop_reason")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.dtel_switch_local_report.pad3")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.dtel_switch_local_report.queue_occupancy")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.dtel_report.pad0")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.dtel_report.pad1")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.dtel_report.pad2")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.dtel_report.queue_id")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.dtel_report.ingress_port")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.dtel_report.egress_port")

@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.dtel.version")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.dtel.next_proto")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.dtel.hw_id")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.dtel.d_q_f")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.dtel.seq_number")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.dtel.switch_id")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.dtel.timestamp")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.dtel_drop_report.drop_reason")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.dtel_switch_local_report.pad3")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.dtel_switch_local_report.queue_occupancy")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.dtel_report.pad0")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.dtel_report.pad1")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.dtel_report.pad2")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.dtel_report.queue_id")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.dtel_report.ingress_port")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.dtel_report.egress_port")

@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.dtel.version")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.dtel.next_proto")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.dtel.hw_id")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.dtel.d_q_f")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.dtel.seq_number")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.dtel.switch_id")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.dtel.timestamp")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.dtel_drop_report.drop_reason")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.dtel_switch_local_report.pad3")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.dtel_switch_local_report.queue_occupancy")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.dtel_report.pad0")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.dtel_report.pad1")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.dtel_report.pad2")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.dtel_report.queue_id")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.dtel_report.ingress_port")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.dtel_report.egress_port")
# 1434 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
typedef bit<8> switch_bridge_type_t;

header switch_bridged_metadata_h {
    switch_pkt_src_t src;
    switch_bridge_type_t type;
    switch_bridged_metadata_t base;


    switch_bridged_metadata_acl_extension_t acl;





    switch_bridged_metadata_dtel_extension_t dtel;


    switch_bridged_metadata_sfc_extension_t sfc;

}

struct switch_port_metadata_t {
    switch_port_lag_index_t port_lag_index;
    switch_ig_port_lag_label_t port_lag_label;



}

// consistent hash - calculation of v6 high/low ip is
// multi-stage process. So this variable tracks the
// v6 ip sequence for crc hash - must be one of the below
//   - none
//   - low-ip is sip, high-ip is dip
//   - low-ip is dip, high-ip is sip
typedef bit<2> switch_cons_hash_ip_seq_t;
const switch_cons_hash_ip_seq_t SWITCH_CONS_HASH_IP_SEQ_NONE = 0;
const switch_cons_hash_ip_seq_t SWITCH_CONS_HASH_IP_SEQ_SIPDIP = 1;
const switch_cons_hash_ip_seq_t SWITCH_CONS_HASH_IP_SEQ_DIPSIP = 2;

@pa_auto_init_metadata

@pa_container_size("ingress", "local_md.mirror.src", 8)
@pa_container_size("ingress", "local_md.mirror.type", 8)
@pa_container_size("ingress", "smac_src_move", 16)
@pa_alias("ingress", "local_md.egress_port", "ig_intr_md_for_tm.ucast_egress_port")

@pa_alias("ingress", "local_md.multicast.id", "ig_intr_md_for_tm.mcast_grp_b")

@pa_alias("ingress", "local_md.qos.qid", "ig_intr_md_for_tm.qid")
@pa_alias("ingress", "local_md.qos.icos", "ig_intr_md_for_tm.ingress_cos")
@pa_alias("ingress", "ig_intr_md_for_dprsr.mirror_type", "local_md.mirror.type")
@pa_container_size("ingress", "local_md.egress_port_lag_index", 16)




@pa_container_size("egress", "local_md.mirror.src", 8)
@pa_container_size("egress", "local_md.mirror.type", 8)

@pa_container_size("egress", "hdr.dtel_drop_report.drop_reason", 8)


// Ingress/Egress metadata
struct switch_local_metadata_t {
    switch_port_t ingress_port; /* ingress port */
    switch_port_t egress_port; /* egress port */
    switch_port_lag_index_t ingress_port_lag_index; /* ingress port/lag index */
    switch_port_lag_index_t egress_port_lag_index; /* egress port/lag index */
    switch_bd_t bd;
    switch_vrf_t vrf;
    switch_nexthop_t nexthop;
    switch_tunnel_nexthop_t tunnel_nexthop;
    switch_nexthop_t acl_nexthop;
    bool acl_port_redirect;
    switch_nexthop_t unused_nexthop;



    bit<32> timestamp;

    switch_hash_t hash;
    switch_hash_t lag_hash;

    switch_flags_t flags;
    switch_checks_t checks;
    switch_ingress_bypass_t bypass;

    switch_ip_metadata_t ipv4;
    switch_ip_metadata_t ipv6;
    switch_ig_port_lag_label_t ingress_port_lag_label;
    switch_bd_label_t bd_label;
    switch_l4_port_label_t l4_src_port_label;
    switch_l4_port_label_t l4_dst_port_label;

    switch_drop_reason_t l2_drop_reason;
    switch_drop_reason_t drop_reason;
    switch_cpu_reason_t cpu_reason;

    switch_lookup_fields_t lkp;
    switch_hash_fields_t hash_fields;
    switch_multicast_metadata_t multicast;
    switch_stp_metadata_t stp;
    switch_qos_metadata_t qos;
    switch_sflow_metadata_t sflow;
    switch_tunnel_metadata_t tunnel;
    switch_learning_metadata_t learning;
    switch_mirror_metadata_t mirror;
    switch_dtel_metadata_t dtel;

    //switch_sfc_ingress_metadata_t sfc;
    switch_sfc_local_metadata_t sfc;

    mac_addr_t same_mac;

    switch_user_metadata_t user_metadata;




    bit<10> partition_key;
    bit<12> partition_index;
    switch_fib_label_t fib_label;

    switch_cons_hash_ip_seq_t cons_hash_v6_ip_seq;
    switch_pkt_src_t pkt_src;
    switch_pkt_length_t pkt_length;
    switch_pkt_type_t pkt_type;




    bit<32> egress_timestamp;
    bit<32> ingress_timestamp;

    switch_eg_port_lag_label_t egress_port_lag_label;
    switch_nexthop_type_t nexthop_type;
    bool inner_ipv4_checksum_update_en;




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

    pfc_h pfc;

    ipv4_h ipv4;
    ipv4_option_h ipv4_option;
    ipv6_h ipv6;
    arp_h arp;
    ipv6_srh_h srh_base;
    ipv6_segment_h[2] srh_seg_list;
    udp_h udp;
    icmp_h icmp;
    igmp_h igmp;
    tcp_h tcp;
# 1619 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
    dtel_report_v05_h dtel;
    dtel_report_base_h dtel_report;
    dtel_switch_local_report_h dtel_switch_local_report;
    dtel_drop_report_h dtel_drop_report;

    rocev2_bth_h rocev2_bth;
    gtpu_h gtp;

    sfc_pause_h sfc_pause;
    padding_112b_h pad_112b;
    padding_96b_h pad_96b;

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
    ipv4_h inner2_ipv4;
    ipv6_h inner2_ipv6;
    udp_h inner2_udp;
    tcp_h inner2_tcp;
    icmp_h inner2_icmp;
}
# 178 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/util.p4" 1
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

# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4" 1
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
# 24 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/util.p4" 2

// Bridged metadata fields for Egress pipeline.
action add_bridged_md(
        inout switch_bridged_metadata_h bridged_md, in switch_local_metadata_t local_md) {
    bridged_md.setValid();
    bridged_md.src = SWITCH_PKT_SRC_BRIDGED;
    bridged_md.base.ingress_port = local_md.ingress_port;
    bridged_md.base.ingress_port_lag_index = local_md.ingress_port_lag_index;
    bridged_md.base.ingress_bd = local_md.bd;
    bridged_md.base.nexthop = local_md.nexthop;
    bridged_md.base.pkt_type = local_md.lkp.pkt_type;
    bridged_md.base.routed = local_md.flags.routed;
    bridged_md.base.bypass_egress = local_md.flags.bypass_egress;






    bridged_md.base.cpu_reason = local_md.cpu_reason;
    bridged_md.base.timestamp = local_md.timestamp;
    bridged_md.base.tc = local_md.qos.tc;
    bridged_md.base.qid = local_md.qos.qid;
    bridged_md.base.color = local_md.qos.color;
    bridged_md.base.vrf = local_md.vrf;


    bridged_md.acl.l4_src_port = local_md.lkp.l4_src_port;
    bridged_md.acl.l4_dst_port = local_md.lkp.l4_dst_port;







    bridged_md.acl.tcp_flags = local_md.lkp.tcp_flags;
# 83 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/util.p4"
    bridged_md.dtel.report_type = local_md.dtel.report_type;
    bridged_md.dtel.session_id = local_md.dtel.session_id;
    bridged_md.dtel.hash = local_md.lag_hash;
    bridged_md.dtel.egress_port = local_md.egress_port;


    bridged_md.sfc = {local_md.sfc.type,
                      local_md.sfc.queue_register_idx};

}

action set_ig_intr_md(in switch_local_metadata_t local_md,
                      inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                      inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    ig_intr_md_for_tm.mcast_grp_b = local_md.multicast.id;
// Set PRE hash values
    ig_intr_md_for_tm.level2_mcast_hash = local_md.lag_hash[28:16];
    ig_intr_md_for_tm.rid = local_md.bd;


    ig_intr_md_for_tm.qid = local_md.qos.qid;
    ig_intr_md_for_tm.ingress_cos = local_md.qos.icos;

}

control SetEgIntrMd(in switch_local_metadata_t local_md,
                    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {




        if (local_md.mirror.type != 0) {



            eg_intr_md_for_dprsr.mirror_type = (bit<4>) local_md.mirror.type;
            eg_intr_md_for_dprsr.mirror_io_select = 1;

        }

    }
}
# 179 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/hash.p4" 1
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

# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4" 1
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
# 24 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/hash.p4" 2

// Flow hash calculation.
# 111 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/hash.p4"
// If fragments, then reset hash l4 port values to zero
// For non fragments, hash l4 ports will be init to l4 port values
control EnableFragHash(inout switch_lookup_fields_t lkp) {
    apply {
        if (lkp.ip_frag != SWITCH_IP_FRAG_NON_FRAG) {
            lkp.hash_l4_dst_port = 0;
            lkp.hash_l4_src_port = 0;
        }
    }
}

control Ipv4Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv4_hash;
    bit<32> ip_src_addr = lkp.ip_src_addr[95:64];
    bit<32> ip_dst_addr = lkp.ip_dst_addr[95:64];
    bit<8> ip_proto = lkp.ip_proto;
    bit<16> l4_dst_port = lkp.hash_l4_dst_port;
    bit<16> l4_src_port = lkp.hash_l4_src_port;

    apply {
        hash [31:0] = ipv4_hash.get({ip_src_addr,
                                     ip_dst_addr,
                                     ip_proto,
                                     l4_dst_port,
                                     l4_src_port});
    }
}

control Ipv6Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_hash;
    bit<128> ip_src_addr = lkp.ip_src_addr;
    bit<128> ip_dst_addr = lkp.ip_dst_addr;
    bit<8> ip_proto = lkp.ip_proto;
    bit<16> l4_dst_port = lkp.hash_l4_dst_port;
    bit<16> l4_src_port = lkp.hash_l4_src_port;
    bit<20> ipv6_flow_label = lkp.ipv6_flow_label;

    apply {
        hash[31:0] = ipv6_hash.get({

                                    ipv6_flow_label,

                                    ip_src_addr,
                                    ip_dst_addr,
                                    ip_proto,
                                    l4_dst_port,
                                    l4_src_port});
    }
}
control NonIpHash(in switch_header_t hdr, in switch_local_metadata_t local_md, out switch_hash_t hash) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;
    mac_addr_t mac_dst_addr = hdr.ethernet.dst_addr;
    mac_addr_t mac_src_addr = hdr.ethernet.src_addr;
    bit<16> mac_type = hdr.ethernet.ether_type;
    switch_port_t port = local_md.ingress_port;

    apply {
        hash [31:0] = non_ip_hash.get({port,
                                       mac_type,
                                       mac_src_addr,
                                       mac_dst_addr});
    }
}
control Lagv4Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) lag_hash;
    bit<32> ip_src_addr = lkp.ip_src_addr[95:64];
    bit<32> ip_dst_addr = lkp.ip_dst_addr[95:64];
    bit<8> ip_proto = lkp.ip_proto;
    bit<16> l4_dst_port = lkp.hash_l4_dst_port;
    bit<16> l4_src_port = lkp.hash_l4_src_port;

    apply {
        hash[31:0] = lag_hash.get({ip_src_addr,
                                   ip_dst_addr,
                                   ip_proto,
                                   l4_dst_port,
                                   l4_src_port});
    }
}
control Lagv6Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) lag_hash;
    bit<128> ip_src_addr = lkp.ip_src_addr;
    bit<128> ip_dst_addr = lkp.ip_dst_addr;
    bit<8> ip_proto = lkp.ip_proto;
    bit<16> l4_dst_port = lkp.hash_l4_dst_port;
    bit<16> l4_src_port = lkp.hash_l4_src_port;
    bit<20> ipv6_flow_label = lkp.ipv6_flow_label;

    apply {
        hash[31:0] = lag_hash.get({

                                   ipv6_flow_label,

                                   ip_src_addr,
                                   ip_dst_addr,
                                   ip_proto,
                                   l4_dst_port,
                                   l4_src_port});
    }
}
# 223 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/hash.p4"
/******************************************************************************
// V4ConsistentHash generic control block
// This block compares v4 sip/dip & calculates low/high v4 IP
// Using the low/high v4-IP, it then calculates/returns V4 consistent hash
******************************************************************************/
control V4ConsistentHash(in bit<32> sip, in bit<32> dip,
                         in bit<16> low_l4_port, in bit<16> high_l4_port,
                         in bit<8> protocol,
                         inout switch_hash_t hash) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv4_inner_hash;
    bit<32> high_ip;
    bit<32> low_ip;

    action step_v4() {
        high_ip = max(sip, dip);
        low_ip = min(sip, dip);
    }

    action v4_calc_hash() {
        hash[31:0] = ipv4_inner_hash.get({low_ip, high_ip,
                                          protocol,
                                          low_l4_port, high_l4_port});
    }

    apply {
        step_v4();
        v4_calc_hash();
    }
}

/**********************************************************************************************
// V6ConsistentHash64bIpSeq generic control block - This compares only higher 64 bits
// of V6 sip & dip, returns 2-bit v6 ip sequence tracker i.e. SWITCH_CONS_HASH_IP_SEQ_<value>
// v6 ip seq for crc hash calc tracker - cons_hash_v6_ip_seq will have below values:
//   i.e. none - SWITCH_CONS_HASH_IP_SEQ_NONE
//   i.e. low-ip is sip, high-ip is dip - SWITCH_CONS_HASH_IP_SEQ_SIPDIP
//   i.e. low-ip is dip, high-ip is sip - SWITCH_CONS_HASH_IP_SEQ_DIPSIP
//
// Below are the steps in this block
//   step 0 - Assume hash seq is SWITCH_CONS_HASH_IP_SEQ_SIPDIP - set the tracker value
//   step 1:
//      compare 32 bits starting from left to right of both src-ip, dst-ip
//      If 32 bit value of src-ip, dst-ip at the respective bit is not equal, apply step 2
//
//   step 2: working on the 32 bit value of both IP at respective position
//      Get high/max 32 bit value between src-ip, dst-ip
//      If high 32 bit value is same as src-ip 32 bit value at respective position
//        --> set value to SWITCH_CONS_HASH_IP_SEQ_DIPSIP
**********************************************************************************************/
control V6ConsistentHash64bIpSeq(in bit<64> sip, in bit<64> dip, inout switch_cons_hash_ip_seq_t ip_seq) {
    bit<32> high_63_32_ip;
    bit<32> src_63_32_ip;
    bit<32> high_31_0_ip;
    bit<32> src_31_0_ip;

    action step_63_32_v6() {
        high_63_32_ip = max(sip[63:32], dip[63:32]);
        src_63_32_ip = sip[63:32];
    }

    action step_31_0_v6() {
        high_31_0_ip = max(sip[31:0], dip[31:0]);
        src_31_0_ip = sip[31:0];
    }

    apply {
        // initialize to 1 i.e low-ip is sip, high-ip is dip
        ip_seq = SWITCH_CONS_HASH_IP_SEQ_SIPDIP;

        step_63_32_v6();
        step_31_0_v6();

        if (sip[63:32] != dip[63:32]) {
            if (high_63_32_ip == src_63_32_ip) {
                ip_seq = SWITCH_CONS_HASH_IP_SEQ_DIPSIP;
            }
        }
        else if (sip[31:0] != dip[31:0]) {
            if (high_31_0_ip == src_31_0_ip) {
                ip_seq = SWITCH_CONS_HASH_IP_SEQ_DIPSIP;
            }
        } else {
            // set 0 if we still have to compare further
            // or if sip & dip are equal
            ip_seq = SWITCH_CONS_HASH_IP_SEQ_NONE;
        }
    }
}

/***************************************************************************************
// V6ConsistentHash generic control block - call this after V6ConsistentHash64bIpSeq()
// Logic can be continuation from the earlier control block V6ConsistentHash64bIpSeq
// This block uses the 2 bit ip sequece tracker from V6ConsistentHash64bIpSeq &
// continues to compare lower 64 bits of v6 sip/dip [if req] to calculate low/high v6 IP
// Using the low/high v6 IP, it then calculates/returns the consistet hash
****************************************************************************************/
control V6ConsistentHash(in bit<128> sip, in bit<128> dip,
                         in switch_cons_hash_ip_seq_t ip_seq,
                         in bit<16> low_l4_port, in bit<16> high_l4_port,
                         in bit<8> protocol,
                         inout switch_hash_t hash) {
    bit<32> high_31_0_ip;
    bit<32> low_31_0_ip;
    bit<32> src_31_0_ip;
    Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_inner_hash_1;
    Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_inner_hash_2;
    bit<32> high_63_32_ip;
    bit<32> src_63_32_ip;

    action step_63_32_v6() {
        high_63_32_ip = max(sip[63:32], dip[63:32]);
        src_63_32_ip = sip[63:32];
    }

    action step_31_0_v6() {
        high_31_0_ip = max(sip[31:0], dip[31:0]);
        src_31_0_ip = sip[31:0];
    }

    // low ip - sip, high ip - dip i.e. SWITCH_CONS_HASH_IP_SEQ_SIPDIP
    action v6_calc_hash_sip_dip() {
        hash[31:0] = ipv6_inner_hash_1.get({sip, dip,
                                            protocol,
                                            low_l4_port, high_l4_port});
    }

    // low ip - dip, high ip - sip i.e. SWITCH_CONS_HASH_IP_SEQ_DIPSIP
    action v6_calc_hash_dip_sip() {
        hash[31:0] = ipv6_inner_hash_2.get({dip, sip,
                                            protocol,
                                            low_l4_port, high_l4_port});
    }

    apply {
        // steps to calculate low/high v6-ip i.e. step 1, step 2
        // Step 1 - Act on the tracker value from the earlier control block
        // if set, based on the comparison of higher 64 bits of sip, dip
        if (ip_seq == SWITCH_CONS_HASH_IP_SEQ_SIPDIP) {
            v6_calc_hash_sip_dip();
        } else if (ip_seq == SWITCH_CONS_HASH_IP_SEQ_DIPSIP) {
            v6_calc_hash_dip_sip();
        // step 2 - else continue comparing the lower 64 bits
        } else {
            step_63_32_v6();
            step_31_0_v6();

            if (sip[63:32] != dip[63:32]) {
                if (high_63_32_ip == src_63_32_ip) {
                    v6_calc_hash_dip_sip();
                } else {
                    v6_calc_hash_sip_dip();
                }
            } else if (high_31_0_ip == src_31_0_ip) {
                v6_calc_hash_dip_sip();
            } else {
                v6_calc_hash_sip_dip();
            }
        }
    }
}

/**********************************************************************************************
// Msft vxlan/nvgre/nvgre-st consistent hashing for tunnel
// If inner ip packet exists, always calculate inner ip hash

// Solution 1 - crc32 consistent hash [low-ip, high-ip, protocol, l4_src_port, l4_tgt_port]
// comparing & calculating low/high v4-ip, low/high l4-port involves not many steps
// But steps to compare/calculate low/high v6-ip [128 bits] involves multi-stage
//
// Stage 1 - Below are the steps for this stage
//
//  1) StartConsistentInnerHash() calls V6ConsistentHash64bIpSeq() if inner pkt is V6
//     ---> V6ConsistentHash64bIpSeq block compares only higher 64 bits of V6 sip & dip,
//           & returns 2-bit v6 ip sequence tracker i.e. SWITCH_CONS_HASH_IP_SEQ_<value>
//
//  2) Then ConsistentInnerHash() compares lower 64 bits for V6 if req & calculates hash
//     ---> For V6 hash, will invoke V6ConsistentHash block. This block uses the 2 bit ip
//          sequece tracker & also compares lower 64 bits if req
//     ---> For V4 hash, will invoke V4ConsistentHash block
//     ---> For nvgre-st, currently using only the lower 32 bit IP to calc hash
//          Running into fitting issues by using V4ConsistentHash block, so
//          calculating the hash directly within this block for now
//
// Multi-stage because  the entire logic wasnt fitting in one single control block
*********************************************************************************************/
control StartConsistentInnerHash(in switch_header_t hd, inout switch_local_metadata_t ig_m) {
    V6ConsistentHash64bIpSeq() compute_v6_cons_hash_64bit_ipseq;
    apply {
        // For nvgre-st, using only lower 32 bits for hash calculation for now
        if (hd.inner_ipv6.isValid() && ig_m.tunnel.type != SWITCH_INGRESS_TUNNEL_TYPE_NVGRE_ST) {
            compute_v6_cons_hash_64bit_ipseq.apply(hd.inner_ipv6.src_addr[127:64],
                                                   hd.inner_ipv6.dst_addr[127:64],
                                                   ig_m.cons_hash_v6_ip_seq);
        }
    }
}

/******************************************************************************************
// Stage 2 - This Logic continuation from the above control block StartConsistentInnerHash
// Below are the steps for this stage
//   1) continues to compare the lower 64 bits of the V6 to figure out low/high v6-ip
//   2) has logic to get low/high l4-port
//   3) has logic to get low/high v4-ip
//   4) calculates consistent crc hash for both inner v6/v4 packet

// Multi-stage because  the entire logic wasnt fitting in one single control block
******************************************************************************************/
control ConsistentInnerHash(in switch_header_t hd, inout switch_local_metadata_t ig_m) {
    bit<32> high_31_0_ip;
    bit<32> low_31_0_ip;
    Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_inner_hash;

    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) l4_tcp_src_p_hash;
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) l4_udp_src_p_hash;
    bit<16> l4_src_port; // Because src_port uses 2 8-bit containers
    bit<16> low_l4_port = 0;
    bit<16> high_l4_port = 0;

    // cant perform max/min operations since src_port uses 2 8-bit containers
    // so moving the src_port value to single 16 bit container
    action step_tcp_src_port() {
        l4_src_port = l4_tcp_src_p_hash.get({16w0 +++ hd.inner_tcp.src_port});
    }

    // cant perform max/min operations since src_port uses 2 8-bit containers
    // so moving the src_port value to single 16 bit container
    action step_udp_src_port() {
        l4_src_port = l4_udp_src_p_hash.get({16w0 +++ hd.inner_udp.src_port});
    }

    action step_tcp_l4_port() {
        high_l4_port = (bit<16>)max(l4_src_port, hd.inner_tcp.dst_port);
        low_l4_port = (bit<16>)min(l4_src_port, hd.inner_tcp.dst_port);
    }

    action step_udp_l4_port() {
        high_l4_port = (bit<16>)max(l4_src_port, hd.inner_udp.dst_port);
        low_l4_port = (bit<16>)min(l4_src_port, hd.inner_udp.dst_port);
    }

    action step_31_0_v6() {
        high_31_0_ip = max(hd.inner_ipv6.src_addr[31:0], hd.inner_ipv6.dst_addr[31:0]);
        low_31_0_ip = min(hd.inner_ipv6.src_addr[31:0], hd.inner_ipv6.dst_addr[31:0]);
    }

    action v6_calc_31_0_hash() {
        ig_m.hash[31:0] = ipv6_inner_hash.get({low_31_0_ip, high_31_0_ip,
                                              hd.inner_ipv6.next_hdr,
                                              low_l4_port, high_l4_port});
    }

    V6ConsistentHash() compute_v6_cons_hash;
    V4ConsistentHash() compute_v4_cons_hash;
    apply {
        // steps to calculate low/high l4-port
        if (hd.inner_udp.isValid()) {
            step_udp_src_port();
            step_udp_l4_port();
        } else if (hd.inner_tcp.isValid()) {
            step_tcp_src_port();
            step_tcp_l4_port();
        }

        if (hd.inner_ipv6.isValid()) {

            if (ig_m.tunnel.type != SWITCH_INGRESS_TUNNEL_TYPE_NVGRE_ST) {
                compute_v6_cons_hash.apply(hd.inner_ipv6.src_addr,
                                           hd.inner_ipv6.dst_addr,
                                           ig_m.cons_hash_v6_ip_seq,
                                           low_l4_port, high_l4_port,
                                           hd.inner_ipv6.next_hdr,
                                           ig_m.hash);
            } else {
                // Running into fitting issues by using V4ConsistentHash for this

                // For nvgre-st
                // currently using only lower 32 bits of v6 for hash calculation
                step_31_0_v6();
                v6_calc_31_0_hash();
            }
        } else if (hd.inner_ipv4.isValid()) {
            compute_v4_cons_hash.apply(hd.inner_ipv4.src_addr,
                                       hd.inner_ipv4.dst_addr,
                                       low_l4_port, high_l4_port,
                                       hd.inner_ipv4.protocol,
                                       ig_m.hash);
        }
    }
}

//***************************************************************************
//
// Vxlan packet hash calculated with inner L3 headers + Vxlan Source Port
//
//***************************************************************************

control InnerDtelv4Hash(in switch_header_t hdr,
                        in switch_local_metadata_t local_md, out switch_hash_t hash) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) lag_hash;
    bit<32> ip_src_addr = hdr.inner_ipv4.src_addr;
    bit<32> ip_dst_addr = hdr.inner_ipv4.dst_addr;
    bit<8> ip_proto = hdr.inner_ipv4.protocol;
    bit<16> l4_src_port = hdr.udp.src_port; // Entropy field from vxlan header
//    bit<16> l4_dst_port = hdr.inner_tcp.dst_port;
//    bit<16> l4_src_port = hdr.inner_tcp.src_port;

    apply {
        hash [31:0] = lag_hash.get({ip_src_addr,
                                     ip_dst_addr,
                                     ip_proto,
//                                     l4_dst_port,
                                     l4_src_port});
    }
}

control InnerDtelv6Hash(in switch_header_t hdr,
                        in switch_local_metadata_t local_md, out switch_hash_t hash) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) lag_hash;
    bit<128> ip_src_addr = hdr.ipv6.src_addr;
    bit<128> ip_dst_addr = hdr.ipv6.dst_addr;
    bit<8> ip_proto = hdr.ipv6.next_hdr;
    bit<16> l4_src_port = hdr.udp.src_port; // Entropy field from vxlan header
//    bit<16> l4_dst_port = hdr.inner_tcp.dst_port;
//    bit<16> l4_src_port = hdr.inner_tcp.src_port;
    bit<20> ipv6_flow_label = hdr.inner_ipv6.flow_label;

    apply {
        hash [31:0] = lag_hash.get({

                                     ipv6_flow_label,

                                     ip_src_addr,
                                     ip_dst_addr,
                                     ip_proto,
//                                     l4_dst_port,
                                     l4_src_port});
    }
}
# 180 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/l3.p4" 1
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

# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4" 1
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
// Common Ingress ACL match keys and Actions
//-----------------------------------------------------------------------------
# 84 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
//-----------------------------------------------------------------------------
// Common Egress ACL match keys and Actions
//-----------------------------------------------------------------------------
# 127 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
//-----------------------------------------------------------------------------
// Common Ingress ACL actions.
//-----------------------------------------------------------------------------
# 190 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
// fib_lpm_miss reset in nexthop.p4 for TF2
# 216 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
// Common Egress ACL actions.
//-----------------------------------------------------------------------------
# 248 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
//-----------------------------------------------------------------------------
// Pre Ingress ACL
//-----------------------------------------------------------------------------
control PreIngressAcl(in switch_header_t hdr, inout switch_local_metadata_t local_md)(
        switch_uint32_t table_size=512) {

    bool is_acl_enabled;
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action set_acl_status(bool enabled) {
        is_acl_enabled = enabled;
    }

    table device_to_acl {
        actions = {
            set_acl_status;
        }
        default_action = set_acl_status(false);
        size = 1;
    }

    // cannot use INGRESS_ACL_ACTIONS above to avoid dependencies
    action no_action() {
        stats.count();
    }
    action deny() {
        local_md.flags.acl_deny = true;
        stats.count();
    }
    action set_vrf(switch_vrf_t vrf) {
        local_md.vrf = vrf;
        stats.count();
    }

    table acl {
        key = {
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
            local_md.lkp.mac_type : ternary;
            local_md.lkp.ip_src_addr : ternary;
            local_md.lkp.ip_dst_addr : ternary;
            local_md.lkp.ip_tos : ternary;
        }

        actions = {
            set_vrf;
            deny;
            no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        device_to_acl.apply();
        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0) && is_acl_enabled == true) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Ingress Shared IP ACL
//-----------------------------------------------------------------------------
control IngressIpAcl(inout switch_local_metadata_t local_md,
                     out switch_nexthop_t acl_nexthop)(
        switch_uint32_t table_size=512) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() { stats.count(); } action set_tc(switch_tc_t tc) { local_md.qos.tc = tc; stats.count(); } action set_color(switch_pkt_color_t color) { local_md.qos.color = color; stats.count(); } action set_meter(switch_meter_index_t index) { local_md.qos.acl_meter_index = index; stats.count(); } action set_user_defined_trap(switch_hostif_trap_t trap_id) { local_md.lkp.hostif_trap_id = trap_id; stats.count(); } action deny() { local_md.flags.acl_deny = true; stats.count(); } action permit(switch_user_metadata_t user_metadata) { local_md.flags.acl_deny = false; local_md.user_metadata = user_metadata; stats.count(); } action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) { local_md.flags.acl_deny = false; local_md.egress_port_lag_index = egress_port_lag_index; local_md.acl_port_redirect = true; local_md.user_metadata = user_metadata; stats.count(); } action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { local_md.mirror.type = 1; local_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS; local_md.mirror.session_id = session_id; local_md.mirror.meter_index = meter_index; stats.count(); } action set_dtel_report_type(switch_dtel_report_type_t type) { local_md.dtel.report_type = local_md.dtel.report_type | type; stats.count(); }
    action redirect_nexthop(switch_user_metadata_t user_metadata, switch_nexthop_t nexthop_index) { acl_nexthop = nexthop_index; local_md.user_metadata = user_metadata; stats.count(); }

    table acl {
        key = {
            local_md.lkp.ip_src_addr : ternary; local_md.lkp.ip_dst_addr : ternary; local_md.lkp.ip_proto : ternary; local_md.lkp.ip_tos : ternary; local_md.lkp.l4_src_port : ternary; local_md.lkp.l4_dst_port : ternary; local_md.lkp.ip_ttl : ternary; local_md.lkp.ip_frag : ternary; local_md.lkp.tcp_flags : ternary; local_md.l4_src_port_label : ternary; local_md.l4_dst_port_label : ternary;
# 336 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
            local_md.ingress_port_lag_label : ternary;


            local_md.bd_label : ternary;



        }

        actions = {
            deny;
            permit;






            mirror;
# 363 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
            set_user_defined_trap;
            no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Ingress Inner IPv4 ACL
//-----------------------------------------------------------------------------
control IngressInnerIpv4Acl(in switch_header_t hdr,
                     inout switch_local_metadata_t local_md)(
        switch_uint32_t table_size=512) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action set_dtel_report_type(switch_dtel_report_type_t type) {
        local_md.dtel.report_type = local_md.dtel.report_type | type;
        stats.count();
    }

    action no_action() {
        stats.count();
    }

    table acl {
        key = {
            hdr.inner_ipv4.src_addr : ternary; hdr.inner_ipv4.dst_addr : ternary; hdr.inner_ipv4.protocol : ternary; hdr.inner_ipv4.diffserv : ternary; hdr.inner_tcp.src_port : ternary; hdr.inner_tcp.dst_port : ternary; hdr.inner_udp.src_port : ternary; hdr.inner_udp.dst_port : ternary; hdr.inner_ipv4.ttl : ternary; hdr.inner_tcp.flags : ternary;
            local_md.ingress_port_lag_index : ternary;
        }

        actions = {
            set_dtel_report_type;
            no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Ingress Inner IPv6 ACL
//-----------------------------------------------------------------------------
control IngressInnerIpv6Acl(in switch_header_t hdr,
                     inout switch_local_metadata_t local_md)(
        switch_uint32_t table_size=512) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action set_dtel_report_type(switch_dtel_report_type_t type) {
        local_md.dtel.report_type = local_md.dtel.report_type | type;
        stats.count();
    }

    action no_action() {
        stats.count();
    }

    table acl {
        key = {
            hdr.inner_ipv6.src_addr : ternary; hdr.inner_ipv6.dst_addr : ternary; hdr.inner_ipv6.next_hdr : ternary; hdr.inner_ipv6.traffic_class : ternary; hdr.inner_tcp.src_port : ternary; hdr.inner_tcp.dst_port : ternary; hdr.inner_udp.src_port : ternary; hdr.inner_udp.dst_port : ternary; hdr.inner_ipv6.hop_limit : ternary; hdr.inner_tcp.flags : ternary;
            local_md.ingress_port_lag_index : ternary;
        }

        actions = {
            set_dtel_report_type;
            no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Ingress IPv4 ACL
//-----------------------------------------------------------------------------
control IngressIpv4Acl(inout switch_local_metadata_t local_md,
                     out switch_nexthop_t acl_nexthop)(
        switch_uint32_t table_size=512) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() { stats.count(); } action set_tc(switch_tc_t tc) { local_md.qos.tc = tc; stats.count(); } action set_color(switch_pkt_color_t color) { local_md.qos.color = color; stats.count(); } action set_meter(switch_meter_index_t index) { local_md.qos.acl_meter_index = index; stats.count(); } action set_user_defined_trap(switch_hostif_trap_t trap_id) { local_md.lkp.hostif_trap_id = trap_id; stats.count(); } action deny() { local_md.flags.acl_deny = true; stats.count(); } action permit(switch_user_metadata_t user_metadata) { local_md.flags.acl_deny = false; local_md.user_metadata = user_metadata; stats.count(); } action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) { local_md.flags.acl_deny = false; local_md.egress_port_lag_index = egress_port_lag_index; local_md.acl_port_redirect = true; local_md.user_metadata = user_metadata; stats.count(); } action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { local_md.mirror.type = 1; local_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS; local_md.mirror.session_id = session_id; local_md.mirror.meter_index = meter_index; stats.count(); } action set_dtel_report_type(switch_dtel_report_type_t type) { local_md.dtel.report_type = local_md.dtel.report_type | type; stats.count(); }
    action redirect_nexthop(switch_user_metadata_t user_metadata, switch_nexthop_t nexthop_index) { acl_nexthop = nexthop_index; local_md.user_metadata = user_metadata; stats.count(); }



    table acl {
        key = {
            local_md.lkp.ip_src_addr[95:64] : ternary; local_md.lkp.ip_dst_addr[95:64] : ternary; local_md.lkp.ip_proto : ternary; local_md.lkp.ip_tos : ternary; local_md.lkp.l4_src_port : ternary; local_md.lkp.l4_dst_port : ternary; local_md.lkp.ip_ttl : ternary; local_md.lkp.ip_frag : ternary; local_md.lkp.tcp_flags : ternary; local_md.l4_src_port_label : ternary; local_md.l4_dst_port_label : ternary;
# 488 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
            local_md.ingress_port_lag_label : ternary;


            local_md.bd_label : ternary;



        }

        actions = {
            deny;
            permit;
# 509 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
            mirror;
# 518 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
            set_user_defined_trap;
            no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Ingress IPv6 ACL
//-----------------------------------------------------------------------------
control IngressIpv6Acl(inout switch_local_metadata_t local_md,
                     out switch_nexthop_t acl_nexthop)(
                       switch_uint32_t table_size=512) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() { stats.count(); } action set_tc(switch_tc_t tc) { local_md.qos.tc = tc; stats.count(); } action set_color(switch_pkt_color_t color) { local_md.qos.color = color; stats.count(); } action set_meter(switch_meter_index_t index) { local_md.qos.acl_meter_index = index; stats.count(); } action set_user_defined_trap(switch_hostif_trap_t trap_id) { local_md.lkp.hostif_trap_id = trap_id; stats.count(); } action deny() { local_md.flags.acl_deny = true; stats.count(); } action permit(switch_user_metadata_t user_metadata) { local_md.flags.acl_deny = false; local_md.user_metadata = user_metadata; stats.count(); } action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) { local_md.flags.acl_deny = false; local_md.egress_port_lag_index = egress_port_lag_index; local_md.acl_port_redirect = true; local_md.user_metadata = user_metadata; stats.count(); } action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { local_md.mirror.type = 1; local_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS; local_md.mirror.session_id = session_id; local_md.mirror.meter_index = meter_index; stats.count(); } action set_dtel_report_type(switch_dtel_report_type_t type) { local_md.dtel.report_type = local_md.dtel.report_type | type; stats.count(); }
    action redirect_nexthop(switch_user_metadata_t user_metadata, switch_nexthop_t nexthop_index) { acl_nexthop = nexthop_index; local_md.user_metadata = user_metadata; stats.count(); }

    table acl {
        key = {
            local_md.lkp.ip_src_addr : ternary; local_md.lkp.ip_dst_addr : ternary; local_md.lkp.ip_proto : ternary; local_md.lkp.ip_tos : ternary; local_md.lkp.l4_src_port : ternary; local_md.lkp.l4_dst_port : ternary; local_md.lkp.ip_ttl : ternary; local_md.lkp.ip_frag : ternary; local_md.lkp.tcp_flags : ternary; local_md.l4_src_port_label : ternary; local_md.l4_dst_port_label : ternary;
# 559 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
            local_md.ingress_port_lag_label : ternary;


            local_md.bd_label : ternary;



        }

        actions = {
            deny;
            permit;






            mirror;
# 586 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
            set_user_defined_trap;
            no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Ingress MAC ACL (For outer header only)
//-----------------------------------------------------------------------------
control IngressMacAcl(in switch_header_t hdr, inout switch_local_metadata_t local_md,
                     out switch_nexthop_t acl_nexthop)(
        switch_uint32_t table_size=512) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() { stats.count(); } action set_tc(switch_tc_t tc) { local_md.qos.tc = tc; stats.count(); } action set_color(switch_pkt_color_t color) { local_md.qos.color = color; stats.count(); } action set_meter(switch_meter_index_t index) { local_md.qos.acl_meter_index = index; stats.count(); } action set_user_defined_trap(switch_hostif_trap_t trap_id) { local_md.lkp.hostif_trap_id = trap_id; stats.count(); } action deny() { local_md.flags.acl_deny = true; stats.count(); } action permit(switch_user_metadata_t user_metadata) { local_md.flags.acl_deny = false; local_md.user_metadata = user_metadata; stats.count(); } action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) { local_md.flags.acl_deny = false; local_md.egress_port_lag_index = egress_port_lag_index; local_md.acl_port_redirect = true; local_md.user_metadata = user_metadata; stats.count(); } action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { local_md.mirror.type = 1; local_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS; local_md.mirror.session_id = session_id; local_md.mirror.meter_index = meter_index; stats.count(); } action set_dtel_report_type(switch_dtel_report_type_t type) { local_md.dtel.report_type = local_md.dtel.report_type | type; stats.count(); }
    action redirect_nexthop(switch_user_metadata_t user_metadata, switch_nexthop_t nexthop_index) { acl_nexthop = nexthop_index; local_md.user_metadata = user_metadata; stats.count(); }

    table acl {
        key = {
            hdr.ethernet.src_addr : ternary; hdr.ethernet.dst_addr : ternary; local_md.lkp.mac_type : ternary;
            local_md.ingress_port_lag_label : ternary;

            local_md.bd_label : ternary;



        }

        actions = {
            deny;
            permit;






            mirror;
# 643 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
            no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Ingress Shared IP DTEL Sample ACL
// Typically a DTEL ACL slice should use the normal shared IP ACL definition
// This is an alternate definition that adds sampling and IFA clone support
//-----------------------------------------------------------------------------
struct switch_acl_sample_info_t {
    bit<32> current;
    bit<32> rate;
}

control IngressIpDtelSampleAcl(inout switch_local_metadata_t local_md,
                         out switch_nexthop_t acl_nexthop)(
        switch_uint32_t table_size=512) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    const bit<32> acl_sample_session_size = 256;

    Register<switch_acl_sample_info_t, bit<32>>(acl_sample_session_size) samplers;
    RegisterAction<switch_acl_sample_info_t, bit<8>, bit<1>>(samplers) sample_packet = {
        void apply(inout switch_acl_sample_info_t reg, out bit<1> flag) {
            if (reg.current > 0) {
                reg.current = reg.current - 1;
            } else {
                reg.current = reg.rate;
                flag = 1;
            }
        }
    };

    action no_action() { stats.count(); } action set_tc(switch_tc_t tc) { local_md.qos.tc = tc; stats.count(); } action set_color(switch_pkt_color_t color) { local_md.qos.color = color; stats.count(); } action set_meter(switch_meter_index_t index) { local_md.qos.acl_meter_index = index; stats.count(); } action set_user_defined_trap(switch_hostif_trap_t trap_id) { local_md.lkp.hostif_trap_id = trap_id; stats.count(); } action deny() { local_md.flags.acl_deny = true; stats.count(); } action permit(switch_user_metadata_t user_metadata) { local_md.flags.acl_deny = false; local_md.user_metadata = user_metadata; stats.count(); } action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) { local_md.flags.acl_deny = false; local_md.egress_port_lag_index = egress_port_lag_index; local_md.acl_port_redirect = true; local_md.user_metadata = user_metadata; stats.count(); } action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { local_md.mirror.type = 1; local_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS; local_md.mirror.session_id = session_id; local_md.mirror.meter_index = meter_index; stats.count(); } action set_dtel_report_type(switch_dtel_report_type_t type) { local_md.dtel.report_type = local_md.dtel.report_type | type; stats.count(); }

    action ifa_clone_sample(switch_ifa_sample_id_t ifa_sample_session) {
        local_md.dtel.ifa_gen_clone = sample_packet.execute(ifa_sample_session);
        stats.count();
    }

    action ifa_clone_sample_and_set_dtel_report_type(
            switch_ifa_sample_id_t ifa_sample_session,
            switch_dtel_report_type_t type) {
        local_md.dtel.report_type = type;
        local_md.dtel.ifa_gen_clone = sample_packet.execute(ifa_sample_session);
        stats.count();
    }

    table acl {
        key = {
            local_md.lkp.ip_src_addr : ternary; local_md.lkp.ip_dst_addr : ternary; local_md.lkp.ip_proto : ternary; local_md.lkp.ip_tos : ternary; local_md.lkp.l4_src_port : ternary; local_md.lkp.l4_dst_port : ternary; local_md.lkp.ip_ttl : ternary; local_md.lkp.ip_frag : ternary; local_md.lkp.tcp_flags : ternary; local_md.l4_src_port_label : ternary; local_md.l4_dst_port_label : ternary;







            local_md.ingress_port_lag_label : ternary;


            local_md.bd_label : ternary;



        }

        actions = {
            set_dtel_report_type;




            no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }





    }
}

// ----------------------------------------------------------------------------
// Comparison/Logical operation unit (LOU)
// LOU can perform logical operationis such AND and OR on tcp flags as well as comparison
// operations such as LT, GT, EQ, and NE for src/dst UDP/TCP ports.
//
// @param table_size : Total number of supported ranges for src/dst ports.
// ----------------------------------------------------------------------------
control LOU(inout switch_local_metadata_t local_md) {

    const switch_uint32_t table_size = 8;

    //TODO(msharif): Change this to bitwise OR so we can allocate bits to src/dst ports at runtime.
    action set_src_port_label(bit<8> label) {
        local_md.l4_src_port_label = label;
    }

    action set_dst_port_label(bit<8> label) {
        local_md.l4_dst_port_label = label;
    }


    @stage(1)

    @entries_with_ranges(table_size)
    table l4_dst_port {
        key = {
            local_md.lkp.l4_dst_port : range;
        }

        actions = {
            NoAction;
            set_dst_port_label;
        }

        const default_action = NoAction;
        size = table_size;
    }


    @stage(1)

    @entries_with_ranges(table_size)
    table l4_src_port {
        key = {
            local_md.lkp.l4_src_port : range;
        }

        actions = {
            NoAction;
            set_src_port_label;
        }

        const default_action = NoAction;
        size = table_size;
    }

    action set_tcp_flags(bit<8> flags) {
        local_md.lkp.tcp_flags = flags;
    }

    table tcp {
        key = { local_md.lkp.tcp_flags : exact; }
        actions = {
            NoAction;
            set_tcp_flags;
        }

        size = 256;
    }

    apply {
# 827 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
    }
}

//-----------------------------------------------------------------------------
//
// Ingress System ACL
//
//-----------------------------------------------------------------------------
control IngressSystemAcl(
        in switch_header_t hdr,
        inout switch_local_metadata_t local_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(
        switch_uint32_t table_size=512) {

    const switch_uint32_t drop_stats_table_size = 8192;

    DirectCounter<bit<64>>(CounterType_t.PACKETS) stats;

    Meter<bit<8>>(1 << 8, MeterType_t.PACKETS) copp_meter;
    DirectCounter<bit<64>>(CounterType_t.PACKETS) copp_stats;

    switch_copp_meter_id_t copp_meter_id;

    action drop(switch_drop_reason_t drop_reason, bool disable_learning) {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        ig_intr_md_for_dprsr.digest_type =
            disable_learning ? SWITCH_DIGEST_TYPE_INVALID : ig_intr_md_for_dprsr.digest_type;
        local_md.drop_reason = drop_reason;



    }

    action copy_to_cpu(switch_cpu_reason_t reason_code,
                       switch_qid_t qid,
                       switch_copp_meter_id_t meter_id,
                       bool disable_learning) {
        local_md.qos.qid = qid;
        // local_md.qos.icos = icos;
        ig_intr_md_for_tm.copy_to_cpu = 1w1;
        ig_intr_md_for_dprsr.digest_type =
            disable_learning ? SWITCH_DIGEST_TYPE_INVALID : ig_intr_md_for_dprsr.digest_type;
        ig_intr_md_for_tm.packet_color = (bit<2>) copp_meter.execute(meter_id);
        copp_meter_id = meter_id;
        local_md.cpu_reason = reason_code;



    }
# 887 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
    action redirect_to_cpu(switch_cpu_reason_t reason_code,
                           switch_qid_t qid,
                           switch_copp_meter_id_t meter_id,
                           bool disable_learning) {
        ig_intr_md_for_dprsr.drop_ctl = 0b1;
        copy_to_cpu(reason_code, qid, meter_id, disable_learning);
    }
# 905 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
    table system_acl {
        key = {
            local_md.ingress_port_lag_label : ternary;
            local_md.bd : ternary;
            local_md.ingress_port_lag_index : ternary;

            // Lookup fields
            local_md.lkp.pkt_type : ternary;
            local_md.lkp.mac_type : ternary;
            local_md.lkp.mac_dst_addr : ternary;
            local_md.lkp.ip_type : ternary;
            local_md.lkp.ip_ttl : ternary;
            local_md.lkp.ip_proto : ternary;
            local_md.lkp.ip_frag : ternary;
            local_md.lkp.ip_dst_addr : ternary;
            local_md.lkp.l4_src_port : ternary;
            local_md.lkp.l4_dst_port : ternary;
            local_md.lkp.arp_opcode : ternary;

            // Flags
            local_md.flags.port_vlan_miss : ternary;
            local_md.flags.acl_deny : ternary;
            local_md.flags.racl_deny : ternary;
            local_md.flags.rmac_hit : ternary;
            local_md.flags.dmac_miss : ternary;
            local_md.flags.myip : ternary;
            local_md.flags.glean : ternary;
            local_md.flags.routed : ternary;
            local_md.flags.fib_lpm_miss : ternary;
            local_md.flags.fib_drop : ternary;






            local_md.flags.link_local : ternary;





            local_md.checks.same_if : ternary;
# 956 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
            local_md.flags.pfc_wd_drop : ternary;

            local_md.ipv4.unicast_enable : ternary;
            local_md.ipv6.unicast_enable : ternary;
# 971 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
            local_md.l2_drop_reason : ternary;
            local_md.drop_reason : ternary;
# 990 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
            local_md.lkp.hostif_trap_id : ternary;
        }

        actions = {
            NoAction;
            drop;
            copy_to_cpu;
            redirect_to_cpu;




        }

        const default_action = NoAction;
        size = table_size;
    }

    action copp_drop() {
        ig_intr_md_for_tm.copy_to_cpu = 1w0;
        copp_stats.count();
    }

    action copp_permit() {
        copp_stats.count();
    }

    table copp {
        key = {
            ig_intr_md_for_tm.packet_color : ternary;
            copp_meter_id : ternary;
        }

        actions = {
            copp_permit;
            copp_drop;
        }

        const default_action = copp_permit;
        size = (1 << 8 + 1);
        counters = copp_stats;
    }

    action count() { stats.count(); }

    table drop_stats {
        key = {
            local_md.drop_reason : exact @name("drop_reason");
            local_md.ingress_port : exact @name("port");
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        counters = stats;
        size = drop_stats_table_size;
    }

    apply {
        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_SYSTEM_ACL != 0)) {
            switch(system_acl.apply().action_run) {

                copy_to_cpu : { copp.apply(); }
                redirect_to_cpu : { copp.apply(); }

                default: {}
            }
        }
        drop_stats.apply();
    }
}

// ----------------------------------------------------------------------------
// Comparison/Logical operation unit (LOU)
// LOU can perform logical operationis such AND and OR on tcp flags as well as comparison
// operations such as LT, GT, EQ, and NE for src/dst UDP/TCP ports.
//
// @param table_size : Total number of supported ranges for src/dst ports.
// ----------------------------------------------------------------------------
control EgressLOU(inout switch_local_metadata_t local_md) {

    const switch_uint32_t table_size = 8;

    //TODO(msharif): Change this to bitwise OR so we can allocate bits to src/dst ports at runtime.
    action set_src_port_label(bit<8> label) {
        local_md.l4_src_port_label = label;
    }

    action set_dst_port_label(bit<8> label) {
        local_md.l4_dst_port_label = label;
    }

// #ifndef TUNNEL_ENABLE
//     @stage(1)
// #endif
    @entries_with_ranges(table_size)
    table l4_dst_port {
        key = {
            local_md.lkp.l4_dst_port : range;
        }

        actions = {
            NoAction;
            set_dst_port_label;
        }

        const default_action = NoAction;
        size = table_size;
    }

// #ifndef TUNNEL_ENABLE
//     @stage(1)
// #endif
    @entries_with_ranges(table_size)
    table l4_src_port {
        key = {
            local_md.lkp.l4_src_port : range;
        }

        actions = {
            NoAction;
            set_src_port_label;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {




    }
}

//-----------------------------------------------------------------------------
// Egress MAC ACL
//-----------------------------------------------------------------------------
control EgressMacAcl(in switch_header_t hdr,
                     inout switch_local_metadata_t local_md)(
                     switch_uint32_t table_size=512) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() { stats.count(); } action deny() { local_md.flags.acl_deny = true; stats.count(); } action permit() { local_md.flags.acl_deny = false; stats.count(); } action set_meter(switch_meter_index_t index) { local_md.qos.acl_meter_index = index; stats.count(); } action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { local_md.mirror.type = 1; local_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS; local_md.mirror.session_id = session_id; local_md.mirror.meter_index = meter_index; stats.count(); }

    table acl {
        key = {
            hdr.ethernet.src_addr : ternary; hdr.ethernet.dst_addr : ternary; hdr.ethernet.ether_type : ternary; local_md.egress_port_lag_label: ternary;
        }

        actions = {
            deny(); permit(); set_meter(); mirror(); no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        if (!local_md.flags.bypass_egress) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Egress IPv4 ACL
//-----------------------------------------------------------------------------
control EgressIpv4Acl(in switch_header_t hdr,
                      inout switch_local_metadata_t local_md)(
                      switch_uint32_t table_size=512) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() { stats.count(); } action deny() { local_md.flags.acl_deny = true; stats.count(); } action permit() { local_md.flags.acl_deny = false; stats.count(); } action set_meter(switch_meter_index_t index) { local_md.qos.acl_meter_index = index; stats.count(); } action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { local_md.mirror.type = 1; local_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS; local_md.mirror.session_id = session_id; local_md.mirror.meter_index = meter_index; stats.count(); }

    table acl {
        key = {
            hdr.ipv4.src_addr : ternary; hdr.ipv4.dst_addr : ternary; hdr.ipv4.protocol : ternary; local_md.lkp.tcp_flags : ternary; local_md.lkp.l4_src_port : ternary; local_md.lkp.l4_dst_port : ternary; local_md.egress_port_lag_label: ternary;
# 1185 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
        }

        actions = {
            deny(); permit(); set_meter(); mirror(); no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        if (!local_md.flags.bypass_egress) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Egress IPv6 ACL
//-----------------------------------------------------------------------------
control EgressIpv6Acl(in switch_header_t hdr,
                      inout switch_local_metadata_t local_md)(
                      switch_uint32_t table_size=512) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() { stats.count(); } action deny() { local_md.flags.acl_deny = true; stats.count(); } action permit() { local_md.flags.acl_deny = false; stats.count(); } action set_meter(switch_meter_index_t index) { local_md.qos.acl_meter_index = index; stats.count(); } action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { local_md.mirror.type = 1; local_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS; local_md.mirror.session_id = session_id; local_md.mirror.meter_index = meter_index; stats.count(); }

    table acl {
        key = {
            hdr.ipv6.src_addr : ternary; hdr.ipv6.dst_addr : ternary; hdr.ipv6.next_hdr : ternary; local_md.lkp.tcp_flags : ternary; local_md.lkp.l4_src_port : ternary; local_md.lkp.l4_dst_port : ternary; local_md.egress_port_lag_label: ternary;
# 1227 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
        }

        actions = {
            deny(); permit(); set_meter(); mirror(); no_action;
        }

        const default_action = no_action;
        counters = stats;
        size = table_size;
    }

    apply {
        if (!local_md.flags.bypass_egress) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
//
// Egress System ACL
//
//-----------------------------------------------------------------------------
control EgressSystemAcl(
        inout switch_header_t hdr,
        inout switch_local_metadata_t local_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        out egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)(
        switch_uint32_t table_size=512) {

    const switch_uint32_t drop_stats_table_size = 8192;
    DirectCounter<bit<64>>(CounterType_t.PACKETS) stats;

    Meter<bit<8>>(1 << 8, MeterType_t.PACKETS) copp_meter;
    DirectCounter<bit<64>>(CounterType_t.PACKETS) copp_stats;

    switch_copp_meter_id_t copp_meter_id;
    switch_pkt_color_t copp_color;

    action drop(switch_drop_reason_t reason_code) {
        local_md.drop_reason = reason_code;
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        local_md.mirror.type = 0;
    }


    action copy_to_cpu(switch_cpu_reason_t reason_code,
                       switch_copp_meter_id_t meter_id) {
        local_md.cpu_reason = reason_code;
        eg_intr_md_for_dprsr.mirror_type = 2;
        local_md.mirror.type = 2;
        local_md.mirror.session_id = SWITCH_MIRROR_SESSION_CPU;
        local_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        copp_color = (bit<2>) copp_meter.execute(meter_id);
        copp_meter_id = meter_id;
    }

    action redirect_to_cpu(switch_cpu_reason_t reason_code,
                           switch_copp_meter_id_t meter_id) {
        copy_to_cpu(reason_code, meter_id);
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }


    action insert_timestamp() {




    }

    table system_acl {
        key = {
            eg_intr_md.egress_port : ternary;
            local_md.flags.acl_deny : ternary;





            local_md.checks.mtu : ternary;





            local_md.flags.wred_drop : ternary;


            local_md.flags.pfc_wd_drop : ternary;
# 1330 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4"
            //TODO add more
        }

        actions = {
            NoAction;
            drop;

            copy_to_cpu;
            redirect_to_cpu;

            insert_timestamp;
        }

        const default_action = NoAction;
        size = table_size;
    }

    action count() { stats.count(); }

    table drop_stats {
        key = {
            local_md.drop_reason : exact @name("drop_reason");
            eg_intr_md.egress_port : exact @name("port");
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        counters = stats;
        size = drop_stats_table_size;
    }


    action copp_drop() {
        local_md.mirror.type = 0;
        copp_stats.count();
    }

    action copp_permit() {
        copp_stats.count();
    }

    @ways(2)
    table copp {
        key = {
            copp_color : exact;
            copp_meter_id : exact;
        }

        actions = {
            copp_permit;
            copp_drop;
        }

        const default_action = copp_permit;
        size = (1 << 8 + 1);
        counters = copp_stats;
    }


    apply {
        if (!local_md.flags.bypass_egress) {
            switch(system_acl.apply().action_run) {

                copy_to_cpu : { copp.apply(); }
                redirect_to_cpu : { copp.apply(); }

                default: {}
            }
        }
        drop_stats.apply();
    }
}
# 24 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/l3.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/l2.p4" 1
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
// Spanning Tree Protocol
// @param local_md : Ingress metadata fields.
// @param stp_md : Spanning tree metadata.
// @param multiple_stp_enable : Allows to map a group of VLAN’s into a single spanning
// tree instance, for which spanning tree is applied independently.
// @param table_size : Size of the mstp table. Only used if multiple stp is enabled.
//
// @flag MULTIPLE_STP: Allows to map a group of VLAN’s into a single spanning
// tree instance, for which spanning tree is applied independently.
//-----------------------------------------------------------------------------
control IngressSTP(in switch_local_metadata_t local_md,
                   inout switch_stp_metadata_t stp_md)(
                   bool multiple_stp_enable=false,
                   switch_uint32_t table_size=4096) {
    // This register is used to check the stp state of the ingress port.
    // (bd << 7 | port) is used as the index to read the stp state. To save
    // resources, only 7-bit local port id is used to construct the indes.
    const bit<32> stp_state_size = 1 << 19;
    Register<bit<1>, bit<32>>(stp_state_size, 0) stp;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;
    RegisterAction<bit<1>, bit<32>, bit<1>>(stp) stp_check = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };

    action set_stp_state(switch_stp_state_t stp_state) {
        stp_md.state_ = stp_state;
    }

    table mstp {
        key = {
            local_md.ingress_port : exact;
            stp_md.group: exact;
        }

        actions = {
            NoAction;
            set_stp_state;
        }

        size = table_size;
        const default_action = NoAction;
    }

    apply {
# 86 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/l2.p4"
    }
}

//-----------------------------------------------------------------------------
// Spanning Tree Protocol
// @param local_md : Egress metadata fields.
// @param port : Egress port.
// @param stp_state : Spanning tree state.
//-----------------------------------------------------------------------------
control EgressSTP(in switch_local_metadata_t local_md, in switch_port_t port, out bool stp_state) {
    // This register is used to check the stp state of the egress port.
    // (bd << 7 | port) is used as the index to read the stp state. To save
    // resources, only 7-bit local port id is used to construct the index.
    Register<bit<1>, bit<32>>(1 << 19, 0) stp;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;
    RegisterAction<bit<1>, bit<32>, bit<1>>(stp) stp_check = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };

    apply {
# 117 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/l2.p4"
    }
}


//-----------------------------------------------------------------------------
// Source MAC lookup
//
// @param src_addr : Source MAC address.
// @param local_md : Ingress metadata
// @param table_size : Size of SMAC table.
//
// MAC learning
// - Trigger a new MAC learn if MAC address is unknown.
// - Trigger a new MAC learn if MAC address is known but attached to a different interface.
//-----------------------------------------------------------------------------
control SMAC(in mac_addr_t src_addr,
             inout switch_local_metadata_t local_md,
             inout switch_digest_type_t digest_type)(
             switch_uint32_t table_size) {
    // local variables for MAC learning
    bool src_miss;
    switch_port_lag_index_t src_move;

    action smac_miss() {
        src_miss = true;
    }

    action smac_hit(switch_port_lag_index_t port_lag_index) {
        src_move = local_md.ingress_port_lag_index ^ port_lag_index;
    }

    table smac {
        key = {
            local_md.bd : exact;
            src_addr : exact;
        }

        actions = {
            @defaultonly smac_miss;
            smac_hit;
        }

        const default_action = smac_miss;
        size = table_size;
        idle_timeout = true;
    }

    action notify() {
        digest_type = SWITCH_DIGEST_TYPE_MAC_LEARNING;
    }

    table learning {
        key = {
            src_miss : exact;
            src_move : ternary;
        }

        actions = {
            NoAction;
            notify;
        }

        const default_action = NoAction;
        size = MIN_TABLE_SIZE;
    }


    apply {
        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_SMAC != 0)) {
                smac.apply();
        }

        if (local_md.learning.bd_mode == SWITCH_LEARNING_MODE_LEARN &&
                local_md.learning.port_mode == SWITCH_LEARNING_MODE_LEARN) {
            learning.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Destination MAC lookup
//
// Performs a lookup on bd and destination MAC address.
// - Bridge out the packet of the interface in the MAC entry.
// - Flood the packet out of all ports within the ingress BD.
//
// @param dst_addr : destination MAC address.
// @param local_md : Ingess metadata
// @param ig_intr_md_for_tm
// @param table_size : Size of the dmac table.
//-----------------------------------------------------------------------------
control DMAC_t(in mac_addr_t dst_addr, inout switch_local_metadata_t local_md);

control DMAC(
        in mac_addr_t dst_addr, inout switch_local_metadata_t local_md)(switch_uint32_t table_size) {

    action dmac_miss() {
        local_md.egress_port_lag_index = SWITCH_FLOOD;
        local_md.flags.dmac_miss = true;
    }

    action dmac_hit(switch_port_lag_index_t port_lag_index) {
        local_md.egress_port_lag_index = port_lag_index;
        local_md.checks.same_if = local_md.ingress_port_lag_index ^ port_lag_index;
    }







    action dmac_redirect(switch_nexthop_t nexthop_index) {
        local_md.nexthop = nexthop_index;
    }

    /* CODE_HACK: P4C-3103 */
    @pack(2)
    table dmac {
        key = {
            local_md.bd : exact;
            dst_addr : exact;
        }

        actions = {
            dmac_miss;
            dmac_hit;



            dmac_redirect;
        }

        const default_action = dmac_miss;
        size = table_size;
    }

    apply {



        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_L2 != 0)) {

            dmac.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Ingress BD (VLAN, RIF) Stats
//
//-----------------------------------------------------------------------------
control IngressBd(in switch_bd_t bd, in switch_pkt_type_t pkt_type)(switch_uint32_t table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action count() { stats.count(); }

    table bd_stats {
        key = {
            bd : exact;
            pkt_type : exact;
        }

        actions = {
            count;
            @defaultonly NoAction;
        }

        const default_action = NoAction;

        // 3 entries per bridge domain for unicast/broadcast/multicast packets.
        size = 3 * table_size;
        counters = stats;
    }

    apply {
        bd_stats.apply();
    }
}
//-----------------------------------------------------------------------------
// Egress BD Stats
//      -- Outer BD for encap cases
//
//-----------------------------------------------------------------------------
control EgressBDStats(inout switch_header_t hdr,
                 inout switch_local_metadata_t local_md) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action count() {
        stats.count();
    }

    table bd_stats {
        key = {
            local_md.bd[12:0] : exact;
            local_md.pkt_type : exact;
        }

        actions = {
            count;
            @defaultonly NoAction;
        }

        size = 3 * BD_TABLE_SIZE;
        counters = stats;
    }

    apply {
        if (local_md.pkt_src == SWITCH_PKT_SRC_BRIDGED) {
          bd_stats.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Egress BD Properties
//      -- Outer BD for encap cases
//
//-----------------------------------------------------------------------------
control EgressBD(inout switch_header_t hdr,
                 inout switch_local_metadata_t local_md) {





    action set_bd_properties(mac_addr_t smac, switch_mtu_t mtu) {

        hdr.ethernet.src_addr = smac;
        local_md.checks.mtu = mtu;
    }




    table bd_mapping {
        key = { local_md.bd[12:0] : exact; }
        actions = {
            set_bd_properties;
        }




        const default_action = set_bd_properties(0, 0x3fff);

        /* CODE_HACK size increased from 5120 to 8192 so that table can be implemented as hash-action */



        size = 5120;

    }

    apply {
        if (!local_md.flags.bypass_egress && local_md.flags.routed) {
            bd_mapping.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// VLAN tag decapsulation
// Removes the vlan tag by default or selectively based on the ingress port if QINQ_ENABLE flag
// is defined.
//
// @param hdr : Parsed headers.
// @param local_md : Egress metadata fields.
// @param port : Ingress port.
// @flag QINQ_ENABLE
//-----------------------------------------------------------------------------
control VlanDecap(inout switch_header_t hdr, in switch_local_metadata_t local_md) {
    action remove_vlan_tag() {
        hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
        hdr.vlan_tag.pop_front(1);
    }

    action remove_double_tag() {
        hdr.ethernet.ether_type = hdr.vlan_tag[1].ether_type;
        hdr.vlan_tag.pop_front(2);
    }

    table vlan_decap {
        key = {



            hdr.vlan_tag[0].isValid() : ternary;



        }

        actions = {
            NoAction;
            remove_vlan_tag;
            remove_double_tag;
        }

        const default_action = NoAction;
    }

    apply {
        if (!local_md.flags.bypass_egress) {



            // Remove the vlan tag by default.
            if (hdr.vlan_tag[0].isValid()) {
                hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
                hdr.vlan_tag[0].setInvalid();
            }

        }
    }
}

//-----------------------------------------------------------------------------
// Vlan translation
//
// @param hdr : Parsed headers.
// @param local_md : Egress metadata fields.
// @flag QINQ_ENABLE
//-----------------------------------------------------------------------------
control VlanXlate(inout switch_header_t hdr,
                  in switch_local_metadata_t local_md)(
                  switch_uint32_t bd_table_size,
                  switch_uint32_t port_bd_table_size) {
    action set_vlan_untagged() {
        //NoAction.
    }

    action set_double_tagged(vlan_id_t vid0, vlan_id_t vid1) {
# 465 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/l2.p4"
   }

    action set_vlan_tagged(vlan_id_t vid) {



        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;

        hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].vid = vid;
        hdr.ethernet.ether_type = 0x8100;
    }

    table port_bd_to_vlan_mapping {
        key = {
            local_md.egress_port_lag_index : exact @name("port_lag_index");
            local_md.bd : exact @name("bd");
        }

        actions = {
            set_vlan_untagged;
            set_vlan_tagged;
            set_double_tagged;
        }

        const default_action = set_vlan_untagged;
        size = port_bd_table_size;
        //TODO : fix table size once scale requirements for double tag is known
    }

    table bd_to_vlan_mapping {
        key = { local_md.bd : exact @name("bd"); }
        actions = {
            set_vlan_untagged;
            set_vlan_tagged;
        }

        const default_action = set_vlan_untagged;
        size = bd_table_size;
    }

    action set_type_vlan() {
        hdr.ethernet.ether_type = 0x8100;
    }

    action set_type_qinq() {
        hdr.ethernet.ether_type = 0x8100;
    }

    table set_ether_type {
        key = {
            hdr.vlan_tag[0].isValid() : exact;
            hdr.vlan_tag[1].isValid() : exact;
        }

        actions = {
            NoAction;
            set_type_vlan;
            set_type_qinq;
        }

        const default_action = NoAction;
        const entries = {
            (true, false) : set_type_vlan();
            (true, true) : set_type_qinq();
        }
    }

    apply {
        if (!local_md.flags.bypass_egress) {
            if (!port_bd_to_vlan_mapping.apply().hit) {
                bd_to_vlan_mapping.apply();
            }




        }
    }
}
# 25 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/l3.p4" 2

//-----------------------------------------------------------------------------
// FIB lookup
//
// @param dst_addr : Destination IPv4 address.
// @param vrf
// @param flags
// @param nexthop : Nexthop index.
// @param host_table_size : Size of the host table.
// @param lpm_table_size : Size of the IPv4 route table.
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Common FIB  actions.
//-----------------------------------------------------------------------------
    action fib_hit(inout switch_local_metadata_t local_md, switch_nexthop_t nexthop_index, switch_fib_label_t fib_label) {
        local_md.nexthop = nexthop_index;



        local_md.flags.routed = true;
    }

    action fib_miss(inout switch_local_metadata_t local_md) {
        local_md.flags.routed = false;
    }

    action fib_miss_lpm4(inout switch_local_metadata_t local_md) {
        local_md.flags.routed = false;
        local_md.flags.fib_lpm_miss = true;
    }

    action fib_miss_lpm6(inout switch_local_metadata_t local_md) {
        local_md.flags.routed = false;
        local_md.flags.fib_lpm_miss = true;
    }

    action fib_drop(inout switch_local_metadata_t local_md) {
        local_md.flags.routed = false;
        local_md.flags.fib_drop = true;
    }

    action fib_myip(inout switch_local_metadata_t local_md, switch_myip_type_t myip) {
        local_md.flags.myip = myip;
    }


//
// *************************** IPv4 FIB **************************************
//
control Fibv4(inout switch_local_metadata_t local_md)(
              switch_uint32_t host_table_size,
              switch_uint32_t lpm_table_size,
              bool local_host_enable=false,
              switch_uint32_t local_host_table_size=1024) {

    /* CODE_HACK: P4C-3103 for table fitting with p4c 9.5. */
    @pack(2)
    @name(".ipv4_host") table host {
        key = {
            local_md.vrf : exact;
            local_md.lkp.ip_dst_addr[95:64] : exact;
        }

        actions = {
            fib_miss(local_md);
            fib_hit(local_md);
            fib_myip(local_md);
            fib_drop(local_md);
        }

        const default_action = fib_miss(local_md);
        size = host_table_size;
    }

    @name(".ipv4_local_host") table local_host {
        key = {
            local_md.vrf : exact;
            local_md.lkp.ip_dst_addr[95:64] : exact;
        }

        actions = {
            fib_miss(local_md);
            fib_hit(local_md);
            fib_myip(local_md);
            fib_drop(local_md);
        }

        const default_action = fib_miss(local_md);
        size = local_host_table_size;
    }







    Alpm(number_partitions = 4096, subtrees_per_partition = 2) algo_lpm;

    @name(".ipv4_lpm") table lpm32 {
        key = {
            local_md.vrf : exact;
            local_md.lkp.ip_dst_addr[95:64] : lpm;
        }

        actions = {
            fib_miss_lpm4(local_md);
            fib_hit(local_md);
            fib_myip(local_md);
            fib_drop(local_md);
        }

        const default_action = fib_miss_lpm4(local_md);
        size = lpm_table_size;
        implementation = algo_lpm;
        requires_versioning = false;
    }

    apply {
        if (local_host_enable) {
            if (!local_host.apply().hit) {
                if (!host.apply().hit) {
                    lpm32.apply();
                }
            }
        } else {
            if (!host.apply().hit) {
                lpm32.apply();
            }
        }
    }
}
//
// *************************** IPv6 FIB **************************************
//
control Fibv6(inout switch_local_metadata_t local_md)(
              switch_uint32_t host_table_size,
              switch_uint32_t lpm_table_size,
              switch_uint32_t lpm64_table_size=1024) {

    /* CODE_HACK Workaround for p4c-4064 */
    @immediate(0)
    @name(".ipv6_host") table host {
        key = {
            local_md.vrf : exact;
            local_md.lkp.ip_dst_addr : exact;
        }

        actions = {
            fib_miss(local_md);
            fib_hit(local_md);
            fib_myip(local_md);
            fib_drop(local_md);
        }

        const default_action = fib_miss(local_md);
        size = host_table_size;
    }



    Alpm(number_partitions = 1024, subtrees_per_partition = 1) algo_lpm128;



    @name(".ipv6_lpm128") table lpm128 {
        key = {
            local_md.vrf : exact;
            local_md.lkp.ip_dst_addr : lpm;
        }

        actions = {
            fib_miss(local_md);
            fib_hit(local_md);
            fib_myip(local_md);
            fib_drop(local_md);
        }

        const default_action = fib_miss(local_md);
        size = lpm_table_size;
        implementation = algo_lpm128;
        requires_versioning = false;
    }
# 231 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/l3.p4"
    Alpm(number_partitions = 2048, subtrees_per_partition = 2) algo_lpm64;
    @name(".ipv6_lpm64") table lpm64 {
        key = {
            local_md.vrf : exact;
            local_md.lkp.ip_dst_addr[127:64] : lpm;
        }

        actions = {
            fib_miss_lpm6(local_md);
            fib_hit(local_md);
            fib_myip(local_md);
            fib_drop(local_md);
        }

        const default_action = fib_miss_lpm6(local_md);
        size = lpm64_table_size;
        implementation = algo_lpm64;
        requires_versioning = false;
    }


    apply {

        if (!host.apply().hit) {



            if (!lpm128.apply().hit)

            {

                lpm64.apply();

            }
        }

    }
}
# 394 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/l3.p4"
//-----------------------------------------------------------------------------
// VRF Properties
//       -- Inner VRF for encap cases
//
//-----------------------------------------------------------------------------
control EgressVRF(inout switch_header_t hdr,
                 inout switch_local_metadata_t local_md) {

    action set_ipv4_vrf_properties(switch_tunnel_vni_t vni, mac_addr_t smac) {
        local_md.tunnel.vni = vni;
        hdr.ethernet.src_addr = smac;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action set_ipv6_vrf_properties(switch_tunnel_vni_t vni, mac_addr_t smac) {
        local_md.tunnel.vni = vni;
        hdr.ethernet.src_addr = smac;
        hdr.ipv6.hop_limit = hdr.ipv6.hop_limit - 1;
    }

    @ways(3)
    table vrf_mapping {
        key = {
            local_md.vrf : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            NoAction;
            set_ipv4_vrf_properties;
            set_ipv6_vrf_properties;
        }

        const default_action = NoAction;
        size = VRF_TABLE_SIZE*2;
    }

    apply {
        vrf_mapping.apply();
    }
}
//-----------------------------------------------------------------------------
// Egress pipeline : MTU Check
//-----------------------------------------------------------------------------
control MTU(in switch_header_t hdr,
            inout switch_local_metadata_t local_md)(
            switch_uint32_t table_size=1024) {

    action ipv4_mtu_check(switch_mtu_t mtu) {
        local_md.checks.mtu = mtu |-| hdr.ipv4.total_len;
    }

    action ipv6_mtu_check(switch_mtu_t mtu) {
        local_md.checks.mtu = mtu |-| hdr.ipv6.payload_len;
    }

    action mtu_miss() {
        local_md.checks.mtu = 16w0xffff;
    }

    table mtu {
        key = {
            local_md.checks.mtu : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }

        actions = {
            ipv4_mtu_check;
            ipv6_mtu_check;
            mtu_miss;
        }

        const default_action = mtu_miss;
        size = table_size;
    }

    apply {
        if (!local_md.flags.bypass_egress)
            mtu.apply();
    }
}
# 181 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/nexthop.p4" 1
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

// ----------------------------------------------------------------------------
// Nexthop/ECMP resolution
//
// @param local_md : Ingress metadata fields
// @param nexthop_table_size : Number of nexthops.
// @param ecmp_group_table_size : Number of ECMP groups.
// @param ecmp_selction_table_size : Maximum number of ECMP members.
//
// ----------------------------------------------------------------------------
control Nexthop(inout switch_local_metadata_t local_md)(
                switch_uint32_t nexthop_table_size,
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


    // ---------------- IP Nexthop ---------------- 
    action set_nexthop_properties(switch_port_lag_index_t port_lag_index,
                                  switch_bd_t bd,
                                  switch_nat_zone_t zone) {



        local_md.egress_port_lag_index = port_lag_index;



        local_md.checks.same_if = local_md.ingress_port_lag_index ^ port_lag_index;




    }

    action set_ecmp_properties(switch_port_lag_index_t port_lag_index,
                               switch_bd_t bd,
                               switch_nexthop_t nexthop_index, switch_nat_zone_t zone) {
        local_md.nexthop = nexthop_index;



        set_nexthop_properties(port_lag_index, bd, zone);
    }

    // ----------------  Post Route Flood ---------------- 
    action set_nexthop_properties_post_routed_flood(switch_bd_t bd, switch_mgid_t mgid, switch_nat_zone_t zone) {
        local_md.egress_port_lag_index = 0;
        local_md.multicast.id = mgid;



    }

    action set_ecmp_properties_post_routed_flood(
            switch_bd_t bd,
            switch_mgid_t mgid,
            switch_nexthop_t nexthop_index, switch_nat_zone_t zone) {
        local_md.nexthop = nexthop_index;
        set_nexthop_properties_post_routed_flood(bd, mgid, zone);
    }

    // ---------------- Glean ---------------- 
    action set_nexthop_properties_glean() {
        local_md.flags.glean = true;
    }

    action set_ecmp_properties_glean(switch_nexthop_t nexthop_index) {
        local_md.nexthop = nexthop_index;
        set_nexthop_properties_glean();
    }

    // ---------------- Drop ---------------- 
    action set_nexthop_properties_drop() {
        local_md.drop_reason = SWITCH_DROP_REASON_NEXTHOP;
    }

    action set_ecmp_properties_drop() {
        set_nexthop_properties_drop();
    }
# 134 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/nexthop.p4"
    @ways(2)
    table ecmp {
        key = {
            local_md.nexthop : exact;
            local_md.hash[15:0] : selector;
        }

        actions = {
            @defaultonly NoAction;
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
            local_md.nexthop : exact;
        }

        actions = {
            @defaultonly NoAction;
            set_nexthop_properties;
            set_nexthop_properties_drop;
            set_nexthop_properties_glean;
            set_nexthop_properties_post_routed_flood;



        }

        const default_action = NoAction;
        size = nexthop_table_size;
    }

    apply {
# 196 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/nexthop.p4"
        switch(nexthop.apply().action_run) {
            NoAction : { ecmp.apply(); }
            default : {}
            }



    }
}
# 248 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/nexthop.p4"
//--------------------------------------------------------------------------
// Egress Pipeline: Neighbor lookup for both routed and tunnel encap cases
//-------------------------------------------------------------------------

control Neighbor(inout switch_header_t hdr,
                inout switch_local_metadata_t local_md)() {

    action rewrite_l2(switch_bd_t bd, mac_addr_t dmac) {
        hdr.ethernet.dst_addr = dmac;
    }

    @use_hash_action(1) table neighbor {
        key = { local_md.nexthop : exact; } // Programming_note : Program if nexthop_type == IP
        actions = {
            rewrite_l2;
        }

        const default_action = rewrite_l2(0, 0);
        size = NEXTHOP_TABLE_SIZE;
    }

    apply {
        // Should not rewrite packets redirected to CPU.
        if (!local_md.flags.bypass_egress && local_md.flags.routed) {
            neighbor.apply();
        }
    }
}

//--------------------------------------------------------------------------
// Egress Pipeline: Outer Nexthop lookup for both routed and tunnel encap cases
/* CODE_HACK: Neighbor and OuterNexthop tables are implemented separately to 
   reduce the data-dependency between various p4 tables. Neighbor table needs to
   be placed after the tunnel encapsulation but OuterNexthop table can be placed
   earlier in the pipeline to reduce the overall pipeline length. */
//-------------------------------------------------------------------------

control OuterNexthop(inout switch_header_t hdr,
                inout switch_local_metadata_t local_md)() {

    action rewrite_l2(switch_bd_t bd) {
        local_md.bd = bd;
    }

    @use_hash_action(1) table outer_nexthop {
        key = { local_md.nexthop : exact; } // Programming_note : Program if nexthop_type == IP or MPLS
        actions = {
            rewrite_l2;
        }

        const default_action = rewrite_l2(0);
        size = NEXTHOP_TABLE_SIZE;
    }

    apply {
        // Should not rewrite packets redirected to CPU.
        if (!local_md.flags.bypass_egress && local_md.flags.routed) {
            outer_nexthop.apply();
        }
    }
}
# 182 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/parde.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be coverep by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/headers.p4" 1
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
# 22 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/parde.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/types.p4" 1
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
# 23 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/parde.p4" 2

//=============================================================================
// Ingress parser
//=============================================================================
parser SwitchIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_local_metadata_t local_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    Checksum() inner2_ipv4_checksum;
    value_set<bit<16>>(1) udp_port_vxlan;
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;

    value_set<switch_cpu_port_value_set_t>(4) recirc_cpu_port;

    value_set<switch_nvgre_value_set_t>(1) nvgre_st_key;





    state start {
        pkt.extract(ig_intr_md);
        local_md.ingress_port = ig_intr_md.ingress_port;



        local_md.timestamp = ig_intr_md.ingress_mac_tstamp[31:0];

        // Check for resubmit flag if packet is resubmitted.
        // transition select(ig_intr_md.resubmit_flag) {
        //    1 : parse_resubmit;
        //    0 : parse_port_metadata;
        // }
        transition parse_port_metadata;
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition accept;
    }

    state parse_port_metadata {
        // Parse port metadata produced by ibuf
        switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);
        local_md.ingress_port_lag_index = port_md.port_lag_index;
        local_md.ingress_port_lag_label = port_md.port_lag_label;



        transition parse_packet;
    }

    state parse_packet {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type, local_md.ingress_port) {
            cpu_port : parse_cpu;

            recirc_cpu_port : parse_recirc_cpu;

            (0x0800, _) : parse_ipv4;
            (0x0806, _) : parse_arp;
            (0x86dd, _) : parse_ipv6;
            (0x8100, _) : parse_vlan;
            (0x8100, _) : parse_vlan;




            (0x8808, _) : parse_pfc;

            default : accept;
        }
    }
# 141 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/parde.p4"
    state parse_cpu {
        pkt.extract(hdr.fabric);
        pkt.extract(hdr.cpu);
        local_md.bypass = hdr.cpu.reason_code;



        transition select(hdr.cpu.ether_type) {
            0x0800 : parse_ipv4;
            0x0806 : parse_arp;
            0x86dd : parse_ipv6;
            0x8100 : parse_vlan;
            0x8100 : parse_vlan;



            default : accept;
        }
    }



    state parse_recirc_cpu{
        pkt.extract(hdr.fabric);
        pkt.extract(hdr.cpu);
        local_md.ingress_port_lag_index = hdr.cpu.port_lag_index[9:0];
        local_md.ingress_port = hdr.cpu.ingress_port[8:0];
        hdr.ethernet.ether_type = hdr.cpu.ether_type;



        transition select(hdr.cpu.ether_type) {
            0x0800 : parse_ipv4;
            0x0806 : parse_arp;
            0x86dd : parse_ipv6;
            0x8100 : parse_vlan;
            0x8100 : parse_vlan;



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


    state parse_pfc {
        pkt.extract(hdr.pfc);
        local_md.bypass = 16w0xfffb; // Don't skip ACL 
        transition accept;
    }


    state parse_ipv4_no_options {
        local_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (1, 0) : parse_icmp;
            (2, 0) : parse_igmp;
            (6, 0) : parse_tcp;
            (17, 0) : parse_udp;
            (47, 0) : parse_ip_gre;




            // Do NOT parse the next header if IP packet is fragmented.
            default : accept;
        }
    }

    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            0x0806 : parse_arp;
            0x0800 : parse_ipv4;
            0x8100 : parse_vlan;
            0x86dd : parse_ipv6;



            default : accept;
        }
    }

    state parse_ipv6 {

        pkt.extract(hdr.ipv6);
# 271 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/parde.p4"
        transition select(hdr.ipv6.next_hdr) {
            58 : parse_icmp;
            6 : parse_tcp;
            17 : parse_udp;
            47 : parse_ip_gre;







            default : accept;
        }



    }
# 442 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/parde.p4"
    state parse_ip_gre {
        pkt.extract(hdr.gre);
        transition select(hdr.gre.flags_version, hdr.gre.proto) {



            (_, 0x0800) : parse_inner_ipv4;
            (_, 0x86dd) : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
# 465 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/parde.p4"
        transition select(hdr.udp.dst_port) {
            2123 : parse_gtp_u;



            4791 : parse_rocev2;
                default : accept;
            }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
# 486 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/parde.p4"
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);




        transition accept;
    }

    state parse_igmp {
        pkt.extract(hdr.igmp);




        transition accept;
    }

    state parse_gtp_u {
        // TODO : is there a need to parse inner headers
        pkt.extract(hdr.gtp);
        transition accept;
    }

    state parse_rocev2 {

        pkt.extract(hdr.rocev2_bth);

        transition accept;
    }

    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        local_md.tunnel.type = SWITCH_INGRESS_TUNNEL_TYPE_VXLAN;
        local_md.tunnel.vni = hdr.vxlan.vni;
        transition parse_inner_ethernet;
    }

    state parse_ipinip {
        local_md.tunnel.type = SWITCH_INGRESS_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv4;
    }

    state parse_ipv6inip {
        local_md.tunnel.type = SWITCH_INGRESS_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv6;
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
        local_md.flags.inner_ipv4_checksum_err = inner_ipv4_checksum.verify();
        transition select(hdr.inner_ipv4.protocol) {
            1 : parse_inner_icmp;
            6 : parse_inner_tcp;
            17 : parse_inner_udp;




            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);







        transition select(hdr.inner_ipv6.next_hdr) {
            58 : parse_inner_icmp;
            6 : parse_inner_tcp;
            17 : parse_inner_udp;
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
# 673 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/parde.p4"
}

//----------------------------------------------------------------------------
// Egress parser
//----------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_local_metadata_t local_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    value_set<bit<16>>(1) udp_port_vxlan;
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;
    value_set<switch_nvgre_value_set_t>(1) nvgre_st_key;

    /* CODE_HACK: P4C-1768. This is a workaround to prevent this state from being split into
     * multiple parser states. If the split happens, the match register allocation algorithm
     * currently runs out of parser match registers. This pragma ensures we do not encounter this
     * case for switch. To be removed once we have better interaction between PHV allocation and the
     * parser to prevent these cases.
     */
    @critical
    state start {
        pkt.extract(eg_intr_md);
        local_md.pkt_length = eg_intr_md.pkt_length;
        local_md.egress_port = eg_intr_md.egress_port;
        local_md.qos.qdepth = eg_intr_md.deq_qdepth;


        switch_port_mirror_metadata_h mirror_md = pkt.lookahead<switch_port_mirror_metadata_h>();
        transition select(eg_intr_md.deflection_flag, mirror_md.src, mirror_md.type) {
            (1, _, _) : parse_deflected_pkt;
            (_, SWITCH_PKT_SRC_BRIDGED, _) : parse_bridged_pkt;
            (_, _, 1) : parse_port_mirrored_metadata;
            (_, SWITCH_PKT_SRC_CLONED_EGRESS, 2) : parse_cpu_mirrored_metadata;
            (_, SWITCH_PKT_SRC_CLONED_INGRESS, 3) : parse_dtel_drop_metadata_from_ingress;

            (_, SWITCH_PKT_SRC_CLONED_INGRESS, 6) : parse_sfc_pause_metadata_from_ingress;

            (_, _, 3) : parse_dtel_drop_metadata_from_egress;
            (_, _, 4) : parse_dtel_switch_local_metadata;
            (_, _, 5) : parse_simple_mirrored_metadata;
        }



    }

    state parse_bridged_pkt {
        pkt.extract(hdr.bridged_md);
        local_md.pkt_src = SWITCH_PKT_SRC_BRIDGED;
        local_md.ingress_port = hdr.bridged_md.base.ingress_port;
        local_md.egress_port_lag_index = hdr.bridged_md.base.ingress_port_lag_index;
        local_md.bd = hdr.bridged_md.base.ingress_bd;
        local_md.nexthop = hdr.bridged_md.base.nexthop;
        local_md.cpu_reason = hdr.bridged_md.base.cpu_reason;
        local_md.flags.routed = hdr.bridged_md.base.routed;
        local_md.flags.bypass_egress = hdr.bridged_md.base.bypass_egress;







        local_md.pkt_type = hdr.bridged_md.base.pkt_type;
        local_md.ingress_timestamp = hdr.bridged_md.base.timestamp;
        local_md.qos.tc = hdr.bridged_md.base.tc;
        local_md.qos.qid = hdr.bridged_md.base.qid;
        local_md.qos.color = hdr.bridged_md.base.color;
        local_md.vrf = hdr.bridged_md.base.vrf;






        local_md.lkp.l4_src_port = hdr.bridged_md.acl.l4_src_port;
        local_md.lkp.l4_dst_port = hdr.bridged_md.acl.l4_dst_port;
        local_md.lkp.tcp_flags = hdr.bridged_md.acl.tcp_flags;
# 776 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/parde.p4"
        local_md.dtel.report_type = hdr.bridged_md.dtel.report_type;
        local_md.dtel.hash = hdr.bridged_md.dtel.hash;
        local_md.dtel.session_id = hdr.bridged_md.dtel.session_id;


        local_md.sfc.type = hdr.bridged_md.sfc.type;
        local_md.sfc.queue_register_idx = hdr.bridged_md.sfc.queue_register_idx;

        transition parse_ethernet;
    }

    state parse_deflected_pkt {

        pkt.extract(hdr.bridged_md);
        local_md.pkt_src = SWITCH_PKT_SRC_DEFLECTED;

        local_md.mirror.type = 255;

        local_md.flags.bypass_egress = true;
        local_md.dtel.report_type = hdr.bridged_md.dtel.report_type;
        local_md.dtel.hash = hdr.bridged_md.dtel.hash;
        // Initialize local_md.dtel.session_id to prevent it from being marked @pa_no_init.
        local_md.dtel.session_id = 0;
        local_md.mirror.session_id = hdr.bridged_md.dtel.session_id;
        local_md.qos.qid = hdr.bridged_md.base.qid;
# 816 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/parde.p4"
        local_md.ingress_timestamp = hdr.bridged_md.base.timestamp;
        hdr.dtel_report = {
            0,
            hdr.bridged_md.base.ingress_port,
            0,
            hdr.bridged_md.dtel.egress_port,
            0,
            hdr.bridged_md.base.qid};
        hdr.dtel_drop_report = {
            SWITCH_DROP_REASON_TRAFFIC_MANAGER,
            0};

        transition accept;



    }

    state parse_port_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.ethernet);
        local_md.pkt_src = port_md.src;
        local_md.mirror.session_id = port_md.session_id;
        local_md.ingress_timestamp = port_md.timestamp;
        local_md.flags.bypass_egress = true;

        local_md.mirror.type = port_md.type;


        // Initialize local_md.dtel.session_id to prevent it from being marked @pa_no_init.
        local_md.dtel.session_id = 0;

        transition accept;
    }

    state parse_cpu_mirrored_metadata {
        switch_cpu_mirror_metadata_h cpu_md;
        pkt.extract(cpu_md);
        pkt.extract(hdr.ethernet);
        local_md.pkt_src = cpu_md.src;
        local_md.flags.bypass_egress = true;
        local_md.bd = cpu_md.bd;
        // local_md.ingress_port = cpu_md.md.port;
        local_md.cpu_reason = cpu_md.reason_code;

        local_md.mirror.type = cpu_md.type;


        // Initialize local_md.dtel.session_id to prevent it from being marked @pa_no_init.
        local_md.dtel.session_id = 0;

        transition accept;
    }

    state parse_dtel_drop_metadata_from_egress {

        switch_dtel_drop_mirror_metadata_h dtel_md;
        pkt.extract(dtel_md);
        local_md.pkt_src = dtel_md.src;
        local_md.mirror.type = dtel_md.type;
        local_md.flags.bypass_egress = true;
        local_md.dtel.report_type = dtel_md.report_type;
        local_md.dtel.hash = dtel_md.hash;
        // Initialize local_md.dtel.session_id to prevent it from being marked @pa_no_init.
        local_md.dtel.session_id = 0;
        local_md.mirror.session_id = dtel_md.session_id;
# 898 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/parde.p4"
        local_md.ingress_timestamp = dtel_md.timestamp;
        hdr.dtel_report = {
            0,
            dtel_md.ingress_port,
            0,
            dtel_md.egress_port,
            0,
            dtel_md.qid};
        hdr.dtel_drop_report = {
            dtel_md.drop_reason,
            0};

        transition accept;



    }

    /* Separate parse state for drop metadata from ingress, in order to set
     * hdr.dtel_report.egress_port to SWITCH_PORT_INVALID */
    state parse_dtel_drop_metadata_from_ingress {

        switch_dtel_drop_mirror_metadata_h dtel_md;
        pkt.extract(dtel_md);
        local_md.pkt_src = dtel_md.src;
        local_md.mirror.type = dtel_md.type;
        local_md.flags.bypass_egress = true;
        local_md.dtel.report_type = dtel_md.report_type;
        local_md.dtel.hash = dtel_md.hash;
        // Initialize local_md.dtel.session_id to prevent it from being marked @pa_no_init.
        local_md.dtel.session_id = 0;
        local_md.mirror.session_id = dtel_md.session_id;
# 945 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/parde.p4"
        local_md.ingress_timestamp = dtel_md.timestamp;
        hdr.dtel_report = {
            0,
            dtel_md.ingress_port,
            0,
            SWITCH_PORT_INVALID,
            0,
            dtel_md.qid};
        hdr.dtel_drop_report = {
            dtel_md.drop_reason,
            0};

        transition accept;



    }


    state parse_sfc_pause_metadata_from_ingress {
        switch_sfc_pause_mirror_metadata_h sfc_md;
        pkt.extract(sfc_md);

        local_md.sfc.type = SfcPacketType.Trigger;
        local_md.sfc.queue_register_idx = sfc_md.queue_register_idx;
        local_md.nexthop = sfc_md.nexthop;
        local_md.flags.routed = true;
        local_md.ingress_port_lag_index = sfc_md.port_lag_index[9:0];
        local_md.ingress_port = sfc_md.ingress_port[8:0];

        transition parse_ethernet;
    }


    state parse_dtel_switch_local_metadata {

        switch_dtel_switch_local_mirror_metadata_h dtel_md;
        pkt.extract(dtel_md);
        local_md.pkt_src = dtel_md.src;
        local_md.mirror.type = dtel_md.type;
        local_md.flags.bypass_egress = true;
        local_md.dtel.report_type = dtel_md.report_type;
        local_md.dtel.hash = dtel_md.hash;
        // Initialize local_md.dtel.session_id to prevent it from being marked @pa_no_init.
        local_md.dtel.session_id = 0;
        local_md.mirror.session_id = dtel_md.session_id;
# 1013 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/parde.p4"
        local_md.ingress_timestamp = dtel_md.timestamp;
        hdr.dtel_report = {
            0,
            dtel_md.ingress_port,
            0,
            dtel_md.egress_port,
            0,
            dtel_md.qid};
        hdr.dtel_switch_local_report = {
            0,
            dtel_md.qdepth,
            dtel_md.egress_timestamp};

        transition accept;



    }

    state parse_simple_mirrored_metadata {

        switch_simple_mirror_metadata_h simple_mirror_md;
        pkt.extract(simple_mirror_md);
        local_md.pkt_src = simple_mirror_md.src;
        local_md.mirror.type = simple_mirror_md.type;
        local_md.mirror.session_id = simple_mirror_md.session_id;
        local_md.flags.bypass_egress = true;
        transition parse_ethernet;



    }

    state parse_packet {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type, eg_intr_md.egress_port) {
            cpu_port : parse_cpu;
            (0x0800, _) : parse_ipv4;
            (0x86dd, _) : parse_ipv6;
            (0x8100, _) : parse_vlan;
            (0x8100, _) : parse_vlan;




            (0x8808, _) : parse_pfc;

            default : accept;
        }
    }

    state parse_cpu {
        local_md.flags.bypass_egress = true;
        transition accept;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol, hdr.ipv4.ihl, hdr.ipv4.frag_offset) {







            // (IP_PROTOCOLS_GRE, 5, 0) : parse_ip_gre;
            (_, 6, _) : parse_ipv4_options;

            (17, 5, 0) : parse_udp;
            (6, 5, 0) : parse_tcp;

            default : accept;
        }
    }

    state parse_ipv4_options {
        pkt.extract(hdr.ipv4_option);
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {







            // (IP_PROTOCOLS_GRE, 0) : parse_ip_gre;
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            0x0800 : parse_ipv4;
            0x8100 : parse_vlan;
            0x86dd : parse_ipv6;



            default : accept;
        }
    }


    state parse_pfc {
        pkt.extract(hdr.pfc);
        transition accept;
    }


    state parse_ipv6 {

        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
# 1140 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/parde.p4"
            // IP_PROTOCOLS_GRE : parse_ip_gre;
            default : accept;
        }



    }
# 1181 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/parde.p4"
    state parse_ip_gre {
        pkt.extract(hdr.gre);
        transition select(hdr.gre.flags_version, hdr.gre.proto) {



            //(_, GRE_PROTOCOLS_IP) : parse_inner_ipv4;
            //(_, GRE_PROTOCOLS_IPV6) : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {




            1674 : egress_parse_sfc_pause;

            default : accept;
        }
    }

    state egress_parse_sfc_pause {

        pkt.extract(hdr.sfc_pause);
        local_md.sfc.pause_dscp = hdr.sfc_pause.dscp;
        local_md.sfc.pause_duration_us = hdr.sfc_pause.duration_us;

        transition accept;
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
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
// Mirror packet deparser
//-----------------------------------------------------------------------------
control IngressMirror(
    inout switch_header_t hdr,
    in switch_local_metadata_t local_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
// Ingress deparser create a copy of the original ingress packet and prepend the prepend the mirror
// header.
    Mirror() mirror;

    apply {

        if (ig_intr_md_for_dprsr.mirror_type == 1) {
            mirror.emit<switch_port_mirror_metadata_h>(
                local_md.mirror.session_id,
                {local_md.mirror.src,
                 local_md.mirror.type,
                 local_md.timestamp,



                 local_md.mirror.session_id});

        } else if (ig_intr_md_for_dprsr.mirror_type == 3) {

            mirror.emit<switch_dtel_drop_mirror_metadata_h>(local_md.dtel.session_id, {
                local_md.mirror.src,
                local_md.mirror.type,
                local_md.timestamp,



                local_md.dtel.session_id,
                local_md.lag_hash,
                local_md.dtel.report_type,
                0,
                local_md.ingress_port,
                0,
                local_md.egress_port,
                0,
                local_md.qos.qid,
                local_md.drop_reason
            });


        } else if (ig_intr_md_for_dprsr.mirror_type == 6) {

            mirror.emit<switch_sfc_pause_mirror_metadata_h>(local_md.mirror.session_id, {
                local_md.mirror.src,
                local_md.mirror.type,
                //ig_md.timestamp,
                0, // We don't use this timestamp, so we can skip
                local_md.sfc.queue_register_idx,
                local_md.nexthop,
                (bit<16>)local_md.ingress_port,
                (bit<16>)local_md.ingress_port_lag_index
            });

        }

    }
}

control EgressMirror(
    inout switch_header_t hdr,
    in switch_local_metadata_t local_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
// Egress deparser first construct the output packet and then prepend the mirror header.
    Mirror() mirror;

    apply {

        if (eg_intr_md_for_dprsr.mirror_type == 1) {
            mirror.emit<switch_port_mirror_metadata_h>(local_md.mirror.session_id, {
                local_md.mirror.src,
                local_md.mirror.type,
                local_md.ingress_timestamp,



                local_md.mirror.session_id});
        } else if (eg_intr_md_for_dprsr.mirror_type == 2) {
            mirror.emit<switch_cpu_mirror_metadata_h>(local_md.mirror.session_id, {
                local_md.mirror.src,
                local_md.mirror.type,
                0,
                local_md.ingress_port,
                local_md.bd,
                0,
                local_md.egress_port_lag_index,
                local_md.cpu_reason});
        } else if (eg_intr_md_for_dprsr.mirror_type == 4) {

            mirror.emit<switch_dtel_switch_local_mirror_metadata_h>(local_md.dtel.session_id, {
                local_md.mirror.src, local_md.mirror.type,
                local_md.ingress_timestamp,



                local_md.dtel.session_id,
                local_md.dtel.hash,
                local_md.dtel.report_type,
                0,
                local_md.ingress_port,
                0,
                local_md.egress_port,
                0,
                local_md.qos.qid,
                0,
                local_md.qos.qdepth,
                local_md.egress_timestamp
            });

        } else if (eg_intr_md_for_dprsr.mirror_type == 3) {

            mirror.emit<switch_dtel_drop_mirror_metadata_h>(local_md.dtel.session_id, {
                local_md.mirror.src,
                local_md.mirror.type,
                local_md.ingress_timestamp,



                local_md.dtel.session_id,
                local_md.dtel.hash,
                local_md.dtel.report_type,
                0,
                local_md.ingress_port,
                0,
                local_md.egress_port,
                0,
                local_md.qos.qid,
                local_md.drop_reason
            });

        } else if (eg_intr_md_for_dprsr.mirror_type == 5) {

            mirror.emit<switch_simple_mirror_metadata_h>(local_md.dtel.session_id, {
                local_md.mirror.src,
                local_md.mirror.type,



                local_md.dtel.session_id
            });

        }

    }
}

control IngressNatChecksum(
    inout switch_header_t hdr,
    in switch_local_metadata_t local_md) {
    Checksum() tcp_checksum;
    Checksum() udp_checksum;
    apply {
# 1434 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/parde.p4"
    }
}

//-----------------------------------------------------------------------------
// Ingress Deparser
//-----------------------------------------------------------------------------
control SwitchIngressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_local_metadata_t local_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    IngressMirror() mirror;
    Digest<switch_learning_digest_t>() digest;







    apply {
        mirror.apply(hdr, local_md, ig_intr_md_for_dprsr);

        if (ig_intr_md_for_dprsr.digest_type == SWITCH_DIGEST_TYPE_MAC_LEARNING) {
            digest.pack({local_md.bd, local_md.ingress_port_lag_index, hdr.ethernet.src_addr});
        }




        pkt.emit(hdr.bridged_md); // Ingress only.
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.arp); // Ingress only.

        pkt.emit(hdr.pfc); // Ingress only

        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv4_option);
        pkt.emit(hdr.ipv6);







        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp); // Ingress only.
        pkt.emit(hdr.icmp); // Ingress only.
        pkt.emit(hdr.igmp); // Ingress only.
        pkt.emit(hdr.rocev2_bth); // Ingress only.



        pkt.emit(hdr.gre);



        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
    }
}


//-----------------------------------------------------------------------------
// Egress Deparser
//-----------------------------------------------------------------------------
control SwitchEgressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_local_metadata_t local_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    EgressMirror() mirror;
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    apply {
        mirror.apply(hdr, local_md, eg_intr_md_for_dprsr);


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
            hdr.ipv4.dst_addr,
            hdr.ipv4_option.type,
            hdr.ipv4_option.length,
            hdr.ipv4_option.value});
# 1555 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/parde.p4"
        pkt.emit(hdr.ethernet);

        pkt.emit(hdr.pfc); //egress only

        pkt.emit(hdr.fabric); // Egress only.
        pkt.emit(hdr.cpu); // Egress only.
        pkt.emit(hdr.timestamp); // Egress only.
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv4_option);
        pkt.emit(hdr.ipv6);







        pkt.emit(hdr.udp);

        pkt.emit(hdr.sfc_pause);
        pkt.emit(hdr.pad_112b);
        pkt.emit(hdr.pad_96b);
        pkt.emit(hdr.tcp);

        pkt.emit(hdr.dtel); // Egress only.







        pkt.emit(hdr.dtel_report); // Egress only.
        pkt.emit(hdr.dtel_switch_local_report); // Egress only.

        pkt.emit(hdr.dtel_drop_report); // Egress only.



        pkt.emit(hdr.gre);



        pkt.emit(hdr.erspan); // Egress only.
        pkt.emit(hdr.erspan_type2); // Egress only.
        pkt.emit(hdr.erspan_type3); // Egress only.
        pkt.emit(hdr.erspan_platform); // Egress only.
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
    }
}
# 183 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/port.p4" 1
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

# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4" 1

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




# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/l2.p4" 1
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
# 28 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4" 2

//-----------------------------------------------------------------------------
// @param hdr : Parsed headers. For mirrored packet only Ethernet header is parsed.
// @param local_md : Egress metadata fields.
// @param table_size : Number of mirror sessions.
//
// @flags PACKET_LENGTH_ADJUSTMENT : For mirrored packet, the length of the mirrored
// metadata fields is also accounted in the packet length. This flags enables the
// calculation of the packet length excluding the mirrored metadata fields.
//-----------------------------------------------------------------------------
control MirrorRewrite(inout switch_header_t hdr,
                      inout switch_local_metadata_t local_md,
                      out egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)(
                      switch_uint32_t table_size=1024) {
    bit<16> length;

    // Common actions
    action add_ethernet_header(in mac_addr_t src_addr,
                               in mac_addr_t dst_addr,
                               in bit<16> ether_type) {
        hdr.ethernet.setValid();
        hdr.ethernet.ether_type = ether_type;
        hdr.ethernet.src_addr = src_addr;
        hdr.ethernet.dst_addr = dst_addr;
    }

    action add_vlan_tag(vlan_id_t vid, bit<3> pcp, bit<16> ether_type) {
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].pcp = pcp;
        // hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].vid = vid;
        hdr.vlan_tag[0].ether_type = ether_type;
    }

    action add_ipv4_header(in bit<8> diffserv,
                           in bit<8> ttl,
                           in bit<8> protocol,
                           in ipv4_addr_t src_addr,
                           in ipv4_addr_t dst_addr) {
        hdr.ipv4.setValid();
        hdr.ipv4.version = 4w4;
        hdr.ipv4.ihl = 4w5;
        hdr.ipv4.diffserv = diffserv;
        // hdr.ipv4.total_len = 0;
        hdr.ipv4.identification = 0;
        hdr.ipv4.flags = 0;
        hdr.ipv4.frag_offset = 0;
        hdr.ipv4.ttl = ttl;
        hdr.ipv4.protocol = protocol;
        hdr.ipv4.src_addr = src_addr;
        hdr.ipv4.dst_addr = dst_addr;
    }

    action add_gre_header(in bit<16> proto) {
        hdr.gre.setValid();
        hdr.gre.proto = proto;
//        hdr.gre.C = 0;
//        hdr.gre.R = 0;
//        hdr.gre.K = 0;
//        hdr.gre.S = 0;
//        hdr.gre.s = 0;
//        hdr.gre.recurse = 0;
//        hdr.gre.flags = 0;
        hdr.gre.flags_version = 0;
    }

    action add_erspan_common(bit<16> version_vlan, bit<10> session_id) {
        hdr.erspan.setValid();
        hdr.erspan.version_vlan = version_vlan;
        hdr.erspan.session_id = (bit<16>) session_id;
    }

    action add_erspan_type2(bit<10> session_id) {
        add_erspan_common(0x1000, session_id);
        hdr.erspan_type2.setValid();
        hdr.erspan_type2.index = 0;
    }

    action add_erspan_type3(bit<10> session_id, bit<32> timestamp, bool opt_sub_header) {
        add_erspan_common(0x2000, session_id);
        hdr.erspan_type3.setValid();
        hdr.erspan_type3.timestamp = timestamp;
        hdr.erspan_type3.ft_d_other = 0x4; // timestamp granularity IEEE 1588
        if (opt_sub_header) {





        }
    }

    //
    // ----------------  QID rewrite ----------------
    //
    action rewrite_(switch_qid_t qid) {
        local_md.qos.qid = qid;
    }
# 139 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4"
    //
    // ---------------- ERSPAN Type II ---------------- 
    //
    action rewrite_erspan_type2(
            switch_qid_t qid,
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
        //GRE sequence number is not supported
        local_md.qos.qid = qid;
        add_erspan_type2((bit<10>)local_md.mirror.session_id);
        add_gre_header(0x88BE);

        // Total length = packet length + 32
        //   IPv4 (20) + GRE (4) + Erspan (8)
        add_ipv4_header(tos, ttl, 47, sip, dip);

        hdr.ipv4.total_len = local_md.pkt_length + 16w32;




        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, 0x0800);
    }

    action rewrite_erspan_type2_with_vlan(
            switch_qid_t qid,
            bit<16> ether_type, mac_addr_t smac, mac_addr_t dmac,
            bit<3> pcp, vlan_id_t vid,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
        local_md.qos.qid = qid;
        add_erspan_type2((bit<10>) local_md.mirror.session_id);
        add_gre_header(0x88BE);

        // Total length = packet length + 32
        //   IPv4 (20) + GRE (4) + Erspan (8)
        add_ipv4_header(tos, ttl, 47, sip, dip);

        hdr.ipv4.total_len = local_md.pkt_length + 16w32;



        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, ether_type);
        add_vlan_tag(vid, pcp, 0x0800);
    }



    //
    // --------- ERSPAN Type III ---------------
    //
    action rewrite_erspan_type3(
            switch_qid_t qid,
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
        local_md.qos.qid = qid;
        add_erspan_type3((bit<10>)local_md.mirror.session_id, (bit<32>)local_md.ingress_timestamp, false);
        add_gre_header(0x22EB);

        // Total length = packet length + 36
        //   IPv4 (20) + GRE (4) + Erspan (12)
        add_ipv4_header(tos, ttl, 47, sip, dip);

        hdr.ipv4.total_len = local_md.pkt_length + 16w36;




        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, 0x0800);
    }

    action rewrite_erspan_type3_with_vlan(
            switch_qid_t qid,
            bit<16> ether_type, mac_addr_t smac, mac_addr_t dmac,
            bit<3> pcp, vlan_id_t vid,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
        local_md.qos.qid = qid;
        add_erspan_type3((bit<10>)local_md.mirror.session_id, (bit<32>)local_md.ingress_timestamp, false);
        add_gre_header(0x22EB);

        // Total length = packet length + 36
        //   IPv4 (20) + GRE (4) + Erspan (12)
        add_ipv4_header(tos, ttl, 47, sip, dip);

        hdr.ipv4.total_len = local_md.pkt_length + 16w36;



        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, ether_type);
        add_vlan_tag(vid, pcp, 0x0800);
    }
# 286 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4"
    //
    // ----------------  DTEL Report  ---------------- 
    //
    action rewrite_dtel_report(
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl,
            bit<16> udp_dst_port, switch_mirror_session_t session_id,
            bit<16> max_pkt_len) {
        // Dtel report header is added later in the pipeline.
        hdr.udp.setValid();
        hdr.udp.dst_port = udp_dst_port;
        hdr.udp.checksum = 0;

        // Total length = packet length + 28
        //   Add outer IPv4 (20) + UDP (8)
        add_ipv4_header(tos, ttl, 17, sip, dip);






        hdr.ipv4.total_len = local_md.pkt_length + 16w28;
        hdr.udp.length = local_md.pkt_length + 16w8;




        hdr.ipv4.flags = 2;

        add_ethernet_header(smac, dmac, 0x0800);
# 328 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4"
        eg_intr_md_for_dprsr.mtu_trunc_len = (bit<14>)max_pkt_len;





        local_md.pkt_length = local_md.pkt_length +
                           DTEL_REPORT_V0_5_OUTER_HEADERS_LENGTH;


    }

    action rewrite_dtel_report_with_entropy(
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl,
            bit<16> udp_dst_port, switch_mirror_session_t session_id,
            bit<16> max_pkt_len) {
        rewrite_dtel_report(smac, dmac, sip, dip, tos, ttl, udp_dst_port,
                            session_id, max_pkt_len);
        hdr.udp.src_port = local_md.dtel.hash[15:0];
    }

    action rewrite_dtel_report_without_entropy(
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl,
            bit<16> udp_dst_port, bit<16> udp_src_port,
            switch_mirror_session_t session_id, bit<16> max_pkt_len) {
        rewrite_dtel_report(smac, dmac, sip, dip, tos, ttl, udp_dst_port,
                            session_id, max_pkt_len);
        hdr.udp.src_port = udp_src_port;
    }

    action rewrite_ip_udp_lengths() {

        // Subtract outer ethernet
        hdr.ipv4.total_len = local_md.pkt_length - 16w14;
        hdr.udp.length = local_md.pkt_length - 16w34;



    }

    action rewrite_dtel_ifa_clone() {
        /* Indicates that IFA clone rewrite needs to occur.
         * For IFA identification using DSCP, not done in place here since
         * the rewrite differs for IPv4 and IPv6 packets. */
        local_md.dtel.ifa_cloned = 1;
    }





    table rewrite {
        key = { local_md.mirror.session_id : exact; }
        actions = {
            NoAction;
            rewrite_;




            rewrite_erspan_type2;
            rewrite_erspan_type2_with_vlan;


            rewrite_erspan_type3;
            rewrite_erspan_type3_with_vlan;






            rewrite_dtel_report_with_entropy;
            rewrite_dtel_report_without_entropy;







        }

        const default_action = NoAction;
        size = table_size;
    }


    //------------------------------------------------------------------------------------------
    // Length Adjustment
    //------------------------------------------------------------------------------------------

    action adjust_length(bit<16> length_offset) {
        local_md.pkt_length = local_md.pkt_length + length_offset;
        local_md.mirror.type = 0;
    }

    table pkt_length {
        key = { local_md.mirror.type : exact; }
        actions = { adjust_length; }
        const entries = {
            //-14
            2 : adjust_length(0xFFF2);
# 476 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4"
            //-11
            1 : adjust_length(0xFFF5);
            3 : adjust_length(2);
            4 : adjust_length(0x0);

            //-7
            5: adjust_length(0xFFF9);






            /* len(telemetry report v0.5 header)
             * + len(telemetry drop report header) - 4 bytes of CRC */
            255: adjust_length(20);

        }
    }

    action rewrite_ipv4_udp_len_truncate() {

        // (eth + crc) = 18
        hdr.ipv4.total_len = (bit<16>)eg_intr_md_for_dprsr.mtu_trunc_len - 16w18;
        // (eth + ipv4 + crc) = 38
        hdr.udp.length = (bit<16>)eg_intr_md_for_dprsr.mtu_trunc_len - 16w38;






    }

    table pkt_len_trunc_adjustment {
        key = {
                hdr.udp.isValid() : exact ;
                hdr.ipv4.isValid() : exact;
        }

        actions = {
                NoAction;
                rewrite_ipv4_udp_len_truncate;
        }

        const default_action = NoAction;
        const entries = {
            (true, true) : rewrite_ipv4_udp_len_truncate();
        }
    }

    apply {


        pkt_length.apply();

        rewrite.apply();


        local_md.pkt_length = local_md.pkt_length |-| (bit<16>)eg_intr_md_for_dprsr.mtu_trunc_len;
        if (local_md.pkt_length > 0 && eg_intr_md_for_dprsr.mtu_trunc_len > 0) {
            pkt_len_trunc_adjustment.apply();



        }



    }
}
# 24 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/port.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/rmac.p4" 1
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

control IngressRmac(inout switch_header_t hdr,
                    inout switch_local_metadata_t local_md)(
                    switch_uint32_t port_vlan_table_size,
                    switch_uint32_t vlan_table_size=4096) {
    //
    // **************** Router MAC Check ************************
    //
    action rmac_miss() {
        local_md.flags.rmac_hit = false;
    }
    action rmac_hit() {
        local_md.flags.rmac_hit = true;
    }

    table pv_rmac {
        key = {
            local_md.ingress_port_lag_index : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
            hdr.vlan_tag[0].vid : ternary;
            hdr.ethernet.dst_addr : exact;
        }

        actions = {
            rmac_miss;
            rmac_hit;
        }

        const default_action = rmac_miss;
        size = port_vlan_table_size;
    }

    table vlan_rmac {
        key = {
            hdr.vlan_tag[0].vid : exact;
            hdr.ethernet.dst_addr : exact;
        }

        actions = {
            @defaultonly rmac_miss;
            rmac_hit;
        }

        const default_action = rmac_miss;
        size = vlan_table_size;
    }

    apply {
        switch (pv_rmac.apply().action_run) {
            rmac_miss : {
                if (hdr.vlan_tag[0].isValid())
                    vlan_rmac.apply();
            }
        }
    }
}
# 25 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/port.p4" 2

//-----------------------------------------------------------------------------
// Ingress port mirroring
//-----------------------------------------------------------------------------
control PortMirror(
        in switch_port_t port,
        in switch_pkt_src_t src,
        inout switch_mirror_metadata_t mirror_md)(
        switch_uint32_t table_size=288) {

    action set_mirror_id(switch_mirror_session_t session_id, switch_mirror_meter_id_t meter_index) {
        mirror_md.type = 1;
        mirror_md.src = src;
        mirror_md.session_id = session_id;



    }

    table port_mirror {
        key = { port : exact; }
        actions = {
            NoAction;
            set_mirror_id;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        port_mirror.apply();
    }
}

control IngressPortMapping(
        inout switch_header_t hdr,
        inout switch_local_metadata_t local_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(
        switch_uint32_t port_vlan_table_size,
        switch_uint32_t bd_table_size,
        switch_uint32_t port_table_size=288,
        switch_uint32_t vlan_table_size=4096,
        switch_uint32_t double_tag_table_size=1024) {

    PortMirror(port_table_size) port_mirror;
    IngressRmac(port_vlan_table_size, vlan_table_size) rmac;
    ActionProfile(bd_table_size) bd_action_profile;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;

    // This register is used to check whether a port is a mermber of a vlan (bd)
    // or not. (port << 12 | vid) is used as the index to read the membership
    // status.To save resources, only 7-bit local port id is used to calculate
    // the indes.
    const bit<32> vlan_membership_size = 1 << 19;
    Register<bit<1>, bit<32>>(vlan_membership_size, 0) vlan_membership;
    RegisterAction<bit<1>, bit<32>, bit<1>>(vlan_membership) check_vlan_membership = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = ~val;
        }
    };

    action terminate_cpu_packet() {
        // local_md.bypass = hdr.cpu.reason_code;
        local_md.ingress_port = (switch_port_t) hdr.cpu.ingress_port;
        local_md.egress_port_lag_index =
            (switch_port_lag_index_t) hdr.cpu.port_lag_index;
        ig_intr_md_for_tm.qid = (switch_qid_t) hdr.cpu.egress_queue;
        local_md.flags.bypass_egress = (bool) hdr.cpu.tx_bypass;
        hdr.ethernet.ether_type = hdr.cpu.ether_type;
    }

    action set_cpu_port_properties(
            switch_port_lag_index_t port_lag_index,
            switch_ig_port_lag_label_t port_lag_label,
            switch_yid_t exclusion_id,
            switch_qos_trust_mode_t trust_mode,
            switch_qos_group_t qos_group,
            switch_pkt_color_t color,
            switch_tc_t tc) {
        local_md.ingress_port_lag_index = port_lag_index;
        local_md.ingress_port_lag_label = port_lag_label;
        local_md.qos.trust_mode = trust_mode;
        local_md.qos.group = qos_group;
        local_md.qos.color = color;
        local_md.qos.tc = tc;
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;

        terminate_cpu_packet();
    }

    action set_port_properties(
            switch_yid_t exclusion_id,
            switch_learning_mode_t learning_mode,
            switch_qos_trust_mode_t trust_mode,
            switch_qos_group_t qos_group,
            switch_pkt_color_t color,
            switch_tc_t tc,
            switch_meter_index_t meter_index,
            switch_sflow_id_t sflow_session_id,
            bool mac_pkt_class) {
        local_md.qos.trust_mode = trust_mode;
        local_md.qos.group = qos_group;
        local_md.qos.color = color;
        local_md.qos.tc = tc;
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
        local_md.learning.port_mode = learning_mode;
        local_md.checks.same_if = SWITCH_FLOOD;
        local_md.flags.mac_pkt_class = mac_pkt_class;






    }

    @placement_priority(2)
    table port_mapping {
        key = {
            local_md.ingress_port : exact;




        }

        actions = {
            set_port_properties;
            set_cpu_port_properties;
        }




        size = port_table_size;

    }

    action port_vlan_miss() {
        //local_md.flags.port_vlan_miss = true;
    }

    action set_bd_properties(switch_bd_t bd,
                             switch_vrf_t vrf,
                             switch_bd_label_t bd_label,
                             switch_stp_group_t stp_group,
                             switch_learning_mode_t learning_mode,
                             bool ipv4_unicast_enable,
                             bool ipv4_multicast_enable,
                             bool igmp_snooping_enable,
                             bool ipv6_unicast_enable,
                             bool ipv6_multicast_enable,
                             bool mld_snooping_enable,
                             switch_multicast_rpf_group_t mrpf_group,
                             switch_nat_zone_t zone) {
        local_md.bd = bd;
        local_md.bd_label = bd_label;
        local_md.vrf = vrf;
        local_md.stp.group = stp_group;
        local_md.multicast.rpf_group = mrpf_group;
        local_md.learning.bd_mode = learning_mode;
        local_md.ipv4.unicast_enable = ipv4_unicast_enable;
        local_md.ipv4.multicast_enable = ipv4_multicast_enable;
        local_md.ipv4.multicast_snooping = igmp_snooping_enable;
        local_md.ipv6.unicast_enable = ipv6_unicast_enable;
        local_md.ipv6.multicast_enable = ipv6_multicast_enable;
        local_md.ipv6.multicast_snooping = mld_snooping_enable;



    }

    // (port, vlan[0], vlan[1]) --> bd mapping
    table port_double_tag_to_bd_mapping {
        key = {
            local_md.ingress_port_lag_index : exact;
            hdr.vlan_tag[0].isValid() : exact;
            hdr.vlan_tag[0].vid : exact;
            hdr.vlan_tag[1].isValid() : exact;
            hdr.vlan_tag[1].vid : exact;
        }

        actions = {
            NoAction;
            port_vlan_miss;
            set_bd_properties;
        }

        const default_action = NoAction;
        implementation = bd_action_profile;
        size = double_tag_table_size;
    }

    // (port, vlan) --> bd mapping -- Following set of entres are needed:
    //   (port, 0, *)    L3 interface.
    //   (port, 1, vlan) L3 sub-interface.
    //   (port, 0, *)    Access port + untagged packet.
    //   (port, 1, vlan) Access port + packets tagged with access-vlan.
    //   (port, 1, 0)    Access port + .1p tagged packets.
    //   (port, 1, vlan) L2 sub-port.
    //   (port, 0, *)    Trunk port if native-vlan is not tagged.

    @placement_priority(2)
    table port_vlan_to_bd_mapping {
        key = {
            local_md.ingress_port_lag_index : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
            hdr.vlan_tag[0].vid : ternary;
        }

        actions = {
            NoAction;
            port_vlan_miss;
            set_bd_properties;
        }

        const default_action = NoAction;
        implementation = bd_action_profile;
        size = port_vlan_table_size;
    }

    // (*, vlan) --> bd mapping
    @placement_priority(2)
    table vlan_to_bd_mapping {
        key = {
            hdr.vlan_tag[0].vid : exact;
        }

        actions = {
            NoAction;
            port_vlan_miss;
            set_bd_properties;
        }

        const default_action = port_vlan_miss;
        implementation = bd_action_profile;
        size = vlan_table_size;
    }

    table cpu_to_bd_mapping {
        key = { hdr.cpu.ingress_bd : exact; }

        actions = {
            NoAction;
            port_vlan_miss;
            set_bd_properties;
        }

        const default_action = port_vlan_miss;
        implementation = bd_action_profile;
        size = bd_table_size;
    }

    action set_peer_link_properties() {
        local_md.flags.peer_link = true;
    }

    table peer_link {
        key = { local_md.ingress_port_lag_index : exact; }
        actions = {
            NoAction;
            set_peer_link_properties;
        }

        const default_action = NoAction;
        size = port_table_size;
    }

    apply {

        port_mirror.apply(local_md.ingress_port, SWITCH_PKT_SRC_CLONED_INGRESS, local_md.mirror);


        switch (port_mapping.apply().action_run) {






            set_port_properties : {



                    if (!port_vlan_to_bd_mapping.apply().hit) {
                        if (hdr.vlan_tag[0].isValid())
                            vlan_to_bd_mapping.apply();
                    }
# 324 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/port.p4"
                rmac.apply(hdr, local_md);

          }
        }

        // Check vlan membership
        if (hdr.vlan_tag[0].isValid() && !hdr.vlan_tag[1].isValid() && (bit<1>) local_md.flags.port_vlan_miss == 0) {
            bit<32> pv_hash_ = hash.get({local_md.ingress_port[6:0], hdr.vlan_tag[0].vid});
            local_md.flags.port_vlan_miss =
                (bool)check_vlan_membership.execute(pv_hash_);
        }




    }
}
# 353 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/port.p4"
// --------------------------------------------------------------------------------------------------------
// Fold - Use below table to 2-fold, 4-fold or arbitary-fold switch pipeline
//
// Pipeline folding involves sending packets from
// ingress pipeline X -> egress pipeline Y -> ingress pipeline Y -> egress pipeline Z ..
//
// To achieve above forwarding behavior two things are needed
// 1. Ability to send Packet from Port x in ingress pipeline X to Port y in egress pipeline Y
// 2. Ability to loopback packet on egress pipeline Y port y to ingress pipeline Y port y
//
// The below table helps achievethe first of these two tasks.
// Specifically it allows for below behavior
// fold_4_pipe:
// ===========
// On a 4-pipe system 1:1 (same port on ingress/egress pipes) forwarding across pipe <N=X> -> Pipe <N=X+1>,
// where N > 0 and N < 4. The value of N wraps around so N goes from 0,1,2,3 -> 0
//
// fold_2_pipe:
// ===========
// On a 2-pipe system 1:1 forwarding across pipe <N=X> -> Pipe <N=X+1>,
// where N > 0 and N < 2. The value of N wraps around so N goes from 0,1 -> 0
//
// set_egress_port: Arbitary/User defined forwarding/folding
// ===============
// Match on any incoming ingress port and send packet to user defined egress Pipe/Port
//
// The Fold table should be added at the end of Switching Ingress Pipeline to override port forwarding
// ---------------------------------------------------------------------------------------------------------
# 406 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/port.p4"
// ----------------------------------------------------------------------------
// Link Aggregation (LAG) resolution
//
// @param local_md : Ingress metadata fields.
// @param hash : Hash value used for port selection.
// @param egress_port : Egress port.
//
// @flag MLAG_ENABLE : Enable multi-chassis LAG.
// ----------------------------------------------------------------------------

control LAG(inout switch_local_metadata_t local_md,
            in switch_hash_t hash,
            out switch_port_t egress_port) {




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
        local_md.egress_port_lag_index = port_lag_index;
        local_md.checks.same_if = local_md.ingress_port_lag_index ^ port_lag_index;
    }

    action lag_miss() { }

    table lag {
        key = {



            local_md.egress_port_lag_index : exact @name("port_lag_index");

            hash : selector;
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
        lag.apply();
    }
}

//-----------------------------------------------------------------------------
// Egress port lookup
//
// @param hdr : Parsed headers.
// @param local_md : Egress metadata fields.
// @param port : Egress port.
//
// @flag EGRESS_PORT_MIRROR_ENABLE: Enables egress port-base mirroring.
//-----------------------------------------------------------------------------
control EgressPortMapping(
        inout switch_header_t hdr,
        inout switch_local_metadata_t local_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        in switch_port_t port)(
        switch_uint32_t table_size=288) {
    PortMirror(table_size) port_mirror;

    action port_normal(switch_port_lag_index_t port_lag_index,
                       switch_eg_port_lag_label_t port_lag_label,
                       switch_qos_group_t qos_group,
                       switch_meter_index_t meter_index,
                       switch_sflow_id_t sflow_session_id,
                       bool mlag_member) {
        local_md.egress_port_lag_index = port_lag_index;
        local_md.egress_port_lag_label = port_lag_label;
        local_md.qos.group = qos_group;
# 507 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/port.p4"
    }

    table port_mapping {
        key = { port : exact; }

        actions = {
            port_normal;
        }

        size = table_size;
    }
# 537 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/port.p4"
    apply {
        port_mapping.apply();


        port_mirror.apply(port, SWITCH_PKT_SRC_CLONED_EGRESS, local_md.mirror);




    }
}
# 588 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/port.p4"
//-----------------------------------------------------------------------------
// CPU-RX Header Insertion
//-----------------------------------------------------------------------------
control EgressCpuRewrite(
        inout switch_header_t hdr,
        inout switch_local_metadata_t local_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        in switch_port_t port)(
        switch_uint32_t table_size=288) {

    action cpu_rewrite() {
        hdr.fabric.setValid();
        hdr.fabric.reserved = 0;
        hdr.fabric.color = 0;
        hdr.fabric.qos = 0;
        hdr.fabric.reserved2 = 0;

        hdr.cpu.setValid();
        hdr.cpu.egress_queue = 0;
        hdr.cpu.tx_bypass = 0;
        hdr.cpu.capture_ts = 0;
        hdr.cpu.reserved = 0;
        hdr.cpu.ingress_port = (bit<16>) local_md.ingress_port;
        hdr.cpu.port_lag_index = (bit<16>) local_md.egress_port_lag_index;
        hdr.cpu.ingress_bd = (bit<16>) local_md.bd;
        hdr.cpu.reason_code = local_md.cpu_reason;
        hdr.cpu.ether_type = hdr.ethernet.ether_type;

        hdr.ethernet.ether_type = 0x9000;
    }

/*  CODE_HACK Workaround for P4C-3919  */



    table cpu_port_rewrite {
        key = { port : exact; }

        actions = {
            cpu_rewrite;
        }

        size = table_size;
    }

    apply {
        cpu_port_rewrite.apply();
    }
}
# 184 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/validation.p4" 1
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

// ============================================================================
// Packet validaion
// Validate ethernet, Ipv4 or Ipv6 headers and set the common lookup fields.
// ============================================================================
control PktValidation(
        in switch_header_t hdr,
        inout switch_local_metadata_t local_md) {
//-----------------------------------------------------------------------------
// Validate outer L2 header
// - Drop the packet if src addr is zero or multicast or dst addr is zero.
//-----------------------------------------------------------------------------
    const switch_uint32_t table_size = MIN_TABLE_SIZE;

    action valid_ethernet_pkt(switch_pkt_type_t pkt_type) {
        local_md.lkp.pkt_type = pkt_type;
        local_md.lkp.mac_dst_addr = hdr.ethernet.dst_addr;
    }

    action malformed_eth_pkt(bit<8> reason) {
        local_md.lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        local_md.lkp.mac_type = hdr.ethernet.ether_type;
        local_md.l2_drop_reason = reason;
    }

    action valid_pkt_untagged(switch_pkt_type_t pkt_type) {
        local_md.lkp.mac_type = hdr.ethernet.ether_type;
        valid_ethernet_pkt(pkt_type);
    }

    action valid_pkt_tagged(switch_pkt_type_t pkt_type) {
        local_md.lkp.mac_type = hdr.vlan_tag[0].ether_type;
        local_md.lkp.pcp = hdr.vlan_tag[0].pcp;
        valid_ethernet_pkt(pkt_type);
    }

    action valid_pkt_double_tagged(switch_pkt_type_t pkt_type) {
        local_md.lkp.mac_type = hdr.vlan_tag[1].ether_type;
        local_md.lkp.pcp = hdr.vlan_tag[1].pcp;
        valid_ethernet_pkt(pkt_type);
    }

    table validate_ethernet {
        key = {
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
            hdr.vlan_tag[0].isValid() : ternary;



        }

        actions = {
            malformed_eth_pkt;
            valid_pkt_untagged;
            valid_pkt_tagged;



        }

        size = table_size;
    }

//-----------------------------------------------------------------------------
// Validate outer L3 header
// - Drop the packet if src addr is zero or multicast or dst addr is zero.
//-----------------------------------------------------------------------------

    action valid_arp_pkt() {





        local_md.lkp.arp_opcode = hdr.arp.opcode;
    }

    // IP Packets
    action valid_ipv6_pkt(bool is_link_local) {
        // Set common lookup fields
        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        local_md.lkp.ip_tos = hdr.ipv6.traffic_class;
        local_md.lkp.ip_proto = hdr.ipv6.next_hdr;
        local_md.lkp.ip_ttl = hdr.ipv6.hop_limit;
        local_md.lkp.ip_src_addr = hdr.ipv6.src_addr;
        local_md.lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        local_md.lkp.ipv6_flow_label = hdr.ipv6.flow_label;
        local_md.flags.link_local = is_link_local;
    }

    action valid_ipv4_pkt(switch_ip_frag_t ip_frag, bool is_link_local) {
        // Set common lookup fields
        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        local_md.lkp.ip_tos = hdr.ipv4.diffserv;
        local_md.lkp.ip_proto = hdr.ipv4.protocol;
        local_md.lkp.ip_ttl = hdr.ipv4.ttl;
        local_md.lkp.ip_src_addr[63:0] = 64w0;
        local_md.lkp.ip_src_addr[95:64] = hdr.ipv4.src_addr;
        local_md.lkp.ip_src_addr[127:96] = 32w0;
        local_md.lkp.ip_dst_addr[63:0] = 64w0;
        local_md.lkp.ip_dst_addr[95:64] = hdr.ipv4.dst_addr;
        local_md.lkp.ip_dst_addr[127:96] = 32w0;
        local_md.lkp.ip_frag = ip_frag;
        local_md.flags.link_local = is_link_local;
    }

    action malformed_ipv4_pkt(bit<8> reason, switch_ip_frag_t ip_frag) {
        // Set common lookup fields just for dtel acl and hash purposes
        valid_ipv4_pkt(ip_frag, false);
        local_md.drop_reason = reason;
    }

    action malformed_ipv6_pkt(bit<8> reason) {
        // Set common lookup fields just for dtel acl and hash purposes
        valid_ipv6_pkt(false);
        local_md.drop_reason = reason;
    }
# 174 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/validation.p4"
    table validate_ip {
        key = {
            hdr.arp.isValid() : ternary;
            hdr.ipv4.isValid() : ternary;
            local_md.flags.ipv4_checksum_err : ternary;
            hdr.ipv4.version : ternary;
            hdr.ipv4.ihl : ternary;
            hdr.ipv4.flags : ternary;
            hdr.ipv4.frag_offset : ternary;
            hdr.ipv4.ttl : ternary;
            hdr.ipv4.src_addr[31:0] : ternary;

            hdr.ipv6.isValid() : ternary;
            hdr.ipv6.version : ternary;
            hdr.ipv6.hop_limit : ternary;
            hdr.ipv6.src_addr[127:0] : ternary;







        }

        actions = {
            malformed_ipv4_pkt;
            malformed_ipv6_pkt;
            valid_arp_pkt;
            valid_ipv4_pkt;
            valid_ipv6_pkt;







        }

        size = table_size;
    }

//-----------------------------------------------------------------------------
// Set L4 and other lookup fields
//-----------------------------------------------------------------------------
    action set_tcp_ports() {
        local_md.lkp.l4_src_port = hdr.tcp.src_port;
        local_md.lkp.l4_dst_port = hdr.tcp.dst_port;
        local_md.lkp.tcp_flags = hdr.tcp.flags;
        local_md.lkp.hash_l4_src_port = hdr.tcp.src_port;
        local_md.lkp.hash_l4_dst_port = hdr.tcp.dst_port;
    }

    action set_udp_ports() {
        local_md.lkp.l4_src_port = hdr.udp.src_port;
        local_md.lkp.l4_dst_port = hdr.udp.dst_port;
        local_md.lkp.tcp_flags = 0;
        local_md.lkp.hash_l4_src_port = hdr.udp.src_port;
        local_md.lkp.hash_l4_dst_port = hdr.udp.dst_port;
    }

    action set_icmp_type() {
        local_md.lkp.l4_src_port[7:0] = hdr.icmp.type;
        local_md.lkp.l4_src_port[15:8] = hdr.icmp.code;
        local_md.lkp.l4_dst_port = 0;
        local_md.lkp.tcp_flags = 0;
        local_md.lkp.hash_l4_src_port[7:0] = hdr.icmp.type;
        local_md.lkp.hash_l4_src_port[15:8] = hdr.icmp.code;
        local_md.lkp.hash_l4_dst_port = 0;
    }

    action set_igmp_type() {
        local_md.lkp.l4_src_port[7:0] = hdr.igmp.type;
        local_md.lkp.l4_src_port[15:8] = 0;
        local_md.lkp.l4_dst_port = 0;
        local_md.lkp.tcp_flags = 0;
        local_md.lkp.hash_l4_src_port = 0;
        local_md.lkp.hash_l4_dst_port = 0;
    }

    // Not much of a validation as it only sets the lookup fields.
    table validate_other {
        key = {
            hdr.tcp.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.icmp.isValid() : exact;
            hdr.igmp.isValid() : exact;
        }

        actions = {
            NoAction;
            set_tcp_ports;
            set_udp_ports;
            set_icmp_type;



        }

        const default_action = NoAction;
        const entries = {
            (true, false, false, false) : set_tcp_ports();
            (false, true, false, false) : set_udp_ports();
            (false, false, true, false) : set_icmp_type();



        }
        size = 16;
    }

    apply {
        validate_ethernet.apply();
        validate_ip.apply();
        validate_other.apply();
    }
}

// ============================================================================
// Same MAC Check
// Checks if source mac address matches with destination mac address
// ============================================================================
control SameMacCheck(in switch_header_t hdr, inout switch_local_metadata_t local_md) {

    action compute_same_mac_check() {
        local_md.drop_reason = SWITCH_DROP_REASON_OUTER_SAME_MAC_CHECK;
    }

    @ways(1)
    table same_mac_check {
        key = {
            local_md.same_mac : exact;
        }
        actions = {
            NoAction;
            compute_same_mac_check;
        }
        const default_action = NoAction;
        const entries = {
            (48w0x0) : compute_same_mac_check();
        }
    }

    apply {
        local_md.same_mac = hdr.ethernet.src_addr ^ hdr.ethernet.dst_addr;
        same_mac_check.apply();
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
control InnerPktValidation(
        in switch_header_t hdr,
        inout switch_local_metadata_t local_md) {

    action valid_ethernet_pkt(switch_pkt_type_t pkt_type) {




        local_md.lkp.pkt_type = pkt_type;
    }

    action valid_ipv4_pkt(switch_pkt_type_t pkt_type) {
        // Set the common IP lookup fields



        local_md.lkp.mac_type = 0x0800;
        local_md.lkp.pkt_type = pkt_type;
        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;



        local_md.lkp.ip_ttl = hdr.inner_ipv4.ttl;
        local_md.lkp.ip_proto = hdr.inner_ipv4.protocol;
        local_md.lkp.ip_src_addr[63:0] = 64w0;
        local_md.lkp.ip_src_addr[95:64] = hdr.inner_ipv4.src_addr;
        local_md.lkp.ip_src_addr[127:96] = 32w0;
        local_md.lkp.ip_dst_addr[63:0] = 64w0;
        local_md.lkp.ip_dst_addr[95:64] = hdr.inner_ipv4.dst_addr;
        local_md.lkp.ip_dst_addr[127:96] = 32w0;
    }

    action valid_ipv6_pkt(switch_pkt_type_t pkt_type) {

        // Set the common IP lookup fields



        local_md.lkp.mac_type = 0x86dd;
        local_md.lkp.pkt_type = pkt_type;
        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;



        local_md.lkp.ip_ttl = hdr.inner_ipv6.hop_limit;
        local_md.lkp.ip_proto = hdr.inner_ipv6.next_hdr;
        local_md.lkp.ip_src_addr = hdr.inner_ipv6.src_addr;
        local_md.lkp.ip_dst_addr = hdr.inner_ipv6.dst_addr;
        local_md.lkp.ipv6_flow_label = hdr.inner_ipv6.flow_label;
        local_md.flags.link_local = false;

    }

    action set_tcp_ports() {
        local_md.lkp.l4_src_port = hdr.inner_tcp.src_port;
        local_md.lkp.l4_dst_port = hdr.inner_tcp.dst_port;
        local_md.lkp.hash_l4_src_port = hdr.inner_tcp.src_port;
        local_md.lkp.hash_l4_dst_port = hdr.inner_tcp.dst_port;
    }

    action set_udp_ports() {
        local_md.lkp.l4_src_port = hdr.inner_udp.src_port;
        local_md.lkp.l4_dst_port = hdr.inner_udp.dst_port;
        local_md.lkp.hash_l4_src_port = hdr.inner_udp.src_port;
        local_md.lkp.hash_l4_dst_port = hdr.inner_udp.dst_port;
    }

    action valid_ipv4_tcp_pkt(switch_pkt_type_t pkt_type) {
        // Set the common L2 lookup fields
        valid_ipv4_pkt(pkt_type);
        set_tcp_ports();
    }

    action valid_ipv4_udp_pkt(switch_pkt_type_t pkt_type) {
        // Set the common L2 lookup fields
        valid_ipv4_pkt(pkt_type);
        set_udp_ports();
    }

    action valid_ipv6_tcp_pkt(switch_pkt_type_t pkt_type) {
        // Set the common L2 lookup fields
        valid_ipv6_pkt(pkt_type);
        set_tcp_ports();
    }

    action valid_ipv6_udp_pkt(switch_pkt_type_t pkt_type) {
        // Set the common L2 lookup fields
        valid_ipv6_pkt(pkt_type);
        set_udp_ports();
    }

    action malformed_pkt(bit<8> reason) {
        local_md.drop_reason = reason;
    }

    table validate_ethernet {
        key = {
            hdr.inner_ethernet.isValid() : ternary;




            hdr.inner_ipv6.isValid() : ternary;
            hdr.inner_ipv6.version : ternary;
            hdr.inner_ipv6.hop_limit : ternary;

            hdr.inner_ipv4.isValid() : ternary;
            local_md.flags.inner_ipv4_checksum_err : ternary;
            hdr.inner_ipv4.version : ternary;
            hdr.inner_ipv4.ihl : ternary;
            hdr.inner_ipv4.ttl : ternary;

            hdr.inner_tcp.isValid() : ternary;
            hdr.inner_udp.isValid() : ternary;

        }

        actions = {
            NoAction;
            valid_ipv4_tcp_pkt;
            valid_ipv4_udp_pkt;
            valid_ipv4_pkt;
            valid_ipv6_tcp_pkt;
            valid_ipv6_udp_pkt;
            valid_ipv6_pkt;



            malformed_pkt;
        }
        size = MIN_TABLE_SIZE;
    }

    apply {
        validate_ethernet.apply();
    }
}
# 185 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4" 1

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
# 186 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4" 1
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
# 187 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/multicast.p4" 1
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
# 442 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/multicast.p4"
//-----------------------------------------------------------------------------
// Multicast flooding
//-----------------------------------------------------------------------------
control MulticastFlooding(inout switch_local_metadata_t local_md)(switch_uint32_t table_size) {

    action flood(switch_mgid_t mgid) {
        local_md.multicast.id = mgid;
    }

    table bd_flood {
        key = {
            local_md.bd : exact @name("bd");
            local_md.lkp.pkt_type : exact @name("pkt_type");



        }

        actions = { flood; }
        size = table_size;
    }

    apply {
        bd_flood.apply();
    }
}

//-----------------------------------------------------------------------------
// Egress Multicast Replication DB
//-----------------------------------------------------------------------------
control MulticastReplication(in switch_rid_t replication_id,
                             in switch_port_t port,
                             inout switch_local_metadata_t local_md)(
                             switch_uint32_t table_size=4096) {
    action rid_hit(switch_bd_t bd) {
        local_md.checks.same_bd = bd ^ local_md.bd;
        local_md.bd = bd;
    }

    action rid_miss() {
        local_md.flags.routed = false;
    }

    table rid {
        key = { replication_id : exact; }
        actions = {
            rid_miss;
            rid_hit;
        }

        size = table_size;
        const default_action = rid_miss;
    }

    apply {
# 506 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/multicast.p4"
    }
}
# 188 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/qos.p4" 1
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




# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4" 1
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
# 27 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/qos.p4" 2

//-------------------------------------------------------------------------------------------------
// ECN Access control list
//
// @param local_md : Ingress metadata fields.
// @param lkp : Lookup fields.
// @param pkt_color : Packet color
// @param table_size : Size of the ACL table.
//-------------------------------------------------------------------------------------------------
control ECNAcl(in switch_local_metadata_t local_md,
               in switch_lookup_fields_t lkp,
               inout switch_pkt_color_t pkt_color)(
               switch_uint32_t table_size=512) {
    action set_ingress_color(switch_pkt_color_t color) {
        pkt_color = color;
    }

    table acl {
        key = {
            local_md.ingress_port_lag_label : ternary;
            lkp.ip_tos : ternary;
            lkp.tcp_flags : ternary;
        }

        actions = {
            NoAction;
            set_ingress_color;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// PFC Watchdog
// Once PFC storm is detected on a queue, the PFC watchdog can drop or forward at per queue level.
// On drop action, all existing packets in the output queue and all subsequent packets destined to
// the output queue are discarded.
//
// @param port
// @param qid : Queue Id.
// @param table_size : Size of the ACL table.
//-------------------------------------------------------------------------------------------------
control PFCWd(in switch_port_t port,
               in switch_qid_t qid,
               out bool flag)(
               switch_uint32_t table_size=512) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action acl_deny() {
        flag = true;
        stats.count();
    }

    @ways(2)
    table acl {
        key = {
            qid : exact;
            port : exact;
        }

        actions = {
            @defaultonly NoAction;
            acl_deny;
        }

        const default_action = NoAction;
        counters = stats;
        size = table_size;
    }

    apply {

        acl.apply();

    }
}

//-------------------------------------------------------------------------------------------------
// Ingress QosMap
// QoS Classification - map dscp/cos/exp -> tc, color
//-------------------------------------------------------------------------------------------------
control IngressQoSMap(inout switch_header_t hdr,
                      inout switch_local_metadata_t local_md)(
        switch_uint32_t dscp_map_size=2048,
        switch_uint32_t pcp_map_size=256) {

    action set_ingress_tc(switch_tc_t tc) {
        local_md.qos.tc = tc;
    }

    action set_ingress_color(switch_pkt_color_t color) {
        local_md.qos.color = color;
    }

    action set_ingress_tc_and_color(
            switch_tc_t tc, switch_pkt_color_t color) {
        set_ingress_tc(tc);
        set_ingress_color(color);
    }

    table dscp_tc_map {
        key = {
            local_md.qos.group : exact;
            local_md.lkp.ip_tos[7:2] : exact;
        }

        actions = {
            NoAction;
            set_ingress_tc;
            set_ingress_color;
            set_ingress_tc_and_color;
        }

        size = dscp_map_size;
    }

    table pcp_tc_map {
        key = {
            local_md.qos.group : exact;
            local_md.lkp.pcp : exact;
        }

        actions = {
            NoAction;
            set_ingress_tc;
            set_ingress_color;
            set_ingress_tc_and_color;
        }

        size = pcp_map_size;
    }

    table exp_tc_map {
        key = {
            local_md.qos.group : exact;
            hdr.mpls[0].exp : exact;
        }

        actions = {
            NoAction;
            set_ingress_tc;
            set_ingress_color;
            set_ingress_tc_and_color;
        }

        size = pcp_map_size;
    }

    apply {





        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_QOS != 0) && local_md.qos.trust_mode & SWITCH_QOS_TRUST_MODE_TRUST_DSCP ==
            SWITCH_QOS_TRUST_MODE_TRUST_DSCP && local_md.lkp.ip_type != SWITCH_IP_TYPE_NONE) {
            dscp_tc_map.apply();
        } else if(!(local_md.bypass & SWITCH_INGRESS_BYPASS_QOS != 0) && local_md.qos.trust_mode & SWITCH_QOS_TRUST_MODE_TRUST_PCP ==
                  SWITCH_QOS_TRUST_MODE_TRUST_PCP && hdr.vlan_tag[0].isValid()) {
            pcp_tc_map.apply();
        }
    }
}

//-------------------------------------------------------------------------------------------------
// Ingress QosMap
// QoS Classification - map Traffic Class -> icos, qid
//-------------------------------------------------------------------------------------------------
control IngressTC(inout switch_local_metadata_t local_md)() {

    const bit<32> tc_table_size = 1024;

    action set_icos(switch_cos_t icos) {
        local_md.qos.icos = icos;
    }

    action set_queue(switch_qid_t qid) {
        local_md.qos.qid = qid;
    }

    action set_icos_and_queue(switch_cos_t icos, switch_qid_t qid) {
        set_icos(icos);
        set_queue(qid);
    }

    table traffic_class {
        key = {
            local_md.ingress_port : ternary @name("port");
            local_md.qos.color : ternary @name("color");
            local_md.qos.tc : exact @name("tc");
        }

        actions = {
            set_icos;
            set_queue;
            set_icos_and_queue;
        }

        size = tc_table_size;
    }

    apply {

        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_QOS != 0)) {
            traffic_class.apply();
        }

    }
}

//-------------------------------------------------------------------------------------------------
// Ingress per PPG Packet and Byte Stats
//-------------------------------------------------------------------------------------------------
control PPGStats(inout switch_local_metadata_t local_md)() {

    const bit<32> ppg_table_size = 1024;
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) ppg_stats;
    action count() {
        ppg_stats.count();
    }

    // Asymmetric table to maintain statistics per local port and cos pair.
    @ways(2)
    table ppg {
        key = {
            local_md.ingress_port : exact @name("port");
            local_md.qos.icos : exact @name("icos");
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        size = ppg_table_size;
        counters = ppg_stats;
    }

    apply {
        ppg.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// Egress QoS Marking
// {TC, Color} -> DSCP/PCP
//-------------------------------------------------------------------------------------------------
control EgressQoS(inout switch_header_t hdr,
                  in switch_port_t port,
                  inout switch_local_metadata_t local_md)(
                  switch_uint32_t table_size=1024) {
    // Overwrites 6-bit dscp only.
    action set_ipv4_dscp(bit<6> dscp, bit<3> exp) {
        hdr.ipv4.diffserv[7:2] = dscp;
        local_md.tunnel.mpls_encap_exp = exp;
    }

    action set_ipv4_tos(switch_uint8_t tos, bit<3> exp) {
        hdr.ipv4.diffserv = tos;
        local_md.tunnel.mpls_encap_exp = exp;
    }

    // Overwrites 6-bit dscp only.
    action set_ipv6_dscp(bit<6> dscp, bit<3> exp) {

        hdr.ipv6.traffic_class[7:2] = dscp;
        local_md.tunnel.mpls_encap_exp = exp;

    }

    action set_ipv6_tos(switch_uint8_t tos, bit<3> exp) {

        hdr.ipv6.traffic_class = tos;
        local_md.tunnel.mpls_encap_exp = exp;

    }

    action set_vlan_pcp(bit<3> pcp, bit<3> exp) {
        hdr.vlan_tag[0].pcp = pcp;
        local_md.tunnel.mpls_encap_exp = exp;
    }

    table qos_map {
        key = {
            local_md.qos.group : ternary @name("group");
            local_md.qos.tc : ternary @name("tc");
            local_md.qos.color : ternary @name("color");
            hdr.ipv4.isValid() : ternary;
            hdr.ipv6.isValid() : ternary;
        }

        actions = {
            NoAction;
            set_ipv4_dscp;
            set_ipv4_tos;
            set_ipv6_dscp;
            set_ipv6_tos;
            set_vlan_pcp;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {

        if (!local_md.flags.bypass_egress) {
            qos_map.apply();
        }

    }
}

//-------------------------------------------------------------------------------------------------
// Per Queue Stats
//-------------------------------------------------------------------------------------------------
control EgressQueue(in switch_port_t port,
                    inout switch_local_metadata_t local_md)(
                    switch_uint32_t queue_table_size=1024) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) queue_stats;

    action count() {
        queue_stats.count();
    }

    // Asymmetric table to maintain statistics per local port and queue pair. This table does NOT
    // take care of packets that get dropped or sent to cpu by system acl.



    @ways(2)
    table queue {
        key = {
            port : exact;
            local_md.qos.qid : exact @name("qid");
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        size = queue_table_size;
        const default_action = NoAction;
        counters = queue_stats;
    }

    apply {
        queue.apply();
    }
}
# 189 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/meter.p4" 1
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




# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4" 1
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
# 27 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/meter.p4" 2

//-------------------------------------------------------------------------------------------------
// Storm Control
//
// Monitors incoming traffic and prevents the excessive traffic on a particular interface by
// dropping the traffic. Each port has a single storm control levels for all types of traffic
// (broadcast, multicast, and unicast).
//
// @param local_md : Ingress metadata fields
// @param pkt_type : One of Unicast, Multicast, or Broadcast packet types.
// @param flag : Indicating whether the packet should get dropped or not.
// @param table_size : Size of the storm control table [per pipe]
// @param meter_size : Size of storm control meters [global pool]
// Stats table size must be 512 per pipe - each port with 6 stat entries [2 colors per pkt-type]
//-------------------------------------------------------------------------------------------------
control StormControl(inout switch_local_metadata_t local_md,
                     in switch_pkt_type_t pkt_type,
                     out bool flag)(
                     switch_uint32_t table_size=256,
                     switch_uint32_t meter_size=1024) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS) storm_control_stats;
    Meter<bit<16>>(meter_size, MeterType_t.PACKETS) meter;

    action count() {
        storm_control_stats.count();
        flag = false;
    }

    action drop_and_count() {
        storm_control_stats.count();
        flag = true;
    }

    table stats {
        key = {
            local_md.qos.storm_control_color: exact;
            pkt_type : ternary;
            local_md.ingress_port: exact;
            local_md.flags.dmac_miss : ternary;
        }

        actions = {
            @defaultonly NoAction;
            count;
            drop_and_count;
        }

        const default_action = NoAction;
        size = table_size*2;
        counters = storm_control_stats;
    }

    action set_meter(bit<16> index) {
        local_md.qos.storm_control_color = (bit<2>) meter.execute(index);
    }

    table storm_control {
        key = {
            local_md.ingress_port : exact;
            pkt_type : ternary;
            local_md.flags.dmac_miss : ternary;
        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {







    }
}

//-------------------------------------------------------------------------------------------------
// Ingress Mirror Meter
//-------------------------------------------------------------------------------------------------
control IngressMirrorMeter(inout switch_local_metadata_t local_md)(
                     switch_uint32_t table_size=256) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;
    Meter<bit<9>>(table_size, MeterType_t.PACKETS) meter;
    switch_pkt_color_t color;

    action mirror_and_count() {
        stats.count();
    }

    action no_mirror_and_count() {
        stats.count();
        local_md.mirror.type = 0;
    }

    @ways(2)
    table meter_action {
        key = {
            color: exact;
            local_md.mirror.meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            mirror_and_count;
            no_mirror_and_count;
        }

        const default_action = NoAction;
        size = table_size*2;
        counters = stats;
    }

    action set_meter(bit<9> index) {
        color = (bit<2>) meter.execute(index);
    }

    table meter_index {
        key = {
            local_md.mirror.meter_index : exact;
        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {




    }
}

//-------------------------------------------------------------------------------------------------
// Egress Mirror Meter
//-------------------------------------------------------------------------------------------------
control EgressMirrorMeter(inout switch_local_metadata_t local_md)(
                     switch_uint32_t table_size=256) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;
    Meter<bit<9>>(table_size, MeterType_t.PACKETS) meter;
    switch_pkt_color_t color;

    action mirror_and_count() {
        stats.count();
    }

    action no_mirror_and_count() {
        stats.count();
        local_md.mirror.type = 0;
    }

    @ways(2)
    table meter_action {
        key = {
            color: exact;
            local_md.mirror.meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            mirror_and_count;
            no_mirror_and_count;
        }

        const default_action = NoAction;
        size = table_size*2;
        counters = stats;
    }

    action set_meter(bit<9> index) {
        color = (bit<2>) meter.execute(index);
    }

    table meter_index {
        key = {
            local_md.mirror.meter_index : exact;
        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {




    }
}
# 190 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/wred.p4" 1
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

//-------------------------------------------------------------------------------------------------
// Weighted Random Early Dropping (WRED)
//
// @param hdr : Parse headers. Only ipv4.diffserv or ipv6.traffic_class are modified.
// @param local_md : Egress metadata fields.
// @param eg_intr_md
// @param flag : A flag indicating that the packet should get dropped by system ACL.
//-------------------------------------------------------------------------------------------------
control WRED(inout switch_header_t hdr,
             in switch_local_metadata_t local_md,
             in egress_intrinsic_metadata_t eg_intr_md,
             out bool wred_drop) {

    switch_wred_index_t index;

    // Flag indicating that the packet needs to be marked/dropped.
    bit<1> wred_flag;
    const switch_uint32_t wred_size = 1 << 10;

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    Wred<bit<19>, switch_wred_index_t>(wred_size, 1 /* drop value*/, 0 /* no drop value */) wred;

    // -----------------------------------------------------------
    // Select a profile and apply wred filter
    // A total of 1k profiles are supported.
    // -----------------------------------------------------------
    action set_wred_index(switch_wred_index_t wred_index) {
        index = wred_index;
        wred_flag = (bit<1>) wred.execute(local_md.qos.qdepth, wred_index);
    }

    // Asymmetric table to get the attached WRED profile.
    table wred_index {
        key = {
           eg_intr_md.egress_port : exact @name("port");
           local_md.qos.qid : exact @name("qid");
           local_md.qos.color : exact @name("color");
        }

        actions = {
            NoAction;
            set_wred_index;
        }

        const default_action = NoAction;
        size = wred_size;
    }

    // -----------------------------------------------------------
    // Mark or Drop packet based on WRED profile and ECN bits
    // -----------------------------------------------------------
    action set_ipv4_ecn() {
        hdr.ipv4.diffserv[1:0] = SWITCH_ECN_CODEPOINT_CE;
        wred_drop = false;
    }

    action set_ipv6_ecn() {
        hdr.ipv6.traffic_class[1:0] = SWITCH_ECN_CODEPOINT_CE;
        wred_drop = false;
    }

    // Packets from flows that are not ECN capable will continue to be dropped by RED (as was the
    // case before ECN) -- RFC2884
    action drop() {
        wred_drop = true;
    }

    table v4_wred_action {
        key = {
            index : exact;
            hdr.ipv4.diffserv[1:0] : exact;
        }

        actions = {
            NoAction;
            drop;
            set_ipv4_ecn;
        }

        // Requires 3 entries per WRED profile to drop or mark IPv4 packets.
        size = 3 * wred_size;
    }

    table v6_wred_action {
        key = {
            index : exact;
            hdr.ipv6.traffic_class[1:0] : exact;
        }

        actions = {
            NoAction;
            drop;
            set_ipv6_ecn;
        }

        // Requires 3 entries per WRED profile to drop or mark IPv6 packets.
        size = 3 * wred_size;
    }

    // -----------------------------------------------------------------------------------------------
    // Counts packets marked or dropped by WRED. Packets "allowed" by wred logic are not counted here.
    // -----------------------------------------------------------------------------------------------
    action count() { stats.count(); }

    @ways(2)
    table wred_stats {
        key = {
            eg_intr_md.egress_port : exact @name("port");
            local_md.qos.qid : exact @name("qid");
            local_md.qos.color : exact @name("color");
            wred_drop : exact;
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        size = 2 * wred_size;
        counters = stats;
    }

    apply {

        if (!local_md.flags.bypass_egress)
            wred_index.apply();

        if (!local_md.flags.bypass_egress && wred_flag == 1) {
            if(hdr.ipv4.isValid()) {
                switch(v4_wred_action.apply().action_run) {
                    NoAction : {}
                    default : { wred_stats.apply(); }
                }
            } else if(hdr.ipv6.isValid()) {
                switch(v6_wred_action.apply().action_run) {
                    NoAction : {}
                    default : { wred_stats.apply(); }
                }
            }
        }

    }
}
# 191 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/acl.p4" 1
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
# 192 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/dtel.p4" 1
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

// Data-plane telemetry (DTel).

//-----------------------------------------------------------------------------
// Deflect on drop configuration checks if deflect on drop is enabled for a given queue/port pair.
// DOD must be only enabled for unicast traffic.
//
// @param report_type : Telemetry report type.
// @param ig_intr_for_tm : Ingress metadata fiels consumed by traffic manager.
// @param table_size
//-----------------------------------------------------------------------------
control DeflectOnDrop(
        in switch_local_metadata_t local_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(
        switch_uint32_t table_size=1024) {

    action enable_dod() {
        ig_intr_md_for_tm.deflect_on_drop = 1w1;
    }

    action disable_dod() {
        ig_intr_md_for_tm.deflect_on_drop = 1w0;
    }

    table config {
        key = {
            local_md.dtel.report_type : ternary;
            ig_intr_md_for_tm.ucast_egress_port : ternary @name("egress_port");
            local_md.qos.qid: ternary @name("qid");



            local_md.cpu_reason : ternary; // to avoid validity issues, replaces
                                         // ig_intr_md_for_tm.copy_to_cpu
        }

        actions = {
            enable_dod;
            disable_dod;
        }

        size = table_size;
        const default_action = disable_dod;
    }

    apply {
        config.apply();
    }
}

//-----------------------------------------------------------------------------
// Mirror on drop configuration
// Checks if mirror on drop is enabled for a given drop reason.
//
// @param report_type : Telemetry report type.
// @param ig_intr_for_tm : Ingress metadata fiels consumed by traffic manager.
// @param table_size
//-----------------------------------------------------------------------------
control MirrorOnDrop(in switch_drop_reason_t drop_reason,
                     inout switch_dtel_metadata_t dtel_md,
                     inout switch_mirror_metadata_t mirror_md) {
    action mirror() {
        mirror_md.type = 3;
        mirror_md.src = SWITCH_PKT_SRC_CLONED_INGRESS;
    }

    action mirror_and_set_d_bit() {
        dtel_md.report_type = dtel_md.report_type | SWITCH_DTEL_REPORT_TYPE_DROP;
        mirror_md.type = 3;
        mirror_md.src = SWITCH_PKT_SRC_CLONED_INGRESS;
    }

    table config {
        key = {
            drop_reason : ternary;
            dtel_md.report_type : ternary;
        }

        actions = {
            NoAction;
            mirror;
            mirror_and_set_d_bit;
        }

        const default_action = NoAction;
        // const entries = {
        //    (SWITCH_DROP_REASON_UNKNOWN, _) : NoAction();
        //    (_, SWITCH_DTEL_REPORT_TYPE_DROP &&& SWITCH_DTEL_REPORT_TYPE_DROP) : mirror();
        // }
    }

    apply {
        config.apply();
    }
}


//-----------------------------------------------------------------------------
// Simple bloom filter for drop report suppression to avoid generating duplicate reports.
//
// @param hash : Hash value used to query the bloom filter.
// @param flag : A flag indicating that the report needs to be suppressed.
//-----------------------------------------------------------------------------
control DropReport(in switch_header_t hdr,
                   in switch_local_metadata_t local_md,
                   in bit<32> hash, inout bit<2> flag) {
    // Two bit arrays of 128K bits.
    Register<bit<1>, bit<17>>(1 << 17, 0) array1;
    Register<bit<1>, bit<17>>(1 << 17, 0) array2;
    RegisterAction<bit<1>, bit<17>, bit<1>>(array1) filter1 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    RegisterAction<bit<1>, bit<17>, bit<1>>(array2) filter2 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    apply {
        if (local_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_DROP |
                                      SWITCH_DTEL_SUPPRESS_REPORT |
                                      SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE)
            == SWITCH_DTEL_REPORT_TYPE_DROP
            && hdr.dtel_drop_report.isValid())
            flag[0:0] = filter1.execute(hash[(17 - 1):0]);
        if (local_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_DROP |
                                      SWITCH_DTEL_SUPPRESS_REPORT |
                                      SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE)
            == SWITCH_DTEL_REPORT_TYPE_DROP
            && hdr.dtel_drop_report.isValid())
            flag[1:1] = filter2.execute(hash[31:(32 - 17)]);

    }
}

//-----------------------------------------------------------------------------
// Generates queue reports if hop latency (or queue depth) exceeds a configurable thresholds.
// Quota-based report suppression to avoid generating excessive amount of reports.
// @param port : Egress port
// @param qid : Queue Id.
// @param qdepth : Queue depth.
//-----------------------------------------------------------------------------
struct switch_queue_alert_threshold_t {
    bit<32> qdepth;
    bit<32> latency;
}

struct switch_queue_report_quota_t {
    bit<32> counter;
    bit<32> latency; // Qunatized latency
}

// Quota policy -- The policy maintains counters to track the number of generated reports.

// @param flag : indicating whether to generate a telemetry report or not.
control QueueReport(inout switch_local_metadata_t local_md,
                    in egress_intrinsic_metadata_t eg_intr_md,
                    out bit<1> qalert) {
    // Quota for a (port, queue) pair.
    bit<16> quota_;
    const bit<32> queue_table_size = 1024;
    const bit<32> queue_register_size = 2048;

    // Register to store latency/qdepth thresholds per (port, queue) pair.
    Register<switch_queue_alert_threshold_t, bit<16>>(queue_register_size) thresholds;
    RegisterAction<switch_queue_alert_threshold_t, bit<16>, bit<1>>(thresholds) check_thresholds = {
        void apply(inout switch_queue_alert_threshold_t reg, out bit<1> flag) {
            // Set the flag if either of qdepth or latency exceeds the threshold.
            if (reg.latency <= local_md.dtel.latency || reg.qdepth <= (bit<32>) local_md.qos.qdepth) {
                flag = 1;
            }
        }
    };

    action set_qmask(bit<32> quantization_mask) {
        // Quantize the latency.
        local_md.dtel.latency = local_md.dtel.latency & quantization_mask;
    }
    action set_qalert(bit<16> index, bit<16> quota, bit<32> quantization_mask) {
        qalert = check_thresholds.execute(index);
        quota_ = quota;
        set_qmask(quantization_mask);
    }
    @ways(2)
    table queue_alert {
        key = {
            local_md.qos.qid : exact @name("qid");
            local_md.egress_port : exact @name("port");
        }

        actions = {
            set_qalert;
            set_qmask;
        }

        size = queue_table_size;
    }

    // Register to store last observed quantized latency and a counter to track available quota.
    Register<switch_queue_report_quota_t, bit<16>>(queue_register_size) quotas;
    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) reset_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            flag = 0;
            reg.counter = (bit<32>) quota_[15:0];
        }
    };

    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) check_latency_and_update_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            // Send a report if number of generated reports is not exceeding the quota
            if (reg.counter > 0) {
                reg.counter = reg.counter - 1;
                flag = 1;
            }

            // Send a report if quantized latency is changed.
            if (reg.latency != local_md.dtel.latency) {
                reg.latency = local_md.dtel.latency;
                flag = 1;
            }
        }
    };

    // This is only used for deflected packets.
    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) update_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            // Send a report if number of generated reports is not exceeding the quota
            if (reg.counter > 0) {
                reg.counter = reg.counter - 1;
                flag = 1;
            }
        }
    };


    action reset_quota_(bit<16> index) {
        qalert = reset_quota.execute(index);
    }

    action update_quota_(bit<16> index) {
        qalert = update_quota.execute(index);
    }

    action check_latency_and_update_quota_(bit<16> index) {
        qalert = check_latency_and_update_quota.execute(index);
    }

    table check_quota {
        key = {
            local_md.pkt_src : exact;
            qalert : exact;
            local_md.qos.qid : exact @name("qid");
            local_md.egress_port : exact @name("port");
        }

        actions = {
            NoAction;
            reset_quota_;
            update_quota_;
            check_latency_and_update_quota_;
        }

        const default_action = NoAction;
        size = 3 * queue_table_size;
    }

    apply {
        if (local_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
            queue_alert.apply();
        check_quota.apply();
    }
}


control FlowReport(in switch_local_metadata_t local_md, out bit<2> flag) {
    bit<16> digest;

    Hash<bit<16>>(HashAlgorithm_t.CRC16) hash;

    // Two bit arrays of 32K bits. The probability of false positive is about 1% for 4K flows.
    Register<bit<16>, bit<16>>(1 << 16, 0) array1;
    Register<bit<16>, bit<16>>(1 << 16, 0) array2;

    // Encodes 2 bit information for flow state change detection
    // rv = 0b1* : New flow.
    // rv = 0b01 : No change in digest is detected.

    @reduction_or_group("filter")
    RegisterAction<bit<16>, bit<16>, bit<2>>(array1) filter1 = {
        void apply(inout bit<16> reg, out bit<2> rv) {
            if (reg == 16w0) {
               rv = 0b10;
            } else if (reg == digest) {
                rv = 0b01;
            }
            reg = digest;
        }
    };

    @reduction_or_group("filter")
    RegisterAction<bit<16>, bit<16>, bit<2>>(array2) filter2 = {
        void apply(inout bit<16> reg, out bit<2> rv) {
            if (reg == 16w0) {
               rv = 0b10;
            } else if (reg == digest) {
                rv = 0b01;
            }
            reg = digest;
        }
    };

    apply {




        digest = hash.get({local_md.dtel.latency, local_md.ingress_port, local_md.egress_port, local_md.dtel.hash});
        if (local_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_FLOW | SWITCH_DTEL_SUPPRESS_REPORT) == SWITCH_DTEL_REPORT_TYPE_FLOW
            && local_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
            flag = filter1.execute(local_md.dtel.hash[15:0]);
        if (local_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_FLOW | SWITCH_DTEL_SUPPRESS_REPORT) == SWITCH_DTEL_REPORT_TYPE_FLOW
            && local_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
            /* CODE_HACK Workaround for reduction_or_group not working */
            flag = flag | filter2.execute(local_md.dtel.hash[31:16]);

    }
}

control IngressDtel(in switch_header_t hdr,
                    in switch_lookup_fields_t lkp,
                    inout switch_local_metadata_t local_md,
                    in bit<16> hash,
                    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                    inout ingress_intrinsic_metadata_for_tm_t ig_intr_for_tm) {

    DeflectOnDrop() dod;
    MirrorOnDrop() mod;

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionProfile(DTEL_SELECTOR_TABLE_SIZE) dtel_action_profile;
    ActionSelector(dtel_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   DTEL_MAX_MEMBERS_PER_GROUP,
                   DTEL_GROUP_TABLE_SIZE) session_selector;
    action set_mirror_session(switch_mirror_session_t session_id) {
        local_md.dtel.session_id = session_id;
    }

    table mirror_session {
        key = {
            hdr.ethernet.isValid() : ternary;
            hash : selector;
        }
        actions = {
            NoAction;
            set_mirror_session;
        }

        implementation = session_selector;
    }

    apply {


        dod.apply(local_md, ig_intr_for_tm);

        if (local_md.mirror.type == 0)
            mod.apply(local_md.drop_reason, local_md.dtel, local_md.mirror);


        mirror_session.apply();

    }
}


control DtelConfig(inout switch_header_t hdr,
                   inout switch_local_metadata_t local_md,
                   inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Register<bit<32>, switch_mirror_session_t>(1024) seq_number;
    RegisterAction<bit<32>, switch_mirror_session_t, bit<32>>(seq_number) get_seq_number = {
        void apply(inout bit<32> reg, out bit<32> rv) {
# 421 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/dtel.p4"
            reg = reg + 1;

            rv = reg;
        }
    };

    action mirror_switch_local() {
        // Generate switch local telemetry report for flow/queue reports.
        local_md.mirror.type = 4;
        local_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
    }

    action mirror_switch_local_and_set_q_bit() {
        local_md.dtel.report_type = local_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_QUEUE;
        mirror_switch_local();
    }

    action mirror_switch_local_and_drop() {
        mirror_switch_local();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action mirror_switch_local_and_set_f_bit_and_drop() {
        local_md.dtel.report_type = local_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_FLOW;
        mirror_switch_local();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action mirror_switch_local_and_set_q_f_bits_and_drop() {
        local_md.dtel.report_type = local_md.dtel.report_type | (
            SWITCH_DTEL_REPORT_TYPE_QUEUE | SWITCH_DTEL_REPORT_TYPE_FLOW);
        mirror_switch_local();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action mirror_drop() {
        // Generate telemetry drop report.
        local_md.mirror.type = 3;
        local_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
    }

    action mirror_drop_and_set_q_bit() {
        local_md.dtel.report_type = local_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_QUEUE;
        mirror_drop();
    }

    action mirror_clone() {
        // Generate (sampled) clone on behalf of downstream IFA capable devices
        local_md.mirror.type = 5;
        local_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        local_md.dtel.session_id = local_md.dtel.clone_session_id;
    }

    action drop() {
        // Drop the report.
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action update(
            switch_dtel_switch_id_t switch_id,
            switch_dtel_hw_id_t hw_id,




            bit<4> next_proto,

            switch_dtel_report_type_t report_type) {
        hdr.dtel.setValid();
        hdr.dtel.hw_id = hw_id;
        hdr.dtel.switch_id = switch_id;
        hdr.dtel.d_q_f = (bit<3>) report_type;
# 503 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/dtel.p4"
        hdr.dtel.version = 0;
        hdr.dtel.next_proto = next_proto;
        hdr.dtel.reserved = 0;
        hdr.dtel.seq_number = get_seq_number.execute(local_md.mirror.session_id);
        hdr.dtel.timestamp = (bit<32>) local_md.ingress_timestamp;

    }

    action update_and_mirror_truncate(
            switch_dtel_switch_id_t switch_id,
            switch_dtel_hw_id_t hw_id,
            bit<4> next_proto,
            bit<8> md_length,
            bit<16> rep_md_bits,
            switch_dtel_report_type_t report_type) {



        update(switch_id, hw_id, next_proto, report_type);

        local_md.mirror.type = 5;
        local_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        // Drop the report.
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action update_and_set_etrap(
            switch_dtel_switch_id_t switch_id,
            switch_dtel_hw_id_t hw_id,
            bit<4> next_proto,
            bit<8> md_length,
            bit<16> rep_md_bits,
            switch_dtel_report_type_t report_type,
            bit<2> etrap_status) {
        hdr.dtel.setValid();
        hdr.dtel.hw_id = hw_id;
        hdr.dtel.switch_id = switch_id;
        hdr.dtel.d_q_f = (bit<3>) report_type;
# 552 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/dtel.p4"
        hdr.dtel.version = 0;
        hdr.dtel.next_proto = next_proto;
        hdr.dtel.reserved[14:13] = etrap_status; // etrap indication
        hdr.dtel.seq_number = get_seq_number.execute(local_md.mirror.session_id);
        hdr.dtel.timestamp = (bit<32>) local_md.ingress_timestamp;

    }

    action set_ipv4_dscp_all(bit<6> dscp) {
        hdr.ipv4.diffserv[7:2] = dscp;
    }

    action set_ipv6_dscp_all(bit<6> dscp) {

        hdr.ipv6.traffic_class[7:2] = dscp;

    }

    action set_ipv4_dscp_2(bit<1> dscp_bit_value) {
        hdr.ipv4.diffserv[2:2] = dscp_bit_value;
    }

    action set_ipv6_dscp_2(bit<1> dscp_bit_value) {

        hdr.ipv6.traffic_class[2:2] = dscp_bit_value;

    }

    action set_ipv4_dscp_3(bit<1> dscp_bit_value) {
        hdr.ipv4.diffserv[3:3] = dscp_bit_value;
    }

    action set_ipv6_dscp_3(bit<1> dscp_bit_value) {

        hdr.ipv6.traffic_class[3:3] = dscp_bit_value;

    }

    action set_ipv4_dscp_4(bit<1> dscp_bit_value) {
        hdr.ipv4.diffserv[4:4] = dscp_bit_value;
    }

    action set_ipv6_dscp_4(bit<1> dscp_bit_value) {

        hdr.ipv6.traffic_class[4:4] = dscp_bit_value;

    }

    action set_ipv4_dscp_5(bit<1> dscp_bit_value) {
        hdr.ipv4.diffserv[5:5] = dscp_bit_value;
    }

    action set_ipv6_dscp_5(bit<1> dscp_bit_value) {

        hdr.ipv6.traffic_class[5:5] = dscp_bit_value;

    }

    action set_ipv4_dscp_6(bit<1> dscp_bit_value) {
        hdr.ipv4.diffserv[6:6] = dscp_bit_value;
    }

    action set_ipv6_dscp_6(bit<1> dscp_bit_value) {

        hdr.ipv6.traffic_class[6:6] = dscp_bit_value;

    }

    action set_ipv4_dscp_7(bit<1> dscp_bit_value) {
        hdr.ipv4.diffserv[7:7] = dscp_bit_value;
    }

    action set_ipv6_dscp_7(bit<1> dscp_bit_value) {

        hdr.ipv6.traffic_class[7:7] = dscp_bit_value;

    }

    /* config table is responsible for triggering the flow/queue report generation for normal
     * traffic and updating the dtel report headers for telemetry reports.
     *
     * pkt_src        report_type     drop_ flow_ queue drop_  drop_ action
     *                                flag  flag  _flag reason report
     *                                                         valid
     * CLONED_INGRESS DROP | SUPPRESS *     *     *     *      y     update(df)
     *                | FLOW
     * CLONED_INGRESS DROP | FLOW     0b11  *     *     *      y     drop
     * CLONED_INGRESS DROP | FLOW     *     *     *     *      y     update(df)
     * CLONED_INGRESS DROP | SUPPRESS *     *     *     *      y     update(d)
     * CLONED_INGRESS DROP            0b11  *     *     *      y     drop
     * CLONED_INGRESS DROP            *     *     *     *      y     update(d)
     *
     * DEFLECTED      DROP | SUPPRESS *     *     1     *      *     update(dqf)
     *                | FLOW
     * DEFLECTED      DROP | FLOW     0b11  *     1     *      *     update(dqf)
     * DEFLECTED      DROP | FLOW     *     *     1     *      *     update(dqf)
     * DEFLECTED      DROP | SUPPRESS *     *     *     *      *     update(df)
     *                | FLOW
     * DEFLECTED      DROP | FLOW     0b11  *     *     *      *     drop
     * DEFLECTED      DROP | FLOW     *     *     *     *      *     update(df)
     * DEFLECTED      DROP | SUPPRESS *     *     1     *      *     update(dq)
     * DEFLECTED      DROP            0b11  *     1     *      *     update(dq)
     * DEFLECTED      DROP            *     *     1     *      *     update(dq)
     * DEFLECTED      DROP | SUPPRESS *     *     *     *      *     update(d)
     * DEFLECTED      DROP            0b11  *     *     *      *     drop
     * DEFLECTED      DROP            *     *     *     *      *     update(d)
     * DEFLECTED      *               *     *     0     *      *     drop
     * DEFLECTED      *               *     *     1     *      *     update(q)
     *
     * CLONED_EGRESS  FLOW | QUEUE    *     *     *     *      n     update(qf)
     * CLONED_EGRESS  QUEUE           *     *     *     *      n     update(q)
     * CLONED_EGRESS  FLOW            *     *     *     *      n     update(f)
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(dqf)
     *                | FLOW | QUEUE
     * CLONED_EGRESS  DROP            0b11  *     *     *      y     update(dqf)
     *                | FLOW | QUEUE
     * CLONED_EGRESS  DROP            *     *     *     *      y     update(dqf)
     *                | FLOW | QUEUE
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(df)
     *                | FLOW
     * CLONED_EGRESS  DROP | FLOW     0b11  *     *     *      y     drop
     * CLONED_EGRESS  DROP | FLOW     *     *     *     *      y     update(df)
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(dq)
     *                | QUEUE
     * CLONED_EGRESS  DROP | QUEUE    0b11  *     *     *      y     update(dq)
     * CLONED_EGRESS  DROP | QUEUE    *     *     *     *      y     update(dq)
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(d)
     * CLONED_EGRESS  DROP            0b11  *     *     *      y     drop
     * CLONED_EGRESS  DROP            *     *     *     *      y     update(d)
     *
     * BRIDGED        FLOW | SUPPRESS *     *     1     0      *     mirror_sw
     * BRIDGED        FLOW            *     0b00  1     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     0b1*  1     0      *     mirror_sw_l
     * BRIDGED        *               *     *     1     0      *     mirror_sw_l
     * BRIDGED        FLOW | SUPPRESS *     *     *     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     0b00  *     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     0b1*  *     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     TCPfl *     0      *     mirror_sw_l
     *
     * BRIDGED        DROP            *     *     *     0      *     NoAction
     * User specified entries for egress drop_reason values: mirror or NoAction
     * BRIDGED        DROP            *     *     1     value  *     mirror_drop
     * BRIDGED        DROP            *     *     *     value  *     action
     * BRIDGED        *               *     *     1     value  *     mirror_sw_l
     * Drop report catch all entries
     * BRIDGED        DROP            *     *     1     *      *     mirror_drop
     * BRIDGED        DROP            *     *     *     *      *     mirror_drop
     * BRIDGED        *               *     *     1     *      *     mirror_sw_l
     *
     * *              *               *     *     *     *      *     NoAction
     * This table is asymmetric as hw_id is pipe specific.
     */

    /* SwitchEgress.dtel_config.config should be programmed to only
     * trigger a mirror action when the incoming local_md.mirror.type == 0,
     * whereas SwitchEgress.system_acl.copp only clears local_md.mirror_type
     * when the incoming value == SWITCH_MIRROR_TYPE_CPU. It is not possible
     * for both tables to trigger a mirror action for the same packet. */
    @ignore_table_dependency("SwitchEgress.system_acl.copp")
    table config {
        key = {
            local_md.pkt_src : ternary;
            local_md.dtel.report_type : ternary;
            local_md.dtel.drop_report_flag : ternary;
            local_md.dtel.flow_report_flag : ternary;
            local_md.dtel.queue_report_flag : ternary;
            local_md.drop_reason : ternary;
            local_md.mirror.type : ternary;
            hdr.dtel_drop_report.isValid() : ternary;

            local_md.lkp.tcp_flags[2:0] : ternary;
# 735 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/dtel.p4"
        }

        actions = {
            NoAction;
            drop;
            mirror_switch_local;
            mirror_switch_local_and_set_q_bit;
            mirror_drop;
            mirror_drop_and_set_q_bit;
            update;
# 772 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/dtel.p4"
        }

        const default_action = NoAction;
    }

    apply {
        config.apply();
    }
}

control IntEdge(inout switch_local_metadata_t local_md)(
                switch_uint32_t port_table_size=288) {

    action set_clone_mirror_session_id(switch_mirror_session_t session_id) {
        local_md.dtel.clone_session_id = session_id;
    }

    action set_ifa_edge() {
        local_md.dtel.report_type = local_md.dtel.report_type | SWITCH_DTEL_IFA_EDGE;
    }

    table port_lookup {
        key = {
            local_md.egress_port : exact;
        }
        actions = {
            NoAction;
            set_clone_mirror_session_id;
            set_ifa_edge;
        }

        const default_action = NoAction;
        size = port_table_size;
    }

    apply {
        if (local_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
            port_lookup.apply();
    }
}

control EgressDtel(inout switch_header_t hdr,
                   inout switch_local_metadata_t local_md,
                   in egress_intrinsic_metadata_t eg_intr_md,
                   in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                   in bit<32> hash) {
    DropReport() drop_report;
    QueueReport() queue_report;
    FlowReport() flow_report;
    IntEdge() int_edge;

    action convert_ingress_port(switch_port_t port) {



        hdr.dtel_report.ingress_port = port;

    }

    table ingress_port_conversion {
        key = {




          hdr.dtel_report.ingress_port : exact @name("port");
          hdr.dtel_report.isValid() : exact @name("dtel_report_valid");

        }
        actions = {
            NoAction;
            convert_ingress_port;
        }

        const default_action = NoAction;
    }

    action convert_egress_port(switch_port_t port) {



        hdr.dtel_report.egress_port = port;

    }

    table egress_port_conversion {
        key = {




          hdr.dtel_report.egress_port : exact @name("port");
          hdr.dtel_report.isValid() : exact @name("dtel_report_valid");

        }
        actions = {
            NoAction;
            convert_egress_port;
        }

        const default_action = NoAction;
    }

    action update_dtel_timestamps() {
        local_md.dtel.latency = eg_intr_md_from_prsr.global_tstamp[31:0] -
                             local_md.ingress_timestamp[31:0];



        local_md.egress_timestamp = eg_intr_md_from_prsr.global_tstamp[31:0];

    }

    apply {

        update_dtel_timestamps();
        if (local_md.pkt_src == SWITCH_PKT_SRC_DEFLECTED && hdr.dtel_drop_report.isValid())



            local_md.egress_port = hdr.dtel_report.egress_port;

        ingress_port_conversion.apply();
        egress_port_conversion.apply();


        queue_report.apply(local_md, eg_intr_md, local_md.dtel.queue_report_flag);



        /* if DTEL_QUEUE_REPORT_ENABLE,
         * flow_report must come after queue_report,
         * since latency masking is done in table queue_alert */
        flow_report.apply(local_md, local_md.dtel.flow_report_flag);



        drop_report.apply(hdr, local_md, hash, local_md.dtel.drop_report_flag);
# 930 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/dtel.p4"
    }
}
# 193 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2
# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/sflow.p4" 1
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

struct switch_sflow_info_t {
    bit<32> current;
    bit<32> rate;
}

//------------------------------------------------------------------------------
// Ingress Sample Packet (sflow)
// @param local_md : Ingress metadata fields.
//------------------------------------------------------------------------------
control IngressSflow(inout switch_local_metadata_t local_md) {
    const bit<32> sflow_session_size = 256;

    Register<switch_sflow_info_t, bit<32>>(sflow_session_size) samplers;
    RegisterAction<switch_sflow_info_t, bit<8>, bit<1>>(samplers) sample_packet = {
        void apply(inout switch_sflow_info_t reg, out bit<1> flag) {
            if (reg.current > 0) {
                reg.current = reg.current - 1;
            } else {
                reg.current = reg.rate;
                flag = 1;
            }
        }
    };

    apply {






    }
}

//------------------------------------------------------------------------------
// Egress Sample Packet (sflow)
// @param local_md : Egress metadata fields.
//------------------------------------------------------------------------------
control EgressSflow(inout switch_local_metadata_t local_md) {
    const bit<32> sflow_session_size = 256;

    Register<switch_sflow_info_t, bit<32>>(sflow_session_size) samplers;
    RegisterAction<switch_sflow_info_t, bit<8>, bit<1>>(samplers) sample_packet = {
        void apply(inout switch_sflow_info_t reg, out bit<1> flag) {
            if (reg.current > 0) {
                reg.current = reg.current - 1;
            } else {
                reg.current = reg.rate;
                flag = 1;
            }
        }
    };

    apply {






    }
}
# 194 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2



# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/sfc_ghost.p4" 1
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

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const bit<1> ghost_total_cnt_idx = 1;

// TODO: This is Tofino2 only (9 bit per port, 7 bit per queue)
const const_t sfc_ingress_queue_idx_cnt = 32w0xffff;
//const const_t sfc_queue_threshold_idx_cnt = 1 << SFC_QUEUE_THRESHOLD_IDX_BITS;
const const_t sfc_queue_threshold_idx_cnt = 8;

// ---------------------------------------------------------------------------
// Common registers and variables for ping-pong tables
// ---------------------------------------------------------------------------

Register<bit<1>, sfc_ingress_queue_idx_t>(sfc_ingress_queue_idx_cnt) sfc_reg_qdepth;

//-----------------------------------------------------------------------------
// Initialize the ghost_metadata by copying the values form the intrinsice meta
// data header (this seems to be required because of a bug as of 2020-11-03.
// Set the queue and buffer pool index for the incoming ghost packet.
//
// @param g_intr_md: the ghost intrinsic meta data
// @return g_md : The ghost meta data
//-----------------------------------------------------------------------------
control GhostSfcInit(in ghost_intrinsic_metadata_t g_intr_md,
                     out sfc_ghost_metadata_t g_md)
                    (const_t queue_idx_size) {

    buffer_memory_ghost_t qlength;

    DirectRegister<bit<32>>() reg_ghost_counter;

    DirectRegisterAction<bit<32>, bool>(reg_ghost_counter) ghost_counter = {
        void apply(inout bit<32> counter){
            counter = counter + 1;
        }
    };

    action do_update_stats() {
        ghost_counter.execute();
    }

    action do_check_threshold_set_q_idx(sfc_ingress_queue_idx_t ingress_port_queue_idx,
                                        buffer_memory_ghost_t qdepth_threshold) {
        do_update_stats();
        g_md.ingress_port_queue_idx = ingress_port_queue_idx;
        g_md.qdepth_threshold_remainder = qdepth_threshold |-| qlength;
    }

    action set_qlength(sfc_ingress_queue_idx_t ingress_port_queue_idx,
                       buffer_memory_ghost_t qdepth_threshold_remainder) {
        do_update_stats();
        g_md.ingress_port_queue_idx = ingress_port_queue_idx;
        g_md.qdepth_threshold_remainder = qdepth_threshold_remainder;
    }

    table ghost_set_register_idx_tbl {
        key = {
            g_intr_md.pipe_id : exact@name("tm_pipe_id");
            g_intr_md.qid[10:7] : exact@name("tm_mac_id");
            g_intr_md.qid[6:0] : exact@name("tm_mac_q_id");
        }
        actions = {
            do_update_stats;
            set_qlength;
            do_check_threshold_set_q_idx;
        }
        registers = reg_ghost_counter;
        const default_action = do_update_stats();
        size = queue_idx_size;
    }

    apply {
        qlength = g_intr_md.qlength[17:2];
        ghost_set_register_idx_tbl.apply();
    }
}

control GhostSfc(in ghost_intrinsic_metadata_t g_intr_md)
                  (const_t queue_idx_size) {

    Register<bit<32>, sfc_queue_idx_t>(queue_idx_size) reg_ghost_counter;

    RegisterAction<bit<32>, sfc_queue_idx_t, bool>(reg_ghost_counter) ghost_counter = {
        void apply(inout bit<32> counter){
            counter = counter + 1;
        }
    };

    // Ghost thread: queue depth value
    RegisterAction<bit<1>, sfc_ingress_queue_idx_t, int<1>>(sfc_reg_qdepth) qdepth_write_over = {
        void apply(inout bit<1> value) {
            value = 1w1;
        }
    };
    RegisterAction<bit<1>, sfc_ingress_queue_idx_t, int<1>>(sfc_reg_qdepth) qdepth_write_under = {
        void apply(inout bit<1> value) {
            value = 1w0;
        }
    };

    action do_set_under_threshold(sfc_ingress_queue_idx_t ingress_port_queue_idx) {
//                                  sfc_queue_idx_t queue_idx) {
//        ghost_counter.execute(queue_idx);
        qdepth_write_over.execute(ingress_port_queue_idx);
    }

    action do_set_over_threshold(sfc_ingress_queue_idx_t ingress_port_queue_idx) {
//                                 sfc_queue_idx_t queue_idx) {
//        ghost_counter.execute(queue_idx);
        qdepth_write_under.execute(ingress_port_queue_idx);
    }

    table ghost_check_threshold_tbl {
        key = {
            g_intr_md.pipe_id : exact@name("tm_pipe_id");
//            g_intr_md.qid[10:7] : exact@name("tm_mac_id");
//            g_intr_md.qid[6:0] : exact@name("tm_mac_q_id");
            g_intr_md.qid : exact@name("tm_qid");
            g_intr_md.qlength : range@name("qdepth");
        }
        actions = {
//            do_ignore_queue;
            do_set_under_threshold;
            do_set_over_threshold;
        }
//        registers = reg_ghost_counter;
        const default_action = do_set_under_threshold(0);//, 0);
        size = queue_idx_size;
    }

    apply {
        ghost_check_threshold_tbl.apply();
    }
}

//-----------------------------------------------------------------------------
// Write the per-queue and per-buffer pool utilization to the shared ping-pong
// registers from the Ghost thread.
//
// @param g_md : The ghost meta data
//-----------------------------------------------------------------------------
control GhostWriteOverThreshold(in ghost_intrinsic_metadata_t g_intr_md,
                                in sfc_ghost_metadata_t g_md) {

    // Ghost thread: queue depth value
    RegisterAction<bit<1>, sfc_ingress_queue_idx_t, int<1>>(sfc_reg_qdepth) qdepth_write_over = {
        void apply(inout bit<1> value) {
            value = 1w1;
        }
    };
    RegisterAction<bit<1>, sfc_ingress_queue_idx_t, int<1>>(sfc_reg_qdepth) qdepth_write_under = {
        void apply(inout bit<1> value) {
            value = 1w0;
        }
    };

    apply {
        if (g_md.qdepth_threshold_remainder == 0) {
            qdepth_write_over.execute(g_md.ingress_port_queue_idx);
        } else {
            qdepth_write_under.execute(g_md.ingress_port_queue_idx);
        }
    }
}




//-----------------------------------------------------------------------------
// Read the per-queue and per-buffer pool utilization to the shared ping-pong
// registers from the Ingress thread. While doing so, compare with the queue
// depth with the threshold provided in sfc and return the threshold-crossing.
//
// @param sfc : The sfc meta data
//----------------------------------------------------------------------------
control IngressReadOverThreshold(in switch_port_t egress_port,
                                 in switch_qid_t qid,
                                 in ghost_intrinsic_metadata_t g_intr_md,
                                 inout switch_sfc_local_metadata_t sfc) {


    // Ghost thread: queue depth value
    RegisterAction<bit<1>, sfc_ingress_queue_idx_t, bool>(sfc_reg_qdepth) qdepth_read = {
        void apply(inout bit<1> queue_over_threshold, out bool rv) {
            rv = (bool)queue_over_threshold;
        }
    };

    apply {
        sfc.qlength_over_threshold = qdepth_read.execute(egress_port ++ qid);
    }
}
# 198 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2

# 1 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/sfc_trigger.p4" 1
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

control IngressSfcEpochInit(in bit<32> timestamp_us,
                            out switch_sfc_local_metadata_t sfc) {

   /*
    * Dependencies:
    *   before:
    *     - IngressSfcTrigger
    *   after
    *     - N/A
    */

    Register<sfc_pause_epoch_register_t, bit<1>>(32w1, {32w0, 32w0}) reg_filter_epoch;

    /**
     * Determine if the epoch is run out and if the filter banks should be switched.
     *
     * @param tstamp: the current timestamp
     * @param epoch_duration: the duration of a new epoch
     * @return rv_bank_switch_idx: Two values in the two lsbs:
                                    [1:1] = switch bank, yes(1) or no(0)
                                    [0:0] = bank idx to use, 0 or 1
     **/
    RegisterParam<bit<32>>(0xffffffff) suppression_epoch_duration;
    RegisterAction<sfc_pause_epoch_register_t, bit<1>, bit<2>>(reg_filter_epoch) get_bank_switch_idx = {
        void apply(inout sfc_pause_epoch_register_t value, out bit<2> rv_bank_switch_idx){
            if (((timestamp_us - value.current_epoch_start)
                  > suppression_epoch_duration.read())
                || (timestamp_us < value.current_epoch_start)) {
                value.current_epoch_start = timestamp_us;
                // Invert value.bank_idx_changed[0:0]
                // Set value.bank_idx_changed[1:1] = 1
                value.bank_idx_changed = ~(value.bank_idx_changed & 32w1);
            } else {
                // Keep value.bank_idx_changed[0:0]
                // Set value.bank_idx_changed[1:1] = 0
                value.bank_idx_changed = value.bank_idx_changed & 32w1;
            }
            rv_bank_switch_idx = value.bank_idx_changed[1:0];
        }
    };

    action do_get_switch_bank_idx() {
        sfc.switch_bank_idx = get_bank_switch_idx.execute(1w0);
    }

    apply {
        do_get_switch_bank_idx();
  }
}


/*
 *
 * Dependencies:
 *   before:
 *     - IngressSfcTrigger
 *     - add_bridged_md
 *   after:
 *     - nexthop
 *     - qos_map
 *     - traffic_class
 */
control IngressSfcPrepare(in ghost_intrinsic_metadata_t g_intr_md,
                          inout switch_header_t hdr,
                          inout switch_local_metadata_t ig_md)
                          (const_t queue_idx_size) {


    IngressReadOverThreshold() ghost_read_q_over_threshold;


    Hash<bit<16>>(HashAlgorithm_t.CRC16) suppression_hash_0;
    Hash<bit<16>>(HashAlgorithm_t.RANDOM) suppression_hash_1;
    DirectCounter<bit<8>>(CounterType_t.PACKETS_AND_BYTES) stats_classify;

    action do_update_stats_classify() {
        stats_classify.count();
    }

    // Important: traffic on RDMA control TCs has to be marked
    // as ig_md.sfc.type=SfcPacketType.TcSignalEnabled
    action do_set_sfc(SfcPacketType sfc_packet_type) {
        ig_md.sfc.type = sfc_packet_type;
        do_update_stats_classify();
    }

    action do_set_no_sfc() {
        ig_md.sfc.type = SfcPacketType.None;
        do_update_stats_classify();
    }
    /* we can keep adding the header check to limit SFC takes effect only at ipv4 rocev2. */
    /* rocev2_bth is only parsed with the outer header. Checking the EtherType
       for 0x800 ensures IPv4 and the absence of VLAN tags. */
    table classify_sfc {
        key = {
            ig_md.qos.tc : exact@name("tc");
            hdr.rocev2_bth.isValid() : exact@name("bth");
            hdr.ethernet.ether_type : exact@name("ethertype");
            ig_md.flags.routed : exact@name("routed");
        }
        actions = {
            do_set_sfc;
            do_set_no_sfc;
        }
        const default_action = do_set_no_sfc;
        size = 256;
        counters = stats_classify;
    }

    action do_get_suppression_hash() {
        ig_md.sfc.suppression_hash_0 = suppression_hash_0.get({ig_md.lkp.ip_src_addr,
                                                           ig_md.lkp.ip_dst_addr,
                                                           // Yes, the next line is dscp
                                                           ig_md.lkp.ip_tos[7:2]});
        ig_md.sfc.suppression_hash_1 = suppression_hash_1.get({ig_md.lkp.ip_src_addr,
                                                           ig_md.lkp.ip_dst_addr,
                                                           // Yes, the next line is dscp
                                                           ig_md.lkp.ip_tos[7:2]});
    }

    action do_set_queue_register_idx(sfc_queue_idx_t queue_register_idx) {
        ig_md.sfc.queue_register_idx = queue_register_idx;
    }

    table set_queue_register_idx {
        key = {
            ig_md.egress_port : exact@name("port");
            ig_md.qos.qid : exact@name("qid");
        }
        actions = {
            do_set_queue_register_idx;
            NoAction;
        }
        default_action = NoAction;
        size = queue_idx_size;
    }

    apply {

        do_get_suppression_hash();

        ghost_read_q_over_threshold.apply(ig_md.egress_port,
                                          ig_md.qos.qid,
                                          g_intr_md,
                                          ig_md.sfc);

        classify_sfc.apply();
        // Set the queue index for egress processing
        set_queue_register_idx.apply();

    }
}


/*
 *
 * Dependencies:
 *   before:
 *     - N/A
 *   after:
 *     - IngressSfcEpochInit
 *     - IngressSfcPrepare
 *     - SystemAcl
 */
control IngressSfcTrigger(inout switch_local_metadata_t ig_md) {

    DirectCounter<bit<8>>(CounterType_t.PACKETS_AND_BYTES) stats_suppression;
    DirectCounter<bit<8>>(CounterType_t.PACKETS_AND_BYTES) stats_mirror;




    bit<1> fr0 = 0;
    bit<1> fr1 = 0;

    Register<bit<1>, sfc_suppression_filter_idx_t>(sfc_suppression_filter_cnt, 0) pause_filter_bank0_filter0;
    Register<bit<1>, sfc_suppression_filter_idx_t>(sfc_suppression_filter_cnt, 0) pause_filter_bank0_filter1;

    Register<bit<1>, sfc_suppression_filter_idx_t>(sfc_suppression_filter_cnt, 0) pause_filter_bank1_filter0;
    Register<bit<1>, sfc_suppression_filter_idx_t>(sfc_suppression_filter_cnt, 0) pause_filter_bank1_filter1;

    RegisterAction<bit<1>, sfc_suppression_filter_idx_t, bit<1>>(pause_filter_bank0_filter0) bank0_filter0 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    RegisterAction<bit<1>, sfc_suppression_filter_idx_t, bit<1>>(pause_filter_bank0_filter1) bank0_filter1 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    RegisterAction<bit<1>, sfc_suppression_filter_idx_t, bit<1>>(pause_filter_bank1_filter0) bank1_filter0 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    RegisterAction<bit<1>, sfc_suppression_filter_idx_t, bit<1>>(pause_filter_bank1_filter1) bank1_filter1 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    action do_update_stats_suppression() {
        stats_suppression.count();
    }

    /* Putting both register accesses in the same action fails, the compiler complains:
      The action sfc_trigger_do_check_suppression_bank0 uses Register SwitchIngress.sfc_trigger.pause_filter_bank0_filter1 but does not use Register SwitchIngress.sfc_trigger.pause_filter_bank1_filter1.
      The action sfc_trigger_do_check_suppression_bank1 uses Register SwitchIngress.sfc_trigger.pause_filter_bank1_filter1 but does not use Register SwitchIngress.sfc_trigger.pause_filter_bank0_filter1.
        The Tofino architecture requires all indirect externs to be addressed with the same expression across all actions they are used in.
        You can also try to distribute individual indirect externs into separate tables.

      Therefore, the switch statement is used to the same effect, see below.
    */
    action do_check_suppression_bank0() {
        do_update_stats_suppression();
    }
    action do_check_suppression_bank1() {
        do_update_stats_suppression();
    }

    table decide_suppression {
        key = {
            ig_md.sfc.type : ternary@name("sfc_type");
            ig_md.mirror.type : ternary@name("mirror_type");
            ig_md.drop_reason : ternary@name("drop_reason");
            ig_md.sfc.qlength_over_threshold : ternary@name("qlength_over_threshold");
            ig_md.sfc.switch_bank_idx[0:0] : ternary@name("bank_idx");

        }
        actions = {
            do_update_stats_suppression;
            do_check_suppression_bank0;
            do_check_suppression_bank1;
        }
        default_action = do_update_stats_suppression;
        size = 16;
        counters = stats_suppression;
    }

    action do_update_stats_mirror() {
        stats_mirror.count();
    }

    Register<bit<32>, bit<9>>(512,0) recirculation_port_pkt_count;
    RegisterAction<bit<32>, bit<9>, bit<32>>(recirculation_port_pkt_count) recirculation_port_pkt_count_increase = {
        void apply(inout bit<32> value, out bit<32> read_value) {
            value = value + 1;
        }
    };

    // Trigger the switch.p4 mirror logic
    action do_set_mirroring(switch_mirror_session_t sid) {
        ig_md.mirror.session_id = sid;
        // These variables trigger the switch.p4 mirror logic
        ig_md.mirror.type = 6;
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        // Statistics
        do_update_stats_mirror();
        recirculation_port_pkt_count_increase.execute(ig_md.egress_port);
    }

    table decide_mirroring {
        key = {
            ig_md.egress_port[8:7] : ternary@name("pipe_id");
            ig_md.sfc.type : ternary@name("sfc_type");
            ig_md.mirror.type : ternary@name("mirror_type");
            ig_md.drop_reason : ternary@name("drop_reason");
            ig_md.sfc.qlength_over_threshold : ternary@name("qlength_over_threshold");
            fr0 : ternary;
            fr1 : ternary;

        }
        actions = {
            do_update_stats_mirror;
            do_set_mirroring;
        }
        default_action = do_update_stats_mirror;
        size = 16;
        counters = stats_mirror;
    }


    action clear_bank0_filter0() {
        pause_filter_bank0_filter0.clear(1w0,1w0);
    }
    @hidden
    table tbl_clear_bank0_filter0 {
        key = { ig_md.sfc.switch_bank_idx: exact; }
        actions = { NoAction; clear_bank0_filter0; }
        const default_action = NoAction;
        const entries = { 2w0b11: clear_bank0_filter0(); }
    }

    action clear_bank0_filter1() {
        pause_filter_bank0_filter1.clear(1w0,1w0);
    }
    @hidden
    table tbl_clear_bank0_filter1 {
        key = { ig_md.sfc.switch_bank_idx: exact; }
        actions = { NoAction; clear_bank0_filter1; }
        const default_action = NoAction;
        const entries = { 2w0b11: clear_bank0_filter1(); }
    }

    action clear_bank1_filter0() {
        pause_filter_bank1_filter0.clear(1w0,1w0);
    }
    @hidden
    table tbl_clear_bank1_filter0 {
        key = { ig_md.sfc.switch_bank_idx: exact; }
        actions = { NoAction; clear_bank1_filter0; }
        const default_action = NoAction;
        const entries = { 2w0b10: clear_bank1_filter0(); }
    }

    action clear_bank1_filter1() {
        pause_filter_bank1_filter1.clear(1w0,1w0);
    }
    @hidden
    table tbl_clear_bank1_filter1 {
        key = { ig_md.sfc.switch_bank_idx: exact; }
        actions = { NoAction; clear_bank1_filter1; }
        const default_action = NoAction;
        const entries = { 2w0b10: clear_bank1_filter1(); }
    }


    apply {

        /* Always clear the register banks independently of the packet
           type to avoid clock overflows from having an impact on the
           suppression. */



        tbl_clear_bank0_filter0.apply();
        tbl_clear_bank0_filter1.apply();
        tbl_clear_bank1_filter0.apply();
        tbl_clear_bank1_filter1.apply();
# 396 "/mnt/p4-tests/p4_16/switch_16/p4src/shared/sfc_trigger.p4"
        // Decide if suppression filter should be run
        switch (decide_suppression.apply().action_run) {
            do_check_suppression_bank0: {
                fr0 = bank0_filter0.execute(ig_md.sfc.suppression_hash_0);
                fr1 = bank0_filter1.execute(ig_md.sfc.suppression_hash_1);
            }
            do_check_suppression_bank1: {
                fr0 = bank1_filter0.execute(ig_md.sfc.suppression_hash_0);
                fr1 = bank1_filter1.execute(ig_md.sfc.suppression_hash_1);
            }
            default: { }
        }

        // Decide to send a trigger via mirror
        decide_mirroring.apply();

    }
}


/*
 *
 * Dependencies:
 *   after:
 *     - EgressPortMapping
 */
control EgressSfc(in egress_intrinsic_metadata_t eg_intr_md,
                  in switch_qos_metadata_t qos,
                  inout switch_header_t hdr,
                  inout switch_sfc_local_metadata_t sfc)
                 (const_t queue_idx_size) {

    DirectCounter<bit<8>>(CounterType_t.PACKETS_AND_BYTES) stats_time_conversion;

    // Egress thread: queue depth value
    Register<sfc_qd_threshold_register_t, sfc_queue_idx_t>(queue_idx_size) reg_qdepth;

    /*
     * SfcPacketType.Data packet: write queue depth
     * How set qdepth_drain_cells for testing:
     * Override qdepth_drain_cells only if in the existing value the msb is not set.
     * Since the qdepth value in eg_md is 19 bits only, and the register is 32 bit,
     * the msb can only be set through the control plane. For testing, the control
     * has to write a qdepth_drain_cells value with the msb set, then data packets
     * will not override the value in the register. If the msb is not set, they will,
     * as is expected for operating SFC.
     */
    RegisterAction<sfc_qd_threshold_register_t, sfc_queue_idx_t, int<32>>(reg_qdepth) qd_write = {
        void apply(inout sfc_qd_threshold_register_t value) {
            // For testing: if the msb is set, keep the existing value.
            // Since qdepth is bit<19> it should never set this bit just by writing a normal value.
            if (value.qdepth_drain_cells < msb_set_32b) {
                value.qdepth_drain_cells = (bit<32>)(qos.qdepth |-| (bit<19>)value.target_qdepth);
            }
        }
    };

    action data_qd_write() {
        qd_write.execute(sfc.queue_register_idx);
    }

    // SfcPacketType.Trigger: read queue depth
    RegisterAction<sfc_qd_threshold_register_t, sfc_queue_idx_t, buffer_memory_egress_t>(reg_qdepth) qd_read = {
        void apply(inout sfc_qd_threshold_register_t value, out buffer_memory_egress_t rv) {
            // Cut off the testing indicator bit at [31:31]
            rv = (buffer_memory_egress_t)value.qdepth_drain_cells[18:3];
        }
    };

    action trigger_qd_read() {
        sfc.q_drain_length = qd_read.execute(sfc.queue_register_idx);
    }

    action do_time_conversion_count() {
        stats_time_conversion.count();
    }
    /*
     * 176 bytes per cell, converting draining time to 1us precision
     * 25GBE => 25,000,000,000/8/1,000,000/176 = 17.76 cells/us
     * 50GBE => 50,000,000,000/8/1,000,000/176 = 35.5 cells/us
     * 100GBE => 100,000,000,000/8/1,000,000/176 = 71 cells/us
     * Approximation of dividers
     * 25GBE: 16
     * 50GBE: 32
     * 100GBE: 64
     * For all conversions, the resulting value is guaranteed to be smaller than
     * 16 bits, which means the type case should be lossless.
     * we think 16 bit with microseconds as the unit is enough. 
     * The maximum switch buffer can support with this pause_duration_us are as follows:
     * 25GBE: 65535 us *25GBE/8.0 = 204,796KB
     * 50GBE: 65535 us *50GBE/8.0 = 409,593KB
     * 100GBE: 65535 us *100GBE/8.0 = 819,187KB  
     * As long as the switch buffer size is less than the above values, we are safe to use 16-bit pause_duration_us.
     */
    action do_calc_cells_to_pause_25g(bit<8> _sfc_pause_dscp) {
        do_time_conversion_count();
        sfc.pause_duration_us = (sfc_pause_duration_us_t)(sfc.q_drain_length >> 1);
        sfc.sfc_pause_packet_dscp = _sfc_pause_dscp;
        sfc.pause_dscp = hdr.ipv4.diffserv >> 2;
    }
    action do_calc_cells_to_pause_50g(bit<8> _sfc_pause_dscp) {
        do_time_conversion_count();
        sfc.pause_duration_us = (sfc_pause_duration_us_t)(sfc.q_drain_length >> 2);
        sfc.sfc_pause_packet_dscp = _sfc_pause_dscp;
        sfc.pause_dscp = hdr.ipv4.diffserv >> 2;
    }
    action do_calc_cells_to_pause_100g(bit<8> _sfc_pause_dscp) {
        do_time_conversion_count();
        sfc.pause_duration_us = (sfc_pause_duration_us_t)(sfc.q_drain_length >> 3);
        sfc.sfc_pause_packet_dscp = _sfc_pause_dscp;
        sfc.pause_dscp = hdr.ipv4.diffserv >> 2;
    }

    /*
     * time_conversion_factor = 1000/(512*linkspeed)
     * if link speed is 25Gbps, time_conversion_factor = 48.8
     * if link speed is 50Gbps, time_conversion_factor = 97.6
     * if link speed is 100Gbps, time_conversion_factor = 195.2
     * Approximation of multipliers
     * 25GBE: 48 = 32 + 16
     * 50GBE: 92 = 64 + 32
     * 100GBE: 196 = 128 + 64
     * 25GBE: 48 = 32 + 16; the max pause_time_us to avoid overflow is 1365; for safety, 1200;
     * 50GBE: 92 = 64 + 32; the max pause_time_us to avoid overflow is 712; for safety, 700;
     * 100GBE: 196 = 128 + 64; the max pause_time_us to avoid overflow is 334; for safety, 320;
     */

    action do_calc_pause_to_pfc_time_25g(LinkToType _link_to_type){
        do_time_conversion_count();
        sfc.multiplier_second_part = sfc.pause_duration_us << 4;
        sfc.pause_duration_us = sfc.pause_duration_us << 5;
        sfc.link_to_type = _link_to_type;
    }
    action do_calc_pause_to_pfc_time_50g(LinkToType _link_to_type){
        do_time_conversion_count();
        sfc.multiplier_second_part = sfc.pause_duration_us << 5;
        sfc.pause_duration_us = sfc.pause_duration_us << 6;
     sfc.link_to_type = _link_to_type;
    }
    action do_calc_pause_to_pfc_time_100g(LinkToType _link_to_type){
        do_time_conversion_count();
        sfc.multiplier_second_part = sfc.pause_duration_us << 6;
        sfc.pause_duration_us = sfc.pause_duration_us << 7;
     sfc.link_to_type = _link_to_type;
   }

    // Todo, this is hardcode
    action testing_conversion(sfc_pause_duration_us_t _pause_duration){
        do_time_conversion_count();
        sfc.pause_duration_us = _pause_duration;
    }

    action do_cal_pause_to_pfc_time_overflow_conversion(sfc_pause_duration_us_t _pause_duration, LinkToType _link_to_type){
        do_time_conversion_count();
        sfc.pause_duration_us = _pause_duration;
        sfc.link_to_type = _link_to_type;
    }

    table pause_time_conversion{
        key = {
            sfc.type : ternary@name("sfc_type");
            sfc.queue_register_idx: exact@name("queue_register_index");
            sfc.pause_duration_us: range@name("pause_duration_us");
        }

        actions = {
            do_time_conversion_count;
            do_calc_cells_to_pause_25g;
            do_calc_cells_to_pause_50g;
            do_calc_cells_to_pause_100g;
            do_calc_pause_to_pfc_time_25g;
            do_calc_pause_to_pfc_time_50g;
            do_calc_pause_to_pfc_time_100g;
            do_cal_pause_to_pfc_time_overflow_conversion;
            testing_conversion;
        }
        const default_action = do_time_conversion_count;
        counters = stats_time_conversion;
        size = 64;
    }

    Register<bit<32>, bit<9>>(512,0) recirculation_port_pkt_count;
    RegisterAction<bit<32>, bit<9>, bit<32>>(recirculation_port_pkt_count) recirculation_port_pkt_count_increase = {
        void apply(inout bit<32> value, out bit<32> read_value) {
            value = value + 1;
        }
    };

    apply {

        if(sfc.type == SfcPacketType.TcSignalEnabled && hdr.sfc_pause.isValid()){
            sfc.type = SfcPacketType.Signal;
        }
        recirculation_port_pkt_count_increase.execute(eg_intr_md.egress_port);
        if (sfc.type == SfcPacketType.Data) {
            data_qd_write();
        } else if (sfc.type == SfcPacketType.Trigger) {
            trigger_qd_read();
        }

        pause_time_conversion.apply();

    }
}


/*
 *
 * Dependencies:
 *   after:
 *     - EgressPortMapping
 */
control EgressSfcPacket(in egress_intrinsic_metadata_t eg_intr_md,
                        inout switch_local_metadata_t eg_md,
                        inout switch_header_t hdr,
                        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                        inout switch_sfc_local_metadata_t sfc) {

    action do_convert_to_pfc_pause(bit<8> pfc_prio_enable_bitmap) {
        hdr.ipv4.setInvalid();
        hdr.udp.setInvalid();
        hdr.sfc_pause.setInvalid();

        /*
         * PFC pkts (802.1Qbb 66B)
         *   dstmac(6B),srcmac(6B),
         *   TYPE(2B8808),Opcode(2B0101),
         *   CEV(2B),
         *   Time0-7(8*2B),Pad(28B),CRC(4B)
         */
        hdr.ethernet.src_addr = 0x000000000000; // ori_dst_mac;
        hdr.ethernet.ether_type = 0x8808;

        hdr.pfc.setValid();
        hdr.pad_112b.setValid();
        hdr.pad_96b.setValid();
        hdr.pfc.opcode = 16w0x0101;
        hdr.pfc.class_enable_vec = pfc_prio_enable_bitmap;
        hdr.pfc.tstamp0 = sfc.pause_duration_us + sfc.multiplier_second_part;
        hdr.pfc.tstamp1 = sfc.pause_duration_us + sfc.multiplier_second_part;
        hdr.pfc.tstamp2 = sfc.pause_duration_us + sfc.multiplier_second_part;
        hdr.pfc.tstamp3 = sfc.pause_duration_us + sfc.multiplier_second_part;
        hdr.pfc.tstamp4 = sfc.pause_duration_us + sfc.multiplier_second_part;
        hdr.pfc.tstamp5 = sfc.pause_duration_us + sfc.multiplier_second_part;
        hdr.pfc.tstamp6 = sfc.pause_duration_us + sfc.multiplier_second_part;
        hdr.pfc.tstamp7 = sfc.pause_duration_us + sfc.multiplier_second_part;
        eg_intr_md_for_dprsr.mtu_trunc_len = 64;
    }

    table convert_to_pfc_pause {
        key = {
            sfc.pause_dscp : ternary@name("pause_dscp");
        }
        actions = {
            NoAction;
            do_convert_to_pfc_pause;
        }
        default_action = NoAction;
        size = 64;
    }

    action gen_sfc_pause_for_rocev2(){
        hdr.fabric.setValid();
        // hdr.fabric.reserved = 0;
        // hdr.fabric.color = 0;
        // hdr.fabric.qos = 0;
        // hdr.fabric.reserved2 = 0;

        hdr.cpu.setValid();
        // hdr.cpu.egress_queue = 0;
        // hdr.cpu.tx_bypass = 0;
        // hdr.cpu.capture_ts = 0;
        // hdr.cpu.reserved = 0;
        hdr.cpu.ingress_port = (bit<16>) eg_md.ingress_port;
        hdr.cpu.port_lag_index = (bit<16>) eg_md.ingress_port_lag_index;
        //hdr.cpu.ingress_bd = (bit<16>) eg_md.bd;
        hdr.cpu.ingress_bd = 0;
        //hdr.cpu.reason_code = 0; //16w0x0002; //eg_md.cpu_reason;
        hdr.cpu.ether_type = hdr.ethernet.ether_type;

        hdr.ethernet.ether_type = 0x9000;

        bit<48> ori_src_mac;
        bit<48> ori_dst_mac;
        ori_src_mac = hdr.ethernet.src_addr;
        ori_dst_mac = hdr.ethernet.dst_addr;
        hdr.ethernet.src_addr = ori_dst_mac;
        hdr.ethernet.dst_addr = ori_src_mac;
        //hdr.ethernet.src_addr = hdr.ethernet.dst_addr;

        //L3
        bit<32> orig_src_ip;
        bit<32> orig_dst_ip;

     orig_src_ip = hdr.ipv4.src_addr;
        orig_dst_ip = hdr.ipv4.dst_addr;
        hdr.ipv4.src_addr = orig_dst_ip;
        hdr.ipv4.dst_addr = orig_src_ip;

        hdr.ipv4.total_len = 46;
        hdr.ipv4.hdr_checksum = 0;
        hdr.ipv4.diffserv = sfc.sfc_pause_packet_dscp;
        hdr.ipv4_option.setInvalid();

        // udp
        hdr.udp.length = 26;
        hdr.udp.dst_port = 1674;

        //TODO: update udp checksum sometime
        hdr.udp.checksum = 0;

        // sfc pause packet format
        hdr.sfc_pause.setValid();
        hdr.pad_112b.setValid();
        hdr.sfc_pause.dscp = sfc.pause_dscp;
        hdr.sfc_pause.duration_us = sfc.pause_duration_us;
        eg_intr_md_for_dprsr.mtu_trunc_len = 78 ; //64 bytes (sfc packet ) + 14 bytes (cpu header)
    }

    action gen_sfc_pause_for_tcp(){
        bit<48> ori_src_mac;
        bit<48> ori_dst_mac;
        ori_src_mac = hdr.ethernet.src_addr;
        ori_dst_mac = hdr.ethernet.dst_addr;
        hdr.ethernet.src_addr = ori_dst_mac;
        hdr.ethernet.dst_addr = ori_src_mac;

        //L3
        bit<32> orig_src_ip;
        bit<32> orig_dst_ip;
        orig_src_ip = hdr.ipv4.src_addr;
        orig_dst_ip = hdr.ipv4.dst_addr;
        hdr.ipv4.src_addr = orig_dst_ip;
        hdr.ipv4.dst_addr = orig_src_ip;
        hdr.ipv4.total_len = 46;
        hdr.ipv4.hdr_checksum = 0;
        hdr.ipv4_option.setInvalid();
        hdr.ipv4.diffserv = 0;

        //tcp header
        bit<16> orig_src_port;
        bit<16> orig_dst_port;
        orig_src_port = hdr.tcp.src_port;
        orig_dst_port = hdr.tcp.dst_port;
        hdr.tcp.src_port = orig_dst_port;
        hdr.tcp.dst_port = orig_src_port;
        hdr.tcp.checksum = 0;

        //yle: use the last bit in the reservation field to let tcp stack know
        // this is an SFC packet.
        // TCP_FLAGS_SFC_PAUSE = 1
        hdr.tcp.res = 1;
        //yle: reuse seq_no as the pause_time
        hdr.tcp.seq_no = (bit<32>)sfc.pause_duration_us;
        eg_intr_md_for_dprsr.mtu_trunc_len = 64;
    }
    Register<bit<32>, bit<9>>(512,0) sfc_count;
    RegisterAction<bit<32>, bit<9>, bit<32>>(sfc_count) sfc_count_increase = {
        void apply(inout bit<32> value, out bit<32> read_value) {
            value = value + 1;
        }
    };

    apply {

        if (sfc.type == SfcPacketType.Trigger) {
            if (hdr.udp.isValid()) {
                gen_sfc_pause_for_rocev2();
            } else {
                gen_sfc_pause_for_tcp();
            }
            sfc_count_increase.execute(eg_intr_md.egress_port);
        } else if (sfc.type == SfcPacketType.Signal
                   && sfc.link_to_type == LinkToType.Server) {
            convert_to_pfc_pause.apply();
        }

    }
}
# 200 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4" 2


// XXX(yumin): currently Brig may pack fields with SALU ops with
// other fields which were set by action data. Until Brig fixes
// it, it is safer to mark SALU related fields as solitary.
@pa_solitary("egress", "local_md.dtel.queue_report_flag")
@pa_solitary("ingress", "local_md.flags.ipv4_checksum_err")
@pa_no_overlay("ingress", "smac_src_move")

control SwitchIngress(
        inout switch_header_t hdr,
        inout switch_local_metadata_t local_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        in ghost_intrinsic_metadata_t g_intr_md
        ) {
    IngressPortMapping(PORT_VLAN_TABLE_SIZE, BD_TABLE_SIZE) ingress_port_mapping;
    PktValidation() pkt_validation;
    SMAC(MAC_TABLE_SIZE) smac;
    DMAC(MAC_TABLE_SIZE) dmac;
    // IngressTunnel() tunnel;
    IngressSflow() sflow;
    IngressBd(BD_TABLE_SIZE) bd_stats;
    EnableFragHash() enable_frag_hash;
    Ipv4Hash() ipv4_hash;
    Ipv6Hash() ipv6_hash;
    NonIpHash() non_ip_hash;
    Lagv4Hash() lagv4_hash;
    Lagv6Hash() lagv6_hash;
    InnerDtelv4Hash() inner_dtelv4_hash;
    InnerDtelv6Hash() inner_dtelv6_hash;
    LOU() lou;
    Fibv4(IPV4_HOST_TABLE_SIZE,
        IPV4_LPM_TABLE_SIZE,
        true,
        IPV4_LOCAL_HOST_TABLE_SIZE) ipv4_fib;
    Fibv6(IPV6_HOST_TABLE_SIZE, IPV6_LPM_TABLE_SIZE, IPV6_LPM64_TABLE_SIZE) ipv6_fib;
    IngressMacAcl(INGRESS_MAC_ACL_TABLE_SIZE) ingress_mac_acl;
    IngressIpv4Acl(INGRESS_IPV4_ACL_TABLE_SIZE) ingress_ipv4_acl;
    IngressIpv6Acl(INGRESS_IPV6_ACL_TABLE_SIZE) ingress_ipv6_acl;
    IngressIpDtelSampleAcl(INGRESS_IP_DTEL_ACL_TABLE_SIZE) ingress_ip_dtel_acl;
    IngressIpAcl(INGRESS_IP_MIRROR_ACL_TABLE_SIZE) ingress_ip_mirror_acl;
    IngressInnerIpv4Acl(INGRESS_IPV4_DTEL_ACL_TABLE_SIZE) ingress_inner_ipv4_dtel_acl;
    IngressInnerIpv6Acl(INGRESS_IPV6_DTEL_ACL_TABLE_SIZE) ingress_inner_ipv6_dtel_acl;
    ECNAcl() ecn_acl;
    PFCWd(512) pfc_wd;
    IngressQoSMap() qos_map;
    IngressTC() traffic_class;
    PPGStats() ppg_stats;
    StormControl() storm_control;
    Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
    // OuterFib() outer_fib;
    LAG() lag;
    MulticastFlooding(BD_FLOOD_TABLE_SIZE) flood;
    IngressSystemAcl() system_acl;
    IngressDtel() dtel;
//    SameMacCheck() same_mac_check;


    IngressSfcEpochInit() sfc_epoch_init;
    IngressSfcPrepare(SFC_QUEUE_IDX_SIZE) sfc_prepare;
    IngressSfcTrigger() sfc_trigger;


    apply {
        pkt_validation.apply(hdr, local_md);
        ingress_port_mapping.apply(hdr, local_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);

 //        ingress_mac_acl.apply(hdr, local_md, local_md.unused_nexthop);
        smac.apply(hdr.ethernet.src_addr, local_md, ig_intr_md_for_dprsr.digest_type);
        // tunnel.apply(hdr, local_md, local_md.lkp);

        if (local_md.flags.rmac_hit) {
            lou.apply(local_md);
            if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_L3 != 0) && local_md.lkp.ip_type == SWITCH_IP_TYPE_IPV6 && local_md.ipv6.unicast_enable) {
                ipv6_fib.apply(local_md);
            } else if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_L3 != 0) && local_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4 && local_md.ipv4.unicast_enable) {
                ipv4_fib.apply(local_md);
            } else {
                dmac.apply(local_md.lkp.mac_dst_addr, local_md);
            }
        } else {
            lou.apply(local_md);
            dmac.apply(local_md.lkp.mac_dst_addr, local_md);
        }

        if (local_md.lkp.ip_type != SWITCH_IP_TYPE_IPV4) {
            ingress_ipv6_acl.apply(local_md, local_md.acl_nexthop);
        }
        if (local_md.lkp.ip_type != SWITCH_IP_TYPE_IPV6) {
            ingress_ipv4_acl.apply(local_md, local_md.acl_nexthop);
        }
        ingress_ip_mirror_acl.apply(local_md, local_md.unused_nexthop);
        sflow.apply(local_md);

        enable_frag_hash.apply(local_md.lkp);
        if (local_md.lkp.ip_type == SWITCH_IP_TYPE_NONE) {
            non_ip_hash.apply(hdr, local_md, local_md.lag_hash);
        } else if (local_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
            lagv4_hash.apply(local_md.lkp, local_md.lag_hash);
        } else {
            lagv6_hash.apply(local_md.lkp, local_md.lag_hash);
        }

        if (local_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
            ipv4_hash.apply(local_md.lkp, local_md.hash[31:0]);
        } else {
            ipv6_hash.apply(local_md.lkp, local_md.hash[31:0]);
        }

//        same_mac_check.apply(hdr, local_md);
        nexthop.apply(local_md);
        qos_map.apply(hdr, local_md);
        traffic_class.apply(local_md);
        storm_control.apply(local_md, local_md.lkp.pkt_type, local_md.flags.storm_control_drop);
        bd_stats.apply(local_md.bd, local_md.lkp.pkt_type);
        // outer_fib.apply(local_md);

        if (local_md.egress_port_lag_index == SWITCH_FLOOD) {
            flood.apply(local_md);
        } else {
            lag.apply(local_md, local_md.lag_hash, ig_intr_md_for_tm.ucast_egress_port);
        }

        // Overwrite LAG hash with hash calculated from inner headers for vxlan transit case
        if (!local_md.tunnel.terminate) {
            if (hdr.inner_ipv4.isValid()) {
                inner_dtelv4_hash.apply(hdr, local_md, local_md.lag_hash);
            } else if (hdr.inner_ipv4.isValid()) {
                inner_dtelv6_hash.apply(hdr, local_md, local_md.lag_hash);
            }
        }

//        ecn_acl.apply(local_md, local_md.lkp, ig_intr_md_for_tm.packet_color);
        pfc_wd.apply(local_md.ingress_port, local_md.qos.qid, local_md.flags.pfc_wd_drop);

        system_acl.apply(hdr, local_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
        ppg_stats.apply(local_md);

        // DTEL watchlist. Use inner headers for tunnel packets
        if (hdr.inner_ipv4.isValid()) {
            ingress_inner_ipv4_dtel_acl.apply(hdr, local_md);
        } else if (hdr.inner_ipv6.isValid()) {
            ingress_inner_ipv6_dtel_acl.apply(hdr, local_md);
        } else {
            ingress_ip_dtel_acl.apply(local_md, local_md.unused_nexthop);
        }

        dtel.apply(
            hdr, local_md.lkp, local_md, local_md.lag_hash[15:0], ig_intr_md_for_dprsr, ig_intr_md_for_tm);




        sfc_epoch_init.apply(ig_intr_md.ingress_mac_tstamp[41:10], local_md.sfc);

        sfc_prepare.apply(g_intr_md, hdr, local_md);

        add_bridged_md(hdr.bridged_md, local_md);

        set_ig_intr_md(local_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);
# 371 "/mnt/p4-tests/p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4"
        sfc_trigger.apply(local_md);



    }
}

control SwitchEgress(
        inout switch_header_t hdr,
        inout switch_local_metadata_t local_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    EgressPortMapping() egress_port_mapping;
    EgressLOU() lou;
    EgressIpv4Acl(EGRESS_IPV4_ACL_TABLE_SIZE) egress_ipv4_acl;
    EgressIpv6Acl(EGRESS_IPV6_ACL_TABLE_SIZE) egress_ipv6_acl;
    EgressQoS() qos;
    EgressQueue() queue;
    EgressSystemAcl() system_acl;
    PFCWd(512) pfc_wd;
    EgressVRF() egress_vrf;
    EgressBD() egress_bd;
    OuterNexthop() outer_nexthop;
    EgressBDStats() egress_bd_stats;
    MirrorRewrite() mirror_rewrite;
    VlanXlate(VLAN_TABLE_SIZE, PORT_VLAN_TABLE_SIZE) vlan_xlate;
    VlanDecap() vlan_decap;
    MTU() mtu;
    WRED() wred;
    EgressDtel() dtel;
    DtelConfig() dtel_config;
    EgressCpuRewrite() cpu_rewrite;
    Neighbor() neighbor;
    SetEgIntrMd() set_eg_intr_md;

    EgressSfc(SFC_QUEUE_IDX_SIZE) sfc;
    EgressSfcPacket() sfc_packet;

    apply {
        egress_port_mapping.apply(hdr, local_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);
        // tunnel_replication.apply(eg_intr_md, local_md);
        if (local_md.pkt_src != SWITCH_PKT_SRC_BRIDGED) {
            mirror_rewrite.apply(hdr, local_md, eg_intr_md_for_dprsr);
        } else {
            if (local_md.tunnel.terminate) {
                // tunnel_decap.apply(hdr, local_md);
            } else {
                vlan_decap.apply(hdr, local_md);
            }
            qos.apply(hdr, eg_intr_md.egress_port, local_md);
            wred.apply(hdr, local_md, eg_intr_md, local_md.flags.wred_drop);
            if (local_md.flags.routed) {
                egress_vrf.apply(hdr, local_md);
            } else {
                // l2_vni_map.apply(hdr, local_md);
            }
            outer_nexthop.apply(hdr, local_md);
            // tunnel_nexthop.apply(hdr, local_md);
            // tunnel_encap.apply(hdr, local_md);
            egress_bd.apply(hdr, local_md);
            lou.apply(local_md);
            if (hdr.ipv4.isValid()) {
                egress_ipv4_acl.apply(hdr, local_md);
            } else if (hdr.ipv6.isValid()) {
                egress_ipv6_acl.apply(hdr, local_md);
            }
            // tunnel_rewrite.apply(hdr, local_md);
            neighbor.apply(hdr, local_md);

        sfc.apply(eg_intr_md, local_md.qos, hdr, local_md.sfc);


        sfc_packet.apply(eg_intr_md, local_md, hdr, eg_intr_md_for_dprsr, local_md.sfc);

            egress_bd_stats.apply(hdr, local_md);
            mtu.apply(hdr, local_md);
            vlan_xlate.apply(hdr, local_md);
            pfc_wd.apply(eg_intr_md.egress_port, local_md.qos.qid, local_md.flags.pfc_wd_drop);
        }
        dtel.apply(hdr, local_md, eg_intr_md, eg_intr_md_from_prsr, local_md.dtel.hash);
        system_acl.apply(hdr, local_md, eg_intr_md, eg_intr_md_for_dprsr);
        dtel_config.apply(hdr, local_md, eg_intr_md_for_dprsr);
        cpu_rewrite.apply(hdr, local_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);
        set_eg_intr_md.apply(local_md, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
        queue.apply(eg_intr_md.egress_port, local_md);
    }
}


control SwitchGhost(in ghost_intrinsic_metadata_t g_intr_md) {
    sfc_ghost_metadata_t g_md;

    GhostSfcInit(SFC_QUEUE_IDX_SIZE) sfc_init;
    GhostWriteOverThreshold() write_queue_buffer_util;

    apply {
        sfc_init.apply(g_intr_md, g_md);
        write_queue_buffer_util.apply(g_intr_md, g_md);
    }
}

control SwitchGhostNew(in ghost_intrinsic_metadata_t g_intr_md) {

    GhostSfc(SFC_QUEUE_IDX_SIZE) sfc;

    apply {
        sfc.apply(g_intr_md);
    }
}



Pipeline <switch_header_t, switch_local_metadata_t, switch_header_t, switch_local_metadata_t> (SwitchIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
        SwitchEgressParser(),
        SwitchEgress(),
        SwitchEgressDeparser()


        ,SwitchGhostNew()


        ) pipe;

Switch(pipe) main;
