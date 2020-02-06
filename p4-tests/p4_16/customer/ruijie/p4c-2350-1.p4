#include <core.p4>
#include <tofino.p4>
#include <tofino1arch.p4>
#include <tna.p4>  /* TOFINO1_ONLY */

@pa_auto_init_metadata

const bit<32> VLAN_TABLE_SIZE = 4096;
const bit<32> BD_FLOOD_TABLE_SIZE = VLAN_TABLE_SIZE * 4;
const bit<32> PORT_VLAN_TABLE_SIZE = 1024;
const bit<32> DOUBLE_TAG_TABLE_SIZE = 4096;
const bit<32> BD_TABLE_SIZE = 5120;
const bit<32> MAC_TABLE_SIZE = 32000;
const bit<32> IPV4_HOST_TABLE_SIZE = 65536;
const bit<32> IPV4_LPM_TABLE_SIZE = 16384;
const bit<32> IPV6_HOST_TABLE_SIZE = 65536;
const bit<32> IPV6_LPM_TABLE_SIZE = 1024;
const bit<32> ECMP_GROUP_TABLE_SIZE = 1024;
const bit<32> ECMP_SELECT_TABLE_SIZE = 16384;
const bit<32> NEXTHOP_TABLE_SIZE = 1 << 16;
const bit<32> IPV4_MULTICAST_STAR_G_TABLE_SIZE = 2048;
const bit<32> IPV4_MULTICAST_S_G_TABLE_SIZE = 4096;
const bit<32> IPV6_MULTICAST_STAR_G_TABLE_SIZE = 512;
const bit<32> IPV6_MULTICAST_S_G_TABLE_SIZE = 512;
const bit<32> RID_TABLE_SIZE = 4096;
const bit<32> TUNNEL_IPV4_REWRITE_SIZE = 65536;
const bit<32> TUNNEL_IPV6_REWRITE_SIZE = 8192;
const bit<32> NUM_TUNNELS = 10240;
const bit<32> OUTER_ECMP_GROUP_TABLE_SIZE = 1024;
const bit<32> OUTER_ECMP_SELECT_TABLE_SIZE = 16384;
const bit<32> IPV4_RACL_TABLE_SIZE = 512;
const bit<32> IPV6_RACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 8192;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 4096;
const bit<32> L3_SUBPORT_STATS_TABLE_SIZE = 1024;
const bit<32> MPLS_INNER_TAG_TABLE_SIZE = 1024;
const bit<32> MPLS_RMAC_TABLE_SIZE = 1024;
const bit<32> MPLS_TUNNEL_TABLE_SIZE = 10240;
const bit<32> MPLS_TUNNEL_REWRITE_TABLE_SIZE = 10240;
const bit<32> MPLS_VC_REWRITE_TABLE_SIZE = 10240;
const bit<32> MPLS_SR_TABLE_SIZE = 10240;
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 512;
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
    bit<24> vsid;
    bit<8>  flow_id;
}

header erspan_type2_h {
    bit<4>  version;
    bit<12> vlan;
    bit<6>  cos_en_t;
    bit<10> session_id;
    bit<12> reserved;
    bit<20> index;
}

header erspan_type3_h {
    bit<4>  version;
    bit<12> vlan;
    bit<6>  cos_bso_t;
    bit<10> session_id;
    bit<32> timestamp;
    bit<16> sgt;
    bit<1>  p;
    bit<5>  ft;
    bit<6>  hw_id;
    bit<1>  d;
    bit<2>  gra;
    bit<1>  o;
}

header erspan_platform_h {
    bit<6>  id;
    bit<58> info;
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

header dtel_drop_report_h {
    bit<7>  pad0;
    bit<9>  ingress_port;
    bit<7>  pad1;
    bit<9>  egress_port;
    bit<3>  pad2;
    bit<5>  queue_id;
    bit<8>  drop_reason;
    bit<16> reserved;
}

header dtel_switch_local_report_h {
    bit<7>  pad0;
    bit<9>  ingress_port;
    bit<7>  pad1;
    bit<9>  egress_port;
    bit<3>  pad2;
    bit<5>  queue_id;
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

struct dtel_report_metadata_0 {
    bit<16> ingress_port;
    bit<16> egress_port;
}

struct dtel_report_metadata_2 {
    bit<8>  queue_id;
    bit<24> queue_occupancy;
}

struct dtel_report_metadata_3 {
    bit<32> timestamp;
}

struct dtel_report_metadata_4 {
    bit<8>  queue_id;
    bit<8>  drop_reason;
    bit<16> reserved;
}

header cpu_h {
    bit<5>  egress_queue;
    bit<1>  tx_bypass;
    bit<1>  capture_ts;
    bit<1>  reserved;
    bit<16> ingress_port;
    bit<16> ingress_ifindex;
    bit<16> ingress_bd;
    bit<16> reason_code;
    bit<16> ether_type;
}

header timestamp_h {
    bit<48> timestamp;
}

header fabric_h {
    bit<3>  packet_type;
    bit<2>  header_version;
    bit<2>  packet_version;
    bit<1>  pad1;
    bit<3>  color;
    bit<5>  qos;
    bit<8>  dst_device;
    bit<16> dst_port_or_group;
}

header fabric_header_unicast_h {
    bool    routed;
    bool    outer_routed;
    bool    tunnel_terminate;
    bit<3>  ingress_tunnel_type;
    @padding
    bit<2>  padding;
    bit<16> nexthop_index;
}

header fabric_header_multicast_h {
    bool    routed;
    bool    outer_routed;
    bool    tunnel_terminate;
    bit<3>  ingress_tunnel_type;
    @padding
    bit<2>  padding;
    bit<16> ingress_ifindex;
    bit<16> ingress_bd;
    bit<16> mcast_grp_a;
    bit<16> mcast_grp_b;
    bit<16> ingress_rid;
    bit<16> l1_exclusion_id;
}

header fabric_header_mirror_h {
    bit<16> rewrite_index;
    bit<16> mirror_session_id;
}

header fabric_header_cpu_h {
    bit<5>  egress_queue;
    bit<1>  tx_bypass;
    bool    capture_tstamp_on_tx;
    bit<1>  reserved;
    bit<16> ingress_port;
    bit<16> ingress_ifindex;
    bit<16> ingress_bd;
    bit<16> reason_code;
}

header fabric_header_timestamp_h {
    bit<16> arrival_time_hi;
    bit<16> arrival_time;
}

header fabric_header_sflow_h {
    bit<16> sflow_session_id;
}

header fabric_header_bfd_event_h {
    bit<16> bfd_session_id;
    bit<16> bfd_event_id;
}

header fabric_payload_header_h {
    bit<16> ether_type;
}

typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;
typedef PortId_t switch_port_t;
const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;
typedef QueueId_t switch_qid_t;
typedef ReplicationId_t switch_rid_t;
const switch_rid_t SWITCH_RID_DEFAULT = 0xffff;
typedef bit<3> switch_ingress_cos_t;
typedef bit<3> switch_digest_type_t;
const switch_digest_type_t SWITCH_DIGEST_TYPE_INVALID = 0;
const switch_digest_type_t SWITCH_DIGEST_TYPE_MAC_LEARNING = 1;
typedef bit<16> switch_ifindex_t;
const switch_ifindex_t SWITCH_IFINDEX_FLOOD = 16w0xffff;
typedef bit<10> switch_port_lag_index_t;
typedef bit<16> switch_bd_t;
const switch_bd_t SWITCH_BD_DEFAULT_VRF = 4097;
typedef bit<14> switch_vrf_t;
typedef bit<16> switch_nexthop_t;
typedef bit<16> switch_outer_nexthop_t;
typedef bit<16> switch_xid_t;
typedef bit<9> switch_yid_t;
typedef bit<16> switch_port_lag_label_t;
typedef bit<16> switch_bd_label_t;
typedef bit<16> switch_if_label_t;
typedef bit<10> switch_rmac_group_t;
typedef bit<16> switch_smac_index_t;
typedef bit<16> switch_mtu_t;
typedef bit<12> switch_stats_index_t;
typedef bit<16> switch_cpu_reason_t;
const switch_cpu_reason_t CPU_REASON_CODE_SFLOW = 4;
const switch_cpu_reason_t SWITCH_CPU_REASON_PTP = 8;
const switch_cpu_reason_t CPU_REASON_CODE_BFD_EVENT = 264;
struct switch_cpu_port_value_set_t {
    bit<16> ether_type;
    bit<9>  port;
}

typedef bit<8> switch_drop_reason_t;
const switch_drop_reason_t SWITCH_DROP_REASON_UNKNOWN = 0;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_ZERO = 10;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_MULTICAST = 11;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_DST_MAC_ZERO = 12;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_ETHERNET_MISS = 13;
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
const switch_drop_reason_t SWITCH_DROP_REASON_METER = 72;
const switch_drop_reason_t SWITCH_DROP_REASON_WRED = 73;
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
const switch_drop_reason_t SWITCH_DROP_REASON_L3_IPV6_DISABLE = 100;
const switch_drop_reason_t SWITCH_DROP_REASON_INGRESS_PFC_WD_DROP = 101;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_PFC_WD_DROP = 102;
typedef bit<2> switch_port_type_t;
const switch_port_type_t SWITCH_PORT_TYPE_NORMAL = 0;
const switch_port_type_t SWITCH_PORT_TYPE_CPU = 1;
const switch_port_type_t SWITCH_PORT_TYPE_FABRIC = 2;
typedef bit<2> switch_ip_type_t;
const switch_ip_type_t SWITCH_IP_TYPE_NONE = 0;
const switch_ip_type_t SWITCH_IP_TYPE_IPV4 = 1;
const switch_ip_type_t SWITCH_IP_TYPE_IPV6 = 2;
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
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_POLICER = 16w0x20;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STORM_CONTROL = 16w0x40;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STP = 16w0x80;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SMAC = 16w0x100;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ALL = 16w0xffff;
typedef bit<8> switch_egress_bypass_t;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_REWRITE = 8w0x1;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_ACL = 8w0x2;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_SYSTEM_ACL = 8w0x4;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_QOS = 8w0x8;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_WRED = 8w0x10;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_STP = 8w0x20;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_MTU = 8w0x40;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_POLICER = 8w0x80;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_ALL = 8w0xff;
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
typedef bit<16> switch_l4_port_label_t;
typedef bit<2> switch_stp_state_t;
const switch_stp_state_t SWITCH_STP_STATE_FORWARDING = 0;
const switch_stp_state_t SWITCH_STP_STATE_BLOCKING = 1;
const switch_stp_state_t SWITCH_STP_STATE_LEARNING = 2;
typedef bit<10> switch_stp_group_t;
struct switch_stp_metadata_t {
    switch_stp_group_t group;
    switch_stp_state_t state_;
}

typedef bit<8> switch_copp_meter_id_t;
typedef bit<10> switch_policer_meter_index_t;
typedef bit<2> switch_qos_trust_mode_t;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_UNTRUSTED = 0;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_TRUST_DSCP = 1;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_TRUST_PCP = 2;
typedef bit<5> switch_qos_group_t;
typedef bit<8> switch_tc_t;
typedef bit<3> switch_cos_t;
struct switch_qos_metadata_t {
    switch_qos_trust_mode_t      trust_mode;
    switch_qos_group_t           group;
    switch_tc_t                  tc;
    switch_pkt_color_t           color;
    switch_pkt_color_t           acl_policer_color;
    switch_pkt_color_t           port_color;
    switch_pkt_color_t           flow_color;
    switch_pkt_color_t           storm_control_color;
    switch_policer_meter_index_t meter_index;
    switch_policer_meter_index_t ingress_flow_meter_index;
    switch_qid_t                 qid;
    switch_ingress_cos_t         icos;
    bit<19>                      qdepth;
}

typedef bit<1> switch_learning_mode_t;
const switch_learning_mode_t SWITCH_LEARNING_MODE_DISABLED = 0;
const switch_learning_mode_t SWITCH_LEARNING_MODE_LEARN = 1;
struct switch_learning_digest_t {
    switch_bd_t      bd;
    switch_ifindex_t ifindex;
    mac_addr_t       src_addr;
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
@flexible struct switch_multicast_metadata_t {
    switch_mgid_t                id;
    bit<2>                       mode;
    switch_multicast_rpf_group_t rpf_group;
    switch_rid_t                 replication_id;
    switch_xid_t                 l1xid;
}

typedef bit<2> switch_urpf_mode_t;
const switch_urpf_mode_t SWITCH_URPF_MODE_NONE = 0;
const switch_urpf_mode_t SWITCH_URPF_MODE_LOOSE = 1;
const switch_urpf_mode_t SWITCH_URPF_MODE_STRICT = 2;
typedef bit<8> switch_wred_index_t;
typedef bit<2> switch_ecn_codepoint_t;
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_NON_ECT = 0b0;
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_ECT0 = 0b10;
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_ECT1 = 0b1;
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_CE = 0b11;
typedef MirrorId_t switch_mirror_session_t;
const switch_mirror_session_t SWITCH_MIRROR_SESSION_CPU = 250;
typedef bit<8> switch_mirror_type_t;
struct switch_mirror_metadata_t {
    switch_pkt_src_t        src;
    switch_mirror_type_t    type;
    switch_mirror_session_t session_id;
}

header switch_port_mirror_metadata_h {
    switch_pkt_src_t        src;
    switch_mirror_type_t    type;
    bit<48>                 timestamp;
    bit<6>                  _pad;
    switch_mirror_session_t session_id;
}

header switch_cpu_mirror_metadata_h {
    switch_pkt_src_t     src;
    switch_mirror_type_t type;
    bit<7>               _pad;
    switch_port_t        port;
    switch_bd_t          bd;
    switch_ifindex_t     ifindex;
    switch_cpu_reason_t  reason_code;
}

enum switch_tunnel_mode_t {
    PIPE,
    UNIFORM
}

typedef bit<3> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NONE = 0;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VXLAN = 1;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPINIP = 2;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_MPLS = 3;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_MPLS_L2VPN = 4;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_MPLS_L3VPN = 5;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_MPLS_SR = 6;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_FABRIC = 7;
enum switch_tunnel_term_mode_t {
    P2P,
    P2MP
}

typedef bit<16> switch_tunnel_index_t;
typedef bit<24> switch_tunnel_id_t;
struct switch_tunnel_metadata_t {
    switch_tunnel_type_t  type;
    switch_tunnel_index_t index;
    switch_tunnel_id_t    id;
    switch_ifindex_t      ifindex;
    bit<16>               hash;
    bit<4>                egress_header_count;
    bit<4>                sr_tunnel_count;
    bit<8>                dmac_index;
    vlan_id_t             u_tag;
    vlan_id_t             p_tag;
    bool                  p_tag_exist;
    bool                  terminate;
}

typedef bit<4> switch_dtel_report_type_t;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_NONE = 0b0;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_DROP = 0b100;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_QUEUE = 0b10;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_FLOW = 0b1;
const switch_dtel_report_type_t SWITCH_DTEL_SUPPRESS_REPORT = 0b1000;
struct switch_dtel_metadata_t {
    switch_dtel_report_type_t report_type;
    bit<32>                   latency;
    switch_mirror_session_t   session_id;
    bit<32>                   hash;
}

header switch_dtel_switch_local_mirror_metadata_h {
    switch_pkt_src_t          src;
    switch_mirror_type_t      type;
    bit<48>                   timestamp;
    bit<6>                    _pad;
    switch_mirror_session_t   session_id;
    bit<32>                   hash;
    bit<4>                    _pad1;
    switch_dtel_report_type_t report_type;
    bit<7>                    _pad2;
    bit<9>                    ingress_port;
    bit<7>                    _pad3;
    bit<9>                    egress_port;
    bit<3>                    _pad4;
    switch_qid_t              qid;
    bit<5>                    _pad5;
    bit<19>                   qdepth;
    bit<32>                   egress_timestamp;
}

header switch_dtel_drop_mirror_metadata_h {
    switch_pkt_src_t          src;
    switch_mirror_type_t      type;
    bit<48>                   timestamp;
    bit<6>                    _pad;
    switch_mirror_session_t   session_id;
    bit<32>                   hash;
    bit<4>                    _pad1;
    switch_dtel_report_type_t report_type;
    bit<7>                    _pad2;
    bit<9>                    ingress_port;
    bit<7>                    _pad3;
    bit<9>                    egress_port;
    bit<3>                    _pad4;
    switch_qid_t              qid;
    switch_drop_reason_t      drop_reason;
}

@flexible struct switch_bridged_metadata_dtel_extension_t {
    switch_dtel_report_type_t report_type;
    switch_mirror_session_t   session_id;
    bit<32>                   hash;
    bit<9>                    egress_port;
}

struct fabric_metadata_t {
    bit<3>  packetType;
    bit<1>  fabric_header_present;
    bit<16> reason_code;
    bit<8>  dst_device;
    bit<16> dst_port;
}

@pa_container_size("ingress", "ig_md.checks.same_if", 16) @pa_container_size("ingress", "ig_md.checks.same_bd", 16) struct switch_ingress_flags_t {
    bool ipv4_checksum_err;
    bool inner_ipv4_checksum_err;
    bool link_local;
    bool routed;
    bool acl_deny;
    bool racl_deny;
    bool port_vlan_miss;
    bool rmac_hit;
    bool dmac_miss;
    bool myip;
    bool glean;
    bool storm_control_drop;
    bool acl_policer_drop;
    bool port_policer_drop;
    bool flood_to_multicast_routers;
    bool peer_link;
    bool capture_ts;
    bool mac_pkt_class;
    bool pfc_wd_drop;
}

struct switch_egress_flags_t {
    bool routed;
    bool acl_deny;
    bool mlag_member;
    bool peer_link;
    bool capture_ts;
    bool wred_drop;
    bool port_policer_drop;
    bool pfc_wd_drop;
}

struct switch_ingress_checks_t {
    switch_bd_t      same_bd;
    switch_ifindex_t same_if;
    bool             mrpf;
    bool             urpf;
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
    switch_pkt_type_t pkt_type;
    mac_addr_t        mac_src_addr;
    mac_addr_t        mac_dst_addr;
    bit<16>           mac_type;
    bit<3>            pcp;
    bit<16>           arp_opcode;
    switch_ip_type_t  ip_type;
    bit<8>            ip_proto;
    bit<8>            ip_ttl;
    bit<8>            ip_tos;
    bit<2>            ip_frag;
    bit<128>          ip_src_addr;
    bit<128>          ip_dst_addr;
    bit<8>            tcp_flags;
    bit<16>           l4_src_port;
    bit<16>           l4_dst_port;
}

@flexible struct switch_bridged_metadata_t {
    switch_port_t       ingress_port;
    switch_ifindex_t    ingress_ifindex;
    switch_bd_t         ingress_bd;
    switch_nexthop_t    nexthop;
    switch_pkt_type_t   pkt_type;
    bool                routed;
    switch_cpu_reason_t cpu_reason;
    bit<48>             timestamp;
    switch_tc_t         tc;
    switch_qid_t        qid;
    switch_pkt_color_t  color;
}

@flexible struct switch_bridged_metadata_acl_extension_t {
    bit<16>                l4_src_port;
    bit<16>                l4_dst_port;
    bit<8>                 tcp_flags;
    switch_l4_port_label_t l4_port_label;
}

@flexible struct switch_bridged_metadata_tunnel_extension_t {
    switch_tunnel_index_t  index;
    switch_outer_nexthop_t outer_nexthop;
    bit<16>                hash;
    switch_vrf_t           vrf;
    bool                   terminate;
    switch_tunnel_type_t   type;
}

typedef bit<8> switch_bridge_type_t;
header switch_bridged_metadata_h {
    switch_pkt_src_t                           src;
    switch_bridge_type_t                       type;
    switch_bridged_metadata_t                  base;
    switch_bridged_metadata_acl_extension_t    acl;
    switch_bridged_metadata_tunnel_extension_t tunnel;
    switch_multicast_metadata_t                multicast;
}

struct switch_port_metadata_t {
    switch_port_lag_index_t port_lag_index;
    switch_port_lag_label_t port_lag_label;
    switch_ifindex_t        ifindex;
}

@pa_container_size("ingress", "ig_md.lkp.l4_src_port", 8) @pa_container_size("ingress", "ig_md.l4_port_label", 8) @pa_container_size("ingress", "ig_md.mirror.src", 8) @pa_container_size("ingress", "ig_md.mirror.type", 8) @pa_alias("ingress", "ig_md.egress_port", "ig_intr_md_for_tm.ucast_egress_port") @pa_alias("ingress", "ig_md.multicast.id", "ig_intr_md_for_tm.mcast_grp_b") @pa_alias("ingress", "ig_md.qos.qid", "ig_intr_md_for_tm.qid") @pa_alias("ingress", "ig_md.qos.icos", "ig_intr_md_for_tm.ingress_cos") @pa_container_size("egress", "hdr.dtel_drop_report.drop_reason", 8) @pa_alias("ingress", "ig_intr_md_for_dprsr.mirror_type", "ig_md.mirror.type") struct switch_ingress_metadata_t {
    switch_ifindex_t            ifindex;
    switch_port_t               port;
    switch_port_t               egress_port;
    switch_port_lag_index_t     port_lag_index;
    switch_port_type_t          port_type;
    switch_ifindex_t            egress_ifindex;
    switch_port_lag_index_t     egress_port_lag_index;
    switch_bd_t                 bd;
    switch_vrf_t                vrf;
    switch_nexthop_t            nexthop;
    switch_outer_nexthop_t      outer_nexthop;
    switch_nexthop_t            acl_nexthop;
    bool                        acl_redirect;
    bit<48>                     timestamp;
    bit<32>                     hash;
    switch_ingress_flags_t      flags;
    switch_ingress_checks_t     checks;
    switch_ingress_bypass_t     bypass;
    switch_ip_metadata_t        ipv4;
    switch_ip_metadata_t        ipv6;
    switch_port_lag_label_t     port_lag_label;
    switch_bd_label_t           bd_label;
    switch_if_label_t           if_label;
    switch_l4_port_label_t      l4_port_label;
    switch_drop_reason_t        drop_reason;
    switch_cpu_reason_t         cpu_reason;
    switch_rmac_group_t         rmac_group;
    switch_lookup_fields_t      lkp;
    switch_multicast_metadata_t multicast;
    switch_stp_metadata_t       stp;
    switch_qos_metadata_t       qos;
    switch_tunnel_metadata_t    tunnel;
    switch_learning_metadata_t  learning;
    switch_mirror_metadata_t    mirror;
    switch_dtel_metadata_t      dtel;
    fabric_metadata_t           fabric_metadata;
}

@pa_container_size("egress", "eg_md.mirror.src", 8) @pa_container_size("egress", "eg_md.mirror.type", 8) struct switch_egress_metadata_t {
    switch_pkt_src_t            pkt_src;
    switch_pkt_length_t         pkt_length;
    switch_pkt_type_t           pkt_type;
    switch_port_lag_index_t     port_lag_index;
    switch_port_type_t          port_type;
    switch_port_t               port;
    switch_port_t               ingress_port;
    switch_ifindex_t            ingress_ifindex;
    switch_bd_t                 bd;
    switch_vrf_t                vrf;
    switch_nexthop_t            nexthop;
    switch_outer_nexthop_t      outer_nexthop;
    bit<32>                     timestamp;
    bit<48>                     ingress_timestamp;
    switch_egress_flags_t       flags;
    switch_egress_checks_t      checks;
    switch_egress_bypass_t      bypass;
    switch_port_lag_label_t     port_lag_label;
    switch_bd_label_t           bd_label;
    switch_if_label_t           if_label;
    switch_l4_port_label_t      l4_port_label;
    switch_lookup_fields_t      lkp;
    switch_multicast_metadata_t multicast;
    switch_qos_metadata_t       qos;
    switch_tunnel_metadata_t    tunnel;
    switch_mirror_metadata_t    mirror;
    switch_dtel_metadata_t      dtel;
    switch_cpu_reason_t         cpu_reason;
    switch_drop_reason_t        drop_reason;
    bit<4>                      vc_index;
    fabric_metadata_t           fabric_metadata;
}

struct switch_mirror_metadata_h {
    switch_port_mirror_metadata_h              port;
    switch_cpu_mirror_metadata_h               cpu;
    switch_dtel_drop_mirror_metadata_h         dtel_drop;
    switch_dtel_switch_local_mirror_metadata_h dtel_switch_local;
}

struct switch_header_t {
    switch_bridged_metadata_h  bridged_md;
    ethernet_h                 ethernet;
    fabric_h                   fabric;
    fabric_header_unicast_h    fabric_unicast_header;
    fabric_header_multicast_h  fabric_multicast_header;
    fabric_header_mirror_h     fabric_mirror_header;
    fabric_header_cpu_h        fabric_cpu_header;
    fabric_header_timestamp_h  fabric_ts_header;
    fabric_header_sflow_h      fabric_sflow_header;
    fabric_header_bfd_event_h  fabric_bfd_event_header;
    fabric_payload_header_h    fabric_payload_header;
    cpu_h                      cpu;
    timestamp_h                timestamp;
    vlan_tag_h[2]              vlan_tag;
    mpls_h[10]                 mpls;
    ipv4_h                     ipv4;
    ipv4_option_h              ipv4_option;
    ipv6_h                     ipv6;
    arp_h                      arp;
    udp_h                      udp;
    icmp_h                     icmp;
    igmp_h                     igmp;
    tcp_h                      tcp;
    dtel_report_v05_h          dtel;
    dtel_switch_local_report_h dtel_switch_local_report;
    dtel_drop_report_h         dtel_drop_report;
    rocev2_bth_h               rocev2_bth;
    vxlan_h                    vxlan;
    gre_h                      gre;
    nvgre_h                    nvgre;
    geneve_h                   geneve;
    erspan_type2_h             erspan_type2;
    erspan_type3_h             erspan_type3;
    erspan_platform_h          erspan_platform;
    ethernet_h                 inner_ethernet;
    vlan_tag_h[2]              inner_vlan_tag;
    ipv4_h                     inner_ipv4;
    ipv6_h                     inner_ipv6;
    udp_h                      inner_udp;
    tcp_h                      inner_tcp;
    icmp_h                     inner_icmp;
}

Hash<bit<32>>(HashAlgorithm_t.CRC32) ip_hash;

Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;

action compute_ip_hash(in switch_lookup_fields_t lkp, out bit<32> hash) {
    hash = ip_hash.get({ lkp.ip_src_addr, lkp.ip_dst_addr, lkp.ip_proto, lkp.l4_dst_port, lkp.l4_src_port });
}
action compute_non_ip_hash(in switch_lookup_fields_t lkp, out bit<32> hash) {
    hash = non_ip_hash.get({ lkp.mac_type, lkp.mac_src_addr, lkp.mac_dst_addr });
}
action add_bridged_md(inout switch_bridged_metadata_h bridged_md, in switch_ingress_metadata_t ig_md) {
    bridged_md.setValid();
    bridged_md.src = SWITCH_PKT_SRC_BRIDGED;
    bridged_md.base = { ig_md.port, ig_md.ifindex, ig_md.bd, ig_md.nexthop, ig_md.lkp.pkt_type, ig_md.flags.routed, ig_md.cpu_reason, ig_md.timestamp, ig_md.qos.tc, ig_md.qos.qid, ig_md.qos.color };
    bridged_md.acl = { ig_md.lkp.l4_src_port, ig_md.lkp.l4_dst_port, ig_md.lkp.tcp_flags, ig_md.l4_port_label };
    bridged_md.tunnel = { ig_md.tunnel.index, ig_md.outer_nexthop, ig_md.hash[15:0], ig_md.vrf, ig_md.tunnel.terminate, ig_md.tunnel.type };
    bridged_md.multicast.id = ig_md.multicast.id;
    bridged_md.multicast.id = ig_md.multicast.replication_id;
    bridged_md.multicast.id = ig_md.multicast.l1xid;
}
action set_ig_intr_md(in switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    ig_intr_md_for_tm.mcast_grp_b = ig_md.multicast.id;
    ig_intr_md_for_tm.level2_mcast_hash = ig_md.hash[28:16];
    ig_intr_md_for_tm.qid = ig_md.qos.qid;
    ig_intr_md_for_tm.ingress_cos = ig_md.qos.icos;
}
action set_eg_intr_md(in switch_egress_metadata_t eg_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    eg_intr_md_for_dprsr.mirror_type = (bit<3>)eg_md.mirror.type;
}
control IngressFabric(inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm, inout switch_header_t hdr) {
    action terminate_cpu_packet() {
        ig_intr_md_for_tm.ucast_egress_port = (bit<9>)hdr.fabric.dst_port_or_group;
        ig_md.bypass = hdr.fabric_cpu_header.reason_code;
        hdr.ethernet.ether_type = hdr.fabric_payload_header.ether_type;
        hdr.fabric.setInvalid();
        hdr.fabric_cpu_header.setInvalid();
        hdr.fabric_payload_header.setInvalid();
    }
    action terminate_fabric_unicast_packet() {
        ig_intr_md_for_tm.ucast_egress_port = (bit<9>)hdr.fabric.dst_port_or_group;
        ig_md.tunnel.terminate = hdr.fabric_unicast_header.tunnel_terminate;
        ig_md.tunnel.type = hdr.fabric_unicast_header.ingress_tunnel_type;
        ig_md.nexthop = hdr.fabric_unicast_header.nexthop_index;
        ig_md.flags.routed = hdr.fabric_unicast_header.routed;
        hdr.ethernet.ether_type = hdr.fabric_payload_header.ether_type;
        hdr.fabric.setInvalid();
        hdr.fabric_unicast_header.setInvalid();
        hdr.fabric_payload_header.setInvalid();
    }
    action switch_fabric_unicast_packet() {
        ig_md.fabric_metadata.fabric_header_present = 1;
        ig_md.fabric_metadata.dst_device = hdr.fabric.dst_device;
        ig_md.fabric_metadata.dst_port = hdr.fabric.dst_port_or_group;
    }
    action terminate_fabric_multicast_packet() {
        ig_md.tunnel.terminate = hdr.fabric_multicast_header.tunnel_terminate;
        ig_md.tunnel.type = hdr.fabric_multicast_header.ingress_tunnel_type;
        ig_md.nexthop = 0;
        ig_md.flags.routed = hdr.fabric_multicast_header.routed;
        ig_intr_md_for_tm.mcast_grp_a = hdr.fabric_multicast_header.mcast_grp_a;
        ig_intr_md_for_tm.mcast_grp_b = hdr.fabric_multicast_header.mcast_grp_b;
        ig_intr_md_for_tm.rid = hdr.fabric_multicast_header.ingress_rid;
        ig_intr_md_for_tm.level1_exclusion_id = hdr.fabric_multicast_header.l1_exclusion_id;
        hdr.ethernet.ether_type = hdr.fabric_payload_header.ether_type;
        hdr.fabric.setInvalid();
        hdr.fabric_multicast_header.setInvalid();
        hdr.fabric_payload_header.setInvalid();
    }
    action switch_fabric_multicast_packet() {
        ig_md.fabric_metadata.fabric_header_present = 1;
        ig_intr_md_for_tm.mcast_grp_a = 0;
        ig_intr_md_for_tm.mcast_grp_b = hdr.fabric.dst_port_or_group;
        ig_intr_md_for_tm.rid = 0;
        ig_intr_md_for_tm.level1_exclusion_id = 0;
    }
    table fabric_ingress_dst_lkp {
        key = {
            hdr.fabric.dst_device: exact;
        }
        actions = {
            terminate_cpu_packet;
            switch_fabric_unicast_packet;
            terminate_fabric_unicast_packet;
            switch_fabric_multicast_packet;
            terminate_fabric_multicast_packet;
        }
    }
    action set_ingress_ifindex_properties(switch_yid_t l2xid) {
        ig_intr_md_for_tm.level2_exclusion_id = l2xid;
    }
    table fabric_ingress_src_lkp {
        key = {
            hdr.fabric_multicast_header.ingress_ifindex: exact;
        }
        actions = {
            set_ingress_ifindex_properties;
        }
        size = 1024;
    }
    action non_ip_over_fabric() {
        ig_md.lkp.mac_src_addr = hdr.ethernet.src_addr;
        ig_md.lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        ig_md.lkp.mac_type = hdr.ethernet.ether_type;
    }
    action ipv4_over_fabric() {
        ig_md.lkp.mac_src_addr = hdr.ethernet.src_addr;
        ig_md.lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        ig_md.lkp.ip_src_addr = (bit<128>)hdr.ipv4.src_addr;
        ig_md.lkp.ip_dst_addr = (bit<128>)hdr.ipv4.dst_addr;
        ig_md.lkp.ip_proto = hdr.ipv4.protocol;
    }
    action ipv6_over_fabric() {
        ig_md.lkp.mac_src_addr = hdr.ethernet.src_addr;
        ig_md.lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        ig_md.lkp.ip_src_addr = (bit<128>)hdr.ipv4.src_addr;
        ig_md.lkp.ip_dst_addr = (bit<128>)hdr.ipv4.dst_addr;
        ig_md.lkp.ip_proto = hdr.ipv4.protocol;
    }
    table native_packet_over_fabric {
        key = {
            hdr.ipv4.isValid(): exact;
            hdr.ipv6.isValid(): exact;
        }
        actions = {
            non_ip_over_fabric;
            ipv4_over_fabric;
            ipv6_over_fabric;
        }
        size = 1024;
    }
    action terminate_fabric_mirror_packet(PortId_t egress_port) {
        ig_intr_md_for_tm.ucast_egress_port = egress_port;
        hdr.ethernet.ether_type = hdr.fabric_payload_header.ether_type;
        hdr.fabric.setInvalid();
        hdr.fabric_mirror_header.setInvalid();
        hdr.fabric_payload_header.setInvalid();
    }
    table fabric_mirror_dst_lkp {
        key = {
            hdr.fabric_mirror_header.rewrite_index    : exact;
            hdr.fabric_mirror_header.mirror_session_id: exact;
        }
        actions = {
            terminate_fabric_mirror_packet;
        }
    }
    apply {
        if (ig_md.port_type != 0) {
            if (hdr.fabric.packet_type != 3) {
                fabric_ingress_dst_lkp.apply();
                if (ig_md.port_type == 1) {
                    if (hdr.fabric_multicast_header.isValid()) {
                        fabric_ingress_src_lkp.apply();
                    }
                    if (ig_md.tunnel.terminate == false) {
                        native_packet_over_fabric.apply();
                    }
                }
            } else {
                fabric_mirror_dst_lkp.apply();
            }
        }
    }
}

control FabricLag(inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(1024, selector_hash, SelectorMode_t.FAIR) fabric_lag_selector;
    action set_fabric_lag_port(PortId_t port) {
        ig_intr_md_for_tm.ucast_egress_port = port;
    }
    action set_fabric_multicast(switch_mgid_t fabric_mgid) {
        ig_md.multicast.id = ig_intr_md_for_tm.mcast_grp_b;
        ig_md.multicast.replication_id = ig_intr_md_for_tm.rid;
        ig_md.multicast.l1xid = ig_intr_md_for_tm.level1_exclusion_id;
    }
    action fabric_lag_miss() {
    }
    table fabric_lag {
        key = {
            ig_md.fabric_metadata.dst_device: exact;
            ig_md.lkp.ip_src_addr           : selector;
            ig_md.lkp.ip_dst_addr           : selector;
            ig_md.lkp.ip_proto              : selector;
            ig_md.lkp.l4_src_port           : selector;
            ig_md.lkp.l4_dst_port           : selector;
        }
        actions = {
            fabric_lag_miss;
            set_fabric_lag_port;
            set_fabric_multicast;
        }
        const default_action = fabric_lag_miss;
        size = 1024;
        implementation = fabric_lag_selector;
    }
    apply {
        fabric_lag.apply();
    }
}

control FabricRewrite(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md) {
    action add_fabric_header(bit<3> packet_type, bit<8> dst_device, bit<16> dst_port_or_grp) {
        hdr.fabric.setValid();
        hdr.fabric.header_version = 0;
        hdr.fabric.packet_version = 0;
        hdr.fabric.pad1 = 0;
        hdr.fabric.packet_type = packet_type;
        hdr.fabric.dst_device = dst_device;
        hdr.fabric.dst_port_or_group = dst_port_or_grp;
    }
    action add_fabric_unicast_header() {
        hdr.fabric_unicast_header.setValid();
        hdr.fabric_unicast_header.routed = eg_md.flags.routed;
        hdr.fabric_unicast_header.outer_routed = eg_md.flags.routed;
        hdr.fabric_unicast_header.tunnel_terminate = eg_md.tunnel.terminate;
        hdr.fabric_unicast_header.ingress_tunnel_type = eg_md.tunnel.type;
        hdr.fabric_unicast_header.nexthop_index = eg_md.nexthop;
    }
    action add_fabric_multicast_header() {
        hdr.fabric_multicast_header.setValid();
        hdr.fabric_multicast_header.routed = eg_md.flags.routed;
        hdr.fabric_multicast_header.outer_routed = eg_md.flags.routed;
        hdr.fabric_multicast_header.tunnel_terminate = eg_md.tunnel.terminate;
        hdr.fabric_multicast_header.ingress_tunnel_type = eg_md.tunnel.type;
        hdr.fabric_multicast_header.ingress_ifindex = eg_md.ingress_ifindex;
        hdr.fabric_multicast_header.ingress_bd = eg_md.bd;
        hdr.fabric_multicast_header.mcast_grp_a = eg_md.multicast.id;
        hdr.fabric_multicast_header.mcast_grp_b = eg_md.multicast.id;
        hdr.fabric_multicast_header.ingress_rid = eg_md.multicast.replication_id;
        hdr.fabric_multicast_header.l1_exclusion_id = eg_md.multicast.l1xid;
    }
    action add_fabric_mirror_header(bit<16> mirror_session_id) {
        hdr.fabric_mirror_header.setValid();
        hdr.fabric_mirror_header.rewrite_index = 0;
        hdr.fabric_mirror_header.mirror_session_id = mirror_session_id;
    }
    action add_fabric_cpu_header() {
        hdr.fabric_cpu_header.setValid();
        hdr.fabric_cpu_header.ingress_port = (bit<16>)eg_md.ingress_port;
        hdr.fabric_cpu_header.ingress_ifindex = eg_md.ingress_ifindex;
        hdr.fabric_cpu_header.ingress_bd = eg_md.bd;
        hdr.fabric_cpu_header.reason_code = eg_md.fabric_metadata.reason_code;
    }
    action add_fabric_payload_header() {
        hdr.fabric_payload_header.setValid();
        hdr.fabric_payload_header.ether_type = hdr.ethernet.ether_type;
    }
    action cpu_rx_rewrite() {
        add_fabric_header(5, 0, 0);
        add_fabric_cpu_header();
        add_fabric_payload_header();
        hdr.ethernet.ether_type = 0x9000;
    }
    action fabric_rewrite(switch_tunnel_index_t tunnel_index) {
        eg_md.tunnel.index = tunnel_index;
    }
    action fabric_unicast_rewrite() {
        add_fabric_header(1, eg_md.fabric_metadata.dst_device, eg_md.fabric_metadata.dst_port);
        add_fabric_unicast_header();
        add_fabric_payload_header();
        hdr.ethernet.ether_type = 0x9000;
    }
    action fabric_multicast_rewrite(bit<16> fabric_mgid) {
        add_fabric_header(2, 127, fabric_mgid);
        add_fabric_multicast_header();
        add_fabric_payload_header();
        hdr.ethernet.ether_type = 0x9000;
    }
    action fabric_mirror_rewrite(bit<16> mirror_session_id) {
        add_fabric_header(3, 0, 0);
        add_fabric_mirror_header(mirror_session_id);
        add_fabric_payload_header();
        hdr.ethernet.ether_type = 0x9000;
    }
    table fabric_rewrite_tbl {
        key = {
            eg_md.fabric_metadata.dst_device: exact;
            eg_md.tunnel.type               : exact;
        }
        actions = {
            fabric_unicast_rewrite;
            fabric_multicast_rewrite;
        }
        size = 1024;
    }
    apply {
        fabric_rewrite_tbl.apply();
    }
}

action ingress_acl_deny(inout switch_ingress_metadata_t ig_md, inout switch_stats_index_t index, switch_stats_index_t stats_index) {
    index = stats_index;
    ig_md.flags.acl_deny = true;
}
action ingress_acl_permit(inout switch_ingress_metadata_t ig_md, inout switch_stats_index_t index, switch_stats_index_t stats_index) {
    index = stats_index;
    ig_md.flags.acl_deny = false;
}
action ingress_acl_redirect(inout switch_ingress_metadata_t ig_md, inout switch_stats_index_t index, inout switch_nexthop_t nexthop, switch_nexthop_t nexthop_index, switch_stats_index_t stats_index) {
    index = stats_index;
    ig_md.flags.acl_deny = false;
}
action ingress_acl_mirror(inout switch_ingress_metadata_t ig_md, inout switch_stats_index_t index, switch_stats_index_t stats_index, switch_mirror_session_t session_id) {
}
action egress_acl_deny(inout switch_egress_metadata_t eg_md, inout switch_stats_index_t index, switch_stats_index_t stats_index) {
    index = stats_index;
    eg_md.flags.acl_deny = true;
}
action egress_acl_permit(inout switch_egress_metadata_t eg_md, inout switch_stats_index_t index, switch_stats_index_t stats_index) {
    index = stats_index;
    eg_md.flags.acl_deny = false;
}
action egress_acl_mirror(inout switch_egress_metadata_t eg_md, inout switch_stats_index_t index, switch_stats_index_t stats_index, switch_mirror_session_t session_id) {
}
control IngressIpAcl(in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md, out switch_stats_index_t index, out switch_nexthop_t nexthop)(switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.mac_type        : ternary;
            lkp.ip_src_addr     : ternary;
            lkp.ip_dst_addr     : ternary;
            lkp.ip_proto        : ternary;
            lkp.ip_tos          : ternary;
            lkp.l4_src_port     : ternary;
            lkp.l4_dst_port     : ternary;
            lkp.ip_ttl          : ternary;
            lkp.tcp_flags       : ternary;
            ig_md.port_lag_label: ternary;
            ig_md.bd_label      : ternary;
            ig_md.l4_port_label : ternary;
        }
        actions = {
            NoAction;
            ingress_acl_deny(ig_md, index);
            ingress_acl_permit(ig_md, index);
            ingress_acl_redirect(ig_md, index, nexthop);
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        acl.apply();
    }
}

control IngressIpv4Acl(in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md, out switch_stats_index_t index, out switch_nexthop_t nexthop)(switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.ip_src_addr[31:0]: ternary;
            lkp.ip_dst_addr[31:0]: ternary;
            lkp.ip_proto         : ternary;
            lkp.ip_tos           : ternary;
            lkp.l4_src_port      : ternary;
            lkp.l4_dst_port      : ternary;
            lkp.ip_ttl           : ternary;
            lkp.ip_frag          : ternary;
            lkp.tcp_flags        : ternary;
            lkp.mac_type         : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label       : ternary;
            ig_md.l4_port_label  : ternary;
        }
        actions = {
            NoAction;
            ingress_acl_deny(ig_md, index);
            ingress_acl_permit(ig_md, index);
            ingress_acl_redirect(ig_md, index, nexthop);
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        acl.apply();
    }
}

control IngressIpv6Acl(in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md, out switch_stats_index_t index, out switch_nexthop_t nexthop)(switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.ip_src_addr     : ternary;
            lkp.ip_dst_addr     : ternary;
            lkp.ip_proto        : ternary;
            lkp.ip_tos          : ternary;
            lkp.l4_src_port     : ternary;
            lkp.l4_dst_port     : ternary;
            lkp.ip_ttl          : ternary;
            lkp.tcp_flags       : ternary;
            ig_md.port_lag_label: ternary;
            ig_md.bd_label      : ternary;
            ig_md.l4_port_label : ternary;
        }
        actions = {
            NoAction;
            ingress_acl_deny(ig_md, index);
            ingress_acl_permit(ig_md, index);
            ingress_acl_redirect(ig_md, index, nexthop);
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        acl.apply();
    }
}

