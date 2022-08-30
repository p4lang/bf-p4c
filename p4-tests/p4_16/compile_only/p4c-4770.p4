#include <core.p4>
#include <tofino1_specs.p4>
#include <tofino1_base.p4>
#include <tofino1_arch.p4>

const bit<32> PORT_TABLE_SIZE = 288 * 2;
const bit<32> VLAN_TABLE_SIZE = 4096;
const bit<32> BD_FLOOD_TABLE_SIZE = VLAN_TABLE_SIZE * 4;
const bit<32> PORT_VLAN_TABLE_SIZE = 1024;
const bit<32> BD_TABLE_SIZE = 1024;
const bit<32> MAC_TABLE_SIZE = 16384;
const bit<32> IPV4_HOST_TABLE_SIZE = 8 * 1024;
const bit<32> IPV4_LPM_TABLE_SIZE = 8 * 1024;
const bit<32> IPV4_LOCAL_HOST_TABLE_SIZE = 8 * 1024;
const bit<32> IPV6_HOST_TABLE_SIZE = 32 * 1024;
const bit<32> IPV6_LPM_TABLE_SIZE = 10 * 1024;
const bit<32> IPV6_LPM64_TABLE_SIZE = 32 * 1024;
const bit<32> ECMP_GROUP_TABLE_SIZE = 128;
const bit<32> ECMP_SELECT_TABLE_SIZE = 4 * 1024;
const bit<32> NEXTHOP_TABLE_SIZE = 65536;
const bit<32> PRE_INGRESS_ACL_TABLE_SIZE = 128;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 128;
const bit<32> INGRESS_IP_MIRROR_ACL_TABLE_SIZE = 128;
const bit<32> INGRESS_IP_DTEL_ACL_TABLE_SIZE = 128;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 64;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 64;
const bit<32> STORM_CONTROL_TABLE_SIZE = 256;
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
@pa_container_size("ingress", "hdr.ethernet.src_addr", 16, 32) @pa_container_size("ingress", "hdr.ethernet.dst_addr", 16, 32) @pa_container_size("ingress", "hdr.ethernet.$valid", 16) header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16>    ether_type;
}

header vlan_tag_h {
    bit<3>    pcp;
    bit<1>    cfi;
    vlan_id_t vid;
    bit<16>   ether_type;
}

header mpls_h {
    bit<20> label;
    bit<3>  exp;
    bit<1>  bos;
    bit<8>  ttl;
}

header ipv4_h {
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffserv;
    bit<16>     total_len;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     frag_offset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header router_alert_option_h {
    bit<8>  type;
    bit<8>  length;
    bit<16> value;
}

header ipv4_option_h {
    bit<8>  type;
    bit<8>  length;
    bit<16> value;
}

header ipv6_h {
    bit<4>      version;
    bit<8>      traffic_class;
    bit<20>     flow_label;
    bit<16>     payload_len;
    bit<8>      next_hdr;
    bit<8>      hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

typedef bit<8> tcp_option_kind_t;
typedef bit<8> tcp_option_len_t;
typedef bit<8> tcp_int_val_t;
typedef bit<8> tcp_int_id_t;
typedef bit<24> tcp_int_lat_t;
header tcp_option_int_h {
    tcp_option_kind_t kind;
    tcp_option_len_t  len;
    tcp_int_val_t     val;
    tcp_int_val_t     uecr;
    tcp_int_id_t      id;
    tcp_int_id_t      idecr;
    tcp_int_lat_t     lat;
    tcp_int_lat_t     latecr;
}

header tcp_option_two_nops_h {
    tcp_option_kind_t nop1;
    tcp_option_kind_t nop2;
}

header tcp_option_ts_h {
    tcp_option_kind_t kind;
    tcp_option_len_t  len;
    bit<32>           tsval;
    bit<32>           tsecr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

header icmp_h {
    bit<8>  type;
    bit<8>  code;
    bit<16> checksum;
}

header igmp_h {
    bit<8>  type;
    bit<8>  code;
    bit<16> checksum;
}

header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8>  hw_addr_len;
    bit<8>  proto_addr_len;
    bit<16> opcode;
}

header rocev2_bth_h {
    bit<8>  opcodee;
    bit<1>  se;
    bit<1>  migration_req;
    bit<2>  pad_count;
    bit<4>  transport_version;
    bit<16> partition_key;
    bit<1>  f_res1;
    bit<1>  b_res1;
    bit<6>  reserved;
    bit<24> dst_qp;
    bit<1>  ack_req;
    bit<7>  reserved2;
}

header fcoe_fc_h {
    bit<4>   version;
    bit<100> reserved;
    bit<8>   sof;
    bit<8>   r_ctl;
    bit<24>  d_id;
    bit<8>   cs_ctl;
    bit<24>  s_id;
    bit<8>   type;
    bit<24>  f_ctl;
    bit<8>   seq_id;
    bit<8>   df_ctl;
    bit<16>  seq_cnt;
    bit<16>  ox_id;
    bit<16>  rx_id;
}

header ipv6_srh_h {
    bit<8>  next_hdr;
    bit<8>  hdr_ext_len;
    bit<8>  routing_type;
    bit<8>  seg_left;
    bit<8>  last_entry;
    bit<8>  flags;
    bit<16> tag;
}

header ipv6_segment_h {
    bit<128> sid;
}

header vxlan_h {
    bit<8>  flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8>  reserved2;
}

header vxlan_gpe_h {
    bit<8>  flags;
    bit<16> reserved;
    bit<24> vni;
    bit<8>  reserved2;
}

header gre_h {
    bit<1>  C;
    bit<1>  R;
    bit<1>  K;
    bit<1>  S;
    bit<1>  s;
    bit<3>  recurse;
    bit<5>  flags;
    bit<3>  version;
    bit<16> proto;
}

header nvgre_h {
    bit<32> vsid_flowid;
}

header erspan_h {
    bit<16> version_vlan;
    bit<16> session_id;
}

header erspan_type2_h {
    bit<32> index;
}

header erspan_type3_h {
    bit<32> timestamp;
    bit<32> ft_d_other;
}

header erspan_platform_h {
    bit<6>  id;
    bit<58> info;
}

header gtpu_h {
    bit<3>  version;
    bit<1>  p;
    bit<1>  t;
    bit<3>  spare0;
    bit<8>  mesg_type;
    bit<16> mesg_len;
    bit<32> teid;
    bit<24> seq_num;
    bit<8>  spare1;
}

header geneve_h {
    bit<2>  version;
    bit<6>  opt_len;
    bit<1>  oam;
    bit<1>  critical;
    bit<6>  reserved;
    bit<16> proto_type;
    bit<24> vni;
    bit<8>  reserved2;
}

header geneve_option_h {
    bit<16> opt_class;
    bit<8>  opt_type;
    bit<3>  reserved;
    bit<5>  opt_len;
}

header bfd_h {
    bit<3>  version;
    bit<5>  diag;
    bit<8>  flags;
    bit<8>  detect_multi;
    bit<8>  len;
    bit<32> my_discriminator;
    bit<32> your_discriminator;
    bit<32> desired_min_tx_interval;
    bit<32> req_min_rx_interval;
    bit<32> req_min_echo_rx_interval;
}

header dtel_report_v05_h {
    bit<4>  version;
    bit<4>  next_proto;
    bit<3>  d_q_f;
    bit<15> reserved;
    bit<6>  hw_id;
    bit<32> seq_number;
    bit<32> timestamp;
    bit<32> switch_id;
}

header dtel_report_base_h {
    bit<7>   pad0;
    PortId_t ingress_port;
    bit<7>   pad1;
    PortId_t egress_port;
    bit<3>   pad2;
    bit<5>   queue_id;
}

header dtel_drop_report_h {
    bit<8>  drop_reason;
    bit<16> reserved;
}

header dtel_switch_local_report_h {
    bit<5>  pad3;
    bit<19> queue_occupancy;
    bit<32> timestamp;
}

header dtel_report_v10_h {
    bit<4>  version;
    bit<4>  length;
    bit<3>  next_proto;
    bit<6>  metadata_bits;
    bit<6>  reserved;
    bit<3>  d_q_f;
    bit<6>  hw_id;
    bit<32> switch_id;
    bit<32> seq_number;
    bit<32> timestamp;
}

header dtel_report_v20_h {
    bit<4>  version;
    bit<4>  hw_id;
    bit<24> seq_number;
    bit<32> switch_id;
    bit<16> report_length;
    bit<8>  md_length;
    bit<3>  d_q_f;
    bit<5>  reserved;
    bit<16> rep_md_bits;
    bit<16> domain_specific_id;
    bit<16> ds_md_bits;
    bit<16> ds_md_status;
}

header dtel_metadata_1_h {
    bit<7>   pad0;
    PortId_t ingress_port;
    bit<7>   pad1;
    PortId_t egress_port;
}

header dtel_metadata_2_h {
    bit<32> hop_latency;
}

header dtel_metadata_3_h {
    bit<3>  pad2;
    bit<5>  queue_id;
    bit<5>  pad3;
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
    bit<3>  pad;
    bit<5>  queue_id;
    bit<8>  drop_reason;
    bit<16> reserved;
}

header fabric_h {
    bit<8> reserved;
    bit<3> color;
    bit<5> qos;
    bit<8> reserved2;
}

header cpu_h {
    bit<1>  tx_bypass;
    bit<1>  capture_ts;
    bit<1>  reserved;
    bit<5>  egress_queue;
    bit<16> ingress_port;
    bit<16> port_lag_index;
    bit<16> ingress_bd;
    bit<16> reason_code;
    bit<16> ether_type;
}

header timestamp_h {
    bit<48> timestamp;
}

typedef bit<8> tcp_int_index_t;
typedef bit<20> tcp_int_abytes_t;
typedef bit<16> tcp_int_hash_t;
typedef bit<3> tcp_int_port_speed_t;
const bit<32> MIN_TABLE_SIZE = 512;
const bit<32> LAG_TABLE_SIZE = 1024;
const bit<32> LAG_GROUP_TABLE_SIZE = 256;
const bit<32> LAG_MAX_MEMBERS_PER_GROUP = 64;
const bit<32> LAG_SELECTOR_TABLE_SIZE = 16384;
const bit<32> VRF_TABLE_SIZE = 1024;
const bit<32> DTEL_GROUP_TABLE_SIZE = 4;
const bit<32> DTEL_MAX_MEMBERS_PER_GROUP = 64;
const bit<32> DTEL_SELECTOR_TABLE_SIZE = 256;
const bit<32> IPV4_DST_VTEP_TABLE_SIZE = 512;
const bit<32> IPV6_DST_VTEP_TABLE_SIZE = 512;
const bit<32> VNI_MAPPING_TABLE_SIZE = 4096;
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
const switch_bd_t SWITCH_BD_DEFAULT_VRF = 4097;
typedef bit<8> switch_vrf_t;
typedef bit<16> switch_nexthop_t;
typedef bit<10> switch_user_metadata_t;
typedef bit<32> switch_hash_t;
typedef bit<128> srv6_sid_t;
typedef bit<16> switch_xid_t;
typedef bit<9> switch_yid_t;
typedef bit<32> switch_ig_port_lag_label_t;
typedef bit<16> switch_eg_port_lag_label_t;
typedef bit<16> switch_bd_label_t;
typedef bit<16> switch_if_label_t;
typedef bit<16> switch_mtu_t;
typedef bit<12> switch_stats_index_t;
typedef bit<16> switch_cpu_reason_t;
const switch_cpu_reason_t SWITCH_CPU_REASON_PTP = 8;
typedef bit<8> switch_fib_label_t;
struct switch_cpu_port_value_set_t {
    bit<16>       ether_type;
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
const switch_drop_reason_t SWITCH_DROP_REASON_SRV6_LOCAL_SID_DROP = 104;
const switch_drop_reason_t SWITCH_DROP_REASON_PORT_ISOLATION_DROP = 105;
typedef bit<1> switch_port_type_t;
const switch_port_type_t SWITCH_PORT_TYPE_NORMAL = 0;
const switch_port_type_t SWITCH_PORT_TYPE_CPU = 1;
typedef bit<2> switch_ip_type_t;
const switch_ip_type_t SWITCH_IP_TYPE_NONE = 0;
const switch_ip_type_t SWITCH_IP_TYPE_IPV4 = 1;
const switch_ip_type_t SWITCH_IP_TYPE_IPV6 = 2;
const switch_ip_type_t SWITCH_IP_TYPE_MPLS = 3;
typedef bit<2> switch_ip_frag_t;
const switch_ip_frag_t SWITCH_IP_FRAG_NON_FRAG = 0b0;
const switch_ip_frag_t SWITCH_IP_FRAG_HEAD = 0b10;
const switch_ip_frag_t SWITCH_IP_FRAG_NON_HEAD = 0b11;
typedef bit<16> switch_ingress_bypass_t;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L2 = 16w0x1;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L3 = 16w0x2;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ACL = 16w0x4;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SYSTEM_ACL = 16w0x8;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_QOS = 16w0x10;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_METER = 16w0x20;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STORM_CONTROL = 16w0x40;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STP = 16w0x80;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SMAC = 16w0x100;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_NAT = 16w0x200;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ALL = 16w0xffff;
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
typedef bit<8> switch_l4_port_label_t;
typedef bit<2> switch_stp_state_t;
const switch_stp_state_t SWITCH_STP_STATE_FORWARDING = 0;
const switch_stp_state_t SWITCH_STP_STATE_BLOCKING = 1;
const switch_stp_state_t SWITCH_STP_STATE_LEARNING = 2;
typedef bit<10> switch_stp_group_t;
struct switch_stp_metadata_t {
    switch_stp_group_t group;
    switch_stp_state_t state_;
}

typedef bit<2> switch_nexthop_type_t;
const switch_nexthop_type_t SWITCH_NEXTHOP_TYPE_IP = 0;
const switch_nexthop_type_t SWITCH_NEXTHOP_TYPE_MPLS = 1;
const switch_nexthop_type_t SWITCH_NEXTHOP_TYPE_TUNNEL_ENCAP = 2;
typedef bit<8> switch_sflow_id_t;
const switch_sflow_id_t SWITCH_SFLOW_INVALID_ID = 8w0xff;
struct switch_sflow_metadata_t {
    switch_sflow_id_t session_id;
    bit<1>            sample_packet;
}

typedef bit<8> switch_hostif_trap_t;
typedef bit<8> switch_copp_meter_id_t;
typedef bit<10> switch_meter_index_t;
typedef bit<8> switch_mirror_meter_id_t;
typedef bit<2> switch_qos_trust_mode_t;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_UNTRUSTED = 0;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_TRUST_DSCP = 1;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_TRUST_PCP = 2;
typedef bit<5> switch_qos_group_t;
typedef bit<8> switch_tc_t;
typedef bit<3> switch_cos_t;
typedef bit<11> switch_etrap_index_t;
typedef bit<2> switch_myip_type_t;
const switch_myip_type_t SWITCH_MYIP_NONE = 0;
const switch_myip_type_t SWITCH_MYIP = 1;
const switch_myip_type_t SWITCH_MYIP_SUBNET = 2;
struct switch_qos_metadata_t {
    switch_qos_trust_mode_t trust_mode;
    switch_qos_group_t      group;
    switch_tc_t             tc;
    switch_pkt_color_t      color;
    switch_pkt_color_t      acl_meter_color;
    switch_pkt_color_t      port_color;
    switch_pkt_color_t      flow_color;
    switch_pkt_color_t      storm_control_color;
    switch_meter_index_t    port_meter_index;
    switch_meter_index_t    acl_meter_index;
    switch_qid_t            qid;
    switch_ingress_cos_t    icos;
    bit<19>                 qdepth;
    switch_etrap_index_t    etrap_index;
    switch_pkt_color_t      etrap_color;
    switch_tc_t             etrap_tc;
    bit<1>                  etrap_state;
}

typedef bit<1> switch_learning_mode_t;
const switch_learning_mode_t SWITCH_LEARNING_MODE_DISABLED = 0;
const switch_learning_mode_t SWITCH_LEARNING_MODE_LEARN = 1;
struct switch_learning_digest_t {
    switch_bd_t             bd;
    switch_port_lag_index_t port_lag_index;
    mac_addr_t              src_addr;
}

struct switch_learning_metadata_t {
    switch_learning_mode_t   bd_mode;
    switch_learning_mode_t   port_mode;
    switch_learning_digest_t digest;
}

typedef bit<2> switch_multicast_mode_t;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_NONE = 0;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_SM = 1;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_BIDIR = 2;
typedef MulticastGroupId_t switch_mgid_t;
typedef bit<16> switch_multicast_rpf_group_t;
struct switch_multicast_metadata_t {
    switch_mgid_t                id;
    bit<2>                       mode;
    switch_multicast_rpf_group_t rpf_group;
}

typedef bit<2> switch_urpf_mode_t;
const switch_urpf_mode_t SWITCH_URPF_MODE_NONE = 0;
const switch_urpf_mode_t SWITCH_URPF_MODE_LOOSE = 1;
const switch_urpf_mode_t SWITCH_URPF_MODE_STRICT = 2;
typedef bit<10> switch_wred_index_t;
typedef bit<2> switch_ecn_codepoint_t;
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_NON_ECT = 0b0;
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_ECT0 = 0b10;
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_ECT1 = 0b1;
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_CE = 0b11;
const switch_ecn_codepoint_t NON_ECT = 0b0;
const switch_ecn_codepoint_t ECT0 = 0b10;
const switch_ecn_codepoint_t ECT1 = 0b1;
const switch_ecn_codepoint_t CE = 0b11;
typedef MirrorId_t switch_mirror_session_t;
const switch_mirror_session_t SWITCH_MIRROR_SESSION_CPU = 250;
typedef bit<8> switch_mirror_type_t;
struct switch_mirror_metadata_t {
    switch_pkt_src_t         src;
    switch_mirror_type_t     type;
    switch_mirror_session_t  session_id;
    switch_mirror_meter_id_t meter_index;
}

header switch_port_mirror_metadata_h {
    switch_pkt_src_t        src;
    switch_mirror_type_t    type;
    bit<32>                 timestamp;
    bit<6>                  _pad;
    switch_mirror_session_t session_id;
}

header switch_cpu_mirror_metadata_h {
    switch_pkt_src_t        src;
    switch_mirror_type_t    type;
    switch_port_padding_t   _pad1;
    switch_port_t           port;
    switch_bd_t             bd;
    bit<6>                  _pad2;
    switch_port_lag_index_t port_lag_index;
    switch_cpu_reason_t     reason_code;
}

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
const switch_tunnel_type_t SWITCH_EGRESS_TUNNEL_TYPE_SRV6 = 8;
enum switch_tunnel_term_mode_t {
    P2P,
    P2MP
}

typedef bit<4> switch_tunnel_index_t;
typedef bit<16> switch_tunnel_ip_index_t;
typedef bit<16> switch_tunnel_nexthop_t;
typedef bit<24> switch_tunnel_vni_t;
struct switch_tunnel_metadata_t {
    switch_tunnel_type_t     type;
    switch_tunnel_index_t    index;
    switch_tunnel_ip_index_t dip_index;
    switch_tunnel_vni_t      vni;
    switch_ifindex_t         ifindex;
    switch_tunnel_mode_t     qos_mode;
    switch_tunnel_mode_t     ttl_mode;
    bit<8>                   encap_ttl;
    bit<8>                   encap_dscp;
    bit<16>                  hash;
    bool                     terminate;
    bit<8>                   nvgre_flow_id;
    bit<2>                   mpls_pop_count;
    bit<3>                   mpls_push_count;
    bit<8>                   mpls_encap_ttl;
    bit<3>                   mpls_encap_exp;
    bit<1>                   mpls_swap;
    bit<128>                 srh_next_sid;
    bit<8>                   srh_seg_left;
    bit<8>                   srh_next_hdr;
    bit<3>                   srv6_seg_len;
    bit<6>                   srh_hdr_len;
    bool                     remove_srh;
    bool                     pop_active_segment;
    bool                     srh_decap_forward;
}

struct switch_nvgre_value_set_t {
    bit<32> vsid_flowid;
}

typedef bit<8> switch_dtel_report_type_t;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_NONE = 0b0;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_DROP = 0b100;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_QUEUE = 0b10;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_FLOW = 0b1;
const switch_dtel_report_type_t SWITCH_DTEL_SUPPRESS_REPORT = 0b1000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_IFA_CLONE = 0b10000;
const switch_dtel_report_type_t SWITCH_DTEL_IFA_EDGE = 0b100000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE = 0b1000000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_ETRAP_HIT = 0b10000000;
typedef bit<8> switch_ifa_sample_id_t;
typedef bit<6> switch_dtel_hw_id_t;
const bit<16> DTEL_REPORT_V0_5_OUTER_HEADERS_LENGTH = 46;
const bit<16> DTEL_REPORT_V2_OUTER_HEADERS_LENGTH = 58;
struct switch_dtel_metadata_t {
    switch_dtel_report_type_t report_type;
    bit<1>                    ifa_gen_clone;
    bit<1>                    ifa_cloned;
    bit<32>                   latency;
    switch_mirror_session_t   session_id;
    switch_mirror_session_t   clone_session_id;
    bit<32>                   hash;
    bit<2>                    drop_report_flag;
    bit<2>                    flow_report_flag;
    bit<1>                    queue_report_flag;
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
    switch_nat_zone_t             ingress_zone;
    bit<16>                       dnapt_index;
    bit<16>                       snapt_index;
    bool                          nat_disable;
    bool                          dnat_pool_hit;
}

header switch_dtel_switch_local_mirror_metadata_h {
    switch_pkt_src_t          src;
    switch_mirror_type_t      type;
    bit<32>                   timestamp;
    bit<6>                    _pad;
    switch_mirror_session_t   session_id;
    bit<32>                   hash;
    switch_dtel_report_type_t report_type;
    switch_port_padding_t     _pad2;
    switch_port_t             ingress_port;
    switch_port_padding_t     _pad3;
    switch_port_t             egress_port;
    bit<3>                    _pad4;
    switch_qid_t              qid;
    bit<5>                    _pad5;
    bit<19>                   qdepth;
    bit<32>                   egress_timestamp;
}

header switch_dtel_drop_mirror_metadata_h {
    switch_pkt_src_t          src;
    switch_mirror_type_t      type;
    bit<32>                   timestamp;
    bit<6>                    _pad;
    switch_mirror_session_t   session_id;
    bit<32>                   hash;
    switch_dtel_report_type_t report_type;
    switch_port_padding_t     _pad2;
    switch_port_t             ingress_port;
    switch_port_padding_t     _pad3;
    switch_port_t             egress_port;
    bit<3>                    _pad4;
    switch_qid_t              qid;
    switch_drop_reason_t      drop_reason;
}

header switch_simple_mirror_metadata_h {
    switch_pkt_src_t        src;
    switch_mirror_type_t    type;
    bit<6>                  _pad;
    switch_mirror_session_t session_id;
}

@flexible struct switch_bridged_metadata_dtel_extension_t {
    switch_dtel_report_type_t report_type;
    switch_mirror_session_t   session_id;
    bit<32>                   hash;
    switch_port_t             egress_port;
}

@pa_container_size("ingress", "ig_md.checks.same_if", 16) @pa_mutually_exclusive("ingress", "lkp.arp_opcode", "lkp.ip_src_addr") @pa_mutually_exclusive("ingress", "lkp.arp_opcode", "lkp.ip_dst_addr") @pa_mutually_exclusive("ingress", "lkp.arp_opcode", "lkp.ipv6_flow_label") @pa_mutually_exclusive("ingress", "lkp.arp_opcode", "lkp.ip_proto") @pa_mutually_exclusive("ingress", "lkp.arp_opcode", "lkp.ip_ttl") @pa_mutually_exclusive("ingress", "lkp.arp_opcode", "lkp.ip_tos") struct switch_ingress_flags_t {
    bool               ipv4_checksum_err;
    bool               inner_ipv4_checksum_err;
    bool               inner2_ipv4_checksum_err;
    bool               link_local;
    bool               routed;
    bool               acl_deny;
    bool               racl_deny;
    bool               port_vlan_miss;
    bool               rmac_hit;
    bool               dmac_miss;
    switch_myip_type_t myip;
    bool               glean;
    bool               storm_control_drop;
    bool               acl_meter_drop;
    bool               port_meter_drop;
    bool               flood_to_multicast_routers;
    bool               peer_link;
    bool               capture_ts;
    bool               mac_pkt_class;
    bool               pfc_wd_drop;
    bool               bypass_egress;
    bool               mpls_trap;
    bool               srv6_trap;
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
    bool isolation_packet_drop;
}

struct switch_ingress_checks_t {
    switch_port_lag_index_t same_if;
    bool                    mrpf;
    bool                    urpf;
}

struct switch_egress_checks_t {
    switch_bd_t  same_bd;
    switch_mtu_t mtu;
    bool         stp;
}

struct switch_ip_metadata_t {
    bool unicast_enable;
    bool multicast_enable;
    bool multicast_snooping;
}

struct switch_lookup_fields_t {
    switch_pkt_type_t    pkt_type;
    mac_addr_t           mac_src_addr;
    mac_addr_t           mac_dst_addr;
    bit<16>              mac_type;
    bit<3>               pcp;
    bit<16>              arp_opcode;
    switch_ip_type_t     ip_type;
    bit<8>               ip_proto;
    bit<8>               ip_ttl;
    bit<8>               ip_tos;
    switch_ip_frag_t     ip_frag;
    bit<128>             ip_src_addr;
    bit<128>             ip_dst_addr;
    bit<20>              ipv6_flow_label;
    bit<8>               tcp_flags;
    bit<16>              l4_src_port;
    bit<16>              l4_dst_port;
    bit<16>              hash_l4_src_port;
    bit<16>              hash_l4_dst_port;
    bool                 mpls_pkt;
    bit<1>               mpls_router_alert_label;
    bit<20>              mpls_lookup_label;
    switch_hostif_trap_t hostif_trap_id;
}

struct switch_hash_fields_t {
    mac_addr_t       mac_src_addr;
    mac_addr_t       mac_dst_addr;
    bit<16>          mac_type;
    switch_ip_type_t ip_type;
    bit<8>           ip_proto;
    bit<128>         ip_src_addr;
    bit<128>         ip_dst_addr;
    bit<16>          l4_src_port;
    bit<16>          l4_dst_port;
    bit<20>          ipv6_flow_label;
}

@flexible struct switch_bridged_metadata_t {
    switch_port_t           ingress_port;
    switch_port_lag_index_t ingress_port_lag_index;
    switch_bd_t             ingress_bd;
    switch_nexthop_t        nexthop;
    switch_pkt_type_t       pkt_type;
    bool                    routed;
    bool                    bypass_egress;
    switch_cpu_reason_t     cpu_reason;
    bit<32>                 timestamp;
    switch_tc_t             tc;
    switch_qid_t            qid;
    switch_pkt_color_t      color;
    switch_vrf_t            vrf;
}

@flexible struct switch_bridged_metadata_acl_extension_t {
    bit<16>                l4_src_port;
    bit<16>                l4_dst_port;
    bit<8>                 tcp_flags;
    switch_l4_port_label_t l4_src_port_label;
    switch_l4_port_label_t l4_dst_port_label;
}

@flexible struct switch_bridged_metadata_tunnel_extension_t {
    switch_tunnel_nexthop_t tunnel_nexthop;
    bool                    terminate;
}

@pa_atomic("ingress", "hdr.bridged_md.base_qid") @pa_container_size("ingress", "hdr.bridged_md.base_qid", 8) @pa_container_size("ingress", "hdr.bridged_md.dtel_report_type", 8) @pa_no_overlay("ingress", "hdr.bridged_md.base_qid") @pa_no_overlay("ingress", "hdr.bridged_md.__pad_0") @pa_no_overlay("ingress", "hdr.bridged_md.__pad_1") @pa_no_overlay("ingress", "hdr.bridged_md.__pad_2") @pa_no_overlay("ingress", "hdr.bridged_md.__pad_3") @pa_no_overlay("ingress", "hdr.bridged_md.__pad_4") @pa_no_overlay("ingress", "hdr.bridged_md.__pad_5") @pa_no_overlay("egress", "hdr.dtel_report.ingress_port") @pa_no_overlay("egress", "hdr.dtel_report.egress_port") @pa_no_overlay("egress", "hdr.dtel_report.queue_id") @pa_no_overlay("egress", "hdr.dtel_drop_report.drop_reason") @pa_no_overlay("egress", "hdr.dtel_drop_report.reserved") @pa_no_overlay("egress", "hdr.dtel_switch_local_report.queue_occupancy") @pa_mutually_exclusive("egress", "hdr.erspan_type3.timestamp", "hdr.erspan_type2.index") typedef bit<8> switch_bridge_type_t;
header switch_bridged_metadata_h {
    switch_pkt_src_t                         src;
    switch_bridge_type_t                     type;
    switch_bridged_metadata_t                base;
    switch_bridged_metadata_acl_extension_t  acl;
    switch_bridged_metadata_dtel_extension_t dtel;
}

struct switch_port_metadata_t {
    switch_port_lag_index_t    port_lag_index;
    switch_ig_port_lag_label_t port_lag_label;
}

typedef bit<2> switch_cons_hash_ip_seq_t;
const switch_cons_hash_ip_seq_t SWITCH_CONS_HASH_IP_SEQ_NONE = 0;
const switch_cons_hash_ip_seq_t SWITCH_CONS_HASH_IP_SEQ_SIPDIP = 1;
const switch_cons_hash_ip_seq_t SWITCH_CONS_HASH_IP_SEQ_DIPSIP = 2;
@pa_auto_init_metadata @pa_container_size("ingress", "ig_md.mirror.src", 8) @pa_container_size("ingress", "ig_md.mirror.type", 8) @pa_container_size("ingress", "smac_src_move", 16) @pa_alias("ingress", "ig_md.egress_port", "ig_intr_md_for_tm.ucast_egress_port") @pa_alias("ingress", "ig_md.qos.qid", "ig_intr_md_for_tm.qid") @pa_alias("ingress", "ig_md.qos.icos", "ig_intr_md_for_tm.ingress_cos") @pa_alias("ingress", "ig_intr_md_for_dprsr.mirror_type", "ig_md.mirror.type") @pa_container_size("ingress", "ig_md.egress_port_lag_index", 16) struct switch_ingress_metadata_t {
    switch_port_t               port;
    switch_port_t               egress_port;
    switch_port_lag_index_t     port_lag_index;
    switch_port_lag_index_t     egress_port_lag_index;
    switch_bd_t                 bd;
    switch_vrf_t                vrf;
    switch_nexthop_t            nexthop;
    switch_tunnel_nexthop_t     tunnel_nexthop;
    switch_nexthop_t            acl_nexthop;
    bool                        acl_port_redirect;
    switch_nexthop_t            unused_nexthop;
    bit<32>                     timestamp;
    switch_hash_t               hash;
    switch_hash_t               lag_hash;
    switch_ingress_flags_t      flags;
    switch_ingress_checks_t     checks;
    switch_ingress_bypass_t     bypass;
    switch_ip_metadata_t        ipv4;
    switch_ip_metadata_t        ipv6;
    switch_ig_port_lag_label_t  port_lag_label;
    switch_bd_label_t           bd_label;
    switch_if_label_t           if_label;
    switch_l4_port_label_t      l4_src_port_label;
    switch_l4_port_label_t      l4_dst_port_label;
    switch_drop_reason_t        l2_drop_reason;
    switch_drop_reason_t        drop_reason;
    switch_cpu_reason_t         cpu_reason;
    switch_lookup_fields_t      lkp;
    switch_hash_fields_t        hash_fields;
    switch_multicast_metadata_t multicast;
    switch_stp_metadata_t       stp;
    switch_qos_metadata_t       qos;
    switch_sflow_metadata_t     sflow;
    switch_tunnel_metadata_t    tunnel;
    switch_learning_metadata_t  learning;
    switch_mirror_metadata_t    mirror;
    switch_dtel_metadata_t      dtel;
    mac_addr_t                  same_mac;
    switch_user_metadata_t      user_metadata;
    bit<10>                     partition_key;
    bit<12>                     partition_index;
    switch_fib_label_t          fib_label;
    switch_cons_hash_ip_seq_t   cons_hash_v6_ip_seq;
}

@pa_container_size("egress", "eg_md.mirror.src", 8) @pa_container_size("egress", "eg_md.mirror.type", 8) @pa_container_size("egress", "hdr.dtel_drop_report.drop_reason", 8) @pa_mutually_exclusive("egress", "hdr.dtel.timestamp", "hdr.erspan_type3.timestamp") struct switch_egress_metadata_t {
    switch_pkt_src_t           pkt_src;
    switch_pkt_length_t        pkt_length;
    switch_pkt_type_t          pkt_type;
    switch_port_lag_index_t    port_lag_index;
    switch_port_type_t         port_type;
    switch_port_t              port;
    switch_port_t              ingress_port;
    switch_bd_t                bd;
    switch_vrf_t               vrf;
    switch_nexthop_t           nexthop;
    switch_tunnel_nexthop_t    tunnel_nexthop;
    bit<32>                    timestamp;
    bit<32>                    ingress_timestamp;
    switch_egress_flags_t      flags;
    switch_egress_checks_t     checks;
    switch_eg_port_lag_label_t port_lag_label;
    switch_bd_label_t          bd_label;
    switch_if_label_t          if_label;
    switch_l4_port_label_t     l4_src_port_label;
    switch_l4_port_label_t     l4_dst_port_label;
    switch_lookup_fields_t     lkp;
    switch_qos_metadata_t      qos;
    switch_tunnel_metadata_t   tunnel;
    switch_mirror_metadata_t   mirror;
    switch_dtel_metadata_t     dtel;
    switch_sflow_metadata_t    sflow;
    switch_cpu_reason_t        cpu_reason;
    switch_drop_reason_t       drop_reason;
    switch_nexthop_type_t      nexthop_type;
    bool                       inner_ipv4_checksum_update_en;
    bool                       tcp_int_update;
    tcp_int_val_t              tcp_int_val;
    bit<16>                    tcp_checksum;
    bit<32>                    latency;
}

struct switch_mirror_metadata_h {
    switch_port_mirror_metadata_h              port;
    switch_cpu_mirror_metadata_h               cpu;
    switch_dtel_drop_mirror_metadata_h         dtel_drop;
    switch_dtel_switch_local_mirror_metadata_h dtel_switch_local;
    switch_simple_mirror_metadata_h            simple_mirror;
}

struct switch_header_t {
    switch_bridged_metadata_h  bridged_md;
    ethernet_h                 ethernet;
    fabric_h                   fabric;
    cpu_h                      cpu;
    timestamp_h                timestamp;
    vlan_tag_h[2]              vlan_tag;
    mpls_h[3]                  mpls;
    ipv4_h                     ipv4;
    ipv4_option_h              ipv4_option;
    ipv6_h                     ipv6;
    arp_h                      arp;
    ipv6_srh_h                 srh_base;
    ipv6_segment_h[2]          srh_seg_list;
    udp_h                      udp;
    icmp_h                     icmp;
    igmp_h                     igmp;
    tcp_h                      tcp;
    tcp_option_int_h           tcpopt_int;
    tcp_option_ts_h            tcpopt_ts;
    tcp_option_two_nops_h      tcpopt_two_nops;
    dtel_report_v05_h          dtel;
    dtel_report_base_h         dtel_report;
    dtel_switch_local_report_h dtel_switch_local_report;
    dtel_drop_report_h         dtel_drop_report;
    rocev2_bth_h               rocev2_bth;
    gtpu_h                     gtp;
    vxlan_h                    vxlan;
    gre_h                      gre;
    nvgre_h                    nvgre;
    geneve_h                   geneve;
    erspan_h                   erspan;
    erspan_type2_h             erspan_type2;
    erspan_type3_h             erspan_type3;
    erspan_platform_h          erspan_platform;
    ethernet_h                 inner_ethernet;
    ipv4_h                     inner_ipv4;
    ipv6_h                     inner_ipv6;
    udp_h                      inner_udp;
    tcp_h                      inner_tcp;
    icmp_h                     inner_icmp;
    ipv4_h                     inner2_ipv4;
    ipv6_h                     inner2_ipv6;
    udp_h                      inner2_udp;
    tcp_h                      inner2_tcp;
    icmp_h                     inner2_icmp;
}

action add_bridged_md(inout switch_bridged_metadata_h bridged_md, in switch_ingress_metadata_t ig_md) {
    bridged_md.setValid();
    bridged_md.src = SWITCH_PKT_SRC_BRIDGED;
    bridged_md.base = { ig_md.port, ig_md.port_lag_index, ig_md.bd, ig_md.nexthop, ig_md.lkp.pkt_type, ig_md.flags.routed, ig_md.flags.bypass_egress, ig_md.cpu_reason, ig_md.timestamp, ig_md.qos.tc, ig_md.qos.qid, ig_md.qos.color, ig_md.vrf };
    bridged_md.acl = { ig_md.lkp.l4_src_port, ig_md.lkp.l4_dst_port, ig_md.lkp.tcp_flags, ig_md.l4_src_port_label, ig_md.l4_dst_port_label };
    bridged_md.dtel = { ig_md.dtel.report_type, ig_md.dtel.session_id, ig_md.lag_hash, ig_md.egress_port };
}
action set_ig_intr_md(in switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    ig_intr_md_for_tm.mcast_grp_b = ig_md.multicast.id;
    ig_intr_md_for_tm.level2_mcast_hash = ig_md.lag_hash[28:16];
    ig_intr_md_for_tm.qid = ig_md.qos.qid;
    ig_intr_md_for_tm.ingress_cos = ig_md.qos.icos;
}
action set_eg_intr_md(in switch_egress_metadata_t eg_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    eg_intr_md_for_dprsr.mirror_type = (bit<3>)eg_md.mirror.type;
}
control CalculateLatency(inout switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr) {
    action calc() {
        eg_md.latency = eg_intr_md_from_prsr.global_tstamp[31:0] - eg_md.ingress_timestamp[31:0];
    }
    apply {
        calc();
    }
}

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
        hash[31:0] = ipv4_hash.get({ ip_src_addr, ip_dst_addr, ip_proto, l4_dst_port, l4_src_port });
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
        hash[31:0] = ipv6_hash.get({ ipv6_flow_label, ip_src_addr, ip_dst_addr, ip_proto, l4_dst_port, l4_src_port });
    }
}

control NonIpHash(in switch_ingress_metadata_t ig_md, out switch_hash_t hash) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;
    mac_addr_t mac_dst_addr = ig_md.lkp.mac_dst_addr;
    mac_addr_t mac_src_addr = ig_md.lkp.mac_src_addr;
    bit<16> mac_type = ig_md.lkp.mac_type;
    switch_port_t port = ig_md.port;
    apply {
        hash[31:0] = non_ip_hash.get({ port, mac_type, mac_src_addr, mac_dst_addr });
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
        hash[31:0] = lag_hash.get({ ip_src_addr, ip_dst_addr, ip_proto, l4_dst_port, l4_src_port });
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
        hash[31:0] = lag_hash.get({ ipv6_flow_label, ip_src_addr, ip_dst_addr, ip_proto, l4_dst_port, l4_src_port });
    }
}

