/*******************************************************************************
 * INTEL CORPORATION CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2020 Intel Corporation
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

// Summary:
//  - 2 headers
//  - 32b fields

// parse_h2 should *NOT* be split over two states because:
//  - 3 x 16b extract
//  - 1 x 16b csum validation
//  - 1 x 8b vld set
//  - 1 x 16b constant gen

header h1_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
}

header h2_t {
    bit<16> f1;
    bit<16> f2;
    bit<16> csum;
}

@pa_container_size("ingress", "h1.f1", 32)
@pa_container_size("ingress", "h1.f2", 32)
@pa_container_size("ingress", "h1.f3", 32)
@pa_container_size("ingress", "h1.f4", 32)

@pa_container_size("ingress", "h2.f1", 16)
@pa_container_size("ingress", "h2.f2", 16)
@pa_container_size("ingress", "h2.csum", 16)

struct headers {
    h1_t h1;
    h2_t h2;
}

@pa_container_size("ingress", "m1", 16)
@pa_container_size("ingress", "csum_err", 16)
struct metadata {
    bit<16> m1;
    bool    csum_err;
}


parser ParserI(packet_in packet,
               out headers hdr,
               out metadata md,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() check_1;

    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr.h1);

        transition select(hdr.h1.f1) {
            32w0xaaaaaaaa: parse_h2;
            default: accept;
        }
    }

    state parse_h2 {
        packet.extract(hdr.h2);
        md.m1 = 16w0x80;

        check_1.add(hdr.h2);

        md.csum_err = check_1.verify();

        transition accept;
    }
}

control DeparserI(
        packet_out b,
        inout headers hdr,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    Checksum() check;
    apply {
        hdr.h2.csum = check.update({hdr.h2.f1, hdr.h2.f2});
        b.emit(hdr);
    }
}

#include "include/narrow_to_wide_w_csum_common.p4"

Switch(pipe) main;
