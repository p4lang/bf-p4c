#include <core.p4>
#include <v1model.p4>

struct acl_metadata_t {
    bit<1>  acl_deny;
    bit<1>  racl_deny;
    bit<16> acl_nexthop;
    bit<16> racl_nexthop;
    bit<2>  acl_nexthop_type;
    bit<2>  racl_nexthop_type;
    bit<1>  acl_redirect;
    bit<1>  racl_redirect;
    bit<16> if_label;
    bit<16> bd_label;
    bit<14> acl_stats_index;
    bit<16> acl_partition_index;
    bit<16> egress_if_label;
    bit<16> egress_bd_label;
    bit<8>  ingress_src_port_range_id;
    bit<8>  ingress_dst_port_range_id;
    bit<8>  egress_src_port_range_id;
    bit<8>  egress_dst_port_range_id;
}

struct egress_metadata_t {
    bit<1>  bypass;
    bit<2>  port_type;
    bit<16> payload_length;
    bit<9>  smac_idx;
    bit<14> bd;
    bit<14> outer_bd;
    bit<48> mac_da;
    bit<1>  routed;
    bit<14> same_bd_check;
    bit<8>  drop_reason;
    bit<16> ifindex;
}

struct fabric_metadata_t {
    bit<3>  packetType;
    bit<1>  fabric_header_present;
    bit<16> reason_code;
}

struct flowlet_metadata_t {
    bit<16> id;
    bit<32> inactive_timeout;
}

struct global_config_metadata_t {
    bit<1>  enable_dod;
    bit<32> switch_id;
}

struct hash_metadata_t {
    bit<16> hash1;
    bit<16> hash2;
    bit<16> entropy_hash;
}

struct i2e_metadata_t {
    bit<32> ingress_tstamp;
    bit<32> mirror_session_id;
}

@pa_alias("ingress", "ig_intr_md.ingress_port", "ingress_metadata.ingress_port") struct ingress_metadata_t {
    bit<9>  ingress_port;
    bit<16> ifindex;
    bit<16> egress_ifindex;
    bit<2>  port_type;
    bit<14> outer_bd;
    bit<14> bd;
    bit<1>  drop_flag;
    bit<8>  drop_reason;
    bit<1>  control_frame;
    bit<32> sflow_take_sample;
    bit<16> bypass_lookups;
}

struct intrinsic_metadata_t {
    bit<16> mcast_grp;
    bit<32> lf_field_list;
    bit<16> egress_rid;
    bit<32> ingress_global_timestamp;
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
    bit<48> lkp_mac_sa;
    bit<48> lkp_mac_da;
    bit<3>  lkp_pkt_type;
    bit<16> lkp_mac_type;
    bit<3>  lkp_pcp;
    bit<1>  non_ip_packet;
    bit<16> l2_nexthop;
    bit<2>  l2_nexthop_type;
    bit<1>  l2_redirect;
    bit<1>  l2_src_miss;
    bit<16> l2_src_move;
    bit<10> stp_group;
    bit<3>  stp_state;
    bit<16> bd_stats_idx;
    bit<1>  learning_enabled;
    bit<1>  port_vlan_mapping_miss;
    bit<16> same_if_check;
}

struct l3_metadata_t {
    bit<2>  lkp_ip_type;
    bit<4>  lkp_ip_version;
    bit<8>  lkp_ip_proto;
    bit<8>  lkp_dscp;
    bit<8>  lkp_ip_ttl;
    bit<16> lkp_l4_sport;
    bit<16> lkp_l4_dport;
    bit<16> lkp_outer_l4_sport;
    bit<16> lkp_outer_l4_dport;
    bit<14> vrf;
    bit<10> rmac_group;
    bit<1>  rmac_hit;
    bit<2>  urpf_mode;
    bit<1>  urpf_hit;
    bit<1>  urpf_check_fail;
    bit<14> urpf_bd_group;
    bit<1>  fib_hit;
    bit<16> fib_nexthop;
    bit<2>  fib_nexthop_type;
    bit<12> fib_partition_index;
    bit<14> same_bd_check;
    bit<16> nexthop_index;
    bit<1>  routed;
    bit<1>  outer_routed;
    bit<8>  mtu_index;
    bit<1>  l3_copy;
    bit<16> l3_mtu_check;
    bit<16> egress_l4_sport;
    bit<16> egress_l4_dport;
}

struct meter_metadata_t {
    bit<2>  packet_color;
    bit<16> meter_index;
}

struct multicast_metadata_t {
    bit<1>  ipv4_mcast_key_type;
    bit<14> ipv4_mcast_key;
    bit<1>  ipv6_mcast_key_type;
    bit<14> ipv6_mcast_key;
    bit<1>  outer_mcast_route_hit;
    bit<2>  outer_mcast_mode;
    bit<1>  mcast_route_hit;
    bit<1>  mcast_bridge_hit;
    bit<1>  ipv4_multicast_enabled;
    bit<1>  ipv6_multicast_enabled;
    bit<1>  igmp_snooping_enabled;
    bit<1>  mld_snooping_enabled;
    bit<14> bd_mrpf_group;
    bit<14> mcast_rpf_group;
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
    bit<2>  nat_nexthop_type;
    bit<1>  nat_hit;
    bit<14> nat_rewrite_index;
    bit<1>  update_checksum;
    bit<1>  update_udp_checksum;
    bit<1>  update_tcp_checksum;
    bit<1>  update_inner_udp_checksum;
    bit<1>  update_inner_tcp_checksum;
    bit<16> l4_len;
}

struct nexthop_metadata_t {
    bit<2> nexthop_type;
}

struct qos_metadata_t {
    bit<5> ingress_qos_group;
    bit<5> tc_qos_group;
    bit<5> egress_qos_group;
    bit<8> lkp_tc;
    bit<1> trust_dscp;
    bit<1> trust_pcp;
}

struct security_metadata_t {
    bit<1> ipsg_enabled;
    bit<1> ipsg_check_fail;
}

