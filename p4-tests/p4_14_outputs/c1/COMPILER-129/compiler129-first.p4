#include <core.p4>
#include <v1model.p4>

struct acl_metadata_t {
    bit<1>  acl_deny;
    bit<1>  acl_copy;
    bit<1>  racl_deny;
    bit<16> acl_nexthop;
    bit<16> racl_nexthop;
    bit<1>  acl_nexthop_type;
    bit<1>  racl_nexthop_type;
    bit<1>  acl_redirect;
    bit<1>  racl_redirect;
    bit<15> if_label;
    bit<16> bd_label;
    bit<10> mirror_session_id;
    bit<32> acl_stats_index;
}

struct egress_metadata_t {
    bit<1>  bypass;
    bit<2>  port_type;
    bit<16> payload_length;
    bit<9>  smac_idx;
    bit<16> bd;
    bit<16> outer_bd;
    bit<48> mac_da;
    bit<1>  routed;
    bit<16> same_bd_check;
    bit<8>  drop_reason;
    bit<32> sflow_take_sample;
}

struct fabric_metadata_t {
    bit<3>  packetType;
    bit<1>  fabric_header_present;
    bit<16> reason_code;
}

struct global_config_metadata_t {
    bit<1> enable_dod;
}

struct hash_metadata_t {
    bit<16> hash1;
    bit<16> hash2;
    bit<16> entropy_hash;
}

struct i2e_metadata_t {
    bit<32> ingress_tstamp;
    bit<16> mirror_session_id;
}

@pa_alias("ingress", "ig_intr_md.ingress_port", "ingress_metadata.ingress_port") struct ingress_metadata_t {
    bit<9>  ingress_port;
    bit<16> ifindex;
    bit<16> egress_ifindex;
    bit<2>  port_type;
    bit<16> outer_bd;
    bit<16> bd;
    bit<1>  drop_flag;
    bit<8>  drop_reason;
    bit<1>  control_frame;
    bit<32> sflow_take_sample;
    bit<3>  sflow_session_id;
}

struct ipv4_metadata_t {
    bit<32> lkp_ipv4_sa;
    bit<32> lkp_ipv4_da;
    bit<1>  ipv4_unicast_enabled;
    bit<2>  ipv4_urpf_mode;
}

struct ipv6_metadata_t {
    bit<128> lkp_ipv6_sa;
    bit<128> lkp_ipv6_da;
    bit<1>   ipv6_unicast_enabled;
    bit<1>   ipv6_src_is_link_local;
    bit<2>   ipv6_urpf_mode;
}

struct l2_metadata_t {
    bit<3>  lkp_pkt_type;
    bit<48> lkp_mac_sa;
    bit<48> lkp_mac_da;
    bit<16> lkp_mac_type;
    bit<16> l2_nexthop;
    bit<1>  l2_nexthop_type;
    bit<1>  l2_redirect;
    bit<1>  l2_src_miss;
    bit<16> l2_src_move;
    bit<10> stp_group;
    bit<3>  stp_state;
    bit<16> bd_stats_idx;
    bit<1>  learning_enabled;
    bit<1>  port_vlan_mapping_miss;
    bit<16> same_if_check;
    bit<2>  mac_lmt_dlf;
    bit<16> mac_lmt_num;
    bit<6>  block_info;
    bit<1>  block_flag;
    bit<1>  RmtLpbk;
    bit<1>  state1588;
    bit<1>  vdcid;
    bit<16> tpid;
    bit<3>  sit;
    bit<1>  router_bridge;
    bit<1>  is_pritag;
    bit<1>  tag1_valid;
    bit<1>  tag2_valid;
    bit<12> vlanid;
    bit<1>  discard_tag_pkt;
    bit<3>  tag_type;
    bit<1>  addtag;
    bit<16> ovlaninfo;
    bit<16> ivlaninfo;
    bit<1>  trunk_en;
    bit<10> trunk_id;
    bit<8>  sb;
    bit<8>  sp;
    bit<1>  netstat_en;
    bit<1>  voice_vlan_en;
    bit<1>  ipca_link_stat_en;
    bit<1>  ipsg_en;
    bit<1>  v6_fp;
    bit<1>  v6_portal;
    bit<1>  dai_en;
    bit<1>  ns_enable;
    bit<1>  state_1588;
    bit<4>  vdc_id;
    bit<1>  vlan_acl_en;
    bit<16> new_ovlan_info;
    bit<16> new_ivlan_info;
    bit<8>  new_tag_num;
    bit<3>  fwd_type;
    bit<2>  tbl_type;
    bit<6>  classid;
    bit<1>  outter_pri_act;
    bit<1>  outter_cfi_act;
    bit<1>  inner_pri_act;
    bit<1>  inner_cfi_act;
    bit<3>  urpf_type;
    bit<12> l3_subindex;
    bit<16> vrfid;
    bit<16> vsi;
    bit<16> svp;
    bit<16> dvp;
    bit<1>  vsi_valid;
    bit<1>  vlanswitch_primode;
    bit<16> vlanswitch_oport;
    bit<1>  vlanlrn_mode;
    bit<1>  vlanlrn_lmt;
    bit<9>  stg_id;
    bit<6>  class_id;
    bit<2>  vlan_mac_lmt_dlf;
    bit<16> vlan_lmt_num;
    bit<1>  bypass_chk;
    bit<32> port_bitmap;
    bit<1>  bmp_status;
    bit<1>  ipv4uc_en;
    bit<1>  ipv4mc_en;
    bit<1>  ipv6uc_en;
    bit<1>  ipv6mc_en;
    bit<1>  mplsuc_en;
    bit<1>  mplsmc_en;
    bit<1>  vlanif_vpn;
    bit<1>  trilluc_en;
    bit<1>  vxlane_en;
    bit<1>  nvgre_en;
    bit<1>  vplssogre_en;
    bit<1>  l3gre_en;
    bit<1>  ivsi_ext;
    bit<16> oport_info;
    bit<16> trunkid;
    bit<16> dvp_index;
    bit<3>  be_opcode;
    bit<1>  oport_is_trunk;
    bit<10> hash_rslt;
    bit<4>  aib_opcode;
    bit<5>  keytype;
    bit<5>  keytype1;
    bit<1>  src_vap_user;
    bit<1>  src_trunk_flag;
    bit<3>  outer_tag_pri;
    bit<1>  outer_tag_cfi;
    bit<3>  inner_tag_pri;
    bit<1>  inner_tag_cfi;
    bit<2>  field_1;
    bit<2>  field_2;
    bit<2>  field_3;
    bit<2>  field_4;
    bit<4>  field_5;
    bit<4>  field_6;
    bit<4>  field_7;
    bit<4>  field_8;
    bit<4>  field_9;
    bit<4>  field_10;
    bit<4>  field_11;
    bit<4>  field_12;
    bit<4>  field_13;
    bit<4>  field_14;
    bit<4>  field_15;
    bit<4>  field_16;
    bit<4>  field_17;
    bit<4>  field_18;
    bit<4>  field_19;
    bit<4>  field_20;
    bit<4>  field_21;
    bit<4>  field_22;
    bit<4>  field_23;
    bit<4>  field_24;
    bit<4>  field_25;
    bit<4>  field_26;
    bit<4>  field_27;
    bit<4>  field_28;
    bit<4>  field_29;
    bit<4>  field_30;
    bit<4>  field_31;
    bit<4>  field_32;
    bit<4>  field_33;
    bit<4>  field_34;
    bit<4>  field_35;
    bit<4>  field_36;
    bit<4>  field_37;
    bit<4>  field_38;
    bit<4>  field_39;
    bit<4>  field_40;
    bit<4>  field_41;
    bit<4>  field_42;
    bit<4>  field_43;
    bit<4>  field_44;
    bit<4>  field_45;
    bit<4>  field_46;
    bit<4>  field_47;
    bit<4>  field_48;
    bit<4>  field_49;
    bit<4>  field_50;
    bit<4>  field_51;
    bit<4>  field_52;
    bit<4>  field_53;
    bit<4>  field_54;
    bit<4>  field_55;
    bit<4>  field_56;
    bit<4>  field_57;
    bit<4>  field_58;
    bit<4>  field_59;
    bit<4>  field_60;
}

struct l3_metadata_t {
    bit<2>  lkp_ip_type;
    bit<4>  lkp_ip_version;
    bit<8>  lkp_ip_proto;
    bit<8>  lkp_ip_tc;
    bit<8>  lkp_ip_ttl;
    bit<16> lkp_l4_sport;
    bit<16> lkp_l4_dport;
    bit<16> lkp_inner_l4_sport;
    bit<16> lkp_inner_l4_dport;
    bit<16> vrf;
    bit<10> rmac_group;
    bit<1>  rmac_hit;
    bit<2>  urpf_mode;
    bit<1>  urpf_hit;
    bit<1>  urpf_check_fail;
    bit<16> urpf_bd_group;
    bit<1>  fib_hit;
    bit<16> fib_nexthop;
    bit<1>  fib_nexthop_type;
    bit<16> same_bd_check;
    bit<16> nexthop_index;
    bit<1>  routed;
    bit<1>  outer_routed;
    bit<8>  mtu_index;
    bit<16> l3_mtu_check;
    bit<4>  tunnel_type;
    bit<1>  bc;
    bit<1>  mc;
    bit<8>  l4_pkt_type;
    bit<1>  ipv4_valid;
    bit<1>  tcp_valid;
    bit<1>  udp_valid;
    bit<13> fragOffSet;
    bit<1>  field_1;
    bit<1>  field_2;
    bit<1>  field_3;
    bit<1>  field_4;
    bit<1>  field_5;
    bit<1>  field_6;
    bit<1>  field_7;
    bit<1>  field_8;
    bit<1>  field_9;
    bit<1>  field_10;
    bit<1>  field_11;
    bit<1>  field_12;
    bit<1>  field_13;
    bit<1>  field_14;
    bit<1>  field_15;
    bit<1>  field_16;
    bit<1>  field_17;
    bit<1>  field_18;
    bit<1>  field_19;
    bit<1>  field_20;
    bit<1>  field_21;
    bit<1>  field_22;
    bit<1>  field_23;
    bit<1>  field_24;
    bit<1>  field_25;
    bit<1>  field_26;
    bit<1>  field_27;
    bit<1>  field_28;
    bit<1>  field_29;
    bit<1>  field_30;
    bit<1>  field_31;
    bit<1>  field_32;
    bit<1>  field_33;
    bit<1>  field_34;
    bit<1>  field_35;
    bit<1>  field_36;
    bit<1>  field_37;
    bit<1>  field_38;
    bit<1>  field_39;
    bit<1>  field_40;
    bit<1>  field_41;
    bit<1>  field_42;
    bit<1>  field_43;
    bit<1>  field_44;
    bit<1>  field_45;
    bit<1>  field_46;
    bit<1>  field_47;
    bit<1>  field_48;
    bit<1>  field_49;
    bit<1>  field_50;
    bit<1>  field_51;
    bit<1>  field_52;
    bit<1>  field_53;
    bit<1>  field_54;
    bit<1>  field_55;
    bit<1>  field_56;
    bit<1>  field_57;
    bit<1>  field_58;
    bit<1>  field_59;
    bit<1>  field_60;
    bit<1>  field_61;
    bit<1>  field_62;
    bit<1>  field_63;
    bit<1>  field_64;
    bit<1>  field_65;
    bit<1>  field_66;
    bit<1>  field_67;
    bit<1>  field_68;
    bit<1>  field_69;
    bit<1>  field_70;
    bit<1>  field_71;
    bit<1>  field_72;
    bit<1>  field_73;
    bit<1>  field_74;
    bit<1>  field_75;
    bit<1>  field_76;
    bit<1>  field_77;
    bit<1>  field_78;
    bit<1>  field_79;
    bit<1>  field_80;
    bit<1>  field_81;
    bit<1>  field_82;
    bit<1>  field_83;
    bit<1>  field_84;
    bit<1>  field_85;
    bit<1>  field_86;
    bit<1>  field_87;
    bit<1>  field_88;
    bit<1>  field_89;
    bit<1>  field_90;
    bit<1>  field_91;
    bit<1>  field_92;
    bit<1>  field_93;
    bit<1>  field_94;
    bit<1>  field_95;
    bit<1>  field_96;
    bit<1>  field_97;
    bit<1>  field_98;
    bit<1>  field_99;
    bit<1>  field_100;
    bit<1>  field_101;
    bit<1>  field_102;
    bit<1>  field_103;
    bit<1>  field_104;
    bit<1>  field_105;
    bit<1>  field_106;
    bit<1>  field_107;
    bit<1>  field_108;
    bit<1>  field_109;
    bit<1>  field_110;
    bit<1>  field_111;
    bit<1>  field_112;
    bit<1>  field_113;
    bit<1>  field_114;
    bit<1>  field_115;
    bit<1>  field_116;
    bit<1>  field_117;
    bit<1>  field_118;
    bit<1>  field_119;
    bit<1>  field_120;
    bit<1>  field_121;
    bit<1>  field_122;
    bit<1>  field_123;
    bit<1>  field_124;
    bit<1>  field_125;
    bit<1>  field_126;
    bit<1>  field_127;
    bit<1>  field_128;
    bit<1>  field_129;
    bit<1>  field_130;
    bit<1>  field_131;
    bit<1>  field_132;
    bit<1>  field_133;
    bit<1>  field_134;
    bit<1>  field_135;
    bit<1>  field_136;
    bit<1>  field_137;
    bit<1>  field_138;
    bit<1>  field_139;
    bit<1>  field_140;
    bit<1>  field_141;
    bit<1>  field_142;
    bit<1>  field_143;
    bit<1>  field_144;
    bit<1>  field_145;
    bit<1>  field_146;
    bit<1>  field_147;
    bit<1>  field_148;
    bit<1>  field_149;
    bit<1>  field_150;
    bit<1>  field_151;
    bit<1>  field_152;
    bit<1>  field_153;
    bit<1>  field_154;
    bit<1>  field_155;
    bit<1>  field_156;
    bit<1>  field_157;
    bit<1>  field_158;
    bit<1>  field_159;
    bit<1>  field_160;
}

struct meter_metadata_t {
    bit<2>  meter_color;
    bit<16> meter_index;
}

struct multicast_metadata_t {
    bit<1>  ipv4_mcast_key_type;
    bit<16> ipv4_mcast_key;
    bit<1>  ipv6_mcast_key_type;
    bit<16> ipv6_mcast_key;
    bit<1>  outer_mcast_route_hit;
    bit<2>  outer_mcast_mode;
    bit<1>  mcast_route_hit;
    bit<1>  mcast_bridge_hit;
    bit<2>  ipv4_multicast_mode;
    bit<2>  ipv6_multicast_mode;
    bit<1>  igmp_snooping_enabled;
    bit<1>  mld_snooping_enabled;
    bit<16> bd_mrpf_group;
    bit<16> mcast_rpf_group;
    bit<2>  mcast_mode;
    bit<16> multicast_route_mc_index;
    bit<16> multicast_bridge_mc_index;
    bit<1>  inner_replica;
    bit<1>  replica;
}

struct nat_metadata_t {
    bit<2>  ingress_nat_mode;
    bit<2>  egress_nat_mode;
    bit<16> nat_nexthop;
    bit<1>  nat_hit;
    bit<16> nat_rewrite_index;
}

struct nexthop_metadata_t {
    bit<1> nexthop_type;
}

struct qos_metadata_t {
    bit<8> outer_dscp;
    bit<3> marked_cos;
    bit<8> marked_dscp;
    bit<3> marked_exp;
}

struct security_metadata_t {
    bit<1> storm_control_color;
    bit<1> ipsg_enabled;
    bit<1> ipsg_check_fail;
}

struct tunnel_metadata_t {
    bit<5>  ingress_tunnel_type;
    bit<24> tunnel_vni;
    bit<1>  mpls_enabled;
    bit<20> mpls_label;
    bit<3>  mpls_exp;
    bit<8>  mpls_ttl;
    bit<5>  egress_tunnel_type;
    bit<14> tunnel_index;
    bit<9>  tunnel_src_index;
    bit<9>  tunnel_smac_index;
    bit<14> tunnel_dst_index;
    bit<14> tunnel_dmac_index;
    bit<24> vnid;
    bit<1>  tunnel_terminate;
    bit<1>  tunnel_if_check;
    bit<4>  egress_header_count;
}

header arp_rarp_t {
    bit<16> hwType;
    bit<16> protoType;
    bit<8>  hwAddrLen;
    bit<8>  protoAddrLen;
    bit<16> opcode;
}

header arp_rarp_ipv4_t {
    bit<48> srcHwAddr;
    bit<32> srcProtoAddr;
    bit<48> dstHwAddr;
    bit<32> dstProtoAddr;
}

header bfd_t {
    bit<3>  version;
    bit<5>  diag;
    bit<2>  state;
    bit<1>  p;
    bit<1>  f;
    bit<1>  c;
    bit<1>  a;
    bit<1>  d;
    bit<1>  m;
    bit<8>  detectMult;
    bit<8>  len;
    bit<32> myDiscriminator;
    bit<32> yourDiscriminator;
    bit<32> desiredMinTxInterval;
    bit<32> requiredMinRxInterval;
    bit<32> requiredMinEchoRxInterval;
}

header coal_pkt_hdr_t {
    bit<16> session_id;
}

header coal_sample_hdr_t {
    bit<32> id;
}

header egress_intrinsic_metadata_t {
    bit<7>  _pad0;
    bit<9>  egress_port;
    bit<5>  _pad1;
    bit<19> enq_qdepth;
    bit<6>  _pad2;
    bit<2>  enq_congest_stat;
    bit<32> enq_tstamp;
    bit<5>  _pad3;
    bit<19> deq_qdepth;
    bit<6>  _pad4;
    bit<2>  deq_congest_stat;
    bit<8>  app_pool_congest_stat;
    bit<32> deq_timedelta;
    bit<16> egress_rid;
    bit<7>  _pad5;
    bit<1>  egress_rid_first;
    bit<3>  _pad6;
    bit<5>  egress_qid;
    bit<5>  _pad7;
    bit<3>  egress_cos;
    bit<7>  _pad8;
    bit<1>  deflection_flag;
    bit<16> pkt_length;
}

header egress_intrinsic_metadata_for_mirror_buffer_t {
    bit<6>  _pad1;
    bit<10> egress_mirror_id;
    bit<1>  coalesce_flush;
    bit<7>  coalesce_length;
}

header egress_intrinsic_metadata_for_output_port_t {
    bit<2> _pad1;
    bit<1> capture_tstamp_on_tx;
    bit<1> update_delay_on_tx;
    bit<1> force_tx_error;
    bit<3> drop_ctl;
}

