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
    bit<8>  clone_src;
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

header generator_metadata_t {
    bit<16> app_id;
    bit<16> batch_id;
    bit<16> instance_id;
}

header ingress_parser_control_signals {
    bit<3> priority;
}

header vlan_tag_t {
    bit<3>  pri;
    bit<1>  cfi;
    bit<12> vid;
    bit<16> ethertype;
}

struct metadata {
    @name("meta") 
    metadata_t meta;
}

struct headers {
    @name("eg_intr_md") 
    egress_intrinsic_metadata_t                    eg_intr_md;
    @name("eg_intr_md_for_mb") 
    egress_intrinsic_metadata_for_mirror_buffer_t  eg_intr_md_for_mb;
    @name("eg_intr_md_for_oport") 
    egress_intrinsic_metadata_for_output_port_t    eg_intr_md_for_oport;
    @name("eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t    eg_intr_md_from_parser_aux;
    @name("ethernet") 
    ethernet_t                                     ethernet;
    @name("ig_intr_md") 
    ingress_intrinsic_metadata_t                   ig_intr_md;
    @name("ig_intr_md_for_mb") 
    ingress_intrinsic_metadata_for_mirror_buffer_t ig_intr_md_for_mb;
    @name("ig_intr_md_for_tm") 
    ingress_intrinsic_metadata_for_tm_t            ig_intr_md_for_tm;
    @name("ig_intr_md_from_parser_aux") 
    ingress_intrinsic_metadata_from_parser_aux_t   ig_intr_md_from_parser_aux;
    @name("ig_pg_md") 
    generator_metadata_t                           ig_pg_md;
    @name("ig_prsr_ctrl") 
    ingress_parser_control_signals                 ig_prsr_ctrl;
    @name("vlan_tag") 
    vlan_tag_t[2]                                  vlan_tag;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("parse_vlan_tag") state parse_vlan_tag {
        packet.extract<vlan_tag_t>(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ethertype) {
            16w0x8100: parse_vlan_tag;
            default: accept;
        }
    }
    @name("start") state start {
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
    @name("NoAction_1") action NoAction() {
    }
    @name("NoAction_2") action NoAction_0() {
    }
    @name("NoAction_3") action NoAction_10() {
    }
    @name("NoAction_4") action NoAction_11() {
    }
    @name("NoAction_5") action NoAction_12() {
    }
    @name("NoAction_6") action NoAction_13() {
    }
    @name("NoAction_7") action NoAction_14() {
    }
    @name("NoAction_8") action NoAction_15() {
    }
    @name("NoAction_9") action NoAction_16() {
    }
    @name("do_new_inner_cfi") action do_new_inner_cfi_0() {
        hdr.vlan_tag[1].cfi = meta.meta.new_inner_cfi;
    }
    @name("do_new_inner_pri") action do_new_inner_pri_0() {
        hdr.vlan_tag[1].pri = meta.meta.new_inner_pri;
    }
    @name("do_new_inner_tpid") action do_new_inner_tpid_0() {
        hdr.vlan_tag[0].ethertype = meta.meta.new_inner_tpid;
    }
    @name("do_new_inner_vid") action do_new_inner_vid_0() {
        hdr.vlan_tag[1].vid = meta.meta.new_inner_vid;
    }
    @name("do_new_outer_cfi") action do_new_outer_cfi_0() {
        hdr.vlan_tag[0].cfi = meta.meta.new_outer_cfi;
    }
    @name("do_new_outer_pri") action do_new_outer_pri_0() {
        hdr.vlan_tag[0].pri = meta.meta.new_outer_pri;
    }
    @name("do_new_outer_tpid") action do_new_outer_tpid_0() {
        hdr.ethernet.ethertype = meta.meta.new_outer_tpid;
    }
    @name("do_new_outer_vid") action do_new_outer_vid_0() {
        hdr.vlan_tag[0].vid = meta.meta.new_outer_vid;
    }
    @name("nop") action nop_0() {
    }
    @name("rewrite_tags") action rewrite_tags_0(bit<16> new_outer_tpid, bit<1> new_outer_tpid_en, bit<3> new_outer_pri, bit<1> new_outer_pri_en, bit<1> new_outer_cfi, bit<1> new_outer_cfi_en, bit<12> new_outer_vid, bit<1> new_outer_vid_en, bit<16> new_inner_tpid, bit<1> new_inner_tpid_en, bit<3> new_inner_pri, bit<1> new_inner_pri_en, bit<1> new_inner_cfi, bit<1> new_inner_cfi_en, bit<12> new_inner_vid, bit<1> new_inner_vid_en) {
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
    @name("new_inner_cfi") table new_inner_cfi_1() {
        actions = {
            do_new_inner_cfi_0();
            NoAction();
        }
        default_action = NoAction();
    }
    @name("new_inner_pri") table new_inner_pri_1() {
        actions = {
            do_new_inner_pri_0();
            NoAction_0();
        }
        default_action = NoAction_0();
    }
    @name("new_inner_tpid") table new_inner_tpid_1() {
        actions = {
            do_new_inner_tpid_0();
            NoAction_10();
        }
        default_action = NoAction_10();
    }
    @name("new_inner_vid") table new_inner_vid_1() {
        actions = {
            do_new_inner_vid_0();
            NoAction_11();
        }
        default_action = NoAction_11();
    }
    @name("new_outer_cfi") table new_outer_cfi_1() {
        actions = {
            do_new_outer_cfi_0();
            NoAction_12();
        }
        default_action = NoAction_12();
    }
    @name("new_outer_pri") table new_outer_pri_1() {
        actions = {
            do_new_outer_pri_0();
            NoAction_13();
        }
        default_action = NoAction_13();
    }
    @name("new_outer_tpid") table new_outer_tpid_1() {
        actions = {
            do_new_outer_tpid_0();
            NoAction_14();
        }
        default_action = NoAction_14();
    }
    @name("new_outer_vid") table new_outer_vid_1() {
        actions = {
            do_new_outer_vid_0();
            NoAction_15();
        }
        default_action = NoAction_15();
    }
    @name("vlan_xlate") table vlan_xlate() {
        actions = {
            nop_0();
            rewrite_tags_0();
            NoAction_16();
        }
        key = {
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[0].vid      : exact;
            hdr.vlan_tag[1].isValid(): exact;
            hdr.vlan_tag[1].vid      : exact;
        }
        default_action = NoAction_16();
    }
    apply {
        vlan_xlate.apply();
        if (meta.meta.new_outer_tpid_en == 1w1) 
            new_outer_tpid_1.apply();
        if (meta.meta.new_outer_pri_en == 1w1) 
            new_outer_pri_1.apply();
        if (meta.meta.new_outer_cfi_en == 1w1) 
            new_outer_cfi_1.apply();
        if (meta.meta.new_outer_vid_en == 1w1) 
            new_outer_vid_1.apply();
        if (meta.meta.new_inner_tpid_en == 1w1) 
            new_inner_tpid_1.apply();
        if (meta.meta.new_inner_pri_en == 1w1) 
            new_inner_pri_1.apply();
        if (meta.meta.new_inner_cfi_en == 1w1) 
            new_inner_cfi_1.apply();
        if (meta.meta.new_inner_vid_en == 1w1) 
            new_inner_vid_1.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<vlan_tag_t[2]>(hdr.vlan_tag);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
