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
    @pa_solitary("ingress", "acl_metadata.if_label") @pa_atomic("ingress", "acl_metadata.if_label") @name(".acl_metadata") 
    acl_metadata_t                              acl_metadata;
    @name(".eg_intr_md") 
    egress_intrinsic_metadata_t                 eg_intr_md;
    @name(".eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t eg_intr_md_from_parser_aux;
    @name(".egress_filter_metadata") 
    egress_filter_metadata_t                    egress_filter_metadata;
    @name(".egress_metadata") 
    egress_metadata_t                           egress_metadata;
    @name(".fabric_metadata") 
    fabric_metadata_t                           fabric_metadata;
    @name(".flowlet_metadata") 
    flowlet_metadata_t                          flowlet_metadata;
    @name(".global_config_metadata") 
    global_config_metadata_t                    global_config_metadata;
    @pa_atomic("ingress", "hash_metadata.hash1") @pa_solitary("ingress", "hash_metadata.hash1") @pa_atomic("ingress", "hash_metadata.hash2") @pa_solitary("ingress", "hash_metadata.hash2") @name(".hash_metadata") 
    hash_metadata_t                             hash_metadata;
    @name(".i2e_metadata") 
    i2e_metadata_t                              i2e_metadata;
    @name(".ig_intr_md") 
    ingress_intrinsic_metadata_t                ig_intr_md;
    @name(".ig_intr_md_for_tm") 
    ingress_intrinsic_metadata_for_tm_t         ig_intr_md_for_tm;
    @name(".ig_prsr_ctrl") 
    ingress_parser_control_signals              ig_prsr_ctrl;
    @pa_atomic("ingress", "ingress_metadata.port_type") @pa_solitary("ingress", "ingress_metadata.port_type") @pa_atomic("ingress", "ingress_metadata.ifindex") @pa_solitary("ingress", "ingress_metadata.ifindex") @pa_atomic("egress", "ingress_metadata.bd") @pa_solitary("egress", "ingress_metadata.bd") @name(".ingress_metadata") 
    ingress_metadata_t                          ingress_metadata;
    @name(".int_metadata") 
    int_metadata_t                              int_metadata;
    @name(".int_metadata_i2e") 
    int_metadata_i2e_t                          int_metadata_i2e;
    @name(".intrinsic_metadata") 
    intrinsic_metadata_t                        intrinsic_metadata;
    @name(".ipv4_metadata") 
    ipv4_metadata_t                             ipv4_metadata;
    @name(".ipv6_metadata") 
    ipv6_metadata_t                             ipv6_metadata;
    @name(".l2_metadata") 
    l2_metadata_t                               l2_metadata;
    @name(".l3_metadata") 
    l3_metadata_t                               l3_metadata;
    @name(".meter_metadata") 
    meter_metadata_t                            meter_metadata;
    @name(".multicast_metadata") 
    multicast_metadata_t                        multicast_metadata;
    @name(".nat_metadata") 
    nat_metadata_t                              nat_metadata;
    @name(".nexthop_metadata") 
    nexthop_metadata_t                          nexthop_metadata;
    @name(".qos_metadata") 
    qos_metadata_t                              qos_metadata;
    @name(".security_metadata") 
    security_metadata_t                         security_metadata;
    @name(".tunnel_metadata") 
    tunnel_metadata_t                           tunnel_metadata;
}

