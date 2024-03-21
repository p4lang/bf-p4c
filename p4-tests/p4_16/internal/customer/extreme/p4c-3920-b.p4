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

#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#define PVS  // define this to hit bug from case 630147

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
const bit<16> ETHERTYPE_IPV4 = 16w0x0800;

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

header custom_metadata_h {
// Value of the tag during pipeline processing:
//  VALUE  - PIPELINE
//   x     - set to user defined value in ingress pipeline_profile_a
//   x+1   - pipeline_profile_b egress
//   x+2   - pipeline_profile_b ingress
//   x+3   - pipeline_profile_a egress
    bit<16> custom_tag;
}

struct custom_header_t {
    ethernet_h ethernet;
    ipv4_h ipv4;

    // Add more headers here.
    custom_metadata_h custom_metadata;
}

struct digest_t {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
}

typedef bit<2> pkt_color_t;
const pkt_color_t SWITCH_METER_COLOR_GREEN = 0;
const pkt_color_t SWITCH_METER_COLOR_YELLOW = 1;
const pkt_color_t SWITCH_METER_COLOR_RED = 2;

struct qos_metadata_a_t {
    pkt_color_t color;
}

typedef bit<16> meter_index_t;

struct port_md_a_t {
    bit<32> f1;
    bit<16> f2;
}

struct metadata_a_t {
  port_md_a_t port_md;
}

struct switch_cpu_port_value_set_t {
    bit<16> ether_type;
}


// ---------------------------------------------------------------------------
// Ingress parser for pipeline a
// ---------------------------------------------------------------------------
parser SwitchIngressParser_a(
        packet_in pkt,
        out custom_header_t hdr,
        out metadata_a_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {


    value_set<switch_cpu_port_value_set_t>(4) cpu_port;


    state start {
        pkt.extract(ig_intr_md);
        ig_md.port_md = port_metadata_unpack<port_md_a_t>(pkt);
        pkt.extract(hdr.ethernet);

        transition select (hdr.ethernet.ether_type) {

            cpu_port : parse_ipv4;



            default : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Egress parser for pipeline a
// ---------------------------------------------------------------------------
parser SwitchEgressParser_a(
        packet_in pkt,
        out custom_header_t hdr,
        out metadata_a_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);
        pkt.extract(hdr.ethernet);
        transition select (hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            default : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition parse_custom_metadata;
    }

    state parse_custom_metadata {
        pkt.extract(hdr.custom_metadata);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser for pipeline a
// ---------------------------------------------------------------------------
control SwitchIngressDeparser_a(
        packet_out pkt,
        inout custom_header_t hdr,
        in metadata_a_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    Checksum() ipv4_checksum;

    apply {
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

        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.custom_metadata);
    }
}


// ---------------------------------------------------------------------------
// Egress Deparser for pipeline a
// ---------------------------------------------------------------------------
control SwitchEgressDeparser_a(packet_out pkt,
                              inout custom_header_t hdr,
                              in metadata_a_t eg_md,
                              in egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md) {
    Checksum() ipv4_checksum;

    apply {
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

        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
    }
}


// ---------------------------------------------------------------------------
// P4 Pipeline a
// Packet travels through different table types (exm, tcam), each of which
// decrement the ipv4 ttl on a table hit.
// Counters and meters are attached to few tables
// ---------------------------------------------------------------------------
control SwitchIngress_a(
        inout custom_header_t hdr,
        inout metadata_a_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    qos_metadata_a_t qos_md;
    Meter<meter_index_t>(512, MeterType_t.BYTES) meter;
    Counter<bit<32>, PortId_t>(
        512, CounterType_t.PACKETS) storm_control_stats;

    action hit() {
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action miss() {
        ig_dprsr_md.drop_ctl = 0x1; // Drop packet.
    }

    table forward {
        key = {
            hdr.ethernet.dst_addr : exact;
            hdr.ipv4.ttl : exact;
        }

        actions = {
            hit;
            miss;
        }

        const default_action = miss;
        size = 1024;
    }

    action encap_custom_metadata(bit<16> tag) {
        hdr.custom_metadata.setValid();
        hdr.custom_metadata.custom_tag = tag;
    }

    table encap_custom_metadata_hdr {
        key = {
            ig_md.port_md.f1 : exact;
            ig_md.port_md.f2 : exact;
        }

        actions = {
            encap_custom_metadata;
        }
        size = 1024;
    }

    action modify_eg_port(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    table pinning {
        key = {
            ig_intr_md.ingress_port : exact;
        }

        actions = {
            NoAction;
            modify_eg_port;
        }

        const default_action = NoAction;
        size = 512;
    }

    action set_color(meter_index_t index) {
        qos_md.color = (bit<2>) meter.execute(index);
    }

    table storm_control {
        key = {
            ig_intr_md.ingress_port : exact;
        }

        actions = {
            NoAction;
            set_color;
        }

        const default_action = NoAction;
        size = 512;
    }

    action count() {
        storm_control_stats.count(ig_intr_md.ingress_port);
    }

    table stats {
        key = {
            qos_md.color : exact;
            ig_intr_md.ingress_port : exact;
        }

        actions = {
            NoAction;
            count;
        }
    }


    apply {
        qos_md.color = 0;
        storm_control.apply();
        stats.apply();
        forward.apply();
        encap_custom_metadata_hdr.apply();
        pinning.apply();
    }
}

control SwitchEgress_a(
    inout custom_header_t hdr,
    inout metadata_a_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) direct_counter;

    action hit() {
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        hdr.custom_metadata.custom_tag = hdr.custom_metadata.custom_tag + 1;
        direct_counter.count();
    }

    action miss() {
        eg_intr_md_for_dprs.drop_ctl = 0x1; // Drop packet.
    }

    table forward {
        key = {
            hdr.ipv4.dst_addr : ternary;
            hdr.ipv4.ttl : ternary;
            hdr.custom_metadata.custom_tag: ternary;
        }

        actions = {
            hit;
            @defaultonly miss;
        }

        const default_action = miss;
        size = 1024;
        counters = direct_counter;
    }

    apply {
        forward.apply();
    }

}

// Packet comes into ingress profile_a which adds an extra custom_metadata_h
// header to the packet. The packet travels to egress profile_b, then to
// ingress profile_b and finally to egress profile_a. The custom_metadata_h
// header is striped off by egress profile_b. Value of custom_tag is modified
// as the packet travels.

Pipeline(SwitchIngressParser_a(),
         SwitchIngress_a(),
         SwitchIngressDeparser_a(),
         SwitchEgressParser_a(),
         SwitchEgress_a(),
         SwitchEgressDeparser_a()) pipeline_profile_a;

Pipeline(SwitchIngressParser_a(),
         SwitchIngress_a(),
         SwitchIngressDeparser_a(),
         SwitchEgressParser_a(),
         SwitchEgress_a(),
         SwitchEgressDeparser_a()) pipeline_profile_b;

Switch(pipeline_profile_a, pipeline_profile_b) main;
