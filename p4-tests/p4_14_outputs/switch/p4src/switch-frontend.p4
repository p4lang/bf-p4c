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
    bit<16> port_lag_label;
    bit<16> bd_label;
    bit<14> acl_stats_index;
    bit<16> acl_partition_index;
    bit<16> egress_port_lag_label;
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
    bit<16> bd;
    bit<16> outer_bd;
    bit<48> mac_da;
    bit<1>  routed;
    bit<16> same_bd_check;
    bit<8>  drop_reason;
    bit<16> ifindex;
    bit<9>  egress_port;
}

struct fabric_metadata_t {
    bit<3>  packetType;
    bit<1>  fabric_header_present;
    bit<16> reason_code;
}

struct flowlet_metadata_t {
    bit<16> id;
    bit<1>  enable;
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
    bit<16> mirror_session_id;
}

struct ingress_metadata_t {
    bit<9>  ingress_port;
    bit<10> port_lag_index;
    bit<10> egress_port_lag_index;
    bit<16> ifindex;
    bit<16> egress_ifindex;
    bit<2>  port_type;
    bit<16> outer_bd;
    bit<16> bd;
    bit<1>  drop_flag;
    bit<8>  drop_reason;
    bit<1>  control_frame;
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
    bit<12> fib_partition_index;
    bit<16> same_bd_check;
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
    bit<16> ipv4_mcast_key;
    bit<1>  ipv6_mcast_key_type;
    bit<16> ipv6_mcast_key;
    bit<1>  outer_mcast_route_hit;
    bit<2>  outer_mcast_mode;
    bit<1>  mcast_route_hit;
    bit<1>  mcast_bridge_hit;
    bit<1>  ipv4_multicast_enabled;
    bit<1>  ipv6_multicast_enabled;
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
    bit<1>  nat_nexthop_type;
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
    bit<1> nexthop_type;
}

