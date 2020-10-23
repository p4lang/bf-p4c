#include <tna.p4>  /* TOFINO1_ONLY */

const bit<32> PORT_TABLE_SIZE = 288 * 2;
const bit<32> VLAN_TABLE_SIZE = 4096;
const bit<32> EVLAN_FLOOD_TABLE_SIZE = VLAN_TABLE_SIZE * 4;
const bit<32> PORT_VLAN_TABLE_SIZE = 1024;
const bit<32> EVLAN_TABLE_SIZE = 5120;
const bit<32> MAC_TABLE_SIZE = 16384;
const bit<32> IPV4_LPM_TABLE_SIZE = 4096;
const bit<32> IPV6_HOST_TABLE_SIZE = 65536;
const bit<32> IPV6_LPM_TABLE_SIZE = 3072;
const bit<32> NEXTHOP_TABLE_SIZE = 131072;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 8192;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 4096;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 8192;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 4096;
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

@pa_auto_init_metadata

header ethernet_h {
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

header br_tag_h {
    bit<3>  epcp;
    bit<1>  edei;
    bit<12> ingress_ecid;
    bit<2>  reserved;
    bit<2>  grp;
    bit<12> ecid;
    bit<8>  ingress_ecid_ext;
    bit<8>  ecid_ext;
    bit<16> ether_type;
}

header mpls_h {
    bit<20> label;
    bit<3>  exp;
    bit<1>  bos;
    bit<8>  ttl;
}

header cw_h {
    bit<4>  diffserv;
    bit<4>  flags;
    bit<2>  frg;
    bit<6>  len;
    bit<16> seq;
}

@pa_container_size("egress", "hdr.ipv4.$valid", 8) header ipv4_h {
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
    bit<16> typeCode;
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

header srv6_list_h {
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
    bit<24> vsid;
    bit<8>  flow_id;
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
    bit<7> pad0;
    bit<9> ingress_port;
    bit<7> pad1;
    bit<9> egress_port;
    bit<3> pad2;
    bit<5> queue_id;
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

header timestamp_h {
    bit<48> timestamp;
}

header fabric_base_lookahead_h {
    bit<6> pkt_type;
    bit<1> mirror;
    bit<1> mcast;
}

header fabric_base_h {
    bit<6> pkt_type;
    bit<1> mirror;
    bit<1> mcast;
}

header fabric_qos_h {
    bit<3> tc;
    bit<2> color;
    bit<1> chgDSCP_disable;
    bit<1> BA;
    @padding
    bit<1> reserved;
}

header fabric_unicast_ext_bfn_igfpga_h {
    bit<1>  extend;
    bit<3>  ext_len;
    bit<3>  service_class;
    @padding
    bit<1>  _pad;
    bit<8>  flags;
    bit<8>  src_port;
    bit<8>  cpu_reason;
    bit<16> hash;
    bit<16> nexthop;
}

header fabric_unicast_ext_igfpga_bfn_h {
    bit<1>  extend;
    bit<3>  ext_len;
    @padding
    bit<4>  ext_word_pad;
    @padding
    bit<4>  flags_pad;
    bit<1>  glean;
    bit<1>  drop;
    bit<1>  is_pbr_nhop;
    bit<1>  flowspec_disable;
    bit<8>  src_port;
    bit<8>  cpu_reason;
    bit<16> ul_nhid;
    bit<16> ol_nhid;
}

header fabric_unicast_ext_fe_encap_h {
    bit<8>  flags;
    @padding
    bit<8>  dst_port;
    bit<16> l2_encap;
    bit<16> l3_encap;
    bit<16> egress_eport;
}

header fabric_unicast_dst_h {
    bit<1> extend;
    bit<7> dst_device;
    bit<8> dst_port;
}

header fabric_multicast_dst_h {
    bit<16> mgid;
}

header fabric_multicast_ext_h {
    bit<16> evlan;
    bit<16> hash;
    bit<16> l2_encap;
    bit<1>  learning;
    @padding
    bit<15> pad1;
}

header fabric_unicast_ext_fe_h {
    bit<16> l2_encap;
    bit<16> l3_encap;
    bit<16> hash;
}

header fabric_unicast_ext_eg_h {
    bit<8>  flags;
    bit<8>  dst_port;
    bit<16> l2_encap;
    bit<16> ptag_igmod_oif;
    bit<16> pkt_len;
    bit<16> FQID;
}

header fabric_unicast_ext_eg_decap_h {
    bit<1>  extend;
    bit<3>  pcp;
    bit<2>  next_hdr_type;
    @padding
    bit<2>  pad;
    bit<8>  dst_port;
    bit<16> l2_encap;
    bit<1>  ptag_igmod;
    bit<15> oif;
    bit<16> pkt_len;
    bit<16> FQID;
}

header fabric_var_ext_1_16bit_h {
    bit<16> data;
}

header fabric_var_ext_2_8bit_h {
    bit<8> data_hi;
    bit<8> data_lo;
}

header fabric_one_pad_h {
    bit<1>  one;
    bit<15> iif;
}

header fabric_post_one_pad_h {
    bit<1>  l2_flag;
    bit<15> l2oif;
}

header fabric_cpu_data_h {
    bit<8>  src_port;
    bit<8>  cpu_reason;
    bit<16> reason_code;
    bit<16> evlan;
    bit<1>  to_cpu;
    bit<15> iif;
    bit<1>  tx_bypass;
    bit<15> pad;
}

header fabric_payload_h {
    bit<16> ether_type;
}

header fabric_eth_base_to_cpu_h {
    bit<6>  pkt_type;
    bit<1>  dir;
    bit<1>  pad;
    bit<16> hash;
}

header fabric_ipfix_to_cpu_h {
    @padding
    bit<1>  pad2;
    bit<15> iif;
    @padding
    bit<1>  pad3;
    bit<15> oif;
    @padding
    bit<1>  pad4;
    bit<15> ul_iif;
}

header fabric_bfd_to_cpu_h {
    @padding
    bit<1>  pad2;
    bit<15> iif;
    bit<8>  src_port;
    bit<8>  reserved;
}

header fabric_ipfix_special_h {
    bit<8> sip_l3class_id;
    bit<8> dip_l3class_id;
    bit<8> sip_pri;
    bit<8> dip_pri;
}

header fabric_eth_base_from_cpu_h {
    bit<6> pkt_type;
    bit<1> tx_bypass;
    bit<1> hw_forward;
}

header fabric_eth_from_cpu_data_h {
    bit<1> pad;
    bit<7> device;
    bit<8> egress_port;
}

typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;
typedef bit<7> switch_device_t;
typedef bit<8> switch_logic_port_t;
typedef PortId_t switch_port_t;
const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;
typedef QueueId_t switch_qid_t;
typedef ReplicationId_t switch_rid_t;
const switch_rid_t SWITCH_RID_DEFAULT = 0xffff;
typedef bit<3> switch_ingress_cos_t;
typedef bit<3> switch_digest_type_t;
const switch_digest_type_t SWITCH_DIGEST_TYPE_INVALID = 0;
const switch_digest_type_t SWITCH_DIGEST_TYPE_MAC_LEARNING = 1;
typedef bit<16> switch_eport_t;
typedef bit<16> switch_eport_label_t;
typedef bit<15> switch_lif_t;
const switch_lif_t SWITCH_FLOOD = 0x3fff;
typedef bit<16> switch_evlan_t;
const switch_evlan_t SWITCH_EVLAN_DEFAULT_VRF = 4097;
typedef bit<14> switch_vrf_t;
typedef bit<16> switch_nexthop_t;
typedef bit<16> switch_outer_nexthop_t;
typedef bit<16> switch_xid_t;
typedef bit<9> switch_yid_t;
typedef bit<16> switch_evlan_label_t;
typedef bit<16> switch_mtu_t;
typedef bit<8> switch_cpu_reason_t;
const switch_cpu_reason_t SWITCH_CPU_REASON_MTU = 1;
const bit<8> SWITCH_CPU_REASON_V4UC_ROUTE = 2;
const bit<8> SWITCH_CPU_REASON_V6UC_ROUTE = 3;
const bit<8> SWITCH_CPU_REASON_UNKNOWN_V4MC = 4;
const bit<8> SWITCH_CPU_REASON_UNKNOWN_V6MC = 5;
const bit<8> SWITCH_CPU_REASON_C2C = 6;
const bit<8> SWITCH_CPU_REASON_BFD_CTRL = 7;
const bit<8> SWITCH_CPU_REASON_BFD_ECHO_V6 = 8;
const bit<8> SWITCH_CPU_REASON_BFD_CTRL_V6 = 9;
const bit<8> SWITCH_CPU_REASON_MICRO_BFD = 10;
const bit<8> SWITCH_CPU_REASON_BFD_ECHO = 11;
const bit<8> SWITCH_CPU_REASON_MICRO_BFD_V6 = 12;
const bit<8> SWITCH_CPU_REASON_MHOP_BFD = 13;
const bit<8> SWITCH_CPU_REASON_MHOP_BFD_V6 = 14;
typedef bit<16> switch_hash_t;
typedef bit<8> switch_hash_mode_t;
struct switch_cpu_port_value_set_t {
    bit<16> ether_type;
    bit<9>  port;
}

typedef bit<3> switch_pkt_src_t;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED = 0;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_INGRESS = 1;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_EGRESS = 2;
const switch_pkt_src_t SWITCH_PKT_SRC_DEFLECTED = 3;
typedef bit<5> switch_bridge_type_t;
const switch_bridge_type_t BRIDGE_TYPE_FRONT_UPLINK = 0x0;
const switch_bridge_type_t BRIDGE_TYPE_UPLINK_FABRIC = 0x1;
const switch_bridge_type_t BRIDGE_TYPE_UPLINK_FRONT = 0x2;
const switch_bridge_type_t BRIDGE_TYPE_FABRIC_DOWNLINK = 0x3;
const switch_bridge_type_t BRIDGE_TYPE_FABRIC_FABRIC = 0x4;
const switch_bridge_type_t BRIDGE_TYPE_DOWNLINK_FRONT = 0x5;
typedef bit<6> switch_pkt_type_t;
const switch_pkt_type_t FABRIC_PKT_TYPE_ETH = 0x0;
const switch_pkt_type_t FABRIC_PKT_TYPE_IPV4 = 0x1;
const switch_pkt_type_t FABRIC_PKT_TYPE_MPLS = 0x2;
const switch_pkt_type_t FABRIC_PKT_TYPE_IPV6 = 0x3;
const switch_pkt_type_t FABRIC_PKT_TYPE_IP = 0x5;
const switch_pkt_type_t FABRIC_PKT_TYPE_MIRROR_TRAN = 0x6;
const switch_pkt_type_t FABRIC_PKT_TYPE_CPU_ETH = 0xe;
const switch_pkt_type_t FABRIC_PKT_TYPE_CPU_PCIE = 0xf;
typedef bit<3> switch_fabric_ext_type_t;
const switch_fabric_ext_type_t FABRIC_EXT_TYPE_TUNNEL_DECAP = 0x0;
const switch_fabric_ext_type_t FABRIC_EXT_TYPE_L4_ENCAP = 0x1;
const switch_fabric_ext_type_t FABRIC_EXT_TYPE_L4_NHOP = 0x2;
typedef bit<3> switch_bridged_metadata_ext_type_t;
const switch_bridged_metadata_ext_type_t BRIDGED_MD_EXT_TYPE_TUNNEL_DECAP = 0x0;
const switch_bridged_metadata_ext_type_t BRIDGED_MD_EXT_TYPE_L4_ENCAP = 0x1;
const switch_bridged_metadata_ext_type_t BRIDGED_MD_EXT_TYPE_SRV6 = 0x2;
const switch_bridged_metadata_ext_type_t BRIDGED_MD_EXT_TYPE_CPP = 0x3;
const switch_bridged_metadata_ext_type_t BRIDGED_MD_EXT_TYPE_MIRROR = 0x4;
typedef bit<2> switch_next_hdr_type_t;
const switch_next_hdr_type_t SWITCH_TUNNEL_NEXT_HDR_TYPE_NONE = 0;
const switch_next_hdr_type_t SWITCH_TUNNEL_NEXT_HDR_TYPE_MPLS = 1;
const switch_next_hdr_type_t SWITCH_TUNNEL_NEXT_HDR_TYPE_IPV4 = 2;
const switch_next_hdr_type_t SWITCH_TUNNEL_NEXT_HDR_TYPE_IPV6 = 3;
typedef bit<6> switch_lkp_pkt_type_t;
const switch_lkp_pkt_type_t FABRIC_PKT_TYPE_UNICAST = 0x1;
const switch_lkp_pkt_type_t FABRIC_PKT_TYPE_MCAST = 0x2;
const switch_lkp_pkt_type_t FABRIC_PKT_TYPE_BROADCAST = 0x3;
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
const switch_drop_reason_t SWITCH_DROP_REASON_MPLS_TERMINATE_ERROR = 103;
const switch_drop_reason_t SWITCH_DROP_REASON_MPLS_POP_ERROR = 104;
const switch_drop_reason_t SWITCH_DROP_REASON_MPLS_TTL_ZERO = 105;
const switch_drop_reason_t SWITCH_DROP_REASON_SRV6_OAM = 106;
const switch_drop_reason_t SWITCH_DROP_REASON_SRV6_ERROR = 107;
typedef bit<4> switch_port_type_t;
const switch_port_type_t PORT_TYPE_UNUSED = 0;
const switch_port_type_t PORT_TYPE_FRONT = 1;
const switch_port_type_t PORT_TYPE_FPGA_UPWARD = 2;
const switch_port_type_t PORT_TYPE_FPGA_DOWN = 3;
const switch_port_type_t PORT_TYPE_CPU_ETH = 4;
const switch_port_type_t PORT_TYPE_CPU_PCIE = 5;
const switch_port_type_t PORT_TYPE_FABRIC = 6;
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
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_METER = 16w0x20;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STORM_CONTROL = 16w0x40;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STP = 16w0x80;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SMAC = 16w0x100;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_TUNNEL = 16w0x200;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ALL = 16w0xffff;
typedef bit<8> switch_egress_bypass_t;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_REWRITE = 8w0x1;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_ACL = 8w0x2;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_SYSTEM_ACL = 8w0x4;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_QOS = 8w0x8;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_WRED = 8w0x10;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_STP = 8w0x20;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_MTU = 8w0x40;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_METER = 8w0x80;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_ALL = 8w0xff;
typedef bit<16> switch_pkt_length_t;
typedef bit<2> switch_pkt_color_t;
const switch_pkt_color_t SWITCH_METER_COLOR_GREEN = 0;
const switch_pkt_color_t SWITCH_METER_COLOR_YELLOW = 1;
const switch_pkt_color_t SWITCH_METER_COLOR_RED = 3;
const switch_hash_mode_t SWITCH_HASH_MODE_NO_IP = 0x0;
const switch_hash_mode_t SWITCH_HASH_MODE_IPV4 = 0x1;
const switch_hash_mode_t SWITCH_HASH_MODE_IPV6 = 0x2;
const switch_hash_mode_t SWITCH_HASH_MODE_MPLS = 0x3;
typedef bit<8> switch_l4_port_label_t;
typedef bit<8> switch_copp_meter_id_t;
typedef bit<12> switch_meter_index_t;
typedef bit<8> switch_mirror_meter_id_t;
typedef bit<3> switch_qos_trust_mode_t;
const switch_qos_trust_mode_t SWITCH_QOS_UNTRUSTED = 0;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_DSCP = 1;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_PCP = 2;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_EXP = 3;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_PRE = 4;
typedef bit<5> switch_qos_group_t;
typedef bit<3> switch_tc_t;
typedef bit<3> switch_cos_t;
struct switch_ingress_qos_metadata_t {
    switch_qid_t            qid;
    switch_ingress_cos_t    icos;
    bit<3>                  pcp;
    switch_tc_t             tc;
    switch_pkt_color_t      color;
    bit<1>                  chgDSCP_disable;
    bit<1>                  BA;
    bit<1>                  pcp_chg;
    bit<1>                  exp_chg;
    bit<1>                  ippre_chg;
    switch_qos_trust_mode_t port_trust_mode;
    switch_qos_trust_mode_t lif_trust_mode;
    switch_qos_trust_mode_t final_trust_mode;
    switch_meter_index_t    lif_meter_index;
    switch_meter_index_t    acl_meter_index;
    bit<8>                  port_meter_index;
    bit<8>                  qppb_meter_index;
    switch_pkt_color_t      qppb_meter_color;
    switch_pkt_color_t      port_meter_color;
    switch_pkt_color_t      lif_meter_color;
    switch_pkt_color_t      acl_meter_color;
    bit<5>                  ds_select;
    bit<1>                  set_dscp;
    bit<1>                  set_tc;
    bit<1>                  set_color;
    bit<6>                  dscp;
    bit<1>                  car_flags;
    bit<2>                  qos_pkt_type;
    bit<6>                  dscp_tmp;
    bit<3>                  tc_tmp;
    bit<2>                  color_tmp;
    bool                    acl_set_tc;
    bool                    acl_set_color;
}

struct switch_egress_qos_metadata_t {
    switch_qid_t         qid;
    bit<19>              qdepth;
    bit<5>               ds_select;
    switch_pkt_color_t   acl_meter_color;
    switch_pkt_color_t   qppb_meter_color;
    switch_pkt_color_t   port_meter_color;
    switch_pkt_color_t   lif_meter_color;
    switch_pkt_color_t   color_tmp;
    bit<8>               port_meter_index;
    bit<8>               qppb_meter_index;
    switch_meter_index_t lif_meter_index;
    switch_meter_index_t acl_meter_index;
    switch_tc_t          tc;
    switch_pkt_color_t   color;
    bit<1>               chgDSCP_disable;
    bit<1>               BA;
    bit<1>               PHB;
    bit<1>               pcp_chg;
    bit<1>               exp_chg;
    bit<1>               ippre_chg;
    bit<16>              FQID;
    switch_pkt_color_t   storm_control_color;
    bit<1>               set_dscp;
    bit<1>               qppb_set_dscp;
    bit<1>               acl_set_dscp;
    bit<6>               dscp;
    bit<6>               qppb_dscp;
    bit<6>               acl_dscp;
    bit<3>               pcp;
    bit<3>               ippre;
    bit<12>              to_fpga_qid;
    bit<16>              flowid;
    bit<1>               car_flags;
}

typedef bit<8> switch_src_index_t;
typedef bit<1> switch_learning_mode_t;
const switch_learning_mode_t SWITCH_LEARNING_MODE_DISABLED = 0;
const switch_learning_mode_t SWITCH_LEARNING_MODE_LEARN = 1;
struct switch_learning_digest_t {
    switch_evlan_t evlan;
    switch_lif_t   learning_l2iif;
    mac_addr_t     src_addr;
}

struct switch_learning_metadata_t {
    switch_learning_mode_t evlan_mode;
    switch_learning_mode_t port_mode;
}

@pa_container_size("egress", "eg_md.lkp.l4_src_port", 16) @pa_container_size("egress", "eg_md.lkp.l4_dst_port", 16) @pa_container_size("ingress", "ig_md.lkp.l4_src_port_label", 8) @pa_container_size("ingress", "ig_md.lkp.l4_dst_port_label", 8) struct switch_lookup_fields_t {
    switch_lkp_pkt_type_t pkt_type;
    mac_addr_t            mac_src_addr;
    mac_addr_t            mac_dst_addr;
    bit<12>               vid;
    bit<8>                ip_tos_label;
    bit<8>                ip_pkt_len_label;
    bit<8>                ip_proto_label;
    bit<16>               l4_src_port_label;
    bit<16>               l4_dst_port_label;
    bit<16>               l4_port_label_16;
    bit<32>               l4_port_label_32;
    bit<64>               l4_port_label_64;
    bit<16>               iif_label;
    bit<16>               port_label;
    switch_ip_type_t      ip_type;
    bit<1>                ip_inner;
    bit<1>                ip_options;
    bit<8>                ip_proto;
    bit<8>                ip_ttl;
    bit<8>                tmp_ttl;
    bit<8>                ip_tos;
    bit<16>               ip_pkt_len;
    bit<8>                ipv6_tos;
    bit<8>                ipv4_tos;
    bit<2>                ip_frag;
    bit<128>              ip_src_addr;
    bit<128>              ip_dst_addr;
    bit<8>                tcp_flags;
    bit<16>               l4_src_port;
    bit<16>               l4_dst_port;
    bit<16>               ipv4_ihl;
    bit<16>               pkt_length;
}

typedef MulticastGroupId_t switch_mgid_t;
struct switch_ip_mc_metadata_t {
    bool multicast_enable;
    bool multicast_snooping;
}

struct switch_ingress_multicast_metadata_t {
    switch_mgid_t           id;
    bit<2>                  mode;
    switch_xid_t            level1_exclusion_id;
    bit<16>                 egress_rid;
    switch_ip_mc_metadata_t ipv4;
    switch_ip_mc_metadata_t ipv6;
}

struct switch_egress_multicast_metadata_t {
    switch_mgid_t           id;
    bit<2>                  mode;
    switch_xid_t            level1_exclusion_id;
    switch_ip_mc_metadata_t ipv4;
    switch_ip_mc_metadata_t ipv6;
}

typedef bit<2> switch_urpf_mode_t;
const switch_urpf_mode_t SWITCH_URPF_MODE_NONE = 0;
const switch_urpf_mode_t SWITCH_URPF_MODE_LOOSE = 1;
const switch_urpf_mode_t SWITCH_URPF_MODE_STRICT = 2;
typedef MirrorId_t switch_mirror_session_t;
const switch_mirror_session_t SWITCH_MIRROR_SESSION_CPU = 250;
typedef bit<5> switch_mirror_type_t;
struct switch_port_metadata_frontpipe_t {
    switch_port_type_t port_type;
}

struct switch_port_metadata_uplink_pipe_t {
    switch_port_type_t port_type;
    bit<1>             is_from_fabric_port;
}

struct switch_port_metadata_fabric_pipe_t {
    switch_port_type_t port_type;
    bit<1>             is_from_fabric_port;
}

struct switch_port_metadata_downlink_pipe_t {
    switch_port_type_t port_type;
    bit<1>             is_from_fabric_port;
}

struct switch_ingress_flags_t {
    bool    ipv4_checksum_err;
    bool    inner_ipv4_checksum_err;
    bool    link_local;
    bool    port_vlan_miss;
    bit<1>  dmac_miss;
    bool    port_meter_drop;
    bool    lif_meter_drop;
    bool    qppb_meter_drop;
    bool    capture_ts;
    bit<1>  flowspec_disable;
    bit<1>  flowspec_disable_v4;
    bit<1>  flowspec_disable_v6;
    bit<1>  glean;
    bit<1>  drop;
    bit<1>  is_pbr_nhop;
    bit<1>  learning;
    bit<1>  learn_en_evlan;
    bool    ext_srv6;
    bool    ext_l4_encap;
    bool    ext_cpp;
    bool    ext_tunnel_decap;
    bool    ext_mirror;
    bool    flood_to_multicast_routers;
    bool    mrpf;
    bool    routed;
    bit<1>  lag_miss;
    bit<1>  bfd_fib_myip;
    bit<1>  bypass_fabric_lag;
    bit<16> ip_ihl_check;
    bit<23> ipv4_mc_check;
    bit<32> ipv6_mc_check;
}

struct switch_egress_flags_t {
    bool   ipv4_checksum_err;
    bool   capture_ts;
    bool   port_meter_drop;
    bool   lif_meter_drop;
    bool   qos_meter_drop;
    bool   acl_meter_drop;
    bool   qppb_meter_drop;
    bool   qosacl_hit;
    bit<1> is_intf;
    bit<1> dmac_miss;
    bit<1> bh_dmac_hit;
    bool   storm_control_drop;
    bit<1> dmac_bypass;
    bool   ext_srv6;
    bool   ext_l4_encap;
    bool   ext_cpp;
    bool   ext_tunnel_decap;
    bool   ext_mirror;
    bool   routed;
    bool   tunnel_routed;
    bit<1> flowspec_disable;
    bit<1> glean;
    bit<1> drop;
    bit<1> is_pbr_nhop;
    bit<1> learning;
    bit<1> learn_en_evlan;
    bit<1> sym_enable;
    bit<1> bfd_fib_myip;
    bit<1> cpu_mirror_pkt;
}

struct switch_ingress_common_metadata_t {
    bit<16>                 ether_type;
    switch_pkt_type_t       pkt_type;
    bit<1>                  is_mirror;
    bit<1>                  is_mcast;
    switch_device_t         dst_device;
    switch_logic_port_t     dst_port;
    bit<6>                  dst_ecid;
    switch_eport_t          eport;
    switch_eport_t          egress_eport;
    switch_eport_label_t    eport_label;
    switch_port_type_t      port_type;
    switch_bridge_type_t    bridge_type;
    bit<1>                  extend;
    bit<1>                  cpu_direction;
    switch_lif_t            iif;
    switch_lif_t            oif;
    switch_lif_t            ul_iif;
    bit<16>                 nexthop;
    bit<16>                 ul_nhid;
    bit<16>                 ol_nhid;
    bit<16>                 l4_nhid;
    bit<16>                 l2_encap;
    bit<16>                 l3_encap;
    bit<16>                 l4_encap;
    switch_drop_reason_t    drop_reason;
    switch_ingress_bypass_t bypass;
    switch_hash_t           hash;
    switch_hash_mode_t      hash_mode;
    bit<16>                 udf;
    switch_port_t           ingress_port;
    switch_logic_port_t     src_port;
    bit<8>                  cpu_reason;
}

struct switch_egress_common_metadata_t {
    bit<16>                ether_type;
    switch_pkt_type_t      pkt_type;
    bit<1>                 is_mirror;
    bit<1>                 is_mcast;
    switch_device_t        dst_device;
    switch_logic_port_t    dst_port;
    bit<6>                 dst_ecid;
    switch_port_t          ingress_port;
    switch_port_type_t     port_type;
    switch_lif_t           iif;
    switch_lif_t           oif;
    switch_lif_t           ul_iif;
    switch_eport_t         eport;
    switch_eport_t         egress_eport;
    switch_eport_label_t   eport_label;
    switch_egress_bypass_t bypass;
    switch_pkt_length_t    pkt_length;
    bit<1>                 extend;
    bit<3>                 ext_len;
    bit<3>                 service_class;
    bit<16>                nexthop;
    bit<16>                l3_encap;
    bit<16>                l2_encap;
    switch_hash_t          hash;
    switch_hash_mode_t     hash_mode;
    bit<16>                udf;
    switch_bridge_type_t   bridge_type;
    switch_logic_port_t    src_port;
    bit<8>                 cpu_reason;
    bit<16>                cpu_code;
}

typedef bit<3> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NONE = 0;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IP_TUNNEL = 1;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPGRE = 2;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPv6GRE = 6;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_SRV6 = 3;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VXLAN = 4;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_MPLS = 5;
typedef bit<4> switch_tunnel_inner_pkt_t;
const switch_tunnel_inner_pkt_t SWITCH_TUNNEL_INNER_PKT_NONE = 0;
const switch_tunnel_inner_pkt_t SWITCH_TUNNEL_INNER_PKT_ETHERNET = 1;
const switch_tunnel_inner_pkt_t SWITCH_TUNNEL_INNER_PKT_IPV4 = 2;
const switch_tunnel_inner_pkt_t SWITCH_TUNNEL_INNER_PKT_IPV6 = 3;
const switch_tunnel_inner_pkt_t SWITCH_TUNNEL_INNER_PKT_IPX = 4;
typedef bit<4> switch_tunnel_encap_type_t;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_NONE = 0;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_IPINIP = 1;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_MPLS = 2;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_ENCAP_SRV6 = 3;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_END_INSERT_SRV6 = 4;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_IPGRE = 5;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_IPV6GRE = 6;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_V4_VXLAN = 7;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_V6_VXLAN = 8;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_H_INSERT_SRV6 = 9;
typedef bit<4> switch_srv6_end_type_t;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_END = 0;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_END_X = 1;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_END_T = 2;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_END_DX = 3;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_END_DT = 4;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_END_B6_ENCAPS = 5;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_END_OP = 6;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_USP = 7;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_USD_END = 8;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_USD_ENDX = 9;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_END_B6_INSERT = 10;
typedef bit<4> switch_srv6_flavors_t;
const switch_srv6_flavors_t SWITCH_SRV6_FLAVORS_PSP = 1 << 0;
const switch_srv6_flavors_t SWITCH_SRV6_FLAVORS_USP = 1 << 1;
const switch_srv6_flavors_t SWITCH_SRV6_FLAVORS_USD = 1 << 2;
const switch_srv6_flavors_t SWITCH_SRV6_FLAVORS_COC = 1 << 3;
typedef bit<3> switch_netport_group_t;
typedef bit<1> switch_ptag_mod_t;
typedef bit<2> switch_ptag_action_t;
const switch_ptag_action_t VLANTAG_RAW_MODE = 0;
const switch_ptag_action_t VLANTAG_REPLACE_IF_PRESENT = 1;
const switch_ptag_action_t VLANTAG_NOREPLACE_IF_PRESENT = 2;
typedef bit<3> switch_tunnel_tc_t;
typedef bit<11> switch_ip_index_t;
struct switch_ingress_tunnel_metadata_t {
    switch_tunnel_type_t    type;
    bit<24>                 vni;
    bool                    terminate;
    bit<8>                  ttl;
    bit<20>                 first_label;
    bit<20>                 second_label;
    bit<20>                 third_label;
    bit<20>                 last_label;
    bit<20>                 entropy_label;
    switch_drop_reason_t    drop_reason;
    switch_tunnel_tc_t      exp;
    bit<8>                  label_space;
    bool                    ttl_copy;
    bool                    exp_mode;
    bool                    continue;
    switch_next_hdr_type_t  next_hdr_type;
    bit<1>                  bos;
    switch_ptag_mod_t       ptag_igmod;
    switch_ptag_action_t    ptag_eg_action;
    bit<16>                 ptag_tpid;
    vlan_id_t               ptag_vid;
    bool                    mpls_enable;
    bit<8>                  php_ttl;
    bit<8>                  tmp_ttl;
    bool                    php_terminate;
    bool                    ttl_copy_1;
    bool                    ttl_copy_2;
    bool                    ttl_copy_3;
    bool                    ttl_copy_4;
    bit<8>                  ttl_1;
    bit<8>                  ttl_2;
    bit<8>                  ttl_3;
    bit<8>                  ttl_4;
    switch_ingress_bypass_t bypass;
    bit<16>                 l4_encap;
    bool                    ip_addr_miss;
    bit<4>                  inner_type;
    bit<4>                  inner_pkt_parsed;
    bit<4>                  srv6_end_type;
    switch_srv6_flavors_t   srv6_flavors;
    switch_lif_t            tmp_l3iif;
    switch_lif_t            tmp_l2iif;
}

struct switch_ingress_ebridge_metadata_t {
    switch_lif_t               l2iif;
    switch_lif_t               l2oif;
    bit<16>                    learning_l2iif;
    switch_evlan_t             evlan;
    switch_learning_metadata_t learning;
    switch_evlan_label_t       evlan_label;
}

struct switch_ingress_route_metadata_t {
    bit<13>      vrf;
    switch_lif_t l3oif;
    switch_lif_t l4_l3oif;
    bit<1>       set_l4_l3oif;
    switch_lif_t l3_l3oif;
    bit<1>       set_l3_l3oif;
    switch_lif_t l2_l3oif;
    bit<1>       set_l2_l3oif;
    bit<4>       l4_sid_cnt;
    bit<4>       l3_sid_cnt;
    bit<4>       sid_cnt;
    bit<16>      pmtu;
    bit<1>       set_pmtu;
    bool         g_l3mac_enable;
    bool         rmac_hit;
    bit<8>       sip_l3class_id;
    bit<8>       dip_l3class_id;
    bit<14>      overlay_counter_index;
    bit<6>       nexthop_type;
    bit<2>       nexthop_cmd;
    bit<16>      mtu_check;
}

typedef bit<4> switch_acl_bypass_t;
const switch_acl_bypass_t SWITCH_ACL_BYPASS_FLOWSPEC = 1 << 0;
const switch_acl_bypass_t SWITCH_ACL_BYPASS_MIRROR = 1 << 1;
const switch_acl_bypass_t SWITCH_ACL_BYPASS_PBR = 1 << 1;
const switch_acl_bypass_t SWITCH_ACL_BYPASS_SAMPLE = 1 << 2;
const switch_acl_bypass_t SWITCH_ACL_BYPASS_QOS = 1 << 2;
const switch_acl_bypass_t SWITCH_ACL_BYPASS_ACL = 1 << 3;
const switch_acl_bypass_t SWITCH_ACL_BYPASS_1 = 1 << 0;
const switch_acl_bypass_t SWITCH_ACL_BYPASS_2 = 1 << 1;
const switch_acl_bypass_t SWITCH_ACL_BYPASS_3 = 1 << 2;
const switch_acl_bypass_t SWITCH_ACL_BYPASS_4 = 1 << 3;
typedef bit<16> switch_acl_classid_t;
struct switch_tmp_cpu_code_t {
    bit<1>  set;
    bit<16> cpu_code;
    bit<16> stats_id;
}

struct switch_ingress_policer_slice_t {
    switch_acl_bypass_t  group;
    switch_acl_classid_t group_classid;
}

struct switch_egress_policer_slice_t {
    switch_acl_bypass_t  group;
    switch_acl_classid_t group_classid;
}

struct switch_policer_pbr_t {
    bit<1> set_dscp;
    bit<6> dscp;
}

struct switch_ingress_policer_metadata_t {
    switch_ingress_policer_slice_t slice1;
    switch_ingress_policer_slice_t slice2;
    switch_ingress_policer_slice_t slice3;
    switch_ingress_policer_slice_t slice4;
    switch_ingress_policer_slice_t slice5;
    switch_ingress_policer_slice_t slice6;
    switch_ingress_policer_slice_t slice7;
    switch_ingress_policer_slice_t slice8;
    switch_acl_bypass_t            bypass;
    switch_pkt_color_t             meter_color;
    bit<16>                        ipv4_lif_label;
    bit<16>                        ipv6_lif_label;
    bit<1>                         drop;
    bit<1>                         mirror_enable;
    bit<15>                        iif;
    switch_acl_classid_t           group_classid_1;
    switch_acl_classid_t           group_classid_2;
    switch_acl_classid_t           group_classid_3;
    switch_acl_classid_t           group_classid_4;
    switch_acl_classid_t           v4_group_classid_1;
    switch_acl_classid_t           v4_group_classid_2;
    switch_acl_classid_t           v4_group_classid_3;
    switch_acl_classid_t           v4_group_classid_4;
    switch_acl_classid_t           v6_group_classid_1;
    switch_acl_classid_t           v6_group_classid_2;
    switch_acl_classid_t           v6_group_classid_3;
    switch_acl_classid_t           v6_group_classid_4;
}

struct switch_ingress_mirror_metadata_t {
    switch_pkt_src_t        src;
    switch_mirror_type_t    type;
    switch_mirror_session_t session_id;
    switch_mirror_session_t mirror_id;
}

struct switch_ingress_fabric_metadata_t {
    switch_cpu_reason_t reason_code;
    switch_cpu_reason_t cpu_reason;
}

typedef bit<128> srv6_sid_t;
struct switch_ingress_srv6_metadata_t {
    srv6_sid_t sid;
    srv6_sid_t g_sid;
    bit<32>    c_sid;
    bit<8>     prefixlen;
    bit<2>     si;
    bool       srh_terminate;
    bool       sl_is_zero;
    bool       sl_is_one;
    bit<8>     seg_left;
    bit<8>     last_entry;
    bit<8>     hdr_ext_len;
}

typedef bit<16> switch_ipfix_t;
typedef bit<16> switch_ipfix_flow_id_t;
typedef bit<16> switch_ipfix_gap_t;
typedef bit<16> switch_ipfix_random_t;
typedef bit<16> switch_ipfix_random_mask_t;
typedef bit<16> switch_ipfix_random_flag_t;
typedef bit<16> switch_ipfix_count_t;
typedef bit<16> switch_ipfix_sample_flag_t;
typedef bit<10> switch_ipfix_session_t;
typedef bit<1> switch_ipfix_enable_t;
typedef bit<1> switch_ipfix_mode_t;
const switch_pkt_type_t SWITCH_IPFIX_PKT_TYPE_IPV4 = 1;
const switch_pkt_type_t SWITCH_IPFIX_PKT_TYPE_MPLS = 2;
const switch_pkt_type_t SWITCH_IPFIX_PKT_TYPE_IPV6 = 3;
const switch_pkt_type_t CPU_ETH_PKT_TYPE_IPFIX = 1;
const switch_pkt_type_t CPU_ETH_PKT_TYPE_BFD = 2;
const switch_pkt_type_t CPU_ETH_PKT_TYPE_SPE_IPFIX = 3;
struct switch_ipfix_metadata_t {
    switch_bridge_type_t       bridge_md_type;
    bool                       enable;
    switch_pkt_type_t          pkt_type;
    switch_ipfix_mode_t        mode;
    switch_pkt_src_t           src;
    switch_ipfix_flow_id_t     flow_id;
    switch_ipfix_gap_t         sample_gap;
    switch_ipfix_random_t      random_num;
    switch_ipfix_random_flag_t random_flag;
    switch_ipfix_random_mask_t random_mask;
    switch_ipfix_count_t       count;
    switch_ipfix_sample_flag_t sample_flag;
    switch_ipfix_session_t     session_id;
    bit<16>                    ether_type;
    bit<16>                    delta;
}

struct switch_egress_tunnel_metadata_t {
    switch_tunnel_type_t       type;
    switch_tunnel_encap_type_t encap_type;
    bool                       terminate;
    bit<1>                     bak_first;
    switch_next_hdr_type_t     next_hdr_type;
    switch_src_index_t         src_index;
    bit<8>                     label_space;
    bit<8>                     ttl;
    bit<1>                     ilm;
    bool                       ttl_copy;
    bit<2>                     dscp_sel;
    bit<6>                     inner_dscp;
    bit<8>                     tc;
    switch_netport_group_t     src_netport_group;
    switch_netport_group_t     dst_netport_group;
    switch_ptag_mod_t          ptag_igmod;
    switch_ptag_action_t       ptag_eg_action;
    vlan_id_t                  ptag_vid;
    bit<16>                    ptag_tpid;
    bit<16>                    pw_id;
    bit<8>                     vc_ttl;
    bit<3>                     vc_exp;
    bit<3>                     exp;
    bit<1>                     bos;
    bit<16>                    ether_type;
    bit<20>                    first_label;
    bit<20>                    second_label;
    bit<20>                    third_label;
    bit<20>                    last_label;
    switch_drop_reason_t       drop_reason;
    switch_egress_bypass_t     bypass;
    switch_tunnel_type_t       tunnel_type;
    bit<16>                    l4_encap;
    bit<24>                    vni;
    switch_lif_t               tmp_l3iif;
    bit<4>                     srv6_end_type;
    bit<1>                     l3_encap_mapping_hit;
}

struct switch_egress_checks_t {
    switch_lif_t same_if;
    switch_mtu_t mtu;
}

struct switch_egress_ebridge_metadata_t {
    switch_evlan_t         evlan;
    switch_egress_checks_t checks;
    switch_evlan_label_t   evlan_label;
    switch_lif_t           l2oif;
}

struct switch_egress_route_metadata_t {
    bit<13> vrf;
    bool    ipv4_unicast_enable;
    bool    ipv6_unicast_enable;
    bool    rmac_hit;
    bit<16> pbr_nexthop;
    bit<8>  pbr_priority;
    bit<1>  pbr_is_ecmp;
    bit<2>  pbr_level;
    bit<8>  priority;
    bit<1>  disable_urpf;
    bit<1>  is_ecmp;
    bit<2>  level;
    bit<8>  priority_check;
    bit<8>  sip_l3class_id;
    bit<8>  dip_l3class_id;
    bit<8>  drop_reason;
    bit<16> local_l3_encap_id;
}

struct switch_egress_policer_metadata_t {
    switch_egress_policer_slice_t slice1;
    switch_egress_policer_slice_t slice2;
    switch_egress_policer_slice_t slice3;
    switch_egress_policer_slice_t slice4;
    switch_egress_policer_slice_t slice5;
    switch_egress_policer_slice_t slice6;
    switch_egress_policer_slice_t slice7;
    switch_egress_policer_slice_t slice8;
    switch_policer_pbr_t          pbr;
    switch_acl_bypass_t           bypass;
    bit<16>                       ipv4_lif_label;
    bit<16>                       ipv6_lif_label;
    bit<1>                        drop;
    switch_pkt_color_t            meter_color;
    bit<1>                        mirror_enable;
    switch_acl_classid_t          group_classid_1;
    switch_acl_classid_t          group_classid_2;
    switch_acl_classid_t          group_classid_3;
    switch_acl_classid_t          group_classid_4;
    switch_acl_classid_t          v4_group_classid_1;
    switch_acl_classid_t          v4_group_classid_2;
    switch_acl_classid_t          v4_group_classid_3;
    switch_acl_classid_t          v4_group_classid_4;
    switch_acl_classid_t          v6_group_classid_1;
    switch_acl_classid_t          v6_group_classid_2;
    switch_acl_classid_t          v6_group_classid_3;
    switch_acl_classid_t          v6_group_classid_4;
}

struct switch_egress_mirror_metadata_t {
    switch_pkt_src_t        src;
    switch_mirror_type_t    type;
    switch_mirror_session_t session_id;
    switch_mirror_session_t mirror_id;
}

struct switch_egress_fabric_metadata_t {
    switch_cpu_reason_t reason_code;
    switch_cpu_reason_t cpu_reason;
}

struct switch_ingress_metadata_t {
    switch_ingress_common_metadata_t    common;
    switch_ingress_flags_t              flags;
    switch_lookup_fields_t              lkp;
    switch_ingress_ebridge_metadata_t   ebridge;
    switch_ingress_route_metadata_t     route;
    switch_ingress_multicast_metadata_t multicast;
    switch_ingress_tunnel_metadata_t    tunnel;
    switch_ingress_policer_metadata_t   policer;
    switch_ingress_mirror_metadata_t    mirror;
    switch_ingress_qos_metadata_t       qos;
    switch_ingress_fabric_metadata_t    fabric;
    switch_ingress_srv6_metadata_t      srv6;
    switch_ipfix_metadata_t             ipfix;
}

struct switch_egress_metadata_t {
    switch_egress_common_metadata_t    common;
    switch_egress_flags_t              flags;
    switch_lookup_fields_t             lkp;
    switch_egress_ebridge_metadata_t   ebridge;
    switch_egress_route_metadata_t     route;
    switch_egress_multicast_metadata_t multicast;
    switch_egress_tunnel_metadata_t    tunnel;
    switch_egress_policer_metadata_t   policer;
    switch_egress_mirror_metadata_t    mirror;
    switch_egress_qos_metadata_t       qos;
    switch_egress_fabric_metadata_t    fabric;
    switch_ipfix_metadata_t            ipfix;
}

header switch_bridged_metadata_lookahead_h {
    switch_pkt_src_t     src;
    switch_bridge_type_t type;
}

header switch_extension_lookahead_h {
    bit<3> ext_type;
    bit<1> extend;
    @padding
    bit<4> _pad;
}

header switch_bridged_src_h {
    switch_pkt_src_t     src;
    switch_bridge_type_t bridge_type;
}

header switch_bridged_metadata_base_h {
    switch_pkt_type_t pkt_type;
    bit<1>            is_mcast;
    bit<1>            is_mirror;
}

header switch_bridged_metadata_qos_encap_h {
    bit<8> data;
}

header switch_bridged_metadata_qos_h {
    bit<3> tc;
    bit<2> color;
    bit<1> chgDSCP_disable;
    bit<1> BA;
    bit<1> pad;
}

header switch_bridged_metadata_12_h {
    bit<1>         extend;
    bool           rmac_hit;
    bit<1>         flowspec_disable;
    bool           ttl_copy;
    @padding
    bit<4>         pad_flags;
    bit<8>         src_port;
    @padding
    bit<1>         pad_lif;
    switch_lif_t   iif;
    bit<8>         ttl;
    bit<8>         label_space;
    switch_evlan_t evlan;
}

header switch_bridged_metadata_34_encap_h {
    bit<8>       flags;
    @padding
    bit<8>       pad;
    bit<16>      l2_encap;
    bit<16>      l3_encap;
    bit<16>      egress_eport;
    @padding
    bit<1>       pad_iif;
    switch_lif_t iif;
    bit<8>       dip_l3class_id;
    bit<8>       sip_l3class_id;
}

header switch_bridged_metadata_34_h {
    bit<1>       extend;
    bit<1>       is_pbr_nhop;
    bit<1>       flowspec_disable;
    @padding
    bit<5>       dst_device;
    @padding
    bit<8>       dst_port;
    bit<16>      l2_encap;
    bit<16>      l3_encap;
    bit<16>      egress_eport;
    @padding
    bit<1>       pad_iif;
    switch_lif_t iif;
    bit<8>       dip_l3class_id;
    bit<8>       sip_l3class_id;
}

header switch_bridged_metadata_310_h {
    bit<16>      hash;
    bit<1>       pad_iif;
    switch_lif_t iif;
    bit<8>       src_port;
    bit<8>       cpu_reason;
}

header switch_bridged_metadata_78_h {
    bit<1>       extend;
    bit<1>       pcp_chg;
    bit<1>       exp_chg;
    bit<1>       ippre_chg;
    @padding
    bit<4>       pad;
    bit<8>       dst_port;
    bit<16>      l2_encap;
    bit<16>      l3_encap;
    bit<1>       pad_iif;
    switch_lif_t iif;
    bit<8>       sip_l3class_id;
    bit<8>       dip_l3class_id;
}

header switch_bridged_metadata_74_h {
    bit<8>  src_port;
    bit<1>  direction;
    @padding
    bit<7>  pad;
    bit<16> hash;
    bit<16> evlan;
}

header switch_bridged_metadata_910_h {
    bit<16>              combine_16;
    bit<1>               pad_iif;
    switch_lif_t         iif;
    bit<1>               pad_oif;
    switch_lif_t         oif;
    switch_acl_classid_t group_classid_1;
    switch_acl_classid_t group_classid_2;
}

header switch_bridged_metadata_910_decap_h {
    bit<1>               extend;
    bit<1>               pad;
    bit<6>               dst_ecid;
    switch_acl_bypass_t  acl_bypass;
    @padding
    bit<3>               pad_flags;
    bit<1>               drop;
    bit<1>               pad_iif;
    switch_lif_t         iif;
    bit<1>               pad_oif;
    switch_lif_t         oif;
    switch_acl_classid_t group_classid_1;
    switch_acl_classid_t group_classid_2;
}

header extension_eth_h {
    bit<16>      evlan;
    bit<1>       pad_oif;
    switch_lif_t l2oif;
}

header extension_tunnel_decap_h {
    bit<3>  ext_type;
    bit<1>  extend;
    @padding
    bit<4>  pad1;
    @padding
    bit<9>  pad2;
    bit<15> ul_iif;
}

header extension_l4_encap_h {
    bit<3>  ext_type;
    bit<1>  extend;
    @padding
    bit<4>  pad1;
    @padding
    bit<8>  pad2;
    bit<16> l4_encap;
}

header extension_l4_nh_h {
    bit<3>  ext_type;
    bit<1>  extend;
    @padding
    bit<4>  pad1;
    @padding
    bit<8>  pad2;
    bit<16> l4_nh;
}

header extension_srv6_h {
    bit<3>  ext_type;
    bit<1>  extend;
    bit<1>  bypass_L3;
    bit<2>  level;
    bit<1>  is_ecmp;
    bit<8>  priority;
    bit<16> nexthop;
}

header extension_cpp_h {
    bit<3> ext_type;
    bit<1> extend;
    @padding
    bit<4> pad1;
    @padding
    bit<6> pad2;
    bit<1> glean;
    bit<1> drop;
    bit<8> src_port;
    bit<8> cpu_reason;
}

header extension_mirror_h {
    bit<3>  ext_type;
    bit<1>  extend;
    @padding
    bit<2>  pad;
    bit<10> mirror_id;
}

header switch_port_mirror_metadata_h {
    switch_pkt_src_t        src;
    switch_mirror_type_t    type;
    bit<6>                  _pad;
    switch_mirror_session_t session_id;
    bit<1>                  _pad2;
    switch_device_t         dst_device;
    switch_logic_port_t     dst_port;
}

header switch_cpu_mirror_metadata_h {
    switch_pkt_src_t     src;
    switch_mirror_type_t type;
    switch_eport_t       eport;
    switch_evlan_t       evlan;
    switch_cpu_reason_t  reason_code;
}

header switch_ipfix_mirror_metadata_h {
    switch_pkt_src_t        src;
    switch_mirror_type_t    type;
    @padding
    bit<6>                  _pad1;
    switch_mirror_session_t session_id;
    bit<16>                 hash;
    @padding
    bit<1>                  _pad2;
    switch_lif_t            iif;
    @padding
    bit<1>                  _pad3;
    switch_lif_t            oif;
    @padding
    bit<1>                  _pad4;
    switch_lif_t            ul_iif;
}

@pa_no_overlay("egress", "hdr.mpls_vc_eg.label") struct switch_header_t {
    switch_bridged_src_h                switch_bridged_src;
    fabric_base_h                       fabric_base;
    switch_bridged_metadata_base_h      bridged_md_base;
    fabric_qos_h                        fabric_qos;
    switch_bridged_metadata_qos_h       bridged_md_qos;
    switch_bridged_metadata_qos_encap_h bridged_md_qos_encap;
    switch_bridged_metadata_12_h        bridged_md_12;
    switch_bridged_metadata_34_encap_h  bridged_md_34_encap;
    switch_bridged_metadata_34_h        bridged_md_34;
    switch_bridged_metadata_310_h       bridged_md_310;
    switch_bridged_metadata_78_h        bridged_md_78;
    switch_bridged_metadata_74_h        bridged_md_74;
    switch_bridged_metadata_910_h       bridged_md_910;
    switch_bridged_metadata_910_decap_h bridged_md_910_decap;
    fabric_unicast_ext_bfn_igfpga_h     fabric_unicast_ext_bfn_igfpga;
    fabric_unicast_ext_igfpga_bfn_h     fabric_unicast_ext_igfpga_bfn;
    fabric_unicast_dst_h                fabric_unicast_dst;
    fabric_unicast_ext_fe_encap_h       fabric_unicast_ext_fe_encap;
    fabric_unicast_ext_fe_h             fabric_unicast_ext_fe;
    fabric_unicast_ext_eg_h             fabric_unicast_ext_eg;
    fabric_unicast_ext_eg_decap_h       fabric_unicast_ext_eg_decap;
    fabric_var_ext_1_16bit_h            fabric_var_ext_1_16bit;
    fabric_var_ext_2_8bit_h             fabric_var_ext_2_8bit;
    fabric_multicast_dst_h              fabric_multicast_dst;
    fabric_multicast_ext_h              fabric_multicast_ext;
    fabric_one_pad_h                    fabric_one_pad;
    fabric_var_ext_1_16bit_h            fabric_post_one_pad_encap;
    fabric_post_one_pad_h               fabric_post_one_pad;
    fabric_cpu_data_h                   fabric_cpu_data;
    fabric_payload_h                    fabric_payload;
    extension_srv6_h                    ext_srv6;
    extension_l4_nh_h                   ext_l4_nh;
    extension_cpp_h                     ext_cpp;
    extension_l4_encap_h                ext_l4_encap;
    extension_mirror_h                  ext_mirror;
    extension_tunnel_decap_h            ext_tunnel_decap;
    extension_eth_h                     ext_eth;
    ethernet_h                          ethernet;
    fabric_eth_base_to_cpu_h            fabric_eth_base_to_cpu;
    fabric_ipfix_to_cpu_h               fabric_ipfix_to_cpu;
    fabric_bfd_to_cpu_h                 fabric_bfd_to_cpu;
    fabric_ipfix_special_h              fabric_ipfix_special;
    fabric_eth_base_from_cpu_h          fabric_eth_base_from_cpu;
    fabric_eth_from_cpu_data_h          fabric_eth_from_cpu_data;
    fabric_payload_h                    fabric_eth_etype;
    timestamp_h                         timestamp;
    br_tag_h                            br_tag;
    vlan_tag_h[2]                       vlan_tag;
    mpls_h[6]                           mpls_ig;
    mpls_h[10]                          mpls_eg;
    mpls_h                              mpls_vc_eg;
    mpls_h                              mpls_flow_eg;
    cw_h                                cw;
    ipv4_h                              ipv4;
    ipv4_option_h                       ipv4_option;
    ipv6_h                              ipv6;
    ipv6_srh_h                          srv6_srh;
    srv6_list_h[10]                     srv6_list;
    arp_h                               arp;
    udp_h                               udp;
    icmp_h                              icmp;
    igmp_h                              igmp;
    tcp_h                               tcp;
    vxlan_h                             vxlan;
    gre_h                               gre;
    nvgre_h                             nvgre;
    geneve_h                            geneve;
    erspan_h                            erspan;
    erspan_type2_h                      erspan_type2;
    erspan_type3_h                      erspan_type3;
    erspan_platform_h                   erspan_platform;
    ethernet_h                          inner_ethernet;
    vlan_tag_h[2]                       inner_vlan_tag;
    ipv4_h                              inner_ipv4;
    ipv6_h                              inner_ipv6;
    udp_h                               inner_udp;
    tcp_h                               inner_tcp;
    icmp_h                              inner_icmp;
}

action add_bridged_md_uc_base(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md, switch_bridge_type_t bridge_type) {
    hdr.switch_bridged_src.setValid();
    hdr.switch_bridged_src.src = SWITCH_PKT_SRC_BRIDGED;
    hdr.switch_bridged_src.bridge_type = bridge_type;
    hdr.bridged_md_base.setValid();
    hdr.bridged_md_base.pkt_type = ig_md.common.pkt_type;
    hdr.bridged_md_base.is_mirror = 0;
    hdr.bridged_md_base.is_mcast = 0;
}
action add_bridged_md_mc_base(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md, switch_bridge_type_t bridge_type) {
    hdr.switch_bridged_src.setValid();
    hdr.switch_bridged_src.src = SWITCH_PKT_SRC_BRIDGED;
    hdr.switch_bridged_src.bridge_type = bridge_type;
    hdr.bridged_md_base.setValid();
    hdr.bridged_md_base.pkt_type = ig_md.common.pkt_type;
    hdr.bridged_md_base.is_mirror = 0;
    hdr.bridged_md_base.is_mcast = 1;
}
action add_bridged_md_mirror_base(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md, switch_bridge_type_t bridge_type) {
    hdr.switch_bridged_src.setValid();
    hdr.switch_bridged_src.src = SWITCH_PKT_SRC_BRIDGED;
    hdr.switch_bridged_src.bridge_type = bridge_type;
    hdr.bridged_md_base.setValid();
    hdr.bridged_md_base.pkt_type = ig_md.common.pkt_type;
    hdr.bridged_md_base.is_mirror = 1;
    hdr.bridged_md_base.is_mcast = 0;
}
action add_bridged_md_qos(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md) {
    hdr.bridged_md_qos.setValid();
    hdr.bridged_md_qos.tc = ig_md.qos.tc;
    hdr.bridged_md_qos.color = ig_md.qos.color;
    hdr.bridged_md_qos.chgDSCP_disable = ig_md.qos.chgDSCP_disable;
    hdr.bridged_md_qos.BA = ig_md.qos.BA;
}
action add_ext_eth(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md) {
    hdr.ext_eth.setValid();
    hdr.ext_eth.evlan = ig_md.ebridge.evlan;
    hdr.ext_eth.l2oif = ig_md.ebridge.l2oif;
}
action add_ext_tunnel_decap(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md) {
    ig_md.flags.ext_tunnel_decap = true;
    ig_md.common.extend = 1w1;
    hdr.ext_tunnel_decap.setValid();
    hdr.ext_tunnel_decap.ext_type = FABRIC_EXT_TYPE_TUNNEL_DECAP;
    hdr.ext_tunnel_decap.extend = 0;
    hdr.ext_tunnel_decap.ul_iif = ig_md.common.iif;
}
action add_ext_l4_encap(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md, bit<1> extend, bit<16> l4_encap) {
    ig_md.flags.ext_l4_encap = true;
    ig_md.common.extend = 1w1;
    hdr.ext_l4_encap.setValid();
    hdr.ext_l4_encap.ext_type = FABRIC_EXT_TYPE_L4_ENCAP;
    hdr.ext_l4_encap.extend = extend;
    hdr.ext_l4_encap.l4_encap = l4_encap;
}
action add_ext_srv6(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md, bit<1> extend, bit<1> bypass_L3, bit<2> level, bit<1> is_ecmp, bit<8> priority, bit<16> nexthop) {
    hdr.ext_srv6.setValid();
    hdr.ext_srv6.ext_type = BRIDGED_MD_EXT_TYPE_SRV6;
    hdr.ext_srv6.extend = extend;
    hdr.ext_srv6.bypass_L3 = bypass_L3;
    hdr.ext_srv6.level = level;
    hdr.ext_srv6.is_ecmp = is_ecmp;
    hdr.ext_srv6.priority = priority;
    hdr.ext_srv6.nexthop = nexthop;
}
action add_ext_cpp(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md, bit<1> glean) {
    hdr.ext_cpp.setValid();
    ig_md.flags.ext_cpp = true;
    ig_md.common.extend = 1;
    hdr.ext_cpp.ext_type = BRIDGED_MD_EXT_TYPE_CPP;
    hdr.ext_cpp.extend = 0;
    hdr.ext_cpp.glean = glean;
    hdr.ext_cpp.drop = 0;
    hdr.ext_cpp.src_port = ig_md.common.src_port;
    hdr.ext_cpp.cpu_reason = ig_md.common.cpu_reason;
}
action add_ext_mirror(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md, in switch_mirror_session_t mirror_id) {
    hdr.ext_mirror.setValid();
    ig_md.flags.ext_mirror = true;
    ig_md.common.extend = 1;
    hdr.ext_mirror.ext_type = BRIDGED_MD_EXT_TYPE_MIRROR;
    hdr.ext_mirror.extend = 0;
    hdr.ext_mirror.mirror_id = mirror_id;
}
action init_bridge_type(inout switch_ingress_metadata_t ig_md, switch_bridge_type_t bridge_type) {
    ig_md.common.bridge_type = bridge_type;
}
control BridgedMetadata_FRONT(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md) {
    Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_8;
    action add_bridged_md_pipe12() {
        add_bridged_md_uc_base(hdr, ig_md, BRIDGE_TYPE_FRONT_UPLINK);
        hdr.bridged_md_qos_encap.setValid();
        hdr.bridged_md_qos_encap.data = hash_8.get({ ig_md.qos.tc ++ ig_md.qos.color ++ ig_md.qos.chgDSCP_disable ++ ig_md.qos.BA ++ ig_md.qos.car_flags });
        hdr.bridged_md_12.setValid();
        hdr.bridged_md_12.extend = ig_md.common.extend;
        hdr.bridged_md_12.rmac_hit = ig_md.route.rmac_hit;
        hdr.bridged_md_12.ttl_copy = ig_md.tunnel.ttl_copy;
        hdr.bridged_md_12.flowspec_disable = ig_md.flags.flowspec_disable;
        hdr.bridged_md_12.src_port = ig_md.common.src_port;
        hdr.bridged_md_12.iif = ig_md.common.iif;
        hdr.bridged_md_12.ttl = ig_md.tunnel.ttl;
        hdr.bridged_md_12.label_space = 0;
        hdr.bridged_md_12.evlan = ig_md.ebridge.evlan;
    }
    table add_bridged_md {
        key = {
            ig_md.common.bridge_type: exact;
        }
        actions = {
            NoAction;
            add_bridged_md_pipe12;
        }
        const default_action = NoAction;
        size = 8;
        const entries = {
                        BRIDGE_TYPE_FRONT_UPLINK : add_bridged_md_pipe12();
        }

    }
    apply {
        add_bridged_md.apply();
    }
}

control BridgedMetadata_extend_FRONT(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md) {
    action set_srv6_extend_bit() {
        hdr.ext_srv6.extend = 1w1;
    }
    table set_extend_bit {
        key = {
            hdr.ext_tunnel_decap.isValid(): exact;
            ig_md.flags.ext_srv6          : exact;
        }
        actions = {
            NoAction;
            set_srv6_extend_bit;
        }
        const default_action = NoAction;
        size = 4;
        const entries = {
                        (true, true) : set_srv6_extend_bit();
        }

    }
    apply {
        set_extend_bit.apply();
    }
}

control BridgedMetadata_extend_UPLINK(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md) {
    action set_cpp_extend_bit() {
        hdr.ext_cpp.extend = 1w1;
    }
    action set_l4encap_extend_bit() {
        hdr.ext_l4_encap.extend = 1w1;
    }
    action set_cpp_l4encap_extend_bit() {
        hdr.ext_cpp.extend = 1w1;
        hdr.ext_l4_encap.extend = 1w1;
    }
    table set_extend_bit {
        key = {
            hdr.ext_tunnel_decap.isValid(): exact;
            ig_md.flags.ext_cpp           : exact;
            ig_md.flags.ext_l4_encap      : exact;
        }
        actions = {
            NoAction;
            set_cpp_extend_bit;
            set_l4encap_extend_bit;
            set_cpp_l4encap_extend_bit;
        }
        const default_action = NoAction;
        size = 8;
        const entries = {
                        (true, true, true) : set_cpp_l4encap_extend_bit();
                        (true, true, false) : set_cpp_extend_bit();
                        (true, false, true) : set_l4encap_extend_bit();
                        (false, true, true) : set_cpp_extend_bit();
        }

    }
    apply {
        set_extend_bit.apply();
    }
}

control BridgedMetadata_extend_DOWNLINK(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md) {
    action set_mirror_extend_bit() {
        hdr.ext_mirror.extend = 1w1;
    }
    table set_extend_bit {
        key = {
            hdr.ext_tunnel_decap.isValid(): exact;
            ig_md.flags.ext_mirror        : exact;
        }
        actions = {
            NoAction;
            set_mirror_extend_bit;
        }
        const default_action = NoAction;
        size = 4;
        const entries = {
                        (true, true) : set_mirror_extend_bit();
        }

    }
    apply {
        set_extend_bit.apply();
    }
}

control BridgedMetadata_UPLINK(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md) {
    Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_8;
    action add_bridged_md_pipe34() {
        add_bridged_md_uc_base(hdr, ig_md, BRIDGE_TYPE_UPLINK_FABRIC);
        add_bridged_md_qos(hdr, ig_md);
        hdr.bridged_md_34_encap.setValid();
        hdr.bridged_md_34_encap.flags = hash_8.get({ ig_md.common.extend ++ ig_md.flags.is_pbr_nhop ++ ig_md.flags.flowspec_disable ++ 5w0 });
        hdr.bridged_md_34_encap.l2_encap = ig_md.common.l2_encap;
        hdr.bridged_md_34_encap.l3_encap = ig_md.common.l3_encap;
        hdr.bridged_md_34_encap.egress_eport = ig_md.common.egress_eport;
        hdr.bridged_md_34_encap.iif = ig_md.common.iif;
        hdr.bridged_md_34_encap.sip_l3class_id = ig_md.route.sip_l3class_id;
        hdr.bridged_md_34_encap.dip_l3class_id = ig_md.route.dip_l3class_id;
    }
    action add_bridged_md_pipe34_eth() {
        add_bridged_md_pipe34();
        add_ext_eth(hdr, ig_md);
    }
    action add_bridged_md_pipe310() {
        add_bridged_md_uc_base(hdr, ig_md, BRIDGE_TYPE_UPLINK_FRONT);
        hdr.bridged_md_310.setValid();
        hdr.bridged_md_310.hash = ig_md.common.hash;
        hdr.bridged_md_310.iif = ig_md.common.iif;
        hdr.bridged_md_310.src_port = ig_md.common.src_port;
        hdr.bridged_md_310.cpu_reason = ig_md.common.cpu_reason;
    }
    table add_bridged_md {
        key = {
            ig_md.common.bridge_type: exact;
            ig_md.common.pkt_type   : ternary;
        }
        actions = {
            NoAction;
            add_bridged_md_pipe34;
            add_bridged_md_pipe34_eth;
            add_bridged_md_pipe310;
        }
        const default_action = NoAction;
        size = 8;
        const entries = {
                        (BRIDGE_TYPE_UPLINK_FRONT, default) : add_bridged_md_pipe310();
                        (BRIDGE_TYPE_UPLINK_FABRIC, FABRIC_PKT_TYPE_ETH) : add_bridged_md_pipe34_eth();
                        (BRIDGE_TYPE_UPLINK_FABRIC, default) : add_bridged_md_pipe34();
        }

    }
    apply {
        add_bridged_md.apply();
    }
}

control BridgedMetadata_UPLINK_FABRIC(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md) {
    Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_8;
    action add_bridged_md_pipe78() {
        add_bridged_md_uc_base(hdr, ig_md, BRIDGE_TYPE_FABRIC_DOWNLINK);
        add_bridged_md_qos(hdr, ig_md);
        hdr.bridged_md_78.setValid();
        hdr.bridged_md_78.extend = ig_md.common.extend;
        hdr.bridged_md_78.pcp_chg = ig_md.qos.pcp_chg;
        hdr.bridged_md_78.exp_chg = ig_md.qos.exp_chg;
        hdr.bridged_md_78.ippre_chg = ig_md.qos.ippre_chg;
        hdr.bridged_md_78.dst_port = ig_md.common.dst_port;
        hdr.bridged_md_78.l2_encap = ig_md.common.l2_encap;
        hdr.bridged_md_78.l3_encap = ig_md.common.l3_encap;
        hdr.bridged_md_78.iif = ig_md.common.iif;
        hdr.bridged_md_78.sip_l3class_id = ig_md.route.sip_l3class_id;
        hdr.bridged_md_78.dip_l3class_id = ig_md.route.dip_l3class_id;
    }
    action add_bridged_md_pipe78_eth() {
        add_bridged_md_pipe78();
        add_ext_eth(hdr, ig_md);
    }
    table add_bridged_md {
        key = {
            ig_md.common.pkt_type: exact;
        }
        actions = {
            add_bridged_md_pipe78;
            add_bridged_md_pipe78_eth;
        }
        const default_action = add_bridged_md_pipe78;
        size = 8;
        const entries = {
                        FABRIC_PKT_TYPE_ETH : add_bridged_md_pipe78_eth();
        }

    }
    apply {
        add_bridged_md.apply();
    }
}

control BridgedMetadata_FABRIC(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md) {
    Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_8;
    action add_bridged_md_pipe78() {
        add_bridged_md_uc_base(hdr, ig_md, BRIDGE_TYPE_FABRIC_DOWNLINK);
        add_bridged_md_qos(hdr, ig_md);
        hdr.bridged_md_78.setValid();
        hdr.bridged_md_78.extend = ig_md.common.extend;
        hdr.bridged_md_78.pcp_chg = ig_md.qos.pcp_chg;
        hdr.bridged_md_78.exp_chg = ig_md.qos.exp_chg;
        hdr.bridged_md_78.ippre_chg = ig_md.qos.ippre_chg;
        hdr.bridged_md_78.dst_port = ig_md.common.dst_port;
        hdr.bridged_md_78.l2_encap = ig_md.common.l2_encap;
        hdr.bridged_md_78.l3_encap = ig_md.common.l3_encap;
        hdr.bridged_md_78.iif = ig_md.common.iif;
        hdr.bridged_md_78.sip_l3class_id = ig_md.route.sip_l3class_id;
        hdr.bridged_md_78.dip_l3class_id = ig_md.route.dip_l3class_id;
    }
    action add_bridged_md_pipe78_eth() {
        add_bridged_md_pipe78();
        add_ext_eth(hdr, ig_md);
    }
    action add_bridged_md_pipe74() {
        add_bridged_md_uc_base(hdr, ig_md, BRIDGE_TYPE_FABRIC_FABRIC);
        hdr.bridged_md_74.setValid();
        hdr.bridged_md_74.src_port = ig_md.common.src_port;
        hdr.bridged_md_74.direction = ig_md.common.cpu_direction;
        hdr.bridged_md_74.hash = ig_md.common.hash;
        hdr.bridged_md_74.evlan = ig_md.ebridge.evlan;
    }
    table add_bridged_md {
        key = {
            ig_md.common.pkt_type: exact;
        }
        actions = {
            add_bridged_md_pipe78;
            add_bridged_md_pipe78_eth;
            add_bridged_md_pipe74;
        }
        const default_action = add_bridged_md_pipe78;
        size = 8;
        const entries = {
                        FABRIC_PKT_TYPE_ETH : add_bridged_md_pipe78_eth();
                        FABRIC_PKT_TYPE_CPU_PCIE : add_bridged_md_pipe74();
        }

    }
    apply {
        add_bridged_md.apply();
    }
}

control BridgedMetadata_DOWNLINK(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md) {
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) hash_16;
    Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_8;
    action add_bridged_md_pipe910() {
        add_bridged_md_uc_base(hdr, ig_md, BRIDGE_TYPE_DOWNLINK_FRONT);
        add_bridged_md_qos(hdr, ig_md);
        hdr.bridged_md_910.setValid();
        hdr.bridged_md_910.combine_16 = hash_16.get({ ig_md.common.extend ++ 1w0 ++ ig_md.common.dst_ecid ++ ig_md.policer.bypass ++ 3w0 ++ ig_md.flags.drop });
        hdr.bridged_md_910.iif = ig_md.common.iif;
        hdr.bridged_md_910.oif = ig_md.common.oif;
        hdr.bridged_md_910.group_classid_1 = ig_md.policer.slice5.group_classid;
        hdr.bridged_md_910.group_classid_2 = ig_md.policer.slice6.group_classid;
    }
    table add_bridged_md {
        key = {
            ig_md.common.bridge_type: exact;
        }
        actions = {
            NoAction;
            add_bridged_md_pipe910;
        }
        const default_action = NoAction;
        size = 8;
        const entries = {
                        BRIDGE_TYPE_DOWNLINK_FRONT : add_bridged_md_pipe910();
        }

    }
    apply {
        add_bridged_md.apply();
    }
}

action add_mirror_translate_md(inout fabric_base_h bridged_md_base, in switch_ingress_metadata_t ig_md) {
}
control IgPortMirror(in switch_port_t port, in switch_pkt_src_t src, inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(switch_uint32_t table_size=256) {
    action set_mirror_id(switch_mirror_session_t mirror_id) {
        ig_md.mirror.mirror_id = mirror_id;
    }
    table ingress_port_mirror {
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
        ingress_port_mirror.apply();
    }
}

control EgPortMirror(in switch_port_t port, in switch_pkt_src_t src, inout switch_egress_metadata_t eg_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)(switch_uint32_t table_size=256) {
    action set_mirror_id(switch_mirror_session_t mirror_id) {
        eg_md.mirror.mirror_id = mirror_id;
    }
    table egress_port_mirror {
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
        egress_port_mirror.apply();
    }
}

control IgMirrorLag(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, in bit<16> hash) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(128, selector_hash, SelectorMode_t.FAIR) mirror_lag_selector;
    action set_mirror_session(switch_mirror_session_t sess_id, switch_device_t device, switch_logic_port_t port) {
        ig_md.mirror.type = 1;
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        ig_intr_md_for_dprsr.mirror_type = (bit<3>)1;
        ig_md.mirror.session_id = sess_id;
        ig_md.common.dst_device = device;
        ig_md.common.dst_port = port;
    }
    @ignore_table_dependency("Ig_front.ipv6_acl1.acl") @ignore_table_dependency("Ig_front.ipv6_acl2.acl") @ignore_table_dependency("Ig_front.ipv6_acl3.acl") @ignore_table_dependency("Ig_front.ipv4_acl1.acl") @ignore_table_dependency("Ig_front.ipv4_acl2.acl") table mirror_lag {
        key = {
            ig_md.mirror.mirror_id: exact;
            hash                  : selector;
        }
        actions = {
            NoAction;
            set_mirror_session;
        }
        const default_action = NoAction;
        size = 128;
        implementation = mirror_lag_selector;
    }
    apply {
        mirror_lag.apply();
    }
}

control EgMirrorLag(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, in bit<16> hash) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(128, selector_hash, SelectorMode_t.FAIR) mirror_lag_selector;
    action set_mirror_session(switch_mirror_session_t sess_id, switch_device_t device, switch_logic_port_t port) {
        eg_md.mirror.type = 1;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_intr_md_for_dprsr.mirror_type = (bit<3>)1;
        eg_md.mirror.session_id = sess_id;
        eg_md.common.dst_device = device;
        eg_md.common.dst_port = port;
    }
    @ignore_table_dependency("Eg_front.acl.ipv6_acl1.acl") @ignore_table_dependency("Eg_front.acl.ipv6_acl2.acl") @ignore_table_dependency("Eg_front.acl.ipv4_acl1.acl") @ignore_table_dependency("Eg_front.acl.ipv4_acl2.acl") table mirror_lag {
        key = {
            eg_md.mirror.mirror_id: exact;
            hash                  : selector;
        }
        actions = {
            NoAction;
            set_mirror_session;
        }
        const default_action = NoAction;
        size = 128;
        implementation = mirror_lag_selector;
    }
    apply {
        mirror_lag.apply();
    }
}

parser SRHParser(packet_in pkt, inout switch_header_t hdr) {
    state start {
        transition parse_srh;
    }
    state parse_srh {
        transition accept;
    }
}

parser IgParser_fabric(packet_in pkt, out switch_header_t hdr, out switch_ingress_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    value_set<bit<16>>(1) udp_port_vxlan;
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;
    state start {
        pkt.extract(ig_intr_md);
        transition parse_port_metadata;
    }
    state parse_resubmit {
        transition accept;
    }
    state parse_port_metadata {
        switch_port_metadata_fabric_pipe_t port_md = port_metadata_unpack<switch_port_metadata_fabric_pipe_t>(pkt);
        ig_md.common.port_type = port_md.port_type;
        transition select(ig_md.common.port_type) {
            PORT_TYPE_FABRIC: parse_fabric_packet;
            PORT_TYPE_CPU_PCIE: parse_cpu;
            default: accept;
        }
    }
    state parse_fabric_packet {
        fabric_base_lookahead_h lookahead = pkt.lookahead<fabric_base_lookahead_h>();
        transition select(lookahead.pkt_type, lookahead.mirror, lookahead.mcast) {
            (FABRIC_PKT_TYPE_CPU_PCIE, default, default): parse_cpu;
            (default, 0, 0): parse_fabric_unicast;
            (default, 0, 1): parse_fabric_mcast;
            (default, 1, 0): parse_fabric_mirror;
            default: accept;
        }
    }
    state parse_fabric_unicast {
        pkt.extract(hdr.fabric_base);
        pkt.extract(hdr.fabric_qos);
        ig_md.common.pkt_type = hdr.fabric_base.pkt_type;
        transition select(ig_md.common.pkt_type) {
            FABRIC_PKT_TYPE_ETH: parse_fabric_unicast_eth;
            FABRIC_PKT_TYPE_IPV4: parse_fabric_unicast_ipv4;
            FABRIC_PKT_TYPE_IPV6: parse_fabric_unicast_ipv6;
            FABRIC_PKT_TYPE_MPLS: parse_fabric_unicast_mpls;
            default: accept;
        }
    }
    state parse_fabric_unicast_eth {
        pkt.extract(hdr.fabric_unicast_dst);
        pkt.extract(hdr.fabric_unicast_ext_fe);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad);
        pkt.extract(hdr.fabric_post_one_pad);
        ig_md.common.dst_port = hdr.fabric_unicast_dst.dst_port;
        transition select(hdr.fabric_unicast_dst.extend) {
            1: parse_fabric_fe_ext_0;
            default: parse_ethernet;
        }
    }
    state parse_fabric_unicast_ipv4 {
        pkt.extract(hdr.fabric_unicast_dst);
        pkt.extract(hdr.fabric_unicast_ext_fe);
        pkt.extract(hdr.fabric_var_ext_2_8bit);
        pkt.extract(hdr.fabric_one_pad);
        ig_md.common.dst_port = hdr.fabric_unicast_dst.dst_port;
        transition select(hdr.fabric_unicast_dst.extend) {
            1: parse_fabric_fe_ext_0;
            default: parse_ipv4;
        }
    }
    state parse_fabric_unicast_ipv6 {
        pkt.extract(hdr.fabric_unicast_dst);
        pkt.extract(hdr.fabric_unicast_ext_fe);
        pkt.extract(hdr.fabric_var_ext_2_8bit);
        pkt.extract(hdr.fabric_one_pad);
        ig_md.common.dst_port = hdr.fabric_unicast_dst.dst_port;
        transition select(hdr.fabric_unicast_dst.extend) {
            1: parse_fabric_fe_ext_0;
            default: parse_ipv6;
        }
    }
    state parse_fabric_unicast_mpls {
        pkt.extract(hdr.fabric_unicast_dst);
        pkt.extract(hdr.fabric_unicast_ext_fe);
        pkt.extract(hdr.fabric_var_ext_2_8bit);
        pkt.extract(hdr.fabric_one_pad);
        ig_md.common.dst_port = hdr.fabric_unicast_dst.dst_port;
        transition select(hdr.fabric_unicast_dst.extend) {
            1: parse_fabric_fe_ext_0;
            default: parse_mpls;
        }
    }
    state parse_fabric_fe_ext_0 {
        switch_extension_lookahead_h extension = pkt.lookahead<switch_extension_lookahead_h>();
        transition select(extension.ext_type) {
            FABRIC_EXT_TYPE_L4_ENCAP: parse_extension_l4_encap;
            BRIDGED_MD_EXT_TYPE_TUNNEL_DECAP: parse_extension_tunnel_decap;
            default: accept;
        }
    }
    state parse_extension_l4_encap {
        pkt.extract(hdr.ext_l4_encap);
        transition select(hdr.ext_l4_encap.extend) {
            1: parse_extension_tunnel_decap;
            default: parse_fabric_uc_end;
        }
    }
    state parse_extension_tunnel_decap {
        pkt.extract(hdr.ext_tunnel_decap);
        transition select(hdr.ext_tunnel_decap.extend) {
            0: parse_fabric_uc_end;
            default: accept;
        }
    }
    state parse_fabric_uc_end {
        transition select(ig_md.common.pkt_type) {
            FABRIC_PKT_TYPE_ETH: parse_ethernet;
            FABRIC_PKT_TYPE_IPV4: parse_ipv4;
            FABRIC_PKT_TYPE_IPV6: parse_ipv6;
            FABRIC_PKT_TYPE_MPLS: parse_mpls;
            default: accept;
        }
    }
    state parse_fabric_mcast {
        pkt.extract(hdr.fabric_base);
        ig_md.common.pkt_type = hdr.fabric_base.pkt_type;
        pkt.extract(hdr.fabric_qos);
        pkt.extract(hdr.fabric_multicast_dst);
        pkt.extract(hdr.fabric_multicast_ext);
        pkt.extract(hdr.fabric_one_pad);
        transition parse_ethernet;
    }
    state parse_fabric_mirror {
        pkt.extract(hdr.fabric_base);
        pkt.extract(hdr.fabric_qos);
        pkt.extract(hdr.fabric_unicast_dst);
        pkt.extract(hdr.fabric_unicast_ext_fe);
        pkt.extract(hdr.fabric_one_pad);
        ig_md.common.pkt_type = hdr.fabric_base.pkt_type;
        ig_md.common.is_mirror = 1;
        ig_md.common.bypass = SWITCH_INGRESS_BYPASS_ALL;
        ig_md.common.dst_port = hdr.fabric_unicast_dst.dst_port;
        ig_md.mirror.type = 1;
        transition parse_ethernet;
    }
    state parse_cpu {
        pkt.extract(hdr.fabric_base);
        pkt.extract(hdr.fabric_qos);
        pkt.extract(hdr.fabric_cpu_data);
        pkt.extract(hdr.fabric_payload);
        transition select(hdr.fabric_payload.ether_type) {
            0x8100: parse_vlan;
            0x800: parse_ipv4;
            0x806: parse_arp;
            0x86dd: parse_ipv6;
            0x8847: parse_mpls;
            0x9000: parse_ethernet;
            default: accept;
        }
    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x806: parse_arp;
            0x8100: parse_vlan;
            default: accept;
        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ig_md.lkp.ip_src_addr[31:0] = hdr.ipv4.src_addr;
        ig_md.lkp.ip_dst_addr[31:0] = hdr.ipv4.dst_addr;
        ig_md.lkp.ip_proto = hdr.ipv4.protocol;
        ig_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        ipv4_checksum.add(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            5: parse_ipv4_no_options;
            default: accept;
        }
    }
    state parse_ipv4_no_options {
        ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (1, 0): parse_icmp;
            (2, 0): parse_igmp;
            (6, 0): parse_tcp;
            (17, 0): parse_udp;
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
        pkt.extract(hdr.mpls_ig.next);
        transition select(hdr.mpls_ig.last.bos) {
            0: parse_mpls;
            1: parse_mpls_bos;
            default: accept;
        }
    }
    state parse_mpls_bos {
        transition accept;
    }
    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        ig_md.lkp.ip_src_addr = hdr.ipv6.src_addr;
        ig_md.lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        ig_md.lkp.ip_proto = hdr.ipv6.next_hdr;
        ig_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        transition select(hdr.ipv6.next_hdr) {
            58: parse_icmp;
            6: parse_tcp;
            17: parse_udp;
            default: accept;
        }
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        ig_md.lkp.l4_src_port = hdr.udp.src_port;
        ig_md.lkp.l4_dst_port = hdr.udp.dst_port;
        transition select(hdr.udp.dst_port) {
            default: accept;
        }
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        ig_md.lkp.l4_src_port = hdr.tcp.src_port;
        ig_md.lkp.l4_dst_port = hdr.tcp.dst_port;
        transition accept;
    }
    state parse_icmp {
        pkt.extract(hdr.icmp);
        ig_md.lkp.l4_src_port = hdr.icmp.typeCode;
        ig_md.lkp.l4_dst_port = 0;
        transition accept;
    }
    state parse_igmp {
        pkt.extract(hdr.igmp);
        transition accept;
    }
}

