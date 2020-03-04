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
 ******************************************************************************/

#include <core.p4>
#include <tna.p4>

#define ETHERTYPE_IPV4 0x0800
#define IP_PROTOCOLS_TCP 6
#define IP_PROTOCOLS_UDP 17

typedef bit<48> mac_addr_t;
typedef bit<16> switch_nexthop_t;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

/*
 * bridged metadata.
 */
struct switch_metadata_t {
    bit<16> port;   // all nicely byte-sized.
    bit<8> check;
    bit<1> routed;
    bit<3> cos;
    bit<1> f0;
    bit<1> f1;
    bit<1> f2;
    bit<1> f3;
}

struct switch_header_t {
    ethernet_h ethernet;
}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(packet_in pkt, out switch_header_t hdr, out switch_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        ig_md.routed = 1w1;
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        ig_md.f0 = 1w1;
        ig_md.f1 = 1w1;
        ig_md.f2 = 1w1;
        ig_md.f3 = 1w1;

        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : accept;
            default : accept;
        }
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(packet_out pkt, inout switch_header_t hdr, in switch_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        pkt.emit(hdr.ethernet);
    }
}

control SwitchIngress(inout switch_header_t hdr, inout switch_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action act(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }
    table test {
        actions = { act; NoAction; }
        key = { hdr.ethernet.dst_addr: exact; }
        default_action = NoAction;
    }
    table test3 {
        actions = { act; NoAction; }
        key = { hdr.ethernet.dst_addr: exact; }
        default_action = NoAction;
    }
    table test4 {
        actions = { act; NoAction; }
        key = { hdr.ethernet.dst_addr: exact; }
        default_action = NoAction;
    }
    table test5 {
        actions = { act; NoAction; }
        key = { hdr.ethernet.dst_addr: exact; }
        default_action = NoAction;
    }
    table test6 {
        actions = { act; NoAction; }
        key = { hdr.ethernet.dst_addr: exact; }
        default_action = NoAction;
    }

    apply {
        if (ig_md.routed == 1) {
            test.apply();
        }
        // We can do better here by inferring test4 test5 test6 will never be applied
        if (ig_md.f0 == 1) {
            test3.apply();
        } else if (ig_md.f1 == 1) {
            test4.apply();
        } else if (ig_md.f2 == 1) {
            test5.apply();
        } else if (ig_md.f3 == 1) {
            test6.apply();
        }
    }
}

parser SwitchEgressParser(packet_in pkt, out switch_header_t hdr, out switch_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

control SwitchEgress(inout switch_header_t hdr, inout switch_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

control SwitchEgressDeparser(packet_out pkt, inout switch_header_t hdr, in switch_metadata_t meta, in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {
        pkt.emit(hdr.ethernet);
    }
}

Pipeline(SwitchIngressParser(), SwitchIngress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) pipe0;

Switch(pipe0) main;
