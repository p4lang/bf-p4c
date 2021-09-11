/*******************************************************************************
 * INTEL CORPORATION CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2021 Intel Corporation
 * All Rights Reserved.
 *
 * This software and the related documents are Intel copyrighted materials,
 * and your use of them is governed by the express license under which they
 * were provided to you ("License"). Unless the License provides otherwise,
 * you may not use, modify, copy, publish, distribute, disclose or transmit this
 * software or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express or
 * implied warranties, other than those that are expressly stated in the License.
 *
 ******************************************************************************/

#include <core.p4>
#include <tna.p4> /* TOFINO1_ONLY */

// Narrow-to-wide extraction test
//
// Summary:
//  - 16b -> 32b narrow-to-wide extract
//  - 2 states before the narrow-to-wide extract
//  - 7 states after the narrow to wide extract, including 1 dummy

header h1_t {
    bit<8>  b1;
    bit<16> h1;
    bit<32> w1;
}

header h2_t {
    bit<8>  b1;
    bit<16> h1;
    bit<32> w1;
    bit<32> w2;
    bit<32> w3;
    bit<32> w4;
}

@pa_container_size("ingress", "h1.b1", 8)
@pa_container_size("ingress", "h1.h1", 16)
@pa_container_size("ingress", "h1.w1", 32)

@pa_container_size("ingress", "h2.b1", 8)
@pa_container_size("ingress", "h2.h1", 16)
@pa_container_size("ingress", "h2.w1", 32)

@pa_container_size("ingress", "h3.b1", 8)
@pa_container_size("ingress", "h3.h1", 16)
@pa_container_size("ingress", "h3.w1", 32)
@pa_container_size("ingress", "h3.w2", 32)
@pa_container_size("ingress", "h3.w3", 32)
@pa_container_size("ingress", "h3.w4", 32)

@pa_container_size("ingress", "h4.b1", 8)
@pa_container_size("ingress", "h4.h1", 16)
@pa_container_size("ingress", "h4.w1", 32)

@pa_container_size("ingress", "h5.b1", 8)
@pa_container_size("ingress", "h5.h1", 16)
@pa_container_size("ingress", "h5.w1", 32)

@pa_container_size("ingress", "h6.b1", 8)
@pa_container_size("ingress", "h6.h1", 16)
@pa_container_size("ingress", "h6.w1", 32)

@pa_container_size("ingress", "h7.b1", 8)
@pa_container_size("ingress", "h7.h1", 16)
@pa_container_size("ingress", "h7.w1", 32)

@pa_container_size("ingress", "h8.b1", 8)
@pa_container_size("ingress", "h8.h1", 16)
@pa_container_size("ingress", "h8.w1", 32)

@pa_container_size("ingress", "h9.b1", 8)
@pa_container_size("ingress", "h9.h1", 16)
@pa_container_size("ingress", "h9.w1", 32)

@pa_container_size("ingress", "hdr.h3.$valid", 32)

struct headers {
    h1_t h1;
    h1_t h2;
    h2_t h3;
    h1_t h4;
    h1_t h5;
    h1_t h6;
    h1_t h7;
    h1_t h8;
    h1_t h9;
}

struct metadata {
}


parser ParserImpl(packet_in packet,
               out headers hdr,
               out metadata md,
               out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);

        transition parse_h1;
    }

    state parse_h1 {
        packet.extract(hdr.h1);

        transition select(hdr.h1.b1) {
            0x01 &&& 0x01 : parse_h2;
            default: accept;
        }
    }

    state parse_h2 {
        packet.extract(hdr.h2);

        transition select(hdr.h2.b1) {
            0x01 &&& 0x01 : parse_h3;
            default: accept;
        }
    }

    state parse_h3 {
        packet.extract(hdr.h3);

        transition select(hdr.h3.h1) {
            0x01 &&& 0x01 : parse_h4;
            default: accept;
        }
    }


    state parse_h4 {
        packet.extract(hdr.h4);

        transition select(hdr.h4.b1) {
            0x01 &&& 0x01 : parse_h5_pre;
            default: accept;
        }
    }

    @dontmerge ("ingress")
    state parse_h5_pre {
        transition parse_h5;
    }

    state parse_h5 {
        packet.extract(hdr.h5);

        transition select(hdr.h5.b1) {
            0x01 &&& 0x01 : parse_h6;
            default: accept;
        }
    }

    state parse_h6 {
        packet.extract(hdr.h6);

        transition select(hdr.h6.b1) {
            0x01 &&& 0x01 : parse_h7;
            default: accept;
        }
    }

    state parse_h7 {
        packet.extract(hdr.h7);

        transition select(hdr.h7.b1) {
            0x01 &&& 0x01 : parse_h8;
            default: accept;
        }
    }

    state parse_h8 {
        packet.extract(hdr.h8);

        transition select(hdr.h8.b1) {
            0x01 &&& 0x01 : parse_h9;
            default: accept;
        }
    }

    state parse_h9 {
        packet.extract(hdr.h9);

        transition accept;
    }
}

control ingress(
        inout headers hdr,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
        if (hdr.h1.b1 == 0xff) {
            hdr.h1.w1[31:16] = hdr.h1.w1[15:0];
        }
        if (hdr.h2.b1 == 0xff) {
            hdr.h2.w1[31:16] = hdr.h2.w1[15:0];
        }
        if (hdr.h3.h1 == 0xffff) {
            hdr.h3.w1[31:16] = hdr.h3.w1[15:0];
            hdr.h3.w2[31:16] = hdr.h3.w2[15:0];
            hdr.h3.w3[31:16] = hdr.h3.w3[15:0];
            hdr.h3.w4[31:16] = hdr.h3.w4[15:0];
        }
        if (hdr.h4.b1 == 0xff) {
            hdr.h4.w1[31:16] = hdr.h4.w1[15:0];
        }
        if (hdr.h5.b1 == 0xff) {
            hdr.h5.w1[31:16] = hdr.h5.w1[15:0];
        }
        if (hdr.h6.b1 == 0xff) {
            hdr.h6.w1[31:16] = hdr.h6.w1[15:0];
        }
        if (hdr.h7.b1 == 0xff) {
            hdr.h7.w1[31:16] = hdr.h7.w1[15:0];
        }
        if (hdr.h8.b1 == 0xff) {
            hdr.h8.w1[31:16] = hdr.h8.w1[15:0];
        }
        if (hdr.h9.b1 == 0xff) {
            hdr.h9.w1[31:16] = hdr.h9.w1[15:0];
        }
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

#include "common_tna_test.h"
