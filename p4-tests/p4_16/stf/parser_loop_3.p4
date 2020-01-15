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

header len_t {
    bit<8> value;
}

header segment_t {
    bit<8> sid;
}

struct metadata {
}

struct headers {
    len_t len;
    segment_t[10]  seg_list;
}

parser ParserI(packet_in packet,
                         out headers hdr,
                         out metadata meta,
                         out ingress_intrinsic_metadata_t ig_intr_md) {
    ParserCounter() pctr;

    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);

        packet.extract(hdr.len);
        pctr.set(hdr.len.value);

        transition parse_seg_list;
    }

    @dont_unroll
    state parse_seg_list {
        transition select(pctr.is_zero()) {
            true: accept;
            false: parse_seg_list_part2;
        }
    }

    state parse_seg_list_part2 {
        transition select(packet.lookahead<bit<8>>()) {
            0x1: parse_one_seg;
            0x2: parse_two_segs;
            0x3: parse_three_segs;
        }
    }

    state parse_one_seg {
        packet.extract(hdr.seg_list.next);
        pctr.decrement(1);
        transition parse_seg_list;
    }

    state parse_two_segs {
        packet.extract(hdr.seg_list.next);
        packet.extract(hdr.seg_list.next);
        pctr.decrement(2);
        transition parse_seg_list;
    }

    state parse_three_segs {
        packet.extract(hdr.seg_list.next);
        packet.extract(hdr.seg_list.next);
        packet.extract(hdr.seg_list.next);
        pctr.decrement(3);
        transition parse_seg_list;
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