struct postcard_metadata_t {
    bit<1> report;
    bit<1> suppress_enb;
    bit<1> sample;
    bit<8> config_session_id;
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

struct telemetry_metadata_t {
    bit<32> flow_hash;
    bit<16> mirror_session_id;
    bit<32> quantized_latency;
    bit<16> local_digest;
    bit<2>  bfilter_output;
    bit<1>  eg_queue_alert;
    bit<1>  eg_queue_change;
    bit<1>  mirror_on_drop;
    bit<8>  dscp_report;
}

struct tunnel_metadata_t {
    bit<5>  ingress_tunnel_type;
    bit<24> tunnel_vni;
    bit<1>  mpls_enabled;
    bit<8>  mpls_ttl;
    bit<3>  mpls_exp;
    bit<1>  mpls_in_udp;
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
    bit<1>  src_vtep_hit;
    bit<16> vtep_ifindex;
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

header inner_l4_ports_t {
    bit<16> srcPort;
    bit<16> dstPort;
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
    @pa_solitary("ingress", "acl_metadata.port_lag_label") @pa_atomic("ingress", "acl_metadata.port_lag_label") @name("acl_metadata") 
    acl_metadata_t           acl_metadata;
    @name("egress_metadata") 
    egress_metadata_t        egress_metadata;
    @name("fabric_metadata") 
    fabric_metadata_t        fabric_metadata;
    @name("flowlet_metadata") 
    flowlet_metadata_t       flowlet_metadata;
    @name("global_config_metadata") 
    global_config_metadata_t global_config_metadata;
    @pa_atomic("ingress", "hash_metadata.hash1") @pa_solitary("ingress", "hash_metadata.hash1") @pa_atomic("ingress", "hash_metadata.hash2") @pa_solitary("ingress", "hash_metadata.hash2") @name("hash_metadata") 
    hash_metadata_t          hash_metadata;
    @name("i2e_metadata") 
    i2e_metadata_t           i2e_metadata;
    @pa_atomic("ingress", "ingress_metadata.port_type") @pa_solitary("ingress", "ingress_metadata.port_type") @pa_atomic("ingress", "ingress_metadata.port_lag_index") @pa_solitary("ingress", "ingress_metadata.port_lag_index") @pa_atomic("ingress", "ingress_metadata.ifindex") @pa_solitary("ingress", "ingress_metadata.ifindex") @pa_atomic("egress", "ingress_metadata.bd") @pa_solitary("egress", "ingress_metadata.bd") @name("ingress_metadata") 
    ingress_metadata_t       ingress_metadata;
    @name("intrinsic_metadata") 
    intrinsic_metadata_t     intrinsic_metadata;
    @name("ipv4_metadata") 
    ipv4_metadata_t          ipv4_metadata;
    @pa_mutually_exclusive("ingress", "ipv4_metadata.lkp_ipv4_sa", "ipv6_metadata.lkp_ipv6_sa") @pa_mutually_exclusive("ingress", "ipv4_metadata.lkp_ipv4_da", "ipv6_metadata.lkp_ipv6_da") @name("ipv6_metadata") 
    ipv6_metadata_t          ipv6_metadata;
    @pa_container_size("ingress", "l2_metadata.same_if_check", 16) @name("l2_metadata") 
    l2_metadata_t            l2_metadata;
    @pa_do_not_bridge("egress", "l3_metadata.lkp_dscp") @name("l3_metadata") 
    l3_metadata_t            l3_metadata;
    @pa_atomic("ingress", "meter_metadata.packet_color") @pa_solitary("ingress", "meter_metadata.packet_color") @pa_atomic("ingress", "meter_metadata.meter_index") @pa_solitary("ingress", "meter_metadata.meter_index") @name("meter_metadata") 
    meter_metadata_t         meter_metadata;
    @pa_solitary("ingress", "multicast_metadata.multicast_route_mc_index") @pa_atomic("ingress", "multicast_metadata.multicast_route_mc_index") @pa_solitary("ingress", "multicast_metadata.multicast_bridge_mc_index") @pa_atomic("ingress", "multicast_metadata.multicast_bridge_mc_index") @pa_container_size("ingress", "ig_intr_md_for_tm.mcast_grp_a", 16) @name("multicast_metadata") 
    multicast_metadata_t     multicast_metadata;
    @name("nat_metadata") 
    nat_metadata_t           nat_metadata;
    @name("nexthop_metadata") 
    nexthop_metadata_t       nexthop_metadata;
    @name("postcard_md") 
    postcard_metadata_t      postcard_md;
    @name("qos_metadata") 
    qos_metadata_t           qos_metadata;
    @name("security_metadata") 
    security_metadata_t      security_metadata;
    @name("telemetry_md") 
    telemetry_metadata_t     telemetry_md;
    @pa_container_size("ingress", "tunnel_metadata.tunnel_lookup", 8) @pa_container_size("ingress", "tunnel_metadata.tunnel_vni", 8) @pa_do_not_bridge("ingress", "tunnel_metadata.tunnel_index") @name("tunnel_metadata") 
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
    @name("inner_l4_ports") 
    inner_l4_ports_t                               inner_l4_ports;
    @name("inner_sctp") 
    sctp_t                                         inner_sctp;
    @pa_fragment("egress", "inner_tcp.checksum") @pa_fragment("egress", "inner_tcp.urgentPtr") @name("inner_tcp") 
    tcp_t                                          inner_tcp;
    @name("inner_udp") 
    udp_t                                          inner_udp;
    @pa_fragment("ingress", "ipv4.hdrChecksum") @pa_fragment("egress", "ipv4.hdrChecksum") @name("ipv4") 
    ipv4_t                                         ipv4;
    @overlay_subheader("egress", "inner_ipv6", "srcAddr", "dstAddr") @name("ipv6") 
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
    @name(".mpls") 
    mpls_t[3]                                      mpls;
    @name(".vlan_tag_") 
    vlan_tag_t[2]                                  vlan_tag_;
}
#include <tofino/stateful_alu.p4>

extern wred {
    void execute(out bit<32> destination, @optional in int index);
    wred();
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<4> tmp;
    bit<112> tmp_0;
    @name(".parse_arp_rarp") state parse_arp_rarp {
        transition parse_set_prio_med;
    }
    @name(".parse_eompls") state parse_eompls {
        meta.tunnel_metadata.ingress_tunnel_type = 5w6;
        transition parse_inner_ethernet;
    }
    @name(".parse_erspan_t3") state parse_erspan_t3 {
        packet.extract<erspan_header_t3_t_0>(hdr.erspan_t3_header);
        transition select(hdr.erspan_t3_header.ft_d_other) {
            16w0x0 &&& 16w0x7c01: parse_inner_ethernet;
            16w0x800 &&& 16w0x7c01: parse_inner_ipv4;
            default: accept;
        }
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
        meta.ipv6_metadata.lkp_ipv6_sa = hdr.inner_ipv6.srcAddr;
        meta.ipv6_metadata.lkp_ipv6_da = hdr.inner_ipv6.dstAddr;
        meta.l3_metadata.lkp_ip_proto = hdr.inner_ipv6.nextHdr;
        meta.l3_metadata.lkp_ip_ttl = hdr.inner_ipv6.hopLimit;
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
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
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
        tmp = packet.lookahead<bit<4>>();
        transition select(tmp[3:0]) {
            4w0x4: parse_mpls_inner_ipv4;
            4w0x6: parse_mpls_inner_ipv6;
            default: parse_eompls;
        }
    }
    @name(".parse_mpls_inner_ipv4") state parse_mpls_inner_ipv4 {
        meta.tunnel_metadata.ingress_tunnel_type = 5w6;
        transition parse_inner_ipv4;
    }
    @name(".parse_mpls_inner_ipv6") state parse_mpls_inner_ipv6 {
        meta.tunnel_metadata.ingress_tunnel_type = 5w6;
        transition parse_inner_ipv6;
    }
    @name(".parse_nvgre") state parse_nvgre {
        packet.extract<nvgre_t>(hdr.nvgre);
        meta.tunnel_metadata.ingress_tunnel_type = 5w5;
        meta.tunnel_metadata.tunnel_vni = hdr.nvgre.tni;
        transition parse_inner_ethernet;
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
        hdr.ig_prsr_ctrl.priority = 3w5;
        transition accept;
    }
    @name(".parse_set_prio_med") state parse_set_prio_med {
        hdr.ig_prsr_ctrl.priority = 3w3;
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
    @name(".parse_vxlan") state parse_vxlan {
        packet.extract<vxlan_t>(hdr.vxlan);
        meta.tunnel_metadata.ingress_tunnel_type = 5w1;
        meta.tunnel_metadata.tunnel_vni = hdr.vxlan.vni;
        transition parse_inner_ethernet;
    }
    @name(".start") state start {
        tmp_0 = packet.lookahead<bit<112>>();
        transition select(tmp_0[15:0]) {
            default: parse_ethernet;
        }
    }
}

control process_bfd_recirc(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_lag_fallback(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_telemetry_queue_alert(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_rid(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_3() {
    }
    @name(".outer_replica_from_rid") action outer_replica_from_rid_0(bit<16> bd, bit<14> dmac_idx, bit<14> tunnel_index, bit<5> tunnel_type, bit<4> header_count) {
        meta.egress_metadata.bd = bd;
        meta.multicast_metadata.replica = 1w1;
        meta.multicast_metadata.inner_replica = 1w0;
        meta.egress_metadata.routed = meta.l3_metadata.outer_routed;
        meta.egress_metadata.same_bd_check = bd ^ meta.ingress_metadata.outer_bd;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
        meta.tunnel_metadata.egress_tunnel_type = tunnel_type;
        meta.tunnel_metadata.egress_header_count = header_count;
        meta.tunnel_metadata.tunnel_dmac_index = dmac_idx;
    }
    @name(".inner_replica_from_rid") action inner_replica_from_rid_0(bit<16> bd, bit<14> dmac_idx, bit<14> tunnel_index, bit<5> tunnel_type, bit<4> header_count) {
        meta.egress_metadata.bd = bd;
        meta.multicast_metadata.replica = 1w1;
        meta.multicast_metadata.inner_replica = 1w1;
        meta.egress_metadata.routed = meta.l3_metadata.routed;
        meta.egress_metadata.same_bd_check = bd ^ meta.ingress_metadata.bd;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
        meta.tunnel_metadata.egress_tunnel_type = tunnel_type;
        meta.tunnel_metadata.egress_header_count = header_count;
        meta.tunnel_metadata.tunnel_dmac_index = dmac_idx;
    }
    @name(".unicast_replica_from_rid") action unicast_replica_from_rid_0(bit<16> bd, bit<14> dmac_idx) {
        meta.egress_metadata.outer_bd = bd;
        meta.tunnel_metadata.tunnel_dmac_index = dmac_idx;
    }
    @ignore_table_dependency("mirror") @name(".rid") table rid_0 {
        actions = {
            nop_3();
            outer_replica_from_rid_0();
            inner_replica_from_rid_0();
            unicast_replica_from_rid_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.eg_intr_md.egress_rid: exact @name("hdr.eg_intr_md.egress_rid") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        if (hdr.eg_intr_md.egress_rid != 16w0) 
            rid_0.apply();
    }
}

control process_egress_bfd_packet(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_mirroring(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_4() {
    }
    @name(".set_mirror_nhop") action set_mirror_nhop_0(bit<16> nhop_idx, bit<16> session_id) {
        meta.l3_metadata.nexthop_index = nhop_idx;
        meta.i2e_metadata.mirror_session_id = session_id;
    }
    @name(".set_mirror_bd") action set_mirror_bd_0(bit<16> bd, bit<16> session_id) {
        meta.egress_metadata.bd = bd;
        meta.i2e_metadata.mirror_session_id = session_id;
    }
    @ternary(1) @ignore_table_dependency("rid") @name(".mirror") table mirror_0 {
        actions = {
            nop_4();
            set_mirror_nhop_0();
            set_mirror_bd_0();
            @defaultonly NoAction();
        }
        key = {
            meta.i2e_metadata.mirror_session_id: exact @name("meta.i2e_metadata.mirror_session_id") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        mirror_0.apply();
    }
}

control process_bfd_mirror_to_cpu(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_replication(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_5() {
    }
    @name(".set_egress_ifindex_from_rid") action set_egress_ifindex_from_rid_0(bit<16> egress_ifindex) {
        meta.ingress_metadata.egress_ifindex = egress_ifindex;
    }
    @name(".set_replica_copy_bridged") action set_replica_copy_bridged_0() {
        meta.egress_metadata.routed = 1w0;
    }
    @name(".mcast_egress_ifindex") table mcast_egress_ifindex_0 {
        actions = {
            nop_5();
            set_egress_ifindex_from_rid_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.eg_intr_md.egress_rid: exact @name("hdr.eg_intr_md.egress_rid") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".replica_type") table replica_type_0 {
        actions = {
            nop_5();
            set_replica_copy_bridged_0();
            @defaultonly NoAction();
        }
        key = {
            meta.multicast_metadata.replica   : exact @name("meta.multicast_metadata.replica") ;
            meta.egress_metadata.same_bd_check: ternary @name("meta.egress_metadata.same_bd_check") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (hdr.eg_intr_md.egress_rid != 16w0) {
            mcast_egress_ifindex_0.apply();
            replica_type_0.apply();
        }
    }
}

control process_telemetry_local_report(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_vlan_decap(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_6() {
    }
    @name(".remove_vlan_single_tagged") action remove_vlan_single_tagged_0() {
        hdr.ethernet.etherType = hdr.vlan_tag_[0].etherType;
        hdr.vlan_tag_[0].setInvalid();
    }
    @name(".remove_vlan_double_tagged") action remove_vlan_double_tagged_0() {
        hdr.ethernet.etherType = hdr.vlan_tag_[1].etherType;
        hdr.vlan_tag_[0].setInvalid();
        hdr.vlan_tag_[1].setInvalid();
    }
    @ternary(1) @name(".vlan_decap") table vlan_decap_0 {
        actions = {
            nop_6();
            remove_vlan_single_tagged_0();
            remove_vlan_double_tagged_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.vlan_tag_[0].isValid(): exact @name("hdr..vlan_tag_[0].isValid()") ;
            hdr.vlan_tag_[1].isValid(): exact @name("hdr..vlan_tag_[1].isValid()") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        vlan_decap_0.apply();
    }
}

control process_tunnel_decap(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".decap_inner_udp") action decap_inner_udp_0() {
        hdr.udp = hdr.inner_udp;
        hdr.inner_udp.setInvalid();
    }
    @name(".decap_inner_tcp") action decap_inner_tcp_0() {
        hdr.tcp = hdr.inner_tcp;
        hdr.inner_tcp.setInvalid();
        hdr.udp.setInvalid();
    }
    @name(".decap_inner_icmp") action decap_inner_icmp_0() {
        hdr.icmp = hdr.inner_icmp;
        hdr.inner_icmp.setInvalid();
        hdr.udp.setInvalid();
    }
    @name(".decap_inner_unknown") action decap_inner_unknown_0() {
        hdr.udp.setInvalid();
    }
    @name(".decap_vxlan_inner_ipv4") action decap_vxlan_inner_ipv4_0() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.vxlan.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv4.setInvalid();
    }
    @name(".decap_vxlan_inner_non_ip") action decap_vxlan_inner_non_ip_0() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.vxlan.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
    }
    @name(".decap_genv_inner_ipv4") action decap_genv_inner_ipv4_0() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.genv.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv4.setInvalid();
    }
    @name(".decap_genv_inner_non_ip") action decap_genv_inner_non_ip_0() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.genv.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
    }
    @name(".decap_gre_inner_ipv4") action decap_gre_inner_ipv4_0() {
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.gre.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ipv4.setInvalid();
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".decap_gre_inner_non_ip") action decap_gre_inner_non_ip_0() {
        hdr.ethernet.etherType = hdr.gre.proto;
        hdr.gre.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
    }
    @name(".decap_ip_inner_ipv4") action decap_ip_inner_ipv4_0() {
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.ipv6.setInvalid();
        hdr.inner_ipv4.setInvalid();
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".decap_vxlan_inner_ipv6") action decap_vxlan_inner_ipv6_0() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.vxlan.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv6.setInvalid();
    }
    @name(".decap_genv_inner_ipv6") action decap_genv_inner_ipv6_0() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.genv.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv6.setInvalid();
    }
    @name(".decap_gre_inner_ipv6") action decap_gre_inner_ipv6_0() {
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.gre.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.inner_ipv6.setInvalid();
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".decap_ip_inner_ipv6") action decap_ip_inner_ipv6_0() {
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.ipv4.setInvalid();
        hdr.inner_ipv6.setInvalid();
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".decap_nvgre_inner_ipv4") action decap_nvgre_inner_ipv4_0() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.nvgre.setInvalid();
        hdr.gre.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv4.setInvalid();
    }
    @name(".decap_nvgre_inner_non_ip") action decap_nvgre_inner_non_ip_0() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.nvgre.setInvalid();
        hdr.gre.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
    }
    @name(".decap_nvgre_inner_ipv6") action decap_nvgre_inner_ipv6_0() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.nvgre.setInvalid();
        hdr.gre.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv6.setInvalid();
    }
    @name(".decap_mpls_inner_ipv4_pop1") action decap_mpls_inner_ipv4_pop1_0() {
        hdr.mpls[0].setInvalid();
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.inner_ipv4.setInvalid();
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".decap_mpls_inner_ethernet_ipv4_pop1") action decap_mpls_inner_ethernet_ipv4_pop1_0() {
        hdr.mpls[0].setInvalid();
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv4.setInvalid();
    }
    @name(".decap_mpls_inner_ethernet_non_ip_pop1") action decap_mpls_inner_ethernet_non_ip_pop1_0() {
        hdr.mpls[0].setInvalid();
        hdr.ethernet = hdr.inner_ethernet;
        hdr.inner_ethernet.setInvalid();
    }
    @name(".decap_mpls_inner_ipv4_pop2") action decap_mpls_inner_ipv4_pop2_0() {
        hdr.mpls[1].setInvalid();
        decap_mpls_inner_ipv4_pop1_0();
    }
    @name(".decap_mpls_inner_ethernet_ipv4_pop2") action decap_mpls_inner_ethernet_ipv4_pop2_0() {
        hdr.mpls[1].setInvalid();
        decap_mpls_inner_ethernet_ipv4_pop1_0();
    }
    @name(".decap_mpls_inner_ethernet_non_ip_pop2") action decap_mpls_inner_ethernet_non_ip_pop2_0() {
        hdr.mpls[1].setInvalid();
        decap_mpls_inner_ethernet_non_ip_pop1_0();
    }
    @name(".decap_mpls_inner_ipv4_pop3") action decap_mpls_inner_ipv4_pop3_0() {
        hdr.mpls[2].setInvalid();
        decap_mpls_inner_ipv4_pop2_0();
    }
    @name(".decap_mpls_inner_ethernet_ipv4_pop3") action decap_mpls_inner_ethernet_ipv4_pop3_0() {
        hdr.mpls[2].setInvalid();
        decap_mpls_inner_ethernet_ipv4_pop2_0();
    }
    @name(".decap_mpls_inner_ethernet_non_ip_pop3") action decap_mpls_inner_ethernet_non_ip_pop3_0() {
        hdr.mpls[2].setInvalid();
        decap_mpls_inner_ethernet_non_ip_pop2_0();
    }
    @name(".decap_mpls_inner_ipv6_pop1") action decap_mpls_inner_ipv6_pop1_0() {
        hdr.mpls[0].setInvalid();
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.inner_ipv6.setInvalid();
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".decap_mpls_inner_ethernet_ipv6_pop1") action decap_mpls_inner_ethernet_ipv6_pop1_0() {
        hdr.mpls[0].setInvalid();
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.inner_ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
    }
    @name(".decap_mpls_inner_ipv6_pop2") action decap_mpls_inner_ipv6_pop2_0() {
        hdr.mpls[1].setInvalid();
        decap_mpls_inner_ipv6_pop1_0();
    }
    @name(".decap_mpls_inner_ethernet_ipv6_pop2") action decap_mpls_inner_ethernet_ipv6_pop2_0() {
        hdr.mpls[1].setInvalid();
        decap_mpls_inner_ethernet_ipv6_pop1_0();
    }
    @name(".decap_mpls_inner_ipv6_pop3") action decap_mpls_inner_ipv6_pop3_0() {
        hdr.mpls[2].setInvalid();
        decap_mpls_inner_ipv6_pop2_0();
    }
    @name(".decap_mpls_inner_ethernet_ipv6_pop3") action decap_mpls_inner_ethernet_ipv6_pop3_0() {
        hdr.mpls[2].setInvalid();
        decap_mpls_inner_ethernet_ipv6_pop2_0();
    }
    @name(".tunnel_decap_process_inner") table tunnel_decap_process_inner_0 {
        actions = {
            decap_inner_udp_0();
            decap_inner_tcp_0();
            decap_inner_icmp_0();
            decap_inner_unknown_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.inner_tcp.isValid() : exact @name("hdr.inner_tcp.isValid()") ;
            hdr.inner_udp.isValid() : exact @name("hdr.inner_udp.isValid()") ;
            hdr.inner_icmp.isValid(): exact @name("hdr.inner_icmp.isValid()") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".tunnel_decap_process_outer") table tunnel_decap_process_outer_0 {
        actions = {
            decap_vxlan_inner_ipv4_0();
            decap_vxlan_inner_non_ip_0();
            decap_genv_inner_ipv4_0();
            decap_genv_inner_non_ip_0();
            decap_gre_inner_ipv4_0();
            decap_gre_inner_non_ip_0();
            decap_ip_inner_ipv4_0();
            decap_vxlan_inner_ipv6_0();
            decap_genv_inner_ipv6_0();
            decap_gre_inner_ipv6_0();
            decap_ip_inner_ipv6_0();
            decap_nvgre_inner_ipv4_0();
            decap_nvgre_inner_non_ip_0();
            decap_nvgre_inner_ipv6_0();
            decap_mpls_inner_ipv4_pop1_0();
            decap_mpls_inner_ethernet_ipv4_pop1_0();
            decap_mpls_inner_ethernet_non_ip_pop1_0();
            decap_mpls_inner_ipv4_pop2_0();
            decap_mpls_inner_ethernet_ipv4_pop2_0();
            decap_mpls_inner_ethernet_non_ip_pop2_0();
            decap_mpls_inner_ipv4_pop3_0();
            decap_mpls_inner_ethernet_ipv4_pop3_0();
            decap_mpls_inner_ethernet_non_ip_pop3_0();
            decap_mpls_inner_ipv6_pop1_0();
            decap_mpls_inner_ethernet_ipv6_pop1_0();
            decap_mpls_inner_ipv6_pop2_0();
            decap_mpls_inner_ethernet_ipv6_pop2_0();
            decap_mpls_inner_ipv6_pop3_0();
            decap_mpls_inner_ethernet_ipv6_pop3_0();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("meta.tunnel_metadata.ingress_tunnel_type") ;
            hdr.inner_ipv4.isValid()                : exact @name("hdr.inner_ipv4.isValid()") ;
            hdr.inner_ipv6.isValid()                : exact @name("hdr.inner_ipv6.isValid()") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        if (meta.tunnel_metadata.tunnel_terminate == 1w1) 
            if (meta.multicast_metadata.inner_replica == 1w1 || meta.multicast_metadata.replica == 1w0) {
                tunnel_decap_process_outer_0.apply();
                tunnel_decap_process_inner_0.apply();
            }
    }
}

control process_srv6_rewrite(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_rewrite(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_7() {
    }
    @name(".set_l2_rewrite") action set_l2_rewrite_0() {
        meta.egress_metadata.routed = 1w0;
        meta.egress_metadata.bd = meta.ingress_metadata.bd;
        meta.egress_metadata.outer_bd = meta.ingress_metadata.bd;
    }
    @name(".set_l2_rewrite_with_tunnel") action set_l2_rewrite_with_tunnel_0(bit<14> tunnel_index, bit<5> tunnel_type) {
        meta.egress_metadata.routed = 1w0;
        meta.egress_metadata.bd = meta.ingress_metadata.bd;
        meta.egress_metadata.outer_bd = meta.ingress_metadata.bd;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
        meta.tunnel_metadata.egress_tunnel_type = tunnel_type;
    }
    @name(".set_l3_rewrite") action set_l3_rewrite_0(bit<16> bd, bit<48> dmac) {
        meta.egress_metadata.routed = 1w1;
        meta.egress_metadata.mac_da = dmac;
        meta.egress_metadata.bd = bd;
        meta.egress_metadata.outer_bd = bd;
    }
    @name(".set_l3_rewrite_with_tunnel") action set_l3_rewrite_with_tunnel_0(bit<16> bd, bit<48> dmac, bit<14> tunnel_index, bit<5> tunnel_type) {
        meta.egress_metadata.routed = 1w1;
        meta.egress_metadata.mac_da = dmac;
        meta.egress_metadata.bd = bd;
        meta.egress_metadata.outer_bd = bd;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
        meta.tunnel_metadata.egress_tunnel_type = tunnel_type;
    }
    @name(".set_mpls_core") action set_mpls_core_0(bit<14> tunnel_index_0, bit<4> header_count_0) {
        meta.egress_metadata.routed = meta.l3_metadata.routed;
        meta.tunnel_metadata.tunnel_index = tunnel_index_0;
        meta.tunnel_metadata.egress_header_count = header_count_0;
    }
    @name(".set_mpls_push_rewrite_l2") action set_mpls_push_rewrite_l2_0(bit<14> tunnel_index, bit<4> header_count) {
        set_mpls_core_0(tunnel_index, header_count);
        meta.egress_metadata.bd = meta.ingress_metadata.bd;
        meta.tunnel_metadata.egress_tunnel_type = 5w13;
    }
    @name(".set_mpls_swap_push_rewrite_l3") action set_mpls_swap_push_rewrite_l3_0(bit<16> bd, bit<48> dmac, bit<20> label, bit<14> tunnel_index, bit<4> header_count) {
        hdr.mpls[0].label = label;
        set_mpls_core_0(tunnel_index, header_count);
        meta.egress_metadata.bd = bd;
        meta.egress_metadata.mac_da = dmac;
        meta.tunnel_metadata.egress_tunnel_type = 5w14;
    }
    @name(".set_mpls_push_rewrite_l3") action set_mpls_push_rewrite_l3_0(bit<16> bd, bit<48> dmac, bit<14> tunnel_index, bit<4> header_count) {
        set_mpls_core_0(tunnel_index, header_count);
        meta.egress_metadata.bd = bd;
        meta.egress_metadata.mac_da = dmac;
        meta.tunnel_metadata.egress_tunnel_type = 5w14;
    }
    @name(".rewrite_ipv4_multicast") action rewrite_ipv4_multicast_0() {
        hdr.ethernet.dstAddr[22:0] = ((bit<48>)hdr.ipv4.dstAddr)[22:0];
    }
    @name(".rewrite_ipv6_multicast") action rewrite_ipv6_multicast_0() {
    }
    @name(".rewrite") table rewrite_0 {
        actions = {
            nop_7();
            set_l2_rewrite_0();
            set_l2_rewrite_with_tunnel_0();
            set_l3_rewrite_0();
            set_l3_rewrite_with_tunnel_0();
            set_mpls_push_rewrite_l2_0();
            set_mpls_swap_push_rewrite_l3_0();
            set_mpls_push_rewrite_l3_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.nexthop_index: exact @name("meta.l3_metadata.nexthop_index") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".rewrite_multicast") table rewrite_multicast_0 {
        actions = {
            nop_7();
            rewrite_ipv4_multicast_0();
            rewrite_ipv6_multicast_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.isValid()       : exact @name("hdr.ipv4.isValid()") ;
            hdr.ipv6.isValid()       : exact @name("hdr.ipv6.isValid()") ;
            hdr.ipv4.dstAddr[31:28]  : ternary @name("hdr.ipv4.dstAddr[31:28]") ;
            hdr.ipv6.dstAddr[127:120]: ternary @name("hdr.ipv6.dstAddr[127:120]") ;
        }
        default_action = NoAction();
    }
    apply {
        if (meta.egress_metadata.routed != 1w0 && meta.l3_metadata.nexthop_index == 16w0) 
            rewrite_multicast_0.apply();
        else 
            rewrite_0.apply();
    }
}

control process_egress_bd(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_8() {
    }
    @name(".set_egress_bd_properties") action set_egress_bd_properties_0(bit<9> smac_idx, bit<8> mtu_index, bit<2> nat_mode, bit<16> bd_label) {
        meta.egress_metadata.smac_idx = smac_idx;
        meta.nat_metadata.egress_nat_mode = nat_mode;
        meta.acl_metadata.egress_bd_label = bd_label;
        meta.l3_metadata.mtu_index = mtu_index;
    }
    @name(".egress_bd_map") table egress_bd_map_0 {
        actions = {
            nop_8();
            set_egress_bd_properties_0();
            @defaultonly NoAction();
        }
        key = {
            meta.egress_metadata.bd: exact @name("meta.egress_metadata.bd") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        egress_bd_map_0.apply();
    }
}

control process_wred(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_egress_qos_map(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_mac_rewrite(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_9() {
    }
    @name(".ipv4_unicast_rewrite") action ipv4_unicast_rewrite_0() {
        hdr.ethernet.dstAddr = meta.egress_metadata.mac_da;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
    }
    @name(".ipv4_multicast_rewrite") action ipv4_multicast_rewrite_0() {
        hdr.ethernet.dstAddr = hdr.ethernet.dstAddr | 48w0x1005e000000;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
    }
    @name(".ipv6_unicast_rewrite") action ipv6_unicast_rewrite_0() {
        hdr.ethernet.dstAddr = meta.egress_metadata.mac_da;
        hdr.ipv6.hopLimit = hdr.ipv6.hopLimit + 8w255;
    }
    @name(".ipv6_multicast_rewrite") action ipv6_multicast_rewrite_0() {
        hdr.ethernet.dstAddr = hdr.ethernet.dstAddr | 48w0x333300000000;
        hdr.ipv6.hopLimit = hdr.ipv6.hopLimit + 8w255;
    }
    @name(".mpls_rewrite") action mpls_rewrite_0() {
        hdr.ethernet.dstAddr = meta.egress_metadata.mac_da;
        hdr.mpls[0].ttl = hdr.mpls[0].ttl + 8w255;
    }
    @name(".rewrite_smac") action rewrite_smac_0(bit<48> smac) {
        hdr.ethernet.srcAddr = smac;
    }
    @name(".l3_rewrite") table l3_rewrite_0 {
        actions = {
            nop_9();
            ipv4_unicast_rewrite_0();
            ipv4_multicast_rewrite_0();
            ipv6_unicast_rewrite_0();
            ipv6_multicast_rewrite_0();
            mpls_rewrite_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.isValid()       : exact @name("hdr.ipv4.isValid()") ;
            hdr.ipv6.isValid()       : exact @name("hdr.ipv6.isValid()") ;
            hdr.mpls[0].isValid()    : exact @name("hdr..mpls[0].isValid()") ;
            hdr.ipv4.dstAddr[31:28]  : ternary @name("hdr.ipv4.dstAddr[31:28]") ;
            hdr.ipv6.dstAddr[127:120]: ternary @name("hdr.ipv6.dstAddr[127:120]") ;
        }
        default_action = NoAction();
    }
    @name(".smac_rewrite") table smac_rewrite_0 {
        actions = {
            rewrite_smac_0();
            @defaultonly NoAction();
        }
        key = {
            meta.egress_metadata.smac_idx: exact @name("meta.egress_metadata.smac_idx") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.egress_metadata.routed == 1w1) {
            l3_rewrite_0.apply();
            smac_rewrite_0.apply();
        }
    }
}

control process_mtu(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".mtu_miss") action mtu_miss_0() {
        meta.l3_metadata.l3_mtu_check = 16w0xffff;
    }
    @name(".ipv4_mtu_check") action ipv4_mtu_check_0(bit<16> l3_mtu) {
        meta.l3_metadata.l3_mtu_check = l3_mtu - hdr.ipv4.totalLen;
    }
    @name(".ipv6_mtu_check") action ipv6_mtu_check_0(bit<16> l3_mtu) {
        meta.l3_metadata.l3_mtu_check = l3_mtu - hdr.ipv6.payloadLen;
    }
    @ternary(1) @name(".mtu") table mtu_0 {
        actions = {
            mtu_miss_0();
            ipv4_mtu_check_0();
            ipv6_mtu_check_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.mtu_index: exact @name("meta.l3_metadata.mtu_index") ;
            hdr.ipv4.isValid()        : exact @name("hdr.ipv4.isValid()") ;
            hdr.ipv6.isValid()        : exact @name("hdr.ipv6.isValid()") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        mtu_0.apply();
    }
}

control process_egress_nat(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_egress_bd_stats(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".egress_bd_stats") direct_counter(CounterType.packets_and_bytes) egress_bd_stats_1;
    @name(".nop") action nop_10() {
        egress_bd_stats_1.count();
    }
    @name(".egress_bd_stats") table egress_bd_stats_2 {
        actions = {
            nop_10();
            @defaultonly NoAction();
        }
        key = {
            meta.egress_metadata.bd      : exact @name("meta.egress_metadata.bd") ;
            meta.l2_metadata.lkp_pkt_type: exact @name("meta.l2_metadata.lkp_pkt_type") ;
        }
        size = 1024;
        @name(".egress_bd_stats") counters = direct_counter(CounterType.packets_and_bytes);
        default_action = NoAction();
    }
    apply {
        egress_bd_stats_2.apply();
    }
}

control process_egress_l4port(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_telemetry_insert(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_tunnel_encap(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_11() {
    }
    @name(".set_egress_tunnel_vni") action set_egress_tunnel_vni_0(bit<24> vnid) {
        meta.tunnel_metadata.vnid = vnid;
    }
    @name(".rewrite_tunnel_dmac") action rewrite_tunnel_dmac_0(bit<48> dmac) {
        hdr.ethernet.dstAddr = dmac;
    }
    @name(".rewrite_tunnel_ipv4_dst") action rewrite_tunnel_ipv4_dst_0(bit<32> ip) {
        hdr.ipv4.dstAddr = ip;
    }
    @name(".rewrite_tunnel_ipv6_dst") action rewrite_tunnel_ipv6_dst_0(bit<128> ip) {
        hdr.ipv6.dstAddr = ip;
    }
    @name(".inner_ipv4_udp_rewrite") action inner_ipv4_udp_rewrite_0() {
        hdr.inner_ipv4 = hdr.ipv4;
        hdr.inner_udp = hdr.udp;
        meta.egress_metadata.payload_length = hdr.ipv4.totalLen;
        hdr.udp.setInvalid();
        hdr.ipv4.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w4;
    }
    @name(".inner_ipv4_tcp_rewrite") action inner_ipv4_tcp_rewrite_0() {
        hdr.inner_ipv4 = hdr.ipv4;
        hdr.inner_tcp = hdr.tcp;
        meta.egress_metadata.payload_length = hdr.ipv4.totalLen;
        hdr.tcp.setInvalid();
        hdr.ipv4.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w4;
    }
    @name(".inner_ipv4_icmp_rewrite") action inner_ipv4_icmp_rewrite_0() {
        hdr.inner_ipv4 = hdr.ipv4;
        hdr.inner_icmp = hdr.icmp;
        meta.egress_metadata.payload_length = hdr.ipv4.totalLen;
        hdr.icmp.setInvalid();
        hdr.ipv4.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w4;
    }
    @name(".inner_ipv4_unknown_rewrite") action inner_ipv4_unknown_rewrite_0() {
        hdr.inner_ipv4 = hdr.ipv4;
        meta.egress_metadata.payload_length = hdr.ipv4.totalLen;
        hdr.ipv4.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w4;
    }
    @name(".inner_ipv6_udp_rewrite") action inner_ipv6_udp_rewrite_0() {
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_udp = hdr.udp;
        meta.egress_metadata.payload_length = hdr.ipv6.payloadLen + 16w40;
        hdr.ipv6.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w41;
    }
    @name(".inner_ipv6_tcp_rewrite") action inner_ipv6_tcp_rewrite_0() {
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_tcp = hdr.tcp;
        meta.egress_metadata.payload_length = hdr.ipv6.payloadLen + 16w40;
        hdr.tcp.setInvalid();
        hdr.ipv6.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w41;
    }
    @name(".inner_ipv6_icmp_rewrite") action inner_ipv6_icmp_rewrite_0() {
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_icmp = hdr.icmp;
        meta.egress_metadata.payload_length = hdr.ipv6.payloadLen + 16w40;
        hdr.icmp.setInvalid();
        hdr.ipv6.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w41;
    }
    @name(".inner_ipv6_unknown_rewrite") action inner_ipv6_unknown_rewrite_0() {
        hdr.inner_ipv6 = hdr.ipv6;
        meta.egress_metadata.payload_length = hdr.ipv6.payloadLen + 16w40;
        hdr.ipv6.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w41;
    }
    @name(".inner_non_ip_rewrite") action inner_non_ip_rewrite_0() {
        meta.egress_metadata.payload_length = hdr.eg_intr_md.pkt_length + 16w65522;
    }
    @name(".fabric_rewrite") action fabric_rewrite_0(bit<14> tunnel_index) {
        meta.tunnel_metadata.tunnel_index = tunnel_index;
    }
    @name(".f_insert_vxlan_header") action f_insert_vxlan_header_0() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.udp.setValid();
        hdr.vxlan.setValid();
        hdr.udp.srcPort = meta.hash_metadata.entropy_hash;
        hdr.udp.dstPort = 16w4789;
        meta.l3_metadata.egress_l4_sport = meta.hash_metadata.entropy_hash;
        meta.l3_metadata.egress_l4_dport = 16w4789;
        hdr.udp.checksum = 16w0;
        hdr.udp.length_ = meta.egress_metadata.payload_length + 16w30;
        hdr.vxlan.flags = 8w0x8;
        hdr.vxlan.reserved = 24w0;
        hdr.vxlan.vni = meta.tunnel_metadata.vnid;
        hdr.vxlan.reserved2 = 8w0;
    }
    @name(".f_insert_ipv4_header") action f_insert_ipv4_header_0(bit<8> proto_0) {
        hdr.ipv4.setValid();
        hdr.ipv4.protocol = proto_0;
        hdr.ipv4.ttl = 8w64;
        hdr.ipv4.version = 4w0x4;
        hdr.ipv4.ihl = 4w0x5;
        hdr.ipv4.diffserv = 8w0;
        hdr.ipv4.identification = 16w0;
    }
    @name(".ipv4_vxlan_rewrite") action ipv4_vxlan_rewrite_0() {
        f_insert_vxlan_header_0();
        f_insert_ipv4_header_0(8w17);
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w50;
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".f_insert_genv_header") action f_insert_genv_header_0() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.udp.setValid();
        hdr.genv.setValid();
        hdr.udp.srcPort = meta.hash_metadata.entropy_hash;
        hdr.udp.dstPort = 16w6081;
        meta.l3_metadata.egress_l4_sport = meta.hash_metadata.entropy_hash;
        meta.l3_metadata.egress_l4_dport = 16w6081;
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
    @name(".ipv4_genv_rewrite") action ipv4_genv_rewrite_0() {
        f_insert_genv_header_0();
        f_insert_ipv4_header_0(8w17);
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w50;
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".f_insert_nvgre_header") action f_insert_nvgre_header_0() {
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
    @name(".ipv4_nvgre_rewrite") action ipv4_nvgre_rewrite_0() {
        f_insert_nvgre_header_0();
        f_insert_ipv4_header_0(8w47);
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w42;
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".f_insert_gre_header") action f_insert_gre_header_0() {
        hdr.gre.setValid();
    }
    @name(".ipv4_gre_rewrite") action ipv4_gre_rewrite_0() {
        f_insert_gre_header_0();
        hdr.gre.proto = hdr.ethernet.etherType;
        f_insert_ipv4_header_0(8w47);
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w24;
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".ipv4_ip_rewrite") action ipv4_ip_rewrite_0() {
        f_insert_ipv4_header_0(meta.tunnel_metadata.inner_ip_proto);
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w20;
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".f_insert_ipv6_header") action f_insert_ipv6_header_0(bit<8> proto_1) {
        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w0x6;
        hdr.ipv6.nextHdr = proto_1;
        hdr.ipv6.hopLimit = 8w64;
        hdr.ipv6.trafficClass = 8w0;
        hdr.ipv6.flowLabel = 20w0;
    }
    @name(".ipv6_gre_rewrite") action ipv6_gre_rewrite_0() {
        f_insert_gre_header_0();
        hdr.gre.proto = hdr.ethernet.etherType;
        f_insert_ipv6_header_0(8w47);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w4;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".ipv6_ip_rewrite") action ipv6_ip_rewrite_0() {
        f_insert_ipv6_header_0(meta.tunnel_metadata.inner_ip_proto);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".ipv6_nvgre_rewrite") action ipv6_nvgre_rewrite_0() {
        f_insert_nvgre_header_0();
        f_insert_ipv6_header_0(8w47);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w22;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".ipv6_vxlan_rewrite") action ipv6_vxlan_rewrite_0() {
        f_insert_vxlan_header_0();
        f_insert_ipv6_header_0(8w17);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w30;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".ipv6_genv_rewrite") action ipv6_genv_rewrite_0() {
        f_insert_genv_header_0();
        f_insert_ipv6_header_0(8w17);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w30;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".mpls_ethernet_push1_rewrite") action mpls_ethernet_push1_rewrite_0() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.mpls.push_front(1);
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".mpls_ip_push1_rewrite") action mpls_ip_push1_rewrite_0() {
        hdr.mpls.push_front(1);
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".mpls_ethernet_push2_rewrite") action mpls_ethernet_push2_rewrite_0() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.mpls.push_front(2);
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".mpls_ip_push2_rewrite") action mpls_ip_push2_rewrite_0() {
        hdr.mpls.push_front(2);
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".mpls_ethernet_push3_rewrite") action mpls_ethernet_push3_rewrite_0() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.mpls.push_front(3);
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".mpls_ip_push3_rewrite") action mpls_ip_push3_rewrite_0() {
        hdr.mpls.push_front(3);
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".f_insert_erspan_common_header") action f_insert_erspan_common_header_0() {
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
        hdr.erspan_t3_header.sgt = 16w0;
        hdr.erspan_t3_header.vlan = 12w0;
    }
    @name(".f_insert_erspan_t3_header") action f_insert_erspan_t3_header_0() {
        f_insert_erspan_common_header_0();
        hdr.erspan_t3_header.ft_d_other = 16w0;
    }
    @name(".ipv4_erspan_t3_rewrite") action ipv4_erspan_t3_rewrite_0() {
        f_insert_erspan_t3_header_0();
        f_insert_ipv4_header_0(8w47);
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w50;
    }
    @name(".ipv6_erspan_t3_rewrite") action ipv6_erspan_t3_rewrite_0() {
        f_insert_erspan_t3_header_0();
        f_insert_ipv6_header_0(8w47);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w26;
    }
    @name(".tunnel_mtu_check") action tunnel_mtu_check_0(bit<16> l3_mtu) {
        meta.l3_metadata.l3_mtu_check = l3_mtu - meta.egress_metadata.payload_length;
    }
    @name(".tunnel_mtu_miss") action tunnel_mtu_miss_0() {
        meta.l3_metadata.l3_mtu_check = 16w0xffff;
    }
    @name(".cpu_rx_rewrite") action cpu_rx_rewrite_0() {
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
    @name(".set_ip_index") action set_ip_index_0(bit<9> sip_index_0, bit<14> dip_index_0) {
        meta.tunnel_metadata.tunnel_src_index = sip_index_0;
        meta.tunnel_metadata.tunnel_dst_index = dip_index_0;
    }
    @name(".set_tunnel_rewrite_details") action set_tunnel_rewrite_details_0(bit<9> smac_idx, bit<9> sip_index, bit<14> dip_index) {
        meta.tunnel_metadata.tunnel_smac_index = smac_idx;
        set_ip_index_0(sip_index, dip_index);
    }
    @name(".set_tunnel_rewrite_details_with_dmac") action set_tunnel_rewrite_details_with_dmac_0(bit<16> outer_bd, bit<9> smac_idx, bit<14> dmac_idx, bit<9> sip_index, bit<14> dip_index) {
        meta.egress_metadata.outer_bd = outer_bd;
        meta.tunnel_metadata.tunnel_smac_index = smac_idx;
        meta.tunnel_metadata.tunnel_dmac_index = dmac_idx;
        set_ip_index_0(sip_index, dip_index);
    }
    @name(".set_mpls_rewrite_push1_core") action set_mpls_rewrite_push1_core_0(bit<20> label1_0, bit<3> exp1_0, bit<8> ttl1_0, bit<9> smac_idx_0, bit<14> dmac_idx_0) {
        hdr.mpls[0].label = label1_0;
        hdr.mpls[0].exp = exp1_0;
        hdr.mpls[0].ttl = ttl1_0;
        meta.tunnel_metadata.tunnel_smac_index = smac_idx_0;
        meta.tunnel_metadata.tunnel_dmac_index = dmac_idx_0;
    }
    @name(".set_mpls_rewrite_push1") action set_mpls_rewrite_push1_0(bit<20> label1, bit<3> exp1, bit<8> ttl1, bit<9> smac_idx, bit<14> dmac_idx, bit<1> bos) {
        set_mpls_rewrite_push1_core_0(label1, exp1, ttl1, smac_idx, dmac_idx);
        hdr.mpls[0].bos = bos;
    }
    @name(".set_mpls_rewrite_push2_core") action set_mpls_rewrite_push2_core_0(bit<20> label1_1, bit<3> exp1_1, bit<8> ttl1_1, bit<20> label2_0, bit<3> exp2_0, bit<8> ttl2_0, bit<9> smac_idx_1, bit<14> dmac_idx_1) {
        hdr.mpls[1].label = label2_0;
        hdr.mpls[1].exp = exp2_0;
        hdr.mpls[1].ttl = ttl2_0;
        hdr.mpls[0].bos = 1w0x0;
        set_mpls_rewrite_push1_core_0(label1_1, exp1_1, ttl1_1, smac_idx_1, dmac_idx_1);
    }
    @name(".set_mpls_rewrite_push2") action set_mpls_rewrite_push2_0(bit<20> label1, bit<3> exp1, bit<8> ttl1, bit<20> label2, bit<3> exp2, bit<8> ttl2, bit<9> smac_idx, bit<14> dmac_idx, bit<1> bos) {
        set_mpls_rewrite_push2_core_0(label1, exp1, ttl1, label2, exp2, ttl2, smac_idx, dmac_idx);
        hdr.mpls[1].bos = bos;
    }
    @name(".set_mpls_rewrite_push3") action set_mpls_rewrite_push3_0(bit<20> label1, bit<3> exp1, bit<8> ttl1, bit<20> label2, bit<3> exp2, bit<8> ttl2, bit<20> label3, bit<3> exp3, bit<8> ttl3, bit<9> smac_idx, bit<14> dmac_idx, bit<1> bos) {
        hdr.mpls[2].label = label3;
        hdr.mpls[2].exp = exp3;
        hdr.mpls[2].ttl = ttl3;
        hdr.mpls[2].bos = bos;
        hdr.mpls[1].bos = 1w0x0;
        set_mpls_rewrite_push2_core_0(label1, exp1, ttl1, label2, exp2, ttl2, smac_idx, dmac_idx);
    }
    @name(".rewrite_tunnel_smac") action rewrite_tunnel_smac_0(bit<48> smac) {
        hdr.ethernet.srcAddr = smac;
    }
    @name(".rewrite_tunnel_ipv4_src") action rewrite_tunnel_ipv4_src_0(bit<32> ip) {
        hdr.ipv4.srcAddr = ip;
    }
    @name(".rewrite_tunnel_ipv6_src") action rewrite_tunnel_ipv6_src_0(bit<128> ip) {
        hdr.ipv6.srcAddr = ip;
    }
    @name(".egress_vni") table egress_vni_0 {
        actions = {
            nop_11();
            set_egress_tunnel_vni_0();
            @defaultonly NoAction();
        }
        key = {
            meta.egress_metadata.bd                : exact @name("meta.egress_metadata.bd") ;
            meta.tunnel_metadata.egress_tunnel_type: exact @name("meta.tunnel_metadata.egress_tunnel_type") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".tunnel_dmac_rewrite") table tunnel_dmac_rewrite_0 {
        actions = {
            nop_11();
            rewrite_tunnel_dmac_0();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.tunnel_dmac_index: exact @name("meta.tunnel_metadata.tunnel_dmac_index") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".tunnel_dst_rewrite") table tunnel_dst_rewrite_0 {
        actions = {
            nop_11();
            rewrite_tunnel_ipv4_dst_0();
            rewrite_tunnel_ipv6_dst_0();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.tunnel_dst_index: exact @name("meta.tunnel_metadata.tunnel_dst_index") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".tunnel_encap_process_inner") table tunnel_encap_process_inner_0 {
        actions = {
            inner_ipv4_udp_rewrite_0();
            inner_ipv4_tcp_rewrite_0();
            inner_ipv4_icmp_rewrite_0();
            inner_ipv4_unknown_rewrite_0();
            inner_ipv6_udp_rewrite_0();
            inner_ipv6_tcp_rewrite_0();
            inner_ipv6_icmp_rewrite_0();
            inner_ipv6_unknown_rewrite_0();
            inner_non_ip_rewrite_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.isValid(): exact @name("hdr.ipv4.isValid()") ;
            hdr.ipv6.isValid(): exact @name("hdr.ipv6.isValid()") ;
            hdr.tcp.isValid() : exact @name("hdr.tcp.isValid()") ;
            hdr.udp.isValid() : exact @name("hdr.udp.isValid()") ;
            hdr.icmp.isValid(): exact @name("hdr.icmp.isValid()") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @ternary(1) @ignore_table_dependency("int_sink_local_report") @ignore_table_dependency("int_outer_encap") @ignore_table_dependency("telemetry_postcard_e2e") @name(".tunnel_encap_process_outer") table tunnel_encap_process_outer_0 {
        actions = {
            nop_11();
            fabric_rewrite_0();
            ipv4_vxlan_rewrite_0();
            ipv4_genv_rewrite_0();
            ipv4_nvgre_rewrite_0();
            ipv4_gre_rewrite_0();
            ipv4_ip_rewrite_0();
            ipv6_gre_rewrite_0();
            ipv6_ip_rewrite_0();
            ipv6_nvgre_rewrite_0();
            ipv6_vxlan_rewrite_0();
            ipv6_genv_rewrite_0();
            mpls_ethernet_push1_rewrite_0();
            mpls_ip_push1_rewrite_0();
            mpls_ethernet_push2_rewrite_0();
            mpls_ip_push2_rewrite_0();
            mpls_ethernet_push3_rewrite_0();
            mpls_ip_push3_rewrite_0();
            ipv4_erspan_t3_rewrite_0();
            ipv6_erspan_t3_rewrite_0();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.egress_tunnel_type : exact @name("meta.tunnel_metadata.egress_tunnel_type") ;
            meta.tunnel_metadata.egress_header_count: exact @name("meta.tunnel_metadata.egress_header_count") ;
            meta.multicast_metadata.replica         : exact @name("meta.multicast_metadata.replica") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".tunnel_mtu") table tunnel_mtu_0 {
        actions = {
            tunnel_mtu_check_0();
            tunnel_mtu_miss_0();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.tunnel_index: exact @name("meta.tunnel_metadata.tunnel_index") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".tunnel_rewrite") table tunnel_rewrite_0 {
        actions = {
            nop_11();
            cpu_rx_rewrite_0();
            set_tunnel_rewrite_details_0();
            set_tunnel_rewrite_details_with_dmac_0();
            set_mpls_rewrite_push1_0();
            set_mpls_rewrite_push2_0();
            set_mpls_rewrite_push3_0();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.tunnel_index: exact @name("meta.tunnel_metadata.tunnel_index") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".tunnel_smac_rewrite") table tunnel_smac_rewrite_0 {
        actions = {
            nop_11();
            rewrite_tunnel_smac_0();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.tunnel_smac_index: exact @name("meta.tunnel_metadata.tunnel_smac_index") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".tunnel_src_rewrite") table tunnel_src_rewrite_0 {
        actions = {
            nop_11();
            rewrite_tunnel_ipv4_src_0();
            rewrite_tunnel_ipv6_src_0();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.tunnel_src_index: exact @name("meta.tunnel_metadata.tunnel_src_index") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        if (meta.fabric_metadata.fabric_header_present == 1w0 && meta.tunnel_metadata.egress_tunnel_type != 5w0) {
            egress_vni_0.apply();
            if (meta.tunnel_metadata.egress_tunnel_type != 5w15 && meta.tunnel_metadata.egress_tunnel_type != 5w16) 
                tunnel_encap_process_inner_0.apply();
            tunnel_encap_process_outer_0.apply();
            tunnel_rewrite_0.apply();
            tunnel_mtu_0.apply();
            tunnel_src_rewrite_0.apply();
            tunnel_dst_rewrite_0.apply();
            tunnel_smac_rewrite_0.apply();
            tunnel_dmac_rewrite_0.apply();
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

control process_telemetry_report_encap(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_telemetry_outer_encap(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_vlan_xlate(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_egress_if_params_untagged") action set_egress_if_params_untagged_0(bit<8> egress_if_label) {
    }
    @name(".set_egress_if_params_tagged") action set_egress_if_params_tagged_0(bit<12> vlan_id, bit<8> egress_if_label) {
        hdr.vlan_tag_[0].setValid();
        hdr.vlan_tag_[0].etherType = hdr.ethernet.etherType;
        hdr.vlan_tag_[0].vid = vlan_id;
        hdr.ethernet.etherType = 16w0x8100;
    }
    @name(".set_egress_if_params_double_tagged") action set_egress_if_params_double_tagged_0(bit<12> s_tag, bit<12> c_tag, bit<8> egress_if_label) {
        hdr.vlan_tag_[1].setValid();
        hdr.vlan_tag_[0].setValid();
        hdr.vlan_tag_[1].etherType = hdr.ethernet.etherType;
        hdr.vlan_tag_[1].vid = c_tag;
        hdr.vlan_tag_[0].etherType = 16w0x8100;
        hdr.vlan_tag_[0].vid = s_tag;
        hdr.ethernet.etherType = 16w0x9100;
    }
    @name(".egress_vlan_xlate") table egress_vlan_xlate_0 {
        actions = {
            set_egress_if_params_untagged_0();
            set_egress_if_params_tagged_0();
            set_egress_if_params_double_tagged_0();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.egress_ifindex: exact @name("meta.ingress_metadata.egress_ifindex") ;
            meta.egress_metadata.bd             : exact @name("meta.egress_metadata.bd") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        egress_vlan_xlate_0.apply();
    }
}

control process_egress_filter(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_egress_system_acl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_12() {
    }
    @name(".drop_packet") action drop_packet_0() {
        mark_to_drop();
    }
    @name(".egress_copy_to_cpu") action egress_copy_to_cpu_0() {
        clone3<tuple<bit<16>, bit<16>, bit<16>, bit<9>>>(CloneType.E2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
    }
    @name(".egress_redirect_to_cpu") action egress_redirect_to_cpu_0() {
        egress_copy_to_cpu_0();
        mark_to_drop();
    }
    @name(".egress_copy_to_cpu_with_reason") action egress_copy_to_cpu_with_reason_0(bit<16> reason_code) {
        meta.fabric_metadata.reason_code = reason_code;
        egress_copy_to_cpu_0();
    }
    @name(".egress_redirect_to_cpu_with_reason") action egress_redirect_to_cpu_with_reason_0(bit<16> reason_code) {
        egress_copy_to_cpu_with_reason_0(reason_code);
        mark_to_drop();
    }
    @name(".egress_mirror_coal_hdr") action egress_mirror_coal_hdr_0(bit<8> session_id, bit<8> id) {
    }
    @name(".egress_mirror") action egress_mirror_0(bit<32> session_id) {
        meta.i2e_metadata.mirror_session_id = (bit<16>)session_id;
        clone3<tuple<bit<32>, bit<16>>>(CloneType.E2E, session_id, { meta.i2e_metadata.ingress_tstamp, meta.i2e_metadata.mirror_session_id });
    }
    @name(".egress_mirror_and_drop") action egress_mirror_and_drop_0(bit<8> reason_code) {
        mark_to_drop();
    }
    @name(".egress_system_acl") table egress_system_acl_0 {
        actions = {
            nop_12();
            drop_packet_0();
            egress_copy_to_cpu_0();
            egress_redirect_to_cpu_0();
            egress_copy_to_cpu_with_reason_0();
            egress_redirect_to_cpu_with_reason_0();
            egress_mirror_coal_hdr_0();
            egress_mirror_0();
            egress_mirror_and_drop_0();
            @defaultonly NoAction();
        }
        key = {
            meta.fabric_metadata.reason_code: ternary @name("meta.fabric_metadata.reason_code") ;
            hdr.eg_intr_md.egress_port      : ternary @name("hdr.eg_intr_md.egress_port") ;
            hdr.eg_intr_md.deflection_flag  : ternary @name("hdr.eg_intr_md.deflection_flag") ;
            meta.l3_metadata.l3_mtu_check   : ternary @name("meta.l3_metadata.l3_mtu_check") ;
            meta.acl_metadata.acl_deny      : ternary @name("meta.acl_metadata.acl_deny") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.egress_metadata.bypass == 1w0) 
            egress_system_acl_0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".egress_port_type_normal") action egress_port_type_normal_0(bit<5> qos_group, bit<16> port_lag_label) {
        meta.egress_metadata.port_type = 2w0;
        meta.qos_metadata.egress_qos_group = qos_group;
        meta.l3_metadata.l3_mtu_check = 16w0xffff;
        meta.acl_metadata.egress_port_lag_label = port_lag_label;
    }
    @name(".egress_port_type_fabric") action egress_port_type_fabric_0() {
        meta.egress_metadata.port_type = 2w1;
        meta.tunnel_metadata.egress_tunnel_type = 5w15;
        meta.l3_metadata.l3_mtu_check = 16w0xffff;
    }
    @name(".egress_port_type_cpu") action egress_port_type_cpu_0() {
        meta.egress_metadata.port_type = 2w2;
        meta.tunnel_metadata.egress_tunnel_type = 5w16;
        meta.l3_metadata.l3_mtu_check = 16w0xffff;
    }
    @ternary(1) @name(".egress_port_mapping") table egress_port_mapping_0 {
        actions = {
            egress_port_type_normal_0();
            egress_port_type_fabric_0();
            egress_port_type_cpu_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.eg_intr_md.egress_port: exact @name("hdr.eg_intr_md.egress_port") ;
        }
        size = 288;
        default_action = NoAction();
    }
    @name(".process_bfd_recirc") process_bfd_recirc() process_bfd_recirc_1;
    @name(".process_lag_fallback") process_lag_fallback() process_lag_fallback_1;
    @name(".process_telemetry_queue_alert") process_telemetry_queue_alert() process_telemetry_queue_alert_1;
    @name(".process_rid") process_rid() process_rid_1;
    @name(".process_egress_bfd_packet") process_egress_bfd_packet() process_egress_bfd_packet_1;
    @name(".process_mirroring") process_mirroring() process_mirroring_1;
    @name(".process_bfd_mirror_to_cpu") process_bfd_mirror_to_cpu() process_bfd_mirror_to_cpu_1;
    @name(".process_replication") process_replication() process_replication_1;
    @name(".process_telemetry_local_report") process_telemetry_local_report() process_telemetry_local_report_1;
    @name(".process_vlan_decap") process_vlan_decap() process_vlan_decap_1;
    @name(".process_tunnel_decap") process_tunnel_decap() process_tunnel_decap_1;
    @name(".process_srv6_rewrite") process_srv6_rewrite() process_srv6_rewrite_1;
    @name(".process_rewrite") process_rewrite() process_rewrite_1;
    @name(".process_egress_bd") process_egress_bd() process_egress_bd_1;
    @name(".process_wred") process_wred() process_wred_1;
    @name(".process_egress_qos_map") process_egress_qos_map() process_egress_qos_map_1;
    @name(".process_mac_rewrite") process_mac_rewrite() process_mac_rewrite_1;
    @name(".process_mtu") process_mtu() process_mtu_1;
    @name(".process_egress_nat") process_egress_nat() process_egress_nat_1;
    @name(".process_egress_bd_stats") process_egress_bd_stats() process_egress_bd_stats_1;
    @name(".process_egress_l4port") process_egress_l4port() process_egress_l4port_1;
    @name(".process_telemetry_insert") process_telemetry_insert() process_telemetry_insert_1;
    @name(".process_tunnel_encap") process_tunnel_encap() process_tunnel_encap_1;
    @name(".process_l4_checksum") process_l4_checksum() process_l4_checksum_1;
    @name(".process_egress_acl") process_egress_acl() process_egress_acl_1;
    @name(".process_telemetry_report_encap") process_telemetry_report_encap() process_telemetry_report_encap_1;
    @name(".process_telemetry_outer_encap") process_telemetry_outer_encap() process_telemetry_outer_encap_1;
    @name(".process_vlan_xlate") process_vlan_xlate() process_vlan_xlate_1;
    @name(".process_egress_filter") process_egress_filter() process_egress_filter_1;
    @name(".process_egress_system_acl") process_egress_system_acl() process_egress_system_acl_1;
    apply {
        process_bfd_recirc_1.apply(hdr, meta, standard_metadata);
        process_lag_fallback_1.apply(hdr, meta, standard_metadata);
        if (hdr.eg_intr_md.deflection_flag == 1w0 && meta.egress_metadata.bypass == 1w0) {
            process_telemetry_queue_alert_1.apply(hdr, meta, standard_metadata);
            process_rid_1.apply(hdr, meta, standard_metadata);
            if (hdr.eg_intr_md_from_parser_aux.clone_src == 8w0) 
                process_egress_bfd_packet_1.apply(hdr, meta, standard_metadata);
            else {
                process_mirroring_1.apply(hdr, meta, standard_metadata);
                process_bfd_mirror_to_cpu_1.apply(hdr, meta, standard_metadata);
            }
            process_replication_1.apply(hdr, meta, standard_metadata);
            if (hdr.eg_intr_md_from_parser_aux.clone_src == 8w0) 
                process_telemetry_local_report_1.apply(hdr, meta, standard_metadata);
            switch (egress_port_mapping_0.apply().action_run) {
                egress_port_type_normal_0: {
                    if (hdr.eg_intr_md_from_parser_aux.clone_src == 8w0) 
                        process_vlan_decap_1.apply(hdr, meta, standard_metadata);
                    process_tunnel_decap_1.apply(hdr, meta, standard_metadata);
                    process_srv6_rewrite_1.apply(hdr, meta, standard_metadata);
                    process_rewrite_1.apply(hdr, meta, standard_metadata);
                    process_egress_bd_1.apply(hdr, meta, standard_metadata);
                    process_wred_1.apply(hdr, meta, standard_metadata);
                    process_egress_qos_map_1.apply(hdr, meta, standard_metadata);
                    process_mac_rewrite_1.apply(hdr, meta, standard_metadata);
                    process_mtu_1.apply(hdr, meta, standard_metadata);
                    process_egress_nat_1.apply(hdr, meta, standard_metadata);
                    process_egress_bd_stats_1.apply(hdr, meta, standard_metadata);
                }
            }

            process_egress_l4port_1.apply(hdr, meta, standard_metadata);
            process_telemetry_insert_1.apply(hdr, meta, standard_metadata);
            process_tunnel_encap_1.apply(hdr, meta, standard_metadata);
            process_l4_checksum_1.apply(hdr, meta, standard_metadata);
            process_egress_acl_1.apply(hdr, meta, standard_metadata);
            if (hdr.eg_intr_md_from_parser_aux.clone_src != 8w0) 
                process_telemetry_report_encap_1.apply(hdr, meta, standard_metadata);
            else 
                process_telemetry_outer_encap_1.apply(hdr, meta, standard_metadata);
            if (meta.egress_metadata.port_type == 2w0) 
                process_vlan_xlate_1.apply(hdr, meta, standard_metadata);
            process_egress_filter_1.apply(hdr, meta, standard_metadata);
        }
        process_egress_system_acl_1.apply(hdr, meta, standard_metadata);
    }
}

control process_ingress_port_mapping(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_port_lag_index") action set_port_lag_index_0(bit<10> port_lag_index, bit<2> port_type) {
        meta.ingress_metadata.port_lag_index = port_lag_index;
        meta.ingress_metadata.port_type = port_type;
    }
    @name(".set_ingress_port_properties") action set_ingress_port_properties_0(bit<16> port_lag_label, bit<9> exclusion_id, bit<5> qos_group, bit<5> tc_qos_group, bit<8> tc, bit<2> color, bit<1> trust_dscp, bit<1> trust_pcp) {
        hdr.ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
        meta.acl_metadata.port_lag_label = port_lag_label;
        meta.qos_metadata.ingress_qos_group = qos_group;
        meta.qos_metadata.tc_qos_group = tc_qos_group;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
        meta.qos_metadata.trust_dscp = trust_dscp;
        meta.qos_metadata.trust_pcp = trust_pcp;
    }
    @name(".ingress_port_mapping") table ingress_port_mapping_0 {
        actions = {
            set_port_lag_index_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("hdr.ig_intr_md.ingress_port") ;
        }
        size = 288;
        default_action = NoAction();
    }
    @name(".ingress_port_properties") table ingress_port_properties_0 {
        actions = {
            set_ingress_port_properties_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("hdr.ig_intr_md.ingress_port") ;
        }
        size = 288;
        default_action = NoAction();
    }
    apply {
        if (hdr.ig_intr_md.resubmit_flag == 1w0) 
            ingress_port_mapping_0.apply();
        ingress_port_properties_0.apply();
    }
}

control process_global_params(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_config_parameters") action set_config_parameters_0(bit<8> enable_flowlet, bit<32> switch_id) {
        meta.i2e_metadata.ingress_tstamp = (bit<32>)hdr.ig_intr_md_from_parser_aux.ingress_global_tstamp;
        meta.ingress_metadata.ingress_port = hdr.ig_intr_md.ingress_port;
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w511;
        meta.global_config_metadata.switch_id = switch_id;
    }
    @name(".switch_config_params") table switch_config_params_0 {
        actions = {
            set_config_parameters_0();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    apply {
        switch_config_params_0.apply();
    }
}

control validate_outer_ipv4_header(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_valid_outer_ipv4_packet") action set_valid_outer_ipv4_packet_0() {
        meta.l3_metadata.lkp_ip_type = 2w1;
        meta.l3_metadata.lkp_dscp = hdr.ipv4.diffserv;
        meta.l3_metadata.lkp_ip_version = hdr.ipv4.version;
    }
    @name(".set_malformed_outer_ipv4_packet") action set_malformed_outer_ipv4_packet_0(bit<8> drop_reason) {
        meta.ingress_metadata.drop_flag = 1w1;
        meta.ingress_metadata.drop_reason = drop_reason;
    }
    @name(".validate_outer_ipv4_packet") table validate_outer_ipv4_packet_0 {
        actions = {
            set_valid_outer_ipv4_packet_0();
            set_malformed_outer_ipv4_packet_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.version       : ternary @name("hdr.ipv4.version") ;
            hdr.ipv4.ihl           : ternary @name("hdr.ipv4.ihl") ;
            hdr.ipv4.ttl           : ternary @name("hdr.ipv4.ttl") ;
            hdr.ipv4.srcAddr[31:24]: ternary @name("hdr.ipv4.srcAddr[31:24]") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        validate_outer_ipv4_packet_0.apply();
    }
}

control validate_outer_ipv6_header(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_valid_outer_ipv6_packet") action set_valid_outer_ipv6_packet_0() {
        meta.l3_metadata.lkp_ip_type = 2w2;
        meta.l3_metadata.lkp_dscp = hdr.ipv6.trafficClass;
        meta.l3_metadata.lkp_ip_version = hdr.ipv6.version;
    }
    @name(".set_malformed_outer_ipv6_packet") action set_malformed_outer_ipv6_packet_0(bit<8> drop_reason) {
        meta.ingress_metadata.drop_flag = 1w1;
        meta.ingress_metadata.drop_reason = drop_reason;
    }
    @name(".validate_outer_ipv6_packet") table validate_outer_ipv6_packet_0 {
        actions = {
            set_valid_outer_ipv6_packet_0();
            set_malformed_outer_ipv6_packet_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv6.version         : ternary @name("hdr.ipv6.version") ;
            hdr.ipv6.hopLimit        : ternary @name("hdr.ipv6.hopLimit") ;
            hdr.ipv6.srcAddr[127:112]: ternary @name("hdr.ipv6.srcAddr[127:112]") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        validate_outer_ipv6_packet_0.apply();
    }
}

control validate_mpls_header(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_valid_mpls_label") action set_valid_mpls_label_0() {
        hash<bit<24>, bit<20>, tuple<bit<20>>, bit<40>>(meta.tunnel_metadata.tunnel_vni, HashAlgorithm.identity, 20w0, { hdr.mpls[0].label }, 40w16777216);
        meta.tunnel_metadata.mpls_exp = hdr.mpls[0].exp;
        meta.tunnel_metadata.tunnel_lookup = 1w1;
    }
    @immediate(0) @name(".validate_mpls_packet") table validate_mpls_packet_0 {
        actions = {
            set_valid_mpls_label_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.mpls[0].isValid(): exact @name("hdr..mpls[0].isValid()") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        validate_mpls_packet_0.apply();
    }
}

control process_validate_outer_header(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".malformed_outer_ethernet_packet") action malformed_outer_ethernet_packet_0(bit<8> drop_reason) {
        meta.ingress_metadata.drop_flag = 1w1;
        meta.ingress_metadata.drop_reason = drop_reason;
    }
    @name(".set_valid_outer_unicast_packet_untagged") action set_valid_outer_unicast_packet_untagged_0() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name(".set_valid_outer_unicast_packet_single_tagged") action set_valid_outer_unicast_packet_single_tagged_0() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[0].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_unicast_packet_double_tagged") action set_valid_outer_unicast_packet_double_tagged_0() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[1].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_unicast_packet_qinq_tagged") action set_valid_outer_unicast_packet_qinq_tagged_0() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_multicast_packet_untagged") action set_valid_outer_multicast_packet_untagged_0() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name(".set_valid_outer_multicast_packet_single_tagged") action set_valid_outer_multicast_packet_single_tagged_0() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[0].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_multicast_packet_double_tagged") action set_valid_outer_multicast_packet_double_tagged_0() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[1].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_multicast_packet_qinq_tagged") action set_valid_outer_multicast_packet_qinq_tagged_0() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_broadcast_packet_untagged") action set_valid_outer_broadcast_packet_untagged_0() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name(".set_valid_outer_broadcast_packet_single_tagged") action set_valid_outer_broadcast_packet_single_tagged_0() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[0].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_broadcast_packet_double_tagged") action set_valid_outer_broadcast_packet_double_tagged_0() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[1].etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".set_valid_outer_broadcast_packet_qinq_tagged") action set_valid_outer_broadcast_packet_qinq_tagged_0() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
        meta.l2_metadata.lkp_pcp = hdr.vlan_tag_[0].pcp;
    }
    @name(".validate_outer_ethernet") table validate_outer_ethernet_0 {
        actions = {
            malformed_outer_ethernet_packet_0();
            set_valid_outer_unicast_packet_untagged_0();
            set_valid_outer_unicast_packet_single_tagged_0();
            set_valid_outer_unicast_packet_double_tagged_0();
            set_valid_outer_unicast_packet_qinq_tagged_0();
            set_valid_outer_multicast_packet_untagged_0();
            set_valid_outer_multicast_packet_single_tagged_0();
            set_valid_outer_multicast_packet_double_tagged_0();
            set_valid_outer_multicast_packet_qinq_tagged_0();
            set_valid_outer_broadcast_packet_untagged_0();
            set_valid_outer_broadcast_packet_single_tagged_0();
            set_valid_outer_broadcast_packet_double_tagged_0();
            set_valid_outer_broadcast_packet_qinq_tagged_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.srcAddr      : ternary @name("hdr.ethernet.srcAddr") ;
            hdr.ethernet.dstAddr      : ternary @name("hdr.ethernet.dstAddr") ;
            hdr.vlan_tag_[0].isValid(): exact @name("hdr..vlan_tag_[0].isValid()") ;
            hdr.vlan_tag_[1].isValid(): exact @name("hdr..vlan_tag_[1].isValid()") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".validate_outer_ipv4_header") validate_outer_ipv4_header() validate_outer_ipv4_header_1;
    @name(".validate_outer_ipv6_header") validate_outer_ipv6_header() validate_outer_ipv6_header_1;
    @name(".validate_mpls_header") validate_mpls_header() validate_mpls_header_1;
    apply {
        switch (validate_outer_ethernet_0.apply().action_run) {
            default: {
                if (hdr.ipv4.isValid()) 
                    validate_outer_ipv4_header_1.apply(hdr, meta, standard_metadata);
                else 
                    if (hdr.ipv6.isValid()) 
                        validate_outer_ipv6_header_1.apply(hdr, meta, standard_metadata);
                if (hdr.mpls[0].isValid()) 
                    validate_mpls_header_1.apply(hdr, meta, standard_metadata);
            }
            malformed_outer_ethernet_packet_0: {
            }
        }

    }
}

control process_telemetry_ingress_prepare(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_bfd_rx_packet(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_port_vlan_mapping(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_bd_properties") action set_bd_properties_0(bit<16> bd, bit<16> vrf, bit<10> stp_group, bit<1> learning_enabled, bit<16> bd_label, bit<16> stats_idx, bit<10> rmac_group, bit<1> ipv4_unicast_enabled, bit<1> ipv6_unicast_enabled, bit<2> ipv4_urpf_mode, bit<2> ipv6_urpf_mode, bit<1> igmp_snooping_enabled, bit<1> mld_snooping_enabled, bit<1> ipv4_multicast_enabled, bit<1> ipv6_multicast_enabled, bit<16> mrpf_group, bit<16> ipv4_mcast_key, bit<1> ipv4_mcast_key_type, bit<16> ipv6_mcast_key, bit<1> ipv6_mcast_key_type) {
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
    }
    @name(".port_vlan_mapping_miss") action port_vlan_mapping_miss_0() {
        meta.l2_metadata.port_vlan_mapping_miss = 1w1;
    }
    @name(".set_ingress_interface_properties") action set_ingress_interface_properties_0(bit<16> ingress_rid, bit<16> ifindex, bit<8> if_label) {
        hdr.ig_intr_md_for_tm.rid = ingress_rid;
        meta.ingress_metadata.ifindex = ifindex;
        meta.l2_metadata.same_if_check = ifindex;
    }
    @name(".nop") action nop_13() {
    }
    @ways(1) @name(".cpu_packet_transform") table cpu_packet_transform_0 {
        actions = {
            set_bd_properties_0();
            port_vlan_mapping_miss_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.fabric_header_cpu.ingressBd: exact @name("hdr.fabric_header_cpu.ingressBd") ;
        }
        size = 1024;
        @name(".bd_action_profile") implementation = action_profile(32w1024);
        default_action = NoAction();
    }
    @name(".port_vlan_to_bd_mapping") table port_vlan_to_bd_mapping_0 {
        actions = {
            set_bd_properties_0();
            port_vlan_mapping_miss_0();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.port_lag_index: exact @name("meta.ingress_metadata.port_lag_index") ;
            hdr.vlan_tag_[0].isValid()          : exact @name("hdr..vlan_tag_[0].isValid()") ;
            hdr.vlan_tag_[0].vid                : exact @name("hdr..vlan_tag_[0].vid") ;
            hdr.vlan_tag_[1].isValid()          : exact @name("hdr..vlan_tag_[1].isValid()") ;
            hdr.vlan_tag_[1].vid                : exact @name("hdr..vlan_tag_[1].vid") ;
        }
        size = 4096;
        @name(".bd_action_profile") implementation = action_profile(32w1024);
        default_action = NoAction();
    }
    @name(".port_vlan_to_ifindex_mapping") table port_vlan_to_ifindex_mapping_0 {
        actions = {
            set_ingress_interface_properties_0();
            nop_13();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.port_lag_index: exact @name("meta.ingress_metadata.port_lag_index") ;
            hdr.vlan_tag_[0].isValid()          : exact @name("hdr..vlan_tag_[0].isValid()") ;
            hdr.vlan_tag_[1].isValid()          : exact @name("hdr..vlan_tag_[1].isValid()") ;
            hdr.vlan_tag_[0].vid                : exact @name("hdr..vlan_tag_[0].vid") ;
            hdr.vlan_tag_[1].vid                : exact @name("hdr..vlan_tag_[1].vid") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    apply {
        if (hdr.fabric_header_cpu.isValid()) 
            cpu_packet_transform_0.apply();
        else 
            port_vlan_to_bd_mapping_0.apply();
        port_vlan_to_ifindex_mapping_0.apply();
    }
}

control process_telemetry_int_sink(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ingress_qos_map(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_srv6(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ingress_fabric(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_14() {
    }
    @name(".terminate_cpu_packet") action terminate_cpu_packet_0() {
        hdr.ig_intr_md_for_tm.ucast_egress_port = (bit<9>)hdr.fabric_header.dstPortOrGroup;
        meta.egress_metadata.bypass = hdr.fabric_header_cpu.txBypass;
        hdr.ethernet.etherType = hdr.fabric_payload_header.etherType;
        hdr.fabric_header.setInvalid();
        hdr.fabric_header_cpu.setInvalid();
        hdr.fabric_payload_header.setInvalid();
    }
    @ternary(1) @name(".fabric_ingress_dst_lkp") table fabric_ingress_dst_lkp_0 {
        actions = {
            nop_14();
            terminate_cpu_packet_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.fabric_header.dstDevice: exact @name("hdr.fabric_header.dstDevice") ;
        }
        default_action = NoAction();
    }
    apply {
        if (meta.ingress_metadata.port_type != 2w0) 
            fabric_ingress_dst_lkp_0.apply();
    }
}

control process_ipv4_vtep(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_15() {
    }
    @name(".set_tunnel_lookup_flag") action set_tunnel_lookup_flag_0() {
        meta.tunnel_metadata.tunnel_lookup = 1w1;
    }
    @name(".set_tunnel_vni_and_lookup_flag") action set_tunnel_vni_and_lookup_flag_0(bit<24> tunnel_vni) {
        meta.tunnel_metadata.tunnel_vni = tunnel_vni;
        set_tunnel_lookup_flag_0();
    }
    @name(".on_miss") action on_miss_2() {
    }
    @name(".src_vtep_hit") action src_vtep_hit_0(bit<16> ifindex) {
        meta.tunnel_metadata.src_vtep_hit = 1w1;
        meta.tunnel_metadata.vtep_ifindex = ifindex;
    }
    @name(".ipv4_dest_vtep") table ipv4_dest_vtep_0 {
        actions = {
            nop_15();
            set_tunnel_lookup_flag_0();
            set_tunnel_vni_and_lookup_flag_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf                    : exact @name("meta.l3_metadata.vrf") ;
            hdr.ipv4.dstAddr                        : exact @name("hdr.ipv4.dstAddr") ;
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("meta.tunnel_metadata.ingress_tunnel_type") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".ipv4_src_vtep") table ipv4_src_vtep_0 {
        actions = {
            on_miss_2();
            src_vtep_hit_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf                    : exact @name("meta.l3_metadata.vrf") ;
            hdr.ipv4.srcAddr                        : exact @name("hdr.ipv4.srcAddr") ;
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("meta.tunnel_metadata.ingress_tunnel_type") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        ipv4_src_vtep_0.apply();
        ipv4_dest_vtep_0.apply();
    }
}

control process_ipv6_vtep(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_16() {
    }
    @name(".set_tunnel_lookup_flag") action set_tunnel_lookup_flag_1() {
        meta.tunnel_metadata.tunnel_lookup = 1w1;
    }
    @name(".set_tunnel_vni_and_lookup_flag") action set_tunnel_vni_and_lookup_flag_1(bit<24> tunnel_vni) {
        meta.tunnel_metadata.tunnel_vni = tunnel_vni;
        set_tunnel_lookup_flag_1();
    }
    @name(".on_miss") action on_miss_3() {
    }
    @name(".src_vtep_hit") action src_vtep_hit_1(bit<16> ifindex) {
        meta.tunnel_metadata.src_vtep_hit = 1w1;
        meta.tunnel_metadata.vtep_ifindex = ifindex;
    }
    @name(".ipv6_dest_vtep") table ipv6_dest_vtep_0 {
        actions = {
            nop_16();
            set_tunnel_lookup_flag_1();
            set_tunnel_vni_and_lookup_flag_1();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf                    : exact @name("meta.l3_metadata.vrf") ;
            hdr.ipv6.dstAddr                        : exact @name("hdr.ipv6.dstAddr") ;
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("meta.tunnel_metadata.ingress_tunnel_type") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".ipv6_src_vtep") table ipv6_src_vtep_0 {
        actions = {
            on_miss_3();
            src_vtep_hit_1();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf                    : exact @name("meta.l3_metadata.vrf") ;
            hdr.ipv6.srcAddr                        : exact @name("hdr.ipv6.srcAddr") ;
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("meta.tunnel_metadata.ingress_tunnel_type") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        ipv6_src_vtep_0.apply();
        ipv6_dest_vtep_0.apply();
    }
}

control process_outer_ipv4_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_17() {
    }
    @name(".on_miss") action on_miss_4() {
    }
    @name(".outer_multicast_route_s_g_hit") action outer_multicast_route_s_g_hit_0(bit<16> mc_index, bit<16> mcast_rpf_group) {
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_bridge_s_g_hit") action outer_multicast_bridge_s_g_hit_0(bit<16> mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.tunnel_metadata.tunnel_lookup = 1w1;
    }
    @name(".outer_multicast_route_sm_star_g_hit") action outer_multicast_route_sm_star_g_hit_0(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.outer_mcast_mode = 2w1;
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_route_bidir_star_g_hit") action outer_multicast_route_bidir_star_g_hit_0(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.outer_mcast_mode = 2w2;
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group | meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_bridge_star_g_hit") action outer_multicast_bridge_star_g_hit_0(bit<16> mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.tunnel_metadata.tunnel_lookup = 1w1;
    }
    @ternary(1) @name(".outer_ipv4_multicast") table outer_ipv4_multicast_0 {
        actions = {
            nop_17();
            on_miss_4();
            outer_multicast_route_s_g_hit_0();
            outer_multicast_bridge_s_g_hit_0();
            @defaultonly NoAction();
        }
        key = {
            meta.multicast_metadata.ipv4_mcast_key_type: exact @name("meta.multicast_metadata.ipv4_mcast_key_type") ;
            meta.multicast_metadata.ipv4_mcast_key     : exact @name("meta.multicast_metadata.ipv4_mcast_key") ;
            hdr.ipv4.srcAddr                           : exact @name("hdr.ipv4.srcAddr") ;
            hdr.ipv4.dstAddr                           : exact @name("hdr.ipv4.dstAddr") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".outer_ipv4_multicast_star_g") table outer_ipv4_multicast_star_g_0 {
        actions = {
            nop_17();
            outer_multicast_route_sm_star_g_hit_0();
            outer_multicast_route_bidir_star_g_hit_0();
            outer_multicast_bridge_star_g_hit_0();
            @defaultonly NoAction();
        }
        key = {
            meta.multicast_metadata.ipv4_mcast_key_type: exact @name("meta.multicast_metadata.ipv4_mcast_key_type") ;
            meta.multicast_metadata.ipv4_mcast_key     : exact @name("meta.multicast_metadata.ipv4_mcast_key") ;
            hdr.ipv4.dstAddr                           : ternary @name("hdr.ipv4.dstAddr") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        switch (outer_ipv4_multicast_0.apply().action_run) {
            on_miss_4: {
                outer_ipv4_multicast_star_g_0.apply();
            }
        }

    }
}

control process_outer_ipv6_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_18() {
    }
    @name(".on_miss") action on_miss_5() {
    }
    @name(".outer_multicast_route_s_g_hit") action outer_multicast_route_s_g_hit_1(bit<16> mc_index, bit<16> mcast_rpf_group) {
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_bridge_s_g_hit") action outer_multicast_bridge_s_g_hit_1(bit<16> mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.tunnel_metadata.tunnel_lookup = 1w1;
    }
    @name(".outer_multicast_route_sm_star_g_hit") action outer_multicast_route_sm_star_g_hit_1(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.outer_mcast_mode = 2w1;
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_route_bidir_star_g_hit") action outer_multicast_route_bidir_star_g_hit_1(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.outer_mcast_mode = 2w2;
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group | meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_bridge_star_g_hit") action outer_multicast_bridge_star_g_hit_1(bit<16> mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.tunnel_metadata.tunnel_lookup = 1w1;
    }
    @name(".outer_ipv6_multicast") table outer_ipv6_multicast_0 {
        actions = {
            nop_18();
            on_miss_5();
            outer_multicast_route_s_g_hit_1();
            outer_multicast_bridge_s_g_hit_1();
            @defaultonly NoAction();
        }
        key = {
            meta.multicast_metadata.ipv6_mcast_key_type: exact @name("meta.multicast_metadata.ipv6_mcast_key_type") ;
            meta.multicast_metadata.ipv6_mcast_key     : exact @name("meta.multicast_metadata.ipv6_mcast_key") ;
            hdr.ipv6.srcAddr                           : exact @name("hdr.ipv6.srcAddr") ;
            hdr.ipv6.dstAddr                           : exact @name("hdr.ipv6.dstAddr") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".outer_ipv6_multicast_star_g") table outer_ipv6_multicast_star_g_0 {
        actions = {
            nop_18();
            outer_multicast_route_sm_star_g_hit_1();
            outer_multicast_route_bidir_star_g_hit_1();
            outer_multicast_bridge_star_g_hit_1();
            @defaultonly NoAction();
        }
        key = {
            meta.multicast_metadata.ipv6_mcast_key_type: exact @name("meta.multicast_metadata.ipv6_mcast_key_type") ;
            meta.multicast_metadata.ipv6_mcast_key     : exact @name("meta.multicast_metadata.ipv6_mcast_key") ;
            hdr.ipv6.dstAddr                           : ternary @name("hdr.ipv6.dstAddr") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        switch (outer_ipv6_multicast_0.apply().action_run) {
            on_miss_5: {
                outer_ipv6_multicast_star_g_0.apply();
            }
        }

    }
}

control process_outer_multicast_rpf(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_outer_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".process_outer_ipv4_multicast") process_outer_ipv4_multicast() process_outer_ipv4_multicast_1;
    @name(".process_outer_ipv6_multicast") process_outer_ipv6_multicast() process_outer_ipv6_multicast_1;
    @name(".process_outer_multicast_rpf") process_outer_multicast_rpf() process_outer_multicast_rpf_1;
    apply {
        if (hdr.ipv4.isValid()) 
            process_outer_ipv4_multicast_1.apply(hdr, meta, standard_metadata);
        else 
            if (hdr.ipv6.isValid()) 
                process_outer_ipv6_multicast_1.apply(hdr, meta, standard_metadata);
        process_outer_multicast_rpf_1.apply(hdr, meta, standard_metadata);
    }
}
#include <tofino/p4_14_prim.p4>

control process_tunnel(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".non_ip_lkp") action non_ip_lkp_0() {
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.l2_metadata.non_ip_packet = 1w1;
        invalidate<bit<16>>(hdr.ig_intr_md_for_tm.mcast_grp_a);
    }
    @name(".ipv4_lkp") action ipv4_lkp_0() {
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.ipv4_metadata.lkp_ipv4_sa = hdr.ipv4.srcAddr;
        meta.ipv4_metadata.lkp_ipv4_da = hdr.ipv4.dstAddr;
        meta.l3_metadata.lkp_ip_proto = hdr.ipv4.protocol;
        meta.l3_metadata.lkp_ip_ttl = hdr.ipv4.ttl;
        meta.l3_metadata.lkp_l4_sport = meta.l3_metadata.lkp_outer_l4_sport;
        meta.l3_metadata.lkp_l4_dport = meta.l3_metadata.lkp_outer_l4_dport;
        invalidate<bit<16>>(hdr.ig_intr_md_for_tm.mcast_grp_a);
    }
    @name(".ipv6_lkp") action ipv6_lkp_0() {
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.ipv6_metadata.lkp_ipv6_sa = hdr.ipv6.srcAddr;
        meta.ipv6_metadata.lkp_ipv6_da = hdr.ipv6.dstAddr;
        meta.l3_metadata.lkp_ip_proto = hdr.ipv6.nextHdr;
        meta.l3_metadata.lkp_ip_ttl = hdr.ipv6.hopLimit;
        meta.l3_metadata.lkp_l4_sport = meta.l3_metadata.lkp_outer_l4_sport;
        meta.l3_metadata.lkp_l4_dport = meta.l3_metadata.lkp_outer_l4_dport;
        invalidate<bit<16>>(hdr.ig_intr_md_for_tm.mcast_grp_a);
    }
    @name(".on_miss") action on_miss_6() {
    }
    @name(".outer_rmac_hit") action outer_rmac_hit_0() {
        meta.l3_metadata.rmac_hit = 1w1;
    }
    @name(".nop") action nop_19() {
    }
    @name(".tunnel_lookup_miss") action tunnel_lookup_miss_1() {
    }
    @name(".terminate_tunnel_inner_non_ip") action terminate_tunnel_inner_non_ip_0(bit<16> bd, bit<16> bd_label, bit<16> stats_idx, bit<16> exclusion_id, bit<16> ingress_rid) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.ingress_metadata.ifindex = meta.tunnel_metadata.vtep_ifindex;
        meta.ingress_metadata.bd = bd;
        meta.acl_metadata.bd_label = bd_label;
        meta.l2_metadata.bd_stats_idx = stats_idx;
        meta.l3_metadata.lkp_ip_type = 2w0;
        meta.l2_metadata.lkp_mac_type = hdr.inner_ethernet.etherType;
        hdr.ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        hdr.ig_intr_md_for_tm.rid = ingress_rid;
        meta.l2_metadata.non_ip_packet = 1w1;
    }
    @name(".terminate_tunnel_inner_ethernet_ipv4") action terminate_tunnel_inner_ethernet_ipv4_0(bit<16> bd, bit<16> vrf, bit<10> rmac_group, bit<16> bd_label, bit<1> ipv4_unicast_enabled, bit<2> ipv4_urpf_mode, bit<1> igmp_snooping_enabled, bit<16> stats_idx, bit<1> ipv4_multicast_enabled, bit<16> mrpf_group, bit<16> exclusion_id, bit<16> ingress_rid) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.ingress_metadata.ifindex = meta.tunnel_metadata.vtep_ifindex;
        meta.ingress_metadata.bd = bd;
        meta.l3_metadata.vrf = vrf;
        meta.ipv4_metadata.ipv4_unicast_enabled = ipv4_unicast_enabled;
        meta.ipv4_metadata.ipv4_urpf_mode = ipv4_urpf_mode;
        meta.l3_metadata.rmac_group = rmac_group;
        meta.acl_metadata.bd_label = bd_label;
        meta.l2_metadata.bd_stats_idx = stats_idx;
        meta.l3_metadata.lkp_ip_type = 2w1;
        meta.l2_metadata.lkp_mac_type = hdr.inner_ethernet.etherType;
        meta.l3_metadata.lkp_ip_version = hdr.inner_ipv4.version;
        meta.l3_metadata.lkp_dscp = hdr.inner_ipv4.diffserv;
        meta.multicast_metadata.igmp_snooping_enabled = igmp_snooping_enabled;
        meta.multicast_metadata.ipv4_multicast_enabled = ipv4_multicast_enabled;
        meta.multicast_metadata.bd_mrpf_group = mrpf_group;
        hdr.ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        hdr.ig_intr_md_for_tm.rid = ingress_rid;
    }
    @name(".terminate_tunnel_inner_ipv4") action terminate_tunnel_inner_ipv4_0(bit<16> vrf, bit<10> rmac_group, bit<2> ipv4_urpf_mode, bit<1> ipv4_unicast_enabled, bit<1> ipv4_multicast_enabled, bit<16> mrpf_group) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.ingress_metadata.ifindex = meta.tunnel_metadata.vtep_ifindex;
        meta.l3_metadata.vrf = vrf;
        meta.ipv4_metadata.ipv4_unicast_enabled = ipv4_unicast_enabled;
        meta.ipv4_metadata.ipv4_urpf_mode = ipv4_urpf_mode;
        meta.l3_metadata.rmac_group = rmac_group;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.l3_metadata.lkp_ip_type = 2w1;
        meta.l3_metadata.lkp_ip_version = hdr.inner_ipv4.version;
        meta.l3_metadata.lkp_dscp = hdr.inner_ipv4.diffserv;
        meta.multicast_metadata.bd_mrpf_group = mrpf_group;
        meta.multicast_metadata.ipv4_multicast_enabled = ipv4_multicast_enabled;
    }
    @name(".terminate_tunnel_inner_ethernet_ipv6") action terminate_tunnel_inner_ethernet_ipv6_0(bit<16> bd, bit<16> vrf, bit<10> rmac_group, bit<16> bd_label, bit<1> ipv6_unicast_enabled, bit<2> ipv6_urpf_mode, bit<1> mld_snooping_enabled, bit<16> stats_idx, bit<1> ipv6_multicast_enabled, bit<16> mrpf_group, bit<16> exclusion_id, bit<16> ingress_rid) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.ingress_metadata.ifindex = meta.tunnel_metadata.vtep_ifindex;
        meta.ingress_metadata.bd = bd;
        meta.l3_metadata.vrf = vrf;
        meta.ipv6_metadata.ipv6_unicast_enabled = ipv6_unicast_enabled;
        meta.ipv6_metadata.ipv6_urpf_mode = ipv6_urpf_mode;
        meta.l3_metadata.rmac_group = rmac_group;
        meta.acl_metadata.bd_label = bd_label;
        meta.l2_metadata.bd_stats_idx = stats_idx;
        meta.l3_metadata.lkp_ip_type = 2w2;
        meta.l2_metadata.lkp_mac_type = hdr.inner_ethernet.etherType;
        meta.l3_metadata.lkp_ip_version = hdr.inner_ipv6.version;
        meta.l3_metadata.lkp_dscp = hdr.inner_ipv6.trafficClass;
        meta.multicast_metadata.bd_mrpf_group = mrpf_group;
        meta.multicast_metadata.ipv6_multicast_enabled = ipv6_multicast_enabled;
        meta.multicast_metadata.mld_snooping_enabled = mld_snooping_enabled;
        hdr.ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        hdr.ig_intr_md_for_tm.rid = ingress_rid;
    }
    @name(".terminate_tunnel_inner_ipv6") action terminate_tunnel_inner_ipv6_0(bit<16> vrf, bit<10> rmac_group, bit<1> ipv6_unicast_enabled, bit<2> ipv6_urpf_mode, bit<1> ipv6_multicast_enabled, bit<16> mrpf_group) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.ingress_metadata.ifindex = meta.tunnel_metadata.vtep_ifindex;
        meta.l3_metadata.vrf = vrf;
        meta.ipv6_metadata.ipv6_unicast_enabled = ipv6_unicast_enabled;
        meta.ipv6_metadata.ipv6_urpf_mode = ipv6_urpf_mode;
        meta.l3_metadata.rmac_group = rmac_group;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.l3_metadata.lkp_ip_type = 2w2;
        meta.l3_metadata.lkp_ip_version = hdr.inner_ipv6.version;
        meta.l3_metadata.lkp_dscp = hdr.inner_ipv6.trafficClass;
        meta.multicast_metadata.bd_mrpf_group = mrpf_group;
        meta.multicast_metadata.ipv6_multicast_enabled = ipv6_multicast_enabled;
    }
    @name(".terminate_eompls") action terminate_eompls_0(bit<16> bd, bit<5> tunnel_type) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.ingress_metadata.ifindex = meta.tunnel_metadata.vtep_ifindex;
        meta.tunnel_metadata.ingress_tunnel_type = tunnel_type;
        meta.ingress_metadata.bd = bd;
        meta.l3_metadata.lkp_ip_type = 2w0;
        meta.l2_metadata.lkp_mac_type = hdr.inner_ethernet.etherType;
    }
    @name(".terminate_vpls") action terminate_vpls_0(bit<16> bd, bit<5> tunnel_type) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.ingress_metadata.ifindex = meta.tunnel_metadata.vtep_ifindex;
        meta.tunnel_metadata.ingress_tunnel_type = tunnel_type;
        meta.ingress_metadata.bd = bd;
        meta.l2_metadata.lkp_mac_type = hdr.inner_ethernet.etherType;
    }
    @name(".terminate_ipv4_over_mpls") action terminate_ipv4_over_mpls_0(bit<16> vrf, bit<5> tunnel_type) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.ingress_metadata.ifindex = meta.tunnel_metadata.vtep_ifindex;
        meta.tunnel_metadata.ingress_tunnel_type = tunnel_type;
        meta.l3_metadata.vrf = vrf;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.l3_metadata.lkp_ip_type = 2w1;
        meta.l2_metadata.lkp_mac_type = hdr.inner_ethernet.etherType;
        meta.l3_metadata.lkp_ip_version = hdr.inner_ipv4.version;
        meta.l3_metadata.lkp_dscp = hdr.inner_ipv4.diffserv;
    }
    @name(".terminate_ipv6_over_mpls") action terminate_ipv6_over_mpls_0(bit<16> vrf, bit<5> tunnel_type) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.ingress_metadata.ifindex = meta.tunnel_metadata.vtep_ifindex;
        meta.tunnel_metadata.ingress_tunnel_type = tunnel_type;
        meta.l3_metadata.vrf = vrf;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.l3_metadata.lkp_ip_type = 2w2;
        meta.l2_metadata.lkp_mac_type = hdr.inner_ethernet.etherType;
        meta.l3_metadata.lkp_ip_version = hdr.inner_ipv6.version;
        meta.l3_metadata.lkp_dscp = hdr.inner_ipv6.trafficClass;
    }
    @name(".terminate_pw") action terminate_pw_0(bit<16> ifindex) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.ingress_metadata.ifindex = meta.tunnel_metadata.vtep_ifindex;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
    }
    @name(".forward_mpls") action forward_mpls_0(bit<16> nexthop_index) {
        meta.l3_metadata.fib_nexthop = nexthop_index;
        meta.l3_metadata.fib_nexthop_type = 1w0;
        meta.l3_metadata.fib_hit = 1w1;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.l2_metadata.non_ip_packet = 1w1;
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".tunnel_check_pass") action tunnel_check_pass_0() {
    }
    @name(".adjust_lkp_fields") table adjust_lkp_fields_0 {
        actions = {
            non_ip_lkp_0();
            ipv4_lkp_0();
            ipv6_lkp_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.isValid(): exact @name("hdr.ipv4.isValid()") ;
            hdr.ipv6.isValid(): exact @name("hdr.ipv6.isValid()") ;
        }
        default_action = NoAction();
    }
    @ternary(1) @name(".outer_rmac") table outer_rmac_0 {
        actions = {
            on_miss_6();
            outer_rmac_hit_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.rmac_group: exact @name("meta.l3_metadata.rmac_group") ;
            hdr.ethernet.dstAddr       : exact @name("hdr.ethernet.dstAddr") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".tunnel") table tunnel_0 {
        actions = {
            nop_19();
            tunnel_lookup_miss_1();
            terminate_tunnel_inner_non_ip_0();
            terminate_tunnel_inner_ethernet_ipv4_0();
            terminate_tunnel_inner_ipv4_0();
            terminate_tunnel_inner_ethernet_ipv6_0();
            terminate_tunnel_inner_ipv6_0();
            terminate_eompls_0();
            terminate_vpls_0();
            terminate_ipv4_over_mpls_0();
            terminate_ipv6_over_mpls_0();
            terminate_pw_0();
            forward_mpls_0();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.tunnel_vni         : exact @name("meta.tunnel_metadata.tunnel_vni") ;
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("meta.tunnel_metadata.ingress_tunnel_type") ;
            hdr.inner_ipv4.isValid()                : exact @name("hdr.inner_ipv4.isValid()") ;
            hdr.inner_ipv6.isValid()                : exact @name("hdr.inner_ipv6.isValid()") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".tunnel_check") table tunnel_check_0 {
        actions = {
            nop_19();
            tunnel_check_pass_0();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.ingress_tunnel_type: ternary @name("meta.tunnel_metadata.ingress_tunnel_type") ;
            meta.tunnel_metadata.tunnel_lookup      : ternary @name("meta.tunnel_metadata.tunnel_lookup") ;
            meta.tunnel_metadata.src_vtep_hit       : ternary @name("meta.tunnel_metadata.src_vtep_hit") ;
        }
        default_action = NoAction();
    }
    @name(".tunnel_lookup_miss") table tunnel_lookup_miss_2 {
        actions = {
            non_ip_lkp_0();
            ipv4_lkp_0();
            ipv6_lkp_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.isValid(): exact @name("hdr.ipv4.isValid()") ;
            hdr.ipv6.isValid(): exact @name("hdr.ipv6.isValid()") ;
        }
        default_action = NoAction();
    }
    @name(".process_ingress_fabric") process_ingress_fabric() process_ingress_fabric_1;
    @name(".process_ipv4_vtep") process_ipv4_vtep() process_ipv4_vtep_1;
    @name(".process_ipv6_vtep") process_ipv6_vtep() process_ipv6_vtep_1;
    @name(".process_outer_multicast") process_outer_multicast() process_outer_multicast_1;
    apply {
        process_ingress_fabric_1.apply(hdr, meta, standard_metadata);
        if (meta.tunnel_metadata.ingress_tunnel_type != 5w0) 
            switch (outer_rmac_0.apply().action_run) {
                default: {
                    if (hdr.ipv4.isValid()) 
                        process_ipv4_vtep_1.apply(hdr, meta, standard_metadata);
                    else 
                        if (hdr.ipv6.isValid()) 
                            process_ipv6_vtep_1.apply(hdr, meta, standard_metadata);
                }
                on_miss_6: {
                    process_outer_multicast_1.apply(hdr, meta, standard_metadata);
                }
            }

        if (meta.tunnel_metadata.tunnel_lookup == 1w1 || meta.multicast_metadata.outer_mcast_route_hit == 1w1 && (meta.multicast_metadata.outer_mcast_mode == 2w1 && meta.multicast_metadata.mcast_rpf_group == 16w0 || meta.multicast_metadata.outer_mcast_mode == 2w2 && meta.multicast_metadata.mcast_rpf_group != 16w0)) 
            switch (tunnel_check_0.apply().action_run) {
                tunnel_check_pass_0: {
                    switch (tunnel_0.apply().action_run) {
                        tunnel_lookup_miss_1: {
                            tunnel_lookup_miss_2.apply();
                        }
                    }

                }
            }

        else 
            adjust_lkp_fields_0.apply();
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

control process_storm_control(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".storm_control_meter") meter(32w1024, MeterType.bytes) storm_control_meter_0;
    @name(".nop") action nop_20() {
    }
    @name(".set_storm_control_meter") action set_storm_control_meter_0(bit<32> meter_idx) {
        storm_control_meter_0.execute_meter<bit<2>>(meter_idx, meta.meter_metadata.packet_color);
        meta.meter_metadata.meter_index = (bit<16>)meter_idx;
    }
    @name(".storm_control") table storm_control_0 {
        actions = {
            nop_20();
            set_storm_control_meter_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port  : exact @name("hdr.ig_intr_md.ingress_port") ;
            meta.l2_metadata.lkp_pkt_type: ternary @name("meta.l2_metadata.lkp_pkt_type") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.ingress_metadata.port_type == 2w0) 
            storm_control_0.apply();
    }
}

control process_spanning_tree(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_stp_state") action set_stp_state_0(bit<3> stp_state) {
        meta.l2_metadata.stp_state = stp_state;
    }
    @ternary(1) @name(".spanning_tree") table spanning_tree_0 {
        actions = {
            set_stp_state_0();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.ifindex: exact @name("meta.ingress_metadata.ifindex") ;
            meta.l2_metadata.stp_group   : exact @name("meta.l2_metadata.stp_group") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        if (meta.ingress_metadata.port_type == 2w0 && meta.l2_metadata.stp_group != 10w0) 
            spanning_tree_0.apply();
    }
}

control process_bfd_packet(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_validate_packet(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_21() {
    }
    @name(".set_unicast") action set_unicast_0() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
    }
    @name(".set_unicast_and_ipv6_src_is_link_local") action set_unicast_and_ipv6_src_is_link_local_0() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.ipv6_metadata.ipv6_src_is_link_local = 1w1;
    }
    @name(".set_multicast") action set_multicast_0() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.bd_stats_idx = meta.l2_metadata.bd_stats_idx + 16w1;
    }
    @name(".set_multicast_and_ipv6_src_is_link_local") action set_multicast_and_ipv6_src_is_link_local_0() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.ipv6_metadata.ipv6_src_is_link_local = 1w1;
        meta.l2_metadata.bd_stats_idx = meta.l2_metadata.bd_stats_idx + 16w1;
    }
    @name(".set_broadcast") action set_broadcast_0() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.bd_stats_idx = meta.l2_metadata.bd_stats_idx + 16w2;
    }
    @name(".set_malformed_packet") action set_malformed_packet_0(bit<8> drop_reason) {
        meta.ingress_metadata.drop_flag = 1w1;
        meta.ingress_metadata.drop_reason = drop_reason;
    }
    @name(".validate_packet") table validate_packet_0 {
        actions = {
            nop_21();
            set_unicast_0();
            set_unicast_and_ipv6_src_is_link_local_0();
            set_multicast_0();
            set_multicast_and_ipv6_src_is_link_local_0();
            set_broadcast_0();
            set_malformed_packet_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l2_metadata.lkp_mac_sa            : ternary @name("meta.l2_metadata.lkp_mac_sa") ;
            meta.l2_metadata.lkp_mac_da            : ternary @name("meta.l2_metadata.lkp_mac_da") ;
            meta.l3_metadata.lkp_ip_type           : ternary @name("meta.l3_metadata.lkp_ip_type") ;
            meta.l3_metadata.lkp_ip_ttl            : ternary @name("meta.l3_metadata.lkp_ip_ttl") ;
            meta.l3_metadata.lkp_ip_version        : ternary @name("meta.l3_metadata.lkp_ip_version") ;
            meta.tunnel_metadata.tunnel_terminate  : ternary @name("meta.tunnel_metadata.tunnel_terminate") ;
            hdr.inner_ipv4.ihl                     : ternary @name("hdr.inner_ipv4.ihl") ;
            meta.ipv4_metadata.lkp_ipv4_sa[31:24]  : ternary @name("meta.ipv4_metadata.lkp_ipv4_sa[31:24]") ;
            meta.ipv6_metadata.lkp_ipv6_sa[127:112]: ternary @name("meta.ipv6_metadata.lkp_ipv6_sa[127:112]") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if ((meta.ingress_metadata.bypass_lookups & 16w0x40) == 16w0 && meta.ingress_metadata.drop_flag == 1w0) 
            validate_packet_0.apply();
    }
}

control process_ingress_l4port(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_22() {
    }
    @name(".set_ingress_dst_port_range_id") action set_ingress_dst_port_range_id_0(bit<8> range_id) {
        meta.acl_metadata.ingress_dst_port_range_id = range_id;
    }
    @name(".set_ingress_src_port_range_id") action set_ingress_src_port_range_id_0(bit<8> range_id) {
        meta.acl_metadata.ingress_src_port_range_id = range_id;
    }
    @name(".ingress_l4_dst_port") table ingress_l4_dst_port_0 {
        actions = {
            nop_22();
            set_ingress_dst_port_range_id_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.lkp_l4_dport: range @name("meta.l3_metadata.lkp_l4_dport") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".ingress_l4_src_port") table ingress_l4_src_port_0 {
        actions = {
            nop_22();
            set_ingress_src_port_range_id_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.lkp_l4_sport: range @name("meta.l3_metadata.lkp_l4_sport") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        ingress_l4_src_port_0.apply();
        ingress_l4_dst_port_0.apply();
    }
}

control process_mac(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_23() {
    }
    @name(".dmac_hit") action dmac_hit_0(bit<16> ifindex, bit<10> port_lag_index) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.ingress_metadata.egress_port_lag_index = port_lag_index;
        meta.l2_metadata.same_if_check = meta.l2_metadata.same_if_check ^ ifindex;
    }
    @name(".dmac_multicast_hit") action dmac_multicast_hit_0(bit<16> mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_b = mc_index;
    }
    @name(".dmac_miss") action dmac_miss_0() {
        meta.ingress_metadata.egress_ifindex = 16w65535;
    }
    @name(".dmac_redirect_nexthop") action dmac_redirect_nexthop_0(bit<16> nexthop_index) {
        meta.l2_metadata.l2_redirect = 1w1;
        meta.l2_metadata.l2_nexthop = nexthop_index;
        meta.l2_metadata.l2_nexthop_type = 1w0;
    }
    @name(".dmac_redirect_ecmp") action dmac_redirect_ecmp_0(bit<16> ecmp_index) {
        meta.l2_metadata.l2_redirect = 1w1;
        meta.l2_metadata.l2_nexthop = ecmp_index;
        meta.l2_metadata.l2_nexthop_type = 1w1;
    }
    @name(".dmac_drop") action dmac_drop_0() {
        mark_to_drop();
    }
    @name(".smac_miss") action smac_miss_0() {
        meta.l2_metadata.l2_src_miss = 1w1;
    }
    @name(".smac_hit") action smac_hit_0(bit<16> ifindex) {
        meta.l2_metadata.l2_src_move = meta.ingress_metadata.ifindex ^ ifindex;
    }
    @name(".dmac") table dmac_0 {
        support_timeout = true;
        actions = {
            nop_23();
            dmac_hit_0();
            dmac_multicast_hit_0();
            dmac_miss_0();
            dmac_redirect_nexthop_0();
            dmac_redirect_ecmp_0();
            dmac_drop_0();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.bd   : exact @name("meta.ingress_metadata.bd") ;
            meta.l2_metadata.lkp_mac_da: exact @name("meta.l2_metadata.lkp_mac_da") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".smac") table smac_0 {
        actions = {
            nop_23();
            smac_miss_0();
            smac_hit_0();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.bd   : exact @name("meta.ingress_metadata.bd") ;
            meta.l2_metadata.lkp_mac_sa: exact @name("meta.l2_metadata.lkp_mac_sa") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        if ((meta.ingress_metadata.bypass_lookups & 16w0x80) == 16w0 && meta.ingress_metadata.port_type == 2w0) 
            smac_0.apply();
        if ((meta.ingress_metadata.bypass_lookups & 16w0x1) == 16w0) 
            dmac_0.apply();
    }
}

control process_mac_acl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_24() {
    }
    @name(".acl_deny") action acl_deny_0(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_permit") action acl_permit_0(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_redirect_nexthop") action acl_redirect_nexthop_0(bit<16> nexthop_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = nexthop_index;
        meta.acl_metadata.acl_nexthop_type = 1w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_redirect_ecmp") action acl_redirect_ecmp_0(bit<16> ecmp_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = ecmp_index;
        meta.acl_metadata.acl_nexthop_type = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_mirror") action acl_mirror_0(bit<32> session_id, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.i2e_metadata.mirror_session_id = (bit<16>)session_id;
        clone3<tuple<bit<32>, bit<16>>>(CloneType.I2E, session_id, { meta.i2e_metadata.ingress_tstamp, meta.i2e_metadata.mirror_session_id });
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".mac_acl") table mac_acl_0 {
        actions = {
            nop_24();
            acl_deny_0();
            acl_permit_0();
            acl_redirect_nexthop_0();
            acl_redirect_ecmp_0();
            acl_mirror_0();
            @defaultonly NoAction();
        }
        key = {
            meta.acl_metadata.port_lag_label: ternary @name("meta.acl_metadata.port_lag_label") ;
            meta.acl_metadata.bd_label      : ternary @name("meta.acl_metadata.bd_label") ;
            meta.l2_metadata.lkp_mac_sa     : ternary @name("meta.l2_metadata.lkp_mac_sa") ;
            meta.l2_metadata.lkp_mac_da     : ternary @name("meta.l2_metadata.lkp_mac_da") ;
            meta.l2_metadata.lkp_mac_type   : ternary @name("meta.l2_metadata.lkp_mac_type") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if ((meta.ingress_metadata.bypass_lookups & 16w0x4) == 16w0) 
            mac_acl_0.apply();
    }
}

control process_ip_acl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_25() {
    }
    @name(".acl_deny") action acl_deny_1(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_permit") action acl_permit_1(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_redirect_nexthop") action acl_redirect_nexthop_1(bit<16> nexthop_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = nexthop_index;
        meta.acl_metadata.acl_nexthop_type = 1w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_redirect_ecmp") action acl_redirect_ecmp_1(bit<16> ecmp_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = ecmp_index;
        meta.acl_metadata.acl_nexthop_type = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_mirror") action acl_mirror_1(bit<32> session_id, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<2> nat_mode, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.i2e_metadata.mirror_session_id = (bit<16>)session_id;
        clone3<tuple<bit<32>, bit<16>>>(CloneType.I2E, session_id, { meta.i2e_metadata.ingress_tstamp, meta.i2e_metadata.mirror_session_id });
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".ip_acl") table ip_acl_0 {
        actions = {
            nop_25();
            acl_deny_1();
            acl_permit_1();
            acl_redirect_nexthop_1();
            acl_redirect_ecmp_1();
            acl_mirror_1();
            @defaultonly NoAction();
        }
        key = {
            meta.acl_metadata.port_lag_label           : ternary @name("meta.acl_metadata.port_lag_label") ;
            meta.acl_metadata.bd_label                 : ternary @name("meta.acl_metadata.bd_label") ;
            meta.ipv4_metadata.lkp_ipv4_sa             : ternary @name("meta.ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da             : ternary @name("meta.ipv4_metadata.lkp_ipv4_da") ;
            meta.l3_metadata.lkp_ip_proto              : ternary @name("meta.l3_metadata.lkp_ip_proto") ;
            meta.acl_metadata.ingress_src_port_range_id: exact @name("meta.acl_metadata.ingress_src_port_range_id") ;
            meta.acl_metadata.ingress_dst_port_range_id: exact @name("meta.acl_metadata.ingress_dst_port_range_id") ;
            hdr.tcp.flags                              : ternary @name("hdr.tcp.flags") ;
            meta.l3_metadata.lkp_ip_ttl                : ternary @name("meta.l3_metadata.lkp_ip_ttl") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".ipv6_acl") table ipv6_acl_0 {
        actions = {
            nop_25();
            acl_deny_1();
            acl_permit_1();
            acl_redirect_nexthop_1();
            acl_redirect_ecmp_1();
            acl_mirror_1();
            @defaultonly NoAction();
        }
        key = {
            meta.acl_metadata.port_lag_label           : ternary @name("meta.acl_metadata.port_lag_label") ;
            meta.acl_metadata.bd_label                 : ternary @name("meta.acl_metadata.bd_label") ;
            meta.ipv6_metadata.lkp_ipv6_sa             : ternary @name("meta.ipv6_metadata.lkp_ipv6_sa") ;
            meta.ipv6_metadata.lkp_ipv6_da             : ternary @name("meta.ipv6_metadata.lkp_ipv6_da") ;
            meta.l3_metadata.lkp_ip_proto              : ternary @name("meta.l3_metadata.lkp_ip_proto") ;
            meta.acl_metadata.ingress_src_port_range_id: exact @name("meta.acl_metadata.ingress_src_port_range_id") ;
            meta.acl_metadata.ingress_dst_port_range_id: exact @name("meta.acl_metadata.ingress_dst_port_range_id") ;
            hdr.tcp.flags                              : ternary @name("hdr.tcp.flags") ;
            meta.l3_metadata.lkp_ip_ttl                : ternary @name("meta.l3_metadata.lkp_ip_ttl") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if ((meta.ingress_metadata.bypass_lookups & 16w0x4) == 16w0) 
            if (meta.l3_metadata.lkp_ip_type == 2w1) 
                ip_acl_0.apply();
            else 
                if (meta.l3_metadata.lkp_ip_type == 2w2) 
                    ipv6_acl_0.apply();
    }
}

control process_ingress_port_mirroring(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_ingress_port_mirror_index") action set_ingress_port_mirror_index_0(bit<32> session_id) {
        meta.i2e_metadata.mirror_session_id = (bit<16>)session_id;
        clone3<tuple<bit<32>, bit<16>>>(CloneType.I2E, session_id, { meta.i2e_metadata.ingress_tstamp, meta.i2e_metadata.mirror_session_id });
    }
    @name(".ingress_port_mirror") table ingress_port_mirror_0 {
        actions = {
            set_ingress_port_mirror_index_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("hdr.ig_intr_md.ingress_port") ;
        }
        size = 288;
        default_action = NoAction();
    }
    apply {
        ingress_port_mirror_0.apply();
    }
}

control process_telemetry_int_upstream_report(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ipv4_racl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_26() {
    }
    @name(".racl_deny") action racl_deny_0(bit<14> acl_stats_index, bit<16> acl_copy_reason, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.racl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".racl_permit") action racl_permit_0(bit<14> acl_stats_index, bit<16> acl_copy_reason, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".racl_redirect_nexthop") action racl_redirect_nexthop_0(bit<16> nexthop_index, bit<14> acl_stats_index, bit<16> acl_copy_reason, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.racl_redirect = 1w1;
        meta.acl_metadata.racl_nexthop = nexthop_index;
        meta.acl_metadata.racl_nexthop_type = 1w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".racl_redirect_ecmp") action racl_redirect_ecmp_0(bit<16> ecmp_index, bit<14> acl_stats_index, bit<16> acl_copy_reason, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.racl_redirect = 1w1;
        meta.acl_metadata.racl_nexthop = ecmp_index;
        meta.acl_metadata.racl_nexthop_type = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".ipv4_racl") table ipv4_racl_0 {
        actions = {
            nop_26();
            racl_deny_0();
            racl_permit_0();
            racl_redirect_nexthop_0();
            racl_redirect_ecmp_0();
            @defaultonly NoAction();
        }
        key = {
            meta.acl_metadata.bd_label                 : ternary @name("meta.acl_metadata.bd_label") ;
            meta.ipv4_metadata.lkp_ipv4_sa             : ternary @name("meta.ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da             : ternary @name("meta.ipv4_metadata.lkp_ipv4_da") ;
            meta.l3_metadata.lkp_ip_proto              : ternary @name("meta.l3_metadata.lkp_ip_proto") ;
            meta.acl_metadata.ingress_src_port_range_id: exact @name("meta.acl_metadata.ingress_src_port_range_id") ;
            meta.acl_metadata.ingress_dst_port_range_id: exact @name("meta.acl_metadata.ingress_dst_port_range_id") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        ipv4_racl_0.apply();
    }
}

control process_ipv4_urpf(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".on_miss") action on_miss_7() {
    }
    @name(".ipv4_urpf_hit") action ipv4_urpf_hit_0(bit<16> urpf_bd_group) {
        meta.l3_metadata.urpf_hit = 1w1;
        meta.l3_metadata.urpf_bd_group = urpf_bd_group;
        meta.l3_metadata.urpf_mode = meta.ipv4_metadata.ipv4_urpf_mode;
    }
    @name(".urpf_miss") action urpf_miss_0() {
        meta.l3_metadata.urpf_check_fail = 1w1;
    }
    @name(".ipv4_urpf") table ipv4_urpf_0 {
        actions = {
            on_miss_7();
            ipv4_urpf_hit_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("meta.l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_sa: exact @name("meta.ipv4_metadata.lkp_ipv4_sa") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".ipv4_urpf_lpm") table ipv4_urpf_lpm_0 {
        actions = {
            ipv4_urpf_hit_0();
            urpf_miss_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("meta.l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_sa: lpm @name("meta.ipv4_metadata.lkp_ipv4_sa") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.ipv4_metadata.ipv4_urpf_mode != 2w0) 
            switch (ipv4_urpf_0.apply().action_run) {
                on_miss_7: {
                    ipv4_urpf_lpm_0.apply();
                }
            }

    }
}

control process_ipv4_fib(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".on_miss") action on_miss_8() {
    }
    @name(".fib_hit_nexthop") action fib_hit_nexthop_0(bit<16> nexthop_index) {
        meta.l3_metadata.fib_hit = 1w1;
        meta.l3_metadata.fib_nexthop = nexthop_index;
        meta.l3_metadata.fib_nexthop_type = 1w0;
    }
    @name(".fib_hit_ecmp") action fib_hit_ecmp_0(bit<16> ecmp_index) {
        meta.l3_metadata.fib_hit = 1w1;
        meta.l3_metadata.fib_nexthop = ecmp_index;
        meta.l3_metadata.fib_nexthop_type = 1w1;
    }
    @name(".ipv4_fib") table ipv4_fib_0 {
        actions = {
            on_miss_8();
            fib_hit_nexthop_0();
            fib_hit_ecmp_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("meta.l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("meta.ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".ipv4_fib_lpm") table ipv4_fib_lpm_0 {
        actions = {
            on_miss_8();
            fib_hit_nexthop_0();
            fib_hit_ecmp_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("meta.l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da: lpm @name("meta.ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        switch (ipv4_fib_0.apply().action_run) {
            on_miss_8: {
                ipv4_fib_lpm_0.apply();
            }
        }

    }
}

control process_ipv6_racl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_27() {
    }
    @name(".racl_deny") action racl_deny_1(bit<14> acl_stats_index, bit<16> acl_copy_reason, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.racl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".racl_permit") action racl_permit_1(bit<14> acl_stats_index, bit<16> acl_copy_reason, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".racl_redirect_nexthop") action racl_redirect_nexthop_1(bit<16> nexthop_index, bit<14> acl_stats_index, bit<16> acl_copy_reason, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.racl_redirect = 1w1;
        meta.acl_metadata.racl_nexthop = nexthop_index;
        meta.acl_metadata.racl_nexthop_type = 1w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".racl_redirect_ecmp") action racl_redirect_ecmp_1(bit<16> ecmp_index, bit<14> acl_stats_index, bit<16> acl_copy_reason, bit<8> ingress_cos, bit<8> tc, bit<8> color) {
        meta.acl_metadata.racl_redirect = 1w1;
        meta.acl_metadata.racl_nexthop = ecmp_index;
        meta.acl_metadata.racl_nexthop_type = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".ipv6_racl") table ipv6_racl_0 {
        actions = {
            nop_27();
            racl_deny_1();
            racl_permit_1();
            racl_redirect_nexthop_1();
            racl_redirect_ecmp_1();
            @defaultonly NoAction();
        }
        key = {
            meta.acl_metadata.bd_label                 : ternary @name("meta.acl_metadata.bd_label") ;
            meta.ipv6_metadata.lkp_ipv6_sa             : ternary @name("meta.ipv6_metadata.lkp_ipv6_sa") ;
            meta.ipv6_metadata.lkp_ipv6_da             : ternary @name("meta.ipv6_metadata.lkp_ipv6_da") ;
            meta.l3_metadata.lkp_ip_proto              : ternary @name("meta.l3_metadata.lkp_ip_proto") ;
            meta.acl_metadata.ingress_src_port_range_id: exact @name("meta.acl_metadata.ingress_src_port_range_id") ;
            meta.acl_metadata.ingress_dst_port_range_id: exact @name("meta.acl_metadata.ingress_dst_port_range_id") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        ipv6_racl_0.apply();
    }
}

control process_ipv6_urpf(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".on_miss") action on_miss_9() {
    }
    @name(".ipv6_urpf_hit") action ipv6_urpf_hit_0(bit<16> urpf_bd_group) {
        meta.l3_metadata.urpf_hit = 1w1;
        meta.l3_metadata.urpf_bd_group = urpf_bd_group;
        meta.l3_metadata.urpf_mode = meta.ipv6_metadata.ipv6_urpf_mode;
    }
    @name(".urpf_miss") action urpf_miss_1() {
        meta.l3_metadata.urpf_check_fail = 1w1;
    }
    @name(".ipv6_urpf") table ipv6_urpf_0 {
        actions = {
            on_miss_9();
            ipv6_urpf_hit_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("meta.l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_sa: exact @name("meta.ipv6_metadata.lkp_ipv6_sa") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".ipv6_urpf_lpm") table ipv6_urpf_lpm_0 {
        actions = {
            ipv6_urpf_hit_0();
            urpf_miss_1();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("meta.l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_sa: lpm @name("meta.ipv6_metadata.lkp_ipv6_sa") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.ipv6_metadata.ipv6_urpf_mode != 2w0) 
            switch (ipv6_urpf_0.apply().action_run) {
                on_miss_9: {
                    ipv6_urpf_lpm_0.apply();
                }
            }

    }
}

control process_ipv6_fib(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".on_miss") action on_miss_10() {
    }
    @name(".fib_hit_nexthop") action fib_hit_nexthop_1(bit<16> nexthop_index) {
        meta.l3_metadata.fib_hit = 1w1;
        meta.l3_metadata.fib_nexthop = nexthop_index;
        meta.l3_metadata.fib_nexthop_type = 1w0;
    }
    @name(".fib_hit_ecmp") action fib_hit_ecmp_1(bit<16> ecmp_index) {
        meta.l3_metadata.fib_hit = 1w1;
        meta.l3_metadata.fib_nexthop = ecmp_index;
        meta.l3_metadata.fib_nexthop_type = 1w1;
    }
    @name(".ipv6_fib") table ipv6_fib_0 {
        actions = {
            on_miss_10();
            fib_hit_nexthop_1();
            fib_hit_ecmp_1();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("meta.l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_da: exact @name("meta.ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".ipv6_fib_lpm") table ipv6_fib_lpm_0 {
        actions = {
            on_miss_10();
            fib_hit_nexthop_1();
            fib_hit_ecmp_1();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("meta.l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_da: lpm @name("meta.ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        switch (ipv6_fib_0.apply().action_run) {
            on_miss_10: {
                ipv6_fib_lpm_0.apply();
            }
        }

    }
}

control process_urpf_bd(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_28() {
    }
    @name(".urpf_bd_miss") action urpf_bd_miss_0() {
        meta.l3_metadata.urpf_check_fail = 1w1;
    }
    @name(".urpf_bd") table urpf_bd_0 {
        actions = {
            nop_28();
            urpf_bd_miss_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.urpf_bd_group: exact @name("meta.l3_metadata.urpf_bd_group") ;
            meta.ingress_metadata.bd      : exact @name("meta.ingress_metadata.bd") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        if (meta.l3_metadata.urpf_mode == 2w2 && meta.l3_metadata.urpf_hit == 1w1) 
            urpf_bd_0.apply();
    }
}

control process_ipv4_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".ipv4_multicast_route_s_g_stats") direct_counter(CounterType.packets) ipv4_multicast_route_s_g_stats_0;
    @name(".ipv4_multicast_route_star_g_stats") direct_counter(CounterType.packets) ipv4_multicast_route_star_g_stats_0;
    @name(".on_miss") action on_miss_11() {
    }
    @name(".multicast_bridge_s_g_hit") action multicast_bridge_s_g_hit_0(bit<16> mc_index) {
        meta.multicast_metadata.multicast_bridge_mc_index = mc_index;
        meta.multicast_metadata.mcast_bridge_hit = 1w1;
    }
    @name(".nop") action nop_29() {
    }
    @name(".multicast_bridge_star_g_hit") action multicast_bridge_star_g_hit_0(bit<16> mc_index) {
        meta.multicast_metadata.multicast_bridge_mc_index = mc_index;
        meta.multicast_metadata.mcast_bridge_hit = 1w1;
    }
    @name(".ipv4_multicast_bridge") table ipv4_multicast_bridge_0 {
        actions = {
            on_miss_11();
            multicast_bridge_s_g_hit_0();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.bd      : exact @name("meta.ingress_metadata.bd") ;
            meta.ipv4_metadata.lkp_ipv4_sa: exact @name("meta.ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("meta.ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".ipv4_multicast_bridge_star_g") table ipv4_multicast_bridge_star_g_0 {
        actions = {
            nop_29();
            multicast_bridge_star_g_hit_0();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.bd      : exact @name("meta.ingress_metadata.bd") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("meta.ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".on_miss") action on_miss_12() {
        ipv4_multicast_route_s_g_stats_0.count();
    }
    @name(".multicast_route_s_g_hit") action multicast_route_s_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        ipv4_multicast_route_s_g_stats_0.count();
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_mode = 2w1;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".ipv4_multicast_route") table ipv4_multicast_route_0 {
        actions = {
            on_miss_12();
            multicast_route_s_g_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("meta.l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_sa: exact @name("meta.ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("meta.ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 1024;
        @name(".ipv4_multicast_route_s_g_stats") counters = direct_counter(CounterType.packets);
        default_action = NoAction();
    }
    @name(".multicast_route_star_g_miss") action multicast_route_star_g_miss() {
        ipv4_multicast_route_star_g_stats_0.count();
        meta.l3_metadata.l3_copy = 1w1;
    }
    @name(".multicast_route_sm_star_g_hit") action multicast_route_sm_star_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        ipv4_multicast_route_star_g_stats_0.count();
        meta.multicast_metadata.mcast_mode = 2w1;
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".multicast_route_bidir_star_g_hit") action multicast_route_bidir_star_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        ipv4_multicast_route_star_g_stats_0.count();
        meta.multicast_metadata.mcast_mode = 2w2;
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group | meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".ipv4_multicast_route_star_g") table ipv4_multicast_route_star_g_0 {
        actions = {
            multicast_route_star_g_miss();
            multicast_route_sm_star_g_hit();
            multicast_route_bidir_star_g_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("meta.l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("meta.ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 1024;
        @name(".ipv4_multicast_route_star_g_stats") counters = direct_counter(CounterType.packets);
        default_action = NoAction();
    }
    apply {
        if ((meta.ingress_metadata.bypass_lookups & 16w0x1) == 16w0) 
            switch (ipv4_multicast_bridge_0.apply().action_run) {
                on_miss_11: {
                    ipv4_multicast_bridge_star_g_0.apply();
                }
            }

        if ((meta.ingress_metadata.bypass_lookups & 16w0x2) == 16w0 && meta.multicast_metadata.ipv4_multicast_enabled == 1w1) 
            switch (ipv4_multicast_route_0.apply().action_run) {
                on_miss_12: {
                    ipv4_multicast_route_star_g_0.apply();
                }
            }

    }
}

control process_ipv6_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".ipv6_multicast_route_s_g_stats") direct_counter(CounterType.packets) ipv6_multicast_route_s_g_stats_0;
    @name(".ipv6_multicast_route_star_g_stats") direct_counter(CounterType.packets) ipv6_multicast_route_star_g_stats_0;
    @name(".on_miss") action on_miss_13() {
    }
    @name(".multicast_bridge_s_g_hit") action multicast_bridge_s_g_hit_1(bit<16> mc_index) {
        meta.multicast_metadata.multicast_bridge_mc_index = mc_index;
        meta.multicast_metadata.mcast_bridge_hit = 1w1;
    }
    @name(".nop") action nop_30() {
    }
    @name(".multicast_bridge_star_g_hit") action multicast_bridge_star_g_hit_1(bit<16> mc_index) {
        meta.multicast_metadata.multicast_bridge_mc_index = mc_index;
        meta.multicast_metadata.mcast_bridge_hit = 1w1;
    }
    @name(".ipv6_multicast_bridge") table ipv6_multicast_bridge_0 {
        actions = {
            on_miss_13();
            multicast_bridge_s_g_hit_1();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.bd      : exact @name("meta.ingress_metadata.bd") ;
            meta.ipv6_metadata.lkp_ipv6_sa: exact @name("meta.ipv6_metadata.lkp_ipv6_sa") ;
            meta.ipv6_metadata.lkp_ipv6_da: exact @name("meta.ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".ipv6_multicast_bridge_star_g") table ipv6_multicast_bridge_star_g_0 {
        actions = {
            nop_30();
            multicast_bridge_star_g_hit_1();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.bd      : exact @name("meta.ingress_metadata.bd") ;
            meta.ipv6_metadata.lkp_ipv6_da: exact @name("meta.ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".on_miss") action on_miss_14() {
        ipv6_multicast_route_s_g_stats_0.count();
    }
    @name(".multicast_route_s_g_hit") action multicast_route_s_g_hit_2(bit<16> mc_index, bit<16> mcast_rpf_group) {
        ipv6_multicast_route_s_g_stats_0.count();
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_mode = 2w1;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".ipv6_multicast_route") table ipv6_multicast_route_0 {
        actions = {
            on_miss_14();
            multicast_route_s_g_hit_2();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("meta.l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_sa: exact @name("meta.ipv6_metadata.lkp_ipv6_sa") ;
            meta.ipv6_metadata.lkp_ipv6_da: exact @name("meta.ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 1024;
        @name(".ipv6_multicast_route_s_g_stats") counters = direct_counter(CounterType.packets);
        default_action = NoAction();
    }
    @name(".multicast_route_star_g_miss") action multicast_route_star_g_miss_2() {
        ipv6_multicast_route_star_g_stats_0.count();
        meta.l3_metadata.l3_copy = 1w1;
    }
    @name(".multicast_route_sm_star_g_hit") action multicast_route_sm_star_g_hit_2(bit<16> mc_index, bit<16> mcast_rpf_group) {
        ipv6_multicast_route_star_g_stats_0.count();
        meta.multicast_metadata.mcast_mode = 2w1;
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".multicast_route_bidir_star_g_hit") action multicast_route_bidir_star_g_hit_2(bit<16> mc_index, bit<16> mcast_rpf_group) {
        ipv6_multicast_route_star_g_stats_0.count();
        meta.multicast_metadata.mcast_mode = 2w2;
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group | meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".ipv6_multicast_route_star_g") table ipv6_multicast_route_star_g_0 {
        actions = {
            multicast_route_star_g_miss_2();
            multicast_route_sm_star_g_hit_2();
            multicast_route_bidir_star_g_hit_2();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("meta.l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_da: exact @name("meta.ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 1024;
        @name(".ipv6_multicast_route_star_g_stats") counters = direct_counter(CounterType.packets);
        default_action = NoAction();
    }
    apply {
        if ((meta.ingress_metadata.bypass_lookups & 16w0x1) == 16w0) 
            switch (ipv6_multicast_bridge_0.apply().action_run) {
                on_miss_13: {
                    ipv6_multicast_bridge_star_g_0.apply();
                }
            }

        if ((meta.ingress_metadata.bypass_lookups & 16w0x2) == 16w0 && meta.multicast_metadata.ipv6_multicast_enabled == 1w1) 
            switch (ipv6_multicast_route_0.apply().action_run) {
                on_miss_14: {
                    ipv6_multicast_route_star_g_0.apply();
                }
            }

    }
}

control process_multicast_rpf(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".process_ipv4_multicast") process_ipv4_multicast() process_ipv4_multicast_1;
    @name(".process_ipv6_multicast") process_ipv6_multicast() process_ipv6_multicast_1;
    @name(".process_multicast_rpf") process_multicast_rpf() process_multicast_rpf_1;
    apply {
        if (meta.l3_metadata.lkp_ip_type == 2w1) 
            process_ipv4_multicast_1.apply(hdr, meta, standard_metadata);
        else 
            if (meta.l3_metadata.lkp_ip_type == 2w2) 
                process_ipv6_multicast_1.apply(hdr, meta, standard_metadata);
        process_multicast_rpf_1.apply(hdr, meta, standard_metadata);
    }
}

control process_ingress_nat(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_meter_index(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".meter_index") direct_meter<bit<2>>(MeterType.bytes) meter_index_1;
    @name(".nop") action nop_31() {
        meter_index_1.read(meta.meter_metadata.packet_color);
    }
    @ternary(1) @name(".meter_index") table meter_index_2 {
        actions = {
            nop_31();
            @defaultonly NoAction();
        }
        key = {
            meta.meter_metadata.meter_index: exact @name("meta.meter_metadata.meter_index") ;
        }
        size = 1024;
        meters = meter_index_1;
        default_action = NoAction();
    }
    apply {
        if ((meta.ingress_metadata.bypass_lookups & 16w0x10) == 16w0) 
            meter_index_2.apply();
    }
}

control process_hashes(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<16> tmp_1;
    tuple<bit<32>, bit<32>, bit<8>, bit<16>, bit<16>> tmp_2;
    bit<16> tmp_3;
    tuple<bit<128>, bit<128>, bit<8>, bit<16>, bit<16>> tmp_4;
    bit<16> tmp_5;
    tuple<bit<16>, bit<48>, bit<48>, bit<16>> tmp_6;
    @name(".compute_lkp_ipv4_hash") action compute_lkp_ipv4_hash_0() {
        tmp_2 = { meta.ipv4_metadata.lkp_ipv4_sa, meta.ipv4_metadata.lkp_ipv4_da, meta.l3_metadata.lkp_ip_proto, meta.l3_metadata.lkp_l4_sport, meta.l3_metadata.lkp_l4_dport };
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>, bit<8>, bit<16>, bit<16>>, bit<32>>(tmp_1, HashAlgorithm.crc16, 16w0, tmp_2, 32w65536);
        meta.hash_metadata.hash1 = tmp_1;
    }
    @name(".compute_lkp_ipv6_hash") action compute_lkp_ipv6_hash_0() {
        tmp_4 = { meta.ipv6_metadata.lkp_ipv6_sa, meta.ipv6_metadata.lkp_ipv6_da, meta.l3_metadata.lkp_ip_proto, meta.l3_metadata.lkp_l4_sport, meta.l3_metadata.lkp_l4_dport };
        hash<bit<16>, bit<16>, tuple<bit<128>, bit<128>, bit<8>, bit<16>, bit<16>>, bit<32>>(tmp_3, HashAlgorithm.crc16, 16w0, tmp_4, 32w65536);
        meta.hash_metadata.hash1 = tmp_3;
    }
    @name(".compute_lkp_non_ip_hash") action compute_lkp_non_ip_hash_0() {
        tmp_6 = { meta.ingress_metadata.ifindex, meta.l2_metadata.lkp_mac_sa, meta.l2_metadata.lkp_mac_da, meta.l2_metadata.lkp_mac_type };
        hash<bit<16>, bit<16>, tuple<bit<16>, bit<48>, bit<48>, bit<16>>, bit<32>>(tmp_5, HashAlgorithm.crc16, 16w0, tmp_6, 32w65536);
        meta.hash_metadata.hash1 = tmp_5;
    }
    @name(".compute_other_hashes") action compute_other_hashes_1() {
        meta.hash_metadata.hash2 = meta.hash_metadata.hash1 >> 2;
        hdr.ig_intr_md_for_tm.level1_mcast_hash = (bit<13>)meta.hash_metadata.hash1;
        hdr.ig_intr_md_for_tm.level2_mcast_hash = (bit<13>)meta.hash_metadata.hash1 >> 3;
        meta.hash_metadata.entropy_hash = meta.hash_metadata.hash1;
    }
    @name(".compute_ipv4_hashes") table compute_ipv4_hashes_0 {
        actions = {
            compute_lkp_ipv4_hash_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.isValid(): exact @name("hdr.ethernet.isValid()") ;
        }
        default_action = NoAction();
    }
    @name(".compute_ipv6_hashes") table compute_ipv6_hashes_0 {
        actions = {
            compute_lkp_ipv6_hash_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.isValid(): exact @name("hdr.ethernet.isValid()") ;
        }
        default_action = NoAction();
    }
    @name(".compute_non_ip_hashes") table compute_non_ip_hashes_0 {
        actions = {
            compute_lkp_non_ip_hash_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.isValid(): exact @name("hdr.ethernet.isValid()") ;
        }
        default_action = NoAction();
    }
    @ternary(1) @name(".compute_other_hashes") table compute_other_hashes_2 {
        actions = {
            compute_other_hashes_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.isValid(): exact @name("hdr.ethernet.isValid()") ;
        }
        default_action = NoAction();
    }
    apply {
        if (meta.tunnel_metadata.tunnel_terminate == 1w0 && hdr.ipv4.isValid() || meta.tunnel_metadata.tunnel_terminate == 1w1 && hdr.inner_ipv4.isValid()) 
            compute_ipv4_hashes_0.apply();
        else 
            if (meta.tunnel_metadata.tunnel_terminate == 1w0 && hdr.ipv6.isValid() || meta.tunnel_metadata.tunnel_terminate == 1w1 && hdr.inner_ipv6.isValid()) 
                compute_ipv6_hashes_0.apply();
            else 
                compute_non_ip_hashes_0.apply();
        compute_other_hashes_2.apply();
    }
}

control process_meter_action(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".meter_stats") direct_counter(CounterType.packets) meter_stats_0;
    @name(".meter_permit") action meter_permit() {
        meter_stats_0.count();
    }
    @name(".meter_deny") action meter_deny() {
        meter_stats_0.count();
        mark_to_drop();
    }
    @name(".meter_action") table meter_action_0 {
        actions = {
            meter_permit();
            meter_deny();
            @defaultonly NoAction();
        }
        key = {
            meta.meter_metadata.packet_color: exact @name("meta.meter_metadata.packet_color") ;
            meta.meter_metadata.meter_index : exact @name("meta.meter_metadata.meter_index") ;
        }
        size = 1024;
        @name(".meter_stats") counters = direct_counter(CounterType.packets);
        default_action = NoAction();
    }
    apply {
        if ((meta.ingress_metadata.bypass_lookups & 16w0x10) == 16w0) 
            meter_action_0.apply();
    }
}

control process_telemetry_watchlist(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ingress_bd_stats(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".ingress_bd_stats") @min_width(32) counter(32w1024, CounterType.packets_and_bytes) ingress_bd_stats_1;
    @name(".update_ingress_bd_stats") action update_ingress_bd_stats_0() {
        ingress_bd_stats_1.count((bit<32>)meta.l2_metadata.bd_stats_idx);
    }
    @name(".ingress_bd_stats") table ingress_bd_stats_2 {
        actions = {
            update_ingress_bd_stats_0();
            @defaultonly NoAction();
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        ingress_bd_stats_2.apply();
    }
}

control process_ingress_acl_stats(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".acl_stats") @min_width(16) counter(32w1024, CounterType.packets_and_bytes) acl_stats_1;
    @name(".acl_stats_update") action acl_stats_update_0() {
        acl_stats_1.count((bit<32>)meta.acl_metadata.acl_stats_index);
    }
    @name(".acl_stats") table acl_stats_2 {
        actions = {
            acl_stats_update_0();
            @defaultonly NoAction();
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        acl_stats_2.apply();
    }
}

control process_storm_control_stats(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".storm_control_stats") direct_counter(CounterType.packets) storm_control_stats_1;
    @name(".nop") action nop_32() {
        storm_control_stats_1.count();
    }
    @name(".storm_control_stats") table storm_control_stats_2 {
        actions = {
            nop_32();
            @defaultonly NoAction();
        }
        key = {
            meta.meter_metadata.packet_color: exact @name("meta.meter_metadata.packet_color") ;
            hdr.ig_intr_md.ingress_port     : exact @name("hdr.ig_intr_md.ingress_port") ;
        }
        size = 1024;
        @name(".storm_control_stats") counters = direct_counter(CounterType.packets);
        default_action = NoAction();
    }
    apply {
        storm_control_stats_2.apply();
    }
}

control process_fwd_results(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_33() {
    }
    @name(".set_l2_redirect_action") action set_l2_redirect_action_0() {
        meta.l3_metadata.nexthop_index = meta.l2_metadata.l2_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.l2_metadata.l2_nexthop_type;
        meta.ingress_metadata.egress_ifindex = 16w0;
        invalidate<bit<16>>(hdr.ig_intr_md_for_tm.mcast_grp_b);
        meta.ingress_metadata.egress_port_lag_index = 10w0;
    }
    @name(".set_fib_redirect_action") action set_fib_redirect_action_0() {
        meta.l3_metadata.nexthop_index = meta.l3_metadata.fib_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.l3_metadata.fib_nexthop_type;
        meta.l3_metadata.routed = 1w1;
        invalidate<bit<16>>(hdr.ig_intr_md_for_tm.mcast_grp_b);
        meta.fabric_metadata.reason_code = 16w0x217;
    }
    @name(".set_cpu_redirect_action") action set_cpu_redirect_action_0(bit<10> cpu_ifindex) {
        meta.l3_metadata.routed = 1w0;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.ingress_metadata.egress_port_lag_index = cpu_ifindex;
    }
    @name(".set_acl_redirect_action") action set_acl_redirect_action_0() {
        meta.l3_metadata.nexthop_index = meta.acl_metadata.acl_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.acl_metadata.acl_nexthop_type;
        meta.ingress_metadata.egress_ifindex = 16w0;
        invalidate<bit<16>>(hdr.ig_intr_md_for_tm.mcast_grp_b);
        meta.ingress_metadata.egress_port_lag_index = 10w0;
    }
    @name(".set_racl_redirect_action") action set_racl_redirect_action_0() {
        meta.l3_metadata.nexthop_index = meta.acl_metadata.racl_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.acl_metadata.racl_nexthop_type;
        meta.l3_metadata.routed = 1w1;
        meta.ingress_metadata.egress_ifindex = 16w0;
        invalidate<bit<16>>(hdr.ig_intr_md_for_tm.mcast_grp_b);
        meta.ingress_metadata.egress_port_lag_index = 10w0;
    }
    @name(".set_multicast_route_action") action set_multicast_route_action_0() {
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.ingress_metadata.egress_port_lag_index = 10w0;
        hdr.ig_intr_md_for_tm.mcast_grp_b = meta.multicast_metadata.multicast_route_mc_index;
        meta.l3_metadata.routed = 1w1;
        meta.l3_metadata.same_bd_check = 16w0xffff;
    }
    @name(".set_multicast_bridge_action") action set_multicast_bridge_action_0() {
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.ingress_metadata.egress_port_lag_index = 10w0;
        hdr.ig_intr_md_for_tm.mcast_grp_b = meta.multicast_metadata.multicast_bridge_mc_index;
    }
    @name(".set_multicast_flood") action set_multicast_flood_0() {
        meta.ingress_metadata.egress_ifindex = 16w65535;
    }
    @name(".set_multicast_drop") action set_multicast_drop_0() {
        meta.ingress_metadata.drop_flag = 1w1;
        meta.ingress_metadata.drop_reason = 8w59;
    }
    @name(".fwd_result") table fwd_result_0 {
        actions = {
            nop_33();
            set_l2_redirect_action_0();
            set_fib_redirect_action_0();
            set_cpu_redirect_action_0();
            set_acl_redirect_action_0();
            set_racl_redirect_action_0();
            set_multicast_route_action_0();
            set_multicast_bridge_action_0();
            set_multicast_flood_0();
            set_multicast_drop_0();
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
            fwd_result_0.apply();
    }
}

control process_flowlet(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_nexthop(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_34() {
    }
    @name(".set_ecmp_nexthop_details") action set_ecmp_nexthop_details_0(bit<16> ifindex, bit<10> port_lag_index, bit<16> bd, bit<16> nhop_index, bit<1> tunnel) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.ingress_metadata.egress_port_lag_index = port_lag_index;
        meta.l3_metadata.nexthop_index = nhop_index;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.l2_metadata.same_if_check = meta.l2_metadata.same_if_check ^ ifindex;
        meta.tunnel_metadata.tunnel_if_check = meta.tunnel_metadata.tunnel_terminate ^ tunnel;
        hdr.ig_intr_md_for_tm.disable_ucast_cutthru = meta.l2_metadata.non_ip_packet & tunnel;
    }
    @name(".set_ecmp_nexthop_details_with_tunnel") action set_ecmp_nexthop_details_with_tunnel_0(bit<16> bd, bit<14> tunnel_index, bit<1> tunnel) {
        meta.tunnel_metadata.tunnel_if_check = meta.tunnel_metadata.tunnel_terminate ^ tunnel;
        hdr.ig_intr_md_for_tm.disable_ucast_cutthru = meta.l2_metadata.non_ip_packet & tunnel;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
        meta.ingress_metadata.egress_ifindex = 16w0x0;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
    }
    @name(".set_ecmp_nexthop_details_for_post_routed_flood") action set_ecmp_nexthop_details_for_post_routed_flood_0(bit<16> bd, bit<16> uuc_mc_index, bit<16> nhop_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_b = uuc_mc_index;
        meta.l3_metadata.nexthop_index = nhop_index;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.ingress_metadata.egress_port_lag_index = 10w0;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
    }
    @name(".set_nexthop_details") action set_nexthop_details_0(bit<16> ifindex, bit<10> port_lag_index, bit<16> bd, bit<1> tunnel) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.ingress_metadata.egress_port_lag_index = port_lag_index;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.l2_metadata.same_if_check = meta.l2_metadata.same_if_check ^ ifindex;
        meta.tunnel_metadata.tunnel_if_check = meta.tunnel_metadata.tunnel_terminate ^ tunnel;
        hdr.ig_intr_md_for_tm.disable_ucast_cutthru = meta.l2_metadata.non_ip_packet & tunnel;
    }
    @name(".set_nexthop_details_with_tunnel") action set_nexthop_details_with_tunnel_0(bit<16> bd, bit<14> tunnel_index, bit<1> tunnel) {
        meta.tunnel_metadata.tunnel_if_check = meta.tunnel_metadata.tunnel_terminate ^ tunnel;
        hdr.ig_intr_md_for_tm.disable_ucast_cutthru = meta.l2_metadata.non_ip_packet & tunnel;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
        meta.ingress_metadata.egress_ifindex = 16w0x0;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
    }
    @name(".set_nexthop_details_for_post_routed_flood") action set_nexthop_details_for_post_routed_flood_0(bit<16> bd, bit<16> uuc_mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_b = uuc_mc_index;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.ingress_metadata.egress_port_lag_index = 10w0;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
    }
    @name(".ecmp_group") table ecmp_group_0 {
        actions = {
            nop_34();
            set_ecmp_nexthop_details_0();
            set_ecmp_nexthop_details_with_tunnel_0();
            set_ecmp_nexthop_details_for_post_routed_flood_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.nexthop_index: exact @name("meta.l3_metadata.nexthop_index") ;
            meta.hash_metadata.hash1      : selector @name("meta.hash_metadata.hash1") ;
        }
        size = 1024;
        @name(".ecmp_action_profile") @mode("fair") implementation = action_selector(HashAlgorithm.identity, 32w1024, 32w14);
        default_action = NoAction();
    }
    @name(".nexthop") table nexthop_0 {
        actions = {
            nop_34();
            set_nexthop_details_0();
            set_nexthop_details_with_tunnel_0();
            set_nexthop_details_for_post_routed_flood_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.nexthop_index: exact @name("meta.l3_metadata.nexthop_index") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        if (meta.nexthop_metadata.nexthop_type == 1w1) 
            ecmp_group_0.apply();
        else 
            nexthop_0.apply();
    }
}

control process_multicast_flooding(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_35() {
    }
    @name(".set_bd_flood_mc_index") action set_bd_flood_mc_index_0(bit<16> mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_b = mc_index;
    }
    @name(".bd_flood") table bd_flood_0 {
        actions = {
            nop_35();
            set_bd_flood_mc_index_0();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.bd     : exact @name("meta.ingress_metadata.bd") ;
            meta.l2_metadata.lkp_pkt_type: exact @name("meta.l2_metadata.lkp_pkt_type") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        bd_flood_0.apply();
    }
}

control process_tunnel_id(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_36() {
    }
    @name(".set_tunnel_mgid") action set_tunnel_mgid_0(bit<16> mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_b = mc_index;
    }
    @ternary(1) @name(".tunnel_to_mgid_mapping") table tunnel_to_mgid_mapping_0 {
        actions = {
            nop_36();
            set_tunnel_mgid_0();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.tunnel_index: exact @name("meta.tunnel_metadata.tunnel_index") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        tunnel_to_mgid_mapping_0.apply();
    }
}

control process_lag(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_lag_miss") action set_lag_miss_0() {
    }
    @name(".set_lag_port") action set_lag_port_0(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".lag_group") table lag_group_0 {
        actions = {
            set_lag_miss_0();
            set_lag_port_0();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.egress_port_lag_index: exact @name("meta.ingress_metadata.egress_port_lag_index") ;
            meta.hash_metadata.hash2                   : selector @name("meta.hash_metadata.hash2") ;
        }
        size = 1024;
        @name(".lag_action_profile") @mode("fair") implementation = action_selector(HashAlgorithm.identity, 32w1024, 32w14);
        default_action = NoAction();
    }
    apply {
        lag_group_0.apply();
    }
}

@name("mac_learn_digest") struct mac_learn_digest {
    bit<16> bd;
    bit<48> lkp_mac_sa;
    bit<16> ifindex;
}

control process_mac_learning(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop_37() {
    }
    @name(".generate_learn_notify") action generate_learn_notify_0() {
        digest<mac_learn_digest>(32w0, { meta.ingress_metadata.bd, meta.l2_metadata.lkp_mac_sa, meta.ingress_metadata.ifindex });
    }
    @name(".learn_notify") table learn_notify_0 {
        actions = {
            nop_37();
            generate_learn_notify_0();
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
            learn_notify_0.apply();
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
    @name(".drop_stats") counter(32w1024, CounterType.packets) drop_stats_1;
    @name(".drop_stats_2") counter(32w1024, CounterType.packets) drop_stats_3;
    @name(".drop_stats_update") action drop_stats_update_0() {
        drop_stats_3.count((bit<32>)meta.ingress_metadata.drop_reason);
    }
    @name(".nop") action nop_38() {
    }
    @name(".copy_to_cpu") action copy_to_cpu_0(bit<5> qid, bit<8> meter_id, bit<3> icos) {
        hdr.ig_intr_md_for_tm.qid = qid;
        hdr.ig_intr_md_for_tm.ingress_cos = icos;
        hdr.ig_intr_md_for_tm.copy_to_cpu = 1w1;
    }
    @name(".redirect_to_cpu") action redirect_to_cpu_0(bit<5> qid, bit<8> meter_id, bit<3> icos) {
        copy_to_cpu_0(qid, meter_id, icos);
        mark_to_drop();
    }
    @name(".copy_to_cpu_with_reason") action copy_to_cpu_with_reason_0(bit<16> reason_code, bit<5> qid, bit<8> meter_id, bit<3> icos) {
        meta.fabric_metadata.reason_code = reason_code;
        copy_to_cpu_0(qid, meter_id, icos);
    }
    @name(".redirect_to_cpu_with_reason") action redirect_to_cpu_with_reason_0(bit<16> reason_code, bit<5> qid, bit<8> meter_id, bit<3> icos) {
        copy_to_cpu_with_reason_0(reason_code, qid, meter_id, icos);
        mark_to_drop();
    }
    @name(".drop_packet") action drop_packet_1() {
        mark_to_drop();
    }
    @name(".drop_packet_with_reason") action drop_packet_with_reason_0(bit<32> drop_reason) {
        drop_stats_1.count(drop_reason);
        mark_to_drop();
    }
    @name(".drop_stats") table drop_stats_4 {
        actions = {
            drop_stats_update_0();
            @defaultonly NoAction();
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".system_acl") table system_acl_0 {
        actions = {
            nop_38();
            redirect_to_cpu_0();
            redirect_to_cpu_with_reason_0();
            copy_to_cpu_0();
            copy_to_cpu_with_reason_0();
            drop_packet_1();
            drop_packet_with_reason_0();
            @defaultonly NoAction();
        }
        key = {
            meta.acl_metadata.port_lag_label         : ternary @name("meta.acl_metadata.port_lag_label") ;
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
            system_acl_0.apply();
            if (meta.ingress_metadata.drop_flag == 1w1) 
                drop_stats_4.apply();
        }
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".rmac_hit") action rmac_hit_0() {
        meta.l3_metadata.rmac_hit = 1w1;
    }
    @name(".rmac_miss") action rmac_miss_0() {
        meta.l3_metadata.rmac_hit = 1w0;
    }
    @name(".rmac") table rmac_0 {
        actions = {
            rmac_hit_0();
            rmac_miss_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.rmac_group: exact @name("meta.l3_metadata.rmac_group") ;
            meta.l2_metadata.lkp_mac_da: exact @name("meta.l2_metadata.lkp_mac_da") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".process_ingress_port_mapping") process_ingress_port_mapping() process_ingress_port_mapping_1;
    @name(".process_global_params") process_global_params() process_global_params_1;
    @name(".process_validate_outer_header") process_validate_outer_header() process_validate_outer_header_1;
    @name(".process_telemetry_ingress_prepare") process_telemetry_ingress_prepare() process_telemetry_ingress_prepare_1;
    @name(".process_bfd_rx_packet") process_bfd_rx_packet() process_bfd_rx_packet_1;
    @name(".process_port_vlan_mapping") process_port_vlan_mapping() process_port_vlan_mapping_1;
    @name(".process_telemetry_int_sink") process_telemetry_int_sink() process_telemetry_int_sink_1;
    @name(".process_ingress_qos_map") process_ingress_qos_map() process_ingress_qos_map_1;
    @name(".process_srv6") process_srv6() process_srv6_1;
    @name(".process_tunnel") process_tunnel() process_tunnel_1;
    @name(".process_ip_sourceguard") process_ip_sourceguard() process_ip_sourceguard_1;
    @name(".process_ingress_sflow") process_ingress_sflow() process_ingress_sflow_1;
    @name(".process_storm_control") process_storm_control() process_storm_control_1;
    @name(".process_spanning_tree") process_spanning_tree() process_spanning_tree_1;
    @name(".process_bfd_packet") process_bfd_packet() process_bfd_packet_1;
    @name(".process_validate_packet") process_validate_packet() process_validate_packet_1;
    @name(".process_ingress_l4port") process_ingress_l4port() process_ingress_l4port_1;
    @name(".process_mac") process_mac() process_mac_1;
    @name(".process_mac_acl") process_mac_acl() process_mac_acl_1;
    @name(".process_ip_acl") process_ip_acl() process_ip_acl_1;
    @name(".process_ingress_port_mirroring") process_ingress_port_mirroring() process_ingress_port_mirroring_1;
    @name(".process_telemetry_int_upstream_report") process_telemetry_int_upstream_report() process_telemetry_int_upstream_report_1;
    @name(".process_ipv4_racl") process_ipv4_racl() process_ipv4_racl_1;
    @name(".process_ipv4_urpf") process_ipv4_urpf() process_ipv4_urpf_1;
    @name(".process_ipv4_fib") process_ipv4_fib() process_ipv4_fib_1;
    @name(".process_ipv6_racl") process_ipv6_racl() process_ipv6_racl_1;
    @name(".process_ipv6_urpf") process_ipv6_urpf() process_ipv6_urpf_1;
    @name(".process_ipv6_fib") process_ipv6_fib() process_ipv6_fib_1;
    @name(".process_urpf_bd") process_urpf_bd() process_urpf_bd_1;
    @name(".process_multicast") process_multicast() process_multicast_1;
    @name(".process_ingress_nat") process_ingress_nat() process_ingress_nat_1;
    @name(".process_meter_index") process_meter_index() process_meter_index_1;
    @name(".process_hashes") process_hashes() process_hashes_1;
    @name(".process_meter_action") process_meter_action() process_meter_action_1;
    @name(".process_telemetry_watchlist") process_telemetry_watchlist() process_telemetry_watchlist_1;
    @name(".process_ingress_bd_stats") process_ingress_bd_stats() process_ingress_bd_stats_1;
    @name(".process_ingress_acl_stats") process_ingress_acl_stats() process_ingress_acl_stats_1;
    @name(".process_storm_control_stats") process_storm_control_stats() process_storm_control_stats_1;
    @name(".process_fwd_results") process_fwd_results() process_fwd_results_1;
    @name(".process_flowlet") process_flowlet() process_flowlet_1;
    @name(".process_nexthop") process_nexthop() process_nexthop_1;
    @name(".process_multicast_flooding") process_multicast_flooding() process_multicast_flooding_1;
    @name(".process_tunnel_id") process_tunnel_id() process_tunnel_id_1;
    @name(".process_lag") process_lag() process_lag_1;
    @name(".process_mac_learning") process_mac_learning() process_mac_learning_1;
    @name(".process_fabric_lag") process_fabric_lag() process_fabric_lag_1;
    @name(".process_traffic_class") process_traffic_class() process_traffic_class_1;
    @name(".process_system_acl") process_system_acl() process_system_acl_1;
    apply {
        process_ingress_port_mapping_1.apply(hdr, meta, standard_metadata);
        process_global_params_1.apply(hdr, meta, standard_metadata);
        process_validate_outer_header_1.apply(hdr, meta, standard_metadata);
        process_telemetry_ingress_prepare_1.apply(hdr, meta, standard_metadata);
        process_bfd_rx_packet_1.apply(hdr, meta, standard_metadata);
        process_port_vlan_mapping_1.apply(hdr, meta, standard_metadata);
        process_telemetry_int_sink_1.apply(hdr, meta, standard_metadata);
        process_ingress_qos_map_1.apply(hdr, meta, standard_metadata);
        process_srv6_1.apply(hdr, meta, standard_metadata);
        process_tunnel_1.apply(hdr, meta, standard_metadata);
        process_ip_sourceguard_1.apply(hdr, meta, standard_metadata);
        process_ingress_sflow_1.apply(hdr, meta, standard_metadata);
        process_storm_control_1.apply(hdr, meta, standard_metadata);
        process_spanning_tree_1.apply(hdr, meta, standard_metadata);
        process_bfd_packet_1.apply(hdr, meta, standard_metadata);
        if (meta.ingress_metadata.port_type != 2w1) 
            if (!(hdr.mpls[0].isValid() && meta.l3_metadata.fib_hit == 1w1)) {
                process_validate_packet_1.apply(hdr, meta, standard_metadata);
                process_ingress_l4port_1.apply(hdr, meta, standard_metadata);
                process_mac_1.apply(hdr, meta, standard_metadata);
                if (meta.l3_metadata.lkp_ip_type == 2w0) 
                    process_mac_acl_1.apply(hdr, meta, standard_metadata);
                else 
                    process_ip_acl_1.apply(hdr, meta, standard_metadata);
                process_ingress_port_mirroring_1.apply(hdr, meta, standard_metadata);
                process_telemetry_int_upstream_report_1.apply(hdr, meta, standard_metadata);
                switch (rmac_0.apply().action_run) {
                    default: {
                        if ((meta.ingress_metadata.bypass_lookups & 16w0x2) == 16w0) {
                            if (meta.l3_metadata.lkp_ip_type == 2w1 && meta.ipv4_metadata.ipv4_unicast_enabled == 1w1) {
                                process_ipv4_racl_1.apply(hdr, meta, standard_metadata);
                                process_ipv4_urpf_1.apply(hdr, meta, standard_metadata);
                                process_ipv4_fib_1.apply(hdr, meta, standard_metadata);
                            }
                            else 
                                if (meta.l3_metadata.lkp_ip_type == 2w2 && meta.ipv6_metadata.ipv6_unicast_enabled == 1w1) {
                                    process_ipv6_racl_1.apply(hdr, meta, standard_metadata);
                                    process_ipv6_urpf_1.apply(hdr, meta, standard_metadata);
                                    process_ipv6_fib_1.apply(hdr, meta, standard_metadata);
                                }
                            process_urpf_bd_1.apply(hdr, meta, standard_metadata);
                        }
                    }
                    rmac_miss_0: {
                        process_multicast_1.apply(hdr, meta, standard_metadata);
                    }
                }

                process_ingress_nat_1.apply(hdr, meta, standard_metadata);
            }
        process_meter_index_1.apply(hdr, meta, standard_metadata);
        process_hashes_1.apply(hdr, meta, standard_metadata);
        process_meter_action_1.apply(hdr, meta, standard_metadata);
        process_telemetry_watchlist_1.apply(hdr, meta, standard_metadata);
        if (meta.ingress_metadata.port_type != 2w1) {
            process_ingress_bd_stats_1.apply(hdr, meta, standard_metadata);
            process_ingress_acl_stats_1.apply(hdr, meta, standard_metadata);
            process_storm_control_stats_1.apply(hdr, meta, standard_metadata);
            process_fwd_results_1.apply(hdr, meta, standard_metadata);
            process_flowlet_1.apply(hdr, meta, standard_metadata);
            process_nexthop_1.apply(hdr, meta, standard_metadata);
            if (meta.ingress_metadata.egress_ifindex == 16w65535) 
                process_multicast_flooding_1.apply(hdr, meta, standard_metadata);
            else 
                if (meta.tunnel_metadata.tunnel_index != 14w0) 
                    process_tunnel_id_1.apply(hdr, meta, standard_metadata);
                else 
                    process_lag_1.apply(hdr, meta, standard_metadata);
            process_mac_learning_1.apply(hdr, meta, standard_metadata);
        }
        process_fabric_lag_1.apply(hdr, meta, standard_metadata);
        process_traffic_class_1.apply(hdr, meta, standard_metadata);
        if (meta.ingress_metadata.port_type != 2w1) 
            process_system_acl_1.apply(hdr, meta, standard_metadata);
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

control verifyChecksum(in headers hdr, inout metadata meta) {
    bit<16> tmp_7;
    bool tmp_8;
    bit<16> tmp_9;
    bool tmp_10;
    @name("inner_ipv4_checksum") Checksum16() inner_ipv4_checksum_0;
    @name("ipv4_checksum") Checksum16() ipv4_checksum_0;
    apply {
        tmp_7 = inner_ipv4_checksum_0.get<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>>({ hdr.inner_ipv4.version, hdr.inner_ipv4.ihl, hdr.inner_ipv4.diffserv, hdr.inner_ipv4.totalLen, hdr.inner_ipv4.identification, hdr.inner_ipv4.flags, hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.ttl, hdr.inner_ipv4.protocol, hdr.inner_ipv4.srcAddr, hdr.inner_ipv4.dstAddr });
        tmp_8 = hdr.inner_ipv4.hdrChecksum == tmp_7;
        if (tmp_8) 
            mark_to_drop();
        tmp_9 = ipv4_checksum_0.get<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr });
        tmp_10 = hdr.ipv4.hdrChecksum == tmp_9;
        if (tmp_10) 
            mark_to_drop();
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    bit<16> tmp_11;
    bit<16> tmp_12;
    @name("inner_ipv4_checksum") Checksum16() inner_ipv4_checksum_1;
    @name("ipv4_checksum") Checksum16() ipv4_checksum_1;
    apply {
        tmp_11 = inner_ipv4_checksum_1.get<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>>({ hdr.inner_ipv4.version, hdr.inner_ipv4.ihl, hdr.inner_ipv4.diffserv, hdr.inner_ipv4.totalLen, hdr.inner_ipv4.identification, hdr.inner_ipv4.flags, hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.ttl, hdr.inner_ipv4.protocol, hdr.inner_ipv4.srcAddr, hdr.inner_ipv4.dstAddr });
        hdr.inner_ipv4.hdrChecksum = tmp_11;
        tmp_12 = ipv4_checksum_1.get<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr });
        hdr.ipv4.hdrChecksum = tmp_12;
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
