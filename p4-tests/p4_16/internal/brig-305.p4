#include <core.p4>
#include <tna.p4>       /* TOFINO1_ONLY */

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    int<8>  i8;
    int<16> i16;
    int<32> i32;
}

struct metadata {
   int<8>  i8a;
   int<8>  i8b;
   int<8>  i8c;
   bit<16> f16;
   bit<16> m16;
   bit<16> d16;
   bit<32> f32;
   bit<32> m32;
   bit<32> d32;
   int<16> i16a;
   int<16> i16b;
   int<16> i16c;
   int<32> i32a;
   int<32> i32b;
   int<32> i32c;
}

struct headers {
    data_t data;
}

header ingress_skip_t {
    bit<64> pad;
}

parser ParserI(packet_in b,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    ingress_skip_t skip;
    state start {
        b.extract(ig_intr_md);
        b.extract(skip);
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

    action act(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }
    table test {
        actions = { act; NoAction; }
        key = { hdr.data.f1: exact; }
        default_action = NoAction;
    }
    apply {
        test.apply();
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
        b.extract(eg_intr_md);
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
    apply {
	// bit<16> -> bit<32>
	bit<32> m32 = hdr.data.f1;
	bit<16> m16 = hdr.data.h1;
	bit<8>  m8  = hdr.data.b1;
	meta.f32 = m32 - (bit<32>)14;
	// bit<16> -> bit<16>
	meta.m16 = m16 * 2;
	// bit<16> -> bit<16>
	meta.d16 = m16 / 2;
	// bit<16> -> int<8>
	meta.i8a = (int<8>)(int<16>)m16;
	// bit<16> -> int<16>
	meta.i16a = (int<16>)m16;
	// bit<16> -> int<32>
	meta.i32a = (int<32>)(int<16>)m16;
	// int<16> -> bit<16>
	hdr.data.h1 = (bit<16>)meta.i16a;
	// int<8> -> bit<16>
	hdr.data.h2 = (bit<16>)(bit<8>)meta.i8a;
	// int<32> -> bit<16>
	hdr.data.h3 = (bit<16>)(bit<32>)meta.i32a;
	// emit
	hdr.data.f2 = meta.f32;
	hdr.data.i8 = meta.i8a;
	hdr.data.i16 = meta.i16a;
	hdr.data.i32 = meta.i32a;
    }
}

control DeparserE(packet_out b,
                  inout headers hdr,
                  in metadata meta,
                  in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply { b.emit(hdr.data); }
}

Pipeline(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;
Switch(pipe0) main;