parser EgParser_fabric(packet_in pkt, out switch_header_t hdr, out switch_egress_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    value_set<bit<16>>(1) udp_port_vxlan;
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;
    @critical state start {
        pkt.extract(eg_intr_md);
        eg_md.common.pkt_length = eg_intr_md.pkt_length;
        eg_md.qos.qdepth = eg_intr_md.deq_qdepth;
        switch_port_mirror_metadata_h mirror_md = pkt.lookahead<switch_port_mirror_metadata_h>();
        transition select(mirror_md.src, mirror_md.type) {
            (SWITCH_PKT_SRC_BRIDGED, BRIDGE_TYPE_UPLINK_FABRIC): parse_bridged_pkt_34;
            (SWITCH_PKT_SRC_BRIDGED, BRIDGE_TYPE_FABRIC_FABRIC): parse_bridged_pkt_74;
            (SWITCH_PKT_SRC_CLONED_EGRESS, 2): parse_cpu_mirrored_metadata;
            (default, 1): parse_port_mirrored_metadata;
        }
    }
    state parse_bridged_pkt_34 {
        pkt.extract(hdr.switch_bridged_src);
        pkt.extract(hdr.bridged_md_base);
        pkt.extract(hdr.bridged_md_qos);
        pkt.extract(hdr.bridged_md_34);
        eg_md.common.pkt_type = hdr.bridged_md_base.pkt_type;
        eg_md.common.is_mcast = hdr.bridged_md_base.is_mcast;
        eg_md.qos.tc = hdr.bridged_md_qos.tc;
        eg_md.qos.color = hdr.bridged_md_qos.color;
        eg_md.qos.chgDSCP_disable = hdr.bridged_md_qos.chgDSCP_disable;
        eg_md.qos.BA = hdr.bridged_md_qos.BA;
        eg_md.flags.is_pbr_nhop = hdr.bridged_md_34.is_pbr_nhop;
        eg_md.flags.flowspec_disable = hdr.bridged_md_34.flowspec_disable;
        eg_md.common.l2_encap = hdr.bridged_md_34.l2_encap;
        eg_md.common.l3_encap = hdr.bridged_md_34.l3_encap;
        eg_md.common.egress_eport = hdr.bridged_md_34.egress_eport;
        eg_md.common.iif = hdr.bridged_md_34.iif;
        eg_md.route.dip_l3class_id = hdr.bridged_md_34.dip_l3class_id;
        eg_md.route.sip_l3class_id = hdr.bridged_md_34.sip_l3class_id;
        transition select(hdr.bridged_md_34.extend) {
            1: parse_bridged_34_ext_0;
            default: parse_bridged_end;
        }
    }
    state parse_bridged_34_ext_0 {
        switch_extension_lookahead_h extension = pkt.lookahead<switch_extension_lookahead_h>();
        transition select(extension.ext_type) {
            BRIDGED_MD_EXT_TYPE_CPP: parse_extension_cpp;
            BRIDGED_MD_EXT_TYPE_L4_ENCAP: parse_extension_l4_encap;
            BRIDGED_MD_EXT_TYPE_TUNNEL_DECAP: parse_extension_tunnel_decap;
            default: accept;
        }
    }
    state parse_extension_cpp {
        pkt.extract(hdr.ext_cpp);
        eg_md.flags.glean = hdr.ext_cpp.glean;
        transition select(hdr.ext_cpp.extend) {
            1: parse_bridged_34_ext_1;
            default: parse_bridged_end;
        }
    }
    state parse_bridged_34_ext_1 {
        switch_extension_lookahead_h extension = pkt.lookahead<switch_extension_lookahead_h>();
        transition select(extension.ext_type) {
            BRIDGED_MD_EXT_TYPE_L4_ENCAP: parse_extension_l4_encap;
            BRIDGED_MD_EXT_TYPE_TUNNEL_DECAP: parse_extension_tunnel_decap;
            default: accept;
        }
    }
    state parse_extension_l4_encap {
        pkt.extract(hdr.ext_l4_encap);
        transition select(hdr.ext_l4_encap.extend) {
            1: parse_bridged_34_ext_2;
            default: parse_bridged_end;
        }
    }
    state parse_bridged_34_ext_2 {
        switch_extension_lookahead_h extension = pkt.lookahead<switch_extension_lookahead_h>();
        transition select(extension.ext_type) {
            BRIDGED_MD_EXT_TYPE_TUNNEL_DECAP: parse_extension_tunnel_decap;
            default: accept;
        }
    }
    state parse_extension_tunnel_decap {
        pkt.extract(hdr.ext_tunnel_decap);
        transition select(hdr.ext_tunnel_decap.extend) {
            0: parse_bridged_end;
            default: accept;
        }
    }
    state parse_bridged_pkt_74 {
        pkt.extract(hdr.switch_bridged_src);
        pkt.extract(hdr.bridged_md_base);
        pkt.extract(hdr.bridged_md_qos);
        pkt.extract(hdr.bridged_md_74);
        eg_md.common.pkt_type = hdr.bridged_md_base.pkt_type;
        eg_md.common.is_mcast = hdr.bridged_md_base.is_mcast;
        transition select(eg_md.common.pkt_type) {
            FABRIC_PKT_TYPE_ETH: parse_ethernet;
            FABRIC_PKT_TYPE_IPV4: parse_ipv4;
            FABRIC_PKT_TYPE_IPV6: parse_ipv6;
            FABRIC_PKT_TYPE_MPLS: parse_mpls;
            default: accept;
        }
    }
    state parse_bridged_end {
        transition select(eg_md.common.pkt_type) {
            FABRIC_PKT_TYPE_ETH: parse_bridged_eth;
            FABRIC_PKT_TYPE_IPV4: parse_ipv4;
            FABRIC_PKT_TYPE_IPV6: parse_ipv6;
            FABRIC_PKT_TYPE_MPLS: parse_mpls;
            default: accept;
        }
    }
    state parse_bridged_eth {
        pkt.extract(hdr.ext_eth);
        eg_md.ebridge.evlan = hdr.ext_eth.evlan;
        eg_md.ebridge.l2oif = hdr.ext_eth.l2oif;
        transition parse_ethernet;
    }
    state parse_port_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.ethernet);
        eg_md.mirror.src = port_md.src;
        eg_md.mirror.session_id = port_md.session_id;
        eg_md.mirror.type = port_md.type;
        eg_md.common.bypass = SWITCH_EGRESS_BYPASS_ALL;
        eg_md.common.is_mirror = 1;
        eg_md.common.dst_device = port_md.dst_device;
        eg_md.common.dst_port = port_md.dst_port;
        eg_md.common.pkt_type = FABRIC_PKT_TYPE_MIRROR_TRAN;
        transition accept;
    }
    state parse_cpu_mirrored_metadata {
        switch_cpu_mirror_metadata_h cpu_md;
        pkt.extract(cpu_md);
        eg_md.flags.cpu_mirror_pkt = 1;
        transition accept;
    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x800: parse_ipv4;
            0x86dd: parse_ipv6;
            0x8100: parse_vlan;
            0x8100: parse_vlan;
            0x8847: parse_mpls;
            default: accept;
        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        eg_md.lkp.ip_src_addr[31:0] = hdr.ipv4.src_addr;
        eg_md.lkp.ip_dst_addr[31:0] = hdr.ipv4.dst_addr;
        eg_md.lkp.ip_proto = hdr.ipv4.protocol;
        eg_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        transition select(hdr.ipv4.protocol, hdr.ipv4.ihl, hdr.ipv4.frag_offset) {
            (6, 5, 0): parse_tcp;
            (17, 5, 0): parse_udp;
            (1, 5, 0): parse_icmp;
            (4, 5, 0): parse_inner_ipv4;
            (41, 5, 0): parse_inner_ipv6;
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
        pkt.extract(hdr.mpls_ig.next);
        transition select(hdr.mpls_ig.last.bos) {
            0: parse_mpls;
            1: parse_mpls_bos;
            default: accept;
        }
    }
    state parse_mpls_bos {
        transition accept;
    }
    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        eg_md.lkp.ip_src_addr = hdr.ipv6.src_addr;
        eg_md.lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        eg_md.lkp.ip_proto = hdr.ipv6.next_hdr;
        eg_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        transition select(hdr.ipv6.next_hdr) {
            6: parse_tcp;
            17: parse_udp;
            58: parse_icmp;
            4: parse_inner_ipv4;
            41: parse_inner_ipv6;
            default: accept;
        }
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        eg_md.lkp.l4_src_port = hdr.udp.src_port;
        eg_md.lkp.l4_dst_port = hdr.udp.dst_port;
        eg_md.lkp.tcp_flags = 0;
        transition select(hdr.udp.dst_port) {
            udp_port_vxlan: parse_vxlan;
            default: accept;
        }
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        eg_md.lkp.l4_src_port = hdr.tcp.src_port;
        eg_md.lkp.l4_dst_port = hdr.tcp.dst_port;
        eg_md.lkp.tcp_flags = hdr.tcp.flags;
        transition accept;
    }
    state parse_icmp {
        pkt.extract(hdr.icmp);
        eg_md.lkp.l4_src_port = hdr.icmp.typeCode;
        eg_md.lkp.l4_dst_port = 0;
        eg_md.lkp.tcp_flags = 0;
        transition accept;
    }
    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        transition accept;
    }
    state parse_inner_ipv4 {
        transition accept;
    }
    state parse_inner_ipv6 {
        transition accept;
    }
}

