# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4"
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
#include <tna.p4>

#if __TARGET_TOFINO__ == 1
@command_line("--disable-parse-min-depth-limit", "--disable-parse-max-depth-limit")
#endif  /* __TARGET_TOFINO__ == 1 */

//-----------------------------------------------------------------------------
// Features.
//-----------------------------------------------------------------------------
// This is a Asymmetric folded pipeline program


// L2



//TODO #define QINQ_ENABLE

// L3 Unicast
# 43 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4"
// Multicast


// ACLs
# 55 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4"
// Mirror

//#define INGRESS_PORT_MIRROR_ENABLE implemented in ingress_1
# 67 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4"
// QoS
# 79 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4"
// Tunnel


//#define IPV6_TUNNEL_ENABLE


//TODO #define TUNNEL_TTL_MODE_ENABLE
//TODO #define TUNNEL_QOS_MODE_ENABLE


// SFLOW


// NAT


// MLAG



// Misc
//#define PTP_ENABLE




//#define HASH_WIDTH_16
//#define HOST64_STAGE_4_PRAGMA





@egress_intrinsic_metadata_opt

//-----------------------------------------------------------------------------
// Table sizes.
//-----------------------------------------------------------------------------

// 4K L2 vlans
const bit<32> VLAN_TABLE_SIZE = 4096;
const bit<32> BD_FLOOD_TABLE_SIZE = VLAN_TABLE_SIZE * 4;

// 1K (port, vlan) <--> BD
const bit<32> PORT_VLAN_TABLE_SIZE = 1024;

// 1K VRF


// 5K BDs
const bit<32> BD_TABLE_SIZE = 5120;

// 16K MACs
const bit<32> MAC_TABLE_SIZE = 16*1024;

// IP Hosts/Routes


const bit<32> IPV4_HOST_TABLE_SIZE = 16*1024;
const bit<32> IPV4_LPM_TABLE_SIZE = 48*1024;
const bit<32> IPV6_HOST_TABLE_SIZE = 4096;
const bit<32> IPV6_HOST64_TABLE_SIZE = 16*1024;
const bit<32> IPV6_LPM_TABLE_SIZE = 512;
const bit<32> IPV6_LPM64_TABLE_SIZE = 12*1024;

// Multicast
const bit<32> IPV4_MULTICAST_STAR_G_TABLE_SIZE = 512;
const bit<32> IPV4_MULTICAST_S_G_TABLE_SIZE = 512;
const bit<32> IPV6_MULTICAST_STAR_G_TABLE_SIZE = 512;
const bit<32> IPV6_MULTICAST_S_G_TABLE_SIZE = 512;
const bit<32> RID_TABLE_SIZE = 4096;

// ECMP/Nexthop
const bit<32> ECMP_GROUP_TABLE_SIZE = 512;
const bit<32> ECMP_SELECT_TABLE_SIZE = 8192;

const bit<32> NEXTHOP_TABLE_SIZE = 4096;

const bit<32> TUNNEL_NEXTHOP_TABLE_SIZE = 4096;
//const bit<32> TUNNEL_NEXTHOP_TABLE_SIZE = 1 << switch_tunnel_nexthop_width;

// 256 v4 and v6 tunnels

const bit<32> TUNNEL_OBJECT_SIZE = 1 << 4;

const bit<32> TUNNEL_ENCAP_IPV4_SIZE = 512;
const bit<32> TUNNEL_ENCAP_IPV6_SIZE = 0;
const bit<32> TUNNEL_ENCAP_IP_SIZE = TUNNEL_ENCAP_IPV4_SIZE + TUNNEL_ENCAP_IPV6_SIZE;
const bit<32> BD_TO_VNI_MAPPING_SIZE = 16 * 1024;

// Ingress ACLs
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IP_MIRROR_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IP_QOS_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IP_PBR_ACL_TABLE_SIZE = 512;

// Egress ACL
const bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_QOS_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_MIRROR_ACL_TABLE_SIZE = 512;

// NAT
const bit<32> NAT_POOL_TABLE_SIZE = 512;
const bit<32> NAT_TABLE_SIZE = 4 * 1024;
const bit<32> NAPT_TABLE_SIZE = 4 * 1024;

// Storm Control
const bit<32> STORM_CONTROL_TABLE_SIZE = 256;

# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/headers.p4" 1
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

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> dei;
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
# 193 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4" 1
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
// Common protocols/types
//-----------------------------------------------------------------------------
# 84 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
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

const bit<32> VNI_MAPPING_TABLE_SIZE = 5*1024; // 4K VLAN + 1K VRF maps
# 111 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
// ----------------------------------------------------------------------------
// LPM
//-----------------------------------------------------------------------------





@pa_container_size("pipe_1", "ingress", "local_md.lkp.ip_dst_addr", 32)
@pa_container_size("pipe_1", "ingress", "_ipv4_lpm_partition_key", 32)
@pa_container_size("pipe_1", "ingress", "hdr.ipv4.dst_addr", 32)
@pa_container_size("pipe_1", "ingress", "hdr.ipv6.dst_addr", 32)
# 186 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
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




typedef bit<2> switch_isolation_group_t;





typedef bit<13> switch_bd_t;
const switch_bd_t SWITCH_BD_DEFAULT_VRF = 4097; // bd allocated for default vrf




const bit<32> VRF_TABLE_SIZE = 1 << 10;
typedef bit<10> switch_vrf_t;
const switch_vrf_t SWITCH_DEFAULT_VRF = 1;




typedef bit<16> switch_nexthop_t;




typedef bit<10> switch_user_metadata_t;
# 262 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
typedef bit<32> switch_hash_t;



typedef bit<16> switch_ecmp_hash_t;

typedef bit<128> srv6_sid_t;
# 279 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
typedef bit<16> switch_xid_t;
typedef L2ExclusionId_t switch_yid_t;


typedef bit<24> switch_ig_port_lag_label_t;






typedef bit<16> switch_eg_port_lag_label_t;

typedef bit<16> switch_bd_label_t;

typedef bit<16> switch_mtu_t;

typedef bit<12> switch_stats_index_t;

typedef bit<8> switch_ports_group_label_t;

typedef bit<16> switch_cpu_reason_t;
const switch_cpu_reason_t SWITCH_CPU_REASON_PTP = 0x8;
const switch_cpu_reason_t SWITCH_CPU_REASON_BFD = 0x9;

typedef bit<8> switch_fib_label_t;

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
const switch_drop_reason_t SWITCH_DROP_REASON_DST_MAC_MCAST_DST_IP_BCAST = 19;
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
const switch_drop_reason_t SWITCH_DROP_REASON_INGRESS_STP_STATE_BLOCKING = 57;
const switch_drop_reason_t SWITCH_DROP_REASON_SAME_IFINDEX = 58;
const switch_drop_reason_t SWITCH_DROP_REASON_MULTICAST_SNOOPING_ENABLED = 59;
const switch_drop_reason_t SWITCH_DROP_REASON_IN_L3_EGRESS_LINK_DOWN = 60;
const switch_drop_reason_t SWITCH_DROP_REASON_MTU_CHECK_FAIL = 70;
const switch_drop_reason_t SWITCH_DROP_REASON_TRAFFIC_MANAGER = 71;
const switch_drop_reason_t SWITCH_DROP_REASON_STORM_CONTROL = 72;
const switch_drop_reason_t SWITCH_DROP_REASON_WRED = 73;
const switch_drop_reason_t SWITCH_DROP_REASON_INGRESS_PORT_METER = 75;
const switch_drop_reason_t SWITCH_DROP_REASON_INGRESS_ACL_METER = 76;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_PORT_METER = 77;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_ACL_METER = 78;
const switch_drop_reason_t SWITCH_DROP_REASON_ACL_DROP = 80;
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
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_ACL_DROP = 92;
const switch_drop_reason_t SWITCH_DROP_REASON_NEXTHOP = 93;
const switch_drop_reason_t SWITCH_DROP_REASON_NON_IP_ROUTER_MAC = 94;
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
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_STP_STATE_BLOCKING = 110;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_MULTICAST_DMAC_MISMATCH = 111;
const switch_drop_reason_t SWITCH_DROP_REASON_SIP_BC = 112;
const switch_drop_reason_t SWITCH_DROP_REASON_IPV6_MC_SCOPE0 = 113;
const switch_drop_reason_t SWITCH_DROP_REASON_IPV6_MC_SCOPE1 = 114;
const switch_drop_reason_t SWITCH_DROP_REASON_ACL_DENY = 115;

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

// ----------------------------------------------------------------------------
// Bypass flags ---------------------------------------------------------------
// ----------------------------------------------------------------------------
typedef bit<16> switch_ingress_bypass_t;
# 472 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
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


// PKT ------------------------------------------------------------------------
typedef bit<16> switch_pkt_length_t;

typedef bit<8> switch_pkt_src_t;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED = 0;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_INGRESS = 1; // mirror original ingress packet
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_EGRESS = 2; // mirror final egress packet
const switch_pkt_src_t SWITCH_PKT_SRC_DEFLECTED = 3;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_EGRESS_IN_PKT= 4; // mirror packet ingressing from TM to egress parser

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


typedef bit<4> switch_etype_label_t;


typedef bit<8> switch_mac_addr_label_t;

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




typedef bit<10> switch_port_meter_id_t;




typedef bit<10> switch_acl_meter_id_t;




typedef bit<8> switch_mirror_meter_id_t;

// MYIP type ------------------------------------------------------------------
typedef bit<2> switch_myip_type_t;
const switch_myip_type_t SWITCH_MYIP_NONE = 0;
const switch_myip_type_t SWITCH_MYIP = 1;
const switch_myip_type_t SWITCH_MYIP_SUBNET = 2;

//Fwd type --------------------------------------------------------------------
typedef bit<2> switch_fwd_type_t;
const switch_fwd_type_t SWITCH_FWD_TYPE_NONE = 0;
const switch_fwd_type_t SWITCH_FWD_TYPE_L2 = 1; // port_lag_index
const switch_fwd_type_t SWITCH_FWD_TYPE_L3 = 2; // nexthop
const switch_fwd_type_t SWITCH_FWD_TYPE_MC = 3; // multicast_id

typedef bit<16> switch_fwd_idx_t;

// QoS ------------------------------------------------------------------------
typedef bit<2> switch_qos_trust_mode_t;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_UNTRUSTED = 0;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_TRUST_DSCP = 1;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_TRUST_PCP = 2;




typedef bit<5> switch_tc_t;
typedef bit<3> switch_cos_t;


typedef bit<11> switch_etrap_index_t;


struct switch_qos_metadata_t {
    switch_qos_trust_mode_t trust_mode; // Ingress only.
    switch_tc_t tc;
    switch_pkt_color_t color;
    switch_pkt_color_t acl_meter_color;
//    switch_pkt_color_t port_color;
//    switch_pkt_color_t flow_color;
    switch_pkt_color_t storm_control_color;
    switch_port_meter_id_t port_meter_index;
    switch_acl_meter_id_t acl_meter_index;
    switch_qid_t qid;
    switch_ingress_cos_t icos; // Ingress only.
    bit<19> qdepth; // Egress only.
    switch_etrap_index_t etrap_index;
    switch_pkt_color_t etrap_color;
    switch_tc_t etrap_tc;
    bit<1> etrap_state;



    bit<3> pcp;
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
    bit<1> hit;
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

typedef bit<8> switch_mirror_session_t;



const switch_mirror_session_t SWITCH_MIRROR_SESSION_CPU = 250;

// Using same mirror type for both Ingress/Egress to simplify the parser.
typedef bit<8> switch_mirror_type_t;
# 697 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
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

    switch_pkt_color_t meter_color;

}

header switch_port_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    bit<32> timestamp;






    switch_mirror_session_t session_id;
    switch_port_padding_t _pad1;
    switch_port_t port;
}

header switch_cpu_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    switch_port_padding_t _pad1;
    switch_port_t port;

    bit<3> _pad3;
    switch_bd_t bd;




    bit<6> _pad2;

    switch_port_lag_index_t port_lag_index;
    switch_cpu_reason_t reason_code;
}

// Tunneling ------------------------------------------------------------------
typedef bit<1> switch_tunnel_mode_t;
const switch_tunnel_mode_t SWITCH_TUNNEL_MODE_PIPE = 0;
const switch_tunnel_mode_t SWITCH_TUNNEL_MODE_UNIFORM = 1;

const switch_tunnel_mode_t SWITCH_ECN_MODE_STANDARD = 0;
const switch_tunnel_mode_t SWITCH_ECN_MODE_COPY_FROM_OUTER = 1;

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

enum switch_tunnel_term_mode_t { P2P, P2MP };
# 794 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
typedef bit<4> switch_tunnel_index_t;



typedef bit<4> switch_tunnel_mapper_index_t;



typedef bit<9> switch_tunnel_ip_index_t;



typedef bit<16> switch_tunnel_nexthop_t;
typedef bit<24> switch_tunnel_vni_t;

struct switch_tunnel_metadata_t {
    switch_tunnel_type_t type;
    switch_tunnel_mode_t ecn_mode;
    switch_tunnel_index_t index; // Egress only.
    switch_tunnel_mapper_index_t mapper_index;
    switch_tunnel_ip_index_t dip_index;
    switch_tunnel_vni_t vni;
//    switch_ifindex_t ifindex;
    switch_tunnel_mode_t qos_mode;
    switch_tunnel_mode_t ttl_mode;
    bit<8> decap_ttl;
    bit<8> decap_tos;
    bit<3> decap_exp;
    bit<16> hash;
    bool terminate;
    bit<8> nvgre_flow_id;
    bit<2> mpls_pop_count;
    bit<3> mpls_push_count;
    bit<8> mpls_encap_ttl;
    bit<3> mpls_encap_exp;
    bit<1> mpls_swap;
    bit<128> srh_next_sid;
//    bit<8> srh_seg_left;
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

typedef bit<8> switch_dtel_report_type_t;
typedef bit<8> switch_ifa_sample_id_t;
# 975 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
// NAT ------------------------------------------------

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

// Source Flow Control related types (SFC) ------------------------------------------------

enum bit<2> LinkToType {
    Unknown = 0,
    Switch = 1,
    Server = 2
}

const bit<32> msb_set_32b = 32w0x80000000;
# 1130 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
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
# 1174 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
struct switch_flags_t {
    bool ipv4_checksum_err;
    bool inner_ipv4_checksum_err;
    bool inner2_ipv4_checksum_err;
    bool link_local;
    bool routed;
    bool l2_tunnel_encap;
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
    bool wred_drop;
    bool port_isolation_packet_drop;
    bool bport_isolation_packet_drop;
    bool fib_lpm_miss;
    bool fib_drop;
    switch_packet_action_t meter_packet_action;
    switch_packet_action_t vrf_ttl_violation;
    bool vrf_ttl_violation_valid;
    bool vlan_arp_suppress;
    switch_packet_action_t vrf_ip_options_violation;
    bool vrf_unknown_l3_multicast_trap;
    bool bfd_to_cpu;
    bool redirect_to_cpu;
    bool copy_cancel;
    bool to_cpu;
    // Add more flags here.
}

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
    bit<1> dei;

    // 1 for ARP request, 2 for ARP reply.
    bit<16> arp_opcode;

    switch_ip_type_t ip_type;
    bit<8> ip_proto;
    bit<8> ip_ttl;
    bit<8> ip_tos;
    switch_ip_frag_t ip_frag;
    bit<128> ip_src_addr;
    bit<128> ip_dst_addr;
    bit<32> ip_src_addr_95_64;
    bit<32> ip_dst_addr_95_64;
    bit<20> ipv6_flow_label;

    bit<8> tcp_flags;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;
    bit<8> inner_tcp_flags;
    bit<16> inner_l4_src_port;
    bit<16> inner_l4_dst_port;
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

// Header types used by ingress/egress deparsers.
@flexible
struct switch_bridged_metadata_base_t {
    // user-defined metadata carried over from ingress to egress.
    switch_port_t ingress_port;
    switch_port_lag_index_t ingress_port_lag_index;
    switch_bd_t ingress_bd;
    switch_nexthop_t nexthop;
    switch_pkt_type_t pkt_type;
    bool routed;
    bool bypass_egress;



    switch_cpu_reason_t cpu_reason;



    bit<32> timestamp;

    switch_tc_t tc;
    switch_qid_t qid;
    switch_pkt_color_t color;
    switch_vrf_t vrf;



    // Add more fields here.
}

// Common metadata used for mirroring.
@flexible
struct switch_bridged_metadata_mirror_extension_t {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    switch_mirror_session_t session_id;
    switch_mirror_meter_id_t meter_index;
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
    switch_tunnel_nexthop_t tunnel_nexthop;

    bit<16> hash;
# 1364 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
    bool terminate;
}
# 1415 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
@pa_mutually_exclusive("pipe_0", "egress", "hdr.erspan", "hdr.vxlan")
@pa_mutually_exclusive("pipe_0", "egress", "hdr.gre", "hdr.vxlan")
@pa_mutually_exclusive("pipe_0", "egress", "hdr.erspan_type3", "hdr.vxlan")
@pa_mutually_exclusive("pipe_0", "egress", "hdr.erspan_type2", "hdr.vxlan")
# 1556 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
@flexible
header switch_fp_bridged_metadata_h {
    bit<16> ingress_bd_tt_myip;
    switch_pkt_type_t pkt_type;
    bool routed;



    bit<32> timestamp;

    switch_tc_t tc;
    bit<8> qid_icos;
    switch_pkt_color_t color;
    bool ipv4_checksum_err;
    bool rmac_hit;
    bool fib_drop;
    bool fib_lpm_miss;
    bit<1> multicast_hit;
    bool acl_deny;
    bool copy_cancel;
    bool nat_disable;
    switch_drop_reason_t drop_reason;
    switch_hostif_trap_t hostif_trap_id;
    switch_mirror_session_t mirror_session_id;
    switch_fwd_type_t fwd_type;
    switch_fwd_idx_t fwd_idx;
}

typedef bit<8> switch_bridge_type_t;
header switch_bridged_metadata_h {
    switch_pkt_src_t src;
    switch_bridge_type_t type;
    switch_bridged_metadata_base_t base;





    switch_bridged_metadata_tunnel_extension_t tunnel;
# 1609 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
}

struct switch_port_metadata_t {
    switch_port_lag_index_t port_lag_index;
    switch_ig_port_lag_label_t port_lag_label;



}

struct switch_fp_port_metadata_t {
    bit<1> unused;
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


/* CODE_HACK: Using an 8-bit container will ensure that a packing of 16 is used
   for L4 port range tables and number of srams will be optimized to 4 each. */
@pa_container_size("pipe_0", "ingress", "local_md.l4_src_port_label", 8)
@pa_container_size("pipe_0", "ingress", "local_md.l4_dst_port_label", 8)
@pa_container_size("pipe_1", "egress", "local_md.l4_src_port_label", 8)
@pa_container_size("pipe_1", "egress", "local_md.l4_dst_port_label", 8)
@pa_container_size("pipe_0", "ingress", "smac_src_move", 16)







@pa_alias("ingress", "local_md.egress_port", "ig_intr_md_for_tm.ucast_egress_port")



@pa_alias("ingress", "local_md.qos.qid", "ig_intr_md_for_tm.qid")
@pa_alias("ingress", "local_md.qos.icos", "ig_intr_md_for_tm.ingress_cos")
@pa_alias("ingress", "ig_intr_md_for_dprsr.mirror_type", "local_md.mirror.type")

@pa_container_size("ingress", "local_md.egress_port_lag_index", 16)


// Prevent container_size 32 which doubles src_napt action ram
@pa_container_size("ingress", "local_md.nat.snapt_index", 16)

@pa_container_size("egress", "local_md.mirror.src", 8)
@pa_container_size("egress", "local_md.mirror.type", 8)
# 1675 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
@pa_atomic("pipe_1", "ingress", "_ipv4_lpm_partition_key")
@pa_container_size("pipe_1", "ingress", "local_md.nexthop", 16)
@pa_container_size("pipe_1", "ingress", "hdr.bridged_md.base_nexthop", 16)


// Ingress/Egress metadata
struct switch_local_metadata_t {
    switch_port_t ingress_port; /* ingress port */
    switch_port_t egress_port; /* egress port */
    switch_port_lag_index_t ingress_port_lag_index; /* ingress port/lag index */
    switch_port_lag_index_t egress_port_lag_index; /* egress port/lag index */
    switch_bd_t bd;
    switch_bd_t ingress_outer_bd;
    switch_bd_t ingress_bd;
    switch_vrf_t vrf;
    switch_nexthop_t nexthop;
    switch_tunnel_nexthop_t tunnel_nexthop;
    switch_nexthop_t acl_nexthop;
    bool acl_port_redirect;
    switch_nexthop_t unused_nexthop;



    bit<32> timestamp;

    switch_ecmp_hash_t ecmp_hash;
    switch_ecmp_hash_t outer_ecmp_hash;
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
    switch_etype_label_t etype_label;
    switch_mac_addr_label_t qos_mac_label;
    switch_mac_addr_label_t pbr_mac_label;
    switch_mac_addr_label_t mirror_mac_label;

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







    mac_addr_t same_mac;

    switch_user_metadata_t user_metadata;

    bit<16> tcp_udp_checksum;
    switch_nat_ingress_metadata_t nat;

    bit<10> partition_key;
    bit<12> partition_index;
    switch_fib_label_t fib_label;

    switch_cons_hash_ip_seq_t cons_hash_v6_ip_seq;
    switch_pkt_src_t pkt_src;
    switch_pkt_length_t pkt_length;




    bit<32> egress_timestamp;
    bit<32> ingress_timestamp;

    switch_eg_port_lag_label_t egress_port_lag_label;
    switch_nexthop_type_t nexthop_type;
    bool inner_ipv4_checksum_update_en;

    switch_isolation_group_t port_isolation_group;
    switch_isolation_group_t bport_isolation_group;
# 1785 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
}

// Header format for mirrored metadata fields
struct switch_mirror_metadata_h {
    switch_port_mirror_metadata_h port;
    switch_cpu_mirror_metadata_h cpu;





}


struct switch_header_t {
    switch_bridged_metadata_h bridged_md;
    switch_fp_bridged_metadata_h fp_bridged_md;
    // switch_mirror_metadata_h mirror;
    ethernet_h ethernet;
    fabric_h fabric;
    cpu_h cpu;
    timestamp_h timestamp;
    vlan_tag_h[2] vlan_tag;
//#ifdef MPLS_ENABLE
    mpls_h[3] mpls;
//#endif



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
# 1833 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
    dtel_report_v05_h dtel;
    dtel_report_base_h dtel_report;
    dtel_switch_local_report_h dtel_switch_local_report;
    dtel_drop_report_h dtel_drop_report;

    rocev2_bth_h rocev2_bth;
    gtpu_h gtp;
# 1848 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4"
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
    igmp_h inner_igmp;
    ipv4_h inner2_ipv4;
    ipv6_h inner2_ipv6;
    udp_h inner2_udp;
    tcp_h inner2_tcp;
    icmp_h inner2_icmp;
    pad_h pad;
}
# 194 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/hash.p4" 1
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


# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4" 1
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
# 21 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/hash.p4" 2

// Flow hash calculation.

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

control Ipv4Hash(in switch_lookup_fields_t lkp, out switch_ecmp_hash_t hash) {
    @name(".ipv4_hash")
    Hash<switch_ecmp_hash_t>(HashAlgorithm_t.CRC16) ipv4_hash;
    bit<32> ip_src_addr = lkp.ip_src_addr[95:64];
    bit<32> ip_dst_addr = lkp.ip_dst_addr[95:64];
    bit<8> ip_proto = lkp.ip_proto;
    bit<16> l4_dst_port = lkp.hash_l4_dst_port;
    bit<16> l4_src_port = lkp.hash_l4_src_port;

    apply {
        hash = ipv4_hash.get({ip_src_addr,
                                     ip_dst_addr,
                                     ip_proto,
                                     l4_dst_port,
                                     l4_src_port});
    }
}

control Ipv6Hash(in switch_lookup_fields_t lkp, out switch_ecmp_hash_t hash) {
    @name(".ipv6_hash")
    Hash<switch_ecmp_hash_t>(HashAlgorithm_t.CRC16) ipv6_hash;
    bit<128> ip_src_addr = lkp.ip_src_addr;
    bit<128> ip_dst_addr = lkp.ip_dst_addr;
    bit<8> ip_proto = lkp.ip_proto;
    bit<16> l4_dst_port = lkp.hash_l4_dst_port;
    bit<16> l4_src_port = lkp.hash_l4_src_port;
    bit<20> ipv6_flow_label = lkp.ipv6_flow_label;

    apply {
        hash = ipv6_hash.get({

                                    ipv6_flow_label,

                                    ip_src_addr,
                                    ip_dst_addr,
                                    ip_proto,
                                    l4_dst_port,
                                    l4_src_port});
    }
}

control OuterIpv4Hash(in switch_lookup_fields_t lkp, out switch_ecmp_hash_t hash) {
    @name(".outer_ipv4_hash")
    Hash<switch_ecmp_hash_t>(HashAlgorithm_t.CRC16) ipv4_hash;
    bit<32> ip_src_addr = lkp.ip_src_addr[95:64];
    bit<32> ip_dst_addr = lkp.ip_dst_addr[95:64];
    bit<8> ip_proto = lkp.ip_proto;
    bit<16> l4_dst_port = lkp.hash_l4_dst_port;
    bit<16> l4_src_port = lkp.hash_l4_src_port;

    apply {
        hash = ipv4_hash.get({
                              ip_proto,
                              l4_dst_port,
                              l4_src_port,
                              ip_dst_addr,
                              ip_src_addr
        });
    }
}

control OuterIpv6Hash(in switch_lookup_fields_t lkp, out switch_ecmp_hash_t hash) {
    @name(".outer_ipv6_hash")
    Hash<switch_ecmp_hash_t>(HashAlgorithm_t.CRC16) ipv6_hash;
    bit<128> ip_src_addr = lkp.ip_src_addr;
    bit<128> ip_dst_addr = lkp.ip_dst_addr;
    bit<8> ip_proto = lkp.ip_proto;
    bit<16> l4_dst_port = lkp.hash_l4_dst_port;
    bit<16> l4_src_port = lkp.hash_l4_src_port;
    bit<20> ipv6_flow_label = lkp.ipv6_flow_label;

    apply {
        hash = ipv6_hash.get({
                                    ip_proto,
                                    l4_dst_port,
                                    l4_src_port,

                                    ipv6_flow_label,

                                    ip_dst_addr,
                                    ip_src_addr
        });
    }
}

control NonIpHash(in switch_header_t hdr, in switch_local_metadata_t local_md, out switch_hash_t hash) {
    @name(".non_ip_hash")
    Hash<switch_hash_t>(HashAlgorithm_t.CRC32) non_ip_hash;
    mac_addr_t mac_dst_addr = hdr.ethernet.dst_addr;
    mac_addr_t mac_src_addr = hdr.ethernet.src_addr;
    bit<16> mac_type = hdr.ethernet.ether_type;
    switch_port_t port = local_md.ingress_port;

    apply {
        hash = non_ip_hash.get({port,
                                       mac_type,
                                       mac_src_addr,
                                       mac_dst_addr});
    }
}
control Lagv4Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
    @name(".lag_v4_hash")
    Hash<switch_hash_t>(HashAlgorithm_t.CRC32) lag_v4_hash;
    bit<32> ip_src_addr = lkp.ip_src_addr[95:64];
    bit<32> ip_dst_addr = lkp.ip_dst_addr[95:64];
    bit<8> ip_proto = lkp.ip_proto;
    bit<16> l4_dst_port = lkp.hash_l4_dst_port;
    bit<16> l4_src_port = lkp.hash_l4_src_port;

    apply {
        hash = lag_v4_hash.get({ip_src_addr,
                                   ip_dst_addr,
                                   ip_proto,
                                   l4_dst_port,
                                   l4_src_port});
    }
}
control Lagv6Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
    @name(".lag_v6_hash")
    Hash<switch_hash_t>(HashAlgorithm_t.CRC32) lag_v6_hash;
    bit<128> ip_src_addr = lkp.ip_src_addr;
    bit<128> ip_dst_addr = lkp.ip_dst_addr;
    bit<8> ip_proto = lkp.ip_proto;
    bit<16> l4_dst_port = lkp.hash_l4_dst_port;
    bit<16> l4_src_port = lkp.hash_l4_src_port;
    bit<20> ipv6_flow_label = lkp.ipv6_flow_label;

