/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/


#include <core.p4>
#include <tna.p4>  /* TOFINO1_ONLY */

@command_line("--disable-parse-max-depth-limit")

//-----------------------------------------------------------------------------
// Features.
//-----------------------------------------------------------------------------
// L2 Unicast

// #define STORM_CONTROL_ENABLE

// L3 Unicast

// #define IPV6_LPM64_ENABLE

// ACLs



// #define ACL_REDIRECT_PORT_ENABLE
// #define ACL_REDIRECT_NEXTHOP_ENABLE
// #define EGRESS_COPP_DISABLE
// #define L4_PORT_EGRESS_LOU_ENABLE
// #define EGRESS_ACL_PORT_RANGE_ENABLE
//To enable port_group in ingress ACLs.
//#define PORT_GROUP_IN_ACL_KEY_ENABLE

// Mirror
# 55 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4"
// QoS

// #define QOS_ACL_ENABLE



// DTEL
// #define DTEL_ENABLE
// #define DTEL_QUEUE_REPORT_ENABLE
// #define DTEL_DROP_REPORT_ENABLE
// #define DTEL_FLOW_REPORT_ENABLE
// #define DTEL_ACL_ENABLE

// SFLOW


// #define PORT_ISOLATION_ENABLE

// // TUNNEL



// // IGW
// #define EIP_IPV6_ENABLE


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
const bit<32> IPV4_LPM_TABLE_SIZE = 16*1024;
const bit<32> IPV4_LOCAL_HOST_TABLE_SIZE = 16*1024;
const bit<32> IPV6_HOST_TABLE_SIZE = 1024;
const bit<32> IPV6_LPM_TABLE_SIZE = 16*1024;
const bit<32> IPV6_LPM64_TABLE_SIZE = 0;

// ECMP/Nexthop
const bit<32> ECMP_GROUP_TABLE_SIZE = 512;
const bit<32> ECMP_SELECT_TABLE_SIZE = 64*ECMP_GROUP_TABLE_SIZE;
const bit<32> NEXTHOP_TABLE_SIZE = 65536;

// Ingress ACLs
const bit<32> PRE_INGRESS_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 2048;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 1024;
const bit<32> INGRESS_IP_MIRROR_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IP_DTEL_ACL_TABLE_SIZE = 512;

// Egress ACLs
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512;

// Storm Control
const bit<32> STORM_CONTROL_TABLE_SIZE = 256;

// Eip
const bit<32> EIP_TABLE_SIZE = 15000;
const bit<32> LOCAL_VTEP_TABLE_SIZE = 1024;
const bit<32> NS_INTERFACE_CLASSIFY_TABLE_SIZE = 1024;
const bit<32> TRAFFIC_CLASSIFY_TABLE_SIZE = 10240;
const bit<32> NS_ACL_TABLE_SIZE = 1000;
const bit<32> NF_TABLE_SIZE = 4096;
const bit<32> DROP_STATS_TABLE_SIZE = 1024;
const bit<32> MPLS_ACL_TABLE_SIZE = 3000;

# 1 "../../p4c-5288/shared/headers.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/


//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------




typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
const int PAD_SIZE = 32;
const int MIN_SIZE = 64;

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

header pad_h {
  bit<(PAD_SIZE*8)> data;
}
# 143 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
//#include "types.p4"
//#include "util.p4"
# 1 "../../p4c-5288/switch-tofino/largetable/table_types.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/





// ----------------------------------------------------------------------------
// GW protocols/types
//-----------------------------------------------------------------------------



typedef bit<2> gw_nat_type_t;
const gw_nat_type_t GW_NAT_TYPE_NONE = 0;
const gw_nat_type_t GW_NAT_TYPE_SNAT = 1;
const gw_nat_type_t GW_NAT_TYPE_DNAT = 2;

typedef bit<2> gw_vni_type_t;
const gw_vni_type_t GW_VNI_TYPE_NONE = 0;
const gw_vni_type_t GW_VNI_TYPE_IN = 1;
const gw_vni_type_t GW_VNI_TYPE_OUT = 2;
const gw_vni_type_t GW_VNI_TYPE_VPC = 3;

typedef bit<8> ns_interface_type_t;
const ns_interface_type_t NS_INTERFACE_TYPE_NONE = 0;
const ns_interface_type_t NS_INTERFACE_TYPE_NF_FORWARD = 1;
const ns_interface_type_t NS_INTERFACE_TYPE_NF_RETURN = 2;
const ns_interface_type_t NS_INTERFACE_TYPE_IG_METER = 3;
const ns_interface_type_t NS_INTERFACE_TYPE_EG_METER = 4;
const ns_interface_type_t NS_INTERFACE_TYPE_BACKEND = 5;
const ns_interface_type_t NS_INTERFACE_TYPE_IAAS_MIGRATE = 6;
// ...
const ns_interface_type_t NS_INTERFACE_TYPE_UNDERLAY = 15;

typedef bit<8> gw_bypass_t;






const gw_bypass_t GW_BYPASS_METER = 8w0x01 << 0;
const gw_bypass_t GW_BYPASS_NAT = 8w0x01 << 1;
const gw_bypass_t GW_BYPASS_NF = 8w0x01 << 2;
const gw_bypass_t GW_BYPASS_FIB_HOST = 8w0x01 << 4;
const gw_bypass_t GW_BYPASS_ACL_SIP = 8w0x01 << 5;

const gw_bypass_t GW_BYPASS_NONE = 8w0x00;
const gw_bypass_t GW_BYPASS_ALL = 8w0xff;


const bit<6> GW_IP_TOS = 12;

typedef bit<24> gw_tunnel_vni_t;
# 88 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
const bit<8> DEFAULT_MPLS_TTL = 8w255;





typedef bit<24> gw_if_id_t;
typedef bit<24> gw_rl_id_t;
typedef bit<24> gw_meter_id_t;
typedef bit<24> gw_nat_id_t;
typedef bit<16> gw_nf_id_t;


// ----------------------------------------------------------------------------
// Common protocols/types
//-----------------------------------------------------------------------------
# 113 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
//#define ETHERTYPE_QINQ 0x88A8 // Note: uncomment once ptf/scapy-vxlan are fixed
# 165 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
// ----------------------------------------------------------------------------
// Common table sizes
//-----------------------------------------------------------------------------

const bit<32> MIN_TABLE_SIZE = 512;

const bit<32> LAG_TABLE_SIZE = 1024;
const bit<32> LAG_GROUP_TABLE_SIZE = 256;
const bit<32> LAG_MAX_MEMBERS_PER_GROUP = 64;
const bit<32> LAG_SELECTOR_TABLE_SIZE = 16384; // 256 * 64

const bit<32> DTEL_GROUP_TABLE_SIZE = 4;
const bit<32> DTEL_MAX_MEMBERS_PER_GROUP = 64;
const bit<32> DTEL_SELECTOR_TABLE_SIZE = 256;

const bit<32> IPV4_DST_VTEP_TABLE_SIZE = 512;
const bit<32> IPV6_DST_VTEP_TABLE_SIZE = 512;



const bit<32> VNI_MAPPING_TABLE_SIZE = 1024; // 1K VRF maps


// ----------------------------------------------------------------------------
// LPM
//-----------------------------------------------------------------------------
# 256 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------
typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;
# 271 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
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




const bit<32> VRF_TABLE_SIZE = 1 << 8;
typedef bit<8> switch_vrf_t;
const switch_vrf_t SWITCH_DEFAULT_VRF = 1;




typedef bit<16> switch_nexthop_t;




typedef bit<10> switch_user_metadata_t;






typedef bit<32> switch_hash_t;

typedef bit<128> srv6_sid_t;
# 335 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
typedef bit<16> switch_xid_t;
typedef L2ExclusionId_t switch_yid_t;




typedef bit<32> switch_ig_port_lag_label_t;




typedef bit<16> switch_eg_port_lag_label_t;

typedef bit<16> switch_bd_label_t;

typedef bit<16> switch_mtu_t;

typedef bit<12> switch_stats_index_t;

typedef bit<16> switch_cpu_reason_t;
const switch_cpu_reason_t SWITCH_CPU_REASON_PTP = 0x8;
const switch_cpu_reason_t SWITCH_CPU_REASON_BFD = 0x9;

typedef bit<8> switch_fib_label_t;

typedef bit<8> switch_bridge_type_t;

struct switch_cpu_port_value_set_t {
    bit<16> ether_type;
    switch_port_t port;
}

// ----------------------------------------------------------------------------
// BFD
// ----------------------------------------------------------------------------

typedef bit<2> bfd_pkt_action_t;
const bfd_pkt_action_t BFD_PKT_ACTION_NORMAL = 0x00;
const bfd_pkt_action_t BFD_PKT_ACTION_TIMEOUT = 0x01;
const bfd_pkt_action_t BFD_PKT_ACTION_DROP = 0x02;
const bfd_pkt_action_t BFD_PKT_ACTION_INVALID = 0x03;




typedef bit<8> bfd_multiplier_t;
typedef bit<12> bfd_session_t;
typedef bit<4> bfd_pipe_t;
typedef bit<8> bfd_timer_t;

struct switch_bfd_metadata_t {
 bfd_multiplier_t tx_mult;
 bfd_multiplier_t rx_mult;
 bfd_pkt_action_t pkt_action;
 bfd_pipe_t pktgen_pipe;
 bfd_session_t session_id;
 bit<1> tx_timer_expired;
 bit<1> session_offload;
 bit<1> rx_recirc;
 bit<1> pkt_tx;
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

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
const switch_drop_reason_t SWITCH_DROP_REASON_L3_PORT_RMAC_MISS = 54;
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
const switch_drop_reason_t SWITCH_DROP_REASON_NON_ROUTABLE = 107;
const switch_drop_reason_t SWITCH_DROP_REASON_MPLS_DISABLE = 108;
const switch_drop_reason_t SWITCH_DROP_REASON_BFD = 109;
//add fo xlt
const switch_drop_reason_t SWITCH_DROP_REASON_INNER_DST_MAC_BROADCAST = 110;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_IP_MISS = 111;


typedef bit<8> gw_drop_reason_t;
const gw_drop_reason_t GW_DROP_REASON_NEXTHOP = 93;
const gw_drop_reason_t GW_DROP_REASON_FIB_MISS = 129;
const gw_drop_reason_t GW_DROP_REASON_GW_PKT_TYPE_NONE = 130;
const gw_drop_reason_t GW_DROP_REASON_EIP_MISS = 131;
const gw_drop_reason_t GW_DROP_REASON_PRIVATE_IP_MISS = 132;
const gw_drop_reason_t GW_DROP_REASON_EIP_INFO_MISS = 133;
const gw_drop_reason_t GW_DROP_REASON_ENCAP_TO_FW_MISS = 134;
const gw_drop_reason_t GW_DROP_REASON_ENCAP_TO_ENI_MISS = 135;
const gw_drop_reason_t GW_DROP_REASON_ENCAP_TO_IGW_MISS = 136;
const gw_drop_reason_t GW_DROP_REASON_EIP_IN_METER_MISS = 137;
const gw_drop_reason_t GW_DROP_REASON_EIP_OUT_METER_MISS = 138;

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

typedef bit<2> switch_packet_action_t;
const switch_packet_action_t SWITCH_PACKET_ACTION_PERMIT = 0b00;
const switch_packet_action_t SWITCH_PACKET_ACTION_DROP = 0b01;
const switch_packet_action_t SWITCH_PACKET_ACTION_COPY = 0b10;
const switch_packet_action_t SWITCH_PACKET_ACTION_TRAP = 0b11;

// Bypass flags ---------------------------------------------------------------
typedef bit<16> switch_ingress_bypass_t;
# 532 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
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
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_BFD_TX = 16w0x0001 << 15;
// Add more ingress bypass flags here.

const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ALL = 16w0x7fff;


typedef bit<16> gw_egress_bypass_t;

const gw_egress_bypass_t GW_EGRESS_BYPASS_L2 = 16w0x0001 << 0;
const gw_egress_bypass_t GW_EGRESS_BYPASS_L3 = 16w0x0001 << 1;
const gw_egress_bypass_t GW_EGRESS_BYPASS_ACL = 16w0x0001 << 2;
const gw_egress_bypass_t GW_EGRESS_BYPASS_SYSTEM_ACL = 16w0x0001 << 3;
const gw_egress_bypass_t GW_EGRESS_BYPASS_QOS = 16w0x0001 << 4;
const gw_egress_bypass_t GW_EGRESS_BYPASS_METER = 16w0x0001 << 5;
const gw_egress_bypass_t GW_EGRESS_BYPASS_STORM_CONTROL = 16w0x0001 << 6;
const gw_egress_bypass_t GW_EGRESS_BYPASS_STP = 16w0x0001 << 7;
const gw_egress_bypass_t GW_EGRESS_BYPASS_SMAC = 16w0x0001 << 8;
const gw_egress_bypass_t GW_EGRESS_BYPASS_NAT = 16w0x0001 << 9;
const gw_egress_bypass_t GW_EGRESS_BYPASS_ROUTING_CHECK = 16w0x0001 << 10;
const gw_egress_bypass_t GW_EGRESS_BYPASS_PV = 16w0x0001 << 11;
const gw_egress_bypass_t GW_EGRESS_BYPASS_BFD_TX = 16w0x0001 << 15;

const gw_egress_bypass_t GW_EGRESS_BYPASS_ALL = 16w0x7fff;


// PKT ------------------------------------------------------------------------
typedef bit<16> switch_pkt_length_t;

typedef bit<8> switch_pkt_src_t;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED = 0;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_INGRESS = 1; // mirror original ingress packet
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_EGRESS = 2; // mirror final egress packet
const switch_pkt_src_t SWITCH_PKT_SRC_DEFLECTED = 3;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_EGRESS_IN_PKT= 4; // mirror packet ingressing from TM to egress parser
const switch_pkt_src_t SWITCH_CPU_BRIDGED = 5; // cpu tunnel for xlt device
const switch_pkt_src_t SWITCH_PKT_SRC_GW_BRIDGED = 6;

typedef bit<2> switch_pkt_color_t;
const switch_pkt_color_t SWITCH_METER_COLOR_GREEN = 0;
const switch_pkt_color_t SWITCH_METER_COLOR_YELLOW = 1;
const switch_pkt_color_t SWITCH_METER_COLOR_RED = 3;

typedef bit<2> switch_pkt_type_t;
const switch_pkt_type_t SWITCH_PKT_TYPE_UNICAST = 0;
const switch_pkt_type_t SWITCH_PKT_TYPE_MULTICAST = 1;
const switch_pkt_type_t SWITCH_PKT_TYPE_BROADCAST = 2;


typedef bit<4> gw_pkt_type_t;
const gw_pkt_type_t GW_PKT_TYPE_NONE = 0;
const gw_pkt_type_t GW_PKT_TYPE_IN_FROM_INTERNET_TO_FW = 1;
const gw_pkt_type_t GW_PKT_TYPE_IN_FROM_INTERNET_TO_ENI = 2;
const gw_pkt_type_t GW_PKT_TYPE_IN_FROM_FW_TO_ENI = 3;
const gw_pkt_type_t GW_PKT_TYPE_OUT_FROM_ENI_TO_IGW = 4;
const gw_pkt_type_t GW_PKT_TYPE_OUT_FROM_ENI_TO_FW = 5;
const gw_pkt_type_t GW_PKT_TYPE_OUT_FROM_ENI_TO_INTERNET = 6;
const gw_pkt_type_t GW_PKT_TYPE_OUT_FROM_IGW_TO_FW = 7;
const gw_pkt_type_t GW_PKT_TYPE_OUT_FROM_IGW_TO_INTERNET = 8;
const gw_pkt_type_t GW_PKT_TYPE_OUT_FROM_FW_TO_INTERNET = 9;
const gw_pkt_type_t GW_PKT_TYPE_IN_FROM_INTERNET = 10;
const gw_pkt_type_t GW_PKT_TYPE_OUT_FROM_ENI = 11;
const gw_pkt_type_t GW_PKT_TYPE_ENCAP = 12;
const gw_pkt_type_t GW_PKT_TYPE_DECAP = 13;

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
# 764 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
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
typedef bit<1> switch_tunnel_mode_t;
const switch_tunnel_mode_t SWITCH_TUNNEL_MODE_PIPE = 0;
const switch_tunnel_mode_t SWITCH_TUNNEL_MODE_UNIFORM = 1;

typedef bit<4> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_INGRESS_TUNNEL_TYPE_NONE = 0;
const switch_tunnel_type_t SWITCH_INGRESS_TUNNEL_TYPE_VXLAN = 1;
const switch_tunnel_type_t SWITCH_INGRESS_TUNNEL_TYPE_IPINIP = 2;
const switch_tunnel_type_t SWITCH_INGRESS_TUNNEL_TYPE_GRE = 3;
const switch_tunnel_type_t SWITCH_INGRESS_TUNNEL_TYPE_NVGRE = 4;
const switch_tunnel_type_t SWITCH_INGRESS_TUNNEL_TYPE_MPLS = 5;
const switch_tunnel_type_t SWITCH_INGRESS_TUNNEL_TYPE_SRV6 = 6;
const switch_tunnel_type_t SWITCH_INGRESS_TUNNEL_TYPE_NVGRE_ST = 7;

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
const switch_tunnel_type_t SWITCH_EGRESS_TUNNEL_TYPE_IPV4_GRE = 10;
const switch_tunnel_type_t SWITCH_EGRESS_TUNNEL_TYPE_IPV6_GRE = 11;

typedef bit<4> packet_type_t;

const bit<8> DEFAULT_VXLAN_TTL = 8w64;
const bit<24> DEFAULT_VNI = 24w0x810000; // Decimal: 8454144
const switch_bd_t SWITCH_VXLAN_DEFAULT_BD = 65535; // bd allocated for default vrf
const mac_addr_t DEFAULT_GATEWAY_SMAC= 48w0x123456123456; // 12:34:56:12:34:56

enum switch_tunnel_term_mode_t { P2P, P2MP };
# 852 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
typedef bit<4> switch_tunnel_index_t;



typedef bit<16> switch_tunnel_ip_index_t;



typedef bit<16> switch_tunnel_nexthop_t;
typedef bit<24> switch_tunnel_vni_t;


@flexible
struct gw_flags_t {
    bool to_fpga;
    bool to_cpu;
    bool mpls_encap_outer_miss;
    bool net_type;
    bool ns_acl_miss;
    bool reverse_nat_miss;
    bool nf_miss;
}

@flexible
struct switch_table_flags_t {
    bit<2> inner_ip_type;
    bit<2> outer_ip_type;
    bit<1> to_igw;
    bit<1> to_fw;
    bit<1> to_lb;
}

struct switch_tunnel_metadata_t {
    switch_tunnel_type_t type;
    switch_tunnel_index_t index; // Egress only.
    // switch_tunnel_ip_index_t dip_index;
    // switch_tunnel_vni_t vpc_vni;
    switch_tunnel_vni_t vni;
    switch_ifindex_t ifindex;
    // switch_tunnel_mode_t qos_mode;
    // switch_tunnel_mode_t ttl_mode;
    // bit<8> encap_ttl;
    // bit<8> encap_dscp;
    bit<16> hash;
    bit<4> gw_pkt_type;
    bit<18> eid;
    ns_interface_type_t interface_type;
    bit<24> ns_id;
    bool net_type;
    bool terminate;
    bit<128> vm_vtep;
    bit<128> private_ip;
    bit<128> eip;
    bool encap;
    // bit<8> nvgre_flow_id;
    // bit<2> mpls_pop_count;
    // bit<3> mpls_push_count;
    // bit<8> mpls_encap_ttl;
    bit<3> mpls_encap_exp;
    // bit<1> mpls_swap;
    // bit<128> srh_next_sid;
    // bit<8> srh_seg_left;
    // bit<8> srh_next_hdr;
    // bit<3> srv6_seg_len;
    // bit<6> srh_hdr_len;
    // bool remove_srh;
    // bool pop_active_segment;
    // bool srh_decap_forward;
    bool eip_net_hit;
    gw_vni_type_t vni_type;
    switch_table_flags_t flags;
    bit<4> eip_zone;
    bit<4> bwp_zone;
    bit<4> igw_node;
    bit<128> src_vtep;
    bit<128> dst_vtep;
    bit<8> resv;

    gw_if_id_t ns_interface_id;
    gw_if_id_t meter_interface_id;
    bit<24> mpls_acl_rule_id;
    gw_nf_id_t nf_id;
    gw_if_id_t nf_interface_id;
    gw_nat_id_t nat_id;
    bit<24> encap_info_id;
    gw_rl_id_t rate_limit_id;
    gw_meter_id_t meter_id;
    bit<3> mpls_push_count;
}

struct switch_nvgre_value_set_t {
    bit<32> vsid_flowid;
}

//Large Table 1
// struct switch_etable_metadata_t {
//     bit<32> hash;
//     bool terminate;
//     bit<1> encap;
//     packet_type_t packet_type;
//     //bit<8> result_type;
//     switch_tunnel_type_t type;
//     switch_tunnel_vni_t vni;
//     mac_addr_t vm_mac;
//     bit<128> inner_ip;
//     bit<128> outer_ip;
//     //bit<16> hash;
//     //switch_vrf_t vrf; // 14bit in base
//     switch_ip_type_t ip_type; // 2bit
//     switch_ip_type_t inner_ip_type; // 2bit
// }

struct switch_nic_metadata_t {
    bit<1> tofino_to_nic;
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
# 995 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
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



    bit<32> timestamp;


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

// Source Flow Control related types (SFC) ------------------------------------------------

enum bit<2> LinkToType {
    Unknown = 0,
    Switch = 1,
    Server = 2
}

const bit<32> msb_set_32b = 32w0x80000000;
# 1250 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
//xlt table service type
typedef bit<5> table_enable_t;

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
# 1293 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
// @pa_mutually_exclusive("ingress", "hdr.inner_ipv4.dst_addr", "hdr.table_2_key.vm_ip")
// @pa_mutually_exclusive("ingress", "hdr.inner_ipv6.dst_addr", "hdr.table_2_key.vm_ip")

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
    bool port_isolation_packet_drop;
    bool bport_isolation_packet_drop;
    bool fib_lpm_miss;
    bool fib_drop;
    switch_packet_action_t meter_packet_action;
    bool bfd_to_cpu;
    // Add more flags here.
    //bool services;
    //bool bypass_service1;
    //bool bypass_service2;
    //bool bypass_tunnel;
    //bool bypass_rewrite;
    //bool to_fpga;
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

    // mac_addr_t mac_src_addr;
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

struct switch_compress_bridged_metadata_t {
    // user-defined metadata carried over from ingress to egress.
    switch_pkt_src_t src; //8b
    switch_bridge_type_t type; //8b

    //copied to bridge_md.acl
    bit<16> l4_src_port;
    bit<16> l4_dst_port;
    bit<8> tcp_flags;

    //copied to bridge_md.base
    switch_vrf_t vrf; //8b
    switch_tc_t tc; //8b

    bit<1> pad_0;
    switch_pkt_type_t pkt_type; //2b
    switch_qid_t qid; //5b

    //copied to bridge_md.table_result
    bit<2> pad_1;
    bit<1> tofino_to_nic;
    bool terminate; // 1bit
    bool encap; // 1bit
    gw_vni_type_t vni_type; //2b
    bool eip_net_hit;
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
# 1503 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
}

//@flexible
//struct switch_bridged_metadata_tunnel_extension_t {
//    bit<32> hash; // TODO: hash 可以考虑不传，在 GwIngress 重新计算
//    bit<18> meter_id; // TODO: 可以放到 header 里面，只从 SwitchIngress -> GwEgress
//    bit<18> eid;
//    switch_drop_reason_t drop_reason;
//    gw_pkt_type_t gw_pkt_type;
//    bool terminate;
//}

@flexible
struct switch_system_acl_drop_flags {
    bool encap_to_fw_miss;
    bool encap_to_eni_miss;
    bool encap_to_igw_miss;
    gw_pkt_type_t gw_pkt_type;
}


struct switch_bridged_metadata_table_extension_t {
    //bit<4> gw_pkt_type;
    // switch_tunnel_vni_t vni;
    // bit<128> inner_ip;
    // bit<128> outer_ip;
    bit<24> ns_id;
    switch_tunnel_vni_t vni;
    bit<32> hash;
    ns_interface_type_t interface_type;

    @flexible bool terminate;
    @flexible switch_system_acl_drop_flags drop_flags;
    @flexible gw_bypass_t bypass;
    @flexible gw_if_id_t ns_interface_id;
    @flexible gw_nat_id_t nat_policy_id;
}

@flexible
struct switch_bridged_metadata_nic_extension_t {
    bit<1> tofino_to_nic;
}

//@flexible
//struct switch_bridged_metadata_flags_extension_t {
//    bool services;
//    bool bypass_service1;
//    bool bypass_service2;
//    bool bypass_tunnel;
//    bool bypass_rewrite;
//    bool to_fpga;
//    bool hit_in_fpga;
//    bool net_type;
//    bool mpls_encap_outer_miss;
//}

header gw_bridged_metadata_h {
    gw_flags_t gw_flags;
    switch_bridged_metadata_table_extension_t tunnel;
}

@flexible
struct switch_inner_pipe_bridged_metadata_t {
    switch_tunnel_vni_t vni;
    bit<128> outer_ip;
    bit<128> inner_ip;
    bit<18> meter_id;
    bit<18> eid;
    bit<4> eip_zone;
    bit<4> bwp_zone;
    bit<4> igw_node;
    switch_table_flags_t flags;
    // switch_ip_type_t outer_ip_type; // 2bit
    // switch_ip_type_t inner_ip_type; // 2bit
    // bit<1> to_igw;
    // bit<1> to_fw;
    // bit<1> to_lb;
}

struct table_result_flags_t {
    bit<2> outer_ip_type;
    bit<2> inner_ip_type;
    bit<1> to_igw;
    bit<1> to_fw;
    bit<1> to_lb;
    bit<1> pad;
}
# 1618 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
// @pa_no_overlay("ingress", "hdr.table_1_key", "hdr.bridged_md")
// @pa_no_overlay("ingress", "hdr.table_2_key", "hdr.bridged_md")

// @pa_no_overlay("ingress", "hdr.table_1_key.pad", "hdr.bridged_md")
// @pa_no_overlay("ingress", "hdr.table_1_key.eip", "hdr.bridged_md")
// @pa_no_overlay("ingress", "hdr.table_2_key.vm_ip", "hdr.bridged_md")
// @pa_no_overlay("ingress", "hdr.table_2_key.vni", "hdr.bridged_md")
# 1636 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.vxlan.flags")
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.vxlan.reserved")
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.vxlan.vni")
@pa_mutually_exclusive("egress", "hdr.erspan.version_vlan", "hdr.vxlan.reserved2")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.vxlan.flags")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.vxlan.reserved")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.vxlan.vni")
@pa_mutually_exclusive("egress", "hdr.erspan.session_id", "hdr.vxlan.reserved2")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.vxlan.flags")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.vxlan.reserved")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.vxlan.vni")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.vxlan.reserved2")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.vxlan.flags")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.vxlan.reserved")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.vxlan.vni")
@pa_mutually_exclusive("egress", "hdr.erspan_type3.ft_d_other", "hdr.vxlan.reserved2")


@pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.erspan_type2.index")
# 1824 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
header switch_bridged_metadata_h {
    switch_pkt_src_t src;
    switch_bridge_type_t type;
    switch_bridged_metadata_t base;


    switch_bridged_metadata_acl_extension_t acl;




    //switch_bridged_metadata_table_extension_t table_result;
    switch_bridged_metadata_nic_extension_t nic;
    //switch_bridged_metadata_flags_extension_t flags;
# 1847 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
}

struct switch_port_metadata_t {
    switch_port_lag_index_t port_lag_index;
    switch_ig_port_lag_label_t port_lag_label;






}

header switch_inner_pipe_bridged_metadata_h {
    switch_inner_pipe_bridged_metadata_t fpga_result;
}

header hash_bridged_metadata_h {
    bit<32> hash;
}

header compress_bridged_metadata_h {
    switch_compress_bridged_metadata_t compress;
}

//additional header
//@pa_mutually_exclusive("ingress", "hdr.fpga_mh.table_enable", "hdr.fpga_mh.reserved", "hdr.fpga_mh.next_hdr")

header flow_trace_h {
    bit<3> up_fpga_nic_id;
    bit<4> reserved;
    switch_port_t ingress_port;

    bit<2> cpu_id;
    bit<3> down_fpga_nic_id;
    bit<2> next_hdr;
    switch_port_t egress_port;
}

header fpga_meta_h {
    bit<2> mode;
    table_enable_t table_enable;
    bit<1> next_hdr;
}

header table_1_key_h {
    bit<176> pad;
    bit<128> eip;
}

header table_1_result_h {
    bit<128> outer_ip;
    bit<128> inner_ip;
    bit<24> vni;
    bit<4> eip_zone;
    bit<4> bwp_zone;
    bit<4> igw_node;
    bit<4> pad;
    table_result_flags_t flags;
}

header table_2_key_h {
    bit<128> vm_ip;
    bit<24> vni;
}

header table_2_result_h {
    bit<128> inner_ip;
    bit<4> eip_zone;
    bit<4> igw_node;
    table_result_flags_t flags;
    bit<8> pad;
}

header cpu_meta_h {
    bit<7> reserved;
    bit<1> next_hdr;
}

header loop_flag_h {
    bit<3> flags;
    bit<5> reserved;
}

header to_fpga_h {
    bit<24> ns_id;
    switch_tunnel_vni_t vni;
    bit<16> orig_pkt_len;
    bit<128> src_addr;
    bit<128> dst_addr;
    bit<32> ecmp_hash;
    ns_interface_type_t interface_type;
    bit<7> reserved;
    bit<1> next_hdr; //0: ipv4 1: ipv6
}

header to_fpga_pading_h {
    bit<208> pad;
}

header from_fpga_h {
    bit<24> ns_id;
    ns_interface_type_t interface_type;
    bit<128> nat_ip;
    bit<128> local_vtep;
    bit<128> remote_vtep;
    switch_tunnel_vni_t vni;
    bit<128> eip;
    bit<3> reserved;
    bit<2> encap_type;
    gw_nat_type_t nat_type;
    bit<1> next_hdr;
}

header from_cpu_h {

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




@pa_alias("ingress", "local_md.ingress_outer_bd", "local_md.bd")


// Ingress/Egress metadata
struct switch_local_metadata_t {
    switch_port_t ingress_port; /* ingress port */
    switch_port_t egress_port; /* egress port */
    switch_port_lag_index_t ingress_port_lag_index; /* ingress port/lag index */
    switch_port_lag_index_t egress_port_lag_index; /* egress port/lag index */
    switch_bd_t bd;
    switch_bd_t ingress_outer_bd;
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
    switch_hostif_trap_t hostif_trap_id;
    switch_hash_fields_t hash_fields;
    switch_multicast_metadata_t multicast;
    switch_stp_metadata_t stp;
    switch_qos_metadata_t qos;
    switch_sflow_metadata_t sflow;
    switch_tunnel_metadata_t tunnel;
    switch_learning_metadata_t learning;
    switch_mirror_metadata_t mirror;
    switch_dtel_metadata_t dtel;
    switch_nic_metadata_t nic;




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
# 2096 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
    bit<16> tcp_udp_checksum;
    bool checksum_upd_udp;
    // Fix provided by Intel
    bit<128> from_fpga_snat_ip;
    bit<128> from_fpga_dnat_ip;
    bit<128> from_fpga_local_vtep;
    bit<128> from_fpga_remote_vtep;
    switch_tunnel_vni_t from_fpga_vni;
    bit<2> from_fpga_encap_type;
    gw_nat_type_t from_fpga_nat_type;
    bit<1> from_fpga_next_hdr;
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
    hash_bridged_metadata_h hash_bridged_md;
    compress_bridged_metadata_h compress_bridged_md;
    switch_bridged_metadata_h bridged_md;
    switch_inner_pipe_bridged_metadata_h inner_bridged_md;
    gw_bridged_metadata_h gw_bridged_md;
    //xlt extra header 
    flow_trace_h flow_trace;
    //fpga_meta_h fpga_mh;
    //table_1_key_h table_1_key;
    //table_1_result_h table_1_result;
    //table_2_key_h table_2_key;
    //table_2_result_h table_2_result;
    cpu_meta_h cpu_mh;
    // switch_mirror_metadata_h mirror;
    from_fpga_h from_fpga;
    to_fpga_h to_fpga;
    to_fpga_pading_h to_fpga_padding;
    ethernet_h ethernet;
    fabric_h fabric;
    loop_flag_h loop_flag;
    cpu_h cpu;
    timestamp_h timestamp;
    vlan_tag_h[2] vlan_tag;
    mpls_h[3] mpls;



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
# 2166 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
    dtel_report_v05_h dtel;
    dtel_report_base_h dtel_report;
    dtel_switch_local_report_h dtel_switch_local_report;
    dtel_drop_report_h dtel_drop_report;

    rocev2_bth_h rocev2_bth;
    gtpu_h gtp;
# 2181 "../../p4c-5288/switch-tofino/largetable/table_types.p4"
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
    pad_h pad;
}
# 146 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/switch-tofino/largetable/table_util.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/

action add_gw_bridged_md_todo(
        inout gw_bridged_metadata_h gw_bridged_md, in switch_local_metadata_t local_md) {
    gw_bridged_md.setValid();
    gw_bridged_md.tunnel.hash = local_md.lag_hash;
    gw_bridged_md.tunnel.vni = local_md.tunnel.vni;
    gw_bridged_md.tunnel.ns_id = local_md.tunnel.ns_id;
    gw_bridged_md.tunnel.interface_type = local_md.tunnel.interface_type;
    gw_bridged_md.tunnel.terminate = local_md.tunnel.terminate;
    gw_bridged_md.gw_flags.net_type = local_md.tunnel.net_type;
}

// Bridged metadata fields for Egress pipeline.
action add_bridged_md(
        inout switch_bridged_metadata_h bridged_md, in switch_local_metadata_t local_md) {
    bridged_md.setValid();
    bridged_md.src = SWITCH_PKT_SRC_GW_BRIDGED;
    bridged_md.base.ingress_port = local_md.ingress_port;
    bridged_md.base.ingress_port_lag_index = local_md.ingress_port_lag_index;
    bridged_md.base.ingress_bd = local_md.bd;
    bridged_md.base.nexthop = local_md.nexthop;
    bridged_md.base.pkt_type = local_md.lkp.pkt_type;
    bridged_md.base.routed = local_md.flags.routed;
    bridged_md.base.bypass_egress = local_md.flags.bypass_egress;
    //bridged_md.table_result.gw_pkt_type = local_md.tunnel.gw_pkt_type;
    bridged_md.nic.tofino_to_nic = local_md.nic.tofino_to_nic;
    //bridged_md.flags.bypass_service1 = true;







    bridged_md.base.cpu_reason = local_md.cpu_reason;
    bridged_md.base.timestamp = local_md.timestamp;
    bridged_md.base.tc = local_md.qos.tc;
    bridged_md.base.qid = local_md.qos.qid;
    bridged_md.base.color = local_md.qos.color;
    bridged_md.base.vrf = local_md.vrf;


    bridged_md.acl.l4_src_port = local_md.lkp.l4_src_port;
    bridged_md.acl.l4_dst_port = local_md.lkp.l4_dst_port;







    bridged_md.acl.tcp_flags = local_md.lkp.tcp_flags;
# 104 "../../p4c-5288/switch-tofino/largetable/table_util.p4"
}

//action fpga_hash_copy_bridged_md(inout hash_bridged_metadata_h hash_bridged_md2, in switch_bridged_metadata_h bridged_md2) {
//    hash_bridged_md2.hash = bridged_md2.table_result.hash;
//}

action rewrite_bridged_md(
        inout switch_bridged_metadata_h table_bridged_md, in switch_local_metadata_t local_md) {
    table_bridged_md.src = SWITCH_PKT_SRC_BRIDGED;
    table_bridged_md.base.ingress_port_lag_index = local_md.ingress_port_lag_index;
    table_bridged_md.base.nexthop = local_md.nexthop;
    table_bridged_md.base.pkt_type = local_md.lkp.pkt_type;
    table_bridged_md.base.routed = local_md.flags.routed;
    table_bridged_md.base.cpu_reason = local_md.cpu_reason;
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
# 153 "../../p4c-5288/switch-tofino/largetable/table_util.p4"
control SetEgIntrMd(inout switch_header_t hdr,
                    in switch_local_metadata_t local_md,
                    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
# 176 "../../p4c-5288/switch-tofino/largetable/table_util.p4"
        if (local_md.mirror.type != 0) {

            eg_intr_md_for_dprsr.mirror_type = (bit<3>) local_md.mirror.type;
# 187 "../../p4c-5288/switch-tofino/largetable/table_util.p4"
        }

    }
}

action mark_for_drop(inout switch_local_metadata_t local_md, switch_drop_reason_t drop_reason) {
    local_md.drop_reason = drop_reason;
}
# 147 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2

# 1 "../../p4c-5288/shared/hash.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/


# 1 "../../p4c-5288/shared/types.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/
# 21 "../../p4c-5288/shared/hash.p4" 2

// Flow hash calculation.
# 108 "../../p4c-5288/shared/hash.p4"
// If fragments, then reset hash l4 port values to zero
// For non fragments, hash l4 ports will be init to l4 port values
control EnableFragHash(inout switch_lookup_fields_t lkp) {
    apply {
        if (lkp.ip_frag != SWITCH_IP_FRAG_NON_FRAG) {
            lkp.hash_l4_dst_port = 0;
            lkp.hash_l4_src_port = 0;
        } else {
            lkp.hash_l4_dst_port = lkp.l4_dst_port;
            lkp.hash_l4_src_port = lkp.l4_src_port;
        }
    }
}

control Ipv4Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
    @name(".ipv4_hash")
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
    @name(".ipv6_hash")
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
    @name(".non_ip_hash")
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
    @name(".lag_v4_hash")
    Hash<bit<32>>(HashAlgorithm_t.CRC32) lag_v4_hash;
    bit<32> ip_src_addr = lkp.ip_src_addr[95:64];
    bit<32> ip_dst_addr = lkp.ip_dst_addr[95:64];
    bit<8> ip_proto = lkp.ip_proto;
    bit<16> l4_dst_port = lkp.hash_l4_dst_port;
    bit<16> l4_src_port = lkp.hash_l4_src_port;

    apply {
        hash[31:0] = lag_v4_hash.get({ip_src_addr,
                                   ip_dst_addr,
                                   ip_proto,
                                   l4_dst_port,
                                   l4_src_port});
    }
}
control Lagv6Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
    @name(".lag_v6_hash")
    Hash<bit<32>>(HashAlgorithm_t.CRC32) lag_v6_hash;
    bit<128> ip_src_addr = lkp.ip_src_addr;
    bit<128> ip_dst_addr = lkp.ip_dst_addr;
    bit<8> ip_proto = lkp.ip_proto;
    bit<16> l4_dst_port = lkp.hash_l4_dst_port;
    bit<16> l4_src_port = lkp.hash_l4_src_port;
    bit<20> ipv6_flow_label = lkp.ipv6_flow_label;

    apply {
        hash[31:0] = lag_v6_hash.get({

                                   ipv6_flow_label,

                                   ip_src_addr,
                                   ip_dst_addr,
                                   ip_proto,
                                   l4_dst_port,
                                   l4_src_port});
    }
}
# 228 "../../p4c-5288/shared/hash.p4"
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
    @name(".inner_dtelv4_hash")
    Hash<bit<32>>(HashAlgorithm_t.CRC32) inner_dtelv4_hash;
    bit<32> ip_src_addr = hdr.inner_ipv4.src_addr;
    bit<32> ip_dst_addr = hdr.inner_ipv4.dst_addr;
    bit<8> ip_proto = hdr.inner_ipv4.protocol;
    bit<16> l4_src_port = hdr.udp.src_port; // Entropy field from vxlan header