header egress_intrinsic_metadata_from_parser_aux_t {
    bit<48> egress_global_tstamp;
    bit<32> egress_global_ver;
    bit<16> egress_parser_err;
    bit<4>  clone_digest_id;
    bit<4>  clone_src;
    bit<8>  coalesce_sample_count;
}

header eompls_t {
    bit<4>  zero;
    bit<12> reserved;
    bit<16> seqNo;
}

@name("erspan_header_t3_t") header erspan_header_t3_t_0 {
    bit<4>  version;
    bit<12> vlan;
    bit<6>  priority;
    bit<10> span_id;
    bit<32> timestamp;
    bit<32> sgt_other;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header fabric_header_t {
    bit<3>  packetType;
    bit<2>  headerVersion;
    bit<2>  packetVersion;
    bit<1>  pad1;
    bit<3>  fabricColor;
    bit<5>  fabricQos;
    bit<8>  dstDevice;
    bit<16> dstPortOrGroup;
}

header fabric_header_cpu_t {
    bit<5>  egressQueue;
    bit<1>  txBypass;
    bit<2>  reserved;
    bit<16> ingressPort;
    bit<16> ingressIfindex;
    bit<16> ingressBd;
    bit<16> reasonCode;
}

header fabric_header_mirror_t {
    bit<16> rewriteIndex;
    bit<10> egressPort;
    bit<5>  egressQueue;
    bit<1>  pad;
}

header fabric_header_multicast_t {
    bit<1>  routed;
    bit<1>  outerRouted;
    bit<1>  tunnelTerminate;
    bit<5>  ingressTunnelType;
    bit<16> ingressIfindex;
    bit<16> ingressBd;
    bit<16> mcastGrpA;
    bit<16> mcastGrpB;
    bit<16> ingressRid;
    bit<16> l1ExclusionId;
}

header fabric_header_unicast_t {
    bit<1>  routed;
    bit<1>  outerRouted;
    bit<1>  tunnelTerminate;
    bit<5>  ingressTunnelType;
    bit<16> nexthopIndex;
}

header fabric_payload_header_t {
    bit<16> etherType;
}

header fcoe_header_t {
    bit<4>  version;
    bit<4>  type_;
    bit<8>  sof;
    bit<32> rsvd1;
    bit<32> ts_upper;
    bit<32> ts_lower;
    bit<32> size_;
    bit<8>  eof;
    bit<24> rsvd2;
}

header genv_t {
    bit<2>  ver;
    bit<6>  optLen;
    bit<1>  oam;
    bit<1>  critical;
    bit<6>  reserved;
    bit<16> protoType;
    bit<24> vni;
    bit<8>  reserved2;
}

header gre_t {
    bit<1>  C;
    bit<1>  R;
    bit<1>  K;
    bit<1>  S;
    bit<1>  s;
    bit<3>  recurse;
    bit<5>  flags;
    bit<3>  ver;
    bit<16> proto;
}

header icmp_t {
    bit<16> typeCode;
    bit<16> hdrChecksum;
}

header ingress_intrinsic_metadata_t {
    bit<1>  resubmit_flag;
    bit<1>  _pad1;
    bit<2>  _pad2;
    bit<3>  _pad3;
    bit<9>  ingress_port;
    bit<48> ingress_mac_tstamp;
}

header ingress_intrinsic_metadata_for_mirror_buffer_t {
    bit<6>  _pad1;
    bit<10> ingress_mirror_id;
}

header ingress_intrinsic_metadata_for_tm_t {
    bit<7>  _pad1;
    bit<9>  ucast_egress_port;
    bit<3>  drop_ctl;
    bit<1>  bypass_egress;
    bit<1>  deflect_on_drop;
    bit<3>  ingress_cos;
    bit<5>  qid;
    bit<3>  icos_for_copy_to_cpu;
    bit<3>  _pad2;
    bit<1>  copy_to_cpu;
    bit<2>  packet_color;
    bit<1>  disable_ucast_cutthru;
    bit<1>  enable_mcast_cutthru;
    bit<16> mcast_grp_a;
    bit<16> mcast_grp_b;
    bit<3>  _pad3;
    bit<13> level1_mcast_hash;
    bit<3>  _pad4;
    bit<13> level2_mcast_hash;
    bit<16> level1_exclusion_id;
    bit<7>  _pad5;
    bit<9>  level2_exclusion_id;
    bit<16> rid;
}

header ingress_intrinsic_metadata_from_parser_aux_t {
    bit<48> ingress_global_tstamp;
    bit<32> ingress_global_ver;
    bit<16> ingress_parser_err;
}

@name("generator_metadata_t") header generator_metadata_t_0 {
    bit<16> app_id;
    bit<16> batch_id;
    bit<16> instance_id;
}

header ingress_parser_control_signals {
    bit<3> priority;
    bit<5> _pad;
    bit<8> parser_counter;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header ipv6_t {
    bit<4>   version;
    bit<8>   trafficClass;
    bit<20>  flowLabel;
    bit<16>  payloadLen;
    bit<8>   nextHdr;
    bit<8>   hopLimit;
    bit<128> srcAddr;
    bit<128> dstAddr;
}

header sctp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> verifTag;
    bit<32> checksum;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length_;
    bit<16> checksum;
}

header lisp_t {
    bit<8>  flags;
    bit<24> nonce;
    bit<32> lsbsInstanceId;
}

header llc_header_t {
    bit<8> dsap;
    bit<8> ssap;
    bit<8> control_;
}

header nsh_t {
    bit<1>  oam;
    bit<1>  context;
    bit<6>  flags;
    bit<8>  reserved;
    bit<16> protoType;
    bit<24> spath;
    bit<8>  sindex;
}

header nsh_context_t {
    bit<32> network_platform;
    bit<32> network_shared;
    bit<32> service_platform;
    bit<32> service_shared;
}

header nvgre_t {
    bit<24> tni;
    bit<8>  flow_id;
}

header roce_header_t {
    bit<320> ib_grh;
    bit<96>  ib_bth;
}

header roce_v2_header_t {
    bit<96> ib_bth;
}

header sflow_hdr_t {
    bit<32> version;
    bit<32> addrType;
    bit<32> ipAddress;
    bit<32> subAgentId;
    bit<32> seqNumber;
    bit<32> uptime;
    bit<32> numSamples;
}

header sflow_raw_hdr_record_t {
    bit<20> enterprise;
    bit<12> format;
    bit<16> flowDataLength_hi;
    bit<16> flowDataLength;
    bit<32> headerProtocol;
    bit<16> frameLength_hi;
    bit<16> frameLength;
    bit<16> bytesRemoved_hi;
    bit<16> bytesRemoved;
    bit<16> headerSize_hi;
    bit<16> headerSize;
}

header sflow_sample_t {
    bit<20> enterprise;
    bit<12> format;
    bit<32> sampleLength;
    bit<32> seqNumer;
    bit<8>  srcIdType;
    bit<24> srcIdIndex;
    bit<32> samplingRate;
    bit<32> samplePool;
    bit<32> numDrops;
    bit<32> inputIfindex;
    bit<32> outputIfindex;
    bit<32> numFlowRecords;
}

header sflow_sample_cpu_t {
    bit<16> sampleLength;
    bit<32> samplePool;
    bit<16> inputIfindex;
    bit<16> outputIfindex;
    bit<8>  numFlowRecords;
    bit<3>  sflow_session_id;
    bit<2>  pipe_id;
    bit<3>  _pad;
}

header snap_header_t {
    bit<24> oui;
    bit<16> type_;
}

header trill_t {
    bit<2>  version;
    bit<2>  reserved;
    bit<1>  multiDestination;
    bit<5>  optLength;
    bit<6>  hopCount;
    bit<16> egressRbridge;
    bit<16> ingressRbridge;
}

header vntag_t {
    bit<1>  direction;
    bit<1>  pointer;
    bit<14> destVif;
    bit<1>  looped;
    bit<1>  reserved;
    bit<2>  version;
    bit<12> srcVif;
}

header vxlan_t {
    bit<8>  flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8>  reserved2;
}

header mpls_t {
    bit<20> label;
    bit<3>  exp;
    bit<1>  bos;
    bit<8>  ttl;
}

header vlan_tag_t {
    bit<3>  pcp;
    bit<1>  cfi;
    bit<12> vid;
    bit<16> etherType;
}

struct metadata {
    @pa_solitary("ingress", "acl_metadata.if_label") @pa_atomic("ingress", "acl_metadata.if_label") @name(".acl_metadata") 
    acl_metadata_t           acl_metadata;
    @name(".egress_metadata") 
    egress_metadata_t        egress_metadata;
    @name(".fabric_metadata") 
    fabric_metadata_t        fabric_metadata;
    @name(".global_config_metadata") 
    global_config_metadata_t global_config_metadata;
    @pa_atomic("ingress", "hash_metadata.hash1") @pa_solitary("ingress", "hash_metadata.hash1") @pa_atomic("ingress", "hash_metadata.hash2") @pa_solitary("ingress", "hash_metadata.hash2") @name(".hash_metadata") 
    hash_metadata_t          hash_metadata;
    @name(".i2e_metadata") 
    i2e_metadata_t           i2e_metadata;
    @pa_atomic("ingress", "ingress_metadata.sflow_take_sample") @pa_solitary("ingress", "ingress_metadata.sflow_take_sample") @name(".ingress_metadata") 
    ingress_metadata_t       ingress_metadata;
    @name(".ipv4_metadata") 
    ipv4_metadata_t          ipv4_metadata;
    @pa_alias("ingress", "ipv4_metadata.lkp_ipv4_sa", "ipv6_metadata.lkp_ipv6_sa") @pa_alias("ingress", "ipv4_metadata.lkp_ipv4_da", "ipv6_metadata.lkp_ipv6_da") @name(".ipv6_metadata") 
    ipv6_metadata_t          ipv6_metadata;
    @name(".l2_metadata") 
    l2_metadata_t            l2_metadata;
    @name(".l3_metadata") 
    l3_metadata_t            l3_metadata;
    @name(".meter_metadata") 
    meter_metadata_t         meter_metadata;
    @name(".multicast_metadata") 
    multicast_metadata_t     multicast_metadata;
    @name(".nat_metadata") 
    nat_metadata_t           nat_metadata;
    @name(".nexthop_metadata") 
    nexthop_metadata_t       nexthop_metadata;
    @name(".qos_metadata") 
    qos_metadata_t           qos_metadata;
    @name(".security_metadata") 
    security_metadata_t      security_metadata;
    @name(".tunnel_metadata") 
    tunnel_metadata_t        tunnel_metadata;
}

struct headers {
    @name(".arp_rarp") 
    arp_rarp_t                                     arp_rarp;
    @name(".arp_rarp_ipv4") 
    arp_rarp_ipv4_t                                arp_rarp_ipv4;
    @name(".bfd") 
    bfd_t                                          bfd;
    @name(".coal_pkt_hdr") 
    coal_pkt_hdr_t                                 coal_pkt_hdr;
    @name(".coal_sample_hdr") 
    coal_sample_hdr_t                              coal_sample_hdr;
    @dont_trim @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md") @pa_atomic("egress", "eg_intr_md.egress_port") @pa_fragment("egress", "eg_intr_md._pad1") @pa_fragment("egress", "eg_intr_md._pad7") @pa_fragment("egress", "eg_intr_md._pad8") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_port") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_cos") @name(".eg_intr_md") 
    egress_intrinsic_metadata_t                    eg_intr_md;
    @dont_trim @pa_intrinsic_header("egress", "eg_intr_md_for_mb") @pa_atomic("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_fragment("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_length") @not_deparsed("ingress") @not_deparsed("egress") @name(".eg_intr_md_for_mb") 
    egress_intrinsic_metadata_for_mirror_buffer_t  eg_intr_md_for_mb;
    @dont_trim @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_oport.drop_ctl") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_for_oport") @name(".eg_intr_md_for_oport") 
    egress_intrinsic_metadata_for_output_port_t    eg_intr_md_for_oport;
    @pa_fragment("egress", "eg_intr_md_from_parser_aux.coalesce_sample_count") @pa_fragment("egress", "eg_intr_md_from_parser_aux.clone_src") @pa_fragment("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @pa_atomic("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_from_parser_aux") @name(".eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t    eg_intr_md_from_parser_aux;
    @name(".eompls") 
    eompls_t                                       eompls;
    @name(".erspan_t3_header") 
    erspan_header_t3_t_0                           erspan_t3_header;
    @name(".ethernet") 
    ethernet_t                                     ethernet;
    @name(".fabric_header") 
    fabric_header_t                                fabric_header;
    @name(".fabric_header_cpu") 
    fabric_header_cpu_t                            fabric_header_cpu;
    @name(".fabric_header_mirror") 
    fabric_header_mirror_t                         fabric_header_mirror;
    @name(".fabric_header_multicast") 
    fabric_header_multicast_t                      fabric_header_multicast;
    @name(".fabric_header_unicast") 
    fabric_header_unicast_t                        fabric_header_unicast;
    @name(".fabric_payload_header") 
    fabric_payload_header_t                        fabric_payload_header;
    @name(".fcoe") 
    fcoe_header_t                                  fcoe;
    @name(".genv") 
    genv_t                                         genv;
    @name(".gre") 
    gre_t                                          gre;
    @name(".icmp") 
    icmp_t                                         icmp;
    @dont_trim @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_intr_md") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md.ingress_port") @name(".ig_intr_md") 
    ingress_intrinsic_metadata_t                   ig_intr_md;
    @dont_trim @pa_intrinsic_header("ingress", "ig_intr_md_for_mb") @pa_atomic("ingress", "ig_intr_md_for_mb.ingress_mirror_id") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_mb.ingress_mirror_id") @not_deparsed("ingress") @not_deparsed("egress") @name(".ig_intr_md_for_mb") 
    ingress_intrinsic_metadata_for_mirror_buffer_t ig_intr_md_for_mb;
    @pa_atomic("ingress", "ig_intr_md_for_tm.ucast_egress_port") @pa_fragment("ingress", "ig_intr_md_for_tm.drop_ctl") @pa_fragment("ingress", "ig_intr_md_for_tm.qid") @pa_fragment("ingress", "ig_intr_md_for_tm._pad2") @pa_atomic("ingress", "ig_intr_md_for_tm.mcast_grp_a") @pa_fragment("ingress", "ig_intr_md_for_tm.mcast_grp_a") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_tm.mcast_grp_a") @pa_atomic("ingress", "ig_intr_md_for_tm.mcast_grp_b") @pa_fragment("ingress", "ig_intr_md_for_tm.mcast_grp_b") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_tm.mcast_grp_b") @pa_atomic("ingress", "ig_intr_md_for_tm.level1_mcast_hash") @pa_fragment("ingress", "ig_intr_md_for_tm._pad3") @pa_atomic("ingress", "ig_intr_md_for_tm.level2_mcast_hash") @pa_fragment("ingress", "ig_intr_md_for_tm._pad4") @pa_atomic("ingress", "ig_intr_md_for_tm.level1_exclusion_id") @pa_fragment("ingress", "ig_intr_md_for_tm.level1_exclusion_id") @pa_atomic("ingress", "ig_intr_md_for_tm.level2_exclusion_id") @pa_fragment("ingress", "ig_intr_md_for_tm._pad5") @pa_atomic("ingress", "ig_intr_md_for_tm.rid") @pa_fragment("ingress", "ig_intr_md_for_tm.rid") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_intr_md_for_tm") @dont_trim @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_tm.drop_ctl") @name(".ig_intr_md_for_tm") 
    ingress_intrinsic_metadata_for_tm_t            ig_intr_md_for_tm;
    @pa_fragment("ingress", "ig_intr_md_from_parser_aux.ingress_parser_err") @pa_atomic("ingress", "ig_intr_md_from_parser_aux.ingress_parser_err") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_intr_md_from_parser_aux") @name(".ig_intr_md_from_parser_aux") 
    ingress_intrinsic_metadata_from_parser_aux_t   ig_intr_md_from_parser_aux;
    @not_deparsed("ingress") @not_deparsed("egress") @name(".ig_pg_md") 
    generator_metadata_t_0                         ig_pg_md;
    @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_prsr_ctrl") @name(".ig_prsr_ctrl") 
    ingress_parser_control_signals                 ig_prsr_ctrl;
    @name(".inner_ethernet") 
    ethernet_t                                     inner_ethernet;
    @name(".inner_icmp") 
    icmp_t                                         inner_icmp;
    @name(".inner_ipv4") 
    ipv4_t                                         inner_ipv4;
    @name(".inner_ipv6") 
    ipv6_t                                         inner_ipv6;
    @name(".inner_sctp") 
    sctp_t                                         inner_sctp;
    @pa_alias("egress", "inner_tcp", "tcp") @name(".inner_tcp") 
    tcp_t                                          inner_tcp;
    @name(".inner_udp") 
    udp_t                                          inner_udp;
    @name(".ipv4") 
    ipv4_t                                         ipv4;
    @overlay_subheader("egress", "inner_ipv6", "srcAddr", "dstAddr") @name(".ipv6") 
    ipv6_t                                         ipv6;
    @name(".lisp") 
    lisp_t                                         lisp;
    @name(".llc_header") 
    llc_header_t                                   llc_header;
    @name(".nsh") 
    nsh_t                                          nsh;
    @name(".nsh_context") 
    nsh_context_t                                  nsh_context;
    @name(".nvgre") 
    nvgre_t                                        nvgre;
    @name(".outer_udp") 
    udp_t                                          outer_udp;
    @name(".roce") 
    roce_header_t                                  roce;
    @name(".roce_v2") 
    roce_v2_header_t                               roce_v2;
    @name(".sctp") 
    sctp_t                                         sctp;
    @name(".sflow") 
    sflow_hdr_t                                    sflow;
    @name(".sflow_raw_hdr_record") 
    sflow_raw_hdr_record_t                         sflow_raw_hdr_record;
    @name(".sflow_sample") 
    sflow_sample_t                                 sflow_sample;
    @name(".sflow_sample_cpu") 
    sflow_sample_cpu_t                             sflow_sample_cpu;
    @name(".snap_header") 
    snap_header_t                                  snap_header;
    @name(".tcp") 
    tcp_t                                          tcp;
    @name(".trill") 
    trill_t                                        trill;
    @name(".udp") 
    udp_t                                          udp;
    @name(".vntag") 
    vntag_t                                        vntag;
    @name(".vxlan") 
    vxlan_t                                        vxlan;
    @name(".mpls") 
    mpls_t[3]                                      mpls;
    @name(".vlan_tag_") 
    vlan_tag_t[2]                                  vlan_tag_;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_arp_rarp") state parse_arp_rarp {
        packet.extract<arp_rarp_t>(hdr.arp_rarp);
        transition select(hdr.arp_rarp.protoType) {
            16w0x800: parse_arp_rarp_ipv4;
            default: accept;
        }
    }
    @name(".parse_arp_rarp_ipv4") state parse_arp_rarp_ipv4 {
        packet.extract<arp_rarp_ipv4_t>(hdr.arp_rarp_ipv4);
        transition parse_set_prio_med;
    }
    @name(".parse_bfd") state parse_bfd {
        packet.extract<bfd_t>(hdr.bfd);
        transition parse_set_prio_max;
    }
    @name(".parse_eompls") state parse_eompls {
        meta.tunnel_metadata.ingress_tunnel_type = 5w6;
        transition parse_inner_ethernet;
    }
    @name(".parse_erspan_t3") state parse_erspan_t3 {
        packet.extract<erspan_header_t3_t_0>(hdr.erspan_t3_header);
        transition parse_inner_ethernet;
    }
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        transition select(hdr.ethernet.etherType) {
            16w0 &&& 16w0xfe00: parse_llc_header;
            16w0 &&& 16w0xfa00: parse_llc_header;
            16w0x9000: parse_fabric_header;
            16w0x8100: parse_vlan;
            16w0x9100: parse_qinq;
            16w0x8847: parse_mpls;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            16w0x806: parse_arp_rarp;
            16w0x88cc: parse_set_prio_high;
            16w0x8809: parse_set_prio_high;
            16w0x9001: parse_sflow_cpu_header;
            default: accept;
        }
    }
    @name(".parse_fabric_header") state parse_fabric_header {
        packet.extract<fabric_header_t>(hdr.fabric_header);
        transition select(hdr.fabric_header.packetType) {
            3w5: parse_fabric_header_cpu;
            default: accept;
        }
    }
    @name(".parse_fabric_header_cpu") state parse_fabric_header_cpu {
        packet.extract<fabric_header_cpu_t>(hdr.fabric_header_cpu);
        transition parse_fabric_payload_header;
    }
    @name(".parse_fabric_header_mirror") state parse_fabric_header_mirror {
        packet.extract<fabric_header_mirror_t>(hdr.fabric_header_mirror);
        transition parse_fabric_payload_header;
    }
    @name(".parse_fabric_header_multicast") state parse_fabric_header_multicast {
        packet.extract<fabric_header_multicast_t>(hdr.fabric_header_multicast);
        transition parse_fabric_payload_header;
    }
    @name(".parse_fabric_header_unicast") state parse_fabric_header_unicast {
        packet.extract<fabric_header_unicast_t>(hdr.fabric_header_unicast);
        transition parse_fabric_payload_header;
    }
    @name(".parse_fabric_payload_header") state parse_fabric_payload_header {
        packet.extract<fabric_payload_header_t>(hdr.fabric_payload_header);
        transition select(hdr.fabric_payload_header.etherType) {
            16w0 &&& 16w0xfe00: parse_llc_header;
            16w0 &&& 16w0xfa00: parse_llc_header;
            16w0x8100: parse_vlan;
            16w0x9100: parse_qinq;
            16w0x8847: parse_mpls;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            16w0x806: parse_arp_rarp;
            16w0x88cc: parse_set_prio_high;
            16w0x8809: parse_set_prio_high;
            16w0x9001: parse_sflow_cpu_header;
            default: accept;
        }
    }
    @name(".parse_fcoe") state parse_fcoe {
        packet.extract<fcoe_header_t>(hdr.fcoe);
        transition accept;
    }
    @name(".parse_geneve") state parse_geneve {
        packet.extract<genv_t>(hdr.genv);
        meta.tunnel_metadata.tunnel_vni = hdr.genv.vni;
        meta.tunnel_metadata.ingress_tunnel_type = 5w4;
        transition select(hdr.genv.ver, hdr.genv.optLen, hdr.genv.protoType) {
            (2w0x0, 6w0x0, 16w0x6558): parse_inner_ethernet;
            (2w0x0, 6w0x0, 16w0x800): parse_inner_ipv4;
            (2w0x0, 6w0x0, 16w0x86dd): parse_inner_ipv6;
            default: accept;
        }
    }
    @name(".parse_gre") state parse_gre {
        packet.extract<gre_t>(hdr.gre);
        transition select(hdr.gre.C, hdr.gre.R, hdr.gre.K, hdr.gre.S, hdr.gre.s, hdr.gre.recurse, hdr.gre.flags, hdr.gre.ver, hdr.gre.proto) {
            (1w0x0, 1w0x0, 1w0x1, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x6558): parse_nvgre;
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x800): parse_gre_ipv4;
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x86dd): parse_gre_ipv6;
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x22eb): parse_erspan_t3;
            default: accept;
        }
    }
    @name(".parse_gre_ipv4") state parse_gre_ipv4 {
        meta.tunnel_metadata.ingress_tunnel_type = 5w2;
        transition parse_inner_ipv4;
    }
    @name(".parse_gre_ipv6") state parse_gre_ipv6 {
        meta.tunnel_metadata.ingress_tunnel_type = 5w2;
        transition parse_inner_ipv6;
    }
    @name(".parse_gre_v6") state parse_gre_v6 {
        packet.extract<gre_t>(hdr.gre);
        transition select(hdr.gre.C, hdr.gre.R, hdr.gre.K, hdr.gre.S, hdr.gre.s, hdr.gre.recurse, hdr.gre.flags, hdr.gre.ver, hdr.gre.proto) {
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x800): parse_gre_ipv4;
            default: accept;
        }
    }
    @name(".parse_icmp") state parse_icmp {
        packet.extract<icmp_t>(hdr.icmp);
        meta.l3_metadata.lkp_l4_sport = hdr.icmp.typeCode;
        transition select(hdr.icmp.typeCode) {
            16w0x8200 &&& 16w0xfe00: parse_set_prio_med;
            16w0x8400 &&& 16w0xfc00: parse_set_prio_med;
            16w0x8800 &&& 16w0xff00: parse_set_prio_med;
            default: accept;
        }
    }
    @name(".parse_inner_ethernet") state parse_inner_ethernet {
        packet.extract<ethernet_t>(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.etherType) {
            16w0x800: parse_inner_ipv4;
            16w0x86dd: parse_inner_ipv6;
            default: accept;
        }
    }
    @name(".parse_inner_icmp") state parse_inner_icmp {
        packet.extract<icmp_t>(hdr.inner_icmp);
        meta.l3_metadata.lkp_inner_l4_sport = hdr.inner_icmp.typeCode;
        transition accept;
    }
    @name(".parse_inner_ipv4") state parse_inner_ipv4 {
        packet.extract<ipv4_t>(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.ihl, hdr.inner_ipv4.protocol) {
            (13w0x0, 4w0x5, 8w0x1): parse_inner_icmp;
            (13w0x0, 4w0x5, 8w0x6): parse_inner_tcp;
            (13w0x0, 4w0x5, 8w0x11): parse_inner_udp;
            default: accept;
        }
    }
    @name(".parse_inner_ipv6") state parse_inner_ipv6 {
        packet.extract<ipv6_t>(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.nextHdr) {
            8w58: parse_inner_icmp;
            8w6: parse_inner_tcp;
            8w17: parse_inner_udp;
            default: accept;
        }
    }
    @name(".parse_inner_sctp") state parse_inner_sctp {
        packet.extract<sctp_t>(hdr.inner_sctp);
        transition accept;
    }
    @name(".parse_inner_tcp") state parse_inner_tcp {
        packet.extract<tcp_t>(hdr.inner_tcp);
        meta.l3_metadata.lkp_inner_l4_sport = hdr.inner_tcp.srcPort;
        meta.l3_metadata.lkp_inner_l4_dport = hdr.inner_tcp.dstPort;
        transition accept;
    }
    @name(".parse_inner_udp") state parse_inner_udp {
        packet.extract<udp_t>(hdr.inner_udp);
        meta.l3_metadata.lkp_inner_l4_sport = hdr.inner_udp.srcPort;
        meta.l3_metadata.lkp_inner_l4_dport = hdr.inner_udp.dstPort;
        transition accept;
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        meta.ipv4_metadata.lkp_ipv4_sa = hdr.ipv4.srcAddr;
        meta.ipv4_metadata.lkp_ipv4_da = hdr.ipv4.dstAddr;
        meta.l3_metadata.lkp_ip_proto = hdr.ipv4.protocol;
        meta.l3_metadata.lkp_ip_ttl = hdr.ipv4.ttl;
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.ihl, hdr.ipv4.protocol) {
            (13w0x0, 4w0x5, 8w0x1): parse_icmp;
            (13w0x0, 4w0x5, 8w0x6): parse_tcp;
            (13w0x0, 4w0x5, 8w0x11): parse_udp;
            (13w0x0, 4w0x5, 8w0x2f): parse_gre;
            (13w0x0, 4w0x5, 8w0x4): parse_ipv4_in_ip;
            (13w0x0, 4w0x5, 8w0x29): parse_ipv6_in_ip;
            (13w0, 4w0, 8w2): parse_set_prio_med;
            (13w0, 4w0, 8w88): parse_set_prio_med;
            (13w0, 4w0, 8w89): parse_set_prio_med;
            (13w0, 4w0, 8w103): parse_set_prio_med;
            (13w0, 4w0, 8w112): parse_set_prio_med;
            default: accept;
        }
    }
    @name(".parse_ipv4_in_ip") state parse_ipv4_in_ip {
        meta.tunnel_metadata.ingress_tunnel_type = 5w3;
        transition parse_inner_ipv4;
    }
    @name(".parse_ipv6") state parse_ipv6 {
        packet.extract<ipv6_t>(hdr.ipv6);
        meta.ipv6_metadata.lkp_ipv6_sa = hdr.ipv6.srcAddr;
        meta.ipv6_metadata.lkp_ipv6_da = hdr.ipv6.dstAddr;
        meta.l3_metadata.lkp_ip_proto = hdr.ipv6.nextHdr;
        meta.l3_metadata.lkp_ip_ttl = hdr.ipv6.hopLimit;
        transition select(hdr.ipv6.nextHdr) {
            8w58: parse_icmp;
            8w6: parse_tcp;
            8w4: parse_ipv4_in_ip;
            8w17: parse_udp;
            8w47: parse_gre;
            8w41: parse_ipv6_in_ip;
            8w88: parse_set_prio_med;
            8w89: parse_set_prio_med;
            8w103: parse_set_prio_med;
            8w112: parse_set_prio_med;
            default: accept;
        }
    }
    @name(".parse_ipv6_in_ip") state parse_ipv6_in_ip {
        meta.tunnel_metadata.ingress_tunnel_type = 5w3;
        transition parse_inner_ipv6;
    }
    @name(".parse_lisp") state parse_lisp {
        packet.extract<lisp_t>(hdr.lisp);
        transition select((packet.lookahead<bit<4>>())[3:0]) {
            4w0x4: parse_inner_ipv4;
            4w0x6: parse_inner_ipv6;
            default: accept;
        }
    }
    @name(".parse_llc_header") state parse_llc_header {
        packet.extract<llc_header_t>(hdr.llc_header);
        transition select(hdr.llc_header.dsap, hdr.llc_header.ssap) {
            (8w0xaa, 8w0xaa): parse_snap_header;
            (8w0xfe, 8w0xfe): parse_set_prio_med;
            default: accept;
        }
    }
    @name(".parse_mpls") state parse_mpls {
        packet.extract<mpls_t>(hdr.mpls.next);
        transition select(hdr.mpls.last.bos) {
            1w0: parse_mpls;
            1w1: parse_mpls_bos;
            default: accept;
        }
    }
    @name(".parse_mpls_bos") state parse_mpls_bos {
        transition select((packet.lookahead<bit<4>>())[3:0]) {
            4w0x4: parse_mpls_inner_ipv4;
            4w0x6: parse_mpls_inner_ipv6;
            default: parse_eompls;
        }
    }
    @name(".parse_mpls_inner_ipv4") state parse_mpls_inner_ipv4 {
        meta.tunnel_metadata.ingress_tunnel_type = 5w9;
        transition parse_inner_ipv4;
    }
    @name(".parse_mpls_inner_ipv6") state parse_mpls_inner_ipv6 {
        meta.tunnel_metadata.ingress_tunnel_type = 5w9;
        transition parse_inner_ipv6;
    }
    @name(".parse_nsh") state parse_nsh {
        packet.extract<nsh_t>(hdr.nsh);
        packet.extract<nsh_context_t>(hdr.nsh_context);
        transition select(hdr.nsh.protoType) {
            16w0x800: parse_inner_ipv4;
            16w0x86dd: parse_inner_ipv6;
            16w0x6558: parse_inner_ethernet;
            default: accept;
        }
    }
    @name(".parse_nvgre") state parse_nvgre {
        packet.extract<nvgre_t>(hdr.nvgre);
        meta.tunnel_metadata.ingress_tunnel_type = 5w5;
        meta.tunnel_metadata.tunnel_vni = hdr.nvgre.tni;
        transition parse_inner_ethernet;
    }
    @name(".parse_pw") state parse_pw {
        transition accept;
    }
    @name(".parse_qinq") state parse_qinq {
        packet.extract<vlan_tag_t>(hdr.vlan_tag_[0]);
        transition select(hdr.vlan_tag_[0].etherType) {
            16w0x8100: parse_qinq_vlan;
            default: accept;
        }
    }
    @name(".parse_qinq_vlan") state parse_qinq_vlan {
        packet.extract<vlan_tag_t>(hdr.vlan_tag_[1]);
        transition select(hdr.vlan_tag_[1].etherType) {
            16w0x8847: parse_mpls;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            16w0x806: parse_arp_rarp;
            16w0x88cc: parse_set_prio_high;
            16w0x8809: parse_set_prio_high;
            default: accept;
        }
    }
    @name(".parse_roce") state parse_roce {
        packet.extract<roce_header_t>(hdr.roce);
        transition accept;
    }
    @name(".parse_roce_v2") state parse_roce_v2 {
        packet.extract<roce_v2_header_t>(hdr.roce_v2);
        transition accept;
    }
    @name(".parse_sctp") state parse_sctp {
        packet.extract<sctp_t>(hdr.sctp);
        transition accept;
    }
    @name(".parse_set_prio_high") state parse_set_prio_high {
        hdr.ig_prsr_ctrl.priority = 3w5;
        transition accept;
    }
    @name(".parse_set_prio_max") state parse_set_prio_max {
        hdr.ig_prsr_ctrl.priority = 3w7;
        transition accept;
    }
    @name(".parse_set_prio_med") state parse_set_prio_med {
        hdr.ig_prsr_ctrl.priority = 3w3;
        transition accept;
    }
    @name(".parse_sflow") state parse_sflow {
        transition accept;
    }
    @name(".parse_sflow_cpu_header") state parse_sflow_cpu_header {
        transition accept;
    }
    @name(".parse_snap_header") state parse_snap_header {
        packet.extract<snap_header_t>(hdr.snap_header);
        transition select(hdr.snap_header.type_) {
            16w0x8100: parse_vlan;
            16w0x9100: parse_qinq;
            16w0x8847: parse_mpls;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            16w0x806: parse_arp_rarp;
            16w0x88cc: parse_set_prio_high;
            16w0x8809: parse_set_prio_high;
            16w0x9001: parse_sflow_cpu_header;
            default: accept;
        }
    }
    @name(".parse_tcp") state parse_tcp {
        packet.extract<tcp_t>(hdr.tcp);
        meta.l3_metadata.lkp_l4_sport = hdr.tcp.srcPort;
        meta.l3_metadata.lkp_l4_dport = hdr.tcp.dstPort;
        transition select(hdr.tcp.dstPort) {
            16w179: parse_set_prio_med;
            16w639: parse_set_prio_med;
            default: accept;
        }
    }
    @name(".parse_trill") state parse_trill {
        packet.extract<trill_t>(hdr.trill);
        transition parse_inner_ethernet;
    }
    @name(".parse_udp") state parse_udp {
        packet.extract<udp_t>(hdr.udp);
        meta.l3_metadata.lkp_l4_sport = hdr.udp.srcPort;
        meta.l3_metadata.lkp_l4_dport = hdr.udp.dstPort;
        transition select(hdr.udp.dstPort) {
            16w4789: parse_vxlan;
            16w6081: parse_geneve;
            16w67: parse_set_prio_med;
            16w68: parse_set_prio_med;
            16w546: parse_set_prio_med;
            16w547: parse_set_prio_med;
            16w520: parse_set_prio_med;
            16w521: parse_set_prio_med;
            16w1985: parse_set_prio_med;
            16w6343: parse_sflow;
            default: accept;
        }
    }
    @name(".parse_udp_v6") state parse_udp_v6 {
        packet.extract<udp_t>(hdr.udp);
        meta.l3_metadata.lkp_l4_sport = hdr.udp.srcPort;
        meta.l3_metadata.lkp_l4_dport = hdr.udp.dstPort;
        transition select(hdr.udp.dstPort) {
            16w67: parse_set_prio_med;
            16w68: parse_set_prio_med;
            16w546: parse_set_prio_med;
            16w547: parse_set_prio_med;
            16w520: parse_set_prio_med;
            16w521: parse_set_prio_med;
            16w1985: parse_set_prio_med;
            default: accept;
        }
    }
    @name(".parse_vlan") state parse_vlan {
        packet.extract<vlan_tag_t>(hdr.vlan_tag_[0]);
        transition select(hdr.vlan_tag_[0].etherType) {
            16w0x8847: parse_mpls;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            16w0x806: parse_arp_rarp;
            16w0x88cc: parse_set_prio_high;
            16w0x8809: parse_set_prio_high;
            default: accept;
        }
    }
    @name(".parse_vntag") state parse_vntag {
        packet.extract<vntag_t>(hdr.vntag);
        transition parse_inner_ethernet;
    }
    @name(".parse_vpls") state parse_vpls {
        transition accept;
    }
    @name(".parse_vxlan") state parse_vxlan {
        packet.extract<vxlan_t>(hdr.vxlan);
        meta.tunnel_metadata.ingress_tunnel_type = 5w1;
        meta.tunnel_metadata.tunnel_vni = hdr.vxlan.vni;
        transition parse_inner_ethernet;
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

@name(".bd_action_profile") action_profile(32w16384) bd_action_profile;

@name(".ecmp_action_profile") @mode("fair") action_selector(HashAlgorithm.identity, 32w16384, 32w14) ecmp_action_profile;

@name(".lag_action_profile") @mode("fair") action_selector(HashAlgorithm.identity, 32w1024, 32w14) lag_action_profile;

control process_add_sflow_headers(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_replication(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_replica_copy_bridged") action set_replica_copy_bridged() {
        meta.egress_metadata.routed = 1w0;
    }
    @name(".outer_replica_from_rid") action outer_replica_from_rid(bit<16> bd, bit<14> tunnel_index, bit<5> tunnel_type, bit<4> header_count) {
        meta.egress_metadata.bd = bd;
        meta.multicast_metadata.replica = 1w1;
        meta.multicast_metadata.inner_replica = 1w0;
        meta.egress_metadata.routed = meta.l3_metadata.outer_routed;
        meta.egress_metadata.same_bd_check = bd ^ meta.ingress_metadata.outer_bd;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
        meta.tunnel_metadata.egress_tunnel_type = tunnel_type;
        meta.tunnel_metadata.egress_header_count = header_count;
    }
    @name(".inner_replica_from_rid") action inner_replica_from_rid(bit<16> bd, bit<14> tunnel_index, bit<5> tunnel_type, bit<4> header_count) {
        meta.egress_metadata.bd = bd;
        meta.multicast_metadata.replica = 1w1;
        meta.multicast_metadata.inner_replica = 1w1;
        meta.egress_metadata.routed = meta.l3_metadata.routed;
        meta.egress_metadata.same_bd_check = bd ^ meta.ingress_metadata.bd;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
        meta.tunnel_metadata.egress_tunnel_type = tunnel_type;
        meta.tunnel_metadata.egress_header_count = header_count;
    }
    @name(".replica_type") table replica_type {
        actions = {
            nop();
            set_replica_copy_bridged();
            @defaultonly NoAction();
        }
        key = {
            meta.multicast_metadata.replica   : exact @name("multicast_metadata.replica") ;
            meta.egress_metadata.same_bd_check: ternary @name("egress_metadata.same_bd_check") ;
        }
        size = 16;
        default_action = NoAction();
    }
    @name(".rid") table rid {
        actions = {
            nop();
            outer_replica_from_rid();
            inner_replica_from_rid();
            @defaultonly NoAction();
        }
        key = {
            hdr.eg_intr_md.egress_rid: exact @name("eg_intr_md.egress_rid") ;
        }
        size = 32768;
        default_action = NoAction();
    }
    apply {
        if (hdr.eg_intr_md.egress_rid != 16w0) {
            rid.apply();
            replica_type.apply();
        }
    }
}

control process_vlan_decap(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".remove_vlan_single_tagged") action remove_vlan_single_tagged() {
        hdr.ethernet.etherType = hdr.vlan_tag_[0].etherType;
        hdr.vlan_tag_[0].setInvalid();
    }
    @name(".remove_vlan_double_tagged") action remove_vlan_double_tagged() {
        hdr.ethernet.etherType = hdr.vlan_tag_[1].etherType;
        hdr.vlan_tag_[0].setInvalid();
        hdr.vlan_tag_[1].setInvalid();
    }
    @ternary(1) @name(".vlan_decap") table vlan_decap {
        actions = {
            nop();
            remove_vlan_single_tagged();
            remove_vlan_double_tagged();
            @defaultonly NoAction();
        }
        key = {
            hdr.vlan_tag_[0].isValid(): exact @name("vlan_tag_[0].$valid$") ;
            hdr.vlan_tag_[1].isValid(): exact @name("vlan_tag_[1].$valid$") ;
        }
        size = 256;
        default_action = NoAction();
    }
    apply {
        vlan_decap.apply();
    }
}