    apply {
        hash = lag_v6_hash.get({

                                   ipv6_flow_label,

                                   ip_src_addr,
                                   ip_dst_addr,
                                   ip_proto,
                                   l4_dst_port,
                                   l4_src_port});
    }
}
# 189 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/hash.p4"
/******************************************************************************
// V4ConsistentHash generic control block
// This block compares v4 sip/dip & calculates low/high v4 IP
// Using the low/high v4-IP, it then calculates/returns V4 consistent hash
******************************************************************************/
control V4ConsistentHash(in bit<32> sip, in bit<32> dip,
                         in bit<16> low_l4_port, in bit<16> high_l4_port,
                         in bit<8> protocol,
                         inout switch_ecmp_hash_t hash) {
    Hash<switch_ecmp_hash_t>(HashAlgorithm_t.CRC16) ipv4_inner_hash;
    bit<32> high_ip;
    bit<32> low_ip;

    action step_v4() {
        high_ip = max(sip, dip);
        low_ip = min(sip, dip);
    }

    action v4_calc_hash() {
        hash = ipv4_inner_hash.get({low_ip, high_ip,
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
                         inout switch_ecmp_hash_t hash) {
    bit<32> high_31_0_ip;
    bit<32> low_31_0_ip;
    bit<32> src_31_0_ip;
    Hash<switch_ecmp_hash_t>(HashAlgorithm_t.CRC16) ipv6_inner_hash_1;
    Hash<switch_ecmp_hash_t>(HashAlgorithm_t.CRC16) ipv6_inner_hash_2;
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
        hash = ipv6_inner_hash_1.get({sip, dip,
                                            protocol,
                                            low_l4_port, high_l4_port});
    }

    // low ip - dip, high ip - sip i.e. SWITCH_CONS_HASH_IP_SEQ_DIPSIP
    action v6_calc_hash_dip_sip() {
        hash = ipv6_inner_hash_2.get({dip, sip,
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
    Hash<switch_ecmp_hash_t>(HashAlgorithm_t.CRC16) ipv6_inner_hash;

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
        ig_m.ecmp_hash = ipv6_inner_hash.get({low_31_0_ip, high_31_0_ip,
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
                                           ig_m.ecmp_hash);
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
                                       ig_m.ecmp_hash);
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
    Hash<switch_hash_t>(HashAlgorithm_t.CRC32) inner_dtelv4_hash;
    bit<32> ip_src_addr = hdr.inner_ipv4.src_addr;
    bit<32> ip_dst_addr = hdr.inner_ipv4.dst_addr;
    bit<8> ip_proto = hdr.inner_ipv4.protocol;
    bit<16> l4_src_port = hdr.udp.src_port; // Entropy field from vxlan header
//    bit<16> l4_dst_port = hdr.inner_tcp.dst_port;
//    bit<16> l4_src_port = hdr.inner_tcp.src_port;

    apply {
        hash = inner_dtelv4_hash.get({
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
    Hash<switch_hash_t>(HashAlgorithm_t.CRC32) inner_dtelv6_hash;
    bit<128> ip_src_addr = hdr.ipv6.src_addr;
    bit<128> ip_dst_addr = hdr.ipv6.dst_addr;
    bit<8> ip_proto = hdr.ipv6.next_hdr;
    bit<16> l4_src_port = hdr.udp.src_port; // Entropy field from vxlan header
//    bit<16> l4_dst_port = hdr.inner_tcp.dst_port;
//    bit<16> l4_src_port = hdr.inner_tcp.src_port;
    bit<20> ipv6_flow_label = hdr.inner_ipv6.flow_label;

    apply {
        hash = inner_dtelv6_hash.get({

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
# 549 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/hash.p4"
    @name(".rotate_by_1") action rotate_by_1() { local_md.ecmp_hash[15:0] = local_md.ecmp_hash[1 -1:0] ++ local_md.ecmp_hash[15:1]; }
    @name(".rotate_by_2") action rotate_by_2() { local_md.ecmp_hash[15:0] = local_md.ecmp_hash[2 -1:0] ++ local_md.ecmp_hash[15:2]; }
    @name(".rotate_by_3") action rotate_by_3() { local_md.ecmp_hash[15:0] = local_md.ecmp_hash[3 -1:0] ++ local_md.ecmp_hash[15:3]; }
    @name(".rotate_by_4") action rotate_by_4() { local_md.ecmp_hash[15:0] = local_md.ecmp_hash[4 -1:0] ++ local_md.ecmp_hash[15:4]; }
    @name(".rotate_by_5") action rotate_by_5() { local_md.ecmp_hash[15:0] = local_md.ecmp_hash[5 -1:0] ++ local_md.ecmp_hash[15:5]; }
    @name(".rotate_by_6") action rotate_by_6() { local_md.ecmp_hash[15:0] = local_md.ecmp_hash[6 -1:0] ++ local_md.ecmp_hash[15:6]; }
    @name(".rotate_by_7") action rotate_by_7() { local_md.ecmp_hash[15:0] = local_md.ecmp_hash[7 -1:0] ++ local_md.ecmp_hash[15:7]; }
    @name(".rotate_by_8") action rotate_by_8() { local_md.ecmp_hash[15:0] = local_md.ecmp_hash[8 -1:0] ++ local_md.ecmp_hash[15:8]; }
    @name(".rotate_by_9") action rotate_by_9() { local_md.ecmp_hash[15:0] = local_md.ecmp_hash[9 -1:0] ++ local_md.ecmp_hash[15:9]; }
    @name(".rotate_by_10") action rotate_by_10() { local_md.ecmp_hash[15:0] = local_md.ecmp_hash[10 -1:0] ++ local_md.ecmp_hash[15:10]; }
    @name(".rotate_by_11") action rotate_by_11() { local_md.ecmp_hash[15:0] = local_md.ecmp_hash[11 -1:0] ++ local_md.ecmp_hash[15:11]; }
    @name(".rotate_by_12") action rotate_by_12() { local_md.ecmp_hash[15:0] = local_md.ecmp_hash[12 -1:0] ++ local_md.ecmp_hash[15:12]; }
    @name(".rotate_by_13") action rotate_by_13() { local_md.ecmp_hash[15:0] = local_md.ecmp_hash[13 -1:0] ++ local_md.ecmp_hash[15:13]; }
    @name(".rotate_by_14") action rotate_by_14() { local_md.ecmp_hash[15:0] = local_md.ecmp_hash[14 -1:0] ++ local_md.ecmp_hash[15:14]; }
    @name(".rotate_by_15") action rotate_by_15() { local_md.ecmp_hash[15:0] = local_md.ecmp_hash[15 -1:0] ++ local_md.ecmp_hash[15:15]; }

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
# 195 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2

# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/l3.p4" 1
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


# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/acl.p4" 1
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


# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/acl2.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2022 Intel Corporation
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
// Ingress MAC ACL
//-----------------------------------------------------------------------------
control IngressMacAcl(in switch_header_t hdr, inout switch_local_metadata_t local_md)(
        switch_uint32_t table_size=512) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    // sai_action : forward
    action no_action() {
        stats.count();
    }

    // sai_action : drop
    action drop() {
        local_md.flags.acl_deny = true;
        stats.count();
    }

    // sai_action : transit/copy cancel
    action transit() {
        local_md.flags.copy_cancel = true;
        stats.count();
    }

    // sai_action : deny
    action deny() {
        local_md.flags.acl_deny = true;
        local_md.flags.copy_cancel = true;
        stats.count();
    }

    // sai_action : trap 
    action trap(switch_hostif_trap_t trap_id) {
        local_md.hostif_trap_id = trap_id;
        stats.count();
    }

    action disable_nat(bool nat_dis) {

        local_md.nat.nat_disable = nat_dis;

        stats.count();
    }

    table acl {
        key = {
            local_md.lkp.mac_src_addr : ternary;
            local_md.lkp.mac_dst_addr : ternary;
            local_md.lkp.mac_type : ternary;
            local_md.lkp.pcp : ternary;
            local_md.lkp.dei : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
            local_md.bd[12:0]: ternary @name("local_md.bd");
            local_md.ingress_port_lag_index : ternary;
            //local_md.flags.rmac_hit : ternary;
        }

        actions = {
            drop;
            deny;
            transit;
            trap;
            disable_nat;
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
control IngressIpv4Acl(inout switch_local_metadata_t local_md)(
                       switch_uint32_t table_size=512) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    // sai_action : forward
    action no_action() {
        stats.count();
    }

     // sai_action : drop
    action drop() {
        local_md.flags.acl_deny = true;
        stats.count();
    }

    // sai_action : transit/copy_cancel
    action transit() {
        local_md.flags.copy_cancel = true;
        stats.count();
    }

    // sai_action : deny
    action deny() {
        local_md.flags.acl_deny = true;
        local_md.flags.copy_cancel = true;
        stats.count();
    }

    // sai_action : trap 
    action trap(switch_hostif_trap_t trap_id) {
        local_md.hostif_trap_id = trap_id;
        stats.count();
    }

    action disable_nat(bool nat_dis) {

        local_md.nat.nat_disable = nat_dis;

        stats.count();
    }

    table acl {
        key = {
            local_md.bd[12:0]: ternary @name("local_md.bd");
            local_md.lkp.ip_src_addr[95:64] : ternary;
            local_md.lkp.ip_dst_addr[95:64] : ternary;
            local_md.lkp.ip_tos : ternary;
            local_md.lkp.ip_proto : ternary;
            local_md.lkp.l4_dst_port : ternary;
            local_md.lkp.l4_src_port : ternary;
            local_md.lkp.tcp_flags : ternary;
            local_md.l4_src_port_label : ternary;
            local_md.l4_dst_port_label : ternary;
            local_md.ingress_port_lag_index : ternary;
            local_md.flags.rmac_hit : ternary;
        }

        actions = {
            drop;
            deny;
            transit;
            trap;
            disable_nat;
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
control IngressIpv6Acl(inout switch_local_metadata_t local_md)(
                       switch_uint32_t table_size=512) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    // sai_action : forward
    action no_action() {
        stats.count();
    }

    // sai_action : drop
    action drop() {
        local_md.flags.acl_deny = true;
        stats.count();
    }

    // sai_action : transit/copy_cancel
    action transit() {
        local_md.flags.copy_cancel = true;
        stats.count();
    }

    // sai_action : deny
    action deny() {
        local_md.flags.acl_deny = true;
        local_md.flags.copy_cancel = true;
        stats.count();
    }

    // sai_action : trap 
    action trap(switch_hostif_trap_t trap_id) {
        local_md.hostif_trap_id = trap_id;
        stats.count();
    }

    action disable_nat(bool nat_dis) {

        local_md.nat.nat_disable = nat_dis;

        stats.count();
    }

    table acl {
        key = {
            local_md.bd[12:0]: ternary @name("local_md.bd");
            local_md.lkp.ip_src_addr : ternary;
            local_md.lkp.ip_dst_addr : ternary;
            local_md.lkp.ip_tos : ternary;
            local_md.lkp.ip_proto : ternary;
            local_md.lkp.l4_dst_port : ternary;
            local_md.lkp.l4_src_port : ternary;
            local_md.lkp.tcp_flags : ternary;
            local_md.l4_src_port_label : ternary;
            local_md.l4_dst_port_label : ternary;
            local_md.ingress_port_lag_index : ternary;
            local_md.flags.rmac_hit : ternary;
        }

        actions = {
            drop;
            deny;
            transit;
            trap;
            disable_nat;
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
// Ingress QoS ACL
//-----------------------------------------------------------------------------
control IngressQosAcl(in switch_header_t hdr, inout switch_local_metadata_t local_md)(
        switch_uint32_t table_size=512) {

    // ************************* ACL TCAM *********************************
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    DirectMeter(MeterType_t.BYTES) meter;

    action no_action(switch_acl_meter_id_t meter_index) {
        stats.count();

        local_md.qos.acl_meter_color = (bit<2>)meter.execute();
        local_md.qos.acl_meter_index = meter_index;

    }

    action set_meter(switch_acl_meter_id_t meter_index) {
        stats.count();

        local_md.qos.acl_meter_color = (bit<2>)meter.execute();
        local_md.qos.acl_meter_index = meter_index;

    }

    // This functionality is not mandatory if there is an egress qos acl in the profile.
    action set_pcp(bit<3> pcp) {
        local_md.lkp.pcp = pcp;
        stats.count();
    }

    action set_tos(switch_uint8_t tos) {
        local_md.lkp.ip_tos = tos;
        stats.count();
    }

    action set_tc(switch_acl_meter_id_t meter_index, switch_tc_t tc) {
        local_md.qos.tc = tc;
        stats.count();

        local_md.qos.acl_meter_color = (bit<2>)meter.execute();
        local_md.qos.acl_meter_index = meter_index;

    }

    action set_color(switch_acl_meter_id_t meter_index, switch_pkt_color_t color) {
        local_md.qos.color = color;
        stats.count();

        local_md.qos.acl_meter_color = (bit<2>)meter.execute();
        local_md.qos.acl_meter_index = meter_index;

    }

    action set_qos_params(switch_acl_meter_id_t meter_index,
                          switch_tc_t tc,
                          switch_pkt_color_t color) {
        local_md.qos.tc = tc;
        local_md.qos.color = color;
        stats.count();

        local_md.qos.acl_meter_index = meter_index;
        local_md.qos.acl_meter_color = (bit<2>)meter.execute();

    }

    table acl {
        key = {
            local_md.qos_mac_label : ternary;
            local_md.etype_label : ternary;
            local_md.lkp.pcp : ternary;
            local_md.lkp.dei : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
            local_md.bd[12:0]: ternary @name("local_md.bd");
            local_md.lkp.ip_src_addr : ternary;
            local_md.lkp.ip_dst_addr : ternary;
            local_md.lkp.ip_tos : ternary;
            local_md.lkp.ip_proto : ternary;
            local_md.lkp.l4_dst_port : ternary;
            local_md.lkp.l4_src_port : ternary;
            local_md.lkp.tcp_flags : ternary;
            local_md.l4_src_port_label : ternary;
            local_md.l4_dst_port_label : ternary;
            local_md.ingress_port_lag_index : ternary;
            local_md.flags.rmac_hit : ternary;
        }

        // TODO combination of basic actions
        actions = {
            //set_pcp;
            //set_tos;
            set_tc;
            set_color;
            set_qos_params;

            set_meter;

            no_action;
        }

        const default_action = no_action(0);
        counters = stats;

        meters = meter;

        size = table_size;
    }

    // ************************* Meter Stats and action**************************
    DirectCounter<bit<32>>(CounterType_t.BYTES) meter_stats;

//    @name(".ingress_acl_meter.count")
    action count() {
        meter_stats.count();
    }

    action drop_and_count() {
        meter_stats.count();
        /* CODE_HACK: This is going to overwrite any drop conditions set earlier in the pipeline. TBD */
        local_md.drop_reason = SWITCH_DROP_REASON_INGRESS_ACL_METER;
    }

//    @name(".ingress_acl_meter.meter_action")
    table meter_action {
        key = {
            local_md.qos.acl_meter_color: exact;
            local_md.qos.acl_meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            drop_and_count();
            count;
        }

        const default_action = NoAction;
        /* Single rate two color policer with drop/no-drop action only */
        size = table_size*2;
        counters = meter_stats;
    }

    apply {
        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();

            meter_action.apply();

        }
    }
}

//-----------------------------------------------------------------------------
// Ingress Mirror ACL
//-----------------------------------------------------------------------------
control IngressMirrorAcl(inout switch_header_t hdr, inout switch_local_metadata_t local_md)(
        switch_uint32_t table_size=512) {

    // ************************* ACL TCAM *********************************
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    DirectMeter(MeterType_t.BYTES) meter;

    action no_action(switch_mirror_meter_id_t meter_index) {
        stats.count();

        local_md.mirror.meter_color = (bit<2>)meter.execute();
        local_md.mirror.meter_index = meter_index;

    }

    action mirror_in(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) {

        hdr.fp_bridged_md.mirror_session_id = session_id;





        stats.count();

        local_md.mirror.meter_color = (bit<2>)meter.execute();
        local_md.mirror.meter_index = meter_index;

    }

    @stage(10)
    table acl {
        key = {
            local_md.mirror_mac_label : ternary;
            local_md.etype_label : ternary;
            local_md.lkp.pcp : ternary;
            local_md.lkp.dei : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
            local_md.bd[12:0]: ternary @name("local_md.bd");
            local_md.lkp.ip_src_addr : ternary;
            local_md.lkp.ip_dst_addr : ternary;
            local_md.lkp.ip_tos : ternary;
            local_md.lkp.ip_proto : ternary;
            local_md.lkp.l4_dst_port : ternary;
            local_md.lkp.l4_src_port : ternary;
            local_md.lkp.tcp_flags : ternary;
            local_md.l4_src_port_label : ternary;
            local_md.l4_dst_port_label : ternary;
            local_md.ingress_port_lag_index : ternary;
            local_md.flags.rmac_hit : ternary;
        }

        actions = {
            mirror_in;
            no_action;
        }

        const default_action = no_action(0);
        counters = stats;

        meters = meter;

        size = table_size;
    }

    // ************************* Meter Stats and Action **********************
    DirectCounter<bit<32>>(CounterType_t.BYTES) meter_stats;

//    @name(".ingress_acl_meter.count")
    action count() {
        meter_stats.count();
    }

    action drop_and_count() {
        meter_stats.count();
        local_md.mirror.type = 0;
    }

//    @name(".ingress_acl_meter.meter_action")
    table meter_action {
        key = {
            local_md.mirror.meter_color: exact;
            local_md.mirror.meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            drop_and_count();
            count;
        }

        const default_action = NoAction;
        size = table_size*2;
        counters = meter_stats;
    }

    apply {
        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();

            meter_action.apply();

        }
    }
}

//-----------------------------------------------------------------------------
// Ingress PBR ACL
//-----------------------------------------------------------------------------
control IngressPbrAcl(inout switch_header_t hdr, inout switch_local_metadata_t local_md)(
        switch_uint32_t table_size=512) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() {
        stats.count();
    }

    action redirect_port(switch_port_lag_index_t egress_port_lag_index) {

        hdr.fp_bridged_md.fwd_type = SWITCH_FWD_TYPE_L2;
        hdr.fp_bridged_md.fwd_idx = (switch_fwd_idx_t)egress_port_lag_index;
        hdr.fp_bridged_md.routed = false;





        local_md.acl_port_redirect = true;
        stats.count();
    }

    action redirect_nexthop(switch_nexthop_t nexthop_index) {

        hdr.fp_bridged_md.fwd_type = SWITCH_FWD_TYPE_L3;
        hdr.fp_bridged_md.fwd_idx =(switch_fwd_idx_t)nexthop_index;
        hdr.fp_bridged_md.routed = true;
        hdr.fp_bridged_md.fib_lpm_miss = false;





        stats.count();
    }



    table acl {
        key = {
            local_md.pbr_mac_label : ternary;
            local_md.etype_label : ternary;
            local_md.lkp.pcp : ternary;
            local_md.lkp.dei : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
            local_md.bd[12:0]: ternary @name("local_md.bd");
            local_md.lkp.ip_src_addr : ternary;
            local_md.lkp.ip_dst_addr : ternary;
            local_md.lkp.ip_tos : ternary;
            local_md.lkp.ip_proto : ternary;
            local_md.lkp.l4_dst_port : ternary;
            local_md.lkp.l4_src_port : ternary;
            local_md.lkp.tcp_flags : ternary;
            local_md.l4_src_port_label : ternary;
            local_md.l4_dst_port_label : ternary;
            local_md.ingress_port_lag_index : ternary;
            local_md.flags.rmac_hit : ternary;
        }

        actions = {
            redirect_port;
            redirect_nexthop;
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
// Range check for L4 Source/Destinations port
// ----------------------------------------------------------------------------
control LOU(inout switch_local_metadata_t local_md) {

    const switch_uint32_t table_size = 64 * 1024;

    @name(".set_ingress_src_port_label")
    action set_src_port_label(bit<8> label) {
        local_md.l4_src_port_label = label;
    }

    @name(".set_ingress_dst_port_label")
    action set_dst_port_label(bit<8> label) {
        local_md.l4_dst_port_label = label;
    }




    @use_hash_action(1) @pack(16)
    table l4_dst_port {
        key = {
            local_md.lkp.l4_dst_port : exact;
        }

        actions = {
            set_dst_port_label;
        }

        const default_action = set_dst_port_label(0);
        size = table_size;
    }




    @use_hash_action(1) @pack(16)
    table l4_src_port {
        key = {
            local_md.lkp.l4_src_port : exact;
        }

        actions = {
            set_src_port_label;
        }

        const default_action = set_src_port_label(0);
        size = table_size;
    }

    apply {
        l4_src_port.apply();
        l4_dst_port.apply();
    }
}

// -------------------------------------------------------------------------------
// Take advantage of sparsity of ethertye values to compress it to a shorter field
// -------------------------------------------------------------------------------
control AclEtype(inout switch_local_metadata_t local_md) {

    action set_etype_label(switch_etype_label_t label) {
        local_md.etype_label = label;
    }

    table etype {
        key = {
            local_md.lkp.mac_type : exact;
        }

        actions = {
            set_etype_label;
        }

        const default_action = set_etype_label(0);
        size = 1 << 4;
    }

    apply {
        etype.apply();
    }
}

// -------------------------------------------------------------------------------
// Compress MAC address to a shorter field
// -------------------------------------------------------------------------------
control AclMacAddr(in switch_port_lag_index_t port_lag_index,
                   in mac_addr_t smac_addr,
                   in mac_addr_t dmac_addr,
                   out switch_mac_addr_label_t mac_label) {

    action set_mac_addr_label(switch_mac_addr_label_t label) {
        mac_label = label;
    }

    table mac {
        key = {
            port_lag_index : ternary;
            smac_addr : ternary;
            dmac_addr : ternary;
        }

        actions = {
            set_mac_addr_label;
        }

        const default_action = set_mac_addr_label(0);
        size = 512;
    }

    apply {
        mac.apply();
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

    DirectCounter<bit<32>>(CounterType_t.PACKETS) stats;

    @name(".ingress_copp_meter")
    Meter<bit<8>>(1 << 8, MeterType_t.PACKETS) copp_meter;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) copp_stats;

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

        local_md.nat.hit = SWITCH_NAT_HIT_NONE;

    }

    @name(".ingress_system_acl_copy_to_cpu_cancel")
    action copy_to_cpu_cancel() {
        ig_intr_md_for_tm.copy_to_cpu = 1w0;
    }
    @name(".ingress_system_acl_deny")
    action deny(switch_drop_reason_t drop_reason, bool disable_learning) {
        drop(drop_reason, disable_learning);
        copy_to_cpu_cancel();
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

        local_md.nat.hit = SWITCH_NAT_HIT_NONE;

        local_md.flags.redirect_to_cpu = true;
        copy_to_cpu(reason_code, qid, meter_id, disable_learning, overwrite_qid);
    }

    @name(".ingress_system_acl_redirect_sflow_to_cpu")
    action redirect_sflow_to_cpu(switch_cpu_reason_t reason_code,
                                 switch_qid_t qid,
                                 switch_copp_meter_id_t meter_id,
                                 bool disable_learning, bool overwrite_qid) {
        ig_intr_md_for_dprsr.drop_ctl = 0b1;
        local_md.flags.redirect_to_cpu = true;
        copy_sflow_to_cpu(reason_code, qid, meter_id, disable_learning, overwrite_qid);
    }

    @name(".ingress_system_acl")
    table system_acl {
        key = {
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
            local_md.flags.vlan_arp_suppress : ternary;
            local_md.flags.vrf_ttl_violation : ternary;
            local_md.flags.vrf_ttl_violation_valid : ternary;
            local_md.flags.vrf_ip_options_violation : ternary;



            local_md.flags.acl_deny : ternary;
            local_md.flags.copy_cancel : ternary;
            local_md.flags.rmac_hit : ternary;
            local_md.flags.dmac_miss : ternary;
            local_md.flags.myip : ternary;
            local_md.flags.glean : ternary;
            local_md.flags.routed : ternary;
            local_md.flags.fib_lpm_miss : ternary;
            local_md.flags.fib_drop : ternary;
//            local_md.qos.acl_meter_color : ternary;
            local_md.qos.storm_control_color : ternary;
            local_md.flags.link_local : ternary;
            local_md.flags.port_meter_drop : ternary;


            local_md.checks.same_if : ternary;




            local_md.flags.pfc_wd_drop : ternary;
            local_md.ipv4.unicast_enable : ternary;
            local_md.ipv6.unicast_enable : ternary;
            local_md.checks.mrpf : ternary;
            local_md.ipv4.multicast_enable : ternary;
            local_md.ipv4.multicast_snooping : ternary;
            local_md.ipv6.multicast_enable : ternary;
            local_md.ipv6.multicast_snooping : ternary;
            local_md.multicast.hit : ternary;
            local_md.flags.vrf_unknown_l3_multicast_trap : ternary;
            local_md.sflow.sample_packet : ternary;



            local_md.drop_reason : ternary;

            // punt packets to cpu if nat.hit == SWITCH_NAT_HIT_TYPE_DEST_NONE
            local_md.nat.hit : ternary;
            local_md.checks.same_zone_check : ternary;

            local_md.tunnel.terminate : ternary;
            local_md.hostif_trap_id : ternary;

            // Header fields
            hdr.ipv4_option.isValid() : ternary;
        }

        actions = {
            permit;
            drop;
            deny;
            copy_to_cpu;
            copy_to_cpu_cancel;
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


//-----------------------------------------------------------------------------
// Egress MAC ACL
//-----------------------------------------------------------------------------
control EgressMacAcl(in switch_header_t hdr,
                     inout switch_local_metadata_t local_md)(
                     switch_uint32_t table_size=512) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() {
        stats.count(sizeInBytes(hdr.bridged_md));
    }

    action drop() {
        local_md.flags.acl_deny = true;
        stats.count(sizeInBytes(hdr.bridged_md));
    }

    table acl {
        key = {
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
            local_md.lkp.mac_type : ternary;
            hdr.vlan_tag[0].pcp : ternary;
            hdr.vlan_tag[0].dei : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
            local_md.bd[12:0]: ternary @name("local_md.bd");
            local_md.egress_port_lag_index : ternary;
            local_md.flags.routed : ternary;
        }

        actions = {
            drop;
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
// Egress IPv4 ACL
//-----------------------------------------------------------------------------
control EgressIpv4Acl(in switch_header_t hdr,
                      inout switch_local_metadata_t local_md)(
                      switch_uint32_t table_size=512) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() {
        stats.count(sizeInBytes(hdr.bridged_md));
    }

    action drop() {
        local_md.flags.acl_deny = true;
        stats.count(sizeInBytes(hdr.bridged_md));
    }

    table acl {
        key = {
            local_md.bd[12:0]: ternary @name("local_md.bd");
            local_md.lkp.ip_src_addr_95_64 : ternary;
            local_md.lkp.ip_dst_addr_95_64 : ternary;
            local_md.lkp.ip_proto : ternary;
            local_md.lkp.ip_tos : ternary;
            local_md.lkp.tcp_flags : ternary;
            local_md.lkp.l4_dst_port : ternary;
            local_md.lkp.l4_src_port : ternary;
            local_md.egress_port_lag_index : ternary;
            local_md.flags.routed : ternary;
        }

        actions = {
            drop;
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
// Egress IPv6 ACL
//-----------------------------------------------------------------------------
control EgressIpv6Acl(in switch_header_t hdr,
                      inout switch_local_metadata_t local_md)(
                      switch_uint32_t table_size=512) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() {
        stats.count(sizeInBytes(hdr.bridged_md));
    }

    action drop() {
        local_md.flags.acl_deny = true;
        stats.count(sizeInBytes(hdr.bridged_md));
    }

    table acl {
        key = {
            local_md.bd[12:0]: ternary @name("local_md.bd");

            hdr.ipv6.src_addr[127:96] : ternary;
            local_md.lkp.ip_src_addr_95_64 : ternary;
            hdr.ipv6.src_addr[63:0] : ternary;

            hdr.ipv6.dst_addr[127:96] : ternary;
            local_md.lkp.ip_dst_addr_95_64 : ternary;
            hdr.ipv6.dst_addr[63:0] : ternary;

            local_md.lkp.ip_proto : ternary;
            local_md.lkp.ip_tos : ternary;
            local_md.lkp.tcp_flags : ternary;
            local_md.lkp.l4_dst_port : ternary;
            local_md.lkp.l4_src_port : ternary;
            local_md.egress_port_lag_index : ternary;
            local_md.flags.routed : ternary;
        }

        actions = {
            drop;
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
// Egress QoS ACL
//-----------------------------------------------------------------------------
control EgressQosAcl(inout switch_header_t hdr, inout switch_local_metadata_t local_md)(
        switch_uint32_t table_size=512) {

    // ************************* ACL TCAM *********************************
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    DirectMeter(MeterType_t.BYTES) meter;

    action no_action(switch_acl_meter_id_t meter_index) {
        stats.count(sizeInBytes(hdr.bridged_md));

        local_md.qos.acl_meter_color = (bit<2>)meter.execute();
        local_md.qos.acl_meter_index = meter_index;

    }

    action set_meter(switch_acl_meter_id_t meter_index) {
        stats.count(sizeInBytes(hdr.bridged_md));

        local_md.qos.acl_meter_color = (bit<2>)meter.execute();
        local_md.qos.acl_meter_index = meter_index;

    }

    action set_pcp(bit<3> pcp, switch_acl_meter_id_t meter_index) {
        hdr.vlan_tag[0].pcp = pcp;
        stats.count(sizeInBytes(hdr.bridged_md));

        local_md.qos.acl_meter_color = (bit<2>)meter.execute();
        local_md.qos.acl_meter_index = meter_index;

    }

    action set_ipv4_tos(switch_uint8_t tos, switch_acl_meter_id_t meter_index) {
        hdr.ipv4.diffserv = tos;
        stats.count(sizeInBytes(hdr.bridged_md));

        local_md.qos.acl_meter_color = (bit<2>)meter.execute();
        local_md.qos.acl_meter_index = meter_index;

    }

    action set_ipv6_tos(switch_uint8_t tos, switch_acl_meter_id_t meter_index) {
        hdr.ipv6.traffic_class = tos;
        stats.count(sizeInBytes(hdr.bridged_md));

        local_md.qos.acl_meter_color = (bit<2>)meter.execute();
        local_md.qos.acl_meter_index = meter_index;

    }

    action set_pcp_and_ipv4_tos(bit<3> pcp, switch_uint8_t tos, switch_acl_meter_id_t meter_index) {
        hdr.vlan_tag[0].pcp = pcp;
        hdr.ipv4.diffserv = tos;
        stats.count(sizeInBytes(hdr.bridged_md));

        local_md.qos.acl_meter_color = (bit<2>)meter.execute();
        local_md.qos.acl_meter_index = meter_index;

    }

    action set_pcp_and_ipv6_tos(bit<3> pcp, switch_uint8_t tos, switch_acl_meter_id_t meter_index) {
        hdr.vlan_tag[0].pcp = pcp;
        hdr.ipv6.traffic_class = tos;
        stats.count(sizeInBytes(hdr.bridged_md));

        local_md.qos.acl_meter_color = (bit<2>)meter.execute();
        local_md.qos.acl_meter_index = meter_index;

    }


    @ignore_table_dependency("SwitchEgress_0.egress_ip_mirror_acl.acl")



    table acl {
        key = {
            local_md.qos_mac_label : ternary;
            local_md.lkp.mac_type : ternary;
            hdr.vlan_tag[0].pcp : ternary;
            hdr.vlan_tag[0].dei : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
            local_md.bd[12:0]: ternary @name("local_md.bd");

            hdr.ipv6.src_addr[127:96] : ternary;
            local_md.lkp.ip_src_addr_95_64 : ternary;
            hdr.ipv6.src_addr[63:0] : ternary;

            hdr.ipv6.dst_addr[127:96] : ternary;
            local_md.lkp.ip_dst_addr_95_64 : ternary;
            hdr.ipv6.dst_addr[63:0] : ternary;

            local_md.lkp.ip_proto : ternary;
            local_md.lkp.ip_tos : ternary;
            local_md.lkp.tcp_flags : ternary;
            local_md.lkp.l4_dst_port : ternary;
            local_md.lkp.l4_src_port : ternary;
            local_md.egress_port_lag_index : ternary;
            local_md.lkp.ip_type : ternary;
            local_md.flags.routed : ternary;
        }

        actions = {

            set_meter;

            set_pcp;
            set_ipv4_tos;
            set_ipv6_tos;
            set_pcp_and_ipv4_tos;
            set_pcp_and_ipv6_tos;
            no_action;
        }

        const default_action = no_action(0);
        counters = stats;

        meters = meter;

        size = table_size;
    }

    // ************************* Meter Stats and Action ***********************
    DirectCounter<bit<32>>(CounterType_t.BYTES) meter_stats;

//    @name(".egress_acl_meter.count")
    action count() {
        meter_stats.count();
    }

//    @Name(".egress_acl_meter.meter_action")
    table meter_action {
        key = {
            local_md.qos.acl_meter_color : exact;
            local_md.qos.acl_meter_index : exact;
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        size = table_size*2;
        counters = meter_stats;
    }

    apply {
        if (!local_md.flags.bypass_egress) {
            acl.apply();

            meter_action.apply();

        }
    }
}

//-----------------------------------------------------------------------------
// Egress Mirror ACL
//-----------------------------------------------------------------------------
control EgressMirrorAcl(in switch_header_t hdr, inout switch_local_metadata_t local_md)(
        switch_uint32_t table_size=512) {

    // ************************* ACL TCAM *********************************
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    DirectMeter(MeterType_t.BYTES) meter;

    action no_action(switch_mirror_meter_id_t meter_index) {
        stats.count(sizeInBytes(hdr.bridged_md));

        local_md.mirror.meter_color = (bit<2>)meter.execute();
        local_md.mirror.meter_index = meter_index;

    }

    action mirror_out(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) {
        local_md.mirror.type = 1;
        local_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        local_md.mirror.session_id = session_id;
        local_md.mirror.meter_index = meter_index;
        stats.count(sizeInBytes(hdr.bridged_md));

        local_md.mirror.meter_color = (bit<2>)meter.execute();
        local_md.mirror.meter_index = meter_index;

    }

    /* Note: Mirror ACL will not match on the final PCP eoverwritten by QoS ACL" */

    @ignore_table_dependency("SwitchEgress_0.egress_ip_qos_acl.acl")



    table acl {
        key = {
            local_md.mirror_mac_label : ternary;
            local_md.lkp.mac_type : ternary;
            hdr.vlan_tag[0].pcp : ternary;
            hdr.vlan_tag[0].dei : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
            local_md.bd[12:0]: ternary @name("local_md.bd");

            hdr.ipv6.src_addr[127:96] : ternary;
            local_md.lkp.ip_src_addr_95_64 : ternary;
            hdr.ipv6.src_addr[63:0] : ternary;

            hdr.ipv6.dst_addr[127:96] : ternary;
            local_md.lkp.ip_dst_addr_95_64 : ternary;
            hdr.ipv6.dst_addr[63:0] : ternary;

            local_md.lkp.ip_proto : ternary;
            local_md.lkp.ip_tos : ternary;
            local_md.lkp.tcp_flags : ternary;
            local_md.lkp.l4_dst_port : ternary;
            local_md.lkp.l4_src_port : ternary;
            local_md.egress_port_lag_index : ternary;
            local_md.lkp.ip_type : ternary;
            local_md.flags.routed : ternary;
        }

        actions = {
            mirror_out;
            no_action;
        }

        const default_action = no_action(0);
        counters = stats;

        meters = meter;

        size = table_size;
    }

    // ************************* Meter Stats and Action **********************
    DirectCounter<bit<32>>(CounterType_t.BYTES) meter_stats;

//    @name(".egress_acl_meter.count")
    action count() {
        meter_stats.count();
    }

//    @name(".egress_acl_meter.meter_action")
    table meter_action {
        key = {
            local_md.mirror.meter_color: exact;
            local_md.mirror.meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        size = table_size*2;
        counters = meter_stats;
    }

    apply {
        if (!local_md.flags.bypass_egress) {
            acl.apply();

            meter_action.apply();

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

    // Take care of any drop conditions triggered earlier in the pipeline
    DirectCounter<bit<32>>(CounterType_t.PACKETS) drop_stats;

    @name(".egress_system_acl_drop")
    action drop(switch_drop_reason_t reason_code) {
        local_md.drop_reason = reason_code;
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        local_md.mirror.type = 0;
        drop_stats.count(sizeInBytes(hdr.bridged_md));
    }
# 1424 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/acl2.p4"
    action mirror_meter_drop(switch_drop_reason_t reason_code) {
        local_md.mirror.type = 0;
        drop_stats.count(sizeInBytes(hdr.bridged_md));
    }

    @name(".egress_system_acl")
    table system_acl {
        key = {
            eg_intr_md.egress_port : ternary;
            local_md.flags.acl_deny : ternary;
            local_md.checks.mtu : ternary;
            local_md.checks.stp : ternary;
            local_md.flags.wred_drop : ternary;
            local_md.flags.pfc_wd_drop : ternary;
            local_md.qos.acl_meter_color : ternary;
            local_md.flags.port_meter_drop : ternary;
            local_md.mirror.meter_color : ternary;
            /* CODE_HACK: not implemented in BMAI */
            //local_md.checks.same_if : ternary;
            local_md.flags.port_isolation_packet_drop : ternary;
            local_md.flags.bport_isolation_packet_drop : ternary;
        }

        /* Programming Note: acl entry for mirror_meter_drop is the lowest priority entry and doesn't need to match on egress port */
        actions = {
            drop;
            mirror_meter_drop;



        }

        counters = drop_stats;
        size = table_size;
    }

    apply {
        if (!local_md.flags.bypass_egress) {
            system_acl.apply();
        }
    }
}
# 21 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/acl.p4" 2
# 21 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/l3.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/l2.p4" 1
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
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;

    // Bit 0 of STP state
    @name(".ingress_stp.stp0")
    Register<bit<1>, bit<32>>(stp_state_size, 0) stp0;
    RegisterAction<bit<1>, bit<32>, bit<1>>(stp0) stp_check0 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };

    // Bit 1 of STP state
    @name(".ingress_stp.stp1")
    Register<bit<1>, bit<32>>(stp_state_size, 0) stp1;
    RegisterAction<bit<1>, bit<32>, bit<1>>(stp1) stp_check1 = {
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

        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_STP != 0)) {
            if (multiple_stp_enable) {
                mstp.apply();
            } else {
                // First 4K BDs which are reserved for VLANs
                if (local_md.ingress_outer_bd[13 -1:12] == 0) {
                    stp_md.state_[0:0] = stp_check0.execute(
                        hash.get({local_md.ingress_outer_bd[11:0], local_md.ingress_port[6:0]}));
                    stp_md.state_[1:1] = stp_check1.execute(
                        hash.get({local_md.ingress_outer_bd[11:0], local_md.ingress_port[6:0]}));
                }
            }
        }

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

        if (!local_md.flags.bypass_egress) {
            // First 4K BDs which are reserved for VLANs
            if (local_md.bd[13 -1:12] == 0) {
                bit<32> stp_hash_ = hash.get({local_md.bd[11:0], port[6:0]});
                stp_state = (bool) stp_check.execute(stp_hash_);
            }
        }

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
             in mac_addr_t dst_addr,
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
            src_miss : ternary;
            src_move : ternary;
            local_md.flags.port_vlan_miss : ternary;
            local_md.stp.state_ : ternary;
            local_md.l2_drop_reason : ternary;
            local_md.drop_reason : ternary;
//            local_md.lkp.pkt_type : ternary;
//            local_md.lkp.mac_type : ternary;
//            dst_addr : ternary;
        }
# 205 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/l2.p4"
        actions = {
            NoAction;
            notify;
        }

        const default_action = NoAction;
        const entries = {

            ( true, _, false, SWITCH_STP_STATE_FORWARDING, 0, _) : notify();
            ( true, _, false, SWITCH_STP_STATE_LEARNING, 0, _) : notify();
            (false, 0 &&& 0x3FF, _, _, _, _) : NoAction();
            (false, _, false, SWITCH_STP_STATE_FORWARDING, 0, _) : notify();
            (false, _, false, SWITCH_STP_STATE_LEARNING, 0, _) : notify();
//            ( true,           _, false, SWITCH_STP_STATE_FORWARDING, 0, _, _, _, _) : notify();
//            ( true,           _, false,   SWITCH_STP_STATE_LEARNING, 0, _, _, _, _) : notify();
//            (false, 0 &&& 0x3FF,     _,                           _, _, _, _, _, _) : NoAction();
//            (false,           _, false, SWITCH_STP_STATE_FORWARDING, 0, _, _, _, _) : notify();
//            (false,           _, false,   SWITCH_STP_STATE_LEARNING, 0, _, _, _, _) : notify();





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


    @name(".dmac_multicast")
    action dmac_multicast(switch_mgid_t index) {
        local_md.multicast.id = index;
    }


    @name(".dmac_redirect")
    action dmac_redirect(switch_nexthop_t nexthop_index) {
        local_md.nexthop = nexthop_index;
    }

    /* CODE_HACK: P4C-3103 */
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

            dmac_multicast;

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
// Same interface check
//-----------------------------------------------------------------------------
control SameIfCheck(inout switch_local_metadata_t local_md) {

    apply {
        if (local_md.drop_reason == 0 &&
            (local_md.ingress_port_lag_index == local_md.egress_port_lag_index)) {
            local_md.drop_reason = SWITCH_DROP_REASON_SAME_IFINDEX;
        }
    }
}

//-----------------------------------------------------------------------------
// Ingress BD (VLAN, RIF) Stats
//
//-----------------------------------------------------------------------------
control IngressBd(in switch_bd_t bd,

                  in switch_header_t hdr,

                  in switch_pkt_type_t pkt_type)(switch_uint32_t table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    // cannot give .count cuz of a bfrt issue

    @name(".ingress_bd_stats_count") action count() { stats.count(sizeInBytes(hdr.fp_bridged_md)); }




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

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    @name(".egress_bd_stats_count") action count() { stats.count(sizeInBytes(hdr.bridged_md)); }

    @name(".egress_bd_stats")
    table bd_stats {
        key = {
            local_md.bd[12:0] : exact;
            local_md.lkp.pkt_type : exact;
        }

        actions = {
            count;
            @defaultonly NoAction;
        }

        size = 3 * BD_TABLE_SIZE;
        counters = stats;
    }

    apply {
        /* CODE_HACK : TODO: Should mirror packets be counted in bd stats */
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

control VlanDecap(inout switch_header_t hdr, inout switch_local_metadata_t local_md) {
    @name(".remove_vlan_tag")
    action remove_vlan_tag() {
        hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
        hdr.vlan_tag.pop_front(1);
    }
# 513 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/l2.p4"
    apply {




        if (!local_md.flags.bypass_egress && hdr.vlan_tag[0].isValid()) {
            // Remove the vlan tag by default.
            hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
            hdr.vlan_tag[0].setInvalid();
            local_md.pkt_length = local_md.pkt_length - 4;

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
                  inout switch_local_metadata_t local_md)(
                  switch_uint32_t bd_table_size,
                  switch_uint32_t port_bd_table_size) {
    @name(".set_vlan_untagged")
    action set_vlan_untagged() {
        local_md.lkp.mac_type = hdr.ethernet.ether_type;
        //NoAction.
    }
# 563 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/l2.p4"
    @name(".set_vlan_tagged")
    action set_vlan_tagged(vlan_id_t vid) {



        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;

        hdr.vlan_tag[0].dei = 0;
        hdr.vlan_tag[0].vid = vid;
        hdr.ethernet.ether_type = 0x8100;
        hdr.vlan_tag[0].pcp = local_md.qos.pcp;
        local_md.lkp.mac_type = hdr.ethernet.ether_type;
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
# 638 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/l2.p4"
    apply {
        if (!local_md.flags.bypass_egress) {
            if (!port_bd_to_vlan_mapping.apply().hit) {
                bd_to_vlan_mapping.apply();
            }




        }
    }
}
# 22 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/l3.p4" 2

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
control Fibv4(in bit<32> dst_addr, inout switch_local_metadata_t local_md)(
              switch_uint32_t host_table_size,
              switch_uint32_t lpm_table_size,
              bool local_host_enable=false,
              switch_uint32_t local_host_table_size=1024) {

    /* CODE_HACK: P4C-3103 for table fitting with p4c 9.5. */
    @pack(2)
    @name(".ipv4_host") table host {
        key = {
            local_md.vrf : exact @name("vrf");
            dst_addr : exact @name("ip_dst_addr");
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
            dst_addr : exact @name("ip_dst_addr");
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


    Alpm(number_partitions = 1024,
         subtrees_per_partition = 2,
         atcam_subset_width = 18,
         shift_granularity = 1) algo_lpm;



    @name(".ipv4_lpm") table lpm32 {
        key = {
            local_md.vrf : exact @name("vrf");
            dst_addr : lpm @name("ip_dst_addr");
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
control Fibv6(in bit<128> dst_addr, inout switch_local_metadata_t local_md)(
              switch_uint32_t host_table_size,
              switch_uint32_t host64_table_size,
              switch_uint32_t lpm_table_size,
              switch_uint32_t lpm64_table_size=1024) {


    @ways(5)

    @name(".ipv6_host") table host {
        key = {
            local_md.vrf : exact @name("vrf");
            dst_addr : exact @name("ip_dst_addr");
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





    @name(".ipv6_host64") table host64 {
        key = {
            local_md.vrf : exact @name("vrf");
            dst_addr[127:64] : exact @name("ip_dst_addr");
        }

        actions = {
            fib_miss(local_md);
            fib_hit(local_md);
            fib_myip(local_md);
            fib_drop(local_md);
        }

        const default_action = fib_miss(local_md);
        size = host64_table_size;
    }
# 234 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/l3.p4"
    @name(".ipv6_lpm_tcam") table lpm_tcam {
        key = {
            local_md.vrf : exact @name("vrf");
            dst_addr : lpm @name("ip_dst_addr");
        }

        actions = {
            fib_miss(local_md);
            fib_hit(local_md);
            fib_myip(local_md);
            fib_drop(local_md);
        }

        const default_action = fib_miss(local_md);
        size = lpm_table_size;
    }



    Alpm(number_partitions = 1024,
         subtrees_per_partition = 2,
         atcam_subset_width = 32,
         shift_granularity = 2) algo_lpm64;



    @name(".ipv6_lpm64") table lpm64 {
        key = {
            local_md.vrf : exact @name("vrf");
            dst_addr[127:64] : lpm @name("ip_dst_addr");
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

            if (!lpm_tcam.apply().hit)



            {

                if(!host64.apply().hit) {


                    lpm64.apply();


                }

            }
        }

    }
}
# 453 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/l3.p4"
//-----------------------------------------------------------------------------
// VRF Properties
//       -- Inner VRF for encap cases
//
//-----------------------------------------------------------------------------

control EgressVRF(inout switch_header_t hdr,
                 inout switch_local_metadata_t local_md) {

    @name(".set_vrf_properties")
    action set_vrf_properties(mac_addr_t smac) {
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

        const default_action = set_vrf_properties(0);
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
# 197 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/nexthop.p4" 1
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
# 46 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/nexthop.p4"
    @name(".nexthop_ecmp_selector")
    ActionSelector(ecmp_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   ecmp_max_members_per_group,
                   ecmp_group_table_size) ecmp_selector;


    // ---------------- IP Nexthop ----------------
    @name(".nexthop_set_nexthop_properties")
    action set_nexthop_properties(switch_port_lag_index_t port_lag_index,



                                  switch_nat_zone_t zone) {

        local_md.checks.same_zone_check = local_md.nat.ingress_zone ^ zone;

        local_md.egress_port_lag_index = port_lag_index;





        // Flattned tunnel + immediate IP nexthop for MPLS, SAL etc.
        local_md.tunnel_nexthop = local_md.nexthop;

    }

    @name(".set_ecmp_properties")
    action set_ecmp_properties(switch_port_lag_index_t port_lag_index,



                               switch_nexthop_t nexthop_index, switch_nat_zone_t zone) {
        local_md.nexthop = nexthop_index;

        local_md.tunnel_nexthop = local_md.nexthop;




        set_nexthop_properties(port_lag_index, zone);

    }

    // ----------------  Post Route Flood ----------------
    @name(".set_nexthop_properties_post_routed_flood")
    action set_nexthop_properties_post_routed_flood(switch_bd_t bd, switch_mgid_t mgid, switch_nat_zone_t zone) {
        local_md.egress_port_lag_index = 0;
        local_md.multicast.id = mgid;

        local_md.checks.same_zone_check = local_md.nat.ingress_zone ^ zone;

    }

    // ---------------- Glean ----------------
    @name(".set_nexthop_properties_glean")
    action set_nexthop_properties_glean(switch_hostif_trap_t trap_id) {
        local_md.flags.glean = true;

        local_md.hostif_trap_id = trap_id;

    }

    @name(".set_ecmp_properties_glean")
    action set_ecmp_properties_glean(switch_hostif_trap_t trap_id) {
        set_nexthop_properties_glean(trap_id);
    }

    // ---------------- Drop ----------------
    @name(".set_nexthop_properties_drop")
    action set_nexthop_properties_drop(switch_drop_reason_t drop_reason) {
        local_md.drop_reason = drop_reason;
    }

    @name(".set_ecmp_properties_drop")
    action set_ecmp_properties_drop() {
        set_nexthop_properties_drop(SWITCH_DROP_REASON_NEXTHOP);
    }


    //  ---------------- Tunnel Encap ----------------
    @name(".set_nexthop_properties_tunnel")
    action set_nexthop_properties_tunnel(switch_tunnel_ip_index_t dip_index) {
        // TODO : Disable cut-through for non-ip packets.
        local_md.tunnel.dip_index = dip_index;
        local_md.egress_port_lag_index = 0;
        local_md.tunnel_nexthop = local_md.nexthop;
    }

    @name(".set_ecmp_properties_tunnel")
    action set_ecmp_properties_tunnel(switch_tunnel_ip_index_t dip_index, switch_nexthop_t nexthop_index) {
        local_md.tunnel.dip_index = dip_index;
        local_md.egress_port_lag_index = 0;
        local_md.tunnel_nexthop = nexthop_index;
    }


    @ways(2)
    @name(".ecmp_table")
    table ecmp {
        key = {
            local_md.nexthop : exact;
            local_md.ecmp_hash : selector;
        }

        actions = {
            @defaultonly NoAction;
            set_ecmp_properties;
            set_ecmp_properties_drop;
            set_ecmp_properties_glean;

            set_ecmp_properties_tunnel;

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

            set_nexthop_properties_tunnel;

        }

        const default_action = NoAction;
        size = nexthop_table_size;
    }

    apply {
# 208 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/nexthop.p4"
        switch(nexthop.apply().action_run) {
            NoAction : { ecmp.apply(); }
            default : {}
            }



    }
}


//--------------------------------------------------------------------------
// Route lookup and ECMP resolution for Tunnel Destination IP
//-------------------------------------------------------------------------
control OuterFib(inout switch_local_metadata_t local_md)(
                 switch_uint32_t ecmp_max_members_per_group=64) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    @name(".outer_fib_ecmp_action_profile")
    ActionProfile(ECMP_SELECT_TABLE_SIZE) ecmp_action_profile;
    @name(".outer_fib_ecmp_selector")
    ActionSelector(ecmp_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   ecmp_max_members_per_group,
                   ECMP_GROUP_TABLE_SIZE) ecmp_selector;

    @name(".outer_fib_set_nexthop_properties")
    action set_nexthop_properties(switch_port_lag_index_t port_lag_index,
                                  switch_nexthop_t nexthop_index) {
        local_md.nexthop = nexthop_index;
        local_md.egress_port_lag_index = port_lag_index;
    }

    @name(".outer_fib")
    table fib {
        key = {
            local_md.tunnel.dip_index : exact;
            local_md.outer_ecmp_hash : selector;
        }

        actions = {
            NoAction;
            set_nexthop_properties;
        }

        const default_action = NoAction;
        implementation = ecmp_selector;
        size = 1 << 9;
    }

    apply {
        fib.apply();
    }
}


//--------------------------------------------------------------------------
// Egress Pipeline: Neighbor lookup for both routed and tunnel encap cases
//-------------------------------------------------------------------------

control Neighbor(inout switch_header_t hdr,
                inout switch_local_metadata_t local_md)() {

    @name(".neighbor_rewrite_l2")
    action rewrite_l2(mac_addr_t dmac) {
        hdr.ethernet.dst_addr = dmac;
    }




    @name (".neighbor")
    table neighbor {
        key = { local_md.nexthop : exact; } // Programming_note : Program if nexthop_type == IP
        actions = {
            rewrite_l2;
        }

        const default_action = rewrite_l2(0);
        size = NEXTHOP_TABLE_SIZE;
    }

    apply {
        // Should not rewrite packets redirected to CPU.
        if (!local_md.flags.bypass_egress && local_md.flags.routed && local_md.nexthop != 0) {
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

    @name(".outer_nexthop_rewrite_l2")
    action rewrite_l2(switch_bd_t bd) {
        local_md.bd = bd;
    }




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
        if (!local_md.flags.bypass_egress && local_md.flags.routed && local_md.nexthop != 0) {
            outer_nexthop.apply();
        }
    }
}
# 198 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/parde_fp.p4" 1
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

# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/headers.p4" 1
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
# 20 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/parde_fp.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4" 1
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
# 21 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/parde_fp.p4" 2

//================================================================================
// Physical Ingress parser on External pipe (Stage 1 of logical ingress pipeline)
//================================================================================
parser SwitchIngressParser_0(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_local_metadata_t local_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    @name(".ingress_udp_port_vxlan")
    value_set<bit<16>>(1) udp_port_vxlan;
    @name(".ingress_cpu_port")
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;

    state start {
        pkt.extract(ig_intr_md);
        local_md.ingress_port = ig_intr_md.ingress_port;



        local_md.ingress_timestamp = ig_intr_md.ingress_mac_tstamp[31:0];

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
            (0x88A8, _) : parse_vlan;



            default : accept;
        }
    }

    state parse_cpu {
        pkt.extract(hdr.fabric);
        pkt.extract(hdr.cpu);
        local_md.bypass = hdr.cpu.reason_code;
        transition select(hdr.cpu.ether_type) {
            0x0800 : parse_ipv4;
            0x0806 : parse_arp;
            0x86dd : parse_ipv6;
            0x8100 : parse_vlan;
            0x88A8 : parse_vlan;



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
        local_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (1, 0) : parse_icmp;
            (2, 0) : parse_igmp;
            (6, 0) : parse_tcp;
            (17, 0) : parse_ipv4_udp;
//            (IP_PROTOCOLS_GRE, 0) : parse_ip_gre;
            (4, 0) : parse_ipinip;
            (41, 0) : parse_ipv6inip;
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
        transition select(hdr.ipv6.next_hdr) {
            58 : parse_icmp;
            6 : parse_tcp;
            17 : parse_ipv6_udp;
//            IP_PROTOCOLS_GRE : parse_ip_gre;
//            IP_PROTOCOLS_IPV4 : parse_ipinip;
//            IP_PROTOCOLS_IPV6 : parse_ipv6inip;



            default : accept;
        }



    }
# 316 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/parde_fp.p4"
//    state parse_ip_gre {
//        pkt.extract(hdr.gre);
//        transition select(hdr.gre.flags_version, hdr.gre.proto) {
//#ifdef NVGRE_ENABLE
//            (0x2000, GRE_PROTOCOLS_NVGRE) : parse_ip_nvgre;
//#endif
//            //(_, GRE_PROTOCOLS_IP) : parse_inner_ipv4;
//            //(_, GRE_PROTOCOLS_IPV6) : parse_inner_ipv6;
//            default : accept;
//        }
//    }

    state parse_ipv4_udp {
        pkt.extract(hdr.udp);
        local_md.lkp.l4_src_port = hdr.udp.src_port;
        local_md.lkp.l4_dst_port = hdr.udp.dst_port;
        transition select(hdr.udp.dst_port) {

            udp_port_vxlan : parse_vxlan;

            default : accept;
        }
    }

    state parse_ipv6_udp {
        pkt.extract(hdr.udp);
        local_md.lkp.l4_src_port = hdr.udp.src_port;
        local_md.lkp.l4_dst_port = hdr.udp.dst_port;
 transition accept;
    }

    state parse_tcp {
        tcp_h tcp_md = pkt.lookahead<tcp_h>();
        local_md.lkp.l4_src_port = tcp_md.src_port;
        local_md.lkp.l4_dst_port = tcp_md.dst_port;
        local_md.lkp.tcp_flags = tcp_md.flags;
        transition accept;
    }

    state parse_icmp {
        icmp_h icmp_md = pkt.lookahead<icmp_h>();
        local_md.lkp.l4_src_port[7:0] = icmp_md.type;
        local_md.lkp.l4_src_port[15:8] = icmp_md.code;
        transition accept;
    }

    state parse_igmp {
        igmp_h igmp_md = pkt.lookahead<igmp_h>();
        local_md.lkp.l4_src_port[7:0] = igmp_md.type;
        local_md.lkp.l4_src_port[15:8] = 0;
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
            6 : parse_inner_tcp;
            17 : parse_inner_udp;
            1 : parse_inner_icmp;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr) {
            6 : parse_inner_tcp;
            17 : parse_inner_udp;
            58 : parse_inner_icmp;
            default : accept;
        }
    }

    state parse_inner_udp {
        udp_h inner_udp_md = pkt.lookahead<udp_h>();
        local_md.lkp.inner_l4_src_port = inner_udp_md.src_port;
        local_md.lkp.inner_l4_dst_port = inner_udp_md.dst_port;
        transition accept;
    }

    state parse_inner_tcp {
        tcp_h inner_tcp_md = pkt.lookahead<tcp_h>();
        local_md.lkp.inner_l4_src_port = inner_tcp_md.src_port;
        local_md.lkp.inner_l4_dst_port = inner_tcp_md.dst_port;
        local_md.lkp.inner_tcp_flags = inner_tcp_md.flags;
        transition accept;
    }

    state parse_inner_icmp {
        icmp_h inner_icmp_md = pkt.lookahead<icmp_h>();
        local_md.lkp.inner_l4_src_port[7:0] = inner_icmp_md.type;
        local_md.lkp.inner_l4_dst_port[15:8] = inner_icmp_md.code;
        transition accept;
    }

}

//=================================================================================
// Physical Egress parser on internal pipe (2nd stage of logical ingress pipeline)
//=================================================================================
parser SwitchEgressParser_1(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_local_metadata_t local_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    @name(".egress1_udp_port_vxlan")
    value_set<bit<16>>(1) udp_port_vxlan;
    @name(".internal_pipe_cpu_port")
    value_set<switch_cpu_port_value_set_t>(1) recirc_port_cpu_hdr;

    state start {
        pkt.extract(eg_intr_md);
        local_md.ingress_port = eg_intr_md.egress_port;
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        pkt.extract(hdr.fp_bridged_md);
        local_md.flags.rmac_hit = hdr.fp_bridged_md.rmac_hit;
        transition select(hdr.ethernet.ether_type, eg_intr_md.egress_port) {
            recirc_port_cpu_hdr : parse_cpu;
            (0x0800, _) : parse_ipv4;
            (0x0806, _) : parse_arp;
            (0x86dd, _) : parse_ipv6;
            (0x8100, _) : parse_vlan;



            default : accept;
        }
    }

    state parse_cpu {
        pkt.extract(hdr.fabric);
        pkt.extract(hdr.cpu);
        local_md.bypass = hdr.cpu.reason_code;
        transition select(hdr.cpu.ether_type) {
            0x0800 : parse_ipv4_no_tunnel;
            0x0806 : parse_arp;
            0x86dd : parse_ipv6;
            0x8100 : parse_vlan_no_tunnel;






            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            0x0806 : parse_arp;
            0x0800 : parse_ipv4;



            0x86dd : parse_ipv6;
            default : accept;
        }
    }

    state parse_vlan_no_tunnel {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            0x0806 : parse_arp;
            0x0800 : parse_ipv4_no_tunnel;



            0x86dd : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol, hdr.ipv4.ihl, hdr.ipv4.frag_offset) {
            (6, 5, 0) : parse_tcp;
            (17, 5, 0) : parse_udp_vxlan;
            (1, 5, 0) : parse_icmp;
            (2, 5, 0) : parse_igmp;

            (4, 5, 0) : parse_inner_ipv4;
            (41, 5, 0) : parse_inner_ipv6;

            (_, 6, _) : parse_ipv4_options;
            default : accept;
        }
    }

    state parse_ipv4_no_tunnel {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol, hdr.ipv4.ihl, hdr.ipv4.frag_offset) {
            (6, 5, 0) : parse_tcp;
            (17, 5, 0) : parse_udp_no_vxlan;
            (1, 5, 0) : parse_icmp;
            (2, 5, 0) : parse_igmp;
            (_, 6, _) : parse_ipv4_options;
            default : accept;
        }
    }

    state parse_ipv4_options {
        pkt.extract(hdr.ipv4_option);
        transition select(hdr.ipv4.protocol) {
            (6) : parse_tcp;
            (17) : parse_udp_no_vxlan;
            (1) : parse_icmp;
            (2) : parse_igmp;
            default : accept;
        }
    }

    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            58 : parse_icmp;
            6 : parse_tcp;
            17 : parse_udp_no_vxlan;
//            IP_PROTOCOLS_GRE : parse_ip_gre;
//            IP_PROTOCOLS_IPV4 : parse_ipinip;
//            IP_PROTOCOLS_IPV6 : parse_ipv6inip;
            default : accept;
        }
    }

//    state parse_ip_gre {
//        pkt.extract(hdr.gre);
//        transition select(hdr.gre.flags_version, hdr.gre.proto) {
//            (_, GRE_PROTOCOLS_IP) : parse_inner_ipv4;
//            (_, GRE_PROTOCOLS_IPV6) : parse_inner_ipv6;
//            default : accept;
//        }
//    }

    state parse_udp_vxlan {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            udp_port_vxlan : parse_vxlan;
            default : accept;
        }
    }

    state parse_udp_no_vxlan {
        pkt.extract(hdr.udp);
        transition accept;
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
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
        transition select(hdr.inner_ipv4.protocol) {
            1 : parse_inner_icmp;
            6 : parse_inner_tcp;
            17 : parse_inner_udp;
            2 : parse_inner_igmp;
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

    state parse_inner_igmp {
        pkt.extract(hdr.inner_igmp);
        transition accept;
    }

}

//=========================================================================================
// Physical Ingress parser on the internal pipe (3rd stage of the logical ingress pipeline)
//=========================================================================================
parser SwitchIngressParser_1(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_local_metadata_t local_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum() tcp_checksum;
    Checksum() udp_checksum;

    @name(".ingress1_udp_port_vxlan")
    value_set<bit<16>>(1) udp_port_vxlan;
    @name(".ingress_pipe_cpu_port")
    value_set<switch_cpu_port_value_set_t>(1) recirc_port_cpu_hdr;

    state start {
        pkt.extract(ig_intr_md);
        local_md.ingress_port = ig_intr_md.ingress_port;
        transition parse_port_metadata;
    }

    state parse_port_metadata {
        // Parse port metadata produced by ibuf
        switch_fp_port_metadata_t port_md = port_metadata_unpack<switch_fp_port_metadata_t>(pkt);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
     0x8808 : parse_pfc;
            default : parse_fp_bridged_md;
        }
    }

    state parse_pfc {
 local_md.bypass = SWITCH_INGRESS_BYPASS_ALL;
        transition accept;
    }

    state parse_fp_bridged_md {
        pkt.extract(hdr.fp_bridged_md);
        local_md.bd = hdr.fp_bridged_md.ingress_bd_tt_myip[12:0];
        local_md.lkp.pkt_type = hdr.fp_bridged_md.pkt_type;
        local_md.flags.routed = hdr.fp_bridged_md.routed;

        local_md.ingress_timestamp = hdr.fp_bridged_md.timestamp;
        local_md.qos.tc = hdr.fp_bridged_md.tc;
        local_md.qos.qid = hdr.fp_bridged_md.qid_icos[4:0];
        local_md.qos.color = hdr.fp_bridged_md.color;
        local_md.qos.icos = hdr.fp_bridged_md.qid_icos[7:5];
        local_md.tunnel.terminate = (bool)hdr.fp_bridged_md.ingress_bd_tt_myip[13:13];

        local_md.flags.ipv4_checksum_err = hdr.fp_bridged_md.ipv4_checksum_err;
        local_md.flags.rmac_hit = hdr.fp_bridged_md.rmac_hit;
        local_md.flags.fib_drop = hdr.fp_bridged_md.fib_drop;
        local_md.flags.fib_lpm_miss = hdr.fp_bridged_md.fib_lpm_miss;
        local_md.multicast.hit = hdr.fp_bridged_md.multicast_hit;
        local_md.flags.acl_deny = hdr.fp_bridged_md.acl_deny;
        local_md.flags.copy_cancel = hdr.fp_bridged_md.copy_cancel;
        local_md.nat.nat_disable = hdr.fp_bridged_md.nat_disable;
        local_md.flags.myip = hdr.fp_bridged_md.ingress_bd_tt_myip[15:14];
        local_md.drop_reason = hdr.fp_bridged_md.drop_reason;
        local_md.hostif_trap_id = hdr.fp_bridged_md.hostif_trap_id;
        local_md.mirror.session_id = hdr.fp_bridged_md.mirror_session_id;

        transition select(hdr.ethernet.ether_type, ig_intr_md.ingress_port) {
            recirc_port_cpu_hdr : parse_cpu;
            (0x0800, _) : parse_ipv4;
            (0x0806, _) : parse_arp;
            (0x86dd, _) : parse_ipv6;
            (0x8100, _) : parse_vlan;
            (0x88A8, _) : parse_vlan;
            default : accept;
        }
    }

    state parse_cpu {
        pkt.extract(hdr.fabric);
        pkt.extract(hdr.cpu);
        local_md.bypass = hdr.cpu.reason_code;



        transition select(hdr.cpu.ether_type) {
            0x0800 : parse_ipv4;
            0x0806 : parse_arp;
            0x86dd : parse_ipv6;
            0x8100 : parse_vlan;
            0x88A8 : parse_vlan;



            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);

        tcp_checksum.subtract({hdr.ipv4.src_addr,hdr.ipv4.dst_addr});
        udp_checksum.subtract({hdr.ipv4.src_addr,hdr.ipv4.dst_addr});

        transition select(hdr.ipv4.protocol, hdr.ipv4.ihl, hdr.ipv4.frag_offset) {
            (6, 5, 0) : parse_tcp;
            (17, 5, 0) : parse_ipv4_udp;
            (1, 5, 0) : parse_icmp;
            (2, 5, 0) : parse_igmp;

            (4, 5, 0) : parse_inner_ipv4;
            (41, 5, 0) : parse_inner_ipv6;

            (_, 6, _) : parse_ipv4_options;
            default : accept;
        }
    }

    state parse_ipv4_options {
        // Only a single 32-bit option (e.g. router alert) is supported.
        pkt.extract(hdr.ipv4_option);
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (6, 5) : parse_tcp;
            (17, 5) : parse_ipv4_udp;
            (1, 5) : parse_icmp;
            (2, 5) : parse_igmp;
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

        tcp_checksum.subtract({hdr.ipv6.src_addr,hdr.ipv6.dst_addr});
        udp_checksum.subtract({hdr.ipv6.src_addr,hdr.ipv6.dst_addr});

        transition select(hdr.ipv6.next_hdr) {
            58 : parse_icmp;
            6 : parse_tcp;
            17 : parse_ipv6_udp;
//            IP_PROTOCOLS_GRE : parse_ip_gre;
//            IP_PROTOCOLS_IPV4 : parse_ipinip;
//            IP_PROTOCOLS_IPV6 : parse_ipv6inip;
            default : accept;
        }
    }

//    state parse_ip_gre {
//        pkt.extract(hdr.gre);
//        transition select(hdr.gre.flags_version, hdr.gre.proto) {
//            (_, GRE_PROTOCOLS_IP) : parse_inner_ipv4;
//            (_, GRE_PROTOCOLS_IPV6) : parse_inner_ipv6;
//            default : accept;
//        }
//    }

    state parse_ipv4_udp {
        pkt.extract(hdr.udp);

        udp_checksum.subtract_all_and_deposit(local_md.tcp_udp_checksum);
        udp_checksum.subtract({hdr.udp.checksum});
        udp_checksum.subtract({hdr.udp.src_port, hdr.udp.dst_port});

        transition select(hdr.udp.dst_port) {
            udp_port_vxlan : parse_vxlan;
            default : accept;
        }
    }

    state parse_ipv6_udp {
        pkt.extract(hdr.udp);

        udp_checksum.subtract_all_and_deposit(local_md.tcp_udp_checksum);
        udp_checksum.subtract({hdr.udp.checksum});
        udp_checksum.subtract({hdr.udp.src_port, hdr.udp.dst_port});

 transition accept;
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);

        tcp_checksum.subtract_all_and_deposit(local_md.tcp_udp_checksum);
        tcp_checksum.subtract({hdr.tcp.checksum});
        tcp_checksum.subtract({hdr.tcp.src_port, hdr.tcp.dst_port});

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
        transition select(hdr.inner_ipv4.protocol) {
            1 : parse_inner_icmp;
            6 : parse_inner_tcp;
            17 : parse_inner_udp;
            2 : parse_inner_igmp;
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

    state parse_inner_igmp {
        pkt.extract(hdr.inner_igmp);
        transition accept;
    }

}

//============================================================================
// Physical Egress parser on the external pipe (Also logical external pipe)
//============================================================================
parser SwitchEgressParser_0(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_local_metadata_t local_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    @name(".egress_udp_port_vxlan")
    value_set<bit<16>>(1) udp_port_vxlan;
    @name(".egress_cpu_port")
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;
    @name(".egress_nvgre_st_key")
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



            (_, SWITCH_PKT_SRC_BRIDGED, _) : parse_bridged_pkt;
            (_, SWITCH_PKT_SRC_CLONED_INGRESS, 1) : parse_port_mirrored_with_fp_bridged_metadata;
            (_, SWITCH_PKT_SRC_CLONED_EGRESS, 1) : parse_port_mirrored_metadata;
            (_, SWITCH_PKT_SRC_CLONED_EGRESS, 2) : parse_cpu_mirrored_metadata;






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




        local_md.lkp.pkt_type = hdr.bridged_md.base.pkt_type;
        local_md.ingress_timestamp = hdr.bridged_md.base.timestamp;
        local_md.qos.tc = hdr.bridged_md.base.tc;
        local_md.qos.qid = hdr.bridged_md.base.qid;
        local_md.qos.color = hdr.bridged_md.base.color;
        local_md.vrf = hdr.bridged_md.base.vrf;


        local_md.tunnel_nexthop = hdr.bridged_md.tunnel.tunnel_nexthop;
        local_md.tunnel.type = 0;

        local_md.tunnel.hash = hdr.bridged_md.tunnel.hash;




        local_md.tunnel.terminate = hdr.bridged_md.tunnel.terminate;






        transition parse_ethernet;
    }
# 1111 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/parde_fp.p4"
    state parse_port_mirrored_with_fp_bridged_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        // pkt is mirrored on internal pipe,
        // so extract internal headers before parsing pkt
        pkt.extract(hdr.ethernet);
        pkt.advance(sizeInBytes(hdr.fp_bridged_md) * 8);
        local_md.pkt_src = port_md.src;
        local_md.mirror.session_id = port_md.session_id;
        local_md.ingress_timestamp = port_md.timestamp;
        local_md.flags.bypass_egress = true;

        local_md.mirror.type = port_md.type;





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
# 1312 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/parde_fp.p4"
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
            (0x88A8, _) : parse_vlan;



     (0x8808, _) : parse_pfc;
            default : accept;
        }
    }

    state parse_pfc {
        local_md.flags.bypass_egress = true;
        transition accept;
    }

    state parse_cpu {
        local_md.flags.bypass_egress = true;
        transition accept;
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        local_md.qos.pcp = hdr.vlan_tag.last.pcp;
        transition select(hdr.vlan_tag.last.ether_type) {
            0x0800 : parse_ipv4;
            0x8100 : parse_vlan;
            0x86dd : parse_ipv6;



            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol, hdr.ipv4.ihl, hdr.ipv4.frag_offset) {
            (6, 5, 0) : parse_tcp;
            (17, 5, 0) : parse_ipv4_udp;
            (1, 5, 0) : parse_icmp;
            (2, 5, 0) : parse_igmp;




            (_, 6, _) : parse_ipv4_options;
            default : accept;
        }
    }

    state parse_ipv4_options {
        pkt.extract(hdr.ipv4_option);
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (6, 5) : parse_tcp;
            (17, 5) : parse_ipv4_udp;
            (1, 5) : parse_icmp;
            (2, 5) : parse_igmp;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            17 : parse_ipv6_udp;
            6 : parse_tcp;
            58: parse_icmp;
# 1397 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/parde_fp.p4"
            default : accept;
        }
    }
# 1433 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/parde_fp.p4"
    state parse_ip_gre {
        pkt.extract(hdr.gre);
        transition select(hdr.gre.flags_version, hdr.gre.proto) {



            //(_, GRE_PROTOCOLS_IP) : parse_inner_ipv4;
            //(_, GRE_PROTOCOLS_IPV6) : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_ipv4_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {



            default : accept;
        }
    }

    state parse_ipv6_udp {
        pkt.extract(hdr.udp);
        transition accept;
    }

    state parse_tcp {
        tcp_h tcp_md = pkt.lookahead<tcp_h>();
        local_md.lkp.l4_src_port = tcp_md.src_port;
        local_md.lkp.l4_dst_port = tcp_md.dst_port;
        local_md.lkp.tcp_flags = tcp_md.flags;
        transition accept;
    }

    state parse_icmp {
        icmp_h icmp_md = pkt.lookahead<icmp_h>();
        local_md.lkp.l4_src_port[7:0] = icmp_md.type;
        local_md.lkp.l4_src_port[15:8] = icmp_md.code;
        transition accept;
    }

    state parse_igmp {
        igmp_h igmp_md = pkt.lookahead<igmp_h>();
        local_md.lkp.l4_src_port[7:0] = igmp_md.type;
        local_md.lkp.l4_src_port[15:8] = 0;
        transition accept;
    }
# 1531 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/parde_fp.p4"
}


//############################################################################
// Mirror packet deparser
//############################################################################
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
                (MirrorId_t)local_md.mirror.session_id,
                {local_md.mirror.src,
                 local_md.mirror.type,
                 local_md.timestamp,





                 local_md.mirror.session_id,
                 0,
                 local_md.ingress_port});

        } else if (ig_intr_md_for_dprsr.mirror_type == 3) {
# 1584 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/parde_fp.p4"
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
            mirror.emit<switch_port_mirror_metadata_h>((MirrorId_t)local_md.mirror.session_id, {
                local_md.mirror.src,
                local_md.mirror.type,
                local_md.ingress_timestamp,





                local_md.mirror.session_id,
                 0,
                 local_md.ingress_port});
        } else if (eg_intr_md_for_dprsr.mirror_type == 2) {
            mirror.emit<switch_cpu_mirror_metadata_h>((MirrorId_t)local_md.mirror.session_id, {
                local_md.mirror.src,
                local_md.mirror.type,
                0,
                local_md.ingress_port,
  0,
                local_md.bd,
                0,
                local_md.egress_port_lag_index,
                local_md.cpu_reason});
        } else if (eg_intr_md_for_dprsr.mirror_type == 4) {
# 1644 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/parde_fp.p4"
        } else if (eg_intr_md_for_dprsr.mirror_type == 3) {
# 1665 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/parde_fp.p4"
        } else if (eg_intr_md_for_dprsr.mirror_type == 5) {
# 1676 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/parde_fp.p4"
        }

    }
}

//############################################################################
// L4 Checksum update
//############################################################################

control IngressNatChecksum(
    inout switch_header_t hdr,
    in switch_local_metadata_t local_md) {
    Checksum() tcp_checksum;
    Checksum() udp_checksum;
    apply {

        if (hdr.ipv4.isValid()) {
            if(hdr.tcp.isValid()) {
              hdr.tcp.checksum = tcp_checksum.update({
                      local_md.lkp.ip_src_addr,
                      local_md.lkp.ip_dst_addr,
                      hdr.tcp.src_port,
                      hdr.tcp.dst_port,
                      local_md.tcp_udp_checksum});
            } else if(hdr.udp.isValid()) {
              hdr.udp.checksum = udp_checksum.update({
                      local_md.lkp.ip_src_addr,
                      local_md.lkp.ip_dst_addr,
                      hdr.udp.src_port,
                      hdr.udp.dst_port,
                      local_md.tcp_udp_checksum});
            }
        }

    }
}

//############################################################################-
// Ingress Deparser on External pipe
//############################################################################-
control SwitchIngressDeparser_0(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_local_metadata_t local_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    @name(".learning_digest")
    Digest<switch_learning_digest_t>() digest;
    Checksum() ipv4_checksum;

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
            hdr.ipv4.dst_addr,
            hdr.ipv4_option.type,
            hdr.ipv4_option.length,
            hdr.ipv4_option.value});

        if (ig_intr_md_for_dprsr.digest_type == SWITCH_DIGEST_TYPE_MAC_LEARNING) {
            digest.pack({local_md.bd, local_md.ingress_port_lag_index, hdr.ethernet.src_addr});
        }

        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.fp_bridged_md);
        pkt.emit(hdr.fabric);
        pkt.emit(hdr.cpu);
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
//        pkt.emit(hdr.inner_udp);
//        pkt.emit(hdr.inner_tcp);
//        pkt.emit(hdr.inner_icmp);
    }
}


//############################################################################-
// Ingress Deparser on the internal pipe
//############################################################################-
control SwitchIngressDeparser_1(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_local_metadata_t local_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    IngressMirror() mirror;

    IngressNatChecksum() nat_checksum;


    apply {
        mirror.apply(hdr, local_md, ig_intr_md_for_dprsr);


        nat_checksum.apply(hdr,local_md);


        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv4_option);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.icmp);
        pkt.emit(hdr.igmp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.gre);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_icmp);
        pkt.emit(hdr.inner_igmp);
    }
}


//############################################################################-
// Egress Deparser on pipe with external facing ports
//############################################################################-
control SwitchEgressDeparser_0(
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


        if (local_md.inner_ipv4_checksum_update_en) {
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


        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.fabric); // Egress only.
        pkt.emit(hdr.cpu); // Egress only.
        pkt.emit(hdr.timestamp); // Egress only.
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv4_option);
        pkt.emit(hdr.ipv6);







        pkt.emit(hdr.tcp);
        pkt.emit(hdr.udp);



        pkt.emit(hdr.icmp); // Egress only.
        pkt.emit(hdr.igmp); // Egress only.







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

//############################################################################-
// Egress Deparser on Internal Pipe
//############################################################################-
control SwitchEgressDeparser_1(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_local_metadata_t local_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.fp_bridged_md);
        pkt.emit(hdr.fabric);
        pkt.emit(hdr.cpu);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv4_option);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.icmp);
        pkt.emit(hdr.igmp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.gre);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_icmp);
        pkt.emit(hdr.inner_igmp);
    }
}
# 199 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/port.p4" 1
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


# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4" 1

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





# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/l2.p4" 1
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
# 25 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4" 2

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
        // hdr.vlan_tag[0].dei = 0;
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
        hdr.ipv6.setInvalid();
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

    action add_erspan_type3(bit<10> session_id,



 bit<32> timestamp) {
        add_erspan_common(0x2000, session_id);
        hdr.erspan_type3.setValid();
        hdr.erspan_type3.timestamp = timestamp;
        hdr.erspan_type3.ft_d_other = 0x4; // timestamp granularity IEEE 1588







    }

    //
    // ----------------  QID rewrite ----------------
    //
    @name(".rewrite_")
    action rewrite_(switch_qid_t qid) {
        local_md.qos.qid = qid;
    }
# 143 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4"
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



        add_erspan_type3((bit<10>)local_md.mirror.session_id, (bit<32>)local_md.ingress_timestamp);

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



        add_erspan_type3((bit<10>)local_md.mirror.session_id, (bit<32>)local_md.ingress_timestamp);

        add_gre_header(0x22EB);

        // Total length = packet length + 36
        //   IPv4 (20) + GRE (4) + Erspan (12)
        add_ipv4_header(tos, ttl, 47, sip, dip);

        hdr.ipv4.total_len = local_md.pkt_length + 16w36;



        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, ether_type);
        add_vlan_tag(vid, pcp, 0x0800);
    }
# 405 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4"
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
# 436 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4"
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


    action adjust_length_with_fp_b_md(){
        // -29[-(4 bytes of CRC + 4 bytes of timestamp + 1 byte of pkt_src + 1 byte of mirror_type
        //       + 2 bytes of ingress_port + len(session_id), + len(switch_fp_bridged_metadata_h))]
        // -[len of switch_fp_bridged_metadata_h]
        switch_fp_bridged_metadata_h fp_b_md;
        switch_mirror_session_t session_id;
        switch_pkt_length_t length_offset = (0xFFF4 - (bit<16>)sizeInBytes(session_id) - (bit<16>)sizeInBytes(fp_b_md));
        local_md.pkt_length = local_md.pkt_length + length_offset;
        local_md.mirror.type = 0;
    }
# 487 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4"
    table pkt_length {
        key = {
                local_md.mirror.type : exact;

                local_md.pkt_src : ternary;

        }
        actions = {
                adjust_length;




                adjust_length_with_fp_b_md;

        }
        const entries = {

            //-14
            (2, _) : adjust_length(0xFFF2);
# 526 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4"
            /* - len(switch_port_mirror_metadata_h) - 4 bytes of CRC */
            //-13
            (1, SWITCH_PKT_SRC_CLONED_INGRESS): adjust_length_with_fp_b_md();
            (1, SWITCH_PKT_SRC_CLONED_EGRESS): adjust_length(0xFFF3);
            /* len(telemetry report v0.5 header)
             * + len(telemetry drop report header)
             * - len(switch_dtel_drop_mirror_metadata_h) - 4 bytes of CRC */
            (3, _) : adjust_length(0x1);
            /* len(telemetry report v0.5 header)
             * + len(telemetry switch local report header)
             * - len(switch_dtel_switch_local_mirror_metadata_h)
             * - 4 bytes of CRC */
            //-1
           (4, _) : adjust_length(0xFFFF);

            /* - len(switch_simple_mirror_metadata_h) - 4 bytes of CRC */
            //-8
           (5, _): adjust_length(0xFFF8);
# 567 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4"
            /* len(telemetry report v0.5 header)
             * + len(telemetry drop report header) - 4 bytes of CRC */
            (255, _): adjust_length(20);
# 638 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4"
        }
    }

    action rewrite_ipv4_udp_len_truncate() {
# 653 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4"
    }
# 674 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4"
    apply {

        if (local_md.pkt_src != SWITCH_PKT_SRC_BRIDGED) {

            pkt_length.apply();

            rewrite.apply();
# 691 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4"
 }

    }
}
# 21 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/port.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/rmac.p4" 1
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
//        local_md.flags.rmac_hit = false;
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
# 22 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/port.p4" 2

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

        mirror_md.meter_index = (switch_mirror_meter_id_t)meter_index;

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
        inout switch_local_metadata_t local_md)(
        switch_uint32_t table_size=288) {

    @name(".set_egress_mirror_id")
    action set_egress_mirror_id(switch_mirror_session_t session_id, switch_mirror_meter_id_t meter_index) {
        local_md.mirror.type = 1;
        local_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        local_md.mirror.session_id = session_id;

        local_md.mirror.meter_index = (switch_mirror_meter_id_t)meter_index;

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

//-----------------------------------------------------------------------------
// Ingress port mapping
//-----------------------------------------------------------------------------
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

    // This register is used to check whether a port is a member of a vlan (bd)
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
        ig_intr_md_for_tm.qid = (switch_qid_t) hdr.cpu.egress_queue;


        hdr.fp_bridged_md.fwd_type = SWITCH_FWD_TYPE_L2;
        hdr.fp_bridged_md.fwd_idx = (switch_fwd_idx_t)hdr.cpu.port_lag_index;






    }

    @name(".set_cpu_port_properties")
    action set_cpu_port_properties(
            switch_port_lag_index_t port_lag_index,
            switch_ig_port_lag_label_t port_lag_label,
            switch_yid_t exclusion_id,
            switch_pkt_color_t color,
            switch_tc_t tc) {
        local_md.ingress_port_lag_index = port_lag_index;
        local_md.ingress_port_lag_label = port_lag_label;
        local_md.qos.color = color;
        local_md.qos.tc = tc;
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;

        terminate_cpu_packet();
    }

    @name(".set_port_properties")
    action set_port_properties(
            switch_yid_t exclusion_id,
            switch_learning_mode_t learning_mode,
            switch_pkt_color_t color,
            switch_tc_t tc,
            switch_port_meter_id_t meter_index,
            switch_sflow_id_t sflow_session_id,
            bool mac_pkt_class,
            switch_ports_group_label_t in_ports_group_label_ipv4,
            switch_ports_group_label_t in_ports_group_label_ipv6,
            switch_ports_group_label_t in_ports_group_label_mirror) {
        local_md.qos.color = color;
        local_md.qos.tc = tc;
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
        local_md.learning.port_mode = learning_mode;

        local_md.checks.same_if = SWITCH_FLOOD;

        local_md.flags.mac_pkt_class = mac_pkt_class;

        local_md.qos.port_meter_index = meter_index;


        local_md.sflow.session_id = sflow_session_id;
# 190 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/port.p4"
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
                             bool vlan_arp_suppress,
                             switch_packet_action_t vrf_ttl_violation,
                             bool vrf_ttl_violation_valid,
                             switch_packet_action_t vrf_ip_options_violation,
                             bool vrf_unknown_l3_multicast_trap,
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
        local_md.flags.vlan_arp_suppress = vlan_arp_suppress;
        local_md.ingress_outer_bd = bd;



        local_md.vrf = vrf;
        local_md.flags.vrf_ttl_violation = vrf_ttl_violation;
        local_md.flags.vrf_ttl_violation_valid = vrf_ttl_violation_valid;
        local_md.flags.vrf_ip_options_violation = vrf_ip_options_violation;
        local_md.flags.vrf_unknown_l3_multicast_trap = vrf_unknown_l3_multicast_trap;
        local_md.stp.group = stp_group;
        local_md.multicast.rpf_group = mrpf_group;
        local_md.learning.bd_mode = learning_mode;
        local_md.ipv4.unicast_enable = ipv4_unicast_enable;
        local_md.ipv4.multicast_enable = ipv4_multicast_enable;
        local_md.ipv4.multicast_snooping = igmp_snooping_enable;
        local_md.ipv6.unicast_enable = ipv6_unicast_enable;
        local_md.ipv6.multicast_enable = ipv6_multicast_enable;
        local_md.ipv6.multicast_snooping = mld_snooping_enable;




        local_md.nat.ingress_zone = zone;

    }
# 293 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/port.p4"
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

    apply {




        switch (port_mapping.apply().action_run) {






            set_port_properties : {



                    if (!port_vlan_to_bd_mapping.apply().hit) {
                        if (hdr.vlan_tag[0].isValid())
                            vlan_to_bd_mapping.apply();
                    }
# 388 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/port.p4"
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

//-----------------------------------------------------------------------------
// Snake for testing
//-----------------------------------------------------------------------------
# 419 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/port.p4"
//---------------------------------------------------------------------------------------------------------
// Ingress Port IP statistics
//---------------------------------------------------------------------------------------------------------
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

control IngressPortStats(
    in switch_header_t hdr,
    in switch_port_t port,
    in bit<1> drop, in bit<1> copy_to_cpu) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

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

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

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

// ----------------------------------------------------------------------------
// Link Aggregation (LAG) resolution
//
// @param local_md : Ingress metadata fields.
// @param hash : Hash value used for port selection.
// @param egress_port : Egress port.
//
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

    @name(".lag_miss")
    action lag_miss() { }

    @name(".lag_table")
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
                           switch_port_meter_id_t meter_index,
                           switch_sflow_id_t sflow_session_id,
                           switch_ports_group_label_t out_ports_group_label_ipv4,
                           switch_ports_group_label_t out_ports_group_label_ipv6) {

        /* Note: egress_port_lag_index carries ingress_port_lag_index at this point in the pipeline */
        local_md.checks.same_if = local_md.egress_port_lag_index ^ port_lag_index;

        local_md.egress_port_lag_index = port_lag_index;
        local_md.egress_port_lag_label = port_lag_label;

        local_md.qos.port_meter_index = meter_index;
# 605 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/port.p4"
    }

    @name(".set_port_cpu")
    action set_port_cpu() {
        local_md.flags.to_cpu = true;
    }

    @name(".egress_port_mapping")
    table port_mapping {
        key = { port : exact; }

        actions = {
            set_port_normal;
            set_port_cpu;
        }

        size = table_size;
    }


    @name(".set_egress_ingress_port_properties")
    action set_egress_ingress_port_properties(switch_isolation_group_t port_isolation_group, switch_isolation_group_t bport_isolation_group) {
        local_md.port_isolation_group = port_isolation_group;
        local_md.bport_isolation_group = bport_isolation_group;
    }

    @name(".egress_ingress_port_mapping")
    table egress_ingress_port_mapping {
        key = {
            local_md.ingress_port : exact;
        }

        actions = {



            set_egress_ingress_port_properties;
        }





        const default_action = set_egress_ingress_port_properties(0, 0);
        size = 2<<9;

    }


    apply {
        port_mapping.apply();


        egress_ingress_port_mapping.apply();

    }
}


//-----------------------------------------------------------------------------
// Egress port isolation
//
// @param hdr : Parsed headers.
// @param local_md : Egress metadata fields.
// @param port : Egress port.
//
//-----------------------------------------------------------------------------
control EgressPortIsolation(
        inout switch_local_metadata_t local_md,
        in egress_intrinsic_metadata_t eg_intr_md)(
        switch_uint32_t table_size=288) {

    @name(".isolate_packet_port")
    action isolate_packet_port(bool drop) {
        local_md.flags.port_isolation_packet_drop = drop;
    }

    @name(".egress_port_isolation")
    table egress_port_isolation {
        key = {
            eg_intr_md.egress_port : exact;
            local_md.port_isolation_group : exact;
        }

        actions = {
            isolate_packet_port;
        }

        const default_action = isolate_packet_port(false);

        size = 2048;



    }

    @name(".isolate_packet_bport")
    action isolate_packet_bport(bool drop) {
        local_md.flags.bport_isolation_packet_drop = drop;
    }

    @name(".egress_bport_isolation")
    table egress_bport_isolation {
        key = {
            eg_intr_md.egress_port : exact;
            local_md.flags.routed : exact;
            local_md.bport_isolation_group : exact;
        }

        actions = {
            isolate_packet_bport;
        }

        const default_action = isolate_packet_bport(false);

        size = 4096;



    }

    apply {
        egress_port_isolation.apply();
        egress_bport_isolation.apply();
    }
}


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


//-----------------------------------------------------------------------------
// Port/BD State for internal pipe
//-----------------------------------------------------------------------------

control PortBDState_IG_1(
    inout switch_header_t hdr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    inout switch_local_metadata_t local_md) {

    action set_port_state(
            switch_port_lag_index_t port_lag_index,
            switch_ig_port_lag_label_t port_lag_label,
            switch_yid_t exclusion_id,
            switch_port_meter_id_t meter_index,
            switch_sflow_id_t sflow_session_id) {
        local_md.ingress_port_lag_index = port_lag_index;
        local_md.ingress_port_lag_label = port_lag_label;
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;

        local_md.checks.same_if = SWITCH_FLOOD;


        local_md.qos.port_meter_index = meter_index;


        local_md.sflow.session_id = sflow_session_id;

        local_md.ingress_port = local_md.ingress_port ^ 0x80;
    }

    action set_cpu_port_state(
            switch_port_lag_index_t port_lag_index,
            switch_ig_port_lag_label_t port_lag_label,
            switch_yid_t exclusion_id,
            switch_port_meter_id_t meter_index,
            switch_sflow_id_t sflow_session_id) {
        local_md.ingress_port_lag_index = port_lag_index;
        local_md.ingress_port_lag_label = port_lag_label;
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;

        local_md.checks.same_if = SWITCH_FLOOD;


        local_md.qos.port_meter_index = meter_index;


        local_md.sflow.session_id = sflow_session_id;

        local_md.flags.bypass_egress = (bool) hdr.cpu.tx_bypass;
        local_md.ingress_port = hdr.cpu.ingress_port[8:0];
        hdr.ethernet.ether_type = hdr.cpu.ether_type;
    }

    /* Ingress VLAN/RIF Properties */
    action set_bd_properties(switch_bd_label_t bd_label,
                             bool ipv4_unicast_enable,
                             bool ipv4_multicast_enable,
                             bool igmp_snooping_enable,
                             bool ipv6_unicast_enable,
                             bool ipv6_multicast_enable,
                             bool mld_snooping_enable,
                             bool mpls_enable,
                             bool vlan_arp_suppress,
                             switch_vrf_t vrf,
                             switch_packet_action_t vrf_ttl_violation,
                             bool vrf_ttl_violation_valid,
                             switch_packet_action_t vrf_ip_options_violation,
                             switch_nat_zone_t zone) {



        local_md.flags.vlan_arp_suppress = vlan_arp_suppress;
        local_md.ipv4.unicast_enable = ipv4_unicast_enable;
        local_md.ipv4.multicast_enable = ipv4_multicast_enable;
        local_md.ipv4.multicast_snooping = igmp_snooping_enable;
        local_md.ipv6.unicast_enable = ipv6_unicast_enable;
        local_md.ipv6.multicast_enable = ipv6_multicast_enable;
        local_md.ipv6.multicast_snooping = mld_snooping_enable;
        local_md.vrf = vrf;
        local_md.flags.vrf_ttl_violation = vrf_ttl_violation;
        local_md.flags.vrf_ttl_violation_valid = vrf_ttl_violation_valid;
        local_md.flags.vrf_ip_options_violation = vrf_ip_options_violation;




        local_md.nat.ingress_zone = zone;

    }

    table port_state {
        key = {
            local_md.ingress_port : exact;
        }

        actions = {
            set_port_state();
            set_cpu_port_state();
        }

        const default_action = set_port_state(0, 0, 0, 0, 0);
        size = 512;
    }


    table bd_state {
        key = { local_md.bd[12:0] : exact; }

        actions = {
            set_bd_properties();
        }

        const default_action = set_bd_properties(0, false, false, false, false, false, false, false, false, 0, 0, false, 0, 0);
        size = 8192;
    }

    apply {
        port_state.apply();
        bd_state.apply();
    }
}


control PortBDState_EG_1(inout switch_header_t hdr, inout switch_local_metadata_t local_md) {

    action set_port_state(
            switch_port_lag_index_t port_lag_index,
            switch_ig_port_lag_label_t port_lag_label) {
        local_md.ingress_port_lag_index = port_lag_index;
        local_md.ingress_port_lag_label = port_lag_label;
        local_md.ingress_port = local_md.ingress_port ^ 0x80;
        local_md.bd = hdr.fp_bridged_md.ingress_bd_tt_myip[12:0];
        local_md.lkp.pkt_type = hdr.fp_bridged_md.pkt_type;
        local_md.flags.routed = hdr.fp_bridged_md.routed;
        local_md.qos.tc = hdr.fp_bridged_md.tc;
        local_md.qos.qid = hdr.fp_bridged_md.qid_icos[4:0];
        local_md.qos.color = hdr.fp_bridged_md.color;
        local_md.qos.icos = hdr.fp_bridged_md.qid_icos[7:5];
        local_md.flags.acl_deny = hdr.fp_bridged_md.acl_deny;
        local_md.nat.nat_disable = hdr.fp_bridged_md.nat_disable;
        local_md.hostif_trap_id = hdr.fp_bridged_md.hostif_trap_id;
        local_md.mirror.session_id = hdr.fp_bridged_md.mirror_session_id;
        local_md.flags.rmac_hit = hdr.fp_bridged_md.rmac_hit;
    }

    action set_cpu_port_state(
            switch_port_lag_index_t port_lag_index,
            switch_ig_port_lag_label_t port_lag_label) {
        local_md.ingress_port_lag_index = port_lag_index;
        local_md.ingress_port_lag_label = port_lag_label;
        local_md.ingress_port = hdr.cpu.ingress_port[8:0];
    }

//    /* Ingress VLAN/RIF Properties */
//    action set_bd_properties(switch_bd_label_t bd_label,
//                             bool ipv4_unicast_enable,
//                             bool ipv4_multicast_enable,
//                             bool igmp_snooping_enable,
//                             bool ipv6_unicast_enable,
//                             bool ipv6_multicast_enable,
//                             bool mld_snooping_enable,
//                             bool mpls_enable,
//                             bool vlan_arp_suppress,
//                             switch_vrf_t vrf,
//                             switch_packet_action_t vrf_ttl_violation,
//                             bool vrf_ttl_violation_valid,
//                             switch_packet_action_t vrf_ip_options_violation,
//                             switch_nat_zone_t zone) {
//#ifdef INGRESS_ACL_BD_LABEL_ENABLE
//        local_md.bd_label = bd_label;
//#endif
//        local_md.flags.vlan_arp_suppress = vlan_arp_suppress;
//        local_md.ipv4.unicast_enable = ipv4_unicast_enable;
//        local_md.ipv4.multicast_enable = ipv4_multicast_enable;
//        local_md.ipv4.multicast_snooping = igmp_snooping_enable;
//        local_md.ipv6.unicast_enable = ipv6_unicast_enable;
//        local_md.ipv6.multicast_enable = ipv6_multicast_enable;
//        local_md.ipv6.multicast_snooping = mld_snooping_enable;
//        local_md.vrf = vrf;
//        local_md.flags.vrf_ttl_violation = vrf_ttl_violation;
//        local_md.flags.vrf_ttl_violation_valid = vrf_ttl_violation_valid;
//        local_md.flags.vrf_ip_options_violation = vrf_ip_options_violation;
//#ifdef MPLS_ENABLE
//        local_md.mpls_enable = mpls_enable;
//#endif
//#ifdef NAT_ENABLE
//        local_md.nat.ingress_zone = zone;
//#endif
//    }
//

    table port_state {
        key = {
            local_md.ingress_port : exact;
        }

        actions = {
            set_port_state();
            set_cpu_port_state();
        }

        const default_action = set_port_state(0, 0);
        size = 512;
    }

//    /* CODE_HACK workaround for p4-4516. This table is instantiated in both ingress and egress pipes, and
//       due to a compiler bug, hash function for the egress table was not being generated */
//    @use_hash_action(0)
//    table bd_state {
//        key = { local_md.bd[12:0] : exact; }
//
//        actions = {
//            set_bd_properties();
//        }
//
//        const default_action = set_bd_properties(0, false, false, false, false, false, false, false, false, 0, 0, false, 0, 0);
//        size = 8192;
//    }

    apply {
        port_state.apply();
//        bd_state.apply();
    }
}

//-----------------------------------------------------------------------------
//
// Demux for fwd_type/fwd_idx in ingress_0
//
//-----------------------------------------------------------------------------

control FwdIdxDemux(in switch_header_t hdr, inout switch_local_metadata_t local_md) {

    action set_nexthop() {
        local_md.nexthop = hdr.fp_bridged_md.fwd_idx;
    }
    action set_multicast_id() {
        local_md.multicast.id = hdr.fp_bridged_md.fwd_idx;
    }
    action set_egress_port_lag_index() {
        local_md.egress_port_lag_index = hdr.fp_bridged_md.fwd_idx[9:0];
    }

    table fwd_idx_demux {
        key = {
            hdr.fp_bridged_md.fwd_type : exact;
        }
        actions = {
     NoAction;
            set_nexthop;
            set_multicast_id;
            set_egress_port_lag_index;
        }
        size = 4;
        const default_action = NoAction;
        const entries = {
            (SWITCH_FWD_TYPE_NONE) : NoAction;
            (SWITCH_FWD_TYPE_L2) : set_egress_port_lag_index;
            (SWITCH_FWD_TYPE_L3) : set_nexthop;
            (SWITCH_FWD_TYPE_MC) : set_multicast_id;
        }
    }

    apply {
        fwd_idx_demux.apply();
    }
}
# 200 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/validation_fp.p4" 1
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

// ============================================================================
//
// Outer Packet validation
// Validate ethernet, Ipv4 or Ipv6 headers and set the common lookup fields.
// Check for malformed packets and set pkt_type
//
//===============================================================================

control PktValidation(
        in switch_header_t hdr,
        inout switch_local_metadata_t local_md) {
    const switch_uint32_t table_size = MIN_TABLE_SIZE;

    //-----------------------------------------------------------------------------
    // Validate outer L2/L3 header
    // - Drop the packet if src addr is zero or multicast or dst addr is zero.
    // Check for malformed packets and set pkt_type
    //-----------------------------------------------------------------------------
    action valid_ethernet_pkt(switch_pkt_type_t pkt_type) {
        local_md.lkp.pkt_type = pkt_type;
        local_md.lkp.mac_src_addr = hdr.ethernet.src_addr;
        local_md.lkp.mac_dst_addr = hdr.ethernet.dst_addr;
    }

    @name(".fp_malformed_eth_pkt")
    action malformed_eth_pkt(bit<8> reason) {
        local_md.lkp.mac_type = hdr.ethernet.ether_type;
        local_md.lkp.mac_src_addr = hdr.ethernet.src_addr;
        local_md.lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        local_md.l2_drop_reason = reason;
    }

    @name(".fp_valid_pkt_untagged")
    action valid_pkt_untagged(switch_pkt_type_t pkt_type) {
        local_md.lkp.mac_type = hdr.ethernet.ether_type;
        valid_ethernet_pkt(pkt_type);
    }

    @name(".fp_valid_pkt_tagged")
    action valid_pkt_tagged(switch_pkt_type_t pkt_type) {
        local_md.lkp.mac_type = hdr.vlan_tag[0].ether_type;
        local_md.lkp.pcp = hdr.vlan_tag[0].pcp;
        local_md.lkp.dei = hdr.vlan_tag[0].dei;
        valid_ethernet_pkt(pkt_type);
    }

    @name(".fp_valid_pkt_double_tagged")
    action valid_pkt_double_tagged(switch_pkt_type_t pkt_type) {
        local_md.lkp.mac_type = hdr.vlan_tag[1].ether_type;
        local_md.lkp.pcp = hdr.vlan_tag[1].pcp;
        local_md.lkp.dei = hdr.vlan_tag[1].dei;
        valid_ethernet_pkt(pkt_type);
    }

    @name(".fp_validate_ethernet")
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

    @name(".fp_valid_arp_pkt")
    action valid_arp_pkt() {






        local_md.lkp.arp_opcode = hdr.arp.opcode;
    }

    // IP Packets
    @name(".fp_valid_ipv6_pkt")
    action valid_ipv6_pkt(bool is_link_local) {
        // Set common lookup fields
        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        local_md.lkp.ip_tos = hdr.ipv6.traffic_class;
        local_md.lkp.ip_src_addr = hdr.ipv6.src_addr;
        local_md.lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        local_md.flags.link_local = is_link_local;
        local_md.lkp.ip_proto = hdr.ipv6.next_hdr;
    }

    @name(".fp_valid_ipv4_pkt")
    action valid_ipv4_pkt(switch_ip_frag_t ip_frag, bool is_link_local) {
        // Set common lookup fields
        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        local_md.lkp.ip_tos = hdr.ipv4.diffserv;
        local_md.lkp.ip_src_addr[95:64] = hdr.ipv4.src_addr;
        local_md.lkp.ip_dst_addr[95:64] = hdr.ipv4.dst_addr;
        local_md.lkp.ip_frag = ip_frag;
        local_md.flags.link_local = is_link_local;
        local_md.lkp.ip_proto = hdr.ipv4.protocol;
    }

    @name(".fp_malformed_ipv4_pkt")
    action malformed_ipv4_pkt(bit<8> reason, switch_ip_frag_t ip_frag) {
        // Set common lookup fields just for dtel acl and hash purposes
        valid_ipv4_pkt(ip_frag, false);
        local_md.drop_reason = reason;
    }

    @name(".fp_malformed_ipv6_pkt")
    action malformed_ipv6_pkt(bit<8> reason) {
        // Set common lookup fields just for dtel acl and hash purposes
        valid_ipv6_pkt(false);
        local_md.drop_reason = reason;
    }
# 182 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/validation_fp.p4"
    @name(".fp_validate_ip")
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

    apply {
        validate_ethernet.apply();
        validate_ip.apply();
    }
}

// ============================================================================
// Same MAC Check
// Checks if source mac address matches with destination mac address
// ============================================================================
control SameMacCheck(in switch_header_t hdr, inout switch_local_metadata_t local_md) {

    apply {
        if (!local_md.tunnel.terminate) {
            if (hdr.ethernet.src_addr[31:0] == hdr.ethernet.dst_addr[31:0]) {
                if (hdr.ethernet.src_addr[47:32] == hdr.ethernet.dst_addr[47:32]) {
                    local_md.drop_reason = SWITCH_DROP_REASON_OUTER_SAME_MAC_CHECK;
                }
            }
        }
    }
}

// ============================================================================
// Inner packet validation
// Validate ethernet, Ipv4 or Ipv6 common lookup fields.
// NOTE:
// For IPinIP packets, the actions are valid_ipv*. This would set the L2
// lookup fields to 0. The RMAC table is setup to ignore the dmac to process
// these packets
// ============================================================================
control InnerPktValidation(
        in switch_header_t hdr,
        inout switch_local_metadata_t local_md) {

    @name(".valid_inner_ethernet_pkt")
    action valid_ethernet_pkt(switch_pkt_type_t pkt_type) {
        local_md.lkp.pkt_type = pkt_type;
        local_md.lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        local_md.lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
        /* Note: Inner packet with vlan tag is not supported */
        local_md.lkp.mac_type = hdr.inner_ethernet.ether_type;
    }

    @name(".valid_inner_ipv4_pkt")
    action valid_ipv4_pkt(switch_pkt_type_t pkt_type) {
        valid_ethernet_pkt(pkt_type);
        // Set the common IP lookup fields
        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;



        local_md.lkp.ip_src_addr[63:0] = 64w0;
        local_md.lkp.ip_src_addr[95:64] = hdr.inner_ipv4.src_addr;
        local_md.lkp.ip_src_addr[127:96] = 32w0;
        local_md.lkp.ip_dst_addr[63:0] = 64w0;
        local_md.lkp.ip_dst_addr[95:64] = hdr.inner_ipv4.dst_addr;
        local_md.lkp.ip_dst_addr[127:96] = 32w0;
 local_md.lkp.l4_src_port = local_md.lkp.inner_l4_src_port;
 local_md.lkp.l4_dst_port = local_md.lkp.inner_l4_dst_port;
 local_md.lkp.tcp_flags = local_md.lkp.inner_tcp_flags;
    }

    @name(".valid_inner_ipv6_pkt")
    action valid_ipv6_pkt(switch_pkt_type_t pkt_type) {
        valid_ethernet_pkt(pkt_type);
        // Set the common IP lookup fields
        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;



        local_md.lkp.ip_src_addr = hdr.inner_ipv6.src_addr;
        local_md.lkp.ip_dst_addr = hdr.inner_ipv6.dst_addr;
        local_md.flags.link_local = false;
    }


    @name(".valid_inner_ipv4_tcp_pkt")
    action valid_ipv4_tcp_pkt(switch_pkt_type_t pkt_type) {
        valid_ipv4_pkt(pkt_type);
    }

    @name(".valid_inner_ipv4_udp_pkt")
    action valid_ipv4_udp_pkt(switch_pkt_type_t pkt_type) {
        valid_ipv4_pkt(pkt_type);
    }

    @name(".valid_inner_ipv6_tcp_pkt")
    action valid_ipv6_tcp_pkt(switch_pkt_type_t pkt_type) {
        valid_ipv6_pkt(pkt_type);
    }

    @name(".valid_inner_ipv6_udp_pkt")
    action valid_ipv6_udp_pkt(switch_pkt_type_t pkt_type) {
        valid_ipv6_pkt(pkt_type);
    }

    @name(".malformed_l2_inner_pkt")
    action malformed_l2_pkt(bit<8> reason) {
        local_md.l2_drop_reason = reason;
    }

    @name(".malformed_l3_inner_pkt")
    action malformed_l3_pkt(bit<8> reason) {
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
        }

        actions = {
            NoAction;
            valid_ipv4_pkt;
            valid_ipv6_pkt;
            valid_ethernet_pkt;
            malformed_l2_pkt;
            malformed_l3_pkt;
        }
        size = MIN_TABLE_SIZE;
    }

    apply {
        validate_ethernet.apply();
    }
}

// ============================================================================
//
// Select between inner or outer headers for further lookup
//
// ============================================================================
control LkpFieldsI1E1(
        in switch_header_t hdr,
        inout switch_local_metadata_t local_md) {

    //---------------------------------------------------------------
    // Non-tunnel termination case : Use outer headers for lkp fields
    //---------------------------------------------------------------

    action set_ethernet_fields_from_outer() {
        local_md.lkp.mac_type = hdr.ethernet.ether_type;
 local_md.lkp.pcp = 0;
 local_md.lkp.dei = 0;
        local_md.lkp.mac_src_addr = hdr.ethernet.src_addr;
        local_md.lkp.mac_dst_addr = hdr.ethernet.dst_addr;
    }

    action set_qtag_ethernet_fields_from_outer() {
        local_md.lkp.mac_type = hdr.vlan_tag[0].ether_type;
 local_md.lkp.pcp = hdr.vlan_tag[0].pcp;
 local_md.lkp.dei = hdr.vlan_tag[0].dei;
        local_md.lkp.mac_src_addr = hdr.ethernet.src_addr;
        local_md.lkp.mac_dst_addr = hdr.ethernet.dst_addr;
    }

    action set_arp_fields_from_outer() {
 set_ethernet_fields_from_outer();
        local_md.lkp.arp_opcode = hdr.arp.opcode;
    }

    action set_non_ip_fields_from_outer() {
 set_ethernet_fields_from_outer();
    }

    action set_ipv4_fields_from_outer(switch_ip_frag_t ip_frag, bool is_link_local) {
 set_ethernet_fields_from_outer();

        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        local_md.lkp.ip_tos = hdr.ipv4.diffserv;
        local_md.lkp.ip_ttl = hdr.ipv4.ttl;
        local_md.lkp.ip_proto = hdr.ipv4.protocol;
        local_md.lkp.ip_src_addr[63:0] = 64w0;
        local_md.lkp.ip_src_addr[95:64] = hdr.ipv4.src_addr;
        local_md.lkp.ip_src_addr[127:96] = 32w0;
        local_md.lkp.ip_dst_addr[63:0] = 64w0;
        local_md.lkp.ip_dst_addr[95:64] = hdr.ipv4.dst_addr;
        local_md.lkp.ip_dst_addr[127:96] = 32w0;
        local_md.lkp.ip_frag = ip_frag;
        local_md.flags.link_local = is_link_local;
    }

    action set_ipv6_fields_from_outer(bool is_link_local) {
 set_ethernet_fields_from_outer();

        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        local_md.lkp.ip_tos = hdr.ipv6.traffic_class;
        local_md.lkp.ip_ttl = hdr.ipv6.hop_limit;
        local_md.lkp.ip_proto = hdr.ipv6.next_hdr;
        local_md.lkp.ip_src_addr = hdr.ipv6.src_addr;
        local_md.lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        local_md.lkp.ipv6_flow_label = hdr.ipv6.flow_label;
        local_md.flags.link_local = is_link_local;
    }

    action set_qtag_arp_fields_from_outer() {
 set_qtag_ethernet_fields_from_outer();
        local_md.lkp.arp_opcode = hdr.arp.opcode;
    }

    action set_qtag_non_ip_fields_from_outer() {
 set_ethernet_fields_from_outer();
    }

    action set_qtag_ipv4_fields_from_outer(switch_ip_frag_t ip_frag, bool is_link_local) {
 set_qtag_ethernet_fields_from_outer();

        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        local_md.lkp.ip_tos = hdr.ipv4.diffserv;
        local_md.lkp.ip_ttl = hdr.ipv4.ttl;
        local_md.lkp.ip_proto = hdr.ipv4.protocol;
        local_md.lkp.ip_src_addr[63:0] = 64w0;
        local_md.lkp.ip_src_addr[95:64] = hdr.ipv4.src_addr;
        local_md.lkp.ip_src_addr[127:96] = 32w0;
        local_md.lkp.ip_dst_addr[63:0] = 64w0;
        local_md.lkp.ip_dst_addr[95:64] = hdr.ipv4.dst_addr;
        local_md.lkp.ip_dst_addr[127:96] = 32w0;
        local_md.lkp.ip_frag = ip_frag;
        local_md.flags.link_local = is_link_local;
    }

    action set_qtag_ipv6_fields_from_outer(bool is_link_local) {
 set_qtag_ethernet_fields_from_outer();

        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        local_md.lkp.ip_tos = hdr.ipv6.traffic_class;
        local_md.lkp.ip_ttl = hdr.ipv6.hop_limit;
        local_md.lkp.ip_proto = hdr.ipv6.next_hdr;
        local_md.lkp.ip_src_addr = hdr.ipv6.src_addr;
        local_md.lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        local_md.lkp.ipv6_flow_label = hdr.ipv6.flow_label;
        local_md.flags.link_local = is_link_local;
    }

    table lkp_ip_fields_from_outer {
        key = {
            hdr.arp.isValid() : exact;
            hdr.vlan_tag[0].isValid() : ternary;
            hdr.ipv4.isValid() : exact;
            hdr.ipv4.flags : ternary;
            hdr.ipv4.frag_offset : ternary;
            hdr.ipv4.src_addr[31:0] : ternary;
            hdr.ipv6.isValid() : exact;
            hdr.ipv6.src_addr[127:112] : ternary;
        }

        actions = {
            NoAction;
            set_ipv4_fields_from_outer;
            set_ipv6_fields_from_outer;
            set_arp_fields_from_outer;
            set_non_ip_fields_from_outer;
            set_qtag_ipv4_fields_from_outer;
            set_qtag_ipv6_fields_from_outer;
            set_qtag_arp_fields_from_outer;
            set_qtag_non_ip_fields_from_outer;
        }

        const default_action = NoAction;
        const entries = {
     // ------------------ untagged packet -----------------------------------
            // arp pkt
            ( true, false, false, _, _, _, false, _) : set_arp_fields_from_outer;
            // no-ip
            (false, false, false, _, _, _, false, _) : set_non_ip_fields_from_outer;
            // link_local ipv4, non-frag
            (false, false, true, 0x0 &&& 0x1, 0, 0xA9FE0000 &&& 0xFFFF0000, false, _) : set_ipv4_fields_from_outer(SWITCH_IP_FRAG_NON_FRAG, true);
            // link_local ipv4, first frag
            (false, false, true, 0x1 &&& 0x1, 0, 0xA9FE0000 &&& 0xFFFF0000, false, _) : set_ipv4_fields_from_outer(SWITCH_IP_FRAG_HEAD, true);
            // link_local ipv4, more frags
            (false, false, true, _, _, 0xA9FE0000 &&& 0xFFFF0000, false, _) : set_ipv4_fields_from_outer(SWITCH_IP_FRAG_NON_HEAD, true);
            // ipv4 non-frag
            (false, false, true, 0x0 &&& 0x1, 0, _, false, _) : set_ipv4_fields_from_outer(SWITCH_IP_FRAG_NON_FRAG, false);
            // ipv4 first frag
            (false, false, true, 0x1 &&& 0x1, 0, _, false, _) : set_ipv4_fields_from_outer(SWITCH_IP_FRAG_HEAD, false);
            // ipv4 more frags, invalid version
            (false, false, true, _, _, _, false, _) : set_ipv4_fields_from_outer(SWITCH_IP_FRAG_NON_HEAD, false);
            // ipv6 link-local
            (false, false, false, _, _, _, true, 0xFE80 &&& 0xFFC0) : set_ipv6_fields_from_outer(true);
            // ipv6
            (false, false, false, _, _, _, true, _) : set_ipv6_fields_from_outer(false);

     // ------------------ untagged packet -----------------------------------
            // arp pkt
            ( true, true, false, _, _, _, false, _) : set_qtag_arp_fields_from_outer;
            // no-ip
            (false, true, false, _, _, _, false, _) : set_qtag_non_ip_fields_from_outer;
            // link_local ipv4, non-frag
            (false, true, true, 0x0 &&& 0x1, 0, 0xA9FE0000 &&& 0xFFFF0000, false, _) : set_qtag_ipv4_fields_from_outer(SWITCH_IP_FRAG_NON_FRAG, true);
            // link_local ipv4, first frag
            (false, true, true, 0x1 &&& 0x1, 0, 0xA9FE0000 &&& 0xFFFF0000, false, _) : set_qtag_ipv4_fields_from_outer(SWITCH_IP_FRAG_HEAD, true);
            // link_local ipv4, more frags
            (false, true, true, _, _, 0xA9FE0000 &&& 0xFFFF0000, false, _) : set_qtag_ipv4_fields_from_outer(SWITCH_IP_FRAG_NON_HEAD, true);
            // ipv4 non-frag
            (false, true, true, 0x0 &&& 0x1, 0, _, false, _) : set_qtag_ipv4_fields_from_outer(SWITCH_IP_FRAG_NON_FRAG, false);
            // ipv4 first frag
            (false, true, true, 0x1 &&& 0x1, 0, _, false, _) : set_qtag_ipv4_fields_from_outer(SWITCH_IP_FRAG_HEAD, false);
            // ipv4 more frags, invalid version
            (false, true, true, _, _, _, false, _) : set_qtag_ipv4_fields_from_outer(SWITCH_IP_FRAG_NON_HEAD, false);
            // ipv6 link-local
            (false, true, false, _, _, _, true, 0xFE80 &&& 0xFFC0) : set_qtag_ipv6_fields_from_outer(true);
            // ipv6
            (false, true, false, _, _, _, true, _) : set_qtag_ipv6_fields_from_outer(false);
        }

        size = MIN_TABLE_SIZE;
    }


    action set_tcp_ports_from_outer() {
        local_md.lkp.l4_src_port = hdr.tcp.src_port;
        local_md.lkp.l4_dst_port = hdr.tcp.dst_port;
        local_md.lkp.tcp_flags = hdr.tcp.flags;
    }

    action set_udp_ports_from_outer() {
        local_md.lkp.l4_src_port = hdr.udp.src_port;
        local_md.lkp.l4_dst_port = hdr.udp.dst_port;
        local_md.lkp.tcp_flags = 0;
    }

    action set_icmp_ports_from_outer() {
        local_md.lkp.l4_src_port[7:0] = hdr.icmp.type;
        local_md.lkp.l4_src_port[15:8] = hdr.icmp.code;
        local_md.lkp.l4_dst_port = 0;
        local_md.lkp.tcp_flags = 0;
    }

    action set_igmp_ports_from_outer() {
        local_md.lkp.l4_src_port[7:0] = hdr.igmp.type;
        local_md.lkp.l4_src_port[15:8] = 0;
        local_md.lkp.l4_dst_port = 0;
        local_md.lkp.tcp_flags = 0;
    }

    table lkp_other_fields_from_outer {
        key = {
            hdr.tcp.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.icmp.isValid() : exact;
            hdr.igmp.isValid() : exact;
        }

        actions = {
            NoAction;
            set_tcp_ports_from_outer;
            set_udp_ports_from_outer;
            set_icmp_ports_from_outer;

            set_igmp_ports_from_outer;

        }

        const default_action = NoAction;
        const entries = {
            (true, false, false, false) : set_tcp_ports_from_outer();
            (false, true, false, false) : set_udp_ports_from_outer();
            (false, false, true, false) : set_icmp_ports_from_outer();

            (false, false, false, true) : set_igmp_ports_from_outer();

        }
        size = 16;
    }

    //---------------------------------------------------------------
    // Tunnel termination case : Use inner headers for lkp fields
    //---------------------------------------------------------------

    action set_non_ip_fields_from_inner() {
        local_md.lkp.mac_type = hdr.inner_ethernet.ether_type;
        local_md.lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        local_md.lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
    }

    action set_arp_fields_from_inner() {
        local_md.lkp.mac_type = hdr.inner_ethernet.ether_type;
        local_md.lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        local_md.lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
        //      local_md.lkp.arp_opcode = hdr.inner_arp.opcode;
    }

    action set_ipv4_fields_from_inner() {
        local_md.lkp.mac_type = 0x0800;
        local_md.lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        local_md.lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;

        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        local_md.lkp.ip_tos = hdr.inner_ipv4.diffserv;
        local_md.lkp.ip_ttl = hdr.inner_ipv4.ttl;
        local_md.lkp.ip_proto = hdr.inner_ipv4.protocol;
        local_md.lkp.ip_src_addr[63:0] = 64w0;
        local_md.lkp.ip_src_addr[95:64] = hdr.inner_ipv4.src_addr;
        local_md.lkp.ip_src_addr[127:96] = 32w0;
        local_md.lkp.ip_dst_addr[63:0] = 64w0;
        local_md.lkp.ip_dst_addr[95:64] = hdr.inner_ipv4.dst_addr;
        local_md.lkp.ip_dst_addr[127:96] = 32w0;
    }

    action set_ipv6_fields_from_inner() {
        local_md.lkp.mac_type = 0x86dd;
        local_md.lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        local_md.lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;

        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        local_md.lkp.ip_tos = hdr.inner_ipv6.traffic_class;
        local_md.lkp.ip_ttl = hdr.inner_ipv6.hop_limit;
        local_md.lkp.ip_proto = hdr.inner_ipv6.next_hdr;
        local_md.lkp.ip_src_addr = hdr.inner_ipv6.src_addr;
        local_md.lkp.ip_dst_addr = hdr.inner_ipv6.dst_addr;
        local_md.lkp.ipv6_flow_label = hdr.inner_ipv6.flow_label;
        local_md.flags.link_local = false;
    }

    action set_tcp_ports_from_inner() {
        local_md.lkp.l4_src_port = hdr.inner_tcp.src_port;
        local_md.lkp.l4_dst_port = hdr.inner_tcp.dst_port;
        local_md.lkp.tcp_flags = hdr.inner_tcp.flags;
    }

    action set_udp_ports_from_inner() {
        local_md.lkp.l4_src_port = hdr.inner_udp.src_port;
        local_md.lkp.l4_dst_port = hdr.inner_udp.dst_port;
        local_md.lkp.tcp_flags = 0;
    }

    action set_icmp_ports_from_inner() {
        local_md.lkp.l4_src_port[7:0] = hdr.inner_icmp.type;
        local_md.lkp.l4_src_port[15:8] = hdr.inner_icmp.code;
        local_md.lkp.l4_dst_port = 0;
        local_md.lkp.tcp_flags = 0;
    }

    action set_igmp_ports_from_inner() {
        local_md.lkp.l4_src_port[7:0] = hdr.inner_igmp.type;
        local_md.lkp.l4_src_port[15:8] = 0;
        local_md.lkp.l4_dst_port = 0;
        local_md.lkp.tcp_flags = 0;
    }

    action set_ipv4_tcp_fields_from_inner() {
        set_ipv4_fields_from_inner();
        set_tcp_ports_from_inner();
    }

    action set_ipv4_udp_fields_from_inner() {
        set_ipv4_fields_from_inner();
        set_udp_ports_from_inner();
    }

    action set_ipv4_icmp_fields_from_inner() {
        set_ipv4_fields_from_inner();
        set_icmp_ports_from_inner();
    }

    action set_ipv4_igmp_fields_from_inner() {
        set_ipv4_fields_from_inner();
        set_igmp_ports_from_inner();
    }

    action set_ipv6_tcp_fields_from_inner() {
        set_ipv6_fields_from_inner();
        set_tcp_ports_from_inner();
    }

    action set_ipv6_udp_fields_from_inner() {
        set_ipv6_fields_from_inner();
        set_udp_ports_from_inner();
    }

    action set_ipv6_icmp_fields_from_inner() {
        set_ipv6_fields_from_inner();
        set_icmp_ports_from_inner();
    }

    action set_ipv6_igmp_fields_from_inner() {
        set_ipv6_fields_from_inner();
        set_igmp_ports_from_inner();
    }

    table lkp_fields_from_inner {
        key = {
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
            hdr.inner_tcp.isValid() : exact;
            hdr.inner_udp.isValid() : exact;
            hdr.inner_icmp.isValid() : exact;
            hdr.inner_igmp.isValid() : exact;
        }

        actions = {
            NoAction;
            set_ipv4_tcp_fields_from_inner;
            set_ipv4_udp_fields_from_inner;
            set_ipv4_icmp_fields_from_inner;
            set_ipv4_igmp_fields_from_inner;
            set_ipv4_fields_from_inner;
            set_ipv6_tcp_fields_from_inner;
            set_ipv6_udp_fields_from_inner;
            set_ipv6_icmp_fields_from_inner;
            set_ipv6_igmp_fields_from_inner;
            set_ipv6_fields_from_inner;
            set_non_ip_fields_from_inner;
        }

        const default_action = NoAction;
        const entries = {
     ( true, false, true, false, false, false) : set_ipv4_tcp_fields_from_inner;
     ( true, false, false, true, false, false) : set_ipv4_udp_fields_from_inner;
     ( true, false, false, false, true, false) : set_ipv4_igmp_fields_from_inner;
     ( true, false, false, false, false, true) : set_ipv4_icmp_fields_from_inner;
     ( true, false, false, false, false, false) : set_ipv4_fields_from_inner;
     (false, true, true, false, false, false) : set_ipv6_tcp_fields_from_inner;
     (false, true, false, true, false, false) : set_ipv6_udp_fields_from_inner;
     (false, true, false, false, true, false) : set_ipv6_igmp_fields_from_inner;
     (false, true, false, false, false, true) : set_ipv6_icmp_fields_from_inner;
     (false, true, false, false, false, false) : set_ipv6_fields_from_inner;
     (false, false, false, false, false, false) : set_non_ip_fields_from_inner;
        }

        size = MIN_TABLE_SIZE;
    }

    apply {
        if (local_md.tunnel.terminate==true) {
            lkp_fields_from_inner.apply();
        } else {
            lkp_ip_fields_from_outer.apply();
            lkp_other_fields_from_outer.apply();
        }
    }
}

// ============================================================================
//
// Extract L3/L4 header fields (step 0)
//
// ============================================================================

control LkpFieldsE0_0(
    in switch_header_t hdr,
    inout switch_local_metadata_t local_md) {

    action set_ipv4_fields() {
        local_md.lkp.ip_proto = hdr.ipv4.protocol;
        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
    }

    action set_ipv6_fields() {
        local_md.lkp.ip_proto = hdr.ipv6.next_hdr;
        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
    }

    action set_udp_ports() {
        local_md.lkp.l4_src_port = hdr.udp.src_port;
        local_md.lkp.l4_dst_port = hdr.udp.dst_port;
        local_md.lkp.tcp_flags = 0;
    }

    action set_ipv4_udp_fields() {
        set_ipv4_fields();
        set_udp_ports();
    }

    action set_ipv6_udp_fields() {
        set_ipv6_fields();
        set_udp_ports();
    }

    table lkp_fields_l3l4 {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.udp.isValid() : exact;
        }
        actions = {
            set_ipv4_udp_fields;
            set_ipv4_fields;
            set_ipv6_udp_fields;
            set_ipv6_fields;
        }
        const entries = {
     ( true, false, true) : set_ipv4_udp_fields;
     ( true, false, false) : set_ipv4_fields;
     (false, true, true) : set_ipv6_udp_fields;
     (false, true, false) : set_ipv6_fields;
        }
        size = MIN_TABLE_SIZE;
    }
    apply {
        if (!local_md.flags.bypass_egress)
            lkp_fields_l3l4.apply();
    }
}


// ============================================================================
//
// Overlay IP addresses in the Egress pipeline for ACL match
//
// ============================================================================

control LkpFieldsE0_1(
    in switch_header_t hdr,
    inout switch_local_metadata_t local_md) {

    action valid_ipv4_pkt() {
        local_md.lkp.ip_src_addr_95_64 = hdr.ipv4.src_addr;
        local_md.lkp.ip_dst_addr_95_64 = hdr.ipv4.dst_addr;
    }

    action valid_ipv6_pkt() {
        local_md.lkp.ip_src_addr_95_64 = hdr.ipv6.src_addr[95:64];
        local_md.lkp.ip_dst_addr_95_64 = hdr.ipv6.dst_addr[95:64];
    }

    @name(".egress_pkt_validation")
    table lkp_fields_ipaddr {
        key = {
            hdr.ipv4.isValid() : ternary;
            hdr.ipv6.isValid() : ternary;
        }
        actions = {
            valid_ipv4_pkt;
            valid_ipv6_pkt;
        }
        const entries = {
            (true, false) : valid_ipv4_pkt;
            (false, true) : valid_ipv6_pkt;
        }
        size = MIN_TABLE_SIZE;
    }
    apply {
        if (!local_md.flags.bypass_egress)
            lkp_fields_ipaddr.apply();
    }
}
# 201 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/mirror_rewrite.p4" 1

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
# 202 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4" 1
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
// Tunnel Termination processing
// Outer router MAC
// Destination VTEP, Insegment and Local SID lookups
//-----------------------------------------------------------------------------
control IngressTunnel(inout switch_header_t hdr,
                      inout switch_local_metadata_t local_md,
                      inout switch_lookup_fields_t lkp)() {
    InnerPktValidation() pkt_validation;

    //
    // **************** Router MAC Check ************************
    //
    @name(".tunnel_rmac_miss")
    action rmac_miss() {
        local_md.flags.rmac_hit = false;
    }
    @name(".tunnel_rmac_hit")
    action rmac_hit() {
        local_md.flags.rmac_hit = true;
    }

    @name(".vxlan_rmac")
    table vxlan_rmac {
        key = {
            local_md.tunnel.vni : exact;
            hdr.inner_ethernet.dst_addr : exact;
        }

        actions = {
            @defaultonly rmac_miss;
            rmac_hit;
        }

        const default_action = rmac_miss;
        size = VNI_MAPPING_TABLE_SIZE;
    }

    @name(".vxlan_device_rmac")
    table vxlan_device_rmac {
        key = {
            hdr.inner_ethernet.dst_addr : exact;
        }

        actions = {
            @defaultonly rmac_miss;
            rmac_hit;
        }

        const default_action = rmac_miss;
        size = 128;
    }

    //
    // **************** Tunnel Termination Table  ************************
    //
    @name(".dst_vtep_hit")
    action dst_vtep_hit(switch_tunnel_mode_t ttl_mode,
                        switch_tunnel_mode_t qos_mode) {






    }

    @name(".set_inner_bd_properties_base")
    action set_inner_bd_properties_base(
            switch_bd_t bd,
            switch_vrf_t vrf,
            switch_packet_action_t vrf_ttl_violation,
            bool vrf_ttl_violation_valid,
            switch_packet_action_t vrf_ip_options_violation,
            switch_bd_label_t bd_label,
            switch_learning_mode_t learning_mode,
            bool ipv4_unicast_enable,
            bool ipv6_unicast_enable) {
//        local_md.ingress_outer_bd = local_md.bd;
        local_md.bd = bd;



        local_md.vrf = vrf;
        local_md.flags.vrf_ttl_violation = vrf_ttl_violation;
        local_md.flags.vrf_ttl_violation_valid = vrf_ttl_violation_valid;
        local_md.flags.vrf_ip_options_violation = vrf_ip_options_violation;
        local_md.learning.bd_mode = learning_mode;
        local_md.ipv4.unicast_enable = ipv4_unicast_enable;
        local_md.ipv4.multicast_enable = false;
        local_md.ipv4.multicast_snooping = false;
        local_md.ipv6.unicast_enable = ipv6_unicast_enable;
        local_md.ipv6.multicast_enable = false;
        local_md.ipv6.multicast_snooping = false;
        local_md.tunnel.terminate = true;
    }

    @name(".set_inner_bd_properties")
    action set_inner_bd_properties(
            switch_bd_t bd,
            switch_vrf_t vrf,
            switch_packet_action_t vrf_ttl_violation,
            bool vrf_ttl_violation_valid,
            switch_packet_action_t vrf_ip_options_violation,
            switch_bd_label_t bd_label,
            switch_learning_mode_t learning_mode,
            bool ipv4_unicast_enable,
            bool ipv6_unicast_enable,
            switch_tunnel_mode_t ttl_mode,
            switch_tunnel_mode_t qos_mode,
            switch_tunnel_mode_t ecn_mode) {
        set_inner_bd_properties_base(bd, vrf,
                                     vrf_ttl_violation,
                                     vrf_ttl_violation_valid,
                                     vrf_ip_options_violation,
                                     bd_label,
                                     learning_mode, ipv4_unicast_enable, ipv6_unicast_enable);
# 151 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
    }

    @name(".dst_vtep")
    table dst_vtep {
        key = {
            hdr.ipv4.src_addr : ternary @name("src_addr");
            hdr.ipv4.dst_addr : ternary @name("dst_addr");
            local_md.vrf : exact;
            local_md.tunnel.type : exact;
        }

        actions = {
            NoAction;

            dst_vtep_hit;

            set_inner_bd_properties;
        }

        size = IPV4_DST_VTEP_TABLE_SIZE;
        const default_action = NoAction;
        requires_versioning = false;
    }
# 226 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
    //
    // ***************** tunnel.vni -> VRF Translation *****************
    //
    @name(".vni_to_bd_mapping")
    table vni_to_bd_mapping {
        key = { local_md.tunnel.vni : exact; }

        actions = {
            NoAction;
            set_inner_bd_properties_base;
        }

        default_action = NoAction;
        size = VNI_MAPPING_TABLE_SIZE;
    }
# 622 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
    //
    // ***************** Control Flow *****************
    //
    apply {
//-----------------------------------------------------------------------
# 739 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
//-----------------------------------------------------------------------
        // outer RMAC lookup for tunnel termination.
        if (local_md.flags.rmac_hit) {
                if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                    switch(dst_vtep.apply().action_run) {
                        dst_vtep_hit : {
                            // Vxlan
                            if (vni_to_bd_mapping.apply().hit) {
                                if (!vxlan_rmac.apply().hit) {
                                  vxlan_device_rmac.apply();
                                };
                                pkt_validation.apply(hdr, local_md);
                            }
                        }

                        set_inner_bd_properties : {
                            // IPinIP or IPinGRE
                            pkt_validation.apply(hdr, local_md);
                        }
                    }
                } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
# 778 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
                }
        }
//-----------------------------------------------------------------------
# 816 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
    }
}

//-----------------------------------------------------------------------------
// Tunnel decapsulation
//
//-----------------------------------------------------------------------------
control TunnelDecap(inout switch_header_t hdr,
                    inout switch_local_metadata_t local_md)() {

    //************************************************************
    //
    // Copy Inner headers to Outer
    //
    //************************************************************
    action store_outer_ipv4_fields() {
      local_md.tunnel.decap_tos = hdr.ipv4.diffserv;
      local_md.tunnel.decap_ttl = hdr.ipv4.ttl;
    }

    action store_outer_ipv6_fields() {
      local_md.tunnel.decap_tos = hdr.ipv6.traffic_class;
      local_md.tunnel.decap_ttl = hdr.ipv6.hop_limit;
    }

    action store_outer_mpls_fields() {
      local_md.tunnel.decap_exp = hdr.mpls[0].exp;
      local_md.tunnel.decap_ttl = hdr.mpls[0].ttl;
    }

    action copy_ipv4_header() {
        hdr.ipv4.setValid();
        hdr.ipv6.setInvalid();
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

        // Pipe mode is taken care of here; Uniform mode will be handled later in the pipeline
        hdr.ipv4.diffserv = hdr.inner_ipv4.diffserv;
        hdr.ipv4.ttl = hdr.inner_ipv4.ttl;

        hdr.inner_ipv4.setInvalid();
    }

    action copy_ipv6_header() {
        hdr.ipv6.setValid();
        hdr.ipv4.setInvalid();
        hdr.ipv6 = hdr.inner_ipv6;

        hdr.inner_ipv6.setInvalid();
    }

    action invalidate_vxlan_header() {
        hdr.vxlan.setInvalid();
        hdr.udp.setInvalid();
        hdr.inner_ethernet.setInvalid();
    }

    action invalidate_gre_header() {



    }

    action invalidate_vlan_tag0() {
        hdr.vlan_tag[0].setInvalid();
    }

    // Outer V4
    action decap_v4_inner_ethernet_ipv4() {
        store_outer_ipv4_fields();
        invalidate_vlan_tag0();
        hdr.ethernet = hdr.inner_ethernet;
        copy_ipv4_header();
        invalidate_vxlan_header();
    }

    action decap_v4_inner_ethernet_ipv6() {
        store_outer_ipv4_fields();
        invalidate_vlan_tag0();
        hdr.ethernet = hdr.inner_ethernet;
        copy_ipv6_header();
        invalidate_vxlan_header();
    }

    action decap_v4_inner_ethernet_non_ip() {
        store_outer_ipv4_fields();
        invalidate_vlan_tag0();
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        invalidate_vxlan_header();
    }

    action decap_v4_inner_ipv4() {
        store_outer_ipv4_fields();
        invalidate_vlan_tag0();
        hdr.ethernet.ether_type = 0x0800;
        copy_ipv4_header();
        invalidate_gre_header();
    }

    action decap_v4_inner_ipv6() {
        store_outer_ipv4_fields();
        invalidate_vlan_tag0();
        hdr.ethernet.ether_type = 0x86dd;
        copy_ipv6_header();
        invalidate_gre_header();
    }

    // Outer V6
    action decap_v6_inner_ethernet_ipv4() {
        store_outer_ipv6_fields();
        invalidate_vlan_tag0();
        hdr.ethernet = hdr.inner_ethernet;
        copy_ipv4_header();
        invalidate_vxlan_header();
    }

    action decap_v6_inner_ethernet_ipv6() {
        store_outer_ipv6_fields();
        invalidate_vlan_tag0();
        hdr.ethernet = hdr.inner_ethernet;
        copy_ipv6_header();
        invalidate_vxlan_header();
    }

    action decap_v6_inner_ethernet_non_ip() {
        store_outer_ipv6_fields();
        invalidate_vlan_tag0();
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        invalidate_vxlan_header();
    }

    action decap_v6_inner_ipv4() {
        store_outer_ipv6_fields();
        invalidate_vlan_tag0();
        hdr.ethernet.ether_type = 0x0800;
        copy_ipv4_header();
        invalidate_gre_header();
    }

    action decap_v6_inner_ipv6() {
        store_outer_ipv6_fields();
        invalidate_vlan_tag0();
        hdr.ethernet.ether_type = 0x86dd;
        copy_ipv6_header();
        invalidate_gre_header();
    }

    action decap_mpls_inner_ipv4() {
        store_outer_mpls_fields();
        invalidate_vlan_tag0();
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.ethernet.ether_type = 0x0800;
        copy_ipv4_header();
    }

    action decap_mpls_inner_ipv6() {
        store_outer_mpls_fields();
        invalidate_vlan_tag0();
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.ethernet.ether_type = 0x86dd;
        copy_ipv6_header();
    }

    action mpls_pop1() {
        store_outer_mpls_fields();
        invalidate_vlan_tag0();
        hdr.mpls.pop_front(1);
    }

    action mpls_pop2() {
        store_outer_mpls_fields();
        invalidate_vlan_tag0();
        hdr.mpls.pop_front(2);
    }

    table decap_tunnel_hdr {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.inner_ethernet.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;






        }

        actions = {

            decap_v4_inner_ethernet_ipv4;
            decap_v4_inner_ethernet_ipv6;
            decap_v4_inner_ethernet_non_ip;
            decap_v6_inner_ethernet_ipv4;
            decap_v6_inner_ethernet_ipv6;
            decap_v6_inner_ethernet_non_ip;

            decap_v4_inner_ipv4;
            decap_v4_inner_ipv6;
            decap_v6_inner_ipv4;
            decap_v6_inner_ipv6;






        }

        const entries = {
# 1079 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
            ( true, false, true, true, true, false) : decap_v4_inner_ethernet_ipv4;
            ( true, false, true, true, false, true) : decap_v4_inner_ethernet_ipv6;
            ( true, false, true, true, false, false) : decap_v4_inner_ethernet_non_ip;
            (false, true, true, true, true, false) : decap_v6_inner_ethernet_ipv4;
            (false, true, true, true, false, true) : decap_v6_inner_ethernet_ipv6;
            (false, true, true, true, false, false) : decap_v6_inner_ethernet_non_ip;

            ( true, false, false, false, true, false) : decap_v4_inner_ipv4;
            ( true, false, false, false, false, true) : decap_v4_inner_ipv6;
            (false, true, false, false, true, false) : decap_v6_inner_ipv4;
            (false, true, false, false, false, true) : decap_v6_inner_ipv6;

        }
        size = MIN_TABLE_SIZE;
    }
# 1233 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
    //************************************************************
    //
    // For Uniform mode, copy stored outer TTL value to the packet
    //
    //************************************************************
# 1295 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
    //************************************************************
    //
    // Uniform mode,
    //    - For IP tunnels, copy stored outer TOS value to the packet
    //    - For MPLS LER/Pop operations, copy from stored outermost exp value
    //
    //************************************************************

    action decap_dscp_inner_v4_uniform() {





        // When RFC 6040 lookup is disabled, copy ecn bits from outer
        // in addition to dscp bits
        @in_hash { hdr.ipv4.diffserv = local_md.tunnel.decap_tos; }

    }
    action decap_dscp_inner_v6_uniform() {





        // When RFC 6040 lookup is disabled, copy ecn bits from outer
        // in addition to dscp bits
        @in_hash { hdr.ipv6.traffic_class = local_md.tunnel.decap_tos; }

    }


    action decap_ecn_inner_v4_from_outer() {
        @in_hash { hdr.ipv4.diffserv[1:0] = local_md.tunnel.decap_tos[1:0]; }
    }
    action decap_ecn_inner_v6_from_outer() {
        @in_hash { hdr.ipv6.traffic_class[1:0] = local_md.tunnel.decap_tos[1:0]; }
    }
# 1351 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
    table decap_dscp {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;







        }
        actions = {
            NoAction;
            decap_dscp_inner_v4_uniform;
            decap_dscp_inner_v6_uniform;

            decap_ecn_inner_v4_from_outer;
            decap_ecn_inner_v6_from_outer;






        }
        const entries = {
# 1423 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
            (true, false): decap_dscp_inner_v4_uniform;
            (false, true): decap_dscp_inner_v6_uniform;


        }
//        const default_action = decap_dscp_inner_v4_uniform;
        size = 32;
    }

    //************************************************************
    //
    // Tunnel decap ECN operations
    //
    //************************************************************
# 1557 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
    apply {
        if (!local_md.flags.bypass_egress) {



            // Copy inner L2/L3 headers into outer headers.
            decap_tunnel_hdr.apply();



            decap_dscp.apply();







        }
    }
}



//-------------------------------------------------------------
// IP Tunnel Encapsulation - Step 1
//
// Tunnel Nexthop
//-------------------------------------------------------------

control TunnelNexthop(inout switch_header_t hdr,
                      inout switch_local_metadata_t local_md) {
    // **************** Tunnel Nexthop table  *************************

    @name(".l2_tunnel_encap")
    action l2_tunnel_encap(
                                  switch_tunnel_type_t type,
                                  switch_tunnel_ip_index_t dip_index,
                                  switch_tunnel_index_t tunnel_index,
                                  switch_tunnel_mapper_index_t tunnel_mapper_index) {
        local_md.tunnel.type = type;
        local_md.tunnel.index = tunnel_index;

        local_md.tunnel.mapper_index = tunnel_mapper_index;

        local_md.tunnel.dip_index = dip_index;
        // While the inner headers are L2 forwarded, the outer headers are
        // routed. In order to properly process the outer ethernet header,
        // local_md.flags.routed must be set to true. This assumes that inner
        // header operations (e.g. egress_vrf) have already been completed
        // while local_md.flags.routed was false, and outer header operations
        // (e.g. outer_nexthop, neighbor, egress_bd.bd_mapping) have not yet
        // started.
        local_md.flags.routed = true;
 local_md.flags.l2_tunnel_encap = true;
    }

    @name(".l3_tunnel_encap")
    action l3_tunnel_encap(
                                  mac_addr_t dmac,
                                  switch_tunnel_type_t type,
                                  switch_tunnel_ip_index_t dip_index,
                                  switch_tunnel_index_t tunnel_index) {
        local_md.flags.routed = true;
        local_md.tunnel.type = type;
        local_md.tunnel.dip_index = dip_index; // Index of IP address from the nexthop object
        local_md.tunnel.index = tunnel_index; // programing_note: id of the tunnel from the nexthop object
        hdr.ethernet.dst_addr = dmac; // programming_note: program switch global dmac if nexthop doesn't provide dmac
    }

    @name(".l3_tunnel_encap_with_vni")
    action l3_tunnel_encap_with_vni(
                                      mac_addr_t dmac,
                                      switch_tunnel_type_t type,
                                      switch_tunnel_vni_t vni,
                                      switch_tunnel_ip_index_t dip_index,
                                      switch_tunnel_index_t tunnel_index) {
        local_md.flags.routed = true;
        local_md.tunnel.type = type;
        local_md.tunnel.index = tunnel_index;
        local_md.tunnel.dip_index = dip_index;
        hdr.ethernet.dst_addr = dmac;
        local_md.tunnel.vni = vni; // programming_note: call this action only if nexthop provides vni OR for asymmetric IRB (rif->vlan>vni)
    }
# 1656 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
    @name(".srv6_encap")
    action srv6_encap(switch_tunnel_index_t tunnel_index, bit<3> seg_len) {
        local_md.flags.routed = true;
        local_md.tunnel.type = SWITCH_EGRESS_TUNNEL_TYPE_SRV6_ENCAP;
        local_md.tunnel.index = tunnel_index;
        local_md.tunnel.srv6_seg_len = seg_len;
    }

    @name(".srv6_insert")
    action srv6_insert(bit<3> seg_len) {
        local_md.flags.routed = true;
        local_md.tunnel.type = SWITCH_EGRESS_TUNNEL_TYPE_SRV6_INSERT;
        local_md.tunnel.srv6_seg_len = seg_len;
    }

    @name(".tunnel_nexthop")
    table tunnel_nexthop {
        //Note: Nexthop table for type == Tunnel Encap | MPLS | SRv6
        key = { local_md.tunnel_nexthop : exact; }
        actions = {
            NoAction;
            l2_tunnel_encap;
            l3_tunnel_encap;
            l3_tunnel_encap_with_vni;







        }

        const default_action = NoAction;
        size = TUNNEL_NEXTHOP_TABLE_SIZE;
    }


    // **************** Control Flow  *************************
    apply {
        if (!local_md.flags.bypass_egress) {
            tunnel_nexthop.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// IP/MPLS Tunnel encapsulation - Step 2
//         -- Copy Outer Headers to inner
//         -- Add Tunnel Header (VXLAN, GRE etc)
//         -- MPLS Label Push
//-----------------------------------------------------------------------------
control TunnelEncap(inout switch_header_t hdr,
                    inout switch_local_metadata_t local_md)() {
    bit<16> payload_len;
    bit<8> ip_proto;
    bit<16> gre_proto;

    //
    // ************ Copy outer to inner **************************
    //
    action copy_ipv4_header() {
        // Copy all of the IPv4 header fields except checksum
        hdr.inner_ipv4.setValid();
        hdr.inner_ipv6.setInvalid();
        hdr.inner_ipv4.version = hdr.ipv4.version;
        hdr.inner_ipv4.ihl = hdr.ipv4.ihl;
        hdr.inner_ipv4.diffserv = hdr.ipv4.diffserv;
        hdr.inner_ipv4.total_len = hdr.ipv4.total_len;
        hdr.inner_ipv4.identification = hdr.ipv4.identification;
        hdr.inner_ipv4.flags = hdr.ipv4.flags;
        hdr.inner_ipv4.frag_offset = hdr.ipv4.frag_offset;
        hdr.inner_ipv4.ttl = hdr.ipv4.ttl;
        hdr.inner_ipv4.protocol = hdr.ipv4.protocol;
        // hdr.inner_ipv4.hdr_checksum = hdr.ipv4.hdr_checksum;
        hdr.inner_ipv4.src_addr = hdr.ipv4.src_addr;
        hdr.inner_ipv4.dst_addr = hdr.ipv4.dst_addr;
        local_md.inner_ipv4_checksum_update_en = true;
        hdr.ipv4.setInvalid();
    }

    action copy_inner_ipv4_udp() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        hdr.inner_udp = hdr.udp;
        hdr.udp.setInvalid();
        hdr.inner_udp.setValid();
        ip_proto = 4;
        gre_proto = 0x0800;
    }

/*
    action copy_inner_ipv4_tcp() {
        payload_len = hdr.ipv4.total_len;
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

        hdr.inner_ipv6 = hdr.ipv6;
        hdr.ipv6.setInvalid();
        hdr.inner_ipv4.setInvalid();

        hdr.inner_udp = hdr.udp;
        ip_proto = 41;
        gre_proto = 0x86dd;

        hdr.udp.setInvalid();
    }

/*
    action copy_inner_ipv6_tcp() {
        payload_len = hdr.ipv6.payload_len + 16w40;
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
        ip_proto = 41;
        gre_proto = 0x86dd;

        hdr.ipv6.setInvalid();
        hdr.inner_ipv4.setInvalid();
    }

    action copy_inner_non_ip() {
        payload_len = local_md.pkt_length - 16w14;
    }


    table tunnel_encap_0 {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.udp.isValid() : exact;
            // hdr.tcp.isValid() : exact; uncomment and add tcp actions if tcp header is parsed in egress
        }

        actions = {
            copy_inner_ipv4_udp;
            copy_inner_ipv4_unknown;
            copy_inner_ipv6_udp;
            copy_inner_ipv6_unknown;
            copy_inner_non_ip;
        }

        const entries = {
            (true, false, false) : copy_inner_ipv4_unknown();
            (false, true, false) : copy_inner_ipv6_unknown();
            (true, false, true) : copy_inner_ipv4_udp();
            (false, true, true) : copy_inner_ipv6_udp();
            (false, false, false) : copy_inner_non_ip();
        }
        size = 8;
    }

    //
    // ************ Add outer IP encapsulation **************************
    //
    action add_udp_header(bit<16> src_port, bit<16> dst_port) {
        hdr.udp.setValid();
        hdr.udp.src_port = src_port;
        hdr.udp.dst_port = dst_port;
        local_md.lkp.l4_src_port = src_port;
        local_md.lkp.l4_dst_port = dst_port;
        hdr.udp.checksum = 0;
        // hdr.udp.length = 0;

        local_md.lkp.l4_src_port = src_port;
        local_md.lkp.l4_dst_port = dst_port;
        local_md.lkp.tcp_flags = 0;

    }

    action clear_l4_lkp_fields() {

        local_md.lkp.l4_src_port = 0;
        local_md.lkp.l4_dst_port = 0;
        local_md.lkp.tcp_flags = 0;

    }

    action add_vxlan_header(bit<24> vni) {

        hdr.vxlan.setValid();
        hdr.vxlan.flags = 8w0x08;
        // hdr.vxlan.reserved = 0;
        hdr.vxlan.vni = vni;
        // hdr.vxlan.reserved2 = 0;

    }

    action add_gre_header(bit<16> proto) {





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
        hdr.ipv6.setInvalid();
        local_md.lkp.ip_proto = hdr.ipv4.protocol;
        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
    }

    action add_ipv6_header(bit<8> proto) {
        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w6;
        hdr.ipv6.flow_label = 0;
        // hdr.ipv6.payload_len = 0;
        hdr.ipv6.next_hdr = proto;
        hdr.ipv4.setInvalid();
        local_md.lkp.ip_proto = hdr.ipv6.next_hdr;
        local_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
    }


    @name(".encap_ipv4_vxlan")
    action encap_ipv4_vxlan(bit<16> vxlan_port) {
        hdr.inner_ethernet = hdr.ethernet;
        add_ipv4_header(17);
        hdr.ipv4.flags = 0x2;
        // Total length = packet length + 50
        //   IPv4 (20) + UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.ipv4.total_len = payload_len + hdr.ipv4.minSizeInBytes() +
        hdr.udp.minSizeInBytes() + hdr.vxlan.minSizeInBytes() + hdr.inner_ethernet.minSizeInBytes();
        add_udp_header(local_md.tunnel.hash, vxlan_port);
        // UDP length = packet length + 30
        //   UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.udp.length = payload_len + hdr.udp.minSizeInBytes() + hdr.vxlan.minSizeInBytes() + hdr.inner_ethernet.minSizeInBytes();
        // Pkt length
        local_md.pkt_length = local_md.pkt_length + hdr.ipv4.minSizeInBytes() +
        hdr.udp.minSizeInBytes() + hdr.vxlan.minSizeInBytes() + hdr.inner_ethernet.minSizeInBytes();

        add_vxlan_header(local_md.tunnel.vni);
        hdr.ethernet.ether_type = 0x0800;
    }
    @name(".encap_ipv6_vxlan")
    action encap_ipv6_vxlan(bit<16> vxlan_port) {
# 1940 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
    }


    @name(".encap_ipv4_ip")
    action encap_ipv4_ip() {
        add_ipv4_header(ip_proto);
        // Total length = packet length + 20
        //   IPv4 (20)
        hdr.ipv4.total_len = payload_len + hdr.ipv4.minSizeInBytes();
        // Pkt length
        local_md.pkt_length = local_md.pkt_length + hdr.ipv4.minSizeInBytes();
        hdr.ethernet.ether_type = 0x0800;
        clear_l4_lkp_fields();
    }

    @name(".encap_ipv6_ip")
    action encap_ipv6_ip() {
# 1966 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
    }
# 2106 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
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
    }
# 2262 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
    apply {
        //P4C-4655: Added extra check of valid tunnel_nexthop. tunnel.type field is not initialized to zero.
        if (!local_md.flags.bypass_egress && local_md.tunnel.type != SWITCH_EGRESS_TUNNEL_TYPE_NONE && local_md.tunnel_nexthop != 0) {
            // Copy L3/L4 header into inner headers.
            if (local_md.tunnel.type != SWITCH_EGRESS_TUNNEL_TYPE_SRV6_INSERT) {
                tunnel_encap_0.apply();
            }
            if (local_md.tunnel.type == SWITCH_EGRESS_TUNNEL_TYPE_MPLS) {







            } else {
                // Add outer IP encapsulation
                tunnel_encap_1.apply();
            }
        }
    }
}

//-----------------------------------------------------------------------------
// IP Tunnel Encapsulation - Step 3
//         -- Outer SIP Rewrite
//         -- Outer DIP Rewrite
//         -- TTL QoS Rewrite
//         -- MPLS TTL/EXP Rewrite
//-----------------------------------------------------------------------------
control TunnelRewrite(inout switch_header_t hdr, inout switch_local_metadata_t local_md)() {
    //
    // ***************** Outer SIP Rewrite **********************
    //
    @name(".ipv4_sip_rewrite")
    action ipv4_sip_rewrite(ipv4_addr_t src_addr, bit<8> ttl_val, bit<6> dscp_val) {
        hdr.ipv4.src_addr = src_addr;

        hdr.ipv4.ttl = ttl_val;
# 2309 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
    }

    @name(".ipv6_sip_rewrite")
    action ipv6_sip_rewrite(ipv6_addr_t src_addr, bit<8> ttl_val, bit<6> dscp_val) {
        hdr.ipv6.src_addr = src_addr;

        hdr.ipv6.hop_limit = ttl_val;
# 2324 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
    }

    @name(".src_addr_rewrite")
    table src_addr_rewrite {
        key = {
            local_md.tunnel.index : exact;
        }
        actions = {
            ipv4_sip_rewrite;



        }
        size = TUNNEL_OBJECT_SIZE;
    }

    //
    // ******** TTL - original header value for uniform mode, new configuration value for Pipe mode ******
    //
    @name(".encap_ttl_v4_in_v4_pipe")
    action encap_ttl_v4_in_v4_pipe(bit<8> ttl_val) {
        hdr.ipv4.ttl = ttl_val;
    }
    @name(".encap_ttl_v4_in_v6_pipe")
    action encap_ttl_v4_in_v6_pipe(bit<8> ttl_val) {
        hdr.ipv6.hop_limit = ttl_val;
    }
    @name(".encap_ttl_v6_in_v4_pipe")
    action encap_ttl_v6_in_v4_pipe(bit<8> ttl_val) {
        hdr.ipv4.ttl = ttl_val;
    }
    @name(".encap_ttl_v6_in_v6_pipe")
    action encap_ttl_v6_in_v6_pipe(bit<8> ttl_val) {
        hdr.ipv6.hop_limit = ttl_val;
    }
    @name(".encap_ttl_v4_in_v4_uniform")
    action encap_ttl_v4_in_v4_uniform() {
        hdr.ipv4.ttl = hdr.inner_ipv4.ttl;
    }
    @name(".encap_ttl_v4_in_v6_uniform")
    action encap_ttl_v4_in_v6_uniform() {
        hdr.ipv6.hop_limit = hdr.inner_ipv4.ttl;
    }
    @name(".encap_ttl_v6_in_v4_uniform")
    action encap_ttl_v6_in_v4_uniform() {
        hdr.ipv4.ttl = hdr.inner_ipv6.hop_limit;
    }
    @name(".encap_ttl_v6_in_v6_uniform")
    action encap_ttl_v6_in_v6_uniform() {
        hdr.ipv6.hop_limit = hdr.inner_ipv6.hop_limit;
    }

    @name(".tunnel_rewrite_encap_ttl")
    table encap_ttl {
        key = {
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            local_md.tunnel.index : exact;
        }
        actions = {
            NoAction;
            encap_ttl_v4_in_v4_pipe;
            encap_ttl_v4_in_v6_pipe;
            encap_ttl_v6_in_v4_pipe;
            encap_ttl_v6_in_v6_pipe;
            encap_ttl_v4_in_v4_uniform;
            encap_ttl_v4_in_v6_uniform;
            encap_ttl_v6_in_v4_uniform;
            encap_ttl_v6_in_v6_uniform;
        }
        const default_action = NoAction;
        size = TUNNEL_OBJECT_SIZE * 3;
    }

    //
    // ********************* DSCP/ ECN **************************
    // DSCP - original header value for uniform mode, new configuration value for Pipe mode
    // ECN - always copy inner to outer
    //
# 2422 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
    @name(".encap_dscp_v4_in_v4_uniform")
    action encap_dscp_v4_in_v4_uniform() {






    }
    @name(".encap_dscp_v4_in_v6_uniform")
    action encap_dscp_v4_in_v6_uniform() {
        // Note: Use inner_ipv4 since outer ipv4.diffserv is clobbered by
        //       new ipv6.flow_label due to different offset
        /* CODE_HACK Use @in_hash to decouple hdr.inner_ipv4.diffserv and
         * hdr.ipv6.traffic_class, so they don't have to share a cluster */
        @in_hash { hdr.ipv6.traffic_class = hdr.inner_ipv4.diffserv; }
        @in_hash { local_md.lkp.ip_tos = hdr.inner_ipv4.diffserv; }
    }
    @name(".encap_dscp_v6_in_v4_uniform")
    action encap_dscp_v6_in_v4_uniform() {
        /* CODE_HACK Use @in_hash to decouple hdr.ipv4.diffserv and
         * hdr.inner_ipv6.traffic_class, so they don't share a cluster */
        @in_hash { hdr.ipv4.diffserv = hdr.inner_ipv6.traffic_class; }
        @in_hash { local_md.lkp.ip_tos = hdr.inner_ipv6.traffic_class; }
    }
    @name(".encap_dscp_v6_in_v6_uniform")
    action encap_dscp_v6_in_v6_uniform() {






    }


    // Setting pipe mode for non-ip traffic, where ecn value should be 0.
    // This applies even when TUNNEL_QOS_MODE_ENABLE is not defined.
    // For ip traffic with pipe mode, instead rely on write of dscp value in
    // src_addr_rewrite, along with encap_dscp_..._ecn actions above.
    @name(".encap_dscp_v4_pipe_mode")
    action encap_dscp_v4_pipe_mode(bit<6> dscp_val) {
        hdr.ipv4.diffserv[1:0] = 0;
        hdr.ipv4.diffserv[7:2] = dscp_val;
 local_md.lkp.ip_tos[7:2] = dscp_val;
    }

    @name(".encap_dscp_v6_pipe_mode")
    action encap_dscp_v6_pipe_mode(bit<6> dscp_val) {
        hdr.ipv6.traffic_class[1:0] = 0;
        hdr.ipv6.traffic_class[7:2] = dscp_val;
 local_md.lkp.ip_tos[7:2] = dscp_val;
    }


    @name(".tunnel_rewrite_encap_dscp")
    table encap_dscp {
        key = {
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            local_md.tunnel.index : exact;
        }
        actions = {
            NoAction;






            encap_dscp_v4_in_v4_uniform;
            encap_dscp_v4_in_v6_uniform;
            encap_dscp_v6_in_v4_uniform;
            encap_dscp_v6_in_v6_uniform;


            encap_dscp_v4_pipe_mode;
            encap_dscp_v6_pipe_mode;

        }

        const default_action = NoAction;
        size = TUNNEL_OBJECT_SIZE * 3;
    }

    //
    // ************ Tunnel destination IP rewrite *******************
    //
    @name(".ipv4_dip_rewrite")
    action ipv4_dip_rewrite(ipv4_addr_t dst_addr) {
        hdr.ipv4.dst_addr = dst_addr;
    }

    @name(".ipv6_dip_rewrite")
    action ipv6_dip_rewrite(ipv6_addr_t dst_addr) {
        hdr.ipv6.dst_addr = dst_addr;
    }

    @name(".dst_addr_rewrite")
    table dst_addr_rewrite {
        key = { local_md.tunnel.dip_index : exact; }
        actions = {
            ipv4_dip_rewrite;



        }
        const default_action = ipv4_dip_rewrite(0);
        size = TUNNEL_ENCAP_IP_SIZE;
    }
# 2905 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
    //
    // ***************** Control Flow ***********************
    //
    apply {
        //P4C-4655: Added extra check of valid tunnel_nexthop. tunnel.type field is not initialized to zero.
        if (!local_md.flags.bypass_egress && local_md.tunnel_nexthop != 0 && local_md.tunnel.type != SWITCH_EGRESS_TUNNEL_TYPE_NONE) {
            if (local_md.tunnel.type == SWITCH_EGRESS_TUNNEL_TYPE_MPLS) {
# 2923 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/tunnel.p4"
            } else {
                dst_addr_rewrite.apply();
            }

            if ((local_md.tunnel.type != SWITCH_EGRESS_TUNNEL_TYPE_SRV6_INSERT) && (local_md.tunnel.type != SWITCH_EGRESS_TUNNEL_TYPE_MPLS)) {
                src_addr_rewrite.apply();



                encap_dscp.apply();
            }
        } else {

     if (hdr.ipv4.isValid()) {
  local_md.lkp.ip_tos = hdr.ipv4.diffserv;
     } else if (hdr.ipv6.isValid()) {
                @in_hash { local_md.lkp.ip_tos = hdr.ipv6.traffic_class; }
     }

 }
    }
}

//-----------------------------------------------------------------------------
// Egress BD to VNI translation
//      -- local_md.bd carries the ingress_bd at this place in the pipeline.
//
//-----------------------------------------------------------------------------
control VniMap(inout switch_header_t hdr,
                   inout switch_local_metadata_t local_md) {

    @name(".set_vni")
    action set_vni(switch_tunnel_vni_t vni) {
        local_md.tunnel.vni = vni;
    }

    @name(".bd_to_vni_mapping")
    table bd_to_vni_mapping {
        key = {
            local_md.bd[11:0] : exact;

            local_md.tunnel.mapper_index : exact;

        }
        actions = {
            set_vni;
        }

        const default_action = set_vni(0);
        size = BD_TO_VNI_MAPPING_SIZE;
    }

    @name(".vrf_to_vni_mapping") @use_hash_action(1)
    table vrf_to_vni_mapping {
        key = {
            local_md.vrf : exact;
        }
        actions = {
            set_vni;
        }

        const default_action = set_vni(0);
        size = VRF_TABLE_SIZE;
    }

    apply {
        if (!local_md.flags.bypass_egress && local_md.tunnel.vni==0) {
     if (local_md.flags.l2_tunnel_encap) {

  bd_to_vni_mapping.apply();

     } else {
  vrf_to_vni_mapping.apply();
     }
 }
    }
}

//-----------------------------------------------------------------------------
// This control uses bport_isolation_group as the flag that pkt
// come from peer_link and should not be tunnel encapsulated
//-----------------------------------------------------------------------------

control PeerLinkTunnelIsolation(inout switch_local_metadata_t local_md) {

    @name(".peer_link_isolate")
    action peer_link_isolate(bool drop) {
        local_md.flags.bport_isolation_packet_drop = drop;
    }
    @name(".peer_link_tunnel_isolation")
    table peer_link_tunnel_isolation {
        key = {
            local_md.bport_isolation_group : exact;
        }
        actions = {
            peer_link_isolate;
        }

        const default_action = peer_link_isolate(false);
        size = 1 << 2;
    }

    apply {

        if (local_md.tunnel.index != 0) {
            peer_link_tunnel_isolation.apply();
        }

    }
}
# 203 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/multicast.p4" 1
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
// IP Multicast
// @param src_addr : IP source address.
// @param grp_addr : IP group address.
// @param bd : Bridge domain.
// @param group_id : Multicast group id.
// @param s_g_table_size : (s, g) table size.
// @param star_g_table_size : (*, g) table size.
//-----------------------------------------------------------------------------
control MulticastBridge<T>(
        in ipv4_addr_t src_addr,
        in ipv4_addr_t grp_addr,
        in switch_bd_t bd,
        out switch_mgid_t group_id,
        out bit<1> multicast_hit)(
        switch_uint32_t s_g_table_size,
        switch_uint32_t star_g_table_size) {
    @name(".multicast_bridge_s_g_hit")
    action s_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }

    @name(".multicast_bridge_star_g_hit")
    action star_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }

    action star_g_miss() {
        multicast_hit = 0;
    }

    @name(".multicast_bridge_ipv4_s_g")
    table s_g {
        key = {
            bd : exact;
            src_addr : exact;
            grp_addr : exact;
        }

        actions = {
            NoAction;
            s_g_hit;
        }

        const default_action = NoAction;
        size = s_g_table_size;
    }

    @ways(2)
    @name(".multicast_bridge_ipv4_star_g")
    table star_g {
        key = {
            bd : exact;
            grp_addr : exact;
        }

        actions = {
            star_g_miss;
            star_g_hit;
        }

        const default_action = star_g_miss;
        size = star_g_table_size;
    }

    apply {
        switch(s_g.apply().action_run) {
            NoAction : { star_g.apply(); }
        }
    }
}

control MulticastBridgev6<T>(
        in ipv6_addr_t src_addr,
        in ipv6_addr_t grp_addr,
        in switch_bd_t bd,
        out switch_mgid_t group_id,
        out bit<1> multicast_hit)(
        switch_uint32_t s_g_table_size,
        switch_uint32_t star_g_table_size) {
    @name(".multicast_bridge_ipv6_s_g_hit")
    action s_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }

    @name(".multicast_bridge_ipv6_star_g_hit")
    action star_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }

    action star_g_miss() {
        multicast_hit = 0;
    }

    @name(".multicast_bridge_ipv6_s_g")
    table s_g {
        key = {
            bd : exact;
            src_addr : exact;
            grp_addr : exact;
        }

        actions = {
            NoAction;
            s_g_hit;
        }

        const default_action = NoAction;
        size = s_g_table_size;
    }

    @ways(2)
    @name(".multicast_bridge_ipv6_star_g")
    table star_g {
        key = {
            bd : exact;
            grp_addr : exact;
        }

        actions = {
            star_g_miss;
            star_g_hit;
        }

        const default_action = star_g_miss;
        size = star_g_table_size;
    }

    apply {
        switch(s_g.apply().action_run) {
            NoAction : { star_g.apply(); }
        }
    }
}

control MulticastRoute<T>(
        in ipv4_addr_t src_addr,
        in ipv4_addr_t grp_addr,
        in switch_vrf_t vrf,
        inout switch_multicast_metadata_t multicast_md,
        out switch_multicast_rpf_group_t rpf_check,
        out switch_mgid_t multicast_group_id,
        out bit<1> multicast_hit)(
        switch_uint32_t s_g_table_size,
        switch_uint32_t star_g_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) s_g_stats;
    //DirectCounter<bit<switch_counter_width>>(CounterType_t.PACKETS) star_g_stats;

    @name(".multicast_route_s_g_hit")
    action s_g_hit(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        s_g_stats.count();
    }

//    @name(".multicast_route_star_g_hit_bidir")
//    action star_g_hit_bidir(
//            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
//        multicast_group_id = mgid;
//        multicast_hit = 1;
//        // rpf check passes if rpf_check != 0
//        rpf_check = rpf_group & multicast_md.rpf_group;
//        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_BIDIR;
//        //star_g_stats.count();
//    }

    @name(".multicast_route_star_g_hit_sm")
    action star_g_hit_sm(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        // rpf check passes if rpf_check == 0
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        //star_g_stats.count();
    }

    // Source and Group address pair (S, G) lookup
    @name(".multicast_route_ipv4_s_g")
    table s_g {
        key = {
            vrf : exact;
            src_addr : exact;
            grp_addr : exact;
        }

        actions = {
            @defaultonly NoAction;
            s_g_hit;
        }

        const default_action = NoAction;
        size = s_g_table_size;
        counters = s_g_stats;
    }

    // Group address (*, G) lookup
    @ways(2)
    @name(".multicast_route_ipv4_star_g")
    table star_g {
        key = {
            vrf : exact;
            grp_addr : exact;
        }

        actions = {
            @defaultonly NoAction;
            star_g_hit_sm;
//            star_g_hit_bidir;
        }

        const default_action = NoAction;
        size = star_g_table_size;
        //counters = star_g_stats;
    }

    apply {
        if (!s_g.apply().hit) {
            star_g.apply();
        }
    }
}


control MulticastRoutev6<T>(
        in ipv6_addr_t src_addr,
        in ipv6_addr_t grp_addr,
        in switch_vrf_t vrf,
        inout switch_multicast_metadata_t multicast_md,
        out switch_multicast_rpf_group_t rpf_check,
        out switch_mgid_t multicast_group_id,
        out bit<1> multicast_hit)(
        switch_uint32_t s_g_table_size,
        switch_uint32_t star_g_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) s_g_stats;
    //DirectCounter<bit<switch_counter_width>>(CounterType_t.PACKETS) star_g_stats;

    @name(".multicast_route_ipv6_s_g_hit")
    action s_g_hit(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        s_g_stats.count();
    }

//    @name(".multicast_route_ipv6_star_g_hit_bidir")
//    action star_g_hit_bidir(
//            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
//        multicast_group_id = mgid;
//        multicast_hit = 1;
//        // rpf check passes if rpf_check != 0
//        rpf_check = rpf_group & multicast_md.rpf_group;
//        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_BIDIR;
//        //star_g_stats.count();
//    }
//
    @name(".multicast_route_ipv6_star_g_hit_sm")
    action star_g_hit_sm(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        // rpf check passes if rpf_check == 0
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        //star_g_stats.count();
    }

    // Source and Group address pair (S, G) lookup
    @name(".multicast_route_ipv6_s_g")
    table s_g {
        key = {
            vrf : exact;
            src_addr : exact;
            grp_addr : exact;
        }

        actions = {
            @defaultonly NoAction;
            s_g_hit;
        }

        const default_action = NoAction;
        size = s_g_table_size;
        counters = s_g_stats;
    }

    // Group address (*, G) lookup
    @ways(2)
    @name(".multicast_route_ipv6_star_g")
    table star_g {
        key = {
            vrf : exact;
            grp_addr : exact;
        }

        actions = {
            @defaultonly NoAction;
            star_g_hit_sm;
//            star_g_hit_bidir;
        }

        const default_action = NoAction;
        size = star_g_table_size;
        //counters = star_g_stats;
    }

    apply {
        if (!s_g.apply().hit) {
            star_g.apply();
        }
    }
}

control IngressMulticast(
        inout switch_header_t hdr,
        in switch_lookup_fields_t lkp,
        inout switch_local_metadata_t local_md)(
        switch_uint32_t ipv4_s_g_table_size,
        switch_uint32_t ipv4_star_g_table_size,
        switch_uint32_t ipv6_s_g_table_size,
        switch_uint32_t ipv6_star_g_table_size) {

    // For each rendezvous point (RP), there is a list of interfaces for which
    // the switch is the designated forwarder (DF).

    MulticastBridge<ipv4_addr_t>(ipv4_s_g_table_size, ipv4_star_g_table_size) ipv4_multicast_bridge;
    MulticastRoute<ipv4_addr_t>(ipv4_s_g_table_size, ipv4_star_g_table_size) ipv4_multicast_route;
    MulticastBridgev6<ipv6_addr_t>(
        ipv6_s_g_table_size, ipv6_star_g_table_size) ipv6_multicast_bridge;
    MulticastRoutev6<ipv6_addr_t>(ipv6_s_g_table_size, ipv6_star_g_table_size) ipv6_multicast_route;

    switch_multicast_rpf_group_t rpf_check;

    @name(".set_multicast_route")
    action set_multicast_route() {

 hdr.fp_bridged_md.fwd_type = SWITCH_FWD_TYPE_MC;
 hdr.fp_bridged_md.fwd_idx = (switch_fwd_idx_t)local_md.multicast.id;



        local_md.checks.mrpf = true;
        local_md.flags.routed = true;
    }

    @name(".set_multicast_bridge")
    action set_multicast_bridge(bool mrpf) {

 hdr.fp_bridged_md.fwd_type = SWITCH_FWD_TYPE_MC;
 hdr.fp_bridged_md.fwd_idx = (switch_fwd_idx_t)local_md.multicast.id;



        local_md.flags.routed = false;
        local_md.checks.mrpf = mrpf;
    }

    @name(".set_multicast_flood")
    action set_multicast_flood(bool mrpf, bool flood) {

 hdr.fp_bridged_md.fwd_type = SWITCH_FWD_TYPE_L2;
 hdr.fp_bridged_md.fwd_idx = (switch_fwd_idx_t)SWITCH_FLOOD;



        local_md.checks.mrpf = mrpf;
        local_md.flags.routed = false;
        local_md.flags.flood_to_multicast_routers = flood;
    }

    @name(".multicast_fwd_result")
    table fwd_result {
        key = {
            local_md.multicast.hit : ternary;
            lkp.ip_type : ternary;
            local_md.ipv4.multicast_snooping : ternary;
            local_md.ipv6.multicast_snooping : ternary;
            local_md.multicast.mode : ternary;
            rpf_check : ternary;
        }

        actions = {
            set_multicast_bridge;
            set_multicast_route;
            set_multicast_flood;
        }
 size = 512;
    }

    apply {
        if (lkp.ip_type == SWITCH_IP_TYPE_IPV4 && local_md.ipv4.multicast_enable) {
            ipv4_multicast_route.apply(hdr.ipv4.src_addr,
                                       hdr.ipv4.dst_addr,
                                       local_md.vrf,
                                       local_md.multicast,
                                       rpf_check,
                                       local_md.multicast.id,
                                       local_md.multicast.hit);
        } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6 && local_md.ipv6.multicast_enable) {

            ipv6_multicast_route.apply(hdr.ipv6.src_addr,
                                       hdr.ipv6.dst_addr,
                                       local_md.vrf,
                                       local_md.multicast,
                                       rpf_check,
                                       local_md.multicast.id,
                                       local_md.multicast.hit);

        }

        if (local_md.multicast.hit == 0 ||
//            (local_md.multicast.mode == SWITCH_MULTICAST_MODE_PIM_BIDIR && rpf_check == 0) ||
            (local_md.multicast.mode == SWITCH_MULTICAST_MODE_PIM_SM && rpf_check != 0)) {

            if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                ipv4_multicast_bridge.apply(hdr.ipv4.src_addr,
                                            hdr.ipv4.dst_addr,
                                            local_md.bd,
                                            local_md.multicast.id,
                                            local_md.multicast.hit);
            } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {

                ipv6_multicast_bridge.apply(hdr.ipv6.src_addr,
                                            hdr.ipv6.dst_addr,
                                            local_md.bd,
                                            local_md.multicast.id,
                                            local_md.multicast.hit);

            }
        }

        fwd_result.apply();
    }
}



//-----------------------------------------------------------------------------
// Multicast flooding
//-----------------------------------------------------------------------------
control MulticastFlooding(inout switch_local_metadata_t local_md)(switch_uint32_t table_size) {

    @name(".mcast_flood")
    action flood(switch_mgid_t mgid) {
        local_md.multicast.id = mgid;
    }

    @name(".bd_flood")
    table bd_flood {
        key = {
            local_md.bd : exact @name("bd");
            local_md.lkp.pkt_type : exact @name("pkt_type");

            local_md.flags.flood_to_multicast_routers : exact @name("flood_to_multicast_routers");

        }

        actions = { flood; }
        size = table_size;
    }

    apply {
        bd_flood.apply();
    }
}

//-----------------------------------------------------------------------------
// Egress/Tunnel Multicast Replication DB
//-----------------------------------------------------------------------------

control Replication(in egress_intrinsic_metadata_t eg_intr_md,
                             inout switch_local_metadata_t local_md)(
                             switch_uint32_t table_size=4096) {

    // L3 Multicast with local ports only
    @name(".mc_rid_hit")
    action rid_hit_mc(switch_bd_t bd) {
        local_md.checks.same_bd = bd ^ local_md.bd;
        local_md.bd = bd;
    }


    // Tunnel Replication for L2MC/Flood
    @name(".tunnel_rid_hit")
    action rid_hit_tunnel(switch_nexthop_t nexthop, switch_nexthop_t tunnel_nexthop) {
        local_md.nexthop = nexthop;
        local_md.tunnel_nexthop = tunnel_nexthop;
    }


    // Tunnel Replication for L3MC
    @name(".tunnel_mc_rid_hit")
    action rid_hit_tunnel_mc(switch_bd_t bd, switch_nexthop_t nexthop, switch_nexthop_t tunnel_nexthop) {
        local_md.checks.same_bd = bd ^ local_md.bd;
        local_md.bd = bd;
        local_md.nexthop = nexthop;
        local_md.tunnel_nexthop = tunnel_nexthop;
    }


    // L2MC/Flood-with-local-ports-only - No need to program this table
    action rid_miss() {
        local_md.flags.routed = false;
    }

    @name(".rid")
    table rid {
        key = { eg_intr_md.egress_rid : exact; }
        actions = {
            rid_miss;
            rid_hit_mc;

            rid_hit_tunnel;

            rid_hit_tunnel_mc;


        }

        size = table_size;
        const default_action = rid_miss;
    }

    apply {
        if (eg_intr_md.egress_rid != 0) {
            rid.apply();

            if (local_md.checks.same_bd == 0)
                local_md.flags.routed = false;

        }
    }
}
# 204 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/qos.p4" 1
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





# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/acl.p4" 1
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


# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/acl2.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2022 Intel Corporation
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
# 21 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/acl.p4" 2
# 24 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/qos.p4" 2

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

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

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

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

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
        switch_uint32_t dscp_map_size=4096,
        switch_uint32_t pcp_map_size=512) {

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
            local_md.ingress_port : exact;
            local_md.lkp.ip_tos[7:2] : exact;
        }

        actions = {
            NoAction;
            set_ingress_tc;
            set_ingress_color;
            set_ingress_tc_and_color;
        }

        const default_action = NoAction;
        size = dscp_map_size;
    }

    @name(".ingress_qos_map.pcp_tc_map")
    table pcp_tc_map {
        key = {
            local_md.ingress_port : exact;
            local_md.lkp.pcp : exact;
        }

        actions = {
            NoAction;
            set_ingress_tc;
            set_ingress_color;
            set_ingress_tc_and_color;
        }

        const default_action = NoAction;
        size = pcp_map_size;
    }