control V4ConsistentHash(in bit<32> sip, in bit<32> dip, in bit<16> low_l4_port, in bit<16> high_l4_port, in bit<8> protocol, inout switch_hash_t hash) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv4_inner_hash;
    bit<32> high_ip;
    bit<32> low_ip;
    action step_v4() {
        high_ip = max(sip, dip);
        low_ip = min(sip, dip);
    }
    action v4_calc_hash() {
        hash[31:0] = ipv4_inner_hash.get({ low_ip, high_ip, protocol, low_l4_port, high_l4_port });
    }
    apply {
        step_v4();
        v4_calc_hash();
    }
}

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
        ip_seq = SWITCH_CONS_HASH_IP_SEQ_SIPDIP;
        step_63_32_v6();
        step_31_0_v6();
        if (sip[63:32] != dip[63:32]) {
            if (high_63_32_ip == src_63_32_ip) {
                ip_seq = SWITCH_CONS_HASH_IP_SEQ_DIPSIP;
            }
        } else if (sip[31:0] != dip[31:0]) {
            if (high_31_0_ip == src_31_0_ip) {
                ip_seq = SWITCH_CONS_HASH_IP_SEQ_DIPSIP;
            }
        } else {
            ip_seq = SWITCH_CONS_HASH_IP_SEQ_NONE;
        }
    }
}