control IgMirror_fabric(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    Mirror() mirror;
    apply {
        if (ig_intr_md_for_dprsr.mirror_type == 1) {
            mirror.emit<switch_port_mirror_metadata_h>(ig_md.mirror.session_id, { ig_md.mirror.src, ig_md.mirror.type, 0, ig_md.mirror.session_id, 0, ig_md.common.dst_device, ig_md.common.dst_port });
        }
    }
}

control EgMirror_fabric(inout switch_header_t hdr, in switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    Mirror() mirror;
    apply {
        if (eg_intr_md_for_dprsr.mirror_type == 1) {
            mirror.emit<switch_port_mirror_metadata_h>(eg_md.mirror.session_id, { eg_md.mirror.src, eg_md.mirror.type, 0, eg_md.mirror.session_id, 0, eg_md.common.dst_device, eg_md.common.dst_port });
        } else if (eg_intr_md_for_dprsr.mirror_type == 2) {
            mirror.emit<switch_cpu_mirror_metadata_h>(eg_md.mirror.session_id, { eg_md.mirror.src, eg_md.mirror.type, 0, eg_md.ebridge.evlan, eg_md.fabric.cpu_reason });
        }
    }
}

control IgDeparser_fabric(packet_out pkt, inout switch_header_t hdr, in switch_ingress_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    IgMirror_fabric() mirror;
    apply {
        mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);
        pkt.emit(hdr.switch_bridged_src);
        pkt.emit(hdr.bridged_md_base);
        pkt.emit(hdr.bridged_md_qos);
        pkt.emit(hdr.bridged_md_78);
        pkt.emit(hdr.ext_eth);
        pkt.emit(hdr.ext_tunnel_decap);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.mpls_ig);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.icmp);
        pkt.emit(hdr.igmp);
    }
}

control EgDeparser_fabric(packet_out pkt, inout switch_header_t hdr, in switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    EgMirror_fabric() mirror;
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    apply {
        mirror.apply(hdr, eg_md, eg_intr_md_for_dprsr);
        if (hdr.ipv4.isValid()) {
            hdr.ipv4.hdr_checksum = ipv4_checksum.update({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.total_len, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.frag_offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.src_addr, hdr.ipv4.dst_addr });
        }
        hdr.inner_ipv4.hdr_checksum = inner_ipv4_checksum.update({ hdr.inner_ipv4.version, hdr.inner_ipv4.ihl, hdr.inner_ipv4.diffserv, hdr.inner_ipv4.total_len, hdr.inner_ipv4.identification, hdr.inner_ipv4.flags, hdr.inner_ipv4.frag_offset, hdr.inner_ipv4.ttl, hdr.inner_ipv4.protocol, hdr.inner_ipv4.src_addr, hdr.inner_ipv4.dst_addr });
        pkt.emit(hdr.fabric_base);
        pkt.emit(hdr.fabric_qos);
        pkt.emit(hdr.fabric_unicast_dst);
        pkt.emit(hdr.fabric_unicast_ext_fe_encap);
        pkt.emit(hdr.fabric_var_ext_1_16bit);
        pkt.emit(hdr.fabric_var_ext_2_8bit);
        pkt.emit(hdr.fabric_multicast_dst);
        pkt.emit(hdr.fabric_multicast_ext);
        pkt.emit(hdr.fabric_one_pad);
        pkt.emit(hdr.fabric_post_one_pad);
        pkt.emit(hdr.fabric_cpu_data);
        pkt.emit(hdr.fabric_payload);
        pkt.emit(hdr.ext_tunnel_decap);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.timestamp);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.icmp);
        pkt.emit(hdr.gre);
        pkt.emit(hdr.erspan);
        pkt.emit(hdr.erspan_type2);
        pkt.emit(hdr.erspan_type3);
        pkt.emit(hdr.erspan_platform);
        pkt.emit(hdr.mpls_ig);
    }
}

parser SRHParser(packet_in pkt, inout switch_header_t hdr) {
    state start {
        transition parse_srh;
    }
    state parse_srh {
        transition accept;
    }
}

parser IgParser_downlink(packet_in pkt, out switch_header_t hdr, out switch_ingress_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    value_set<bit<16>>(1) udp_port_vxlan;
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;
    state start {
        pkt.extract(ig_intr_md);
        transition parse_port_metadata;
    }
    state parse_resubmit {
        transition accept;
    }
    state parse_port_metadata {
        switch_port_metadata_downlink_pipe_t port_md = port_metadata_unpack<switch_port_metadata_downlink_pipe_t>(pkt);
        ig_md.common.port_type = port_md.port_type;
        transition parse_fpga_eg_packet;
    }
    state parse_fpga_eg_packet {
        fabric_base_lookahead_h lookahead = pkt.lookahead<fabric_base_lookahead_h>();
        transition select(lookahead.mcast) {
            0: parse_fpga_eg_unicast;
            1: parse_fpga_eg_mcast;
            default: accept;
        }
    }
    state parse_fpga_eg_unicast {
        pkt.extract(hdr.fabric_base);
        ig_md.common.pkt_type = hdr.fabric_base.pkt_type;
        pkt.extract(hdr.fabric_qos);
        pkt.extract(hdr.fabric_unicast_ext_eg_decap);
        ig_md.common.oif = hdr.fabric_unicast_ext_eg_decap.oif;
        ig_md.tunnel.next_hdr_type = hdr.fabric_unicast_ext_eg_decap.next_hdr_type;
        pkt.extract(hdr.fabric_one_pad);
        transition select(hdr.fabric_unicast_ext_eg_decap.extend) {
            1: parse_extension_tunnel_decap;
            default: parse_fabric_uc_end;
        }
    }
    state parse_extension_tunnel_decap {
        pkt.extract(hdr.ext_tunnel_decap);
        transition parse_fabric_uc_end;
    }
    state parse_fabric_uc_end {
        transition select(ig_md.common.pkt_type, ig_md.tunnel.next_hdr_type) {
            (FABRIC_PKT_TYPE_ETH, 0): parse_ethernet;
            (FABRIC_PKT_TYPE_IPV4, 0): parse_ipv4;
            (FABRIC_PKT_TYPE_IPV6, 0): parse_ipv6;
            (FABRIC_PKT_TYPE_MPLS, 0): parse_mpls;
            (default, SWITCH_TUNNEL_NEXT_HDR_TYPE_MPLS): parse_mpls;
            (default, SWITCH_TUNNEL_NEXT_HDR_TYPE_IPV4): parse_ipv4;
            (default, SWITCH_TUNNEL_NEXT_HDR_TYPE_IPV6): parse_ipv6;
            default: accept;
        }
    }
    state parse_fpga_eg_mcast {
        pkt.extract(hdr.fabric_base);
        ig_md.common.pkt_type = hdr.fabric_base.pkt_type;
        pkt.extract(hdr.fabric_qos);
        pkt.extract(hdr.fabric_unicast_ext_eg_decap);
        ig_md.common.oif = hdr.fabric_unicast_ext_eg_decap.oif;
        pkt.extract(hdr.fabric_one_pad);
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
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
        ig_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        ipv4_checksum.add(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            5: parse_ipv4_no_options;
            default: accept;
        }
    }
    state parse_ipv4_no_options {
        ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (1, 0): parse_icmp;
            (2, 0): parse_igmp;
            (6, 0): parse_tcp;
            (17, 0): parse_udp;
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
        pkt.extract(hdr.mpls_ig.next);
        transition select(hdr.mpls_ig.last.bos) {
            0: parse_mpls;
            1: parse_mpls_bos;
            default: accept;
        }
    }
    state parse_mpls_bos {
        transition accept;
    }
    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        ig_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        transition select(hdr.ipv6.next_hdr) {
            58: parse_icmp;
            6: parse_tcp;
            17: parse_udp;
            default: accept;
        }
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        ig_md.lkp.l4_src_port = hdr.udp.src_port;
        ig_md.lkp.l4_dst_port = hdr.udp.dst_port;
        transition select(hdr.udp.dst_port) {
            default: accept;
        }
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        ig_md.lkp.l4_src_port = hdr.tcp.src_port;
        ig_md.lkp.l4_dst_port = hdr.tcp.dst_port;
        ig_md.lkp.tcp_flags = hdr.tcp.flags;
        transition accept;
    }
    state parse_icmp {
        pkt.extract(hdr.icmp);
        ig_md.lkp.l4_src_port = hdr.icmp.typeCode;
        ig_md.lkp.l4_dst_port = 0;
        transition accept;
    }
    state parse_igmp {
        pkt.extract(hdr.igmp);
        transition accept;
    }
}

parser EgParser_downlink(packet_in pkt, out switch_header_t hdr, out switch_egress_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    value_set<bit<16>>(1) udp_port_vxlan;
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;
    @critical state start {
        pkt.extract(eg_intr_md);
        eg_md.common.pkt_length = eg_intr_md.pkt_length;
        eg_md.qos.qdepth = eg_intr_md.deq_qdepth;
        switch_port_mirror_metadata_h mirror_md = pkt.lookahead<switch_port_mirror_metadata_h>();
        transition select(mirror_md.src, mirror_md.type) {
            (SWITCH_PKT_SRC_BRIDGED, BRIDGE_TYPE_FABRIC_DOWNLINK): parse_bridged_pkt_78;
            (default, 1): parse_port_mirrored_metadata;
        }
    }
    state parse_bridged_pkt_78 {
        pkt.extract(hdr.switch_bridged_src);
        pkt.extract(hdr.bridged_md_base);
        pkt.extract(hdr.bridged_md_qos);
        pkt.extract(hdr.bridged_md_78);
        eg_md.common.pkt_type = hdr.bridged_md_base.pkt_type;
        eg_md.common.is_mcast = hdr.bridged_md_base.is_mcast;
        eg_md.qos.tc = hdr.bridged_md_qos.tc;
        eg_md.qos.color = hdr.bridged_md_qos.color;
        eg_md.qos.chgDSCP_disable = hdr.bridged_md_qos.chgDSCP_disable;
        eg_md.qos.BA = hdr.bridged_md_qos.BA;
        transition select(hdr.bridged_md_78.extend) {
            1: parse_bridged_78_ext_0;
            default: parse_bridged_end;
        }
    }
    state parse_bridged_78_ext_0 {
        switch_extension_lookahead_h extension = pkt.lookahead<switch_extension_lookahead_h>();
        transition select(extension.ext_type) {
            BRIDGED_MD_EXT_TYPE_L4_ENCAP: parse_extension_l4_encap;
            BRIDGED_MD_EXT_TYPE_TUNNEL_DECAP: parse_extension_tunnel_decap;
            default: accept;
        }
    }
    state parse_extension_l4_encap {
        pkt.extract(hdr.ext_l4_encap);
        eg_md.tunnel.l4_encap = hdr.ext_l4_encap.l4_encap;
        transition select(hdr.ext_l4_encap.extend) {
            1: parse_extension_tunnel_decap;
            default: parse_bridged_end;
        }
    }
    state parse_extension_tunnel_decap {
        pkt.extract(hdr.ext_tunnel_decap);
        transition select(hdr.ext_tunnel_decap.extend) {
            0: parse_bridged_end;
            default: accept;
        }
    }
    state parse_bridged_end {
        transition select(eg_md.common.pkt_type, eg_md.common.is_mcast) {
            (FABRIC_PKT_TYPE_ETH, 0): parse_bridged_eth;
            (FABRIC_PKT_TYPE_IPV4, 0): parse_ipv4;
            (FABRIC_PKT_TYPE_IPV6, 0): parse_ipv6;
            (FABRIC_PKT_TYPE_MPLS, 0): parse_mpls;
            (default, 1): parse_bridged_eth;
            default: accept;
        }
    }
    state parse_bridged_eth {
        pkt.extract(hdr.ext_eth);
        eg_md.ebridge.evlan = hdr.ext_eth.evlan;
        eg_md.ebridge.l2oif = hdr.ext_eth.l2oif;
        transition parse_ethernet;
    }
    state parse_port_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.ethernet);
        transition accept;
    }
    state parse_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            0x800: parse_ipv4;
            0x86dd: parse_ipv6;
            0x8100: parse_vlan;
            0x8100: parse_vlan;
            default: accept;
        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.ihl, hdr.inner_ipv4.frag_offset) {
            (6, 5, 0): parse_tcp;
            (17, 5, 0): parse_udp;
            (1, 5, 0): parse_icmp;
            default: accept;
        }
    }
    state parse_vlan {
        pkt.extract(hdr.inner_vlan_tag[0]);
        transition select(hdr.inner_vlan_tag.last.ether_type) {
            0x800: parse_ipv4;
            0x8100: parse_vlan;
            0x86dd: parse_ipv6;
            default: accept;
        }
    }
    state parse_mpls {
        pkt.extract(hdr.mpls_vc_eg);
        transition accept;
    }
    state parse_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr) {
            6: parse_tcp;
            17: parse_udp;
            58: parse_icmp;
            default: accept;
        }
    }
    state parse_udp {
        pkt.extract(hdr.inner_udp);
        eg_md.lkp.l4_src_port = hdr.inner_udp.src_port;
        eg_md.lkp.l4_dst_port = hdr.inner_udp.dst_port;
        eg_md.lkp.tcp_flags = 0;
        transition accept;
    }
    state parse_tcp {
        pkt.extract(hdr.inner_tcp);
        eg_md.lkp.l4_src_port = hdr.inner_tcp.src_port;
        eg_md.lkp.l4_dst_port = hdr.inner_tcp.dst_port;
        eg_md.lkp.tcp_flags = hdr.inner_tcp.flags;
        transition accept;
    }
    state parse_icmp {
        pkt.extract(hdr.inner_icmp);
        eg_md.lkp.l4_src_port = hdr.inner_icmp.typeCode;
        eg_md.lkp.l4_dst_port = 0;
        eg_md.lkp.tcp_flags = 0;
        transition accept;
    }
}

control IgMirror_downlink(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    Mirror() mirror;
    apply {
        if (ig_intr_md_for_dprsr.mirror_type == 1) {
            mirror.emit<switch_port_mirror_metadata_h>(ig_md.mirror.session_id, { ig_md.mirror.src, ig_md.mirror.type, 0, ig_md.mirror.session_id, 0, ig_md.common.dst_device, ig_md.common.dst_port });
        }
    }
}

control EgMirror_downlink(inout switch_header_t hdr, in switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    Mirror() mirror;
    apply {
        if (eg_intr_md_for_dprsr.mirror_type == 1) {
            mirror.emit<switch_port_mirror_metadata_h>(eg_md.mirror.session_id, { eg_md.mirror.src, eg_md.mirror.type, 0, eg_md.mirror.session_id, 0, eg_md.common.dst_device, eg_md.common.dst_port });
        } else if (eg_intr_md_for_dprsr.mirror_type == 2) {
            mirror.emit<switch_cpu_mirror_metadata_h>(eg_md.mirror.session_id, { eg_md.mirror.src, eg_md.mirror.type, 0, eg_md.ebridge.evlan, eg_md.fabric.cpu_reason });
        }
    }
}

control IgDeparser_downlink(packet_out pkt, inout switch_header_t hdr, in switch_ingress_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr.switch_bridged_src);
        pkt.emit(hdr.bridged_md_base);
        pkt.emit(hdr.bridged_md_qos);
        pkt.emit(hdr.bridged_md_910);
        pkt.emit(hdr.ext_mirror);
        pkt.emit(hdr.ext_tunnel_decap);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.mpls_ig);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.icmp);
        pkt.emit(hdr.igmp);
    }
}

control EgDeparser_downlink(packet_out pkt, inout switch_header_t hdr, in switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    apply {
        pkt.emit(hdr.fabric_base);
        pkt.emit(hdr.fabric_qos);
        pkt.emit(hdr.fabric_unicast_ext_eg);
        pkt.emit(hdr.fabric_multicast_dst);
        pkt.emit(hdr.fabric_multicast_ext);
        pkt.emit(hdr.fabric_one_pad);
        pkt.emit(hdr.fabric_post_one_pad);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.timestamp);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.srv6_srh);
        pkt.emit(hdr.srv6_list);
        pkt.emit(hdr.gre);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.mpls_eg);
        pkt.emit(hdr.mpls_vc_eg);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_vlan_tag);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
    }
}

control IngressPortMapping_front(inout switch_header_t hdr, in switch_port_t ingress_port, inout switch_ingress_metadata_t ig_md, out switch_port_t local_physics_port, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(switch_uint32_t port_table_size=512, switch_uint32_t lif_table_size=32768, switch_uint32_t cpu_eth_table_size=256) {
    Random<bit<16>>() random;
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) port_stats_ig;
    action terminate_cpu_eth_packet() {
        ig_intr_md_for_tm.bypass_egress = 0;
        hdr.ethernet.ether_type = hdr.fabric_eth_etype.ether_type;
        hdr.fabric_eth_base_from_cpu.setInvalid();
        hdr.fabric_eth_from_cpu_data.setInvalid();
        hdr.fabric_eth_etype.setInvalid();
    }
    action ingress_port_front(switch_logic_port_t src_port, switch_port_t egress_port, bit<1> flowspec_disable_v4, bit<1> flowspec_disable_v6, switch_eport_t eport) {
        ig_md.common.src_port = src_port;
        local_physics_port = egress_port;
        ig_md.flags.flowspec_disable_v4 = flowspec_disable_v4;
        ig_md.flags.flowspec_disable_v6 = flowspec_disable_v6;
        ig_md.common.eport = eport;
        ig_md.ipfix.random_num = random.get();
        port_stats_ig.count();
    }
    action ingress_port_cpu_eth(switch_logic_port_t src_port, switch_port_t egress_port, switch_eport_t eport) {
        ig_md.common.src_port = src_port;
        local_physics_port = egress_port;
        ig_md.common.eport = eport;
        terminate_cpu_eth_packet();
        port_stats_ig.count();
    }
    table ingress_port_mapping {
        key = {
            ingress_port        : exact;
            hdr.br_tag.isValid(): ternary;
            hdr.br_tag.ecid     : ternary;
        }
        actions = {
            ingress_port_front;
            ingress_port_cpu_eth;
        }
        counters = port_stats_ig;
        size = port_table_size;
    }
    action miss() {
        ig_md.common.iif = 0;
    }
    action set_l3iif(switch_lif_t lif, switch_acl_classid_t v4_classid_1, switch_acl_classid_t v4_classid_2, switch_acl_classid_t v4_classid_3, switch_acl_classid_t v4_classid_4, switch_acl_classid_t v6_classid_1, switch_acl_classid_t v6_classid_2, switch_acl_classid_t v6_classid_3, switch_acl_classid_t v6_classid_4) {
        ig_md.common.iif = lif;
        ig_md.policer.iif = lif;
        ig_md.policer.v4_group_classid_1 = v4_classid_1;
        ig_md.policer.v4_group_classid_1 = v4_classid_2;
        ig_md.policer.v4_group_classid_1 = v4_classid_3;
        ig_md.policer.v4_group_classid_1 = v4_classid_4;
        ig_md.policer.v6_group_classid_1 = v6_classid_1;
        ig_md.policer.v6_group_classid_1 = v6_classid_2;
        ig_md.policer.v6_group_classid_1 = v6_classid_3;
        ig_md.policer.v6_group_classid_1 = v6_classid_4;
    }
    action set_l2iif(switch_lif_t lif, switch_acl_classid_t v4_classid_1, switch_acl_classid_t v4_classid_2, switch_acl_classid_t v4_classid_3, switch_acl_classid_t v4_classid_4, switch_acl_classid_t v6_classid_1, switch_acl_classid_t v6_classid_2, switch_acl_classid_t v6_classid_3, switch_acl_classid_t v6_classid_4) {
        ig_md.common.iif = lif;
        ig_md.policer.iif = lif;
        ig_md.policer.v4_group_classid_1 = v4_classid_1;
        ig_md.policer.v4_group_classid_1 = v4_classid_2;
        ig_md.policer.v4_group_classid_1 = v4_classid_3;
        ig_md.policer.v4_group_classid_1 = v4_classid_4;
        ig_md.policer.v6_group_classid_1 = v6_classid_1;
        ig_md.policer.v6_group_classid_1 = v6_classid_2;
        ig_md.policer.v6_group_classid_1 = v6_classid_3;
        ig_md.policer.v6_group_classid_1 = v6_classid_4;
    }
    table port_vlan_to_lif_mapping {
        key = {
            ig_md.common.eport       : exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[0].vid      : exact;
        }
        actions = {
            NoAction;
            set_l3iif;
            set_l2iif;
        }
        const default_action = NoAction;
        size = lif_table_size;
    }
    table back_port_vlan_to_lif_mapping {
        key = {
            ig_md.common.eport       : ternary;
            hdr.vlan_tag[0].isValid(): ternary;
            hdr.vlan_tag[0].vid      : ternary;
        }
        actions = {
            miss;
            set_l3iif;
            set_l2iif;
        }
        const default_action = miss;
        size = 512;
    }
    apply {
        ingress_port_mapping.apply();
        if (!port_vlan_to_lif_mapping.apply().hit) {
            back_port_vlan_to_lif_mapping.apply();
        }
    }
}

control EgressPortMapping_front(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, in switch_port_t port)(switch_uint32_t table_size=512) {
    Random<bit<16>>() random;
    action egress_port_front() {
        eg_md.common.port_type = PORT_TYPE_FRONT;
        eg_md.ipfix.random_num = random.get();
    }
    action egress_port_cpu_eth() {
        eg_md.common.port_type = PORT_TYPE_CPU_ETH;
    }
    table egress_port_mapping {
        key = {
            port: exact;
        }
        actions = {
            egress_port_front;
            egress_port_cpu_eth;
        }
        size = table_size;
    }
    apply {
        egress_port_mapping.apply();
    }
}

control EgressPortMapping_uplink(inout switch_egress_metadata_t eg_md)(switch_uint32_t table_size=512) {
    action set_eport(switch_eport_t eport) {
        eg_md.common.eport = eport;
    }
    table srt_port_to_eport_mapping {
        key = {
            eg_md.common.src_port: exact;
        }
        actions = {
            set_eport;
        }
        size = table_size;
    }
    apply {
        srt_port_to_eport_mapping.apply();
    }
}

control IngressPortMapping_fabric(inout switch_header_t hdr, in switch_port_t port, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm, inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size=512) {
    action terminate_cpu_packet() {
        ig_intr_md_for_tm.bypass_egress = hdr.fabric_cpu_data.tx_bypass;
        ig_md.common.bypass = hdr.fabric_cpu_data.reason_code;
        ig_md.ebridge.evlan = hdr.fabric_cpu_data.evlan;
        ig_md.qos.color = hdr.fabric_qos.color;
        ig_md.qos.tc = hdr.fabric_qos.tc;
    }
    action set_cpu_pcie_properties(switch_yid_t exclusion_id) {
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
        terminate_cpu_packet();
    }
    table ingress_port_properties {
        key = {
            port                         : exact;
            hdr.fabric_cpu_data.isValid(): exact;
            hdr.fabric_cpu_data.iif      : exact;
        }
        actions = {
            set_cpu_pcie_properties;
        }
        size = table_size;
    }
    action pcie_flood(switch_mgid_t mgid) {
        ig_md.multicast.id = mgid;
        hdr.fabric_base.pkt_type = FABRIC_PKT_TYPE_ETH;
        ig_intr_md_for_tm.ucast_egress_port = SWITCH_PORT_INVALID;
    }
    table cpu_bd_mapping {
        key = {
            ig_md.common.pkt_type    : exact;
            hdr.fabric_cpu_data.evlan: exact;
        }
        actions = {
            pcie_flood;
        }
        size = 4096;
    }
    apply {
        switch (ingress_port_properties.apply().action_run) {
            set_cpu_pcie_properties: {
                cpu_bd_mapping.apply();
            }
            default: {
            }
        }

    }
}

control EgressPortMapping_fabric(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, in switch_port_t port)(switch_uint32_t table_size=512) {
    action egress_port_fabric() {
        eg_md.common.port_type = PORT_TYPE_FABRIC;
    }
    action egress_port_cpu_pcie() {
        eg_md.common.port_type = PORT_TYPE_CPU_PCIE;
    }
    table egress_port_mapping {
        key = {
            port: exact;
        }
        actions = {
            egress_port_fabric;
            egress_port_cpu_pcie;
        }
        size = table_size;
    }
    apply {
        egress_port_mapping.apply();
    }
}

control EgressPortMapping_downlink(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, in switch_port_t port)(switch_uint32_t table_size=512) {
    apply {
    }
}

control McExportMapping(in switch_port_t ingress_port, out switch_port_t local_physics_port)(switch_uint32_t table_size=128) {
    action set_front_egress_port(switch_port_t egress_port) {
        local_physics_port = egress_port;
    }
    table downfpga_port_to_front_port_mapping {
        key = {
            ingress_port: exact;
        }
        actions = {
            set_front_egress_port;
        }
        size = table_size;
    }
    apply {
        downfpga_port_to_front_port_mapping.apply();
    }
}

control LAGFilter(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    action Noaction() {
    }
    action drop() {
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }
    table non_designated_filter {
        key = {
            eg_md.multicast.id   : exact;
            eg_intr_md.egress_rid: exact;
        }
        actions = {
            Noaction;
            drop;
        }
        const default_action = Noaction();
        size = 512;
    }
    apply {
        non_designated_filter.apply();
    }
}

control uplink_port_qos_properties(inout switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md) {
    action set_port_properties(switch_qos_trust_mode_t trust_mode, switch_qos_group_t qos_group, switch_pkt_color_t color, switch_tc_t tc) {
        eg_md.qos.color = color;
        eg_md.qos.tc = tc;
    }
    table port_qos_properties {
        key = {
            eg_intr_md.egress_port: exact;
        }
        actions = {
            NoAction;
            set_port_properties;
        }
        size = 512;
    }
    apply {
        port_qos_properties.apply();
    }
}

