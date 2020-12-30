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
//
// parse_h2 should _not_ be split over two states because:
//  - 5 x 32b extracts
//  - 1 x 16b extract
//  - 1 x 8b vld set
//  - 1 x 16b csum validation

header h1_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
}

header h2_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<32> f5;
    bit<16> csum;
}

@pa_container_size("ingress", "h1.f1", 32)
@pa_container_size("ingress", "h1.f2", 32)
@pa_container_size("ingress", "h1.f3", 32)
@pa_container_size("ingress", "h1.f4", 32)

@pa_container_size("ingress", "h2.f1", 32)
@pa_container_size("ingress", "h2.f2", 32)
@pa_container_size("ingress", "h2.f3", 32)
@pa_container_size("ingress", "h2.f4", 32)
@pa_container_size("ingress", "h2.f5", 32)
@pa_container_size("ingress", "h2.csum", 16)

struct headers {
    h1_t h1;
    h2_t h2;
}

@pa_container_size("ingress", "m1", 32)
@pa_container_size("ingress", "csum_err", 16)
struct metadata {
    bit<32> m1;
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
        md.m1 = 32w0x80;

        check_1.add(hdr.h2);

        md.csum_err = check_1.verify();

        transition accept;
    }
}

control IngressP(
        inout headers hdr,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
        if (meta.csum_err) {
            hdr.h2.f1 = hdr.h2.f5;
        }
        ig_intr_tm_md.ucast_egress_port = 0;
    }
}

control DeparserI(
        packet_out b,
        inout headers hdr,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    Checksum() check;
    apply {
        hdr.h2.csum = check.update({hdr.h2.f1, hdr.h2.f2, hdr.h2.f3, hdr.h2.f4});
        b.emit(hdr);
    }
}

parser ParserE(packet_in packet,
               out headers hdr,
               out metadata meta,
               out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        transition accept;
    }
}

control EgressP(
        inout headers hdr,
        inout metadata meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply { }
}

control DeparserE(packet_out b,
                  inout headers hdr,
                  in metadata meta,
                  in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply { b.emit(hdr); }
}

Pipeline(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe;
Switch(pipe) main;
