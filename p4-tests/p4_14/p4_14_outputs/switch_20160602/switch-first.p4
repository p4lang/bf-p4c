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
    bit<16> if_label;
    bit<16> bd_label;
    bit<14> acl_stats_index;
    bit<16> acl_partition_index;
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
}

struct ingress_parser_control_signals {
    bit<3> priority;
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
    @saturating 
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
    bit<8>  lkp_ip_tc;
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
    @saturating 
    bit<16> l3_mtu_check;
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
    bit<1>  update_inner_checksum;
    bit<16> l4_len;
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
    bit<14> tunnel_dst_index;
    bit<9>  tunnel_src_index;
    bit<9>  tunnel_smac_index;
    bit<14> tunnel_dmac_index;
    bit<24> vnid;
    bit<1>  tunnel_terminate;
    bit<1>  tunnel_if_check;
    bit<4>  egress_header_count;
    bit<8>  inner_ip_proto;
    bit<1>  skip_encap_inner;
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
    bit<1>  pdu_frame;
    bit<5>  frame_type;
    bit<6>  hw_id;
    bit<1>  direction;
    bit<2>  granularity;
    bit<1>  optional_sub_hdr;
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
    @name(".intrinsic_metadata") 
    intrinsic_metadata_t                        intrinsic_metadata;
    @name(".ipv4_metadata") 
    ipv4_metadata_t                             ipv4_metadata;
    @pa_alias("ingress", "ipv4_metadata.lkp_ipv4_sa", "ipv6_metadata.lkp_ipv6_sa") @pa_alias("ingress", "ipv4_metadata.lkp_ipv4_da", "ipv6_metadata.lkp_ipv6_da") @name(".ipv6_metadata") 
    ipv6_metadata_t                             ipv6_metadata;
    @name(".l2_metadata") 
    l2_metadata_t                               l2_metadata;
    @name(".l3_metadata") 
    l3_metadata_t                               l3_metadata;
    @pa_atomic("ingress", "meter_metadata.meter_color") @pa_solitary("ingress", "meter_metadata.meter_color") @pa_atomic("ingress", "meter_metadata.meter_index") @pa_solitary("ingress", "meter_metadata.meter_index") @name(".meter_metadata") 
    meter_metadata_t                            meter_metadata;
    @pa_solitary("ingress", "multicast_metadata.multicast_route_mc_index") @pa_atomic("ingress", "multicast_metadata.multicast_route_mc_index") @pa_solitary("ingress", "multicast_metadata.multicast_bridge_mc_index") @pa_atomic("ingress", "multicast_metadata.multicast_bridge_mc_index") @name(".multicast_metadata") 
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
    @name(".arp_rarp") 
    arp_rarp_t                arp_rarp;
    @name(".arp_rarp_ipv4") 
    arp_rarp_ipv4_t           arp_rarp_ipv4;
    @name(".bfd") 
    bfd_t                     bfd;
    @name(".eompls") 
    eompls_t                  eompls;
    @name(".erspan_t3_header") 
    erspan_header_t3_t_0      erspan_t3_header;
    @name(".ethernet") 
    ethernet_t                ethernet;
    @name(".fabric_header") 
    fabric_header_t           fabric_header;
    @name(".fabric_header_cpu") 
    fabric_header_cpu_t       fabric_header_cpu;
    @name(".fabric_header_mirror") 
    fabric_header_mirror_t    fabric_header_mirror;
    @name(".fabric_header_multicast") 
    fabric_header_multicast_t fabric_header_multicast;
    @name(".fabric_header_sflow") 
    fabric_header_sflow_t     fabric_header_sflow;
    @name(".fabric_header_unicast") 
    fabric_header_unicast_t   fabric_header_unicast;
    @name(".fabric_payload_header") 
    fabric_payload_header_t   fabric_payload_header;
    @name(".fcoe") 
    fcoe_header_t             fcoe;
    @name(".genv") 
    genv_t                    genv;
    @name(".gre") 
    gre_t                     gre;
    @name(".icmp") 
    icmp_t                    icmp;
    @name(".inner_ethernet") 
    ethernet_t                inner_ethernet;
    @name(".inner_icmp") 
    icmp_t                    inner_icmp;
    @pa_fragment("ingress", "inner_ipv4.hdrChecksum") @pa_fragment("egress", "inner_ipv4.hdrChecksum") @name(".inner_ipv4") 
    ipv4_t                    inner_ipv4;
    @name(".inner_ipv6") 
    ipv6_t                    inner_ipv6;
    @name(".inner_sctp") 
    sctp_t                    inner_sctp;
    @pa_alias("egress", "inner_tcp", "tcp") @name(".inner_tcp") 
    tcp_t                     inner_tcp;
    @name(".inner_udp") 
    udp_t                     inner_udp;
    @pa_fragment("ingress", "ipv4.hdrChecksum") @pa_fragment("egress", "ipv4.hdrChecksum") @name(".ipv4") 
    ipv4_t                    ipv4;
    @overlay_subheader("egress", "inner_ipv6", "srcAddr", "dstAddr") @name(".ipv6") 
    ipv6_t                    ipv6;
    @name(".lisp") 
    lisp_t                    lisp;
    @name(".llc_header") 
    llc_header_t              llc_header;
    @name(".nsh") 
    nsh_t                     nsh;
    @name(".nsh_context") 
    nsh_context_t             nsh_context;
    @name(".nvgre") 
    nvgre_t                   nvgre;
    @name(".outer_udp") 
    udp_t                     outer_udp;
    @name(".roce") 
    roce_header_t             roce;
    @name(".roce_v2") 
    roce_v2_header_t          roce_v2;
    @name(".sctp") 
    sctp_t                    sctp;
    @name(".sflow") 
    sflow_hdr_t               sflow;
    @name(".sflow_raw_hdr_record") 
    sflow_raw_hdr_record_t    sflow_raw_hdr_record;
    @name(".sflow_sample") 
    sflow_sample_t            sflow_sample;
    @name(".snap_header") 
    snap_header_t             snap_header;
    @name(".tcp") 
    tcp_t                     tcp;
    @name(".trill") 
    trill_t                   trill;
    @name(".udp") 
    udp_t                     udp;
    @name(".vntag") 
    vntag_t                   vntag;
    @name(".vxlan") 
    vxlan_t                   vxlan;
    @name(".mpls") 
    mpls_t[3]                 mpls;
    @name(".vlan_tag_") 
    vlan_tag_t[2]             vlan_tag_;
}
#include <tofino/stateful_alu.p4>

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
        transition select(hdr.erspan_t3_header.frame_type) {
            5w0: parse_inner_ethernet;
            5w2: parse_inner_ipv4;
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
    @name(".parse_inner_sctp") state parse_inner_sctp {
        packet.extract<sctp_t>(hdr.inner_sctp);
        transition accept;
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
        meta.ig_prsr_ctrl.priority = 3w5;
        transition accept;
    }
    @name(".parse_set_prio_max") state parse_set_prio_max {
        meta.ig_prsr_ctrl.priority = 3w7;
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
    @name(".parse_trill") state parse_trill {
        packet.extract<trill_t>(hdr.trill);
        transition parse_inner_ethernet;
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
    @name(".parse_udp_v6") state parse_udp_v6 {
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

@name(".bd_action_profile") action_profile(32w1024) bd_action_profile;

@name(".ecmp_action_profile") @mode("fair") action_selector(HashAlgorithm.identity, 32w1024, 32w14) ecmp_action_profile;

@name(".lag_action_profile") @mode("fair") action_selector(HashAlgorithm.identity, 32w1024, 32w14) lag_action_profile;

control process_int_egress_prep(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_mirroring(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_mirror_nhop") action set_mirror_nhop(bit<16> nhop_idx) {
        meta.l3_metadata.nexthop_index = nhop_idx;
    }
    @name(".set_mirror_bd") action set_mirror_bd(bit<16> bd) {
        meta.egress_metadata.bd = bd;
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
    apply {
        mirror.apply();
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
        size = 512;
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
            meta.eg_intr_md.egress_rid: exact @name("eg_intr_md.egress_rid") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        if (meta.eg_intr_md.egress_rid != 16w0) {
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
        size = 1024;
        default_action = NoAction();
    }
    apply {
        vlan_decap.apply();
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
    @name(".decap_gre_inner_ipv4") action decap_gre_inner_ipv4() {
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.gre.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ipv4.setInvalid();
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".decap_gre_inner_ipv6") action decap_gre_inner_ipv6() {
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.gre.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.inner_ipv6.setInvalid();
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".decap_gre_inner_non_ip") action decap_gre_inner_non_ip() {
        hdr.ethernet.etherType = hdr.gre.proto;
        hdr.gre.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.inner_ipv6.setInvalid();
    }
    @name(".decap_ip_inner_ipv4") action decap_ip_inner_ipv4() {
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.ipv6.setInvalid();
        hdr.inner_ipv4.setInvalid();
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".decap_ip_inner_ipv6") action decap_ip_inner_ipv6() {
        hdr.ipv6 = hdr.inner_ipv6;
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
        size = 1024;
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
            decap_gre_inner_ipv4();
            decap_gre_inner_ipv6();
            decap_gre_inner_non_ip();
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
        size = 1024;
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
        size = 1024;
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
            hdr.ipv4.dstAddr[31:28]  : ternary @name("ipv4.dstAddr") ;
            hdr.ipv6.dstAddr[127:120]: ternary @name("ipv6.dstAddr") ;
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
    @name(".set_egress_bd_properties") action set_egress_bd_properties(bit<9> smac_idx, bit<2> nat_mode) {
        meta.egress_metadata.smac_idx = smac_idx;
        meta.nat_metadata.egress_nat_mode = nat_mode;
    }
    @name(".egress_bd_map") table egress_bd_map {
        actions = {
            nop();
            set_egress_bd_properties();
            @defaultonly NoAction();
        }
        key = {
            meta.egress_metadata.bd: exact @name("egress_metadata.bd") ;
        }
        size = 1024;
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
            hdr.ipv4.dstAddr[31:28]  : ternary @name("ipv4.dstAddr") ;
            hdr.ipv6.dstAddr[127:120]: ternary @name("ipv6.dstAddr") ;
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
        meta.l3_metadata.l3_mtu_check = l3_mtu |-| hdr.ipv4.totalLen;
    }
    @name(".ipv6_mtu_check") action ipv6_mtu_check(bit<16> l3_mtu) {
        meta.l3_metadata.l3_mtu_check = l3_mtu |-| hdr.ipv6.payloadLen;
    }
    @ternary(1) @name(".mtu") table mtu {
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
        size = 1024;
        default_action = NoAction();
    }
    apply {
        mtu.apply();
    }
}

control process_egress_nat(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".nat_update_l4_checksum") action nat_update_l4_checksum() {
        meta.nat_metadata.update_checksum = 1w1;
        meta.nat_metadata.l4_len = hdr.ipv4.totalLen + 16w65516;
    }
    @name(".set_nat_src_rewrite") action set_nat_src_rewrite(bit<32> src_ip) {
        hdr.ipv4.srcAddr = src_ip;
        nat_update_l4_checksum();
    }
    @name(".set_nat_dst_rewrite") action set_nat_dst_rewrite(bit<32> dst_ip) {
        hdr.ipv4.dstAddr = dst_ip;
        nat_update_l4_checksum();
    }
    @name(".set_nat_src_dst_rewrite") action set_nat_src_dst_rewrite(bit<32> src_ip, bit<32> dst_ip) {
        hdr.ipv4.srcAddr = src_ip;
        hdr.ipv4.dstAddr = dst_ip;
        nat_update_l4_checksum();
    }
    @name(".set_nat_src_udp_rewrite") action set_nat_src_udp_rewrite(bit<32> src_ip, bit<16> src_port) {
        hdr.ipv4.srcAddr = src_ip;
        hdr.udp.srcPort = src_port;
        nat_update_l4_checksum();
    }
    @name(".set_nat_dst_udp_rewrite") action set_nat_dst_udp_rewrite(bit<32> dst_ip, bit<16> dst_port) {
        hdr.ipv4.dstAddr = dst_ip;
        hdr.udp.dstPort = dst_port;
        nat_update_l4_checksum();
    }
    @name(".set_nat_src_dst_udp_rewrite") action set_nat_src_dst_udp_rewrite(bit<32> src_ip, bit<32> dst_ip, bit<16> src_port, bit<16> dst_port) {
        hdr.ipv4.srcAddr = src_ip;
        hdr.ipv4.dstAddr = dst_ip;
        hdr.udp.srcPort = src_port;
        hdr.udp.dstPort = dst_port;
        nat_update_l4_checksum();
    }
    @name(".set_nat_src_tcp_rewrite") action set_nat_src_tcp_rewrite(bit<32> src_ip, bit<16> src_port) {
        hdr.ipv4.srcAddr = src_ip;
        hdr.tcp.srcPort = src_port;
        nat_update_l4_checksum();
    }
    @name(".set_nat_dst_tcp_rewrite") action set_nat_dst_tcp_rewrite(bit<32> dst_ip, bit<16> dst_port) {
        hdr.ipv4.dstAddr = dst_ip;
        hdr.tcp.dstPort = dst_port;
        nat_update_l4_checksum();
    }
    @name(".set_nat_src_dst_tcp_rewrite") action set_nat_src_dst_tcp_rewrite(bit<32> src_ip, bit<32> dst_ip, bit<16> src_port, bit<16> dst_port) {
        hdr.ipv4.srcAddr = src_ip;
        hdr.ipv4.dstAddr = dst_ip;
        hdr.tcp.srcPort = src_port;
        hdr.tcp.dstPort = dst_port;
        nat_update_l4_checksum();
    }
    @name(".egress_nat") table egress_nat {
        actions = {
            nop();
            set_nat_src_rewrite();
            set_nat_dst_rewrite();
            set_nat_src_dst_rewrite();
            set_nat_src_udp_rewrite();
            set_nat_dst_udp_rewrite();
            set_nat_src_dst_udp_rewrite();
            set_nat_src_tcp_rewrite();
            set_nat_dst_tcp_rewrite();
            set_nat_src_dst_tcp_rewrite();
            @defaultonly NoAction();
        }
        key = {
            meta.nat_metadata.nat_rewrite_index: exact @name("nat_metadata.nat_rewrite_index") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        if (meta.nat_metadata.ingress_nat_mode != 2w0 && meta.nat_metadata.ingress_nat_mode != meta.nat_metadata.egress_nat_mode) 
            egress_nat.apply();
    }
}

control process_egress_bd_stats(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".egress_bd_stats") @min_width(32) direct_counter(CounterType.packets_and_bytes) egress_bd_stats;
    @name(".nop") action nop() {
    }
    @name(".nop") action nop_0() {
        egress_bd_stats.count();
    }
    @name(".egress_bd_stats") table egress_bd_stats_0 {
        actions = {
            nop_0();
            @defaultonly NoAction();
        }
        key = {
            meta.egress_metadata.bd      : exact @name("egress_metadata.bd") ;
            meta.l2_metadata.lkp_pkt_type: exact @name("l2_metadata.lkp_pkt_type") ;
        }
        size = 1024;
        counters = egress_bd_stats;
        default_action = NoAction();
    }
    apply {
        egress_bd_stats_0.apply();
    }
}

control process_int_egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
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
        meta.tunnel_metadata.inner_ip_proto = 8w4;
    }
    @name(".inner_ipv4_tcp_rewrite") action inner_ipv4_tcp_rewrite() {
        hdr.inner_ipv4 = hdr.ipv4;
        hdr.inner_tcp.setValid();
        meta.egress_metadata.payload_length = hdr.ipv4.totalLen;
        hdr.tcp.setInvalid();
        hdr.ipv4.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w4;
    }
    @name(".inner_ipv4_icmp_rewrite") action inner_ipv4_icmp_rewrite() {
        hdr.inner_ipv4 = hdr.ipv4;
        hdr.inner_icmp = hdr.icmp;
        meta.egress_metadata.payload_length = hdr.ipv4.totalLen;
        hdr.icmp.setInvalid();
        hdr.ipv4.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w4;
    }
    @name(".inner_ipv4_unknown_rewrite") action inner_ipv4_unknown_rewrite() {
        hdr.inner_ipv4 = hdr.ipv4;
        meta.egress_metadata.payload_length = hdr.ipv4.totalLen;
        hdr.ipv4.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w4;
    }
    @name(".inner_ipv6_udp_rewrite") action inner_ipv6_udp_rewrite() {
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_udp = hdr.udp;
        meta.egress_metadata.payload_length = hdr.ipv6.payloadLen + 16w40;
        hdr.ipv6.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w41;
    }
    @name(".inner_ipv6_tcp_rewrite") action inner_ipv6_tcp_rewrite() {
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_tcp.setValid();
        meta.egress_metadata.payload_length = hdr.ipv6.payloadLen + 16w40;
        hdr.tcp.setInvalid();
        hdr.ipv6.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w41;
    }
    @name(".inner_ipv6_icmp_rewrite") action inner_ipv6_icmp_rewrite() {
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_icmp = hdr.icmp;
        meta.egress_metadata.payload_length = hdr.ipv6.payloadLen + 16w40;
        hdr.icmp.setInvalid();
        hdr.ipv6.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w41;
    }
    @name(".inner_ipv6_unknown_rewrite") action inner_ipv6_unknown_rewrite() {
        hdr.inner_ipv6 = hdr.ipv6;
        meta.egress_metadata.payload_length = hdr.ipv6.payloadLen + 16w40;
        hdr.ipv6.setInvalid();
        meta.tunnel_metadata.inner_ip_proto = 8w41;
    }
    @name(".inner_non_ip_rewrite") action inner_non_ip_rewrite() {
    }
    @name(".fabric_rewrite") action fabric_rewrite(bit<14> tunnel_index) {
        meta.tunnel_metadata.tunnel_index = tunnel_index;
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
    @name(".f_insert_gre_header") action f_insert_gre_header() {
        hdr.gre.setValid();
    }
    @name(".ipv4_gre_rewrite") action ipv4_gre_rewrite() {
        f_insert_gre_header();
        hdr.gre.proto = hdr.ethernet.etherType;
        f_insert_ipv4_header(8w47);
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w24;
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".ipv4_ip_rewrite") action ipv4_ip_rewrite() {
        f_insert_ipv4_header(meta.tunnel_metadata.inner_ip_proto);
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w20;
        hdr.ethernet.etherType = 16w0x800;
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
        hdr.erspan_t3_header.sgt = 16w0;
        hdr.erspan_t3_header.pdu_frame = 1w0;
        hdr.erspan_t3_header.frame_type = 5w0;
        hdr.erspan_t3_header.hw_id = 6w0;
        hdr.erspan_t3_header.direction = 1w0;
        hdr.erspan_t3_header.granularity = 2w0;
        hdr.erspan_t3_header.optional_sub_hdr = 1w0;
    }
    @name(".ipv4_erspan_t3_rewrite") action ipv4_erspan_t3_rewrite() {
        f_insert_erspan_t3_header();
        f_insert_ipv4_header(8w47);
        hdr.ipv4.totalLen = meta.egress_metadata.payload_length + 16w50;
    }
    @name(".f_insert_ipv6_header") action f_insert_ipv6_header(bit<8> proto) {
        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w0x6;
        hdr.ipv6.nextHdr = proto;
        hdr.ipv6.hopLimit = 8w64;
        hdr.ipv6.trafficClass = 8w0;
        hdr.ipv6.flowLabel = 20w0;
    }
    @name(".ipv6_gre_rewrite") action ipv6_gre_rewrite() {
        f_insert_gre_header();
        hdr.gre.proto = hdr.ethernet.etherType;
        f_insert_ipv6_header(8w47);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w4;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".ipv6_ip_rewrite") action ipv6_ip_rewrite() {
        f_insert_ipv6_header(meta.tunnel_metadata.inner_ip_proto);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".ipv6_nvgre_rewrite") action ipv6_nvgre_rewrite() {
        f_insert_nvgre_header();
        f_insert_ipv6_header(8w47);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w22;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".ipv6_vxlan_rewrite") action ipv6_vxlan_rewrite() {
        f_insert_vxlan_header();
        f_insert_ipv6_header(8w17);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w30;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".ipv6_genv_rewrite") action ipv6_genv_rewrite() {
        f_insert_genv_header();
        f_insert_ipv6_header(8w17);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w30;
        hdr.ethernet.etherType = 16w0x86dd;
    }
    @name(".ipv6_erspan_t3_rewrite") action ipv6_erspan_t3_rewrite() {
        f_insert_erspan_t3_header();
        f_insert_ipv6_header(8w47);
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w26;
    }
    @name(".mpls_ethernet_push1_rewrite") action mpls_ethernet_push1_rewrite() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".mpls_ip_push1_rewrite") action mpls_ip_push1_rewrite() {
        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".mpls_ethernet_push2_rewrite") action mpls_ethernet_push2_rewrite() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.mpls.push_front(2);
        hdr.mpls[0].setValid();
        hdr.mpls[1].setValid();
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".mpls_ip_push2_rewrite") action mpls_ip_push2_rewrite() {
        hdr.mpls.push_front(2);
        hdr.mpls[0].setValid();
        hdr.mpls[1].setValid();
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".mpls_ethernet_push3_rewrite") action mpls_ethernet_push3_rewrite() {
        hdr.inner_ethernet = hdr.ethernet;
        hdr.mpls.push_front(3);
        hdr.mpls[0].setValid();
        hdr.mpls[1].setValid();
        hdr.mpls[2].setValid();
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".mpls_ip_push3_rewrite") action mpls_ip_push3_rewrite() {
        hdr.mpls.push_front(3);
        hdr.mpls[0].setValid();
        hdr.mpls[1].setValid();
        hdr.mpls[2].setValid();
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name(".tunnel_mtu_check") action tunnel_mtu_check(bit<16> l3_mtu) {
        meta.l3_metadata.l3_mtu_check = l3_mtu |-| meta.egress_metadata.payload_length;
    }
    @name(".tunnel_mtu_miss") action tunnel_mtu_miss() {
        meta.l3_metadata.l3_mtu_check = 16w0xffff;
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
        size = 1024;
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
        size = 1024;
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
        size = 1024;
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
        size = 1024;
        default_action = NoAction();
    }
    @name(".tunnel_encap_process_outer") table tunnel_encap_process_outer {
        actions = {
            nop();
            fabric_rewrite();
            ipv4_vxlan_rewrite();
            ipv4_genv_rewrite();
            ipv4_nvgre_rewrite();
            ipv4_gre_rewrite();
            ipv4_ip_rewrite();
            ipv4_erspan_t3_rewrite();
            ipv6_gre_rewrite();
            ipv6_ip_rewrite();
            ipv6_nvgre_rewrite();
            ipv6_vxlan_rewrite();
            ipv6_genv_rewrite();
            ipv6_erspan_t3_rewrite();
            mpls_ethernet_push1_rewrite();
            mpls_ip_push1_rewrite();
            mpls_ethernet_push2_rewrite();
            mpls_ip_push2_rewrite();
            mpls_ethernet_push3_rewrite();
            mpls_ip_push3_rewrite();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.egress_tunnel_type : exact @name("tunnel_metadata.egress_tunnel_type") ;
            meta.tunnel_metadata.egress_header_count: exact @name("tunnel_metadata.egress_header_count") ;
            meta.multicast_metadata.replica         : exact @name("multicast_metadata.replica") ;
        }
        size = 1024;
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
        size = 1024;
        default_action = NoAction();
    }
    @name(".tunnel_rewrite") table tunnel_rewrite {
        actions = {
            nop();
            cpu_rx_rewrite();
            set_tunnel_rewrite_details();
            set_mpls_rewrite_push1();
            set_mpls_rewrite_push2();
            set_mpls_rewrite_push3();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.tunnel_index: exact @name("tunnel_metadata.tunnel_index") ;
        }
        size = 1024;
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
        size = 1024;
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
        size = 1024;
        default_action = NoAction();
    }
    apply {
        if (meta.fabric_metadata.fabric_header_present == 1w0 && meta.tunnel_metadata.egress_tunnel_type != 5w0) {
            egress_vni.apply();
            if (meta.tunnel_metadata.egress_tunnel_type != 5w15 && meta.tunnel_metadata.egress_tunnel_type != 5w16 && meta.tunnel_metadata.skip_encap_inner == 1w0) 
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
            meta.egress_metadata.ifindex: exact @name("egress_metadata.ifindex") ;
            meta.egress_metadata.bd     : exact @name("egress_metadata.bd") ;
        }
        size = 1024;
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
    @name(".egress_mirror") action egress_mirror(bit<32> session_id) {
        meta.i2e_metadata.mirror_session_id = (bit<16>)session_id;
        clone3<tuple<bit<32>, bit<16>>>(CloneType.E2E, session_id, { meta.i2e_metadata.ingress_tstamp, meta.i2e_metadata.mirror_session_id });
    }
    @name(".egress_mirror_drop") action egress_mirror_drop(bit<32> session_id) {
        egress_mirror(session_id);
        mark_to_drop();
    }
    @name(".egress_acl") table egress_acl {
        actions = {
            nop();
            egress_redirect_to_cpu();
            egress_mirror_coal_hdr();
            egress_mirror();
            egress_mirror_drop();
            @defaultonly NoAction();
        }
        key = {
            meta.eg_intr_md.egress_port    : ternary @name("eg_intr_md.egress_port") ;
            meta.eg_intr_md.deflection_flag: ternary @name("eg_intr_md.deflection_flag") ;
            meta.l3_metadata.l3_mtu_check  : ternary @name("l3_metadata.l3_mtu_check") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.egress_metadata.bypass == 1w0) 
            egress_acl.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".egress_port_type_normal") action egress_port_type_normal(bit<16> ifindex) {
        meta.egress_metadata.port_type = 2w0;
        meta.egress_metadata.ifindex = ifindex;
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
    @name(".egress_port_mapping") table egress_port_mapping {
        actions = {
            egress_port_type_normal();
            egress_port_type_fabric();
            egress_port_type_cpu();
            @defaultonly NoAction();
        }
        key = {
            meta.eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        size = 288;
        default_action = NoAction();
    }
    @name(".process_int_egress_prep") process_int_egress_prep() process_int_egress_prep_0;
    @name(".process_mirroring") process_mirroring() process_mirroring_0;
    @name(".process_replication") process_replication() process_replication_0;
    @name(".process_vlan_decap") process_vlan_decap() process_vlan_decap_0;
    @name(".process_tunnel_decap") process_tunnel_decap() process_tunnel_decap_0;
    @name(".process_rewrite") process_rewrite() process_rewrite_0;
    @name(".process_egress_bd") process_egress_bd() process_egress_bd_0;
    @name(".process_mac_rewrite") process_mac_rewrite() process_mac_rewrite_0;
    @name(".process_mtu") process_mtu() process_mtu_0;
    @name(".process_egress_nat") process_egress_nat() process_egress_nat_0;
    @name(".process_egress_bd_stats") process_egress_bd_stats() process_egress_bd_stats_0;
    @name(".process_int_egress") process_int_egress() process_int_egress_0;
    @name(".process_tunnel_encap") process_tunnel_encap() process_tunnel_encap_0;
    @name(".process_int_outer_encap") process_int_outer_encap() process_int_outer_encap_0;
    @name(".process_vlan_xlate") process_vlan_xlate() process_vlan_xlate_0;
    @name(".process_egress_filter") process_egress_filter() process_egress_filter_0;
    @name(".process_egress_acl") process_egress_acl() process_egress_acl_0;
    apply {
        if (meta.eg_intr_md.deflection_flag == 1w0 && meta.egress_metadata.bypass == 1w0) {
            process_int_egress_prep_0.apply(hdr, meta, standard_metadata);
            if (standard_metadata.instance_type != 32w0 && standard_metadata.instance_type != 32w5) 
                process_mirroring_0.apply(hdr, meta, standard_metadata);
            else 
                process_replication_0.apply(hdr, meta, standard_metadata);
            switch (egress_port_mapping.apply().action_run) {
                egress_port_type_normal: {
                    if (standard_metadata.instance_type == 32w0 || standard_metadata.instance_type == 32w5) 
                        process_vlan_decap_0.apply(hdr, meta, standard_metadata);
                    process_tunnel_decap_0.apply(hdr, meta, standard_metadata);
                    process_rewrite_0.apply(hdr, meta, standard_metadata);
                    process_egress_bd_0.apply(hdr, meta, standard_metadata);
                    process_mac_rewrite_0.apply(hdr, meta, standard_metadata);
                    process_mtu_0.apply(hdr, meta, standard_metadata);
                    process_egress_nat_0.apply(hdr, meta, standard_metadata);
                    process_egress_bd_stats_0.apply(hdr, meta, standard_metadata);
                }
            }

            process_int_egress_0.apply(hdr, meta, standard_metadata);
            process_tunnel_encap_0.apply(hdr, meta, standard_metadata);
            process_int_outer_encap_0.apply(hdr, meta, standard_metadata);
            if (meta.egress_metadata.port_type == 2w0) 
                process_vlan_xlate_0.apply(hdr, meta, standard_metadata);
            process_egress_filter_0.apply(hdr, meta, standard_metadata);
        }
        process_egress_acl_0.apply(hdr, meta, standard_metadata);
    }
}

control process_ingress_port_mapping(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_ifindex") action set_ifindex(bit<16> ifindex, bit<2> port_type) {
        meta.ingress_metadata.ifindex = ifindex;
        meta.ingress_metadata.port_type = port_type;
    }
    @name(".set_ingress_port_properties") action set_ingress_port_properties(bit<16> if_label, bit<9> exclusion_id) {
        meta.ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
        meta.acl_metadata.if_label = if_label;
    }
    @name(".ingress_port_mapping") table ingress_port_mapping {
        actions = {
            set_ifindex();
            @defaultonly NoAction();
        }
        key = {
            meta.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 288;
        default_action = NoAction();
    }
    @name(".ingress_port_properties") table ingress_port_properties {
        actions = {
            set_ingress_port_properties();
            @defaultonly NoAction();
        }
        key = {
            meta.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
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

control validate_outer_ipv4_header(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_valid_outer_ipv4_packet") action set_valid_outer_ipv4_packet() {
        meta.l3_metadata.lkp_ip_type = 2w1;
        meta.l3_metadata.lkp_ip_tc = hdr.ipv4.diffserv;
        meta.l3_metadata.lkp_ip_version = hdr.ipv4.version;
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
            hdr.ipv4.version       : ternary @name("ipv4.version") ;
            hdr.ipv4.ttl           : ternary @name("ipv4.ttl") ;
            hdr.ipv4.srcAddr[31:24]: ternary @name("ipv4.srcAddr") ;
        }
        size = 512;
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
        meta.l3_metadata.lkp_ip_version = hdr.ipv6.version;
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
            hdr.ipv6.version         : ternary @name("ipv6.version") ;
            hdr.ipv6.hopLimit        : ternary @name("ipv6.hopLimit") ;
            hdr.ipv6.srcAddr[127:112]: ternary @name("ipv6.srcAddr") ;
        }
        size = 512;
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
    }
    @name(".set_valid_outer_unicast_packet_double_tagged") action set_valid_outer_unicast_packet_double_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[1].etherType;
    }
    @name(".set_valid_outer_unicast_packet_qinq_tagged") action set_valid_outer_unicast_packet_qinq_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w1;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name(".set_valid_outer_multicast_packet_untagged") action set_valid_outer_multicast_packet_untagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name(".set_valid_outer_multicast_packet_single_tagged") action set_valid_outer_multicast_packet_single_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[0].etherType;
    }
    @name(".set_valid_outer_multicast_packet_double_tagged") action set_valid_outer_multicast_packet_double_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[1].etherType;
    }
    @name(".set_valid_outer_multicast_packet_qinq_tagged") action set_valid_outer_multicast_packet_qinq_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w2;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name(".set_valid_outer_broadcast_packet_untagged") action set_valid_outer_broadcast_packet_untagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name(".set_valid_outer_broadcast_packet_single_tagged") action set_valid_outer_broadcast_packet_single_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[0].etherType;
    }
    @name(".set_valid_outer_broadcast_packet_double_tagged") action set_valid_outer_broadcast_packet_double_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.vlan_tag_[1].etherType;
    }
    @name(".set_valid_outer_broadcast_packet_qinq_tagged") action set_valid_outer_broadcast_packet_qinq_tagged() {
        meta.l2_metadata.lkp_pkt_type = 3w4;
        meta.l2_metadata.lkp_mac_type = hdr.ethernet.etherType;
    }
    @name(".validate_outer_ethernet") table validate_outer_ethernet {
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
            hdr.ethernet.srcAddr      : ternary @name("ethernet.srcAddr") ;
            hdr.ethernet.dstAddr      : ternary @name("ethernet.dstAddr") ;
            hdr.vlan_tag_[0].isValid(): exact @name("vlan_tag_[0].$valid$") ;
            hdr.vlan_tag_[1].isValid(): exact @name("vlan_tag_[1].$valid$") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".validate_outer_ipv4_header") validate_outer_ipv4_header() validate_outer_ipv4_header_0;
    @name(".validate_outer_ipv6_header") validate_outer_ipv6_header() validate_outer_ipv6_header_0;
    @name(".validate_mpls_header") validate_mpls_header() validate_mpls_header_0;
    apply {
        switch (validate_outer_ethernet.apply().action_run) {
            malformed_outer_ethernet_packet: {
            }
            default: {
                if (hdr.ipv4.isValid()) 
                    validate_outer_ipv4_header_0.apply(hdr, meta, standard_metadata);
                else 
                    if (hdr.ipv6.isValid()) 
                        validate_outer_ipv6_header_0.apply(hdr, meta, standard_metadata);
                    else 
                        if (hdr.mpls[0].isValid()) 
                            validate_mpls_header_0.apply(hdr, meta, standard_metadata);
            }
        }

    }
}

control process_global_params(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".deflect_on_drop") action deflect_on_drop(bit<1> enable_dod) {
        meta.ig_intr_md_for_tm.deflect_on_drop = enable_dod;
    }
    @name(".set_config_parameters") action set_config_parameters(bit<1> enable_dod, bit<8> enable_flowlet) {
        deflect_on_drop(enable_dod);
        meta.i2e_metadata.ingress_tstamp = (bit<32>)meta.ig_intr_md.ingress_global_tstamp;
        meta.ingress_metadata.ingress_port = meta.ig_intr_md.ingress_port;
        meta.l2_metadata.same_if_check = meta.ingress_metadata.ifindex;
        meta.ig_intr_md_for_tm.ucast_egress_port = 9w511;
    }
    @name(".switch_config_params") table switch_config_params {
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

control process_int_endpoint(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_port_vlan_mapping(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_bd_properties") action set_bd_properties(bit<16> bd, bit<16> vrf, bit<10> stp_group, bit<1> learning_enabled, bit<16> bd_label, bit<16> stats_idx, bit<10> rmac_group, bit<1> ipv4_unicast_enabled, bit<1> ipv6_unicast_enabled, bit<2> ipv4_urpf_mode, bit<2> ipv6_urpf_mode, bit<1> igmp_snooping_enabled, bit<1> mld_snooping_enabled, bit<1> ipv4_multicast_enabled, bit<1> ipv6_multicast_enabled, bit<16> mrpf_group, bit<16> ipv4_mcast_key, bit<1> ipv4_mcast_key_type, bit<16> ipv6_mcast_key, bit<1> ipv6_mcast_key_type, bit<16> ingress_rid) {
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
    @name(".port_vlan_mapping") table port_vlan_mapping {
        actions = {
            set_bd_properties();
            port_vlan_mapping_miss();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.ifindex: exact @name("ingress_metadata.ifindex") ;
            hdr.vlan_tag_[0].isValid()   : exact @name("vlan_tag_[0].$valid$") ;
            hdr.vlan_tag_[0].vid         : exact @name("vlan_tag_[0].vid") ;
            hdr.vlan_tag_[1].isValid()   : exact @name("vlan_tag_[1].$valid$") ;
            hdr.vlan_tag_[1].vid         : exact @name("vlan_tag_[1].vid") ;
        }
        size = 4096;
        implementation = bd_action_profile;
        default_action = NoAction();
    }
    apply {
        port_vlan_mapping.apply();
    }
}

control process_spanning_tree(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_stp_state") action set_stp_state(bit<3> stp_state) {
        meta.l2_metadata.stp_state = stp_state;
    }
    @name(".spanning_tree") table spanning_tree {
        actions = {
            set_stp_state();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.ifindex: exact @name("ingress_metadata.ifindex") ;
            meta.l2_metadata.stp_group   : exact @name("l2_metadata.stp_group") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        if (meta.ingress_metadata.port_type == 2w0 && meta.l2_metadata.stp_group != 10w0) 
            spanning_tree.apply();
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
    @ternary(1) @name(".fabric_ingress_dst_lkp") table fabric_ingress_dst_lkp {
        actions = {
            nop();
            terminate_cpu_packet();
            @defaultonly NoAction();
        }
        key = {
            hdr.fabric_header.dstDevice: exact @name("fabric_header.dstDevice") ;
        }
        default_action = NoAction();
    }
    apply {
        if (meta.ingress_metadata.port_type != 2w0) 
            fabric_ingress_dst_lkp.apply();
    }
}

control process_outer_ipv4_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".on_miss") action on_miss() {
    }
    @name(".outer_multicast_route_s_g_hit") action outer_multicast_route_s_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_bridge_s_g_hit") action outer_multicast_bridge_s_g_hit(bit<16> mc_index) {
        meta.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.tunnel_metadata.tunnel_terminate = 1w1;
    }
    @name(".outer_multicast_route_sm_star_g_hit") action outer_multicast_route_sm_star_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.outer_mcast_mode = 2w1;
        meta.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_route_bidir_star_g_hit") action outer_multicast_route_bidir_star_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.outer_mcast_mode = 2w2;
        meta.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group | meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_bridge_star_g_hit") action outer_multicast_bridge_star_g_hit(bit<16> mc_index) {
        meta.ig_intr_md_for_tm.mcast_grp_a = mc_index;
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
            hdr.ipv4.srcAddr                           : exact @name("ipv4.srcAddr") ;
            hdr.ipv4.dstAddr                           : exact @name("ipv4.dstAddr") ;
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
            hdr.ipv4.dstAddr                           : ternary @name("ipv4.dstAddr") ;
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
        meta.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_bridge_s_g_hit") action outer_multicast_bridge_s_g_hit(bit<16> mc_index) {
        meta.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.tunnel_metadata.tunnel_terminate = 1w1;
    }
    @name(".outer_multicast_route_sm_star_g_hit") action outer_multicast_route_sm_star_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.outer_mcast_mode = 2w1;
        meta.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_route_bidir_star_g_hit") action outer_multicast_route_bidir_star_g_hit(bit<16> mc_index, bit<16> mcast_rpf_group) {
        meta.multicast_metadata.outer_mcast_mode = 2w2;
        meta.ig_intr_md_for_tm.mcast_grp_a = mc_index;
        meta.multicast_metadata.outer_mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group | meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".outer_multicast_bridge_star_g_hit") action outer_multicast_bridge_star_g_hit(bit<16> mc_index) {
        meta.ig_intr_md_for_tm.mcast_grp_a = mc_index;
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
            hdr.ipv6.srcAddr                           : exact @name("ipv6.srcAddr") ;
            hdr.ipv6.dstAddr                           : exact @name("ipv6.dstAddr") ;
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
            hdr.ipv6.dstAddr                           : ternary @name("ipv6.dstAddr") ;
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

control process_ipv4_vtep(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_tunnel_termination_flag") action set_tunnel_termination_flag() {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
    }
    @name(".set_tunnel_vni_and_termination_flag") action set_tunnel_vni_and_termination_flag(bit<24> tunnel_vni) {
        meta.tunnel_metadata.tunnel_vni = tunnel_vni;
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
            set_tunnel_vni_and_termination_flag();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf                    : exact @name("l3_metadata.vrf") ;
            hdr.ipv4.dstAddr                        : exact @name("ipv4.dstAddr") ;
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("tunnel_metadata.ingress_tunnel_type") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".ipv4_src_vtep") table ipv4_src_vtep {
        actions = {
            on_miss();
            src_vtep_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf                    : exact @name("l3_metadata.vrf") ;
            hdr.ipv4.srcAddr                        : exact @name("ipv4.srcAddr") ;
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("tunnel_metadata.ingress_tunnel_type") ;
        }
        size = 1024;
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

control process_ipv6_vtep(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_tunnel_termination_flag") action set_tunnel_termination_flag() {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
    }
    @name(".set_tunnel_vni_and_termination_flag") action set_tunnel_vni_and_termination_flag(bit<24> tunnel_vni) {
        meta.tunnel_metadata.tunnel_vni = tunnel_vni;
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
            set_tunnel_vni_and_termination_flag();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf                    : exact @name("l3_metadata.vrf") ;
            hdr.ipv6.dstAddr                        : exact @name("ipv6.dstAddr") ;
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("tunnel_metadata.ingress_tunnel_type") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".ipv6_src_vtep") table ipv6_src_vtep {
        actions = {
            on_miss();
            src_vtep_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf                    : exact @name("l3_metadata.vrf") ;
            hdr.ipv6.srcAddr                        : exact @name("ipv6.srcAddr") ;
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("tunnel_metadata.ingress_tunnel_type") ;
        }
        size = 1024;
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
        meta.l2_metadata.lkp_mac_type = hdr.inner_ethernet.etherType;
    }
    @name(".terminate_vpls") action terminate_vpls(bit<16> bd, bit<5> tunnel_type) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.tunnel_metadata.ingress_tunnel_type = tunnel_type;
        meta.ingress_metadata.bd = bd;
        meta.l2_metadata.lkp_mac_type = hdr.inner_ethernet.etherType;
    }
    @name(".terminate_ipv4_over_mpls") action terminate_ipv4_over_mpls(bit<16> vrf, bit<5> tunnel_type) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.tunnel_metadata.ingress_tunnel_type = tunnel_type;
        meta.l3_metadata.vrf = vrf;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.l3_metadata.lkp_ip_type = 2w1;
        meta.l2_metadata.lkp_mac_type = hdr.inner_ethernet.etherType;
        meta.l3_metadata.lkp_ip_version = hdr.inner_ipv4.version;
        meta.l3_metadata.lkp_ip_tc = hdr.inner_ipv4.diffserv;
    }
    @name(".terminate_ipv6_over_mpls") action terminate_ipv6_over_mpls(bit<16> vrf, bit<5> tunnel_type) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.tunnel_metadata.ingress_tunnel_type = tunnel_type;
        meta.l3_metadata.vrf = vrf;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.l3_metadata.lkp_ip_type = 2w2;
        meta.l2_metadata.lkp_mac_type = hdr.inner_ethernet.etherType;
        meta.l3_metadata.lkp_ip_version = hdr.inner_ipv6.version;
        meta.l3_metadata.lkp_ip_tc = hdr.inner_ipv6.trafficClass;
    }
    @name(".terminate_pw") action terminate_pw(bit<16> ifindex) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
    }
    @name(".forward_mpls") action forward_mpls(bit<16> nexthop_index) {
        meta.l3_metadata.fib_nexthop = nexthop_index;
        meta.l3_metadata.fib_nexthop_type = 1w0;
        meta.l3_metadata.fib_hit = 1w1;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
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
        size = 1024;
        default_action = NoAction();
    }
    apply {
        mpls_0.apply();
    }
}

