#include <core.p4>
#include <v1model.p4>

struct acl_metadata_t {
    bit<1>  acl_deny;
    bit<1>  racl_deny;
    bit<16> acl_nexthop;
    bit<16> racl_nexthop;
    bit<1>  acl_nexthop_type;
    bit<1>  racl_nexthop_type;
    bit<1>  acl_redirect;
    bit<1>  racl_redirect;
}

struct egress_metadata_t {
    bit<16> payload_length;
    bit<9>  smac_idx;
    bit<16> bd;
    bit<1>  inner_replica;
    bit<1>  replica;
    bit<48> mac_da;
    bit<1>  routed;
    bit<16> same_bd_check;
    bit<4>  header_count;
    bit<8>  drop_reason;
    bit<1>  egress_bypass;
    bit<1>  fabric_bypass;
    bit<8>  drop_exception;
}

struct fabric_header_internal_t {
    bit<3>  packetType;
    bit<5>  pad1;
    bit<8>  ingress_tunnel_type;
    bit<16> egress_bd;
    bit<16> nexthop_index;
    bit<16> lkp_mac_type;
    bit<1>  routed;
    bit<1>  outer_routed;
    bit<1>  tunnel_terminate;
    bit<4>  header_count;
    bit<1>  pad2;
}

struct ingress_metadata_t {
    bit<16> lkp_l4_sport;
    bit<16> lkp_l4_dport;
    bit<16> lkp_inner_l4_sport;
    bit<16> lkp_inner_l4_dport;
    bit<8>  lkp_icmp_type;
    bit<8>  lkp_icmp_code;
    bit<8>  lkp_inner_icmp_type;
    bit<8>  lkp_inner_icmp_code;
    bit<16> ifindex;
    bit<2>  vrf;
    bit<16> outer_bd;
    bit<8>  outer_dscp;
    bit<1>  src_is_link_local;
    bit<16> bd;
    bit<16> uuc_mc_index;
    bit<16> umc_mc_index;
    bit<16> bcast_mc_index;
    bit<16> if_label;
    bit<16> bd_label;
    bit<1>  ipsg_check_fail;
    bit<10> mirror_session_id;
    bit<3>  marked_cos;
    bit<8>  marked_dscp;
    bit<3>  marked_exp;
    bit<16> egress_ifindex;
    bit<16> same_bd_check;
    bit<24> ipv4_dstaddr_24b;
    bit<1>  drop_0;
    bit<8>  drop_reason;
    bit<1>  control_frame;
}

struct ipv4_metadata_t {
    bit<32> lkp_ipv4_sa;
    bit<32> lkp_ipv4_da;
    bit<1>  ipv4_unicast_enabled;
    bit<2>  ipv4_urpf_mode;
    bit<1>  fib_hit_exm_prefix_length_32;
    bit<10> fib_nexthop_exm_prefix_length_32;
    bit<1>  fib_nexthop_type_exm_prefix_length_32;
    bit<1>  fib_hit_exm_prefix_length_31;
    bit<10> fib_nexthop_exm_prefix_length_31;
    bit<1>  fib_nexthop_type_exm_prefix_length_31;
    bit<1>  fib_hit_exm_prefix_length_30;
    bit<10> fib_nexthop_exm_prefix_length_30;
    bit<1>  fib_nexthop_type_exm_prefix_length_30;
    bit<1>  fib_hit_exm_prefix_length_29;
    bit<10> fib_nexthop_exm_prefix_length_29;
    bit<1>  fib_nexthop_type_exm_prefix_length_29;
    bit<1>  fib_hit_exm_prefix_length_28;
    bit<10> fib_nexthop_exm_prefix_length_28;
    bit<1>  fib_nexthop_type_exm_prefix_length_28;
    bit<1>  fib_hit_exm_prefix_length_27;
    bit<10> fib_nexthop_exm_prefix_length_27;
    bit<1>  fib_nexthop_type_exm_prefix_length_27;
    bit<1>  fib_hit_exm_prefix_length_26;
    bit<10> fib_nexthop_exm_prefix_length_26;
    bit<1>  fib_nexthop_type_exm_prefix_length_26;
    bit<1>  fib_hit_exm_prefix_length_25;
    bit<10> fib_nexthop_exm_prefix_length_25;
    bit<1>  fib_nexthop_type_exm_prefix_length_25;
    bit<1>  fib_hit_exm_prefix_length_24;
    bit<10> fib_nexthop_exm_prefix_length_24;
    bit<1>  fib_nexthop_type_exm_prefix_length_24;
    bit<1>  fib_hit_exm_prefix_length_23;
    bit<10> fib_nexthop_exm_prefix_length_23;
    bit<1>  fib_nexthop_type_exm_prefix_length_23;
    bit<1>  fib_hit_lpm_prefix_range_22_to_0;
    bit<10> fib_nexthop_lpm_prefix_range_22_to_0;
    bit<1>  fib_nexthop_type_lpm_prefix_range_22_to_0;
}

struct ipv6_metadata_t {
    bit<128> lkp_ipv6_sa;
    bit<128> lkp_ipv6_da;
    bit<1>   ipv6_unicast_enabled;
    bit<2>   ipv6_urpf_mode;
    bit<1>   fib_hit_exm_prefix_length_128;
    bit<16>  fib_nexthop_exm_prefix_length_128;
    bit<1>   fib_nexthop_type_exm_prefix_length_128;
    bit<1>   fib_hit_lpm_prefix_range_127_to_65;
    bit<16>  fib_nexthop_lpm_prefix_range_127_to_65;
    bit<1>   fib_nexthop_type_lpm_prefix_range_127_to_65;
    bit<1>   fib_hit_exm_prefix_length_64;
    bit<16>  fib_nexthop_exm_prefix_length_64;
    bit<1>   fib_nexthop_type_exm_prefix_length_64;
    bit<1>   fib_hit_lpm_prefix_range_63_to_0;
    bit<16>  fib_nexthop_lpm_prefix_range_63_to_0;
    bit<1>   fib_nexthop_type_lpm_prefix_range_63_to_0;
}

struct l2_metadata_t {
    bit<3>  lkp_pkt_type;
    bit<48> lkp_mac_sa;
    bit<48> lkp_mac_da;
    bit<16> l2_nexthop;
    bit<1>  l2_nexthop_type;
    bit<1>  l2_redirect;
    bit<1>  l2_src_miss;
    bit<16> l2_src_move;
    bit<10> stp_group;
    bit<3>  stp_state;
    bit<16> bd_stats_idx;
}

struct l3_metadata_t {
    bit<2>  lkp_ip_type;
    bit<8>  lkp_ip_proto;
    bit<8>  lkp_ip_tc;
    bit<8>  lkp_ip_ttl;
    bit<10> rmac_group;
    bit<1>  rmac_hit;
    bit<2>  urpf_mode;
    bit<1>  urpf_hit;
    bit<1>  urpf_check_fail;
    bit<16> urpf_bd_group;
    bit<1>  fib_hit;
    bit<16> fib_nexthop;
    bit<1>  fib_nexthop_type;
}

