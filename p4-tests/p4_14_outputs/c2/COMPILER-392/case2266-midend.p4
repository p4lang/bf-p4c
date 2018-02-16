#include <core.p4>
#include <v1model.p4>

struct ebmeta_t {
    bit<8>  current_offset;
    bit<8>  mpls_offset;
    bit<8>  ip1_offset;
    bit<8>  ip2_offset;
    bit<16> port_hash;
    bit<8>  lanwan_out_port;
    bit<16> dpi_port;
    bit<1>  is_nat;
    bit<1>  is_lan;
    bit<3>  port_type;
    bit<2>  useless1;
    bit<8>  dpi_queue;
    bit<16> mirror_port;
}

header ebheader_t {
    bit<16> unused1;
    bit<8>  dst_main_agg;
    bit<8>  dst_main_dpi;
    bit<16> dst_mirror;
    bit<8>  unused2;
    bit<6>  flags_unused_bits;
    bit<1>  is_nat;
    bit<1>  is_lan;
    bit<8>  offset_ip1;
    bit<8>  offset_ip2;
    bit<8>  offset_mpls;
    bit<8>  offset_payload;
    bit<8>  ethertype_eb;
    bit<8>  rss_queue;
    bit<32> hash1;
    bit<32> hash2;
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
    bit<5> _pad;
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
    bit<4>   ver;
    bit<8>   tclass;
    bit<20>  flowl;
    bit<16>  payloadLen;
    bit<8>   nextHeader;
    bit<8>   hopLimit;
    bit<128> srcAddr;
    bit<128> dstAddr;
}

header mpls_cw_t {
    bit<32> useless;
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

header pppoe_t {
    bit<4>  version;
    bit<4>  ptype;
    bit<8>  code;
    bit<16> session;
    bit<16> payloadLen;
    bit<16> protocol;
}

header sctp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> tag;
    bit<32> csum;
}

header skip_12_t {
    bit<96> useless;
}

header skip_16_t {
    bit<128> useless;
}

header skip_20_t {
    bit<160> useless;
}

header skip_24_t {
    bit<192> useless;
}

header skip_28_t {
    bit<224> useless;
}

header skip_32_t {
    bit<256> useless;
}

header skip_36_t {
    bit<288> useless;
}

header skip_40_t {
    bit<320> useless;
}

header skip_4_t {
    bit<32> useless;
}

header skip_8_t {
    bit<64> useless;
}

header tcp_t {
    bit<16> portSrc;
    bit<16> portDst;
    bit<32> seqNum;
    bit<32> ackNum;
    bit<4>  headerLen;
    bit<6>  reserved;
    bit<6>  controlBits;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    bit<16> portSrc;
    bit<16> portDst;
    bit<16> len;
    bit<16> csum;
}

header udplite_t {
    bit<16> portSrc;
    bit<16> portDst;
    bit<16> ccover;
    bit<16> csum;
}

header mpls_t {
    bit<20> label;
    bit<3>  tclass;
    bit<1>  bottom;
    bit<8>  ttl;
}

header vlan_t {
    bit<3>  prio;
    bit<1>  cfi;
    bit<12> id;
    bit<16> etherType;
}

struct metadata {
    @name(".ebmeta") 
    ebmeta_t ebmeta;
}