control V6ConsistentHash(in bit<128> sip, in bit<128> dip, in switch_cons_hash_ip_seq_t ip_seq, in bit<16> low_l4_port, in bit<16> high_l4_port, in bit<8> protocol, inout switch_hash_t hash) {
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
    action v6_calc_hash_sip_dip() {
        hash[31:0] = ipv6_inner_hash_1.get({ sip, dip, protocol, low_l4_port, high_l4_port });
    }
    action v6_calc_hash_dip_sip() {
        hash[31:0] = ipv6_inner_hash_2.get({ dip, sip, protocol, low_l4_port, high_l4_port });
    }
    apply {
        if (ip_seq == SWITCH_CONS_HASH_IP_SEQ_SIPDIP) {
            v6_calc_hash_sip_dip();
        } else if (ip_seq == SWITCH_CONS_HASH_IP_SEQ_DIPSIP) {
            v6_calc_hash_dip_sip();
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

control StartConsistentInnerHash(in switch_header_t hd, inout switch_ingress_metadata_t ig_m) {
    V6ConsistentHash64bIpSeq() compute_v6_cons_hash_64bit_ipseq;
    apply {
        if (hd.inner_ipv6.isValid() && ig_m.tunnel.type != SWITCH_INGRESS_TUNNEL_TYPE_NVGRE_ST) {
            compute_v6_cons_hash_64bit_ipseq.apply(hd.inner_ipv6.src_addr[127:64], hd.inner_ipv6.dst_addr[127:64], ig_m.cons_hash_v6_ip_seq);
        }
    }
}

control ConsistentInnerHash(in switch_header_t hd, inout switch_ingress_metadata_t ig_m) {
    bit<32> high_31_0_ip;
    bit<32> low_31_0_ip;
    Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_inner_hash;
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) l4_tcp_src_p_hash;
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) l4_udp_src_p_hash;
    bit<16> l4_src_port;
    bit<16> low_l4_port = 0;
    bit<16> high_l4_port = 0;
    action step_tcp_src_port() {
        l4_src_port = l4_tcp_src_p_hash.get({ 16w0 ++ +hd.inner_tcp.src_port });
    }
    action step_udp_src_port() {
        l4_src_port = l4_udp_src_p_hash.get({ 16w0 ++ +hd.inner_udp.src_port });
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
        ig_m.hash[31:0] = ipv6_inner_hash.get({ low_31_0_ip, high_31_0_ip, hd.inner_ipv6.next_hdr, low_l4_port, high_l4_port });
    }
    V6ConsistentHash() compute_v6_cons_hash;
    V4ConsistentHash() compute_v4_cons_hash;
    apply {
        if (hd.inner_udp.isValid()) {
            step_udp_src_port();
            step_udp_l4_port();
        } else if (hd.inner_tcp.isValid()) {
            step_tcp_src_port();
            step_tcp_l4_port();
        }
        if (hd.inner_ipv6.isValid()) {
            if (ig_m.tunnel.type != SWITCH_INGRESS_TUNNEL_TYPE_NVGRE_ST) {
                compute_v6_cons_hash.apply(hd.inner_ipv6.src_addr, hd.inner_ipv6.dst_addr, ig_m.cons_hash_v6_ip_seq, low_l4_port, high_l4_port, hd.inner_ipv6.next_hdr, ig_m.hash);
            } else {
                step_31_0_v6();
                v6_calc_31_0_hash();
            }
        } else if (hd.inner_ipv4.isValid()) {
            compute_v4_cons_hash.apply(hd.inner_ipv4.src_addr, hd.inner_ipv4.dst_addr, low_l4_port, high_l4_port, hd.inner_ipv4.protocol, ig_m.hash);
        }
    }
}

control PreIngressAcl(inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size=512) {
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
    action no_action() {
        stats.count();
    }
    action deny() {
        ig_md.flags.acl_deny = true;
        stats.count();
    }
    action set_vrf(switch_vrf_t vrf) {
        ig_md.vrf = vrf;
        stats.count();
    }
    table acl {
        key = {
            ig_md.lkp.mac_src_addr: ternary;
            ig_md.lkp.mac_dst_addr: ternary;
            ig_md.lkp.mac_type    : ternary;
            ig_md.lkp.ip_src_addr : ternary;
            ig_md.lkp.ip_dst_addr : ternary;
            ig_md.lkp.ip_tos      : ternary;
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
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0) && is_acl_enabled == true) {
            acl.apply();
        }
    }
}

control IngressIpAcl(inout switch_ingress_metadata_t ig_md, out switch_nexthop_t acl_nexthop)(switch_uint32_t table_size=512) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;
    action no_action() {
        stats.count();
    }
    action set_tc(switch_tc_t tc) {
        ig_md.qos.tc = tc;
        stats.count();
    }
    action set_color(switch_pkt_color_t color) {
        ig_md.qos.color = color;
        stats.count();
    }
    action set_meter(switch_meter_index_t index) {
        ig_md.qos.acl_meter_index = index;
        stats.count();
    }
    action set_user_defined_trap(switch_hostif_trap_t trap_id) {
        ig_md.lkp.hostif_trap_id = trap_id;
        stats.count();
    }
    action deny() {
        ig_md.flags.acl_deny = true;
        stats.count();
    }
    action permit(switch_user_metadata_t user_metadata) {
        ig_md.flags.acl_deny = false;
        ig_md.user_metadata = user_metadata;
        stats.count();
    }
    action redirect_nexthop(switch_user_metadata_t user_metadata, switch_nexthop_t nexthop_index) {
        acl_nexthop = nexthop_index;
        ig_md.user_metadata = user_metadata;
        stats.count();
    }
    action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) {
        ig_md.flags.acl_deny = false;
        ig_md.egress_port_lag_index = egress_port_lag_index;
        ig_md.acl_port_redirect = true;
        ig_md.user_metadata = user_metadata;
        stats.count();
    }
    action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) {
        ig_md.mirror.type = 1;
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        ig_md.mirror.session_id = session_id;
        ig_md.mirror.meter_index = meter_index;
        stats.count();
    }
    action set_dtel_report_type(switch_dtel_report_type_t type) {
        ig_md.dtel.report_type = ig_md.dtel.report_type | type;
        stats.count();
    }
    table acl {
        key = {
            ig_md.lkp.ip_src_addr  : ternary;
            ig_md.lkp.ip_dst_addr  : ternary;
            ig_md.lkp.ip_proto     : ternary;
            ig_md.lkp.ip_tos       : ternary;
            ig_md.lkp.l4_src_port  : ternary;
            ig_md.lkp.l4_dst_port  : ternary;
            ig_md.lkp.ip_ttl       : ternary;
            ig_md.lkp.ip_frag      : ternary;
            ig_md.lkp.tcp_flags    : ternary;
            ig_md.bd_label         : ternary;
            ig_md.l4_src_port_label: ternary;
            ig_md.l4_dst_port_label: ternary;
            ig_md.lkp.mac_type     : ternary;
            ig_md.port_lag_label   : ternary;
        }
        actions = {
            deny;
            permit;
            redirect_nexthop;
            redirect_port;
            mirror;
            set_user_defined_trap;
            no_action;
        }
        const default_action = no_action;
        counters = stats;
        size = table_size;
    }
    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }
    }
}

control IngressIpv4Acl(inout switch_ingress_metadata_t ig_md, out switch_nexthop_t acl_nexthop)(switch_uint32_t table_size=512) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;
    action no_action() {
        stats.count();
    }
    action set_tc(switch_tc_t tc) {
        ig_md.qos.tc = tc;
        stats.count();
    }
    action set_color(switch_pkt_color_t color) {
        ig_md.qos.color = color;
        stats.count();
    }
    action set_meter(switch_meter_index_t index) {
        ig_md.qos.acl_meter_index = index;
        stats.count();
    }
    action set_user_defined_trap(switch_hostif_trap_t trap_id) {
        ig_md.lkp.hostif_trap_id = trap_id;
        stats.count();
    }
    action deny() {
        ig_md.flags.acl_deny = true;
        stats.count();
    }
    action permit(switch_user_metadata_t user_metadata) {
        ig_md.flags.acl_deny = false;
        ig_md.user_metadata = user_metadata;
        stats.count();
    }
    action redirect_nexthop(switch_user_metadata_t user_metadata, switch_nexthop_t nexthop_index) {
        acl_nexthop = nexthop_index;
        ig_md.user_metadata = user_metadata;
        stats.count();
    }
    action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) {
        ig_md.flags.acl_deny = false;
        ig_md.egress_port_lag_index = egress_port_lag_index;
        ig_md.acl_port_redirect = true;
        ig_md.user_metadata = user_metadata;
        stats.count();
    }
    action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) {
        ig_md.mirror.type = 1;
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        ig_md.mirror.session_id = session_id;
        ig_md.mirror.meter_index = meter_index;
        stats.count();
    }
    action set_dtel_report_type(switch_dtel_report_type_t type) {
        ig_md.dtel.report_type = ig_md.dtel.report_type | type;
        stats.count();
    }
    table acl {
        key = {
            ig_md.lkp.ip_src_addr[95:64]: ternary;
            ig_md.lkp.ip_dst_addr[95:64]: ternary;
            ig_md.lkp.ip_proto          : ternary;
            ig_md.lkp.ip_tos            : ternary;
            ig_md.lkp.l4_src_port       : ternary;
            ig_md.lkp.l4_dst_port       : ternary;
            ig_md.lkp.ip_ttl            : ternary;
            ig_md.lkp.ip_frag           : ternary;
            ig_md.lkp.tcp_flags         : ternary;
            ig_md.bd_label              : ternary;
            ig_md.l4_src_port_label     : ternary;
            ig_md.l4_dst_port_label     : ternary;
            ig_md.lkp.mac_type          : ternary;
            ig_md.port_lag_label        : ternary;
        }
        actions = {
            deny;
            permit;
            redirect_nexthop;
            redirect_port;
            mirror;
            set_user_defined_trap;
            no_action;
        }
        const default_action = no_action;
        counters = stats;
        size = table_size;
    }
    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }
    }
}

control IngressIpv6Acl(inout switch_ingress_metadata_t ig_md, out switch_nexthop_t acl_nexthop)(switch_uint32_t table_size=512) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;
    action no_action() {
        stats.count();
    }
    action set_tc(switch_tc_t tc) {
        ig_md.qos.tc = tc;
        stats.count();
    }
    action set_color(switch_pkt_color_t color) {
        ig_md.qos.color = color;
        stats.count();
    }
    action set_meter(switch_meter_index_t index) {
        ig_md.qos.acl_meter_index = index;
        stats.count();
    }
    action set_user_defined_trap(switch_hostif_trap_t trap_id) {
        ig_md.lkp.hostif_trap_id = trap_id;
        stats.count();
    }
    action deny() {
        ig_md.flags.acl_deny = true;
        stats.count();
    }
    action permit(switch_user_metadata_t user_metadata) {
        ig_md.flags.acl_deny = false;
        ig_md.user_metadata = user_metadata;
        stats.count();
    }
    action redirect_nexthop(switch_user_metadata_t user_metadata, switch_nexthop_t nexthop_index) {
        acl_nexthop = nexthop_index;
        ig_md.user_metadata = user_metadata;
        stats.count();
    }
    action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) {
        ig_md.flags.acl_deny = false;
        ig_md.egress_port_lag_index = egress_port_lag_index;
        ig_md.acl_port_redirect = true;
        ig_md.user_metadata = user_metadata;
        stats.count();
    }
    action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) {
        ig_md.mirror.type = 1;
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        ig_md.mirror.session_id = session_id;
        ig_md.mirror.meter_index = meter_index;
        stats.count();
    }
    action set_dtel_report_type(switch_dtel_report_type_t type) {
        ig_md.dtel.report_type = ig_md.dtel.report_type | type;
        stats.count();
    }
    table acl {
        key = {
            ig_md.lkp.ip_src_addr  : ternary;
            ig_md.lkp.ip_dst_addr  : ternary;
            ig_md.lkp.ip_proto     : ternary;
            ig_md.lkp.ip_tos       : ternary;
            ig_md.lkp.l4_src_port  : ternary;
            ig_md.lkp.l4_dst_port  : ternary;
            ig_md.lkp.ip_ttl       : ternary;
            ig_md.lkp.ip_frag      : ternary;
            ig_md.lkp.tcp_flags    : ternary;
            ig_md.bd_label         : ternary;
            ig_md.l4_src_port_label: ternary;
            ig_md.l4_dst_port_label: ternary;
            ig_md.lkp.mac_type     : ternary;
            ig_md.port_lag_label   : ternary;
        }
        actions = {
            deny;
            permit;
            redirect_nexthop;
            redirect_port;
            mirror;
            set_user_defined_trap;
            no_action;
        }
        const default_action = no_action;
        counters = stats;
        size = table_size;
    }
    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }
    }
}

control IngressMacAcl(inout switch_ingress_metadata_t ig_md, out switch_nexthop_t acl_nexthop)(switch_uint32_t table_size=512) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;
    action no_action() {
        stats.count();
    }
    action set_tc(switch_tc_t tc) {
        ig_md.qos.tc = tc;
        stats.count();
    }
    action set_color(switch_pkt_color_t color) {
        ig_md.qos.color = color;
        stats.count();
    }
    action set_meter(switch_meter_index_t index) {
        ig_md.qos.acl_meter_index = index;
        stats.count();
    }
    action set_user_defined_trap(switch_hostif_trap_t trap_id) {
        ig_md.lkp.hostif_trap_id = trap_id;
        stats.count();
    }
    action deny() {
        ig_md.flags.acl_deny = true;
        stats.count();
    }
    action permit(switch_user_metadata_t user_metadata) {
        ig_md.flags.acl_deny = false;
        ig_md.user_metadata = user_metadata;
        stats.count();
    }
    action redirect_nexthop(switch_user_metadata_t user_metadata, switch_nexthop_t nexthop_index) {
        acl_nexthop = nexthop_index;
        ig_md.user_metadata = user_metadata;
        stats.count();
    }
    action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) {
        ig_md.flags.acl_deny = false;
        ig_md.egress_port_lag_index = egress_port_lag_index;
        ig_md.acl_port_redirect = true;
        ig_md.user_metadata = user_metadata;
        stats.count();
    }
    action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) {
        ig_md.mirror.type = 1;
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        ig_md.mirror.session_id = session_id;
        ig_md.mirror.meter_index = meter_index;
        stats.count();
    }
    action set_dtel_report_type(switch_dtel_report_type_t type) {
        ig_md.dtel.report_type = ig_md.dtel.report_type | type;
        stats.count();
    }
    table acl {
        key = {
            ig_md.lkp.mac_src_addr: ternary;
            ig_md.lkp.mac_dst_addr: ternary;
            ig_md.lkp.mac_type    : ternary;
            ig_md.port_lag_label  : ternary;
            ig_md.bd_label        : ternary;
        }
        actions = {
            deny;
            permit;
            redirect_nexthop;
            redirect_port;
            mirror;
            no_action;
        }
        const default_action = no_action;
        counters = stats;
        size = table_size;
    }
    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }
    }
}

struct switch_acl_sample_info_t {
    bit<32> current;
    bit<32> rate;
}

control IngressIpDtelSampleAcl(inout switch_ingress_metadata_t ig_md, out switch_nexthop_t acl_nexthop)(switch_uint32_t table_size=512) {
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
    action no_action() {
        stats.count();
    }
    action set_tc(switch_tc_t tc) {
        ig_md.qos.tc = tc;
        stats.count();
    }
    action set_color(switch_pkt_color_t color) {
        ig_md.qos.color = color;
        stats.count();
    }
    action set_meter(switch_meter_index_t index) {
        ig_md.qos.acl_meter_index = index;
        stats.count();
    }
    action set_user_defined_trap(switch_hostif_trap_t trap_id) {
        ig_md.lkp.hostif_trap_id = trap_id;
        stats.count();
    }
    action deny() {
        ig_md.flags.acl_deny = true;
        stats.count();
    }
    action permit(switch_user_metadata_t user_metadata) {
        ig_md.flags.acl_deny = false;
        ig_md.user_metadata = user_metadata;
        stats.count();
    }
    action redirect_nexthop(switch_user_metadata_t user_metadata, switch_nexthop_t nexthop_index) {
        acl_nexthop = nexthop_index;
        ig_md.user_metadata = user_metadata;
        stats.count();
    }
    action redirect_port(switch_user_metadata_t user_metadata, switch_port_lag_index_t egress_port_lag_index) {
        ig_md.flags.acl_deny = false;
        ig_md.egress_port_lag_index = egress_port_lag_index;
        ig_md.acl_port_redirect = true;
        ig_md.user_metadata = user_metadata;
        stats.count();
    }
    action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) {
        ig_md.mirror.type = 1;
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        ig_md.mirror.session_id = session_id;
        ig_md.mirror.meter_index = meter_index;
        stats.count();
    }
    action set_dtel_report_type(switch_dtel_report_type_t type) {
        ig_md.dtel.report_type = ig_md.dtel.report_type | type;
        stats.count();
    }
    action ifa_clone_sample(switch_ifa_sample_id_t ifa_sample_session) {
        ig_md.dtel.ifa_gen_clone = sample_packet.execute(ifa_sample_session);
        stats.count();
    }
    action ifa_clone_sample_and_set_dtel_report_type(switch_ifa_sample_id_t ifa_sample_session, switch_dtel_report_type_t type) {
        ig_md.dtel.report_type = type;
        ig_md.dtel.ifa_gen_clone = sample_packet.execute(ifa_sample_session);
        stats.count();
    }
    table acl {
        key = {
            ig_md.lkp.ip_src_addr  : ternary;
            ig_md.lkp.ip_dst_addr  : ternary;
            ig_md.lkp.ip_proto     : ternary;
            ig_md.lkp.ip_tos       : ternary;
            ig_md.lkp.l4_src_port  : ternary;
            ig_md.lkp.l4_dst_port  : ternary;
            ig_md.lkp.ip_ttl       : ternary;
            ig_md.lkp.ip_frag      : ternary;
            ig_md.lkp.tcp_flags    : ternary;
            ig_md.bd_label         : ternary;
            ig_md.l4_src_port_label: ternary;
            ig_md.l4_dst_port_label: ternary;
            ig_md.lkp.mac_type     : ternary;
            ig_md.port_lag_label   : ternary;
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
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            acl.apply();
        }
    }
}

control LOU(inout switch_ingress_metadata_t ig_md) {
    const switch_uint32_t table_size = 8;
    action set_src_port_label(bit<8> label) {
        ig_md.l4_src_port_label = label;
    }
    action set_dst_port_label(bit<8> label) {
        ig_md.l4_dst_port_label = label;
    }
    @stage(1) @entries_with_ranges(table_size) table l4_dst_port {
        key = {
            ig_md.lkp.l4_dst_port: range;
        }
        actions = {
            NoAction;
            set_dst_port_label;
        }
        const default_action = NoAction;
        size = table_size;
    }
    @stage(1) @entries_with_ranges(table_size) table l4_src_port {
        key = {
            ig_md.lkp.l4_src_port: range;
        }
        actions = {
            NoAction;
            set_src_port_label;
        }
        const default_action = NoAction;
        size = table_size;
    }
    action set_tcp_flags(bit<8> flags) {
        ig_md.lkp.tcp_flags = flags;
    }
    table tcp {
        key = {
            ig_md.lkp.tcp_flags: exact;
        }
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

control IngressSystemAcl(in switch_header_t hdr, inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(switch_uint32_t table_size=512) {
    const switch_uint32_t drop_stats_table_size = 8192;
    DirectCounter<bit<64>>(CounterType_t.PACKETS) stats;
    Meter<bit<8>>(1 << 8, MeterType_t.PACKETS) copp_meter;
    DirectCounter<bit<64>>(CounterType_t.PACKETS) copp_stats;
    switch_copp_meter_id_t copp_meter_id;
    action drop(switch_drop_reason_t drop_reason, bool disable_learning) {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        ig_intr_md_for_dprsr.digest_type = (disable_learning ? SWITCH_DIGEST_TYPE_INVALID : ig_intr_md_for_dprsr.digest_type);
        ig_md.drop_reason = drop_reason;
    }
    action copy_to_cpu(switch_cpu_reason_t reason_code, switch_qid_t qid, switch_copp_meter_id_t meter_id, bool disable_learning) {
        ig_md.qos.qid = qid;
        ig_intr_md_for_tm.copy_to_cpu = 1w1;
        ig_intr_md_for_dprsr.digest_type = (disable_learning ? SWITCH_DIGEST_TYPE_INVALID : ig_intr_md_for_dprsr.digest_type);
        ig_intr_md_for_tm.packet_color = (bit<2>)copp_meter.execute(meter_id);
        copp_meter_id = meter_id;
        ig_md.cpu_reason = reason_code;
    }
    action redirect_to_cpu(switch_cpu_reason_t reason_code, switch_qid_t qid, switch_copp_meter_id_t meter_id, bool disable_learning) {
        ig_intr_md_for_dprsr.drop_ctl = 0b1;
        copy_to_cpu(reason_code, qid, meter_id, disable_learning);
    }
    table system_acl {
        key = {
            ig_md.port_lag_label      : ternary;
            ig_md.bd_label            : ternary;
            ig_md.port_lag_index      : ternary;
            ig_md.lkp.pkt_type        : ternary;
            ig_md.lkp.mac_type        : ternary;
            ig_md.lkp.mac_dst_addr    : ternary;
            ig_md.lkp.ip_type         : ternary;
            ig_md.lkp.ip_ttl          : ternary;
            ig_md.lkp.ip_proto        : ternary;
            ig_md.lkp.ip_frag         : ternary;
            ig_md.lkp.ip_dst_addr     : ternary;
            ig_md.lkp.l4_src_port     : ternary;
            ig_md.lkp.l4_dst_port     : ternary;
            ig_md.lkp.arp_opcode      : ternary;
            ig_md.flags.port_vlan_miss: ternary;
            ig_md.flags.acl_deny      : ternary;
            ig_md.flags.racl_deny     : ternary;
            ig_md.flags.rmac_hit      : ternary;
            ig_md.flags.dmac_miss     : ternary;
            ig_md.flags.myip          : ternary;
            ig_md.flags.glean         : ternary;
            ig_md.flags.routed        : ternary;
            ig_md.flags.acl_meter_drop: ternary;
            ig_md.flags.link_local    : ternary;
            ig_md.checks.same_if      : ternary;
            ig_md.flags.pfc_wd_drop   : ternary;
            ig_md.ipv4.unicast_enable : ternary;
            ig_md.ipv6.unicast_enable : ternary;
            ig_md.l2_drop_reason      : ternary;
            ig_md.drop_reason         : ternary;
            ig_md.lkp.hostif_trap_id  : ternary;
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
            ig_intr_md_for_tm.packet_color: ternary;
            copp_meter_id                 : ternary;
        }
        actions = {
            copp_permit;
            copp_drop;
        }
        const default_action = copp_permit;
        size = 1 << 8 + 1;
        counters = copp_stats;
    }
    action count() {
        stats.count();
    }
    table drop_stats {
        key = {
            ig_md.drop_reason: exact @name("drop_reason") ;
            ig_md.port       : exact @name("port") ;
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
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SYSTEM_ACL != 0)) {
            switch (system_acl.apply().action_run) {
                copy_to_cpu: {
                    copp.apply();
                }
                redirect_to_cpu: {
                    copp.apply();
                }
                default: {
                }
            }
        }
        drop_stats.apply();
    }
}

control EgressMacAcl(in switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t table_size=512) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;
    action no_action() {
        stats.count();
    }
    action deny() {
        eg_md.flags.acl_deny = true;
        stats.count();
    }
    action permit() {
        eg_md.flags.acl_deny = false;
        stats.count();
    }
    action set_meter(switch_meter_index_t index) {
        eg_md.qos.acl_meter_index = index;
        stats.count();
    }
    action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) {
        eg_md.mirror.type = 1;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.mirror.session_id = session_id;
        eg_md.mirror.meter_index = meter_index;
        stats.count();
    }
    table acl {
        key = {
            hdr.ethernet.src_addr  : ternary;
            hdr.ethernet.dst_addr  : ternary;
            hdr.ethernet.ether_type: ternary;
            eg_md.port_lag_label   : ternary;
        }
        actions = {
            deny();
            permit();
            set_meter();
            mirror();
            no_action;
        }
        const default_action = no_action;
        counters = stats;
        size = table_size;
    }
    apply {
        if (!eg_md.flags.bypass_egress) {
            acl.apply();
        }
    }
}