control IngressMacAcl(in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md, out switch_stats_index_t index, out switch_nexthop_t nexthop)(switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.mac_src_addr    : ternary;
            lkp.mac_dst_addr    : ternary;
            lkp.mac_type        : ternary;
            ig_md.port_lag_label: ternary;
            ig_md.bd_label      : ternary;
        }
        actions = {
            NoAction;
            ingress_acl_deny(ig_md, index);
            ingress_acl_permit(ig_md, index);
            ingress_acl_redirect(ig_md, index, nexthop);
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        acl.apply();
    }
}

control LOU(in bit<16> src_port, in bit<16> dst_port, inout bit<8> tcp_flags, out switch_l4_port_label_t port_label) {
    const switch_uint32_t table_size = 16 / 2;
    action set_src_port_label(bit<8> label) {
        port_label[7:0] = label;
    }
    action set_dst_port_label(bit<8> label) {
        port_label[15:8] = label;
    }
    @entries_with_ranges(table_size) table l4_dst_port {
        key = {
            dst_port: range;
        }
        actions = {
            NoAction;
            set_dst_port_label;
        }
        const default_action = NoAction;
        size = table_size;
    }
    @entries_with_ranges(table_size) table l4_src_port {
        key = {
            src_port: range;
        }
        actions = {
            NoAction;
            set_src_port_label;
        }
        const default_action = NoAction;
        size = table_size;
    }
    action set_tcp_flags(bit<8> flags) {
        tcp_flags = flags;
    }
    table tcp {
        key = {
            tcp_flags: exact;
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

control IngressAcl(inout switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md)(switch_uint32_t ipv4_table_size=512, switch_uint32_t ipv6_table_size=512, switch_uint32_t mac_table_size=512, bool mac_acl_enable=false, bool mac_packet_class_enable=false) {
    IngressIpv4Acl(ipv4_table_size) ipv4_acl;
    IngressIpv6Acl(ipv6_table_size) ipv6_acl;
    IngressMacAcl(mac_table_size) mac_acl;
    LOU() lou;
    Counter<bit<16>, switch_stats_index_t>(ipv4_table_size + ipv6_table_size + mac_table_size, CounterType_t.PACKETS_AND_BYTES) stats;
    switch_stats_index_t stats_index;
    switch_nexthop_t nexthop;
    apply {
        ig_md.flags.acl_deny = false;
        stats_index = 0;
        nexthop = 0;
        lou.apply(lkp.l4_src_port, lkp.l4_dst_port, lkp.tcp_flags, ig_md.l4_port_label);
        if (mac_acl_enable && !(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            if (lkp.ip_type == SWITCH_IP_TYPE_NONE || mac_packet_class_enable && ig_md.flags.mac_pkt_class) {
                mac_acl.apply(lkp, ig_md, stats_index, nexthop);
            }
        }
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0) && (!mac_packet_class_enable || !ig_md.flags.mac_pkt_class)) {
            if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
                ipv6_acl.apply(lkp, ig_md, stats_index, nexthop);
            } else if (!mac_acl_enable || lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                ipv4_acl.apply(lkp, ig_md, stats_index, nexthop);
            }
        }
        if (nexthop != 0) {
            ig_md.nexthop = nexthop;
        }
        stats.count(stats_index);
    }
}

action racl_deny(inout switch_ingress_metadata_t ig_md, inout switch_stats_index_t index, switch_stats_index_t stats_index) {
    index = stats_index;
    ig_md.flags.racl_deny = true;
}
action racl_permit(inout switch_ingress_metadata_t ig_md, inout switch_stats_index_t index, switch_stats_index_t stats_index) {
    index = stats_index;
    ig_md.flags.racl_deny = false;
}
action racl_redirect(inout switch_stats_index_t index, inout switch_nexthop_t nexthop, switch_stats_index_t stats_index, switch_nexthop_t nexthop_index) {
    index = stats_index;
    nexthop = nexthop_index;
}
control Ipv4Racl(in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md, out switch_stats_index_t index, out switch_nexthop_t nexthop)(switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.ip_src_addr[31:0]: ternary;
            lkp.ip_dst_addr[31:0]: ternary;
            lkp.ip_proto         : ternary;
            lkp.ip_tos           : ternary;
            lkp.l4_src_port      : ternary;
            lkp.l4_dst_port      : ternary;
            lkp.ip_ttl           : ternary;
            lkp.ip_frag          : ternary;
            lkp.tcp_flags        : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label       : ternary;
            ig_md.l4_port_label  : ternary;
        }
        actions = {
            NoAction;
            racl_deny(ig_md, index);
            racl_permit(ig_md, index);
            racl_redirect(index, nexthop);
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        acl.apply();
    }
}

control Ipv6Racl(in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md, out switch_stats_index_t index, out switch_nexthop_t nexthop)(switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.ip_src_addr     : ternary;
            lkp.ip_dst_addr     : ternary;
            lkp.ip_proto        : ternary;
            lkp.ip_tos          : ternary;
            lkp.l4_src_port     : ternary;
            lkp.l4_dst_port     : ternary;
            lkp.ip_ttl          : ternary;
            lkp.tcp_flags       : ternary;
            ig_md.port_lag_label: ternary;
            ig_md.bd_label      : ternary;
            ig_md.l4_port_label : ternary;
        }
        actions = {
            NoAction;
            racl_deny(ig_md, index);
            racl_permit(ig_md, index);
            racl_redirect(index, nexthop);
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        acl.apply();
    }
}

control RouterAcl(in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md)(switch_uint32_t ipv4_table_size=512, switch_uint32_t ipv6_table_size=512, bool stats_enable=false) {
    switch_stats_index_t stats_index;
    switch_nexthop_t nexthop;
    Counter<bit<16>, switch_stats_index_t>(ipv4_table_size + ipv6_table_size, CounterType_t.PACKETS_AND_BYTES) stats;
    Ipv4Racl(ipv4_table_size) ipv4_racl;
    Ipv6Racl(ipv6_table_size) ipv6_racl;
    apply {
        stats_index = 0;
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                ipv4_racl.apply(lkp, ig_md, stats_index, nexthop);
            } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
                ipv6_racl.apply(lkp, ig_md, stats_index, nexthop);
            }
        }
        if (stats_enable && ig_md.flags.routed) {
            stats.count(stats_index);
        }
    }
}

