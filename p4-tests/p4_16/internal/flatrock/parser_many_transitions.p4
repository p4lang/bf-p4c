#include <t5na.p4>

header data_h {
    bit<32>     f1;
    bit<32>     f2;
    bit<16>     h1;
    bit<8>      b1;
    bit<8>      b2;
}

struct headers {
    data_h      data1;
    data_h      data2;
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
        packet.extract(hdrs.data1);

        transition select(hdrs.data1.h1) {
            0x0001 &&& 0xffff : parse_b1;
            0x0002 &&& 0xffff : parse_b1;
            0x0003 &&& 0xffff : parse_b1;
            0x0004 &&& 0xffff : parse_b1;
            0x0005 &&& 0xffff : parse_b1;
            0x0006 &&& 0xffff : parse_b1;
            0x0007 &&& 0xffff : parse_b1;
            0x0008 &&& 0xffff : parse_b1;
            0x0009 &&& 0xffff : parse_b1;
            0x0010 &&& 0xffff : parse_b1;
            0x0011 &&& 0xffff : parse_b1;
            0x0012 &&& 0xffff : parse_b1;
            0x0013 &&& 0xffff : parse_b1;
            0x0014 &&& 0xffff : parse_b1;
            0x0015 &&& 0xffff : parse_b1;
            0x0016 &&& 0xffff : parse_b1;
            0x0017 &&& 0xffff : parse_b1;
            0x0018 &&& 0xffff : parse_b1;
            0x0019 &&& 0xffff : parse_b1;
            0x0020 &&& 0xffff : parse_b1;
            0x0021 &&& 0xffff : parse_b1;
            0x0022 &&& 0xffff : parse_b1;
            0x0023 &&& 0xffff : parse_b1;
            0x0024 &&& 0xffff : parse_b1;
            0x0025 &&& 0xffff : parse_b1;
            0x0026 &&& 0xffff : parse_b1;
            0x0027 &&& 0xffff : parse_b1;
            0x0028 &&& 0xffff : parse_b1;
            0x0029 &&& 0xffff : parse_b1;
            0x0030 &&& 0xffff : parse_b1;
            0x0031 &&& 0xffff : parse_b1;
            0x0032 &&& 0xffff : parse_b1;
            0x0033 &&& 0xffff : parse_b1;
            0x0034 &&& 0xffff : parse_b1;
            0x0035 &&& 0xffff : parse_b1;
            0x0036 &&& 0xffff : parse_b1;
            0x0037 &&& 0xffff : parse_b1;
            0x0038 &&& 0xffff : parse_b1;
            0x0039 &&& 0xffff : parse_b1;
            0x0040 &&& 0xffff : parse_b1;
            0x0041 &&& 0xffff : parse_b1;
            0x0042 &&& 0xffff : parse_b1;
            0x0043 &&& 0xffff : parse_b1;
            0x0044 &&& 0xffff : parse_b1;
            0x0045 &&& 0xffff : parse_b1;
            0x0046 &&& 0xffff : parse_b1;
            0x0047 &&& 0xffff : parse_b1;
            0x0048 &&& 0xffff : parse_b1;
            0x0049 &&& 0xffff : parse_b1;
            0x0050 &&& 0xffff : parse_b1;
            0x0051 &&& 0xffff : parse_b1;
            0x0052 &&& 0xffff : parse_b1;
            0x0053 &&& 0xffff : parse_b1;
            0x0054 &&& 0xffff : parse_b1;
            0x0055 &&& 0xffff : parse_b1;
            0x0056 &&& 0xffff : parse_b1;
            0x0057 &&& 0xffff : parse_b1;
            0x0058 &&& 0xffff : parse_b1;
            0x0059 &&& 0xffff : parse_b1;
            0x0060 &&& 0xffff : parse_b1;
            0x0061 &&& 0xffff : parse_b1;
            0x0062 &&& 0xffff : parse_b1;
            0x0063 &&& 0xffff : parse_b1;
            0x0064 &&& 0xffff : parse_b1;
            0x0065 &&& 0xffff : parse_b1;
            0x0066 &&& 0xffff : parse_b1;
            0x0067 &&& 0xffff : parse_b1;
            0x0068 &&& 0xffff : parse_b1;
            0x0069 &&& 0xffff : parse_b1;
            default :  accept;
        }
    }

    state parse_b1 {
        packet.extract(hdrs.data2);
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
