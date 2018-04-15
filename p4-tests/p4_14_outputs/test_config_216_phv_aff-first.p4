#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<32> a;
    bit<4>  b;
    bit<4>  c;
    bit<16> d;
    bit<8>  e;
    bit<8>  f;
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

header first_t {
    bit<8> a;
    bit<8> b;
    bit<8> c;
    bit<8> d;
}

header hdr_0_t {
    bit<4>  a_0;
    bit<4>  a_1;
    bit<16> b;
    bit<32> c;
    bit<32> d;
    bit<8>  e;
    bit<16> f;
    bit<3>  g;
    bit<8>  h;
    bit<5>  i;
}

header hdr_2_t {
    bit<8> a;
    bit<8> b;
    bit<8> c;
    bit<8> d;
}

header hdr_3_t {
    bit<32> a_3;
    bit<32> a_4;
    bit<32> a_5;
    bit<32> a_6;
    bit<27> a_7;
    bit<1>  b_1;
    bit<2>  b_2;
    bit<4>  b_3;
    bit<30> a_8;
    bit<32> a_9;
    bit<32> a_10;
    bit<32> a_11;
    bit<32> a_12;
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

header hdr_1_t {
    bit<32> a;
    bit<32> b;
    bit<16> c;
    bit<4>  d_0;
    bit<4>  d_1;
    bit<8>  e;
    bit<16> f;
    bit<32> g;
}

struct metadata {
    @name(".meta") 
    meta_t meta;
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
    @pa_container_size("ingress", "first.b", 16) @name(".first") 
    first_t                                        first;
    @pa_container_size("ingress", "hdr_0.d", 32) @name(".hdr_0") 
    hdr_0_t                                        hdr_0;
    @name(".hdr_2") 
    hdr_2_t                                        hdr_2;
    @name(".hdr_3") 
    hdr_3_t                                        hdr_3;
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
    @name(".hdr_1") 
    hdr_1_t[3]                                     hdr_1;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".first_p") state first_p {
        packet.extract<first_t>(hdr.first);
        transition select(hdr.first.c) {
            8w0x3f: parse_hdr_0;
            default: parse_hdr_1;
        }
    }
    @name(".parse_hdr_0") state parse_hdr_0 {
        packet.extract<hdr_0_t>(hdr.hdr_0);
        transition accept;
    }
    @name(".parse_hdr_1") state parse_hdr_1 {
        packet.extract<hdr_1_t>(hdr.hdr_1.next);
        transition select(hdr.hdr_1[0].d_0) {
            4w0: parse_hdr_1;
            4w1: parse_hdr_2;
            default: accept;
        }
    }
    @name(".parse_hdr_2") state parse_hdr_2 {
        packet.extract<hdr_2_t>(hdr.hdr_2);
        transition parse_hdr_3;
    }
    @name(".parse_hdr_3") state parse_hdr_3 {
        packet.extract<hdr_3_t>(hdr.hdr_3);
        transition accept;
    }
    @name(".start") state start {
        transition first_p;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_all") action set_all(bit<32> p0, bit<4> p2, bit<16> p3) {
        meta.meta.a = p0;
        meta.meta.c = p2;
        meta.meta.d = p3;
    }
    @name(".action_0") action action_0(bit<8> p0, bit<8> p1) {
        meta.meta.a = 32w0;
        meta.meta.b = hdr.hdr_0.a_1;
        mark_to_drop();
    }
    @name(".action_1") action action_1(bit<16> p1, bit<8> p2) {
        meta.meta.b = hdr.hdr_1[0].d_1;
        meta.meta.d = p1;
        meta.meta.c = meta.meta.c + 4w1;
        meta.meta.e = p2 - meta.meta.f;
    }
    @name(".do_nothing") action do_nothing() {
    }
    @name(".action_2") action action_2() {
        meta.meta.e = meta.meta.e + 8w5;
    }
    @name(".action_3") action action_3(bit<8> p0) {
        meta.meta.f = 8w1;
    }
    @name(".table_i0") table table_i0 {
        actions = {
            set_all();
            action_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.hdr_0.b: ternary @name("hdr_0.b") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".table_i1") table table_i1 {
        actions = {
            action_1();
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.hdr_1[0].c: ternary @name("hdr_1[0].c") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".table_i2") table table_i2 {
        actions = {
            do_nothing();
            action_2();
            @defaultonly NoAction();
        }
        key = {
            meta.meta.a: exact @name("meta.a") ;
            meta.meta.b: exact @name("meta.b") ;
            meta.meta.c: exact @name("meta.c") ;
            meta.meta.d: exact @name("meta.d") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".table_i3") table table_i3 {
        actions = {
            do_nothing();
            action_3();
            @defaultonly NoAction();
        }
        key = {
            meta.meta.b: ternary @name("meta.b") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (hdr.hdr_0.isValid()) 
            table_i0.apply();
        else 
            table_i1.apply();
        table_i2.apply();
        table_i3.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<first_t>(hdr.first);
        packet.emit<hdr_1_t[3]>(hdr.hdr_1);
        packet.emit<hdr_2_t>(hdr.hdr_2);
        packet.emit<hdr_3_t>(hdr.hdr_3);
        packet.emit<hdr_0_t>(hdr.hdr_0);
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