control Ipv4MirrorAcl(in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md, out switch_stats_index_t index)(switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.ip_src_addr[31:0]: ternary;
            lkp.ip_dst_addr[31:0]: ternary;
            lkp.ip_proto         : ternary;
            lkp.ip_tos           : ternary;
            lkp.l4_src_port      : ternary;
            lkp.l4_dst_port      : ternary;
            lkp.ip_ttl           : ternary;
            lkp.ip_frag          : ternary;
            lkp.tcp_flags        : ternary;
            lkp.mac_type         : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.l4_port_label  : ternary;
        }
        actions = {
            NoAction;
            ingress_acl_mirror(ig_md, index);
        }
        size = table_size;
    }
    apply {
        acl.apply();
    }
}

control Ipv6MirrorAcl(in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md, out switch_stats_index_t index)(switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.ip_src_addr     : ternary;
            lkp.ip_dst_addr     : ternary;
            lkp.ip_proto        : ternary;
            lkp.ip_tos          : ternary;
            lkp.l4_src_port     : ternary;
            lkp.l4_dst_port     : ternary;
            lkp.ip_ttl          : ternary;
            lkp.tcp_flags       : ternary;
            ig_md.port_lag_label: ternary;
            ig_md.l4_port_label : ternary;
        }
        actions = {
            NoAction;
            ingress_acl_mirror(ig_md, index);
        }
        size = table_size;
    }
    apply {
        acl.apply();
    }
}

control IpMirrorAcl(in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md, out switch_stats_index_t index)(switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.mac_type        : ternary;
            lkp.ip_src_addr     : ternary;
            lkp.ip_dst_addr     : ternary;
            lkp.ip_proto        : ternary;
            lkp.ip_tos          : ternary;
            lkp.l4_src_port     : ternary;
            lkp.l4_dst_port     : ternary;
            lkp.ip_ttl          : ternary;
            lkp.tcp_flags       : ternary;
            ig_md.port_lag_label: ternary;
            ig_md.l4_port_label : ternary;
        }
        actions = {
            NoAction;
            ingress_acl_mirror(ig_md, index);
        }
        size = table_size;
    }
    apply {
        acl.apply();
    }
}

control MirrorAcl(inout switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md)(switch_uint32_t ipv4_table_size=512, switch_uint32_t ipv6_table_size=512, bool stats_enable=false) {
    Ipv4MirrorAcl(ipv4_table_size) ipv4;
    Ipv6MirrorAcl(ipv6_table_size) ipv6;
    IpMirrorAcl(ipv6_table_size) ip;
    Counter<bit<16>, switch_stats_index_t>(ipv4_table_size + ipv6_table_size, CounterType_t.PACKETS_AND_BYTES) stats;
    switch_stats_index_t stats_index;
    apply {
    }
}

control Ipv4EgressMirrorAcl(in switch_header_t hdr, in switch_lookup_fields_t lkp, inout switch_egress_metadata_t eg_md, out switch_stats_index_t index)(switch_uint32_t table_size=512) {
    table acl {
        key = {
            hdr.ipv4.src_addr      : ternary;
            hdr.ipv4.dst_addr      : ternary;
            hdr.ipv4.protocol      : ternary;
            hdr.ipv4.diffserv      : ternary;
            lkp.tcp_flags          : ternary;
            lkp.l4_src_port        : ternary;
            lkp.l4_dst_port        : ternary;
            hdr.ethernet.ether_type: ternary;
            eg_md.port_lag_label   : ternary;
            eg_md.l4_port_label    : ternary;
        }
        actions = {
            NoAction;
            egress_acl_mirror(eg_md, index);
        }
        size = table_size;
    }
    apply {
        acl.apply();
    }
}

control Ipv6EgressMirrorAcl(in switch_header_t hdr, in switch_lookup_fields_t lkp, inout switch_egress_metadata_t eg_md, out switch_stats_index_t index)(switch_uint32_t table_size=512) {
    table acl {
        key = {
            hdr.ipv6.src_addr     : ternary;
            hdr.ipv6.dst_addr     : ternary;
            hdr.ipv6.next_hdr     : ternary;
            hdr.ipv6.traffic_class: ternary;
            lkp.tcp_flags         : ternary;
            lkp.l4_src_port       : ternary;
            lkp.l4_dst_port       : ternary;
            eg_md.port_lag_label  : ternary;
            eg_md.l4_port_label   : ternary;
        }
        actions = {
            NoAction;
            egress_acl_mirror(eg_md, index);
        }
        size = table_size;
    }
    apply {
        acl.apply();
    }
}

control EgressMirrorAcl(in switch_header_t hdr, inout switch_lookup_fields_t lkp, inout switch_egress_metadata_t eg_md)(switch_uint32_t ipv4_table_size=512, switch_uint32_t ipv6_table_size=512, bool stats_enable=false) {
    Ipv4EgressMirrorAcl(ipv4_table_size) ipv4;
    Ipv6EgressMirrorAcl(ipv6_table_size) ipv6;
    Counter<bit<16>, switch_stats_index_t>(ipv4_table_size + ipv6_table_size, CounterType_t.PACKETS_AND_BYTES) stats;
    switch_stats_index_t stats_index;
    apply {
    }
}

control IngressSystemAcl(inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(switch_uint32_t table_size=512) {
    const switch_uint32_t drop_stats_table_size = 8192;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) stats;
    Meter<bit<8>>(1 << 8, MeterType_t.PACKETS) copp_meter;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) copp_stats;
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
        ig_md.cpu_reason = reason_code;
    }
    action redirect_to_cpu(switch_cpu_reason_t reason_code, switch_qid_t qid, switch_copp_meter_id_t meter_id, bool disable_learning) {
        ig_intr_md_for_dprsr.drop_ctl = 0b1;
        copy_to_cpu(reason_code, qid, meter_id, disable_learning);
    }
    table system_acl {
        key = {
            ig_md.port_lag_label         : ternary;
            ig_md.bd_label               : ternary;
            ig_md.ifindex                : ternary;
            ig_md.lkp.pkt_type           : ternary;
            ig_md.lkp.mac_type           : ternary;
            ig_md.lkp.mac_dst_addr       : ternary;
            ig_md.lkp.ip_type            : ternary;
            ig_md.lkp.ip_ttl             : ternary;
            ig_md.lkp.ip_proto           : ternary;
            ig_md.lkp.ip_frag            : ternary;
            ig_md.lkp.ip_dst_addr        : ternary;
            ig_md.lkp.l4_src_port        : ternary;
            ig_md.lkp.l4_dst_port        : ternary;
            ig_md.lkp.arp_opcode         : ternary;
            ig_md.flags.port_vlan_miss   : ternary;
            ig_md.flags.acl_deny         : ternary;
            ig_md.flags.racl_deny        : ternary;
            ig_md.flags.rmac_hit         : ternary;
            ig_md.flags.dmac_miss        : ternary;
            ig_md.flags.myip             : ternary;
            ig_md.flags.glean            : ternary;
            ig_md.flags.routed           : ternary;
            ig_md.qos.acl_policer_color  : ternary;
            ig_md.flags.link_local       : ternary;
            ig_md.ipv4.unicast_enable    : ternary;
            ig_md.ipv6.unicast_enable    : ternary;
            ig_md.checks.mrpf            : ternary;
            ig_md.ipv4.multicast_enable  : ternary;
            ig_md.ipv4.multicast_snooping: ternary;
            ig_md.ipv6.multicast_enable  : ternary;
            ig_md.ipv6.multicast_snooping: ternary;
            ig_md.drop_reason            : ternary;
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
        ig_intr_md_for_tm.copy_to_cpu = 1w0;
        copp_meter_id = 0;
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SYSTEM_ACL != 0)) {
            system_acl.apply();
        }
        drop_stats.apply();
    }
}

control EgressMacAcl(in switch_header_t hdr, inout switch_egress_metadata_t eg_md, out switch_stats_index_t index)(switch_uint32_t table_size=512) {
    table acl {
        key = {
            eg_md.port_lag_label   : ternary;
            eg_md.bd_label         : ternary;
            hdr.ethernet.src_addr  : ternary;
            hdr.ethernet.dst_addr  : ternary;
            hdr.ethernet.ether_type: ternary;
        }
        actions = {
            NoAction;
            egress_acl_deny(eg_md, index);
            egress_acl_permit(eg_md, index);
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        acl.apply();
    }
}

control EgressIpv4Acl(in switch_header_t hdr, in switch_lookup_fields_t lkp, inout switch_egress_metadata_t eg_md, out switch_stats_index_t index)(switch_uint32_t table_size=512) {
    table acl {
        key = {
            hdr.ipv4.src_addr      : ternary;
            hdr.ipv4.dst_addr      : ternary;
            hdr.ipv4.protocol      : ternary;
            hdr.ipv4.diffserv      : ternary;
            lkp.tcp_flags          : ternary;
            lkp.l4_src_port        : ternary;
            lkp.l4_dst_port        : ternary;
            hdr.ethernet.ether_type: ternary;
            eg_md.port_lag_label   : ternary;
            eg_md.bd_label         : ternary;
            eg_md.l4_port_label    : ternary;
        }
        actions = {
            NoAction;
            egress_acl_deny(eg_md, index);
            egress_acl_permit(eg_md, index);
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        acl.apply();
    }
}

control EgressIpv6Acl(in switch_header_t hdr, in switch_lookup_fields_t lkp, inout switch_egress_metadata_t eg_md, out switch_stats_index_t index)(switch_uint32_t table_size=512) {
    table acl {
        key = {
            hdr.ipv6.src_addr     : ternary;
            hdr.ipv6.dst_addr     : ternary;
            hdr.ipv6.next_hdr     : ternary;
            hdr.ipv6.traffic_class: ternary;
            lkp.tcp_flags         : ternary;
            lkp.l4_src_port       : ternary;
            lkp.l4_dst_port       : ternary;
            eg_md.port_lag_label  : ternary;
            eg_md.bd_label        : ternary;
            eg_md.l4_port_label   : ternary;
        }
        actions = {
            NoAction;
            egress_acl_deny(eg_md, index);
            egress_acl_permit(eg_md, index);
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        acl.apply();
    }
}

control EgressAcl(in switch_header_t hdr, in switch_lookup_fields_t lkp, inout switch_egress_metadata_t eg_md)(switch_uint32_t ipv4_table_size=512, switch_uint32_t ipv6_table_size=512, switch_uint32_t mac_table_size=512, bool mac_acl_enable=false) {
    EgressIpv4Acl(ipv4_table_size) egress_ipv4_acl;
    EgressIpv6Acl(ipv6_table_size) egress_ipv6_acl;
    EgressMacAcl(mac_table_size) egress_mac_acl;
    Counter<bit<16>, switch_stats_index_t>(ipv4_table_size + ipv6_table_size + mac_table_size, CounterType_t.PACKETS_AND_BYTES) stats;
    switch_stats_index_t stats_index;
    apply {
        eg_md.flags.acl_deny = false;
        stats_index = 0;
        if (mac_acl_enable && !(eg_md.bypass & SWITCH_EGRESS_BYPASS_ACL != 0)) {
            egress_mac_acl.apply(hdr, eg_md, stats_index);
        }
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_ACL != 0)) {
            if (hdr.ipv6.isValid()) {
                egress_ipv6_acl.apply(hdr, lkp, eg_md, stats_index);
            } else if (!mac_acl_enable || hdr.ipv4.isValid()) {
                egress_ipv4_acl.apply(hdr, lkp, eg_md, stats_index);
            }
        }
        stats.count(stats_index);
    }
}

control EgressSystemAcl(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, out egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)(switch_uint32_t table_size=512) {
    const switch_uint32_t drop_stats_table_size = 8192;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) stats;
    action drop(switch_drop_reason_t reason_code) {
        eg_md.drop_reason = reason_code;
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }
    action copy_to_cpu(switch_cpu_reason_t reason_code) {
        eg_md.cpu_reason = reason_code;
        eg_intr_md_for_dprsr.mirror_type = 2;
        eg_md.mirror.type = 2;
        eg_md.mirror.session_id = SWITCH_MIRROR_SESSION_CPU;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
    }
    action redirect_to_cpu(switch_cpu_reason_t reason_code) {
        copy_to_cpu(reason_code);
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }
    action insert_timestamp() {
    }
    table system_acl {
        key = {
            eg_intr_md.egress_port: ternary;
            eg_md.flags.acl_deny  : ternary;
            eg_md.checks.mtu      : ternary;
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
    apply {
        eg_md.drop_reason = 0;
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_SYSTEM_ACL != 0)) {
            system_acl.apply();
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
        stp_state = false;
    }
}

control SMAC(in mac_addr_t src_addr, inout switch_ingress_metadata_t ig_md, inout switch_digest_type_t digest_type)(switch_uint32_t table_size) {
    bool src_miss;
    switch_ifindex_t src_move;
    action smac_miss() {
        src_miss = true;
    }
    action smac_hit(switch_ifindex_t ifindex) {
        src_move = ig_md.ifindex ^ ifindex;
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
    }
    apply {
        src_miss = false;
        src_move = 0;
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
        ig_md.egress_ifindex = SWITCH_IFINDEX_FLOOD;
        ig_md.flags.dmac_miss = true;
    }
    action dmac_hit(switch_ifindex_t ifindex, switch_port_lag_index_t port_lag_index) {
        ig_md.egress_ifindex = ifindex;
        ig_md.egress_port_lag_index = port_lag_index;
        ig_md.checks.same_if = ig_md.ifindex ^ ifindex;
    }
    action dmac_multicast(switch_mgid_t index) {
        ig_md.multicast.id = index;
    }
    action dmac_redirect(switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
    }
    table dmac {
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
        ig_md.flags.dmac_miss = false;
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_L2 != 0)) {
            dmac.apply();
        }
    }
}

control IngressBd(in switch_bd_t bd, in switch_pkt_type_t pkt_type)(switch_uint32_t table_size) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
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

control EgressBd(in switch_header_t hdr, in switch_bd_t bd, in switch_pkt_type_t pkt_type, in switch_pkt_src_t pkt_src, out switch_bd_label_t label, out switch_smac_index_t smac_idx, out switch_mtu_t mtu_idx)(switch_uint32_t table_size) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
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
        size = 3 * table_size;
        counters = stats;
    }
    action set_bd_properties(switch_bd_label_t bd_label, switch_smac_index_t smac_index, switch_mtu_t mtu_index) {
        label = bd_label;
        smac_idx = smac_index;
        mtu_idx = mtu_index;
    }
    table bd_mapping {
        key = {
            bd: exact;
        }
        actions = {
            NoAction;
            set_bd_properties;
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        mtu_idx = 0;
        bd_mapping.apply();
        if (pkt_src == SWITCH_PKT_SRC_BRIDGED) {
            bd_stats.apply();
        }
    }
}

control VlanDecap(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md) {
    action remove_vlan_tag() {
        hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
        eg_md.tunnel.u_tag = hdr.vlan_tag[0].vid;
        eg_md.tunnel.p_tag_exist = false;
        hdr.vlan_tag[0].setInvalid();
    }
    action remove_double_tag() {
        hdr.ethernet.ether_type = hdr.vlan_tag[1].ether_type;
        eg_md.tunnel.u_tag = hdr.vlan_tag[1].vid;
        eg_md.tunnel.p_tag = hdr.vlan_tag[0].vid;
        eg_md.tunnel.p_tag_exist = true;
        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
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
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0)) {
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
        hdr.vlan_tag[0].pcp = eg_md.lkp.pcp;
        hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].vid = vid;
        hdr.ethernet.ether_type = 0x8100;
    }
    action set_double_tagged_with_utag(vlan_id_t vid0) {
        set_double_tagged(vid0, eg_md.tunnel.u_tag);
    }
    action set_vlan_tagged_with_utag() {
        set_vlan_tagged(eg_md.tunnel.u_tag);
    }
    action set_double_tagged_with_ptag_utag() {
        set_double_tagged(eg_md.tunnel.p_tag, eg_md.tunnel.u_tag);
    }
    table port_bd_to_vlan_mapping {
        key = {
            eg_md.port_lag_index    : exact @name("port_lag_index") ;
            eg_md.bd                : exact @name("bd") ;
            eg_md.tunnel.p_tag_exist: exact;
        }
        actions = {
            set_vlan_untagged;
            set_vlan_tagged;
            set_double_tagged;
            set_vlan_tagged_with_utag;
            set_double_tagged_with_utag;
            set_double_tagged_with_ptag_utag;
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
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0)) {
            if (!port_bd_to_vlan_mapping.apply().hit) {
                bd_to_vlan_mapping.apply();
            }
        }
    }
}

control Fib<T>(in ipv4_addr_t dst_addr, in switch_vrf_t vrf, out switch_ingress_flags_t flags, out switch_nexthop_t nexthop)(switch_uint32_t host_table_size, switch_uint32_t lpm_table_size, bool local_host_enable=false, switch_uint32_t local_host_table_size=1024) {
    action fib_hit(switch_nexthop_t nexthop_index) {
        nexthop = nexthop_index;
        flags.routed = true;
    }
    action fib_miss() {
        flags.routed = false;
    }
    action fib_myip() {
        flags.myip = true;
    }
    table fib {
        key = {
            vrf     : exact;
            dst_addr: exact;
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
            vrf     : exact;
            dst_addr: exact;
        }
        actions = {
            fib_miss;
            fib_hit;
            fib_myip;
        }
        const default_action = fib_miss;
        size = local_host_table_size;
    }
    @alpm(1) @alpm_partitions(1024) @alpm_subtrees_per_partition(2) table fib_lpm {
        key = {
            vrf     : exact;
            dst_addr: lpm;
        }
        actions = {
            fib_miss;
            fib_hit;
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

control Fibv6<T>(in ipv6_addr_t dst_addr, in switch_vrf_t vrf, out switch_ingress_flags_t flags, out switch_nexthop_t nexthop)(switch_uint32_t host_table_size, switch_uint32_t lpm_table_size, switch_uint32_t lpm64_table_size) {
    action fib_hit(switch_nexthop_t nexthop_index) {
        nexthop = nexthop_index;
        flags.routed = true;
    }
    action fib_miss() {
        flags.routed = false;
    }
    action fib_myip() {
        flags.myip = true;
    }
    table fib {
        key = {
            vrf     : exact;
            dst_addr: exact;
        }
        actions = {
            fib_miss;
            fib_hit;
            fib_myip;
        }
        const default_action = fib_miss;
        size = host_table_size;
    }
    table fib_lpm {
        key = {
            vrf     : exact;
            dst_addr: lpm;
        }
        actions = {
            fib_miss;
            fib_hit;
        }
        const default_action = fib_miss;
        size = lpm_table_size;
    }
    apply {
        if (!fib.apply().hit) {
            fib_lpm.apply();
        }
    }
}

control MTU(in switch_header_t hdr, in switch_egress_metadata_t eg_md, inout switch_mtu_t mtu_check)(switch_uint32_t table_size=1024) {
    action ipv4_mtu_check(switch_mtu_t mtu) {
        mtu_check = mtu |-| hdr.ipv4.total_len;
    }
    action ipv6_mtu_check(switch_mtu_t mtu) {
        mtu_check = mtu |-| hdr.ipv6.payload_len;
    }
    action mtu_miss() {
        mtu_check = 16w0xffff;
    }
    table mtu {
        key = {
            mtu_check         : exact;
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
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_MTU != 0)) {
            mtu.apply();
        }
    }
}

control IngressUnicast(in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md)(DMAC_t dmac, switch_uint32_t ipv4_host_table_size, switch_uint32_t ipv4_route_table_size, switch_uint32_t ipv6_host_table_size=1024, switch_uint32_t ipv6_route_table_size=512, switch_uint32_t ipv6_route64_table_size=512, bool local_host_enable=false, switch_uint32_t ipv4_local_host_table_size=1024) {
    Fib<ipv4_addr_t>(ipv4_host_table_size, ipv4_route_table_size, local_host_enable, ipv4_local_host_table_size) ipv4_fib;
    Fibv6<ipv6_addr_t>(ipv6_host_table_size, ipv6_route_table_size, ipv6_route64_table_size) ipv6_fib;
    action rmac_hit() {
        ig_md.flags.rmac_hit = true;
    }
    action rmac_miss() {
    }
    table rmac {
        key = {
            ig_md.rmac_group: exact;
            lkp.mac_dst_addr: exact;
        }
        actions = {
            rmac_hit;
            @defaultonly rmac_miss;
        }
        const default_action = rmac_miss;
        size = 1024;
    }
    apply {
        if (rmac.apply().hit) {
            if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_L3 != 0)) {
                if (lkp.ip_type == SWITCH_IP_TYPE_IPV6 && ig_md.ipv6.unicast_enable) {
                    ipv6_fib.apply(lkp.ip_dst_addr, ig_md.vrf, ig_md.flags, ig_md.nexthop);
                } else {
                }
            }
        } else {
            dmac.apply(lkp.mac_dst_addr, ig_md);
        }
    }
}

control Nexthop(inout switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md, in bit<16> hash)(switch_uint32_t nexthop_table_size, switch_uint32_t ecmp_table_size, switch_uint32_t ecmp_selection_table_size) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(ecmp_selection_table_size, selector_hash, SelectorMode_t.FAIR) ecmp_selector;
    action set_nexthop_properties(switch_ifindex_t ifindex, switch_port_lag_index_t port_lag_index, switch_bd_t bd) {
        ig_md.egress_ifindex = ifindex;
        ig_md.egress_port_lag_index = port_lag_index;
        ig_md.checks.same_if = ig_md.ifindex ^ ifindex;
        ig_md.checks.same_bd = ig_md.bd ^ bd;
    }
    action set_nexthop_properties_post_routed_flood(switch_bd_t bd, switch_mgid_t mgid) {
        ig_md.egress_ifindex = 0;
        ig_md.egress_port_lag_index = 0;
        ig_md.checks.same_bd = ig_md.bd ^ bd;
        ig_md.multicast.id = mgid;
    }
    action set_nexthop_properties_glean() {
        ig_md.flags.glean = true;
        ig_md.checks.same_bd = 0xffff;
    }
    action set_nexthop_properties_drop() {
        ig_md.drop_reason = SWITCH_DROP_REASON_NEXTHOP;
    }
    action set_ecmp_properties(switch_ifindex_t ifindex, switch_port_lag_index_t port_lag_index, switch_bd_t bd, switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties(ifindex, port_lag_index, bd);
    }
    action set_ecmp_properties_post_routed_flood(switch_bd_t bd, switch_mgid_t mgid, switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties_post_routed_flood(bd, mgid);
    }
    action set_ecmp_properties_glean(switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties_glean();
    }
    action set_tunnel_properties(switch_bd_t bd, switch_tunnel_index_t tunnel_index) {
        ig_md.tunnel.index = tunnel_index;
        ig_md.egress_ifindex = 0;
        ig_md.checks.same_bd = ig_md.bd ^ bd;
    }
    table ecmp {
        key = {
            ig_md.nexthop: exact;
            hash         : selector;
        }
        actions = {
            NoAction;
            set_ecmp_properties;
            set_ecmp_properties_glean;
            set_ecmp_properties_post_routed_flood;
            set_tunnel_properties;
        }
        const default_action = NoAction;
        size = ecmp_table_size;
        implementation = ecmp_selector;
    }
    table nexthop {
        key = {
            ig_md.nexthop: exact;
        }
        actions = {
            NoAction;
            set_nexthop_properties;
            set_nexthop_properties_drop;
            set_nexthop_properties_glean;
            set_nexthop_properties_post_routed_flood;
            set_tunnel_properties;
        }
        const default_action = NoAction;
        size = nexthop_table_size;
    }
    apply {
        ig_md.checks.same_bd = 0;
        ig_md.flags.glean = false;
        switch (nexthop.apply().action_run) {
            NoAction: {
                ecmp.apply();
            }
            default: {
            }
        }

    }
}

control OuterFib(inout switch_ingress_metadata_t ig_md, in bit<16> hash)(switch_uint32_t fib_table_size, switch_uint32_t ecmp_table_size, switch_uint32_t ecmp_selection_table_size) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(ecmp_selection_table_size, selector_hash, SelectorMode_t.FAIR) ecmp_selector;
    action set_nexthop_properties(switch_ifindex_t ifindex, switch_port_lag_index_t port_lag_index, switch_outer_nexthop_t nexthop_index) {
        ig_md.outer_nexthop = nexthop_index;
        ig_md.egress_ifindex = ifindex;
        ig_md.egress_port_lag_index = port_lag_index;
    }
    table fib {
        key = {
            ig_md.tunnel.index: exact;
            hash              : selector;
        }
        actions = {
            NoAction;
            set_nexthop_properties;
        }
        const default_action = NoAction;
        implementation = ecmp_selector;
        size = fib_table_size;
    }
    apply {
        fib.apply();
    }
}