control EgressIpv4Acl(in switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t table_size=512) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;
    action no_action() {
        stats.count();
    }
    action deny() {
        eg_md.flags.acl_deny = true;
        stats.count();
    }
    action permit() {
        eg_md.flags.acl_deny = false;
        stats.count();
    }
    action set_meter(switch_meter_index_t index) {
        eg_md.qos.acl_meter_index = index;
        stats.count();
    }
    action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) {
        eg_md.mirror.type = 1;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.mirror.session_id = session_id;
        eg_md.mirror.meter_index = meter_index;
        stats.count();
    }
    table acl {
        key = {
            hdr.ipv4.src_addr      : ternary;
            hdr.ipv4.dst_addr      : ternary;
            hdr.ipv4.protocol      : ternary;
            eg_md.lkp.tcp_flags    : ternary;
            eg_md.lkp.l4_src_port  : ternary;
            eg_md.lkp.l4_dst_port  : ternary;
            eg_md.l4_src_port_label: ternary;
            eg_md.l4_dst_port_label: ternary;
            eg_md.port_lag_label   : ternary;
            hdr.ethernet.ether_type: ternary;
        }
        actions = {
            deny();
            permit();
            set_meter();
            mirror();
            no_action;
        }
        const default_action = no_action;
        counters = stats;
        size = table_size;
    }
    apply {
        if (!eg_md.flags.bypass_egress) {
            acl.apply();
        }
    }
}

control EgressIpv6Acl(in switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t table_size=512) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;
    action no_action() {
        stats.count();
    }
    action deny() {
        eg_md.flags.acl_deny = true;
        stats.count();
    }
    action permit() {
        eg_md.flags.acl_deny = false;
        stats.count();
    }
    action set_meter(switch_meter_index_t index) {
        eg_md.qos.acl_meter_index = index;
        stats.count();
    }
    action mirror(switch_mirror_meter_id_t meter_index, switch_mirror_session_t session_id) {
        eg_md.mirror.type = 1;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.mirror.session_id = session_id;
        eg_md.mirror.meter_index = meter_index;
        stats.count();
    }
    table acl {
        key = {
            hdr.ipv6.src_addr      : ternary;
            hdr.ipv6.dst_addr      : ternary;
            hdr.ipv6.next_hdr      : ternary;
            eg_md.lkp.tcp_flags    : ternary;
            eg_md.lkp.l4_src_port  : ternary;
            eg_md.lkp.l4_dst_port  : ternary;
            eg_md.l4_src_port_label: ternary;
            eg_md.l4_dst_port_label: ternary;
            eg_md.port_lag_label   : ternary;
            hdr.ethernet.ether_type: ternary;
        }
        actions = {
            deny();
            permit();
            set_meter();
            mirror();
            no_action;
        }
        const default_action = no_action;
        counters = stats;
        size = table_size;
    }
    apply {
        if (!eg_md.flags.bypass_egress) {
            acl.apply();
        }
    }
}

control EgressSystemAcl(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, out egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)(switch_uint32_t table_size=512) {
    const switch_uint32_t drop_stats_table_size = 8192;
    DirectCounter<bit<64>>(CounterType_t.PACKETS) stats;
    Meter<bit<8>>(1 << 8, MeterType_t.PACKETS) copp_meter;
    DirectCounter<bit<64>>(CounterType_t.PACKETS) copp_stats;
    switch_copp_meter_id_t copp_meter_id;
    switch_pkt_color_t copp_color;
    action drop(switch_drop_reason_t reason_code) {
        eg_md.drop_reason = reason_code;
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        eg_md.mirror.type = 0;
    }
    action copy_to_cpu(switch_cpu_reason_t reason_code, switch_copp_meter_id_t meter_id) {
        eg_md.cpu_reason = reason_code;
        eg_intr_md_for_dprsr.mirror_type = 2;
        eg_md.mirror.type = 2;
        eg_md.mirror.session_id = SWITCH_MIRROR_SESSION_CPU;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        copp_color = (bit<2>)copp_meter.execute(meter_id);
        copp_meter_id = meter_id;
    }
    action redirect_to_cpu(switch_cpu_reason_t reason_code, switch_copp_meter_id_t meter_id) {
        copy_to_cpu(reason_code, meter_id);
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }
    action insert_timestamp() {
    }
    table system_acl {
        key = {
            eg_intr_md.egress_port : ternary;
            eg_md.flags.acl_deny   : ternary;
            eg_md.checks.mtu       : ternary;
            eg_md.flags.wred_drop  : ternary;
            eg_md.flags.pfc_wd_drop: ternary;
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
    action count() {
        stats.count();
    }
    table drop_stats {
        key = {
            eg_md.drop_reason     : exact @name("drop_reason") ;
            eg_intr_md.egress_port: exact @name("port") ;
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
        eg_intr_md_for_dprsr.mirror_type = 0;
        copp_stats.count();
    }
    action copp_permit() {
        copp_stats.count();
    }
    @ways(2) table copp {
        key = {
            copp_color   : exact;
            copp_meter_id: exact;
        }
        actions = {
            copp_permit;
            copp_drop;
        }
        const default_action = copp_permit;
        size = 1 << 8 + 1;
        counters = copp_stats;
    }
    apply {
        if (!eg_md.flags.bypass_egress) {
            switch (system_acl.apply().action_run) {
                copy_to_cpu: {
                    copp.apply();
                }
                redirect_to_cpu: {
                    copp.apply();
                }
                default: {
                }
            }
        }
        drop_stats.apply();
    }
}

control IngressSTP(in switch_ingress_metadata_t ig_md, inout switch_stp_metadata_t stp_md)(bool multiple_stp_enable=false, switch_uint32_t table_size=4096) {
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
            ig_md.port  : exact;
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
    }
}

control EgressSTP(in switch_egress_metadata_t eg_md, in switch_port_t port, out bool stp_state) {
    Register<bit<1>, bit<32>>(1 << 19, 0) stp;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;
    RegisterAction<bit<1>, bit<32>, bit<1>>(stp) stp_check = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };
    apply {
    }
}

control SMAC(in mac_addr_t src_addr, inout switch_ingress_metadata_t ig_md, inout switch_digest_type_t digest_type)(switch_uint32_t table_size) {
    bool src_miss;
    switch_port_lag_index_t src_move;
    action smac_miss() {
        src_miss = true;
    }
    action smac_hit(switch_port_lag_index_t port_lag_index) {
        src_move = ig_md.port_lag_index ^ port_lag_index;
    }
    table smac {
        key = {
            ig_md.bd: exact;
            src_addr: exact;
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
            src_miss: exact;
            src_move: ternary;
        }
        actions = {
            NoAction;
            notify;
        }
        const default_action = NoAction;
        size = MIN_TABLE_SIZE;
    }
    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SMAC != 0)) {
            smac.apply();
        }
        if (ig_md.learning.bd_mode == SWITCH_LEARNING_MODE_LEARN && ig_md.learning.port_mode == SWITCH_LEARNING_MODE_LEARN) {
            learning.apply();
        }
    }
}

control DMAC_t(in mac_addr_t dst_addr, inout switch_ingress_metadata_t ig_md);
control DMAC(in mac_addr_t dst_addr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size) {
    action dmac_miss() {
        ig_md.egress_port_lag_index = SWITCH_FLOOD;
        ig_md.flags.dmac_miss = true;
    }
    action dmac_hit(switch_port_lag_index_t port_lag_index) {
        ig_md.egress_port_lag_index = port_lag_index;
        ig_md.checks.same_if = ig_md.port_lag_index ^ port_lag_index;
    }
    action dmac_multicast(switch_mgid_t index) {
        ig_md.multicast.id = index;
    }
    action dmac_redirect(switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
    }
    @pack(2) table dmac {
        key = {
            ig_md.bd: exact;
            dst_addr: exact;
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
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_L2 != 0) && ig_md.acl_port_redirect == false) {
            dmac.apply();
        }
    }
}

control IngressBd(in switch_bd_t bd, in switch_pkt_type_t pkt_type)(switch_uint32_t table_size) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;
    action count() {
        stats.count();
    }
    table bd_stats {
        key = {
            bd      : exact;
            pkt_type: exact;
        }
        actions = {
            count;
            @defaultonly NoAction;
        }
        const default_action = NoAction;
        size = 3 * table_size;
        counters = stats;
    }
    apply {
        bd_stats.apply();
    }
}

control EgressBDStats(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;
    action count() {
        stats.count();
    }
    table bd_stats {
        key = {
            eg_md.bd[12:0]: exact;
            eg_md.pkt_type: exact;
        }
        actions = {
            count;
            @defaultonly NoAction;
        }
        size = 3 * BD_TABLE_SIZE;
        counters = stats;
    }
    apply {
        if (eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED) {
            bd_stats.apply();
        }
    }
}

control EgressBD(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md) {
    action set_bd_properties(mac_addr_t smac, switch_mtu_t mtu) {
        hdr.ethernet.src_addr = smac;
        eg_md.checks.mtu = mtu;
    }
    table bd_mapping {
        key = {
            eg_md.bd[12:0]: exact;
        }
        actions = {
            set_bd_properties;
        }
        const default_action = set_bd_properties(0, 0x3fff);
        size = 6144;
    }
    apply {
        if (!eg_md.flags.bypass_egress && eg_md.flags.routed) {
            bd_mapping.apply();
        }
    }
}

control VlanDecap(inout switch_header_t hdr, in switch_egress_metadata_t eg_md) {
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
            hdr.vlan_tag[0].isValid(): ternary;
        }
        actions = {
            NoAction;
            remove_vlan_tag;
            remove_double_tag;
        }
        const default_action = NoAction;
    }
    apply {
        if (!eg_md.flags.bypass_egress) {
            if (hdr.vlan_tag[0].isValid()) {
                hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
                hdr.vlan_tag[0].setInvalid();
            }
        }
    }
}

control VlanXlate(inout switch_header_t hdr, in switch_egress_metadata_t eg_md)(switch_uint32_t bd_table_size, switch_uint32_t port_bd_table_size) {
    action set_vlan_untagged() {
    }
    action set_double_tagged(vlan_id_t vid0, vlan_id_t vid1) {
    }
    action set_vlan_tagged(vlan_id_t vid) {
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;
        hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].vid = vid;
        hdr.ethernet.ether_type = 0x8100;
    }
    @ways(2) table port_bd_to_vlan_mapping {
        key = {
            eg_md.port_lag_index: exact @name("port_lag_index") ;
            eg_md.bd            : exact @name("bd") ;
        }
        actions = {
            set_vlan_untagged;
            set_vlan_tagged;
            set_double_tagged;
        }
        const default_action = set_vlan_untagged;
        size = port_bd_table_size;
    }
    table bd_to_vlan_mapping {
        key = {
            eg_md.bd: exact @name("bd") ;
        }
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
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
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
        if (!eg_md.flags.bypass_egress) {
            if (!port_bd_to_vlan_mapping.apply().hit) {
                bd_to_vlan_mapping.apply();
            }
        }
    }
}