control process_egress_sflow(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_tunnel_decap(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".decap_inner_udp") action decap_inner_udp() {
        hdr.udp = hdr.inner_udp;
        hdr.inner_udp.setInvalid();
    }
    @name(".decap_inner_tcp") action decap_inner_tcp() {
        hdr.tcp.setValid();
        hdr.inner_tcp.setInvalid();
        hdr.udp.setInvalid();
    }
    @name(".decap_inner_icmp") action decap_inner_icmp() {
        hdr.icmp = hdr.inner_icmp;
        hdr.inner_icmp.setInvalid();
        hdr.udp.setInvalid();
    }
    @name(".decap_inner_unknown") action decap_inner_unknown() {
        hdr.udp.setInvalid();
    }
    @name(".decap_vxlan_inner_ipv4") action decap_vxlan_inner_ipv4() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.vxlan.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv4.setInvalid();
    }
    @name(".decap_vxlan_inner_ipv6") action decap_vxlan_inner_ipv6() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.vxlan.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv6.setInvalid();
    }
    @name(".decap_vxlan_inner_non_ip") action decap_vxlan_inner_non_ip() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.vxlan.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
    }
    @name(".decap_genv_inner_ipv4") action decap_genv_inner_ipv4() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.genv.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv4.setInvalid();
    }
    @name(".decap_genv_inner_ipv6") action decap_genv_inner_ipv6() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.genv.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv6.setInvalid();
    }
    @name(".decap_genv_inner_non_ip") action decap_genv_inner_non_ip() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.genv.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
    }
    @name(".decap_nvgre_inner_ipv4") action decap_nvgre_inner_ipv4() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.nvgre.setInvalid();
        hdr.gre.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv4.setInvalid();
    }
    @name(".decap_nvgre_inner_ipv6") action decap_nvgre_inner_ipv6() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.nvgre.setInvalid();
        hdr.gre.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv6.setInvalid();
    }
    @name(".decap_nvgre_inner_non_ip") action decap_nvgre_inner_non_ip() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.nvgre.setInvalid();
        hdr.gre.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
    }
    @name(".decap_ip_inner_ipv4") action decap_ip_inner_ipv4() {
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.gre.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ipv4.setInvalid();
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".decap_ip_inner_ipv6") action decap_ip_inner_ipv6() {
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.gre.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.inner_ipv6.setInvalid();
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".decap_mpls_inner_ipv4_pop1") action decap_mpls_inner_ipv4_pop1() {
        hdr.mpls[0].setInvalid();
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.inner_ipv4.setInvalid();
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".decap_mpls_inner_ipv6_pop1") action decap_mpls_inner_ipv6_pop1() {
        hdr.mpls[0].setInvalid();
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.inner_ipv6.setInvalid();
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".decap_mpls_inner_ethernet_ipv4_pop1") action decap_mpls_inner_ethernet_ipv4_pop1() {
        hdr.mpls[0].setInvalid();
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv4.setInvalid();
    }
    @name(".decap_mpls_inner_ethernet_ipv6_pop1") action decap_mpls_inner_ethernet_ipv6_pop1() {
        hdr.mpls[0].setInvalid();
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv6.setInvalid();
    }
    @name(".decap_mpls_inner_ethernet_non_ip_pop1") action decap_mpls_inner_ethernet_non_ip_pop1() {
        hdr.mpls[0].setInvalid();
        hdr.ethernet = hdr.inner_ethernet;
        hdr.inner_ethernet.setInvalid();
    }
    @name(".decap_mpls_inner_ipv4_pop2") action decap_mpls_inner_ipv4_pop2() {
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.inner_ipv4.setInvalid();
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".decap_mpls_inner_ipv6_pop2") action decap_mpls_inner_ipv6_pop2() {
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.inner_ipv6.setInvalid();
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".decap_mpls_inner_ethernet_ipv4_pop2") action decap_mpls_inner_ethernet_ipv4_pop2() {
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv4.setInvalid();
    }
    @name(".decap_mpls_inner_ethernet_ipv6_pop2") action decap_mpls_inner_ethernet_ipv6_pop2() {
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv6.setInvalid();
    }
    @name(".decap_mpls_inner_ethernet_non_ip_pop2") action decap_mpls_inner_ethernet_non_ip_pop2() {
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.ethernet = hdr.inner_ethernet;
        hdr.inner_ethernet.setInvalid();
    }
    @name(".decap_mpls_inner_ipv4_pop3") action decap_mpls_inner_ipv4_pop3() {
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.inner_ipv4.setInvalid();
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".decap_mpls_inner_ipv6_pop3") action decap_mpls_inner_ipv6_pop3() {
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.inner_ipv6.setInvalid();
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".decap_mpls_inner_ethernet_ipv4_pop3") action decap_mpls_inner_ethernet_ipv4_pop3() {
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv4.setInvalid();
    }
    @name(".decap_mpls_inner_ethernet_ipv6_pop3") action decap_mpls_inner_ethernet_ipv6_pop3() {
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv6.setInvalid();
    }
    @name(".decap_mpls_inner_ethernet_non_ip_pop3") action decap_mpls_inner_ethernet_non_ip_pop3() {
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.ethernet = hdr.inner_ethernet;
        hdr.inner_ethernet.setInvalid();
    }
    @name(".tunnel_decap_process_inner") table tunnel_decap_process_inner {
        actions = {
            decap_inner_udp();
            decap_inner_tcp();
            decap_inner_icmp();
            decap_inner_unknown();
            @defaultonly NoAction();
        }
        key = {
            hdr.inner_tcp.isValid() : exact @name("inner_tcp.$valid$") ;
            hdr.inner_udp.isValid() : exact @name("inner_udp.$valid$") ;
            hdr.inner_icmp.isValid(): exact @name("inner_icmp.$valid$") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".tunnel_decap_process_outer") table tunnel_decap_process_outer {
        actions = {
            decap_vxlan_inner_ipv4();
            decap_vxlan_inner_ipv6();
            decap_vxlan_inner_non_ip();
            decap_genv_inner_ipv4();
            decap_genv_inner_ipv6();
            decap_genv_inner_non_ip();
            decap_nvgre_inner_ipv4();
            decap_nvgre_inner_ipv6();
            decap_nvgre_inner_non_ip();
            decap_ip_inner_ipv4();
            decap_ip_inner_ipv6();
            decap_mpls_inner_ipv4_pop1();
            decap_mpls_inner_ipv6_pop1();
            decap_mpls_inner_ethernet_ipv4_pop1();
            decap_mpls_inner_ethernet_ipv6_pop1();
            decap_mpls_inner_ethernet_non_ip_pop1();
            decap_mpls_inner_ipv4_pop2();
            decap_mpls_inner_ipv6_pop2();
            decap_mpls_inner_ethernet_ipv4_pop2();
            decap_mpls_inner_ethernet_ipv6_pop2();
            decap_mpls_inner_ethernet_non_ip_pop2();
            decap_mpls_inner_ipv4_pop3();
            decap_mpls_inner_ipv6_pop3();
            decap_mpls_inner_ethernet_ipv4_pop3();
            decap_mpls_inner_ethernet_ipv6_pop3();
            decap_mpls_inner_ethernet_non_ip_pop3();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("tunnel_metadata.ingress_tunnel_type") ;
            hdr.inner_ipv4.isValid()                : exact @name("inner_ipv4.$valid$") ;
            hdr.inner_ipv6.isValid()                : exact @name("inner_ipv6.$valid$") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.tunnel_metadata.tunnel_terminate == 1w1) 
            if (meta.multicast_metadata.inner_replica == 1w1 || meta.multicast_metadata.replica == 1w0) {
                tunnel_decap_process_outer.apply();
                tunnel_decap_process_inner.apply();
            }
    }
}