control process_tunnel(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".non_ip_lkp") action non_ip_lkp() {
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.ig_intr_md_for_tm.mcast_grp_a = 16w0;
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
    @name(".ipv6_lkp") action ipv6_lkp() {
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.ipv6_metadata.lkp_ipv6_sa = hdr.ipv6.srcAddr;
        meta.ipv6_metadata.lkp_ipv6_da = hdr.ipv6.dstAddr;
        meta.l3_metadata.lkp_ip_proto = hdr.ipv6.nextHdr;
        meta.l3_metadata.lkp_ip_ttl = hdr.ipv6.hopLimit;
        meta.l3_metadata.lkp_l4_sport = meta.l3_metadata.lkp_outer_l4_sport;
        meta.l3_metadata.lkp_l4_dport = meta.l3_metadata.lkp_outer_l4_dport;
        meta.ig_intr_md_for_tm.mcast_grp_a = 16w0;
    }
    @name(".on_miss") action on_miss() {
    }
    @name(".outer_rmac_hit") action outer_rmac_hit() {
        meta.l3_metadata.rmac_hit = 1w1;
    }
    @name(".nop") action nop() {
    }
    @name(".tunnel_lookup_miss") action tunnel_lookup_miss() {
    }
    @name(".terminate_tunnel_inner_non_ip") action terminate_tunnel_inner_non_ip(bit<16> bd, bit<16> bd_label, bit<16> stats_idx, bit<16> exclusion_id, bit<16> ingress_rid) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.ingress_metadata.bd = bd;
        meta.acl_metadata.bd_label = bd_label;
        meta.l2_metadata.bd_stats_idx = stats_idx;
        meta.l3_metadata.lkp_ip_type = 2w0;
        meta.l2_metadata.lkp_mac_type = hdr.inner_ethernet.etherType;
        meta.ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        meta.ig_intr_md_for_tm.rid = ingress_rid;
    }
    @name(".terminate_tunnel_inner_ethernet_ipv4") action terminate_tunnel_inner_ethernet_ipv4(bit<16> bd, bit<16> vrf, bit<10> rmac_group, bit<16> bd_label, bit<1> ipv4_unicast_enabled, bit<2> ipv4_urpf_mode, bit<1> igmp_snooping_enabled, bit<16> stats_idx, bit<1> ipv4_multicast_enabled, bit<16> mrpf_group, bit<16> exclusion_id, bit<16> ingress_rid) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.ingress_metadata.bd = bd;
        meta.l3_metadata.vrf = vrf;
        meta.qos_metadata.outer_dscp = meta.l3_metadata.lkp_ip_tc;
        meta.ipv4_metadata.ipv4_unicast_enabled = ipv4_unicast_enabled;
        meta.ipv4_metadata.ipv4_urpf_mode = ipv4_urpf_mode;
        meta.l3_metadata.rmac_group = rmac_group;
        meta.acl_metadata.bd_label = bd_label;
        meta.l2_metadata.bd_stats_idx = stats_idx;
        meta.l3_metadata.lkp_ip_type = 2w1;
        meta.l2_metadata.lkp_mac_type = hdr.inner_ethernet.etherType;
        meta.l3_metadata.lkp_ip_version = hdr.inner_ipv4.version;
        meta.l3_metadata.lkp_ip_tc = hdr.inner_ipv4.diffserv;
        meta.multicast_metadata.igmp_snooping_enabled = igmp_snooping_enabled;
        meta.multicast_metadata.ipv4_multicast_enabled = ipv4_multicast_enabled;
        meta.multicast_metadata.bd_mrpf_group = mrpf_group;
        meta.ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        meta.ig_intr_md_for_tm.rid = ingress_rid;
    }
    @name(".terminate_tunnel_inner_ipv4") action terminate_tunnel_inner_ipv4(bit<16> vrf, bit<10> rmac_group, bit<2> ipv4_urpf_mode, bit<1> ipv4_unicast_enabled, bit<1> ipv4_multicast_enabled, bit<16> mrpf_group) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.l3_metadata.vrf = vrf;
        meta.qos_metadata.outer_dscp = meta.l3_metadata.lkp_ip_tc;
        meta.ipv4_metadata.ipv4_unicast_enabled = ipv4_unicast_enabled;
        meta.ipv4_metadata.ipv4_urpf_mode = ipv4_urpf_mode;
        meta.l3_metadata.rmac_group = rmac_group;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.l3_metadata.lkp_ip_type = 2w1;
        meta.l3_metadata.lkp_ip_version = hdr.inner_ipv4.version;
        meta.l3_metadata.lkp_ip_tc = hdr.inner_ipv4.diffserv;
        meta.multicast_metadata.bd_mrpf_group = mrpf_group;
        meta.multicast_metadata.ipv4_multicast_enabled = ipv4_multicast_enabled;
    }
    @name(".terminate_tunnel_inner_ethernet_ipv6") action terminate_tunnel_inner_ethernet_ipv6(bit<16> bd, bit<16> vrf, bit<10> rmac_group, bit<16> bd_label, bit<1> ipv6_unicast_enabled, bit<2> ipv6_urpf_mode, bit<1> mld_snooping_enabled, bit<16> stats_idx, bit<1> ipv6_multicast_enabled, bit<16> mrpf_group, bit<16> exclusion_id, bit<16> ingress_rid) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.ingress_metadata.bd = bd;
        meta.l3_metadata.vrf = vrf;
        meta.qos_metadata.outer_dscp = meta.l3_metadata.lkp_ip_tc;
        meta.ipv6_metadata.ipv6_unicast_enabled = ipv6_unicast_enabled;
        meta.ipv6_metadata.ipv6_urpf_mode = ipv6_urpf_mode;
        meta.l3_metadata.rmac_group = rmac_group;
        meta.acl_metadata.bd_label = bd_label;
        meta.l2_metadata.bd_stats_idx = stats_idx;
        meta.l3_metadata.lkp_ip_type = 2w2;
        meta.l2_metadata.lkp_mac_type = hdr.inner_ethernet.etherType;
        meta.l3_metadata.lkp_ip_version = hdr.inner_ipv6.version;
        meta.l3_metadata.lkp_ip_tc = hdr.inner_ipv6.trafficClass;
        meta.multicast_metadata.bd_mrpf_group = mrpf_group;
        meta.multicast_metadata.ipv6_multicast_enabled = ipv6_multicast_enabled;
        meta.multicast_metadata.mld_snooping_enabled = mld_snooping_enabled;
        meta.ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        meta.ig_intr_md_for_tm.rid = ingress_rid;
    }
    @name(".terminate_tunnel_inner_ipv6") action terminate_tunnel_inner_ipv6(bit<16> vrf, bit<10> rmac_group, bit<1> ipv6_unicast_enabled, bit<2> ipv6_urpf_mode, bit<1> ipv6_multicast_enabled, bit<16> mrpf_group) {
        meta.tunnel_metadata.tunnel_terminate = 1w1;
        meta.l3_metadata.vrf = vrf;
        meta.qos_metadata.outer_dscp = meta.l3_metadata.lkp_ip_tc;
        meta.ipv6_metadata.ipv6_unicast_enabled = ipv6_unicast_enabled;
        meta.ipv6_metadata.ipv6_urpf_mode = ipv6_urpf_mode;
        meta.l3_metadata.rmac_group = rmac_group;
        meta.l2_metadata.lkp_mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.ethernet.dstAddr;
        meta.l3_metadata.lkp_ip_type = 2w2;
        meta.l3_metadata.lkp_ip_version = hdr.inner_ipv6.version;
        meta.l3_metadata.lkp_ip_tc = hdr.inner_ipv6.trafficClass;
        meta.multicast_metadata.bd_mrpf_group = mrpf_group;
        meta.multicast_metadata.ipv6_multicast_enabled = ipv6_multicast_enabled;
    }
    @name(".adjust_lkp_fields") table adjust_lkp_fields {
        actions = {
            non_ip_lkp();
            ipv4_lkp();
            ipv6_lkp();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.isValid(): exact @name("ipv4.$valid$") ;
            hdr.ipv6.isValid(): exact @name("ipv6.$valid$") ;
        }
        default_action = NoAction();
    }
    @ternary(1) @name(".outer_rmac") table outer_rmac {
        actions = {
            on_miss();
            outer_rmac_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.rmac_group: exact @name("l3_metadata.rmac_group") ;
            hdr.ethernet.dstAddr       : exact @name("ethernet.dstAddr") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".tunnel") table tunnel {
        actions = {
            nop();
            tunnel_lookup_miss();
            terminate_tunnel_inner_non_ip();
            terminate_tunnel_inner_ethernet_ipv4();
            terminate_tunnel_inner_ipv4();
            terminate_tunnel_inner_ethernet_ipv6();
            terminate_tunnel_inner_ipv6();
            @defaultonly NoAction();
        }
        key = {
            meta.tunnel_metadata.tunnel_vni         : exact @name("tunnel_metadata.tunnel_vni") ;
            meta.tunnel_metadata.ingress_tunnel_type: exact @name("tunnel_metadata.ingress_tunnel_type") ;
            hdr.inner_ipv4.isValid()                : exact @name("inner_ipv4.$valid$") ;
            hdr.inner_ipv6.isValid()                : exact @name("inner_ipv6.$valid$") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".tunnel_lookup_miss") table tunnel_lookup_miss_0 {
        actions = {
            non_ip_lkp();
            ipv4_lkp();
            ipv6_lkp();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.isValid(): exact @name("ipv4.$valid$") ;
            hdr.ipv6.isValid(): exact @name("ipv6.$valid$") ;
        }
        default_action = NoAction();
    }
    @name(".process_ingress_fabric") process_ingress_fabric() process_ingress_fabric_0;
    @name(".process_outer_multicast") process_outer_multicast() process_outer_multicast_0;
    @name(".process_ipv4_vtep") process_ipv4_vtep() process_ipv4_vtep_0;
    @name(".process_ipv6_vtep") process_ipv6_vtep() process_ipv6_vtep_0;
    @name(".process_mpls") process_mpls() process_mpls_0;
    apply {
        process_ingress_fabric_0.apply(hdr, meta, standard_metadata);
        if (meta.tunnel_metadata.ingress_tunnel_type != 5w0) 
            switch (outer_rmac.apply().action_run) {
                on_miss: {
                    process_outer_multicast_0.apply(hdr, meta, standard_metadata);
                }
                default: {
                    if (hdr.ipv4.isValid()) 
                        process_ipv4_vtep_0.apply(hdr, meta, standard_metadata);
                    else 
                        if (hdr.ipv6.isValid()) 
                            process_ipv6_vtep_0.apply(hdr, meta, standard_metadata);
                        else 
                            if (hdr.mpls[0].isValid()) 
                                process_mpls_0.apply(hdr, meta, standard_metadata);
                }
            }

        if (meta.tunnel_metadata.tunnel_terminate == 1w1 || meta.multicast_metadata.outer_mcast_route_hit == 1w1 && (meta.multicast_metadata.outer_mcast_mode == 2w1 && meta.multicast_metadata.mcast_rpf_group == 16w0 || meta.multicast_metadata.outer_mcast_mode == 2w2 && meta.multicast_metadata.mcast_rpf_group != 16w0)) 
            switch (tunnel.apply().action_run) {
                tunnel_lookup_miss: {
                    tunnel_lookup_miss_0.apply();
                }
            }

        else 
            adjust_lkp_fields.apply();
    }
}

control process_storm_control(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".storm_control_meter") meter(32w1024, MeterType.bytes) storm_control_meter;
    @name(".nop") action nop() {
    }
    @name(".set_storm_control_meter") action set_storm_control_meter(bit<32> meter_idx) {
        storm_control_meter.execute_meter<bit<2>>(meter_idx, meta.meter_metadata.meter_color);
        meta.meter_metadata.meter_index = (bit<16>)meter_idx;
    }
    @name(".storm_control") table storm_control {
        actions = {
            nop();
            set_storm_control_meter();
            @defaultonly NoAction();
        }
        key = {
            meta.ig_intr_md.ingress_port : exact @name("ig_intr_md.ingress_port") ;
            meta.l2_metadata.lkp_pkt_type: ternary @name("l2_metadata.lkp_pkt_type") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.ingress_metadata.port_type == 2w0) 
            storm_control.apply();
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
    @name(".validate_packet") table validate_packet {
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
            meta.l2_metadata.lkp_mac_sa[40:40]     : ternary @name("l2_metadata.lkp_mac_sa") ;
            meta.l2_metadata.lkp_mac_da            : ternary @name("l2_metadata.lkp_mac_da") ;
            meta.l3_metadata.lkp_ip_type           : ternary @name("l3_metadata.lkp_ip_type") ;
            meta.l3_metadata.lkp_ip_ttl            : ternary @name("l3_metadata.lkp_ip_ttl") ;
            meta.l3_metadata.lkp_ip_version        : ternary @name("l3_metadata.lkp_ip_version") ;
            meta.ipv4_metadata.lkp_ipv4_sa[31:24]  : ternary @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv6_metadata.lkp_ipv6_sa[127:112]: ternary @name("ipv6_metadata.lkp_ipv6_sa") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.ingress_metadata.drop_flag == 1w0) 
            validate_packet.apply();
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
    }
    @name(".dmac_miss") action dmac_miss() {
        meta.ingress_metadata.egress_ifindex = 16w65535;
    }
    @name(".dmac_redirect_nexthop") action dmac_redirect_nexthop(bit<16> nexthop_index) {
        meta.l2_metadata.l2_redirect = 1w1;
        meta.l2_metadata.l2_nexthop = nexthop_index;
        meta.l2_metadata.l2_nexthop_type = 1w0;
    }
    @name(".dmac_redirect_ecmp") action dmac_redirect_ecmp(bit<16> ecmp_index) {
        meta.l2_metadata.l2_redirect = 1w1;
        meta.l2_metadata.l2_nexthop = ecmp_index;
        meta.l2_metadata.l2_nexthop_type = 1w1;
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
    @name(".dmac") table dmac {
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
            meta.ingress_metadata.bd   : exact @name("ingress_metadata.bd") ;
            meta.l2_metadata.lkp_mac_da: exact @name("l2_metadata.lkp_mac_da") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".smac") table smac {
        actions = {
            nop();
            smac_miss();
            smac_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.bd   : exact @name("ingress_metadata.bd") ;
            meta.l2_metadata.lkp_mac_sa: exact @name("l2_metadata.lkp_mac_sa") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        if (meta.ingress_metadata.port_type == 2w0) 
            smac.apply();
        if (meta.ingress_metadata.bypass_lookups & 16w0x1 == 16w0) 
            dmac.apply();
    }
}

control process_mac_acl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".acl_deny") action acl_deny(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<1> acl_copy, bit<16> acl_copy_reason, bit<2> nat_mode) {
        meta.acl_metadata.acl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.acl_metadata.acl_copy = acl_copy;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_permit") action acl_permit(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<1> acl_copy, bit<16> acl_copy_reason, bit<2> nat_mode) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.acl_metadata.acl_copy = acl_copy;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_redirect_nexthop") action acl_redirect_nexthop(bit<16> nexthop_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<1> acl_copy, bit<16> acl_copy_reason, bit<2> nat_mode) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = nexthop_index;
        meta.acl_metadata.acl_nexthop_type = 1w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.acl_metadata.acl_copy = acl_copy;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_redirect_ecmp") action acl_redirect_ecmp(bit<16> ecmp_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<1> acl_copy, bit<16> acl_copy_reason, bit<2> nat_mode) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = ecmp_index;
        meta.acl_metadata.acl_nexthop_type = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.acl_metadata.acl_copy = acl_copy;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_mirror") action acl_mirror(bit<32> session_id, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<2> nat_mode) {
        meta.i2e_metadata.mirror_session_id = (bit<16>)session_id;
        clone3<tuple<bit<32>, bit<16>>>(CloneType.I2E, session_id, { meta.i2e_metadata.ingress_tstamp, meta.i2e_metadata.mirror_session_id });
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".mac_acl") table mac_acl {
        actions = {
            nop();
            acl_deny();
            acl_permit();
            acl_redirect_nexthop();
            acl_redirect_ecmp();
            acl_mirror();
            @defaultonly NoAction();
        }
        key = {
            meta.acl_metadata.if_label   : ternary @name("acl_metadata.if_label") ;
            meta.acl_metadata.bd_label   : ternary @name("acl_metadata.bd_label") ;
            meta.l2_metadata.lkp_mac_sa  : ternary @name("l2_metadata.lkp_mac_sa") ;
            meta.l2_metadata.lkp_mac_da  : ternary @name("l2_metadata.lkp_mac_da") ;
            meta.l2_metadata.lkp_mac_type: ternary @name("l2_metadata.lkp_mac_type") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.ingress_metadata.bypass_lookups & 16w0x4 == 16w0) 
            mac_acl.apply();
    }
}