# 241 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/qos.p4"
    apply {





        /*
        If IP packet:
            - Lookup DSCP-TC map if attached to the port
            - If result is no action
                - Lookup PCP-TC map
        else if non-IP packet:
            - Lookup PCP-TC map
        */
        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_QOS != 0)) {
            if (local_md.lkp.ip_type != SWITCH_IP_TYPE_NONE) {
                switch(dscp_tc_map.apply().action_run) {
                    NoAction : { pcp_tc_map.apply(); }
                }
            } else {
                pcp_tc_map.apply();
            }
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
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) ppg_stats;
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

    // Overwrites 6-bit dscp only.
    @name(".egress_qos.set_ipv6_dscp")
    action set_ipv6_dscp(bit<6> dscp, bit<3> exp) {

        hdr.ipv6.traffic_class[7:2] = dscp;
        local_md.tunnel.mpls_encap_exp = exp;

    }

    @name(".egress_qos.set_vlan_pcp")
    action set_vlan_pcp(bit<3> pcp, bit<3> exp) {
        local_md.qos.pcp = pcp;
        local_md.tunnel.mpls_encap_exp = exp;
    }

    // This is asymmetric table.
    // To support 32 TC, 3 Colors and 64 ports, table requires 12K entries.
    // If we need to support more TCs, need to increase the table size.
    @name(".egress_qos.l3_qos_map")
    table l3_qos_map {
        key = {
            port : exact @name("port");
            local_md.qos.tc : exact @name("tc");
            local_md.qos.color : exact @name("color");
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }

        actions = {
            NoAction;
            set_ipv4_dscp;
            set_ipv6_dscp;
        }

        const default_action = NoAction;
        size = 12288;
    }

    @name(".egress_qos.l2_qos_map")
    table l2_qos_map {
        key = {
            port : exact @name("port");
            local_md.qos.tc : exact @name("tc");
            local_md.qos.color : exact @name("color");
        }

        actions = {
            NoAction;
            set_vlan_pcp;
        }

        const default_action = NoAction;
        size = 6144;
    }

    apply {

        if (!local_md.flags.bypass_egress) {
            l2_qos_map.apply();
            l3_qos_map.apply();
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
# 205 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/meter.p4" 1
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





# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/acl.p4" 1
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


# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/acl2.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2022 Intel Corporation
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
# 21 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/acl.p4" 2
# 24 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/meter.p4" 2

//-------------------------------------------------------------------------------------------------
// Storm Control
//
// Monitors incoming traffic and prevents the excessive traffic on a particular interface by
// dropping the traffic. Each port has separate storm control levels for each types of traffic
// (broadcast, unknown multicast, and unknown unicast).
//
// @param local_md : Ingress metadata fields
// @param pkt_type : One of Unicast, Multicast, or Broadcast packet types.
// @param flag : Indicating whether the packet should get dropped or not.
// @param table_size : Size of the storm control table [per pipe]
// @param meter_size : Size of storm control meters
// Stats table size must be 512 per pipe - each port with 6 stat entries [2 colors per pkt-type]
//-------------------------------------------------------------------------------------------------
control StormControl(inout switch_local_metadata_t local_md,
                     in switch_pkt_type_t pkt_type,
                     out bool flag)(
                     switch_uint32_t table_size=256,
                     switch_uint32_t meter_size=1024) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) storm_control_stats;
    @name(".storm_control.meter")
    Meter<bit<16>>(meter_size, MeterType_t.BYTES) meter;

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

     local_md.multicast.hit : ternary;

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

     local_md.multicast.hit : ternary;

        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {

        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_STORM_CONTROL != 0))
            storm_control.apply();

        if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_STORM_CONTROL != 0))
            stats.apply();

    }
}

