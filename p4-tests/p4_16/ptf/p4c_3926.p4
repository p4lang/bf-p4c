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

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ether_type;
}

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
@pa_container_size("ingress", "h2.csum", 16)

@pa_container_size("ingress", "h3.f1", 32)
@pa_container_size("ingress", "h3.f2", 32)
@pa_container_size("ingress", "h3.f3", 32)
@pa_container_size("ingress", "h3.f4", 32)

struct headers {
    ethernet_t eth;
    h1_t h1;
    h2_t h2;
    h1_t h3;
}

@pa_container_size("ingress", "m1", 32)
@pa_container_size("ingress", "csum_err", 16)
struct metadata {
    bit<32> m1;
    bool    csum_err;
}

struct pvs_data {
    bit<16> f;
}

parser ParserI(packet_in packet,
               out headers hdr,
               out metadata md,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() check_1;
    value_set<pvs_data>(4) pvs;

    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        transition parse_eth;
    }

    state parse_eth {
        packet.extract(hdr.eth);
        transition select(hdr.eth.ether_type) {
            pvs     : parse_h1;
            default : accept;
        }
    }

    state parse_h1 {
        packet.extract(hdr.h1);
        transition select(hdr.h1.f1) {
            32w0xaaaaaaaa: parse_h2;
            default: accept;
        }
    }

    state parse_h2 {
        packet.extract(hdr.h2);
        md.m1 = 32w0x80;

        packet.extract(hdr.h3);
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
        //hdr.h2.csum = check.update({hdr.h2.f1, hdr.h2.f2, hdr.h2.f3, hdr.h2.f4});
        b.emit(hdr);
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
            hdr.h2.f1 = meta.m1;
        }
        if (!hdr.h1.isValid()) {
            ig_intr_dprs_md.drop_ctl = 0x1;
        }
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
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