action fib_hit(inout switch_ingress_metadata_t ig_md, switch_nexthop_t nexthop_index, switch_fib_label_t fib_label) {
    ig_md.nexthop = nexthop_index;
    ig_md.flags.routed = true;
}
action fib_miss(inout switch_ingress_metadata_t ig_md) {
    ig_md.flags.routed = false;
}
action fib_myip_subnet(inout switch_ingress_metadata_t ig_md) {
    ig_md.flags.myip = SWITCH_MYIP_SUBNET;
}
action fib_myip(inout switch_ingress_metadata_t ig_md) {
    ig_md.flags.myip = SWITCH_MYIP;
}
control Fibv4(inout switch_ingress_metadata_t ig_md)(switch_uint32_t host_table_size, switch_uint32_t lpm_table_size, bool local_host_enable=false, switch_uint32_t local_host_table_size=1024) {
    @pack(2) @name(".ipv4_host") table host {
        key = {
            ig_md.vrf                   : exact;
            ig_md.lkp.ip_dst_addr[95:64]: exact;
        }
        actions = {
            fib_miss(ig_md);
            fib_hit(ig_md);
            fib_myip(ig_md);
            fib_myip_subnet(ig_md);
        }
        const default_action = fib_miss(ig_md);
        size = host_table_size;
    }
    @name(".ipv4_local_host") table local_host {
        key = {
            ig_md.vrf                   : exact;
            ig_md.lkp.ip_dst_addr[95:64]: exact;
        }
        actions = {
            fib_miss(ig_md);
            fib_hit(ig_md);
            fib_myip(ig_md);
            fib_myip_subnet(ig_md);
        }
        const default_action = fib_miss(ig_md);
        size = local_host_table_size;
    }
    Alpm(number_partitions = 1024, subtrees_per_partition = 2) algo_lpm;
    @name(".ipv4_lpm") table lpm32 {
        key = {
            ig_md.vrf                   : exact;
            ig_md.lkp.ip_dst_addr[95:64]: lpm;
        }
        actions = {
            fib_miss(ig_md);
            fib_hit(ig_md);
            fib_myip(ig_md);
            fib_myip_subnet(ig_md);
        }
        const default_action = fib_miss(ig_md);
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

control Fibv6(inout switch_ingress_metadata_t ig_md)(switch_uint32_t host_table_size, switch_uint32_t lpm_table_size, switch_uint32_t lpm64_table_size=1024) {
    @name(".ipv6_host") table host {
        key = {
            ig_md.vrf            : exact;
            ig_md.lkp.ip_dst_addr: exact;
        }
        actions = {
            fib_miss(ig_md);
            fib_hit(ig_md);
            fib_myip(ig_md);
            fib_myip_subnet(ig_md);
        }
        const default_action = fib_miss(ig_md);
        size = host_table_size;
    }
    Alpm(number_partitions = 1024, subtrees_per_partition = 1) algo_lpm128;
    @name(".ipv6_lpm128") table lpm128 {
        key = {
            ig_md.vrf            : exact;
            ig_md.lkp.ip_dst_addr: lpm;
        }
        actions = {
            fib_miss(ig_md);
            fib_hit(ig_md);
            fib_myip(ig_md);
            fib_myip_subnet(ig_md);
        }
        const default_action = fib_miss(ig_md);
        size = lpm_table_size;
        implementation = algo_lpm128;
        requires_versioning = false;
    }
    Alpm(number_partitions = 1024, subtrees_per_partition = 2) algo_lpm64;
    @name(".ipv6_lpm64") table lpm64 {
        key = {
            ig_md.vrf                    : exact;
            ig_md.lkp.ip_dst_addr[127:64]: lpm;
        }
        actions = {
            fib_miss(ig_md);
            fib_hit(ig_md);
            fib_myip(ig_md);
            fib_myip_subnet(ig_md);
        }
        const default_action = fib_miss(ig_md);
        size = lpm64_table_size;
        implementation = algo_lpm64;
        requires_versioning = false;
    }
    apply {
        if (!host.apply().hit) {
            if (!lpm128.apply().hit) {
                lpm64.apply();
            }
        }
    }
}

control EgressVRF(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md) {
    action set_ipv4_vrf_properties(switch_tunnel_vni_t vni, mac_addr_t smac) {
        eg_md.tunnel.vni = vni;
        hdr.ethernet.src_addr = smac;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }
    action set_ipv6_vrf_properties(switch_tunnel_vni_t vni, mac_addr_t smac) {
        eg_md.tunnel.vni = vni;
        hdr.ethernet.src_addr = smac;
        hdr.ipv6.hop_limit = hdr.ipv6.hop_limit - 1;
    }
    @ways(3) table vrf_mapping {
        key = {
            eg_md.vrf         : exact;
            hdr.ipv4.isValid(): exact;
            hdr.ipv6.isValid(): exact;
        }
        actions = {
            NoAction;
            set_ipv4_vrf_properties;
            set_ipv6_vrf_properties;
        }
        const default_action = NoAction;
        size = VRF_TABLE_SIZE * 2;
    }
    apply {
        if (eg_md.flags.routed) {
            vrf_mapping.apply();
        }
    }
}

control MTU(in switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t table_size=1024) {
    action ipv4_mtu_check(switch_mtu_t mtu) {
        eg_md.checks.mtu = mtu |-| hdr.ipv4.total_len;
    }
    action ipv6_mtu_check(switch_mtu_t mtu) {
        eg_md.checks.mtu = mtu |-| hdr.ipv6.payload_len;
    }
    action mtu_miss() {
        eg_md.checks.mtu = 16w0xffff;
    }
    table mtu {
        key = {
            eg_md.checks.mtu  : exact;
            hdr.ipv4.isValid(): exact;
            hdr.ipv6.isValid(): exact;
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
        if (!eg_md.flags.bypass_egress) {
            mtu.apply();
        }
    }
}

control Nexthop(inout switch_ingress_metadata_t ig_md)(switch_uint32_t nexthop_table_size, switch_uint32_t ecmp_group_table_size, switch_uint32_t ecmp_selection_table_size, switch_uint32_t ecmp_max_members_per_group=64) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionProfile(ecmp_selection_table_size) ecmp_action_profile;
    ActionSelector(ecmp_action_profile, selector_hash, SelectorMode_t.FAIR, ecmp_max_members_per_group, ecmp_group_table_size) ecmp_selector;
    action set_nexthop_properties(switch_port_lag_index_t port_lag_index, switch_bd_t bd, switch_nat_zone_t zone) {
        ig_md.egress_port_lag_index = port_lag_index;
        ig_md.checks.same_if = ig_md.port_lag_index ^ port_lag_index;
    }
    action set_ecmp_properties(switch_port_lag_index_t port_lag_index, switch_bd_t bd, switch_nexthop_t nexthop_index, switch_nat_zone_t zone) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties(port_lag_index, bd, zone);
    }
    action set_nexthop_properties_post_routed_flood(switch_bd_t bd, switch_mgid_t mgid, switch_nat_zone_t zone) {
        ig_md.egress_port_lag_index = 0;
        ig_md.multicast.id = mgid;
    }
    action set_ecmp_properties_post_routed_flood(switch_bd_t bd, switch_mgid_t mgid, switch_nexthop_t nexthop_index, switch_nat_zone_t zone) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties_post_routed_flood(bd, mgid, zone);
    }
    action set_nexthop_properties_glean() {
        ig_md.flags.glean = true;
    }
    action set_ecmp_properties_glean(switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties_glean();
    }
    action set_nexthop_properties_drop() {
        ig_md.drop_reason = SWITCH_DROP_REASON_NEXTHOP;
    }
    action set_ecmp_properties_drop() {
        set_nexthop_properties_drop();
    }
    @ways(2) table ecmp {
        key = {
            ig_md.nexthop   : exact;
            ig_md.hash[15:0]: selector;
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
            ig_md.nexthop: exact;
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
        if (ig_md.acl_port_redirect == true) {
            ig_md.flags.routed = false;
            ig_md.nexthop = 0;
        } else {
            switch (nexthop.apply().action_run) {
                NoAction: {
                    ecmp.apply();
                }
                default: {
                }
            }
        }
    }
}

control Neighbor(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md) {
    action rewrite_l2(switch_bd_t bd, mac_addr_t dmac) {
        hdr.ethernet.dst_addr = dmac;
    }
    @use_hash_action(1) table neighbor {
        key = {
            eg_md.nexthop: exact;
        }
        actions = {
            rewrite_l2;
        }
        const default_action = rewrite_l2(0, 0);
        size = NEXTHOP_TABLE_SIZE;
    }
    apply {
        if (!eg_md.flags.bypass_egress && eg_md.flags.routed) {
            neighbor.apply();
        }
    }
}

control OuterNexthop(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md) {
    action rewrite_l2(switch_bd_t bd) {
        eg_md.bd = bd;
    }
    @use_hash_action(1) table outer_nexthop {
        key = {
            eg_md.nexthop: exact;
        }
        actions = {
            rewrite_l2;
        }
        const default_action = rewrite_l2(0);
        size = NEXTHOP_TABLE_SIZE;
    }
    apply {
        if (!eg_md.flags.bypass_egress && eg_md.flags.routed) {
            outer_nexthop.apply();
        }
    }
}

parser SwitchIngressParser(packet_in pkt, out switch_header_t hdr, out switch_ingress_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    Checksum() inner2_ipv4_checksum;
    value_set<bit<16>>(1) udp_port_vxlan;
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;
    value_set<switch_nvgre_value_set_t>(1) nvgre_st_key;
    state start {
        pkt.extract(ig_intr_md);
        ig_md.port = ig_intr_md.ingress_port;
        ig_md.timestamp = ig_intr_md.ingress_mac_tstamp[31:0];
        transition parse_port_metadata;
    }
    state parse_resubmit {
        transition accept;
    }
    state parse_port_metadata {
        switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);
        ig_md.port_lag_index = port_md.port_lag_index;
        ig_md.port_lag_label = port_md.port_lag_label;
        transition parse_packet;
    }
    state parse_packet {
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type, ig_md.port) {
            cpu_port: parse_cpu;
            (0x800, default): parse_ipv4;
            (0x806, default): parse_arp;
            (0x86dd, default): parse_ipv6;
            (0x8100, default): parse_vlan;
            (0x8100, default): parse_vlan;
            default: accept;
        }
    }
    state parse_cpu {
        pkt.extract(hdr.fabric);
        pkt.extract(hdr.cpu);
        ig_md.bypass = hdr.cpu.reason_code;
        transition select(hdr.cpu.ether_type) {
            0x800: parse_ipv4;
            0x806: parse_arp;
            0x86dd: parse_ipv6;
            0x8100: parse_vlan;
            0x8100: parse_vlan;
            default: accept;
        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            5: parse_ipv4_no_options;
            6: parse_ipv4_options;
            default: accept;
        }
    }
    state parse_ipv4_options {
        pkt.extract(hdr.ipv4_option);
        ipv4_checksum.add(hdr.ipv4_option);
        transition parse_ipv4_no_options;
    }
    state parse_ipv4_no_options {
        ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (1, 0): parse_icmp;
            (2, 0): parse_igmp;
            (6, 0): parse_tcp;
            (17, 0): parse_udp;
            (47, 0): parse_ip_gre;
            (4, 0): parse_ipinip;
            (41, 0): parse_ipv6inip;
            default: accept;
        }
    }
    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }
    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            0x806: parse_arp;
            0x800: parse_ipv4;
            0x8100: parse_vlan;
            0x86dd: parse_ipv6;
            default: accept;
        }
    }
    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            58: parse_icmp;
            6: parse_tcp;
            17: parse_udp;
            47: parse_ip_gre;
            4: parse_ipinip;
            41: parse_ipv6inip;
            default: accept;
        }
    }
    state parse_ip_gre {
        pkt.extract(hdr.gre);
        transition select(hdr.gre.C, hdr.gre.R, hdr.gre.K, hdr.gre.S, hdr.gre.s, hdr.gre.recurse, hdr.gre.flags, hdr.gre.version, hdr.gre.proto) {
            (default, default, default, default, default, default, default, default, 0x800): parse_inner_ipv4;
            (default, default, default, default, default, default, default, default, 0x86dd): parse_inner_ipv6;
            default: accept;
        }
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            2123: parse_gtp_u;
            4791: parse_rocev2;
            default: accept;
        }
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
    state parse_gtp_u {
        pkt.extract(hdr.gtp);
        transition accept;
    }
    state parse_rocev2 {
        transition accept;
    }
    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        ig_md.tunnel.type = SWITCH_INGRESS_TUNNEL_TYPE_VXLAN;
        ig_md.tunnel.vni = hdr.vxlan.vni;
        transition parse_inner_ethernet;
    }
    state parse_ipinip {
        transition accept;
    }
    state parse_ipv6inip {
        transition accept;
    }
    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            0x800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;
            default: accept;
        }
    }
    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        inner_ipv4_checksum.add(hdr.inner_ipv4);
        ig_md.flags.inner_ipv4_checksum_err = inner_ipv4_checksum.verify();
        transition select(hdr.inner_ipv4.protocol) {
            1: parse_inner_icmp;
            6: parse_inner_tcp;
            17: parse_inner_udp;
            default: accept;
        }
    }
    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr) {
            58: parse_inner_icmp;
            6: parse_inner_tcp;
            17: parse_inner_udp;
            default: accept;
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

parser SwitchEgressParser(packet_in pkt, out switch_header_t hdr, out switch_egress_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    value_set<bit<16>>(1) udp_port_vxlan;
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;
    value_set<switch_nvgre_value_set_t>(1) nvgre_st_key;
    Checksum() tcp_checksum;
    @critical state start {
        pkt.extract(eg_intr_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.port = eg_intr_md.egress_port;
        eg_md.qos.qdepth = eg_intr_md.deq_qdepth;
        switch_port_mirror_metadata_h mirror_md = pkt.lookahead<switch_port_mirror_metadata_h>();
        transition select(eg_intr_md.deflection_flag, mirror_md.src, mirror_md.type) {
            (1, default, default): parse_deflected_pkt;
            (default, SWITCH_PKT_SRC_BRIDGED, default): parse_bridged_pkt;
            (default, default, 1): parse_port_mirrored_metadata;
            (default, SWITCH_PKT_SRC_CLONED_EGRESS, 2): parse_cpu_mirrored_metadata;
            (default, SWITCH_PKT_SRC_CLONED_INGRESS, 3): parse_dtel_drop_metadata_from_ingress;
            (default, default, 3): parse_dtel_drop_metadata_from_egress;
            (default, default, 4): parse_dtel_switch_local_metadata;
            (default, default, 5): parse_simple_mirrored_metadata;
        }
    }
    state parse_bridged_pkt {
        pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_BRIDGED;
        eg_md.ingress_port = hdr.bridged_md.base.ingress_port;
        eg_md.port_lag_index = hdr.bridged_md.base.ingress_port_lag_index;
        eg_md.bd = hdr.bridged_md.base.ingress_bd;
        eg_md.nexthop = hdr.bridged_md.base.nexthop;
        eg_md.cpu_reason = hdr.bridged_md.base.cpu_reason;
        eg_md.flags.routed = hdr.bridged_md.base.routed;
        eg_md.flags.bypass_egress = hdr.bridged_md.base.bypass_egress;
        eg_md.pkt_type = hdr.bridged_md.base.pkt_type;
        eg_md.ingress_timestamp = hdr.bridged_md.base.timestamp;
        eg_md.qos.tc = hdr.bridged_md.base.tc;
        eg_md.qos.qid = hdr.bridged_md.base.qid;
        eg_md.qos.color = hdr.bridged_md.base.color;
        eg_md.vrf = hdr.bridged_md.base.vrf;
        eg_md.l4_src_port_label = hdr.bridged_md.acl.l4_src_port_label;
        eg_md.l4_dst_port_label = hdr.bridged_md.acl.l4_dst_port_label;
        eg_md.lkp.l4_src_port = hdr.bridged_md.acl.l4_src_port;
        eg_md.lkp.l4_dst_port = hdr.bridged_md.acl.l4_dst_port;
        eg_md.lkp.tcp_flags = hdr.bridged_md.acl.tcp_flags;
        eg_md.dtel.report_type = hdr.bridged_md.dtel.report_type;
        eg_md.dtel.hash = hdr.bridged_md.dtel.hash;
        eg_md.dtel.session_id = hdr.bridged_md.dtel.session_id;
        transition parse_ethernet;
    }
    state parse_deflected_pkt {
        pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_DEFLECTED;
        eg_md.mirror.type = 255;
        eg_md.dtel.report_type = hdr.bridged_md.dtel.report_type;
        eg_md.dtel.hash = hdr.bridged_md.dtel.hash;
        eg_md.dtel.session_id = 0;
        eg_md.mirror.session_id = hdr.bridged_md.dtel.session_id;
        eg_md.qos.qid = hdr.bridged_md.base.qid;
        eg_md.ingress_timestamp = hdr.bridged_md.base.timestamp;
        hdr.dtel_report = { 0, hdr.bridged_md.base.ingress_port, 0, hdr.bridged_md.dtel.egress_port, 0, hdr.bridged_md.base.qid };
        hdr.dtel_drop_report = { SWITCH_DROP_REASON_TRAFFIC_MANAGER, 0 };
        transition accept;
    }
    state parse_port_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.ethernet);
        eg_md.pkt_src = port_md.src;
        eg_md.mirror.session_id = port_md.session_id;
        eg_md.ingress_timestamp = port_md.timestamp;
        eg_md.flags.bypass_egress = true;
        eg_md.mirror.type = port_md.type;
        eg_md.dtel.session_id = 0;
        transition accept;
    }
    state parse_cpu_mirrored_metadata {
        switch_cpu_mirror_metadata_h cpu_md;
        pkt.extract(cpu_md);
        pkt.extract(hdr.ethernet);
        eg_md.pkt_src = cpu_md.src;
        eg_md.flags.bypass_egress = true;
        eg_md.bd = cpu_md.bd;
        eg_md.cpu_reason = cpu_md.reason_code;
        eg_md.mirror.type = cpu_md.type;
        eg_md.dtel.session_id = 0;
        transition accept;
    }
    state parse_dtel_drop_metadata_from_egress {
        switch_dtel_drop_mirror_metadata_h dtel_md;
        pkt.extract(dtel_md);
        eg_md.pkt_src = dtel_md.src;
        eg_md.mirror.type = dtel_md.type;
        eg_md.dtel.report_type = dtel_md.report_type;
        eg_md.dtel.hash = dtel_md.hash;
        eg_md.dtel.session_id = 0;
        eg_md.mirror.session_id = dtel_md.session_id;
        eg_md.ingress_timestamp = dtel_md.timestamp;
        hdr.dtel_report = { 0, dtel_md.ingress_port, 0, dtel_md.egress_port, 0, dtel_md.qid };
        hdr.dtel_drop_report = { dtel_md.drop_reason, 0 };
        transition accept;
    }
    state parse_dtel_drop_metadata_from_ingress {
        switch_dtel_drop_mirror_metadata_h dtel_md;
        pkt.extract(dtel_md);
        eg_md.pkt_src = dtel_md.src;
        eg_md.mirror.type = dtel_md.type;
        eg_md.dtel.report_type = dtel_md.report_type;
        eg_md.dtel.hash = dtel_md.hash;
        eg_md.dtel.session_id = 0;
        eg_md.mirror.session_id = dtel_md.session_id;
        eg_md.ingress_timestamp = dtel_md.timestamp;
        hdr.dtel_report = { 0, dtel_md.ingress_port, 0, SWITCH_PORT_INVALID, 0, dtel_md.qid };
        hdr.dtel_drop_report = { dtel_md.drop_reason, 0 };
        transition accept;
    }
    state parse_dtel_switch_local_metadata {
        switch_dtel_switch_local_mirror_metadata_h dtel_md;
        pkt.extract(dtel_md);
        eg_md.pkt_src = dtel_md.src;
        eg_md.mirror.type = dtel_md.type;
        eg_md.dtel.report_type = dtel_md.report_type;
        eg_md.dtel.hash = dtel_md.hash;
        eg_md.dtel.session_id = 0;
        eg_md.mirror.session_id = dtel_md.session_id;
        eg_md.ingress_timestamp = dtel_md.timestamp;
        hdr.dtel_report = { 0, dtel_md.ingress_port, 0, dtel_md.egress_port, 0, dtel_md.qid };
        hdr.dtel_switch_local_report = { 0, dtel_md.qdepth, dtel_md.egress_timestamp };
        transition accept;
    }
    state parse_simple_mirrored_metadata {
        switch_simple_mirror_metadata_h simple_mirror_md;
        pkt.extract(simple_mirror_md);
        eg_md.pkt_src = simple_mirror_md.src;
        eg_md.mirror.type = simple_mirror_md.type;
        eg_md.mirror.session_id = simple_mirror_md.session_id;
        eg_md.flags.bypass_egress = true;
        transition parse_ethernet;
    }
    state parse_packet {
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type, eg_intr_md.egress_port) {
            cpu_port: parse_cpu;
            (0x800, default): parse_ipv4;
            (0x86dd, default): parse_ipv6;
            (0x8100, default): parse_vlan;
            (0x8100, default): parse_vlan;
            default: accept;
        }
    }
    state parse_cpu {
        eg_md.flags.bypass_egress = true;
        transition accept;
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol, hdr.ipv4.ihl, hdr.ipv4.frag_offset) {
            (6, 5, 0): parse_tcp;
            (17, 5, 0): parse_udp;
            (default, 6, default): parse_ipv4_options;
            default: accept;
        }
    }
    state parse_ipv4_options {
        pkt.extract(hdr.ipv4_option);
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (6, 0): parse_tcp;
            (17, 0): parse_udp;
            default: accept;
        }
    }
    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            0x800: parse_ipv4;
            0x8100: parse_vlan;
            0x86dd: parse_ipv6;
            default: accept;
        }
    }
    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            6: parse_tcp;
            default: accept;
        }
    }
    state parse_ip_gre {
        pkt.extract(hdr.gre);
        transition select(hdr.gre.C, hdr.gre.R, hdr.gre.K, hdr.gre.S, hdr.gre.s, hdr.gre.recurse, hdr.gre.flags, hdr.gre.version, hdr.gre.proto) {
            default: accept;
        }
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            default: accept;
        }
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        tcp_checksum.subtract({ hdr.tcp.checksum });
        transition select(hdr.tcp.data_offset) {
            4w0x8 .. 4w0xf: parse_tcp_options_short;
            default: accept;
        }
    }
    state parse_tcp_options_short {
        transition select(pkt.lookahead<tcp_option_kind_t>()) {
            0x72: parse_tcp_option_int;
            0x8: parse_tcp_option_ts;
            0x1: parse_tcp_option_nop_before;
            default: accept;
        }
    }
    state parse_tcp_option_nop_before {
        pkt.extract(hdr.tcpopt_two_nops);
        transition parse_tcp_options_short;
    }
    state parse_tcp_option_ts {
        pkt.extract(hdr.tcpopt_ts);
        transition select(pkt.lookahead<tcp_option_kind_t>(), hdr.tcp.data_offset) {
            (0x72, 4w0xb .. 4w0xf): parse_tcp_option_int;
            default: accept;
        }
    }
    state parse_tcp_option_int {
        pkt.extract(hdr.tcpopt_int);
        eg_md.tcp_int_val = hdr.tcpopt_int.val;
        tcp_checksum.subtract_all_and_deposit(eg_md.tcp_checksum);
        tcp_checksum.subtract({ hdr.tcpopt_int });
        transition accept;
    }
    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;
    }
    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            0x800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;
            default: accept;
        }
    }
    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol) {
            17: parse_inner_udp;
            default: accept;
        }
    }
    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr) {
            17: parse_inner_udp;
            default: accept;
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

control IngressMirror(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    Mirror() mirror;
    apply {
        if (ig_intr_md_for_dprsr.mirror_type == 1) {
            mirror.emit<switch_port_mirror_metadata_h>(ig_md.mirror.session_id, { ig_md.mirror.src, ig_md.mirror.type, ig_md.timestamp, 0, ig_md.mirror.session_id });
        } else if (ig_intr_md_for_dprsr.mirror_type == 3) {
            mirror.emit<switch_dtel_drop_mirror_metadata_h>(ig_md.dtel.session_id, { ig_md.mirror.src, ig_md.mirror.type, ig_md.timestamp, 0, ig_md.dtel.session_id, ig_md.lag_hash, ig_md.dtel.report_type, 0, ig_md.port, 0, ig_md.egress_port, 0, ig_md.qos.qid, ig_md.drop_reason });
        }
    }
}

control EgressMirror(inout switch_header_t hdr, in switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    Mirror() mirror;
    apply {
        if (eg_intr_md_for_dprsr.mirror_type == 1) {
            mirror.emit<switch_port_mirror_metadata_h>(eg_md.mirror.session_id, { eg_md.mirror.src, eg_md.mirror.type, eg_md.ingress_timestamp, 0, eg_md.mirror.session_id });
        } else if (eg_intr_md_for_dprsr.mirror_type == 2) {
            mirror.emit<switch_cpu_mirror_metadata_h>(eg_md.mirror.session_id, { eg_md.mirror.src, eg_md.mirror.type, 0, eg_md.ingress_port, eg_md.bd, 0, eg_md.port_lag_index, eg_md.cpu_reason });
        } else if (eg_intr_md_for_dprsr.mirror_type == 4) {
            mirror.emit<switch_dtel_switch_local_mirror_metadata_h>(eg_md.dtel.session_id, { eg_md.mirror.src, eg_md.mirror.type, eg_md.ingress_timestamp, 0, eg_md.dtel.session_id, eg_md.dtel.hash, eg_md.dtel.report_type, 0, eg_md.ingress_port, 0, eg_md.port, 0, eg_md.qos.qid, 0, eg_md.qos.qdepth, eg_md.timestamp });
        } else if (eg_intr_md_for_dprsr.mirror_type == 3) {
            mirror.emit<switch_dtel_drop_mirror_metadata_h>(eg_md.dtel.session_id, { eg_md.mirror.src, eg_md.mirror.type, eg_md.ingress_timestamp, 0, eg_md.dtel.session_id, eg_md.dtel.hash, eg_md.dtel.report_type, 0, eg_md.ingress_port, 0, eg_md.port, 0, eg_md.qos.qid, eg_md.drop_reason });
        } else if (eg_intr_md_for_dprsr.mirror_type == 5) {
            mirror.emit<switch_simple_mirror_metadata_h>(eg_md.dtel.session_id, { eg_md.mirror.src, eg_md.mirror.type, 0, eg_md.dtel.session_id });
        }
    }
}

control IngressNatChecksum(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md) {
    Checksum() tcp_checksum;
    Checksum() udp_checksum;
    apply {
    }
}

control SwitchIngressDeparser(packet_out pkt, inout switch_header_t hdr, in switch_ingress_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    IngressMirror() mirror;
    Digest<switch_learning_digest_t>() digest;
    apply {
        mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);
        if (ig_intr_md_for_dprsr.digest_type == SWITCH_DIGEST_TYPE_MAC_LEARNING) {
            digest.pack({ ig_md.bd, ig_md.port_lag_index, ig_md.lkp.mac_src_addr });
        }
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
        pkt.emit(hdr.rocev2_bth);
        pkt.emit(hdr.gre);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
    }
}

control SwitchEgressDeparser(packet_out pkt, inout switch_header_t hdr, in switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    EgressMirror() mirror;
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    Checksum() tcp_checksum;
    apply {
        mirror.apply(hdr, eg_md, eg_intr_md_for_dprsr);
        hdr.ipv4.hdr_checksum = ipv4_checksum.update({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.total_len, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.frag_offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4_option.type, hdr.ipv4_option.length, hdr.ipv4_option.value });
        if (eg_md.tcp_int_update) {
            hdr.tcp.checksum = tcp_checksum.update({ hdr.tcpopt_int, eg_md.tcp_checksum });
        }
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.fabric);
        pkt.emit(hdr.cpu);
        pkt.emit(hdr.timestamp);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv4_option);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.tcpopt_two_nops);
        pkt.emit(hdr.tcpopt_ts);
        pkt.emit(hdr.tcpopt_int);
        pkt.emit(hdr.dtel);
        pkt.emit(hdr.dtel_report);
        pkt.emit(hdr.dtel_switch_local_report);
        pkt.emit(hdr.dtel_drop_report);
        pkt.emit(hdr.gre);
        pkt.emit(hdr.erspan);
        pkt.emit(hdr.erspan_type2);
        pkt.emit(hdr.erspan_type3);
        pkt.emit(hdr.erspan_platform);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
    }
}

