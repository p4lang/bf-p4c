#include <core.p4>
#include <v1model.p4>

struct egress_metadata_t {
    bit<16> ifindex;
    bit<16> payload_length;
}

struct ingress_metadata_t {
    bit<16> ifindex;
    bit<16> egress_ifindex;
    bit<4>  bypass;
}

struct l2_metadata_t {
    bit<48> mac_sa;
    bit<48> mac_da;
    bit<16> bd;
}

struct l3_metadata_t {
    bit<4>   version;
    bit<8>   proto;
    bit<16>  l4_sport;
    bit<16>  l4_dport;
    bit<32>  ipv4_da;
    bit<32>  ipv4_sa;
    bit<128> ipv6_da;
    bit<128> ipv6_sa;
    bit<16>  flow_label;
    bit<16>  vrf;
    bit<16>  nexthop;
    bit<16>  hash;
}

struct sr_metadata_t {
    bit<128> sid;
    bit<8>   proto;
    bit<4>   action_;
}

struct tunnel_metadata_t {
    bit<16> index;
}

header arp_t {
    bit<16> hwType;
    bit<16> protoType;
    bit<8>  hwAddrLen;
    bit<8>  protoAddrLen;
    bit<16> opcode;
    bit<48> hwSrcAddr;
    bit<32> protoSrcAddr;
    bit<48> hwDstAddr;
    bit<32> protoDstAddr;
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

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header icmp_t {
    bit<8>  icmpType;
    bit<8>  code;
    bit<16> checksum;
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

header ipv6_srh_t {
    bit<8>  nextHdr;
    bit<8>  hdrExtLen;
    bit<8>  routingType;
    bit<8>  segLeft;
    bit<8>  firstSeg;
    bit<8>  flags;
    bit<16> reserved;
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

header ipv6_srh_segment_t {
    bit<128> sid;
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
    @name(".egress_metadata") 
    egress_metadata_t  egress_metadata;
    @name(".ingress_metadata") 
    ingress_metadata_t ingress_metadata;
    @name(".l2_metadata") 
    l2_metadata_t      l2_metadata;
    @name(".l3_metadata") 
    l3_metadata_t      l3_metadata;
    @name(".sr_metadata") 
    sr_metadata_t      sr_metadata;
    @name(".tunnel_metadata") 
    tunnel_metadata_t  tunnel_metadata;
}

struct headers {
    @name(".arp") 
    arp_t                                          arp;
    @dont_trim @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md") @pa_atomic("egress", "eg_intr_md.egress_port") @pa_fragment("egress", "eg_intr_md._pad1") @pa_fragment("egress", "eg_intr_md._pad7") @pa_fragment("egress", "eg_intr_md._pad8") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_port") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_cos") @name(".eg_intr_md") 
    egress_intrinsic_metadata_t                    eg_intr_md;
    @dont_trim @pa_intrinsic_header("egress", "eg_intr_md_for_mb") @pa_atomic("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_fragment("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_length") @not_deparsed("ingress") @not_deparsed("egress") @name(".eg_intr_md_for_mb") 
    egress_intrinsic_metadata_for_mirror_buffer_t  eg_intr_md_for_mb;
    @dont_trim @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_oport.drop_ctl") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_for_oport") @name(".eg_intr_md_for_oport") 
    egress_intrinsic_metadata_for_output_port_t    eg_intr_md_for_oport;
    @pa_fragment("egress", "eg_intr_md_from_parser_aux.coalesce_sample_count") @pa_fragment("egress", "eg_intr_md_from_parser_aux.clone_src") @pa_fragment("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @pa_atomic("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_from_parser_aux") @name(".eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t    eg_intr_md_from_parser_aux;
    @name(".ethernet") 
    ethernet_t                                     ethernet;
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
    @pa_alias("egress", "inner_icmp", "icmp") @name(".inner_icmp") 
    icmp_t                                         inner_icmp;
    @name(".inner_ipv4") 
    ipv4_t                                         inner_ipv4;
    @name(".inner_ipv6") 
    ipv6_t                                         inner_ipv6;
    @name(".inner_ipv6_srh") 
    ipv6_srh_t                                     inner_ipv6_srh;
    @pa_alias("egress", "inner_tcp", "tcp") @name(".inner_tcp") 
    tcp_t                                          inner_tcp;
    @pa_alias("egress", "inner_udp", "udp") @name(".inner_udp") 
    udp_t                                          inner_udp;
    @name(".ipv4") 
    ipv4_t                                         ipv4;
    @name(".ipv6") 
    ipv6_t                                         ipv6;
    @name(".ipv6_srh") 
    ipv6_srh_t                                     ipv6_srh;
    @name(".tcp") 
    tcp_t                                          tcp;
    @name(".udp") 
    udp_t                                          udp;
    @name(".inner_ipv6_srh_seg_list") 
    ipv6_srh_segment_t[5]                          inner_ipv6_srh_seg_list;
    @name(".ipv6_srh_seg_list") 
    ipv6_srh_segment_t[5]                          ipv6_srh_seg_list;
    @name(".mpls") 
    mpls_t[16]                                     mpls;
    @name(".vlan_tag") 
    vlan_tag_t[2]                                  vlan_tag;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".extract_srh_active_segment_0") state extract_srh_active_segment_0 {
        packet.extract<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[0]);
        transition parse_srh_next_hdr;
    }
    @name(".extract_srh_active_segment_1") state extract_srh_active_segment_1 {
        packet.extract<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[1]);
        meta.sr_metadata.sid = hdr.ipv6_srh_seg_list[1].sid;
        transition parse_ipv6_srh_segment_after_sid_0;
    }
    @name(".extract_srh_active_segment_2") state extract_srh_active_segment_2 {
        packet.extract<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[2]);
        meta.sr_metadata.sid = hdr.ipv6_srh_seg_list[2].sid;
        transition parse_ipv6_srh_segment_after_sid_1;
    }
    @name(".extract_srh_active_segment_3") state extract_srh_active_segment_3 {
        packet.extract<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[3]);
        meta.sr_metadata.sid = hdr.ipv6_srh_seg_list[3].sid;
        transition parse_ipv6_srh_segment_after_sid_2;
    }
    @name(".parse_arp") state parse_arp {
        packet.extract<arp_t>(hdr.arp);
        transition accept;
    }
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x8100: parse_vlan;
            16w0x806: parse_arp;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            default: accept;
        }
    }
    @name(".parse_icmp") state parse_icmp {
        packet.extract<icmp_t>(hdr.icmp);
        transition accept;
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
        transition accept;
    }
    @name(".parse_inner_ipv4") state parse_inner_ipv4 {
        packet.extract<ipv4_t>(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.protocol) {
            (13w0, 8w1): parse_inner_icmp;
            (13w0, 8w6): parse_inner_tcp;
            (13w0, 8w17): parse_inner_udp;
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
    @name(".parse_inner_srh") state parse_inner_srh {
        packet.extract<ipv6_srh_t>(hdr.inner_ipv6_srh);
        hdr.ig_prsr_ctrl.parser_counter = hdr.inner_ipv6_srh.firstSeg;
        transition select(hdr.inner_ipv6_srh.firstSeg) {
            8w0x0: accept;
            default: parse_inner_srh_seg_list;
        }
    }
    @name(".parse_inner_srh_seg_list") state parse_inner_srh_seg_list {
        packet.extract<ipv6_srh_segment_t>(hdr.inner_ipv6_srh_seg_list.next);
        transition select(hdr.ig_prsr_ctrl.parser_counter) {
            8w0x0: accept;
            default: parse_inner_srh_seg_list;
        }
    }
    @name(".parse_inner_tcp") state parse_inner_tcp {
        packet.extract<tcp_t>(hdr.inner_tcp);
        transition accept;
    }
    @name(".parse_inner_udp") state parse_inner_udp {
        packet.extract<udp_t>(hdr.inner_udp);
        transition accept;
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w1): parse_icmp;
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name(".parse_ipv6") state parse_ipv6 {
        packet.extract<ipv6_t>(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            8w58: parse_icmp;
            8w6: parse_tcp;
            8w17: parse_udp;
            8w43: parse_ipv6_srh;
            default: accept;
        }
    }
    @name(".parse_ipv6_srh") state parse_ipv6_srh {
        packet.extract<ipv6_srh_t>(hdr.ipv6_srh);
        transition select(hdr.ipv6_srh.firstSeg) {
            8w0: accept;
            8w1: parse_ipv6_srh_segment_before_sid_1;
            8w2: parse_ipv6_srh_segment_before_sid_2;
            8w3: parse_ipv6_srh_segment_before_sid_3;
            8w4: parse_ipv6_srh_segment_before_sid_4;
        }
    }
    @name(".parse_ipv6_srh_segment_after_sid_0") state parse_ipv6_srh_segment_after_sid_0 {
        packet.extract<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[0]);
        transition parse_srh_next_hdr;
    }
    @name(".parse_ipv6_srh_segment_after_sid_1") state parse_ipv6_srh_segment_after_sid_1 {
        packet.extract<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[1]);
        transition parse_ipv6_srh_segment_after_sid_0;
    }
    @name(".parse_ipv6_srh_segment_after_sid_2") state parse_ipv6_srh_segment_after_sid_2 {
        packet.extract<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[2]);
        transition parse_ipv6_srh_segment_after_sid_1;
    }
    @name(".parse_ipv6_srh_segment_before_sid_0") state parse_ipv6_srh_segment_before_sid_0 {
        packet.extract<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[0]);
        transition parse_srh_next_hdr;
    }
    @name(".parse_ipv6_srh_segment_before_sid_1") state parse_ipv6_srh_segment_before_sid_1 {
        packet.extract<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[1]);
        transition select(hdr.ipv6_srh.segLeft) {
            8w1: extract_srh_active_segment_0;
            default: parse_ipv6_srh_segment_before_sid_0;
        }
    }
    @name(".parse_ipv6_srh_segment_before_sid_2") state parse_ipv6_srh_segment_before_sid_2 {
        packet.extract<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[2]);
        transition select(hdr.ipv6_srh.segLeft) {
            8w2: extract_srh_active_segment_1;
            default: parse_ipv6_srh_segment_before_sid_1;
        }
    }
    @name(".parse_ipv6_srh_segment_before_sid_3") state parse_ipv6_srh_segment_before_sid_3 {
        packet.extract<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[3]);
        transition select(hdr.ipv6_srh.segLeft) {
            8w3: extract_srh_active_segment_2;
            default: parse_ipv6_srh_segment_before_sid_2;
        }
    }
    @name(".parse_ipv6_srh_segment_before_sid_4") state parse_ipv6_srh_segment_before_sid_4 {
        packet.extract<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[4]);
        transition select(hdr.ipv6_srh.segLeft) {
            8w4: extract_srh_active_segment_3;
            default: parse_ipv6_srh_segment_before_sid_3;
        }
    }
    @name(".parse_srh_next_hdr") state parse_srh_next_hdr {
        transition select(hdr.ipv6_srh.nextHdr) {
            8w41: parse_inner_ipv6;
            8w4: parse_inner_ipv4;
            8w97: parse_inner_ethernet;
            8w43: parse_inner_srh;
            default: accept;
        }
    }
    @name(".parse_tcp") state parse_tcp {
        packet.extract<tcp_t>(hdr.tcp);
        transition accept;
    }
    @name(".parse_udp") state parse_udp {
        packet.extract<udp_t>(hdr.udp);
        transition select(hdr.udp.dstPort) {
            default: accept;
        }
    }
    @name(".parse_vlan") state parse_vlan {
        packet.extract<vlan_tag_t>(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.etherType) {
            16w0x8100: parse_vlan;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            default: accept;
        }
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

@name(".l3_action_profile") @mode("fair") action_selector(HashAlgorithm.identity, 32w0, 32w14) l3_action_profile;

@name(".lag_action_profile") @mode("fair") action_selector(HashAlgorithm.crc16, 32w0, 32w14) lag_action_profile;

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_1() {
    }
    @name(".NoAction") action NoAction_26() {
    }
    @name(".NoAction") action NoAction_27() {
    }
    @name(".NoAction") action NoAction_28() {
    }
    @name(".NoAction") action NoAction_29() {
    }
    @name(".NoAction") action NoAction_30() {
    }
    @name(".NoAction") action NoAction_31() {
    }
    @name(".NoAction") action NoAction_32() {
    }
    @name(".set_egress_ifindex") action set_egress_ifindex(bit<16> ifindex) {
        meta.egress_metadata.ifindex = ifindex;
    }
    @name(".set_egress_packet_vlan_untagged") action set_egress_packet_vlan_untagged() {
    }
    @name(".set_egress_packet_vlan_tagged") action set_egress_packet_vlan_tagged(bit<12> vlan_id) {
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].etherType = hdr.ethernet.etherType;
        hdr.vlan_tag[0].vid = vlan_id;
        hdr.ethernet.etherType = 16w0x8100;
    }
    @name(".set_egress_packet_vlan_double_tagged") action set_egress_packet_vlan_double_tagged(bit<12> s_tag, bit<12> c_tag) {
        hdr.vlan_tag[1].setValid();
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[1].etherType = hdr.ethernet.etherType;
        hdr.vlan_tag[1].vid = c_tag;
        hdr.vlan_tag[0].etherType = 16w0x8100;
        hdr.vlan_tag[0].vid = s_tag;
        hdr.ethernet.etherType = 16w0x9100;
    }
    @name(".remove_vlan_single_tagged") action remove_vlan_single_tagged() {
        hdr.ethernet.etherType = hdr.vlan_tag[0].etherType;
        hdr.vlan_tag[0].setInvalid();
    }
    @name(".remove_vlan_double_tagged") action remove_vlan_double_tagged() {
        hdr.ethernet.etherType = hdr.vlan_tag[1].etherType;
        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
    }
    @name(".egress_port_mapping") table egress_port_mapping_0 {
        actions = {
            set_egress_ifindex();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        default_action = NoAction_0();
    }
    @name(".egress_vlan_xlate") table egress_vlan_xlate_0 {
        actions = {
            set_egress_packet_vlan_untagged();
            set_egress_packet_vlan_tagged();
            set_egress_packet_vlan_double_tagged();
            @defaultonly NoAction_1();
        }
        key = {
            meta.egress_metadata.ifindex: exact @name("egress_metadata.ifindex") ;
            meta.l2_metadata.bd         : exact @name("l2_metadata.bd") ;
        }
        default_action = NoAction_1();
    }
    @name(".vlan_decap") table vlan_decap_0 {
        actions = {
            remove_vlan_single_tagged();
            remove_vlan_double_tagged();
            @defaultonly NoAction_26();
        }
        key = {
            hdr.vlan_tag[0].isValid(): ternary @name("vlan_tag[0].$valid$") ;
            hdr.vlan_tag[1].isValid(): ternary @name("vlan_tag[1].$valid$") ;
        }
        default_action = NoAction_26();
    }
    @name(".pop_ipv6_srh") action _pop_ipv6_srh_0() {
        hdr.ipv6_srh.setInvalid();
        hdr.ipv6_srh_seg_list[0].setInvalid();
        hdr.ipv6_srh_seg_list[1].setInvalid();
        hdr.ipv6_srh_seg_list[2].setInvalid();
        hdr.ipv6_srh_seg_list[3].setInvalid();
        hdr.ipv6_srh_seg_list[4].setInvalid();
    }
    @name(".decap_inner_non_ip") action _decap_inner_non_ip_0() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.inner_ethernet.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.ipv6_srh.setInvalid();
        hdr.ipv6_srh_seg_list[0].setInvalid();
        hdr.ipv6_srh_seg_list[1].setInvalid();
        hdr.ipv6_srh_seg_list[2].setInvalid();
        hdr.ipv6_srh_seg_list[3].setInvalid();
        hdr.ipv6_srh_seg_list[4].setInvalid();
    }
    @name(".decap_inner_ipv4") action _decap_inner_ipv4_0() {
        hdr.ethernet.etherType = 16w0x800;
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.inner_ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.ipv6_srh.setInvalid();
        hdr.ipv6_srh_seg_list[0].setInvalid();
        hdr.ipv6_srh_seg_list[1].setInvalid();
        hdr.ipv6_srh_seg_list[2].setInvalid();
        hdr.ipv6_srh_seg_list[3].setInvalid();
        hdr.ipv6_srh_seg_list[4].setInvalid();
    }
    @name(".decap_inner_ipv6") action _decap_inner_ipv6_0() {
        hdr.ethernet.etherType = 16w0x86dd;
        hdr.ipv6 = hdr.inner_ipv6;
        hdr.inner_ipv6.setInvalid();
        hdr.ipv6_srh.setInvalid();
        hdr.ipv6_srh_seg_list[0].setInvalid();
        hdr.ipv6_srh_seg_list[1].setInvalid();
        hdr.ipv6_srh_seg_list[2].setInvalid();
        hdr.ipv6_srh_seg_list[3].setInvalid();
        hdr.ipv6_srh_seg_list[4].setInvalid();
    }
    @name(".srv6_decap") table _srv6_decap {
        actions = {
            _decap_inner_non_ip_0();
            _decap_inner_ipv4_0();
            _decap_inner_ipv6_0();
            _pop_ipv6_srh_0();
            @defaultonly NoAction_27();
        }
        key = {
            meta.sr_metadata.action_: exact @name("sr_metadata.action_") ;
            hdr.inner_ipv4.isValid(): exact @name("inner_ipv4.$valid$") ;
            hdr.inner_ipv6.isValid(): exact @name("inner_ipv6.$valid$") ;
        }
        default_action = NoAction_27();
    }
    @name(".smac_rewrite") action _smac_rewrite_0(bit<48> smac) {
        hdr.ethernet.srcAddr = smac;
    }
    @name(".ipv4_rewrite") action _ipv4_rewrite_0() {
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
    }
    @name(".ipv6_rewrite") action _ipv6_rewrite_0() {
        hdr.ipv6.hopLimit = hdr.ipv6.hopLimit + 8w255;
    }
    @name(".l2_rewrite") table _l2_rewrite {
        actions = {
            _smac_rewrite_0();
            @defaultonly NoAction_28();
        }
        key = {
            meta.l2_metadata.bd: exact @name("l2_metadata.bd") ;
        }
        default_action = NoAction_28();
    }
    @name(".l3_rewrite") table _l3_rewrite {
        actions = {
            _ipv4_rewrite_0();
            _ipv6_rewrite_0();
            @defaultonly NoAction_29();
        }
        key = {
            hdr.ipv4.isValid(): exact @name("ipv4.$valid$") ;
            hdr.ipv6.isValid(): exact @name("ipv6.$valid$") ;
        }
        default_action = NoAction_29();
    }
    @name(".srv6_rewrite_1") action _srv6_rewrite_3() {
        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w0x6;
        hdr.ipv6.nextHdr = 8w43;
        hdr.ipv6.hopLimit = 8w64;
        hdr.ipv6_srh.setValid();
        hdr.ipv6_srh.nextHdr = meta.sr_metadata.proto;
        hdr.ipv6_srh.routingType = 8w0x4;
        hdr.ipv6_srh_seg_list.push_front(1);
        hdr.ipv6_srh_seg_list[0].setValid();
        hdr.ethernet.etherType = 16w0x86dd;
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w24;
    }
    @name(".srv6_rewrite_2") action _srv6_rewrite_4() {
        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w0x6;
        hdr.ipv6.nextHdr = 8w43;
        hdr.ipv6.hopLimit = 8w64;
        hdr.ipv6_srh.setValid();
        hdr.ipv6_srh.nextHdr = meta.sr_metadata.proto;
        hdr.ipv6_srh.routingType = 8w0x4;
        hdr.ipv6_srh_seg_list.push_front(2);
        hdr.ipv6_srh_seg_list[0].setValid();
        hdr.ipv6_srh_seg_list[1].setValid();
        hdr.ethernet.etherType = 16w0x86dd;
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w40;
    }
    @name(".srv6_rewrite_3") action _srv6_rewrite_5() {
        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w0x6;
        hdr.ipv6.nextHdr = 8w43;
        hdr.ipv6.hopLimit = 8w64;
        hdr.ipv6_srh.setValid();
        hdr.ipv6_srh.nextHdr = meta.sr_metadata.proto;
        hdr.ipv6_srh.routingType = 8w0x4;
        hdr.ipv6_srh_seg_list.push_front(3);
        hdr.ipv6_srh_seg_list[0].setValid();
        hdr.ipv6_srh_seg_list[1].setValid();
        hdr.ipv6_srh_seg_list[2].setValid();
        hdr.ethernet.etherType = 16w0x86dd;
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w56;
    }
    @name(".srv6_rewrite_4") action _srv6_rewrite_6() {
        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w0x6;
        hdr.ipv6.nextHdr = 8w43;
        hdr.ipv6.hopLimit = 8w64;
        hdr.ipv6_srh.setValid();
        hdr.ipv6_srh.nextHdr = meta.sr_metadata.proto;
        hdr.ipv6_srh.routingType = 8w0x4;
        hdr.ipv6_srh_seg_list.push_front(4);
        hdr.ipv6_srh_seg_list[0].setValid();
        hdr.ipv6_srh_seg_list[1].setValid();
        hdr.ipv6_srh_seg_list[2].setValid();
        hdr.ipv6_srh_seg_list[3].setValid();
        hdr.ethernet.etherType = 16w0x86dd;
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length + 16w72;
    }
    @name(".set_srv6_seg_list_rewrite") action _set_srv6_seg_list_rewrite_0(bit<8> srh_len, bit<8> seg_left, bit<128> sid0, bit<128> sid1, bit<128> sid2) {
        hdr.ipv6_srh.hdrExtLen = srh_len;
        hdr.ipv6_srh.segLeft = seg_left;
        hdr.ipv6_srh.firstSeg = seg_left;
        hdr.ipv6_srh_seg_list[0].sid = sid0;
        hdr.ipv6_srh_seg_list[1].sid = sid1;
        hdr.ipv6_srh_seg_list[2].sid = sid2;
    }
    @name(".inner_ipv4_rewrite") action _inner_ipv4_rewrite_0() {
        hdr.inner_ipv4 = hdr.ipv4;
        hdr.ipv4.setInvalid();
        meta.egress_metadata.payload_length = hdr.ipv4.totalLen;
    }
    @name(".inner_ipv6_rewrite") action _inner_ipv6_rewrite_0() {
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.ipv6.setInvalid();
        meta.egress_metadata.payload_length = hdr.ipv6.payloadLen + 16w40;
    }
    @name(".inner_non_ip_rewrite") action _inner_non_ip_rewrite_0() {
        hdr.inner_ethernet = hdr.ethernet;
        meta.egress_metadata.payload_length = hdr.eg_intr_md.pkt_length + 16w65522;
    }
    @name(".srv6_encap") table _srv6_encap {
        actions = {
            _srv6_rewrite_3();
            _srv6_rewrite_4();
            _srv6_rewrite_5();
            _srv6_rewrite_6();
            @defaultonly NoAction_30();
        }
        key = {
            meta.tunnel_metadata.index: exact @name("tunnel_metadata.index") ;
        }
        default_action = NoAction_30();
    }
    @name(".srv6_rewrite") table _srv6_rewrite_7 {
        actions = {
            _set_srv6_seg_list_rewrite_0();
            @defaultonly NoAction_31();
        }
        key = {
            meta.tunnel_metadata.index: exact @name("tunnel_metadata.index") ;
        }
        default_action = NoAction_31();
    }
    @name(".tunnel_encap_process_inner") table _tunnel_encap_process_inner {
        actions = {
            _inner_ipv4_rewrite_0();
            _inner_ipv6_rewrite_0();
            _inner_non_ip_rewrite_0();
            @defaultonly NoAction_32();
        }
        key = {
            hdr.ipv4.isValid(): exact @name("ipv4.$valid$") ;
            hdr.ipv6.isValid(): exact @name("ipv6.$valid$") ;
        }
        default_action = NoAction_32();
    }
    apply {
        egress_port_mapping_0.apply();
        vlan_decap_0.apply();
        _srv6_decap.apply();
        _l2_rewrite.apply();
        _l3_rewrite.apply();
        _tunnel_encap_process_inner.apply();
        _srv6_encap.apply();
        _srv6_rewrite_7.apply();
        egress_vlan_xlate_0.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_33() {
    }
    @name(".NoAction") action NoAction_34() {
    }
    @name(".NoAction") action NoAction_35() {
    }
    @name(".NoAction") action NoAction_36() {
    }
    @name(".NoAction") action NoAction_37() {
    }
    @name(".NoAction") action NoAction_38() {
    }
    @name(".NoAction") action NoAction_39() {
    }
    @name(".NoAction") action NoAction_40() {
    }
    @name(".NoAction") action NoAction_41() {
    }
    @name(".NoAction") action NoAction_42() {
    }
    @name(".NoAction") action NoAction_43() {
    }
    @name(".NoAction") action NoAction_44() {
    }
    @name(".NoAction") action NoAction_45() {
    }
    @name(".NoAction") action NoAction_46() {
    }
    @name(".NoAction") action NoAction_47() {
    }
    @name(".set_lag_miss") action set_lag_miss() {
    }
    @name(".set_lag_port") action set_lag_port(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".set_nexthop_info") action set_nexthop_info(bit<16> bd, bit<48> dmac) {
        meta.l2_metadata.bd = bd;
        meta.l2_metadata.mac_da = dmac;
        hdr.ethernet.dstAddr = dmac;
        meta.tunnel_metadata.index = 16w0;
    }
    @name(".set_tunnel_info") action set_tunnel_info(bit<16> bd, bit<48> dmac, bit<16> index) {
        meta.l2_metadata.bd = bd;
        meta.l2_metadata.mac_da = dmac;
        meta.tunnel_metadata.index = index;
    }
    @name(".rmac_hit") action rmac_hit() {
    }
    @name(".rmac_miss") action rmac_miss() {
    }
    @name(".lag_group") table lag_group_0 {
        actions = {
            set_lag_miss();
            set_lag_port();
            @defaultonly NoAction_33();
        }
        key = {
            meta.ingress_metadata.egress_ifindex: exact @name("ingress_metadata.egress_ifindex") ;
            meta.l2_metadata.mac_sa             : selector @name("l2_metadata.mac_sa") ;
            meta.l2_metadata.mac_da             : selector @name("l2_metadata.mac_da") ;
        }
        implementation = lag_action_profile;
        default_action = NoAction_33();
    }
    @name(".nexthop") table nexthop_0 {
        actions = {
            set_nexthop_info();
            set_tunnel_info();
            @defaultonly NoAction_34();
        }
        key = {
            meta.l3_metadata.nexthop: exact @name("l3_metadata.nexthop") ;
            meta.l3_metadata.hash   : selector @name("l3_metadata.hash") ;
        }
        implementation = l3_action_profile;
        default_action = NoAction_34();
    }
    @name(".rmac") table rmac_0 {
        actions = {
            rmac_hit();
            rmac_miss();
            @defaultonly NoAction_35();
        }
        key = {
            meta.l2_metadata.mac_da: exact @name("l2_metadata.mac_da") ;
        }
        default_action = NoAction_35();
    }
    @name(".set_ifindex") action _set_ifindex_0(bit<16> ifindex) {
        meta.ingress_metadata.ifindex = ifindex;
    }
    @name(".set_ingress_port_properties") action _set_ingress_port_properties_0() {
    }
    @name(".set_bd_properties") action _set_bd_properties_0(bit<16> bd, bit<16> vrf) {
        meta.l3_metadata.vrf = vrf;
        meta.l2_metadata.bd = bd;
    }
    @name(".ingress_port_mapping") table _ingress_port_mapping {
        actions = {
            _set_ifindex_0();
            @defaultonly NoAction_36();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        default_action = NoAction_36();
    }
    @name(".ingress_port_properties") table _ingress_port_properties {
        actions = {
            _set_ingress_port_properties_0();
            @defaultonly NoAction_37();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        default_action = NoAction_37();
    }
    @name(".port_vlan_mapping") table _port_vlan_mapping {
        actions = {
            _set_bd_properties_0();
            @defaultonly NoAction_38();
        }
        key = {
            meta.ingress_metadata.ifindex: exact @name("ingress_metadata.ifindex") ;
            hdr.vlan_tag[0].isValid()    : exact @name("vlan_tag[0].$valid$") ;
            hdr.vlan_tag[0].vid          : exact @name("vlan_tag[0].vid") ;
            hdr.vlan_tag[1].isValid()    : exact @name("vlan_tag[1].$valid$") ;
            hdr.vlan_tag[1].vid          : exact @name("vlan_tag[1].vid") ;
        }
        default_action = NoAction_38();
    }
    @name(".drop_") action _drop_0() {
        mark_to_drop();
    }
    @name(".transit") action _transit_0() {
    }
    @name(".end") action _end_0() {
        meta.l2_metadata.mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.mac_da = hdr.ethernet.dstAddr;
        meta.l3_metadata.ipv6_sa = hdr.ipv6.srcAddr;
        meta.l3_metadata.ipv6_da = meta.sr_metadata.sid;
        meta.l3_metadata.proto = hdr.ipv6.nextHdr;
        meta.l3_metadata.flow_label = (bit<16>)hdr.ipv6.flowLabel;
        hdr.ipv6_srh.segLeft = hdr.ipv6_srh.segLeft + 8w255;
        hdr.ipv6.dstAddr = meta.sr_metadata.sid;
    }
    @name(".end_x") action _end_x_0(bit<16> nexthop) {
        meta.l3_metadata.nexthop = nexthop;
        meta.ingress_metadata.bypass = 4w0x2;
        hdr.ipv6_srh.segLeft = hdr.ipv6_srh.segLeft + 8w255;
        hdr.ipv6.dstAddr = meta.sr_metadata.sid;
    }
    @name(".end_t") action _end_t_0() {
    }
    @name(".end_dx2") action _end_dx2_0(bit<16> ifindex) {
        meta.sr_metadata.action_ = 4w0x1;
        meta.ingress_metadata.egress_ifindex = ifindex;
        meta.ingress_metadata.bypass = 4w0xf;
    }
    @name(".end_dx4") action _end_dx4_0(bit<16> nexthop) {
        meta.sr_metadata.action_ = 4w0x1;
        meta.l3_metadata.nexthop = nexthop;
        meta.ingress_metadata.bypass = 4w0x2;
    }
    @name(".end_dx6") action _end_dx6_0(bit<16> nexthop) {
        meta.sr_metadata.action_ = 4w0x1;
        meta.l3_metadata.nexthop = nexthop;
        meta.ingress_metadata.bypass = 4w0x2;
    }
    @name(".end_dt2") action _end_dt2_0(bit<16> bd) {
        meta.sr_metadata.action_ = 4w0x1;
        meta.l2_metadata.bd = bd;
        meta.l2_metadata.mac_sa = hdr.inner_ethernet.srcAddr;
        meta.l2_metadata.mac_da = hdr.inner_ethernet.dstAddr;
    }
    @name(".end_dt4") action _end_dt4_0(bit<16> vrf) {
        meta.sr_metadata.action_ = 4w0x1;
        meta.l3_metadata.vrf = vrf;
        meta.l2_metadata.mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.mac_da = hdr.ethernet.dstAddr;
        meta.l3_metadata.ipv4_sa = hdr.inner_ipv4.srcAddr;
        meta.l3_metadata.ipv4_da = hdr.inner_ipv4.dstAddr;
        meta.l3_metadata.proto = hdr.inner_ipv4.protocol;
    }
    @name(".end_dt6") action _end_dt6_0(bit<16> vrf) {
        meta.sr_metadata.action_ = 4w0x1;
        meta.l3_metadata.vrf = vrf;
        meta.l2_metadata.mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.mac_da = hdr.ethernet.dstAddr;
        meta.l3_metadata.ipv6_sa = hdr.inner_ipv6.srcAddr;
        meta.l3_metadata.ipv6_da = hdr.inner_ipv6.dstAddr;
        meta.l3_metadata.proto = hdr.inner_ipv6.nextHdr;
        meta.l3_metadata.flow_label = (bit<16>)hdr.inner_ipv6.flowLabel;
    }
    @name(".end_b6") action _end_b6_0(bit<128> sid) {
        meta.sr_metadata.action_ = 4w0x4;
        meta.l2_metadata.mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.mac_da = hdr.ethernet.dstAddr;
        meta.l3_metadata.ipv6_sa = hdr.ipv6.srcAddr;
        meta.l3_metadata.ipv6_da = sid;
        meta.l3_metadata.proto = hdr.ipv6.nextHdr;
        meta.l3_metadata.flow_label = (bit<16>)hdr.ipv6.flowLabel;
        hdr.ipv6.dstAddr = sid;
    }
    @name(".end_b6_encaps") action _end_b6_encaps_0(bit<128> sid) {
        meta.sr_metadata.action_ = 4w0x8;
        meta.l2_metadata.mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.mac_da = hdr.ethernet.dstAddr;
        meta.l3_metadata.ipv6_sa = hdr.ipv6.srcAddr;
        meta.l3_metadata.ipv6_da = sid;
        meta.l3_metadata.proto = hdr.ipv6.nextHdr;
        meta.l3_metadata.flow_label = (bit<16>)hdr.ipv6.flowLabel;
        hdr.ipv6_srh.segLeft = hdr.ipv6_srh.segLeft + 8w255;
        hdr.ipv6.dstAddr = meta.sr_metadata.sid;
    }
    @name(".t") action _t_0() {
        meta.l2_metadata.mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.mac_da = hdr.ethernet.dstAddr;
        meta.l3_metadata.ipv6_sa = hdr.ipv6.srcAddr;
        meta.l3_metadata.ipv6_da = hdr.ipv6.dstAddr;
        meta.l3_metadata.proto = hdr.ipv6.nextHdr;
        meta.l3_metadata.flow_label = (bit<16>)hdr.ipv6.flowLabel;
    }
    @name(".t_insert") action _t_insert_0(bit<128> sid) {
        meta.sr_metadata.action_ = 4w0x4;
        meta.l2_metadata.mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.mac_da = hdr.ethernet.dstAddr;
        meta.l3_metadata.ipv6_sa = hdr.ipv6.srcAddr;
        meta.l3_metadata.ipv6_da = sid;
        meta.l3_metadata.proto = hdr.ipv6.nextHdr;
        meta.l3_metadata.flow_label = (bit<16>)hdr.ipv6.flowLabel;
    }
    @name(".t_encaps") action _t_encaps_0(bit<128> srcAddr, bit<128> dstAddr, bit<20> flowLabel) {
        meta.sr_metadata.action_ = 4w0x8;
        meta.l2_metadata.mac_sa = hdr.ethernet.srcAddr;
        meta.l2_metadata.mac_da = hdr.ethernet.dstAddr;
        meta.l3_metadata.ipv6_sa = srcAddr;
        meta.l3_metadata.ipv6_da = dstAddr;
        meta.l3_metadata.proto = 8w43;
        meta.l3_metadata.flow_label = (bit<16>)flowLabel;
    }
    @name(".srv6_local_sid") table _srv6_local_sid {
        actions = {
            _drop_0();
            _transit_0();
            _end_0();
            _end_x_0();
            _end_t_0();
            _end_dx2_0();
            _end_dx4_0();
            _end_dx6_0();
            _end_dt2_0();
            _end_dt4_0();
            _end_dt6_0();
            _end_b6_0();
            _end_b6_encaps_0();
            @defaultonly NoAction_39();
        }
        key = {
            hdr.ipv6.dstAddr      : lpm @name("ipv6.dstAddr") ;
            hdr.ipv6_srh.isValid(): ternary @name("ipv6_srh.$valid$") ;
            hdr.ipv6_srh.segLeft  : ternary @name("ipv6_srh.segLeft") ;
            hdr.ipv6_srh.nextHdr  : ternary @name("ipv6_srh.nextHdr") ;
        }
        default_action = NoAction_39();
    }
    @name(".srv6_transit") table _srv6_transit {
        actions = {
            _t_0();
            _t_insert_0();
            _t_encaps_0();
            @defaultonly NoAction_40();
        }
        key = {
            hdr.ipv6.dstAddr: lpm @name("ipv6.dstAddr") ;
        }
        default_action = NoAction_40();
    }
    @name(".compute_ipv4_hash") action _compute_ipv4_hash_0() {
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>, bit<8>, bit<16>, bit<16>>, bit<32>>(meta.l3_metadata.hash, HashAlgorithm.crc16, 16w0, { meta.l3_metadata.ipv4_da, meta.l3_metadata.ipv4_sa, meta.l3_metadata.proto, meta.l3_metadata.l4_sport, meta.l3_metadata.l4_dport }, 32w65536);
    }
    @name(".compute_ipv6_hash") action _compute_ipv6_hash_0() {
        hash<bit<16>, bit<16>, tuple<bit<128>, bit<128>, bit<8>, bit<16>, bit<16>, bit<16>>, bit<32>>(meta.l3_metadata.hash, HashAlgorithm.crc16, 16w0, { meta.l3_metadata.ipv6_da, meta.l3_metadata.ipv6_sa, meta.l3_metadata.proto, meta.l3_metadata.flow_label, meta.l3_metadata.l4_sport, meta.l3_metadata.l4_dport }, 32w65536);
    }
    @name(".compute_hash") table _compute_hash {
        actions = {
            _compute_ipv4_hash_0();
            _compute_ipv6_hash_0();
            @defaultonly NoAction_41();
        }
        key = {
            meta.l3_metadata.version: exact @name("l3_metadata.version") ;
            hdr.ethernet.isValid()  : exact @name("ethernet.$valid$") ;
        }
        default_action = NoAction_41();
    }
    @name(".miss_") action _miss() {
    }
    @name(".set_nexthop_index") action _set_nexthop_index(bit<16> index) {
        meta.l3_metadata.nexthop = index;
    }
    @name(".set_nexthop_index") action _set_nexthop_index_0(bit<16> index) {
        meta.l3_metadata.nexthop = index;
    }
    @name(".ipv4_fib") table _ipv4_fib_0 {
        actions = {
            _miss();
            _set_nexthop_index();
            @defaultonly NoAction_42();
        }
        key = {
            meta.l3_metadata.vrf    : exact @name("l3_metadata.vrf") ;
            meta.l3_metadata.ipv4_da: exact @name("l3_metadata.ipv4_da") ;
        }
        default_action = NoAction_42();
    }
    @name(".ipv4_fib_lpm") table _ipv4_fib_lpm_0 {
        actions = {
            _set_nexthop_index_0();
            @defaultonly NoAction_43();
        }
        key = {
            meta.l3_metadata.vrf    : exact @name("l3_metadata.vrf") ;
            meta.l3_metadata.ipv4_da: lpm @name("l3_metadata.ipv4_da") ;
        }
        default_action = NoAction_43();
    }
    @name(".miss_") action _miss_0() {
    }
    @name(".set_nexthop_index") action _set_nexthop_index_5(bit<16> index) {
        meta.l3_metadata.nexthop = index;
    }
    @name(".set_nexthop_index") action _set_nexthop_index_6(bit<16> index) {
        meta.l3_metadata.nexthop = index;
    }
    @name(".ipv6_fib") table _ipv6_fib_0 {
        actions = {
            _miss_0();
            _set_nexthop_index_5();
            @defaultonly NoAction_44();
        }
        key = {
            meta.l3_metadata.vrf    : exact @name("l3_metadata.vrf") ;
            meta.l3_metadata.ipv6_da: exact @name("l3_metadata.ipv6_da") ;
        }
        default_action = NoAction_44();
    }
    @name(".ipv6_fib_lpm") table _ipv6_fib_lpm_0 {
        actions = {
            _set_nexthop_index_6();
            @defaultonly NoAction_45();
        }
        key = {
            meta.l3_metadata.vrf    : exact @name("l3_metadata.vrf") ;
            meta.l3_metadata.ipv6_da: lpm @name("l3_metadata.ipv6_da") ;
        }
        default_action = NoAction_45();
    }
    @name(".dmac_hit") action _dmac_hit_0(bit<16> ifindex) {
        meta.ingress_metadata.egress_ifindex = ifindex;
    }
    @name(".dmac_miss") action _dmac_miss_0() {
    }
    @name(".dmac_redirect") action _dmac_redirect_0(bit<8> index) {
    }
    @name(".dmac_drop") action _dmac_drop_0() {
        mark_to_drop();
    }
    @name(".smac_miss") action _smac_miss_0() {
    }
    @name(".smac_hit") action _smac_hit_0() {
    }
    @name(".dmac") table _dmac {
        support_timeout = true;
        actions = {
            _dmac_hit_0();
            _dmac_miss_0();
            _dmac_redirect_0();
            _dmac_drop_0();
            @defaultonly NoAction_46();
        }
        key = {
            meta.l2_metadata.bd    : exact @name("l2_metadata.bd") ;
            meta.l2_metadata.mac_da: exact @name("l2_metadata.mac_da") ;
        }
        default_action = NoAction_46();
    }
    @name(".smac") table _smac {
        actions = {
            _smac_miss_0();
            _smac_hit_0();
            @defaultonly NoAction_47();
        }
        key = {
            meta.l2_metadata.bd    : exact @name("l2_metadata.bd") ;
            meta.l2_metadata.mac_sa: exact @name("l2_metadata.mac_sa") ;
        }
        default_action = NoAction_47();
    }
    apply {
        _ingress_port_mapping.apply();
        _ingress_port_properties.apply();
        _port_vlan_mapping.apply();
        if (hdr.ipv6.isValid()) 
            switch (_srv6_local_sid.apply().action_run) {
                _transit_0: {
                    _srv6_transit.apply();
                }
            }

        switch (rmac_0.apply().action_run) {
            rmac_hit: {
                if (meta.ingress_metadata.bypass & 4w0x2 == 4w0) {
                    _compute_hash.apply();
                    if (meta.l3_metadata.version == 4w4) 
                        switch (_ipv4_fib_0.apply().action_run) {
                            _miss: {
                                _ipv4_fib_lpm_0.apply();
                            }
                        }

                    else 
                        if (meta.l3_metadata.version == 4w6) 
                            switch (_ipv6_fib_0.apply().action_run) {
                                _miss_0: {
                                    _ipv6_fib_lpm_0.apply();
                                }
                            }

                }
            }
        }

        nexthop_0.apply();
        if (meta.ingress_metadata.bypass & 4w0x1 == 4w0) {
            _smac.apply();
            _dmac.apply();
        }
        lag_group_0.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<arp_t>(hdr.arp);
        packet.emit<vlan_tag_t[2]>(hdr.vlan_tag);
        packet.emit<ipv6_t>(hdr.ipv6);
        packet.emit<ipv6_srh_t>(hdr.ipv6_srh);
        packet.emit<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[4]);
        packet.emit<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[3]);
        packet.emit<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[2]);
        packet.emit<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[1]);
        packet.emit<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[0]);
        packet.emit<ipv6_srh_t>(hdr.inner_ipv6_srh);
        packet.emit<ipv6_srh_segment_t[5]>(hdr.inner_ipv6_srh_seg_list);
        packet.emit<ethernet_t>(hdr.inner_ethernet);
        packet.emit<ipv4_t>(hdr.inner_ipv4);
        packet.emit<ipv6_t>(hdr.inner_ipv6);
        packet.emit<udp_t>(hdr.inner_udp);
        packet.emit<tcp_t>(hdr.inner_tcp);
        packet.emit<icmp_t>(hdr.inner_icmp);
        packet.emit<ipv4_t>(hdr.ipv4);
        packet.emit<udp_t>(hdr.udp);
        packet.emit<tcp_t>(hdr.tcp);
        packet.emit<icmp_t>(hdr.icmp);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

