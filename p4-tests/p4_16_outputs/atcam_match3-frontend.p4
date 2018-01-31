#include <core.p4>
#include <tofino.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<16> h2;
    bit<8>  b1;
    bit<8>  b2;
}

struct partition_t {
    bit<10> partition_index;
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

control IngressP(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    @name("IngressP.noop") action noop_0() {
    }
    @name("IngressP.noop") action noop_2() {
    }
    @name("IngressP.init_index") action init_index_0(bit<10> p_index, bit<9> port) {
        meta.partition.partition_index = p_index;
        ig_intr_tm_md.ucast_egress_port = port;
    }
    @name("IngressP.first") action first_0(bit<32> f2, bit<16> h2) {
        hdr.data.f2 = f2;
        hdr.data.h2 = h2;
    }
    @name("IngressP.set_partition") table set_partition {
        actions = {
            init_index_0();
            noop_0();
        }
        key = {
            hdr.data.b1: exact @name("hdr.data.b1") ;
            hdr.data.b2: exact @name("hdr.data.b2") ;
        }
        default_action = noop_0();
    }
    @atcam_partition_index("partition.partition_index") @atcam_number_partitions(1024) @name("IngressP.atcam_match") table atcam_match {
        actions = {
            first_0();
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
        set_partition.apply();
        atcam_match.apply();
    }
}

control DeparserI(packet_out b, inout headers hdr, in metadata meta) {
    apply {
        b.emit<data_t>(hdr.data);
    }
}

parser ParserE(packet_in b, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract<data_t>(hdr.data);
        transition accept;
    }
}

control EgressP(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr) {
    apply {
    }
}

control DeparserE(packet_out b, inout headers hdr, in metadata meta) {
    apply {
        b.emit<data_t>(hdr.data);
    }
}

Switch<headers, metadata, headers, metadata>(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) main;

