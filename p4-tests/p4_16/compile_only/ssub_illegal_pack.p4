#include <tna.p4>
#define DATA_T_OVERRIDE

// Force hdr.data.h1 into a 32b container.
// This should produce a compiler error because hdr.data.h1 is used in a
// saturating subtract and sources must be in containers by themselves.
@pa_container_size("ingress", "hdr.data.h1", 32)

header data_t {
    bit<8>  b1;
    bit<8>  b2;
    bit<16> h1;
    bit<32> f1;
    bit<8>  b3;
}

struct metadata {
}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    bit<16> hdr_len = 16w100;
    bit<16> hdr_check;

    action adj() {
        hdr_check = hdr.data.h1 |-| hdr_len;
    }

    table test1 {
        key = { hdr.data.f1 : exact; }
        actions = {
            NoAction;
            adj;
        }

        const default_action = NoAction;
    }

    apply {
        hdr_check = 0;
        ig_intr_tm_md.ucast_egress_port = 3;
        test1.apply();
        if (hdr_check != 0) {
            hdr.data.b3 = 8w0xff;
        }
    }
}

#include "common_tna_test.h"
