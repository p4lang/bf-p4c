#include <tna.p4>  /* TOFINO1_ONLY */
# 15 "/sde/bf-sde-9.5.1.47-cpr/install/share/p4c/p4include/tna.p4" 2
# 3 "/share/ticket/ali-00634648/test.p4" 2
# 1 "/share/ticket/ali-00634648/common.p4" 1
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
# 88 "/share/ticket/ali-00634648/common.p4"
// Address Resolution Protocol -- RFC 6747
# 97 "/share/ticket/ali-00634648/common.p4"
// Segment Routing Extension (SRH) -- IETFv7
# 107 "/share/ticket/ali-00634648/common.p4"
// VXLAN -- RFC 7348






// Generic Routing Encapsulation (GRE) -- RFC 1701
# 4 "/share/ticket/ali-00634648/test.p4" 2

header ethernet_h{
    bit<48> dst_addr; bit<48> src_addr; bit<16> ether_type;
}
header ipv4_h{
    bit<4> version; bit<4> ihl; bit<8> diffserv; bit<16> total_len; bit<16> identification; bit<3> flags; bit<13> frag_offset; bit<8> ttl; bit<8> protocol; bit<16> hdr_checksum; bit<32> src_addr; bit<32> dst_addr;
}

header ipv6_h{
    bit<4> version; bit<8> traffic_class; bit<20> flow_label; bit<16> payload_len; bit<8> next_hdr; bit<8> hop_limit; bit<128> src_addr; bit<128> dst_addr;
}
struct header_t{
    ethernet_h ethernet;
    ipv4_h ipv4;
    ipv6_h ipv6;
}
struct metadata_t{}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md,
        out ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

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
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv4;
            default : accept;
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

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {

    apply {
         pkt.emit(hdr);
    }
}

// ---------------------------------------------------------------------------
// Ingress Control
// ---------------------------------------------------------------------------
control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action route(bit<9> port){
        ig_intr_tm_md.ucast_egress_port = port;
    }
    action AAAA_cidr_route(bit<9> port) {route(port);}
    action BBBB_cidr_route(bit<9> port) {route(port);}
    action CCCC_cidr_route(bit<9> port) {route(port);}

    Alpm(number_partitions=1024, subtrees_per_partition=2) alpm;
    @pragma ways 4
    table cidr_route {
        key = {
            hdr.ipv4.isValid() : exact; // must true
            hdr.ipv4.dst_addr : lpm;
        }
        actions = {
            CCCC_cidr_route;
            BBBB_cidr_route;
            AAAA_cidr_route;
        }
        size = 40*1024;
	implementation = alpm;
    }
    table dst_route{
     key = {
            hdr.ipv4.dst_addr : exact;
        }
        actions = {
            route;
        }
    }
    table dst_route_v6{
        key = {
            hdr.ipv6.dst_addr : exact;
        }
        actions = {
            route;
        }
    }
    apply {
        switch(cidr_route.apply().action_run){
           AAAA_cidr_route:{}
           BBBB_cidr_route:{
                if (hdr.ipv6.isValid()){
                    dst_route_v6.apply();
                }
                else{
                    dst_route.apply();
                }
           }
        }
    }
}
// ---------------------------------------------------------------------------
// Egress parser
// ---------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }

}

// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------
control SwitchEgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {
         pkt.emit(hdr);
    }
}

// ---------------------------------------------------------------------------
// Egress Control
// ---------------------------------------------------------------------------
control SwitchEgress(
        inout header_t hdr,
        inout metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {

    apply {}
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

Switch(pipe) main;