//    bit<16> l4_dst_port = hdr.inner_tcp.dst_port;
//    bit<16> l4_src_port = hdr.inner_tcp.src_port;

    apply {
        hash [31:0] = inner_dtelv4_hash.get({
                                     ip_src_addr,
                                     ip_dst_addr,
                                     ip_proto,
//                                     l4_dst_port,
                                     l4_src_port});
    }
}

control InnerDtelv6Hash(in switch_header_t hdr,
                        in switch_local_metadata_t local_md, out switch_hash_t hash) {
    @name(".inner_dtelv6_hash")
    Hash<bit<32>>(HashAlgorithm_t.CRC32) inner_dtelv6_hash;
    bit<128> ip_src_addr = hdr.ipv6.src_addr;
    bit<128> ip_dst_addr = hdr.ipv6.dst_addr;
    bit<8> ip_proto = hdr.ipv6.next_hdr;
    bit<16> l4_src_port = hdr.udp.src_port; // Entropy field from vxlan header
//    bit<16> l4_dst_port = hdr.inner_tcp.dst_port;
//    bit<16> l4_src_port = hdr.inner_tcp.src_port;
    bit<20> ipv6_flow_label = hdr.inner_ipv6.flow_label;

    apply {
        hash [31:0] = inner_dtelv6_hash.get({

                                     ipv6_flow_label,

                                     ip_src_addr,
                                     ip_dst_addr,
                                     ip_proto,
//                                     l4_dst_port,
                                     l4_src_port});
    }
}
/******************************************************************************
// RotateHash
// Rotate hash after caclulation
******************************************************************************/

control RotateHash(inout switch_local_metadata_t local_md) {

    @name(".rotate_by_0")
    action rotate_by_0() {
    }
# 588 "../../p4c-5288/shared/hash.p4"
    @name(".rotate_by_1") action rotate_by_1() { local_md.hash[15:0] = local_md.hash[1 -1:0] ++ local_md.hash[15:1]; }
    @name(".rotate_by_2") action rotate_by_2() { local_md.hash[15:0] = local_md.hash[2 -1:0] ++ local_md.hash[15:2]; }
    @name(".rotate_by_3") action rotate_by_3() { local_md.hash[15:0] = local_md.hash[3 -1:0] ++ local_md.hash[15:3]; }
    @name(".rotate_by_4") action rotate_by_4() { local_md.hash[15:0] = local_md.hash[4 -1:0] ++ local_md.hash[15:4]; }
    @name(".rotate_by_5") action rotate_by_5() { local_md.hash[15:0] = local_md.hash[5 -1:0] ++ local_md.hash[15:5]; }
    @name(".rotate_by_6") action rotate_by_6() { local_md.hash[15:0] = local_md.hash[6 -1:0] ++ local_md.hash[15:6]; }
    @name(".rotate_by_7") action rotate_by_7() { local_md.hash[15:0] = local_md.hash[7 -1:0] ++ local_md.hash[15:7]; }
    @name(".rotate_by_8") action rotate_by_8() { local_md.hash[15:0] = local_md.hash[8 -1:0] ++ local_md.hash[15:8]; }
    @name(".rotate_by_9") action rotate_by_9() { local_md.hash[15:0] = local_md.hash[9 -1:0] ++ local_md.hash[15:9]; }
    @name(".rotate_by_10") action rotate_by_10() { local_md.hash[15:0] = local_md.hash[10 -1:0] ++ local_md.hash[15:10]; }
    @name(".rotate_by_11") action rotate_by_11() { local_md.hash[15:0] = local_md.hash[11 -1:0] ++ local_md.hash[15:11]; }
    @name(".rotate_by_12") action rotate_by_12() { local_md.hash[15:0] = local_md.hash[12 -1:0] ++ local_md.hash[15:12]; }
    @name(".rotate_by_13") action rotate_by_13() { local_md.hash[15:0] = local_md.hash[13 -1:0] ++ local_md.hash[15:13]; }
    @name(".rotate_by_14") action rotate_by_14() { local_md.hash[15:0] = local_md.hash[14 -1:0] ++ local_md.hash[15:14]; }
    @name(".rotate_by_15") action rotate_by_15() { local_md.hash[15:0] = local_md.hash[15 -1:0] ++ local_md.hash[15:15]; }

    @name(".rotate_hash")
    table rotate_hash {
        actions = {
            rotate_by_0;
            rotate_by_1;
            rotate_by_2;
            rotate_by_3;
            rotate_by_4;
            rotate_by_5;
            rotate_by_6;
            rotate_by_7;
            rotate_by_8;
            rotate_by_9;
            rotate_by_10;
            rotate_by_11;
            rotate_by_12;
            rotate_by_13;
            rotate_by_14;
            rotate_by_15;
        }
        size = 16;
        default_action = rotate_by_0;
    }

    apply {
        rotate_hash.apply();
    }
}
# 149 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2

# 1 "../../p4c-5288/shared/l3.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/


# 1 "../../p4c-5288/shared/acl.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/





