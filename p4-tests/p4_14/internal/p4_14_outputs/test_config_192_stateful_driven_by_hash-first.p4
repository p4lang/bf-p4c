#include <core.p4>
#include <v1model.p4>

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

header pkt_t {
    bit<32> field_a_32;
    bit<32> field_b_32;
    bit<32> field_c_32;
    bit<32> field_d_32;
    bit<16> field_e_16;
    bit<16> field_f_16;
    bit<16> field_g_16;
    bit<16> field_h_16;
    bit<8>  field_i_8;
    bit<8>  field_j_8;
    bit<8>  field_k_8;
    bit<8>  field_l_8;
}

struct metadata {
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
    @name(".pkt") 
    pkt_t                                          pkt;
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<pkt_t>(hdr.pkt);
        transition accept;
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

@name(".r_em_direct") register<bit<16>>(32w2048) r_em_direct;

@name(".r_em_indirect") register<bit<16>>(32w8192) r_em_indirect;

@name(".r_hash_act") register<bit<8>>(32w256) r_hash_act;

@name(".r_no_key") register<bit<16>>(32w1024) r_no_key;

@name(".r_t_direct") register<bit<16>>(32w3072) r_t_direct;

@name(".r_t_indirect") register<bit<16>>(32w8192) r_t_indirect;

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".b_em_direct") RegisterAction<bit<16>, bit<32>, bit<16>>(r_em_direct) b_em_direct = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = 16w0;
            bit<16> in_value;
            in_value = value;
            value = in_value + 16w1;
            rv = value;
        }
    };
    @name(".b_em_indirect") RegisterAction<bit<16>, bit<32>, bit<16>>(r_em_indirect) b_em_indirect = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = 16w0;
            bit<16> in_value;
            in_value = value;
            value = in_value + 16w5;
            rv = value;
        }
    };
    @name(".b_hash_act") RegisterAction<bit<8>, bit<32>, bit<8>>(r_hash_act) b_hash_act = {
        void apply(inout bit<8> value, out bit<8> rv) {
            rv = 8w0;
            bit<8> in_value;
            in_value = value;
            value = in_value + 8w5;
            rv = value;
        }
    };
    @name(".b_no_key") RegisterAction<bit<16>, bit<32>, bit<16>>(r_no_key) b_no_key = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = 16w0;
            bit<16> in_value;
            in_value = value;
            value = in_value + 16w5;
            rv = value;
        }
    };
    @name(".b_t_direct") RegisterAction<bit<16>, bit<32>, bit<16>>(r_t_direct) b_t_direct = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = 16w0;
            bit<16> in_value;
            in_value = value;
            value = in_value + 16w1;
            rv = value;
        }
    };
    @name(".b_t_indirect") RegisterAction<bit<16>, bit<32>, bit<16>>(r_t_indirect) b_t_indirect = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = 16w0;
            bit<16> in_value;
            in_value = value;
            value = in_value + 16w5;
            rv = value;
        }
    };
    @name(".a_em_direct") action a_em_direct() {
        {
            bit<12> temp;
            hash<bit<12>, bit<12>, tuple<bit<32>, bit<32>>, bit<13>>(temp, HashAlgorithm.random, 12w0, { hdr.pkt.field_a_32, hdr.pkt.field_b_32 }, 13w4096);
            hdr.pkt.field_e_16 = b_em_direct.execute((bit<32>)temp);
        }
    }
    @name(".a_em_indirect") action a_em_indirect() {
        {
            bit<13> temp_0;
            hash<bit<13>, bit<13>, tuple<bit<32>, bit<32>>, bit<14>>(temp_0, HashAlgorithm.random, 13w0, { hdr.pkt.field_a_32, hdr.pkt.field_b_32 }, 14w8192);
            hdr.pkt.field_f_16 = b_em_indirect.execute((bit<32>)temp_0);
        }
    }
    @name(".do_nothing") action do_nothing() {
    }
    @name(".a_hash_act") action a_hash_act() {
        {
            bit<10> temp_1;
            hash<bit<10>, bit<10>, tuple<bit<32>, bit<32>>, bit<11>>(temp_1, HashAlgorithm.random, 10w0, { hdr.pkt.field_a_32, hdr.pkt.field_b_32 }, 11w1024);
            hdr.pkt.field_j_8 = b_hash_act.execute((bit<32>)temp_1);
        }
    }
    @name(".a_no_key") action a_no_key() {
        {
            bit<16> temp_2;
            hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>>, bit<17>>(temp_2, HashAlgorithm.random, 16w0, { hdr.pkt.field_a_32, hdr.pkt.field_b_32 }, 17w65536);
            hdr.pkt.field_i_8 = (bit<8>)b_no_key.execute((bit<32>)temp_2);
        }
    }
    @name(".a_t_direct") action a_t_direct() {
        {
            bit<12> temp_3;
            hash<bit<12>, bit<12>, tuple<bit<32>, bit<32>>, bit<13>>(temp_3, HashAlgorithm.random, 12w0, { hdr.pkt.field_a_32, hdr.pkt.field_b_32 }, 13w4096);
            hdr.pkt.field_g_16 = b_t_direct.execute((bit<32>)temp_3);
        }
    }
    @name(".a_t_indirect") action a_t_indirect() {
        {
            bit<13> temp_4;
            hash<bit<13>, bit<13>, tuple<bit<32>, bit<32>>, bit<14>>(temp_4, HashAlgorithm.random, 13w0, { hdr.pkt.field_a_32, hdr.pkt.field_b_32 }, 14w8192);
            hdr.pkt.field_h_16 = b_t_indirect.execute((bit<32>)temp_4);
        }
    }
    @name(".t_em_direct") table t_em_direct {
        actions = {
            a_em_direct();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_a_32: exact @name("pkt.field_a_32") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    @name(".t_em_indirect") table t_em_indirect {
        actions = {
            a_em_indirect();
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_a_32: exact @name("pkt.field_a_32") ;
        }
        size = 2048;
        default_action = NoAction();
    }
    @name(".t_hash_act") table t_hash_act {
        actions = {
            a_hash_act();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_d_32[9:0]: exact @name("pkt.field_d_32") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".t_no_key") table t_no_key {
        actions = {
            a_no_key();
        }
        size = 1024;
        default_action = a_no_key();
    }
    @name(".t_t_direct") table t_t_direct {
        actions = {
            a_t_direct();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_a_32: ternary @name("pkt.field_a_32") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    @name(".t_t_indirect") table t_t_indirect {
        actions = {
            a_t_indirect();
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_a_32: ternary @name("pkt.field_a_32") ;
        }
        size = 2048;
        default_action = NoAction();
    }
    apply {
        t_em_direct.apply();
        t_em_indirect.apply();
        t_t_direct.apply();
        t_t_indirect.apply();
        t_no_key.apply();
        t_hash_act.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<pkt_t>(hdr.pkt);
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