control StormControl(inout switch_egress_metadata_t eg_md, inout switch_header_t hdr, in switch_pkt_type_t pkt_type)(switch_uint32_t table_size=512) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS) storm_control_stats;
    Meter<bit<16>>(table_size, MeterType_t.BYTES) meter;
    action count() {
        storm_control_stats.count();
    }
    action drop_and_count() {
        storm_control_stats.count();
    }
    table stats {
        key = {
            eg_md.qos.storm_control_color: exact;
            pkt_type                     : ternary;
            eg_md.common.src_port        : exact;
            eg_md.flags.dmac_miss        : ternary;
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
        eg_md.qos.storm_control_color = (bit<2>)meter.execute(index);
    }
    table storm_control {
        key = {
            eg_md.common.src_port: exact;
            pkt_type             : ternary;
            eg_md.flags.dmac_miss: ternary;
        }
        actions = {
            @defaultonly NoAction;
            set_meter;
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        storm_control.apply();
        stats.apply();
    }
}

control DevPortMapping_downlink(inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(switch_uint32_t table_size=512) {
    action set_dev_port(switch_port_t dev_port, bit<6> dst_ecid) {
        ig_intr_md_for_tm.ucast_egress_port = dev_port;
        ig_md.common.dst_ecid = dst_ecid;
    }
    table dev_port_mapping {
        key = {
            ig_md.common.dst_port: exact;
        }
        actions = {
            NoAction;
            set_dev_port;
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        dev_port_mapping.apply();
    }
}

control BrXlate(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, in switch_port_t port)(switch_uint32_t port_table_size=512) {
    action set_br_untagged() {
    }
    action set_br_tagged(bit<12> ecid) {
        hdr.br_tag.setValid();
        hdr.br_tag.ether_type = hdr.ethernet.ether_type;
        hdr.br_tag.epcp = 0;
        hdr.br_tag.edei = 0;
        hdr.br_tag.ingress_ecid = 0;
        hdr.br_tag.reserved = 0;
        hdr.br_tag.grp = 0;
        hdr.br_tag.ecid = ecid;
        hdr.br_tag.ingress_ecid_ext = 0;
        hdr.br_tag.ecid_ext = 0;
        hdr.ethernet.ether_type = 0x893f;
    }
    table port_to_br_mapping {
        key = {
            port                 : exact;
            eg_md.common.dst_ecid: exact;
        }
        actions = {
            set_br_untagged;
            set_br_tagged;
        }
        size = port_table_size;
    }
    apply {
        port_to_br_mapping.apply();
    }
}

control MC_LAG(inout switch_egress_metadata_t eg_md, in bit<16> hash, out switch_logic_port_t target_port)(switch_uint32_t table_size=512) {
    const bit<32> mc_lag_max_entrys = 9216;
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(mc_lag_max_entrys, selector_hash, SelectorMode_t.FAIR) mc_lag_selector;
    action load_balancing(switch_logic_port_t port) {
        target_port = port;
    }
    action lag_miss() {
    }
    @selector_enable_scramble(0) table mc_lag {
        key = {
            eg_md.common.egress_eport: exact @name("eport") ;
            hash                     : selector;
        }
        actions = {
            load_balancing;
            lag_miss;
        }
        const default_action = lag_miss();
        size = table_size;
        implementation = mc_lag_selector;
    }
    apply {
        mc_lag.apply();
    }
}

control IngressHASH_front(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md, inout switch_hash_t hash, inout switch_hash_mode_t hash_mode, inout switch_ingress_tunnel_metadata_t tunnel) {
    Hash<bit<16>>(HashAlgorithm_t.CRC16) ip_hash;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) mpls_hash;
    action compute_ip_hash() {
        hash = ip_hash.get({ ig_md.lkp.ip_src_addr, ig_md.lkp.ip_dst_addr, ig_md.lkp.ip_proto, ig_md.lkp.l4_src_port, ig_md.lkp.l4_dst_port });
    }
    action compute_mpls_hash() {
        hash = mpls_hash.get({ tunnel.first_label, tunnel.second_label, tunnel.third_label });
    }
    table hash_value_compute {
        key = {
            ig_md.lkp.ip_type       : exact;
            hdr.mpls_ig[0].isValid(): exact;
        }
        actions = {
            compute_ip_hash;
            compute_mpls_hash;
        }
        const entries = {
                        (SWITCH_IP_TYPE_NONE, true) : compute_mpls_hash();
                        (SWITCH_IP_TYPE_IPV4, false) : compute_ip_hash();
                        (SWITCH_IP_TYPE_IPV6, false) : compute_ip_hash();
        }

        size = 64;
    }
    apply {
        hash_value_compute.apply();
    }
}

control EgressHASH_front(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, inout switch_hash_t hash, inout switch_hash_mode_t hash_mode, inout switch_egress_tunnel_metadata_t tunnel) {
    Hash<bit<16>>(HashAlgorithm_t.CRC16) ip_hash;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) mpls_hash;
    action miss() {
    }
    action compute_ip_hash() {
        hash = ip_hash.get({ eg_md.lkp.ip_src_addr, eg_md.lkp.ip_dst_addr, eg_md.lkp.ip_proto, eg_md.lkp.l4_src_port, eg_md.lkp.l4_dst_port });
    }
    action compute_mpls_hash() {
        hash = mpls_hash.get({ tunnel.first_label, tunnel.second_label, tunnel.third_label });
    }
    table hash_value_compute {
        key = {
            eg_md.lkp.ip_type       : exact;
            hdr.mpls_ig[0].isValid(): exact;
        }
        actions = {
            compute_ip_hash;
            compute_mpls_hash;
        }
        const entries = {
                        (SWITCH_IP_TYPE_NONE, true) : compute_mpls_hash();
                        (SWITCH_IP_TYPE_IPV4, false) : compute_ip_hash();
                        (SWITCH_IP_TYPE_IPV6, false) : compute_ip_hash();
        }

        size = 64;
    }
    apply {
        hash_value_compute.apply();
    }
}

control IngressHASH_uplink(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md, inout switch_ingress_tunnel_metadata_t tunnel, inout switch_hash_t hash, inout switch_hash_mode_t hash_mode) {
    Hash<bit<16>>(HashAlgorithm_t.CRC16) mpls_hash;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) eth_hash;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) ipv4_hash;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) ipv6_hash;
    Random<bit<16>>() random;
    action compute_mpls_hash() {
        hash = mpls_hash.get({ tunnel.first_label, tunnel.second_label, tunnel.third_label, ig_md.common.udf });
    }
    action compute_eth_hash() {
        hash = eth_hash.get({ hdr.ethernet.ether_type, hdr.ethernet.src_addr, hdr.ethernet.dst_addr, ig_md.ebridge.evlan, ig_md.common.udf });
    }
    action compute_ipv4_hash() {
        hash = ipv4_hash.get({ hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol, ig_md.lkp.l4_src_port, ig_md.lkp.l4_dst_port, ig_md.common.udf });
    }
    action compute_ipv6_hash() {
        hash = ipv6_hash.get({ hdr.ipv6.src_addr, hdr.ipv6.dst_addr, hdr.ipv6.next_hdr, hdr.ipv6.flow_label, ig_md.lkp.l4_src_port, ig_md.lkp.l4_dst_port, ig_md.common.udf });
    }
    action miss() {
    }
    action set_hash_mode(switch_hash_mode_t mode, bit<16> udf) {
        hash_mode = mode;
        ig_md.common.udf = udf;
    }
    table hash_mode_config {
        key = {
            ig_md.common.pkt_type: exact @name("pkt_type") ;
        }
        actions = {
            set_hash_mode;
        }
        size = 128;
    }
    table no_ip_hash_value_compute {
        key = {
            hash_mode: exact;
        }
        actions = {
            compute_mpls_hash;
            compute_eth_hash;
            miss;
        }
        const default_action = miss;
        size = 128;
    }
    table ip_hash_value_compute {
        key = {
            hash_mode: exact;
        }
        actions = {
            compute_ipv4_hash;
            compute_ipv6_hash;
            miss;
        }
        const default_action = miss;
        size = 128;
    }
    apply {
        hash_mode_config.apply();
        switch (no_ip_hash_value_compute.apply().action_run) {
            miss: {
                ip_hash_value_compute.apply();
            }
        }

    }
}

control EgressHASH_uplink(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, inout switch_egress_tunnel_metadata_t tunnel, inout switch_hash_t hash, inout switch_hash_mode_t hash_mode) {
    Hash<bit<16>>(HashAlgorithm_t.CRC16) mpls_hash;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) eth_hash;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) ipv4_hash;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) ipv6_hash;
    @symmetric("hdr.ipv4.src_addr", "hdr.ipv4.dst_addr") @symmetric("eg_md.lkp.l4_src_port", "eg_md.lkp.l4_dst_port") Hash<bit<16>>(HashAlgorithm_t.CRC16) sym_ipv4_hash;
    @symmetric("hdr.ipv6.src_addr", "hdr.ipv6.dst_addr") @symmetric("eg_md.lkp.l4_src_port", "eg_md.lkp.l4_dst_port") Hash<bit<16>>(HashAlgorithm_t.CRC16) sym_ipv6_hash;
    action compute_mpls_hash() {
        hash = mpls_hash.get({ tunnel.first_label, tunnel.second_label, tunnel.third_label, eg_md.common.udf });
    }
    action compute_eth_hash() {
        hash = eth_hash.get({ hdr.ethernet.ether_type, hdr.ethernet.src_addr, hdr.ethernet.dst_addr, eg_md.ebridge.evlan, eg_md.common.udf });
    }
    action compute_ipv4_hash() {
        hash = ipv4_hash.get({ hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol, eg_md.lkp.l4_src_port, eg_md.lkp.l4_dst_port, eg_md.common.udf });
    }
    action compute_ipv6_hash() {
        hash = ipv6_hash.get({ hdr.ipv6.src_addr, hdr.ipv6.dst_addr, hdr.ipv6.next_hdr, hdr.ipv6.flow_label, eg_md.lkp.l4_src_port, eg_md.lkp.l4_dst_port, eg_md.common.udf });
    }
    action compute_sym_ipv4_hash() {
        hash = sym_ipv4_hash.get({ hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol, eg_md.lkp.l4_src_port, eg_md.lkp.l4_dst_port, eg_md.common.udf });
    }
    action compute_sym_ipv6_hash() {
        hash = sym_ipv6_hash.get({ hdr.ipv6.src_addr, hdr.ipv6.dst_addr, hdr.ipv6.next_hdr, hdr.ipv6.flow_label, eg_md.lkp.l4_src_port, eg_md.lkp.l4_dst_port, eg_md.common.udf });
    }
    action set_hash_mode(switch_hash_mode_t mode, bit<16> udf) {
        hash_mode = mode;
        eg_md.common.udf = udf;
    }
    action miss() {
    }
    table hash_mode_config {
        key = {
            eg_md.common.pkt_type: exact @name("pkt_type") ;
        }
        actions = {
            set_hash_mode;
        }
        size = 128;
    }
    table no_ip_hash_value_compute {
        key = {
            hash_mode: exact;
        }
        actions = {
            compute_mpls_hash;
            compute_eth_hash;
            miss;
        }
        const default_action = miss;
        size = 128;
    }
    table ip_hash_value_compute {
        key = {
            hash_mode: exact;
        }
        actions = {
            compute_ipv4_hash;
            compute_ipv6_hash;
            miss;
        }
        const default_action = miss;
        size = 128;
    }
    table sym_hash_value_compute {
        key = {
            hash_mode: exact;
        }
        actions = {
            compute_sym_ipv4_hash;
            compute_sym_ipv6_hash;
            miss;
        }
        const default_action = miss;
        size = 128;
    }
    apply {
        hash_mode_config.apply();
        switch (no_ip_hash_value_compute.apply().action_run) {
            miss: {
                switch (ip_hash_value_compute.apply().action_run) {
                    miss: {
                        sym_hash_value_compute.apply();
                    }
                }

            }
        }

    }
}

control Pkt_Type(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md) {
    action set_type(bit<2> type) {
        ig_md.qos.qos_pkt_type = type;
    }
    table set_qos_pkt_type {
        key = {
            hdr.ethernet.ether_type: exact;
        }
        actions = {
            set_type;
        }
        size = 4;
        const entries = {
                        0x8100 : set_type(0);
                        0x800 : set_type(1);
                        0x86dd : set_type(1);
                        0x8847 : set_type(2);
        }

    }
    apply {
        set_qos_pkt_type.apply();
    }
}

control In_Qos_properties(inout switch_ingress_metadata_t ig_md)(switch_uint32_t eport_table_size=256, switch_uint32_t lif_table_size=16384) {
    action set_port_qos_properties(switch_pkt_color_t color, switch_tc_t tc, switch_qos_trust_mode_t trust_mode, bit<5> ds, bit<8> index) {
        ig_md.qos.color = color;
        ig_md.qos.tc = tc;
        ig_md.qos.port_trust_mode = trust_mode;
        ig_md.qos.ds_select = ds;
        ig_md.qos.port_meter_index = index;
    }
    table eport_properties_mapping {
        key = {
            ig_md.common.src_port: exact;
        }
        actions = {
            NoAction;
            set_port_qos_properties;
        }
        const default_action = NoAction;
        size = eport_table_size;
    }
    action set_lif_qos_properties(switch_qos_trust_mode_t trust_mode, bit<5> ds) {
        ig_md.qos.lif_trust_mode = trust_mode;
        ig_md.qos.ds_select = ds;
    }
    table lif_properties_mapping {
        key = {
            ig_md.policer.iif: exact;
        }
        actions = {
            NoAction;
            set_lif_qos_properties;
        }
        const default_action = NoAction;
        size = lif_table_size;
    }
    apply {
        eport_properties_mapping.apply();
        lif_properties_mapping.apply();
    }
}

control Decide_trust(inout switch_ingress_metadata_t ig_md) {
    action set_trust(bit<3> trust_mode) {
        ig_md.qos.final_trust_mode = trust_mode;
    }
    table set_qos_trust_mode {
        key = {
            ig_md.qos.qos_pkt_type   : ternary;
            ig_md.qos.lif_trust_mode : ternary;
            ig_md.qos.port_trust_mode: ternary;
        }
        actions = {
            set_trust;
        }
        const default_action = set_trust(SWITCH_QOS_UNTRUSTED);
        size = 16;
        const entries = {
                        (2, SWITCH_QOS_TRUST_EXP, default) : set_trust(SWITCH_QOS_TRUST_EXP);
                        (1, SWITCH_QOS_TRUST_DSCP, default) : set_trust(SWITCH_QOS_TRUST_DSCP);
                        (1, SWITCH_QOS_TRUST_PRE, default) : set_trust(SWITCH_QOS_TRUST_PRE);
                        (0, SWITCH_QOS_TRUST_PCP, default) : set_trust(SWITCH_QOS_TRUST_PCP);
                        (2, default, SWITCH_QOS_TRUST_EXP) : set_trust(SWITCH_QOS_TRUST_EXP);
                        (1, default, SWITCH_QOS_TRUST_DSCP) : set_trust(SWITCH_QOS_TRUST_DSCP);
                        (1, default, SWITCH_QOS_TRUST_PRE) : set_trust(SWITCH_QOS_TRUST_PRE);
                        (0, default, SWITCH_QOS_TRUST_PCP) : set_trust(SWITCH_QOS_TRUST_PCP);
        }

    }
    apply {
        set_qos_trust_mode.apply();
    }
}

control IngressQoS(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t dscp_map_size=2048, switch_uint32_t pcp_map_size=256, switch_uint32_t exp_map_size=256, switch_uint32_t pre_map_size=256) {
    action set_tc(switch_tc_t tc) {
        ig_md.qos.tc = tc;
        ig_md.qos.BA = 1;
    }
    action set_pkt_color(switch_pkt_color_t color) {
        ig_md.qos.color = color;
        ig_md.qos.BA = 1;
    }
    action set_tc_and_color(switch_tc_t tc, switch_pkt_color_t color) {
        set_tc(tc);
        set_pkt_color(color);
    }
    action dscp_set_tc(switch_tc_t tc) {
        ig_md.qos.tc = tc;
        ig_md.qos.BA = 1;
        ig_md.qos.chgDSCP_disable = 1;
    }
    action dscp_set_pkt_color(switch_pkt_color_t color) {
        ig_md.qos.color = color;
        ig_md.qos.BA = 1;
        ig_md.qos.chgDSCP_disable = 1;
    }
    action dscp_set_tc_and_color(switch_tc_t tc, switch_pkt_color_t color) {
        set_tc(tc);
        set_pkt_color(color);
        ig_md.qos.chgDSCP_disable = 1;
    }
    table dscp_tc_map {
        key = {
            ig_md.lkp.ip_tos[7:2]: exact;
            ig_md.qos.ds_select  : exact;
        }
        actions = {
            NoAction;
            dscp_set_tc;
            dscp_set_pkt_color;
            dscp_set_tc_and_color;
        }
        size = dscp_map_size;
    }
    table ippre_tc_map {
        key = {
            ig_md.lkp.ip_tos[7:5]: exact;
            ig_md.qos.ds_select  : exact;
        }
        actions = {
            NoAction;
            set_tc;
            set_pkt_color;
            set_tc_and_color;
        }
        size = pre_map_size;
    }
    table pcp_tc_map {
        key = {
            hdr.vlan_tag[0].pcp: exact;
            ig_md.qos.ds_select: exact;
        }
        actions = {
            NoAction;
            set_tc;
            set_pkt_color;
            set_tc_and_color;
        }
        size = pcp_map_size;
    }
    table exp_tc_map {
        key = {
            hdr.mpls_ig[0].exp : exact;
            ig_md.qos.ds_select: exact;
        }
        actions = {
            NoAction;
            set_tc;
            set_pkt_color;
            set_tc_and_color;
        }
        size = exp_map_size;
    }
    apply {
        if (ig_md.qos.final_trust_mode == SWITCH_QOS_TRUST_EXP) {
            exp_tc_map.apply();
        } else if (ig_md.qos.final_trust_mode == SWITCH_QOS_TRUST_DSCP) {
            dscp_tc_map.apply();
        } else if (ig_md.qos.final_trust_mode == SWITCH_QOS_TRUST_PRE) {
            ippre_tc_map.apply();
        } else if (ig_md.qos.final_trust_mode == SWITCH_QOS_TRUST_PCP) {
            pcp_tc_map.apply();
        }
    }
}