struct multicast_metadata_t {
    bit<1>  outer_ipv4_mcast_key_type;
    bit<8>  outer_ipv4_mcast_key;
    bit<1>  outer_ipv6_mcast_key_type;
    bit<8>  outer_ipv6_mcast_key;
    bit<1>  outer_mcast_route_hit;
    bit<2>  outer_mcast_mode;
    bit<1>  ip_multicast;
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

struct security_metadata_t {
    bit<1> storm_control_color;
    bit<1> ipsg_enabled;
}

struct tunnel_metadata_t {
    bit<8>  ingress_tunnel_type;
    bit<24> tunnel_vni;
    bit<1>  mpls_enabled;
    bit<20> mpls_label;
    bit<3>  mpls_exp;
    bit<8>  mpls_ttl;
    bit<8>  egress_tunnel_type;
    bit<14> tunnel_index;
    bit<9>  tunnel_src_index;
    bit<9>  tunnel_smac_index;
    bit<14> tunnel_dst_index;
    bit<14> tunnel_dmac_index;
    bit<24> vnid;
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

@name("erspan_header_v1_t") header erspan_header_v1_t_0 {
    bit<4>  version;
    bit<12> vlan;
    bit<6>  priority;
    bit<10> span_id;
    bit<8>  direction;
    bit<8>  truncated;
}

@name("erspan_header_v2_t") header erspan_header_v2_t_0 {
    bit<4>  version;
    bit<12> vlan;
    bit<6>  priority;
    bit<10> span_id;
    bit<32> unknown7;
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
    bit<16> dstPort;
}

header fabric_header_control_t {
    bit<10> egressPort;
    bit<5>  egressQueue;
    bit<1>  pad;
    bit<1>  type_;
    bit<1>  dir;
    bit<1>  redirectToCpu;
    bit<1>  forwardingBypass;
    bit<1>  aclBypass;
    bit<3>  reserved;
}

header fabric_header_cpu_t {
    bit<11> reserved;
    bit<5>  egressQueue;
    bit<16> port;
}

header fabric_header_mirror_t {
    bit<16> rewriteIndex;
    bit<10> egressPort;
    bit<5>  egressQueue;
    bit<1>  pad;
}

header fabric_header_multicast_t {
    bit<1>  tunnelTerminate;
    bit<1>  routed;
    bit<1>  outerRouted;
    bit<5>  pad1;
    bit<8>  ingressTunnelType;
    bit<16> egressBd;
    bit<16> lkpMacType;
    bit<16> mcastGrpA;
    bit<16> mcastGrpB;
    bit<16> ingressRid;
    bit<16> l1ExclusionId;
    bit<9>  l2ExclusionId;
    bit<7>  pad2;
    bit<13> l1McastHash;
    bit<3>  pad3;
    bit<13> l2McastHash;
    bit<3>  pad4;
}

header fabric_header_unicast_t {
    bit<4>  headerCount;
    bit<1>  tunnelTerminate;
    bit<1>  routed;
    bit<1>  outerRouted;
    bit<1>  pad;
    bit<8>  ingressTunnelType;
    bit<16> egressBd;
    bit<16> lkpMacType;
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
    bit<8>  type_;
    bit<8>  code;
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
    bit<5> _pad1;
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
    bit<8>  reserved;
}

header roce_header_t {
    bit<320> ib_grh;
    bit<96>  ib_bth;
}

header roce_v2_header_t {
    bit<96> ib_bth;
}

header sflow_t {
    bit<32> version;
    bit<32> ipVersion;
    bit<32> ipAddress;
    bit<32> subAgentId;
    bit<32> seqNumber;
    bit<32> uptime;
    bit<32> numSamples;
}

header sflow_internal_ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header sflow_record_t {
    bit<20> enterprise;
    bit<12> format;
    bit<32> flowDataLength;
    bit<32> headerProtocol;
    bit<32> frameLength;
    bit<32> bytesRemoved;
    bit<32> headerSize;
}

header sflow_sample_t {
    bit<20> enterprise;
    bit<12> format;
    bit<32> sampleLength;
    bit<32> seqNumer;
    bit<8>  srcIdClass;
    bit<24> srcIdIndex;
    bit<32> samplingRate;
    bit<32> samplePool;
    bit<32> numDrops;
    bit<32> inputIfindex;
    bit<32> outputIfindex;
    bit<32> numFlowRecords;
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

header vlan_tag_3b_t {
    bit<3>  pcp;
    bit<1>  cfi;
    bit<4>  vid;
    bit<16> etherType;
}

header vlan_tag_5b_t {
    bit<3>  pcp;
    bit<1>  cfi;
    bit<20> vid;
    bit<16> etherType;
}

struct metadata {
    @name(".acl_metadata") 
    acl_metadata_t           acl_metadata;
    @name(".egress_metadata") 
    egress_metadata_t        egress_metadata;
    @name(".i_fabric_header") 
    fabric_header_internal_t i_fabric_header;
    @name(".ingress_metadata") 
    ingress_metadata_t       ingress_metadata;
    @name(".ipv4_metadata") 
    ipv4_metadata_t          ipv4_metadata;
    @name(".ipv6_metadata") 
    ipv6_metadata_t          ipv6_metadata;
    @name(".l2_metadata") 
    l2_metadata_t            l2_metadata;
    @name(".l3_metadata") 
    l3_metadata_t            l3_metadata;
    @name(".multicast_metadata") 
    multicast_metadata_t     multicast_metadata;
    @name(".nat_metadata") 
    nat_metadata_t           nat_metadata;
    @name(".nexthop_metadata") 
    nexthop_metadata_t       nexthop_metadata;
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
    @name(".erspan_v1_header") 
    erspan_header_v1_t_0                           erspan_v1_header;
    @name(".erspan_v2_header") 
    erspan_header_v2_t_0                           erspan_v2_header;
    @name(".ethernet") 
    ethernet_t                                     ethernet;
    @name(".fabric_header") 
    fabric_header_t                                fabric_header;
    @name(".fabric_header_control") 
    fabric_header_control_t                        fabric_header_control;
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
    @name(".inner_tcp") 
    tcp_t                                          inner_tcp;
    @name(".inner_udp") 
    udp_t                                          inner_udp;
    @name(".ipv4") 
    ipv4_t                                         ipv4;
    @name(".ipv6") 
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
    @name(".outer_ipv4") 
    ipv4_t                                         outer_ipv4;
    @name(".outer_ipv6") 
    ipv6_t                                         outer_ipv6;
    @name(".outer_udp") 
    udp_t                                          outer_udp;
    @name(".roce") 
    roce_header_t                                  roce;
    @name(".roce_v2") 
    roce_v2_header_t                               roce_v2;
    @name(".sctp") 
    sctp_t                                         sctp;
    @name(".sflow") 
    sflow_t                                        sflow;
    @name(".sflow_internal_ethernet") 
    sflow_internal_ethernet_t                      sflow_internal_ethernet;
    @name(".sflow_record") 
    sflow_record_t                                 sflow_record;
    @name(".sflow_sample") 
    sflow_sample_t                                 sflow_sample;
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
    @name(".vlan_tag_3b") 
    vlan_tag_3b_t[2]                               vlan_tag_3b;
    @name(".vlan_tag_5b") 
    vlan_tag_5b_t[2]                               vlan_tag_5b;
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
    @name(".parse_bf_internal_sflow") state parse_bf_internal_sflow {
        packet.extract<sflow_internal_ethernet_t>(hdr.sflow_internal_ethernet);
        packet.extract<sflow_sample_t>(hdr.sflow_sample);
        packet.extract<sflow_record_t>(hdr.sflow_record);
        transition accept;
    }
    @name(".parse_bfd") state parse_bfd {
        packet.extract<bfd_t>(hdr.bfd);
        transition parse_set_prio_max;
    }
    @name(".parse_eompls") state parse_eompls {
        meta.tunnel_metadata.ingress_tunnel_type = 8w5;
        transition parse_inner_ethernet;
    }
    @name(".parse_erspan_v1") state parse_erspan_v1 {
        packet.extract<erspan_header_v1_t_0>(hdr.erspan_v1_header);
        transition accept;
    }
    @name(".parse_erspan_v2") state parse_erspan_v2 {
        packet.extract<erspan_header_v2_t_0>(hdr.erspan_v2_header);
        transition accept;
    }
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0 &&& 16w0xfe00: parse_llc_header;
            16w0 &&& 16w0xfa00: parse_llc_header;
            16w0x9000: parse_fabric_header;
            16w0x8100: parse_vlan;
            16w0x9100: parse_vlan;
            16w0x8847: parse_mpls;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            16w0x806: parse_arp_rarp;
            16w0x8035: parse_arp_rarp;
            16w0x8915: parse_roce;
            16w0x8906: parse_fcoe;
            16w0x8926: parse_vntag;
            16w0x88cc: parse_set_prio_high;
            16w0x8809: parse_set_prio_high;
            default: accept;
        }
    }
    @name(".parse_external_fabric_header") state parse_external_fabric_header {
        packet.extract<fabric_header_t>(hdr.fabric_header);
        transition select(hdr.fabric_header.packetType) {
            3w2: parse_fabric_header_unicast;
            3w3: parse_fabric_header_multicast;
            3w4: parse_fabric_header_mirror;
            3w5: parse_fabric_header_control;
            3w6: parse_fabric_header_cpu;
            default: accept;
        }
    }
    @name(".parse_fabric_header") state parse_fabric_header {
        transition select((packet.lookahead<bit<3>>())[2:0]) {
            3w1: parse_internal_fabric_header;
            default: parse_external_fabric_header;
        }
    }
    @name(".parse_fabric_header_control") state parse_fabric_header_control {
        packet.extract<fabric_header_control_t>(hdr.fabric_header_control);
        transition parse_fabric_payload_header;
    }
    @name(".parse_fabric_header_cpu") state parse_fabric_header_cpu {
        packet.extract<fabric_header_cpu_t>(hdr.fabric_header_cpu);
        hdr.ig_intr_md_for_tm.ucast_egress_port = (bit<9>)hdr.fabric_header_cpu.port;
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
            16w0x9100: parse_vlan;
            16w0x8847: parse_mpls;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            16w0x806: parse_arp_rarp;
            16w0x8035: parse_arp_rarp;
            16w0x8915: parse_roce;
            16w0x8906: parse_fcoe;
            16w0x8926: parse_vntag;
            16w0x88cc: parse_set_prio_high;
            16w0x8809: parse_set_prio_high;
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
        meta.tunnel_metadata.ingress_tunnel_type = 8w3;
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
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x88be): parse_erspan_v1;
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x22eb): parse_erspan_v2;
            default: accept;
        }
    }
    @name(".parse_gre_ipv4") state parse_gre_ipv4 {
        meta.tunnel_metadata.ingress_tunnel_type = 8w2;
        transition parse_inner_ipv4;
    }
    @name(".parse_gre_ipv6") state parse_gre_ipv6 {
        meta.tunnel_metadata.ingress_tunnel_type = 8w2;
        transition parse_inner_ipv6;
    }
    @name(".parse_icmp") state parse_icmp {
        packet.extract<icmp_t>(hdr.icmp);
        meta.ingress_metadata.lkp_icmp_type = hdr.icmp.type_;
        meta.ingress_metadata.lkp_icmp_code = hdr.icmp.code;
        transition select(hdr.icmp.type_) {
            8w0x82 &&& 8w0xfe: parse_set_prio_med;
            8w0x84 &&& 8w0xfc: parse_set_prio_med;
            8w0x88: parse_set_prio_med;
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
        meta.ingress_metadata.lkp_inner_icmp_type = hdr.inner_icmp.type_;
        meta.ingress_metadata.lkp_inner_icmp_code = hdr.inner_icmp.code;
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
        meta.ingress_metadata.lkp_inner_l4_sport = hdr.inner_tcp.srcPort;
        meta.ingress_metadata.lkp_inner_l4_dport = hdr.inner_tcp.dstPort;
        transition accept;
    }
    @name(".parse_inner_udp") state parse_inner_udp {
        packet.extract<udp_t>(hdr.inner_udp);
        meta.ingress_metadata.lkp_inner_l4_sport = hdr.inner_udp.srcPort;
        meta.ingress_metadata.lkp_inner_l4_dport = hdr.inner_udp.dstPort;
        transition accept;
    }
    @name(".parse_internal_fabric_header") state parse_internal_fabric_header {
        transition accept;
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        meta.ingress_metadata.ipv4_dstaddr_24b = (bit<24>)hdr.ipv4.dstAddr;
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.ihl, hdr.ipv4.protocol) {
            (13w0x0, 4w0x5, 8w0x1): parse_icmp;
            (13w0x0, 4w0x5, 8w0x6): parse_tcp;
            (13w0x0, 4w0x5, 8w0x11): parse_udp;
            (13w0x0, 4w0x5, 8w0x2f): parse_gre;
            (13w0x0, 4w0x5, 8w0x4): parse_inner_ipv4;
            (13w0x0, 4w0x5, 8w0x29): parse_inner_ipv6;
            (13w0, 4w0, 8w2): parse_set_prio_med;
            (13w0, 4w0, 8w88): parse_set_prio_med;
            (13w0, 4w0, 8w89): parse_set_prio_med;
            (13w0, 4w0, 8w103): parse_set_prio_med;
            (13w0, 4w0, 8w112): parse_set_prio_med;
            default: accept;
        }
    }
    @name(".parse_ipv6") state parse_ipv6 {
        packet.extract<ipv6_t>(hdr.ipv6);
        meta.ipv6_metadata.lkp_ipv6_sa = hdr.ipv6.srcAddr;
        meta.ipv6_metadata.lkp_ipv6_da = hdr.ipv6.dstAddr;
        transition select(hdr.ipv6.nextHdr) {
            8w58: parse_icmp;
            8w6: parse_tcp;
            8w17: parse_udp;
            8w47: parse_gre;
            8w4: parse_inner_ipv4;
            8w41: parse_inner_ipv6;
            8w88: parse_set_prio_med;
            8w89: parse_set_prio_med;
            8w103: parse_set_prio_med;
            8w112: parse_set_prio_med;
            default: accept;
        }
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
        meta.tunnel_metadata.ingress_tunnel_type = 8w6;
        transition parse_inner_ipv4;
    }
    @name(".parse_mpls_inner_ipv6") state parse_mpls_inner_ipv6 {
        meta.tunnel_metadata.ingress_tunnel_type = 8w6;
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
        meta.tunnel_metadata.ingress_tunnel_type = 8w4;
        meta.tunnel_metadata.tunnel_vni = hdr.nvgre.tni;
        transition parse_inner_ethernet;
    }
    @name(".parse_pw") state parse_pw {
        transition accept;
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
        packet.extract<sflow_t>(hdr.sflow);
        transition accept;
    }
    @name(".parse_snap_header") state parse_snap_header {
        packet.extract<snap_header_t>(hdr.snap_header);
        transition select(hdr.snap_header.type_) {
            16w0x8100: parse_vlan;
            16w0x9100: parse_vlan;
            16w0x8847: parse_mpls;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            16w0x806: parse_arp_rarp;
            16w0x8035: parse_arp_rarp;
            16w0x8915: parse_roce;
            16w0x8906: parse_fcoe;
            16w0x8926: parse_vntag;
            16w0x88cc: parse_set_prio_high;
            16w0x8809: parse_set_prio_high;
            default: accept;
        }
    }
    @name(".parse_tcp") state parse_tcp {
        packet.extract<tcp_t>(hdr.tcp);
        meta.ingress_metadata.lkp_l4_sport = hdr.tcp.srcPort;
        meta.ingress_metadata.lkp_l4_dport = hdr.tcp.dstPort;
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
        meta.ingress_metadata.lkp_l4_sport = hdr.udp.srcPort;
        meta.ingress_metadata.lkp_l4_dport = hdr.udp.dstPort;
        transition select(hdr.udp.dstPort) {
            16w4789: parse_vxlan;
            16w6081: parse_geneve;
            16w4791: parse_roce_v2;
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
        packet.extract<vlan_tag_t>(hdr.vlan_tag_.next);
        transition select(hdr.vlan_tag_.last.etherType) {
            16w0x8100: parse_vlan;
            16w0x9100: parse_vlan;
            16w0x8847: parse_mpls;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            16w0x806: parse_arp_rarp;
            16w0x8035: parse_arp_rarp;
            16w0x8915: parse_roce;
            16w0x8906: parse_fcoe;
            16w0x8926: parse_vntag;
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
        meta.tunnel_metadata.ingress_tunnel_type = 8w1;
        meta.tunnel_metadata.tunnel_vni = hdr.vxlan.vni;
        transition parse_inner_ethernet;
    }
    @name(".start") state start {
        meta.ingress_metadata.drop_0 = 1w0;
        transition parse_ethernet;
    }
}

@name(".bd_action_profile") action_profile(32w16384) bd_action_profile;

@name(".ecmp_action_profile") action_selector(HashAlgorithm.crc16, 32w16384, 32w10) ecmp_action_profile;

@name(".lag_action_profile") action_selector(HashAlgorithm.crc16, 32w1024, 32w8) lag_action_profile;

control process_fabric_egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".cpu_tx_rewrite") action cpu_tx_rewrite() {
        hdr.ethernet.etherType = hdr.fabric_payload_header.etherType;
        hdr.fabric_header.setInvalid();
        hdr.fabric_header_cpu.setInvalid();
        hdr.fabric_payload_header.setInvalid();
        meta.egress_metadata.fabric_bypass = 1w1;
    }
    @name(".cpu_rx_rewrite") action cpu_rx_rewrite() {
        hdr.fabric_header.setValid();
        hdr.fabric_header_cpu.setValid();
        hdr.fabric_header.headerVersion = 2w0;
        hdr.fabric_header.packetVersion = 2w0;
        hdr.fabric_header.pad1 = 1w0;
        hdr.fabric_header.packetType = 3w6;
        hdr.fabric_header_cpu.port = (bit<16>)hdr.ig_intr_md.ingress_port;
        meta.egress_metadata.fabric_bypass = 1w1;
        hdr.fabric_payload_header.setValid();
        hdr.fabric_payload_header.etherType = hdr.ethernet.etherType;
        hdr.ethernet.etherType = 16w0x9000;
    }
    @name(".fabric_rewrite") table fabric_rewrite {
        actions = {
            nop();
            cpu_tx_rewrite();
            cpu_rx_rewrite();
            @defaultonly NoAction();
        }
        key = {
            hdr.eg_intr_md.egress_port : ternary @name("eg_intr_md.egress_port") ;
            hdr.ig_intr_md.ingress_port: ternary @name("ig_intr_md.ingress_port") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        fabric_rewrite.apply();
    }
}