struct headers {
    @name(".eompls") 
    eompls_t                                eompls;
    @name(".erspan_t3_header") 
    erspan_header_t3_t_0                    erspan_t3_header;
    @name(".ethernet") 
    ethernet_t                              ethernet;
    @name(".fabric_header") 
    fabric_header_t                         fabric_header;
    @name(".fabric_header_bfd") 
    fabric_header_bfd_event_t               fabric_header_bfd;
    @name(".fabric_header_cpu") 
    fabric_header_cpu_t                     fabric_header_cpu;
    @name(".fabric_header_mirror") 
    fabric_header_mirror_t                  fabric_header_mirror;
    @name(".fabric_header_multicast") 
    fabric_header_multicast_t               fabric_header_multicast;
    @name(".fabric_header_sflow") 
    fabric_header_sflow_t                   fabric_header_sflow;
    @name(".fabric_header_unicast") 
    fabric_header_unicast_t                 fabric_header_unicast;
    @name(".fabric_payload_header") 
    fabric_payload_header_t                 fabric_payload_header;
    @name(".fcoe") 
    fcoe_header_t                           fcoe;
    @name(".genv") 
    genv_t                                  genv;
    @name(".gre") 
    gre_t                                   gre;
    @name(".icmp") 
    icmp_t                                  icmp;
    @name(".inner_ethernet") 
    ethernet_t                              inner_ethernet;
    @name(".inner_icmp") 
    icmp_t                                  inner_icmp;
    @pa_fragment("ingress", "inner_ipv4.hdrChecksum") @pa_fragment("egress", "inner_ipv4.hdrChecksum") @name(".inner_ipv4") 
    ipv4_t                                  inner_ipv4;
    @name(".inner_ipv6") 
    ipv6_t                                  inner_ipv6;
    @name(".inner_sctp") 
    sctp_t                                  inner_sctp;
    @pa_fragment("egress", "inner_tcp.checksum") @pa_fragment("egress", "inner_tcp.urgentPtr") @name(".inner_tcp") 
    tcp_t                                   inner_tcp;
    @name(".inner_udp") 
    udp_t                                   inner_udp;
    @name(".int_egress_port_id_header") 
    int_egress_port_id_header_t             int_egress_port_id_header;
    @name(".int_egress_port_tx_utilization_header") 
    int_egress_port_tx_utilization_header_t int_egress_port_tx_utilization_header;
    @name(".int_header") 
    int_header_t                            int_header;
    @name(".int_hop_latency_header") 
    int_hop_latency_header_t                int_hop_latency_header;
    @name(".int_ingress_port_id_header") 
    int_ingress_port_id_header_t            int_ingress_port_id_header;
    @name(".int_ingress_tstamp_header") 
    int_ingress_tstamp_header_t             int_ingress_tstamp_header;
    @name(".int_plt_header") 
    int_plt_header_t                        int_plt_header;
    @name(".int_port_ids_header") 
    int_port_ids_header_t                   int_port_ids_header;
    @name(".int_q_congestion_header") 
    int_q_congestion_header_t               int_q_congestion_header;
    @name(".int_q_occupancy_header") 
    int_q_occupancy_header_t                int_q_occupancy_header;
    @name(".int_switch_id_header") 
    int_switch_id_header_t                  int_switch_id_header;
    @pa_fragment("ingress", "ipv4.hdrChecksum") @pa_fragment("egress", "ipv4.hdrChecksum") @name(".ipv4") 
    ipv4_t                                  ipv4;
    @name(".ipv6") 
    ipv6_t                                  ipv6;
    @name(".lisp") 
    lisp_t                                  lisp;
    @name(".llc_header") 
    llc_header_t                            llc_header;
    @name(".nsh") 
    nsh_t                                   nsh;
    @name(".nsh_context") 
    nsh_context_t                           nsh_context;
    @name(".nvgre") 
    nvgre_t                                 nvgre;
    @name(".outer_udp") 
    udp_t                                   outer_udp;
    @name(".roce") 
    roce_header_t                           roce;
    @name(".roce_v2") 
    roce_v2_header_t                        roce_v2;
    @name(".sctp") 
    sctp_t                                  sctp;
    @name(".sflow") 
    sflow_hdr_t                             sflow;
    @name(".sflow_raw_hdr_record") 
    sflow_raw_hdr_record_t                  sflow_raw_hdr_record;
    @name(".sflow_sample") 
    sflow_sample_t                          sflow_sample;
    @name(".snap_header") 
    snap_header_t                           snap_header;
    @pa_fragment("egress", "tcp.checksum") @pa_fragment("egress", "tcp.urgentPtr") @name(".tcp") 
    tcp_t                                   tcp;
    @name(".trill") 
    trill_t                                 trill;
    @name(".udp") 
    udp_t                                   udp;
    @name(".vntag") 
    vntag_t                                 vntag;
    @name(".vxlan") 
    vxlan_t                                 vxlan;
    @name(".vxlan_gpe") 
    vxlan_gpe_t                             vxlan_gpe;
    @name(".vxlan_gpe_int_header") 
    vxlan_gpe_int_header_t                  vxlan_gpe_int_header;
    @name(".vxlan_gpe_int_plt_header") 
    vxlan_gpe_int_header_t                  vxlan_gpe_int_plt_header;
    @name(".mpls") 
    mpls_t[3]                               mpls;
    @name(".vlan_tag_") 
    vlan_tag_t[2]                           vlan_tag_;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<8> tmp_9;
    bit<112> tmp_10;
    @name(".parse_arp_rarp") state parse_arp_rarp {
        transition parse_set_prio_med;
    }
    @name(".parse_ethernet") state parse_ethernet {
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
    @name(".parse_fabric_header") state parse_fabric_header {
        packet.extract<fabric_header_t>(hdr.fabric_header);
        transition select(hdr.fabric_header.packetType) {
            3w1: parse_fabric_header_unicast;
            3w2: parse_fabric_header_multicast;
            3w3: parse_fabric_header_mirror;
            3w5: parse_fabric_header_cpu;
            default: accept;
        }
    }
    @name(".parse_fabric_header_cpu") state parse_fabric_header_cpu {
        packet.extract<fabric_header_cpu_t>(hdr.fabric_header_cpu);
        meta.ingress_metadata.bypass_lookups = hdr.fabric_header_cpu.reasonCode;
        transition select(hdr.fabric_header_cpu.reasonCode) {
            default: parse_fabric_payload_header;
        }
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
            default: accept;
        }
    }
    @name(".parse_gpe_int_header") state parse_gpe_int_header {
        tmp_9 = packet.lookahead<bit<8>>();
        transition select(tmp_9[7:0]) {
            8w3: parse_int_shim_plt_header;
            default: parse_int_shim_header;
        }
    }
    @name(".parse_icmp") state parse_icmp {
        packet.extract<icmp_t>(hdr.icmp);
        meta.l3_metadata.lkp_outer_l4_sport = hdr.icmp.typeCode;
        transition select(hdr.icmp.typeCode) {
            16w0x8200 &&& 16w0xfe00: parse_set_prio_med;
            16w0x8400 &&& 16w0xfc00: parse_set_prio_med;
            16w0x8800 &&& 16w0xff00: parse_set_prio_med;
            default: accept;
        }
    }
    @name(".parse_inner_ethernet") state parse_inner_ethernet {
        packet.extract<ethernet_t>(hdr.inner_ethernet);
        meta.l2_metadata.lkp_mac_sa = hdr.inner_ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.inner_ethernet.dstAddr;
        transition select(hdr.inner_ethernet.etherType) {
            16w0x800: parse_inner_ipv4;
            16w0x86dd: parse_inner_ipv6;
            default: accept;
        }
    }
    @name(".parse_inner_icmp") state parse_inner_icmp {
        packet.extract<icmp_t>(hdr.inner_icmp);
        meta.l3_metadata.lkp_l4_sport = hdr.inner_icmp.typeCode;
        transition accept;
    }
    @name(".parse_inner_ipv4") state parse_inner_ipv4 {
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
    @name(".parse_inner_ipv6") state parse_inner_ipv6 {
        packet.extract<ipv6_t>(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.nextHdr) {
            8w58: parse_inner_icmp;
            8w6: parse_inner_tcp;
            8w17: parse_inner_udp;
            default: accept;
        }
    }
    @name(".parse_inner_tcp") state parse_inner_tcp {
        packet.extract<tcp_t>(hdr.inner_tcp);
        meta.l3_metadata.lkp_l4_sport = hdr.inner_tcp.srcPort;
        meta.l3_metadata.lkp_l4_dport = hdr.inner_tcp.dstPort;
        transition accept;
    }
    @name(".parse_inner_udp") state parse_inner_udp {
        packet.extract<udp_t>(hdr.inner_udp);
        meta.l3_metadata.lkp_l4_sport = hdr.inner_udp.srcPort;
        meta.l3_metadata.lkp_l4_dport = hdr.inner_udp.dstPort;
        transition accept;
    }
    @name(".parse_int_header") state parse_int_header {
        packet.extract<int_header_t>(hdr.int_header);
        meta.int_metadata.int_hdr_word_len = (bit<8>)hdr.int_header.ins_cnt;
        transition select(hdr.int_header.rsvd1, hdr.int_header.total_hop_cnt) {
            (5w0x0 &&& 5w0xf, 8w0x0 &&& 8w0xff): accept;
            default: accept;
        }
    }
    @name(".parse_int_shim_header") state parse_int_shim_header {
        packet.extract<vxlan_gpe_int_header_t>(hdr.vxlan_gpe_int_header);
        transition parse_int_header;
    }
    @name(".parse_int_shim_plt_header") state parse_int_shim_plt_header {
        packet.extract<vxlan_gpe_int_header_t>(hdr.vxlan_gpe_int_plt_header);
        packet.extract<int_plt_header_t>(hdr.int_plt_header);
        transition select(hdr.vxlan_gpe_int_plt_header.next_proto) {
            8w0x5: parse_int_shim_header;
            default: accept;
        }
    }
    @name(".parse_ipv4") state parse_ipv4 {
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
    @name(".parse_ipv4_in_ip") state parse_ipv4_in_ip {
        meta.tunnel_metadata.ingress_tunnel_type = 5w3;
        transition parse_inner_ipv4;
    }
    @name(".parse_ipv6") state parse_ipv6 {
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
    @name(".parse_llc_header") state parse_llc_header {
        packet.extract<llc_header_t>(hdr.llc_header);
        transition select(hdr.llc_header.dsap, hdr.llc_header.ssap) {
            (8w0xaa, 8w0xaa): parse_snap_header;
            (8w0xfe, 8w0xfe): parse_set_prio_med;
            default: accept;
        }
    }
    @name(".parse_mpls") state parse_mpls {
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
    @name(".parse_set_prio_high") state parse_set_prio_high {
        meta.ig_prsr_ctrl.priority = 3w5;
        transition accept;
    }
    @name(".parse_set_prio_med") state parse_set_prio_med {
        meta.ig_prsr_ctrl.priority = 3w3;
        transition accept;
    }
    @name(".parse_sflow") state parse_sflow {
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
            default: accept;
        }
    }
    @name(".parse_tcp") state parse_tcp {
        packet.extract<tcp_t>(hdr.tcp);
        meta.l3_metadata.lkp_outer_l4_sport = hdr.tcp.srcPort;
        meta.l3_metadata.lkp_outer_l4_dport = hdr.tcp.dstPort;
        transition select(hdr.tcp.dstPort) {
            16w179: parse_set_prio_med;
            16w639: parse_set_prio_med;
            default: accept;
        }
    }
    @name(".parse_udp") state parse_udp {
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
    @name(".parse_vxlan_gpe") state parse_vxlan_gpe {
        packet.extract<vxlan_gpe_t>(hdr.vxlan_gpe);
        meta.tunnel_metadata.ingress_tunnel_type = 5w12;
        meta.tunnel_metadata.tunnel_vni = hdr.vxlan_gpe.vni;
        transition select(hdr.vxlan_gpe.flags, hdr.vxlan_gpe.next_proto) {
            (8w0x8 &&& 8w0x8, 8w0x5 &&& 8w0xff): parse_gpe_int_header;
            default: parse_inner_ethernet;
        }
    }
    @name(".start") state start {
        tmp_10 = packet.lookahead<bit<112>>();
        transition select(tmp_10[15:0]) {
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
    @name("NoAction") action NoAction_0() {
    }
    @name("NoAction") action NoAction_1() {
    }
    @name("NoAction") action NoAction_57() {
    }
    @name("NoAction") action NoAction_58() {
    }
    @name("NoAction") action NoAction_59() {
    }
    @name("NoAction") action NoAction_60() {
    }
    @name("NoAction") action NoAction_61() {
    }
    @name("NoAction") action NoAction_62() {
    }
    @name("NoAction") action NoAction_63() {
    }
    @name("NoAction") action NoAction_64() {
    }
    @name("NoAction") action NoAction_65() {
    }
    @name("NoAction") action NoAction_66() {
    }
    @name("NoAction") action NoAction_67() {
    }
    @name("NoAction") action NoAction_68() {
    }
    @name("NoAction") action NoAction_69() {
    }
    @name("NoAction") action NoAction_70() {
    }
    @name("NoAction") action NoAction_71() {
    }
    @name("NoAction") action NoAction_72() {
    }
    @name("NoAction") action NoAction_73() {
    }
    @name("NoAction") action NoAction_74() {
    }
    @name("NoAction") action NoAction_75() {
    }
    @name("NoAction") action NoAction_76() {
    }
    @name("NoAction") action NoAction_77() {
    }
    @name("NoAction") action NoAction_78() {
    }
    @name("NoAction") action NoAction_79() {
    }
    @name("NoAction") action NoAction_80() {
    }
    @name(".egress_port_type_normal") action egress_port_type_normal_0(bit<16> ifindex, bit<5> qos_group, bit<16> if_label) {
        meta.egress_metadata.port_type = 2w0;
        meta.egress_metadata.ifindex = ifindex;
        meta.qos_metadata.egress_qos_group = qos_group;
        meta.acl_metadata.egress_if_label = if_label;
    }
    @name(".egress_port_type_fabric") action egress_port_type_fabric_0(bit<16> ifindex) {
        meta.egress_metadata.port_type = 2w1;
        meta.egress_metadata.ifindex = ifindex;
        meta.tunnel_metadata.egress_tunnel_type = 5w15;
    }
    @name(".egress_port_type_cpu") action egress_port_type_cpu_0(bit<16> ifindex) {
        meta.egress_metadata.port_type = 2w2;
        meta.egress_metadata.ifindex = ifindex;
        meta.tunnel_metadata.egress_tunnel_type = 5w16;
    }
    @name(".egress_port_mapping") table egress_port_mapping {
        actions = {
            egress_port_type_normal_0();
            egress_port_type_fabric_0();
            egress_port_type_cpu_0();
            @defaultonly NoAction_0();
        }
        key = {
            meta.eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        size = 288;
        default_action = NoAction_0();
    }
    @name(".quantize_latency_1") action _quantize_latency() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 1;
    }
    @name(".quantize_latency_2") action _quantize_latency_0() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 2;
    }
    @name(".quantize_latency_3") action _quantize_latency_1() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 3;
    }
    @name(".quantize_latency_4") action _quantize_latency_2() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 4;
    }
    @name(".quantize_latency_5") action _quantize_latency_3() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 5;
    }
    @name(".quantize_latency_6") action _quantize_latency_4() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 6;
    }
    @name(".quantize_latency_7") action _quantize_latency_5() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 7;
    }
    @name(".quantize_latency_8") action _quantize_latency_6() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 8;
    }
    @name(".quantize_latency_9") action _quantize_latency_7() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 9;
    }
    @name(".quantize_latency_10") action _quantize_latency_8() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 10;
    }
    @name(".quantize_latency_11") action _quantize_latency_9() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 11;
    }
    @name(".quantize_latency_12") action _quantize_latency_10() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 12;
    }
    @name(".quantize_latency_13") action _quantize_latency_11() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 13;
    }
    @name(".quantize_latency_14") action _quantize_latency_12() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 14;
    }
    @name(".quantize_latency_15") action _quantize_latency_13() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta >> 15;
    }
    @name(".copy_latency") action _copy_latency() {
        meta.int_metadata.quantized_latency = meta.eg_intr_md.deq_timedelta;
    }
    @name(".scramble_latency") action _scramble_latency() {
        meta.int_metadata.quantized_latency = meta.global_config_metadata.switch_id - meta.int_metadata.quantized_latency;
    }
    @name(".plt_quantize_latency") table _plt_quantize_latency_0 {
        actions = {
            _quantize_latency();
            _quantize_latency_0();
            _quantize_latency_1();
            _quantize_latency_2();
            _quantize_latency_3();
            _quantize_latency_4();
            _quantize_latency_5();
            _quantize_latency_6();
            _quantize_latency_7();
            _quantize_latency_8();
            _quantize_latency_9();
            _quantize_latency_10();
            _quantize_latency_11();
            _quantize_latency_12();
            _quantize_latency_13();
            _copy_latency();
            @defaultonly NoAction_1();
        }
        key = {
            hdr.ethernet.isValid(): exact @name("ethernet.$valid$") ;
        }
        size = 2;
        default_action = NoAction_1();
    }
    @name(".plt_scramble_latency") table _plt_scramble_latency_0 {
        actions = {
            _scramble_latency();
            @defaultonly NoAction_57();
        }
        size = 1;
        default_action = NoAction_57();
    }
    @name(".nop") action _nop_1() {
    }
    @name(".remove_vlan_single_tagged") action _remove_vlan_single_tagged() {
        hdr.ethernet.etherType = hdr.vlan_tag_[0].etherType;
        hdr.vlan_tag_[0].setInvalid();
    }
    @name(".remove_vlan_double_tagged") action _remove_vlan_double_tagged() {
        hdr.ethernet.etherType = hdr.vlan_tag_[1].etherType;
        hdr.vlan_tag_[0].setInvalid();
        hdr.vlan_tag_[1].setInvalid();
    }
    @ternary(1) @name(".vlan_decap") table _vlan_decap_0 {
        actions = {
            _nop_1();
            _remove_vlan_single_tagged();
            _remove_vlan_double_tagged();
            @defaultonly NoAction_58();
        }
        key = {
            hdr.vlan_tag_[0].isValid(): exact @name("vlan_tag_[0].$valid$") ;
            hdr.vlan_tag_[1].isValid(): exact @name("vlan_tag_[1].$valid$") ;
        }
        size = 256;
        default_action = NoAction_58();
    }
    @name(".nop") action _nop_2() {
    }
    @name(".set_l2_rewrite") action _set_l2_rewrite() {
        meta.egress_metadata.routed = 1w0;
        meta.egress_metadata.bd = meta.ingress_metadata.bd;
        meta.egress_metadata.outer_bd = meta.ingress_metadata.bd;
    }
    @name(".rewrite") table _rewrite_0 {
        actions = {
            _nop_2();
            _set_l2_rewrite();
            @defaultonly NoAction_59();
        }
        key = {
            meta.l3_metadata.nexthop_index: exact @name("l3_metadata.nexthop_index") ;
        }
        size = 16384;
        default_action = NoAction_59();
    }
    @name(".nop") action _nop_3() {
    }
    @name(".set_egress_bd_properties") action _set_egress_bd_properties(bit<9> smac_idx, bit<2> nat_mode, bit<16> bd_label) {
        meta.egress_metadata.smac_idx = smac_idx;
        meta.nat_metadata.egress_nat_mode = nat_mode;
        meta.acl_metadata.egress_bd_label = bd_label;
    }
    @name(".egress_bd_map") table _egress_bd_map_0 {
        actions = {
            _nop_3();
            _set_egress_bd_properties();
            @defaultonly NoAction_60();
        }
        key = {
            meta.egress_metadata.bd: exact @name("egress_metadata.bd") ;
        }
        size = 16384;
        default_action = NoAction_60();
    }
    @name(".egress_bd_stats") direct_counter(CounterType.packets_and_bytes) _egress_bd_stats_1;
    @name(".nop") action _nop_4() {
        _egress_bd_stats_1.count();
    }
    @name(".egress_bd_stats") table _egress_bd_stats_2 {
        actions = {
            _nop_4();
            @defaultonly NoAction_61();
        }
        key = {
            meta.egress_metadata.bd      : exact @name("egress_metadata.bd") ;
            meta.l2_metadata.lkp_pkt_type: exact @name("l2_metadata.lkp_pkt_type") ;
        }
        size = 16384;
        @name(".egress_bd_stats") counters = direct_counter(CounterType.packets_and_bytes);
        default_action = NoAction_61();
    }
    @name(".nop") action _nop_5() {
    }
    @name(".set_egress_tcp_port_fields") action _set_egress_tcp_port_fields() {
        meta.l3_metadata.egress_l4_sport = hdr.tcp.srcPort;
        meta.l3_metadata.egress_l4_dport = hdr.tcp.dstPort;
    }
    @name(".set_egress_udp_port_fields") action _set_egress_udp_port_fields() {
        meta.l3_metadata.egress_l4_sport = hdr.udp.srcPort;
        meta.l3_metadata.egress_l4_dport = hdr.udp.dstPort;
    }
    @name(".set_egress_icmp_port_fields") action _set_egress_icmp_port_fields() {
        meta.l3_metadata.egress_l4_sport = hdr.icmp.typeCode;
    }
    @name(".egress_l4port_fields") table _egress_l4port_fields_0 {
        actions = {
            _nop_5();
            _set_egress_tcp_port_fields();
            _set_egress_udp_port_fields();
            _set_egress_icmp_port_fields();
            @defaultonly NoAction_62();
        }
        key = {
            hdr.tcp.isValid() : exact @name("tcp.$valid$") ;
            hdr.udp.isValid() : exact @name("udp.$valid$") ;
            hdr.icmp.isValid(): exact @name("icmp.$valid$") ;
        }
        size = 4;
        default_action = NoAction_62();
    }
    @name(".int_set_header_0_bos") action _int_set_header_0_bos_0() {
        hdr.int_switch_id_header.bos = 1w1;
    }
    @name(".int_set_header_1_bos") action _int_set_header_1_bos_0() {
        hdr.int_port_ids_header.bos = 1w1;
    }
    @name(".int_set_header_2_bos") action _int_set_header_2_bos_0() {
        hdr.int_hop_latency_header.bos = 1w1;
    }
    @name(".int_set_header_3_bos") action _int_set_header_3_bos_0() {
        hdr.int_q_occupancy_header.bos = 1w1;
    }
    @name(".nop") action _nop_6() {
    }
    @name(".nop") action _nop_7() {
    }
    @name(".nop") action _nop_8() {
    }
    @name(".nop") action _nop_9() {
    }
    @name(".nop") action _nop_10() {
    }
    @name(".int_transit") action _int_transit_0() {
        meta.int_metadata.hit_state = 2w1;
        meta.int_metadata.insert_cnt = hdr.int_header.max_hop_cnt - hdr.int_header.total_hop_cnt;
        meta.int_metadata.insert_byte_cnt = (bit<16>)meta.int_metadata.int_hdr_word_len << 2;
    }
    @name(".int_reset") action _int_reset_0() {
        meta.int_metadata.insert_cnt = 8w0;
        meta.int_metadata.int_hdr_word_len = 8w0;
    }
    @name(".int_set_header_0003_i0") action _int_set_header_0003_i0_0() {
    }
    @name(".int_set_header_0003_i1") action _int_set_header_0003_i1_0() {
        hdr.int_q_occupancy_header.setValid();
        hdr.int_q_occupancy_header.q_occupancy1 = 7w0;
        hdr.int_q_occupancy_header.q_occupancy0 = (bit<24>)meta.eg_intr_md.enq_qdepth;
    }
    @name(".int_set_header_0003_i2") action _int_set_header_0003_i2_0() {
        hdr.int_hop_latency_header.setValid();
        hdr.int_hop_latency_header.hop_latency = (bit<31>)meta.eg_intr_md.deq_timedelta;
    }
    @name(".int_set_header_0003_i3") action _int_set_header_0003_i3_0() {
        hdr.int_q_occupancy_header.setValid();
        hdr.int_q_occupancy_header.q_occupancy1 = 7w0;
        hdr.int_q_occupancy_header.q_occupancy0 = (bit<24>)meta.eg_intr_md.enq_qdepth;
        hdr.int_hop_latency_header.setValid();
        hdr.int_hop_latency_header.hop_latency = (bit<31>)meta.eg_intr_md.deq_timedelta;
    }
    @name(".int_set_header_0003_i4") action _int_set_header_0003_i4_0() {
        hdr.int_port_ids_header.setValid();
        hdr.int_port_ids_header.ingress_port_id = meta.ingress_metadata.ingress_port;
        hdr.int_port_ids_header.egress_port_id = (bit<16>)meta.eg_intr_md.egress_port;
    }
    @name(".int_set_header_0003_i5") action _int_set_header_0003_i5_0() {
        hdr.int_q_occupancy_header.setValid();
        hdr.int_q_occupancy_header.q_occupancy1 = 7w0;
        hdr.int_q_occupancy_header.q_occupancy0 = (bit<24>)meta.eg_intr_md.enq_qdepth;
        hdr.int_port_ids_header.setValid();
        hdr.int_port_ids_header.ingress_port_id = meta.ingress_metadata.ingress_port;
        hdr.int_port_ids_header.egress_port_id = (bit<16>)meta.eg_intr_md.egress_port;
    }
    @name(".int_set_header_0003_i6") action _int_set_header_0003_i6_0() {
        hdr.int_hop_latency_header.setValid();
        hdr.int_hop_latency_header.hop_latency = (bit<31>)meta.eg_intr_md.deq_timedelta;
        hdr.int_port_ids_header.setValid();
        hdr.int_port_ids_header.ingress_port_id = meta.ingress_metadata.ingress_port;
        hdr.int_port_ids_header.egress_port_id = (bit<16>)meta.eg_intr_md.egress_port;
    }
    @name(".int_set_header_0003_i7") action _int_set_header_0003_i7_0() {
        hdr.int_q_occupancy_header.setValid();
        hdr.int_q_occupancy_header.q_occupancy1 = 7w0;
        hdr.int_q_occupancy_header.q_occupancy0 = (bit<24>)meta.eg_intr_md.enq_qdepth;
        hdr.int_hop_latency_header.setValid();
        hdr.int_hop_latency_header.hop_latency = (bit<31>)meta.eg_intr_md.deq_timedelta;
        hdr.int_port_ids_header.setValid();
        hdr.int_port_ids_header.ingress_port_id = meta.ingress_metadata.ingress_port;
        hdr.int_port_ids_header.egress_port_id = (bit<16>)meta.eg_intr_md.egress_port;
    }
    @name(".int_set_header_0003_i8") action _int_set_header_0003_i8_0() {
        hdr.int_switch_id_header.setValid();
        hdr.int_switch_id_header.switch_id = (bit<31>)meta.global_config_metadata.switch_id;
    }
    @name(".int_set_header_0003_i9") action _int_set_header_0003_i9_0() {
        hdr.int_q_occupancy_header.setValid();
        hdr.int_q_occupancy_header.q_occupancy1 = 7w0;
        hdr.int_q_occupancy_header.q_occupancy0 = (bit<24>)meta.eg_intr_md.enq_qdepth;
        hdr.int_switch_id_header.setValid();
        hdr.int_switch_id_header.switch_id = (bit<31>)meta.global_config_metadata.switch_id;
    }
    @name(".int_set_header_0003_i10") action _int_set_header_0003_i10_0() {
        hdr.int_hop_latency_header.setValid();
        hdr.int_hop_latency_header.hop_latency = (bit<31>)meta.eg_intr_md.deq_timedelta;
        hdr.int_switch_id_header.setValid();
        hdr.int_switch_id_header.switch_id = (bit<31>)meta.global_config_metadata.switch_id;
    }
    @name(".int_set_header_0003_i11") action _int_set_header_0003_i11_0() {
        hdr.int_q_occupancy_header.setValid();
        hdr.int_q_occupancy_header.q_occupancy1 = 7w0;
        hdr.int_q_occupancy_header.q_occupancy0 = (bit<24>)meta.eg_intr_md.enq_qdepth;
        hdr.int_hop_latency_header.setValid();
        hdr.int_hop_latency_header.hop_latency = (bit<31>)meta.eg_intr_md.deq_timedelta;
        hdr.int_switch_id_header.setValid();
        hdr.int_switch_id_header.switch_id = (bit<31>)meta.global_config_metadata.switch_id;
    }
    @name(".int_set_header_0003_i12") action _int_set_header_0003_i12_0() {
        hdr.int_port_ids_header.setValid();
        hdr.int_port_ids_header.ingress_port_id = meta.ingress_metadata.ingress_port;
        hdr.int_port_ids_header.egress_port_id = (bit<16>)meta.eg_intr_md.egress_port;
        hdr.int_switch_id_header.setValid();
        hdr.int_switch_id_header.switch_id = (bit<31>)meta.global_config_metadata.switch_id;
    }
    @name(".int_set_header_0003_i13") action _int_set_header_0003_i13_0() {
        hdr.int_q_occupancy_header.setValid();
        hdr.int_q_occupancy_header.q_occupancy1 = 7w0;
        hdr.int_q_occupancy_header.q_occupancy0 = (bit<24>)meta.eg_intr_md.enq_qdepth;
        hdr.int_port_ids_header.setValid();
        hdr.int_port_ids_header.ingress_port_id = meta.ingress_metadata.ingress_port;
        hdr.int_port_ids_header.egress_port_id = (bit<16>)meta.eg_intr_md.egress_port;
        hdr.int_switch_id_header.setValid();
        hdr.int_switch_id_header.switch_id = (bit<31>)meta.global_config_metadata.switch_id;
    }
    @name(".int_set_header_0003_i14") action _int_set_header_0003_i14_0() {
        hdr.int_hop_latency_header.setValid();
        hdr.int_hop_latency_header.hop_latency = (bit<31>)meta.eg_intr_md.deq_timedelta;
        hdr.int_port_ids_header.setValid();
        hdr.int_port_ids_header.ingress_port_id = meta.ingress_metadata.ingress_port;
        hdr.int_port_ids_header.egress_port_id = (bit<16>)meta.eg_intr_md.egress_port;
        hdr.int_switch_id_header.setValid();
        hdr.int_switch_id_header.switch_id = (bit<31>)meta.global_config_metadata.switch_id;
    }
    @name(".int_set_header_0003_i15") action _int_set_header_0003_i15_0() {
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
    @name(".int_set_e_bit") action _int_set_e_bit_0() {
        hdr.int_header.e = 1w1;
    }
    @name(".int_update_total_hop_cnt") action _int_update_total_hop_cnt_0() {
        hdr.int_header.total_hop_cnt = hdr.int_header.total_hop_cnt + 8w1;
    }
    @name(".clear_upper") action _clear_upper_0() {
        meta.int_metadata.insert_byte_cnt = meta.int_metadata.insert_byte_cnt & 16w0x7f;
    }
    @name(".int_bos") table _int_bos {
        actions = {
            _int_set_header_0_bos_0();
            _int_set_header_1_bos_0();
            _int_set_header_2_bos_0();
            _int_set_header_3_bos_0();
            _nop_6();
            @defaultonly NoAction_63();
        }
        key = {
            hdr.int_header.total_hop_cnt        : ternary @name("int_header.total_hop_cnt") ;
            hdr.int_header.instruction_mask_0003: ternary @name("int_header.instruction_mask_0003") ;
            hdr.int_header.instruction_mask_0407: ternary @name("int_header.instruction_mask_0407") ;
            hdr.int_header.instruction_mask_0811: ternary @name("int_header.instruction_mask_0811") ;
            hdr.int_header.instruction_mask_1215: ternary @name("int_header.instruction_mask_1215") ;
        }
        size = 17;
        default_action = NoAction_63();
    }
    @name(".int_insert") table _int_insert {
        actions = {
            _int_transit_0();
            _int_reset_0();
            _nop_7();
            @defaultonly NoAction_64();
        }
        key = {
            meta.int_metadata_i2e.source   : ternary @name("int_metadata_i2e.source") ;
            meta.int_metadata_i2e.sink     : ternary @name("int_metadata_i2e.sink") ;
            hdr.int_header.isValid()       : exact @name("int_header.$valid$") ;
            standard_metadata.instance_type: ternary @name("standard_metadata.instance_type") ;
        }
        size = 5;
        default_action = NoAction_64();
    }
    @ternary(1) @name(".int_inst_0003") table _int_inst {
        actions = {
            _int_set_header_0003_i0_0();
            _int_set_header_0003_i1_0();
            _int_set_header_0003_i2_0();
            _int_set_header_0003_i3_0();
            _int_set_header_0003_i4_0();
            _int_set_header_0003_i5_0();
            _int_set_header_0003_i6_0();
            _int_set_header_0003_i7_0();
            _int_set_header_0003_i8_0();
            _int_set_header_0003_i9_0();
            _int_set_header_0003_i10_0();
            _int_set_header_0003_i11_0();
            _int_set_header_0003_i12_0();
            _int_set_header_0003_i13_0();
            _int_set_header_0003_i14_0();
            _int_set_header_0003_i15_0();
            @defaultonly NoAction_65();
        }
        key = {
            hdr.int_header.instruction_mask_0003: exact @name("int_header.instruction_mask_0003") ;
        }
        size = 17;
        default_action = NoAction_65();
    }
    @ternary(1) @name(".int_inst_0407") table _int_inst_0 {
        actions = {
            _nop_8();
            @defaultonly NoAction_66();
        }
        key = {
            hdr.int_header.instruction_mask_0407: exact @name("int_header.instruction_mask_0407") ;
        }
        size = 17;
        default_action = NoAction_66();
    }
    @name(".int_inst_0811") table _int_inst_1 {
        actions = {
            _nop_9();
            @defaultonly NoAction_67();
        }
        key = {
            hdr.int_header.instruction_mask_0811: exact @name("int_header.instruction_mask_0811") ;
        }
        size = 17;
        default_action = NoAction_67();
    }
    @name(".int_inst_1215") table _int_inst_2 {
        actions = {
            _nop_10();
            @defaultonly NoAction_68();
        }
        key = {
            hdr.int_header.instruction_mask_1215: exact @name("int_header.instruction_mask_1215") ;
        }
        size = 17;
        default_action = NoAction_68();
    }
    @name(".int_meta_header_update") table _int_meta_header_update {
        actions = {
            _int_set_e_bit_0();
            _int_update_total_hop_cnt_0();
            @defaultonly NoAction_69();
        }
        key = {
            meta.int_metadata.insert_cnt: exact @name("int_metadata.insert_cnt") ;
        }
        size = 2;
        default_action = NoAction_69();
    }
    @name(".int_transit_clear_byte_cnt") table _int_transit_clear_byte_cnt {
        actions = {
            _clear_upper_0();
            @defaultonly NoAction_70();
        }
        size = 1;
        default_action = NoAction_70();
    }
    @name(".update_int_plt_header") action _update_int_plt_header_0() {
        hdr.int_plt_header.pl_encoding = hdr.int_plt_header.pl_encoding ^ meta.int_metadata.quantized_latency;
    }
    @name(".int_plt_encode") table _int_plt_encode {
        actions = {
            _update_int_plt_header_0();
            @defaultonly NoAction_71();
        }
        size = 1;
        default_action = NoAction_71();
    }
    @name(".nop") action _nop_11() {
    }
    @name(".nop") action _nop_12() {
    }
    @name(".fabric_rewrite") action _fabric_rewrite(bit<14> tunnel_index) {
        meta.tunnel_metadata.tunnel_index = tunnel_index;
    }
    @name(".cpu_rx_rewrite") action _cpu_rx_rewrite() {
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
    @name(".fabric_unicast_rewrite") action _fabric_unicast_rewrite() {
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
    @ternary(1) @name(".tunnel_encap_process_outer") table _tunnel_encap_process_outer_0 {
        actions = {
            _nop_11();
            _fabric_rewrite();
            @defaultonly NoAction_72();
        }
        key = {
            meta.tunnel_metadata.egress_tunnel_type : exact @name("tunnel_metadata.egress_tunnel_type") ;
            meta.tunnel_metadata.egress_header_count: exact @name("tunnel_metadata.egress_header_count") ;
            meta.multicast_metadata.replica         : exact @name("multicast_metadata.replica") ;
        }
        size = 256;
        default_action = NoAction_72();
    }
    @name(".tunnel_rewrite") table _tunnel_rewrite_0 {
        actions = {
            _nop_12();
            _cpu_rx_rewrite();
            _fabric_unicast_rewrite();
            @defaultonly NoAction_73();
        }
        key = {
            meta.tunnel_metadata.tunnel_index: exact @name("tunnel_metadata.tunnel_index") ;
        }
        size = 16384;
        default_action = NoAction_73();
    }
    @name(".nop") action _nop_13() {
    }
    @name(".nop") action _nop_14() {
    }
    @name(".egress_acl_deny") action _egress_acl_deny(bit<16> acl_copy_reason) {
        meta.acl_metadata.acl_deny = 1w1;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".egress_acl_deny") action _egress_acl_deny_2(bit<16> acl_copy_reason) {
        meta.acl_metadata.acl_deny = 1w1;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".egress_acl_permit") action _egress_acl_permit(bit<16> acl_copy_reason) {
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".egress_acl_permit") action _egress_acl_permit_2(bit<16> acl_copy_reason) {
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".egress_ip_acl") table _egress_ip_acl_0 {
        actions = {
            _nop_13();
            _egress_acl_deny();
            _egress_acl_permit();
            @defaultonly NoAction_74();
        }
        key = {
            meta.acl_metadata.egress_if_label         : ternary @name("acl_metadata.egress_if_label") ;
            meta.acl_metadata.egress_bd_label         : ternary @name("acl_metadata.egress_bd_label") ;
            hdr.ipv4.srcAddr                          : ternary @name("ipv4.srcAddr") ;
            hdr.ipv4.dstAddr                          : ternary @name("ipv4.dstAddr") ;
            hdr.ipv4.protocol                         : ternary @name("ipv4.protocol") ;
            meta.acl_metadata.egress_src_port_range_id: exact @name("acl_metadata.egress_src_port_range_id") ;
            meta.acl_metadata.egress_dst_port_range_id: exact @name("acl_metadata.egress_dst_port_range_id") ;
        }
        size = 128;
        default_action = NoAction_74();
    }
    @name(".egress_mac_acl") table _egress_mac_acl_0 {
        actions = {
            _nop_14();
            _egress_acl_deny_2();
            _egress_acl_permit_2();
            @defaultonly NoAction_75();
        }
        key = {
            meta.acl_metadata.egress_if_label: ternary @name("acl_metadata.egress_if_label") ;
            meta.acl_metadata.egress_bd_label: ternary @name("acl_metadata.egress_bd_label") ;
            hdr.ethernet.srcAddr             : ternary @name("ethernet.srcAddr") ;
            hdr.ethernet.dstAddr             : ternary @name("ethernet.dstAddr") ;
            hdr.ethernet.etherType           : ternary @name("ethernet.etherType") ;
        }
        size = 128;
        default_action = NoAction_75();
    }
    @name(".int_update_vxlan_gpe_ipv4") action _int_update_vxlan_gpe_ipv4() {
        hdr.ipv4.totalLen = hdr.ipv4.totalLen + meta.int_metadata.insert_byte_cnt;
        hdr.udp.length_ = hdr.udp.length_ + meta.int_metadata.insert_byte_cnt;
        hdr.vxlan_gpe_int_header.len = hdr.vxlan_gpe_int_header.len + meta.int_metadata.int_hdr_word_len;
    }
    @name(".nop") action _nop_15() {
    }
    @name(".int_outer_encap") table _int_outer_encap_0 {
        actions = {
            _int_update_vxlan_gpe_ipv4();
            _nop_15();
            @defaultonly NoAction_76();
        }
        key = {
            hdr.ipv4.isValid()                     : exact @name("ipv4.$valid$") ;
            hdr.vxlan_gpe.isValid()                : exact @name("vxlan_gpe.$valid$") ;
            hdr.erspan_t3_header.isValid()         : exact @name("erspan_t3_header.$valid$") ;
            meta.int_metadata_i2e.source           : exact @name("int_metadata_i2e.source") ;
            meta.int_metadata_i2e.sink             : exact @name("int_metadata_i2e.sink") ;
            meta.tunnel_metadata.egress_tunnel_type: ternary @name("tunnel_metadata.egress_tunnel_type") ;
        }
        size = 8;
        default_action = NoAction_76();
    }
    @name(".set_egress_packet_vlan_untagged") action _set_egress_packet_vlan_untagged() {
    }
    @name(".set_egress_packet_vlan_tagged") action _set_egress_packet_vlan_tagged(bit<12> vlan_id) {
        hdr.vlan_tag_[0].setValid();
        hdr.vlan_tag_[0].etherType = hdr.ethernet.etherType;
        hdr.vlan_tag_[0].vid = vlan_id;
        hdr.ethernet.etherType = 16w0x8100;
    }
    @name(".set_egress_packet_vlan_double_tagged") action _set_egress_packet_vlan_double_tagged(bit<12> s_tag, bit<12> c_tag) {
        hdr.vlan_tag_[1].setValid();
        hdr.vlan_tag_[0].setValid();
        hdr.vlan_tag_[1].etherType = hdr.ethernet.etherType;
        hdr.vlan_tag_[1].vid = c_tag;
        hdr.vlan_tag_[0].etherType = 16w0x8100;
        hdr.vlan_tag_[0].vid = s_tag;
        hdr.ethernet.etherType = 16w0x9100;
    }
    @name(".egress_vlan_xlate") table _egress_vlan_xlate_0 {
        actions = {
            _set_egress_packet_vlan_untagged();
            _set_egress_packet_vlan_tagged();
            _set_egress_packet_vlan_double_tagged();
            @defaultonly NoAction_77();
        }
        key = {
            meta.egress_metadata.ifindex: exact @name("egress_metadata.ifindex") ;
            meta.egress_metadata.bd     : exact @name("egress_metadata.bd") ;
        }
        size = 32768;
        default_action = NoAction_77();
    }
    @name(".egress_filter_check") action _egress_filter_check() {
        meta.egress_filter_metadata.ifindex_check = meta.ingress_metadata.ifindex ^ meta.egress_metadata.ifindex;
        meta.egress_filter_metadata.bd = meta.ingress_metadata.outer_bd ^ meta.egress_metadata.outer_bd;
        meta.egress_filter_metadata.inner_bd = meta.ingress_metadata.bd ^ meta.egress_metadata.bd;
    }
    @name(".set_egress_filter_drop") action _set_egress_filter_drop() {
        mark_to_drop();
    }
    @name(".egress_filter") table _egress_filter_0 {
        actions = {
            _egress_filter_check();
            @defaultonly NoAction_78();
        }
        default_action = NoAction_78();
    }
    @name(".egress_filter_drop") table _egress_filter_drop_0 {
        actions = {
            _set_egress_filter_drop();
            @defaultonly NoAction_79();
        }
        default_action = NoAction_79();
    }
    @name(".nop") action _nop_16() {
    }
    @name(".drop_packet") action _drop_packet() {
        mark_to_drop();
    }
    @name(".egress_copy_to_cpu") action _egress_copy_to_cpu() {
        clone3<tuple_0>(CloneType.E2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
    }
    @name(".egress_redirect_to_cpu") action _egress_redirect_to_cpu() {
        clone3<tuple_0>(CloneType.E2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
        mark_to_drop();
    }
    @name(".egress_copy_to_cpu_with_reason") action _egress_copy_to_cpu_with_reason(bit<16> reason_code) {
        meta.fabric_metadata.reason_code = reason_code;
        clone3<tuple_0>(CloneType.E2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, reason_code, meta.ingress_metadata.ingress_port });
    }
    @name(".egress_redirect_to_cpu_with_reason") action _egress_redirect_to_cpu_with_reason(bit<16> reason_code) {
        meta.fabric_metadata.reason_code = reason_code;
        clone3<tuple_0>(CloneType.E2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, reason_code, meta.ingress_metadata.ingress_port });
        mark_to_drop();
    }
    @name(".egress_mirror_coal_hdr") action _egress_mirror_coal_hdr(bit<8> session_id, bit<8> id) {
    }
    @name(".egress_system_acl") table _egress_system_acl_0 {
        actions = {
            _nop_16();
            _drop_packet();
            _egress_copy_to_cpu();
            _egress_redirect_to_cpu();
            _egress_copy_to_cpu_with_reason();
            _egress_redirect_to_cpu_with_reason();
            _egress_mirror_coal_hdr();
            @defaultonly NoAction_80();
        }
        key = {
            meta.fabric_metadata.reason_code: ternary @name("fabric_metadata.reason_code") ;
            meta.eg_intr_md.egress_port     : ternary @name("eg_intr_md.egress_port") ;
            meta.eg_intr_md.deflection_flag : ternary @name("eg_intr_md.deflection_flag") ;
            meta.l3_metadata.l3_mtu_check   : ternary @name("l3_metadata.l3_mtu_check") ;
            meta.acl_metadata.acl_deny      : ternary @name("acl_metadata.acl_deny") ;
        }
        size = 128;
        default_action = NoAction_80();
    }
    apply {
        if (meta.eg_intr_md.deflection_flag == 1w0 && meta.egress_metadata.bypass == 1w0) {
            _plt_quantize_latency_0.apply();
            if (meta.int_metadata_i2e.sink == 1w0) 
                _plt_scramble_latency_0.apply();
            switch (egress_port_mapping.apply().action_run) {
                egress_port_type_normal_0: {
                    if (standard_metadata.instance_type == 32w0 || standard_metadata.instance_type == 32w5) 
                        _vlan_decap_0.apply();
                    if (meta.egress_metadata.routed == 1w0 || meta.l3_metadata.nexthop_index != 16w0) 
                        _rewrite_0.apply();
                    else 
                        ;
                    _egress_bd_map_0.apply();
                    _egress_bd_stats_2.apply();
                }
            }

            _egress_l4port_fields_0.apply();
            if (meta.int_metadata_i2e.sink == 1w1 && !(standard_metadata.instance_type != 32w0 && standard_metadata.instance_type != 32w5)) 
                ;
            else {
                _int_insert.apply();
                if (meta.int_metadata.hit_state != 2w0) {
                    if (meta.int_metadata.hit_state == 2w1) 
                        _int_transit_clear_byte_cnt.apply();
                    if (meta.int_metadata.insert_cnt != 8w0) {
                        _int_inst.apply();
                        _int_inst_0.apply();
                        _int_inst_1.apply();
                        _int_inst_2.apply();
                        _int_bos.apply();
                    }
                    _int_meta_header_update.apply();
                }
                if (meta.tunnel_metadata.egress_tunnel_type == 5w7 || meta.tunnel_metadata.egress_tunnel_type == 5w20) 
                    ;
                else 
                    if (meta.int_metadata_i2e.source == 1w0 && meta.int_metadata_i2e.sink == 1w0 && hdr.int_plt_header.isValid()) 
                        _int_plt_encode.apply();
            }
            if (meta.fabric_metadata.fabric_header_present == 1w0 && meta.tunnel_metadata.egress_tunnel_type != 5w0) {
                _tunnel_encap_process_outer_0.apply();
                _tunnel_rewrite_0.apply();
            }
            if (hdr.ipv4.isValid()) 
                _egress_ip_acl_0.apply();
            else 
                if (hdr.ipv6.isValid()) 
                    ;
                else 
                    _egress_mac_acl_0.apply();
            if (meta.int_metadata.insert_cnt != 8w0 || meta.int_metadata_i2e.sink == 1w1 && standard_metadata.instance_type == 32w2) 
                _int_outer_encap_0.apply();
            if (meta.egress_metadata.port_type == 2w0) 
                _egress_vlan_xlate_0.apply();
            _egress_filter_0.apply();
            if (meta.multicast_metadata.inner_replica == 1w1) 
                if (meta.tunnel_metadata.ingress_tunnel_type == 5w0 && meta.tunnel_metadata.egress_tunnel_type == 5w0 || meta.tunnel_metadata.ingress_tunnel_type != 5w0 && meta.tunnel_metadata.egress_tunnel_type != 5w0) 
                    _egress_filter_drop_0.apply();
        }
        if (meta.egress_metadata.bypass == 1w0) 
            _egress_system_acl_0.apply();
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
    @name("NoAction") action NoAction_81() {
    }
    @name("NoAction") action NoAction_82() {
    }
    @name("NoAction") action NoAction_83() {
    }
    @name("NoAction") action NoAction_84() {
    }
    @name("NoAction") action NoAction_85() {
    }
    @name("NoAction") action NoAction_86() {
    }
    @name("NoAction") action NoAction_87() {
    }
    @name("NoAction") action NoAction_88() {
    }
    @name("NoAction") action NoAction_89() {
    }
    @name("NoAction") action NoAction_90() {
    }
    @name("NoAction") action NoAction_91() {
    }
    @name("NoAction") action NoAction_92() {
    }
    @name("NoAction") action NoAction_93() {
    }
    @name("NoAction") action NoAction_94() {
    }
    @name("NoAction") action NoAction_95() {
    }
    @name("NoAction") action NoAction_96() {
    }
    @name("NoAction") action NoAction_97() {
    }
    @name("NoAction") action NoAction_98() {
    }
    @name("NoAction") action NoAction_99() {
    }
    @name("NoAction") action NoAction_100() {
    }
    @name("NoAction") action NoAction_101() {
    }
    @name("NoAction") action NoAction_102() {
    }
    @name("NoAction") action NoAction_103() {
    }
    @name("NoAction") action NoAction_104() {
    }
    @name("NoAction") action NoAction_105() {
    }
    @name("NoAction") action NoAction_106() {
    }
    @name("NoAction") action NoAction_107() {
    }
    @name("NoAction") action NoAction_108() {
    }
    @name("NoAction") action NoAction_109() {
    }
    @pa_atomic("ingress", "l3_metadata.lkp_ip_version") @pa_solitary("ingress", "l3_metadata.lkp_ip_version") @name(".rmac_hit") action rmac_hit_0() {
        meta.l3_metadata.rmac_hit = 1w1;
    }
    @name(".rmac_miss") action rmac_miss_0() {
        meta.l3_metadata.rmac_hit = 1w0;
    }
    @ternary(1) @name(".rmac") table rmac {
        actions = {
            rmac_hit_0();
            rmac_miss_0();
            @defaultonly NoAction_81();
        }
        key = {
            meta.l3_metadata.rmac_group: exact @name("l3_metadata.rmac_group") ;
            meta.l2_metadata.lkp_mac_da: exact @name("l2_metadata.lkp_mac_da") ;
        }
        size = 512;
        default_action = NoAction_81();
    }
    @name(".set_ifindex") action _set_ifindex(bit<16> ifindex, bit<2> port_type) {
        meta.ingress_metadata.ifindex = ifindex;
        meta.ingress_metadata.port_type = port_type;
    }
    @name(".set_ingress_port_properties") action _set_ingress_port_properties(bit<16> if_label, bit<9> exclusion_id, bit<5> qos_group, bit<5> tc_qos_group, bit<8> tc, bit<2> color, bit<1> trust_dscp, bit<1> trust_pcp) {
        meta.ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
        meta.acl_metadata.if_label = if_label;
        meta.qos_metadata.ingress_qos_group = qos_group;
        meta.qos_metadata.tc_qos_group = tc_qos_group;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
        meta.qos_metadata.trust_dscp = trust_dscp;
        meta.qos_metadata.trust_pcp = trust_pcp;
    }
    @name(".ingress_port_mapping") table _ingress_port_mapping_0 {
        actions = {
            _set_ifindex();
            @defaultonly NoAction_82();
        }
        key = {
            meta.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 288;
        default_action = NoAction_82();
    }
    @name(".ingress_port_properties") table _ingress_port_properties_0 {
        actions = {
            _set_ingress_port_properties();
            @defaultonly NoAction_83();
        }
        key = {
            meta.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 288;
        default_action = NoAction_83();
    }
    @name(".set_config_parameters") action _set_config_parameters(bit<1> enable_dod, bit<8> enable_flowlet, bit<32> switch_id) {
        meta.ig_intr_md_for_tm.deflect_on_drop = enable_dod;
        meta.i2e_metadata.ingress_tstamp = (bit<32>)meta.ig_intr_md.ingress_global_tstamp;
        meta.ingress_metadata.ingress_port = meta.ig_intr_md.ingress_port;
        meta.l2_metadata.same_if_check = meta.ingress_metadata.ifindex;
        meta.ig_intr_md_for_tm.ucast_egress_port = 9w511;
        meta.global_config_metadata.switch_id = switch_id;
    }
    @name(".switch_config_params") table _switch_config_params_0 {
        actions = {
            _set_config_parameters();
            @defaultonly NoAction_84();
        }
        size = 1;
        default_action = NoAction_84();
    }
    @name(".malformed_outer_ethernet_packet") action _malformed_outer_ethernet_packet(bit<8> drop_reason) {
        meta.ingress_metadata.drop_flag = 1w1;
        meta.ingress_metadata.drop_reason = drop_reason;
    }
    @name(".set_valid_outer_unicast_packet_untagged") action _set_valid_outer_unicast_packet_untagged() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name(".set_valid_outer_unicast_packet_single_tagged") action _set_valid_outer_unicast_packet_single_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[0].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_unicast_packet_double_tagged") action _set_valid_outer_unicast_packet_double_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[1].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_unicast_packet_qinq_tagged") action _set_valid_outer_unicast_packet_qinq_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_multicast_packet_untagged") action _set_valid_outer_multicast_packet_untagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name(".set_valid_outer_multicast_packet_single_tagged") action _set_valid_outer_multicast_packet_single_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[0].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_multicast_packet_double_tagged") action _set_valid_outer_multicast_packet_double_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[1].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_multicast_packet_qinq_tagged") action _set_valid_outer_multicast_packet_qinq_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_broadcast_packet_untagged") action _set_valid_outer_broadcast_packet_untagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name(".set_valid_outer_broadcast_packet_single_tagged") action _set_valid_outer_broadcast_packet_single_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[0].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_broadcast_packet_double_tagged") action _set_valid_outer_broadcast_packet_double_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[1].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_broadcast_packet_qinq_tagged") action _set_valid_outer_broadcast_packet_qinq_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".validate_outer_ethernet") table _validate_outer_ethernet_0 {
        actions = {
            _malformed_outer_ethernet_packet();
            _set_valid_outer_unicast_packet_untagged();
            _set_valid_outer_unicast_packet_single_tagged();
            _set_valid_outer_unicast_packet_double_tagged();
            _set_valid_outer_unicast_packet_qinq_tagged();
            _set_valid_outer_multicast_packet_untagged();
            _set_valid_outer_multicast_packet_single_tagged();
            _set_valid_outer_multicast_packet_double_tagged();
            _set_valid_outer_multicast_packet_qinq_tagged();
            _set_valid_outer_broadcast_packet_untagged();
            _set_valid_outer_broadcast_packet_single_tagged();
            _set_valid_outer_broadcast_packet_double_tagged();
            _set_valid_outer_broadcast_packet_qinq_tagged();
            @defaultonly NoAction_85();
        }
        key = {
            hdr.ethernet.srcAddr      : ternary @name("ethernet.srcAddr") ;
            hdr.ethernet.dstAddr      : ternary @name("ethernet.dstAddr") ;
            hdr.vlan_tag_[0].isValid(): exact @name("vlan_tag_[0].$valid$") ;
            hdr.vlan_tag_[1].isValid(): exact @name("vlan_tag_[1].$valid$") ;
        }
        size = 64;
        default_action = NoAction_85();
    }
    @name(".non_ip_lkp") action _non_ip_lkp() {
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.ig_intr_md_for_tm.mcast_grp_a = 16w0;
        meta.l2_metadata.non_ip_packet = 1w1;
    }
    @name(".ipv4_lkp") action _ipv4_lkp() {
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
    @name(".set_bd_properties") action _set_bd_properties(bit<14> bd, bit<14> vrf, bit<10> stp_group, bit<1> learning_enabled, bit<16> bd_label, bit<16> stats_idx, bit<10> rmac_group, bit<1> ipv4_unicast_enabled, bit<1> ipv6_unicast_enabled, bit<2> ipv4_urpf_mode, bit<2> ipv6_urpf_mode, bit<1> igmp_snooping_enabled, bit<1> mld_snooping_enabled, bit<1> ipv4_multicast_enabled, bit<1> ipv6_multicast_enabled, bit<14> mrpf_group, bit<14> ipv4_mcast_key, bit<1> ipv4_mcast_key_type, bit<14> ipv6_mcast_key, bit<1> ipv6_mcast_key_type, bit<16> ingress_rid) {
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
    @name(".port_vlan_mapping_miss") action _port_vlan_mapping_miss() {
        meta.l2_metadata.port_vlan_mapping_miss = 1w1;
    }
    @name(".adjust_lkp_fields") table _adjust_lkp_fields_0 {
        actions = {
            _non_ip_lkp();
            _ipv4_lkp();
            @defaultonly NoAction_86();
        }
        key = {
            hdr.ipv4.isValid(): exact @name("ipv4.$valid$") ;
            hdr.ipv6.isValid(): exact @name("ipv6.$valid$") ;
        }
        default_action = NoAction_86();
    }
    @name(".port_vlan_mapping") table _port_vlan_mapping_0 {
        actions = {
            _set_bd_properties();
            _port_vlan_mapping_miss();
            @defaultonly NoAction_87();
        }
        key = {
            meta.ingress_metadata.ifindex: exact @name("ingress_metadata.ifindex") ;
            hdr.vlan_tag_[0].isValid()   : exact @name("vlan_tag_[0].$valid$") ;
            hdr.vlan_tag_[0].vid         : exact @name("vlan_tag_[0].vid") ;
            hdr.vlan_tag_[1].isValid()   : exact @name("vlan_tag_[1].$valid$") ;
            hdr.vlan_tag_[1].vid         : exact @name("vlan_tag_[1].vid") ;
        }
        size = 32768;
        @name(".bd_action_profile") implementation = action_profile(32w16384);
        default_action = NoAction_87();
    }
    @name(".set_stp_state") action _set_stp_state(bit<3> stp_state) {
        meta.l2_metadata.stp_state = stp_state;
    }
    @ternary(1) @name(".spanning_tree") table _spanning_tree_0 {
        actions = {
            _set_stp_state();
            @defaultonly NoAction_88();
        }
        key = {
            meta.ingress_metadata.ifindex: exact @name("ingress_metadata.ifindex") ;
            meta.l2_metadata.stp_group   : exact @name("l2_metadata.stp_group") ;
        }
        size = 4096;
        default_action = NoAction_88();
    }
    @name(".nop") action _nop_17() {
    }
    @name(".nop") action _nop_18() {
    }
    @name(".terminate_cpu_packet") action _terminate_cpu_packet_0() {
        meta.ig_intr_md_for_tm.ucast_egress_port = (bit<9>)hdr.fabric_header.dstPortOrGroup;
        meta.egress_metadata.bypass = hdr.fabric_header_cpu.txBypass;
        hdr.ethernet.etherType = hdr.fabric_payload_header.etherType;
        hdr.fabric_header.setInvalid();
        hdr.fabric_header_cpu.setInvalid();
        hdr.fabric_payload_header.setInvalid();
    }
    @name(".switch_fabric_unicast_packet") action _switch_fabric_unicast_packet_0() {
        meta.fabric_metadata.fabric_header_present = 1w1;
        meta.fabric_metadata.dst_device = hdr.fabric_header.dstDevice;
        meta.fabric_metadata.dst_port = hdr.fabric_header.dstPortOrGroup;
    }
    @name(".terminate_fabric_unicast_packet") action _terminate_fabric_unicast_packet_0() {
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
    @name(".set_ingress_ifindex_properties") action _set_ingress_ifindex_properties_0(bit<9> l2xid) {
        meta.ig_intr_md_for_tm.level2_exclusion_id = l2xid;
    }
    @name(".non_ip_over_fabric") action _non_ip_over_fabric_0() {
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name(".ipv4_over_fabric") action _ipv4_over_fabric_0() {
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.ipv4_metadata.lkp_ipv4_sa = hdr.ipv4.srcAddr;
        meta.ipv4_metadata.lkp_ipv4_da = hdr.ipv4.dstAddr;
        meta.l3_metadata.lkp_ip_proto = hdr.ipv4.protocol;
        meta.l3_metadata.lkp_l4_sport = meta.l3_metadata.lkp_outer_l4_sport;
        meta.l3_metadata.lkp_l4_dport = meta.l3_metadata.lkp_outer_l4_dport;
    }
    @ternary(1) @name(".fabric_ingress_dst_lkp") table _fabric_ingress_dst_lkp {
        actions = {
            _nop_17();
            _terminate_cpu_packet_0();
            _switch_fabric_unicast_packet_0();
            _terminate_fabric_unicast_packet_0();
            @defaultonly NoAction_89();
        }
        key = {
            hdr.fabric_header.dstDevice: exact @name("fabric_header.dstDevice") ;
        }
        default_action = NoAction_89();
    }
    @name(".fabric_ingress_src_lkp") table _fabric_ingress_src_lkp {
        actions = {
            _nop_18();
            _set_ingress_ifindex_properties_0();
            @defaultonly NoAction_90();
        }
        key = {
            hdr.fabric_header_multicast.ingressIfindex: exact @name("fabric_header_multicast.ingressIfindex") ;
        }
        size = 1024;
        default_action = NoAction_90();
    }
    @name(".native_packet_over_fabric") table _native_packet_over_fabric {
        actions = {
            _non_ip_over_fabric_0();
            _ipv4_over_fabric_0();
            @defaultonly NoAction_91();
        }
        key = {
            hdr.ipv4.isValid(): exact @name("ipv4.$valid$") ;
            hdr.ipv6.isValid(): exact @name("ipv6.$valid$") ;
        }
        size = 1024;
        default_action = NoAction_91();
    }
    @name(".nop") action _nop_19() {
    }
    @name(".set_unicast") action _set_unicast() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
    }
    @name(".set_unicast_and_ipv6_src_is_link_local") action _set_unicast_and_ipv6_src_is_link_local() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.ipv6_metadata.ipv6_src_is_link_local = 1w1;
    }
    @name(".set_multicast") action _set_multicast() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.bd_stats_idx = meta.l2_metadata.bd_stats_idx + 16w1;
    }
    @name(".set_multicast_and_ipv6_src_is_link_local") action _set_multicast_and_ipv6_src_is_link_local() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.ipv6_metadata.ipv6_src_is_link_local = 1w1;
        meta.l2_metadata.bd_stats_idx = meta.l2_metadata.bd_stats_idx + 16w1;
    }
    @name(".set_broadcast") action _set_broadcast() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.bd_stats_idx = meta.l2_metadata.bd_stats_idx + 16w2;
    }
    @name(".set_malformed_packet") action _set_malformed_packet(bit<8> drop_reason) {
        meta.ingress_metadata.drop_flag = 1w1;
        meta.ingress_metadata.drop_reason = drop_reason;
    }
    @name(".validate_packet") table _validate_packet_0 {
        actions = {
            _nop_19();
            _set_unicast();
            _set_unicast_and_ipv6_src_is_link_local();
            _set_multicast();
            _set_multicast_and_ipv6_src_is_link_local();
            _set_broadcast();
            _set_malformed_packet();
            @defaultonly NoAction_92();
        }
        key = {
            meta.l2_metadata.lkp_mac_sa          : ternary @name("l2_metadata.lkp_mac_sa") ;
            meta.l2_metadata.lkp_mac_da          : ternary @name("l2_metadata.lkp_mac_da") ;
            meta.l3_metadata.lkp_ip_type         : ternary @name("l3_metadata.lkp_ip_type") ;
            meta.l3_metadata.lkp_ip_ttl          : ternary @name("l3_metadata.lkp_ip_ttl") ;
            meta.l3_metadata.lkp_ip_version      : ternary @name("l3_metadata.lkp_ip_version") ;
            meta.ipv4_metadata.lkp_ipv4_sa[31:24]: ternary @name("ipv4_metadata.lkp_ipv4_sa[31:24]") ;
        }
        size = 64;
        default_action = NoAction_92();
    }
    @name(".nop") action _nop_20() {
    }
    @name(".nop") action _nop_48() {
    }
    @name(".dmac_hit") action _dmac_hit(bit<16> ifindex) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.l2_metadata.same_if_check = meta.l2_metadata.same_if_check ^ ifindex;
    }
    @name(".dmac_multicast_hit") action _dmac_multicast_hit(bit<16> mc_index) {
        meta.ig_intr_md_for_tm.mcast_grp_b = mc_index;
        meta.fabric_metadata.dst_device = 8w127;
    }
    @name(".dmac_miss") action _dmac_miss() {
        meta.ingress_metadata.egress_ifindex = 16w65535;
        meta.fabric_metadata.dst_device = 8w127;
    }
    @name(".dmac_redirect_nexthop") action _dmac_redirect_nexthop(bit<16> nexthop_index) {
        meta.l2_metadata.l2_redirect = 1w1;
        meta.l2_metadata.l2_nexthop = nexthop_index;
        meta.l2_metadata.l2_nexthop_type = 2w0;
    }
    @name(".dmac_redirect_ecmp") action _dmac_redirect_ecmp(bit<16> ecmp_index) {
        meta.l2_metadata.l2_redirect = 1w1;
        meta.l2_metadata.l2_nexthop = ecmp_index;
        meta.l2_metadata.l2_nexthop_type = 2w1;
    }
    @name(".dmac_drop") action _dmac_drop() {
        mark_to_drop();
    }
    @name(".smac_miss") action _smac_miss() {
        meta.l2_metadata.l2_src_miss = 1w1;
    }
    @name(".smac_hit") action _smac_hit(bit<16> ifindex) {
        meta.l2_metadata.l2_src_move = meta.ingress_metadata.ifindex ^ ifindex;
    }
    @idletime_precision(2) @name(".dmac") table _dmac_0 {
        support_timeout = true;
        actions = {
            _nop_20();
            _dmac_hit();
            _dmac_multicast_hit();
            _dmac_miss();
            _dmac_redirect_nexthop();
            _dmac_redirect_ecmp();
            _dmac_drop();
            @defaultonly NoAction_93();
        }
        key = {
            meta.ingress_metadata.bd   : exact @name("ingress_metadata.bd") ;
            meta.l2_metadata.lkp_mac_da: exact @name("l2_metadata.lkp_mac_da") ;
        }
        size = 512000;
        default_action = NoAction_93();
    }
    @name(".smac") table _smac_0 {
        actions = {
            _nop_48();
            _smac_miss();
            _smac_hit();
            @defaultonly NoAction_94();
        }
        key = {
            meta.ingress_metadata.bd   : exact @name("ingress_metadata.bd") ;
            meta.l2_metadata.lkp_mac_sa: exact @name("l2_metadata.lkp_mac_sa") ;
        }
        size = 512000;
        default_action = NoAction_94();
    }
    @name(".nop") action _nop_49() {
    }
    @name(".acl_deny") action _acl_deny(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_permit") action _acl_permit(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_redirect_nexthop") action _acl_redirect_nexthop(bit<16> nexthop_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = nexthop_index;
        meta.acl_metadata.acl_nexthop_type = 2w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_redirect_ecmp") action _acl_redirect_ecmp(bit<16> ecmp_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = ecmp_index;
        meta.acl_metadata.acl_nexthop_type = 2w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".mac_acl") table _mac_acl_0 {
        actions = {
            _nop_49();
            _acl_deny();
            _acl_permit();
            _acl_redirect_nexthop();
            _acl_redirect_ecmp();
            @defaultonly NoAction_95();
        }
        key = {
            meta.acl_metadata.if_label   : ternary @name("acl_metadata.if_label") ;
            meta.acl_metadata.bd_label   : ternary @name("acl_metadata.bd_label") ;
            meta.l2_metadata.lkp_mac_sa  : ternary @name("l2_metadata.lkp_mac_sa") ;
            meta.l2_metadata.lkp_mac_da  : ternary @name("l2_metadata.lkp_mac_da") ;
            meta.l2_metadata.lkp_mac_type: ternary @name("l2_metadata.lkp_mac_type") ;
        }
        size = 128;
        default_action = NoAction_95();
    }
    @name(".nop") action _nop_50() {
    }
    @name(".acl_deny") action _acl_deny_0(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_permit") action _acl_permit_0(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_redirect_nexthop") action _acl_redirect_nexthop_0(bit<16> nexthop_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = nexthop_index;
        meta.acl_metadata.acl_nexthop_type = 2w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_redirect_ecmp") action _acl_redirect_ecmp_0(bit<16> ecmp_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = ecmp_index;
        meta.acl_metadata.acl_nexthop_type = 2w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".ip_acl") table _ip_acl_0 {
        actions = {
            _nop_50();
            _acl_deny_0();
            _acl_permit_0();
            _acl_redirect_nexthop_0();
            _acl_redirect_ecmp_0();
            @defaultonly NoAction_96();
        }
        key = {
            meta.acl_metadata.if_label                 : ternary @name("acl_metadata.if_label") ;
            meta.acl_metadata.bd_label                 : ternary @name("acl_metadata.bd_label") ;
            meta.ipv4_metadata.lkp_ipv4_sa             : ternary @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da             : ternary @name("ipv4_metadata.lkp_ipv4_da") ;
            meta.l3_metadata.lkp_ip_proto              : ternary @name("l3_metadata.lkp_ip_proto") ;
            meta.acl_metadata.ingress_src_port_range_id: exact @name("acl_metadata.ingress_src_port_range_id") ;
            meta.acl_metadata.ingress_dst_port_range_id: exact @name("acl_metadata.ingress_dst_port_range_id") ;
            hdr.tcp.flags                              : ternary @name("tcp.flags") ;
            meta.l3_metadata.lkp_ip_ttl                : ternary @name("l3_metadata.lkp_ip_ttl") ;
        }
        size = 128;
        default_action = NoAction_96();
    }
    @name(".compute_lkp_ipv4_hash") action _compute_lkp_ipv4_hash() {
        hash<bit<16>, bit<16>, tuple_1, bit<32>>(meta.hash_metadata.hash1, HashAlgorithm.crc16, 16w0, { meta.ipv4_metadata.lkp_ipv4_sa, meta.ipv4_metadata.lkp_ipv4_da, meta.l3_metadata.lkp_ip_proto, meta.l3_metadata.lkp_l4_sport, meta.l3_metadata.lkp_l4_dport }, 32w65536);
        hash<bit<16>, bit<16>, tuple_2, bit<32>>(meta.hash_metadata.hash2, HashAlgorithm.crc16, 16w0, { meta.l2_metadata.lkp_mac_sa, meta.l2_metadata.lkp_mac_da, meta.ipv4_metadata.lkp_ipv4_sa, meta.ipv4_metadata.lkp_ipv4_da, meta.l3_metadata.lkp_ip_proto, meta.l3_metadata.lkp_l4_sport, meta.l3_metadata.lkp_l4_dport }, 32w65536);
    }
    @name(".compute_lkp_non_ip_hash") action _compute_lkp_non_ip_hash() {
        hash<bit<16>, bit<16>, tuple_3, bit<32>>(meta.hash_metadata.hash2, HashAlgorithm.crc16, 16w0, { meta.ingress_metadata.ifindex, meta.l2_metadata.lkp_mac_sa, meta.l2_metadata.lkp_mac_da, meta.l2_metadata.lkp_mac_type }, 32w65536);
    }
    @name(".computed_two_hashes") action _computed_two_hashes() {
        meta.ig_intr_md_for_tm.level1_mcast_hash = (bit<13>)meta.hash_metadata.hash1;
        meta.ig_intr_md_for_tm.level2_mcast_hash = (bit<13>)meta.hash_metadata.hash2;
        meta.hash_metadata.entropy_hash = meta.hash_metadata.hash2;
    }
    @name(".computed_one_hash") action _computed_one_hash() {
        meta.hash_metadata.hash1 = meta.hash_metadata.hash2;
        meta.ig_intr_md_for_tm.level1_mcast_hash = (bit<13>)meta.hash_metadata.hash2;
        meta.ig_intr_md_for_tm.level2_mcast_hash = (bit<13>)meta.hash_metadata.hash2;
        meta.hash_metadata.entropy_hash = meta.hash_metadata.hash2;
    }
    @name(".compute_ipv4_hashes") table _compute_ipv4_hashes_0 {
        actions = {
            _compute_lkp_ipv4_hash();
            @defaultonly NoAction_97();
        }
        default_action = NoAction_97();
    }
    @name(".compute_non_ip_hashes") table _compute_non_ip_hashes_0 {
        actions = {
            _compute_lkp_non_ip_hash();
            @defaultonly NoAction_98();
        }
        default_action = NoAction_98();
    }
    @ternary(1) @name(".compute_other_hashes") table _compute_other_hashes_0 {
        actions = {
            _computed_two_hashes();
            _computed_one_hash();
            @defaultonly NoAction_99();
        }
        key = {
            meta.hash_metadata.hash1: exact @name("hash_metadata.hash1") ;
        }
        default_action = NoAction_99();
    }
    @min_width(32) @name(".ingress_bd_stats") counter(32w16384, CounterType.packets_and_bytes) _ingress_bd_stats_1;
    @name(".update_ingress_bd_stats") action _update_ingress_bd_stats() {
        _ingress_bd_stats_1.count((bit<32>)meta.l2_metadata.bd_stats_idx);
    }
    @name(".ingress_bd_stats") table _ingress_bd_stats_2 {
        actions = {
            _update_ingress_bd_stats();
            @defaultonly NoAction_100();
        }
        size = 16384;
        default_action = NoAction_100();
    }
    @min_width(16) @name(".acl_stats") counter(32w128, CounterType.packets_and_bytes) _acl_stats_1;
    @name(".acl_stats_update") action _acl_stats_update() {
        _acl_stats_1.count((bit<32>)meta.acl_metadata.acl_stats_index);
    }
    @name(".acl_stats") table _acl_stats_2 {
        actions = {
            _acl_stats_update();
            @defaultonly NoAction_101();
        }
        size = 128;
        default_action = NoAction_101();
    }
    @name(".nop") action _nop_51() {
    }
    @name(".set_l2_redirect_action") action _set_l2_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.l2_metadata.l2_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.l2_metadata.l2_nexthop_type;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name(".set_fib_redirect_action") action _set_fib_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.l3_metadata.fib_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.l3_metadata.fib_nexthop_type;
        meta.l3_metadata.routed = 1w1;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
        meta.fabric_metadata.reason_code = 16w0x217;
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name(".set_cpu_redirect_action") action _set_cpu_redirect_action() {
        meta.l3_metadata.routed = 1w0;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
        meta.ig_intr_md_for_tm.ucast_egress_port = 9w64;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name(".set_acl_redirect_action") action _set_acl_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.acl_metadata.acl_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.acl_metadata.acl_nexthop_type;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name(".set_racl_redirect_action") action _set_racl_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.acl_metadata.racl_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.acl_metadata.racl_nexthop_type;
        meta.l3_metadata.routed = 1w1;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name(".fwd_result") table _fwd_result_0 {
        actions = {
            _nop_51();
            _set_l2_redirect_action();
            _set_fib_redirect_action();
            _set_cpu_redirect_action();
            _set_acl_redirect_action();
            _set_racl_redirect_action();
            @defaultonly NoAction_102();
        }
        key = {
            meta.l2_metadata.l2_redirect                 : ternary @name("l2_metadata.l2_redirect") ;
            meta.acl_metadata.acl_redirect               : ternary @name("acl_metadata.acl_redirect") ;
            meta.acl_metadata.racl_redirect              : ternary @name("acl_metadata.racl_redirect") ;
            meta.l3_metadata.rmac_hit                    : ternary @name("l3_metadata.rmac_hit") ;
            meta.l3_metadata.fib_hit                     : ternary @name("l3_metadata.fib_hit") ;
            meta.nat_metadata.nat_hit                    : ternary @name("nat_metadata.nat_hit") ;
            meta.l2_metadata.lkp_pkt_type                : ternary @name("l2_metadata.lkp_pkt_type") ;
            meta.l3_metadata.lkp_ip_type                 : ternary @name("l3_metadata.lkp_ip_type") ;
            meta.multicast_metadata.igmp_snooping_enabled: ternary @name("multicast_metadata.igmp_snooping_enabled") ;
            meta.multicast_metadata.mld_snooping_enabled : ternary @name("multicast_metadata.mld_snooping_enabled") ;
            meta.multicast_metadata.mcast_route_hit      : ternary @name("multicast_metadata.mcast_route_hit") ;
            meta.multicast_metadata.mcast_bridge_hit     : ternary @name("multicast_metadata.mcast_bridge_hit") ;
            meta.multicast_metadata.mcast_rpf_group      : ternary @name("multicast_metadata.mcast_rpf_group") ;
            meta.multicast_metadata.mcast_mode           : ternary @name("multicast_metadata.mcast_mode") ;
        }
        size = 512;
        default_action = NoAction_102();
    }
    @name(".nop") action _nop_52() {
    }
    @name(".nop") action _nop_53() {
    }
    @name(".set_ecmp_nexthop_details") action _set_ecmp_nexthop_details(bit<16> ifindex, bit<14> bd, bit<16> nhop_index, bit<1> tunnel) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.l3_metadata.nexthop_index = nhop_index;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.l2_metadata.same_if_check = meta.l2_metadata.same_if_check ^ ifindex;
        meta.tunnel_metadata.tunnel_if_check = meta.tunnel_metadata.tunnel_terminate ^ tunnel;
        meta.ig_intr_md_for_tm.disable_ucast_cutthru = meta.l2_metadata.non_ip_packet & tunnel;
    }
    @name(".set_ecmp_nexthop_details_for_post_routed_flood") action _set_ecmp_nexthop_details_for_post_routed_flood(bit<14> bd, bit<16> uuc_mc_index, bit<16> nhop_index) {
        meta.ig_intr_md_for_tm.mcast_grp_b = uuc_mc_index;
        meta.l3_metadata.nexthop_index = nhop_index;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.fabric_metadata.dst_device = 8w127;
    }
    @name(".set_nexthop_details") action _set_nexthop_details(bit<16> ifindex, bit<14> bd, bit<1> tunnel) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.l2_metadata.same_if_check = meta.l2_metadata.same_if_check ^ ifindex;
        meta.tunnel_metadata.tunnel_if_check = meta.tunnel_metadata.tunnel_terminate ^ tunnel;
        meta.ig_intr_md_for_tm.disable_ucast_cutthru = meta.l2_metadata.non_ip_packet & tunnel;
    }
    @name(".set_nexthop_details_for_post_routed_flood") action _set_nexthop_details_for_post_routed_flood(bit<14> bd, bit<16> uuc_mc_index) {
        meta.ig_intr_md_for_tm.mcast_grp_b = uuc_mc_index;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.fabric_metadata.dst_device = 8w127;
    }
    @name(".ecmp_group") table _ecmp_group_0 {
        actions = {
            _nop_52();
            _set_ecmp_nexthop_details();
            _set_ecmp_nexthop_details_for_post_routed_flood();
            @defaultonly NoAction_103();
        }
        key = {
            meta.l3_metadata.nexthop_index: exact @name("l3_metadata.nexthop_index") ;
            meta.hash_metadata.hash1      : selector @name("hash_metadata.hash1") ;
        }
        size = 1024;
        @name(".ecmp_action_profile") @mode("fair") implementation = action_selector(HashAlgorithm.identity, 32w16384, 32w14);
        default_action = NoAction_103();
    }
    @name(".nexthop") table _nexthop_0 {
        actions = {
            _nop_53();
            _set_nexthop_details();
            _set_nexthop_details_for_post_routed_flood();
            @defaultonly NoAction_104();
        }
        key = {
            meta.l3_metadata.nexthop_index: exact @name("l3_metadata.nexthop_index") ;
        }
        size = 16384;
        default_action = NoAction_104();
    }
    @name(".set_lag_miss") action _set_lag_miss() {
    }
    @name(".set_lag_port") action _set_lag_port(bit<9> port) {
        meta.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".set_lag_remote_port") action _set_lag_remote_port(bit<8> device, bit<16> port) {
        meta.fabric_metadata.dst_device = device;
        meta.fabric_metadata.dst_port = port;
    }
    @name(".lag_group") table _lag_group_0 {
        actions = {
            _set_lag_miss();
            _set_lag_port();
            _set_lag_remote_port();
            @defaultonly NoAction_105();
        }
        key = {
            meta.ingress_metadata.egress_ifindex: exact @name("ingress_metadata.egress_ifindex") ;
            meta.hash_metadata.hash2            : selector @name("hash_metadata.hash2") ;
        }
        size = 1024;
        @name(".lag_action_profile") @mode("fair") implementation = action_selector(HashAlgorithm.identity, 32w1024, 32w14);
        default_action = NoAction_105();
    }
    @name(".nop") action _nop_54() {
    }
    @name(".generate_learn_notify") action _generate_learn_notify() {
        digest<mac_learn_digest>(32w1024, { meta.ingress_metadata.bd, meta.l2_metadata.lkp_mac_sa, meta.ingress_metadata.ifindex });
    }
    @name(".learn_notify") table _learn_notify_0 {
        actions = {
            _nop_54();
            _generate_learn_notify();
            @defaultonly NoAction_106();
        }
        key = {
            meta.l2_metadata.l2_src_miss: ternary @name("l2_metadata.l2_src_miss") ;
            meta.l2_metadata.l2_src_move: ternary @name("l2_metadata.l2_src_move") ;
            meta.l2_metadata.stp_state  : ternary @name("l2_metadata.stp_state") ;
        }
        size = 512;
        default_action = NoAction_106();
    }
    @name(".nop") action _nop_55() {
    }
    @name(".set_fabric_lag_port") action _set_fabric_lag_port(bit<9> port) {
        meta.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".fabric_lag") table _fabric_lag_0 {
        actions = {
            _nop_55();
            _set_fabric_lag_port();
            @defaultonly NoAction_107();
        }
        key = {
            meta.fabric_metadata.dst_device: exact @name("fabric_metadata.dst_device") ;
            meta.hash_metadata.hash2       : selector @name("hash_metadata.hash2") ;
        }
        @name(".fabric_lag_action_profile") @mode("fair") implementation = action_selector(HashAlgorithm.identity, 32w1024, 32w14);
        default_action = NoAction_107();
    }
    @name(".drop_stats") counter(32w256, CounterType.packets) _drop_stats_2;
    @name(".drop_stats_2") counter(32w256, CounterType.packets) _drop_stats_3;
    @name(".drop_stats_update") action _drop_stats_update() {
        _drop_stats_3.count((bit<32>)meta.ingress_metadata.drop_reason);
    }
    @name(".nop") action _nop_56() {
    }
    @name(".copy_to_cpu") action _copy_to_cpu(bit<5> qid, bit<8> meter_id, bit<3> icos) {
        meta.ig_intr_md_for_tm.qid = qid;
        meta.ig_intr_md_for_tm.ingress_cos = icos;
        clone3<tuple_0>(CloneType.I2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
    }
    @name(".redirect_to_cpu") action _redirect_to_cpu(bit<5> qid, bit<8> meter_id, bit<3> icos) {
        meta.ig_intr_md_for_tm.qid = qid;
        meta.ig_intr_md_for_tm.ingress_cos = icos;
        clone3<tuple_0>(CloneType.I2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
        mark_to_drop();
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name(".copy_to_cpu_with_reason") action _copy_to_cpu_with_reason(bit<16> reason_code, bit<5> qid, bit<8> meter_id, bit<3> icos) {
        meta.fabric_metadata.reason_code = reason_code;
        meta.ig_intr_md_for_tm.qid = qid;
        meta.ig_intr_md_for_tm.ingress_cos = icos;
        clone3<tuple_0>(CloneType.I2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, reason_code, meta.ingress_metadata.ingress_port });
    }
    @name(".redirect_to_cpu_with_reason") action _redirect_to_cpu_with_reason(bit<16> reason_code, bit<5> qid, bit<8> meter_id, bit<3> icos) {
        meta.fabric_metadata.reason_code = reason_code;
        meta.ig_intr_md_for_tm.qid = qid;
        meta.ig_intr_md_for_tm.ingress_cos = icos;
        clone3<tuple_0>(CloneType.I2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, reason_code, meta.ingress_metadata.ingress_port });
        mark_to_drop();
        meta.fabric_metadata.dst_device = 8w0;
    }
    @name(".drop_packet") action _drop_packet_0() {
        mark_to_drop();
    }
    @name(".drop_packet_with_reason") action _drop_packet_with_reason(bit<32> drop_reason) {
        _drop_stats_2.count(drop_reason);
        mark_to_drop();
    }
    @name(".drop_stats") table _drop_stats_4 {
        actions = {
            _drop_stats_update();
            @defaultonly NoAction_108();
        }
        size = 256;
        default_action = NoAction_108();
    }
    @name(".system_acl") table _system_acl_0 {
        actions = {
            _nop_56();
            _redirect_to_cpu();
            _redirect_to_cpu_with_reason();
            _copy_to_cpu();
            _copy_to_cpu_with_reason();
            _drop_packet_0();
            _drop_packet_with_reason();
            @defaultonly NoAction_109();
        }
        key = {
            meta.acl_metadata.if_label               : ternary @name("acl_metadata.if_label") ;
            meta.acl_metadata.bd_label               : ternary @name("acl_metadata.bd_label") ;
            meta.ingress_metadata.ifindex            : ternary @name("ingress_metadata.ifindex") ;
            meta.l2_metadata.lkp_mac_type            : ternary @name("l2_metadata.lkp_mac_type") ;
            meta.l2_metadata.port_vlan_mapping_miss  : ternary @name("l2_metadata.port_vlan_mapping_miss") ;
            meta.security_metadata.ipsg_check_fail   : ternary @name("security_metadata.ipsg_check_fail") ;
            meta.acl_metadata.acl_deny               : ternary @name("acl_metadata.acl_deny") ;
            meta.acl_metadata.racl_deny              : ternary @name("acl_metadata.racl_deny") ;
            meta.l3_metadata.urpf_check_fail         : ternary @name("l3_metadata.urpf_check_fail") ;
            meta.ingress_metadata.drop_flag          : ternary @name("ingress_metadata.drop_flag") ;
            meta.l3_metadata.l3_copy                 : ternary @name("l3_metadata.l3_copy") ;
            meta.l3_metadata.rmac_hit                : ternary @name("l3_metadata.rmac_hit") ;
            meta.l3_metadata.routed                  : ternary @name("l3_metadata.routed") ;
            meta.ipv6_metadata.ipv6_src_is_link_local: ternary @name("ipv6_metadata.ipv6_src_is_link_local") ;
            meta.l2_metadata.same_if_check           : ternary @name("l2_metadata.same_if_check") ;
            meta.tunnel_metadata.tunnel_if_check     : ternary @name("tunnel_metadata.tunnel_if_check") ;
            meta.l3_metadata.same_bd_check           : ternary @name("l3_metadata.same_bd_check") ;
            meta.l3_metadata.lkp_ip_ttl              : ternary @name("l3_metadata.lkp_ip_ttl") ;
            meta.l2_metadata.stp_state               : ternary @name("l2_metadata.stp_state") ;
            meta.ingress_metadata.control_frame      : ternary @name("ingress_metadata.control_frame") ;
            meta.ipv4_metadata.ipv4_unicast_enabled  : ternary @name("ipv4_metadata.ipv4_unicast_enabled") ;
            meta.ipv6_metadata.ipv6_unicast_enabled  : ternary @name("ipv6_metadata.ipv6_unicast_enabled") ;
            meta.ingress_metadata.egress_ifindex     : ternary @name("ingress_metadata.egress_ifindex") ;
            meta.fabric_metadata.reason_code         : ternary @name("fabric_metadata.reason_code") ;
        }
        size = 512;
        default_action = NoAction_109();
    }
    apply {
        if (meta.ig_intr_md.resubmit_flag == 1w0) 
            _ingress_port_mapping_0.apply();
        _ingress_port_properties_0.apply();
        _switch_config_params_0.apply();
        switch (_validate_outer_ethernet_0.apply().action_run) {
            default: {
            }
            _malformed_outer_ethernet_packet: {
            }
        }

        _port_vlan_mapping_0.apply();
        _adjust_lkp_fields_0.apply();
        if (meta.ingress_metadata.port_type == 2w0 && meta.l2_metadata.stp_group != 10w0) 
            _spanning_tree_0.apply();
        if (meta.ingress_metadata.port_type != 2w0) {
            _fabric_ingress_dst_lkp.apply();
            if (meta.ingress_metadata.port_type == 2w1) {
                if (hdr.fabric_header_multicast.isValid()) 
                    _fabric_ingress_src_lkp.apply();
                if (meta.tunnel_metadata.tunnel_terminate == 1w0) 
                    _native_packet_over_fabric.apply();
            }
        }
        if (meta.ingress_metadata.port_type != 2w1) {
            if ((meta.ingress_metadata.bypass_lookups & 16w0x40) == 16w0 && meta.ingress_metadata.drop_flag == 1w0) 
                _validate_packet_0.apply();
            if ((meta.ingress_metadata.bypass_lookups & 16w0x80) == 16w0 && meta.ingress_metadata.port_type == 2w0) 
                _smac_0.apply();
            if ((meta.ingress_metadata.bypass_lookups & 16w0x1) == 16w0) 
                _dmac_0.apply();
            if (meta.l3_metadata.lkp_ip_type == 2w0) 
                if ((meta.ingress_metadata.bypass_lookups & 16w0x4) == 16w0) 
                    _mac_acl_0.apply();
            else 
                if ((meta.ingress_metadata.bypass_lookups & 16w0x4) == 16w0) 
                    if (meta.l3_metadata.lkp_ip_type == 2w1) 
                        _ip_acl_0.apply();
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
            _compute_ipv4_hashes_0.apply();
        else 
            _compute_non_ip_hashes_0.apply();
        _compute_other_hashes_0.apply();
        if (meta.ingress_metadata.port_type != 2w1) {
            _ingress_bd_stats_2.apply();
            _acl_stats_2.apply();
            if (meta.ingress_metadata.bypass_lookups != 16w0xffff) 
                _fwd_result_0.apply();
            if (meta.nexthop_metadata.nexthop_type == 2w1) 
                _ecmp_group_0.apply();
            else 
                _nexthop_0.apply();
            if (meta.ingress_metadata.egress_ifindex == 16w65535) 
                ;
            else 
                _lag_group_0.apply();
            if (meta.l2_metadata.learning_enabled == 1w1) 
                _learn_notify_0.apply();
        }
        _fabric_lag_0.apply();
        if (meta.ingress_metadata.port_type != 2w1) 
            if ((meta.ingress_metadata.bypass_lookups & 16w0x20) == 16w0) {
                _system_acl_0.apply();
                if (meta.ingress_metadata.drop_flag == 1w1) 
                    _drop_stats_4.apply();
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
    bool tmp_11;
    bit<16> tmp_12;
    bool tmp_14;
    bit<16> tmp_15;
    @name("inner_ipv4_checksum") Checksum16() inner_ipv4_checksum;
    @name("ipv4_checksum") Checksum16() ipv4_checksum;
    apply {
        if (hdr.inner_ipv4.ihl != 4w5) 
            tmp_11 = false;
        else {
            tmp_12 = inner_ipv4_checksum.get<tuple_4>({ hdr.inner_ipv4.version, hdr.inner_ipv4.ihl, hdr.inner_ipv4.diffserv, hdr.inner_ipv4.totalLen, hdr.inner_ipv4.identification, hdr.inner_ipv4.flags, hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.ttl, hdr.inner_ipv4.protocol, hdr.inner_ipv4.srcAddr, hdr.inner_ipv4.dstAddr });
            tmp_11 = hdr.inner_ipv4.hdrChecksum == tmp_12;
        }
        if (tmp_11) 
            mark_to_drop();
        if (hdr.ipv4.ihl != 4w5) 
            tmp_14 = false;
        else {
            tmp_15 = ipv4_checksum.get<tuple_4>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr });
            tmp_14 = hdr.ipv4.hdrChecksum == tmp_15;
        }
        if (tmp_14) 
            mark_to_drop();
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    bit<16> tmp_17;
    bit<16> tmp_18;
    @name("inner_ipv4_checksum") Checksum16() inner_ipv4_checksum_2;
    @name("ipv4_checksum") Checksum16() ipv4_checksum_2;
    apply {
        if (hdr.inner_ipv4.ihl == 4w5) {
            tmp_17 = inner_ipv4_checksum_2.get<tuple_4>({ hdr.inner_ipv4.version, hdr.inner_ipv4.ihl, hdr.inner_ipv4.diffserv, hdr.inner_ipv4.totalLen, hdr.inner_ipv4.identification, hdr.inner_ipv4.flags, hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.ttl, hdr.inner_ipv4.protocol, hdr.inner_ipv4.srcAddr, hdr.inner_ipv4.dstAddr });
            hdr.inner_ipv4.hdrChecksum = tmp_17;
        }
        if (hdr.ipv4.ihl == 4w5) {
            tmp_18 = ipv4_checksum_2.get<tuple_4>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr });
            hdr.ipv4.hdrChecksum = tmp_18;
        }
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
