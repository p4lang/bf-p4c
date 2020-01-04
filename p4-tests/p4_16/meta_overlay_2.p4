/***************************************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 *
 * Soumyadeep Ghosh
 *
 * This test is designed to test the initialization at strict dominators, when all strict dominators
 * write to the initialized field in some of their actions (but not all actions).
 *
 *
 **************************************************************************************************/

#if __TARGET_TOFINO__ >= 2
#include "t2na.p4"
#else
#include <tna.p4>
#endif

header data_h {
    bit<8>      f1;
    bit<8>      f2;
}

struct metadata {
    bit<8>      m1;
    bit<8>      m2;
}

struct packet_t {
    data_h      data;
}

parser parserI(
        packet_in b,
        out packet_t hdrs,
        out metadata meta,
        out ingress_intrinsic_metadata_t ig_intr_md)
{
    state start {
#if __TARGET_TOFINO__ >= 2
        b.advance(256);
#else
        b.advance(128);
#endif
        b.extract(hdrs.data);
        transition accept;
    }
}

control ingress(
        inout packet_t hdrs, 
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action set1(bit<9> port, bit<8> val) {
        meta.m1 = val;
        ig_intr_tm_md.ucast_egress_port = port;
    }

    action set2() {
        hdrs.data.f1 = meta.m1;
    }

    action set3(bit<8> val) {
        hdrs.data.f2 = val;
    }

    action set4(bit<8> val) {
        hdrs.data.f1 = val + hdrs.data.f1;
    }

    action set5_1(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
        hdrs.data.f1 = meta.m2;
    }

    action set5_2(bit<8> val) {
        meta.m2 = val;
    }

    action set6_1(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
        hdrs.data.f1 = meta.m2;
    }

    action set6_2(bit<8> val) {
        meta.m2 = 3;
    }

    action set7() {
        hdrs.data.f2 = meta.m2;
    }

    table test1 {
        key = {
            hdrs.data.f1 : exact;
        }
        actions = {
            set1;
        }
    }

    table test2 {
        key = {
            hdrs.data.f2 : exact;
        }
        actions = {
            set2;
        }
    }

    table test3 {
        key = {
            hdrs.data.f1 : exact;
        }
        actions = {
            set3;
        }
    }

    table test4 {
        key = {
            hdrs.data.f2 : exact;
        }
        actions = {
            set4;
        }
        default_action = set4(0x1);
    }

    table test5 {
        key = {
            hdrs.data.f1 : exact;
        }
        actions = {
            set5_1;
            set5_2;
        }
        default_action = set5_1(6);
    }

    table test6 {
        key = {
            hdrs.data.f2 : exact;
        }
        actions = {
            set6_1;
            set6_2;
        }
        default_action = set6_1(7);
    }

    table test7 {
        key = {
            meta.m2 : exact;
        }
        actions = {
            set7;
        }
        default_action = set7();
    }

    apply {
        test1.apply();
        test2.apply();
        test3.apply();
        test4.apply();
        if (hdrs.data.f1 == 0x09)
            test5.apply();
        else
            test6.apply();
        test7.apply();
    }
}

control deparserI(
        packet_out b,
        inout packet_t hdrs,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        b.emit(hdrs.data);
    }
}

parser parserE(
        packet_in b,
        out packet_t hdrs,
        out metadata meta,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract(eg_intr_md);
        b.extract(hdrs.data);
        transition accept;
    }
}

control egress(
        inout packet_t hdrs, 
        inout metadata meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply { }
}

control deparserE(
        packet_out b,
        inout packet_t hdrs,
        in metadata meta,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md) {
    apply {
        b.emit(hdrs.data);
    }
}

Pipeline(parserI(), ingress(), deparserI(), parserE(), egress(), deparserE()) pipe0;
Switch(pipe0) main;
