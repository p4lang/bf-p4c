// PAC (parde): wide branching
// ---------------------------
//
// Summary:
//  - Multiple headers with *wide* branching in parser
//  - No reconvergence in parse graph
//  - Multiple analyzer stages
//  - Too many choices to fit in a single analyzer stage
//  - Parser matching required to identify headers
//  - Minimal PPU processing to use header
//
// Goals:
//  - Verify ability to spill large nubmers of states across stages.
//
// Assumptions:
//  - 24 matches per analyzer; have 30 total next states from main. Adjust if
//    the number of analyzer stages changes.

#include <t5na.p4>

#define PRSR_OVERRIDE

header hdr_main_h {
    bit<32>      ctrl;
}

header hdr_b1_h {
    bit<8>      f1;
}

header hdr_h1_h {
    bit<16>     f1;
}

header hdr_w1_h {
    bit<32>     f1;
}


struct headers {
    hdr_main_h  main;

    hdr_b1_h    b1;
    hdr_h1_h    h1;
    hdr_w1_h    w1;
}

struct metadata {
}

parser ingressParser(packet_in packet, out headers hdrs,
                     out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md)
{
    state start {
        packet.extract(hdrs.main);
        transition select(hdrs.main.ctrl) {
            0x00000001 &&& 0xffffffff : parse_b1;
            0x00000002 &&& 0xffffffff : parse_b1;
            0x00000004 &&& 0xffffffff : parse_b1;
            0x00000008 &&& 0xffffffff : parse_b1;
            0x00000010 &&& 0xffffffff : parse_b1;
            0x00000020 &&& 0xffffffff : parse_b1;
            0x00000040 &&& 0xffffffff : parse_b1;
            0x00000080 &&& 0xffffffff : parse_b1;
            0x00000100 &&& 0xffffffff : parse_b1;
            0x00000200 &&& 0xffffffff : parse_b1;

            0x00000400 &&& 0xffffffff : parse_h1;
            0x00000800 &&& 0xffffffff : parse_h1;
            0x00001000 &&& 0xffffffff : parse_h1;
            0x00002000 &&& 0xffffffff : parse_h1;
            0x00004000 &&& 0xffffffff : parse_h1;
            0x00008000 &&& 0xffffffff : parse_h1;
            0x00010000 &&& 0xffffffff : parse_h1;
            0x00020000 &&& 0xffffffff : parse_h1;
            0x00040000 &&& 0xffffffff : parse_h1;
            0x00080000 &&& 0xffffffff : parse_h1;

            0x00100000 &&& 0xffffffff : parse_w1;
            0x00200000 &&& 0xffffffff : parse_w1;
            0x00400000 &&& 0xffffffff : parse_w1;
            0x00800000 &&& 0xffffffff : parse_w1;
            0x01000000 &&& 0xffffffff : parse_w1;
            0x02000000 &&& 0xffffffff : parse_w1;
            0x04000000 &&& 0xffffffff : parse_w1;
            0x08000000 &&& 0xffffffff : parse_w1;
            0x10000000 &&& 0xffffffff : parse_w1;
            0x20000000 &&& 0xffffffff : parse_w1;

            default :  accept;
        }
    }

    state parse_b1 {
        packet.extract(hdrs.b1);
        transition accept;
    }

    state parse_h1 {
        packet.extract(hdrs.h1);
        transition accept;
    }

    state parse_w1 {
        packet.extract(hdrs.w1);
        transition accept;
    }
}
control egress(inout headers hdrs, inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
{
    apply {
        if (hdrs.b1.isValid() && hdrs.b1.f1 != 8w0) hdrs.b1.f1 = 8w0xff;

        if (hdrs.h1.isValid() && hdrs.h1.f1 != 16w0) hdrs.h1.f1 = 16w0xffff;

        if (hdrs.w1.isValid() && hdrs.w1.f1 != 32w0) hdrs.w1.f1 = 32w0xffffffff;
    }
}

#include "common_t5na_test.p4h"
