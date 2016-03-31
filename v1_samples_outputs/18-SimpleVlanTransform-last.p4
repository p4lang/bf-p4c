#include "/home/mbudiu/barefoot/git/P4/p4c/build/../p4include/core.p4"
#include "/home/mbudiu/barefoot/git/P4/p4c/build/../p4include/v1model.p4"

struct egress_intrinsic_metadata_t {
    bit<16> egress_port;
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

struct egress_intrinsic_metadata_for_mirror_buffer_t {
    bit<6>  _pad1;
    bit<10> egress_mirror_id;
    bit<1>  coalesce_flush;
    bit<7>  coalesce_length;
}

struct egress_intrinsic_metadata_for_output_port_t {
    bit<2> _pad1;
    bit<1> capture_tstamp_on_tx;
    bit<1> update_delay_on_tx;
    bit<1> force_tx_error;
    bit<3> drop_ctl;
}

struct egress_intrinsic_metadata_from_parser_aux_t {
    bit<48> egress_global_tstamp;
    bit<32> egress_global_ver;
    bit<16> egress_parser_err;
    bit<8>  clone_src;
    bit<8>  coalesce_sample_count;
}

struct ingress_intrinsic_metadata_t {
    bit<1>  resubmit_flag;
    bit<1>  _pad1;
    bit<2>  _pad2;
    bit<3>  _pad3;
    bit<9>  ingress_port;
    bit<48> ingress_mac_tstamp;
}

struct ingress_intrinsic_metadata_for_mirror_buffer_t {
    bit<6>  _pad1;
    bit<10> ingress_mirror_id;
}

struct ingress_intrinsic_metadata_for_tm_t {
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

struct ingress_intrinsic_metadata_from_parser_aux_t {
    bit<48> ingress_global_tstamp;
    bit<32> ingress_global_ver;
    bit<16> ingress_parser_err;
}

struct generator_metadata_t {
    bit<16> app_id;
    bit<16> batch_id;
    bit<16> instance_id;
}

struct ingress_parser_control_signals {
    bit<3> priority;
}

struct metadata_t {
    bit<16> new_tpid;
    bit<3>  new_pri;
    bit<1>  new_cfi;
    bit<12> new_vid;
    bit<1>  new_tpid_en;
    bit<1>  new_pri_en;
    bit<1>  new_cfi_en;
    bit<1>  new_vid_en;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> ethertype;
}

header vlan_tag_t {
    bit<3>  pri;
    bit<1>  cfi;
    bit<12> vid;
    bit<16> ethertype;
}

struct metadata {
    @name("eg_intr_md") 
    egress_intrinsic_metadata_t                    eg_intr_md;
    @name("eg_intr_md_for_mb") 
    egress_intrinsic_metadata_for_mirror_buffer_t  eg_intr_md_for_mb;
    @name("eg_intr_md_for_oport") 
    egress_intrinsic_metadata_for_output_port_t    eg_intr_md_for_oport;
    @name("eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t    eg_intr_md_from_parser_aux;
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
    @name("meta") 
    metadata_t                                     meta;
}

struct headers {
    @name("ethernet") 
    ethernet_t ethernet;
    @name("vlan_tag") 
    vlan_tag_t vlan_tag;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("parse_vlan_tag") state parse_vlan_tag {
        packet.extract(hdr.vlan_tag);
        transition accept;
    }
    @name("start") state start {
        packet.extract(hdr.ethernet);
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
    action do_new_cfi() {
        hdr.vlan_tag.cfi = meta.meta.new_cfi;
    }
    action do_new_pri() {
        hdr.vlan_tag.pri = meta.meta.new_pri;
    }
    action do_new_tpid() {
        hdr.ethernet.ethertype = meta.meta.new_tpid;
    }
    action do_new_vid() {
        hdr.vlan_tag.vid = meta.meta.new_vid;
    }
    action rewrite_tag(bit<16> new_tpid, bit<1> new_tpid_en, bit<3> new_pri, bit<1> new_pri_en, bit<1> new_cfi, bit<1> new_cfi_en, bit<12> new_vid, bit<1> new_vid_en) {
        meta.meta.new_tpid = new_tpid;
        meta.meta.new_tpid_en = new_tpid_en;
        meta.meta.new_pri = new_pri;
        meta.meta.new_pri_en = new_pri_en;
        meta.meta.new_cfi = new_cfi;
        meta.meta.new_cfi_en = new_cfi_en;
        meta.meta.new_vid = new_vid;
        meta.meta.new_vid_en = new_vid_en;
    }
    @name("new_cfi") table new_cfi() {
        actions = {
            do_new_cfi;
        }
    }

    @name("new_pri") table new_pri() {
        actions = {
            do_new_pri;
        }
    }

    @name("new_tpid") table new_tpid() {
        actions = {
            do_new_tpid;
        }
    }

    @name("new_vid") table new_vid() {
        actions = {
            do_new_vid;
        }
    }

    @name("vlan_xlate") table vlan_xlate() {
        actions = {
            rewrite_tag;
        }
        key = {
            hdr.vlan_tag.vid: exact;
        }
    }

    apply {
        switch (vlan_xlate.apply().action_run) {
            rewrite_tag: {
                if (meta.meta.new_tpid_en == 1w1) 
                    new_tpid.apply();
                if (meta.meta.new_pri_en == 1w1) 
                    new_pri.apply();
                if (meta.meta.new_cfi_en == 1w1) 
                    new_cfi.apply();
                if (meta.meta.new_vid_en == 1w1) 
                    new_vid.apply();
            }
        }

    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.vlan_tag);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
