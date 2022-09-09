/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(
    /* User */
    inout headers hdr,
    inout metadata meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    Register<bit<32>, bit<10>>(1024) reg;

    RegisterAction<bit<32>, bit<10>, bit<32>>(reg) reg_act_1 = {
        void apply(inout bit<32> reg_data) {
            reg_data = 1;
        }
    };

    RegisterAction<bit<32>, bit<10>, bit<32>>(reg) reg_act_2 = {
        void apply(inout bit<32> reg_data) {
            reg_data = 2;
        }
    };

    RegisterAction<bit<32>, bit<10>, bit<32>>(reg) reg_act_3 = {
        void apply(inout bit<32> reg_data) {
            reg_data = 3;
        }
    };

    RegisterAction<bit<32>, bit<10>, bit<32>>(reg) reg_act_4 = {
        void apply(inout bit<32> reg_data) {
            reg_data = 4;
        }
    };

    RegisterAction<bit<32>, bit<10>, bit<32>>(reg) reg_act_5 = {
        void apply(inout bit<32> reg_data) {
            reg_data = 5;
        }
    };

    action action1() {
        reg_act_1.execute(hdr.data.f1[9:0]);
    }

    action action2() {
        reg_act_2.execute(hdr.data.f1[9:0]);
    }

    action action3() {
        reg_act_3.execute(hdr.data.f1[9:0]);
    }

    action action4() {
        reg_act_4.execute(hdr.data.f1[9:0]);
    }

    action action5() {
        reg_act_5.execute(hdr.data.f1[9:0]);
    }

    table test_table {
        key = {
            hdr.data.h1 : exact;
        }
        actions = {
            action1;
            action2;
            action3;
            action4;
            action5;
        }
    }

    apply {
        test_table.apply();
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

#include "common_tna_test.h"