struct headers {
    @name(".ebheader") 
    ebheader_t                                     ebheader;
    @dont_trim @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md") @pa_atomic("egress", "eg_intr_md.egress_port") @pa_fragment("egress", "eg_intr_md._pad1") @pa_fragment("egress", "eg_intr_md._pad7") @pa_fragment("egress", "eg_intr_md._pad8") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_port") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_cos") @name(".eg_intr_md") 
    egress_intrinsic_metadata_t                    eg_intr_md;
    @dont_trim @pa_intrinsic_header("egress", "eg_intr_md_for_mb") @pa_atomic("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_fragment("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_length") @not_deparsed("ingress") @not_deparsed("egress") @name(".eg_intr_md_for_mb") 
    egress_intrinsic_metadata_for_mirror_buffer_t  eg_intr_md_for_mb;
    @dont_trim @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_oport.drop_ctl") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_for_oport") @name(".eg_intr_md_for_oport") 
    egress_intrinsic_metadata_for_output_port_t    eg_intr_md_for_oport;
    @pa_fragment("egress", "eg_intr_md_from_parser_aux.coalesce_sample_count") @pa_fragment("egress", "eg_intr_md_from_parser_aux.clone_src") @pa_fragment("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @pa_atomic("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_from_parser_aux") @name(".eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t    eg_intr_md_from_parser_aux;
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
    ethernet_t_0                                   inner_ethernet;
    @name(".inner_ipv4") 
    ipv4_t                                         inner_ipv4;
    @name(".inner_ipv6") 
    ipv6_t                                         inner_ipv6;
    @name(".mpls_cw") 
    mpls_cw_t                                      mpls_cw;
    @name(".outer_ethernet") 
    ethernet_t_0                                   outer_ethernet;
    @name(".outer_ipv4") 
    ipv4_t                                         outer_ipv4;
    @name(".outer_ipv6") 
    ipv6_t                                         outer_ipv6;
    @name(".pktgen_generic") 
    pktgen_generic_header_t                        pktgen_generic;
    @name(".pktgen_port_down") 
    pktgen_port_down_header_t                      pktgen_port_down;
    @name(".pktgen_recirc") 
    pktgen_recirc_header_t                         pktgen_recirc;
    @name(".pktgen_timer") 
    pktgen_timer_header_t                          pktgen_timer;
    @name(".pppoe") 
    pppoe_t                                        pppoe;
    @name(".sctp") 
    sctp_t                                         sctp;
    @name(".skip_12_i") 
    skip_12_t                                      skip_12_i;
    @name(".skip_12_o") 
    skip_12_t                                      skip_12_o;
    @name(".skip_16_i") 
    skip_16_t                                      skip_16_i;
    @name(".skip_16_o") 
    skip_16_t                                      skip_16_o;
    @name(".skip_20_i") 
    skip_20_t                                      skip_20_i;
    @name(".skip_20_o") 
    skip_20_t                                      skip_20_o;
    @name(".skip_24_i") 
    skip_24_t                                      skip_24_i;
    @name(".skip_24_o") 
    skip_24_t                                      skip_24_o;
    @name(".skip_28_i") 
    skip_28_t                                      skip_28_i;
    @name(".skip_28_o") 
    skip_28_t                                      skip_28_o;
    @name(".skip_32_i") 
    skip_32_t                                      skip_32_i;
    @name(".skip_32_o") 
    skip_32_t                                      skip_32_o;
    @name(".skip_36_i") 
    skip_36_t                                      skip_36_i;
    @name(".skip_36_o") 
    skip_36_t                                      skip_36_o;
    @name(".skip_40_i") 
    skip_40_t                                      skip_40_i;
    @name(".skip_40_o") 
    skip_40_t                                      skip_40_o;
    @name(".skip_4_i") 
    skip_4_t                                       skip_4_i;
    @name(".skip_4_o") 
    skip_4_t                                       skip_4_o;
    @name(".skip_8_i") 
    skip_8_t                                       skip_8_i;
    @name(".skip_8_o") 
    skip_8_t                                       skip_8_o;
    @name(".tcp") 
    tcp_t                                          tcp;
    @name(".udp") 
    udp_t                                          udp;
    @name(".udplite") 
    udplite_t                                      udplite;
    @name(".mpls") 
    mpls_t[5]                                      mpls;
    @name(".outer_vlan") 
    vlan_t[5]                                      outer_vlan;
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<80> tmp_4;
    bit<56> tmp_5;
    bit<104> tmp_6;
    bit<8> tmp_7;
    bit<8> tmp_8;
    @name(".cw_try_ipv4") state cw_try_ipv4 {
        tmp_4 = packet.lookahead<bit<80>>();
        transition select(tmp_4[7:0]) {
            8w0x4: parse_outer_ipv4;
            8w0x29: parse_outer_ipv4;
            8w0x88: parse_outer_ipv4;
            8w0x84: parse_outer_ipv4;
            8w0x6: parse_outer_ipv4;
            8w0x11: parse_outer_ipv4;
            8w0x2f: parse_outer_ipv4;
            default: parse_inner_ethernet;
        }
    }
    @name(".cw_try_ipv6") state cw_try_ipv6 {
        tmp_5 = packet.lookahead<bit<56>>();
        transition select(tmp_5[7:0]) {
            8w0x4: parse_outer_ipv6;
            8w0x29: parse_outer_ipv6;
            8w0x88: parse_outer_ipv6;
            8w0x84: parse_outer_ipv6;
            8w0x6: parse_outer_ipv6;
            8w0x11: parse_outer_ipv6;
            8w0x2f: parse_outer_ipv6;
            8w0: parse_outer_ipv6;
            8w43: parse_outer_ipv6;
            8w44: parse_outer_ipv6;
            8w50: parse_outer_ipv6;
            8w51: parse_outer_ipv6;
            8w60: parse_outer_ipv6;
            8w135: parse_outer_ipv6;
            8w59: parse_outer_ipv6;
            default: parse_inner_ethernet;
        }
    }
    @name(".determine_first_parser") state determine_first_parser {
        tmp_6 = packet.lookahead<bit<104>>();
        transition select(tmp_6[7:0]) {
            8w0xec: accept;
            8w0xeb: parse_ebheader;
            default: parse_outer_ethernet;
        }
    }
    @name(".inner_ipv4_determine_after") state inner_ipv4_determine_after {
        transition select(hdr.inner_ipv4.protocol) {
            8w0x88: parse_udplite;
            8w0x84: parse_sctp;
            8w0x6: parse_tcp;
            8w0x11: parse_udp;
            default: accept;
        }
    }
    @name(".inner_ipv4_determine_after_skip_12") state inner_ipv4_determine_after_skip_12 {
        packet.extract<skip_12_t>(hdr.skip_12_i);
        transition inner_ipv4_determine_after;
    }
    @name(".inner_ipv4_determine_after_skip_16") state inner_ipv4_determine_after_skip_16 {
        packet.extract<skip_16_t>(hdr.skip_16_i);
        transition inner_ipv4_determine_after;
    }
    @name(".inner_ipv4_determine_after_skip_20") state inner_ipv4_determine_after_skip_20 {
        packet.extract<skip_20_t>(hdr.skip_20_i);
        transition inner_ipv4_determine_after;
    }
    @name(".inner_ipv4_determine_after_skip_24") state inner_ipv4_determine_after_skip_24 {
        packet.extract<skip_24_t>(hdr.skip_24_i);
        transition inner_ipv4_determine_after;
    }
    @name(".inner_ipv4_determine_after_skip_28") state inner_ipv4_determine_after_skip_28 {
        packet.extract<skip_28_t>(hdr.skip_28_i);
        transition inner_ipv4_determine_after;
    }
    @name(".inner_ipv4_determine_after_skip_32") state inner_ipv4_determine_after_skip_32 {
        packet.extract<skip_32_t>(hdr.skip_32_i);
        transition inner_ipv4_determine_after;
    }
    @name(".inner_ipv4_determine_after_skip_36") state inner_ipv4_determine_after_skip_36 {
        packet.extract<skip_36_t>(hdr.skip_36_i);
        transition inner_ipv4_determine_after;
    }
    @name(".inner_ipv4_determine_after_skip_4") state inner_ipv4_determine_after_skip_4 {
        packet.extract<skip_4_t>(hdr.skip_4_i);
        transition inner_ipv4_determine_after;
    }
    @name(".inner_ipv4_determine_after_skip_40") state inner_ipv4_determine_after_skip_40 {
        packet.extract<skip_40_t>(hdr.skip_40_i);
        transition inner_ipv4_determine_after;
    }
    @name(".inner_ipv4_determine_after_skip_8") state inner_ipv4_determine_after_skip_8 {
        packet.extract<skip_8_t>(hdr.skip_8_i);
        transition inner_ipv4_determine_after;
    }
    @name(".outer_ipv4_determine_after") state outer_ipv4_determine_after {
        transition select(hdr.outer_ipv4.protocol) {
            8w0x4: parse_inner_ipv4;
            8w0x29: parse_inner_ipv6;
            8w0x88: parse_udplite;
            8w0x84: parse_sctp;
            8w0x6: parse_tcp;
            8w0x11: parse_udp;
            default: accept;
        }
    }
    @name(".outer_ipv4_determine_after_skip_12") state outer_ipv4_determine_after_skip_12 {
        packet.extract<skip_12_t>(hdr.skip_12_o);
        transition outer_ipv4_determine_after;
    }
    @name(".outer_ipv4_determine_after_skip_16") state outer_ipv4_determine_after_skip_16 {
        packet.extract<skip_16_t>(hdr.skip_16_o);
        transition outer_ipv4_determine_after;
    }
    @name(".outer_ipv4_determine_after_skip_20") state outer_ipv4_determine_after_skip_20 {
        packet.extract<skip_20_t>(hdr.skip_20_o);
        transition outer_ipv4_determine_after;
    }
    @name(".outer_ipv4_determine_after_skip_24") state outer_ipv4_determine_after_skip_24 {
        packet.extract<skip_24_t>(hdr.skip_24_o);
        transition outer_ipv4_determine_after;
    }
    @name(".outer_ipv4_determine_after_skip_28") state outer_ipv4_determine_after_skip_28 {
        packet.extract<skip_28_t>(hdr.skip_28_o);
        transition outer_ipv4_determine_after;
    }
    @name(".outer_ipv4_determine_after_skip_32") state outer_ipv4_determine_after_skip_32 {
        packet.extract<skip_32_t>(hdr.skip_32_o);
        transition outer_ipv4_determine_after;
    }
    @name(".outer_ipv4_determine_after_skip_36") state outer_ipv4_determine_after_skip_36 {
        packet.extract<skip_36_t>(hdr.skip_36_o);
        transition outer_ipv4_determine_after;
    }
    @name(".outer_ipv4_determine_after_skip_4") state outer_ipv4_determine_after_skip_4 {
        packet.extract<skip_4_t>(hdr.skip_4_o);
        transition outer_ipv4_determine_after;
    }
    @name(".outer_ipv4_determine_after_skip_40") state outer_ipv4_determine_after_skip_40 {
        packet.extract<skip_40_t>(hdr.skip_40_o);
        transition outer_ipv4_determine_after;
    }
    @name(".outer_ipv4_determine_after_skip_8") state outer_ipv4_determine_after_skip_8 {
        packet.extract<skip_8_t>(hdr.skip_8_o);
        transition outer_ipv4_determine_after;
    }
    @name(".parse_ebheader") state parse_ebheader {
        packet.extract<ebheader_t>(hdr.ebheader);
        transition parse_fake_ethernet;
    }
    @name(".parse_fake_ethernet") state parse_fake_ethernet {
        packet.extract<ethernet_t_0>(hdr.outer_ethernet);
        transition accept;
    }
    @name(".parse_inner_ethernet") state parse_inner_ethernet {
        packet.extract<ethernet_t_0>(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.etherType) {
            16w0x800: parse_outer_ipv4;
            16w0x86dd: parse_outer_ipv6;
            16w0x8864: parse_pppoe;
            default: accept;
        }
    }
    @name(".parse_inner_ipv4") state parse_inner_ipv4 {
        packet.extract<ipv4_t>(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.ihl) {
            4w0x6: inner_ipv4_determine_after_skip_4;
            4w0x7: inner_ipv4_determine_after_skip_8;
            4w0x8: inner_ipv4_determine_after_skip_12;
            4w0x9: inner_ipv4_determine_after_skip_16;
            4w0xa: inner_ipv4_determine_after_skip_20;
            4w0xb: inner_ipv4_determine_after_skip_24;
            4w0xc: inner_ipv4_determine_after_skip_28;
            4w0xd: inner_ipv4_determine_after_skip_32;
            4w0xe: inner_ipv4_determine_after_skip_36;
            4w0xf: inner_ipv4_determine_after_skip_40;
            default: inner_ipv4_determine_after;
        }
    }
    @name(".parse_inner_ipv6") state parse_inner_ipv6 {
        packet.extract<ipv6_t>(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.nextHeader) {
            8w0x88: parse_udplite;
            8w0x84: parse_sctp;
            8w0x6: parse_tcp;
            8w0x11: parse_udp;
            default: accept;
        }
    }
    @name(".parse_mpls") state parse_mpls {
        packet.extract<mpls_t>(hdr.mpls.next);
        transition select(hdr.mpls.last.bottom) {
            1w0: parse_mpls;
            1w1: parse_mpls_cw_determine;
            default: accept;
        }
    }
    @name(".parse_mpls_cw") state parse_mpls_cw {
        packet.extract<mpls_cw_t>(hdr.mpls_cw);
        tmp_7 = packet.lookahead<bit<8>>();
        transition select(tmp_7[7:0]) {
            8w0x45: cw_try_ipv4;
            8w0x46 &&& 8w0xfe: cw_try_ipv4;
            8w0x48 &&& 8w0xf8: cw_try_ipv4;
            8w0x60 &&& 8w0xf0: cw_try_ipv6;
            default: parse_inner_ethernet;
        }
    }
    @name(".parse_mpls_cw_determine") state parse_mpls_cw_determine {
        tmp_8 = packet.lookahead<bit<8>>();
        transition select(tmp_8[7:0]) {
            8w0x0: parse_mpls_cw;
            8w0x45: cw_try_ipv4;
            8w0x46 &&& 8w0xfe: cw_try_ipv4;
            8w0x48 &&& 8w0xf8: cw_try_ipv4;
            8w0x60 &&& 8w0xf0: cw_try_ipv6;
            default: parse_inner_ethernet;
        }
    }
    @name(".parse_outer_ethernet") state parse_outer_ethernet {
        packet.extract<ethernet_t_0>(hdr.outer_ethernet);
        transition select(hdr.outer_ethernet.etherType) {
            16w0x8100: parse_outer_vlan;
            16w0x88a8: parse_outer_vlan;
            16w0x9200: parse_outer_vlan;
            16w0x9100: parse_outer_vlan;
            16w0x8847: parse_mpls;
            16w0x8848: parse_mpls;
            16w0x800: parse_outer_ipv4;
            16w0x86dd: parse_outer_ipv6;
            16w0x8864: parse_pppoe;
            default: accept;
        }
    }
    @name(".parse_outer_ipv4") state parse_outer_ipv4 {
        packet.extract<ipv4_t>(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.ihl) {
            4w0x6: outer_ipv4_determine_after_skip_4;
            4w0x7: outer_ipv4_determine_after_skip_8;
            4w0x8: outer_ipv4_determine_after_skip_12;
            4w0x9: outer_ipv4_determine_after_skip_16;
            4w0xa: outer_ipv4_determine_after_skip_20;
            4w0xb: outer_ipv4_determine_after_skip_24;
            4w0xc: outer_ipv4_determine_after_skip_28;
            4w0xd: outer_ipv4_determine_after_skip_32;
            4w0xe: outer_ipv4_determine_after_skip_36;
            4w0xf: outer_ipv4_determine_after_skip_40;
            default: outer_ipv4_determine_after;
        }
    }
    @name(".parse_outer_ipv6") state parse_outer_ipv6 {
        packet.extract<ipv6_t>(hdr.outer_ipv6);
        transition select(hdr.outer_ipv6.nextHeader) {
            8w0x4: parse_inner_ipv4;
            8w0x29: parse_inner_ipv6;
            8w0x88: parse_udplite;
            8w0x84: parse_sctp;
            8w0x6: parse_tcp;
            8w0x11: parse_udp;
            default: accept;
        }
    }
    @name(".parse_outer_vlan") state parse_outer_vlan {
        packet.extract<vlan_t>(hdr.outer_vlan.next);
        transition select(hdr.outer_vlan.last.etherType) {
            16w0x8100: parse_outer_vlan;
            16w0x88a8: parse_outer_vlan;
            16w0x9200: parse_outer_vlan;
            16w0x9100: parse_outer_vlan;
            16w0x8847: parse_mpls;
            16w0x8848: parse_mpls;
            16w0x800: parse_outer_ipv4;
            16w0x86dd: parse_outer_ipv6;
            16w0x8864: parse_pppoe;
            default: accept;
        }
    }
    @name(".parse_pppoe") state parse_pppoe {
        packet.extract<pppoe_t>(hdr.pppoe);
        transition select(hdr.pppoe.protocol) {
            16w0x21: parse_outer_ipv4;
            16w0x57: parse_outer_ipv6;
            default: accept;
        }
    }
    @name(".parse_sctp") state parse_sctp {
        packet.extract<sctp_t>(hdr.sctp);
        transition accept;
    }
    @name(".parse_tcp") state parse_tcp {
        packet.extract<tcp_t>(hdr.tcp);
        transition accept;
    }
    @name(".parse_udp") state parse_udp {
        packet.extract<udp_t>(hdr.udp);
        transition accept;
    }
    @name(".parse_udplite") state parse_udplite {
        packet.extract<udplite_t>(hdr.udplite);
        transition accept;
    }
    @name(".start") state start {
        transition determine_first_parser;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_1() {
    }
    @name(".do_add_ebheader") action do_add_ebheader_0() {
        hdr.ebheader.setValid();
        hdr.ebheader.ethertype_eb = 8w0xeb;
        hdr.ebheader.dst_main_dpi = meta.ebmeta.lanwan_out_port;
        hdr.ebheader.is_nat = meta.ebmeta.is_nat;
        hdr.ebheader.rss_queue = meta.ebmeta.dpi_queue;
        hdr.ebheader.offset_mpls = meta.ebmeta.mpls_offset;
        hdr.ebheader.offset_payload = meta.ebmeta.current_offset;
        hdr.ebheader.offset_ip1 = meta.ebmeta.ip1_offset;
        hdr.ebheader.offset_ip2 = meta.ebmeta.ip2_offset;
    }
    @name("._nop") action _nop_0() {
    }
    @name("._nop") action _nop_1() {
    }
    @name(".do_remove_ebheader") action do_remove_ebheader_0() {
        meta.ebmeta.mirror_port = hdr.ebheader.dst_mirror;
        hdr.ebheader.setInvalid();
    }
    @name(".add_ebheader") table add_ebheader {
        actions = {
            do_add_ebheader_0();
            _nop_0();
            @defaultonly NoAction_0();
        }
        key = {
            meta.ebmeta.port_type: exact @name("ebmeta.port_type") ;
        }
        default_action = NoAction_0();
    }
    @name(".remove_ebheader") table remove_ebheader {
        actions = {
            do_remove_ebheader_0();
            _nop_1();
            @defaultonly NoAction_1();
        }
        key = {
            meta.ebmeta.port_type: exact @name("ebmeta.port_type") ;
        }
        default_action = NoAction_1();
    }
    apply {
        add_ebheader.apply();
        remove_ebheader.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_6() {
    }
    @name(".NoAction") action NoAction_7() {
    }
    @name(".set_nat_lanwan_flag_and_linked_port") action set_nat_lanwan_flag_and_linked_port_0(bit<1> is_lan, bit<1> is_nat, bit<8> linked_port) {
        meta.ebmeta.is_lan = is_lan;
        meta.ebmeta.is_nat = is_nat;
        meta.ebmeta.lanwan_out_port = linked_port;
    }
    @name("._nop") action _nop_4() {
    }
    @name(".set_port_type") action set_port_type_0(bit<3> port_type) {
        meta.ebmeta.port_type = port_type;
    }
    @name("._drop") action _drop_0() {
        mark_to_drop();
    }
    @name(".determine_nat_lanwan_flag_and_linked_port") table determine_nat_lanwan_flag_and_linked_port {
        actions = {
            set_nat_lanwan_flag_and_linked_port_0();
            _nop_4();
            @defaultonly NoAction_6();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        default_action = NoAction_6();
    }
    @name(".determine_port_type") table determine_port_type {
        actions = {
            set_port_type_0();
            _drop_0();
            @defaultonly NoAction_7();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        default_action = NoAction_7();
    }
    apply {
        determine_port_type.apply();
        determine_nat_lanwan_flag_and_linked_port.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ebheader_t>(hdr.ebheader);
        packet.emit<ethernet_t_0>(hdr.outer_ethernet);
        packet.emit<vlan_t>(hdr.outer_vlan[0]);
        packet.emit<vlan_t>(hdr.outer_vlan[1]);
        packet.emit<vlan_t>(hdr.outer_vlan[2]);
        packet.emit<vlan_t>(hdr.outer_vlan[3]);
        packet.emit<vlan_t>(hdr.outer_vlan[4]);
        packet.emit<mpls_t>(hdr.mpls[0]);
        packet.emit<mpls_t>(hdr.mpls[1]);
        packet.emit<mpls_t>(hdr.mpls[2]);
        packet.emit<mpls_t>(hdr.mpls[3]);
        packet.emit<mpls_t>(hdr.mpls[4]);
        packet.emit<mpls_cw_t>(hdr.mpls_cw);
        packet.emit<ethernet_t_0>(hdr.inner_ethernet);
        packet.emit<pppoe_t>(hdr.pppoe);
        packet.emit<ipv6_t>(hdr.outer_ipv6);
        packet.emit<ipv4_t>(hdr.outer_ipv4);
        packet.emit<skip_40_t>(hdr.skip_40_o);
        packet.emit<skip_36_t>(hdr.skip_36_o);
        packet.emit<skip_32_t>(hdr.skip_32_o);
        packet.emit<skip_28_t>(hdr.skip_28_o);
        packet.emit<skip_24_t>(hdr.skip_24_o);
        packet.emit<skip_20_t>(hdr.skip_20_o);
        packet.emit<skip_16_t>(hdr.skip_16_o);
        packet.emit<skip_12_t>(hdr.skip_12_o);
        packet.emit<skip_8_t>(hdr.skip_8_o);
        packet.emit<skip_4_t>(hdr.skip_4_o);
        packet.emit<ipv6_t>(hdr.inner_ipv6);
        packet.emit<ipv4_t>(hdr.inner_ipv4);
        packet.emit<skip_40_t>(hdr.skip_40_i);
        packet.emit<skip_36_t>(hdr.skip_36_i);
        packet.emit<skip_32_t>(hdr.skip_32_i);
        packet.emit<skip_28_t>(hdr.skip_28_i);
        packet.emit<skip_24_t>(hdr.skip_24_i);
        packet.emit<skip_20_t>(hdr.skip_20_i);
        packet.emit<skip_16_t>(hdr.skip_16_i);
        packet.emit<skip_12_t>(hdr.skip_12_i);
        packet.emit<skip_8_t>(hdr.skip_8_i);
        packet.emit<skip_4_t>(hdr.skip_4_i);
        packet.emit<udp_t>(hdr.udp);
        packet.emit<tcp_t>(hdr.tcp);
        packet.emit<sctp_t>(hdr.sctp);
        packet.emit<udplite_t>(hdr.udplite);
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

