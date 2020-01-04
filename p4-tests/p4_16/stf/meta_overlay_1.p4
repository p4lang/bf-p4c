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
 * This test is designed to test the interaction of the deparsed-zero optimization and metadata
 * initialization required by live range shrinking-based overlay.
 *
 * The field m2 is designed to be overlaid due to disjoint live ranges with the header field
 * data2.f2, which is a deparsed-zero candidate. Therefore, four byte-sized slices of data2.f2 and
 * m2 will be be allocated to the same container, B0. If the initialization is correctly inserted
 * (only one initialization instruction corresponding to one byte-sized slice of data2.f2 is
 * inserted in actions of table test6), then compilation will succeed. Further, correct
 * initialization of the deparsed-zero fields will ensure that the packet output is correct.
 *
 **************************************************************************************************/

#if __TARGET_TOFINO__ >= 2
#include "t2na.p4"
#else
#include <tna.p4>
#endif

header data_h {
    bit<16>      f1;
    bit<16>      f2;
}

header data_w {
    bit<32>      f1;
    bit<32>      f2;
    bit<8>       f3;
}

struct metadata {
    bit<16>      m1;
    bit<8>       m2;
    bit<8>       m3;
}

struct packet_t {
    data_h      data1;
    data_w      data2;
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
        b.extract(hdrs.data1);
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
    action set1(bit<9> port, bit<16> val) {
        meta.m1 = val;
        meta.m2 = 4;
        ig_intr_tm_md.ucast_egress_port = port;
    }

    action set2(bit<9> port) {
        meta.m3 = meta.m2;
        hdrs.data1.f1 = meta.m1;
        ig_intr_tm_md.ucast_egress_port = port;
    }

    action set3(bit<9> port, bit<16> val) {
        hdrs.data1.f2 = val;
        ig_intr_tm_md.ucast_egress_port = port;
    }

    action set4(bit<9> port, bit<16> val) {
        hdrs.data1.f1 = val;
        ig_intr_tm_md.ucast_egress_port = port;
    }

    action set5(bit<9> port, bit<16> val) {
        hdrs.data1.f2 = val;
        ig_intr_tm_md.ucast_egress_port = port;
    }

    action set6(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
        hdrs.data2.setValid();
        hdrs.data2.f1 = 0x1234;
        hdrs.data2.f2 = 0;
        hdrs.data2.f3 = meta.m3;
    }

    table test1 {
        key = {
            hdrs.data1.f1 : exact;
        }
        actions = {
            set1;
        }
    }

    table test2 {
        key = {
            hdrs.data1.f2 : exact;
        }
        actions = {
            set2;
        }
    }

    table test3 {
        key = {
            hdrs.data1.f1 : exact;
        }
        actions = {
            set3;
        }
    }

    table test4 {
        key = {
            hdrs.data1.f2 : exact;
        }
        actions = {
            set4;
        }
    }

    table test5 {
        key = {
            hdrs.data1.f1 : exact;
        }
        actions = {
            set5;
        }
        default_action = set5(3, 0x1234);
    }

    table test6 {
        key = {
            hdrs.data1.f2 : exact;
        }
        actions = {
            set6;
        }
    }

    apply {
        meta.m1 = 1;
        test1.apply();
        test2.apply();
        test3.apply();
        test4.apply();
        test5.apply();
        test6.apply();
    }
}

control deparserI(
        packet_out b,
        inout packet_t hdrs,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        b.emit(hdrs.data1);
        b.emit(hdrs.data2);
    }
}

parser parserE(
        packet_in b,
        out packet_t hdrs,
        out metadata meta,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract(eg_intr_md);
        b.extract(hdrs.data1);
        b.extract(hdrs.data2);
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
        b.emit(hdrs.data1);
        b.emit(hdrs.data2);
    }
}

Pipeline(parserI(), ingress(), deparserI(), parserE(), egress(), deparserE()) pipe0;
Switch(pipe0) main;