parser SRHParser(packet_in pkt, inout switch_header_t hdr) {
    state start {
        transition accept;
    }
    state parse_srh {
        transition accept;
    }
}

parser SwitchIngressParser(packet_in pkt, out switch_header_t hdr, out switch_ingress_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    value_set<bit<16>>(1) udp_port_vxlan;
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;
    state start {
        pkt.extract(ig_intr_md);
        ig_md.port = ig_intr_md.ingress_port;
        ig_md.timestamp = ig_intr_md.ingress_mac_tstamp;
        transition parse_port_metadata;
    }
    state parse_resubmit {
        transition accept;
    }
    state parse_port_metadata {
        switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);
        ig_md.port_lag_index = port_md.port_lag_index;
        ig_md.port_lag_label = port_md.port_lag_label;
        ig_md.ifindex = port_md.ifindex;
        transition parse_packet;
    }
    state parse_packet {
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type, ig_intr_md.ingress_port) {
            (0x9000, default): parse_fabric;
            (0x800, default): parse_ipv4;
            (0x806, default): parse_arp;
            (0x86dd, default): parse_ipv6;
            (0x8100, default): parse_vlan;
            (0x8100, default): parse_vlan;
            (0x8906, default): parse_fcoe;
            (0x8847, default): parse_mpls;
            default: accept;
        }
    }
    state parse_fabric {
        pkt.extract(hdr.fabric);
        transition select(hdr.fabric.packet_type) {
            1: parse_fabric_unicast;
            2: parse_fabric_multicast;
            3: parse_fabric_mirror;
            5: parse_fabric_cpu;
            default: accept;
        }
    }
    state parse_fabric_unicast {
        pkt.extract(hdr.fabric_unicast_header);
        transition parse_fabric_payload;
    }
    state parse_fabric_multicast {
        pkt.extract(hdr.fabric_multicast_header);
        transition parse_fabric_payload;
    }
    state parse_fabric_mirror {
        pkt.extract(hdr.fabric_mirror_header);
        transition parse_fabric_payload;
    }
    state parse_fabric_cpu {
        pkt.extract(hdr.fabric_cpu_header);
        ig_md.bypass = hdr.fabric_cpu_header.reason_code;
        ig_md.flags.capture_ts = hdr.fabric_cpu_header.capture_tstamp_on_tx;
        transition select(hdr.fabric_cpu_header.reason_code) {
            default: parse_fabric_payload;
        }
    }
    state parse_fabric_payload {
        pkt.extract(hdr.fabric_payload_header);
        transition select(hdr.fabric_payload_header.ether_type) {
            0x800: parse_ipv4;
            0x806: parse_arp;
            0x86dd: parse_ipv6;
            0x8100: parse_vlan;
            0x8100: parse_vlan;
            0x8906: parse_fcoe;
            0x8847: parse_mpls;
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
    state parse_mpls {
        pkt.extract(hdr.mpls.next);
        transition select(hdr.mpls.last.bos) {
            0: parse_mpls;
            1: parse_mpls_bos;
            default: accept;
        }
    }
    state parse_mpls_bos {
        transition select(pkt.lookahead<bit<4>>()) {
            0x4: parse_mpls_inner_ipv4;
            0x6: parse_mpls_inner_ipv6;
            default: parse_eompls;
        }
    }
    state parse_mpls_inner_ipv4 {
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_MPLS;
        transition parse_inner_ipv4;
    }
    state parse_mpls_inner_ipv6 {
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_MPLS;
        transition parse_inner_ipv6;
    }
    state parse_eompls {
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_MPLS;
        transition parse_inner_ethernet;
    }
    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            58: parse_icmp;
            6: parse_tcp;
            17: parse_udp;
            4: parse_ipinip;
            41: parse_ipv6inip;
            default: accept;
        }
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            udp_port_vxlan: parse_vxlan;
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
    state parse_rocev2 {
        transition accept;
    }
    state parse_fcoe {
        transition accept;
    }
    state parse_vxlan {
        transition accept;
    }
    state parse_ipinip {
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv4;
    }
    state parse_ipv6inip {
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv6;
    }
    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            0x800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;
            0x8100: parse_inner_vlan;
            0x8100: parse_inner_vlan;
            default: accept;
        }
    }
    state parse_inner_vlan {
        pkt.extract(hdr.inner_vlan_tag.next);
        transition select(hdr.inner_vlan_tag.last.ether_type) {
            0x800: parse_inner_ipv4;
            0x8100: parse_inner_vlan;
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
    @critical state start {
        pkt.extract(eg_intr_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.port = eg_intr_md.egress_port;
        eg_md.qos.qdepth = eg_intr_md.enq_qdepth;
        switch_port_mirror_metadata_h mirror_md = pkt.lookahead<switch_port_mirror_metadata_h>();
        transition select(eg_intr_md.deflection_flag, mirror_md.src, mirror_md.type) {
            (1, default, default): parse_deflected_pkt;
            (default, SWITCH_PKT_SRC_BRIDGED, default): parse_bridged_pkt;
            (default, default, 1): parse_port_mirrored_metadata;
            (default, SWITCH_PKT_SRC_CLONED_EGRESS, 2): parse_cpu_mirrored_metadata;
            (default, default, 3): parse_dtel_drop_metadata;
            (default, default, 4): parse_dtel_switch_local_metadata;
        }
    }
    state parse_bridged_pkt {
        pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_BRIDGED;
        eg_md.ingress_port = hdr.bridged_md.base.ingress_port;
        eg_md.ingress_ifindex = hdr.bridged_md.base.ingress_ifindex;
        eg_md.bd = hdr.bridged_md.base.ingress_bd;
        eg_md.nexthop = hdr.bridged_md.base.nexthop;
        eg_md.cpu_reason = hdr.bridged_md.base.cpu_reason;
        eg_md.flags.routed = hdr.bridged_md.base.routed;
        eg_md.pkt_type = hdr.bridged_md.base.pkt_type;
        eg_md.ingress_timestamp = hdr.bridged_md.base.timestamp;
        eg_md.qos.tc = hdr.bridged_md.base.tc;
        eg_md.qos.qid = hdr.bridged_md.base.qid;
        eg_md.qos.color = hdr.bridged_md.base.color;
        eg_md.l4_port_label = hdr.bridged_md.acl.l4_port_label;
        eg_md.lkp.l4_src_port = hdr.bridged_md.acl.l4_src_port;
        eg_md.lkp.l4_dst_port = hdr.bridged_md.acl.l4_dst_port;
        eg_md.lkp.tcp_flags = hdr.bridged_md.acl.tcp_flags;
        eg_md.outer_nexthop = hdr.bridged_md.tunnel.outer_nexthop;
        eg_md.tunnel.index = hdr.bridged_md.tunnel.index;
        eg_md.tunnel.hash = hdr.bridged_md.tunnel.hash;
        eg_md.vrf = hdr.bridged_md.tunnel.vrf;
        eg_md.tunnel.terminate = hdr.bridged_md.tunnel.terminate;
        eg_md.tunnel.type = hdr.bridged_md.tunnel.type;
        eg_md.multicast.id = hdr.bridged_md.multicast.id;
        eg_md.multicast.replication_id = hdr.bridged_md.multicast.replication_id;
        eg_md.multicast.l1xid = hdr.bridged_md.multicast.l1xid;
        transition parse_ethernet;
    }
    state parse_deflected_pkt {
    }
    state parse_port_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.ethernet);
        eg_md.pkt_src = port_md.src;
        eg_md.mirror.session_id = port_md.session_id;
        eg_md.ingress_timestamp = port_md.timestamp;
        eg_md.bypass = ~SWITCH_EGRESS_BYPASS_MTU;
        transition accept;
    }
    state parse_cpu_mirrored_metadata {
        switch_cpu_mirror_metadata_h cpu_md;
        pkt.extract(cpu_md);
        pkt.extract(hdr.ethernet);
        eg_md.pkt_src = cpu_md.src;
        eg_md.bypass = ~SWITCH_EGRESS_BYPASS_MTU;
        eg_md.bd = cpu_md.bd;
        eg_md.cpu_reason = cpu_md.reason_code;
        transition accept;
    }
    state parse_dtel_drop_metadata {
        transition reject;
    }
    state parse_dtel_switch_local_metadata {
        transition reject;
    }
    state parse_packet {
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type, eg_intr_md.egress_port) {
            cpu_port: parse_cpu;
            (0x9000, default): parse_fabric;
            (0x800, default): parse_ipv4;
            (0x86dd, default): parse_ipv6;
            (0x8100, default): parse_vlan;
            (0x8100, default): parse_vlan;
            (0x8847, default): parse_mpls;
            default: accept;
        }
    }
    state parse_fabric {
        pkt.extract(hdr.fabric);
        transition select(hdr.fabric.packet_type) {
            1: parse_fabric_unicast;
            2: parse_fabric_multicast;
            3: parse_fabric_mirror;
            5: parse_fabric_cpu;
            default: accept;
        }
    }
    state parse_fabric_unicast {
        pkt.extract(hdr.fabric_unicast_header);
        transition parse_fabric_payload;
    }
    state parse_fabric_multicast {
        pkt.extract(hdr.fabric_multicast_header);
        transition parse_fabric_payload;
    }
    state parse_fabric_mirror {
        pkt.extract(hdr.fabric_mirror_header);
        transition parse_fabric_payload;
    }
    state parse_fabric_cpu {
        pkt.extract(hdr.fabric_cpu_header);
        transition select(hdr.fabric_cpu_header.reason_code) {
            default: parse_fabric_payload;
        }
    }
    state parse_fabric_payload {
        pkt.extract(hdr.fabric_payload_header);
        transition select(hdr.fabric_payload_header.ether_type) {
            0x800: parse_ipv4;
            0x86dd: parse_ipv6;
            0x8100: parse_vlan;
            0x8100: parse_vlan;
            0x8847: parse_mpls;
            default: accept;
        }
    }
    state parse_cpu {
        eg_md.bypass = SWITCH_EGRESS_BYPASS_ALL;
        transition accept;
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol, hdr.ipv4.ihl, hdr.ipv4.frag_offset) {
            (17, 5, 0): parse_udp;
            (4, 5, 0): parse_inner_ipv4;
            (41, 5, 0): parse_inner_ipv6;
            (default, 6, default): parse_ipv4_options;
            default: accept;
        }
    }
    state parse_ipv4_options {
        pkt.extract(hdr.ipv4_option);
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (17, 0): parse_udp;
            (4, 0): parse_inner_ipv4;
            (41, 0): parse_inner_ipv6;
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
    state parse_mpls {
        pkt.extract(hdr.mpls.next);
        transition select(hdr.mpls.last.bos) {
            0: parse_mpls;
            1: parse_mpls_bos;
            default: accept;
        }
    }
    state parse_mpls_bos {
        transition select(pkt.lookahead<bit<4>>()) {
            0x4: parse_inner_ipv4;
            0x6: parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }
    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            17: parse_udp;
            4: parse_inner_ipv4;
            41: parse_inner_ipv6;
            default: accept;
        }
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            udp_port_vxlan: parse_vxlan;
            default: accept;
        }
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }
    state parse_vxlan {
        transition accept;
    }
    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            0x800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;
            0x8100: parse_inner_vlan;
            0x8100: parse_inner_vlan;
            default: accept;
        }
    }
    state parse_inner_vlan {
        pkt.extract(hdr.inner_vlan_tag.next);
        transition select(hdr.inner_vlan_tag.last.ether_type) {
            0x800: parse_inner_ipv4;
            0x8100: parse_inner_vlan;
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
        } else if (ig_intr_md_for_dprsr.mirror_type == 2) {
            mirror.emit<switch_cpu_mirror_metadata_h>(ig_md.mirror.session_id, { ig_md.mirror.src, ig_md.mirror.type, 0, ig_md.port, ig_md.bd, ig_md.ifindex, ig_md.cpu_reason });
        } else if (ig_intr_md_for_dprsr.mirror_type == 3) {
        }
    }
}

control EgressMirror(inout switch_header_t hdr, in switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    Mirror() mirror;
    apply {
        if (eg_intr_md_for_dprsr.mirror_type == 1) {
            mirror.emit<switch_port_mirror_metadata_h>(eg_md.mirror.session_id, { eg_md.mirror.src, eg_md.mirror.type, eg_md.ingress_timestamp, 0, eg_md.mirror.session_id });
        } else if (eg_intr_md_for_dprsr.mirror_type == 2) {
            mirror.emit<switch_cpu_mirror_metadata_h>(eg_md.mirror.session_id, { eg_md.mirror.src, eg_md.mirror.type, 0, eg_md.ingress_port, eg_md.bd, eg_md.ingress_ifindex, eg_md.cpu_reason });
        } else if (eg_intr_md_for_dprsr.mirror_type == 4) {
        }
    }
}

control SwitchIngressDeparser(packet_out pkt, inout switch_header_t hdr, in switch_ingress_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    IngressMirror() mirror;
    Digest<switch_learning_digest_t>() digest;
    apply {
        mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);
        if (ig_intr_md_for_dprsr.digest_type == SWITCH_DIGEST_TYPE_MAC_LEARNING) {
            digest.pack({ ig_md.bd, ig_md.ifindex, ig_md.lkp.mac_src_addr });
        }
        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.fabric);
        pkt.emit(hdr.fabric_unicast_header);
        pkt.emit(hdr.fabric_multicast_header);
        pkt.emit(hdr.fabric_mirror_header);
        pkt.emit(hdr.fabric_cpu_header);
        pkt.emit(hdr.fabric_ts_header);
        pkt.emit(hdr.fabric_sflow_header);
        pkt.emit(hdr.fabric_bfd_event_header);
        pkt.emit(hdr.fabric_payload_header);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.mpls);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv4_option);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.icmp);
        pkt.emit(hdr.igmp);
        pkt.emit(hdr.rocev2_bth);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_vlan_tag);
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
    apply {
        mirror.apply(hdr, eg_md, eg_intr_md_for_dprsr);
        if (hdr.ipv4_option.isValid()) {
            hdr.ipv4.hdr_checksum = ipv4_checksum.update({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.total_len, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.frag_offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4_option.type, hdr.ipv4_option.length, hdr.ipv4_option.value });
        } else if (hdr.ipv4.isValid()) {
            hdr.ipv4.hdr_checksum = ipv4_checksum.update({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.total_len, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.frag_offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.src_addr, hdr.ipv4.dst_addr });
        }
        hdr.inner_ipv4.hdr_checksum = inner_ipv4_checksum.update({ hdr.inner_ipv4.version, hdr.inner_ipv4.ihl, hdr.inner_ipv4.diffserv, hdr.inner_ipv4.total_len, hdr.inner_ipv4.identification, hdr.inner_ipv4.flags, hdr.inner_ipv4.frag_offset, hdr.inner_ipv4.ttl, hdr.inner_ipv4.protocol, hdr.inner_ipv4.src_addr, hdr.inner_ipv4.dst_addr });
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.fabric);
        pkt.emit(hdr.fabric_unicast_header);
        pkt.emit(hdr.fabric_multicast_header);
        pkt.emit(hdr.fabric_mirror_header);
        pkt.emit(hdr.fabric_cpu_header);
        pkt.emit(hdr.fabric_ts_header);
        pkt.emit(hdr.fabric_sflow_header);
        pkt.emit(hdr.fabric_bfd_event_header);
        pkt.emit(hdr.fabric_payload_header);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.mpls);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.dtel);
        pkt.emit(hdr.dtel_switch_local_report);
        pkt.emit(hdr.dtel_drop_report);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.gre);
        pkt.emit(hdr.erspan_type2);
        pkt.emit(hdr.erspan_type3);
        pkt.emit(hdr.erspan_platform);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_vlan_tag);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
    }
}

control MirrorRewrite(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t table_size=1024) {
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
    }
    action add_gre_header(in bit<16> proto) {
        hdr.gre.setValid();
        hdr.gre.flags = 0;
        hdr.gre.version = 0;
        hdr.gre.proto = proto;
    }
    action add_erspan_type2(bit<10> session_id) {
        hdr.erspan_type2.setValid();
        hdr.erspan_type2.version = 4w0x1;
        hdr.erspan_type2.vlan = 0;
        hdr.erspan_type2.cos_en_t = 0;
        hdr.erspan_type2.session_id = session_id;
    }
    action add_erspan_type3(bit<10> session_id, bit<32> timestamp, bool opt_sub_header) {
        hdr.erspan_type3.setValid();
        hdr.erspan_type3.version = 4w0x2;
        hdr.erspan_type3.vlan = 0;
        hdr.erspan_type3.cos_bso_t = 0;
        hdr.erspan_type3.session_id = session_id;
        hdr.erspan_type3.timestamp = timestamp;
        hdr.erspan_type3.sgt = 0;
        hdr.erspan_type3.p = 0;
        hdr.erspan_type3.ft = 0;
        hdr.erspan_type3.hw_id = 0;
        hdr.erspan_type3.d = 0;
        hdr.erspan_type3.gra = 0b10;
        if (opt_sub_header) {
            hdr.erspan_type3.o = 1;
            hdr.erspan_platform.setValid();
            hdr.erspan_platform.id = 0;
            hdr.erspan_platform.info = 0;
        } else {
            hdr.erspan_type3.o = 0;
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
        hdr.ipv4.total_len = eg_md.pkt_length + 16w18;
        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, 0x800);
    }
    action rewrite_erspan_type2_with_vlan(switch_qid_t qid, bit<16> ether_type, mac_addr_t smac, mac_addr_t dmac, bit<3> pcp, vlan_id_t vid, ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
        eg_md.qos.qid = qid;
        add_erspan_type2((bit<10>)eg_md.mirror.session_id);
        add_gre_header(0x88be);
        add_ipv4_header(tos, ttl, 47, sip, dip);
        hdr.ipv4.total_len = eg_md.pkt_length + 16w18;
        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, ether_type);
        add_vlan_tag(vid, pcp, 0x800);
    }
    action rewrite_erspan_type3(switch_qid_t qid, mac_addr_t smac, mac_addr_t dmac, ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
        eg_md.qos.qid = qid;
        add_erspan_type3((bit<10>)eg_md.mirror.session_id, (bit<32>)eg_md.ingress_timestamp, false);
        add_gre_header(0x22eb);
        add_ipv4_header(tos, ttl, 47, sip, dip);
        hdr.ipv4.total_len = eg_md.pkt_length + 16w22;
        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, 0x800);
    }
    action rewrite_erspan_type3_with_vlan(switch_qid_t qid, bit<16> ether_type, mac_addr_t smac, mac_addr_t dmac, bit<3> pcp, vlan_id_t vid, ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
        eg_md.qos.qid = qid;
        add_erspan_type3((bit<10>)eg_md.mirror.session_id, (bit<32>)eg_md.ingress_timestamp, false);
        add_gre_header(0x22eb);
        add_ipv4_header(tos, ttl, 47, sip, dip);
        hdr.ipv4.total_len = eg_md.pkt_length + 16w22;
        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, ether_type);
        add_vlan_tag(vid, pcp, 0x800);
    }
    action rewrite_erspan_type3_platform_specific(switch_qid_t qid, mac_addr_t smac, mac_addr_t dmac, ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
        eg_md.qos.qid = qid;
        add_erspan_type3((bit<10>)eg_md.mirror.session_id, (bit<32>)eg_md.ingress_timestamp, true);
        add_gre_header(0x22eb);
        add_ipv4_header(tos, ttl, 47, sip, dip);
        hdr.ipv4.total_len = eg_md.pkt_length + 16w30;
        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, 0x800);
    }
    action rewrite_erspan_type3_platform_specific_with_vlan(switch_qid_t qid, bit<16> ether_type, mac_addr_t smac, mac_addr_t dmac, bit<3> pcp, vlan_id_t vid, ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
        eg_md.qos.qid = qid;
        add_erspan_type3((bit<10>)eg_md.mirror.session_id, (bit<32>)eg_md.ingress_timestamp, true);
        add_gre_header(0x22eb);
        add_ipv4_header(tos, ttl, 47, sip, dip);
        hdr.ipv4.total_len = eg_md.pkt_length + 16w30;
        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, ether_type);
        add_vlan_tag(vid, pcp, 0x800);
    }
    action rewrite_dtel_report(mac_addr_t smac, mac_addr_t dmac, ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl, bit<16> udp_dst_port) {
    }
    action rewrite_dtel_report_with_entropy(mac_addr_t smac, mac_addr_t dmac, ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl, bit<16> udp_dst_port) {
    }
    action rewrite_dtel_report_without_entropy(mac_addr_t smac, mac_addr_t dmac, ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl, bit<16> udp_dst_port, bit<16> udp_src_port) {
    }
    table rewrite {
        key = {
            eg_md.mirror.session_id: exact;
        }
        actions = {
            NoAction;
            rewrite_;
            rewrite_rspan;
            rewrite_erspan_type2;
            rewrite_erspan_type3;
            rewrite_erspan_type3_platform_specific;
            rewrite_erspan_type2_with_vlan;
            rewrite_erspan_type3_with_vlan;
            rewrite_erspan_type3_platform_specific_with_vlan;
            rewrite_dtel_report_with_entropy;
            rewrite_dtel_report_without_entropy;
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
                        1 : adjust_length(-14);

                        2 : adjust_length(-14);

                        3 : adjust_length(-13);

                        4 : adjust_length(-15);

        }

    }
    apply {
        if (eg_md.pkt_src != SWITCH_PKT_SRC_BRIDGED) {
            rewrite.apply();
        }
    }
}

control Rewrite(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t nexthop_table_size, switch_uint32_t bd_table_size) {
    EgressBd(bd_table_size) egress_bd;
    switch_smac_index_t smac_index;
    action rewrite_l2_with_tunnel(switch_tunnel_type_t type) {
        eg_md.flags.routed = false;
        eg_md.tunnel.type = type;
    }
    action rewrite_l3(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.flags.routed = true;
        hdr.ethernet.dst_addr = dmac;
        eg_md.bd = bd;
    }
    action rewrite_l3_with_tunnel_id(mac_addr_t dmac, switch_tunnel_type_t type, switch_tunnel_id_t id) {
        eg_md.flags.routed = true;
        hdr.ethernet.dst_addr = dmac;
        eg_md.bd = SWITCH_BD_DEFAULT_VRF;
        eg_md.tunnel.type = type;
        eg_md.tunnel.id = id;
    }
    action rewrite_l3_with_tunnel_bd(mac_addr_t dmac, switch_tunnel_type_t type, switch_bd_t bd) {
        eg_md.flags.routed = true;
        hdr.ethernet.dst_addr = dmac;
        eg_md.bd = bd;
        eg_md.tunnel.type = type;
    }
    action rewrite_l3_with_tunnel(mac_addr_t dmac, switch_tunnel_type_t type) {
        eg_md.flags.routed = true;
        hdr.ethernet.dst_addr = dmac;
        eg_md.tunnel.type = type;
        eg_md.bd = (switch_bd_t)eg_md.vrf;
    }
    action rewrite_with_mpls_push(bit<8> dmac_index, switch_tunnel_type_t type, switch_tunnel_id_t id, bit<4> header_count, bit<4> sr_count, bit<4> vc_index) {
        eg_md.flags.routed = true;
        eg_md.tunnel.dmac_index = dmac_index;
        eg_md.tunnel.type = type;
        eg_md.tunnel.id = id;
        eg_md.tunnel.egress_header_count = header_count;
        eg_md.tunnel.sr_tunnel_count = sr_count;
        eg_md.vc_index = vc_index;
    }
    action rewrite_sr_pop(mac_addr_t dmac) {
        hdr.mpls.pop_front(1);
        eg_md.flags.routed = true;
        hdr.ethernet.dst_addr = dmac;
        eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_MPLS_SR;
    }
    table nexthop_rewrite {
        key = {
            eg_md.nexthop: exact;
        }
        actions = {
            NoAction;
            rewrite_l2_with_tunnel;
            rewrite_l3;
            rewrite_l3_with_tunnel;
            rewrite_l3_with_tunnel_bd;
            rewrite_l3_with_tunnel_id;
            rewrite_with_mpls_push;
            rewrite_sr_pop;
        }
        const default_action = NoAction;
        size = nexthop_table_size;
    }
    action rewrite_smac(mac_addr_t smac) {
        hdr.ethernet.src_addr = smac;
    }
    table smac_rewrite {
        key = {
            smac_index: exact;
        }
        actions = {
            NoAction;
            rewrite_smac;
        }
        const default_action = NoAction;
    }
    action rewrite_ipv4_multicast() {
    }
    action rewrite_ipv6_multicast() {
    }
    table multicast_rewrite {
        key = {
            hdr.ipv4.isValid()      : exact;
            hdr.ipv4.dst_addr[31:28]: ternary;
        }
        actions = {
            NoAction;
            rewrite_ipv4_multicast;
            rewrite_ipv6_multicast;
        }
        const default_action = NoAction;
    }
    action rewrite_ipv4() {
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }
    action rewrite_ipv6() {
        hdr.ipv6.hop_limit = hdr.ipv6.hop_limit - 1;
    }
    table ip_rewrite {
        key = {
            hdr.ipv4.isValid(): exact;
            hdr.ipv6.isValid(): exact;
        }
        actions = {
            rewrite_ipv4;
            rewrite_ipv6;
        }
        const entries = {
                        (true, false) : rewrite_ipv4();

                        (false, true) : rewrite_ipv6();

        }

    }
    apply {
        smac_index = 0;
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0)) {
            nexthop_rewrite.apply();
        }
        egress_bd.apply(hdr, eg_md.bd, eg_md.pkt_type, eg_md.pkt_src, eg_md.bd_label, smac_index, eg_md.checks.mtu);
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0) && eg_md.flags.routed) {
            ip_rewrite.apply();
            smac_rewrite.apply();
        }
    }
}