control process_egress_nat(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_rewrite(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_l2_rewrite") action set_l2_rewrite() {
        meta.egress_metadata.routed = 1w0;
        meta.egress_metadata.bd = meta.ingress_metadata.bd;
        meta.egress_metadata.outer_bd = meta.ingress_metadata.bd;
    }
    @name(".set_l2_rewrite_with_tunnel") action set_l2_rewrite_with_tunnel(bit<14> tunnel_index, bit<5> tunnel_type) {
        meta.egress_metadata.routed = 1w0;
        meta.egress_metadata.bd = meta.ingress_metadata.bd;
        meta.egress_metadata.outer_bd = meta.ingress_metadata.bd;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
        meta.tunnel_metadata.egress_tunnel_type = tunnel_type;
    }
    @name(".set_l3_rewrite") action set_l3_rewrite(bit<16> bd, bit<8> mtu_index, bit<48> dmac) {
        meta.egress_metadata.routed = 1w1;
        meta.egress_metadata.mac_da = dmac;
        meta.egress_metadata.bd = bd;
        meta.egress_metadata.outer_bd = bd;
        meta.l3_metadata.mtu_index = mtu_index;
    }
    @name(".set_l3_rewrite_with_tunnel") action set_l3_rewrite_with_tunnel(bit<16> bd, bit<48> dmac, bit<14> tunnel_index, bit<5> tunnel_type) {
        meta.egress_metadata.routed = 1w1;
        meta.egress_metadata.mac_da = dmac;
        meta.egress_metadata.bd = bd;
        meta.egress_metadata.outer_bd = bd;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
        meta.tunnel_metadata.egress_tunnel_type = tunnel_type;
    }
    @name(".set_mpls_swap_push_rewrite_l2") action set_mpls_swap_push_rewrite_l2(bit<20> label, bit<14> tunnel_index, bit<4> header_count) {
        meta.egress_metadata.routed = meta.l3_metadata.routed;
        meta.egress_metadata.bd = meta.ingress_metadata.bd;
        hdr.mpls[0].label = label;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
        meta.tunnel_metadata.egress_header_count = header_count;
        meta.tunnel_metadata.egress_tunnel_type = 5w13;
    }
    @name(".set_mpls_push_rewrite_l2") action set_mpls_push_rewrite_l2(bit<14> tunnel_index, bit<4> header_count) {
        meta.egress_metadata.routed = meta.l3_metadata.routed;
        meta.egress_metadata.bd = meta.ingress_metadata.bd;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
        meta.tunnel_metadata.egress_header_count = header_count;
        meta.tunnel_metadata.egress_tunnel_type = 5w13;
    }
    @name(".set_mpls_swap_push_rewrite_l3") action set_mpls_swap_push_rewrite_l3(bit<16> bd, bit<48> dmac, bit<20> label, bit<14> tunnel_index, bit<4> header_count) {
        meta.egress_metadata.routed = meta.l3_metadata.routed;
        meta.egress_metadata.bd = bd;
        hdr.mpls[0].label = label;
        meta.egress_metadata.mac_da = dmac;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
        meta.tunnel_metadata.egress_header_count = header_count;
        meta.tunnel_metadata.egress_tunnel_type = 5w14;
    }
    @name(".set_mpls_push_rewrite_l3") action set_mpls_push_rewrite_l3(bit<16> bd, bit<48> dmac, bit<14> tunnel_index, bit<4> header_count) {
        meta.egress_metadata.routed = meta.l3_metadata.routed;
        meta.egress_metadata.bd = bd;
        meta.egress_metadata.mac_da = dmac;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
        meta.tunnel_metadata.egress_header_count = header_count;
        meta.tunnel_metadata.egress_tunnel_type = 5w14;
    }
    @name(".rewrite_ipv4_multicast") action rewrite_ipv4_multicast() {
        hdr.ethernet.dstAddr[22:0] = ((bit<48>)hdr.ipv4.dstAddr)[22:0];
    }
    @name(".rewrite_ipv6_multicast") action rewrite_ipv6_multicast() {
    }
    @name(".rewrite") table rewrite {
        actions = {
            nop();
            set_l2_rewrite();
            set_l2_rewrite_with_tunnel();
            set_l3_rewrite();
            set_l3_rewrite_with_tunnel();
            set_mpls_swap_push_rewrite_l2();
            set_mpls_push_rewrite_l2();
            set_mpls_swap_push_rewrite_l3();
            set_mpls_push_rewrite_l3();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.nexthop_index: exact @name("l3_metadata.nexthop_index") ;
        }
        size = 43000;
        default_action = NoAction();
    }
    @name(".rewrite_multicast") table rewrite_multicast {
        actions = {
            nop();
            rewrite_ipv4_multicast();
            rewrite_ipv6_multicast();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.isValid()       : exact @name("ipv4.$valid$") ;
            hdr.ipv6.isValid()       : exact @name("ipv6.$valid$") ;
            hdr.ipv4.dstAddr[31:28]  : ternary @name("ipv4.dstAddr[31:28]") ;
            hdr.ipv6.dstAddr[127:120]: ternary @name("ipv6.dstAddr[127:120]") ;
        }
        default_action = NoAction();
    }
    apply {
        if (meta.egress_metadata.routed == 1w0 || meta.l3_metadata.nexthop_index != 16w0) 
            rewrite.apply();
        else 
            rewrite_multicast.apply();
    }
}

control process_egress_bd(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_egress_bd_properties") action set_egress_bd_properties(bit<9> smac_idx) {
        meta.egress_metadata.smac_idx = smac_idx;
    }
    @ternary(1) @name(".egress_bd_map") table egress_bd_map {
        actions = {
            nop();
            set_egress_bd_properties();
            @defaultonly NoAction();
        }
        key = {
            meta.egress_metadata.bd: exact @name("egress_metadata.bd") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    apply {
        egress_bd_map.apply();
    }
}

control process_mac_rewrite(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".ipv4_unicast_rewrite") action ipv4_unicast_rewrite() {
        hdr.ethernet.dstAddr = meta.egress_metadata.mac_da;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
    }
    @name(".ipv4_multicast_rewrite") action ipv4_multicast_rewrite() {
        hdr.ethernet.dstAddr = hdr.ethernet.dstAddr | 48w0x1005e000000;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
    }
    @name(".ipv6_unicast_rewrite") action ipv6_unicast_rewrite() {
        hdr.ethernet.dstAddr = meta.egress_metadata.mac_da;
        hdr.ipv6.hopLimit = hdr.ipv6.hopLimit + 8w255;
    }
    @name(".ipv6_multicast_rewrite") action ipv6_multicast_rewrite() {
        hdr.ethernet.dstAddr = hdr.ethernet.dstAddr | 48w0x333300000000;
        hdr.ipv6.hopLimit = hdr.ipv6.hopLimit + 8w255;
    }
    @name(".mpls_rewrite") action mpls_rewrite() {
        hdr.ethernet.dstAddr = meta.egress_metadata.mac_da;
        hdr.mpls[0].ttl = hdr.mpls[0].ttl + 8w255;
    }
    @name(".rewrite_smac") action rewrite_smac(bit<48> smac) {
        hdr.ethernet.srcAddr = smac;
    }
    @name(".l3_rewrite") table l3_rewrite {
        actions = {
            nop();
            ipv4_unicast_rewrite();
            ipv4_multicast_rewrite();
            ipv6_unicast_rewrite();
            ipv6_multicast_rewrite();
            mpls_rewrite();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.isValid()       : exact @name("ipv4.$valid$") ;
            hdr.ipv6.isValid()       : exact @name("ipv6.$valid$") ;
            hdr.mpls[0].isValid()    : exact @name("mpls[0].$valid$") ;
            hdr.ipv4.dstAddr[31:28]  : ternary @name("ipv4.dstAddr[31:28]") ;
            hdr.ipv6.dstAddr[127:120]: ternary @name("ipv6.dstAddr[127:120]") ;
        }
        default_action = NoAction();
    }
    @name(".smac_rewrite") table smac_rewrite {
        actions = {
            rewrite_smac();
            @defaultonly NoAction();
        }
        key = {
            meta.egress_metadata.smac_idx: exact @name("egress_metadata.smac_idx") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.egress_metadata.routed == 1w1) {
            l3_rewrite.apply();
            smac_rewrite.apply();
        }
    }
}