//-------------------------------------------------------------------------------------------------
// Ingress Mirror Meter
//-------------------------------------------------------------------------------------------------
control IngressMirrorMeter(inout switch_local_metadata_t local_md)(
                     switch_uint32_t table_size=256) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

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

            meter_index.apply();
            meter_action.apply();

    }
}

//-------------------------------------------------------------------------------------------------
// Egress Mirror Meter
//-------------------------------------------------------------------------------------------------
control EgressMirrorMeter(inout switch_local_metadata_t local_md)(
                     switch_uint32_t table_size=256) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
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

            meter_index.apply();
            meter_action.apply();

    }
}


//-------------------------------------------------------------------------------------------------
// Ingress Port Meter
//-------------------------------------------------------------------------------------------------
control IngressPortMeter(inout switch_local_metadata_t local_md)(
                     switch_uint32_t table_size=256) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    @name(".ingress_port_meter.meter")
    Meter<bit<9>>(table_size, MeterType_t.BYTES) meter;
    switch_pkt_color_t color;

    @name(".ingress_port_meter.count")
    action count() {
        stats.count();
        local_md.flags.port_meter_drop = false;
    }

    @name(".ingress_port_meter.drop_and_count")
    action drop_and_count() {
        stats.count();
        local_md.flags.port_meter_drop = true;
    }

    @name(".ingress_port_meter.meter_action")
    table meter_action {
        key = {
            color: exact;
            local_md.qos.port_meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            count;
            drop_and_count;
        }

        const default_action = NoAction;
        size = table_size*3;
        counters = stats;
    }

    @name(".ingress_port_meter.set_meter")
    action set_meter(bit<9> index) {
        color = (bit<2>) meter.execute(index);
    }

    @name(".ingress_port_meter.meter_index")
    table meter_index {
        key = {
            local_md.qos.port_meter_index : exact;
        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
            meter_index.apply();
            meter_action.apply();
    }
}