control PortMirror(in switch_port_t port, in switch_pkt_src_t src, inout switch_mirror_metadata_t mirror_md)(switch_uint32_t table_size=288) {
    action set_mirror_id(switch_mirror_session_t session_id) {
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

control L3SubPortStats(in switch_port_t port, in switch_bd_t bd, in switch_pkt_type_t pkt_type)(switch_uint32_t table_size=288) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    action count() {
        stats.count();
    }
    table port_stats {
        key = {
            port    : exact;
            bd      : exact;
            pkt_type: exact;
        }
        actions = {
            count;
            @defaultonly NoAction;
        }
        size = 3 * table_size;
        counters = stats;
    }
    apply {
        port_stats.apply();
    }
}

control Egresss_L3SubPortStats(in switch_port_t port, in switch_bd_t bd, in switch_pkt_type_t pkt_type)(switch_uint32_t table_size=288) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    action count() {
        stats.count();
    }
    table port_stats {
        key = {
            port    : exact;
            bd      : exact;
            pkt_type: exact;
        }
        actions = {
            count;
            @defaultonly NoAction;
        }
        size = 3 * table_size;
        counters = stats;
    }
    apply {
        port_stats.apply();
    }
}

control IngressPortMapping(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(switch_uint32_t port_vlan_table_size, switch_uint32_t bd_table_size, switch_uint32_t port_table_size=288, switch_uint32_t vlan_table_size=4096, switch_uint32_t double_tag_table_size=1024) {
    PortMirror(port_table_size) port_mirror;
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
        ig_md.egress_ifindex = (switch_ifindex_t)hdr.fabric.dst_port_or_group;
        ig_intr_md_for_tm.bypass_egress = hdr.cpu.tx_bypass;
        hdr.ethernet.ether_type = hdr.cpu.ether_type;
    }
    action set_cpu_port_properties(switch_port_lag_index_t port_lag_index, switch_port_lag_label_t port_lag_label, switch_yid_t exclusion_id, switch_qos_trust_mode_t trust_mode, switch_qos_group_t qos_group, switch_pkt_color_t color, switch_tc_t tc) {
        ig_md.port_lag_index = port_lag_index;
        ig_md.port_lag_label = port_lag_label;
        ig_md.qos.trust_mode = trust_mode;
        ig_md.qos.group = qos_group;
        ig_md.qos.color = color;
        ig_md.qos.tc = tc;
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
        terminate_cpu_packet();
    }
    action set_port_properties(switch_yid_t exclusion_id, switch_learning_mode_t learning_mode, switch_qos_trust_mode_t trust_mode, switch_qos_group_t qos_group, switch_pkt_color_t color, switch_tc_t tc, bool mac_pkt_class) {
        ig_md.qos.trust_mode = trust_mode;
        ig_md.qos.group = qos_group;
        ig_md.qos.color = color;
        ig_md.qos.tc = tc;
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
        ig_md.learning.port_mode = learning_mode;
        ig_md.checks.same_if = 0xffff;
        ig_md.flags.mac_pkt_class = mac_pkt_class;
    }
    action set_fabric_port_properties(switch_yid_t exclusion_id, switch_learning_mode_t learning_mode, switch_qos_trust_mode_t trust_mode, switch_qos_group_t qos_group, switch_pkt_color_t color, switch_tc_t tc, bool mac_pkt_class) {
        ig_md.qos.trust_mode = trust_mode;
        ig_md.qos.group = qos_group;
        ig_md.qos.color = color;
        ig_md.qos.tc = tc;
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
        ig_md.learning.port_mode = learning_mode;
        ig_md.checks.same_if = 0xffff;
        ig_md.flags.mac_pkt_class = mac_pkt_class;
        ig_md.port_type = SWITCH_PORT_TYPE_FABRIC;
    }
    table port_mapping {
        key = {
            ig_md.port          : exact;
            hdr.cpu.isValid()   : exact;
            hdr.cpu.ingress_port: exact;
        }
        actions = {
            set_port_properties;
            set_cpu_port_properties;
        }
        size = port_table_size * 2;
    }
    action port_vlan_miss() {
    }
    action set_bd_properties(switch_bd_t bd, switch_vrf_t vrf, switch_bd_label_t bd_label, switch_rid_t rid, switch_stp_group_t stp_group, switch_learning_mode_t learning_mode, bool ipv4_unicast_enable, bool ipv4_multicast_enable, bool igmp_snooping_enable, bool ipv6_unicast_enable, bool ipv6_multicast_enable, bool mld_snooping_enable, switch_multicast_rpf_group_t mrpf_group, switch_rmac_group_t rmac_group) {
        ig_md.bd = bd;
        ig_md.bd_label = bd_label;
        ig_md.vrf = vrf;
        ig_intr_md_for_tm.rid = rid;
        ig_md.rmac_group = rmac_group;
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
            ig_md.port_lag_index     : exact;
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
    action set_interface_properties(switch_ifindex_t ifindex, switch_if_label_t if_label) {
        ig_md.ifindex = ifindex;
        ig_md.checks.same_if = 0xffff;
        ig_md.if_label = if_label;
    }
    table port_vlan_to_ifindex_mapping {
        key = {
            ig_md.port_lag_index: exact;
            hdr.vlan_tag[0].vid : exact;
        }
        actions = {
            NoAction;
            set_interface_properties;
        }
        const default_action = NoAction;
        size = port_vlan_table_size;
    }
    table port_to_ifindex_mapping {
        key = {
            ig_md.port_lag_index: exact;
        }
        actions = {
            NoAction;
            set_interface_properties;
        }
        const default_action = NoAction;
        size = port_table_size;
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
        switch (port_mapping.apply().action_run) {
            set_cpu_port_properties: {
                cpu_to_bd_mapping.apply();
            }
            set_port_properties: {
                if (!port_vlan_to_bd_mapping.apply().hit) {
                    if (hdr.vlan_tag[0].isValid()) {
                        vlan_to_bd_mapping.apply();
                    }
                }
            }
        }

        if (hdr.vlan_tag[0].isValid()) {
            if (!port_vlan_to_ifindex_mapping.apply().hit) {
                port_to_ifindex_mapping.apply();
            }
        } else {
            port_to_ifindex_mapping.apply();
        }
        if (hdr.vlan_tag[0].isValid() && !hdr.vlan_tag[1].isValid() && (bit<1>)ig_md.flags.port_vlan_miss == 0) {
            bit<32> pv_hash_ = hash.get({ ig_md.port[6:0], hdr.vlan_tag[0].vid });
            ig_md.flags.port_vlan_miss = (bool)check_vlan_membership.execute(pv_hash_);
        }
        port_mirror.apply(ig_md.port, SWITCH_PKT_SRC_CLONED_INGRESS, ig_md.mirror);
    }
}

control LAG(inout switch_ingress_metadata_t ig_md, in bit<16> hash, out switch_port_t egress_port) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(1024, selector_hash, SelectorMode_t.FAIR) lag_selector;
    action set_lag_port(switch_port_t port) {
        egress_port = port;
    }
    action set_peer_link_port(switch_port_t port, switch_ifindex_t ifindex) {
    }
    action set_lag_remote_port(switch_port_t port, bit<8> dst_device) {
        egress_port = port;
        ig_md.fabric_metadata.dst_device = dst_device;
    }
    action lag_miss() {
    }
    table lag {
        key = {
            ig_md.egress_ifindex: exact @name("port_lag_index") ;
            hash                : selector;
        }
        actions = {
            lag_miss;
            set_lag_port;
            set_peer_link_port;
            set_lag_remote_port;
        }
        const default_action = lag_miss;
        size = 1024;
        implementation = lag_selector;
    }
    table lag_wcmp {
        key = {
            ig_md.egress_ifindex: exact @name("port_lag_index") ;
            hash                : range;
        }
        actions = {
            lag_miss;
            set_lag_port;
            set_peer_link_port;
        }
        const default_action = lag_miss;
        size = 1024;
    }
    apply {
        if (!lag.apply().hit) {
            lag_wcmp.apply();
        }
    }
}

control EgressPortMapping(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, in switch_port_t port)(switch_uint32_t table_size=288) {
    PortMirror(table_size) port_mirror;
    action port_normal(switch_port_lag_index_t port_lag_index, switch_port_lag_label_t port_lag_label, switch_qos_group_t qos_group, bool mlag_member) {
        eg_md.port_lag_index = port_lag_index;
        eg_md.port_lag_label = port_lag_label;
        eg_md.qos.group = qos_group;
        eg_md.flags.mlag_member = mlag_member;
    }
    action port_fabric() {
        eg_md.port_type = SWITCH_PORT_TYPE_FABRIC;
        eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_FABRIC;
        eg_md.checks.mtu = 0xffff;
    }
    action cpu_rewrite() {
        hdr.fabric.setValid();
        hdr.fabric.color = 0;
        hdr.fabric.qos = 0;
        hdr.fabric.dst_port_or_group = 0;
        hdr.cpu.setValid();
        hdr.cpu.egress_queue = 0;
        hdr.cpu.tx_bypass = 0;
        hdr.cpu.capture_ts = 0;
        hdr.cpu.reserved = 0;
        hdr.cpu.ingress_port = (bit<16>)eg_md.ingress_port;
        hdr.cpu.ingress_ifindex = (bit<16>)eg_md.ingress_ifindex;
        hdr.cpu.ingress_bd = (bit<16>)eg_md.bd;
        hdr.cpu.reason_code = eg_md.cpu_reason;
        hdr.cpu.ether_type = hdr.ethernet.ether_type;
        hdr.ethernet.ether_type = 0x9000;
    }
    action port_cpu(switch_port_lag_index_t port_lag_index) {
        cpu_rewrite();
    }
    @ignore_table_dependency("SwitchEgress.mirror_rewrite.rewrite") table port_mapping {
        key = {
            port: exact;
        }
        actions = {
            port_normal;
            port_cpu;
            port_fabric;
        }
        size = table_size;
    }
    apply {
        port_mapping.apply();
        port_mirror.apply(port, SWITCH_PKT_SRC_CLONED_EGRESS, eg_md.mirror);
    }
}

control PktValidation(in switch_header_t hdr, inout switch_ingress_flags_t flags, inout switch_lookup_fields_t lkp, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm, out switch_drop_reason_t drop_reason) {
    const switch_uint32_t table_size = 64;
    action init_l4_lkp_ports() {
        lkp.l4_src_port = 0;
        lkp.l4_dst_port = 0;
    }
    action malformed_pkt(bit<8> reason) {
        drop_reason = reason;
    }
    action malformed_non_ip_pkt(bit<8> reason) {
        init_l4_lkp_ports();
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.ethernet.ether_type;
        malformed_pkt(reason);
    }
    action valid_unicast_pkt_untagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_UNICAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.ethernet.ether_type;
    }
    action valid_multicast_pkt_untagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_MULTICAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.ethernet.ether_type;
    }
    action valid_broadcast_pkt_untagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_BROADCAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.ethernet.ether_type;
    }
    action valid_unicast_pkt_tagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_UNICAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.vlan_tag[0].ether_type;
        lkp.pcp = hdr.vlan_tag[0].pcp;
    }
    action valid_multicast_pkt_tagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_MULTICAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.vlan_tag[0].ether_type;
        lkp.pcp = hdr.vlan_tag[0].pcp;
    }
    action valid_broadcast_pkt_tagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_BROADCAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.vlan_tag[0].ether_type;
        lkp.pcp = hdr.vlan_tag[0].pcp;
    }
    action valid_unicast_pkt_double_tagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_UNICAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.vlan_tag[1].ether_type;
        lkp.pcp = hdr.vlan_tag[1].pcp;
    }
    table validate_ethernet {
        key = {
            hdr.ethernet.src_addr    : ternary;
            hdr.ethernet.dst_addr    : ternary;
            hdr.vlan_tag[0].isValid(): ternary;
        }
        actions = {
            malformed_non_ip_pkt;
            valid_unicast_pkt_untagged;
            valid_multicast_pkt_untagged;
            valid_broadcast_pkt_untagged;
            valid_unicast_pkt_tagged;
            valid_multicast_pkt_tagged;
            valid_broadcast_pkt_tagged;
        }
        size = table_size;
    }
    action malformed_ipv4_pkt(bit<8> reason) {
        lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        lkp.ip_tos = hdr.ipv4.diffserv;
        lkp.ip_proto = hdr.ipv4.protocol;
        lkp.ip_ttl = hdr.ipv4.ttl;
        lkp.ip_src_addr = (bit<128>)hdr.ipv4.src_addr;
        lkp.ip_dst_addr = (bit<128>)hdr.ipv4.dst_addr;
        malformed_pkt(reason);
    }
    action valid_ipv4_pkt(switch_ip_frag_t ip_frag) {
        lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        lkp.ip_tos = hdr.ipv4.diffserv;
        lkp.ip_proto = hdr.ipv4.protocol;
        lkp.ip_ttl = hdr.ipv4.ttl;
        lkp.ip_src_addr = (bit<128>)hdr.ipv4.src_addr;
        lkp.ip_dst_addr = (bit<128>)hdr.ipv4.dst_addr;
        lkp.ip_frag = ip_frag;
    }
    table validate_ipv4 {
        key = {
            flags.ipv4_checksum_err : ternary;
            hdr.ipv4.version        : ternary;
            hdr.ipv4.ihl            : ternary;
            hdr.ipv4.flags          : ternary;
            hdr.ipv4.frag_offset    : ternary;
            hdr.ipv4.ttl            : ternary;
            hdr.ipv4.src_addr[31:24]: ternary;
        }
        actions = {
            valid_ipv4_pkt;
            malformed_ipv4_pkt;
        }
        size = table_size;
    }
    action malformed_ipv6_pkt(bit<8> reason) {
        lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        lkp.ip_tos = hdr.ipv6.traffic_class;
        lkp.ip_proto = hdr.ipv6.next_hdr;
        lkp.ip_ttl = hdr.ipv6.hop_limit;
        lkp.ip_src_addr = hdr.ipv6.src_addr;
        lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        malformed_pkt(reason);
    }
    action valid_ipv6_pkt(bool is_link_local) {
        lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        lkp.ip_tos = hdr.ipv6.traffic_class;
        lkp.ip_proto = hdr.ipv6.next_hdr;
        lkp.ip_ttl = hdr.ipv6.hop_limit;
        lkp.ip_src_addr = hdr.ipv6.src_addr;
        lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        flags.link_local = is_link_local;
    }
    table validate_ipv6 {
        key = {
            hdr.ipv6.version         : ternary;
            hdr.ipv6.hop_limit       : ternary;
            hdr.ipv6.src_addr[127:96]: ternary;
        }
        actions = {
            valid_ipv6_pkt;
            malformed_ipv6_pkt;
        }
        size = table_size;
    }
    action set_tcp_ports() {
        lkp.l4_src_port = hdr.tcp.src_port;
        lkp.l4_dst_port = hdr.tcp.dst_port;
        lkp.tcp_flags = hdr.tcp.flags;
    }
    action set_udp_ports() {
        lkp.l4_src_port = hdr.udp.src_port;
        lkp.l4_dst_port = hdr.udp.dst_port;
    }
    action set_icmp_type() {
        lkp.l4_src_port[7:0] = hdr.icmp.type;
        lkp.l4_src_port[15:8] = hdr.icmp.code;
        lkp.l4_dst_port = 0;
    }
    action set_igmp_type() {
        lkp.l4_src_port = 0;
        lkp.l4_dst_port = 0;
    }
    action set_arp_opcode() {
        init_l4_lkp_ports();
        lkp.arp_opcode = hdr.arp.opcode;
    }
    table validate_other {
        key = {
            hdr.tcp.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.icmp.isValid(): exact;
            hdr.igmp.isValid(): exact;
            hdr.arp.isValid() : exact;
        }
        actions = {
            init_l4_lkp_ports;
            set_tcp_ports;
            set_udp_ports;
            set_icmp_type;
            set_igmp_type;
            set_arp_opcode;
        }
        const default_action = init_l4_lkp_ports;
        const entries = {
                        (true, false, false, false, false) : set_tcp_ports();

                        (false, true, false, false, false) : set_udp_ports();

                        (false, false, true, false, false) : set_icmp_type();

                        (false, false, false, true, false) : set_igmp_type();

                        (false, false, false, false, true) : set_arp_opcode();

        }

    }
    apply {
        flags.link_local = false;
        lkp.mac_src_addr = 0;
        lkp.mac_dst_addr = 0;
        lkp.mac_type = 0;
        lkp.pcp = 0;
        lkp.arp_opcode = 0;
        lkp.ip_type = 0;
        lkp.ip_tos = 0;
        lkp.ip_proto = 0;
        lkp.ip_ttl = 0;
        lkp.ip_src_addr = 0;
        lkp.ip_dst_addr = 0;
        lkp.ip_frag = 0;
        switch (validate_ethernet.apply().action_run) {
            malformed_non_ip_pkt: {
            }
            default: {
                if (hdr.ipv4.isValid()) {
                    validate_ipv4.apply();
                } else if (hdr.ipv6.isValid()) {
                    validate_ipv6.apply();
                }
                validate_other.apply();
            }
        }

    }
}

control InnerPktValidation(in switch_header_t hdr, inout switch_lookup_fields_t lkp, inout switch_ingress_flags_t flags, inout switch_drop_reason_t drop_reason) {
    action valid_unicast_pkt() {
        lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
        lkp.mac_type = hdr.inner_ethernet.ether_type;
        lkp.pkt_type = SWITCH_PKT_TYPE_UNICAST;
    }
    action valid_multicast_pkt() {
        lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
        lkp.mac_type = hdr.inner_ethernet.ether_type;
        lkp.pkt_type = SWITCH_PKT_TYPE_MULTICAST;
    }
    action valid_broadcast_pkt() {
        lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
        lkp.mac_type = hdr.inner_ethernet.ether_type;
        lkp.pkt_type = SWITCH_PKT_TYPE_BROADCAST;
    }
    action malformed_pkt(bit<8> reason) {
        drop_reason = reason;
    }
    table validate_ethernet {
        key = {
            hdr.inner_ethernet.isValid(): exact;
            hdr.inner_ethernet.dst_addr : ternary;
        }
        actions = {
            NoAction;
            valid_unicast_pkt;
            valid_multicast_pkt;
            valid_broadcast_pkt;
            malformed_pkt;
        }
    }
    action valid_ipv4_pkt() {
        lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        lkp.ip_tos = hdr.inner_ipv4.diffserv;
        lkp.ip_ttl = hdr.inner_ipv4.ttl;
        lkp.ip_proto = hdr.inner_ipv4.protocol;
        lkp.ip_src_addr = (bit<128>)hdr.inner_ipv4.src_addr;
        lkp.ip_dst_addr = (bit<128>)hdr.inner_ipv4.dst_addr;
    }
    table validate_ipv4 {
        key = {
            flags.inner_ipv4_checksum_err: ternary;
            hdr.inner_ipv4.version       : ternary;
            hdr.inner_ipv4.ihl           : ternary;
            hdr.inner_ipv4.ttl           : ternary;
        }
        actions = {
            valid_ipv4_pkt;
            malformed_pkt;
        }
    }
    action valid_ipv6_pkt() {
        lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        lkp.ip_tos = hdr.inner_ipv6.traffic_class;
        lkp.ip_ttl = hdr.inner_ipv6.hop_limit;
        lkp.ip_proto = hdr.inner_ipv6.next_hdr;
        lkp.ip_src_addr = hdr.inner_ipv6.src_addr;
        lkp.ip_dst_addr = hdr.inner_ipv6.dst_addr;
        flags.link_local = false;
    }
    table validate_ipv6 {
        key = {
            hdr.inner_ipv6.version  : ternary;
            hdr.inner_ipv6.hop_limit: ternary;
        }
        actions = {
            valid_ipv6_pkt;
            malformed_pkt;
        }
        const entries = {
                        (0 &&& 0, 0) : malformed_pkt(SWITCH_DROP_REASON_IP_IHL_INVALID);

                        (6, 0 &&& 0) : valid_ipv6_pkt();

                        (0 &&& 0, 0 &&& 0) : malformed_pkt(SWITCH_DROP_REASON_IP_VERSION_INVALID);

        }

    }
    action set_tcp_ports() {
        lkp.l4_src_port = hdr.inner_tcp.src_port;
        lkp.l4_dst_port = hdr.inner_tcp.dst_port;
    }
    action set_udp_ports() {
        lkp.l4_src_port = hdr.inner_udp.src_port;
        lkp.l4_dst_port = hdr.inner_udp.dst_port;
    }
    table validate_other {
        key = {
            hdr.inner_tcp.isValid(): exact;
            hdr.inner_udp.isValid(): exact;
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
        switch (validate_ethernet.apply().action_run) {
            malformed_pkt: {
            }
            default: {
                if (hdr.inner_ipv4.isValid()) {
                    validate_ipv4.apply();
                } else if (hdr.inner_ipv6.isValid()) {
                    validate_ipv6.apply();
                }
                validate_other.apply();
            }
        }

    }
}

control MulticastBridge<T>(in ipv4_addr_t src_addr, in ipv4_addr_t grp_addr, in switch_bd_t bd, out switch_mgid_t group_id, out bit<1> multicast_hit)(switch_uint32_t s_g_table_size, switch_uint32_t star_g_table_size) {
    action s_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }
    action star_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }
    action star_g_miss() {
        multicast_hit = 0;
    }
    table s_g {
        key = {
            bd      : exact;
            src_addr: exact;
            grp_addr: exact;
        }
        actions = {
            NoAction;
            s_g_hit;
        }
        const default_action = NoAction;
        size = s_g_table_size;
    }
    table star_g {
        key = {
            bd      : exact;
            grp_addr: exact;
        }
        actions = {
            star_g_miss;
            star_g_hit;
        }
        const default_action = star_g_miss;
        size = star_g_table_size;
    }
    apply {
        switch (s_g.apply().action_run) {
            NoAction: {
                star_g.apply();
            }
        }

    }
}

control MulticastBridgev6<T>(in ipv6_addr_t src_addr, in ipv6_addr_t grp_addr, in switch_bd_t bd, out switch_mgid_t group_id, out bit<1> multicast_hit)(switch_uint32_t s_g_table_size, switch_uint32_t star_g_table_size) {
    action s_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }
    action star_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }
    action star_g_miss() {
        multicast_hit = 0;
    }
    table s_g {
        key = {
            bd      : exact;
            src_addr: exact;
            grp_addr: exact;
        }
        actions = {
            NoAction;
            s_g_hit;
        }
        const default_action = NoAction;
        size = s_g_table_size;
    }
    table star_g {
        key = {
            bd      : exact;
            grp_addr: exact;
        }
        actions = {
            star_g_miss;
            star_g_hit;
        }
        const default_action = star_g_miss;
        size = star_g_table_size;
    }
    apply {
        switch (s_g.apply().action_run) {
            NoAction: {
                star_g.apply();
            }
        }

    }
}

control MulticastRoute<T>(in ipv4_addr_t src_addr, in ipv4_addr_t grp_addr, in switch_vrf_t vrf, inout switch_multicast_metadata_t multicast_md, out switch_multicast_rpf_group_t rpf_check, out switch_mgid_t multicast_group_id, out bit<1> multicast_hit)(switch_uint32_t s_g_table_size, switch_uint32_t star_g_table_size) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS) s_g_stats;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) star_g_stats;
    action s_g_hit(switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        s_g_stats.count();
    }
    action star_g_hit_bidir(switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group & multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_BIDIR;
        star_g_stats.count();
    }
    action star_g_hit_sm(switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        star_g_stats.count();
    }
    table s_g {
        key = {
            vrf     : exact;
            src_addr: exact;
            grp_addr: exact;
        }
        actions = {
            @defaultonly NoAction;
            s_g_hit;
        }
        const default_action = NoAction;
        size = s_g_table_size;
        counters = s_g_stats;
    }
    table star_g {
        key = {
            vrf     : exact;
            grp_addr: exact;
        }
        actions = {
            @defaultonly NoAction;
            star_g_hit_sm;
            star_g_hit_bidir;
        }
        const default_action = NoAction;
        size = star_g_table_size;
        counters = star_g_stats;
    }
    apply {
        if (!s_g.apply().hit) {
            star_g.apply();
        }
    }
}

