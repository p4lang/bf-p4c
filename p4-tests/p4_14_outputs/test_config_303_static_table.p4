#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<8>   bm_0;
    bit<8>   bm_1;
    bit<8>   i2e_0;
    bit<16>  i2e_1;
    bit<32>  i2e_2;
    bit<48>  i2e_3;
    bit<64>  i2e_4;
    bit<80>  i2e_5;
    bit<96>  i2e_6;
    bit<128> i2e_7;
    bit<8>   e2e_0;
    bit<16>  e2e_1;
    bit<32>  e2e_2;
    bit<48>  e2e_3;
    bit<64>  e2e_4;
    bit<80>  e2e_5;
    bit<96>  e2e_6;
    bit<128> e2e_7;
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
    bit<5> _pad;
    bit<8> parser_counter;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

struct metadata {
    @pa_container_size("ingress", "meta.i2e_0", 8) @pa_container_size("ingress", "meta.i2e_1", 16) @pa_container_size("ingress", "meta.i2e_2", 32) @pa_container_size("ingress", "meta.i2e_3", 16, 32) @pa_container_size("ingress", "meta.i2e_4", 32, 32) @pa_container_size("ingress", "meta.i2e_5", 16, 32, 32) @pa_container_size("ingress", "meta.i2e_6", 32, 32, 32) @pa_container_size("ingress", "meta.i2e_7", 32) @pa_container_size("egress", "meta.e2e_0", 8) @pa_container_size("egress", "meta.e2e_1", 16) @pa_container_size("egress", "meta.e2e_2", 32) @pa_container_size("egress", "meta.e2e_3", 16, 32) @pa_container_size("egress", "meta.e2e_4", 32, 32) @pa_container_size("egress", "meta.e2e_5", 16, 32, 32) @pa_container_size("egress", "meta.e2e_6", 32, 32, 32) @pa_container_size("egress", "meta.e2e_7", 32) @name(".meta") 
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
    @name(".ipv4") 
    ipv4_t                                         ipv4;
    @name(".tcp") 
    tcp_t                                          tcp;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w6): parse_tcp;
            default: accept;
        }
    }
    @name(".parse_tcp") state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_pkt") action set_pkt(bit<8> p) {
        hdr.ethernet.dstAddr = 48w0xffffffffffff;
    }
    @name(".do_nothing") action do_nothing() {
    }
    @name(".ec0") action ec0() {
        meta.meta.e2e_0 = 8w0;
        clone3(CloneType.E2E, (bit<32>)32w0, { meta.meta.e2e_0 });
    }
    @name(".ec1") action ec1() {
        meta.meta.e2e_1 = 16w1;
        clone3(CloneType.E2E, (bit<32>)32w1, { meta.meta.e2e_1 });
    }
    @name(".ec2") action ec2() {
        meta.meta.e2e_2 = 32w2;
        clone3(CloneType.E2E, (bit<32>)32w2, { meta.meta.e2e_2 });
    }
    @name(".ec3") action ec3() {
        meta.meta.e2e_3 = 48w3;
        clone3(CloneType.E2E, (bit<32>)32w3, { meta.meta.e2e_3 });
    }
    @name(".ec4") action ec4() {
        meta.meta.e2e_4 = 64w4;
        clone3(CloneType.E2E, (bit<32>)32w4, { meta.meta.e2e_4 });
    }
    @name(".ec5") action ec5() {
        meta.meta.e2e_5 = 80w5;
        clone3(CloneType.E2E, (bit<32>)32w5, { meta.meta.e2e_5 });
    }
    @name(".ec6") action ec6() {
        meta.meta.e2e_6 = 96w6;
        clone3(CloneType.E2E, (bit<32>)32w6, { meta.meta.e2e_6 });
    }
    @name(".ec7") action ec7() {
        meta.meta.e2e_7 = 128w7;
        clone3(CloneType.E2E, (bit<32>)32w7, { meta.meta.e2e_7 });
    }
    @name(".et0") table et0 {
        actions = {
            set_pkt;
            do_nothing;
        }
        key = {
            meta.meta.bm_0: exact;
            meta.meta.bm_1: exact;
        }
        size = 2048;
    }
    @name(".et1") table et1 {
        actions = {
            ec0;
            ec1;
            ec2;
            ec3;
            ec4;
            ec5;
            ec6;
            ec7;
            do_nothing;
        }
        key = {
            hdr.eg_intr_md_from_parser_aux.clone_src: exact;
            hdr.eg_intr_md.pkt_length               : exact;
            hdr.ethernet.etherType                  : exact;
        }
        size = 1024;
    }
    apply {
        if (hdr.eg_intr_md_from_parser_aux.clone_src == 4w0) {
            et0.apply();
        }
        et1.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_bm") action set_bm(bit<8> a, bit<8> b, bit<9> p) {
        meta.meta.bm_0 = a;
        meta.meta.bm_1 = b;
        hdr.ig_intr_md_for_tm.ucast_egress_port = p;
    }
    @name(".do_nothing") action do_nothing() {
    }
    @name(".ic0") action ic0() {
        meta.meta.i2e_0 = 8w0;
        clone3(CloneType.I2E, (bit<32>)32w0, { meta.meta.i2e_0 });
    }
    @name(".ic1") action ic1() {
        meta.meta.i2e_1 = 16w1;
        clone3(CloneType.I2E, (bit<32>)32w1, { meta.meta.i2e_1 });
    }
    @name(".ic2") action ic2() {
        meta.meta.i2e_2 = 32w2;
        clone3(CloneType.I2E, (bit<32>)32w2, { meta.meta.i2e_2 });
    }
    @name(".ic3") action ic3() {
        meta.meta.i2e_3 = 48w3;
        clone3(CloneType.I2E, (bit<32>)32w3, { meta.meta.i2e_3 });
    }
    @name(".ic4") action ic4() {
        meta.meta.i2e_4 = 64w4;
        clone3(CloneType.I2E, (bit<32>)32w4, { meta.meta.i2e_4 });
    }
    @name(".ic5") action ic5() {
        meta.meta.i2e_5 = 80w5;
        clone3(CloneType.I2E, (bit<32>)32w5, { meta.meta.i2e_5 });
    }
    @name(".ic6") action ic6() {
        meta.meta.i2e_6 = 96w6;
        clone3(CloneType.I2E, (bit<32>)32w6, { meta.meta.i2e_6 });
    }
    @name(".ic7") action ic7() {
        meta.meta.i2e_7 = 128w7;
        clone3(CloneType.I2E, (bit<32>)32w7, { meta.meta.i2e_7 });
    }
    @name(".it0") table it0 {
        actions = {
            set_bm;
            do_nothing;
        }
        key = {
            hdr.ethernet.etherType[7:0]: exact;
        }
        size = 256;
    }
    @name(".it1") table it1 {
        actions = {
            ic0;
            ic1;
            ic2;
            ic3;
            ic4;
            ic5;
            ic6;
            ic7;
            do_nothing;
        }
        key = {
            hdr.ethernet.etherType[7:0]: exact;
        }
        size = 256;
    }
    apply {
        it0.apply();
        it1.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
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

