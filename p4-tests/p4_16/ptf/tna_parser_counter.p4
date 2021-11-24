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
#if __TARGET_TOFINO__ == 1
#include <tofino1_specs.p4>
#include <tofino1_arch.p4>
#elif __TARGET_TOFINO__ == 2
#include <tofino2_specs.p4>
#include <tofino2_arch.p4>
#else
#include <tofino3_specs.p4>
#include <tofino3_arch.p4>
#endif

header ipv6_srh_segment_t {
    bit<128> sid;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header ipv4_option_EOL_t {
    bit<8> value;
}

header ipv4_option_NOP_t {
    bit<8> value;
}

header ipv4_option_addr_ext_t {
    bit<8>  value;
    bit<8>  len;
    bit<32> src_ext;
    bit<32> dst_ext;
}

header ipv6_t {
    bit<4>   version;
    bit<8>   trafficClass;
    bit<20>  flowLabel;
    bit<16>  payloadLen;
    bit<8>   nextHdr;
    bit<8>   hopLimit;
    bit<128> srcAddr;
    bit<128> dstAddr;
}

header ipv6_srh_t {
    bit<8>  nextHdr;
    bit<8>  hdrExtLen;
    bit<8>  routingType;
    bit<8>  segLeft;
    bit<8>  firstSeg;
    bit<16> flags;
    bit<8>  reserved;
}

struct metadata {
}

struct headers {
    ipv6_srh_segment_t     active_segment;
    ethernet_t             ethernet;
    ipv4_t                 ipv4;
    ipv4_option_EOL_t      ipv4_option_EOL;
    ipv4_option_NOP_t      ipv4_option_NOP;
    ipv4_option_addr_ext_t ipv4_option_addr_ext;
    ipv6_t                 ipv6;
    ipv6_srh_t             ipv6_srh;
    ipv6_srh_segment_t[9]  ipv6_srh_seg_list;
}

parser ParserI(packet_in packet,
                         out headers hdr,
                         out metadata meta,
                         out ingress_intrinsic_metadata_t ig_intr_md) {
    ParserCounter() pctr;

    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);

#if __TARGET_TOFINO__ >= 2
        pctr.set(hdr.ipv4.ihl, 8w255, 8w6, 8w60, 8w20);
#elif __TARGET_TOFINO__ == 1
        pctr.set(hdr.ipv4.ihl, 8w255, 8w6, 3w5, 8w21);
#endif
        transition select(hdr.ipv4.ihl) {
            4w0x5: accept;
            default: parse_ipv4_options;
        }
    }

    state parse_ipv4_option_addr_ext {
        packet.extract(hdr.ipv4_option_addr_ext);
        pctr.decrement(10);
        transition parse_ipv4_options;
    }

    state parse_ipv4_option_eol {
        packet.extract(hdr.ipv4_option_EOL);
        pctr.decrement(1);
        transition parse_ipv4_options;
    }

    state parse_ipv4_option_nop {
        packet.extract(hdr.ipv4_option_NOP);
        pctr.decrement(1);
        transition parse_ipv4_options;
    }

    state parse_ipv4_options {
        transition select((bit<1>)pctr.is_zero(), (packet.lookahead<bit<8>>())[7:0]) {
            (1w1 &&& 1w1, 8w0x0 &&& 8w0x0): accept;
            (1w1 &&& 1w0, 8w0x0 &&& 8w0xff): parse_ipv4_option_eol;
            (1w1 &&& 1w0, 8w0x1 &&& 8w0xff): parse_ipv4_option_nop;
            (1w1 &&& 1w0, 8w0x93 &&& 8w0xff): parse_ipv4_option_addr_ext;
        }
    }

    state parse_ipv6 {
        packet.extract(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            8w43: parse_ipv6_srh;
        }
    }

    state parse_ipv6_srh {
        packet.extract(hdr.ipv6_srh);
        pctr.set(hdr.ipv6_srh.segLeft);
        transition parse_ipv6_srh_seg_list;
    }

    state parse_ipv6_srh_active_segment {
        packet.extract(hdr.active_segment);
        transition accept;
    }

    state parse_ipv6_srh_seg_list {
        transition select(pctr.is_zero()) {
            true: parse_ipv6_srh_active_segment;
            default: parse_ipv6_srh_segment;
        }
    }

    state parse_ipv6_srh_segment {
        packet.extract(hdr.ipv6_srh_seg_list.next);
        pctr.decrement(1);
        transition parse_ipv6_srh_seg_list;
    }
}

parser ParserE(packet_in packet,
                        out headers hdr,
                        out metadata meta,
                        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
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
    action NoAction_0() { }

    action set_egress_port(PortId_t egress_port) {
        ig_intr_tm_md.ucast_egress_port = egress_port;
    }

    action rewrite_ipv6_and_set_egress_port(PortId_t egress_port) {
        hdr.ipv6.dstAddr = hdr.active_segment.sid;
        ig_intr_tm_md.ucast_egress_port = egress_port;
    }

    table ipv4_option_lookup_0 {
        actions = {
            set_egress_port();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.ipv4_option_NOP.isValid()     : exact;
            hdr.ipv4_option_EOL.isValid()     : exact;
            hdr.ipv4_option_addr_ext.isValid(): exact;
        }
        default_action = NoAction_0();
    }

    table sr_lookup_0 {
        actions = {
            rewrite_ipv6_and_set_egress_port();
            @defaultonly NoAction_0();
        }
        default_action = NoAction_0();
    }

    apply {
        if (hdr.ipv6_srh.isValid()) {
            sr_lookup_0.apply();
        }
        if (hdr.ipv4.isValid()) {
            ipv4_option_lookup_0.apply();
        }
    }
}

control DeparserI(packet_out packet,
                  inout headers hdr,
                  in metadata meta,
                  in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv6);
        packet.emit(hdr.ipv6_srh);
        packet.emit(hdr.ipv6_srh_seg_list);
        packet.emit(hdr.active_segment);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.ipv4_option_EOL);
        packet.emit(hdr.ipv4_option_NOP);
        packet.emit(hdr.ipv4_option_addr_ext);
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
