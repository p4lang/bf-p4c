// PAC (parde): shallow branching
// ------------------------------
//
// Summary:
//  - Multiple headers with shallow branching in parser
//  - No reconvergence in parse graph
//  - Multiple analyzer stages
//  - Parser matching required to identify headers
//  - Minimal PPU processing to use header
//
// Goals:
//  - Verify simple partitioning across stages
//  - Verify matching.

#include <t5na.p4>

#define PRSR_OVERRIDE

header hdr_1_h {
    bit<32>     f1;
    bit<32>     f2;
    bit<16>     h1;
    bit<8>      b1;
    bit<8>      b2;
}

header hdr_2_h {
    bit<8>      b1;
    bit<8>      b2;
}

header hdr_3_h {
    bit<16>     h1;
    bit<16>     h2;
}

header hdr_4_h {
    bit<32>     f1;
    bit<32>     f2;
}


struct headers {
    hdr_1_h     h1;
    hdr_2_h     h2;
    hdr_3_h     h3;
    hdr_4_h     h4;
}

struct metadata {
}

parser ingressParser(packet_in packet, out headers hdrs,
                     out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md)
{
    state start {
        // FIXME: update this for Tofino5
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdrs.h1);
        transition select(hdrs.h1.h1) {
            16w0x0001 : parse_h2;
            16w0x0002 : parse_h3;
            default :  accept;
        }
    }

    state parse_h2 {
        packet.extract(hdrs.h2);
        transition accept;
    }

    state parse_h3 {
        packet.extract(hdrs.h3);
        transition select(hdrs.h3.h1) {
            16w0x0001 : parse_h4;
            default :  accept;
        }
    }

    state parse_h4 {
        packet.extract(hdrs.h4);
        transition accept;
    }
}
control egress(inout headers hdrs, inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
{
    apply {
        hdrs.h1.b1 = 8w0x11;

        if (hdrs.h2.isValid()) {
            hdrs.h2.b1 = 8w0xff;
        }

        if (hdrs.h3.isValid()) {
            hdrs.h3.h1 = 16w0xffff;
        }

        if (hdrs.h4.isValid()) {
            hdrs.h4.f1 = 32w0xffffffff;
        }
    }
}

#include "common_t5na_test.p4h"