//-----------------------------------------------------------------------------
// Common Ingress ACL match keys and Actions
//-----------------------------------------------------------------------------
# 97 "../../p4c-5288/shared/acl.p4"
//-----------------------------------------------------------------------------
// Common Egress ACL match keys and Actions
//-----------------------------------------------------------------------------
# 149 "../../p4c-5288/shared/acl.p4"
//-----------------------------------------------------------------------------
// Common Ingress ACL actions.
//-----------------------------------------------------------------------------
# 221 "../../p4c-5288/shared/acl.p4"
// fib_lpm_miss reset in nexthop.p4 for TF2
# 257 "../../p4c-5288/shared/acl.p4"
// Common Egress ACL actions.
//-----------------------------------------------------------------------------
# 295 "../../p4c-5288/shared/acl.p4"
//-----------------------------------------------------------------------------
// Pre Ingress ACL
//-----------------------------------------------------------------------------
control PreIngressAcl(in switch_header_t hdr, inout switch_local_metadata_t local_md)(
        switch_uint32_t table_size=512) {

    bool is_acl_enabled;
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    @name(".set_acl_status")
    action set_acl_status(bool enabled) {
        is_acl_enabled = enabled;
    }

    @name(".device_to_acl")
    table device_to_acl {
        actions = {
            set_acl_status;
        }
        default_action = set_acl_status(false);
        size = 1;
    }

    // cannot use INGRESS_ACL_ACTIONS above to avoid dependencies
    @name(".pre_ingress_acl_no_action")
    action no_action() {
        stats.count();
    }
    @name(".pre_ingress_acl_deny")
    action deny() {
        local_md.flags.acl_deny = true;
        stats.count();
    }
    @name(".pre_ingress_acl_set_vrf")
    action set_vrf(switch_vrf_t vrf) {
        local_md.vrf = vrf;
        stats.count();
    }

    @name(".pre_ingress_acl")
    table acl {
        key = {
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
            local_md.lkp.mac_type : ternary;






            local_md.lkp.ip_src_addr : ternary;
            local_md.lkp.ip_dst_addr : ternary;

            local_md.lkp.ip_tos : ternary;
            local_md.ingress_port : ternary;
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

    action set_tc(switch_tc_t tc) { local_md.qos.tc = tc; stats.count(); } action set_color(switch_pkt_color_t color) { local_md.qos.color = color; stats.count(); } action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) { local_md.flags.acl_deny = false; local_md.egress_port_lag_index = egress_port_lag_index; local_md.acl_port_redirect = true; local_md.user_metadata = user_metadata; stats.count(); } action mirror_in(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { local_md.mirror.type = 1; local_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS; local_md.mirror.session_id = session_id; local_md.mirror.meter_index = meter_index; stats.count(); } action set_dtel_report_type(switch_dtel_report_type_t type) { local_md.dtel.report_type = local_md.dtel.report_type | type; stats.count(); }
    action no_action() { stats.count(); } action permit(switch_user_metadata_t user_metadata, switch_hostif_trap_t trap_id, switch_meter_index_t meter_index) { local_md.flags.acl_deny = false; local_md.user_metadata = user_metadata; local_md.hostif_trap_id = trap_id; local_md.qos.acl_meter_index = meter_index; stats.count(); } action deny() { local_md.flags.acl_deny = true; stats.count(); } action copy_to_cpu(switch_hostif_trap_t trap_id, switch_meter_index_t meter_index) { local_md.hostif_trap_id = trap_id; local_md.qos.acl_meter_index = meter_index; stats.count(); } action trap(switch_hostif_trap_t trap_id, switch_meter_index_t meter_index) { local_md.hostif_trap_id = trap_id; local_md.qos.acl_meter_index = meter_index; deny(); }
    action redirect_nexthop(switch_user_metadata_t user_metadata, switch_nexthop_t nexthop_index) { acl_nexthop = nexthop_index; local_md.flags.fib_lpm_miss = false; local_md.user_metadata = user_metadata; stats.count(); }




    table acl {
        key = {



            local_md.lkp.ip_src_addr : ternary; local_md.lkp.ip_dst_addr : ternary; local_md.lkp.ip_proto : ternary; local_md.lkp.ip_tos : ternary; local_md.lkp.l4_src_port : ternary; local_md.lkp.l4_dst_port : ternary; local_md.lkp.ip_ttl : ternary; local_md.lkp.ip_frag : ternary; local_md.lkp.tcp_flags : ternary; local_md.l4_src_port_label : ternary; local_md.l4_dst_port_label : ternary;





            local_md.lkp.mac_type : ternary;
# 411 "../../p4c-5288/shared/acl.p4"
            local_md.ingress_port_lag_label : ternary;


            local_md.bd_label : ternary;






        }

        actions = {
            deny;
            trap;
            copy_to_cpu;
            permit;






            mirror_in;
# 445 "../../p4c-5288/shared/acl.p4"
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
            hdr.inner_ipv4.src_addr : ternary; hdr.inner_ipv4.dst_addr : ternary; hdr.inner_ipv4.protocol : ternary; hdr.inner_ipv4.diffserv : ternary; hdr.inner_tcp.src_port : ternary; hdr.inner_tcp.dst_port : ternary; hdr.inner_udp.src_port : ternary; hdr.inner_udp.dst_port : ternary; hdr.inner_ipv4.ttl : ternary; hdr.inner_tcp.flags : ternary; local_md.tunnel.vni : ternary;
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
            hdr.inner_ipv6.src_addr : ternary; hdr.inner_ipv6.dst_addr : ternary; hdr.inner_ipv6.next_hdr : ternary; hdr.inner_ipv6.traffic_class : ternary; hdr.inner_tcp.src_port : ternary; hdr.inner_tcp.dst_port : ternary; hdr.inner_udp.src_port : ternary; hdr.inner_udp.dst_port : ternary; hdr.inner_ipv6.hop_limit : ternary; hdr.inner_tcp.flags : ternary; local_md.tunnel.vni : ternary;
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

    action set_tc(switch_tc_t tc) { local_md.qos.tc = tc; stats.count(); } action set_color(switch_pkt_color_t color) { local_md.qos.color = color; stats.count(); } action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) { local_md.flags.acl_deny = false; local_md.egress_port_lag_index = egress_port_lag_index; local_md.acl_port_redirect = true; local_md.user_metadata = user_metadata; stats.count(); } action mirror_in(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { local_md.mirror.type = 1; local_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS; local_md.mirror.session_id = session_id; local_md.mirror.meter_index = meter_index; stats.count(); } action set_dtel_report_type(switch_dtel_report_type_t type) { local_md.dtel.report_type = local_md.dtel.report_type | type; stats.count(); }
    action no_action() { stats.count(); } action permit(switch_user_metadata_t user_metadata, switch_hostif_trap_t trap_id, switch_meter_index_t meter_index) { local_md.flags.acl_deny = false; local_md.user_metadata = user_metadata; local_md.hostif_trap_id = trap_id; local_md.qos.acl_meter_index = meter_index; stats.count(); } action deny() { local_md.flags.acl_deny = true; stats.count(); } action copy_to_cpu(switch_hostif_trap_t trap_id, switch_meter_index_t meter_index) { local_md.hostif_trap_id = trap_id; local_md.qos.acl_meter_index = meter_index; stats.count(); } action trap(switch_hostif_trap_t trap_id, switch_meter_index_t meter_index) { local_md.hostif_trap_id = trap_id; local_md.qos.acl_meter_index = meter_index; deny(); }
    action redirect_nexthop(switch_user_metadata_t user_metadata, switch_nexthop_t nexthop_index) { acl_nexthop = nexthop_index; local_md.flags.fib_lpm_miss = false; local_md.user_metadata = user_metadata; stats.count(); }






    table acl {
        key = {
            local_md.lkp.ip_src_addr[95:64] : ternary; local_md.lkp.ip_dst_addr[95:64] : ternary; local_md.lkp.ip_proto : ternary; local_md.lkp.ip_tos : ternary; local_md.lkp.l4_src_port : ternary; local_md.lkp.l4_dst_port : ternary; local_md.lkp.ip_ttl : ternary; local_md.lkp.ip_frag : ternary; local_md.lkp.tcp_flags : ternary; local_md.l4_src_port_label : ternary; local_md.l4_dst_port_label : ternary;




            local_md.lkp.mac_type : ternary;
# 576 "../../p4c-5288/shared/acl.p4"
            local_md.ingress_port_lag_label : ternary;


            local_md.bd_label : ternary;






        }

        actions = {
            deny;
            trap;
            copy_to_cpu;
            permit;
# 602 "../../p4c-5288/shared/acl.p4"
            mirror_in;
# 613 "../../p4c-5288/shared/acl.p4"
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

    action set_tc(switch_tc_t tc) { local_md.qos.tc = tc; stats.count(); } action set_color(switch_pkt_color_t color) { local_md.qos.color = color; stats.count(); } action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) { local_md.flags.acl_deny = false; local_md.egress_port_lag_index = egress_port_lag_index; local_md.acl_port_redirect = true; local_md.user_metadata = user_metadata; stats.count(); } action mirror_in(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { local_md.mirror.type = 1; local_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS; local_md.mirror.session_id = session_id; local_md.mirror.meter_index = meter_index; stats.count(); } action set_dtel_report_type(switch_dtel_report_type_t type) { local_md.dtel.report_type = local_md.dtel.report_type | type; stats.count(); }
    action no_action() { stats.count(); } action permit(switch_user_metadata_t user_metadata, switch_hostif_trap_t trap_id, switch_meter_index_t meter_index) { local_md.flags.acl_deny = false; local_md.user_metadata = user_metadata; local_md.hostif_trap_id = trap_id; local_md.qos.acl_meter_index = meter_index; stats.count(); } action deny() { local_md.flags.acl_deny = true; stats.count(); } action copy_to_cpu(switch_hostif_trap_t trap_id, switch_meter_index_t meter_index) { local_md.hostif_trap_id = trap_id; local_md.qos.acl_meter_index = meter_index; stats.count(); } action trap(switch_hostif_trap_t trap_id, switch_meter_index_t meter_index) { local_md.hostif_trap_id = trap_id; local_md.qos.acl_meter_index = meter_index; deny(); }
    action redirect_nexthop(switch_user_metadata_t user_metadata, switch_nexthop_t nexthop_index) { acl_nexthop = nexthop_index; local_md.flags.fib_lpm_miss = false; local_md.user_metadata = user_metadata; stats.count(); }




    table acl {
        key = {



            local_md.lkp.ip_src_addr : ternary; local_md.lkp.ip_dst_addr : ternary; local_md.lkp.ip_proto : ternary; local_md.lkp.ip_tos : ternary; local_md.lkp.l4_src_port : ternary; local_md.lkp.l4_dst_port : ternary; local_md.lkp.ip_ttl : ternary; local_md.lkp.ip_frag : ternary; local_md.lkp.tcp_flags : ternary; local_md.l4_src_port_label : ternary; local_md.l4_dst_port_label : ternary;






            local_md.lkp.mac_type : ternary;
# 665 "../../p4c-5288/shared/acl.p4"
            local_md.ingress_port_lag_label : ternary;


            local_md.bd_label : ternary;






        }

        actions = {
            deny;
            trap;
            copy_to_cpu;
            permit;






            mirror_in;
# 699 "../../p4c-5288/shared/acl.p4"
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

control IngressTosMirrorAcl(inout switch_local_metadata_t local_md)(switch_uint32_t table_size=512) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() {
        stats.count();
    }
    action mirror_in(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) {
        local_md.mirror.type = 1;
        local_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        local_md.mirror.session_id = session_id;
        local_md.mirror.meter_index = meter_index;
        stats.count();
    }




    table acl {
        key = {
            local_md.lkp.ip_tos : ternary;
            local_md.ingress_port_lag_label : ternary;
        }

        actions = {
            mirror_in;



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

    action set_tc(switch_tc_t tc) { local_md.qos.tc = tc; stats.count(); } action set_color(switch_pkt_color_t color) { local_md.qos.color = color; stats.count(); } action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) { local_md.flags.acl_deny = false; local_md.egress_port_lag_index = egress_port_lag_index; local_md.acl_port_redirect = true; local_md.user_metadata = user_metadata; stats.count(); } action mirror_in(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { local_md.mirror.type = 1; local_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS; local_md.mirror.session_id = session_id; local_md.mirror.meter_index = meter_index; stats.count(); } action set_dtel_report_type(switch_dtel_report_type_t type) { local_md.dtel.report_type = local_md.dtel.report_type | type; stats.count(); }
    action no_action() { stats.count(); } action permit(switch_user_metadata_t user_metadata, switch_hostif_trap_t trap_id, switch_meter_index_t meter_index) { local_md.flags.acl_deny = false; local_md.user_metadata = user_metadata; local_md.hostif_trap_id = trap_id; local_md.qos.acl_meter_index = meter_index; stats.count(); } action deny() { local_md.flags.acl_deny = true; stats.count(); } action copy_to_cpu(switch_hostif_trap_t trap_id, switch_meter_index_t meter_index) { local_md.hostif_trap_id = trap_id; local_md.qos.acl_meter_index = meter_index; stats.count(); } action trap(switch_hostif_trap_t trap_id, switch_meter_index_t meter_index) { local_md.hostif_trap_id = trap_id; local_md.qos.acl_meter_index = meter_index; deny(); }
    action redirect_nexthop(switch_user_metadata_t user_metadata, switch_nexthop_t nexthop_index) { acl_nexthop = nexthop_index; local_md.flags.fib_lpm_miss = false; local_md.user_metadata = user_metadata; stats.count(); }

    table acl {
        key = {
            hdr.ethernet.src_addr : ternary; hdr.ethernet.dst_addr : ternary; local_md.lkp.mac_type : ternary;
            local_md.ingress_port_lag_label : ternary;

            local_md.bd_label : ternary;



        }

        actions = {
            deny;
            permit;






            mirror_in;







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

    action set_tc(switch_tc_t tc) { local_md.qos.tc = tc; stats.count(); } action set_color(switch_pkt_color_t color) { local_md.qos.color = color; stats.count(); } action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) { local_md.flags.acl_deny = false; local_md.egress_port_lag_index = egress_port_lag_index; local_md.acl_port_redirect = true; local_md.user_metadata = user_metadata; stats.count(); } action mirror_in(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { local_md.mirror.type = 1; local_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS; local_md.mirror.session_id = session_id; local_md.mirror.meter_index = meter_index; stats.count(); } action set_dtel_report_type(switch_dtel_report_type_t type) { local_md.dtel.report_type = local_md.dtel.report_type | type; stats.count(); }
    action no_action() { stats.count(); } action permit(switch_user_metadata_t user_metadata, switch_hostif_trap_t trap_id, switch_meter_index_t meter_index) { local_md.flags.acl_deny = false; local_md.user_metadata = user_metadata; local_md.hostif_trap_id = trap_id; local_md.qos.acl_meter_index = meter_index; stats.count(); } action deny() { local_md.flags.acl_deny = true; stats.count(); } action copy_to_cpu(switch_hostif_trap_t trap_id, switch_meter_index_t meter_index) { local_md.hostif_trap_id = trap_id; local_md.qos.acl_meter_index = meter_index; stats.count(); } action trap(switch_hostif_trap_t trap_id, switch_meter_index_t meter_index) { local_md.hostif_trap_id = trap_id; local_md.qos.acl_meter_index = meter_index; deny(); }

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



            local_md.lkp.mac_type : ternary;





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
    @name(".set_ingress_src_port_label")
    action set_src_port_label(bit<8> label) {
        local_md.l4_src_port_label = label;
    }

    @name(".set_ingress_dst_port_label")
    action set_dst_port_label(bit<8> label) {
        local_md.l4_dst_port_label = label;
    }

    @entries_with_ranges(table_size)
    @name(".ingress_l4_dst_port")
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

    @entries_with_ranges(table_size)
    @name(".ingress_l4_src_port")
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

    @name(".set_tcp_flags")
    action set_tcp_flags(bit<8> flags) {
        local_md.lkp.tcp_flags = flags;
    }

    @name(".ingress_lou_tcp")
    table tcp {
        key = { local_md.lkp.tcp_flags : exact; }
        actions = {
            NoAction;
            set_tcp_flags;
        }

        size = 256;
    }

    apply {

        l4_src_port.apply();
        l4_dst_port.apply();





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

    @name(".ingress_copp_meter")
    Meter<bit<8>>(1 << 8, MeterType_t.PACKETS) copp_meter;
    DirectCounter<bit<64>>(CounterType_t.PACKETS) copp_stats;

    switch_copp_meter_id_t copp_meter_id;

    @name(".ingress_system_acl_permit")
    action permit() {
        local_md.drop_reason = SWITCH_DROP_REASON_UNKNOWN;
    }
    @name(".ingress_system_acl_drop")
    action drop(switch_drop_reason_t drop_reason, bool disable_learning) {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        ig_intr_md_for_dprsr.digest_type =
            disable_learning ? SWITCH_DIGEST_TYPE_INVALID : ig_intr_md_for_dprsr.digest_type;
        local_md.drop_reason = drop_reason;



    }

    @name(".ingress_system_acl_copy_to_cpu")
    action copy_to_cpu(switch_cpu_reason_t reason_code,
                       switch_qid_t qid,
                       switch_copp_meter_id_t meter_id,
                       bool disable_learning, bool overwrite_qid) {
        local_md.qos.qid = overwrite_qid ? qid : local_md.qos.qid;
        // local_md.qos.icos = icos;
        ig_intr_md_for_tm.copy_to_cpu = 1w1;
        ig_intr_md_for_dprsr.digest_type =
            disable_learning ? SWITCH_DIGEST_TYPE_INVALID : ig_intr_md_for_dprsr.digest_type;
        ig_intr_md_for_tm.packet_color = (bit<2>) copp_meter.execute(meter_id);
        copp_meter_id = meter_id;
        local_md.cpu_reason = reason_code;



        local_md.drop_reason = SWITCH_DROP_REASON_UNKNOWN;
    }


    @name(".ingress_system_acl_copy_sflow_to_cpu")
    action copy_sflow_to_cpu(switch_cpu_reason_t reason_code,
                             switch_qid_t qid,
                             switch_copp_meter_id_t meter_id,
                             bool disable_learning, bool overwrite_qid) {
        copy_to_cpu(reason_code + (bit<16>)local_md.sflow.session_id, qid, meter_id, disable_learning, overwrite_qid);
    }


    @name(".ingress_system_acl_redirect_to_cpu")
    action redirect_to_cpu(switch_cpu_reason_t reason_code,
                           switch_qid_t qid,
                           switch_copp_meter_id_t meter_id,
                           bool disable_learning, bool overwrite_qid) {
        ig_intr_md_for_dprsr.drop_ctl = 0b1;
        copy_to_cpu(reason_code, qid, meter_id, disable_learning, overwrite_qid);
    }


    @name(".ingress_system_acl_redirect_sflow_to_cpu")
    action redirect_sflow_to_cpu(switch_cpu_reason_t reason_code,
                                 switch_qid_t qid,
                                 switch_copp_meter_id_t meter_id,
                                 bool disable_learning, bool overwrite_qid) {
        ig_intr_md_for_dprsr.drop_ctl = 0b1;
        copy_sflow_to_cpu(reason_code, qid, meter_id, disable_learning, overwrite_qid);
    }
# 1088 "../../p4c-5288/shared/acl.p4"
    @name(".ingress_system_acl")
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
# 1140 "../../p4c-5288/shared/acl.p4"
            local_md.flags.pfc_wd_drop : ternary;

            local_md.ipv4.unicast_enable : ternary;
            local_md.ipv6.unicast_enable : ternary;
# 1153 "../../p4c-5288/shared/acl.p4"
            local_md.sflow.sample_packet : ternary;

            local_md.l2_drop_reason : ternary;
            local_md.drop_reason : ternary;
# 1178 "../../p4c-5288/shared/acl.p4"
            local_md.hostif_trap_id : ternary;
        }

        actions = {
            permit;
            drop;
            copy_to_cpu;
            redirect_to_cpu;

            copy_sflow_to_cpu;
            redirect_sflow_to_cpu;

        }

        const default_action = permit;
        size = table_size;
    }

    @name(".ingress_copp_drop")
    action copp_drop() {
        ig_intr_md_for_tm.copy_to_cpu = 1w0;
        copp_stats.count();
    }

    @name(".ingress_copp_permit")
    action copp_permit() {
        copp_stats.count();
    }

    @name(".ingress_copp")
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

    @name(".ingress_drop_stats_count")
    action count() { stats.count(); }

    @name(".ingress_drop_stats")
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
    @name(".set_egress_src_port_label")
    action set_src_port_label(bit<8> label) {
        local_md.l4_src_port_label = label;
    }

    @name(".set_egress_dst_port_label")
    action set_dst_port_label(bit<8> label) {
        local_md.l4_dst_port_label = label;
    }

    @entries_with_ranges(table_size)
    @name(".egress_l4_dst_port")
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

    @entries_with_ranges(table_size)
    @name(".egress_l4_src_port")
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

    action no_action() { stats.count(); } action deny() { local_md.flags.acl_deny = true; stats.count(); } action permit(switch_meter_index_t meter_index) { local_md.flags.acl_deny = false; local_md.qos.acl_meter_index = meter_index; stats.count(); } action mirror_out(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { local_md.mirror.type = 1; local_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS; local_md.mirror.session_id = session_id; local_md.mirror.meter_index = meter_index; stats.count(); }

    table acl {
        key = {
            hdr.ethernet.src_addr : ternary; hdr.ethernet.dst_addr : ternary; hdr.ethernet.ether_type : ternary; local_md.egress_port_lag_label: ternary;
        }

        actions = {
            deny(); permit(); mirror_out(); no_action;
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

    action no_action() { stats.count(); } action deny() { local_md.flags.acl_deny = true; stats.count(); } action permit(switch_meter_index_t meter_index) { local_md.flags.acl_deny = false; local_md.qos.acl_meter_index = meter_index; stats.count(); } action mirror_out(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { local_md.mirror.type = 1; local_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS; local_md.mirror.session_id = session_id; local_md.mirror.meter_index = meter_index; stats.count(); }




    table acl {
        key = {
            hdr.ipv4.src_addr : ternary; hdr.ipv4.dst_addr : ternary; hdr.ipv4.protocol : ternary; local_md.lkp.tcp_flags : ternary; local_md.lkp.l4_src_port : ternary; local_md.lkp.l4_dst_port : ternary; local_md.egress_port_lag_label: ternary;

            hdr.ethernet.ether_type : ternary;
# 1385 "../../p4c-5288/shared/acl.p4"
        }

        actions = {
            deny(); permit(); mirror_out(); no_action;



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

    action no_action() { stats.count(); } action deny() { local_md.flags.acl_deny = true; stats.count(); } action permit(switch_meter_index_t meter_index) { local_md.flags.acl_deny = false; local_md.qos.acl_meter_index = meter_index; stats.count(); } action mirror_out(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) { local_md.mirror.type = 1; local_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS; local_md.mirror.session_id = session_id; local_md.mirror.meter_index = meter_index; stats.count(); }




    table acl {
        key = {



            hdr.ipv6.src_addr : ternary; hdr.ipv6.dst_addr : ternary; hdr.ipv6.next_hdr : ternary; local_md.lkp.tcp_flags : ternary; local_md.lkp.l4_src_port : ternary; local_md.lkp.l4_dst_port : ternary; local_md.egress_port_lag_label: ternary;



            hdr.ethernet.ether_type : ternary;
# 1444 "../../p4c-5288/shared/acl.p4"
        }

        actions = {
            deny(); permit(); mirror_out(); no_action;



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

control EgressTosMirrorAcl(in switch_header_t hdr,
                           inout switch_local_metadata_t local_md)(
                           switch_uint32_t table_size=512) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() {
      stats.count();
    }

    action mirror_out(switch_mirror_meter_id_t meter_index,
                  switch_mirror_session_t session_id) {
        local_md.mirror.type = 1;
        local_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        local_md.mirror.session_id = session_id;
        local_md.mirror.meter_index = meter_index;
        stats.count();
    }




    table acl {
        key = {
            hdr.ipv4.diffserv : ternary;
            hdr.ipv6.traffic_class : ternary;
            hdr.ipv4.isValid() : ternary;
            hdr.ipv6.isValid() : ternary;
            local_md.egress_port_lag_label : ternary;
        }

        actions = {
            mirror_out;
            no_action;



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

    @name(".egress_copp_meter")
    Meter<bit<8>>(1 << 8, MeterType_t.PACKETS) copp_meter;
    DirectCounter<bit<64>>(CounterType_t.PACKETS) copp_stats;

    switch_copp_meter_id_t copp_meter_id;
    switch_pkt_color_t copp_color;

    @name(".egress_system_acl_drop")
    action drop(switch_drop_reason_t reason_code) {
        local_md.drop_reason = reason_code;
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        local_md.mirror.type = 0;
    }


    @name(".egress_system_acl_copy_to_cpu")
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

    @name(".egress_system_acl_redirect_to_cpu")
    action redirect_to_cpu(switch_cpu_reason_t reason_code,
                           switch_copp_meter_id_t meter_id) {
        copy_to_cpu(reason_code, meter_id);
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }


    @name(".egress_system_acl_ingress_timestamp")
    action insert_timestamp() {




    }

    @name(".egress_system_acl")
    table system_acl {
        key = {
            eg_intr_md.egress_port : ternary;
            local_md.flags.acl_deny : ternary;





            local_md.checks.mtu : ternary;





            local_md.flags.wred_drop : ternary;


            local_md.flags.pfc_wd_drop : ternary;
# 1606 "../../p4c-5288/shared/acl.p4"
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

    @name(".egress_drop_stats_count")
    action count() { stats.count(); }

    @name(".egress_drop_stats")
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


    @name(".egress_copp_drop")
    action copp_drop() {
        local_md.mirror.type = 0;
        copp_stats.count();
    }

    @name(".egress_copp_permit")
    action copp_permit() {
        copp_stats.count();
    }

    @ways(2)
    @name(".egress_copp")
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
# 21 "../../p4c-5288/shared/l3.p4" 2
# 1 "../../p4c-5288/shared/l2.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/





//-----------------------------------------------------------------------------
// Spanning Tree Protocol
// @param local_md : Ingress metadata fields.
// @param stp_md : Spanning tree metadata.
// @param multiple_stp_enable : Allows to map a group of VLAN?s into a single spanning
// tree instance, for which spanning tree is applied independently.
// @param table_size : Size of the mstp table. Only used if multiple stp is enabled.
//
// @flag MULTIPLE_STP: Allows to map a group of VLAN?s into a single spanning
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
    @name(".ingress_stp.stp")
    Register<bit<1>, bit<32>>(stp_state_size, 0) stp;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;
    RegisterAction<bit<1>, bit<32>, bit<1>>(stp) stp_check = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };

    @name(".ingress_stp.set_stp_state")
    action set_stp_state(switch_stp_state_t stp_state) {
        stp_md.state_ = stp_state;
    }

    @name(".ingress_stp.mstp")
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
# 86 "../../p4c-5288/shared/l2.p4"
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
    @name(".egress_stp.stp")
    Register<bit<1>, bit<32>>(1 << 19, 0) stp;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;
    RegisterAction<bit<1>, bit<32>, bit<1>>(stp) stp_check = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };

    apply {
# 118 "../../p4c-5288/shared/l2.p4"
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

    @name(".smac_miss")
    action smac_miss() { src_miss = true; }

    @name(".smac_hit")
    action smac_hit(switch_port_lag_index_t port_lag_index) {
        src_move = local_md.ingress_port_lag_index ^ port_lag_index;
    }

    @name(".smac") table smac {
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
        const entries = {
            (true, _) : notify();
            (false, 0 &&& 0x3FF) : NoAction();
            (false, _) : notify();
        }
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

    @name(".dmac_miss")
    action dmac_miss() {
        local_md.egress_port_lag_index = SWITCH_FLOOD;
        local_md.flags.dmac_miss = true;
    }

    @name(".dmac_hit")
    action dmac_hit(switch_port_lag_index_t port_lag_index) {
        local_md.egress_port_lag_index = port_lag_index;
        local_md.checks.same_if = local_md.ingress_port_lag_index ^ port_lag_index;
    }
# 238 "../../p4c-5288/shared/l2.p4"
    @name(".dmac_redirect")
    action dmac_redirect(switch_nexthop_t nexthop_index) {
        local_md.nexthop = nexthop_index;
    }


    @pack(2)
    @name(".dmac")
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

    // cannot give .count cuz of a bfrt issue
    @name(".ingress_bd_stats_count") action count() { stats.count(); }

    @name(".ingress_bd_stats")
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

    @name(".egress_bd_stats_count") action count() { stats.count(); }

    @name(".egress_bd_stats")
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






    @name(".set_egress_bd_mapping")
    action set_bd_properties(mac_addr_t smac, switch_mtu_t mtu) {

        hdr.ethernet.src_addr = smac;
        local_md.checks.mtu = mtu;
    }




    @name(".egress_bd_mapping")
    table bd_mapping {
        key = { local_md.bd[12:0] : exact; }
        actions = {
            set_bd_properties;
        }




        const default_action = set_bd_properties(0, 0x3fff);





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
control VlanDecap(inout switch_header_t hdr, inout switch_local_metadata_t local_md) {
    @name(".remove_vlan_tag")
    action remove_vlan_tag() {
        hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
        hdr.vlan_tag.pop_front(1);
    }
# 420 "../../p4c-5288/shared/l2.p4"
    @name(".vlan_decap")
    table vlan_decap {
        key = {



            hdr.vlan_tag[0].isValid() : ternary;



        }

        actions = {
            NoAction;
            remove_vlan_tag;



        }

        const default_action = NoAction;
    }

    apply {
        if (!local_md.flags.bypass_egress) {



            // Remove the vlan tag by default.
            if (hdr.vlan_tag[0].isValid()) {
                hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
                hdr.vlan_tag[0].setInvalid();
                local_md.pkt_length = local_md.pkt_length - 4;
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
    @name(".set_vlan_untagged")
    action set_vlan_untagged() {
        //NoAction.
    }
# 492 "../../p4c-5288/shared/l2.p4"
    @name(".set_vlan_tagged")
    action set_vlan_tagged(vlan_id_t vid) {



        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;

        hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].vid = vid;
        hdr.ethernet.ether_type = 0x8100;
    }

    @name(".port_bd_to_vlan_mapping")
    table port_bd_to_vlan_mapping {
        key = {
            local_md.egress_port_lag_index : exact @name("port_lag_index");
            local_md.bd : exact @name("bd");
        }

        actions = {
            set_vlan_untagged;
            set_vlan_tagged;



        }

        const default_action = set_vlan_untagged;
        size = port_bd_table_size;
        //TODO : fix table size once scale requirements for double tag is known
    }

    @name(".bd_to_vlan_mapping")
    table bd_to_vlan_mapping {
        key = { local_md.bd : exact @name("bd"); }
        actions = {
            set_vlan_untagged;
            set_vlan_tagged;
        }

        const default_action = set_vlan_untagged;
        size = bd_table_size;
    }
# 566 "../../p4c-5288/shared/l2.p4"
    apply {
        if (!local_md.flags.bypass_egress) {
            if (!port_bd_to_vlan_mapping.apply().hit) {
                bd_to_vlan_mapping.apply();
            }




        }
    }
}
# 22 "../../p4c-5288/shared/l3.p4" 2

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


    @pack(2)
    @name(".ipv4_host") table host {
        key = {
            local_md.vrf : exact @name("vrf");
            local_md.lkp.ip_dst_addr[95:64] : exact @name("ip_dst_addr");
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
            local_md.vrf : exact @name("vrf");
            local_md.lkp.ip_dst_addr[95:64] : exact @name("ip_dst_addr");
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







    Alpm(number_partitions = 2048, subtrees_per_partition = 2) algo_lpm;

    @name(".ipv4_lpm") table lpm32 {
        key = {
            local_md.vrf : exact @name("vrf");
            local_md.lkp.ip_dst_addr[95:64] : lpm @name("ip_dst_addr");
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
              switch_uint32_t host64_table_size,
              switch_uint32_t lpm_table_size,
              switch_uint32_t lpm64_table_size=1024) {


    @immediate(0)
    @name(".ipv6_host") table host {
        key = {
            local_md.vrf : exact @name("vrf");
            local_md.lkp.ip_dst_addr : exact @name("ip_dst_addr");
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
# 208 "../../p4c-5288/shared/l3.p4"
    Alpm(number_partitions = 1024, subtrees_per_partition = 2) algo_lpm128;

    @name(".ipv6_lpm128") table lpm128 {
        key = {
            local_md.vrf : exact @name("vrf");
            local_md.lkp.ip_dst_addr : lpm @name("ip_dst_addr");
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
# 278 "../../p4c-5288/shared/l3.p4"
    apply {

        if (!host.apply().hit) {



            if (!lpm128.apply().hit)

            {
# 296 "../../p4c-5288/shared/l3.p4"
            }
        }

    }
}
# 453 "../../p4c-5288/shared/l3.p4"
//-----------------------------------------------------------------------------
// VRF Properties
//       -- Inner VRF for encap cases
//
//-----------------------------------------------------------------------------

control EgressVRF(inout switch_header_t hdr,
                 inout switch_local_metadata_t local_md) {

    @name(".set_vrf_properties")
    action set_vrf_properties(switch_tunnel_vni_t vni, mac_addr_t smac) {
        local_md.tunnel.vni = vni;
        hdr.ethernet.src_addr = smac;
    }

    @use_hash_action(1)
    @name(".vrf_mapping") table vrf_mapping {
        key = {
            local_md.vrf : exact @name("vrf");
        }
        actions = {
            set_vrf_properties;
        }

        const default_action = set_vrf_properties(0, 0);
        size = VRF_TABLE_SIZE;
    }

    apply {
        if (!local_md.flags.bypass_egress && local_md.flags.routed) {
            vrf_mapping.apply();
            if (hdr.ipv4.isValid()) {
                hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
            } else if (hdr.ipv6.isValid()) {
                hdr.ipv6.hop_limit = hdr.ipv6.hop_limit - 1;
            }
        }
    }
}
//-----------------------------------------------------------------------------
// Egress pipeline : MTU Check
//-----------------------------------------------------------------------------
control MTU(in switch_header_t hdr,
            inout switch_local_metadata_t local_md)(
            switch_uint32_t table_size=16) {

    action ipv4_mtu_check() {
        local_md.checks.mtu = local_md.checks.mtu |-| hdr.ipv4.total_len;
    }

    action ipv6_mtu_check() {
        local_md.checks.mtu = local_md.checks.mtu |-| hdr.ipv6.payload_len;
    }

    action mtu_miss() {
        local_md.checks.mtu = 16w0xffff;
    }

    table mtu {
        key = {
            local_md.flags.bypass_egress : exact;
            local_md.flags.routed : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }

        actions = {
            ipv4_mtu_check;
            ipv6_mtu_check;
            mtu_miss;
        }

        const default_action = mtu_miss;
        const entries = {
            (false, true, true, false) : ipv4_mtu_check();
            (false, true, false, true) : ipv6_mtu_check();
        }
        size = table_size;
    }

    apply {
        mtu.apply();
    }
}
# 151 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/shared/nexthop.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
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
    @name(".nexthop_ecmp_action_profile")
    ActionProfile(ecmp_selection_table_size) ecmp_action_profile;
# 46 "../../p4c-5288/shared/nexthop.p4"
    @name(".nexthop_ecmp_selector")
    ActionSelector(ecmp_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   ecmp_max_members_per_group,
                   ecmp_group_table_size) ecmp_selector;


    // ---------------- IP Nexthop ----------------
    @name(".nexthop_set_nexthop_properties")
    action set_nexthop_properties(switch_port_lag_index_t port_lag_index,
                                  switch_bd_t bd,
                                  switch_nat_zone_t zone) {



        local_md.egress_port_lag_index = port_lag_index;



        local_md.checks.same_if = local_md.ingress_port_lag_index ^ port_lag_index;




    }

    @name(".set_ecmp_properties")
    action set_ecmp_properties(switch_port_lag_index_t port_lag_index,
                               switch_bd_t bd,
                               switch_nexthop_t nexthop_index, switch_nat_zone_t zone) {
        local_md.nexthop = nexthop_index;



        set_nexthop_properties(port_lag_index, bd, zone);
    }

    // ----------------  Post Route Flood ----------------
    @name(".set_nexthop_properties_post_routed_flood")
    action set_nexthop_properties_post_routed_flood(switch_bd_t bd, switch_mgid_t mgid, switch_nat_zone_t zone) {
        local_md.egress_port_lag_index = 0;
        local_md.multicast.id = mgid;



    }

    @name(".set_ecmp_properties_post_routed_flood")
    action set_ecmp_properties_post_routed_flood(
            switch_bd_t bd,
            switch_mgid_t mgid,
            switch_nexthop_t nexthop_index, switch_nat_zone_t zone) {
        local_md.nexthop = nexthop_index;
        set_nexthop_properties_post_routed_flood(bd, mgid, zone);
    }

    // ---------------- Glean ----------------
    @name(".set_nexthop_properties_glean")
    action set_nexthop_properties_glean() {
        local_md.flags.glean = true;
    }

    @name(".set_ecmp_properties_glean")
    action set_ecmp_properties_glean(switch_nexthop_t nexthop_index) {
        local_md.nexthop = nexthop_index;
        set_nexthop_properties_glean();
    }

    // ---------------- Drop ----------------
    @name(".set_nexthop_properties_drop")
    action set_nexthop_properties_drop() {
        local_md.drop_reason = SWITCH_DROP_REASON_NEXTHOP;
    }

    @name(".set_ecmp_properties_drop")
    action set_ecmp_properties_drop() {
        set_nexthop_properties_drop();
    }
# 144 "../../p4c-5288/shared/nexthop.p4"
    @ways(2)
    @name(".ecmp")
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




    @name(".nexthop")
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
# 208 "../../p4c-5288/shared/nexthop.p4"
        switch(nexthop.apply().action_run) {
            NoAction : { ecmp.apply(); }
            default : {}
            }



    }
}
# 264 "../../p4c-5288/shared/nexthop.p4"
//--------------------------------------------------------------------------
// Egress Pipeline: Neighbor lookup for both routed and tunnel encap cases
//-------------------------------------------------------------------------

control Neighbor(inout switch_header_t hdr,
                inout switch_local_metadata_t local_md)() {

    @name(".neighbor_rewrite_l2")
    action rewrite_l2(switch_bd_t bd, mac_addr_t dmac) {
        hdr.ethernet.dst_addr = dmac;
    }

    @use_hash_action(1)
    @name (".neighbor")
    table neighbor {
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
//-------------------------------------------------------------------------

control OuterNexthop(inout switch_header_t hdr,
                inout switch_local_metadata_t local_md)() {

    @name(".outer_nexthop_rewrite_l2")
    action rewrite_l2(switch_bd_t bd) {
        local_md.bd = bd;
    }

    @use_hash_action(1)
    @name(".outer_nexthop")
    table outer_nexthop {
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
# 152 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/shared/parde.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/


# 1 "../../p4c-5288/shared/headers.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/


//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------
# 21 "../../p4c-5288/shared/parde.p4" 2
# 1 "../../p4c-5288/shared/types.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/
# 22 "../../p4c-5288/shared/parde.p4" 2

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



            (0x0800, _) : parse_ipv4;
            (0x0806, _) : parse_arp;
            (0x86dd, _) : parse_ipv6;
            (0x8100, _) : parse_vlan;
            (0x8100, _) : parse_vlan;






            default : accept;
        }
    }
# 151 "../../p4c-5288/shared/parde.p4"
    state parse_cpu {
        pkt.extract(hdr.fabric);
        pkt.extract(hdr.loop_flag);
        pkt.extract(hdr.cpu);
        local_md.bypass = hdr.cpu.reason_code;



        transition select(hdr.loop_flag.flags) {
            1 : accept;
            2 : parse_cpu_etype;
        }
    }


    state parse_cpu_etype {
        transition select(hdr.cpu.ether_type) {
            0x0800 : parse_ipv4;
            0x0806 : parse_arp;
            0x86dd : parse_ipv6;
            0x8100 : parse_vlan;
            0x8100 : parse_vlan;



            default : accept;
        }
    }
# 205 "../../p4c-5288/shared/parde.p4"
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
# 240 "../../p4c-5288/shared/parde.p4"
    state parse_ipv4_no_options {
        local_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (1, 0) : parse_icmp;
            (2, 0) : parse_igmp;
            (6, 0) : parse_tcp;
            (17, 0) : parse_udp;







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
# 292 "../../p4c-5288/shared/parde.p4"
        transition select(hdr.ipv6.next_hdr) {
            58 : parse_icmp;
            6 : parse_tcp;
            17 : parse_udp;
# 306 "../../p4c-5288/shared/parde.p4"
            default : accept;
        }



    }
# 480 "../../p4c-5288/shared/parde.p4"
    state parse_udp {
        pkt.extract(hdr.udp);
# 491 "../../p4c-5288/shared/parde.p4"
        transition select(hdr.udp.dst_port) {
            2123 : parse_gtp_u;

            udp_port_vxlan : parse_vxlan;






            4791 : parse_rocev2;
                default : accept;
            }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
# 517 "../../p4c-5288/shared/parde.p4"
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



        transition accept;
    }

    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        local_md.tunnel.type = SWITCH_INGRESS_TUNNEL_TYPE_VXLAN;
        local_md.tunnel.vni = hdr.vxlan.vni;
        transition parse_inner_ethernet;
    }
# 565 "../../p4c-5288/shared/parde.p4"
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
# 711 "../../p4c-5288/shared/parde.p4"
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
            (_, SWITCH_PKT_SRC_GW_BRIDGED, _): parse_bridged_pkt;



            (_, _, 1) : parse_port_mirrored_metadata;
            (_, SWITCH_PKT_SRC_CLONED_EGRESS, 2) : parse_cpu_mirrored_metadata;
            (_, SWITCH_PKT_SRC_CLONED_INGRESS, 3) : parse_dtel_drop_metadata_from_ingress;



            (_, _, 3) : parse_dtel_drop_metadata_from_egress;
            (_, _, 4) : parse_dtel_switch_local_metadata;
            (_, _, 5) : parse_simple_mirrored_metadata;
            (_, SWITCH_CPU_BRIDGED, _) : parse_cpu_bridge_pkt;
        }



    }

    state parse_cpu_bridge_pkt {
        pkt.extract(hdr.bridged_md);
        pkt.extract(hdr.ethernet);
        pkt.extract(hdr.fabric);
        transition accept;
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
# 797 "../../p4c-5288/shared/parde.p4"
        local_md.lkp.l4_src_port = hdr.bridged_md.acl.l4_src_port;
        local_md.lkp.l4_dst_port = hdr.bridged_md.acl.l4_dst_port;
        local_md.lkp.tcp_flags = hdr.bridged_md.acl.tcp_flags;
# 840 "../../p4c-5288/shared/parde.p4"
        transition select(hdr.bridged_md.src) {
            SWITCH_PKT_SRC_GW_BRIDGED : parse_gw_bridged_pkt;
            _ : parse_ethernet;
        }
    }

    state parse_gw_bridged_pkt {
        pkt.extract(hdr.gw_bridged_md);
        transition parse_ethernet;
    }

    state parse_deflected_pkt {
# 894 "../../p4c-5288/shared/parde.p4"
        transition reject;

    }

    /* Below state is for mirror packet with
       Format <mirror_hd> <bridged MD> <packet> ----> SWITCH_PKT_SRC_CLONED_EGRESS_IN_PKT
       When mirror stage is egress, io_select set to 0 i.e. mirror packet ingressing from TM to egress parser
    */
    state parse_port_mirrored_with_bridged_metadata {
        switch_port_mirror_metadata_h port_md;
        switch_bridged_metadata_h b_md;
        pkt.extract(port_md);
        pkt.extract(b_md);
        pkt.extract(hdr.ethernet);
        local_md.pkt_src = port_md.src;
        local_md.mirror.session_id = port_md.session_id;
        local_md.ingress_timestamp = port_md.timestamp;
        local_md.flags.bypass_egress = true;

        local_md.mirror.type = port_md.type;





        transition accept;
    }

    /* Below state is for mirror packet with below format
        1) Format <mirror_hd> <in_packet> ----> SWITCH_PKT_SRC_CLONED_INGRESS
           Happens when mirror stage is ingress, io_select set to 0 i.e. mirror original ingress packet
        2) Format <mirror_hd> <out_packet> ----> SWITCH_PKT_SRC_CLONED_EGRESS
           Happens when mirror stage is egress, io_select set to 1 i.e. mirror final egress packet
    */
    state parse_port_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.ethernet);
        local_md.pkt_src = port_md.src;
        local_md.mirror.session_id = port_md.session_id;
        local_md.ingress_timestamp = port_md.timestamp;
        local_md.flags.bypass_egress = true;

        local_md.mirror.type = port_md.type;





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





        transition accept;
    }

    state parse_dtel_drop_metadata_from_egress {
# 1006 "../../p4c-5288/shared/parde.p4"
        transition reject;

    }

    /* Separate parse state for drop metadata from ingress, in order to set
     * hdr.dtel_report.egress_port to SWITCH_PORT_INVALID */
    state parse_dtel_drop_metadata_from_ingress {
# 1053 "../../p4c-5288/shared/parde.p4"
        transition reject;

    }
# 1074 "../../p4c-5288/shared/parde.p4"
    state parse_dtel_switch_local_metadata {
# 1123 "../../p4c-5288/shared/parde.p4"
        transition reject;

    }

    state parse_simple_mirrored_metadata {
# 1137 "../../p4c-5288/shared/parde.p4"
        transition reject;

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
            (0x88B5, _) : parse_flow_trace;






            default : parse_pad;
        }
    }

    state parse_cpu {
        local_md.flags.bypass_egress = true;
        transition select(hdr.ethernet.ether_type) {
            0x88B5 : parse_flow_trace_cpu;
            default : parse_pad;
        }
    }

    state parse_flow_trace_cpu {
        pkt.extract(hdr.flow_trace);
        transition parse_pad;
    }

    state parse_flow_trace {
        pkt.extract(hdr.flow_trace);
        transition select(hdr.flow_trace.next_hdr) {
            0 : parse_ipv4;
            1 : parse_ipv6;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol, hdr.ipv4.ihl, hdr.ipv4.frag_offset) {
# 1200 "../../p4c-5288/shared/parde.p4"
            (_, 6, _) : parse_ipv4_options;



            default : parse_pad;
        }
    }

    state parse_ipv4_options {
        pkt.extract(hdr.ipv4_option);
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
# 1221 "../../p4c-5288/shared/parde.p4"
            default : parse_pad;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            0x0800 : parse_ipv4;
            0x8100 : parse_vlan;
            0x86dd : parse_ipv6;



            default : parse_pad;
        }
    }
# 1245 "../../p4c-5288/shared/parde.p4"
    state parse_ipv6 {

        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {

            // IP_PROTOCOLS_TCP : parse_tcp;
            17 : parse_udp;
# 1260 "../../p4c-5288/shared/parde.p4"
            default : parse_pad;
        }



    }
# 1313 "../../p4c-5288/shared/parde.p4"
    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {

            udp_port_vxlan : parse_vxlan;
# 1327 "../../p4c-5288/shared/parde.p4"
            default : parse_pad;
        }
    }

    state egress_parse_sfc_pause {





        transition parse_pad;
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition parse_pad;
    }

    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;
    }
# 1356 "../../p4c-5288/shared/parde.p4"
    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : parse_pad;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition parse_pad;
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition parse_pad;
    }

    state parse_pad {






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

                 0,

                 local_md.mirror.session_id});

        } else if (ig_intr_md_for_dprsr.mirror_type == 3) {
# 1433 "../../p4c-5288/shared/parde.p4"
        } else if (ig_intr_md_for_dprsr.mirror_type == 6) {
# 1446 "../../p4c-5288/shared/parde.p4"
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

                0,

                local_md.mirror.session_id});
        }
# 1479 "../../p4c-5288/shared/parde.p4"
        else if (eg_intr_md_for_dprsr.mirror_type == 2) {
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
# 1511 "../../p4c-5288/shared/parde.p4"
        } else if (eg_intr_md_for_dprsr.mirror_type == 3) {
# 1532 "../../p4c-5288/shared/parde.p4"
        } else if (eg_intr_md_for_dprsr.mirror_type == 5) {
# 1543 "../../p4c-5288/shared/parde.p4"
        }

    }
}

control IngressNatChecksum(
    inout switch_header_t hdr,
    in switch_local_metadata_t local_md) {
    Checksum() tcp_checksum;
    Checksum() udp_checksum;
    apply {
# 1571 "../../p4c-5288/shared/parde.p4"
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
            digest.pack({local_md.ingress_outer_bd, local_md.ingress_port_lag_index, hdr.ethernet.src_addr});
        }




        pkt.emit(hdr.bridged_md); // Ingress only.
        pkt.emit(hdr.gw_bridged_md);
        pkt.emit(hdr.ethernet);

        pkt.emit(hdr.fabric);
        pkt.emit(hdr.cpu);

        pkt.emit(hdr.flow_trace);
        pkt.emit(hdr.cpu_mh);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.arp); // Ingress only.



        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv4_option);
        pkt.emit(hdr.ipv6);







        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp); // Ingress only.
        pkt.emit(hdr.icmp); // Ingress only.
        pkt.emit(hdr.igmp); // Ingress only.
        pkt.emit(hdr.rocev2_bth); // Ingress only.

        pkt.emit(hdr.vxlan);

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
# 1699 "../../p4c-5288/shared/parde.p4"
        pkt.emit(hdr.ethernet);



        pkt.emit(hdr.fabric); // Egress only.
        pkt.emit(hdr.loop_flag);
        pkt.emit(hdr.cpu); // Egress only.
        pkt.emit(hdr.timestamp); // Egress only.
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv4_option);
        pkt.emit(hdr.ipv6);







        pkt.emit(hdr.udp);






        pkt.emit(hdr.dtel); // Egress only.







        pkt.emit(hdr.dtel_report); // Egress only.
        pkt.emit(hdr.dtel_switch_local_report); // Egress only.

        pkt.emit(hdr.dtel_drop_report); // Egress only.

        pkt.emit(hdr.vxlan);

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
# 153 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/switch-tofino/largetable/table_parde.p4" 1
//=============================================================================
// Table 23 Ingress parser
//=============================================================================


parser Tablep23IParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_local_metadata_t local_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum() tcp_checksum;
    Checksum() udp_checksum;

    state start {
        pkt.extract(ig_intr_md);
        local_md.ingress_port = ig_intr_md.ingress_port;
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type, local_md.ingress_port) {
            (_, 320) : parse_cpu;
            (_, 510) : parse_fake_start;
            (0x88B5, _) : parse_flow_trace;
            (0x0800, _) : parse_ipv4;
            (0x86dd, _) : parse_ipv6;
            default : accept;
        }
    }

    state parse_fake_start {// To make sure the field can be emitted
        pkt.extract(hdr.flow_trace);
        transition select(hdr.flow_trace.next_hdr) {
            2 : parse_fake_fpga_meta;
            _ : accept;
        }
    }

    state parse_fake_fpga_meta {
        from_fpga_h from_fpga;
        pkt.extract(from_fpga);
        local_md.from_fpga_snat_ip = from_fpga.nat_ip;
        local_md.from_fpga_dnat_ip = from_fpga.nat_ip;
        local_md.from_fpga_local_vtep = from_fpga.local_vtep;
        local_md.from_fpga_remote_vtep = from_fpga.remote_vtep;
        local_md.from_fpga_vni = from_fpga.vni;
        local_md.from_fpga_encap_type = from_fpga.encap_type;
        local_md.from_fpga_nat_type = from_fpga.nat_type;
        local_md.from_fpga_next_hdr = from_fpga.next_hdr;
        transition select(from_fpga.next_hdr) {
            0 : parse_ipv4;
            1 : parse_ipv6;
        }
    }

    //state parse_fake_fpga_mode_0 {
    //    transition select(hdr.fpga_mh.table_enable) {
    //        0b10000 : parse_mode_0_table_10000_key;
    //    }
    //}

    //state parse_fake_fpga_mode_1 {
    //    transition select(hdr.fpga_mh.table_enable) {
    //        0b10000 : parse_mode_1_table_10000_key;
    //    }
    //}

    //state parse_mode_0_table_10000_key {
    //    pkt.extract(hdr.table_1_key);
    //    transition select(hdr.fpga_mh.next_hdr) {
    //        0 : parse_ipv4;
    //        1 : parse_ipv6;
    //    }
    //}

    //state parse_mode_1_table_10000_key {
    //    pkt.extract(hdr.table_2_key);
    //    transition select(hdr.fpga_mh.next_hdr) {
    //        0 : parse_ipv4;
    //        1 : parse_ipv6;
    //    }
    //}

    state parse_cpu {
        transition accept;
    }

    state parse_flow_trace {
        pkt.extract(hdr.flow_trace);
        transition select(hdr.flow_trace.next_hdr) {
            0 : parse_ipv4;
            1 : parse_ipv6;
            2 : parse_fpga_meta;
            3 : parse_cpu_meta;
        }
    }

    state parse_fpga_meta {
        from_fpga_h from_fpga;
        pkt.extract(from_fpga);
        local_md.from_fpga_snat_ip = from_fpga.nat_ip;
        local_md.from_fpga_dnat_ip = from_fpga.nat_ip;
        local_md.from_fpga_local_vtep = from_fpga.local_vtep;
        local_md.from_fpga_remote_vtep = from_fpga.remote_vtep;
        local_md.from_fpga_vni = from_fpga.vni;
        local_md.from_fpga_encap_type = from_fpga.encap_type;
        local_md.from_fpga_nat_type = from_fpga.nat_type;
        local_md.from_fpga_next_hdr = from_fpga.next_hdr;
        transition select(from_fpga.next_hdr) {
            0 : parse_ipv4;
            1 : parse_ipv6;
        }
    }

    // state parse_fpga_mode_0 {
    //     transition select(hdr.fpga_mh.table_enable) {
    //         0b10000 : parse_mode_0_table_10000_result;
    //     }
    // }
// 
    // state parse_fpga_mode_1 {
    //     transition select(hdr.fpga_mh.table_enable) {
    //         0b10000 : parse_mode_1_table_10000_result;
    //     }
    // }
// 
    // state parse_mode_0_table_10000_result {
    //     pkt.extract(hdr.table_1_result);
    //     transition select(hdr.fpga_mh.next_hdr) {
    //         0 : parse_nic_ipv4;
    //         1 : parse_nic_ipv6;
    //     }
    // }
// 
    // state parse_mode_1_table_10000_result {
    //     pkt.extract(hdr.table_2_result);
    //     transition select(hdr.fpga_mh.next_hdr) {
    //         0 : parse_nic_ipv4;
    //         1 : parse_nic_ipv6;
    //     }
    // }

    state parse_cpu_meta {
        pkt.extract(hdr.cpu_mh);
        transition select(hdr.cpu_mh.next_hdr) {
            0 : parse_nic_ipv4;
            1 : parse_nic_ipv6;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.bridged_md);
        pkt.extract(hdr.gw_bridged_md);
        pkt.extract(hdr.ipv4);
        tcp_checksum.subtract({hdr.ipv4.src_addr,hdr.ipv4.dst_addr});
        udp_checksum.subtract({hdr.ipv4.src_addr,hdr.ipv4.dst_addr});
        transition select(hdr.ipv4.ihl) {
            5 : parse_ipv4_no_options;
            6 : parse_ipv4_options;
            default : accept;
        }
    }

    state parse_nic_ipv4 {
        pkt.extract(hdr.hash_bridged_md);
        pkt.extract(hdr.compress_bridged_md);
        pkt.extract(hdr.ipv4);
        tcp_checksum.subtract({hdr.ipv4.src_addr,hdr.ipv4.dst_addr});
        udp_checksum.subtract({hdr.ipv4.src_addr,hdr.ipv4.dst_addr});
        transition select(hdr.ipv4.ihl) {
            5 : parse_ipv4_no_options;
            6 : parse_ipv4_options;
            default : accept;
        }
    }

    state parse_ipv4_options {
        // Only a single 32-bit option (e.g. router alert) is supported.
        pkt.extract(hdr.ipv4_option);
        //ipv4_checksum.add(hdr.ipv4_option);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        //local_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (17, 0) : parse_inner_udp;
            (6, 0) : parse_inner_tcp;
            // Do NOT parse the next header if IP packet is fragmented.
            default : accept;
        }
    }

    state parse_ipv6 {

        pkt.extract(hdr.bridged_md);
        pkt.extract(hdr.gw_bridged_md);
        pkt.extract(hdr.ipv6);
        tcp_checksum.subtract({hdr.ipv6.src_addr,hdr.ipv6.dst_addr});
        udp_checksum.subtract({hdr.ipv6.src_addr,hdr.ipv6.dst_addr});
        transition select(hdr.ipv6.next_hdr) {
            17 : parse_inner_udp;
            6: parse_inner_tcp;
            default : accept;
        }



    }

    state parse_nic_ipv6 {

        pkt.extract(hdr.hash_bridged_md);
        pkt.extract(hdr.compress_bridged_md);
        pkt.extract(hdr.ipv6);
        tcp_checksum.subtract({hdr.ipv6.src_addr,hdr.ipv6.dst_addr});
        udp_checksum.subtract({hdr.ipv6.src_addr,hdr.ipv6.dst_addr});
        transition select(hdr.ipv6.next_hdr) {
            17 : parse_inner_udp;
            6: parse_inner_tcp;
            default : accept;
        }



    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        udp_checksum.subtract_all_and_deposit(local_md.tcp_udp_checksum);
        udp_checksum.subtract({hdr.inner_udp.checksum});
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        tcp_checksum.subtract_all_and_deposit(local_md.tcp_udp_checksum);
        tcp_checksum.subtract({hdr.inner_tcp.checksum});
        transition accept;
    }

}

//=============================================================================
// Table 23 Ingress Deparser
//=============================================================================

control Tablep23IDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_local_metadata_t local_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    Checksum() tcp_checksum;
    Checksum() udp_checksum;


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
            hdr.inner_ipv4.dst_addr,
            hdr.ipv4_option.type,
            hdr.ipv4_option.length,
            hdr.ipv4_option.value});




        hdr.inner_tcp.checksum = tcp_checksum.update({
            local_md.lkp.ip_src_addr,
            local_md.lkp.ip_dst_addr,
            local_md.tcp_udp_checksum});

        if (local_md.checksum_upd_udp) {
            hdr.inner_udp.checksum = udp_checksum.update(data = {
                local_md.lkp.ip_src_addr,
                local_md.lkp.ip_dst_addr,
                local_md.tcp_udp_checksum
            }, zeros_as_ones = true);
            // UDP specific checksum handling
        }

        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.gw_bridged_md);
        //pkt.emit(hdr.inner_bridged_md);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.flow_trace);
        //pkt.emit(hdr.fpga_mh);
        pkt.emit(hdr.cpu_mh);
        //pkt.emit(hdr.table_1_key);
        // pkt.emit(hdr.table_1_result);
        //pkt.emit(hdr.table_2_key);
        // pkt.emit(hdr.table_2_result);
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
// Table 23 Egress parser
//=============================================================================
parser Tablep23EParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_local_metadata_t local_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    @critical
    state start {
        pkt.extract(eg_intr_md);
        local_md.pkt_length = eg_intr_md.pkt_length;
        local_md.egress_port = eg_intr_md.egress_port;
        //local_md.qos.qdepth = eg_intr_md.deq_qdepth;
        transition parse_pkt;
    }

    state parse_pkt {
        transition select(local_md.egress_port) {
            320 : parse_cpu;
            _ : parse_bridged_pkt;
        }
    }

    state parse_cpu {
        transition accept;
    }

    state parse_bridged_pkt {
        pkt.extract(hdr.bridged_md);
        pkt.extract(hdr.gw_bridged_md);
        local_md.nic.tofino_to_nic = hdr.bridged_md.nic.tofino_to_nic;
        //local_md.flags.to_fpga = hdr.bridged_md.flags.to_fpga;
        //transition select(local_md.flags.to_fpga) {
        //    true : parse_ethernet_to_fpga;
        //    false : parse_ethernet;
        //}
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x88B5 : parse_flow_trace;
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            _ : accept;
        }
    }

    state parse_flow_trace {
        pkt.extract(hdr.flow_trace);
        transition select(hdr.flow_trace.next_hdr) {
            3 : parse_to_nic;
            0 : parse_ipv4;
            1 : parse_ipv6;
            _ : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition accept;
    }

    state parse_to_nic {
        pkt.extract(hdr.cpu_mh);
        transition accept;
    }

    //state parse_ethernet_to_fpga {
    //    pkt.extract(hdr.ethernet);
    //    pkt.extract(hdr.flow_trace);  
    //    pkt.extract(hdr.fpga_mh);
    //    transition select(hdr.fpga_mh.mode) {
    //        0 : parse_table_1_key;
    //        1 : parse_table_2_key;
    //    }
    //}
//
    //state parse_table_1_key {
    //    pkt.extract(hdr.table_1_key);
    //    transition accept;
    //}
//
    //state parse_table_2_key {
    //    pkt.extract(hdr.table_2_key);
    //    transition accept;
    //}
}

//=============================================================================
// Table 23 Egress deparser
//=============================================================================

control Tablep23EDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_local_metadata_t local_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    apply {
        // hdr.ipv4.hdr_checksum = ipv4_checksum.update({
        //     hdr.ipv4.version,
        //     hdr.ipv4.ihl,
        //     hdr.ipv4.diffserv,
        //     hdr.ipv4.total_len,
        //     hdr.ipv4.identification,
        //     hdr.ipv4.flags,
        //     hdr.ipv4.frag_offset,
        //     hdr.ipv4.ttl,
        //     hdr.ipv4.protocol,
        //     hdr.ipv4.src_addr,
        //     hdr.ipv4.dst_addr});
        //     // hdr.opaque_option.type,
        //     // hdr.opaque_option.length,
        //     // hdr.opaque_option.value});

        // hdr.inner_ipv4.hdr_checksum = inner_ipv4_checksum.update({
        //     hdr.inner_ipv4.version,
        //     hdr.inner_ipv4.ihl,
        //     hdr.inner_ipv4.diffserv,
        //     hdr.inner_ipv4.total_len,
        //     hdr.inner_ipv4.identification,
        //     hdr.inner_ipv4.flags,
        //     hdr.inner_ipv4.frag_offset,
        //     hdr.inner_ipv4.ttl,
        //     hdr.inner_ipv4.protocol,
        //     hdr.inner_ipv4.src_addr,
        //     hdr.inner_ipv4.dst_addr});

        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.fabric); // Egress only.
        pkt.emit(hdr.cpu); // Egress only.
        pkt.emit(hdr.timestamp); // Egress only.
        pkt.emit(hdr.flow_trace);
        //pkt.emit(hdr.fpga_mh);
        //pkt.emit(hdr.table_1_key);
        // pkt.emit(hdr.table_1_result);
        //pkt.emit(hdr.table_2_key);
        // pkt.emit(hdr.table_2_result);
        pkt.emit(hdr.to_fpga);
        pkt.emit(hdr.to_fpga_padding);
        pkt.emit(hdr.cpu_mh);
        pkt.emit(hdr.hash_bridged_md);
        pkt.emit(hdr.compress_bridged_md);
        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.gw_bridged_md);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
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

//=============================================================================
// Table 1 Egress parser
//=============================================================================
parser Tablep1EParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_local_metadata_t local_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    Checksum() tcp_checksum;
    Checksum() udp_checksum;

    @critical
    state start {
        pkt.extract(eg_intr_md);
        local_md.pkt_length = eg_intr_md.pkt_length;
        local_md.egress_port = eg_intr_md.egress_port;
        local_md.qos.qdepth = eg_intr_md.deq_qdepth;
        transition parse_bridged_pkt;
    }

    state parse_bridged_pkt {
        pkt.extract(hdr.bridged_md);
        // hdr.bridged_md.base.routed = true;
        // hdr.bridged_md.base.bypass_egress = false;
        // local_md.hash = hdr.bridged_md.table_result.hash;
        // local_md.tunnel.encap = hdr.bridged_md.table_result.encap;
        // local_md.tunnel.terminate = hdr.bridged_md.table_result.terminate;
        // local_md.tunnel.eip_net_hit = hdr.bridged_md.table_result.eip_net_hit;
        //local_md.tunnel.vni_type = hdr.bridged_md.table_result.vni_type; 
        local_md.nic.tofino_to_nic = hdr.bridged_md.nic.tofino_to_nic;
        transition select(local_md.nic.tofino_to_nic) {
            1 : parse_pkt_from_nic;
            0 : parse_pkt_not_from_nic;
        }
    }

    state parse_pkt_not_from_nic {
        //pkt.extract(hdr.inner_bridged_md);
        /*
        transition select(hdr.bridged_md.table_result.terminate) {
            true : parse_vxlan_ethernet;
            false : parse_ethernet;
        }
        */
        transition parse_ethernet;
    }

    state parse_pkt_from_nic {
        pkt.extract(hdr.ethernet);
        pkt.extract(hdr.flow_trace);
        transition parse_pad;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x88B5 : parse_flow_trace;
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
        }
    }

    state parse_vxlan_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x88B5 : parse_vxlan_flow_trace;
            0x0800 : parse_vxlan_ipv4;
            0x86dd : parse_vxlan_ipv6;
        }
    }

    state parse_flow_trace {
        pkt.extract(hdr.flow_trace);
        transition select(hdr.flow_trace.next_hdr) {
            0 : parse_ipv4;
            1 : parse_ipv6;
        }
    }

    state parse_vxlan_flow_trace {
        pkt.extract(hdr.flow_trace);
        transition select(hdr.flow_trace.next_hdr) {
            0 : parse_vxlan_ipv4;
            1 : parse_vxlan_ipv6;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        tcp_checksum.subtract({hdr.inner_ipv4.src_addr,hdr.inner_ipv4.dst_addr});
        udp_checksum.subtract({hdr.inner_ipv4.src_addr,hdr.inner_ipv4.dst_addr});
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.ihl, hdr.inner_ipv4.frag_offset) {
            (17, 5, 0) : parse_udp;
            (6, 5, 0) : parse_tcp;
            (_, 6, _) : parse_ipv4_options;
            default : parse_pad;
        }
    }

    state parse_ipv4_options {
        pkt.extract(hdr.ipv4_option);
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.frag_offset) {
            (17, 0) : parse_udp;
            (6, 0) : parse_tcp;
            default : parse_pad;
        }
    }

    state parse_vxlan_ipv4 {
        pkt.extract(hdr.ipv4);
        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        transition select(hdr.ipv4.protocol, hdr.ipv4.ihl, hdr.ipv4.frag_offset) {
            (17, 5, 0) : parse_vxlan_udp;
            default : parse_pad;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        tcp_checksum.subtract({hdr.inner_ipv6.src_addr,hdr.inner_ipv6.dst_addr});
        udp_checksum.subtract({hdr.inner_ipv6.src_addr,hdr.inner_ipv6.dst_addr});
        transition select(hdr.inner_ipv6.next_hdr) {
            17 : parse_udp;
            6 : parse_tcp;
            default : parse_pad;
        }
    }

    state parse_vxlan_ipv6 {
        pkt.extract(hdr.ipv6);
        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        transition select(hdr.ipv6.next_hdr) {
            17 : parse_vxlan_udp;
            default : parse_pad;
        }
    }

    state parse_udp {
        pkt.extract(hdr.inner_udp);
        udp_checksum.subtract_all_and_deposit(local_md.tcp_udp_checksum);
        udp_checksum.subtract({hdr.inner_udp.checksum});
        transition parse_pad;
    }

    state parse_tcp {
        pkt.extract(hdr.inner_tcp);
        tcp_checksum.subtract_all_and_deposit(local_md.tcp_udp_checksum);
        tcp_checksum.subtract({hdr.inner_tcp.checksum});
        transition parse_pad;
    }

    state parse_vxlan_udp {
        pkt.extract(hdr.udp);
        transition parse_vxlan;
    }

    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        local_md.tunnel.vni = hdr.vxlan.vni;
        transition parse_inner_ethernet;
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : parse_pad;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        tcp_checksum.subtract({hdr.inner_ipv4.src_addr,hdr.inner_ipv4.dst_addr});
        udp_checksum.subtract({hdr.inner_ipv4.src_addr,hdr.inner_ipv4.dst_addr});
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.ihl, hdr.inner_ipv4.frag_offset) {
            (17, 5, 0) : parse_inner_udp;
            (6, 5, 0) : parse_inner_tcp;
            (_, 6, _) : parse_inner_ipv4_options;
            default : parse_pad;
        }
    }

    state parse_inner_ipv4_options {
        pkt.extract(hdr.ipv4_option);
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.frag_offset) {
            (17, 0) : parse_inner_udp;
            (6, 0) : parse_inner_tcp;
            default : parse_pad;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        tcp_checksum.subtract({hdr.inner_ipv6.src_addr,hdr.inner_ipv6.dst_addr});
        udp_checksum.subtract({hdr.inner_ipv6.src_addr,hdr.inner_ipv6.dst_addr});
        transition select(hdr.inner_ipv6.next_hdr) {
            17 : parse_inner_udp;
            6 : parse_inner_tcp;
            default : parse_pad;
        }
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        udp_checksum.subtract_all_and_deposit(local_md.tcp_udp_checksum);
        udp_checksum.subtract({hdr.inner_udp.checksum});
        transition parse_pad;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        tcp_checksum.subtract_all_and_deposit(local_md.tcp_udp_checksum);
        tcp_checksum.subtract({hdr.inner_tcp.checksum});
        transition parse_pad;
    }

    state parse_pad {






      transition accept;
    }
}


//=============================================================================
// Table 1 Egress deparser
//=============================================================================
control Tablep1EDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_local_metadata_t local_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    Checksum() tcp_checksum;
    Checksum() udp_checksum;

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
            hdr.inner_ipv4.dst_addr,
            hdr.ipv4_option.type,
            hdr.ipv4_option.length,
            hdr.ipv4_option.value});


        // hdr.inner_tcp.checksum = tcp_checksum.update({
        //     local_md.lkp.ip_src_addr,
        //     local_md.lkp.ip_dst_addr,
        //     local_md.tcp_udp_checksum});

        // if (local_md.checksum_upd_udp) {
        //     hdr.inner_udp.checksum = udp_checksum.update(data = {
        //         local_md.lkp.ip_src_addr,
        //         local_md.lkp.ip_dst_addr,
        //         local_md.tcp_udp_checksum
        //     }, zeros_as_ones = true);
        //     // UDP specific checksum handling
        // }

        if (hdr.inner_ipv4.isValid()) {
            hdr.inner_tcp.checksum = tcp_checksum.update({
                hdr.inner_ipv4.src_addr,
                hdr.inner_ipv4.dst_addr,
                local_md.tcp_udp_checksum});

            if (local_md.checksum_upd_udp) {
                hdr.inner_udp.checksum = udp_checksum.update(data = {
                    hdr.inner_ipv4.src_addr,
                    hdr.inner_ipv4.dst_addr,
                    local_md.tcp_udp_checksum
                }, zeros_as_ones = true);
                // UDP specific checksum handling
            }
        }

        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.flow_trace);
        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.erspan); // Egress only.
        pkt.emit(hdr.erspan_type2); // Egress only.
        pkt.emit(hdr.erspan_type3); // Egress only.
        pkt.emit(hdr.erspan_platform); // Egress only.
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.ipv4_option);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);



    }
}