control MirrorRewrite(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, out egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)(switch_uint32_t table_size=1024) {
    bit<16> length;
    action add_ethernet_header(in mac_addr_t src_addr, in mac_addr_t dst_addr, in bit<16> ether_type) {
        hdr.ethernet.setValid();
        hdr.ethernet.ether_type = ether_type;
        hdr.ethernet.src_addr = src_addr;
        hdr.ethernet.dst_addr = dst_addr;
    }
    action add_vlan_tag(vlan_id_t vid, bit<3> pcp, bit<16> ether_type) {
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].pcp = pcp;
        hdr.vlan_tag[0].vid = vid;
        hdr.vlan_tag[0].ether_type = ether_type;
    }
    action add_ipv4_header(in bit<8> diffserv, in bit<8> ttl, in bit<8> protocol, in ipv4_addr_t src_addr, in ipv4_addr_t dst_addr) {
        hdr.ipv4.setValid();
        hdr.ipv4.version = 4w4;
        hdr.ipv4.ihl = 4w5;
        hdr.ipv4.diffserv = diffserv;
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
        hdr.gre.C = 0;
        hdr.gre.R = 0;
        hdr.gre.K = 0;
        hdr.gre.S = 0;
        hdr.gre.s = 0;
        hdr.gre.recurse = 0;
        hdr.gre.flags = 0;
        hdr.gre.version = 0;
    }
    action add_erspan_common(bit<16> version_vlan, bit<10> session_id) {
        hdr.erspan.setValid();
        hdr.erspan.version_vlan = version_vlan;
        hdr.erspan.session_id = (bit<16>)session_id;
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
        hdr.erspan_type3.ft_d_other = 0x4;
        if (opt_sub_header) {
        }
    }
    action rewrite_(switch_qid_t qid) {
        eg_md.qos.qid = qid;
    }
    action rewrite_rspan(switch_qid_t qid, bit<3> pcp, vlan_id_t vid) {
    }
    action rewrite_erspan_type2(switch_qid_t qid, mac_addr_t smac, mac_addr_t dmac, ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
        eg_md.qos.qid = qid;
        add_erspan_type2((bit<10>)eg_md.mirror.session_id);
        add_gre_header(0x88be);
        add_ipv4_header(tos, ttl, 47, sip, dip);
        hdr.ipv4.total_len = eg_md.pkt_length + 16w32;
        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, 0x800);
    }
    action rewrite_erspan_type2_with_vlan(switch_qid_t qid, bit<16> ether_type, mac_addr_t smac, mac_addr_t dmac, bit<3> pcp, vlan_id_t vid, ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
        eg_md.qos.qid = qid;
        add_erspan_type2((bit<10>)eg_md.mirror.session_id);
        add_gre_header(0x88be);
        add_ipv4_header(tos, ttl, 47, sip, dip);
        hdr.ipv4.total_len = eg_md.pkt_length + 16w32;
        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, ether_type);
        add_vlan_tag(vid, pcp, 0x800);
    }
    action rewrite_erspan_type3(switch_qid_t qid, mac_addr_t smac, mac_addr_t dmac, ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
        eg_md.qos.qid = qid;
        add_erspan_type3((bit<10>)eg_md.mirror.session_id, (bit<32>)eg_md.ingress_timestamp, false);
        add_gre_header(0x22eb);
        add_ipv4_header(tos, ttl, 47, sip, dip);
        hdr.ipv4.total_len = eg_md.pkt_length + 16w36;
        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, 0x800);
    }
    action rewrite_erspan_type3_with_vlan(switch_qid_t qid, bit<16> ether_type, mac_addr_t smac, mac_addr_t dmac, bit<3> pcp, vlan_id_t vid, ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
        eg_md.qos.qid = qid;
        add_erspan_type3((bit<10>)eg_md.mirror.session_id, (bit<32>)eg_md.ingress_timestamp, false);
        add_gre_header(0x22eb);
        add_ipv4_header(tos, ttl, 47, sip, dip);
        hdr.ipv4.total_len = eg_md.pkt_length + 16w36;
        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, ether_type);
        add_vlan_tag(vid, pcp, 0x800);
    }
    action rewrite_erspan_type3_platform_specific(switch_qid_t qid, mac_addr_t smac, mac_addr_t dmac, ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
        eg_md.qos.qid = qid;
        add_erspan_type3((bit<10>)eg_md.mirror.session_id, (bit<32>)eg_md.ingress_timestamp, true);
        add_gre_header(0x22eb);
        add_ipv4_header(tos, ttl, 47, sip, dip);
        hdr.ipv4.total_len = eg_md.pkt_length + 16w44;
        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, 0x800);
    }
    action rewrite_erspan_type3_platform_specific_with_vlan(switch_qid_t qid, bit<16> ether_type, mac_addr_t smac, mac_addr_t dmac, bit<3> pcp, vlan_id_t vid, ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
        eg_md.qos.qid = qid;
        add_erspan_type3((bit<10>)eg_md.mirror.session_id, (bit<32>)eg_md.ingress_timestamp, true);
        add_gre_header(0x22eb);
        add_ipv4_header(tos, ttl, 47, sip, dip);
        hdr.ipv4.total_len = eg_md.pkt_length + 16w44;
        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, ether_type);
        add_vlan_tag(vid, pcp, 0x800);
    }
    action rewrite_dtel_report(mac_addr_t smac, mac_addr_t dmac, ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl, bit<16> udp_dst_port, switch_mirror_session_t session_id, bit<16> max_pkt_len) {
        hdr.udp.setValid();
        hdr.udp.dst_port = udp_dst_port;
        hdr.udp.checksum = 0;
        add_ipv4_header(tos, ttl, 17, sip, dip);
        hdr.ipv4.total_len = eg_md.pkt_length + 16w28;
        hdr.udp.length = eg_md.pkt_length + 16w8;
        hdr.ipv4.flags = 2;
        add_ethernet_header(smac, dmac, 0x800);
        eg_md.dtel.session_id = session_id;
    }
    action rewrite_dtel_report_with_entropy(mac_addr_t smac, mac_addr_t dmac, ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl, bit<16> udp_dst_port, switch_mirror_session_t session_id, bit<16> max_pkt_len) {
        rewrite_dtel_report(smac, dmac, sip, dip, tos, ttl, udp_dst_port, session_id, max_pkt_len);
        hdr.udp.src_port = eg_md.dtel.hash[15:0];
    }
    action rewrite_dtel_report_without_entropy(mac_addr_t smac, mac_addr_t dmac, ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl, bit<16> udp_dst_port, bit<16> udp_src_port, switch_mirror_session_t session_id, bit<16> max_pkt_len) {
        rewrite_dtel_report(smac, dmac, sip, dip, tos, ttl, udp_dst_port, session_id, max_pkt_len);
        hdr.udp.src_port = udp_src_port;
    }
    action rewrite_ip_udp_lengths() {
        hdr.ipv4.total_len = eg_md.pkt_length - 16w14;
        hdr.udp.length = eg_md.pkt_length - 16w34;
    }
    action rewrite_dtel_ifa_clone() {
        eg_md.dtel.ifa_cloned = 1;
    }
    @ways(2) table rewrite {
        key = {
            eg_md.mirror.session_id: exact;
        }
        actions = {
            NoAction;
            rewrite_;
            rewrite_rspan;
            rewrite_erspan_type2;
            rewrite_erspan_type3;
            rewrite_erspan_type2_with_vlan;
            rewrite_erspan_type3_with_vlan;
            rewrite_dtel_report_with_entropy;
            rewrite_dtel_report_without_entropy;
            rewrite_ip_udp_lengths;
        }
        const default_action = NoAction;
        size = table_size;
    }
    action adjust_length(bit<16> length_offset) {
        eg_md.pkt_length = eg_md.pkt_length + length_offset;
        eg_md.mirror.type = 0;
    }
    table pkt_length {
        key = {
            eg_md.mirror.type: exact;
        }
        actions = {
            adjust_length;
        }
        const entries = {
                        2 : adjust_length(0xfff2);
                        1 : adjust_length(0xfff4);
                        3 : adjust_length(0x1);
                        4 : adjust_length(0xffff);
                        5 : adjust_length(0xfff8);
                        255 : adjust_length(20);
        }
    }
    action rewrite_ipv4_udp_len_truncate() {
    }
    table pkt_len_trunc_adjustment {
        key = {
            hdr.udp.isValid() : exact;
            hdr.ipv4.isValid(): exact;
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
    }
}

control IngressRmac(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t port_vlan_table_size, switch_uint32_t vlan_table_size=4096) {
    action rmac_miss() {
        ig_md.flags.rmac_hit = false;
    }
    action rmac_hit() {
        ig_md.flags.rmac_hit = true;
    }
    table pv_rmac {
        key = {
            ig_md.port_lag_index     : ternary;
            hdr.vlan_tag[0].isValid(): ternary;
            hdr.vlan_tag[0].vid      : ternary;
            hdr.ethernet.dst_addr    : exact;
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
            hdr.vlan_tag[0].vid  : exact;
            hdr.ethernet.dst_addr: exact;
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
            rmac_miss: {
                if (hdr.vlan_tag[0].isValid()) {
                    vlan_rmac.apply();
                }
            }
        }
    }
}