control Traffic_front(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(switch_uint32_t queue_table_size=32) {
    action set_icos(switch_cos_t icos) {
        ig_intr_md_for_tm.ingress_cos = icos;
    }
    action set_queue(switch_qid_t qid) {
        ig_intr_md_for_tm.qid = qid;
    }
    action set_icos_and_queue(switch_cos_t icos, switch_qid_t qid) {
        set_icos(icos);
        set_queue(qid);
    }
    table traffic_class {
        key = {
            ig_md.qos.tc: exact;
        }
        actions = {
            set_icos;
            set_queue;
            set_icos_and_queue;
        }
        size = queue_table_size;
    }
    apply {
        traffic_class.apply();
    }
}

control Traffic_uplink(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(switch_uint32_t queue_table_size=32) {
    action set_icos(switch_cos_t icos) {
        ig_intr_md_for_tm.ingress_cos = icos;
    }
    action set_queue(switch_qid_t qid) {
        ig_intr_md_for_tm.qid = qid;
    }
    action set_icos_and_queue(switch_cos_t icos, switch_qid_t qid) {
        set_icos(icos);
        set_queue(qid);
    }
    table traffic_class {
        key = {
            ig_md.qos.tc: exact;
        }
        actions = {
            set_icos;
            set_queue;
            set_icos_and_queue;
        }
        size = queue_table_size;
    }
    apply {
        traffic_class.apply();
    }
}

control Traffic_downlink(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(switch_uint32_t queue_table_size=32) {
    action set_icos(switch_cos_t icos) {
        ig_intr_md_for_tm.ingress_cos = icos;
    }
    action set_queue(switch_qid_t qid) {
        ig_intr_md_for_tm.qid = qid;
    }
    action set_icos_and_queue(switch_cos_t icos, switch_qid_t qid) {
        set_icos(icos);
        set_queue(qid);
    }
    table traffic_class {
        key = {
            ig_md.qos.tc: exact;
        }
        actions = {
            set_icos;
            set_queue;
            set_icos_and_queue;
        }
        size = queue_table_size;
    }
    apply {
        traffic_class.apply();
    }
}

control Traffic_fabric(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(switch_uint32_t queue_table_size=32) {
    action set_icos(switch_cos_t icos) {
        ig_intr_md_for_tm.ingress_cos = icos;
    }
    action set_queue(switch_qid_t qid) {
        ig_intr_md_for_tm.qid = qid;
    }
    action set_icos_and_queue(switch_cos_t icos, switch_qid_t qid) {
        set_icos(icos);
        set_queue(qid);
    }
    table traffic_class {
        key = {
            ig_md.qos.tc: exact;
        }
        actions = {
            set_icos;
            set_queue;
            set_icos_and_queue;
        }
        size = queue_table_size;
    }
    apply {
        traffic_class.apply();
    }
}

control Out_Qos_properties(inout switch_egress_metadata_t eg_md)(switch_uint32_t table_size=256, switch_uint32_t lif_table_size=16384) {
    action set_port_properties(bit<5> ds, bit<8> index, bit<1> PHB) {
        eg_md.qos.ds_select = ds;
        eg_md.qos.port_meter_index = index;
        eg_md.qos.PHB = PHB;
    }
    table egress_port_mapping {
        key = {
            eg_md.common.dst_port: exact;
        }
        actions = {
            set_port_properties;
        }
        size = table_size;
    }
    action set_oif_properties(bit<5> ds, bit<12> qid, bit<1> PHB, bool set_phb) {
        eg_md.qos.ds_select = ds;
        eg_md.qos.to_fpga_qid = qid;
        eg_md.flags.is_intf = 1;
        eg_md.qos.PHB = (set_phb ? PHB : eg_md.qos.PHB);
    }
    table oif_ds_mapping {
        key = {
            eg_md.common.oif: exact;
        }
        actions = {
            set_oif_properties;
        }
        size = lif_table_size;
    }
    apply {
        egress_port_mapping.apply();
        oif_ds_mapping.apply();
    }
}

control EgressQoS(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t table_size=1024) {
    action set_pcp(bit<3> pcp) {
        eg_md.qos.pcp = pcp;
    }
    table pcp_remap {
        key = {
            eg_md.qos.tc       : exact;
            eg_md.qos.color    : exact;
            eg_md.qos.ds_select: exact;
        }
        actions = {
            NoAction;
            set_pcp;
        }
        const default_action = NoAction;
        size = table_size;
    }
    action set_dscp(bit<6> dscp) {
        eg_md.qos.dscp = dscp;
    }
    table dscp_remap {
        key = {
            eg_md.qos.tc       : exact;
            eg_md.qos.color    : exact;
            eg_md.qos.ds_select: exact;
        }
        actions = {
            NoAction;
            set_dscp;
        }
        const default_action = NoAction;
        size = table_size;
    }
    action set_ippre(bit<3> ippre) {
        eg_md.qos.ippre = ippre;
    }
    table ippre_remap {
        key = {
            eg_md.qos.tc       : exact;
            eg_md.qos.color    : exact;
            eg_md.qos.ds_select: exact;
        }
        actions = {
            NoAction;
            set_ippre;
        }
        const default_action = NoAction;
        size = table_size;
    }
    action set_exp(bit<3> exp) {
        eg_md.tunnel.exp = exp;
    }
    table exp_remap {
        key = {
            eg_md.qos.tc       : exact;
            eg_md.qos.color    : exact;
            eg_md.qos.ds_select: exact;
        }
        actions = {
            NoAction;
            set_exp;
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        if (eg_md.qos.BA == 1 && eg_md.qos.PHB == 1) {
            exp_remap.apply();
            pcp_remap.apply();
            ippre_remap.apply();
            dscp_remap.apply();
        }
    }
}

control Dscp_decide(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md) {
    action acl_dscp_set() {
        eg_md.qos.dscp = eg_md.qos.acl_dscp;
    }
    action qppb_dscp_set() {
        eg_md.qos.dscp = eg_md.qos.qppb_dscp;
    }
    table deside_dscp {
        key = {
            eg_md.qos.acl_set_dscp : exact;
            eg_md.qos.qppb_set_dscp: exact;
        }
        actions = {
            acl_dscp_set;
            qppb_dscp_set;
        }
    }
    apply {
        deside_dscp.apply();
    }
}

control Modify_Hdr_Cos(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t table_size=8) {
    action qppb_set_v4_dscp() {
        hdr.ipv4.diffserv[7:2] = eg_md.qos.qppb_dscp;
    }
    action qppb_set_v6_dscp() {
        hdr.ipv6.traffic_class[7:2] = eg_md.qos.qppb_dscp;
    }
    action qppb_set_inner_v4_dscp() {
        hdr.inner_ipv4.diffserv[7:2] = eg_md.qos.qppb_dscp;
    }
    action qppb_set_inner_v6_dscp() {
        hdr.inner_ipv6.traffic_class[7:2] = eg_md.qos.qppb_dscp;
    }
    action acl_set_v4_dscp() {
        hdr.ipv4.diffserv[7:2] = eg_md.qos.acl_dscp;
    }
    action acl_set_v6_dscp() {
        hdr.ipv6.traffic_class[7:2] = eg_md.qos.acl_dscp;
    }
    action acl_set_inner_v4_dscp() {
        hdr.inner_ipv4.diffserv[7:2] = eg_md.qos.acl_dscp;
    }
    action acl_set_inner_v6_dscp() {
        hdr.inner_ipv6.traffic_class[7:2] = eg_md.qos.acl_dscp;
    }
    table qppb_acl_set_dscp {
        key = {
            eg_md.lkp.ip_type      : exact;
            eg_md.lkp.ip_inner     : exact;
            eg_md.qos.qppb_set_dscp: exact;
            eg_md.qos.acl_set_dscp : exact;
        }
        actions = {
            qppb_set_v4_dscp;
            qppb_set_v6_dscp;
            qppb_set_inner_v4_dscp;
            qppb_set_inner_v6_dscp;
            acl_set_v4_dscp;
            acl_set_v6_dscp;
            acl_set_inner_v4_dscp;
            acl_set_inner_v6_dscp;
        }
        size = 16;
        const entries = {
                        (SWITCH_IP_TYPE_IPV4, 0, 1, 0) : qppb_set_v4_dscp();
                        (SWITCH_IP_TYPE_IPV4, 0, 1, 1) : qppb_set_v4_dscp();
                        (SWITCH_IP_TYPE_IPV4, 0, 0, 1) : acl_set_v4_dscp();
                        (SWITCH_IP_TYPE_IPV4, 1, 1, 0) : qppb_set_inner_v4_dscp();
                        (SWITCH_IP_TYPE_IPV4, 1, 1, 1) : qppb_set_inner_v4_dscp();
                        (SWITCH_IP_TYPE_IPV4, 1, 0, 1) : acl_set_inner_v4_dscp();
                        (SWITCH_IP_TYPE_IPV6, 0, 1, 0) : qppb_set_v6_dscp();
                        (SWITCH_IP_TYPE_IPV6, 0, 1, 1) : qppb_set_v6_dscp();
                        (SWITCH_IP_TYPE_IPV6, 0, 0, 1) : acl_set_v6_dscp();
                        (SWITCH_IP_TYPE_IPV6, 1, 1, 0) : qppb_set_inner_v6_dscp();
                        (SWITCH_IP_TYPE_IPV6, 1, 1, 1) : qppb_set_inner_v6_dscp();
                        (SWITCH_IP_TYPE_IPV6, 1, 0, 1) : acl_set_inner_v6_dscp();
        }

    }
    action qos_set_inner_v4_dscp() {
        hdr.inner_ipv4.diffserv[7:2] = eg_md.qos.dscp;
    }
    action qos_set_inner_v6_dscp() {
        hdr.inner_ipv6.traffic_class[7:2] = eg_md.qos.dscp;
    }
    action set_mpls_exp() {
        hdr.mpls_vc_eg.exp = eg_md.tunnel.exp;
    }
    table set_cos {
        key = {
            eg_md.common.pkt_type    : ternary;
            eg_md.qos.chgDSCP_disable: ternary;
        }
        actions = {
            NoAction;
            qos_set_inner_v4_dscp;
            qos_set_inner_v6_dscp;
            set_mpls_exp;
        }
        const default_action = NoAction;
        const entries = {
                        (FABRIC_PKT_TYPE_MPLS, default) : set_mpls_exp();
                        (FABRIC_PKT_TYPE_IPV4, 0) : qos_set_inner_v4_dscp();
                        (FABRIC_PKT_TYPE_IPV6, 0) : qos_set_inner_v6_dscp();
        }

        size = 16;
    }
    action set_vlan_pcp() {
        hdr.vlan_tag[0].pcp = eg_md.qos.pcp;
    }
    table set_tag_pcp {
        key = {
            hdr.inner_vlan_tag[0].isValid(): exact;
        }
        actions = {
            NoAction;
            set_vlan_pcp;
        }
        const default_action = NoAction;
        const entries = {
                        true : set_vlan_pcp();
        }

        size = 16;
    }
    apply {
        if (eg_md.qos.qppb_set_dscp == 1 || eg_md.qos.acl_set_dscp == 1) {
            qppb_acl_set_dscp.apply();
        } else if (eg_md.qos.BA == 1 && eg_md.qos.PHB == 1 && eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_NONE) {
            set_cos.apply();
        }
        if (eg_md.qos.BA == 1 && eg_md.qos.PHB == 1 && eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_NONE) {
            set_tag_pcp.apply();
        }
    }
}

control Tc_Color_decide(inout switch_ingress_metadata_t ig_md) {
    action set_tc() {
        ig_md.qos.tc = ig_md.qos.tc_tmp;
    }
    action set_color() {
        ig_md.qos.color = ig_md.qos.color_tmp;
    }
    action set_tc_color() {
        ig_md.qos.tc = ig_md.qos.tc_tmp;
        ig_md.qos.color = ig_md.qos.color_tmp;
    }
    table tc_color_over {
        key = {
            ig_md.qos.acl_set_color: exact;
            ig_md.qos.acl_set_tc   : exact;
        }
        actions = {
            NoAction;
            set_tc;
            set_color;
            set_tc_color;
        }
        const default_action = NoAction;
    }
    apply {
        tc_color_over.apply();
    }
}

control In_LifMeter(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size=1024) {
    Meter<bit<14>>(4096, MeterType_t.BYTES) v4_meter;
    Meter<bit<14>>(4096, MeterType_t.BYTES) v6_meter;
    action v4_set_color_blind() {
        ig_md.qos.lif_meter_color = (bit<2>)v4_meter.execute((bit<14>)ig_md.policer.iif);
    }
    @ignore_table_dependency("Ig_front.lif_meter.v6_lif_meter") table v4_lif_meter {
        key = {
            ig_md.policer.iif: exact;
        }
        actions = {
            @defaultonly NoAction;
            v4_set_color_blind;
        }
        const default_action = NoAction;
        size = 4 * table_size;
    }
    action v6_set_color_blind() {
        ig_md.qos.lif_meter_color = (bit<2>)v6_meter.execute((bit<14>)ig_md.policer.iif);
    }
    @ignore_table_dependency("Ig_front.lif_meter.v4_lif_meter") table v6_lif_meter {
        key = {
            ig_md.policer.iif: exact;
        }
        actions = {
            @defaultonly NoAction;
            v6_set_color_blind;
        }
        const default_action = NoAction;
        size = 4 * table_size;
    }
    apply {
        if (hdr.ipv4.isValid()) {
            v4_lif_meter.apply();
        } else if (hdr.ipv6.isValid()) {
            v6_lif_meter.apply();
        }
    }
}

control Out_LifMeter(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t table_size=1024) {
    Meter<bit<14>>(16384, MeterType_t.BYTES) v4_meter;
    Meter<bit<14>>(16384, MeterType_t.BYTES) v6_meter;
    action v4_set_color_blind() {
        eg_md.qos.lif_meter_color = (bit<2>)v4_meter.execute((bit<14>)eg_md.common.oif);
    }
    @ignore_table_dependency("Eg_downlink.lif_meter.v6_lif_meter") @placement_priority(50) table v4_lif_meter {
        key = {
            eg_md.common.oif: exact;
        }
        actions = {
            @defaultonly NoAction;
            v4_set_color_blind;
        }
        const default_action = NoAction;
        size = 16 * table_size;
    }
    action v6_set_color_blind() {
        eg_md.qos.lif_meter_color = (bit<2>)v6_meter.execute((bit<14>)eg_md.common.oif);
    }
    @ignore_table_dependency("Eg_downlink.lif_meter.v4_lif_meter") @placement_priority(50) table v6_lif_meter {
        key = {
            eg_md.common.oif: exact;
        }
        actions = {
            @defaultonly NoAction;
            v6_set_color_blind;
        }
        const default_action = NoAction;
        size = 16 * table_size;
    }
    apply {
        if (hdr.inner_ipv4.isValid()) {
            v4_lif_meter.apply();
        } else if (hdr.inner_ipv6.isValid()) {
            v6_lif_meter.apply();
        }
    }
}

control In_PortMeter(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size=256) {
    Meter<bit<8>>(256, MeterType_t.BYTES) meter;
    action set_color_blind() {
        ig_md.qos.port_meter_color = (bit<2>)meter.execute(ig_md.qos.port_meter_index);
    }
    table meter_index {
        key = {
            ig_md.qos.port_meter_index: exact;
        }
        actions = {
            @defaultonly NoAction;
            set_color_blind;
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        meter_index.apply();
    }
}

control Out_PortMeter(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t table_size=256) {
    Meter<bit<8>>(256, MeterType_t.BYTES) meter;
    action set_color_blind() {
        eg_md.qos.port_meter_color = (bit<2>)meter.execute(eg_md.qos.port_meter_index);
    }
    table meter_index {
        key = {
            eg_md.qos.port_meter_index: exact;
        }
        actions = {
            @defaultonly NoAction;
            set_color_blind;
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        meter_index.apply();
    }
}

control AclMeter_In(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size=4096) {
    Meter<bit<12>>(4096, MeterType_t.BYTES) meter;
    action set_color_blind() {
        ig_md.qos.acl_meter_color = (bit<2>)meter.execute(ig_md.qos.acl_meter_index);
    }
    table meter_index {
        key = {
            ig_md.qos.acl_meter_index: exact;
        }
        actions = {
            @defaultonly NoAction;
            set_color_blind;
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        meter_index.apply();
    }
}

control AclMeter_Out(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t table_size=4096) {
    Meter<bit<12>>(4096, MeterType_t.BYTES) meter;
    action set_color_blind() {
        eg_md.qos.acl_meter_color = (bit<2>)meter.execute(eg_md.qos.acl_meter_index);
    }
    table meter_index {
        key = {
            eg_md.qos.acl_meter_index: exact;
        }
        actions = {
            @defaultonly NoAction;
            set_color_blind;
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        meter_index.apply();
    }
}

control QppbMeter_In(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size=256) {
    Meter<bit<8>>(256, MeterType_t.BYTES) meter;
    action set_color_blind() {
        ig_md.qos.qppb_meter_color = (bit<2>)meter.execute(ig_md.qos.qppb_meter_index);
    }
    table meter_index {
        key = {
            ig_md.qos.qppb_meter_index: exact;
        }
        actions = {
            @defaultonly NoAction;
            set_color_blind;
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        meter_index.apply();
    }
}

control QppbMeter_Out(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t table_size=256) {
    Meter<bit<8>>(256, MeterType_t.BYTES) meter;
    action set_color_blind() {
        eg_md.qos.qppb_meter_color = (bit<2>)meter.execute(eg_md.qos.qppb_meter_index);
    }
    @placement_priority(127) table meter_index {
        key = {
            eg_md.qos.qppb_meter_index: exact;
        }
        actions = {
            @defaultonly NoAction;
            set_color_blind;
        }
        const default_action = NoAction;
        size = 256;
    }
    apply {
        meter_index.apply();
    }
}

control Meter_decide_In(inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    Counter<bit<32>, bit<14>>(16 * 1024, CounterType_t.PACKETS) meter_stats;
    action drop() {
        ig_md.qos.car_flags = 1;
        meter_stats.count(ig_md.policer.iif[13:0]);
    }
    action forward() {
    }
    table meter_result {
        key = {
            ig_md.qos.port_meter_color: ternary;
            ig_md.qos.lif_meter_color : ternary;
            ig_md.qos.acl_meter_color : ternary;
        }
        actions = {
            drop;
            forward;
        }
        const default_action = forward();
    }
    apply {
        meter_result.apply();
    }
}

control TM(inout switch_egress_metadata_t eg_md) {
    Counter<bit<64>, bit<16>>(32768, CounterType_t.PACKETS_AND_BYTES) hqos_pkt_counter1;
    action hqos_pkt_add1() {
        hqos_pkt_counter1.count(eg_md.qos.flowid);
    }
    table hqos_pkt_count1 {
        key = {
            eg_md.qos.flowid: exact;
        }
        actions = {
            NoAction;
            hqos_pkt_add1;
        }
        const default_action = NoAction;
        size = 32768;
    }
    Counter<bit<64>, bit<16>>(32768, CounterType_t.PACKETS_AND_BYTES) hqos_pkt_counter2;
    action hqos_pkt_add2() {
        hqos_pkt_counter2.count(eg_md.qos.flowid);
    }
    table hqos_pkt_count2 {
        key = {
            eg_md.qos.flowid: exact;
        }
        actions = {
            NoAction;
            hqos_pkt_add2;
        }
        const default_action = NoAction;
        size = 32768;
    }
    Register<bit<32>, bit<16>>(65536, 0) hqos_drop_pkt_reg1;
    RegisterAction<bit<32>, bit<16>, bit<1>>(hqos_drop_pkt_reg1) hqos_drop_pkt_act1 = {
        void apply(inout bit<32> reg) {
            reg = reg + 1;
        }
    };
    action hqos_drop_pkt_add1() {
        hqos_drop_pkt_act1.execute(eg_md.qos.flowid);
    }
    table hqos_drop_pkt_count1 {
        key = {
            eg_md.qos.flowid: exact;
        }
        actions = {
            NoAction;
            hqos_drop_pkt_add1;
        }
        const default_action = NoAction;
        size = 65536;
    }
    Register<bit<32>, bit<16>>(65536, 0) hqos_drop_byte_reg1;
    RegisterAction<bit<32>, bit<16>, bit<1>>(hqos_drop_byte_reg1) hqos_drop_byte_act1 = {
        void apply(inout bit<32> reg) {
            reg = reg + 1;
        }
    };
    action hqos_drop_byte_add1() {
        hqos_drop_byte_act1.execute(eg_md.qos.flowid);
    }
    table hqos_drop_byte_count1 {
        key = {
            eg_md.qos.flowid: exact;
        }
        actions = {
            NoAction;
            hqos_drop_byte_add1;
        }
        const default_action = NoAction;
        size = 65536;
    }
    apply {
        hqos_pkt_count1.apply();
        hqos_drop_pkt_count1.apply();
        hqos_drop_byte_count1.apply();
    }
}

control Qos_Count(inout switch_ingress_metadata_t ig_md) {
    Register<bit<32>, bit<16>>(80, 0) qos_drop_pkt_reg1;
    RegisterAction<bit<32>, bit<16>, bit<1>>(qos_drop_pkt_reg1) qos_drop_pkt_act1 = {
        void apply(inout bit<32> reg) {
            reg = reg + 1;
        }
    };
    action qos_drop_pkt_add1(bit<16> flowid) {
        qos_drop_pkt_act1.execute(flowid);
    }
    table qos_drop_pkt_count1 {
        key = {
            ig_md.common.dst_port: exact;
            ig_md.qos.tc         : exact;
        }
        actions = {
            NoAction;
            qos_drop_pkt_add1;
        }
        const default_action = NoAction;
        size = 80;
    }
    Register<bit<32>, bit<16>>(80, 0) qos_drop_byte_reg1;
    RegisterAction<bit<32>, bit<16>, bit<1>>(qos_drop_byte_reg1) qos_drop_byte_act1 = {
        void apply(inout bit<32> reg) {
            reg = reg + 1;
        }
    };
    action qos_drop_byte_add1(bit<16> flowid) {
        qos_drop_byte_act1.execute(flowid);
    }
    table qos_drop_byte_count1 {
        key = {
            ig_md.common.dst_port: exact;
            ig_md.qos.tc         : exact;
        }
        actions = {
            NoAction;
            qos_drop_byte_add1;
        }
        const default_action = NoAction;
        size = 80;
    }
    apply {
        qos_drop_pkt_count1.apply();
        qos_drop_byte_count1.apply();
    }
}

control Qid_Map(inout switch_egress_metadata_t eg_md) {
    action set_flowid(bit<16> flowid) {
        eg_md.qos.flowid = flowid;
    }
    table qid_map {
        key = {
            eg_md.flags.is_intf: exact;
        }
        actions = {
            set_flowid;
        }
        const entries = {
                        0 : set_flowid(0);
                        1 : set_flowid(0x8000);
        }

        size = 2;
    }
    apply {
        qid_map.apply();
        eg_md.qos.flowid[14:3] = eg_md.qos.to_fpga_qid;
        eg_md.qos.flowid[2:0] = eg_md.qos.tc;
    }
}

control downlink_ig_acl_key_sel(in switch_header_t hdr, inout switch_ingress_metadata_t ig_md, inout switch_ingress_policer_slice_t slice) {
    action set_group_classid_1() {
        slice.group_classid = ig_md.policer.group_classid_1;
    }
    action set_group_classid_2() {
        slice.group_classid = ig_md.policer.group_classid_2;
    }
    action set_group_classid_3() {
        slice.group_classid = ig_md.policer.group_classid_3;
    }
    action set_group_classid_4() {
        slice.group_classid = ig_md.policer.group_classid_4;
    }
    @placement_priority(60)
    table acl {
        key = {
            slice.group: exact;
        }
        actions = {
            set_group_classid_1;
            set_group_classid_2;
            set_group_classid_3;
            set_group_classid_4;
        }
        const entries = {
                        SWITCH_ACL_BYPASS_1 : set_group_classid_1();
                        SWITCH_ACL_BYPASS_2 : set_group_classid_2();
                        SWITCH_ACL_BYPASS_3 : set_group_classid_3();
                        SWITCH_ACL_BYPASS_4 : set_group_classid_4();
        }

        size = 4;
    }
    apply {
        acl.apply();
    }
}

control ig_ip_frag(in ipv4_h ipv4, inout switch_lookup_fields_t lkp) {
    action set_ip_frag(switch_ip_frag_t ip_frag) {
        lkp.ip_frag = ip_frag;
    }
    table get_ip_frag {
        key = {
            ipv4.isValid()  : exact;
            ipv4.flags      : ternary;
            ipv4.frag_offset: ternary;
        }
        actions = {
            set_ip_frag;
        }
        default_action = set_ip_frag(0);
        size = 8;
    }
    apply {
        get_ip_frag.apply();
    }
}

control eg_ip_frag(in ipv4_h ipv4, inout switch_lookup_fields_t lkp) {
    action set_ip_frag(switch_ip_frag_t ip_frag) {
        lkp.ip_frag = ip_frag;
    }
    table get_ip_frag {
        key = {
            ipv4.isValid()  : exact;
            ipv4.flags      : ternary;
            ipv4.frag_offset: ternary;
        }
        actions = {
            set_ip_frag;
        }
        default_action = set_ip_frag(0);
        size = 8;
    }
    apply {
        get_ip_frag.apply();
    }
}

control downlink_ig_acl_pre(in switch_header_t hdr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm, inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size=128) {
    ig_ip_frag() ip_frag;
    downlink_ig_acl_key_sel() key_sel2;
    downlink_ig_acl_key_sel() key_sel3;
    downlink_ig_acl_key_sel() key_sel4;
    downlink_ig_acl_key_sel() key_sel5;
    downlink_ig_acl_key_sel() key_sel6;
    action set_properties(switch_acl_classid_t classid_1, switch_acl_classid_t classid_2, switch_acl_classid_t classid_3, switch_acl_classid_t classid_4) {
        ig_md.policer.group_classid_1 = classid_1;
        ig_md.policer.group_classid_2 = classid_2;
        ig_md.policer.group_classid_3 = classid_3;
        ig_md.policer.group_classid_4 = classid_4;
        ig_md.policer.slice1.group_classid = classid_1;
    }
    table oif_properties {
        key = {
            hdr.ipv4.isValid(): exact;
            hdr.ipv6.isValid(): exact;
            ig_md.common.oif  : exact;
        }
        actions = {
            NoAction;
            set_properties;
        }
        const default_action = NoAction;
        size = 32 * 1024;
    }
    action set_src_port_label(bit<32> label) {
        ig_md.lkp.l4_port_label_32 = label;
    }
    action set_dst_port_label(bit<32> label) {
        ig_md.lkp.l4_port_label_32 = ig_md.lkp.l4_port_label_32 | label;
    }
    @entries_with_ranges(table_size) table l4_dst_port {
        key = {
            hdr.ipv4.isValid()   : exact;
            hdr.ipv6.isValid()   : exact;
            ig_md.lkp.l4_dst_port: range;
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
            hdr.ipv4.isValid()   : exact;
            hdr.ipv6.isValid()   : exact;
            ig_md.lkp.l4_src_port: range;
        }
        actions = {
            NoAction;
            set_src_port_label;
        }
        const default_action = NoAction;
        size = table_size;
    }
    action set_group(switch_acl_bypass_t group1, switch_acl_bypass_t group2, switch_acl_bypass_t group3, switch_acl_bypass_t group4, switch_acl_bypass_t group5, switch_acl_bypass_t group6) {
        ig_md.policer.slice1.group = group1;
        ig_md.policer.slice2.group = group2;
        ig_md.policer.slice3.group = group3;
        ig_md.policer.slice4.group = group4;
        ig_md.policer.slice5.group = group5;
        ig_md.policer.slice6.group = group6;
    }
    table acl_group {
        key = {
            hdr.ipv4.isValid(): exact;
            hdr.ipv6.isValid(): exact;
        }
        actions = {
            NoAction;
            set_group;
        }
        size = 2;
        default_action = NoAction;
    }
    apply {
        ig_md.policer.bypass = 0;
        oif_properties.apply();
        l4_src_port.apply();
        l4_dst_port.apply();
        ip_frag.apply(hdr.ipv4, ig_md.lkp);
        acl_group.apply();
        key_sel2.apply(hdr, ig_md, ig_md.policer.slice2);
        key_sel3.apply(hdr, ig_md, ig_md.policer.slice3);
        key_sel4.apply(hdr, ig_md, ig_md.policer.slice4);
        key_sel5.apply(hdr, ig_md, ig_md.policer.slice5);
        key_sel6.apply(hdr, ig_md, ig_md.policer.slice6);
    }
}

control downlink_ig_ipv4_acl(inout switch_header_t hdr, in switch_lookup_fields_t lkp, in switch_ingress_policer_slice_t slice, inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size=1024) {
    Counter<bit<32>, bit<16>>(table_size, CounterType_t.PACKETS_AND_BYTES) stats;
    action set_acl(bit<16> stats_id, bool set_drop) {
        stats.count(stats_id);
        ig_md.policer.bypass = ig_md.policer.bypass | slice.group;
        ig_md.flags.drop = (bit<1>)set_drop;
    }
    action set_mirror(bit<16> stats_id, switch_mirror_session_t mirror_id) {
        stats.count(stats_id);
        ig_md.policer.bypass = ig_md.policer.bypass | slice.group;
        add_ext_mirror(hdr, ig_md, mirror_id);
    }
    action set_sample(bit<16> stats_id, switch_ipfix_flow_id_t flow_id, switch_ipfix_mode_t mode, switch_ipfix_gap_t sample_gap, switch_ipfix_random_mask_t random_mask, switch_ipfix_session_t session_id) {
        stats.count(stats_id);
        ig_md.policer.bypass = ig_md.policer.bypass | slice.group;
        ig_md.ipfix.enable = true;
        ig_md.ipfix.flow_id = flow_id;
        ig_md.ipfix.mode = mode;
        ig_md.ipfix.sample_gap = sample_gap;
        ig_md.ipfix.random_mask = random_mask;
        ig_md.ipfix.session_id = session_id;
    }
    @ignore_table_dependency("Ig_downlink.acl.ipv6_acl1.acl") @ignore_table_dependency("Ig_downlink.acl.ipv6_acl2.acl") @ignore_table_dependency("Ig_downlink.acl.ipv6_acl3.acl") @ignore_table_dependency("Ig_downlink.acl.ipv6_acl4.acl") @placement_priority(126) table acl {
        key = {
            hdr.ipv4.src_addr   : ternary @name("ip_src_addr") ;
            hdr.ipv4.dst_addr   : ternary @name("ip_dst_addr") ;
            hdr.ipv4.protocol   : ternary @name("ip_proto") ;
            hdr.ipv4.diffserv   : ternary @name("ip_tos") ;
            lkp.ip_frag         : ternary @name("ip_frag") ;
            ig_md.policer.bypass: ternary @name("bypass") ;
            slice.group_classid : ternary @name("group_classid") ;
            lkp.l4_src_port     : ternary @name("l4_src_port") ;
            lkp.l4_dst_port     : ternary @name("l4_dst_port") ;
            lkp.l4_port_label_32: ternary @name("l4_port_label") ;
            lkp.tcp_flags[5:0]  : ternary @name("tcp_flags") ;
        }
        actions = {
            set_acl;
            set_mirror;
        }
        size = table_size;
    }
    apply {
        if (hdr.ipv4.isValid()) {
            acl.apply();
        }
    }
}

control downlink_ig_ipv6_acl(inout switch_header_t hdr, in switch_lookup_fields_t lkp, in switch_ingress_policer_slice_t slice, inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size=1024) {
    Counter<bit<32>, bit<16>>(table_size, CounterType_t.PACKETS_AND_BYTES) stats;
    action set_acl(bit<16> stats_id, bool set_drop) {
        stats.count(stats_id);
        ig_md.policer.bypass = ig_md.policer.bypass | slice.group;
        ig_md.flags.drop = (bit<1>)set_drop;
    }
    action set_mirror(bit<16> stats_id, switch_mirror_session_t mirror_id) {
        stats.count(stats_id);
        ig_md.policer.bypass = ig_md.policer.bypass | slice.group;
        add_ext_mirror(hdr, ig_md, mirror_id);
    }
    action set_sample(bit<16> stats_id, switch_ipfix_flow_id_t flow_id, switch_ipfix_mode_t mode, switch_ipfix_gap_t sample_gap, switch_ipfix_random_mask_t random_mask, switch_ipfix_session_t session_id) {
        stats.count(stats_id);
        ig_md.policer.bypass = ig_md.policer.bypass | slice.group;
        ig_md.ipfix.enable = true;
        ig_md.ipfix.flow_id = flow_id;
        ig_md.ipfix.mode = mode;
        ig_md.ipfix.sample_gap = sample_gap;
        ig_md.ipfix.random_mask = random_mask;
        ig_md.ipfix.session_id = session_id;
    }
    @ignore_table_dependency("Ig_downlink.acl.ipv4_acl1.acl") @ignore_table_dependency("Ig_downlink.acl.ipv4_acl2.acl") @ignore_table_dependency("Ig_downlink.acl.ipv4_acl3.acl") @ignore_table_dependency("Ig_downlink.acl.ipv4_acl4.acl") @placement_priority(126) table acl {
        key = {
            hdr.ipv6.src_addr     : ternary @name("ip_src_addr") ;
            hdr.ipv6.dst_addr     : ternary @name("ip_dst_addr") ;
            hdr.ipv6.next_hdr     : ternary @name("ip_proto") ;
            hdr.ipv6.traffic_class: ternary @name("ip_tos") ;
            ig_md.policer.bypass  : ternary @name("bypass") ;
            slice.group_classid   : ternary @name("group_classid") ;
            lkp.l4_src_port       : ternary @name("l4_src_port") ;
            lkp.l4_dst_port       : ternary @name("l4_dst_port") ;
            lkp.l4_port_label_32  : ternary @name("l4_port_label") ;
            lkp.tcp_flags[5:0]    : ternary @name("tcp_flags") ;
        }
        actions = {
            set_acl;
            set_mirror;
        }
        size = table_size;
    }
    apply {
        if (hdr.ipv6.isValid()) {
            acl.apply();
        }
    }
}

control downlink_ig_acl(inout switch_header_t hdr, in switch_lookup_fields_t lkp, inout switch_ingress_metadata_t ig_md) {
    downlink_ig_ipv6_acl(1024) ipv6_acl1;
    downlink_ig_ipv6_acl(1024) ipv6_acl2;
    downlink_ig_ipv6_acl(1024) ipv6_acl3;
    downlink_ig_ipv6_acl(1024) ipv6_acl4;
    downlink_ig_ipv4_acl(2048) ipv4_acl1;
    downlink_ig_ipv4_acl(2048) ipv4_acl2;
    downlink_ig_ipv4_acl(2048) ipv4_acl3;
    downlink_ig_ipv4_acl(2048) ipv4_acl4;
    apply {
        ipv4_acl1.apply(hdr, lkp, ig_md.policer.slice1, ig_md);
        ipv4_acl2.apply(hdr, lkp, ig_md.policer.slice2, ig_md);
        ipv4_acl3.apply(hdr, lkp, ig_md.policer.slice3, ig_md);
        ipv4_acl4.apply(hdr, lkp, ig_md.policer.slice4, ig_md);
        ipv6_acl1.apply(hdr, lkp, ig_md.policer.slice1, ig_md);
        ipv6_acl2.apply(hdr, lkp, ig_md.policer.slice2, ig_md);
        ipv6_acl3.apply(hdr, lkp, ig_md.policer.slice3, ig_md);
        ipv6_acl4.apply(hdr, lkp, ig_md.policer.slice4, ig_md);
    }
}

control downlink_eg_acl_pre(in switch_header_t hdr, inout switch_lookup_fields_t lkp, inout switch_egress_metadata_t eg_md) {
    eg_ip_frag() ip_frag;
    eg_ip_frag() inner_ip_frag;
    action set_properties(switch_acl_classid_t classid_1) {
        eg_md.policer.group_classid_1 = classid_1;
    }
    table oif_properties {
        key = {
            hdr.inner_ipv4.isValid(): exact;
            hdr.inner_ipv6.isValid(): exact;
            eg_md.common.oif        : exact;
        }
        actions = {
            NoAction;
            set_properties;
        }
        const default_action = NoAction;
        size = 32 * 1024;
    }
    action set_src_port_label(bit<32> label) {
        eg_md.lkp.l4_port_label_32 = label;
    }
    action set_dst_port_label(bit<32> label) {
        eg_md.lkp.l4_port_label_32 = eg_md.lkp.l4_port_label_32 | label;
    }
    @entries_with_ranges(64) table l4_dst_port {
        key = {
            hdr.inner_ipv4.isValid(): exact;
            hdr.inner_ipv6.isValid(): exact;
            eg_md.lkp.l4_dst_port   : range;
        }
        actions = {
            NoAction;
            set_dst_port_label;
        }
        const default_action = NoAction;
        size = 64;
    }
    @entries_with_ranges(64) table l4_src_port {
        key = {
            hdr.inner_ipv4.isValid(): exact;
            hdr.inner_ipv6.isValid(): exact;
            eg_md.lkp.l4_src_port   : range;
        }
        actions = {
            NoAction;
            set_src_port_label;
        }
        const default_action = NoAction;
        size = 64;
    }
    action set_ipv4() {
        eg_md.lkp.ip_src_addr[31:0] = hdr.ipv4.src_addr;
        eg_md.lkp.ip_dst_addr[31:0] = hdr.ipv4.dst_addr;
        eg_md.lkp.ip_proto = hdr.ipv4.protocol;
        eg_md.lkp.ip_tos = hdr.ipv4.diffserv;
        eg_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        eg_md.lkp.ip_inner = 0;
    }
    action set_inner_ipv4() {
        eg_md.lkp.ip_src_addr[31:0] = hdr.inner_ipv4.src_addr;
        eg_md.lkp.ip_dst_addr[31:0] = hdr.inner_ipv4.dst_addr;
        eg_md.lkp.ip_proto = hdr.inner_ipv4.protocol;
        eg_md.lkp.ip_tos = hdr.inner_ipv4.diffserv;
        eg_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        eg_md.lkp.ip_inner = 1;
    }
    action set_ipv6() {
        eg_md.lkp.ip_src_addr = hdr.ipv6.src_addr;
        eg_md.lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        eg_md.lkp.ip_proto = hdr.ipv6.next_hdr;
        eg_md.lkp.ip_tos = hdr.ipv6.traffic_class;
        eg_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        eg_md.lkp.ip_inner = 0;
    }
    action set_inner_ipv6() {
        eg_md.lkp.ip_src_addr = hdr.inner_ipv6.src_addr;
        eg_md.lkp.ip_dst_addr = hdr.inner_ipv6.dst_addr;
        eg_md.lkp.ip_proto = hdr.inner_ipv6.next_hdr;
        eg_md.lkp.ip_tos = hdr.inner_ipv6.traffic_class;
        eg_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        eg_md.lkp.ip_inner = 1;
    }
    table set_ip {
        key = {
            hdr.ipv4.isValid()      : exact;
            hdr.ipv6.isValid()      : exact;
            hdr.inner_ipv4.isValid(): exact;
            hdr.inner_ipv6.isValid(): exact;
        }
        actions = {
            set_ipv4;
            set_ipv6;
            set_inner_ipv4;
            set_inner_ipv6;
        }
        size = 16;
        const entries = {
                        (true, false, false, false) : set_ipv4();
                        (true, false, true, false) : set_ipv4();
                        (true, false, false, true) : set_ipv4();
                        (false, true, false, false) : set_ipv6();
                        (false, true, true, false) : set_ipv6();
                        (false, true, false, true) : set_ipv6();
                        (false, false, true, false) : set_inner_ipv4();
                        (false, false, false, true) : set_inner_ipv6();
        }

    }
    apply {
        oif_properties.apply();
        if (eg_md.tunnel.encap_type != SWITCH_TUNNEL_ENCAP_TYPE_MPLS && !hdr.mpls_vc_eg.isValid()) {
            set_ip.apply();
        }
        if (hdr.ipv4.isValid()) {
            ip_frag.apply(hdr.ipv4, eg_md.lkp);
        } else if (hdr.inner_ipv4.isValid()) {
            inner_ip_frag.apply(hdr.inner_ipv4, eg_md.lkp);
        }
        l4_src_port.apply();
        l4_dst_port.apply();
    }
}

control downlink_eg_qppb_acl(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t table_size=512) {
    Counter<bit<32>, bit<16>>(table_size, CounterType_t.PACKETS_AND_BYTES) stats;
    Meter<bit<16>>(table_size, MeterType_t.PACKETS) meter;
    action set_qppb(bit<16> stats_id, bit<8> meter_id, bit<1> set_dscp, bit<6> dscp) {
        stats.count(stats_id);
        eg_md.qos.qppb_meter_index = meter_id;
        eg_md.qos.qppb_set_dscp = set_dscp;
        eg_md.qos.qppb_dscp = dscp;
    }
    table acl {
        key = {
            eg_md.common.oif          : ternary;
            eg_md.route.dip_l3class_id: ternary;
            eg_md.route.sip_l3class_id: ternary;
        }
        actions = {
            set_qppb;
        }
        size = table_size;
    }
    action ipv4_dscp() {
        hdr.inner_ipv4.diffserv[7:2] = eg_md.qos.dscp;
        eg_md.qos.chgDSCP_disable = 1;
    }
    action ipv6_dscp() {
        hdr.inner_ipv6.traffic_class[7:2] = eg_md.qos.dscp;
        eg_md.qos.chgDSCP_disable = 1;
    }
    table chg_dscp {
        key = {
            eg_md.qos.chgDSCP_disable: exact;
            eg_md.qos.set_dscp       : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }
        actions = {
            ipv4_dscp;
            ipv6_dscp;
        }
        size = 16;
    }
    apply {
        acl.apply();
    }
}

control downlink_eg_qos_acl(inout switch_header_t hdr, inout switch_lookup_fields_t lkp, inout switch_egress_metadata_t eg_md)(switch_uint32_t ipv4_table_size=1024, switch_uint32_t ipv6_table_size=512) {
    Counter<bit<32>, bit<16>>(ipv4_table_size + ipv6_table_size, CounterType_t.PACKETS_AND_BYTES) stats;
    Meter<bit<12>>(ipv4_table_size + ipv6_table_size, MeterType_t.PACKETS) meter;
    action set_qos(bit<16> stats_id, switch_meter_index_t meter_id, bit<1> set_dscp, bit<6> dscp) {
        stats.count(stats_id);
        eg_md.qos.acl_meter_color = (bit<2>)meter.execute(meter_id);
        eg_md.qos.acl_set_dscp = set_dscp;
        eg_md.qos.acl_dscp = dscp;
    }
    @ignore_table_dependency("Eg_downlink.qos_acl.ipv6_acl") table ipv4_acl {
        key = {
            lkp.ip_src_addr[31:0]        : ternary @name("ip_src_addr") ;
            lkp.ip_dst_addr[31:0]        : ternary @name("ip_dst_addr") ;
            lkp.ip_proto                 : ternary @name("ip_proto") ;
            lkp.ip_tos                   : ternary @name("ip_tos") ;
            lkp.ip_frag                  : ternary @name("ip_frag") ;
            eg_md.policer.group_classid_1: ternary @name("group_classid") ;
            lkp.l4_src_port              : ternary @name("l4_src_port") ;
            lkp.l4_dst_port              : ternary @name("l4_dst_port") ;
            lkp.l4_port_label_32         : ternary @name("l4_port_label") ;
            lkp.tcp_flags[5:0]           : ternary @name("tcp_flags") ;
        }
        actions = {
            set_qos;
        }
        size = ipv4_table_size;
    }
    @ignore_table_dependency("Eg_downlink.qos_acl.ipv4_acl") table ipv6_acl {
        key = {
            lkp.ip_src_addr              : ternary @name("ip_src_addr") ;
            lkp.ip_dst_addr              : ternary @name("ip_dst_addr") ;
            lkp.ip_proto                 : ternary @name("ip_proto") ;
            lkp.ip_tos                   : ternary @name("ip_tos") ;
            eg_md.policer.group_classid_1: ternary @name("group_classid") ;
            lkp.l4_src_port              : ternary @name("l4_src_port") ;
            lkp.l4_dst_port              : ternary @name("l4_dst_port") ;
            lkp.l4_port_label_32         : ternary @name("l4_port_label") ;
            lkp.tcp_flags[5:0]           : ternary @name("tcp_flags") ;
        }
        actions = {
            set_qos;
        }
        size = ipv6_table_size;
    }
    action ipv4_dscp() {
        hdr.inner_ipv4.diffserv[7:2] = eg_md.qos.dscp;
        eg_md.qos.chgDSCP_disable = 1;
    }
    action ipv6_dscp() {
        hdr.inner_ipv6.traffic_class[7:2] = eg_md.qos.dscp;
        eg_md.qos.chgDSCP_disable = 1;
    }
    table chg_dscp {
        key = {
            eg_md.qos.chgDSCP_disable: exact;
            eg_md.qos.set_dscp       : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }
        actions = {
            ipv4_dscp;
            ipv6_dscp;
        }
        size = 16;
    }
    apply {
        if (eg_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
            ipv4_acl.apply();
        } else if (eg_md.lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
            ipv6_acl.apply();
        }
    }
}

control DownlinkEgressSystemAcl(inout switch_egress_metadata_t eg_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    switch_drop_reason_t acl_drop_reason;
    const switch_uint32_t sys_acl_table_size = 512;
    const switch_uint32_t drop_stats_table_size = 8192;
    Counter<bit<32>, bit<14>>(16 * 1024, CounterType_t.PACKETS) stats;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) sysacl_stats;
    action drop(switch_drop_reason_t reason_code, bit<16> stats_id) {
        acl_drop_reason = reason_code;
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        stats.count(eg_md.common.oif[13:0]);
    }
    action forward() {
    }
    table system_acl {
        key = {
            eg_md.qos.qppb_meter_color: ternary;
            eg_md.qos.port_meter_color: ternary;
            eg_md.qos.lif_meter_color : ternary;
            eg_md.qos.acl_meter_color : ternary;
        }
        actions = {
            drop;
            forward;
        }
        const default_action = forward();
        size = sys_acl_table_size;
    }
    apply {
        acl_drop_reason = 0;
        system_acl.apply();
    }
}

control black_white_list(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md) {
    switch_tmp_cpu_code_t w_cpu_code1;
    switch_tmp_cpu_code_t w_cpu_code2;
    switch_tmp_cpu_code_t w_cpu_code3;
    switch_tmp_cpu_code_t w_cpu_code4;
    switch_tmp_cpu_code_t b_cpu_code1;
    Counter<bit<32>, bit<16>>(1 << 16, CounterType_t.PACKETS) stats;
    bit<16> tmp_stats_id;
    action set_cpu_code(inout switch_tmp_cpu_code_t tmp_cpu_code, bit<16> cpu_code, bit<16> stats_id) {
        tmp_cpu_code.set = 1;
        tmp_cpu_code.cpu_code = cpu_code;
        tmp_cpu_code.stats_id = stats_id;
    }
    table black_sport {
        key = {
            hdr.ext_cpp.cpu_reason: exact;
            hdr.ext_cpp.src_port  : exact;
        }
        actions = {
            set_cpu_code(b_cpu_code1);
        }
        size = 2560;
    }
    table black_sport_back {
        key = {
            hdr.ext_cpp.cpu_reason: exact;
            hdr.ext_cpp.src_port  : ternary;
        }
        actions = {
            set_cpu_code(b_cpu_code1);
        }
        size = 512;
    }
    table white_sip_l4sport {
        key = {
            hdr.ext_cpp.cpu_reason: exact;
            eg_md.lkp.ip_type     : exact;
            eg_md.lkp.ip_src_addr : exact;
            eg_md.lkp.l4_src_port : exact;
        }
        actions = {
            set_cpu_code(w_cpu_code1);
        }
        size = 1024 * 6;
    }
    table white_sip_l4sport_back {
        key = {
            hdr.ext_cpp.cpu_reason: exact;
            eg_md.lkp.ip_type     : exact;
            eg_md.lkp.ip_src_addr : ternary;
            eg_md.lkp.l4_src_port : ternary;
        }
        actions = {
            set_cpu_code(w_cpu_code1);
        }
        size = 1024;
    }
    table white_sip_l4dport {
        key = {
            hdr.ext_cpp.cpu_reason: exact;
            eg_md.lkp.ip_type     : exact;
            eg_md.lkp.ip_src_addr : exact;
            eg_md.lkp.l4_dst_port : exact;
        }
        actions = {
            set_cpu_code(w_cpu_code2);
        }
        size = 1024 * 6;
    }
    table white_sip_l4dport_back {
        key = {
            hdr.ext_cpp.cpu_reason: exact;
            eg_md.lkp.ip_type     : exact;
            eg_md.lkp.ip_src_addr : ternary;
            eg_md.lkp.l4_dst_port : ternary;
        }
        actions = {
            set_cpu_code(w_cpu_code2);
        }
        size = 1024;
    }
    table white_sip {
        key = {
            hdr.ext_cpp.cpu_reason: exact;
            eg_md.lkp.ip_type     : exact;
            eg_md.lkp.ip_src_addr : exact;
        }
        actions = {
            set_cpu_code(w_cpu_code3);
        }
        size = 1024 * 4 + 512;
    }
    table white_sip_back {
        key = {
            hdr.ext_cpp.cpu_reason: exact;
            eg_md.lkp.ip_type     : exact;
            eg_md.lkp.ip_src_addr : ternary;
        }
        actions = {
            set_cpu_code(w_cpu_code3);
        }
        size = 512;
    }
    table white_smac {
        key = {
            hdr.ext_cpp.cpu_reason: exact;
            eg_md.lkp.mac_src_addr: exact;
        }
        actions = {
            set_cpu_code(w_cpu_code4);
        }
        size = 1024 * 2;
    }
    table white_smac_back {
        key = {
            hdr.ext_cpp.cpu_reason: exact;
            eg_md.lkp.mac_src_addr: ternary;
        }
        actions = {
            set_cpu_code(w_cpu_code4);
        }
        size = 512;
    }
    action sel_w_cpu_code1() {
        eg_md.common.cpu_code = w_cpu_code1.cpu_code;
        tmp_stats_id = w_cpu_code1.stats_id;
    }
    action sel_w_cpu_code2() {
        eg_md.common.cpu_code = w_cpu_code2.cpu_code;
        tmp_stats_id = w_cpu_code2.stats_id;
    }
    action sel_w_cpu_code3() {
        eg_md.common.cpu_code = w_cpu_code3.cpu_code;
        tmp_stats_id = w_cpu_code3.stats_id;
    }
    action sel_w_cpu_code4() {
        eg_md.common.cpu_code = w_cpu_code4.cpu_code;
        tmp_stats_id = w_cpu_code4.stats_id;
    }
    action sel_b_cpu_code1() {
        eg_md.common.cpu_code = b_cpu_code1.cpu_code;
        tmp_stats_id = b_cpu_code1.stats_id;
    }
    table cpu_code_dec {
        key = {
            w_cpu_code1.set: ternary;
            w_cpu_code2.set: ternary;
            w_cpu_code3.set: ternary;
            w_cpu_code4.set: ternary;
            b_cpu_code1.set: ternary;
        }
        actions = {
            sel_w_cpu_code1;
            sel_w_cpu_code2;
            sel_w_cpu_code3;
            sel_w_cpu_code4;
            sel_b_cpu_code1;
        }
        size = 5;
        const entries = {
                        (1, default, default, default, default) : sel_w_cpu_code1();
                        (default, 1, default, default, default) : sel_w_cpu_code2();
                        (default, default, 1, default, default) : sel_w_cpu_code3();
                        (default, default, default, 1, default) : sel_w_cpu_code4();
                        (default, default, default, default, 1) : sel_b_cpu_code1();
        }

    }
    apply {
        w_cpu_code1 = { 0, 0, 0 };
        w_cpu_code2 = { 0, 0, 0 };
        w_cpu_code3 = { 0, 0, 0 };
        w_cpu_code4 = { 0, 0, 0 };
        b_cpu_code1 = { 0, 0, 0 };
        tmp_stats_id = 0;
        switch (black_sport.apply().action_run) {
            set_cpu_code: {
            }
            default: {
                black_sport_back.apply();
            }
        }

        switch (white_sip_l4sport.apply().action_run) {
            set_cpu_code: {
            }
            default: {
                white_sip_l4sport_back.apply();
            }
        }

        switch (white_sip_l4dport.apply().action_run) {
            set_cpu_code: {
            }
            default: {
                white_sip_l4dport_back.apply();
            }
        }

        switch (white_sip.apply().action_run) {
            set_cpu_code: {
            }
            default: {
                white_sip_back.apply();
            }
        }

        switch (white_smac.apply().action_run) {
            set_cpu_code: {
            }
            default: {
                white_smac_back.apply();
            }
        }

        cpu_code_dec.apply();
        stats.count(tmp_stats_id);
    }
}

control fabric_copp(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    black_white_list() bw_list;
    Meter<bit<16>>(256, MeterType_t.BYTES) type_meter;
    Meter<bit<5>>(32, MeterType_t.BYTES) qid_meter;
    Meter<bit<1>>(1, MeterType_t.BYTES) port_meter;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) host_acl_stats;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) copp1_stats;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) copp2_stats;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) copp3_stats;
    bit<2> type_color;
    bit<2> qid_color;
    bit<2> port_color;
    bit<5> tmp_qid;
    action to_cpu(bit<16> meter_id, bit<5> qid, switch_mirror_session_t session_id) {
        type_color = (bit<2>)type_meter.execute(meter_id);
        tmp_qid = qid;
        eg_md.mirror.session_id = session_id;
        host_acl_stats.count();
    }
    action no_to_cpu() {
        eg_md.flags.glean = 0;
        host_acl_stats.count();
    }
    table host_acl {
        key = {
            hdr.ext_cpp.cpu_reason: ternary;
            eg_md.common.cpu_code : ternary;
            eg_md.lkp.ip_type     : exact;
            eg_md.lkp.ip_src_addr : ternary;
            eg_md.lkp.ip_dst_addr : ternary;
            eg_md.lkp.ip_proto    : ternary;
            eg_md.lkp.l4_src_port : ternary;
            eg_md.lkp.l4_dst_port : ternary;
        }
        actions = {
            to_cpu;
            no_to_cpu;
        }
        size = 256;
        counters = host_acl_stats;
    }
    action copp1_permit() {
        copp1_stats.count();
    }
    action copp1_drop() {
        eg_md.flags.glean = 0;
        copp1_stats.count();
    }
    table copp1 {
        key = {
            eg_md.flags.glean: exact;
            type_color       : exact;
        }
        actions = {
            copp1_permit;
            copp1_drop;
        }
        counters = copp1_stats;
        size = 2;
        const default_action = copp1_drop;
        const entries = {
                        (1, SWITCH_METER_COLOR_GREEN) : copp1_permit();
                        (1, SWITCH_METER_COLOR_YELLOW) : copp1_permit();
        }

    }
    action copp2_permit() {
        port_color = (bit<2>)port_meter.execute(0);
        copp2_stats.count();
    }
    action copp2_drop() {
        eg_md.flags.glean = 0;
        copp2_stats.count();
    }
    table copp2 {
        key = {
            eg_md.flags.glean: exact;
            qid_color        : exact;
        }
        actions = {
            copp2_permit;
            copp2_drop;
        }
        counters = copp2_stats;
        size = 2;
        const default_action = copp2_drop;
        const entries = {
                        (1, SWITCH_METER_COLOR_GREEN) : copp2_permit();
                        (1, SWITCH_METER_COLOR_YELLOW) : copp2_permit();
        }

    }
    action copp3_permit() {
        eg_intr_md_for_dprsr.mirror_type = 2;
        eg_md.mirror.type = 2;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        copp3_stats.count();
    }
    action copp3_drop() {
        eg_md.flags.glean = 0;
        copp3_stats.count();
    }
    table copp3 {
        key = {
            eg_md.flags.glean: exact;
            port_color       : exact;
        }
        actions = {
            copp3_permit;
            copp3_drop;
        }
        counters = copp3_stats;
        size = 2;
        const default_action = copp3_drop;
        const entries = {
                        (1, SWITCH_METER_COLOR_GREEN) : copp3_permit();
                        (1, SWITCH_METER_COLOR_YELLOW) : copp3_permit();
        }

    }
    apply {
        type_color = 0;
        qid_color = 0;
        port_color = 0;
        tmp_qid = 0;
        if (hdr.ext_cpp.isValid() && eg_intr_md.egress_port == 320 || eg_md.flags.glean == 1) {
            eg_md.flags.glean = 1;
            eg_md.common.cpu_code = (bit<16>)hdr.ext_cpp.cpu_reason;
            bw_list.apply(hdr, eg_md);
            host_acl.apply();
            switch (copp1.apply().action_run) {
                copp1_permit: {
                    qid_color = (bit<2>)qid_meter.execute(tmp_qid);
                }
            }

            copp2.apply();
            copp3.apply();
            eg_intr_md_for_dprsr.drop_ctl = 0x1;
        }
    }
}

control L2IntfAttr(inout switch_egress_metadata_t eg_md)(switch_uint32_t l2oif_attribute_size=16384, switch_uint32_t l2iif_attribute_size=16384) {
    action set_l2iif_properties(switch_netport_group_t ntpt_group, switch_ptag_mod_t ptg_igmd) {
        eg_md.tunnel.src_netport_group = ntpt_group;
        eg_md.tunnel.ptag_igmod = ptg_igmd;
    }
    table l2iif_attribute {
        key = {
            eg_md.common.iif: exact;
        }
        actions = {
            set_l2iif_properties;
            NoAction;
        }
        const default_action = NoAction;
        size = l2iif_attribute_size;
    }
    action set_l2oif_attribute(switch_netport_group_t ntpt_group) {
        eg_md.tunnel.dst_netport_group = ntpt_group;
    }
    table l2oif_attribute {
        key = {
            eg_md.ebridge.l2oif: exact;
        }
        actions = {
            set_l2oif_attribute;
            NoAction;
        }
        const default_action = NoAction;
        size = l2oif_attribute_size;
    }
    apply {
        if (eg_md.common.pkt_type == FABRIC_PKT_TYPE_ETH) {
            l2iif_attribute.apply();
            l2oif_attribute.apply();
        }
    }
}

control HorizonSplit(inout switch_egress_metadata_t eg_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)(switch_uint32_t horizon_split_size=64) {
    action drop() {
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }
    table horizon_split {
        key = {
            eg_md.tunnel.src_netport_group: exact;
            eg_md.tunnel.dst_netport_group: exact;
        }
        actions = {
            drop;
            NoAction;
        }
        const default_action = NoAction;
        size = horizon_split_size;
    }
    apply {
        if (eg_md.common.pkt_type == FABRIC_PKT_TYPE_ETH) {
            horizon_split.apply();
        }
    }
}

control IngressIPTunnel(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t src_dst_addr_size=10 * 1024, switch_uint32_t dst_addr_size=20 * 1024, switch_uint32_t src_dst_addr_back_size=512) {
    action end(switch_srv6_flavors_t srv6_flavors, bit<8> prefixlen, bit<2> si) {
        ig_md.tunnel.srv6_end_type = SWITCH_SRV6_END_TYPE_END;
        ig_md.tunnel.srv6_flavors = srv6_flavors;
        ig_md.srv6.prefixlen = prefixlen;
        ig_md.srv6.si = si;
    }
    action end_x(switch_srv6_flavors_t srv6_flavors, bit<8> prefixlen, bit<2> si, bit<16> nexthop, bit<1> is_ecmp, bit<2> level, bit<8> priority) {
        ig_md.flags.ext_srv6 = true;
        ig_md.common.extend = 1;
        add_ext_srv6(hdr, ig_md, 0, 1, level, is_ecmp, priority, nexthop);
        ig_md.tunnel.srv6_end_type = SWITCH_SRV6_END_TYPE_END_X;
        ig_md.tunnel.srv6_flavors = srv6_flavors;
        ig_md.srv6.prefixlen = prefixlen;
        ig_md.srv6.si = si;
    }
    action end_t(switch_srv6_flavors_t srv6_flavors, bit<8> prefixlen, bit<2> si, switch_lif_t l3iif) {
        end(srv6_flavors, prefixlen, si);
    }
    action end_b6(bit<16> nexthop, bit<1> is_ecmp, bit<2> level, bit<8> priority) {
        ig_md.flags.ext_srv6 = true;
        ig_md.common.extend = 1;
        add_ext_srv6(hdr, ig_md, 0, 1, level, is_ecmp, priority, nexthop);
    }
    action end_b6_encaps(bit<16> nexthop, bit<1> is_ecmp, bit<2> level, bit<8> priority) {
        end_b6(nexthop, is_ecmp, level, priority);
        ig_md.tunnel.srv6_end_type = SWITCH_SRV6_END_TYPE_END_B6_ENCAPS;
    }
    action end_b6_encaps_red(bit<16> nexthop, bit<1> is_ecmp, bit<2> level, bit<8> priority) {
        end_b6_encaps(nexthop, is_ecmp, level, priority);
    }
    action end_b6_insert(bit<16> nexthop, bit<1> is_ecmp, bit<2> level, bit<8> priority) {
        end_b6(nexthop, is_ecmp, level, priority);
        ig_md.tunnel.srv6_end_type = SWITCH_SRV6_END_TYPE_END_B6_INSERT;
    }
    action end_b6_insert_red(bit<16> nexthop, bit<1> is_ecmp, bit<2> level, bit<8> priority) {
        end_b6_insert(nexthop, is_ecmp, level, priority);
    }
    action end_op() {
        ig_md.tunnel.drop_reason = SWITCH_DROP_REASON_SRV6_OAM;
        ig_md.tunnel.srv6_end_type = SWITCH_SRV6_END_TYPE_END_OP;
    }
    action action_miss() {
        ig_md.tunnel.ip_addr_miss = true;
    }
    action set_terminate_properties(switch_lif_t l3iif, switch_tunnel_inner_pkt_t inner_type) {
        ig_md.tunnel.tmp_l3iif = l3iif;
        ig_md.tunnel.inner_type = inner_type;
    }
    action set_terminate_properties_vxlan(switch_lif_t l2iif) {
        ig_md.tunnel.tmp_l2iif = l2iif;
        ig_md.tunnel.inner_type = SWITCH_TUNNEL_INNER_PKT_NONE;
    }
    @placement_priority(127) table src_dst_addr {
        key = {
            ig_md.lkp.ip_src_addr: exact;
            ig_md.lkp.ip_dst_addr: exact;
            ig_md.tunnel.type    : exact;
        }
        actions = {
            NoAction;
            set_terminate_properties;
            set_terminate_properties_vxlan;
        }
        const default_action = NoAction;
        size = src_dst_addr_size;
    }
    @placement_priority(127) table dst_addr {
        key = {
            ig_md.lkp.ip_dst_addr: exact;
            ig_md.tunnel.type    : exact;
        }
        actions = {
            NoAction;
            end;
            end_x;
            end_b6_encaps;
            end_b6_encaps_red;
            end_b6_insert;
            end_b6_insert_red;
            end_op;
        }
        const default_action = NoAction;
        size = dst_addr_size;
    }
    @placement_priority(127) table src_dst_addr_back {
        key = {
            ig_md.lkp.ip_src_addr: ternary;
            ig_md.lkp.ip_dst_addr: ternary;
            ig_md.tunnel.type    : ternary;
        }
        actions = {
            action_miss;
            set_terminate_properties;
            set_terminate_properties_vxlan;
            end;
            end_x;
            end_b6_encaps;
            end_b6_encaps_red;
            end_b6_insert;
            end_b6_insert_red;
            end_op;
        }
        const default_action = action_miss;
        size = src_dst_addr_back_size;
    }
    apply {
        switch (src_dst_addr.apply().action_run) {
            NoAction: {
                switch (dst_addr.apply().action_run) {
                    NoAction: {
                        src_dst_addr_back.apply();
                    }
                }

            }
        }

    }
}

control IPTunnelTerminate(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t ip_tunnel_terminate_size=2 * 1024) {
    action set_terminate_properties() {
        ig_md.tunnel.terminate = true;
        ig_md.common.ul_iif = ig_md.common.iif;
        add_ext_tunnel_decap(hdr, ig_md);
        ig_md.common.iif = ig_md.tunnel.tmp_l3iif;
    }
    table ip_tunnel_terminate {
        key = {
            ig_md.tunnel.type            : exact;
            ig_md.tunnel.inner_pkt_parsed: exact;
            ig_md.tunnel.inner_type      : exact;
            ig_md.tunnel.ip_addr_miss    : exact;
        }
        actions = {
            set_terminate_properties;
            NoAction;
        }
        const default_action = NoAction;
        size = ip_tunnel_terminate_size;
    }
    apply {
        ip_tunnel_terminate.apply();
    }
}

control TunnelRewrite(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t get_rewrite_info_size=8 * 1024, switch_uint32_t ip_src_rewrite_size=2 * 1024, switch_uint32_t ip_ttl_rewrite_size=16, switch_uint32_t ip_dscp_rewrite_size=64) {
    action encap_ipv6_info(switch_src_index_t src_index, ipv6_addr_t dst, bit<8> hop_limit, bit<2> dscp_select, bit<6> tc_value) {
        eg_md.tunnel.src_index = src_index;
        hdr.ipv6.dst_addr = dst;
        hdr.ipv6.hop_limit = hop_limit;
        eg_md.tunnel.dscp_sel = dscp_select;
        hdr.ipv6.traffic_class[7:2] = tc_value;
    }
    action encap_ipv4_info(switch_src_index_t src_index, ipv4_addr_t dip, bit<8> ttl, bit<2> dscp_select, bit<6> dscp_value) {
        eg_md.tunnel.src_index = src_index;
        hdr.ipv4.dst_addr = dip;
        hdr.ipv4.ttl = ttl;
        eg_md.tunnel.dscp_sel = dscp_select;
        hdr.ipv4.diffserv[7:2] = dscp_value;
    }
    table get_rewrite_info {
        key = {
            eg_md.route.local_l3_encap_id[12:0]: exact;
        }
        actions = {
            encap_ipv4_info;
            encap_ipv6_info;
            NoAction;
        }
        const default_action = NoAction;
        size = get_rewrite_info_size;
    }
    action ipv6_set_src(ipv6_addr_t src) {
        hdr.ipv6.src_addr = src;
    }
    action ipv4_set_src(ipv4_addr_t src) {
        hdr.ipv4.src_addr = src;
    }
    table ip_src_rewrite {
        key = {
            eg_md.tunnel.src_index: exact;
        }
        actions = {
            ipv6_set_src;
            ipv4_set_src;
            NoAction;
        }
        size = ip_src_rewrite_size;
    }
    action copy_ipv4_ttl() {
        hdr.ipv4.ttl = eg_md.tunnel.ttl;
    }
    action copy_ipv6_hop_limit() {
        hdr.ipv6.hop_limit = eg_md.tunnel.ttl;
    }
    table ip_ttl_rewrite {
        key = {
            hdr.ipv4.ttl      : exact;
            hdr.ipv4.isValid(): exact;
            hdr.ipv6.hop_limit: exact;
            hdr.ipv6.isValid(): exact;
        }
        actions = {
            copy_ipv4_ttl;
            copy_ipv6_hop_limit;
            NoAction;
        }
        default_action = NoAction;
        size = ip_ttl_rewrite_size;
    }
    action copy_ipv4_from_pkt() {
        hdr.ipv4.diffserv[7:2] = eg_md.tunnel.inner_dscp;
    }
    action copy_ipv4_from_qos() {
        hdr.ipv4.diffserv[7:2] = eg_md.qos.dscp;
    }
    action copy_ipv6_from_pkt() {
        hdr.ipv6.traffic_class[7:2] = eg_md.tunnel.inner_dscp;
    }
    action copy_ipv6_from_qos() {
        hdr.ipv6.traffic_class[7:2] = eg_md.qos.dscp;
    }
    table ip_dscp_rewrite {
        key = {
            eg_md.tunnel.dscp_sel: exact;
            hdr.ipv4.isValid()   : exact;
            hdr.ipv6.isValid()   : exact;
        }
        actions = {
            NoAction;
            copy_ipv4_from_pkt;
            copy_ipv4_from_qos;
            copy_ipv6_from_pkt;
            copy_ipv6_from_qos;
        }
        const default_action = NoAction;
        size = ip_dscp_rewrite_size;
    }
    apply {
        get_rewrite_info.apply();
        ip_src_rewrite.apply();
        ip_ttl_rewrite.apply();
        ip_dscp_rewrite.apply();
    }
}

control VxlanTerminate(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t vxlan_terminate_size=16 * 1024, switch_uint32_t vxlan_terminate_back_size=512) {
    action set_terminate_properties(bit<16> evlan) {
        ig_md.ebridge.evlan = evlan;
        ig_md.tunnel.terminate = true;
        ig_md.common.ul_iif = ig_md.common.iif;
        add_ext_tunnel_decap(hdr, ig_md);
        ig_md.common.iif = ig_md.tunnel.tmp_l2iif;
    }
    table vxlan_terminate {
        key = {
            hdr.vxlan.vni            : exact;
            ig_md.tunnel.ip_addr_miss: exact;
        }
        actions = {
            set_terminate_properties;
            NoAction;
        }
        const default_action = NoAction;
        size = vxlan_terminate_size;
    }
    @stage(5) table vxlan_terminate_back {
        key = {
            hdr.vxlan.vni            : ternary;
            ig_md.tunnel.ip_addr_miss: ternary;
        }
        actions = {
            set_terminate_properties;
            NoAction;
        }
        const default_action = NoAction;
        size = vxlan_terminate_back_size;
    }
    apply {
        switch (vxlan_terminate.apply().action_run) {
            NoAction: {
                vxlan_terminate_back.apply();
            }
        }

    }
}

control L4ENCAP(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t l4_encap_table_size=65536, switch_uint32_t set_smac_size=16384) {
    action l4_encap_set_ethernet(bit<48> dst_addr, switch_lif_t l3oif) {
        hdr.ethernet.setValid();
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_ETH;
        hdr.ethernet.dst_addr = dst_addr;
        ig_md.route.l3oif = l3oif;
    }
    table l4_encap {
        key = {
            ig_md.tunnel.l4_encap: exact;
        }
        actions = {
            l4_encap_set_ethernet;
            NoAction;
        }
        const default_action = NoAction;
        size = l4_encap_table_size;
    }
    action set_smac_with_evlan(bit<48> src_addr, bit<16> evlan) {
        hdr.ethernet.src_addr = src_addr;
        ig_md.ebridge.evlan = evlan;
    }
    table set_smac {
        key = {
            ig_md.route.l3oif: exact;
        }
        actions = {
            NoAction;
            set_smac_with_evlan;
        }
        const default_action = NoAction;
        size = set_smac_size;
    }
    apply {
        l4_encap.apply();
        set_smac.apply();
    }
}

control EvlanMapVni(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t evlan_vni_mapping_size=8 * 1024) {
    action evlan_to_vni_map(bit<24> vni) {
        eg_md.tunnel.vni = vni;
    }
    @placement_priority(100) table evlan_vni_mapping {
        key = {
            eg_md.ebridge.evlan: exact;
        }
        actions = {
            evlan_to_vni_map;
            NoAction;
        }
        const default_action = NoAction;
        size = evlan_vni_mapping_size;
    }
    apply {
        if (eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_V4_VXLAN || eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_V6_VXLAN) {
            evlan_vni_mapping.apply();
        }
    }
}

control PW_PTAG_XLATE(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t table_ptag_encap_size=32, switch_uint32_t table_ptag_encap_inner_size=8) {
    action add_p() {
        hdr.inner_vlan_tag.push_front(1);
        hdr.inner_vlan_tag[0].setValid();
        hdr.inner_vlan_tag[0].vid = eg_md.tunnel.ptag_vid;
        hdr.inner_vlan_tag[0].ether_type = hdr.inner_ethernet.ether_type;
        hdr.inner_vlan_tag[0].cfi = 0;
        hdr.inner_vlan_tag[0].pcp = 0;
        hdr.inner_ethernet.ether_type = eg_md.tunnel.ptag_tpid;
        eg_md.common.pkt_length = eg_md.common.pkt_length + 16w4;
    }
    action modify_p() {
        hdr.inner_vlan_tag[0].vid = eg_md.tunnel.ptag_vid;
        hdr.inner_ethernet.ether_type = eg_md.tunnel.ptag_tpid;
    }
    action del_p() {
        hdr.inner_ethernet.ether_type = hdr.inner_vlan_tag[0].ether_type;
        hdr.inner_vlan_tag.pop_front(1);
        eg_md.common.pkt_length = eg_md.common.pkt_length - 16w4;
    }
    table pw_ptag_encap {
        key = {
            hdr.inner_vlan_tag[0].isValid(): exact;
            eg_md.tunnel.ptag_igmod        : exact;
            eg_md.tunnel.ptag_eg_action    : exact;
        }
        actions = {
            add_p;
            modify_p;
            del_p;
            NoAction;
        }
        default_action = NoAction;
        size = table_ptag_encap_size;
        const entries = {
                        (true, 0, VLANTAG_RAW_MODE) : NoAction();
                        (true, 0, VLANTAG_REPLACE_IF_PRESENT) : add_p();
                        (true, 0, VLANTAG_NOREPLACE_IF_PRESENT) : add_p();
                        (false, 0, VLANTAG_RAW_MODE) : NoAction();
                        (false, 0, VLANTAG_REPLACE_IF_PRESENT) : add_p();
                        (false, 0, VLANTAG_NOREPLACE_IF_PRESENT) : add_p();
                        (true, 1, VLANTAG_RAW_MODE) : del_p();
                        (true, 1, VLANTAG_REPLACE_IF_PRESENT) : modify_p();
                        (true, 1, VLANTAG_NOREPLACE_IF_PRESENT) : NoAction();
        }

    }
    action encap_inner_1() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.inner_vlan_tag[0] = hdr.vlan_tag[0];
        hdr.vlan_tag.pop_front(1);
    }
    action encap_inner_2() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.inner_vlan_tag[0] = hdr.vlan_tag[0];
        hdr.inner_vlan_tag[1] = hdr.vlan_tag[1];
        hdr.vlan_tag.pop_front(2);
    }
    table ptag_encap_inner {
        key = {
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
        }
        actions = {
            encap_inner_1;
            encap_inner_2;
            NoAction;
        }
        const default_action = NoAction;
        size = table_ptag_encap_inner_size;
    }
    apply {
        if (eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_MPLS) {
            pw_ptag_encap.apply();
        }
    }
}

control MPLS_tunnel_0_encap(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, inout switch_egress_tunnel_metadata_t tunnel)(switch_uint32_t tunnel0_table_size=64 * 1024) {
    bit<8> tunnel_ttl = 0;
    bit<3> tunnel_exp_mode = 0;
    bit<2> tunnel_label_num = 0;
    bit<1> opcode = 0;
    action push_tunnel_label_1(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[10 - 1].setValid();
        hdr.mpls_eg[10 - 1].label = label;
        hdr.mpls_eg[10 - 1].exp = exp;
        hdr.mpls_eg[10 - 1].bos = 0;
        hdr.mpls_eg[10 - 1].ttl = ttl;
    }
    action push_tunnel_one_label(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode) {
        push_tunnel_label_1(label0, exp0, ttl0);
        tunnel_ttl = ttl0;
        tunnel_exp_mode = exp_mode;
        tunnel_label_num = 1;
        opcode = 0;
    }
    action swap(bit<20> label, bit<3> exp, bit<8> ttl, bit<3> exp_mode) {
        hdr.mpls_vc_eg.label = label;
        hdr.mpls_vc_eg.exp = exp;
        hdr.mpls_vc_eg.ttl = ttl;
        tunnel_exp_mode = exp_mode;
        tunnel_ttl = ttl;
        opcode = 1;
    }
    action swap_to_self(bit<3> exp, bit<8> ttl, bit<3> exp_mode) {
        hdr.mpls_vc_eg.exp = exp;
        hdr.mpls_vc_eg.ttl = ttl;
        tunnel_exp_mode = exp_mode;
        tunnel_ttl = ttl;
        opcode = 1;
    }
    table mpls_tunnel0_rewrite {
        key = {
            eg_md.common.l3_encap: exact;
        }
        actions = {
            push_tunnel_one_label;
            swap;
            swap_to_self;
            NoAction;
        }
        const default_action = NoAction;
        size = tunnel0_table_size;
    }
    action rewrite_mpls_one_ttl() {
        hdr.mpls_eg[10 - 1].ttl = tunnel.ttl;
    }
    action rewrite_mpls_one_ttl_bos() {
        hdr.mpls_eg[10 - 1].ttl = tunnel.ttl;
        hdr.mpls_eg[10 - 1].bos = 1;
    }
    action rewrite_swap_mpls_ttl() {
        hdr.mpls_vc_eg.ttl = tunnel.ttl;
    }
    action rewrite_mpls_one_bos() {
        hdr.mpls_eg[10 - 1].bos = 1;
    }
    table mpls_tunnel0_ttl_rewrite {
        key = {
            hdr.mpls_vc_eg.isValid(): exact;
            tunnel_ttl              : ternary;
            tunnel_label_num        : exact;
            opcode                  : exact;
        }
        actions = {
            rewrite_mpls_one_ttl;
            rewrite_mpls_one_ttl_bos;
            rewrite_mpls_one_bos;
            rewrite_swap_mpls_ttl;
            NoAction;
        }
        const default_action = NoAction;
    }
    action rewrite_mpls_one_exp() {
        hdr.mpls_eg[10 - 1].exp = tunnel.exp;
    }
    table mpls_tunnel0_exp_rewrite {
        key = {
            tunnel_exp_mode : exact;
            tunnel_label_num: exact;
        }
        actions = {
            rewrite_mpls_one_exp;
            NoAction;
        }
        const default_action = NoAction;
        size = 32;
    }
    apply {
        mpls_tunnel0_rewrite.apply();
        mpls_tunnel0_ttl_rewrite.apply();
        mpls_tunnel0_exp_rewrite.apply();
    }
}

control MPLS_tunnel_1_encap(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, inout switch_egress_tunnel_metadata_t tunnel)(switch_uint32_t tunnel1_table_size=64 * 1024) {
    bit<8> tunnel_ttl = 0;
    bit<3> tunnel_exp_mode = 0;
    bit<3> tunnel_label_num = 0;
    action push_tunnel_label_2(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[10 - 2].setValid();
        hdr.mpls_eg[10 - 2].label = label;
        hdr.mpls_eg[10 - 2].exp = exp;
        hdr.mpls_eg[10 - 2].bos = 0;
        hdr.mpls_eg[10 - 2].ttl = ttl;
    }
    action push_tunnel_label_3(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[10 - 3].setValid();
        hdr.mpls_eg[10 - 3].label = label;
        hdr.mpls_eg[10 - 3].exp = exp;
        hdr.mpls_eg[10 - 3].bos = 0;
        hdr.mpls_eg[10 - 3].ttl = ttl;
    }
    action push_tunnel_label_4(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[10 - 4].setValid();
        hdr.mpls_eg[10 - 4].label = label;
        hdr.mpls_eg[10 - 4].exp = exp;
        hdr.mpls_eg[10 - 4].bos = 0;
        hdr.mpls_eg[10 - 4].ttl = ttl;
    }
    action push_tunnel_label_5(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[10 - 5].setValid();
        hdr.mpls_eg[10 - 5].label = label;
        hdr.mpls_eg[10 - 5].exp = exp;
        hdr.mpls_eg[10 - 5].bos = 0;
        hdr.mpls_eg[10 - 5].ttl = ttl;
    }
    action push_tunnel_one_label(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode) {
        push_tunnel_label_2(label0, exp0, ttl0);
        tunnel_ttl = ttl0;
        tunnel_exp_mode = exp_mode;
        tunnel_label_num = 1;
    }
    action push_tunnel_two_labels(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode, bit<20> label1) {
        push_tunnel_label_2(label0, exp0, ttl0);
        push_tunnel_label_3(label1, exp0, ttl0);
        tunnel_ttl = ttl0;
        tunnel_exp_mode = exp_mode;
        tunnel_label_num = 2;
    }
    action push_tunnel_three_labels(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode, bit<20> label1, bit<20> label2) {
        push_tunnel_label_2(label0, exp0, ttl0);
        push_tunnel_label_3(label1, exp0, ttl0);
        push_tunnel_label_4(label2, exp0, ttl0);
        tunnel_ttl = ttl0;
        tunnel_exp_mode = exp_mode;
        tunnel_label_num = 3;
    }
    action push_tunnel_four_labels(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode, bit<20> label1, bit<20> label2, bit<20> label3) {
        push_tunnel_label_2(label0, exp0, ttl0);
        push_tunnel_label_3(label1, exp0, ttl0);
        push_tunnel_label_4(label2, exp0, ttl0);
        push_tunnel_label_5(label3, exp0, ttl0);
        tunnel_ttl = ttl0;
        tunnel_exp_mode = exp_mode;
        tunnel_label_num = 4;
    }
    table mpls_tunnel1_rewrite {
        key = {
            eg_md.common.l3_encap: exact;
        }
        actions = {
            push_tunnel_one_label;
            push_tunnel_two_labels;
            push_tunnel_three_labels;
            push_tunnel_four_labels;
            NoAction;
        }
        const default_action = NoAction;
        size = tunnel1_table_size;
    }
    action rewrite_mpls_one_ttl() {
        hdr.mpls_eg[10 - 2].ttl = tunnel.ttl;
    }
    action rewrite_mpls_two_ttl() {
        hdr.mpls_eg[10 - 2].ttl = tunnel.ttl;
        hdr.mpls_eg[10 - 3].ttl = tunnel.ttl;
    }
    action rewrite_mpls_three_ttl() {
        hdr.mpls_eg[10 - 2].ttl = tunnel.ttl;
        hdr.mpls_eg[10 - 3].ttl = tunnel.ttl;
        hdr.mpls_eg[10 - 4].ttl = tunnel.ttl;
    }
    action rewrite_mpls_four_ttl() {
        hdr.mpls_eg[10 - 2].ttl = tunnel.ttl;
        hdr.mpls_eg[10 - 3].ttl = tunnel.ttl;
        hdr.mpls_eg[10 - 4].ttl = tunnel.ttl;
        hdr.mpls_eg[10 - 5].ttl = tunnel.ttl;
    }
    table mpls_tunnel1_ttl_rewrite {
        key = {
            tunnel_ttl      : exact;
            tunnel_label_num: exact;
        }
        actions = {
            rewrite_mpls_one_ttl;
            rewrite_mpls_two_ttl;
            rewrite_mpls_three_ttl;
            rewrite_mpls_four_ttl;
            NoAction;
        }
        const default_action = NoAction;
    }
    action rewrite_mpls_one_exp() {
        hdr.mpls_eg[10 - 2].exp = tunnel.exp;
    }
    action rewrite_mpls_two_exp() {
        hdr.mpls_eg[10 - 2].exp = tunnel.exp;
        hdr.mpls_eg[10 - 3].exp = tunnel.exp;
    }
    action rewrite_mpls_three_exp() {
        hdr.mpls_eg[10 - 2].exp = tunnel.exp;
        hdr.mpls_eg[10 - 3].exp = tunnel.exp;
        hdr.mpls_eg[10 - 4].exp = tunnel.exp;
    }
    action rewrite_mpls_four_exp() {
        hdr.mpls_eg[10 - 2].exp = tunnel.exp;
        hdr.mpls_eg[10 - 3].exp = tunnel.exp;
        hdr.mpls_eg[10 - 4].exp = tunnel.exp;
        hdr.mpls_eg[10 - 5].exp = tunnel.exp;
    }
    table mpls_tunnel1_exp_rewrite {
        key = {
            tunnel_exp_mode : exact;
            tunnel_label_num: exact;
        }
        actions = {
            rewrite_mpls_one_exp;
            rewrite_mpls_two_exp;
            rewrite_mpls_three_exp;
            rewrite_mpls_four_exp;
            NoAction;
        }
        const default_action = NoAction;
        size = 32;
    }
    apply {
        mpls_tunnel1_rewrite.apply();
        mpls_tunnel1_ttl_rewrite.apply();
        mpls_tunnel1_exp_rewrite.apply();
    }
}

control MPLS_tunnel_2_encap(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, inout switch_egress_tunnel_metadata_t tunnel)(switch_uint32_t tunnel2_table_size=16 * 1024) {
    bit<8> tunnel_ttl = 0;
    bit<3> tunnel_exp_mode = 0;
    bit<4> tunnel_label_num = 0;
    action push_tunnel_label_6(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[10 - 6].setValid();
        hdr.mpls_eg[10 - 6].label = label;
        hdr.mpls_eg[10 - 6].exp = exp;
        hdr.mpls_eg[10 - 6].bos = 0;
        hdr.mpls_eg[10 - 6].ttl = ttl;
    }
    action push_tunnel_label_7(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[10 - 7].setValid();
        hdr.mpls_eg[10 - 7].label = label;
        hdr.mpls_eg[10 - 7].exp = exp;
        hdr.mpls_eg[10 - 7].bos = 0;
        hdr.mpls_eg[10 - 7].ttl = ttl;
    }
    action push_tunnel_label_8(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[10 - 8].setValid();
        hdr.mpls_eg[10 - 8].label = label;
        hdr.mpls_eg[10 - 8].exp = exp;
        hdr.mpls_eg[10 - 8].bos = 0;
        hdr.mpls_eg[10 - 8].ttl = ttl;
    }
    action push_tunnel_label_9(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[10 - 9].setValid();
        hdr.mpls_eg[10 - 9].label = label;
        hdr.mpls_eg[10 - 9].exp = exp;
        hdr.mpls_eg[10 - 9].bos = 0;
        hdr.mpls_eg[10 - 9].ttl = ttl;
    }
    action push_tunnel_label_10(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[10 - 10].setValid();
        hdr.mpls_eg[10 - 10].label = label;
        hdr.mpls_eg[10 - 10].exp = exp;
        hdr.mpls_eg[10 - 10].bos = 0;
        hdr.mpls_eg[10 - 10].ttl = ttl;
    }
    action push_tunnel_one_label(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode) {
        push_tunnel_label_6(label0, exp0, ttl0);
        tunnel_ttl = ttl0;
        tunnel_exp_mode = exp_mode;
        tunnel_label_num = 1;
    }
    action push_tunnel_two_labels(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode, bit<20> label1) {
        push_tunnel_label_6(label0, exp0, ttl0);
        push_tunnel_label_7(label1, exp0, ttl0);
        tunnel_ttl = ttl0;
        tunnel_exp_mode = exp_mode;
        tunnel_label_num = 2;
    }
    action push_tunnel_three_labels(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode, bit<20> label1, bit<20> label2) {
        push_tunnel_label_6(label0, exp0, ttl0);
        push_tunnel_label_7(label1, exp0, ttl0);
        push_tunnel_label_8(label2, exp0, ttl0);
        tunnel_ttl = ttl0;
        tunnel_exp_mode = exp_mode;
        tunnel_label_num = 3;
    }
    action push_tunnel_four_labels(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode, bit<20> label1, bit<20> label2, bit<20> label3) {
        push_tunnel_label_6(label0, exp0, ttl0);
        push_tunnel_label_7(label1, exp0, ttl0);
        push_tunnel_label_8(label2, exp0, ttl0);
        push_tunnel_label_9(label3, exp0, ttl0);
        tunnel_ttl = ttl0;
        tunnel_exp_mode = exp_mode;
        tunnel_label_num = 4;
    }
    action push_tunnel_five_labels(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode, bit<20> label1, bit<20> label2, bit<20> label3, bit<20> label4) {
        push_tunnel_label_6(label0, exp0, ttl0);
        push_tunnel_label_7(label1, exp0, ttl0);
        push_tunnel_label_8(label2, exp0, ttl0);
        push_tunnel_label_9(label3, exp0, ttl0);
        push_tunnel_label_10(label4, exp0, ttl0);
        tunnel_ttl = ttl0;
        tunnel_exp_mode = exp_mode;
        tunnel_label_num = 5;
    }
    table mpls_tunnel2_rewrite {
        key = {
            eg_md.route.local_l3_encap_id[13:0]: exact;
        }
        actions = {
            push_tunnel_one_label;
            push_tunnel_two_labels;
            push_tunnel_three_labels;
            push_tunnel_four_labels;
            push_tunnel_five_labels;
            NoAction;
        }
        const default_action = NoAction;
        size = tunnel2_table_size;
    }
    action rewrite_mpls_one_ttl() {
        hdr.mpls_eg[10 - 6].ttl = tunnel.ttl;
    }
    action rewrite_mpls_two_ttl() {
        hdr.mpls_eg[10 - 6].ttl = tunnel.ttl;
        hdr.mpls_eg[10 - 7].ttl = tunnel.ttl;
    }
    action rewrite_mpls_three_ttl() {
        hdr.mpls_eg[10 - 6].ttl = tunnel.ttl;
        hdr.mpls_eg[10 - 7].ttl = tunnel.ttl;
        hdr.mpls_eg[10 - 8].ttl = tunnel.ttl;
    }
    action rewrite_mpls_four_ttl() {
        hdr.mpls_eg[10 - 6].ttl = tunnel.ttl;
        hdr.mpls_eg[10 - 7].ttl = tunnel.ttl;
        hdr.mpls_eg[10 - 8].ttl = tunnel.ttl;
        hdr.mpls_eg[10 - 9].ttl = tunnel.ttl;
    }
    action rewrite_mpls_five_ttl() {
        hdr.mpls_eg[10 - 6].ttl = tunnel.ttl;
        hdr.mpls_eg[10 - 7].ttl = tunnel.ttl;
        hdr.mpls_eg[10 - 8].ttl = tunnel.ttl;
        hdr.mpls_eg[10 - 9].ttl = tunnel.ttl;
        hdr.mpls_eg[10 - 10].ttl = tunnel.ttl;
    }
    table mpls_tunnel2_ttl_rewrite {
        key = {
            tunnel_ttl      : exact;
            tunnel_label_num: exact;
        }
        actions = {
            rewrite_mpls_one_ttl;
            rewrite_mpls_two_ttl;
            rewrite_mpls_three_ttl;
            rewrite_mpls_four_ttl;
            rewrite_mpls_five_ttl;
            NoAction;
        }
        const default_action = NoAction;
    }
    action rewrite_mpls_one_exp() {
        hdr.mpls_eg[10 - 6].exp = tunnel.exp;
    }
    action rewrite_mpls_two_exp() {
        hdr.mpls_eg[10 - 6].exp = tunnel.exp;
        hdr.mpls_eg[10 - 7].exp = tunnel.exp;
    }
    action rewrite_mpls_three_exp() {
        hdr.mpls_eg[10 - 6].exp = tunnel.exp;
        hdr.mpls_eg[10 - 7].exp = tunnel.exp;
        hdr.mpls_eg[10 - 8].exp = tunnel.exp;
    }
    action rewrite_mpls_four_exp() {
        hdr.mpls_eg[10 - 6].exp = tunnel.exp;
        hdr.mpls_eg[10 - 7].exp = tunnel.exp;
        hdr.mpls_eg[10 - 8].exp = tunnel.exp;
        hdr.mpls_eg[10 - 9].exp = tunnel.exp;
    }
    action rewrite_mpls_five_exp() {
        hdr.mpls_eg[10 - 6].exp = tunnel.exp;
        hdr.mpls_eg[10 - 7].exp = tunnel.exp;
        hdr.mpls_eg[10 - 8].exp = tunnel.exp;
        hdr.mpls_eg[10 - 9].exp = tunnel.exp;
        hdr.mpls_eg[10 - 10].exp = tunnel.exp;
    }
    table mpls_tunnel2_exp_rewrite {
        key = {
            tunnel_exp_mode : exact;
            tunnel_label_num: exact;
        }
        actions = {
            rewrite_mpls_one_exp;
            rewrite_mpls_two_exp;
            rewrite_mpls_three_exp;
            rewrite_mpls_four_exp;
            rewrite_mpls_five_exp;
            NoAction;
        }
        const default_action = NoAction;
        size = 128;
    }
    apply {
        mpls_tunnel2_rewrite.apply();
        mpls_tunnel2_ttl_rewrite.apply();
        mpls_tunnel2_exp_rewrite.apply();
    }
}

control MPLS_encap(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, inout switch_egress_tunnel_metadata_t tunnel)(switch_uint32_t tunnel0_table_size=64 * 1024, switch_uint32_t tunnel1_table_size=64 * 1024) {
    PW_PTAG_XLATE() pw_ptag_xlate;
    MPLS_tunnel_0_encap(tunnel0_table_size) mpls_tunnel0_rewrite;
    MPLS_tunnel_1_encap(tunnel1_table_size) mpls_tunnel1_rewrite;
    apply {
        pw_ptag_xlate.apply(hdr, eg_md);
        mpls_tunnel0_rewrite.apply(hdr, eg_md, tunnel);
        mpls_tunnel1_rewrite.apply(hdr, eg_md, tunnel);
    }
}

control MPLS_encap2(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, inout switch_egress_tunnel_metadata_t tunnel)(switch_uint32_t tunnel2_table_size=16 * 1024) {
    MPLS_tunnel_2_encap(tunnel2_table_size) mpls_tunnel2_rewrite;
    apply {
        mpls_tunnel2_rewrite.apply(hdr, eg_md, tunnel);
    }
}

control MPLS_VC_encap(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(switch_uint32_t vc_table_size=64 * 1024) {
    bit<8> vc_ttl = 0;
    bit<3> vc_exp_mode = 0;
    action swap(bit<20> label, bit<3> exp, bit<8> ttl, bit<3> exp_mode) {
        hdr.mpls_vc_eg.label = label;
        hdr.mpls_vc_eg.exp = exp;
        hdr.mpls_vc_eg.ttl = ttl;
        vc_exp_mode = exp_mode;
        vc_ttl = ttl;
    }
    action swap_to_self(bit<3> exp, bit<8> ttl, bit<3> exp_mode) {
        hdr.mpls_vc_eg.exp = exp;
        hdr.mpls_vc_eg.ttl = ttl;
        vc_exp_mode = exp_mode;
        vc_ttl = ttl;
    }
    action push_vc_label(bit<20> label, bit<3> exp, bit<1> bos, bit<8> ttl) {
        hdr.mpls_vc_eg.setValid();
        hdr.mpls_vc_eg.label = label;
        hdr.mpls_vc_eg.exp = exp;
        hdr.mpls_vc_eg.bos = bos;
        hdr.mpls_vc_eg.ttl = ttl;
    }
    action push_vc(bit<20> label, bit<3> exp, bit<8> ttl, bit<3> exp_mode) {
        push_vc_label(label, exp, 1, ttl);
        vc_exp_mode = exp_mode;
        vc_ttl = ttl;
    }
    action set_l2vpn_properties(vlan_id_t p_vd, switch_ptag_action_t p_action, bit<16> p_tpd) {
        eg_md.tunnel.ptag_vid = p_vd;
        eg_md.tunnel.ptag_eg_action = p_action;
        eg_md.tunnel.ptag_tpid = p_tpd;
    }
    action push_l2(bit<20> label, bit<3> exp, bit<8> ttl, vlan_id_t p_vd, switch_ptag_action_t p_action, bit<16> p_tpd) {
        push_vc_label(label, exp, 1, ttl);
        set_l2vpn_properties(p_vd, p_action, p_tpd);
        vc_ttl = ttl;
    }
    @stage(4) table mpls_vc_rewrite {
        key = {
            eg_md.tunnel.l4_encap: exact;
        }
        actions = {
            swap;
            swap_to_self;
            push_vc;
            push_l2;
            NoAction;
        }
        const default_action = NoAction;
        size = vc_table_size;
    }
    action rewrite_mpls_ttl() {
        hdr.mpls_vc_eg.ttl = eg_md.tunnel.ttl;
    }
    table mpls_vc_ttl_rewrite {
        key = {
            vc_ttl: exact;
        }
        actions = {
            rewrite_mpls_ttl;
            NoAction;
        }
        const default_action = NoAction;
        size = 256;
    }
    action rewrite_mpls_exp() {
        hdr.mpls_vc_eg.exp = eg_md.tunnel.exp;
    }
    table mpls_vc_exp_rewrite {
        key = {
            vc_exp_mode: exact;
        }
        actions = {
            rewrite_mpls_exp;
            NoAction;
        }
        const default_action = NoAction;
        size = 8;
    }
    apply {
        if (eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_MPLS) {
            mpls_vc_rewrite.apply();
            mpls_vc_ttl_rewrite.apply();
            mpls_vc_exp_rewrite.apply();
        }
    }
}

control TunnelType(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t set_tunnel_type_size=32) {
    action set_tunnel_type(switch_tunnel_type_t tunnel_type) {
        ig_md.tunnel.type = tunnel_type;
        ig_md.flags.flowspec_disable = 1;
    }
    action miss() {
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_NONE;
    }
    table tunnel_type {
        key = {
            hdr.ipv4.isValid()           : exact;
            hdr.ipv6.isValid()           : exact;
            hdr.gre.isValid()            : exact;
            hdr.vxlan.isValid()          : exact;
            hdr.mpls_ig[0].isValid()     : exact;
            ig_md.tunnel.inner_pkt_parsed: exact;
        }
        actions = {
            miss;
            set_tunnel_type;
        }
        const default_action = miss;
        size = set_tunnel_type_size;
    }
    apply {
        tunnel_type.apply();
    }
}

control TunnelDecap(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t tunnel_decap_table_size=512) {
    action common_decap() {
        hdr.ethernet.setInvalid();
        hdr.vlan_tag[0].setInvalid();
    }
    action decap_l2vpn_tunnel() {
        common_decap();
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_ETH;
        ig_md.route.rmac_hit = false;
    }
    action decap_l3vpn_tunnel() {
        common_decap();
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_IP;
    }
    action decap_mpls_tunnel() {
        common_decap();
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_MPLS;
    }
    action decap_ip_tunnel() {
        common_decap();
        hdr.ipv4.setInvalid();
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_IP;
    }
    action decap_ip_gre_tunnel() {
        hdr.gre.setInvalid();
        decap_ip_tunnel();
    }
    action decap_vxlan_tunnel() {
        ig_md.route.rmac_hit = false;
        hdr.vxlan.setInvalid();
        hdr.udp.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        common_decap();
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_ETH;
    }
    action remove_srh_header() {
        hdr.srv6_srh.setInvalid();
        hdr.srv6_list[0].setInvalid();
        hdr.srv6_list[1].setInvalid();
        hdr.srv6_list[2].setInvalid();
        hdr.srv6_list[3].setInvalid();
        hdr.srv6_list[4].setInvalid();
        hdr.srv6_list[5].setInvalid();
        hdr.srv6_list[6].setInvalid();
        hdr.srv6_list[7].setInvalid();
        hdr.srv6_list[8].setInvalid();
        hdr.srv6_list[9].setInvalid();
    }
    action decap_srv6_inner_unknown() {
        common_decap();
        hdr.ipv6.setInvalid();
        remove_srh_header();
    }
    action decap_srh() {
        common_decap();
        remove_srh_header();
    }
    action decap_srv6_inner_ethernet() {
        common_decap();
        hdr.ipv6.setInvalid();
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_ETH;
        remove_srh_header();
    }
    action decap_srv6_inner_ip() {
        common_decap();
        hdr.ipv6.setInvalid();
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_IP;
        remove_srh_header();
    }
    table tunnel_decap {
        key = {
            hdr.srv6_srh.next_hdr        : ternary;
            hdr.ipv6.next_hdr            : ternary;
            ig_md.srv6.srh_terminate     : ternary;
            ig_md.tunnel.terminate       : ternary;
            ig_md.tunnel.type            : ternary;
            ig_md.tunnel.inner_pkt_parsed: ternary;
            ig_md.tunnel.mpls_enable     : ternary;
        }
        actions = {
            NoAction;
            decap_ip_tunnel;
            decap_ip_gre_tunnel;
            decap_vxlan_tunnel;
            decap_mpls_tunnel;
            decap_l2vpn_tunnel;
            decap_l3vpn_tunnel;
            decap_srv6_inner_unknown;
            decap_srh;
            decap_srv6_inner_ethernet;
            decap_srv6_inner_ip;
        }
        size = tunnel_decap_table_size;
    }
    apply {
        if (ig_md.route.rmac_hit == true) {
            if (ig_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
                tunnel_decap.apply();
            }
        }
    }
}

control TunnelEncap(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md) {
    bit<16> payload_len = 0;
    bit<8> ip_proto = 0;
    bit<16> gre_ether_type = 0;
    action add_ipv4_header() {
        hdr.ipv4.setValid();
        hdr.ipv4.version = 4w4;
        hdr.ipv4.ihl = 4w5;
        hdr.ipv4.identification = 0;
        hdr.ipv4.frag_offset = 0;
        hdr.ipv4.diffserv = 0;
    }
    action add_ipv6_header() {
        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w6;
        hdr.ipv6.traffic_class = 0;
        hdr.ipv6.flow_label[19:16] = 4w0;
        hdr.ipv6.flow_label[15:0] = eg_md.common.hash;
    }
    action add_gre_header(bit<16> proto) {
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
    action add_udp_header(bit<16> src_port, bit<16> dst_port) {
        hdr.udp.setValid();
        hdr.udp.src_port = src_port;
        hdr.udp.dst_port = dst_port;
        hdr.udp.checksum = 0;
    }
    action add_vxlan_header(bit<24> vni) {
        hdr.vxlan.setValid();
        hdr.vxlan.flags = 8w0x8;
        hdr.vxlan.vni = vni;
    }
    action encap_outer_ip() {
        add_ipv4_header();
        hdr.ipv4.protocol = ip_proto;
        hdr.ipv4.flags = 0;
        hdr.ipv4.total_len = payload_len + 16w20;
        eg_md.common.pkt_type = FABRIC_PKT_TYPE_IPV4;
    }
    action encap_outer_mpls() {
        eg_md.tunnel.next_hdr_type = SWITCH_TUNNEL_NEXT_HDR_TYPE_MPLS;
    }
    action encap_outer_ip_gre() {
        add_ipv4_header();
        hdr.ipv4.flags = 0;
        hdr.ipv4.protocol = 47;
        hdr.ipv4.total_len = payload_len + 16w24;
        add_gre_header(gre_ether_type);
        eg_md.common.pkt_type = FABRIC_PKT_TYPE_IPV4;
    }
    action encap_outer_srv6() {
        add_ipv6_header();
        hdr.ipv6.payload_len = payload_len + 16w40;
        hdr.ipv6.next_hdr = ip_proto;
        eg_md.common.pkt_type = FABRIC_PKT_TYPE_IPV6;
    }
    action copy_ipv6_header() {
        hdr.ipv6.setValid();
        hdr.ipv6.version = hdr.inner_ipv6.version;
        hdr.ipv6.flow_label = hdr.inner_ipv6.flow_label;
        hdr.ipv6.payload_len = hdr.inner_ipv6.payload_len;
        hdr.ipv6.next_hdr = hdr.inner_ipv6.next_hdr;
        hdr.ipv6.src_addr = hdr.inner_ipv6.src_addr;
        hdr.ipv6.hop_limit = hdr.inner_ipv6.hop_limit;
        hdr.ipv6.traffic_class = hdr.inner_ipv6.traffic_class;
        hdr.inner_ipv6.setInvalid();
    }
    action insert_outer_srv6() {
        copy_ipv6_header();
    }
    action encap_outer_ipv4_vxlan(bit<16> dst_port) {
        add_ipv4_header();
        hdr.ipv4.flags = 2;
        hdr.ipv4.protocol = 17;
        hdr.ipv4.total_len = payload_len + 16w50;
        add_udp_header(eg_md.common.hash, dst_port);
        hdr.udp.length = payload_len + 16w30;
        add_vxlan_header(eg_md.tunnel.vni);
        eg_md.common.pkt_type = FABRIC_PKT_TYPE_IPV4;
        eg_md.tunnel.next_hdr_type = SWITCH_TUNNEL_NEXT_HDR_TYPE_IPV4;
        hdr.inner_vlan_tag[0].setInvalid();
    }
    action encap_outer_ipv6_vxlan(bit<16> dst_port) {
        add_ipv6_header();
        hdr.ipv6.payload_len = payload_len + 16w30;
        hdr.ipv6.next_hdr = 17;
        add_udp_header(eg_md.common.hash, dst_port);
        hdr.udp.length = payload_len + 16w30;
        add_vxlan_header(eg_md.tunnel.vni);
        eg_md.common.pkt_type = FABRIC_PKT_TYPE_IPV6;
        eg_md.tunnel.next_hdr_type = SWITCH_TUNNEL_NEXT_HDR_TYPE_IPV6;
        hdr.inner_vlan_tag[0].setInvalid();
    }
    table encap_outer {
        key = {
            eg_md.tunnel.encap_type: exact;
        }
        actions = {
            NoAction;
            encap_outer_ip;
            encap_outer_mpls;
            encap_outer_ip_gre;
            encap_outer_ipv4_vxlan;
            encap_outer_ipv6_vxlan;
        }
        const default_action = NoAction;
        size = 16;
    }
    action get_ipv4_ttl() {
        eg_md.tunnel.ttl = hdr.inner_ipv4.ttl;
        eg_md.tunnel.inner_dscp = hdr.inner_ipv4.diffserv[7:2];
        ip_proto = 4;
        gre_ether_type = 0x800;
        payload_len = hdr.inner_ipv4.total_len;
    }
    action get_ipv6_ttl() {
        eg_md.tunnel.ttl = hdr.inner_ipv6.hop_limit;
        eg_md.tunnel.inner_dscp = hdr.inner_ipv6.traffic_class[7:2];
        ip_proto = 41;
        gre_ether_type = 0x86dd;
        payload_len = hdr.inner_ipv6.payload_len + 16w40;
    }
    action get_mpls_ttl() {
        eg_md.tunnel.ttl = hdr.mpls_vc_eg.ttl;
    }
    table get_inner_info {
        key = {
            hdr.mpls_vc_eg.isValid(): exact;
            hdr.inner_ipv4.isValid(): exact;
            hdr.inner_ipv6.isValid(): exact;
        }
        actions = {
            NoAction;
            get_ipv4_ttl;
            get_ipv6_ttl;
            get_mpls_ttl;
        }
        const default_action = NoAction;
        size = 8;
    }
    apply {
        if (eg_md.tunnel.encap_type != SWITCH_TUNNEL_ENCAP_TYPE_NONE) {
            get_inner_info.apply();
            encap_outer.apply();
        }
    }
}

control L3EncapMapping(inout switch_egress_metadata_t eg_md) {
    const switch_uint32_t l3_encap_mapping_size = 65536;
    action l3_encap_id_mapping(bit<16> l3_encap_id, switch_tunnel_encap_type_t type, bit<16> encap_length) {
        eg_md.route.local_l3_encap_id = l3_encap_id;
        eg_md.tunnel.encap_type = type;
        eg_md.common.pkt_length = eg_md.common.pkt_length + encap_length;
        eg_md.tunnel.l3_encap_mapping_hit = 1;
    }
    table l3_encap_mapping {
        key = {
            eg_md.common.l3_encap: exact;
        }
        actions = {
            NoAction;
            l3_encap_id_mapping;
        }
        size = l3_encap_mapping_size;
    }
    apply {
        l3_encap_mapping.apply();
    }
}

control L4EncapMapping(inout switch_egress_metadata_t eg_md) {
    const switch_uint32_t l4_encap_mapping_size = 65536;
    action l4_encap_id_mapping(switch_tunnel_encap_type_t type, bit<16> encap_length) {
        eg_md.tunnel.encap_type = type;
        eg_md.common.pkt_length = eg_md.common.pkt_length + encap_length;
    }
    table l4_encap_mapping {
        key = {
            eg_md.tunnel.l4_encap: exact;
        }
        actions = {
            NoAction;
            l4_encap_id_mapping;
        }
        size = l4_encap_mapping_size;
    }
    apply {
        l4_encap_mapping.apply();
    }
}

control IntfIpfix_FrontIg(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md) {
    action sample_to_cpu(switch_ipfix_flow_id_t flow_id, switch_ipfix_mode_t mode, switch_ipfix_gap_t sample_gap, switch_ipfix_random_mask_t random_mask, switch_ipfix_session_t session_id) {
        ig_md.ipfix.enable = true;
        ig_md.ipfix.flow_id = flow_id;
        ig_md.ipfix.mode = mode;
        ig_md.ipfix.sample_gap = sample_gap;
        ig_md.ipfix.random_mask = random_mask;
        ig_md.ipfix.session_id = session_id;
    }
    table ig_intf_to_ipfix_flow {
        key = {
            ig_intr_md.ingress_port: exact;
            ig_md.ipfix.pkt_type   : exact;
        }
        actions = {
            sample_to_cpu;
        }
        size = 256;
    }
    apply {
        ig_intf_to_ipfix_flow.apply();
    }
}

control IntfIpfix_FrontEg(inout switch_header_t hdr, in egress_intrinsic_metadata_t eg_intr_md, inout switch_egress_metadata_t eg_md) {
    action sample_to_cpu(switch_ipfix_flow_id_t flow_id, switch_ipfix_mode_t mode, switch_ipfix_gap_t sample_gap, switch_ipfix_random_mask_t random_mask, switch_ipfix_session_t session_id) {
        eg_md.ipfix.enable = true;
        eg_md.ipfix.flow_id = flow_id;
        eg_md.ipfix.mode = mode;
        eg_md.ipfix.sample_gap = sample_gap;
        eg_md.ipfix.random_mask = random_mask;
        eg_md.ipfix.session_id = session_id;
    }
    table eg_intf_to_ipfix_flow {
        key = {
            eg_intr_md.egress_port: exact;
            eg_md.common.pkt_type : exact;
        }
        actions = {
            sample_to_cpu;
        }
        size = 256;
    }
    apply {
        if (eg_md.ipfix.enable == false) {
            eg_intf_to_ipfix_flow.apply();
        }
    }
}

control SampleToCPU_FrontIg(inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    action set_sample_mode_random() {
        ig_md.ipfix.random_num = ig_md.ipfix.random_num & ig_md.ipfix.random_mask;
    }
    action set_sample_mode_fixed() {
        ig_md.ipfix.random_num = ig_md.ipfix.sample_gap;
    }
    table ipfix_sample_mode {
        key = {
            ig_md.ipfix.mode: exact;
        }
        actions = {
            set_sample_mode_random;
            set_sample_mode_fixed;
        }
        default_action = set_sample_mode_random;
        const entries = {
                        0 : set_sample_mode_random();
                        1 : set_sample_mode_fixed();
        }

    }
    action set_delta() {
        ig_md.ipfix.delta = ig_md.ipfix.random_num |-| ig_md.ipfix.sample_gap;
    }
    action modify_invalid_random() {
        ig_md.ipfix.random_num = 1;
        ig_md.ipfix.delta = 0;
    }
    table ipfix_modify_random {
        key = {
            ig_md.ipfix.random_num: exact;
        }
        actions = {
            set_delta;
            modify_invalid_random;
        }
        size = 32;
        default_action = set_delta();
        const entries = {
                        0 : modify_invalid_random();
        }

    }
    const bit<32> ipfix_size = 256;
    Register<switch_ipfix_t, bit<16>>(ipfix_size, 0) sample_count_reg;
    RegisterAction<switch_ipfix_t, bit<16>, switch_ipfix_t>(sample_count_reg) cal_count = {
        void apply(inout switch_ipfix_t reg, out switch_ipfix_t count) {
            if (reg < ig_md.ipfix.sample_gap) {
                reg = reg + 1;
                count = reg;
            } else {
                reg = 1;
                count = reg;
            }
        }
    };
    action set_packet_count() {
        ig_md.ipfix.count = cal_count.execute(ig_md.ipfix.flow_id);
    }
    table ipfix_packet_count {
        key = {
            ig_md.ipfix.enable: exact;
        }
        actions = {
            set_packet_count;
        }
        const entries = {
                        true : set_packet_count();
        }

    }
    action set_random_flag() {
        ig_md.ipfix.random_flag = 1;
    }
    action reset_random_flag() {
        ig_md.ipfix.random_flag = 0;
    }
    table ipfix_set_random_flag {
        key = {
            ig_md.ipfix.count: exact;
        }
        actions = {
            set_random_flag;
            reset_random_flag;
        }
        default_action = reset_random_flag;
        const entries = {
                        1 : set_random_flag();
        }

    }
    Register<switch_ipfix_t, bit<16>>(ipfix_size) check_sample_flag_reg;
    RegisterAction<switch_ipfix_t, bit<16>, bit<16>>(check_sample_flag_reg) set_random = {
        void apply(inout switch_ipfix_t reg, out bit<16> flag) {
            reg = ig_md.ipfix.random_num;
            if (reg == 1) {
                flag = 1;
            } else {
                flag = 0;
            }
        }
    };
    RegisterAction<switch_ipfix_t, bit<16>, bit<16>>(check_sample_flag_reg) compare_random = {
        void apply(inout switch_ipfix_t reg, out bit<16> flag) {
            if (reg == ig_md.ipfix.count) {
                flag = 1;
            } else {
                flag = 0;
            }
        }
    };
    action set_random_num() {
        ig_md.ipfix.sample_flag = set_random.execute(ig_md.ipfix.flow_id);
    }
    action set_flag() {
        ig_md.ipfix.sample_flag = compare_random.execute(ig_md.ipfix.flow_id);
    }
    table ipfix_set_sample_flag {
        key = {
            ig_md.ipfix.random_flag: exact;
        }
        actions = {
            set_random_num;
            set_flag;
        }
        size = 32;
        const entries = {
                        1 : set_random_num();
                        0 : set_flag();
        }

    }
    action calc_random_num() {
        ig_md.ipfix.random_num = ig_md.ipfix.delta;
    }
    table ipfix_random_calc {
        key = {
            ig_md.ipfix.delta: ternary;
        }
        actions = {
            calc_random_num;
            NoAction;
        }
    }
    apply {
        ipfix_sample_mode.apply();
        ipfix_modify_random.apply();
        if (ig_md.ipfix.delta > 0) {
            ig_md.ipfix.random_num = ig_md.ipfix.delta;
        }
        ipfix_packet_count.apply();
        ipfix_set_random_flag.apply();
        ipfix_set_sample_flag.apply();
    }
}

control SampleToCPU_FrontEg(inout switch_egress_metadata_t eg_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    action set_sample_mode_random() {
        eg_md.ipfix.random_num = eg_md.ipfix.random_num & eg_md.ipfix.random_mask;
    }
    action set_sample_mode_fixed() {
        eg_md.ipfix.random_num = eg_md.ipfix.sample_gap;
    }
    table ipfix_sample_mode {
        key = {
            eg_md.ipfix.mode: exact;
        }
        actions = {
            set_sample_mode_random;
            set_sample_mode_fixed;
        }
        default_action = set_sample_mode_random;
        const entries = {
                        0 : set_sample_mode_random();
                        1 : set_sample_mode_fixed();
        }

    }
    action set_delta() {
        eg_md.ipfix.delta = eg_md.ipfix.random_num |-| eg_md.ipfix.sample_gap;
    }
    action modify_invalid_random() {
        eg_md.ipfix.random_num = 1;
        eg_md.ipfix.delta = 0;
    }
    table ipfix_modify_random {
        key = {
            eg_md.ipfix.random_num: exact;
        }
        actions = {
            set_delta;
            modify_invalid_random;
        }
        size = 1024;
        default_action = set_delta();
        const entries = {
                        0 : modify_invalid_random();
        }

    }
    const bit<32> ipfix_size = 256;
    Register<switch_ipfix_t, bit<16>>(ipfix_size, 0) sample_count_reg;
    RegisterAction<switch_ipfix_t, bit<16>, switch_ipfix_t>(sample_count_reg) cal_count = {
        void apply(inout switch_ipfix_t reg, out switch_ipfix_t count) {
            if (reg < eg_md.ipfix.sample_gap) {
                reg = reg + 1;
                count = reg;
            } else {
                reg = 1;
                count = reg;
            }
        }
    };
    action set_packet_count() {
        eg_md.ipfix.count = cal_count.execute(eg_md.ipfix.flow_id);
    }
    table ipfix_packet_count {
        key = {
            eg_md.ipfix.enable: exact;
        }
        actions = {
            set_packet_count;
        }
        const entries = {
                        true : set_packet_count();
        }

    }
    action set_random_flag() {
        eg_md.ipfix.random_flag = 1;
    }
    action reset_random_flag() {
        eg_md.ipfix.random_flag = 0;
    }
    table ipfix_set_random_flag {
        key = {
            eg_md.ipfix.count: exact;
        }
        actions = {
            set_random_flag;
            reset_random_flag;
        }
        default_action = reset_random_flag;
        const entries = {
                        1 : set_random_flag();
        }

    }
    Register<switch_ipfix_t, bit<16>>(ipfix_size) check_sample_flag_reg;
    RegisterAction<switch_ipfix_t, bit<16>, bit<16>>(check_sample_flag_reg) set_random = {
        void apply(inout switch_ipfix_t reg, out bit<16> flag) {
            reg = eg_md.ipfix.random_num;
            if (reg == 1) {
                flag = 1;
            } else {
                flag = 0;
            }
        }
    };
    RegisterAction<switch_ipfix_t, bit<16>, bit<16>>(check_sample_flag_reg) compare_random = {
        void apply(inout switch_ipfix_t reg, out bit<16> flag) {
            if (reg == eg_md.ipfix.count) {
                flag = 1;
            } else {
                flag = 0;
            }
        }
    };
    action set_random_num() {
        eg_md.ipfix.sample_flag = set_random.execute(eg_md.ipfix.flow_id);
    }
    action set_flag() {
        eg_md.ipfix.sample_flag = compare_random.execute(eg_md.ipfix.flow_id);
    }
    table ipfix_set_sample_flag {
        key = {
            eg_md.ipfix.random_flag: exact;
        }
        actions = {
            set_random_num;
            set_flag;
        }
        size = 32;
        const entries = {
                        1 : set_random_num();
                        0 : set_flag();
        }

    }
    apply {
        ipfix_sample_mode.apply();
        ipfix_modify_random.apply();
        if (eg_md.ipfix.delta > 0) {
            eg_md.ipfix.random_num = eg_md.ipfix.delta;
        }
        ipfix_packet_count.apply();
        ipfix_set_random_flag.apply();
        ipfix_set_sample_flag.apply();
    }
}

control SetMirrorParam_FrontIg(inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    action set_ipfix_mirror_sess() {
        ig_md.mirror.type = 6;
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        ig_md.mirror.session_id = ig_md.ipfix.session_id;
        ig_intr_md_for_dprsr.mirror_type = (bit<3>)6;
    }
    @ignore_table_dependency("Ig_front.ipv6_acl1.acl") @ignore_table_dependency("Ig_front.ipv6_acl2.acl") @ignore_table_dependency("Ig_front.ipv6_acl3.acl") @ignore_table_dependency("Ig_front.ipv4_acl1.acl") @ignore_table_dependency("Ig_front.ipv4_acl2.acl") table ipfix_set_mirror_session {
        key = {
            ig_md.ipfix.sample_flag: exact;
        }
        actions = {
            set_ipfix_mirror_sess;
        }
        size = 32;
        const entries = {
                        1 : set_ipfix_mirror_sess();
        }

    }
    apply {
        ipfix_set_mirror_session.apply();
    }
}

control SetMirrorParam_FrontEg(inout switch_egress_metadata_t eg_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    action set_ipfix_mirror_sess() {
        eg_md.mirror.type = 6;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.mirror.session_id = eg_md.ipfix.session_id;
        eg_intr_md_for_dprsr.mirror_type = (bit<3>)6;
    }
    table ipfix_set_mirror_session {
        key = {
            eg_md.ipfix.sample_flag: exact;
        }
        actions = {
            set_ipfix_mirror_sess;
        }
        size = 32;
        const entries = {
                        1 : set_ipfix_mirror_sess();
        }

    }
    apply {
        ipfix_set_mirror_session.apply();
    }
}

control EncapIPFIX(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, in bit<16> hash) {
    action encap_ig_ipfix_cpu_header() {
        hdr.fabric_eth_base_to_cpu.setValid();
        hdr.fabric_eth_base_to_cpu.pkt_type = CPU_ETH_PKT_TYPE_IPFIX;
        hdr.fabric_eth_base_to_cpu.dir = 0;
        hdr.fabric_eth_base_to_cpu.hash = hash;
        hdr.fabric_ipfix_to_cpu.setValid();
        hdr.fabric_ipfix_to_cpu.iif = eg_md.common.iif;
        hdr.fabric_ipfix_to_cpu.oif = eg_md.common.oif;
        hdr.fabric_ipfix_to_cpu.ul_iif = eg_md.common.ul_iif;
        hdr.fabric_eth_etype.setValid();
        hdr.fabric_eth_etype.ether_type = hdr.ethernet.ether_type;
        hdr.ethernet.ether_type = 0x9000;
        eg_md.mirror.type = 0;
        eg_md.mirror.session_id = 0;
    }
    action encap_eg_ipfix_cpu_header() {
        hdr.fabric_eth_base_to_cpu.setValid();
        hdr.fabric_eth_base_to_cpu.pkt_type = CPU_ETH_PKT_TYPE_IPFIX;
        hdr.fabric_eth_base_to_cpu.dir = 1;
        hdr.fabric_eth_base_to_cpu.hash = hash;
        hdr.fabric_ipfix_to_cpu.setValid();
        hdr.fabric_ipfix_to_cpu.iif = eg_md.common.iif;
        hdr.fabric_ipfix_to_cpu.oif = eg_md.common.oif;
        hdr.fabric_ipfix_to_cpu.ul_iif = eg_md.common.ul_iif;
        hdr.fabric_eth_etype.setValid();
        hdr.fabric_eth_etype.ether_type = hdr.ethernet.ether_type;
        hdr.ethernet.ether_type = 0x9000;
        eg_md.mirror.type = 0;
        eg_md.mirror.session_id = 0;
    }
    table encap_ipfix_cpu {
        key = {
            eg_md.mirror.type: exact;
            eg_md.mirror.src : exact;
        }
        actions = {
            encap_ig_ipfix_cpu_header;
            encap_eg_ipfix_cpu_header;
            NoAction;
        }
        default_action = NoAction;
        size = 32;
        const entries = {
                        (6, SWITCH_PKT_SRC_CLONED_INGRESS) : encap_ig_ipfix_cpu_header();
                        (6, SWITCH_PKT_SRC_CLONED_EGRESS) : encap_eg_ipfix_cpu_header();
        }

    }
    apply {
        encap_ipfix_cpu.apply();
    }
}

control EncapBfd(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, in bit<16> hash) {
    action encap_cpu_header_for_ipv4(bit<48> dst_addr, bit<48> src_addr) {
        hdr.fabric_eth_base_to_cpu.setValid();
        hdr.fabric_eth_base_to_cpu.pkt_type = CPU_ETH_PKT_TYPE_BFD;
        hdr.fabric_eth_base_to_cpu.hash = hash;
        hdr.fabric_bfd_to_cpu.setValid();
        hdr.fabric_bfd_to_cpu.iif = eg_md.common.iif;
        hdr.fabric_bfd_to_cpu.src_port = eg_md.common.src_port;
        hdr.fabric_eth_etype.setValid();
        hdr.fabric_eth_etype.ether_type = 0x800;
        hdr.ethernet.ether_type = 0x9000;
        hdr.ethernet.dst_addr = dst_addr;
        hdr.ethernet.src_addr = src_addr;
    }
    action encap_cpu_header_for_ipv6(bit<48> dst_addr, bit<48> src_addr) {
        hdr.fabric_eth_base_to_cpu.setValid();
        hdr.fabric_eth_base_to_cpu.pkt_type = CPU_ETH_PKT_TYPE_BFD;
        hdr.fabric_eth_base_to_cpu.hash = hash;
        hdr.fabric_bfd_to_cpu.setValid();
        hdr.fabric_bfd_to_cpu.iif = eg_md.common.iif;
        hdr.fabric_bfd_to_cpu.src_port = eg_md.common.src_port;
        hdr.fabric_eth_etype.setValid();
        hdr.fabric_eth_etype.ether_type = 0x86dd;
        hdr.ethernet.ether_type = 0x9000;
        hdr.ethernet.dst_addr = dst_addr;
        hdr.ethernet.src_addr = src_addr;
    }
    action encap_cpu_header_for_mpls(bit<48> dst_addr, bit<48> src_addr) {
        hdr.fabric_eth_base_to_cpu.setValid();
        hdr.fabric_eth_base_to_cpu.pkt_type = CPU_ETH_PKT_TYPE_BFD;
        hdr.fabric_eth_base_to_cpu.hash = hash;
        hdr.fabric_bfd_to_cpu.setValid();
        hdr.fabric_bfd_to_cpu.iif = eg_md.common.iif;
        hdr.fabric_bfd_to_cpu.src_port = eg_md.common.src_port;
        hdr.fabric_eth_etype.setValid();
        hdr.fabric_eth_etype.ether_type = 0x8847;
        hdr.ethernet.ether_type = 0x9000;
        hdr.ethernet.dst_addr = dst_addr;
        hdr.ethernet.src_addr = src_addr;
    }
    table encap_bfd_cpu {
        key = {
            hdr.bridged_md_310.isValid(): exact;
            eg_md.common.pkt_type       : exact;
        }
        actions = {
            encap_cpu_header_for_ipv4;
            encap_cpu_header_for_ipv6;
            encap_cpu_header_for_mpls;
            NoAction;
        }
        default_action = NoAction;
        size = 32;
        const entries = {
                        (true, FABRIC_PKT_TYPE_IPV4) : encap_cpu_header_for_ipv4(0x2222222200, 0x1122334455);
                        (true, FABRIC_PKT_TYPE_IPV6) : encap_cpu_header_for_ipv6(0x2222222200, 0x1122334455);
                        (true, FABRIC_PKT_TYPE_MPLS) : encap_cpu_header_for_mpls(0x2222222200, 0x1122334455);
        }

    }
    apply {
        encap_bfd_cpu.apply();
    }
}

control L2EncapMapping(in switch_header_t hdr, inout switch_egress_metadata_t eg_md) {
    const switch_uint32_t l2_encap_size = 65536;
    action set_l3oif(switch_lif_t l3oif) {
        eg_md.common.oif = l3oif;
    }
    table l2_encap_to_l3oif {
        key = {
            eg_md.common.l2_encap: exact;
        }
        actions = {
            NoAction;
            set_l3oif;
        }
        const default_action = NoAction;
        size = l2_encap_size;
    }
    apply {
        l2_encap_to_l3oif.apply();
    }
}

control SetEtherType(in switch_header_t hdr, inout switch_ingress_metadata_t ig_md) {
    action set_ipv4_ethertype() {
        ig_md.common.ether_type = 0x800;
    }
    action set_ipv6_ethertype() {
        ig_md.common.ether_type = 0x86dd;
    }
    action set_mpls_ethertype() {
        ig_md.common.ether_type = 0x8847;
    }
    table set_ethertype {
        key = {
            hdr.fabric_base.pkt_type: exact;
        }
        actions = {
            set_ipv4_ethertype;
            set_ipv6_ethertype;
            set_mpls_ethertype;
        }
        const entries = {
                        FABRIC_PKT_TYPE_IPV4 : set_ipv4_ethertype();
                        FABRIC_PKT_TYPE_IPV6 : set_ipv6_ethertype();
                        FABRIC_PKT_TYPE_MPLS : set_mpls_ethertype();
        }

        size = 16;
    }
    apply {
        set_ethertype.apply();
    }
}

control LocalL2Encap(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md) {
    const switch_uint32_t l2_encap_size = 65536;
    const switch_uint32_t table_ptag_encap_size = 32;
    const switch_uint32_t rewrite_smac_size = 16384;
    action l2_encap_add_with_vlan(vlan_id_t vid) {
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].ether_type = ig_md.common.ether_type;
        hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].vid = vid;
        hdr.vlan_tag[0].pcp = ig_md.qos.pcp;
        hdr.ethernet.ether_type = 0x8100;
    }
    action l2_encap_add_ethernet_with_vlan(bit<48> dst_addr, vlan_id_t vid) {
        hdr.ethernet.setValid();
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].ether_type = ig_md.common.ether_type;
        hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].vid = vid;
        hdr.vlan_tag[0].pcp = ig_md.qos.pcp;
        hdr.ethernet.dst_addr = dst_addr;
        hdr.ethernet.ether_type = 0x8100;
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_ETH;
    }
    action l2_encap_add_ethernet_without_vlan(bit<48> dst_addr) {
        hdr.ethernet.setValid();
        hdr.ethernet.dst_addr = dst_addr;
        hdr.ethernet.ether_type = ig_md.common.ether_type;
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_ETH;
    }
    action l2_encap_get_ptag(switch_ptag_action_t p_action, vlan_id_t p_vd) {
        ig_md.tunnel.ptag_eg_action = p_action;
        ig_md.tunnel.ptag_vid = p_vd;
    }
    @stage(10) table l2_encap {
        key = {
            ig_md.common.l2_encap: exact;
        }
        actions = {
            NoAction;
            l2_encap_add_ethernet_with_vlan;
            l2_encap_add_ethernet_without_vlan;
            l2_encap_add_with_vlan;
            l2_encap_get_ptag;
        }
        const default_action = NoAction;
        size = l2_encap_size;
    }
    action add_p() {
        hdr.vlan_tag.push_front(1);
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].vid = ig_md.tunnel.ptag_vid;
        hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;
        hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].pcp = 0;
        hdr.ethernet.ether_type = ig_md.tunnel.ptag_tpid;
    }
    action modify_p() {
        hdr.vlan_tag[0].vid = ig_md.tunnel.ptag_vid;
        hdr.ethernet.ether_type = ig_md.tunnel.ptag_tpid;
    }
    action del_p() {
        hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
        hdr.vlan_tag.pop_front(1);
    }
    table ac_ptag_xlate {
        key = {
            hdr.vlan_tag[0].isValid()  : exact;
            ig_md.tunnel.ptag_igmod    : exact;
            ig_md.tunnel.ptag_eg_action: exact;
        }
        actions = {
            add_p;
            modify_p;
            del_p;
            NoAction;
        }
        default_action = NoAction;
        size = table_ptag_encap_size;
        const entries = {
                        (true, 0, VLANTAG_RAW_MODE) : NoAction();
                        (true, 0, VLANTAG_REPLACE_IF_PRESENT) : add_p();
                        (true, 0, VLANTAG_NOREPLACE_IF_PRESENT) : add_p();
                        (false, 0, VLANTAG_RAW_MODE) : NoAction();
                        (false, 0, VLANTAG_REPLACE_IF_PRESENT) : add_p();
                        (false, 0, VLANTAG_NOREPLACE_IF_PRESENT) : add_p();
                        (true, 1, VLANTAG_RAW_MODE) : del_p();
                        (true, 1, VLANTAG_REPLACE_IF_PRESENT) : modify_p();
                        (true, 1, VLANTAG_NOREPLACE_IF_PRESENT) : NoAction();
        }

    }
    action rewrite_smac_act(bit<48> src_addr) {
        hdr.ethernet.src_addr = src_addr;
    }
    table rewrite_smac {
        key = {
            ig_md.common.oif: exact;
        }
        actions = {
            NoAction;
            rewrite_smac_act;
        }
        const default_action = NoAction;
        size = rewrite_smac_size;
    }
    apply {
        switch (l2_encap.apply().action_run) {
            l2_encap_get_ptag: {
                ac_ptag_xlate.apply();
            }
        }

        rewrite_smac.apply();
    }
}

