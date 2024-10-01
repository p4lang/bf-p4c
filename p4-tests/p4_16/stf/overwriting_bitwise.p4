#include <tna.p4>

struct metadata { }

#define DATA_T_OVERRIDE
header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<2>  x1;
    bit<1>  x2;
    bit<1>  x3;
    bit<4>  x4;
    bit<8>  b2;
}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action noop() { }
    action t1() { // AND
        hdr.data.x4 = hdr.data.x4 & 4w0x2;
    }
    action t2() { // OR
        hdr.data.x1 = hdr.data.x1 | 2w0x1;
        hdr.data.x2 = hdr.data.x2 | 1w0x1;
    }
    action t3() { // XOR
        hdr.data.x4[3:2] = hdr.data.x4[3:2] ^ 2w0x2;
    }
    action t4() { // XNOR
        hdr.data.x1 = ~hdr.data.x1 ^ 2w0x1;
        hdr.data.x4 = ~hdr.data.x4 ^ 4w0xd;
    }

    table test {
        key = { hdr.data.f1 : exact; }
        actions = { noop; t1; t2; t3; t4; }
        size = 256;
    }

    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        test.apply();
    }
}

#include "common_tna_test.h"
