/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2018-2019 Barefoot Networks, Inc.
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
 ******************************************************************************/
#include <core.p4>
#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#elif __TARGET_TOFINO__ == 1
#include <tna.p4>
#else
#error Unsupported target
#endif

header option_a_t {
    bit<8> value;
}

header option_b_t {
    bit<16> value;
}

header option_c_t {
    bit<32> value;
}

struct metadata {
}

struct headers {
    option_a_t[4]  option_a;
    option_b_t[4]  option_b;
    option_c_t[4]  option_c;
}

parser ParserI(packet_in packet,
                         out headers hdr,
                         out metadata meta,
                         out ingress_intrinsic_metadata_t ig_intr_md) {
    ParserCounter() pctr;

    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        pctr.set(8w4);
        transition parse_options;
    }

    @dont_unroll
    state parse_options {
        transition select(pctr.is_zero(), (packet.lookahead<bit<8>>())[7:0]) {
            (true, _): accept;
            (false, 0xa): parse_option_a;
            (false, 0xb): parse_option_b;
            (false, 0xc): parse_option_c;
        }
    }

    state parse_option_a {
        packet.extract(hdr.option_a.next);
        pctr.decrement(1);
        transition parse_options;
    }

    state parse_option_b {
        packet.extract(hdr.option_b.next);
        pctr.decrement(1);
        transition parse_options;
    }

    state parse_option_c {
        packet.extract(hdr.option_c.next);
        pctr.decrement(1);
        transition parse_options;
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

control IngressP(
        inout headers hdr,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
            ig_intr_tm_md.ucast_egress_port = 2;
    }
}

control DeparserI(packet_out packet,
                  inout headers hdr,
                  in metadata meta,
                  in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        packet.emit(hdr);
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

control DeparserE(packet_out packet,
                           inout headers hdr,
                           in metadata meta,
                           in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply { }
}

Pipeline(ParserI(),
         IngressP(),
         DeparserI(),
         ParserE(),
         EgressP(),
         DeparserE()) pipe;

Switch(pipe) main;