control MulticastRoutev6<T>(in ipv6_addr_t src_addr, in ipv6_addr_t grp_addr, in switch_vrf_t vrf, inout switch_multicast_metadata_t multicast_md, out switch_multicast_rpf_group_t rpf_check, out switch_mgid_t multicast_group_id, out bit<1> multicast_hit)(switch_uint32_t s_g_table_size, switch_uint32_t star_g_table_size) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS) s_g_stats;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) star_g_stats;
    action s_g_hit(switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        s_g_stats.count();
    }
    action star_g_hit_bidir(switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group & multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_BIDIR;
        star_g_stats.count();
    }
    action star_g_hit_sm(switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        star_g_stats.count();
    }
    table s_g {
        key = {
            vrf     : exact;
            src_addr: exact;
            grp_addr: exact;
        }
        actions = {
            @defaultonly NoAction;
            s_g_hit;
        }
        const default_action = NoAction;
        size = s_g_table_size;
        counters = s_g_stats;
    }
    table star_g {
        key = {
            vrf     : exact;
            grp_addr: exact;
        }
        actions = {
            @defaultonly NoAction;
            star_g_hit_sm;
            star_g_hit_bidir;
        }
        const default_action = NoAction;
        size = star_g_table_size;
        counters = star_g_stats;
    }
    apply {
        if (!s_g.apply().hit) {
            star_g.apply();
        }
    }
}

control IngressMulticast(in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md)(switch_uint32_t ipv4_s_g_table_size, switch_uint32_t ipv4_star_g_table_size, switch_uint32_t ipv6_s_g_table_size, switch_uint32_t ipv6_star_g_table_size) {
    MulticastBridge<ipv4_addr_t>(ipv4_s_g_table_size, ipv4_star_g_table_size) ipv4_multicast_bridge;
    MulticastRoute<ipv4_addr_t>(ipv4_s_g_table_size, ipv4_star_g_table_size) ipv4_multicast_route;
    MulticastBridgev6<ipv6_addr_t>(ipv6_s_g_table_size, ipv6_star_g_table_size) ipv6_multicast_bridge;
    MulticastRoutev6<ipv6_addr_t>(ipv6_s_g_table_size, ipv6_star_g_table_size) ipv6_multicast_route;
    switch_multicast_rpf_group_t rpf_check;
    bit<1> multicast_hit;
    action set_multicast_route() {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_ifindex = 0;
        ig_md.checks.mrpf = true;
        ig_md.flags.routed = true;
        ig_md.checks.same_bd = 0x3fff;
    }
    action set_multicast_bridge(bool mrpf) {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_ifindex = 0;
        ig_md.checks.mrpf = mrpf;
        ig_md.flags.routed = false;
    }
    action set_multicast_flood(bool mrpf, bool flood) {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_ifindex = SWITCH_IFINDEX_FLOOD;
        ig_md.checks.mrpf = mrpf;
        ig_md.flags.routed = false;
        ig_md.flags.flood_to_multicast_routers = flood;
    }
    table fwd_result {
        key = {
            multicast_hit                : ternary;
            lkp.ip_type                  : ternary;
            ig_md.ipv4.multicast_snooping: ternary;
            ig_md.ipv6.multicast_snooping: ternary;
            ig_md.multicast.mode         : ternary;
            rpf_check                    : ternary;
        }
        actions = {
            set_multicast_bridge;
            set_multicast_route;
            set_multicast_flood;
        }
    }
    apply {
        if (lkp.ip_type == SWITCH_IP_TYPE_IPV4 && ig_md.ipv4.multicast_enable) {
            ipv4_multicast_route.apply(lkp.ip_src_addr[31:0], lkp.ip_dst_addr[31:0], ig_md.vrf, ig_md.multicast, rpf_check, ig_md.multicast.id, multicast_hit);
        } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6 && ig_md.ipv6.multicast_enable) {
            ipv6_multicast_route.apply(lkp.ip_src_addr, lkp.ip_dst_addr, ig_md.vrf, ig_md.multicast, rpf_check, ig_md.multicast.id, multicast_hit);
        }
        if (multicast_hit == 0 || ig_md.multicast.mode == SWITCH_MULTICAST_MODE_PIM_SM && rpf_check != 0 || ig_md.multicast.mode == SWITCH_MULTICAST_MODE_PIM_BIDIR && rpf_check == 0) {
            if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                ipv4_multicast_bridge.apply(lkp.ip_src_addr[31:0], lkp.ip_dst_addr[31:0], ig_md.bd, ig_md.multicast.id, multicast_hit);
            } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
                ipv6_multicast_bridge.apply(lkp.ip_src_addr, lkp.ip_dst_addr, ig_md.bd, ig_md.multicast.id, multicast_hit);
            }
        }
        fwd_result.apply();
    }
}

control MulticastFlooding(inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size) {
    action flood(switch_mgid_t mgid) {
        ig_md.multicast.id = mgid;
    }
    table bd_flood {
        key = {
            ig_md.bd                              : exact @name("bd") ;
            ig_md.lkp.pkt_type                    : exact @name("pkt_type") ;
            ig_md.tunnel.terminate                : exact;
            ig_md.flags.flood_to_multicast_routers: exact @name("flood_to_multicast_routers") ;
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
    action rid_tunnel_hit(switch_bd_t bd, switch_tunnel_index_t tunnel_index, switch_nexthop_t nexthop_index) {
        eg_md.checks.same_bd = bd ^ eg_md.bd;
        eg_md.bd = bd;
        eg_md.tunnel.index = tunnel_index;
        eg_md.nexthop = nexthop_index;
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
            rid_tunnel_hit;
        }
        size = table_size;
        const default_action = rid_miss;
    }
    apply {
        if (replication_id != 0) {
            rid.apply();
        }
        if (eg_md.checks.same_bd == 0) {
            eg_md.flags.routed = false;
        }
    }
}

control IngressPolicer(in switch_ingress_metadata_t ig_md, inout switch_qos_metadata_t qos_md, out bool flag)(switch_uint32_t table_size=1024) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    DirectMeter(MeterType_t.BYTES) meter;
    action meter_deny() {
        stats.count();
        flag = true;
        qos_md.color = qos_md.acl_policer_color;
    }
    action meter_permit() {
        stats.count();
    }
    table meter_action {
        key = {
            qos_md.acl_policer_color: exact;
            qos_md.meter_index      : exact;
        }
        actions = {
            meter_permit;
            meter_deny;
        }
        const default_action = meter_permit;
        size = 3 * table_size;
        counters = stats;
    }
    action set_color() {
        qos_md.acl_policer_color = (bit<2>)meter.execute();
    }
    table meter_index {
        key = {
            qos_md.meter_index: exact;
        }
        actions = {
            @defaultonly NoAction;
            set_color;
        }
        const default_action = NoAction;
        size = table_size;
        meters = meter;
    }
    apply {
        flag = false;
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_POLICER != 0)) {
            meter_index.apply();
        }
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_POLICER != 0)) {
            meter_action.apply();
        }
    }
}

control StormControl(inout switch_ingress_metadata_t ig_md, in switch_pkt_type_t pkt_type, out bool flag)(switch_uint32_t table_size=512) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS) storm_control_stats;
    Meter<bit<16>>(table_size, MeterType_t.BYTES) meter;
    action count() {
        storm_control_stats.count();
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
        size = table_size;
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
        ig_md.qos.storm_control_color = 0;
    }
}

control PortPolicer(in switch_port_t port, out bool flag)(switch_uint32_t table_size=288) {
    DirectCounter<bit<32>>(CounterType_t.BYTES) stats;
    Meter<bit<9>>(table_size, MeterType_t.BYTES) meter;
    switch_pkt_color_t color;
    action permit_and_count() {
        stats.count();
        flag = false;
    }
    action drop_and_count() {
        stats.count();
        flag = true;
    }
    table meter_action {
        key = {
            color: exact;
            port : exact;
        }
        actions = {
            @defaultonly NoAction;
            permit_and_count;
            drop_and_count;
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
            port: exact;
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

control PortPolicer2(in switch_port_t port, out bool flag)(switch_uint32_t table_size=288) {
    DirectCounter<bit<32>>(CounterType_t.BYTES) stats;
    Meter<bit<9>>(table_size, MeterType_t.BYTES) meter;
    switch_pkt_color_t color;
    action permit_and_count() {
        stats.count();
        flag = false;
    }
    action drop_and_count() {
        stats.count();
        flag = true;
    }
    table meter_action {
        key = {
            color: exact;
            port : exact;
        }
        actions = {
            @defaultonly NoAction;
            permit_and_count;
            drop_and_count;
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
            port: exact;
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

action set_ingress_tc(inout switch_qos_metadata_t qos_md, switch_tc_t tc) {
    qos_md.tc = tc;
}
action set_ingress_color(inout switch_qos_metadata_t qos_md, switch_pkt_color_t color) {
    qos_md.color = color;
}
action set_ingress_tc_and_color(inout switch_qos_metadata_t qos_md, switch_tc_t tc, switch_pkt_color_t color) {
    set_ingress_tc(qos_md, tc);
    set_ingress_color(qos_md, color);
}
action set_ingress_meter(inout switch_qos_metadata_t qos_md, switch_policer_meter_index_t index) {
    qos_md.meter_index = index;
}
action set_ingress_tc_color_and_meter(inout switch_qos_metadata_t qos_md, switch_tc_t tc, switch_pkt_color_t color, switch_policer_meter_index_t index) {
    set_ingress_tc_and_color(qos_md, tc, color);
    qos_md.meter_index = index;
}
control MacQosAcl(in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.mac_src_addr    : ternary;
            lkp.mac_dst_addr    : ternary;
            lkp.mac_type        : ternary;
            ig_md.port_lag_label: ternary;
            lkp.pcp             : ternary;
        }
        actions = {
            NoAction;
            set_ingress_tc(ig_md.qos);
            set_ingress_color(ig_md.qos);
            set_ingress_tc_and_color(ig_md.qos);
            set_ingress_meter(ig_md.qos);
            set_ingress_tc_color_and_meter(ig_md.qos);
        }
        size = table_size;
    }
    apply {
        acl.apply();
    }
}

control Ipv4QosAcl(in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.ip_src_addr[31:0]: ternary;
            lkp.ip_dst_addr[31:0]: ternary;
            lkp.ip_proto         : ternary;
            lkp.ip_tos           : ternary;
            lkp.l4_src_port      : ternary;
            lkp.l4_dst_port      : ternary;
            lkp.ip_ttl           : ternary;
            lkp.ip_frag          : ternary;
            lkp.tcp_flags        : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label       : ternary;
            ig_md.l4_port_label  : ternary;
        }
        actions = {
            NoAction;
            set_ingress_tc(ig_md.qos);
            set_ingress_color(ig_md.qos);
            set_ingress_tc_and_color(ig_md.qos);
            set_ingress_meter(ig_md.qos);
            set_ingress_tc_color_and_meter(ig_md.qos);
        }
        size = table_size;
    }
    apply {
        acl.apply();
    }
}

control Ipv6QosAcl(in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.ip_src_addr     : ternary;
            lkp.ip_dst_addr     : ternary;
            lkp.ip_proto        : ternary;
            lkp.ip_tos          : ternary;
            lkp.l4_src_port     : ternary;
            lkp.l4_dst_port     : ternary;
            lkp.ip_ttl          : ternary;
            lkp.tcp_flags       : ternary;
            ig_md.port_lag_label: ternary;
            ig_md.bd_label      : ternary;
            ig_md.l4_port_label : ternary;
        }
        actions = {
            NoAction;
            set_ingress_tc(ig_md.qos);
            set_ingress_color(ig_md.qos);
            set_ingress_tc_and_color(ig_md.qos);
            set_ingress_meter(ig_md.qos);
            set_ingress_tc_color_and_meter(ig_md.qos);
        }
        size = table_size;
    }
    apply {
        acl.apply();
    }
}

control IpQosAcl(in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.mac_type        : ternary;
            lkp.ip_src_addr     : ternary;
            lkp.ip_dst_addr     : ternary;
            lkp.ip_proto        : ternary;
            lkp.ip_tos          : ternary;
            lkp.l4_src_port     : ternary;
            lkp.l4_dst_port     : ternary;
            lkp.ip_ttl          : ternary;
            lkp.tcp_flags       : ternary;
            ig_md.port_lag_label: ternary;
            ig_md.bd_label      : ternary;
            ig_md.l4_port_label : ternary;
        }
        actions = {
            NoAction;
            set_ingress_tc(ig_md.qos);
            set_ingress_color(ig_md.qos);
            set_ingress_tc_and_color(ig_md.qos);
            set_ingress_meter(ig_md.qos);
            set_ingress_tc_color_and_meter(ig_md.qos);
        }
        size = table_size;
    }
    apply {
        acl.apply();
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
    DirectCounter<bit<16>>(CounterType_t.PACKETS_AND_BYTES) stats;
    action acl_deny() {
        flag = true;
        stats.count();
    }
    table acl {
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
    }
}

control IngressQoS(in switch_header_t hdr, in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md)(switch_uint32_t dscp_map_size=1024, switch_uint32_t pcp_map_size=1024) {
    const bit<32> ppg_table_size = 1024;
    const bit<32> queue_table_size = 1024;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) ppg_stats;
    IngressPolicer(1 << 10) policer;
    MacQosAcl() mac_acl;
    IpQosAcl() ip_acl;
    table dscp_tc_map {
        key = {
            ig_md.qos.group: exact;
            lkp.ip_tos     : exact;
        }
        actions = {
            NoAction;
            set_ingress_tc(ig_md.qos);
            set_ingress_color(ig_md.qos);
            set_ingress_tc_and_color(ig_md.qos);
            set_ingress_tc_color_and_meter(ig_md.qos);
        }
        size = dscp_map_size;
    }
    table pcp_tc_map {
        key = {
            ig_md.qos.group: ternary;
            lkp.pcp        : exact;
        }
        actions = {
            NoAction;
            set_ingress_tc(ig_md.qos);
            set_ingress_color(ig_md.qos);
            set_ingress_tc_and_color(ig_md.qos);
            set_ingress_tc_color_and_meter(ig_md.qos);
        }
        size = pcp_map_size;
    }
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
        size = queue_table_size;
    }
    action count() {
        ppg_stats.count();
    }
    table ppg {
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
        ig_md.qos.color = SWITCH_METER_COLOR_GREEN;
        ig_md.qos.tc = 0;
        ig_md.qos.icos = 0;
        ig_md.qos.qid = 0;
        ig_md.qos.meter_index = 0;
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_QOS != 0)) {
            if (ig_md.qos.trust_mode & SWITCH_QOS_TRUST_MODE_TRUST_DSCP == SWITCH_QOS_TRUST_MODE_TRUST_DSCP && lkp.ip_type != SWITCH_IP_TYPE_NONE) {
                dscp_tc_map.apply();
            } else if (ig_md.qos.trust_mode & SWITCH_QOS_TRUST_MODE_TRUST_PCP == SWITCH_QOS_TRUST_MODE_TRUST_PCP && hdr.vlan_tag[0].isValid()) {
                pcp_tc_map.apply();
            }
        }
        policer.apply(ig_md, ig_md.qos, ig_md.flags.acl_policer_drop);
        traffic_class.apply();
        ppg.apply();
    }
}

control EgressQoS(inout switch_header_t hdr, in switch_port_t port, inout switch_egress_metadata_t eg_md)(switch_uint32_t table_size=1024) {
    const bit<32> queue_table_size = 1024;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) queue_stats;
    action set_ipv4_dscp(bit<6> dscp) {
        hdr.ipv4.diffserv[7:2] = dscp;
    }
    action set_ipv4_tos(switch_uint8_t tos) {
        hdr.ipv4.diffserv = tos;
    }
    action set_ipv6_dscp(bit<6> dscp) {
        hdr.ipv6.traffic_class[7:2] = dscp;
    }
    action set_ipv6_tos(switch_uint8_t tos) {
        hdr.ipv6.traffic_class = tos;
    }
    action set_vlan_pcp(bit<3> pcp) {
        eg_md.lkp.pcp = pcp;
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
    action count() {
        queue_stats.count();
    }
    table queue {
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
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_QOS != 0)) {
            qos_map.apply();
        }
        queue.apply();
    }
}

control IngressTunnel(in switch_header_t hdr, inout switch_ingress_metadata_t ig_md, inout switch_lookup_fields_t lkp)(switch_uint32_t ipv4_src_vtep_table_size=1024, switch_uint32_t ipv6_src_vtep_table_size=1024, switch_uint32_t ipv4_dst_vtep_table_size=1024, switch_uint32_t ipv6_dst_vtep_table_size=1024, switch_uint32_t vni_mapping_table_size=1024) {
    InnerPktValidation() pkt_validation;
    action rmac_hit() {
    }
    table rmac {
        key = {
            ig_md.rmac_group: exact;
            lkp.mac_dst_addr: exact;
        }
        actions = {
            NoAction;
            rmac_hit;
        }
        const default_action = NoAction;
        size = 1024;
    }
    action src_vtep_hit(switch_ifindex_t ifindex) {
        ig_md.tunnel.ifindex = ifindex;
    }
    action src_vtep_miss() {
    }
    table src_vtep {
        key = {
            lkp.ip_src_addr[31:0]: exact @name("src_addr") ;
            ig_md.vrf            : exact;
            ig_md.tunnel.type    : exact;
        }
        actions = {
            src_vtep_miss;
            src_vtep_hit;
        }
        const default_action = src_vtep_miss;
        size = ipv4_src_vtep_table_size;
    }
    table src_vtepv6 {
        key = {
            lkp.ip_src_addr  : exact @name("src_addr") ;
            ig_md.vrf        : exact;
            ig_md.tunnel.type: exact;
        }
        actions = {
            src_vtep_miss;
            src_vtep_hit;
        }
        const default_action = src_vtep_miss;
        size = ipv6_src_vtep_table_size;
    }
    action dst_vtep_hit() {
    }
    action set_vni_properties(switch_bd_t bd, switch_vrf_t vrf, switch_bd_label_t bd_label, switch_rid_t rid, switch_learning_mode_t learning_mode, bool ipv4_unicast_enable, bool ipv4_multicast_enable, bool igmp_snooping_enable, bool ipv6_unicast_enable, bool ipv6_multicast_enable, bool mld_snooping_enable, switch_multicast_rpf_group_t mrpf_group, switch_rmac_group_t rmac_group) {
        ig_md.bd = bd;
        ig_md.bd_label = bd_label;
        ig_md.vrf = vrf;
        ig_md.rmac_group = rmac_group;
        ig_md.multicast.rpf_group = mrpf_group;
        ig_md.learning.bd_mode = learning_mode;
        ig_md.ipv4.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv4.multicast_enable = ipv4_multicast_enable;
        ig_md.ipv4.multicast_snooping = igmp_snooping_enable;
        ig_md.ipv6.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv6.multicast_enable = ipv6_multicast_enable;
        ig_md.ipv6.multicast_snooping = mld_snooping_enable;
        ig_md.tunnel.terminate = true;
    }
    table dst_vtep {
        key = {
            lkp.ip_src_addr[31:0]: ternary @name("src_addr") ;
            lkp.ip_dst_addr[31:0]: ternary @name("dst_addr") ;
            ig_md.vrf            : exact;
            ig_md.tunnel.type    : exact;
        }
        actions = {
            NoAction;
            dst_vtep_hit;
            set_vni_properties;
        }
        const default_action = NoAction;
    }
    table dst_vtepv6 {
        key = {
            lkp.ip_src_addr  : ternary @name("src_addr") ;
            lkp.ip_dst_addr  : ternary @name("dst_addr") ;
            ig_md.vrf        : exact;
            ig_md.tunnel.type: exact;
        }
        actions = {
            NoAction;
            dst_vtep_hit;
            set_vni_properties;
        }
        const default_action = NoAction;
    }
    table vni_to_bd_mapping {
        key = {
            ig_md.tunnel.id: exact;
        }
        actions = {
            NoAction;
            set_vni_properties;
        }
        default_action = NoAction;
        size = vni_mapping_table_size;
    }
    apply {
        switch (rmac.apply().action_run) {
            rmac_hit: {
                if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                    switch (dst_vtep.apply().action_run) {
                        dst_vtep_hit: {
                            vni_to_bd_mapping.apply();
                            pkt_validation.apply(hdr, lkp, ig_md.flags, ig_md.drop_reason);
                        }
                        set_vni_properties: {
                            pkt_validation.apply(hdr, lkp, ig_md.flags, ig_md.drop_reason);
                        }
                    }

                } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
                    switch (dst_vtepv6.apply().action_run) {
                        dst_vtep_hit: {
                            vni_to_bd_mapping.apply();
                            pkt_validation.apply(hdr, lkp, ig_md.flags, ig_md.drop_reason);
                        }
                        set_vni_properties: {
                            pkt_validation.apply(hdr, lkp, ig_md.flags, ig_md.drop_reason);
                        }
                    }

                }
            }
        }

    }
}

control TunnelDecap(inout switch_header_t hdr, in switch_egress_metadata_t eg_md)(switch_tunnel_mode_t mode) {
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
            hdr.inner_udp.isValid(): exact;
        }
        actions = {
            decap_inner_udp;
            decap_inner_unknown;
        }
        const default_action = decap_inner_unknown;
        const entries = {
                        true : decap_inner_udp();

        }

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
        hdr.ipv4.src_addr = hdr.inner_ipv4.src_addr;
        hdr.ipv4.dst_addr = hdr.inner_ipv4.dst_addr;
        if (mode == switch_tunnel_mode_t.UNIFORM) {
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
        } else if (mode == switch_tunnel_mode_t.PIPE) {
            hdr.ipv6.hop_limit = hdr.inner_ipv6.hop_limit;
            hdr.ipv6.traffic_class = hdr.inner_ipv6.traffic_class;
        }
        hdr.inner_ipv6.setInvalid();
    }
    action invalidate_tunneling_headers() {
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
        hdr.ethernet.ether_type = 0x800;
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
            hdr.inner_ethernet.isValid(): exact;
            hdr.inner_ipv4.isValid()    : exact;
            hdr.inner_ipv6.isValid()    : exact;
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

    }
    apply {
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0) && eg_md.tunnel.terminate) {
            decap_inner_ip.apply();
        }
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0) && eg_md.tunnel.terminate) {
            decap_inner_l4.apply();
        }
    }
}

control TunnelRewrite(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t ipv4_dst_addr_rewrite_table_size=1024, switch_uint32_t ipv6_dst_addr_rewrite_table_size=1024, switch_uint32_t nexthop_rewrite_table_size=512, switch_uint32_t src_addr_rewrite_table_size=1024, switch_uint32_t smac_rewrite_table_size=1024) {
    EgressBd(BD_TABLE_SIZE) egress_bd;
    switch_bd_label_t bd_label;
    switch_smac_index_t smac_index;
    action rewrite_tunnel(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.bd = bd;
        hdr.ethernet.dst_addr = dmac;
    }
    table nexthop_rewrite {
        key = {
            eg_md.outer_nexthop: exact;
        }
        actions = {
            NoAction;
            rewrite_tunnel;
        }
        const default_action = NoAction;
        size = nexthop_rewrite_table_size;
    }
    action rewrite_ipv4_src(ipv4_addr_t src_addr) {
        hdr.ipv4.src_addr = src_addr;
    }
    action rewrite_ipv6_src(ipv6_addr_t src_addr) {
        hdr.ipv6.src_addr = src_addr;
    }
    table src_addr_rewrite {
        key = {
            eg_md.bd: exact;
        }
        actions = {
            rewrite_ipv4_src;
            rewrite_ipv6_src;
        }
        size = src_addr_rewrite_table_size;
    }
    action rewrite_ipv4_dst(ipv4_addr_t dst_addr) {
        hdr.ipv4.dst_addr = dst_addr;
    }
    action rewrite_ipv6_dst(ipv6_addr_t dst_addr) {
        hdr.ipv6.dst_addr = dst_addr;
    }
    table ipv4_dst_addr_rewrite {
        key = {
            eg_md.tunnel.index: exact;
        }
        actions = {
            rewrite_ipv4_dst;
        }
        const default_action = rewrite_ipv4_dst(0);
        size = ipv4_dst_addr_rewrite_table_size;
    }
    table ipv6_dst_addr_rewrite {
        key = {
            eg_md.tunnel.index: exact;
        }
        actions = {
            rewrite_ipv6_dst;
        }
        const default_action = rewrite_ipv6_dst(0);
        size = ipv6_dst_addr_rewrite_table_size;
    }
    action rewrite_smac(mac_addr_t smac) {
        hdr.ethernet.src_addr = smac;
    }
    table smac_rewrite {
        key = {
            smac_index: exact;
        }
        actions = {
            NoAction;
            rewrite_smac;
        }
        const default_action = NoAction;
        size = smac_rewrite_table_size;
    }
    apply {
        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
            nexthop_rewrite.apply();
        }
        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
            egress_bd.apply(hdr, eg_md.bd, eg_md.pkt_type, eg_md.pkt_src, bd_label, smac_index, eg_md.checks.mtu);
        }
        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
            src_addr_rewrite.apply();
        }
        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
            if (hdr.ipv4.isValid()) {
                ipv4_dst_addr_rewrite.apply();
            } else if (hdr.ipv6.isValid()) {
                ipv6_dst_addr_rewrite.apply();
            }
        }
        smac_rewrite.apply();
    }
}

