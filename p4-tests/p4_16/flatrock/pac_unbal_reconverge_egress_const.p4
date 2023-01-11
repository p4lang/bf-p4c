// PAC (parde): branching with unbalanced reconvergence
// ----------------------------------------------------
//
// Summary:
//  - Branching with unbalanced reconvergence
//  - Multiple analyzer stages
//  - Parser matching required to identify headers
//  - Minimal PPU processing to use header
//
// Goals:
//  - Verify that reconvergence points are correctly placed after all
//    dependencies.
//
// This test mimics something like Ethernet, VLAN, and IPv4 where a VLAN header
// may optionally be placed between Ethernet and IPv4.

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


struct headers {
    hdr_1_h     h1;
    hdr_2_h     h2;
    hdr_3_h     h3;
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
        transition parse_h3;
    }

    state parse_h3 {
        packet.extract(hdrs.h3);
        transition accept;
    }
}
control egress(inout headers hdrs, inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
{
    apply {
        if (hdrs.h1.isValid()) {
            hdrs.h1.b2 = 8w0xa1;
        }
        if (hdrs.h2.isValid()) {
            hdrs.h2.b2 = 8w0xb1;
        }
        if (hdrs.h3.isValid()) {
            hdrs.h3.h2 = 16w0xc1c2;
        }
    }
}

#include "common_t5na_test.p4h"


