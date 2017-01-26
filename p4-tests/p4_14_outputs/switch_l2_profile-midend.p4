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

header erspan_header_t3_t {
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
    erspan_header_t3_t                      erspan_t3_header;
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
    @name("parse_arp_rarp") state parse_arp_rarp {
        transition parse_set_prio_med;
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
    @name("parse_gpe_int_header") state parse_gpe_int_header {
        transition select((packet.lookahead<bit<8>>())[7:0]) {
            8w3: parse_int_shim_plt_header;
            default: parse_int_shim_header;
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
    @name("parse_set_prio_high") state parse_set_prio_high {
        meta.ig_prsr_ctrl.priority = 3w5;
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
        transition select((packet.lookahead<bit<112>>())[111:96]) {
            default: parse_ethernet;
        }
    }
}

struct tuple_0 {
    bit<14> field;
    bit<16> field_0;
    bit<16> field_1;
    bit<9>  field_2;
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("NoAction_2") action NoAction_0() {
    }
    @name("NoAction_3") action NoAction_1() {
    }
    @name("NoAction_4") action NoAction_57() {
    }
    @name("NoAction_5") action NoAction_58() {
    }
    @name("NoAction_6") action NoAction_59() {
    }
    @name("NoAction_7") action NoAction_60() {
    }
    @name("NoAction_8") action NoAction_61() {
    }
    @name("NoAction_9") action NoAction_62() {
    }
    @name("NoAction_10") action NoAction_63() {
    }
    @name("NoAction_11") action NoAction_64() {
    }
    @name("NoAction_12") action NoAction_65() {
    }
    @name("NoAction_13") action NoAction_66() {
    }
    @name("NoAction_14") action NoAction_67() {
    }
    @name("NoAction_15") action NoAction_68() {
    }
    @name("NoAction_16") action NoAction_69() {
    }
    @name("NoAction_17") action NoAction_70() {
    }
    @name("NoAction_18") action NoAction_71() {
    }
    @name("NoAction_19") action NoAction_72() {
    }
    @name("NoAction_20") action NoAction_73() {
    }
    @name("NoAction_21") action NoAction_74() {
    }
    @name("NoAction_22") action NoAction_75() {
    }
    @name("NoAction_23") action NoAction_76() {
    }
    @name("NoAction_24") action NoAction_77() {
    }
    @name("NoAction_25") action NoAction_78() {
    }
    @name("NoAction_26") action NoAction_79() {
    }
    @name("NoAction_27") action NoAction_80() {
    }
    @name("egress_port_type_normal") action egress_port_type_normal_0(bit<16> ifindex, bit<5> qos_group, bit<16> if_label) {
        meta.egress_metadata.port_type = 2w0;
        meta.egress_metadata.ifindex = ifindex;
        meta.qos_metadata.egress_qos_group = qos_group;
        meta.acl_metadata.egress_if_label = if_label;
    }
    @name("egress_port_type_fabric") action egress_port_type_fabric_0(bit<16> ifindex) {
        meta.egress_metadata.port_type = 2w1;
        meta.egress_metadata.ifindex = ifindex;
        meta.tunnel_metadata.egress_tunnel_type = 5w15;
    }
    @name("egress_port_type_cpu") action egress_port_type_cpu_0(bit<16> ifindex) {
        meta.egress_metadata.port_type = 2w2;
        meta.egress_metadata.ifindex = ifindex;
        meta.tunnel_metadata.egress_tunnel_type = 5w16;
    }
    @name("egress_port_mapping") table egress_port_mapping() {
        actions = {
            egress_port_type_normal_0();
            egress_port_type_fabric_0();
            egress_port_type_cpu_0();
            @default_only NoAction_0();
        }
        key = {
            meta.eg_intr_md.egress_port: exact;
        }
        size = 288;
        default_action = NoAction_0();
    }
    @name("process_int_egress_prep.quantize_latency_1") action process_int_egress_prep_quantize_latency() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 1;
    }
    @name("process_int_egress_prep.quantize_latency_2") action process_int_egress_prep_quantize_latency_0() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 2;
    }
    @name("process_int_egress_prep.quantize_latency_3") action process_int_egress_prep_quantize_latency_1() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 3;
    }
    @name("process_int_egress_prep.quantize_latency_4") action process_int_egress_prep_quantize_latency_2() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 4;
    }
    @name("process_int_egress_prep.quantize_latency_5") action process_int_egress_prep_quantize_latency_3() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 5;
    }
    @name("process_int_egress_prep.quantize_latency_6") action process_int_egress_prep_quantize_latency_4() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 6;
    }
    @name("process_int_egress_prep.quantize_latency_7") action process_int_egress_prep_quantize_latency_5() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 7;
    }
    @name("process_int_egress_prep.quantize_latency_8") action process_int_egress_prep_quantize_latency_6() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 8;
    }
    @name("process_int_egress_prep.quantize_latency_9") action process_int_egress_prep_quantize_latency_7() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 9;
    }
    @name("process_int_egress_prep.quantize_latency_10") action process_int_egress_prep_quantize_latency_8() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 10;
    }
    @name("process_int_egress_prep.quantize_latency_11") action process_int_egress_prep_quantize_latency_9() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 11;
    }
    @name("process_int_egress_prep.quantize_latency_12") action process_int_egress_prep_quantize_latency_10() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 12;
    }
    @name("process_int_egress_prep.quantize_latency_13") action process_int_egress_prep_quantize_latency_11() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 13;
    }
    @name("process_int_egress_prep.quantize_latency_14") action process_int_egress_prep_quantize_latency_12() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 14;
    }
    @name("process_int_egress_prep.quantize_latency_15") action process_int_egress_prep_quantize_latency_13() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 15;
    }
    @name("process_int_egress_prep.copy_latency") action process_int_egress_prep_copy_latency() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta;
    }
    @name("process_int_egress_prep.scramble_latency") action process_int_egress_prep_scramble_latency() {
        meta.int_metadata.quantized_latency = meta.global_config_metadata.switch_id - meta.int_metadata.quantized_latency;
    }
    @name("process_int_egress_prep.plt_quantize_latency") table process_int_egress_prep_plt_quantize_latency_0() {
        actions = {
            process_int_egress_prep_quantize_latency();
            process_int_egress_prep_quantize_latency_0();
            process_int_egress_prep_quantize_latency_1();
            process_int_egress_prep_quantize_latency_2();
            process_int_egress_prep_quantize_latency_3();
            process_int_egress_prep_quantize_latency_4();
            process_int_egress_prep_quantize_latency_5();
            process_int_egress_prep_quantize_latency_6();
            process_int_egress_prep_quantize_latency_7();
            process_int_egress_prep_quantize_latency_8();
            process_int_egress_prep_quantize_latency_9();
            process_int_egress_prep_quantize_latency_10();
            process_int_egress_prep_quantize_latency_11();
            process_int_egress_prep_quantize_latency_12();
            process_int_egress_prep_quantize_latency_13();
            process_int_egress_prep_copy_latency();
            @default_only NoAction_1();
        }
        key = {
            hdr.ethernet.isValid(): exact;
        }
        size = 2;
        default_action = NoAction_1();
    }
    @name("process_int_egress_prep.plt_scramble_latency") table process_int_egress_prep_plt_scramble_latency_0() {
        actions = {
            process_int_egress_prep_scramble_latency();
            @default_only NoAction_57();
        }
        size = 1;
        default_action = NoAction_57();
    }
    @name("process_vlan_decap.nop") action process_vlan_decap_nop() {
    }
    @name("process_vlan_decap.remove_vlan_single_tagged") action process_vlan_decap_remove_vlan_single_tagged() {
        hdr.ethernet.etherType = hdr.vlan_tag_[0].etherType;
        hdr.vlan_tag_[0].setInvalid();
    }
    @name("process_vlan_decap.remove_vlan_double_tagged") action process_vlan_decap_remove_vlan_double_tagged() {
        hdr.ethernet.etherType = hdr.vlan_tag_[1].etherType;
        hdr.vlan_tag_[0].setInvalid();
        hdr.vlan_tag_[1].setInvalid();
    }
    @ternary(1) @name("process_vlan_decap.vlan_decap") table process_vlan_decap_vlan_decap_0() {
        actions = {
            process_vlan_decap_nop();
            process_vlan_decap_remove_vlan_single_tagged();
            process_vlan_decap_remove_vlan_double_tagged();
            @default_only NoAction_58();
        }
        key = {
            hdr.vlan_tag_[0].isValid(): exact;
            hdr.vlan_tag_[1].isValid(): exact;
        }
        size = 256;
        default_action = NoAction_58();
    }
    @name("process_rewrite.nop") action process_rewrite_nop() {
    }
    @name("process_rewrite.set_l2_rewrite") action process_rewrite_set_l2_rewrite() {
        meta.egress_metadata.routed = 1w0;
        meta.egress_metadata.bd = meta.ingress_metadata.bd;
        meta.egress_metadata.outer_bd = meta.ingress_metadata.bd;
    }
    @name("process_rewrite.rewrite") table process_rewrite_rewrite_0() {
        actions = {
            process_rewrite_nop();
            process_rewrite_set_l2_rewrite();
            @default_only NoAction_59();
        }
        key = {
            meta.l3_metadata.nexthop_index: exact;
        }
        size = 16384;
        default_action = NoAction_59();
    }
    @name("process_egress_bd.nop") action process_egress_bd_nop() {
    }
    @name("process_egress_bd.set_egress_bd_properties") action process_egress_bd_set_egress_bd_properties(bit<9> smac_idx, bit<2> nat_mode, bit<16> bd_label) {
        meta.egress_metadata.smac_idx = smac_idx;
        meta.nat_metadata.egress_nat_mode = nat_mode;
        meta.acl_metadata.egress_bd_label = bd_label;
    }
    @name("process_egress_bd.egress_bd_map") table process_egress_bd_egress_bd_map_0() {
        actions = {
            process_egress_bd_nop();
            process_egress_bd_set_egress_bd_properties();
            @default_only NoAction_60();
        }
        key = {
            meta.egress_metadata.bd: exact;
        }
        size = 16384;
        default_action = NoAction_60();
    }
    @name("process_egress_bd_stats.nop") action process_egress_bd_stats_nop() {
    }
    @name("process_egress_bd_stats.egress_bd_stats") table process_egress_bd_stats_egress_bd_stats_0() {
        actions = {
            process_egress_bd_stats_nop();
            @default_only NoAction_61();
        }
        key = {
            meta.egress_metadata.bd      : exact;
            meta.l2_metadata.lkp_pkt_type: exact;
        }
        size = 16384;
        default_action = NoAction_61();
        @name("egress_bd_stats") counters = direct_counter(CounterType.packets_and_bytes);
    }
    @name("process_egress_l4port.nop") action process_egress_l4port_nop() {
    }
    @name("process_egress_l4port.set_egress_tcp_port_fields") action process_egress_l4port_set_egress_tcp_port_fields() {
        meta.l3_metadata.egress_l4_sport = hdr.tcp.srcPort;
        meta.l3_metadata.egress_l4_dport = hdr.tcp.dstPort;
    }
    @name("process_egress_l4port.set_egress_udp_port_fields") action process_egress_l4port_set_egress_udp_port_fields() {
        meta.l3_metadata.egress_l4_sport = hdr.udp.srcPort;
        meta.l3_metadata.egress_l4_dport = hdr.udp.dstPort;
    }
    @name("process_egress_l4port.set_egress_icmp_port_fields") action process_egress_l4port_set_egress_icmp_port_fields() {
        meta.l3_metadata.egress_l4_sport = hdr.icmp.typeCode;
    }
    @name("process_egress_l4port.egress_l4port_fields") table process_egress_l4port_egress_l4port_fields_0() {
        actions = {
            process_egress_l4port_nop();
            process_egress_l4port_set_egress_tcp_port_fields();
            process_egress_l4port_set_egress_udp_port_fields();
            process_egress_l4port_set_egress_icmp_port_fields();
            @default_only NoAction_62();
        }
        key = {
            hdr.tcp.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.icmp.isValid(): exact;
        }
        size = 4;
        default_action = NoAction_62();
    }
    @name("process_int_egress.process_int_insertion.int_set_header_0_bos") action process_int_egress_process_int_insertion_int_set_header_0_bos() {
        hdr.int_switch_id_header.bos = 1w1;
    }
    @name("process_int_egress.process_int_insertion.int_set_header_1_bos") action process_int_egress_process_int_insertion_int_set_header_1_bos() {
        hdr.int_port_ids_header.bos = 1w1;
    }
    @name("process_int_egress.process_int_insertion.int_set_header_2_bos") action process_int_egress_process_int_insertion_int_set_header_2_bos() {
        hdr.int_hop_latency_header.bos = 1w1;
    }
    @name("process_int_egress.process_int_insertion.int_set_header_3_bos") action process_int_egress_process_int_insertion_int_set_header_3_bos() {
        hdr.int_q_occupancy_header.bos = 1w1;
    }
    @name("process_int_egress.process_int_insertion.nop") action process_int_egress_process_int_insertion_nop() {
    }
    @name("process_int_egress.process_int_insertion.nop") action process_int_egress_process_int_insertion_nop_5() {
    }
    @name("process_int_egress.process_int_insertion.nop") action process_int_egress_process_int_insertion_nop_6() {
    }
    @name("process_int_egress.process_int_insertion.nop") action process_int_egress_process_int_insertion_nop_7() {
    }
    @name("process_int_egress.process_int_insertion.nop") action process_int_egress_process_int_insertion_nop_8() {
    }
    @name("process_int_egress.process_int_insertion.int_transit") action process_int_egress_process_int_insertion_int_transit() {
        meta.int_metadata.hit_state = 2w1;
        meta.int_metadata.insert_cnt = hdr.int_header.max_hop_cnt - hdr.int_header.total_hop_cnt;
        meta.int_metadata.insert_byte_cnt = (bit<16>)(meta.int_metadata.int_hdr_word_len << 2);
    }
    @name("process_int_egress.process_int_insertion.int_reset") action process_int_egress_process_int_insertion_int_reset() {
        meta.int_metadata.insert_cnt = 8w0;
        meta.int_metadata.int_hdr_word_len = 8w0;
    }
    @name("process_int_egress.process_int_insertion.int_set_header_0003_i0") action process_int_egress_process_int_insertion_int_set_header_0003_i0() {
    }
    @name("process_int_egress.process_int_insertion.int_set_header_0003_i1") action process_int_egress_process_int_insertion_int_set_header_0003_i1() {
        hdr.int_q_occupancy_header.setValid();
        hdr.int_q_occupancy_header.q_occupancy1 = 7w0;
        hdr.int_q_occupancy_header.q_occupancy0 = (bit<24>)meta.eg_intr_md.enq_qdepth;
    }
    @name("process_int_egress.process_int_insertion.int_set_header_0003_i2") action process_int_egress_process_int_insertion_int_set_header_0003_i2() {
        hdr.int_hop_latency_header.setValid();
        hdr.int_hop_latency_header.hop_latency = (bit<31>)meta.eg_intr_md.deq_timedelta;
    }
    @name("process_int_egress.process_int_insertion.int_set_header_0003_i3") action process_int_egress_process_int_insertion_int_set_header_0003_i3() {
        hdr.int_q_occupancy_header.setValid();
        hdr.int_q_occupancy_header.q_occupancy1 = 7w0;
        hdr.int_q_occupancy_header.q_occupancy0 = (bit<24>)meta.eg_intr_md.enq_qdepth;
        hdr.int_hop_latency_header.setValid();
        hdr.int_hop_latency_header.hop_latency = (bit<31>)meta.eg_intr_md.deq_timedelta;
    }
    @name("process_int_egress.process_int_insertion.int_set_header_0003_i4") action process_int_egress_process_int_insertion_int_set_header_0003_i4() {
        hdr.int_port_ids_header.setValid();
        hdr.int_port_ids_header.ingress_port_id = meta.ingress_metadata.ingress_port;
        hdr.int_port_ids_header.egress_port_id = (bit<16>)meta.eg_intr_md.egress_port;
    }
    @name("process_int_egress.process_int_insertion.int_set_header_0003_i5") action process_int_egress_process_int_insertion_int_set_header_0003_i5() {
        hdr.int_q_occupancy_header.setValid();
        hdr.int_q_occupancy_header.q_occupancy1 = 7w0;
        hdr.int_q_occupancy_header.q_occupancy0 = (bit<24>)meta.eg_intr_md.enq_qdepth;
        hdr.int_port_ids_header.setValid();
        hdr.int_port_ids_header.ingress_port_id = meta.ingress_metadata.ingress_port;
        hdr.int_port_ids_header.egress_port_id = (bit<16>)meta.eg_intr_md.egress_port;
    }
    @name("process_int_egress.process_int_insertion.int_set_header_0003_i6") action process_int_egress_process_int_insertion_int_set_header_0003_i6() {
        hdr.int_hop_latency_header.setValid();
        hdr.int_hop_latency_header.hop_latency = (bit<31>)meta.eg_intr_md.deq_timedelta;
        hdr.int_port_ids_header.setValid();
        hdr.int_port_ids_header.ingress_port_id = meta.ingress_metadata.ingress_port;
        hdr.int_port_ids_header.egress_port_id = (bit<16>)meta.eg_intr_md.egress_port;
    }
    @name("process_int_egress.process_int_insertion.int_set_header_0003_i7") action process_int_egress_process_int_insertion_int_set_header_0003_i7() {
        hdr.int_q_occupancy_header.setValid();
        hdr.int_q_occupancy_header.q_occupancy1 = 7w0;
        hdr.int_q_occupancy_header.q_occupancy0 = (bit<24>)meta.eg_intr_md.enq_qdepth;
        hdr.int_hop_latency_header.setValid();
        hdr.int_hop_latency_header.hop_latency = (bit<31>)meta.eg_intr_md.deq_timedelta;
        hdr.int_port_ids_header.setValid();
        hdr.int_port_ids_header.ingress_port_id = meta.ingress_metadata.ingress_port;
        hdr.int_port_ids_header.egress_port_id = (bit<16>)meta.eg_intr_md.egress_port;
    }
    @name("process_int_egress.process_int_insertion.int_set_header_0003_i8") action process_int_egress_process_int_insertion_int_set_header_0003_i8() {
        hdr.int_switch_id_header.setValid();
        hdr.int_switch_id_header.switch_id = (bit<31>)meta.global_config_metadata.switch_id;
    }
    @name("process_int_egress.process_int_insertion.int_set_header_0003_i9") action process_int_egress_process_int_insertion_int_set_header_0003_i9() {
        hdr.int_q_occupancy_header.setValid();
        hdr.int_q_occupancy_header.q_occupancy1 = 7w0;
        hdr.int_q_occupancy_header.q_occupancy0 = (bit<24>)meta.eg_intr_md.enq_qdepth;
        hdr.int_switch_id_header.setValid();
        hdr.int_switch_id_header.switch_id = (bit<31>)meta.global_config_metadata.switch_id;
    }
    @name("process_int_egress.process_int_insertion.int_set_header_0003_i10") action process_int_egress_process_int_insertion_int_set_header_0003_i10() {
        hdr.int_hop_latency_header.setValid();
        hdr.int_hop_latency_header.hop_latency = (bit<31>)meta.eg_intr_md.deq_timedelta;
        hdr.int_switch_id_header.setValid();
        hdr.int_switch_id_header.switch_id = (bit<31>)meta.global_config_metadata.switch_id;
    }
    @name("process_int_egress.process_int_insertion.int_set_header_0003_i11") action process_int_egress_process_int_insertion_int_set_header_0003_i11() {
        hdr.int_q_occupancy_header.setValid();
        hdr.int_q_occupancy_header.q_occupancy1 = 7w0;
        hdr.int_q_occupancy_header.q_occupancy0 = (bit<24>)meta.eg_intr_md.enq_qdepth;
        hdr.int_hop_latency_header.setValid();
        hdr.int_hop_latency_header.hop_latency = (bit<31>)meta.eg_intr_md.deq_timedelta;
        hdr.int_switch_id_header.setValid();
        hdr.int_switch_id_header.switch_id = (bit<31>)meta.global_config_metadata.switch_id;
    }
    @name("process_int_egress.process_int_insertion.int_set_header_0003_i12") action process_int_egress_process_int_insertion_int_set_header_0003_i12() {
        hdr.int_port_ids_header.setValid();
        hdr.int_port_ids_header.ingress_port_id = meta.ingress_metadata.ingress_port;
        hdr.int_port_ids_header.egress_port_id = (bit<16>)meta.eg_intr_md.egress_port;
        hdr.int_switch_id_header.setValid();
        hdr.int_switch_id_header.switch_id = (bit<31>)meta.global_config_metadata.switch_id;
    }
    @name("process_int_egress.process_int_insertion.int_set_header_0003_i13") action process_int_egress_process_int_insertion_int_set_header_0003_i13() {
        hdr.int_q_occupancy_header.setValid();
        hdr.int_q_occupancy_header.q_occupancy1 = 7w0;
        hdr.int_q_occupancy_header.q_occupancy0 = (bit<24>)meta.eg_intr_md.enq_qdepth;
        hdr.int_port_ids_header.setValid();
        hdr.int_port_ids_header.ingress_port_id = meta.ingress_metadata.ingress_port;
        hdr.int_port_ids_header.egress_port_id = (bit<16>)meta.eg_intr_md.egress_port;
        hdr.int_switch_id_header.setValid();
        hdr.int_switch_id_header.switch_id = (bit<31>)meta.global_config_metadata.switch_id;
    }
    @name("process_int_egress.process_int_insertion.int_set_header_0003_i14") action process_int_egress_process_int_insertion_int_set_header_0003_i14() {
        hdr.int_hop_latency_header.setValid();
        hdr.int_hop_latency_header.hop_latency = (bit<31>)meta.eg_intr_md.deq_timedelta;
        hdr.int_port_ids_header.setValid();
        hdr.int_port_ids_header.ingress_port_id = meta.ingress_metadata.ingress_port;
        hdr.int_port_ids_header.egress_port_id = (bit<16>)meta.eg_intr_md.egress_port;
        hdr.int_switch_id_header.setValid();
        hdr.int_switch_id_header.switch_id = (bit<31>)meta.global_config_metadata.switch_id;
    }
    @name("process_int_egress.process_int_insertion.int_set_header_0003_i15") action process_int_egress_process_int_insertion_int_set_header_0003_i15() {
        hdr.int_q_occupancy_header.setValid();
        hdr.int_q_occupancy_header.q_occupancy1 = 7w0;
        hdr.int_q_occupancy_header.q_occupancy0 = (bit<24>)meta.eg_intr_md.enq_qdepth;
        hdr.int_hop_latency_header.setValid();
        hdr.int_hop_latency_header.hop_latency = (bit<31>)meta.eg_intr_md.deq_timedelta;
        hdr.int_port_ids_header.setValid();
        hdr.int_port_ids_header.ingress_port_id = meta.ingress_metadata.ingress_port;
        hdr.int_port_ids_header.egress_port_id = (bit<16>)meta.eg_intr_md.egress_port;
        hdr.int_switch_id_header.setValid();
        hdr.int_switch_id_header.switch_id = (bit<31>)meta.global_config_metadata.switch_id;
    }
    @name("process_int_egress.process_int_insertion.int_set_e_bit") action process_int_egress_process_int_insertion_int_set_e_bit() {
        hdr.int_header.e = 1w1;
    }
    @name("process_int_egress.process_int_insertion.int_update_total_hop_cnt") action process_int_egress_process_int_insertion_int_update_total_hop_cnt() {
        hdr.int_header.total_hop_cnt = hdr.int_header.total_hop_cnt + 8w1;
    }
    @name("process_int_egress.process_int_insertion.clear_upper") action process_int_egress_process_int_insertion_clear_upper() {
        meta.int_metadata.insert_byte_cnt = meta.int_metadata.insert_byte_cnt & 16w0x7f;
    }
    @name("process_int_egress.process_int_insertion.int_bos") table process_int_egress_process_int_insertion_int_bos_0() {
        actions = {
            process_int_egress_process_int_insertion_int_set_header_0_bos();
            process_int_egress_process_int_insertion_int_set_header_1_bos();
            process_int_egress_process_int_insertion_int_set_header_2_bos();
            process_int_egress_process_int_insertion_int_set_header_3_bos();
            process_int_egress_process_int_insertion_nop();
            @default_only NoAction_63();
        }
        key = {
            hdr.int_header.total_hop_cnt        : ternary;
            hdr.int_header.instruction_mask_0003: ternary;
            hdr.int_header.instruction_mask_0407: ternary;
            hdr.int_header.instruction_mask_0811: ternary;
            hdr.int_header.instruction_mask_1215: ternary;
        }
        size = 17;
        default_action = NoAction_63();
    }
    @name("process_int_egress.process_int_insertion.int_insert") table process_int_egress_process_int_insertion_int_insert_0() {
        actions = {
            process_int_egress_process_int_insertion_int_transit();
            process_int_egress_process_int_insertion_int_reset();
            process_int_egress_process_int_insertion_nop_5();
            @default_only NoAction_64();
        }
        key = {
            meta.int_metadata_i2e.source   : ternary;
            meta.int_metadata_i2e.sink     : ternary;
            hdr.int_header.isValid()       : exact;
            standard_metadata.instance_type: ternary;
        }
        size = 5;
        default_action = NoAction_64();
    }
    @ternary(1) @name("process_int_egress.process_int_insertion.int_inst_0003") table process_int_egress_process_int_insertion_int_inst_3() {
        actions = {
            process_int_egress_process_int_insertion_int_set_header_0003_i0();
            process_int_egress_process_int_insertion_int_set_header_0003_i1();
            process_int_egress_process_int_insertion_int_set_header_0003_i2();
            process_int_egress_process_int_insertion_int_set_header_0003_i3();
            process_int_egress_process_int_insertion_int_set_header_0003_i4();
            process_int_egress_process_int_insertion_int_set_header_0003_i5();
            process_int_egress_process_int_insertion_int_set_header_0003_i6();
            process_int_egress_process_int_insertion_int_set_header_0003_i7();
            process_int_egress_process_int_insertion_int_set_header_0003_i8();
            process_int_egress_process_int_insertion_int_set_header_0003_i9();
            process_int_egress_process_int_insertion_int_set_header_0003_i10();
            process_int_egress_process_int_insertion_int_set_header_0003_i11();
            process_int_egress_process_int_insertion_int_set_header_0003_i12();
            process_int_egress_process_int_insertion_int_set_header_0003_i13();
            process_int_egress_process_int_insertion_int_set_header_0003_i14();
            process_int_egress_process_int_insertion_int_set_header_0003_i15();
            @default_only NoAction_65();
        }
        key = {
            hdr.int_header.instruction_mask_0003: exact;
        }
        size = 17;
        default_action = NoAction_65();
    }
    @ternary(1) @name("process_int_egress.process_int_insertion.int_inst_0407") table process_int_egress_process_int_insertion_int_inst_4() {
        actions = {
            process_int_egress_process_int_insertion_nop_6();
            @default_only NoAction_66();
        }
        key = {
            hdr.int_header.instruction_mask_0407: exact;
        }
        size = 17;
        default_action = NoAction_66();
    }
    @name("process_int_egress.process_int_insertion.int_inst_0811") table process_int_egress_process_int_insertion_int_inst_5() {
        actions = {
            process_int_egress_process_int_insertion_nop_7();
            @default_only NoAction_67();
        }
        key = {
            hdr.int_header.instruction_mask_0811: exact;
        }
        size = 17;
        default_action = NoAction_67();
    }
    @name("process_int_egress.process_int_insertion.int_inst_1215") table process_int_egress_process_int_insertion_int_inst_6() {
        actions = {
            process_int_egress_process_int_insertion_nop_8();
            @default_only NoAction_68();
        }
        key = {
            hdr.int_header.instruction_mask_1215: exact;
        }
        size = 17;
        default_action = NoAction_68();
    }
    @name("process_int_egress.process_int_insertion.int_meta_header_update") table process_int_egress_process_int_insertion_int_meta_header_update_0() {
        actions = {
            process_int_egress_process_int_insertion_int_set_e_bit();
            process_int_egress_process_int_insertion_int_update_total_hop_cnt();
            @default_only NoAction_69();
        }
        key = {
            meta.int_metadata.insert_cnt: exact;
        }
        size = 2;
        default_action = NoAction_69();
    }
    @name("process_int_egress.process_int_insertion.int_transit_clear_byte_cnt") table process_int_egress_process_int_insertion_int_transit_clear_byte_cnt_0() {
        actions = {
            process_int_egress_process_int_insertion_clear_upper();
            @default_only NoAction_70();
        }
        size = 1;
        default_action = NoAction_70();
    }
    @name("process_int_egress.process_plt_insertion.update_int_plt_header") action process_int_egress_process_plt_insertion_update_int_plt_header() {
        hdr.int_plt_header.pl_encoding = hdr.int_plt_header.pl_encoding ^ meta.int_metadata.quantized_latency;
    }
    @name("process_int_egress.process_plt_insertion.int_plt_encode") table process_int_egress_process_plt_insertion_int_plt_encode_0() {
        actions = {
            process_int_egress_process_plt_insertion_update_int_plt_header();
            @default_only NoAction_71();
        }
        size = 1;
        default_action = NoAction_71();
    }
    @name("process_tunnel_encap.nop") action process_tunnel_encap_nop() {
    }
    @name("process_tunnel_encap.nop") action process_tunnel_encap_nop_2() {
    }
    @name("process_tunnel_encap.fabric_rewrite") action process_tunnel_encap_fabric_rewrite(bit<14> tunnel_index) {
        meta.tunnel_metadata.tunnel_index = tunnel_index;
    }
    @name("process_tunnel_encap.cpu_rx_rewrite") action process_tunnel_encap_cpu_rx_rewrite() {
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
    @name("process_tunnel_encap.fabric_unicast_rewrite") action process_tunnel_encap_fabric_unicast_rewrite() {
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
    @ternary(1) @name("process_tunnel_encap.tunnel_encap_process_outer") table process_tunnel_encap_tunnel_encap_process_outer_0() {
        actions = {
            process_tunnel_encap_nop();
            process_tunnel_encap_fabric_rewrite();
            @default_only NoAction_72();
        }
        key = {
            meta.tunnel_metadata.egress_tunnel_type : exact;
            meta.tunnel_metadata.egress_header_count: exact;
            meta.multicast_metadata.replica         : exact;
        }
        size = 256;
        default_action = NoAction_72();
    }
    @name("process_tunnel_encap.tunnel_rewrite") table process_tunnel_encap_tunnel_rewrite_0() {
        actions = {
            process_tunnel_encap_nop_2();
            process_tunnel_encap_cpu_rx_rewrite();
            process_tunnel_encap_fabric_unicast_rewrite();
            @default_only NoAction_73();
        }
        key = {
            meta.tunnel_metadata.tunnel_index: exact;
        }
        size = 16384;
        default_action = NoAction_73();
    }
    @name("process_egress_acl.nop") action process_egress_acl_nop() {
    }
    @name("process_egress_acl.nop") action process_egress_acl_nop_2() {
    }
    @name("process_egress_acl.egress_acl_deny") action process_egress_acl_egress_acl_deny(bit<16> acl_copy_reason) {
        meta.acl_metadata.acl_deny = 1w1;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name("process_egress_acl.egress_acl_deny") action process_egress_acl_egress_acl_deny_2(bit<16> acl_copy_reason) {
        meta.acl_metadata.acl_deny = 1w1;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name("process_egress_acl.egress_acl_permit") action process_egress_acl_egress_acl_permit(bit<16> acl_copy_reason) {
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name("process_egress_acl.egress_acl_permit") action process_egress_acl_egress_acl_permit_2(bit<16> acl_copy_reason) {
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name("process_egress_acl.egress_ip_acl") table process_egress_acl_egress_ip_acl_0() {
        actions = {
            process_egress_acl_nop();
            process_egress_acl_egress_acl_deny();
            process_egress_acl_egress_acl_permit();
            @default_only NoAction_74();
        }
        key = {
            meta.acl_metadata.egress_if_label         : ternary;
            meta.acl_metadata.egress_bd_label         : ternary;
            hdr.ipv4.srcAddr                          : ternary;
            hdr.ipv4.dstAddr                          : ternary;
            hdr.ipv4.protocol                         : ternary;
            meta.acl_metadata.egress_src_port_range_id: exact;
            meta.acl_metadata.egress_dst_port_range_id: exact;
        }
        size = 128;
        default_action = NoAction_74();
    }
    @name("process_egress_acl.egress_mac_acl") table process_egress_acl_egress_mac_acl_0() {
        actions = {
            process_egress_acl_nop_2();
            process_egress_acl_egress_acl_deny_2();
            process_egress_acl_egress_acl_permit_2();
            @default_only NoAction_75();
        }
        key = {
            meta.acl_metadata.egress_if_label: ternary;
            meta.acl_metadata.egress_bd_label: ternary;
            hdr.ethernet.srcAddr             : ternary;
            hdr.ethernet.dstAddr             : ternary;
            hdr.ethernet.etherType           : ternary;
        }
        size = 128;
        default_action = NoAction_75();
    }
    @name("process_int_outer_encap.int_update_vxlan_gpe_ipv4") action process_int_outer_encap_int_update_vxlan_gpe_ipv4() {
        hdr.ipv4.totalLen = hdr.ipv4.totalLen + meta.int_metadata.insert_byte_cnt;
        hdr.udp.length_ = hdr.udp.length_ + meta.int_metadata.insert_byte_cnt;
        hdr.vxlan_gpe_int_header.len = hdr.vxlan_gpe_int_header.len + meta.int_metadata.int_hdr_word_len;
    }
    @name("process_int_outer_encap.nop") action process_int_outer_encap_nop() {
    }
    @name("process_int_outer_encap.int_outer_encap") table process_int_outer_encap_int_outer_encap_0() {
        actions = {
            process_int_outer_encap_int_update_vxlan_gpe_ipv4();
            process_int_outer_encap_nop();
            @default_only NoAction_76();
        }
        key = {
            hdr.ipv4.isValid()                     : exact;
            hdr.vxlan_gpe.isValid()                : exact;
            hdr.erspan_t3_header.isValid()         : exact;
            meta.int_metadata_i2e.source           : exact;
            meta.int_metadata_i2e.sink             : exact;
            meta.tunnel_metadata.egress_tunnel_type: ternary;
        }
        size = 8;
        default_action = NoAction_76();
    }
    @name("process_vlan_xlate.set_egress_packet_vlan_untagged") action process_vlan_xlate_set_egress_packet_vlan_untagged() {
    }
    @name("process_vlan_xlate.set_egress_packet_vlan_tagged") action process_vlan_xlate_set_egress_packet_vlan_tagged(bit<12> vlan_id) {
        hdr.vlan_tag_[0].setValid();
        hdr.vlan_tag_[0].etherType = hdr.ethernet.etherType;
        hdr.vlan_tag_[0].vid = vlan_id;
        hdr.ethernet.etherType = 16w0x8100;
    }
    @name("process_vlan_xlate.set_egress_packet_vlan_double_tagged") action process_vlan_xlate_set_egress_packet_vlan_double_tagged(bit<12> s_tag, bit<12> c_tag) {
        hdr.vlan_tag_[1].setValid();
        hdr.vlan_tag_[0].setValid();
        hdr.vlan_tag_[1].etherType = hdr.ethernet.etherType;
        hdr.vlan_tag_[1].vid = c_tag;
        hdr.vlan_tag_[0].etherType = 16w0x8100;
        hdr.vlan_tag_[0].vid = s_tag;
        hdr.ethernet.etherType = 16w0x9100;
    }
    @name("process_vlan_xlate.egress_vlan_xlate") table process_vlan_xlate_egress_vlan_xlate_0() {
        actions = {
            process_vlan_xlate_set_egress_packet_vlan_untagged();
            process_vlan_xlate_set_egress_packet_vlan_tagged();
            process_vlan_xlate_set_egress_packet_vlan_double_tagged();
            @default_only NoAction_77();
        }
        key = {
            meta.egress_metadata.ifindex: exact;
            meta.egress_metadata.bd     : exact;
        }
        size = 32768;
        default_action = NoAction_77();
    }
    @name("process_egress_filter.egress_filter_check") action process_egress_filter_egress_filter_check() {
        meta.egress_filter_metadata.ifindex_check = meta.ingress_metadata.ifindex ^ meta.egress_metadata.ifindex;
        meta.egress_filter_metadata.bd = meta.ingress_metadata.outer_bd ^ meta.egress_metadata.outer_bd;
        meta.egress_filter_metadata.inner_bd = meta.ingress_metadata.bd ^ meta.egress_metadata.bd;
    }
    @name("process_egress_filter.set_egress_filter_drop") action process_egress_filter_set_egress_filter_drop() {
        mark_to_drop();
    }
    @name("process_egress_filter.egress_filter") table process_egress_filter_egress_filter_0() {
        actions = {
            process_egress_filter_egress_filter_check();
            @default_only NoAction_78();
        }
        default_action = NoAction_78();
    }
    @name("process_egress_filter.egress_filter_drop") table process_egress_filter_egress_filter_drop_0() {
        actions = {
            process_egress_filter_set_egress_filter_drop();
            @default_only NoAction_79();
        }
        default_action = NoAction_79();
    }
    @name("process_egress_system_acl.nop") action process_egress_system_acl_nop() {
    }
    @name("process_egress_system_acl.drop_packet") action process_egress_system_acl_drop_packet() {
        mark_to_drop();
    }
    @name("process_egress_system_acl.egress_copy_to_cpu") action process_egress_system_acl_egress_copy_to_cpu() {
        clone3<tuple_0>(CloneType.E2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
    }
    @name("process_egress_system_acl.egress_redirect_to_cpu") action process_egress_system_acl_egress_redirect_to_cpu() {
        clone3<tuple_0>(CloneType.E2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
        mark_to_drop();
    }
    @name("process_egress_system_acl.egress_copy_to_cpu_with_reason") action process_egress_system_acl_egress_copy_to_cpu_with_reason(bit<16> reason_code) {
        meta.fabric_metadata.reason_code = reason_code;
        clone3<tuple_0>(CloneType.E2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
    }
    @name("process_egress_system_acl.egress_redirect_to_cpu_with_reason") action process_egress_system_acl_egress_redirect_to_cpu_with_reason(bit<16> reason_code) {
        meta.fabric_metadata.reason_code = reason_code;
        clone3<tuple_0>(CloneType.E2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
        mark_to_drop();
    }
    @name("process_egress_system_acl.egress_mirror_coal_hdr") action process_egress_system_acl_egress_mirror_coal_hdr(bit<8> session_id, bit<8> id) {
    }
    @name("process_egress_system_acl.egress_system_acl") table process_egress_system_acl_egress_system_acl_0() {
        actions = {
            process_egress_system_acl_nop();
            process_egress_system_acl_drop_packet();
            process_egress_system_acl_egress_copy_to_cpu();
            process_egress_system_acl_egress_redirect_to_cpu();
            process_egress_system_acl_egress_copy_to_cpu_with_reason();
            process_egress_system_acl_egress_redirect_to_cpu_with_reason();
            process_egress_system_acl_egress_mirror_coal_hdr();
            @default_only NoAction_80();
        }
        key = {
            meta.fabric_metadata.reason_code: ternary;
            meta.eg_intr_md.egress_port     : ternary;
            meta.eg_intr_md.deflection_flag : ternary;
            meta.l3_metadata.l3_mtu_check   : ternary;
            meta.acl_metadata.acl_deny      : ternary;
        }
        size = 128;
        default_action = NoAction_80();
    }
    apply {
        if (meta.eg_intr_md.deflection_flag == 1w0 && meta.egress_metadata.bypass == 1w0) {
            process_int_egress_prep_plt_quantize_latency_0.apply();
            if (meta.int_metadata_i2e.sink == 1w0) 
                process_int_egress_prep_plt_scramble_latency_0.apply();
            switch (egress_port_mapping.apply().action_run) {
                egress_port_type_normal_0: {
                    if (standard_metadata.instance_type == 32w0 || standard_metadata.instance_type == 32w5) 
                        process_vlan_decap_vlan_decap_0.apply();
                    if (meta.egress_metadata.routed == 1w0 || meta.l3_metadata.nexthop_index != 16w0) 
                        process_rewrite_rewrite_0.apply();
                    else 
                        ;
                    process_egress_bd_egress_bd_map_0.apply();
                    process_egress_bd_stats_egress_bd_stats_0.apply();
                }
            }

            process_egress_l4port_egress_l4port_fields_0.apply();
            if (meta.int_metadata_i2e.sink == 1w1 && !(standard_metadata.instance_type != 32w0 && standard_metadata.instance_type != 32w5)) 
                ;
            else {
                process_int_egress_process_int_insertion_int_insert_0.apply();
                if (meta.int_metadata.hit_state != 2w0) {
                    if (meta.int_metadata.hit_state == 2w1) 
                        process_int_egress_process_int_insertion_int_transit_clear_byte_cnt_0.apply();
                    if (meta.int_metadata.insert_cnt != 8w0) {
                        process_int_egress_process_int_insertion_int_inst_3.apply();
                        process_int_egress_process_int_insertion_int_inst_4.apply();
                        process_int_egress_process_int_insertion_int_inst_5.apply();
                        process_int_egress_process_int_insertion_int_inst_6.apply();
                        process_int_egress_process_int_insertion_int_bos_0.apply();
                    }
                    process_int_egress_process_int_insertion_int_meta_header_update_0.apply();
                }
                if (meta.tunnel_metadata.egress_tunnel_type == 5w7 || meta.tunnel_metadata.egress_tunnel_type == 5w20) 
                    ;
                else 
                    if (meta.int_metadata_i2e.source == 1w0 && meta.int_metadata_i2e.sink == 1w0 && hdr.int_plt_header.isValid()) 
                        process_int_egress_process_plt_insertion_int_plt_encode_0.apply();
            }
            if (meta.fabric_metadata.fabric_header_present == 1w0 && meta.tunnel_metadata.egress_tunnel_type != 5w0) {
                process_tunnel_encap_tunnel_encap_process_outer_0.apply();
                process_tunnel_encap_tunnel_rewrite_0.apply();
            }
            if (hdr.ipv4.isValid()) 
                process_egress_acl_egress_ip_acl_0.apply();
            else 
                if (hdr.ipv6.isValid()) 
                    ;
                else 
                    process_egress_acl_egress_mac_acl_0.apply();
            if (meta.int_metadata.insert_cnt != 8w0 || meta.int_metadata_i2e.sink == 1w1 && standard_metadata.instance_type == 32w2) 
                process_int_outer_encap_int_outer_encap_0.apply();
            if (meta.egress_metadata.port_type == 2w0) 
                process_vlan_xlate_egress_vlan_xlate_0.apply();
            process_egress_filter_egress_filter_0.apply();
            if (meta.multicast_metadata.inner_replica == 1w1) 
                if (meta.tunnel_metadata.ingress_tunnel_type == 5w0 && meta.tunnel_metadata.egress_tunnel_type == 5w0 || meta.tunnel_metadata.ingress_tunnel_type != 5w0 && meta.tunnel_metadata.egress_tunnel_type != 5w0) 
                    process_egress_filter_egress_filter_drop_0.apply();
        }
        if (meta.egress_metadata.bypass == 1w0) 
            process_egress_system_acl_egress_system_acl_0.apply();
    }
}

@name("mac_learn_digest") struct mac_learn_digest {
    bit<14> bd;
    bit<48> lkp_mac_sa;
    bit<16> ifindex;
}

struct tuple_1 {
    bit<32> field_3;
    bit<32> field_4;
    bit<8>  field_5;
    bit<16> field_6;
    bit<16> field_7;
}

struct tuple_2 {
    bit<48> field_8;
    bit<48> field_9;
    bit<32> field_10;
    bit<32> field_11;
    bit<8>  field_12;
    bit<16> field_13;
    bit<16> field_14;
}

struct tuple_3 {
    bit<16> field_15;
    bit<48> field_16;
    bit<48> field_17;
    bit<16> field_18;
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("NoAction_28") action NoAction_81() {
    }
    @name("NoAction_29") action NoAction_82() {
    }
    @name("NoAction_30") action NoAction_83() {
    }
    @name("NoAction_31") action NoAction_84() {
    }
    @name("NoAction_32") action NoAction_85() {
    }
    @name("NoAction_33") action NoAction_86() {
    }
    @name("NoAction_34") action NoAction_87() {
    }
    @name("NoAction_35") action NoAction_88() {
    }
    @name("NoAction_36") action NoAction_89() {
    }
    @name("NoAction_37") action NoAction_90() {
    }
    @name("NoAction_38") action NoAction_91() {
    }
    @name("NoAction_39") action NoAction_92() {
    }
    @name("NoAction_40") action NoAction_93() {
    }
    @name("NoAction_41") action NoAction_94() {
    }
    @name("NoAction_42") action NoAction_95() {
    }
    @name("NoAction_43") action NoAction_96() {
    }
    @name("NoAction_44") action NoAction_97() {
    }
    @name("NoAction_45") action NoAction_98() {
    }
    @name("NoAction_46") action NoAction_99() {
    }
    @name("NoAction_47") action NoAction_100() {
    }
    @name("NoAction_48") action NoAction_101() {
    }
    @name("NoAction_49") action NoAction_102() {
    }
    @name("NoAction_50") action NoAction_103() {
    }
    @name("NoAction_51") action NoAction_104() {
    }
    @name("NoAction_52") action NoAction_105() {
    }
    @name("NoAction_53") action NoAction_106() {
    }
    @name("NoAction_54") action NoAction_107() {
    }
    @name("NoAction_55") action NoAction_108() {
    }
    @name("NoAction_56") action NoAction_109() {
    }
    @name("rmac_hit") action rmac_hit_0() {
        meta.l3_metadata.rmac_hit = 1w1;
    }
    @name("rmac_miss") action rmac_miss_0() {
        meta.l3_metadata.rmac_hit = 1w0;
    }
    @ternary(1) @name("rmac") table rmac() {
        actions = {
            rmac_hit_0();
            rmac_miss_0();
            @default_only NoAction_81();
        }
        key = {
            meta.l3_metadata.rmac_group: exact;
            meta.l2_metadata.lkp_mac_da: exact;
        }
        size = 512;
        default_action = NoAction_81();
    }
    @name("process_ingress_port_mapping.set_ifindex") action process_ingress_port_mapping_set_ifindex(bit<16> ifindex, bit<2> port_type) {
        meta.ingress_metadata.ifindex = ifindex;
        meta.ingress_metadata.port_type = port_type;
    }
    @name("process_ingress_port_mapping.set_ingress_port_properties") action process_ingress_port_mapping_set_ingress_port_properties(bit<16> if_label, bit<9> exclusion_id, bit<5> qos_group, bit<5> tc_qos_group, bit<8> tc, bit<2> color, bit<1> trust_dscp, bit<1> trust_pcp) {
        meta.ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
        meta.acl_metadata.if_label = if_label;
        meta.qos_metadata.ingress_qos_group = qos_group;
        meta.qos_metadata.tc_qos_group = tc_qos_group;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
        meta.qos_metadata.trust_dscp = trust_dscp;
        meta.qos_metadata.trust_pcp = trust_pcp;
    }
    @name("process_ingress_port_mapping.ingress_port_mapping") table process_ingress_port_mapping_ingress_port_mapping_0() {
        actions = {
            process_ingress_port_mapping_set_ifindex();
            @default_only NoAction_82();
        }
        key = {
            meta.ig_intr_md.ingress_port: exact;
        }
        size = 288;
        default_action = NoAction_82();
    }
    @name("process_ingress_port_mapping.ingress_port_properties") table process_ingress_port_mapping_ingress_port_properties_0() {
        actions = {
            process_ingress_port_mapping_set_ingress_port_properties();
            @default_only NoAction_83();
        }
        key = {
            meta.ig_intr_md.ingress_port: exact;
        }
        size = 288;
        default_action = NoAction_83();
    }
    @name("process_global_params.set_config_parameters") action process_global_params_set_config_parameters(bit<1> enable_dod, bit<8> enable_flowlet, bit<32> switch_id) {
        meta.ig_intr_md_for_tm.deflect_on_drop = enable_dod;
        meta.i2e_metadata.ingress_tstamp = (bit<32>)meta.ig_intr_md.ingress_global_tstamp;
        meta.ingress_metadata.ingress_port = meta.ig_intr_md.ingress_port;
        meta.l2_metadata.same_if_check = meta.ingress_metadata.ifindex;
        meta.ig_intr_md_for_tm.ucast_egress_port = 9w511;
        meta.global_config_metadata.switch_id = switch_id;
    }
    @name("process_global_params.switch_config_params") table process_global_params_switch_config_params_0() {
        actions = {
            process_global_params_set_config_parameters();
            @default_only NoAction_84();
        }
        size = 1;
        default_action = NoAction_84();
    }
    @name("process_validate_outer_header.malformed_outer_ethernet_packet") action process_validate_outer_header_malformed_outer_ethernet_packet(bit<8> drop_reason) {
        meta.ingress_metadata.drop_flag = 1w1;
        meta.ingress_metadata.drop_reason = drop_reason;
    }
    @name("process_validate_outer_header.set_valid_outer_unicast_packet_untagged") action process_validate_outer_header_set_valid_outer_unicast_packet_untagged() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name("process_validate_outer_header.set_valid_outer_unicast_packet_single_tagged") action process_validate_outer_header_set_valid_outer_unicast_packet_single_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[0].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name("process_validate_outer_header.set_valid_outer_unicast_packet_double_tagged") action process_validate_outer_header_set_valid_outer_unicast_packet_double_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[1].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name("process_validate_outer_header.set_valid_outer_unicast_packet_qinq_tagged") action process_validate_outer_header_set_valid_outer_unicast_packet_qinq_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name("process_validate_outer_header.set_valid_outer_multicast_packet_untagged") action process_validate_outer_header_set_valid_outer_multicast_packet_untagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name("process_validate_outer_header.set_valid_outer_multicast_packet_single_tagged") action process_validate_outer_header_set_valid_outer_multicast_packet_single_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[0].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name("process_validate_outer_header.set_valid_outer_multicast_packet_double_tagged") action process_validate_outer_header_set_valid_outer_multicast_packet_double_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[1].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name("process_validate_outer_header.set_valid_outer_multicast_packet_qinq_tagged") action process_validate_outer_header_set_valid_outer_multicast_packet_qinq_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name("process_validate_outer_header.set_valid_outer_broadcast_packet_untagged") action process_validate_outer_header_set_valid_outer_broadcast_packet_untagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name("process_validate_outer_header.set_valid_outer_broadcast_packet_single_tagged") action process_validate_outer_header_set_valid_outer_broadcast_packet_single_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[0].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name("process_validate_outer_header.set_valid_outer_broadcast_packet_double_tagged") action process_validate_outer_header_set_valid_outer_broadcast_packet_double_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[1].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name("process_validate_outer_header.set_valid_outer_broadcast_packet_qinq_tagged") action process_validate_outer_header_set_valid_outer_broadcast_packet_qinq_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name("process_validate_outer_header.validate_outer_ethernet") table process_validate_outer_header_validate_outer_ethernet_0() {
        actions = {
            process_validate_outer_header_malformed_outer_ethernet_packet();
            process_validate_outer_header_set_valid_outer_unicast_packet_untagged();
            process_validate_outer_header_set_valid_outer_unicast_packet_single_tagged();
            process_validate_outer_header_set_valid_outer_unicast_packet_double_tagged();
            process_validate_outer_header_set_valid_outer_unicast_packet_qinq_tagged();
            process_validate_outer_header_set_valid_outer_multicast_packet_untagged();
            process_validate_outer_header_set_valid_outer_multicast_packet_single_tagged();
            process_validate_outer_header_set_valid_outer_multicast_packet_double_tagged();
            process_validate_outer_header_set_valid_outer_multicast_packet_qinq_tagged();
            process_validate_outer_header_set_valid_outer_broadcast_packet_untagged();
            process_validate_outer_header_set_valid_outer_broadcast_packet_single_tagged();
            process_validate_outer_header_set_valid_outer_broadcast_packet_double_tagged();
            process_validate_outer_header_set_valid_outer_broadcast_packet_qinq_tagged();
            @default_only NoAction_85();
        }
        key = {
            hdr.ethernet.srcAddr      : ternary;
            hdr.ethernet.dstAddr      : ternary;
            hdr.vlan_tag_[0].isValid(): exact;
            hdr.vlan_tag_[1].isValid(): exact;
        }
        size = 64;
        default_action = NoAction_85();
    }
    @name("process_port_vlan_mapping.non_ip_lkp") action process_port_vlan_mapping_non_ip_lkp() {
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.ig_intr_md_for_tm.mcast_grp_a = 16w0;
        meta.l2_metadata.non_ip_packet = 1w1;
    }
    @name("process_port_vlan_mapping.ipv4_lkp") action process_port_vlan_mapping_ipv4_lkp() {
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
    @name("process_port_vlan_mapping.set_bd_properties") action process_port_vlan_mapping_set_bd_properties(bit<14> bd, bit<14> vrf, bit<10> stp_group, bit<1> learning_enabled, bit<16> bd_label, bit<16> stats_idx, bit<10> rmac_group, bit<1> ipv4_unicast_enabled, bit<1> ipv6_unicast_enabled, bit<2> ipv4_urpf_mode, bit<2> ipv6_urpf_mode, bit<1> igmp_snooping_enabled, bit<1> mld_snooping_enabled, bit<1> ipv4_multicast_enabled, bit<1> ipv6_multicast_enabled, bit<14> mrpf_group, bit<14> ipv4_mcast_key, bit<1> ipv4_mcast_key_type, bit<14> ipv6_mcast_key, bit<1> ipv6_mcast_key_type, bit<16> ingress_rid) {
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
    @name("process_port_vlan_mapping.port_vlan_mapping_miss") action process_port_vlan_mapping_port_vlan_mapping_miss() {
        meta.l2_metadata.port_vlan_mapping_miss = 1w1;
    }
    @name("process_port_vlan_mapping.adjust_lkp_fields") table process_port_vlan_mapping_adjust_lkp_fields_0() {
        actions = {
            process_port_vlan_mapping_non_ip_lkp();
            process_port_vlan_mapping_ipv4_lkp();
            @default_only NoAction_86();
        }
        key = {
            hdr.ipv4.isValid(): exact;
            hdr.ipv6.isValid(): exact;
        }
        default_action = NoAction_86();
    }
    @name("process_port_vlan_mapping.port_vlan_mapping") table process_port_vlan_mapping_port_vlan_mapping_0() {
        actions = {
            process_port_vlan_mapping_set_bd_properties();
            process_port_vlan_mapping_port_vlan_mapping_miss();
            @default_only NoAction_87();
        }
        key = {
            meta.ingress_metadata.ifindex: exact;
            hdr.vlan_tag_[0].isValid()   : exact;
            hdr.vlan_tag_[0].vid         : exact;
            hdr.vlan_tag_[1].isValid()   : exact;
            hdr.vlan_tag_[1].vid         : exact;
        }
        size = 32768;
        default_action = NoAction_87();
        @name("bd_action_profile") implementation = action_profile(32w16384);
    }
    @name("process_spanning_tree.set_stp_state") action process_spanning_tree_set_stp_state(bit<3> stp_state) {
        meta.l2_metadata.stp_state = stp_state;
    }
    @ternary(1) @name("process_spanning_tree.spanning_tree") table process_spanning_tree_spanning_tree_0() {
        actions = {
            process_spanning_tree_set_stp_state();
            @default_only NoAction_88();
        }
        key = {
            meta.ingress_metadata.ifindex: exact;
            meta.l2_metadata.stp_group   : exact;
        }
        size = 4096;
        default_action = NoAction_88();
    }
    @name("process_tunnel.process_ingress_fabric.nop") action process_tunnel_process_ingress_fabric_nop() {
    }
    @name("process_tunnel.process_ingress_fabric.nop") action process_tunnel_process_ingress_fabric_nop_2() {
    }
    @name("process_tunnel.process_ingress_fabric.terminate_cpu_packet") action process_tunnel_process_ingress_fabric_terminate_cpu_packet() {
        meta.ig_intr_md_for_tm.ucast_egress_port = (bit<9>)hdr.fabric_header.dstPortOrGroup;
        meta.egress_metadata.bypass = hdr.fabric_header_cpu.txBypass;
        hdr.ethernet.etherType = hdr.fabric_payload_header.etherType;
        hdr.fabric_header.setInvalid();
        hdr.fabric_header_cpu.setInvalid();
        hdr.fabric_payload_header.setInvalid();
    }
    @name("process_tunnel.process_ingress_fabric.switch_fabric_unicast_packet") action process_tunnel_process_ingress_fabric_switch_fabric_unicast_packet() {
        meta.fabric_metadata.fabric_header_present = 1w1;
        meta.fabric_metadata.dst_device = hdr.fabric_header.dstDevice;
        meta.fabric_metadata.dst_port = hdr.fabric_header.dstPortOrGroup;
    }
    @name("process_tunnel.process_ingress_fabric.terminate_fabric_unicast_packet") action process_tunnel_process_ingress_fabric_terminate_fabric_unicast_packet() {
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
    @name("process_tunnel.process_ingress_fabric.set_ingress_ifindex_properties") action process_tunnel_process_ingress_fabric_set_ingress_ifindex_properties(bit<9> l2xid) {
        meta.ig_intr_md_for_tm.level2_exclusion_id = l2xid;
    }
    @name("process_tunnel.process_ingress_fabric.non_ip_over_fabric") action process_tunnel_process_ingress_fabric_non_ip_over_fabric() {
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name("process_tunnel.process_ingress_fabric.ipv4_over_fabric") action process_tunnel_process_ingress_fabric_ipv4_over_fabric() {
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.ipv4_metadata.lkp_ipv4_sa = hdr.ipv4.srcAddr;
        meta.ipv4_metadata.lkp_ipv4_da = hdr.ipv4.dstAddr;
        meta.l3_metadata.lkp_ip_proto = hdr.ipv4.protocol;
        meta.l3_metadata.lkp_l4_sport = meta.l3_metadata.lkp_outer_l4_sport;
        meta.l3_metadata.lkp_l4_dport = meta.l3_metadata.lkp_outer_l4_dport;
    }
    @ternary(1) @name("process_tunnel.process_ingress_fabric.fabric_ingress_dst_lkp") table process_tunnel_process_ingress_fabric_fabric_ingress_dst_lkp_0() {
        actions = {
            process_tunnel_process_ingress_fabric_nop();
            process_tunnel_process_ingress_fabric_terminate_cpu_packet();
            process_tunnel_process_ingress_fabric_switch_fabric_unicast_packet();
            process_tunnel_process_ingress_fabric_terminate_fabric_unicast_packet();
            @default_only NoAction_89();
        }
        key = {
            hdr.fabric_header.dstDevice: exact;
        }
        default_action = NoAction_89();
    }
    @name("process_tunnel.process_ingress_fabric.fabric_ingress_src_lkp") table process_tunnel_process_ingress_fabric_fabric_ingress_src_lkp_0() {
        actions = {
            process_tunnel_process_ingress_fabric_nop_2();
            process_tunnel_process_ingress_fabric_set_ingress_ifindex_properties();
            @default_only NoAction_90();
        }
        key = {
            hdr.fabric_header_multicast.ingressIfindex: exact;
        }
        size = 1024;
        default_action = NoAction_90();
    }
    @name("process_tunnel.process_ingress_fabric.native_packet_over_fabric") table process_tunnel_process_ingress_fabric_native_packet_over_fabric_0() {
        actions = {
            process_tunnel_process_ingress_fabric_non_ip_over_fabric();
            process_tunnel_process_ingress_fabric_ipv4_over_fabric();
            @default_only NoAction_91();
        }
        key = {
            hdr.ipv4.isValid(): exact;
            hdr.ipv6.isValid(): exact;
        }
        size = 1024;
        default_action = NoAction_91();
    }
    @name("process_validate_packet.nop") action process_validate_packet_nop() {
    }
    @name("process_validate_packet.set_unicast") action process_validate_packet_set_unicast() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
    }
    @name("process_validate_packet.set_unicast_and_ipv6_src_is_link_local") action process_validate_packet_set_unicast_and_ipv6_src_is_link_local() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.ipv6_metadata.ipv6_src_is_link_local = 1w1;
    }
    @name("process_validate_packet.set_multicast") action process_validate_packet_set_multicast() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.bd_stats_idx = meta.l2_metadata.bd_stats_idx + 16w1;
    }
    @name("process_validate_packet.set_multicast_and_ipv6_src_is_link_local") action process_validate_packet_set_multicast_and_ipv6_src_is_link_local() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.ipv6_metadata.ipv6_src_is_link_local = 1w1;
        meta.l2_metadata.bd_stats_idx = meta.l2_metadata.bd_stats_idx + 16w1;
    }
    @name("process_validate_packet.set_broadcast") action process_validate_packet_set_broadcast() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.bd_stats_idx = meta.l2_metadata.bd_stats_idx + 16w2;
    }
    @name("process_validate_packet.set_malformed_packet") action process_validate_packet_set_malformed_packet(bit<8> drop_reason) {
        meta.ingress_metadata.drop_flag = 1w1;
        meta.ingress_metadata.drop_reason = drop_reason;
    }
    @name("process_validate_packet.validate_packet") table process_validate_packet_validate_packet_0() {
        actions = {
            process_validate_packet_nop();
            process_validate_packet_set_unicast();
            process_validate_packet_set_unicast_and_ipv6_src_is_link_local();
            process_validate_packet_set_multicast();
            process_validate_packet_set_multicast_and_ipv6_src_is_link_local();
            process_validate_packet_set_broadcast();
            process_validate_packet_set_malformed_packet();
            @default_only NoAction_92();
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
        default_action = NoAction_92();
    }
    @name("process_mac.nop") action process_mac_nop() {
    }
    @name("process_mac.nop") action process_mac_nop_2() {
    }
    @name("process_mac.dmac_hit") action process_mac_dmac_hit(bit<16> ifindex) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.l2_metadata.same_if_check = meta.l2_metadata.same_if_check ^ ifindex;
    }
    @name("process_mac.dmac_multicast_hit") action process_mac_dmac_multicast_hit(bit<16> mc_index) {
        meta.ig_intr_md_for_tm.mcast_grp_b = mc_index;
        meta.fabric_metadata.dst_device = 8w127;
    }
    @name("process_mac.dmac_miss") action process_mac_dmac_miss() {
        meta.ingress_metadata.egress_ifindex = 16w65535;
        meta.fabric_metadata.dst_device = 8w127;
    }
    @name("process_mac.dmac_redirect_nexthop") action process_mac_dmac_redirect_nexthop(bit<16> nexthop_index) {
        meta.l2_metadata.l2_redirect = 1w1;
        meta.l2_metadata.l2_nexthop = nexthop_index;
        meta.l2_metadata.l2_nexthop_type = 2w0;
    }
    @name("process_mac.dmac_redirect_ecmp") action process_mac_dmac_redirect_ecmp(bit<16> ecmp_index) {
        meta.l2_metadata.l2_redirect = 1w1;
        meta.l2_metadata.l2_nexthop = ecmp_index;
        meta.l2_metadata.l2_nexthop_type = 2w1;
    }
    @name("process_mac.dmac_drop") action process_mac_dmac_drop() {
        mark_to_drop();
    }
    @name("process_mac.smac_miss") action process_mac_smac_miss() {
        meta.l2_metadata.l2_src_miss = 1w1;
    }
    @name("process_mac.smac_hit") action process_mac_smac_hit(bit<16> ifindex) {
        meta.l2_metadata.l2_src_move = meta.ingress_metadata.ifindex ^ ifindex;
    }
    @idletime_precision(2) @name("process_mac.dmac") table process_mac_dmac_0() {
        support_timeout = true;
        actions = {
            process_mac_nop();
            process_mac_dmac_hit();
            process_mac_dmac_multicast_hit();
            process_mac_dmac_miss();
            process_mac_dmac_redirect_nexthop();
            process_mac_dmac_redirect_ecmp();
            process_mac_dmac_drop();
            @default_only NoAction_93();
        }
        key = {
            meta.ingress_metadata.bd   : exact;
            meta.l2_metadata.lkp_mac_da: exact;
        }
        size = 512000;
        default_action = NoAction_93();
    }
    @name("process_mac.smac") table process_mac_smac_0() {
        actions = {
            process_mac_nop_2();
            process_mac_smac_miss();
            process_mac_smac_hit();
            @default_only NoAction_94();
        }
        key = {
            meta.ingress_metadata.bd   : exact;
            meta.l2_metadata.lkp_mac_sa: exact;
        }
        size = 512000;
        default_action = NoAction_94();
    }
    @name("process_mac_acl.nop") action process_mac_acl_nop() {
    }
    @name("process_mac_acl.acl_deny") action process_mac_acl_acl_deny(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name("process_mac_acl.acl_permit") action process_mac_acl_acl_permit(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name("process_mac_acl.acl_redirect_nexthop") action process_mac_acl_acl_redirect_nexthop(bit<16> nexthop_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = nexthop_index;
        meta.acl_metadata.acl_nexthop_type = 2w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name("process_mac_acl.acl_redirect_ecmp") action process_mac_acl_acl_redirect_ecmp(bit<16> ecmp_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = ecmp_index;
        meta.acl_metadata.acl_nexthop_type = 2w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name("process_mac_acl.mac_acl") table process_mac_acl_mac_acl_0() {
        actions = {
            process_mac_acl_nop();
            process_mac_acl_acl_deny();
            process_mac_acl_acl_permit();
            process_mac_acl_acl_redirect_nexthop();
            process_mac_acl_acl_redirect_ecmp();
            @default_only NoAction_95();
        }
        key = {
            meta.acl_metadata.if_label   : ternary;
            meta.acl_metadata.bd_label   : ternary;
            meta.l2_metadata.lkp_mac_sa  : ternary;
            meta.l2_metadata.lkp_mac_da  : ternary;
            meta.l2_metadata.lkp_mac_type: ternary;
        }
        size = 128;
        default_action = NoAction_95();
    }
    @name("process_ip_acl.nop") action process_ip_acl_nop() {
    }
    @name("process_ip_acl.acl_deny") action process_ip_acl_acl_deny(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name("process_ip_acl.acl_permit") action process_ip_acl_acl_permit(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name("process_ip_acl.acl_redirect_nexthop") action process_ip_acl_acl_redirect_nexthop(bit<16> nexthop_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = nexthop_index;
        meta.acl_metadata.acl_nexthop_type = 2w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name("process_ip_acl.acl_redirect_ecmp") action process_ip_acl_acl_redirect_ecmp(bit<16> ecmp_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = ecmp_index;
        meta.acl_metadata.acl_nexthop_type = 2w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name("process_ip_acl.ip_acl") table process_ip_acl_ip_acl_0() {
        actions = {
            process_ip_acl_nop();
            process_ip_acl_acl_deny();
            process_ip_acl_acl_permit();
            process_ip_acl_acl_redirect_nexthop();
            process_ip_acl_acl_redirect_ecmp();
            @default_only NoAction_96();
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
        default_action = NoAction_96();
    }
    @name("process_hashes.compute_lkp_ipv4_hash") action process_hashes_compute_lkp_ipv4_hash() {
        hash<bit<16>, bit<16>, tuple_1, bit<32>>(meta.hash_metadata.hash1, HashAlgorithm.crc16, 16w0, { meta.ipv4_metadata.lkp_ipv4_sa, meta.ipv4_metadata.lkp_ipv4_da, meta.l3_metadata.lkp_ip_proto, meta.l3_metadata.lkp_l4_sport, meta.l3_metadata.lkp_l4_dport }, 32w65536);
        hash<bit<16>, bit<16>, tuple_2, bit<32>>(meta.hash_metadata.hash2, HashAlgorithm.crc16, 16w0, { meta.l2_metadata.lkp_mac_sa, meta.l2_metadata.lkp_mac_da, meta.ipv4_metadata.lkp_ipv4_sa, meta.ipv4_metadata.lkp_ipv4_da, meta.l3_metadata.lkp_ip_proto, meta.l3_metadata.lkp_l4_sport, meta.l3_metadata.lkp_l4_dport }, 32w65536);
    }
    @name("process_hashes.compute_lkp_non_ip_hash") action process_hashes_compute_lkp_non_ip_hash() {
        hash<bit<16>, bit<16>, tuple_3, bit<32>>(meta.hash_metadata.hash2, HashAlgorithm.crc16, 16w0, { meta.ingress_metadata.ifindex, meta.l2_metadata.lkp_mac_sa, meta.l2_metadata.lkp_mac_da, meta.l2_metadata.lkp_mac_type }, 32w65536);
    }
    @name("process_hashes.computed_two_hashes") action process_hashes_computed_two_hashes() {
        meta.ig_intr_md_for_tm.level1_mcast_hash = (bit<13>)meta.hash_metadata.hash1;
        meta.ig_intr_md_for_tm.level2_mcast_hash = (bit<13>)meta.hash_metadata.hash2;
        meta.hash_metadata.entropy_hash = meta.hash_metadata.hash2;
    }
    @name("process_hashes.computed_one_hash") action process_hashes_computed_one_hash() {
        meta.hash_metadata.hash1 = meta.hash_metadata.hash2;
        meta.ig_intr_md_for_tm.level1_mcast_hash = (bit<13>)meta.hash_metadata.hash2;
        meta.ig_intr_md_for_tm.level2_mcast_hash = (bit<13>)meta.hash_metadata.hash2;
        meta.hash_metadata.entropy_hash = meta.hash_metadata.hash2;
    }
    @name("process_hashes.compute_ipv4_hashes") table process_hashes_compute_ipv4_hashes_0() {
        actions = {
            process_hashes_compute_lkp_ipv4_hash();
            @default_only NoAction_97();
        }
        default_action = NoAction_97();
    }
    @name("process_hashes.compute_non_ip_hashes") table process_hashes_compute_non_ip_hashes_0() {
        actions = {
            process_hashes_compute_lkp_non_ip_hash();
            @default_only NoAction_98();
        }
        default_action = NoAction_98();
    }
    @ternary(1) @name("process_hashes.compute_other_hashes") table process_hashes_compute_other_hashes_0() {
        actions = {
            process_hashes_computed_two_hashes();
            process_hashes_computed_one_hash();
            @default_only NoAction_99();
        }
        key = {
            meta.hash_metadata.hash1: exact;
        }
        default_action = NoAction_99();
    }
    @name("process_ingress_bd_stats.ingress_bd_stats") counter(32w16384, CounterType.packets_and_bytes) process_ingress_bd_stats_ingress_bd_stats_1;
    @name("process_ingress_bd_stats.update_ingress_bd_stats") action process_ingress_bd_stats_update_ingress_bd_stats() {
        process_ingress_bd_stats_ingress_bd_stats_1.count((bit<32>)meta.l2_metadata.bd_stats_idx);
    }
    @name("process_ingress_bd_stats.ingress_bd_stats") table process_ingress_bd_stats_ingress_bd_stats_2() {
        actions = {
            process_ingress_bd_stats_update_ingress_bd_stats();
            @default_only NoAction_100();
        }
        size = 16384;
        default_action = NoAction_100();
    }
    @name("process_ingress_acl_stats.acl_stats") counter(32w128, CounterType.packets_and_bytes) process_ingress_acl_stats_acl_stats_1;
    @name("process_ingress_acl_stats.acl_stats_update") action process_ingress_acl_stats_acl_stats_update() {
        process_ingress_acl_stats_acl_stats_1.count((bit<32>)meta.acl_metadata.acl_stats_index);
    }
    @name("process_ingress_acl_stats.acl_stats") table process_ingress_acl_stats_acl_stats_2() {
        actions = {
            process_ingress_acl_stats_acl_stats_update();
            @default_only NoAction_101();
        }
        size = 128;
        default_action = NoAction_101();
    }
    @name("process_fwd_results.nop") action process_fwd_results_nop() {
    }
    @name("process_fwd_results.set_l2_redirect_action") action process_fwd_results_set_l2_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.l2_metadata.l2_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.l2_metadata.l2_nexthop_type;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name("process_fwd_results.set_fib_redirect_action") action process_fwd_results_set_fib_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.l3_metadata.fib_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.l3_metadata.fib_nexthop_type;
        meta.l3_metadata.routed = 1w1;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
        meta.fabric_metadata.reason_code = 16w0x217;
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name("process_fwd_results.set_cpu_redirect_action") action process_fwd_results_set_cpu_redirect_action() {
        meta.l3_metadata.routed = 1w0;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
        meta.ig_intr_md_for_tm.ucast_egress_port = 9w64;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name("process_fwd_results.set_acl_redirect_action") action process_fwd_results_set_acl_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.acl_metadata.acl_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.acl_metadata.acl_nexthop_type;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name("process_fwd_results.set_racl_redirect_action") action process_fwd_results_set_racl_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.acl_metadata.racl_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.acl_metadata.racl_nexthop_type;
        meta.l3_metadata.routed = 1w1;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name("process_fwd_results.fwd_result") table process_fwd_results_fwd_result_0() {
        actions = {
            process_fwd_results_nop();
            process_fwd_results_set_l2_redirect_action();
            process_fwd_results_set_fib_redirect_action();
            process_fwd_results_set_cpu_redirect_action();
            process_fwd_results_set_acl_redirect_action();
            process_fwd_results_set_racl_redirect_action();
            @default_only NoAction_102();
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
        default_action = NoAction_102();
    }
    @name("process_nexthop.nop") action process_nexthop_nop() {
    }
    @name("process_nexthop.nop") action process_nexthop_nop_2() {
    }
    @name("process_nexthop.set_ecmp_nexthop_details") action process_nexthop_set_ecmp_nexthop_details(bit<16> ifindex, bit<14> bd, bit<16> nhop_index, bit<1> tunnel) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.l3_metadata.nexthop_index = nhop_index;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.l2_metadata.same_if_check = meta.l2_metadata.same_if_check ^ ifindex;
        meta.tunnel_metadata.tunnel_if_check = meta.tunnel_metadata.tunnel_terminate ^ tunnel;
        meta.ig_intr_md_for_tm.disable_ucast_cutthru = meta.l2_metadata.non_ip_packet & tunnel;
    }
    @name("process_nexthop.set_ecmp_nexthop_details_for_post_routed_flood") action process_nexthop_set_ecmp_nexthop_details_for_post_routed_flood(bit<14> bd, bit<16> uuc_mc_index, bit<16> nhop_index) {
        meta.ig_intr_md_for_tm.mcast_grp_b = uuc_mc_index;
        meta.l3_metadata.nexthop_index = nhop_index;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.fabric_metadata.dst_device = 8w127;
    }
    @name("process_nexthop.set_nexthop_details") action process_nexthop_set_nexthop_details(bit<16> ifindex, bit<14> bd, bit<1> tunnel) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.l2_metadata.same_if_check = meta.l2_metadata.same_if_check ^ ifindex;
        meta.tunnel_metadata.tunnel_if_check = meta.tunnel_metadata.tunnel_terminate ^ tunnel;
        meta.ig_intr_md_for_tm.disable_ucast_cutthru = meta.l2_metadata.non_ip_packet & tunnel;
    }
    @name("process_nexthop.set_nexthop_details_for_post_routed_flood") action process_nexthop_set_nexthop_details_for_post_routed_flood(bit<14> bd, bit<16> uuc_mc_index) {
        meta.ig_intr_md_for_tm.mcast_grp_b = uuc_mc_index;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.fabric_metadata.dst_device = 8w127;
    }
    @name("process_nexthop.ecmp_group") table process_nexthop_ecmp_group_0() {
        actions = {
            process_nexthop_nop();
            process_nexthop_set_ecmp_nexthop_details();
            process_nexthop_set_ecmp_nexthop_details_for_post_routed_flood();
            @default_only NoAction_103();
        }
        key = {
            meta.l3_metadata.nexthop_index: exact;
            meta.hash_metadata.hash1      : selector;
        }
        size = 1024;
        default_action = NoAction_103();
        @name("ecmp_action_profile") implementation = action_selector(HashAlgorithm.identity, 32w16384, 32w14);
    }
    @name("process_nexthop.nexthop") table process_nexthop_nexthop_0() {
        actions = {
            process_nexthop_nop_2();
            process_nexthop_set_nexthop_details();
            process_nexthop_set_nexthop_details_for_post_routed_flood();
            @default_only NoAction_104();
        }
        key = {
            meta.l3_metadata.nexthop_index: exact;
        }
        size = 16384;
        default_action = NoAction_104();
    }
    @name("process_lag.set_lag_miss") action process_lag_set_lag_miss() {
    }
    @name("process_lag.set_lag_port") action process_lag_set_lag_port(bit<9> port) {
        meta.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name("process_lag.set_lag_remote_port") action process_lag_set_lag_remote_port(bit<8> device, bit<16> port) {
        meta.fabric_metadata.dst_device = device;
        meta.fabric_metadata.dst_port = port;
    }
    @name("process_lag.lag_group") table process_lag_lag_group_0() {
        actions = {
            process_lag_set_lag_miss();
            process_lag_set_lag_port();
            process_lag_set_lag_remote_port();
            @default_only NoAction_105();
        }
        key = {
            meta.ingress_metadata.egress_ifindex: exact;
            meta.hash_metadata.hash2            : selector;
        }
        size = 1024;
        default_action = NoAction_105();
        @name("lag_action_profile") implementation = action_selector(HashAlgorithm.identity, 32w1024, 32w14);
    }
    @name("process_mac_learning.nop") action process_mac_learning_nop() {
    }
    @name("process_mac_learning.generate_learn_notify") action process_mac_learning_generate_learn_notify() {
        digest<mac_learn_digest>(32w1024, { meta.ingress_metadata.bd, meta.l2_metadata.lkp_mac_sa, meta.ingress_metadata.ifindex });
    }
    @name("process_mac_learning.learn_notify") table process_mac_learning_learn_notify_0() {
        actions = {
            process_mac_learning_nop();
            process_mac_learning_generate_learn_notify();
            @default_only NoAction_106();
        }
        key = {
            meta.l2_metadata.l2_src_miss: ternary;
            meta.l2_metadata.l2_src_move: ternary;
            meta.l2_metadata.stp_state  : ternary;
        }
        size = 512;
        default_action = NoAction_106();
    }
    @name("process_fabric_lag.nop") action process_fabric_lag_nop() {
    }
    @name("process_fabric_lag.set_fabric_lag_port") action process_fabric_lag_set_fabric_lag_port(bit<9> port) {
        meta.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name("process_fabric_lag.fabric_lag") table process_fabric_lag_fabric_lag_0() {
        actions = {
            process_fabric_lag_nop();
            process_fabric_lag_set_fabric_lag_port();
            @default_only NoAction_107();
        }
        key = {
            meta.fabric_metadata.dst_device: exact;
            meta.hash_metadata.hash2       : selector;
        }
        default_action = NoAction_107();
        @name("fabric_lag_action_profile") implementation = action_selector(HashAlgorithm.identity, 32w1024, 32w14);
    }
    @name("process_system_acl.drop_stats") counter(32w256, CounterType.packets) process_system_acl_drop_stats_2;
    @name("process_system_acl.drop_stats_2") counter(32w256, CounterType.packets) process_system_acl_drop_stats_3;
    @name("process_system_acl.drop_stats_update") action process_system_acl_drop_stats_update() {
        process_system_acl_drop_stats_3.count((bit<32>)meta.ingress_metadata.drop_reason);
    }
    @name("process_system_acl.nop") action process_system_acl_nop() {
    }
    @name("process_system_acl.copy_to_cpu") action process_system_acl_copy_to_cpu(bit<5> qid, bit<8> meter_id, bit<3> icos) {
        meta.ig_intr_md_for_tm.qid = qid;
        meta.ig_intr_md_for_tm.ingress_cos = icos;
        clone3<tuple_0>(CloneType.I2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
    }
    @name("process_system_acl.redirect_to_cpu") action process_system_acl_redirect_to_cpu(bit<5> qid, bit<8> meter_id, bit<3> icos) {
        meta.ig_intr_md_for_tm.qid = qid;
        meta.ig_intr_md_for_tm.ingress_cos = icos;
        clone3<tuple_0>(CloneType.I2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
        mark_to_drop();
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name("process_system_acl.copy_to_cpu_with_reason") action process_system_acl_copy_to_cpu_with_reason(bit<16> reason_code, bit<5> qid, bit<8> meter_id, bit<3> icos) {
        meta.fabric_metadata.reason_code = reason_code;
        meta.ig_intr_md_for_tm.qid = qid;
        meta.ig_intr_md_for_tm.ingress_cos = icos;
        clone3<tuple_0>(CloneType.I2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
    }
    @name("process_system_acl.redirect_to_cpu_with_reason") action process_system_acl_redirect_to_cpu_with_reason(bit<16> reason_code, bit<5> qid, bit<8> meter_id, bit<3> icos) {
        meta.fabric_metadata.reason_code = reason_code;
        meta.ig_intr_md_for_tm.qid = qid;
        meta.ig_intr_md_for_tm.ingress_cos = icos;
        clone3<tuple_0>(CloneType.I2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
        mark_to_drop();
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name("process_system_acl.drop_packet") action process_system_acl_drop_packet() {
        mark_to_drop();
    }
    @name("process_system_acl.drop_packet_with_reason") action process_system_acl_drop_packet_with_reason(bit<8> drop_reason) {
        process_system_acl_drop_stats_2.count((bit<32>)drop_reason);
        mark_to_drop();
    }
    @name("process_system_acl.drop_stats") table process_system_acl_drop_stats_4() {
        actions = {
            process_system_acl_drop_stats_update();
            @default_only NoAction_108();
        }
        size = 256;
        default_action = NoAction_108();
    }
    @name("process_system_acl.system_acl") table process_system_acl_system_acl_0() {
        actions = {
            process_system_acl_nop();
            process_system_acl_redirect_to_cpu();
            process_system_acl_redirect_to_cpu_with_reason();
            process_system_acl_copy_to_cpu();
            process_system_acl_copy_to_cpu_with_reason();
            process_system_acl_drop_packet();
            process_system_acl_drop_packet_with_reason();
            @default_only NoAction_109();
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
        default_action = NoAction_109();
    }
    apply {
        if (meta.ig_intr_md.resubmit_flag == 1w0) 
            process_ingress_port_mapping_ingress_port_mapping_0.apply();
        process_ingress_port_mapping_ingress_port_properties_0.apply();
        process_global_params_switch_config_params_0.apply();
        switch (process_validate_outer_header_validate_outer_ethernet_0.apply().action_run) {
            default: {
            }
            process_validate_outer_header_malformed_outer_ethernet_packet: {
            }
        }

        process_port_vlan_mapping_port_vlan_mapping_0.apply();
        process_port_vlan_mapping_adjust_lkp_fields_0.apply();
        if (meta.ingress_metadata.port_type == 2w0 && meta.l2_metadata.stp_group != 10w0) 
            process_spanning_tree_spanning_tree_0.apply();
        if (meta.ingress_metadata.port_type != 2w0) {
            process_tunnel_process_ingress_fabric_fabric_ingress_dst_lkp_0.apply();
            if (meta.ingress_metadata.port_type == 2w1) {
                if (hdr.fabric_header_multicast.isValid()) 
                    process_tunnel_process_ingress_fabric_fabric_ingress_src_lkp_0.apply();
                if (meta.tunnel_metadata.tunnel_terminate == 1w0) 
                    process_tunnel_process_ingress_fabric_native_packet_over_fabric_0.apply();
            }
        }
        if (meta.ingress_metadata.port_type != 2w1) {
            if ((meta.ingress_metadata.bypass_lookups & 16w0x40) == 16w0 && meta.ingress_metadata.drop_flag == 1w0) 
                process_validate_packet_validate_packet_0.apply();
            if ((meta.ingress_metadata.bypass_lookups & 16w0x80) == 16w0 && meta.ingress_metadata.port_type == 2w0) 
                process_mac_smac_0.apply();
            if ((meta.ingress_metadata.bypass_lookups & 16w0x1) == 16w0) 
                process_mac_dmac_0.apply();
            if (meta.l3_metadata.lkp_ip_type == 2w0) 
                if ((meta.ingress_metadata.bypass_lookups & 16w0x4) == 16w0) 
                    process_mac_acl_mac_acl_0.apply();
            else 
                if ((meta.ingress_metadata.bypass_lookups & 16w0x4) == 16w0) 
                    if (meta.l3_metadata.lkp_ip_type == 2w1) 
                        process_ip_acl_ip_acl_0.apply();
                    else 
                        ;
            switch (rmac.apply().action_run) {
                default: {
                }
                rmac_miss_0: {
                }
            }

        }
        if (meta.tunnel_metadata.tunnel_terminate == 1w0 && hdr.ipv4.isValid() || meta.tunnel_metadata.tunnel_terminate == 1w1 && hdr.inner_ipv4.isValid()) 
            process_hashes_compute_ipv4_hashes_0.apply();
        else 
            process_hashes_compute_non_ip_hashes_0.apply();
        process_hashes_compute_other_hashes_0.apply();
        if (meta.ingress_metadata.port_type != 2w1) {
            process_ingress_bd_stats_ingress_bd_stats_2.apply();
            process_ingress_acl_stats_acl_stats_2.apply();
            if (!(meta.ingress_metadata.bypass_lookups == 16w0xffff)) 
                process_fwd_results_fwd_result_0.apply();
            if (meta.nexthop_metadata.nexthop_type == 2w1) 
                process_nexthop_ecmp_group_0.apply();
            else 
                process_nexthop_nexthop_0.apply();
            if (meta.ingress_metadata.egress_ifindex == 16w65535) 
                ;
            else 
                process_lag_lag_group_0.apply();
            if (meta.l2_metadata.learning_enabled == 1w1) 
                process_mac_learning_learn_notify_0.apply();
        }
        process_fabric_lag_fabric_lag_0.apply();
        if (meta.ingress_metadata.port_type != 2w1) 
            if ((meta.ingress_metadata.bypass_lookups & 16w0x20) == 16w0) {
                process_system_acl_system_acl_0.apply();
                if (meta.ingress_metadata.drop_flag == 1w1) 
                    process_system_acl_drop_stats_4.apply();
            }
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

struct tuple_4 {
    bit<4>  field_19;
    bit<4>  field_20;
    bit<8>  field_21;
    bit<16> field_22;
    bit<16> field_23;
    bit<3>  field_24;
    bit<13> field_25;
    bit<8>  field_26;
    bit<8>  field_27;
    bit<32> field_28;
    bit<32> field_29;
}

control verifyChecksum(in headers hdr, inout metadata meta) {
    @name("inner_ipv4_checksum") Checksum16() inner_ipv4_checksum;
    @name("ipv4_checksum") Checksum16() ipv4_checksum;
    apply {
        if (hdr.inner_ipv4.ihl == 4w5 && hdr.inner_ipv4.hdrChecksum == (inner_ipv4_checksum.get<tuple_4>({ hdr.inner_ipv4.version, hdr.inner_ipv4.ihl, hdr.inner_ipv4.diffserv, hdr.inner_ipv4.totalLen, hdr.inner_ipv4.identification, hdr.inner_ipv4.flags, hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.ttl, hdr.inner_ipv4.protocol, hdr.inner_ipv4.srcAddr, hdr.inner_ipv4.dstAddr }))) 
            mark_to_drop();
        if (hdr.ipv4.ihl == 4w5 && hdr.ipv4.hdrChecksum == (ipv4_checksum.get<tuple_4>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }))) 
            mark_to_drop();
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    @name("inner_ipv4_checksum") Checksum16() inner_ipv4_checksum_2;
    @name("ipv4_checksum") Checksum16() ipv4_checksum_2;
    apply {
        if (hdr.inner_ipv4.ihl == 4w5) 
            hdr.inner_ipv4.hdrChecksum = inner_ipv4_checksum_2.get<tuple_4>({ hdr.inner_ipv4.version, hdr.inner_ipv4.ihl, hdr.inner_ipv4.diffserv, hdr.inner_ipv4.totalLen, hdr.inner_ipv4.identification, hdr.inner_ipv4.flags, hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.ttl, hdr.inner_ipv4.protocol, hdr.inner_ipv4.srcAddr, hdr.inner_ipv4.dstAddr });
        if (hdr.ipv4.ihl == 4w5) 
            hdr.ipv4.hdrChecksum = ipv4_checksum_2.get<tuple_4>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr });
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
