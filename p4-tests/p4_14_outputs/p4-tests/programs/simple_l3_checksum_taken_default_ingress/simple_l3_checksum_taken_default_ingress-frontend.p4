#include <core.p4>
#include <v1model.p4>

struct l4_lookup_t {
    bit<16> word_1;
    bit<16> word_2;
    bit<1>  first_frag;
}

struct meta_t {
    bit<1> ipv4_checksum_update;
    bit<1> ipv4_tcp_checksum_update;
    bit<1> ipv4_udp_checksum_update;
    bit<1> ipv6_tcp_checksum_update;
    bit<1> ipv6_udp_checksum_update;
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
    bit<16> typeCode;
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

header igmp_t {
    bit<16> typeCode;
    bit<16> checksum;
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

header option_word_t {
    bit<32> data;
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

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
}

header tcp_checksum_t {
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> len;
}

header udp_checksum_t {
    bit<16> checksum;
}

header vlan_tag_t {
    bit<3>  pcp;
    bit<1>  cfi;
    bit<12> vid;
    bit<16> etherType;
}

struct metadata {
    @name(".l4_lookup") 
    l4_lookup_t l4_lookup;
    @name(".meta") 
    meta_t      meta;
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
    @name(".igmp") 
    igmp_t                                         igmp;
    @name(".ipv4") 
    ipv4_t                                         ipv4;
    @name(".ipv4_option_word_1") 
    option_word_t                                  ipv4_option_word_1;
    @name(".ipv4_option_word_10") 
    option_word_t                                  ipv4_option_word_10;
    @name(".ipv4_option_word_2") 
    option_word_t                                  ipv4_option_word_2;
    @name(".ipv4_option_word_3") 
    option_word_t                                  ipv4_option_word_3;
    @name(".ipv4_option_word_4") 
    option_word_t                                  ipv4_option_word_4;
    @name(".ipv4_option_word_5") 
    option_word_t                                  ipv4_option_word_5;
    @name(".ipv4_option_word_6") 
    option_word_t                                  ipv4_option_word_6;
    @name(".ipv4_option_word_7") 
    option_word_t                                  ipv4_option_word_7;
    @name(".ipv4_option_word_8") 
    option_word_t                                  ipv4_option_word_8;
    @name(".ipv4_option_word_9") 
    option_word_t                                  ipv4_option_word_9;
    @name(".ipv6") 
    ipv6_t                                         ipv6;
    @name(".tcp") 
    tcp_t                                          tcp;
    @name(".tcp_checksum_v4") 
    tcp_checksum_t                                 tcp_checksum_v4;
    @name(".tcp_checksum_v6") 
    tcp_checksum_t                                 tcp_checksum_v6;
    @name(".udp") 
    udp_t                                          udp;
    @name(".udp_checksum_v4") 
    udp_checksum_t                                 udp_checksum_v4;
    @name(".udp_checksum_v6") 
    udp_checksum_t                                 udp_checksum_v6;
    @name(".vlan_tag") 
    vlan_tag_t[2]                                  vlan_tag;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<16> tmp;
    bit<32> tmp_0;
    bit<16> tmp_1;
    bit<32> tmp_2;
    bit<16> tmp_3;
    bit<32> tmp_4;
    bit<16> tmp_5;
    bit<32> tmp_6;
    bit<16> tmp_7;
    bit<32> tmp_8;
    bit<16> tmp_9;
    bit<32> tmp_10;
    bit<16> tmp_11;
    bit<32> tmp_12;
    bit<16> tmp_13;
    bit<32> tmp_14;
    bit<16> tmp_15;
    bit<32> tmp_16;
    bit<16> tmp_17;
    bit<32> tmp_18;
    bit<16> tmp_19;
    bit<32> tmp_20;
    bit<16> tmp_21;
    bit<32> tmp_22;
    @name(".parse_first_fragment") state parse_first_fragment {
        meta.l4_lookup.first_frag = 1w1;
        transition accept;
    }
    @name(".parse_icmp") state parse_icmp {
        packet.extract<icmp_t>(hdr.icmp);
        transition parse_first_fragment;
    }
    @name(".parse_igmp") state parse_igmp {
        packet.extract<igmp_t>(hdr.igmp);
        transition parse_first_fragment;
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            4w0x5: parse_ipv4_no_options;
            4w0x6: parse_ipv4_options_1;
            4w0x7: parse_ipv4_options_2;
            4w0x8: parse_ipv4_options_3;
            4w0x9: parse_ipv4_options_4;
            4w0xa: parse_ipv4_options_5;
            4w0xb: parse_ipv4_options_6;
            4w0xc: parse_ipv4_options_7;
            4w0xd: parse_ipv4_options_8;
            4w0xe: parse_ipv4_options_9;
            4w0xf: parse_ipv4_options_10;
            4w0x0 &&& 4w0xf: parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_no_options") state parse_ipv4_no_options {
        tmp = packet.lookahead<bit<16>>();
        meta.l4_lookup.word_1 = tmp[15:0];
        tmp_0 = packet.lookahead<bit<32>>();
        meta.l4_lookup.word_2 = tmp_0[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_1") state parse_ipv4_options_1 {
        packet.extract<option_word_t>(hdr.ipv4_option_word_1);
        tmp_1 = packet.lookahead<bit<16>>();
        meta.l4_lookup.word_1 = tmp_1[15:0];
        tmp_2 = packet.lookahead<bit<32>>();
        meta.l4_lookup.word_2 = tmp_2[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_10") state parse_ipv4_options_10 {
        packet.extract<option_word_t>(hdr.ipv4_option_word_1);
        packet.extract<option_word_t>(hdr.ipv4_option_word_2);
        packet.extract<option_word_t>(hdr.ipv4_option_word_3);
        packet.extract<option_word_t>(hdr.ipv4_option_word_4);
        packet.extract<option_word_t>(hdr.ipv4_option_word_5);
        packet.extract<option_word_t>(hdr.ipv4_option_word_6);
        packet.extract<option_word_t>(hdr.ipv4_option_word_7);
        packet.extract<option_word_t>(hdr.ipv4_option_word_8);
        packet.extract<option_word_t>(hdr.ipv4_option_word_9);
        packet.extract<option_word_t>(hdr.ipv4_option_word_10);
        tmp_3 = packet.lookahead<bit<16>>();
        meta.l4_lookup.word_1 = tmp_3[15:0];
        tmp_4 = packet.lookahead<bit<32>>();
        meta.l4_lookup.word_2 = tmp_4[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_2") state parse_ipv4_options_2 {
        packet.extract<option_word_t>(hdr.ipv4_option_word_1);
        packet.extract<option_word_t>(hdr.ipv4_option_word_2);
        tmp_5 = packet.lookahead<bit<16>>();
        meta.l4_lookup.word_1 = tmp_5[15:0];
        tmp_6 = packet.lookahead<bit<32>>();
        meta.l4_lookup.word_2 = tmp_6[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_3") state parse_ipv4_options_3 {
        packet.extract<option_word_t>(hdr.ipv4_option_word_1);
        packet.extract<option_word_t>(hdr.ipv4_option_word_2);
        packet.extract<option_word_t>(hdr.ipv4_option_word_3);
        tmp_7 = packet.lookahead<bit<16>>();
        meta.l4_lookup.word_1 = tmp_7[15:0];
        tmp_8 = packet.lookahead<bit<32>>();
        meta.l4_lookup.word_2 = tmp_8[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_4") state parse_ipv4_options_4 {
        packet.extract<option_word_t>(hdr.ipv4_option_word_1);
        packet.extract<option_word_t>(hdr.ipv4_option_word_2);
        packet.extract<option_word_t>(hdr.ipv4_option_word_3);
        packet.extract<option_word_t>(hdr.ipv4_option_word_4);
        tmp_9 = packet.lookahead<bit<16>>();
        meta.l4_lookup.word_1 = tmp_9[15:0];
        tmp_10 = packet.lookahead<bit<32>>();
        meta.l4_lookup.word_2 = tmp_10[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_5") state parse_ipv4_options_5 {
        packet.extract<option_word_t>(hdr.ipv4_option_word_1);
        packet.extract<option_word_t>(hdr.ipv4_option_word_2);
        packet.extract<option_word_t>(hdr.ipv4_option_word_3);
        packet.extract<option_word_t>(hdr.ipv4_option_word_4);
        packet.extract<option_word_t>(hdr.ipv4_option_word_5);
        tmp_11 = packet.lookahead<bit<16>>();
        meta.l4_lookup.word_1 = tmp_11[15:0];
        tmp_12 = packet.lookahead<bit<32>>();
        meta.l4_lookup.word_2 = tmp_12[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_6") state parse_ipv4_options_6 {
        packet.extract<option_word_t>(hdr.ipv4_option_word_1);
        packet.extract<option_word_t>(hdr.ipv4_option_word_2);
        packet.extract<option_word_t>(hdr.ipv4_option_word_3);
        packet.extract<option_word_t>(hdr.ipv4_option_word_4);
        packet.extract<option_word_t>(hdr.ipv4_option_word_5);
        packet.extract<option_word_t>(hdr.ipv4_option_word_6);
        tmp_13 = packet.lookahead<bit<16>>();
        meta.l4_lookup.word_1 = tmp_13[15:0];
        tmp_14 = packet.lookahead<bit<32>>();
        meta.l4_lookup.word_2 = tmp_14[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_7") state parse_ipv4_options_7 {
        packet.extract<option_word_t>(hdr.ipv4_option_word_1);
        packet.extract<option_word_t>(hdr.ipv4_option_word_2);
        packet.extract<option_word_t>(hdr.ipv4_option_word_3);
        packet.extract<option_word_t>(hdr.ipv4_option_word_4);
        packet.extract<option_word_t>(hdr.ipv4_option_word_5);
        packet.extract<option_word_t>(hdr.ipv4_option_word_6);
        packet.extract<option_word_t>(hdr.ipv4_option_word_7);
        tmp_15 = packet.lookahead<bit<16>>();
        meta.l4_lookup.word_1 = tmp_15[15:0];
        tmp_16 = packet.lookahead<bit<32>>();
        meta.l4_lookup.word_2 = tmp_16[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_8") state parse_ipv4_options_8 {
        packet.extract<option_word_t>(hdr.ipv4_option_word_1);
        packet.extract<option_word_t>(hdr.ipv4_option_word_2);
        packet.extract<option_word_t>(hdr.ipv4_option_word_3);
        packet.extract<option_word_t>(hdr.ipv4_option_word_4);
        packet.extract<option_word_t>(hdr.ipv4_option_word_5);
        packet.extract<option_word_t>(hdr.ipv4_option_word_6);
        packet.extract<option_word_t>(hdr.ipv4_option_word_7);
        packet.extract<option_word_t>(hdr.ipv4_option_word_8);
        tmp_17 = packet.lookahead<bit<16>>();
        meta.l4_lookup.word_1 = tmp_17[15:0];
        tmp_18 = packet.lookahead<bit<32>>();
        meta.l4_lookup.word_2 = tmp_18[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_9") state parse_ipv4_options_9 {
        packet.extract<option_word_t>(hdr.ipv4_option_word_1);
        packet.extract<option_word_t>(hdr.ipv4_option_word_2);
        packet.extract<option_word_t>(hdr.ipv4_option_word_3);
        packet.extract<option_word_t>(hdr.ipv4_option_word_4);
        packet.extract<option_word_t>(hdr.ipv4_option_word_5);
        packet.extract<option_word_t>(hdr.ipv4_option_word_6);
        packet.extract<option_word_t>(hdr.ipv4_option_word_7);
        packet.extract<option_word_t>(hdr.ipv4_option_word_8);
        packet.extract<option_word_t>(hdr.ipv4_option_word_9);
        tmp_19 = packet.lookahead<bit<16>>();
        meta.l4_lookup.word_1 = tmp_19[15:0];
        tmp_20 = packet.lookahead<bit<32>>();
        meta.l4_lookup.word_2 = tmp_20[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            default: accept;
        }
    }
    @name(".parse_ipv6") state parse_ipv6 {
        packet.extract<ipv6_t>(hdr.ipv6);
        tmp_21 = packet.lookahead<bit<16>>();
        meta.l4_lookup.word_1 = tmp_21[15:0];
        tmp_22 = packet.lookahead<bit<32>>();
        meta.l4_lookup.word_2 = tmp_22[15:0];
        transition select(hdr.ipv6.nextHdr) {
            8w0x1: parse_icmp;
            8w0x2: parse_igmp;
            8w0x6: parse_tcp_v6;
            8w0x11: parse_udp_v6;
            default: parse_first_fragment;
        }
    }
    @name(".parse_tcp_v4") state parse_tcp_v4 {
        packet.extract<tcp_t>(hdr.tcp);
        packet.extract<tcp_checksum_t>(hdr.tcp_checksum_v4);
        transition parse_first_fragment;
    }
    @name(".parse_tcp_v6") state parse_tcp_v6 {
        packet.extract<tcp_t>(hdr.tcp);
        packet.extract<tcp_checksum_t>(hdr.tcp_checksum_v6);
        transition parse_first_fragment;
    }
    @name(".parse_udp_v4") state parse_udp_v4 {
        packet.extract<udp_t>(hdr.udp);
        packet.extract<udp_checksum_t>(hdr.udp_checksum_v4);
        transition parse_first_fragment;
    }
    @name(".parse_udp_v6") state parse_udp_v6 {
        packet.extract<udp_t>(hdr.udp);
        packet.extract<udp_checksum_t>(hdr.udp_checksum_v6);
        transition parse_first_fragment;
    }
    @name(".parse_vlan_tag") state parse_vlan_tag {
        packet.extract<vlan_tag_t>(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.etherType) {
            16w0x8100: parse_vlan_tag;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            default: accept;
        }
    }
    @name(".start") state start {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x8100: parse_vlan_tag;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            default: accept;
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_4() {
    }
    @name(".NoAction") action NoAction_5() {
    }
    @name(".send") action send(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".send") action send_3(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".send") action send_4(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".send_with_ipv4_metadata") action send_with_ipv4_metadata(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
        meta.meta.ipv4_checksum_update = 1w1;
    }
    @name(".discard") action discard() {
        hdr.ig_intr_md_for_tm.drop_ctl = 3w1;
    }
    @name(".discard") action discard_3() {
        hdr.ig_intr_md_for_tm.drop_ctl = 3w1;
    }
    @name(".discard") action discard_4() {
        hdr.ig_intr_md_for_tm.drop_ctl = 3w1;
    }
    @name(".l3_forward") action l3_forward(bit<48> dmac, bit<48> smac, bit<9> port) {
        hdr.ethernet.dstAddr = dmac;
        hdr.ethernet.srcAddr = smac;
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".l3_forward") action l3_forward_2(bit<48> dmac, bit<48> smac, bit<9> port) {
        hdr.ethernet.dstAddr = dmac;
        hdr.ethernet.srcAddr = smac;
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".l3_forward_v4") action l3_forward_v4(bit<48> dmac, bit<48> smac, bit<9> port) {
        meta.meta.ipv4_checksum_update = 1w1;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
        hdr.ethernet.dstAddr = dmac;
        hdr.ethernet.srcAddr = smac;
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".nat_v4") action nat_v4(bit<32> sip, bit<32> dip, bit<8> ttl, bit<9> port) {
        hdr.ipv4.srcAddr = sip;
        hdr.ipv4.dstAddr = dip;
        hdr.ipv4.ttl = ttl;
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".tcp_nat_v4") action tcp_nat_v4(bit<32> sip, bit<32> dip, bit<8> ttl, bit<9> port, bit<16> sport, bit<16> dport) {
        meta.meta.ipv4_checksum_update = 1w1;
        meta.meta.ipv4_tcp_checksum_update = 1w1;
        meta.meta.ipv4_udp_checksum_update = 1w0;
        hdr.tcp.srcPort = sport;
        hdr.tcp.dstPort = dport;
        hdr.ipv4.srcAddr = sip;
        hdr.ipv4.dstAddr = dip;
        hdr.ipv4.ttl = ttl;
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".udp_nat_v4") action udp_nat_v4(bit<32> sip, bit<32> dip, bit<8> ttl, bit<9> port, bit<16> sport, bit<16> dport) {
        meta.meta.ipv4_checksum_update = 1w1;
        meta.meta.ipv4_tcp_checksum_update = 1w0;
        meta.meta.ipv4_udp_checksum_update = 1w1;
        hdr.udp.srcPort = sport;
        hdr.udp.dstPort = dport;
        hdr.ipv4.srcAddr = sip;
        hdr.ipv4.dstAddr = dip;
        hdr.ipv4.ttl = ttl;
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".l3_forward_v6") action l3_forward_v6(bit<48> dmac, bit<48> smac, bit<9> port) {
        hdr.ethernet.dstAddr = dmac;
        hdr.ethernet.srcAddr = smac;
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
        hdr.ipv6.hopLimit = hdr.ipv6.hopLimit + 8w255;
    }
    @name(".nat_v6") action nat_v6(bit<128> sip, bit<128> dip, bit<8> ttl, bit<9> port) {
        hdr.ipv6.srcAddr = sip;
        hdr.ipv6.dstAddr = dip;
        hdr.ipv6.hopLimit = ttl;
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".tcp_nat_v6") action tcp_nat_v6(bit<128> sip, bit<128> dip, bit<8> ttl, bit<9> port, bit<16> sport, bit<16> dport) {
        meta.meta.ipv6_tcp_checksum_update = 1w1;
        meta.meta.ipv6_udp_checksum_update = 1w0;
        hdr.tcp.srcPort = sport;
        hdr.tcp.dstPort = dport;
        hdr.ipv6.srcAddr = sip;
        hdr.ipv6.dstAddr = dip;
        hdr.ipv6.hopLimit = ttl;
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".udp_nat_v6") action udp_nat_v6(bit<128> sip, bit<128> dip, bit<8> ttl, bit<9> port, bit<16> sport, bit<16> dport) {
        meta.meta.ipv6_tcp_checksum_update = 1w0;
        meta.meta.ipv6_udp_checksum_update = 1w1;
        hdr.udp.srcPort = sport;
        hdr.udp.dstPort = dport;
        hdr.ipv6.srcAddr = sip;
        hdr.ipv6.dstAddr = dip;
        hdr.ipv6.hopLimit = ttl;
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".ipv4_acl") table ipv4_acl_0 {
        actions = {
            send();
            send_with_ipv4_metadata();
            discard();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.ipv4.srcAddr                                 : ternary @name("ipv4.srcAddr") ;
            hdr.ipv4.dstAddr                                 : ternary @name("ipv4.dstAddr") ;
            hdr.ig_intr_md_from_parser_aux.ingress_parser_err: ternary @name("ig_intr_md_from_parser_aux.ingress_parser_err") ;
        }
        size = 1024;
        default_action = NoAction_0();
    }
    @name(".ipv4_l4_acl") table ipv4_l4_acl_0 {
        actions = {
            send_3();
            discard_3();
            l3_forward_v4();
            l3_forward();
            nat_v4();
            tcp_nat_v4();
            udp_nat_v4();
            @defaultonly NoAction_4();
        }
        key = {
            hdr.ipv4.srcAddr                                 : ternary @name("ipv4.srcAddr") ;
            hdr.ipv4.dstAddr                                 : ternary @name("ipv4.dstAddr") ;
            hdr.ipv4.protocol                                : ternary @name("ipv4.protocol") ;
            meta.l4_lookup.word_1                            : ternary @name("l4_lookup.word_1") ;
            meta.l4_lookup.word_2                            : ternary @name("l4_lookup.word_2") ;
            meta.l4_lookup.first_frag                        : ternary @name("l4_lookup.first_frag") ;
            hdr.ig_intr_md_from_parser_aux.ingress_parser_err: ternary @name("ig_intr_md_from_parser_aux.ingress_parser_err") ;
        }
        size = 1024;
        default_action = NoAction_4();
    }
    @name(".ipv6_acl") table ipv6_acl_0 {
        actions = {
            send_4();
            discard_4();
            l3_forward_2();
            l3_forward_v6();
            nat_v6();
            tcp_nat_v6();
            udp_nat_v6();
            @defaultonly NoAction_5();
        }
        key = {
            hdr.ipv6.srcAddr                                 : exact @name("ipv6.srcAddr") ;
            hdr.ipv6.dstAddr                                 : exact @name("ipv6.dstAddr") ;
            hdr.ipv6.nextHdr                                 : exact @name("ipv6.nextHdr") ;
            meta.l4_lookup.word_1                            : ternary @name("l4_lookup.word_1") ;
            meta.l4_lookup.word_2                            : ternary @name("l4_lookup.word_2") ;
            meta.l4_lookup.first_frag                        : ternary @name("l4_lookup.first_frag") ;
            hdr.ig_intr_md_from_parser_aux.ingress_parser_err: ternary @name("ig_intr_md_from_parser_aux.ingress_parser_err") ;
        }
        size = 1024;
        default_action = NoAction_5();
    }
    apply {
        if (hdr.ipv4.isValid()) 
            if (hdr.tcp.isValid()) 
                ipv4_l4_acl_0.apply();
            else 
                if (hdr.udp.isValid()) 
                    ipv4_l4_acl_0.apply();
                else 
                    ipv4_acl_0.apply();
        else 
            if (hdr.ipv6.isValid()) 
                ipv6_acl_0.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<vlan_tag_t[2]>(hdr.vlan_tag);
        packet.emit<ipv6_t>(hdr.ipv6);
        packet.emit<ipv4_t>(hdr.ipv4);
        packet.emit<option_word_t>(hdr.ipv4_option_word_1);
        packet.emit<option_word_t>(hdr.ipv4_option_word_2);
        packet.emit<option_word_t>(hdr.ipv4_option_word_3);
        packet.emit<option_word_t>(hdr.ipv4_option_word_4);
        packet.emit<option_word_t>(hdr.ipv4_option_word_5);
        packet.emit<option_word_t>(hdr.ipv4_option_word_6);
        packet.emit<option_word_t>(hdr.ipv4_option_word_7);
        packet.emit<option_word_t>(hdr.ipv4_option_word_8);
        packet.emit<option_word_t>(hdr.ipv4_option_word_9);
        packet.emit<option_word_t>(hdr.ipv4_option_word_10);
        packet.emit<udp_t>(hdr.udp);
        packet.emit<udp_checksum_t>(hdr.udp_checksum_v6);
        packet.emit<udp_checksum_t>(hdr.udp_checksum_v4);
        packet.emit<tcp_t>(hdr.tcp);
        packet.emit<tcp_checksum_t>(hdr.tcp_checksum_v6);
        packet.emit<tcp_checksum_t>(hdr.tcp_checksum_v4);
        packet.emit<igmp_t>(hdr.igmp);
        packet.emit<icmp_t>(hdr.icmp);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
        verify_checksum<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>, bit<32>, bit<32>, bit<32>, bit<32>, bit<32>, bit<32>, bit<32>, bit<32>, bit<32>, bit<32>>, bit<16>>(true, { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4_option_word_1.data, hdr.ipv4_option_word_2.data, hdr.ipv4_option_word_3.data, hdr.ipv4_option_word_4.data, hdr.ipv4_option_word_5.data, hdr.ipv4_option_word_6.data, hdr.ipv4_option_word_7.data, hdr.ipv4_option_word_8.data, hdr.ipv4_option_word_9.data, hdr.ipv4_option_word_10.data }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
        update_checksum<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>, bit<32>, bit<32>, bit<32>, bit<32>, bit<32>, bit<32>, bit<32>, bit<32>, bit<32>, bit<32>>, bit<16>>(meta.meta.ipv4_checksum_update == 1w1, { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4_option_word_1.data, hdr.ipv4_option_word_2.data, hdr.ipv4_option_word_3.data, hdr.ipv4_option_word_4.data, hdr.ipv4_option_word_5.data, hdr.ipv4_option_word_6.data, hdr.ipv4_option_word_7.data, hdr.ipv4_option_word_8.data, hdr.ipv4_option_word_9.data, hdr.ipv4_option_word_10.data }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
        update_checksum_with_payload<tuple<bit<32>, bit<32>, bit<8>, bit<8>, bit<16>, bit<16>, bit<16>, bit<32>, bit<32>, bit<4>, bit<4>, bit<8>, bit<16>, bit<16>>, bit<16>>(true, { hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, 8w0, hdr.ipv4.protocol, hdr.ipv4.totalLen, hdr.tcp.srcPort, hdr.tcp.dstPort, hdr.tcp.seqNo, hdr.tcp.ackNo, hdr.tcp.dataOffset, hdr.tcp.res, hdr.tcp.flags, hdr.tcp.window, hdr.tcp_checksum_v4.urgentPtr }, hdr.tcp_checksum_v4.checksum, HashAlgorithm.csum16);
        update_checksum_with_payload<tuple<bit<128>, bit<128>, bit<16>, bit<8>, bit<8>, bit<16>, bit<16>, bit<32>, bit<32>, bit<4>, bit<4>, bit<8>, bit<16>, bit<16>>, bit<16>>(true, { hdr.ipv6.srcAddr, hdr.ipv6.dstAddr, hdr.ipv6.payloadLen, 8w0, hdr.ipv6.nextHdr, hdr.tcp.srcPort, hdr.tcp.dstPort, hdr.tcp.seqNo, hdr.tcp.ackNo, hdr.tcp.dataOffset, hdr.tcp.res, hdr.tcp.flags, hdr.tcp.window, hdr.tcp_checksum_v6.urgentPtr }, hdr.tcp_checksum_v6.checksum, HashAlgorithm.csum16);
        update_checksum_with_payload<tuple<bit<32>, bit<32>, bit<8>, bit<8>, bit<16>, bit<16>, bit<16>>, bit<16>>(true, { hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, 8w0, hdr.ipv4.protocol, hdr.ipv4.totalLen, hdr.udp.srcPort, hdr.udp.dstPort }, hdr.udp_checksum_v4.checksum, HashAlgorithm.csum16);
        update_checksum_with_payload<tuple<bit<128>, bit<128>, bit<16>, bit<8>, bit<8>, bit<16>, bit<16>>, bit<16>>(true, { hdr.ipv6.srcAddr, hdr.ipv6.dstAddr, hdr.ipv6.payloadLen, 8w0, hdr.ipv6.nextHdr, hdr.udp.srcPort, hdr.udp.dstPort }, hdr.udp_checksum_v6.checksum, HashAlgorithm.csum16);
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

