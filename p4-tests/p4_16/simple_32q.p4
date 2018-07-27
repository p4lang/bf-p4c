/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2016 Barefoot Networks, Inc.
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
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

#include <core.p4>
#include <tna.p4>
#include "util.h"

#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_IPV6 0x86dd
#define IP_PROTOCOLS_TCP 6
#define IP_PROTOCOLS_UDP 17


struct switch_header_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    ipv6_h ipv6;
}

struct switch_metadata_t { }

parser SwitchEgressParser(
    packet_in pkt,
    out switch_header_t hdr,
    out switch_metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition accept;
    }
}

control SwitchIngressDeparser(packet_out pkt,
                              inout switch_header_t hdr,
                              in switch_metadata_t ig_md,
                              in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply { }
}


control SwitchEgressDeparser(packet_out pkt,
                              inout switch_header_t hdr,
                              in switch_metadata_t eg_md,
                              in egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md) {
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
    }
}

control SwitchIngress(
        inout switch_header_t hdr,
        inout switch_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}


control SwitchEgress(
    inout switch_header_t hdr,
    inout switch_metadata_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    DirectLpf<bit<19>>() dummy_lpf;
    Wred<bit<19>, bit<10>>(1024, 0, 1) indirect_wred;
    bit<1> wred_flag;
    bit<19> avg_queue;

    action set_ipv4_ecn() {
        hdr.ipv4.diffserv[1:0] = 0b11;
    }

    action set_ipv6_ecn() {
        hdr.ipv6.traffic_class[1:0] = 0b11;
    }

    table ecn_marking {
        key = {
            hdr.ipv4.isValid() : ternary;
            hdr.ipv4.diffserv : ternary;
            hdr.ipv6.isValid() : ternary;
            hdr.ipv6.traffic_class : ternary;
        }

        actions = {
            NoAction;
            set_ipv4_ecn;
            set_ipv6_ecn;
        }

        size = 1024;
    }

    action set_wred_flag(bit<10> index) {
        wred_flag = (bit<1>) indirect_wred.execute(eg_intr_md.enq_qdepth, index);
    }

    table wred {
        key = {
           eg_intr_md.egress_port : exact;
           eg_intr_md.egress_qid : exact;
        }

        actions = {
            NoAction;
            set_wred_flag;
        }

        const default_action = NoAction;
        size = 2048;
    }

    action set_avg_queue() {
        avg_queue = dummy_lpf.execute(eg_intr_md.deq_qdepth);
    }

    table queue {
        key = {
            eg_intr_md.egress_port : exact;
        }

        actions = {
            set_avg_queue;
        }

        filters = dummy_lpf;
    }

    apply {
        wred_flag = 0;
        avg_queue = 0;

        queue.apply();
        if (avg_queue == 0) {
            exit;
        }

        wred.apply();
        if (wred_flag == 1)
            ecn_marking.apply();
    }
}

Pipeline(TofinoIngressParser<switch_header_t, switch_metadata_t>(),
       SwitchIngress(),
       SwitchIngressDeparser(),
       SwitchEgressParser(),
       SwitchEgress(),
       SwitchEgressDeparser()) pipe0;

Pipeline(TofinoIngressParser<switch_header_t, switch_metadata_t>(),
       SwitchIngress(),
       SwitchIngressDeparser(),
       SwitchEgressParser(),
       SwitchEgress(),
       SwitchEgressDeparser()) pipe1;

Switch(pipe0, pipe1) main;