struct tunnel_metadata_t {
    bit<5>  ingress_tunnel_type;
    bit<24> tunnel_vni;
    bit<1>  mpls_enabled;
    bit<8>  mpls_ttl;
    bit<3>  mpls_exp;
    bit<5>  egress_tunnel_type;
    bit<14> tunnel_index;
    bit<14> tunnel_dst_index;
    bit<9>  tunnel_src_index;
    bit<9>  tunnel_smac_index;
    bit<14> tunnel_dmac_index;
    bit<24> vnid;
    bit<1>  tunnel_lookup;
    bit<1>  tunnel_terminate;
    bit<1>  tunnel_if_check;
    bit<4>  egress_header_count;
    bit<8>  inner_ip_proto;
    bit<1>  skip_encap_inner;
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
    bit<8>  clone_src;
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
    bit<16> sgt;
    bit<16> ft_d_other;
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

header fabric_header_bfd_event_t {
    bit<16> bfd_session_id;
    bit<16> bfd_event_id;
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

header fabric_header_sflow_t {
    bit<16> sflow_session_id;
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

header pktgen_generic_header_t {
    bit<3>  _pad0;
    bit<3>  app_id;
    bit<2>  pipe_id;
    bit<8>  key_msb;
    bit<16> batch_id;
    bit<16> packet_id;
}

header pktgen_port_down_header_t {
    bit<3>  _pad0;
    bit<3>  app_id;
    bit<2>  pipe_id;
    bit<15> _pad1;
    bit<9>  port_num;
    bit<16> packet_id;
}

header pktgen_recirc_header_t {
    bit<3>  _pad0;
    bit<3>  app_id;
    bit<2>  pipe_id;
    bit<24> key;
    bit<16> packet_id;
}

header pktgen_timer_header_t {
    bit<3>  _pad0;
    bit<3>  app_id;
    bit<2>  pipe_id;
    bit<8>  _pad1;
    bit<16> batch_id;
    bit<16> packet_id;
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
    @pa_solitary("ingress", "acl_metadata.if_label") @pa_atomic("ingress", "acl_metadata.if_label") @name("acl_metadata") 
    acl_metadata_t           acl_metadata;
    @name("egress_metadata") 
    egress_metadata_t        egress_metadata;
    @name("fabric_metadata") 
    fabric_metadata_t        fabric_metadata;
    @pa_atomic("ingress", "flowlet_metadata.id") @name("flowlet_metadata") 
    flowlet_metadata_t       flowlet_metadata;
    @name("global_config_metadata") 
    global_config_metadata_t global_config_metadata;
    @pa_atomic("ingress", "hash_metadata.hash1") @pa_solitary("ingress", "hash_metadata.hash1") @pa_atomic("ingress", "hash_metadata.hash2") @pa_solitary("ingress", "hash_metadata.hash2") @name("hash_metadata") 
    hash_metadata_t          hash_metadata;
    @name("i2e_metadata") 
    i2e_metadata_t           i2e_metadata;
    @pa_atomic("ingress", "ingress_metadata.port_type") @pa_solitary("ingress", "ingress_metadata.port_type") @pa_atomic("ingress", "ingress_metadata.ifindex") @pa_solitary("ingress", "ingress_metadata.ifindex") @pa_atomic("egress", "ingress_metadata.bd") @pa_solitary("egress", "ingress_metadata.bd") @name("ingress_metadata") 
    ingress_metadata_t       ingress_metadata;
    @name("intrinsic_metadata") 
    intrinsic_metadata_t     intrinsic_metadata;
    @name("ipv4_metadata") 
    ipv4_metadata_t          ipv4_metadata;
    @name("ipv6_metadata") 
    ipv6_metadata_t          ipv6_metadata;
    @name("l2_metadata") 
    l2_metadata_t            l2_metadata;
    @name("l3_metadata") 
    l3_metadata_t            l3_metadata;
    @name("meter_metadata") 
    meter_metadata_t         meter_metadata;
    @name("multicast_metadata") 
    multicast_metadata_t     multicast_metadata;
    @name("nat_metadata") 
    nat_metadata_t           nat_metadata;
    @name("nexthop_metadata") 
    nexthop_metadata_t       nexthop_metadata;
    @name("qos_metadata") 
    qos_metadata_t           qos_metadata;
    @name("security_metadata") 
    security_metadata_t      security_metadata;
    @name("tunnel_metadata") 
    tunnel_metadata_t        tunnel_metadata;
}

struct headers {
    @dont_trim @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md") @pa_atomic("egress", "eg_intr_md.egress_port") @pa_fragment("egress", "eg_intr_md._pad1") @pa_fragment("egress", "eg_intr_md._pad7") @pa_fragment("egress", "eg_intr_md._pad8") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_port") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_cos") @name("eg_intr_md") 
    egress_intrinsic_metadata_t                    eg_intr_md;
    @dont_trim @pa_intrinsic_header("egress", "eg_intr_md_for_mb") @pa_atomic("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_fragment("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_length") @not_deparsed("ingress") @not_deparsed("egress") @name("eg_intr_md_for_mb") 
    egress_intrinsic_metadata_for_mirror_buffer_t  eg_intr_md_for_mb;
    @dont_trim @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_oport.drop_ctl") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_for_oport") @name("eg_intr_md_for_oport") 
    egress_intrinsic_metadata_for_output_port_t    eg_intr_md_for_oport;
    @pa_fragment("egress", "eg_intr_md_from_parser_aux.coalesce_sample_count") @pa_fragment("egress", "eg_intr_md_from_parser_aux.clone_src") @pa_fragment("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @pa_atomic("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_from_parser_aux") @name("eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t    eg_intr_md_from_parser_aux;
    @name("eompls") 
    eompls_t                                       eompls;
    @name("erspan_t3_header") 
    erspan_header_t3_t_0                           erspan_t3_header;
    @name("ethernet") 
    ethernet_t                                     ethernet;
    @name("fabric_header") 
    fabric_header_t                                fabric_header;
    @name("fabric_header_bfd") 
    fabric_header_bfd_event_t                      fabric_header_bfd;
    @name("fabric_header_cpu") 
    fabric_header_cpu_t                            fabric_header_cpu;
    @name("fabric_header_mirror") 
    fabric_header_mirror_t                         fabric_header_mirror;
    @name("fabric_header_multicast") 
    fabric_header_multicast_t                      fabric_header_multicast;
    @name("fabric_header_sflow") 
    fabric_header_sflow_t                          fabric_header_sflow;
    @name("fabric_header_unicast") 
    fabric_header_unicast_t                        fabric_header_unicast;
    @name("fabric_payload_header") 
    fabric_payload_header_t                        fabric_payload_header;
    @name("fcoe") 
    fcoe_header_t                                  fcoe;
    @name("genv") 
    genv_t                                         genv;
    @name("gre") 
    gre_t                                          gre;
    @name("icmp") 
    icmp_t                                         icmp;
    @dont_trim @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_intr_md") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md.ingress_port") @name("ig_intr_md") 
    ingress_intrinsic_metadata_t                   ig_intr_md;
    @dont_trim @pa_intrinsic_header("ingress", "ig_intr_md_for_mb") @pa_atomic("ingress", "ig_intr_md_for_mb.ingress_mirror_id") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_mb.ingress_mirror_id") @not_deparsed("ingress") @not_deparsed("egress") @name("ig_intr_md_for_mb") 
    ingress_intrinsic_metadata_for_mirror_buffer_t ig_intr_md_for_mb;
    @pa_atomic("ingress", "ig_intr_md_for_tm.ucast_egress_port") @pa_fragment("ingress", "ig_intr_md_for_tm.drop_ctl") @pa_fragment("ingress", "ig_intr_md_for_tm.qid") @pa_fragment("ingress", "ig_intr_md_for_tm._pad2") @pa_atomic("ingress", "ig_intr_md_for_tm.mcast_grp_a") @pa_fragment("ingress", "ig_intr_md_for_tm.mcast_grp_a") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_tm.mcast_grp_a") @pa_atomic("ingress", "ig_intr_md_for_tm.mcast_grp_b") @pa_fragment("ingress", "ig_intr_md_for_tm.mcast_grp_b") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_tm.mcast_grp_b") @pa_atomic("ingress", "ig_intr_md_for_tm.level1_mcast_hash") @pa_fragment("ingress", "ig_intr_md_for_tm._pad3") @pa_atomic("ingress", "ig_intr_md_for_tm.level2_mcast_hash") @pa_fragment("ingress", "ig_intr_md_for_tm._pad4") @pa_atomic("ingress", "ig_intr_md_for_tm.level1_exclusion_id") @pa_fragment("ingress", "ig_intr_md_for_tm.level1_exclusion_id") @pa_atomic("ingress", "ig_intr_md_for_tm.level2_exclusion_id") @pa_fragment("ingress", "ig_intr_md_for_tm._pad5") @pa_atomic("ingress", "ig_intr_md_for_tm.rid") @pa_fragment("ingress", "ig_intr_md_for_tm.rid") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_intr_md_for_tm") @dont_trim @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_tm.drop_ctl") @name("ig_intr_md_for_tm") 
    ingress_intrinsic_metadata_for_tm_t            ig_intr_md_for_tm;
    @pa_fragment("ingress", "ig_intr_md_from_parser_aux.ingress_parser_err") @pa_atomic("ingress", "ig_intr_md_from_parser_aux.ingress_parser_err") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_intr_md_from_parser_aux") @name("ig_intr_md_from_parser_aux") 
    ingress_intrinsic_metadata_from_parser_aux_t   ig_intr_md_from_parser_aux;
    @not_deparsed("ingress") @not_deparsed("egress") @name("ig_pg_md") 
    generator_metadata_t_0                         ig_pg_md;
    @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_prsr_ctrl") @name("ig_prsr_ctrl") 
    ingress_parser_control_signals                 ig_prsr_ctrl;
    @name("inner_ethernet") 
    ethernet_t                                     inner_ethernet;
    @name("inner_icmp") 
    icmp_t                                         inner_icmp;
    @pa_fragment("ingress", "inner_ipv4.hdrChecksum") @pa_fragment("egress", "inner_ipv4.hdrChecksum") @name("inner_ipv4") 
    ipv4_t                                         inner_ipv4;
    @name("inner_ipv6") 
    ipv6_t                                         inner_ipv6;
    @name("inner_sctp") 
    sctp_t                                         inner_sctp;
    @pa_alias("egress", "inner_tcp", "tcp") @pa_fragment("egress", "inner_tcp.checksum") @pa_fragment("egress", "inner_tcp.urgentPtr") @name("inner_tcp") 
    tcp_t                                          inner_tcp;
    @name("inner_udp") 
    udp_t                                          inner_udp;
    @pa_fragment("ingress", "ipv4.hdrChecksum") @pa_fragment("egress", "ipv4.hdrChecksum") @name("ipv4") 
    ipv4_t                                         ipv4;
    @name("ipv6") 
    ipv6_t                                         ipv6;
    @name("lisp") 
    lisp_t                                         lisp;
    @name("llc_header") 
    llc_header_t                                   llc_header;
    @name("nsh") 
    nsh_t                                          nsh;
    @name("nsh_context") 
    nsh_context_t                                  nsh_context;
    @name("nvgre") 
    nvgre_t                                        nvgre;
    @name("outer_udp") 
    udp_t                                          outer_udp;
    @name("pktgen_generic") 
    pktgen_generic_header_t                        pktgen_generic;
    @name("pktgen_port_down") 
    pktgen_port_down_header_t                      pktgen_port_down;
    @name("pktgen_recirc") 
    pktgen_recirc_header_t                         pktgen_recirc;
    @name("pktgen_timer") 
    pktgen_timer_header_t                          pktgen_timer;
    @name("roce") 
    roce_header_t                                  roce;
    @name("roce_v2") 
    roce_v2_header_t                               roce_v2;
    @name("sctp") 
    sctp_t                                         sctp;
    @name("sflow") 
    sflow_hdr_t                                    sflow;
    @name("sflow_raw_hdr_record") 
    sflow_raw_hdr_record_t                         sflow_raw_hdr_record;
    @name("sflow_sample") 
    sflow_sample_t                                 sflow_sample;
    @name("snap_header") 
    snap_header_t                                  snap_header;
    @pa_fragment("egress", "tcp.checksum") @pa_fragment("egress", "tcp.urgentPtr") @name("tcp") 
    tcp_t                                          tcp;
    @name("trill") 
    trill_t                                        trill;
    @name("udp") 
    udp_t                                          udp;
    @name("vntag") 
    vntag_t                                        vntag;
    @name("vxlan") 
    vxlan_t                                        vxlan;
    @name("mpls") 
    mpls_t[3]                                      mpls;
    @name("vlan_tag_") 
    vlan_tag_t[2]                                  vlan_tag_;
}

