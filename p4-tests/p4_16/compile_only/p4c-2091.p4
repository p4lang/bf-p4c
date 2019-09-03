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
 **************************************************************************************************/

#if __TARGET_TOFINO__ == 2
#include "t2na.p4"
#else
#include <tna.p4>
#endif

header data_h {
    bit<3> a1;
    bit<3> a2;
    bit<2> a3;
}

struct metadata { bit<3> meta1; }

struct packet_t {
    data_h      data1;
    data_h      data2;
}

parser parserI(
        packet_in b,
        out packet_t hdrs,
        out metadata meta,
        out ingress_intrinsic_metadata_t ig_intr_md)
{
    state start {
#if __TARGET_TOFINO__ == 2
        b.advance(256);
#else
        b.advance(128);
#endif
        b.extract(hdrs.data1);
        b.extract(hdrs.data2);
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
    action set1(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
        hdrs.data1.a1 = hdrs.data2.a1;
        hdrs.data1.a2 = hdrs.data2.a1;
    }

    table test1 {
        key = {
            hdrs.data1.a3 : exact;
        }
        actions = {
            set1;
        }
    }

    apply {
        test1.apply();
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
