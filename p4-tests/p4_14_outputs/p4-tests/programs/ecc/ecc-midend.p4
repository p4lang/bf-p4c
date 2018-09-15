#include <core.p4>
#include <v1model.p4>

struct md_t {
    bit<1> pass;
    bit<2> color;
}

struct test_select_t {
    bit<1>  chk_prsr;
    bit<1>  chk_simple_tcam;
    bit<1>  chk_simple_exm;
    bit<1>  chk_stats;
    bit<1>  chk_meter;
    bit<1>  chk_stful;
    bit<1>  chk_sel;
    bit<1>  chk_idle_t;
    bit<1>  chk_idle_e;
    bit<20> key;
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

struct metadata {
    @name(".md") 
    md_t          md;
    @name(".test_sel") 
    test_select_t test_sel;
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
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition accept;
    }
}

@name(".ap") @mode("fair") action_selector(HashAlgorithm.crc16, 32w0, 32w16) ap;

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".do_drop_it") action do_drop_it_0() {
        mark_to_drop();
    }
    @name(".drop_it") table drop_it {
        actions = {
            do_drop_it_0();
        }
        size = 1;
        default_action = do_drop_it_0();
    }
    apply {
        if (meta.md.pass == 1w1) 
            ;
        else 
            drop_it.apply();
    }
}

