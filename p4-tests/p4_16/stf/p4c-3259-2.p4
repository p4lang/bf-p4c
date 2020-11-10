#include <core.p4>
#include <tofino.p4>
#include <tofino1arch.p4>

const bit<32> PORT_TABLE_SIZE = 512;
const bit<32> STROM_CONTROL_TABLE_SIZE = 1024;
const bit<32> HASH_COMPUTE_TABLE_SIZE = 64;
const bit<32> HASH_MODE_TABLE_SIZE = 64;
const bit<32> LAG_TABLE_SIZE = 512;
const bit<32> LIF_TABLE_SIZE = 32768;
const bit<32> LIF_PROPERTIES_TABLE_SIZE = 16384;
const bit<32> BACK_LIF_TABLE_SIZE = 512;
const bit<32> EVLAN_FLOOD_TABLE_SIZE = 8192;
const bit<32> LIF_STATS_TABLE_SIZE = 16384;
const bit<32> IP_STATS_TABLE_SIZE = 10240;
const bit<32> PORT_VLAN_TABLE_SIZE = 1024;
const bit<32> EVLAN_TABLE_SIZE = 8192;
const bit<32> MAC_TABLE_SIZE = 81920;
const bit<32> BACK_MAC_TABLE_SIZE = 512;
const bit<32> EVLAN_ATTR_SIZE = 8192;
const bit<32> EVLAN_RMAC_SIZE = 1024;
const bit<32> L2LIF_TABLE_SIZE = 16384;
const bit<32> HORIZON_SPLIT_SIZE = 64;
const bit<32> PTAG_ENCAP_SIZE = 32;
const bit<32> VALIDATION_TABLE_SIZE = 64;
const bit<32> L3IIF_TABLE_SIZE = 16384;
const bit<32> VMAC_TABLE_SIZE = 2048;
const bit<32> VMAC_BACK_TABLE_SIZE = 1024;
const bit<32> IPV4_LPM_TABLE_SIZE = 1024;
const bit<32> IPV6_LPM_TABLE_SIZE = 1024;
const bit<32> IPV4_HOST_TABLE_SIZE = 20480;
const bit<32> IPV6_HOST_TABLE_SIZE = 20480;
const bit<32> L4_NEXTHOP_TABLE_SIZE = 65536;
const bit<32> OVERLAY_NEXTHOP_TABLE_SIZE = 65536;
const bit<32> UNDERLAY_NEXTHOP_TABLE_SIZE = 65536;
const bit<32> OVERLAY_COUNTER_TABLE_SIZE = 16384;
const bit<32> MTU_CHECK_TABLE_SIZE = 16384;
const bit<32> L2_ENCAP_TABLE_SIZE = 65536;
const bit<32> RID_ATTRIBUTE_TABLE_SIZE = 16384;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 8192;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 4096;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 8192;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 4096;
const bit<32> VXLAN_TERMINATE_SIZE = 16384;
const bit<32> L4_ENCAP_TABLE_SIZE = 65536;
const bit<32> SET_SMAC_SIZE = 16384;
const bit<32> EVLAN_VNI_MAPING_SIZE = 8192;
const bit<32> GET_REWRITE_INFO_SIZE = 8192;
const bit<32> MPLS_VC_ENCAP_SIZE = 65536;
const bit<32> MPLS_TUNNEL0_TABLE_SIZE = 65536;
const bit<32> MPLS_TUNNEL1_TABLE_SIZE = 16384;
const bit<32> MPLS_TUNNEL2_TABLE_SIZE = 16384;
const bit<32> ILM_TABLE_SIZE = 32768;
const bit<32> ILM3_TABLE_SIZE = 49152;
const bit<32> L3_ENCAP_MAPPING_SIZE = 65536;
const bit<32> SRC_DST_ADDR_SIZE = 14336;
const bit<32> DST_ADDR_SIZE = 13312;
const bit<32> G_DST_ADDR_SIZE = 13312;
const bit<32> PORT_IPFIX_TABLE_SIZE = 512;
const bit<32> MIRROR_LAG_TABLE_SIZE = 512;
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
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

header drop_msg_h {
    bit<16> port;
    bit<16> fqid;
    bit<16> len;
}

