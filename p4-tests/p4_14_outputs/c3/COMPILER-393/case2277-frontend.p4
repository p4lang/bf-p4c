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
    bit<16> bd;
    bit<16> outer_bd;
    bit<48> mac_da;
    bit<1>  routed;
    bit<16> same_bd_check;
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
    bit<1>  src_vtep_hit;
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
    bit<8>  flow_id;
}

header pktgen_generic_header_t {
    bit<3>  _pad0;
    bit<2>  pipe_id;
    bit<3>  app_id;
    bit<8>  key_msb;
    bit<16> batch_id;
    bit<16> packet_id;
}

header pktgen_port_down_header_t {
    bit<3>  _pad0;
    bit<2>  pipe_id;
    bit<3>  app_id;
    bit<15> _pad1;
    bit<9>  port_num;
    bit<16> packet_id;
}

header pktgen_recirc_header_t {
    bit<3>  _pad0;
    bit<2>  pipe_id;
    bit<3>  app_id;
    bit<24> key;
    bit<16> packet_id;
}

header pktgen_timer_header_t {
    bit<3>  _pad0;
    bit<2>  pipe_id;
    bit<3>  app_id;
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
    @pa_solitary("ingress", "acl_metadata.if_label") @pa_atomic("ingress", "acl_metadata.if_label") @name(".acl_metadata") 
    acl_metadata_t           acl_metadata;
    @name(".egress_metadata") 
    egress_metadata_t        egress_metadata;
    @name(".fabric_metadata") 
    fabric_metadata_t        fabric_metadata;
    @pa_atomic("ingress", "flowlet_metadata.id") @name(".flowlet_metadata") 
    flowlet_metadata_t       flowlet_metadata;
    @name(".global_config_metadata") 
    global_config_metadata_t global_config_metadata;
    @pa_atomic("ingress", "hash_metadata.hash1") @pa_solitary("ingress", "hash_metadata.hash1") @pa_atomic("ingress", "hash_metadata.hash2") @pa_solitary("ingress", "hash_metadata.hash2") @name(".hash_metadata") 
    hash_metadata_t          hash_metadata;
    @name(".i2e_metadata") 
    i2e_metadata_t           i2e_metadata;
    @pa_atomic("ingress", "ingress_metadata.port_type") @pa_solitary("ingress", "ingress_metadata.port_type") @pa_atomic("ingress", "ingress_metadata.ifindex") @pa_solitary("ingress", "ingress_metadata.ifindex") @pa_atomic("egress", "ingress_metadata.bd") @pa_solitary("egress", "ingress_metadata.bd") @name(".ingress_metadata") 
    ingress_metadata_t       ingress_metadata;
    @name(".intrinsic_metadata") 
    intrinsic_metadata_t     intrinsic_metadata;
    @name(".ipv4_metadata") 
    ipv4_metadata_t          ipv4_metadata;
    @pa_alias("ingress", "ipv4_metadata.lkp_ipv4_sa", "ipv6_metadata.lkp_ipv6_sa") @pa_alias("ingress", "ipv4_metadata.lkp_ipv4_da", "ipv6_metadata.lkp_ipv6_da") @pa_mutually_exclusive("ingress", "ipv4_metadata.lkp_ipv4_sa", "ipv6_metadata.lkp_ipv6_sa") @pa_mutually_exclusive("ingress", "ipv4_metadata.lkp_ipv4_da", "ipv6_metadata.lkp_ipv6_da") @name(".ipv6_metadata") 
    ipv6_metadata_t          ipv6_metadata;
    @name(".l2_metadata") 
    l2_metadata_t            l2_metadata;
    @name(".l3_metadata") 
    l3_metadata_t            l3_metadata;
    @name(".meter_metadata") 
    meter_metadata_t         meter_metadata;
    @pa_solitary("ingress", "multicast_metadata.multicast_route_mc_index") @pa_atomic("ingress", "multicast_metadata.multicast_route_mc_index") @pa_solitary("ingress", "multicast_metadata.multicast_bridge_mc_index") @pa_atomic("ingress", "multicast_metadata.multicast_bridge_mc_index") @name(".multicast_metadata") 
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
    @name(".fabric_header_bfd") 
    fabric_header_bfd_event_t                      fabric_header_bfd;
    @name(".fabric_header_cpu") 
    fabric_header_cpu_t                            fabric_header_cpu;
    @name(".fabric_header_mirror") 
    fabric_header_mirror_t                         fabric_header_mirror;
    @name(".fabric_header_multicast") 
    fabric_header_multicast_t                      fabric_header_multicast;
    @name(".fabric_header_sflow") 
    fabric_header_sflow_t                          fabric_header_sflow;
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
    @pa_fragment("ingress", "inner_ipv4.hdrChecksum") @pa_fragment("egress", "inner_ipv4.hdrChecksum") @name(".inner_ipv4") 
    ipv4_t                                         inner_ipv4;
    @name(".inner_ipv6") 
    ipv6_t                                         inner_ipv6;
    @name(".inner_sctp") 
    sctp_t                                         inner_sctp;
    @pa_alias("egress", "inner_tcp", "tcp") @pa_fragment("egress", "inner_tcp.checksum") @pa_fragment("egress", "inner_tcp.urgentPtr") @name(".inner_tcp") 
    tcp_t                                          inner_tcp;
    @name(".inner_udp") 
    udp_t                                          inner_udp;
    @pa_fragment("ingress", "ipv4.hdrChecksum") @pa_fragment("egress", "ipv4.hdrChecksum") @name(".ipv4") 
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
    @name(".pktgen_generic") 
    pktgen_generic_header_t                        pktgen_generic;
    @name(".pktgen_port_down") 
    pktgen_port_down_header_t                      pktgen_port_down;
    @name(".pktgen_recirc") 
    pktgen_recirc_header_t                         pktgen_recirc;
    @name(".pktgen_timer") 
    pktgen_timer_header_t                          pktgen_timer;
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
    @name(".snap_header") 
    snap_header_t                                  snap_header;
    @pa_fragment("egress", "tcp.checksum") @pa_fragment("egress", "tcp.urgentPtr") @name(".tcp") 
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
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<112> tmp_0;
    @name(".parse_arp_rarp") state parse_arp_rarp {
        transition parse_set_prio_med;
    }
    @name(".parse_erspan_t3") state parse_erspan_t3 {
        packet.extract<erspan_header_t3_t_0>(hdr.erspan_t3_header);
        transition select(hdr.erspan_t3_header.ft_d_other) {
            16w0 &&& 16w0x7c01: parse_inner_ethernet;
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
        transition accept;
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

@name(".bd_action_profile") action_profile(32w16384) bd_action_profile;

@name(".ecmp_action_profile") @mode("fair") action_selector(HashAlgorithm.identity, 32w16384, 32w14) ecmp_action_profile;

@name(".lag_action_profile") @mode("fair") action_selector(HashAlgorithm.identity, 32w1024, 32w14) lag_action_profile;

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_1() {
    }
    @name(".NoAction") action NoAction_98() {
    }
    @name(".NoAction") action NoAction_99() {
    }
    @name(".NoAction") action NoAction_100() {
    }
    @name(".NoAction") action NoAction_101() {
    }
    @name(".NoAction") action NoAction_102() {
    }
    @name(".NoAction") action NoAction_103() {
    }
    @name(".NoAction") action NoAction_104() {
    }
    @name(".NoAction") action NoAction_105() {
    }
    @name(".NoAction") action NoAction_106() {
    }
    @name(".NoAction") action NoAction_107() {
    }
    @name(".NoAction") action NoAction_108() {
    }
    @name(".NoAction") action NoAction_109() {
    }
    @name(".NoAction") action NoAction_110() {
    }
    @name(".NoAction") action NoAction_111() {
    }
    @name(".NoAction") action NoAction_112() {
    }
    @name(".NoAction") action NoAction_113() {
    }
    @name(".NoAction") action NoAction_114() {
    }
    @name(".NoAction") action NoAction_115() {
    }
    @name(".NoAction") action NoAction_116() {
    }
    @name(".NoAction") action NoAction_117() {
    }
    @name(".NoAction") action NoAction_118() {
    }
    @name(".NoAction") action NoAction_119() {
    }
    @name(".NoAction") action NoAction_120() {
    }
    @name(".NoAction") action NoAction_121() {
    }
    @name(".NoAction") action NoAction_122() {
    }
    @name(".NoAction") action NoAction_123() {
    }
    @name(".egress_port_type_normal") action egress_port_type_normal_0(bit<16> ifindex, bit<5> qos_group, bit<16> if_label) {
        meta.egress_metadata.port_type = 2w0;
        meta.egress_metadata.ifindex = ifindex;
        meta.qos_metadata.egress_qos_group = qos_group;
        meta.acl_metadata.egress_if_label = if_label;
        meta.l3_metadata.l3_mtu_check = 16w0xffff;
    }
    @name(".egress_port_type_fabric") action egress_port_type_fabric_0(bit<16> ifindex) {
        meta.egress_metadata.port_type = 2w1;
        meta.egress_metadata.ifindex = ifindex;
        meta.tunnel_metadata.egress_tunnel_type = 5w15;
        meta.l3_metadata.l3_mtu_check = 16w0xffff;
    }
    @name(".egress_port_type_cpu") action egress_port_type_cpu_0(bit<16> ifindex) {
        meta.egress_metadata.port_type = 2w2;
        meta.egress_metadata.ifindex = ifindex;
        meta.tunnel_metadata.egress_tunnel_type = 5w16;
        meta.l3_metadata.l3_mtu_check = 16w0xffff;
    }
    @name(".egress_port_mapping") table egress_port_mapping {
        actions = {
            egress_port_type_normal_0();
            egress_port_type_fabric_0();
            egress_port_type_cpu_0();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        size = 288;
        default_action = NoAction_0();
    }
    @name(".nop") action _nop_8() {
    }
    @name(".set_mirror_nhop") action _set_mirror_nhop(bit<16> nhop_idx) {
        meta.l3_metadata.nexthop_index = nhop_idx;
    }
    @name(".set_mirror_bd") action _set_mirror_bd(bit<16> bd) {
        meta.egress_metadata.bd = bd;
    }
    @ternary(1) @name(".mirror") table _mirror_0 {
        actions = {
            _nop_8();
            _set_mirror_nhop();
            _set_mirror_bd();
            @defaultonly NoAction_1();
        }
        key = {
            meta.i2e_metadata.mirror_session_id: exact @name("i2e_metadata.mirror_session_id") ;
        }
        size = 1024;
        default_action = NoAction_1();
    }
    @name(".nop") action _nop_9() {
    }
    @name(".nop") action _nop_10() {
    }
    @name(".set_replica_copy_bridged") action _set_replica_copy_bridged() {
        meta.egress_metadata.routed = 1w0;
    }
    @name(".outer_replica_from_rid") action _outer_replica_from_rid(bit<16> bd, bit<14> tunnel_index, bit<5> tunnel_type, bit<4> header_count) {
        meta.egress_metadata.bd = bd;
        meta.multicast_metadata.replica = 1w1;
        meta.multicast_metadata.inner_replica = 1w0;
        meta.egress_metadata.routed = meta.l3_metadata.outer_routed;
        meta.egress_metadata.same_bd_check = bd ^ meta.ingress_metadata.outer_bd;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
        meta.tunnel_metadata.egress_tunnel_type = tunnel_type;
        meta.tunnel_metadata.egress_header_count = header_count;
    }
    @name(".inner_replica_from_rid") action _inner_replica_from_rid(bit<16> bd, bit<14> tunnel_index, bit<5> tunnel_type, bit<4> header_count) {
        meta.egress_metadata.bd = bd;
        meta.multicast_metadata.replica = 1w1;
        meta.multicast_metadata.inner_replica = 1w1;
        meta.egress_metadata.routed = meta.l3_metadata.routed;
        meta.egress_metadata.same_bd_check = bd ^ meta.ingress_metadata.bd;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
        meta.tunnel_metadata.egress_tunnel_type = tunnel_type;
        meta.tunnel_metadata.egress_header_count = header_count;
    }
    @name(".replica_type") table _replica_type_0 {
        actions = {
            _nop_9();
            _set_replica_copy_bridged();
            @defaultonly NoAction_98();
        }
        key = {
            meta.multicast_metadata.replica   : exact @name("multicast_metadata.replica") ;
            meta.egress_metadata.same_bd_check: ternary @name("egress_metadata.same_bd_check") ;
        }
        size = 16;
        default_action = NoAction_98();
    }
    @name(".rid") table _rid_0 {
        actions = {
            _nop_10();
            _outer_replica_from_rid();
            _inner_replica_from_rid();
            @defaultonly NoAction_99();
        }
        key = {
            hdr.eg_intr_md.egress_rid: exact @name("eg_intr_md.egress_rid") ;
        }
        size = 32768;
        default_action = NoAction_99();
    }
    @name(".nop") action _nop_11() {
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
            _nop_11();
            _remove_vlan_single_tagged();
            _remove_vlan_double_tagged();
            @defaultonly NoAction_100();
        }
        key = {
            hdr.vlan_tag_[0].isValid(): exact @name("vlan_tag_[0].$valid$") ;
            hdr.vlan_tag_[1].isValid(): exact @name("vlan_tag_[1].$valid$") ;
        }
        size = 256;
        default_action = NoAction_100();
    }
    @name(".decap_inner_udp") action _decap_inner_udp() {
        hdr.udp = hdr.inner_udp;
        hdr.inner_udp.setInvalid();
    }
    @name(".decap_inner_tcp") action _decap_inner_tcp() {
        hdr.tcp.setValid();
        hdr.inner_tcp.setInvalid();
        hdr.udp.setInvalid();
    }
    @name(".decap_inner_icmp") action _decap_inner_icmp() {
        hdr.icmp = hdr.inner_icmp;
        hdr.inner_icmp.setInvalid();
        hdr.udp.setInvalid();
    }
    @name(".decap_inner_unknown") action _decap_inner_unknown() {
        hdr.udp.setInvalid();
    }
    @name(".decap_vxlan_inner_ipv4") action _decap_vxlan_inner_ipv4() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.vxlan.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv4.setInvalid();
    }
    @name(".decap_vxlan_inner_ipv6") action _decap_vxlan_inner_ipv6() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.vxlan.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv6.setInvalid();
    }
    @name(".decap_vxlan_inner_non_ip") action _decap_vxlan_inner_non_ip() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.vxlan.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
    }
    @name(".decap_genv_inner_ipv4") action _decap_genv_inner_ipv4() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.genv.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv4.setInvalid();
    }
    @name(".decap_genv_inner_ipv6") action _decap_genv_inner_ipv6() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.genv.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv6.setInvalid();
    }
    @name(".decap_genv_inner_non_ip") action _decap_genv_inner_non_ip() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.genv.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
    }
    @name(".decap_gre_inner_ipv4") action _decap_gre_inner_ipv4() {
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.gre.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ipv4.setInvalid();
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".decap_gre_inner_ipv6") action _decap_gre_inner_ipv6() {
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.gre.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.inner_ipv6.setInvalid();
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".decap_gre_inner_non_ip") action _decap_gre_inner_non_ip() {
        hdr.ethernet.etherType = hdr.gre.proto;
        hdr.gre.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.inner_ipv6.setInvalid();
    }
    @name(".decap_ip_inner_ipv4") action _decap_ip_inner_ipv4() {
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.ipv6.setInvalid();
        hdr.inner_ipv4.setInvalid();
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".decap_ip_inner_ipv6") action _decap_ip_inner_ipv6() {
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.ipv4.setInvalid();
        hdr.inner_ipv6.setInvalid();
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".tunnel_decap_process_inner") table _tunnel_decap_process_inner_0 {
        actions = {
            _decap_inner_udp();
            _decap_inner_tcp();
            _decap_inner_icmp();
            _decap_inner_unknown();
            @defaultonly NoAction_101();
        }
        key = {
            hdr.inner_tcp.isValid() : exact @name("inner_tcp.$valid$") ;
            hdr.inner_udp.isValid() : exact @name("inner_udp.$valid$") ;
            hdr.inner_icmp.isValid(): exact @name("inner_icmp.$valid$") ;
        }
        size = 512;
        default_action = NoAction_101();
    }
    @name(".tunnel_decap_process_outer") table _tunnel_decap_process_outer_0 {
        actions = {
            _decap_vxlan_inner_ipv4();
            _decap_vxlan_inner_ipv6();
            _decap_vxlan_inner_non_ip();
            _decap_genv_inner_ipv4();
            _decap_genv_inner_ipv6();
            _decap_genv_inner_non_ip();
            _decap_gre_inner_ipv4();
            _decap_gre_inner_ipv6();
            _decap_gre_inner_non_ip();
            _decap_ip_inner_ipv4();
            _decap_ip_inner_ipv6();
            @defaultonly NoAction_102();
        }
        key = {
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("tunnel_metadata.ingress_tunnel_type") ;
            hdr.inner_ipv4.isValid()                : exact @name("inner_ipv4.$valid$") ;
            hdr.inner_ipv6.isValid()                : exact @name("inner_ipv6.$valid$") ;
        }
        size = 512;
        default_action = NoAction_102();
    }
    @name(".nop") action _nop_12() {
    }
    @name(".nop") action _nop_13() {
    }
    @name(".set_l2_rewrite") action _set_l2_rewrite() {
        meta.egress_metadata.routed = 1w0;
        meta.egress_metadata.bd = meta.ingress_metadata.bd;
        meta.egress_metadata.outer_bd = meta.ingress_metadata.bd;
    }
    @name(".set_l2_rewrite_with_tunnel") action _set_l2_rewrite_with_tunnel(bit<14> tunnel_index, bit<5> tunnel_type) {
        meta.egress_metadata.routed = 1w0;
        meta.egress_metadata.bd = meta.ingress_metadata.bd;
        meta.egress_metadata.outer_bd = meta.ingress_metadata.bd;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
        meta.tunnel_metadata.egress_tunnel_type = tunnel_type;
    }
    @name(".set_l3_rewrite") action _set_l3_rewrite(bit<16> bd, bit<8> mtu_index, bit<48> dmac) {
        meta.egress_metadata.routed = 1w1;
        meta.egress_metadata.mac_da = dmac;
        meta.egress_metadata.bd = bd;
        meta.egress_metadata.outer_bd = bd;
        meta.l3_metadata.mtu_index = mtu_index;
    }
    @name(".set_l3_rewrite_with_tunnel") action _set_l3_rewrite_with_tunnel(bit<16> bd, bit<48> dmac, bit<14> tunnel_index, bit<5> tunnel_type) {
        meta.egress_metadata.routed = 1w1;
        meta.egress_metadata.mac_da = dmac;
        meta.egress_metadata.bd = bd;
        meta.egress_metadata.outer_bd = bd;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
        meta.tunnel_metadata.egress_tunnel_type = tunnel_type;
    }
    @name(".rewrite_ipv4_multicast") action _rewrite_ipv4_multicast() {
        hdr.ethernet.dstAddr[22:0] = ((bit<48>)hdr.ipv4.dstAddr)[22:0];
    }
    @name(".rewrite_ipv6_multicast") action _rewrite_ipv6_multicast() {
    }
    @name(".rewrite") table _rewrite_0 {
        actions = {
            _nop_12();
            _set_l2_rewrite();
            _set_l2_rewrite_with_tunnel();
            _set_l3_rewrite();
            _set_l3_rewrite_with_tunnel();
            @defaultonly NoAction_103();
        }
        key = {
            meta.l3_metadata.nexthop_index: exact @name("l3_metadata.nexthop_index") ;
        }
        size = 49152;
        default_action = NoAction_103();
    }
    @name(".rewrite_multicast") table _rewrite_multicast_0 {
        actions = {
            _nop_13();
            _rewrite_ipv4_multicast();
            _rewrite_ipv6_multicast();
            @defaultonly NoAction_104();
        }
        key = {
            hdr.ipv4.isValid()       : exact @name("ipv4.$valid$") ;
            hdr.ipv6.isValid()       : exact @name("ipv6.$valid$") ;
            hdr.ipv4.dstAddr[31:28]  : ternary @name("ipv4.dstAddr[31:28]") ;
            hdr.ipv6.dstAddr[127:120]: ternary @name("ipv6.dstAddr[127:120]") ;
        }
        default_action = NoAction_104();
    }
    @name(".nop") action _nop_14() {
    }
    @name(".set_egress_bd_properties") action _set_egress_bd_properties(bit<9> smac_idx, bit<2> nat_mode, bit<16> bd_label) {
        meta.egress_metadata.smac_idx = smac_idx;
        meta.nat_metadata.egress_nat_mode = nat_mode;
        meta.acl_metadata.egress_bd_label = bd_label;
    }
    @name(".egress_bd_map") table _egress_bd_map_0 {
        actions = {
            _nop_14();
            _set_egress_bd_properties();
            @defaultonly NoAction_105();
        }
        key = {
            meta.egress_metadata.bd: exact @name("egress_metadata.bd") ;
        }
        size = 16384;
        default_action = NoAction_105();
    }
    @name(".nop") action _nop_15() {
    }
    @name(".set_mpls_exp_marking") action _set_mpls_exp_marking(bit<8> exp) {
        meta.l3_metadata.lkp_dscp = exp;
    }
    @name(".set_ip_dscp_marking") action _set_ip_dscp_marking(bit<8> dscp) {
        meta.l3_metadata.lkp_dscp = dscp;
    }
    @name(".set_vlan_pcp_marking") action _set_vlan_pcp_marking(bit<3> pcp) {
        meta.l2_metadata.lkp_pcp = pcp;
    }
    @name(".egress_qos_map") table _egress_qos_map_0 {
        actions = {
            _nop_15();
            _set_mpls_exp_marking();
            _set_ip_dscp_marking();
            _set_vlan_pcp_marking();
            @defaultonly NoAction_106();
        }
        key = {
            meta.qos_metadata.egress_qos_group: ternary @name("qos_metadata.egress_qos_group") ;
            meta.qos_metadata.lkp_tc          : ternary @name("qos_metadata.lkp_tc") ;
        }
        size = 512;
        default_action = NoAction_106();
    }
    @name(".nop") action _nop_16() {
    }
    @name(".ipv4_unicast_rewrite") action _ipv4_unicast_rewrite() {
        hdr.ethernet.dstAddr = meta.egress_metadata.mac_da;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
        hdr.ipv4.diffserv = meta.l3_metadata.lkp_dscp;
    }
    @name(".ipv4_multicast_rewrite") action _ipv4_multicast_rewrite() {
        hdr.ethernet.dstAddr = hdr.ethernet.dstAddr | 48w0x1005e000000;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
        hdr.ipv4.diffserv = meta.l3_metadata.lkp_dscp;
    }
    @name(".ipv6_unicast_rewrite") action _ipv6_unicast_rewrite() {
        hdr.ethernet.dstAddr = meta.egress_metadata.mac_da;
        hdr.ipv6.hopLimit = hdr.ipv6.hopLimit + 8w255;
        hdr.ipv6.trafficClass = meta.l3_metadata.lkp_dscp;
    }
    @name(".ipv6_multicast_rewrite") action _ipv6_multicast_rewrite() {
        hdr.ethernet.dstAddr = hdr.ethernet.dstAddr | 48w0x333300000000;
        hdr.ipv6.hopLimit = hdr.ipv6.hopLimit + 8w255;
        hdr.ipv6.trafficClass = meta.l3_metadata.lkp_dscp;
    }
    @name(".rewrite_smac") action _rewrite_smac(bit<48> smac) {
        hdr.ethernet.srcAddr = smac;
    }
    @name(".l3_rewrite") table _l3_rewrite_0 {
        actions = {
            _nop_16();
            _ipv4_unicast_rewrite();
            _ipv4_multicast_rewrite();
            _ipv6_unicast_rewrite();
            _ipv6_multicast_rewrite();
            @defaultonly NoAction_107();
        }
        key = {
            hdr.ipv4.isValid()       : exact @name("ipv4.$valid$") ;
            hdr.ipv6.isValid()       : exact @name("ipv6.$valid$") ;
            hdr.ipv4.dstAddr[31:28]  : ternary @name("ipv4.dstAddr[31:28]") ;
            hdr.ipv6.dstAddr[127:120]: ternary @name("ipv6.dstAddr[127:120]") ;
        }
        default_action = NoAction_107();
    }
    @name(".smac_rewrite") table _smac_rewrite_0 {
        actions = {
            _rewrite_smac();
            @defaultonly NoAction_108();
        }
        key = {
            meta.egress_metadata.smac_idx: exact @name("egress_metadata.smac_idx") ;
        }
        size = 512;
        default_action = NoAction_108();
    }
    @name(".mtu_miss") action _mtu_miss() {
        meta.l3_metadata.l3_mtu_check = 16w0xffff;
    }
    @name(".ipv4_mtu_check") action _ipv4_mtu_check(bit<16> l3_mtu) {
        meta.l3_metadata.l3_mtu_check = l3_mtu - hdr.ipv4.totalLen;
    }
    @name(".ipv6_mtu_check") action _ipv6_mtu_check(bit<16> l3_mtu) {
        meta.l3_metadata.l3_mtu_check = l3_mtu - hdr.ipv6.payloadLen;
    }
    @ternary(1) @name(".mtu") table _mtu_0 {
        actions = {
            _mtu_miss();
            _ipv4_mtu_check();
            _ipv6_mtu_check();
            @defaultonly NoAction_109();
        }
        key = {
            meta.l3_metadata.mtu_index: exact @name("l3_metadata.mtu_index") ;
            hdr.ipv4.isValid()        : exact @name("ipv4.$valid$") ;
            hdr.ipv6.isValid()        : exact @name("ipv6.$valid$") ;
        }
        size = 512;
        default_action = NoAction_109();
    }
    @name(".nop") action _nop_17() {
    }
    @name(".set_nat_src_rewrite") action _set_nat_src_rewrite(bit<32> src_ip) {
        hdr.ipv4.srcAddr = src_ip;
        meta.nat_metadata.update_checksum = 1w1;
        meta.nat_metadata.l4_len = 16w0;
    }
    @name(".set_nat_dst_rewrite") action _set_nat_dst_rewrite(bit<32> dst_ip) {
        hdr.ipv4.dstAddr = dst_ip;
        meta.nat_metadata.update_checksum = 1w1;
        meta.nat_metadata.l4_len = 16w0;
    }
    @name(".set_nat_src_dst_rewrite") action _set_nat_src_dst_rewrite(bit<32> src_ip, bit<32> dst_ip) {
        hdr.ipv4.srcAddr = src_ip;
        hdr.ipv4.dstAddr = dst_ip;
        meta.nat_metadata.update_checksum = 1w1;
        meta.nat_metadata.l4_len = 16w0;
    }
    @name(".set_nat_src_udp_rewrite") action _set_nat_src_udp_rewrite(bit<32> src_ip, bit<16> src_port) {
        hdr.ipv4.srcAddr = src_ip;
        hdr.udp.srcPort = src_port;
        meta.nat_metadata.update_checksum = 1w1;
        meta.nat_metadata.l4_len = 16w0;
    }
    @name(".set_nat_dst_udp_rewrite") action _set_nat_dst_udp_rewrite(bit<32> dst_ip, bit<16> dst_port) {
        hdr.ipv4.dstAddr = dst_ip;
        hdr.udp.dstPort = dst_port;
        meta.nat_metadata.update_checksum = 1w1;
        meta.nat_metadata.l4_len = 16w0;
    }
    @name(".set_nat_src_dst_udp_rewrite") action _set_nat_src_dst_udp_rewrite(bit<32> src_ip, bit<32> dst_ip, bit<16> src_port, bit<16> dst_port) {
        hdr.ipv4.srcAddr = src_ip;
        hdr.ipv4.dstAddr = dst_ip;
        hdr.udp.srcPort = src_port;
        hdr.udp.dstPort = dst_port;
        meta.nat_metadata.update_checksum = 1w1;
        meta.nat_metadata.l4_len = 16w0;
    }
    @name(".set_nat_src_tcp_rewrite") action _set_nat_src_tcp_rewrite(bit<32> src_ip, bit<16> src_port) {
        hdr.ipv4.srcAddr = src_ip;
        hdr.tcp.srcPort = src_port;
        meta.nat_metadata.update_checksum = 1w1;
        meta.nat_metadata.l4_len = 16w0;
    }
    @name(".set_nat_dst_tcp_rewrite") action _set_nat_dst_tcp_rewrite(bit<32> dst_ip, bit<16> dst_port) {
        hdr.ipv4.dstAddr = dst_ip;
        hdr.tcp.dstPort = dst_port;
        meta.nat_metadata.update_checksum = 1w1;
        meta.nat_metadata.l4_len = 16w0;
    }
    @name(".set_nat_src_dst_tcp_rewrite") action _set_nat_src_dst_tcp_rewrite(bit<32> src_ip, bit<32> dst_ip, bit<16> src_port, bit<16> dst_port) {
        hdr.ipv4.srcAddr = src_ip;
        hdr.ipv4.dstAddr = dst_ip;
        hdr.tcp.srcPort = src_port;
        hdr.tcp.dstPort = dst_port;
        meta.nat_metadata.update_checksum = 1w1;
        meta.nat_metadata.l4_len = 16w0;
    }
    @name(".egress_nat") table _egress_nat_0 {
        actions = {
            _nop_17();
            _set_nat_src_rewrite();
            _set_nat_dst_rewrite();
            _set_nat_src_dst_rewrite();
            _set_nat_src_udp_rewrite();
            _set_nat_dst_udp_rewrite();
            _set_nat_src_dst_udp_rewrite();
            _set_nat_src_tcp_rewrite();
            _set_nat_dst_tcp_rewrite();
            _set_nat_src_dst_tcp_rewrite();
            @defaultonly NoAction_110();
        }
        key = {
            meta.nat_metadata.nat_rewrite_index: exact @name("nat_metadata.nat_rewrite_index") ;
        }
        size = 16384;
        default_action = NoAction_110();
    }
    @min_width(32) @name(".egress_bd_stats") direct_counter(CounterType.packets_and_bytes) _egress_bd_stats_1;
    @name(".nop") action _nop_18() {
        _egress_bd_stats_1.count();
    }
    @name(".egress_bd_stats") table _egress_bd_stats_2 {
        actions = {
            _nop_18();
            @defaultonly NoAction_111();
        }
        key = {
            meta.egress_metadata.bd      : exact @name("egress_metadata.bd") ;
            meta.l2_metadata.lkp_pkt_type: exact @name("l2_metadata.lkp_pkt_type") ;
        }
        size = 16384;
        counters = _egress_bd_stats_1;
        default_action = NoAction_111();
    }
    @name(".nop") action _nop_19() {
    }
    @name(".nop") action _nop_20() {
    }
    @name(".nop") action _nop_21() {
    }
    @name(".nop") action _nop_22() {
    }
    @name(".nop") action _nop_23() {
    }
    @name(".nop") action _nop_24() {
    }
    @name(".nop") action _nop_25() {
    }
    @name(".set_egress_tunnel_vni") action _set_egress_tunnel_vni(bit<24> vnid) {
        meta.tunnel_metadata.vnid = vnid;
    }
    @name(".rewrite_tunnel_dmac") action _rewrite_tunnel_dmac(bit<48> dmac) {
        hdr.ethernet.dstAddr = dmac;
    }
    @name(".rewrite_tunnel_ipv4_dst") action _rewrite_tunnel_ipv4_dst(bit<32> ip) {
        hdr.ipv4.dstAddr = ip;
    }
    @name(".rewrite_tunnel_ipv6_dst") action _rewrite_tunnel_ipv6_dst(bit<128> ip) {
        hdr.ipv6.dstAddr = ip;
    }
    @name(".inner_ipv4_udp_rewrite") action _inner_ipv4_udp_rewrite() {
        hdr.inner_ipv4 = hdr.ipv4;
        hdr.inner_udp = hdr.udp;
        meta.egress_metadata.payload_length = hdr.ipv4.totalLen;
        hdr.udp.setInvalid();
        hdr.ipv4.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w4;
    }
    @name(".inner_ipv4_tcp_rewrite") action _inner_ipv4_tcp_rewrite() {
        hdr.inner_ipv4 = hdr.ipv4;
        hdr.inner_tcp.setValid();
        meta.egress_metadata.payload_length = hdr.ipv4.totalLen;
        hdr.tcp.setInvalid();
        hdr.ipv4.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w4;
    }
    @name(".inner_ipv4_icmp_rewrite") action _inner_ipv4_icmp_rewrite() {
        hdr.inner_ipv4 = hdr.ipv4;
        hdr.inner_icmp = hdr.icmp;
        meta.egress_metadata.payload_length = hdr.ipv4.totalLen;
        hdr.icmp.setInvalid();
        hdr.ipv4.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w4;
    }
    @name(".inner_ipv4_unknown_rewrite") action _inner_ipv4_unknown_rewrite() {
        hdr.inner_ipv4 = hdr.ipv4;
        meta.egress_metadata.payload_length = hdr.ipv4.totalLen;
        hdr.ipv4.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w4;
    }
    @name(".inner_ipv6_udp_rewrite") action _inner_ipv6_udp_rewrite() {
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_udp = hdr.udp;
        meta.egress_metadata.payload_length = hdr.ipv6.payloadLen + 16w40;
        hdr.ipv6.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w41;
    }
    @name(".inner_ipv6_tcp_rewrite") action _inner_ipv6_tcp_rewrite() {
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_tcp.setValid();
        meta.egress_metadata.payload_length = hdr.ipv6.payloadLen + 16w40;
        hdr.tcp.setInvalid();
        hdr.ipv6.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w41;
    }
    @name(".inner_ipv6_icmp_rewrite") action _inner_ipv6_icmp_rewrite() {
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_icmp = hdr.icmp;
        meta.egress_metadata.payload_length = hdr.ipv6.payloadLen + 16w40;
        hdr.icmp.setInvalid();
        hdr.ipv6.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w41;
    }
    @name(".inner_ipv6_unknown_rewrite") action _inner_ipv6_unknown_rewrite() {
        hdr.inner_ipv6 = hdr.ipv6;
        meta.egress_metadata.payload_length = hdr.ipv6.payloadLen + 16w40;
        hdr.ipv6.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w41;
    }
    @name(".inner_non_ip_rewrite") action _inner_non_ip_rewrite() {
    }
    @name(".fabric_rewrite") action _fabric_rewrite(bit<14> tunnel_index) {
        meta.tunnel_metadata.tunnel_index = tunnel_index;
    }
    @name(".ipv4_vxlan_rewrite") action _ipv4_vxlan_rewrite() {
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
        hdr.ipv4.setValid();
        hdr.ipv4.protocol = 8w17;
        hdr.ipv4.ttl = 8w64;
        hdr.ipv4.version = 4w0x4;
        hdr.ipv4.ihl = 4w0x5;
        hdr.ipv4.identification = 16w0;
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w50;
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".ipv4_genv_rewrite") action _ipv4_genv_rewrite() {
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
        hdr.ipv4.setValid();
        hdr.ipv4.protocol = 8w17;
        hdr.ipv4.ttl = 8w64;
        hdr.ipv4.version = 4w0x4;
        hdr.ipv4.ihl = 4w0x5;
        hdr.ipv4.identification = 16w0;
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w50;
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".ipv4_gre_rewrite") action _ipv4_gre_rewrite() {
        hdr.gre.setValid();
        hdr.gre.proto = hdr.ethernet.etherType;
        hdr.ipv4.setValid();
        hdr.ipv4.protocol = 8w47;
        hdr.ipv4.ttl = 8w64;
        hdr.ipv4.version = 4w0x4;
        hdr.ipv4.ihl = 4w0x5;
        hdr.ipv4.identification = 16w0;
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w24;
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".ipv4_ip_rewrite") action _ipv4_ip_rewrite() {
        hdr.ipv4.setValid();
        hdr.ipv4.protocol = meta.tunnel_metadata.inner_ip_proto;
        hdr.ipv4.ttl = 8w64;
        hdr.ipv4.version = 4w0x4;
        hdr.ipv4.ihl = 4w0x5;
        hdr.ipv4.identification = 16w0;
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w20;
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".ipv6_gre_rewrite") action _ipv6_gre_rewrite() {
        hdr.gre.setValid();
        hdr.gre.proto = hdr.ethernet.etherType;
        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w0x6;
        hdr.ipv6.nextHdr = 8w47;
        hdr.ipv6.hopLimit = 8w64;
        hdr.ipv6.trafficClass = 8w0;
        hdr.ipv6.flowLabel = 20w0;
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w4;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".ipv6_ip_rewrite") action _ipv6_ip_rewrite() {
        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w0x6;
        hdr.ipv6.nextHdr = meta.tunnel_metadata.inner_ip_proto;
        hdr.ipv6.hopLimit = 8w64;
        hdr.ipv6.trafficClass = 8w0;
        hdr.ipv6.flowLabel = 20w0;
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".ipv6_vxlan_rewrite") action _ipv6_vxlan_rewrite() {
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
        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w0x6;
        hdr.ipv6.nextHdr = 8w17;
        hdr.ipv6.hopLimit = 8w64;
        hdr.ipv6.trafficClass = 8w0;
        hdr.ipv6.flowLabel = 20w0;
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w30;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".ipv6_genv_rewrite") action _ipv6_genv_rewrite() {
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
        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w0x6;
        hdr.ipv6.nextHdr = 8w17;
        hdr.ipv6.hopLimit = 8w64;
        hdr.ipv6.trafficClass = 8w0;
        hdr.ipv6.flowLabel = 20w0;
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w30;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".ipv4_erspan_t3_rewrite") action _ipv4_erspan_t3_rewrite() {
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
        hdr.erspan_t3_header.ft_d_other = 16w0;
        hdr.ipv4.setValid();
        hdr.ipv4.protocol = 8w47;
        hdr.ipv4.ttl = 8w64;
        hdr.ipv4.version = 4w0x4;
        hdr.ipv4.ihl = 4w0x5;
        hdr.ipv4.identification = 16w0;
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w50;
    }
    @name(".ipv6_erspan_t3_rewrite") action _ipv6_erspan_t3_rewrite() {
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
        hdr.erspan_t3_header.ft_d_other = 16w0;
        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w0x6;
        hdr.ipv6.nextHdr = 8w47;
        hdr.ipv6.hopLimit = 8w64;
        hdr.ipv6.trafficClass = 8w0;
        hdr.ipv6.flowLabel = 20w0;
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w26;
    }
    @name(".tunnel_mtu_check") action _tunnel_mtu_check(bit<16> l3_mtu) {
        meta.l3_metadata.l3_mtu_check = l3_mtu - meta.egress_metadata.payload_length;
    }
    @name(".tunnel_mtu_miss") action _tunnel_mtu_miss() {
        meta.l3_metadata.l3_mtu_check = 16w0xffff;
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
        hdr.fabric_header_cpu.ingressBd = meta.ingress_metadata.bd;
        hdr.fabric_header_cpu.reasonCode = meta.fabric_metadata.reason_code;
        hdr.fabric_payload_header.setValid();
        hdr.fabric_payload_header.etherType = hdr.ethernet.etherType;
        hdr.ethernet.etherType = 16w0x9000;
    }
    @name(".set_tunnel_rewrite_details") action _set_tunnel_rewrite_details(bit<16> outer_bd, bit<9> smac_idx, bit<14> dmac_idx, bit<9> sip_index, bit<14> dip_index) {
        meta.egress_metadata.outer_bd = outer_bd;
        meta.tunnel_metadata.tunnel_smac_index = smac_idx;
        meta.tunnel_metadata.tunnel_dmac_index = dmac_idx;
        meta.tunnel_metadata.tunnel_src_index = sip_index;
        meta.tunnel_metadata.tunnel_dst_index = dip_index;
    }
    @name(".rewrite_tunnel_smac") action _rewrite_tunnel_smac(bit<48> smac) {
        hdr.ethernet.srcAddr = smac;
    }
    @name(".rewrite_tunnel_ipv4_src") action _rewrite_tunnel_ipv4_src(bit<32> ip) {
        hdr.ipv4.srcAddr = ip;
    }
    @name(".rewrite_tunnel_ipv6_src") action _rewrite_tunnel_ipv6_src(bit<128> ip) {
        hdr.ipv6.srcAddr = ip;
    }
    @name(".egress_vni") table _egress_vni_0 {
        actions = {
            _nop_19();
            _set_egress_tunnel_vni();
            @defaultonly NoAction_112();
        }
        key = {
            meta.egress_metadata.bd                : exact @name("egress_metadata.bd") ;
            meta.tunnel_metadata.egress_tunnel_type: exact @name("tunnel_metadata.egress_tunnel_type") ;
        }
        size = 16384;
        default_action = NoAction_112();
    }
    @name(".tunnel_dmac_rewrite") table _tunnel_dmac_rewrite_0 {
        actions = {
            _nop_20();
            _rewrite_tunnel_dmac();
            @defaultonly NoAction_113();
        }
        key = {
            meta.tunnel_metadata.tunnel_dmac_index: exact @name("tunnel_metadata.tunnel_dmac_index") ;
        }
        size = 16384;
        default_action = NoAction_113();
    }
    @name(".tunnel_dst_rewrite") table _tunnel_dst_rewrite_0 {
        actions = {
            _nop_21();
            _rewrite_tunnel_ipv4_dst();
            _rewrite_tunnel_ipv6_dst();
            @defaultonly NoAction_114();
        }
        key = {
            meta.tunnel_metadata.tunnel_dst_index: exact @name("tunnel_metadata.tunnel_dst_index") ;
        }
        size = 16354;
        default_action = NoAction_114();
    }
    @name(".tunnel_encap_process_inner") table _tunnel_encap_process_inner_0 {
        actions = {
            _inner_ipv4_udp_rewrite();
            _inner_ipv4_tcp_rewrite();
            _inner_ipv4_icmp_rewrite();
            _inner_ipv4_unknown_rewrite();
            _inner_ipv6_udp_rewrite();
            _inner_ipv6_tcp_rewrite();
            _inner_ipv6_icmp_rewrite();
            _inner_ipv6_unknown_rewrite();
            _inner_non_ip_rewrite();
            @defaultonly NoAction_115();
        }
        key = {
            hdr.ipv4.isValid(): exact @name("ipv4.$valid$") ;
            hdr.ipv6.isValid(): exact @name("ipv6.$valid$") ;
            hdr.tcp.isValid() : exact @name("tcp.$valid$") ;
            hdr.udp.isValid() : exact @name("udp.$valid$") ;
            hdr.icmp.isValid(): exact @name("icmp.$valid$") ;
        }
        size = 256;
        default_action = NoAction_115();
    }
    @ternary(1) @name(".tunnel_encap_process_outer") table _tunnel_encap_process_outer_0 {
        actions = {
            _nop_22();
            _fabric_rewrite();
            _ipv4_vxlan_rewrite();
            _ipv4_genv_rewrite();
            _ipv4_gre_rewrite();
            _ipv4_ip_rewrite();
            _ipv6_gre_rewrite();
            _ipv6_ip_rewrite();
            _ipv6_vxlan_rewrite();
            _ipv6_genv_rewrite();
            _ipv4_erspan_t3_rewrite();
            _ipv6_erspan_t3_rewrite();
            @defaultonly NoAction_116();
        }
        key = {
            meta.tunnel_metadata.egress_tunnel_type : exact @name("tunnel_metadata.egress_tunnel_type") ;
            meta.tunnel_metadata.egress_header_count: exact @name("tunnel_metadata.egress_header_count") ;
            meta.multicast_metadata.replica         : exact @name("multicast_metadata.replica") ;
        }
        size = 256;
        default_action = NoAction_116();
    }
    @name(".tunnel_mtu") table _tunnel_mtu_0 {
        actions = {
            _tunnel_mtu_check();
            _tunnel_mtu_miss();
            @defaultonly NoAction_117();
        }
        key = {
            meta.tunnel_metadata.tunnel_index: exact @name("tunnel_metadata.tunnel_index") ;
        }
        size = 16384;
        default_action = NoAction_117();
    }
    @name(".tunnel_rewrite") table _tunnel_rewrite_0 {
        actions = {
            _nop_23();
            _cpu_rx_rewrite();
            _set_tunnel_rewrite_details();
            @defaultonly NoAction_118();
        }
        key = {
            meta.tunnel_metadata.tunnel_index: exact @name("tunnel_metadata.tunnel_index") ;
        }
        size = 16384;
        default_action = NoAction_118();
    }
    @name(".tunnel_smac_rewrite") table _tunnel_smac_rewrite_0 {
        actions = {
            _nop_24();
            _rewrite_tunnel_smac();
            @defaultonly NoAction_119();
        }
        key = {
            meta.tunnel_metadata.tunnel_smac_index: exact @name("tunnel_metadata.tunnel_smac_index") ;
        }
        size = 512;
        default_action = NoAction_119();
    }
    @name(".tunnel_src_rewrite") table _tunnel_src_rewrite_0 {
        actions = {
            _nop_25();
            _rewrite_tunnel_ipv4_src();
            _rewrite_tunnel_ipv6_src();
            @defaultonly NoAction_120();
        }
        key = {
            meta.tunnel_metadata.tunnel_src_index: exact @name("tunnel_metadata.tunnel_src_index") ;
        }
        size = 512;
        default_action = NoAction_120();
    }
    @name(".nop") action _nop_26() {
    }
    @name(".update_udp_checksum") action _update_udp_checksum() {
        meta.nat_metadata.update_udp_checksum = 1w1;
    }
    @name(".update_tcp_checksum") action _update_tcp_checksum() {
        meta.nat_metadata.update_tcp_checksum = 1w1;
    }
    @name(".update_inner_udp_checksum") action _update_inner_udp_checksum() {
        meta.nat_metadata.update_inner_udp_checksum = 1w1;
    }
    @name(".update_inner_tcp_checksum") action _update_inner_tcp_checksum() {
        meta.nat_metadata.update_inner_tcp_checksum = 1w1;
    }
    @name(".update_l4_checksum") table _update_l4_checksum_0 {
        actions = {
            _nop_26();
            _update_udp_checksum();
            _update_tcp_checksum();
            _update_inner_udp_checksum();
            _update_inner_tcp_checksum();
            @defaultonly NoAction_121();
        }
        key = {
            meta.nat_metadata.update_checksum      : ternary @name("nat_metadata.update_checksum") ;
            meta.tunnel_metadata.egress_tunnel_type: ternary @name("tunnel_metadata.egress_tunnel_type") ;
            hdr.udp.isValid()                      : ternary @name("udp.$valid$") ;
            hdr.tcp.isValid()                      : ternary @name("tcp.$valid$") ;
            hdr.inner_udp.isValid()                : ternary @name("inner_udp.$valid$") ;
            hdr.inner_tcp.isValid()                : ternary @name("inner_tcp.$valid$") ;
            hdr.udp.checksum                       : ternary @name("udp.checksum") ;
            hdr.inner_udp.checksum                 : ternary @name("inner_udp.checksum") ;
        }
        size = 512;
        default_action = NoAction_121();
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
            @defaultonly NoAction_122();
        }
        key = {
            meta.egress_metadata.ifindex: exact @name("egress_metadata.ifindex") ;
            meta.egress_metadata.bd     : exact @name("egress_metadata.bd") ;
        }
        size = 32768;
        default_action = NoAction_122();
    }
    @name(".nop") action _nop_27() {
    }
    @name(".drop_packet") action _drop_packet() {
        mark_to_drop();
    }
    @name(".egress_copy_to_cpu") action _egress_copy_to_cpu() {
        clone3<tuple<bit<16>, bit<16>, bit<16>, bit<9>>>(CloneType.E2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
    }
    @name(".egress_redirect_to_cpu") action _egress_redirect_to_cpu() {
        clone3<tuple<bit<16>, bit<16>, bit<16>, bit<9>>>(CloneType.E2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
        mark_to_drop();
    }
    @name(".egress_copy_to_cpu_with_reason") action _egress_copy_to_cpu_with_reason(bit<16> reason_code) {
        meta.fabric_metadata.reason_code = reason_code;
        clone3<tuple<bit<16>, bit<16>, bit<16>, bit<9>>>(CloneType.E2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
    }
    @name(".egress_redirect_to_cpu_with_reason") action _egress_redirect_to_cpu_with_reason(bit<16> reason_code) {
        meta.fabric_metadata.reason_code = reason_code;
        clone3<tuple<bit<16>, bit<16>, bit<16>, bit<9>>>(CloneType.E2E, 32w250, { meta.ingress_metadata.bd, meta.ingress_metadata.ifindex, meta.fabric_metadata.reason_code, meta.ingress_metadata.ingress_port });
        mark_to_drop();
    }
    @name(".egress_mirror_coal_hdr") action _egress_mirror_coal_hdr(bit<8> session_id, bit<8> id) {
    }
    @name(".egress_mirror") action _egress_mirror(bit<32> session_id) {
        meta.i2e_metadata.mirror_session_id = (bit<16>)session_id;
        clone3<tuple<bit<32>, bit<16>>>(CloneType.E2E, session_id, { meta.i2e_metadata.ingress_tstamp, meta.i2e_metadata.mirror_session_id });
    }
    @name(".egress_mirror_drop") action _egress_mirror_drop(bit<8> reason_code, bit<8> platform_id) {
        meta.i2e_metadata.mirror_session_id = (bit<16>)32w1015;
        clone3<tuple<bit<32>, bit<16>>>(CloneType.E2E, 32w1015, { meta.i2e_metadata.ingress_tstamp, meta.i2e_metadata.mirror_session_id });
        mark_to_drop();
    }
    @name(".egress_system_acl") table _egress_system_acl_0 {
        actions = {
            _nop_27();
            _drop_packet();
            _egress_copy_to_cpu();
            _egress_redirect_to_cpu();
            _egress_copy_to_cpu_with_reason();
            _egress_redirect_to_cpu_with_reason();
            _egress_mirror_coal_hdr();
            _egress_mirror();
            _egress_mirror_drop();
            @defaultonly NoAction_123();
        }
        key = {
            meta.fabric_metadata.reason_code: ternary @name("fabric_metadata.reason_code") ;
            hdr.eg_intr_md.egress_port      : ternary @name("eg_intr_md.egress_port") ;
            hdr.eg_intr_md.deflection_flag  : ternary @name("eg_intr_md.deflection_flag") ;
            meta.l3_metadata.l3_mtu_check   : ternary @name("l3_metadata.l3_mtu_check") ;
            meta.acl_metadata.acl_deny      : ternary @name("acl_metadata.acl_deny") ;
        }
        size = 1024;
        default_action = NoAction_123();
    }
    apply {
        if (hdr.eg_intr_md.deflection_flag == 1w0 && meta.egress_metadata.bypass == 1w0) {
            if (hdr.eg_intr_md_from_parser_aux.clone_src != 4w0) 
                _mirror_0.apply();
            else 
                if (hdr.eg_intr_md.egress_rid != 16w0) {
                    _rid_0.apply();
                    _replica_type_0.apply();
                }
            switch (egress_port_mapping.apply().action_run) {
                egress_port_type_normal_0: {
                    if (hdr.eg_intr_md_from_parser_aux.clone_src == 4w0) 
                        _vlan_decap_0.apply();
                    if (meta.tunnel_metadata.tunnel_terminate == 1w1) 
                        if (meta.multicast_metadata.inner_replica == 1w1 || meta.multicast_metadata.replica == 1w0) {
                            _tunnel_decap_process_outer_0.apply();
                            _tunnel_decap_process_inner_0.apply();
                        }
                    if (meta.egress_metadata.routed == 1w0 || meta.l3_metadata.nexthop_index != 16w0) 
                        _rewrite_0.apply();
                    else 
                        _rewrite_multicast_0.apply();
                    _egress_bd_map_0.apply();
                    if (meta.ingress_metadata.bypass_lookups & 16w0x8 == 16w0) 
                        _egress_qos_map_0.apply();
                    if (meta.egress_metadata.routed == 1w1) {
                        _l3_rewrite_0.apply();
                        _smac_rewrite_0.apply();
                    }
                    _mtu_0.apply();
                    if (meta.nat_metadata.ingress_nat_mode != 2w0 && meta.nat_metadata.ingress_nat_mode != meta.nat_metadata.egress_nat_mode) 
                        _egress_nat_0.apply();
                    _egress_bd_stats_2.apply();
                }
            }

            if (meta.fabric_metadata.fabric_header_present == 1w0 && meta.tunnel_metadata.egress_tunnel_type != 5w0) {
                _egress_vni_0.apply();
                if (meta.tunnel_metadata.egress_tunnel_type != 5w15 && meta.tunnel_metadata.egress_tunnel_type != 5w16 && meta.tunnel_metadata.skip_encap_inner == 1w0) 
                    _tunnel_encap_process_inner_0.apply();
                _tunnel_encap_process_outer_0.apply();
                _tunnel_rewrite_0.apply();
                _tunnel_mtu_0.apply();
                _tunnel_src_rewrite_0.apply();
                _tunnel_dst_rewrite_0.apply();
                _tunnel_smac_rewrite_0.apply();
                _tunnel_dmac_rewrite_0.apply();
            }
            _update_l4_checksum_0.apply();
            if (meta.egress_metadata.port_type == 2w0) 
                _egress_vlan_xlate_0.apply();
        }
        if (meta.egress_metadata.bypass == 1w0) 
            _egress_system_acl_0.apply();
    }
}
#include <tofino/p4_14_prim.p4>

@name("mac_learn_digest") struct mac_learn_digest {
    bit<16> bd;
    bit<48> lkp_mac_sa;
    bit<16> ifindex;
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_124() {
    }
    @name(".NoAction") action NoAction_125() {
    }
    @name(".NoAction") action NoAction_126() {
    }
    @name(".NoAction") action NoAction_127() {
    }
    @name(".NoAction") action NoAction_128() {
    }
    @name(".NoAction") action NoAction_129() {
    }
    @name(".NoAction") action NoAction_130() {
    }
    @name(".NoAction") action NoAction_131() {
    }
    @name(".NoAction") action NoAction_132() {
    }
    @name(".NoAction") action NoAction_133() {
    }
    @name(".NoAction") action NoAction_134() {
    }
    @name(".NoAction") action NoAction_135() {
    }
    @name(".NoAction") action NoAction_136() {
    }
    @name(".NoAction") action NoAction_137() {
    }
    @name(".NoAction") action NoAction_138() {
    }
    @name(".NoAction") action NoAction_139() {
    }
    @name(".NoAction") action NoAction_140() {
    }
    @name(".NoAction") action NoAction_141() {
    }
    @name(".NoAction") action NoAction_142() {
    }
    @name(".NoAction") action NoAction_143() {
    }
    @name(".NoAction") action NoAction_144() {
    }
    @name(".NoAction") action NoAction_145() {
    }
    @name(".NoAction") action NoAction_146() {
    }
    @name(".NoAction") action NoAction_147() {
    }
    @name(".NoAction") action NoAction_148() {
    }
    @name(".NoAction") action NoAction_149() {
    }
    @name(".NoAction") action NoAction_150() {
    }
    @name(".NoAction") action NoAction_151() {
    }
    @name(".NoAction") action NoAction_152() {
    }
    @name(".NoAction") action NoAction_153() {
    }
    @name(".NoAction") action NoAction_154() {
    }
    @name(".NoAction") action NoAction_155() {
    }
    @name(".NoAction") action NoAction_156() {
    }
    @name(".NoAction") action NoAction_157() {
    }
    @name(".NoAction") action NoAction_158() {
    }
    @name(".NoAction") action NoAction_159() {
    }
    @name(".NoAction") action NoAction_160() {
    }
    @name(".NoAction") action NoAction_161() {
    }
    @name(".NoAction") action NoAction_162() {
    }
    @name(".NoAction") action NoAction_163() {
    }
    @name(".NoAction") action NoAction_164() {
    }
    @name(".NoAction") action NoAction_165() {
    }
    @name(".NoAction") action NoAction_166() {
    }
    @name(".NoAction") action NoAction_167() {
    }
    @name(".NoAction") action NoAction_168() {
    }
    @name(".NoAction") action NoAction_169() {
    }
    @name(".NoAction") action NoAction_170() {
    }
    @name(".NoAction") action NoAction_171() {
    }
    @name(".NoAction") action NoAction_172() {
    }
    @name(".NoAction") action NoAction_173() {
    }
    @name(".NoAction") action NoAction_174() {
    }
    @name(".NoAction") action NoAction_175() {
    }
    @name(".NoAction") action NoAction_176() {
    }
    @name(".NoAction") action NoAction_177() {
    }
    @name(".NoAction") action NoAction_178() {
    }
    @name(".NoAction") action NoAction_179() {
    }
    @name(".NoAction") action NoAction_180() {
    }
    @name(".NoAction") action NoAction_181() {
    }
    @name(".NoAction") action NoAction_182() {
    }
    @name(".NoAction") action NoAction_183() {
    }
    @name(".NoAction") action NoAction_184() {
    }
    @name(".NoAction") action NoAction_185() {
    }
    @name(".NoAction") action NoAction_186() {
    }
    @name(".NoAction") action NoAction_187() {
    }
    @name(".NoAction") action NoAction_188() {
    }
    @name(".NoAction") action NoAction_189() {
    }
    @name(".NoAction") action NoAction_190() {
    }
    @name(".NoAction") action NoAction_191() {
    }
    @pa_atomic("ingress", "l3_metadata.lkp_ip_version") @pa_solitary("ingress", "l3_metadata.lkp_ip_version") @name(".rmac_hit") action rmac_hit_0() {
        meta.l3_metadata.rmac_hit = 1w1;
    }
    @name(".rmac_miss") action rmac_miss_0() {
        meta.l3_metadata.rmac_hit = 1w0;
    }
    @name(".rmac") table rmac {
        actions = {
            rmac_hit_0();
            rmac_miss_0();
            @defaultonly NoAction_124();
        }
        key = {
            meta.l3_metadata.rmac_group: exact @name("l3_metadata.rmac_group") ;
            meta.l2_metadata.lkp_mac_da: exact @name("l2_metadata.lkp_mac_da") ;
        }
        size = 512;
        default_action = NoAction_124();
    }
    @name(".set_ifindex") action _set_ifindex(bit<16> ifindex, bit<2> port_type) {
        meta.ingress_metadata.ifindex = ifindex;
        meta.ingress_metadata.port_type = port_type;
    }
    @name(".set_ingress_port_properties") action _set_ingress_port_properties(bit<16> if_label, bit<9> exclusion_id, bit<5> qos_group, bit<5> tc_qos_group, bit<8> tc, bit<2> color, bit<1> trust_dscp, bit<1> trust_pcp) {
        hdr.ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
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
            @defaultonly NoAction_125();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 288;
        default_action = NoAction_125();
    }
    @name(".ingress_port_properties") table _ingress_port_properties_0 {
        actions = {
            _set_ingress_port_properties();
            @defaultonly NoAction_126();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 288;
        default_action = NoAction_126();
    }
    @name(".set_config_parameters") action _set_config_parameters(bit<1> enable_dod, bit<8> enable_flowlet, bit<32> switch_id) {
        hdr.ig_intr_md_for_tm.deflect_on_drop = enable_dod;
        meta.i2e_metadata.ingress_tstamp = (bit<32>)hdr.ig_intr_md_from_parser_aux.ingress_global_tstamp;
        meta.ingress_metadata.ingress_port = hdr.ig_intr_md.ingress_port;
        meta.l2_metadata.same_if_check = meta.ingress_metadata.ifindex;
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w511;
        meta.global_config_metadata.switch_id = switch_id;
    }
    @name(".switch_config_params") table _switch_config_params_0 {
        actions = {
            _set_config_parameters();
            @defaultonly NoAction_127();
        }
        size = 1;
        default_action = NoAction_127();
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
            @defaultonly NoAction_128();
        }
        key = {
            hdr.ethernet.srcAddr      : ternary @name("ethernet.srcAddr") ;
            hdr.ethernet.dstAddr      : ternary @name("ethernet.dstAddr") ;
            hdr.vlan_tag_[0].isValid(): exact @name("vlan_tag_[0].$valid$") ;
            hdr.vlan_tag_[1].isValid(): exact @name("vlan_tag_[1].$valid$") ;
        }
        size = 64;
        default_action = NoAction_128();
    }
    @name(".set_valid_outer_ipv4_packet") action _set_valid_outer_ipv4_packet_0() {
        meta.l3_metadata.lkp_ip_type = 2w1;
        meta.l3_metadata.lkp_dscp = hdr.ipv4.diffserv;
        meta.l3_metadata.lkp_ip_version = hdr.ipv4.version;
    }
    @name(".set_malformed_outer_ipv4_packet") action _set_malformed_outer_ipv4_packet_0(bit<8> drop_reason) {
        meta.ingress_metadata.drop_flag = 1w1;
        meta.ingress_metadata.drop_reason = drop_reason;
    }
    @name(".validate_outer_ipv4_packet") table _validate_outer_ipv4_packet {
        actions = {
            _set_valid_outer_ipv4_packet_0();
            _set_malformed_outer_ipv4_packet_0();
            @defaultonly NoAction_129();
        }
        key = {
            hdr.ipv4.version       : ternary @name("ipv4.version") ;
            hdr.ipv4.ttl           : ternary @name("ipv4.ttl") ;
            hdr.ipv4.srcAddr[31:24]: ternary @name("ipv4.srcAddr[31:24]") ;
        }
        size = 64;
        default_action = NoAction_129();
    }
    @name(".set_valid_outer_ipv6_packet") action _set_valid_outer_ipv6_packet_0() {
        meta.l3_metadata.lkp_ip_type = 2w2;
        meta.l3_metadata.lkp_dscp = hdr.ipv6.trafficClass;
        meta.l3_metadata.lkp_ip_version = hdr.ipv6.version;
    }
    @name(".set_malformed_outer_ipv6_packet") action _set_malformed_outer_ipv6_packet_0(bit<8> drop_reason) {
        meta.ingress_metadata.drop_flag = 1w1;
        meta.ingress_metadata.drop_reason = drop_reason;
    }
    @name(".validate_outer_ipv6_packet") table _validate_outer_ipv6_packet {
        actions = {
            _set_valid_outer_ipv6_packet_0();
            _set_malformed_outer_ipv6_packet_0();
            @defaultonly NoAction_130();
        }
        key = {
            hdr.ipv6.version         : ternary @name("ipv6.version") ;
            hdr.ipv6.hopLimit        : ternary @name("ipv6.hopLimit") ;
            hdr.ipv6.srcAddr[127:112]: ternary @name("ipv6.srcAddr[127:112]") ;
        }
        size = 64;
        default_action = NoAction_130();
    }
    @name(".set_bd_properties") action _set_bd_properties(bit<16> bd, bit<16> vrf, bit<10> stp_group, bit<1> learning_enabled, bit<16> bd_label, bit<16> stats_idx, bit<10> rmac_group, bit<1> ipv4_unicast_enabled, bit<1> ipv6_unicast_enabled, bit<2> ipv4_urpf_mode, bit<2> ipv6_urpf_mode, bit<1> igmp_snooping_enabled, bit<1> mld_snooping_enabled, bit<1> ipv4_multicast_enabled, bit<1> ipv6_multicast_enabled, bit<16> mrpf_group, bit<16> ipv4_mcast_key, bit<1> ipv4_mcast_key_type, bit<16> ipv6_mcast_key, bit<1> ipv6_mcast_key_type, bit<16> ingress_rid) {
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
    @name(".port_vlan_mapping_miss") action _port_vlan_mapping_miss() {
        meta.l2_metadata.port_vlan_mapping_miss = 1w1;
    }
    @name(".port_vlan_mapping") table _port_vlan_mapping_0 {
        actions = {
            _set_bd_properties();
            _port_vlan_mapping_miss();
            @defaultonly NoAction_131();
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
        default_action = NoAction_131();
    }
    @name(".set_stp_state") action _set_stp_state(bit<3> stp_state) {
        meta.l2_metadata.stp_state = stp_state;
    }
    @ternary(1) @name(".spanning_tree") table _spanning_tree_0 {
        actions = {
            _set_stp_state();
            @defaultonly NoAction_132();
        }
        key = {
            meta.ingress_metadata.ifindex: exact @name("ingress_metadata.ifindex") ;
            meta.l2_metadata.stp_group   : exact @name("l2_metadata.stp_group") ;
        }
        size = 4096;
        default_action = NoAction_132();
    }
    @name(".nop") action _nop_28() {
    }
    @name(".nop") action _nop_29() {
    }
    @name(".set_ingress_tc") action _set_ingress_tc(bit<8> tc) {
        meta.qos_metadata.lkp_tc = tc;
    }
    @name(".set_ingress_tc") action _set_ingress_tc_2(bit<8> tc) {
        meta.qos_metadata.lkp_tc = tc;
    }
    @name(".set_ingress_color") action _set_ingress_color(bit<2> color) {
        meta.meter_metadata.packet_color = color;
    }
    @name(".set_ingress_color") action _set_ingress_color_2(bit<2> color) {
        meta.meter_metadata.packet_color = color;
    }
    @name(".set_ingress_tc_and_color") action _set_ingress_tc_and_color(bit<8> tc, bit<2> color) {
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".set_ingress_tc_and_color") action _set_ingress_tc_and_color_2(bit<8> tc, bit<2> color) {
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".ingress_qos_map_dscp") table _ingress_qos_map_dscp_0 {
        actions = {
            _nop_28();
            _set_ingress_tc();
            _set_ingress_color();
            _set_ingress_tc_and_color();
            @defaultonly NoAction_133();
        }
        key = {
            meta.qos_metadata.ingress_qos_group: ternary @name("qos_metadata.ingress_qos_group") ;
            meta.l3_metadata.lkp_dscp          : ternary @name("l3_metadata.lkp_dscp") ;
        }
        size = 64;
        default_action = NoAction_133();
    }
    @name(".ingress_qos_map_pcp") table _ingress_qos_map_pcp_0 {
        actions = {
            _nop_29();
            _set_ingress_tc_2();
            _set_ingress_color_2();
            _set_ingress_tc_and_color_2();
            @defaultonly NoAction_134();
        }
        key = {
            meta.qos_metadata.ingress_qos_group: ternary @name("qos_metadata.ingress_qos_group") ;
            meta.l2_metadata.lkp_pcp           : ternary @name("l2_metadata.lkp_pcp") ;
        }
        size = 64;
        default_action = NoAction_134();
    }
    @name(".non_ip_lkp") action _non_ip_lkp() {
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.l2_metadata.non_ip_packet = 1w1;
        invalidate<bit<16>>(hdr.ig_intr_md_for_tm.mcast_grp_a);
    }
    @name(".non_ip_lkp") action _non_ip_lkp_2() {
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.l2_metadata.non_ip_packet = 1w1;
        invalidate<bit<16>>(hdr.ig_intr_md_for_tm.mcast_grp_a);
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
        invalidate<bit<16>>(hdr.ig_intr_md_for_tm.mcast_grp_a);
    }
    @name(".ipv4_lkp") action _ipv4_lkp_2() {
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
    @name(".ipv6_lkp") action _ipv6_lkp() {
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
    @name(".ipv6_lkp") action _ipv6_lkp_2() {
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
    @name(".on_miss") action _on_miss_9() {
    }
    @name(".outer_rmac_hit") action _outer_rmac_hit() {
        meta.l3_metadata.rmac_hit = 1w1;
    }
    @name(".nop") action _nop_30() {
    }
    @name(".nop") action _nop_31() {
    }
    @name(".tunnel_lookup_miss") action _tunnel_lookup_miss() {
    }
    @name(".terminate_tunnel_inner_non_ip") action _terminate_tunnel_inner_non_ip(bit<16> bd, bit<16> bd_label, bit<16> stats_idx, bit<16> exclusion_id, bit<16> ingress_rid) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.ingress_metadata.bd = bd;
        meta.acl_metadata.bd_label = bd_label;
        meta.l2_metadata.bd_stats_idx = stats_idx;
        meta.l3_metadata.lkp_ip_type = 2w0;
        meta.l2_metadata.lkp_mac_type = hdr.inner_ethernet.etherType;
        hdr.ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        hdr.ig_intr_md_for_tm.rid = ingress_rid;
        meta.l2_metadata.non_ip_packet = 1w1;
    }
    @name(".terminate_tunnel_inner_ethernet_ipv4") action _terminate_tunnel_inner_ethernet_ipv4(bit<16> bd, bit<16> vrf, bit<10> rmac_group, bit<16> bd_label, bit<1> ipv4_unicast_enabled, bit<2> ipv4_urpf_mode, bit<1> igmp_snooping_enabled, bit<16> stats_idx, bit<1> ipv4_multicast_enabled, bit<16> mrpf_group, bit<16> exclusion_id, bit<16> ingress_rid) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
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
        meta.multicast_metadata.igmp_snooping_enabled = igmp_snooping_enabled;
        meta.multicast_metadata.ipv4_multicast_enabled = ipv4_multicast_enabled;
        meta.multicast_metadata.bd_mrpf_group = mrpf_group;
        hdr.ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        hdr.ig_intr_md_for_tm.rid = ingress_rid;
    }
    @name(".terminate_tunnel_inner_ipv4") action _terminate_tunnel_inner_ipv4(bit<16> vrf, bit<10> rmac_group, bit<2> ipv4_urpf_mode, bit<1> ipv4_unicast_enabled, bit<1> ipv4_multicast_enabled, bit<16> mrpf_group) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.l3_metadata.vrf = vrf;
        meta.ipv4_metadata.ipv4_unicast_enabled = ipv4_unicast_enabled;
        meta.ipv4_metadata.ipv4_urpf_mode = ipv4_urpf_mode;
        meta.l3_metadata.rmac_group = rmac_group;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.l3_metadata.lkp_ip_type = 2w1;
        meta.l3_metadata.lkp_ip_version = hdr.inner_ipv4.version;
        meta.multicast_metadata.bd_mrpf_group = mrpf_group;
        meta.multicast_metadata.ipv4_multicast_enabled = ipv4_multicast_enabled;
    }
    @name(".terminate_tunnel_inner_ethernet_ipv6") action _terminate_tunnel_inner_ethernet_ipv6(bit<16> bd, bit<16> vrf, bit<10> rmac_group, bit<16> bd_label, bit<1> ipv6_unicast_enabled, bit<2> ipv6_urpf_mode, bit<1> mld_snooping_enabled, bit<16> stats_idx, bit<1> ipv6_multicast_enabled, bit<16> mrpf_group, bit<16> exclusion_id, bit<16> ingress_rid) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
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
        meta.multicast_metadata.bd_mrpf_group = mrpf_group;
        meta.multicast_metadata.ipv6_multicast_enabled = ipv6_multicast_enabled;
        meta.multicast_metadata.mld_snooping_enabled = mld_snooping_enabled;
        hdr.ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        hdr.ig_intr_md_for_tm.rid = ingress_rid;
    }
    @name(".terminate_tunnel_inner_ipv6") action _terminate_tunnel_inner_ipv6(bit<16> vrf, bit<10> rmac_group, bit<1> ipv6_unicast_enabled, bit<2> ipv6_urpf_mode, bit<1> ipv6_multicast_enabled, bit<16> mrpf_group) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.l3_metadata.vrf = vrf;
        meta.ipv6_metadata.ipv6_unicast_enabled = ipv6_unicast_enabled;
        meta.ipv6_metadata.ipv6_urpf_mode = ipv6_urpf_mode;
        meta.l3_metadata.rmac_group = rmac_group;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.l3_metadata.lkp_ip_type = 2w2;
        meta.l3_metadata.lkp_ip_version = hdr.inner_ipv6.version;
        meta.multicast_metadata.bd_mrpf_group = mrpf_group;
        meta.multicast_metadata.ipv6_multicast_enabled = ipv6_multicast_enabled;
    }
    @name(".tunnel_check_pass") action _tunnel_check_pass() {
    }
    @name(".adjust_lkp_fields") table _adjust_lkp_fields_0 {
        actions = {
            _non_ip_lkp();
            _ipv4_lkp();
            _ipv6_lkp();
            @defaultonly NoAction_135();
        }
        key = {
            hdr.ipv4.isValid(): exact @name("ipv4.$valid$") ;
            hdr.ipv6.isValid(): exact @name("ipv6.$valid$") ;
        }
        default_action = NoAction_135();
    }
    @ternary(1) @name(".outer_rmac") table _outer_rmac_0 {
        actions = {
            _on_miss_9();
            _outer_rmac_hit();
            @defaultonly NoAction_136();
        }
        key = {
            meta.l3_metadata.rmac_group: exact @name("l3_metadata.rmac_group") ;
            hdr.ethernet.dstAddr       : exact @name("ethernet.dstAddr") ;
        }
        size = 512;
        default_action = NoAction_136();
    }
    @name(".tunnel") table _tunnel_0 {
        actions = {
            _nop_30();
            _tunnel_lookup_miss();
            _terminate_tunnel_inner_non_ip();
            _terminate_tunnel_inner_ethernet_ipv4();
            _terminate_tunnel_inner_ipv4();
            _terminate_tunnel_inner_ethernet_ipv6();
            _terminate_tunnel_inner_ipv6();
            @defaultonly NoAction_137();
        }
        key = {
            meta.tunnel_metadata.tunnel_vni         : exact @name("tunnel_metadata.tunnel_vni") ;
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("tunnel_metadata.ingress_tunnel_type") ;
            hdr.inner_ipv4.isValid()                : exact @name("inner_ipv4.$valid$") ;
            hdr.inner_ipv6.isValid()                : exact @name("inner_ipv6.$valid$") ;
        }
        size = 16384;
        default_action = NoAction_137();
    }
    @name(".tunnel_check") table _tunnel_check_0 {
        actions = {
            _nop_31();
            _tunnel_check_pass();
            @defaultonly NoAction_138();
        }
        key = {
            meta.tunnel_metadata.ingress_tunnel_type: ternary @name("tunnel_metadata.ingress_tunnel_type") ;
            meta.tunnel_metadata.tunnel_lookup      : ternary @name("tunnel_metadata.tunnel_lookup") ;
            meta.tunnel_metadata.src_vtep_hit       : ternary @name("tunnel_metadata.src_vtep_hit") ;
        }
        default_action = NoAction_138();
    }
    @name(".tunnel_lookup_miss") table _tunnel_lookup_miss_2 {
        actions = {
            _non_ip_lkp_2();
            _ipv4_lkp_2();
            _ipv6_lkp_2();
            @defaultonly NoAction_139();
        }
        key = {
            hdr.ipv4.isValid(): exact @name("ipv4.$valid$") ;
            hdr.ipv6.isValid(): exact @name("ipv6.$valid$") ;
        }
        default_action = NoAction_139();
    }
    @name(".nop") action _nop_32() {
    }
    @name(".terminate_cpu_packet") action _terminate_cpu_packet_0() {
        hdr.ig_intr_md_for_tm.ucast_egress_port = (bit<9>)hdr.fabric_header.dstPortOrGroup;
        meta.egress_metadata.bypass = hdr.fabric_header_cpu.txBypass;
        hdr.ethernet.etherType = hdr.fabric_payload_header.etherType;
        hdr.fabric_header.setInvalid();
        hdr.fabric_header_cpu.setInvalid();
        hdr.fabric_payload_header.setInvalid();
    }
    @ternary(1) @name(".fabric_ingress_dst_lkp") table _fabric_ingress_dst_lkp {
        actions = {
            _nop_32();
            _terminate_cpu_packet_0();
            @defaultonly NoAction_140();
        }
        key = {
            hdr.fabric_header.dstDevice: exact @name("fabric_header.dstDevice") ;
        }
        default_action = NoAction_140();
    }
    @name(".nop") action _nop_33() {
    }
    @name(".set_tunnel_lookup_flag") action _set_tunnel_lookup_flag_1() {
        meta.tunnel_metadata.tunnel_lookup = 1w1;
    }
    @name(".set_tunnel_vni_and_lookup_flag") action _set_tunnel_vni_and_lookup_flag_1(bit<24> tunnel_vni) {
        meta.tunnel_metadata.tunnel_vni = tunnel_vni;
        meta.tunnel_metadata.tunnel_lookup = 1w1;
    }
    @name(".on_miss") action _on_miss_10() {
    }
    @name(".src_vtep_hit") action _src_vtep_hit_1(bit<16> ifindex) {
        meta.ingress_metadata.ifindex = ifindex;
        meta.tunnel_metadata.src_vtep_hit = 1w1;
    }
    @name(".ipv4_dest_vtep") table _ipv4_dest_vtep {
        actions = {
            _nop_33();
            _set_tunnel_lookup_flag_1();
            _set_tunnel_vni_and_lookup_flag_1();
            @defaultonly NoAction_141();
        }
        key = {
            meta.l3_metadata.vrf                    : exact @name("l3_metadata.vrf") ;
            hdr.ipv4.dstAddr                        : exact @name("ipv4.dstAddr") ;
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("tunnel_metadata.ingress_tunnel_type") ;
        }
        size = 512;
        default_action = NoAction_141();
    }
    @name(".ipv4_src_vtep") table _ipv4_src_vtep {
        actions = {
            _on_miss_10();
            _src_vtep_hit_1();
            @defaultonly NoAction_142();
        }
        key = {
            meta.l3_metadata.vrf                    : exact @name("l3_metadata.vrf") ;
            hdr.ipv4.srcAddr                        : exact @name("ipv4.srcAddr") ;
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("tunnel_metadata.ingress_tunnel_type") ;
        }
        size = 16384;
        default_action = NoAction_142();
    }
    @name(".nop") action _nop_34() {
    }
    @name(".set_tunnel_lookup_flag") action _set_tunnel_lookup_flag_2() {
        meta.tunnel_metadata.tunnel_lookup = 1w1;
    }
    @name(".set_tunnel_vni_and_lookup_flag") action _set_tunnel_vni_and_lookup_flag_2(bit<24> tunnel_vni) {
        meta.tunnel_metadata.tunnel_vni = tunnel_vni;
        meta.tunnel_metadata.tunnel_lookup = 1w1;
    }
    @name(".on_miss") action _on_miss_11() {
    }
    @name(".src_vtep_hit") action _src_vtep_hit_2(bit<16> ifindex) {
        meta.ingress_metadata.ifindex = ifindex;
        meta.tunnel_metadata.src_vtep_hit = 1w1;
    }
    @name(".ipv6_dest_vtep") table _ipv6_dest_vtep {
        actions = {
            _nop_34();
            _set_tunnel_lookup_flag_2();
            _set_tunnel_vni_and_lookup_flag_2();
            @defaultonly NoAction_143();
        }
        key = {
            meta.l3_metadata.vrf                    : exact @name("l3_metadata.vrf") ;
            hdr.ipv6.dstAddr                        : exact @name("ipv6.dstAddr") ;
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("tunnel_metadata.ingress_tunnel_type") ;
        }
        size = 512;
        default_action = NoAction_143();
    }
    @name(".ipv6_src_vtep") table _ipv6_src_vtep {
        actions = {
            _on_miss_11();
            _src_vtep_hit_2();
            @defaultonly NoAction_144();
        }
        key = {
            meta.l3_metadata.vrf                    : exact @name("l3_metadata.vrf") ;
            hdr.ipv6.srcAddr                        : exact @name("ipv6.srcAddr") ;
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("tunnel_metadata.ingress_tunnel_type") ;
        }
        size = 4096;
        default_action = NoAction_144();
    }
    @name(".nop") action _nop_35() {
    }
    @name(".nop") action _nop_36() {
    }
    @name(".on_miss") action _on_miss_12() {
    }
    @name(".outer_multicast_route_s_g_hit") action _outer_multicast_route_s_g_hit_1(bit<16> mc_index, bit<16> mcast_rpf_group) {
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_bridge_s_g_hit") action _outer_multicast_bridge_s_g_hit_1(bit<16> mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.tunnel_metadata.tunnel_lookup = 1w1;
    }
    @name(".outer_multicast_route_sm_star_g_hit") action _outer_multicast_route_sm_star_g_hit_1(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.outer_mcast_mode = 2w1;
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_route_bidir_star_g_hit") action _outer_multicast_route_bidir_star_g_hit_1(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.outer_mcast_mode = 2w2;
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group | meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_bridge_star_g_hit") action _outer_multicast_bridge_star_g_hit_1(bit<16> mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.tunnel_metadata.tunnel_lookup = 1w1;
    }
    @name(".outer_ipv4_multicast") table _outer_ipv4_multicast {
        actions = {
            _nop_35();
            _on_miss_12();
            _outer_multicast_route_s_g_hit_1();
            _outer_multicast_bridge_s_g_hit_1();
            @defaultonly NoAction_145();
        }
        key = {
            meta.multicast_metadata.ipv4_mcast_key_type: exact @name("multicast_metadata.ipv4_mcast_key_type") ;
            meta.multicast_metadata.ipv4_mcast_key     : exact @name("multicast_metadata.ipv4_mcast_key") ;
            hdr.ipv4.srcAddr                           : exact @name("ipv4.srcAddr") ;
            hdr.ipv4.dstAddr                           : exact @name("ipv4.dstAddr") ;
        }
        size = 1024;
        default_action = NoAction_145();
    }
    @name(".outer_ipv4_multicast_star_g") table _outer_ipv4_multicast_star_g {
        actions = {
            _nop_36();
            _outer_multicast_route_sm_star_g_hit_1();
            _outer_multicast_route_bidir_star_g_hit_1();
            _outer_multicast_bridge_star_g_hit_1();
            @defaultonly NoAction_146();
        }
        key = {
            meta.multicast_metadata.ipv4_mcast_key_type: exact @name("multicast_metadata.ipv4_mcast_key_type") ;
            meta.multicast_metadata.ipv4_mcast_key     : exact @name("multicast_metadata.ipv4_mcast_key") ;
            hdr.ipv4.dstAddr                           : ternary @name("ipv4.dstAddr") ;
        }
        size = 512;
        default_action = NoAction_146();
    }
    @name(".nop") action _nop_37() {
    }
    @name(".nop") action _nop_38() {
    }
    @name(".on_miss") action _on_miss_13() {
    }
    @name(".outer_multicast_route_s_g_hit") action _outer_multicast_route_s_g_hit_2(bit<16> mc_index, bit<16> mcast_rpf_group) {
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_bridge_s_g_hit") action _outer_multicast_bridge_s_g_hit_2(bit<16> mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.tunnel_metadata.tunnel_lookup = 1w1;
    }
    @name(".outer_multicast_route_sm_star_g_hit") action _outer_multicast_route_sm_star_g_hit_2(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.outer_mcast_mode = 2w1;
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_route_bidir_star_g_hit") action _outer_multicast_route_bidir_star_g_hit_2(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.outer_mcast_mode = 2w2;
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group | meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_bridge_star_g_hit") action _outer_multicast_bridge_star_g_hit_2(bit<16> mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.tunnel_metadata.tunnel_lookup = 1w1;
    }
    @name(".outer_ipv6_multicast") table _outer_ipv6_multicast {
        actions = {
            _nop_37();
            _on_miss_13();
            _outer_multicast_route_s_g_hit_2();
            _outer_multicast_bridge_s_g_hit_2();
            @defaultonly NoAction_147();
        }
        key = {
            meta.multicast_metadata.ipv6_mcast_key_type: exact @name("multicast_metadata.ipv6_mcast_key_type") ;
            meta.multicast_metadata.ipv6_mcast_key     : exact @name("multicast_metadata.ipv6_mcast_key") ;
            hdr.ipv6.srcAddr                           : exact @name("ipv6.srcAddr") ;
            hdr.ipv6.dstAddr                           : exact @name("ipv6.dstAddr") ;
        }
        size = 1024;
        default_action = NoAction_147();
    }
    @name(".outer_ipv6_multicast_star_g") table _outer_ipv6_multicast_star_g {
        actions = {
            _nop_38();
            _outer_multicast_route_sm_star_g_hit_2();
            _outer_multicast_route_bidir_star_g_hit_2();
            _outer_multicast_bridge_star_g_hit_2();
            @defaultonly NoAction_148();
        }
        key = {
            meta.multicast_metadata.ipv6_mcast_key_type: exact @name("multicast_metadata.ipv6_mcast_key_type") ;
            meta.multicast_metadata.ipv6_mcast_key     : exact @name("multicast_metadata.ipv6_mcast_key") ;
            hdr.ipv6.dstAddr                           : ternary @name("ipv6.dstAddr") ;
        }
        size = 512;
        default_action = NoAction_148();
    }
    @name(".nop") action _nop_39() {
    }
    @name(".set_storm_control_meter") action _set_storm_control_meter(bit<8> meter_idx) {
    }
    @name(".storm_control") table _storm_control_0 {
        actions = {
            _nop_39();
            _set_storm_control_meter();
            @defaultonly NoAction_149();
        }
        key = {
            hdr.ig_intr_md.ingress_port  : exact @name("ig_intr_md.ingress_port") ;
            meta.l2_metadata.lkp_pkt_type: ternary @name("l2_metadata.lkp_pkt_type") ;
        }
        size = 512;
        default_action = NoAction_149();
    }
    @name(".nop") action _nop_40() {
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
            _nop_40();
            _set_unicast();
            _set_unicast_and_ipv6_src_is_link_local();
            _set_multicast();
            _set_multicast_and_ipv6_src_is_link_local();
            _set_broadcast();
            _set_malformed_packet();
            @defaultonly NoAction_150();
        }
        key = {
            meta.l2_metadata.lkp_mac_sa            : ternary @name("l2_metadata.lkp_mac_sa") ;
            meta.l2_metadata.lkp_mac_da            : ternary @name("l2_metadata.lkp_mac_da") ;
            meta.l3_metadata.lkp_ip_type           : ternary @name("l3_metadata.lkp_ip_type") ;
            meta.l3_metadata.lkp_ip_ttl            : ternary @name("l3_metadata.lkp_ip_ttl") ;
            meta.l3_metadata.lkp_ip_version        : ternary @name("l3_metadata.lkp_ip_version") ;
            meta.ipv4_metadata.lkp_ipv4_sa[31:24]  : ternary @name("ipv4_metadata.lkp_ipv4_sa[31:24]") ;
            meta.ipv6_metadata.lkp_ipv6_sa[127:112]: ternary @name("ipv6_metadata.lkp_ipv6_sa[127:112]") ;
        }
        size = 64;
        default_action = NoAction_150();
    }
    @name(".nop") action _nop_41() {
    }
    @name(".nop") action _nop_42() {
    }
    @name(".set_ingress_dst_port_range_id") action _set_ingress_dst_port_range_id(bit<8> range_id) {
        meta.acl_metadata.ingress_dst_port_range_id = range_id;
    }
    @name(".set_ingress_src_port_range_id") action _set_ingress_src_port_range_id(bit<8> range_id) {
        meta.acl_metadata.ingress_src_port_range_id = range_id;
    }
    @name(".ingress_l4_dst_port") table _ingress_l4_dst_port_0 {
        actions = {
            _nop_41();
            _set_ingress_dst_port_range_id();
            @defaultonly NoAction_151();
        }
        key = {
            meta.l3_metadata.lkp_l4_dport: range @name("l3_metadata.lkp_l4_dport") ;
        }
        size = 256;
        default_action = NoAction_151();
    }
    @name(".ingress_l4_src_port") table _ingress_l4_src_port_0 {
        actions = {
            _nop_42();
            _set_ingress_src_port_range_id();
            @defaultonly NoAction_152();
        }
        key = {
            meta.l3_metadata.lkp_l4_sport: range @name("l3_metadata.lkp_l4_sport") ;
        }
        size = 256;
        default_action = NoAction_152();
    }
    @name(".nop") action _nop_43() {
    }
    @name(".nop") action _nop_44() {
    }
    @name(".dmac_hit") action _dmac_hit(bit<16> ifindex) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.l2_metadata.same_if_check = meta.l2_metadata.same_if_check ^ ifindex;
    }
    @name(".dmac_multicast_hit") action _dmac_multicast_hit(bit<16> mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_b = mc_index;
    }
    @name(".dmac_miss") action _dmac_miss() {
        meta.ingress_metadata.egress_ifindex = 16w65535;
    }
    @name(".dmac_redirect_nexthop") action _dmac_redirect_nexthop(bit<16> nexthop_index) {
        meta.l2_metadata.l2_redirect = 1w1;
        meta.l2_metadata.l2_nexthop = nexthop_index;
        meta.l2_metadata.l2_nexthop_type = 1w0;
    }
    @name(".dmac_redirect_ecmp") action _dmac_redirect_ecmp(bit<16> ecmp_index) {
        meta.l2_metadata.l2_redirect = 1w1;
        meta.l2_metadata.l2_nexthop = ecmp_index;
        meta.l2_metadata.l2_nexthop_type = 1w1;
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
    @name(".dmac") table _dmac_0 {
        support_timeout = true;
        actions = {
            _nop_43();
            _dmac_hit();
            _dmac_multicast_hit();
            _dmac_miss();
            _dmac_redirect_nexthop();
            _dmac_redirect_ecmp();
            _dmac_drop();
            @defaultonly NoAction_153();
        }
        key = {
            meta.ingress_metadata.bd   : exact @name("ingress_metadata.bd") ;
            meta.l2_metadata.lkp_mac_da: exact @name("l2_metadata.lkp_mac_da") ;
        }
        size = 65536;
        default_action = NoAction_153();
    }
    @name(".smac") table _smac_0 {
        actions = {
            _nop_44();
            _smac_miss();
            _smac_hit();
            @defaultonly NoAction_154();
        }
        key = {
            meta.ingress_metadata.bd   : exact @name("ingress_metadata.bd") ;
            meta.l2_metadata.lkp_mac_sa: exact @name("l2_metadata.lkp_mac_sa") ;
        }
        size = 65536;
        default_action = NoAction_154();
    }
    @name(".nop") action _nop_89() {
    }
    @name(".acl_deny") action _acl_deny(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.acl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".acl_permit") action _acl_permit(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".acl_redirect_nexthop") action _acl_redirect_nexthop(bit<16> nexthop_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = nexthop_index;
        meta.acl_metadata.acl_nexthop_type = 1w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".acl_redirect_ecmp") action _acl_redirect_ecmp(bit<16> ecmp_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = ecmp_index;
        meta.acl_metadata.acl_nexthop_type = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".acl_mirror") action _acl_mirror(bit<32> session_id, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<2> nat_mode, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.i2e_metadata.mirror_session_id = (bit<16>)session_id;
        clone3<tuple<bit<32>, bit<16>>>(CloneType.I2E, session_id, { meta.i2e_metadata.ingress_tstamp, meta.i2e_metadata.mirror_session_id });
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".mac_acl") table _mac_acl_0 {
        actions = {
            _nop_89();
            _acl_deny();
            _acl_permit();
            _acl_redirect_nexthop();
            _acl_redirect_ecmp();
            _acl_mirror();
            @defaultonly NoAction_155();
        }
        key = {
            meta.acl_metadata.if_label   : ternary @name("acl_metadata.if_label") ;
            meta.acl_metadata.bd_label   : ternary @name("acl_metadata.bd_label") ;
            meta.l2_metadata.lkp_mac_sa  : ternary @name("l2_metadata.lkp_mac_sa") ;
            meta.l2_metadata.lkp_mac_da  : ternary @name("l2_metadata.lkp_mac_da") ;
            meta.l2_metadata.lkp_mac_type: ternary @name("l2_metadata.lkp_mac_type") ;
        }
        size = 512;
        default_action = NoAction_155();
    }
    @name(".nop") action _nop_90() {
    }
    @name(".nop") action _nop_91() {
    }
    @name(".acl_deny") action _acl_deny_0(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.acl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".acl_deny") action _acl_deny_4(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.acl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".acl_permit") action _acl_permit_0(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".acl_permit") action _acl_permit_4(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".acl_redirect_nexthop") action _acl_redirect_nexthop_0(bit<16> nexthop_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = nexthop_index;
        meta.acl_metadata.acl_nexthop_type = 1w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".acl_redirect_nexthop") action _acl_redirect_nexthop_4(bit<16> nexthop_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = nexthop_index;
        meta.acl_metadata.acl_nexthop_type = 1w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".acl_redirect_ecmp") action _acl_redirect_ecmp_0(bit<16> ecmp_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = ecmp_index;
        meta.acl_metadata.acl_nexthop_type = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".acl_redirect_ecmp") action _acl_redirect_ecmp_4(bit<16> ecmp_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<16> acl_copy_reason, bit<2> nat_mode, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = ecmp_index;
        meta.acl_metadata.acl_nexthop_type = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".acl_mirror") action _acl_mirror_0(bit<32> session_id, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<2> nat_mode, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.i2e_metadata.mirror_session_id = (bit<16>)session_id;
        clone3<tuple<bit<32>, bit<16>>>(CloneType.I2E, session_id, { meta.i2e_metadata.ingress_tstamp, meta.i2e_metadata.mirror_session_id });
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".acl_mirror") action _acl_mirror_4(bit<32> session_id, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<2> nat_mode, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.i2e_metadata.mirror_session_id = (bit<16>)session_id;
        clone3<tuple<bit<32>, bit<16>>>(CloneType.I2E, session_id, { meta.i2e_metadata.ingress_tstamp, meta.i2e_metadata.mirror_session_id });
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".ip_acl") table _ip_acl_0 {
        actions = {
            _nop_90();
            _acl_deny_0();
            _acl_permit_0();
            _acl_redirect_nexthop_0();
            _acl_redirect_ecmp_0();
            _acl_mirror_0();
            @defaultonly NoAction_156();
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
        size = 1024;
        default_action = NoAction_156();
    }
    @name(".ipv6_acl") table _ipv6_acl_0 {
        actions = {
            _nop_91();
            _acl_deny_4();
            _acl_permit_4();
            _acl_redirect_nexthop_4();
            _acl_redirect_ecmp_4();
            _acl_mirror_4();
            @defaultonly NoAction_157();
        }
        key = {
            meta.acl_metadata.if_label                 : ternary @name("acl_metadata.if_label") ;
            meta.acl_metadata.bd_label                 : ternary @name("acl_metadata.bd_label") ;
            meta.ipv6_metadata.lkp_ipv6_sa             : ternary @name("ipv6_metadata.lkp_ipv6_sa") ;
            meta.ipv6_metadata.lkp_ipv6_da             : ternary @name("ipv6_metadata.lkp_ipv6_da") ;
            meta.l3_metadata.lkp_ip_proto              : ternary @name("l3_metadata.lkp_ip_proto") ;
            meta.acl_metadata.ingress_src_port_range_id: exact @name("acl_metadata.ingress_src_port_range_id") ;
            meta.acl_metadata.ingress_dst_port_range_id: exact @name("acl_metadata.ingress_dst_port_range_id") ;
            hdr.tcp.flags                              : ternary @name("tcp.flags") ;
            meta.l3_metadata.lkp_ip_ttl                : ternary @name("l3_metadata.lkp_ip_ttl") ;
        }
        size = 512;
        default_action = NoAction_157();
    }
    @name(".nop") action _nop_92() {
    }
    @name(".racl_deny") action _racl_deny(bit<14> acl_stats_index, bit<16> acl_copy_reason, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.racl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".racl_permit") action _racl_permit(bit<14> acl_stats_index, bit<16> acl_copy_reason, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".racl_redirect_nexthop") action _racl_redirect_nexthop(bit<16> nexthop_index, bit<14> acl_stats_index, bit<16> acl_copy_reason, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.racl_redirect = 1w1;
        meta.acl_metadata.racl_nexthop = nexthop_index;
        meta.acl_metadata.racl_nexthop_type = 1w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".racl_redirect_ecmp") action _racl_redirect_ecmp(bit<16> ecmp_index, bit<14> acl_stats_index, bit<16> acl_copy_reason, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.racl_redirect = 1w1;
        meta.acl_metadata.racl_nexthop = ecmp_index;
        meta.acl_metadata.racl_nexthop_type = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".ipv4_racl") table _ipv4_racl_0 {
        actions = {
            _nop_92();
            _racl_deny();
            _racl_permit();
            _racl_redirect_nexthop();
            _racl_redirect_ecmp();
            @defaultonly NoAction_158();
        }
        key = {
            meta.acl_metadata.bd_label                 : ternary @name("acl_metadata.bd_label") ;
            meta.ipv4_metadata.lkp_ipv4_sa             : ternary @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da             : ternary @name("ipv4_metadata.lkp_ipv4_da") ;
            meta.l3_metadata.lkp_ip_proto              : ternary @name("l3_metadata.lkp_ip_proto") ;
            meta.acl_metadata.ingress_src_port_range_id: exact @name("acl_metadata.ingress_src_port_range_id") ;
            meta.acl_metadata.ingress_dst_port_range_id: exact @name("acl_metadata.ingress_dst_port_range_id") ;
        }
        size = 1024;
        default_action = NoAction_158();
    }
    @name(".on_miss") action _on_miss_14() {
    }
    @name(".on_miss") action _on_miss_15() {
    }
    @name(".fib_hit_nexthop") action _fib_hit_nexthop(bit<16> nexthop_index) {
        meta.l3_metadata.fib_hit = 1w1;
        meta.l3_metadata.fib_nexthop = nexthop_index;
        meta.l3_metadata.fib_nexthop_type = 1w0;
    }
    @name(".fib_hit_nexthop") action _fib_hit_nexthop_0(bit<16> nexthop_index) {
        meta.l3_metadata.fib_hit = 1w1;
        meta.l3_metadata.fib_nexthop = nexthop_index;
        meta.l3_metadata.fib_nexthop_type = 1w0;
    }
    @name(".fib_hit_ecmp") action _fib_hit_ecmp(bit<16> ecmp_index) {
        meta.l3_metadata.fib_hit = 1w1;
        meta.l3_metadata.fib_nexthop = ecmp_index;
        meta.l3_metadata.fib_nexthop_type = 1w1;
    }
    @name(".fib_hit_ecmp") action _fib_hit_ecmp_0(bit<16> ecmp_index) {
        meta.l3_metadata.fib_hit = 1w1;
        meta.l3_metadata.fib_nexthop = ecmp_index;
        meta.l3_metadata.fib_nexthop_type = 1w1;
    }
    @name(".ipv4_fib") table _ipv4_fib_0 {
        actions = {
            _on_miss_14();
            _fib_hit_nexthop();
            _fib_hit_ecmp();
            @defaultonly NoAction_159();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 65536;
        default_action = NoAction_159();
    }
    @name(".ipv4_fib_lpm") table _ipv4_fib_lpm_0 {
        actions = {
            _on_miss_15();
            _fib_hit_nexthop_0();
            _fib_hit_ecmp_0();
            @defaultonly NoAction_160();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da: lpm @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 32768;
        default_action = NoAction_160();
    }
    @name(".nop") action _nop_93() {
    }
    @name(".racl_deny") action _racl_deny_0(bit<14> acl_stats_index, bit<16> acl_copy_reason, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.racl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".racl_permit") action _racl_permit_0(bit<14> acl_stats_index, bit<16> acl_copy_reason, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".racl_redirect_nexthop") action _racl_redirect_nexthop_0(bit<16> nexthop_index, bit<14> acl_stats_index, bit<16> acl_copy_reason, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.racl_redirect = 1w1;
        meta.acl_metadata.racl_nexthop = nexthop_index;
        meta.acl_metadata.racl_nexthop_type = 1w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".racl_redirect_ecmp") action _racl_redirect_ecmp_0(bit<16> ecmp_index, bit<14> acl_stats_index, bit<16> acl_copy_reason, bit<3> ingress_cos, bit<8> tc, bit<2> color) {
        meta.acl_metadata.racl_redirect = 1w1;
        meta.acl_metadata.racl_nexthop = ecmp_index;
        meta.acl_metadata.racl_nexthop_type = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        hdr.ig_intr_md_for_tm.ingress_cos = ingress_cos;
        meta.qos_metadata.lkp_tc = tc;
        meta.meter_metadata.packet_color = color;
    }
    @name(".ipv6_racl") table _ipv6_racl_0 {
        actions = {
            _nop_93();
            _racl_deny_0();
            _racl_permit_0();
            _racl_redirect_nexthop_0();
            _racl_redirect_ecmp_0();
            @defaultonly NoAction_161();
        }
        key = {
            meta.acl_metadata.bd_label                 : ternary @name("acl_metadata.bd_label") ;
            meta.ipv6_metadata.lkp_ipv6_sa             : ternary @name("ipv6_metadata.lkp_ipv6_sa") ;
            meta.ipv6_metadata.lkp_ipv6_da             : ternary @name("ipv6_metadata.lkp_ipv6_da") ;
            meta.l3_metadata.lkp_ip_proto              : ternary @name("l3_metadata.lkp_ip_proto") ;
            meta.acl_metadata.ingress_src_port_range_id: exact @name("acl_metadata.ingress_src_port_range_id") ;
            meta.acl_metadata.ingress_dst_port_range_id: exact @name("acl_metadata.ingress_dst_port_range_id") ;
        }
        size = 512;
        default_action = NoAction_161();
    }
    @name(".on_miss") action _on_miss_16() {
    }
    @name(".on_miss") action _on_miss_17() {
    }
    @name(".fib_hit_nexthop") action _fib_hit_nexthop_5(bit<16> nexthop_index) {
        meta.l3_metadata.fib_hit = 1w1;
        meta.l3_metadata.fib_nexthop = nexthop_index;
        meta.l3_metadata.fib_nexthop_type = 1w0;
    }
    @name(".fib_hit_nexthop") action _fib_hit_nexthop_6(bit<16> nexthop_index) {
        meta.l3_metadata.fib_hit = 1w1;
        meta.l3_metadata.fib_nexthop = nexthop_index;
        meta.l3_metadata.fib_nexthop_type = 1w0;
    }
    @name(".fib_hit_ecmp") action _fib_hit_ecmp_5(bit<16> ecmp_index) {
        meta.l3_metadata.fib_hit = 1w1;
        meta.l3_metadata.fib_nexthop = ecmp_index;
        meta.l3_metadata.fib_nexthop_type = 1w1;
    }
    @name(".fib_hit_ecmp") action _fib_hit_ecmp_6(bit<16> ecmp_index) {
        meta.l3_metadata.fib_hit = 1w1;
        meta.l3_metadata.fib_nexthop = ecmp_index;
        meta.l3_metadata.fib_nexthop_type = 1w1;
    }
    @name(".ipv6_fib") table _ipv6_fib_0 {
        actions = {
            _on_miss_16();
            _fib_hit_nexthop_5();
            _fib_hit_ecmp_5();
            @defaultonly NoAction_162();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_da: exact @name("ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 16384;
        default_action = NoAction_162();
    }
    @name(".ipv6_fib_lpm") table _ipv6_fib_lpm_0 {
        actions = {
            _on_miss_17();
            _fib_hit_nexthop_6();
            _fib_hit_ecmp_6();
            @defaultonly NoAction_163();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_da: lpm @name("ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 16384;
        default_action = NoAction_163();
    }
    @name(".ipv4_multicast_route_s_g_stats") direct_counter(CounterType.packets) _ipv4_multicast_route_s_g_stats;
    @name(".ipv4_multicast_route_star_g_stats") direct_counter(CounterType.packets) _ipv4_multicast_route_star_g_stats;
    @name(".on_miss") action _on_miss_18() {
    }
    @name(".multicast_bridge_s_g_hit") action _multicast_bridge_s_g_hit_1(bit<16> mc_index) {
        meta.multicast_metadata.multicast_bridge_mc_index = mc_index;
        meta.multicast_metadata.mcast_bridge_hit = 1w1;
    }
    @name(".nop") action _nop_94() {
    }
    @name(".multicast_bridge_star_g_hit") action _multicast_bridge_star_g_hit_1(bit<16> mc_index) {
        meta.multicast_metadata.multicast_bridge_mc_index = mc_index;
        meta.multicast_metadata.mcast_bridge_hit = 1w1;
    }
    @name(".ipv4_multicast_bridge") table _ipv4_multicast_bridge {
        actions = {
            _on_miss_18();
            _multicast_bridge_s_g_hit_1();
            @defaultonly NoAction_164();
        }
        key = {
            meta.ingress_metadata.bd      : exact @name("ingress_metadata.bd") ;
            meta.ipv4_metadata.lkp_ipv4_sa: exact @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 4096;
        default_action = NoAction_164();
    }
    @name(".ipv4_multicast_bridge_star_g") table _ipv4_multicast_bridge_star_g {
        actions = {
            _nop_94();
            _multicast_bridge_star_g_hit_1();
            @defaultonly NoAction_165();
        }
        key = {
            meta.ingress_metadata.bd      : exact @name("ingress_metadata.bd") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 2048;
        default_action = NoAction_165();
    }
    @name(".on_miss") action _on_miss_19() {
        _ipv4_multicast_route_s_g_stats.count();
    }
    @name(".multicast_route_s_g_hit") action _multicast_route_s_g_hit_1(bit<16> mc_index, bit<16> mcast_rpf_group) {
        _ipv4_multicast_route_s_g_stats.count();
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_mode = 2w1;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".ipv4_multicast_route") table _ipv4_multicast_route {
        actions = {
            _on_miss_19();
            _multicast_route_s_g_hit_1();
            @defaultonly NoAction_166();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_sa: exact @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 4096;
        counters = _ipv4_multicast_route_s_g_stats;
        default_action = NoAction_166();
    }
    @name(".multicast_route_star_g_miss") action _multicast_route_star_g_miss_1() {
        _ipv4_multicast_route_star_g_stats.count();
        meta.l3_metadata.l3_copy = 1w1;
    }
    @name(".multicast_route_sm_star_g_hit") action _multicast_route_sm_star_g_hit_1(bit<16> mc_index, bit<16> mcast_rpf_group) {
        _ipv4_multicast_route_star_g_stats.count();
        meta.multicast_metadata.mcast_mode = 2w1;
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".multicast_route_bidir_star_g_hit") action _multicast_route_bidir_star_g_hit_1(bit<16> mc_index, bit<16> mcast_rpf_group) {
        _ipv4_multicast_route_star_g_stats.count();
        meta.multicast_metadata.mcast_mode = 2w2;
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group | meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".ipv4_multicast_route_star_g") table _ipv4_multicast_route_star_g {
        actions = {
            _multicast_route_star_g_miss_1();
            _multicast_route_sm_star_g_hit_1();
            _multicast_route_bidir_star_g_hit_1();
            @defaultonly NoAction_167();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 2048;
        counters = _ipv4_multicast_route_star_g_stats;
        default_action = NoAction_167();
    }
    @name(".ipv6_multicast_route_s_g_stats") direct_counter(CounterType.packets) _ipv6_multicast_route_s_g_stats;
    @name(".ipv6_multicast_route_star_g_stats") direct_counter(CounterType.packets) _ipv6_multicast_route_star_g_stats;
    @name(".on_miss") action _on_miss_20() {
    }
    @name(".multicast_bridge_s_g_hit") action _multicast_bridge_s_g_hit_2(bit<16> mc_index) {
        meta.multicast_metadata.multicast_bridge_mc_index = mc_index;
        meta.multicast_metadata.mcast_bridge_hit = 1w1;
    }
    @name(".nop") action _nop_95() {
    }
    @name(".multicast_bridge_star_g_hit") action _multicast_bridge_star_g_hit_2(bit<16> mc_index) {
        meta.multicast_metadata.multicast_bridge_mc_index = mc_index;
        meta.multicast_metadata.mcast_bridge_hit = 1w1;
    }
    @name(".ipv6_multicast_bridge") table _ipv6_multicast_bridge {
        actions = {
            _on_miss_20();
            _multicast_bridge_s_g_hit_2();
            @defaultonly NoAction_168();
        }
        key = {
            meta.ingress_metadata.bd      : exact @name("ingress_metadata.bd") ;
            meta.ipv6_metadata.lkp_ipv6_sa: exact @name("ipv6_metadata.lkp_ipv6_sa") ;
            meta.ipv6_metadata.lkp_ipv6_da: exact @name("ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 512;
        default_action = NoAction_168();
    }
    @name(".ipv6_multicast_bridge_star_g") table _ipv6_multicast_bridge_star_g {
        actions = {
            _nop_95();
            _multicast_bridge_star_g_hit_2();
            @defaultonly NoAction_169();
        }
        key = {
            meta.ingress_metadata.bd      : exact @name("ingress_metadata.bd") ;
            meta.ipv6_metadata.lkp_ipv6_da: exact @name("ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 512;
        default_action = NoAction_169();
    }
    @name(".on_miss") action _on_miss_27() {
        _ipv6_multicast_route_s_g_stats.count();
    }
    @name(".multicast_route_s_g_hit") action _multicast_route_s_g_hit_2(bit<16> mc_index, bit<16> mcast_rpf_group) {
        _ipv6_multicast_route_s_g_stats.count();
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_mode = 2w1;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".ipv6_multicast_route") table _ipv6_multicast_route {
        actions = {
            _on_miss_27();
            _multicast_route_s_g_hit_2();
            @defaultonly NoAction_170();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_sa: exact @name("ipv6_metadata.lkp_ipv6_sa") ;
            meta.ipv6_metadata.lkp_ipv6_da: exact @name("ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 512;
        counters = _ipv6_multicast_route_s_g_stats;
        default_action = NoAction_170();
    }
    @name(".multicast_route_star_g_miss") action _multicast_route_star_g_miss_2() {
        _ipv6_multicast_route_star_g_stats.count();
        meta.l3_metadata.l3_copy = 1w1;
    }
    @name(".multicast_route_sm_star_g_hit") action _multicast_route_sm_star_g_hit_2(bit<16> mc_index, bit<16> mcast_rpf_group) {
        _ipv6_multicast_route_star_g_stats.count();
        meta.multicast_metadata.mcast_mode = 2w1;
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".multicast_route_bidir_star_g_hit") action _multicast_route_bidir_star_g_hit_2(bit<16> mc_index, bit<16> mcast_rpf_group) {
        _ipv6_multicast_route_star_g_stats.count();
        meta.multicast_metadata.mcast_mode = 2w2;
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group | meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".ipv6_multicast_route_star_g") table _ipv6_multicast_route_star_g {
        actions = {
            _multicast_route_star_g_miss_2();
            _multicast_route_sm_star_g_hit_2();
            _multicast_route_bidir_star_g_hit_2();
            @defaultonly NoAction_171();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_da: exact @name("ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 512;
        counters = _ipv6_multicast_route_star_g_stats;
        default_action = NoAction_171();
    }
    @name(".on_miss") action _on_miss_28() {
    }
    @name(".on_miss") action _on_miss_29() {
    }
    @name(".on_miss") action _on_miss_30() {
    }
    @name(".set_dst_nat_nexthop_index") action _set_dst_nat_nexthop_index(bit<16> nexthop_index, bit<1> nexthop_type, bit<14> nat_rewrite_index) {
        meta.nat_metadata.nat_nexthop = nexthop_index;
        meta.nat_metadata.nat_nexthop_type = nexthop_type;
        meta.nat_metadata.nat_rewrite_index = nat_rewrite_index;
        meta.nat_metadata.nat_hit = 1w1;
    }
    @name(".set_dst_nat_nexthop_index") action _set_dst_nat_nexthop_index_2(bit<16> nexthop_index, bit<1> nexthop_type, bit<14> nat_rewrite_index) {
        meta.nat_metadata.nat_nexthop = nexthop_index;
        meta.nat_metadata.nat_nexthop_type = nexthop_type;
        meta.nat_metadata.nat_rewrite_index = nat_rewrite_index;
        meta.nat_metadata.nat_hit = 1w1;
    }
    @name(".nop") action _nop_96() {
    }
    @name(".set_src_nat_rewrite_index") action _set_src_nat_rewrite_index(bit<14> nat_rewrite_index) {
        meta.nat_metadata.nat_rewrite_index = nat_rewrite_index;
    }
    @name(".set_src_nat_rewrite_index") action _set_src_nat_rewrite_index_2(bit<14> nat_rewrite_index) {
        meta.nat_metadata.nat_rewrite_index = nat_rewrite_index;
    }
    @name(".set_twice_nat_nexthop_index") action _set_twice_nat_nexthop_index(bit<16> nexthop_index, bit<1> nexthop_type, bit<14> nat_rewrite_index) {
        meta.nat_metadata.nat_nexthop = nexthop_index;
        meta.nat_metadata.nat_nexthop_type = nexthop_type;
        meta.nat_metadata.nat_rewrite_index = nat_rewrite_index;
        meta.nat_metadata.nat_hit = 1w1;
    }
    @name(".set_twice_nat_nexthop_index") action _set_twice_nat_nexthop_index_2(bit<16> nexthop_index, bit<1> nexthop_type, bit<14> nat_rewrite_index) {
        meta.nat_metadata.nat_nexthop = nexthop_index;
        meta.nat_metadata.nat_nexthop_type = nexthop_type;
        meta.nat_metadata.nat_rewrite_index = nat_rewrite_index;
        meta.nat_metadata.nat_hit = 1w1;
    }
    @name(".nat_dst") table _nat_dst_0 {
        actions = {
            _on_miss_28();
            _set_dst_nat_nexthop_index();
            @defaultonly NoAction_172();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("ipv4_metadata.lkp_ipv4_da") ;
            meta.l3_metadata.lkp_ip_proto : exact @name("l3_metadata.lkp_ip_proto") ;
            meta.l3_metadata.lkp_l4_dport : exact @name("l3_metadata.lkp_l4_dport") ;
        }
        size = 4096;
        default_action = NoAction_172();
    }
    @name(".nat_flow") table _nat_flow_0 {
        actions = {
            _nop_96();
            _set_src_nat_rewrite_index();
            _set_dst_nat_nexthop_index_2();
            _set_twice_nat_nexthop_index();
            @defaultonly NoAction_173();
        }
        key = {
            meta.l3_metadata.vrf          : ternary @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_sa: ternary @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da: ternary @name("ipv4_metadata.lkp_ipv4_da") ;
            meta.l3_metadata.lkp_ip_proto : ternary @name("l3_metadata.lkp_ip_proto") ;
            meta.l3_metadata.lkp_l4_sport : ternary @name("l3_metadata.lkp_l4_sport") ;
            meta.l3_metadata.lkp_l4_dport : ternary @name("l3_metadata.lkp_l4_dport") ;
        }
        size = 512;
        default_action = NoAction_173();
    }
    @name(".nat_src") table _nat_src_0 {
        actions = {
            _on_miss_29();
            _set_src_nat_rewrite_index_2();
            @defaultonly NoAction_174();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_sa: exact @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.l3_metadata.lkp_ip_proto : exact @name("l3_metadata.lkp_ip_proto") ;
            meta.l3_metadata.lkp_l4_sport : exact @name("l3_metadata.lkp_l4_sport") ;
        }
        size = 4096;
        default_action = NoAction_174();
    }
    @name(".nat_twice") table _nat_twice_0 {
        actions = {
            _on_miss_30();
            _set_twice_nat_nexthop_index_2();
            @defaultonly NoAction_175();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_sa: exact @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("ipv4_metadata.lkp_ipv4_da") ;
            meta.l3_metadata.lkp_ip_proto : exact @name("l3_metadata.lkp_ip_proto") ;
            meta.l3_metadata.lkp_l4_sport : exact @name("l3_metadata.lkp_l4_sport") ;
            meta.l3_metadata.lkp_l4_dport : exact @name("l3_metadata.lkp_l4_dport") ;
        }
        size = 4096;
        default_action = NoAction_175();
    }
    @name(".compute_lkp_ipv4_hash") action _compute_lkp_ipv4_hash() {
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>, bit<8>, bit<16>, bit<16>>, bit<32>>(meta.hash_metadata.hash1, HashAlgorithm.crc16, 16w0, { meta.ipv4_metadata.lkp_ipv4_sa, meta.ipv4_metadata.lkp_ipv4_da, meta.l3_metadata.lkp_ip_proto, meta.l3_metadata.lkp_l4_sport, meta.l3_metadata.lkp_l4_dport }, 32w65536);
    }
    @name(".compute_lkp_ipv6_hash") action _compute_lkp_ipv6_hash() {
        hash<bit<16>, bit<16>, tuple<bit<128>, bit<128>, bit<8>, bit<16>, bit<16>>, bit<32>>(meta.hash_metadata.hash1, HashAlgorithm.crc16, 16w0, { meta.ipv6_metadata.lkp_ipv6_sa, meta.ipv6_metadata.lkp_ipv6_da, meta.l3_metadata.lkp_ip_proto, meta.l3_metadata.lkp_l4_sport, meta.l3_metadata.lkp_l4_dport }, 32w65536);
    }
    @name(".compute_lkp_non_ip_hash") action _compute_lkp_non_ip_hash() {
        hash<bit<16>, bit<16>, tuple<bit<16>, bit<48>, bit<48>, bit<16>>, bit<32>>(meta.hash_metadata.hash1, HashAlgorithm.crc16, 16w0, { meta.ingress_metadata.ifindex, meta.l2_metadata.lkp_mac_sa, meta.l2_metadata.lkp_mac_da, meta.l2_metadata.lkp_mac_type }, 32w65536);
    }
    @name(".compute_other_hashes") action _compute_other_hashes() {
        meta.hash_metadata.hash2 = meta.hash_metadata.hash1 >> 2;
        hdr.ig_intr_md_for_tm.level1_mcast_hash = (bit<13>)meta.hash_metadata.hash1;
        hdr.ig_intr_md_for_tm.level2_mcast_hash = (bit<13>)meta.hash_metadata.hash1 >> 3;
        meta.hash_metadata.entropy_hash = meta.hash_metadata.hash1;
    }
    @name(".compute_ipv4_hashes") table _compute_ipv4_hashes_0 {
        actions = {
            _compute_lkp_ipv4_hash();
            @defaultonly NoAction_176();
        }
        key = {
            hdr.ethernet.isValid(): exact @name("ethernet.$valid$") ;
        }
        default_action = NoAction_176();
    }
    @name(".compute_ipv6_hashes") table _compute_ipv6_hashes_0 {
        actions = {
            _compute_lkp_ipv6_hash();
            @defaultonly NoAction_177();
        }
        key = {
            hdr.ethernet.isValid(): exact @name("ethernet.$valid$") ;
        }
        default_action = NoAction_177();
    }
    @name(".compute_non_ip_hashes") table _compute_non_ip_hashes_0 {
        actions = {
            _compute_lkp_non_ip_hash();
            @defaultonly NoAction_178();
        }
        key = {
            hdr.ethernet.isValid(): exact @name("ethernet.$valid$") ;
        }
        default_action = NoAction_178();
    }
    @ternary(1) @name(".compute_other_hashes") table _compute_other_hashes_2 {
        actions = {
            _compute_other_hashes();
            @defaultonly NoAction_179();
        }
        key = {
            hdr.ethernet.isValid(): exact @name("ethernet.$valid$") ;
        }
        default_action = NoAction_179();
    }
    @min_width(32) @name(".ingress_bd_stats") counter(32w16384, CounterType.packets_and_bytes) _ingress_bd_stats_1;
    @name(".update_ingress_bd_stats") action _update_ingress_bd_stats() {
        _ingress_bd_stats_1.count((bit<32>)meta.l2_metadata.bd_stats_idx);
    }
    @name(".ingress_bd_stats") table _ingress_bd_stats_2 {
        actions = {
            _update_ingress_bd_stats();
            @defaultonly NoAction_180();
        }
        size = 16384;
        default_action = NoAction_180();
    }
    @min_width(16) @name(".acl_stats") counter(32w8192, CounterType.packets_and_bytes) _acl_stats_1;
    @name(".acl_stats_update") action _acl_stats_update() {
        _acl_stats_1.count((bit<32>)meta.acl_metadata.acl_stats_index);
    }
    @name(".acl_stats") table _acl_stats_2 {
        actions = {
            _acl_stats_update();
            @defaultonly NoAction_181();
        }
        size = 8192;
        default_action = NoAction_181();
    }
    @name(".storm_control_stats") direct_counter(CounterType.packets) _storm_control_stats_1;
    @name(".nop") action _nop_97() {
        _storm_control_stats_1.count();
    }
    @name(".storm_control_stats") table _storm_control_stats_2 {
        actions = {
            _nop_97();
            @defaultonly NoAction_182();
        }
        key = {
            meta.meter_metadata.packet_color: exact @name("meter_metadata.packet_color") ;
            hdr.ig_intr_md.ingress_port     : exact @name("ig_intr_md.ingress_port") ;
        }
        size = 8;
        counters = _storm_control_stats_1;
        default_action = NoAction_182();
    }
    @name(".nop") action _nop_98() {
    }
    @name(".set_l2_redirect_action") action _set_l2_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.l2_metadata.l2_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.l2_metadata.l2_nexthop_type;
        meta.ingress_metadata.egress_ifindex = 16w0;
        invalidate<bit<16>>(hdr.ig_intr_md_for_tm.mcast_grp_b);
    }
    @name(".set_fib_redirect_action") action _set_fib_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.l3_metadata.fib_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.l3_metadata.fib_nexthop_type;
        meta.l3_metadata.routed = 1w1;
        invalidate<bit<16>>(hdr.ig_intr_md_for_tm.mcast_grp_b);
        meta.fabric_metadata.reason_code = 16w0x217;
    }
    @name(".set_cpu_redirect_action") action _set_cpu_redirect_action(bit<16> cpu_ifindex) {
        meta.l3_metadata.routed = 1w0;
        meta.ingress_metadata.egress_ifindex = cpu_ifindex;
    }
    @name(".set_acl_redirect_action") action _set_acl_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.acl_metadata.acl_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.acl_metadata.acl_nexthop_type;
        meta.ingress_metadata.egress_ifindex = 16w0;
        invalidate<bit<16>>(hdr.ig_intr_md_for_tm.mcast_grp_b);
    }
    @name(".set_racl_redirect_action") action _set_racl_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.acl_metadata.racl_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.acl_metadata.racl_nexthop_type;
        meta.l3_metadata.routed = 1w1;
        meta.ingress_metadata.egress_ifindex = 16w0;
        invalidate<bit<16>>(hdr.ig_intr_md_for_tm.mcast_grp_b);
    }
    @name(".set_nat_redirect_action") action _set_nat_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.nat_metadata.nat_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.nat_metadata.nat_nexthop_type;
        meta.l3_metadata.routed = 1w1;
        invalidate<bit<16>>(hdr.ig_intr_md_for_tm.mcast_grp_b);
    }
    @name(".set_multicast_route_action") action _set_multicast_route_action() {
        meta.ingress_metadata.egress_ifindex = 16w0;
        hdr.ig_intr_md_for_tm.mcast_grp_b = meta.multicast_metadata.multicast_route_mc_index;
        meta.l3_metadata.routed = 1w1;
        meta.l3_metadata.same_bd_check = 16w0xffff;
    }
    @name(".set_multicast_bridge_action") action _set_multicast_bridge_action() {
        meta.ingress_metadata.egress_ifindex = 16w0;
        hdr.ig_intr_md_for_tm.mcast_grp_b = meta.multicast_metadata.multicast_bridge_mc_index;
    }
    @name(".set_multicast_flood") action _set_multicast_flood() {
        meta.ingress_metadata.egress_ifindex = 16w65535;
    }
    @name(".set_multicast_drop") action _set_multicast_drop() {
        meta.ingress_metadata.drop_flag = 1w1;
        meta.ingress_metadata.drop_reason = 8w44;
    }
    @name(".fwd_result") table _fwd_result_0 {
        actions = {
            _nop_98();
            _set_l2_redirect_action();
            _set_fib_redirect_action();
            _set_cpu_redirect_action();
            _set_acl_redirect_action();
            _set_racl_redirect_action();
            _set_nat_redirect_action();
            _set_multicast_route_action();
            _set_multicast_bridge_action();
            _set_multicast_flood();
            _set_multicast_drop();
            @defaultonly NoAction_183();
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
        default_action = NoAction_183();
    }
    @name(".nop") action _nop_99() {
    }
    @name(".nop") action _nop_100() {
    }
    @name(".set_ecmp_nexthop_details") action _set_ecmp_nexthop_details(bit<16> ifindex, bit<16> bd, bit<16> nhop_index, bit<1> tunnel) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.l3_metadata.nexthop_index = nhop_index;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.l2_metadata.same_if_check = meta.l2_metadata.same_if_check ^ ifindex;
        meta.tunnel_metadata.tunnel_if_check = meta.tunnel_metadata.tunnel_terminate ^ tunnel;
        hdr.ig_intr_md_for_tm.disable_ucast_cutthru = meta.l2_metadata.non_ip_packet & tunnel;
    }
    @name(".set_ecmp_nexthop_details_for_post_routed_flood") action _set_ecmp_nexthop_details_for_post_routed_flood(bit<16> bd, bit<16> uuc_mc_index, bit<16> nhop_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_b = uuc_mc_index;
        meta.l3_metadata.nexthop_index = nhop_index;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
    }
    @name(".set_nexthop_details") action _set_nexthop_details(bit<16> ifindex, bit<16> bd, bit<1> tunnel) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.l2_metadata.same_if_check = meta.l2_metadata.same_if_check ^ ifindex;
        meta.tunnel_metadata.tunnel_if_check = meta.tunnel_metadata.tunnel_terminate ^ tunnel;
        hdr.ig_intr_md_for_tm.disable_ucast_cutthru = meta.l2_metadata.non_ip_packet & tunnel;
    }
    @name(".set_nexthop_details_for_post_routed_flood") action _set_nexthop_details_for_post_routed_flood(bit<16> bd, bit<16> uuc_mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_b = uuc_mc_index;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
    }
    @name(".ecmp_group") table _ecmp_group_0 {
        actions = {
            _nop_99();
            _set_ecmp_nexthop_details();
            _set_ecmp_nexthop_details_for_post_routed_flood();
            @defaultonly NoAction_184();
        }
        key = {
            meta.l3_metadata.nexthop_index: exact @name("l3_metadata.nexthop_index") ;
            meta.hash_metadata.hash1      : selector @name("hash_metadata.hash1") ;
        }
        size = 1024;
        implementation = ecmp_action_profile;
        default_action = NoAction_184();
    }
    @name(".nexthop") table _nexthop_0 {
        actions = {
            _nop_100();
            _set_nexthop_details();
            _set_nexthop_details_for_post_routed_flood();
            @defaultonly NoAction_185();
        }
        key = {
            meta.l3_metadata.nexthop_index: exact @name("l3_metadata.nexthop_index") ;
        }
        size = 49152;
        default_action = NoAction_185();
    }
    @name(".nop") action _nop_101() {
    }
    @name(".set_bd_flood_mc_index") action _set_bd_flood_mc_index(bit<16> mc_index) {
        hdr.ig_intr_md_for_tm.mcast_grp_b = mc_index;
    }
    @name(".bd_flood") table _bd_flood_0 {
        actions = {
            _nop_101();
            _set_bd_flood_mc_index();
            @defaultonly NoAction_186();
        }
        key = {
            meta.ingress_metadata.bd     : exact @name("ingress_metadata.bd") ;
            meta.l2_metadata.lkp_pkt_type: exact @name("l2_metadata.lkp_pkt_type") ;
        }
        size = 49152;
        default_action = NoAction_186();
    }
    @name(".set_lag_miss") action _set_lag_miss() {
    }
    @name(".set_lag_port") action _set_lag_port(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".lag_group") table _lag_group_0 {
        actions = {
            _set_lag_miss();
            _set_lag_port();
            @defaultonly NoAction_187();
        }
        key = {
            meta.ingress_metadata.egress_ifindex: exact @name("ingress_metadata.egress_ifindex") ;
            meta.hash_metadata.hash2            : selector @name("hash_metadata.hash2") ;
        }
        size = 1024;
        implementation = lag_action_profile;
        default_action = NoAction_187();
    }
    @name(".nop") action _nop_102() {
    }
    @name(".generate_learn_notify") action _generate_learn_notify() {
        digest<mac_learn_digest>(32w0, { meta.ingress_metadata.bd, meta.l2_metadata.lkp_mac_sa, meta.ingress_metadata.ifindex });
    }
    @name(".learn_notify") table _learn_notify_0 {
        actions = {
            _nop_102();
            _generate_learn_notify();
            @defaultonly NoAction_188();
        }
        key = {
            meta.l2_metadata.l2_src_miss: ternary @name("l2_metadata.l2_src_miss") ;
            meta.l2_metadata.l2_src_move: ternary @name("l2_metadata.l2_src_move") ;
            meta.l2_metadata.stp_state  : ternary @name("l2_metadata.stp_state") ;
        }
        size = 512;
        default_action = NoAction_188();
    }
    @name(".nop") action _nop_103() {
    }
    @name(".set_icos") action _set_icos(bit<3> icos) {
        hdr.ig_intr_md_for_tm.ingress_cos = icos;
    }
    @name(".set_queue") action _set_queue(bit<5> qid) {
        hdr.ig_intr_md_for_tm.qid = qid;
    }
    @name(".set_icos_and_queue") action _set_icos_and_queue(bit<3> icos, bit<5> qid) {
        hdr.ig_intr_md_for_tm.ingress_cos = icos;
        hdr.ig_intr_md_for_tm.qid = qid;
    }
    @name(".traffic_class") table _traffic_class_0 {
        actions = {
            _nop_103();
            _set_icos();
            _set_queue();
            _set_icos_and_queue();
            @defaultonly NoAction_189();
        }
        key = {
            meta.qos_metadata.tc_qos_group: ternary @name("qos_metadata.tc_qos_group") ;
            meta.qos_metadata.lkp_tc      : ternary @name("qos_metadata.lkp_tc") ;
        }
        size = 512;
        default_action = NoAction_189();
    }
    @name(".drop_stats") counter(32w256, CounterType.packets) _drop_stats_2;
    @name(".drop_stats_2") counter(32w256, CounterType.packets) _drop_stats_3;
    @name(".drop_stats_update") action _drop_stats_update() {
        _drop_stats_3.count((bit<32>)meta.ingress_metadata.drop_reason);
    }
    @name(".nop") action _nop_104() {
    }
    @name(".copy_to_cpu") action _copy_to_cpu(bit<5> qid, bit<8> meter_id, bit<3> icos) {
        hdr.ig_intr_md_for_tm.qid = qid;
        hdr.ig_intr_md_for_tm.ingress_cos = icos;
        hdr.ig_intr_md_for_tm.copy_to_cpu = 1w1;
    }
    @name(".redirect_to_cpu") action _redirect_to_cpu(bit<5> qid, bit<8> meter_id, bit<3> icos) {
        hdr.ig_intr_md_for_tm.qid = qid;
        hdr.ig_intr_md_for_tm.ingress_cos = icos;
        hdr.ig_intr_md_for_tm.copy_to_cpu = 1w1;
        mark_to_drop();
    }
    @name(".copy_to_cpu_with_reason") action _copy_to_cpu_with_reason(bit<16> reason_code, bit<5> qid, bit<8> meter_id, bit<3> icos) {
        meta.fabric_metadata.reason_code = reason_code;
        hdr.ig_intr_md_for_tm.qid = qid;
        hdr.ig_intr_md_for_tm.ingress_cos = icos;
        hdr.ig_intr_md_for_tm.copy_to_cpu = 1w1;
    }
    @name(".redirect_to_cpu_with_reason") action _redirect_to_cpu_with_reason(bit<16> reason_code, bit<5> qid, bit<8> meter_id, bit<3> icos) {
        meta.fabric_metadata.reason_code = reason_code;
        hdr.ig_intr_md_for_tm.qid = qid;
        hdr.ig_intr_md_for_tm.ingress_cos = icos;
        hdr.ig_intr_md_for_tm.copy_to_cpu = 1w1;
        mark_to_drop();
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
            @defaultonly NoAction_190();
        }
        size = 256;
        default_action = NoAction_190();
    }
    @name(".system_acl") table _system_acl_0 {
        actions = {
            _nop_104();
            _redirect_to_cpu();
            _redirect_to_cpu_with_reason();
            _copy_to_cpu();
            _copy_to_cpu_with_reason();
            _drop_packet_0();
            _drop_packet_with_reason();
            @defaultonly NoAction_191();
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
        default_action = NoAction_191();
    }
    apply {
        if (hdr.ig_intr_md.resubmit_flag == 1w0) 
            _ingress_port_mapping_0.apply();
        _ingress_port_properties_0.apply();
        _switch_config_params_0.apply();
        switch (_validate_outer_ethernet_0.apply().action_run) {
            default: {
                if (hdr.ipv4.isValid()) 
                    _validate_outer_ipv4_packet.apply();
                else 
                    if (hdr.ipv6.isValid()) 
                        _validate_outer_ipv6_packet.apply();
                    else 
                        ;
            }
            _malformed_outer_ethernet_packet: {
            }
        }

        _port_vlan_mapping_0.apply();
        if (meta.ingress_metadata.port_type == 2w0 && meta.l2_metadata.stp_group != 10w0) 
            _spanning_tree_0.apply();
        if (meta.ingress_metadata.bypass_lookups & 16w0x8 == 16w0) 
            if (meta.qos_metadata.trust_dscp == 1w1) 
                _ingress_qos_map_dscp_0.apply();
            else 
                if (meta.qos_metadata.trust_pcp == 1w1) 
                    _ingress_qos_map_pcp_0.apply();
        if (meta.ingress_metadata.port_type != 2w0) 
            _fabric_ingress_dst_lkp.apply();
        if (meta.tunnel_metadata.ingress_tunnel_type != 5w0) 
            switch (_outer_rmac_0.apply().action_run) {
                default: {
                    if (hdr.ipv4.isValid()) {
                        _ipv4_src_vtep.apply();
                        _ipv4_dest_vtep.apply();
                    }
                    else 
                        if (hdr.ipv6.isValid()) {
                            _ipv6_src_vtep.apply();
                            _ipv6_dest_vtep.apply();
                        }
                }
                _on_miss_9: {
                    if (hdr.ipv4.isValid()) 
                        switch (_outer_ipv4_multicast.apply().action_run) {
                            _on_miss_12: {
                                _outer_ipv4_multicast_star_g.apply();
                            }
                        }

                    else 
                        if (hdr.ipv6.isValid()) 
                            switch (_outer_ipv6_multicast.apply().action_run) {
                                _on_miss_13: {
                                    _outer_ipv6_multicast_star_g.apply();
                                }
                            }

                }
            }

        if (meta.tunnel_metadata.tunnel_lookup == 1w1 || meta.multicast_metadata.outer_mcast_route_hit == 1w1 && (meta.multicast_metadata.outer_mcast_mode == 2w1 && meta.multicast_metadata.mcast_rpf_group == 16w0 || meta.multicast_metadata.outer_mcast_mode == 2w2 && meta.multicast_metadata.mcast_rpf_group != 16w0)) 
            switch (_tunnel_check_0.apply().action_run) {
                _tunnel_check_pass: {
                    switch (_tunnel_0.apply().action_run) {
                        _tunnel_lookup_miss: {
                            _tunnel_lookup_miss_2.apply();
                        }
                    }

                }
            }

        else 
            _adjust_lkp_fields_0.apply();
        if (meta.ingress_metadata.port_type == 2w0) 
            _storm_control_0.apply();
        if (meta.ingress_metadata.port_type != 2w1) {
            if (meta.ingress_metadata.bypass_lookups & 16w0x40 == 16w0 && meta.ingress_metadata.drop_flag == 1w0) 
                _validate_packet_0.apply();
            _ingress_l4_src_port_0.apply();
            _ingress_l4_dst_port_0.apply();
            if (meta.ingress_metadata.bypass_lookups & 16w0x80 == 16w0 && meta.ingress_metadata.port_type == 2w0) 
                _smac_0.apply();
            if (meta.ingress_metadata.bypass_lookups & 16w0x1 == 16w0) 
                _dmac_0.apply();
            if (meta.l3_metadata.lkp_ip_type == 2w0) 
                if (meta.ingress_metadata.bypass_lookups & 16w0x4 == 16w0) 
                    _mac_acl_0.apply();
            else 
                if (meta.ingress_metadata.bypass_lookups & 16w0x4 == 16w0) 
                    if (meta.l3_metadata.lkp_ip_type == 2w1) 
                        _ip_acl_0.apply();
                    else 
                        if (meta.l3_metadata.lkp_ip_type == 2w2) 
                            _ipv6_acl_0.apply();
            switch (rmac.apply().action_run) {
                default: {
                    if (meta.ingress_metadata.bypass_lookups & 16w0x2 == 16w0) 
                        if (meta.l3_metadata.lkp_ip_type == 2w1 && meta.ipv4_metadata.ipv4_unicast_enabled == 1w1) {
                            _ipv4_racl_0.apply();
                            switch (_ipv4_fib_0.apply().action_run) {
                                _on_miss_14: {
                                    _ipv4_fib_lpm_0.apply();
                                }
                            }

                        }
                        else 
                            if (meta.l3_metadata.lkp_ip_type == 2w2 && meta.ipv6_metadata.ipv6_unicast_enabled == 1w1) {
                                _ipv6_racl_0.apply();
                                switch (_ipv6_fib_0.apply().action_run) {
                                    _on_miss_16: {
                                        _ipv6_fib_lpm_0.apply();
                                    }
                                }

                            }
                }
                rmac_miss_0: {
                    if (meta.l3_metadata.lkp_ip_type == 2w1) {
                        if (meta.ingress_metadata.bypass_lookups & 16w0x1 == 16w0) 
                            switch (_ipv4_multicast_bridge.apply().action_run) {
                                _on_miss_18: {
                                    _ipv4_multicast_bridge_star_g.apply();
                                }
                            }

                        if (meta.ingress_metadata.bypass_lookups & 16w0x2 == 16w0 && meta.multicast_metadata.ipv4_multicast_enabled == 1w1) 
                            switch (_ipv4_multicast_route.apply().action_run) {
                                _on_miss_19: {
                                    _ipv4_multicast_route_star_g.apply();
                                }
                            }

                    }
                    else 
                        if (meta.l3_metadata.lkp_ip_type == 2w2) {
                            if (meta.ingress_metadata.bypass_lookups & 16w0x1 == 16w0) 
                                switch (_ipv6_multicast_bridge.apply().action_run) {
                                    _on_miss_20: {
                                        _ipv6_multicast_bridge_star_g.apply();
                                    }
                                }

                            if (meta.ingress_metadata.bypass_lookups & 16w0x2 == 16w0 && meta.multicast_metadata.ipv6_multicast_enabled == 1w1) 
                                switch (_ipv6_multicast_route.apply().action_run) {
                                    _on_miss_27: {
                                        _ipv6_multicast_route_star_g.apply();
                                    }
                                }

                        }
                }
            }

            switch (_nat_twice_0.apply().action_run) {
                _on_miss_30: {
                    switch (_nat_dst_0.apply().action_run) {
                        _on_miss_28: {
                            switch (_nat_src_0.apply().action_run) {
                                _on_miss_29: {
                                    _nat_flow_0.apply();
                                }
                            }

                        }
                    }

                }
            }

        }
        if (meta.tunnel_metadata.tunnel_terminate == 1w0 && hdr.ipv4.isValid() || meta.tunnel_metadata.tunnel_terminate == 1w1 && hdr.inner_ipv4.isValid()) 
            _compute_ipv4_hashes_0.apply();
        else 
            if (meta.tunnel_metadata.tunnel_terminate == 1w0 && hdr.ipv6.isValid() || meta.tunnel_metadata.tunnel_terminate == 1w1 && hdr.inner_ipv6.isValid()) 
                _compute_ipv6_hashes_0.apply();
            else 
                _compute_non_ip_hashes_0.apply();
        _compute_other_hashes_2.apply();
        if (meta.ingress_metadata.port_type != 2w1) {
            _ingress_bd_stats_2.apply();
            _acl_stats_2.apply();
            _storm_control_stats_2.apply();
            if (meta.ingress_metadata.bypass_lookups != 16w0xffff) 
                _fwd_result_0.apply();
            if (meta.nexthop_metadata.nexthop_type == 1w1) 
                _ecmp_group_0.apply();
            else 
                _nexthop_0.apply();
            if (meta.ingress_metadata.egress_ifindex == 16w65535) 
                _bd_flood_0.apply();
            else 
                _lag_group_0.apply();
            if (meta.l2_metadata.learning_enabled == 1w1) 
                _learn_notify_0.apply();
        }
        _traffic_class_0.apply();
        if (meta.ingress_metadata.port_type != 2w1) 
            if (meta.ingress_metadata.bypass_lookups & 16w0x20 == 16w0) {
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
        packet.emit<ethernet_t>(hdr.inner_ethernet);
        packet.emit<ipv6_t>(hdr.inner_ipv6);
        packet.emit<ipv4_t>(hdr.inner_ipv4);
        packet.emit<udp_t>(hdr.inner_udp);
        packet.emit<tcp_t>(hdr.inner_tcp);
        packet.emit<icmp_t>(hdr.inner_icmp);
        packet.emit<tcp_t>(hdr.tcp);
        packet.emit<icmp_t>(hdr.icmp);
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
        update_checksum_with_payload<tuple<bit<32>, bit<32>, bit<8>, bit<8>, bit<16>, bit<16>, bit<16>, bit<16>>, bit<16>>(meta.nat_metadata.update_inner_udp_checksum == 1w1, { hdr.inner_ipv4.srcAddr, hdr.inner_ipv4.dstAddr, 8w0, hdr.inner_ipv4.protocol, meta.nat_metadata.l4_len, hdr.inner_udp.srcPort, hdr.inner_udp.dstPort, hdr.inner_udp.length_ }, hdr.inner_udp.checksum, HashAlgorithm.csum16);
        update_checksum<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>, bit<16>>(true, { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
        update_checksum_with_payload<tuple<bit<32>, bit<32>, bit<8>, bit<8>, bit<16>, bit<16>, bit<16>, bit<32>, bit<32>, bit<4>, bit<4>, bit<8>, bit<16>, bit<16>>, bit<16>>(meta.nat_metadata.update_tcp_checksum == 1w1, { hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, 8w0, hdr.ipv4.protocol, meta.nat_metadata.l4_len, hdr.tcp.srcPort, hdr.tcp.dstPort, hdr.tcp.seqNo, hdr.tcp.ackNo, hdr.tcp.dataOffset, hdr.tcp.res, hdr.tcp.flags, hdr.tcp.window, hdr.tcp.urgentPtr }, hdr.tcp.checksum, HashAlgorithm.csum16);
        update_checksum_with_payload<tuple<bit<32>, bit<32>, bit<8>, bit<8>, bit<16>, bit<16>, bit<16>, bit<16>>, bit<16>>(meta.nat_metadata.update_udp_checksum == 1w1, { hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, 8w0, hdr.ipv4.protocol, meta.nat_metadata.l4_len, hdr.udp.srcPort, hdr.udp.dstPort, hdr.udp.length_ }, hdr.udp.checksum, HashAlgorithm.csum16);
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