control PortMirror(in switch_port_t port, in switch_pkt_src_t src, inout switch_mirror_metadata_t mirror_md)(switch_uint32_t table_size=288) {
    action set_mirror_id(switch_mirror_session_t session_id, switch_mirror_meter_id_t meter_index) {
        mirror_md.type = 1;
        mirror_md.src = src;
        mirror_md.session_id = session_id;
    }
    table port_mirror {
        key = {
            port: exact;
        }
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

control IngressPortMapping(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(switch_uint32_t port_vlan_table_size, switch_uint32_t bd_table_size, switch_uint32_t port_table_size=288, switch_uint32_t vlan_table_size=4096, switch_uint32_t double_tag_table_size=1024) {
    PortMirror(port_table_size) port_mirror;
    IngressRmac(port_vlan_table_size, vlan_table_size) rmac;
    ActionProfile(bd_table_size) bd_action_profile;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;
    const bit<32> vlan_membership_size = 1 << 19;
    Register<bit<1>, bit<32>>(vlan_membership_size, 0) vlan_membership;
    RegisterAction<bit<1>, bit<32>, bit<1>>(vlan_membership) check_vlan_membership = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = ~val;
        }
    };
    action terminate_cpu_packet() {
        ig_md.port = (switch_port_t)hdr.cpu.ingress_port;
        ig_md.egress_port_lag_index = (switch_port_lag_index_t)hdr.cpu.port_lag_index;
        ig_intr_md_for_tm.qid = (switch_qid_t)hdr.cpu.egress_queue;
        ig_md.flags.bypass_egress = (bool)hdr.cpu.tx_bypass;
        hdr.ethernet.ether_type = hdr.cpu.ether_type;
    }
    action set_cpu_port_properties(switch_port_lag_index_t port_lag_index, switch_ig_port_lag_label_t port_lag_label, switch_yid_t exclusion_id, switch_qos_trust_mode_t trust_mode, switch_qos_group_t qos_group, switch_pkt_color_t color, switch_tc_t tc) {
        ig_md.port_lag_index = port_lag_index;
        ig_md.port_lag_label = port_lag_label;
        ig_md.qos.trust_mode = trust_mode;
        ig_md.qos.group = qos_group;
        ig_md.qos.color = color;
        ig_md.qos.tc = tc;
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
        terminate_cpu_packet();
    }
    action set_port_properties(switch_yid_t exclusion_id, switch_learning_mode_t learning_mode, switch_qos_trust_mode_t trust_mode, switch_qos_group_t qos_group, switch_pkt_color_t color, switch_tc_t tc, switch_meter_index_t meter_index, switch_sflow_id_t sflow_session_id, bool mac_pkt_class) {
        ig_md.qos.trust_mode = trust_mode;
        ig_md.qos.group = qos_group;
        ig_md.qos.color = color;
        ig_md.qos.tc = tc;
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
        ig_md.learning.port_mode = learning_mode;
        ig_md.checks.same_if = SWITCH_FLOOD;
        ig_md.flags.mac_pkt_class = mac_pkt_class;
    }
    table port_mapping {
        key = {
            ig_md.port: exact;
        }
        actions = {
            set_port_properties;
            set_cpu_port_properties;
        }
        size = port_table_size;
    }
    action port_vlan_miss() {
    }
    action set_bd_properties(switch_bd_t bd, switch_vrf_t vrf, switch_bd_label_t bd_label, switch_rid_t rid, switch_stp_group_t stp_group, switch_learning_mode_t learning_mode, bool ipv4_unicast_enable, bool ipv4_multicast_enable, bool igmp_snooping_enable, bool ipv6_unicast_enable, bool ipv6_multicast_enable, bool mld_snooping_enable, switch_multicast_rpf_group_t mrpf_group, switch_nat_zone_t zone) {
        ig_md.bd = bd;
        ig_md.bd_label = bd_label;
        ig_md.vrf = vrf;
        ig_intr_md_for_tm.rid = rid;
        ig_md.stp.group = stp_group;
        ig_md.multicast.rpf_group = mrpf_group;
        ig_md.learning.bd_mode = learning_mode;
        ig_md.ipv4.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv4.multicast_enable = ipv4_multicast_enable;
        ig_md.ipv4.multicast_snooping = igmp_snooping_enable;
        ig_md.ipv6.unicast_enable = ipv6_unicast_enable;
        ig_md.ipv6.multicast_enable = ipv6_multicast_enable;
        ig_md.ipv6.multicast_snooping = mld_snooping_enable;
    }
    table port_double_tag_to_bd_mapping {
        key = {
            ig_md.port_lag_index     : exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[0].vid      : exact;
            hdr.vlan_tag[1].isValid(): exact;
            hdr.vlan_tag[1].vid      : exact;
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
    table port_vlan_to_bd_mapping {
        key = {
            ig_md.port_lag_index     : ternary;
            hdr.vlan_tag[0].isValid(): ternary;
            hdr.vlan_tag[0].vid      : ternary;
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
    table vlan_to_bd_mapping {
        key = {
            hdr.vlan_tag[0].vid: exact;
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
        key = {
            hdr.cpu.ingress_bd: exact;
        }
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
        ig_intr_md_for_tm.rid = SWITCH_RID_DEFAULT;
        ig_md.flags.peer_link = true;
    }
    table peer_link {
        key = {
            ig_md.port_lag_index: exact;
        }
        actions = {
            NoAction;
            set_peer_link_properties;
        }
        const default_action = NoAction;
        size = port_table_size;
    }
    apply {
        port_mirror.apply(ig_md.port, SWITCH_PKT_SRC_CLONED_INGRESS, ig_md.mirror);
        switch (port_mapping.apply().action_run) {
            set_port_properties: {
                if (!port_vlan_to_bd_mapping.apply().hit) {
                    if (hdr.vlan_tag[0].isValid()) {
                        vlan_to_bd_mapping.apply();
                    }
                }
                rmac.apply(hdr, ig_md);
            }
        }
        if (hdr.vlan_tag[0].isValid() && !hdr.vlan_tag[1].isValid() && (bit<1>)ig_md.flags.port_vlan_miss == 0) {
            bit<32> pv_hash_ = hash.get({ ig_md.port[6:0], hdr.vlan_tag[0].vid });
            ig_md.flags.port_vlan_miss = (bool)check_vlan_membership.execute(pv_hash_);
        }
    }
}

control LAG(inout switch_ingress_metadata_t ig_md, in switch_hash_t hash, out switch_port_t egress_port) {
    Hash<switch_uint16_t>(HashAlgorithm_t.CRC16) selector_hash;
    ActionProfile(LAG_SELECTOR_TABLE_SIZE) lag_action_profile;
    ActionSelector(lag_action_profile, selector_hash, SelectorMode_t.FAIR, LAG_MAX_MEMBERS_PER_GROUP, LAG_GROUP_TABLE_SIZE) lag_selector;
    action set_lag_port(switch_port_t port) {
        egress_port = port;
    }
    action set_peer_link_port(switch_port_t port, switch_port_lag_index_t port_lag_index) {
        egress_port = port;
        ig_md.egress_port_lag_index = port_lag_index;
        ig_md.checks.same_if = ig_md.port_lag_index ^ port_lag_index;
    }
    action lag_miss() {
    }
    table lag {
        key = {
            ig_md.egress_port_lag_index: exact @name("port_lag_index") ;
            hash                       : selector;
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

control EgressPortMapping(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, in switch_port_t port)(switch_uint32_t table_size=288) {
    PortMirror(table_size) port_mirror;
    action port_normal(switch_port_lag_index_t port_lag_index, switch_eg_port_lag_label_t port_lag_label, switch_qos_group_t qos_group, switch_meter_index_t meter_index, switch_sflow_id_t sflow_session_id, bool mlag_member) {
        eg_md.port_lag_index = port_lag_index;
        eg_md.port_lag_label = port_lag_label;
        eg_md.qos.group = qos_group;
    }
    table port_mapping {
        key = {
            port: exact;
        }
        actions = {
            port_normal;
        }
        size = table_size;
    }
    apply {
        port_mapping.apply();
        port_mirror.apply(port, SWITCH_PKT_SRC_CLONED_EGRESS, eg_md.mirror);
    }
}

control EgressCpuRewrite(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, in switch_port_t port)(switch_uint32_t table_size=288) {
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
        hdr.cpu.ingress_port = (bit<16>)eg_md.ingress_port;
        hdr.cpu.port_lag_index = (bit<16>)eg_md.port_lag_index;
        hdr.cpu.ingress_bd = (bit<16>)eg_md.bd;
        hdr.cpu.reason_code = eg_md.cpu_reason;
        hdr.cpu.ether_type = hdr.ethernet.ether_type;
        hdr.ethernet.ether_type = 0x9000;
    }
    table cpu_port_rewrite {
        key = {
            port: exact;
        }
        actions = {
            cpu_rewrite;
        }
        size = table_size;
    }
    apply {
        cpu_port_rewrite.apply();
    }
}

control PktValidation(in switch_header_t hdr, inout switch_ingress_metadata_t ig_md) {
    const switch_uint32_t table_size = MIN_TABLE_SIZE;
    action valid_ethernet_pkt(switch_pkt_type_t pkt_type) {
        ig_md.lkp.pkt_type = pkt_type;
        ig_md.lkp.mac_src_addr = hdr.ethernet.src_addr;
        ig_md.lkp.mac_dst_addr = hdr.ethernet.dst_addr;
    }
    action malformed_eth_pkt(bit<8> reason) {
        ig_md.lkp.mac_src_addr = hdr.ethernet.src_addr;
        ig_md.lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        ig_md.lkp.mac_type = hdr.ethernet.ether_type;
        ig_md.l2_drop_reason = reason;
    }
    action valid_pkt_untagged(switch_pkt_type_t pkt_type) {
        ig_md.lkp.mac_type = hdr.ethernet.ether_type;
        valid_ethernet_pkt(pkt_type);
    }
    action valid_pkt_tagged(switch_pkt_type_t pkt_type) {
        ig_md.lkp.mac_type = hdr.vlan_tag[0].ether_type;
        ig_md.lkp.pcp = hdr.vlan_tag[0].pcp;
        valid_ethernet_pkt(pkt_type);
    }
    action valid_pkt_double_tagged(switch_pkt_type_t pkt_type) {
        ig_md.lkp.mac_type = hdr.vlan_tag[1].ether_type;
        ig_md.lkp.pcp = hdr.vlan_tag[1].pcp;
        valid_ethernet_pkt(pkt_type);
    }
    table validate_ethernet {
        key = {
            hdr.ethernet.src_addr    : ternary;
            hdr.ethernet.dst_addr    : ternary;
            hdr.vlan_tag[0].isValid(): ternary;
        }
        actions = {
            malformed_eth_pkt;
            valid_pkt_untagged;
            valid_pkt_tagged;
        }
        size = table_size;
    }
    action valid_arp_pkt() {
        ig_md.lkp.arp_opcode = hdr.arp.opcode;
    }
    action valid_ipv6_pkt(bool is_link_local) {
        ig_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp.ip_tos = hdr.ipv6.traffic_class;
        ig_md.lkp.ip_proto = hdr.ipv6.next_hdr;
        ig_md.lkp.ip_ttl = hdr.ipv6.hop_limit;
        ig_md.lkp.ip_src_addr = hdr.ipv6.src_addr;
        ig_md.lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        ig_md.lkp.ipv6_flow_label = hdr.ipv6.flow_label;
        ig_md.flags.link_local = is_link_local;
    }
    action valid_ipv4_pkt(switch_ip_frag_t ip_frag, bool is_link_local) {
        ig_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        ig_md.lkp.ip_tos = hdr.ipv4.diffserv;
        ig_md.lkp.ip_proto = hdr.ipv4.protocol;
        ig_md.lkp.ip_ttl = hdr.ipv4.ttl;
        ig_md.lkp.ip_src_addr[63:0] = 64w0;
        ig_md.lkp.ip_src_addr[95:64] = hdr.ipv4.src_addr;
        ig_md.lkp.ip_src_addr[127:96] = 32w0;
        ig_md.lkp.ip_dst_addr[63:0] = 64w0;
        ig_md.lkp.ip_dst_addr[95:64] = hdr.ipv4.dst_addr;
        ig_md.lkp.ip_dst_addr[127:96] = 32w0;
        ig_md.lkp.ip_frag = ip_frag;
        ig_md.flags.link_local = is_link_local;
    }
    action malformed_ipv4_pkt(bit<8> reason, switch_ip_frag_t ip_frag) {
        valid_ipv4_pkt(ip_frag, false);
        ig_md.drop_reason = reason;
    }
    action malformed_ipv6_pkt(bit<8> reason) {
        valid_ipv6_pkt(false);
        ig_md.drop_reason = reason;
    }
    table validate_ip {
        key = {
            hdr.arp.isValid()            : ternary;
            hdr.ipv4.isValid()           : ternary;
            ig_md.flags.ipv4_checksum_err: ternary;
            hdr.ipv4.version             : ternary;
            hdr.ipv4.ihl                 : ternary;
            hdr.ipv4.flags               : ternary;
            hdr.ipv4.frag_offset         : ternary;
            hdr.ipv4.ttl                 : ternary;
            hdr.ipv4.src_addr[31:0]      : ternary;
            hdr.ipv6.isValid()           : ternary;
            hdr.ipv6.version             : ternary;
            hdr.ipv6.hop_limit           : ternary;
            hdr.ipv6.src_addr[127:0]     : ternary;
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
    action set_tcp_ports() {
        ig_md.lkp.l4_src_port = hdr.tcp.src_port;
        ig_md.lkp.l4_dst_port = hdr.tcp.dst_port;
        ig_md.lkp.tcp_flags = hdr.tcp.flags;
        ig_md.lkp.hash_l4_src_port = hdr.tcp.src_port;
        ig_md.lkp.hash_l4_dst_port = hdr.tcp.dst_port;
    }
    action set_udp_ports() {
        ig_md.lkp.l4_src_port = hdr.udp.src_port;
        ig_md.lkp.l4_dst_port = hdr.udp.dst_port;
        ig_md.lkp.tcp_flags = 0;
        ig_md.lkp.hash_l4_src_port = hdr.udp.src_port;
        ig_md.lkp.hash_l4_dst_port = hdr.udp.dst_port;
    }
    action set_icmp_type() {
        ig_md.lkp.l4_src_port[7:0] = hdr.icmp.type;
        ig_md.lkp.l4_src_port[15:8] = hdr.icmp.code;
        ig_md.lkp.l4_dst_port = 0;
        ig_md.lkp.tcp_flags = 0;
        ig_md.lkp.hash_l4_src_port[7:0] = hdr.icmp.type;
        ig_md.lkp.hash_l4_src_port[15:8] = hdr.icmp.code;
        ig_md.lkp.hash_l4_dst_port = 0;
    }
    action set_igmp_type() {
        ig_md.lkp.l4_src_port[7:0] = hdr.igmp.type;
        ig_md.lkp.l4_src_port[15:8] = 0;
        ig_md.lkp.l4_dst_port = 0;
        ig_md.lkp.tcp_flags = 0;
        ig_md.lkp.hash_l4_src_port = 0;
        ig_md.lkp.hash_l4_dst_port = 0;
    }
    table validate_other {
        key = {
            hdr.tcp.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.icmp.isValid(): exact;
            hdr.igmp.isValid(): exact;
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

control SameMacCheck(inout switch_ingress_metadata_t ig_md) {
    action compute_same_mac_check() {
        ig_md.drop_reason = SWITCH_DROP_REASON_OUTER_SAME_MAC_CHECK;
    }
    @ways(1) table same_mac_check {
        key = {
            ig_md.same_mac: exact;
        }
        actions = {
            NoAction;
            compute_same_mac_check;
        }
        const default_action = NoAction;
        const entries = {
                        48w0x0 : compute_same_mac_check();
        }
    }
    apply {
        ig_md.same_mac = ig_md.lkp.mac_src_addr ^ ig_md.lkp.mac_dst_addr;
        same_mac_check.apply();
    }
}

control InnerPktValidation(in switch_header_t hdr, inout switch_ingress_metadata_t ig_md) {
    action valid_ethernet_pkt(switch_pkt_type_t pkt_type) {
        ig_md.lkp.pkt_type = pkt_type;
    }
    action valid_ipv4_pkt(switch_pkt_type_t pkt_type) {
        ig_md.lkp.mac_type = 0x800;
        ig_md.lkp.pkt_type = pkt_type;
        ig_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        ig_md.lkp.ip_tos = hdr.inner_ipv4.diffserv;
        ig_md.lkp.ip_ttl = hdr.inner_ipv4.ttl;
        ig_md.lkp.ip_proto = hdr.inner_ipv4.protocol;
        ig_md.lkp.ip_src_addr[63:0] = 64w0;
        ig_md.lkp.ip_src_addr[95:64] = hdr.inner_ipv4.src_addr;
        ig_md.lkp.ip_src_addr[127:96] = 32w0;
        ig_md.lkp.ip_dst_addr[63:0] = 64w0;
        ig_md.lkp.ip_dst_addr[95:64] = hdr.inner_ipv4.dst_addr;
        ig_md.lkp.ip_dst_addr[127:96] = 32w0;
    }
    action valid_ipv6_pkt(switch_pkt_type_t pkt_type) {
        ig_md.lkp.mac_type = 0x86dd;
        ig_md.lkp.pkt_type = pkt_type;
        ig_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp.ip_tos = hdr.inner_ipv6.traffic_class;
        ig_md.lkp.ip_ttl = hdr.inner_ipv6.hop_limit;
        ig_md.lkp.ip_proto = hdr.inner_ipv6.next_hdr;
        ig_md.lkp.ip_src_addr = hdr.inner_ipv6.src_addr;
        ig_md.lkp.ip_dst_addr = hdr.inner_ipv6.dst_addr;
        ig_md.lkp.ipv6_flow_label = hdr.inner_ipv6.flow_label;
        ig_md.flags.link_local = false;
    }
    action set_tcp_ports() {
        ig_md.lkp.l4_src_port = hdr.inner_tcp.src_port;
        ig_md.lkp.l4_dst_port = hdr.inner_tcp.dst_port;
        ig_md.lkp.hash_l4_src_port = hdr.inner_tcp.src_port;
        ig_md.lkp.hash_l4_dst_port = hdr.inner_tcp.dst_port;
    }
    action set_udp_ports() {
        ig_md.lkp.l4_src_port = hdr.inner_udp.src_port;
        ig_md.lkp.l4_dst_port = hdr.inner_udp.dst_port;
        ig_md.lkp.hash_l4_src_port = hdr.inner_udp.src_port;
        ig_md.lkp.hash_l4_dst_port = hdr.inner_udp.dst_port;
    }
    action valid_ipv4_tcp_pkt(switch_pkt_type_t pkt_type) {
        valid_ipv4_pkt(pkt_type);
        set_tcp_ports();
    }
    action valid_ipv4_udp_pkt(switch_pkt_type_t pkt_type) {
        valid_ipv4_pkt(pkt_type);
        set_udp_ports();
    }
    action valid_ipv6_tcp_pkt(switch_pkt_type_t pkt_type) {
        valid_ipv6_pkt(pkt_type);
        set_tcp_ports();
    }
    action valid_ipv6_udp_pkt(switch_pkt_type_t pkt_type) {
        valid_ipv6_pkt(pkt_type);
        set_udp_ports();
    }
    action malformed_pkt(bit<8> reason) {
        ig_md.drop_reason = reason;
    }
    table validate_ethernet {
        key = {
            hdr.inner_ethernet.isValid()       : ternary;
            hdr.inner_ipv6.isValid()           : ternary;
            hdr.inner_ipv6.version             : ternary;
            hdr.inner_ipv6.hop_limit           : ternary;
            hdr.inner_ipv4.isValid()           : ternary;
            ig_md.flags.inner_ipv4_checksum_err: ternary;
            hdr.inner_ipv4.version             : ternary;
            hdr.inner_ipv4.ihl                 : ternary;
            hdr.inner_ipv4.ttl                 : ternary;
            hdr.inner_tcp.isValid()            : ternary;
            hdr.inner_udp.isValid()            : ternary;
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

control MulticastFlooding(inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size) {
    action flood(switch_mgid_t mgid) {
        ig_md.multicast.id = mgid;
    }
    table bd_flood {
        key = {
            ig_md.bd          : exact @name("bd") ;
            ig_md.lkp.pkt_type: exact @name("pkt_type") ;
        }
        actions = {
            flood;
        }
        size = table_size;
    }
    apply {
        bd_flood.apply();
    }
}

control MulticastReplication(in switch_rid_t replication_id, in switch_port_t port, inout switch_egress_metadata_t eg_md)(switch_uint32_t table_size=4096) {
    action rid_hit(switch_bd_t bd) {
        eg_md.checks.same_bd = bd ^ eg_md.bd;
        eg_md.bd = bd;
    }
    action rid_miss() {
        eg_md.flags.routed = false;
    }
    table rid {
        key = {
            replication_id: exact;
        }
        actions = {
            rid_miss;
            rid_hit;
        }
        size = table_size;
        const default_action = rid_miss;
    }
    apply {
    }
}

control ECNAcl(in switch_ingress_metadata_t ig_md, in switch_lookup_fields_t lkp, inout switch_pkt_color_t pkt_color)(switch_uint32_t table_size=512) {
    action set_ingress_color(switch_pkt_color_t color) {
        pkt_color = color;
    }
    table acl {
        key = {
            ig_md.port_lag_label: ternary;
            lkp.ip_tos          : ternary;
            lkp.tcp_flags       : ternary;
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

control PFCWd(in switch_port_t port, in switch_qid_t qid, out bool flag)(switch_uint32_t table_size=512) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;
    action acl_deny() {
        flag = true;
        stats.count();
    }
    @ways(2) table acl {
        key = {
            qid : exact;
            port: exact;
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

control IngressQoSMap(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t dscp_map_size=2048, switch_uint32_t pcp_map_size=256) {
    action set_ingress_tc(switch_tc_t tc) {
        ig_md.qos.tc = tc;
    }
    action set_ingress_color(switch_pkt_color_t color) {
        ig_md.qos.color = color;
    }
    action set_ingress_tc_and_color(switch_tc_t tc, switch_pkt_color_t color) {
        set_ingress_tc(tc);
        set_ingress_color(color);
    }
    table dscp_tc_map {
        key = {
            ig_md.qos.group      : exact;
            ig_md.lkp.ip_tos[7:2]: exact;
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
            ig_md.qos.group: exact;
            ig_md.lkp.pcp  : exact;
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
            ig_md.qos.group: exact;
            hdr.mpls[0].exp: exact;
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
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_QOS != 0) && ig_md.qos.trust_mode & SWITCH_QOS_TRUST_MODE_TRUST_DSCP == SWITCH_QOS_TRUST_MODE_TRUST_DSCP && ig_md.lkp.ip_type != SWITCH_IP_TYPE_NONE) {
            dscp_tc_map.apply();
        } else if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_QOS != 0) && ig_md.qos.trust_mode & SWITCH_QOS_TRUST_MODE_TRUST_PCP == SWITCH_QOS_TRUST_MODE_TRUST_PCP && hdr.vlan_tag[0].isValid()) {
            pcp_tc_map.apply();
        }
    }
}

control IngressTC(inout switch_ingress_metadata_t ig_md) {
    const bit<32> tc_table_size = 1024;
    action set_icos(switch_cos_t icos) {
        ig_md.qos.icos = icos;
    }
    action set_queue(switch_qid_t qid) {
        ig_md.qos.qid = qid;
    }
    action set_icos_and_queue(switch_cos_t icos, switch_qid_t qid) {
        set_icos(icos);
        set_queue(qid);
    }
    table traffic_class {
        key = {
            ig_md.port     : ternary @name("port") ;
            ig_md.qos.color: ternary @name("color") ;
            ig_md.qos.tc   : exact @name("tc") ;
        }
        actions = {
            set_icos;
            set_queue;
            set_icos_and_queue;
        }
        size = tc_table_size;
    }
    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_QOS != 0)) {
            traffic_class.apply();
        }
    }
}

control PPGStats(inout switch_ingress_metadata_t ig_md) {
    const bit<32> ppg_table_size = 1024;
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) ppg_stats;
    action count() {
        ppg_stats.count();
    }
    @ways(2) table ppg {
        key = {
            ig_md.port    : exact @name("port") ;
            ig_md.qos.icos: exact @name("icos") ;
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

control EgressQoS(inout switch_header_t hdr, in switch_port_t port, inout switch_egress_metadata_t eg_md)(switch_uint32_t table_size=1024) {
    action set_ipv4_dscp(bit<6> dscp, bit<3> exp) {
        hdr.ipv4.diffserv[7:2] = dscp;
        eg_md.tunnel.mpls_encap_exp = exp;
    }
    action set_ipv4_tos(switch_uint8_t tos, bit<3> exp) {
        hdr.ipv4.diffserv = tos;
        eg_md.tunnel.mpls_encap_exp = exp;
    }
    action set_ipv6_dscp(bit<6> dscp, bit<3> exp) {
        hdr.ipv6.traffic_class[7:2] = dscp;
        eg_md.tunnel.mpls_encap_exp = exp;
    }
    action set_ipv6_tos(switch_uint8_t tos, bit<3> exp) {
        hdr.ipv6.traffic_class = tos;
        eg_md.tunnel.mpls_encap_exp = exp;
    }
    action set_vlan_pcp(bit<3> pcp, bit<3> exp) {
        hdr.vlan_tag[0].pcp = pcp;
        eg_md.tunnel.mpls_encap_exp = exp;
    }
    table qos_map {
        key = {
            eg_md.qos.group   : ternary @name("group") ;
            eg_md.qos.tc      : ternary @name("tc") ;
            eg_md.qos.color   : ternary @name("color") ;
            hdr.ipv4.isValid(): ternary;
            hdr.ipv6.isValid(): ternary;
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
        if (!eg_md.flags.bypass_egress) {
            qos_map.apply();
        }
    }
}

control EgressQueue(in switch_port_t port, inout switch_egress_metadata_t eg_md)(switch_uint32_t queue_table_size=4096) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) queue_stats;
    action count() {
        queue_stats.count();
    }
    @ways(2) table queue {
        key = {
            port         : exact;
            eg_md.qos.qid: exact @name("qid") ;
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

control StormControl(inout switch_ingress_metadata_t ig_md, in switch_pkt_type_t pkt_type, out bool flag)(switch_uint32_t table_size=256, switch_uint32_t meter_size=1024) {
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
            ig_md.qos.storm_control_color: exact;
            pkt_type                     : ternary;
            ig_md.port                   : exact;
            ig_md.flags.dmac_miss        : ternary;
        }
        actions = {
            @defaultonly NoAction;
            count;
            drop_and_count;
        }
        const default_action = NoAction;
        size = table_size * 2;
        counters = storm_control_stats;
    }
    action set_meter(bit<16> index) {
        ig_md.qos.storm_control_color = (bit<2>)meter.execute(index);
    }
    table storm_control {
        key = {
            ig_md.port           : exact;
            pkt_type             : ternary;
            ig_md.flags.dmac_miss: ternary;
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

control IngressMirrorMeter(inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size=256) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;
    Meter<bit<9>>(table_size, MeterType_t.PACKETS) meter;
    switch_pkt_color_t color;
    action mirror_and_count() {
        stats.count();
    }
    action no_mirror_and_count() {
        stats.count();
        ig_md.mirror.type = 0;
    }
    @ways(2) table meter_action {
        key = {
            color                   : exact;
            ig_md.mirror.meter_index: exact;
        }
        actions = {
            @defaultonly NoAction;
            mirror_and_count;
            no_mirror_and_count;
        }
        const default_action = NoAction;
        size = table_size * 2;
        counters = stats;
    }
    action set_meter(bit<9> index) {
        color = (bit<2>)meter.execute(index);
    }
    table meter_index {
        key = {
            ig_md.mirror.meter_index: exact;
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

control EgressMirrorMeter(inout switch_egress_metadata_t eg_md)(switch_uint32_t table_size=256) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;
    Meter<bit<9>>(table_size, MeterType_t.PACKETS) meter;
    switch_pkt_color_t color;
    action mirror_and_count() {
        stats.count();
    }
    action no_mirror_and_count() {
        stats.count();
        eg_md.mirror.type = 0;
    }
    @ways(2) table meter_action {
        key = {
            color                   : exact;
            eg_md.mirror.meter_index: exact;
        }
        actions = {
            @defaultonly NoAction;
            mirror_and_count;
            no_mirror_and_count;
        }
        const default_action = NoAction;
        size = table_size * 2;
        counters = stats;
    }
    action set_meter(bit<9> index) {
        color = (bit<2>)meter.execute(index);
    }
    table meter_index {
        key = {
            eg_md.mirror.meter_index: exact;
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

control IngressAclMeter(inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size=256) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;
    Meter<bit<9>>(table_size, MeterType_t.BYTES) meter;
    switch_pkt_color_t color;
    action count() {
        stats.count();
        ig_md.flags.acl_meter_drop = false;
    }
    action drop_and_count() {
        stats.count();
        ig_md.flags.acl_meter_drop = true;
    }
    table meter_action {
        key = {
            color                    : exact;
            ig_md.qos.acl_meter_index: exact;
        }
        actions = {
            @defaultonly NoAction;
            count;
            drop_and_count;
        }
        const default_action = NoAction;
        size = table_size * 3;
        counters = stats;
    }
    action set_meter(bit<9> index) {
        color = (bit<2>)meter.execute(index);
    }
    table meter_index {
        key = {
            ig_md.qos.acl_meter_index: exact;
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

control WRED(inout switch_header_t hdr, in switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, out bool wred_drop) {
    switch_wred_index_t index;
    bit<1> wred_flag;
    const switch_uint32_t wred_size = 1 << 10;
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) stats;
    Wred<bit<19>, switch_wred_index_t>(wred_size, 1, 0) wred;
    action set_wred_index(switch_wred_index_t wred_index) {
        index = wred_index;
        wred_flag = (bit<1>)wred.execute(eg_md.qos.qdepth, wred_index);
    }
    table wred_index {
        key = {
            eg_intr_md.egress_port: exact @name("port") ;
            eg_md.qos.qid         : exact @name("qid") ;
            eg_md.qos.color       : exact @name("color") ;
        }
        actions = {
            NoAction;
            set_wred_index;
        }
        const default_action = NoAction;
        size = wred_size;
    }
    action set_ipv4_ecn() {
        hdr.ipv4.diffserv[1:0] = SWITCH_ECN_CODEPOINT_CE;
        wred_drop = false;
    }
    action set_ipv6_ecn() {
        hdr.ipv6.traffic_class[1:0] = SWITCH_ECN_CODEPOINT_CE;
        wred_drop = false;
    }
    action drop() {
        wred_drop = true;
    }
    table v4_wred_action {
        key = {
            index                 : exact;
            hdr.ipv4.diffserv[1:0]: exact;
        }
        actions = {
            NoAction;
            drop;
            set_ipv4_ecn;
        }
        size = 3 * wred_size;
    }
    table v6_wred_action {
        key = {
            index                      : exact;
            hdr.ipv6.traffic_class[1:0]: exact;
        }
        actions = {
            NoAction;
            drop;
            set_ipv6_ecn;
        }
        size = 3 * wred_size;
    }
    action count() {
        stats.count();
    }
    @ways(2) table wred_stats {
        key = {
            eg_intr_md.egress_port: exact @name("port") ;
            eg_md.qos.qid         : exact @name("qid") ;
            eg_md.qos.color       : exact @name("color") ;
            wred_drop             : exact;
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
        if (!eg_md.flags.bypass_egress) {
            wred_index.apply();
        }
        if (!eg_md.flags.bypass_egress && wred_flag == 1) {
            if (hdr.ipv4.isValid()) {
                switch (v4_wred_action.apply().action_run) {
                    NoAction: {
                    }
                    default: {
                        wred_stats.apply();
                    }
                }
            } else if (hdr.ipv6.isValid()) {
                switch (v6_wred_action.apply().action_run) {
                    NoAction: {
                    }
                    default: {
                        wred_stats.apply();
                    }
                }
            }
        }
    }
}

control DeflectOnDrop(in switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(switch_uint32_t table_size=1024) {
    action enable_dod() {
        ig_intr_md_for_tm.deflect_on_drop = 1w1;
    }
    action disable_dod() {
        ig_intr_md_for_tm.deflect_on_drop = 1w0;
    }
    table config {
        key = {
            ig_md.dtel.report_type             : ternary;
            ig_intr_md_for_tm.ucast_egress_port: ternary @name("egress_port") ;
            ig_md.qos.qid                      : ternary @name("qid") ;
            ig_md.multicast.id                 : ternary;
            ig_md.cpu_reason                   : ternary;
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

control MirrorOnDrop(in switch_drop_reason_t drop_reason, inout switch_dtel_metadata_t dtel_md, inout switch_mirror_metadata_t mirror_md) {
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
            drop_reason        : ternary;
            dtel_md.report_type: ternary;
        }
        actions = {
            NoAction;
            mirror;
            mirror_and_set_d_bit;
        }
        const default_action = NoAction;
    }
    apply {
        config.apply();
    }
}

control DropReport(in switch_header_t hdr, in switch_egress_metadata_t eg_md, in bit<32> hash, inout bit<2> flag) {
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
        if (eg_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_DROP | SWITCH_DTEL_SUPPRESS_REPORT | SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE) == SWITCH_DTEL_REPORT_TYPE_DROP && hdr.dtel_drop_report.isValid()) {
            flag[0:0] = filter1.execute(hash[17 - 1:0]);
        }
        if (eg_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_DROP | SWITCH_DTEL_SUPPRESS_REPORT | SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE) == SWITCH_DTEL_REPORT_TYPE_DROP && hdr.dtel_drop_report.isValid()) {
            flag[1:1] = filter2.execute(hash[31:32 - 17]);
        }
    }
}

struct switch_queue_alert_threshold_t {
    bit<32> qdepth;
    bit<32> latency;
}

struct switch_queue_report_quota_t {
    bit<32> counter;
    bit<32> latency;
}

control QueueReport(inout switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, out bit<1> qalert) {
    bit<16> quota_;
    const bit<32> queue_table_size = 1024;
    const bit<32> queue_register_size = 2048;
    Register<switch_queue_alert_threshold_t, bit<16>>(queue_register_size) thresholds;
    RegisterAction<switch_queue_alert_threshold_t, bit<16>, bit<1>>(thresholds) check_thresholds = {
        void apply(inout switch_queue_alert_threshold_t reg, out bit<1> flag) {
            if (reg.latency <= eg_md.dtel.latency || reg.qdepth <= (bit<32>)eg_md.qos.qdepth) {
                flag = 1;
            }
        }
    };
    action set_qmask(bit<32> quantization_mask) {
        eg_md.dtel.latency = eg_md.dtel.latency & quantization_mask;
    }
    action set_qalert(bit<16> index, bit<16> quota, bit<32> quantization_mask) {
        qalert = check_thresholds.execute(index);
        quota_ = quota;
        set_qmask(quantization_mask);
    }
    @ways(2) table queue_alert {
        key = {
            eg_md.qos.qid: exact @name("qid") ;
            eg_md.port   : exact @name("port") ;
        }
        actions = {
            set_qalert;
            set_qmask;
        }
        size = queue_table_size;
    }
    Register<switch_queue_report_quota_t, bit<16>>(queue_register_size) quotas;
    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) reset_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            flag = 0;
            reg.counter = (bit<32>)quota_[15:0];
        }
    };
    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) check_latency_and_update_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            if (reg.counter > 0) {
                reg.counter = reg.counter - 1;
                flag = 1;
            }
            if (reg.latency != eg_md.dtel.latency) {
                reg.latency = eg_md.dtel.latency;
                flag = 1;
            }
        }
    };
    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) update_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
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
            eg_md.pkt_src: exact;
            qalert       : exact;
            eg_md.qos.qid: exact @name("qid") ;
            eg_md.port   : exact @name("port") ;
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
        if (eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED) {
            queue_alert.apply();
        }
        check_quota.apply();
    }
}

control FlowReport(in switch_egress_metadata_t eg_md, out bit<2> flag) {
    bit<16> digest;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) hash;
    Register<bit<16>, bit<16>>(1 << 16, 0) array1;
    Register<bit<16>, bit<16>>(1 << 16, 0) array2;
    @reduction_or_group("filter") RegisterAction<bit<16>, bit<16>, bit<2>>(array1) filter1 = {
        void apply(inout bit<16> reg, out bit<2> rv) {
            if (reg == 16w0) {
                rv = 0b10;
            } else if (reg == digest) {
                rv = 0b1;
            }
            reg = digest;
        }
    };
    @reduction_or_group("filter") RegisterAction<bit<16>, bit<16>, bit<2>>(array2) filter2 = {
        void apply(inout bit<16> reg, out bit<2> rv) {
            if (reg == 16w0) {
                rv = 0b10;
            } else if (reg == digest) {
                rv = 0b1;
            }
            reg = digest;
        }
    };
    apply {
        digest = hash.get({ eg_md.dtel.latency, eg_md.ingress_port, eg_md.port, eg_md.dtel.hash });
        if (eg_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_FLOW | SWITCH_DTEL_SUPPRESS_REPORT) == SWITCH_DTEL_REPORT_TYPE_FLOW && eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED) {
            flag = filter1.execute(eg_md.dtel.hash[15:0]);
        }
        if (eg_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_FLOW | SWITCH_DTEL_SUPPRESS_REPORT) == SWITCH_DTEL_REPORT_TYPE_FLOW && eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED) {
            flag = flag | filter2.execute(eg_md.dtel.hash[31:16]);
        }
    }
}

control IngressDtel(in switch_header_t hdr, in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md, in bit<16> hash, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_for_tm) {
    DeflectOnDrop() dod;
    MirrorOnDrop() mod;
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionProfile(DTEL_SELECTOR_TABLE_SIZE) dtel_action_profile;
    ActionSelector(dtel_action_profile, selector_hash, SelectorMode_t.FAIR, DTEL_MAX_MEMBERS_PER_GROUP, DTEL_GROUP_TABLE_SIZE) session_selector;
    action set_mirror_session(switch_mirror_session_t session_id) {
        ig_md.dtel.session_id = session_id;
    }
    table mirror_session {
        key = {
            hdr.ethernet.isValid(): ternary;
            hash                  : selector;
        }
        actions = {
            NoAction;
            set_mirror_session;
        }
        implementation = session_selector;
    }
    apply {
        dod.apply(ig_md, ig_intr_for_tm);
        if (ig_md.mirror.type == 0) {
            mod.apply(ig_md.drop_reason, ig_md.dtel, ig_md.mirror);
        }
        mirror_session.apply();
    }
}

control DtelConfig(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    Register<bit<32>, switch_mirror_session_t>(1024) seq_number;
    RegisterAction<bit<32>, switch_mirror_session_t, bit<32>>(seq_number) get_seq_number = {
        void apply(inout bit<32> reg, out bit<32> rv) {
            reg = reg + 1;
            rv = reg;
        }
    };
    action mirror_switch_local() {
        eg_md.mirror.type = 4;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
    }
    action mirror_switch_local_and_set_q_bit() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_QUEUE;
        mirror_switch_local();
    }
    action mirror_switch_local_and_drop() {
        mirror_switch_local();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }
    action mirror_switch_local_and_set_f_bit_and_drop() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_FLOW;
        mirror_switch_local();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }
    action mirror_switch_local_and_set_q_f_bits_and_drop() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | (SWITCH_DTEL_REPORT_TYPE_QUEUE | SWITCH_DTEL_REPORT_TYPE_FLOW);
        mirror_switch_local();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }
    action mirror_drop() {
        eg_md.mirror.type = 3;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
    }
    action mirror_drop_and_set_q_bit() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_QUEUE;
        mirror_drop();
    }
    action mirror_clone() {
        eg_md.mirror.type = 5;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.dtel.session_id = eg_md.dtel.clone_session_id;
    }
    action drop() {
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }
    action update(switch_uint32_t switch_id, switch_dtel_hw_id_t hw_id, bit<4> next_proto, switch_dtel_report_type_t report_type) {
        hdr.dtel.setValid();
        hdr.dtel.hw_id = hw_id;
        hdr.dtel.switch_id = switch_id;
        hdr.dtel.d_q_f = (bit<3>)report_type;
        hdr.dtel.version = 0;
        hdr.dtel.next_proto = next_proto;
        hdr.dtel.reserved = 0;
        hdr.dtel.seq_number = get_seq_number.execute(eg_md.mirror.session_id);
        hdr.dtel.timestamp = (bit<32>)eg_md.ingress_timestamp;
    }
    action update_and_mirror_truncate(switch_uint32_t switch_id, switch_dtel_hw_id_t hw_id, bit<4> next_proto, bit<8> md_length, bit<16> rep_md_bits, switch_dtel_report_type_t report_type) {
        update(switch_id, hw_id, next_proto, report_type);
        eg_md.mirror.type = 5;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }
    action update_and_set_etrap(switch_uint32_t switch_id, switch_dtel_hw_id_t hw_id, bit<4> next_proto, bit<8> md_length, bit<16> rep_md_bits, switch_dtel_report_type_t report_type, bit<2> etrap_status) {
        hdr.dtel.setValid();
        hdr.dtel.hw_id = hw_id;
        hdr.dtel.switch_id = switch_id;
        hdr.dtel.d_q_f = (bit<3>)report_type;
        hdr.dtel.version = 0;
        hdr.dtel.next_proto = next_proto;
        hdr.dtel.reserved[14:13] = etrap_status;
        hdr.dtel.seq_number = get_seq_number.execute(eg_md.mirror.session_id);
        hdr.dtel.timestamp = (bit<32>)eg_md.ingress_timestamp;
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
    table config {
        key = {
            eg_md.pkt_src                 : ternary;
            eg_md.dtel.report_type        : ternary;
            eg_md.dtel.drop_report_flag   : ternary;
            eg_md.dtel.flow_report_flag   : ternary;
            eg_md.dtel.queue_report_flag  : ternary;
            eg_md.drop_reason             : ternary;
            eg_md.mirror.type             : ternary;
            hdr.dtel_drop_report.isValid(): ternary;
            eg_md.lkp.tcp_flags[2:0]      : ternary;
        }
        actions = {
            NoAction;
            drop;
            mirror_switch_local;
            mirror_switch_local_and_set_q_bit;
            mirror_drop;
            mirror_drop_and_set_q_bit;
            update;
            update_and_mirror_truncate;
        }
        const default_action = NoAction;
    }
    apply {
        config.apply();
    }
}

control IntEdge(inout switch_egress_metadata_t eg_md)(switch_uint32_t port_table_size=288) {
    action set_clone_mirror_session_id(switch_mirror_session_t session_id) {
        eg_md.dtel.clone_session_id = session_id;
    }
    action set_ifa_edge() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_IFA_EDGE;
    }
    table port_lookup {
        key = {
            eg_md.port: exact;
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
        if (eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED) {
            port_lookup.apply();
        }
    }
}

control EgressDtel(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, in bit<32> hash) {
    DropReport() drop_report;
    QueueReport() queue_report;
    FlowReport() flow_report;
    IntEdge() int_edge;
    action convert_ingress_port(switch_port_t port) {
        hdr.dtel_report.ingress_port = port;
    }
    table ingress_port_conversion {
        key = {
            hdr.dtel_report.ingress_port: exact @name("port") ;
            hdr.dtel_report.isValid()   : exact @name("dtel_report_valid") ;
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
            hdr.dtel_report.egress_port: exact @name("port") ;
            hdr.dtel_report.isValid()  : exact @name("dtel_report_valid") ;
        }
        actions = {
            NoAction;
            convert_egress_port;
        }
        const default_action = NoAction;
    }
    action update_dtel_timestamps() {
        eg_md.dtel.latency = eg_md.latency;
        eg_md.timestamp = eg_intr_md_from_prsr.global_tstamp[31:0];
    }
    apply {
        update_dtel_timestamps();
        if (eg_md.pkt_src == SWITCH_PKT_SRC_DEFLECTED && hdr.dtel_drop_report.isValid()) {
            eg_md.port = hdr.dtel_report.egress_port;
        }
        ingress_port_conversion.apply();
        egress_port_conversion.apply();
        queue_report.apply(eg_md, eg_intr_md, eg_md.dtel.queue_report_flag);
        flow_report.apply(eg_md, eg_md.dtel.flow_report_flag);
        drop_report.apply(hdr, eg_md, hash, eg_md.dtel.drop_report_flag);
    }
}

struct switch_sflow_info_t {
    bit<32> current;
    bit<32> rate;
}

control IngressSflow(inout switch_ingress_metadata_t ig_md) {
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

control EgressSflow(inout switch_egress_metadata_t eg_md) {
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

control TcpInt(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, switch_uint32_t port_table_size=288) {
    tcp_int_index_t qdepth_index = 0;
    tcp_int_index_t abytes_index = 0;
    DirectLpf<tcp_int_abytes_t>() abytes_lpf;
    tcp_int_abytes_t abytes_l = 0;
    tcp_int_port_speed_t port_speed_l;
    tcp_int_val_t val_diff = 0;
    bit<32> shifted_hop_lat;
    bit<32> sum_hop_lat;
    Hash<tcp_int_hash_t>(HashAlgorithm_t.RANDOM) hash;
    tcp_int_hash_t int_tag_flag = 1;
    action set_abytes() {
        abytes_l = abytes_lpf.execute((tcp_int_abytes_t)eg_intr_md.pkt_length);
    }
    table abytes {
        key = {
            eg_intr_md.egress_port: exact;
            eg_intr_md.egress_qid : exact;
        }
        actions = {
            set_abytes;
        }
        size = 512;
        filters = abytes_lpf;
        const default_action = set_abytes;
    }
    action set_port_speed(tcp_int_port_speed_t port_speed) {
        port_speed_l = port_speed;
    }
    table port_speed_map {
        key = {
            eg_intr_md.egress_port: exact;
        }
        actions = {
            set_port_speed;
        }
        size = port_table_size;
        default_action = set_port_speed(4);
    }
    action set_abytes_index(tcp_int_index_t index) {
        abytes_index = index;
    }
    @entries_with_ranges(1 << 8) table abytes_map {
        key = {
            abytes_l: range;
        }
        actions = {
            set_abytes_index;
        }
        size = 1 << 8;
    }
    action set_qdepth_index(tcp_int_index_t index) {
        qdepth_index = index;
    }
    @entries_with_ranges(1 << 8) table qdepth_map {
        key = {
            eg_intr_md.deq_qdepth[16 - 1:0]: range;
        }
        actions = {
            set_qdepth_index;
        }
        size = 1 << 8;
    }
    action update_int_val() {
        hdr.tcpopt_int.val = eg_md.tcp_int_val + val_diff;
        hdr.tcpopt_int.id = hdr.ipv4.ttl;
    }
    action calculate_int_val(tcp_int_val_t int_val) {
        val_diff = int_val |-| eg_md.tcp_int_val;
    }
    table int_val {
        key = {
            qdepth_index: exact;
            abytes_index: exact;
        }
        actions = {
            calculate_int_val;
            NoAction;
        }
        size = (1 << 8) * (1 << 8);
        const default_action = NoAction;
    }
    action set_int_tag(tcp_int_hash_t inverse_ratio) {
        int_tag_flag = hash.get({ hdr.tcp.seq_no[31:10], hdr.ipv4.identification }) & inverse_ratio;
    }
    table int_tag {
        actions = {
            set_int_tag;
        }
        size = 1;
        default_action = set_int_tag(0);
    }
    action shift_hop_lat() {
        shifted_hop_lat = hdr.tcpopt_int.lat ++ 8w0;
    }
    action add_this_hop_lat() {
        sum_hop_lat = shifted_hop_lat |+| eg_md.latency;
    }
    action add_const_hop_lat(bit<32> const_lat_ns) {
        sum_hop_lat = sum_hop_lat |+| const_lat_ns;
    }
    action update_int_lat() {
        hdr.tcpopt_int.lat = sum_hop_lat[31:8];
        eg_md.tcp_int_update = true;
    }
    table const_hop_lat {
        actions = {
            add_const_hop_lat;
        }
        size = 1;
        default_action = add_const_hop_lat(0);
    }
    apply {
        if (hdr.tcpopt_int.isValid()) {
            if (hdr.ipv4.isValid()) {
                int_tag.apply();
            } else if (hdr.ipv6.isValid()) {
            }
            shift_hop_lat();
            add_this_hop_lat();
            const_hop_lat.apply();
            abytes.apply();
            port_speed_map.apply();
            abytes_map.apply();
            qdepth_map.apply();
            int_val.apply();
            if (int_tag_flag == 0) {
                update_int_lat();
                if (val_diff != 0 || hdr.tcpopt_int.id == 0) {
                    update_int_val();
                }
            }
        }
    }
}

@pa_container_size("egress", "tcp_int_abytes_l", 8, 8, 8) control SwitchIngress(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    IngressPortMapping(PORT_VLAN_TABLE_SIZE, BD_TABLE_SIZE) ingress_port_mapping;
    PktValidation() pkt_validation;
    SMAC(MAC_TABLE_SIZE) smac;
    DMAC(MAC_TABLE_SIZE) dmac;
    IngressSflow() sflow;
    IngressBd(BD_TABLE_SIZE) bd_stats;
    Ipv4Hash() ipv4_hash;
    Ipv6Hash() ipv6_hash;
    NonIpHash() non_ip_hash;
    Lagv4Hash() lagv4_hash;
    Lagv6Hash() lagv6_hash;
    LOU() lou;
    Fibv4(IPV4_HOST_TABLE_SIZE, IPV4_LPM_TABLE_SIZE, true, IPV4_LOCAL_HOST_TABLE_SIZE) ipv4_fib;
    Fibv6(IPV6_HOST_TABLE_SIZE, IPV6_LPM_TABLE_SIZE, IPV6_LPM64_TABLE_SIZE) ipv6_fib;
    PreIngressAcl(PRE_INGRESS_ACL_TABLE_SIZE) pre_ingress_acl;
    IngressIpv4Acl(INGRESS_IPV4_ACL_TABLE_SIZE) ingress_ipv4_acl;
    IngressIpv6Acl(INGRESS_IPV6_ACL_TABLE_SIZE) ingress_ipv6_acl;
    IngressIpAcl(INGRESS_IP_MIRROR_ACL_TABLE_SIZE) ingress_ip_mirror_acl;
    IngressIpDtelSampleAcl(INGRESS_IP_DTEL_ACL_TABLE_SIZE) ingress_ip_dtel_acl;
    ECNAcl() ecn_acl;
    PFCWd(512) pfc_wd;
    IngressQoSMap() qos_map;
    IngressTC() traffic_class;
    PPGStats() ppg_stats;
    StormControl() storm_control;
    Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
    LAG() lag;
    MulticastFlooding(BD_FLOOD_TABLE_SIZE) flood;
    IngressSystemAcl() system_acl;
    IngressDtel() dtel;
    SameMacCheck() same_mac_check;
    apply {
        pkt_validation.apply(hdr, ig_md);
        ingress_port_mapping.apply(hdr, ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
        pre_ingress_acl.apply(ig_md);
        lou.apply(ig_md);
        smac.apply(ig_md.lkp.mac_src_addr, ig_md, ig_intr_md_for_dprsr.digest_type);
        bd_stats.apply(ig_md.bd, ig_md.lkp.pkt_type);
        same_mac_check.apply(ig_md);
        if (ig_md.flags.rmac_hit) {
            if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_L3 != 0) && ig_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4 && ig_md.ipv4.unicast_enable) {
                ipv4_fib.apply(ig_md);
                ingress_ipv4_acl.apply(ig_md, ig_md.nexthop);
                if (ig_md.lkp.ip_type != SWITCH_IP_TYPE_IPV4) {
                    ingress_ipv6_acl.apply(ig_md, ig_md.nexthop);
                }
            } else if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_L3 != 0) && ig_md.lkp.ip_type == SWITCH_IP_TYPE_IPV6 && ig_md.ipv6.unicast_enable) {
                ipv6_fib.apply(ig_md);
                ingress_ipv6_acl.apply(ig_md, ig_md.nexthop);
            } else {
                dmac.apply(ig_md.lkp.mac_dst_addr, ig_md);
                if (ig_md.lkp.ip_type != SWITCH_IP_TYPE_IPV6) {
                    ingress_ipv4_acl.apply(ig_md, ig_md.nexthop);
                }
                if (ig_md.lkp.ip_type != SWITCH_IP_TYPE_IPV4) {
                    ingress_ipv6_acl.apply(ig_md, ig_md.nexthop);
                }
            }
        } else {
            dmac.apply(ig_md.lkp.mac_dst_addr, ig_md);
            if (ig_md.lkp.ip_type != SWITCH_IP_TYPE_IPV6) {
                ingress_ipv4_acl.apply(ig_md, ig_md.nexthop);
            }
            if (ig_md.lkp.ip_type != SWITCH_IP_TYPE_IPV4) {
                ingress_ipv6_acl.apply(ig_md, ig_md.nexthop);
            }
        }
        ingress_ip_mirror_acl.apply(ig_md, ig_md.unused_nexthop);
        sflow.apply(ig_md);
        if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_NONE) {
            non_ip_hash.apply(ig_md, ig_md.lag_hash);
        } else if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
            lagv4_hash.apply(ig_md.lkp, ig_md.lag_hash);
        } else {
            lagv6_hash.apply(ig_md.lkp, ig_md.lag_hash);
        }
        if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
            ipv4_hash.apply(ig_md.lkp, ig_md.hash);
        } else {
            ipv6_hash.apply(ig_md.lkp, ig_md.hash);
        }
        nexthop.apply(ig_md);
        qos_map.apply(hdr, ig_md);
        traffic_class.apply(ig_md);
        storm_control.apply(ig_md, ig_md.lkp.pkt_type, ig_md.flags.storm_control_drop);
        ppg_stats.apply(ig_md);
        if (ig_md.egress_port_lag_index == SWITCH_FLOOD) {
            flood.apply(ig_md);
        } else {
            lag.apply(ig_md, ig_md.lag_hash, ig_intr_md_for_tm.ucast_egress_port);
        }
        ecn_acl.apply(ig_md, ig_md.lkp, ig_intr_md_for_tm.packet_color);
        pfc_wd.apply(ig_md.port, ig_md.qos.qid, ig_md.flags.pfc_wd_drop);
        system_acl.apply(hdr, ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
        ingress_ip_dtel_acl.apply(ig_md, ig_md.unused_nexthop);
        dtel.apply(hdr, ig_md.lkp, ig_md, ig_md.lag_hash[15:0], ig_intr_md_for_dprsr, ig_intr_md_for_tm);
        add_bridged_md(hdr.bridged_md, ig_md);
        set_ig_intr_md(ig_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);
    }
}

control SwitchEgress(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    EgressPortMapping() egress_port_mapping;
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
    CalculateLatency() calc_latency;
    TcpInt() tcp_int;
    EgressDtel() dtel;
    DtelConfig() dtel_config;
    EgressCpuRewrite() cpu_rewrite;
    Neighbor() neighbor;
    apply {
        egress_port_mapping.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);
        if (eg_md.pkt_src != SWITCH_PKT_SRC_BRIDGED) {
            mirror_rewrite.apply(hdr, eg_md, eg_intr_md_for_dprsr);
        }
        calc_latency.apply(eg_md, eg_intr_md_from_prsr);
        tcp_int.apply(hdr, eg_md, eg_intr_md, eg_intr_md_from_prsr);
        vlan_decap.apply(hdr, eg_md);
        qos.apply(hdr, eg_intr_md.egress_port, eg_md);
        wred.apply(hdr, eg_md, eg_intr_md, eg_md.flags.wred_drop);
        egress_vrf.apply(hdr, eg_md);
        outer_nexthop.apply(hdr, eg_md);
        egress_bd.apply(hdr, eg_md);
        if (hdr.ipv4.isValid()) {
            egress_ipv4_acl.apply(hdr, eg_md);
        } else if (hdr.ipv6.isValid()) {
            egress_ipv6_acl.apply(hdr, eg_md);
        }
        neighbor.apply(hdr, eg_md);
        egress_bd_stats.apply(hdr, eg_md);
        mtu.apply(hdr, eg_md);
        vlan_xlate.apply(hdr, eg_md);
        pfc_wd.apply(eg_intr_md.egress_port, eg_md.qos.qid, eg_md.flags.pfc_wd_drop);
        dtel.apply(hdr, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_md.dtel.hash);
        system_acl.apply(hdr, eg_md, eg_intr_md, eg_intr_md_for_dprsr);
        dtel_config.apply(hdr, eg_md, eg_intr_md_for_dprsr);
        cpu_rewrite.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);
        set_eg_intr_md(eg_md, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
        queue.apply(eg_intr_md.egress_port, eg_md);
    }
}

Pipeline(SwitchIngressParser(), SwitchIngress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) pipe;

Switch(pipe) main;