control process_mtu(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".mtu_miss") action mtu_miss() {
        meta.l3_metadata.l3_mtu_check = 16w0xffff;
    }
    @name(".ipv4_mtu_check") action ipv4_mtu_check(bit<16> l3_mtu) {
        meta.l3_metadata.l3_mtu_check = l3_mtu - hdr.ipv4.totalLen;
    }
    @name(".ipv6_mtu_check") action ipv6_mtu_check(bit<16> l3_mtu) {
        meta.l3_metadata.l3_mtu_check = l3_mtu - hdr.ipv6.payloadLen;
    }
    @name(".mtu") table mtu {
        actions = {
            mtu_miss();
            ipv4_mtu_check();
            ipv6_mtu_check();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.mtu_index: exact @name("l3_metadata.mtu_index") ;
            hdr.ipv4.isValid()        : exact @name("ipv4.$valid$") ;
            hdr.ipv6.isValid()        : exact @name("ipv6.$valid$") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        mtu.apply();
    }
}

control process_int_insertion(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_sflow_take_sample(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_tunnel_encap(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_egress_tunnel_vni") action set_egress_tunnel_vni(bit<24> vnid) {
        meta.tunnel_metadata.vnid = vnid;
    }
    @name(".rewrite_tunnel_dmac") action rewrite_tunnel_dmac(bit<48> dmac) {
        hdr.ethernet.dstAddr = dmac;
    }
    @name(".rewrite_tunnel_ipv4_dst") action rewrite_tunnel_ipv4_dst(bit<32> ip) {
        hdr.ipv4.dstAddr = ip;
    }
    @name(".rewrite_tunnel_ipv6_dst") action rewrite_tunnel_ipv6_dst(bit<128> ip) {
        hdr.ipv6.dstAddr = ip;
    }
    @name(".inner_ipv4_udp_rewrite") action inner_ipv4_udp_rewrite() {
        hdr.inner_ipv4 = hdr.ipv4;
        hdr.inner_udp = hdr.udp;
        meta.egress_metadata.payload_length = hdr.ipv4.totalLen;
        hdr.udp.setInvalid();
        hdr.ipv4.setInvalid();
    }
    @name(".inner_ipv4_tcp_rewrite") action inner_ipv4_tcp_rewrite() {
        hdr.inner_ipv4 = hdr.ipv4;
        hdr.inner_tcp.setValid();
        meta.egress_metadata.payload_length = hdr.ipv4.totalLen;
        hdr.tcp.setInvalid();
        hdr.ipv4.setInvalid();
    }
    @name(".inner_ipv4_icmp_rewrite") action inner_ipv4_icmp_rewrite() {
        hdr.inner_ipv4 = hdr.ipv4;
        hdr.inner_icmp = hdr.icmp;
        meta.egress_metadata.payload_length = hdr.ipv4.totalLen;
        hdr.icmp.setInvalid();
        hdr.ipv4.setInvalid();
    }
    @name(".inner_ipv4_unknown_rewrite") action inner_ipv4_unknown_rewrite() {
        hdr.inner_ipv4 = hdr.ipv4;
        meta.egress_metadata.payload_length = hdr.ipv4.totalLen;
        hdr.ipv4.setInvalid();
    }
    @name(".inner_ipv6_udp_rewrite") action inner_ipv6_udp_rewrite() {
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_udp = hdr.udp;
        meta.egress_metadata.payload_length = hdr.ipv6.payloadLen + 16w40;
        hdr.ipv6.setInvalid();
    }
    @name(".inner_ipv6_tcp_rewrite") action inner_ipv6_tcp_rewrite() {
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_tcp.setValid();
        meta.egress_metadata.payload_length = hdr.ipv6.payloadLen + 16w40;
        hdr.tcp.setInvalid();
        hdr.ipv6.setInvalid();
    }
    @name(".inner_ipv6_icmp_rewrite") action inner_ipv6_icmp_rewrite() {
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_icmp = hdr.icmp;
        meta.egress_metadata.payload_length = hdr.ipv6.payloadLen + 16w40;
        hdr.icmp.setInvalid();
        hdr.ipv6.setInvalid();
    }
    @name(".inner_ipv6_unknown_rewrite") action inner_ipv6_unknown_rewrite() {
        hdr.inner_ipv6 = hdr.ipv6;
        meta.egress_metadata.payload_length = hdr.ipv6.payloadLen + 16w40;
        hdr.ipv6.setInvalid();
    }
    @name(".inner_non_ip_rewrite") action inner_non_ip_rewrite() {
    }
    @name(".f_insert_vxlan_header") action f_insert_vxlan_header() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.udp.setValid();
        hdr.vxlan.setValid();
        hdr.udp.srcPort = meta.hash_metadata.entropy_hash;
        hdr.udp.dstPort = 16w4789;
        hdr.udp.checksum = 16w0;
        hdr.udp.length_ = meta.egress_metadata.payload_length + 16w30;
        hdr.vxlan.flags = 8w0x8;
        hdr.vxlan.reserved = 24w0;
        hdr.vxlan.vni = meta.tunnel_metadata.vnid;
        hdr.vxlan.reserved2 = 8w0;
    }
    @name(".f_insert_ipv4_header") action f_insert_ipv4_header(bit<8> proto) {
        hdr.ipv4.setValid();
        hdr.ipv4.protocol = proto;
        hdr.ipv4.ttl = 8w64;
        hdr.ipv4.version = 4w0x4;
        hdr.ipv4.ihl = 4w0x5;
        hdr.ipv4.identification = 16w0;
    }
    @name(".ipv4_vxlan_rewrite") action ipv4_vxlan_rewrite() {
        f_insert_vxlan_header();
        f_insert_ipv4_header(8w17);
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w50;
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".f_insert_ipv6_header") action f_insert_ipv6_header(bit<8> proto) {
        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w0x6;
        hdr.ipv6.nextHdr = proto;
        hdr.ipv6.hopLimit = 8w64;
        hdr.ipv6.trafficClass = 8w0;
        hdr.ipv6.flowLabel = 20w0;
    }
    @name(".ipv6_vxlan_rewrite") action ipv6_vxlan_rewrite() {
        f_insert_vxlan_header();
        f_insert_ipv6_header(8w17);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w30;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".f_insert_genv_header") action f_insert_genv_header() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.udp.setValid();
        hdr.genv.setValid();
        hdr.udp.srcPort = meta.hash_metadata.entropy_hash;
        hdr.udp.dstPort = 16w6081;
        hdr.udp.checksum = 16w0;
        hdr.udp.length_ = meta.egress_metadata.payload_length + 16w30;
        hdr.genv.ver = 2w0;
        hdr.genv.oam = 1w0;
        hdr.genv.critical = 1w0;
        hdr.genv.optLen = 6w0;
        hdr.genv.protoType = 16w0x6558;
        hdr.genv.vni = meta.tunnel_metadata.vnid;
        hdr.genv.reserved = 6w0;
        hdr.genv.reserved2 = 8w0;
    }
    @name(".ipv4_genv_rewrite") action ipv4_genv_rewrite() {
        f_insert_genv_header();
        f_insert_ipv4_header(8w17);
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w50;
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".ipv6_genv_rewrite") action ipv6_genv_rewrite() {
        f_insert_genv_header();
        f_insert_ipv6_header(8w17);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w30;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".f_insert_nvgre_header") action f_insert_nvgre_header() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.gre.setValid();
        hdr.nvgre.setValid();
        hdr.gre.proto = 16w0x6558;
        hdr.gre.recurse = 3w0;
        hdr.gre.flags = 5w0;
        hdr.gre.ver = 3w0;
        hdr.gre.R = 1w0;
        hdr.gre.K = 1w1;
        hdr.gre.C = 1w0;
        hdr.gre.S = 1w0;
        hdr.gre.s = 1w0;
        hdr.nvgre.tni = meta.tunnel_metadata.vnid;
        hdr.nvgre.flow_id[7:0] = ((bit<8>)meta.hash_metadata.entropy_hash)[7:0];
    }
    @name(".ipv4_nvgre_rewrite") action ipv4_nvgre_rewrite() {
        f_insert_nvgre_header();
        f_insert_ipv4_header(8w47);
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w42;
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".ipv6_nvgre_rewrite") action ipv6_nvgre_rewrite() {
        f_insert_nvgre_header();
        f_insert_ipv6_header(8w47);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w22;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".f_insert_gre_header") action f_insert_gre_header() {
        hdr.gre.setValid();
    }
    @name(".ipv4_gre_rewrite") action ipv4_gre_rewrite() {
        f_insert_gre_header();
        hdr.gre.proto = hdr.ethernet.etherType;
        f_insert_ipv4_header(8w47);
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w38;
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".ipv6_gre_rewrite") action ipv6_gre_rewrite() {
        f_insert_gre_header();
        hdr.gre.proto = 16w0x800;
        f_insert_ipv6_header(8w47);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w18;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".ipv4_ipv4_rewrite") action ipv4_ipv4_rewrite() {
        f_insert_ipv4_header(8w4);
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w20;
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".ipv4_ipv6_rewrite") action ipv4_ipv6_rewrite() {
        f_insert_ipv4_header(8w41);
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w40;
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".ipv6_ipv4_rewrite") action ipv6_ipv4_rewrite() {
        f_insert_ipv6_header(8w4);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w20;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".ipv6_ipv6_rewrite") action ipv6_ipv6_rewrite() {
        f_insert_ipv6_header(8w41);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w40;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".f_insert_erspan_t3_header") action f_insert_erspan_t3_header() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.gre.setValid();
        hdr.erspan_t3_header.setValid();
        hdr.gre.C = 1w0;
        hdr.gre.R = 1w0;
        hdr.gre.K = 1w0;
        hdr.gre.S = 1w0;
        hdr.gre.s = 1w0;
        hdr.gre.recurse = 3w0;
        hdr.gre.flags = 5w0;
        hdr.gre.ver = 3w0;
        hdr.gre.proto = 16w0x22eb;
        hdr.erspan_t3_header.timestamp = meta.i2e_metadata.ingress_tstamp;
        hdr.erspan_t3_header.span_id = (bit<10>)meta.i2e_metadata.mirror_session_id;
        hdr.erspan_t3_header.version = 4w2;
        hdr.erspan_t3_header.sgt_other = 32w0;
    }
    @name(".ipv4_erspan_t3_rewrite") action ipv4_erspan_t3_rewrite() {
        f_insert_erspan_t3_header();
        f_insert_ipv4_header(8w47);
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w50;
    }
    @name(".ipv6_erspan_t3_rewrite") action ipv6_erspan_t3_rewrite() {
        f_insert_erspan_t3_header();
        f_insert_ipv6_header(8w47);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w26;
    }
    @name(".mpls_ethernet_push1_rewrite") action mpls_ethernet_push1_rewrite() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.mpls.push_front(1);
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".mpls_ip_push1_rewrite") action mpls_ip_push1_rewrite() {
        hdr.mpls.push_front(1);
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".mpls_ethernet_push2_rewrite") action mpls_ethernet_push2_rewrite() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.mpls.push_front(2);
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".mpls_ip_push2_rewrite") action mpls_ip_push2_rewrite() {
        hdr.mpls.push_front(2);
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".mpls_ethernet_push3_rewrite") action mpls_ethernet_push3_rewrite() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.mpls.push_front(3);
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".mpls_ip_push3_rewrite") action mpls_ip_push3_rewrite() {
        hdr.mpls.push_front(3);
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".fabric_rewrite") action fabric_rewrite(bit<14> tunnel_index) {
        meta.tunnel_metadata.tunnel_index = tunnel_index;
    }
    @name(".tunnel_mtu_check") action tunnel_mtu_check(bit<16> l3_mtu) {
        meta.l3_metadata.l3_mtu_check = l3_mtu - meta.egress_metadata.payload_length;
    }
    @name(".tunnel_mtu_miss") action tunnel_mtu_miss() {
        meta.l3_metadata.l3_mtu_check = 16w0xffff;
    }
    @name(".set_tunnel_rewrite_details") action set_tunnel_rewrite_details(bit<16> outer_bd, bit<9> smac_idx, bit<14> dmac_idx, bit<9> sip_index, bit<14> dip_index) {
        meta.egress_metadata.outer_bd = outer_bd;
        meta.tunnel_metadata.tunnel_smac_index = smac_idx;
        meta.tunnel_metadata.tunnel_dmac_index = dmac_idx;
        meta.tunnel_metadata.tunnel_src_index = sip_index;
        meta.tunnel_metadata.tunnel_dst_index = dip_index;
    }
    @name(".set_mpls_rewrite_push1") action set_mpls_rewrite_push1(bit<20> label1, bit<3> exp1, bit<8> ttl1, bit<9> smac_idx, bit<14> dmac_idx) {
        hdr.mpls[0].label = label1;
        hdr.mpls[0].exp = exp1;
        hdr.mpls[0].bos = 1w0x1;
        hdr.mpls[0].ttl = ttl1;
        meta.tunnel_metadata.tunnel_smac_index = smac_idx;
        meta.tunnel_metadata.tunnel_dmac_index = dmac_idx;
    }
    @name(".set_mpls_rewrite_push2") action set_mpls_rewrite_push2(bit<20> label1, bit<3> exp1, bit<8> ttl1, bit<20> label2, bit<3> exp2, bit<8> ttl2, bit<9> smac_idx, bit<14> dmac_idx) {
        hdr.mpls[0].label = label1;
        hdr.mpls[0].exp = exp1;
        hdr.mpls[0].ttl = ttl1;
        hdr.mpls[0].bos = 1w0x0;
        hdr.mpls[1].label = label2;
        hdr.mpls[1].exp = exp2;
        hdr.mpls[1].ttl = ttl2;
        hdr.mpls[1].bos = 1w0x1;
        meta.tunnel_metadata.tunnel_smac_index = smac_idx;
        meta.tunnel_metadata.tunnel_dmac_index = dmac_idx;
    }
    @name(".set_mpls_rewrite_push3") action set_mpls_rewrite_push3(bit<20> label1, bit<3> exp1, bit<8> ttl1, bit<20> label2, bit<3> exp2, bit<8> ttl2, bit<20> label3, bit<3> exp3, bit<8> ttl3, bit<9> smac_idx, bit<14> dmac_idx) {
        hdr.mpls[0].label = label1;
        hdr.mpls[0].exp = exp1;
        hdr.mpls[0].ttl = ttl1;
        hdr.mpls[0].bos = 1w0x0;
        hdr.mpls[1].label = label2;
        hdr.mpls[1].exp = exp2;
        hdr.mpls[1].ttl = ttl2;
        hdr.mpls[1].bos = 1w0x0;
        hdr.mpls[2].label = label3;
        hdr.mpls[2].exp = exp3;
        hdr.mpls[2].ttl = ttl3;
        hdr.mpls[2].bos = 1w0x1;
        meta.tunnel_metadata.tunnel_smac_index = smac_idx;
        meta.tunnel_metadata.tunnel_dmac_index = dmac_idx;
    }
    @name(".cpu_rx_rewrite") action cpu_rx_rewrite() {
        hdr.fabric_header.setValid();
        hdr.fabric_header.headerVersion = 2w0;
        hdr.fabric_header.packetVersion = 2w0;
        hdr.fabric_header.pad1 = 1w0;
        hdr.fabric_header.packetType = 3w5;
        hdr.fabric_header_cpu.setValid();
        hdr.fabric_header_cpu.ingressPort = (bit<16>)meta.ingress_metadata.ingress_port;
        hdr.fabric_header_cpu.ingressIfindex = meta.ingress_metadata.ifindex;
        hdr.fabric_header_cpu.ingressBd = meta.ingress_metadata.bd;
        hdr.fabric_header_cpu.reasonCode = meta.fabric_metadata.reason_code;
        hdr.fabric_payload_header.setValid();
        hdr.fabric_payload_header.etherType = hdr.ethernet.etherType;
        hdr.ethernet.etherType = 16w0x9000;
    }
    @name(".rewrite_tunnel_smac") action rewrite_tunnel_smac(bit<48> smac) {
        hdr.ethernet.srcAddr = smac;
    }
    @name(".rewrite_tunnel_ipv4_src") action rewrite_tunnel_ipv4_src(bit<32> ip) {
        hdr.ipv4.srcAddr = ip;
    }
    @name(".rewrite_tunnel_ipv6_src") action rewrite_tunnel_ipv6_src(bit<128> ip) {
        hdr.ipv6.srcAddr = ip;
    }
    @name(".egress_vni") table egress_vni {
        actions = {
            nop();
            set_egress_tunnel_vni();
            @defaultonly NoAction();
        }
        key = {
            meta.egress_metadata.bd                : exact @name("egress_metadata.bd") ;
            meta.tunnel_metadata.egress_tunnel_type: exact @name("tunnel_metadata.egress_tunnel_type") ;
        }
        size = 16384;
        default_action = NoAction();
    }
    @name(".tunnel_dmac_rewrite") table tunnel_dmac_rewrite {
        actions = {
            nop();
            rewrite_tunnel_dmac();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.tunnel_dmac_index: exact @name("tunnel_metadata.tunnel_dmac_index") ;
        }
        size = 16384;
        default_action = NoAction();
    }
    @name(".tunnel_dst_rewrite") table tunnel_dst_rewrite {
        actions = {
            nop();
            rewrite_tunnel_ipv4_dst();
            rewrite_tunnel_ipv6_dst();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.tunnel_dst_index: exact @name("tunnel_metadata.tunnel_dst_index") ;
        }
        size = 16384;
        default_action = NoAction();
    }
    @name(".tunnel_encap_process_inner") table tunnel_encap_process_inner {
        actions = {
            inner_ipv4_udp_rewrite();
            inner_ipv4_tcp_rewrite();
            inner_ipv4_icmp_rewrite();
            inner_ipv4_unknown_rewrite();
            inner_ipv6_udp_rewrite();
            inner_ipv6_tcp_rewrite();
            inner_ipv6_icmp_rewrite();
            inner_ipv6_unknown_rewrite();
            inner_non_ip_rewrite();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.isValid(): exact @name("ipv4.$valid$") ;
            hdr.ipv6.isValid(): exact @name("ipv6.$valid$") ;
            hdr.tcp.isValid() : exact @name("tcp.$valid$") ;
            hdr.udp.isValid() : exact @name("udp.$valid$") ;
            hdr.icmp.isValid(): exact @name("icmp.$valid$") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".tunnel_encap_process_outer") table tunnel_encap_process_outer {
        actions = {
            nop();
            ipv4_vxlan_rewrite();
            ipv6_vxlan_rewrite();
            ipv4_genv_rewrite();
            ipv6_genv_rewrite();
            ipv4_nvgre_rewrite();
            ipv6_nvgre_rewrite();
            ipv4_gre_rewrite();
            ipv6_gre_rewrite();
            ipv4_ipv4_rewrite();
            ipv4_ipv6_rewrite();
            ipv6_ipv4_rewrite();
            ipv6_ipv6_rewrite();
            ipv4_erspan_t3_rewrite();
            ipv6_erspan_t3_rewrite();
            mpls_ethernet_push1_rewrite();
            mpls_ip_push1_rewrite();
            mpls_ethernet_push2_rewrite();
            mpls_ip_push2_rewrite();
            mpls_ethernet_push3_rewrite();
            mpls_ip_push3_rewrite();
            fabric_rewrite();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.egress_tunnel_type : exact @name("tunnel_metadata.egress_tunnel_type") ;
            meta.tunnel_metadata.egress_header_count: exact @name("tunnel_metadata.egress_header_count") ;
            meta.multicast_metadata.replica         : exact @name("multicast_metadata.replica") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".tunnel_mtu") table tunnel_mtu {
        actions = {
            tunnel_mtu_check();
            tunnel_mtu_miss();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.tunnel_index: exact @name("tunnel_metadata.tunnel_index") ;
        }
        size = 16384;
        default_action = NoAction();
    }
    @name(".tunnel_rewrite") table tunnel_rewrite {
        actions = {
            nop();
            set_tunnel_rewrite_details();
            set_mpls_rewrite_push1();
            set_mpls_rewrite_push2();
            set_mpls_rewrite_push3();
            cpu_rx_rewrite();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.tunnel_index: exact @name("tunnel_metadata.tunnel_index") ;
        }
        size = 16384;
        default_action = NoAction();
    }
    @name(".tunnel_smac_rewrite") table tunnel_smac_rewrite {
        actions = {
            nop();
            rewrite_tunnel_smac();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.tunnel_smac_index: exact @name("tunnel_metadata.tunnel_smac_index") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".tunnel_src_rewrite") table tunnel_src_rewrite {
        actions = {
            nop();
            rewrite_tunnel_ipv4_src();
            rewrite_tunnel_ipv6_src();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.tunnel_src_index: exact @name("tunnel_metadata.tunnel_src_index") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.fabric_metadata.fabric_header_present == 1w0 && meta.tunnel_metadata.egress_tunnel_type != 5w0) {
            egress_vni.apply();
            if (meta.tunnel_metadata.egress_tunnel_type != 5w15 && meta.tunnel_metadata.egress_tunnel_type != 5w16) 
                tunnel_encap_process_inner.apply();
            tunnel_encap_process_outer.apply();
            tunnel_rewrite.apply();
            tunnel_mtu.apply();
            tunnel_src_rewrite.apply();
            tunnel_dst_rewrite.apply();
            tunnel_smac_rewrite.apply();
            tunnel_dmac_rewrite.apply();
        }
    }
}

control process_int_outer_encap(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_vlan_xlate(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_egress_packet_vlan_untagged") action set_egress_packet_vlan_untagged() {
    }
    @name(".set_egress_packet_vlan_tagged") action set_egress_packet_vlan_tagged(bit<12> vlan_id) {
        hdr.vlan_tag_[0].setValid();
        hdr.vlan_tag_[0].etherType = hdr.ethernet.etherType;
        hdr.vlan_tag_[0].vid = vlan_id;
        hdr.ethernet.etherType = 16w0x8100;
    }
    @name(".set_egress_packet_vlan_double_tagged") action set_egress_packet_vlan_double_tagged(bit<12> s_tag, bit<12> c_tag) {
        hdr.vlan_tag_[1].setValid();
        hdr.vlan_tag_[0].setValid();
        hdr.vlan_tag_[1].etherType = hdr.ethernet.etherType;
        hdr.vlan_tag_[1].vid = c_tag;
        hdr.vlan_tag_[0].etherType = 16w0x8100;
        hdr.vlan_tag_[0].vid = s_tag;
        hdr.ethernet.etherType = 16w0x9100;
    }
    @name(".egress_vlan_xlate") table egress_vlan_xlate {
        actions = {
            set_egress_packet_vlan_untagged();
            set_egress_packet_vlan_tagged();
            set_egress_packet_vlan_double_tagged();
            @defaultonly NoAction();
        }
        key = {
            hdr.eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
            meta.egress_metadata.bd   : exact @name("egress_metadata.bd") ;
        }
        size = 32768;
        default_action = NoAction();
    }
    apply {
        egress_vlan_xlate.apply();
    }
}

control process_egress_filter(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_egress_acl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".egress_mirror") action egress_mirror(bit<32> session_id) {
        meta.i2e_metadata.mirror_session_id = (bit<16>)session_id;
        clone3<tuple<bit<32>, bit<16>>>(CloneType.E2E, session_id, { meta.i2e_metadata.ingress_tstamp, meta.i2e_metadata.mirror_session_id });
    }
    @name(".egress_mirror_drop") action egress_mirror_drop(bit<32> session_id) {
        egress_mirror(session_id);
        mark_to_drop();
    }
    @name(".egress_copy_to_cpu") action egress_copy_to_cpu(bit<16> reason_code) {
        meta.fabric_metadata.reason_code = reason_code;
        clone3<tuple<bit<16>, bit<16>, bit<16>, bit<9>>>(CloneType.E2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
    }
    @name(".egress_redirect_to_cpu") action egress_redirect_to_cpu(bit<16> reason_code) {
        egress_copy_to_cpu(reason_code);
        mark_to_drop();
    }
    @name(".egress_mirror_coal_hdr") action egress_mirror_coal_hdr(bit<8> session_id, bit<8> id) {
    }
    @name(".egress_acl") table egress_acl {
        actions = {
            nop();
            egress_mirror();
            egress_mirror_drop();
            egress_redirect_to_cpu();
            egress_mirror_coal_hdr();
            @defaultonly NoAction();
        }
        key = {
            hdr.eg_intr_md.egress_port    : ternary @name("eg_intr_md.egress_port") ;
            hdr.eg_intr_md.deflection_flag: ternary @name("eg_intr_md.deflection_flag") ;
            meta.l3_metadata.l3_mtu_check : ternary @name("l3_metadata.l3_mtu_check") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        if (meta.egress_metadata.bypass == 1w0) 
            egress_acl.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".egress_port_type_normal") action egress_port_type_normal() {
        meta.egress_metadata.port_type = 2w0;
        random<bit<32>>(meta.egress_metadata.sflow_take_sample, 32w0, 32w4294967295);
    }
    @name(".egress_port_type_fabric") action egress_port_type_fabric() {
        meta.egress_metadata.port_type = 2w1;
        meta.tunnel_metadata.egress_tunnel_type = 5w15;
    }
    @name(".egress_port_type_cpu") action egress_port_type_cpu() {
        meta.egress_metadata.port_type = 2w2;
        meta.tunnel_metadata.egress_tunnel_type = 5w16;
    }
    @name(".nop") action nop() {
    }
    @name(".set_mirror_nhop") action set_mirror_nhop(bit<16> nhop_idx) {
        meta.l3_metadata.nexthop_index = nhop_idx;
    }
    @name(".set_mirror_bd") action set_mirror_bd(bit<16> bd) {
        meta.egress_metadata.bd = bd;
    }
    @name(".egress_port_mapping") table egress_port_mapping {
        actions = {
            egress_port_type_normal();
            egress_port_type_fabric();
            egress_port_type_cpu();
            @defaultonly NoAction();
        }
        key = {
            hdr.eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        size = 288;
        default_action = NoAction();
    }
    @ternary(1) @name(".mirror") table mirror {
        actions = {
            nop();
            set_mirror_nhop();
            set_mirror_bd();
            @defaultonly NoAction();
        }
        key = {
            meta.i2e_metadata.mirror_session_id: exact @name("i2e_metadata.mirror_session_id") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".process_add_sflow_headers") process_add_sflow_headers() process_add_sflow_headers_0;
    @name(".process_replication") process_replication() process_replication_0;
    @name(".process_vlan_decap") process_vlan_decap() process_vlan_decap_0;
    @name(".process_egress_sflow") process_egress_sflow() process_egress_sflow_0;
    @name(".process_tunnel_decap") process_tunnel_decap() process_tunnel_decap_0;
    @name(".process_egress_nat") process_egress_nat() process_egress_nat_0;
    @name(".process_rewrite") process_rewrite() process_rewrite_0;
    @name(".process_egress_bd") process_egress_bd() process_egress_bd_0;
    @name(".process_mac_rewrite") process_mac_rewrite() process_mac_rewrite_0;
    @name(".process_mtu") process_mtu() process_mtu_0;
    @name(".process_int_insertion") process_int_insertion() process_int_insertion_0;
    @name(".process_sflow_take_sample") process_sflow_take_sample() process_sflow_take_sample_0;
    @name(".process_tunnel_encap") process_tunnel_encap() process_tunnel_encap_0;
    @name(".process_int_outer_encap") process_int_outer_encap() process_int_outer_encap_0;
    @name(".process_vlan_xlate") process_vlan_xlate() process_vlan_xlate_0;
    @name(".process_egress_filter") process_egress_filter() process_egress_filter_0;
    @name(".process_egress_acl") process_egress_acl() process_egress_acl_0;
    apply {
        if (hdr.eg_intr_md.deflection_flag == 1w0 && meta.egress_metadata.bypass == 1w0) {
            if (hdr.eg_intr_md_from_parser_aux.clone_src != 4w0) {
                mirror.apply();
                process_add_sflow_headers_0.apply(hdr, meta, standard_metadata);
            }
            else 
                process_replication_0.apply(hdr, meta, standard_metadata);
            switch (egress_port_mapping.apply().action_run) {
                egress_port_type_normal: {
                    if (hdr.eg_intr_md_from_parser_aux.clone_src == 4w0) {
                        process_vlan_decap_0.apply(hdr, meta, standard_metadata);
                        process_egress_sflow_0.apply(hdr, meta, standard_metadata);
                    }
                    process_tunnel_decap_0.apply(hdr, meta, standard_metadata);
                    process_egress_nat_0.apply(hdr, meta, standard_metadata);
                    process_rewrite_0.apply(hdr, meta, standard_metadata);
                    process_egress_bd_0.apply(hdr, meta, standard_metadata);
                    process_mac_rewrite_0.apply(hdr, meta, standard_metadata);
                    process_mtu_0.apply(hdr, meta, standard_metadata);
                    process_int_insertion_0.apply(hdr, meta, standard_metadata);
                }
            }

            process_sflow_take_sample_0.apply(hdr, meta, standard_metadata);
            process_tunnel_encap_0.apply(hdr, meta, standard_metadata);
            process_int_outer_encap_0.apply(hdr, meta, standard_metadata);
            if (meta.egress_metadata.port_type == 2w0) 
                process_vlan_xlate_0.apply(hdr, meta, standard_metadata);
            process_egress_filter_0.apply(hdr, meta, standard_metadata);
        }
        process_egress_acl_0.apply(hdr, meta, standard_metadata);
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".modify_outer_pri1") action modify_outer_pri1(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        meta.l2_metadata.field_1 = meta.ingress_metadata.port_type;
        meta.l2_metadata.field_2 = 2w0;
        meta.l2_metadata.field_3 = meta.ingress_metadata.port_type;
        meta.l2_metadata.field_4 = 2w1;
        meta.l2_metadata.field_5 = meta.l2_metadata.field_5 + 4w5;
        meta.l2_metadata.field_6 = 4w1;
        meta.l2_metadata.field_7 = meta.l2_metadata.field_7 + 4w2;
        meta.l2_metadata.field_8 = 4w3;
        meta.l2_metadata.field_9 = meta.l2_metadata.field_9 + 4w4;
        meta.l2_metadata.field_10 = 4w5;
        meta.l2_metadata.field_11 = 4w1;
        meta.l2_metadata.field_12 = 4w2;
        meta.l2_metadata.field_13 = 4w3;
        meta.l2_metadata.field_14 = meta.l2_metadata.field_14 + 4w4;
        meta.l2_metadata.field_15 = 4w5;
        meta.l2_metadata.field_16 = 4w1;
        meta.l2_metadata.field_17 = meta.l2_metadata.field_17 + 4w2;
        meta.l2_metadata.field_18 = 4w3;
        meta.l2_metadata.field_19 = meta.l2_metadata.field_19 + 4w4;
        meta.l2_metadata.field_20 = 4w5;
        meta.l2_metadata.field_21 = 4w1;
        meta.l2_metadata.field_22 = meta.l2_metadata.field_22 + 4w2;
        meta.l2_metadata.field_23 = 4w3;
        meta.l2_metadata.field_24 = meta.l2_metadata.field_24 + 4w4;
        meta.l2_metadata.field_25 = 4w5;
        meta.l2_metadata.field_26 = meta.l2_metadata.field_26 + 4w15;
        meta.l2_metadata.field_27 = 4w2;
        meta.l2_metadata.field_28 = 4w3;
        meta.l2_metadata.field_29 = 4w4;
        meta.l2_metadata.field_30 = 4w5;
        meta.l2_metadata.field_31 = 4w1;
        meta.l2_metadata.field_32 = 4w2;
        meta.l2_metadata.field_33 = 4w3;
        meta.l2_metadata.field_34 = 4w4;
        meta.l2_metadata.field_35 = 4w5;
        meta.l2_metadata.field_36 = 4w1;
        meta.l2_metadata.field_37 = 4w2;
        meta.l2_metadata.field_38 = 4w3;
        meta.l2_metadata.field_39 = meta.l2_metadata.field_39 + 4w4;
        meta.l2_metadata.field_40 = 4w5;
        meta.l2_metadata.field_41 = 4w1;
        meta.l2_metadata.field_42 = 4w2;
        meta.l2_metadata.field_43 = meta.l2_metadata.field_43 + 4w3;
        meta.l2_metadata.field_44 = 4w4;
        meta.l2_metadata.field_45 = meta.l2_metadata.field_45 + 4w5;
        meta.l2_metadata.field_46 = 4w1;
        meta.l2_metadata.field_47 = 4w2;
        meta.l2_metadata.field_48 = 4w3;
        meta.l2_metadata.field_49 = 4w4;
        meta.l2_metadata.field_50 = 4w5;
        meta.l2_metadata.field_51 = 4w1;
        meta.l2_metadata.field_52 = 4w2;
        meta.l2_metadata.field_53 = 4w3;
        meta.l2_metadata.field_54 = meta.l2_metadata.field_54 + 4w4;
        meta.l2_metadata.field_55 = 4w5;
        meta.l2_metadata.field_56 = meta.l2_metadata.field_56 + 4w1;
        meta.l2_metadata.field_57 = 4w2;
        meta.l2_metadata.field_58 = 4w3;
        meta.l2_metadata.field_59 = meta.l2_metadata.field_59 + 4w12;
        meta.l2_metadata.field_60 = 4w5;
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_sa = 48w1;
        meta.l2_metadata.lkp_mac_da = 48w1;
        meta.l2_metadata.lkp_mac_type = 16w1;
        meta.l2_metadata.l2_nexthop = 16w1;
        meta.l2_metadata.l2_src_move = 16w1;
        meta.l2_metadata.stp_group = 10w1;
        meta.l2_metadata.stp_state = 3w1;
        meta.l2_metadata.bd_stats_idx = 16w1;
        meta.l2_metadata.learning_enabled = 1w1;
        meta.l2_metadata.same_if_check = 16w1;
        meta.l2_metadata.mac_lmt_dlf = 2w1;
        meta.l2_metadata.mac_lmt_num = 16w1;
        meta.l2_metadata.block_info = 6w1;
        meta.l2_metadata.tpid = 16w1;
        meta.l2_metadata.sit = 3w1;
        meta.l2_metadata.router_bridge = 1w1;
        meta.l2_metadata.is_pritag = 1w1;
        meta.l2_metadata.vlanid = 12w1;
        meta.l2_metadata.addtag = 1w1;
        meta.l2_metadata.ovlaninfo = 16w1;
        meta.l2_metadata.ivlaninfo = 16w1;
        meta.l2_metadata.trunk_en = 1w1;
        meta.l2_metadata.trunk_id = 10w1;
        meta.l2_metadata.sb = 8w1;
        meta.l2_metadata.sp = 8w1;
        meta.l2_metadata.dai_en = 1w1;
        meta.l2_metadata.ns_enable = 1w1;
        meta.l2_metadata.vdc_id = 4w1;
        meta.l2_metadata.new_ovlan_info = 16w1;
        meta.l2_metadata.new_ivlan_info = 16w1;
        meta.l2_metadata.new_tag_num = 8w1;
        meta.l2_metadata.fwd_type = 3w1;
        meta.l2_metadata.tbl_type = 2w1;
        meta.l2_metadata.classid = 6w1;
        meta.l2_metadata.outter_pri_act = 1w1;
        meta.l2_metadata.outter_cfi_act = 1w1;
        meta.l2_metadata.inner_pri_act = 1w1;
        meta.l2_metadata.inner_cfi_act = 1w1;
        meta.l2_metadata.urpf_type = 3w1;
        meta.l2_metadata.vrfid = 16w1;
        meta.l2_metadata.vsi = 16w1;
        meta.l2_metadata.svp = 16w1;
        meta.l2_metadata.dvp = 16w1;
        meta.l2_metadata.vsi_valid = 1w1;
        meta.l2_metadata.vlanswitch_primode = 1w1;
        meta.l2_metadata.vlanswitch_oport = 16w1;
        meta.l2_metadata.vlanlrn_mode = 1w1;
        meta.l2_metadata.vlanlrn_lmt = 1w1;
        meta.l2_metadata.stg_id = 9w1;
        meta.l2_metadata.class_id = 6w1;
        meta.l2_metadata.vlan_mac_lmt_dlf = 2w1;
        meta.l2_metadata.vlan_lmt_num = 16w1;
        meta.l2_metadata.bypass_chk = 1w1;
        meta.l2_metadata.port_bitmap = 32w1;
        meta.l2_metadata.ipv4uc_en = 1w1;
        meta.l2_metadata.ipv4mc_en = 1w1;
        meta.l2_metadata.mplsuc_en = 1w1;
        meta.l2_metadata.mplsmc_en = 1w1;
        meta.l2_metadata.vlanif_vpn = 1w1;
        meta.l2_metadata.trilluc_en = 1w1;
        meta.l2_metadata.vxlane_en = 1w1;
        meta.l2_metadata.nvgre_en = 1w1;
        meta.l2_metadata.vplssogre_en = 1w1;
        meta.l2_metadata.l3gre_en = 1w1;
        meta.l2_metadata.ivsi_ext = 1w1;
        meta.l2_metadata.oport_info = 16w1;
        meta.l2_metadata.trunkid = 16w1;
        meta.l2_metadata.dvp_index = 16w1;
        meta.l2_metadata.be_opcode = 3w1;
        meta.l2_metadata.oport_is_trunk = 1w1;
        meta.l2_metadata.hash_rslt = 10w1;
        meta.l2_metadata.aib_opcode = 4w1;
        meta.l2_metadata.keytype = 5w1;
        meta.l2_metadata.src_vap_user = 1w1;
        meta.l2_metadata.src_trunk_flag = 1w1;
        meta.l2_metadata.outer_tag_pri = 3w1;
        meta.l2_metadata.outer_tag_cfi = 1w1;
        meta.l2_metadata.inner_tag_pri = 3w1;
        meta.l2_metadata.inner_tag_cfi = 1w1;
        meta.l3_metadata.rmac_group = 10w0;
        meta.l3_metadata.rmac_hit = 1w0;
        meta.l3_metadata.urpf_mode = 2w0;
        meta.l3_metadata.urpf_hit = 1w0;
        meta.l3_metadata.urpf_check_fail = 1w0;
        meta.l3_metadata.urpf_bd_group = 16w0;
        meta.l3_metadata.fib_hit = 1w0;
        meta.l3_metadata.fib_nexthop = 16w0;
        meta.l3_metadata.fib_nexthop_type = 1w0;
        meta.l3_metadata.same_bd_check = 16w0;
        meta.l3_metadata.mc = 1w0;
        meta.l3_metadata.l4_pkt_type = 8w0;
        meta.l3_metadata.ipv4_valid = 1w0;
        meta.l3_metadata.tcp_valid = 1w0;
        meta.l3_metadata.udp_valid = 1w0;
        meta.l3_metadata.fragOffSet = 13w0;
        meta.l3_metadata.nexthop_index = 16w0;
        meta.l3_metadata.outer_routed = 1w0;
        meta.l3_metadata.mtu_index = 8w0;
        meta.l3_metadata.l3_mtu_check = 16w0;
        meta.l3_metadata.tunnel_type = 4w0;
        meta.l3_metadata.bc = 1w0;
        meta.l3_metadata.field_1 = meta.ingress_metadata.drop_flag;
        meta.l3_metadata.field_2 = 1w1;
        meta.l3_metadata.field_3 = 1w1;
        meta.l3_metadata.field_4 = 1w1;
        meta.l3_metadata.field_5 = 1w1;
        meta.l3_metadata.field_6 = 1w1;
        meta.l3_metadata.field_7 = 1w1;
        meta.l3_metadata.field_8 = meta.ingress_metadata.drop_flag;
        meta.l3_metadata.field_9 = 1w1;
        meta.l3_metadata.field_10 = meta.ingress_metadata.drop_flag;
        meta.l3_metadata.field_11 = 1w1;
        meta.l3_metadata.field_12 = 1w1;
        meta.l3_metadata.field_13 = 1w1;
        meta.l3_metadata.field_14 = meta.ingress_metadata.drop_flag;
        meta.l3_metadata.field_15 = 1w1;
        meta.l3_metadata.field_16 = 1w1;
        meta.l3_metadata.field_17 = 1w1;
        meta.l3_metadata.field_18 = 1w1;
        meta.l3_metadata.field_19 = 1w1;
        meta.l3_metadata.field_20 = meta.ingress_metadata.drop_flag;
        meta.l3_metadata.field_21 = 1w1;
        meta.l3_metadata.field_22 = 1w1;
        meta.l3_metadata.field_23 = 1w1;
        meta.l3_metadata.field_24 = meta.ingress_metadata.drop_flag;
        meta.l3_metadata.field_25 = meta.ingress_metadata.drop_flag;
        meta.l3_metadata.field_26 = 1w1;
        meta.l3_metadata.field_27 = 1w1;
        meta.l3_metadata.field_28 = 1w1;
        meta.l3_metadata.field_29 = 1w1;
        meta.l3_metadata.field_30 = 1w1;
        meta.l3_metadata.field_31 = 1w1;
        meta.l3_metadata.field_32 = 1w1;
        meta.l3_metadata.field_33 = meta.ingress_metadata.drop_flag;
        meta.l3_metadata.field_34 = 1w1;
        meta.l3_metadata.field_35 = 1w1;
        meta.l3_metadata.field_36 = meta.ingress_metadata.drop_flag;
        meta.l3_metadata.field_37 = 1w1;
        meta.l3_metadata.field_38 = 1w1;
        meta.l3_metadata.field_39 = 1w1;
        meta.l3_metadata.field_40 = 1w1;
        meta.l3_metadata.field_41 = 1w1;
        meta.l3_metadata.field_42 = 1w1;
        meta.l3_metadata.field_43 = 1w1;
        meta.l3_metadata.field_44 = meta.ingress_metadata.drop_flag;
        meta.l3_metadata.field_45 = 1w1;
        meta.l3_metadata.field_46 = 1w1;
        meta.l3_metadata.field_47 = 1w1;
        meta.l3_metadata.field_48 = 1w1;
        meta.l3_metadata.field_49 = 1w1;
        meta.l3_metadata.field_50 = 1w1;
        meta.l3_metadata.field_51 = 1w1;
        meta.l3_metadata.field_52 = 1w1;
        meta.l3_metadata.field_53 = 1w1;
        meta.l3_metadata.field_54 = 1w1;
        meta.l3_metadata.field_55 = a;
        meta.l3_metadata.field_56 = 1w1;
        meta.l3_metadata.field_57 = b;
        meta.l3_metadata.field_58 = 1w1;
        meta.l3_metadata.field_59 = c;
        meta.l3_metadata.field_60 = 1w1;
        meta.l3_metadata.field_61 = 1w1;
        meta.l3_metadata.field_62 = 1w1;
        meta.l3_metadata.field_63 = 1w1;
        meta.l3_metadata.field_64 = d;
        meta.l3_metadata.field_65 = 1w1;
        meta.l3_metadata.field_66 = 1w1;
        meta.l3_metadata.field_67 = 1w1;
        meta.l3_metadata.field_68 = 1w1;
        meta.l3_metadata.field_69 = 1w1;
        meta.l3_metadata.field_70 = 1w1;
        meta.l3_metadata.field_71 = 1w1;
        meta.l3_metadata.field_72 = 1w1;
        meta.l3_metadata.field_73 = 1w1;
        meta.l3_metadata.field_74 = e;
        meta.l3_metadata.field_75 = 1w1;
        meta.l3_metadata.field_76 = 1w1;
        meta.l3_metadata.field_77 = 1w1;
        meta.l3_metadata.field_78 = 1w1;
        meta.l3_metadata.field_79 = a;
        meta.l3_metadata.field_80 = 1w1;
        meta.l3_metadata.field_81 = 1w1;
        meta.l3_metadata.field_82 = 1w1;
        meta.l3_metadata.field_83 = 1w1;
        meta.l3_metadata.field_84 = 1w1;
        meta.l3_metadata.field_85 = 1w1;
        meta.l3_metadata.field_86 = 1w1;
        meta.l3_metadata.field_87 = 1w1;
        meta.l3_metadata.field_88 = 1w1;
        meta.l3_metadata.field_89 = f;
        meta.l3_metadata.field_90 = 1w1;
        meta.l3_metadata.field_91 = 1w1;
        meta.l3_metadata.field_92 = 1w1;
        meta.l3_metadata.field_93 = 1w1;
        meta.l3_metadata.field_94 = 1w1;
        meta.l3_metadata.field_95 = 1w1;
        meta.l3_metadata.field_96 = 1w1;
        meta.l3_metadata.field_97 = 1w1;
        meta.l3_metadata.field_98 = 1w1;
        meta.l3_metadata.field_99 = 1w1;
        meta.l3_metadata.field_100 = 1w1;
        meta.l3_metadata.field_101 = 1w1;
        meta.l3_metadata.field_102 = 1w1;
        meta.l3_metadata.field_103 = 1w1;
        meta.l3_metadata.field_104 = 1w1;
        meta.l3_metadata.field_105 = 1w1;
        meta.l3_metadata.field_106 = 1w1;
        meta.l3_metadata.field_107 = 1w1;
        meta.l3_metadata.field_108 = 1w1;
        meta.l3_metadata.field_109 = 1w1;
        meta.l3_metadata.field_110 = 1w1;
        meta.l3_metadata.field_111 = 1w1;
        meta.l3_metadata.field_112 = 1w1;
        meta.l3_metadata.field_113 = 1w1;
        meta.l3_metadata.field_114 = 1w1;
        meta.l3_metadata.field_115 = b;
        meta.l3_metadata.field_116 = 1w1;
        meta.l3_metadata.field_117 = 1w1;
        meta.l3_metadata.field_118 = 1w1;
        meta.l3_metadata.field_119 = 1w1;
        meta.l3_metadata.field_120 = 1w1;
        meta.l3_metadata.field_121 = c;
        meta.l3_metadata.field_122 = 1w1;
        meta.l3_metadata.field_123 = 1w1;
        meta.l3_metadata.field_124 = 1w1;
        meta.l3_metadata.field_125 = 1w1;
        meta.l3_metadata.field_126 = 1w1;
        meta.l3_metadata.field_127 = 1w1;
        meta.l3_metadata.field_128 = 1w1;
        meta.l3_metadata.field_129 = 1w1;
        meta.l3_metadata.field_130 = 1w1;
        meta.l3_metadata.field_131 = 1w1;
        meta.l3_metadata.field_132 = 1w1;
        meta.l3_metadata.field_133 = 1w1;
        meta.l3_metadata.field_134 = 1w1;
        meta.l3_metadata.field_135 = 1w1;
        meta.l3_metadata.field_136 = 1w1;
        meta.l3_metadata.field_137 = 1w1;
        meta.l3_metadata.field_138 = 1w1;
        meta.l3_metadata.field_139 = 1w1;
        meta.l3_metadata.field_140 = 1w1;
        meta.l3_metadata.field_141 = 1w1;
        meta.l3_metadata.field_142 = 1w1;
        meta.l3_metadata.field_143 = 1w1;
        meta.l3_metadata.field_144 = d;
        meta.l3_metadata.field_145 = 1w1;
        meta.l3_metadata.field_146 = 1w1;
        meta.l3_metadata.field_147 = 1w1;
        meta.l3_metadata.field_148 = 1w1;
        meta.l3_metadata.field_149 = 1w1;
        meta.l3_metadata.field_150 = 1w1;
        meta.l3_metadata.field_151 = 1w1;
        meta.l3_metadata.field_152 = 1w1;
        meta.l3_metadata.field_153 = e;
        meta.l3_metadata.field_154 = 1w1;
        meta.l3_metadata.field_155 = 1w1;
        meta.l3_metadata.field_156 = 1w1;
        meta.l3_metadata.field_157 = 1w1;
        meta.l3_metadata.field_158 = 1w1;
        meta.l3_metadata.field_159 = 1w1;
        meta.l3_metadata.field_160 = meta.ingress_metadata.drop_flag;
    }
    @name(".modify_outer_pri2") action modify_outer_pri2(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        modify_outer_pri1(a, b, c, d, e, f);
    }
    @name(".modify_outer_pri3") action modify_outer_pri3(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        modify_outer_pri1(a, b, c, d, e, f);
    }
    @name(".modify_outer_pri4") action modify_outer_pri4(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        modify_outer_pri1(a, b, c, d, e, f);
    }
    @name(".modify_outer_pri5") action modify_outer_pri5(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        modify_outer_pri1(a, b, c, d, e, f);
    }
    @name(".modify_outer_pri6") action modify_outer_pri6(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        modify_outer_pri1(a, b, c, d, e, f);
    }
    @name(".modify_outer_pri7") action modify_outer_pri7(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        modify_outer_pri1(a, b, c, d, e, f);
    }
    @name(".modify_outer_pri8") action modify_outer_pri8(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        modify_outer_pri1(a, b, c, d, e, f);
    }
    @name(".modify_outer_pri9") action modify_outer_pri9(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        modify_outer_pri1(a, b, c, d, e, f);
    }
    @name(".modify_outer_pri10") action modify_outer_pri10(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        modify_outer_pri1(a, b, c, d, e, f);
    }
    @name(".modify_outer_pri11") action modify_outer_pri11(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        modify_outer_pri1(a, b, c, d, e, f);
    }
    @name(".modify_outer_pri12") action modify_outer_pri12(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        modify_outer_pri1(a, b, c, d, e, f);
    }
    @name(".modify_outer_pri13") action modify_outer_pri13(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        modify_outer_pri1(a, b, c, d, e, f);
    }
    @name(".modify_outer_pri14") action modify_outer_pri14(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        modify_outer_pri1(a, b, c, d, e, f);
    }
    @name(".modify_outer_pri15") action modify_outer_pri15(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        modify_outer_pri1(a, b, c, d, e, f);
    }
    @name(".modify_outer_pri16") action modify_outer_pri16(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        modify_outer_pri1(a, b, c, d, e, f);
    }
    @name(".modify_outer_pri17") action modify_outer_pri17(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        modify_outer_pri1(a, b, c, d, e, f);
    }
    @name(".modify_outer_pri18") action modify_outer_pri18(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        modify_outer_pri1(a, b, c, d, e, f);
    }
    @name(".modify_outer_pri19") action modify_outer_pri19(bit<1> a, bit<1> b, bit<1> c, bit<1> d, bit<1> e, bit<1> f) {
        modify_outer_pri1(a, b, c, d, e, f);
    }
    @name(".modify_outer_pri") table modify_outer_pri {
        actions = {
            modify_outer_pri1();
            modify_outer_pri2();
            modify_outer_pri3();
            modify_outer_pri4();
            modify_outer_pri5();
            modify_outer_pri6();
            modify_outer_pri7();
            modify_outer_pri8();
            modify_outer_pri9();
            modify_outer_pri10();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        default_action = NoAction();
    }
    @name(".modify_outer_pri_new1") table modify_outer_pri_new1 {
        actions = {
            modify_outer_pri1();
            modify_outer_pri2();
            modify_outer_pri3();
            modify_outer_pri4();
            modify_outer_pri5();
            modify_outer_pri6();
            modify_outer_pri7();
            modify_outer_pri8();
            modify_outer_pri9();
            modify_outer_pri11();
            modify_outer_pri12();
            modify_outer_pri13();
            modify_outer_pri14();
            modify_outer_pri15();
            modify_outer_pri16();
            modify_outer_pri17();
            modify_outer_pri18();
            modify_outer_pri19();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        default_action = NoAction();
    }
    apply {
        if (meta.l2_metadata.field_1 == 2w1) 
            modify_outer_pri.apply();
        else 
            if (meta.l2_metadata.field_1 == 2w2) 
                modify_outer_pri_new1.apply();
    }
}

control process_ipv4_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".on_miss") action on_miss() {
    }
    @name(".multicast_bridge_s_g_hit") action multicast_bridge_s_g_hit(bit<16> mc_index) {
        meta.multicast_metadata.multicast_bridge_mc_index = mc_index;
        meta.multicast_metadata.mcast_bridge_hit = 1w1;
    }
    @name(".nop") action nop() {
    }
    @name(".multicast_bridge_star_g_hit") action multicast_bridge_star_g_hit(bit<16> mc_index) {
        meta.multicast_metadata.multicast_bridge_mc_index = mc_index;
        meta.multicast_metadata.mcast_bridge_hit = 1w1;
    }
    @name(".multicast_route_s_g_hit") action multicast_route_s_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_mode = 2w1;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".multicast_route_sm_star_g_hit") action multicast_route_sm_star_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.mcast_mode = 2w1;
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".multicast_route_bidir_star_g_hit") action multicast_route_bidir_star_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.mcast_mode = 2w2;
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group | meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".ipv4_multicast_bridge") table ipv4_multicast_bridge {
        actions = {
            on_miss();
            multicast_bridge_s_g_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.bd      : exact @name("ingress_metadata.bd") ;
            meta.ipv4_metadata.lkp_ipv4_sa: exact @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    @name(".ipv4_multicast_bridge_star_g") table ipv4_multicast_bridge_star_g {
        actions = {
            nop();
            multicast_bridge_star_g_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.bd      : exact @name("ingress_metadata.bd") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 2048;
        default_action = NoAction();
    }
    @name(".ipv4_multicast_route") table ipv4_multicast_route {
        actions = {
            on_miss();
            multicast_route_s_g_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_sa: exact @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    @name(".ipv4_multicast_route_star_g") table ipv4_multicast_route_star_g {
        actions = {
            nop();
            multicast_route_sm_star_g_hit();
            multicast_route_bidir_star_g_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 2048;
        default_action = NoAction();
    }
    apply {
        switch (ipv4_multicast_bridge.apply().action_run) {
            on_miss: {
                ipv4_multicast_bridge_star_g.apply();
            }
        }

        if (meta.multicast_metadata.ipv4_multicast_mode != 2w0) 
            switch (ipv4_multicast_route.apply().action_run) {
                on_miss: {
                    ipv4_multicast_route_star_g.apply();
                }
            }

    }
}

control process_ipv4_vtep(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_tunnel_termination_flag") action set_tunnel_termination_flag() {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
    }
    @name(".on_miss") action on_miss() {
    }
    @name(".src_vtep_hit") action src_vtep_hit(bit<16> ifindex) {
        meta.ingress_metadata.ifindex = ifindex;
    }
    @name(".ipv4_dest_vtep") table ipv4_dest_vtep {
        actions = {
            nop();
            set_tunnel_termination_flag();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf                    : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da          : exact @name("ipv4_metadata.lkp_ipv4_da") ;
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("tunnel_metadata.ingress_tunnel_type") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".ipv4_src_vtep") table ipv4_src_vtep {
        actions = {
            on_miss();
            src_vtep_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_sa: exact @name("ipv4_metadata.lkp_ipv4_sa") ;
        }
        size = 16384;
        default_action = NoAction();
    }
    apply {
        switch (ipv4_src_vtep.apply().action_run) {
            src_vtep_hit: {
                ipv4_dest_vtep.apply();
            }
        }

    }
}

control process_ipv6_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".on_miss") action on_miss() {
    }
    @name(".multicast_bridge_s_g_hit") action multicast_bridge_s_g_hit(bit<16> mc_index) {
        meta.multicast_metadata.multicast_bridge_mc_index = mc_index;
        meta.multicast_metadata.mcast_bridge_hit = 1w1;
    }
    @name(".nop") action nop() {
    }
    @name(".multicast_bridge_star_g_hit") action multicast_bridge_star_g_hit(bit<16> mc_index) {
        meta.multicast_metadata.multicast_bridge_mc_index = mc_index;
        meta.multicast_metadata.mcast_bridge_hit = 1w1;
    }
    @name(".multicast_route_s_g_hit") action multicast_route_s_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_mode = 2w1;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".multicast_route_sm_star_g_hit") action multicast_route_sm_star_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.mcast_mode = 2w1;
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".multicast_route_bidir_star_g_hit") action multicast_route_bidir_star_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.mcast_mode = 2w2;
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group | meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".ipv6_multicast_bridge") table ipv6_multicast_bridge {
        actions = {
            on_miss();
            multicast_bridge_s_g_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.bd      : exact @name("ingress_metadata.bd") ;
            meta.ipv6_metadata.lkp_ipv6_sa: exact @name("ipv6_metadata.lkp_ipv6_sa") ;
            meta.ipv6_metadata.lkp_ipv6_da: exact @name("ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".ipv6_multicast_bridge_star_g") table ipv6_multicast_bridge_star_g {
        actions = {
            nop();
            multicast_bridge_star_g_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.bd      : exact @name("ingress_metadata.bd") ;
            meta.ipv6_metadata.lkp_ipv6_da: exact @name("ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".ipv6_multicast_route") table ipv6_multicast_route {
        actions = {
            on_miss();
            multicast_route_s_g_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_sa: exact @name("ipv6_metadata.lkp_ipv6_sa") ;
            meta.ipv6_metadata.lkp_ipv6_da: exact @name("ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".ipv6_multicast_route_star_g") table ipv6_multicast_route_star_g {
        actions = {
            nop();
            multicast_route_sm_star_g_hit();
            multicast_route_bidir_star_g_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_da: exact @name("ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        switch (ipv6_multicast_bridge.apply().action_run) {
            on_miss: {
                ipv6_multicast_bridge_star_g.apply();
            }
        }

        if (meta.multicast_metadata.ipv6_multicast_mode != 2w0) 
            switch (ipv6_multicast_route.apply().action_run) {
                on_miss: {
                    ipv6_multicast_route_star_g.apply();
                }
            }

    }
}

control process_ipv6_vtep(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_tunnel_termination_flag") action set_tunnel_termination_flag() {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
    }
    @name(".on_miss") action on_miss() {
    }
    @name(".src_vtep_hit") action src_vtep_hit(bit<16> ifindex) {
        meta.ingress_metadata.ifindex = ifindex;
    }
    @name(".ipv6_dest_vtep") table ipv6_dest_vtep {
        actions = {
            nop();
            set_tunnel_termination_flag();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf                    : exact @name("l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_da          : exact @name("ipv6_metadata.lkp_ipv6_da") ;
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("tunnel_metadata.ingress_tunnel_type") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".ipv6_src_vtep") table ipv6_src_vtep {
        actions = {
            on_miss();
            src_vtep_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_sa: exact @name("ipv6_metadata.lkp_ipv6_sa") ;
        }
        size = 16384;
        default_action = NoAction();
    }
    apply {
        switch (ipv6_src_vtep.apply().action_run) {
            src_vtep_hit: {
                ipv6_dest_vtep.apply();
            }
        }

    }
}

control process_mpls(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".terminate_eompls") action terminate_eompls(bit<16> bd, bit<5> tunnel_type) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.tunnel_metadata.ingress_tunnel_type = tunnel_type;
        meta.ingress_metadata.bd = bd;
        meta.l2_metadata.lkp_mac_sa = hdr.inner_ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.inner_ethernet.dstAddr;
        meta.l2_metadata.lkp_mac_type = hdr.inner_ethernet.etherType;
    }
    @name(".terminate_vpls") action terminate_vpls(bit<16> bd, bit<5> tunnel_type) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.tunnel_metadata.ingress_tunnel_type = tunnel_type;
        meta.ingress_metadata.bd = bd;
        meta.l2_metadata.lkp_mac_sa = hdr.inner_ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.inner_ethernet.dstAddr;
        meta.l2_metadata.lkp_mac_type = hdr.inner_ethernet.etherType;
    }
    @name(".terminate_ipv4_over_mpls") action terminate_ipv4_over_mpls(bit<16> vrf, bit<5> tunnel_type) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.tunnel_metadata.ingress_tunnel_type = tunnel_type;
        meta.l3_metadata.vrf = vrf;
        meta.l3_metadata.lkp_ip_type = 2w1;
        meta.ipv4_metadata.lkp_ipv4_sa = hdr.inner_ipv4.srcAddr;
        meta.ipv4_metadata.lkp_ipv4_da = hdr.inner_ipv4.dstAddr;
        meta.l3_metadata.lkp_ip_version = hdr.inner_ipv4.version;
        meta.l3_metadata.lkp_ip_proto = hdr.inner_ipv4.protocol;
        meta.l3_metadata.lkp_ip_tc = hdr.inner_ipv4.diffserv;
        meta.l3_metadata.lkp_ip_ttl = hdr.inner_ipv4.ttl;
        meta.l3_metadata.lkp_l4_sport = meta.l3_metadata.lkp_inner_l4_sport;
        meta.l3_metadata.lkp_l4_dport = meta.l3_metadata.lkp_inner_l4_dport;
    }
    @name(".terminate_ipv6_over_mpls") action terminate_ipv6_over_mpls(bit<16> vrf, bit<5> tunnel_type) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.tunnel_metadata.ingress_tunnel_type = tunnel_type;
        meta.l3_metadata.vrf = vrf;
        meta.l3_metadata.lkp_ip_type = 2w2;
        meta.ipv6_metadata.lkp_ipv6_sa = hdr.inner_ipv6.srcAddr;
        meta.ipv6_metadata.lkp_ipv6_da = hdr.inner_ipv6.dstAddr;
        meta.l3_metadata.lkp_ip_version = hdr.inner_ipv6.version;
        meta.l3_metadata.lkp_ip_proto = hdr.inner_ipv6.nextHdr;
        meta.l3_metadata.lkp_ip_tc = hdr.inner_ipv6.trafficClass;
        meta.l3_metadata.lkp_ip_ttl = hdr.inner_ipv6.hopLimit;
        meta.l3_metadata.lkp_l4_sport = meta.l3_metadata.lkp_inner_l4_sport;
        meta.l3_metadata.lkp_l4_dport = meta.l3_metadata.lkp_inner_l4_dport;
    }
    @name(".terminate_pw") action terminate_pw(bit<16> ifindex) {
        meta.ingress_metadata.egress_ifindex = ifindex;
    }
    @name(".forward_mpls") action forward_mpls(bit<16> nexthop_index) {
        meta.l3_metadata.fib_nexthop = nexthop_index;
        meta.l3_metadata.fib_nexthop_type = 1w0;
        meta.l3_metadata.fib_hit = 1w1;
    }
    @ternary(1) @name(".mpls") table mpls_0 {
        actions = {
            terminate_eompls();
            terminate_vpls();
            terminate_ipv4_over_mpls();
            terminate_ipv6_over_mpls();
            terminate_pw();
            forward_mpls();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.mpls_label: exact @name("tunnel_metadata.mpls_label") ;
            hdr.inner_ipv4.isValid()       : exact @name("inner_ipv4.$valid$") ;
            hdr.inner_ipv6.isValid()       : exact @name("inner_ipv6.$valid$") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    apply {
        mpls_0.apply();
    }
}

control process_multicast_rpf(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_outer_ipv4_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".on_miss") action on_miss() {
    }
    @name(".outer_multicast_route_s_g_hit") action outer_multicast_route_s_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_bridge_s_g_hit") action outer_multicast_bridge_s_g_hit(bit<16> mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.tunnel_metadata.tunnel_terminate = 1w1;
    }
    @name(".outer_multicast_route_sm_star_g_hit") action outer_multicast_route_sm_star_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.outer_mcast_mode = 2w1;
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_route_bidir_star_g_hit") action outer_multicast_route_bidir_star_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.outer_mcast_mode = 2w2;
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group | meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_bridge_star_g_hit") action outer_multicast_bridge_star_g_hit(bit<16> mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.tunnel_metadata.tunnel_terminate = 1w1;
    }
    @name(".outer_ipv4_multicast") table outer_ipv4_multicast {
        actions = {
            nop();
            on_miss();
            outer_multicast_route_s_g_hit();
            outer_multicast_bridge_s_g_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.multicast_metadata.ipv4_mcast_key_type: exact @name("multicast_metadata.ipv4_mcast_key_type") ;
            meta.multicast_metadata.ipv4_mcast_key     : exact @name("multicast_metadata.ipv4_mcast_key") ;
            meta.ipv4_metadata.lkp_ipv4_sa             : exact @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da             : exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".outer_ipv4_multicast_star_g") table outer_ipv4_multicast_star_g {
        actions = {
            nop();
            outer_multicast_route_sm_star_g_hit();
            outer_multicast_route_bidir_star_g_hit();
            outer_multicast_bridge_star_g_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.multicast_metadata.ipv4_mcast_key_type: exact @name("multicast_metadata.ipv4_mcast_key_type") ;
            meta.multicast_metadata.ipv4_mcast_key     : exact @name("multicast_metadata.ipv4_mcast_key") ;
            meta.ipv4_metadata.lkp_ipv4_da             : ternary @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        switch (outer_ipv4_multicast.apply().action_run) {
            on_miss: {
                outer_ipv4_multicast_star_g.apply();
            }
        }

    }
}

control process_outer_ipv6_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".on_miss") action on_miss() {
    }
    @name(".outer_multicast_route_s_g_hit") action outer_multicast_route_s_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_bridge_s_g_hit") action outer_multicast_bridge_s_g_hit(bit<16> mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.tunnel_metadata.tunnel_terminate = 1w1;
    }
    @name(".outer_multicast_route_sm_star_g_hit") action outer_multicast_route_sm_star_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.outer_mcast_mode = 2w1;
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_route_bidir_star_g_hit") action outer_multicast_route_bidir_star_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.outer_mcast_mode = 2w2;
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group | meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_bridge_star_g_hit") action outer_multicast_bridge_star_g_hit(bit<16> mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.tunnel_metadata.tunnel_terminate = 1w1;
    }
    @name(".outer_ipv6_multicast") table outer_ipv6_multicast {
        actions = {
            nop();
            on_miss();
            outer_multicast_route_s_g_hit();
            outer_multicast_bridge_s_g_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.multicast_metadata.ipv6_mcast_key_type: exact @name("multicast_metadata.ipv6_mcast_key_type") ;
            meta.multicast_metadata.ipv6_mcast_key     : exact @name("multicast_metadata.ipv6_mcast_key") ;
            meta.ipv6_metadata.lkp_ipv6_sa             : exact @name("ipv6_metadata.lkp_ipv6_sa") ;
            meta.ipv6_metadata.lkp_ipv6_da             : exact @name("ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".outer_ipv6_multicast_star_g") table outer_ipv6_multicast_star_g {
        actions = {
            nop();
            outer_multicast_route_sm_star_g_hit();
            outer_multicast_route_bidir_star_g_hit();
            outer_multicast_bridge_star_g_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.multicast_metadata.ipv6_mcast_key_type: exact @name("multicast_metadata.ipv6_mcast_key_type") ;
            meta.multicast_metadata.ipv6_mcast_key     : exact @name("multicast_metadata.ipv6_mcast_key") ;
            meta.ipv6_metadata.lkp_ipv6_da             : ternary @name("ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        switch (outer_ipv6_multicast.apply().action_run) {
            on_miss: {
                outer_ipv6_multicast_star_g.apply();
            }
        }

    }
}

control process_outer_multicast_rpf(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_outer_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".process_outer_ipv4_multicast") process_outer_ipv4_multicast() process_outer_ipv4_multicast_0;
    @name(".process_outer_ipv6_multicast") process_outer_ipv6_multicast() process_outer_ipv6_multicast_0;
    @name(".process_outer_multicast_rpf") process_outer_multicast_rpf() process_outer_multicast_rpf_0;
    apply {
        if (hdr.ipv4.isValid()) 
            process_outer_ipv4_multicast_0.apply(hdr, meta, standard_metadata);
        else 
            if (hdr.ipv6.isValid()) 
                process_outer_ipv6_multicast_0.apply(hdr, meta, standard_metadata);
        process_outer_multicast_rpf_0.apply(hdr, meta, standard_metadata);
    }
}

control validate_outer_ipv4_header(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_valid_outer_ipv4_packet") action set_valid_outer_ipv4_packet() {
        meta.l3_metadata.lkp_ip_type = 2w1;
        meta.l3_metadata.lkp_ip_tc = hdr.ipv4.diffserv;
        meta.l3_metadata.lkp_ip_version = 4w4;
    }
    @name(".set_malformed_outer_ipv4_packet") action set_malformed_outer_ipv4_packet(bit<8> drop_reason) {
        meta.ingress_metadata.drop_flag = 1w1;
        meta.ingress_metadata.drop_reason = drop_reason;
    }
    @name(".validate_outer_ipv4_packet") table validate_outer_ipv4_packet {
        actions = {
            set_valid_outer_ipv4_packet();
            set_malformed_outer_ipv4_packet();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.version                     : ternary @name("ipv4.version") ;
            meta.l3_metadata.lkp_ip_ttl          : ternary @name("l3_metadata.lkp_ip_ttl") ;
            meta.ipv4_metadata.lkp_ipv4_sa[31:24]: ternary @name("ipv4_metadata.lkp_ipv4_sa[31:24]") ;
        }
        size = 64;
        default_action = NoAction();
    }
    apply {
        validate_outer_ipv4_packet.apply();
    }
}

control validate_outer_ipv6_header(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_valid_outer_ipv6_packet") action set_valid_outer_ipv6_packet() {
        meta.l3_metadata.lkp_ip_type = 2w2;
        meta.l3_metadata.lkp_ip_tc = hdr.ipv6.trafficClass;
        meta.l3_metadata.lkp_ip_version = 4w6;
    }
    @name(".set_malformed_outer_ipv6_packet") action set_malformed_outer_ipv6_packet(bit<8> drop_reason) {
        meta.ingress_metadata.drop_flag = 1w1;
        meta.ingress_metadata.drop_reason = drop_reason;
    }
    @name(".validate_outer_ipv6_packet") table validate_outer_ipv6_packet {
        actions = {
            set_valid_outer_ipv6_packet();
            set_malformed_outer_ipv6_packet();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv6.version                       : ternary @name("ipv6.version") ;
            meta.l3_metadata.lkp_ip_ttl            : ternary @name("l3_metadata.lkp_ip_ttl") ;
            meta.ipv6_metadata.lkp_ipv6_sa[127:112]: ternary @name("ipv6_metadata.lkp_ipv6_sa[127:112]") ;
        }
        size = 64;
        default_action = NoAction();
    }
    apply {
        validate_outer_ipv6_packet.apply();
    }
}

control validate_mpls_header(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_valid_mpls_label1") action set_valid_mpls_label1() {
        meta.tunnel_metadata.mpls_label = hdr.mpls[0].label;
        meta.tunnel_metadata.mpls_exp = hdr.mpls[0].exp;
    }
    @name(".set_valid_mpls_label2") action set_valid_mpls_label2() {
        meta.tunnel_metadata.mpls_label = hdr.mpls[1].label;
        meta.tunnel_metadata.mpls_exp = hdr.mpls[1].exp;
    }
    @name(".set_valid_mpls_label3") action set_valid_mpls_label3() {
        meta.tunnel_metadata.mpls_label = hdr.mpls[2].label;
        meta.tunnel_metadata.mpls_exp = hdr.mpls[2].exp;
    }
    @name(".validate_mpls_packet") table validate_mpls_packet {
        actions = {
            set_valid_mpls_label1();
            set_valid_mpls_label2();
            set_valid_mpls_label3();
            @defaultonly NoAction();
        }
        key = {
            hdr.mpls[0].label    : ternary @name("mpls[0].label") ;
            hdr.mpls[0].bos      : ternary @name("mpls[0].bos") ;
            hdr.mpls[0].isValid(): exact @name("mpls[0].$valid$") ;
            hdr.mpls[1].label    : ternary @name("mpls[1].label") ;
            hdr.mpls[1].bos      : ternary @name("mpls[1].bos") ;
            hdr.mpls[1].isValid(): exact @name("mpls[1].$valid$") ;
            hdr.mpls[2].label    : ternary @name("mpls[2].label") ;
            hdr.mpls[2].bos      : ternary @name("mpls[2].bos") ;
            hdr.mpls[2].isValid(): exact @name("mpls[2].$valid$") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        validate_mpls_packet.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<fabric_header_t>(hdr.fabric_header);
        packet.emit<fabric_header_cpu_t>(hdr.fabric_header_cpu);
        packet.emit<fabric_payload_header_t>(hdr.fabric_payload_header);
        packet.emit<llc_header_t>(hdr.llc_header);
        packet.emit<snap_header_t>(hdr.snap_header);
        packet.emit<vlan_tag_t>(hdr.vlan_tag_[0]);
        packet.emit<vlan_tag_t>(hdr.vlan_tag_[1]);
        packet.emit<arp_rarp_t>(hdr.arp_rarp);
        packet.emit<arp_rarp_ipv4_t>(hdr.arp_rarp_ipv4);
        packet.emit<ipv6_t>(hdr.ipv6);
        packet.emit<ipv4_t>(hdr.ipv4);
        packet.emit<gre_t>(hdr.gre);
        packet.emit<erspan_header_t3_t_0>(hdr.erspan_t3_header);
        packet.emit<nvgre_t>(hdr.nvgre);
        packet.emit<udp_t>(hdr.udp);
        packet.emit<genv_t>(hdr.genv);
        packet.emit<vxlan_t>(hdr.vxlan);
        packet.emit<tcp_t>(hdr.tcp);
        packet.emit<icmp_t>(hdr.icmp);
        packet.emit<mpls_t[3]>(hdr.mpls);
        packet.emit<ethernet_t>(hdr.inner_ethernet);
        packet.emit<ipv6_t>(hdr.inner_ipv6);
        packet.emit<ipv4_t>(hdr.inner_ipv4);
        packet.emit<udp_t>(hdr.inner_udp);
        packet.emit<tcp_t>(hdr.inner_tcp);
        packet.emit<icmp_t>(hdr.inner_icmp);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
        verify_checksum<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>, bit<16>>(true, { hdr.inner_ipv4.version, hdr.inner_ipv4.ihl, hdr.inner_ipv4.diffserv, hdr.inner_ipv4.totalLen, hdr.inner_ipv4.identification, hdr.inner_ipv4.flags, hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.ttl, hdr.inner_ipv4.protocol, hdr.inner_ipv4.srcAddr, hdr.inner_ipv4.dstAddr }, hdr.inner_ipv4.hdrChecksum, HashAlgorithm.csum16);
        verify_checksum<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>, bit<16>>(true, { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
        update_checksum<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>, bit<16>>(true, { hdr.inner_ipv4.version, hdr.inner_ipv4.ihl, hdr.inner_ipv4.diffserv, hdr.inner_ipv4.totalLen, hdr.inner_ipv4.identification, hdr.inner_ipv4.flags, hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.ttl, hdr.inner_ipv4.protocol, hdr.inner_ipv4.srcAddr, hdr.inner_ipv4.dstAddr }, hdr.inner_ipv4.hdrChecksum, HashAlgorithm.csum16);
        update_checksum<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>, bit<16>>(true, { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