//-------------------------------------------------------------------------------------------------
// Egress Port Meter
//-------------------------------------------------------------------------------------------------
control EgressPortMeter(inout switch_local_metadata_t local_md)(
                     switch_uint32_t table_size=256) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    @name(".egress_port_meter.meter")
    Meter<bit<9>>(table_size, MeterType_t.BYTES) meter;
    switch_pkt_color_t color;

    @name(".egress_port_meter.count")
    action count() {
        stats.count();
        local_md.flags.port_meter_drop = false;
    }

    @name(".egress_port_meter.drop_and_count")
    action drop_and_count() {
        stats.count();
        local_md.flags.port_meter_drop = true;
    }

    @name(".egress_port_meter.meter_action")
    table meter_action {
        key = {
            color: exact;
            local_md.qos.port_meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            count;
            drop_and_count;
        }

        const default_action = NoAction;
        size = table_size*3;
        counters = stats;
    }

    @name(".egress_port_meter.set_meter")
    action set_meter(bit<9> index) {
        color = (bit<2>) meter.execute(index);
    }

    @name(".egress_port_meter.meter_index")
    table meter_index {
        key = {
            local_md.qos.port_meter_index : exact;
        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
            meter_index.apply();
            meter_action.apply();
    }
}



//-------------------------------------------------------------------------------------------------
// Ingress ACL Meter
//-------------------------------------------------------------------------------------------------
control IngressAclMeter(inout switch_local_metadata_t local_md)(
                     switch_uint32_t table_size=256) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    @name(".ingress_acl_meter.meter")
    Meter<bit<9>>(table_size, MeterType_t.BYTES) meter;
    switch_pkt_color_t color;

    @name(".ingress_acl_meter.count")
    action count(switch_packet_action_t packet_action) {
        stats.count();
        local_md.flags.meter_packet_action = packet_action;
    }

    @name(".ingress_acl_meter.meter_action")
    table meter_action {
        key = {
            color: exact;
            local_md.qos.acl_meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        size = table_size*3;
        counters = stats;
    }

    @name(".ingress_acl_meter.set_meter")
    action set_meter(bit<9> index) {
        color = (bit<2>) meter.execute(index);
    }

    @name(".ingress_acl_meter.meter_index")
    table meter_index {
        key = {
            local_md.qos.acl_meter_index : exact;
        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
            meter_index.apply();
            meter_action.apply();
    }
}



//-------------------------------------------------------------------------------------------------
// Egress ACL Meter
//-------------------------------------------------------------------------------------------------
control EgressAclMeter(inout switch_local_metadata_t local_md)(
                     switch_uint32_t table_size=256) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    @name(".egress_acl_meter.meter")
    Meter<bit<9>>(table_size, MeterType_t.BYTES) meter;
    switch_pkt_color_t color;

    @name(".egress_acl_meter.count")
    action count(switch_packet_action_t packet_action) {
        stats.count();
        local_md.flags.meter_packet_action = packet_action;
    }

    @name(".egress_acl_meter.meter_action")
    table meter_action {
        key = {
            color: exact;
            local_md.qos.acl_meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        size = table_size*3;
        counters = stats;
    }

    @name(".egress_acl_meter.set_meter")
    action set_meter(bit<9> index) {
        color = (bit<2>) meter.execute(index);
    }

    @name(".egress_acl_meter.meter_index")
    table meter_index {
        key = {
            local_md.qos.acl_meter_index : exact;
        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
            meter_index.apply();
            meter_action.apply();
    }
}
# 206 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/wred.p4" 1
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
             inout switch_local_metadata_t local_md,
             in egress_intrinsic_metadata_t eg_intr_md,
             out bool wred_drop) {

    switch_wred_index_t index;

    // Flag indicating that the packet needs to be marked/dropped.
    bit<1> wred_flag;
    const switch_uint32_t wred_size = 1 << 10;

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

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
# 207 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/acl.p4" 1
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


# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/acl2.p4" 1
/*******************************************************************************
 *  INTEL CONFIDENTIAL
 *
 *  Copyright (c) 2022 Intel Corporation
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
# 21 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/acl.p4" 2
# 208 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/nat2.p4" 1
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
# 40 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/nat2.p4"
control DestNat(inout switch_local_metadata_t local_md)() {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) dnat_pool_stats;
    @name(".set_dnat_pool_hit")
    action set_dnat_pool_hit() {
        local_md.nat.dnat_pool_hit = true;
        dnat_pool_stats.count();
    }

    @name(".set_dnat_pool_miss")
    action set_dnat_pool_miss() {
        local_md.nat.dnat_pool_hit = false;
        dnat_pool_stats.count();
    }

    @name(".dnat_pool")
    table dnat_pool {
        key = {
            local_md.lkp.ip_dst_addr[95:64] : exact;
        }
        actions = {
            set_dnat_pool_hit;
            set_dnat_pool_miss;
        }
        counters = dnat_pool_stats;
        const default_action = set_dnat_pool_miss;
        size = NAT_POOL_TABLE_SIZE;
    }

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) dest_napt_stats;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) dest_nat_stats;

    @name(".dnapt_miss")
    action dnapt_miss() {
        local_md.nat.hit = SWITCH_NAT_HIT_TYPE_DEST_NONE;
        dest_napt_stats.count();
    }

    @name(".dnat_miss")
    action dnat_miss() {
        local_md.nat.hit = SWITCH_NAT_HIT_TYPE_DEST_NONE;
        dest_nat_stats.count();
    }

    @name(".set_dnapt_rewrite")
    action set_dnapt_rewrite(ipv4_addr_t dip, bit<16> dport) {
        local_md.lkp.ip_dst_addr[95:64] = dip;
        local_md.lkp.l4_dst_port = dport;
        local_md.nat.hit = SWITCH_NAT_HIT_TYPE_DEST_NAPT;
        dest_napt_stats.count();
    }

    @name(".set_dnat_rewrite")
    action set_dnat_rewrite(ipv4_addr_t dip) {
        local_md.lkp.ip_dst_addr[95:64] = dip;
        local_md.nat.hit = SWITCH_NAT_HIT_TYPE_DEST_NAT;
        dest_nat_stats.count();
    }

    @name(".dest_napt")
    table dest_napt {
        key = {
            local_md.lkp.ip_dst_addr[95:64] : exact; local_md.lkp.ip_proto : exact; local_md.lkp.l4_dst_port : exact;
        }
        actions = {
            set_dnapt_rewrite;
            dnapt_miss;
        }
        const default_action = dnapt_miss;
        size = NAPT_TABLE_SIZE;
        counters = dest_napt_stats;
        idle_timeout = true;
    }

    @name(".dest_nat")
    table dest_nat {
        key = {
            local_md.lkp.ip_dst_addr[95:64] : exact;
        }
        actions = {
            set_dnat_rewrite;
            dnat_miss;
        }
        const default_action = dnat_miss;
        size = NAT_TABLE_SIZE;
        counters = dest_nat_stats;
        idle_timeout = true;
    }

    apply {
        if(local_md.nat.nat_disable == false) {
            if(local_md.nat.ingress_zone == SWITCH_NAT_OUTSIDE_ZONE_ID) {
                switch(dnat_pool.apply().action_run) {
                    set_dnat_pool_hit : {
                        switch(dest_napt.apply().action_run) {
                            set_dnapt_rewrite : {}
                            dnapt_miss: {dest_nat.apply();}
                        }
                    }
                }
            }
        }
    }
}

control SourceNat(inout switch_local_metadata_t local_md)() {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) src_napt_stats;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) src_nat_stats;

    @name(".set_snapt_rewrite")
    action set_snapt_rewrite(ipv4_addr_t sip, bit<16> sport) {
        local_md.lkp.ip_src_addr[95:64] = sip;
        local_md.lkp.l4_src_port = sport;
        local_md.nat.hit = SWITCH_NAT_HIT_TYPE_SRC_NAPT;
        src_napt_stats.count();
    }
    @name(".set_snat_rewrite")
    action set_snat_rewrite(ipv4_addr_t sip) {
        local_md.lkp.ip_src_addr[95:64] = sip;
        local_md.nat.hit = SWITCH_NAT_HIT_TYPE_SRC_NAT;
        src_nat_stats.count();
    }

    @name(".source_napt_miss")
    action source_napt_miss() {
        src_napt_stats.count();
        local_md.nat.hit = SWITCH_NAT_HIT_TYPE_SRC_NONE;
    }
    @name(".source_nat_miss")
    action source_nat_miss() {
        local_md.nat.hit = SWITCH_NAT_HIT_TYPE_SRC_NONE;
        src_nat_stats.count();
    }

    @name(".source_nat")
    table source_nat {
        key = {
            local_md.lkp.ip_src_addr[95:64] : exact;
        }
        actions = {
            set_snat_rewrite;
            source_nat_miss;
        }
        const default_action = source_nat_miss;
        size = NAT_TABLE_SIZE;
        counters = src_nat_stats;
        idle_timeout = true;
    }

    @name(".source_napt")
    table source_napt {
        key = {
            local_md.lkp.ip_src_addr[95:64] : exact; local_md.lkp.ip_proto : exact; local_md.lkp.l4_src_port : exact;
        }
        actions = {
            set_snapt_rewrite;
            source_napt_miss;
        }
        const default_action = source_napt_miss;
        size = NAPT_TABLE_SIZE;
        counters = src_napt_stats;
        idle_timeout = true;
    }

    apply {
        if(local_md.nat.ingress_zone == SWITCH_NAT_INSIDE_ZONE_ID && local_md.nat.nat_disable == false) {
            switch(source_napt.apply().action_run) {
                set_snapt_rewrite: {}
                source_napt_miss: {source_nat.apply();}
            }
        }
    }

}

control IngressNatRewrite(inout switch_header_t hdr, inout switch_local_metadata_t local_md)() {
    @name(".rewrite_tcp_ipda")
    action rewrite_tcp_ipda() {
        hdr.ipv4.dst_addr = local_md.lkp.ip_dst_addr[95:64];
        hdr.tcp.dst_port = local_md.lkp.l4_dst_port;
    }
    @name(".rewrite_udp_ipda")
    action rewrite_udp_ipda() {
        hdr.ipv4.dst_addr = local_md.lkp.ip_dst_addr[95:64];
        hdr.udp.dst_port = local_md.lkp.l4_dst_port;
    }
    @name(".rewrite_ipda")
    action rewrite_ipda() {
        hdr.ipv4.dst_addr = local_md.lkp.ip_dst_addr[95:64];
    }
    @name(".rewrite_ipsa")
    action rewrite_ipsa() {
        hdr.ipv4.src_addr = local_md.lkp.ip_src_addr[95:64];
    }
    @name(".rewrite_tcp_ipsa")
    action rewrite_tcp_ipsa() {
        hdr.ipv4.src_addr = local_md.lkp.ip_src_addr[95:64];
        hdr.tcp.src_port = local_md.lkp.l4_src_port;
    }
    @name(".rewrite_udp_ipsa")
    action rewrite_udp_ipsa() {
        hdr.ipv4.src_addr = local_md.lkp.ip_src_addr[95:64];
        hdr.udp.src_port = local_md.lkp.l4_src_port;
    }
    @name(".ingress_nat_rewrite")
    table ingress_nat_rewrite {
        key = {
            local_md.nat.hit : exact;
            local_md.lkp.ip_proto : exact;
            local_md.checks.same_zone_check : ternary;
        }
        actions = {
            rewrite_tcp_ipda;
            rewrite_udp_ipda;
            rewrite_ipda;
            rewrite_tcp_ipsa;
            rewrite_udp_ipsa;
            rewrite_ipsa;
        }
        size = 512;
    }
    apply {
        ingress_nat_rewrite.apply();
    }
}
# 209 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/fold.p4" 1
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
# 210 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/util.p4" 1
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


# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/types.p4" 1
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
# 21 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/util.p4" 2



//-------------------------------------------------------------------------------------------------
// Pack qid and icos into the same byte
//-------------------------------------------------------------------------------------------------
control BridgedMDPack(inout switch_header_t hdr, inout switch_local_metadata_t local_md)() {

    action set_bridged_md_fields() {
        hdr.fp_bridged_md.qid_icos[7:5] = local_md.qos.icos;
        hdr.fp_bridged_md.qid_icos[4:0] = local_md.qos.qid;
 hdr.fp_bridged_md.ingress_bd_tt_myip[12:0] = local_md.bd;
 hdr.fp_bridged_md.ingress_bd_tt_myip[13:13] = (bit<1>)local_md.tunnel.terminate;
 hdr.fp_bridged_md.ingress_bd_tt_myip[15:14] = local_md.flags.myip;
    }

    table bridged_md_pack {
        actions = {
            set_bridged_md_fields;
        }

        const default_action = set_bridged_md_fields();
        size = 256;
    }

    apply {
        bridged_md_pack.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// Set drop reason for internal bridged_md in folded pipeline
//-------------------------------------------------------------------------------------------------
control SetIG0DropReason(inout switch_header_t hdr, in switch_local_metadata_t local_md) {

    action update_drop_reason(switch_drop_reason_t drop_reason) {
        hdr.fp_bridged_md.drop_reason = drop_reason;
    }

    action copy_from_l2_drop_reason() {
        hdr.fp_bridged_md.drop_reason = local_md.l2_drop_reason;
    }

    action copy_from_drop_reason() {
        hdr.fp_bridged_md.drop_reason = local_md.drop_reason;
    }

    table drop_reason_update {
        key = {
                local_md.l2_drop_reason : ternary;
                local_md.flags.port_vlan_miss : ternary;
                local_md.stp.state_ : ternary;
        }
        actions = {
            update_drop_reason;
            copy_from_l2_drop_reason;
            copy_from_drop_reason;
        }
        default_action = copy_from_drop_reason();
        size = 512;

        const entries = {
     // Previous L2 drops
            (SWITCH_DROP_REASON_SRC_MAC_ZERO, _, _) : copy_from_l2_drop_reason();
            (SWITCH_DROP_REASON_DST_MAC_ZERO, _, _) : copy_from_l2_drop_reason();
            (SWITCH_DROP_REASON_SRC_MAC_MULTICAST, _, _) : copy_from_l2_drop_reason();
            (SWITCH_DROP_REASON_OUTER_SRC_MAC_ZERO, _, _) : copy_from_l2_drop_reason();
            (SWITCH_DROP_REASON_OUTER_DST_MAC_ZERO, _, _) : copy_from_l2_drop_reason();
            (SWITCH_DROP_REASON_OUTER_SRC_MAC_MULTICAST, _, _) : copy_from_l2_drop_reason();
            (SWITCH_DROP_REASON_DMAC_RESERVED, _, _) : copy_from_l2_drop_reason();
     // additional L2 drop reasons
            (0, true, _) : update_drop_reason(SWITCH_DROP_REASON_PORT_VLAN_MAPPING_MISS);
            (0, false, SWITCH_STP_STATE_LEARNING) : update_drop_reason(SWITCH_DROP_REASON_STP_STATE_LEARNING);
            (0, false, SWITCH_STP_STATE_BLOCKING) : update_drop_reason(SWITCH_DROP_REASON_INGRESS_STP_STATE_BLOCKING);
     // previous non-L2 drops
            (0, false, SWITCH_STP_STATE_FORWARDING) : copy_from_drop_reason();
        }
    }

    apply {
        drop_reason_update.apply();
    }
}
# 211 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2
# 1 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/shared/sflow.p4" 1
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
# 212 "/data/bf-p4c-compilers/master-git/p4-tests/p4_16/switch_16/p4src/switch-tofino/switch_tofino_x7.p4" 2

//-----------------------------------------------------------------------------
// Control Flow
//-----------------------------------------------------------------------------

@pa_no_overlay("pipe_0", "ingress", "smac_src_move")

//=============================================================================
// Begining of Logical Ingress Pipeline - using ingress stage of external pipe
//=============================================================================
control SwitchIngress_0(
    inout switch_header_t hdr,
    inout switch_local_metadata_t local_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    IngressPortMapping(PORT_VLAN_TABLE_SIZE, BD_TABLE_SIZE) ingress_port_mapping;
    PktValidation() pkt_validation;
    IngressSTP() stp;
    SMAC(MAC_TABLE_SIZE) smac;
    IngressTunnel() tunnel;
    IngressMulticast(IPV4_MULTICAST_S_G_TABLE_SIZE,
        IPV4_MULTICAST_STAR_G_TABLE_SIZE,
        IPV6_MULTICAST_S_G_TABLE_SIZE,
        IPV6_MULTICAST_STAR_G_TABLE_SIZE) multicast;
    Fibv6(IPV6_HOST_TABLE_SIZE, IPV6_HOST64_TABLE_SIZE, IPV6_LPM_TABLE_SIZE, IPV6_LPM64_TABLE_SIZE) ipv6_fib;
    IngressMacAcl(INGRESS_MAC_ACL_TABLE_SIZE) ingress_mac_acl;
    IngressQoSMap() qos_map;
    IngressTC() traffic_class;
    PPGStats() ppg_stats;
    IngressPortMeter() port_meter;
    SameMacCheck() same_mac_check;
    action fold_4_pipe() { ig_intr_md_for_tm.ucast_egress_port = (ig_intr_md.ingress_port + 0x80); } action fold_2_pipe() { ig_intr_md_for_tm.ucast_egress_port = (ig_intr_md.ingress_port ^ 0x80); } action set_egress_port(switch_port_t dev_port) { ig_intr_md_for_tm.ucast_egress_port = dev_port; } table fold { key = { ig_intr_md.ingress_port : exact; } actions = { fold_2_pipe; fold_4_pipe; set_egress_port; } size = MIN_TABLE_SIZE; default_action = fold_4_pipe; }
    AclEtype() acl_etype1;
    AclMacAddr() qos_acl_mac;
    LOU() qos_acl_lou;
    IngressQosAcl(INGRESS_IP_QOS_ACL_TABLE_SIZE) ingress_ip_qos_acl;
    SetIG0DropReason() set_drop_reason;
    BridgedMDPack() bridged_md_pack;

    apply {
        // Check Packet headers
        pkt_validation.apply(hdr, local_md);

        // PV Mapping
        ingress_port_mapping.apply(hdr, local_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);

        // Ingress L2 Features
        stp.apply(local_md, local_md.stp);

        // QoS classification
        qos_map.apply(hdr, local_md);

        // Tunnel Termination Check
        tunnel.apply(hdr, local_md, local_md.lkp);

        // Same Mac Check for non-termination cases only
        same_mac_check.apply(hdr, local_md);

        // Source MAC lookup for learning
        smac.apply(local_md.lkp.mac_src_addr, local_md.lkp.mac_dst_addr, local_md, ig_intr_md_for_dprsr.digest_type);

        // L2 ACLs
        ingress_mac_acl.apply(hdr, local_md);

        // Ethertype compression for ACL keys
        acl_etype1.apply(local_md);
        // MAC Address compression for ACL keys
        qos_acl_mac.apply(local_md.ingress_port_lag_index,
                          local_md.lkp.mac_src_addr,
                          local_md.lkp.mac_dst_addr,
                          local_md.qos_mac_label);
        // L4 Port range check for ACLs
        qos_acl_lou.apply(local_md);
        // QoS ACL
        ingress_ip_qos_acl.apply(hdr, local_md);

        // IP multicast for both V4/V6 and IPv6 FIB
        if (!((local_md.bypass & SWITCH_INGRESS_BYPASS_L3 != 0) || (local_md.bypass & SWITCH_INGRESS_BYPASS_L2 != 0)) && local_md.lkp.pkt_type == SWITCH_PKT_TYPE_MULTICAST && (local_md.lkp.ip_type != SWITCH_IP_TYPE_NONE)) {
            multicast.apply(hdr, local_md.lkp, local_md);
        } else if (local_md.flags.rmac_hit) {
            if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_L3 != 0) && (local_md.lkp.ip_type == SWITCH_IP_TYPE_IPV6) && local_md.ipv6.unicast_enable) {
                ipv6_fib.apply(local_md.lkp.ip_dst_addr, local_md);
            }
        }

        // TC->(Queue, icos) Mappping
        traffic_class.apply(local_md);

        ppg_stats.apply(local_md);

        //
        // Bridged metadata header is added here first and can be modified in other
        // logical ingress pipeline stages
        //
        hdr.fp_bridged_md.setValid();
        hdr.fp_bridged_md.pkt_type = local_md.lkp.pkt_type;
        hdr.fp_bridged_md.routed = local_md.flags.routed;
        hdr.fp_bridged_md.timestamp = local_md.timestamp;
        hdr.fp_bridged_md.tc = local_md.qos.tc;
        hdr.fp_bridged_md.color = local_md.qos.color;
        hdr.fp_bridged_md.drop_reason = local_md.drop_reason;

        hdr.fp_bridged_md.fib_lpm_miss = local_md.flags.fib_lpm_miss;
        hdr.fp_bridged_md.fib_drop = local_md.flags.fib_drop;
        hdr.fp_bridged_md.rmac_hit = local_md.flags.rmac_hit;
        hdr.fp_bridged_md.acl_deny = local_md.flags.acl_deny;
        hdr.fp_bridged_md.copy_cancel = local_md.flags.copy_cancel;
        hdr.fp_bridged_md.multicast_hit = local_md.multicast.hit;
        hdr.fp_bridged_md.hostif_trap_id = local_md.hostif_trap_id;
        set_drop_reason.apply(hdr, local_md);
        bridged_md_pack.apply(hdr, local_md);

        /* CODE_HACK : This could be done in l3.p4 as well but we need to do it for ipv6 only
           and currently v4/v6 share common p4 actions. */
        if (local_md.nexthop!=0) {
            hdr.fp_bridged_md.fwd_type = SWITCH_FWD_TYPE_L3;
            hdr.fp_bridged_md.fwd_idx =(switch_fwd_idx_t)local_md.nexthop;
        }
        fold.apply();

        ig_intr_md_for_tm.qid = local_md.qos.qid;
        ig_intr_md_for_tm.ingress_cos = local_md.qos.icos;
    }
}

