#include <t5na.p4>

#define PRSR_OVERRIDE

header hdr_1_h {
    bit<16>     h1;
    bit<16>     h2;
}

struct headers {
    hdr_1_h     h1;
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
        transition select(hdrs.h1.h1, hdrs.h1.h2) {
            (16w0x0001, 16w0x0001) : parse_h2;
            default :  accept;
        }
    }

    state parse_h2 {
        transition accept;
    }
}
control egress(inout headers hdrs, inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
{
    apply { }
}

#include "common_t5na_test.p4h"


