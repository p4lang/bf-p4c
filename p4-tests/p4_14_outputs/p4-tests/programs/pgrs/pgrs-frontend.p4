#include <core.p4>
#include <v1model.p4>

struct ig_md_t {
    bit<1> skip_lkups;
    bit<1> pktgen_port;
    bit<2> pktgen_type;
    bit<1> test_recirc;
    bit<1> pfe_override_test;
}

struct pfe_md_t {
    bit<16> a;
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

header pktgen_header_t {
    bit<8> id;
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

struct metadata {
    @name(".ig_md") 
    ig_md_t  ig_md;
    @name(".pfe_md") 
    pfe_md_t pfe_md;
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
    @name(".pgen_header") 
    pktgen_header_t                                pgen_header;
    @name(".pktgen_generic") 
    pktgen_generic_header_t                        pktgen_generic;
    @name(".pktgen_port_down") 
    pktgen_port_down_header_t                      pktgen_port_down;
    @name(".pktgen_recirc") 
    pktgen_recirc_header_t                         pktgen_recirc;
    @name(".pktgen_timer") 
    pktgen_timer_header_t                          pktgen_timer;
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".pktgen_done") state pktgen_done {
        transition accept;
    }
    @name(".pktgen_port_down") state pktgen_port_down {
        meta.ig_md.pktgen_type = 2w2;
        transition pktgen_done;
    }
    @name(".pktgen_recirc") state pktgen_recirc {
        meta.ig_md.pktgen_type = 2w3;
        transition pktgen_done;
    }
    @name(".pktgen_timer") state pktgen_timer {
        meta.ig_md.pktgen_type = 2w0;
        transition pktgen_done;
    }
    @name(".start") state start {
        packet.extract<pktgen_header_t>(hdr.pgen_header);
        transition select(hdr.pgen_header.id) {
            8w0x0 &&& 8w0x1f: pktgen_port_down;
            8w0x1 &&& 8w0x1f: pktgen_timer;
            8w0x2 &&& 8w0x1f: pktgen_recirc;
            8w0x3 &&& 8w0x1f: pktgen_timer;
            8w0x4 &&& 8w0x1f: pktgen_timer;
            8w0x5 &&& 8w0x1f: pktgen_timer;
            8w0x6 &&& 8w0x1f: pktgen_timer;
            8w0x7 &&& 8w0x1f: pktgen_timer;
            8w0x8 &&& 8w0x1f: pktgen_timer;
            8w0x9 &&& 8w0x1f: pktgen_port_down;
            8w0xa &&& 8w0x1f: pktgen_timer;
            8w0xb &&& 8w0x1f: pktgen_recirc;
            8w0xc &&& 8w0x1f: pktgen_timer;
            8w0xd &&& 8w0x1f: pktgen_timer;
            8w0xe &&& 8w0x1f: pktgen_timer;
            8w0xf &&& 8w0x1f: pktgen_timer;
            8w0x10 &&& 8w0x1f: pktgen_timer;
            8w0x11 &&& 8w0x1f: pktgen_timer;
            8w0x12 &&& 8w0x1f: pktgen_port_down;
            8w0x13 &&& 8w0x1f: pktgen_timer;
            8w0x14 &&& 8w0x1f: pktgen_recirc;
            8w0x15 &&& 8w0x1f: pktgen_timer;
            8w0x16 &&& 8w0x1f: pktgen_timer;
            8w0x17 &&& 8w0x1f: pktgen_timer;
            8w0x18 &&& 8w0x1f: pktgen_timer;
            8w0x19 &&& 8w0x1f: pktgen_timer;
            8w0x1a &&& 8w0x1f: pktgen_timer;
            8w0x1b &&& 8w0x1f: pktgen_port_down;
            8w0x1c &&& 8w0x1f: pktgen_timer;
            8w0x1d &&& 8w0x1f: pktgen_recirc;
            8w0x1e &&& 8w0x1f: pktgen_timer;
            8w0x1f &&& 8w0x1f: pktgen_timer;
            default: accept;
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}
#include <tofino/p4_14_prim.p4>

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".c1") counter(32w500, CounterType.packets) c1_0;
    @name(".c2") counter(32w500, CounterType.packets) c2_0;
    @name(".r1") register<bit<32>>(32w500) r1_0;
    @name(".r2") register<bit<32>>(32w500) r2_0;
    @name("alu1") register_action<bit<32>, bit<32>>(r1_0) alu1_0 = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            value = value + 32w1;
        }
    };
    @name("alu1_1") register_action<bit<32>, bit<32>>(r1_0) alu1_2 = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            value = value + 32w10;
        }
    };
    @name("alu2") register_action<bit<32>, bit<32>>(r2_0) alu2_0 = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            value = value + 32w1;
        }
    };
    @name("alu2_1") register_action<bit<32>, bit<32>>(r2_0) alu2_2 = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            value = value + 32w10;
        }
    };
    @name(".local_recirc") action local_recirc_0(bit<8> local_port) {
        recirculate_raw((bit<9>)local_port);
    }
    @name(".a1") action a1_0() {
    }
    @name(".a2") action a2_0(bit<32> cntr_index) {
        c1_0.count(cntr_index);
    }
    @name(".a4") action a4_0() {
        c1_0.count(32w12);
    }
    @name(".a3") action a3_0() {
        c2_0.count((bit<32>)hdr.ig_intr_md.ingress_port);
    }
    @name(".a5") action a5_0(bit<32> stful_index) {
        alu1_0.execute(stful_index);
    }
    @name(".a7") action a7_0() {
        alu1_0.execute(32w12);
    }
    @name(".a8") action a8_0() {
        alu1_2.execute(32w13);
    }
    @name(".a6") action a6_0() {
        alu2_0.execute((bit<32>)hdr.ig_intr_md.ingress_port);
    }
    @name(".a9") action a9_0() {
        alu2_2.execute((bit<32>)hdr.ig_intr_md.ingress_port);
    }
    @name(".do_tcam") action do_tcam_0() {
    }
    @name(".do_exm") action do_exm_0() {
    }
    @name(".port_down_ok") action port_down_ok_0() {
    }
    @name(".port_down_nok") action port_down_nok_0() {
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w6;
    }
    @name(".recirc_ok") action recirc_ok_0() {
    }
    @name(".recirc_nok") action recirc_nok_0() {
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w6;
    }
    @name(".timer_ok") action timer_ok_0() {
    }
    @name(".timer_nok") action timer_nok_0() {
        hdr.ig_intr_md_for_tm.ucast_egress_port = 9w6;
    }
    @name(".set_md") action set_md_0(bit<9> eg_port, bit<1> skip, bit<1> pktgen_port, bit<1> test_recirc, bit<16> mgid1, bit<16> mgid2, bit<1> pfe) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = eg_port;
        meta.ig_md.skip_lkups = skip;
        meta.ig_md.pktgen_port = pktgen_port;
        meta.ig_md.test_recirc = test_recirc;
        hdr.ig_intr_md_for_tm.mcast_grp_a = mgid1;
        hdr.ig_intr_md_for_tm.mcast_grp_b = mgid2;
        meta.ig_md.pfe_override_test = pfe;
    }
    @name(".do_local_recirc") table do_local_recirc_0 {
        actions = {
            local_recirc_0();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @name(".e1") table e1_0 {
        actions = {
            a1_0();
            a2_0();
            a4_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 5;
        default_action = NoAction();
    }
    @name(".e2") table e2_0 {
        actions = {
            a1_0();
            a3_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 5;
        default_action = NoAction();
    }
    @name(".e4") table e4_0 {
        actions = {
            a1_0();
            a5_0();
            a7_0();
            a8_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 5;
        default_action = NoAction();
    }
    @name(".e5") table e5_0 {
        actions = {
            a1_0();
            a6_0();
            a9_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 5;
        default_action = NoAction();
    }
    @name(".eg_tcam_or_exm") table eg_tcam_or_exm_0 {
        actions = {
            do_tcam_0();
            do_exm_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 2;
        default_action = NoAction();
    }
    @name(".pg_verify_port_down") table pg_verify_port_down_0 {
        actions = {
            port_down_ok_0();
            port_down_nok_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        default_action = NoAction();
    }
    @name(".pg_verify_recirc") table pg_verify_recirc_0 {
        actions = {
            recirc_ok_0();
            recirc_nok_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        default_action = NoAction();
    }
    @name(".pg_verify_timer") table pg_verify_timer_0 {
        actions = {
            timer_ok_0();
            timer_nok_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        default_action = NoAction();
    }
    @name(".port_tbl") table port_tbl_0 {
        actions = {
            set_md_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 288;
        default_action = NoAction();
    }
    @name(".t1") table t1_0 {
        actions = {
            a1_0();
            a2_0();
            a4_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: ternary @name("ig_intr_md.ingress_port") ;
        }
        size = 5;
        default_action = NoAction();
    }
    @name(".t2") table t2_0 {
        actions = {
            a1_0();
            a3_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: ternary @name("ig_intr_md.ingress_port") ;
        }
        size = 5;
        default_action = NoAction();
    }
    @name(".t4") table t4_0 {
        actions = {
            a1_0();
            a5_0();
            a7_0();
            a8_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: ternary @name("ig_intr_md.ingress_port") ;
        }
        size = 5;
        default_action = NoAction();
    }
    @name(".t5") table t5_0 {
        actions = {
            a1_0();
            a6_0();
            a9_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.ig_intr_md.ingress_port: ternary @name("ig_intr_md.ingress_port") ;
        }
        size = 5;
        default_action = NoAction();
    }
    apply {
        port_tbl_0.apply();
        if (meta.ig_md.skip_lkups == 1w0) {
            if (meta.ig_md.pktgen_port == 1w1) {
                if (meta.ig_md.pktgen_type == 2w0) 
                    pg_verify_timer_0.apply();
                if (meta.ig_md.pktgen_type == 2w2) 
                    pg_verify_port_down_0.apply();
                if (meta.ig_md.pktgen_type == 2w3) 
                    pg_verify_recirc_0.apply();
            }
            if (meta.ig_md.pfe_override_test == 1w1) 
                switch (eg_tcam_or_exm_0.apply().action_run) {
                    do_exm_0: {
                        e1_0.apply();
                        e2_0.apply();
                        e4_0.apply();
                        e5_0.apply();
                    }
                    do_tcam_0: {
                        t1_0.apply();
                        t2_0.apply();
                        t4_0.apply();
                        t5_0.apply();
                    }
                }

        }
        else 
            if (meta.ig_md.test_recirc == 1w1) 
                do_local_recirc_0.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<pktgen_header_t>(hdr.pgen_header);
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