header pause_info_h {
    bit<16> code;
    bit<16> time;
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

@pa_container_size("ingress", "hdr.ipv6.dst_addr", 32, 32, 32, 32) header ipv6_h {
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
    bit<48> sender_mac;
    bit<32> sender_ip;
    bit<48> dst_mac;
    bit<32> dst_ip;
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
    bit<1> is_mirror;
    bit<1> is_mcast;
}

header fabric_base_h {
    bit<6> pkt_type;
    bit<1> is_mirror;
    bit<1> is_mcast;
}

header fabric_qos_h {
    bit<3> tc;
    bit<2> color;
    bit<1> chgDSCP_disable;
    bit<1> BA;
    bit<1> track;
}

header fabric_unicast_ext_bfn_igfpga_h {
    bit<8>  flags;
    bit<8>  nh_option;
    bit<8>  cpu_reason;
    bit<8>  src_port;
    bit<16> nexthop;
    bit<16> hash;
}

header fabric_unicast_ext_igfpga_bfn_h {
    bit<1>  extend;
    bit<1>  fwd_fail;
    @padding
    bit<2>  pad;
    bit<1>  glean;
    bit<1>  drop;
    bit<1>  is_pbr_nhop;
    bit<1>  flowspec_disable;
    bit<8>  hash_lite;
    bit<8>  cpu_reason;
    bit<8>  src_port;
    bit<16> ul_nhid;
    bit<16> ol_nhid;
}

header fabric_unicast_dst_encap_h {
    bit<8> flags;
    @padding
    bit<8> dst_port;
}

header fabric_unicast_dst_h {
    bit<1> extend;
    bit<7> dst_device;
    bit<8> dst_port;
}

header fabric_unicast_ext_fe_encap_h {
    bit<16> l2_encap;
    bit<16> l3_encap;
    bit<16> egress_eport;
}

header fabric_unicast_ext_fe_h {
    bit<16> l2_encap;
    bit<16> l3_encap;
    bit<16> hash;
}

header fabric_multicast_src_h {
    bit<1> extend;
    bit<7> src_device;
    bit<8> src_port;
}

header fabric_multicast_ext_h {
    @padding
    bit<3>  pad1;
    bit<1>  gleaned;
    @padding
    bit<12> pad;
    bit<16> mgid;
    bit<16> hash;
    bit<16> evlan;
}

header fabric_unicast_ext_eg_encap_h {
    bit<16> combine;
    bit<16> l2_encap;
    bit<16> ptag_igmod_oif;
    bit<16> pkt_len;
    bit<16> FQID;
}

header fabric_unicast_ext_eg_h {
    bit<2>  next_hdr_type;
    bit<3>  pcp;
    @padding
    bit<3>  pad;
    bit<8>  dst_port;
    bit<16> l2_encap;
    bit<1>  ptag_igmod;
    @padding
    bit<1>  oif_pad;
    bit<14> oif;
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
    @padding
    bit<1>  pad;
    bit<14> iif;
}

header fabric_post_one_pad_h {
    bit<1>  l2_flag;
    @padding
    bit<1>  pad;
    bit<14> l2oif;
}

header fabric_cpu_pcie_base_h {
    bit<6> cpu_pkt_type;
    bit<2> fwd_mode;
    @padding
    bit<3> pad_qos;
    bit<5> qid;
}

header fabric_cpu_data_h {
    @padding
    bit<8>  pad1;
    bit<8>  cpu_reason;
    bit<16> cpu_code;
    @padding
    bit<16> pad;
    bit<16> evlan;
}

header fabric_payload_h {
    bit<16> ether_type;
}

header fabric_to_cpu_eth_base_h {
    bit<6> pkt_type;
    bit<1> dir;
    @padding
    bit<9> pad1;
}

header fabric_to_cpu_eth_data_h {
    @padding
    bit<2>  pad_iif;
    bit<14> iif;
    @padding
    bit<2>  pad_oif;
    bit<14> oif;
    bit<16> var_16bit;
    bit<8>  var_8bit_1;
    bit<8>  var_8bit_2;
    @padding
    bit<16> reserved;
}

header fabric_from_cpu_eth_base_h {
    bit<6> pkt_type;
    bit<2> fwd_mode;
    bit<5> qid;
    @padding
    bit<2> pad;
    bit<1> track;
}

header fabric_from_cpu_eth_data_h {
    bit<8>  dst_port;
    bit<8>  src_port;
    bit<16> dst_eport;
    bit<16> src_eport;
    bit<16> hash;
    @padding
    bit<2>  pad_iif;
    bit<14> iif;
}

typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;
typedef bit<7> switch_device_t;
typedef bit<8> switch_logic_port_t;
typedef PortId_t switch_port_t;
const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;
const switch_port_t SWITCH_PORT_FRONT_RECIRC = 9w0x44;
typedef QueueId_t switch_qid_t;
const switch_qid_t SWITCH_QID_CPU_TO_CPU = 7;
typedef ReplicationId_t switch_rid_t;
const switch_rid_t SWITCH_RID_DEFAULT = 0xffff;
typedef bit<3> switch_ingress_cos_t;
typedef bit<3> switch_digest_type_t;
const switch_digest_type_t SWITCH_DIGEST_TYPE_INVALID = 0;
const switch_digest_type_t SWITCH_DIGEST_TYPE_MAC_LEARNING = 1;
typedef bit<16> switch_eport_t;
typedef bit<16> switch_eport_label_t;
typedef bit<14> switch_lif_t;
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
const bit<8> SWITCH_CPU_REASON_IPFIX_SEPC_V4 = 15;
const bit<8> SWITCH_CPU_REASON_IPFIX_SEPC_V6 = 16;
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
const switch_bridge_type_t BRIDGE_TYPE_FRONT_UPLINK = 0;
const switch_bridge_type_t BRIDGE_TYPE_UPLINK_FABRIC = 1;
const switch_bridge_type_t BRIDGE_TYPE_UPLINK_FRONT = 2;
const switch_bridge_type_t BRIDGE_TYPE_FABRIC_DOWNLINK = 3;
const switch_bridge_type_t BRIDGE_TYPE_FABRIC_FABRIC = 4;
const switch_bridge_type_t BRIDGE_TYPE_DOWNLINK_FRONT = 5;
const switch_bridge_type_t BRIDGE_TYPE_FRONT_UPLINK_RECIRC = 6;
const switch_bridge_type_t BRIDGE_TYPE_FPGA_DROP = 7;
const switch_bridge_type_t BRIDGE_TYPE_QOS_RECIRC = 8;
const switch_bridge_type_t BRIDGE_TYPE_FPGA_PAUSE = 9;
const switch_bridge_type_t BRIDGE_TYPE_FRONT_FRONT = 10;
const switch_bridge_type_t BRIDGE_TYPE_FABRIC_FRONT = 11;
typedef bit<6> switch_pkt_type_t;
const switch_pkt_type_t FABRIC_PKT_TYPE_ETH = 0;
const switch_pkt_type_t FABRIC_PKT_TYPE_IPV4 = 1;
const switch_pkt_type_t FABRIC_PKT_TYPE_MPLS = 2;
const switch_pkt_type_t FABRIC_PKT_TYPE_IPV6 = 3;
const switch_pkt_type_t FABRIC_PKT_TYPE_RESERVED = 4;
const switch_pkt_type_t FABRIC_PKT_TYPE_IP = 5;
const switch_pkt_type_t FABRIC_PKT_TYPE_MIRROR_TRAN = 6;
const switch_pkt_type_t FABRIC_PKT_TYPE_FPGA_DROP = 7;
const switch_pkt_type_t FABRIC_PKT_TYPE_FPGA_PAUSE = 8;
const switch_pkt_type_t FABRIC_PKT_TYPE_IPFIX_SPEC_V4 = 9;
const switch_pkt_type_t FABRIC_PKT_TYPE_IPFIX_SPEC_V6 = 10;
const switch_pkt_type_t FABRIC_PKT_TYPE_BLACK_HOLE = 12;
const switch_pkt_type_t FABRIC_PKT_TYPE_CPU_ETH = 14;
const switch_pkt_type_t FABRIC_PKT_TYPE_CPU_PCIE = 15;
typedef bit<3> switch_fabric_ext_type_t;
const switch_fabric_ext_type_t FABRIC_EXT_TYPE_TUNNEL_DECAP = 0;
const switch_fabric_ext_type_t FABRIC_EXT_TYPE_L4_ENCAP = 1;
const switch_fabric_ext_type_t FABRIC_EXT_TYPE_L4_NHOP = 2;
typedef bit<2> switch_ext_data_type_t;
const switch_ext_data_type_t SWITCH_TUNNEL_DECAP_TYPE_TUNNEL = 0;
const switch_ext_data_type_t SWITCH_TUNNEL_DECAP_TYPE_OR = 1;
typedef bit<3> switch_bridged_metadata_ext_type_t;
const switch_bridged_metadata_ext_type_t BRIDGED_MD_EXT_TYPE_TUNNEL_DECAP = 0;
const switch_bridged_metadata_ext_type_t BRIDGED_MD_EXT_TYPE_L4_ENCAP = 1;
const switch_bridged_metadata_ext_type_t BRIDGED_MD_EXT_TYPE_SRV6 = 2;
const switch_bridged_metadata_ext_type_t BRIDGED_MD_EXT_TYPE_CPP = 3;
const switch_bridged_metadata_ext_type_t BRIDGED_MD_EXT_TYPE_MIRROR = 4;
typedef bit<2> switch_next_hdr_type_t;
const switch_next_hdr_type_t SWITCH_TUNNEL_NEXT_HDR_TYPE_NONE = 0;
const switch_next_hdr_type_t SWITCH_TUNNEL_NEXT_HDR_TYPE_MPLS = 1;
const switch_next_hdr_type_t SWITCH_TUNNEL_NEXT_HDR_TYPE_IPV4 = 2;
const switch_next_hdr_type_t SWITCH_TUNNEL_NEXT_HDR_TYPE_IPV6 = 3;
typedef bit<3> switch_mpls_vc_encap_opcode_t;
const switch_mpls_vc_encap_opcode_t SWITCH_MPLS_VC_ENCAP_OPCODE_ACTION_MISS = 0;
const switch_mpls_vc_encap_opcode_t SWITCH_MPLS_VC_ENCAP_OPCODE_PUSH_L2 = 1;
const switch_mpls_vc_encap_opcode_t SWITCH_MPLS_VC_ENCAP_OPCODE_PUSH_VC = 2;
const switch_mpls_vc_encap_opcode_t SWITCH_MPLS_VC_ENCAP_OPCODE_SWAP = 3;
const switch_mpls_vc_encap_opcode_t SWITCH_MPLS_VC_ENCAP_OPCODE_SWAP_SELF = 4;
typedef bit<2> switch_mpls_encap0_opcode_t;
const switch_mpls_encap0_opcode_t SWITCH_MPLS_ENCAP0_OPCODE_ACTION_MISS = 0;
const switch_mpls_encap0_opcode_t SWITCH_MPLS_ENCAP0_OPCODE_PUSH = 1;
const switch_mpls_encap0_opcode_t SWITCH_MPLS_ENCAP0_OPCODE_SWAP = 2;
const switch_mpls_encap0_opcode_t SWITCH_MPLS_ENCAP0_OPCODE_SWAP_SELF = 3;
typedef bit<6> switch_cpu_pcie_pkt_type_t;
const switch_cpu_pcie_pkt_type_t CPU_PCIE_PKT_TYPE_CPU_TO_CPU = 0;
const switch_cpu_pcie_pkt_type_t CPU_PCIE_PKT_TYPE_CPU_UC = 1;
const switch_cpu_pcie_pkt_type_t CPU_PCIE_PKT_TYPE_CPU_MC = 2;
typedef bit<2> switch_fwd_mode_t;
const switch_fwd_mode_t FWD_MODE_HW_FWDD = 0;
const switch_fwd_mode_t FWD_MODE_LOCAL = 1;
const switch_fwd_mode_t FWD_MODE_REMOTE = 2;
const switch_fwd_mode_t FWD_MODE_HOP = 3;
typedef bit<6> switch_cpu_eth_encap_id_t;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_INVALID = 0;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_BFD_ETH = 1;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_BFD_IPV4 = 2;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_BFD_IPV6 = 3;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_IPFIX_IG = 4;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_IPFIX_EG = 5;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_IPFIX_SPEC_V4 = 6;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_IPFIX_SPEC_V6 = 7;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_PIPELINE_TRACE = 8;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_PCAP = 9;
typedef bit<2> switch_lkp_pkt_type_t;
const switch_lkp_pkt_type_t FABRIC_PKT_TYPE_UNICAST = 0x1;
const switch_lkp_pkt_type_t FABRIC_PKT_TYPE_MCAST = 0x2;
const switch_lkp_pkt_type_t FABRIC_PKT_TYPE_BROADCAST = 0x3;
typedef bit<8> switch_drop_reason_t;
const switch_drop_reason_t SWITCH_DROP_REASON_UNKNOWN = 0;
const switch_drop_reason_t SWITCH_DROP_REASON_FORWARD = 1;
const switch_drop_reason_t SWITCH_DROP_REASON_PREV_DROP = 2;
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
const switch_drop_reason_t SWITCH_DROP_REASON_IP_DISABLE = 108;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_MC_CHECK_FAIL = 109;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_DST_ZERO = 110;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_DST_LOOPBACK = 111;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_E_ADDR = 112;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_BROADCAST = 113;
const switch_drop_reason_t SWITCH_DROP_REASON_FIB_MISS = 114;
const switch_drop_reason_t SWITCH_DROP_REASON_NEXTHOP_MISS = 115;
const switch_drop_reason_t SWITCH_DROP_REASON_LAG_MISS = 120;
const switch_drop_reason_t SWITCH_DROP_REASON_MPLS_DISABLE = 121;
const switch_drop_reason_t SWITCH_DROP_REASON_INGRESS_LIF_METER = 122;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_LIF_METER = 123;
const switch_drop_reason_t SWITCH_DROP_REASON_HORIZON_SPLIT = 124;
const switch_drop_reason_t SWITCH_DROP_REASON_QINQ = 125;
const switch_drop_reason_t SWITCH_DROP_REASON_FLOWSPEC_DROP = 126;
const switch_drop_reason_t SWITCH_DROP_REASON_FLOWSPEC_COLOR = 127;
const switch_drop_reason_t SWITCH_DROP_REASON_DST_PORT_INVALID = 128;
const switch_drop_reason_t SWITCH_DROP_REASON_STATIC_MAC_MOVE_PKT_DROP = 129;
const switch_drop_reason_t SWITCH_DROP_REASON_INGRESS_QPPB_METER = 130;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_QPPB_METER = 131;
typedef bit<3> switch_cpp_drop_reason_t;
const switch_cpp_drop_reason_t SWITCH_DROP_REASON_BLACK_LIST = 1;
const switch_cpp_drop_reason_t SWITCH_DROP_REASON_HOST_ACL = 2;
const switch_cpp_drop_reason_t SWITCH_DROP_REASON_TYPE_METER = 3;
const switch_cpp_drop_reason_t SWITCH_DROP_REASON_QID_METER = 4;
const switch_cpp_drop_reason_t SWITCH_DROP_REASON_PORT_METER = 5;
typedef bit<4> switch_port_type_t;
const switch_port_type_t PORT_TYPE_UNUSED = 0;
const switch_port_type_t PORT_TYPE_FRONT = 1;
const switch_port_type_t PORT_TYPE_FPGA_UPWARD = 2;
const switch_port_type_t PORT_TYPE_FPGA_DOWN = 3;
const switch_port_type_t PORT_TYPE_CPU_ETH = 4;
const switch_port_type_t PORT_TYPE_CPU_PCIE = 5;
const switch_port_type_t PORT_TYPE_FABRIC = 6;
const switch_port_type_t PORT_TYPE_RECIRC = 7;
const switch_port_type_t PORT_TYPE_QOS_RECIRC = 8;
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
const switch_hash_mode_t SWITCH_HASH_MODE_MPLS = 0x2;
const switch_hash_mode_t SWITCH_HASH_MODE_IPV6 = 0x3;
const switch_hash_mode_t SWITCH_SYM_HASH_MODE_IPV4 = 0x4;
const switch_hash_mode_t SWITCH_SYM_HASH_MODE_IPV6 = 0x5;
const switch_hash_mode_t SWITCH_HASH_MODE_MPLS_EXT = 0x6;
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
@pa_solitary("ingress", "ig_md.qos.lif_meter_index") struct switch_ingress_qos_metadata_t {
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
    bit<14>                 lif_meter_index;
    bit<12>                 v4v6_meter_index;
    bit<12>                 acl_meter_index;
    bit<8>                  port_meter_index;
    bit<8>                  qppb_meter_index;
    switch_pkt_color_t      qppb_meter_color;
    switch_pkt_color_t      port_meter_color;
    switch_pkt_color_t      lif_meter_color;
    switch_pkt_color_t      acl_meter_color;
    bit<3>                  drop_color;
    bit<5>                  port_ds;
    bit<5>                  lif_ds;
    bit<1>                  mpls_valid;
    bit<1>                  set_dscp;
    bit<1>                  qppb_set_dscp;
    bit<6>                  qppb_dscp;
    bit<1>                  set_tc;
    bit<1>                  set_color;
    bit<6>                  dscp;
    bit<1>                  car_flag;
    bit<2>                  qos_pkt_type;
    bit<6>                  dscp_tmp;
    bit<3>                  tc_tmp;
    bit<2>                  color_tmp;
    bool                    acl_set_tc;
    bool                    acl_set_color;
    bit<16>                 FQID;
    bit<32>                 len_sub1;
    bit<32>                 len_sub2;
    bit<1>                  fq_dlb_enb;
    bit<1>                  port_hqos_enb;
    bit<1>                  lif_hqos_enb;
    bit<12>                 port_base_qid;
    bit<12>                 lif_base_qid;
}

@pa_solitary("egress", "eg_md.qos.lif_meter_index") struct switch_egress_qos_metadata_t {
    switch_qid_t       qid;
    bit<19>            qdepth;
    bit<5>             port_ds;
    bit<5>             lif_ds;
    bit<3>             drop_color;
    switch_pkt_color_t acl_meter_color;
    switch_pkt_color_t qppb_meter_color;
    switch_pkt_color_t port_meter_color;
    switch_pkt_color_t lif_meter_color;
    switch_pkt_color_t color_tmp;
    bit<8>             port_meter_index;
    bit<8>             qppb_meter_index;
    bit<14>            lif_meter_index;
    bit<12>            v4v6_meter_index;
    bit<12>            acl_meter_index;
    switch_tc_t        tc;
    switch_pkt_color_t color;
    bit<1>             chgDSCP_disable;
    bit<1>             BA;
    bit<1>             port_PHB;
    bit<1>             lif_PHB;
    bit<1>             pcp_chg;
    bit<1>             exp_chg;
    bit<1>             ippre_chg;
    bit<1>             port_hqos_enb;
    bit<1>             lif_hqos_enb;
    bit<16>            FQID;
    switch_pkt_color_t storm_control_color;
    bit<1>             set_dscp;
    bit<1>             qppb_set_dscp;
    bit<1>             acl_set_dscp;
    bit<6>             dscp;
    bit<6>             qppb_dscp;
    bit<6>             acl_dscp;
    bit<3>             pcp;
    bit<3>             ippre;
    bit<12>            port_base_qid;
    bit<12>            lif_base_qid;
    bit<1>             car_flag;
    bit<32>            len_sub1;
    bit<32>            len_sub2;
    bit<1>             drop_flag;
    bit<16>            to_be_sub;
    bit<16>            to_be_add;
    bit<1>             q_hi_flag;
    bit<1>             q_lo_flag;
    bit<32>            mirror_max;
}

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

struct switch_lookup_fields_t {
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
    bit<3>                mpls_exp;
    bit<4>                version;
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
typedef bit<8> switch_pipeline_location_t;
const switch_pipeline_location_t INGRESS_FRONT = 1;
const switch_pipeline_location_t EGRESS_UPLINK = 2;
const switch_pipeline_location_t INGRESS_UPLINK = 3;
const switch_pipeline_location_t EGRESS_FABRIC = 4;
const switch_pipeline_location_t INGRESS_FE = 5;
const switch_pipeline_location_t EGRESS_FE = 6;
const switch_pipeline_location_t INGRESS_FABRIC = 7;
const switch_pipeline_location_t EGRESS_DOWNLINK = 8;
const switch_pipeline_location_t INGRESS_DOWNLINK = 9;
const switch_pipeline_location_t EGRESS_FRONT = 10;
struct switch_port_metadata_frontpipe_t {
    switch_port_type_t port_type;
}

struct switch_port_metadata_uplink_pipe_t {
    switch_port_type_t port_type;
}

struct switch_port_metadata_fabric_pipe_t {
    switch_port_type_t  port_type;
    bit<7>              src_device;
    switch_logic_port_t src_port;
}

struct switch_port_metadata_downlink_pipe_t {
    switch_port_type_t port_type;
}

@pa_container_size("ingress", "ig_md.flags.ipv6_mc_check", 32) @pa_solitary("ingress", "ig_md.flags.is_mac_static") struct switch_ingress_flags_t {
    bool    ipv4_checksum_err;
    bool    inner_ipv4_checksum_err;
    bool    link_local;
    bit<1>  dmac_miss;
    bit<1>  is_mac_static;
    bit<1>  static_mac_move_drop;
    bool    port_meter_drop;
    bool    lif_meter_drop;
    bool    qppb_meter_drop;
    bool    capture_ts;
    bit<1>  flowspec_disable;
    bit<1>  flowspec_disable_v4;
    bit<1>  flowspec_disable_v6;
    bit<1>  fwd_fail;
    bit<1>  glean;
    bit<1>  drop;
    bit<1>  is_pbr_nhop;
    bit<1>  bypass_acl;
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
    bit<1> dmac_miss;
    bit<1> bh_dmac_hit;
    bit<1> horizon_split_drop_reason;
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
    bit<1> bypass_acl;
    bit<1> bypass_sysacl;
    bit<1> is_gleaned;
    bit<1> learning;
    bit<1> learn_en_evlan;
    bit<1> sym_enable;
    bit<1> efm_drop;
    bit<1> cpu_mirror_pkt;
}

typedef bit<1> switch_iif_type_t;
const switch_iif_type_t SWITCH_L3_IIF_TYPE = 1;
const switch_iif_type_t SWITCH_L2_IIF_TYPE = 0;
struct switch_ingress_common_metadata_t {
    bit<16>                    ether_type;
    switch_pkt_type_t          pkt_type;
    bit<1>                     is_mirror;
    bit<1>                     is_mcast;
    switch_device_t            dst_device;
    switch_logic_port_t        dst_port;
    bit<1>                     efm_enable;
    bit<6>                     dst_ecid;
    switch_eport_t             eport;
    switch_eport_t             egress_eport;
    switch_eport_label_t       eport_label;
    switch_port_type_t         port_type;
    switch_bridge_type_t       bridge_type;
    bit<1>                     extend;
    bit<1>                     cpu_direction;
    bit<1>                     bypass_fpga;
    bit<2>                     fwd_mode;
    bit<1>                     track;
    bit<1>                     is_from_cpu_pcie;
    switch_iif_type_t          iif_type;
    switch_lif_t               iif;
    switch_lif_t               oif;
    switch_lif_t               ul_iif;
    bit<16>                    nexthop;
    bit<16>                    ul_nhid;
    bit<16>                    ol_nhid;
    bit<16>                    l2_encap;
    bit<16>                    l3_encap;
    bit<16>                    l4_encap;
    switch_drop_reason_t       drop_reason;
    switch_pipeline_location_t pipeline_location;
    bit<16>                    trace_counter;
    bool                       prr_enable;
    bit<16>                    prr_sn;
    switch_ingress_bypass_t    bypass;
    switch_hash_t              hash;
    switch_hash_t              hash_tmp;
    switch_hash_mode_t         hash_mode;
    bit<16>                    udf;
    switch_port_t              ingress_port;
    bit<7>                     src_device;
    switch_logic_port_t        src_port;
    bit<8>                     cpu_reason;
    bit<16>                    cpu_code;
}

@pa_solitary("egress", "eg_md.common.is_mirror") struct switch_egress_common_metadata_t {
    bit<16>                    ether_type;
    switch_pkt_type_t          pkt_type;
    bit<1>                     is_mirror;
    bit<1>                     is_mcast;
    switch_cpu_eth_encap_id_t  cpu_eth_encap_id;
    switch_device_t            dst_device;
    switch_logic_port_t        dst_port;
    bit<6>                     dst_ecid;
    bit<1>                     efm_enable;
    bit<1>                     is_from_cpu_pcie;
    switch_port_t              ingress_port;
    switch_port_type_t         port_type;
    switch_iif_type_t          iif_type;
    switch_lif_t               iif;
    switch_lif_t               oif;
    switch_lif_t               ul_iif;
    switch_eport_t             eport;
    switch_eport_t             egress_eport;
    switch_eport_label_t       eport_label;
    switch_egress_bypass_t     bypass;
    switch_pkt_length_t        pkt_length;
    bit<1>                     extend;
    bit<3>                     ext_len;
    bit<3>                     service_class;
    bit<1>                     track;
    switch_drop_reason_t       drop_reason;
    switch_pipeline_location_t pipeline_location;
    bit<16>                    trace_counter;
    bit<16>                    nexthop;
    bit<16>                    l3_encap;
    bit<16>                    l2_encap;
    switch_hash_t              hash;
    switch_hash_mode_t         hash_mode;
    bit<16>                    udf;
    switch_bridge_type_t       bridge_type;
    bit<7>                     src_device;
    switch_logic_port_t        src_port;
    bit<8>                     cpu_reason;
    bit<16>                    cpu_code;
    bit<6>                     srv6_tc;
    bit<1>                     srv6_set_dscp;
}

typedef bit<3> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NONE = 0;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IP_TUNNEL = 1;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPGRE = 2;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_SRV6 = 3;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPV4_VXLAN = 4;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_MPLS = 5;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPv6GRE = 6;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPV6_VXLAN = 7;
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
typedef bit<4> switch_opcode_type_t;
const switch_opcode_type_t SWITCH_MPLS_POP_CONTINUE = 0;
const switch_opcode_type_t SWITCH_MPLS_L2VPN_TER = 1;
const switch_opcode_type_t SWITCH_MPLS_L3VPN_TER = 2;
const switch_opcode_type_t SWITCH_MPLS_POP = 3;
const switch_opcode_type_t SWITCH_MPLS_SWAP = 4;
const switch_opcode_type_t SWITCH_MPLS_PUSH = 5;
const switch_opcode_type_t SWITCH_MPLS_SWAP_ENCAP = 6;
typedef bit<3> switch_exp_mode_t;
const switch_exp_mode_t SWITCH_EXP_MODE_MAP = 0;
const switch_exp_mode_t SWITCH_EXP_MODE_SET = 1;
const switch_exp_mode_t SWITCH_EXP_MODE_SWAP_KEEP = 2;
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
const switch_ptag_mod_t SWITCH_PTAG_MOD_RAW = 0;
const switch_ptag_mod_t SWITCH_PTAG_MOD_TAGGED = 1;
typedef bit<2> switch_ptag_action_t;
const switch_ptag_action_t VLANTAG_NONE_MODE = 0;
const switch_ptag_action_t VLANTAG_RAW_MODE = 1;
const switch_ptag_action_t VLANTAG_REPLACE_IF_PRESENT = 2;
const switch_ptag_action_t VLANTAG_NOREPLACE_IF_PRESENT = 3;
typedef bit<3> switch_tunnel_tc_t;
typedef bit<11> switch_ip_index_t;
@pa_solitary("ingress", "ig_md.tunnel.tmp_iif") struct switch_ingress_tunnel_metadata_t {
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
    bit<1>                  ttl_copy;
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
    bit<1>                  ttl_copy_1;
    bit<1>                  ttl_copy_2;
    bit<1>                  ttl_copy_3;
    bit<1>                  ttl_copy_4;
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
    switch_lif_t            tmp_iif;
    bool                    vxlan_l4_encap_flag;
    bit<48>                 dst_addr;
    bit<1>                  phpcopy;
    bit<4>                  opcode;
    switch_tunnel_encap_type_t encap_type;
}

struct switch_ingress_ebridge_metadata_t {
    switch_lif_t               l2iif;
    switch_lif_t               l2oif;
    bit<16>                    learning_l2iif;
    switch_evlan_t             evlan;
    switch_learning_metadata_t learning;
    switch_evlan_label_t       evlan_label;
}

@pa_atomic("ingress", "ig_md.route.l2_l3oif") struct switch_ingress_route_metadata_t {
    bit<13>      vrf;
    switch_lif_t l3oif;
    switch_lif_t l4_l3oif;
    bit<1>       set_l4_l3oif;
    switch_lif_t l3_l3oif;
    bit<1>       set_l3_l3oif;
    switch_lif_t l2_l3oif;
    bit<1>       set_l2_l3oif;
    bit<6>       l3_sid_cnt;
    bit<6>       sid_cnt;
    bit<16>      pmtu;
    bit<1>       set_pmtu;
    bool         g_l3mac_enable;
    bit<1>       rmac_hit;
    bit<8>       sip_l3class_id;
    bit<8>       dip_l3class_id;
    bit<14>      overlay_counter_index;
    bit<6>       nexthop_type;
    bit<2>       nexthop_cmd;
    bit<16>      mtu_check;
    bit<48>      ether_dstaddr;
    bit<4>       type;
    bit<8>       causeid;
    bit<8>       ttl_check;
    bit<4>      mpls_l3_encap_id_lo;
    bit<10>      mpls_l3_encap_id_hi;
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

@pa_container_size("ingress", "ig_md.policer.meter_id", 32) struct switch_ingress_policer_metadata_t {
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
    bit<16>                        meter_id;
    bit<1>                         drop;
    bit<1>                         mirror_enable;
    switch_lif_t                   iif;
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
    switch_pkt_color_t      color;
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
    bit<1>     usp;
    bool       srh_terminate;
    bool       sl_is_zero;
    bool       sl_is_one;
    bit<8>     seg_left;
    bit<8>     last_entry;
    bit<8>     hdr_ext_len;
    bit<1>     is_loopback;
}

typedef bit<16> switch_ipfix_t;
typedef bit<16> switch_ipfix_flow_id_t;
typedef bit<16> switch_ipfix_gap_t;
typedef bit<16> switch_ipfix_random_t;
typedef bit<16> switch_ipfix_random_mask_t;
typedef bit<16> switch_ipfix_random_flag_t;
typedef bit<16> switch_ipfix_count_t;
typedef bit<1> switch_ipfix_sample_flag_t;
typedef bit<10> switch_ipfix_session_t;
typedef bit<1> switch_ipfix_enable_t;
typedef bit<1> switch_ipfix_mode_t;
const switch_pkt_type_t SWITCH_IPFIX_PKT_TYPE_IPV4 = 1;
const switch_pkt_type_t SWITCH_IPFIX_PKT_TYPE_MPLS = 2;
const switch_pkt_type_t SWITCH_IPFIX_PKT_TYPE_IPV6 = 3;
const switch_pkt_type_t CPU_ETH_PKT_TYPE_IPFIX = 1;
const switch_pkt_type_t CPU_ETH_PKT_TYPE_BFD = 2;
const switch_pkt_type_t CPU_ETH_PKT_TYPE_PCAP = 3;
const switch_pkt_type_t CPU_ETH_PKT_TYPE_TRACE = 7;
const switch_pkt_type_t CPU_ETH_PKT_TYPE_IPFIX_SPEC_V4 = 9;
const switch_pkt_type_t CPU_ETH_PKT_TYPE_IPFIX_SPEC_V6 = 10;
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
    switch_ipfix_sample_flag_t ig_sample_flag;
    switch_ipfix_sample_flag_t eg_sample_flag;
    switch_ipfix_sample_flag_t sample_flag;
    switch_ipfix_sample_flag_t pcap_flag;
    switch_ipfix_session_t     session_id;
    bit<16>                    ether_type;
    bit<16>                    delta;
    bit<2>                     fwd_mode;
    bit<6>                     cpu_eth_encap_pkt_type;
    bit<1>                     dir;
}

@pa_no_overlay("egress", "eg_md.tunnel.ptag_vid") @pa_no_overlay("egress", "eg_md.tunnel.exp") @pa_no_overlay("egress", "eg_md.tunnel.vni") struct switch_egress_tunnel_metadata_t {
    switch_tunnel_type_t       type;
    switch_tunnel_type_t       evlan_type;
    bit<1>                     evlan_rmac_hit;
    switch_tunnel_encap_type_t encap_type;
    bool                       terminate;
    bit<1>                     bak_first;
    switch_next_hdr_type_t     next_hdr_type;
    bit<8>                     label_space;
    bit<8>                     ttl;
    bit<1>                     ilm;
    bit<1>                     ttl_copy;
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
    bit<16>                    l4_encap;
    bit<24>                    vni;
    switch_lif_t               tmp_l3iif;
    bit<4>                     srv6_end_type;
    bit<1>                     l3_encap_mapping_hit;
    bit<16>                    payload_len;
    bit<8>                     ip_proto;
    bit<16>                    gre_ether_type;
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
    bool                   anycast_en;
}

struct switch_egress_route_metadata_t {
    bit<13> vrf;
    bool    ipv4_unicast_enable;
    bool    ipv6_unicast_enable;
    bit<1>  rmac_hit;
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
    bit<14> mpls_l3_encap_id;
    bit<16> iptunnel_l3_encap_id;
    bit<8>  causeid;
    bit<8>  ttl_check;
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
    bit<1>                        drop;
    switch_pkt_color_t            meter_color;
    bit<1>                        mirror_enable;
    switch_lif_t                  iif;
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
    switch_pkt_color_t      color;
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

@pa_atomic("egress", "eg_md.policer.group_classid_1") @pa_atomic("egress", "eg_md.policer.group_classid_2") @pa_atomic("egress", "eg_md.policer.group_classid_3") @pa_atomic("egress", "eg_md.policer.group_classid_4") struct switch_egress_metadata_t {
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
    bit<1>            is_mirror;
    bit<1>            is_mcast;
}

header switch_bridged_metadata_base_encap_h {
    bit<8> data;
}

header switch_bridged_metadata_qos_encap_h {
    bit<8> data;
}

header switch_bridged_metadata_qos_h {
    bit<3> tc;
    bit<2> color;
    bit<1> chgDSCP_disable;
    bit<1> BA;
    bit<1> track;
}

header switch_bridged_metadata_12_encap_h {
    bit<8>       combine;
    bit<8>       src_port;
    bit<1>       pad;
    bit<1>       car_flag;
    switch_lif_t iif;
    bit<8>       ttl;
    bit<8>       label_space;
    bit<16>      hash;
    bit<16>      iif_type_evlan;
    bit<16>      egress_eport;
}

header switch_bridged_metadata_12_h {
    bit<1>            extend;
    bit<1>            rmac_hit;
    bit<1>            flowspec_disable;
    bit<1>            ttl_copy;
    bit<4>            srv6_end_type;
    bit<8>            src_port;
    bit<1>            pad;
    bit<1>            car_flag;
    switch_lif_t      iif;
    bit<8>            ttl;
    bit<8>            label_space;
    bit<16>           hash;
    switch_iif_type_t iif_type;
    bit<15>           evlan;
    bit<16>           egress_eport;
}

header switch_bridged_metadata_34_encap_h {
    bit<16> l2_encap;
    bit<16> l3_encap;
    bit<16> l4_encap;
}

header switch_bridged_metadata_34_h {
    bit<1>       extend;
    bit<1>       is_pbr_nhop;
    bit<1>       flowspec_disable;
    @padding
    bit<5>       pad;
    bit<8>       src_port;
    bit<16>      l2_encap;
    bit<16>      l3_encap;
    bit<16>      egress_eport;
    @padding
    bit<2>       pad_iif;
    switch_lif_t iif;
    bit<8>       dip_l3class_id;
    bit<8>       sip_l3class_id;
}

header switch_bridged_metadata_310_h {
    bit<8>       cpu_reason;
    bit<8>       src_port;
    bit<2>       pad_oif;
    switch_lif_t oif;
    bit<2>       pad_iif;
    switch_lif_t iif;
    bit<8>       dip_l3class_id;
    bit<8>       sip_l3class_id;
}

header switch_bridged_metadata_78_h {
    bit<1>       extend;
    bit<1>       pcp_chg;
    bit<1>       exp_chg;
    bit<1>       ippre_chg;
    bit<1>       is_from_cpu_pcie;
    @padding
    bit<3>       pad;
    bit<8>       dst_port;
    bit<16>      l2_encap;
    bit<16>      l3_encap;
    bit<16>      hash;
    bit<8>       sip_l3class_id;
    bit<8>       dip_l3class_id;
    bit<2>       pad_iif;
    switch_lif_t iif;
}

header switch_bridged_metadata_74_h {
    bit<16>      evlan;
    @padding
    bit<2>       pad_iif;
    switch_lif_t iif;
}

header switch_bridged_metadata_710_h {
    bit<8> dst_port;
}

header switch_bridged_metadata_910_encap_h {
    bit<16>              combine_16;
    bit<2>               pad_iif;
    switch_lif_t         iif;
    bit<2>               pad_oif;
    switch_lif_t         oif;
    switch_acl_classid_t group_classid_1;
    switch_acl_classid_t group_classid_2;
    bit<32>              l4_port_label_32;
}

header switch_bridged_metadata_910_h {
    bit<1>               drop;
    bit<2>               ip_frag;
    @padding
    bit<1>               pad;
    switch_acl_bypass_t  acl_bypass;
    bit<8>               dst_port;
    bit<2>               pad_iif;
    switch_lif_t         iif;
    bit<2>               pad_oif;
    switch_lif_t         oif;
    switch_acl_classid_t group_classid_1;
    switch_acl_classid_t group_classid_2;
    bit<32>              l4_port_label_32;
}

header switch_bridged_metadata_110_h {
    bit<8> dst_port;
}

header extension_eth_h {
    bit<16>      evlan;
    bit<2>       pad_oif;
    switch_lif_t l2oif;
}

header extension_tunnel_decap_data_encap_h {
    bit<32> data;
}

header extension_tunnel_decap_h {
    bit<3>                 ext_type;
    bit<1>                 extend;
    @padding
    bit<2>                 pad;
    switch_ext_data_type_t data_type;
    bit<3>                 tunnel_type;
    @padding
    bit<7>                 pad2;
    switch_lif_t           ul_iif;
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
    bool    bypass_L3;
    bit<2>  level;
    bit<1>  is_ecmp;
    bit<8>  priority;
    bit<16> nexthop;
    bit<8>  tc;
    bit<1>  set_dscp;
    @padding
    bit<7>  pad;
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
    bit<8> cpu_reason;
    bit<8> src_port;
}

header switch_port_mirror_metadata_h {
    switch_pkt_src_t        src;
    switch_mirror_type_t    type;
    bit<6>                  _pad;
    switch_mirror_session_t session_id;
    switch_logic_port_t     dst_port;
    switch_eport_t          dst_eport;
}

header switch_cpu_mirror_metadata_h {
    switch_pkt_src_t     src;
    switch_mirror_type_t type;
    @padding
    bit<7>               pad;
    bit<1>               track;
}

header switch_fabric_trace_mirror_metadata_h {
    switch_pkt_src_t           src;
    switch_mirror_type_t       type;
    switch_drop_reason_t       drop_reason;
    @padding
    bit<8>                     pad;
    switch_pipeline_location_t pipeline_location;
    bit<16>                    trace_counter;
}

header switch_ipfix_mirror_metadata_h {
    switch_pkt_src_t        src;
    switch_mirror_type_t    type;
    @padding
    bit<6>                  _pad1;
    switch_mirror_session_t session_id;
    @padding
    bit<2>                  pad_iif;
    switch_lif_t            iif;
    @padding
    bit<2>                  pad_oif;
    switch_lif_t            oif;
    bit<16>                 hash;
}

header switch_pcap_mirror_metadata_h {
    switch_pkt_src_t     src;
    switch_mirror_type_t type;
    bit<16>              cpu_code;
}

header switch_recirc_h {
    switch_logic_port_t src_port;
    switch_port_t       egress_port;
    bit<7>              pad;
    switch_eport_t      eport;
    bit<16>             ether_type;
}

@pa_no_overlay("egress", "hdr.mpls_vc_eg.label") @pa_no_overlay("egress", "hdr.mpls_vc_eg.ttl") struct switch_header_t {
    switch_bridged_src_h                 switch_bridged_src;
    fabric_base_h                        fabric_base;
    switch_bridged_metadata_base_h       bridged_md_base;
    switch_bridged_metadata_base_encap_h bridged_md_base_encap;
    fabric_qos_h                         fabric_qos;
    switch_bridged_metadata_qos_h        bridged_md_qos;
    switch_bridged_metadata_qos_encap_h  bridged_md_qos_encap;
    fabric_cpu_pcie_base_h               fabric_cpu_pcie_base;
    switch_bridged_metadata_12_encap_h   bridged_md_12_encap;
    switch_bridged_metadata_12_h         bridged_md_12;
    switch_bridged_metadata_34_encap_h   bridged_md_34_encap;
    switch_bridged_metadata_34_h         bridged_md_34;
    switch_bridged_metadata_310_h        bridged_md_310;
    switch_bridged_metadata_78_h         bridged_md_78;
    switch_bridged_metadata_74_h         bridged_md_74;
    switch_bridged_metadata_910_encap_h  bridged_md_910_encap;
    switch_bridged_metadata_910_h        bridged_md_910;
    switch_bridged_metadata_110_h        bridged_md_110;
    fabric_unicast_ext_bfn_igfpga_h      fabric_unicast_ext_bfn_igfpga;
    fabric_unicast_ext_igfpga_bfn_h      fabric_unicast_ext_igfpga_bfn;
    fabric_unicast_dst_encap_h           fabric_unicast_dst_encap;
    fabric_unicast_dst_h                 fabric_unicast_dst;
    fabric_unicast_ext_fe_encap_h        fabric_unicast_ext_fe_encap;
    fabric_unicast_ext_fe_h              fabric_unicast_ext_fe;
    fabric_var_ext_1_16bit_h             fabric_var_ext_1_16bit;
    fabric_var_ext_2_8bit_h              fabric_var_ext_2_8bit;
    fabric_multicast_src_h               fabric_multicast_src;
    fabric_multicast_ext_h               fabric_multicast_ext;
    fabric_unicast_ext_eg_encap_h        fabric_unicast_ext_eg_encap;
    fabric_unicast_ext_eg_h              fabric_unicast_ext_eg;
    fabric_cpu_data_h                    fabric_cpu_data;
    fabric_one_pad_h                     fabric_one_pad;
    fabric_var_ext_1_16bit_h             fabric_post_one_pad_encap;
    fabric_post_one_pad_h                fabric_post_one_pad;
    extension_srv6_h                     ext_srv6;
    extension_l4_nh_h                    ext_l4_nh;
    extension_cpp_h                      ext_cpp;
    extension_l4_encap_h                 ext_l4_encap;
    extension_tunnel_decap_data_encap_h  ext_tunnel_decap_data_encap;
    extension_tunnel_decap_h             ext_tunnel_decap;
    extension_eth_h                      ext_eth;
    ethernet_h                           ethernet;
    switch_recirc_h                      pri_data;
    fabric_to_cpu_eth_base_h             fabric_to_cpu_eth_base;
    fabric_to_cpu_eth_data_h             fabric_to_cpu_eth_data;
    fabric_from_cpu_eth_base_h           fabric_from_cpu_eth_base;
    fabric_from_cpu_eth_data_h           fabric_from_cpu_eth_data;
    fabric_payload_h                     fabric_eth_etype;
    timestamp_h                          timestamp;
    br_tag_h                             br_tag;
    vlan_tag_h[2]                        vlan_tag;
    mpls_h[6]                            mpls_ig;
    mpls_h[9]                            mpls_eg;
    mpls_h                               mpls_vc_eg;
    mpls_h                               mpls_flow_eg;
    drop_msg_h[2]                        drop_msg;
    pause_info_h                         pause_info;
    cw_h                                 cw;
    ipv4_h                               ipv4;
    ipv4_option_h                        ipv4_option;
    ipv6_h                               ipv6;
    ipv6_srh_h                           srv6_srh;
    srv6_list_h[10]                      srv6_list;
    arp_h                                arp;
    udp_h                                udp;
    icmp_h                               icmp;
    igmp_h                               igmp;
    tcp_h                                tcp;
    vxlan_h                              vxlan;
    gre_h                                gre;
    nvgre_h                              nvgre;
    geneve_h                             geneve;
    erspan_h                             erspan;
    erspan_type2_h                       erspan_type2;
    erspan_type3_h                       erspan_type3;
    erspan_platform_h                    erspan_platform;
    ethernet_h                           inner_ethernet;
    vlan_tag_h[2]                        inner_vlan_tag;
    ipv4_h                               inner_ipv4;
    ipv6_h                               inner_ipv6;
    udp_h                                inner_udp;
    tcp_h                                inner_tcp;
    icmp_h                               inner_icmp;
}

parser IgParser_front(packet_in pkt, out switch_header_t hdr, out switch_ingress_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        transition parse_port_metadata;
    }
    state parse_port_metadata {
        switch_port_metadata_frontpipe_t port_md = port_metadata_unpack<switch_port_metadata_frontpipe_t>(pkt);
        ig_md.common.port_type = port_md.port_type;
        transition parse_ethernet;
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
        transition accept;
    }
    state parse_vlan {
        pkt.extract(hdr.vlan_tag[0]);
        transition select(hdr.vlan_tag[0].ether_type) {
            0x800: parse_ipv4;
            0x8100: parse_vlan_1;
            0x86dd: parse_ipv6;
            0x8847: parse_mpls;
            default: accept;
        }
    }
    state parse_vlan_1 {
        pkt.extract(hdr.vlan_tag[1]);
        transition select(hdr.vlan_tag[1].ether_type) {
            0x800: parse_ipv4;
            0x86dd: parse_ipv6;
            0x8847: parse_mpls;
            default: accept;
        }
    }
    state parse_mpls {
        pkt.extract(hdr.mpls_ig.next);
        transition select(hdr.mpls_ig.last.bos) {
            0: parse_mpls;
            default: accept;
        }
    }
    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition accept;
    }
}

parser EgParser_front(packet_in pkt, out switch_header_t hdr, out switch_egress_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control IgDeparser_front(packet_out pkt, inout switch_header_t hdr, in switch_ingress_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr.bridged_md_34_encap);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.pri_data);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.mpls_ig);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.srv6_srh);
        pkt.emit(hdr.srv6_list);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.icmp);
        pkt.emit(hdr.igmp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.mpls_eg);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
    }
}