//==================================================================================
// Continuation of logical ingress pipeline using egress stage of the internal pipe
//==================================================================================

// using physical naming convention for intrinsic metadata (egress)
// using logical naming convention for internal metadata (ingress)

@pa_alias("pipe_1", "egress", "hdr.fp_bridged_md.ingress_port", "local_md.ingress_port")
//@pa_alias("pipe_1", "egress", "hdr.fp_bridged_md.ingress_bd", "local_md.bd")
//@pa_alias("pipe_1", "egress", "hdr.fp_bridged_md.pkt_type", "local_md.lkp.pkt_type")
//@pa_alias("pipe_1", "egress", "hdr.fp_bridged_md.routed", "local_md.flags.routed")
//timestamp
//@pa_alias("pipe_1", "egress", "hdr.fp_bridged_md.tc", "local_md.qos.tc")
//@pa_alias("pipe_1", "egress", "hdr.fp_bridged_md.qid", "local_md.qos.qid")
//@pa_alias("pipe_1", "egress", "hdr.fp_bridged_md.icos", "local_md.qos.icos")
//@pa_alias("pipe_1", "egress", "hdr.fp_bridged_md.color", "local_md.qos.color")
//@pa_alias("pipe_1", "egress", "hdr.fp_bridged_md.vrf", "local_md.qos.vrf")
//tunnel.terminate
//ipv4_checksum_err
//link-local
//rmac-hit
//fib-drop
//fib-lpm-miss
//multicast_hit
@pa_alias("pipe_1", "egress", "hdr.fp_bridged_md.copy_cancel", "local_md.flags.copy_cancel")
@pa_alias("pipe_1", "egress", "hdr.fp_bridged_md.acl_deny", "local_md.flags.acl_deny")
@pa_alias("pipe_1", "egress", "hdr.fp_bridged_md.nat_disable", "local_md.nat.nat_disable")
//myip
//drop reason
//@pa_alias("pipe_1", "egress", "hdr.fp_bridged_md.hostif_trap_id", "local_md.hostif_trap_id")
//@pa_alias("pipe_1", "egress", "hdr.fp_bridged_md.mirror_session_id", "local_md.mirror.session_id")
control SwitchEgress_1(
    inout switch_header_t hdr,
    inout switch_local_metadata_t local_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    LOU() ip_acl_lou;
    AclEtype() acl_etype2;
    AclMacAddr() pbr_acl_mac;
    AclMacAddr() mirror_acl_mac;
    IngressIpv4Acl(INGRESS_IPV4_ACL_TABLE_SIZE) ingress_ipv4_acl;
    IngressIpv6Acl(INGRESS_IPV6_ACL_TABLE_SIZE) ingress_ipv6_acl;
    IngressMirrorAcl(INGRESS_IP_MIRROR_ACL_TABLE_SIZE) ingress_ip_mirror_acl;
    LkpFieldsI1E1() pkt_validation;
    PortBDState_EG_1() port_bd_state_eg_1;
    ingress_intrinsic_metadata_for_tm_t unused;
    IngressPbrAcl(INGRESS_IP_PBR_ACL_TABLE_SIZE) ingress_ip_acl;

    apply {
        // Derive lookup fields from either outer or inner headers
        pkt_validation.apply(hdr, local_md);
        // Port/Vlan/RIF State
        port_bd_state_eg_1.apply(hdr, local_md);

        // L4 Port range check for ACLs
        ip_acl_lou.apply(local_md);
        // Ethertype compression for ACL keys
        acl_etype2.apply(local_md);
        // MAC Address compression for ACL keys
        pbr_acl_mac.apply(local_md.ingress_port_lag_index,
                          local_md.lkp.mac_src_addr,
                          local_md.lkp.mac_dst_addr,
                          local_md.pbr_mac_label);
        mirror_acl_mac.apply(local_md.ingress_port_lag_index,
                             local_md.lkp.mac_src_addr,
                             local_md.lkp.mac_dst_addr,
                             local_md.mirror_mac_label);

        // IPv6/IPv4 ACL
        if (local_md.lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
            ingress_ipv6_acl.apply(local_md);
        } else if (local_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
            ingress_ipv4_acl.apply(local_md);
        }

        // Mirror ACL
        ingress_ip_mirror_acl.apply(hdr, local_md);

        // PBR ACL
        ingress_ip_acl.apply(hdr, local_md);

        // Bridged Metadata
        hdr.fp_bridged_md.acl_deny = local_md.flags.acl_deny;
        hdr.fp_bridged_md.nat_disable = local_md.nat.nat_disable;
        hdr.fp_bridged_md.hostif_trap_id = local_md.hostif_trap_id;
    }
}

