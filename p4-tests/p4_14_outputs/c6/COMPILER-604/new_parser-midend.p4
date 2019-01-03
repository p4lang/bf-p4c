#include <core.p4>
#include <v1model.p4>

header arp_t {
    bit<16> hwType;
    bit<16> protoType;
    bit<8>  hwAddrLen;
    bit<8>  protoAddrLen;
    bit<16> opcode;
}

header arp_ipv4_t {
    bit<48> srcHwAddr;
    bit<32> srcProtoAddr;
    bit<48> dstHwAddr;
    bit<32> dstProtoAddr;
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

header etherII_t {
    bit<16> etherType;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
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

header ipv4_options_12b_t {
    bit<96> options;
}

header ipv4_options_16b_t {
    bit<128> options;
}

header ipv4_options_20b_t {
    bit<160> options;
}

header ipv4_options_24b_t {
    bit<192> options;
}

header ipv4_options_28b_t {
    bit<224> options;
}

header ipv4_options_32b_t {
    bit<256> options;
}

header ipv4_options_36b_t {
    bit<288> options;
}

header ipv4_options_40b_t {
    bit<320> options;
}

header ipv4_options_4b_t {
    bit<32> options;
}

header ipv4_options_8b_t {
    bit<64> options;
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

header llc_t {
    bit<16> len;
    bit<8>  dsap;
    bit<8>  ssap;
}

header mpls_t {
    bit<20> label;
    bit<3>  exp;
    bit<1>  bos;
    bit<8>  ttl;
}

header snap_t {
    bit<8>  ctrl;
    bit<24> oui;
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

header vlan_tag_t {
    bit<16> tpid;
    bit<3>  pri;
    bit<1>  cfi;
    bit<12> vid;
}

struct metadata {
}

struct headers {
    @name(".arp") 
    arp_t                                          arp;
    @name(".arp_ipv4") 
    arp_ipv4_t                                     arp_ipv4;
    @dont_trim @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md") @pa_atomic("egress", "eg_intr_md.egress_port") @pa_fragment("egress", "eg_intr_md._pad1") @pa_fragment("egress", "eg_intr_md._pad7") @pa_fragment("egress", "eg_intr_md._pad8") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_port") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_cos") @name(".eg_intr_md") 
    egress_intrinsic_metadata_t                    eg_intr_md;
    @dont_trim @pa_intrinsic_header("egress", "eg_intr_md_for_mb") @pa_atomic("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_fragment("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_length") @not_deparsed("ingress") @not_deparsed("egress") @name(".eg_intr_md_for_mb") 
    egress_intrinsic_metadata_for_mirror_buffer_t  eg_intr_md_for_mb;
    @dont_trim @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_oport.drop_ctl") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_for_oport") @name(".eg_intr_md_for_oport") 
    egress_intrinsic_metadata_for_output_port_t    eg_intr_md_for_oport;
    @pa_fragment("egress", "eg_intr_md_from_parser_aux.coalesce_sample_count") @pa_fragment("egress", "eg_intr_md_from_parser_aux.clone_src") @pa_fragment("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @pa_atomic("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_from_parser_aux") @name(".eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t    eg_intr_md_from_parser_aux;
    @name(".etherII") 
    etherII_t                                      etherII;
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
    @name(".ipv4") 
    ipv4_t                                         ipv4;
    @name(".ipv4_options_12b") 
    ipv4_options_12b_t                             ipv4_options_12b;
    @name(".ipv4_options_16b") 
    ipv4_options_16b_t                             ipv4_options_16b;
    @name(".ipv4_options_20b") 
    ipv4_options_20b_t                             ipv4_options_20b;
    @name(".ipv4_options_24b") 
    ipv4_options_24b_t                             ipv4_options_24b;
    @name(".ipv4_options_28b") 
    ipv4_options_28b_t                             ipv4_options_28b;
    @name(".ipv4_options_32b") 
    ipv4_options_32b_t                             ipv4_options_32b;
    @name(".ipv4_options_36b") 
    ipv4_options_36b_t                             ipv4_options_36b;
    @name(".ipv4_options_40b") 
    ipv4_options_40b_t                             ipv4_options_40b;
    @name(".ipv4_options_4b") 
    ipv4_options_4b_t                              ipv4_options_4b;
    @name(".ipv4_options_8b") 
    ipv4_options_8b_t                              ipv4_options_8b;
    @name(".ipv6") 
    ipv6_t                                         ipv6;
    @name(".llc") 
    llc_t                                          llc;
    @name(".mpls_bos") 
    mpls_t                                         mpls_bos;
    @name(".snap") 
    snap_t                                         snap;
    @name(".tcp") 
    tcp_t                                          tcp;
    @name(".udp") 
    udp_t                                          udp;
    @name(".mpls") 
    mpls_t[3]                                      mpls;
    @name(".vlan_tag") 
    vlan_tag_t[2]                                  vlan_tag;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<24> tmp;
    bit<4> tmp_0;
    bit<16> tmp_1;
    bit<16> tmp_2;
    bit<16> tmp_3;
    @name(".parse_arp") state parse_arp {
        packet.extract<etherII_t>(hdr.etherII);
        packet.extract<arp_t>(hdr.arp);
        transition select(hdr.arp.hwType, hdr.arp.protoType) {
            (16w0x1, 16w0x800): parse_arp_ipv4;
            default: accept;
        }
    }
    @name(".parse_arp_ipv4") state parse_arp_ipv4 {
        packet.extract<arp_ipv4_t>(hdr.arp_ipv4);
        transition accept;
    }
    @name(".parse_etherII") state parse_etherII {
        packet.extract<etherII_t>(hdr.etherII);
        transition accept;
    }
    @name(".parse_icmp") state parse_icmp {
        packet.extract<icmp_t>(hdr.icmp);
        transition accept;
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract<etherII_t>(hdr.etherII);
        transition parse_pure_ipv4;
    }
    @name(".parse_ipv4_options_12b") state parse_ipv4_options_12b {
        packet.extract<ipv4_options_12b_t>(hdr.ipv4_options_12b);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w1): parse_icmp;
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_16b") state parse_ipv4_options_16b {
        packet.extract<ipv4_options_16b_t>(hdr.ipv4_options_16b);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w1): parse_icmp;
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_20b") state parse_ipv4_options_20b {
        packet.extract<ipv4_options_20b_t>(hdr.ipv4_options_20b);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w1): parse_icmp;
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_24b") state parse_ipv4_options_24b {
        packet.extract<ipv4_options_24b_t>(hdr.ipv4_options_24b);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w1): parse_icmp;
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_28b") state parse_ipv4_options_28b {
        packet.extract<ipv4_options_28b_t>(hdr.ipv4_options_28b);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w1): parse_icmp;
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_32b") state parse_ipv4_options_32b {
        packet.extract<ipv4_options_32b_t>(hdr.ipv4_options_32b);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w1): parse_icmp;
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_36b") state parse_ipv4_options_36b {
        packet.extract<ipv4_options_36b_t>(hdr.ipv4_options_36b);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w1): parse_icmp;
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_40b") state parse_ipv4_options_40b {
        packet.extract<ipv4_options_40b_t>(hdr.ipv4_options_40b);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w1): parse_icmp;
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_4b") state parse_ipv4_options_4b {
        packet.extract<ipv4_options_4b_t>(hdr.ipv4_options_4b);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w1): parse_icmp;
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_8b") state parse_ipv4_options_8b {
        packet.extract<ipv4_options_8b_t>(hdr.ipv4_options_8b);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w1): parse_icmp;
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name(".parse_ipv6") state parse_ipv6 {
        packet.extract<etherII_t>(hdr.etherII);
        transition parse_pure_ipv6;
    }
    @name(".parse_llc") state parse_llc {
        packet.extract<llc_t>(hdr.llc);
        transition select(hdr.llc.ssap, hdr.llc.dsap) {
            (8w0xaa, 8w0xaa): parse_snap;
            (8w0xaa, 8w0xab): parse_snap;
            (8w0xab, 8w0xaa): parse_snap;
            (8w0xab, 8w0xab): parse_snap;
            default: accept;
        }
    }
    @name(".parse_mpls") state parse_mpls {
        tmp = packet.lookahead<bit<24>>();
        transition select(tmp[0:0]) {
            1w0: parse_mpls_non_bos;
            1w1: parse_mpls_bos;
            default: noMatch;
        }
    }
    @name(".parse_mpls_bos") state parse_mpls_bos {
        packet.extract<mpls_t>(hdr.mpls_bos);
        tmp_0 = packet.lookahead<bit<4>>();
        transition select(tmp_0[3:0]) {
            4w4: parse_pure_ipv4;
            4w6: parse_pure_ipv6;
            default: accept;
        }
    }
    @name(".parse_mpls_non_bos") state parse_mpls_non_bos {
        packet.extract<mpls_t>(hdr.mpls.next);
        transition parse_mpls;
    }
    @name(".parse_pure_ipv4") state parse_pure_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.ihl, hdr.ipv4.protocol) {
            (13w0x0, 4w0x5, 8w0x1): parse_icmp;
            (13w0x0, 4w0x5, 8w0x6): parse_tcp;
            (13w0x0, 4w0x5, 8w0x11): parse_udp;
            (13w0x0 &&& 13w0x0, 4w0x5 &&& 4w0xf, 8w0x0 &&& 8w0x0): accept;
            (13w0x0 &&& 13w0x0, 4w0x6 &&& 4w0xf, 8w0x0 &&& 8w0x0): parse_ipv4_options_4b;
            (13w0x0 &&& 13w0x0, 4w0x7 &&& 4w0xf, 8w0x0 &&& 8w0x0): parse_ipv4_options_8b;
            (13w0x0 &&& 13w0x0, 4w0x8 &&& 4w0xf, 8w0x0 &&& 8w0x0): parse_ipv4_options_12b;
            (13w0x0 &&& 13w0x0, 4w0x9 &&& 4w0xf, 8w0x0 &&& 8w0x0): parse_ipv4_options_16b;
            (13w0x0 &&& 13w0x0, 4w0xa &&& 4w0xf, 8w0x0 &&& 8w0x0): parse_ipv4_options_20b;
            (13w0x0 &&& 13w0x0, 4w0xb &&& 4w0xf, 8w0x0 &&& 8w0x0): parse_ipv4_options_24b;
            (13w0x0 &&& 13w0x0, 4w0xc &&& 4w0xf, 8w0x0 &&& 8w0x0): parse_ipv4_options_28b;
            (13w0x0 &&& 13w0x0, 4w0xd &&& 4w0xf, 8w0x0 &&& 8w0x0): parse_ipv4_options_32b;
            (13w0x0 &&& 13w0x0, 4w0xe &&& 4w0xf, 8w0x0 &&& 8w0x0): parse_ipv4_options_36b;
            (13w0x0 &&& 13w0x0, 4w0xf &&& 4w0xf, 8w0x0 &&& 8w0x0): parse_ipv4_options_40b;
            default: accept;
        }
    }
    @name(".parse_pure_ipv6") state parse_pure_ipv6 {
        packet.extract<ipv6_t>(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            8w1: parse_icmp;
            8w6: parse_tcp;
            8w17: parse_udp;
            default: accept;
        }
    }
    @name(".parse_snap") state parse_snap {
        packet.extract<snap_t>(hdr.snap);
        tmp_1 = packet.lookahead<bit<16>>();
        transition select(tmp_1[15:0]) {
            16w0x800: parse_ipv4;
            16w0x806: parse_arp;
            16w0x86dd: parse_ipv6;
            default: parse_etherII;
        }
    }
    @name(".parse_tcp") state parse_tcp {
        packet.extract<tcp_t>(hdr.tcp);
        transition accept;
    }
    @name(".parse_udp") state parse_udp {
        packet.extract<udp_t>(hdr.udp);
        transition accept;
    }
    @name(".parse_vlan_tag") state parse_vlan_tag {
        packet.extract<vlan_tag_t>(hdr.vlan_tag.next);
        tmp_2 = packet.lookahead<bit<16>>();
        transition select(tmp_2[15:0]) {
            16w0x0 &&& 16w0xfc00: parse_llc;
            16w0x400 &&& 16w0xfe00: parse_llc;
            16w0x8100 &&& 16w0xfeff: parse_vlan_tag;
            16w0x800: parse_ipv4;
            16w0x806: parse_arp;
            16w0x86dd: parse_ipv6;
            16w0x8847: parse_mpls;
            default: parse_etherII;
        }
    }
    @name(".start") state start {
        packet.extract<ethernet_t>(hdr.ethernet);
        tmp_3 = packet.lookahead<bit<16>>();
        transition select(tmp_3[15:0]) {
            16w0x0 &&& 16w0xfc00: parse_llc;
            16w0x400 &&& 16w0xfe00: parse_llc;
            16w0x8100 &&& 16w0xfeff: parse_vlan_tag;
            16w0x800: parse_ipv4;
            16w0x806: parse_arp;
            16w0x86dd: parse_ipv6;
            16w0x8847: parse_mpls;
            default: parse_etherII;
        }
    }
    state noMatch {
        verify(false, error.NoMatch);
        transition reject;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<vlan_tag_t>(hdr.vlan_tag[0]);
        packet.emit<vlan_tag_t>(hdr.vlan_tag[1]);
        packet.emit<mpls_t>(hdr.mpls[0]);
        packet.emit<mpls_t>(hdr.mpls[1]);
        packet.emit<mpls_t>(hdr.mpls[2]);
        packet.emit<mpls_t>(hdr.mpls_bos);
        packet.emit<llc_t>(hdr.llc);
        packet.emit<snap_t>(hdr.snap);
        packet.emit<etherII_t>(hdr.etherII);
        packet.emit<ipv6_t>(hdr.ipv6);
        packet.emit<ipv4_t>(hdr.ipv4);
        packet.emit<ipv4_options_40b_t>(hdr.ipv4_options_40b);
        packet.emit<ipv4_options_36b_t>(hdr.ipv4_options_36b);
        packet.emit<ipv4_options_32b_t>(hdr.ipv4_options_32b);
        packet.emit<ipv4_options_28b_t>(hdr.ipv4_options_28b);
        packet.emit<ipv4_options_24b_t>(hdr.ipv4_options_24b);
        packet.emit<ipv4_options_20b_t>(hdr.ipv4_options_20b);
        packet.emit<ipv4_options_16b_t>(hdr.ipv4_options_16b);
        packet.emit<ipv4_options_12b_t>(hdr.ipv4_options_12b);
        packet.emit<ipv4_options_8b_t>(hdr.ipv4_options_8b);
        packet.emit<ipv4_options_4b_t>(hdr.ipv4_options_4b);
        packet.emit<udp_t>(hdr.udp);
        packet.emit<tcp_t>(hdr.tcp);
        packet.emit<icmp_t>(hdr.icmp);
        packet.emit<arp_t>(hdr.arp);
        packet.emit<arp_ipv4_t>(hdr.arp_ipv4);
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