control process_ip_acl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".acl_deny") action acl_deny(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<1> acl_copy, bit<16> acl_copy_reason, bit<2> nat_mode) {
        meta.acl_metadata.acl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.acl_metadata.acl_copy = acl_copy;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_permit") action acl_permit(bit<14> acl_stats_index, bit<16> acl_meter_index, bit<1> acl_copy, bit<16> acl_copy_reason, bit<2> nat_mode) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.acl_metadata.acl_copy = acl_copy;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_redirect_nexthop") action acl_redirect_nexthop(bit<16> nexthop_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<1> acl_copy, bit<16> acl_copy_reason, bit<2> nat_mode) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = nexthop_index;
        meta.acl_metadata.acl_nexthop_type = 1w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.acl_metadata.acl_copy = acl_copy;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_redirect_ecmp") action acl_redirect_ecmp(bit<16> ecmp_index, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<1> acl_copy, bit<16> acl_copy_reason, bit<2> nat_mode) {
        meta.acl_metadata.acl_redirect = 1w1;
        meta.acl_metadata.acl_nexthop = ecmp_index;
        meta.acl_metadata.acl_nexthop_type = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.acl_metadata.acl_copy = acl_copy;
        meta.fabric_metadata.reason_code = acl_copy_reason;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".acl_mirror") action acl_mirror(bit<32> session_id, bit<14> acl_stats_index, bit<16> acl_meter_index, bit<2> nat_mode) {
        meta.i2e_metadata.mirror_session_id = (bit<16>)session_id;
        clone3<tuple<bit<32>, bit<16>>>(CloneType.I2E, session_id, { meta.i2e_metadata.ingress_tstamp, meta.i2e_metadata.mirror_session_id });
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.meter_metadata.meter_index = acl_meter_index;
        meta.nat_metadata.ingress_nat_mode = nat_mode;
    }
    @name(".ip_acl") table ip_acl {
        actions = {
            nop();
            acl_deny();
            acl_permit();
            acl_redirect_nexthop();
            acl_redirect_ecmp();
            acl_mirror();
            @defaultonly NoAction();
        }
        key = {
            meta.acl_metadata.if_label    : ternary @name("acl_metadata.if_label") ;
            meta.acl_metadata.bd_label    : ternary @name("acl_metadata.bd_label") ;
            meta.ipv4_metadata.lkp_ipv4_sa: ternary @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da: ternary @name("ipv4_metadata.lkp_ipv4_da") ;
            meta.l3_metadata.lkp_ip_proto : ternary @name("l3_metadata.lkp_ip_proto") ;
            meta.l3_metadata.lkp_l4_sport : ternary @name("l3_metadata.lkp_l4_sport") ;
            meta.l3_metadata.lkp_l4_dport : ternary @name("l3_metadata.lkp_l4_dport") ;
            hdr.tcp.flags                 : ternary @name("tcp.flags") ;
            meta.l3_metadata.lkp_ip_ttl   : ternary @name("l3_metadata.lkp_ip_ttl") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".ipv6_acl") table ipv6_acl {
        actions = {
            nop();
            acl_deny();
            acl_permit();
            acl_redirect_nexthop();
            acl_redirect_ecmp();
            acl_mirror();
            @defaultonly NoAction();
        }
        key = {
            meta.acl_metadata.if_label    : ternary @name("acl_metadata.if_label") ;
            meta.acl_metadata.bd_label    : ternary @name("acl_metadata.bd_label") ;
            meta.ipv6_metadata.lkp_ipv6_sa: ternary @name("ipv6_metadata.lkp_ipv6_sa") ;
            meta.ipv6_metadata.lkp_ipv6_da: ternary @name("ipv6_metadata.lkp_ipv6_da") ;
            meta.l3_metadata.lkp_ip_proto : ternary @name("l3_metadata.lkp_ip_proto") ;
            meta.l3_metadata.lkp_l4_sport : ternary @name("l3_metadata.lkp_l4_sport") ;
            meta.l3_metadata.lkp_l4_dport : ternary @name("l3_metadata.lkp_l4_dport") ;
            hdr.tcp.flags                 : ternary @name("tcp.flags") ;
            meta.l3_metadata.lkp_ip_ttl   : ternary @name("l3_metadata.lkp_ip_ttl") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.ingress_metadata.bypass_lookups & 16w0x4 == 16w0) 
            if (meta.l3_metadata.lkp_ip_type == 2w1) 
                ip_acl.apply();
            else 
                if (meta.l3_metadata.lkp_ip_type == 2w2) 
                    ipv6_acl.apply();
    }
}