control process_replication(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_vlan_decap(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".vlan_decap_nop") action vlan_decap_nop() {
        hdr.ethernet.etherType = meta.i_fabric_header.lkp_mac_type;
    }
    @name(".remove_vlan_single_tagged") action remove_vlan_single_tagged() {
        hdr.vlan_tag_[0].setInvalid();
        hdr.ethernet.etherType = meta.i_fabric_header.lkp_mac_type;
    }
    @name(".remove_vlan_double_tagged") action remove_vlan_double_tagged() {
        hdr.vlan_tag_[0].setInvalid();
        hdr.vlan_tag_[1].setInvalid();
        hdr.ethernet.etherType = meta.i_fabric_header.lkp_mac_type;
    }
    @name(".remove_vlan_qinq_tagged") action remove_vlan_qinq_tagged() {
        hdr.vlan_tag_[0].setInvalid();
        hdr.vlan_tag_[1].setInvalid();
        hdr.ethernet.etherType = meta.i_fabric_header.lkp_mac_type;
    }
    @name(".vlan_decap") table vlan_decap {
        actions = {
            vlan_decap_nop();
            remove_vlan_single_tagged();
            remove_vlan_double_tagged();
            remove_vlan_qinq_tagged();
            @defaultonly NoAction();
        }
        key = {
            meta.egress_metadata.drop_exception: exact @name("egress_metadata.drop_exception") ;
            hdr.vlan_tag_[0].isValid()         : exact @name("vlan_tag_[0].$valid$") ;
            hdr.vlan_tag_[1].isValid()         : exact @name("vlan_tag_[1].$valid$") ;
        }
        size = 256;
        default_action = NoAction();
    }
    apply {
        vlan_decap.apply();
    }
}

control process_tunnel_decap(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_egress_bd(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_egress_bd_properties") action set_egress_bd_properties(bit<2> nat_mode) {
        meta.nat_metadata.egress_nat_mode = nat_mode;
    }
    @name(".egress_bd_map") table egress_bd_map {
        actions = {
            nop();
            set_egress_bd_properties();
            @defaultonly NoAction();
        }
        key = {
            meta.i_fabric_header.egress_bd: exact @name("i_fabric_header.egress_bd") ;
        }
        size = 16384;
        default_action = NoAction();
    }
    apply {
        egress_bd_map.apply();
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
        meta.egress_metadata.bd = meta.i_fabric_header.egress_bd;
    }
    @name(".set_ipv4_unicast_rewrite") action set_ipv4_unicast_rewrite(bit<9> smac_idx, bit<48> dmac) {
        meta.egress_metadata.smac_idx = smac_idx;
        meta.egress_metadata.mac_da = dmac;
        meta.egress_metadata.routed = 1w1;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
        meta.egress_metadata.bd = meta.i_fabric_header.egress_bd;
    }
    @name(".rewrite") table rewrite {
        actions = {
            nop();
            set_l2_rewrite();
            set_ipv4_unicast_rewrite();
            @defaultonly NoAction();
        }
        key = {
            meta.i_fabric_header.nexthop_index: exact @name("i_fabric_header.nexthop_index") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        rewrite.apply();
    }
}

control process_mac_rewrite(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".rewrite_unicast_mac") action rewrite_unicast_mac(bit<48> smac) {
        hdr.ethernet.srcAddr = smac;
        hdr.ethernet.dstAddr = meta.egress_metadata.mac_da;
    }
    @name(".rewrite_multicast_mac") action rewrite_multicast_mac(bit<48> smac) {
        hdr.ethernet.srcAddr = smac;
        hdr.ethernet.dstAddr = 48w0x1005e000000;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
    }
    @name(".mac_rewrite") table mac_rewrite {
        actions = {
            nop();
            rewrite_unicast_mac();
            rewrite_multicast_mac();
            @defaultonly NoAction();
        }
        key = {
            meta.egress_metadata.smac_idx: exact @name("egress_metadata.smac_idx") ;
            hdr.ipv4.dstAddr             : ternary @name("ipv4.dstAddr") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.i_fabric_header.routed == 1w1) 
            mac_rewrite.apply();
    }
}

