#include <tna.p4>

struct tuple_0 {
    bit<8> field;
    bit<8> field_0;
    bit<8> field_1;
    bit<8> field_2;
    bit<8> field_3;
    bit<8> field_4;
    bit<8> field_5;
    bit<8> field_6;
    bit<8> field_7;
    bit<8> field_8;
    bit<8> field_9;
    bit<8> field_10;
    bit<8> field_11;
    bit<8> field_12;
    bit<8> field_13;
    bit<8> field_14;
}
#include <tna.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<16> h2;
    bit<8>  b1;
    bit<8>  b2;
}

struct partition_t {
    bit<12> partition_index;
}

struct headers {
    data_t data;
}

struct metadata {
    partition_t partition;
}

parser ParserI(packet_in b, out headers hdr, out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        b.extract<data_t>(hdr.data);
        transition accept;
    }
}

control IngressP(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    @name("IngressP.noop") action noop() {
    }
    @name("IngressP.noop") action noop_2() {
    }
    @name("IngressP.init_index") action init_index(bit<12> p_index, bit<9> port) {
        meta.partition.partition_index = p_index;
        ig_intr_tm_md.ucast_egress_port = port;
    }
    @name("IngressP.first") action first(bit<32> f2, bit<16> h2) {
        hdr.data.f2 = f2;
        hdr.data.h2 = h2;
    }
    @name("IngressP.set_partition") table set_partition_0 {
        actions = {
            init_index();
            noop();
        }
        key = {
            hdr.data.b1: exact @name("hdr.data.b1") ;
            hdr.data.b2: exact @name("hdr.data.b2") ;
        }
        default_action = noop();
    }
    @atcam_partition_index("partition.partition_index") @atcam_number_partitions(4096) @name("IngressP.atcam_match") table atcam_match_0 {
        actions = {
            first();
            noop_2();
        }
        key = {
            hdr.data.h1                   : ternary @name("hdr.data.h1") ;
            meta.partition.partition_index: exact @name("meta.partition.partition_index") ;
        }
        default_action = noop_2();
        size = 32768;
    }
    apply {
        set_partition_0.apply();
        atcam_match_0.apply();
    }
}

control DeparserI(packet_out b, inout headers hdr, in metadata meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    @hidden action act() {
        b.emit<data_t>(hdr.data);
    }
    @hidden table tbl_act {
        actions = {
            act();
        }
        const default_action = act();
    }
    apply {
        tbl_act.apply();
    }
}

parser ParserE(packet_in b, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract<data_t>(hdr.data);
        transition accept;
    }
}

control EgressP(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md, inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

control DeparserE(packet_out b, inout headers hdr, in metadata meta, in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    @hidden action act_0() {
        b.emit<data_t>(hdr.data);
    }
    @hidden table tbl_act_0 {
        actions = {
            act_0();
        }
        const default_action = act_0();
    }
    apply {
        tbl_act_0.apply();
    }
}

Pipeline<headers, metadata, headers, metadata>(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;

Switch<headers, metadata, headers, metadata, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;
