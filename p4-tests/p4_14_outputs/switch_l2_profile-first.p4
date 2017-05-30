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

struct egress_intrinsic_metadata_t {
    bit<9>  egress_port;
    bit<19> enq_qdepth;
    bit<2>  enq_congest_stat;
    bit<32> enq_tstamp;
    bit<19> deq_qdepth;
    bit<2>  deq_congest_stat;
    bit<8>  app_pool_congest_stat;
    bit<32> deq_timedelta;
    bit<16> egress_rid;
    bit<1>  egress_rid_first;
    bit<5>  egress_qid;
    bit<3>  egress_cos;
    bit<1>  deflection_flag;
}

struct egress_intrinsic_metadata_from_parser_aux_t {
    bit<8>  clone_src;
    bit<48> egress_global_tstamp;
}

struct egress_filter_metadata_t {
    bit<16> ifindex_check;
    bit<14> bd;
    bit<14> inner_bd;
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
    bit<8>  dst_device;
    bit<16> dst_port;
}

struct flowlet_metadata_t {
    bit<16> id;
    bit<32> inactive_timeout;
    bit<32> timestamp;
    bit<13> map_index;
    bit<32> inter_packet_gap;
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

struct ingress_intrinsic_metadata_t {
    bit<1>  resubmit_flag;
    bit<9>  ingress_port;
    bit<48> ingress_global_tstamp;
    bit<32> lf_field_list;
}

struct ingress_intrinsic_metadata_for_tm_t {
    bit<9>  ucast_egress_port;
    bit<3>  drop_ctl;
    bit<16> mcast_grp_a;
    bit<16> mcast_grp_b;
    bit<13> level1_mcast_hash;
    bit<13> level2_mcast_hash;
    bit<16> level1_exclusion_id;
    bit<9>  level2_exclusion_id;
    bit<16> rid;
    bit<1>  deflect_on_drop;
    bit<3>  ingress_cos;
    bit<5>  qid;
    bit<2>  packet_color;
    bit<1>  disable_ucast_cutthru;
    bit<1>  enable_mcast_cutthru;
}

struct ingress_parser_control_signals {
    bit<3> priority;
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

struct int_metadata_t {
    bit<8>  insert_cnt;
    bit<16> remove_byte_cnt;
    bit<16> insert_byte_cnt;
    bit<8>  int_hdr_word_len;
    bit<2>  hit_state;
    bit<32> quantized_latency;
}

struct int_metadata_i2e_t {
    bit<1> source;
    bit<1> plt_source;
    bit<1> sink;
    bit<1> report;
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
    bit<16> mcast_grp_a;
    bit<16> mcast_grp_b;
    bit<16> ingress_rid;
    bit<16> l1_exclusion_id;
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

header int_egress_port_id_header_t {
    bit<1>  bos;
    bit<31> egress_port_id;
}

header int_egress_port_tx_utilization_header_t {
    bit<1>  bos;
    bit<31> egress_port_tx_utilization;
}

header int_header_t {
    bit<2>  ver;
    bit<2>  rep;
    bit<1>  c;
    bit<1>  e;
    bit<5>  rsvd1;
    bit<5>  ins_cnt;
    bit<8>  max_hop_cnt;
    bit<8>  total_hop_cnt;
    bit<4>  instruction_mask_0003;
    bit<4>  instruction_mask_0407;
    bit<4>  instruction_mask_0811;
    bit<4>  instruction_mask_1215;
    bit<16> rsvd2;
}

header int_hop_latency_header_t {
    bit<1>  bos;
    bit<31> hop_latency;
}

header int_ingress_port_id_header_t {
    bit<1>  bos;
    bit<15> ingress_port_id_1;
    bit<16> ingress_port_id_0;
}

header int_ingress_tstamp_header_t {
    bit<1>  bos;
    bit<31> ingress_tstamp;
}

header int_plt_header_t {
    bit<32> pl_encoding;
}

header int_port_ids_header_t {
    bit<1>  bos;
    bit<6>  pad_1;
    bit<9>  ingress_port_id;
    bit<16> egress_port_id;
}

header int_q_congestion_header_t {
    bit<1>  bos;
    bit<31> q_congestion;
}

header int_q_occupancy_header_t {
    bit<1>  bos;
    bit<7>  q_occupancy1;
    bit<24> q_occupancy0;
}

header int_switch_id_header_t {
    bit<1>  bos;
    bit<31> switch_id;
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

header vxlan_gpe_t {
    bit<8>  flags;
    bit<16> reserved;
    bit<8>  next_proto;
    bit<24> vni;
    bit<8>  reserved2;
}

header vxlan_gpe_int_header_t {
    bit<8> int_type;
    bit<8> rsvd;
    bit<8> len;
    bit<8> next_proto;
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
    acl_metadata_t                              acl_metadata;
    @name("eg_intr_md") 
    egress_intrinsic_metadata_t                 eg_intr_md;
    @name("eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t eg_intr_md_from_parser_aux;
    @name("egress_filter_metadata") 
    egress_filter_metadata_t                    egress_filter_metadata;
    @name("egress_metadata") 
    egress_metadata_t                           egress_metadata;
    @name("fabric_metadata") 
    fabric_metadata_t                           fabric_metadata;
    @name("flowlet_metadata") 
    flowlet_metadata_t                          flowlet_metadata;
    @name("global_config_metadata") 
    global_config_metadata_t                    global_config_metadata;
    @pa_atomic("ingress", "hash_metadata.hash1") @pa_solitary("ingress", "hash_metadata.hash1") @pa_atomic("ingress", "hash_metadata.hash2") @pa_solitary("ingress", "hash_metadata.hash2") @name("hash_metadata") 
    hash_metadata_t                             hash_metadata;
    @name("i2e_metadata") 
    i2e_metadata_t                              i2e_metadata;
    @name("ig_intr_md") 
    ingress_intrinsic_metadata_t                ig_intr_md;
    @name("ig_intr_md_for_tm") 
    ingress_intrinsic_metadata_for_tm_t         ig_intr_md_for_tm;
    @name("ig_prsr_ctrl") 
    ingress_parser_control_signals              ig_prsr_ctrl;
    @pa_atomic("ingress", "ingress_metadata.port_type") @pa_solitary("ingress", "ingress_metadata.port_type") @pa_atomic("ingress", "ingress_metadata.ifindex") @pa_solitary("ingress", "ingress_metadata.ifindex") @pa_atomic("egress", "ingress_metadata.bd") @pa_solitary("egress", "ingress_metadata.bd") @name("ingress_metadata") 
    ingress_metadata_t                          ingress_metadata;
    @name("int_metadata") 
    int_metadata_t                              int_metadata;
    @name("int_metadata_i2e") 
    int_metadata_i2e_t                          int_metadata_i2e;
    @name("intrinsic_metadata") 
    intrinsic_metadata_t                        intrinsic_metadata;
    @name("ipv4_metadata") 
    ipv4_metadata_t                             ipv4_metadata;
    @name("ipv6_metadata") 
    ipv6_metadata_t                             ipv6_metadata;
    @name("l2_metadata") 
    l2_metadata_t                               l2_metadata;
    @name("l3_metadata") 
    l3_metadata_t                               l3_metadata;
    @name("meter_metadata") 
    meter_metadata_t                            meter_metadata;
    @name("multicast_metadata") 
    multicast_metadata_t                        multicast_metadata;
    @name("nat_metadata") 
    nat_metadata_t                              nat_metadata;
    @name("nexthop_metadata") 
    nexthop_metadata_t                          nexthop_metadata;
    @name("qos_metadata") 
    qos_metadata_t                              qos_metadata;
    @name("security_metadata") 
    security_metadata_t                         security_metadata;
    @name("tunnel_metadata") 
    tunnel_metadata_t                           tunnel_metadata;
}

struct headers {
    @name("eompls") 
    eompls_t                                eompls;
    @name("erspan_t3_header") 
    erspan_header_t3_t_0                    erspan_t3_header;
    @name("ethernet") 
    ethernet_t                              ethernet;
    @name("fabric_header") 
    fabric_header_t                         fabric_header;
    @name("fabric_header_bfd") 
    fabric_header_bfd_event_t               fabric_header_bfd;
    @name("fabric_header_cpu") 
    fabric_header_cpu_t                     fabric_header_cpu;
    @name("fabric_header_mirror") 
    fabric_header_mirror_t                  fabric_header_mirror;
    @name("fabric_header_multicast") 
    fabric_header_multicast_t               fabric_header_multicast;
    @name("fabric_header_sflow") 
    fabric_header_sflow_t                   fabric_header_sflow;
    @name("fabric_header_unicast") 
    fabric_header_unicast_t                 fabric_header_unicast;
    @name("fabric_payload_header") 
    fabric_payload_header_t                 fabric_payload_header;
    @name("fcoe") 
    fcoe_header_t                           fcoe;
    @name("genv") 
    genv_t                                  genv;
    @name("gre") 
    gre_t                                   gre;
    @name("icmp") 
    icmp_t                                  icmp;
    @name("inner_ethernet") 
    ethernet_t                              inner_ethernet;
    @name("inner_icmp") 
    icmp_t                                  inner_icmp;
    @pa_fragment("ingress", "inner_ipv4.hdrChecksum") @pa_fragment("egress", "inner_ipv4.hdrChecksum") @name("inner_ipv4") 
    ipv4_t                                  inner_ipv4;
    @name("inner_ipv6") 
    ipv6_t                                  inner_ipv6;
    @name("inner_sctp") 
    sctp_t                                  inner_sctp;
    @pa_fragment("egress", "inner_tcp.checksum") @pa_fragment("egress", "inner_tcp.urgentPtr") @name("inner_tcp") 
    tcp_t                                   inner_tcp;
    @name("inner_udp") 
    udp_t                                   inner_udp;
    @name("int_egress_port_id_header") 
    int_egress_port_id_header_t             int_egress_port_id_header;
    @name("int_egress_port_tx_utilization_header") 
    int_egress_port_tx_utilization_header_t int_egress_port_tx_utilization_header;
    @name("int_header") 
    int_header_t                            int_header;
    @name("int_hop_latency_header") 
    int_hop_latency_header_t                int_hop_latency_header;
    @name("int_ingress_port_id_header") 
    int_ingress_port_id_header_t            int_ingress_port_id_header;
    @name("int_ingress_tstamp_header") 
    int_ingress_tstamp_header_t             int_ingress_tstamp_header;
    @name("int_plt_header") 
    int_plt_header_t                        int_plt_header;
    @name("int_port_ids_header") 
    int_port_ids_header_t                   int_port_ids_header;
    @name("int_q_congestion_header") 
    int_q_congestion_header_t               int_q_congestion_header;
    @name("int_q_occupancy_header") 
    int_q_occupancy_header_t                int_q_occupancy_header;
    @name("int_switch_id_header") 
    int_switch_id_header_t                  int_switch_id_header;
    @pa_fragment("ingress", "ipv4.hdrChecksum") @pa_fragment("egress", "ipv4.hdrChecksum") @name("ipv4") 
    ipv4_t                                  ipv4;
    @name("ipv6") 
    ipv6_t                                  ipv6;
    @name("lisp") 
    lisp_t                                  lisp;
    @name("llc_header") 
    llc_header_t                            llc_header;
    @name("nsh") 
    nsh_t                                   nsh;
    @name("nsh_context") 
    nsh_context_t                           nsh_context;
    @name("nvgre") 
    nvgre_t                                 nvgre;
    @name("outer_udp") 
    udp_t                                   outer_udp;
    @name("roce") 
    roce_header_t                           roce;
    @name("roce_v2") 
    roce_v2_header_t                        roce_v2;
    @name("sctp") 
    sctp_t                                  sctp;
    @name("sflow") 
    sflow_hdr_t                             sflow;
    @name("sflow_raw_hdr_record") 
    sflow_raw_hdr_record_t                  sflow_raw_hdr_record;
    @name("sflow_sample") 
    sflow_sample_t                          sflow_sample;
    @name("snap_header") 
    snap_header_t                           snap_header;
    @pa_fragment("egress", "tcp.checksum") @pa_fragment("egress", "tcp.urgentPtr") @name("tcp") 
    tcp_t                                   tcp;
    @name("trill") 
    trill_t                                 trill;
    @name("udp") 
    udp_t                                   udp;
    @name("vntag") 
    vntag_t                                 vntag;
    @name("vxlan") 
    vxlan_t                                 vxlan;
    @name("vxlan_gpe") 
    vxlan_gpe_t                             vxlan_gpe;
    @name("vxlan_gpe_int_header") 
    vxlan_gpe_int_header_t                  vxlan_gpe_int_header;
    @name("vxlan_gpe_int_plt_header") 
    vxlan_gpe_int_header_t                  vxlan_gpe_int_plt_header;
    @name("mpls") 
    mpls_t[3]                               mpls;
    @name("vlan_tag_") 
    vlan_tag_t[2]                           vlan_tag_;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("parse_all_int_meta_value_heders") state parse_all_int_meta_value_heders {
        packet.extract<int_switch_id_header_t>(hdr.int_switch_id_header);
        packet.extract<int_port_ids_header_t>(hdr.int_port_ids_header);
        packet.extract<int_hop_latency_header_t>(hdr.int_hop_latency_header);
        packet.extract<int_q_occupancy_header_t>(hdr.int_q_occupancy_header);
        transition accept;
    }
    @name("parse_arp_rarp") state parse_arp_rarp {
        transition parse_set_prio_med;
    }
    @name("parse_eompls") state parse_eompls {
        meta.tunnel_metadata.ingress_tunnel_type = 5w6;
        transition parse_inner_ethernet;
    }
    @name("parse_erspan_t3") state parse_erspan_t3 {
        packet.extract<erspan_header_t3_t_0>(hdr.erspan_t3_header);
        transition select(hdr.erspan_t3_header.ft_d_other) {
            16w0 &&& 16w0x7c01: parse_inner_ethernet;
            16w0x800 &&& 16w0x7c01: parse_inner_ipv4;
            default: accept;
        }
    }
    @name("parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
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
        packet.extract<fabric_header_t>(hdr.fabric_header);
        transition select(hdr.fabric_header.packetType) {
            3w1: parse_fabric_header_unicast;
            3w2: parse_fabric_header_multicast;
            3w3: parse_fabric_header_mirror;
            3w5: parse_fabric_header_cpu;
            default: accept;
        }
    }
    @name("parse_fabric_header_cpu") state parse_fabric_header_cpu {
        packet.extract<fabric_header_cpu_t>(hdr.fabric_header_cpu);
        meta.ingress_metadata.bypass_lookups = hdr.fabric_header_cpu.reasonCode;
        transition select(hdr.fabric_header_cpu.reasonCode) {
            default: parse_fabric_payload_header;
        }
    }
    @name("parse_fabric_header_mirror") state parse_fabric_header_mirror {
        packet.extract<fabric_header_mirror_t>(hdr.fabric_header_mirror);
        transition parse_fabric_payload_header;
    }
    @name("parse_fabric_header_multicast") state parse_fabric_header_multicast {
        packet.extract<fabric_header_multicast_t>(hdr.fabric_header_multicast);
        transition parse_fabric_payload_header;
    }
    @name("parse_fabric_header_unicast") state parse_fabric_header_unicast {
        packet.extract<fabric_header_unicast_t>(hdr.fabric_header_unicast);
        transition parse_fabric_payload_header;
    }
    @name("parse_fabric_payload_header") state parse_fabric_payload_header {
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
            default: accept;
        }
    }
    @name("parse_fcoe") state parse_fcoe {
        packet.extract<fcoe_header_t>(hdr.fcoe);
        transition accept;
    }
    @name("parse_geneve") state parse_geneve {
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
    @name("parse_gpe_int_header") state parse_gpe_int_header {
        transition select((packet.lookahead<bit<8>>())[7:0]) {
            8w3: parse_int_shim_plt_header;
            default: parse_int_shim_header;
        }
    }
    @name("parse_gre") state parse_gre {
        packet.extract<gre_t>(hdr.gre);
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
        packet.extract<gre_t>(hdr.gre);
        transition select(hdr.gre.C, hdr.gre.R, hdr.gre.K, hdr.gre.S, hdr.gre.s, hdr.gre.recurse, hdr.gre.flags, hdr.gre.ver, hdr.gre.proto) {
            (1w0x0, 1w0x0, 1w0x0, 1w0x0, 1w0x0, 3w0x0, 5w0x0, 3w0x0, 16w0x800): parse_gre_ipv4;
            default: accept;
        }
    }
    @name("parse_icmp") state parse_icmp {
        packet.extract<icmp_t>(hdr.icmp);
        meta.l3_metadata.lkp_outer_l4_sport = hdr.icmp.typeCode;
        transition select(hdr.icmp.typeCode) {
            16w0x8200 &&& 16w0xfe00: parse_set_prio_med;
            16w0x8400 &&& 16w0xfc00: parse_set_prio_med;
            16w0x8800 &&& 16w0xff00: parse_set_prio_med;
            default: accept;
        }
    }
    @name("parse_inner_ethernet") state parse_inner_ethernet {
        packet.extract<ethernet_t>(hdr.inner_ethernet);
        meta.l2_metadata.lkp_mac_sa = hdr.inner_ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.inner_ethernet.dstAddr;
        transition select(hdr.inner_ethernet.etherType) {
            16w0x800: parse_inner_ipv4;
            16w0x86dd: parse_inner_ipv6;
            default: accept;
        }
    }
    @name("parse_inner_icmp") state parse_inner_icmp {
        packet.extract<icmp_t>(hdr.inner_icmp);
        meta.l3_metadata.lkp_l4_sport = hdr.inner_icmp.typeCode;
        transition accept;
    }
    @name("parse_inner_ipv4") state parse_inner_ipv4 {
        packet.extract<ipv4_t>(hdr.inner_ipv4);
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
        packet.extract<ipv6_t>(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.nextHdr) {
            8w58: parse_inner_icmp;
            8w6: parse_inner_tcp;
            8w17: parse_inner_udp;
            default: accept;
        }
    }
    @name("parse_inner_sctp") state parse_inner_sctp {
        packet.extract<sctp_t>(hdr.inner_sctp);
        transition accept;
    }
    @name("parse_inner_tcp") state parse_inner_tcp {
        packet.extract<tcp_t>(hdr.inner_tcp);
        meta.l3_metadata.lkp_l4_sport = hdr.inner_tcp.srcPort;
        meta.l3_metadata.lkp_l4_dport = hdr.inner_tcp.dstPort;
        transition accept;
    }
    @name("parse_inner_udp") state parse_inner_udp {
        packet.extract<udp_t>(hdr.inner_udp);
        meta.l3_metadata.lkp_l4_sport = hdr.inner_udp.srcPort;
        meta.l3_metadata.lkp_l4_dport = hdr.inner_udp.dstPort;
        transition accept;
    }
    @name("parse_int_header") state parse_int_header {
        packet.extract<int_header_t>(hdr.int_header);
        meta.int_metadata.int_hdr_word_len = (bit<8>)hdr.int_header.ins_cnt;
        transition select(hdr.int_header.rsvd1, hdr.int_header.total_hop_cnt) {
            (5w0x0 &&& 5w0xf, 8w0x0 &&& 8w0xff): accept;
            default: accept;
            default: parse_all_int_meta_value_heders;
        }
    }
    @name("parse_int_shim_header") state parse_int_shim_header {
        packet.extract<vxlan_gpe_int_header_t>(hdr.vxlan_gpe_int_header);
        transition parse_int_header;
    }
    @name("parse_int_shim_plt_header") state parse_int_shim_plt_header {
        packet.extract<vxlan_gpe_int_header_t>(hdr.vxlan_gpe_int_plt_header);
        packet.extract<int_plt_header_t>(hdr.int_plt_header);
        transition select(hdr.vxlan_gpe_int_plt_header.next_proto) {
            8w0x5: parse_int_shim_header;
            default: accept;
        }
    }
    @name("parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
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
        packet.extract<ipv6_t>(hdr.ipv6);
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
        packet.extract<lisp_t>(hdr.lisp);
        transition select((packet.lookahead<bit<4>>())[3:0]) {
            4w0x4: parse_inner_ipv4;
            4w0x6: parse_inner_ipv6;
            default: accept;
        }
    }
    @name("parse_llc_header") state parse_llc_header {
        packet.extract<llc_header_t>(hdr.llc_header);
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
        packet.extract<nsh_t>(hdr.nsh);
        packet.extract<nsh_context_t>(hdr.nsh_context);
        transition select(hdr.nsh.protoType) {
            16w0x800: parse_inner_ipv4;
            16w0x86dd: parse_inner_ipv6;
            16w0x6558: parse_inner_ethernet;
            default: accept;
        }
    }
    @name("parse_nvgre") state parse_nvgre {
        packet.extract<nvgre_t>(hdr.nvgre);
        meta.tunnel_metadata.ingress_tunnel_type = 5w5;
        meta.tunnel_metadata.tunnel_vni = hdr.nvgre.tni;
        transition parse_inner_ethernet;
    }
    @name("parse_pw") state parse_pw {
        transition accept;
    }
    @name("parse_qinq") state parse_qinq {
        packet.extract<vlan_tag_t>(hdr.vlan_tag_[0]);
        transition select(hdr.vlan_tag_[0].etherType) {
            16w0x8100: parse_qinq_vlan;
            default: accept;
        }
    }
    @name("parse_qinq_vlan") state parse_qinq_vlan {
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
    @name("parse_roce") state parse_roce {
        packet.extract<roce_header_t>(hdr.roce);
        transition accept;
    }
    @name("parse_roce_v2") state parse_roce_v2 {
        packet.extract<roce_v2_header_t>(hdr.roce_v2);
        transition accept;
    }
    @name("parse_sctp") state parse_sctp {
        packet.extract<sctp_t>(hdr.sctp);
        transition accept;
    }
    @name("parse_set_prio_high") state parse_set_prio_high {
        meta.ig_prsr_ctrl.priority = 3w5;
        transition accept;
    }
    @name("parse_set_prio_max") state parse_set_prio_max {
        meta.ig_prsr_ctrl.priority = 3w7;
        transition accept;
    }
    @name("parse_set_prio_med") state parse_set_prio_med {
        meta.ig_prsr_ctrl.priority = 3w3;
        transition accept;
    }
    @name("parse_sflow") state parse_sflow {
        transition accept;
    }
    @name("parse_snap_header") state parse_snap_header {
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
            default: accept;
        }
    }
    @name("parse_tcp") state parse_tcp {
        packet.extract<tcp_t>(hdr.tcp);
        meta.l3_metadata.lkp_outer_l4_sport = hdr.tcp.srcPort;
        meta.l3_metadata.lkp_outer_l4_dport = hdr.tcp.dstPort;
        transition select(hdr.tcp.dstPort) {
            16w179: parse_set_prio_med;
            16w639: parse_set_prio_med;
            default: accept;
        }
    }
    @name("parse_trill") state parse_trill {
        packet.extract<trill_t>(hdr.trill);
        transition parse_inner_ethernet;
    }
    @name("parse_udp") state parse_udp {
        packet.extract<udp_t>(hdr.udp);
        meta.l3_metadata.lkp_outer_l4_sport = hdr.udp.srcPort;
        meta.l3_metadata.lkp_outer_l4_dport = hdr.udp.dstPort;
        transition select(hdr.udp.dstPort) {
            16w4790: parse_vxlan_gpe;
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
        packet.extract<udp_t>(hdr.udp);
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
    @name("parse_vntag") state parse_vntag {
        packet.extract<vntag_t>(hdr.vntag);
        transition parse_inner_ethernet;
    }
    @name("parse_vpls") state parse_vpls {
        transition accept;
    }
    @name("parse_vxlan") state parse_vxlan {
        packet.extract<vxlan_t>(hdr.vxlan);
        meta.tunnel_metadata.ingress_tunnel_type = 5w1;
        meta.tunnel_metadata.tunnel_vni = hdr.vxlan.vni;
        transition parse_inner_ethernet;
    }
    @name("parse_vxlan_gpe") state parse_vxlan_gpe {
        packet.extract<vxlan_gpe_t>(hdr.vxlan_gpe);
        meta.tunnel_metadata.ingress_tunnel_type = 5w12;
        meta.tunnel_metadata.tunnel_vni = hdr.vxlan_gpe.vni;
        transition select(hdr.vxlan_gpe.flags, hdr.vxlan_gpe.next_proto) {
            (8w0x8 &&& 8w0x8, 8w0x5 &&& 8w0xff): parse_gpe_int_header;
            default: parse_inner_ethernet;
        }
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
    @name(".quantize_latency_1") action quantize_latency_1() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 1;
    }
    @name(".quantize_latency_2") action quantize_latency_2() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 2;
    }
    @name(".quantize_latency_3") action quantize_latency_3() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 3;
    }
    @name(".quantize_latency_4") action quantize_latency_4() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 4;
    }
    @name(".quantize_latency_5") action quantize_latency_5() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 5;
    }
    @name(".quantize_latency_6") action quantize_latency_6() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 6;
    }
    @name(".quantize_latency_7") action quantize_latency_7() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 7;
    }
    @name(".quantize_latency_8") action quantize_latency_8() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 8;
    }
    @name(".quantize_latency_9") action quantize_latency_9() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 9;
    }
    @name(".quantize_latency_10") action quantize_latency_10() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 10;
    }
    @name(".quantize_latency_11") action quantize_latency_11() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 11;
    }
    @name(".quantize_latency_12") action quantize_latency_12() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 12;
    }
    @name(".quantize_latency_13") action quantize_latency_13() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 13;
    }
    @name(".quantize_latency_14") action quantize_latency_14() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 14;
    }
    @name(".quantize_latency_15") action quantize_latency_15() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 15;
    }
    @name(".copy_latency") action copy_latency() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta;
    }
    @name(".scramble_latency") action scramble_latency() {
        meta.int_metadata.quantized_latency = meta.global_config_metadata.switch_id - meta.int_metadata.quantized_latency;
    }
    @name("plt_quantize_latency") table plt_quantize_latency {
        actions = {
            quantize_latency_1();
            quantize_latency_2();
            quantize_latency_3();
            quantize_latency_4();
            quantize_latency_5();
            quantize_latency_6();
            quantize_latency_7();
            quantize_latency_8();
            quantize_latency_9();
            quantize_latency_10();
            quantize_latency_11();
            quantize_latency_12();
            quantize_latency_13();
            quantize_latency_14();
            quantize_latency_15();
            copy_latency();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.isValid(): exact @name("hdr.ethernet.isValid()") ;
        }
        size = 2;
        default_action = NoAction();
    }
    @name("plt_scramble_latency") table plt_scramble_latency {
        actions = {
            scramble_latency();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    apply {
        plt_quantize_latency.apply();
        if (meta.int_metadata_i2e.sink == 1w0) 
            plt_scramble_latency.apply();
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
            nop();
            remove_vlan_single_tagged();
            remove_vlan_double_tagged();
            @defaultonly NoAction();
        }
        key = {
            hdr.vlan_tag_[0].isValid(): exact @name("hdr.vlan_tag_[0].isValid()") ;
            hdr.vlan_tag_[1].isValid(): exact @name("hdr.vlan_tag_[1].isValid()") ;
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
            nop();
            set_l2_rewrite();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.nexthop_index: exact @name("meta.l3_metadata.nexthop_index") ;
        }
        size = 16384;
        default_action = NoAction();
    }
    apply {
        if (meta.egress_metadata.routed == 1w0 || meta.l3_metadata.nexthop_index != 16w0) 
            rewrite.apply();
        else 
            ;
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
            nop();
            set_egress_bd_properties();
            @defaultonly NoAction();
        }
        key = {
            meta.egress_metadata.bd: exact @name("meta.egress_metadata.bd") ;
        }
        size = 16384;
        default_action = NoAction();
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
            nop_0();
            @defaultonly NoAction();
        }
        key = {
            meta.egress_metadata.bd      : exact @name("meta.egress_metadata.bd") ;
            meta.l2_metadata.lkp_pkt_type: exact @name("meta.l2_metadata.lkp_pkt_type") ;
        }
        size = 16384;
        @name("egress_bd_stats") counters = direct_counter(CounterType.packets_and_bytes);
        default_action = NoAction();
    }
    apply {
        egress_bd_stats_0.apply();
    }
}

