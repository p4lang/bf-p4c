// mirror simple
// -------------
//
// Tests basic mirror functionality:
//  - ingress mirror
//  - egresss mirror - input pkt
//  - egresss mirror - output pkt

#include <t5na.p4>

header data_h {
    bit<32>     f1;
    bit<32>     f2;
    bit<16>     h1;
    bit<16>     h2;
    bit<16>     h3;
    bit<8>      b1;
    bit<8>      b2;
}

struct headers {
    data_h       data;
}

struct metadata {
    MirrorId_t   mirr_sess_id;
}

#define HAVE_INGRESS
control ingress(in headers hdrs, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action noop() { }
    action set_mcast_a(MulticastGroupId_t mcast_grp) {
        ig_intr_tm_md.mcast_grp_a = mcast_grp;
    }
    action set_mcast_b(MulticastGroupId_t mcast_grp) {
        ig_intr_tm_md.mcast_grp_b = mcast_grp;
    }

    table ig_mcast_a_tbl {
        key = {
            hdrs.data.b1 : exact;
        }
        actions = { noop; set_mcast_a; }
        size = 128;
        const default_action = noop();
    }

    table ig_mcast_b_tbl {
        key = {
            hdrs.data.b2 : exact;
        }
        actions = { noop; set_mcast_b; }
        size = 128;
        const default_action = noop();
    }

    apply {
        ig_intr_tm_md.ucast_egress_pipe = ig_intr_md.ingress_pipe;
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;

        // ig_mcast_a_tbl.apply();
        // ig_mcast_b_tbl.apply();

        if (hdrs.data.b1[0:0] == 0x1) {
            ig_intr_tm_md.mcast_grp_a = hdrs.data.h1;
        }

        if (hdrs.data.b1[1:1] == 0x1) {
            ig_intr_tm_md.mcast_grp_b = hdrs.data.h2;
        }

        if (hdrs.data.b1[2:2] == 0x1) {
            // FIXME: Matej: please uncomment these and check out the failure
            // Seeing:
            //   Compiler Bug: Offset of extract (extract inbuf bit[0..15] to PHV-allocated hdrs.data/data.h1;) source in input buffer (0) is lower than offset of destination field (64)
            // ig_intr_tm_md.level1_mcast_hash = hdrs.data.f1[28:16];
            // ig_intr_tm_md.level2_mcast_hash = hdrs.data.f1[12:0];
            // ig_intr_tm_md.level1_exclusion_id = hdrs.data.f2[31:16];
            // ig_intr_tm_md.level2_exclusion_id = hdrs.data.f2[9:0];
            ig_intr_tm_md.rid = hdrs.data.h3;
        }
    }
}

control egress(inout headers hdrs, inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
{
    apply { }
}

#include "common_t5na_test.p4h"