//==================================================================================
// Final step in logical ingress pipeline - using ingress stage of the internal pipe
//==================================================================================

control SwitchIngress_1(
    inout switch_header_t hdr,
    inout switch_local_metadata_t local_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    DMAC(MAC_TABLE_SIZE) dmac;
    IngressBd(BD_TABLE_SIZE) bd_stats;
    Fibv4(IPV4_HOST_TABLE_SIZE, IPV4_LPM_TABLE_SIZE) ipv4_fib;
    StormControl(STORM_CONTROL_TABLE_SIZE) storm_control;
    IngressPFCWd(512) pfc_wd;
    Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
    OuterFib() outer_fib;
    LAG() lag;
    MulticastFlooding(BD_FLOOD_TABLE_SIZE) flood;
    IngressSystemAcl() system_acl;
    DestNat() dest_nat;
    SourceNat() source_nat;
    IngressNatRewrite() ingress_nat_rewrite;
    LkpFieldsI1E1() pkt_validation;
    IngressPortMirror() port_mirror;
    PortBDState_IG_1() port_bd_state_ig_1;
    TunnelDecap() tunnel_decap;
    EnableFragHash() enable_frag_hash;
    Ipv4Hash() ipv4_hash;
    Ipv6Hash() ipv6_hash;
    OuterIpv4Hash() outer_ipv4_hash;
    OuterIpv6Hash() outer_ipv6_hash;
    NonIpHash() non_ip_hash;
    Lagv4Hash() lagv4_hash;
    Lagv6Hash() lagv6_hash;
    IngressSflow() sflow;
    FwdIdxDemux() fwd_idx_demux;

    apply {
        fwd_idx_demux.apply(hdr, local_md);

        // Derive lookup fields from either outer or inner headers
        pkt_validation.apply(hdr, local_md);
        // Port/Vlan/RIF State
        port_bd_state_ig_1.apply(hdr, ig_intr_md_for_tm, local_md);

        // NAT
        if (local_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
            dest_nat.apply(local_md);
            source_nat.apply(local_md);
        }

        // Ingress port mirror
        if (local_md.mirror.session_id == 0) {
            port_mirror.apply(local_md.ingress_port, local_md.mirror);
        } else {
            local_md.mirror.type = 1;
            local_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        }

        if(local_md.egress_port_lag_index == 0) {
            // IPv4 Route, ACL + DMAC Lookup
            if (local_md.flags.rmac_hit) {
                if (local_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                    if (!(local_md.bypass & SWITCH_INGRESS_BYPASS_L3 != 0) && local_md.ipv4.unicast_enable && (local_md.nexthop==0)) {
                        ipv4_fib.apply(local_md.lkp.ip_dst_addr[95:64], local_md);
                    }
                }
            } else {
                dmac.apply(local_md.lkp.mac_dst_addr, local_md);
            }
        }

        // Hash calculation for ECMP, LAG, Tunnels, DTEL, Multicast
        enable_frag_hash.apply(local_md.lkp);
        if (local_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
            lagv4_hash.apply(local_md.lkp, local_md.lag_hash);
        } else if (local_md.lkp.ip_type == SWITCH_IP_TYPE_NONE) {
            non_ip_hash.apply(hdr, local_md, local_md.lag_hash);
        } else {
            lagv6_hash.apply(local_md.lkp, local_md.lag_hash);
        }

        if (local_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
            ipv4_hash.apply(local_md.lkp, local_md.ecmp_hash);
            outer_ipv4_hash.apply(local_md.lkp, local_md.outer_ecmp_hash);
        } else {
            ipv6_hash.apply(local_md.lkp, local_md.ecmp_hash);
            outer_ipv6_hash.apply(local_md.lkp, local_md.outer_ecmp_hash);
        }

        // sflow
        sflow.apply(local_md);

        // Nexthop
        nexthop.apply(local_md);

        // Outer ECMP/Nexthop
        outer_fib.apply(local_md);

        // Storm control for broadcast/unknown unicast and unknown multicast
        storm_control.apply(local_md, local_md.lkp.pkt_type, local_md.flags.storm_control_drop);

        // PFC Watchdog
        pfc_wd.apply(local_md.ingress_port, local_md.qos.qid, local_md.flags.pfc_wd_drop);

        // VLAN/RIF Stats
        bd_stats.apply(local_md.bd, hdr, local_md.lkp.pkt_type);

        if (local_md.lkp.mac_type == 0x8808) {
            /* Redirect PFC frames to corresponding external port */
            ig_intr_md_for_tm.ucast_egress_port = local_md.ingress_port;
        } else if (local_md.multicast.hit == 0) {
            // Lag/Flood
            if (local_md.egress_port_lag_index == SWITCH_FLOOD) {
                flood.apply(local_md);
            } else {
                lag.apply(local_md, local_md.lag_hash, ig_intr_md_for_tm.ucast_egress_port);
            }
        }

        // System ACL
        system_acl.apply(hdr, local_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);

        // no rewrites if packet was redirected to cpu
        if (local_md.flags.redirect_to_cpu==false) {
            if (local_md.tunnel.terminate==false) {
                // Nat Rewrite
                if ((local_md.nat.hit != SWITCH_NAT_HIT_NONE) && (local_md.nat.nat_disable == false)) {
                    ingress_nat_rewrite.apply(hdr,local_md);
                }
            } else {
                // Tunnel Decapsulation
                tunnel_decap.apply(hdr, local_md);
            }
        }

        // Update Bridged Metadata
        hdr.bridged_md.setValid();
        hdr.bridged_md.src = SWITCH_PKT_SRC_BRIDGED;
        hdr.bridged_md.base.ingress_port = local_md.ingress_port;
        hdr.bridged_md.base.ingress_port_lag_index = local_md.ingress_port_lag_index;
        hdr.bridged_md.base.ingress_bd = local_md.bd;
        hdr.bridged_md.base.nexthop = local_md.nexthop;
        hdr.bridged_md.base.pkt_type = local_md.lkp.pkt_type;
        hdr.bridged_md.base.routed = local_md.flags.routed;
        if (local_md.flags.bypass_egress)
            hdr.bridged_md.base.bypass_egress = true;



        hdr.bridged_md.base.cpu_reason = local_md.cpu_reason;
        hdr.bridged_md.base.timestamp = local_md.timestamp;
        hdr.bridged_md.base.tc = local_md.qos.tc;
        hdr.bridged_md.base.qid = local_md.qos.qid;
        hdr.bridged_md.base.color = local_md.qos.color;
        hdr.bridged_md.base.vrf = local_md.vrf;

        hdr.bridged_md.tunnel.tunnel_nexthop = local_md.tunnel_nexthop;
        hdr.bridged_md.tunnel.hash = local_md.lag_hash[15:0];
        hdr.bridged_md.tunnel.terminate = local_md.tunnel.terminate;

        // Intrinsic metadata to TM
        ig_intr_md_for_tm.mcast_grp_b = local_md.multicast.id;
        // Set PRE hash values
        ig_intr_md_for_tm.level2_mcast_hash = local_md.lag_hash[28:16];
        ig_intr_md_for_tm.rid = (bit<16>)local_md.bd;
        ig_intr_md_for_tm.qid = local_md.qos.qid;
        ig_intr_md_for_tm.ingress_cos = local_md.qos.icos;
        if (local_md.tunnel.terminate) {
            ig_intr_md_for_tm.level1_exclusion_id = 16w1;
        }
    }
}

