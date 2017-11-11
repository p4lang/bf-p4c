
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
    bit<11> partition_index;
}

struct headers {
    data_t data;
}

struct metadata {
    partition_t partition;
}

parser ParserI(packet_in b,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        b.extract(hdr.data);
        transition accept;
    }
}

control IngressP(inout headers hdr,
                 inout metadata meta,
                 in ingress_intrinsic_metadata_t ig_intr_md,
                 in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                 inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action noop() {}

    action init_index(bit<11> p_index, bit<9> port) {
        meta.partition.partition_index = p_index;
        ig_intr_tm_md.ucast_egress_port = port;
    }

    action first(bit<32> f2, bit<16> h2) {
        hdr.data.f2 = f2;
        hdr.data.h2 = h2;
    }

    table set_partition {
        actions = { init_index; noop; }
        key = { hdr.data.b1 : exact;
                hdr.data.b2 : exact; }
        default_action = noop();
    }

    @atcam_partition_index("partition.partition_index")
    @atcam_number_partitions(2048)
    table atcam_match {
        actions = { first; noop; }
        key = { hdr.data.h1 : ternary;
                meta.partition.partition_index : exact; }
        default_action = noop();
        size = 32768;
    }

    apply {
        set_partition.apply();
        atcam_match.apply();
    }

}

control DeparserI(packet_out b,
                  in headers hdr,
                  in metadata meta) {
    apply { b.emit(hdr.data); }
}

parser ParserE(packet_in b,
               out headers hdr,
               out metadata meta,
               out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract(hdr.data);
        transition accept;
    }
}

control EgressP(inout headers hdr,
                inout metadata meta,
                in egress_intrinsic_metadata_t eg_intr_md,
                in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr) {
    apply { }
}

control DeparserE(packet_out b,
                  in headers hdr,
                  in metadata meta) {
    apply { b.emit(hdr.data); }
}

Switch(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) main;