control EgDeparser_front(packet_out pkt, inout switch_header_t hdr, in switch_egress_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.pause_info);
        pkt.emit(hdr.fabric_to_cpu_eth_base);
        pkt.emit(hdr.fabric_to_cpu_eth_data);
        pkt.emit(hdr.fabric_eth_etype);
        pkt.emit(hdr.timestamp);
        pkt.emit(hdr.br_tag);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.icmp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.erspan);
        pkt.emit(hdr.erspan_type2);
        pkt.emit(hdr.erspan_type3);
        pkt.emit(hdr.erspan_platform);
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

control Forward(in ingress_intrinsic_metadata_t ig_intr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(switch_uint32_t port_table_size=512) {
    action hit(switch_port_t port) {
        ig_intr_md_for_tm.ucast_egress_port = port;
        ig_intr_md_for_tm.bypass_egress = 1;
    }
    table forward {
        key = {
            ig_intr_md.ingress_port: exact @name("ingress_port") ;
        }
        actions = {
            hit;
            NoAction;
        }
        const default_action = NoAction;
        size = port_table_size;
    }
    apply {
        forward.apply();
    }
}

control Nexthop(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md) {
    const switch_uint32_t overlay_nexthop_size = 65536;
    action set_overlay_nexthop_properties(bit<14> g_l3_encap) {
        ig_md.route.mpls_l3_encap_id_lo = g_l3_encap[13:10];
        ig_md.route.mpls_l3_encap_id_hi = g_l3_encap[9:0];
    }
    table overlay_nexthop {
        key = {
            hdr.ipv4.dst_addr: exact;
        }
        actions = {
            set_overlay_nexthop_properties;
        }
        const default_action = set_overlay_nexthop_properties(0);
        size = OVERLAY_NEXTHOP_TABLE_SIZE;
    }
    apply {
        overlay_nexthop.apply();
    }
}

control MPLS_tunnel_2_encap(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t tunnel2_table_size) {
    action push_tunnel_label_5(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[0].setValid();
        hdr.mpls_eg[0].label = label;
        hdr.mpls_eg[0].exp = exp;
        hdr.mpls_eg[0].bos = 0;
        hdr.mpls_eg[0].ttl = ttl;
    }
    action push_tunnel_label_6(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[1].setValid();
        hdr.mpls_eg[1].label = label;
        hdr.mpls_eg[1].exp = exp;
        hdr.mpls_eg[1].bos = 0;
        hdr.mpls_eg[1].ttl = ttl;
    }
    action push_tunnel_label_7(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[2].setValid();
        hdr.mpls_eg[2].label = label;
        hdr.mpls_eg[2].exp = exp;
        hdr.mpls_eg[2].bos = 0;
        hdr.mpls_eg[2].ttl = ttl;
    }
    action push_tunnel_label_8(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[3].setValid();
        hdr.mpls_eg[3].label = label;
        hdr.mpls_eg[3].exp = exp;
        hdr.mpls_eg[3].bos = 0;
        hdr.mpls_eg[3].ttl = ttl;
    }
    action push_tunnel_label_9(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[4].setValid();
        hdr.mpls_eg[4].label = label;
        hdr.mpls_eg[4].exp = exp;
        hdr.mpls_eg[4].bos = 0;
        hdr.mpls_eg[4].ttl = ttl;
    }
    action push_tunnel_five_labels(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode, bit<20> label1, bit<20> label2, bit<20> label3, bit<20> label4, bit<3> label_num) {
        push_tunnel_label_5(label0, exp0, ttl0);
        push_tunnel_label_6(label1, exp0, ttl0);
        push_tunnel_label_7(label2, exp0, ttl0);
        push_tunnel_label_8(label3, label_num, ttl0);
        push_tunnel_label_9(label4, exp_mode, ttl0);
    }
    @use_hash_action(1) table mpls_tunnel2_rewrite {
        key = {
            ig_md.route.mpls_l3_encap_id_lo: exact;
            ig_md.route.mpls_l3_encap_id_hi: exact;
        }
        actions = {
            push_tunnel_five_labels;
        }
        const default_action = push_tunnel_five_labels(0, 0, 0, 0, 0, 0, 0, 0, 0);
        size = tunnel2_table_size;
    }
    apply {
        mpls_tunnel2_rewrite.apply();
    }
}

control Ig_front(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    Forward() forward;
    Nexthop() nexthop;
    MPLS_tunnel_2_encap(16384) mpls_tunnel2_rewrite;
    apply {
        forward.apply(ig_intr_md, ig_intr_md_for_tm);
        nexthop.apply(hdr, ig_md);
        mpls_tunnel2_rewrite.apply(hdr, ig_md);
    }
}

control Eg_front(inout switch_header_t hdr, inout switch_egress_metadata_t ig_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

Pipeline(IgParser_front(), Ig_front(), IgDeparser_front(), EgParser_front(), Eg_front(), EgDeparser_front()) pp_front;

Switch(pp_front) main;