//=============================================================================
// Table 1 Ingress parser
//=============================================================================
parser Tablep1IParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_local_metadata_t local_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type, ig_intr_md.ingress_port) {
            (0x0800, _) : parse_ipv4;
            (0x86dd, _) : parse_ipv6;
            (0x88B5, _) : parse_flow_trace;
            default : accept;
        }
    }

    state parse_flow_trace {
        pkt.extract(hdr.flow_trace);
        pkt.extract(hdr.bridged_md);
        local_md.ingress_port_lag_index = hdr.bridged_md.base.ingress_port_lag_index;
        local_md.qos.qid = hdr.bridged_md.base.qid;
        //local_md.hash = hdr.bridged_md.table_result.hash;
        //local_md.lag_hash = hdr.bridged_md.table_result.hash;
        local_md.vrf = hdr.bridged_md.base.vrf;
        transition select(hdr.flow_trace.next_hdr) {
            0 : parse_ipv4;
            1 : parse_ipv6;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition accept;
    }
}


//=============================================================================
// Table 1 Ingress deparser
//=============================================================================
control Tablep1IDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_local_metadata_t local_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr.bridged_md); // Ingress only.
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.flow_trace);
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
# 154 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/shared/port.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/


# 1 "../../p4c-5288/shared/mirror_rewrite.p4" 1

/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/





# 1 "../../p4c-5288/shared/l2.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/
# 25 "../../p4c-5288/shared/mirror_rewrite.p4" 2

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
    @name(".rewrite_")
    action rewrite_(switch_qid_t qid) {
        local_md.qos.qid = qid;
    }