control TunnelEncap(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_tunnel_mode_t mode=switch_tunnel_mode_t.PIPE, switch_uint32_t vni_mapping_table_size=1024) {
    bit<16> payload_len;
    bit<8> ip_proto;
    action set_vni(switch_tunnel_id_t id) {
        eg_md.tunnel.id = id;
    }
    table bd_to_vni_mapping {
        key = {
            eg_md.bd: exact;
        }
        actions = {
            NoAction;
            set_vni;
        }
        size = vni_mapping_table_size;
    }
    action copy_ipv4_header() {
        hdr.inner_ipv4.setValid();
        hdr.inner_ipv4.version = hdr.ipv4.version;
        hdr.inner_ipv4.ihl = hdr.ipv4.ihl;
        hdr.inner_ipv4.diffserv = hdr.ipv4.diffserv;
        hdr.inner_ipv4.total_len = hdr.ipv4.total_len;
        hdr.inner_ipv4.identification = hdr.ipv4.identification;
        hdr.inner_ipv4.flags = hdr.ipv4.flags;
        hdr.inner_ipv4.frag_offset = hdr.ipv4.frag_offset;
        hdr.inner_ipv4.ttl = hdr.ipv4.ttl;
        hdr.inner_ipv4.protocol = hdr.ipv4.protocol;
        hdr.inner_ipv4.src_addr = hdr.ipv4.src_addr;
        hdr.inner_ipv4.dst_addr = hdr.ipv4.dst_addr;
        hdr.ipv4.setInvalid();
    }
    action copy_ipv6_header() {
        hdr.inner_ipv6.version = hdr.ipv6.version;
        hdr.inner_ipv6.flow_label = hdr.ipv6.flow_label;
        hdr.inner_ipv6.payload_len = hdr.ipv6.payload_len;
        hdr.inner_ipv6.src_addr = hdr.ipv6.src_addr;
        hdr.inner_ipv6.dst_addr = hdr.ipv6.dst_addr;
        hdr.inner_ipv6.hop_limit = hdr.ipv6.hop_limit;
        hdr.inner_ipv6.traffic_class = hdr.ipv6.traffic_class;
        hdr.ipv6.setInvalid();
    }
    action rewrite_inner_ipv4_udp() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        hdr.inner_udp = hdr.udp;
        hdr.udp.setInvalid();
        ip_proto = 4;
    }
    action rewrite_inner_ipv4_tcp() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        hdr.inner_tcp = hdr.tcp;
        hdr.tcp.setInvalid();
        ip_proto = 4;
    }
    action rewrite_inner_ipv4_unknown() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        ip_proto = 4;
    }
    action rewrite_inner_ipv6_udp() {
        payload_len = hdr.ipv6.payload_len + 16w40;
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_udp = hdr.udp;
        hdr.udp.setInvalid();
        hdr.ipv6.setInvalid();
        ip_proto = 41;
    }
    action rewrite_inner_ipv6_tcp() {
        payload_len = hdr.ipv6.payload_len + 16w40;
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_tcp = hdr.tcp;
        hdr.tcp.setInvalid();
        hdr.ipv6.setInvalid();
        ip_proto = 41;
    }
    action rewrite_inner_ipv6_unknown() {
        payload_len = hdr.ipv6.payload_len + 16w40;
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.ipv6.setInvalid();
        ip_proto = 41;
    }
    table encap_outer {
        key = {
            hdr.ipv4.isValid(): exact;
            hdr.ipv6.isValid(): exact;
            hdr.udp.isValid() : exact;
        }
        actions = {
            rewrite_inner_ipv4_udp;
            rewrite_inner_ipv4_unknown;
            rewrite_inner_ipv6_udp;
            rewrite_inner_ipv6_unknown;
        }
        const entries = {
                        (true, false, false) : rewrite_inner_ipv4_unknown();

                        (false, true, false) : rewrite_inner_ipv6_unknown();

                        (true, false, true) : rewrite_inner_ipv4_udp();

                        (false, true, true) : rewrite_inner_ipv6_udp();

        }

    }
    action add_udp_header(bit<16> src_port, bit<16> dst_port) {
        hdr.udp.setValid();
        hdr.udp.src_port = src_port;
        hdr.udp.dst_port = dst_port;
        hdr.udp.checksum = 0;
    }
    action add_vxlan_header(bit<24> vni) {
    }
    action add_gre_header(bit<16> proto) {
    }
    action add_erspan_header(bit<32> timestamp, switch_mirror_session_t session_id) {
        hdr.erspan_type3.setValid();
        hdr.erspan_type3.timestamp = timestamp;
        hdr.erspan_type3.session_id = (bit<10>)session_id;
        hdr.erspan_type3.version = 4w0x2;
        hdr.erspan_type3.sgt = 0;
        hdr.erspan_type3.vlan = 0;
    }
    action add_ipv4_header(bit<8> proto) {
        hdr.ipv4.setValid();
        hdr.ipv4.version = 4w4;
        hdr.ipv4.ihl = 4w5;
        hdr.ipv4.identification = 0;
        hdr.ipv4.flags = 0;
        hdr.ipv4.frag_offset = 0;
        hdr.ipv4.protocol = proto;
        if (mode == switch_tunnel_mode_t.UNIFORM) {
        } else if (mode == switch_tunnel_mode_t.PIPE) {
            hdr.ipv4.ttl = 8w64;
            hdr.ipv4.diffserv = 0;
        }
    }
    action add_ipv6_header(bit<8> proto) {
        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w6;
        hdr.ipv6.flow_label = 0;
        hdr.ipv6.next_hdr = proto;
        if (mode == switch_tunnel_mode_t.UNIFORM) {
        } else if (mode == switch_tunnel_mode_t.PIPE) {
            hdr.ipv6.hop_limit = 8w64;
            hdr.ipv6.traffic_class = 0;
        }
    }
    action rewrite_ipv4_vxlan(bit<16> vxlan_port) {
        hdr.inner_ethernet = hdr.ethernet;
        add_ipv4_header(17);
        hdr.ipv4.total_len = payload_len + 16w50;
        add_udp_header(eg_md.tunnel.hash, vxlan_port);
        hdr.udp.length = payload_len + 16w30;
        add_vxlan_header(eg_md.tunnel.id);
        hdr.ethernet.ether_type = 0x800;
    }
    action rewrite_ipv4_ip() {
        add_ipv4_header(ip_proto);
        hdr.ipv4.total_len = payload_len + 16w20;
        hdr.ethernet.ether_type = 0x800;
    }
    action rewrite_ipv6_vxlan(bit<16> vxlan_port) {
        hdr.inner_ethernet = hdr.ethernet;
        add_ipv6_header(17);
        hdr.ipv6.payload_len = payload_len + 16w30;
        add_udp_header(eg_md.tunnel.hash, vxlan_port);
        hdr.udp.length = payload_len + 16w30;
        add_vxlan_header(eg_md.tunnel.id);
        hdr.ethernet.ether_type = 0x86dd;
    }
    action rewrite_ipv6_ip() {
        add_ipv6_header(ip_proto);
        hdr.ipv6.payload_len = payload_len;
        hdr.ethernet.ether_type = 0x86dd;
    }
    table tunnel {
        key = {
            eg_md.tunnel.type: exact;
        }
        actions = {
            NoAction;
            rewrite_ipv4_vxlan;
            rewrite_ipv6_vxlan;
            rewrite_ipv4_ip;
            rewrite_ipv6_ip;
        }
        const default_action = NoAction;
    }
    apply {
        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE && eg_md.tunnel.id == 0) {
            bd_to_vni_mapping.apply();
        }
        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
            encap_outer.apply();
            tunnel.apply();
        }
    }
}

control IngressMPLS(in switch_header_t hdr, inout switch_ingress_metadata_t ig_md, inout switch_lookup_fields_t lkp)(switch_uint32_t rmac_size=1024, switch_uint32_t mpls_tunnel_size=1024) {
    action rmac_hit() {
    }
    table rmac {
        key = {
            ig_md.rmac_group: exact;
            lkp.mac_dst_addr: exact;
        }
        actions = {
            NoAction;
            rmac_hit;
        }
        const default_action = NoAction;
        size = rmac_size;
    }
    action forward_to_fpga() {
    }
    action terminate_ip_over_mpls(switch_bd_t bd, switch_vrf_t vrf, switch_bd_label_t bd_label, bool ipv4_unicast_enable, bool ipv4_multicast_enable, bool igmp_snooping_enable, bool ipv6_unicast_enable, bool ipv6_multicast_enable, bool mld_snooping_enable, switch_multicast_rpf_group_t mrpf_group, switch_rmac_group_t rmac_group) {
        ig_md.bd = bd;
        ig_md.bd_label = bd_label;
        ig_md.vrf = vrf;
        ig_md.rmac_group = rmac_group;
        ig_md.multicast.rpf_group = mrpf_group;
        ig_md.learning.bd_mode = SWITCH_LEARNING_MODE_DISABLED;
        ig_md.ipv4.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv4.multicast_enable = ipv4_multicast_enable;
        ig_md.ipv4.multicast_snooping = igmp_snooping_enable;
        ig_md.ipv6.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv6.multicast_enable = ipv6_multicast_enable;
        ig_md.ipv6.multicast_snooping = mld_snooping_enable;
        ig_md.tunnel.terminate = true;
    }
    action terminate_eth_over_mpls(switch_bd_t bd, switch_vrf_t vrf, switch_bd_label_t bd_label, switch_ifindex_t pw_ifindex, bool ipv4_unicast_enable, bool ipv4_multicast_enable, bool igmp_snooping_enable, bool ipv6_unicast_enable, bool ipv6_multicast_enable, bool mld_snooping_enable, switch_multicast_rpf_group_t mrpf_group, switch_rmac_group_t rmac_group) {
        ig_md.bd = bd;
        ig_md.bd_label = bd_label;
        ig_md.vrf = vrf;
        ig_md.rmac_group = rmac_group;
        ig_md.ifindex = pw_ifindex;
        ig_md.multicast.rpf_group = mrpf_group;
        ig_md.learning.bd_mode = SWITCH_LEARNING_MODE_LEARN;
        ig_md.ipv4.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv4.multicast_enable = ipv4_multicast_enable;
        ig_md.ipv4.multicast_snooping = igmp_snooping_enable;
        ig_md.ipv6.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv6.multicast_enable = ipv6_multicast_enable;
        ig_md.ipv6.multicast_snooping = mld_snooping_enable;
        ig_md.tunnel.terminate = true;
    }
    table mpls_tunnel {
        key = {
            hdr.mpls[0].label: exact;
        }
        actions = {
            forward_to_fpga;
            terminate_ip_over_mpls;
            terminate_eth_over_mpls;
        }
        const default_action = forward_to_fpga;
        size = mpls_tunnel_size;
    }
    apply {
        if (hdr.mpls[0].isValid()) {
            switch (rmac.apply().action_run) {
                rmac_hit: {
                    mpls_tunnel.apply();
                }
            }

        }
    }
}

control MPLSDecap(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md) {
    action decap_inner_udp() {
        hdr.udp = hdr.inner_udp;
        hdr.inner_udp.setInvalid();
        hdr.tcp.setInvalid();
        hdr.icmp.setInvalid();
    }
    action decap_inner_tcp() {
        hdr.tcp = hdr.inner_tcp;
        hdr.inner_tcp.setInvalid();
        hdr.udp.setInvalid();
        hdr.icmp.setInvalid();
    }
    action decap_inner_icmp() {
        hdr.icmp = hdr.inner_icmp;
        hdr.inner_icmp.setInvalid();
        hdr.udp.setInvalid();
        hdr.tcp.setInvalid();
    }
    action decap_inner_unknown() {
    }
    table decap_inner_l4 {
        key = {
            hdr.inner_udp.isValid() : exact;
            hdr.inner_tcp.isValid() : exact;
            hdr.inner_icmp.isValid(): exact;
        }
        actions = {
            decap_inner_udp;
            decap_inner_tcp;
            decap_inner_icmp;
            decap_inner_unknown;
        }
        const default_action = decap_inner_unknown;
        const entries = {
                        (true, false, false) : decap_inner_udp();

                        (false, true, false) : decap_inner_tcp();

                        (false, false, true) : decap_inner_icmp();

        }

    }
    action decap_mpls() {
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.mpls[3].setInvalid();
        hdr.mpls[4].setInvalid();
        hdr.mpls[5].setInvalid();
        hdr.mpls[6].setInvalid();
        hdr.mpls[7].setInvalid();
        hdr.mpls[8].setInvalid();
        hdr.mpls[9].setInvalid();
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
        hdr.ipv4.src_addr = hdr.inner_ipv4.src_addr;
        hdr.ipv4.dst_addr = hdr.inner_ipv4.dst_addr;
        hdr.ipv4.ttl = hdr.inner_ipv4.ttl;
        hdr.ipv4.diffserv = hdr.inner_ipv4.diffserv;
        hdr.inner_ipv4.setInvalid();
    }
    action copy_tag_header() {
        hdr.vlan_tag[0].pcp = hdr.inner_vlan_tag[0].pcp;
        hdr.vlan_tag[0].cfi = hdr.inner_vlan_tag[0].cfi;
        hdr.vlan_tag[0].vid = hdr.inner_vlan_tag[0].vid;
        hdr.inner_vlan_tag[0].setInvalid();
    }
    action copy_double_tag_header() {
        hdr.vlan_tag[1].pcp = hdr.inner_vlan_tag[1].pcp;
        hdr.vlan_tag[1].cfi = hdr.inner_vlan_tag[1].cfi;
        hdr.vlan_tag[1].vid = hdr.inner_vlan_tag[1].vid;
        hdr.inner_vlan_tag[1].setInvalid();
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
    action invalidate_tunneling_headers() {
        hdr.vxlan.setInvalid();
    }
    action decap_inner_ethernet_ipv4() {
        hdr.ethernet = hdr.inner_ethernet;
        copy_ipv4_header();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_tunneling_headers();
        decap_mpls();
    }
    action decap_inner_ethernet_tag_ipv4() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ethernet.ether_type = 4;
        copy_ipv4_header();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_tunneling_headers();
        eg_md.tunnel.u_tag = hdr.inner_vlan_tag[0].vid;
        eg_md.tunnel.p_tag_exist = false;
        hdr.vlan_tag[0].setInvalid();
        decap_mpls();
    }
    action decap_inner_ethernet_double_tag_ipv4() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ethernet.ether_type = 4;
        copy_ipv4_header();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_tunneling_headers();
        eg_md.tunnel.u_tag = hdr.inner_vlan_tag[1].vid;
        eg_md.tunnel.p_tag = hdr.inner_vlan_tag[0].vid;
        eg_md.tunnel.p_tag_exist = true;
        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
        decap_mpls();
    }
    action decap_inner_ethernet_ipv6() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ethernet.ether_type = 41;
        copy_ipv6_header();
        hdr.ipv4.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_tunneling_headers();
        decap_mpls();
    }
    action decap_inner_ethernet_tag_ipv6() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ethernet.ether_type = 41;
        copy_ipv6_header();
        hdr.ipv4.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_tunneling_headers();
        eg_md.tunnel.u_tag = hdr.inner_vlan_tag[0].vid;
        eg_md.tunnel.p_tag_exist = false;
        hdr.vlan_tag[0].setInvalid();
        decap_mpls();
    }
    action decap_inner_ethernet_double_tag_ipv6() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ethernet.ether_type = 41;
        copy_ipv6_header();
        hdr.ipv4.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_tunneling_headers();
        eg_md.tunnel.u_tag = hdr.inner_vlan_tag[1].vid;
        eg_md.tunnel.p_tag = hdr.inner_vlan_tag[0].vid;
        eg_md.tunnel.p_tag_exist = true;
        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
        decap_mpls();
    }
    action decap_inner_ethernet_non_ip() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_tunneling_headers();
        decap_mpls();
    }
    action decap_inner_ipv4() {
        hdr.ethernet.ether_type = 0x800;
        copy_ipv4_header();
        hdr.ipv6.setInvalid();
        invalidate_tunneling_headers();
        decap_mpls();
    }
    action decap_inner_ipv6() {
        hdr.ethernet.ether_type = 0x86dd;
        copy_ipv6_header();
        hdr.ipv4.setInvalid();
        invalidate_tunneling_headers();
        decap_mpls();
    }
    table mpls_decap_inner_ip {
        key = {
            hdr.inner_ethernet.isValid()   : exact;
            hdr.inner_vlan_tag[0].isValid(): exact;
            hdr.inner_vlan_tag[1].isValid(): exact;
            hdr.inner_ipv4.isValid()       : exact;
            hdr.inner_ipv6.isValid()       : exact;
        }
        actions = {
            decap_inner_ethernet_ipv4;
            decap_inner_ethernet_tag_ipv4;
            decap_inner_ethernet_double_tag_ipv4;
            decap_inner_ethernet_ipv6;
            decap_inner_ethernet_tag_ipv6;
            decap_inner_ethernet_double_tag_ipv6;
            decap_inner_ethernet_non_ip;
            decap_inner_ipv4;
            decap_inner_ipv6;
        }
    }
    apply {
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0) && eg_md.tunnel.terminate) {
            mpls_decap_inner_ip.apply();
        }
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0) && eg_md.tunnel.terminate) {
            decap_inner_l4.apply();
        }
    }
}

control MPLSEncap(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t bd_inner_tag_size=1024) {
    action copy_ipv4_header() {
        hdr.inner_ipv4.setValid();
        hdr.inner_ipv4.version = hdr.ipv4.version;
        hdr.inner_ipv4.ihl = hdr.ipv4.ihl;
        hdr.inner_ipv4.diffserv = hdr.ipv4.diffserv;
        hdr.inner_ipv4.total_len = hdr.ipv4.total_len;
        hdr.inner_ipv4.identification = hdr.ipv4.identification;
        hdr.inner_ipv4.flags = hdr.ipv4.flags;
        hdr.inner_ipv4.frag_offset = hdr.ipv4.frag_offset;
        hdr.inner_ipv4.ttl = hdr.ipv4.ttl;
        hdr.inner_ipv4.protocol = hdr.ipv4.protocol;
        hdr.inner_ipv4.src_addr = hdr.ipv4.src_addr;
        hdr.inner_ipv4.dst_addr = hdr.ipv4.dst_addr;
        hdr.ipv4.setInvalid();
    }
    action copy_ipv6_header() {
        hdr.inner_ipv6.version = hdr.ipv6.version;
        hdr.inner_ipv6.flow_label = hdr.ipv6.flow_label;
        hdr.inner_ipv6.payload_len = hdr.ipv6.payload_len;
        hdr.inner_ipv6.src_addr = hdr.ipv6.src_addr;
        hdr.inner_ipv6.dst_addr = hdr.ipv6.dst_addr;
        hdr.inner_ipv6.hop_limit = hdr.ipv6.hop_limit;
        hdr.inner_ipv6.traffic_class = hdr.ipv6.traffic_class;
        hdr.ipv6.setInvalid();
    }
    action rewrite_inner_ipv4_udp() {
        copy_ipv4_header();
        hdr.inner_udp = hdr.udp;
        hdr.udp.setInvalid();
        hdr.icmp.setInvalid();
    }
    action rewrite_inner_ipv4_tcp() {
        copy_ipv4_header();
        hdr.inner_tcp = hdr.tcp;
        hdr.tcp.setInvalid();
        hdr.icmp.setInvalid();
    }
    action rewrite_inner_ipv4_icmp() {
        copy_ipv4_header();
        hdr.inner_icmp = hdr.icmp;
        hdr.tcp.setInvalid();
        hdr.udp.setInvalid();
    }
    action rewrite_inner_ipv4_unknown() {
        copy_ipv4_header();
    }
    action rewrite_inner_ipv6_udp() {
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_udp = hdr.udp;
        hdr.udp.setInvalid();
        hdr.ipv6.setInvalid();
    }
    action rewrite_inner_ipv6_tcp() {
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_tcp = hdr.tcp;
        hdr.tcp.setInvalid();
        hdr.ipv6.setInvalid();
    }
    action rewrite_inner_ipv6_icmp() {
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_icmp = hdr.icmp;
        hdr.tcp.setInvalid();
        hdr.udp.setInvalid();
        hdr.ipv6.setInvalid();
    }
    action rewrite_inner_ipv6_unknown() {
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.ipv6.setInvalid();
    }
    table encap_inner {
        key = {
            hdr.ipv4.isValid(): exact;
            hdr.ipv6.isValid(): exact;
            hdr.udp.isValid() : exact;
            hdr.tcp.isValid() : exact;
            hdr.icmp.isValid(): exact;
        }
        actions = {
            rewrite_inner_ipv4_udp;
            rewrite_inner_ipv4_tcp;
            rewrite_inner_ipv4_icmp;
            rewrite_inner_ipv4_unknown;
            rewrite_inner_ipv6_udp;
            rewrite_inner_ipv6_tcp;
            rewrite_inner_ipv6_icmp;
            rewrite_inner_ipv6_unknown;
        }
    }
    action mpls_ethernet_push1_rewrite() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.inner_ethernet.setValid();
        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.ethernet.ether_type = 0x8847;
    }
    action mpls_ip_push1_rewrite() {
        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.ethernet.ether_type = 0x8847;
    }
    action mpls_ethernet_push2_rewrite() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.inner_ethernet.setValid();
        hdr.mpls.push_front(2);
        hdr.mpls[0].setValid();
        hdr.mpls[1].setValid();
        hdr.ethernet.ether_type = 0x8847;
    }
    action mpls_ip_push2_rewrite() {
        hdr.mpls.push_front(2);
        hdr.mpls[0].setValid();
        hdr.mpls[1].setValid();
        hdr.ethernet.ether_type = 0x8847;
    }
    action mpls_ethernet_push3_rewrite() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.inner_ethernet.setValid();
        hdr.mpls.push_front(3);
        hdr.mpls[0].setValid();
        hdr.mpls[1].setValid();
        hdr.mpls[2].setValid();
        hdr.ethernet.ether_type = 0x8847;
    }
    action mpls_ip_push3_rewrite() {
        hdr.mpls.push_front(3);
        hdr.mpls[0].setValid();
        hdr.mpls[1].setValid();
        hdr.mpls[2].setValid();
        hdr.ethernet.ether_type = 0x8847;
    }
    action mpls_ethernet_push4_rewrite() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.inner_ethernet.setValid();
        hdr.mpls.push_front(4);
        hdr.mpls[0].setValid();
        hdr.mpls[1].setValid();
        hdr.mpls[2].setValid();
        hdr.mpls[3].setValid();
        hdr.ethernet.ether_type = 0x8847;
    }
    action mpls_ip_push4_rewrite() {
        hdr.mpls.push_front(4);
        hdr.mpls[0].setValid();
        hdr.mpls[1].setValid();
        hdr.mpls[2].setValid();
        hdr.mpls[3].setValid();
        hdr.ethernet.ether_type = 0x8847;
    }
    table mpls_encap {
        key = {
            eg_md.tunnel.type               : exact;
            eg_md.tunnel.egress_header_count: exact;
        }
        actions = {
            NoAction;
            mpls_ethernet_push1_rewrite;
            mpls_ip_push1_rewrite;
            mpls_ethernet_push2_rewrite;
            mpls_ip_push2_rewrite;
            mpls_ethernet_push3_rewrite;
            mpls_ip_push3_rewrite;
            mpls_ethernet_push4_rewrite;
            mpls_ip_push4_rewrite;
        }
        const default_action = NoAction;
    }
    action set_double_tagged(vlan_id_t vid0, vlan_id_t vid1) {
        hdr.inner_vlan_tag[0].setValid();
        hdr.inner_vlan_tag[0].pcp = 0;
        hdr.inner_vlan_tag[0].cfi = 0;
        hdr.inner_vlan_tag[0].vid = vid0;
        hdr.inner_vlan_tag[0].ether_type = 0x8100;
        hdr.inner_vlan_tag[1].setValid();
        hdr.inner_vlan_tag[1].pcp = 0;
        hdr.inner_vlan_tag[1].cfi = 0;
        hdr.inner_vlan_tag[1].vid = vid1;
        hdr.inner_vlan_tag[1].ether_type = hdr.inner_ethernet.ether_type;
        hdr.ethernet.ether_type = 0x8100;
    }
    action set_vlan_tagged(vlan_id_t vid) {
        hdr.inner_vlan_tag[0].setValid();
        hdr.inner_vlan_tag[0].ether_type = hdr.inner_ethernet.ether_type;
        hdr.inner_vlan_tag[0].pcp = eg_md.lkp.pcp;
        hdr.inner_vlan_tag[0].cfi = 0;
        hdr.inner_vlan_tag[0].vid = vid;
        hdr.inner_ethernet.ether_type = 0x8100;
    }
    action set_double_tagged_with_utag(vlan_id_t vid0) {
        set_double_tagged(vid0, eg_md.tunnel.u_tag);
    }
    action set_vlan_tagged_with_utag() {
        set_vlan_tagged(eg_md.tunnel.u_tag);
    }
    action set_double_tagged_with_ptag_utag() {
        set_double_tagged(eg_md.tunnel.p_tag, eg_md.tunnel.u_tag);
    }
    table inner_tag_encap {
        key = {
            eg_md.bd                : exact;
            eg_md.tunnel.p_tag_exist: exact;
        }
        actions = {
            NoAction;
            set_vlan_tagged;
            set_double_tagged;
            set_vlan_tagged_with_utag;
            set_double_tagged_with_utag;
            set_double_tagged_with_ptag_utag;
        }
        const default_action = NoAction;
        size = bd_inner_tag_size;
    }
    apply {
        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
            encap_inner.apply();
            mpls_encap.apply();
            inner_tag_encap.apply();
        }
    }
}

