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
    bit<1>  is_banan;
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
    bit<1>  is_banan;
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
    bit<5> _pad1;
    bit<8> parser_counter;
}

header mpls_cw_t {
    bit<32> useless;
}

@name("ethernet_t") header ethernet_t_0 {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
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
    @name(".mpls_cw") 
    mpls_cw_t                                      mpls_cw;
    @name(".outer_ethernet") 
    ethernet_t_0                                   outer_ethernet;
    @name(".pktgen_generic") 
    pktgen_generic_header_t                        pktgen_generic;
    @name(".pktgen_port_down") 
    pktgen_port_down_header_t                      pktgen_port_down;
    @name(".pktgen_recirc") 
    pktgen_recirc_header_t                         pktgen_recirc;
    @name(".pktgen_timer") 
    pktgen_timer_header_t                          pktgen_timer;
    @name(".mpls") 
    mpls_t[5]                                      mpls;
    @name(".outer_vlan") 
    vlan_t[5]                                      outer_vlan;
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<80> tmp;
    bit<56> tmp_0;
    bit<104> tmp_1;
    bit<8> tmp_2;
    bit<8> tmp_3;
    @name(".cw_try_ipv4") state cw_try_ipv4 {
        tmp = packet.lookahead<bit<80>>();
        transition select(tmp[7:0]) {
            default: accept;
        }
    }
    @name(".cw_try_ipv6") state cw_try_ipv6 {
        tmp_0 = packet.lookahead<bit<56>>();
        transition select(tmp_0[7:0]) {
            default: accept;
        }
    }
    @name(".determine_first_parser") state determine_first_parser {
        tmp_1 = packet.lookahead<bit<104>>();
        transition select(tmp_1[7:0]) {
            8w0xec: accept;
            8w0xeb: parse_ebheader;
            default: parse_outer_ethernet;
        }
    }
    @name(".parse_ebheader") state parse_ebheader {
        packet.extract<ebheader_t>(hdr.ebheader);
        transition parse_fake_ethernet;
    }
    @name(".parse_fake_ethernet") state parse_fake_ethernet {
        packet.extract<ethernet_t_0>(hdr.outer_ethernet);
        transition accept;
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
        tmp_2 = packet.lookahead<bit<8>>();
        transition select(tmp_2[7:0]) {
            8w0x45: cw_try_ipv4;
            8w0x46 &&& 8w0xfe: cw_try_ipv4;
            8w0x48 &&& 8w0xf8: cw_try_ipv4;
            8w0x60 &&& 8w0xf0: cw_try_ipv6;
            default: accept;
        }
    }
    @name(".parse_mpls_cw_determine") state parse_mpls_cw_determine {
        tmp_3 = packet.lookahead<bit<8>>();
        transition select(tmp_3[7:0]) {
            8w0x0: parse_mpls_cw;
            8w0x45: cw_try_ipv4;
            8w0x46 &&& 8w0xfe: cw_try_ipv4;
            8w0x48 &&& 8w0xf8: cw_try_ipv4;
            8w0x60 &&& 8w0xf0: cw_try_ipv6;
            default: accept;
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
            default: accept;
        }
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
    @name(".do_add_ebheader") action do_add_ebheader() {
        hdr.ebheader.setValid();
        hdr.ebheader.ethertype_eb = 8w0xeb;
        hdr.ebheader.dst_main_dpi = meta.ebmeta.lanwan_out_port;
        hdr.ebheader.is_nat = meta.ebmeta.is_nat;
        hdr.ebheader.is_banan = meta.ebmeta.is_banan;
        hdr.ebheader.rss_queue = meta.ebmeta.dpi_queue;
        hdr.ebheader.offset_mpls = meta.ebmeta.mpls_offset;
        hdr.ebheader.offset_payload = meta.ebmeta.current_offset;
        hdr.ebheader.offset_ip1 = meta.ebmeta.ip1_offset;
        hdr.ebheader.offset_ip2 = meta.ebmeta.ip2_offset;
    }
    @name("._nop") action _nop() {
    }
    @name("._nop") action _nop_2() {
    }
    @name(".do_remove_ebheader") action do_remove_ebheader() {
        meta.ebmeta.mirror_port = hdr.ebheader.dst_mirror;
        hdr.ebheader.setInvalid();
    }
    @name(".add_ebheader") table add_ebheader_0 {
        actions = {
            do_add_ebheader();
            _nop();
            @defaultonly NoAction_0();
        }
        key = {
            meta.ebmeta.port_type: exact @name("ebmeta.port_type") ;
        }
        default_action = NoAction_0();
    }
    @name(".remove_ebheader") table remove_ebheader_0 {
        actions = {
            do_remove_ebheader();
            _nop_2();
            @defaultonly NoAction_1();
        }
        key = {
            meta.ebmeta.port_type: exact @name("ebmeta.port_type") ;
        }
        default_action = NoAction_1();
    }
    apply {
        add_ebheader_0.apply();
        remove_ebheader_0.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_6() {
    }
    @name(".NoAction") action NoAction_7() {
    }
    @name(".set_nat_lanwan_flag_and_linked_port") action set_nat_lanwan_flag_and_linked_port(bit<1> is_banan, bit<1> is_nat, bit<8> linked_port) {
        meta.ebmeta.is_banan = is_banan;
        meta.ebmeta.is_nat = is_nat;
        meta.ebmeta.lanwan_out_port = linked_port;
    }
    @name("._nop") action _nop_4() {
    }
    @name(".set_port_type") action set_port_type(bit<3> port_type) {
        meta.ebmeta.port_type = port_type;
    }
    @name("._drop") action _drop() {
        mark_to_drop();
    }
    @name(".determine_nat_lanwan_flag_and_linked_port") table determine_nat_lanwan_flag_and_linked_port_0 {
        actions = {
            set_nat_lanwan_flag_and_linked_port();
            _nop_4();
            @defaultonly NoAction_6();
        }
        key = {
            standard_metadata.ingress_port: exact @name("standard_metadata.ingress_port") ;
        }
        default_action = NoAction_6();
    }
    @name(".determine_port_type") table determine_port_type_0 {
        actions = {
            set_port_type();
            _drop();
            @defaultonly NoAction_7();
        }
        key = {
            standard_metadata.ingress_port: exact @name("standard_metadata.ingress_port") ;
        }
        default_action = NoAction_7();
    }
    apply {
        determine_port_type_0.apply();
        determine_nat_lanwan_flag_and_linked_port_0.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ebheader_t>(hdr.ebheader);
        packet.emit<ethernet_t_0>(hdr.outer_ethernet);
        packet.emit<vlan_t[5]>(hdr.outer_vlan);
        packet.emit<mpls_t[5]>(hdr.mpls);
        packet.emit<mpls_cw_t>(hdr.mpls_cw);
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