control RidAttribute(in egress_intrinsic_metadata_t eg_intr_md, inout switch_egress_metadata_t eg_md)(switch_uint32_t rid_attribute_size=65536) {
    action set_l3mc_rid_properties(bit<16> l2_encap, switch_eport_t egress_eport) {
        eg_md.common.l2_encap = l2_encap;
        eg_md.common.egress_eport = egress_eport;
    }
    action set_l2flood_rid_properties(bit<16> l4_encap, bit<16> l3_encap, bit<16> l2_encap, switch_lif_t l2oif, switch_eport_t egress_eport) {
        eg_md.tunnel.l4_encap = l4_encap;
        eg_md.common.l3_encap = l3_encap;
        eg_md.common.l2_encap = l2_encap;
        eg_md.common.oif = l2oif;
        eg_md.common.egress_eport = egress_eport;
    }
    table rid_attribute {
        key = {
            eg_intr_md.egress_rid: exact;
        }
        actions = {
            set_l3mc_rid_properties;
            set_l2flood_rid_properties;
            NoAction;
        }
        const default_action = NoAction;
        size = rid_attribute_size;
    }
    apply {
        if (eg_md.common.is_mcast == 1) {
            rid_attribute.apply();
        }
    }
}

control mgid_copy_to_tm(inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm, inout switch_ingress_metadata_t ig_md) {
    action mgid_copy_tm() {
        ig_intr_md_for_tm.mcast_grp_b = ig_md.multicast.id;
        ig_intr_md_for_tm.level1_exclusion_id = (bit<16>)ig_md.common.iif;
        ig_intr_md_for_tm.level2_mcast_hash = ig_md.common.hash[12:0];
    }
    table mgid_copy {
        actions = {
            mgid_copy_tm;
        }
        const default_action = mgid_copy_tm;
    }
    apply {
        mgid_copy.apply();
    }
}

