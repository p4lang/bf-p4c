// Test to verify that each slice assigned from a random-number generator gets
// a different value.
//
// Test includes code to resubmit the packet and fetch the RNG again if any
// slices have the same. A single run has ~1.2% chance of two slices having the
// same value. Two runs have ~0.014% chance of two slices in each run having
// the same value.

#include <tna.p4>
#define DATA_T_OVERRIDE

header data_t {
    bit<16> f1;
    bit<8>  f2;
    bit<16> f3;
    bit<8>  f4;
    bit<8>  f5;
    bit<8>  f6;
    bit<8>  f7;
}

struct metadata {
    bit<24> rand_num;
}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    Random<bit<24>>() my_rng;
    bit<8> tmp;

    action set_rand() {
        meta.rand_num = my_rng.get();
    }

    table test1 {
        key = { hdr.data.f1 : exact; }
        actions = {
            NoAction;
            set_rand;
        }

        const default_action = NoAction;
    }

    action set_f3(bit<16> val) {
        hdr.data.f3 = val;
    }

    table test2 {
        key = { meta.rand_num : exact; }
        actions = {
            NoAction;
            set_f3;
        }

        const default_action = NoAction;
    }

    apply {
        ig_intr_tm_md.ucast_egress_port = 3;

        test1.apply();

        if (hdr.data.f1[15:15] == 1) {
            hdr.data.f2 = meta.rand_num[7:0];
            hdr.data.f4 = meta.rand_num[15:8];
            hdr.data.f6 = meta.rand_num[23:16];
        }

        hdr.data.f3 = 0;
        tmp = hdr.data.f5;
        hdr.data.f5 = hdr.data.f7;
        hdr.data.f7 = tmp;

        test2.apply();

        if (hdr.data.f1[13:13] == 1) {
            meta.rand_num[15:8] = meta.rand_num[15:8] + 1;
        }


        if (hdr.data.f1[14:14] == 1) {
            // Resubmit if any two slices match as there is a small chance that
            // they would naturally
            if (meta.rand_num[7:0] == meta.rand_num[15:8] ||
                    meta.rand_num[7:0] == meta.rand_num[23:16] ||
                    meta.rand_num[15:8] == meta.rand_num[23:16]) {
                if (ig_intr_md.resubmit_flag == 0) {
                    ig_intr_dprs_md.resubmit_type = 1;
                }
            }

            if (meta.rand_num[7:0] != meta.rand_num[15:8]) {
                hdr.data.f2 = 1;
            }
            if (meta.rand_num[7:0] != meta.rand_num[23:16]) {
                hdr.data.f4 = 2;
            }
            if (meta.rand_num[15:8] != meta.rand_num[23:16]) {
                hdr.data.f6 = 3;
            }
        }
    }
}

control ingressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                        in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
    Resubmit() resubmit;

    apply {
        if (ig_intr_md_for_dprs.resubmit_type == 1) {
            resubmit.emit();
        }
        packet.emit(hdr);
    }
}

#define INGRESS_DPRSR_OVERRIDE
#include "common_tna_test.h"