control process_tunnel_encap(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_mtu(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_vlan_xlate(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_egress_packet_vlan_tagged") action set_egress_packet_vlan_tagged(bit<12> vlan_id) {
        hdr.vlan_tag_[0].setValid();
        hdr.vlan_tag_[0].etherType = hdr.ethernet.etherType;
        hdr.vlan_tag_[0].vid = vlan_id;
        hdr.ethernet.etherType = 16w0x8100;
    }
    @name(".set_egress_packet_vlan_untagged") action set_egress_packet_vlan_untagged() {
    }
    @name(".egress_vlan_xlate") table egress_vlan_xlate {
        actions = {
            set_egress_packet_vlan_tagged();
            set_egress_packet_vlan_untagged();
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
    apply {
    }
}

control process_i_fabric_egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".process_fabric_egress") process_fabric_egress() process_fabric_egress_0;
    @name(".process_replication") process_replication() process_replication_0;
    @name(".process_vlan_decap") process_vlan_decap() process_vlan_decap_0;
    @name(".process_tunnel_decap") process_tunnel_decap() process_tunnel_decap_0;
    @name(".process_egress_bd") process_egress_bd() process_egress_bd_0;
    @name(".process_egress_nat") process_egress_nat() process_egress_nat_0;
    @name(".process_rewrite") process_rewrite() process_rewrite_0;
    @name(".process_mac_rewrite") process_mac_rewrite() process_mac_rewrite_0;
    @name(".process_tunnel_encap") process_tunnel_encap() process_tunnel_encap_0;
    @name(".process_mtu") process_mtu() process_mtu_0;
    @name(".process_vlan_xlate") process_vlan_xlate() process_vlan_xlate_0;
    @name(".process_egress_filter") process_egress_filter() process_egress_filter_0;
    @name(".process_egress_acl") process_egress_acl() process_egress_acl_0;
    @name(".process_i_fabric_egress") process_i_fabric_egress() process_i_fabric_egress_0;
    apply {
        if (meta.egress_metadata.egress_bypass == 1w0) {
            process_fabric_egress_0.apply(hdr, meta, standard_metadata);
            if (meta.egress_metadata.fabric_bypass == 1w0) {
                process_replication_0.apply(hdr, meta, standard_metadata);
                process_vlan_decap_0.apply(hdr, meta, standard_metadata);
                process_tunnel_decap_0.apply(hdr, meta, standard_metadata);
                process_egress_bd_0.apply(hdr, meta, standard_metadata);
                process_egress_nat_0.apply(hdr, meta, standard_metadata);
                process_rewrite_0.apply(hdr, meta, standard_metadata);
                process_mac_rewrite_0.apply(hdr, meta, standard_metadata);
                process_tunnel_encap_0.apply(hdr, meta, standard_metadata);
                process_mtu_0.apply(hdr, meta, standard_metadata);
                process_vlan_xlate_0.apply(hdr, meta, standard_metadata);
                process_egress_filter_0.apply(hdr, meta, standard_metadata);
                process_egress_acl_0.apply(hdr, meta, standard_metadata);
                process_i_fabric_egress_0.apply(hdr, meta, standard_metadata);
            }
        }
    }
}

control process_fabric_ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control validate_outer_ethernet_header(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".add_i_fabric_header") action add_i_fabric_header(bit<16> etherType) {
        meta.i_fabric_header.ingress_tunnel_type = meta.tunnel_metadata.ingress_tunnel_type;
        meta.i_fabric_header.lkp_mac_type = etherType;
    }
    @name(".set_valid_outer_unicast_packet_untagged") action set_valid_outer_unicast_packet_untagged() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w511;
        add_i_fabric_header(hdr.ethernet.etherType);
    }
    @name(".set_valid_outer_unicast_packet_single_tagged") action set_valid_outer_unicast_packet_single_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w511;
        add_i_fabric_header(hdr.vlan_tag_[0].etherType);
    }
    @name(".set_valid_outer_unicast_packet_double_tagged") action set_valid_outer_unicast_packet_double_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w511;
        add_i_fabric_header(hdr.vlan_tag_[1].etherType);
    }
    @name(".set_valid_outer_unicast_packet_qinq_tagged") action set_valid_outer_unicast_packet_qinq_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w511;
        add_i_fabric_header(hdr.ethernet.etherType);
    }
    @name(".set_valid_outer_multicast_packet_untagged") action set_valid_outer_multicast_packet_untagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w511;
        add_i_fabric_header(hdr.ethernet.etherType);
    }
    @name(".set_valid_outer_multicast_packet_single_tagged") action set_valid_outer_multicast_packet_single_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w511;
        add_i_fabric_header(hdr.vlan_tag_[0].etherType);
    }
    @name(".set_valid_outer_multicast_packet_double_tagged") action set_valid_outer_multicast_packet_double_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w511;
        add_i_fabric_header(hdr.vlan_tag_[1].etherType);
    }
    @name(".set_valid_outer_multicast_packet_qinq_tagged") action set_valid_outer_multicast_packet_qinq_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w511;
        add_i_fabric_header(hdr.ethernet.etherType);
    }
    @name(".set_valid_outer_broadcast_packet_untagged") action set_valid_outer_broadcast_packet_untagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w511;
        add_i_fabric_header(hdr.ethernet.etherType);
    }
    @name(".set_valid_outer_broadcast_packet_single_tagged") action set_valid_outer_broadcast_packet_single_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w511;
        add_i_fabric_header(hdr.vlan_tag_[0].etherType);
    }
    @name(".set_valid_outer_broadcast_packet_double_tagged") action set_valid_outer_broadcast_packet_double_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w511;
        add_i_fabric_header(hdr.vlan_tag_[1].etherType);
    }
    @name(".set_valid_outer_broadcast_packet_qinq_tagged") action set_valid_outer_broadcast_packet_qinq_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w511;
        add_i_fabric_header(hdr.ethernet.etherType);
    }
    @name(".validate_outer_ethernet") table validate_outer_ethernet {
        actions = {
            set_valid_outer_unicast_packet_untagged();
            set_valid_outer_unicast_packet_single_tagged();
            set_valid_outer_unicast_packet_double_tagged();
            set_valid_outer_unicast_packet_qinq_tagged();
            set_valid_outer_multicast_packet_untagged();
            set_valid_outer_multicast_packet_single_tagged();
            set_valid_outer_multicast_packet_double_tagged();
            set_valid_outer_multicast_packet_qinq_tagged();
            set_valid_outer_broadcast_packet_untagged();
            set_valid_outer_broadcast_packet_single_tagged();
            set_valid_outer_broadcast_packet_double_tagged();
            set_valid_outer_broadcast_packet_qinq_tagged();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.dstAddr      : ternary @name("ethernet.dstAddr") ;
            hdr.vlan_tag_[0].isValid(): exact @name("vlan_tag_[0].$valid$") ;
            hdr.vlan_tag_[1].isValid(): exact @name("vlan_tag_[1].$valid$") ;
        }
        size = 64;
        default_action = NoAction();
    }
    apply {
        validate_outer_ethernet.apply();
    }
}

control validate_outer_ipv4_header(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_valid_outer_ipv4_packet") action set_valid_outer_ipv4_packet() {
        meta.l3_metadata.lkp_ip_type = 2w1;
        meta.ipv4_metadata.lkp_ipv4_sa = hdr.ipv4.srcAddr;
        meta.ipv4_metadata.lkp_ipv4_da = hdr.ipv4.dstAddr;
        meta.l3_metadata.lkp_ip_proto = hdr.ipv4.protocol;
        meta.l3_metadata.lkp_ip_tc = hdr.ipv4.diffserv;
        meta.l3_metadata.lkp_ip_ttl = hdr.ipv4.ttl;
    }
    @name(".set_malformed_outer_ipv4_packet") action set_malformed_outer_ipv4_packet() {
    }
    @name(".validate_outer_ipv4_packet") table validate_outer_ipv4_packet {
        actions = {
            set_valid_outer_ipv4_packet();
            set_malformed_outer_ipv4_packet();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.version: exact @name("ipv4.version") ;
            hdr.ipv4.ihl    : exact @name("ipv4.ihl") ;
            hdr.ipv4.ttl    : exact @name("ipv4.ttl") ;
            hdr.ipv4.srcAddr: ternary @name("ipv4.srcAddr") ;
            hdr.ipv4.dstAddr: ternary @name("ipv4.dstAddr") ;
        }
        size = 64;
        default_action = NoAction();
    }
    apply {
        validate_outer_ipv4_packet.apply();
    }
}

