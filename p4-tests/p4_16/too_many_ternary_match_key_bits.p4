#include <core.p4>
#include <tna.p4>

header data_h {
    bit<128>      f1;
    bit<128>      f2;
    bit<128>      f3;
    bit<128>      f4;
}

struct metadata {
    bit<32>       w1;
    bit<16>       h1;
    bit<8>        b1;
}

struct packet_t {
    data_h      data;
}

parser parserI(
        packet_in b,
        out packet_t hdrs,
        out metadata meta,
        out ingress_intrinsic_metadata_t ig_intr_md)
{
    state start {
        b.extract(ig_intr_md);
        b.extract(hdrs.data);
        meta.w1 = 1234;
        meta.h1 = 24;
        meta.b1 = 9;
        transition accept;
    }
}

control ingress(
        inout packet_t hdrs, 
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action setb1(bit<9> port, bit<128> val) {
        hdrs.data.f1 = val;
        ig_intr_tm_md.ucast_egress_port = port;
    }
    action noop() { }

    table test1 {
        key = {
            hdrs.data.f1 : ternary;
            hdrs.data.f2 : ternary;
            hdrs.data.f3 : ternary;
            hdrs.data.f4 : ternary;
            meta.w1      : ternary;
            meta.h1      : ternary;
            meta.b1      : ternary;
        }
        actions = {
            setb1;
            noop;
        }
    }

    apply {
        test1.apply();
    }
}

control deparserI(
        packet_out b,
        inout packet_t hdrs,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        b.emit(hdrs.data);
    }
}

parser parserE(
        packet_in b,
        out packet_t hdrs,
        out metadata meta,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract(eg_intr_md);
        b.extract(hdrs.data);
        transition accept;
    }
}

control egress(
        inout packet_t hdrs, 
        inout metadata meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply { }
}

control deparserE(
        packet_out b,
        inout packet_t hdrs,
        in metadata meta,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md) {
    apply {
        b.emit(hdrs.data);
    }
}

Pipeline(parserI(), ingress(), deparserI(), parserE(), egress(), deparserE()) pipe0;
Switch(pipe0) main;