control process_int_upstream_report(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_qos(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_ipv4_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".ipv4_multicast_route_s_g_stats") direct_counter(CounterType.packets) ipv4_multicast_route_s_g_stats;
    @name(".ipv4_multicast_route_star_g_stats") direct_counter(CounterType.packets) ipv4_multicast_route_star_g_stats;
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
    @name(".multicast_route_star_g_miss") action multicast_route_star_g_miss() {
        meta.l3_metadata.l3_copy = 1w1;
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
        size = 1024;
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
        size = 1024;
        default_action = NoAction();
    }
    @name(".on_miss") action on_miss_0() {
        ipv4_multicast_route_s_g_stats.count();
    }
    @name(".multicast_route_s_g_hit") action multicast_route_s_g_hit_0(bit<16> mc_index, bit<16> mcast_rpf_group) {
        ipv4_multicast_route_s_g_stats.count();
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_mode = 2w1;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".ipv4_multicast_route") table ipv4_multicast_route {
        actions = {
            on_miss_0();
            multicast_route_s_g_hit_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_sa: exact @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 1024;
        counters = ipv4_multicast_route_s_g_stats;
        default_action = NoAction();
    }
    @name(".multicast_route_star_g_miss") action multicast_route_star_g_miss_0() {
        ipv4_multicast_route_star_g_stats.count();
        meta.l3_metadata.l3_copy = 1w1;
    }
    @name(".multicast_route_sm_star_g_hit") action multicast_route_sm_star_g_hit_0(bit<16> mc_index, bit<16> mcast_rpf_group) {
        ipv4_multicast_route_star_g_stats.count();
        meta.multicast_metadata.mcast_mode = 2w1;
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".multicast_route_bidir_star_g_hit") action multicast_route_bidir_star_g_hit_0(bit<16> mc_index, bit<16> mcast_rpf_group) {
        ipv4_multicast_route_star_g_stats.count();
        meta.multicast_metadata.mcast_mode = 2w2;
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group | meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".ipv4_multicast_route_star_g") table ipv4_multicast_route_star_g {
        actions = {
            multicast_route_star_g_miss_0();
            multicast_route_sm_star_g_hit_0();
            multicast_route_bidir_star_g_hit_0();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 1024;
        counters = ipv4_multicast_route_star_g_stats;
        default_action = NoAction();
    }
    apply {
        if (meta.ingress_metadata.bypass_lookups & 16w0x1 == 16w0) 
            switch (ipv4_multicast_bridge.apply().action_run) {
                on_miss: {
                    ipv4_multicast_bridge_star_g.apply();
                }
            }

        if (meta.ingress_metadata.bypass_lookups & 16w0x2 == 16w0 && meta.multicast_metadata.ipv4_multicast_enabled == 1w1) 
            switch (ipv4_multicast_route.apply().action_run) {
                on_miss_0: {
                    ipv4_multicast_route_star_g.apply();
                }
            }

    }
}

control process_ipv6_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".ipv6_multicast_route_s_g_stats") direct_counter(CounterType.packets) ipv6_multicast_route_s_g_stats;
    @name(".ipv6_multicast_route_star_g_stats") direct_counter(CounterType.packets) ipv6_multicast_route_star_g_stats;
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
    @name(".multicast_route_star_g_miss") action multicast_route_star_g_miss() {
        meta.l3_metadata.l3_copy = 1w1;
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
        size = 1024;
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
        size = 1024;
        default_action = NoAction();
    }
    @name(".on_miss") action on_miss_1() {
        ipv6_multicast_route_s_g_stats.count();
    }
    @name(".multicast_route_s_g_hit") action multicast_route_s_g_hit_1(bit<16> mc_index, bit<16> mcast_rpf_group) {
        ipv6_multicast_route_s_g_stats.count();
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_mode = 2w1;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".ipv6_multicast_route") table ipv6_multicast_route {
        actions = {
            on_miss_1();
            multicast_route_s_g_hit_1();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_sa: exact @name("ipv6_metadata.lkp_ipv6_sa") ;
            meta.ipv6_metadata.lkp_ipv6_da: exact @name("ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 1024;
        counters = ipv6_multicast_route_s_g_stats;
        default_action = NoAction();
    }
    @name(".multicast_route_star_g_miss") action multicast_route_star_g_miss_1() {
        ipv6_multicast_route_star_g_stats.count();
        meta.l3_metadata.l3_copy = 1w1;
    }
    @name(".multicast_route_sm_star_g_hit") action multicast_route_sm_star_g_hit_1(bit<16> mc_index, bit<16> mcast_rpf_group) {
        ipv6_multicast_route_star_g_stats.count();
        meta.multicast_metadata.mcast_mode = 2w1;
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group ^ meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".multicast_route_bidir_star_g_hit") action multicast_route_bidir_star_g_hit_1(bit<16> mc_index, bit<16> mcast_rpf_group) {
        ipv6_multicast_route_star_g_stats.count();
        meta.multicast_metadata.mcast_mode = 2w2;
        meta.multicast_metadata.multicast_route_mc_index = mc_index;
        meta.multicast_metadata.mcast_route_hit = 1w1;
        meta.multicast_metadata.mcast_rpf_group = mcast_rpf_group | meta.multicast_metadata.bd_mrpf_group;
    }
    @name(".ipv6_multicast_route_star_g") table ipv6_multicast_route_star_g {
        actions = {
            multicast_route_star_g_miss_1();
            multicast_route_sm_star_g_hit_1();
            multicast_route_bidir_star_g_hit_1();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_da: exact @name("ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 1024;
        counters = ipv6_multicast_route_star_g_stats;
        default_action = NoAction();
    }
    apply {
        if (meta.ingress_metadata.bypass_lookups & 16w0x1 == 16w0) 
            switch (ipv6_multicast_bridge.apply().action_run) {
                on_miss: {
                    ipv6_multicast_bridge_star_g.apply();
                }
            }

        if (meta.ingress_metadata.bypass_lookups & 16w0x2 == 16w0 && meta.multicast_metadata.ipv6_multicast_enabled == 1w1) 
            switch (ipv6_multicast_route.apply().action_run) {
                on_miss_1: {
                    ipv6_multicast_route_star_g.apply();
                }
            }

    }
}

control process_multicast_rpf(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_multicast(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".process_ipv4_multicast") process_ipv4_multicast() process_ipv4_multicast_0;
    @name(".process_ipv6_multicast") process_ipv6_multicast() process_ipv6_multicast_0;
    @name(".process_multicast_rpf") process_multicast_rpf() process_multicast_rpf_0;
    apply {
        if (meta.l3_metadata.lkp_ip_type == 2w1) 
            process_ipv4_multicast_0.apply(hdr, meta, standard_metadata);
        else 
            if (meta.l3_metadata.lkp_ip_type == 2w2) 
                process_ipv6_multicast_0.apply(hdr, meta, standard_metadata);
        process_multicast_rpf_0.apply(hdr, meta, standard_metadata);
    }
}

control process_ipv4_racl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".racl_deny") action racl_deny(bit<14> acl_stats_index, bit<1> acl_copy, bit<16> acl_copy_reason) {
        meta.acl_metadata.racl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.acl_metadata.acl_copy = acl_copy;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".racl_permit") action racl_permit(bit<14> acl_stats_index, bit<1> acl_copy, bit<16> acl_copy_reason) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.acl_metadata.acl_copy = acl_copy;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".racl_redirect_nexthop") action racl_redirect_nexthop(bit<16> nexthop_index, bit<14> acl_stats_index, bit<1> acl_copy, bit<16> acl_copy_reason) {
        meta.acl_metadata.racl_redirect = 1w1;
        meta.acl_metadata.racl_nexthop = nexthop_index;
        meta.acl_metadata.racl_nexthop_type = 1w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.acl_metadata.acl_copy = acl_copy;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".racl_redirect_ecmp") action racl_redirect_ecmp(bit<16> ecmp_index, bit<14> acl_stats_index, bit<1> acl_copy, bit<16> acl_copy_reason) {
        meta.acl_metadata.racl_redirect = 1w1;
        meta.acl_metadata.racl_nexthop = ecmp_index;
        meta.acl_metadata.racl_nexthop_type = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.acl_metadata.acl_copy = acl_copy;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".ipv4_racl") table ipv4_racl {
        actions = {
            nop();
            racl_deny();
            racl_permit();
            racl_redirect_nexthop();
            racl_redirect_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.acl_metadata.bd_label    : ternary @name("acl_metadata.bd_label") ;
            meta.ipv4_metadata.lkp_ipv4_sa: ternary @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da: ternary @name("ipv4_metadata.lkp_ipv4_da") ;
            meta.l3_metadata.lkp_ip_proto : ternary @name("l3_metadata.lkp_ip_proto") ;
            meta.l3_metadata.lkp_l4_sport : ternary @name("l3_metadata.lkp_l4_sport") ;
            meta.l3_metadata.lkp_l4_dport : ternary @name("l3_metadata.lkp_l4_dport") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        ipv4_racl.apply();
    }
}

control process_ipv4_urpf(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".on_miss") action on_miss() {
    }
    @name(".ipv4_urpf_hit") action ipv4_urpf_hit(bit<16> urpf_bd_group) {
        meta.l3_metadata.urpf_hit = 1w1;
        meta.l3_metadata.urpf_bd_group = urpf_bd_group;
        meta.l3_metadata.urpf_mode = meta.ipv4_metadata.ipv4_urpf_mode;
    }
    @name(".urpf_miss") action urpf_miss() {
        meta.l3_metadata.urpf_check_fail = 1w1;
    }
    @name(".ipv4_urpf") table ipv4_urpf {
        actions = {
            on_miss();
            ipv4_urpf_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_sa: exact @name("ipv4_metadata.lkp_ipv4_sa") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".ipv4_urpf_lpm") table ipv4_urpf_lpm {
        actions = {
            ipv4_urpf_hit();
            urpf_miss();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_sa: lpm @name("ipv4_metadata.lkp_ipv4_sa") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.ipv4_metadata.ipv4_urpf_mode != 2w0) 
            switch (ipv4_urpf.apply().action_run) {
                on_miss: {
                    ipv4_urpf_lpm.apply();
                }
            }

    }
}

control process_ipv4_fib(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".on_miss") action on_miss() {
    }
    @name(".fib_hit_nexthop") action fib_hit_nexthop(bit<16> nexthop_index) {
        meta.l3_metadata.fib_hit = 1w1;
        meta.l3_metadata.fib_nexthop = nexthop_index;
        meta.l3_metadata.fib_nexthop_type = 1w0;
    }
    @name(".fib_hit_ecmp") action fib_hit_ecmp(bit<16> ecmp_index) {
        meta.l3_metadata.fib_hit = 1w1;
        meta.l3_metadata.fib_nexthop = ecmp_index;
        meta.l3_metadata.fib_nexthop_type = 1w1;
    }
    @name(".ipv4_fib") table ipv4_fib {
        actions = {
            on_miss();
            fib_hit_nexthop();
            fib_hit_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".ipv4_fib_lpm") table ipv4_fib_lpm {
        actions = {
            on_miss();
            fib_hit_nexthop();
            fib_hit_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da: lpm @name("ipv4_metadata.lkp_ipv4_da") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        switch (ipv4_fib.apply().action_run) {
            on_miss: {
                ipv4_fib_lpm.apply();
            }
        }

    }
}

control process_ipv6_racl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".racl_deny") action racl_deny(bit<14> acl_stats_index, bit<1> acl_copy, bit<16> acl_copy_reason) {
        meta.acl_metadata.racl_deny = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.acl_metadata.acl_copy = acl_copy;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".racl_permit") action racl_permit(bit<14> acl_stats_index, bit<1> acl_copy, bit<16> acl_copy_reason) {
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.acl_metadata.acl_copy = acl_copy;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".racl_redirect_nexthop") action racl_redirect_nexthop(bit<16> nexthop_index, bit<14> acl_stats_index, bit<1> acl_copy, bit<16> acl_copy_reason) {
        meta.acl_metadata.racl_redirect = 1w1;
        meta.acl_metadata.racl_nexthop = nexthop_index;
        meta.acl_metadata.racl_nexthop_type = 1w0;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.acl_metadata.acl_copy = acl_copy;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".racl_redirect_ecmp") action racl_redirect_ecmp(bit<16> ecmp_index, bit<14> acl_stats_index, bit<1> acl_copy, bit<16> acl_copy_reason) {
        meta.acl_metadata.racl_redirect = 1w1;
        meta.acl_metadata.racl_nexthop = ecmp_index;
        meta.acl_metadata.racl_nexthop_type = 1w1;
        meta.acl_metadata.acl_stats_index = acl_stats_index;
        meta.acl_metadata.acl_copy = acl_copy;
        meta.fabric_metadata.reason_code = acl_copy_reason;
    }
    @name(".ipv6_racl") table ipv6_racl {
        actions = {
            nop();
            racl_deny();
            racl_permit();
            racl_redirect_nexthop();
            racl_redirect_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.acl_metadata.bd_label    : ternary @name("acl_metadata.bd_label") ;
            meta.ipv6_metadata.lkp_ipv6_sa: ternary @name("ipv6_metadata.lkp_ipv6_sa") ;
            meta.ipv6_metadata.lkp_ipv6_da: ternary @name("ipv6_metadata.lkp_ipv6_da") ;
            meta.l3_metadata.lkp_ip_proto : ternary @name("l3_metadata.lkp_ip_proto") ;
            meta.l3_metadata.lkp_l4_sport : ternary @name("l3_metadata.lkp_l4_sport") ;
            meta.l3_metadata.lkp_l4_dport : ternary @name("l3_metadata.lkp_l4_dport") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        ipv6_racl.apply();
    }
}

control process_ipv6_urpf(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".on_miss") action on_miss() {
    }
    @name(".ipv6_urpf_hit") action ipv6_urpf_hit(bit<16> urpf_bd_group) {
        meta.l3_metadata.urpf_hit = 1w1;
        meta.l3_metadata.urpf_bd_group = urpf_bd_group;
        meta.l3_metadata.urpf_mode = meta.ipv6_metadata.ipv6_urpf_mode;
    }
    @name(".urpf_miss") action urpf_miss() {
        meta.l3_metadata.urpf_check_fail = 1w1;
    }
    @name(".ipv6_urpf") table ipv6_urpf {
        actions = {
            on_miss();
            ipv6_urpf_hit();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_sa: exact @name("ipv6_metadata.lkp_ipv6_sa") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".ipv6_urpf_lpm") table ipv6_urpf_lpm {
        actions = {
            ipv6_urpf_hit();
            urpf_miss();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_sa: lpm @name("ipv6_metadata.lkp_ipv6_sa") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.ipv6_metadata.ipv6_urpf_mode != 2w0) 
            switch (ipv6_urpf.apply().action_run) {
                on_miss: {
                    ipv6_urpf_lpm.apply();
                }
            }

    }
}

control process_ipv6_fib(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".on_miss") action on_miss() {
    }
    @name(".fib_hit_nexthop") action fib_hit_nexthop(bit<16> nexthop_index) {
        meta.l3_metadata.fib_hit = 1w1;
        meta.l3_metadata.fib_nexthop = nexthop_index;
        meta.l3_metadata.fib_nexthop_type = 1w0;
    }
    @name(".fib_hit_ecmp") action fib_hit_ecmp(bit<16> ecmp_index) {
        meta.l3_metadata.fib_hit = 1w1;
        meta.l3_metadata.fib_nexthop = ecmp_index;
        meta.l3_metadata.fib_nexthop_type = 1w1;
    }
    @name(".ipv6_fib") table ipv6_fib {
        actions = {
            on_miss();
            fib_hit_nexthop();
            fib_hit_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_da: exact @name("ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".ipv6_fib_lpm") table ipv6_fib_lpm {
        actions = {
            on_miss();
            fib_hit_nexthop();
            fib_hit_ecmp();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv6_metadata.lkp_ipv6_da: lpm @name("ipv6_metadata.lkp_ipv6_da") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        switch (ipv6_fib.apply().action_run) {
            on_miss: {
                ipv6_fib_lpm.apply();
            }
        }

    }
}

control process_urpf_bd(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".urpf_bd_miss") action urpf_bd_miss() {
        meta.l3_metadata.urpf_check_fail = 1w1;
    }
    @name(".urpf_bd") table urpf_bd {
        actions = {
            nop();
            urpf_bd_miss();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.urpf_bd_group: exact @name("l3_metadata.urpf_bd_group") ;
            meta.ingress_metadata.bd      : exact @name("ingress_metadata.bd") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        if (meta.l3_metadata.urpf_mode == 2w2 && meta.l3_metadata.urpf_hit == 1w1) 
            urpf_bd.apply();
    }
}

control process_ingress_nat(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".on_miss") action on_miss() {
    }
    @name(".set_dst_nat_nexthop_index") action set_dst_nat_nexthop_index(bit<16> nexthop_index, bit<1> nexthop_type, bit<14> nat_rewrite_index) {
        meta.nat_metadata.nat_nexthop = nexthop_index;
        meta.nat_metadata.nat_nexthop_type = nexthop_type;
        meta.nat_metadata.nat_rewrite_index = nat_rewrite_index;
        meta.nat_metadata.nat_hit = 1w1;
    }
    @name(".nop") action nop() {
    }
    @name(".set_src_nat_rewrite_index") action set_src_nat_rewrite_index(bit<14> nat_rewrite_index) {
        meta.nat_metadata.nat_rewrite_index = nat_rewrite_index;
    }
    @name(".set_twice_nat_nexthop_index") action set_twice_nat_nexthop_index(bit<16> nexthop_index, bit<1> nexthop_type, bit<14> nat_rewrite_index) {
        meta.nat_metadata.nat_nexthop = nexthop_index;
        meta.nat_metadata.nat_nexthop_type = nexthop_type;
        meta.nat_metadata.nat_rewrite_index = nat_rewrite_index;
        meta.nat_metadata.nat_hit = 1w1;
    }
    @name(".nat_dst") table nat_dst {
        actions = {
            on_miss();
            set_dst_nat_nexthop_index();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("ipv4_metadata.lkp_ipv4_da") ;
            meta.l3_metadata.lkp_ip_proto : exact @name("l3_metadata.lkp_ip_proto") ;
            meta.l3_metadata.lkp_l4_dport : exact @name("l3_metadata.lkp_l4_dport") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".nat_flow") table nat_flow {
        actions = {
            nop();
            set_src_nat_rewrite_index();
            set_dst_nat_nexthop_index();
            set_twice_nat_nexthop_index();
            @defaultonly NoAction();
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
        default_action = NoAction();
    }
    @name(".nat_src") table nat_src {
        actions = {
            on_miss();
            set_src_nat_rewrite_index();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_sa: exact @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.l3_metadata.lkp_ip_proto : exact @name("l3_metadata.lkp_ip_proto") ;
            meta.l3_metadata.lkp_l4_sport : exact @name("l3_metadata.lkp_l4_sport") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".nat_twice") table nat_twice {
        actions = {
            on_miss();
            set_twice_nat_nexthop_index();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.vrf          : exact @name("l3_metadata.vrf") ;
            meta.ipv4_metadata.lkp_ipv4_sa: exact @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da: exact @name("ipv4_metadata.lkp_ipv4_da") ;
            meta.l3_metadata.lkp_ip_proto : exact @name("l3_metadata.lkp_ip_proto") ;
            meta.l3_metadata.lkp_l4_sport : exact @name("l3_metadata.lkp_l4_sport") ;
            meta.l3_metadata.lkp_l4_dport : exact @name("l3_metadata.lkp_l4_dport") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        switch (nat_twice.apply().action_run) {
            on_miss: {
                switch (nat_dst.apply().action_run) {
                    on_miss: {
                        switch (nat_src.apply().action_run) {
                            on_miss: {
                                nat_flow.apply();
                            }
                        }

                    }
                }

            }
        }

    }
}

control process_int_sink_update_outer(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control process_meter_index(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".meter_index") direct_meter<bit<2>>(MeterType.bytes) meter_index;
    @name(".nop") action nop() {
    }
    @name(".nop") action nop_1() {
        meter_index.read(meta.meter_metadata.meter_color);
    }
    @ternary(1) @name(".meter_index") table meter_index_0 {
        actions = {
            nop_1();
            @defaultonly NoAction();
        }
        key = {
            meta.meter_metadata.meter_index: exact @name("meter_metadata.meter_index") ;
        }
        size = 1024;
        meters = meter_index;
        default_action = NoAction();
    }
    apply {
        if (meta.ingress_metadata.bypass_lookups & 16w0x10 == 16w0) 
            meter_index_0.apply();
    }
}

control process_hashes(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".compute_lkp_ipv4_hash") action compute_lkp_ipv4_hash() {
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>, bit<8>, bit<16>, bit<16>>, bit<32>>(meta.hash_metadata.hash1, HashAlgorithm.crc16, 16w0, { meta.ipv4_metadata.lkp_ipv4_sa, meta.ipv4_metadata.lkp_ipv4_da, meta.l3_metadata.lkp_ip_proto, meta.l3_metadata.lkp_l4_sport, meta.l3_metadata.lkp_l4_dport }, 32w65536);
        hash<bit<16>, bit<16>, tuple<bit<48>, bit<48>, bit<32>, bit<32>, bit<8>, bit<16>, bit<16>>, bit<32>>(meta.hash_metadata.hash2, HashAlgorithm.crc16, 16w0, { meta.l2_metadata.lkp_mac_sa, meta.l2_metadata.lkp_mac_da, meta.ipv4_metadata.lkp_ipv4_sa, meta.ipv4_metadata.lkp_ipv4_da, meta.l3_metadata.lkp_ip_proto, meta.l3_metadata.lkp_l4_sport, meta.l3_metadata.lkp_l4_dport }, 32w65536);
    }
    @name(".compute_lkp_ipv6_hash") action compute_lkp_ipv6_hash() {
        hash<bit<16>, bit<16>, tuple<bit<128>, bit<128>, bit<8>, bit<16>, bit<16>>, bit<32>>(meta.hash_metadata.hash1, HashAlgorithm.crc16, 16w0, { meta.ipv6_metadata.lkp_ipv6_sa, meta.ipv6_metadata.lkp_ipv6_da, meta.l3_metadata.lkp_ip_proto, meta.l3_metadata.lkp_l4_sport, meta.l3_metadata.lkp_l4_dport }, 32w65536);
        hash<bit<16>, bit<16>, tuple<bit<48>, bit<48>, bit<128>, bit<128>, bit<8>, bit<16>, bit<16>>, bit<32>>(meta.hash_metadata.hash2, HashAlgorithm.crc16, 16w0, { meta.l2_metadata.lkp_mac_sa, meta.l2_metadata.lkp_mac_da, meta.ipv6_metadata.lkp_ipv6_sa, meta.ipv6_metadata.lkp_ipv6_da, meta.l3_metadata.lkp_ip_proto, meta.l3_metadata.lkp_l4_sport, meta.l3_metadata.lkp_l4_dport }, 32w65536);
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
    @name(".compute_ipv4_hashes") table compute_ipv4_hashes {
        actions = {
            compute_lkp_ipv4_hash();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.isValid(): exact @name("ethernet.$valid$") ;
        }
        default_action = NoAction();
    }
    @name(".compute_ipv6_hashes") table compute_ipv6_hashes {
        actions = {
            compute_lkp_ipv6_hash();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.isValid(): exact @name("ethernet.$valid$") ;
        }
        default_action = NoAction();
    }
    @name(".compute_non_ip_hashes") table compute_non_ip_hashes {
        actions = {
            compute_lkp_non_ip_hash();
            @defaultonly NoAction();
        }
        key = {
            hdr.ethernet.isValid(): exact @name("ethernet.$valid$") ;
        }
        default_action = NoAction();
    }
    @ternary(1) @name(".compute_other_hashes") table compute_other_hashes {
        actions = {
            computed_two_hashes();
            computed_one_hash();
            @defaultonly NoAction();
        }
        key = {
            meta.hash_metadata.hash1: exact @name("hash_metadata.hash1") ;
        }
        default_action = NoAction();
    }
    apply {
        if (meta.tunnel_metadata.tunnel_terminate == 1w0 && hdr.ipv4.isValid() || meta.tunnel_metadata.tunnel_terminate == 1w1 && hdr.inner_ipv4.isValid()) 
            compute_ipv4_hashes.apply();
        else 
            if (meta.tunnel_metadata.tunnel_terminate == 1w0 && hdr.ipv6.isValid() || meta.tunnel_metadata.tunnel_terminate == 1w1 && hdr.inner_ipv6.isValid()) 
                compute_ipv6_hashes.apply();
            else 
                compute_non_ip_hashes.apply();
        compute_other_hashes.apply();
    }
}

control process_meter_action(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".meter_stats") direct_counter(CounterType.packets) meter_stats;
    @name(".meter_permit") action meter_permit() {
    }
    @name(".meter_deny") action meter_deny() {
        mark_to_drop();
    }
    @name(".meter_permit") action meter_permit_0() {
        meter_stats.count();
    }
    @name(".meter_deny") action meter_deny_0() {
        meter_stats.count();
        mark_to_drop();
    }
    @name(".meter_action") table meter_action {
        actions = {
            meter_permit_0();
            meter_deny_0();
            @defaultonly NoAction();
        }
        key = {
            meta.meter_metadata.meter_color: exact @name("meter_metadata.meter_color") ;
            meta.meter_metadata.meter_index: exact @name("meter_metadata.meter_index") ;
        }
        size = 1024;
        counters = meter_stats;
        default_action = NoAction();
    }
    apply {
        if (meta.ingress_metadata.bypass_lookups & 16w0x10 == 16w0) 
            meter_action.apply();
    }
}

control process_ingress_bd_stats(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".ingress_bd_stats") @min_width(32) counter(32w1024, CounterType.packets_and_bytes) ingress_bd_stats;
    @name(".update_ingress_bd_stats") action update_ingress_bd_stats() {
        ingress_bd_stats.count((bit<32>)meta.l2_metadata.bd_stats_idx);
    }
    @name(".ingress_bd_stats") table ingress_bd_stats_0 {
        actions = {
            update_ingress_bd_stats();
            @defaultonly NoAction();
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        ingress_bd_stats_0.apply();
    }
}

control process_ingress_acl_stats(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".acl_stats") @min_width(16) counter(32w1024, CounterType.packets_and_bytes) acl_stats;
    @name(".acl_stats_update") action acl_stats_update() {
        acl_stats.count((bit<32>)meta.acl_metadata.acl_stats_index);
    }
    @name(".acl_stats") table acl_stats_0 {
        actions = {
            acl_stats_update();
            @defaultonly NoAction();
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        acl_stats_0.apply();
    }
}

control process_storm_control_stats(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".storm_control_stats") direct_counter(CounterType.packets) storm_control_stats;
    @name(".nop") action nop() {
    }
    @name(".nop") action nop_2() {
        storm_control_stats.count();
    }
    @name(".storm_control_stats") table storm_control_stats_0 {
        actions = {
            nop_2();
            @defaultonly NoAction();
        }
        key = {
            meta.meter_metadata.meter_color: exact @name("meter_metadata.meter_color") ;
            meta.ig_intr_md.ingress_port   : exact @name("ig_intr_md.ingress_port") ;
        }
        size = 1024;
        counters = storm_control_stats;
        default_action = NoAction();
    }
    apply {
        storm_control_stats_0.apply();
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
    }
    @name(".set_fib_redirect_action") action set_fib_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.l3_metadata.fib_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.l3_metadata.fib_nexthop_type;
        meta.l3_metadata.routed = 1w1;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".set_cpu_redirect_action") action set_cpu_redirect_action() {
        meta.l3_metadata.routed = 1w0;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
        meta.ig_intr_md_for_tm.ucast_egress_port = 9w64;
        meta.ingress_metadata.egress_ifindex = 16w0;
    }
    @name(".set_acl_redirect_action") action set_acl_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.acl_metadata.acl_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.acl_metadata.acl_nexthop_type;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".set_racl_redirect_action") action set_racl_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.acl_metadata.racl_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.acl_metadata.racl_nexthop_type;
        meta.l3_metadata.routed = 1w1;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".set_nat_redirect_action") action set_nat_redirect_action() {
        meta.l3_metadata.nexthop_index = meta.nat_metadata.nat_nexthop;
        meta.nexthop_metadata.nexthop_type = meta.nat_metadata.nat_nexthop_type;
        meta.l3_metadata.routed = 1w1;
        meta.ig_intr_md_for_tm.mcast_grp_b = 16w0;
    }
    @name(".set_multicast_route_action") action set_multicast_route_action() {
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.ig_intr_md_for_tm.mcast_grp_b = meta.multicast_metadata.multicast_route_mc_index;
        meta.l3_metadata.routed = 1w1;
        meta.l3_metadata.same_bd_check = 16w0xffff;
    }
    @name(".set_multicast_bridge_action") action set_multicast_bridge_action() {
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.ig_intr_md_for_tm.mcast_grp_b = meta.multicast_metadata.multicast_bridge_mc_index;
    }
    @name(".set_multicast_flood") action set_multicast_flood() {
        meta.ingress_metadata.egress_ifindex = 16w65535;
    }
    @name(".set_multicast_drop") action set_multicast_drop() {
        meta.ingress_metadata.drop_flag = 1w1;
        meta.ingress_metadata.drop_reason = 8w44;
    }
    @name(".fwd_result") table fwd_result {
        actions = {
            nop();
            set_l2_redirect_action();
            set_fib_redirect_action();
            set_cpu_redirect_action();
            set_acl_redirect_action();
            set_racl_redirect_action();
            set_nat_redirect_action();
            set_multicast_route_action();
            set_multicast_bridge_action();
            set_multicast_flood();
            set_multicast_drop();
            @defaultonly NoAction();
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
    @name(".set_ecmp_nexthop_details") action set_ecmp_nexthop_details(bit<16> ifindex, bit<16> bd, bit<16> nhop_index, bit<1> tunnel) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.l3_metadata.nexthop_index = nhop_index;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.l2_metadata.same_if_check = meta.l2_metadata.same_if_check ^ ifindex;
        meta.tunnel_metadata.tunnel_if_check = meta.tunnel_metadata.tunnel_terminate ^ tunnel;
    }
    @name(".set_ecmp_nexthop_details_for_post_routed_flood") action set_ecmp_nexthop_details_for_post_routed_flood(bit<16> bd, bit<16> uuc_mc_index, bit<16> nhop_index) {
        meta.ig_intr_md_for_tm.mcast_grp_b = uuc_mc_index;
        meta.l3_metadata.nexthop_index = nhop_index;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
    }
    @name(".set_nexthop_details") action set_nexthop_details(bit<16> ifindex, bit<16> bd, bit<1> tunnel) {
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
        meta.l2_metadata.same_if_check = meta.l2_metadata.same_if_check ^ ifindex;
        meta.tunnel_metadata.tunnel_if_check = meta.tunnel_metadata.tunnel_terminate ^ tunnel;
    }
    @name(".set_nexthop_details_for_post_routed_flood") action set_nexthop_details_for_post_routed_flood(bit<16> bd, bit<16> uuc_mc_index) {
        meta.ig_intr_md_for_tm.mcast_grp_b = uuc_mc_index;
        meta.ingress_metadata.egress_ifindex = 16w0;
        meta.l3_metadata.same_bd_check = meta.ingress_metadata.bd ^ bd;
    }
    @name(".ecmp_group") table ecmp_group {
        actions = {
            nop();
            set_ecmp_nexthop_details();
            set_ecmp_nexthop_details_for_post_routed_flood();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.nexthop_index: exact @name("l3_metadata.nexthop_index") ;
            meta.hash_metadata.hash1      : selector @name("hash_metadata.hash1") ;
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
            meta.l3_metadata.nexthop_index: exact @name("l3_metadata.nexthop_index") ;
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

control process_multicast_flooding(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_bd_flood_mc_index") action set_bd_flood_mc_index(bit<16> mc_index) {
        meta.ig_intr_md_for_tm.mcast_grp_b = mc_index;
    }
    @name(".bd_flood") table bd_flood {
        actions = {
            nop();
            set_bd_flood_mc_index();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.bd     : exact @name("ingress_metadata.bd") ;
            meta.l2_metadata.lkp_pkt_type: exact @name("l2_metadata.lkp_pkt_type") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        bd_flood.apply();
    }
}

control process_lag(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_lag_miss") action set_lag_miss() {
    }
    @name(".set_lag_port") action set_lag_port(bit<9> port) {
        meta.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".lag_group") table lag_group {
        actions = {
            set_lag_miss();
            set_lag_port();
            @defaultonly NoAction();
        }
        key = {
            meta.ingress_metadata.egress_ifindex: exact @name("ingress_metadata.egress_ifindex") ;
            meta.hash_metadata.hash2            : selector @name("hash_metadata.hash2") ;
        }
        size = 1024;
        implementation = lag_action_profile;
        default_action = NoAction();
    }
    apply {
        lag_group.apply();
    }
}

@name("mac_learn_digest") struct mac_learn_digest {
    bit<16> bd;
    bit<48> lkp_mac_sa;
    bit<16> ifindex;
}

control process_mac_learning(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".generate_learn_notify") action generate_learn_notify() {
        digest<mac_learn_digest>(32w0, {meta.ingress_metadata.bd,meta.l2_metadata.lkp_mac_sa,meta.ingress_metadata.ifindex});
    }
    @name(".learn_notify") table learn_notify {
        actions = {
            nop();
            generate_learn_notify();
            @defaultonly NoAction();
        }
        key = {
            meta.l2_metadata.l2_src_miss: ternary @name("l2_metadata.l2_src_miss") ;
            meta.l2_metadata.l2_src_move: ternary @name("l2_metadata.l2_src_move") ;
            meta.l2_metadata.stp_state  : ternary @name("l2_metadata.stp_state") ;
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
    apply {
    }
}

control process_system_acl(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".drop_stats") counter(32w1024, CounterType.packets) drop_stats;
    @name(".drop_stats_2") counter(32w1024, CounterType.packets) drop_stats_2;
    @name(".drop_stats_update") action drop_stats_update() {
        drop_stats_2.count((bit<32>)meta.ingress_metadata.drop_reason);
    }
    @name(".nop") action nop() {
    }
    @name(".copy_to_cpu") action copy_to_cpu() {
    }
    @name(".copy_to_cpu_with_reason") action copy_to_cpu_with_reason(bit<16> reason_code) {
        meta.fabric_metadata.reason_code = reason_code;
        copy_to_cpu();
    }
    @name(".redirect_to_cpu") action redirect_to_cpu(bit<16> reason_code) {
        copy_to_cpu_with_reason(reason_code);
        mark_to_drop();
    }
    @name(".drop_packet") action drop_packet() {
        mark_to_drop();
    }
    @name(".drop_packet_with_reason") action drop_packet_with_reason(bit<32> drop_reason) {
        drop_stats.count(drop_reason);
        mark_to_drop();
    }
    @name(".negative_mirror") action negative_mirror(bit<32> session_id) {
        clone3<tuple<bit<16>, bit<8>>>(CloneType.I2E, session_id, { meta.ingress_metadata.ifindex, meta.ingress_metadata.drop_reason });
        mark_to_drop();
    }
    @name(".drop_stats") table drop_stats_0 {
        actions = {
            drop_stats_update();
            @defaultonly NoAction();
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".system_acl") table system_acl {
        actions = {
            nop();
            redirect_to_cpu();
            copy_to_cpu_with_reason();
            copy_to_cpu();
            drop_packet();
            drop_packet_with_reason();
            negative_mirror();
            @defaultonly NoAction();
        }
        key = {
            meta.acl_metadata.if_label                : ternary @name("acl_metadata.if_label") ;
            meta.acl_metadata.bd_label                : ternary @name("acl_metadata.bd_label") ;
            meta.l2_metadata.lkp_mac_sa               : ternary @name("l2_metadata.lkp_mac_sa") ;
            meta.l2_metadata.lkp_mac_da               : ternary @name("l2_metadata.lkp_mac_da") ;
            meta.l2_metadata.lkp_mac_type             : ternary @name("l2_metadata.lkp_mac_type") ;
            meta.ingress_metadata.ifindex             : ternary @name("ingress_metadata.ifindex") ;
            meta.l2_metadata.port_vlan_mapping_miss   : ternary @name("l2_metadata.port_vlan_mapping_miss") ;
            meta.security_metadata.ipsg_check_fail    : ternary @name("security_metadata.ipsg_check_fail") ;
            meta.security_metadata.storm_control_color: ternary @name("security_metadata.storm_control_color") ;
            meta.acl_metadata.acl_deny                : ternary @name("acl_metadata.acl_deny") ;
            meta.acl_metadata.racl_deny               : ternary @name("acl_metadata.racl_deny") ;
            meta.l3_metadata.urpf_check_fail          : ternary @name("l3_metadata.urpf_check_fail") ;
            meta.ingress_metadata.drop_flag           : ternary @name("ingress_metadata.drop_flag") ;
            meta.acl_metadata.acl_copy                : ternary @name("acl_metadata.acl_copy") ;
            meta.l3_metadata.l3_copy                  : ternary @name("l3_metadata.l3_copy") ;
            meta.l3_metadata.rmac_hit                 : ternary @name("l3_metadata.rmac_hit") ;
            meta.l3_metadata.routed                   : ternary @name("l3_metadata.routed") ;
            meta.ipv6_metadata.ipv6_src_is_link_local : ternary @name("ipv6_metadata.ipv6_src_is_link_local") ;
            meta.l2_metadata.same_if_check            : ternary @name("l2_metadata.same_if_check") ;
            meta.tunnel_metadata.tunnel_if_check      : ternary @name("tunnel_metadata.tunnel_if_check") ;
            meta.l3_metadata.same_bd_check            : ternary @name("l3_metadata.same_bd_check") ;
            meta.l3_metadata.lkp_ip_ttl               : ternary @name("l3_metadata.lkp_ip_ttl") ;
            meta.l2_metadata.stp_state                : ternary @name("l2_metadata.stp_state") ;
            meta.ingress_metadata.control_frame       : ternary @name("ingress_metadata.control_frame") ;
            meta.ipv4_metadata.ipv4_unicast_enabled   : ternary @name("ipv4_metadata.ipv4_unicast_enabled") ;
            meta.ipv6_metadata.ipv6_unicast_enabled   : ternary @name("ipv6_metadata.ipv6_unicast_enabled") ;
            meta.ingress_metadata.egress_ifindex      : ternary @name("ingress_metadata.egress_ifindex") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (meta.ingress_metadata.bypass_lookups & 16w0x20 == 16w0) {
            system_acl.apply();
            if (meta.ingress_metadata.drop_flag == 1w1) 
                drop_stats_0.apply();
        }
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".rmac_hit") action rmac_hit() {
        meta.l3_metadata.rmac_hit = 1w1;
    }
    @name(".rmac_miss") action rmac_miss() {
        meta.l3_metadata.rmac_hit = 1w0;
    }
    @ternary(1) @name(".rmac") table rmac {
        actions = {
            rmac_hit();
            rmac_miss();
            @defaultonly NoAction();
        }
        key = {
            meta.l3_metadata.rmac_group: exact @name("l3_metadata.rmac_group") ;
            meta.l2_metadata.lkp_mac_da: exact @name("l2_metadata.lkp_mac_da") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".process_ingress_port_mapping") process_ingress_port_mapping() process_ingress_port_mapping_0;
    @name(".process_validate_outer_header") process_validate_outer_header() process_validate_outer_header_0;
    @name(".process_global_params") process_global_params() process_global_params_0;
    @name(".process_int_endpoint") process_int_endpoint() process_int_endpoint_0;
    @name(".process_port_vlan_mapping") process_port_vlan_mapping() process_port_vlan_mapping_0;
    @name(".process_spanning_tree") process_spanning_tree() process_spanning_tree_0;
    @name(".process_ip_sourceguard") process_ip_sourceguard() process_ip_sourceguard_0;
    @name(".process_ingress_sflow") process_ingress_sflow() process_ingress_sflow_0;
    @name(".process_tunnel") process_tunnel() process_tunnel_0;
    @name(".process_storm_control") process_storm_control() process_storm_control_0;
    @name(".process_validate_packet") process_validate_packet() process_validate_packet_0;
    @name(".process_mac") process_mac() process_mac_0;
    @name(".process_mac_acl") process_mac_acl() process_mac_acl_0;
    @name(".process_ip_acl") process_ip_acl() process_ip_acl_0;
    @name(".process_int_upstream_report") process_int_upstream_report() process_int_upstream_report_0;
    @name(".process_qos") process_qos() process_qos_0;
    @name(".process_multicast") process_multicast() process_multicast_0;
    @name(".process_ipv4_racl") process_ipv4_racl() process_ipv4_racl_0;
    @name(".process_ipv4_urpf") process_ipv4_urpf() process_ipv4_urpf_0;
    @name(".process_ipv4_fib") process_ipv4_fib() process_ipv4_fib_0;
    @name(".process_ipv6_racl") process_ipv6_racl() process_ipv6_racl_0;
    @name(".process_ipv6_urpf") process_ipv6_urpf() process_ipv6_urpf_0;
    @name(".process_ipv6_fib") process_ipv6_fib() process_ipv6_fib_0;
    @name(".process_urpf_bd") process_urpf_bd() process_urpf_bd_0;
    @name(".process_ingress_nat") process_ingress_nat() process_ingress_nat_0;
    @name(".process_int_sink_update_outer") process_int_sink_update_outer() process_int_sink_update_outer_0;
    @name(".process_meter_index") process_meter_index() process_meter_index_0;
    @name(".process_hashes") process_hashes() process_hashes_0;
    @name(".process_meter_action") process_meter_action() process_meter_action_0;
    @name(".process_ingress_bd_stats") process_ingress_bd_stats() process_ingress_bd_stats_0;
    @name(".process_ingress_acl_stats") process_ingress_acl_stats() process_ingress_acl_stats_0;
    @name(".process_storm_control_stats") process_storm_control_stats() process_storm_control_stats_0;
    @name(".process_fwd_results") process_fwd_results() process_fwd_results_0;
    @name(".process_nexthop") process_nexthop() process_nexthop_0;
    @name(".process_multicast_flooding") process_multicast_flooding() process_multicast_flooding_0;
    @name(".process_lag") process_lag() process_lag_0;
    @name(".process_mac_learning") process_mac_learning() process_mac_learning_0;
    @name(".process_fabric_lag") process_fabric_lag() process_fabric_lag_0;
    @name(".process_system_acl") process_system_acl() process_system_acl_0;
    apply {
        process_ingress_port_mapping_0.apply(hdr, meta, standard_metadata);
        process_validate_outer_header_0.apply(hdr, meta, standard_metadata);
        process_global_params_0.apply(hdr, meta, standard_metadata);
        process_int_endpoint_0.apply(hdr, meta, standard_metadata);
        process_port_vlan_mapping_0.apply(hdr, meta, standard_metadata);
        process_spanning_tree_0.apply(hdr, meta, standard_metadata);
        process_ip_sourceguard_0.apply(hdr, meta, standard_metadata);
        process_ingress_sflow_0.apply(hdr, meta, standard_metadata);
        process_tunnel_0.apply(hdr, meta, standard_metadata);
        process_storm_control_0.apply(hdr, meta, standard_metadata);
        if (meta.ingress_metadata.port_type != 2w1) 
            if (!(hdr.mpls[0].isValid() && meta.l3_metadata.fib_hit == 1w1)) {
                process_validate_packet_0.apply(hdr, meta, standard_metadata);
                process_mac_0.apply(hdr, meta, standard_metadata);
                if (meta.l3_metadata.lkp_ip_type == 2w0) 
                    process_mac_acl_0.apply(hdr, meta, standard_metadata);
                else 
                    process_ip_acl_0.apply(hdr, meta, standard_metadata);
                process_int_upstream_report_0.apply(hdr, meta, standard_metadata);
                process_qos_0.apply(hdr, meta, standard_metadata);
                switch (rmac.apply().action_run) {
                    rmac_miss: {
                        process_multicast_0.apply(hdr, meta, standard_metadata);
                    }
                    default: {
                        if (meta.ingress_metadata.bypass_lookups & 16w0x2 == 16w0) {
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
            if (meta.ingress_metadata.egress_ifindex == 16w65535) 
                process_multicast_flooding_0.apply(hdr, meta, standard_metadata);
            else 
                process_lag_0.apply(hdr, meta, standard_metadata);
            process_mac_learning_0.apply(hdr, meta, standard_metadata);
        }
        process_fabric_lag_0.apply(hdr, meta, standard_metadata);
        if (meta.ingress_metadata.port_type != 2w1) 
            process_system_acl_0.apply(hdr, meta, standard_metadata);
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