extern stateful_alu {
    void execute_stateful_alu(@optional in bit<32> index);
    void execute_stateful_alu_from_hash<FL>(in FL hash_field_list);
    void execute_stateful_log();
    stateful_alu();
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("parse_arp_rarp") state parse_arp_rarp {
        transition parse_set_prio_med;
    }
    @name("parse_eompls") state parse_eompls {
        meta.tunnel_metadata.ingress_tunnel_type = 5w6;
        transition parse_inner_ethernet;
    }
    @name("parse_erspan_t3") state parse_erspan_t3 {
        packet.extract(hdr.erspan_t3_header);
        transition select(hdr.erspan_t3_header.ft_d_other) {
            16w0 &&& 16w0x7c01: parse_inner_ethernet;
            16w0x800 &&& 16w0x7c01: parse_inner_ipv4;
            default: accept;
        }
    }
    @name("parse_ethernet") state parse_ethernet {
        packet.extract(hdr.ethernet);
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
            default: accept;
        }
    }
    @name("parse_fabric_header") state parse_fabric_header {
        packet.extract(hdr.fabric_header);
        transition select(hdr.fabric_header.packetType) {
            3w5: parse_fabric_header_cpu;
            default: accept;
        }
    }
    @name("parse_fabric_header_cpu") state parse_fabric_header_cpu {
        packet.extract(hdr.fabric_header_cpu);
        meta.ingress_metadata.bypass_lookups = hdr.fabric_header_cpu.reasonCode;
        transition select(hdr.fabric_header_cpu.reasonCode) {
            default: parse_fabric_payload_header;
        }
    }
    @name("parse_fabric_header_mirror") state parse_fabric_header_mirror {
        packet.extract(hdr.fabric_header_mirror);
        transition parse_fabric_payload_header;
    }
    @name("parse_fabric_header_multicast") state parse_fabric_header_multicast {
        packet.extract(hdr.fabric_header_multicast);
        transition parse_fabric_payload_header;
    }
    @name("parse_fabric_header_unicast") state parse_fabric_header_unicast {
        packet.extract(hdr.fabric_header_unicast);
        transition parse_fabric_payload_header;
    }
    @name("parse_fabric_payload_header") state parse_fabric_payload_header {
        packet.extract(hdr.fabric_payload_header);
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
            default: accept;
        }
    }
    @name("parse_fcoe") state parse_fcoe {
        packet.extract(hdr.fcoe);
        transition accept;
    }
    @name("parse_geneve") state parse_geneve {
        packet.extract(hdr.genv);
        meta.tunnel_metadata.tunnel_vni = hdr.genv.vni;
        meta.tunnel_metadata.ingress_tunnel_type = 5w4;
        transition select(hdr.genv.ver, hdr.genv.optLen, hdr.genv.protoType) {
            (2w0x0, 6w0x0, 16w0x6558): parse_inner_ethernet;
            (2w0x0, 6w0x0, 16w0x800): parse_inner_ipv4;
            (2w0x0, 6w0x0, 16w0x86dd): parse_inner_ipv6;
            default: accept;
        }
    }
    @name("parse_gre") state parse_gre {
        packet.extract(hdr.gre);
        transition select(hdr.gre.C, hdr.gre.R, hdr.gre.K, hdr.gre.S, hdr.gre.s, hdr.gre.recurse, hdr.gre.flags, hdr.gre.ver, hdr.gre.proto) {
            (1w0x0, 1w0x0, 1w0x1, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x6558): parse_nvgre;
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x800): parse_gre_ipv4;
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x86dd): parse_gre_ipv6;
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x22eb): parse_erspan_t3;
            default: accept;
        }
    }
    @name("parse_gre_ipv4") state parse_gre_ipv4 {
        meta.tunnel_metadata.ingress_tunnel_type = 5w2;
        transition parse_inner_ipv4;
    }
    @name("parse_gre_ipv6") state parse_gre_ipv6 {
        meta.tunnel_metadata.ingress_tunnel_type = 5w2;
        transition parse_inner_ipv6;
    }
    @name("parse_gre_v6") state parse_gre_v6 {
        packet.extract(hdr.gre);
        transition select(hdr.gre.C, hdr.gre.R, hdr.gre.K, hdr.gre.S, hdr.gre.s, hdr.gre.recurse, hdr.gre.flags, hdr.gre.ver, hdr.gre.proto) {
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x800): parse_gre_ipv4;
            default: accept;
        }
    }
    @name("parse_icmp") state parse_icmp {
        packet.extract(hdr.icmp);
        meta.l3_metadata.lkp_outer_l4_sport = hdr.icmp.typeCode;
        transition select(hdr.icmp.typeCode) {
            16w0x8200 &&& 16w0xfe00: parse_set_prio_med;
            16w0x8400 &&& 16w0xfc00: parse_set_prio_med;
            16w0x8800 &&& 16w0xff00: parse_set_prio_med;
            default: accept;
        }
    }
    @name("parse_inner_ethernet") state parse_inner_ethernet {
        packet.extract(hdr.inner_ethernet);
        meta.l2_metadata.lkp_mac_sa = hdr.inner_ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.inner_ethernet.dstAddr;
        transition select(hdr.inner_ethernet.etherType) {
            16w0x800: parse_inner_ipv4;
            16w0x86dd: parse_inner_ipv6;
            default: accept;
        }
    }
    @name("parse_inner_icmp") state parse_inner_icmp {
        packet.extract(hdr.inner_icmp);
        meta.l3_metadata.lkp_l4_sport = hdr.inner_icmp.typeCode;
        transition accept;
    }
    @name("parse_inner_ipv4") state parse_inner_ipv4 {
        packet.extract(hdr.inner_ipv4);
        meta.ipv4_metadata.lkp_ipv4_sa = hdr.inner_ipv4.srcAddr;
        meta.ipv4_metadata.lkp_ipv4_da = hdr.inner_ipv4.dstAddr;
        meta.l3_metadata.lkp_ip_proto = hdr.inner_ipv4.protocol;
        meta.l3_metadata.lkp_ip_ttl = hdr.inner_ipv4.ttl;
        transition select(hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.ihl, hdr.inner_ipv4.protocol) {
            (13w0x0, 4w0x5, 8w0x1): parse_inner_icmp;
            (13w0x0, 4w0x5, 8w0x6): parse_inner_tcp;
            (13w0x0, 4w0x5, 8w0x11): parse_inner_udp;
            default: accept;
        }
    }
    @name("parse_inner_ipv6") state parse_inner_ipv6 {
        packet.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.nextHdr) {
            8w58: parse_inner_icmp;
            8w6: parse_inner_tcp;
            8w17: parse_inner_udp;
            default: accept;
        }
    }
    @name("parse_inner_sctp") state parse_inner_sctp {
        packet.extract(hdr.inner_sctp);
        transition accept;
    }
    @name("parse_inner_tcp") state parse_inner_tcp {
        packet.extract(hdr.inner_tcp);
        meta.l3_metadata.lkp_l4_sport = hdr.inner_tcp.srcPort;
        meta.l3_metadata.lkp_l4_dport = hdr.inner_tcp.dstPort;
        transition accept;
    }
    @name("parse_inner_udp") state parse_inner_udp {
        packet.extract(hdr.inner_udp);
        meta.l3_metadata.lkp_l4_sport = hdr.inner_udp.srcPort;
        meta.l3_metadata.lkp_l4_dport = hdr.inner_udp.dstPort;
        transition accept;
    }
    @name("parse_ipv4") state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.ihl, hdr.ipv4.protocol) {
            (13w0x0, 4w0x5, 8w0x1): parse_icmp;
            (13w0x0, 4w0x5, 8w0x6): parse_tcp;
            (13w0x0, 4w0x5, 8w0x11): parse_udp;
            (13w0, 4w0, 8w2): parse_set_prio_med;
            (13w0, 4w0, 8w88): parse_set_prio_med;
            (13w0, 4w0, 8w89): parse_set_prio_med;
            (13w0, 4w0, 8w103): parse_set_prio_med;
            (13w0, 4w0, 8w112): parse_set_prio_med;
            default: accept;
        }
    }
    @name("parse_ipv4_in_ip") state parse_ipv4_in_ip {
        meta.tunnel_metadata.ingress_tunnel_type = 5w3;
        transition parse_inner_ipv4;
    }
    @name("parse_ipv6") state parse_ipv6 {
        packet.extract(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            8w58: parse_icmp;
            8w6: parse_tcp;
            8w4: parse_ipv4_in_ip;
            8w88: parse_set_prio_med;
            8w89: parse_set_prio_med;
            8w103: parse_set_prio_med;
            8w112: parse_set_prio_med;
            default: accept;
        }
    }
    @name("parse_ipv6_in_ip") state parse_ipv6_in_ip {
        meta.tunnel_metadata.ingress_tunnel_type = 5w3;
        transition parse_inner_ipv6;
    }
    @name("parse_lisp") state parse_lisp {
        packet.extract(hdr.lisp);
        transition select((packet.lookahead<bit<4>>())[3:0]) {
            4w0x4: parse_inner_ipv4;
            4w0x6: parse_inner_ipv6;
            default: accept;
        }
    }
    @name("parse_llc_header") state parse_llc_header {
        packet.extract(hdr.llc_header);
        transition select(hdr.llc_header.dsap, hdr.llc_header.ssap) {
            (8w0xaa, 8w0xaa): parse_snap_header;
            (8w0xfe, 8w0xfe): parse_set_prio_med;
            default: accept;
        }
    }
    @name("parse_mpls") state parse_mpls {
        transition accept;
    }
    @name("parse_mpls_bos") state parse_mpls_bos {
        transition select((packet.lookahead<bit<4>>())[3:0]) {
            default: parse_eompls;
        }
    }
    @name("parse_mpls_inner_ipv4") state parse_mpls_inner_ipv4 {
        meta.tunnel_metadata.ingress_tunnel_type = 5w6;
        transition parse_inner_ipv4;
    }
    @name("parse_mpls_inner_ipv6") state parse_mpls_inner_ipv6 {
        meta.tunnel_metadata.ingress_tunnel_type = 5w6;
        transition parse_inner_ipv6;
    }
    @name("parse_nsh") state parse_nsh {
        packet.extract(hdr.nsh);
        packet.extract(hdr.nsh_context);
        transition select(hdr.nsh.protoType) {
            16w0x800: parse_inner_ipv4;
            16w0x86dd: parse_inner_ipv6;
            16w0x6558: parse_inner_ethernet;
            default: accept;
        }
    }
    @name("parse_nvgre") state parse_nvgre {
        packet.extract(hdr.nvgre);
        meta.tunnel_metadata.ingress_tunnel_type = 5w5;
        meta.tunnel_metadata.tunnel_vni = hdr.nvgre.tni;
        transition parse_inner_ethernet;
    }
    @name("parse_pw") state parse_pw {
        transition accept;
    }
    @name("parse_qinq") state parse_qinq {
        packet.extract(hdr.vlan_tag_[0]);
        transition select(hdr.vlan_tag_[0].etherType) {
            16w0x8100: parse_qinq_vlan;
            default: accept;
        }
    }
    @name("parse_qinq_vlan") state parse_qinq_vlan {
        packet.extract(hdr.vlan_tag_[1]);
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
    @name("parse_roce") state parse_roce {
        packet.extract(hdr.roce);
        transition accept;
    }
    @name("parse_roce_v2") state parse_roce_v2 {
        packet.extract(hdr.roce_v2);
        transition accept;
    }
    @name("parse_sctp") state parse_sctp {
        packet.extract(hdr.sctp);
        transition accept;
    }
    @name("parse_set_prio_high") state parse_set_prio_high {
        hdr.ig_prsr_ctrl.priority = 3w5;
        transition accept;
    }
    @name("parse_set_prio_max") state parse_set_prio_max {
        hdr.ig_prsr_ctrl.priority = 3w7;
        transition accept;
    }
    @name("parse_set_prio_med") state parse_set_prio_med {
        hdr.ig_prsr_ctrl.priority = 3w3;
        transition accept;
    }
    @name("parse_sflow") state parse_sflow {
        transition accept;
    }
    @name("parse_snap_header") state parse_snap_header {
        packet.extract(hdr.snap_header);
        transition select(hdr.snap_header.type_) {
            16w0x8100: parse_vlan;
            16w0x9100: parse_qinq;
            16w0x8847: parse_mpls;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            16w0x806: parse_arp_rarp;
            16w0x88cc: parse_set_prio_high;
            16w0x8809: parse_set_prio_high;
            default: accept;
        }
    }
    @name("parse_tcp") state parse_tcp {
        packet.extract(hdr.tcp);
        meta.l3_metadata.lkp_outer_l4_sport = hdr.tcp.srcPort;
        meta.l3_metadata.lkp_outer_l4_dport = hdr.tcp.dstPort;
        transition select(hdr.tcp.dstPort) {
            16w179: parse_set_prio_med;
            16w639: parse_set_prio_med;
            default: accept;
        }
    }
    @name("parse_trill") state parse_trill {
        packet.extract(hdr.trill);
        transition parse_inner_ethernet;
    }
    @name("parse_udp") state parse_udp {
        packet.extract(hdr.udp);
        meta.l3_metadata.lkp_outer_l4_sport = hdr.udp.srcPort;
        meta.l3_metadata.lkp_outer_l4_dport = hdr.udp.dstPort;
        transition select(hdr.udp.dstPort) {
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
    @name("parse_udp_v6") state parse_udp_v6 {
        packet.extract(hdr.udp);
        meta.l3_metadata.lkp_outer_l4_sport = hdr.udp.srcPort;
        meta.l3_metadata.lkp_outer_l4_dport = hdr.udp.dstPort;
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
    @name("parse_vlan") state parse_vlan {
        packet.extract(hdr.vlan_tag_[0]);
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
    @name("parse_vntag") state parse_vntag {
        packet.extract(hdr.vntag);
        transition parse_inner_ethernet;
    }
    @name("parse_vpls") state parse_vpls {
        transition accept;
    }
    @name("parse_vxlan") state parse_vxlan {
        packet.extract(hdr.vxlan);
        meta.tunnel_metadata.ingress_tunnel_type = 5w1;
        meta.tunnel_metadata.tunnel_vni = hdr.vxlan.vni;
        transition parse_inner_ethernet;
    }
    @name("start") state start {
        transition select((packet.lookahead<bit<112>>())[15:0]) {
            default: parse_ethernet;
        }
    }
}

control process_adjust_packet_length(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_bfd_recirc(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_int_egress_prep(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_mirroring(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_bfd_mirror_to_cpu(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_replication(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_egress_bfd_packet(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
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
    @ternary(1) @name("vlan_decap") table vlan_decap {
        actions = {
            nop;
            remove_vlan_single_tagged;
            remove_vlan_double_tagged;
        }
        key = {
            hdr.vlan_tag_[0].isValid(): exact;
            hdr.vlan_tag_[1].isValid(): exact;
        }
        size = 256;
    }
    apply {
        vlan_decap.apply();
    }
}

control process_tunnel_decap(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
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
    @name("rewrite") table rewrite {
        actions = {
            nop;
            set_l2_rewrite;
        }
        key = {
            meta.l3_metadata.nexthop_index: exact;
        }
        size = 16384;
    }
    apply {
        if (meta.egress_metadata.routed == 1w0 || meta.l3_metadata.nexthop_index != 16w0) {
            rewrite.apply();
        }
        else {
        }
    }
}

control process_egress_bd(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_egress_bd_properties") action set_egress_bd_properties(bit<9> smac_idx, bit<2> nat_mode, bit<16> bd_label) {
        meta.egress_metadata.smac_idx = smac_idx;
        meta.nat_metadata.egress_nat_mode = nat_mode;
        meta.acl_metadata.egress_bd_label = bd_label;
    }
    @name("egress_bd_map") table egress_bd_map {
        actions = {
            nop;
            set_egress_bd_properties;
        }
        key = {
            meta.egress_metadata.bd: exact;
        }
        size = 16384;
    }
    apply {
        egress_bd_map.apply();
    }
}

control process_egress_qos_map(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_mac_rewrite(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_mtu(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_egress_nat(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_egress_bd_stats(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("egress_bd_stats") direct_counter(CounterType.packets_and_bytes) egress_bd_stats;
    @name(".nop") action nop() {
    }
    @name(".nop") action nop_0() {
        egress_bd_stats.count();
    }
    @name("egress_bd_stats") table egress_bd_stats_0 {
        actions = {
            nop_0;
        }
        key = {
            meta.egress_metadata.bd      : exact;
            meta.l2_metadata.lkp_pkt_type: exact;
        }
        size = 16384;
        @name("egress_bd_stats") counters = direct_counter(CounterType.packets_and_bytes);
    }
    apply {
        egress_bd_stats_0.apply();
    }
}

control process_egress_l4port(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_int_egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_tunnel_encap(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".fabric_rewrite") action fabric_rewrite(bit<14> tunnel_index) {
        meta.tunnel_metadata.tunnel_index = tunnel_index;
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
        hdr.fabric_header_cpu.ingressBd = (bit<16>)meta.ingress_metadata.bd;
        hdr.fabric_header_cpu.reasonCode = meta.fabric_metadata.reason_code;
        hdr.fabric_payload_header.setValid();
        hdr.fabric_payload_header.etherType = hdr.ethernet.etherType;
        hdr.ethernet.etherType = 16w0x9000;
    }
    @ternary(1) @name("tunnel_encap_process_outer") table tunnel_encap_process_outer {
        actions = {
            nop;
            fabric_rewrite;
        }
        key = {
            meta.tunnel_metadata.egress_tunnel_type : exact;
            meta.tunnel_metadata.egress_header_count: exact;
            meta.multicast_metadata.replica         : exact;
        }
        size = 256;
    }
    @name("tunnel_rewrite") table tunnel_rewrite {
        actions = {
            nop;
            cpu_rx_rewrite;
        }
        key = {
            meta.tunnel_metadata.tunnel_index: exact;
        }
        size = 16384;
    }
    apply {
        if (meta.fabric_metadata.fabric_header_present == 1w0 && meta.tunnel_metadata.egress_tunnel_type != 5w0) {
            tunnel_encap_process_outer.apply();
            tunnel_rewrite.apply();
        }
    }
}

control process_l4_checksum(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_egress_acl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
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
    @name("egress_vlan_xlate") table egress_vlan_xlate {
        actions = {
            set_egress_packet_vlan_untagged;
            set_egress_packet_vlan_tagged;
            set_egress_packet_vlan_double_tagged;
        }
        key = {
            meta.egress_metadata.ifindex: exact;
            meta.egress_metadata.bd     : exact;
        }
        size = 32768;
    }
    apply {
        egress_vlan_xlate.apply();
    }
}

control process_egress_filter(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_egress_system_acl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".drop_packet") action drop_packet() {
        mark_to_drop();
    }
    @name(".egress_copy_to_cpu") action egress_copy_to_cpu() {
        clone3(CloneType.E2E, (bit<32>)32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
    }
    @name(".egress_redirect_to_cpu") action egress_redirect_to_cpu() {
        egress_copy_to_cpu();
        mark_to_drop();
    }
    @name(".egress_copy_to_cpu_with_reason") action egress_copy_to_cpu_with_reason(bit<16> reason_code) {
        meta.fabric_metadata.reason_code = reason_code;
        egress_copy_to_cpu();
    }
    @name(".egress_redirect_to_cpu_with_reason") action egress_redirect_to_cpu_with_reason(bit<16> reason_code) {
        egress_copy_to_cpu_with_reason(reason_code);
        mark_to_drop();
    }
    @name(".egress_mirror_coal_hdr") action egress_mirror_coal_hdr(bit<8> session_id, bit<8> id) {
    }
    @name("egress_system_acl") table egress_system_acl {
        actions = {
            nop;
            drop_packet;
            egress_copy_to_cpu;
            egress_redirect_to_cpu;
            egress_copy_to_cpu_with_reason;
            egress_redirect_to_cpu_with_reason;
            egress_mirror_coal_hdr;
        }
        key = {
            meta.fabric_metadata.reason_code: ternary;
            hdr.eg_intr_md.egress_port      : ternary;
            hdr.eg_intr_md.deflection_flag  : ternary;
            meta.l3_metadata.l3_mtu_check   : ternary;
            meta.acl_metadata.acl_deny      : ternary;
        }
        size = 128;
    }
    apply {
        if (meta.egress_metadata.bypass == 1w0) {
            egress_system_acl.apply();
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".egress_port_type_normal") action egress_port_type_normal(bit<16> ifindex, bit<5> qos_group, bit<16> if_label) {
        meta.egress_metadata.port_type = 2w0;
        meta.egress_metadata.ifindex = ifindex;
        meta.qos_metadata.egress_qos_group = qos_group;
        meta.acl_metadata.egress_if_label = if_label;
    }
    @name(".egress_port_type_fabric") action egress_port_type_fabric(bit<16> ifindex) {
        meta.egress_metadata.port_type = 2w1;
        meta.egress_metadata.ifindex = ifindex;
        meta.tunnel_metadata.egress_tunnel_type = 5w15;
    }
    @name(".egress_port_type_cpu") action egress_port_type_cpu(bit<16> ifindex) {
        meta.egress_metadata.port_type = 2w2;
        meta.egress_metadata.ifindex = ifindex;
        meta.tunnel_metadata.egress_tunnel_type = 5w16;
    }
    @name("egress_port_mapping") table egress_port_mapping {
        actions = {
            egress_port_type_normal;
            egress_port_type_fabric;
            egress_port_type_cpu;
        }
        key = {
            hdr.eg_intr_md.egress_port: exact;
        }
        size = 288;
    }
    @name("process_adjust_packet_length") process_adjust_packet_length() process_adjust_packet_length_0;
    @name("process_bfd_recirc") process_bfd_recirc() process_bfd_recirc_0;
    @name("process_int_egress_prep") process_int_egress_prep() process_int_egress_prep_0;
    @name("process_mirroring") process_mirroring() process_mirroring_0;
    @name("process_bfd_mirror_to_cpu") process_bfd_mirror_to_cpu() process_bfd_mirror_to_cpu_0;
    @name("process_replication") process_replication() process_replication_0;
    @name("process_egress_bfd_packet") process_egress_bfd_packet() process_egress_bfd_packet_0;
    @name("process_vlan_decap") process_vlan_decap() process_vlan_decap_0;
    @name("process_tunnel_decap") process_tunnel_decap() process_tunnel_decap_0;
    @name("process_rewrite") process_rewrite() process_rewrite_0;
    @name("process_egress_bd") process_egress_bd() process_egress_bd_0;
    @name("process_egress_qos_map") process_egress_qos_map() process_egress_qos_map_0;
    @name("process_mac_rewrite") process_mac_rewrite() process_mac_rewrite_0;
    @name("process_mtu") process_mtu() process_mtu_0;
    @name("process_egress_nat") process_egress_nat() process_egress_nat_0;
    @name("process_egress_bd_stats") process_egress_bd_stats() process_egress_bd_stats_0;
    @name("process_egress_l4port") process_egress_l4port() process_egress_l4port_0;
    @name("process_int_egress") process_int_egress() process_int_egress_0;
    @name("process_tunnel_encap") process_tunnel_encap() process_tunnel_encap_0;
    @name("process_l4_checksum") process_l4_checksum() process_l4_checksum_0;
    @name("process_egress_acl") process_egress_acl() process_egress_acl_0;
    @name("process_int_outer_encap") process_int_outer_encap() process_int_outer_encap_0;
    @name("process_vlan_xlate") process_vlan_xlate() process_vlan_xlate_0;
    @name("process_egress_filter") process_egress_filter() process_egress_filter_0;
    @name("process_egress_system_acl") process_egress_system_acl() process_egress_system_acl_0;
    apply {
        process_adjust_packet_length_0.apply(hdr, meta, standard_metadata);
        process_bfd_recirc_0.apply(hdr, meta, standard_metadata);
        if (hdr.eg_intr_md.deflection_flag == 1w0 && meta.egress_metadata.bypass == 1w0) {
            process_int_egress_prep_0.apply(hdr, meta, standard_metadata);
            if (hdr.eg_intr_md_from_parser_aux.clone_src != 8w0) {
                process_mirroring_0.apply(hdr, meta, standard_metadata);
                process_bfd_mirror_to_cpu_0.apply(hdr, meta, standard_metadata);
            }
            else {
                process_replication_0.apply(hdr, meta, standard_metadata);
                process_egress_bfd_packet_0.apply(hdr, meta, standard_metadata);
            }
            switch (egress_port_mapping.apply().action_run) {
                egress_port_type_normal: {
                    if (hdr.eg_intr_md_from_parser_aux.clone_src == 8w0) {
                        process_vlan_decap_0.apply(hdr, meta, standard_metadata);
                    }
                    process_tunnel_decap_0.apply(hdr, meta, standard_metadata);
                    process_rewrite_0.apply(hdr, meta, standard_metadata);
                    process_egress_bd_0.apply(hdr, meta, standard_metadata);
                    process_egress_qos_map_0.apply(hdr, meta, standard_metadata);
                    process_mac_rewrite_0.apply(hdr, meta, standard_metadata);
                    process_mtu_0.apply(hdr, meta, standard_metadata);
                    process_egress_nat_0.apply(hdr, meta, standard_metadata);
                    process_egress_bd_stats_0.apply(hdr, meta, standard_metadata);
                }
            }

            process_egress_l4port_0.apply(hdr, meta, standard_metadata);
            process_int_egress_0.apply(hdr, meta, standard_metadata);
            process_tunnel_encap_0.apply(hdr, meta, standard_metadata);
            process_l4_checksum_0.apply(hdr, meta, standard_metadata);
            process_egress_acl_0.apply(hdr, meta, standard_metadata);
            process_int_outer_encap_0.apply(hdr, meta, standard_metadata);
            if (meta.egress_metadata.port_type == 2w0) {
                process_vlan_xlate_0.apply(hdr, meta, standard_metadata);
            }
            process_egress_filter_0.apply(hdr, meta, standard_metadata);
        }
        process_egress_system_acl_0.apply(hdr, meta, standard_metadata);
    }
}

control process_ingress_port_mapping(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_ifindex") action set_ifindex(bit<16> ifindex, bit<2> port_type) {
        meta.ingress_metadata.ifindex = ifindex;
        meta.ingress_metadata.port_type = port_type;
    }
    @name(".set_ingress_port_properties") action set_ingress_port_properties(bit<16> if_label, bit<9> exclusion_id, bit<5> qos_group, bit<5> tc_qos_group, bit<8> tc, bit<2> color, bit<1> trust_dscp, bit<1> trust_pcp) {
        hdr.ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
        meta.acl_metadata.if_label = if_label;
        meta.qos_metadata.ingress_qos_group = qos_group;
        meta.qos_metadata.tc_qos_group = tc_qos_group;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
        meta.qos_metadata.trust_dscp = trust_dscp;
        meta.qos_metadata.trust_pcp = trust_pcp;
    }
    @name("ingress_port_mapping") table ingress_port_mapping {
        actions = {
            set_ifindex;
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact;
        }
        size = 288;
    }
    @name("ingress_port_properties") table ingress_port_properties {
        actions = {
            set_ingress_port_properties;
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact;
        }
        size = 288;
    }
    apply {
        if (hdr.ig_intr_md.resubmit_flag == 1w0) {
            ingress_port_mapping.apply();
        }
        ingress_port_properties.apply();
    }
}

control process_global_params(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".deflect_on_drop") action deflect_on_drop(bit<1> enable_dod) {
        hdr.ig_intr_md_for_tm.deflect_on_drop = enable_dod;
    }
    @name(".set_config_parameters") action set_config_parameters(bit<1> enable_dod, bit<8> enable_flowlet, bit<32> switch_id) {
        deflect_on_drop(enable_dod);
        meta.i2e_metadata.ingress_tstamp = (bit<32>)hdr.ig_intr_md_from_parser_aux.ingress_global_tstamp;
        meta.ingress_metadata.ingress_port = hdr.ig_intr_md.ingress_port;
        meta.l2_metadata.same_if_check = meta.ingress_metadata.ifindex;
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w511;
        meta.global_config_metadata.switch_id = switch_id;
    }
    @name("switch_config_params") table switch_config_params {
        actions = {
            set_config_parameters;
        }
        size = 1;
    }
    apply {
        switch_config_params.apply();
    }
}

control validate_outer_ipv4_header(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control validate_outer_ipv6_header(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_validate_outer_header(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".malformed_outer_ethernet_packet") action malformed_outer_ethernet_packet(bit<8> drop_reason) {
        meta.ingress_metadata.drop_flag = 1w1;
        meta.ingress_metadata.drop_reason = drop_reason;
    }
    @name(".set_valid_outer_unicast_packet_untagged") action set_valid_outer_unicast_packet_untagged() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name(".set_valid_outer_unicast_packet_single_tagged") action set_valid_outer_unicast_packet_single_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[0].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_unicast_packet_double_tagged") action set_valid_outer_unicast_packet_double_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[1].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_unicast_packet_qinq_tagged") action set_valid_outer_unicast_packet_qinq_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_multicast_packet_untagged") action set_valid_outer_multicast_packet_untagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name(".set_valid_outer_multicast_packet_single_tagged") action set_valid_outer_multicast_packet_single_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[0].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_multicast_packet_double_tagged") action set_valid_outer_multicast_packet_double_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[1].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_multicast_packet_qinq_tagged") action set_valid_outer_multicast_packet_qinq_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_broadcast_packet_untagged") action set_valid_outer_broadcast_packet_untagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name(".set_valid_outer_broadcast_packet_single_tagged") action set_valid_outer_broadcast_packet_single_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[0].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_broadcast_packet_double_tagged") action set_valid_outer_broadcast_packet_double_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[1].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_broadcast_packet_qinq_tagged") action set_valid_outer_broadcast_packet_qinq_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name("validate_outer_ethernet") table validate_outer_ethernet {
        actions = {
            malformed_outer_ethernet_packet;
            set_valid_outer_unicast_packet_untagged;
            set_valid_outer_unicast_packet_single_tagged;
            set_valid_outer_unicast_packet_double_tagged;
            set_valid_outer_unicast_packet_qinq_tagged;
            set_valid_outer_multicast_packet_untagged;
            set_valid_outer_multicast_packet_single_tagged;
            set_valid_outer_multicast_packet_double_tagged;
            set_valid_outer_multicast_packet_qinq_tagged;
            set_valid_outer_broadcast_packet_untagged;
            set_valid_outer_broadcast_packet_single_tagged;
            set_valid_outer_broadcast_packet_double_tagged;
            set_valid_outer_broadcast_packet_qinq_tagged;
        }
        key = {
            hdr.ethernet.srcAddr      : ternary;
            hdr.ethernet.dstAddr      : ternary;
            hdr.vlan_tag_[0].isValid(): exact;
            hdr.vlan_tag_[1].isValid(): exact;
        }
        size = 64;
    }
    @name("validate_outer_ipv4_header") validate_outer_ipv4_header() validate_outer_ipv4_header_0;
    @name("validate_outer_ipv6_header") validate_outer_ipv6_header() validate_outer_ipv6_header_0;
    apply {
        switch (validate_outer_ethernet.apply().action_run) {
            default: {
                if (hdr.ipv4.isValid()) {
                    validate_outer_ipv4_header_0.apply(hdr, meta, standard_metadata);
                }
                else {
                    if (hdr.ipv6.isValid()) {
                        validate_outer_ipv6_header_0.apply(hdr, meta, standard_metadata);
                    }
                    else {
                    }
                }
            }
            malformed_outer_ethernet_packet: {
            }
        }

    }
}

control process_int_endpoint(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_bfd_rx_packet(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_port_vlan_mapping(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".non_ip_lkp") action non_ip_lkp() {
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        hdr.ig_intr_md_for_tm.mcast_grp_a = 16w0;
        meta.l2_metadata.non_ip_packet = 1w1;
    }
    @name(".ipv4_lkp") action ipv4_lkp() {
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.ipv4_metadata.lkp_ipv4_sa = hdr.ipv4.srcAddr;
        meta.ipv4_metadata.lkp_ipv4_da = hdr.ipv4.dstAddr;
        meta.l3_metadata.lkp_ip_proto = hdr.ipv4.protocol;
        meta.l3_metadata.lkp_ip_ttl = hdr.ipv4.ttl;
        meta.l3_metadata.lkp_l4_sport = meta.l3_metadata.lkp_outer_l4_sport;
        meta.l3_metadata.lkp_l4_dport = meta.l3_metadata.lkp_outer_l4_dport;
        hdr.ig_intr_md_for_tm.mcast_grp_a = 16w0;
    }
    @name(".set_bd_properties") action set_bd_properties(bit<14> bd, bit<14> vrf, bit<10> stp_group, bit<1> learning_enabled, bit<16> bd_label, bit<16> stats_idx, bit<10> rmac_group, bit<1> ipv4_unicast_enabled, bit<1> ipv6_unicast_enabled, bit<2> ipv4_urpf_mode, bit<2> ipv6_urpf_mode, bit<1> igmp_snooping_enabled, bit<1> mld_snooping_enabled, bit<1> ipv4_multicast_enabled, bit<1> ipv6_multicast_enabled, bit<14> mrpf_group, bit<14> ipv4_mcast_key, bit<1> ipv4_mcast_key_type, bit<14> ipv6_mcast_key, bit<1> ipv6_mcast_key_type, bit<16> ingress_rid) {
        meta.ingress_metadata.bd = bd;
        meta.ingress_metadata.outer_bd = bd;
        meta.acl_metadata.bd_label = bd_label;
        meta.l2_metadata.stp_group = stp_group;
        meta.l2_metadata.bd_stats_idx = stats_idx;
        meta.l2_metadata.learning_enabled = learning_enabled;
        meta.l3_metadata.vrf = vrf;
        meta.ipv4_metadata.ipv4_unicast_enabled = ipv4_unicast_enabled;
        meta.ipv6_metadata.ipv6_unicast_enabled = ipv6_unicast_enabled;
        meta.ipv4_metadata.ipv4_urpf_mode = ipv4_urpf_mode;
        meta.ipv6_metadata.ipv6_urpf_mode = ipv6_urpf_mode;
        meta.l3_metadata.rmac_group = rmac_group;
        meta.multicast_metadata.igmp_snooping_enabled = igmp_snooping_enabled;
        meta.multicast_metadata.mld_snooping_enabled = mld_snooping_enabled;
        meta.multicast_metadata.ipv4_multicast_enabled = ipv4_multicast_enabled;
        meta.multicast_metadata.ipv6_multicast_enabled = ipv6_multicast_enabled;
        meta.multicast_metadata.bd_mrpf_group = mrpf_group;
        meta.multicast_metadata.ipv4_mcast_key_type = ipv4_mcast_key_type;
        meta.multicast_metadata.ipv4_mcast_key = ipv4_mcast_key;
        meta.multicast_metadata.ipv6_mcast_key_type = ipv6_mcast_key_type;
        meta.multicast_metadata.ipv6_mcast_key = ipv6_mcast_key;
        hdr.ig_intr_md_for_tm.rid = ingress_rid;
    }
    @name(".port_vlan_mapping_miss") action port_vlan_mapping_miss() {
        meta.l2_metadata.port_vlan_mapping_miss = 1w1;
    }
    @name("adjust_lkp_fields") table adjust_lkp_fields {
        actions = {
            non_ip_lkp;
            ipv4_lkp;
        }
        key = {
            hdr.ipv4.isValid(): exact;
            hdr.ipv6.isValid(): exact;
        }
    }
    @name("port_vlan_mapping") table port_vlan_mapping {
        actions = {
            set_bd_properties;
            port_vlan_mapping_miss;
        }
        key = {
            meta.ingress_metadata.ifindex: exact;
            hdr.vlan_tag_[0].isValid()   : exact;
            hdr.vlan_tag_[0].vid         : exact;
            hdr.vlan_tag_[1].isValid()   : exact;
            hdr.vlan_tag_[1].vid         : exact;
        }
        size = 32768;
        @name("bd_action_profile") implementation = action_profile(32w16384);
    }
    apply {
        port_vlan_mapping.apply();
        adjust_lkp_fields.apply();
    }
}

control process_spanning_tree(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_stp_state") action set_stp_state(bit<3> stp_state) {
        meta.l2_metadata.stp_state = stp_state;
    }
    @ternary(1) @name("spanning_tree") table spanning_tree {
        actions = {
            set_stp_state;
        }
        key = {
            meta.ingress_metadata.ifindex: exact;
            meta.l2_metadata.stp_group   : exact;
        }
        size = 4096;
    }
    apply {
        if (meta.ingress_metadata.port_type == 2w0 && meta.l2_metadata.stp_group != 10w0) {
            spanning_tree.apply();
        }
    }
}

control process_ingress_qos_map(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ip_sourceguard(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ingress_sflow(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ingress_fabric(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".terminate_cpu_packet") action terminate_cpu_packet() {
        hdr.ig_intr_md_for_tm.ucast_egress_port = (bit<9>)hdr.fabric_header.dstPortOrGroup;
        meta.egress_metadata.bypass = hdr.fabric_header_cpu.txBypass;
        hdr.ethernet.etherType = hdr.fabric_payload_header.etherType;
        hdr.fabric_header.setInvalid();
        hdr.fabric_header_cpu.setInvalid();
        hdr.fabric_payload_header.setInvalid();
    }
    @ternary(1) @name("fabric_ingress_dst_lkp") table fabric_ingress_dst_lkp {
        actions = {
            nop;
            terminate_cpu_packet;
        }
        key = {
            hdr.fabric_header.dstDevice: exact;
        }
    }
    apply {
        if (meta.ingress_metadata.port_type != 2w0) {
            fabric_ingress_dst_lkp.apply();
        }
    }
}

control process_tunnel(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("process_ingress_fabric") process_ingress_fabric() process_ingress_fabric_0;
    apply {
        process_ingress_fabric_0.apply(hdr, meta, standard_metadata);
    }
}

control process_storm_control(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_bfd_packet(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_validate_packet(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_unicast") action set_unicast() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
    }
    @name(".set_unicast_and_ipv6_src_is_link_local") action set_unicast_and_ipv6_src_is_link_local() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.ipv6_metadata.ipv6_src_is_link_local = 1w1;
    }
    @name(".set_multicast") action set_multicast() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.bd_stats_idx = meta.l2_metadata.bd_stats_idx + 16w1;
    }
    @name(".set_multicast_and_ipv6_src_is_link_local") action set_multicast_and_ipv6_src_is_link_local() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.ipv6_metadata.ipv6_src_is_link_local = 1w1;
        meta.l2_metadata.bd_stats_idx = meta.l2_metadata.bd_stats_idx + 16w1;
    }
    @name(".set_broadcast") action set_broadcast() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.bd_stats_idx = meta.l2_metadata.bd_stats_idx + 16w2;
    }
    @name(".set_malformed_packet") action set_malformed_packet(bit<8> drop_reason) {
        meta.ingress_metadata.drop_flag = 1w1;
        meta.ingress_metadata.drop_reason = drop_reason;
    }
    @name("validate_packet") table validate_packet {
        actions = {
            nop;
            set_unicast;
            set_unicast_and_ipv6_src_is_link_local;
            set_multicast;
            set_multicast_and_ipv6_src_is_link_local;
            set_broadcast;
            set_malformed_packet;
        }
        key = {
            meta.l2_metadata.lkp_mac_sa          : ternary;
            meta.l2_metadata.lkp_mac_da          : ternary;
            meta.l3_metadata.lkp_ip_type         : ternary;
            meta.l3_metadata.lkp_ip_ttl          : ternary;
            meta.l3_metadata.lkp_ip_version      : ternary;
            meta.ipv4_metadata.lkp_ipv4_sa[31:24]: ternary;
        }
        size = 64;
    }
    apply {
        if ((meta.ingress_metadata.bypass_lookups & 16w0x40) == 16w0 && meta.ingress_metadata.drop_flag == 1w0) {
            validate_packet.apply();
        }
    }
}

control process_ingress_l4port(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_mac(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".dmac_hit") action dmac_hit(bit<16> ifindex) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.l2_metadata.same_if_check = meta.l2_metadata.same_if_check ^ ifindex;
    }
    @name(".dmac_multicast_hit") action dmac_multicast_hit(bit<16> mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_b = mc_index;
    }
    @name(".dmac_miss") action dmac_miss() {
        meta.ingress_metadata.egress_ifindex = 16w65535;
    }
    @name(".dmac_redirect_nexthop") action dmac_redirect_nexthop(bit<16> nexthop_index) {
        meta.l2_metadata.l2_redirect = 1w1;
        meta.l2_metadata.l2_nexthop = nexthop_index;
        meta.l2_metadata.l2_nexthop_type = 2w0;
    }
    @name(".dmac_redirect_ecmp") action dmac_redirect_ecmp(bit<16> ecmp_index) {
        meta.l2_metadata.l2_redirect = 1w1;
        meta.l2_metadata.l2_nexthop = ecmp_index;
        meta.l2_metadata.l2_nexthop_type = 2w1;
    }
    @name(".dmac_drop") action dmac_drop() {
        mark_to_drop();
    }
    @name(".smac_miss") action smac_miss() {
        meta.l2_metadata.l2_src_miss = 1w1;
    }
    @name(".smac_hit") action smac_hit(bit<16> ifindex) {
        meta.l2_metadata.l2_src_move = meta.ingress_metadata.ifindex ^ ifindex;
    }
    @idletime_precision(2) @name("dmac") table dmac {
        support_timeout = true;
        actions = {
            nop;
            dmac_hit;
            dmac_multicast_hit;
            dmac_miss;
            dmac_redirect_nexthop;
            dmac_redirect_ecmp;
            dmac_drop;
        }
        key = {
            meta.ingress_metadata.bd   : exact;
            meta.l2_metadata.lkp_mac_da: exact;
        }
        size = 440000;
    }
    @name("smac") table smac {
        actions = {
            nop;
            smac_miss;
            smac_hit;
        }
        key = {
            meta.ingress_metadata.bd   : exact;
            meta.l2_metadata.lkp_mac_sa: exact;
        }
        size = 440000;
    }
    apply {
        if ((meta.ingress_metadata.bypass_lookups & 16w0x80) == 16w0 && meta.ingress_metadata.port_type == 2w0) {
            smac.apply();
        }
        if ((meta.ingress_metadata.bypass_lookups & 16w0x1) == 16w0) {
            dmac.apply();
        }
    }
}

control process_mac_acl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".acl_deny") action acl_deny(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_permit") action acl_permit(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_redirect_nexthop") action acl_redirect_nexthop(bit<16> nexthop_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = nexthop_index;
        meta.acl_metadata.acl_nexthop_type = 2w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_redirect_ecmp") action acl_redirect_ecmp(bit<16> ecmp_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = ecmp_index;
        meta.acl_metadata.acl_nexthop_type = 2w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name("mac_acl") table mac_acl {
        actions = {
            nop;
            acl_deny;
            acl_permit;
            acl_redirect_nexthop;
            acl_redirect_ecmp;
        }
        key = {
            meta.acl_metadata.if_label   : ternary;
            meta.acl_metadata.bd_label   : ternary;
            meta.l2_metadata.lkp_mac_sa  : ternary;
            meta.l2_metadata.lkp_mac_da  : ternary;
            meta.l2_metadata.lkp_mac_type: ternary;
        }
        size = 128;
    }
    apply {
        if ((meta.ingress_metadata.bypass_lookups & 16w0x4) == 16w0) {
            mac_acl.apply();
        }
    }
}

control process_ip_acl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".acl_deny") action acl_deny(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_permit") action acl_permit(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_redirect_nexthop") action acl_redirect_nexthop(bit<16> nexthop_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = nexthop_index;
        meta.acl_metadata.acl_nexthop_type = 2w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_redirect_ecmp") action acl_redirect_ecmp(bit<16> ecmp_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = ecmp_index;
        meta.acl_metadata.acl_nexthop_type = 2w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name("ip_acl") table ip_acl {
        actions = {
            nop;
            acl_deny;
            acl_permit;
            acl_redirect_nexthop;
            acl_redirect_ecmp;
        }
        key = {
            meta.acl_metadata.if_label                 : ternary;
            meta.acl_metadata.bd_label                 : ternary;
            meta.ipv4_metadata.lkp_ipv4_sa             : ternary;
            meta.ipv4_metadata.lkp_ipv4_da             : ternary;
            meta.l3_metadata.lkp_ip_proto              : ternary;
            meta.acl_metadata.ingress_src_port_range_id: exact;
            meta.acl_metadata.ingress_dst_port_range_id: exact;
            hdr.tcp.flags                              : ternary;
            meta.l3_metadata.lkp_ip_ttl                : ternary;
        }
        size = 128;
    }
    apply {
        if ((meta.ingress_metadata.bypass_lookups & 16w0x4) == 16w0) {
            if (meta.l3_metadata.lkp_ip_type == 2w1) {
                ip_acl.apply();
            }
            else {
                if (meta.l3_metadata.lkp_ip_type == 2w2) {
                }
            }
        }
    }
}

control process_int_upstream_report(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ipv4_racl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ipv4_urpf(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ipv4_fib(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
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

control process_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ingress_nat(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_int_sink_update_outer(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_meter_index(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_hashes(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".compute_lkp_ipv4_hash") action compute_lkp_ipv4_hash() {
        hash(meta.hash_metadata.hash1, HashAlgorithm.crc16, (bit<16>)0, { meta.ipv4_metadata.lkp_ipv4_sa, meta.ipv4_metadata.lkp_ipv4_da, meta.l3_metadata.lkp_ip_proto, meta.l3_metadata.lkp_l4_sport, meta.l3_metadata.lkp_l4_dport }, (bit<32>)65536);
        hash(meta.hash_metadata.hash2, HashAlgorithm.crc16, (bit<16>)0, { meta.l2_metadata.lkp_mac_sa, meta.l2_metadata.lkp_mac_da, meta.ipv4_metadata.lkp_ipv4_sa, meta.ipv4_metadata.lkp_ipv4_da, meta.l3_metadata.lkp_ip_proto, meta.l3_metadata.lkp_l4_sport, meta.l3_metadata.lkp_l4_dport }, (bit<32>)65536);
    }
    @name(".compute_lkp_non_ip_hash") action compute_lkp_non_ip_hash() {
        hash(meta.hash_metadata.hash2, HashAlgorithm.crc16, (bit<16>)0, { meta.ingress_metadata.ifindex, meta.l2_metadata.lkp_mac_sa, meta.l2_metadata.lkp_mac_da, meta.l2_metadata.lkp_mac_type }, (bit<32>)65536);
    }
    @name(".computed_two_hashes") action computed_two_hashes() {
        hdr.ig_intr_md_for_tm.level1_mcast_hash = (bit<13>)meta.hash_metadata.hash1;
        hdr.ig_intr_md_for_tm.level2_mcast_hash = (bit<13>)meta.hash_metadata.hash2;
        meta.hash_metadata.entropy_hash = meta.hash_metadata.hash2;
    }
    @name(".computed_one_hash") action computed_one_hash() {
        meta.hash_metadata.hash1 = meta.hash_metadata.hash2;
        hdr.ig_intr_md_for_tm.level1_mcast_hash = (bit<13>)meta.hash_metadata.hash2;
        hdr.ig_intr_md_for_tm.level2_mcast_hash = (bit<13>)meta.hash_metadata.hash2;
        meta.hash_metadata.entropy_hash = meta.hash_metadata.hash2;
    }
    @name("compute_ipv4_hashes") table compute_ipv4_hashes {
        actions = {
            compute_lkp_ipv4_hash;
        }
        key = {
            hdr.ethernet.isValid(): exact;
        }
    }
    @name("compute_non_ip_hashes") table compute_non_ip_hashes {
        actions = {
            compute_lkp_non_ip_hash;
        }
        key = {
            hdr.ethernet.isValid(): exact;
        }
    }
    @ternary(1) @name("compute_other_hashes") table compute_other_hashes {
        actions = {
            computed_two_hashes;
            computed_one_hash;
        }
        key = {
            meta.hash_metadata.hash1: exact;
        }
    }
    apply {
        if (meta.tunnel_metadata.tunnel_terminate == 1w0 && hdr.ipv4.isValid() || meta.tunnel_metadata.tunnel_terminate == 1w1 && hdr.inner_ipv4.isValid()) {
            compute_ipv4_hashes.apply();
        }
        else {
            compute_non_ip_hashes.apply();
        }
        compute_other_hashes.apply();
    }
}

control process_meter_action(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ingress_bd_stats(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("ingress_bd_stats") @min_width(32) counter(32w16384, CounterType.packets_and_bytes) ingress_bd_stats;
    @name(".update_ingress_bd_stats") action update_ingress_bd_stats() {
        ingress_bd_stats.count((bit<32>)(bit<14>)meta.l2_metadata.bd_stats_idx);
    }
    @name("ingress_bd_stats") table ingress_bd_stats_0 {
        actions = {
            update_ingress_bd_stats;
        }
        size = 16384;
    }
    apply {
        ingress_bd_stats_0.apply();
    }
}

control process_ingress_acl_stats(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("acl_stats") @min_width(16) counter(32w128, CounterType.packets_and_bytes) acl_stats;
    @name(".acl_stats_update") action acl_stats_update() {
        acl_stats.count((bit<32>)(bit<7>)meta.acl_metadata.acl_stats_index);
    }
    @name("acl_stats") table acl_stats_0 {
        actions = {
            acl_stats_update;
        }
        size = 128;
    }
    apply {
        acl_stats_0.apply();
    }
}

control process_storm_control_stats(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_fwd_results(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_l2_redirect_action") action set_l2_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.l2_metadata.l2_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.l2_metadata.l2_nexthop_type;
        meta.ingress_metadata.egress_ifindex = 16w0;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".set_fib_redirect_action") action set_fib_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.l3_metadata.fib_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.l3_metadata.fib_nexthop_type;
        meta.l3_metadata.routed = 1w1;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
        meta.fabric_metadata.reason_code = 16w0x217;
    }
    @name(".set_cpu_redirect_action") action set_cpu_redirect_action() {
        meta.l3_metadata.routed = 1w0;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w64;
        meta.ingress_metadata.egress_ifindex = 16w0;
    }
    @name(".set_acl_redirect_action") action set_acl_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.acl_metadata.acl_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.acl_metadata.acl_nexthop_type;
        meta.ingress_metadata.egress_ifindex = 16w0;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".set_racl_redirect_action") action set_racl_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.acl_metadata.racl_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.acl_metadata.racl_nexthop_type;
        meta.l3_metadata.routed = 1w1;
        meta.ingress_metadata.egress_ifindex = 16w0;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name("fwd_result") table fwd_result {
        actions = {
            nop;
            set_l2_redirect_action;
            set_fib_redirect_action;
            set_cpu_redirect_action;
            set_acl_redirect_action;
            set_racl_redirect_action;
        }
        key = {
            meta.l2_metadata.l2_redirect                 : ternary;
            meta.acl_metadata.acl_redirect               : ternary;
            meta.acl_metadata.racl_redirect              : ternary;
            meta.l3_metadata.rmac_hit                    : ternary;
            meta.l3_metadata.fib_hit                     : ternary;
            meta.nat_metadata.nat_hit                    : ternary;
            meta.l2_metadata.lkp_pkt_type                : ternary;
            meta.l3_metadata.lkp_ip_type                 : ternary;
            meta.multicast_metadata.igmp_snooping_enabled: ternary;
            meta.multicast_metadata.mld_snooping_enabled : ternary;
            meta.multicast_metadata.mcast_route_hit      : ternary;
            meta.multicast_metadata.mcast_bridge_hit     : ternary;
            meta.multicast_metadata.mcast_rpf_group      : ternary;
            meta.multicast_metadata.mcast_mode           : ternary;
        }
        size = 512;
    }
    apply {
        if (!(meta.ingress_metadata.bypass_lookups == 16w0xffff)) {
            fwd_result.apply();
        }
    }
}

control process_nexthop(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_ecmp_nexthop_details") action set_ecmp_nexthop_details(bit<16> ifindex, bit<14> bd, bit<16> nhop_index, bit<1> tunnel) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.l3_metadata.nexthop_index = nhop_index;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.l2_metadata.same_if_check = meta.l2_metadata.same_if_check ^ ifindex;
        meta.tunnel_metadata.tunnel_if_check = meta.tunnel_metadata.tunnel_terminate ^ tunnel;
        hdr.ig_intr_md_for_tm.disable_ucast_cutthru = meta.l2_metadata.non_ip_packet & tunnel;
    }
    @name(".set_ecmp_nexthop_details_for_post_routed_flood") action set_ecmp_nexthop_details_for_post_routed_flood(bit<14> bd, bit<16> uuc_mc_index, bit<16> nhop_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_b = uuc_mc_index;
        meta.l3_metadata.nexthop_index = nhop_index;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
    }
    @name(".set_nexthop_details") action set_nexthop_details(bit<16> ifindex, bit<14> bd, bit<1> tunnel) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.l2_metadata.same_if_check = meta.l2_metadata.same_if_check ^ ifindex;
        meta.tunnel_metadata.tunnel_if_check = meta.tunnel_metadata.tunnel_terminate ^ tunnel;
        hdr.ig_intr_md_for_tm.disable_ucast_cutthru = meta.l2_metadata.non_ip_packet & tunnel;
    }
    @name(".set_nexthop_details_for_post_routed_flood") action set_nexthop_details_for_post_routed_flood(bit<14> bd, bit<16> uuc_mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_b = uuc_mc_index;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
    }
    @name("ecmp_group") table ecmp_group {
        actions = {
            nop;
            set_ecmp_nexthop_details;
            set_ecmp_nexthop_details_for_post_routed_flood;
        }
        key = {
            meta.l3_metadata.nexthop_index: exact;
            meta.hash_metadata.hash1      : selector;
        }
        size = 1024;
        @name("ecmp_action_profile") @mode("fair") implementation = action_selector(HashAlgorithm.identity, 32w16384, 32w14);
    }
    @name("nexthop") table nexthop {
        actions = {
            nop;
            set_nexthop_details;
            set_nexthop_details_for_post_routed_flood;
        }
        key = {
            meta.l3_metadata.nexthop_index: exact;
        }
        size = 16384;
    }
    apply {
        if (meta.nexthop_metadata.nexthop_type == 2w1) {
            ecmp_group.apply();
        }
        else {
            nexthop.apply();
        }
    }
}

control process_wcmp(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_multicast_flooding(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_lag(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_lag_miss") action set_lag_miss() {
    }
    @name(".set_lag_port") action set_lag_port(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name("lag_group") table lag_group {
        actions = {
            set_lag_miss;
            set_lag_port;
        }
        key = {
            meta.ingress_metadata.egress_ifindex: exact;
            meta.hash_metadata.hash2            : selector;
        }
        size = 1024;
        @name("lag_action_profile") @mode("fair") implementation = action_selector(HashAlgorithm.identity, 32w1024, 32w14);
    }
    apply {
        lag_group.apply();
    }
}

@name("mac_learn_digest") struct mac_learn_digest {
    bit<14> bd;
    bit<48> lkp_mac_sa;
    bit<16> ifindex;
}

control process_mac_learning(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".generate_learn_notify") action generate_learn_notify() {
        digest<mac_learn_digest>((bit<32>)0, { meta.ingress_metadata.bd, meta.l2_metadata.lkp_mac_sa, meta.ingress_metadata.ifindex });
    }
    @name("learn_notify") table learn_notify {
        actions = {
            nop;
            generate_learn_notify;
        }
        key = {
            meta.l2_metadata.l2_src_miss: ternary;
            meta.l2_metadata.l2_src_move: ternary;
            meta.l2_metadata.stp_state  : ternary;
        }
        size = 512;
    }
    apply {
        if (meta.l2_metadata.learning_enabled == 1w1) {
            learn_notify.apply();
        }
    }
}

control process_fabric_lag(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_traffic_class(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_system_acl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("drop_stats") counter(32w256, CounterType.packets) drop_stats;
    @name("drop_stats_2") counter(32w256, CounterType.packets) drop_stats_2;
    @name(".drop_stats_update") action drop_stats_update() {
        drop_stats_2.count((bit<32>)meta.ingress_metadata.drop_reason);
    }
    @name(".nop") action nop() {
    }
    @name(".copy_to_cpu") action copy_to_cpu(bit<5> qid, bit<8> meter_id, bit<3> icos) {
        hdr.ig_intr_md_for_tm.qid = qid;
        hdr.ig_intr_md_for_tm.ingress_cos = icos;
        hdr.ig_intr_md_for_tm.copy_to_cpu = 1w1;
    }
    @name(".redirect_to_cpu") action redirect_to_cpu(bit<5> qid, bit<8> meter_id, bit<3> icos) {
        copy_to_cpu(qid, meter_id, icos);
        mark_to_drop();
    }
    @name(".copy_to_cpu_with_reason") action copy_to_cpu_with_reason(bit<16> reason_code, bit<5> qid, bit<8> meter_id, bit<3> icos) {
        meta.fabric_metadata.reason_code = reason_code;
        copy_to_cpu(qid, meter_id, icos);
    }
    @name(".redirect_to_cpu_with_reason") action redirect_to_cpu_with_reason(bit<16> reason_code, bit<5> qid, bit<8> meter_id, bit<3> icos) {
        copy_to_cpu_with_reason(reason_code, qid, meter_id, icos);
        mark_to_drop();
    }
    @name(".drop_packet") action drop_packet() {
        mark_to_drop();
    }
    @name(".drop_packet_with_reason") action drop_packet_with_reason(bit<8> drop_reason) {
        drop_stats.count((bit<32>)drop_reason);
        mark_to_drop();
    }
    @name("drop_stats") table drop_stats_0 {
        actions = {
            drop_stats_update;
        }
        size = 256;
    }
    @name("system_acl") table system_acl {
        actions = {
            nop;
            redirect_to_cpu;
            redirect_to_cpu_with_reason;
            copy_to_cpu;
            copy_to_cpu_with_reason;
            drop_packet;
            drop_packet_with_reason;
        }
        key = {
            meta.acl_metadata.if_label               : ternary;
            meta.acl_metadata.bd_label               : ternary;
            meta.ingress_metadata.ifindex            : ternary;
            meta.l2_metadata.lkp_mac_type            : ternary;
            meta.l2_metadata.port_vlan_mapping_miss  : ternary;
            meta.security_metadata.ipsg_check_fail   : ternary;
            meta.acl_metadata.acl_deny               : ternary;
            meta.acl_metadata.racl_deny              : ternary;
            meta.l3_metadata.urpf_check_fail         : ternary;
            meta.ingress_metadata.drop_flag          : ternary;
            meta.l3_metadata.l3_copy                 : ternary;
            meta.l3_metadata.rmac_hit                : ternary;
            meta.l3_metadata.routed                  : ternary;
            meta.ipv6_metadata.ipv6_src_is_link_local: ternary;
            meta.l2_metadata.same_if_check           : ternary;
            meta.tunnel_metadata.tunnel_if_check     : ternary;
            meta.l3_metadata.same_bd_check           : ternary;
            meta.l3_metadata.lkp_ip_ttl              : ternary;
            meta.l2_metadata.stp_state               : ternary;
            meta.ingress_metadata.control_frame      : ternary;
            meta.ipv4_metadata.ipv4_unicast_enabled  : ternary;
            meta.ipv6_metadata.ipv6_unicast_enabled  : ternary;
            meta.ingress_metadata.egress_ifindex     : ternary;
            meta.fabric_metadata.reason_code         : ternary;
        }
        size = 512;
    }
    apply {
        if ((meta.ingress_metadata.bypass_lookups & 16w0x20) == 16w0) {
            system_acl.apply();
            if (meta.ingress_metadata.drop_flag == 1w1) {
                drop_stats_0.apply();
            }
        }
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @pa_atomic("ingress", "l3_metadata.lkp_ip_version") @pa_solitary("ingress", "l3_metadata.lkp_ip_version") @name(".rmac_hit") action rmac_hit() {
        meta.l3_metadata.rmac_hit = 1w1;
    }
    @name(".rmac_miss") action rmac_miss() {
        meta.l3_metadata.rmac_hit = 1w0;
    }
    @ternary(1) @name("rmac") table rmac {
        actions = {
            rmac_hit;
            rmac_miss;
        }
        key = {
            meta.l3_metadata.rmac_group: exact;
            meta.l2_metadata.lkp_mac_da: exact;
        }
        size = 512;
    }
    @name("process_ingress_port_mapping") process_ingress_port_mapping() process_ingress_port_mapping_0;
    @name("process_global_params") process_global_params() process_global_params_0;
    @name("process_validate_outer_header") process_validate_outer_header() process_validate_outer_header_0;
    @name("process_int_endpoint") process_int_endpoint() process_int_endpoint_0;
    @name("process_bfd_rx_packet") process_bfd_rx_packet() process_bfd_rx_packet_0;
    @name("process_port_vlan_mapping") process_port_vlan_mapping() process_port_vlan_mapping_0;
    @name("process_spanning_tree") process_spanning_tree() process_spanning_tree_0;
    @name("process_ingress_qos_map") process_ingress_qos_map() process_ingress_qos_map_0;
    @name("process_ip_sourceguard") process_ip_sourceguard() process_ip_sourceguard_0;
    @name("process_ingress_sflow") process_ingress_sflow() process_ingress_sflow_0;
    @name("process_tunnel") process_tunnel() process_tunnel_0;
    @name("process_storm_control") process_storm_control() process_storm_control_0;
    @name("process_bfd_packet") process_bfd_packet() process_bfd_packet_0;
    @name("process_validate_packet") process_validate_packet() process_validate_packet_0;
    @name("process_ingress_l4port") process_ingress_l4port() process_ingress_l4port_0;
    @name("process_mac") process_mac() process_mac_0;
    @name("process_mac_acl") process_mac_acl() process_mac_acl_0;
    @name("process_ip_acl") process_ip_acl() process_ip_acl_0;
    @name("process_int_upstream_report") process_int_upstream_report() process_int_upstream_report_0;
    @name("process_ipv4_racl") process_ipv4_racl() process_ipv4_racl_0;
    @name("process_ipv4_urpf") process_ipv4_urpf() process_ipv4_urpf_0;
    @name("process_ipv4_fib") process_ipv4_fib() process_ipv4_fib_0;
    @name("process_ipv6_racl") process_ipv6_racl() process_ipv6_racl_0;
    @name("process_ipv6_urpf") process_ipv6_urpf() process_ipv6_urpf_0;
    @name("process_ipv6_fib") process_ipv6_fib() process_ipv6_fib_0;
    @name("process_urpf_bd") process_urpf_bd() process_urpf_bd_0;
    @name("process_multicast") process_multicast() process_multicast_0;
    @name("process_ingress_nat") process_ingress_nat() process_ingress_nat_0;
    @name("process_int_sink_update_outer") process_int_sink_update_outer() process_int_sink_update_outer_0;
    @name("process_meter_index") process_meter_index() process_meter_index_0;
    @name("process_hashes") process_hashes() process_hashes_0;
    @name("process_meter_action") process_meter_action() process_meter_action_0;
    @name("process_ingress_bd_stats") process_ingress_bd_stats() process_ingress_bd_stats_0;
    @name("process_ingress_acl_stats") process_ingress_acl_stats() process_ingress_acl_stats_0;
    @name("process_storm_control_stats") process_storm_control_stats() process_storm_control_stats_0;
    @name("process_fwd_results") process_fwd_results() process_fwd_results_0;
    @name("process_nexthop") process_nexthop() process_nexthop_0;
    @name("process_wcmp") process_wcmp() process_wcmp_0;
    @name("process_multicast_flooding") process_multicast_flooding() process_multicast_flooding_0;
    @name("process_lag") process_lag() process_lag_0;
    @name("process_mac_learning") process_mac_learning() process_mac_learning_0;
    @name("process_fabric_lag") process_fabric_lag() process_fabric_lag_0;
    @name("process_traffic_class") process_traffic_class() process_traffic_class_0;
    @name("process_system_acl") process_system_acl() process_system_acl_0;
    apply {
        process_ingress_port_mapping_0.apply(hdr, meta, standard_metadata);
        process_global_params_0.apply(hdr, meta, standard_metadata);
        process_validate_outer_header_0.apply(hdr, meta, standard_metadata);
        process_int_endpoint_0.apply(hdr, meta, standard_metadata);
        process_bfd_rx_packet_0.apply(hdr, meta, standard_metadata);
        process_port_vlan_mapping_0.apply(hdr, meta, standard_metadata);
        process_spanning_tree_0.apply(hdr, meta, standard_metadata);
        process_ingress_qos_map_0.apply(hdr, meta, standard_metadata);
        process_ip_sourceguard_0.apply(hdr, meta, standard_metadata);
        process_ingress_sflow_0.apply(hdr, meta, standard_metadata);
        process_tunnel_0.apply(hdr, meta, standard_metadata);
        process_storm_control_0.apply(hdr, meta, standard_metadata);
        process_bfd_packet_0.apply(hdr, meta, standard_metadata);
        if (meta.ingress_metadata.port_type != 2w1) {
            process_validate_packet_0.apply(hdr, meta, standard_metadata);
            process_ingress_l4port_0.apply(hdr, meta, standard_metadata);
            process_mac_0.apply(hdr, meta, standard_metadata);
            if (meta.l3_metadata.lkp_ip_type == 2w0) {
                process_mac_acl_0.apply(hdr, meta, standard_metadata);
            }
            else {
                process_ip_acl_0.apply(hdr, meta, standard_metadata);
            }
            process_int_upstream_report_0.apply(hdr, meta, standard_metadata);
            switch (rmac.apply().action_run) {
                default: {
                    if ((meta.ingress_metadata.bypass_lookups & 16w0x2) == 16w0) {
                        if (meta.l3_metadata.lkp_ip_type == 2w1 && meta.ipv4_metadata.ipv4_unicast_enabled == 1w1) {
                            process_ipv4_racl_0.apply(hdr, meta, standard_metadata);
                            process_ipv4_urpf_0.apply(hdr, meta, standard_metadata);
                            process_ipv4_fib_0.apply(hdr, meta, standard_metadata);
                        }
                        else {
                            if (meta.l3_metadata.lkp_ip_type == 2w2 && meta.ipv6_metadata.ipv6_unicast_enabled == 1w1) {
                                process_ipv6_racl_0.apply(hdr, meta, standard_metadata);
                                process_ipv6_urpf_0.apply(hdr, meta, standard_metadata);
                                process_ipv6_fib_0.apply(hdr, meta, standard_metadata);
                            }
                        }
                        process_urpf_bd_0.apply(hdr, meta, standard_metadata);
                    }
                }
                rmac_miss: {
                    process_multicast_0.apply(hdr, meta, standard_metadata);
                }
            }

            process_ingress_nat_0.apply(hdr, meta, standard_metadata);
        }
        process_int_sink_update_outer_0.apply(hdr, meta, standard_metadata);
        process_meter_index_0.apply(hdr, meta, standard_metadata);
        process_hashes_0.apply(hdr, meta, standard_metadata);
        process_meter_action_0.apply(hdr, meta, standard_metadata);
        if (meta.ingress_metadata.port_type != 2w1) {
            process_ingress_bd_stats_0.apply(hdr, meta, standard_metadata);
            process_ingress_acl_stats_0.apply(hdr, meta, standard_metadata);
            process_storm_control_stats_0.apply(hdr, meta, standard_metadata);
            process_fwd_results_0.apply(hdr, meta, standard_metadata);
            process_nexthop_0.apply(hdr, meta, standard_metadata);
            process_wcmp_0.apply(hdr, meta, standard_metadata);
            if (meta.ingress_metadata.egress_ifindex == 16w65535) {
                process_multicast_flooding_0.apply(hdr, meta, standard_metadata);
            }
            else {
                process_lag_0.apply(hdr, meta, standard_metadata);
            }
            process_mac_learning_0.apply(hdr, meta, standard_metadata);
        }
        process_fabric_lag_0.apply(hdr, meta, standard_metadata);
        process_traffic_class_0.apply(hdr, meta, standard_metadata);
        if (meta.ingress_metadata.port_type != 2w1) {
            process_system_acl_0.apply(hdr, meta, standard_metadata);
        }
    }
}

control process_bfd_tx_packet(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_egress_bfd_tx_timers(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_flowlet(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("flowlet_state") register<bit<64>>(32w8192) flowlet_state;
    stateful_alu() flowlet_alu;
    @name(".flowlet_lookup") action flowlet_lookup() {
        flowlet_alu.execute_stateful_alu_from_hash({ meta.hash_metadata.hash1 });
    }
    @name("flowlet") table flowlet {
        actions = {
            flowlet_lookup;
        }
        size = 1;
    }
    apply {
        if (meta.flowlet_metadata.inactive_timeout != 32w0) {
            flowlet.apply();
        }
    }
}

control process_int_insertion(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ipv4_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ipv4_vtep(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ipv6_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ipv6_vtep(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_multicast_rpf(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_outer_ipv4_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_outer_ipv6_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_outer_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_outer_multicast_rpf(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_pktgen(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_pktgen_port_down(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_plt_insertion(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control validate_mpls_header(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.fabric_header);
        packet.emit(hdr.fabric_header_cpu);
        packet.emit(hdr.fabric_payload_header);
        packet.emit(hdr.llc_header);
        packet.emit(hdr.snap_header);
        packet.emit(hdr.vlan_tag_[0]);
        packet.emit(hdr.vlan_tag_[1]);
        packet.emit(hdr.ipv6);
        packet.emit(hdr.inner_ipv4);
        packet.emit(hdr.inner_udp);
        packet.emit(hdr.inner_tcp);
        packet.emit(hdr.inner_icmp);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.tcp);
        packet.emit(hdr.icmp);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta) {
    Checksum16() inner_ipv4_checksum;
    Checksum16() ipv4_checksum;
    apply {
        if (hdr.inner_ipv4.hdrChecksum == inner_ipv4_checksum.get({ hdr.inner_ipv4.version, hdr.inner_ipv4.ihl, hdr.inner_ipv4.diffserv, hdr.inner_ipv4.totalLen, hdr.inner_ipv4.identification, hdr.inner_ipv4.flags, hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.ttl, hdr.inner_ipv4.protocol, hdr.inner_ipv4.srcAddr, hdr.inner_ipv4.dstAddr })) 
            mark_to_drop();
        if (hdr.ipv4.hdrChecksum == ipv4_checksum.get({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr })) 
            mark_to_drop();
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    Checksum16() inner_ipv4_checksum;
    Checksum16() ipv4_checksum;
    apply {
        hdr.inner_ipv4.hdrChecksum = inner_ipv4_checksum.get({ hdr.inner_ipv4.version, hdr.inner_ipv4.ihl, hdr.inner_ipv4.diffserv, hdr.inner_ipv4.totalLen, hdr.inner_ipv4.identification, hdr.inner_ipv4.flags, hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.ttl, hdr.inner_ipv4.protocol, hdr.inner_ipv4.srcAddr, hdr.inner_ipv4.dstAddr });
        hdr.ipv4.hdrChecksum = ipv4_checksum.get({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr });
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
