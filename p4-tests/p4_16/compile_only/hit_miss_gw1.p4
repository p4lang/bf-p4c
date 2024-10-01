#include <tna.p4>

header data_t {
    bit<8>  c1;
    bit<8>  c2;
    bit<8>  c3;
    bit<32> r1;
    bit<32> r2;
    bit<32> r3;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
    bit<8>  b5;
    bit<8>  b6;
}

struct partition_t {
    bit<10> partition_index;
}

struct headers {
    data_t data;
}

struct metadata { }


parser ParserI(packet_in b,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        b.extract(hdr.data);
        transition accept;
    }
}

control IngressP(
        inout headers hdr,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action noop() {}

    action setb1(bit<8> b1) {
        hdr.data.b1 = b1;
    }

    action setb2(bit<8> b2) {
        hdr.data.b2 = b2;
    }

    action setb3(bit<8> b3) {
        hdr.data.b3 = b3;
    }

    table t1 {
        key = { hdr.data.r1 : exact; }
        actions = { setb1; noop; }
        size = 1024;
        const default_action = noop;
    }

    table t2 {
        key = { hdr.data.r2 : exact; }
        actions = { setb2; noop; }
        size = 1024;
        const default_action = noop;
    }

    table t3 {
        key = { hdr.data.b1 : exact;
                hdr.data.b2 : exact; }
        actions = { setb3;  noop; }
        size = 1024;
    }

    apply {
        if (hdr.data.c1 == 0) {
            if (t1.apply().miss) {
                t2.apply();
            }
            t3.apply();
        }
    }
}

control DeparserI(
        packet_out b,
        inout headers hdr,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
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

control EgressP(
        inout headers hdr,
        inout metadata meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply { }
}

control DeparserE(packet_out b,
                  inout headers hdr,
                  in metadata meta,
                  in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply { b.emit(hdr.data); }
}

Pipeline(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;
Switch(pipe0) main;