//==================================================================================
// Logical Egress pipeline - using egress stage of the external pipe
//==================================================================================

@pa_alias("pipe_0", "egress", "eg_intr_md_for_dprsr.mirror_type", "local_md.mirror.type")
control SwitchEgress_0(
    inout switch_header_t hdr,
    inout switch_local_metadata_t local_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    EgressPortMapping() egress_port_mapping;
    EgressPortMirror(288) port_mirror;
    EgressQoS() qos;
    EgressQueue() queue;
    EgressMacAcl(EGRESS_MAC_ACL_TABLE_SIZE) egress_mac_acl;
    EgressIpv4Acl(EGRESS_IPV4_ACL_TABLE_SIZE) egress_ipv4_acl;
    EgressIpv6Acl(EGRESS_IPV6_ACL_TABLE_SIZE) egress_ipv6_acl;
    AclMacAddr() egress_qos_acl_mac;
    AclMacAddr() egress_mirror_acl_mac;
    EgressQosAcl(EGRESS_QOS_ACL_TABLE_SIZE) egress_ip_qos_acl;
    EgressMirrorAcl(EGRESS_MIRROR_ACL_TABLE_SIZE) egress_ip_mirror_acl;
    EgressSystemAcl() system_acl;
    EgressPFCWd(512) pfc_wd;
    EgressVRF() egress_vrf;
    EgressBD() egress_bd;
    OuterNexthop() outer_nexthop;
    EgressBDStats() egress_bd_stats;
    MirrorRewrite() mirror_rewrite;
    VlanXlate(VLAN_TABLE_SIZE, PORT_VLAN_TABLE_SIZE) vlan_xlate;
    TunnelNexthop() tunnel_nexthop;
    TunnelEncap() tunnel_encap;
    TunnelRewrite() tunnel_rewrite;
    EgressCpuRewrite() cpu_rewrite;
    EgressPortIsolation() port_isolation;
    PeerLinkTunnelIsolation() peer_link_tunnel_isolation;
    Neighbor() neighbor;
    Replication() replication;
    VniMap() vni_map;
    MTU() mtu;
    WRED() wred;
    EgressSTP() stp;
    LkpFieldsE0_0() lkp_fields_0;
    LkpFieldsE0_1() lkp_fields_1;
//    EgressPacketValidation() egress_pkt_validation;
    VlanDecap() vlan_decap;

    apply {
        if (local_md.pkt_src != SWITCH_PKT_SRC_BRIDGED) {
            // Mirror packet rewrite
            mirror_rewrite.apply(hdr, local_md, eg_intr_md_for_dprsr);
        } else {
     // Extract packet header fields for ACL lookup - Step 1
     lkp_fields_0.apply(hdr, local_md);

            // Egress port properties
            egress_port_mapping.apply(hdr, local_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);

     // Remove VLAN header
            vlan_decap.apply(hdr, local_md);

            // Tunnel/Multicast( replication context
            replication.apply(eg_intr_md, local_md);

            // Egress Port Mirror
            port_mirror.apply(eg_intr_md.egress_port, local_md);

            // SMAC(inner for tunnel encap cases) derivation
            egress_vrf.apply(hdr, local_md);

            // Tunnel Nexthop lookup for rewrite information/indices. VNI for asymmetric IRB
            tunnel_nexthop.apply(hdr, local_md);

            // VRF/VLAN -> VNI Map
            vni_map.apply(hdr, local_md);

            // ECN Marking
            wred.apply(hdr, local_md, eg_intr_md, local_md.flags.wred_drop);

            // {TC, Color} -> {DSCP, PCP} maps
            qos.apply(hdr, eg_intr_md.egress_port, local_md);

            // Outer BD derivation
            outer_nexthop.apply(hdr, local_md);

            // Tunnel Encapsulation
            tunnel_encap.apply(hdr, local_md);

            // Outer SIP/DIP/QoS rewrite for encap cases
            tunnel_rewrite.apply(hdr, local_md);

     // Extract packet header fields for ACL lookup - Step 2
     lkp_fields_1.apply(hdr, local_md);

            // IPv4/v6 security ACLs
            if (hdr.ipv4.isValid()) {
                egress_ipv4_acl.apply(hdr, local_md);
            } else if (hdr.ipv6.isValid()) {
                egress_ipv6_acl.apply(hdr, local_md);
            }

            // Outer SMAC and MTU
            egress_bd.apply(hdr, local_md);

            // Outer DMAC
            neighbor.apply(hdr, local_md);

            // Push Qtag(s)
            vlan_xlate.apply(hdr, local_md);

            // Mirror/QoS ACL MAC Compression
            egress_qos_acl_mac.apply(local_md.egress_port_lag_index,
                                     hdr.ethernet.src_addr,
                                     hdr.ethernet.dst_addr,
                                     local_md.qos_mac_label);
            egress_mirror_acl_mac.apply(local_md.egress_port_lag_index,
                                        hdr.ethernet.src_addr,
                                        hdr.ethernet.dst_addr,
                                        local_md.mirror_mac_label);

            // MAC ACL
            egress_mac_acl.apply(hdr, local_md);

            // QoS ACL
            egress_ip_qos_acl.apply(hdr, local_md);

            // Mirror ACL
            egress_ip_mirror_acl.apply(hdr, local_md);

            // VLAN/RIF Stats
            egress_bd_stats.apply(hdr, local_md);

            // MTU Check
            mtu.apply(hdr, local_md);

            // PFC Watchdog
            pfc_wd.apply(eg_intr_md.egress_port, local_md.qos.qid, local_md.flags.pfc_wd_drop);

            // MLAG pruning
            port_isolation.apply(local_md, eg_intr_md);
            peer_link_tunnel_isolation.apply(local_md);

            // Egress STP Check
            stp.apply(local_md, eg_intr_md.egress_port, local_md.checks.stp);

            // Drop conditions + Mirror ACL
            system_acl.apply(hdr, local_md, eg_intr_md, eg_intr_md_for_dprsr);

            // Modify packets to CPU
            cpu_rewrite.apply(hdr, local_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);
        }
        // Queue Stats
        queue.apply(eg_intr_md.egress_port, local_md);





    }
}

//-----------------------------------------------------------------------------
// Pipeline
//-----------------------------------------------------------------------------

Pipeline<switch_header_t, switch_local_metadata_t, switch_header_t, switch_local_metadata_t>(
    SwitchIngressParser_0(),
    SwitchIngress_0(),
    SwitchIngressDeparser_0(),
    SwitchEgressParser_0(),
    SwitchEgress_0(),
    SwitchEgressDeparser_0()) pipe_0;

Pipeline<switch_header_t, switch_local_metadata_t, switch_header_t, switch_local_metadata_t>(
    SwitchIngressParser_1(),
    SwitchIngress_1(),
    SwitchIngressDeparser_1(),
    SwitchEgressParser_1(),
    SwitchEgress_1(),
    SwitchEgressDeparser_1()) pipe_1;

// Pkt path = SwitchIngress_0 -> SwitchEgress_1 -> SwitchIngress_1 -> SwitchEgress_0
Switch(pipe_0, pipe_1) main;
