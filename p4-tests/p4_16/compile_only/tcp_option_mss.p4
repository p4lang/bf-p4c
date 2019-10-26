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
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

struct headers {
}

struct metadata {
    bit<32> seq_no;
    bit<32> ack_no;
    bit<16> ss;
    bit<8> ws;
    bit<8> sack_permitted;
    bit<32> ts1;
    bit<32> ts2;
}


// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser ParserI(
        packet_in pkt,
        out headers hdr,
        out metadata meta,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    ParserCounter<>() pctr;

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition next_option;
    }

    state parse_tcp_option_end {
        pkt.advance(8);

        pctr.decrement(1);
        transition accept;
    }

    state parse_tcp_option_nop {
        pkt.advance(8);

        pctr.decrement(1);
        transition next_option;
    }

    state parse_tcp_option_mss {
        pkt.advance(16);
        meta.ss = pkt.lookahead<bit<16>>();
        pkt.advance(16);

        pctr.decrement(4);
        transition next_option;
    }

    state parse_tcp_option_sack_permitted { 
        pkt.advance(16);
        meta.sack_permitted = 0x40;

        pctr.decrement(2);
        transition next_option;
    }

    state parse_tcp_option_tlv_2 {
        pkt.advance(16);
        pctr.decrement(2);
        transition next_option;
    }

    state parse_tcp_option_tlv_3 {
        pkt.advance(24);
        pctr.decrement(3);
        transition next_option;
    }

    state parse_tcp_option_tlv_40 {
        pkt.advance(320);
        pctr.decrement(40);
        transition next_option;
    }

    @dont_unroll
    state next_option {
        transition select(pctr.is_zero(), (pkt.lookahead<bit<16>>())) {
            (true, _): accept;
            (false, 0x0000 &&& 0xff00): parse_tcp_option_end;
            (false, 0x0100 &&& 0xff00): parse_tcp_option_nop; 
            (false, 0x0200 &&& 0xff00): parse_tcp_option_mss; 
            (false, 0x0400 &&& 0xff00): parse_tcp_option_sack_permitted; 
            (false, 0x0002 &&& 0x00ff): parse_tcp_option_tlv_2;
            (false, 0x0003 &&& 0x00ff): parse_tcp_option_tlv_3; 
            (false, 0x0028 &&& 0x00ff): parse_tcp_option_tlv_40; 
            (false, _): accept;
        }
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control DeparserI(
        packet_out pkt,
        inout headers hdr,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
         pkt.emit(hdr);
    }
}

control IngressP(
        inout headers hdr,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    apply { }
}

parser ParserE(packet_in b,
               out headers hdr,
               out metadata meta,
               out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;  // XXX can't have empty parser in P4-16
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
    apply { }
}

Pipeline(ParserI(),
         IngressP(),
         DeparserI(),
         ParserE(),
         EgressP<>(),
         DeparserE()) pipe;

Switch(pipe) main;

