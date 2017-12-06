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
    bit<5> _pad;
}

header ipv6_t {
    bit<4>   version;
    bit<8>   trafficClass;
    bit<20>  flowLabel;
    bit<16>  payloadLen;
    bit<8>   nextHdr;
    bit<8>   hopLimit;
    bit<128> srcAddr;
    bit<128> dstAddr;
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
    @name(".ipv6") 
    ipv6_t                                         ipv6;
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract(hdr.ethernet);
        packet.extract(hdr.ipv6);
        transition accept;
    }
}

@name(".ap") action_profile(32w0) ap;

@name(".sel_ap") action_selector(HashAlgorithm.crc32, 32w0, 32w29) sel_ap;

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".ha_cntr") direct_counter(CounterType.packets) ha_cntr;
    @name(".cntr") @min_width(32) counter(32w1000, CounterType.packets_and_bytes) cntr;
    @name(".r0") register<bit<32>>(32w0) r0;
    register_action<bit<32>, bit<32>>(r0) r0_alu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            value = value + 32w1;
        }
    };
    @name(".n") action n() {
    }
    @name(".set_dmac") action set_dmac(bit<48> d) {
        hdr.ethernet.dstAddr = d;
    }
    @name(".a") action a(bit<9> x) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = x;
    }
    @name(".b") action b(bit<9> x, bit<32> i) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = x;
        cntr.count((bit<32>)i);
    }
    @name(".c") action c(bit<9> x) {
        a(x);
        cntr.count((bit<32>)32w1);
    }
    @name(".d") action d(bit<128> x, bit<20> y, bit<32> i) {
        hdr.ipv6.srcAddr = x;
        hdr.ipv6.flowLabel = y;
        cntr.count((bit<32>)i);
    }
    @name(".e") action e() {
        cntr.count((bit<32>)32w0);
    }
    @name(".N") action N(bit<16> x) {
        hdr.ig_intr_md_for_tm.rid = x;
    }
    @name(".r0_inc") action r0_inc() {
        r0_alu.execute();
    }
    @name(".r0_inc_duplicate") action r0_inc_duplicate() {
        r0_alu.execute();
    }
    @name(".set_smac") action set_smac(bit<48> s) {
        hdr.ethernet.srcAddr = s;
    }
    @alpm(1) @name(".alpm") table alpm {
        actions = {
            n;
        }
        key = {
            hdr.ig_intr_md.ingress_port: lpm;
        }
    }
    @name(".e_keyless") table e_keyless {
        actions = {
            set_dmac;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
        }
        size = 10;
    }
    @name(".exm") table exm {
        actions = {
            n;
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact;
        }
    }
    @name(".exm_ap") table exm_ap {
        actions = {
            a;
            b;
            c;
            d;
            e;
        }
        key = {
            hdr.ipv6.isValid(): exact;
            hdr.ipv6.srcAddr  : exact;
            hdr.ipv6.dstAddr  : exact;
        }
        implementation = ap;
    }
    @name(".exm_sel") table exm_sel {
        actions = {
            a;
            b;
            c;
            d;
            e;
        }
        key = {
            hdr.ipv6.isValid()  : exact;
            hdr.ipv6.srcAddr    : exact;
            hdr.ipv6.dstAddr    : exact;
            hdr.ethernet.dstAddr: selector;
            hdr.ethernet.srcAddr: selector;
        }
        implementation = sel_ap;
    }
    @name(".n") action n_0() {
        ha_cntr.count();
    }
    @use_hash_action(1) @name(".ha") table ha {
        actions = {
            n_0;
            @defaultonly n;
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact;
        }
        size = 512;
        default_action = n();
        counters = ha_cntr;
    }
    @name(".p0") table p0 {
        actions = {
            N;
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact;
        }
        size = 288;
    }
    @name(".r") table r {
        actions = {
            r0_inc;
            r0_inc_duplicate;
        }
        size = 1;
        default_action = r0_inc();
    }
    @name(".t_keyless") table t_keyless {
        actions = {
            set_smac;
        }
        key = {
            hdr.ethernet.srcAddr: ternary;
        }
        size = 10;
    }
    @name(".tcam") table tcam {
        actions = {
            n;
        }
        key = {
            hdr.ig_intr_md.ingress_port: ternary;
        }
    }
    @name(".tcam_ap") table tcam_ap {
        actions = {
            a;
            b;
            c;
            d;
            e;
        }
        key = {
            hdr.ipv6.isValid(): exact;
            hdr.ipv6.srcAddr  : exact;
            hdr.ipv6.dstAddr  : lpm;
        }
        implementation = ap;
    }
    @name(".tcam_sel") table tcam_sel {
        actions = {
            a;
            b;
            c;
            d;
            e;
        }
        key = {
            hdr.ipv6.isValid()  : exact;
            hdr.ipv6.srcAddr    : exact;
            hdr.ipv6.dstAddr    : lpm;
            hdr.ethernet.dstAddr: selector;
            hdr.ethernet.srcAddr: selector;
        }
        implementation = sel_ap;
    }
    apply {
        if (1w0 == hdr.ig_intr_md.resubmit_flag) {
            p0.apply();
        }
        exm.apply();
        tcam.apply();
        ha.apply();
        alpm.apply();
        if (hdr.ig_intr_md.ingress_port == 9w0) {
            exm_sel.apply();
        }
        else {
            if (hdr.ig_intr_md.ingress_port == 9w1) {
                tcam_sel.apply();
            }
            else {
                if (hdr.ig_intr_md.ingress_port == 9w2) {
                    exm_ap.apply();
                }
                else {
                    if (hdr.ig_intr_md.ingress_port == 9w3) {
                        tcam_ap.apply();
                    }
                }
            }
        }
        r.apply();
        e_keyless.apply();
        t_keyless.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv6);
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

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

