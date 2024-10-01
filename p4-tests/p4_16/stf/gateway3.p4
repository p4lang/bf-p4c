#include <core.p4>
#include <v1model.p4>

#define DATA_T_OVERRIDE
header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    int<8>  b1;
    int<5>  x1;
    int<3>  x2;
    int<6>  x3;
    int<2>  x4;
}

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                inout standard_metadata_t standard_metadata) {
    apply {
        standard_metadata.egress_spec = 2;
        if (hdr.data.b1 >= -3 && hdr.data.b1 < 7)
            hdr.data.h1[0:0] = 1;
        if (hdr.data.b1 >= -80 && hdr.data.b1 < 80)
            hdr.data.h1[1:1] = 1;
        if (hdr.data.x1 >= -3 && hdr.data.x1 < 7)
            hdr.data.h1[2:2] = 1;
        if (hdr.data.x2 >= -1 && hdr.data.x2 < 3)
            hdr.data.h1[3:3] = 1;
        if (hdr.data.x3 >= -3 && hdr.data.x3 < 7)
            hdr.data.h1[4:4] = 1;
    }
}

#include "common_v1_test.h"