control McEnable(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md) {
    action enable_act() {
        eg_md.common.is_mcast = 1;
    }
    action disable_act() {
        eg_md.common.is_mcast = 0;
    }
    table Mc_enable {
        key = {
            eg_md.multicast.ipv6.multicast_enable: exact;
            eg_md.multicast.ipv4.multicast_enable: exact;
            hdr.ipv4.isValid()                   : exact;
            hdr.ipv6.isValid()                   : exact;
        }
        actions = {
            NoAction;
            enable_act;
            disable_act;
        }
        const entries = {
                        (true, true, true, false) : enable_act();
                        (true, false, true, false) : enable_act();
                        (false, true, true, false) : disable_act();
                        (false, false, true, false) : disable_act();
                        (true, true, false, true) : enable_act();
                        (true, false, false, true) : disable_act();
                        (false, true, false, true) : enable_act();
                        (false, false, false, true) : disable_act();
        }

    }
    apply {
        if (eg_md.lkp.pkt_type == FABRIC_PKT_TYPE_MCAST) {
            Mc_enable.apply();
        }
    }
}

action fabric_base_decap(in switch_header_t hdr, inout switch_ingress_metadata_t ig_md) {
    ig_md.common.is_mirror = hdr.fabric_base.mirror;
    ig_md.common.is_mcast = hdr.fabric_base.mcast;
}
action fabric_qos_decap(in switch_header_t hdr, inout switch_ingress_metadata_t ig_md) {
    ig_md.qos.tc = hdr.fabric_qos.tc;
    ig_md.qos.color = hdr.fabric_qos.color;
    ig_md.qos.chgDSCP_disable = hdr.fabric_qos.chgDSCP_disable;
    ig_md.qos.BA = hdr.fabric_qos.BA;
}
control IngressFabric_uplink(inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout switch_header_t hdr) {
    action terminate_unicast() {
        fabric_base_decap(hdr, ig_md);
        fabric_qos_decap(hdr, ig_md);
        ig_md.flags.glean = hdr.fabric_unicast_ext_igfpga_bfn.glean;
        ig_md.flags.drop = hdr.fabric_unicast_ext_igfpga_bfn.drop;
        ig_md.flags.is_pbr_nhop = hdr.fabric_unicast_ext_igfpga_bfn.is_pbr_nhop;
        ig_md.flags.flowspec_disable = hdr.fabric_unicast_ext_igfpga_bfn.flowspec_disable;
        ig_md.common.src_port = hdr.fabric_unicast_ext_igfpga_bfn.src_port;
        ig_md.common.cpu_reason = hdr.fabric_unicast_ext_igfpga_bfn.cpu_reason;
        ig_md.common.ul_nhid = hdr.fabric_unicast_ext_igfpga_bfn.ul_nhid;
        ig_md.common.ol_nhid = hdr.fabric_unicast_ext_igfpga_bfn.ol_nhid;
        ig_md.common.iif = hdr.fabric_one_pad.iif;
    }
    action terminate_unicast_eth() {
        terminate_unicast();
        ig_md.ebridge.evlan = hdr.fabric_var_ext_1_16bit.data;
        ig_md.flags.learning = hdr.fabric_post_one_pad.l2_flag;
        ig_md.ebridge.l2oif = hdr.fabric_post_one_pad.l2oif;
    }
    action terminate_unicast_ip() {
        terminate_unicast();
        ig_md.route.dip_l3class_id = hdr.fabric_var_ext_2_8bit.data_hi;
        ig_md.route.sip_l3class_id = hdr.fabric_var_ext_2_8bit.data_lo;
    }
    action terminate_unicast_ipv4() {
        terminate_unicast_ip();
    }
    action terminate_unicast_ipv6() {
        terminate_unicast_ip();
    }
    action terminate_unicast_mpls() {
        terminate_unicast();
        ig_md.tunnel.label_space = hdr.fabric_var_ext_2_8bit.data_hi;
    }
    action terminate_multicast() {
        fabric_base_decap(hdr, ig_md);
        fabric_qos_decap(hdr, ig_md);
        ig_md.flags.learning = hdr.fabric_multicast_ext.learning;
        ig_md.common.iif = hdr.fabric_one_pad.iif;
    }
    table fabric_ingress_decap {
        key = {
            hdr.fabric_base.pkt_type: exact;
        }
        actions = {
            NoAction;
            terminate_unicast_eth;
            terminate_unicast_ipv4;
            terminate_unicast_ipv6;
            terminate_unicast_mpls;
        }
        const default_action = NoAction;
        size = 128;
        const entries = {
                        FABRIC_PKT_TYPE_ETH : terminate_unicast_eth();
                        FABRIC_PKT_TYPE_IPV4 : terminate_unicast_ipv4();
                        FABRIC_PKT_TYPE_IPV6 : terminate_unicast_ipv6();
                        FABRIC_PKT_TYPE_MPLS : terminate_unicast_mpls();
        }

    }
    apply {
        if (hdr.ext_tunnel_decap.isValid()) {
            ig_md.common.extend = 1w1;
        }
        if (hdr.fabric_base.mcast == 1w0) {
            fabric_ingress_decap.apply();
        } else {
            terminate_multicast();
        }
    }
}