control process_egress_l4port(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_egress_tcp_port_fields") action set_egress_tcp_port_fields() {
        meta.l3_metadata.egress_l4_sport = hdr.tcp.srcPort;
        meta.l3_metadata.egress_l4_dport = hdr.tcp.dstPort;
    }
    @name(".set_egress_udp_port_fields") action set_egress_udp_port_fields() {
        meta.l3_metadata.egress_l4_sport = hdr.udp.srcPort;
        meta.l3_metadata.egress_l4_dport = hdr.udp.dstPort;
    }
    @name(".set_egress_icmp_port_fields") action set_egress_icmp_port_fields() {
        meta.l3_metadata.egress_l4_sport = hdr.icmp.typeCode;
    }
    @name("egress_l4port_fields") table egress_l4port_fields {
        actions = {
            nop();
            set_egress_tcp_port_fields();
            set_egress_udp_port_fields();
            set_egress_icmp_port_fields();
            @defaultonly NoAction();
        }
        key = {
            hdr.tcp.isValid() : exact @name("hdr.tcp.isValid()") ;
            hdr.udp.isValid() : exact @name("hdr.udp.isValid()") ;
            hdr.icmp.isValid(): exact @name("hdr.icmp.isValid()") ;
        }
        size = 4;
        default_action = NoAction();
    }
    apply {
        egress_l4port_fields.apply();
    }
}