# 138 "../../p4c-5288/shared/mirror_rewrite.p4"
    //
    // ---------------- ERSPAN Type II ---------------- 
    //
    @name(".rewrite_erspan_type2")
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

    @name(".rewrite_erspan_type2_with_vlan")
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
    @name(".rewrite_erspan_type3")
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

    @name(".rewrite_erspan_type3_with_vlan")
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
# 388 "../../p4c-5288/shared/mirror_rewrite.p4"
    @ways(2)

    @name(".mirror_rewrite")
    table rewrite {
        key = { local_md.mirror.session_id : exact; }
        actions = {
            NoAction;
            rewrite_;




            rewrite_erspan_type2;
            rewrite_erspan_type2_with_vlan;


            rewrite_erspan_type3;
            rewrite_erspan_type3_with_vlan;
# 421 "../../p4c-5288/shared/mirror_rewrite.p4"
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
# 459 "../../p4c-5288/shared/mirror_rewrite.p4"
    table pkt_length {
        key = { local_md.mirror.type : exact; }
        actions = {
                adjust_length;



        }
        const entries = {
            //-14
            2 : adjust_length(0xFFF2);
# 489 "../../p4c-5288/shared/mirror_rewrite.p4"
            /* - len(switch_port_mirror_metadata_h) - 4 bytes of CRC */
            //-12
            1 : adjust_length(0xFFF4);
            /* len(telemetry report v0.5 header)
             * + len(telemetry drop report header)
             * - len(switch_dtel_drop_mirror_metadata_h) - 4 bytes of CRC */
            3 : adjust_length(0x1);
            /* len(telemetry report v0.5 header)
             * + len(telemetry switch local report header)
             * - len(switch_dtel_switch_local_mirror_metadata_h)
             * - 4 bytes of CRC */
            //-1
            4 : adjust_length(0xFFFF);

            /* - len(switch_simple_mirror_metadata_h) - 4 bytes of CRC */
            //-8
            5: adjust_length(0xFFF8);
# 529 "../../p4c-5288/shared/mirror_rewrite.p4"
            /* len(telemetry report v0.5 header)
             * + len(telemetry drop report header) - 4 bytes of CRC */
            255: adjust_length(20);

        }
    }

    action rewrite_ipv4_udp_len_truncate() {
# 548 "../../p4c-5288/shared/mirror_rewrite.p4"
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
# 585 "../../p4c-5288/shared/mirror_rewrite.p4"
    }
}
# 21 "../../p4c-5288/shared/port.p4" 2
# 1 "../../p4c-5288/shared/rmac.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/


control IngressRmac(inout switch_header_t hdr,
                    inout switch_local_metadata_t local_md)(
                    switch_uint32_t port_vlan_table_size,
                    switch_uint32_t vlan_table_size=4096) {
    //
    // **************** Router MAC Check ************************
    //
    @name(".rmac_miss")
    action rmac_miss() {
        local_md.flags.rmac_hit = false;
    }
    @name(".rmac_hit")
    action rmac_hit() {
        local_md.flags.rmac_hit = true;
    }

    @name(".pv_rmac")
    table pv_rmac {
        key = {
            local_md.ingress_port_lag_index : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
            hdr.vlan_tag[0].vid : ternary;
            hdr.ethernet.dst_addr : ternary;
        }

        actions = {
            rmac_miss;
            rmac_hit;
        }

        const default_action = rmac_miss;
        size = port_vlan_table_size;
    }

    @name(".vlan_rmac")
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
# 22 "../../p4c-5288/shared/port.p4" 2

//-----------------------------------------------------------------------------
// Ingress port mirroring
//-----------------------------------------------------------------------------
control IngressPortMirror(
        in switch_port_t port,
        inout switch_mirror_metadata_t mirror_md)(
        switch_uint32_t table_size=288) {

    @name(".set_ingress_mirror_id")
    action set_ingress_mirror_id(switch_mirror_session_t session_id, switch_mirror_meter_id_t meter_index) {
        mirror_md.type = 1;
        mirror_md.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        mirror_md.session_id = session_id;



    }

    @name(".ingress_port_mirror")
    table ingress_port_mirror {
        key = { port : exact; }
        actions = {
            NoAction;
            set_ingress_mirror_id;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        ingress_port_mirror.apply();
    }
}

//-----------------------------------------------------------------------------
// Egress port mirroring
//-----------------------------------------------------------------------------
control EgressPortMirror(
        in switch_port_t port,
        inout switch_mirror_metadata_t mirror_md)(
        switch_uint32_t table_size=288) {

    @name(".set_egress_mirror_id")
    action set_egress_mirror_id(switch_mirror_session_t session_id, switch_mirror_meter_id_t meter_index) {
        mirror_md.type = 1;
        mirror_md.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        mirror_md.session_id = session_id;



    }

    @name(".egress_port_mirror")
    table egress_port_mirror {
        key = { port : exact; }
        actions = {
            NoAction;
            set_egress_mirror_id;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        egress_port_mirror.apply();
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

    IngressPortMirror(port_table_size) port_mirror;
    IngressRmac(port_vlan_table_size, vlan_table_size) rmac;
    @name(".bd_action_profile")
    ActionProfile(bd_table_size) bd_action_profile;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;

    // This register is used to check whether a port is a mermber of a vlan (bd)
    // or not. (port << 12 | vid) is used as the index to read the membership
    // status.To save resources, only 7-bit local port id is used to calculate
    // the indes.
    const bit<32> vlan_membership_size = 1 << 19;
    @name(".vlan_membership")
    Register<bit<1>, bit<32>>(vlan_membership_size, 0) vlan_membership;
    RegisterAction<bit<1>, bit<32>, bit<1>>(vlan_membership) check_vlan_membership = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = ~val;
        }
    };

    action terminate_cpu_packet() {
        local_md.ingress_port = (switch_port_t) hdr.cpu.ingress_port;
        local_md.egress_port_lag_index =
            (switch_port_lag_index_t) hdr.cpu.port_lag_index;
        ig_intr_md_for_tm.qid = (switch_qid_t) hdr.cpu.egress_queue;
        local_md.flags.bypass_egress = (bool) hdr.cpu.tx_bypass;
        hdr.ethernet.ether_type = hdr.cpu.ether_type;
    }

    @name(".set_cpu_port_properties")
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

    @name(".set_port_properties")
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




        local_md.sflow.session_id = sflow_session_id;

    }

    @placement_priority(2)
    @name(".ingress_port_mapping")
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

    @name(".port_vlan_miss")
    action port_vlan_miss() {
        //local_md.flags.port_vlan_miss = true;
    }

    @name(".set_bd_properties")
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
                             bool mpls_enable,
                             switch_multicast_rpf_group_t mrpf_group,
                             switch_nat_zone_t zone) {
        local_md.bd = bd;
        local_md.ingress_outer_bd = bd;

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
# 270 "../../p4c-5288/shared/port.p4"
    // (port, vlan) --> bd mapping -- Following set of entres are needed:
    //   (port, 0, *)    L3 interface.
    //   (port, 1, vlan) L3 sub-interface.
    //   (port, 0, *)    Access port + untagged packet.
    //   (port, 1, vlan) Access port + packets tagged with access-vlan.
    //   (port, 1, 0)    Access port + .1p tagged packets.
    //   (port, 1, vlan) L2 sub-port.
    //   (port, 0, *)    Trunk port if native-vlan is not tagged.

    @placement_priority(2)
    @name(".port_vlan_to_bd_mapping")
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
    @name(".vlan_to_bd_mapping")
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

    @name(".cpu_to_bd_mapping")
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

    @name(".set_peer_link_properties")
    action set_peer_link_properties() {
        local_md.flags.peer_link = true;
    }

    @name(".peer_link")
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

        port_mirror.apply(local_md.ingress_port, local_md.mirror);


        switch (port_mapping.apply().action_run) {






            set_port_properties : {



                    if (!port_vlan_to_bd_mapping.apply().hit) {
                        if (hdr.vlan_tag[0].isValid())
                            vlan_to_bd_mapping.apply();
                    }
# 379 "../../p4c-5288/shared/port.p4"
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
# 410 "../../p4c-5288/shared/port.p4"
/* programming notes:
 *  - Program one set of entry for every local port on the pipe
 *  - I/G bit is bit 40 of eth.dst_addr.
 *  - Entries are in decreasing order of priority
 *  - ipv4 received = discards + non_uc + uc
 *  - ipv6 received = discards + bc + mc + uc
 *  - ipv6 non_uc = bc + mc

 *  { is_ipv4, is_ipv6, drop, copy_to_cpu, eth.dst_addr } = counter_name
 *  {  true, false,  true, false, X        } = ipv4 discards
 *  {  true, false, false,     X, ig_bit=1 } = ipv4 non_uc
 *  {  true, false, false,     X, ig_bit=0 } = ipv4 uc

 *  { false,  true,  true, false, X        } = ipv6 discards
 *  { false,  true, false,     X, all_1s   } = ipv6 bc
 *  { false,  true, false,     X, ig_bit=1 } = ipv6 mc
 *  { false,  true, false,     X,        X } = ipv6 uc
 */

//---------------------------------------------------------------------------------------------------------
// Ingress Port IP statistics
//---------------------------------------------------------------------------------------------------------
control IngressPortStats(
    in switch_header_t hdr,
    in switch_port_t port,
    in bit<1> drop, in bit<1> copy_to_cpu) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    @name(".ingress_ip_stats_count")
    action no_action() {
        stats.count();
    }

    @name(".ingress_ip_port_stats")
    table ingress_ip_port_stats {
        key = {
            port : exact;
            hdr.ipv4.isValid() : ternary;
            hdr.ipv6.isValid() : ternary;
            drop : ternary;
            copy_to_cpu : ternary;
            hdr.ethernet.dst_addr : ternary;
        }
        actions = { no_action; }
        const default_action = no_action;
        size = 512;
        counters = stats;
    }

    apply {
        ingress_ip_port_stats.apply();
    }
}

//---------------------------------------------------------------------------------------------------------
// Egress Port IP statistics
//---------------------------------------------------------------------------------------------------------
control EgressPortStats(
    in switch_header_t hdr,
    in switch_port_t port,
    in bit<1> drop, in bit<1> copy_to_cpu) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    @name(".egress_ip_stats_count")
    action no_action() {
        stats.count();
    }

    @name(".egress_ip_port_stats")
    table egress_ip_port_stats {
        key = {
            port : exact;
            hdr.ipv4.isValid() : ternary;
            hdr.ipv6.isValid() : ternary;
            drop : ternary;
            copy_to_cpu : ternary;
            hdr.ethernet.dst_addr : ternary;
        }
        actions = { no_action; }
        const default_action = no_action;
        size = 512;
        counters = stats;
    }

    apply {
        egress_ip_port_stats.apply();
    }
}

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
# 554 "../../p4c-5288/shared/port.p4"
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

    @name(".lag_action_profile")
    ActionProfile(LAG_SELECTOR_TABLE_SIZE) lag_action_profile;
    @name(".lag_selector")
    ActionSelector(lag_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   LAG_MAX_MEMBERS_PER_GROUP,
                   LAG_GROUP_TABLE_SIZE) lag_selector;

    @name(".set_lag_port")
    action set_lag_port(switch_port_t port) {
        egress_port = port;
    }

    @name(".set_peer_link_port")
    action set_peer_link_port(switch_port_t port, switch_port_lag_index_t port_lag_index) {
        egress_port = port;
        local_md.egress_port_lag_index = port_lag_index;
        local_md.checks.same_if = local_md.ingress_port_lag_index ^ port_lag_index;
    }

    @name(".lag_miss")
    action lag_miss() { }

    @name(".lag")
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
//-----------------------------------------------------------------------------
control EgressPortMapping(
        inout switch_header_t hdr,
        inout switch_local_metadata_t local_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        in switch_port_t port)(
        switch_uint32_t table_size=288) {

    @name(".set_port_normal")
    action set_port_normal(switch_port_lag_index_t port_lag_index,
                           switch_eg_port_lag_label_t port_lag_label,
                           switch_qos_group_t qos_group,
                           switch_meter_index_t meter_index,
                           switch_sflow_id_t sflow_session_id,
                           bool mlag_member,
                           switch_eg_port_lag_label_t acl_out_ports) {
        local_md.egress_port_lag_index = port_lag_index;
        local_md.egress_port_lag_label = port_lag_label;
        local_md.qos.group = qos_group;
# 664 "../../p4c-5288/shared/port.p4"
    }

    @name(".egress_port_mapping")
    table port_mapping {
        key = { port : exact; }

        actions = {
            set_port_normal;
        }

        size = table_size;
    }
# 700 "../../p4c-5288/shared/port.p4"
    apply {
        port_mapping.apply();




    }
}
# 773 "../../p4c-5288/shared/port.p4"
//-----------------------------------------------------------------------------
// CPU-RX Header Insertion
//-----------------------------------------------------------------------------
control EgressCpuRewrite(
        inout switch_header_t hdr,
        inout switch_local_metadata_t local_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        in switch_port_t port)(
        switch_uint32_t table_size=288) {

    @name(".cpu_rewrite")
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

    @name(".cpu_port_rewrite")
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
# 155 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
//#include "validation.p4"
# 1 "../../p4c-5288/shared/mirror_rewrite.p4" 1

/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/
# 157 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/shared/multicast.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/
# 452 "../../p4c-5288/shared/multicast.p4"
//-----------------------------------------------------------------------------
// Multicast flooding
//-----------------------------------------------------------------------------
control MulticastFlooding(inout switch_local_metadata_t local_md)(switch_uint32_t table_size) {

    @name(".flood")
    action flood(switch_mgid_t mgid) {
        local_md.multicast.id = mgid;
    }

    @name(".bd_flood")
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
    @name(".multicast_rid_hit")
    action rid_hit(switch_bd_t bd) {
        local_md.checks.same_bd = bd ^ local_md.bd;
        local_md.bd = bd;
    }

    action rid_miss() {
        local_md.flags.routed = false;
    }

    @name(".multicast_rid")
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
# 520 "../../p4c-5288/shared/multicast.p4"
    }
}
# 158 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/shared/qos.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/





# 1 "../../p4c-5288/shared/acl.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/
# 24 "../../p4c-5288/shared/qos.p4" 2

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
    @name(".ecn_acl.set_ingress_color")
    action set_ingress_color(switch_pkt_color_t color) {
        pkt_color = color;
    }

    @name(".ecn_acl.acl")
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
// Ingress PFC Watchdog
// Once PFC storm is detected on a queue, the PFC watchdog can drop or forward at per queue level.
// On drop action, all existing packets in the output queue and all subsequent packets destined to
// the output queue are discarded.
//
// @param port
// @param qid : Queue Id.
// @param table_size : Size of the ACL table.
//-------------------------------------------------------------------------------------------------
control IngressPFCWd(in switch_port_t port,
               in switch_qid_t qid,
               out bool flag)(
               switch_uint32_t table_size=512) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    @name(".ingress_pfcwd.acl_deny")
    action acl_deny() {
        flag = true;
        stats.count();
    }

    @ways(2)
    @name(".ingress_pfcwd.acl")
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
// Egress PFC Watchdog
// Once PFC storm is detected on a queue, the PFC watchdog can drop or forward at per queue level.
// On drop action, all existing packets in the output queue and all subsequent packets destined to
// the output queue are discarded.
//
// @param port
// @param qid : Queue Id.
// @param table_size : Size of the ACL table.
//-------------------------------------------------------------------------------------------------
control EgressPFCWd(in switch_port_t port,
               in switch_qid_t qid,
               out bool flag)(
               switch_uint32_t table_size=512) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;

    @name(".egress_pfcwd.acl_deny")
    action acl_deny() {
        flag = true;
        stats.count();
    }

    @ways(2)
    @name(".egress_pfcwd.acl")
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

    @name(".ingress_qos_map.set_ingress_tc")
    action set_ingress_tc(switch_tc_t tc) {
        local_md.qos.tc = tc;
    }

    @name(".ingress_qos_map.set_ingress_color")
    action set_ingress_color(switch_pkt_color_t color) {
        local_md.qos.color = color;
    }

    @name(".ingress_qos_map.set_ingress_tc_and_color")
    action set_ingress_tc_and_color(
            switch_tc_t tc, switch_pkt_color_t color) {
        set_ingress_tc(tc);
        set_ingress_color(color);
    }

    @name(".ingress_qos_map.dscp_tc_map")
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

    @name(".ingress_qos_map.pcp_tc_map")
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

    @name(".ingress_qos_map.exp_tc_map")
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
// Ingress QosTC
// QoS Classification - map Traffic Class -> icos, qid
//-------------------------------------------------------------------------------------------------
control IngressTC(inout switch_local_metadata_t local_md)() {

    const bit<32> tc_table_size = 1024;

    @name(".ingress_tc.set_icos")
    action set_icos(switch_cos_t icos) {
        local_md.qos.icos = icos;
    }

    @name(".ingress_tc.set_queue")
    action set_queue(switch_qid_t qid) {
        local_md.qos.qid = qid;
    }

    @name(".ingress_tc.set_icos_and_queue")
    action set_icos_and_queue(switch_cos_t icos, switch_qid_t qid) {
        set_icos(icos);
        set_queue(qid);
    }

    @name(".ingress_tc.traffic_class")
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
    @name(".ppg_stats.count")
    action count() {
        ppg_stats.count();
    }

    // Asymmetric table to maintain statistics per local port and cos pair.
    @ways(2)
    @name(".ppg_stats.ppg")
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
    @name(".egress_qos.set_ipv4_dscp")
    action set_ipv4_dscp(bit<6> dscp, bit<3> exp) {
        hdr.ipv4.diffserv[7:2] = dscp;
        local_md.tunnel.mpls_encap_exp = exp;
    }

    @name(".egress_qos.set_ipv4_tos")
    action set_ipv4_tos(switch_uint8_t tos, bit<3> exp) {
        hdr.ipv4.diffserv = tos;
        local_md.tunnel.mpls_encap_exp = exp;
    }

    // Overwrites 6-bit dscp only.
    @name(".egress_qos.set_ipv6_dscp")
    action set_ipv6_dscp(bit<6> dscp, bit<3> exp) {

        hdr.ipv6.traffic_class[7:2] = dscp;
        local_md.tunnel.mpls_encap_exp = exp;

    }

    @name(".egress_qos.set_ipv6_tos")
    action set_ipv6_tos(switch_uint8_t tos, bit<3> exp) {

        hdr.ipv6.traffic_class = tos;
        local_md.tunnel.mpls_encap_exp = exp;

    }

    @name(".egress_qos.set_vlan_pcp")
    action set_vlan_pcp(bit<3> pcp, bit<3> exp) {
        hdr.vlan_tag[0].pcp = pcp;
        local_md.tunnel.mpls_encap_exp = exp;
    }

    @name(".egress_qos.qos_map")
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

    @name(".egress_queue.count")
    action count() {
        queue_stats.count();
    }

    // Asymmetric table to maintain statistics per local port and queue pair. This table does NOT
    // take care of packets that get dropped or sent to cpu by system acl.



    @ways(2)
    @pack(2)
    @name(".egress_queue.queue")
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
# 159 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/shared/meter.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/





# 1 "../../p4c-5288/shared/acl.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/
# 24 "../../p4c-5288/shared/meter.p4" 2

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
    @name(".storm_control.meter")
    Meter<bit<16>>(meter_size, MeterType_t.PACKETS) meter;

    @name(".storm_control.count")
    action count() {
        storm_control_stats.count();
        flag = false;
    }

    @name(".storm_control.drop_and_count")
    action drop_and_count() {
        storm_control_stats.count();
        flag = true;
    }

    @name(".storm_control.stats")
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

    @name(".storm_control.set_meter")
    action set_meter(bit<16> index) {
        local_md.qos.storm_control_color = (bit<2>) meter.execute(index);
    }

    @name(".storm_control.storm_control")
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

    @name(".ingress_mirror_meter.meter")
    Meter<bit<9>>(table_size, MeterType_t.PACKETS) meter;
    switch_pkt_color_t color;

    @name(".ingress_mirror_meter.mirror_and_count")
    action mirror_and_count() {
        stats.count();
    }

    @name(".ingress_mirror_meter.no_mirror_and_count")
    action no_mirror_and_count() {
        stats.count();
        local_md.mirror.type = 0;
    }

    @ways(2)
    @name(".ingress_mirror_meter.meter_action")
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

    @name(".ingress_mirror_meter.set_meter")
    action set_meter(bit<9> index) {
        color = (bit<2>) meter.execute(index);
    }

    @name(".ingress_mirror_meter.meter_index")
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
    @name(".egress_mirror_meter.meter")
    Meter<bit<9>>(table_size, MeterType_t.PACKETS) meter;
    switch_pkt_color_t color;

    @name(".egress_mirror_meter.mirror_and_count")
    action mirror_and_count() {
        stats.count();
    }

    @name(".egress_mirror_meter.no_mirror_and_count")
    action no_mirror_and_count() {
        stats.count();
        local_md.mirror.type = 0;
    }

    @ways(2)
    @name(".egress_mirror_meter.meter_action")
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

    @name(".egress_mirror_meter.set_meter")
    action set_meter(bit<9> index) {
        color = (bit<2>) meter.execute(index);
    }

    @name(".egress_mirror_meter.meter_index")
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
# 160 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/shared/wred.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
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

    @name(".egress_wred.wred")
    Wred<bit<19>, switch_wred_index_t>(wred_size, 1 /* drop value*/, 0 /* no drop value */) wred;

    // -----------------------------------------------------------
    // Select a profile and apply wred filter
    // A total of 1k profiles are supported.
    // -----------------------------------------------------------
    @name(".egress_wred.set_wred_index")
    action set_wred_index(switch_wred_index_t wred_index) {
        index = wred_index;
        wred_flag = (bit<1>) wred.execute(local_md.qos.qdepth, wred_index);
    }

    // Asymmetric table to get the attached WRED profile.
    @name(".egress_wred.wred_index")
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
    @name(".egress_wred.set_ipv4_ecn")
    action set_ipv4_ecn() {
        hdr.ipv4.diffserv[1:0] = SWITCH_ECN_CODEPOINT_CE;
        wred_drop = false;
    }

    @name(".egress_wred.set_ipv6_ecn")
    action set_ipv6_ecn() {
        hdr.ipv6.traffic_class[1:0] = SWITCH_ECN_CODEPOINT_CE;
        wred_drop = false;
    }

    // Packets from flows that are not ECN capable will continue to be dropped by RED (as was the
    // case before ECN) -- RFC2884
    @name(".egress_wred.drop")
    action drop() {
        wred_drop = true;
    }

    @name(".egress_wred.v4_wred_action")
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

    @name(".egress_wred.v6_wred_action")
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
    @name(".egress_wred.count")
    action count() { stats.count(); }

    @ways(2)
    @name(".egress_wred.wred_stats")
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
# 161 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/shared/acl.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/
# 162 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
//#include "dtel.p4"
# 1 "../../p4c-5288/shared/sflow.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
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

    @name(".ingress_sflow_samplers")
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

      if (local_md.sflow.session_id != SWITCH_SFLOW_INVALID_ID) {
        local_md.sflow.sample_packet =
            sample_packet.execute(local_md.sflow.session_id);
      }

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
# 164 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/switch-tofino/largetable/table_acl.p4" 1
control GwIngressSystemAcl(
        in switch_header_t hdr,
        inout switch_local_metadata_t local_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(
        switch_uint32_t table_size=1024) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS) stats;

    action permit() {
        local_md.drop_reason = SWITCH_DROP_REASON_UNKNOWN;
    }

    action drop(switch_drop_reason_t drop_reason) {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        ig_intr_md_for_dprsr.digest_type = SWITCH_DIGEST_TYPE_INVALID;
        local_md.drop_reason = drop_reason;
    }

    // TODO: add copp to limit the speed of copying to cpu.
    action copy_to_cpu(switch_cpu_reason_t reason_code,
                       switch_qid_t qid) {
        local_md.qos.qid = qid; // 0x1
        // local_md.qos.icos = icos;
        ig_intr_md_for_tm.copy_to_cpu = 1w1;
        ig_intr_md_for_dprsr.digest_type = SWITCH_DIGEST_TYPE_INVALID;
        local_md.cpu_reason = reason_code; // 0x2e: SWITCH_HOSTIF_TRAP_ATTR_TYPE_MYIP
    }

    action redirect_to_cpu(switch_cpu_reason_t reason_code,
                           switch_qid_t qid) {
        ig_intr_md_for_dprsr.drop_ctl = 0b1;
        copy_to_cpu(reason_code, qid);
    }

    table system_acl {
        key = {
            // Flags
            local_md.flags.myip : ternary @name("myip");
            local_md.flags.routed : ternary @name("routed");

            local_md.drop_reason : ternary @name("drop_reason");
            //hdr.bridged_md.table_result.drop_flags.gw_pkt_type : ternary @name("gw_pkt_type");

            // GW Drop Flags
            // hdr.bridged_md.gw_flags.eip_miss : ternary @name("eip_miss");
            // hdr.bridged_md.gw_flags.private_ip_miss : ternary @name("private_ip_miss");
            //hdr.bridged_md.table_result.eip_info_miss : ternary @name("eip_info_miss");
            //hdr.bridged_md.table_result.drop_flags.encap_to_fw_miss : ternary @name("encap_to_fw_miss");
            //hdr.bridged_md.table_result.drop_flags.encap_to_eni_miss : ternary @name("encap_to_eni_miss");
            //hdr.bridged_md.table_result.drop_flags.encap_to_igw_miss : ternary @name("encap_to_igw_miss");
        }

        actions = {
            permit;
            drop;
            copy_to_cpu;
            redirect_to_cpu;
        }

        const default_action = permit;
        size = table_size;
    }

    action count() {
        stats.count();
    }

    table drop_stats {
        key = {
            local_md.drop_reason : exact @name("drop_reason");
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        counters = stats;
        size = table_size;
    }

    apply {
        system_acl.apply();
        drop_stats.apply();
    }
}

control GwEgressSystemAcl(
        inout switch_header_t hdr,
        inout switch_local_metadata_t local_md,
        out egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)(
        switch_uint32_t drop_stats_table_size=1024) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS) stats;

    action drop_count() {
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        stats.count();
    }

    action count() {
        stats.count();
    }

    table drop_stats {
        key = {
            local_md.drop_reason : exact @name("drop_reason");
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
# 165 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/switch-tofino/largetable/table_validation.p4" 1
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
    bit<8> bit_8_0 = 0x0;
    bit<16> bit_16_0 = 0x00;

    action valid_ethernet_pkt(switch_pkt_type_t pkt_type) {
        local_md.lkp.pkt_type = pkt_type;
        local_md.lkp.mac_dst_addr = hdr.ethernet.dst_addr;
    }

    @name(".malformed_eth_pkt")
    action malformed_eth_pkt(bit<8> reason) {
        local_md.lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        local_md.lkp.mac_type = hdr.ethernet.ether_type;
        local_md.l2_drop_reason = reason;
    }

    @name(".valid_pkt_untagged")
    action valid_pkt_untagged(switch_pkt_type_t pkt_type) {
        local_md.lkp.mac_type = hdr.ethernet.ether_type;
        valid_ethernet_pkt(pkt_type);
    }

    @name(".valid_pkt_tagged")
    action valid_pkt_tagged(switch_pkt_type_t pkt_type) {
        local_md.lkp.mac_type = hdr.vlan_tag[0].ether_type;
        local_md.lkp.pcp = hdr.vlan_tag[0].pcp;
        valid_ethernet_pkt(pkt_type);
    }
# 50 "../../p4c-5288/switch-tofino/largetable/table_validation.p4"
    @name(".validate_ethernet")
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

    @name(".valid_arp_pkt")
    action valid_arp_pkt() {





        local_md.lkp.arp_opcode = hdr.arp.opcode;
    }

    // IP Packets
    @name(".valid_ipv6_pkt")
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

    @name(".valid_ipv4_pkt")
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

    @name(".malformed_ipv4_pkt")
    action malformed_ipv4_pkt(bit<8> reason, switch_ip_frag_t ip_frag) {
        // Set common lookup fields just for dtel acl and hash purposes
        valid_ipv4_pkt(ip_frag, false);
        local_md.drop_reason = reason;
    }

    @name(".malformed_ipv6_pkt")
    action malformed_ipv6_pkt(bit<8> reason) {
        // Set common lookup fields just for dtel acl and hash purposes
        valid_ipv6_pkt(false);
        local_md.drop_reason = reason;
    }
# 171 "../../p4c-5288/switch-tofino/largetable/table_validation.p4"
    @name(".validate_ip")
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
    }

    action set_udp_ports() {
        local_md.lkp.l4_src_port = hdr.udp.src_port;
        local_md.lkp.l4_dst_port = hdr.udp.dst_port;
        local_md.lkp.tcp_flags = bit_8_0;
    }

    action set_icmp_type() {
        local_md.lkp.l4_src_port[7:0] = hdr.icmp.type;
        local_md.lkp.l4_src_port[15:8] = hdr.icmp.code;
        local_md.lkp.l4_dst_port = bit_16_0;
        local_md.lkp.tcp_flags = bit_8_0;
    }

    action set_igmp_type() {
        local_md.lkp.l4_src_port[7:0] = hdr.igmp.type;
        local_md.lkp.l4_src_port[15:8] = 0;
        local_md.lkp.l4_dst_port = 0;
        local_md.lkp.tcp_flags = 0;
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

    @name(".compute_same_mac_check")
    action compute_same_mac_check() {
        local_md.drop_reason = SWITCH_DROP_REASON_OUTER_SAME_MAC_CHECK;
    }

    @ways(1)
    @name(".same_mac_check")
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

    bit<8> bit_8_0 = 0x0;
    bit<16> bit_16_0 = 0x00;
    @name(".valid_inner_ethernet_pkt")
    action valid_ethernet_pkt(switch_pkt_type_t pkt_type) {

        local_md.lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
        local_md.lkp.mac_type = hdr.inner_ethernet.ether_type;

        local_md.lkp.pkt_type = pkt_type;
    }

    @name(".valid_inner_ipv4_pkt")
    action valid_ipv4_pkt(switch_pkt_type_t pkt_type) {
        // Set the common IP lookup fields

        local_md.lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;

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

    @name(".valid_inner_ipv6_pkt")
    action valid_ipv6_pkt(switch_pkt_type_t pkt_type) {

        // Set the common IP lookup fields

        local_md.lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;

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
        local_md.lkp.tcp_flags = hdr.inner_tcp.flags;
    }

    action set_udp_ports() {
        local_md.lkp.l4_src_port = hdr.inner_udp.src_port;
        local_md.lkp.l4_dst_port = hdr.inner_udp.dst_port;
        local_md.lkp.tcp_flags = bit_8_0;
    }

    action set_icmp_type() {
        local_md.lkp.l4_src_port[7:0] = hdr.inner_icmp.type;
        local_md.lkp.l4_src_port[15:8] = hdr.inner_icmp.code;
        local_md.lkp.l4_dst_port = bit_16_0;
        local_md.lkp.tcp_flags = bit_8_0;
    }

    @name(".valid_inner_ipv4_tcp_pkt")
    action valid_ipv4_tcp_pkt(switch_pkt_type_t pkt_type) {
        // Set the common L2 lookup fields
        valid_ipv4_pkt(pkt_type);
        set_tcp_ports();
    }

    @name(".valid_inner_ipv4_udp_pkt")
    action valid_ipv4_udp_pkt(switch_pkt_type_t pkt_type) {
        // Set the common L2 lookup fields
        valid_ipv4_pkt(pkt_type);
        set_udp_ports();
    }

    @name(".valid_inner_ipv4_icmp_pkt")
    action valid_ipv4_icmp_pkt(switch_pkt_type_t pkt_type) {
        // Set the common L2 lookup fields
        valid_ipv4_pkt(pkt_type);
        set_icmp_type();
    }

    @name(".valid_inner_ipv6_tcp_pkt")
    action valid_ipv6_tcp_pkt(switch_pkt_type_t pkt_type) {
        // Set the common L2 lookup fields
        valid_ipv6_pkt(pkt_type);
        set_tcp_ports();
    }

    @name(".valid_inner_ipv6_udp_pkt")
    action valid_ipv6_udp_pkt(switch_pkt_type_t pkt_type) {
        // Set the common L2 lookup fields
        valid_ipv6_pkt(pkt_type);
        set_udp_ports();
    }

    @name(".valid_inner_ipv6_icmp_pkt")
    action valid_ipv6_icmp_pkt(switch_pkt_type_t pkt_type) {
        // Set the common L2 lookup fields
        valid_ipv6_pkt(pkt_type);
        set_icmp_type();
    }

    @name(".malformed_inner_pkt")
    action malformed_pkt(bit<8> reason) {
        local_md.drop_reason = reason;
    }

    @name(".validate_inner_ethernet")
    table validate_ethernet {
        key = {
            hdr.inner_ethernet.isValid() : ternary;

            hdr.inner_ethernet.dst_addr : ternary;


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
            hdr.inner_icmp.isValid() : ternary;

        }

        actions = {
            NoAction;
            valid_ipv4_tcp_pkt;
            valid_ipv4_udp_pkt;
            valid_ipv4_icmp_pkt;
            valid_ipv4_pkt;
            valid_ipv6_tcp_pkt;
            valid_ipv6_udp_pkt;
            valid_ipv6_icmp_pkt;
            valid_ipv6_pkt;

            valid_ethernet_pkt;

            malformed_pkt;
        }
        size = MIN_TABLE_SIZE;
    }

    apply {
        validate_ethernet.apply();
    }
}

control GwPktValidation(
        in switch_header_t hdr,
        inout switch_lookup_fields_t lkp) {
//-----------------------------------------------------------------------------
// Validate outer L3 header
// - Drop the packet if src addr is zero or multicast or dst addr is zero.
//-----------------------------------------------------------------------------

    // IP Packets
    @name(".gw_valid_ipv6_pkt")
    action valid_ipv6_pkt() {
        // Set common lookup fields
        lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        lkp.ip_tos = hdr.ipv6.traffic_class;
        lkp.ip_proto = hdr.ipv6.next_hdr;
        lkp.ip_ttl = hdr.ipv6.hop_limit;
        lkp.ip_src_addr = hdr.ipv6.src_addr;
        lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        lkp.ipv6_flow_label = hdr.ipv6.flow_label;
    }

    @name(".gw_valid_ipv4_pkt")
    action valid_ipv4_pkt() {
        // Set common lookup fields
        lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        lkp.ip_tos = hdr.ipv4.diffserv;
        lkp.ip_proto = hdr.ipv4.protocol;
        lkp.ip_ttl = hdr.ipv4.ttl;
        lkp.ip_src_addr[63:0] = 64w0;
        lkp.ip_src_addr[95:64] = hdr.ipv4.src_addr;
        lkp.ip_src_addr[127:96] = 32w0;
        lkp.ip_dst_addr[63:0] = 64w0;
        lkp.ip_dst_addr[95:64] = hdr.ipv4.dst_addr;
        lkp.ip_dst_addr[127:96] = 32w0;
    }

    @name("gw_validate_ip")
    table validate_ip {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }

        actions = {
            valid_ipv4_pkt;
            valid_ipv6_pkt;
        }

        const entries = {
            (true, false) : valid_ipv4_pkt();
            (false, true) : valid_ipv6_pkt();
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

    action set_icmp_type() {
        lkp.l4_src_port[7:0] = hdr.icmp.type;
        lkp.l4_src_port[15:8] = hdr.icmp.code;
        lkp.l4_dst_port = 0;
        lkp.tcp_flags = 0;
    }

    // Not much of a validation as it only sets the lookup fields.
    table validate_other {
        key = {
            hdr.tcp.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.icmp.isValid() : exact;
        }

        actions = {
            NoAction;
            set_tcp_ports;
            set_udp_ports;
            set_icmp_type;
        }

        const default_action = NoAction;
        const entries = {
            (true, false, false) : set_tcp_ports();
            (false, true, false) : set_udp_ports();
            (false, false, true) : set_icmp_type();
        }
    }

    apply {
        validate_ip.apply();
        validate_other.apply();
    }
}
# 166 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2

# 1 "../../p4c-5288/switch-tofino/largetable/gw_l3.p4" 1
//-----------------------------------------------------------------------------
// GW FIB lookup
//
// @param dst_addr : Destination IPv4 address.
// @param vrf
// @param flags
// @param nexthop : Nexthop index.
// @param host_table_size : Size of the host table.
// @param lpm_table_size : Size of the IPv4 route table.
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Common GW FIB  actions.
//-----------------------------------------------------------------------------
    action gw_fib_hit(inout switch_local_metadata_t local_md, switch_nexthop_t nexthop_index, switch_fib_label_t fib_label) {
        local_md.nexthop = nexthop_index;



        local_md.flags.routed = true;
    }

    action gw_fib_miss(inout switch_local_metadata_t local_md) {
        local_md.flags.routed = false;
    }

    action gw_fib_miss_lpm4(inout switch_local_metadata_t local_md) {
        local_md.flags.routed = false;
        local_md.flags.fib_lpm_miss = true;
    }

    action gw_fib_miss_lpm6(inout switch_local_metadata_t local_md) {
        local_md.flags.routed = false;
        local_md.flags.fib_lpm_miss = true;
    }

    action gw_fib_drop(inout switch_local_metadata_t local_md) {
        local_md.flags.routed = false;
        local_md.flags.fib_drop = true;
    }

    action gw_fib_myip(inout switch_local_metadata_t local_md, switch_myip_type_t myip) {
        local_md.flags.myip = myip;
    }

//
// *************************** IPv4 FIB **************************************
//
control GwFibv4(inout switch_local_metadata_t local_md)(
              switch_uint32_t host_table_size,
              switch_uint32_t lpm_table_size,
              bool local_host_enable=false,
              switch_uint32_t local_host_table_size=1024) {


    @pack(2)
    @name(".ipv4_host") table host {
        key = {
            local_md.vrf : exact @name("vrf");
            local_md.lkp.ip_dst_addr[95:64] : exact @name("ip_dst_addr");
        }

        actions = {
            gw_fib_miss(local_md);
            gw_fib_hit(local_md);
            gw_fib_myip(local_md);
            gw_fib_drop(local_md);
        }

        const default_action = gw_fib_miss(local_md);
        size = host_table_size;
    }

    @name(".ipv4_local_host") table local_host {
        key = {
            local_md.vrf : exact @name("vrf");
            local_md.lkp.ip_dst_addr[95:64] : exact @name("ip_dst_addr");
        }

        actions = {
            gw_fib_miss(local_md);
            gw_fib_hit(local_md);
            gw_fib_myip(local_md);
            gw_fib_drop(local_md);
        }

        const default_action = gw_fib_miss(local_md);
        size = local_host_table_size;
    }







    Alpm(number_partitions = 2048, subtrees_per_partition = 2) algo_lpm;

    @name(".ipv4_lpm") table lpm32 {
        key = {
            local_md.vrf : exact @name("vrf");
            local_md.lkp.ip_dst_addr[95:64] : lpm @name("ip_dst_addr");
        }

        actions = {
            gw_fib_miss_lpm4(local_md);
            gw_fib_hit(local_md);
            gw_fib_myip(local_md);
            gw_fib_drop(local_md);
        }

        const default_action = gw_fib_miss_lpm4(local_md);
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
control GwFibv6(inout switch_local_metadata_t local_md)(
              switch_uint32_t host_table_size,
              switch_uint32_t host64_table_size,
              switch_uint32_t lpm_table_size,
              switch_uint32_t lpm64_table_size=1024) {


    @immediate(0)
    @name(".ipv6_host") table host {
        key = {
            local_md.vrf : exact @name("vrf");
            local_md.lkp.ip_dst_addr : exact @name("ip_dst_addr");
        }

        actions = {
            gw_fib_miss(local_md);
            gw_fib_hit(local_md);
            gw_fib_myip(local_md);
            gw_fib_drop(local_md);
        }

        const default_action = gw_fib_miss(local_md);
        size = host_table_size;
    }
# 185 "../../p4c-5288/switch-tofino/largetable/gw_l3.p4"
    Alpm(number_partitions = 1024, subtrees_per_partition = 2) algo_lpm128;

    @name(".ipv6_lpm128") table lpm128 {
        key = {
            local_md.vrf : exact @name("vrf");
            local_md.lkp.ip_dst_addr : lpm @name("ip_dst_addr");
        }

        actions = {
            gw_fib_miss(local_md);
            gw_fib_hit(local_md);
            gw_fib_myip(local_md);
            gw_fib_drop(local_md);
        }

        const default_action = gw_fib_miss(local_md);
        size = lpm_table_size;
        implementation = algo_lpm128;
        requires_versioning = false;
    }
# 255 "../../p4c-5288/switch-tofino/largetable/gw_l3.p4"
    apply {

        if (!host.apply().hit) {



            if (!lpm128.apply().hit)

            {
# 273 "../../p4c-5288/switch-tofino/largetable/gw_l3.p4"
            }
        }

    }
}
# 168 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/switch-tofino/largetable/gw_nexthop.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/


// ----------------------------------------------------------------------------
// GW Nexthop/ECMP resolution
//
// @param local_md : Ingress metadata fields
// @param nexthop_table_size : Number of nexthops.
// @param ecmp_group_table_size : Number of ECMP groups.
// @param ecmp_selction_table_size : Maximum number of ECMP members.
//
// ----------------------------------------------------------------------------
control GwNexthop(inout switch_local_metadata_t local_md)(
                switch_uint32_t nexthop_table_size,
                switch_uint32_t ecmp_group_table_size,
                switch_uint32_t ecmp_selection_table_size,
                switch_uint32_t ecmp_max_members_per_group=64) {

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    @name(".nexthop_ecmp_action_profile")
    ActionProfile(ecmp_selection_table_size) ecmp_action_profile;
# 46 "../../p4c-5288/switch-tofino/largetable/gw_nexthop.p4"
    @name(".nexthop_ecmp_selector")
    ActionSelector(ecmp_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   ecmp_max_members_per_group,
                   ecmp_group_table_size) ecmp_selector;


    // ---------------- IP Nexthop ----------------
    @name(".gw_nexthop_set_nexthop_properties")
    action set_nexthop_properties(switch_port_lag_index_t port_lag_index,
                                  switch_bd_t bd,
                                  switch_nat_zone_t zone) {



        local_md.egress_port_lag_index = port_lag_index;



        local_md.checks.same_if = local_md.ingress_port_lag_index ^ port_lag_index;




    }

    @name(".gw_set_ecmp_properties")
    action set_ecmp_properties(switch_port_lag_index_t port_lag_index,
                               switch_bd_t bd,
                               switch_nexthop_t nexthop_index, switch_nat_zone_t zone) {
        local_md.nexthop = nexthop_index;



        set_nexthop_properties(port_lag_index, bd, zone);
    }

    // ----------------  Post Route Flood ----------------
    @name(".gw_set_nexthop_properties_post_routed_flood")
    action set_nexthop_properties_post_routed_flood(switch_bd_t bd, switch_mgid_t mgid, switch_nat_zone_t zone) {
        local_md.egress_port_lag_index = 0;
        local_md.multicast.id = mgid;



    }

    @name(".gw_set_ecmp_properties_post_routed_flood")
    action set_ecmp_properties_post_routed_flood(
            switch_bd_t bd,
            switch_mgid_t mgid,
            switch_nexthop_t nexthop_index, switch_nat_zone_t zone) {
        local_md.nexthop = nexthop_index;
        set_nexthop_properties_post_routed_flood(bd, mgid, zone);
    }

    // ---------------- Glean ----------------
    @name(".gw_set_nexthop_properties_glean")
    action set_nexthop_properties_glean() {
        local_md.flags.glean = true;
    }

    @name(".gw_set_ecmp_properties_glean")
    action set_ecmp_properties_glean(switch_nexthop_t nexthop_index) {
        local_md.nexthop = nexthop_index;
        set_nexthop_properties_glean();
    }

    // ---------------- Drop ----------------
    @name(".gw_set_nexthop_properties_drop")
    action set_nexthop_properties_drop() {
        local_md.drop_reason = GW_DROP_REASON_NEXTHOP;
    }

    @name(".gw_set_ecmp_properties_drop")
    action set_ecmp_properties_drop() {
        set_nexthop_properties_drop();
    }

    @ways(2)
    @name(".ecmp")
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




    @name(".nexthop")
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
# 184 "../../p4c-5288/switch-tofino/largetable/gw_nexthop.p4"
        switch(nexthop.apply().action_run) {
            NoAction : { ecmp.apply(); }
            default : {}
            }



    }
}
# 169 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/switch-tofino/largetable/gw_port.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2021 Intel Corporation
 *  All Rights Reserved.
 *
 *  This software and the related documents are Intel copyrighted materials,
 *  and your use of them is governed by the express license under which they
 *  were provided to you ("License"). Unless the License provides otherwise,
 *  you may not use, modify, copy, publish, distribute, disclose or transmit
 *  this software or the related documents without Intel's prior written
 *  permission.
 *
 *  This software and the related documents are provided as is, with no express
 *  or implied warranties, other than those that are expressly stated in the
 *  License.
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Ingress port mirroring
//-----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Link Aggregation (LAG) resolution
//
// @param local_md : Ingress metadata fields.
// @param hash : Hash value used for port selection.
// @param egress_port : Egress port.
//
// @flag MLAG_ENABLE : Enable multi-chassis LAG.
// ----------------------------------------------------------------------------

control GwLAG(inout switch_local_metadata_t local_md,
            in switch_hash_t hash,
            out switch_port_t egress_port) {




    Hash<switch_uint16_t>(HashAlgorithm_t.CRC16) selector_hash;

    @name(".lag_action_profile")
    ActionProfile(LAG_SELECTOR_TABLE_SIZE) lag_action_profile;
    @name(".lag_selector")
    ActionSelector(lag_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   LAG_MAX_MEMBERS_PER_GROUP,
                   LAG_GROUP_TABLE_SIZE) lag_selector;

    @name(".gw_set_lag_port")
    action set_lag_port(switch_port_t port) {
        egress_port = port;
    }

    @name(".gw_set_peer_link_port")
    action set_peer_link_port(switch_port_t port, switch_port_lag_index_t port_lag_index) {
        egress_port = port;
        local_md.egress_port_lag_index = port_lag_index;
        local_md.checks.same_if = local_md.ingress_port_lag_index ^ port_lag_index;
    }

    @name(".gw_lag_miss")
    action lag_miss() { }

    @name(".lag")
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
# 170 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/switch-tofino/largetable/gw_stats.p4" 1
//control EipInStats(in switch_header_t hdr, in gw_local_metadata_t local_md) {
//    DirectCounter<bit<gw_counter_width>>(CounterType_t.PACKETS_AND_BYTES) stats;
//
//    action eip_in_permit() {}
//
//    table eip_in_match {
//        key = {
//            local_md.tunnel.gw_flags.meter_type : exact @name("meter_type");
//            local_md.tunnel.gw_pkt_flags.eip_info_miss : exact @name("eip_info_miss");
//            local_md.tunnel.gw_pkt_flags.eip_miss : exact @name("eip_miss");
//            local_md.tunnel.gw_pkt_flags.private_ip_miss : exact @name("private_ip_miss");
//            local_md.tunnel.gw_flags.encap_to_fw_miss : exact @name("encap_to_fw_miss");
//            local_md.tunnel.gw_flags.encap_to_eni_miss : exact @name("encap_to_eni_miss");
//            local_md.tunnel.gw_flags.encap_to_igw_miss : exact @name("encap_to_igw_miss");
//        }
//
//        actions = {
//            @defaultonly NoAction;
//            eip_in_permit;
//        }
//
//        const default_action = NoAction;
//        const entries = {
//            (GW_METER_TYPE_IN, false, false, false, false, false, false) : eip_in_permit();
//        }
//    }
//
//    @name(".eip_in_stats_count")
//    action count() {
//        stats.count(adjust_byte_count=sizeInBytes(hdr.bridged_md)+ADJUST_BYTE_COUNT);
//    }
//
//    @name(".eip_in_stats")
//    table eip_stats {
//        key = {
//            local_md.tunnel.eid : exact @name("eid");
//        }
//
//        actions = {
//            count;
//        }
//
//        counters = stats;
//        size = EIP_TABLE_SIZE;
//    }
//
//    apply {
//        if (eip_in_match.apply().hit) {
//            eip_stats.apply();
//        }
//    }
//}
//
//control EipInDropStats(in switch_header_t hdr, in gw_local_metadata_t local_md) {
//    DirectCounter<bit<gw_counter_width>>(CounterType_t.PACKETS_AND_BYTES) stats;
//
//    @name(".eip_in_drop_stats_count")
//    action count() {
//        stats.count(adjust_byte_count=sizeInBytes(hdr.bridged_md)+ADJUST_BYTE_COUNT);
//    }
//
//    @name(".eip_in_drop_stats")
//    table drop_stats {
//        key = {
//            local_md.tunnel.eid : exact @name("eid");
//        }
//
//        actions = {
//            count;
//        }
//
//        counters = stats;
//        size = EIP_TABLE_SIZE;
//    }
//
//    apply {
//        drop_stats.apply();
//    }
//}
//
//control EipOutStats(in switch_header_t hdr, in gw_local_metadata_t local_md)(
//    switch_uint32_t table_size) {
//    DirectCounter<bit<gw_counter_width>>(CounterType_t.PACKETS_AND_BYTES) stats;
//
//    @name(".eip_out_stats_count")
//    action count() {
//        stats.count(adjust_byte_count=sizeInBytes(hdr.bridged_md)+ADJUST_BYTE_COUNT);
//    }
//
//    @name(".eip_out_stats")
//    table eip_stats {
//        key = {
//            local_md.tunnel.eid : exact @name("eid");
//        }
//
//        actions = {
//            count;
//        }
//
//        counters = stats;
//        size = table_size;
//    }
//
//    apply {
//        if (local_md.tunnel.gw_flags.meter_type == GW_METER_TYPE_OUT) {
//            eip_stats.apply();
//        }
//    }
//}
//
//control EipOutDropStats(in switch_header_t hdr, in gw_local_metadata_t local_md) {
//    DirectCounter<bit<gw_counter_width>>(CounterType_t.PACKETS_AND_BYTES) stats;
//
//    @name(".eip_out_drop_stats_count")
//    action count() {
//        stats.count(adjust_byte_count=sizeInBytes(hdr.bridged_md)+ADJUST_BYTE_COUNT);
//    }
//
//    @name(".eip_out_drop_stats")
//    table drop_stats {
//        key = {
//            local_md.tunnel.eid : exact @name("eid");
//        }
//
//        actions = {
//            count;
//        }
//
//        counters = stats;
//        size = EIP_TABLE_SIZE;
//    }
//
//    apply {
//        drop_stats.apply();
//    }
//}
# 171 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/switch-tofino/largetable/gw_meter.p4" 1
control EipInMeter(
        in switch_header_t hdr,
        in switch_local_metadata_t local_md,
        out bit<2> packet_color) {

    DirectMeter(MeterType_t.BYTES) meter;

    @name(".eip_in_set_color")
    action set_color() {
        packet_color = (bit<2>) meter.execute(adjust_byte_count=sizeInBytes(hdr.bridged_md)+4);
    }

    @name(".eip_in_meter")
    table eip_meter {
        key = {
            local_md.tunnel.meter_id : exact @name("meter_id");
        }

        actions = {
            set_color;
        }

        default_action = set_color;
        meters = meter;
        size = EIP_TABLE_SIZE;
    }

    apply {
        eip_meter.apply();
    }
}

control EipOutMeter(
        in switch_header_t hdr,
        in switch_local_metadata_t local_md,
        out bit<2> packet_color) {

    DirectMeter(MeterType_t.BYTES) meter;

    @name(".eip_out_set_color")
    action set_color() {
        packet_color = (bit<2>) meter.execute(adjust_byte_count=sizeInBytes(hdr.bridged_md)+4);
    }

    @name(".eip_out_meter")
    table eip_meter {
        key = {
            local_md.tunnel.meter_id : exact @name("meter_id");
        }

        actions = {
            set_color;
        }

        default_action = set_color;
        meters = meter;
        size = EIP_TABLE_SIZE;
    }

    apply {
        eip_meter.apply();
    }
}
# 172 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
//#include "largetable/pipe1_parde.p4"
# 1 "../../p4c-5288/switch-tofino/largetable/table_tunnel.p4" 1

// To avoid the compiler puts these two fields in a same phv
@pa_container_size("egress", "hdr.udp.src_port", 16)
@pa_container_size("egress", "hdr.udp.dst_port", 16)

//-----------------------------------------------------------------------------
// Tunnel processing
// Outer router MAC
// IP source and destination VTEP
//-----------------------------------------------------------------------------
control GwIngressTunnel(inout switch_header_t hdr,
                      inout switch_local_metadata_t local_md,
                      inout switch_lookup_fields_t lkp,
                      inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    InnerPktValidation() pkt_validation;
    // Hash<bit<32>>(HashAlgorithm_t.CRC32) eip_hash;
    // Hash<bit<32>>(HashAlgorithm_t.CRC32) private_ip_hash;

    action set_inner_bd_properties_base() {
        // local_md.ingress_outer_bd = local_md.bd;
        local_md.bd = SWITCH_VXLAN_DEFAULT_BD; // 65535: bd allocated for default vrf

        local_md.bd_label = 0x0;

        // local_md.vrf = SWITCH_BD_DEFAULT_VRF;
        local_md.learning.bd_mode = SWITCH_LEARNING_MODE_DISABLED;
        local_md.ipv4.unicast_enable = true;
        local_md.ipv4.multicast_enable = false;
        local_md.ipv4.multicast_snooping = false;
        local_md.ipv6.unicast_enable = true;
        local_md.ipv6.multicast_enable = false;
        local_md.ipv6.multicast_snooping = false;
        local_md.tunnel.terminate = true;
    }

    action set_routed_and_bypass_fib()
    {
        local_md.flags.routed = true;
        local_md.bypass = local_md.bypass | SWITCH_INGRESS_BYPASS_L3 | SWITCH_INGRESS_BYPASS_L2;
    }

    action set_inner_bd_properties() {
        set_inner_bd_properties_base();
        //local_md.flags.services = true;
        set_routed_and_bypass_fib();
    }



    @name(".local_vtep_hit")
    action local_vtep_hit(bit<24> ns_id) {
        local_md.tunnel.ns_id = ns_id;
    }

    @ternary(1)
    table gw_vtep {
        key = {
            //lkp.ip_type : exact @name("ip_type");
            lkp.ip_dst_addr : exact @name("gw_vtep");
        }

        actions = {
            local_vtep_hit;
            @defaultonly NoAction;
        }

        const default_action = NoAction;
        size = LOCAL_VTEP_TABLE_SIZE;
    }

    @name(".ns_interface_hit")
    action ns_interface_hit(bit<8> type) {
        local_md.tunnel.interface_type = type;
    }

    @name(".ns_interface_classify")
    table ns_interface_classify {
        key = {
            local_md.tunnel.ns_id : exact @name("ns_id");
            local_md.tunnel.vni : ternary @name("vni");
        }

        actions = {
            ns_interface_hit;
        }

        default_action = ns_interface_hit(NS_INTERFACE_TYPE_NONE);
        size = NS_INTERFACE_CLASSIFY_TABLE_SIZE;
    }

    //default net type: false not default true
     @name(".ns_hit")
    action ns_hit(bit<24> ns_id, bool net_type) {
        local_md.tunnel.ns_id = ns_id;
        local_md.tunnel.interface_type = NS_INTERFACE_TYPE_UNDERLAY;
        local_md.tunnel.net_type = net_type;
        set_routed_and_bypass_fib();
    }

    Alpm(number_partitions = 1024, subtrees_per_partition = 2) alpm;
    // Traffic classify: assign underlay incoming traffic namespace
    @name(".traffic_classify")
    table traffic_classify {
        key = {
            // local_md.lkp.ip_type : exact @name("ip_type");
            local_md.lkp.ip_dst_addr : lpm @name("dst_addr");
        }

        actions = {
            @defaultonly NoAction;
            ns_hit;
        }

        const default_action = NoAction;
        size = TRAFFIC_CLASSIFY_TABLE_SIZE;
        implementation = alpm;
        requires_versioning = false;
    }


    apply {
        // outer RMAC lookup for tunnel termination.
        // packets from CPU will not hit the rmac table.
        if (local_md.flags.rmac_hit) {
            if (local_md.tunnel.type == SWITCH_INGRESS_TUNNEL_TYPE_VXLAN) {
                if (gw_vtep.apply().hit) {
                    set_inner_bd_properties();
                    pkt_validation.apply(hdr, local_md);
                    ns_interface_classify.apply();
                }
            }

            if (!local_md.tunnel.terminate) {
                traffic_classify.apply();
            }

            if (local_md.tunnel.terminate && (lkp.pkt_type == SWITCH_PKT_TYPE_MULTICAST || lkp.pkt_type == SWITCH_PKT_TYPE_BROADCAST)) {
                mark_for_drop(local_md, SWITCH_DROP_REASON_INNER_DST_MAC_BROADCAST);
            }
            //adjust_flow_trace.apply();
        }
    }
}

control GwIngressToNic(inout switch_header_t hdr,
                      inout switch_local_metadata_t local_md,
                      inout switch_lookup_fields_t lkp,
                      inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    action set_route() {
        // set routed flag
        local_md.flags.routed = true;
        // bypass l3 router
        local_md.bypass = local_md.bypass | SWITCH_INGRESS_BYPASS_L3;
    }

    action set_flow_trace() {
        hdr.flow_trace.setValid();
        hdr.cpu_mh.setValid();
        hdr.ethernet.ether_type = 0x88B5;
        hdr.flow_trace.ingress_port = local_md.ingress_port;
        hdr.flow_trace.next_hdr = 0b11;
    }

    action nic_hit() {
        set_route();
        set_flow_trace();
        //local_md.flags.services = true;
        local_md.nic.tofino_to_nic = 1;
    }

    table dst_classify_nic {
        key = {
            lkp.ip_dst_addr[95:64] : lpm @name("eip");
        }

        actions = {
            NoAction;
            nic_hit;
        }
        default_action = NoAction;
        size = MIN_TABLE_SIZE;
    }

    // action rewrite_flow_trace(bit<2> next_hdr) {
    //     hdr.ethernet.ether_type = ETHERTYPE_FPT;
    //     hdr.flow_trace.next_hdr = next_hdr;
    // }

    // table adjust_flow_trace {
    //     key = {
    //         hdr.flow_trace.isValid() : exact;
    //         hdr.ipv4.isValid() : exact;
    //         hdr.ipv6.isValid() : exact;
    //     }
    //     actions = {
    //         NoAction;
    //         rewrite_flow_trace;
    //     }
    //     const entries = {
    //         (true, true, false) : rewrite_flow_trace(0b00);
    //         (true, false, true) : rewrite_flow_trace(0b01);
    //     }
    //     default_action = NoAction;
    //     size = MIN_TABLE_SIZE;
    // }
    action rewrite_cpu_mh_v4() {
        hdr.cpu_mh.next_hdr = 0;
    }

    action rewrite_cpu_mh_v6() {
        hdr.cpu_mh.next_hdr = 1;
    }

    table cpu_mh_rewrite {
        key = {
            hdr.cpu_mh.isValid() : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            rewrite_cpu_mh_v4;
            rewrite_cpu_mh_v6;
            NoAction;
        }
        const default_action = NoAction;
        const entries = {
            (true, true, false) : rewrite_cpu_mh_v4();
            (true, false, true) : rewrite_cpu_mh_v6();
        }
    }

    apply {
        dst_classify_nic.apply();
        cpu_mh_rewrite.apply();
    }
}

//control TableMatch(inout switch_header_t hdr,
//                      inout switch_local_metadata_t local_md,
//                      inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
//                      inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)() {  
//    
//    bit<9> origin_port_lower = local_md.ingress_port & 0x7f; 
//    bit<9> pipe_offset_2 = 0b100000000;
//    bit<9> pipe_offset_1 = 0b010000000;
//    bit<9> port_offset = 0b000100000;
//    // DirectMeter(MeterType_t.BYTES) meter_in;
//    // DirectMeter(MeterType_t.BYTES) meter_out;
//    // DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_in_drop;
//    // DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_out_drop;
//    // DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_in;
//    // DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_out;
//    bit<2> packet_color;
//
//    action set_eid(bit<18> eid, bit<18> meter_id) {
//        local_md.tunnel.eid = eid;
//        local_md.tunnel.meter_id = meter_id;
//    }
//
//    action eip_hit(bit<18> eid, bit<18> meter_id) {
//        set_eid(eid, meter_id);
//    }
//
//    action eip_miss() {
//
//    }
//
//    action private_ip_hit(bit<18> eid, bit<18> meter_id) {
//        set_eid(eid, meter_id);
//    }
//
//    action private_ip_miss() {
//
//    }
//
//    table eip_to_eid {
//        key = {
//            local_md.lkp.ip_type : exact @name("ip_type");
//            local_md.tunnel.eip : exact @name("eip");
//        }
//
//        actions = {
//            eip_hit;
//            @defaultonly eip_miss;
//        }
//
//        const default_action = eip_miss;
//        size = EIP_TABLE_SIZE;
//    }
//
//    table private_ip_to_eid {
//        key = {
//            local_md.lkp.ip_type : exact @name("ip_type");
//            local_md.tunnel.vni : exact @name("vni");
//            local_md.lkp.ip_src_addr : exact @name("private_ip");
//        }
//
//        actions = {
//            private_ip_hit;
//            @defaultonly private_ip_miss;
//        }
//
//        const default_action = private_ip_miss;
//        size = EIP_TABLE_SIZE;
//    }
//
//    action set_eip_info(bit<128> vm_vtep, bit<128> private_ip, bit<128> eip, bit<24> vni, bit<4> eip_zone, bit<4> bwp_zone, bit<4> igw_node, bit<2> inner_ip_type, bit<2> outer_ip_type, bit<1> to_igw, bit<1> to_fw, bit<1> to_lb) {
//        local_md.tunnel.vm_vtep = vm_vtep;
//        local_md.tunnel.private_ip = private_ip;
//        local_md.tunnel.eip = eip;
//        local_md.tunnel.vni = vni;
//        local_md.tunnel.eip_zone = eip_zone;
//        local_md.tunnel.bwp_zone = bwp_zone;
//        local_md.tunnel.igw_node = igw_node;
//        local_md.tunnel.flags.outer_ip_type = outer_ip_type;
//        local_md.tunnel.flags.inner_ip_type = inner_ip_type;
//        local_md.tunnel.flags.to_igw = to_igw;
//        local_md.tunnel.flags.to_fw = to_fw;
//        local_md.tunnel.flags.to_lb = to_lb;
//    }
//
//    action eip_info_miss() {
//        ig_intr_md_for_dprsr.drop_ctl = 0x1;
//        hdr.bridged_md.table_result.eip_info_miss = true;
//    }
//
//    table eip_info {
//        key = {
//            local_md.tunnel.eid : exact @name("eid");
//        }
//
//        actions = {
//            // set_info_vtepv4;
//            set_eip_info;
//            @defaultonly eip_info_miss;
//        }
//
//        const default_action = eip_info_miss;
//        size = EIP_TABLE_SIZE;
//    }
//
//    // action rewrite_inner_type_v4() {
//    //     hdr.inner_bridged_md.fpga_result.flags.inner_ip_type = SWITCH_IP_TYPE_IPV4;
//    // }
//
//    // action rewrite_inner_type_v6() {
//    //     hdr.inner_bridged_md.fpga_result.flags.inner_ip_type = SWITCH_IP_TYPE_IPV6;
//    // }
//
//    action encap_flags() {
//        hdr.inner_bridged_md.fpga_result.flags.outer_ip_type = local_md.tunnel.flags.outer_ip_type;
//        hdr.inner_bridged_md.fpga_result.flags.inner_ip_type = local_md.tunnel.flags.inner_ip_type;
//        hdr.inner_bridged_md.fpga_result.flags.to_igw = local_md.tunnel.flags.to_igw;
//        hdr.inner_bridged_md.fpga_result.flags.to_fw = local_md.tunnel.flags.to_fw;
//        hdr.inner_bridged_md.fpga_result.flags.to_lb = local_md.tunnel.flags.to_lb;
//        hdr.inner_bridged_md.fpga_result.meter_id = local_md.tunnel.meter_id;
//        hdr.inner_bridged_md.fpga_result.eid = local_md.tunnel.eid;
//    }
//
//    action encap_tunnel() {
//        hdr.inner_bridged_md.fpga_result.outer_ip = local_md.tunnel.vm_vtep;
//        hdr.inner_bridged_md.fpga_result.vni = local_md.tunnel.vni;
//        hdr.inner_bridged_md.fpga_result.inner_ip = local_md.tunnel.private_ip;
//        hdr.inner_bridged_md.fpga_result.eip_zone = local_md.tunnel.eip_zone;
//        hdr.inner_bridged_md.fpga_result.bwp_zone = local_md.tunnel.bwp_zone;
//        hdr.inner_bridged_md.fpga_result.igw_node = local_md.tunnel.igw_node;
//    }
//
//    action encap() {
//        hdr.inner_bridged_md.setValid();
//        encap_tunnel();
//        encap_flags();
//    }
//
//    action decap_flags() {
//        hdr.inner_bridged_md.fpga_result.flags.outer_ip_type = local_md.tunnel.flags.outer_ip_type;
//        hdr.inner_bridged_md.fpga_result.flags.inner_ip_type = local_md.tunnel.flags.inner_ip_type;
//        hdr.inner_bridged_md.fpga_result.flags.to_igw = local_md.tunnel.flags.to_igw;
//        hdr.inner_bridged_md.fpga_result.flags.to_fw = local_md.tunnel.flags.to_fw;
//        hdr.inner_bridged_md.fpga_result.meter_id = local_md.tunnel.meter_id;
//        hdr.inner_bridged_md.fpga_result.eid = local_md.tunnel.eid;
//    }
//
//    action decap_tunnel() {
//        hdr.inner_bridged_md.fpga_result.inner_ip =local_md.tunnel.eip;
//        hdr.inner_bridged_md.fpga_result.eip_zone = local_md.tunnel.eip_zone;
//        hdr.inner_bridged_md.fpga_result.igw_node = local_md.tunnel.igw_node;  
//    }
//
//    action decap() {
//        hdr.inner_bridged_md.setValid();
//        decap_tunnel();
//        decap_flags();
//    }
//
//    table eid_add_bridge {
//        key = {
//            local_md.tunnel.vni_type : exact;
//        }
//        actions = {
//            encap;
//            decap;
//        }
//        const default_action = encap();
//        const entries = {
//            (GW_VNI_TYPE_VPC) : decap();
//        }
//    }

    // action eip_in_meter_miss() {
    //     hdr.bridged_md.table_result.drop_reason = GW_DROP_REASON_EIP_IN_METER_MISS;
    // }

    // action set_eip_in_color() {
    //     packet_color = (bit<2>) meter_in.execute();
    // }

    // table eip_in_meter {
    //     key = {
    //         local_md.tunnel.meter_id : exact @name("meter_id");
    //     }

    //     actions = {
    //         @defaultonly eip_in_meter_miss;
    //         set_eip_in_color;
    //     }

    //     const default_action = eip_in_meter_miss;
    //     meters = meter_in;
    //     size = EIP_TABLE_SIZE;
    // }

    // @name(".eip_in_drop_stats_count")
    // action in_drop_count() {
    //     stats_in_drop.count();
    // }

    // @name(".eip_in_drop_stats")
    // table eip_in_drop {
    //     key = {
    //         local_md.tunnel.eid : exact @name("eid");
    //     }

    //     actions = {
    //         in_drop_count;
    //     }

    //     counters = stats_in_drop;
    //     size = EIP_TABLE_SIZE;
    // }

    // @name(".eip_in_stats_count")
    // action eip_in_count() {
    //     stats_in.count();
    // }

    // @name(".eip_in_stats")
    // table eip_in_stats {
    //     key = {
    //         local_md.tunnel.eid  : exact @name("eid");
    //     }

    //     actions = {
    //         eip_in_count;
    //     }

    //     counters = stats_in;
    //     size = EIP_TABLE_SIZE;
    // }

    // action set_eip_out_color() {
    //     packet_color = (bit<2>) meter_out.execute();
    // }

    // table eip_out_meter {
    //     key = {
    //         local_md.tunnel.meter_id : exact @name("meter_id");
    //     }

    //     actions = {
    //         @defaultonly eip_in_meter_miss;
    //         set_eip_out_color;
    //         // redirect_to_igw;
    //     }

    //     const default_action = eip_in_meter_miss;
    //     meters = meter_out;
    //     size = EIP_TABLE_SIZE;
    // }

    // @name(".eip_out_drop_stats_count")
    // action out_drop_count() {
    //     stats_out_drop.count();
    // }

    // @name(".eip_out_drop_stats")
    // table eip_out_drop {
    //     key = {
    //         local_md.tunnel.eid : exact @name("eid");
    //     }

    //     actions = {
    //         out_drop_count;
    //     }

    //     counters = stats_out_drop;
    //     size = EIP_TABLE_SIZE;
    // }

    // @name(".eip_out_stats_count")
    // action eip_out_count() {
    //     stats_out.count();
    // }

    // @name(".eip_out_stats")
    // table eip_out_stats {
    //     key = {
    //         local_md.tunnel.eid  : exact @name("eid");
    //     }

    //     actions = {
    //         eip_out_count;
    //     }

    //     counters = stats_out;
    //     size = EIP_TABLE_SIZE;
    // }

//    action rewrie_flow_trace_for_fpga() {
//        hdr.flow_trace.next_hdr = 0b10;
//    }
//
//    action encap_fpga_mh_for_key1() {
//        hdr.fpga_mh.setValid();
//        hdr.fpga_mh.table_enable[4:4] = 1;
//        hdr.fpga_mh.mode = 0;
//        //hdr.fpga_mh.next_hdr = 0;
//    }
//
//    action encap_fpga_mh_for_key2() {
//        hdr.fpga_mh.setValid();
//        hdr.fpga_mh.table_enable[4:4] = 1;
//        hdr.fpga_mh.mode = 1;
//        //hdr.fpga_mh.next_hdr = 0;
//    }
//
//    action encap_fpga_key1() {
//        hdr.table_1_key.setValid();
//        hdr.table_1_key.eip = local_md.tunnel.eip;
//    }
//
//    // action encap_fpga_key1_v6() {
//    //     hdr.table_1_key.setValid();
//    //     hdr.table_1_key.eip = local_md.lkp.ip_dst_addr;
//    // }
//
//    // table encap_fpga_key1 {
//    //     key = {
//    //         local_md.lkp.ip_type : exact;
//    //     }
//    //     actions = {
//    //         encap_fpga_key1_v4;
//    //         encap_fpga_key1_v6;
//    //     }
//    //     const entries = {
//    //         (SWITCH_IP_TYPE_IPV4) : encap_fpga_key1_v4();
//    //         (SWITCH_IP_TYPE_IPV6) : encap_fpga_key1_v6();
//    //     }
//    // }
//
//    action encap_fpga_key2() {
//        hdr.table_2_key.setValid();
//        hdr.table_2_key.vm_ip = local_md.lkp.ip_src_addr;
//        hdr.table_2_key.vni = local_md.tunnel.vni;
//    }
//
//    // action encap_fpga_key2_v6() {
//    //     hdr.table_2_key.setValid();
//    //     hdr.table_2_key.vm_ip[31:0] = local_md.lkp.ip_dst_addr[95:64];
//    //     hdr.table_2_key.vni = local_md.tunnel.vni;
//    // }
//
//    // table encap_fpga_key2 {
//    //     key = {
//    //         local_md.lkp.ip_type : exact;
//    //     }
//    //     actions = {
//    //         encap_fpga_key2_v4;
//    //         encap_fpga_key2_v6;
//    //     }
//    //     const entries = {
//    //         (SWITCH_IP_TYPE_IPV4) : encap_fpga_key2_v4();
//    //         (SWITCH_IP_TYPE_IPV6) : encap_fpga_key2_v6();
//    //     }
//    // }
//
//    action rewrite_fpga_mh_v4() {
//        hdr.fpga_mh.next_hdr = 0;
//    }
//
//    action rewrite_fpga_mh_v6() {
//        hdr.fpga_mh.next_hdr = 1;
//    }
//
//    table fpga_mh_rewrite {
//        key = {
//            hdr.fpga_mh.isValid() : exact;
//            hdr.ipv4.isValid() : exact;
//            hdr.ipv6.isValid() : exact;
//        }
//        actions = {
//            rewrite_fpga_mh_v4;
//            rewrite_fpga_mh_v6;
//            NoAction;
//        }
//        const default_action = NoAction;
//        const entries = {
//            (true, true, false) : rewrite_fpga_mh_v4();
//            (true, false, true) : rewrite_fpga_mh_v6();
//        }
//    }
//
//    action redirect_pipe23_lo_to_fpga_port(PortId_t port) {
//        ig_intr_md_for_tm.ucast_egress_port = port;
//    }
//
//    table redirect_pipe23_lo_to_fpga {
//        key = {
//            local_md.ingress_port : exact;
//        }
//        actions = {
//            redirect_pipe23_lo_to_fpga_port();
//        }
//    }
//
//    action redirect_pipe23_lo_to_pipe1_port(PortId_t port) {
//        ig_intr_md_for_tm.ucast_egress_port = port;
//    }
//
//    table redirect_pipe23_lo_to_pipe1 {
//        key = {
//            local_md.ingress_port : exact;
//        }
//        actions = {
//            redirect_pipe23_lo_to_pipe1_port;
//        }
//    }
//
//    action set_bridge_flag_to_fpga() {
//        //hdr.bridged_md.flags.to_fpga = true;
//    }
//
//    action set_fpga_miss_tag() {
//        //hdr.bridged_md.flags.hit_in_fpga = false;
//    }
//
//    table set_fpga_miss {
//        // key = {
//        //     hdr.fpga_mh.isValid() : exact;
//        // }
//        actions = {
//            set_fpga_miss_tag;
//            // NoAction;
//        }
//        const default_action = set_fpga_miss_tag();
//    }
//
//    // action vni_in_v4() {
//    //     local_md.tunnel.eip = lkp.ip_dst_addr[31:0];
//    // }
//
//    action vni_in() {
//        local_md.tunnel.eip = local_md.lkp.ip_dst_addr;
//    }
//
//    // action vni_out_v4() {
//    //     local_md.tunnel.eip = lkp.ip_src_addr[31:0];
//    // }
//
//    action vni_out() {
//        local_md.tunnel.eip = local_md.lkp.ip_src_addr;
//    }
//
//    action vni_vpc_v4() {}
//
//    action vni_vpc_v6() {
//        local_md.tunnel.eip = local_md.lkp.ip_src_addr;
//    }
//
//    table vni_type_match {
//        key = {
//            local_md.lkp.ip_type : exact @name("ip_type");
//            local_md.tunnel.vni_type : exact @name("vni_type");
//        }
//
//        actions = {
//            @defaultonly NoAction;
//            // vni_in_v4;
//            // vni_in_v6;
//            // vni_out_v4;
//            // vni_out_v6;
//            vni_in;
//            vni_out;
//            vni_vpc_v4;
//            vni_vpc_v6;
//        }
//
//        const default_action = NoAction;
//
//        const entries = {
//            (SWITCH_IP_TYPE_IPV4, GW_VNI_TYPE_VPC) : vni_vpc_v4();
//            (SWITCH_IP_TYPE_IPV6, GW_VNI_TYPE_VPC) : vni_vpc_v6();
//            (SWITCH_IP_TYPE_IPV4, GW_VNI_TYPE_IN) : vni_in();
//            (SWITCH_IP_TYPE_IPV6, GW_VNI_TYPE_IN) : vni_in();
//            (SWITCH_IP_TYPE_IPV4, GW_VNI_TYPE_OUT) : vni_out();
//            (SWITCH_IP_TYPE_IPV6, GW_VNI_TYPE_OUT) : vni_out();
//            // (SWITCH_IP_TYPE_IPV4, GW_VNI_TYPE_IN) : vni_in_v4();
//            // (SWITCH_IP_TYPE_IPV6, GW_VNI_TYPE_IN) : vni_in_v6();
//            // (SWITCH_IP_TYPE_IPV4, GW_VNI_TYPE_OUT) : vni_out_v4();
//            // (SWITCH_IP_TYPE_IPV6, GW_VNI_TYPE_OUT) : vni_out_v6();
//        }
//    }
//
//    apply {
//        vni_type_match.apply();
//        if (local_md.tunnel.vni_type == GW_VNI_TYPE_VPC) {
//            switch(private_ip_to_eid.apply().action_run) {
//                private_ip_hit : {
//                    eip_info.apply();
//                    eid_add_bridge.apply();
//                    set_fpga_miss.apply();
//                }
//                private_ip_miss : {
//                    rewrie_flow_trace_for_fpga();
//                    encap_fpga_mh_for_key2();
//                    encap_fpga_key2();
//                    set_bridge_flag_to_fpga();
//                }
//            } 
//        } else {
//            switch(eip_to_eid.apply().action_run) {
//                eip_hit : {                 
//                    eip_info.apply();
//                    eid_add_bridge.apply();
//                    set_fpga_miss.apply();
//                }
//                eip_miss : {
//                    rewrie_flow_trace_for_fpga();
//                    encap_fpga_mh_for_key1();
//                    encap_fpga_key1();
//                    set_bridge_flag_to_fpga();
//                }
//            }
//        }
//        fpga_mh_rewrite.apply();     
//        //redirect to different devices
//        if (hdr.table_1_key.isValid() || hdr.table_2_key.isValid()) {
//            redirect_pipe23_lo_to_fpga.apply();
//        }
//        else {
//            redirect_pipe23_lo_to_pipe1.apply();
//        }
//    }
//}

control FromNic(inout switch_header_t hdr,
                      inout switch_local_metadata_t local_md,
                      inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    action set_to_port(switch_port_t port) {
        ig_intr_md_for_tm.ucast_egress_port = port;
    }

    table redirect_to_port {
        key = {
            local_md.ingress_port : exact;
        }
        actions = {
            set_to_port;
        }
    }
    apply {
        redirect_to_port.apply();
    }
}

//-----------------------------------------------------------------------------
// Tunnel decapsulation
//
//-----------------------------------------------------------------------------
control TunnelDecap(inout switch_header_t hdr,
                    inout switch_local_metadata_t local_md)() {
    /*
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

        hdr.ipv4.ttl = hdr.inner_ipv4.ttl;
        hdr.ipv4.diffserv = hdr.inner_ipv4.diffserv;

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

        hdr.ipv6.hop_limit = hdr.inner_ipv6.hop_limit;
        hdr.ipv6.traffic_class = hdr.inner_ipv6.traffic_class;

        hdr.inner_ipv6.setInvalid();
    }
    */

    action invalidate_vxlan_header() {
        hdr.vxlan.setInvalid();
    }

    action invalidate_vlan_tag0() {
        hdr.vlan_tag[0].setInvalid();
    }

    action decap_inner_ethernet_ipv4() {
        invalidate_vlan_tag0();
        hdr.ethernet = hdr.inner_ethernet;
        // copy_ipv4_header();
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.udp.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_vxlan_header();
    }

    action decap_inner_ethernet_ipv6() {
        invalidate_vlan_tag0();
        hdr.ethernet = hdr.inner_ethernet;
        // copy_ipv6_header();
        hdr.ipv6.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.udp.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_vxlan_header();
    }

    action decap_inner_ethernet_non_ip() {
        invalidate_vlan_tag0();
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.udp.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_vxlan_header();
    }

    action decap_inner_ipv4() {
        invalidate_vlan_tag0();
        // hdr.ethernet.ether_type = ETHERTYPE_IPV4; // comment out for flow_trace (ETHERTYPE_FPT)
        hdr.flow_trace.next_hdr = 0;
        // copy_ipv4_header();
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
    }

    action decap_inner_ipv6() {
        invalidate_vlan_tag0();
        // hdr.ethernet.ether_type = ETHERTYPE_IPV6; // comment out for flow_trace (ETHERTYPE_FPT)
        hdr.flow_trace.next_hdr = 1;
        // copy_ipv6_header();
        hdr.ipv6.setInvalid();
        hdr.ipv4.setInvalid();
    }

    table decap_tunnel_hdr {
        key = {
            hdr.udp.isValid() : exact;
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
            (true, true, true, false) : decap_inner_ethernet_ipv4;
            (true, true, false, true) : decap_inner_ethernet_ipv6;
            (true, true, false, false) : decap_inner_ethernet_non_ip;
            (false, false, true, false) : decap_inner_ipv4;
            (false, false, false, true) : decap_inner_ipv6;
        }
        size = MIN_TABLE_SIZE;
    }

    apply {
        if (!local_md.flags.bypass_egress) {
            // Copy inner L2/L3 headers into outer headers.
            decap_tunnel_hdr.apply();
            hdr.ethernet.ether_type = 0x88B5;
        }
    }
}

// //-----------------------------------------------------------------------------
// // Tunnel decapsulation
// //-----------------------------------------------------------------------------
// control TunnelDecap(inout switch_header_t hdr,
//                     inout switch_local_metadata_t local_md)() {

//     action copy_ipv4_header() {
//         hdr.ipv4.setValid();
//         hdr.ipv4.version = hdr.inner_ipv4.version;
//         hdr.ipv4.ihl = hdr.inner_ipv4.ihl;
//         hdr.ipv4.total_len = hdr.inner_ipv4.total_len;
//         hdr.ipv4.identification = hdr.inner_ipv4.identification;
//         hdr.ipv4.flags = hdr.inner_ipv4.flags;
//         hdr.ipv4.frag_offset = hdr.inner_ipv4.frag_offset;
//         hdr.ipv4.protocol = hdr.inner_ipv4.protocol;
//         // hdr.ipv4.hdr_checksum = hdr.inner_ipv4.hdr_checksum;
//         hdr.ipv4.src_addr = hdr.inner_ipv4.src_addr;
//         hdr.ipv4.dst_addr = hdr.inner_ipv4.dst_addr;

//         hdr.ipv4.ttl = hdr.inner_ipv4.ttl;
//         hdr.ipv4.diffserv = hdr.inner_ipv4.diffserv;

//         hdr.inner_ipv4.setInvalid();
//     }

//     action copy_ipv6_header() {
//         hdr.ipv6.setValid();
//         hdr.ipv6.version = hdr.inner_ipv6.version;
//         hdr.ipv6.flow_label = hdr.inner_ipv6.flow_label;
//         hdr.ipv6.payload_len = hdr.inner_ipv6.payload_len;
//         hdr.ipv6.next_hdr = hdr.inner_ipv6.next_hdr;
//         hdr.ipv6.src_addr = hdr.inner_ipv6.src_addr;
//         hdr.ipv6.dst_addr = hdr.inner_ipv6.dst_addr;

//         hdr.ipv6.hop_limit = hdr.inner_ipv6.hop_limit;
//         hdr.ipv6.traffic_class = hdr.inner_ipv6.traffic_class;

//         hdr.inner_ipv6.setInvalid();
//     }

//     action invalidate_vxlan_header() {
//         hdr.vxlan.setInvalid();
//     }

//     action invalidate_vlan_tag0() {
//         hdr.vlan_tag[0].setInvalid();
//     }

//     action decap_inner_ethernet_ipv4() {
//         invalidate_vlan_tag0();
//         hdr.ethernet = hdr.inner_ethernet;
//         copy_ipv4_header();
//         hdr.ipv6.setInvalid();
//         hdr.udp.setInvalid();
//         hdr.inner_ethernet.setInvalid();
//         invalidate_vxlan_header();
//     }

//     action decap_inner_ethernet_ipv6() {
//         invalidate_vlan_tag0();
//         hdr.ethernet = hdr.inner_ethernet;
//         copy_ipv6_header();
//         hdr.ipv4.setInvalid();
//         hdr.udp.setInvalid();
//         hdr.inner_ethernet.setInvalid();
//         invalidate_vxlan_header();
//     }


//     table tunnel_decap {
//         key = {
//             local_md.tunnel.vm_vtep_type : exact;
//         }

//         actions = {
//             decap_inner_ethernet_ipv4;
//             decap_inner_ethernet_ipv6;
//         }
//         size = MIN_TABLE_SIZE;
//     }

//     apply {
//         if (!local_md.flags.bypass_egress) {
//             // Copy inner L2/L3 headers into outer headers.
//             tunnel_decap.apply();
//         }
//     }
// }


//-----------------------------------------------------------------------------
// Tunnel encapsulation
//         -- Copy Outer Headers to inner
//         -- Add Tunnel Header (VXLAN, GRE etc)
//-----------------------------------------------------------------------------
control TunnelEncap(inout switch_header_t hdr,
                    inout switch_local_metadata_t local_md)() {
    bit<16> payload_len;
    bit<8> ip_proto;
    bit<16> gre_proto;

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
        local_md.inner_ipv4_checksum_update_en = true;
    }

    action copy_ipv6_header() {
        hdr.inner_ipv6.setValid();
        hdr.inner_ipv6.version = hdr.ipv6.version;
        hdr.inner_ipv6.flow_label = hdr.ipv6.flow_label;
        hdr.inner_ipv6.payload_len = hdr.ipv6.payload_len;
        hdr.inner_ipv6.src_addr = hdr.ipv6.src_addr;
        hdr.inner_ipv6.dst_addr = hdr.ipv6.dst_addr;
        hdr.inner_ipv6.hop_limit = hdr.ipv6.hop_limit - 1;
        hdr.inner_ipv6.traffic_class = hdr.ipv6.traffic_class;
        hdr.ipv6.setInvalid();
    }

    action copy_inner_ipv4_udp() {
        payload_len = hdr.ipv4.total_len;
        hdr.inner_ipv4.ttl = hdr.inner_ipv4.ttl - 1;
        copy_ipv4_header();
        // hdr.inner_udp = hdr.udp;
        // hdr.udp.setInvalid();
        ip_proto = 4;
     gre_proto = 0x0800;
    }

/*
    action copy_inner_ipv4_tcp() {
        payload_len = hdr.ipv4.total_len;
        hdr.inner_ipv4.ttl = hdr.inner_ipv4.ttl - 1;
        copy_ipv4_header();
        hdr.inner_tcp = hdr.tcp;
        hdr.tcp.setInvalid();
        ip_proto = IP_PROTOCOLS_IPV4;
	gre_proto = GRE_PROTOCOLS_IP;
    }
*/
    action copy_inner_ipv4_unknown() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        ip_proto = 4;
     gre_proto = 0x0800;
    }

    action copy_inner_ipv6_udp() {
        payload_len = hdr.ipv6.payload_len + 16w40;
        hdr.inner_ipv6.hop_limit = hdr.inner_ipv6.hop_limit - 1;
        // hdr.inner_ipv6 = hdr.ipv6;
        // hdr.inner_udp = hdr.udp;
        // hdr.udp.setInvalid();
        // hdr.ipv6.setInvalid();
        ip_proto = 41;
     gre_proto = 0x86dd;
    }

/*
    action copy_inner_ipv6_tcp() {
        payload_len = hdr.ipv6.payload_len + 16w40;
        hdr.inner_ipv6.hop_limit = hdr.inner_ipv6.hop_limit - 1;
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_tcp = hdr.tcp;
        hdr.tcp.setInvalid();
        hdr.ipv6.setInvalid();
        ip_proto = IP_PROTOCOLS_IPV6;
	gre_proto = GRE_PROTOCOLS_IPV6;
    }
*/
    action copy_inner_ipv6_unknown() {
        payload_len = hdr.ipv6.payload_len + 16w40;
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.ipv6.setInvalid();
        ip_proto = 41;
     gre_proto = 0x86dd;
    }

    action copy_inner_non_ip() {
        payload_len = local_md.pkt_length - 16w14;
    }


    table tunnel_encap_0 {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            // hdr.inner_udp.isValid() : exact;
            // hdr.tcp.isValid() : exact; uncomment and add tcp actions if tcp header is parsed in egress
        }

        actions = {
            // copy_inner_ipv4_udp;
            copy_inner_ipv4_unknown;
            // copy_inner_ipv6_udp;
            copy_inner_ipv6_unknown;
         // copy_inner_non_ip;
        }

        const entries = {
            // (true, false, false) : copy_inner_ipv4_unknown();
            // (false, true, false) : copy_inner_ipv6_unknown();
            // (true, false, true) : copy_inner_ipv4_udp();
            // (false, true, true) : copy_inner_ipv6_udp();
            // (false, false, false) : copy_inner_non_ip();
            (true, false) : copy_inner_ipv4_unknown();
            (false, true) : copy_inner_ipv6_unknown();
        }
        size = 4;
    }
    // table tunnel_encap_0 {
    //     key = {
    //         hdr.inner_ipv4.isValid() : exact;
    //         hdr.inner_ipv6.isValid() : exact;
    //         hdr,inner_udp.isValid() : exact;
    //     }

    //     actions = {
    //         extract_ipv4_length;
    //         extract_ipv6_length;
    //     }

    //     const entries = {
    //         (true, false) : extract_ipv4_length();
    //         (false, true) : extract_ipv6_length();
    //     }
    //     size = 8;
    // }


    //
    // ************ Add outer IP encapsulation **************************
    //
    action add_udp_header(bit<16> src_port, bit<16> dst_port) {
        hdr.udp.setValid();
        hdr.udp.src_port = src_port;
        hdr.udp.dst_port = dst_port;
        hdr.udp.checksum = 0;
        // hdr.udp.length = 0;
    }

    action add_vxlan_header(bit<24> vni) {

        hdr.vxlan.setValid();
        hdr.vxlan.flags = 8w0x08;
        // hdr.vxlan.reserved = 0;
        hdr.vxlan.vni = vni;
        hdr.vxlan.reserved2 = local_md.tunnel.resv; // for source learning

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
        hdr.ipv4.diffserv[7:2] = GW_IP_TOS;

        hdr.ipv4.ttl = DEFAULT_VXLAN_TTL + 1;
        hdr.ipv4.src_addr = local_md.tunnel.src_vtep[95:64];
        hdr.ipv4.dst_addr = local_md.tunnel.dst_vtep[95:64];
    }

    action add_ipv6_header(bit<8> proto) {
        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w6;
        hdr.ipv6.flow_label = 0;
        // hdr.ipv6.payload_len = 0;
        hdr.ipv6.next_hdr = proto;
        hdr.ipv6.traffic_class[7:2] = GW_IP_TOS;

        hdr.ipv6.hop_limit = DEFAULT_VXLAN_TTL + 1;
        hdr.ipv6.src_addr = local_md.tunnel.src_vtep;
        hdr.ipv6.dst_addr = local_md.tunnel.dst_vtep;
    }


    @name(".encap_ipv4_vxlan")
    action encap_ipv4_vxlan(bit<16> vxlan_port) {
        hdr.inner_ethernet.setValid();
        hdr.inner_ethernet = hdr.ethernet;//to fix
        add_ipv4_header(17);
        hdr.ipv4.flags = 0x2;
        // Total length = packet length + 50
        //   IPv4 (20) + UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.ipv4.total_len = payload_len + hdr.ipv4.minSizeInBytes() +
        hdr.udp.minSizeInBytes() + hdr.vxlan.minSizeInBytes() + hdr.inner_ethernet.minSizeInBytes();
        add_udp_header(local_md.tunnel.hash[15:0], vxlan_port);
        // UDP length = packet length + 30
        //   UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.udp.length = payload_len + hdr.udp.minSizeInBytes() + hdr.vxlan.minSizeInBytes() + hdr.inner_ethernet.minSizeInBytes();
        // Pkt length
        local_md.pkt_length = local_md.pkt_length + hdr.ipv4.minSizeInBytes() +
        hdr.udp.minSizeInBytes() + hdr.vxlan.minSizeInBytes() + hdr.inner_ethernet.minSizeInBytes();

        add_vxlan_header(local_md.tunnel.vni);
        // hdr.ethernet.ether_type = ETHERTYPE_IPV4; // comment out for flow_trace (ETHERTYPE_FPT)
        hdr.flow_trace.next_hdr = 0b00;
    }
    @name(".encap_ipv6_vxlan")
    action encap_ipv6_vxlan(bit<16> vxlan_port) {

        hdr.inner_ethernet.setValid();
        hdr.inner_ethernet = hdr.ethernet;
        add_ipv6_header(17);
        // Payload length = packet length + 50
        //   UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.ipv6.payload_len = payload_len + hdr.udp.minSizeInBytes() + hdr.vxlan.minSizeInBytes() + hdr.inner_ethernet.minSizeInBytes();
        add_udp_header(local_md.tunnel.hash[15:0], vxlan_port);
        // UDP length = packet length + 30
        //   UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.udp.length = payload_len + hdr.udp.minSizeInBytes() + hdr.vxlan.minSizeInBytes() + hdr.inner_ethernet.minSizeInBytes();
        // Pkt length
        local_md.pkt_length = local_md.pkt_length + hdr.ipv6.minSizeInBytes() +
        hdr.udp.minSizeInBytes() + hdr.vxlan.minSizeInBytes() + hdr.inner_ethernet.minSizeInBytes();

        add_vxlan_header(local_md.tunnel.vni);
        // hdr.ethernet.ether_type = ETHERTYPE_IPV6; // comment out for flow_trace (ETHERTYPE_FPT)
        hdr.flow_trace.next_hdr = 0b01;

    }


    @name(".encap_ipv4_ip")
    action encap_ipv4_ip() {
        add_ipv4_header(ip_proto);
        // Total length = packet length + 20
        //   IPv4 (20)
        hdr.ipv4.total_len = payload_len + hdr.ipv4.minSizeInBytes();
        // Pkt length
        local_md.pkt_length = local_md.pkt_length + hdr.ipv4.minSizeInBytes();
        // hdr.ethernet.ether_type = ETHERTYPE_IPV4; // comment out for flow_trace (ETHERTYPE_FPT)
    }

    @name(".encap_ipv6_ip")
    action encap_ipv6_ip() {

        add_ipv6_header(ip_proto);
        // Payload length = packet length
        hdr.ipv6.payload_len = payload_len;
        // Pkt length
        local_md.pkt_length = local_md.pkt_length + hdr.ipv6.minSizeInBytes();
        // hdr.ethernet.ether_type = ETHERTYPE_IPV6; // comment out for flow_trace (ETHERTYPE_FPT)

    }

    @name(".tunnel_encap_1")
    table tunnel_encap_1 {
        key = {
            local_md.tunnel.type : exact;
        }

        actions = {
            NoAction;

            encap_ipv4_vxlan;
            encap_ipv6_vxlan;

            encap_ipv4_ip;
            encap_ipv6_ip;
        }

        const default_action = NoAction;
        size = MIN_TABLE_SIZE;
        const entries = {
            SWITCH_EGRESS_TUNNEL_TYPE_IPV4_VXLAN : encap_ipv4_vxlan(4789);
            SWITCH_EGRESS_TUNNEL_TYPE_IPV6_VXLAN : encap_ipv6_vxlan(4789);
        }
    }

    action change_ether_type_for_v4() {
        hdr.inner_ethernet.ether_type = 0x0800;
    }

    action change_ether_type_for_v6() {
        hdr.inner_ethernet.ether_type = 0x86dd;
    }

    table inner_ethernet_fix {
        key = {
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }
        actions = {
            change_ether_type_for_v4;
            change_ether_type_for_v6;
        }
        const entries = {
            (true, false) : change_ether_type_for_v4();
            (false, true) : change_ether_type_for_v6();
        }
    }

    apply {
        // Copy L3/L4 header into inner headers.
        tunnel_encap_0.apply();
        // Add outer IP encapsulation
        tunnel_encap_1.apply();
        inner_ethernet_fix.apply();
    }
}

// //-----------------------------------------------------------------------------
// // IP Tunnel Encapsulation - Step 3
// //         -- Outer SIP Rewrite
// //         -- Outer DIP Rewrite

// //-----------------------------------------------------------------------------
// control TunnelRewrite(inout switch_header_t hdr, inout gw_local_metadata_t local_md)() {

//     bit<32> gw_src_ipv4;
//     bit<128> gw_src_ipv6;

//     action set_gw_src_ip(ipv4_addr_t gw_vtep_v4, ipv6_addr_t gw_vtep_v6) {
//         gw_src_ipv4 = gw_vtep_v4;
//         gw_src_ipv6 = gw_vtep_v6;
//     }

//     action src_ip_miss() {
//         local_md.drop_reason = SWITCH_DROP_REASON_SRC_IP_MISS;//to fix drop action
//     }

//     table set_gw_ip {
//         actions = {
//             set_gw_src_ip;
//             src_ip_miss;
//         }
//         default_action = src_ip_miss;
//     }

//     action v4in4_encap_rewrite() {
//         hdr.ipv4.src_addr = gw_src_ipv4;
//         hdr.ipv4.dst_addr = local_md.tunnel.vm_vtep[31:0];
//         hdr.inner_ipv4.dst_addr = local_md.tunnel.private_ip[31:0];
//     }

//     action v4in6_encap_rewrite() {
//         hdr.ipv6.src_addr = gw_src_ipv6;
//         hdr.ipv6.dst_addr = local_md.tunnel.vm_vtep;
//         hdr.inner_ipv4.dst_addr = local_md.tunnel.private_ip[31:0];
//     }

//     action v6in4_encap_rewrite() {
//         hdr.ipv4.src_addr = gw_src_ipv4;
//         hdr.ipv4.dst_addr = local_md.tunnel.vm_vtep[31:0];
//         hdr.inner_ipv6.dst_addr = local_md.tunnel.private_ip;
//     }

//     action v6in6_encap_rewrite() {
//         hdr.ipv6.src_addr = gw_src_ipv6;
//         hdr.ipv6.dst_addr = local_md.tunnel.vm_vtep;
//         hdr.inner_ipv6.dst_addr = local_md.tunnel.private_ip;
//     }

//     action v4_decap_rewrite() {
//         hdr.inner_ipv4.src_addr = local_md.tunnel.eip[31:0];
//     }

//     action v6_decap_rewrite() {
//         hdr.inner_ipv6.src_addr = local_md.tunnel.eip;
//     }

//     @name(".service_rewrite")
//     table service_rewrite {
//         key = {
//             hdr.inner_ipv4.isValid() : exact;
//             hdr.inner_ipv6.isValid() : exact;
//             hdr.ipv4.isValid() : exact;
//             hdr.ipv6.isValid() : exact;
//         }
//         actions = {
//             NoAction;
//             v4in4_encap_rewrite;
//             v4in6_encap_rewrite;
//             v6in4_encap_rewrite;
//             v6in6_encap_rewrite;
//             v4_decap_rewrite;
//             v6_decap_rewrite;
//         }

//         const entries = {
//             (true, false, true, false) : v4in4_encap_rewrite;
//             (true, false, false, true) : v4in6_encap_rewrite;
//             (false, true, true, false) : v6in4_encap_rewrite;
//             (false, true, false, true) : v6in6_encap_rewrite;
//             (true, false, false, false) : v4_decap_rewrite;
//             (false, true, false, false) : v6_decap_rewrite;
//         }
//         size = MIN_TABLE_SIZE;
//     }

//     //
//     // ***************** Control Flow ***********************
//     //
//     apply {
//         set_gw_ip.apply();
//         service_rewrite.apply();
//     }
// }

//-----------------------------------------------------------------------------
// IP Tunnel Encapsulation - Step 3
//         -- Outer SIP Rewrite
//         -- Outer DIP Rewrite

//-----------------------------------------------------------------------------
//control FPGABridgeMdConstruct(inout switch_header_t hdr, inout switch_local_metadata_t local_md)() {
//    //bit<1> zero = 0b0;
//    //bit<1> one = 0b01;
//    //bit<1> two = 0b10;
//    
//    action set_table_1_flags() {
//        hdr.inner_bridged_md.setValid();
//        hdr.inner_bridged_md.fpga_result.igw_node = hdr.table_1_result.igw_node;
//        hdr.inner_bridged_md.fpga_result.flags.outer_ip_type = hdr.table_1_result.flags.outer_ip_type;
//        hdr.inner_bridged_md.fpga_result.flags.inner_ip_type = hdr.table_1_result.flags.inner_ip_type;
//        hdr.inner_bridged_md.fpga_result.flags.to_igw = hdr.table_1_result.flags.to_igw;
//        hdr.inner_bridged_md.fpga_result.flags.to_fw = hdr.table_1_result.flags.to_fw;
//        hdr.inner_bridged_md.fpga_result.flags.to_lb = hdr.table_1_result.flags.to_lb;
//    }
//
//    action set_table_1_result() {
//        //hdr.bridged_md.table_result.gw_pkt_type = 0;//fix
//        hdr.inner_bridged_md.fpga_result.inner_ip = hdr.table_1_result.inner_ip;
//        hdr.inner_bridged_md.fpga_result.outer_ip = hdr.table_1_result.outer_ip;
//        hdr.inner_bridged_md.fpga_result.vni = hdr.table_1_result.vni;
//        hdr.inner_bridged_md.fpga_result.eip_zone = hdr.table_1_result.eip_zone;
//        hdr.inner_bridged_md.fpga_result.bwp_zone = hdr.table_1_result.bwp_zone;
//        //set_table_1_flags();
//        hdr.table_1_result.setInvalid();
//    }
//
//    action set_table_2_flags() {
//        hdr.inner_bridged_md.setValid();
//        hdr.inner_bridged_md.fpga_result.flags.outer_ip_type = hdr.table_2_result.flags.outer_ip_type;
//        hdr.inner_bridged_md.fpga_result.flags.inner_ip_type = hdr.table_2_result.flags.inner_ip_type;
//        hdr.inner_bridged_md.fpga_result.flags.to_igw = hdr.table_2_result.flags.to_igw;
//        hdr.inner_bridged_md.fpga_result.flags.to_fw = hdr.table_2_result.flags.to_fw;
//    }
//
//    action set_table_2_result() {
//        //hdr.bridged_md.table_result.gw_pkt_type = 1;//fix
//        hdr.inner_bridged_md.fpga_result.inner_ip = hdr.table_2_result.inner_ip;
//        hdr.inner_bridged_md.fpga_result.eip_zone = hdr.table_2_result.eip_zone;
//        hdr.inner_bridged_md.fpga_result.igw_node = hdr.table_2_result.igw_node;
//        //set_table_2_flags();
//        hdr.table_2_result.setInvalid();
//    }
//    
//    action rewrite_flow_trace_v4() {
//        hdr.flow_trace.next_hdr = 0b00;
//        hdr.fpga_mh.setInvalid(); 
//    }
//
//    action rewrite_flow_trace_v6() {
//        hdr.flow_trace.next_hdr = 0b01;
//        hdr.fpga_mh.setInvalid(); 
//    }
//
//    table flow_trace_rewrite {
//        key = {
//            hdr.fpga_mh.next_hdr : exact;
//        }
//        actions = {
//            rewrite_flow_trace_v4;
//            rewrite_flow_trace_v6;
//        }
//        const entries = {
//            0 : rewrite_flow_trace_v4;
//            1 : rewrite_flow_trace_v6;
//        }
//    }
//
//    // action set_ip_type(bit<2> outer_ip_type) {
//    //     hdr.inner_bridged_md.fpga_result.ip_type = outer_ip_type;
//    // }
//
//    // table set_outer_type {
//    //     key = {
//    //         hdr.table_1_result.isValid() : exact;
//    //         hdr.table_2_result.isValid() : exact;
//    //         hdr.table_1_result.result_type : exact;
//    //     }
//    //     actions = {
//    //         set_ip_type;
//    //     }
//    //     const entries = {
//    //         (true, false, 0x01) : set_ip_type(0b01);
//    //         (true, false, 0x02) : set_ip_type(0b01);
//    //         (true, false, 0x03) : set_ip_type(0b10);
//    //         (true, false, 0x04) : set_ip_type(0b10);
//    //         (false, true, 0x01) : set_ip_type(0b01);
//    //         (false, true, 0x02) : set_ip_type(0b10);
//    //     }
//    // }
//    
//
//    @name(".bridged_metadata_rewrite")
//    table bridged_metadata_rewrite {
//        key = {
//            hdr.table_1_result.isValid() : exact;
//            hdr.table_2_result.isValid() : exact;
//        }
//        actions = {
//            //NoAction;
//            set_table_1_result;
//            set_table_2_result;
//        }
//
//        const entries = {
//            (true, false) : set_table_1_result;
//            (false, true) : set_table_2_result;
//        }
//        size = MIN_TABLE_SIZE;
//    }
//
//    @name(".bridged_metadata_flags_rewrite")
//    table bridged_metadata_flags_rewrite {
//        key = {
//            hdr.table_1_result.isValid() : exact;
//            hdr.table_2_result.isValid() : exact;
//        }
//        actions = {
//            //NoAction;
//            set_table_1_flags;
//            set_table_2_flags;
//        }
//
//        const entries = {
//            (true, false) : set_table_1_flags;
//            (false, true) : set_table_2_flags;
//        }
//        size = MIN_TABLE_SIZE;
//    }
//
//    action fpga_hash_construct_bridged_md() {
//        hdr.bridged_md.table_result.hash = hdr.hash_bridged_md.hash;
//    }
//
//    // action set_fpga_drop_reason_to_0() {
//    //     hdr.bridged_md.table_result.drop_reason = 0;
//    // }
//
//    action set_fpga_hit() {
//        //hdr.bridged_md.flags.hit_in_fpga = true;
//    }
//    
//
//    action add_bridged_md_1() {
//        hdr.bridged_md.setValid();
//        hdr.bridged_md.src = hdr.compress_bridged_md.compress.src;
//        hdr.bridged_md.type = hdr.compress_bridged_md.compress.type;
//
//        hdr.bridged_md.base.pkt_type = hdr.compress_bridged_md.compress.pkt_type;
//        hdr.bridged_md.base.tc = hdr.compress_bridged_md.compress.tc;
//        hdr.bridged_md.base.qid = hdr.compress_bridged_md.compress.qid;
//        hdr.bridged_md.base.vrf = hdr.compress_bridged_md.compress.vrf;
//        hdr.bridged_md.base.routed = true;
//        hdr.bridged_md.base.bypass_egress = false;
//
//        hdr.bridged_md.acl.l4_src_port = hdr.compress_bridged_md.compress.l4_src_port;
//        hdr.bridged_md.acl.l4_dst_port = hdr.compress_bridged_md.compress.l4_dst_port;
//        hdr.bridged_md.acl.tcp_flags = hdr.compress_bridged_md.compress.tcp_flags;
//
//        hdr.bridged_md.table_result.terminate = hdr.compress_bridged_md.compress.terminate;
//        hdr.bridged_md.table_result.encap = hdr.compress_bridged_md.compress.encap;
//        hdr.bridged_md.table_result.vni_type = hdr.compress_bridged_md.compress.vni_type;
//        hdr.bridged_md.table_result.eip_net_hit = hdr.compress_bridged_md.compress.eip_net_hit;
//
//        hdr.bridged_md.nic.tofino_to_nic = hdr.compress_bridged_md.compress.tofino_to_nic;
// 
//    }
//    //
//    // ***************** Control Flow ***********************
//    //
//
//    apply {
//            // if(set_outer_type.apply().hit){
//            //     set_fpga_drop_reason_to_0();
//            // }       
//            flow_trace_rewrite.apply();
//            bridged_metadata_flags_rewrite.apply();
//            if(bridged_metadata_rewrite.apply().hit){
//                add_bridged_md_1();
//                fpga_hash_construct_bridged_md();
//                //set_fpga_drop_reason_to_0();
//                set_fpga_hit();
//            } 
//    }
//}

control CPUBridgeMdConstruct(inout switch_header_t hdr, inout switch_local_metadata_t local_md)() {
    //bit<1> zero = 0b0;
    //bit<1> one = 0b01;
    //bit<1> two = 0b10;

    action rewrite_flow_trace_v4() {
        hdr.flow_trace.next_hdr = 0b00;
        hdr.cpu_mh.setInvalid();
    }

    action rewrite_flow_trace_v6() {
        hdr.flow_trace.next_hdr = 0b01;
        hdr.cpu_mh.setInvalid();
    }

    table flow_trace_rewrite {
        key = {
            hdr.cpu_mh.next_hdr : exact;
        }
        actions = {
            rewrite_flow_trace_v4;
            rewrite_flow_trace_v6;
        }
        const entries = {
            0 : rewrite_flow_trace_v4;
            1 : rewrite_flow_trace_v6;
        }
    }

    //action fpga_hash_construct_bridged_md() {
    //   hdr.bridged_md.table_result.hash = hdr.hash_bridged_md.hash;
    //}

    // action set_fpga_drop_reason_to_0() {
    //     hdr.bridged_md.table_result.drop_reason = 0;
    // }

    // 
    // ***************** Control Flow ***********************
    //
    apply {
            flow_trace_rewrite.apply();
            //fpga_hash_construct_bridged_md();
            //set_fpga_drop_reason_to_0();
    }
}

control MplsTunnelEncap(inout switch_header_t hdr,
                        inout switch_local_metadata_t local_md)() {
    bit<16> payload_len;
    bit<8> ip_proto;
    switch_ip_type_t ip_type;

    //
    // ************ Copy outer to inner **************************
    //
    action copy_inner_ipv4_unknown() {
        payload_len = hdr.inner_ipv4.total_len;
        // hdr.inner_ipv4.ttl = hdr.inner_ipv4.ttl - 1;
        ip_proto = 4;
    }

    action copy_inner_ipv6_unknown() {
        payload_len = hdr.inner_ipv6.payload_len + 16w40;
        // hdr.inner_ipv6.hop_limit = hdr.inner_ipv6.hop_limit - 1;
        ip_proto = 41;
    }

    table tunnel_encap_0 {
        key = {
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }

        actions = {
            copy_inner_ipv4_unknown;
            copy_inner_ipv6_unknown;
        }

        const entries = {
            (true, false) : copy_inner_ipv4_unknown();
            (false, true) : copy_inner_ipv6_unknown();
        }
        size = 4;
    }

    //
    // ************ Add MPLS encapsulation **************************
    //
    action rewrite_payload_len_1() {
        payload_len = payload_len + hdr.mpls[0].minSizeInBytes();
    }

    action rewrite_payload_len_2() {
        payload_len = payload_len + hdr.mpls[0].minSizeInBytes() + hdr.mpls[1].minSizeInBytes();
    }

    action rewrite_payload_len_3() {
        payload_len = payload_len + hdr.mpls[0].minSizeInBytes() + hdr.mpls[1].minSizeInBytes() +
          hdr.mpls[2].minSizeInBytes();
    }

    table mpls_payload_len {
        key = {
            local_md.tunnel.mpls_push_count : exact;
        }

        actions = {
            @defaultonly NoAction;
            rewrite_payload_len_1;
            rewrite_payload_len_2;
            rewrite_payload_len_3;
        }

        const default_action = NoAction;
        const entries = {
            1 : rewrite_payload_len_1();
            2 : rewrite_payload_len_2();
            3 : rewrite_payload_len_3();
        }
    }

    //
    // ************ Add outer IP encapsulation **************************
    //
    action add_udp_header(bit<16> src_port, bit<16> dst_port) {
        hdr.udp.setValid();
        hdr.udp.src_port = src_port | 0xC000;
        hdr.udp.dst_port = dst_port;
        hdr.udp.checksum = 0;
        // hdr.udp.length = 0;
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
        hdr.ipv4.diffserv = local_md.lkp.ip_tos;

        hdr.ipv4.ttl = DEFAULT_VXLAN_TTL + 1;
    }

    bit<20> ipv6_fl = 0;
    bit<4> ipv6_ver = 4w6;
    action add_ipv6_header(bit<8> proto) {
        hdr.ipv6.setValid();
        hdr.ipv6.version = ipv6_ver;
        hdr.ipv6.flow_label = ipv6_fl;
        // hdr.ipv6.payload_len = 0;
        hdr.ipv6.next_hdr = proto;
        hdr.ipv6.traffic_class = local_md.lkp.ip_tos;

        hdr.ipv6.hop_limit = DEFAULT_VXLAN_TTL + 1;
    }

    @name(".encap_ipv4_mpls")
    action encap_ipv4_mpls(ipv4_addr_t dst_addr) {
        add_ipv4_header(17);
        hdr.ipv4.flags = 0x2;
        hdr.ipv4.dst_addr = dst_addr;
        // Total length = packet length + 28 + 
        //   IPv4 (20) + UDP (8) + MPLS ()
        hdr.ipv4.total_len = payload_len + hdr.ipv4.minSizeInBytes() + hdr.udp.minSizeInBytes();
        add_udp_header(local_md.tunnel.hash[15:0], 6635);
        // UDP length = packet length + 8 + 
        //   UDP (8) + MPLS ()
        hdr.udp.length = payload_len + hdr.udp.minSizeInBytes();
        // Pkt length
        local_md.pkt_length = local_md.pkt_length + hdr.ipv4.minSizeInBytes() + hdr.udp.minSizeInBytes();

        hdr.ethernet.ether_type = 0x0800;
        ip_type = SWITCH_IP_TYPE_IPV4;
    }

    @name(".encap_ipv6_mpls")
    action encap_ipv6_mpls(ipv6_addr_t dst_addr) {
        add_ipv6_header(17);
        hdr.ipv6.dst_addr = dst_addr;
        // Payload length = packet length + 50
        //   UDP (8) + MPLS ()
        hdr.ipv6.payload_len = payload_len + hdr.udp.minSizeInBytes();
        add_udp_header(local_md.tunnel.hash[15:0], 6635);
        // UDP length = packet length + 8 + 
        //   UDP (8) + MPLS ()
        hdr.udp.length = payload_len + hdr.udp.minSizeInBytes();
        // Pkt length
        local_md.pkt_length = local_md.pkt_length + hdr.ipv6.minSizeInBytes() + hdr.udp.minSizeInBytes();

        hdr.ethernet.ether_type = 0x86dd;
        ip_type = SWITCH_IP_TYPE_IPV6;
    }

    action tunnel_encap_miss() {
        hdr.gw_bridged_md.gw_flags.mpls_encap_outer_miss = true;
    }

    @name(".mpls_encap_outer")
    table tunnel_encap_1 {
        key = {
            local_md.tunnel.encap_info_id : exact @name("encap_info_id");
        }

        actions = {
            @defaultonly tunnel_encap_miss;
            encap_ipv4_mpls;
            encap_ipv6_mpls;
        }

        const default_action = tunnel_encap_miss;
        size = MPLS_ACL_TABLE_SIZE;
    }

    @name(".mpls_rewrite_ipv4_src")
    action rewrite_ipv4_src(ipv4_addr_t src_addr) {
        hdr.ipv4.src_addr = src_addr;
    }

    @name(".mpls_rewrite_ipv6_src")
    action rewrite_ipv6_src(ipv6_addr_t src_addr) {
        hdr.ipv6.src_addr = src_addr;
    }

    @name(".mpls_src_addr_rewrite")
    table src_addr_rewrite {
        key = {
            ip_type : exact @name("ip_type");
        }

        actions = {
            @defaultonly tunnel_encap_miss;
            rewrite_ipv4_src;
            rewrite_ipv6_src;
        }

        const default_action = tunnel_encap_miss;
    }

    apply {
        tunnel_encap_0.apply();
        mpls_payload_len.apply();
        tunnel_encap_1.apply();
        src_addr_rewrite.apply();
    }
}
# 174 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/switch-tofino/largetable/table_business_acl.p4" 1
control BusinessACL(
    inout switch_local_metadata_t local_md,
    inout gw_bridged_metadata_h gw_bridged_hdr
) {

    action eip_miss() {
        gw_bridged_hdr.gw_flags.reverse_nat_miss = true;
    }

    @name(".set_ipv4_eip")
    action set_ipv4_eip(ipv4_addr_t src_addr) {
        local_md.lkp.ip_src_addr[95:64] = src_addr;
    }

    // docs: https://bytedance.feishu.cn/docx/U51fdU8Y0o4TywxBDk7cSsLun1x#TVGzdMCLbox2alxMlW6cpufnnIe
    @name(".ip_mapping")
    table ip_mapping {
        key = {
            gw_bridged_hdr.tunnel.ns_id : exact @name("ns_id");
            gw_bridged_hdr.tunnel.vni : exact @name("vni");
            local_md.lkp.ip_src_addr : exact @name("src_addr");
        }

        actions = {
            @defaultonly eip_miss;
            set_ipv4_eip;
        }

        const default_action = eip_miss;
        size = NS_ACL_TABLE_SIZE;
    }
    action ns_acl_miss() {
        gw_bridged_hdr.gw_flags.ns_acl_miss = true;
    }

    @name(".ns_set_acl_properties")
    action set_acl_properties(gw_rl_id_t rate_limit_id,
        gw_if_id_t ns_interface_id, gw_nf_id_t nf_id,
        gw_nat_id_t nat_id) {
        local_md.tunnel.ns_interface_id = ns_interface_id;
        local_md.tunnel.rate_limit_id = rate_limit_id;
        local_md.tunnel.nf_id = nf_id;
        local_md.tunnel.nat_id = nat_id;
        gw_bridged_hdr.gw_flags.ns_acl_miss = false;
    }

    @name(".ns_acl_sip")
    table ns_acl_sip {
        key = {
            // local_md.tunnel.ns_id : exact @name("ns_id");
            gw_bridged_hdr.tunnel.ns_id : exact @name("ns_id");
            local_md.lkp.ip_src_addr : exact @name("src_addr");
        }

        actions = {
            @defaultonly NoAction;
            set_acl_properties;
        }

        const default_action = NoAction;
        size = NS_ACL_TABLE_SIZE;
    }

    @name(".ns_acl_dip")
    table ns_acl_dip {
        key = {
            // local_md.tunnel.ns_id : exact @name("ns_id");
            gw_bridged_hdr.tunnel.ns_id : exact @name("ns_id");
            local_md.lkp.ip_dst_addr : exact @name("dst_addr");
        }

        actions = {
            @defaultonly ns_acl_miss;
            set_acl_properties;
        }

        const default_action = ns_acl_miss;
        size = NS_ACL_TABLE_SIZE;
    }

    action nf_miss() {
        gw_bridged_hdr.gw_flags.nf_miss = true;
    }

    @name(".nf_hit")
    action nf_hit(gw_if_id_t nf_interface_id) {
        local_md.tunnel.nf_interface_id = nf_interface_id;
    }

    @name(".nf_bypass")
    action nf_bypass() {
        local_md.tunnel.nf_interface_id = 0;
    }

    @name(".network_function")
    table nf {
        key = {
            local_md.tunnel.nf_id : exact @name("nf_id");
        }

        actions = {
            @defaultonly nf_miss;
            nf_hit;
            nf_bypass;
        }

        const default_action = nf_miss;
        size = NF_TABLE_SIZE;
    }

    action local_meter(gw_meter_id_t meter_id) {
        local_md.tunnel.meter_id = meter_id;
        local_md.tunnel.meter_interface_id = 0;
    }

    action redirect_meter(gw_if_id_t redirect_if_id) {
        local_md.tunnel.meter_id = 0;
        local_md.tunnel.meter_interface_id = redirect_if_id;
    }

    @name(".rate_limit")
    table rate_limit {
        key = {
            local_md.tunnel.rate_limit_id : exact @name("rate_limit_id");
        }

        actions = {
            local_meter;
            redirect_meter;
            @defaultonly NoAction;
        }

        const default_action = NoAction;
        size = NS_ACL_TABLE_SIZE * 2;
    }



    @name(".ns_to_backend")
    action to_backend(gw_bypass_t bypass) {
        gw_bridged_hdr.tunnel.ns_interface_id = local_md.tunnel.ns_interface_id;
        gw_bridged_hdr.tunnel.bypass = gw_bridged_hdr.tunnel.bypass | bypass;
    }

    @name(".ns_to_igw")
    action to_igw(gw_bypass_t bypass) {
        gw_bridged_hdr.tunnel.ns_interface_id = local_md.tunnel.meter_interface_id;
        gw_bridged_hdr.tunnel.bypass = gw_bridged_hdr.tunnel.bypass | bypass;
    }

    @name(".ns_to_nf")
    action to_nf(gw_bypass_t bypass) {
        gw_bridged_hdr.tunnel.ns_interface_id = local_md.tunnel.nf_interface_id;
        gw_bridged_hdr.tunnel.bypass = gw_bridged_hdr.tunnel.bypass | bypass;
    }

    // set bypass flag and final interface id
    @name(".oaa")
    table oaa {
        key = {
            gw_bridged_hdr.tunnel.terminate : ternary @name("terminate");
            gw_bridged_hdr.tunnel.interface_type : ternary @name("ns_interface_type");
            local_md.tunnel.meter_interface_id : ternary @name("meter_interface_id");
            local_md.tunnel.nf_interface_id : ternary @name("nf_interface_id");
        }

        actions = {
            @defaultonly NoAction;
            to_backend;
            to_igw;
            to_nf;
        }

        const default_action = NoAction;
        size = MIN_TABLE_SIZE;
    }

    apply {
        if (local_md.tunnel.interface_type == NS_INTERFACE_TYPE_BACKEND) {
            ip_mapping.apply();
        }
        if (!ns_acl_sip.apply().hit)
            ns_acl_dip.apply();
        nf.apply();
        rate_limit.apply();
        oaa.apply();
        gw_bridged_hdr.tunnel.nat_policy_id = local_md.tunnel.nat_id;
    }
}
# 175 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/switch-tofino/largetable/table_fpga.p4" 1



control FPGAHdrWrap(
    inout switch_local_metadata_t local_md,
    inout switch_header_t hdr
) {
    action to_fpga_construct_0()
    {
        hdr.to_fpga.setValid();
        hdr.to_fpga.ns_id = hdr.gw_bridged_md.tunnel.ns_id;
        hdr.to_fpga.vni = hdr.gw_bridged_md.tunnel.vni;
        hdr.to_fpga.orig_pkt_len = local_md.pkt_length;
        hdr.to_fpga.src_addr = local_md.lkp.ip_src_addr;
        hdr.to_fpga.dst_addr = local_md.lkp.ip_dst_addr;
        hdr.to_fpga.ecmp_hash = hdr.gw_bridged_md.tunnel.hash;
        hdr.to_fpga.interface_type = hdr.gw_bridged_md.tunnel.interface_type;
        hdr.to_fpga.reserved = 0;
    }

    action to_fpga_construct_1()
    {

    }

    action update_flow_trace()
    {
        hdr.flow_trace.next_hdr = 2;
    }
    apply {
        to_fpga_construct_0();
        if (hdr.ipv4.isValid())
        {
            hdr.to_fpga.next_hdr = 0;
        } else {
            hdr.to_fpga.next_hdr = 1;
        }
        update_flow_trace();
        hdr.to_fpga_padding.setValid();
    }
}

control FPGAHdrUnwrap(inout switch_local_metadata_t local_md,
    inout switch_header_t hdr
)
{
    action set_snat() {
        local_md.lkp.ip_src_addr = local_md.from_fpga_snat_ip;
    }

    action set_dnat() {
        local_md.lkp.ip_dst_addr = local_md.from_fpga_snat_ip;
    }

    table nat_unwrap {
        key = {
            local_md.from_fpga_nat_type : exact;
        }

        actions = {
            NoAction;
            set_snat;
            set_dnat;
        }
        const default_action = NoAction;
        const entries = {
            GW_NAT_TYPE_NONE : NoAction;
            GW_NAT_TYPE_SNAT : set_snat();
            GW_NAT_TYPE_DNAT : set_dnat();
        }
        size = MIN_TABLE_SIZE;
    }

    action construct_local_md_0()
    {
        local_md.tunnel.type[3:2] = 0;
        local_md.tunnel.type[1:0] = local_md.from_fpga_encap_type;
        local_md.tunnel.src_vtep = local_md.from_fpga_local_vtep;
        local_md.tunnel.dst_vtep = local_md.from_fpga_remote_vtep;
        local_md.tunnel.vni = local_md.from_fpga_vni;
    }
    apply {
        construct_local_md_0();
        if (local_md.from_fpga_next_hdr == 0)
            hdr.flow_trace.next_hdr = 0b00;
        else
            hdr.flow_trace.next_hdr = 0b01;
        nat_unwrap.apply();
        //hdr.from_fpga.setInvalid();
    }
}
# 176 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2
# 1 "../../p4c-5288/switch-tofino/largetable/service_pipe1.p4" 1
// @pa_container_size("egress", "local_md.tunnel.gw_flags", 8)

control TableServiceIngress(
        inout switch_header_t hdr,
        inout switch_local_metadata_t local_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    GwPktValidation() pkt_validation;
    GwFibv4(IPV4_HOST_TABLE_SIZE,
        IPV4_LPM_TABLE_SIZE,
        true,
        IPV4_LOCAL_HOST_TABLE_SIZE) ipv4_fib;
    GwFibv6(IPV6_HOST_TABLE_SIZE, 64, IPV6_LPM_TABLE_SIZE, IPV6_LPM64_TABLE_SIZE) ipv6_fib;
    GwNexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
    GwLAG() lag;
    GwIngressSystemAcl() system_acl;

    action set_ucast_port(bit<9> port) {
        ig_intr_md_for_tm.ucast_egress_port = port;
    }

    table debug_fib {
        key = {
            local_md.lkp.ip_dst_addr : exact;
        }
        actions = {
            NoAction;
            set_ucast_port;
        }
        default_action = NoAction;
        size = MIN_TABLE_SIZE;
    }

    apply {
        if (local_md.drop_reason == 0x00) {
            pkt_validation.apply(hdr, local_md.lkp);
            if (local_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                ipv4_fib.apply(local_md);
            } else if (local_md.lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
                ipv6_fib.apply(local_md);
            }
            if (!local_md.flags.routed) {
                local_md.drop_reason = GW_DROP_REASON_FIB_MISS;
            }
            nexthop.apply(local_md);
            lag.apply(local_md, local_md.lag_hash, ig_intr_md_for_tm.ucast_egress_port);
        }

        system_acl.apply(hdr, local_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
        rewrite_bridged_md(hdr.bridged_md, local_md);
        set_ig_intr_md(local_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);//fast set for debug
        debug_fib.apply();
    }
}

// @pa_solitary("egress", "local_md.tunnel.gw_flags")
control TableServiceEgress(
        inout switch_header_t hdr,
        inout switch_local_metadata_t local_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    GwPktValidation() gw_pkt_validation;
    MplsTunnelEncap() mpls_tunnel_encap;
    bit<8> tos;

    action rewrite_flow_trace_v4() {
        hdr.flow_trace.next_hdr = 0;
    }

    action rewrite_flow_trace_v6() {
        hdr.flow_trace.next_hdr = 1;
    }

    table flow_trace_rewrite {
        key = {
            hdr.flow_trace.isValid() : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }
        actions = {
            rewrite_flow_trace_v4;
            rewrite_flow_trace_v6;
            NoAction;
        }
        const default_action = NoAction;
        const entries = {
            (true, true, false, true, false) : rewrite_flow_trace_v4();
            (true, true, false, false, true) : rewrite_flow_trace_v4();
            (true, false, true, true, false) : rewrite_flow_trace_v6();
            (true, false, true, false, true) : rewrite_flow_trace_v6();
            (true, false, false, true, false) : rewrite_flow_trace_v4();
            (true, false, false, false, true) : rewrite_flow_trace_v6();
        }
    }

    action gw_bypass_meter() {
        local_md.bypass = local_md.bypass | GW_EGRESS_BYPASS_METER;
    }

    //table gw_bypass_match {
    //    key = {
    //        local_md.tunnel.hit_in_fpga: exact;
    //    }
//
    //    actions = {
    //        gw_bypass_meter;
    //        NoAction;
    //    }
    //    const default_action = NoAction;
    //    const entries = {
    //        (true) : gw_bypass_meter();
    //    }
    //    size = 2;
    //}

    //action set_local_metadata_from_bridged_md(){
    //    local_md.tunnel.terminate = hdr.bridged_md.table_result.terminate;
    //    local_md.tunnel.hash = hdr.bridged_md.table_result.hash;
    //    //local_md.nic.tofino_to_nic = hdr.bridged_md.nic.tofino_to_nic;
    //    local_md.tunnel.gw_pkt_flags.eip_net_hit = hdr.bridged_md.table_result.eip_net_hit;
    //    local_md.tunnel.gw_pkt_flags.eip_info_miss = hdr.bridged_md.table_result.eip_info_miss;
    //    local_md.tunnel.gw_pkt_flags.vni_type = hdr.bridged_md.table_result.vni_type;
    //    //local_md.tunnel.gw_pkt_type = hdr.bridged_md.table_result.gw_pkt_type;
    //}
//
    //action set_local_metadata_from_inner_bridged_md_0(){
    //    local_md.tunnel.vm_vtep = hdr.inner_bridged_md.fpga_result.outer_ip;
    //    local_md.tunnel.eip = hdr.inner_bridged_md.fpga_result.inner_ip;
    //    local_md.tunnel.private_ip = hdr.inner_bridged_md.fpga_result.inner_ip;
    //    local_md.tunnel.eid = hdr.inner_bridged_md.fpga_result.eid;
    //    local_md.tunnel.meter_id = hdr.inner_bridged_md.fpga_result.meter_id;
    //    // local_md.tunnel.vni = hdr.inner_bridged_md.fpga_result.vni;
    //    local_md.tunnel.vpc_vni = hdr.inner_bridged_md.fpga_result.vni;
//
    //    local_md.tunnel.gw_pkt_flags.eip_zone = hdr.inner_bridged_md.fpga_result.eip_zone;
    //    local_md.tunnel.gw_pkt_flags.bwp_zone = hdr.inner_bridged_md.fpga_result.bwp_zone;
    //    local_md.tunnel.gw_pkt_flags.igw_node = hdr.inner_bridged_md.fpga_result.igw_node;
//
    //    local_md.tunnel.gw_pkt_flags.to_igw = hdr.inner_bridged_md.fpga_result.flags.to_igw;
    //    local_md.tunnel.gw_pkt_flags.to_fw = hdr.inner_bridged_md.fpga_result.flags.to_fw;
    //    local_md.tunnel.gw_pkt_flags.to_lb = hdr.inner_bridged_md.fpga_result.flags.to_lb;
    //    local_md.tunnel.vm_vtep_type = hdr.inner_bridged_md.fpga_result.flags.outer_ip_type;
    //    local_md.tunnel.inner_ip_type = hdr.inner_bridged_md.fpga_result.flags.inner_ip_type;
    //}
//
    //action set_local_metadata_from_inner_bridged_md_1(){
    //        local_md.tunnel.hit_in_fpga = hdr.bridged_md.flags.hit_in_fpga;
    //}
//
    //action add_bridged_md_0() {
    //    hdr.bridged_md.setValid();
    //    hdr.bridged_md.table_result.drop_flags.encap_to_fw_miss = local_md.tunnel.gw_flags.encap_to_fw_miss;
    //    hdr.bridged_md.table_result.drop_flags.encap_to_eni_miss = local_md.tunnel.gw_flags.encap_to_eni_miss;
    //}
//
    //action add_bridged_md_1() {
    //    hdr.bridged_md.table_result.drop_flags.encap_to_igw_miss = local_md.tunnel.gw_flags.encap_to_igw_miss;
    //    hdr.bridged_md.table_result.drop_flags.gw_pkt_type = local_md.tunnel.gw_pkt_type;
    //}

    @name(".set_mpls_properties")
    action set_mpls_properties(bit<24> mpls_acl_rule_id, bit<24> encap_info_id) {
        local_md.tunnel.mpls_acl_rule_id = mpls_acl_rule_id;
        local_md.tunnel.encap_info_id = encap_info_id;
    }

    @name(".mpls_acl")
    table mpls_acl {
        key = {
            // local_md.tunnel.ns_id : exact @name("ns_id");
            local_md.lkp.ip_dst_addr : ternary @name("dst_addr");
            local_md.lkp.ip_src_addr : ternary @name("src_addr");
            local_md.lkp.ip_tos : ternary @name("tos");
        }

        actions = {
            @defaultonly NoAction;
            set_mpls_properties;
        }

        const default_action = NoAction;
        size = MPLS_ACL_TABLE_SIZE;
    }

    @name(".mpls_encap_1_label")
    action mpls_encap_1_label(bit<20> label0) {
        local_md.tunnel.mpls_push_count = 1;
        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.mpls[0].bos = 1;
        hdr.mpls[0].label = label0;
        hdr.mpls[0].ttl = DEFAULT_MPLS_TTL;
        hdr.ethernet.ether_type = 0x8847;
        local_md.pkt_length = local_md.pkt_length + hdr.mpls[0].minSizeInBytes();
    }
    @name(".mpls_encap_2_label")
    action mpls_encap_2_label(bit<20> label0, bit<20> label1) {
        local_md.tunnel.mpls_push_count = 2;
        hdr.mpls.push_front(2);
        hdr.mpls[0].setValid();
        hdr.mpls[1].setValid();
        hdr.mpls[0].bos = 0;
        hdr.mpls[1].bos = 1;
        hdr.mpls[0].label = label0;
        hdr.mpls[1].label = label1;
        hdr.mpls[0].ttl = DEFAULT_MPLS_TTL;
        hdr.mpls[1].ttl = DEFAULT_MPLS_TTL;
        hdr.ethernet.ether_type = 0x8847;
        local_md.pkt_length = local_md.pkt_length + hdr.mpls[0].minSizeInBytes() +
          hdr.mpls[1].minSizeInBytes();
    }
    @name(".mpls_encap_3_label")
    action mpls_encap_3_label(bit<20> label0, bit<20> label1, bit<20> label2) {
        local_md.tunnel.mpls_push_count = 3;
        hdr.mpls.push_front(3);
        hdr.mpls[0].setValid();
        hdr.mpls[1].setValid();
        hdr.mpls[2].setValid();
        hdr.mpls[0].bos = 0;
        hdr.mpls[1].bos = 0;
        hdr.mpls[2].bos = 1;
        hdr.mpls[0].label = label0;
        hdr.mpls[1].label = label1;
        hdr.mpls[2].label = label2;
        hdr.mpls[0].ttl = DEFAULT_MPLS_TTL;
        hdr.mpls[1].ttl = DEFAULT_MPLS_TTL;
        hdr.mpls[2].ttl = DEFAULT_MPLS_TTL;
        hdr.ethernet.ether_type = 0x8847;
        local_md.pkt_length = local_md.pkt_length + hdr.mpls[0].minSizeInBytes() +
          hdr.mpls[1].minSizeInBytes() + hdr.mpls[2].minSizeInBytes();
    }

    @name(".mpls_encap_label")
    table mpls_encap_label {
        key = {
            local_md.tunnel.encap_info_id : exact @name("encap_info_id");
        }

        actions = {
            @defaultonly NoAction;
            mpls_encap_1_label;
            mpls_encap_2_label;
            mpls_encap_3_label;
        }

        const default_action = NoAction;
        size = MPLS_ACL_TABLE_SIZE;
    }

    @name(".mpls_exp_1")
    action mpls_exp_1(bit<3> exp) {
        hdr.mpls[0].exp = exp;
    }

    @name(".mpls_exp_2")
    action mpls_exp_2(bit<3> exp) {
        hdr.mpls[0].exp = exp;
        hdr.mpls[1].exp = exp;
    }

    @name(".mpls_exp_3")
    action mpls_exp_3(bit<3> exp) {
        hdr.mpls[0].exp = exp;
        hdr.mpls[1].exp = exp;
        hdr.mpls[2].exp = exp;
    }

    @name(".mpls_exp_rewrite")
    table mpls_exp_rewrite {
        key = {
            local_md.tunnel.mpls_push_count : exact @name("mpls_push_count");
            local_md.lkp.ip_tos : exact @name("tos");
        }

        actions = {
            @defaultonly NoAction;
            mpls_exp_1;
            mpls_exp_2;
            mpls_exp_3;
        }

        const default_action = NoAction;
        size = MIN_TABLE_SIZE;
    }

    apply {
        if(local_md.nic.tofino_to_nic == 1) {
            //by pass
        }
        else {
            //set_local_metadata_from_bridged_md();
            //set_local_metadata_from_inner_bridged_md_0();
            //set_local_metadata_from_inner_bridged_md_1();
            //gw_bypass_match.apply();
            gw_pkt_validation.apply(hdr, local_md.lkp);
            mpls_acl.apply();
            //mpls_acl_stats.apply(hdr, local_md);
            mpls_encap_label.apply();
            mpls_exp_rewrite.apply();

            if (local_md.tunnel.encap_info_id != 0) {
                mpls_tunnel_encap.apply(hdr, local_md);
            }
            //add_bridged_md_0();
            //add_bridged_md_1();

            flow_trace_rewrite.apply();

            // system_acl.apply(hdr, local_md, eg_intr_md_for_dprsr);
        }
    }
}
# 177 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2

# 1 "../../p4c-5288/switch-tofino/largetable/table_pipe23.p4" 1
// To avoid the compiler puts these two fields in a same phv
@pa_no_overlay("ingress", "hdr.table_1_result.vni")
@pa_no_overlay("ingress", "hdr.table_2_key.vni")

@pa_no_overlay("egress", "hdr.bridged_md.base.tc", "hdr.bridged_md.base.vrf")

// @pa_no_overlay("ingress", "hdr.table_1_key.pad", "hdr.bridged_md.base")
// @pa_no_overlay("ingress", "hdr.table_1_key.eip", "hdr.bridged_md.base")
// @pa_no_overlay("ingress", "hdr.table_2_key.vm_ip", "hdr.bridged_md.base")
// @pa_no_overlay("ingress", "hdr.table_2_key.vni", "hdr.bridged_md")

// @pa_no_overlay("ingress", "hdr.inner_ipv4.dst_addr","hdr.table_1_key")
// @pa_no_overlay("ingress", "hdr.inner_ipv6.dst_addr","hdr.table_1_key")
// @pa_no_overlay("ingress", "hdr.inner_ipv4.src_addr","hdr.table_1_key")
// @pa_no_overlay("ingress", "hdr.inner_ipv6.src_addr","hdr.table_1_key")

// @pa_no_overlay("ingress", "hdr.inner_ipv4.dst_addr","hdr.table_2_key")
// @pa_no_overlay("ingress", "hdr.inner_ipv6.dst_addr","hdr.table_2_key")
// @pa_no_overlay("ingress", "hdr.inner_ipv4.src_addr","hdr.table_2_key")
// @pa_no_overlay("ingress", "hdr.inner_ipv6.src_addr","hdr.table_2_key")

// @pa_no_overlay("ingress", "hdr.bridged_md.base","hdr.table_1_key.pad")
// @pa_no_overlay("ingress", "hdr.bridged_md.base","hdr.table_1_key.eip")
// @pa_no_overlay("ingress", "hdr.bridged_md.base","hdr.table_2_key.vm_ip")
// @pa_no_overlay("ingress", "hdr.bridged_md.base","hdr.table_2_key.vni")


// @pa_no_overlay("ingress", "hdr.table_2_key.vm_ip", "hdr.inner_ipv4.dst_addr")
// @pa_no_overlay("ingress", "hdr.table_2_key.vm_ip", "hdr.inner_ipv6.dst_addr")

// @pa_mutually_exclusive("ingress", "hdr.bridged_md.table_result.hash","hdr.table_1_result,outer_ip")
// @pa_mutually_exclusive("ingress", "hdr.bridged_md.table_result.hash","hdr.table_2_result,outer_ip")

control TableIngress(
        inout switch_header_t hdr,
        inout switch_local_metadata_t local_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    // PktValidation() pkt_validation;//to check

    TunnelEncap() tunnel_encap;
    FromNic() from_nic;
    //FPGABridgeMdConstruct() fpga_bridged_md_construct;
    CPUBridgeMdConstruct() cpu_bridged_md_construct;
    FPGAHdrUnwrap() fpga_hdr_unwrap;
    GwPktValidation() gw_pkt_validation;

    bit<9> origin_port_lower = ig_intr_md.ingress_port & 0x7f;
    bit<9> pipe1_port_higher = 0b010000000;
    bool from_fpga = false;

    action rewrite_next_pipe_nic(bit<9> port_num) {
        ig_intr_md_for_tm.ucast_egress_port = pipe1_port_higher + port_num;
    }

    table nic_to_pipe1 {
        key = {
            local_md.hash[3:0] : exact;
        }
        actions = {
            rewrite_next_pipe_nic;
        }
        const entries= {
            0b0000 : rewrite_next_pipe_nic(0b000000000);
            0b0001 : rewrite_next_pipe_nic(0b000000100);
            0b0010 : rewrite_next_pipe_nic(0b000001000);
            0b0011 : rewrite_next_pipe_nic(0b000001100);
            0b0100 : rewrite_next_pipe_nic(0b000010000);
            0b0101 : rewrite_next_pipe_nic(0b000010100);
            0b0110 : rewrite_next_pipe_nic(0b000011000);
            0b0111 : rewrite_next_pipe_nic(0b000011100);
            0b1000 : rewrite_next_pipe_nic(0b000100000);
            0b1001 : rewrite_next_pipe_nic(0b000100100);
            0b1010 : rewrite_next_pipe_nic(0b000101000);
            0b1011 : rewrite_next_pipe_nic(0b000101100);
            0b1100 : rewrite_next_pipe_nic(0b000110000);
            0b1101 : rewrite_next_pipe_nic(0b000110100);
            0b1110 : rewrite_next_pipe_nic(0b000111000);
            0b1111 : rewrite_next_pipe_nic(0b000111100);
        }
        size = 16;
    }

    action hit_fpga_port() {
        from_fpga = true;
    }

    table fpga_port_map {
        key = {
            ig_intr_md.ingress_port : exact;
        }
        actions = {
            hit_fpga_port;
        }
        size = MIN_TABLE_SIZE;
    }

    action redirect_fpga_to_pipe1_port(PortId_t port) {
        ig_intr_md_for_tm.ucast_egress_port = port;
        hdr.gw_bridged_md.setInvalid();
    }

    table redirect_fpga_to_pipe1 {
        key = {
            local_md.ingress_port : exact;
        }
        actions = {
            redirect_fpga_to_pipe1_port;
        }
        size = MIN_TABLE_SIZE;
    }

    action unwrap_gw_bridged_md() {
        //local_md.hash = hdr.bridged_md.table_result.hash;
        //local_md.tunnel.encap = hdr.bridged_md.table_result.encap;
        //local_md.tunnel.terminate = hdr.bridged_md.table_result.terminate;
        //local_md.tunnel.eip_net_hit = hdr.bridged_md.table_result.eip_net_hit;
        //local_md.tunnel.vni_type = hdr.bridged_md.table_result.vni_type;
        //local_md.tunnel.gw_pkt_type = hdr.bridged_md.table_result.gw_pkt_type;
        local_md.nic.tofino_to_nic = hdr.bridged_md.nic.tofino_to_nic;
        local_md.tunnel.nat_id = hdr.gw_bridged_md.tunnel.nat_policy_id;
        local_md.tunnel.ns_interface_id = hdr.gw_bridged_md.tunnel.ns_interface_id;
        local_md.tunnel.ns_id = hdr.gw_bridged_md.tunnel.ns_id;
        // Used to determine VXLAN port
        local_md.tunnel.hash = hdr.gw_bridged_md.tunnel.hash[15:0];
    }

    action set_compress_ip_metadata() {
        // local_md.hash = hdr.compress_bridged_md.compress.hash;
        // local_md.tunnel.encap = hdr.compress_bridged_md.compress.encap;
        // local_md.tunnel.terminate = hdr.compress_bridged_md.compress.terminate;
        // local_md.tunnel.gw_pkt_type = hdr.compress_bridged_md.compress.gw_pkt_type;
        local_md.nic.tofino_to_nic = hdr.compress_bridged_md.compress.tofino_to_nic;
        // local_md.flags.services = hdr.compress_bridged_md.compress.services; 
    }

    table set_local_metadata {
        key = {
            hdr.flow_trace.next_hdr : exact;
            hdr.flow_trace.isValid() : exact;
        }
        actions = {
            unwrap_gw_bridged_md;
            set_compress_ip_metadata;
            NoAction;
        }
        const default_action = NoAction;
        const entries = {
            (0, true) : unwrap_gw_bridged_md();
            (1, true) : unwrap_gw_bridged_md();
            (2, true) : set_compress_ip_metadata();
            (3, true) : set_compress_ip_metadata();
        }
        size = MIN_TABLE_SIZE;
    }

    action add_bridged_md() {
        hdr.bridged_md.setValid();
        hdr.bridged_md.src = hdr.compress_bridged_md.compress.src;
        hdr.bridged_md.type = hdr.compress_bridged_md.compress.type;

        hdr.bridged_md.base.pkt_type = hdr.compress_bridged_md.compress.pkt_type;
        hdr.bridged_md.base.tc = hdr.compress_bridged_md.compress.tc;
        hdr.bridged_md.base.qid = hdr.compress_bridged_md.compress.qid;
        hdr.bridged_md.base.vrf = hdr.compress_bridged_md.compress.vrf;
        hdr.bridged_md.base.routed = true;
        hdr.bridged_md.base.bypass_egress = false;

        hdr.bridged_md.acl.l4_src_port = hdr.compress_bridged_md.compress.l4_src_port;
        hdr.bridged_md.acl.l4_dst_port = hdr.compress_bridged_md.compress.l4_dst_port;
        hdr.bridged_md.acl.tcp_flags = hdr.compress_bridged_md.compress.tcp_flags;

        //hdr.bridged_md.table_result.terminate = hdr.compress_bridged_md.compress.terminate;
        //hdr.bridged_md.table_result.encap = hdr.compress_bridged_md.compress.encap;
        //hdr.bridged_md.table_result.vni_type = hdr.compress_bridged_md.compress.vni_type;
        //hdr.bridged_md.table_result.eip_net_hit = hdr.compress_bridged_md.compress.eip_net_hit;

        hdr.bridged_md.nic.tofino_to_nic = hdr.compress_bridged_md.compress.tofino_to_nic;
    }

    action set_ns_interface_vtep(switch_tunnel_type_t tunnel_type,
                                ipv6_addr_t src_vtep, ipv6_addr_t dst_vtep,
                                switch_tunnel_vni_t vni
                                )
    {
        local_md.tunnel.vni = vni;
        local_md.tunnel.type = tunnel_type;
        local_md.tunnel.src_vtep = src_vtep;
        local_md.tunnel.dst_vtep = dst_vtep;
    }

    @name(".ns_interface")
    table ns_interface {
        key = {
            local_md.tunnel.ns_interface_id : exact @name("interface_id");
        }

        actions = {
            @defaultonly NoAction;
            set_ns_interface_vtep;
        }

        const default_action = NoAction;
        size = NS_ACL_TABLE_SIZE * 2;
    }

    action nat_miss() {
    }

    @name(".rewrite_ipv4_dip")
    action rewrite_ipv4_dip(ipv4_addr_t dst_addr) {
        local_md.lkp.ip_dst_addr[95:64] = dst_addr;
    }

    @name(".rewrite_ipv4_sip")
    action rewrite_ipv4_sip(ipv4_addr_t src_addr) {
        local_md.lkp.ip_src_addr[95:64] = src_addr;
    }


    @name(".nat")
    table nat {
        key = {
            local_md.tunnel.nat_id : exact @name("nat_policy_id");
        }

        actions = {
            @defaultonly nat_miss;
            rewrite_ipv4_dip;
            rewrite_ipv4_sip;
        }

        const default_action = nat_miss;
        size = NS_ACL_TABLE_SIZE * 2;
    }

    action redirect_pipe23_lo_to_fpga_port(PortId_t port) {
        ig_intr_md_for_tm.ucast_egress_port = port;
    }

    table redirect_pipe23_lo_to_fpga {
        key = {
            local_md.ingress_port : exact;
        }
        actions = {
            redirect_pipe23_lo_to_fpga_port();
        }
    }

    action rewrite_ipv4_addrs()
    {
        hdr.ipv4.src_addr = local_md.lkp.ip_src_addr[95:64];
        hdr.ipv4.dst_addr = local_md.lkp.ip_dst_addr[95:64];
    }

    action rewrite_ipv6_addrs()
    {
        hdr.ipv6.src_addr = local_md.lkp.ip_src_addr;
        hdr.ipv6.dst_addr = local_md.lkp.ip_dst_addr;
    }

    table rewrite_ip_addr {
        key = {
            local_md.lkp.ip_type : exact;
        }
        actions = {
            rewrite_ipv4_addrs();
            rewrite_ipv6_addrs();
            NoAction;
        }
        size = MIN_TABLE_SIZE;
        const default_action = NoAction;
        const entries = {
            SWITCH_IP_TYPE_IPV4: rewrite_ipv4_addrs();
            SWITCH_IP_TYPE_IPV6: rewrite_ipv6_addrs();
        }
    }

    apply {
        //set_local_metadata.apply();
        // For packets for BGP etc. from CPU
        if (local_md.ingress_port==320) {
            ig_intr_md_for_tm.ucast_egress_port = 64;
            //add bridge type
            hdr.bridged_md.setValid();
            hdr.bridged_md.src = SWITCH_CPU_BRIDGED;
        }
        // For packets from 100G e810 NIC
        else if(( (local_md.ingress_port==260) || (local_md.ingress_port==416) )) {
            set_compress_ip_metadata();
            cpu_bridged_md_construct.apply(hdr, local_md);
            //add_bridged_md();
            hdr.hash_bridged_md.setInvalid();
            hdr.compress_bridged_md.setInvalid();
            if (local_md.nic.tofino_to_nic == 1) {
                nic_to_pipe1.apply();
                from_nic.apply(hdr, local_md, ig_intr_md_for_tm);
            }
        }
        else {
            gw_pkt_validation.apply(hdr, local_md.lkp);
            //For packets just come from switch pipe
            if (!fpga_port_map.apply().hit) {
                unwrap_gw_bridged_md();
                if (hdr.gw_bridged_md.tunnel.ns_interface_id != 0) {
                    ns_interface.apply();
                }
                if (local_md.tunnel.nat_id != 0 && !(hdr.gw_bridged_md.tunnel.bypass & GW_BYPASS_NAT != 0)) {
                    nat.apply();
                }
            }
            //For the result just come from FPGA
            else {
                //set_compress_ip_metadata();
                //fpga_bridged_md_construct.apply(hdr, local_md); 
                //hdr.hash_bridged_md.setInvalid();
                //hdr.compress_bridged_md.setInvalid(); 
                fpga_hdr_unwrap.apply(local_md, hdr);
            }

            //Check if we previously missed the ACL, if so, go to FPGA
            if (!from_fpga &&
                hdr.gw_bridged_md.gw_flags.ns_acl_miss &&
                (hdr.gw_bridged_md.tunnel.terminate || hdr.gw_bridged_md.gw_flags.net_type))
            {
                hdr.gw_bridged_md.gw_flags.to_fpga = true;
                redirect_pipe23_lo_to_fpga.apply();
                exit;
            }

            // since we are gonna encap, we check whether udp has checksum
            if (hdr.inner_udp.isValid() && hdr.inner_udp.checksum != 0) {
                local_md.checksum_upd_udp = true;
            }
            rewrite_ip_addr.apply();
            if (local_md.tunnel.type != SWITCH_EGRESS_TUNNEL_TYPE_NONE) {
                tunnel_encap.apply(hdr, local_md);
            } else {
                hdr.gw_bridged_md.tunnel.interface_type = NS_INTERFACE_TYPE_UNDERLAY;
            }
            redirect_fpga_to_pipe1.apply();
        }
    }
}

control TableEgress(
        inout switch_header_t hdr,
        inout switch_local_metadata_t local_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    BusinessACL() business_acl;
    GwPktValidation() gw_pkt_validation;
    FPGAHdrWrap() fpga_hdr_wrap;
    action hit_fpga_port() {}

    table fpga_port_map {
        key = {
            eg_intr_md.egress_port : exact;
        }
        actions = {
            hit_fpga_port;
        }
        size = MIN_TABLE_SIZE;
    }

    action add_compress_bridged_md() {
        hdr.compress_bridged_md.compress.src = hdr.bridged_md.src;
        hdr.compress_bridged_md.compress.type = hdr.bridged_md.type;

        hdr.compress_bridged_md.compress.l4_src_port = hdr.bridged_md.acl.l4_src_port;
        hdr.compress_bridged_md.compress.l4_dst_port = hdr.bridged_md.acl.l4_dst_port;
        hdr.compress_bridged_md.compress.tcp_flags = hdr.bridged_md.acl.tcp_flags;

        hdr.compress_bridged_md.compress.vrf = hdr.bridged_md.base.vrf;
        hdr.compress_bridged_md.compress.tc = hdr.bridged_md.base.tc;

        hdr.compress_bridged_md.compress.pkt_type = hdr.bridged_md.base.pkt_type;
        // hdr.compress_bridged_md.compress.qid = hdr.bridged_md.base.qid;

        hdr.compress_bridged_md.compress.tofino_to_nic = hdr.bridged_md.nic.tofino_to_nic;
        //hdr.compress_bridged_md.compress.terminate = hdr.bridged_md.table_result.terminate;
        //hdr.compress_bridged_md.compress.encap = hdr.bridged_md.table_result.encap;
        //hdr.compress_bridged_md.compress.vni_type = hdr.bridged_md.table_result.vni_type;
        //hdr.compress_bridged_md.compress.eip_net_hit = hdr.bridged_md.table_result.eip_net_hit;
    }

    action add_compress_bridged_md2() {
        hdr.compress_bridged_md.compress.qid = hdr.bridged_md.base.qid;
    }

    @name(".ns_to_backend")
    action to_backend(gw_bypass_t bypass) {
        hdr.gw_bridged_md.tunnel.ns_interface_id = local_md.tunnel.ns_interface_id;
        hdr.gw_bridged_md.tunnel.bypass = bypass;
    }

    @name(".ns_to_igw")
    action to_igw(gw_bypass_t bypass) {
        hdr.gw_bridged_md.tunnel.ns_interface_id = local_md.tunnel.meter_interface_id;
        hdr.gw_bridged_md.tunnel.bypass = bypass;
    }

    apply {
        if (local_md.egress_port==320) {
            //by pass to cpu pcie
        }
        else if(( (local_md.egress_port==260) || (local_md.egress_port==416) )) {
            hdr.compress_bridged_md.setValid();
            hdr.hash_bridged_md.setValid();
            //fpga_hash_copy_bridged_md(hdr.hash_bridged_md,hdr.bridged_md);
            //add_compress_bridged_md();
            //add_compress_bridged_md2();

            hdr.bridged_md.setInvalid();
        }
        else {
            gw_pkt_validation.apply(hdr, local_md.lkp);
            if (fpga_port_map.apply().hit) {
                //hdr.compress_bridged_md.setValid();
                //hdr.hash_bridged_md.setValid();
                //fpga_hash_copy_bridged_md(hdr.hash_bridged_md,hdr.bridged_md);
                //add_compress_bridged_md();
                //add_compress_bridged_md2();
                //hdr.bridged_md.setInvalid();
                //to fpga packet egress process
                //fpga meta has encaped in TableIngress
                fpga_hdr_wrap.apply(local_md, hdr);
            }
            else {
                business_acl.apply(local_md, hdr.gw_bridged_md);
            }
        }
    }
}
# 179 "../../p4c-5288/switch-tofino/switch_tofino_xlt.p4" 2

@pa_solitary("ingress", "bridged_md.nic.tofino_to_nic")

control SwitchIngress(
        inout switch_header_t hdr,
        inout switch_local_metadata_t local_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    bit<9> origin_port_lower = ig_intr_md.ingress_port & 0x7f;

    IngressPortMapping(PORT_VLAN_TABLE_SIZE, BD_TABLE_SIZE) ingress_port_mapping;
    PktValidation() pkt_validation;
    SMAC(MAC_TABLE_SIZE) smac;
    DMAC(MAC_TABLE_SIZE) dmac;
    IngressSflow() sflow;
    IngressBd(BD_TABLE_SIZE) bd_stats;
    EnableFragHash() enable_frag_hash;
    Ipv4Hash() ipv4_hash;
    Ipv6Hash() ipv6_hash;
    NonIpHash() non_ip_hash;
    Lagv4Hash() lagv4_hash;
    Lagv6Hash() lagv6_hash;
    LOU() lou;
    Fibv4(IPV4_HOST_TABLE_SIZE,
        IPV4_LPM_TABLE_SIZE,
        true,
        IPV4_LOCAL_HOST_TABLE_SIZE) ipv4_fib;
    Fibv6(IPV6_HOST_TABLE_SIZE, 64, IPV6_LPM_TABLE_SIZE, IPV6_LPM64_TABLE_SIZE) ipv6_fib;
    //PreIngressAcl(PRE_INGRESS_ACL_TABLE_SIZE) pre_ingress_acl;
    //IngressIpv4Acl(INGRESS_IPV4_ACL_TABLE_SIZE) ingress_ipv4_acl;
    //IngressIpv6Acl(INGRESS_IPV6_ACL_TABLE_SIZE) ingress_ipv6_acl;
    IngressIpAcl(INGRESS_IP_MIRROR_ACL_TABLE_SIZE) ingress_ip_mirror_acl;
    //IngressIpDtelSampleAcl(INGRESS_IP_DTEL_ACL_TABLE_SIZE) ingress_ip_dtel_acl;
    ECNAcl() ecn_acl;
    IngressPFCWd(512) pfc_wd;
    IngressQoSMap() qos_map;
    IngressTC() traffic_class;
    PPGStats() ppg_stats;
    StormControl() storm_control;
    Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
    LAG() lag;
    MulticastFlooding(BD_FLOOD_TABLE_SIZE) flood;
    IngressSystemAcl() system_acl;
    //IngressDtel() dtel;
    SameMacCheck() same_mac_check;

    GwIngressTunnel() tunnel;
    TunnelDecap() tunnel_decap;
    //GwIngressToNic() to_nic;

    action redirect_pipe0_to_pipe23_lo_port(PortId_t port) {
        ig_intr_md_for_tm.ucast_egress_port = port;
    }

    table redirect_pipe0_to_pipe23_lo {
        key = {
            local_md.ingress_port : exact;
        }
        actions = {
            redirect_pipe0_to_pipe23_lo_port;
        }
        size = MIN_TABLE_SIZE;
    }

    action redirect_to_0_cpu() {
        ig_intr_md_for_tm.ucast_egress_port = 0x104;
    }

    action redirect_to_1_cpu() {
        ig_intr_md_for_tm.ucast_egress_port = 0x1a0;
    }

    table redirect_to_service_cpu {
        key = {
            local_md.ingress_port[5:5] : exact @name("port_range");
        }
        actions = {
            redirect_to_0_cpu();
            redirect_to_1_cpu();
        }
    }

    action rewrite_flow_trace(bit<2> next_hdr) {
        hdr.ethernet.ether_type = 0x88B5;
        hdr.flow_trace.setValid();
        hdr.flow_trace.next_hdr = next_hdr;
        hdr.flow_trace.ingress_port = local_md.ingress_port;
    }

    table adjust_flow_trace {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            NoAction;
            rewrite_flow_trace;
        }
        const entries = {
            (true, false) : rewrite_flow_trace(0b00);
            (false, true) : rewrite_flow_trace(0b01);
        }
        default_action = NoAction;
        size = MIN_TABLE_SIZE;
    }

    apply {
        /*
        For XLT Device, the PCIe CPU port is at 320, which is not at switch pipe
        We need to redirect the packet to the pipe port 320 belongs to.
        To CPU: pipe0 egress -> pipe0 ingress -> pipe2 egress
        From CPU: pipe2 ingress -> pipe0 egress -> pipe0 ingress
        */
        // CPU Packets just looped back from 64 now goes to pipe2
        if (hdr.loop_flag.isValid() && hdr.loop_flag.flags == 1 &&
            local_md.ingress_port==64){
            hdr.loop_flag.setInvalid();
            ig_intr_md_for_tm.ucast_egress_port = 320;
        }
        else{
            //Incoming PCIe packets from CPU now looped back from 320
            if (hdr.loop_flag.isValid() && hdr.loop_flag.flags == 2 &&
                local_md.ingress_port==64){
                hdr.loop_flag.setInvalid();
            }
            pkt_validation.apply(hdr, local_md);
            ingress_port_mapping.apply(hdr, local_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
            //pre_ingress_acl.apply(hdr, local_md);
            lou.apply(local_md);
            enable_frag_hash.apply(local_md.lkp);
            tunnel.apply(hdr, local_md, local_md.lkp, ig_intr_md_for_dprsr);
            //to_nic.apply(hdr, local_md, local_md.lkp, ig_intr_md_for_tm);
            adjust_flow_trace.apply();
            smac.apply(hdr.ethernet.src_addr, local_md, ig_intr_md_for_dprsr.digest_type);
            bd_stats.apply(local_md.bd, local_md.lkp.pkt_type);
            same_mac_check.apply(hdr, local_md);

            if (local_md.flags.rmac_hit) {
                // Set bypass(L3) in tunnel
                if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_L3 != 0) && local_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4 && local_md.ipv4.unicast_enable) {
                    ipv4_fib.apply(local_md);
                    //ingress_ipv4_acl.apply(local_md, local_md.nexthop);
                    // this is a workaround to always make v6_acl the default next table for v4_acl
                    //if (local_md.lkp.ip_type != SWITCH_IP_TYPE_IPV4) {
                    //    ingress_ipv6_acl.apply(local_md, local_md.nexthop);
                    //}
                } else if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_L3 != 0) && local_md.lkp.ip_type == SWITCH_IP_TYPE_IPV6 && local_md.ipv6.unicast_enable) {
                    ipv6_fib.apply(local_md);
                    //ingress_ipv6_acl.apply(local_md, local_md.nexthop);
                } else {
                    dmac.apply(local_md.lkp.mac_dst_addr, local_md);
                    //if (local_md.lkp.ip_type != SWITCH_IP_TYPE_IPV6) {
                    //    ingress_ipv4_acl.apply(local_md, local_md.nexthop);
                    //}
                    //if (local_md.lkp.ip_type != SWITCH_IP_TYPE_IPV4) {
                    //    ingress_ipv6_acl.apply(local_md, local_md.nexthop);
                    //}
                }
            } else {
                dmac.apply(local_md.lkp.mac_dst_addr, local_md);
                //if (local_md.lkp.ip_type != SWITCH_IP_TYPE_IPV6) {
                //    ingress_ipv4_acl.apply(local_md, local_md.nexthop);
                //}
                //if (local_md.lkp.ip_type != SWITCH_IP_TYPE_IPV4) {
                //    ingress_ipv6_acl.apply(local_md, local_md.nexthop);
                //}
            }

            ingress_ip_mirror_acl.apply(local_md, local_md.unused_nexthop);
            sflow.apply(local_md);

            if (local_md.lkp.ip_type == SWITCH_IP_TYPE_NONE) {
                non_ip_hash.apply(hdr, local_md, local_md.lag_hash);
            } else if (local_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                lagv4_hash.apply(local_md.lkp, local_md.lag_hash);
            } else {
                lagv6_hash.apply(local_md.lkp, local_md.lag_hash);
            }

            if (local_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                ipv4_hash.apply(local_md.lkp, local_md.hash);
            } else {
                ipv6_hash.apply(local_md.lkp, local_md.hash);
            }

            nexthop.apply(local_md);
            qos_map.apply(hdr, local_md);
            traffic_class.apply(local_md);
            storm_control.apply(local_md, local_md.lkp.pkt_type, local_md.flags.storm_control_drop);
            ppg_stats.apply(local_md);

            if (local_md.egress_port_lag_index == SWITCH_FLOOD) {
                flood.apply(local_md);
            } else {
                lag.apply(local_md, local_md.lag_hash, ig_intr_md_for_tm.ucast_egress_port);
            }

            ecn_acl.apply(local_md, local_md.lkp, ig_intr_md_for_tm.packet_color);
            pfc_wd.apply(local_md.ingress_port, local_md.qos.qid, local_md.flags.pfc_wd_drop);

            system_acl.apply(hdr, local_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
            // ingress_ip_dtel_acl.apply(local_md, local_md.unused_nexthop);
            // dtel.apply(
            //     hdr, local_md.lkp, local_md, local_md.lag_hash[15:0], ig_intr_md_for_dprsr, ig_intr_md_for_tm);

            if (local_md.tunnel.terminate) {
                tunnel_decap.apply(hdr, local_md);
            }
            redirect_pipe0_to_pipe23_lo.apply();
            add_bridged_md(hdr.bridged_md, local_md);
            add_gw_bridged_md_todo(hdr.gw_bridged_md, local_md);
            set_ig_intr_md(local_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);
            hdr.fabric.setInvalid();
            hdr.cpu.setInvalid();
        }
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
    EgressPortMirror(288) port_mirror;
    EgressLOU() lou;
    EgressIpv4Acl(EGRESS_IPV4_ACL_TABLE_SIZE) egress_ipv4_acl;
    EgressIpv6Acl(EGRESS_IPV6_ACL_TABLE_SIZE) egress_ipv6_acl;
    EgressQoS() qos;
    EgressQueue() queue;
    EgressSystemAcl() system_acl;
    EgressPFCWd(512) pfc_wd;
    EgressVRF() egress_vrf;
    EgressBD() egress_bd;
    OuterNexthop() outer_nexthop;
    EgressBDStats() egress_bd_stats;
    MirrorRewrite() mirror_rewrite;
    VlanXlate(VLAN_TABLE_SIZE, PORT_VLAN_TABLE_SIZE) vlan_xlate;
    VlanDecap() vlan_decap;
    MTU() mtu;
    WRED() wred;
    //EgressDtel() dtel;
    //DtelConfig() dtel_config;
    EgressCpuRewrite() cpu_rewrite;
    //EgressPortIsolation() port_isolation;
    Neighbor() neighbor;
    SetEgIntrMd() set_eg_intr_md;

    action rewrite_flow_trace_v4() {
        hdr.ethernet.ether_type = 0x0800;
    }

    action rewrite_flow_trace_v6() {
        hdr.ethernet.ether_type = 0x86dd;
    }

    table rewrite_ether_type {
        key = {
            hdr.flow_trace.isValid() : exact;
            hdr.flow_trace.next_hdr : exact;
        }
        actions = {
            rewrite_flow_trace_v4;
            rewrite_flow_trace_v6;
        }
        const entries = {
            (true, 0) : rewrite_flow_trace_v4;
            (true, 1) : rewrite_flow_trace_v6;
        }
        size = MIN_TABLE_SIZE;
    }

    apply {
        /* For packet from PCIe CPU:
        These packets are from port 320 pipe2
        */
        if (local_md.egress_port == 64 && hdr.bridged_md.isValid() && hdr.bridged_md.src == SWITCH_CPU_BRIDGED) {
            hdr.bridged_md.setInvalid();
            hdr.loop_flag.setValid();
            hdr.loop_flag.flags = 2;
        }
        else {
            rewrite_ether_type.apply();
            if (local_md.egress_port == 64) {
                hdr.loop_flag.setValid();
                hdr.loop_flag.flags = 1;
            }
            hdr.flow_trace.egress_port = local_md.egress_port;
            egress_port_mapping.apply(hdr, local_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);
            if (local_md.pkt_src != SWITCH_PKT_SRC_BRIDGED) {
                mirror_rewrite.apply(hdr, local_md, eg_intr_md_for_dprsr);
            } else {
                port_mirror.apply(eg_intr_md.egress_port, local_md.mirror);
            }
            vlan_decap.apply(hdr, local_md);
            qos.apply(hdr, eg_intr_md.egress_port, local_md);
            wred.apply(hdr, local_md, eg_intr_md, local_md.flags.wred_drop);
            egress_vrf.apply(hdr, local_md);
            outer_nexthop.apply(hdr, local_md);
            egress_bd.apply(hdr, local_md);
            lou.apply(local_md);
            if (hdr.ipv4.isValid()) {
                egress_ipv4_acl.apply(hdr, local_md);
            } else if (hdr.ipv6.isValid()) {
                egress_ipv6_acl.apply(hdr, local_md);
            }
            neighbor.apply(hdr, local_md);
            egress_bd_stats.apply(hdr, local_md);


            mtu.apply(hdr, local_md);
            vlan_xlate.apply(hdr, local_md);
            pfc_wd.apply(eg_intr_md.egress_port, local_md.qos.qid, local_md.flags.pfc_wd_drop);
            //dtel.apply(hdr, local_md, eg_intr_md, eg_intr_md_from_prsr, local_md.dtel.hash);
            //port_isolation.apply(local_md, eg_intr_md);
            system_acl.apply(hdr, local_md, eg_intr_md, eg_intr_md_for_dprsr);
            //dtel_config.apply(hdr, local_md, eg_intr_md_for_dprsr);
            cpu_rewrite.apply(hdr, local_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);
            set_eg_intr_md.apply(hdr, local_md, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
            queue.apply(eg_intr_md.egress_port, local_md);
        }
    }
}

Pipeline <switch_header_t, switch_local_metadata_t, switch_header_t, switch_local_metadata_t> (SwitchIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
        SwitchEgressParser(),
        SwitchEgress(),
        SwitchEgressDeparser()) pipe;

Pipeline <switch_header_t, switch_local_metadata_t, switch_header_t, switch_local_metadata_t> (Tablep1IParser(),
        TableServiceIngress(),
        Tablep1IDeparser(),
        Tablep1EParser(),
        TableServiceEgress(),
        Tablep1EDeparser()) servicepipe1;


Pipeline <switch_header_t, switch_local_metadata_t, switch_header_t, switch_local_metadata_t> (Tablep23IParser(),
        TableIngress(),
        Tablep23IDeparser(),
        Tablep23EParser(),
        TableEgress(),
        Tablep23EDeparser()) tablepipe23;

Switch(tablepipe23, servicepipe1, pipe) main;