control validate_outer_ipv6_header(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control validate_mpls_header(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_port_mapping(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_ifindex") action set_ifindex(bit<16> ifindex, bit<16> if_label, bit<9> exclusion_id) {
        meta.ingress_metadata.ifindex = ifindex;
        hdr.ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
        meta.ingress_metadata.if_label = if_label;
    }
    @name(".port_mapping") table port_mapping {
        actions = {
            set_ifindex();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 288;
        default_action = NoAction();
    }
    apply {
        port_mapping.apply();
    }
}

control process_storm_control(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_port_vlan_mapping(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_bd") action set_bd(bit<16> bd, bit<2> vrf, bit<10> rmac_group, bit<16> bd_label, bit<16> uuc_mc_index, bit<16> bcast_mc_index, bit<16> umc_mc_index, bit<1> ipv4_unicast_enabled, bit<1> igmp_snooping_enabled, bit<10> stp_group, bit<16> exclusion_id, bit<16> stats_idx) {
        meta.ingress_metadata.vrf = vrf;
        meta.ipv4_metadata.ipv4_unicast_enabled = ipv4_unicast_enabled;
        meta.multicast_metadata.igmp_snooping_enabled = igmp_snooping_enabled;
        meta.l3_metadata.rmac_group = rmac_group;
        meta.ingress_metadata.uuc_mc_index = uuc_mc_index;
        meta.ingress_metadata.umc_mc_index = umc_mc_index;
        meta.ingress_metadata.bcast_mc_index = bcast_mc_index;
        meta.ingress_metadata.bd_label = bd_label;
        meta.ingress_metadata.bd = bd;
        meta.ingress_metadata.outer_bd = bd;
        meta.l2_metadata.stp_group = stp_group;
        hdr.ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        meta.l2_metadata.bd_stats_idx = stats_idx;
    }
    @name(".set_bd_ipv4_mcast_switch_ipv6_mcast_switch_flags") action set_bd_ipv4_mcast_switch_ipv6_mcast_switch_flags(bit<16> bd, bit<2> vrf, bit<10> rmac_group, bit<16> mrpf_group, bit<16> bd_label, bit<16> uuc_mc_index, bit<16> bcast_mc_index, bit<16> umc_mc_index, bit<1> ipv4_unicast_enabled, bit<1> ipv6_unicast_enabled, bit<2> ipv4_multicast_mode, bit<2> ipv6_multicast_mode, bit<1> igmp_snooping_enabled, bit<1> mld_snooping_enabled, bit<2> ipv4_urpf_mode, bit<2> ipv6_urpf_mode, bit<10> stp_group, bit<16> exclusion_id, bit<16> stats_idx) {
        meta.ingress_metadata.vrf = vrf;
        meta.ingress_metadata.bd = bd;
        meta.ingress_metadata.outer_bd = bd;
        meta.multicast_metadata.outer_ipv4_mcast_key_type = 1w0;
        meta.multicast_metadata.outer_ipv4_mcast_key = (bit<8>)bd;
        meta.multicast_metadata.outer_ipv6_mcast_key_type = 1w0;
        meta.multicast_metadata.outer_ipv6_mcast_key = (bit<8>)bd;
        meta.ipv4_metadata.ipv4_unicast_enabled = ipv4_unicast_enabled;
        meta.ipv6_metadata.ipv6_unicast_enabled = ipv6_unicast_enabled;
        meta.multicast_metadata.ipv4_multicast_mode = ipv4_multicast_mode;
        meta.multicast_metadata.ipv6_multicast_mode = ipv6_multicast_mode;
        meta.multicast_metadata.igmp_snooping_enabled = igmp_snooping_enabled;
        meta.multicast_metadata.mld_snooping_enabled = mld_snooping_enabled;
        meta.ipv4_metadata.ipv4_urpf_mode = ipv4_urpf_mode;
        meta.ipv6_metadata.ipv6_urpf_mode = ipv6_urpf_mode;
        meta.l3_metadata.rmac_group = rmac_group;
        meta.multicast_metadata.bd_mrpf_group = mrpf_group;
        meta.ingress_metadata.uuc_mc_index = uuc_mc_index;
        meta.ingress_metadata.umc_mc_index = umc_mc_index;
        meta.ingress_metadata.bcast_mc_index = bcast_mc_index;
        meta.ingress_metadata.bd_label = bd_label;
        meta.l2_metadata.stp_group = stp_group;
        hdr.ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        meta.l2_metadata.bd_stats_idx = stats_idx;
    }
    @name(".set_bd_ipv4_mcast_switch_ipv6_mcast_route_flags") action set_bd_ipv4_mcast_switch_ipv6_mcast_route_flags(bit<16> bd, bit<8> vrf, bit<10> rmac_group, bit<16> mrpf_group, bit<16> bd_label, bit<16> uuc_mc_index, bit<16> bcast_mc_index, bit<16> umc_mc_index, bit<1> ipv4_unicast_enabled, bit<1> ipv6_unicast_enabled, bit<2> ipv4_multicast_mode, bit<2> ipv6_multicast_mode, bit<1> igmp_snooping_enabled, bit<1> mld_snooping_enabled, bit<2> ipv4_urpf_mode, bit<2> ipv6_urpf_mode, bit<10> stp_group, bit<16> exclusion_id, bit<16> stats_idx) {
        meta.ingress_metadata.vrf = (bit<2>)vrf;
        meta.ingress_metadata.bd = bd;
        meta.ingress_metadata.outer_bd = bd;
        meta.multicast_metadata.outer_ipv4_mcast_key_type = 1w0;
        meta.multicast_metadata.outer_ipv4_mcast_key = (bit<8>)bd;
        meta.multicast_metadata.outer_ipv6_mcast_key_type = 1w1;
        meta.multicast_metadata.outer_ipv6_mcast_key = vrf;
        meta.ipv4_metadata.ipv4_unicast_enabled = ipv4_unicast_enabled;
        meta.ipv6_metadata.ipv6_unicast_enabled = ipv6_unicast_enabled;
        meta.multicast_metadata.ipv4_multicast_mode = ipv4_multicast_mode;
        meta.multicast_metadata.ipv6_multicast_mode = ipv6_multicast_mode;
        meta.multicast_metadata.igmp_snooping_enabled = igmp_snooping_enabled;
        meta.multicast_metadata.mld_snooping_enabled = mld_snooping_enabled;
        meta.ipv4_metadata.ipv4_urpf_mode = ipv4_urpf_mode;
        meta.ipv6_metadata.ipv6_urpf_mode = ipv6_urpf_mode;
        meta.l3_metadata.rmac_group = rmac_group;
        meta.multicast_metadata.bd_mrpf_group = mrpf_group;
        meta.ingress_metadata.uuc_mc_index = uuc_mc_index;
        meta.ingress_metadata.umc_mc_index = umc_mc_index;
        meta.ingress_metadata.bcast_mc_index = bcast_mc_index;
        meta.ingress_metadata.bd_label = bd_label;
        meta.l2_metadata.stp_group = stp_group;
        hdr.ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        meta.l2_metadata.bd_stats_idx = stats_idx;
    }
    @name(".set_bd_ipv4_mcast_route_ipv6_mcast_switch_flags") action set_bd_ipv4_mcast_route_ipv6_mcast_switch_flags(bit<16> bd, bit<8> vrf, bit<10> rmac_group, bit<16> mrpf_group, bit<16> bd_label, bit<16> uuc_mc_index, bit<16> bcast_mc_index, bit<16> umc_mc_index, bit<1> ipv4_unicast_enabled, bit<1> ipv6_unicast_enabled, bit<2> ipv4_multicast_mode, bit<2> ipv6_multicast_mode, bit<1> igmp_snooping_enabled, bit<1> mld_snooping_enabled, bit<2> ipv4_urpf_mode, bit<2> ipv6_urpf_mode, bit<10> stp_group, bit<16> exclusion_id, bit<16> stats_idx) {
        meta.ingress_metadata.vrf = (bit<2>)vrf;
        meta.ingress_metadata.bd = bd;
        meta.ingress_metadata.outer_bd = bd;
        meta.multicast_metadata.outer_ipv4_mcast_key_type = 1w1;
        meta.multicast_metadata.outer_ipv4_mcast_key = vrf;
        meta.multicast_metadata.outer_ipv6_mcast_key_type = 1w0;
        meta.multicast_metadata.outer_ipv6_mcast_key = (bit<8>)bd;
        meta.ipv4_metadata.ipv4_unicast_enabled = ipv4_unicast_enabled;
        meta.ipv6_metadata.ipv6_unicast_enabled = ipv6_unicast_enabled;
        meta.multicast_metadata.ipv4_multicast_mode = ipv4_multicast_mode;
        meta.multicast_metadata.ipv6_multicast_mode = ipv6_multicast_mode;
        meta.multicast_metadata.igmp_snooping_enabled = igmp_snooping_enabled;
        meta.multicast_metadata.mld_snooping_enabled = mld_snooping_enabled;
        meta.ipv4_metadata.ipv4_urpf_mode = ipv4_urpf_mode;
        meta.ipv6_metadata.ipv6_urpf_mode = ipv6_urpf_mode;
        meta.l3_metadata.rmac_group = rmac_group;
        meta.multicast_metadata.bd_mrpf_group = mrpf_group;
        meta.ingress_metadata.uuc_mc_index = uuc_mc_index;
        meta.ingress_metadata.umc_mc_index = umc_mc_index;
        meta.ingress_metadata.bcast_mc_index = bcast_mc_index;
        meta.ingress_metadata.bd_label = bd_label;
        meta.l2_metadata.stp_group = stp_group;
        hdr.ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        meta.l2_metadata.bd_stats_idx = stats_idx;
    }
    @name(".set_bd_ipv4_mcast_route_ipv6_mcast_route_flags") action set_bd_ipv4_mcast_route_ipv6_mcast_route_flags(bit<16> bd, bit<8> vrf, bit<10> rmac_group, bit<16> mrpf_group, bit<16> bd_label, bit<16> uuc_mc_index, bit<16> bcast_mc_index, bit<16> umc_mc_index, bit<1> ipv4_unicast_enabled, bit<1> ipv6_unicast_enabled, bit<2> ipv4_multicast_mode, bit<2> ipv6_multicast_mode, bit<1> igmp_snooping_enabled, bit<1> mld_snooping_enabled, bit<2> ipv4_urpf_mode, bit<2> ipv6_urpf_mode, bit<10> stp_group, bit<16> exclusion_id, bit<16> stats_idx) {
        meta.ingress_metadata.vrf = (bit<2>)vrf;
        meta.ingress_metadata.bd = bd;
        meta.ingress_metadata.outer_bd = bd;
        meta.multicast_metadata.outer_ipv4_mcast_key_type = 1w1;
        meta.multicast_metadata.outer_ipv4_mcast_key = vrf;
        meta.multicast_metadata.outer_ipv6_mcast_key_type = 1w1;
        meta.multicast_metadata.outer_ipv6_mcast_key = vrf;
        meta.ipv4_metadata.ipv4_unicast_enabled = ipv4_unicast_enabled;
        meta.ipv6_metadata.ipv6_unicast_enabled = ipv6_unicast_enabled;
        meta.multicast_metadata.ipv4_multicast_mode = ipv4_multicast_mode;
        meta.multicast_metadata.ipv6_multicast_mode = ipv6_multicast_mode;
        meta.multicast_metadata.igmp_snooping_enabled = igmp_snooping_enabled;
        meta.multicast_metadata.mld_snooping_enabled = mld_snooping_enabled;
        meta.ipv4_metadata.ipv4_urpf_mode = ipv4_urpf_mode;
        meta.ipv6_metadata.ipv6_urpf_mode = ipv6_urpf_mode;
        meta.l3_metadata.rmac_group = rmac_group;
        meta.multicast_metadata.bd_mrpf_group = mrpf_group;
        meta.ingress_metadata.uuc_mc_index = uuc_mc_index;
        meta.ingress_metadata.umc_mc_index = umc_mc_index;
        meta.ingress_metadata.bcast_mc_index = bcast_mc_index;
        meta.ingress_metadata.bd_label = bd_label;
        meta.l2_metadata.stp_group = stp_group;
        hdr.ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        meta.l2_metadata.bd_stats_idx = stats_idx;
    }
    @name(".port_vlan_mapping") table port_vlan_mapping {
        actions = {
            set_bd();
            set_bd_ipv4_mcast_switch_ipv6_mcast_switch_flags();
            set_bd_ipv4_mcast_switch_ipv6_mcast_route_flags();
            set_bd_ipv4_mcast_route_ipv6_mcast_switch_flags();
            set_bd_ipv4_mcast_route_ipv6_mcast_route_flags();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.ifindex: exact @name("ingress_metadata.ifindex") ;
            hdr.vlan_tag_[0].isValid()   : exact @name("vlan_tag_[0].$valid$") ;
            hdr.vlan_tag_[0].vid         : exact @name("vlan_tag_[0].vid") ;
            hdr.vlan_tag_[1].isValid()   : exact @name("vlan_tag_[1].$valid$") ;
            hdr.vlan_tag_[1].vid         : exact @name("vlan_tag_[1].vid") ;
        }
        size = 32768;
        implementation = bd_action_profile;
        default_action = NoAction();
    }
    apply {
        port_vlan_mapping.apply();
    }
}

control process_spanning_tree(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ip_sourceguard(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_validate_packet(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_unicast") action set_unicast() {
    }
    @name(".set_unicast_and_ipv6_src_is_link_local") action set_unicast_and_ipv6_src_is_link_local() {
        meta.ingress_metadata.src_is_link_local = 1w1;
    }
    @name(".set_multicast") action set_multicast() {
        meta.l2_metadata.bd_stats_idx = meta.l2_metadata.bd_stats_idx + 16w1;
    }
    @name(".set_ip_multicast") action set_ip_multicast() {
        meta.multicast_metadata.ip_multicast = 1w1;
        meta.l2_metadata.bd_stats_idx = meta.l2_metadata.bd_stats_idx + 16w1;
    }
    @name(".set_ip_multicast_and_ipv6_src_is_link_local") action set_ip_multicast_and_ipv6_src_is_link_local() {
        meta.multicast_metadata.ip_multicast = 1w1;
        meta.ingress_metadata.src_is_link_local = 1w1;
        meta.l2_metadata.bd_stats_idx = meta.l2_metadata.bd_stats_idx + 16w1;
    }
    @name(".set_broadcast") action set_broadcast() {
        meta.l2_metadata.bd_stats_idx = meta.l2_metadata.bd_stats_idx + 16w2;
    }
    @name(".validate_packet") table validate_packet {
        actions = {
            nop();
            set_unicast();
            set_unicast_and_ipv6_src_is_link_local();
            set_multicast();
            set_ip_multicast();
            set_ip_multicast_and_ipv6_src_is_link_local();
            set_broadcast();
            @defaultonly NoAction();
        }
        key = {
            meta.l2_metadata.lkp_mac_da: ternary @name("l2_metadata.lkp_mac_da") ;
        }
        size = 64;
        default_action = NoAction();
    }
    apply {
        validate_packet.apply();
    }
}

control process_mac(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_mac_acl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ip_acl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_qos(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ipv4_racl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_nat(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ipv4_urpf(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ipv4_fib(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".on_miss") action on_miss() {
    }
    @name(".fib_hit_exm_prefix_length_23_nexthop") action fib_hit_exm_prefix_length_23_nexthop(bit<10> nexthop_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_23 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_23 = nexthop_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_23 = 1w0;
    }
    @name(".fib_hit_exm_prefix_length_23_ecmp") action fib_hit_exm_prefix_length_23_ecmp(bit<10> ecmp_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_23 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_23 = ecmp_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_23 = 1w1;
    }
    @name(".fib_hit_exm_prefix_length_24_nexthop") action fib_hit_exm_prefix_length_24_nexthop(bit<10> nexthop_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_24 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_24 = nexthop_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_24 = 1w0;
    }
    @name(".fib_hit_exm_prefix_length_24_ecmp") action fib_hit_exm_prefix_length_24_ecmp(bit<10> ecmp_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_24 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_24 = ecmp_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_24 = 1w1;
    }
    @name(".fib_hit_exm_prefix_length_25_nexthop") action fib_hit_exm_prefix_length_25_nexthop(bit<10> nexthop_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_25 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_25 = nexthop_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_25 = 1w0;
    }
    @name(".fib_hit_exm_prefix_length_25_ecmp") action fib_hit_exm_prefix_length_25_ecmp(bit<10> ecmp_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_25 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_25 = ecmp_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_25 = 1w1;
    }
    @name(".fib_hit_exm_prefix_length_26_nexthop") action fib_hit_exm_prefix_length_26_nexthop(bit<10> nexthop_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_26 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_26 = nexthop_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_26 = 1w0;
    }
    @name(".fib_hit_exm_prefix_length_26_ecmp") action fib_hit_exm_prefix_length_26_ecmp(bit<10> ecmp_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_26 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_26 = ecmp_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_26 = 1w1;
    }
    @name(".fib_hit_exm_prefix_length_27_nexthop") action fib_hit_exm_prefix_length_27_nexthop(bit<10> nexthop_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_27 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_27 = nexthop_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_27 = 1w0;
    }
    @name(".fib_hit_exm_prefix_length_27_ecmp") action fib_hit_exm_prefix_length_27_ecmp(bit<10> ecmp_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_27 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_27 = ecmp_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_27 = 1w1;
    }
    @name(".fib_hit_exm_prefix_length_28_nexthop") action fib_hit_exm_prefix_length_28_nexthop(bit<10> nexthop_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_28 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_28 = nexthop_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_28 = 1w0;
    }
    @name(".fib_hit_exm_prefix_length_28_ecmp") action fib_hit_exm_prefix_length_28_ecmp(bit<10> ecmp_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_28 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_28 = ecmp_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_28 = 1w1;
    }
    @name(".fib_hit_exm_prefix_length_29_nexthop") action fib_hit_exm_prefix_length_29_nexthop(bit<10> nexthop_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_29 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_29 = nexthop_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_29 = 1w0;
    }
    @name(".fib_hit_exm_prefix_length_29_ecmp") action fib_hit_exm_prefix_length_29_ecmp(bit<10> ecmp_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_29 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_29 = ecmp_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_29 = 1w1;
    }
    @name(".fib_hit_exm_prefix_length_30_nexthop") action fib_hit_exm_prefix_length_30_nexthop(bit<10> nexthop_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_30 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_30 = nexthop_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_30 = 1w0;
    }
    @name(".fib_hit_exm_prefix_length_30_ecmp") action fib_hit_exm_prefix_length_30_ecmp(bit<10> ecmp_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_30 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_30 = ecmp_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_30 = 1w1;
    }
    @name(".fib_hit_exm_prefix_length_31_nexthop") action fib_hit_exm_prefix_length_31_nexthop(bit<10> nexthop_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_31 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_31 = nexthop_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_31 = 1w0;
    }
    @name(".fib_hit_exm_prefix_length_31_ecmp") action fib_hit_exm_prefix_length_31_ecmp(bit<10> ecmp_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_31 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_31 = ecmp_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_31 = 1w1;
    }
    @name(".fib_hit_exm_prefix_length_32_nexthop") action fib_hit_exm_prefix_length_32_nexthop(bit<10> nexthop_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_32 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_32 = nexthop_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_32 = 1w0;
    }
    @name(".fib_hit_exm_prefix_length_32_ecmp") action fib_hit_exm_prefix_length_32_ecmp(bit<10> ecmp_index) {
        meta.ipv4_metadata.fib_hit_exm_prefix_length_32 = 1w1;
        meta.ipv4_metadata.fib_nexthop_exm_prefix_length_32 = ecmp_index;
        meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_32 = 1w1;
    }
    @name(".fib_hit_lpm_prefix_range_22_to_0_nexthop") action fib_hit_lpm_prefix_range_22_to_0_nexthop(bit<10> nexthop_index) {
        meta.ipv4_metadata.fib_hit_lpm_prefix_range_22_to_0 = 1w1;
        meta.ipv4_metadata.fib_nexthop_lpm_prefix_range_22_to_0 = nexthop_index;
        meta.ipv4_metadata.fib_nexthop_type_lpm_prefix_range_22_to_0 = 1w0;
    }
    @name(".fib_hit_lpm_prefix_range_22_to_0_ecmp") action fib_hit_lpm_prefix_range_22_to_0_ecmp(bit<10> ecmp_index) {
        meta.ipv4_metadata.fib_hit_lpm_prefix_range_22_to_0 = 1w1;
        meta.ipv4_metadata.fib_nexthop_lpm_prefix_range_22_to_0 = ecmp_index;
        meta.ipv4_metadata.fib_nexthop_type_lpm_prefix_range_22_to_0 = 1w1;
    }
    @name(".ipv4_fib_exm_prefix_length_23") table ipv4_fib_exm_prefix_length_23 {
        actions = {
            on_miss();
            fib_hit_exm_prefix_length_23_nexthop();
            fib_hit_exm_prefix_length_23_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.vrf           : exact @name("ingress_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da[31:9]: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 30720;
        default_action = NoAction();
    }
    @name(".ipv4_fib_exm_prefix_length_24") table ipv4_fib_exm_prefix_length_24 {
        actions = {
            on_miss();
            fib_hit_exm_prefix_length_24_nexthop();
            fib_hit_exm_prefix_length_24_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.vrf           : exact @name("ingress_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da[31:8]: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 38400;
        default_action = NoAction();
    }
    @name(".ipv4_fib_exm_prefix_length_25") table ipv4_fib_exm_prefix_length_25 {
        actions = {
            on_miss();
            fib_hit_exm_prefix_length_25_nexthop();
            fib_hit_exm_prefix_length_25_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.vrf           : exact @name("ingress_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da[31:7]: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 3840;
        default_action = NoAction();
    }
    @name(".ipv4_fib_exm_prefix_length_26") table ipv4_fib_exm_prefix_length_26 {
        actions = {
            on_miss();
            fib_hit_exm_prefix_length_26_nexthop();
            fib_hit_exm_prefix_length_26_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.vrf           : exact @name("ingress_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da[31:6]: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 7680;
        default_action = NoAction();
    }
    @name(".ipv4_fib_exm_prefix_length_27") table ipv4_fib_exm_prefix_length_27 {
        actions = {
            on_miss();
            fib_hit_exm_prefix_length_27_nexthop();
            fib_hit_exm_prefix_length_27_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.vrf           : exact @name("ingress_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da[31:5]: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 7680;
        default_action = NoAction();
    }
    @name(".ipv4_fib_exm_prefix_length_28") table ipv4_fib_exm_prefix_length_28 {
        actions = {
            on_miss();
            fib_hit_exm_prefix_length_28_nexthop();
            fib_hit_exm_prefix_length_28_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.vrf           : exact @name("ingress_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da[31:4]: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 30720;
        default_action = NoAction();
    }
    @name(".ipv4_fib_exm_prefix_length_29") table ipv4_fib_exm_prefix_length_29 {
        actions = {
            on_miss();
            fib_hit_exm_prefix_length_29_nexthop();
            fib_hit_exm_prefix_length_29_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.vrf           : exact @name("ingress_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da[31:3]: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 15360;
        default_action = NoAction();
    }
    @name(".ipv4_fib_exm_prefix_length_30") table ipv4_fib_exm_prefix_length_30 {
        actions = {
            on_miss();
            fib_hit_exm_prefix_length_30_nexthop();
            fib_hit_exm_prefix_length_30_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.vrf           : exact @name("ingress_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da[31:2]: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 23040;
        default_action = NoAction();
    }
    @name(".ipv4_fib_exm_prefix_length_31") table ipv4_fib_exm_prefix_length_31 {
        actions = {
            on_miss();
            fib_hit_exm_prefix_length_31_nexthop();
            fib_hit_exm_prefix_length_31_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.vrf           : exact @name("ingress_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da[31:1]: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".ipv4_fib_exm_prefix_length_32") table ipv4_fib_exm_prefix_length_32 {
        actions = {
            on_miss();
            fib_hit_exm_prefix_length_32_nexthop();
            fib_hit_exm_prefix_length_32_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.vrf     : exact @name("ingress_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 19200;
        default_action = NoAction();
    }
    @name(".ipv4_fib_lpm_prefix_range_22_to_0") table ipv4_fib_lpm_prefix_range_22_to_0 {
        actions = {
            on_miss();
            fib_hit_lpm_prefix_range_22_to_0_nexthop();
            fib_hit_lpm_prefix_range_22_to_0_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.vrf     : exact @name("ingress_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da: lpm @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        ipv4_fib_exm_prefix_length_32.apply();
        ipv4_fib_exm_prefix_length_31.apply();
        ipv4_fib_exm_prefix_length_30.apply();
        ipv4_fib_exm_prefix_length_29.apply();
        ipv4_fib_exm_prefix_length_28.apply();
        ipv4_fib_exm_prefix_length_27.apply();
        ipv4_fib_exm_prefix_length_26.apply();
        ipv4_fib_exm_prefix_length_25.apply();
        ipv4_fib_exm_prefix_length_24.apply();
        ipv4_fib_exm_prefix_length_23.apply();
        ipv4_fib_lpm_prefix_range_22_to_0.apply();
    }
}

control process_ipv6_racl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ipv6_urpf(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ipv6_fib(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_urpf_bd(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_merge_results(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_l2_redirect_action") action set_l2_redirect_action() {
        meta.i_fabric_header.nexthop_index = meta.l2_metadata.l2_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.l2_metadata.l2_nexthop_type;
    }
    @name(".set_acl_redirect_action") action set_acl_redirect_action() {
        meta.i_fabric_header.nexthop_index = meta.acl_metadata.acl_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.acl_metadata.acl_nexthop_type;
    }
    @name(".set_racl_redirect_action") action set_racl_redirect_action() {
        meta.i_fabric_header.nexthop_index = meta.acl_metadata.racl_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.acl_metadata.racl_nexthop_type;
        meta.i_fabric_header.routed = 1w1;
    }
    @name(".set_fib_redirect_action") action set_fib_redirect_action() {
        meta.i_fabric_header.nexthop_index = meta.l3_metadata.fib_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.l3_metadata.fib_nexthop_type;
        meta.i_fabric_header.routed = 1w1;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".set_nat_redirect_action") action set_nat_redirect_action() {
        meta.i_fabric_header.nexthop_index = meta.nat_metadata.nat_nexthop;
        meta.nexthop_metadata.nexthop_type = 1w0;
        meta.i_fabric_header.routed = 1w1;
    }
    @name(".set_fib_exm_prefix_length_32_redirect_action") action set_fib_exm_prefix_length_32_redirect_action() {
        meta.nexthop_metadata.nexthop_type = meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_32;
        meta.i_fabric_header.routed = 1w1;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".set_fib_exm_prefix_length_31_redirect_action") action set_fib_exm_prefix_length_31_redirect_action() {
        meta.nexthop_metadata.nexthop_type = meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_31;
        meta.i_fabric_header.routed = 1w1;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".set_fib_exm_prefix_length_30_redirect_action") action set_fib_exm_prefix_length_30_redirect_action() {
        meta.nexthop_metadata.nexthop_type = meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_30;
        meta.i_fabric_header.routed = 1w1;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".set_fib_exm_prefix_length_29_redirect_action") action set_fib_exm_prefix_length_29_redirect_action() {
        meta.nexthop_metadata.nexthop_type = meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_29;
        meta.i_fabric_header.routed = 1w1;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".set_fib_exm_prefix_length_28_redirect_action") action set_fib_exm_prefix_length_28_redirect_action() {
        meta.nexthop_metadata.nexthop_type = meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_28;
        meta.i_fabric_header.routed = 1w1;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".set_fib_exm_prefix_length_27_redirect_action") action set_fib_exm_prefix_length_27_redirect_action() {
        meta.nexthop_metadata.nexthop_type = meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_27;
        meta.i_fabric_header.routed = 1w1;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".set_fib_exm_prefix_length_26_redirect_action") action set_fib_exm_prefix_length_26_redirect_action() {
        meta.nexthop_metadata.nexthop_type = meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_26;
        meta.i_fabric_header.routed = 1w1;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".set_fib_exm_prefix_length_25_redirect_action") action set_fib_exm_prefix_length_25_redirect_action() {
        meta.nexthop_metadata.nexthop_type = meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_25;
        meta.i_fabric_header.routed = 1w1;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".set_fib_exm_prefix_length_24_redirect_action") action set_fib_exm_prefix_length_24_redirect_action() {
        meta.nexthop_metadata.nexthop_type = meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_24;
        meta.i_fabric_header.routed = 1w1;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".set_fib_exm_prefix_length_23_redirect_action") action set_fib_exm_prefix_length_23_redirect_action() {
        meta.nexthop_metadata.nexthop_type = meta.ipv4_metadata.fib_nexthop_type_exm_prefix_length_23;
        meta.i_fabric_header.routed = 1w1;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".set_fib_lpm_prefix_range_22_to_0_redirect_action") action set_fib_lpm_prefix_range_22_to_0_redirect_action() {
        meta.nexthop_metadata.nexthop_type = meta.ipv4_metadata.fib_nexthop_type_lpm_prefix_range_22_to_0;
        meta.i_fabric_header.routed = 1w1;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".fwd_result") table fwd_result {
        actions = {
            nop();
            set_l2_redirect_action();
            set_acl_redirect_action();
            set_racl_redirect_action();
            set_fib_redirect_action();
            set_nat_redirect_action();
            set_fib_exm_prefix_length_32_redirect_action();
            set_fib_exm_prefix_length_31_redirect_action();
            set_fib_exm_prefix_length_30_redirect_action();
            set_fib_exm_prefix_length_29_redirect_action();
            set_fib_exm_prefix_length_28_redirect_action();
            set_fib_exm_prefix_length_27_redirect_action();
            set_fib_exm_prefix_length_26_redirect_action();
            set_fib_exm_prefix_length_25_redirect_action();
            set_fib_exm_prefix_length_24_redirect_action();
            set_fib_exm_prefix_length_23_redirect_action();
            set_fib_lpm_prefix_range_22_to_0_redirect_action();
            @defaultonly NoAction();
        }
        key = {
            meta.ipv4_metadata.fib_hit_exm_prefix_length_32    : ternary @name("ipv4_metadata.fib_hit_exm_prefix_length_32") ;
            meta.ipv4_metadata.fib_hit_exm_prefix_length_31    : ternary @name("ipv4_metadata.fib_hit_exm_prefix_length_31") ;
            meta.ipv4_metadata.fib_hit_exm_prefix_length_30    : ternary @name("ipv4_metadata.fib_hit_exm_prefix_length_30") ;
            meta.ipv4_metadata.fib_hit_exm_prefix_length_29    : ternary @name("ipv4_metadata.fib_hit_exm_prefix_length_29") ;
            meta.ipv4_metadata.fib_hit_exm_prefix_length_28    : ternary @name("ipv4_metadata.fib_hit_exm_prefix_length_28") ;
            meta.ipv4_metadata.fib_hit_exm_prefix_length_27    : ternary @name("ipv4_metadata.fib_hit_exm_prefix_length_27") ;
            meta.ipv4_metadata.fib_hit_exm_prefix_length_26    : ternary @name("ipv4_metadata.fib_hit_exm_prefix_length_26") ;
            meta.ipv4_metadata.fib_hit_exm_prefix_length_25    : ternary @name("ipv4_metadata.fib_hit_exm_prefix_length_25") ;
            meta.ipv4_metadata.fib_hit_exm_prefix_length_24    : ternary @name("ipv4_metadata.fib_hit_exm_prefix_length_24") ;
            meta.ipv4_metadata.fib_hit_exm_prefix_length_23    : ternary @name("ipv4_metadata.fib_hit_exm_prefix_length_23") ;
            meta.ipv4_metadata.fib_hit_lpm_prefix_range_22_to_0: ternary @name("ipv4_metadata.fib_hit_lpm_prefix_range_22_to_0") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        fwd_result.apply();
    }
}

control process_nexthop(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_ecmp_nexthop_details") action set_ecmp_nexthop_details(bit<16> ifindex, bit<16> bd, bit<16> nhop_index) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.i_fabric_header.egress_bd = bd;
        meta.i_fabric_header.nexthop_index = nhop_index;
        meta.ingress_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
    }
    @name(".set_ecmp_nexthop_details_for_post_routed_flood") action set_ecmp_nexthop_details_for_post_routed_flood(bit<16> bd, bit<16> uuc_mc_index, bit<16> nhop_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_b = uuc_mc_index;
        meta.i_fabric_header.egress_bd = bd;
        meta.i_fabric_header.nexthop_index = nhop_index;
        meta.ingress_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
    }
    @name(".set_nexthop_details") action set_nexthop_details(bit<16> ifindex, bit<16> bd) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.i_fabric_header.egress_bd = bd;
        meta.ingress_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
    }
    @name(".set_nexthop_details_for_post_routed_flood") action set_nexthop_details_for_post_routed_flood(bit<16> bd, bit<16> uuc_mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_b = uuc_mc_index;
        meta.i_fabric_header.egress_bd = bd;
        meta.ingress_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
    }
    @name(".ecmp_group") table ecmp_group {
        actions = {
            nop();
            set_ecmp_nexthop_details();
            set_ecmp_nexthop_details_for_post_routed_flood();
            @defaultonly NoAction();
        }
        key = {
            meta.i_fabric_header.nexthop_index: exact @name("i_fabric_header.nexthop_index") ;
            meta.ipv4_metadata.lkp_ipv4_sa    : selector @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da    : selector @name("ipv4_metadata.lkp_ipv4_da") ;
            meta.l3_metadata.lkp_ip_proto     : selector @name("l3_metadata.lkp_ip_proto") ;
            meta.ingress_metadata.lkp_l4_sport: selector @name("ingress_metadata.lkp_l4_sport") ;
            meta.ingress_metadata.lkp_l4_dport: selector @name("ingress_metadata.lkp_l4_dport") ;
        }
        size = 1024;
        implementation = ecmp_action_profile;
        default_action = NoAction();
    }
    @name(".nexthop") table nexthop {
        actions = {
            nop();
            set_nexthop_details();
            set_nexthop_details_for_post_routed_flood();
            @defaultonly NoAction();
        }
        key = {
            meta.i_fabric_header.nexthop_index: exact @name("i_fabric_header.nexthop_index") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        if (meta.nexthop_metadata.nexthop_type == 1w1) 
            ecmp_group.apply();
        else 
            nexthop.apply();
    }
}

control process_ingress_bd_stats(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".ingress_bd_stats") counter(32w16384, CounterType.packets_and_bytes) ingress_bd_stats;
    @name(".update_ingress_bd_stats") action update_ingress_bd_stats() {
        ingress_bd_stats.count((bit<32>)meta.l2_metadata.bd_stats_idx);
    }
    @name(".ingress_bd_stats") table ingress_bd_stats_0 {
        actions = {
            update_ingress_bd_stats();
            @defaultonly NoAction();
        }
        size = 64;
        default_action = NoAction();
    }
    apply {
        ingress_bd_stats_0.apply();
    }
}

control process_lag(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_lag_port") action set_lag_port(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".lag_group") table lag_group {
        actions = {
            nop();
            set_lag_port();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.egress_ifindex: exact @name("ingress_metadata.egress_ifindex") ;
            meta.l2_metadata.lkp_mac_sa         : selector @name("l2_metadata.lkp_mac_sa") ;
            meta.l2_metadata.lkp_mac_da         : selector @name("l2_metadata.lkp_mac_da") ;
            meta.i_fabric_header.lkp_mac_type   : selector @name("i_fabric_header.lkp_mac_type") ;
            meta.ipv4_metadata.lkp_ipv4_sa      : selector @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da      : selector @name("ipv4_metadata.lkp_ipv4_da") ;
            meta.l3_metadata.lkp_ip_proto       : selector @name("l3_metadata.lkp_ip_proto") ;
            meta.ingress_metadata.lkp_l4_sport  : selector @name("ingress_metadata.lkp_l4_sport") ;
            meta.ingress_metadata.lkp_l4_dport  : selector @name("ingress_metadata.lkp_l4_dport") ;
        }
        size = 1024;
        implementation = lag_action_profile;
        default_action = NoAction();
    }
    apply {
        lag_group.apply();
    }
}

control process_mac_learning(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_fabric_lag(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_system_acl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".redirect_to_cpu") action redirect_to_cpu() {
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w64;
        hdr.ig_intr_md_for_tm.mcast_grp_a = 16w0;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".copy_to_cpu") action copy_to_cpu() {
        clone(CloneType.I2E, 32w250);
    }
    @name(".drop_packet") action drop_packet() {
        mark_to_drop();
    }
    @name(".negative_mirror") action negative_mirror(bit<32> clone_spec, bit<8> drop_reason) {
        meta.ingress_metadata.drop_reason = drop_reason;
        clone3<tuple<bit<16>, bit<8>, bit<8>>>(CloneType.I2E, clone_spec, { meta.ingress_metadata.ifindex, meta.ingress_metadata.drop_reason, meta.l3_metadata.lkp_ip_ttl });
        mark_to_drop();
    }
    @name(".system_acl") table system_acl {
        actions = {
            nop();
            redirect_to_cpu();
            copy_to_cpu();
            drop_packet();
            negative_mirror();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.if_label         : ternary @name("ingress_metadata.if_label") ;
            meta.ingress_metadata.bd_label         : ternary @name("ingress_metadata.bd_label") ;
            meta.ipv4_metadata.lkp_ipv4_sa         : ternary @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da         : ternary @name("ipv4_metadata.lkp_ipv4_da") ;
            meta.l3_metadata.lkp_ip_proto          : ternary @name("l3_metadata.lkp_ip_proto") ;
            meta.l2_metadata.lkp_mac_sa            : ternary @name("l2_metadata.lkp_mac_sa") ;
            meta.l2_metadata.lkp_mac_da            : ternary @name("l2_metadata.lkp_mac_da") ;
            meta.i_fabric_header.lkp_mac_type      : ternary @name("i_fabric_header.lkp_mac_type") ;
            meta.ingress_metadata.ipsg_check_fail  : ternary @name("ingress_metadata.ipsg_check_fail") ;
            meta.acl_metadata.acl_deny             : ternary @name("acl_metadata.acl_deny") ;
            meta.acl_metadata.racl_deny            : ternary @name("acl_metadata.racl_deny") ;
            meta.l3_metadata.urpf_check_fail       : ternary @name("l3_metadata.urpf_check_fail") ;
            meta.i_fabric_header.routed            : ternary @name("i_fabric_header.routed") ;
            meta.ingress_metadata.src_is_link_local: ternary @name("ingress_metadata.src_is_link_local") ;
            meta.ingress_metadata.same_bd_check    : ternary @name("ingress_metadata.same_bd_check") ;
            meta.l3_metadata.lkp_ip_ttl            : ternary @name("l3_metadata.lkp_ip_ttl") ;
            meta.l2_metadata.stp_state             : ternary @name("l2_metadata.stp_state") ;
            meta.ingress_metadata.control_frame    : ternary @name("ingress_metadata.control_frame") ;
            meta.ipv4_metadata.ipv4_unicast_enabled: ternary @name("ipv4_metadata.ipv4_unicast_enabled") ;
            hdr.ig_intr_md_for_tm.ucast_egress_port: ternary @name("ig_intr_md_for_tm.ucast_egress_port") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        system_acl.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".rmac_hit") action rmac_hit() {
        meta.l3_metadata.rmac_hit = 1w1;
        meta.ingress_metadata.egress_ifindex = 16w64;
        hdr.ig_intr_md_for_tm.mcast_grp_a = 16w0;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".rmac_miss") action rmac_miss() {
        meta.l3_metadata.rmac_hit = 1w0;
    }
    @name(".rmac") table rmac {
        actions = {
            rmac_hit();
            rmac_miss();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.rmac_group: exact @name("l3_metadata.rmac_group") ;
            meta.l2_metadata.lkp_mac_da: exact @name("l2_metadata.lkp_mac_da") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".process_fabric_ingress") process_fabric_ingress() process_fabric_ingress_0;
    @name(".validate_outer_ethernet_header") validate_outer_ethernet_header() validate_outer_ethernet_header_0;
    @name(".validate_outer_ipv4_header") validate_outer_ipv4_header() validate_outer_ipv4_header_0;
    @name(".validate_outer_ipv6_header") validate_outer_ipv6_header() validate_outer_ipv6_header_0;
    @name(".validate_mpls_header") validate_mpls_header() validate_mpls_header_0;
    @name(".process_port_mapping") process_port_mapping() process_port_mapping_0;
    @name(".process_storm_control") process_storm_control() process_storm_control_0;
    @name(".process_port_vlan_mapping") process_port_vlan_mapping() process_port_vlan_mapping_0;
    @name(".process_spanning_tree") process_spanning_tree() process_spanning_tree_0;
    @name(".process_ip_sourceguard") process_ip_sourceguard() process_ip_sourceguard_0;
    @name(".process_validate_packet") process_validate_packet() process_validate_packet_0;
    @name(".process_mac") process_mac() process_mac_0;
    @name(".process_mac_acl") process_mac_acl() process_mac_acl_0;
    @name(".process_ip_acl") process_ip_acl() process_ip_acl_0;
    @name(".process_qos") process_qos() process_qos_0;
    @name(".process_multicast") process_multicast() process_multicast_0;
    @name(".process_ipv4_racl") process_ipv4_racl() process_ipv4_racl_0;
    @name(".process_nat") process_nat() process_nat_0;
    @name(".process_ipv4_urpf") process_ipv4_urpf() process_ipv4_urpf_0;
    @name(".process_ipv4_fib") process_ipv4_fib() process_ipv4_fib_0;
    @name(".process_ipv6_racl") process_ipv6_racl() process_ipv6_racl_0;
    @name(".process_ipv6_urpf") process_ipv6_urpf() process_ipv6_urpf_0;
    @name(".process_ipv6_fib") process_ipv6_fib() process_ipv6_fib_0;
    @name(".process_urpf_bd") process_urpf_bd() process_urpf_bd_0;
    @name(".process_merge_results") process_merge_results() process_merge_results_0;
    @name(".process_nexthop") process_nexthop() process_nexthop_0;
    @name(".process_ingress_bd_stats") process_ingress_bd_stats() process_ingress_bd_stats_0;
    @name(".process_lag") process_lag() process_lag_0;
    @name(".process_mac_learning") process_mac_learning() process_mac_learning_0;
    @name(".process_fabric_lag") process_fabric_lag() process_fabric_lag_0;
    @name(".process_system_acl") process_system_acl() process_system_acl_0;
    apply {
        if (hdr.fabric_header.isValid()) 
            process_fabric_ingress_0.apply(hdr, meta, standard_metadata);
        else {
            validate_outer_ethernet_header_0.apply(hdr, meta, standard_metadata);
            if (hdr.ipv4.isValid()) 
                validate_outer_ipv4_header_0.apply(hdr, meta, standard_metadata);
            else 
                if (hdr.ipv6.isValid()) 
                    validate_outer_ipv6_header_0.apply(hdr, meta, standard_metadata);
            if (hdr.mpls[0].isValid()) 
                validate_mpls_header_0.apply(hdr, meta, standard_metadata);
            process_port_mapping_0.apply(hdr, meta, standard_metadata);
            process_storm_control_0.apply(hdr, meta, standard_metadata);
            process_port_vlan_mapping_0.apply(hdr, meta, standard_metadata);
            process_spanning_tree_0.apply(hdr, meta, standard_metadata);
            process_ip_sourceguard_0.apply(hdr, meta, standard_metadata);
            process_validate_packet_0.apply(hdr, meta, standard_metadata);
            process_mac_0.apply(hdr, meta, standard_metadata);
            if (meta.l3_metadata.lkp_ip_type == 2w0) 
                process_mac_acl_0.apply(hdr, meta, standard_metadata);
            else 
                process_ip_acl_0.apply(hdr, meta, standard_metadata);
            process_qos_0.apply(hdr, meta, standard_metadata);
            switch (rmac.apply().action_run) {
                rmac_miss: {
                    process_multicast_0.apply(hdr, meta, standard_metadata);
                }
                default: {
                    if (meta.l3_metadata.lkp_ip_type == 2w1 && meta.ipv4_metadata.ipv4_unicast_enabled == 1w1) {
                        process_ipv4_racl_0.apply(hdr, meta, standard_metadata);
                        process_nat_0.apply(hdr, meta, standard_metadata);
                        process_ipv4_urpf_0.apply(hdr, meta, standard_metadata);
                        process_ipv4_fib_0.apply(hdr, meta, standard_metadata);
                    }
                    else 
                        if (meta.l3_metadata.lkp_ip_type == 2w2 && meta.ipv6_metadata.ipv6_unicast_enabled == 1w1) {
                            process_ipv6_racl_0.apply(hdr, meta, standard_metadata);
                            process_ipv6_urpf_0.apply(hdr, meta, standard_metadata);
                            process_ipv6_fib_0.apply(hdr, meta, standard_metadata);
                        }
                    process_urpf_bd_0.apply(hdr, meta, standard_metadata);
                }
            }

            process_merge_results_0.apply(hdr, meta, standard_metadata);
            process_nexthop_0.apply(hdr, meta, standard_metadata);
            process_ingress_bd_stats_0.apply(hdr, meta, standard_metadata);
            process_lag_0.apply(hdr, meta, standard_metadata);
            process_mac_learning_0.apply(hdr, meta, standard_metadata);
        }
        process_fabric_lag_0.apply(hdr, meta, standard_metadata);
        process_system_acl_0.apply(hdr, meta, standard_metadata);
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<fabric_header_t>(hdr.fabric_header);
        packet.emit<fabric_header_cpu_t>(hdr.fabric_header_cpu);
        packet.emit<fabric_header_control_t>(hdr.fabric_header_control);
        packet.emit<fabric_header_mirror_t>(hdr.fabric_header_mirror);
        packet.emit<fabric_header_multicast_t>(hdr.fabric_header_multicast);
        packet.emit<fabric_header_unicast_t>(hdr.fabric_header_unicast);
        packet.emit<fabric_payload_header_t>(hdr.fabric_payload_header);
        packet.emit<llc_header_t>(hdr.llc_header);
        packet.emit<snap_header_t>(hdr.snap_header);
        packet.emit<vlan_tag_t[2]>(hdr.vlan_tag_);
        packet.emit<vntag_t>(hdr.vntag);
        packet.emit<fcoe_header_t>(hdr.fcoe);
        packet.emit<roce_header_t>(hdr.roce);
        packet.emit<arp_rarp_t>(hdr.arp_rarp);
        packet.emit<arp_rarp_ipv4_t>(hdr.arp_rarp_ipv4);
        packet.emit<ipv6_t>(hdr.ipv6);
        packet.emit<ipv4_t>(hdr.ipv4);
        packet.emit<gre_t>(hdr.gre);
        packet.emit<erspan_header_v2_t_0>(hdr.erspan_v2_header);
        packet.emit<erspan_header_v1_t_0>(hdr.erspan_v1_header);
        packet.emit<nvgre_t>(hdr.nvgre);
        packet.emit<udp_t>(hdr.udp);
        packet.emit<roce_v2_header_t>(hdr.roce_v2);
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