control process_int_insertion(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".int_set_header_0_bos") action int_set_header_0_bos() {
        hdr.int_switch_id_header.bos = 1w1;
    }
    @name(".int_set_header_1_bos") action int_set_header_1_bos() {
        hdr.int_port_ids_header.bos = 1w1;
    }
    @name(".int_set_header_2_bos") action int_set_header_2_bos() {
        hdr.int_hop_latency_header.bos = 1w1;
    }
    @name(".int_set_header_3_bos") action int_set_header_3_bos() {
        hdr.int_q_occupancy_header.bos = 1w1;
    }
    @name(".nop") action nop() {
    }
    @name(".int_transit") action int_transit() {
        meta.int_metadata.hit_state = 2w1;
        meta.int_metadata.insert_cnt = hdr.int_header.max_hop_cnt - hdr.int_header.total_hop_cnt;
        meta.int_metadata.insert_byte_cnt = (bit<16>)(meta.int_metadata.int_hdr_word_len << 2);
    }
    @name(".int_reset") action int_reset() {
        meta.int_metadata.insert_cnt = 8w0;
        meta.int_metadata.int_hdr_word_len = 8w0;
    }
    @name(".int_set_header_0003_i0") action int_set_header_0003_i0() {
    }
    @name(".int_set_header_3") action int_set_header_3() {
        hdr.int_q_occupancy_header.setValid();
        hdr.int_q_occupancy_header.q_occupancy1 = 7w0;
        hdr.int_q_occupancy_header.q_occupancy0 = (bit<24>)meta.eg_intr_md.enq_qdepth;
    }
    @name(".int_set_header_0003_i1") action int_set_header_0003_i1() {
        int_set_header_3();
    }
    @name(".int_set_header_2") action int_set_header_2() {
        hdr.int_hop_latency_header.setValid();
        hdr.int_hop_latency_header.hop_latency = (bit<31>)meta.eg_intr_md.deq_timedelta;
    }
    @name(".int_set_header_0003_i2") action int_set_header_0003_i2() {
        int_set_header_2();
    }
    @name(".int_set_header_0003_i3") action int_set_header_0003_i3() {
        int_set_header_3();
        int_set_header_2();
    }
    @name(".int_set_header_1") action int_set_header_1() {
        hdr.int_port_ids_header.setValid();
        hdr.int_port_ids_header.ingress_port_id = meta.ingress_metadata.ingress_port;
        hdr.int_port_ids_header.egress_port_id = (bit<16>)meta.eg_intr_md.egress_port;
    }
    @name(".int_set_header_0003_i4") action int_set_header_0003_i4() {
        int_set_header_1();
    }
    @name(".int_set_header_0003_i5") action int_set_header_0003_i5() {
        int_set_header_3();
        int_set_header_1();
    }
    @name(".int_set_header_0003_i6") action int_set_header_0003_i6() {
        int_set_header_2();
        int_set_header_1();
    }
    @name(".int_set_header_0003_i7") action int_set_header_0003_i7() {
        int_set_header_3();
        int_set_header_2();
        int_set_header_1();
    }
    @name(".int_set_header_0") action int_set_header_0() {
        hdr.int_switch_id_header.setValid();
        hdr.int_switch_id_header.switch_id = (bit<31>)meta.global_config_metadata.switch_id;
    }
    @name(".int_set_header_0003_i8") action int_set_header_0003_i8() {
        int_set_header_0();
    }
    @name(".int_set_header_0003_i9") action int_set_header_0003_i9() {
        int_set_header_3();
        int_set_header_0();
    }
    @name(".int_set_header_0003_i10") action int_set_header_0003_i10() {
        int_set_header_2();
        int_set_header_0();
    }
    @name(".int_set_header_0003_i11") action int_set_header_0003_i11() {
        int_set_header_3();
        int_set_header_2();
        int_set_header_0();
    }
    @name(".int_set_header_0003_i12") action int_set_header_0003_i12() {
        int_set_header_1();
        int_set_header_0();
    }
    @name(".int_set_header_0003_i13") action int_set_header_0003_i13() {
        int_set_header_3();
        int_set_header_1();
        int_set_header_0();
    }
    @name(".int_set_header_0003_i14") action int_set_header_0003_i14() {
        int_set_header_2();
        int_set_header_1();
        int_set_header_0();
    }
    @name(".int_set_header_0003_i15") action int_set_header_0003_i15() {
        int_set_header_3();
        int_set_header_2();
        int_set_header_1();
        int_set_header_0();
    }
    @name(".int_set_e_bit") action int_set_e_bit() {
        hdr.int_header.e = 1w1;
    }
    @name(".int_update_total_hop_cnt") action int_update_total_hop_cnt() {
        hdr.int_header.total_hop_cnt = hdr.int_header.total_hop_cnt + 8w1;
    }
    @name(".clear_upper") action clear_upper() {
        meta.int_metadata.insert_byte_cnt = meta.int_metadata.insert_byte_cnt & 16w0x7f;
    }
    @name("int_bos") table int_bos {
        actions = {
            int_set_header_0_bos();
            int_set_header_1_bos();
            int_set_header_2_bos();
            int_set_header_3_bos();
            nop();
            @defaultonly NoAction();
        }
        key = {
            hdr.int_header.total_hop_cnt        : ternary @name("hdr.int_header.total_hop_cnt") ;
            hdr.int_header.instruction_mask_0003: ternary @name("hdr.int_header.instruction_mask_0003") ;
            hdr.int_header.instruction_mask_0407: ternary @name("hdr.int_header.instruction_mask_0407") ;
            hdr.int_header.instruction_mask_0811: ternary @name("hdr.int_header.instruction_mask_0811") ;
            hdr.int_header.instruction_mask_1215: ternary @name("hdr.int_header.instruction_mask_1215") ;
        }
        size = 17;
        default_action = NoAction();
    }
    @name("int_insert") table int_insert {
        actions = {
            int_transit();
            int_reset();
            nop();
            @defaultonly NoAction();
        }
        key = {
            meta.int_metadata_i2e.source   : ternary @name("meta.int_metadata_i2e.source") ;
            meta.int_metadata_i2e.sink     : ternary @name("meta.int_metadata_i2e.sink") ;
            hdr.int_header.isValid()       : exact @name("hdr.int_header.isValid()") ;
            standard_metadata.instance_type: ternary @name("standard_metadata.instance_type") ;
        }
        size = 5;
        default_action = NoAction();
    }
    @ternary(1) @name("int_inst_0003") table int_inst_0003 {
        actions = {
            int_set_header_0003_i0();
            int_set_header_0003_i1();
            int_set_header_0003_i2();
            int_set_header_0003_i3();
            int_set_header_0003_i4();
            int_set_header_0003_i5();
            int_set_header_0003_i6();
            int_set_header_0003_i7();
            int_set_header_0003_i8();
            int_set_header_0003_i9();
            int_set_header_0003_i10();
            int_set_header_0003_i11();
            int_set_header_0003_i12();
            int_set_header_0003_i13();
            int_set_header_0003_i14();
            int_set_header_0003_i15();
            @defaultonly NoAction();
        }
        key = {
            hdr.int_header.instruction_mask_0003: exact @name("hdr.int_header.instruction_mask_0003") ;
        }
        size = 17;
        default_action = NoAction();
    }
    @ternary(1) @name("int_inst_0407") table int_inst_0407 {
        actions = {
            nop();
            @defaultonly NoAction();
        }
        key = {
            hdr.int_header.instruction_mask_0407: exact @name("hdr.int_header.instruction_mask_0407") ;
        }
        size = 17;
        default_action = NoAction();
    }
    @name("int_inst_0811") table int_inst_0811 {
        actions = {
            nop();
            @defaultonly NoAction();
        }
        key = {
            hdr.int_header.instruction_mask_0811: exact @name("hdr.int_header.instruction_mask_0811") ;
        }
        size = 17;
        default_action = NoAction();
    }
    @name("int_inst_1215") table int_inst_1215 {
        actions = {
            nop();
            @defaultonly NoAction();
        }
        key = {
            hdr.int_header.instruction_mask_1215: exact @name("hdr.int_header.instruction_mask_1215") ;
        }
        size = 17;
        default_action = NoAction();
    }
    @name("int_meta_header_update") table int_meta_header_update {
        actions = {
            int_set_e_bit();
            int_update_total_hop_cnt();
            @defaultonly NoAction();
        }
        key = {
            meta.int_metadata.insert_cnt: exact @name("meta.int_metadata.insert_cnt") ;
        }
        size = 2;
        default_action = NoAction();
    }
    @name("int_transit_clear_byte_cnt") table int_transit_clear_byte_cnt {
        actions = {
            clear_upper();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    apply {
        int_insert.apply();
        if (meta.int_metadata.hit_state != 2w0) {
            if (meta.int_metadata.hit_state == 2w1) 
                int_transit_clear_byte_cnt.apply();
            if (meta.int_metadata.insert_cnt != 8w0) {
                int_inst_0003.apply();
                int_inst_0407.apply();
                int_inst_0811.apply();
                int_inst_1215.apply();
                int_bos.apply();
            }
            int_meta_header_update.apply();
        }
    }
}

control process_plt_insertion(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".update_int_plt_header") action update_int_plt_header() {
        hdr.int_plt_header.pl_encoding = hdr.int_plt_header.pl_encoding ^ meta.int_metadata.quantized_latency;
    }
    @name("int_plt_encode") table int_plt_encode {
        actions = {
            update_int_plt_header();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    apply {
        if (meta.int_metadata_i2e.source == 1w0 && meta.int_metadata_i2e.sink == 1w0 && hdr.int_plt_header.isValid()) 
            int_plt_encode.apply();
    }
}

control process_int_egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("process_int_insertion") process_int_insertion() process_int_insertion_0;
    @name("process_plt_insertion") process_plt_insertion() process_plt_insertion_0;
    apply {
        if (meta.int_metadata_i2e.sink == 1w1 && !(standard_metadata.instance_type != 32w0 && standard_metadata.instance_type != 32w5)) 
            ;
        else {
            process_int_insertion_0.apply(hdr, meta, standard_metadata);
            if (meta.tunnel_metadata.egress_tunnel_type == 5w7 || meta.tunnel_metadata.egress_tunnel_type == 5w20) 
                ;
            else 
                process_plt_insertion_0.apply(hdr, meta, standard_metadata);
        }
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
    @name(".fabric_unicast_rewrite") action fabric_unicast_rewrite() {
        hdr.fabric_header.setValid();
        hdr.fabric_header.headerVersion = 2w0;
        hdr.fabric_header.packetVersion = 2w0;
        hdr.fabric_header.pad1 = 1w0;
        hdr.fabric_header.packetType = 3w1;
        hdr.fabric_header.dstDevice = meta.fabric_metadata.dst_device;
        hdr.fabric_header.dstPortOrGroup = meta.fabric_metadata.dst_port;
        hdr.fabric_header_unicast.setValid();
        hdr.fabric_header_unicast.tunnelTerminate = meta.tunnel_metadata.tunnel_terminate;
        hdr.fabric_header_unicast.routed = meta.l3_metadata.routed;
        hdr.fabric_header_unicast.outerRouted = meta.l3_metadata.outer_routed;
        hdr.fabric_header_unicast.ingressTunnelType = meta.tunnel_metadata.ingress_tunnel_type;
        hdr.fabric_header_unicast.nexthopIndex = meta.l3_metadata.nexthop_index;
        hdr.fabric_payload_header.setValid();
        hdr.fabric_payload_header.etherType = hdr.ethernet.etherType;
        hdr.ethernet.etherType = 16w0x9000;
    }
    @ternary(1) @name("tunnel_encap_process_outer") table tunnel_encap_process_outer {
        actions = {
            nop();
            fabric_rewrite();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.egress_tunnel_type : exact @name("meta.tunnel_metadata.egress_tunnel_type") ;
            meta.tunnel_metadata.egress_header_count: exact @name("meta.tunnel_metadata.egress_header_count") ;
            meta.multicast_metadata.replica         : exact @name("meta.multicast_metadata.replica") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name("tunnel_rewrite") table tunnel_rewrite {
        actions = {
            nop();
            cpu_rx_rewrite();
            fabric_unicast_rewrite();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.tunnel_index: exact @name("meta.tunnel_metadata.tunnel_index") ;
        }
        size = 16384;
        default_action = NoAction();
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
    @name(".nop") action nop() {
    }
    @name(".egress_acl_deny") action egress_acl_deny(bit<16> acl_copy_reason) {
        meta.acl_metadata.acl_deny = 1w1;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".egress_acl_permit") action egress_acl_permit(bit<16> acl_copy_reason) {
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name("egress_ip_acl") table egress_ip_acl {
        actions = {
            nop();
            egress_acl_deny();
            egress_acl_permit();
            @defaultonly NoAction();
        }
        key = {
            meta.acl_metadata.egress_if_label         : ternary @name("meta.acl_metadata.egress_if_label") ;
            meta.acl_metadata.egress_bd_label         : ternary @name("meta.acl_metadata.egress_bd_label") ;
            hdr.ipv4.srcAddr                          : ternary @name("hdr.ipv4.srcAddr") ;
            hdr.ipv4.dstAddr                          : ternary @name("hdr.ipv4.dstAddr") ;
            hdr.ipv4.protocol                         : ternary @name("hdr.ipv4.protocol") ;
            meta.acl_metadata.egress_src_port_range_id: exact @name("meta.acl_metadata.egress_src_port_range_id") ;
            meta.acl_metadata.egress_dst_port_range_id: exact @name("meta.acl_metadata.egress_dst_port_range_id") ;
        }
        size = 128;
        default_action = NoAction();
    }
    @name("egress_mac_acl") table egress_mac_acl {
        actions = {
            nop();
            egress_acl_deny();
            egress_acl_permit();
            @defaultonly NoAction();
        }
        key = {
            meta.acl_metadata.egress_if_label: ternary @name("meta.acl_metadata.egress_if_label") ;
            meta.acl_metadata.egress_bd_label: ternary @name("meta.acl_metadata.egress_bd_label") ;
            hdr.ethernet.srcAddr             : ternary @name("hdr.ethernet.srcAddr") ;
            hdr.ethernet.dstAddr             : ternary @name("hdr.ethernet.dstAddr") ;
            hdr.ethernet.etherType           : ternary @name("hdr.ethernet.etherType") ;
        }
        size = 128;
        default_action = NoAction();
    }
    apply {
        if (hdr.ipv4.isValid()) 
            egress_ip_acl.apply();
        else 
            if (hdr.ipv6.isValid()) 
                ;
            else 
                egress_mac_acl.apply();
    }
}

control process_int_outer_encap(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".int_update_vxlan_gpe_ipv4") action int_update_vxlan_gpe_ipv4() {
        hdr.ipv4.totalLen = hdr.ipv4.totalLen + meta.int_metadata.insert_byte_cnt;
        hdr.udp.length_ = hdr.udp.length_ + meta.int_metadata.insert_byte_cnt;
        hdr.vxlan_gpe_int_header.len = hdr.vxlan_gpe_int_header.len + meta.int_metadata.int_hdr_word_len;
    }
    @name(".nop") action nop() {
    }
    @name("int_outer_encap") table int_outer_encap {
        actions = {
            int_update_vxlan_gpe_ipv4();
            nop();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.isValid()                     : exact @name("hdr.ipv4.isValid()") ;
            hdr.vxlan_gpe.isValid()                : exact @name("hdr.vxlan_gpe.isValid()") ;
            hdr.erspan_t3_header.isValid()         : exact @name("hdr.erspan_t3_header.isValid()") ;
            meta.int_metadata_i2e.source           : exact @name("meta.int_metadata_i2e.source") ;
            meta.int_metadata_i2e.sink             : exact @name("meta.int_metadata_i2e.sink") ;
            meta.tunnel_metadata.egress_tunnel_type: ternary @name("meta.tunnel_metadata.egress_tunnel_type") ;
        }
        size = 8;
        default_action = NoAction();
    }
    apply {
        if (meta.int_metadata.insert_cnt != 8w0 || meta.int_metadata_i2e.sink == 1w1 && standard_metadata.instance_type == 32w2) 
            int_outer_encap.apply();
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
            set_egress_packet_vlan_untagged();
            set_egress_packet_vlan_tagged();
            set_egress_packet_vlan_double_tagged();
            @defaultonly NoAction();
        }
        key = {
            meta.egress_metadata.ifindex: exact @name("meta.egress_metadata.ifindex") ;
            meta.egress_metadata.bd     : exact @name("meta.egress_metadata.bd") ;
        }
        size = 32768;
        default_action = NoAction();
    }
    apply {
        egress_vlan_xlate.apply();
    }
}

control process_egress_filter(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".egress_filter_check") action egress_filter_check() {
        meta.egress_filter_metadata.ifindex_check = meta.ingress_metadata.ifindex ^ meta.egress_metadata.ifindex;
        meta.egress_filter_metadata.bd = meta.ingress_metadata.outer_bd ^ meta.egress_metadata.outer_bd;
        meta.egress_filter_metadata.inner_bd = meta.ingress_metadata.bd ^ meta.egress_metadata.bd;
    }
    @name(".set_egress_filter_drop") action set_egress_filter_drop() {
        mark_to_drop();
    }
    @name("egress_filter") table egress_filter {
        actions = {
            egress_filter_check();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @name("egress_filter_drop") table egress_filter_drop {
        actions = {
            set_egress_filter_drop();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    apply {
        egress_filter.apply();
        if (meta.multicast_metadata.inner_replica == 1w1) 
            if (meta.tunnel_metadata.ingress_tunnel_type == 5w0 && meta.tunnel_metadata.egress_tunnel_type == 5w0 || meta.tunnel_metadata.ingress_tunnel_type != 5w0 && meta.tunnel_metadata.egress_tunnel_type != 5w0) 
                egress_filter_drop.apply();
    }
}

control process_egress_system_acl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".drop_packet") action drop_packet() {
        mark_to_drop();
    }
    @name(".egress_copy_to_cpu") action egress_copy_to_cpu() {
        clone3<tuple<bit<14>, bit<16>, bit<16>, bit<9>>>(CloneType.E2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
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
            nop();
            drop_packet();
            egress_copy_to_cpu();
            egress_redirect_to_cpu();
            egress_copy_to_cpu_with_reason();
            egress_redirect_to_cpu_with_reason();
            egress_mirror_coal_hdr();
            @defaultonly NoAction();
        }
        key = {
            meta.fabric_metadata.reason_code: ternary @name("meta.fabric_metadata.reason_code") ;
            meta.eg_intr_md.egress_port     : ternary @name("meta.eg_intr_md.egress_port") ;
            meta.eg_intr_md.deflection_flag : ternary @name("meta.eg_intr_md.deflection_flag") ;
            meta.l3_metadata.l3_mtu_check   : ternary @name("meta.l3_metadata.l3_mtu_check") ;
            meta.acl_metadata.acl_deny      : ternary @name("meta.acl_metadata.acl_deny") ;
        }
        size = 128;
        default_action = NoAction();
    }
    apply {
        if (meta.egress_metadata.bypass == 1w0) 
            egress_system_acl.apply();
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
            egress_port_type_normal();
            egress_port_type_fabric();
            egress_port_type_cpu();
            @defaultonly NoAction();
        }
        key = {
            meta.eg_intr_md.egress_port: exact @name("meta.eg_intr_md.egress_port") ;
        }
        size = 288;
        default_action = NoAction();
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
        if (meta.eg_intr_md.deflection_flag == 1w0 && meta.egress_metadata.bypass == 1w0) {
            process_int_egress_prep_0.apply(hdr, meta, standard_metadata);
            if (standard_metadata.instance_type != 32w0 && standard_metadata.instance_type != 32w5) {
                process_mirroring_0.apply(hdr, meta, standard_metadata);
                process_bfd_mirror_to_cpu_0.apply(hdr, meta, standard_metadata);
            }
            else {
                process_replication_0.apply(hdr, meta, standard_metadata);
                process_egress_bfd_packet_0.apply(hdr, meta, standard_metadata);
            }
            switch (egress_port_mapping.apply().action_run) {
                egress_port_type_normal: {
                    if (standard_metadata.instance_type == 32w0 || standard_metadata.instance_type == 32w5) 
                        process_vlan_decap_0.apply(hdr, meta, standard_metadata);
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
            if (meta.egress_metadata.port_type == 2w0) 
                process_vlan_xlate_0.apply(hdr, meta, standard_metadata);
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
        meta.ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
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
            set_ifindex();
            @defaultonly NoAction();
        }
        key = {
            meta.ig_intr_md.ingress_port: exact @name("meta.ig_intr_md.ingress_port") ;
        }
        size = 288;
        default_action = NoAction();
    }
    @name("ingress_port_properties") table ingress_port_properties {
        actions = {
            set_ingress_port_properties();
            @defaultonly NoAction();
        }
        key = {
            meta.ig_intr_md.ingress_port: exact @name("meta.ig_intr_md.ingress_port") ;
        }
        size = 288;
        default_action = NoAction();
    }
    apply {
        if (meta.ig_intr_md.resubmit_flag == 1w0) 
            ingress_port_mapping.apply();
        ingress_port_properties.apply();
    }
}

control process_global_params(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".deflect_on_drop") action deflect_on_drop(bit<1> enable_dod) {
        meta.ig_intr_md_for_tm.deflect_on_drop = enable_dod;
    }
    @name(".set_config_parameters") action set_config_parameters(bit<1> enable_dod, bit<8> enable_flowlet, bit<32> switch_id) {
        deflect_on_drop(enable_dod);
        meta.i2e_metadata.ingress_tstamp = (bit<32>)meta.ig_intr_md.ingress_global_tstamp;
        meta.ingress_metadata.ingress_port = meta.ig_intr_md.ingress_port;
        meta.l2_metadata.same_if_check = meta.ingress_metadata.ifindex;
        meta.ig_intr_md_for_tm.ucast_egress_port = 9w511;
        meta.global_config_metadata.switch_id = switch_id;
    }
    @name("switch_config_params") table switch_config_params {
        actions = {
            set_config_parameters();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
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
            malformed_outer_ethernet_packet();
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
            hdr.ethernet.srcAddr      : ternary @name("hdr.ethernet.srcAddr") ;
            hdr.ethernet.dstAddr      : ternary @name("hdr.ethernet.dstAddr") ;
            hdr.vlan_tag_[0].isValid(): exact @name("hdr.vlan_tag_[0].isValid()") ;
            hdr.vlan_tag_[1].isValid(): exact @name("hdr.vlan_tag_[1].isValid()") ;
        }
        size = 64;
        default_action = NoAction();
    }
    @name("validate_outer_ipv4_header") validate_outer_ipv4_header() validate_outer_ipv4_header_0;
    @name("validate_outer_ipv6_header") validate_outer_ipv6_header() validate_outer_ipv6_header_0;
    apply {
        switch (validate_outer_ethernet.apply().action_run) {
            default: {
                if (hdr.ipv4.isValid()) 
                    validate_outer_ipv4_header_0.apply(hdr, meta, standard_metadata);
                else 
                    if (hdr.ipv6.isValid()) 
                        validate_outer_ipv6_header_0.apply(hdr, meta, standard_metadata);
                    else 
                        ;
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
        meta.ig_intr_md_for_tm.mcast_grp_a = 16w0;
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
        meta.ig_intr_md_for_tm.mcast_grp_a = 16w0;
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
        meta.ig_intr_md_for_tm.rid = ingress_rid;
    }
    @name(".port_vlan_mapping_miss") action port_vlan_mapping_miss() {
        meta.l2_metadata.port_vlan_mapping_miss = 1w1;
    }
    @name("adjust_lkp_fields") table adjust_lkp_fields {
        actions = {
            non_ip_lkp();
            ipv4_lkp();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.isValid(): exact @name("hdr.ipv4.isValid()") ;
            hdr.ipv6.isValid(): exact @name("hdr.ipv6.isValid()") ;
        }
        default_action = NoAction();
    }
    @name("port_vlan_mapping") table port_vlan_mapping {
        actions = {
            set_bd_properties();
            port_vlan_mapping_miss();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.ifindex: exact @name("meta.ingress_metadata.ifindex") ;
            hdr.vlan_tag_[0].isValid()   : exact @name("hdr.vlan_tag_[0].isValid()") ;
            hdr.vlan_tag_[0].vid         : exact @name("hdr.vlan_tag_[0].vid") ;
            hdr.vlan_tag_[1].isValid()   : exact @name("hdr.vlan_tag_[1].isValid()") ;
            hdr.vlan_tag_[1].vid         : exact @name("hdr.vlan_tag_[1].vid") ;
        }
        size = 32768;
        @name("bd_action_profile") implementation = action_profile(32w16384);
        default_action = NoAction();
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
            set_stp_state();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.ifindex: exact @name("meta.ingress_metadata.ifindex") ;
            meta.l2_metadata.stp_group   : exact @name("meta.l2_metadata.stp_group") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    apply {
        if (meta.ingress_metadata.port_type == 2w0 && meta.l2_metadata.stp_group != 10w0) 
            spanning_tree.apply();
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
        meta.ig_intr_md_for_tm.ucast_egress_port = (bit<9>)hdr.fabric_header.dstPortOrGroup;
        meta.egress_metadata.bypass = hdr.fabric_header_cpu.txBypass;
        hdr.ethernet.etherType = hdr.fabric_payload_header.etherType;
        hdr.fabric_header.setInvalid();
        hdr.fabric_header_cpu.setInvalid();
        hdr.fabric_payload_header.setInvalid();
    }
    @name(".switch_fabric_unicast_packet") action switch_fabric_unicast_packet() {
        meta.fabric_metadata.fabric_header_present = 1w1;
        meta.fabric_metadata.dst_device = hdr.fabric_header.dstDevice;
        meta.fabric_metadata.dst_port = hdr.fabric_header.dstPortOrGroup;
    }
    @name(".terminate_fabric_unicast_packet") action terminate_fabric_unicast_packet() {
        meta.ig_intr_md_for_tm.ucast_egress_port = (bit<9>)hdr.fabric_header.dstPortOrGroup;
        meta.tunnel_metadata.tunnel_terminate = hdr.fabric_header_unicast.tunnelTerminate;
        meta.tunnel_metadata.ingress_tunnel_type = hdr.fabric_header_unicast.ingressTunnelType;
        meta.l3_metadata.nexthop_index = hdr.fabric_header_unicast.nexthopIndex;
        meta.l3_metadata.routed = hdr.fabric_header_unicast.routed;
        meta.l3_metadata.outer_routed = hdr.fabric_header_unicast.outerRouted;
        hdr.ethernet.etherType = hdr.fabric_payload_header.etherType;
        hdr.fabric_header.setInvalid();
        hdr.fabric_header_unicast.setInvalid();
        hdr.fabric_payload_header.setInvalid();
    }
    @name(".set_ingress_ifindex_properties") action set_ingress_ifindex_properties(bit<9> l2xid) {
        meta.ig_intr_md_for_tm.level2_exclusion_id = l2xid;
    }
    @name(".non_ip_over_fabric") action non_ip_over_fabric() {
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name(".ipv4_over_fabric") action ipv4_over_fabric() {
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.ipv4_metadata.lkp_ipv4_sa = hdr.ipv4.srcAddr;
        meta.ipv4_metadata.lkp_ipv4_da = hdr.ipv4.dstAddr;
        meta.l3_metadata.lkp_ip_proto = hdr.ipv4.protocol;
        meta.l3_metadata.lkp_l4_sport = meta.l3_metadata.lkp_outer_l4_sport;
        meta.l3_metadata.lkp_l4_dport = meta.l3_metadata.lkp_outer_l4_dport;
    }
    @ternary(1) @name("fabric_ingress_dst_lkp") table fabric_ingress_dst_lkp {
        actions = {
            nop();
            terminate_cpu_packet();
            switch_fabric_unicast_packet();
            terminate_fabric_unicast_packet();
            @defaultonly NoAction();
        }
        key = {
            hdr.fabric_header.dstDevice: exact @name("hdr.fabric_header.dstDevice") ;
        }
        default_action = NoAction();
    }
    @name("fabric_ingress_src_lkp") table fabric_ingress_src_lkp {
        actions = {
            nop();
            set_ingress_ifindex_properties();
            @defaultonly NoAction();
        }
        key = {
            hdr.fabric_header_multicast.ingressIfindex: exact @name("hdr.fabric_header_multicast.ingressIfindex") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name("native_packet_over_fabric") table native_packet_over_fabric {
        actions = {
            non_ip_over_fabric();
            ipv4_over_fabric();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.isValid(): exact @name("hdr.ipv4.isValid()") ;
            hdr.ipv6.isValid(): exact @name("hdr.ipv6.isValid()") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        if (meta.ingress_metadata.port_type != 2w0) {
            fabric_ingress_dst_lkp.apply();
            if (meta.ingress_metadata.port_type == 2w1) {
                if (hdr.fabric_header_multicast.isValid()) 
                    fabric_ingress_src_lkp.apply();
                if (meta.tunnel_metadata.tunnel_terminate == 1w0) 
                    native_packet_over_fabric.apply();
            }
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
            nop();
            set_unicast();
            set_unicast_and_ipv6_src_is_link_local();
            set_multicast();
            set_multicast_and_ipv6_src_is_link_local();
            set_broadcast();
            set_malformed_packet();
            @defaultonly NoAction();
        }
        key = {
            meta.l2_metadata.lkp_mac_sa          : ternary @name("meta.l2_metadata.lkp_mac_sa") ;
            meta.l2_metadata.lkp_mac_da          : ternary @name("meta.l2_metadata.lkp_mac_da") ;
            meta.l3_metadata.lkp_ip_type         : ternary @name("meta.l3_metadata.lkp_ip_type") ;
            meta.l3_metadata.lkp_ip_ttl          : ternary @name("meta.l3_metadata.lkp_ip_ttl") ;
            meta.l3_metadata.lkp_ip_version      : ternary @name("meta.l3_metadata.lkp_ip_version") ;
            meta.ipv4_metadata.lkp_ipv4_sa[31:24]: ternary @name("meta.ipv4_metadata.lkp_ipv4_sa[31:24]") ;
        }
        size = 64;
        default_action = NoAction();
    }
    apply {
        if ((meta.ingress_metadata.bypass_lookups & 16w0x40) == 16w0 && meta.ingress_metadata.drop_flag == 1w0) 
            validate_packet.apply();
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
        meta.ig_intr_md_for_tm.mcast_grp_b = mc_index;
        meta.fabric_metadata.dst_device = 8w127;
    }
    @name(".dmac_miss") action dmac_miss() {
        meta.ingress_metadata.egress_ifindex = 16w65535;
        meta.fabric_metadata.dst_device = 8w127;
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
            nop();
            dmac_hit();
            dmac_multicast_hit();
            dmac_miss();
            dmac_redirect_nexthop();
            dmac_redirect_ecmp();
            dmac_drop();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.bd   : exact @name("meta.ingress_metadata.bd") ;
            meta.l2_metadata.lkp_mac_da: exact @name("meta.l2_metadata.lkp_mac_da") ;
        }
        size = 512000;
        default_action = NoAction();
    }
    @name("smac") table smac {
        actions = {
            nop();
            smac_miss();
            smac_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.bd   : exact @name("meta.ingress_metadata.bd") ;
            meta.l2_metadata.lkp_mac_sa: exact @name("meta.l2_metadata.lkp_mac_sa") ;
        }
        size = 512000;
        default_action = NoAction();
    }
    apply {
        if ((meta.ingress_metadata.bypass_lookups & 16w0x80) == 16w0 && meta.ingress_metadata.port_type == 2w0) 
            smac.apply();
        if ((meta.ingress_metadata.bypass_lookups & 16w0x1) == 16w0) 
            dmac.apply();
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
            nop();
            acl_deny();
            acl_permit();
            acl_redirect_nexthop();
            acl_redirect_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.acl_metadata.if_label   : ternary @name("meta.acl_metadata.if_label") ;
            meta.acl_metadata.bd_label   : ternary @name("meta.acl_metadata.bd_label") ;
            meta.l2_metadata.lkp_mac_sa  : ternary @name("meta.l2_metadata.lkp_mac_sa") ;
            meta.l2_metadata.lkp_mac_da  : ternary @name("meta.l2_metadata.lkp_mac_da") ;
            meta.l2_metadata.lkp_mac_type: ternary @name("meta.l2_metadata.lkp_mac_type") ;
        }
        size = 128;
        default_action = NoAction();
    }
    apply {
        if ((meta.ingress_metadata.bypass_lookups & 16w0x4) == 16w0) 
            mac_acl.apply();
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
            nop();
            acl_deny();
            acl_permit();
            acl_redirect_nexthop();
            acl_redirect_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.acl_metadata.if_label                 : ternary @name("meta.acl_metadata.if_label") ;
            meta.acl_metadata.bd_label                 : ternary @name("meta.acl_metadata.bd_label") ;
            meta.ipv4_metadata.lkp_ipv4_sa             : ternary @name("meta.ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da             : ternary @name("meta.ipv4_metadata.lkp_ipv4_da") ;
            meta.l3_metadata.lkp_ip_proto              : ternary @name("meta.l3_metadata.lkp_ip_proto") ;
            meta.acl_metadata.ingress_src_port_range_id: exact @name("meta.acl_metadata.ingress_src_port_range_id") ;
            meta.acl_metadata.ingress_dst_port_range_id: exact @name("meta.acl_metadata.ingress_dst_port_range_id") ;
            hdr.tcp.flags                              : ternary @name("hdr.tcp.flags") ;
            meta.l3_metadata.lkp_ip_ttl                : ternary @name("meta.l3_metadata.lkp_ip_ttl") ;
        }
        size = 128;
        default_action = NoAction();
    }
    apply {
        if ((meta.ingress_metadata.bypass_lookups & 16w0x4) == 16w0) 
            if (meta.l3_metadata.lkp_ip_type == 2w1) 
                ip_acl.apply();
            else 
                ;
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
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>, bit<8>, bit<16>, bit<16>>, bit<32>>(meta.hash_metadata.hash1, HashAlgorithm.crc16, 16w0, { meta.ipv4_metadata.lkp_ipv4_sa, meta.ipv4_metadata.lkp_ipv4_da, meta.l3_metadata.lkp_ip_proto, meta.l3_metadata.lkp_l4_sport, meta.l3_metadata.lkp_l4_dport }, 32w65536);
        hash<bit<16>, bit<16>, tuple<bit<48>, bit<48>, bit<32>, bit<32>, bit<8>, bit<16>, bit<16>>, bit<32>>(meta.hash_metadata.hash2, HashAlgorithm.crc16, 16w0, { meta.l2_metadata.lkp_mac_sa, meta.l2_metadata.lkp_mac_da, meta.ipv4_metadata.lkp_ipv4_sa, meta.ipv4_metadata.lkp_ipv4_da, meta.l3_metadata.lkp_ip_proto, meta.l3_metadata.lkp_l4_sport, meta.l3_metadata.lkp_l4_dport }, 32w65536);
    }
    @name(".compute_lkp_non_ip_hash") action compute_lkp_non_ip_hash() {
        hash<bit<16>, bit<16>, tuple<bit<16>, bit<48>, bit<48>, bit<16>>, bit<32>>(meta.hash_metadata.hash2, HashAlgorithm.crc16, 16w0, { meta.ingress_metadata.ifindex, meta.l2_metadata.lkp_mac_sa, meta.l2_metadata.lkp_mac_da, meta.l2_metadata.lkp_mac_type }, 32w65536);
    }
    @name(".computed_two_hashes") action computed_two_hashes() {
        meta.ig_intr_md_for_tm.level1_mcast_hash = (bit<13>)meta.hash_metadata.hash1;
        meta.ig_intr_md_for_tm.level2_mcast_hash = (bit<13>)meta.hash_metadata.hash2;
        meta.hash_metadata.entropy_hash = meta.hash_metadata.hash2;
    }
    @name(".computed_one_hash") action computed_one_hash() {
        meta.hash_metadata.hash1 = meta.hash_metadata.hash2;
        meta.ig_intr_md_for_tm.level1_mcast_hash = (bit<13>)meta.hash_metadata.hash2;
        meta.ig_intr_md_for_tm.level2_mcast_hash = (bit<13>)meta.hash_metadata.hash2;
        meta.hash_metadata.entropy_hash = meta.hash_metadata.hash2;
    }
    @name("compute_ipv4_hashes") table compute_ipv4_hashes {
        actions = {
            compute_lkp_ipv4_hash();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @name("compute_non_ip_hashes") table compute_non_ip_hashes {
        actions = {
            compute_lkp_non_ip_hash();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @ternary(1) @name("compute_other_hashes") table compute_other_hashes {
        actions = {
            computed_two_hashes();
            computed_one_hash();
            @defaultonly NoAction();
        }
        key = {
            meta.hash_metadata.hash1: exact @name("meta.hash_metadata.hash1") ;
        }
        default_action = NoAction();
    }
    apply {
        if (meta.tunnel_metadata.tunnel_terminate == 1w0 && hdr.ipv4.isValid() || meta.tunnel_metadata.tunnel_terminate == 1w1 && hdr.inner_ipv4.isValid()) 
            compute_ipv4_hashes.apply();
        else 
            compute_non_ip_hashes.apply();
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
        ingress_bd_stats.count((bit<32>)meta.l2_metadata.bd_stats_idx);
    }
    @name("ingress_bd_stats") table ingress_bd_stats_0 {
        actions = {
            update_ingress_bd_stats();
            @defaultonly NoAction();
        }
        size = 16384;
        default_action = NoAction();
    }
    apply {
        ingress_bd_stats_0.apply();
    }
}

control process_ingress_acl_stats(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("acl_stats") @min_width(16) counter(32w128, CounterType.packets_and_bytes) acl_stats;
    @name(".acl_stats_update") action acl_stats_update() {
        acl_stats.count((bit<32>)meta.acl_metadata.acl_stats_index);
    }
    @name("acl_stats") table acl_stats_0 {
        actions = {
            acl_stats_update();
            @defaultonly NoAction();
        }
        size = 128;
        default_action = NoAction();
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
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name(".set_fib_redirect_action") action set_fib_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.l3_metadata.fib_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.l3_metadata.fib_nexthop_type;
        meta.l3_metadata.routed = 1w1;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
        meta.fabric_metadata.reason_code = 16w0x217;
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name(".set_cpu_redirect_action") action set_cpu_redirect_action() {
        meta.l3_metadata.routed = 1w0;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
        meta.ig_intr_md_for_tm.ucast_egress_port = 9w64;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name(".set_acl_redirect_action") action set_acl_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.acl_metadata.acl_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.acl_metadata.acl_nexthop_type;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name(".set_racl_redirect_action") action set_racl_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.acl_metadata.racl_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.acl_metadata.racl_nexthop_type;
        meta.l3_metadata.routed = 1w1;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name("fwd_result") table fwd_result {
        actions = {
            nop();
            set_l2_redirect_action();
            set_fib_redirect_action();
            set_cpu_redirect_action();
            set_acl_redirect_action();
            set_racl_redirect_action();
            @defaultonly NoAction();
        }
        key = {
            meta.l2_metadata.l2_redirect                 : ternary @name("meta.l2_metadata.l2_redirect") ;
            meta.acl_metadata.acl_redirect               : ternary @name("meta.acl_metadata.acl_redirect") ;
            meta.acl_metadata.racl_redirect              : ternary @name("meta.acl_metadata.racl_redirect") ;
            meta.l3_metadata.rmac_hit                    : ternary @name("meta.l3_metadata.rmac_hit") ;
            meta.l3_metadata.fib_hit                     : ternary @name("meta.l3_metadata.fib_hit") ;
            meta.nat_metadata.nat_hit                    : ternary @name("meta.nat_metadata.nat_hit") ;
            meta.l2_metadata.lkp_pkt_type                : ternary @name("meta.l2_metadata.lkp_pkt_type") ;
            meta.l3_metadata.lkp_ip_type                 : ternary @name("meta.l3_metadata.lkp_ip_type") ;
            meta.multicast_metadata.igmp_snooping_enabled: ternary @name("meta.multicast_metadata.igmp_snooping_enabled") ;
            meta.multicast_metadata.mld_snooping_enabled : ternary @name("meta.multicast_metadata.mld_snooping_enabled") ;
            meta.multicast_metadata.mcast_route_hit      : ternary @name("meta.multicast_metadata.mcast_route_hit") ;
            meta.multicast_metadata.mcast_bridge_hit     : ternary @name("meta.multicast_metadata.mcast_bridge_hit") ;
            meta.multicast_metadata.mcast_rpf_group      : ternary @name("meta.multicast_metadata.mcast_rpf_group") ;
            meta.multicast_metadata.mcast_mode           : ternary @name("meta.multicast_metadata.mcast_mode") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.ingress_metadata.bypass_lookups != 16w0xffff) 
            fwd_result.apply();
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
        meta.ig_intr_md_for_tm.disable_ucast_cutthru = meta.l2_metadata.non_ip_packet & tunnel;
    }
    @name(".set_ecmp_nexthop_details_for_post_routed_flood") action set_ecmp_nexthop_details_for_post_routed_flood(bit<14> bd, bit<16> uuc_mc_index, bit<16> nhop_index) {
        meta.ig_intr_md_for_tm.mcast_grp_b = uuc_mc_index;
        meta.l3_metadata.nexthop_index = nhop_index;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.fabric_metadata.dst_device = 8w127;
    }
    @name(".set_nexthop_details") action set_nexthop_details(bit<16> ifindex, bit<14> bd, bit<1> tunnel) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.l2_metadata.same_if_check = meta.l2_metadata.same_if_check ^ ifindex;
        meta.tunnel_metadata.tunnel_if_check = meta.tunnel_metadata.tunnel_terminate ^ tunnel;
        meta.ig_intr_md_for_tm.disable_ucast_cutthru = meta.l2_metadata.non_ip_packet & tunnel;
    }
    @name(".set_nexthop_details_for_post_routed_flood") action set_nexthop_details_for_post_routed_flood(bit<14> bd, bit<16> uuc_mc_index) {
        meta.ig_intr_md_for_tm.mcast_grp_b = uuc_mc_index;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.fabric_metadata.dst_device = 8w127;
    }
    @name("ecmp_group") table ecmp_group {
        actions = {
            nop();
            set_ecmp_nexthop_details();
            set_ecmp_nexthop_details_for_post_routed_flood();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.nexthop_index: exact @name("meta.l3_metadata.nexthop_index") ;
            meta.hash_metadata.hash1      : selector @name("meta.hash_metadata.hash1") ;
        }
        size = 1024;
        @name("ecmp_action_profile") @mode("fair") implementation = action_selector(HashAlgorithm.identity, 32w16384, 32w14);
        default_action = NoAction();
    }
    @name("nexthop") table nexthop {
        actions = {
            nop();
            set_nexthop_details();
            set_nexthop_details_for_post_routed_flood();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.nexthop_index: exact @name("meta.l3_metadata.nexthop_index") ;
        }
        size = 16384;
        default_action = NoAction();
    }
    apply {
        if (meta.nexthop_metadata.nexthop_type == 2w1) 
            ecmp_group.apply();
        else 
            nexthop.apply();
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
        meta.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".set_lag_remote_port") action set_lag_remote_port(bit<8> device, bit<16> port) {
        meta.fabric_metadata.dst_device = device;
        meta.fabric_metadata.dst_port = port;
    }
    @name("lag_group") table lag_group {
        actions = {
            set_lag_miss();
            set_lag_port();
            set_lag_remote_port();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.egress_ifindex: exact @name("meta.ingress_metadata.egress_ifindex") ;
            meta.hash_metadata.hash2            : selector @name("meta.hash_metadata.hash2") ;
        }
        size = 1024;
        @name("lag_action_profile") @mode("fair") implementation = action_selector(HashAlgorithm.identity, 32w1024, 32w14);
        default_action = NoAction();
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
        digest<mac_learn_digest>(32w1024, { meta.ingress_metadata.bd, meta.l2_metadata.lkp_mac_sa, meta.ingress_metadata.ifindex });
    }
    @name("learn_notify") table learn_notify {
        actions = {
            nop();
            generate_learn_notify();
            @defaultonly NoAction();
        }
        key = {
            meta.l2_metadata.l2_src_miss: ternary @name("meta.l2_metadata.l2_src_miss") ;
            meta.l2_metadata.l2_src_move: ternary @name("meta.l2_metadata.l2_src_move") ;
            meta.l2_metadata.stp_state  : ternary @name("meta.l2_metadata.stp_state") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.l2_metadata.learning_enabled == 1w1) 
            learn_notify.apply();
    }
}

control process_fabric_lag(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_fabric_lag_port") action set_fabric_lag_port(bit<9> port) {
        meta.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name("fabric_lag") table fabric_lag {
        actions = {
            nop();
            set_fabric_lag_port();
            @defaultonly NoAction();
        }
        key = {
            meta.fabric_metadata.dst_device: exact @name("meta.fabric_metadata.dst_device") ;
            meta.hash_metadata.hash2       : selector @name("meta.hash_metadata.hash2") ;
        }
        @name("fabric_lag_action_profile") @mode("fair") implementation = action_selector(HashAlgorithm.identity, 32w1024, 32w14);
        default_action = NoAction();
    }
    apply {
        fabric_lag.apply();
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
        meta.ig_intr_md_for_tm.qid = qid;
        meta.ig_intr_md_for_tm.ingress_cos = icos;
        clone3<tuple<bit<14>, bit<16>, bit<16>, bit<9>>>(CloneType.I2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
    }
    @name(".redirect_to_cpu") action redirect_to_cpu(bit<5> qid, bit<8> meter_id, bit<3> icos) {
        copy_to_cpu(qid, meter_id, icos);
        mark_to_drop();
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name(".copy_to_cpu_with_reason") action copy_to_cpu_with_reason(bit<16> reason_code, bit<5> qid, bit<8> meter_id, bit<3> icos) {
        meta.fabric_metadata.reason_code = reason_code;
        copy_to_cpu(qid, meter_id, icos);
    }
    @name(".redirect_to_cpu_with_reason") action redirect_to_cpu_with_reason(bit<16> reason_code, bit<5> qid, bit<8> meter_id, bit<3> icos) {
        copy_to_cpu_with_reason(reason_code, qid, meter_id, icos);
        mark_to_drop();
        meta.fabric_metadata.dst_device = 8w0;
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
            drop_stats_update();
            @defaultonly NoAction();
        }
        size = 256;
        default_action = NoAction();
    }
    @name("system_acl") table system_acl {
        actions = {
            nop();
            redirect_to_cpu();
            redirect_to_cpu_with_reason();
            copy_to_cpu();
            copy_to_cpu_with_reason();
            drop_packet();
            drop_packet_with_reason();
            @defaultonly NoAction();
        }
        key = {
            meta.acl_metadata.if_label               : ternary @name("meta.acl_metadata.if_label") ;
            meta.acl_metadata.bd_label               : ternary @name("meta.acl_metadata.bd_label") ;
            meta.ingress_metadata.ifindex            : ternary @name("meta.ingress_metadata.ifindex") ;
            meta.l2_metadata.lkp_mac_type            : ternary @name("meta.l2_metadata.lkp_mac_type") ;
            meta.l2_metadata.port_vlan_mapping_miss  : ternary @name("meta.l2_metadata.port_vlan_mapping_miss") ;
            meta.security_metadata.ipsg_check_fail   : ternary @name("meta.security_metadata.ipsg_check_fail") ;
            meta.acl_metadata.acl_deny               : ternary @name("meta.acl_metadata.acl_deny") ;
            meta.acl_metadata.racl_deny              : ternary @name("meta.acl_metadata.racl_deny") ;
            meta.l3_metadata.urpf_check_fail         : ternary @name("meta.l3_metadata.urpf_check_fail") ;
            meta.ingress_metadata.drop_flag          : ternary @name("meta.ingress_metadata.drop_flag") ;
            meta.l3_metadata.l3_copy                 : ternary @name("meta.l3_metadata.l3_copy") ;
            meta.l3_metadata.rmac_hit                : ternary @name("meta.l3_metadata.rmac_hit") ;
            meta.l3_metadata.routed                  : ternary @name("meta.l3_metadata.routed") ;
            meta.ipv6_metadata.ipv6_src_is_link_local: ternary @name("meta.ipv6_metadata.ipv6_src_is_link_local") ;
            meta.l2_metadata.same_if_check           : ternary @name("meta.l2_metadata.same_if_check") ;
            meta.tunnel_metadata.tunnel_if_check     : ternary @name("meta.tunnel_metadata.tunnel_if_check") ;
            meta.l3_metadata.same_bd_check           : ternary @name("meta.l3_metadata.same_bd_check") ;
            meta.l3_metadata.lkp_ip_ttl              : ternary @name("meta.l3_metadata.lkp_ip_ttl") ;
            meta.l2_metadata.stp_state               : ternary @name("meta.l2_metadata.stp_state") ;
            meta.ingress_metadata.control_frame      : ternary @name("meta.ingress_metadata.control_frame") ;
            meta.ipv4_metadata.ipv4_unicast_enabled  : ternary @name("meta.ipv4_metadata.ipv4_unicast_enabled") ;
            meta.ipv6_metadata.ipv6_unicast_enabled  : ternary @name("meta.ipv6_metadata.ipv6_unicast_enabled") ;
            meta.ingress_metadata.egress_ifindex     : ternary @name("meta.ingress_metadata.egress_ifindex") ;
            meta.fabric_metadata.reason_code         : ternary @name("meta.fabric_metadata.reason_code") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if ((meta.ingress_metadata.bypass_lookups & 16w0x20) == 16w0) {
            system_acl.apply();
            if (meta.ingress_metadata.drop_flag == 1w1) 
                drop_stats_0.apply();
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
            rmac_hit();
            rmac_miss();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.rmac_group: exact @name("meta.l3_metadata.rmac_group") ;
            meta.l2_metadata.lkp_mac_da: exact @name("meta.l2_metadata.lkp_mac_da") ;
        }
        size = 512;
        default_action = NoAction();
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
            if (meta.l3_metadata.lkp_ip_type == 2w0) 
                process_mac_acl_0.apply(hdr, meta, standard_metadata);
            else 
                process_ip_acl_0.apply(hdr, meta, standard_metadata);
            process_int_upstream_report_0.apply(hdr, meta, standard_metadata);
            switch (rmac.apply().action_run) {
                default: {
                    if ((meta.ingress_metadata.bypass_lookups & 16w0x2) == 16w0) {
                        if (meta.l3_metadata.lkp_ip_type == 2w1 && meta.ipv4_metadata.ipv4_unicast_enabled == 1w1) {
                            process_ipv4_racl_0.apply(hdr, meta, standard_metadata);
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
            if (meta.ingress_metadata.egress_ifindex == 16w65535) 
                process_multicast_flooding_0.apply(hdr, meta, standard_metadata);
            else 
                process_lag_0.apply(hdr, meta, standard_metadata);
            process_mac_learning_0.apply(hdr, meta, standard_metadata);
        }
        process_fabric_lag_0.apply(hdr, meta, standard_metadata);
        process_traffic_class_0.apply(hdr, meta, standard_metadata);
        if (meta.ingress_metadata.port_type != 2w1) 
            process_system_acl_0.apply(hdr, meta, standard_metadata);
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
    @name("flowlet_id") register<bit<16>>(32w8192) flowlet_id;
    @name("flowlet_lastseen") register<bit<32>>(32w8192) flowlet_lastseen;
    @name(".flowlet_lookup") action flowlet_lookup() {
        hash<bit<13>, bit<13>, tuple<bit<16>>, bit<26>>(meta.flowlet_metadata.map_index, HashAlgorithm.identity, 13w0, { meta.hash_metadata.hash1 }, 26w8192);
        meta.flowlet_metadata.inter_packet_gap = meta.intrinsic_metadata.ingress_global_timestamp;
        flowlet_id.read(meta.flowlet_metadata.id, (bit<32>)meta.flowlet_metadata.map_index);
        flowlet_lastseen.read(meta.flowlet_metadata.timestamp, (bit<32>)meta.flowlet_metadata.map_index);
        meta.flowlet_metadata.inter_packet_gap = meta.flowlet_metadata.inter_packet_gap - meta.flowlet_metadata.timestamp;
        flowlet_lastseen.write((bit<32>)meta.flowlet_metadata.map_index, meta.intrinsic_metadata.ingress_global_timestamp);
        meta.flowlet_metadata.inter_packet_gap = meta.flowlet_metadata.inter_packet_gap - meta.flowlet_metadata.inactive_timeout;
    }
    @name(".update_flowlet_id") action update_flowlet_id() {
        meta.flowlet_metadata.id = meta.flowlet_metadata.id + 16w1;
        flowlet_id.write((bit<32>)meta.flowlet_metadata.map_index, meta.flowlet_metadata.id);
    }
    @name("flowlet") table flowlet {
        actions = {
            flowlet_lookup();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    @name("new_flowlet") table new_flowlet {
        actions = {
            update_flowlet_id();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    apply {
        if (meta.flowlet_metadata.inactive_timeout != 32w0) {
            flowlet.apply();
            if (meta.flowlet_metadata.inter_packet_gap != 32w0) 
                new_flowlet.apply();
        }
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

control validate_mpls_header(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<fabric_header_t>(hdr.fabric_header);
        packet.emit<fabric_header_cpu_t>(hdr.fabric_header_cpu);
        packet.emit<fabric_header_mirror_t>(hdr.fabric_header_mirror);
        packet.emit<fabric_header_multicast_t>(hdr.fabric_header_multicast);
        packet.emit<fabric_header_unicast_t>(hdr.fabric_header_unicast);
        packet.emit<fabric_payload_header_t>(hdr.fabric_payload_header);
        packet.emit<llc_header_t>(hdr.llc_header);
        packet.emit<snap_header_t>(hdr.snap_header);
        packet.emit<vlan_tag_t>(hdr.vlan_tag_[0]);
        packet.emit<vlan_tag_t>(hdr.vlan_tag_[1]);
        packet.emit<ipv6_t>(hdr.ipv6);
        packet.emit<ipv4_t>(hdr.ipv4);
        packet.emit<udp_t>(hdr.udp);
        packet.emit<vxlan_gpe_t>(hdr.vxlan_gpe);
        packet.emit<ethernet_t>(hdr.inner_ethernet);
        packet.emit<ipv6_t>(hdr.inner_ipv6);
        packet.emit<ipv4_t>(hdr.inner_ipv4);
        packet.emit<udp_t>(hdr.inner_udp);
        packet.emit<tcp_t>(hdr.inner_tcp);
        packet.emit<icmp_t>(hdr.inner_icmp);
        packet.emit<vxlan_gpe_int_header_t>(hdr.vxlan_gpe_int_plt_header);
        packet.emit<int_plt_header_t>(hdr.int_plt_header);
        packet.emit<vxlan_gpe_int_header_t>(hdr.vxlan_gpe_int_header);
        packet.emit<int_header_t>(hdr.int_header);
        packet.emit<int_switch_id_header_t>(hdr.int_switch_id_header);
        packet.emit<int_port_ids_header_t>(hdr.int_port_ids_header);
        packet.emit<int_hop_latency_header_t>(hdr.int_hop_latency_header);
        packet.emit<int_q_occupancy_header_t>(hdr.int_q_occupancy_header);
        packet.emit<tcp_t>(hdr.tcp);
        packet.emit<icmp_t>(hdr.icmp);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta) {
    Checksum16() inner_ipv4_checksum;
    Checksum16() ipv4_checksum;
    apply {
        if (hdr.inner_ipv4.ihl == 4w5 && hdr.inner_ipv4.hdrChecksum == (inner_ipv4_checksum.get<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>>({ hdr.inner_ipv4.version, hdr.inner_ipv4.ihl, hdr.inner_ipv4.diffserv, hdr.inner_ipv4.totalLen, hdr.inner_ipv4.identification, hdr.inner_ipv4.flags, hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.ttl, hdr.inner_ipv4.protocol, hdr.inner_ipv4.srcAddr, hdr.inner_ipv4.dstAddr }))) 
            mark_to_drop();
        if (hdr.ipv4.ihl == 4w5 && hdr.ipv4.hdrChecksum == (ipv4_checksum.get<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }))) 
            mark_to_drop();
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    Checksum16() inner_ipv4_checksum;
    Checksum16() ipv4_checksum;
    apply {
        if (hdr.inner_ipv4.ihl == 4w5) 
            hdr.inner_ipv4.hdrChecksum = inner_ipv4_checksum.get<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>>({ hdr.inner_ipv4.version, hdr.inner_ipv4.ihl, hdr.inner_ipv4.diffserv, hdr.inner_ipv4.totalLen, hdr.inner_ipv4.identification, hdr.inner_ipv4.flags, hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.ttl, hdr.inner_ipv4.protocol, hdr.inner_ipv4.srcAddr, hdr.inner_ipv4.dstAddr });
        if (hdr.ipv4.ihl == 4w5) 
            hdr.ipv4.hdrChecksum = ipv4_checksum.get<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr });
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
