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
 * Soumyadeep Ghosh (dghosh@barefootnetworks.com)
 *
 * This test checks if the can_pack() method in ActionPhvConstraints correctly inteprets the case of
 * metadata fields being overlayed vs metadata fields being packed together. Two metadata fields
 * meta.m1 and meta.m2 are overlayable because of disjoint live ranges. However, in this case,
 * because of the allocation of their respective cluster fields (data.f1 and data.f2) to a 32-bit
 * container, one of the checks performed will be whether meta.m1 and meta.m2 must be packed in the
 * same container.
 *
 * The right answer to this can_pack() question is that they cannot be packed together because of
 * the XOR operation in action set5, which would overwrite the entire container. This right answer
 * is only produced by can_pack() if AllocatePHV recognizes that the metadata fields in this case
 * are being packed together, despite being overlayable due to disjoint live ranges.
 *
 **************************************************************************************************/

#include <tna.p4>

header data_h {
    bit<16>      f1;
    bit<16>      f2;
}

struct metadata {
    bit<16>      m1;
    bit<16>      m2;
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
    action set1(PortId_t port, bit<16> val) {
        meta.m1 = val;
        ig_intr_tm_md.ucast_egress_port = port;
    }

    action set2(PortId_t port) {
        hdrs.data.f2 = meta.m1;
        ig_intr_tm_md.ucast_egress_port = port;
    }

    action set3(PortId_t port) {
        hdrs.data.f1 = hdrs.data.f2;
        ig_intr_tm_md.ucast_egress_port = port;
    }

    action set4(PortId_t port) {
        hdrs.data.f2 = hdrs.data.f1;
        ig_intr_tm_md.ucast_egress_port = port;
    }

    action set5(PortId_t port, bit<16> val) {
        meta.m2 = hdrs.data.f1 ^ val;
        ig_intr_tm_md.ucast_egress_port = port;
    }

    action set6(PortId_t port) {
        hdrs.data.f1 = meta.m2;
        ig_intr_tm_md.ucast_egress_port = port;
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
    }

    table test5 {
        key = {
            hdrs.data.f1 : exact;
        }
        actions = {
            set5;
        }
        default_action = set5(3, 0x1234);
    }

    table test6 {
        key = {
            hdrs.data.f2 : exact;
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