@name(".r") register<bit<16>>(32w8192) r;

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_7() {
    }
    @name(".NoAction") action NoAction_8() {
    }
    @name(".NoAction") action NoAction_9() {
    }
    @name(".NoAction") action NoAction_10() {
    }
    @name(".NoAction") action NoAction_11() {
    }
    @name(".cntr") @min_width(32) counter(32w16384, CounterType.packets) cntr;
    @name(".m") meter(32w1024, MeterType.packets) m;
    @initial_register_lo_value(1) @name(".r_alu") RegisterAction<bit<16>, bit<16>>(r) r_alu = {
        void apply(inout bit<16> value) {
            value = value + 16w1;
        }
    };
    @name(".pass") action pass_0() {
        meta.md.pass = 1w1;
    }
    @name(".pass") action pass_7() {
        meta.md.pass = 1w1;
    }
    @name(".pass") action pass_8() {
        meta.md.pass = 1w1;
    }
    @name(".pass") action pass_9() {
        meta.md.pass = 1w1;
    }
    @name(".pass") action pass_10() {
        meta.md.pass = 1w1;
    }
    @name(".pass") action pass_11() {
        meta.md.pass = 1w1;
    }
    @name(".nop") action nop_0() {
    }
    @name(".nop") action nop_6() {
    }
    @name(".nop") action nop_7() {
    }
    @name(".nop") action nop_8() {
    }
    @name(".nop") action nop_9() {
    }
    @name(".nop") action nop_10() {
    }
    @name(".run_m") action run_m_0() {
        m.execute_meter<bit<2>>(32w917, meta.md.color);
    }
    @name(".set_md") action set_md_0(bit<1> chk_prsr, bit<1> chk_simple_tcam, bit<1> chk_simple_exm, bit<1> chk_stats, bit<1> chk_meter, bit<1> chk_stful, bit<1> chk_sel, bit<1> chk_idle_t, bit<1> chk_idle_e, bit<20> key) {
        meta.test_sel.chk_prsr = chk_prsr;
        meta.test_sel.chk_simple_tcam = chk_simple_tcam;
        meta.test_sel.chk_simple_exm = chk_simple_exm;
        meta.test_sel.chk_stats = chk_stats;
        meta.test_sel.chk_meter = chk_meter;
        meta.test_sel.chk_stful = chk_stful;
        meta.test_sel.chk_sel = chk_sel;
        meta.test_sel.chk_idle_t = chk_idle_t;
        meta.test_sel.chk_idle_e = chk_idle_e;
        meta.test_sel.key = key;
    }
    @name(".set_key") action set_key_0(bit<20> x) {
        meta.test_sel.key = x;
    }
    @name(".set_key") action set_key_3(bit<20> x) {
        meta.test_sel.key = x;
    }
    @name(".set_key") action set_key_4(bit<20> x) {
        meta.test_sel.key = x;
    }
    @name(".do_set_dest") action do_set_dest_0() {
        hdr.ig_intr_md_for_tm.ucast_egress_port = hdr.ig_intr_md.ingress_port;
    }
    @name(".count_it") action count_it_0() {
        cntr.count((bit<32>)meta.test_sel.key);
    }
    @name(".run_r") action run_r_0() {
        r_alu.execute((bit<32>)meta.test_sel.key);
    }
    @stage(10) @include_idletime(1) @idletime_precision(3) @name(".idle_exm") table idle_exm {
        support_timeout = true;
        actions = {
            pass_0();
            nop_0();
            @defaultonly NoAction_0();
        }
        key = {
            meta.test_sel.key[9:0]: exact @name("test_sel.key[9:0]") ;
        }
        size = 1024;
        default_action = NoAction_0();
    }
    @stage(9) @include_idletime(1) @idletime_precision(1) @name(".idle_tcam") table idle_tcam {
        support_timeout = true;
        actions = {
            pass_7();
            nop_6();
            @defaultonly NoAction_7();
        }
        key = {
            meta.test_sel.key: ternary @name("test_sel.key") ;
        }
        size = 512;
        default_action = NoAction_7();
    }
    @stage(5) @name(".mtr") table mtr {
        actions = {
            run_m_0();
        }
        size = 1;
        default_action = run_m_0();
    }
    @name(".p0") table p0 {
        actions = {
            set_md_0();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 288;
        default_action = set_md_0(1w0, 1w0, 1w0, 1w0, 1w0, 1w0, 1w0, 1w0, 1w0, 20w0);
    }
    @stage(0) @name(".prsr") table prsr {
        actions = {
            pass_8();
            nop_7();
            @defaultonly NoAction_8();
        }
        key = {
            hdr.ethernet.isValid(): exact @name("ethernet.$valid$") ;
        }
        size = 2;
        default_action = NoAction_8();
    }
    @stage(6) @name(".sel") table sel_1 {
        actions = {
            set_key_0();
            nop_8();
            pass_9();
            @defaultonly NoAction_9();
        }
        key = {
            meta.test_sel.key[9:0]: exact @name("test_sel.key[9:0]") ;
            meta.test_sel.key     : selector @name("test_sel.key") ;
        }
        size = 1024;
        implementation = ap;
        default_action = NoAction_9();
    }
    @name(".set_dest") table set_dest {
        actions = {
            do_set_dest_0();
        }
        size = 1;
        default_action = do_set_dest_0();
    }
    @stage(2) @immediate(0) @name(".simple_exm") table simple_exm {
        actions = {
            pass_10();
            nop_9();
            set_key_3();
            @defaultonly NoAction_10();
        }
        key = {
            meta.test_sel.key[9:0]: exact @name("test_sel.key[9:0]") ;
        }
        size = 1024;
        default_action = NoAction_10();
    }
    @stage(1) @name(".simple_tcam") table simple_tcam {
        actions = {
            pass_11();
            nop_10();
            set_key_4();
            @defaultonly NoAction_11();
        }
        key = {
            meta.test_sel.key: ternary @name("test_sel.key") ;
        }
        size = 512;
        default_action = NoAction_11();
    }
    @stage(3) @name(".stats") table stats {
        actions = {
            count_it_0();
        }
        size = 1;
        default_action = count_it_0();
    }
    @stage(4) @name(".stful") table stful {
        actions = {
            run_r_0();
        }
        size = 1;
        default_action = run_r_0();
    }
    apply {
        if (1w0 == hdr.ig_intr_md.resubmit_flag) 
            p0.apply();
        if (meta.test_sel.chk_prsr == 1w1) 
            prsr.apply();
        if (meta.test_sel.chk_simple_tcam == 1w1) 
            simple_tcam.apply();
        if (meta.test_sel.chk_simple_exm == 1w1) 
            simple_exm.apply();
        if (meta.test_sel.chk_stats == 1w1) 
            stats.apply();
        if (meta.test_sel.chk_stful == 1w1) 
            stful.apply();
        if (meta.test_sel.chk_meter == 1w1) 
            mtr.apply();
        if (meta.test_sel.chk_sel == 1w1) 
            sel_1.apply();
        if (meta.test_sel.chk_idle_t == 1w1) 
            idle_tcam.apply();
        if (meta.test_sel.chk_idle_e == 1w1) 
            idle_exm.apply();
        set_dest.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
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

