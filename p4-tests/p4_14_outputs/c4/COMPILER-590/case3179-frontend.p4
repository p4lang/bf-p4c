#include <core.p4>
#include <v1model.p4>

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
    bit<16> lkp_mac_type;
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
}

struct metadata_t {
    bit<2>  lb_type;
    bit<3>  lb_port_group;
    bit<48> lb_port_num;
    bit<10> lb_hash;
    bit<3>  mpls_tunnel_type;
    bit<3>  inner_tunnel_type;
    bit<1>  pw_ctrl_word_present;
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

@name("fabricpath_extra_t") header fabricpath_extra_t_0 {
    bit<10> ftag;
    bit<6>  ttl;
}

@name("fabricpath_t") header fabricpath_t_0 {
    bit<6>  endnode_id;
    bit<1>  univ_local;
    bit<1>  indiv_group;
    bit<2>  endnode_idx;
    bit<1>  rsvd;
    bit<1>  ooo_dl;
    bit<12> switch_id;
    bit<8>  subswitch_id;
    bit<16> port_id;
    bit<48> srcAddr;
    bit<16> etherType;
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

header gtpv1_t {
    bit<3>  ver;
    bit<1>  pt;
    bit<1>  r;
    bit<1>  e;
    bit<1>  s;
    bit<1>  pn;
    bit<8>  mtype;
    bit<16> mlen;
    bit<32> teid;
}

header gtpv1_opt_fields_t {
    bit<16> seqnum;
    bit<8>  next_hdr;
    bit<8>  npdu;
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

@name("ethernet_t") header ethernet_t_0 {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
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

@name("etherType_t") header etherType_t_0 {
    bit<16> etherType;
}

@name("icmp_t") header icmp_t_0 {
    bit<16> typeCode;
    bit<16> hdrChecksum;
}

header macs_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
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

header vntag_t {
    bit<16> etherType;
    bit<2>  Version;
    bit<1>  dbit;
    bit<1>  ptr_bit;
    bit<12> dest_vif;
    bit<1>  looped;
    bit<3>  rsvd;
    bit<12> src_vif;
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
    @name(".ipv4_metadata") 
    ipv4_metadata_t ipv4_metadata;
    @name(".ipv6_metadata") 
    ipv6_metadata_t ipv6_metadata;
    @name(".l2_metadata") 
    l2_metadata_t   l2_metadata;
    @name(".l3_metadata") 
    l3_metadata_t   l3_metadata;
    @name(".meta") 
    metadata_t      meta;
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
    @name(".fp_extra") 
    fabricpath_extra_t_0                           fp_extra;
    @name(".fp_hdr") 
    fabricpath_t_0                                 fp_hdr;
    @name(".geneve_hdr") 
    genv_t                                         geneve_hdr;
    @name(".gre") 
    gre_t                                          gre;
    @name(".gtpv1_hdr") 
    gtpv1_t                                        gtpv1_hdr;
    @name(".gtpv1_opts") 
    gtpv1_opt_fields_t                             gtpv1_opts;
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
    @name(".inner_eth") 
    ethernet_t_0                                   inner_eth;
    @name(".inner_ipv4") 
    ipv4_t                                         inner_ipv4;
    @name(".inner_ipv6") 
    ipv6_t                                         inner_ipv6;
    @name(".outer_etherType") 
    etherType_t_0                                  outer_etherType;
    @name(".outer_icmp") 
    icmp_t_0                                       outer_icmp;
    @name(".outer_ipv4") 
    ipv4_t                                         outer_ipv4;
    @name(".outer_ipv6") 
    ipv6_t                                         outer_ipv6;
    @name(".outer_macs") 
    macs_t                                         outer_macs;
    @name(".outer_tcp") 
    tcp_t                                          outer_tcp;
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
    @name(".vntag") 
    vntag_t                                        vntag;
    @name(".mpls") 
    mpls_t[8]                                      mpls;
    @name(".vlan_tag_") 
    vlan_tag_t[2]                                  vlan_tag_;
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<112> tmp;
    bit<4> tmp_0;
    bit<4> tmp_1;
    @name(".lookahead_etherType") state lookahead_etherType {
        tmp = packet.lookahead<bit<112>>();
        transition select(tmp[3:0]) {
            4w0x6: parse_vntag;
            4w0x3: parse_fabricpath;
            default: parse_outer_ethernet;
        }
    }
    @name(".no_inner_tunnel") state no_inner_tunnel {
        meta.meta.inner_tunnel_type = 3w0;
        transition accept;
    }
    @name(".parse_fabricpath") state parse_fabricpath {
        packet.extract<fabricpath_t_0>(hdr.fp_hdr);
        packet.extract<fabricpath_extra_t_0>(hdr.fp_extra);
        transition parse_outer_ethernet;
    }
    @name(".parse_geneve_hdr") state parse_geneve_hdr {
        packet.extract<genv_t>(hdr.geneve_hdr);
        transition parse_geneve_payload;
    }
    @name(".parse_geneve_payload") state parse_geneve_payload {
        transition select(hdr.geneve_hdr.protoType) {
            16w0x6558: parse_inner_eth;
            default: accept;
        }
    }
    @name(".parse_gre") state parse_gre {
        packet.extract<gre_t>(hdr.gre);
        transition select(hdr.gre.proto) {
            16w0x6558: parse_inner_eth;
            default: accept;
        }
    }
    @name(".parse_gtp_inner_ipv4") state parse_gtp_inner_ipv4 {
        meta.meta.lb_type = 2w3;
        transition parse_inner_ipv4;
    }
    @name(".parse_gtp_inner_ipv6") state parse_gtp_inner_ipv6 {
        meta.meta.lb_type = 2w3;
        transition parse_inner_ipv6;
    }
    @name(".parse_gtp_inner_non_ip") state parse_gtp_inner_non_ip {
        meta.meta.lb_type = 2w0;
        transition accept;
    }
    @name(".parse_gtp_payload") state parse_gtp_payload {
        tmp_0 = packet.lookahead<bit<4>>();
        transition select(tmp_0[3:0]) {
            4w4: parse_gtp_inner_ipv4;
            4w6: parse_gtp_inner_ipv6;
            default: parse_gtp_inner_non_ip;
        }
    }
    @name(".parse_gtpc") state parse_gtpc {
        meta.meta.lb_type = 2w1;
        transition accept;
    }
    @name(".parse_gtpu") state parse_gtpu {
        transition parse_gtpv1_hdr;
    }
    @name(".parse_gtpv1_hdr") state parse_gtpv1_hdr {
        packet.extract<gtpv1_t>(hdr.gtpv1_hdr);
        transition select(hdr.gtpv1_hdr.e, hdr.gtpv1_hdr.s, hdr.gtpv1_hdr.pn) {
            (1w0, 1w0, 1w0): parse_gtp_payload;
            (1w0, 1w0, 1w0): parse_gtp_payload;
            (1w0, 1w0, 1w0): parse_gtp_payload;
            default: parse_gtpv1_opts;
        }
    }
    @name(".parse_gtpv1_opts") state parse_gtpv1_opts {
        packet.extract<gtpv1_opt_fields_t>(hdr.gtpv1_opts);
        transition parse_gtp_payload;
    }
    @name(".parse_inner_eth") state parse_inner_eth {
        packet.extract<ethernet_t_0>(hdr.inner_eth);
        meta.l2_metadata.lkp_mac_sa = hdr.inner_eth.srcAddr;
        meta.l2_metadata.lkp_mac_da = hdr.inner_eth.dstAddr;
        transition select(hdr.inner_eth.etherType) {
            16w0x800: parse_inner_ipv4;
            16w0x86dd: parse_inner_ipv6;
            default: accept;
        }
    }
    @name(".parse_inner_ipv4") state parse_inner_ipv4 {
        packet.extract<ipv4_t>(hdr.inner_ipv4);
        meta.meta.inner_tunnel_type = 3w2;
        transition accept;
    }
    @name(".parse_inner_ipv6") state parse_inner_ipv6 {
        packet.extract<ipv6_t>(hdr.inner_ipv6);
        meta.meta.inner_tunnel_type = 3w3;
        transition accept;
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
        tmp_1 = packet.lookahead<bit<4>>();
        transition select(tmp_1[3:0]) {
            4w0x0: parse_mpls_pw_ctrl;
            4w0x4: parse_mpls_inner_ipv4;
            4w0x6: parse_mpls_inner_ipv6;
            default: no_inner_tunnel;
        }
    }
    @name(".parse_mpls_inner_ipv4") state parse_mpls_inner_ipv4 {
        meta.meta.mpls_tunnel_type = 3w2;
        transition parse_outer_ipv4;
    }
    @name(".parse_mpls_inner_ipv6") state parse_mpls_inner_ipv6 {
        meta.meta.mpls_tunnel_type = 3w3;
        transition parse_outer_ipv6;
    }
    @name(".parse_mpls_pw_ctrl") state parse_mpls_pw_ctrl {
        meta.meta.pw_ctrl_word_present = 1w1;
        meta.meta.mpls_tunnel_type = 3w0;
        transition accept;
    }
    @name(".parse_non_gtp") state parse_non_gtp {
        meta.meta.lb_type = 2w2;
        transition accept;
    }
    @name(".parse_outer_etherType") state parse_outer_etherType {
        packet.extract<etherType_t_0>(hdr.outer_etherType);
        transition select(hdr.outer_etherType.etherType) {
            16w0x8100: parse_vlan;
            16w0x88a8: parse_vlan;
            16w0x9100: parse_vlan;
            16w0x8847: parse_mpls;
            16w0x800: parse_outer_ipv4;
            16w0x86dd: parse_outer_ipv6;
            default: accept;
        }
    }
    @name(".parse_outer_ethernet") state parse_outer_ethernet {
        packet.extract<macs_t>(hdr.outer_macs);
        transition parse_outer_etherType;
    }
    @name(".parse_outer_ipv4") state parse_outer_ipv4 {
        packet.extract<ipv4_t>(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.protocol) {
            8w17: parse_outer_tcp;
            8w17: parse_outer_udp;
            8w47: parse_gre;
            default: accept;
        }
    }
    @name(".parse_outer_ipv6") state parse_outer_ipv6 {
        packet.extract<ipv6_t>(hdr.outer_ipv6);
        transition select(hdr.outer_ipv6.nextHdr) {
            8w17: parse_outer_udp;
            default: accept;
        }
    }
    @name(".parse_outer_tcp") state parse_outer_tcp {
        packet.extract<tcp_t>(hdr.outer_tcp);
        meta.l3_metadata.lkp_l4_sport = hdr.outer_tcp.srcPort;
        meta.l3_metadata.lkp_l4_dport = hdr.outer_tcp.dstPort;
        transition accept;
    }
    @name(".parse_outer_udp") state parse_outer_udp {
        packet.extract<udp_t>(hdr.outer_udp);
        meta.l3_metadata.lkp_l4_sport = hdr.outer_udp.srcPort;
        meta.l3_metadata.lkp_l4_dport = hdr.outer_udp.dstPort;
        transition select(hdr.outer_udp.dstPort) {
            16w2123: parse_gtpc;
            16w2152: parse_gtpu;
            16w6081: parse_geneve_hdr;
            default: parse_non_gtp;
        }
    }
    @name(".parse_vlan") state parse_vlan {
        packet.extract<vlan_tag_t>(hdr.vlan_tag_.next);
        transition select(hdr.vlan_tag_.last.etherType) {
            16w0x8100: parse_vlan;
            16w0x8847: parse_mpls;
            default: accept;
        }
    }
    @name(".parse_vntag") state parse_vntag {
        packet.extract<macs_t>(hdr.outer_macs);
        packet.extract<vntag_t>(hdr.vntag);
        transition parse_outer_etherType;
    }
    @name(".start") state start {
        transition lookahead_etherType;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".gtp_strip") action gtp_strip() {
        hdr.outer_ipv4.setInvalid();
        hdr.outer_ipv6.setInvalid();
        hdr.outer_udp.setInvalid();
        hdr.gtpv1_hdr.setInvalid();
        hdr.gtpv1_opts.setInvalid();
    }
    @name(".nop") action nop() {
    }
    @name(".nop") action nop_2() {
    }
    @name(".nop") action nop_10() {
    }
    @name(".l2gre_encap") action l2gre_encap(bit<48> smac, bit<48> dmac, bit<32> sip, bit<32> dip) {
        hdr.inner_eth.dstAddr = hdr.outer_macs.dstAddr;
        hdr.inner_eth.srcAddr = hdr.outer_macs.srcAddr;
        hdr.inner_eth.etherType = hdr.outer_etherType.etherType;
        hdr.outer_macs.dstAddr = dmac;
        hdr.outer_macs.srcAddr = smac;
        hdr.outer_etherType.etherType = 16w0x800;
        hdr.inner_ipv4 = hdr.outer_ipv4;
        hdr.outer_ipv4.srcAddr = sip;
        hdr.outer_ipv4.dstAddr = dip;
        hdr.outer_ipv4.version = 4w4;
        hdr.outer_ipv4.ihl = 4w5;
        hdr.outer_ipv4.diffserv = 8w0;
        hdr.outer_ipv4.totalLen = hdr.outer_ipv4.totalLen + 16w18;
        hdr.outer_ipv4.identification = 16w0;
        hdr.outer_ipv4.flags = 3w0;
        hdr.outer_ipv4.fragOffset = 13w0;
        hdr.outer_ipv4.ttl = 8w64;
        hdr.outer_ipv4.protocol = 8w47;
        hdr.outer_ipv4.hdrChecksum = 16w0;
        hdr.gre.setValid();
        hdr.gre.C = 1w0;
        hdr.gre.R = 1w0;
        hdr.gre.K = 1w0;
        hdr.gre.S = 1w0;
        hdr.gre.s = 1w0;
        hdr.gre.recurse = 3w0;
        hdr.gre.flags = 5w0;
        hdr.gre.ver = 3w0;
        hdr.gre.proto = 16w0x6558;
    }
    @name(".rewrite_outer_ethtype") action rewrite_outer_ethtype(bit<16> etherType) {
        hdr.outer_etherType.etherType = etherType;
    }
    @name(".rewrite_vlan0_ethtype") action rewrite_vlan0_ethtype(bit<16> etherType) {
        hdr.vlan_tag_[0].etherType = etherType;
    }
    @name(".rewrite_vlan1_ethtype") action rewrite_vlan1_ethtype(bit<16> etherType) {
        hdr.vlan_tag_[1].etherType = etherType;
    }
    @name(".gtp_tbl") table gtp_tbl_0 {
        actions = {
            gtp_strip();
            nop();
        }
        key = {
            hdr.gtpv1_hdr.isValid()    : exact @name("gtpv1_hdr.$valid$") ;
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        max_size = 256;
        default_action = nop();
    }
    @name(".l2gre_encap_tbl") table l2gre_encap_tbl_0 {
        actions = {
            l2gre_encap();
            nop_2();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        max_size = 256;
        default_action = nop_2();
    }
    @name(".rewrite_tbl") table rewrite_tbl_0 {
        actions = {
            rewrite_outer_ethtype();
            rewrite_vlan0_ethtype();
            rewrite_vlan1_ethtype();
            nop_10();
        }
        key = {
            hdr.vlan_tag_[0].isValid() : exact @name("vlan_tag_[0].$valid$") ;
            hdr.vlan_tag_[1].isValid() : exact @name("vlan_tag_[1].$valid$") ;
            meta.meta.mpls_tunnel_type : ternary @name("meta.mpls_tunnel_type") ;
            meta.meta.inner_tunnel_type: ternary @name("meta.inner_tunnel_type") ;
        }
        max_size = 16;
        default_action = nop_10();
    }
    apply {
        if (meta.meta.lb_type == 2w3) 
            gtp_tbl_0.apply();
        rewrite_tbl_0.apply();
        l2gre_encap_tbl_0.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_6() {
    }
    @name(".NoAction") action NoAction_7() {
    }
    @name(".NoAction") action NoAction_8() {
    }
    @name(".NoAction") action NoAction_9() {
    }
    bool tmp_2;
    @name(".nop") action nop_11() {
    }
    @name(".nop") action nop_12() {
    }
    @name(".nop") action nop_13() {
    }
    @name(".nop") action nop_14() {
    }
    @name(".nop") action nop_15() {
    }
    @name(".nop") action nop_16() {
    }
    @name(".acl_deny") action acl_deny() {
        mark_to_drop();
    }
    @name(".set_egr") action set_egr(bit<9> egress_spec) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_spec;
    }
    @name(".acl_permit") action acl_permit(bit<9> egress_spec) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_spec;
    }
    @name(".set_lb_hashed_index_ipv4") action set_lb_hashed_index_ipv4() {
        hash<bit<10>, bit<10>, tuple<bit<32>, bit<32>>, bit<20>>(meta.meta.lb_hash, HashAlgorithm.crc16, 10w0, { hdr.inner_ipv4.srcAddr, hdr.inner_ipv4.dstAddr }, 20w1024);
    }
    @name(".set_lb_hashed_index_ipv6") action set_lb_hashed_index_ipv6() {
        hash<bit<10>, bit<10>, tuple<bit<128>, bit<128>>, bit<20>>(meta.meta.lb_hash, HashAlgorithm.crc16, 10w0, { hdr.inner_ipv6.srcAddr, hdr.inner_ipv6.dstAddr }, 20w1024);
    }
    @name(".fp_strip") action fp_strip() {
        hdr.fp_hdr.setInvalid();
        hdr.fp_extra.setInvalid();
    }
    @name("._drop") action _drop() {
        mark_to_drop();
    }
    @name(".geneve_strip") action geneve_strip() {
        hdr.outer_macs.setInvalid();
        hdr.outer_etherType.setInvalid();
        hdr.outer_ipv4.setInvalid();
        hdr.outer_udp.setInvalid();
        hdr.geneve_hdr.setInvalid();
    }
    @name(".l2gre_decap") action l2gre_decap() {
        hdr.outer_macs.setInvalid();
        hdr.outer_etherType.setInvalid();
        hdr.outer_ipv4.setInvalid();
        hdr.gre.setInvalid();
    }
    @name(".set_lb_group") action set_lb_group(bit<3> group_num) {
        meta.meta.lb_port_group = group_num;
    }
    @name(".set_lb_group") action set_lb_group_2(bit<3> group_num) {
        meta.meta.lb_port_group = group_num;
    }
    @name(".set_hashed_lb_port") action set_hashed_lb_port(bit<48> lb_port) {
        hdr.outer_macs.dstAddr[39:32] = lb_port[39:32];
    }
    @name(".mpls_strip") action mpls_strip() {
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.mpls[3].setInvalid();
        hdr.mpls[4].setInvalid();
        hdr.mpls[5].setInvalid();
        hdr.mpls[6].setInvalid();
        hdr.mpls[7].setInvalid();
    }
    @name(".rewrite_outer_dmac") action rewrite_outer_dmac(bit<48> mac) {
        hdr.outer_macs.dstAddr[47:40] = mac[47:40];
    }
    @name(".vntag_strip") action vntag_strip() {
        hdr.vntag.setInvalid();
    }
    @entries_with_ranges(40) @name(".acl_tbl") table acl_tbl_0 {
        actions = {
            nop_11();
            acl_deny();
            acl_permit();
        }
        key = {
            meta.l2_metadata.lkp_mac_sa        : ternary @name("l2_metadata.lkp_mac_sa") ;
            meta.l2_metadata.lkp_mac_da        : ternary @name("l2_metadata.lkp_mac_da") ;
            meta.l2_metadata.lkp_mac_type      : ternary @name("l2_metadata.lkp_mac_type") ;
            meta.ipv4_metadata.lkp_ipv4_sa     : ternary @name("ipv4_metadata.lkp_ipv4_sa") ;
            meta.ipv4_metadata.lkp_ipv4_da     : ternary @name("ipv4_metadata.lkp_ipv4_da") ;
            meta.l3_metadata.lkp_ip_proto      : ternary @name("l3_metadata.lkp_ip_proto") ;
            meta.l3_metadata.lkp_l4_sport      : range @name("l3_metadata.lkp_l4_sport") ;
            meta.l3_metadata.lkp_l4_dport      : range @name("l3_metadata.lkp_l4_dport") ;
            meta.l3_metadata.lkp_outer_l4_sport: range @name("l3_metadata.lkp_outer_l4_sport") ;
            meta.l3_metadata.lkp_outer_l4_dport: range @name("l3_metadata.lkp_outer_l4_dport") ;
            meta.l3_metadata.lkp_ip_ttl        : ternary @name("l3_metadata.lkp_ip_ttl") ;
        }
        size = 512;
        default_action = nop_11();
    }
    @name(".compute_inner_ip_hash_tbl_ipv4") table compute_inner_ip_hash_tbl_ipv4_0 {
        actions = {
            set_lb_hashed_index_ipv4();
        }
        size = 1;
        default_action = set_lb_hashed_index_ipv4();
    }
    @name(".compute_inner_ip_hash_tbl_ipv6") table compute_inner_ip_hash_tbl_ipv6_0 {
        actions = {
            set_lb_hashed_index_ipv6();
        }
        size = 1;
        default_action = set_lb_hashed_index_ipv6();
    }
    @name(".fp_tbl") table fp_tbl_0 {
        actions = {
            fp_strip();
            nop_12();
        }
        key = {
            hdr.fp_hdr.isValid()       : exact @name("fp_hdr.$valid$") ;
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        max_size = 256;
        default_action = nop_12();
    }
    @name(".fwd_tbl") table fwd_tbl_0 {
        actions = {
            set_egr();
            _drop();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        max_size = 16;
        default_action = NoAction_0();
    }
    @name(".geneve_tbl") table geneve_tbl_0 {
        actions = {
            geneve_strip();
            nop_13();
        }
        key = {
            hdr.geneve_hdr.isValid()   : exact @name("geneve_hdr.$valid$") ;
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        max_size = 256;
        default_action = nop_13();
    }
    @name(".l2gre_decap_tbl") table l2gre_decap_tbl_0 {
        actions = {
            l2gre_decap();
            nop_14();
        }
        key = {
            hdr.gre.isValid()          : exact @name("gre.$valid$") ;
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        max_size = 256;
        default_action = nop_14();
    }
    @name(".lb_group_tbl_ipv4") table lb_group_tbl_ipv4_0 {
        actions = {
            set_lb_group();
            @defaultonly NoAction_6();
        }
        key = {
            hdr.outer_ipv4.srcAddr: ternary @name("outer_ipv4.srcAddr") ;
        }
        max_size = 16;
        default_action = NoAction_6();
    }
    @name(".lb_group_tbl_ipv6") table lb_group_tbl_ipv6_0 {
        actions = {
            set_lb_group_2();
            @defaultonly NoAction_7();
        }
        key = {
            hdr.outer_ipv6.srcAddr: ternary @name("outer_ipv6.srcAddr") ;
        }
        max_size = 16;
        default_action = NoAction_7();
    }
    @name(".lb_weight_tbl") table lb_weight_tbl_0 {
        actions = {
            set_hashed_lb_port();
            @defaultonly NoAction_8();
        }
        key = {
            hdr.gtpv1_hdr.isValid(): exact @name("gtpv1_hdr.$valid$") ;
            meta.meta.lb_hash      : exact @name("meta.lb_hash") ;
        }
        size = 1024;
        default_action = NoAction_8();
    }
    @name(".mpls_tbl") table mpls_tbl_0 {
        actions = {
            mpls_strip();
            nop_15();
        }
        key = {
            hdr.ig_intr_md.ingress_port   : exact @name("ig_intr_md.ingress_port") ;
            hdr.mpls[0].isValid()         : exact @name("mpls[0].$valid$") ;
            meta.meta.pw_ctrl_word_present: exact @name("meta.pw_ctrl_word_present") ;
            meta.meta.mpls_tunnel_type    : exact @name("meta.mpls_tunnel_type") ;
        }
        max_size = 16;
        default_action = nop_15();
    }
    @name(".rewrite_dmac_tbl") table rewrite_dmac_tbl_0 {
        actions = {
            rewrite_outer_dmac();
            @defaultonly NoAction_9();
        }
        key = {
            hdr.gtpv1_hdr.isValid()    : exact @name("gtpv1_hdr.$valid$") ;
            meta.meta.inner_tunnel_type: exact @name("meta.inner_tunnel_type") ;
            meta.meta.lb_type          : exact @name("meta.lb_type") ;
            meta.meta.lb_port_group    : exact @name("meta.lb_port_group") ;
        }
        max_size = 64;
        default_action = NoAction_9();
    }
    @name(".vntag_tbl") table vntag_tbl_0 {
        actions = {
            vntag_strip();
            nop_16();
        }
        key = {
            hdr.vntag.isValid()        : exact @name("vntag.$valid$") ;
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        max_size = 256;
        default_action = nop_16();
    }
    apply {
        if (meta.meta.inner_tunnel_type == 3w2) 
            compute_inner_ip_hash_tbl_ipv4_0.apply();
        else 
            if (meta.meta.inner_tunnel_type == 3w3) 
                compute_inner_ip_hash_tbl_ipv6_0.apply();
        fp_tbl_0.apply();
        vntag_tbl_0.apply();
        lb_weight_tbl_0.apply();
        if (hdr.outer_ipv4.isValid()) 
            lb_group_tbl_ipv4_0.apply();
        if (hdr.outer_ipv6.isValid()) 
            lb_group_tbl_ipv6_0.apply();
        mpls_tbl_0.apply();
        geneve_tbl_0.apply();
        l2gre_decap_tbl_0.apply();
        rewrite_dmac_tbl_0.apply();
        tmp_2 = acl_tbl_0.apply().hit;
        if (tmp_2) 
            ;
        else 
            fwd_tbl_0.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<fabricpath_t_0>(hdr.fp_hdr);
        packet.emit<fabricpath_extra_t_0>(hdr.fp_extra);
        packet.emit<macs_t>(hdr.outer_macs);
        packet.emit<vntag_t>(hdr.vntag);
        packet.emit<etherType_t_0>(hdr.outer_etherType);
        packet.emit<vlan_tag_t[2]>(hdr.vlan_tag_);
        packet.emit<mpls_t[8]>(hdr.mpls);
        packet.emit<ipv6_t>(hdr.outer_ipv6);
        packet.emit<ipv4_t>(hdr.outer_ipv4);
        packet.emit<gre_t>(hdr.gre);
        packet.emit<udp_t>(hdr.outer_udp);
        packet.emit<genv_t>(hdr.geneve_hdr);
        packet.emit<ethernet_t_0>(hdr.inner_eth);
        packet.emit<gtpv1_t>(hdr.gtpv1_hdr);
        packet.emit<gtpv1_opt_fields_t>(hdr.gtpv1_opts);
        packet.emit<ipv6_t>(hdr.inner_ipv6);
        packet.emit<ipv4_t>(hdr.inner_ipv4);
        packet.emit<tcp_t>(hdr.outer_tcp);
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

