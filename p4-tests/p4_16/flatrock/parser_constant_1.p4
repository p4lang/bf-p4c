#include <t5na.p4>

header data_h {
    bit<64>     d1;
    bit<32>     f1;
    bit<32>     f2;
    bit<16>     h1;
    bit<8>      b1;
    bit<8>      b2;
}

struct headers {
    data_h      data;
}
struct metadata {
}

#define PRSR_OVERRIDE
parser ingressParser(packet_in packet, out headers hdrs,
                     out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md)
{
    state start {
        // FIXME: update this for Tofino5
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdrs.data);

        hdrs.data.d1 = 0x12345678deadbeef;
        hdrs.data.f1 = 0x11111111;
        hdrs.data.f2 = 0x22222222;
        hdrs.data.h1 = 0x3333;
        hdrs.data.b1 = 0x42;
        // FIXME (P4C-4686)
        // When all header fields are extracted from other source than packet
        // modify_flag action setting $valid field for the header is not generated.
        // Therefore the following field is commented out so that there is at least
        // one field extracted from the packet and the test can work until the generating
        // of modify_flag action is fixed to work even in this corner case.
        // hdrs.data.b2 = 0x43;
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
