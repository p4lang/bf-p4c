/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2019-present Barefoot Networks, Inc.
 *
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.  Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

#include <core.p4>
#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
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
    bit<16> hdr_length;
    bit<16> checksum;
}

header custom_common_hdr_h {
    bit<8> type;
    bit<8> code;
}

header custom_hdr1_h {
    bit<8> type;
    bit<8> code;
    bit<16> data;
}

header custom_hdr2_h {
    bit<8> type;
    bit<8> code;
    bit<32> data;
}

struct header_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    tcp_h tcp;
    udp_h udp;
    custom_common_hdr_h custom_common;
    custom_hdr1_h custom_hdr1;
    custom_hdr2_h custom_hdr2;
}

struct empty_header_t {}

struct empty_metadata_t {}


struct metadata_t {
    bit<16> checksum_ipv4_tmp;
    bit<16> checksum_tcp_tmp;
    bit<16> checksum_udp_tmp;

    bool checksum_upd_ipv4;
    bool checksum_upd_tcp;
    bool checksum_upd_udp;

    bool checksum_err_ipv4_igprs;
}

parser TofinoIngressParser(
        packet_in pkt,
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
        pkt.advance(PORT_METADATA_SIZE);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;
    Checksum() ipv4_checksum;
    Checksum() tcp_checksum;
    Checksum() udp_checksum;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
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
        ipv4_checksum.add(hdr.ipv4);
        ig_md.checksum_err_ipv4_igprs = ipv4_checksum.verify();

        tcp_checksum.subtract({hdr.ipv4.src_addr});
        udp_checksum.subtract({hdr.ipv4.src_addr});

        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            default : accept;
        }
    }

    state parse_tcp {
        // The tcp checksum cannot be verified, since we cannot compute
        // the payload's checksum.
        pkt.extract(hdr.tcp);

        tcp_checksum.subtract({hdr.tcp.checksum});
        tcp_checksum.subtract({hdr.tcp.src_port});
        ig_md.checksum_tcp_tmp = tcp_checksum.get();

        transition parse_custom_common;
    }

    state parse_udp {
        // The tcp checksum cannot be verified, since we cannot compute
        // the payload's checksum.
        pkt.extract(hdr.udp);

        udp_checksum.subtract({hdr.udp.checksum});
        udp_checksum.subtract({hdr.udp.src_port});
        ig_md.checksum_udp_tmp = udp_checksum.get();

        transition parse_custom_common;
    }
    state parse_custom_common {
        pkt.extract(hdr.custom_common);
        transition select(hdr.custom_common.type) {
            0x1 : parse_custom_hdr1;
            0x2 : parse_custom_hdr2;
            default : accept;
        }
    }

    state parse_custom_hdr1 {
        pkt.extract(hdr.custom_hdr1);
        transition accept;
    }

    state parse_custom_hdr2 {
        pkt.extract(hdr.custom_hdr2);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress
// ---------------------------------------------------------------------------
control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action nop_() { }

    action checksum_upd_ipv4(bool update) {
        ig_md.checksum_upd_ipv4 = update;
    }

    action checksum_upd_tcp(bool update) {
        ig_md.checksum_upd_tcp = update;
    }

    action checksum_upd_udp(bool update) {
        ig_md.checksum_upd_udp = update;
    }

    action checksum_upd_ipv4_tcp_udp(bool update) {
        checksum_upd_ipv4(update);
        checksum_upd_tcp(update);
        checksum_upd_udp(update);
    }

    action snat(ipv4_addr_t src_addr,
                bool update) {
        hdr.ipv4.src_addr = src_addr;
        checksum_upd_ipv4_tcp_udp(update);
    }

    action stpat(bit<16> src_port,
                bool update) {
        checksum_upd_tcp(update);
        hdr.tcp.src_port = src_port;
    }

    action sntpat(ipv4_addr_t src_addr,
                 bit<16> src_port,
                 bool update) {
        checksum_upd_ipv4(update);
        checksum_upd_tcp(update);
        hdr.ipv4.src_addr = src_addr;
        hdr.tcp.src_port = src_port;
    }

    action supat(bit<16> src_port,
                bool update) {
        checksum_upd_udp(update);
        hdr.udp.src_port = src_port;
    }

    action snupat(ipv4_addr_t src_addr,
                 bit<16> src_port,
                 bool update) {
        checksum_upd_ipv4(update);
        checksum_upd_udp(update);
        hdr.ipv4.src_addr = src_addr;
        hdr.udp.src_port = src_port;
    }

    table translate {
        key = {
            hdr.ipv4.src_addr : exact;
            hdr.custom_common.type: exact;
            hdr.custom_hdr1.type: exact;
            hdr.custom_hdr2.type: exact;
        }
        actions = {
            nop_;
            snat;
            stpat;
            sntpat;
            supat;
            snupat;
            checksum_upd_ipv4;
            checksum_upd_tcp;
            checksum_upd_udp;
            checksum_upd_ipv4_tcp_udp;
        }

        default_action = nop_;
    }

    action set_output_port(PortId_t port_id) {
        ig_tm_md.ucast_egress_port = port_id;
    }

    table output_port {
        actions = {
            set_output_port;
        }
    }

    apply {
        // Apply address and port translations
        translate.apply();

        output_port.apply();

        // Ensure the UDP checksum is only checked if it was set in the incoming
        // packet
        if (hdr.udp.checksum == 0 && ig_md.checksum_upd_udp) {
            checksum_upd_udp(false);
        }

        // Detect checksum errors in the ingress parser and tag the packets
        if (ig_md.checksum_err_ipv4_igprs) {
            hdr.ethernet.dst_addr = 0x0000deadbeef;
        }

        // No need for egress processing, skip it and use empty controls for egress.
        ig_tm_md.bypass_egress = 1w1;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(packet_out pkt,
                              inout header_t hdr,
                              in metadata_t ig_md,
                              in ingress_intrinsic_metadata_for_deparser_t
                                ig_intr_dprsr_md
                              ) {

    Checksum() ipv4_checksum;
    Checksum() tcp_checksum;
    Checksum() udp_checksum;

    apply {
        // Updating and checking of the checksum is done in the deparser.
        // Checksumming units are only available in the parser sections of
        // the program.
        if (ig_md.checksum_upd_ipv4) {
            hdr.ipv4.hdr_checksum = ipv4_checksum.update(
                {hdr.ipv4.version,
                 hdr.ipv4.ihl,
                 hdr.ipv4.diffserv,
                 hdr.ipv4.total_len,
                 hdr.ipv4.identification,
                 hdr.ipv4.flags,
                 hdr.ipv4.frag_offset,
                 hdr.ipv4.ttl,
                 hdr.ipv4.protocol,
                 hdr.ipv4.src_addr,
                 hdr.ipv4.dst_addr});
        }

        // p4c-4837: make sure custom_hdr1 and custom_hdr2 are not packed in same container.
        if (ig_md.checksum_upd_tcp) {
            hdr.tcp.checksum = tcp_checksum.update({
                hdr.ipv4.src_addr,
                hdr.tcp.src_port,
                hdr.custom_common,
                hdr.custom_hdr1,
                hdr.custom_hdr2,
                ig_md.checksum_tcp_tmp
            });
        }

        // p4c-4837: make sure custom_hdr1 and custom_hdr2 are not packed in same container.
        if (ig_md.checksum_upd_udp) {
            hdr.udp.checksum = udp_checksum.update(data = {
                hdr.ipv4.src_addr,
                hdr.udp.src_port,
                hdr.custom_common,
                hdr.custom_hdr1,
                hdr.custom_hdr2,
                ig_md.checksum_udp_tmp
            }, zeros_as_ones = true);
            // UDP specific checksum handling
        }

        pkt.emit(hdr);
    }
}

parser EmptyEgressParser(
        packet_in pkt,
        out empty_header_t hdr,
        out empty_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser(
        packet_out pkt,
        inout empty_header_t hdr,
        in empty_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}

control EmptyEgress(
        inout empty_header_t hdr,
        inout empty_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}

Pipeline(SwitchIngressParser(),
       SwitchIngress(),
       SwitchIngressDeparser(),
       EmptyEgressParser(),
       EmptyEgress(),
       EmptyEgressDeparser()) pipe;

Switch(pipe) main;