control IngressFabric_uplink_fabric(inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout switch_header_t hdr) {
    action terminate_unicast() {
        fabric_base_decap(hdr, ig_md);
        fabric_qos_decap(hdr, ig_md);
        ig_md.common.l2_encap = hdr.fabric_unicast_ext_fe.l2_encap;
        ig_md.common.l3_encap = hdr.fabric_unicast_ext_fe.l3_encap;
        ig_md.common.hash[15:0] = hdr.fabric_unicast_ext_fe.hash;
        ig_md.common.iif = hdr.fabric_one_pad.iif;
    }
    action terminate_unicast_eth() {
        terminate_unicast();
        ig_md.ebridge.evlan = hdr.fabric_var_ext_1_16bit.data;
        ig_md.ebridge.l2oif = hdr.fabric_post_one_pad.l2oif;
    }
    action terminate_unicast_ip() {
        terminate_unicast();
        ig_md.route.dip_l3class_id = hdr.fabric_var_ext_2_8bit.data_hi;
        ig_md.route.sip_l3class_id = hdr.fabric_var_ext_2_8bit.data_lo;
    }
    action terminate_unicast_ipv4() {
        terminate_unicast_ip();
    }
    action terminate_unicast_ipv6() {
        terminate_unicast_ip();
    }
    action terminate_unicast_mpls() {
        terminate_unicast();
    }
    action terminate_tran_mirror() {
        terminate_unicast();
        ig_intr_md_for_tm.bypass_egress = 1w1;
    }
    action terminate_multicast() {
        fabric_base_decap(hdr, ig_md);
        fabric_qos_decap(hdr, ig_md);
        ig_md.multicast.id = hdr.fabric_multicast_dst.mgid;
        ig_md.ebridge.evlan = hdr.fabric_multicast_ext.evlan;
        ig_md.common.hash[15:0] = hdr.fabric_multicast_ext.hash;
        ig_md.flags.learning = hdr.fabric_multicast_ext.learning;
        ig_md.common.iif = hdr.fabric_one_pad.iif;
    }
    table fabric_ingress_decap {
        key = {
            hdr.fabric_base.pkt_type: exact;
        }
        actions = {
            NoAction;
            terminate_unicast_eth;
            terminate_unicast_ipv4;
            terminate_unicast_ipv6;
            terminate_unicast_mpls;
            terminate_tran_mirror;
        }
        const default_action = NoAction;
        size = 128;
        const entries = {
                        FABRIC_PKT_TYPE_ETH : terminate_unicast_eth();
                        FABRIC_PKT_TYPE_IPV4 : terminate_unicast_ipv4();
                        FABRIC_PKT_TYPE_IPV6 : terminate_unicast_ipv6();
                        FABRIC_PKT_TYPE_MPLS : terminate_unicast_mpls();
                        FABRIC_PKT_TYPE_MIRROR_TRAN : terminate_tran_mirror();
        }

    }
    action set_fpga_id(bit<7> dst_device) {
        ig_md.common.dst_device = dst_device;
    }
    table fabric_ingress_dst_lkp {
        key = {
            ig_md.common.port_type: exact;
            ig_md.common.dst_port : exact;
        }
        actions = {
            NoAction;
            set_fpga_id;
        }
        const default_action = NoAction;
        size = 128;
    }
    apply {
        if (hdr.ext_l4_encap.isValid() || hdr.ext_tunnel_decap.isValid()) {
            ig_md.common.extend = 1w1;
        }
        if (hdr.fabric_base.mcast == 1w0) {
            fabric_ingress_decap.apply();
            fabric_ingress_dst_lkp.apply();
        } else {
            terminate_multicast();
        }
    }
}

control IngressFabric_fabric(inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout switch_header_t hdr) {
    action terminate_unicast() {
        fabric_base_decap(hdr, ig_md);
        fabric_qos_decap(hdr, ig_md);
        ig_md.common.l2_encap = hdr.fabric_unicast_ext_fe.l2_encap;
        ig_md.common.l3_encap = hdr.fabric_unicast_ext_fe.l3_encap;
        ig_md.common.hash[15:0] = hdr.fabric_unicast_ext_fe.hash;
        ig_md.common.iif = hdr.fabric_one_pad.iif;
    }
    action terminate_unicast_eth() {
        terminate_unicast();
        ig_md.ebridge.evlan = hdr.fabric_var_ext_1_16bit.data;
        ig_md.ebridge.l2oif = hdr.fabric_post_one_pad.l2oif;
    }
    action terminate_unicast_ip() {
        terminate_unicast();
        ig_md.route.dip_l3class_id = hdr.fabric_var_ext_2_8bit.data_hi;
        ig_md.route.sip_l3class_id = hdr.fabric_var_ext_2_8bit.data_lo;
    }
    action terminate_unicast_ipv4() {
        terminate_unicast_ip();
    }
    action terminate_unicast_ipv6() {
        terminate_unicast_ip();
    }
    action terminate_unicast_mpls() {
        terminate_unicast();
    }
    action drop() {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
    }
    action redirect_to_cpu() {
        ig_intr_md_for_tm.copy_to_cpu = 1;
        drop();
    }
    action terminate_tran_mirror() {
        terminate_unicast();
        ig_intr_md_for_tm.bypass_egress = 1w1;
    }
    action terminate_multicast() {
        fabric_base_decap(hdr, ig_md);
        fabric_qos_decap(hdr, ig_md);
        ig_md.multicast.id = hdr.fabric_multicast_dst.mgid;
        ig_md.ebridge.evlan = hdr.fabric_multicast_ext.evlan;
        ig_md.common.hash[15:0] = hdr.fabric_multicast_ext.hash;
        ig_md.flags.learning = hdr.fabric_multicast_ext.learning;
        ig_md.common.iif = hdr.fabric_one_pad.iif;
    }
    table fabric_ingress_decap {
        key = {
            hdr.fabric_base.pkt_type: exact;
        }
        actions = {
            NoAction;
            terminate_unicast_eth;
            terminate_unicast_ipv4;
            terminate_unicast_ipv6;
            terminate_unicast_mpls;
            redirect_to_cpu;
            terminate_tran_mirror;
        }
        const default_action = NoAction;
        size = 128;
        const entries = {
                        FABRIC_PKT_TYPE_ETH : terminate_unicast_eth();
                        FABRIC_PKT_TYPE_IPV4 : terminate_unicast_ipv4();
                        FABRIC_PKT_TYPE_IPV6 : terminate_unicast_ipv6();
                        FABRIC_PKT_TYPE_MPLS : terminate_unicast_mpls();
                        FABRIC_PKT_TYPE_CPU_PCIE : redirect_to_cpu();
                        FABRIC_PKT_TYPE_MIRROR_TRAN : terminate_tran_mirror();
        }

    }
    action set_fpga_id(bit<7> dst_device) {
        ig_md.common.dst_device = dst_device;
    }
    table fabric_ingress_dst_lkp {
        key = {
            ig_md.common.port_type: exact;
            ig_md.common.dst_port : exact;
        }
        actions = {
            NoAction;
            set_fpga_id;
        }
        const default_action = NoAction;
        size = 128;
    }
    apply {
        if (hdr.ext_l4_encap.isValid() || hdr.ext_tunnel_decap.isValid()) {
            ig_md.common.extend = 1w1;
        }
        if (hdr.fabric_base.mcast == 1w0) {
            fabric_ingress_decap.apply();
            fabric_ingress_dst_lkp.apply();
        } else {
            terminate_multicast();
        }
    }
}

control IngressFabric_downlink(inout switch_ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout switch_header_t hdr) {
    action terminate_unicast() {
        fabric_base_decap(hdr, ig_md);
        fabric_qos_decap(hdr, ig_md);
        ig_md.qos.pcp = hdr.fabric_unicast_ext_eg_decap.pcp;
        ig_md.tunnel.next_hdr_type = hdr.fabric_unicast_ext_eg_decap.next_hdr_type;
        ig_md.common.dst_port = hdr.fabric_unicast_ext_eg_decap.dst_port;
        ig_md.common.l2_encap = hdr.fabric_unicast_ext_eg_decap.l2_encap;
        ig_md.tunnel.ptag_igmod = hdr.fabric_unicast_ext_eg_decap.ptag_igmod;
        ig_md.common.iif = hdr.fabric_one_pad.iif;
    }
    action terminate_multicast() {
        fabric_base_decap(hdr, ig_md);
        fabric_qos_decap(hdr, ig_md);
        ig_md.common.dst_port = hdr.fabric_unicast_ext_eg_decap.dst_port;
        ig_md.common.l2_encap = hdr.fabric_unicast_ext_eg_decap.l2_encap;
        ig_md.tunnel.ptag_igmod = hdr.fabric_unicast_ext_eg_decap.ptag_igmod;
        ig_md.common.iif = hdr.fabric_one_pad.iif;
    }
    table fabric_ingress_decap {
        key = {
            hdr.fabric_base.mcast: exact;
        }
        actions = {
            NoAction;
            terminate_unicast;
            terminate_multicast;
        }
        const default_action = NoAction;
        size = 128;
        const entries = {
                        0 : terminate_unicast();
                        1 : terminate_multicast();
        }

    }
    apply {
        if (hdr.ext_tunnel_decap.isValid()) {
            ig_md.common.extend = 1w1;
        }
        fabric_ingress_decap.apply();
    }
}

control FabricLag(in switch_header_t hdr, inout switch_ingress_metadata_t ig_md, in bit<16> hash, out switch_port_t egress_port) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(128, selector_hash, SelectorMode_t.FAIR) fabric_lag_selector;
    action set_fabric_lag_port(switch_port_t port) {
        egress_port = port;
    }
    table fabric_lag {
        key = {
            ig_md.common.dst_device: exact;
            ig_md.flags.glean      : exact;
            hash                   : selector;
        }
        actions = {
            NoAction;
            set_fabric_lag_port;
        }
        const default_action = NoAction;
        size = 128;
        implementation = fabric_lag_selector;
    }
    apply {
        fabric_lag.apply();
    }
}

control FabricDLBLag_uplink(in switch_header_t hdr, inout switch_ingress_metadata_t ig_md, in bit<16> hash, out switch_port_t egress_port) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(128, selector_hash, SelectorMode_t.FAIR) fabric_lag_selector;
    action set_fabric_lag_port(switch_port_t port) {
        egress_port = port;
    }
    table fabric_lag {
        key = {
            ig_md.common.dst_device: exact;
            hash                   : selector;
        }
        actions = {
            NoAction;
            set_fabric_lag_port;
        }
        const default_action = NoAction;
        size = 128;
        implementation = fabric_lag_selector;
    }
    apply {
        fabric_lag.apply();
    }
}

control FabricDLBLag(in switch_header_t hdr, inout switch_ingress_metadata_t ig_md, in bit<16> hash, out switch_port_t egress_port) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(128, selector_hash, SelectorMode_t.FAIR) fabric_lag_selector;
    action set_fabric_lag_port(switch_port_t port) {
        egress_port = port;
    }
    table fabric_lag {
        key = {
            ig_md.common.dst_device: exact;
            hash                   : selector;
        }
        actions = {
            NoAction;
            set_fabric_lag_port;
        }
        const default_action = NoAction;
        size = 128;
        implementation = fabric_lag_selector;
    }
    apply {
        fabric_lag.apply();
    }
}

action fabric_base_uc_encap(inout switch_header_t hdr, in switch_egress_metadata_t eg_md) {
    hdr.fabric_base.setValid();
    hdr.fabric_base.pkt_type = eg_md.common.pkt_type;
    hdr.fabric_base.mirror = 0;
    hdr.fabric_base.mcast = 0;
}
action fabric_base_mc_encap(inout switch_header_t hdr, in switch_egress_metadata_t eg_md) {
    hdr.fabric_base.setValid();
    hdr.fabric_base.pkt_type = eg_md.common.pkt_type;
    hdr.fabric_base.mirror = 0;
    hdr.fabric_base.mcast = 1;
}
action fabric_base_mirror_encap(inout switch_header_t hdr, in switch_egress_metadata_t eg_md) {
    hdr.fabric_base.setValid();
    hdr.fabric_base.pkt_type = eg_md.common.pkt_type;
    hdr.fabric_base.mirror = 1;
    hdr.fabric_base.mcast = 0;
}
action fabric_qos_encap(inout switch_header_t hdr, in switch_egress_metadata_t eg_md) {
    hdr.fabric_qos.setValid();
    hdr.fabric_qos.tc = eg_md.qos.tc;
    hdr.fabric_qos.color = eg_md.qos.color;
    hdr.fabric_qos.chgDSCP_disable = eg_md.qos.chgDSCP_disable;
    hdr.fabric_qos.BA = eg_md.qos.BA;
}
control FabricRewrite_uplink(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md) {
    Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_flags_pv;
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) hash_16_pv;
    action fabric_unicast() {
        fabric_base_uc_encap(hdr, eg_md);
        fabric_qos_encap(hdr, eg_md);
        hdr.fabric_unicast_ext_bfn_igfpga.setValid();
        hdr.fabric_unicast_ext_bfn_igfpga.extend = eg_md.common.extend;
        hdr.fabric_unicast_ext_bfn_igfpga.ext_len = eg_md.common.ext_len;
        hdr.fabric_unicast_ext_bfn_igfpga.service_class = eg_md.common.service_class;
        hdr.fabric_unicast_ext_bfn_igfpga.flags = hash_flags_pv.get({ eg_md.route.level ++ eg_md.route.is_ecmp ++ eg_md.route.disable_urpf ++ eg_md.flags.glean ++ eg_md.flags.drop ++ eg_md.flags.is_pbr_nhop ++ eg_md.flags.flowspec_disable });
        hdr.fabric_unicast_ext_bfn_igfpga.src_port = eg_md.common.src_port;
        hdr.fabric_unicast_ext_bfn_igfpga.cpu_reason = eg_md.common.cpu_reason;
        hdr.fabric_unicast_ext_bfn_igfpga.hash = eg_md.common.hash[15:0];
        hdr.fabric_unicast_ext_bfn_igfpga.nexthop = eg_md.common.nexthop;
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
    }
    action fabric_unicast_eth() {
        fabric_unicast();
        hdr.fabric_var_ext_1_16bit.setValid();
        hdr.fabric_var_ext_1_16bit.data = eg_md.ebridge.evlan;
        hdr.fabric_post_one_pad_encap.setValid();
        hdr.fabric_post_one_pad_encap.data = hash_16_pv.get({ eg_md.flags.learning ++ eg_md.ebridge.l2oif });
        hdr.fabric_post_one_pad.l2_flag = eg_md.flags.learning;
        hdr.fabric_post_one_pad.l2oif = eg_md.ebridge.l2oif;
    }
    action fabric_unicast_ip() {
        fabric_unicast();
        hdr.fabric_var_ext_2_8bit.setValid();
        hdr.fabric_var_ext_2_8bit.data_hi = eg_md.route.dip_l3class_id;
        hdr.fabric_var_ext_2_8bit.data_lo = eg_md.route.priority;
        hdr.ethernet.setInvalid();
        hdr.vlan_tag[0].setInvalid();
    }
    action fabric_unicast_ipv4() {
        fabric_unicast_ip();
    }
    action fabric_unicast_ipv6() {
        fabric_unicast_ip();
    }
    action fabric_unicast_mpls() {
        fabric_unicast();
        hdr.fabric_var_ext_2_8bit.setValid();
        hdr.fabric_var_ext_2_8bit.data_hi = eg_md.tunnel.label_space;
        hdr.ethernet.setInvalid();
    }
    action fabric_multicast_rewrite() {
        fabric_base_mc_encap(hdr, eg_md);
        fabric_qos_encap(hdr, eg_md);
        hdr.fabric_multicast_dst.setValid();
        hdr.fabric_multicast_ext.evlan = eg_md.ebridge.evlan;
        hdr.fabric_multicast_ext.learning = eg_md.flags.learning;
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
    }
    table fabric_rewrite {
        key = {
            eg_md.common.pkt_type: exact;
            eg_md.common.is_mcast: exact;
            eg_md.route.rmac_hit : exact;
        }
        actions = {
            NoAction;
            fabric_unicast_eth;
            fabric_unicast_ipv4;
            fabric_unicast_ipv6;
            fabric_unicast_mpls;
        }
        const default_action = NoAction;
        size = 128;
        const entries = {
                        (FABRIC_PKT_TYPE_ETH, 0, false) : fabric_unicast_eth();
                        (FABRIC_PKT_TYPE_IPV4, 0, false) : fabric_unicast_eth();
                        (FABRIC_PKT_TYPE_IPV6, 0, false) : fabric_unicast_eth();
                        (FABRIC_PKT_TYPE_MPLS, 0, false) : fabric_unicast_mpls();
                        (FABRIC_PKT_TYPE_IPV4, 0, true) : fabric_unicast_ipv4();
                        (FABRIC_PKT_TYPE_IPV6, 0, true) : fabric_unicast_ipv6();
                        (FABRIC_PKT_TYPE_MPLS, 0, true) : fabric_unicast_mpls();
        }

    }
    action ext_len_word_1() {
        eg_md.common.ext_len = 1;
    }
    table header_ext_len {
        key = {
            hdr.ext_tunnel_decap.isValid(): exact;
        }
        actions = {
            NoAction;
            ext_len_word_1;
        }
        const default_action = NoAction;
        size = 8;
        const entries = {
                        true : ext_len_word_1;
        }

    }
    apply {
        header_ext_len.apply();
        if (eg_md.common.is_mcast == 1w0) {
            fabric_rewrite.apply();
        } else {
            fabric_multicast_rewrite();
        }
    }
}

control FabricRewrite_uplink_fabric(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md) {
    Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_flags_pv;
    action fabric_unicast() {
        fabric_base_uc_encap(hdr, eg_md);
        fabric_qos_encap(hdr, eg_md);
        hdr.fabric_unicast_ext_fe_encap.setValid();
        hdr.fabric_unicast_ext_fe_encap.flags = hash_flags_pv.get({ eg_md.common.extend ++ eg_md.flags.is_pbr_nhop ++ eg_md.flags.flowspec_disable ++ 5w0 });
        hdr.fabric_unicast_ext_fe_encap.l2_encap = eg_md.common.l2_encap;
        hdr.fabric_unicast_ext_fe_encap.l3_encap = eg_md.common.l3_encap;
        hdr.fabric_unicast_ext_fe_encap.egress_eport = eg_md.common.egress_eport;
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
    }
    action fabric_unicast_eth() {
        fabric_unicast();
        hdr.fabric_var_ext_1_16bit.setValid();
        hdr.fabric_var_ext_1_16bit.data = eg_md.ebridge.evlan;
        hdr.fabric_post_one_pad.setValid();
        hdr.fabric_post_one_pad.l2oif = eg_md.ebridge.l2oif;
    }
    action fabric_unicast_ip() {
        fabric_unicast();
        hdr.fabric_var_ext_2_8bit.setValid();
        hdr.fabric_var_ext_2_8bit.data_hi = eg_md.route.dip_l3class_id;
        hdr.fabric_var_ext_2_8bit.data_lo = eg_md.route.sip_l3class_id;
    }
    action fabric_unicast_ipv4() {
        fabric_unicast_ip();
    }
    action fabric_unicast_ipv6() {
        fabric_unicast_ip();
    }
    action fabric_unicast_mpls() {
        fabric_unicast();
        hdr.fabric_var_ext_2_8bit.setValid();
    }
    action fabric_cpu_to_fabric() {
        fabric_base_uc_encap(hdr, eg_md);
        fabric_qos_encap(hdr, eg_md);
        hdr.fabric_unicast_dst.setValid();
        hdr.fabric_unicast_dst.dst_device = eg_md.common.dst_device;
        hdr.fabric_unicast_dst.dst_port = eg_md.common.dst_port;
        hdr.fabric_cpu_data.setValid();
        hdr.fabric_payload.setValid();
        hdr.fabric_payload.ether_type = hdr.ethernet.ether_type;
    }
    action fabric_mirror() {
        fabric_base_mirror_encap(hdr, eg_md);
        hdr.fabric_qos.setValid();
        hdr.fabric_unicast_dst.setValid();
        hdr.fabric_unicast_dst.extend = 0;
        hdr.fabric_unicast_dst.dst_device = eg_md.common.dst_device;
        hdr.fabric_unicast_dst.dst_port = eg_md.common.dst_port;
        hdr.fabric_unicast_ext_fe.setValid();
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
    }
    action fabric_multicast_rewrite() {
        fabric_base_mc_encap(hdr, eg_md);
        fabric_qos_encap(hdr, eg_md);
        hdr.fabric_multicast_dst.setValid();
        hdr.fabric_multicast_ext.evlan = eg_md.ebridge.evlan;
        hdr.fabric_multicast_ext.learning = eg_md.flags.learning;
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
    }
    table fabric_rewrite {
        key = {
            eg_md.common.pkt_type: exact;
        }
        actions = {
            NoAction;
            fabric_unicast_eth;
            fabric_unicast_ipv4;
            fabric_unicast_ipv6;
            fabric_unicast_mpls;
            fabric_mirror;
        }
        const default_action = NoAction;
        size = 128;
        const entries = {
                        FABRIC_PKT_TYPE_ETH : fabric_unicast_eth();
                        FABRIC_PKT_TYPE_IPV4 : fabric_unicast_ipv4();
                        FABRIC_PKT_TYPE_IPV6 : fabric_unicast_ipv6();
                        FABRIC_PKT_TYPE_MPLS : fabric_unicast_mpls();
                        FABRIC_PKT_TYPE_MIRROR_TRAN : fabric_mirror();
        }

    }
    apply {
        if (eg_md.common.is_mcast == 1w0) {
            fabric_rewrite.apply();
        } else {
            fabric_multicast_rewrite();
        }
    }
}

control FabricRewrite_fabric(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md) {
    Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_flags_pv;
    action fabric_unicast() {
        fabric_base_uc_encap(hdr, eg_md);
        fabric_qos_encap(hdr, eg_md);
        hdr.fabric_unicast_ext_fe_encap.setValid();
        hdr.fabric_unicast_ext_fe_encap.flags = hash_flags_pv.get({ eg_md.common.extend ++ eg_md.flags.is_pbr_nhop ++ eg_md.flags.flowspec_disable ++ 5w0 });
        hdr.fabric_unicast_ext_fe_encap.l2_encap = eg_md.common.l2_encap;
        hdr.fabric_unicast_ext_fe_encap.l3_encap = eg_md.common.l3_encap;
        hdr.fabric_unicast_ext_fe_encap.egress_eport = eg_md.common.egress_eport;
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
    }
    action fabric_unicast_eth() {
        fabric_unicast();
        hdr.fabric_var_ext_1_16bit.setValid();
        hdr.fabric_var_ext_1_16bit.data = eg_md.ebridge.evlan;
        hdr.fabric_post_one_pad.setValid();
        hdr.fabric_post_one_pad.l2oif = eg_md.ebridge.l2oif;
    }
    action fabric_unicast_ip() {
        fabric_unicast();
        hdr.fabric_var_ext_2_8bit.setValid();
        hdr.fabric_var_ext_2_8bit.data_hi = eg_md.route.dip_l3class_id;
        hdr.fabric_var_ext_2_8bit.data_lo = eg_md.route.sip_l3class_id;
    }
    action fabric_unicast_ipv4() {
        fabric_unicast_ip();
    }
    action fabric_unicast_ipv6() {
        fabric_unicast_ip();
    }
    action fabric_unicast_mpls() {
        fabric_unicast();
        hdr.fabric_var_ext_2_8bit.setValid();
    }
    action fabric_c2c_to_fabric() {
        fabric_base_uc_encap(hdr, eg_md);
        hdr.fabric_qos.setValid();
        hdr.fabric_unicast_dst.setValid();
        hdr.fabric_unicast_dst.dst_device = eg_md.common.dst_device;
        hdr.fabric_unicast_dst.dst_port = eg_md.common.dst_port;
        hdr.fabric_cpu_data.setValid();
        hdr.fabric_payload.setValid();
        hdr.fabric_payload.ether_type = 0x9000;
    }
    action fabric_c2c_to_pcie() {
        fabric_base_uc_encap(hdr, eg_md);
        hdr.fabric_qos.setValid();
        hdr.fabric_unicast_dst.setValid();
        hdr.fabric_unicast_dst.dst_device = eg_md.common.dst_device;
        hdr.fabric_unicast_dst.dst_port = eg_md.common.dst_port;
        hdr.fabric_cpu_data.setValid();
        hdr.fabric_cpu_data.iif = eg_md.common.iif;
        hdr.fabric_cpu_data.reason_code = 0xffff;
        hdr.fabric_payload.setValid();
        hdr.fabric_payload.ether_type = 0x9000;
    }
    action fabric_ctl_rewrite() {
        fabric_base_uc_encap(hdr, eg_md);
        hdr.fabric_qos.setValid();
        hdr.fabric_unicast_dst.setValid();
        hdr.fabric_unicast_dst.dst_device = eg_md.common.dst_device;
        hdr.fabric_unicast_dst.dst_port = eg_md.common.dst_port;
        hdr.fabric_cpu_data.setValid();
        hdr.fabric_cpu_data.iif = eg_md.common.iif;
        hdr.fabric_cpu_data.reason_code = (bit<16>)eg_md.fabric.reason_code;
        hdr.fabric_payload.setValid();
        hdr.fabric_payload.ether_type = 0x9000;
    }
    action fabric_mirror() {
        fabric_base_mirror_encap(hdr, eg_md);
        hdr.fabric_qos.setValid();
        hdr.fabric_unicast_dst.setValid();
        hdr.fabric_unicast_dst.extend = 0;
        hdr.fabric_unicast_dst.dst_device = eg_md.common.dst_device;
        hdr.fabric_unicast_dst.dst_port = eg_md.common.dst_port;
        hdr.fabric_unicast_ext_fe.setValid();
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
    }
    action fabric_eth_to_pcie() {
        fabric_ctl_rewrite();
    }
    action fabric_ip_to_pcie() {
        fabric_ctl_rewrite();
    }
    action fabric_multicast_rewrite() {
        fabric_base_mc_encap(hdr, eg_md);
        fabric_qos_encap(hdr, eg_md);
        hdr.fabric_multicast_dst.setValid();
        hdr.fabric_multicast_ext.evlan = eg_md.ebridge.evlan;
        hdr.fabric_multicast_ext.learning = eg_md.flags.learning;
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
    }
    table fabric_rewrite {
        key = {
            eg_md.common.pkt_type : exact;
            eg_md.common.port_type: exact;
        }
        actions = {
            NoAction;
            fabric_unicast_eth;
            fabric_unicast_ipv4;
            fabric_unicast_ipv6;
            fabric_unicast_mpls;
            fabric_c2c_to_fabric;
            fabric_c2c_to_pcie;
            fabric_eth_to_pcie;
            fabric_ip_to_pcie;
            fabric_mirror;
        }
        const default_action = NoAction;
        size = 128;
        const entries = {
                        (FABRIC_PKT_TYPE_ETH, PORT_TYPE_FABRIC) : fabric_unicast_eth();
                        (FABRIC_PKT_TYPE_IPV4, PORT_TYPE_FABRIC) : fabric_unicast_ipv4();
                        (FABRIC_PKT_TYPE_IPV6, PORT_TYPE_FABRIC) : fabric_unicast_ipv6();
                        (FABRIC_PKT_TYPE_MPLS, PORT_TYPE_FABRIC) : fabric_unicast_mpls();
                        (FABRIC_PKT_TYPE_MIRROR_TRAN, PORT_TYPE_FABRIC) : fabric_mirror();
                        (FABRIC_PKT_TYPE_CPU_PCIE, PORT_TYPE_FABRIC) : fabric_c2c_to_fabric();
                        (FABRIC_PKT_TYPE_CPU_PCIE, PORT_TYPE_CPU_PCIE) : fabric_c2c_to_pcie();
                        (FABRIC_PKT_TYPE_ETH, PORT_TYPE_CPU_PCIE) : fabric_eth_to_pcie();
                        (FABRIC_PKT_TYPE_IP, PORT_TYPE_CPU_PCIE) : fabric_ip_to_pcie();
        }

    }
    apply {
        if (eg_md.common.is_mcast == 1w0) {
            fabric_rewrite.apply();
        } else {
            fabric_multicast_rewrite();
        }
    }
}

control FabricRewrite_downlink(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md) {
    Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_flags_pv;
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) hash_16_pv;
    action fabric_unicast_rewrite() {
        fabric_base_uc_encap(hdr, eg_md);
        fabric_qos_encap(hdr, eg_md);
        hdr.fabric_unicast_ext_eg.setValid();
        hdr.fabric_unicast_ext_eg.flags = hash_flags_pv.get({ eg_md.common.extend ++ eg_md.qos.pcp ++ eg_md.tunnel.next_hdr_type ++ 2w0 });
        hdr.fabric_unicast_ext_eg.dst_port = eg_md.common.dst_port;
        hdr.fabric_unicast_ext_eg.l2_encap = eg_md.common.l2_encap;
        hdr.fabric_unicast_ext_eg.ptag_igmod_oif = hash_16_pv.get({ eg_md.tunnel.ptag_igmod ++ eg_md.common.oif });
        hdr.fabric_unicast_ext_eg.pkt_len = eg_md.common.pkt_length;
        hdr.fabric_unicast_ext_eg.FQID = eg_md.qos.FQID;
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
    }
    action fabric_multicast_rewrite() {
        fabric_base_mc_encap(hdr, eg_md);
        fabric_qos_encap(hdr, eg_md);
        hdr.fabric_unicast_ext_eg.setValid();
        hdr.fabric_unicast_ext_eg.flags = hash_flags_pv.get({ eg_md.common.extend ++ eg_md.qos.pcp ++ eg_md.tunnel.next_hdr_type ++ 2w0 });
        hdr.fabric_unicast_ext_eg.dst_port = eg_md.common.dst_port;
        hdr.fabric_unicast_ext_eg.l2_encap = eg_md.common.l2_encap;
        hdr.fabric_unicast_ext_eg.ptag_igmod_oif = hash_16_pv.get({ eg_md.tunnel.ptag_igmod ++ eg_md.common.oif });
        hdr.fabric_unicast_ext_eg.pkt_len = eg_md.common.pkt_length;
        hdr.fabric_unicast_ext_eg.FQID = eg_md.qos.FQID;
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
    }
    table fabric_rewrite {
        key = {
            eg_md.common.is_mcast: exact;
        }
        actions = {
            NoAction;
            fabric_unicast_rewrite;
            fabric_multicast_rewrite;
        }
        const default_action = NoAction;
        size = 128;
        const entries = {
                        0 : fabric_unicast_rewrite();
                        1 : fabric_multicast_rewrite();
        }

    }
    apply {
        if (hdr.ext_tunnel_decap.isValid()) {
            eg_md.common.pkt_length = eg_md.common.pkt_length + 16w18;
        } else {
            eg_md.common.pkt_length = eg_md.common.pkt_length + 16w14;
        }
        fabric_rewrite.apply();
    }
}

control FabricVlanDecap(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md) {
    action remove_vlan_tag() {
        hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
        hdr.vlan_tag[0].setInvalid();
    }
    table vlan_decap {
        key = {
            hdr.vlan_tag[0].isValid(): exact;
        }
        actions = {
            NoAction;
            remove_vlan_tag;
        }
        const default_action = NoAction;
        size = 512;
    }
    apply {
        vlan_decap.apply();
    }
}

control FabricVlanXlate(inout switch_header_t hdr, in switch_ingress_metadata_t ig_md) {
    bit<3> pcp_tmp;
    action set_vlan_tagged(vlan_id_t vid) {
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;
        hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].vid = vid;
        hdr.vlan_tag[0].pcp = pcp_tmp;
        hdr.ethernet.ether_type = 0x8100;
    }
    table vlan_encap {
        key = {
            ig_md.common.egress_eport: exact;
            ig_md.ebridge.evlan      : exact;
        }
        actions = {
            NoAction;
            set_vlan_tagged;
        }
        const default_action = NoAction;
        size = 1024;
    }
    action set_vlan_pcp(bit<3> pcp) {
        pcp_tmp = pcp;
    }
    table pcp_map {
        key = {
            ig_md.qos.tc   : exact;
            ig_md.qos.color: exact;
        }
        actions = {
            NoAction;
            set_vlan_pcp;
        }
        const default_action = NoAction;
        size = 1024;
    }
    apply {
        pcp_map.apply();
        vlan_encap.apply();
    }
}

control Ig_downlink(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    McExportMapping() mc_egport_mapping;
    IngressFabric_downlink() ig_fabric;
    Traffic_downlink() traffic_class;
    Qos_Count() qos_count;
    SetEtherType() set_ethertype;
    LocalL2Encap() l2_encap;
    downlink_ig_acl_pre() acl_pre;
    downlink_ig_acl() acl;
    DevPortMapping_downlink() dev_port_mapping;
    BridgedMetadata_DOWNLINK() bridged_md_downlink;
    BridgedMetadata_extend_DOWNLINK() bridged_md_ext_downlink;
    apply {
        init_bridge_type(ig_md, BRIDGE_TYPE_DOWNLINK_FRONT);
        ig_fabric.apply(ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr, hdr);
        acl_pre.apply(hdr, ig_intr_md_for_tm, ig_md);
        traffic_class.apply(hdr, ig_md, ig_intr_md_for_tm);
        acl.apply(hdr, ig_md.lkp, ig_md);
        if (ig_md.common.is_mcast == 1) {
            mc_egport_mapping.apply(ig_intr_md.ingress_port, ig_intr_md_for_tm.ucast_egress_port);
        }
        qos_count.apply(ig_md);
        dev_port_mapping.apply(ig_md, ig_intr_md_for_tm);
        set_ethertype.apply(hdr, ig_md);
        l2_encap.apply(hdr, ig_md);
        if (ig_intr_md_for_tm.bypass_egress == 1w0) {
            bridged_md_ext_downlink.apply(hdr, ig_md);
            bridged_md_downlink.apply(hdr, ig_md);
        }
    }
}

control Eg_downlink(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    EgressPortMapping_downlink() egress_port_mapping;
    RidAttribute() rid_attribute;
    EvlanMapVni() evlan_map_vni;
    L2IntfAttr() l2_intf_attr;
    HorizonSplit() horizon_split;
    TunnelEncap() encap_outer;
    MPLS_VC_encap() mpls_vc_encap;
    TunnelRewrite() tunnel_rewrite;
    MPLS_encap() mpls_encap;
    MPLS_encap2() mpls_encap2;
    L2EncapMapping() l2_encap_mapping;
    L3EncapMapping() l3_encap_mapping;
    L4EncapMapping() l4_encap_mapping;
    Out_Qos_properties() qos_properties;
    EgressQoS() qos;
    Modify_Hdr_Cos() modify_cos;
    downlink_eg_qppb_acl() qppb;
    QppbMeter_Out() qppb_meter;
    AclMeter_Out() acl_meter;
    Dscp_decide() dscp_decide;
    downlink_eg_acl_pre() acl_pre;
    downlink_eg_qos_acl() qos_acl;
    Out_LifMeter() lif_meter;
    Qid_Map() qid_map;
    Out_PortMeter() port_meter;
    LAGFilter() lag_filter;
    DownlinkEgressSystemAcl() sysacl;
    FabricRewrite_downlink() fabric_rewrite;
    MC_LAG() mc_lag;
    apply {
        if (hdr.ext_l4_encap.isValid() || hdr.ext_tunnel_decap.isValid()) {
            eg_md.common.extend = 1w1;
        }
        egress_port_mapping.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);
        if (eg_md.common.port_type == PORT_TYPE_FPGA_DOWN) {
            lag_filter.apply(hdr, eg_md, eg_intr_md, eg_intr_md_for_dprsr);
        }
        rid_attribute.apply(eg_intr_md, eg_md);
        l2_intf_attr.apply(eg_md);
        horizon_split.apply(eg_md, eg_intr_md_for_dprsr);
        l4_encap_mapping.apply(eg_md);
        l3_encap_mapping.apply(eg_md);
        l2_encap_mapping.apply(hdr, eg_md);
        qos_properties.apply(eg_md);
        qos.apply(hdr, eg_md);
        port_meter.apply(hdr, eg_md);
        evlan_map_vni.apply(hdr, eg_md);
        encap_outer.apply(hdr, eg_md);
        if (eg_md.tunnel.l4_encap != 0) {
            mpls_vc_encap.apply(hdr, eg_md);
        }
        if (eg_md.tunnel.l3_encap_mapping_hit == 1) {
            if (eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_MPLS) {
                mpls_encap.apply(hdr, eg_md, eg_md.tunnel);
            } else {
                tunnel_rewrite.apply(hdr, eg_md);
            }
        }
        if (eg_md.tunnel.l3_encap_mapping_hit == 1) {
            if (eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_MPLS) {
                mpls_encap2.apply(hdr, eg_md, eg_md.tunnel);
            }
        }
        lif_meter.apply(hdr, eg_md);
        acl_pre.apply(hdr, eg_md.lkp, eg_md);
        qos_acl.apply(hdr, eg_md.lkp, eg_md);
        qppb.apply(hdr, eg_md);
        qppb_meter.apply(hdr, eg_md);
        modify_cos.apply(hdr, eg_md);
        sysacl.apply(eg_md, eg_intr_md_for_dprsr);
        qid_map.apply(eg_md);
        if (eg_md.common.is_mcast == 1) {
            mc_lag.apply(eg_md, eg_md.common.hash, eg_md.common.dst_port);
        }
        fabric_rewrite.apply(hdr, eg_md, eg_intr_md);
    }
}

control Ig_fabric(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    IngressPortMapping_fabric() ingress_port_mapping;
    IngressFabric_fabric() ig_fabric;
    FabricDLBLag() fabric_dlb;
    Traffic_fabric() traffic_class;
    mgid_copy_to_tm() mgid_cp;
    BridgedMetadata_FABRIC() bridged_md_fabric;
    FabricVlanDecap() fabric_vlan_decap;
    FabricVlanXlate() fabric_vlan_encap;
    apply {
        ingress_port_mapping.apply(hdr, ig_intr_md.ingress_port, ig_intr_md_for_tm, ig_md);
        ig_fabric.apply(ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr, hdr);
        fabric_dlb.apply(hdr, ig_md, ig_md.common.hash, ig_intr_md_for_tm.ucast_egress_port);
        traffic_class.apply(hdr, ig_md, ig_intr_md_for_tm);
        if (ig_md.common.is_mcast == 1) {
            mgid_cp.apply(ig_intr_md_for_tm, ig_md);
        }
        if (ig_md.common.port_type == PORT_TYPE_CPU_PCIE) {
            fabric_vlan_decap.apply(hdr, ig_md);
            fabric_vlan_encap.apply(hdr, ig_md);
        }
        if (ig_intr_md_for_tm.bypass_egress == 1w0) {
            bridged_md_fabric.apply(hdr, ig_md);
        }
    }
}

control Eg_fabric(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    EgressPortMapping_fabric() egress_port_mapping;
    FabricRewrite_fabric() fabric_rewrite;
    fabric_copp() copp;
    Counter<bit<32>, bit<1>>(1, CounterType_t.PACKETS) cpu_stats;
    apply {
        if (hdr.ext_l4_encap.isValid() || hdr.ext_tunnel_decap.isValid()) {
            eg_md.common.extend = 1w1;
        }
        if (eg_md.flags.cpu_mirror_pkt == 0) {
            egress_port_mapping.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);
            copp.apply(hdr, eg_md, eg_intr_md, eg_intr_md_for_dprsr);
            fabric_rewrite.apply(hdr, eg_md, eg_intr_md);
        } else {
            cpu_stats.count(0);
        }
    }
}

Pipeline(IgParser_fabric(), Ig_fabric(), IgDeparser_fabric(), EgParser_fabric(), Eg_fabric(), EgDeparser_fabric()) pp_fabric;

Pipeline(IgParser_downlink(), Ig_downlink(), IgDeparser_downlink(), EgParser_downlink(), Eg_downlink(), EgDeparser_downlink()) pp_downlink;

Switch(pp_fabric, pp_downlink) main;

