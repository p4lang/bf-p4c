#include "/home/cdodd/p4c/build/../p4include/core.p4"
#include "/home/cdodd/p4c/build/../p4include/v1model.p4"

struct metadata_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<32> f5;
    bit<32> f6;
    bit<32> f7;
    bit<32> f8;
}

header egress_intrinsic_metadata_t {
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
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("start") state start {
        packet.extract(hdr.ethernet);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
        bool hasReturned_0 = false;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("a1") action a1(bit<32> d1, bit<32> d2, bit<32> d3, bit<32> d4, bit<32> d5, bit<32> d6, bit<32> d7, bit<32> d8) {
        bool hasReturned_2 = false;
        meta.meta.f1 = d1;
        meta.meta.f2 = d2;
        meta.meta.f3 = d3;
        meta.meta.f4 = d4;
        meta.meta.f5 = d5;
        meta.meta.f6 = d6;
        meta.meta.f7 = d7;
        meta.meta.f8 = d8;
        resubmit({ meta.meta.f1, meta.meta.f2, meta.meta.f3, meta.meta.f4, meta.meta.f5, meta.meta.f6, meta.meta.f7, meta.meta.f8 });
    }
    @name("t1") table t1() {
        actions = {
            a1;
            NoAction;
        }
        default_action = NoAction();
    }

    apply {
        bool hasReturned_1 = false;
        if (hdr.ig_intr_md.resubmit_flag == 1w0) 
            t1.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        bool hasReturned_3 = false;
        packet.emit(hdr.ethernet);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
        bool hasReturned_4 = false;
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
        bool hasReturned_5 = false;
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
