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
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

#ifndef CASE_FIX
#define CASE_FIX 4
#endif
#include <tna.p4>

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
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/



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



        pkt.advance(64);

        transition accept;
    }
}

parser TofinoEgressParser(
        packet_in pkt,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

// Empty egress parser/control blocks
parser EmptyEgressParser<H, M>(
        packet_in pkt,
        out H hdr,
        out M eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser<H, M>(
        packet_out pkt,
        inout H hdr,
        in M eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}

control EmptyEgress<H, M>(
        inout H hdr,
        inout M eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}
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




typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
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

header ipv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
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

header icmp_h {
    bit<8> type_;
    bit<8> code;
    bit<16> hdr_checksum;
}

// Address Resolution Protocol -- RFC 6747
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
    // ...
}

// Segment Routing Extension (SRH) -- IETFv7
header ipv6_srh_h {
    bit<8> next_hdr;
    bit<8> hdr_ext_len;
    bit<8> routing_type;
    bit<8> seg_left;
    bit<8> last_entry;
    bit<8> flags;
    bit<16> tag;
}

// VXLAN -- RFC 7348
header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

// Generic Routing Encapsulation (GRE) -- RFC 1701
header gre_h {
    bit<1> C;
    bit<1> R;
    bit<1> K;
    bit<1> S;
    bit<1> s;
    bit<3> recurse;
    bit<5> flags;
    bit<3> version;
    bit<16> proto;
}

struct header_t {
    ethernet_h ethernet;
    vlan_tag_h vlan_tag;
    ipv4_h ipv4;
    ipv6_h ipv6;
    tcp_h tcp;
    udp_h udp;

    // Add more headers here.
}

parser SimplePacketParser(packet_in pkt, inout header_t hdr) {
    state start { // parse Ethernet
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
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

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
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

struct ingress_metadata_t {
};

struct egress_metadata_t {
}

/* -*- P4_16 -*- */




// *****************************************************************************
// Example register code, taken from "P4 Language Cheat Sheet"
// *****************************************************************************

control npb_ing_flowtable_v4 (
 in header_t hdr,
 in ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

 bit<32> flowtable_hash;

 // =========================================================================
 // The Register Array
 // =========================================================================

 Register<bit<32>, bit<32>>(32w1024) test_reg;

 RegisterAction<bit<32>, bit<32>, bit<32>>(test_reg) test_reg_action = {
  void apply(
   inout bit<32> value,
   out bit<32> read_value
  ) {
   // check entry
   read_value = value;

   // update entry
#if CASE_FIX > 0
   value = (bit<16>)ig_intr_md.ingress_port ++ flowtable_hash[31:16];
#else
   value = {(bit<16>)ig_intr_md.ingress_port ++ flowtable_hash[31:16]};
#endif
  }
 };

 // =========================================================================
 // The Hash Function
 // =========================================================================

 Hash<bit<32>>(HashAlgorithm_t.CRC32) h;

 // =========================================================================
 //
 // =========================================================================

 apply {
  bit<32> return_value;

  // ***** hash the key *****
  flowtable_hash = h.get({hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol, hdr.tcp.src_port, hdr.tcp.dst_port});

  // ***** use hashed key to index register *****
  return_value = test_reg_action.execute((bit<32>)flowtable_hash);

  // ***** drop packet? *****
#if CASE_FIX == 1
  if(return_value == (bit<16>)ig_intr_md.ingress_port ++ flowtable_hash[31:16]) {
#elif CASE_FIX == 2
  if(return_value[31:16] == (bit<16>)ig_intr_md.ingress_port &&
     return_value[15:0] == flowtable_hash[31:16]) {
#elif CASE_FIX == 3
  if(return_value[31:16] == (bit<16>)ig_intr_md.ingress_port) {
     if(return_value[15:0] == flowtable_hash[31:16])  {
#elif CASE_FIX == 4
  if((PortId_t)return_value[31:16] == ig_intr_md.ingress_port) {
     if(return_value[15:0] == flowtable_hash[31:16])  {
#else
  if(return_value =={(bit<16>)ig_intr_md.ingress_port ++ flowtable_hash[31:16]}) {
#endif
   ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
#if CASE_FIX >= 3
     }
#endif
  }

 }

}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// INGRESS
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------

parser SwitchIngressParser(
 packet_in pkt,
 out header_t hdr,
 out ingress_metadata_t ig_md,
 out ingress_intrinsic_metadata_t ig_intr_md
) {

 TofinoIngressParser() tofino_parser;

 state start {
  tofino_parser.apply(pkt, ig_intr_md);
  transition parse_ethernet;
 }

 state parse_ethernet {
  pkt.extract(hdr.ethernet);
  transition parse_ipv4;
 }

 state parse_ipv4 {
  pkt.extract(hdr.ipv4);
  transition accept;
 }
}

// ---------------------------------------------------------------------------
// Ingress Match-Action
// ---------------------------------------------------------------------------

control SwitchIngress(
 inout header_t hdr,
 inout ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

 apply {

  npb_ing_flowtable_v4.apply(
   hdr,
   ig_md,
   ig_intr_md,
   ig_intr_md_from_prsr,
   ig_intr_md_for_dprsr,
   ig_intr_md_for_tm
  );

 }

}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------

control SwitchIngressDeparser(
 packet_out pkt,
 inout header_t hdr,
 in ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md
) {

 Checksum() ipv4_checksum;

 apply {
  hdr.ipv4.hdr_checksum = ipv4_checksum.update({
   hdr.ipv4.version,
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

//		 pkt.emit(hdr);
   pkt.emit(hdr.ethernet);
   pkt.emit(hdr.vlan_tag);
   pkt.emit(hdr.ipv4);
   pkt.emit(hdr.ipv6);
   pkt.emit(hdr.tcp);
   pkt.emit(hdr.udp);
 }
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// EGRESS
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Egress parser
// ---------------------------------------------------------------------------

parser SwitchEgressParser(
 packet_in pkt,
 out header_t hdr,
 out egress_metadata_t eg_md,
 out egress_intrinsic_metadata_t eg_intr_md
) {

 TofinoEgressParser() tofino_parser;

 state start {
  tofino_parser.apply(pkt, eg_intr_md);
  transition parse_ethernet;
 }

 state parse_ethernet {
  pkt.extract(hdr.ethernet);
  transition parse_ipv4;
 }

 state parse_ipv4 {
  pkt.extract(hdr.ipv4);
  transition accept;
 }
}

// ---------------------------------------------------------------------------
// Egress Match-Action
// ---------------------------------------------------------------------------

control SwitchEgress(
 inout header_t hdr,
 inout egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 apply {


 }
}

// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------

control SwitchEgressDeparser(
 packet_out pkt,
 inout header_t hdr,
 in egress_metadata_t eg_md,
 in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md
) {

 Checksum() ipv4_checksum;

 apply {
  hdr.ipv4.hdr_checksum = ipv4_checksum.update({
   hdr.ipv4.version,
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

//		 pkt.emit(hdr);
   pkt.emit(hdr.ethernet);
   pkt.emit(hdr.vlan_tag);
   pkt.emit(hdr.ipv4);
   pkt.emit(hdr.ipv6);
   pkt.emit(hdr.tcp);
   pkt.emit(hdr.udp);
 }
}

// ---------------------------------------------------------------------------
// Top-Level
// ---------------------------------------------------------------------------

Pipeline(
 SwitchIngressParser (),
 SwitchIngress (),
 SwitchIngressDeparser(),
 SwitchEgressParser (),
 SwitchEgress (),
 SwitchEgressDeparser ()
) pipe;

Switch(pipe) main;
