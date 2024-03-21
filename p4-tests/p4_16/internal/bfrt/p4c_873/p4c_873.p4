#include <core.p4>
#include <v1model.p4>
struct metadata { }
#include "includes/trivial_parser.h"

control ingress(inout headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
    apply {
        hdr.data.h1 = 255;
        standard_metadata.egress_spec = 10;
    }
}

#include "includes/common_v1_test.h"
