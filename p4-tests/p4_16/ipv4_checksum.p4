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
 * $Id: $
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

#include <core.p4>
#include <tofino.p4>

#define ETHERTYPE_IPV4 0x0800
#define IP_PROTOCOLS_TCP 6
#define IP_PROTOCOLS_UDP 17

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<16> switch_nexthop_t;


header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> hdr_lenght;
    bit<16> checksum;
}

struct switch_header_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    tcp_h tcp;
    udp_h udp;
}

struct switch_metadata_t {

}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }

    state parse_port_metadata {
        // Skip port metadata.
        pkt.advance(64);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            default : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition accept;
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Egress parser
// ---------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(packet_out pkt,
                              inout switch_header_t hdr,
                              in switch_metadata_t ig_md) {
    checksum<bit<16>>(HashAlgorithm_t.CRC16) ipv4_checksum;

    apply {
        ipv4_checksum.update({hdr.ipv4.version,
                              hdr.ipv4.ihl,
                              hdr.ipv4.diffserv,
                              hdr.ipv4.total_len,
                              hdr.ipv4.identification,
                              hdr.ipv4.flags,
                              hdr.ipv4.frag_offset,
                              hdr.ipv4.ttl,
                              hdr.ipv4.protocol,
                              hdr.ipv4.src_addr,
                              hdr.ipv4.dst_addr}, hdr.ipv4.hdr_checksum);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
    }
}

// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------
control SwitchEgressDeparser(packet_out pkt,
                             inout switch_header_t hdr,
                             in switch_metadata_t eg_md) {
    apply {}
}


control SwitchIngress(
        inout switch_header_t hdr,
        inout switch_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    switch_nexthop_t nexthop_index;

    action miss_() {}

    action set_nexthop(switch_nexthop_t index) {
        nexthop_index = index;
    }

    action set_nexthop_info(mac_addr_t dmac) {
        hdr.ethernet.dst_addr = dmac;
    }

    action set_port(PortId_t port) {
        ig_intr_md_for_tm.ucast_egress_port = port;
        ig_intr_md_for_tm.bypass_egress = 1; // bypass egress pipeline.
    }

    action rewrite_(mac_addr_t smac) {
        hdr.ipv4.ttl =  hdr.ipv4.ttl - 1;
        hdr.ethernet.src_addr = smac;
    }

    table fib {
        key = { hdr.ipv4.dst_addr : exact; }
        actions = {
            miss_;
            set_nexthop;
        }

        const default_action = miss_;
    }

    table nexthop {
        key = { nexthop_index : exact; }
        actions = { set_nexthop_info; }
    }


    table dmac {
        key = { hdr.ethernet.dst_addr : exact; }
        actions = {
            set_port;
            miss_;
        }

        const default_action = miss_;
    }

    table rewrite {
        key = { ig_intr_md_for_tm.ucast_egress_port : exact; }
        actions = { rewrite_; }
    }

    apply {
        nexthop_index = 0;

        fib.apply();
        nexthop.apply();
        dmac.apply();
        rewrite.apply();
    }
}


control SwitchEgress(
        inout switch_header_t hdr,
        inout switch_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr)  {
    apply {}
}

Switch(SwitchIngressParser(),
       SwitchIngress(),
       SwitchIngressDeparser(),
       SwitchEgressParser(),
       SwitchEgress(),
       SwitchEgressDeparser()) main;
