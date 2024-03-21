#include <core.p4>
#include <v1model.p4>

struct metadata_t {
    bit<16> new_outer_tpid;
    bit<3>  new_outer_pri;
    bit<1>  new_outer_cfi;
    bit<12> new_outer_vid;
    bit<16> new_inner_tpid;
    bit<3>  new_inner_pri;
    bit<1>  new_inner_cfi;
    bit<12> new_inner_vid;
    bit<1>  new_outer_tpid_en;
    bit<1>  new_outer_pri_en;
    bit<1>  new_outer_cfi_en;
    bit<1>  new_outer_vid_en;
    bit<1>  new_inner_tpid_en;
    bit<1>  new_inner_pri_en;
    bit<1>  new_inner_cfi_en;
    bit<1>  new_inner_vid_en;
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
    bit<16> ethertype;
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

header vlan_tag_t {
    bit<3>  pri;
    bit<1>  cfi;
    bit<12> vid;
    bit<16> ethertype;
}

struct metadata {
    @name(".meta") 
    metadata_t meta;
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
    @name(".vlan_tag") 
    vlan_tag_t[2]                                  vlan_tag;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_vlan_tag") state parse_vlan_tag {
        packet.extract<vlan_tag_t>(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ethertype) {
            16w0x8100: parse_vlan_tag;
            default: accept;
        }
    }
    @name(".start") state start {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.ethertype) {
            16w0x8100: parse_vlan_tag;
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
    @name(".NoAction") action NoAction_10() {
    }
    @name(".NoAction") action NoAction_11() {
    }
    @name(".NoAction") action NoAction_12() {
    }
    @name(".NoAction") action NoAction_13() {
    }
    @name(".NoAction") action NoAction_14() {
    }
    @name(".NoAction") action NoAction_15() {
    }
    @name(".NoAction") action NoAction_16() {
    }
    @name(".NoAction") action NoAction_17() {
    }
    @name(".do_new_inner_cfi") action do_new_inner_cfi() {
        hdr.vlan_tag[1].cfi = meta.meta.new_inner_cfi;
    }
    @name(".do_new_inner_pri") action do_new_inner_pri() {
        hdr.vlan_tag[1].pri = meta.meta.new_inner_pri;
    }
    @name(".do_new_inner_tpid") action do_new_inner_tpid() {
        hdr.vlan_tag[0].ethertype = meta.meta.new_inner_tpid;
    }
    @name(".do_new_inner_vid") action do_new_inner_vid() {
        hdr.vlan_tag[1].vid = meta.meta.new_inner_vid;
    }
    @name(".do_new_outer_cfi") action do_new_outer_cfi() {
        hdr.vlan_tag[0].cfi = meta.meta.new_outer_cfi;
    }
    @name(".do_new_outer_pri") action do_new_outer_pri() {
        hdr.vlan_tag[0].pri = meta.meta.new_outer_pri;
    }
    @name(".do_new_outer_tpid") action do_new_outer_tpid() {
        hdr.ethernet.ethertype = meta.meta.new_outer_tpid;
    }
    @name(".do_new_outer_vid") action do_new_outer_vid() {
        hdr.vlan_tag[0].vid = meta.meta.new_outer_vid;
    }
    @name(".nop") action nop() {
    }
    @name(".rewrite_tags") action rewrite_tags(bit<16> new_outer_tpid, bit<1> new_outer_tpid_en, bit<3> new_outer_pri, bit<1> new_outer_pri_en, bit<1> new_outer_cfi, bit<1> new_outer_cfi_en, bit<12> new_outer_vid, bit<1> new_outer_vid_en, bit<16> new_inner_tpid, bit<1> new_inner_tpid_en, bit<3> new_inner_pri, bit<1> new_inner_pri_en, bit<1> new_inner_cfi, bit<1> new_inner_cfi_en, bit<12> new_inner_vid, bit<1> new_inner_vid_en) {
        meta.meta.new_outer_tpid = new_outer_tpid;
        meta.meta.new_outer_tpid_en = new_outer_tpid_en;
        meta.meta.new_outer_pri = new_outer_pri;
        meta.meta.new_outer_pri_en = new_outer_pri_en;
        meta.meta.new_outer_cfi = new_outer_cfi;
        meta.meta.new_outer_cfi_en = new_outer_cfi_en;
        meta.meta.new_outer_vid = new_outer_vid;
        meta.meta.new_outer_vid_en = new_outer_vid_en;
        meta.meta.new_inner_tpid = new_inner_tpid;
        meta.meta.new_inner_tpid_en = new_inner_tpid_en;
        meta.meta.new_inner_pri = new_inner_pri;
        meta.meta.new_inner_pri_en = new_inner_pri_en;
        meta.meta.new_inner_cfi = new_inner_cfi;
        meta.meta.new_inner_cfi_en = new_inner_cfi_en;
        meta.meta.new_inner_vid = new_inner_vid;
        meta.meta.new_inner_vid_en = new_inner_vid_en;
    }
    @name(".new_inner_cfi") table new_inner_cfi_0 {
        actions = {
            do_new_inner_cfi();
            @defaultonly NoAction_0();
        }
        default_action = NoAction_0();
    }
    @name(".new_inner_pri") table new_inner_pri_0 {
        actions = {
            do_new_inner_pri();
            @defaultonly NoAction_10();
        }
        default_action = NoAction_10();
    }
    @name(".new_inner_tpid") table new_inner_tpid_0 {
        actions = {
            do_new_inner_tpid();
            @defaultonly NoAction_11();
        }
        default_action = NoAction_11();
    }
    @name(".new_inner_vid") table new_inner_vid_0 {
        actions = {
            do_new_inner_vid();
            @defaultonly NoAction_12();
        }
        default_action = NoAction_12();
    }
    @name(".new_outer_cfi") table new_outer_cfi_0 {
        actions = {
            do_new_outer_cfi();
            @defaultonly NoAction_13();
        }
        default_action = NoAction_13();
    }
    @name(".new_outer_pri") table new_outer_pri_0 {
        actions = {
            do_new_outer_pri();
            @defaultonly NoAction_14();
        }
        default_action = NoAction_14();
    }
    @name(".new_outer_tpid") table new_outer_tpid_0 {
        actions = {
            do_new_outer_tpid();
            @defaultonly NoAction_15();
        }
        default_action = NoAction_15();
    }
    @name(".new_outer_vid") table new_outer_vid_0 {
        actions = {
            do_new_outer_vid();
            @defaultonly NoAction_16();
        }
        default_action = NoAction_16();
    }
    @name(".vlan_xlate") table vlan_xlate_0 {
        actions = {
            nop();
            rewrite_tags();
            @defaultonly NoAction_17();
        }
        key = {
            hdr.vlan_tag[0].isValid(): exact @name("vlan_tag[0].$valid$") ;
            hdr.vlan_tag[0].vid      : exact @name("vlan_tag[0].vid") ;
            hdr.vlan_tag[1].isValid(): exact @name("vlan_tag[1].$valid$") ;
            hdr.vlan_tag[1].vid      : exact @name("vlan_tag[1].vid") ;
        }
        default_action = NoAction_17();
    }
    apply {
        vlan_xlate_0.apply();
        if (meta.meta.new_outer_tpid_en == 1w1) 
            new_outer_tpid_0.apply();
        if (meta.meta.new_outer_pri_en == 1w1) 
            new_outer_pri_0.apply();
        if (meta.meta.new_outer_cfi_en == 1w1) 
            new_outer_cfi_0.apply();
        if (meta.meta.new_outer_vid_en == 1w1) 
            new_outer_vid_0.apply();
        if (meta.meta.new_inner_tpid_en == 1w1) 
            new_inner_tpid_0.apply();
        if (meta.meta.new_inner_pri_en == 1w1) 
            new_inner_pri_0.apply();
        if (meta.meta.new_inner_cfi_en == 1w1) 
            new_inner_cfi_0.apply();
        if (meta.meta.new_inner_vid_en == 1w1) 
            new_inner_vid_0.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<vlan_tag_t>(hdr.vlan_tag[0]);
        packet.emit<vlan_tag_t>(hdr.vlan_tag[1]);
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

