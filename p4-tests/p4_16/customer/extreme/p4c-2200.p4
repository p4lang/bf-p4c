#include <tna.p4>

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
}
header igmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
}
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
}
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
}
header fcoe_fc_h {
    bit<4> version;
    bit<100> reserved;
    bit<8> sof;
    bit<8> r_ctl;
    bit<24> d_id;
    bit<8> cs_ctl;
    bit<24> s_id;
    bit<8> type;
    bit<24> f_ctl;
    bit<8> seq_id;
    bit<8> df_ctl;
    bit<16> seq_cnt;
    bit<16> ox_id;
    bit<16> rx_id;
}
header ipv6_srh_h {
    bit<8> next_hdr;
    bit<8> hdr_ext_len;
    bit<8> routing_type;
    bit<8> seg_left;
    bit<8> last_entry;
    bit<8> flags;
    bit<16> tag;
}
header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}
header vxlan_gpe_h {
    bit<8> flags;
    bit<16> reserved;
    bit<24> vni;
    bit<8> reserved2;
}
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
header nvgre_h {
    bit<24> vsid;
    bit<8> flow_id;
}
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
header dtel_drop_report_h {
    bit<7> pad0;
    bit<9> ingress_port;
    bit<7> pad1;
    bit<9> egress_port;
    bit<3> pad2;
    bit<5> queue_id;
    bit<8> drop_reason;
    bit<16> reserved;
}
header dtel_switch_local_report_h {
    bit<7> pad0;
    bit<9> ingress_port;
    bit<7> pad1;
    bit<9> egress_port;
    bit<3> pad2;
    bit<5> queue_id;
    bit<5> pad3;
    bit<19> queue_occupancy;
    bit<32> timestamp;
}
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
struct dtel_report_metadata_0 {
    bit<16> ingress_port;
    bit<16> egress_port;
}
struct dtel_report_metadata_2 {
    bit<8> queue_id;
    bit<24> queue_occupancy;
}
struct dtel_report_metadata_3 {
    bit<32> timestamp;
}
struct dtel_report_metadata_4 {
    bit<8> queue_id;
    bit<8> drop_reason;
    bit<16> reserved;
}
header fabric_h {
    bit<8> reserved;
    bit<3> color;
    bit<5> qos;
    bit<8> reserved2;
    bit<16> dst_port_or_group;
}
header cpu_h {
    bit<5> egress_queue;
    bit<1> tx_bypass;
    bit<1> capture_ts;
    bit<1> reserved;
    bit<16> ingress_port;
    bit<16> ingress_ifindex;
    bit<16> ingress_bd;
    bit<16> reason_code;
    bit<16> ether_type;
}
header timestamp_h {
    bit<48> timestamp;
}
header ethernet_tagged_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
    bit<3> tag_pcp;
    bit<1> tag_cfi;
    vlan_id_t tag_vid;
    bit<16> ether_type_tag;
}
header spbm_h {
    bit<3> pcp;
    bit<1> dei;
    bit<1> uca;
    bit<1> res1;
    bit<2> res2;
    bit<24> isid;
}
header erspan_type1_h {
    bit<4> version;
    bit<12> vlan;
    bit<6> cos_en_t;
    bit<10> session_id;
    bit<12> reserved;
    bit<20> index;
}
header erspan_type2_h {
    bit<32> seq_num;
    bit<4> version;
    bit<12> vlan;
    bit<6> cos_en_t;
    bit<10> session_id;
    bit<12> reserved;
    bit<20> index;
}
header erspan_type3_h {
    bit<4> version;
    bit<12> vlan;
    bit<6> cos_bso_t;
    bit<10> session_id;
    bit<32> timestamp;
    bit<16> sgt;
    bit<1> p;
    bit<5> ft;
    bit<6> hw_id;
    bit<1> d;
    bit<2> gra;
    bit<1> o;
}
header erspan_platform_h {
    bit<6> id;
    bit<58> info;
}
header nsh_base_h {
    bit<2> version;
    bit<1> o;
    bit<1> reserved;
    bit<6> ttl;
    bit<6> len;
    bit<4> reserved2;
    bit<4> md_type;
    bit<8> next_proto;
}
header nsh_svc_path_h {
    bit<24> spi;
    bit<8> si;
}
header nsh_md1_context_h {
    bit<128> md;
}
header nsh_md2_context_fixed_h {
    bit<16> md_class;
    bit<8> type;
    bit<1> reserved;
    bit<7> len;
}
header nsh_extr_h {
    bit<2> version;
    bit<1> o;
    bit<1> reserved;
    bit<6> ttl;
    bit<6> len;
    bit<4> reserved2;
    bit<4> md_type;
    bit<8> next_proto;
    bit<24> spi;
    bit<8> si;
    bit<16> md_class;
    bit<8> type;
    bit<1> reserved3;
    bit<7> md_len;
    bit<8> extr_sf_bitmask;
    bit<16> extr_tenant_id;
    bit<8> extr_flow_type;
    bit<32> extr_rsvd;
}
struct nsh_extr_internal_lkp_t {
    bit<1> valid;
    bool terminate;
    bit<24> spi;
    bit<8> si;
    bit<8> extr_sf_bitmask_local;
    bit<8> extr_sf_bitmask_remote;
    bit<16> extr_tenant_id;
    bit<8> extr_flow_type;
}
header e_tag_h {
    bit<3> pcp;
    bit<1> dei;
    bit<12> ingress_cid_base;
    bit<2> rsvd_0;
    bit<2> grp;
    bit<12> cid_base;
    bit<16> rsvd_1;
    bit<16> ether_type;
}
header vn_tag_h {
    bit<1> dir;
    bit<1> ptr;
    bit<14> dvif_id;
    bit<1> loop;
    bit<3> rsvd;
    bit<12> svif_id;
    bit<16> ether_type;
}
header sctp_h {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> verifTag;
    bit<32> checksum;
}
header mpls_pw_cw_h {
    bit<4> zeros;
    bit<12> rsvd;
    bit<16> seqNum;
}
header udf_h {
    bit<88> opaque;
}
header esp_h {
    bit<32> spi;
    bit<32> seq_num;
}
header gtp_v1_base_h {
    bit<3> version;
    bit<1> PT;
    bit<1> reserved;
    bit<1> E;
    bit<1> S;
    bit<1> PN;
    bit<8> msg_type;
    bit<16> msg_len;
}
header gtp_v2_base_h {
    bit<3> version;
    bit<1> P;
    bit<1> T;
    bit<3> reserved;
    bit<8> msg_type;
    bit<16> msg_len;
}
header gtp_v1_v2_teid_h {
    bit<32> teid;
}
header gtp_v1_optional_h {
    bit<16> seq_num;
    bit<8> n_pdu_num;
    bit<8> next_ext_hdr_type;
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
const switch_cpu_reason_t SWITCH_CPU_REASON_PTP = 8;
struct switch_cpu_port_value_set_t {
    bit<16> ether_type;
    bit<9> port;
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
const switch_drop_reason_t SWITCH_DROP_REASON_UNDERLAY_NSH_VERSION_INVALID = 110;
const switch_drop_reason_t SWITCH_DROP_REASON_UNDERLAY_NSH_OAM = 111;
const switch_drop_reason_t SWITCH_DROP_REASON_UNDERLAY_NSH_TTL_ZERO = 112;
const switch_drop_reason_t SWITCH_DROP_REASON_UNDERLAY_NSH_LEN_INVALID = 113;
const switch_drop_reason_t SWITCH_DROP_REASON_UNDERLAY_NSH_MDTYPE_INVALID = 114;
const switch_drop_reason_t SWITCH_DROP_REASON_UNDERLAY_NSH_NEXT_PROTO_INVALID = 115;
const switch_drop_reason_t SWITCH_DROP_REASON_UNDERLAY_NSH_SI_ZERO = 116;
const switch_drop_reason_t SWITCH_DROP_REASON_UNDERLAY_NSH_MD_LEN_INVALID = 117;
typedef bit<1> switch_port_type_t;
const switch_port_type_t SWITCH_PORT_TYPE_NORMAL = 0;
const switch_port_type_t SWITCH_PORT_TYPE_CPU = 1;
typedef bit<2> switch_ip_type_t;
const switch_ip_type_t SWITCH_IP_TYPE_NONE = 0;
const switch_ip_type_t SWITCH_IP_TYPE_IPV4 = 1;
const switch_ip_type_t SWITCH_IP_TYPE_IPV6 = 2;
typedef bit<2> switch_ip_frag_t;
const switch_ip_frag_t SWITCH_IP_FRAG_NON_FRAG = 0b00;
const switch_ip_frag_t SWITCH_IP_FRAG_HEAD = 0b10;
const switch_ip_frag_t SWITCH_IP_FRAG_NON_HEAD = 0b11;
typedef bit<16> switch_ingress_bypass_t;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L2 = 16w0x0001;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L3 = 16w0x0002;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ACL = 16w0x0004;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SYSTEM_ACL = 16w0x0008;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_QOS = 16w0x0010;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_POLICER = 16w0x0020;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STORM_CONTROL = 16w0x0040;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STP = 16w0x0080;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SMAC = 16w0x0100;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ALL = 16w0xffff;
typedef bit<8> switch_egress_bypass_t;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_REWRITE = 8w0x01;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_ACL = 8w0x02;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_SYSTEM_ACL = 8w0x04;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_QOS = 8w0x08;
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
    switch_qos_trust_mode_t trust_mode;
    switch_qos_group_t group;
    switch_tc_t tc;
    switch_pkt_color_t color;
    switch_pkt_color_t acl_policer_color;
    switch_pkt_color_t port_color;
    switch_pkt_color_t flow_color;
    switch_pkt_color_t storm_control_color;
    switch_policer_meter_index_t meter_index;
    switch_policer_meter_index_t ingress_flow_meter_index;
    switch_qid_t qid;
    switch_ingress_cos_t icos;
    bit<19> qdepth;
}
typedef bit<1> switch_learning_mode_t;
const switch_learning_mode_t SWITCH_LEARNING_MODE_DISABLED = 0;
const switch_learning_mode_t SWITCH_LEARNING_MODE_LEARN = 1;
struct switch_learning_digest_t {
    switch_bd_t bd;
    switch_ifindex_t ifindex;
    mac_addr_t src_addr;
}
struct switch_learning_metadata_t {
    switch_learning_mode_t bd_mode;
    switch_learning_mode_t port_mode;
    switch_learning_digest_t digest;
}
typedef bit<2> switch_multicast_mode_t;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_NONE = 0;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_SM = 1;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_BIDIR = 2;
typedef MulticastGroupId_t switch_mgid_t;
typedef bit<16> switch_multicast_rpf_group_t;
struct switch_multicast_metadata_t {
    switch_mgid_t id;
    bit<2> mode;
    switch_multicast_rpf_group_t rpf_group;
}
typedef bit<2> switch_urpf_mode_t;
const switch_urpf_mode_t SWITCH_URPF_MODE_NONE = 0;
const switch_urpf_mode_t SWITCH_URPF_MODE_LOOSE = 1;
const switch_urpf_mode_t SWITCH_URPF_MODE_STRICT = 2;
typedef bit<8> switch_wred_index_t;
typedef bit<2> switch_ecn_codepoint_t;
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_NON_ECT = 0b00;
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_ECT0 = 0b10;
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_ECT1 = 0b01;
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_CE = 0b11;
typedef MirrorId_t switch_mirror_session_t;
const switch_mirror_session_t SWITCH_MIRROR_SESSION_CPU = 250;
typedef bit<8> switch_mirror_type_t;
struct switch_mirror_metadata_t {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    switch_mirror_session_t session_id;
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
    bit<7> _pad;
    switch_port_t port;
    switch_bd_t bd;
    switch_ifindex_t ifindex;
    switch_cpu_reason_t reason_code;
}
enum switch_tunnel_mode_t { PIPE, UNIFORM }
typedef bit<3> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NONE = 0;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VXLAN = 1;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPINIP = 2;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_MACINMAC = 3;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NVGRE = 4;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTPC = 5;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTPU = 6;
enum switch_tunnel_term_mode_t { P2P, P2MP };
typedef bit<16> switch_tunnel_index_t;
typedef bit<32> switch_tunnel_id_t;
struct switch_tunnel_metadata_t {
    switch_tunnel_type_t type;
    switch_tunnel_index_t index;
    switch_tunnel_id_t id;
 bit<8> flow_id;
    switch_ifindex_t ifindex;
    bit<16> hash;
    bool terminate;
}
typedef bit<4> switch_dtel_report_type_t;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_NONE = 0b000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_DROP = 0b100;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_QUEUE = 0b010;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_FLOW = 0b001;
const switch_dtel_report_type_t SWITCH_DTEL_SUPPRESS_REPORT = 0b1000;
struct switch_dtel_metadata_t {
    switch_dtel_report_type_t report_type;
    bit<32> latency;
    switch_mirror_session_t session_id;
    bit<32> hash;
}
header switch_dtel_switch_local_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    bit<48> timestamp;
    bit<6> _pad;
    switch_mirror_session_t session_id;
    bit<32> hash;
    bit<4> _pad1;
    switch_dtel_report_type_t report_type;
    bit<7> _pad2;
    bit<9> ingress_port;
    bit<7> _pad3;
    bit<9> egress_port;
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
    bit<4> _pad1;
    switch_dtel_report_type_t report_type;
    bit<7> _pad2;
    bit<9> ingress_port;
    bit<7> _pad3;
    bit<9> egress_port;
    bit<3> _pad4;
    switch_qid_t qid;
    switch_drop_reason_t drop_reason;
}
@flexible
struct switch_bridged_metadata_dtel_extension_t {
    switch_dtel_report_type_t report_type;
    switch_mirror_session_t session_id;
    bit<32> hash;
    bit<9> egress_port;
}
@pa_container_size("ingress", "ig_md.checks.same_if", 16)
@pa_container_size("ingress", "ig_md.checks.same_bd", 16)
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
    switch_bd_t same_bd;
    switch_ifindex_t same_if;
    bool mrpf;
    bool urpf;
}
struct switch_egress_checks_t {
    switch_bd_t same_bd;
    switch_mtu_t mtu;
    bool stp;
}
struct switch_ip_metadata_t {
    bool unicast_enable;
    bool multicast_enable;
    bool multicast_snooping;
}
struct switch_lookup_fields_t {
    switch_pkt_type_t pkt_type;
    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<16> mac_type;
    bit<3> pcp;
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
@flexible
struct switch_bridged_metadata_t {
    switch_port_t ingress_port;
    switch_ifindex_t ingress_ifindex;
    switch_bd_t ingress_bd;
    switch_nexthop_t nexthop;
    switch_pkt_type_t pkt_type;
    bool routed;
    bool peer_link;
    switch_cpu_reason_t cpu_reason;
    bit<48> timestamp;
    switch_tc_t tc;
    switch_qid_t qid;
    switch_pkt_color_t color;
    bit<1> orig_pkt_had_nsh;
    bit<1> nsh_extr_valid;
    bool nsh_extr_terminate;
    bit<24> nsh_extr_spi;
    bit<8> nsh_extr_si;
    bit<8> nsh_extr_sf_bitmask_local;
    bit<8> nsh_extr_sf_bitmask_remote;
    bit<16> nsh_extr_tenant_id;
    bit<8> nsh_extr_flow_type;
}
@flexible
struct switch_bridged_metadata_acl_extension_t {
    bit<16> l4_src_port;
    bit<16> l4_dst_port;
    bit<8> tcp_flags;
    switch_l4_port_label_t l4_port_label;
}
@flexible
struct switch_bridged_metadata_tunnel_extension_t {
    switch_tunnel_index_t index;
    switch_outer_nexthop_t outer_nexthop;
    bit<16> hash;
    switch_vrf_t vrf;
    bool terminate;
}
typedef bit<8> switch_bridge_type_t;
header switch_bridged_metadata_h {
    switch_pkt_src_t src;
    switch_bridge_type_t type;
    switch_bridged_metadata_t base;
    switch_bridged_metadata_tunnel_extension_t tunnel;
}
struct switch_port_metadata_t {
    switch_port_lag_index_t port_lag_index;
    switch_port_lag_label_t port_lag_label;
    switch_ifindex_t ifindex;
}
@pa_container_size("ingress", "ig_md.lkp.l4_src_port", 8)
@pa_container_size("ingress", "ig_md.l4_port_label", 8)
@pa_container_size("ingress", "ig_md.mirror.src", 8)
@pa_container_size("ingress", "ig_md.mirror.type", 8)
@pa_alias("ingress", "ig_md.egress_port", "ig_intr_md_for_tm.ucast_egress_port")
@pa_alias("ingress", "ig_md.multicast.id", "ig_intr_md_for_tm.mcast_grp_b")
@pa_alias("ingress", "ig_md.qos.qid", "ig_intr_md_for_tm.qid")
@pa_alias("ingress", "ig_md.qos.icos", "ig_intr_md_for_tm.ingress_cos")
@pa_container_size("egress", "hdr.dtel_drop_report.drop_reason", 8)
@pa_alias("ingress", "ig_intr_md_for_dprsr.mirror_type", "ig_md.mirror.type")
struct switch_ingress_metadata_t {
    switch_ifindex_t ifindex;
    switch_port_t port;
    switch_port_t egress_port;
    switch_port_lag_index_t port_lag_index;
    switch_ifindex_t egress_ifindex;
    switch_port_lag_index_t egress_port_lag_index;
    switch_bd_t bd;
    switch_vrf_t vrf;
    switch_nexthop_t nexthop;
    switch_outer_nexthop_t outer_nexthop;
    switch_nexthop_t acl_nexthop;
    bool acl_redirect;
    bit<48> timestamp;
    bit<32> hash;
    switch_ingress_flags_t flags;
    switch_ingress_checks_t checks;
    switch_ingress_bypass_t bypass;
    switch_ip_metadata_t ipv4;
    switch_ip_metadata_t ipv6;
    switch_port_lag_label_t port_lag_label;
    switch_bd_label_t bd_label;
    switch_if_label_t if_label;
    switch_l4_port_label_t l4_port_label;
    switch_drop_reason_t drop_reason;
    switch_cpu_reason_t cpu_reason;
    switch_rmac_group_t rmac_group;
    switch_lookup_fields_t lkp;
    switch_multicast_metadata_t multicast;
    switch_stp_metadata_t stp;
    switch_qos_metadata_t qos;
    switch_tunnel_metadata_t tunnel;
    switch_learning_metadata_t learning;
    switch_mirror_metadata_t mirror;
    switch_dtel_metadata_t dtel;
    bit<1> orig_pkt_had_nsh;
    nsh_extr_internal_lkp_t nsh_extr;
}
@pa_container_size("egress", "eg_md.mirror.src", 8)
@pa_container_size("egress", "eg_md.mirror.type", 8)
struct switch_egress_metadata_t {
    switch_pkt_src_t pkt_src;
    switch_pkt_length_t pkt_length;
    switch_pkt_type_t pkt_type;
    switch_port_lag_index_t port_lag_index;
    switch_port_type_t port_type;
    switch_port_t port;
    switch_port_t ingress_port;
    switch_ifindex_t ingress_ifindex;
    switch_bd_t bd;
    switch_vrf_t vrf;
    switch_nexthop_t nexthop;
    switch_outer_nexthop_t outer_nexthop;
    bit<32> timestamp;
    bit<48> ingress_timestamp;
    switch_egress_flags_t flags;
    switch_egress_checks_t checks;
    switch_egress_bypass_t bypass;
    switch_port_lag_label_t port_lag_label;
    switch_bd_label_t bd_label;
    switch_if_label_t if_label;
    switch_l4_port_label_t l4_port_label;
    switch_lookup_fields_t lkp;
    switch_qos_metadata_t qos;
    switch_tunnel_metadata_t tunnel;
    switch_tunnel_metadata_t tunnel_nsh;
    switch_mirror_metadata_t mirror;
    switch_dtel_metadata_t dtel;
    switch_cpu_reason_t cpu_reason;
    switch_drop_reason_t drop_reason;
    bit<1> orig_pkt_had_nsh;
    nsh_extr_internal_lkp_t nsh_extr;
    bit<5> action_bitmask;
    bit<10 > action_3_meter_id;
    bit<8> action_3_meter_overhead;
}
struct switch_mirror_metadata_h {
    switch_port_mirror_metadata_h port;
    switch_cpu_mirror_metadata_h cpu;
    switch_dtel_drop_mirror_metadata_h dtel_drop;
    switch_dtel_switch_local_mirror_metadata_h dtel_switch_local;
}
struct switch_header_t {
    switch_bridged_metadata_h bridged_md;
    ethernet_h ethernet;
    e_tag_h e_tag;
    vn_tag_h vn_tag;
    fabric_h fabric;
    cpu_h cpu;
    timestamp_h timestamp;
    vlan_tag_h[2] vlan_tag;
    mpls_h[4] mpls;
    ipv4_h ipv4;
    ipv4_option_h ipv4_option;
    ipv6_h ipv6;
    arp_h arp;
    udp_h udp;
    icmp_h icmp;
    igmp_h igmp;
    tcp_h tcp;
    dtel_report_v05_h dtel;
    dtel_switch_local_report_h dtel_switch_local_report;
    dtel_drop_report_h dtel_drop_report;
    rocev2_bth_h rocev2_bth;
    vxlan_h vxlan;
    gre_h gre;
    nvgre_h nvgre;
    geneve_h geneve;
    erspan_type2_h erspan_type2;
    erspan_type3_h erspan_type3;
    erspan_platform_h erspan_platform;
    ethernet_h ethernet_underlay;
    vlan_tag_h[1] vlan_tag_underlay;
    nsh_extr_h nsh_extr_underlay;
    sctp_h sctp;
    esp_h esp;
    gtp_v1_base_h gtp_v1_base;
    gtp_v2_base_h gtp_v2_base;
    gtp_v1_v2_teid_h gtp_v1_v2_teid;
    gtp_v1_optional_h gtp_v1_optional;
    udf_h udf;
    ethernet_h inner_ethernet;
    ipv4_h inner_ipv4;
    ipv6_h inner_ipv6;
    udp_h inner_udp;
    tcp_h inner_tcp;
    icmp_h inner_icmp;
    vlan_tag_h inner_vlan_tag;
    arp_h inner_arp;
    sctp_h inner_sctp;
    gre_h inner_gre;
    esp_h inner_esp;
    igmp_h inner_igmp;
    udf_h inner_udf;
}
const bit<32> PORT_TABLE_SIZE = 288 * 2;
const bit<32> VLAN_TABLE_SIZE = 4096;
const bit<32> BD_FLOOD_TABLE_SIZE = VLAN_TABLE_SIZE * 4;
const bit<32> PORT_VLAN_TABLE_SIZE = 1024;
const bit<32> DOUBLE_TAG_TABLE_SIZE = 4096;
const bit<32> BD_TABLE_SIZE = 5120;
const bit<32> MAC_TABLE_SIZE = 16384;
const bit<32> IPV4_LPM_TABLE_SIZE = 16384;
const bit<32> IPV6_LPM_TABLE_SIZE = 1024;
const bit<32> IPV4_HOST_TABLE_SIZE = 32768;
const bit<32> IPV6_HOST_TABLE_SIZE = 8192;
const bit<32> IPV4_MULTICAST_STAR_G_TABLE_SIZE = 2048;
const bit<32> IPV4_MULTICAST_S_G_TABLE_SIZE = 4096;
const bit<32> IPV6_MULTICAST_STAR_G_TABLE_SIZE = 512;
const bit<32> IPV6_MULTICAST_S_G_TABLE_SIZE = 512;
const bit<32> RID_TABLE_SIZE = 4096;
const bit<32> DEST_TUNNEL_TABLE_SIZE = 512;
const bit<32> IPV4_SRC_TUNNEL_TABLE_SIZE = 4096;
const bit<32> IPV6_SRC_TUNNEL_TABLE_SIZE = 1024;
const bit<32> VNI_MAPPING_TABLE_SIZE = 4096;
const bit<32> TUNNEL_SRC_REWRITE_TABLE_SIZE = 512;
const bit<32> TUNNEL_DST_REWRITE_TABLE_SIZE = 4096;
const bit<32> TUNNEL_SMAC_REWRITE_TABLE_SIZE = 512;
const bit<32> TUNNEL_DMAC_REWRITE_TABLE_SIZE = 4096;
const bit<32> TUNNEL_REWRITE_TABLE_SIZE = 512;
const bit<32> ECMP_GROUP_TABLE_SIZE = 1024;
const bit<32> OUTER_ECMP_GROUP_TABLE_SIZE = 4096;
const bit<32> ECMP_SELECT_TABLE_SIZE = 16384;
const bit<32> NEXTHOP_TABLE_SIZE = 32768;
const bit<32> OUTER_NEXTHOP_TABLE_SIZE = 4096;
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_MIRROR_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_MAC_QOS_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_QOS_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV6_QOS_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_L4_PORT_LOU_TABLE_SIZE = 16 / 2;
const bit<32> IPV4_RACL_TABLE_SIZE = 512;
const bit<32> IPV6_RACL_TABLE_SIZE = 512;
const bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512;
const bit<32> WRED_SIZE = 1 << 8;
const bit<32> COPP_METER_SIZE = 1 << 8;
const bit<32> COPP_DROP_TABLE_SIZE = 1 << (8 + 1);
const bit<32> DSCP_TO_TC_TABLE_SIZE = 1024;
const bit<32> PCP_TO_TC_TABLE_SIZE = 1024;
const bit<32> QUEUE_TABLE_SIZE = 1024;
const bit<32> EGRESS_QOS_MAP_TABLE_SIZE = 1024;
const bit<32> INGRESS_POLICER_TABLE_SIZE = 1 << 10;
const bit<32> STORM_CONTROL_TABLE_SIZE = 512;
const bit<32> INGRESS_SYSTEM_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_SYSTEM_ACL_TABLE_SIZE = 512;
const bit<32> DROP_STATS_TABLE_SIZE = 1 << 8;
const bit<32> L3_MTU_TABLE_SIZE = 1024;
const bit<32> NPB_ING_SFC_FLOW_TYPE_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SFC_NSH_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SFC_SCHD_TABLE_PART1_DEPTH = 1024;
const bit<32> NPB_ING_SFC_SCHD_TABLE_PART2_DEPTH = 1024;
const bit<32> NPB_ING_SFF_ARP_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L2_TABLE_DEPTH = 512;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L3_V4_TABLE_DEPTH = 512;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L3_V6_TABLE_DEPTH = 512;
const bit<32> NPB_ING_SF_0_BAS_ADV_SCHD_TABLE_PART1_DEPTH = 1024;
const bit<32> NPB_ING_SF_0_BAS_ADV_SCHD_TABLE_PART2_DEPTH = 1024;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_TABLE_DEPTH = 1024;
const bit<32> OUTER_ECMP_SELECT_TABLE_SIZE = 16384;
const bit<32> NUM_TUNNELS = 4096;
Hash<bit<32>>(HashAlgorithm_t.CRC32) ip_hash;
Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;
action compute_ip_hash(in switch_lookup_fields_t lkp, out bit<32> hash) {
    hash = ip_hash.get({lkp.ip_src_addr,
                        lkp.ip_dst_addr,
                        lkp.ip_proto,
                        lkp.l4_dst_port,
                        lkp.l4_src_port});
}
action compute_non_ip_hash(in switch_lookup_fields_t lkp, out bit<32> hash) {
    hash = non_ip_hash.get({lkp.mac_type, lkp.mac_src_addr, lkp.mac_dst_addr});
}
action add_bridged_md(
        inout switch_bridged_metadata_h bridged_md, in switch_ingress_metadata_t ig_md) {
    bridged_md.setValid();
    bridged_md.src = SWITCH_PKT_SRC_BRIDGED;
    bridged_md.base = {
        ig_md.port, ig_md.ifindex, ig_md.bd, ig_md.nexthop, ig_md.lkp.pkt_type,
        ig_md.flags.routed, ig_md.flags.peer_link, ig_md.cpu_reason,
        ig_md.timestamp, ig_md.qos.tc, ig_md.qos.qid, ig_md.qos.color,
        ig_md.orig_pkt_had_nsh,
        ig_md.nsh_extr.valid,
        ig_md.nsh_extr.terminate,
        ig_md.nsh_extr.spi,
        ig_md.nsh_extr.si,
        ig_md.nsh_extr.extr_sf_bitmask_local,
        ig_md.nsh_extr.extr_sf_bitmask_remote,
        ig_md.nsh_extr.extr_tenant_id,
        ig_md.nsh_extr.extr_flow_type
    };
    bridged_md.tunnel = {ig_md.tunnel.index,
                         ig_md.outer_nexthop,
                         ig_md.hash[15:0],
                         ig_md.vrf,
                         ig_md.tunnel.terminate};
}
action set_ig_intr_md(in switch_ingress_metadata_t ig_md,
                      inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                      inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    ig_intr_md_for_tm.mcast_grp_b = ig_md.multicast.id;
    ig_intr_md_for_tm.level2_mcast_hash = ig_md.hash[28:16];
}
action set_eg_intr_md(in switch_egress_metadata_t eg_md,
                      inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                      inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    eg_intr_md_for_dprsr.mirror_type = (bit<3>) eg_md.mirror.type;
}
action ingress_acl_deny(inout switch_ingress_metadata_t ig_md,
                        inout switch_stats_index_t index,
                        switch_stats_index_t stats_index) {
    index = stats_index;
    ig_md.flags.acl_deny = true;
}
action ingress_acl_permit(inout switch_ingress_metadata_t ig_md,
                          inout switch_stats_index_t index,
                          switch_stats_index_t stats_index) {
    index = stats_index;
    ig_md.flags.acl_deny = false;
}
action ingress_acl_redirect(inout switch_ingress_metadata_t ig_md,
                            inout switch_stats_index_t index,
                            inout switch_nexthop_t nexthop,
                            switch_nexthop_t nexthop_index,
                            switch_stats_index_t stats_index) {
    index = stats_index;
    ig_md.flags.acl_deny = false;
}
action ingress_acl_mirror(inout switch_ingress_metadata_t ig_md,
                          inout switch_stats_index_t index,
                          switch_stats_index_t stats_index,
                          switch_mirror_session_t session_id) {
}
action egress_acl_deny(inout switch_egress_metadata_t eg_md,
                        inout switch_stats_index_t index,
                        switch_stats_index_t stats_index) {
    index = stats_index;
    eg_md.flags.acl_deny = true;
}
action egress_acl_permit(inout switch_egress_metadata_t eg_md,
                         inout switch_stats_index_t index,
                         switch_stats_index_t stats_index) {
    index = stats_index;
    eg_md.flags.acl_deny = false;
}
action egress_acl_mirror(inout switch_egress_metadata_t eg_md,
                         inout switch_stats_index_t index,
                         switch_stats_index_t stats_index,
                         switch_mirror_session_t session_id) {
}
control IngressIpAcl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index,
        out switch_nexthop_t nexthop)(
        switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.mac_type : ternary; lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
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
control IngressIpv4Acl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index,
        out switch_nexthop_t nexthop)(
        switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.ip_src_addr[31:0] : ternary; lkp.ip_dst_addr[31:0] : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.ip_frag : ternary; lkp.tcp_flags : ternary;
            lkp.mac_type : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
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
control IngressIpv6Acl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index,
        out switch_nexthop_t nexthop)(
        switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
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
control IngressMacAcl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index,
        out switch_nexthop_t nexthop)(
        switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.mac_src_addr : ternary; lkp.mac_dst_addr : ternary; lkp.mac_type : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
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
control LOU(in bit<16> src_port,
            in bit<16> dst_port,
            inout bit<8> tcp_flags,
            out switch_l4_port_label_t port_label) {
    const switch_uint32_t table_size = 16 / 2;
    action set_src_port_label(bit<8> label) {
        port_label[7:0] = label;
    }
    action set_dst_port_label(bit<8> label) {
        port_label[15:8] = label;
    }
    @entries_with_ranges(table_size)
    table l4_dst_port {
        key = {
            dst_port : range;
        }
        actions = {
            NoAction;
            set_dst_port_label;
        }
        const default_action = NoAction;
        size = table_size;
    }
    @entries_with_ranges(table_size)
    table l4_src_port {
        key = {
            src_port : range;
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
        key = { tcp_flags : exact; }
        actions = {
            NoAction;
            set_tcp_flags;
        }
        size = 256;
    }
    apply {
    }
}
control IngressAcl(
        inout switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t ipv4_table_size=512,
        switch_uint32_t ipv6_table_size=512,
        switch_uint32_t mac_table_size=512,
        bool mac_acl_enable=false,
        bool mac_packet_class_enable=false) {
    IngressIpv4Acl(ipv4_table_size) ipv4_acl;
    IngressIpv6Acl(ipv6_table_size) ipv6_acl;
    IngressMacAcl(mac_table_size) mac_acl;
    LOU() lou;
    Counter<bit<16>, switch_stats_index_t>(
        ipv4_table_size + ipv6_table_size + mac_table_size, CounterType_t.PACKETS_AND_BYTES) stats;
    switch_stats_index_t stats_index;
    switch_nexthop_t nexthop;
    apply {
        ig_md.flags.acl_deny = false;
        stats_index = 0;
        nexthop = 0;
        lou.apply(lkp.l4_src_port, lkp.l4_dst_port, lkp.tcp_flags, ig_md.l4_port_label);
        if (mac_acl_enable && !(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            if (lkp.ip_type == SWITCH_IP_TYPE_NONE || (mac_packet_class_enable && ig_md.flags.mac_pkt_class)) {
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
        stats.count(stats_index);
    }
}
action racl_deny(inout switch_ingress_metadata_t ig_md,
                 inout switch_stats_index_t index,
                 switch_stats_index_t stats_index) {
    index = stats_index;
    ig_md.flags.racl_deny = true;
}
action racl_permit(inout switch_ingress_metadata_t ig_md,
                   inout switch_stats_index_t index,
                   switch_stats_index_t stats_index) {
    index = stats_index;
    ig_md.flags.racl_deny = false;
}
action racl_redirect(inout switch_stats_index_t index,
                     inout switch_nexthop_t nexthop,
                     switch_stats_index_t stats_index,
                     switch_nexthop_t nexthop_index) {
    index = stats_index;
    nexthop = nexthop_index;
}
control Ipv4Racl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index,
        out switch_nexthop_t nexthop)(
        switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.ip_src_addr[31:0] : ternary; lkp.ip_dst_addr[31:0] : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.ip_frag : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
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
control Ipv6Racl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index,
        out switch_nexthop_t nexthop)(
        switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
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
control RouterAcl(in switch_lookup_fields_t lkp,
                  inout switch_ingress_metadata_t ig_md)(
                  switch_uint32_t ipv4_table_size=512,
                  switch_uint32_t ipv6_table_size=512,
                  bool stats_enable=false) {
    switch_stats_index_t stats_index;
    switch_nexthop_t nexthop;
    Counter<bit<16>, switch_stats_index_t>(
        ipv4_table_size + ipv6_table_size, CounterType_t.PACKETS_AND_BYTES) stats;
    Ipv4Racl(ipv4_table_size) ipv4_racl;
    Ipv6Racl(ipv6_table_size) ipv6_racl;
    apply {
    }
}
control Ipv4MirrorAcl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index)(
        switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.ip_src_addr[31:0] : ternary; lkp.ip_dst_addr[31:0] : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.ip_frag : ternary; lkp.tcp_flags : ternary;
            lkp.mac_type : ternary;
            ig_md.port_lag_label : ternary;
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
control Ipv6MirrorAcl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index)(
        switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
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
control IpMirrorAcl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index)(
        switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.mac_type : ternary; lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
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
control MirrorAcl(
        inout switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t ipv4_table_size=512,
        switch_uint32_t ipv6_table_size=512,
        bool stats_enable=false) {
    Ipv4MirrorAcl(ipv4_table_size) ipv4;
    Ipv6MirrorAcl(ipv6_table_size) ipv6;
    IpMirrorAcl(ipv6_table_size) ip;
    Counter<bit<16>, switch_stats_index_t>(
        ipv4_table_size + ipv6_table_size, CounterType_t.PACKETS_AND_BYTES) stats;
    switch_stats_index_t stats_index;
    apply {
    }
}
control Ipv4EgressMirrorAcl(
        in switch_header_t hdr,
        in switch_lookup_fields_t lkp,
        inout switch_egress_metadata_t eg_md,
        out switch_stats_index_t index)(
        switch_uint32_t table_size=512) {
    table acl {
        key = {
            hdr.ipv4.src_addr : ternary; hdr.ipv4.dst_addr : ternary; hdr.ipv4.protocol : ternary; hdr.ipv4.diffserv : ternary; lkp.tcp_flags : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary;
            hdr.ethernet.ether_type : ternary;
            eg_md.port_lag_label : ternary;
            eg_md.l4_port_label : ternary;
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
control Ipv6EgressMirrorAcl(
        in switch_header_t hdr,
        in switch_lookup_fields_t lkp,
        inout switch_egress_metadata_t eg_md,
        out switch_stats_index_t index)(
        switch_uint32_t table_size=512) {
    table acl {
        key = {
            hdr.ipv6.src_addr : ternary; hdr.ipv6.dst_addr : ternary; hdr.ipv6.next_hdr : ternary; hdr.ipv6.traffic_class : ternary; lkp.tcp_flags : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary;
            eg_md.port_lag_label : ternary;
            eg_md.l4_port_label : ternary;
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
control EgressMirrorAcl(
        in switch_header_t hdr,
        inout switch_lookup_fields_t lkp,
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t ipv4_table_size=512,
        switch_uint32_t ipv6_table_size=512,
        bool stats_enable=false) {
    Ipv4EgressMirrorAcl(ipv4_table_size) ipv4;
    Ipv6EgressMirrorAcl(ipv6_table_size) ipv6;
    Counter<bit<16>, switch_stats_index_t>(
        ipv4_table_size + ipv6_table_size, CounterType_t.PACKETS_AND_BYTES) stats;
    switch_stats_index_t stats_index;
    apply {
    }
}
control IngressSystemAcl(
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(
        switch_uint32_t table_size=512) {
    const switch_uint32_t drop_stats_table_size = 8192;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) stats;
    Meter<bit<8>>(1 << 8, MeterType_t.PACKETS) copp_meter;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) copp_stats;
    switch_copp_meter_id_t copp_meter_id;
    action drop(switch_drop_reason_t drop_reason, bool disable_learning) {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        ig_intr_md_for_dprsr.digest_type =
            disable_learning ? SWITCH_DIGEST_TYPE_INVALID : ig_intr_md_for_dprsr.digest_type;
        ig_md.drop_reason = drop_reason;
    }
    action copy_to_cpu(switch_cpu_reason_t reason_code,
                       switch_qid_t qid,
                       switch_copp_meter_id_t meter_id,
                       bool disable_learning) {
        ig_md.qos.qid = qid;
        ig_intr_md_for_tm.copy_to_cpu = 1w1;
        ig_intr_md_for_dprsr.digest_type =
            disable_learning ? SWITCH_DIGEST_TYPE_INVALID : ig_intr_md_for_dprsr.digest_type;
        ig_md.cpu_reason = reason_code;
    }
    action redirect_to_cpu(switch_cpu_reason_t reason_code,
                           switch_qid_t qid,
                           switch_copp_meter_id_t meter_id,
                           bool disable_learning) {
        ig_intr_md_for_dprsr.drop_ctl = 0b1;
        copy_to_cpu(reason_code, qid, meter_id, disable_learning);
    }
    table system_acl {
        key = {
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.ifindex : ternary;
            ig_md.lkp.pkt_type : ternary;
            ig_md.lkp.mac_type : ternary;
            ig_md.lkp.mac_dst_addr : ternary;
            ig_md.lkp.ip_type : ternary;
            ig_md.lkp.ip_ttl : ternary;
            ig_md.lkp.ip_proto : ternary;
            ig_md.lkp.ip_frag : ternary;
            ig_md.lkp.ip_dst_addr : ternary;
            ig_md.lkp.l4_src_port : ternary;
            ig_md.lkp.l4_dst_port : ternary;
            ig_md.lkp.arp_opcode : ternary;
            ig_md.flags.port_vlan_miss : ternary;
            ig_md.flags.acl_deny : ternary;
            ig_md.flags.racl_deny : ternary;
            ig_md.flags.rmac_hit : ternary;
            ig_md.flags.dmac_miss : ternary;
            ig_md.flags.myip : ternary;
            ig_md.flags.glean : ternary;
            ig_md.flags.routed : ternary;
            ig_md.flags.link_local : ternary;
            ig_md.ipv4.unicast_enable : ternary;
            ig_md.ipv6.unicast_enable : ternary;
            ig_md.checks.mrpf : ternary;
            ig_md.ipv4.multicast_enable : ternary;
            ig_md.ipv4.multicast_snooping : ternary;
            ig_md.ipv6.multicast_enable : ternary;
            ig_md.ipv6.multicast_snooping : ternary;
            ig_md.drop_reason : ternary;
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
            ig_md.drop_reason : exact @name("drop_reason");
            ig_md.port : exact @name("port");
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
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SYSTEM_ACL != 0))
            system_acl.apply();
        drop_stats.apply();
    }
}
control EgressMacAcl(in switch_header_t hdr,
                     inout switch_egress_metadata_t eg_md,
                     out switch_stats_index_t index)(
                     switch_uint32_t table_size=512) {
    table acl {
        key = {
            eg_md.port_lag_label : ternary;
            eg_md.bd_label : ternary;
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
            hdr.ethernet.ether_type : ternary;
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
control EgressIpv4Acl(in switch_header_t hdr,
                      in switch_lookup_fields_t lkp,
                      inout switch_egress_metadata_t eg_md,
                      out switch_stats_index_t index)(
                      switch_uint32_t table_size=512) {
    table acl {
        key = {
            hdr.ipv4.src_addr : ternary; hdr.ipv4.dst_addr : ternary; hdr.ipv4.protocol : ternary; hdr.ipv4.diffserv : ternary; lkp.tcp_flags : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary;
            hdr.ethernet.ether_type : ternary;
            eg_md.port_lag_label : ternary;
            eg_md.bd_label : ternary;
            eg_md.l4_port_label : ternary;
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
control EgressIpv6Acl(in switch_header_t hdr,
                      in switch_lookup_fields_t lkp,
                      inout switch_egress_metadata_t eg_md,
                      out switch_stats_index_t index)(
                      switch_uint32_t table_size=512) {
    table acl {
        key = {
            hdr.ipv6.src_addr : ternary; hdr.ipv6.dst_addr : ternary; hdr.ipv6.next_hdr : ternary; hdr.ipv6.traffic_class : ternary; lkp.tcp_flags : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary;
            eg_md.port_lag_label : ternary;
            eg_md.bd_label : ternary;
            eg_md.l4_port_label : ternary;
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
control EgressAcl(in switch_header_t hdr,
                  in switch_lookup_fields_t lkp,
                  inout switch_egress_metadata_t eg_md)(
                  switch_uint32_t ipv4_table_size=512,
                  switch_uint32_t ipv6_table_size=512,
                  switch_uint32_t mac_table_size=512,
                  bool mac_acl_enable=false) {
    EgressIpv4Acl(ipv4_table_size) egress_ipv4_acl;
    EgressIpv6Acl(ipv6_table_size) egress_ipv6_acl;
    EgressMacAcl(mac_table_size) egress_mac_acl;
    Counter<bit<16>, switch_stats_index_t>(
        ipv4_table_size + ipv6_table_size + mac_table_size, CounterType_t.PACKETS_AND_BYTES) stats;
    switch_stats_index_t stats_index;
    apply {
        eg_md.flags.acl_deny = false;
    }
}
control EgressSystemAcl(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        out egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)(
        switch_uint32_t table_size=512) {
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
            eg_intr_md.egress_port : ternary;
            eg_md.flags.acl_deny : ternary;
            eg_md.checks.mtu : ternary;
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
            eg_md.drop_reason : exact @name("drop_reason");
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
    apply {
        eg_md.drop_reason = 0;
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_SYSTEM_ACL != 0))
            system_acl.apply();
        drop_stats.apply();
    }
}
control IngressSTP(in switch_ingress_metadata_t ig_md,
                   inout switch_stp_metadata_t stp_md)(
                   bool multiple_stp_enable=false,
                   switch_uint32_t table_size=4096) {
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
            ig_md.port : exact;
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
control SMAC(in mac_addr_t src_addr,
             inout switch_ingress_metadata_t ig_md,
             inout switch_digest_type_t digest_type)(
             switch_uint32_t table_size) {
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
            ig_md.bd : exact;
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
    }
    apply {
        src_miss = false;
        src_move = 0;
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SMAC != 0)) {
            smac.apply();
        }
        if (ig_md.learning.bd_mode == SWITCH_LEARNING_MODE_LEARN &&
                ig_md.learning.port_mode == SWITCH_LEARNING_MODE_LEARN) {
            learning.apply();
        }
    }
}
control DMAC_t(in mac_addr_t dst_addr, inout switch_ingress_metadata_t ig_md);
control DMAC(
        in mac_addr_t dst_addr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size) {
    action dmac_miss() {
        ig_md.egress_ifindex = SWITCH_IFINDEX_FLOOD;
        ig_md.flags.dmac_miss = true;
    }
    action dmac_hit(switch_ifindex_t ifindex,
                    switch_port_lag_index_t port_lag_index) {
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
            ig_md.bd : exact;
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
        ig_md.flags.dmac_miss = false;
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_L2 != 0)) {
            dmac.apply();
        }
    }
}
control IngressBd(in switch_bd_t bd, in switch_pkt_type_t pkt_type)(switch_uint32_t table_size) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
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
        size = 3 * table_size;
        counters = stats;
    }
    apply {
        bd_stats.apply();
    }
}
control EgressBd(in switch_header_t hdr,
                 in switch_bd_t bd,
                 in switch_pkt_type_t pkt_type,
                 in switch_pkt_src_t pkt_src,
                 out switch_bd_label_t label,
                 out switch_smac_index_t smac_idx,
                 out switch_mtu_t mtu_idx)(
                 switch_uint32_t table_size) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    action count() {
        stats.count();
    }
    table bd_stats {
        key = {
            bd : exact;
            pkt_type : exact;
        }
        actions = {
            count;
            @defaultonly NoAction;
        }
        size = 3 * table_size;
        counters = stats;
    }
    action set_bd_properties(switch_bd_label_t bd_label,
                             switch_smac_index_t smac_index,
                             switch_mtu_t mtu_index) {
        label = bd_label;
        smac_idx = smac_index;
        mtu_idx = mtu_index;
    }
    table bd_mapping {
        key = { bd : exact; }
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
        if (pkt_src == SWITCH_PKT_SRC_BRIDGED)
            bd_stats.apply();
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
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0)) {
            if (hdr.vlan_tag[0].isValid()) {
                hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
                hdr.vlan_tag[0].setInvalid();
            }
        }
    }
}
control VlanXlate(inout switch_header_t hdr,
                  in switch_egress_metadata_t eg_md)(
                  switch_uint32_t bd_table_size,
                  switch_uint32_t port_bd_table_size) {
    action set_vlan_untagged() {
    }
    action set_double_tagged(vlan_id_t vid0, vlan_id_t vid1) {
   }
    vlan_id_t vid_temp;
    action set_vlan_tagged(vlan_id_t vid) {
        vid_temp = vid;
    }
    action set_vlan_tagged_orig(vlan_id_t vid) {
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;
        hdr.vlan_tag[0].pcp = eg_md.lkp.pcp;
        hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].vid = vid;
        hdr.ethernet.ether_type = 0x8100;
    }
    action set_vlan_tagged_nsh(vlan_id_t vid) {
        hdr.vlan_tag_underlay[0].setValid();
        hdr.vlan_tag_underlay[0].ether_type = hdr.ethernet_underlay.ether_type;
        hdr.vlan_tag_underlay[0].cfi = 0;
        hdr.vlan_tag_underlay[0].vid = vid;
        hdr.ethernet_underlay.ether_type = 0x8100;
    }
    table port_bd_to_vlan_mapping {
        key = {
            eg_md.port_lag_index : exact @name("port_lag_index");
            eg_md.bd : exact @name("bd");
        }
        actions = {
            set_vlan_untagged;
            set_vlan_tagged_orig;
            set_double_tagged;
            set_vlan_tagged_nsh;
        }
        const default_action = set_vlan_untagged;
        size = port_bd_table_size;
    }
    table bd_to_vlan_mapping {
        key = { eg_md.bd : exact @name("bd"); }
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
    action set_type_vlan_nsh() {
        hdr.ethernet_underlay.ether_type = 0x8100;
    }
    table set_ether_type {
        key = {
            hdr.vlan_tag[0].isValid() : exact;
            hdr.vlan_tag[1].isValid() : exact;
            hdr.vlan_tag_underlay[0].isValid() : exact;
        }
        actions = {
            NoAction;
            set_type_vlan;
            set_type_qinq;
            set_type_vlan_nsh;
        }
        const default_action = NoAction;
        const entries = {
            (true, false, false) : set_type_vlan();
            (true, true, false) : set_type_qinq();
            (_, _, true ) : set_type_vlan_nsh();
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
control Fib<T>(in ipv4_addr_t dst_addr,
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
    action fib_myip() {
        flags.myip = true;
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
control Fibv6<T>(in ipv6_addr_t dst_addr,
                 in switch_vrf_t vrf,
                 out switch_ingress_flags_t flags,
                 out switch_nexthop_t nexthop)(
                 switch_uint32_t host_table_size,
                 switch_uint32_t lpm_table_size,
                 switch_uint32_t lpm64_table_size
                 ) {
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
control MTU(in switch_header_t hdr,
            in switch_egress_metadata_t eg_md,
            inout switch_mtu_t mtu_check)(
            switch_uint32_t table_size=1024) {
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
            mtu_check : exact;
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
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_MTU != 0))
            mtu.apply();
    }
}
control IngressUnicast(in switch_lookup_fields_t lkp,
                       inout switch_ingress_metadata_t ig_md)(
                       DMAC_t dmac,
                       switch_uint32_t ipv4_host_table_size,
                       switch_uint32_t ipv4_route_table_size,
                       switch_uint32_t ipv6_host_table_size=1024,
                       switch_uint32_t ipv6_route_table_size=512,
                       switch_uint32_t ipv6_route64_table_size=512,
                       bool local_host_enable=false,
                       switch_uint32_t ipv4_local_host_table_size=1024) {
    Fib<ipv4_addr_t>(ipv4_host_table_size,
                     ipv4_route_table_size,
                     local_host_enable,
                     ipv4_local_host_table_size) ipv4_fib;
    Fibv6<ipv6_addr_t>(ipv6_host_table_size, ipv6_route_table_size, ipv6_route64_table_size) ipv6_fib;
    action rmac_hit() {
        ig_md.flags.rmac_hit = true;
    }
    action rmac_miss() {
    }
    table rmac {
        key = {
            ig_md.rmac_group : exact;
            lkp.mac_dst_addr : exact;
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
                if (lkp.ip_type == SWITCH_IP_TYPE_IPV4 && ig_md.ipv4.unicast_enable) {
                    ipv4_fib.apply(lkp.ip_dst_addr[31:0],
                                   ig_md.vrf,
                                   ig_md.flags,
                                   ig_md.nexthop);
                } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6 && ig_md.ipv6.unicast_enable) {
                    ipv6_fib.apply(lkp.ip_dst_addr,
                                   ig_md.vrf,
                                   ig_md.flags,
                                   ig_md.nexthop);
                } else {
                }
            }
        } else {
            dmac.apply(lkp.mac_dst_addr, ig_md);
        }
    }
}
control Nexthop(inout switch_lookup_fields_t lkp,
                inout switch_ingress_metadata_t ig_md,
                in bit<16> hash)(
                switch_uint32_t nexthop_table_size,
                switch_uint32_t ecmp_table_size,
                switch_uint32_t ecmp_selection_table_size) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(
        ecmp_selection_table_size, selector_hash, SelectorMode_t.FAIR) ecmp_selector;
    action set_nexthop_properties(switch_ifindex_t ifindex,
                                  switch_port_lag_index_t port_lag_index,
                                  switch_bd_t bd) {
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
    action set_ecmp_properties(switch_ifindex_t ifindex,
                               switch_port_lag_index_t port_lag_index,
                               switch_bd_t bd,
                               switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties(ifindex, port_lag_index, bd);
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
    action set_tunnel_properties(switch_bd_t bd, switch_tunnel_index_t tunnel_index) {
        ig_md.tunnel.index = tunnel_index;
        ig_md.egress_ifindex = 0;
        ig_md.checks.same_bd = ig_md.bd ^ bd;
    }
    table ecmp {
        key = {
            ig_md.nexthop : exact;
            hash : selector;
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
            ig_md.nexthop : exact;
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
        switch(nexthop.apply().action_run) {
            NoAction : { ecmp.apply(); }
            default : {}
        }
    }
}
control OuterFib(inout switch_ingress_metadata_t ig_md,
                     in bit<16> hash)(
                     switch_uint32_t fib_table_size,
                     switch_uint32_t ecmp_table_size,
                     switch_uint32_t ecmp_selection_table_size) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(ecmp_selection_table_size, selector_hash, SelectorMode_t.FAIR) ecmp_selector;
    action set_nexthop_properties(switch_ifindex_t ifindex,
                                  switch_port_lag_index_t port_lag_index,
                                  switch_outer_nexthop_t nexthop_index) {
        ig_md.outer_nexthop = nexthop_index;
        ig_md.egress_ifindex = ifindex;
        ig_md.egress_port_lag_index = port_lag_index;
    }
    table fib {
        key = {
            ig_md.tunnel.index : exact;
        }
        actions = {
            NoAction;
            set_nexthop_properties;
        }
        const default_action = NoAction;
        size = fib_table_size;
    }
    apply {
        fib.apply();
    }
}
parser ParserUnderlayL2(
    packet_in pkt,
    inout switch_header_t hdr,
    out bit<16> ether_type) {
    state start {
        pkt.extract(hdr.ethernet);
        ether_type = hdr.ethernet.ether_type;
        transition select(hdr.ethernet.ether_type) {
            0x893F : parse_br;
            0x8926 : parse_vn;
            0x8100 : parse_vlan;
            0x8100 : parse_vlan;
            default : accept;
        }
    }
    state parse_br {
     pkt.extract(hdr.e_tag);
        ether_type = hdr.e_tag.ether_type;
        transition select(hdr.e_tag.ether_type) {
            0x8100 : parse_vlan;
            0x8100 : parse_vlan;
            default : accept;
        }
    }
    state parse_vn {
     pkt.extract(hdr.vn_tag);
        ether_type = hdr.vn_tag.ether_type;
        transition select(hdr.vn_tag.ether_type) {
            0x8100 : parse_vlan;
            0x8100 : parse_vlan;
            default : accept;
        }
    }
    state parse_vlan {
     pkt.extract(hdr.vlan_tag.next);
        ether_type = hdr.vlan_tag.last.ether_type;
        transition select(hdr.vlan_tag.last.ether_type) {
            0x8100 : parse_vlan;
            0x8100 : parse_vlan;
            default : accept;
        }
    }
}
parser NpbIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    value_set<bit<16>>(1) udp_port_vxlan;
 bit<16> ether_type;
 bit<16> inner_ether_type;
 bit<8> protocol;
 bit<8> inner_protocol;
    state start {
        pkt.extract(ig_intr_md);
        ig_md.port = ig_intr_md.ingress_port;
        ig_md.timestamp = ig_intr_md.ingress_mac_tstamp;
        transition parse_port_metadata;
    }
    state parse_resubmit {
        transition reject;
    }
    state parse_port_metadata {
        switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);
        ig_md.port_lag_index = port_md.port_lag_index;
        ig_md.port_lag_label = port_md.port_lag_label;
        ig_md.ifindex = port_md.ifindex;
        transition snoop_underlay;
    }
    state parse_cpu {
        pkt.extract(hdr.fabric);
        pkt.extract(hdr.cpu);
        ig_md.bypass = hdr.cpu.reason_code;
        ig_md.flags.capture_ts = (bool) hdr.cpu.capture_ts;
        transition select(hdr.cpu.ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            default : accept;
        }
    }
    state snoop_underlay {
        transition select(pkt.lookahead<bit<112>>()[15:0], pkt.lookahead<bit<144>>()[15:0]) {
            (0x894F, _): parse_underlay_nsh;
            (0x8100, 0x894F): parse_underlay_nsh_tagged;
            default: parse_underlay_l2_ethernet;
        }
    }
    state parse_underlay_nsh {
        pkt.extract<ethernet_h>(_);
     pkt.extract(hdr.nsh_extr_underlay);
        ig_md.orig_pkt_had_nsh = 1;
        transition parse_underlay_l2_ethernet;
    }
    state parse_underlay_nsh_tagged {
        pkt.extract<ethernet_h>(_);
        pkt.extract<vlan_tag_h>(_);
     pkt.extract(hdr.nsh_extr_underlay);
        ig_md.orig_pkt_had_nsh = 1;
        transition parse_underlay_l2_ethernet;
    }
    state parse_underlay_l2_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x893F : parse_underlay_l2_br;
            0x8926 : parse_underlay_l2_vn;
            0x8100 : parse_underlay_l2_vlan;
            0x8100 : parse_underlay_l2_vlan;
            0x8847 : parse_mpls;
            0x0800 : parse_ipv4;
            0x0806 : parse_arp;
            0x86dd : parse_ipv6;
            0x9000 : parse_cpu;
            default : accept;
        }
    }
    state parse_underlay_l2_br {
     pkt.extract(hdr.e_tag);
        ether_type = hdr.e_tag.ether_type;
        transition select(hdr.e_tag.ether_type) {
            0x8100 : parse_underlay_l2_vlan;
            0x8100 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }
    state parse_underlay_l2_vn {
     pkt.extract(hdr.vn_tag);
        ether_type = hdr.vn_tag.ether_type;
        transition select(hdr.vn_tag.ether_type) {
            0x8100 : parse_underlay_l2_vlan;
            0x8100 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }
    state parse_underlay_l2_vlan {
     pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            0x8100 : parse_underlay_l2_vlan;
            0x8100 : parse_underlay_l2_vlan;
            0x8847 : parse_mpls;
            0x0800 : parse_ipv4;
            0x0806 : parse_arp;
            0x86dd : parse_ipv6;
            0x9000 : parse_cpu;
            default : accept;
        }
    }
    state parse_underlay_l2_ether_type {
        transition select(ether_type) {
            0x8847 : parse_mpls;
            0x0800 : parse_ipv4;
            0x0806 : parse_arp;
            0x86dd : parse_ipv6;
            0x9000 : parse_cpu;
            default : accept;
        }
    }
    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        protocol = hdr.ipv4.protocol;
        ipv4_checksum.add(hdr.ipv4);
        transition select(hdr.ipv4.ihl, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
            (5, 3w2 &&& 3w5, 0): parse_ipv4_no_options_frags;
            default : accept;
        }
    }
    state parse_ipv4_no_options_frags {
        ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol) {
            1: parse_icmp;
            2: parse_igmp;
            default: parse_l3_protocol;
        }
    }
    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        protocol = hdr.ipv6.next_hdr;
        transition select(hdr.ipv6.next_hdr) {
            58: parse_icmp;
            default: parse_l3_protocol;
        }
    }
    state parse_l3_protocol {
        transition select(protocol) {
           4: parse_ipinip;
           41: parse_ipv6inip;
           17: parse_udp;
           6: parse_tcp;
           0x84: parse_sctp;
           0x32: parse_esp;
           47: parse_gre;
           default : accept;
       }
    }
    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }
    state parse_igmp {
        pkt.extract(hdr.igmp);
        transition accept;
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.src_port, hdr.udp.dst_port) {
            (_, 4789): parse_vxlan;
            (_, 2123): parse_gtp_c;
            (2123, _): parse_gtp_c;
            (_, 2152): parse_gtp_u;
            (2152, _): parse_gtp_u;
            default : parse_udf;
        }
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition parse_udf;
    }
    state parse_sctp {
        pkt.extract(hdr.sctp);
        transition parse_udf;
    }
    state parse_mpls {
        transition accept;
    }
    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_VXLAN;
        transition parse_inner_ethernet;
    }
    state parse_ipinip {
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv4;
    }
    state parse_ipv6inip {
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv6;
    }
    state parse_gre {
     pkt.extract(hdr.gre);
        transition select(
            hdr.gre.C,
            hdr.gre.R,
            hdr.gre.K,
            hdr.gre.S,
            hdr.gre.s,
            hdr.gre.recurse,
            hdr.gre.version,
            hdr.gre.proto) {
            (0,0,1,0,0,0,0,0x6558): parse_nvgre;
            (0,0,0,0,0,0,0,0x8847): parse_mpls;
            (0,0,0,0,0,0,0,0x0800): parse_inner_ipv4;
            (0,0,0,0,0,0,0,0x86dd): parse_inner_ipv6;
            default: accept;
        }
    }
    state parse_nvgre {
     pkt.extract(hdr.nvgre);
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_NVGRE;
     transition parse_inner_ethernet;
    }
    state parse_esp {
        pkt.extract(hdr.esp);
        transition accept;
    }
    state parse_gtp_c {
        gtp_v2_base_h snoop_gtp_v2_base = pkt.lookahead<gtp_v2_base_h>();
        transition select(snoop_gtp_v2_base.version, snoop_gtp_v2_base.T) {
            (2, 1): extract_gtp_c;
            default: accept;
        }
    }
    state extract_gtp_c {
        pkt.extract(hdr.gtp_v2_base);
        pkt.extract(hdr.gtp_v1_v2_teid);
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_GTPC;
        ig_md.tunnel.id = hdr.gtp_v1_v2_teid.teid;
     transition accept;
    }
    state parse_gtp_u {
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {
            (1, 1, 0, 0, 0): extract_gtp_u;
            default: accept;
        }
    }
    state extract_gtp_u {
        pkt.extract(hdr.gtp_v1_base);
        pkt.extract(hdr.gtp_v1_v2_teid);
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.tunnel.id = hdr.gtp_v1_v2_teid.teid;
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4;
            6: parse_inner_ipv6;
            default: accept;
        }
    }
    state parse_udf {
        transition accept;
    }
    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            0x8100 : parse_inner_vlan;
            0x0806 : parse_inner_arp;
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }
    state parse_inner_vlan {
        pkt.extract(hdr.inner_vlan_tag);
        transition select(hdr.inner_vlan_tag.ether_type) {
            0x0806 : parse_inner_arp;
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }
    state parse_inner_arp {
        pkt.extract(hdr.inner_arp);
        transition accept;
    }
    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        inner_protocol = hdr.inner_ipv4.protocol;
        inner_ipv4_checksum.add(hdr.inner_ipv4);
        transition select(
            hdr.inner_ipv4.ihl,
            hdr.inner_ipv4.flags,
            hdr.inner_ipv4.frag_offset) {
            (5, 3w2 &&& 3w5, 0): parse_inner_ipv4_no_options_frags;
            default: accept;
        }
    }
    state parse_inner_ipv4_no_options_frags {
        ig_md.flags.inner_ipv4_checksum_err = inner_ipv4_checksum.verify();
        transition select(hdr.inner_ipv4.protocol) {
            1: parse_inner_icmp;
            2: parse_inner_igmp;
            default: parse_inner_l3_protocol;
        }
    }
    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        inner_protocol = hdr.inner_ipv6.next_hdr;
        transition select(hdr.inner_ipv6.next_hdr) {
            58: parse_inner_icmp;
            default: parse_inner_l3_protocol;
        }
    }
    state parse_inner_l3_protocol {
        transition select(inner_protocol) {
           17: parse_inner_udp;
           6: parse_inner_tcp;
           0x84: parse_inner_sctp;
           0x32: parse_inner_esp;
           47: parse_inner_gre;
           default : accept;
       }
    }
    state parse_inner_icmp {
        pkt.extract(hdr.inner_icmp);
        transition accept;
    }
    state parse_inner_igmp {
        pkt.extract(hdr.inner_igmp);
        transition accept;
    }
    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition parse_inner_udf;
    }
    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition parse_inner_udf;
    }
    state parse_inner_sctp {
        pkt.extract(hdr.inner_sctp);
        transition parse_inner_udf;
    }
    state parse_inner_esp {
        pkt.extract(hdr.inner_esp);
        transition accept;
    }
    state parse_inner_gre {
        pkt.extract(hdr.inner_gre);
        transition accept;
    }
    state parse_inner_udf {
        transition accept;
    }
}
parser NpbEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
 bit<16> ether_type;
 bit<16> inner_ether_type;
 bit<8> protocol;
 bit<8> inner_protocol;
    value_set<bit<16>>(1) udp_port_vxlan;
 value_set<switch_cpu_port_value_set_t>(1) cpu_port;
    state start {
        pkt.extract(eg_intr_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.port = eg_intr_md.egress_port;
        eg_md.qos.qdepth = eg_intr_md.enq_qdepth;
        transition parse_bridged_pkt;
    }
    state parse_bridged_pkt {
  pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_BRIDGED;
        eg_md.ingress_port = hdr.bridged_md.base.ingress_port;
        eg_md.ingress_ifindex = hdr.bridged_md.base.ingress_ifindex;
        eg_md.bd = hdr.bridged_md.base.ingress_bd;
        eg_md.nexthop = hdr.bridged_md.base.nexthop;
        eg_md.qos.tc = hdr.bridged_md.base.tc;
        eg_md.cpu_reason = hdr.bridged_md.base.cpu_reason;
        eg_md.flags.routed = hdr.bridged_md.base.routed;
        eg_md.flags.peer_link = hdr.bridged_md.base.peer_link;
        eg_md.pkt_type = hdr.bridged_md.base.pkt_type;
        eg_md.ingress_timestamp = hdr.bridged_md.base.timestamp;
        eg_md.qos.qid = hdr.bridged_md.base.qid;
        eg_md.outer_nexthop = hdr.bridged_md.tunnel.outer_nexthop;
        eg_md.tunnel.index = hdr.bridged_md.tunnel.index;
        eg_md.tunnel.hash = hdr.bridged_md.tunnel.hash;
  eg_md.vrf = hdr.bridged_md.tunnel.vrf;
        eg_md.tunnel.terminate = hdr.bridged_md.tunnel.terminate;
        eg_md.orig_pkt_had_nsh = hdr.bridged_md.base.orig_pkt_had_nsh;
        eg_md.nsh_extr.valid = hdr.bridged_md.base.nsh_extr_valid;
        eg_md.nsh_extr.terminate = hdr.bridged_md.base.nsh_extr_terminate;
        eg_md.tunnel_nsh.terminate = hdr.bridged_md.base.nsh_extr_terminate;
        eg_md.nsh_extr.spi = hdr.bridged_md.base.nsh_extr_spi;
        eg_md.nsh_extr.si = hdr.bridged_md.base.nsh_extr_si;
        eg_md.nsh_extr.extr_sf_bitmask_local = hdr.bridged_md.base.nsh_extr_sf_bitmask_local;
        eg_md.nsh_extr.extr_sf_bitmask_remote = hdr.bridged_md.base.nsh_extr_sf_bitmask_remote;
        eg_md.nsh_extr.extr_tenant_id = hdr.bridged_md.base.nsh_extr_tenant_id;
        eg_md.nsh_extr.extr_flow_type = hdr.bridged_md.base.nsh_extr_flow_type;
        transition select(eg_md.orig_pkt_had_nsh) {
            0: parse_underlay_l2_ethernet;
            1: parse_underlay_nsh;
        }
    }
    state parse_deflected_pkt {
    }
    state parse_port_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.ethernet);
        eg_md.pkt_src = port_md.src;
        eg_md.mirror.type = port_md.type;
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
        eg_md.mirror.type = cpu_md.type;
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
    state parse_underlay_nsh {
        pkt.extract(hdr.nsh_extr_underlay);
        transition parse_underlay_l2_ethernet;
    }
    state parse_underlay_l2_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x893F : parse_underlay_l2_br;
            0x8926 : parse_underlay_l2_vn;
            0x8100 : parse_underlay_l2_vlan;
            0x8100 : parse_underlay_l2_vlan;
            0x8847 : parse_mpls;
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            default : accept;
        }
    }
    state parse_underlay_l2_br {
     pkt.extract(hdr.e_tag);
        ether_type = hdr.e_tag.ether_type;
        transition select(hdr.e_tag.ether_type) {
            0x8100 : parse_underlay_l2_vlan;
            0x8100 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }
    state parse_underlay_l2_vn {
     pkt.extract(hdr.vn_tag);
        ether_type = hdr.vn_tag.ether_type;
        transition select(hdr.vn_tag.ether_type) {
            0x8100 : parse_underlay_l2_vlan;
            0x8100 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }
    state parse_underlay_l2_vlan {
     pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            0x8100 : parse_underlay_l2_vlan;
            0x8100 : parse_underlay_l2_vlan;
            0x8847 : parse_mpls;
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            default : accept;
        }
    }
    state parse_underlay_l2_ether_type {
        transition select(ether_type) {
            0x8847 : parse_mpls;
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            default : accept;
        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        protocol = hdr.ipv4.protocol;
        transition select(hdr.ipv4.ihl, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
            (5, 3w2 &&& 3w5, 0): parse_l3_protocol;
            default : accept;
        }
    }
    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        protocol = hdr.ipv6.next_hdr;
        transition parse_l3_protocol;
    }
    state parse_l3_protocol {
        transition select(protocol) {
           4: parse_inner_ipv4;
           41: parse_inner_ipv6;
           17: parse_udp;
           6: parse_tcp;
           0x84: parse_sctp;
           0x32: parse_esp;
           47: parse_gre;
           default : accept;
       }
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.src_port, hdr.udp.dst_port) {
            (_, 4789): parse_vxlan;
            (_, 2123): parse_gtp_c;
            (2123, _): parse_gtp_c;
            (_, 2152): parse_gtp_u;
            (2152, _): parse_gtp_u;
            default : accept;
        }
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }
    state parse_sctp {
        pkt.extract(hdr.sctp);
        transition accept;
    }
    state parse_mpls {
        transition accept;
    }
    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;
    }
    state parse_gre {
     pkt.extract(hdr.gre);
        transition select(
            hdr.gre.C,
            hdr.gre.R,
            hdr.gre.K,
            hdr.gre.S,
            hdr.gre.s,
            hdr.gre.recurse,
            hdr.gre.version,
            hdr.gre.proto) {
            (0,0,1,0,0,0,0,0x6558): parse_nvgre;
            (0,0,0,0,0,0,0,0x8847): parse_mpls;
            (0,0,0,0,0,0,0,0x0800): parse_inner_ipv4;
            (0,0,0,0,0,0,0,0x86dd): parse_inner_ipv6;
            default: accept;
        }
    }
    state parse_nvgre {
     pkt.extract(hdr.nvgre);
     transition parse_inner_ethernet;
    }
    state parse_esp {
        pkt.extract(hdr.esp);
        transition accept;
    }
    state parse_gtp_c {
        gtp_v2_base_h snoop_gtp_v2_base = pkt.lookahead<gtp_v2_base_h>();
        transition select(snoop_gtp_v2_base.version, snoop_gtp_v2_base.T) {
            (2, 1): extract_gtp_c;
            default: accept;
        }
    }
    state extract_gtp_c {
        pkt.extract(hdr.gtp_v2_base);
        pkt.extract(hdr.gtp_v1_v2_teid);
     transition accept;
    }
    state parse_gtp_u {
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {
            (1, 1, 0, 0, 0): extract_gtp_u;
            default: accept;
        }
    }
    state extract_gtp_u {
        pkt.extract(hdr.gtp_v1_base);
        pkt.extract(hdr.gtp_v1_v2_teid);
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4;
            6: parse_inner_ipv6;
            default: accept;
        }
    }
    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            0x8100 : parse_inner_vlan;
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }
    state parse_inner_vlan {
        pkt.extract(hdr.inner_vlan_tag);
        transition select(hdr.inner_vlan_tag.ether_type) {
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }
    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        inner_protocol = hdr.inner_ipv4.protocol;
        transition select(
            hdr.inner_ipv4.ihl,
            hdr.inner_ipv4.flags,
            hdr.inner_ipv4.frag_offset) {
            (5, 3w2 &&& 3w5, 0): parse_inner_l3_protocol;
            default: accept;
        }
    }
    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        inner_protocol = hdr.inner_ipv6.next_hdr;
        transition parse_inner_l3_protocol;
    }
    state parse_inner_l3_protocol {
        transition select(inner_protocol) {
           17: parse_inner_udp;
           6: parse_inner_tcp;
           0x84: parse_inner_sctp;
           0x32: parse_inner_esp;
           47: parse_inner_gre;
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
    state parse_inner_sctp {
        pkt.extract(hdr.inner_sctp);
        transition accept;
    }
    state parse_inner_esp {
        pkt.extract(hdr.inner_esp);
        transition accept;
    }
    state parse_inner_gre {
        pkt.extract(hdr.inner_gre);
        transition accept;
    }
}
parser PktgenParser<H>(packet_in pkt,
                       inout switch_header_t hdr,
                       inout H md) {
    state start {
        transition reject;
    }
    state parse_pktgen {
        transition reject;
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
control IngressMirror(
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    Mirror() mirror;
    apply {
    }
}
control EgressMirror(
    inout switch_header_t hdr,
    in switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    Mirror() mirror;
    apply {
    }
}
control SwitchIngressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    IngressMirror() mirror;
    Digest<switch_learning_digest_t>() digest;
    apply {
        mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);
        if (ig_intr_md_for_dprsr.digest_type == SWITCH_DIGEST_TYPE_MAC_LEARNING) {
            digest.pack({ig_md.bd, ig_md.ifindex, ig_md.lkp.mac_src_addr});
        }
        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.nsh_extr_underlay);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.e_tag);
        pkt.emit(hdr.vn_tag);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.gre);
        pkt.emit(hdr.nvgre);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.sctp);
        pkt.emit(hdr.esp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.icmp);
        pkt.emit(hdr.igmp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.gtp_v1_base);
        pkt.emit(hdr.gtp_v2_base);
        pkt.emit(hdr.gtp_v1_v2_teid);
        pkt.emit(hdr.gtp_v1_optional);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_vlan_tag);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_gre);
        pkt.emit(hdr.inner_sctp);
        pkt.emit(hdr.inner_esp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
        pkt.emit(hdr.inner_igmp);
    }
}
control SwitchEgressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    EgressMirror() mirror;
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    apply {
        mirror.apply(hdr, eg_md, eg_intr_md_for_dprsr);
        if (hdr.ipv4_option.isValid()) {
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
        } else if (hdr.ipv4.isValid()) {
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
        }
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
        pkt.emit(hdr.ethernet_underlay);
        pkt.emit(hdr.vlan_tag_underlay);
        pkt.emit(hdr.nsh_extr_underlay);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.fabric);
        pkt.emit(hdr.cpu);
        pkt.emit(hdr.timestamp);
        pkt.emit(hdr.e_tag);
        pkt.emit(hdr.vn_tag);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.gre);
        pkt.emit(hdr.nvgre);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.sctp);
        pkt.emit(hdr.esp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.gtp_v1_base);
        pkt.emit(hdr.gtp_v2_base);
        pkt.emit(hdr.gtp_v1_v2_teid);
        pkt.emit(hdr.gtp_v1_optional);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_vlan_tag);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_gre);
        pkt.emit(hdr.inner_sctp);
        pkt.emit(hdr.inner_esp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
        pkt.emit(hdr.inner_igmp);
    }
}
control MirrorRewrite(inout switch_header_t hdr,
                      inout switch_egress_metadata_t eg_md)(
                      switch_uint32_t table_size=1024) {
    bit<16> length;
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
    action rewrite_erspan_type2(
            switch_qid_t qid,
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
    }
    action rewrite_erspan_type2_with_vlan(
            switch_qid_t qid,
            bit<16> ether_type, mac_addr_t smac, mac_addr_t dmac,
            bit<3> pcp, vlan_id_t vid,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
    }
    action rewrite_erspan_type3(
            switch_qid_t qid,
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
    }
    action rewrite_erspan_type3_with_vlan(
            switch_qid_t qid,
            bit<16> ether_type, mac_addr_t smac, mac_addr_t dmac,
            bit<3> pcp, vlan_id_t vid,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
    }
    action rewrite_erspan_type3_platform_specific(
            switch_qid_t qid,
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
    }
    action rewrite_erspan_type3_platform_specific_with_vlan(
            switch_qid_t qid,
            bit<16> ether_type, mac_addr_t smac, mac_addr_t dmac,
            bit<3> pcp, vlan_id_t vid,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
    }
    action rewrite_dtel_report(
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl,
            bit<16> udp_dst_port) {
    }
    action rewrite_dtel_report_with_entropy(
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl,
            bit<16> udp_dst_port) {
    }
    action rewrite_dtel_report_without_entropy(
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl,
            bit<16> udp_dst_port, bit<16> udp_src_port) {
    }
    table rewrite {
        key = { eg_md.mirror.session_id : exact; }
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
        key = { eg_md.mirror.type : exact; }
        actions = { adjust_length; }
        const entries = {
            1 : adjust_length(-14);
            2 : adjust_length(-14);
            3 : adjust_length(-13);
            4 : adjust_length(-15);
        }
    }
    apply {
    }
}
control Rewrite(inout switch_header_t hdr,
                inout switch_egress_metadata_t eg_md)(
                switch_uint32_t nexthop_table_size,
                switch_uint32_t bd_table_size) {
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
    action rewrite_l3_with_tunnel_id(
            mac_addr_t dmac, switch_tunnel_type_t type, switch_tunnel_id_t id, bit<8> flow_id) {
        eg_md.flags.routed = true;
        hdr.ethernet.dst_addr = dmac;
        eg_md.bd = SWITCH_BD_DEFAULT_VRF;
        eg_md.tunnel.type = type;
        eg_md.tunnel.id = id;
  eg_md.tunnel.flow_id = flow_id;
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
        eg_md.bd = (switch_bd_t) eg_md.vrf;
    }
    table nexthop_rewrite {
        key = { eg_md.nexthop : exact; }
        actions = {
            NoAction;
            rewrite_l2_with_tunnel;
            rewrite_l3;
            rewrite_l3_with_tunnel;
            rewrite_l3_with_tunnel_bd;
            rewrite_l3_with_tunnel_id;
        }
        const default_action = NoAction;
        size = nexthop_table_size;
    }
    action rewrite_smac(mac_addr_t smac) {
        hdr.ethernet.src_addr = smac;
    }
    table smac_rewrite {
        key = { smac_index : exact; }
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
            hdr.ipv4.isValid() : exact;
            hdr.ipv4.dst_addr[31:28] : ternary;
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
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.nsh_extr_underlay.isValid() : exact;
        }
        actions = {
            rewrite_ipv4;
            rewrite_ipv6;
        }
        const entries = {
            (true, false, false) : rewrite_ipv4();
            (false, true, false) : rewrite_ipv6();
        }
    }
    apply {
        smac_index = 0;
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0)) {
            nexthop_rewrite.apply();
        }
        egress_bd.apply(hdr, eg_md.bd, eg_md.pkt_type, eg_md.pkt_src,
            eg_md.bd_label, smac_index, eg_md.checks.mtu);
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0) && eg_md.flags.routed) {
            ip_rewrite.apply();
            smac_rewrite.apply();
        }
    }
}
control PortMirror(
        in switch_port_t port,
        in switch_pkt_src_t src,
        inout switch_mirror_metadata_t mirror_md)(
        switch_uint32_t table_size=288) {
    action set_mirror_id(switch_mirror_session_t session_id) {
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
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(
        switch_uint32_t port_vlan_table_size,
        switch_uint32_t bd_table_size,
        switch_uint32_t port_table_size=288,
        switch_uint32_t vlan_table_size=4096,
        switch_uint32_t double_tag_table_size=1024) {
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
        ig_md.port = (switch_port_t) hdr.cpu.ingress_port;
        ig_md.egress_ifindex =
            (switch_ifindex_t) hdr.fabric.dst_port_or_group;
        ig_intr_md_for_tm.bypass_egress = hdr.cpu.tx_bypass;
        hdr.ethernet.ether_type = hdr.cpu.ether_type;
    }
    action set_cpu_port_properties(
            switch_port_lag_index_t port_lag_index,
            switch_port_lag_label_t port_lag_label,
            switch_yid_t exclusion_id,
            switch_qos_trust_mode_t trust_mode,
            switch_qos_group_t qos_group,
            switch_pkt_color_t color,
            switch_tc_t tc) {
        ig_md.port_lag_index = port_lag_index;
        ig_md.port_lag_label = port_lag_label;
        ig_md.qos.trust_mode = trust_mode;
        ig_md.qos.group = qos_group;
        ig_md.qos.color = color;
        ig_md.qos.tc = tc;
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
            bool mac_pkt_class) {
        ig_md.qos.trust_mode = trust_mode;
        ig_md.qos.group = qos_group;
        ig_md.qos.color = color;
        ig_md.qos.tc = tc;
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
        ig_md.learning.port_mode = learning_mode;
        ig_md.checks.same_if = 0xffff;
        ig_md.flags.mac_pkt_class = mac_pkt_class;
    }
    table port_mapping {
        key = {
            ig_md.port : exact;
            hdr.cpu.isValid() : exact;
            hdr.cpu.ingress_port : exact;
        }
        actions = {
            set_port_properties;
            set_cpu_port_properties;
        }
        size = port_table_size * 2;
    }
    action port_vlan_miss() {
    }
    action set_bd_properties(switch_bd_t bd,
                             switch_vrf_t vrf,
                             switch_bd_label_t bd_label,
                             switch_rid_t rid,
                             switch_stp_group_t stp_group,
                             switch_learning_mode_t learning_mode,
                             bool ipv4_unicast_enable,
                             bool ipv4_multicast_enable,
                             bool igmp_snooping_enable,
                             bool ipv6_unicast_enable,
                             bool ipv6_multicast_enable,
                             bool mld_snooping_enable,
                             switch_multicast_rpf_group_t mrpf_group,
                             switch_rmac_group_t rmac_group) {
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
            ig_md.port_lag_index : exact;
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
    table port_vlan_to_bd_mapping {
        key = {
            ig_md.port_lag_index : exact;
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
    action set_interface_properties(switch_ifindex_t ifindex, switch_if_label_t if_label) {
        ig_md.ifindex = ifindex;
        ig_md.checks.same_if = 0xffff;
        ig_md.if_label = if_label;
    }
    table port_vlan_to_ifindex_mapping {
        key = {
            ig_md.port_lag_index : exact;
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
            ig_md.port_lag_index : exact;
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
        key = { ig_md.port_lag_index : exact; }
        actions = {
            NoAction;
            set_peer_link_properties;
        }
        const default_action = NoAction;
        size = port_table_size;
    }
    apply {
        switch (port_mapping.apply().action_run) {
            set_cpu_port_properties : {
                cpu_to_bd_mapping.apply();
            }
            set_port_properties : {
                    if (!port_vlan_to_bd_mapping.apply().hit) {
                        if (hdr.vlan_tag[0].isValid())
                            vlan_to_bd_mapping.apply();
                    }
                }
            }
        if (hdr.vlan_tag[0].isValid() && !hdr.vlan_tag[1].isValid() && (bit<1>) ig_md.flags.port_vlan_miss == 0) {
            bit<32> pv_hash_ = hash.get({ig_md.port[6:0], hdr.vlan_tag[0].vid});
            ig_md.flags.port_vlan_miss =
                (bool)check_vlan_membership.execute(pv_hash_);
        }
    }
}
control LAG(inout switch_ingress_metadata_t ig_md,
            in bit<16> hash,
            out switch_port_t egress_port) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(1024, selector_hash, SelectorMode_t.FAIR) lag_selector;
    action set_lag_port(switch_port_t port) {
        egress_port = port;
    }
    action set_peer_link_port(switch_port_t port, switch_ifindex_t ifindex) {
    }
    action lag_miss() { }
    table lag {
        key = {
            ig_md.egress_ifindex : exact @name("port_lag_index");
            hash : selector;
        }
        actions = {
            lag_miss;
            set_lag_port;
            set_peer_link_port;
        }
        const default_action = lag_miss;
        size = 1024;
        implementation = lag_selector;
    }
    apply {
        lag.apply();
    }
}
control EgressPortMapping(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        in switch_port_t port)(
        switch_uint32_t table_size=288) {
    PortMirror(table_size) port_mirror;
    action port_normal(switch_port_lag_index_t port_lag_index,
                       switch_port_lag_label_t port_lag_label,
                       switch_qos_group_t qos_group,
                       bool mlag_member) {
        eg_md.port_lag_index = port_lag_index;
        eg_md.port_lag_label = port_lag_label;
        eg_md.qos.group = qos_group;
        eg_md.flags.mlag_member = mlag_member;
    }
    action cpu_rewrite() {
        hdr.fabric.setValid();
        hdr.fabric.reserved = 0;
        hdr.fabric.color = 0;
        hdr.fabric.qos = 0;
        hdr.fabric.reserved2 = 0;
        hdr.fabric.dst_port_or_group = 0;
        hdr.cpu.setValid();
        hdr.cpu.egress_queue = 0;
        hdr.cpu.tx_bypass = 0;
        hdr.cpu.capture_ts = 0;
        hdr.cpu.reserved = 0;
        hdr.cpu.ingress_port = (bit<16>) eg_md.ingress_port;
        hdr.cpu.ingress_ifindex = (bit<16>) eg_md.ingress_ifindex;
        hdr.cpu.ingress_bd = (bit<16>) eg_md.bd;
        hdr.cpu.reason_code = eg_md.cpu_reason;
        hdr.cpu.ether_type = hdr.ethernet.ether_type;
        hdr.ethernet.ether_type = 0x9000;
    }
    action port_cpu(switch_port_lag_index_t port_lag_index) {
        cpu_rewrite();
    }
    @ignore_table_dependency("SwitchEgress.mirror_rewrite.rewrite")
    table port_mapping {
        key = { port : exact; }
        actions = {
            port_normal;
            port_cpu;
        }
        size = table_size;
    }
    apply {
        port_mapping.apply();
    }
}
control PktValidation(
        in switch_header_t hdr,
        inout switch_ingress_flags_t flags,
        inout switch_lookup_fields_t lkp,
  in switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
        out ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        out switch_drop_reason_t drop_reason) {
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
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
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
        lkp.ip_src_addr = (bit<128>) hdr.ipv4.src_addr;
        lkp.ip_dst_addr = (bit<128>) hdr.ipv4.dst_addr;
        malformed_pkt(reason);
    }
    action valid_ipv4_pkt(switch_ip_frag_t ip_frag) {
        lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        lkp.ip_tos = hdr.ipv4.diffserv;
        lkp.ip_proto = hdr.ipv4.protocol;
        lkp.ip_ttl = hdr.ipv4.ttl;
        lkp.ip_src_addr = (bit<128>) hdr.ipv4.src_addr;
        lkp.ip_dst_addr = (bit<128>) hdr.ipv4.dst_addr;
        lkp.ip_frag = ip_frag;
    }
    table validate_ipv4 {
        key = {
            flags.ipv4_checksum_err : ternary;
            hdr.ipv4.version : ternary;
            hdr.ipv4.ihl : ternary;
            hdr.ipv4.flags : ternary;
            hdr.ipv4.frag_offset : ternary;
            hdr.ipv4.ttl : ternary;
            hdr.ipv4.src_addr[31:24] : ternary;
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
            hdr.ipv6.version : ternary;
            hdr.ipv6.hop_limit : ternary;
            hdr.ipv6.src_addr[127:96] : ternary;
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
            hdr.icmp.isValid() : exact;
            hdr.igmp.isValid() : exact;
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
    table validate_nsh {
        key = {
            hdr.nsh_extr_underlay.version : range;
            hdr.nsh_extr_underlay.o : ternary;
            hdr.nsh_extr_underlay.ttl : ternary;
            hdr.nsh_extr_underlay.len : range;
            hdr.nsh_extr_underlay.md_type : range;
            hdr.nsh_extr_underlay.next_proto : range;
            hdr.nsh_extr_underlay.si : ternary;
            hdr.nsh_extr_underlay.md_len : range;
        }
        actions = {
            NoAction;
            malformed_pkt;
        }
        size = table_size;
        const default_action = NoAction;
        const entries = {
            (2w1 .. 2w3, _, _, _, _, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_VERSION_INVALID);
            (_, 1, _, _, _, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_OAM);
            (_, _, 0, _, _, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_TTL_ZERO);
            (_, _, _, 6w0 .. 6w4, _, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_LEN_INVALID);
            (_, _, _, 6w6 .. 6w63, _, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_LEN_INVALID);
            (_, _, _, _, 4w0 .. 4w1, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_MDTYPE_INVALID);
            (_, _, _, _, 4w3 .. 4w15, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_MDTYPE_INVALID);
            (_, _, _, _, _, 8w0 .. 8w2, _, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_NEXT_PROTO_INVALID);
            (_, _, _, _, _, 8w4 .. 8w255, _, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_NEXT_PROTO_INVALID);
            (_, _, _, _, _, _, 0, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_SI_ZERO);
            (_, _, _, _, _, _, _, 7w0 .. 7w7):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_MD_LEN_INVALID);
            (_, _, _, _, _, _, _, 7w9 .. 7w127):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_MD_LEN_INVALID);
        }
    }
    action set_udf() {
    }
    table validate_udf {
        key = {
            hdr.udf.isValid() : exact;
        }
        actions = {
            NoAction;
            set_udf;
        }
        const default_action = NoAction;
        const entries = {
            (true) : set_udf();
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
        if (hdr.nsh_extr_underlay.isValid()) {
            switch(validate_nsh.apply().action_run) {
                malformed_pkt : {}
                default: {
                    switch(validate_ethernet.apply().action_run) {
                        malformed_non_ip_pkt : {}
                        default : {
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
        } else {
                    switch(validate_ethernet.apply().action_run) {
                        malformed_non_ip_pkt : {}
                        default : {
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
}
control InnerPktValidation(
        in switch_header_t hdr,
        inout switch_lookup_fields_t lkp,
        inout switch_ingress_flags_t flags,
        inout switch_drop_reason_t drop_reason) {
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
            hdr.inner_ethernet.isValid() : exact;
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
        lkp.ip_src_addr = (bit<128>) hdr.inner_ipv4.src_addr;
        lkp.ip_dst_addr = (bit<128>) hdr.inner_ipv4.dst_addr;
    }
    table validate_ipv4 {
        key = {
            flags.inner_ipv4_checksum_err : ternary;
            hdr.inner_ipv4.version : ternary;
            hdr.inner_ipv4.ihl : ternary;
            hdr.inner_ipv4.ttl : ternary;
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
            hdr.inner_ipv6.version : ternary;
            hdr.inner_ipv6.hop_limit : ternary;
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
            hdr.inner_tcp.isValid() : exact;
            hdr.inner_udp.isValid() : exact;
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
    action set_udf() {
    }
    table validate_udf {
        key = {
            hdr.inner_udf.isValid() : exact;
        }
        actions = {
            NoAction;
            set_udf;
        }
        const default_action = NoAction;
        const entries = {
            (true) : set_udf();
        }
    }
    apply {
        switch(validate_ethernet.apply().action_run) {
            malformed_pkt : {}
            default : {
                if (hdr.inner_ipv4.isValid()) {
                    validate_ipv4.apply();
                } else if (hdr.inner_ipv6.isValid()) {
                }
                validate_other.apply();
            }
        }
    }
}
control IngressTunnel(in switch_header_t hdr,
                      inout switch_ingress_metadata_t ig_md,
                      inout switch_lookup_fields_t lkp)(
                      switch_uint32_t ipv4_src_vtep_table_size=1024,
                      switch_uint32_t ipv6_src_vtep_table_size=1024,
                      switch_uint32_t ipv4_dst_vtep_table_size=1024,
                      switch_uint32_t ipv6_dst_vtep_table_size=1024,
                      switch_uint32_t vni_mapping_table_size=1024) {
    InnerPktValidation() pkt_validation;
    action rmac_hit() { }
    table rmac {
        key = {
            ig_md.rmac_group : exact;
            lkp.mac_dst_addr : exact;
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
    action src_vtep_miss() {}
    table src_vtep {
        key = {
            lkp.ip_src_addr[31:0] : exact @name("src_addr");
            ig_md.vrf : exact;
            ig_md.tunnel.type : exact;
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
            lkp.ip_src_addr : exact @name("src_addr");
            ig_md.vrf : exact;
            ig_md.tunnel.type : exact;
        }
        actions = {
            src_vtep_miss;
            src_vtep_hit;
        }
        const default_action = src_vtep_miss;
        size = ipv6_src_vtep_table_size;
    }
    action dst_vtep_hit() {}
    action set_vni_properties(
            switch_bd_t bd,
            switch_vrf_t vrf,
            switch_bd_label_t bd_label,
            switch_rid_t rid,
            switch_learning_mode_t learning_mode,
            bool ipv4_unicast_enable,
            bool ipv4_multicast_enable,
            bool igmp_snooping_enable,
            bool ipv6_unicast_enable,
            bool ipv6_multicast_enable,
            bool mld_snooping_enable,
            switch_multicast_rpf_group_t mrpf_group,
            switch_rmac_group_t rmac_group) {
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
            lkp.ip_src_addr[31:0] : ternary @name("src_addr");
            lkp.ip_dst_addr[31:0] : ternary @name("dst_addr");
            ig_md.vrf : exact;
            ig_md.tunnel.type : exact;
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
            lkp.ip_src_addr : ternary @name("src_addr");
            lkp.ip_dst_addr : ternary @name("dst_addr");
            ig_md.vrf : exact;
            ig_md.tunnel.type : exact;
        }
        actions = {
            NoAction;
            dst_vtep_hit;
            set_vni_properties;
        }
        const default_action = NoAction;
    }
    table vni_to_bd_mapping {
        key = { ig_md.tunnel.id : exact; }
        actions = {
            NoAction;
            set_vni_properties;
        }
        default_action = NoAction;
        size = vni_mapping_table_size;
    }
    apply {
        switch(rmac.apply().action_run) {
            rmac_hit : {
                if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                    switch(dst_vtep.apply().action_run) {
                        dst_vtep_hit : {
                            vni_to_bd_mapping.apply();
                            pkt_validation.apply(hdr, lkp, ig_md.flags, ig_md.drop_reason);
                        }
                        set_vni_properties : {
                            pkt_validation.apply(hdr, lkp, ig_md.flags, ig_md.drop_reason);
                        }
                    }
                } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
                }
            }
        }
    }
}
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
        key = { hdr.inner_udp.isValid() : exact; }
        actions = {
            decap_inner_udp;
            decap_inner_unknown;
        }
        const default_action = decap_inner_unknown;
        const entries = {
            (true) : decap_inner_udp();
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
        hdr.gre.setInvalid();
        hdr.nvgre.setInvalid();
        hdr.gtp_v1_base.setInvalid();
        hdr.gtp_v2_base.setInvalid();
        hdr.gtp_v1_v2_teid.setInvalid();
        hdr.gtp_v1_optional.setInvalid();
    }
    action decap_inner_ethernet_ipv4() {
        hdr.ethernet = hdr.inner_ethernet;
        copy_ipv4_header();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_tunneling_headers();
    }
    action decap_inner_ethernet_ipv6() {
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
    }
    action invalidate_tunneling_headers_nsh() {
    }
    action decap_underlay_nsh() {
        hdr.ethernet_underlay.setInvalid();
        hdr.vlan_tag_underlay[0].setInvalid();
        invalidate_tunneling_headers();
    }
    apply {
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0) && eg_md.tunnel_nsh.terminate)
            decap_underlay_nsh();
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0) && eg_md.tunnel.terminate)
            decap_inner_ip.apply();
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0) && eg_md.tunnel.terminate)
            decap_inner_l4.apply();
    }
}
control TunnelRewrite(inout switch_header_t hdr,
                      inout switch_egress_metadata_t eg_md)(
                      switch_uint32_t ipv4_dst_addr_rewrite_table_size=1024,
                      switch_uint32_t ipv6_dst_addr_rewrite_table_size=1024,
                      switch_uint32_t nexthop_rewrite_table_size=512,
                      switch_uint32_t src_addr_rewrite_table_size=1024,
                      switch_uint32_t smac_rewrite_table_size=1024) {
    EgressBd(BD_TABLE_SIZE) egress_bd;
    switch_bd_label_t bd_label;
    switch_smac_index_t smac_index;
    switch_bd_t bd_temp;
    mac_addr_t dmac_temp;
    action rewrite_tunnel(switch_bd_t bd, mac_addr_t dmac) {
        bd_temp = bd;
        dmac_temp = dmac;
    }
    action rewrite_tunnel_orig(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.bd = bd;
        hdr.ethernet.dst_addr = dmac;
    }
    action rewrite_tunnel_nsh(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.bd = bd;
        hdr.ethernet_underlay.dst_addr = dmac;
    }
    table nexthop_rewrite {
        key = {
            eg_md.outer_nexthop : exact;
        }
        actions = {
            NoAction;
            rewrite_tunnel_orig;
            rewrite_tunnel_nsh;
        }
        const default_action = NoAction;
        size = nexthop_rewrite_table_size;
    }
    action rewrite_ipv4_src(ipv4_addr_t src_addr) {
        hdr.ipv4.src_addr = src_addr;
    }
    action rewrite_ipv6_src(ipv6_addr_t src_addr) {
    }
    table src_addr_rewrite {
        key = { eg_md.bd : exact; }
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
        key = { eg_md.tunnel.index : exact; }
        actions = { rewrite_ipv4_dst; }
        size = ipv4_dst_addr_rewrite_table_size;
    }
    table ipv6_dst_addr_rewrite {
        key = { eg_md.tunnel.index : exact; }
        actions = { rewrite_ipv6_dst; }
        size = ipv6_dst_addr_rewrite_table_size;
    }
    mac_addr_t smac_temp;
    action rewrite_smac(mac_addr_t smac) {
        smac_temp = smac;
    }
    action rewrite_smac_orig(mac_addr_t smac) {
        hdr.ethernet.src_addr = smac;
    }
    action rewrite_smac_nsh(mac_addr_t smac) {
        hdr.ethernet_underlay.src_addr = smac;
    }
    table smac_rewrite {
        key = { smac_index : exact; }
        actions = {
            NoAction;
            rewrite_smac_orig;
            rewrite_smac_nsh;
        }
        const default_action = NoAction;
        size = smac_rewrite_table_size;
    }
    apply {
        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE)
            nexthop_rewrite.apply();
        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE)
            egress_bd.apply(hdr, eg_md.bd, eg_md.pkt_type, eg_md.pkt_src,
                bd_label, smac_index, eg_md.checks.mtu);
        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE)
            src_addr_rewrite.apply();
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
control TunnelEncap(inout switch_header_t hdr,
                    inout switch_egress_metadata_t eg_md)(
                    switch_tunnel_mode_t mode=switch_tunnel_mode_t.PIPE,
                    switch_uint32_t vni_mapping_table_size=1024) {
    bit<16> payload_len;
    bit<8> ip_proto;
    action set_vni(switch_tunnel_id_t id) {
        eg_md.tunnel.id = id;
    }
    table bd_to_vni_mapping {
        key = { eg_md.bd : exact; }
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
    }
    action rewrite_inner_ipv6_tcp() {
    }
    action rewrite_inner_ipv6_unknown() {
    }
    table encap_outer {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.nsh_extr_underlay.isValid() : exact;
        }
        actions = {
            rewrite_inner_ipv4_udp;
            rewrite_inner_ipv4_unknown;
            rewrite_inner_ipv6_udp;
            rewrite_inner_ipv6_unknown;
        }
        const entries = {
            (true, false, false, false) : rewrite_inner_ipv4_unknown();
            (false, true, false, false) : rewrite_inner_ipv6_unknown();
            (true, false, true, false) : rewrite_inner_ipv4_udp();
            (false, true, true, false) : rewrite_inner_ipv6_udp();
        }
    }
    action add_udp_header(bit<16> src_port, bit<16> dst_port) {
        hdr.udp.setValid();
        hdr.udp.src_port = src_port;
        hdr.udp.dst_port = dst_port;
        hdr.udp.checksum = 0;
    }
    action add_vxlan_header(bit<24> vni) {
        hdr.vxlan.setValid();
        hdr.vxlan.flags = 8w0x08;
        hdr.vxlan.vni = vni;
    }
    action add_gre_header(bit<16> proto, bit<1> K) {
        hdr.gre.setValid();
        hdr.gre.proto = proto;
        hdr.gre.C = 0;
        hdr.gre.R = 0;
        hdr.gre.K = K;
        hdr.gre.S = 0;
        hdr.gre.s = 0;
        hdr.gre.recurse = 0;
        hdr.gre.flags = 0;
        hdr.gre.version = 0;
    }
    action add_nvgre_header(bit<24> vsid, bit<8> flow_id) {
        hdr.nvgre.setValid();
        hdr.nvgre.vsid = vsid;
        hdr.nvgre.flow_id = flow_id;
    }
    action add_gtpc_header(bit<32> teid) {
        hdr.gtp_v2_base.setValid();
        hdr.gtp_v2_base.version = 2;
        hdr.gtp_v2_base.P = 0;
        hdr.gtp_v2_base.T = 1;
        hdr.gtp_v2_base.reserved = 0;
        hdr.gtp_v2_base.msg_type = 0;
        hdr.gtp_v2_base.msg_len = 0;
        hdr.gtp_v1_v2_teid.setValid();
        hdr.gtp_v1_v2_teid.teid = teid;
    }
    action add_gtpu_header(bit<32> teid) {
        hdr.gtp_v1_base.setValid();
        hdr.gtp_v1_base.version = 1;
        hdr.gtp_v1_base.PT = 1;
        hdr.gtp_v1_base.reserved = 0;
        hdr.gtp_v1_base.E = 0;
        hdr.gtp_v1_base.S = 0;
        hdr.gtp_v1_base.PN = 0;
        hdr.gtp_v1_base.msg_type = 0;
        hdr.gtp_v1_base.msg_len = 0;
        hdr.gtp_v1_v2_teid.setValid();
        hdr.gtp_v1_v2_teid.teid = teid;
    }
    action add_erspan_header(bit<32> timestamp, switch_mirror_session_t session_id) {
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
        add_vxlan_header(eg_md.tunnel.id[23:0]);
        hdr.ethernet.ether_type = 0x0800;
    }
    action rewrite_ipv4_ip() {
        add_ipv4_header(ip_proto);
        hdr.ipv4.total_len = payload_len + 16w20;
        hdr.ethernet.ether_type = 0x0800;
    }
    action rewrite_ipv4_nvgre() {
        add_ipv4_header(47);
        hdr.ipv4.total_len = payload_len + 16w28;
        add_gre_header(0x6558, 1);
        add_nvgre_header((bit<24>)eg_md.tunnel.id, 0);
        hdr.ethernet.ether_type = 0x0800;
    }
    action rewrite_ipv4_gtpc() {
        add_ipv4_header(17);
        hdr.ipv4.total_len = payload_len + 16w28;
        add_gtpc_header(eg_md.tunnel.id);
        hdr.ethernet.ether_type = 0x0800;
    }
    action rewrite_ipv4_gtpu() {
        add_ipv4_header(17);
        hdr.ipv4.total_len = payload_len + 16w28;
        add_gtpu_header(eg_md.tunnel.id);
        hdr.ethernet.ether_type = 0x0800;
    }
    action rewrite_ipv6_vxlan(bit<16> vxlan_port) {
    }
    action rewrite_ipv6_ip() {
    }
    action rewrite_ipv6_nvgre() {
    }
    action rewrite_ipv6_gtpc() {
    }
    action rewrite_ipv6_gtpu() {
    }
    action rewrite_mac_in_mac() {
    }
    action rewrite_mac_in_mac_nsh_() {
        hdr.ethernet_underlay.setValid();
        hdr.ethernet_underlay.ether_type = 0x894F;
    }
    action rewrite_mac_in_mac_nsh() {
    }
    table tunnel {
        key = {
            eg_md.tunnel.type : exact;
        }
        actions = {
            NoAction;
            rewrite_ipv4_vxlan;
            rewrite_ipv6_vxlan;
            rewrite_ipv4_ip;
            rewrite_ipv6_ip;
            rewrite_mac_in_mac;
            rewrite_ipv4_nvgre;
            rewrite_ipv6_nvgre;
            rewrite_ipv4_gtpc;
            rewrite_ipv6_gtpc;
            rewrite_ipv4_gtpu;
            rewrite_ipv6_gtpu;
        }
        const default_action = NoAction;
    }
    apply {
        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE && eg_md.tunnel.id == 0)
            bd_to_vni_mapping.apply();
        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
            encap_outer.apply();
            switch(tunnel.apply().action_run) {
                rewrite_mac_in_mac : {
                    if(hdr.nsh_extr_underlay.isValid()) {
                        rewrite_mac_in_mac_nsh_();
                    } else {
                    }
                }
            }
        }
    }
}
control MulticastBridge<T>(
        in ipv4_addr_t src_addr,
        in ipv4_addr_t grp_addr,
        in switch_bd_t bd,
        out switch_mgid_t group_id,
        out bit<1> multicast_hit)(
        switch_uint32_t s_g_table_size,
        switch_uint32_t star_g_table_size) {
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
    DirectCounter<bit<32>>(CounterType_t.PACKETS) star_g_stats;
    action s_g_hit(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        s_g_stats.count();
    }
    action star_g_hit_bidir(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group & multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_BIDIR;
        star_g_stats.count();
    }
    action star_g_hit_sm(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        star_g_stats.count();
    }
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
    table star_g {
        key = {
            vrf : exact;
            grp_addr : exact;
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
    DirectCounter<bit<32>>(CounterType_t.PACKETS) star_g_stats;
    action s_g_hit(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        s_g_stats.count();
    }
    action star_g_hit_bidir(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group & multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_BIDIR;
        star_g_stats.count();
    }
    action star_g_hit_sm(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        star_g_stats.count();
    }
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
    table star_g {
        key = {
            vrf : exact;
            grp_addr : exact;
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
control IngressMulticast(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t ipv4_s_g_table_size,
        switch_uint32_t ipv4_star_g_table_size,
        switch_uint32_t ipv6_s_g_table_size,
        switch_uint32_t ipv6_star_g_table_size) {
    MulticastBridge<ipv4_addr_t>(ipv4_s_g_table_size, ipv4_star_g_table_size) ipv4_multicast_bridge;
    MulticastRoute<ipv4_addr_t>(ipv4_s_g_table_size, ipv4_star_g_table_size) ipv4_multicast_route;
    MulticastBridgev6<ipv6_addr_t>(
        ipv6_s_g_table_size, ipv6_star_g_table_size) ipv6_multicast_bridge;
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
            multicast_hit : ternary;
            lkp.ip_type : ternary;
            ig_md.ipv4.multicast_snooping : ternary;
            ig_md.ipv6.multicast_snooping : ternary;
            ig_md.multicast.mode : ternary;
            rpf_check : ternary;
        }
        actions = {
            set_multicast_bridge;
            set_multicast_route;
            set_multicast_flood;
        }
    }
    apply {
        if (lkp.ip_type == SWITCH_IP_TYPE_IPV4 && ig_md.ipv4.multicast_enable) {
            ipv4_multicast_route.apply(lkp.ip_src_addr[31:0],
                                       lkp.ip_dst_addr[31:0],
                                       ig_md.vrf,
                                       ig_md.multicast,
                                       rpf_check,
                                       ig_md.multicast.id,
                                       multicast_hit);
        } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6 && ig_md.ipv6.multicast_enable) {
            ipv6_multicast_route.apply(lkp.ip_src_addr,
                                       lkp.ip_dst_addr,
                                       ig_md.vrf,
                                       ig_md.multicast,
                                       rpf_check,
                                       ig_md.multicast.id,
                                       multicast_hit);
        }
        if (multicast_hit == 0 ||
            (ig_md.multicast.mode == SWITCH_MULTICAST_MODE_PIM_SM && rpf_check != 0) ||
            (ig_md.multicast.mode == SWITCH_MULTICAST_MODE_PIM_BIDIR && rpf_check == 0)) {
            if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                ipv4_multicast_bridge.apply(lkp.ip_src_addr[31:0],
                                            lkp.ip_dst_addr[31:0],
                                            ig_md.bd,
                                            ig_md.multicast.id,
                                            multicast_hit);
            } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
                ipv6_multicast_bridge.apply(lkp.ip_src_addr,
                                            lkp.ip_dst_addr,
                                            ig_md.bd,
                                            ig_md.multicast.id,
                                            multicast_hit);
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
            ig_md.bd : exact @name("bd");
            ig_md.lkp.pkt_type : exact @name("pkt_type");
            ig_md.flags.flood_to_multicast_routers : exact @name("flood_to_multicast_routers");
        }
        actions = { flood; }
        size = table_size;
    }
    apply {
        bd_flood.apply();
    }
}
control MulticastReplication(in switch_rid_t replication_id,
                             in switch_port_t port,
                             inout switch_egress_metadata_t eg_md)(
                             switch_uint32_t table_size=4096) {
    action rid_hit(
        switch_bd_t bd,
        bit<24> spi,
        bit<8> si,
        bit<8> sf_bitmask_local,
        bit<8> sf_bitmask_remote,
        bit<16> tenant_id,
        bit<8> flow_type
    ) {
        eg_md.checks.same_bd = bd ^ eg_md.bd;
        eg_md.bd = bd;
        eg_md.nsh_extr.spi = spi;
        eg_md.nsh_extr.si = si;
        eg_md.nsh_extr.extr_sf_bitmask_local = sf_bitmask_local;
        eg_md.nsh_extr.extr_sf_bitmask_remote = sf_bitmask_remote;
        eg_md.nsh_extr.extr_tenant_id = tenant_id;
        eg_md.nsh_extr.extr_flow_type = flow_type;
    }
    action rid_miss() {
        eg_md.flags.routed = false;
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
        if (replication_id != 0)
            rid.apply();
        if (eg_md.checks.same_bd == 0)
            eg_md.flags.routed = false;
    }
}
control IngressPolicer(in switch_ingress_metadata_t ig_md,
                       inout switch_qos_metadata_t qos_md,
                       out bool flag)(
                       switch_uint32_t table_size=1024) {
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
            qos_md.acl_policer_color : exact;
            qos_md.meter_index : exact;
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
        qos_md.acl_policer_color = (bit<2>) meter.execute();
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
    }
}
control StormControl(inout switch_ingress_metadata_t ig_md,
                     in switch_pkt_type_t pkt_type,
                     out bool flag)(
                     switch_uint32_t table_size=512) {
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
            pkt_type : ternary;
            ig_md.port: exact;
            ig_md.flags.dmac_miss : ternary;
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
        ig_md.qos.storm_control_color = (bit<2>) meter.execute(index);
    }
    table storm_control {
        key = {
            ig_md.port : exact;
            pkt_type : ternary;
            ig_md.flags.dmac_miss : ternary;
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
control PortPolicer(in switch_port_t port,
                     out bool flag)(
                     switch_uint32_t table_size=288) {
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
            port: exact;
        }
        actions = {
            @defaultonly NoAction;
            permit_and_count;
            drop_and_count;
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
            port : exact;
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
control PortPolicer2(in switch_port_t port,
                     out bool flag)(
                     switch_uint32_t table_size=288) {
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
            port: exact;
        }
        actions = {
            @defaultonly NoAction;
            permit_and_count;
            drop_and_count;
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
            port : exact;
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
action set_ingress_tc_and_color(
        inout switch_qos_metadata_t qos_md, switch_tc_t tc, switch_pkt_color_t color) {
    set_ingress_tc(qos_md, tc);
    set_ingress_color(qos_md, color);
}
action set_ingress_meter(
        inout switch_qos_metadata_t qos_md,
        switch_policer_meter_index_t index) {
    qos_md.meter_index = index;
}
action set_ingress_tc_color_and_meter(
        inout switch_qos_metadata_t qos_md,
        switch_tc_t tc,
        switch_pkt_color_t color,
        switch_policer_meter_index_t index) {
}
control MacQosAcl(
    in switch_lookup_fields_t lkp,
    inout switch_ingress_metadata_t ig_md)(
    switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.mac_src_addr : ternary; lkp.mac_dst_addr : ternary; lkp.mac_type : ternary;
            ig_md.port_lag_label : ternary;
            lkp.pcp : ternary;
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
control Ipv4QosAcl(
    in switch_lookup_fields_t lkp,
    inout switch_ingress_metadata_t ig_md)(
    switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.ip_src_addr[31:0] : ternary; lkp.ip_dst_addr[31:0] : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.ip_frag : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
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
control Ipv6QosAcl(
    in switch_lookup_fields_t lkp,
    inout switch_ingress_metadata_t ig_md)(
    switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
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
control IpQosAcl(
    in switch_lookup_fields_t lkp,
    inout switch_ingress_metadata_t ig_md)(
    switch_uint32_t table_size=512) {
    table acl {
        key = {
            lkp.mac_type : ternary; lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
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
control ECNAcl(in switch_ingress_metadata_t ig_md,
               in switch_lookup_fields_t lkp,
               inout switch_pkt_color_t pkt_color)(
               switch_uint32_t table_size=512) {
    action set_ingress_color(switch_pkt_color_t color) {
        pkt_color = color;
    }
    table acl {
        key = {
            ig_md.port_lag_label : ternary;
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
control PFCWd(in switch_port_t port,
               in switch_qid_t qid,
               out bool flag)(
               switch_uint32_t table_size=512) {
    DirectCounter<bit<16>>(CounterType_t.PACKETS_AND_BYTES) stats;
    action acl_deny() {
        flag = true;
        stats.count();
    }
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
    }
}
control IngressQoS(
        in switch_header_t hdr,
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t dscp_map_size=1024,
        switch_uint32_t pcp_map_size=1024) {
    const bit<32> ppg_table_size = 1024;
    const bit<32> queue_table_size = 1024;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) ppg_stats;
    IngressPolicer(1 << 10) policer;
    MacQosAcl() mac_acl;
    IpQosAcl() ip_acl;
    table dscp_tc_map {
        key = {
            ig_md.qos.group : exact;
            lkp.ip_tos : exact;
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
            ig_md.qos.group : ternary;
            lkp.pcp : exact;
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
            ig_md.port : ternary @name("port");
            ig_md.qos.color : ternary @name("color");
            ig_md.qos.tc : exact @name("tc");
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
            ig_md.port : exact @name("port");
            ig_md.qos.icos : exact @name("icos");
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
    }
}
control EgressQoS(inout switch_header_t hdr,
                  in switch_port_t port,
                  inout switch_egress_metadata_t eg_md)(
                  switch_uint32_t table_size=1024) {
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
            eg_md.qos.group : ternary @name("group");
            eg_md.qos.tc : ternary @name("tc");
            eg_md.qos.color : ternary @name("color");
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
    action count() {
        queue_stats.count();
    }
    table queue {
        key = {
            port : exact;
            eg_md.qos.qid : exact @name("qid");
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
    }
}
control WRED(inout switch_header_t hdr,
             in switch_egress_metadata_t eg_md,
             in egress_intrinsic_metadata_t eg_intr_md,
             out bool flag) {
    switch_wred_index_t index;
    bit<1> wred_flag;
    const switch_uint32_t wred_size = 1 << 8;
    const switch_uint32_t wred_index_table_size = 2048;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    Wred<bit<19>, switch_wred_index_t>(wred_size, 1 , 0 ) wred;
    action set_ipv4_ecn() {
        hdr.ipv4.diffserv[1:0] = SWITCH_ECN_CODEPOINT_CE;
    }
    action set_ipv6_ecn() {
        hdr.ipv6.traffic_class[1:0] = SWITCH_ECN_CODEPOINT_CE;
    }
    action drop() {
        flag = true;
    }
    table wred_action {
        key = {
            index : exact;
            hdr.ipv4.isValid() : ternary;
            hdr.ipv4.diffserv : ternary;
            hdr.ipv6.isValid() : ternary;
            hdr.ipv6.traffic_class : ternary;
        }
        actions = {
            NoAction;
            drop;
            set_ipv4_ecn;
            set_ipv6_ecn;
        }
        size = 4 * wred_size;
    }
    action set_wred_index(switch_wred_index_t wred_index) {
        index = wred_index;
        wred_flag = (bit<1>) wred.execute(eg_md.qos.qdepth, wred_index);
    }
    table wred_index {
        key = {
           eg_intr_md.egress_port : exact @name("port");
           eg_md.qos.qid : exact @name("qid");
           eg_md.qos.color : exact @name("color");
        }
        actions = {
            NoAction;
            set_wred_index;
        }
        const default_action = NoAction;
        size = wred_index_table_size;
    }
    action count() { stats.count(); }
    table wred_stats {
        key = {
            eg_intr_md.egress_port : exact @name("port");
            eg_md.qos.qid : exact @name("qid");
            eg_md.qos.color : exact @name("color");
            flag : exact;
        }
        actions = {
            @defaultonly NoAction;
            count;
        }
        const default_action = NoAction;
        size = 2 * wred_index_table_size;
        counters = stats;
    }
    apply {
    }
}
control DtelAcl(in switch_lookup_fields_t lkp,
                in switch_ingress_metadata_t ig_md,
                out switch_dtel_report_type_t report_type)(
                switch_uint32_t table_size=512) {
    action acl_hit(switch_dtel_report_type_t type) {
        report_type = type;
    }
    table acl {
        key = {
            lkp.mac_type : ternary; lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }
        actions = {
            acl_hit;
        }
        const default_action = acl_hit(SWITCH_DTEL_REPORT_TYPE_NONE);
        size = table_size;
    }
    apply {
        acl.apply();
    }
}
control Ipv4DtelAcl(in switch_lookup_fields_t lkp,
                    in switch_ingress_metadata_t ig_md,
                    out switch_dtel_report_type_t report_type)(
                    switch_uint32_t table_size=512) {
    action acl_hit(switch_dtel_report_type_t type) {
        report_type = type;
    }
    table acl {
        key = {
            lkp.ip_src_addr[31:0] : ternary; lkp.ip_dst_addr[31:0] : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.ip_frag : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }
        actions = {
            acl_hit();
        }
        const default_action = acl_hit(SWITCH_DTEL_REPORT_TYPE_NONE);
        size = table_size;
    }
    apply {
        acl.apply();
    }
}
control Ipv6DtelAcl(in switch_lookup_fields_t lkp,
                    in switch_ingress_metadata_t ig_md,
                    out switch_dtel_report_type_t report_type)(
                    switch_uint32_t table_size=512) {
    action acl_hit(switch_dtel_report_type_t type) {
        report_type = type;
    }
    table acl {
        key = {
            lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }
        actions = {
            acl_hit();
        }
        const default_action = acl_hit(SWITCH_DTEL_REPORT_TYPE_NONE);
        size = table_size;
    }
    apply {
        acl.apply();
    }
}
control DeflectOnDrop(
        in switch_ingress_metadata_t ig_md,
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
            ig_md.dtel.report_type : ternary;
            ig_intr_md_for_tm.ucast_egress_port : ternary @name("egress_port");
            ig_md.qos.qid: ternary @name("qid");
            ig_md.multicast.id : ternary;
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
control MirrorOnDrop(in switch_drop_reason_t drop_reason,
                     inout switch_dtel_metadata_t dtel_md,
                     inout switch_mirror_metadata_t mirror_md) {
    action mirror() {
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
        }
        const default_action = NoAction;
    }
    apply {
        config.apply();
    }
}
control DropReport(in switch_dtel_metadata_t dtel_md, in bit<32> hash, inout bit<2> flag) {
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
        flag = 0;
        if (dtel_md.report_type & (SWITCH_DTEL_REPORT_TYPE_DROP | SWITCH_DTEL_SUPPRESS_REPORT) == SWITCH_DTEL_REPORT_TYPE_DROP)
            flag[0:0] = filter1.execute(hash[16:0]);
        if (dtel_md.report_type & (SWITCH_DTEL_REPORT_TYPE_DROP | SWITCH_DTEL_SUPPRESS_REPORT) == SWITCH_DTEL_REPORT_TYPE_DROP)
            flag[1:1] = filter2.execute(hash[31:15]);
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
control QueueReport(inout switch_egress_metadata_t eg_md,
                    in egress_intrinsic_metadata_t eg_intr_md,
                    out bit<1> qalert) {
    bit<16> quota_;
    const bit<32> queue_table_size = 1024;
    const bit<32> queue_register_size = 2048;
    Register<switch_queue_alert_threshold_t, bit<16>>(queue_register_size) thresholds;
    RegisterAction<switch_queue_alert_threshold_t, bit<16>, bit<1>>(thresholds) check_thresholds = {
        void apply(inout switch_queue_alert_threshold_t reg, out bit<1> flag) {
            if (reg.latency <= eg_md.dtel.latency || reg.qdepth <= (bit<32>) eg_intr_md.enq_qdepth) {
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
    table queue_alert {
        key = {
            eg_md.qos.qid : exact @name("qid");
            eg_md.port : exact @name("port");
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
            reg.counter = (bit<32>) quota_[15:0];
        }
    };
    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) check_latency_and_update_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            flag = 0;
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
            flag = 0;
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
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_QUEUE;
        qalert = update_quota.execute(index);
    }
    action check_latency_and_update_quota_(bit<16> index) {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_QUEUE;
        qalert = check_latency_and_update_quota.execute(index);
    }
    table check_quota {
        key = {
            eg_md.pkt_src : exact;
            qalert : exact;
            eg_md.qos.qid : exact @name("qid");
            eg_md.port : exact @name("port");
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
        if (eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
            queue_alert.apply();
        check_quota.apply();
    }
}
control FlowReport(inout switch_egress_metadata_t eg_md, out bit<2> flag) {
    bit<16> digest;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) hash;
    Register<bit<16>, bit<16>>(1 << 16, 0) array1;
    Register<bit<16>, bit<16>>(1 << 16, 0) array2;
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
    }
}
control IngressDtel(in switch_header_t hdr,
                    in switch_lookup_fields_t lkp,
                    inout switch_ingress_metadata_t ig_md,
                    in bit<16> hash,
                    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                    inout ingress_intrinsic_metadata_for_tm_t ig_intr_for_tm) {
    Ipv4DtelAcl() ipv4_dtel_acl;
    DtelAcl() dtel_acl;
    DeflectOnDrop() dod;
    MirrorOnDrop() mod;
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(120, selector_hash, SelectorMode_t.FAIR) session_selector;
    action set_mirror_session(switch_mirror_session_t session_id) {
        ig_md.dtel.session_id = session_id;
    }
    table mirror_session {
        key = { hash : selector; }
        actions = {
            NoAction;
            set_mirror_session;
        }
        implementation = session_selector;
    }
    apply {
    }
}
control EgressDtel(inout switch_header_t hdr,
                   inout switch_egress_metadata_t eg_md,
                   in egress_intrinsic_metadata_t eg_intr_md,
                   in bit<32> hash,
                   inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    DropReport() drop_report;
    QueueReport() queue_report;
    FlowReport() flow_report;
    bit<2> drop_report_flag;
    bit<2> flow_report_flag;
    bit<1> queue_report_flag;
    Register<bit<32>, switch_mirror_session_t>(1024) seq_number;
    RegisterAction<bit<32>, switch_mirror_session_t, bit<32>>(seq_number) get_seq_number = {
        void apply(inout bit<32> reg, out bit<32> rv) {
            reg = reg + 1;
            rv = reg;
        }
    };
    action mirror() {
        eg_md.mirror.type = 4;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
    }
    action drop() {
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }
    action update(
            switch_uint32_t switch_id,
            bit<6> hw_id,
            bit<4> next_proto,
            switch_dtel_report_type_t report_type) {
        hdr.dtel.setValid();
        hdr.dtel.version = 0;
        hdr.dtel.next_proto = next_proto;
        hdr.dtel.d_q_f = (bit<3>) report_type;
        hdr.dtel.reserved = 0;
        hdr.dtel.hw_id = hw_id;
        hdr.dtel.seq_number = get_seq_number.execute(eg_md.dtel.session_id);
        hdr.dtel.timestamp = (bit<32>) eg_md.ingress_timestamp;
        hdr.dtel.switch_id = switch_id;
    }
    table config {
        key = {
            eg_md.pkt_src : ternary;
            eg_md.dtel.report_type : ternary;
            drop_report_flag : ternary;
            flow_report_flag : ternary;
            queue_report_flag : ternary;
        }
        actions = {
            NoAction;
            drop;
            mirror;
            update;
        }
        const default_action = NoAction;
    }
    action convert_ingress_port(switch_port_t port) {
        hdr.dtel_drop_report.ingress_port = port;
    }
    table ingress_port_conversion {
        key = { hdr.dtel_drop_report.ingress_port : exact @name("port"); }
        actions = {
            NoAction;
            convert_ingress_port;
        }
        const default_action = NoAction;
    }
    action convert_egress_port(switch_port_t port) {
        hdr.dtel_drop_report.egress_port = port;
    }
    table egress_port_conversion {
        key = { hdr.dtel_drop_report.egress_port : exact @name("port"); }
        actions = {
            NoAction;
            convert_egress_port;
        }
        const default_action = NoAction;
    }
    action convert_ingress_port2(switch_port_t port) {
        hdr.dtel_switch_local_report.ingress_port = port;
    }
    table ingress_port_conversion2 {
        key = { hdr.dtel_switch_local_report.ingress_port : exact @name("port"); }
        actions = {
            NoAction;
            convert_ingress_port2;
        }
        const default_action = NoAction;
    }
    action convert_egress_port2(switch_port_t port) {
        hdr.dtel_switch_local_report.egress_port = port;
    }
    table egress_port_conversion2 {
        key = { hdr.dtel_switch_local_report.egress_port : exact @name("port"); }
        actions = {
            NoAction;
            convert_egress_port2;
        }
        const default_action = NoAction;
    }
    apply {
    }
}
control npb_ing_sfc_top (
 inout switch_header_t hdr,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {
 bit<8> sfc_internal;
 action ing_sfc_sfc_classifier_123_hit (
  bit<24> nsh_sph_spi,
  bit<8> nsh_sph_si,
  bit<8> flow_type,
  bit<8> sf_bitmask_local,
  bit<8> sfc
 ) {
  ig_md.nsh_extr.valid = 1;
  ig_md.nsh_extr.spi = nsh_sph_spi;
  ig_md.nsh_extr.si = nsh_sph_si;
  ig_md.nsh_extr.extr_flow_type = flow_type;
  ig_md.nsh_extr.extr_sf_bitmask_local = sf_bitmask_local;
 }
 table ing_sfc_sfc_class_123 {
  key = {
   ig_md.lkp.ip_type : exact;
   ig_md.lkp.ip_proto : exact;
   ig_md.lkp.l4_src_port : ternary;
   ig_md.lkp.l4_dst_port : ternary;
   ig_md.nsh_extr.extr_tenant_id : exact;
  }
  actions = {
   NoAction;
   ing_sfc_sfc_classifier_123_hit;
  }
  const default_action = NoAction;
  size = NPB_ING_SFC_FLOW_TYPE_TABLE_DEPTH;
 }
 action ing_sfc_flowtype_classifier_1_hit (
  bit<8> flow_type
 ) {
  ig_md.nsh_extr.extr_flow_type = flow_type;
 }
 table ing_sfc_flowtype_class_1 {
  key = {
   ig_md.lkp.ip_type : exact;
   ig_md.lkp.ip_proto : exact;
   ig_md.lkp.l4_src_port : ternary;
   ig_md.lkp.l4_dst_port : ternary;
   ig_md.nsh_extr.extr_tenant_id : exact;
  }
  actions = {
   NoAction;
   ing_sfc_flowtype_classifier_1_hit;
  }
  const default_action = NoAction;
  size = NPB_ING_SFC_FLOW_TYPE_TABLE_DEPTH;
 }
 action ing_sfc_sfc_classifier_23_hit (
  bit<24> nsh_sph_spi,
  bit<8> nsh_sph_si,
  bit<8> sf_bitmask_local,
  bit<8> sfc
 ) {
  ig_md.nsh_extr.valid = 1;
  ig_md.nsh_extr.spi = nsh_sph_spi;
  ig_md.nsh_extr.si = nsh_sph_si;
  ig_md.nsh_extr.extr_sf_bitmask_local = sf_bitmask_local;
 }
 table ing_sfc_sfc_class_23 {
  key = {
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }
  actions = {
   NoAction;
   ing_sfc_sfc_classifier_23_hit;
  }
  const default_action = NoAction;
  size = NPB_ING_SFC_NSH_TABLE_DEPTH;
 }
 action ing_sfc_sfc_classifier_2_hit (
  bit<8> nsh_sph_si,
  bit<8> sf_bitmask_local,
  bit<8> sfc
 ) {
  ig_md.nsh_extr.si = nsh_sph_si;
  ig_md.nsh_extr.extr_sf_bitmask_local = sf_bitmask_local;
  sfc_internal = sfc;
 }
 table ing_sfc_sfc_class_2 {
  key = {
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }
  actions = {
   NoAction;
   ing_sfc_sfc_classifier_2_hit;
  }
  const default_action = NoAction;
  size = NPB_ING_SFC_NSH_TABLE_DEPTH;
 }
 action ing_sfc_flow_schd_3_hit (
  bit<24> nsh_sph_spi
 ) {
  ig_md.nsh_extr.valid = 1;
  ig_md.nsh_extr.spi = nsh_sph_spi;
 }
 table ing_sfc_flow_schd_3 {
  key = {
   sfc_internal : exact;
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }
  actions = {
   NoAction;
   ing_sfc_flow_schd_3_hit;
  }
  const default_action = NoAction;
  size = NPB_ING_SFC_NSH_TABLE_DEPTH;
 }
 apply {
  if(hdr.nsh_extr_underlay.isValid()) {
   ig_md.nsh_extr.valid = 1;
   ig_md.nsh_extr.spi = hdr.nsh_extr_underlay.spi;
   ig_md.nsh_extr.si = hdr.nsh_extr_underlay.si;
   ig_md.nsh_extr.extr_sf_bitmask_local = hdr.nsh_extr_underlay.extr_sf_bitmask;
   ig_md.nsh_extr.extr_tenant_id = hdr.nsh_extr_underlay.extr_tenant_id;
   ig_md.nsh_extr.extr_flow_type = hdr.nsh_extr_underlay.extr_flow_type;
  } else {
   ing_sfc_sfc_class_123.apply();
  }
  ig_md.nsh_extr.extr_tenant_id = (bit<16>)ig_md.bd;
 }
}
control npb_ing_sf_npb_basic_adv_top (
 inout switch_header_t hdr,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {
 bit<8> flow_type_new;
 bit<8> nsh_sph_si_new;
 bit<8> nsh_sf_bitmask_local_new;
 bit<8> nsh_sf_bitmask_remote_new;
 bit<8> sfc_internal;
 bit<1> action_bitmask_internal;
 bit<1> table_1_hit_internal;
 bit<32> ig_md_lkp_ip_src_addr;
 bit<32> ig_md_lkp_ip_dst_addr;
 action npb_ing_sf_policy_hit_drop (
 ) {
  ig_md.nsh_extr.valid = 0;
 }
 action npb_ing_sf_policy_hit_send (
  bit<8> flow_type,
  bit<8> nsh_sph_si,
  bit<8> sf_bitmask_local,
  bit<8> sf_bitmask_remote,
  bit<8> sfc,
  bit<1> action_bitmask
 ) {
  flow_type_new = flow_type;
  nsh_sph_si_new = nsh_sph_si;
  nsh_sf_bitmask_local_new = sf_bitmask_local;
  nsh_sf_bitmask_remote_new = sf_bitmask_remote;
  sfc_internal = sfc;
  action_bitmask_internal = action_bitmask;
  table_1_hit_internal = 1;
 }
 table npb_ing_sf_policy_l2347_v4 {
  key = {
   ig_md.lkp.mac_src_addr : ternary;
   ig_md.lkp.mac_dst_addr : ternary;
   ig_md.lkp.mac_type : ternary;
   ig_md.lkp.ip_type : ternary;
   ig_md.lkp.ip_proto : ternary;
   ig_md_lkp_ip_src_addr : ternary;
   ig_md_lkp_ip_dst_addr : ternary;
   ig_md.lkp.l4_src_port : ternary;
   ig_md.lkp.l4_dst_port : ternary;
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }
  actions = {
   NoAction;
   npb_ing_sf_policy_hit_send;
   npb_ing_sf_policy_hit_drop;
  }
  const default_action = NoAction;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L2_TABLE_DEPTH;
 }
 table npb_ing_sf_policy_l2347_v6 {
  key = {
   ig_md.lkp.mac_src_addr : ternary;
   ig_md.lkp.mac_dst_addr : ternary;
   ig_md.lkp.mac_type : ternary;
   ig_md.lkp.ip_type : ternary;
   ig_md.lkp.ip_proto : ternary;
   ig_md.lkp.ip_src_addr : ternary;
   ig_md.lkp.ip_dst_addr : ternary;
   ig_md.lkp.l4_src_port : ternary;
   ig_md.lkp.l4_dst_port : ternary;
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }
  actions = {
   NoAction;
   npb_ing_sf_policy_hit_send;
   npb_ing_sf_policy_hit_drop;
  }
  const default_action = NoAction;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L2_TABLE_DEPTH;
 }
 table npb_ing_sf_policy_l2 {
  key = {
   ig_md.lkp.mac_src_addr : ternary;
   ig_md.lkp.mac_dst_addr : ternary;
   ig_md.lkp.mac_type : ternary;
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }
  actions = {
   NoAction;
   npb_ing_sf_policy_hit_send;
   npb_ing_sf_policy_hit_drop;
  }
  const default_action = NoAction;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L2_TABLE_DEPTH;
 }
 table npb_ing_sf_policy_l34_v4 {
  key = {
   ig_md.lkp.ip_type : ternary;
   ig_md.lkp.ip_proto : ternary;
   ig_md_lkp_ip_src_addr : ternary;
   ig_md_lkp_ip_dst_addr : ternary;
   ig_md.lkp.l4_src_port : ternary;
   ig_md.lkp.l4_dst_port : ternary;
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }
  actions = {
   NoAction;
   npb_ing_sf_policy_hit_send;
   npb_ing_sf_policy_hit_drop;
  }
  const default_action = NoAction;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L3_V4_TABLE_DEPTH;
 }
 table npb_ing_sf_policy_l34_v6 {
  key = {
   ig_md.lkp.ip_type : ternary;
   ig_md.lkp.ip_proto : ternary;
   ig_md.lkp.ip_src_addr : ternary;
   ig_md.lkp.ip_dst_addr : ternary;
   ig_md.lkp.l4_src_port : ternary;
   ig_md.lkp.l4_dst_port : ternary;
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }
  actions = {
   NoAction;
   npb_ing_sf_policy_hit_send;
   npb_ing_sf_policy_hit_drop;
  }
  const default_action = NoAction;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L3_V6_TABLE_DEPTH;
 }
 table npb_ing_sf_policy_l7 {
  key = {
   ig_md.lkp.l4_src_port : ternary;
   ig_md.lkp.l4_dst_port : ternary;
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }
  actions = {
   NoAction;
   npb_ing_sf_policy_hit_send;
   npb_ing_sf_policy_hit_drop;
  }
  const default_action = NoAction;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L3_V6_TABLE_DEPTH;
 }
 action npb_ing_sf_flow_schd_hit (
  bit<24> nsh_sph_spi
 ) {
  ig_md.nsh_extr.extr_flow_type = flow_type_new;
  ig_md.nsh_extr.spi = nsh_sph_spi;
  ig_md.nsh_extr.si = nsh_sph_si_new;
  ig_md.nsh_extr.extr_sf_bitmask_local = nsh_sf_bitmask_local_new;
  ig_md.nsh_extr.extr_sf_bitmask_remote = nsh_sf_bitmask_remote_new;
 }
 action npb_ing_sf_flow_schd_miss (
 ) {
 }
 table npb_ing_sf_flow_schd {
  key = {
   sfc_internal : exact;
   ig_md.nsh_extr.extr_tenant_id : exact;
   flow_type_new : exact;
  }
  actions = {
   NoAction;
   npb_ing_sf_flow_schd_hit;
   npb_ing_sf_flow_schd_miss;
  }
  const default_action = npb_ing_sf_flow_schd_miss;
  size = NPB_ING_SF_0_BAS_ADV_SCHD_TABLE_PART1_DEPTH;
 }
 apply {
  ig_md_lkp_ip_src_addr = ig_md.lkp.ip_src_addr[31:0];
  ig_md_lkp_ip_dst_addr = ig_md.lkp.ip_dst_addr[31:0];
  if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
   npb_ing_sf_policy_l2347_v4.apply();
  } else if(ig_md.lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
   npb_ing_sf_policy_l2347_v6.apply();
  }
  if(action_bitmask_internal[0:0] == 1) {
  }
  if(table_1_hit_internal == 1) {
   npb_ing_sf_flow_schd.apply();
  }
  ig_md.nsh_extr.si = ig_md.nsh_extr.si - 1;
 }
}
control npb_ing_sff_top (
 inout switch_header_t hdr,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {
 bit<8> ig_md_nsh_extr_si;
 action drop_pkt (
 ) {
  ig_intr_md_for_dprsr.drop_ctl = 0x1;
 }
 action dmac_miss(
  bit<8> sf_bitmask_remote,
  bool end_of_chain
 ) {
  ig_md.egress_ifindex = SWITCH_IFINDEX_FLOOD;
        ig_md.flags.dmac_miss = true;
  ig_md.nsh_extr.extr_sf_bitmask_remote = sf_bitmask_remote;
  ig_md.nsh_extr.terminate = end_of_chain;
 }
 action dmac_hit(
  switch_ifindex_t ifindex,
  switch_port_lag_index_t port_lag_index,
  bit<8> sf_bitmask_remote,
  bool end_of_chain
 ) {
  ig_md.egress_ifindex = ifindex;
  ig_md.egress_port_lag_index = port_lag_index;
  ig_md.checks.same_if = ig_md.ifindex ^ ifindex;
  ig_md.nsh_extr.extr_sf_bitmask_remote = sf_bitmask_remote;
  ig_md.nsh_extr.terminate = end_of_chain;
 }
 action dmac_multicast(
  switch_mgid_t index,
  bit<8> sf_bitmask_remote,
  bool end_of_chain
 ) {
        ig_md.multicast.id = index;
  ig_md.nsh_extr.extr_sf_bitmask_remote = sf_bitmask_remote;
  ig_md.nsh_extr.terminate = end_of_chain;
 }
 action dmac_redirect(
  switch_nexthop_t nexthop_index,
  bit<8> sf_bitmask_remote,
  bool end_of_chain
 ) {
  ig_md.nexthop = nexthop_index;
  ig_md.nsh_extr.extr_sf_bitmask_remote = sf_bitmask_remote;
  ig_md.nsh_extr.terminate = end_of_chain;
 }
 action fib_hit(
  switch_nexthop_t nexthop_index,
  bit<8> sf_bitmask_remote,
  bool end_of_chain
 ) {
  ig_md.nexthop = nexthop_index;
  ig_md.flags.routed = true;
  ig_md.nsh_extr.extr_sf_bitmask_remote = sf_bitmask_remote;
  ig_md.nsh_extr.terminate = end_of_chain;
 }
 action fib_miss(
  bit<8> sf_bitmask_remote,
  bool end_of_chain
 ) {
  ig_md.flags.routed = false;
  ig_md.nsh_extr.extr_sf_bitmask_remote = sf_bitmask_remote;
  ig_md.nsh_extr.terminate = end_of_chain;
 }
 action fib_myip(
  bit<8> sf_bitmask_remote,
  bool end_of_chain
 ) {
  ig_md.flags.myip = true;
  ig_md.nsh_extr.extr_sf_bitmask_remote = sf_bitmask_remote;
  ig_md.nsh_extr.terminate = end_of_chain;
 }
 table npb_ing_sff_arp {
  key = {
   ig_md.nsh_extr.spi : exact;
   ig_md_nsh_extr_si : exact;
  }
  actions = {
   drop_pkt;
   dmac_miss;
   dmac_hit;
   dmac_multicast;
   dmac_redirect;
   fib_miss;
   fib_hit;
   fib_myip;
  }
  const default_action = drop_pkt;
  size = NPB_ING_SFF_ARP_TABLE_DEPTH;
 }
 bit<2> nsh_si_dec_amount;
    action new_si(bit<2> dec) {
        nsh_si_dec_amount = dec;
    }
    table npb_ing_sff_dec_si {
        key = { ig_md.nsh_extr.extr_sf_bitmask_local[2:0] : exact; }
        actions = { new_si; }
        const entries = {
            0 : new_si(0);
            1 : new_si(0);
            2 : new_si(1);
            3 : new_si(1);
            4 : new_si(1);
            5 : new_si(1);
            6 : new_si(2);
            7 : new_si(2);
        }
    }
 apply {
  ig_md.flags.dmac_miss = false;
  if(ig_md.nsh_extr.valid == 1) {
  }
   if(ig_md.nsh_extr.extr_sf_bitmask_local[0:0] == 1) {
    npb_ing_sf_npb_basic_adv_top.apply (
     hdr,
     ig_md,
     ig_intr_md,
     ig_intr_md_from_prsr,
     ig_intr_md_for_dprsr,
     ig_intr_md_for_tm
    );
   }
  if(ig_md.nsh_extr.valid == 1) {
   npb_ing_sff_dec_si.apply();
   ig_md_nsh_extr_si = ig_md.nsh_extr.si |-| (bit<8>)nsh_si_dec_amount;
   npb_ing_sff_arp.apply();
  }
 }
}
control npb_egr_sf_proxy_top_part1 (
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {
 action egr_sf_action_sel_hit(
  bit<5> action_bitmask,
  bit<10> action_3_meter_id,
  bit<8> action_3_meter_overhead
 ) {
  eg_md.action_bitmask = action_bitmask;
  eg_md.action_3_meter_id = action_3_meter_id;
  eg_md.action_3_meter_overhead = action_3_meter_overhead;
 }
 action egr_sf_action_sel_miss(
 ) {
  eg_md.action_bitmask = 0;
 }
 table egr_sf_action_sel {
  key = {
      hdr.nsh_extr_underlay.spi : exact;
      hdr.nsh_extr_underlay.si : exact;
  }
  actions = {
      egr_sf_action_sel_hit;
      egr_sf_action_sel_miss;
  }
  const default_action = egr_sf_action_sel_miss;
  size = NPB_EGR_SF_2_EGRESS_SFP_TABLE_DEPTH;
 }
 apply {
  egr_sf_action_sel.apply();
 }
}
control npb_egr_sf_proxy_meter (
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {
 bit<8> temp;
 DirectMeter(MeterType_t.BYTES) direct_meter;
 action set_color_direct() {
  temp = direct_meter.execute();
 }
 table direct_meter_color {
  key = {
   eg_md.action_3_meter_id : exact;
  }
  actions = {
   set_color_direct;
  }
  meters = direct_meter;
  size = 1024;
 }
 apply {
  direct_meter_color.apply();
  if(temp == 0) {
   eg_intr_md_for_dprsr.drop_ctl = 0x1;
  }
 }
}
struct pair_t {
 bit<16> hash;
 bit<16> data;
};
control npb_ing_sf_npb_basic_adv_dedup_reg (
 in switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport,
 in bit<17> flowtable_hash_lo,
 in bit<16> flowtable_hash_hi
) {
 Register <pair_t, bit<17>>(32w131072) test_reg;
 RegisterAction<pair_t, bit<17>, bit<8>>(test_reg) register_array = {
  void apply(
   inout pair_t reg_value,
   out bit<8> return_value
  ) {
   if(reg_value.hash == flowtable_hash_hi) {
    if(reg_value.data == (bit<16>)(eg_md.ingress_port)) {
     return_value = 0;
    } else {
     return_value = 1;
    }
   } else {
    reg_value.hash = flowtable_hash_hi;
    reg_value.data = (bit<16>)(eg_md.ingress_port);
    return_value = 0;
   }
  }
 };
 apply {
  bit<8> return_value;
  return_value = register_array.execute(flowtable_hash_lo);
  if(return_value != 0) {
   eg_intr_md_for_dprsr.drop_ctl = 0x1;
  }
 }
}
control npb_ing_sf_npb_basic_adv_dedup (
 in switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {
 npb_ing_sf_npb_basic_adv_dedup_reg() npb_ing_sf_npb_basic_adv_dedup_reg_0;
 bit<32> flowtable_hash;
 bit<17> flowtable_hash_lo;
 bit<16> flowtable_hash_hi;
 Hash<bit<17>>(HashAlgorithm_t.CRC32) h_lo;
 Hash<bit<16 >>(HashAlgorithm_t.CRC16) h_hi;
 apply {
  flowtable_hash_lo = h_lo.get({eg_md.lkp.ip_src_addr, eg_md.lkp.ip_dst_addr, eg_md.lkp.ip_proto, eg_md.lkp.l4_src_port, eg_md.lkp.l4_dst_port});
  flowtable_hash_hi = h_hi.get({eg_md.lkp.ip_src_addr, eg_md.lkp.ip_dst_addr, eg_md.lkp.ip_proto, eg_md.lkp.l4_src_port, eg_md.lkp.l4_dst_port});
  npb_ing_sf_npb_basic_adv_dedup_reg_0.apply (
   hdr,
   eg_md,
   eg_intr_md,
   eg_intr_md_from_prsr,
   eg_intr_md_for_dprsr,
   eg_intr_md_for_oport,
   flowtable_hash_lo,
   flowtable_hash_hi
  );
 }
}
control npb_egr_sf_proxy_top_part2 (
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {
 apply {
  if(eg_md.action_bitmask[3:3] == 1) {
  }
  if(eg_md.action_bitmask[4:4] == 1) {
  }
  hdr.nsh_extr_underlay.si = hdr.nsh_extr_underlay.si - 1;
 }
}
control npb_egr_sff_top_part1 (
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {
    action new_ttl(bit<6> ttl) {
        hdr.nsh_extr_underlay.ttl = ttl;
    }
    action discard() {
        eg_intr_md_for_dprsr.drop_ctl = 1;
    }
    table npb_egr_sff_dec_ttl {
        key = { hdr.nsh_extr_underlay.ttl : exact; }
        actions = { new_ttl; discard; }
        const entries = {
            0 : new_ttl(63);
            1 : new_ttl(0);
            2 : new_ttl(1);
            3 : new_ttl(2);
            4 : new_ttl(3);
            5 : new_ttl(4);
            6 : new_ttl(5);
            7 : new_ttl(6);
            8 : new_ttl(7);
            9 : new_ttl(8);
            10 : new_ttl(9);
            11 : new_ttl(10);
            12 : new_ttl(11);
            13 : new_ttl(12);
            14 : new_ttl(13);
            15 : new_ttl(14);
            16 : new_ttl(15);
            17 : new_ttl(16);
            18 : new_ttl(17);
            19 : new_ttl(18);
            20 : new_ttl(19);
            21 : new_ttl(20);
            22 : new_ttl(21);
            23 : new_ttl(22);
            24 : new_ttl(23);
            25 : new_ttl(24);
            26 : new_ttl(25);
            27 : new_ttl(26);
            28 : new_ttl(27);
            29 : new_ttl(28);
            30 : new_ttl(29);
            31 : new_ttl(30);
            32 : new_ttl(31);
            33 : new_ttl(32);
            34 : new_ttl(33);
            35 : new_ttl(34);
            36 : new_ttl(35);
            37 : new_ttl(36);
            38 : new_ttl(37);
            39 : new_ttl(38);
            40 : new_ttl(39);
            41 : new_ttl(40);
            42 : new_ttl(41);
            43 : new_ttl(42);
            44 : new_ttl(43);
            45 : new_ttl(44);
            46 : new_ttl(45);
            47 : new_ttl(46);
            48 : new_ttl(47);
            49 : new_ttl(48);
            50 : new_ttl(49);
            51 : new_ttl(50);
            52 : new_ttl(51);
            53 : new_ttl(52);
            54 : new_ttl(53);
            55 : new_ttl(54);
            56 : new_ttl(55);
            57 : new_ttl(56);
            58 : new_ttl(57);
            59 : new_ttl(58);
            60 : new_ttl(59);
            61 : new_ttl(60);
            62 : new_ttl(61);
            63 : new_ttl(62);
        }
    }
 apply {
  if(eg_md.nsh_extr.terminate == true) {
   hdr.nsh_extr_underlay.setInvalid();
  } else {
   hdr.nsh_extr_underlay.spi = eg_md.nsh_extr.spi;
   hdr.nsh_extr_underlay.si = eg_md.nsh_extr.si;
   hdr.nsh_extr_underlay.extr_sf_bitmask = eg_md.nsh_extr.extr_sf_bitmask_remote;
   hdr.nsh_extr_underlay.extr_tenant_id = eg_md.nsh_extr.extr_tenant_id;
   hdr.nsh_extr_underlay.extr_flow_type = eg_md.nsh_extr.extr_flow_type;
   if(hdr.nsh_extr_underlay.isValid()) {
   } else {
    if(eg_md.nsh_extr.valid == 1) {
      hdr.nsh_extr_underlay.setValid();
    }
    hdr.nsh_extr_underlay.version = 0x0;
    hdr.nsh_extr_underlay.o = 0x0;
    hdr.nsh_extr_underlay.reserved = 0x0;
    hdr.nsh_extr_underlay.ttl = 0x0;
    hdr.nsh_extr_underlay.len = 0x5;
    hdr.nsh_extr_underlay.reserved2 = 0x0;
    hdr.nsh_extr_underlay.md_type = 0x2;
    hdr.nsh_extr_underlay.next_proto = 0x3;
    hdr.nsh_extr_underlay.md_class = 0x0;
    hdr.nsh_extr_underlay.type = 0x0;
    hdr.nsh_extr_underlay.reserved3 = 0x0;
    hdr.nsh_extr_underlay.md_len = 0x8;
    hdr.nsh_extr_underlay.extr_rsvd = 0x0;
   }
  }
   if(eg_md.nsh_extr.extr_sf_bitmask_local[1:1] == 1) {
    hdr.nsh_extr_underlay.si = hdr.nsh_extr_underlay.si - 1;
   }
   if(eg_md.nsh_extr.extr_sf_bitmask_local[2:2] == 1) {
    npb_egr_sf_proxy_top_part1.apply (
     hdr,
     eg_md,
     eg_intr_md,
     eg_intr_md_from_prsr,
     eg_intr_md_for_dprsr,
     eg_intr_md_for_oport
    );
   }
  if(eg_md.nsh_extr.valid == 1) {
  }
 }
}
control npb_egr_sff_top_part2 (
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {
    action new_ttl(bit<6> ttl) {
        hdr.nsh_extr_underlay.ttl = ttl;
    }
    action discard() {
        eg_intr_md_for_dprsr.drop_ctl = 1;
    }
    table npb_egr_sff_dec_ttl {
        key = { hdr.nsh_extr_underlay.ttl : exact; }
        actions = { new_ttl; discard; }
        const entries = {
            0 : new_ttl(63);
            1 : new_ttl(0);
            2 : new_ttl(1);
            3 : new_ttl(2);
            4 : new_ttl(3);
            5 : new_ttl(4);
            6 : new_ttl(5);
            7 : new_ttl(6);
            8 : new_ttl(7);
            9 : new_ttl(8);
            10 : new_ttl(9);
            11 : new_ttl(10);
            12 : new_ttl(11);
            13 : new_ttl(12);
            14 : new_ttl(13);
            15 : new_ttl(14);
            16 : new_ttl(15);
            17 : new_ttl(16);
            18 : new_ttl(17);
            19 : new_ttl(18);
            20 : new_ttl(19);
            21 : new_ttl(20);
            22 : new_ttl(21);
            23 : new_ttl(22);
            24 : new_ttl(23);
            25 : new_ttl(24);
            26 : new_ttl(25);
            27 : new_ttl(26);
            28 : new_ttl(27);
            29 : new_ttl(28);
            30 : new_ttl(29);
            31 : new_ttl(30);
            32 : new_ttl(31);
            33 : new_ttl(32);
            34 : new_ttl(33);
            35 : new_ttl(34);
            36 : new_ttl(35);
            37 : new_ttl(36);
            38 : new_ttl(37);
            39 : new_ttl(38);
            40 : new_ttl(39);
            41 : new_ttl(40);
            42 : new_ttl(41);
            43 : new_ttl(42);
            44 : new_ttl(43);
            45 : new_ttl(44);
            46 : new_ttl(45);
            47 : new_ttl(46);
            48 : new_ttl(47);
            49 : new_ttl(48);
            50 : new_ttl(49);
            51 : new_ttl(50);
            52 : new_ttl(51);
            53 : new_ttl(52);
            54 : new_ttl(53);
            55 : new_ttl(54);
            56 : new_ttl(55);
            57 : new_ttl(56);
            58 : new_ttl(57);
            59 : new_ttl(58);
            60 : new_ttl(59);
            61 : new_ttl(60);
            62 : new_ttl(61);
            63 : new_ttl(62);
        }
    }
 apply {
  if(eg_md.nsh_extr.valid == 1) {
  }
   if(eg_md.nsh_extr.extr_sf_bitmask_local[2:2] == 1) {
    npb_egr_sf_proxy_top_part2.apply (
     hdr,
     eg_md,
     eg_intr_md,
     eg_intr_md_from_prsr,
     eg_intr_md_for_dprsr,
     eg_intr_md_for_oport
    );
   }
  if(eg_md.nsh_extr.valid == 1) {
            npb_egr_sff_dec_ttl.apply();
   if(eg_md.nsh_extr.terminate == false) {
    if((hdr.nsh_extr_underlay.ttl == 0) || (hdr.nsh_extr_underlay.si == 0)) {
     eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }
   }
  }
 }
}
@pa_no_overlay("ingress", "hdr.bridged_md.__pad_3")
control SwitchIngress(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
 switch_ingress_metadata_t ig_md_nsh;
    IngressPortMapping(PORT_VLAN_TABLE_SIZE,
                       BD_TABLE_SIZE,
                       DOUBLE_TAG_TABLE_SIZE) ingress_port_mapping;
    PktValidation() pkt_validation;
    IngressSTP() stp;
    SMAC(MAC_TABLE_SIZE) smac;
    DMAC(MAC_TABLE_SIZE) dmac;
    IngressTunnel(IPV4_SRC_TUNNEL_TABLE_SIZE) tunnel_nsh;
    IngressBd(BD_TABLE_SIZE) bd_stats;
    IngressMulticast(IPV4_MULTICAST_S_G_TABLE_SIZE,
                     IPV4_MULTICAST_STAR_G_TABLE_SIZE,
                     IPV6_MULTICAST_S_G_TABLE_SIZE,
                     IPV6_MULTICAST_STAR_G_TABLE_SIZE) multicast;
    IngressUnicast(dmac,
                   IPV4_HOST_TABLE_SIZE,
                   IPV4_LPM_TABLE_SIZE,
                   IPV6_HOST_TABLE_SIZE,
                   IPV6_LPM_TABLE_SIZE) unicast;
    IngressAcl(INGRESS_IPV4_ACL_TABLE_SIZE,
               INGRESS_IPV6_ACL_TABLE_SIZE,
               INGRESS_MAC_ACL_TABLE_SIZE,
               true ) acl;
    MirrorAcl(stats_enable=true) mirror_acl;
    RouterAcl(IPV4_RACL_TABLE_SIZE, IPV6_RACL_TABLE_SIZE, true) racl;
    IngressDtel() dtel;
    IngressQoS() qos;
    StormControl(STORM_CONTROL_TABLE_SIZE) storm_control;
    Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
    OuterFib(
        NUM_TUNNELS, OUTER_ECMP_GROUP_TABLE_SIZE, OUTER_ECMP_SELECT_TABLE_SIZE) outer_fib;
    LAG() lag;
    MulticastFlooding(BD_FLOOD_TABLE_SIZE) flood;
    IngressSystemAcl() system_acl;
    apply {
        ig_intr_md_for_dprsr.drop_ctl = 0;
        ig_md.multicast.id = 0;
        ig_md.flags.racl_deny = false;
        ig_md.flags.flood_to_multicast_routers = false;
        pkt_validation.apply(hdr, ig_md.flags, ig_md.lkp, ig_md, ig_intr_from_prsr, ig_intr_md_for_dprsr, ig_intr_md_for_tm, ig_md.drop_reason);
        ig_md_nsh = ig_md ;
        ingress_port_mapping.apply(hdr, ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
        tunnel_nsh.apply(hdr, ig_md_nsh, ig_md_nsh.lkp);
        mirror_acl.apply(ig_md.lkp, ig_md);
        npb_ing_sfc_top.apply (
            hdr,
            ig_md_nsh,
            ig_intr_md,
            ig_intr_from_prsr,
            ig_intr_md_for_dprsr,
            ig_intr_md_for_tm
        );
        npb_ing_sff_top.apply (
            hdr,
            ig_md_nsh,
            ig_intr_md,
            ig_intr_from_prsr,
            ig_intr_md_for_dprsr,
            ig_intr_md_for_tm
        );
        ig_md.lkp = ig_md_nsh.lkp;
        ig_md.tunnel.ifindex = ig_md_nsh.tunnel.ifindex;
        ig_md.bd = ig_md_nsh.bd;
        ig_md.bd_label = ig_md_nsh.bd_label;
        ig_md.vrf = ig_md_nsh.vrf;
        ig_md.rmac_group = ig_md_nsh.rmac_group;
        ig_md.multicast.rpf_group = ig_md_nsh.multicast.rpf_group;
        ig_md.learning.bd_mode = ig_md_nsh.learning.bd_mode;
        ig_md.ipv4.unicast_enable = ig_md_nsh.ipv4.unicast_enable;
        ig_md.ipv4.multicast_enable = ig_md_nsh.ipv4.multicast_enable;
        ig_md.ipv4.multicast_snooping = ig_md_nsh.ipv4.multicast_snooping;
        ig_md.ipv6.unicast_enable = ig_md_nsh.ipv6.unicast_enable;
        ig_md.ipv6.multicast_enable = ig_md_nsh.ipv6.multicast_enable;
        ig_md.ipv6.multicast_snooping = ig_md_nsh.ipv6.multicast_snooping;
        ig_md.tunnel.terminate = ig_md_nsh.tunnel.terminate;
if(ig_md.nsh_extr.valid == 1) {
} else {
    ig_intr_md_for_dprsr.drop_ctl = 1;
}
        racl.apply(ig_md.lkp, ig_md);
        if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_NONE)
            compute_non_ip_hash(ig_md.lkp, ig_md.hash);
        else
            compute_ip_hash(ig_md.lkp, ig_md.hash);
        nexthop.apply(ig_md.lkp, ig_md, ig_md.hash[15:0]);
        qos.apply(hdr, ig_md.lkp, ig_md);
        storm_control.apply(ig_md, ig_md.lkp.pkt_type, ig_md.flags.storm_control_drop);
        outer_fib.apply(ig_md, ig_md.hash[31:16]);
        if (ig_md.egress_ifindex == SWITCH_IFINDEX_FLOOD) {
        } else {
            lag.apply(ig_md, ig_md.hash[31:16], ig_intr_md_for_tm.ucast_egress_port);
        }
        dtel.apply(
            hdr, ig_md.lkp, ig_md, ig_md.hash[15:0], ig_intr_md_for_dprsr, ig_intr_md_for_tm);
        if (ig_intr_md_for_tm.bypass_egress == 1w0) {
            add_bridged_md(hdr.bridged_md, ig_md);
        }
        set_ig_intr_md(ig_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);
    }
}
control SwitchEgress(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    EgressPortMapping(PORT_TABLE_SIZE) egress_port_mapping;
    EgressSTP() stp;
    EgressAcl() acl;
    EgressQoS(EGRESS_QOS_MAP_TABLE_SIZE) qos;
    EgressSystemAcl() system_acl;
    Rewrite(NEXTHOP_TABLE_SIZE, BD_TABLE_SIZE) rewrite;
    EgressDtel() dtel;
    MirrorRewrite() mirror_rewrite;
    VlanXlate(VLAN_TABLE_SIZE, PORT_VLAN_TABLE_SIZE) vlan_xlate;
    VlanDecap() vlan_decap;
    TunnelDecap(switch_tunnel_mode_t.PIPE) tunnel_decap;
    TunnelEncap(switch_tunnel_mode_t.PIPE) tunnel_encap;
    TunnelRewrite() tunnel_rewrite;
    MTU() mtu;
    WRED() wred;
    MulticastReplication(RID_TABLE_SIZE) multicast_replication;
    apply {
        eg_intr_md_for_dprsr.drop_ctl = 0;
        eg_md.timestamp = eg_intr_md_from_prsr.global_tstamp[31:0];
        egress_port_mapping.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);
        mirror_rewrite.apply(hdr, eg_md);
        multicast_replication.apply(eg_intr_md.egress_rid, eg_intr_md.egress_port, eg_md);
        npb_egr_sff_top_part1.apply (
            hdr,
            eg_md,
            eg_intr_md,
            eg_intr_md_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );
        stp.apply(eg_md, eg_intr_md.egress_port, eg_md.checks.stp);
        vlan_decap.apply(hdr, eg_md);
        tunnel_decap.apply(hdr, eg_md);
        qos.apply(hdr, eg_intr_md.egress_port, eg_md);
        wred.apply(hdr, eg_md, eg_intr_md, eg_md.flags.wred_drop);
        npb_egr_sff_top_part2.apply (
            hdr,
            eg_md,
            eg_intr_md,
            eg_intr_md_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );
        rewrite.apply(hdr, eg_md);
        tunnel_encap.apply(hdr, eg_md);
        tunnel_rewrite.apply(hdr, eg_md);
        mtu.apply(hdr, eg_md, eg_md.checks.mtu);
        vlan_xlate.apply(hdr, eg_md);
        dtel.apply(hdr, eg_md, eg_intr_md, eg_md.dtel.hash, eg_intr_md_for_dprsr);
        set_eg_intr_md(eg_md, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
    }
}
Pipeline(
        NpbIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
        NpbEgressParser(),
        SwitchEgress(),
        SwitchEgressDeparser()) pipe;
Switch(pipe) main;