control MPLSRewrite(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t mpls_tunnel_size=1024, switch_uint32_t mpls_vc_size=512) {
    action set_mpls_rewrite_push1_core(bit<20> label1, bit<3> exp1, bit<8> ttl1) {
        hdr.mpls[0].label = label1;
        hdr.mpls[0].exp = exp1;
        hdr.mpls[0].ttl = ttl1;
    }
    action set_mpls_rewrite_push1(bit<20> label1, bit<3> exp1, bit<8> ttl1, bit<1> bos) {
        set_mpls_rewrite_push1_core(label1, exp1, ttl1);
        hdr.mpls[0].bos = bos;
    }
    action set_mpls_rewrite_push2_core(bit<20> label1, bit<3> exp1, bit<8> ttl1, bit<20> label2, bit<3> exp2, bit<8> ttl2) {
        hdr.mpls[1].label = label2;
        hdr.mpls[1].exp = exp2;
        hdr.mpls[1].ttl = ttl2;
        hdr.mpls[0].bos = 0;
        set_mpls_rewrite_push1_core(label1, exp1, ttl1);
    }
    action set_mpls_rewrite_push2(bit<20> label1, bit<3> exp1, bit<8> ttl1, bit<20> label2, bit<3> exp2, bit<8> ttl2, bit<1> bos) {
        set_mpls_rewrite_push2_core(label1, exp1, ttl1, label2, exp2, ttl2);
        hdr.mpls[1].bos = bos;
    }
    action set_mpls_rewrite_push3(bit<20> label1, bit<3> exp1, bit<8> ttl1, bit<20> label2, bit<3> exp2, bit<8> ttl2, bit<20> label3, bit<3> exp3, bit<8> ttl3, bit<1> bos) {
        hdr.mpls[2].label = label3;
        hdr.mpls[2].exp = exp3;
        hdr.mpls[2].ttl = ttl3;
        hdr.mpls[2].bos = bos;
        hdr.mpls[1].bos = 0;
        set_mpls_rewrite_push2_core(label1, exp1, ttl1, label2, exp2, ttl2);
    }
    table mpls_tunnel_rewrite {
        key = {
            eg_md.tunnel.index: exact;
        }
        actions = {
            NoAction;
            set_mpls_rewrite_push1;
            set_mpls_rewrite_push2;
            set_mpls_rewrite_push3;
        }
        const default_action = NoAction;
        size = mpls_tunnel_size;
    }
    action set_mpls_vc_rewrite_1(bit<20> label1, bit<3> exp1, bit<8> ttl1) {
        hdr.mpls[0].label = label1;
        hdr.mpls[0].exp = exp1;
        hdr.mpls[0].ttl = ttl1;
        hdr.mpls[0].bos = 1;
    }
    action set_mpls_vc_rewrite_2(bit<20> label1, bit<3> exp1, bit<8> ttl1) {
        hdr.mpls[1].label = label1;
        hdr.mpls[1].exp = exp1;
        hdr.mpls[1].ttl = ttl1;
        hdr.mpls[1].bos = 1;
    }
    action set_mpls_vc_rewrite_3(bit<20> label1, bit<3> exp1, bit<8> ttl1) {
        hdr.mpls[2].label = label1;
        hdr.mpls[2].exp = exp1;
        hdr.mpls[2].ttl = ttl1;
        hdr.mpls[2].bos = 1;
    }
    action set_mpls_vc_rewrite_4(bit<20> label1, bit<3> exp1, bit<8> ttl1) {
        hdr.mpls[3].label = label1;
        hdr.mpls[3].exp = exp1;
        hdr.mpls[3].ttl = ttl1;
        hdr.mpls[3].bos = 1;
    }
    table mpls_vc_rewrite {
        key = {
            eg_md.vc_index                  : exact;
            eg_md.tunnel.egress_header_count: exact;
        }
        actions = {
            NoAction;
            set_mpls_vc_rewrite_1;
            set_mpls_vc_rewrite_2;
            set_mpls_vc_rewrite_3;
            set_mpls_vc_rewrite_4;
        }
        const default_action = NoAction;
        size = mpls_vc_size;
    }
    action dmac_rewrite(mac_addr_t dmac) {
        hdr.ethernet.dst_addr = dmac;
    }
    table tunnel_dmac_rewrite {
        key = {
            eg_md.tunnel.dmac_index: exact;
        }
        actions = {
            NoAction;
            dmac_rewrite;
        }
        const default_action = NoAction;
    }
    apply {
        mpls_tunnel_rewrite.apply();
        mpls_vc_rewrite.apply();
        tunnel_dmac_rewrite.apply();
    }
}

control SRProcess(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t sr_table_size=512) {
    action set_mpls_push_sr_1() {
        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
    }
    action set_mpls_push_sr_2() {
        hdr.mpls.push_front(2);
        hdr.mpls[0].setValid();
        hdr.mpls[1].setValid();
    }
    action set_mpls_push_sr_3() {
        hdr.mpls.push_front(3);
        hdr.mpls[0].setValid();
        hdr.mpls[1].setValid();
        hdr.mpls[2].setValid();
    }
    action set_mpls_push_sr_4() {
        hdr.mpls.push_front(4);
        hdr.mpls[0].setValid();
        hdr.mpls[1].setValid();
        hdr.mpls[2].setValid();
        hdr.mpls[3].setValid();
    }
    action set_mpls_push_sr_5() {
        hdr.mpls.push_front(5);
        hdr.mpls[0].setValid();
        hdr.mpls[1].setValid();
        hdr.mpls[2].setValid();
        hdr.mpls[3].setValid();
        hdr.mpls[4].setValid();
    }
    action set_mpls_push_sr_6() {
        hdr.mpls.push_front(6);
        hdr.mpls[0].setValid();
        hdr.mpls[1].setValid();
        hdr.mpls[2].setValid();
        hdr.mpls[3].setValid();
        hdr.mpls[4].setValid();
        hdr.mpls[5].setValid();
    }
    table sr_encap_process {
        key = {
            eg_md.tunnel.sr_tunnel_count: exact;
        }
        actions = {
            NoAction;
            set_mpls_push_sr_1;
            set_mpls_push_sr_2;
            set_mpls_push_sr_3;
            set_mpls_push_sr_4;
            set_mpls_push_sr_5;
            set_mpls_push_sr_6;
        }
        const default_action = NoAction;
    }
    action set_mpls_rewrite_push1_core(bit<20> label1, bit<3> exp1, bit<8> ttl1) {
        hdr.mpls[0].label = label1;
        hdr.mpls[0].exp = exp1;
        hdr.mpls[0].ttl = ttl1;
    }
    action set_mpls_rewrite_push1(bit<20> label1, bit<3> exp1, bit<8> ttl1, bit<1> bos) {
        set_mpls_rewrite_push1_core(label1, exp1, ttl1);
        hdr.mpls[0].bos = bos;
    }
    action set_mpls_rewrite_push2_core(bit<20> label1, bit<3> exp1, bit<8> ttl1, bit<20> label2, bit<3> exp2, bit<8> ttl2) {
        hdr.mpls[1].label = label2;
        hdr.mpls[1].exp = exp2;
        hdr.mpls[1].ttl = ttl2;
        hdr.mpls[0].bos = 0;
        set_mpls_rewrite_push1_core(label1, exp1, ttl1);
    }
    action set_mpls_rewrite_push2(bit<20> label1, bit<3> exp1, bit<8> ttl1, bit<20> label2, bit<3> exp2, bit<8> ttl2, bit<1> bos) {
        set_mpls_rewrite_push2_core(label1, exp1, ttl1, label2, exp2, ttl2);
        hdr.mpls[1].bos = bos;
    }
    action set_mpls_rewrite_push3(bit<20> label1, bit<3> exp1, bit<8> ttl1, bit<20> label2, bit<3> exp2, bit<8> ttl2, bit<20> label3, bit<3> exp3, bit<8> ttl3, bit<1> bos) {
        hdr.mpls[2].label = label3;
        hdr.mpls[2].exp = exp3;
        hdr.mpls[2].ttl = ttl3;
        hdr.mpls[2].bos = bos;
        hdr.mpls[1].bos = 0;
        set_mpls_rewrite_push2_core(label1, exp1, ttl1, label2, exp2, ttl2);
    }
    action set_mpls_rewrite_push4_core(bit<20> label1, bit<3> exp1, bit<8> ttl1) {
        hdr.mpls[3].label = label1;
        hdr.mpls[3].exp = exp1;
        hdr.mpls[3].ttl = ttl1;
    }
    action set_mpls_rewrite_push4(bit<20> label1, bit<3> exp1, bit<8> ttl1, bit<1> bos) {
        set_mpls_rewrite_push4_core(label1, exp1, ttl1);
        hdr.mpls[3].bos = bos;
    }
    action set_mpls_rewrite_push5_core(bit<20> label1, bit<3> exp1, bit<8> ttl1, bit<20> label2, bit<3> exp2, bit<8> ttl2) {
        hdr.mpls[4].label = label2;
        hdr.mpls[4].exp = exp2;
        hdr.mpls[4].ttl = ttl2;
        hdr.mpls[3].bos = 0;
        set_mpls_rewrite_push4_core(label1, exp1, ttl1);
    }
    action set_mpls_rewrite_push5(bit<20> label1, bit<3> exp1, bit<8> ttl1, bit<20> label2, bit<3> exp2, bit<8> ttl2, bit<1> bos) {
        set_mpls_rewrite_push5_core(label1, exp1, ttl1, label2, exp2, ttl2);
        hdr.mpls[4].bos = bos;
    }
    action set_mpls_rewrite_push6(bit<20> label1, bit<3> exp1, bit<8> ttl1, bit<20> label2, bit<3> exp2, bit<8> ttl2, bit<20> label3, bit<3> exp3, bit<8> ttl3, bit<1> bos) {
        hdr.mpls[5].label = label3;
        hdr.mpls[5].exp = exp3;
        hdr.mpls[5].ttl = ttl3;
        hdr.mpls[5].bos = bos;
        hdr.mpls[4].bos = 0;
        set_mpls_rewrite_push5_core(label1, exp1, ttl1, label2, exp2, ttl2);
    }
    table sr_rewrite_0_2 {
        key = {
            eg_md.tunnel.index: exact;
        }
        actions = {
            NoAction;
            set_mpls_rewrite_push1;
            set_mpls_rewrite_push2;
            set_mpls_rewrite_push3;
        }
        const default_action = NoAction;
        size = sr_table_size;
    }
    table sr_rewrite_3_5 {
        key = {
            eg_md.tunnel.index: exact;
        }
        actions = {
            NoAction;
            set_mpls_rewrite_push4;
            set_mpls_rewrite_push5;
            set_mpls_rewrite_push6;
        }
        const default_action = NoAction;
        size = sr_table_size;
    }
    action set_mpls_rewrite_pop1() {
        hdr.mpls.pop_front(1);
    }
    action set_mpls_rewrite_pop2() {
        hdr.mpls.pop_front(2);
    }
    action set_mpls_rewrite_pop3() {
        hdr.mpls.pop_front(3);
    }
    apply {
        if (eg_md.tunnel.sr_tunnel_count != 0) {
            sr_encap_process.apply();
            sr_rewrite_0_2.apply();
            sr_rewrite_3_5.apply();
        }
    }
}

typedef bit<10> switch_ipfix_group_t;
const switch_ipfix_group_t SWITCH_IPFIX_GROUP_INVALID = 0;
typedef bit<32> switch_ipfix_pkt_invl_t;
const switch_ipfix_pkt_invl_t SWITCH_IPFIX_PKT_INVL_INVALID = 0;
typedef bit<1> switch_ipfix_sample_type_t;
const switch_ipfix_sample_type_t SWITCH_IPFIX_SAMPLE_TYPE_NONE = 0b0;
const switch_ipfix_sample_type_t SWITCH_IPFIX_SAMPLE_TYPE_DO = 0b1;
control IpfixMirror(in switch_ipfix_group_t ipfix_group, in switch_pkt_src_t src, inout switch_mirror_metadata_t mirror_md, inout switch_cpu_reason_t ipfix_reason_code)(switch_uint32_t table_size=288) {
    action copy_to_cpu(switch_mirror_session_t session_id, switch_cpu_reason_t reason_code) {
        ipfix_reason_code = reason_code;
        mirror_md.type = 2;
        mirror_md.session_id = session_id;
        mirror_md.src = src;
    }
    table ipfix_mirror {
        key = {
            ipfix_group: exact;
        }
        actions = {
            NoAction;
            copy_to_cpu;
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        ipfix_mirror.apply();
    }
}

control IngressIpfix(inout switch_ingress_metadata_t ig_md)(switch_uint32_t acl_table_size=512, switch_uint32_t checksample_table_size=512, switch_uint32_t ipfix_mirror_table_size=512) {
    IpfixMirror(ipfix_mirror_table_size) ipfix_mirror;
    switch_ipfix_group_t ipfix_group;
    switch_ipfix_pkt_invl_t ipfix_pkt_invl;
    switch_ipfix_sample_type_t sample_type;
    Counter<bit<16>, switch_ipfix_group_t>(checksample_table_size, CounterType_t.PACKETS_AND_BYTES) stats;
    Register<bit<32>, switch_ipfix_group_t>(checksample_table_size, 0) packet_number;
    RegisterAction<bit<32>, switch_ipfix_group_t, switch_ipfix_sample_type_t>(packet_number) check_pkt_invl = {
        void apply(inout bit<32> reg, out switch_ipfix_sample_type_t flag) {
            if (reg < ipfix_pkt_invl) {
                reg = reg + 1;
                flag = SWITCH_IPFIX_SAMPLE_TYPE_NONE;
            } else {
                reg = 0;
                flag = SWITCH_IPFIX_SAMPLE_TYPE_DO;
            }
        }
    };
    action acl_hit(switch_ipfix_group_t group, switch_ipfix_pkt_invl_t packet_interval) {
        ipfix_group = group;
        ipfix_pkt_invl = packet_interval;
    }
    table ipfix_acl {
        key = {
            ig_md.port: ternary;
        }
        actions = {
            acl_hit();
        }
        const default_action = acl_hit(SWITCH_IPFIX_GROUP_INVALID, SWITCH_IPFIX_PKT_INVL_INVALID);
        size = acl_table_size;
    }
    action check_pktinvl() {
        sample_type = check_pkt_invl.execute(ipfix_group);
        stats.count(ipfix_group);
    }
    action no_sample() {
        sample_type = SWITCH_IPFIX_SAMPLE_TYPE_NONE;
    }
    table check_sample {
        key = {
            ipfix_group: exact;
        }
        actions = {
            check_pktinvl;
            no_sample;
        }
        const default_action = no_sample;
        size = checksample_table_size;
    }
    apply {
        ipfix_acl.apply();
        check_sample.apply();
        if (sample_type == SWITCH_IPFIX_SAMPLE_TYPE_DO) {
            ipfix_mirror.apply(ipfix_group, SWITCH_PKT_SRC_CLONED_INGRESS, ig_md.mirror, ig_md.cpu_reason);
        }
    }
}

control EgressIpfix(inout switch_egress_metadata_t eg_md)(switch_uint32_t acl_table_size=512, switch_uint32_t checksample_table_size=512, switch_uint32_t ipfix_mirror_table_size=512) {
    IpfixMirror(ipfix_mirror_table_size) ipfix_mirror;
    switch_ipfix_group_t ipfix_group;
    switch_ipfix_pkt_invl_t ipfix_pkt_invl;
    switch_ipfix_sample_type_t sample_type;
    Counter<bit<16>, switch_ipfix_group_t>(checksample_table_size, CounterType_t.PACKETS_AND_BYTES) stats;
    Register<bit<32>, switch_ipfix_group_t>(checksample_table_size, 0) packet_number;
    RegisterAction<bit<32>, switch_ipfix_group_t, switch_ipfix_sample_type_t>(packet_number) check_pkt_invl = {
        void apply(inout bit<32> reg, out switch_ipfix_sample_type_t flag) {
            if (reg < ipfix_pkt_invl) {
                reg = reg + 1;
                flag = SWITCH_IPFIX_SAMPLE_TYPE_NONE;
            } else {
                reg = 0;
                flag = SWITCH_IPFIX_SAMPLE_TYPE_DO;
            }
        }
    };
    action acl_hit(switch_ipfix_group_t group, switch_ipfix_pkt_invl_t packet_interval) {
        ipfix_group = group;
        ipfix_pkt_invl = packet_interval;
    }
    table ipfix_acl {
        key = {
            eg_md.port: ternary;
        }
        actions = {
            acl_hit();
        }
        const default_action = acl_hit(SWITCH_IPFIX_GROUP_INVALID, SWITCH_IPFIX_PKT_INVL_INVALID);
        size = acl_table_size;
    }
    action check_pktinvl() {
        sample_type = check_pkt_invl.execute(ipfix_group);
        stats.count(ipfix_group);
    }
    action no_sample() {
        sample_type = SWITCH_IPFIX_SAMPLE_TYPE_NONE;
    }
    table check_sample {
        key = {
            ipfix_group: exact;
        }
        actions = {
            check_pktinvl;
            no_sample;
        }
        const default_action = no_sample;
        size = checksample_table_size;
    }
    apply {
        ipfix_acl.apply();
        check_sample.apply();
        if (sample_type == SWITCH_IPFIX_SAMPLE_TYPE_DO) {
            ipfix_mirror.apply(ipfix_group, SWITCH_PKT_SRC_CLONED_EGRESS, eg_md.mirror, eg_md.cpu_reason);
        }
    }
}

control SwitchIngress(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    IngressPortMapping(PORT_VLAN_TABLE_SIZE, BD_TABLE_SIZE) ingress_port_mapping;
    PktValidation() pkt_validation;
    IngressFabric() ig_fabric;
    SMAC(MAC_TABLE_SIZE) smac;
    DMAC(MAC_TABLE_SIZE) dmac;
    IngressBd(BD_TABLE_SIZE) bd_stats;
    IngressMulticast(IPV4_MULTICAST_S_G_TABLE_SIZE, IPV4_MULTICAST_STAR_G_TABLE_SIZE, IPV6_MULTICAST_S_G_TABLE_SIZE, IPV6_MULTICAST_STAR_G_TABLE_SIZE) multicast;
    IngressUnicast(dmac, IPV4_HOST_TABLE_SIZE, IPV4_LPM_TABLE_SIZE, IPV6_HOST_TABLE_SIZE, IPV6_LPM_TABLE_SIZE) unicast;
    IngressAcl(INGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE, false) acl;
    IngressTunnel() tunnel;
    RouterAcl(IPV4_RACL_TABLE_SIZE, IPV6_RACL_TABLE_SIZE, true) racl;
    IngressQoS() qos;
    Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
    OuterFib(NUM_TUNNELS, OUTER_ECMP_GROUP_TABLE_SIZE, OUTER_ECMP_SELECT_TABLE_SIZE) outer_fib;
    LAG() lag;
    FabricLag() fabric_lag;
    MulticastFlooding(BD_FLOOD_TABLE_SIZE) flood;
    IngressSystemAcl() system_acl;
    IngressMPLS(MPLS_RMAC_TABLE_SIZE, MPLS_TUNNEL_TABLE_SIZE) mpls_tunnel;
    IngressIpfix() ip_fix;
    L3SubPortStats() subport_stats;
    apply {
        ig_intr_md_for_dprsr.drop_ctl = 0;
        ig_md.multicast.id = 0;
        ig_md.flags.racl_deny = false;
        ig_md.flags.flood_to_multicast_routers = false;
        pkt_validation.apply(hdr, ig_md.flags, ig_md.lkp, ig_intr_md_for_tm, ig_md.drop_reason);
        ingress_port_mapping.apply(hdr, ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
        ig_fabric.apply(ig_md, ig_intr_md_for_tm, hdr);
        mpls_tunnel.apply(hdr, ig_md, ig_md.lkp);
        smac.apply(ig_md.lkp.mac_src_addr, ig_md, ig_intr_md_for_dprsr.digest_type);
        bd_stats.apply(ig_md.bd, ig_md.lkp.pkt_type);
        acl.apply(ig_md.lkp, ig_md);
        if (ig_md.lkp.pkt_type == SWITCH_PKT_TYPE_UNICAST) {
            unicast.apply(ig_md.lkp, ig_md);
        } else if (ig_md.lkp.pkt_type == SWITCH_PKT_TYPE_MULTICAST && ig_md.lkp.ip_type != SWITCH_IP_TYPE_NONE) {
            multicast.apply(ig_md.lkp, ig_md);
        } else {
            dmac.apply(ig_md.lkp.mac_dst_addr, ig_md);
        }
        subport_stats.apply(ig_md.port, ig_md.bd, ig_md.lkp.pkt_type);
        racl.apply(ig_md.lkp, ig_md);
        if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_NONE) {
            compute_non_ip_hash(ig_md.lkp, ig_md.hash);
        } else {
            compute_ip_hash(ig_md.lkp, ig_md.hash);
        }
        nexthop.apply(ig_md.lkp, ig_md, ig_md.hash[15:0]);
        qos.apply(hdr, ig_md.lkp, ig_md);
        outer_fib.apply(ig_md, ig_md.hash[31:16]);
        if (ig_md.egress_ifindex == SWITCH_IFINDEX_FLOOD) {
            flood.apply(ig_md);
        } else {
            lag.apply(ig_md, ig_md.hash[31:16], ig_intr_md_for_tm.ucast_egress_port);
        }
        fabric_lag.apply(ig_md, ig_intr_md_for_tm);
        ip_fix.apply(ig_md);
        system_acl.apply(ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
        if (ig_intr_md_for_tm.bypass_egress == 1w0) {
            add_bridged_md(hdr.bridged_md, ig_md);
        }
        set_ig_intr_md(ig_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);
    }
}

control SwitchEgress(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    EgressPortMapping() egress_port_mapping;
    EgressQoS() qos;
    EgressAcl() acl;
    EgressSystemAcl() system_acl;
    Rewrite(NEXTHOP_TABLE_SIZE, BD_TABLE_SIZE) rewrite;
    MirrorRewrite() mirror_rewrite;
    VlanXlate(VLAN_TABLE_SIZE, PORT_VLAN_TABLE_SIZE) vlan_xlate;
    VlanDecap() vlan_decap;
    TunnelDecap(mode = switch_tunnel_mode_t.PIPE) tunnel_decap;
    TunnelEncap(mode = switch_tunnel_mode_t.PIPE) tunnel_encap;
    TunnelRewrite(TUNNEL_IPV4_REWRITE_SIZE, TUNNEL_IPV6_REWRITE_SIZE, 1024) tunnel_rewrite;
    FabricRewrite() fabric_rewrite;
    MPLSDecap() mpls_decap;
    MPLSEncap(MPLS_INNER_TAG_TABLE_SIZE) mpls_encap;
    MPLSRewrite(MPLS_TUNNEL_REWRITE_TABLE_SIZE, MPLS_VC_REWRITE_TABLE_SIZE) mpls_rewrite;
    SRProcess(MPLS_SR_TABLE_SIZE) sr_process;
    MTU() mtu;
    MulticastReplication() multicast_replication;
    EgressIpfix() ip_fix;
    Egresss_L3SubPortStats() subport_stats;
    apply {
        eg_intr_md_for_dprsr.drop_ctl = 0;
        mirror_rewrite.apply(hdr, eg_md);
        egress_port_mapping.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);
        multicast_replication.apply(eg_intr_md.egress_rid, eg_intr_md.egress_port, eg_md);
        vlan_decap.apply(hdr, eg_md);
        mpls_decap.apply(hdr, eg_md);
        rewrite.apply(hdr, eg_md);
        acl.apply(hdr, eg_md.lkp, eg_md);
        subport_stats.apply(eg_md.port, eg_md.bd, eg_md.pkt_type);
        qos.apply(hdr, eg_intr_md.egress_port, eg_md);
        mpls_encap.apply(hdr, eg_md);
        mpls_rewrite.apply(hdr, eg_md);
        sr_process.apply(hdr, eg_md);
        fabric_rewrite.apply(hdr, eg_md);
        mtu.apply(hdr, eg_md, eg_md.checks.mtu);
        vlan_xlate.apply(hdr, eg_md);
        ip_fix.apply(eg_md);
        system_acl.apply(hdr, eg_md, eg_intr_md, eg_intr_md_for_dprsr);
        set_eg_intr_md(eg_md, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
    }
}

Pipeline(SwitchIngressParser(), SwitchIngress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) pipe;

Switch(pipe) main;

